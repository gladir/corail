{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

{ ARC.PAS - Clone de la commande ARC de SEA (System Enhancement Associates) }
{ Supporte le vrai format .ARC : methodes 1..9 en decompression,            }
{ methodes 2 (store), 3 (pack/RLE) et 8 (crunch/LZW) en compression.        }
{                                                                            }
{ Format du header par entree :                                              }
{   1 octet  : marqueur $1A                                                  }
{   1 octet  : methode (0=fin, 1..9)                                         }
{   13 octets: nom de fichier (NUL-termine)                                  }
{   4 octets : taille compressee (LongInt LE)                                }
{   2 octets : date DOS                                                      }
{   2 octets : heure DOS                                                     }
{   2 octets : CRC-16 (poly $A001)                                           }
{   4 octets : taille originale (LongInt LE) -- absent si methode=1          }
{                                                                            }
{ Methodes :                                                                 }
{   1 = Stored (ancien, sans champ OrigSize)                                 }
{   2 = Stored                                                               }
{   3 = Packed (RLE avec DLE = $90)                                          }
{   4 = Squeezed (RLE + Huffman statique)                                    }
{   5 = crunched (LZW statique 12 bits, sans RLE)                            }
{   6 = crunched (LZW statique 12 bits, avec RLE)                            }
{   7 = crunched (LZW statique 12 bits, hash rapide)                         }
{   8 = Crunched (LZW dynamique 9-12 bits + RLE)                             }
{   9 = Squashed (LZW dynamique 9-13 bits, sans RLE)                         }

Program ARC;

{$IFDEF FPC}
 {$MODE TP}
{$ENDIF}
{$R-,S-,I-,V-,B-}

Uses Dos;

Const
 Version       = '1.0';
 ARC_MARK      = $1A;
 DLE_MARK      = $90;

 M_END    = 0;
 M_OLD    = 1;
 M_STORE  = 2;
 M_PACK   = 3;
 M_SQ     = 4;
 M_CR5    = 5;
 M_CR6    = 6;
 M_CR7    = 7;
 M_CR8    = 8;
 M_SQUASH = 9;

 IOBUFSZ  = 4096;

 LZW_INIT_BITS    = 9;
 LZW_FIRST_CODE   = 257;
 LZW_CLEAR        = 256;
 LZW_MAX_CR       = 12;
 LZW_MAX_SQUASH   = 13;
 LZW_TBLSZ_CR     = 4096;
 LZW_TBLSZ_SQUASH = 8192;

Type
 {$IFNDEF FPC}
  SmallInt=Integer;
 {$ENDIF}
 Str13  = String[13];
 Str80  = String[80];
 Str255 = String[255];

 PIOBuf = ^TIOBuf;
 TIOBuf = Array[0..IOBUFSZ-1] of Byte;

 PLZWPrefix = ^TLZWPrefix;
 TLZWPrefix = Array[0..LZW_TBLSZ_SQUASH-1] of Word;
 PLZWSuffix = ^TLZWSuffix;
 TLZWSuffix = Array[0..LZW_TBLSZ_SQUASH-1] of Byte;
 PLZWStack  = ^TLZWStack;
 TLZWStack  = Array[0..LZW_TBLSZ_SQUASH-1] of Byte;

 PCRCTab = ^TCRCTab;
 TCRCTab = Array[0..255] of Word;

 TFileHdr = Record
  Method   : Byte;
  Name     : Str13;
  CompSize : LongInt;
  Date     : Word;
  Time     : Word;
  CRC      : Word;
  OrigSize : LongInt;
 End;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 { Switches }
 Sw_Backup, Sw_Store, Sw_NoWarn, Sw_NoNote : Boolean;
 Sw_Crypt : Boolean;
 Password : Str80;

 { CRC }
 CRCTab : PCRCTab;
 CRC    : Word;

 { Compteurs }
 N_Added, N_Updated, N_Deleted, N_Extracted, N_Tested : Word;

 { Buffers I/O (sur le tas) }
 InBuf, OutBuf : PIOBuf;
 InPos, InCnt, OutPos : Word;
 InEnd : Boolean;
 InByteCount : LongInt;

 { Cipher state }
 CryptIdx : Word;

 { LZW state (sur le tas) }
 LZW_Prefix : PLZWPrefix;
 LZW_Suffix : PLZWSuffix;
 LZW_Stack  : PLZWStack;
 LZW_StackP : Word;
 LZW_Bits   : Byte;
 LZW_MaxBits: Byte;
 LZW_MaxCode: LongInt;
 LZW_TblSz  : LongInt;
 LZW_NextCode: LongInt;
 LZW_PrevCode: LongInt;
 LZW_FinChar: Byte;
 LZW_BitBuf : LongInt;
 LZW_BitCnt : Byte;
 LZW_First  : Boolean;

 { RLE state (decode) }
 RLE_LastByte : Byte;
 RLE_State    : Byte;  { 0=normal, 1=after DLE, 2=have count }
 RLE_Count    : Byte;

 { Squeeze (method 4) }
 SQ_NodeL : Array[0..256] of Integer;
 SQ_NodeR : Array[0..256] of Integer;
 SQ_NumNodes : Integer;
 SQ_BitBuf : Word;
 SQ_BitCnt : Byte;
 SQ_EOF    : Boolean;

 { Pour ecrire }
 WriteOutBuf : PIOBuf;
 WriteOutPos : Word;

{ ===== Utilitaires generaux ============================================ }

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;


Procedure Die(Const Msg: Str255);
Begin
 WriteLn('ARC: ', Msg);
 Halt(1);
End;

Procedure Warn(Const Msg: Str255);
Begin
 If Not Sw_NoWarn Then WriteLn('ARC: warning: ', Msg);
End;

Procedure Note(Const Msg: Str255);
Begin
 If Not Sw_NoNote Then WriteLn('ARC: ', Msg);
End;

Function UpStr(Const S: Str255): Str255;
Var I: Byte; R: Str255;
Begin R := S; For I := 1 To Length(R) Do R[I] := UpCase(R[I]); UpStr := R; End;

Function StripPath(Const S: Str255): Str255;
Var I: Integer;
Begin
 For I := Length(S) DownTo 1 Do
  If (S[I]='\') Or (S[I]='/') Or (S[I]=':') Then Begin
   StripPath := Copy(S, I+1, 255); Exit;
  End;
 StripPath := S;
End;

Function LongStr(L: LongInt): Str13;
Var S: Str13;
Begin Str(L, S); LongStr := S; End;

Function PadLeft(Const S: Str80; W: Byte): Str80;
Var R: Str80;
Begin
 R := S;
 While Length(R) < W Do R := ' ' + R;
 PadLeft := R;
End;

Function PadRight(Const S: Str80; W: Byte): Str80;
Var R: Str80;
Begin
 R := S;
 While Length(R) < W Do R := R + ' ';
 PadRight := R;
End;

Function Min(A, B: LongInt): LongInt;
Begin If A < B Then Min := A Else Min := B; End;

{ ===== CRC-16 (poly $A001) ============================================= }

Procedure InitCRCTab;
Var I, J: Word; C: Word;
Begin
 New(CRCTab);
 For I := 0 To 255 Do Begin
  C := I;
  For J := 0 To 7 Do
   If (C And 1) <> 0 Then C := (C Shr 1) Xor $A001
                     Else C := C Shr 1;
  CRCTab^[I] := C;
 End;
End;

Procedure UpdCRC(B: Byte);
Begin
 CRC := (CRC Shr 8) Xor CRCTab^[(CRC Xor B) And $FF];
End;

Procedure ResetCRC; Begin CRC := 0; End;

{ ===== I/O bas niveau avec optionnel chiffrement ======================= }

Var
 ArcF : File;
 ArcOpened : Boolean;

Procedure CryptByte(Var B: Byte);
Begin
 If Sw_Crypt And (Length(Password) > 0) Then Begin
  B := B Xor Byte(Password[(CryptIdx Mod Length(Password)) + 1]);
  Inc(CryptIdx);
 End;
End;

Procedure ResetCrypt; Begin CryptIdx := 0; End;

Procedure InResetCounters;
Begin
 InPos := 0; InCnt := 0; InEnd := False; InByteCount := 0;
End;

Procedure InRefill;
Var R: Word;
Begin
 BlockRead(ArcF, InBuf^, IOBUFSZ, R);
 InCnt := R;
 InPos := 0;
 If R = 0 Then InEnd := True;
End;

Function InGetByte: Byte;
Var B: Byte;
Begin
 If InEnd Then Begin InGetByte := 0; Exit; End;
 If InPos >= InCnt Then InRefill;
 If InEnd Then Begin InGetByte := 0; Exit; End;
 B := InBuf^[InPos]; Inc(InPos); Inc(InByteCount);
 CryptByte(B);
 InGetByte := B;
End;

{ Lecture sans chiffrement (pour entete) }
Function InGetByteRaw: Byte;
Begin
 If InEnd Then Begin InGetByteRaw := 0; Exit; End;
 If InPos >= InCnt Then InRefill;
 If InEnd Then Begin InGetByteRaw := 0; Exit; End;
 InGetByteRaw := InBuf^[InPos]; Inc(InPos);
End;

Function InGetWord: Word;
Var L, H: Byte;
Begin L := InGetByteRaw; H := InGetByteRaw; InGetWord := L Or (Word(H) Shl 8); End;

Function InGetLong: LongInt;
Var B0, B1, B2, B3: Byte;
Begin
 B0 := InGetByteRaw; B1 := InGetByteRaw;
 B2 := InGetByteRaw; B3 := InGetByteRaw;
 InGetLong := LongInt(B0) Or (LongInt(B1) Shl 8) Or
              (LongInt(B2) Shl 16) Or (LongInt(B3) Shl 24);
End;

{ ===== Sortie ========================================================== }

Var
 OutF : File;
 OutFile_Open : Boolean;
 OutSize : LongInt;
 OutToStdout : Boolean;

Procedure FlushOut;
Var I: Word;
Begin
 If OutPos = 0 Then Exit;
 If OutToStdout Then Begin
  For I := 0 To OutPos - 1 Do Write(Chr(OutBuf^[I]));
 End Else If OutFile_Open Then
  BlockWrite(OutF, OutBuf^, OutPos);
 OutPos := 0;
End;

Procedure OutPutByte(B: Byte);
Begin
 If OutPos >= IOBUFSZ Then FlushOut;
 OutBuf^[OutPos] := B; Inc(OutPos);
 Inc(OutSize);
 UpdCRC(B);
End;

{ ===== Decompression : methode 1 et 2 (stored) ========================== }

Procedure D_Stored(Size: LongInt);
Var I: LongInt;
Begin
 For I := 1 To Size Do OutPutByte(InGetByte);
End;

{ ===== RLE (DLE = $90) =================================================
  Sequence:
   octet != $90 -> sortie directe, dernier_octet = octet
   $90 puis 0  -> sortie litterale $90
   $90 puis n (n>=2) -> repeter dernier_octet (n-1) fois supplementaire
  Le decodeur traite cela transparentement.                                }

Procedure RLEReset;
Begin RLE_LastByte := 0; RLE_State := 0; End;

Procedure RLEPutByte(B: Byte);
Begin
 Case RLE_State Of
  0: Begin
      If B = DLE_MARK Then RLE_State := 1
      Else Begin OutPutByte(B); RLE_LastByte := B; End;
     End;
  1: Begin
      If B = 0 Then Begin
       OutPutByte(DLE_MARK); RLE_LastByte := DLE_MARK;
       RLE_State := 0;
      End Else Begin
       { repeter RLE_LastByte (B-1) fois }
       While B > 1 Do Begin OutPutByte(RLE_LastByte); Dec(B); End;
       RLE_State := 0;
      End;
     End;
 End;
End;

{ Methode 3 : RLE pur }
Procedure D_Pack(CompSize: LongInt);
Var I: LongInt;
Begin
 RLEReset;
 For I := 1 To CompSize Do RLEPutByte(InGetByte);
End;

{ ===== Methode 4 : Squeezed (RLE + Huffman statique) =================== }

Function SQ_GetBit: Byte;
Var B: Byte;
Begin
 If SQ_BitCnt = 0 Then Begin
  SQ_BitBuf := InGetByte;
  SQ_BitCnt := 8;
 End;
 B := SQ_BitBuf And 1;
 SQ_BitBuf := SQ_BitBuf Shr 1;
 Dec(SQ_BitCnt);
 SQ_GetBit := B;
End;

Function SQ_DecodeSym: Integer;
Var Node: Integer;
Begin
 Node := 0;
 While Node >= 0 Do Begin
  If SQ_GetBit = 0 Then Node := SQ_NodeL[Node]
                   Else Node := SQ_NodeR[Node];
 End;
 SQ_DecodeSym := -(Node + 1);
End;

Procedure D_Squeeze(CompSize: LongInt);
Var I: Integer; Sym: Integer; LowB, HighB: Byte;
Begin
 SQ_BitBuf := 0; SQ_BitCnt := 0; SQ_EOF := False;
 RLEReset;
 { Lire l'entete du squeeze : nombre de noeuds (Word LE) }
 LowB := InGetByte; HighB := InGetByte;
 SQ_NumNodes := LowB Or (Integer(HighB) Shl 8);
 If (SQ_NumNodes < 0) Or (SQ_NumNodes > 257) Then Begin
  Warn('arbre squeeze invalide');
  Exit;
 End;
 For I := 0 To SQ_NumNodes - 1 Do Begin
  LowB := InGetByte; HighB := InGetByte;
  SQ_NodeL[I] := SmallInt(Word(LowB) Or (Word(HighB) Shl 8));
  LowB := InGetByte; HighB := InGetByte;
  SQ_NodeR[I] := SmallInt(Word(LowB) Or (Word(HighB) Shl 8));
 End;
 { Decoder symboles jusqu'a EOF (sym=256) }
 Repeat
  Sym := SQ_DecodeSym;
  If Sym = 256 Then Break;
  If (Sym >= 0) And (Sym <= 255) Then RLEPutByte(Sym);
 Until False;
End;

{ ===== Methodes 5/6/7/8/9 : LZW ========================================
  Methodes 5,6,7 : LZW statique 12 bits.
  Methodes 8,9   : LZW dynamique 9..maxbits bits.
  Methodes 6,7,8 : passent par RLE en sortie. 5,9 : non.                  }

Procedure LZW_InitState(MaxBits: Byte);
Var I: LongInt;
Begin
 LZW_MaxBits := MaxBits;
 LZW_MaxCode := (LongInt(1) Shl MaxBits) - 1;
 LZW_TblSz := LongInt(1) Shl MaxBits;
 LZW_Bits := LZW_INIT_BITS;
 LZW_NextCode := LZW_FIRST_CODE;
 LZW_BitBuf := 0;
 LZW_BitCnt := 0;
 LZW_StackP := 0;
 LZW_First := True;
 LZW_PrevCode := 0;
 LZW_FinChar := 0;
 For I := 0 To 255 Do Begin
  LZW_Prefix^[I] := 0;
  LZW_Suffix^[I] := I;
 End;
End;

Function LZW_ReadCode: LongInt;
Var C: LongInt;
Begin
 While LZW_BitCnt < LZW_Bits Do Begin
  LZW_BitBuf := LZW_BitBuf Or (LongInt(InGetByte) Shl LZW_BitCnt);
  Inc(LZW_BitCnt, 8);
 End;
 C := LZW_BitBuf And ((LongInt(1) Shl LZW_Bits) - 1);
 LZW_BitBuf := LZW_BitBuf Shr LZW_Bits;
 Dec(LZW_BitCnt, LZW_Bits);
 LZW_ReadCode := C;
End;

Procedure LZW_OutByteDispatch(B: Byte; UseRLE: Boolean);
Begin
 If UseRLE Then RLEPutByte(B) Else OutPutByte(B);
End;

{ Decompression LZW generique. UseRLE = vrai pour 6,7,8 ; faux pour 5,9.
  Static = vrai pour 5,6,7 (12 bits fixe, table statique sans extension de
  largeur de code) ; faux pour 8,9 (largeur dynamique 9..maxbits).         }
Procedure D_LZW(MaxBits: Byte; UseRLE, StaticBits: Boolean);
Var
 Code, InCode: LongInt;
 K: Byte;
 I: Word;
Begin
 LZW_InitState(MaxBits);
 If UseRLE Then RLEReset;
 If StaticBits Then LZW_Bits := MaxBits;

 While Not InEnd Do Begin
  Code := LZW_ReadCode;
  If InEnd Then Break;
  If Code = LZW_CLEAR Then Begin
   { Reset (rare en ARC) }
   LZW_NextCode := LZW_FIRST_CODE;
   If Not StaticBits Then LZW_Bits := LZW_INIT_BITS;
   LZW_First := True;
   Continue;
  End;

  If LZW_First Then Begin
   LZW_First := False;
   If (Code >= 0) And (Code <= 255) Then Begin
    LZW_OutByteDispatch(Code, UseRLE);
    LZW_PrevCode := Code;
    LZW_FinChar := Code;
   End;
   Continue;
  End;

  InCode := Code;
  If Code >= LZW_NextCode Then Begin
   { KwKwK case }
   LZW_Stack^[LZW_StackP] := LZW_FinChar; Inc(LZW_StackP);
   Code := LZW_PrevCode;
  End;

  While Code > 255 Do Begin
   If LZW_StackP >= LZW_TblSz Then Begin
    Warn('flux LZW corrompu'); Exit;
   End;
   LZW_Stack^[LZW_StackP] := LZW_Suffix^[Code]; Inc(LZW_StackP);
   Code := LZW_Prefix^[Code];
  End;
  K := LZW_Suffix^[Code];
  LZW_FinChar := K;
  LZW_OutByteDispatch(K, UseRLE);
  While LZW_StackP > 0 Do Begin
   Dec(LZW_StackP);
   LZW_OutByteDispatch(LZW_Stack^[LZW_StackP], UseRLE);
  End;

  { Ajouter au dictionnaire }
  If LZW_NextCode < LZW_TblSz Then Begin
   LZW_Prefix^[LZW_NextCode] := LZW_PrevCode;
   LZW_Suffix^[LZW_NextCode] := K;
   Inc(LZW_NextCode);
   If (Not StaticBits) And (LZW_NextCode = (LongInt(1) Shl LZW_Bits))
      And (LZW_Bits < LZW_MaxBits) Then
    Inc(LZW_Bits);
  End;
  LZW_PrevCode := InCode;
 End;
End;

{ ===== Dispatcher de decompression ===================================== }

Function Decompress(Var Hdr: TFileHdr): Boolean;
Var CountStart, CountEnd : LongInt;
Begin
 ResetCRC;
 OutPos := 0;
 OutSize := 0;
 RLEReset;
 ResetCrypt;
 CountStart := InByteCount;
 Decompress := True;

 Case Hdr.Method Of
  M_OLD, M_STORE : D_Stored(Hdr.CompSize);
  M_PACK         : D_Pack(Hdr.CompSize);
  M_SQ           : D_Squeeze(Hdr.CompSize);
  M_CR5          : D_LZW(LZW_MAX_CR, False, True);
  M_CR6, M_CR7   : D_LZW(LZW_MAX_CR, True,  True);
  M_CR8          : D_LZW(LZW_MAX_CR, True,  False);
  M_SQUASH       : D_LZW(LZW_MAX_SQUASH, False, False);
 Else
  Warn('methode inconnue : ' + LongStr(Hdr.Method));
  Decompress := False;
 End;

 { Sauter le reste eventuel des octets compresses pour les methodes LZW
   qui peuvent ne pas consommer le flux exactement }
 CountEnd := InByteCount;
 While (CountEnd - CountStart) < Hdr.CompSize Do Begin
  InGetByteRaw;
  Inc(CountEnd);
 End;
 FlushOut;
End;

{ ===== Lecture du header ARC =========================================== }

Function ReadHeader(Var Hdr: TFileHdr): Boolean;
Var Mark, M, B: Byte; I: Byte;
Begin
 ReadHeader := False;
 Mark := InGetByteRaw;
 If InEnd Then Exit;
 If Mark <> ARC_MARK Then Begin
  Warn('marqueur ARC absent (' + LongStr(Mark) + ')');
  Exit;
 End;
 M := InGetByteRaw;
 Hdr.Method := M;
 If M = M_END Then Begin ReadHeader := True; Exit; End;
 If M > M_SQUASH Then Begin
  Warn('methode non supportee : ' + LongStr(M));
  Exit;
 End;

 Hdr.Name := '';
 For I := 0 To 12 Do Begin
  B := InGetByteRaw;
  If (B <> 0) And (Length(Hdr.Name) < 13) Then
   Hdr.Name := Hdr.Name + Char(B);
 End;
 Hdr.CompSize := InGetLong;
 Hdr.Date     := InGetWord;
 Hdr.Time     := InGetWord;
 Hdr.CRC      := InGetWord;
 If M = M_OLD Then Hdr.OrigSize := Hdr.CompSize
              Else Hdr.OrigSize := InGetLong;
 ReadHeader := True;
End;

{ ===== Ecriture du header ARC ========================================== }

Procedure WriteByteToArc(B: Byte; Var OutPosL: Word; ArcOut: PIOBuf);
Var Tmp: Byte;
Begin
 Tmp := B; CryptByte(Tmp);  { Note : ne sera applique que sur donnees, voir WriteData }
 ArcOut^[OutPosL] := B; Inc(OutPosL);
End;

Var
 WrF : File;
 WrBuf : PIOBuf;
 WrPos : Word;
 WrByteCount : LongInt;
 WrCryptIdx : Word;
 WrCryptOn  : Boolean;

Procedure WrFlush;
Begin
 If WrPos > 0 Then Begin
  BlockWrite(WrF, WrBuf^, WrPos);
  WrPos := 0;
 End;
End;

Procedure WrByte(B: Byte);
Begin
 If WrPos >= IOBUFSZ Then WrFlush;
 WrBuf^[WrPos] := B; Inc(WrPos); Inc(WrByteCount);
End;

Procedure WrByteCipher(B: Byte);
Begin
 If WrCryptOn And (Length(Password) > 0) Then Begin
  B := B Xor Byte(Password[(WrCryptIdx Mod Length(Password)) + 1]);
  Inc(WrCryptIdx);
 End;
 WrByte(B);
End;

Procedure WrWord(W: Word); Begin WrByte(W And $FF); WrByte((W Shr 8) And $FF); End;
Procedure WrLong(L: LongInt);
Begin
 WrByte(Byte(L And $FF));
 WrByte(Byte((L Shr 8) And $FF));
 WrByte(Byte((L Shr 16) And $FF));
 WrByte(Byte((L Shr 24) And $FF));
End;

Procedure WriteHeader(Const Hdr: TFileHdr);
Var I: Byte; C: Char; NameOut: Str13;
Begin
 WrByte(ARC_MARK);
 WrByte(Hdr.Method);
 NameOut := UpStr(Hdr.Name);
 If Length(NameOut) > 12 Then NameOut[0] := Char(12);
 For I := 1 To Length(NameOut) Do Begin
  C := NameOut[I];
  WrByte(Ord(C));
 End;
 For I := Length(NameOut) + 1 To 13 Do WrByte(0);
 WrLong(Hdr.CompSize);
 WrWord(Hdr.Date);
 WrWord(Hdr.Time);
 WrWord(Hdr.CRC);
 If Hdr.Method <> M_OLD Then WrLong(Hdr.OrigSize);
End;

Procedure WriteEOA;
Begin
 WrByte(ARC_MARK); WrByte(M_END);
End;

{ ===== Compression : methode 2 (stored) ================================ }

Var
 Src : File;
 SrcBuf : PIOBuf;
 SrcPos, SrcCnt : Word;
 SrcEnd : Boolean;

Procedure SrcReset;
Begin SrcPos := 0; SrcCnt := 0; SrcEnd := False; End;

Procedure SrcRefill;
Var R: Word;
Begin
 BlockRead(Src, SrcBuf^, IOBUFSZ, R);
 SrcCnt := R; SrcPos := 0;
 If R = 0 Then SrcEnd := True;
End;

Function SrcGetByte(Var B: Byte): Boolean;
Begin
 If SrcPos >= SrcCnt Then SrcRefill;
 If SrcEnd Then Begin SrcGetByte := False; Exit; End;
 B := SrcBuf^[SrcPos]; Inc(SrcPos);
 SrcGetByte := True;
End;

Procedure E_Store(Var Hdr: TFileHdr);
Var B: Byte;
Begin
 Hdr.Method := M_STORE;
 Hdr.CompSize := 0;
 ResetCRC;
 SrcReset;
 While SrcGetByte(B) Do Begin
  UpdCRC(B);
  WrByteCipher(B);
  Inc(Hdr.CompSize);
 End;
 Hdr.CRC := CRC;
 Hdr.OrigSize := Hdr.CompSize;
End;

{ ===== Compression : methode 3 (Packed/RLE) ============================ }

Var
 RLEEnc_Last : Byte;
 RLEEnc_Run  : Word;
 RLEEnc_HasLast : Boolean;

Procedure RLEEncReset;
Begin RLEEnc_HasLast := False; RLEEnc_Run := 0; RLEEnc_Last := 0; End;

Procedure RLEEncEmit(Var Hdr: TFileHdr);
Var Cnt: Word;
Begin
 If Not RLEEnc_HasLast Then Exit;
 If (RLEEnc_Run < 4) And (RLEEnc_Last <> DLE_MARK) Then Begin
  { Emettre tel quel }
  Cnt := RLEEnc_Run;
  While Cnt > 0 Do Begin
   UpdCRC(RLEEnc_Last);
   WrByteCipher(RLEEnc_Last);
   Inc(Hdr.CompSize);
   Dec(Cnt);
  End;
 End Else Begin
  { Emettre 1 fois (sauf si Last == DLE) + DLE + count }
  If RLEEnc_Last <> DLE_MARK Then Begin
   UpdCRC(RLEEnc_Last);
   WrByteCipher(RLEEnc_Last);
   Inc(Hdr.CompSize);
  End;
  UpdCRC(DLE_MARK); WrByteCipher(DLE_MARK); Inc(Hdr.CompSize);
  UpdCRC(Byte(RLEEnc_Run And $FF)); WrByteCipher(Byte(RLEEnc_Run And $FF));
  Inc(Hdr.CompSize);
 End;
End;

Procedure E_Pack(Var Hdr: TFileHdr);
Var B: Byte;
Begin
 Hdr.Method := M_PACK;
 Hdr.CompSize := 0;
 Hdr.OrigSize := 0;
 ResetCRC;
 SrcReset;
 RLEEncReset;

 While SrcGetByte(B) Do Begin
  Inc(Hdr.OrigSize);
  { Cas special : DLE litteral => emit RLE_LastByte run, puis DLE+0 }
  If B = DLE_MARK Then Begin
   RLEEncEmit(Hdr);
   RLEEnc_HasLast := False;
   UpdCRC(DLE_MARK); WrByteCipher(DLE_MARK); Inc(Hdr.CompSize);
   UpdCRC(0); WrByteCipher(0); Inc(Hdr.CompSize);
   Continue;
  End;
  If RLEEnc_HasLast And (B = RLEEnc_Last) And (RLEEnc_Run < 255) Then
   Inc(RLEEnc_Run)
  Else Begin
   RLEEncEmit(Hdr);
   RLEEnc_Last := B;
   RLEEnc_Run := 1;
   RLEEnc_HasLast := True;
  End;
 End;
 RLEEncEmit(Hdr);
 Hdr.CRC := CRC;
End;

{ ===== Compression : methode 8 (Crunched LZW 9..12 + RLE) ==============
  On passe la source par RLE-encode puis on alimente un LZW dynamique.    }

Const
 LZWENC_HASHSIZE = 5003;   { premier > 4096 * 1.2 }

Var
 LZWE_Hash : Array[0..LZWENC_HASHSIZE-1] of LongInt;
 LZWE_Code : Array[0..LZWENC_HASHSIZE-1] of Word;
 LZWE_FreeEnt : LongInt;
 LZWE_Ent     : LongInt;
 LZWE_BitBuf  : LongInt;
 LZWE_BitCnt  : Byte;
 LZWE_Bits    : Byte;
 LZWE_MaxBits : Byte;
 LZWE_MaxCode : LongInt;
 LZWE_First   : Boolean;

Procedure LZWE_OutBits(Code: LongInt; Var Hdr: TFileHdr);
Begin
 LZWE_BitBuf := LZWE_BitBuf Or (Code Shl LZWE_BitCnt);
 Inc(LZWE_BitCnt, LZWE_Bits);
 While LZWE_BitCnt >= 8 Do Begin
  UpdCRC(Byte(LZWE_BitBuf And $FF));
  WrByteCipher(Byte(LZWE_BitBuf And $FF));
  Inc(Hdr.CompSize);
  LZWE_BitBuf := LZWE_BitBuf Shr 8;
  Dec(LZWE_BitCnt, 8);
 End;
End;

Procedure LZWE_FlushBits(Var Hdr: TFileHdr);
Begin
 While LZWE_BitCnt > 0 Do Begin
  UpdCRC(Byte(LZWE_BitBuf And $FF));
  WrByteCipher(Byte(LZWE_BitBuf And $FF));
  Inc(Hdr.CompSize);
  LZWE_BitBuf := LZWE_BitBuf Shr 8;
  If LZWE_BitCnt < 8 Then LZWE_BitCnt := 0 Else Dec(LZWE_BitCnt, 8);
 End;
End;

Procedure LZWE_Init(MaxBits: Byte);
Var I: LongInt;
Begin
 LZWE_MaxBits := MaxBits;
 LZWE_MaxCode := (LongInt(1) Shl MaxBits) - 1;
 LZWE_Bits := LZW_INIT_BITS;
 LZWE_FreeEnt := LZW_FIRST_CODE;
 LZWE_BitBuf := 0;
 LZWE_BitCnt := 0;
 LZWE_First := True;
 For I := 0 To LZWENC_HASHSIZE - 1 Do LZWE_Hash[I] := -1;
End;

Function LZWE_Lookup(Prefix: LongInt; Suffix: Byte): LongInt;
Var
 FCode: LongInt;
 Hash, Disp: LongInt;
Begin
 FCode := (LongInt(Suffix) Shl LZWE_MaxBits) Or Prefix;
 Hash := ((LongInt(Suffix) Shl 8) Xor Prefix) Mod LZWENC_HASHSIZE;
 If Hash < 0 Then Hash := Hash + LZWENC_HASHSIZE;
 Repeat
  If LZWE_Hash[Hash] = -1 Then Begin
   LZWE_Lookup := -(Hash + 1); Exit;
  End;
  If LZWE_Hash[Hash] = FCode Then Begin
   LZWE_Lookup := LZWE_Code[Hash]; Exit;
  End;
  Disp := LZWENC_HASHSIZE - Hash;
  If Disp <= 0 Then Disp := 1;
  Hash := Hash - Disp;
  If Hash < 0 Then Hash := Hash + LZWENC_HASHSIZE;
 Until False;
End;

Procedure LZWE_FeedByte(B: Byte; Var Hdr: TFileHdr);
Var R: LongInt;
Begin
 If LZWE_First Then Begin
  LZWE_Ent := B; LZWE_First := False; Exit;
 End;
 R := LZWE_Lookup(LZWE_Ent, B);
 If R >= 0 Then
  LZWE_Ent := R
 Else Begin
  { R = -(hash+1), case d'insertion }
  LZWE_OutBits(LZWE_Ent, Hdr);
  If LZWE_FreeEnt <= LZWE_MaxCode Then Begin
   LZWE_Hash[-R - 1] := (LongInt(B) Shl LZWE_MaxBits) Or LZWE_Ent;
   LZWE_Code[-R - 1] := LZWE_FreeEnt;
   Inc(LZWE_FreeEnt);
   If (LZWE_FreeEnt > ((LongInt(1) Shl LZWE_Bits) - 1)) And
      (LZWE_Bits < LZWE_MaxBits) Then
    Inc(LZWE_Bits);
  End;
  LZWE_Ent := B;
 End;
End;

Procedure LZWE_Finish(Var Hdr: TFileHdr);
Begin
 If Not LZWE_First Then LZWE_OutBits(LZWE_Ent, Hdr);
 LZWE_FlushBits(Hdr);
End;

{ RLE encoder pour pre-traiter le flux avant LZW (methode 8) }

Var
 RLEPre_Last : Byte;
 RLEPre_Run  : Word;
 RLEPre_HasLast : Boolean;

Procedure RLEPreReset;
Begin RLEPre_HasLast := False; RLEPre_Run := 0; End;

Procedure RLEPreEmit(Var Hdr: TFileHdr);
Var Cnt: Word;
Begin
 If Not RLEPre_HasLast Then Exit;
 If (RLEPre_Run < 4) And (RLEPre_Last <> DLE_MARK) Then Begin
  Cnt := RLEPre_Run;
  While Cnt > 0 Do Begin
   LZWE_FeedByte(RLEPre_Last, Hdr);
   Dec(Cnt);
  End;
 End Else Begin
  If RLEPre_Last <> DLE_MARK Then LZWE_FeedByte(RLEPre_Last, Hdr);
  LZWE_FeedByte(DLE_MARK, Hdr);
  LZWE_FeedByte(Byte(RLEPre_Run And $FF), Hdr);
 End;
End;

Procedure E_Crunch(Var Hdr: TFileHdr);
Var B: Byte;
Begin
 Hdr.Method := M_CR8;
 Hdr.CompSize := 0;
 Hdr.OrigSize := 0;
 ResetCRC;
 SrcReset;
 RLEPreReset;
 LZWE_Init(LZW_MAX_CR);

 While SrcGetByte(B) Do Begin
  Inc(Hdr.OrigSize);
  If B = DLE_MARK Then Begin
   RLEPreEmit(Hdr);
   RLEPre_HasLast := False;
   LZWE_FeedByte(DLE_MARK, Hdr);
   LZWE_FeedByte(0, Hdr);
   Continue;
  End;
  If RLEPre_HasLast And (B = RLEPre_Last) And (RLEPre_Run < 255) Then
   Inc(RLEPre_Run)
  Else Begin
   RLEPreEmit(Hdr);
   RLEPre_Last := B;
   RLEPre_Run := 1;
   RLEPre_HasLast := True;
  End;
 End;
 RLEPreEmit(Hdr);
 LZWE_Finish(Hdr);
 Hdr.CRC := CRC;
End;

{ ===== Selection automatique de la meilleure methode ===================
  Strategie : compresser en methode 8, methode 3 et methode 2 en memoire ;
  garder le meilleur. Pour simplifier ici, on essaie 8, et si store est
  meilleur on rebascule en 2.                                              }

Procedure CompressFile(Var Hdr: TFileHdr; Const SrcName: Str255;
                       PrefMethod: Byte);
Var
 BasePos, TryPos: LongInt;
 TryHdr: TFileHdr;
 BestM: Byte;
 BestSize: LongInt;
 FT: LongInt;
 DT: DateTime;
Begin
 Hdr.Name := UpStr(StripPath(SrcName));

 Assign(Src, SrcName);
 {$I-} Reset(Src, 1); {$I+}
 If IOResult <> 0 Then Begin
  Warn('impossible de lire ' + SrcName);
  Hdr.Method := M_STORE; Hdr.CompSize := 0; Hdr.OrigSize := 0;
  Exit;
 End;

 { Date/heure du fichier source }
 GetFTime(Src, FT);
 UnpackTime(FT, DT);
 Hdr.Date := (Word(DT.Year - 1980) Shl 9) Or (Word(DT.Month) Shl 5) Or Word(DT.Day);
 Hdr.Time := (Word(DT.Hour) Shl 11) Or (Word(DT.Min) Shl 5) Or (Word(DT.Sec) Shr 1);

 BasePos := FilePos(WrF);
 WriteHeader(Hdr);  { placeholder }
 WrFlush;
 TryPos := FilePos(WrF);

 BestM := M_STORE;
 BestSize := MaxLongInt;

 If Sw_Store Or (PrefMethod = M_STORE) Then Begin
  ResetCrypt; WrCryptIdx := 0;
  E_Store(Hdr);
  BestM := M_STORE; BestSize := Hdr.CompSize;
 End Else Begin
  { Essayer la methode demandee }
  Case PrefMethod Of
   M_PACK : Begin Reset(Src, 1); WrCryptIdx := 0; E_Pack(Hdr); End;
   M_CR8  : Begin Reset(Src, 1); WrCryptIdx := 0; E_Crunch(Hdr); End;
  Else
   Begin Reset(Src, 1); WrCryptIdx := 0; E_Crunch(Hdr); End;
  End;
  BestM := Hdr.Method;
  BestSize := Hdr.CompSize;

  { Si la compression a gonfle, on tombe en stored }
  If Hdr.CompSize >= Hdr.OrigSize Then Begin
   WrFlush;
   Seek(WrF, TryPos);
   Reset(Src, 1);
   WrCryptIdx := 0;
   E_Store(Hdr);
   BestM := M_STORE;
   BestSize := Hdr.CompSize;
  End;
 End;

 Close(Src);
 WrFlush;

 { Reecrire l'entete avec les bonnes valeurs }
 TryHdr := Hdr;
 Seek(WrF, BasePos);
 WriteHeader(TryHdr);
 WrFlush;
 Seek(WrF, FileSize(WrF));
 BestM := BestM; { evite avertissement variable inutilisee }
End;

{ ===== Affichage =====================================================  }

Function MethodName(M: Byte): Str13;
Begin
 Case M Of
  M_OLD    : MethodName := 'unpacked old';
  M_STORE  : MethodName := 'stored';
  M_PACK   : MethodName := 'packed';
  M_SQ     : MethodName := 'squeezed';
  M_CR5    : MethodName := 'crunched5';
  M_CR6    : MethodName := 'crunched6';
  M_CR7    : MethodName := 'crunched7';
  M_CR8    : MethodName := 'crunched';
  M_SQUASH : MethodName := 'squashed';
 Else MethodName := '?';
 End;
End;

Function Pad02(N: Word): Str13;
Var S: Str13;
Begin Str(N, S); If N < 10 Then S := '0' + S; Pad02 := S; End;

Procedure FormatDateTime(D, T: Word; Var DS, TS: Str13);
Var Y, Mo, Da, H, Mi, Se: Word;
    SY: Str13;
Begin
 Y := 1980 + (D Shr 9); Mo := (D Shr 5) And $0F; Da := D And $1F;
 H := T Shr 11; Mi := (T Shr 5) And $3F; Se := (T And $1F) Shl 1;
 Str(Y, SY);
 DS := SY + '-' + Pad02(Mo) + '-' + Pad02(Da);
 TS := Pad02(H) + ':' + Pad02(Mi) + ':' + Pad02(Se);
End;

{ ===== Commandes ======================================================= }

Const MAX_NAMES = 64;

Var
 ArgNames : Array[1..MAX_NAMES] of Str13;
 ArgCount : Byte;

Function MatchPattern(Const Pat, S: Str13): Boolean;
Var I, J: Integer; P, X: Str13;
Begin
 P := UpStr(Pat); X := UpStr(S);
 I := 1; J := 1;
 While (I <= Length(P)) And (J <= Length(X)) Do Begin
  If P[I] = '?' Then Begin Inc(I); Inc(J); Continue; End;
  If P[I] = '*' Then Begin
   If I = Length(P) Then Begin MatchPattern := True; Exit; End;
   Inc(I);
   While J <= Length(X) Do Begin
    If MatchPattern(Copy(P, I, 255), Copy(X, J, 255)) Then Begin
     MatchPattern := True; Exit;
    End;
    Inc(J);
   End;
   MatchPattern := False; Exit;
  End;
  If P[I] <> X[J] Then Begin MatchPattern := False; Exit; End;
  Inc(I); Inc(J);
 End;
 While (I <= Length(P)) And (P[I] = '*') Do Inc(I);
 MatchPattern := (I > Length(P)) And (J > Length(X));
End;

Function NameSelected(Const N: Str13): Boolean;
Var I: Byte;
Begin
 If ArgCount = 0 Then Begin NameSelected := True; Exit; End;
 For I := 1 To ArgCount Do
  If MatchPattern(ArgNames[I], N) Then Begin
   NameSelected := True; Exit;
  End;
 NameSelected := False;
End;

Procedure CmdList(Verbose: Boolean);
Var Hdr: TFileHdr;
    DS, TS: Str13;
    TotComp, TotOrig, FP: LongInt;
    Count: Word;
    Ratio: Word;
Begin
 If Verbose Then
  WriteLn('Name           Length   Stowage  SF   Size now  Date       Time     CRC')
 Else
  WriteLn('Name           Length    Date');
 WriteLn('============   =======  ========  ===  ========  =========  =======  ====');
 TotComp := 0; TotOrig := 0; Count := 0;
 Repeat
  If Not ReadHeader(Hdr) Then Break;
  If Hdr.Method = M_END Then Break;
  If NameSelected(Hdr.Name) Then Begin
   FormatDateTime(Hdr.Date, Hdr.Time, DS, TS);
   If Verbose Then Begin
    If Hdr.OrigSize > 0 Then
     Ratio := 100 - Word((Hdr.CompSize * 100) Div Hdr.OrigSize)
    Else
     Ratio := 0;
    WriteLn(PadRight(Hdr.Name, 13),
            PadLeft(LongStr(Hdr.OrigSize), 10), '  ',
            PadRight(MethodName(Hdr.Method), 9),
            PadLeft(LongStr(Ratio) + '%', 4), '  ',
            PadLeft(LongStr(Hdr.CompSize), 8), '  ',
            DS, '  ', TS, '  ',
            PadLeft(LongStr(Hdr.CRC), 4));
   End Else Begin
    WriteLn(PadRight(Hdr.Name, 13),
            PadLeft(LongStr(Hdr.OrigSize), 10), '  ', DS);
   End;
   Inc(TotComp, Hdr.CompSize);
   Inc(TotOrig, Hdr.OrigSize);
   Inc(Count);
  End;
  { Avancer dans le fichier en sautant les CompSize octets }
  FP := FilePos(ArcF) - LongInt(InCnt) + LongInt(InPos);
  Inc(FP, Hdr.CompSize);
  Seek(ArcF, FP);
  InPos := 0; InCnt := 0;
 Until False;
 WriteLn('====           =======            ===  ========');
 WriteLn(PadRight(LongStr(Count), 13),
         PadLeft(LongStr(TotOrig), 10),
         '            ',
         PadLeft(LongStr(TotComp), 8));
End;

Procedure CmdExtract(ToStdout: Boolean);
Var Hdr: TFileHdr;
    OutName: Str13;
    DataStartPos: LongInt;
    StoredCRC: Word;
    Selected: Boolean;
    XDT: DateTime;
    XFT: LongInt;
Begin
 Repeat
  If Not ReadHeader(Hdr) Then Break;
  If Hdr.Method = M_END Then Break;
  Selected := NameSelected(Hdr.Name);
  DataStartPos := FilePos(ArcF) - LongInt(InCnt) + LongInt(InPos);
  If Selected Then Begin
   OutName := Hdr.Name;
   OutToStdout := ToStdout;
   OutFile_Open := False;
   If Not ToStdout Then Begin
    Assign(OutF, OutName);
    {$I-} Rewrite(OutF, 1); {$I+}
    If IOResult <> 0 Then Begin
     Warn('impossible de creer ' + OutName);
     { Sauter les donnees }
     Seek(ArcF, DataStartPos + Hdr.CompSize);
     InPos := 0; InCnt := 0;
     Continue;
    End;
    OutFile_Open := True;
   End;
   StoredCRC := Hdr.CRC;
   Decompress(Hdr);
   If OutFile_Open Then Begin
    XDT.Year  := 1980 + (Hdr.Date Shr 9);
    XDT.Month := (Hdr.Date Shr 5) And $0F;
    XDT.Day   := Hdr.Date And $1F;
    XDT.Hour  := Hdr.Time Shr 11;
    XDT.Min   := (Hdr.Time Shr 5) And $3F;
    XDT.Sec   := (Hdr.Time And $1F) Shl 1;
    If XDT.Month = 0 Then XDT.Month := 1;
    If XDT.Day = 0 Then XDT.Day := 1;
    PackTime(XDT, XFT);
    SetFTime(OutF, XFT);
    Close(OutF);
   End;
   If Not ToStdout Then Begin
    If CRC = StoredCRC Then Begin
     If Not Sw_NoNote Then
      WriteLn('Extracted: ', OutName, ' (', Hdr.OrigSize, ' octets)');
     Inc(N_Extracted);
    End Else Begin
     Warn(OutName + ': CRC erreur (' + LongStr(CRC) + ' vs ' + LongStr(StoredCRC) + ')');
    End;
   End;
   Seek(ArcF, DataStartPos + Hdr.CompSize);
   InPos := 0; InCnt := 0;
  End Else Begin
   Seek(ArcF, DataStartPos + Hdr.CompSize);
   InPos := 0; InCnt := 0;
  End;
 Until False;
End;

Procedure CmdTest;
Var Hdr: TFileHdr; StoredCRC: Word; DataStartPos: LongInt;
Begin
 Repeat
  If Not ReadHeader(Hdr) Then Break;
  If Hdr.Method = M_END Then Break;
  DataStartPos := FilePos(ArcF) - LongInt(InCnt) + LongInt(InPos);
  If NameSelected(Hdr.Name) Then Begin
   OutFile_Open := False; OutToStdout := False;
   { Redirige sortie vers le neant : on remplace OutPutByte par CRC seul }
   OutSize := 0; OutPos := 0;
   StoredCRC := Hdr.CRC;
   ResetCRC; ResetCrypt;
   { Pour test, on decompresse sans ecrire : reutiliser Decompress mais
     ne pas ouvrir de fichier ; OutPutByte appellera FlushOut qui ne fera
     rien si ni OutFile_Open ni OutToStdout. }
   Decompress(Hdr);
   If CRC = StoredCRC Then Begin
    If Not Sw_NoNote Then WriteLn('Test : ', Hdr.Name, ' OK');
    Inc(N_Tested);
   End Else
    WriteLn('Test : ', Hdr.Name, ' ECHEC (CRC ',
            LongStr(CRC), ' vs ', LongStr(StoredCRC), ')');
   Seek(ArcF, DataStartPos + Hdr.CompSize);
   InPos := 0; InCnt := 0;
  End Else Begin
   Seek(ArcF, DataStartPos + Hdr.CompSize);
   InPos := 0; InCnt := 0;
  End;
 Until False;
End;

{ Pour les commandes add/move/update/freshen/delete on travaille sur deux
  fichiers : l'archive originale (lue) et l'archive temporaire (ecrite),
  puis renommer.                                                          }

Var
 OrigArcName : Str255;
 TmpArcName  : Str255;

Procedure CopyOneEntry(Var Hdr: TFileHdr);
Var I: LongInt; B: Byte;
Begin
 WriteHeader(Hdr);
 For I := 1 To Hdr.CompSize Do Begin
  B := InGetByteRaw;
  WrByte(B);
 End;
End;

Procedure SkipEntryData(Var Hdr: TFileHdr);
Var DataStartPos: LongInt;
Begin
 DataStartPos := FilePos(ArcF) - LongInt(InCnt) + LongInt(InPos);
 Seek(ArcF, DataStartPos + Hdr.CompSize);
 InPos := 0; InCnt := 0;
End;

Procedure CmdDelete;
Var Hdr: TFileHdr; Deleted: Boolean;
Begin
 Repeat
  If Not ReadHeader(Hdr) Then Break;
  If Hdr.Method = M_END Then Break;
  Deleted := NameSelected(Hdr.Name);
  If Deleted Then Begin
   If Not Sw_NoNote Then WriteLn('Suppression : ', Hdr.Name);
   Inc(N_Deleted);
   SkipEntryData(Hdr);
  End Else
   CopyOneEntry(Hdr);
 Until False;
 WriteEOA;
End;

Function FileAge(Const N: Str255): LongInt;
Var F: File; FT: LongInt; OldMode: Byte;
Begin
 Assign(F, N);
 OldMode := FileMode; FileMode := 0;
 {$I-} Reset(F, 1); {$I+}
 FileMode := OldMode;
 If IOResult <> 0 Then Begin FileAge := -1; Exit; End;
 GetFTime(F, FT);
 Close(F);
 FileAge := FT;
End;

Function ArcDateTimeAsFT(D, T: Word): LongInt;
Var DT: DateTime; FT: LongInt;
Begin
 DT.Year  := 1980 + (D Shr 9);
 DT.Month := (D Shr 5) And $0F;
 DT.Day   := D And $1F;
 DT.Hour  := T Shr 11;
 DT.Min   := (T Shr 5) And $3F;
 DT.Sec   := (T And $1F) Shl 1;
 If DT.Month = 0 Then DT.Month := 1;
 If DT.Day = 0 Then DT.Day := 1;
 PackTime(DT, FT);
 ArcDateTimeAsFT := FT;
End;

{ Mode = 'a' add (remplace si existe), 'u' update (si nouveau ou plus recent),
         'f' freshen (uniquement si deja present et plus recent),
         'm' move (= add + delete source apres) }

Procedure CmdAddLike(Mode: Char);
Var Hdr: TFileHdr; SrcName: Str13; AddIt: Boolean;
    SrcFT, ArcFT: LongInt;
    InArc: Array[1..MAX_NAMES] of Boolean;
    I: Byte;
    NewHdr: TFileHdr;
Begin
 For I := 1 To MAX_NAMES Do InArc[I] := False;

 { Premiere passe : copier les entrees existantes, en remplacant celles
   selectionnees si le mode l'exige. }
 Repeat
  If Not ReadHeader(Hdr) Then Break;
  If Hdr.Method = M_END Then Break;
  AddIt := False;
  { Le fichier source local correspondant existe-t-il ? }
  For I := 1 To ArgCount Do Begin
   If UpStr(StripPath(ArgNames[I])) = UpStr(Hdr.Name) Then Begin
    InArc[I] := True;
    SrcName := ArgNames[I];
    SrcFT := FileAge(SrcName);
    If SrcFT < 0 Then AddIt := False
    Else Begin
     ArcFT := ArcDateTimeAsFT(Hdr.Date, Hdr.Time);
     Case Mode Of
      'a','m' : AddIt := True;
      'u'     : AddIt := SrcFT > ArcFT;
      'f'     : AddIt := SrcFT > ArcFT;
     End;
    End;
    Break;
   End;
  End;
  If AddIt Then Begin
   SkipEntryData(Hdr);
   FillChar(NewHdr, SizeOf(NewHdr), 0);
   CompressFile(NewHdr, SrcName, M_CR8);
   If Not Sw_NoNote Then WriteLn('Remplace : ', NewHdr.Name);
   Inc(N_Updated);
  End Else
   CopyOneEntry(Hdr);
 Until False;

 { Seconde passe : pour les fichiers absents de l'archive, ajouter
   (uniquement si mode permet : 'a','m','u' oui ; 'f' non).             }
 If (Mode = 'a') Or (Mode = 'm') Or (Mode = 'u') Then Begin
  For I := 1 To ArgCount Do Begin
   If Not InArc[I] Then Begin
    If FileAge(ArgNames[I]) < 0 Then Begin
     Warn('aucun fichier ne correspond a : ' + ArgNames[I]);
     Continue;
    End;
    FillChar(NewHdr, SizeOf(NewHdr), 0);
    CompressFile(NewHdr, ArgNames[I], M_CR8);
    If Not Sw_NoNote Then WriteLn('Ajout : ', NewHdr.Name);
    Inc(N_Added);
   End;
  End;
 End;
 WriteEOA;

 If Mode = 'm' Then Begin
  For I := 1 To ArgCount Do Begin
   If InArc[I] Or (FileAge(ArgNames[I]) >= 0) Then Begin
    Assign(Src, ArgNames[I]);
    {$I-} Erase(Src); {$I+}
    If IOResult = 0 Then
     If Not Sw_NoNote Then WriteLn('Source supprimee : ', ArgNames[I]);
   End;
  End;
 End;
End;

Procedure CmdConvert;
Var Hdr: TFileHdr; NewHdr: TFileHdr; TmpName: Str13;
Begin
 Repeat
  If Not ReadHeader(Hdr) Then Break;
  If Hdr.Method = M_END Then Break;
  If NameSelected(Hdr.Name) And
     (Hdr.Method <> M_CR8) And (Hdr.Method <> M_STORE) Then Begin
   { Extraire vers un fichier temporaire puis recompresser }
   TmpName := 'ARCCONV.TMP';
   OutToStdout := False;
   OutFile_Open := True;
   Assign(OutF, TmpName); Rewrite(OutF, 1);
   Decompress(Hdr);
   Close(OutF);
   FillChar(NewHdr, SizeOf(NewHdr), 0);
   NewHdr.Date := Hdr.Date; NewHdr.Time := Hdr.Time;
   CompressFile(NewHdr, TmpName, M_CR8);
   Assign(OutF, TmpName); Erase(OutF);
   If Not Sw_NoNote Then WriteLn('Converti : ', Hdr.Name);
   Inc(N_Updated);
  End Else
   CopyOneEntry(Hdr);
 Until False;
 WriteEOA;
End;

{ ===== Parsing arguments ============================================== }

Var
 Cmd : Char;
 ArchiveName : Str255;

Procedure Usage;Begin
 Case Language of
    _English:Begin
       WriteLn('ARC ', Version, ' - This command lets you create, compress, ',
               'extract and manage archive files so that several files can be ',
               'grouped together in a single compressed container (.ARC).');
        WriteLn;
        WriteLn('Usage: ARC {amufdxerplvtc}[bswn][g<password>] <archive> [<filename> ...]');
        WriteLn(' Where:   a   = add files to archive');
        WriteLn('          m   = move files to archive');
        WriteLn('          u   = update files in archive');
        WriteLn('          f   = freshen files in archive');
        WriteLn('          d   = delete files from archive');
        WriteLn('          x,e = extract files from archive');
        WriteLn('          p   = copy files from archive to standard output');
        WriteLn('          l   = list files in archive');
        WriteLn('          v   = verbose listing of files in archive');
        WriteLn('          t   = test archive integrity');
        WriteLn('          c   = convert entry to new packing method');
        WriteLn('          b   = retain backup copy of archive');
        WriteLn('          s   = suppress compression (store only)');
        WriteLn('          w   = suppress warning messages');
        WriteLn('          n   = suppress notes and comments');
        WriteLn('          g   = Encrypt/decrypt archive entry');    
    End;
    Else Begin
     WriteLn('ARC ', Version, ' - Cette commande permet de cr�er, compresser, ',
            'extraire et g�rer des fichiers d''archives afin de regrouper ',
            'plusieurs fichiers dans un seul conteneur compress� (.ARC).');
        WriteLn;
        WriteLn('Usage : ARC {amufdxerplvtc}[bswn][g<mot_de_passe>] <archive> [<fichier> ...]');
        WriteLn(' O� :     a   = ajouter des fichiers � l''archive');
        WriteLn('          m   = d�placer des fichiers vers l''archive');
        WriteLn('          u   = mettre � jour les fichiers de l''archive');
        WriteLn('          f   = rafra�chir les fichiers de l''archive');
        WriteLn('          d   = supprimer des fichiers de l''archive');
        WriteLn('          x,e = extraire des fichiers de l''archive');
        WriteLn('          p   = copier des fichiers de l''archive vers la sortie standard');
        WriteLn('          l   = lister les fichiers de l''archive');
        WriteLn('          v   = liste d�taill�e des fichiers de l''archive');
        WriteLn('          t   = tester l''int�grit� de l''archive');
        WriteLn('          c   = convertir une entr�e vers une nouvelle m�thode de compression');
        WriteLn('          b   = conserver une copie de sauvegarde de l''archive');
        WriteLn('          s   = supprimer la compression (stockage seul)');
        WriteLn('          w   = supprimer les messages d''avertissement');
        WriteLn('          n   = supprimer les notes et commentaires');
        WriteLn('          g   = chiffrer/d�chiffrer une entr�e de l''archive');
    End;
 End;
 Halt(1);
End;

Procedure ParseCmdLine;
Var
 I, J: Byte;
 K: Integer;
 S: Str255;
 InG: Boolean;
 HasExt: Boolean;
Begin
 ArgCount := 0;
 Cmd := #0;
 Sw_Backup := False; Sw_Store := False;
 Sw_NoWarn := False; Sw_NoNote := False;
 Sw_Crypt := False; Password := '';
 ArchiveName := '';

 If ParamCount < 2 Then Usage;

 { Argument 1 : sequence de lettres }
 S := ParamStr(1);
 InG := False;
 For I := 1 To Length(S) Do Begin
  If InG Then Begin Password := Password + S[I]; Continue; End;
  Case UpCase(S[I]) Of
   'A','M','U','F','D','X','E','P','L','V','T','C','R' :
    Begin
     If Cmd = #0 Then Cmd := UpCase(S[I])
     Else Begin
      WriteLn('Cannot mix ', Cmd, ' and ', UpCase(S[I]));
      Halt(1);
     End;
    End;
   'B' : Sw_Backup := True;
   'S' : Sw_Store := True;
   'W' : Sw_NoWarn := True;
   'N' : Sw_NoNote := True;
   'G' : Begin Sw_Crypt := True; InG := True; End;
  Else
   WriteLn(UpCase(S[I]), ' is an unknown command');
   Halt(1);
  End;
 End;
 If Cmd = #0 Then Begin
  WriteLn('I have nothing to do!');
  Halt(1);
 End;

 ArchiveName := ParamStr(2);
 HasExt := False;
 For K := Length(ArchiveName) DownTo 1 Do Begin
  If (ArchiveName[K] = '\') Or (ArchiveName[K] = '/') Then Break;
  If ArchiveName[K] = '.' Then Begin HasExt := True; Break; End;
 End;
 If Not HasExt Then ArchiveName := ArchiveName + '.ARC';

 For J := 3 To ParamCount Do Begin
  If ArgCount < MAX_NAMES Then Begin
   Inc(ArgCount); ArgNames[ArgCount] := UpStr(ParamStr(J));
  End;
 End;
End;

{ ===== Initialisation/cleanup ========================================= }

Procedure InitBuffers;
Begin
 New(InBuf); New(OutBuf); New(SrcBuf); New(WrBuf);
 New(LZW_Prefix); New(LZW_Suffix); New(LZW_Stack);
 InitCRCTab;
 OutPos := 0; WrPos := 0; WrByteCount := 0;
 WrCryptOn := False; WrCryptIdx := 0;
 N_Added := 0; N_Updated := 0; N_Deleted := 0;
 N_Extracted := 0; N_Tested := 0;
End;

Procedure OpenArc;
Begin
 Assign(ArcF, ArchiveName);
 {$I-} Reset(ArcF, 1); {$I+}
 If IOResult <> 0 Then Begin
  ArcOpened := False;
  InResetCounters;
  InEnd := True;
  Exit;
 End;
 ArcOpened := True;
 InResetCounters;
End;

Procedure CloseArc;
Begin
 If ArcOpened Then Begin Close(ArcF); ArcOpened := False; End;
End;

Procedure OpenWriteArc(Const N: Str255);
Begin
 Assign(WrF, N);
 {$I-} Rewrite(WrF, 1); {$I+}
 If IOResult <> 0 Then Die('impossible de creer ' + N);
 WrPos := 0; WrByteCount := 0;
 Sw_Crypt := Sw_Crypt; { idem }
 WrCryptOn := Sw_Crypt;
End;

Procedure CloseWriteArc;
Begin WrFlush; Close(WrF); End;

{ ===== Main ============================================================ }

Procedure RunCommand;
Var BakName: Str255; I: Integer;
Begin
 OpenArc;
 If (Not ArcOpened) And
    (Cmd <> 'A') And (Cmd <> 'M') And (Cmd <> 'U') Then
  Die('impossible d''ouvrir ' + ArchiveName);
 Case Cmd Of
  'L' : CmdList(False);
  'V' : CmdList(True);
  'X','E' : CmdExtract(False);
  'P' : Begin Sw_NoNote := True; CmdExtract(True); End;
  'T' : CmdTest;
  'A','M','U','F','D','C' :
   Begin
    { Operations modifiantes : on ecrit dans un fichier temporaire }
    TmpArcName := ArchiveName + '.$$$';
    OpenWriteArc(TmpArcName);
    Case Cmd Of
     'D' : CmdDelete;
     'C' : CmdConvert;
    Else CmdAddLike(Char(Ord(Cmd) + 32));  { 'a','m','u','f' minuscule }
    End;
    CloseWriteArc;
    CloseArc;
    { Backup eventuel }
    If Sw_Backup Then Begin
     BakName := Copy(ArchiveName, 1, Length(ArchiveName) - 4) + '.BAK';
     Assign(WrF, BakName); {$I-} Erase(WrF); {$I+} I := IOResult;
     Rename(ArcF, BakName);
    End Else Begin
     Assign(ArcF, ArchiveName); {$I-} Erase(ArcF); {$I+} I := IOResult;
    End;
    Assign(WrF, TmpArcName);
    Rename(WrF, ArchiveName);
    OpenArc;
   End;
  'R' : Die('R: ne sait pas faire ' + Cmd + ' pour l''instant');
 Else
  Die('I don''t know how to do ' + Cmd + ' yet!');
 End;
 CloseArc;
End;

BEGIN
 Language := _French;
 TmpLanguage := GetEnv('LANGUAGE');
 If TmpLanguage <> '' Then Begin
  If TmpLanguage[1] = '"' Then TmpLanguage := Copy(TmpLanguage, 2, 255);
  If StrToUpper(Copy(TmpLanguage,1,2)) = 'EN' Then Language := _English Else
  If StrToUpper(Copy(TmpLanguage,1,2)) = 'GR' Then Language := _Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2)) = 'IT' Then Language := _Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2)) = 'SP' Then Language := _Spain;
 End;
 ParseCmdLine;
 InitBuffers;
 RunCommand;
 If Not Sw_NoNote Then Begin
  If N_Added    > 0 Then WriteLn(N_Added, ' fichier(s) ajoute(s)');
  If N_Updated  > 0 Then WriteLn(N_Updated, ' fichier(s) mis a jour');
  If N_Deleted  > 0 Then WriteLn(N_Deleted, ' fichier(s) supprime(s)');
  If N_Extracted> 0 Then WriteLn(N_Extracted, ' fichier(s) extrait(s)');
  If N_Tested   > 0 Then WriteLn(N_Tested, ' fichier(s) testes');
 End;
END.
