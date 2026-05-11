{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

{ LHICE.PAS - Clone Turbo Pascal/Free Pascal de la commande ICE / LHarc 1.14
  Format LZH (Level-0), methodes -lh0- (stored) et -lh1- (LZSS + Huffman
  adaptatif a la Okumura - "LZHUF"). Decode aussi -lh4-/-lh5- ? Non : seul
  le format LH0 et LH1 d'origine ICE 1.14 est supporte.

  Auteur : portage Pascal sous licence libre.
  Reference : LZHUF.C (Haruyasu Yoshizaki & Haruhiko Okumura, 1988-89).

  Compilation : fpc -Mtp -O1 LHICE.PAS                                    }

{$IFDEF FPC}{$MODE TP}{$ENDIF}
{$R-,S-,I-,Q-}

Program LHICE;

Uses Dos;

Const
 Version       = '1.14';
 ARC_EXT       = '.ICE';
 IOBUFSZ       = 8192;
 MAX_NAMES     = 256;
 MAX_FN        = 80;       { longueur max chemin stocke }

 { Parametres LZHUF }
 LZ_N          = 4096;     { taille du tampon glissant }
 LZ_F          = 60;       { taille du look-ahead       }
 LZ_THRESHOLD  = 2;        { match minimum             }
 LZ_NIL        = LZ_N;     { sentinelle d'arbre        }

 { Huffman adaptatif }
 N_CHAR        = (256 - LZ_THRESHOLD) + LZ_F;   { 314 }
 T_TBL         = (N_CHAR * 2) - 1;              { 627 }
 R_ROOT        = T_TBL - 1;                     { 626 }
 MAX_FREQ      = $8000;

 ARC_MARKER    = $1A;   { absent du format LZH mais utilise par anciens }

Type
 Str13   = String[13];
 Str80   = String[80];
 Str255  = String[255];

 PIOBuf  = ^TIOBuf;
 TIOBuf  = Array[0..IOBUFSZ-1] of Byte;

 TLhHdr  = Record
  Method     : Array[1..5] of Char;     { "-lh0-" ou "-lh1-" }
  CompSize   : LongInt;
  OrigSize   : LongInt;
  TimeStamp  : LongInt;                 { MS-DOS pack time   }
  Attr       : Byte;
  Level      : Byte;
  Name       : Str255;
  CRC        : Word;
 End;

 { Liste chainee des arguments fichiers - allouee sur le tas.
   En Turbo Pascal le segment de donnees est limite a 64 Ko,
   un Array[1..256] of Str255 (= 65536 octets) ne tient pas. }
 PArgNode = ^TArgNode;
 TArgNode = Record
  Name  : Str255;
  InArc : Boolean;
  Next  : PArgNode;
 End;

Var
 { Etat global }
 Cmd         : Char;
 ArchiveName : Str255;
 ArgCount    : Word;
 ArgHead     : PArgNode;
 ArgTail     : PArgNode;

 { Switches }
 Sw_Compare  : Boolean;   { /c : skip time compare }
 Sw_NoMsg    : Boolean;   { /m }
 Sw_NoInd    : Boolean;   { /n }
 Sw_AnyAttr  : Boolean;   { /a }
 Sw_ExtName  : Boolean;   { /x }
 Sw_NoLh1    : Boolean;   { force store }
 Language    : Byte;      { 0=Fr 1=En }

 { Fichier archive }
 ArcF        : File;
 ArcOpened   : Boolean;
 InBuf       : PIOBuf;
 InPos, InCnt: Word;
 InEnd       : Boolean;
 InByteCount : LongInt;

 { Sortie (extraction) }
 OutF        : File;
 OutFileOpen : Boolean;
 OutToStdout : Boolean;
 OutBuf      : PIOBuf;
 OutPos      : Word;
 OutSize     : LongInt;

 { Source (compression) }
 SrcF        : File;
 SrcBuf      : PIOBuf;
 SrcPos, SrcCnt: Word;
 SrcEnd      : Boolean;
 SrcByteRead : LongInt;

 { Ecriture archive }
 WrF         : File;
 WrBuf       : PIOBuf;
 WrPos       : Word;
 WrByteCount : LongInt;

 { Etat LZSS partage encodeur/decodeur }
 LZ_Text     : Array[0..LZ_N + LZ_F - 1] of Byte;

 { Etat decodeur LZSS }
 D_R         : Word;

 { Etat encodeur LZSS - arbres binaires de match }
 E_Dad       : Array[0..LZ_N] of Word;
 E_LSon      : Array[0..LZ_N] of Word;
 E_RSon      : Array[0..LZ_N + 256] of Word;
 E_MatchPos  : Word;
 E_MatchLen  : Word;

 { Etat Huffman adaptatif }
 H_Freq      : Array[0..T_TBL] of Word;
 H_Prnt      : Array[0..T_TBL + N_CHAR - 1] of Word;
 H_Son       : Array[0..T_TBL] of Word;

 { Etat bit I/O }
 BitBuf      : Word;
 BitCnt      : Byte;     { bits valides dans BitBuf cote MSB }

 { CRC }
 CRC         : Word;

 { Stats globales }
 N_Added     : Word;
 N_Updated   : Word;
 N_Extracted : Word;
 N_Tested    : Word;
 N_Deleted   : Word;
 N_Listed    : Word;
 ExitCode_   : Byte;

 TmpArcName  : Str255;

{ ===== Tables statiques pour encodage de la position ================== }

Const
 P_LEN : Array[0..63] of Byte = (
  $03, $04, $04, $04, $05, $05, $05, $05,
  $05, $05, $05, $05, $06, $06, $06, $06,
  $06, $06, $06, $06, $06, $06, $06, $06,
  $07, $07, $07, $07, $07, $07, $07, $07,
  $07, $07, $07, $07, $07, $07, $07, $07,
  $07, $07, $07, $07, $07, $07, $07, $07,
  $08, $08, $08, $08, $08, $08, $08, $08,
  $08, $08, $08, $08, $08, $08, $08, $08);

 P_CODE : Array[0..63] of Byte = (
  $00, $20, $30, $40, $50, $58, $60, $68,
  $70, $78, $80, $88, $90, $94, $98, $9C,
  $A0, $A4, $A8, $AC, $B0, $B4, $B8, $BC,
  $C0, $C2, $C4, $C6, $C8, $CA, $CC, $CE,
  $D0, $D2, $D4, $D6, $D8, $DA, $DC, $DE,
  $E0, $E2, $E4, $E6, $E8, $EA, $EC, $EE,
  $F0, $F1, $F2, $F3, $F4, $F5, $F6, $F7,
  $F8, $F9, $FA, $FB, $FC, $FD, $FE, $FF);

 D_CODE : Array[0..255] of Byte = (
   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
   1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
   2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
   3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
   4,  4,  4,  4,  4,  4,  4,  4,  5,  5,  5,  5,  5,  5,  5,  5,
   6,  6,  6,  6,  6,  6,  6,  6,  7,  7,  7,  7,  7,  7,  7,  7,
   8,  8,  8,  8,  8,  8,  8,  8,  9,  9,  9,  9,  9,  9,  9,  9,
  10, 10, 10, 10, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11,
  12, 12, 12, 12, 13, 13, 13, 13, 14, 14, 14, 14, 15, 15, 15, 15,
  16, 16, 16, 16, 17, 17, 17, 17, 18, 18, 18, 18, 19, 19, 19, 19,
  20, 20, 20, 20, 21, 21, 21, 21, 22, 22, 22, 22, 23, 23, 23, 23,
  24, 24, 25, 25, 26, 26, 27, 27, 28, 28, 29, 29, 30, 30, 31, 31,
  32, 32, 33, 33, 34, 34, 35, 35, 36, 36, 37, 37, 38, 38, 39, 39,
  40, 40, 41, 41, 42, 42, 43, 43, 44, 44, 45, 45, 46, 46, 47, 47,
  48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63);

 D_LEN : Array[0..255] of Byte = (
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
  4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
  4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
  6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
  6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
  6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
  7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
  7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
  7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
  8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8);

{ ===== CRC-16 (poly $A001, comme ARC/LHA) ============================= }

Procedure ResetCRC; Begin CRC := 0; End;

Procedure UpdCRC(B: Byte);
Var I: Byte;
Begin
 CRC := CRC Xor B;
 For I := 1 To 8 Do
  If (CRC And 1) <> 0 Then CRC := (CRC Shr 1) Xor $A001
  Else CRC := CRC Shr 1;
End;

{ ===== Utilitaires chaines =========================================== }

Function UpStr(Const S: Str255): Str255;
Var I: Word; R: Str255;
Begin
 R := S; For I := 1 To Length(R) Do R[I] := UpCase(R[I]); UpStr := R;
End;

Function LongStr(L: LongInt): Str13;
Var S: Str13;
Begin Str(L, S); LongStr := S; End;

Function PadLeft(Const S: Str80; W: Byte): Str80;
Var R: Str80;
Begin R := S; While Length(R) < W Do R := ' ' + R; PadLeft := R; End;

Function PadRight(Const S: Str80; W: Byte): Str80;
Var R: Str80;
Begin R := S; While Length(R) < W Do R := R + ' '; PadRight := R; End;

Function HasExt(Const N: Str255): Boolean;
Var I: Word;
Begin
 HasExt := False;
 For I := Length(N) DownTo 1 Do Begin
  If (N[I] = '\') Or (N[I] = '/') Or (N[I] = ':') Then Exit;
  If N[I] = '.' Then Begin HasExt := True; Exit; End;
 End;
End;

Function StripPath(Const S: Str255): Str255;
Var I: Word;
Begin
 For I := Length(S) DownTo 1 Do
  If (S[I]='\') Or (S[I]='/') Or (S[I]=':') Then Begin
   StripPath := Copy(S, I+1, 255); Exit;
  End;
 StripPath := S;
End;

{ ===== Messages ====================================================== }

Procedure Warn(Const M: Str255);
Begin WriteLn('ICE: ', M); End;

Procedure Die(Const M: Str255);
Begin WriteLn('ICE: ', M); Halt(2); End;

{ ===== I/O bufferise sur archive ===================================== }

Procedure InResetCounters;
Begin InPos := 0; InCnt := 0; InEnd := False; InByteCount := 0; End;

Procedure InRefill;
Var R: Word;
Begin
 BlockRead(ArcF, InBuf^, IOBUFSZ, R);
 InCnt := R; InPos := 0;
 If R = 0 Then InEnd := True;
End;

Function InGetByte: Byte;
Var B: Byte;
Begin
 If InEnd Then Begin InGetByte := 0; Exit; End;
 If InPos >= InCnt Then InRefill;
 If InEnd Then Begin InGetByte := 0; Exit; End;
 B := InBuf^[InPos]; Inc(InPos); Inc(InByteCount);
 InGetByte := B;
End;

Function InGetWord: Word;
Var L, H: Byte;
Begin L := InGetByte; H := InGetByte; InGetWord := L Or (Word(H) Shl 8); End;

Function InGetLong: LongInt;
Var B0, B1, B2, B3: Byte; R: LongInt;
Begin
 B0 := InGetByte; B1 := InGetByte; B2 := InGetByte; B3 := InGetByte;
 R := LongInt(B0) Or (LongInt(B1) Shl 8) Or
      (LongInt(B2) Shl 16) Or (LongInt(B3) Shl 24);
 InGetLong := R;
End;

Procedure WrFlush;
Begin
 If WrPos > 0 Then Begin BlockWrite(WrF, WrBuf^, WrPos); WrPos := 0; End;
End;

Procedure WrByte(B: Byte);
Begin
 If WrPos >= IOBUFSZ Then WrFlush;
 WrBuf^[WrPos] := B; Inc(WrPos); Inc(WrByteCount);
End;

Procedure WrWord(W: Word); Begin WrByte(W And $FF); WrByte((W Shr 8) And $FF); End;

Procedure WrLong(L: LongInt);
Begin
 WrByte(Byte(L And $FF));
 WrByte(Byte((L Shr 8) And $FF));
 WrByte(Byte((L Shr 16) And $FF));
 WrByte(Byte((L Shr 24) And $FF));
End;

{ ===== Sortie (decompression) ======================================== }

Procedure OutFlush;
Var I: Word;
Begin
 If OutPos = 0 Then Exit;
 If OutToStdout Then
  For I := 0 To OutPos - 1 Do Write(Char(OutBuf^[I]))
 Else
  BlockWrite(OutF, OutBuf^, OutPos);
 OutPos := 0;
End;

Procedure OutPutByte(B: Byte);
Begin
 If OutPos >= IOBUFSZ Then OutFlush;
 OutBuf^[OutPos] := B; Inc(OutPos); Inc(OutSize);
 UpdCRC(B);
End;

{ ===== Source (compression) ========================================== }

Procedure SrcReset;
Begin SrcPos := 0; SrcCnt := 0; SrcEnd := False; SrcByteRead := 0; End;

Procedure SrcRefill;
Var R: Word;
Begin
 BlockRead(SrcF, SrcBuf^, IOBUFSZ, R);
 SrcCnt := R; SrcPos := 0; If R = 0 Then SrcEnd := True;
End;

Function SrcGetByte(Var B: Byte): Boolean;
Begin
 If SrcPos >= SrcCnt Then SrcRefill;
 If SrcEnd Then Begin SrcGetByte := False; Exit; End;
 B := SrcBuf^[SrcPos]; Inc(SrcPos); Inc(SrcByteRead);
 SrcGetByte := True;
End;

{ ===== Bit I/O ======================================================= }

Procedure BitInit;
Begin BitBuf := 0; BitCnt := 0; End;

Procedure PutBits(N: Byte; X: Word);
Var Mask: Word;
Begin
 { Place N bits a partir du MSB de BitBuf vers WrByte. }
 Mask := Word(1) Shl (N - 1);
 While Mask <> 0 Do Begin
  If (X And Mask) <> 0 Then BitBuf := BitBuf Or (Word(1) Shl (15 - BitCnt));
  Inc(BitCnt);
  If BitCnt = 16 Then Begin
   WrByte(Byte((BitBuf Shr 8) And $FF));
   WrByte(Byte(BitBuf And $FF));
   BitBuf := 0; BitCnt := 0;
  End;
  Mask := Mask Shr 1;
 End;
End;

Procedure FlushPutBits;
Begin
 If BitCnt > 0 Then Begin
  WrByte(Byte((BitBuf Shr 8) And $FF));
  WrByte(Byte(BitBuf And $FF));
  BitBuf := 0; BitCnt := 0;
 End;
End;

{ Lecture : BitBuf agit comme registre MSB. }

Procedure GetInit;
Begin
 BitBuf := 0;
 { Pre-charger 32 bits virtuels : on lit a la demande }
 BitCnt := 0;
End;

Function GetBit: Byte;
Begin
 If BitCnt = 0 Then Begin
  BitBuf := Word(InGetByte) Shl 8;
  BitBuf := BitBuf Or InGetByte;
  BitCnt := 16;
 End;
 If (BitBuf And $8000) <> 0 Then GetBit := 1 Else GetBit := 0;
 BitBuf := BitBuf Shl 1;
 Dec(BitCnt);
End;

Function GetBits(N: Byte): Word;
Var R: Word;
Begin
 R := 0;
 While N > 0 Do Begin R := (R Shl 1) Or GetBit; Dec(N); End;
 GetBits := R;
End;

{ ===== Huffman adaptatif ============================================= }

Procedure HuffStartTree;
Var I, J: Word;
Begin
 For I := 0 To N_CHAR - 1 Do Begin
  H_Freq[I] := 1;
  H_Son[I] := I + T_TBL;
  H_Prnt[I + T_TBL] := I;
 End;
 I := 0; J := N_CHAR;
 While J <= R_ROOT Do Begin
  H_Freq[J] := H_Freq[I] + H_Freq[I + 1];
  H_Son[J] := I;
  H_Prnt[I] := J;
  H_Prnt[I + 1] := J;
  Inc(I, 2); Inc(J);
 End;
 H_Freq[T_TBL] := $FFFF;
 H_Prnt[R_ROOT] := 0;
End;

Procedure HuffReconstruct;
Var I, J, K, F, L: Word;
Begin
 { Collecter feuilles, diviser frequences par 2 }
 J := 0;
 For I := 0 To T_TBL - 1 Do Begin
  If H_Son[I] >= T_TBL Then Begin
   H_Freq[J] := (H_Freq[I] + 1) Shr 1;
   H_Son[J] := H_Son[I];
   Inc(J);
  End;
 End;
 { Reconstruire les noeuds internes }
 I := 0; J := N_CHAR;
 While J < T_TBL Do Begin
  K := I + 1; F := H_Freq[I] + H_Freq[K];
  H_Freq[J] := F;
  K := J - 1;
  While F < H_Freq[K] Do Dec(K);
  Inc(K);
  L := (J - K) Shl 1;
  Move(H_Freq[K], H_Freq[K + 1], L);
  H_Freq[K] := F;
  Move(H_Son[K], H_Son[K + 1], L);
  H_Son[K] := I;
  Inc(I, 2); Inc(J);
 End;
 { Reconstruire les pointeurs Prnt }
 For I := 0 To T_TBL - 1 Do Begin
  K := H_Son[I];
  If K >= T_TBL Then H_Prnt[K] := I
  Else Begin H_Prnt[K] := I; H_Prnt[K + 1] := I; End;
 End;
End;

Procedure HuffUpdate(C: Word);
Var I, J, K, L: Word;
Begin
 If H_Freq[R_ROOT] = MAX_FREQ Then HuffReconstruct;
 C := H_Prnt[C + T_TBL];
 Repeat
  Inc(H_Freq[C]);
  K := H_Freq[C];
  { Si frequence devient plus grande que le voisin, echanger }
  L := C + 1;
  If L < T_TBL Then Begin
   If K > H_Freq[L] Then Begin
    While (L < T_TBL) And (K > H_Freq[L]) Do Inc(L);
    Dec(L);
    H_Freq[C] := H_Freq[L];
    H_Freq[L] := K;
    I := H_Son[C];
    H_Prnt[I] := L;
    If I < T_TBL Then H_Prnt[I + 1] := L;
    J := H_Son[L];
    H_Son[L] := I;
    H_Prnt[J] := C;
    If J < T_TBL Then H_Prnt[J + 1] := C;
    H_Son[C] := J;
    C := L;
   End;
  End;
  C := H_Prnt[C];
 Until C = 0;
End;

{ ===== Decodeur Huffman + position =================================== }

Function DecodeChar: Word;
Var C: Word;
Begin
 C := H_Son[R_ROOT];
 While C < T_TBL Do
  If GetBit = 1 Then C := H_Son[C + 1]
  Else C := H_Son[C];
 C := C - T_TBL;
 HuffUpdate(C);
 DecodeChar := C;
End;

Function DecodePosition: Word;
Var I, J, C: Word;
Begin
 { Charger 8 bits puis utiliser D_CODE / D_LEN }
 I := GetBits(8);
 C := Word(D_CODE[I]) Shl 6;
 J := D_LEN[I];
 { Lire (j - 2) bits supplementaires pour completer le numero de bucket }
 If J > 2 Then I := (I Shl (J - 2)) Or GetBits(J - 2);
 { Combiner low 6 bits brut }
 DecodePosition := C Or (I And $3F);
End;

{ ===== Encodeur Huffman + position =================================== }

Procedure EncodeChar(C: Word);
Var I, J, K: Word;
 Code, Len: Word;
Begin
 Code := 0; Len := 0;
 K := H_Prnt[C + T_TBL];
 Repeat
  Code := Code Shr 1;
  If (K And 1) <> 0 Then Code := Code Or $8000;
  Inc(Len);
  K := H_Prnt[K];
 Until K = R_ROOT;
 { Aligne a gauche }
 PutBits(Len, Code Shr (16 - Len));
 HuffUpdate(C);
 { eviter avertissements }
 I := 0; J := 0; I := I; J := J;
End;

Procedure EncodePosition(C: Word);
Var I: Word;
Begin
 I := C Shr 6;
 PutBits(P_LEN[I], P_CODE[I] Shr (8 - P_LEN[I]));
 PutBits(6, C And $3F);
End;

{ ===== LZSS encodeur : init/insert/delete/match ====================== }

Procedure LZE_InitTree;
Var I: Word;
Begin
 For I := LZ_N + 1 To LZ_N + 256 Do E_RSon[I] := LZ_NIL;
 For I := 0 To LZ_N - 1 Do E_Dad[I] := LZ_NIL;
End;

Procedure LZE_InsertNode(R: Word);
Var I, P, Cmp: Word; Geq: Boolean;
Begin
 Cmp := 1;
 P := LZ_N + 1 + LZ_Text[R];
 E_RSon[R] := LZ_NIL; E_LSon[R] := LZ_NIL;
 E_MatchLen := 0;
 Geq := True;
 While True Do Begin
  If Geq Then Begin
   If E_RSon[P] = LZ_NIL Then Begin E_RSon[P] := R; E_Dad[R] := P; Exit; End;
   P := E_RSon[P];
  End Else Begin
   If E_LSon[P] = LZ_NIL Then Begin E_LSon[P] := R; E_Dad[R] := P; Exit; End;
   P := E_LSon[P];
  End;
  I := 1;
  While I < LZ_F Do Begin
   If LZ_Text[R + I] <> LZ_Text[P + I] Then Begin
    If LZ_Text[R + I] > LZ_Text[P + I] Then Geq := True Else Geq := False;
    Break;
   End;
   Inc(I);
  End;
  If I = LZ_F Then Begin
   { match parfait => remplacer le noeud existant }
   E_Dad[R] := E_Dad[P];
   E_LSon[R] := E_LSon[P];
   E_RSon[R] := E_RSon[P];
   E_Dad[E_LSon[P]] := R;
   E_Dad[E_RSon[P]] := R;
   If E_RSon[E_Dad[P]] = P Then E_RSon[E_Dad[P]] := R
   Else E_LSon[E_Dad[P]] := R;
   E_Dad[P] := LZ_NIL;
   E_MatchLen := LZ_F;
   E_MatchPos := P;
   Exit;
  End;
  If I > E_MatchLen Then Begin
   E_MatchPos := P;
   E_MatchLen := I;
   If I >= LZ_F Then Break;
  End;
 End;
End;

Procedure LZE_DeleteNode(P: Word);
Var Q: Word;
Begin
 If E_Dad[P] = LZ_NIL Then Exit;
 If E_RSon[P] = LZ_NIL Then Q := E_LSon[P]
 Else If E_LSon[P] = LZ_NIL Then Q := E_RSon[P]
 Else Begin
  Q := E_LSon[P];
  If E_RSon[Q] <> LZ_NIL Then Begin
   Repeat Q := E_RSon[Q]; Until E_RSon[Q] = LZ_NIL;
   E_RSon[E_Dad[Q]] := E_LSon[Q];
   E_Dad[E_LSon[Q]] := E_Dad[Q];
   E_LSon[Q] := E_LSon[P];
   E_Dad[E_LSon[P]] := Q;
  End;
  E_RSon[Q] := E_RSon[P];
  E_Dad[E_RSon[P]] := Q;
 End;
 E_Dad[Q] := E_Dad[P];
 If E_RSon[E_Dad[P]] = P Then E_RSon[E_Dad[P]] := Q
 Else E_LSon[E_Dad[P]] := Q;
 E_Dad[P] := LZ_NIL;
End;

{ ===== Encodeur LH1 complet ========================================== }

Procedure E_LH1(Var Hdr: TLhHdr);
Var
 I, R, S, Len, LastLen: Word;
 C: Byte;
 OK: Boolean;
Begin
 BitInit;
 HuffStartTree;
 LZE_InitTree;

 For I := 0 To LZ_N - LZ_F - 1 Do LZ_Text[I] := $20; { spaces }

 R := LZ_N - LZ_F; S := 0; Len := 0;
 While (Len < LZ_F) Do Begin
  OK := SrcGetByte(C);
  If Not OK Then Break;
  LZ_Text[R + Len] := C;
  UpdCRC(C);
  Inc(Len);
 End;
 If Len = 0 Then Exit;

 For I := 1 To LZ_F Do LZE_InsertNode(R - I);
 LZE_InsertNode(R);

 Repeat
  If E_MatchLen > Len Then E_MatchLen := Len;
  If E_MatchLen <= LZ_THRESHOLD Then Begin
   E_MatchLen := 1;
   EncodeChar(LZ_Text[R]);
  End Else Begin
   EncodeChar(Word(255 - LZ_THRESHOLD) + E_MatchLen);
   EncodePosition((R - E_MatchPos - 1) And (LZ_N - 1));
  End;
  LastLen := E_MatchLen;
  I := 0;
  While I < LastLen Do Begin
   OK := SrcGetByte(C);
   If Not OK Then Break;
   UpdCRC(C);
   LZE_DeleteNode(S);
   LZ_Text[S] := C;
   If S < LZ_F - 1 Then LZ_Text[S + LZ_N] := C;
   S := (S + 1) And (LZ_N - 1);
   R := (R + 1) And (LZ_N - 1);
   LZE_InsertNode(R);
   Inc(I);
  End;
  While I < LastLen Do Begin
   Inc(I);
   LZE_DeleteNode(S);
   S := (S + 1) And (LZ_N - 1);
   R := (R + 1) And (LZ_N - 1);
   If Len > 0 Then Dec(Len);
   If Len > 0 Then LZE_InsertNode(R);
  End;
  If I < LastLen Then Begin
   { source epuisee, finir d'avancer fenetre proprement }
   While I < LastLen Do Begin
    LZE_DeleteNode(S);
    S := (S + 1) And (LZ_N - 1);
    R := (R + 1) And (LZ_N - 1);
    Dec(Len);
    If Len > 0 Then LZE_InsertNode(R);
    Inc(I);
   End;
  End;
 Until Len <= 0;

 FlushPutBits;
End;

{ ===== Decodeur LH1 complet ========================================== }

Procedure D_LH1(CompSize, OrigSize: LongInt);
Var
 I, J, K, R: Word;
 C: Word;
 Count: LongInt;
 InStart: LongInt;
Begin
 GetInit;
 HuffStartTree;
 For I := 0 To LZ_N - LZ_F - 1 Do LZ_Text[I] := $20;
 R := LZ_N - LZ_F;
 Count := 0;
 InStart := InByteCount;

 While Count < OrigSize Do Begin
  If (InByteCount - InStart) > CompSize + 4 Then Break;
  C := DecodeChar;
  If C < 256 Then Begin
   OutPutByte(Byte(C));
   LZ_Text[R] := Byte(C);
   R := (R + 1) And (LZ_N - 1);
   Inc(Count);
  End Else Begin
   I := (R - DecodePosition - 1) And (LZ_N - 1);
   J := C - 255 + LZ_THRESHOLD - 1;
   For K := 0 To J Do Begin
    C := LZ_Text[(I + K) And (LZ_N - 1)];
    OutPutByte(Byte(C));
    LZ_Text[R] := Byte(C);
    R := (R + 1) And (LZ_N - 1);
    Inc(Count);
    If Count >= OrigSize Then Break;
   End;
  End;
 End;
End;

{ ===== Lecture / ecriture en-tete LZH Level-0 ======================== }

Function ReadHeader(Var H: TLhHdr): Boolean;
Var
 HdrLen, Sum, ChkSum: Word;
 I: Word;
 FnLen: Byte;
 Bytes: Array[0..255] of Byte;
 NB: Word;
 ArcSize: LongInt;
Begin
 ReadHeader := False;
 If InEnd Then Exit;
 HdrLen := InGetByte;
 If HdrLen = 0 Then Exit;  { fin d'archive }
 If InEnd Then Exit;
 { Un en-tete Level-0 valide a 22..22+MAX_FN octets de contenu. }
 If (HdrLen < 22) Or (HdrLen > 22 + MAX_FN) Then Begin
  Warn('en-tete invalide (taille ' + LongStr(HdrLen) + ')');
  Warn('format non reconnu (pas une archive ICE/LZH ?)');
  Exit;
 End;
 ChkSum := InGetByte;
 NB := HdrLen;
 For I := 0 To NB - 1 Do Bytes[I] := InGetByte;
 If InEnd Then Begin Warn('en-tete tronque'); Exit; End;
 Sum := 0;
 For I := 0 To NB - 1 Do Sum := (Sum + Bytes[I]) And $FF;
 If (Sum And $FF) <> ChkSum Then Begin
  Warn('checksum entete invalide (pas une archive ICE/LZH ?)');
  Exit;
 End;
 { Parser }
 For I := 1 To 5 Do H.Method[I] := Char(Bytes[I - 1]);
 { Verifier que la methode commence par '-' et finit par '-' }
 If (H.Method[1] <> '-') Or (H.Method[5] <> '-') Then Begin
  Warn('methode invalide : ' + H.Method);
  Exit;
 End;
 H.CompSize := LongInt(Bytes[5]) Or (LongInt(Bytes[6]) Shl 8)
            Or (LongInt(Bytes[7]) Shl 16) Or (LongInt(Bytes[8]) Shl 24);
 H.OrigSize := LongInt(Bytes[9]) Or (LongInt(Bytes[10]) Shl 8)
            Or (LongInt(Bytes[11]) Shl 16) Or (LongInt(Bytes[12]) Shl 24);
 H.TimeStamp := LongInt(Bytes[13]) Or (LongInt(Bytes[14]) Shl 8)
             Or (LongInt(Bytes[15]) Shl 16) Or (LongInt(Bytes[16]) Shl 24);
 H.Attr := Bytes[17];
 H.Level := Bytes[18];
 FnLen := Bytes[19];
 If (Word(FnLen) + 22) > HdrLen Then Begin
  Warn('nom de fichier invalide');
  Exit;
 End;
 H.Name := '';
 For I := 0 To FnLen - 1 Do H.Name := H.Name + Char(Bytes[20 + I]);
 H.CRC := Word(Bytes[20 + FnLen]) Or (Word(Bytes[21 + FnLen]) Shl 8);
 { Verifier coherence avec la taille de l'archive }
 If ArcOpened Then Begin
  ArcSize := FileSize(ArcF);
  If (H.CompSize < 0) Or (H.CompSize > ArcSize) Then Begin
   Warn('taille compressee invalide');
   Exit;
  End;
 End;
 ReadHeader := True;
End;

Procedure WriteHeader(Const H: TLhHdr);
Var
 Buf: Array[0..255] of Byte;
 FnLen: Byte;
 HdrLen, Sum: Word;
 I: Word;
Begin
 FnLen := Length(H.Name);
 If FnLen > MAX_FN Then FnLen := MAX_FN;
 HdrLen := 22 + FnLen;  { taille payload entete = methode...CRC inclus }
 { remplir Buf }
 For I := 1 To 5 Do Buf[I - 1] := Byte(H.Method[I]);
 Buf[5]  := Byte(H.CompSize And $FF);
 Buf[6]  := Byte((H.CompSize Shr 8) And $FF);
 Buf[7]  := Byte((H.CompSize Shr 16) And $FF);
 Buf[8]  := Byte((H.CompSize Shr 24) And $FF);
 Buf[9]  := Byte(H.OrigSize And $FF);
 Buf[10] := Byte((H.OrigSize Shr 8) And $FF);
 Buf[11] := Byte((H.OrigSize Shr 16) And $FF);
 Buf[12] := Byte((H.OrigSize Shr 24) And $FF);
 Buf[13] := Byte(H.TimeStamp And $FF);
 Buf[14] := Byte((H.TimeStamp Shr 8) And $FF);
 Buf[15] := Byte((H.TimeStamp Shr 16) And $FF);
 Buf[16] := Byte((H.TimeStamp Shr 24) And $FF);
 Buf[17] := H.Attr;
 Buf[18] := H.Level;
 Buf[19] := FnLen;
 For I := 1 To FnLen Do Buf[19 + I] := Byte(H.Name[I]);
 Buf[20 + FnLen] := Byte(H.CRC And $FF);
 Buf[21 + FnLen] := Byte((H.CRC Shr 8) And $FF);
 Sum := 0;
 For I := 0 To HdrLen - 1 Do Sum := (Sum + Buf[I]) And $FF;
 WrByte(Byte(HdrLen And $FF));
 WrByte(Byte(Sum And $FF));
 For I := 0 To HdrLen - 1 Do WrByte(Buf[I]);
End;

Procedure WriteEOA;
Begin WrByte(0); End;

{ ===== Skip et copy d'entrees ======================================== }

Procedure SkipEntryData(Var H: TLhHdr);
Var Pos: LongInt;
Begin
 Pos := FilePos(ArcF) - LongInt(InCnt) + LongInt(InPos);
 Seek(ArcF, Pos + H.CompSize);
 InPos := 0; InCnt := 0;
End;

Procedure CopyEntryData(Var H: TLhHdr);
Var I: LongInt; B: Byte;
Begin
 For I := 1 To H.CompSize Do Begin B := InGetByte; WrByte(B); End;
End;

Procedure CopyOneEntry(Var H: TLhHdr);
Begin
 WriteHeader(H);
 CopyEntryData(H);
End;

{ ===== Selection nom ================================================= }

Function NameSelected(Const N: Str255): Boolean;
Var P: PArgNode; Up, UpStripN, Cand: Str255;
Begin
 If ArgCount = 0 Then Begin NameSelected := True; Exit; End;
 Up := UpStr(N);
 UpStripN := UpStr(StripPath(N));
 P := ArgHead;
 While P <> Nil Do Begin
  Cand := UpStr(P^.Name);
  If (Up = Cand) Or (UpStripN = UpStr(StripPath(P^.Name)))
  Then Begin NameSelected := True; Exit; End;
  P := P^.Next;
 End;
 NameSelected := False;
End;

{ ===== Decompression dispatcher ====================================== }

Type TMethodTag = String[5];

Function MethodIs(Const H: TLhHdr; Const S: TMethodTag): Boolean;
Var I: Byte; OK: Boolean;
Begin
 OK := True;
 For I := 1 To 5 Do If H.Method[I] <> S[I] Then OK := False;
 MethodIs := OK;
End;

Procedure D_Stored(CompSize: LongInt);
Var I: LongInt; B: Byte;
Begin
 For I := 1 To CompSize Do Begin B := InGetByte; OutPutByte(B); End;
End;

Function Decompress(Var H: TLhHdr): Boolean;
Var StartBytes, Consumed: LongInt; Skip: LongInt; B: Byte;
Begin
 ResetCRC; OutPos := 0; OutSize := 0;
 StartBytes := InByteCount;
 If MethodIs(H, '-lh0-') Or MethodIs(H, '-lz4-') Then Begin
  D_Stored(H.CompSize); Decompress := True;
 End Else If MethodIs(H, '-lh1-') Or MethodIs(H, '-lz5-') Then Begin
  D_LH1(H.CompSize, H.OrigSize); Decompress := True;
 End Else Begin
  Warn('methode non supportee : ' + H.Method);
  SkipEntryData(H);
  Decompress := False;
  Exit;
 End;
 OutFlush;
 { Aligner sur fin du bloc compresse }
 Consumed := InByteCount - StartBytes;
 If Consumed < H.CompSize Then Begin
  Skip := H.CompSize - Consumed;
  While Skip > 0 Do Begin B := InGetByte; Dec(Skip); If InEnd Then Break; End;
 End;
End;

{ ===== Format date/heure ============================================= }

Procedure FormatDateTime(FT: LongInt; Var DStr, TStr: Str13);
Var DT: DateTime; S: Str13;
Begin
 UnpackTime(FT, DT);
 If DT.Year < 1980 Then DT.Year := 1980;
 Str(DT.Year:4, S); DStr := S + '-';
 Str(DT.Month:2, S); If S[1] = ' ' Then S[1] := '0'; DStr := DStr + S + '-';
 Str(DT.Day:2, S);   If S[1] = ' ' Then S[1] := '0'; DStr := DStr + S;
 Str(DT.Hour:2, S);  If S[1] = ' ' Then S[1] := '0'; TStr := S + ':';
 Str(DT.Min:2, S);   If S[1] = ' ' Then S[1] := '0'; TStr := TStr + S + ':';
 Str(DT.Sec:2, S);   If S[1] = ' ' Then S[1] := '0'; TStr := TStr + S;
End;

{ ===== Commande LIST / VIEW ========================================== }

Procedure CmdList(Verbose: Boolean);
Var
 H: TLhHdr;
 DStr, TStr: Str13;
 Ratio: Word;
 TotO, TotC: LongInt;
 N: Word;
 MStr: String[5];
 I: Byte;
Begin
 WriteLn(' Name           Original   Packed Ratio  Method   Date     Time     CRC');
 WriteLn(' ----------- ---------- ---------- -----  ------ ---------- -------- ----');
 TotO := 0; TotC := 0; N := 0;
 While True Do Begin
  If Not ReadHeader(H) Then Break;
  If NameSelected(H.Name) Then Begin
   FormatDateTime(H.TimeStamp, DStr, TStr);
   If H.OrigSize > 0 Then
    Ratio := Word((LongInt(H.CompSize) * 1000) Div H.OrigSize)
   Else Ratio := 0;
   MStr := '     ';
   For I := 1 To 5 Do MStr[I] := H.Method[I];
   MStr[0] := Char(5);
   If Verbose Then
    WriteLn(' ', PadRight(H.Name, 12), ' ',
           PadLeft(LongStr(H.OrigSize), 10), ' ',
           PadLeft(LongStr(H.CompSize), 10), ' ',
           PadLeft(LongStr(Ratio Div 10) + '.' + Chr(Ord('0') + (Ratio Mod 10)), 5),
           '  ', MStr, ' ', DStr, ' ', TStr, ' ',
           PadLeft(LongStr(H.CRC), 5))
   Else
    WriteLn(' ', PadRight(H.Name, 12), ' ',
           PadLeft(LongStr(H.OrigSize), 10), ' ',
           PadLeft(LongStr(H.CompSize), 10), ' ',
           PadLeft(LongStr(Ratio Div 10) + '.' + Chr(Ord('0') + (Ratio Mod 10)), 5),
           '  ', MStr, ' ', DStr);
   Inc(TotO, H.OrigSize); Inc(TotC, H.CompSize); Inc(N);
   Inc(N_Listed);
  End;
  SkipEntryData(H);
 End;
 WriteLn(' ----------- ---------- ---------- -----  ------ ---------- -------- ----');
 If TotO > 0 Then Ratio := Word((LongInt(TotC) * 1000) Div TotO) Else Ratio := 0;
 WriteLn(' ', PadLeft(LongStr(N), 12), ' ',
        PadLeft(LongStr(TotO), 10), ' ',
        PadLeft(LongStr(TotC), 10), ' ',
        PadLeft(LongStr(Ratio Div 10) + '.' + Chr(Ord('0') + (Ratio Mod 10)), 5));
End;

{ ===== Commande TEST ================================================= }

Procedure CmdTest;
Var H: TLhHdr; StoredCRC: Word; OK: Boolean;
Begin
 OutToStdout := False;
 While True Do Begin
  If Not ReadHeader(H) Then Break;
  If NameSelected(H.Name) Then Begin
   StoredCRC := H.CRC;
   Assign(OutF, 'ICE$$$.TMP'); {$I-} Rewrite(OutF, 1); {$I+}
   If IOResult <> 0 Then Begin
    Warn('impossible de creer fichier temp');
    SkipEntryData(H); Continue;
   End;
   OutFileOpen := True;
   OK := Decompress(H);
   OutFlush;
   Close(OutF);
   Assign(OutF, 'ICE$$$.TMP'); {$I-} Erase(OutF); {$I+} If IOResult <> 0 Then ;
   If OK Then Begin
    If CRC = StoredCRC Then WriteLn('Test : ', H.Name, ' OK')
    Else Begin
     WriteLn('Test : ', H.Name, ' ECHEC (CRC ', CRC, ' vs ', StoredCRC, ')');
     ExitCode_ := 1;
    End;
    Inc(N_Tested);
   End;
  End Else
   SkipEntryData(H);
 End;
End;

{ ===== Commande EXTRACT / PRINT ====================================== }

Procedure CmdExtract(ToStdout: Boolean);
Var H: TLhHdr; OK: Boolean; OutName: Str255;
    StoredCRC: Word; FT: LongInt;
Begin
 While True Do Begin
  If Not ReadHeader(H) Then Break;
  If NameSelected(H.Name) Then Begin
   StoredCRC := H.CRC;
   OutName := StripPath(H.Name);
   If ToStdout Then Begin
    OutToStdout := True; OutFileOpen := False;
   End Else Begin
    OutToStdout := False;
    Assign(OutF, OutName);
    {$I-} Rewrite(OutF, 1); {$I+}
    If IOResult <> 0 Then Begin
     Warn('impossible de creer ' + OutName);
     SkipEntryData(H); Continue;
    End;
    OutFileOpen := True;
   End;
   OK := Decompress(H);
   If (Not ToStdout) And OutFileOpen Then Begin
    FT := H.TimeStamp;
    SetFTime(OutF, FT);
    Close(OutF); OutFileOpen := False;
    If OK And (CRC <> StoredCRC) Then Begin
     Warn(H.Name + ': CRC erreur (' + LongStr(CRC) + ' vs ' + LongStr(StoredCRC) + ')');
     ExitCode_ := 1;
    End;
    If OK Then Begin
     If Not Sw_NoInd Then WriteLn('Extracted : ', H.Name, ' (', H.OrigSize, ' octets)');
     Inc(N_Extracted);
    End;
   End;
  End Else
   SkipEntryData(H);
 End;
End;

{ ===== Compression ==================================================== }

Procedure E_Stored(Var H: TLhHdr);
Var C: Byte;
Begin
 ResetCRC;
 While SrcGetByte(C) Do Begin UpdCRC(C); WrByte(C); End;
 H.CRC := CRC;
End;

Procedure CompressFile(Var H: TLhHdr; Const SrcName: Str255);
Var
 BasePos, TryPos: LongInt;
 FT: LongInt;
 SaveByteCount: LongInt;
Begin
 H.Name := UpStr(StripPath(SrcName));
 Assign(SrcF, SrcName);
 {$I-} Reset(SrcF, 1); {$I+}
 If IOResult <> 0 Then Begin
  Warn('impossible de lire ' + SrcName);
  H.Method := '-lh0-'; H.CompSize := 0; H.OrigSize := 0; Exit;
 End;
 GetFTime(SrcF, FT);
 H.TimeStamp := FT;
 H.Attr := $20;
 H.Level := 0;

 WrFlush;
 BasePos := FilePos(WrF);
 H.Method := '-lh1-'; H.CompSize := 0; H.OrigSize := 0; H.CRC := 0;
 WriteHeader(H);  { placeholder }
 WrFlush;
 TryPos := FilePos(WrF);
 SaveByteCount := WrByteCount;

 SrcReset;
 ResetCRC;
 If Sw_NoLh1 Then Begin
  H.Method := '-lh0-';
  E_Stored(H);
 End Else
  E_LH1(H);

 H.OrigSize := SrcByteRead;
 H.CompSize := WrByteCount - SaveByteCount;
 H.CRC := CRC;
 Close(SrcF);
 WrFlush;

 { Si LH1 gonfle, refaire en LH0 }
 If (Not Sw_NoLh1) And (H.CompSize >= H.OrigSize) Then Begin
  WrFlush;
  Seek(WrF, TryPos);
  WrByteCount := SaveByteCount; WrPos := 0;
  Assign(SrcF, SrcName); Reset(SrcF, 1); SrcReset;
  H.Method := '-lh0-';
  E_Stored(H);
  H.OrigSize := SrcByteRead;
  H.CompSize := WrByteCount - SaveByteCount;
  Close(SrcF);
  WrFlush;
  Truncate(WrF);
 End;

 Seek(WrF, BasePos);
 WriteHeader(H);
 WrFlush;
 Seek(WrF, TryPos + H.CompSize);
End;

{ ===== Commande ADD / UPDATE / FRESHEN / MOVE ======================== }

Procedure CmdAddLike(Mode: Char);
Var
 H, New: TLhHdr;
 P: PArgNode;
 SrcFT, ArcFT: LongInt;
 SrcName: Str255;
 AddIt: Boolean;
 F: File;
 OldMode: Byte;
 MatchNode: PArgNode;
Begin
 P := ArgHead;
 While P <> Nil Do Begin P^.InArc := False; P := P^.Next; End;

 While True Do Begin
  If Not ReadHeader(H) Then Break;
  AddIt := False; SrcName := ''; MatchNode := Nil;
  P := ArgHead;
  While P <> Nil Do Begin
   If UpStr(StripPath(P^.Name)) = UpStr(H.Name) Then Begin
    P^.InArc := True;
    MatchNode := P;
    SrcName := P^.Name;
    Assign(F, SrcName); OldMode := FileMode; FileMode := 0;
    {$I-} Reset(F, 1); {$I+} FileMode := OldMode;
    If IOResult <> 0 Then SrcFT := -1
    Else Begin GetFTime(F, SrcFT); Close(F); End;
    ArcFT := H.TimeStamp;
    Case Mode Of
     'a','m' : AddIt := SrcFT >= 0;
     'u'     : AddIt := (SrcFT >= 0) And ((SrcFT > ArcFT) Or Sw_Compare);
     'f'     : AddIt := (SrcFT >= 0) And ((SrcFT > ArcFT) Or Sw_Compare);
    End;
    Break;
   End;
   P := P^.Next;
  End;
  If MatchNode = Nil Then ;
  If AddIt Then Begin
   SkipEntryData(H);
   FillChar(New, SizeOf(New), 0);
   CompressFile(New, SrcName);
   WriteLn('Remplace : ', New.Name);
   Inc(N_Updated);
  End Else
   CopyOneEntry(H);
 End;

 If (Mode = 'a') Or (Mode = 'm') Or (Mode = 'u') Then Begin
  P := ArgHead;
  While P <> Nil Do Begin
   If Not P^.InArc Then Begin
    Assign(F, P^.Name); OldMode := FileMode; FileMode := 0;
    {$I-} Reset(F, 1); {$I+} FileMode := OldMode;
    If IOResult <> 0 Then Begin
     Warn('aucun fichier ne correspond a : ' + P^.Name);
     ExitCode_ := 1;
    End Else Begin
     Close(F);
     FillChar(New, SizeOf(New), 0);
     CompressFile(New, P^.Name);
     WriteLn('Frozen : ', New.Name);
     P^.InArc := True;
     Inc(N_Added);
    End;
   End;
   P := P^.Next;
  End;
 End;
 WriteEOA;

 If Mode = 'm' Then Begin
  P := ArgHead;
  While P <> Nil Do Begin
   If P^.InArc Then Begin
    Assign(F, P^.Name); {$I-} Erase(F); {$I+} If IOResult = 0 Then ;
   End;
   P := P^.Next;
  End;
 End;
End;

Procedure CmdDelete;
Var H: TLhHdr;
Begin
 While True Do Begin
  If Not ReadHeader(H) Then Break;
  If NameSelected(H.Name) Then Begin
   WriteLn('Suppression : ', H.Name);
   SkipEntryData(H);
   Inc(N_Deleted);
  End Else
   CopyOneEntry(H);
 End;
 WriteEOA;
End;

{ ===== Aide =========================================================== }

Procedure Usage;
Begin
 If Language = 1 Then Begin
  WriteLn('ICE ', Version, ' - High-performance file-compression program from ');
  WriteLn('Haruyasu Yoshizaki 1988-89.');
  WriteLn;
  WriteLn('Usage : LHICE <cmd> [/<sw>...] <archive>[.ICE] [files...]');
  WriteLn;
  WriteLn('Commands :');
  WriteLn('  a   Add files to archive');
  WriteLn('  u   Update files (newer only)');
  WriteLn('  m   Move files into archive (Add + delete source)');
  WriteLn('  f   Freshen files (replace existing newer)');
  WriteLn('  d   Delete files from archive');
  WriteLn('  e/x Extract files from archive');
  WriteLn('  p   disPlay files to standard output');
  WriteLn('  l   List files (short)');
  WriteLn('  v   View list (verbose)');
  WriteLn('  t   Test integrity (CRC check)');
  WriteLn;
  WriteLn('Switches :');
  WriteLn('  /c  skip time-stamp Comparison');
  WriteLn('  /m  no Message for query (yes-to-all)');
  WriteLn('  /n  No Indicator (silent)');
  WriteLn('  /a  Any attribute (include hidden/system)');
  WriteLn('  /x  eXtended file names with directory');
  WriteLn('  /s  Store only (no -lh1- compression)');
 End Else Begin
  WriteLn('ICE ', Version, ' - Cette commande permet de lancer l''outil ',
           'de compression de fichiers haute performance de Haruyasu ',
           'Yoshizaki 1988-89.');
  WriteLn;
  WriteLn('Syntaxe : LHICE <cmd> [/<sw>...] <archive>[.ICE] [fichiers...]');
  WriteLn;
  WriteLn('Commandes :');
  WriteLn('  a   Ajouter des fichiers a l''archive');
  WriteLn('  u   Mettre a jour (seulement les plus recents)');
  WriteLn('  m   Deplacer des fichiers (ajout + suppression source)');
  WriteLn('  f   Rafraichir (remplace seulement si plus recent)');
  WriteLn('  d   Supprimer des fichiers de l''archive');
  WriteLn('  e/x Extraire des fichiers de l''archive');
  WriteLn('  p   Afficher (Print) sur la sortie standard');
  WriteLn('  l   Lister les fichiers (court)');
  WriteLn('  v   Visualiser la liste (detaille)');
  WriteLn('  t   Tester l''integrite (controle CRC)');
  WriteLn;
  WriteLn('Options :');
  WriteLn('  /c  Ignorer la Comparaison de date');
  WriteLn('  /m  Pas de Message de confirmation (oui a tout)');
  WriteLn('  /n  Pas d''indicateur (silencieux)');
  WriteLn('  /a  N''importe quel Attribut (inclure caches/systeme)');
  WriteLn('  /x  Noms de fichiers eXtensifs avec repertoire');
  WriteLn('  /s  Stocker uniquement (pas de compression -lh1-)');
 End;
End;

{ ===== Analyse ligne de commande ===================================== }

Procedure AddArg(Const S: Str255);
Var P: PArgNode;
Begin
 New(P);
 P^.Name := S; P^.InArc := False; P^.Next := Nil;
 If ArgHead = Nil Then ArgHead := P Else ArgTail^.Next := P;
 ArgTail := P;
 Inc(ArgCount);
End;

Procedure FreeArgList;
Var P, Q: PArgNode;
Begin
 P := ArgHead;
 While P <> Nil Do Begin Q := P^.Next; Dispose(P); P := Q; End;
 ArgHead := Nil; ArgTail := Nil; ArgCount := 0;
End;

Procedure ParseCmdLine;
Var
 I: Word; S: Str255; J: Byte;
Begin
 ArgCount := 0; ArgHead := Nil; ArgTail := Nil;
 Cmd := #0;
 Sw_Compare := False; Sw_NoMsg := False; Sw_NoInd := False;
 Sw_AnyAttr := False; Sw_ExtName := False; Sw_NoLh1 := False;
 ArchiveName := '';
 If ParamCount < 1 Then Begin Usage; Halt(0); End;
 For I := 1 To ParamCount Do Begin
  S := ParamStr(I);
  If (Length(S) > 0) And ((S[1] = '/') Or (S[1] = '-')) Then Begin
   For J := 2 To Length(S) Do
    Case UpCase(S[J]) Of
     'C' : Sw_Compare := True;
     'M' : Sw_NoMsg   := True;
     'N' : Sw_NoInd   := True;
     'A' : Sw_AnyAttr := True;
     'X' : Sw_ExtName := True;
     'S' : Sw_NoLh1   := True;
    End;
   Continue;
  End;
  If Cmd = #0 Then Begin
   If Length(S) >= 1 Then Cmd := UpCase(S[1]);
   Continue;
  End;
  If ArchiveName = '' Then Begin
   ArchiveName := S;
   If Not HasExt(ArchiveName) Then ArchiveName := ArchiveName + ARC_EXT;
   Continue;
  End;
  If ArgCount < MAX_NAMES Then AddArg(S);
 End;
 If ArchiveName = '' Then Begin Usage; Halt(0); End;
End;

{ ===== Init / cleanup ================================================ }

Procedure InitBuffers;
Begin New(InBuf); New(OutBuf); New(SrcBuf); New(WrBuf); End;

Procedure DoneBuffers;
Begin Dispose(InBuf); Dispose(OutBuf); Dispose(SrcBuf); Dispose(WrBuf); End;

Procedure OpenArc;
Begin
 Assign(ArcF, ArchiveName);
 {$I-} Reset(ArcF, 1); {$I+}
 If IOResult <> 0 Then Begin
  ArcOpened := False; InResetCounters; InEnd := True; Exit;
 End;
 ArcOpened := True; InResetCounters;
End;

Procedure CloseArc;
Begin If ArcOpened Then Begin Close(ArcF); ArcOpened := False; End; End;

Procedure OpenWriteArc(Const N: Str255);
Begin
 Assign(WrF, N);
 {$I-} Rewrite(WrF, 1); {$I+}
 If IOResult <> 0 Then Die('impossible de creer ' + N);
 WrPos := 0; WrByteCount := 0;
End;

Procedure CloseWriteArc;
Begin WrFlush; Close(WrF); End;

{ ===== Main =========================================================== }

Procedure RunCommand;
Var I: Integer;
Begin
 OpenArc;
 If (Not ArcOpened) And
    (Cmd <> 'A') And (Cmd <> 'M') And (Cmd <> 'U') Then
  Die('impossible d''ouvrir ' + ArchiveName);
 Case Cmd Of
  'L' : CmdList(False);
  'V' : CmdList(True);
  'X','E' : CmdExtract(False);
  'P' : Begin Sw_NoInd := True; CmdExtract(True); End;
  'T' : CmdTest;
  'A','M','U','F','D' :
   Begin
    TmpArcName := ArchiveName + '.$$$';
    OpenWriteArc(TmpArcName);
    Case Cmd Of
     'D' : CmdDelete;
    Else CmdAddLike(Char(Ord(Cmd) + 32));
    End;
    CloseWriteArc;
    CloseArc;
    Assign(ArcF, ArchiveName); {$I-} Erase(ArcF); {$I+} I := IOResult;
    Assign(WrF, TmpArcName); Rename(WrF, ArchiveName);
    OpenArc;
    I := I;
   End;
 Else
  Begin
   If Cmd = #0 Then CmdList(False)
   Else Die('commande inconnue : ' + Cmd);
  End;
 End;
 CloseArc;
End;

Var
 EnvL: String;
BEGIN
 Language := 0;
 EnvL := GetEnv('LANGUAGE');
 If Length(EnvL) >= 2 Then
  If (UpCase(EnvL[1]) = 'E') And (UpCase(EnvL[2]) = 'N') Then Language := 1;

 ExitCode_ := 0;
 ParseCmdLine;
 InitBuffers;
 RunCommand;

 If Not Sw_NoInd Then Begin
  If N_Added > 0 Then WriteLn(N_Added, ' fichier(s) ajoute(s)');
  If N_Updated > 0 Then WriteLn(N_Updated, ' fichier(s) mis a jour');
  If N_Deleted > 0 Then WriteLn(N_Deleted, ' fichier(s) supprime(s)');
  If N_Extracted > 0 Then WriteLn(N_Extracted, ' fichier(s) extrait(s)');
  If N_Tested > 0 Then WriteLn(N_Tested, ' fichier(s) testes');
 End;
 DoneBuffers;
 FreeArgList;
 Halt(ExitCode_);
END.
