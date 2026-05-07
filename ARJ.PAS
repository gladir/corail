{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program ARJ;

{$A-}

Uses DOS;

Type
 ArjHeader=Record
  HeadId:Word;           { Signature: 60000 }
  BHdrSz:Word;           { Taille de la simple ent�te de fichier }
  FHdrSz:Byte;           { Taille de l'ent�te fichier }
  AVNo:Byte;
  MAVX:Byte;
  HostOS:Byte;
  Flags:Byte;
  SVer:Byte;
  FType:Byte;
  Res1:Byte;
  DosDT:LongInt;
  CSize:LongInt;         { Taille compress� }
  OSize:LongInt;         { Taille original }
  SEFP:LongInt;
  FSFPos:Word;
  SEDLgn:Word;
  Res2:Word;
  NameDat:Array[1..120]of Char;{ D�but du nom,... }
  Res3:Array[1..10]of Char;
 End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

Function LongHex2Str(value:LongInt):String;
Begin
 LongHex2Str:=ByteHex2Str((value shr 24)and $FF)+
              ByteHex2Str((value shr 16)and $FF)+
              ByteHex2Str((value shr 8)and $FF)+
              ByteHex2Str(value and $FF);
End;

{ ============================================================ }
{ === ARJ Method 1-3 Decompressor (port of unarj decode.c) === }
{ ============================================================ }

Var
 SourceARJ,DestFile:File;

Const
 D_DICSIZ    = 26624;
 D_THRESHOLD = 3;
 D_NC        = 510;
 D_NP        = 17;
 D_NT        = 19;
 D_CBIT      = 9;
 D_PBIT      = 5;
 D_TBIT      = 5;
 D_CTBITS    = 12;
 D_PTBITS    = 8;
 D_CRCPoly   :LongInt = LongInt($EDB88320);

Type
 TByteBuf = Array[0..16383] of Byte;
 PByteBuf = ^TByteBuf;
 TWordBuf = Array[0..16383] of Word;
 PWordBuf = ^TWordBuf;
 TInBuf4K  = Array[0..4095] of Byte;       PInBuf4K  = ^TInBuf4K;
 TCTab4K   = Array[0..4095] of Word;       PCTab4K   = ^TCTab4K;
 TBranch   = Array[0..1019] of Word;       PBranch   = ^TBranch;
 TDictBuf  = Array[0..D_DICSIZ-1] of Byte; PDictBuf  = ^TDictBuf;
 TCRCTab   = Array[0..255] of LongInt;     PCRCTab   = ^TCRCTab;

Var
 D_BitBuf: Word;
 D_BitCount: Byte;
 D_SubBitBuf: Byte;
 D_InBuf: PInBuf4K;
 D_InPos, D_InEnd: Word;
 D_CompLeft: LongInt;
 D_CLen: Array[0..509] of Byte;
 D_PtLen: Array[0..18] of Byte;
 D_CTable: PCTab4K;
 D_PtTable: Array[0..255] of Word;
 D_LeftT, D_RightT: PBranch;
 D_BlockSize: Word;
 D_Dict: PDictBuf;
 D_DictPos: Word;
 D_CRCTab: PCRCTab;
 D_CRCInited: Boolean;
 D_Error: Boolean;

Procedure D_InitCRC;
Var
 I,J:Integer;
 C:LongInt;
Begin
 If D_CRCInited Then Exit;
 For I:=0 to 255 Do Begin
  C:=I;
  For J:=0 to 7 Do
   If(C and 1)<>0 Then C:=(C shr 1) xor D_CRCPoly
                  Else C:=C shr 1;
  D_CRCTab^[I]:=C;
 End;
 D_CRCInited:=True;
End;

Function D_UpdateCRC(CRC: LongInt; B: Byte): LongInt;
Begin
 D_UpdateCRC := (CRC shr 8) xor D_CRCTab^[(CRC xor B) and $FF];
End;

Procedure D_FillIn;
Var
 Need:LongInt;
 Got:Word;
Begin
 If D_CompLeft <= 0 Then Begin
  D_InPos := 0; D_InEnd := 0; Exit;
 End;
 Need := 4096;
 If D_CompLeft < Need Then Need := D_CompLeft;
 BlockRead(SourceARJ, D_InBuf^, Need, Got);
 D_InPos := 0;
 D_InEnd := Got;
 Dec(D_CompLeft, Got);
End;

Function D_GetByte: Byte;
Begin
 If D_InPos >= D_InEnd Then D_FillIn;
 If D_InPos >= D_InEnd Then Begin
  D_GetByte := 0;
  Exit;
 End;
 D_GetByte := D_InBuf^[D_InPos];
 Inc(D_InPos);
End;

Procedure D_FillBuf(N: Byte);
Begin
 If N >= 16 Then D_BitBuf := 0
            Else D_BitBuf := D_BitBuf shl N;
 While N > D_BitCount Do Begin
  Dec(N, D_BitCount);
  If N < 16 Then
   D_BitBuf := D_BitBuf or (Word(D_SubBitBuf) shl N);
  D_SubBitBuf := D_GetByte;
  D_BitCount := 8;
 End;
 Dec(D_BitCount, N);
 D_BitBuf := D_BitBuf or (Word(D_SubBitBuf) shr D_BitCount);
End;

Function D_GetBits(N: Byte): Word;
Var X: Word;
Begin
 X := D_BitBuf shr (16 - N);
 D_FillBuf(N);
 D_GetBits := X;
End;

Procedure D_InitGetBits;
Begin
 D_BitBuf := 0;
 D_SubBitBuf := 0;
 D_BitCount := 0;
 D_FillBuf(16);
End;

Procedure D_MakeTable(NChar, TableBits: Word; BL: PByteBuf; Tbl: PWordBuf);
Var
 Count: Array[0..16] of LongInt;
 Start: Array[0..17] of LongInt;
 Weight: Array[0..16] of LongInt;
 I, K, NextCode, Mask: LongInt;
 Len, Ch: Word;
 JutBits, Avail: Word;
 PMode: Byte;
 PIdx, Tmp: Word;
Begin
 For I:=1 To 16 Do Count[I]:=0;
 For I:=0 To LongInt(NChar)-1 Do Inc(Count[BL^[I]]);
 Start[1]:=0;
 For I:=1 To 16 Do Start[I+1]:=Start[I]+(Count[I] shl (16-I));
 If Start[17]<>$10000 Then Begin D_Error:=True; Exit; End;

 JutBits := 16 - TableBits;
 For I:=1 To TableBits Do Begin
  Start[I] := Start[I] shr JutBits;
  Weight[I] := LongInt(1) shl (TableBits-I);
 End;
 For I:=TableBits+1 To 16 Do
  Weight[I] := LongInt(1) shl (16-I);

 I := Start[TableBits+1] shr JutBits;
 If I <> $10000 Then Begin
  K := LongInt(1) shl TableBits;
  While I < K Do Begin
   Tbl^[I] := 0;
   Inc(I);
  End;
 End;

 Avail := NChar;
 Mask := LongInt(1) shl (15 - TableBits);
 For Ch:=0 To NChar-1 Do Begin
  Len := BL^[Ch];
  If Len = 0 Then Continue;
  NextCode := Start[Len] + Weight[Len];
  If Len <= TableBits Then Begin
   I := Start[Len];
   While I < NextCode Do Begin
    Tbl^[I] := Ch;
    Inc(I);
   End;
  End Else Begin
   K := Start[Len];
   PMode := 0;
   PIdx := K shr JutBits;
   I := Len - TableBits;
   While I <> 0 Do Begin
    Case PMode Of
     0: Tmp := Tbl^[PIdx];
     1: Tmp := D_LeftT^[PIdx];
    Else Tmp := D_RightT^[PIdx];
    End;
    If Tmp = 0 Then Begin
     D_RightT^[Avail] := 0;
     D_LeftT^[Avail] := 0;
     Tmp := Avail;
     Case PMode Of
      0: Tbl^[PIdx] := Avail;
      1: D_LeftT^[PIdx] := Avail;
     Else D_RightT^[PIdx] := Avail;
     End;
     Inc(Avail);
    End;
    If(K and Mask)<>0 Then PMode:=2 Else PMode:=1;
    PIdx := Tmp;
    K := K shl 1;
    Dec(I);
   End;
   Case PMode Of
    0: Tbl^[PIdx] := Ch;
    1: D_LeftT^[PIdx] := Ch;
   Else D_RightT^[PIdx] := Ch;
   End;
  End;
  Start[Len] := NextCode;
 End;
End;

Procedure D_ReadPtLen(NN: Word; NBit: Byte; ISpecial: Integer);
Var
 I: Integer;
 C, N: Word;
 Mask: Word;
Begin
 N := D_GetBits(NBit);
 If N = 0 Then Begin
  C := D_GetBits(NBit);
  For I:=0 To NN-1 Do D_PtLen[I] := 0;
  For I:=0 To 255 Do D_PtTable[I] := C;
 End Else Begin
  I := 0;
  While I < N Do Begin
   C := D_BitBuf shr 13;
   If C = 7 Then Begin
    Mask := $1000;
    While(Mask and D_BitBuf)<>0 Do Begin
     Mask := Mask shr 1;
     Inc(C);
    End;
   End;
   If C < 7 Then D_FillBuf(3) Else D_FillBuf(C-3);
   D_PtLen[I] := C;
   Inc(I);
   If I = ISpecial Then Begin
    C := D_GetBits(2);
    While C > 0 Do Begin
     D_PtLen[I] := 0;
     Inc(I);
     Dec(C);
    End;
   End;
  End;
  While I < NN Do Begin
   D_PtLen[I] := 0;
   Inc(I);
  End;
  D_MakeTable(NN, 8, PByteBuf(@D_PtLen), PWordBuf(@D_PtTable));
 End;
End;

Procedure D_ReadCLen;
Var
 I: Integer;
 C, N: Word;
 Mask: Word;
Begin
 N := D_GetBits(D_CBIT);
 If N = 0 Then Begin
  C := D_GetBits(D_CBIT);
  For I:=0 To D_NC-1 Do D_CLen[I] := 0;
  For I:=0 To 4095 Do D_CTable^[I] := C;
 End Else Begin
  I := 0;
  While I < N Do Begin
   C := D_PtTable[D_BitBuf shr 8];
   If C >= D_NT Then Begin
    Mask := $80;
    Repeat
     If(D_BitBuf and Mask)<>0 Then C := D_RightT^[C]
                              Else C := D_LeftT^[C];
     Mask := Mask shr 1;
    Until C < D_NT;
   End;
   D_FillBuf(D_PtLen[C]);
   If C <= 2 Then Begin
    If C = 0 Then C := 1
    Else If C = 1 Then C := D_GetBits(4) + 3
    Else C := D_GetBits(D_CBIT) + 20;
    While C > 0 Do Begin
     D_CLen[I] := 0;
     Inc(I);
     Dec(C);
    End;
   End Else Begin
    D_CLen[I] := C - 2;
    Inc(I);
   End;
  End;
  While I < D_NC Do Begin
   D_CLen[I] := 0;
   Inc(I);
  End;
  D_MakeTable(D_NC, 12, PByteBuf(@D_CLen), PWordBuf(D_CTable));
 End;
End;

Function D_DecodeC: Word;
Var
 J: Word;
 Mask: Word;
Begin
 If D_BlockSize = 0 Then Begin
  D_BlockSize := D_GetBits(16);
  D_ReadPtLen(D_NT, D_TBIT, 3);
  If D_Error Then Begin D_DecodeC:=0; Exit; End;
  D_ReadCLen;
  If D_Error Then Begin D_DecodeC:=0; Exit; End;
  D_ReadPtLen(D_NP, D_PBIT, -1);
  If D_Error Then Begin D_DecodeC:=0; Exit; End;
 End;
 Dec(D_BlockSize);
 J := D_CTable^[D_BitBuf shr 4];
 If J >= D_NC Then Begin
  Mask := $08;
  Repeat
   If(D_BitBuf and Mask)<>0 Then J := D_RightT^[J]
                            Else J := D_LeftT^[J];
   Mask := Mask shr 1;
  Until J < D_NC;
 End;
 D_FillBuf(D_CLen[J]);
 D_DecodeC := J;
End;

Function D_DecodeP: Word;
Var
 J: Word;
 Mask: Word;
Begin
 J := D_PtTable[D_BitBuf shr 8];
 If J >= D_NP Then Begin
  Mask := $80;
  Repeat
   If(D_BitBuf and Mask)<>0 Then J := D_RightT^[J]
                            Else J := D_LeftT^[J];
   Mask := Mask shr 1;
  Until J < D_NP;
 End;
 D_FillBuf(D_PtLen[J]);
 If J <> 0 Then
  J := (Word(1) shl (J-1)) + D_GetBits(J-1);
 D_DecodeP := J;
End;

Function D_Decompress(CSize, OSize, ExpectedCRC: LongInt;
                      Var ResCRC: LongInt): Boolean;
Var
 Count, J, I, P: LongInt;
 C: Word;
Begin
 D_InitCRC;
 ResCRC := LongInt($FFFFFFFF);
 D_BlockSize := 0;
 D_DictPos := 0;
 D_Error := False;
 D_CompLeft := CSize;
 D_InPos := 0;
 D_InEnd := 0;
 D_InitGetBits;
 Count := 0;
 While(Count < OSize) and (not D_Error) Do Begin
  C := D_DecodeC;
  If D_Error Then Break;
  If C <= 255 Then Begin
   D_Dict^[D_DictPos] := C;
   ResCRC := D_UpdateCRC(ResCRC, C);
   Inc(D_DictPos);
   If D_DictPos >= D_DICSIZ Then Begin
    BlockWrite(DestFile, D_Dict^, D_DICSIZ);
    D_DictPos := 0;
   End;
   Inc(Count);
  End Else Begin
   J := LongInt(C) - 253;  { c - (UCHAR_MAX + 1 - THRESHOLD) }
   Inc(Count, J);
   I := LongInt(D_DictPos) - LongInt(D_DecodeP) - 1;
   If I < 0 Then Inc(I, D_DICSIZ);
   P := I;
   While J > 0 Do Begin
    D_Dict^[D_DictPos] := D_Dict^[P];
    ResCRC := D_UpdateCRC(ResCRC, D_Dict^[P]);
    Inc(P);
    If P >= D_DICSIZ Then P := 0;
    Inc(D_DictPos);
    If D_DictPos >= D_DICSIZ Then Begin
     BlockWrite(DestFile, D_Dict^, D_DICSIZ);
     D_DictPos := 0;
    End;
    Dec(J);
   End;
  End;
 End;
 If(D_DictPos > 0) and (not D_Error) Then
  BlockWrite(DestFile, D_Dict^, D_DictPos);
 ResCRC := ResCRC xor LongInt($FFFFFFFF);
 D_Decompress := (not D_Error) and (Count >= OSize);
End;

{ ============================================================ }{ === ARJ Archive Writer (method 0 stored)               ==== }
{ ============================================================ }

Function CRC32OfFile(Var F: File; Size: LongInt): LongInt;
Var
 Buf: Array[0..4095] of Byte;
 ToRead: LongInt;
 Got, I: Integer;
 CRC: LongInt;
Begin
 D_InitCRC;
 CRC := LongInt($FFFFFFFF);
 While Size > 0 Do Begin
  If Size > 4096 Then ToRead := 4096 Else ToRead := Size;
  BlockRead(F, Buf, ToRead, Got);
  If Got <= 0 Then Break;
  For I := 0 To Got - 1 Do
   CRC := D_UpdateCRC(CRC, Buf[I]);
  Dec(Size, Got);
 End;
 CRC32OfFile := CRC xor LongInt($FFFFFFFF);
End;

Function CRC32OfBuf(Var Buf; Len: Word): LongInt;
Var
 P: ^Byte;
 I: Word;
 CRC: LongInt;
Begin
 D_InitCRC;
 CRC := LongInt($FFFFFFFF);
 P := @Buf;
 For I := 1 To Len Do Begin
  CRC := D_UpdateCRC(CRC, P^);
  Inc(P);
 End;
 CRC32OfBuf := CRC xor LongInt($FFFFFFFF);
End;

Function StripPath(S: String): String;
Var I: Integer;
Begin
 For I := Length(S) DownTo 1 Do
  If(S[I]='\')or(S[I]='/')or(S[I]=':')Then Begin
   StripPath := Copy(S, I+1, 255);
   Exit;
  End;
 StripPath := S;
End;

{ Write little-endian Word to a buffer at position P, advance P }
Procedure PutW(Var Buf:Array of Byte; Var P:Word; V:Word);
Begin
 Buf[P] := V and $FF; Inc(P);
 Buf[P] := (V shr 8) and $FF; Inc(P);
End;

Procedure PutB(Var Buf:Array of Byte; Var P:Word; V:Byte);
Begin
 Buf[P] := V; Inc(P);
End;

Procedure PutL(Var Buf:Array of Byte; Var P:Word; V:LongInt);
Begin
 Buf[P] := V and $FF; Inc(P);
 Buf[P] := (V shr 8) and $FF; Inc(P);
 Buf[P] := (V shr 16) and $FF; Inc(P);
 Buf[P] := (V shr 24) and $FF; Inc(P);
End;

Procedure PutStrZ(Var Buf:Array of Byte; Var P:Word; S:String);
Var I: Integer;
Begin
 For I := 1 To Length(S) Do Begin
  Buf[P] := Ord(S[I]); Inc(P);
 End;
 Buf[P] := 0; Inc(P);
End;

{ Build a basic ARJ header (without the 4-byte HeadID/BHdrSz prefix and
  without the CRC/ExtHdr trailer) into Buf. Returns length written. }
Function BuildBasicHeader(Var Buf:Array of Byte; FType:Byte; SVer:Byte;
                         DosDT:LongInt; CSize, OSize, FileCRC:LongInt;
                         Name, Comment:String):Word;
Var P: Word;
Begin
 P := 0;
 PutB(Buf, P, 30);            { FHdrSz }
 PutB(Buf, P, 11);            { AVNo - archiver version }
 PutB(Buf, P, 1);             { MAVX - min version to extract }
 PutB(Buf, P, 0);             { HostOS = MSDOS }
 PutB(Buf, P, 0);             { Flags }
 PutB(Buf, P, SVer);          { Method (0 = stored) }
 PutB(Buf, P, FType);         { File type (0=binary, 2=main hdr) }
 PutB(Buf, P, 0);             { Reserved }
 PutL(Buf, P, DosDT);         { Date/time modified }
 PutL(Buf, P, CSize);         { Compressed size }
 PutL(Buf, P, OSize);         { Original size }
 PutL(Buf, P, FileCRC);       { File CRC32 }
 PutW(Buf, P, 0);             { Filespec position in filename }
 PutW(Buf, P, 0);             { Length of file access mode }
 PutW(Buf, P, 0);             { Host data / reserved }
 PutStrZ(Buf, P, Name);       { Filename }
 PutStrZ(Buf, P, Comment);    { Comment }
 BuildBasicHeader := P;
End;

Procedure WriteArjHeader(Var F: File; FType, SVer:Byte; DosDT:LongInt;
                         CSize, OSize, FileCRC:LongInt;
                         Name, Comment:String);
Var
 BHBuf: Array[0..511] of Byte;
 Prefix: Array[0..3] of Byte;
 Trailer: Array[0..5] of Byte;
 Len: Word;
 HCRC: LongInt;
 P: Word;
Begin
 Len := BuildBasicHeader(BHBuf, FType, SVer, DosDT, CSize, OSize, FileCRC,
                         Name, Comment);
 P := 0;
 PutW(Prefix, P, $EA60);      { ARJ signature }
 PutW(Prefix, P, Len);        { Basic header size }
 BlockWrite(F, Prefix, 4);
 BlockWrite(F, BHBuf, Len);
 HCRC := CRC32OfBuf(BHBuf, Len);
 P := 0;
 PutL(Trailer, P, HCRC);      { Basic header CRC }
 PutW(Trailer, P, 0);         { Extended header size = 0 }
 BlockWrite(F, Trailer, 6);
End;

Procedure WriteEndMarker(Var F: File);
Var
 EOA: Array[0..3] of Byte;
 P: Word;
Begin
 P := 0;
 PutW(EOA, P, $EA60);
 PutW(EOA, P, 0);             { BHdrSz=0 = end-of-archive }
 BlockWrite(F, EOA, 4);
End;

{ Find offset of the end-of-archive marker in an existing archive.
  Returns -1 on error, otherwise the byte offset of the EOA HeadID. }
Function FindEndOfArchive(Var F: File): LongInt;
Var
 Pos, Sz: LongInt;
 ByRd: Integer;
 Hdr: Array[0..3] of Byte;
 BHdrSz: Word;
 BHData: Array[0..511] of Byte;
 ExtSz: Word;
 BasicCSize: LongInt;
 RawCSize: Array[0..3] of Byte;
 BasicFType: Byte;
Begin
 Pos := 0;
 Sz := FileSize(F);
 While Pos < Sz Do Begin
  Seek(F, Pos);
  BlockRead(F, Hdr, 4, ByRd);
  If ByRd < 4 Then Begin FindEndOfArchive := -1; Exit; End;
  If(Hdr[0]<>$60)or(Hdr[1]<>$EA)Then Begin
   FindEndOfArchive := -1; Exit;
  End;
  BHdrSz := Hdr[2] or (Word(Hdr[3]) shl 8);
  If BHdrSz = 0 Then Begin
   FindEndOfArchive := Pos;
   Exit;
  End;
  If BHdrSz > 512 Then Begin FindEndOfArchive := -1; Exit; End;
  BlockRead(F, BHData, BHdrSz, ByRd);
  If ByRd < BHdrSz Then Begin FindEndOfArchive := -1; Exit; End;
  BasicFType := BHData[6];
  { CSize is at offset 1+1+1+1+1+1+1+1+4 = 12 within the basic header }
  RawCSize[0] := BHData[12]; RawCSize[1] := BHData[13];
  RawCSize[2] := BHData[14]; RawCSize[3] := BHData[15];
  BasicCSize := LongInt(RawCSize[0]) or
               (LongInt(RawCSize[1]) shl 8) or
               (LongInt(RawCSize[2]) shl 16) or
               (LongInt(RawCSize[3]) shl 24);
  { Skip CRC (4) + ExtHdrSz (2) [+ ExtHdr + extCRC if present] }
  Seek(F, Pos + 4 + LongInt(BHdrSz) + 4);
  BlockRead(F, Hdr, 2, ByRd);
  If ByRd < 2 Then Begin FindEndOfArchive := -1; Exit; End;
  ExtSz := Hdr[0] or (Word(Hdr[1]) shl 8);
  Pos := Pos + 4 + LongInt(BHdrSz) + 4 + 2;
  If ExtSz > 0 Then Inc(Pos, LongInt(ExtSz) + 4);
  If BasicFType <> 2 Then Inc(Pos, BasicCSize);
 End;
 FindEndOfArchive := -1;
End;

{ ============================================================ }
{ === ARJ Method 1 Encoder (literal-only Huffman)         === }
{ ============================================================ }

Type
 TOutBuf4K  = Array[0..4095] of Byte;     POutBuf4K  = ^TOutBuf4K;
 TBlockBuf  = Array[0..7999] of Byte;     PBlockBuf  = ^TBlockBuf;
 THuffPar   = Array[0..1023] of Integer;  PHuffPar   = ^THuffPar;
 THuffNF    = Array[0..1023] of LongInt;  PHuffNF    = ^THuffNF;

Var
 E_BitBuf: Word;
 E_BitCount: Byte;
 E_OutBuf: POutBuf4K;
 E_OutPos: Word;
 E_BytesWritten: LongInt;
 E_BlockBuf: PBlockBuf;
 E_BlockN: Word;
 E_FreqC: Array[0..D_NC-1] of LongInt;
 E_FreqT: Array[0..D_NT-1] of LongInt;
 E_LensC: Array[0..D_NC-1] of Byte;
 E_LensT: Array[0..D_NT-1] of Byte;
 E_CodesC: Array[0..D_NC-1] of Word;
 E_CodesT: Array[0..D_NT-1] of Word;
 E_HuffParent: PHuffPar;
 E_HuffNF: PHuffNF;

Procedure E_FlushOut;
Begin
 If E_OutPos > 0 Then Begin
  BlockWrite(SourceARJ, E_OutBuf^, E_OutPos);
  Inc(E_BytesWritten, E_OutPos);
  E_OutPos := 0;
 End;
End;

Procedure E_PutByte(B: Byte);
Begin
 E_OutBuf^[E_OutPos] := B;
 Inc(E_OutPos);
 If E_OutPos >= 4096 Then E_FlushOut;
End;

Procedure E_PutBits(N: Byte; V: Word);
Begin
 While N > 0 Do Begin
  Dec(N);
  If((V shr N) and 1) = 1 Then
   E_BitBuf := E_BitBuf or (Word(1) shl (15 - E_BitCount));
  Inc(E_BitCount);
  If E_BitCount = 16 Then Begin
   E_PutByte(Hi(E_BitBuf));
   E_PutByte(Lo(E_BitBuf));
   E_BitBuf := 0;
   E_BitCount := 0;
  End;
 End;
End;

Procedure E_FinishBits;
Begin
 If E_BitCount > 0 Then Begin
  E_PutByte(Hi(E_BitBuf));
  If E_BitCount > 8 Then E_PutByte(Lo(E_BitBuf));
  E_BitBuf := 0;
  E_BitCount := 0;
 End;
 E_FlushOut;
End;

{ Build canonical Huffman lengths from frequencies. NSym <= 510. }
Procedure E_BuildHuffman(Var Freq:Array of LongInt; NSym:Word;
                         Var Lens:Array of Byte);
Var
 I, J, A, B, M, Active, D: Integer;
Begin
 For I := 0 To NSym-1 Do Begin
  E_HuffNF^[I] := Freq[I];
  E_HuffParent^[I] := -1;
  Lens[I] := 0;
 End;
 Active := 0;
 For I := 0 To NSym-1 Do If Freq[I] > 0 Then Inc(Active);
 If Active = 0 Then Exit;
 If Active = 1 Then Begin
  For I := 0 To NSym-1 Do If Freq[I] > 0 Then Lens[I] := 1;
  Exit;
 End;
 M := NSym;
 While True Do Begin
  A := -1; B := -1;
  For I := 0 To M-1 Do
   If(E_HuffNF^[I] > 0)and(E_HuffParent^[I] = -1)Then Begin
    If(A = -1)or(E_HuffNF^[I] < E_HuffNF^[A])Then Begin
     B := A; A := I;
    End Else If(B = -1)or(E_HuffNF^[I] < E_HuffNF^[B])Then
     B := I;
   End;
  If B = -1 Then Break;
  E_HuffNF^[M] := E_HuffNF^[A] + E_HuffNF^[B];
  E_HuffParent^[M] := -1;
  E_HuffParent^[A] := M;
  E_HuffParent^[B] := M;
  Inc(M);
 End;
 For I := 0 To NSym-1 Do Begin
  If Freq[I] = 0 Then Continue;
  D := 0;
  J := I;
  While E_HuffParent^[J] <> -1 Do Begin
   Inc(D);
   J := E_HuffParent^[J];
  End;
  Lens[I] := D;
 End;
End;

Procedure E_CanonicalCodes(Var Lens:Array of Byte; NSym:Word;
                           Var Codes:Array of Word);
Var
 BLCount: Array[0..17] of Word;
 NextCode: Array[0..17] of Word;
 I: Integer;
 Code: LongInt;
 L: Byte;
Begin
 For I := 0 To 17 Do BLCount[I] := 0;
 For I := 0 To NSym-1 Do Inc(BLCount[Lens[I]]);
 BLCount[0] := 0;
 Code := 0;
 NextCode[0] := 0;
 For I := 1 To 16 Do Begin
  Code := (Code + BLCount[I-1]) shl 1;
  NextCode[I] := Code;
 End;
 For I := 0 To NSym-1 Do Begin
  L := Lens[I];
  If L > 0 Then Begin
   Codes[I] := NextCode[L];
   Inc(NextCode[L]);
  End Else
   Codes[I] := 0;
 End;
End;

{ Emit one length value (0..16) using the 3-bit + extension encoding
  used in ARJ for the NT and NP length tables. }
Procedure E_EmitLen3(L: Byte);
Var K: Integer;
Begin
 If L < 7 Then E_PutBits(3, L)
 Else Begin
  E_PutBits(3, 7);
  For K := 1 To L - 7 Do E_PutBits(1, 1);
  E_PutBits(1, 0);
 End;
End;

{ Write a PT-style length table (NT or NP). NN = alphabet size,
  NBit = bit-width of N, ISpecial = position to insert 2-bit zero-fill. }
Procedure E_WritePtLen(Var Lens:Array of Byte; NN:Word; NBit:Byte;
                       ISpecial:Integer);
Var
 I, ZCount, ActiveLast: Integer;
 N: Word;
Begin
 ActiveLast := -1;
 For I := 0 To NN-1 Do If Lens[I] <> 0 Then ActiveLast := I;
 N := ActiveLast + 1;
 If N = 0 Then Begin
  E_PutBits(NBit, 0);
  E_PutBits(NBit, 0);
  Exit;
 End;
 E_PutBits(NBit, N);
 I := 0;
 While I < N Do Begin
  E_EmitLen3(Lens[I]);
  Inc(I);
  If I = ISpecial Then Begin
   ZCount := 0;
   While(I < N)and(Lens[I] = 0)and(ZCount < 3)Do Begin
    Inc(I);
    Inc(ZCount);
   End;
   E_PutBits(2, ZCount);
  End;
 End;
End;

{ Walk CLen and either count NT symbols (CountOnly=True) or emit them
  using the previously-built NT Huffman codes (CountOnly=False). }
Procedure E_ProcessCLen(Var Lens:Array of Byte; NN:Word;
                        CountOnly:Boolean);
Var
 I, J, RunLen, Chunk: Integer;
Begin
 I := 0;
 While I < NN Do Begin
  If Lens[I] = 0 Then Begin
   J := I;
   While(J < NN)and(Lens[J] = 0)Do Inc(J);
   RunLen := J - I;
   While RunLen > 0 Do Begin
    If RunLen >= 20 Then Begin
     Chunk := RunLen;
     If Chunk > 531 Then Chunk := 531;
     If CountOnly Then Inc(E_FreqT[2])
     Else Begin
      E_PutBits(E_LensT[2], E_CodesT[2]);
      E_PutBits(D_CBIT, Chunk - 20);
     End;
     Dec(RunLen, Chunk);
    End Else If RunLen >= 3 Then Begin
     Chunk := RunLen;
     If Chunk > 18 Then Chunk := 18;
     If CountOnly Then Inc(E_FreqT[1])
     Else Begin
      E_PutBits(E_LensT[1], E_CodesT[1]);
      E_PutBits(4, Chunk - 3);
     End;
     Dec(RunLen, Chunk);
    End Else Begin
     If CountOnly Then Inc(E_FreqT[0])
     Else E_PutBits(E_LensT[0], E_CodesT[0]);
     Dec(RunLen);
    End;
   End;
   I := J;
  End Else Begin
   If CountOnly Then Inc(E_FreqT[Lens[I] + 2])
   Else E_PutBits(E_LensT[Lens[I] + 2], E_CodesT[Lens[I] + 2]);
   Inc(I);
  End;
 End;
End;

Procedure E_WriteCLenHeader(Var Lens:Array of Byte; NN:Word);
Var
 I, ActiveLast: Integer;
 N: Word;
Begin
 ActiveLast := -1;
 For I := 0 To NN-1 Do If Lens[I] <> 0 Then ActiveLast := I;
 N := ActiveLast + 1;
 If N = 0 Then Begin
  E_PutBits(D_CBIT, 0);
  E_PutBits(D_CBIT, 0);
  Exit;
 End;
 E_PutBits(D_CBIT, N);
 E_ProcessCLen(Lens, N, False);
End;

{ Flush the current literal block: emit BlockSize, the three length tables
  (NT, CLen, NP), then the Huffman-coded literals. }
Procedure E_FlushBlock;
Var
 I, ActiveLast: Integer;
 N: Word;
 NPLens: Array[0..D_NP-1] of Byte;
 OnlySym: Integer;
 ActiveCount: Integer;
Begin
 If E_BlockN = 0 Then Exit;
 { 1) Frequencies for C alphabet (literals only). }
 For I := 0 To D_NC-1 Do E_FreqC[I] := 0;
 For I := 0 To E_BlockN-1 Do Inc(E_FreqC[E_BlockBuf^[I]]);
 { 2) Build C Huffman tree. }
 ActiveCount := 0; OnlySym := -1;
 For I := 0 To D_NC-1 Do If E_FreqC[I] > 0 Then Begin
  Inc(ActiveCount);
  OnlySym := I;
 End;
 E_BuildHuffman(E_FreqC, D_NC, E_LensC);
 E_CanonicalCodes(E_LensC, D_NC, E_CodesC);
 { 3) BlockSize. }
 E_PutBits(16, E_BlockN);
 If ActiveCount = 1 Then Begin
  { Single-symbol block: use special forms throughout. }
  { NT: special N=0, C=0 }
  E_PutBits(D_TBIT, 0);
  E_PutBits(D_TBIT, 0);
  { CLen: special N=0, C=OnlySym }
  E_PutBits(D_CBIT, 0);
  E_PutBits(D_CBIT, OnlySym);
  { NP: special N=0, C=0 }
  E_PutBits(D_PBIT, 0);
  E_PutBits(D_PBIT, 0);
  { No further bits per symbol: decoder returns the constant via CTable. }
 End Else Begin
  { 4) Determine N for CLen and count NT symbol frequencies. }
  ActiveLast := -1;
  For I := 0 To D_NC-1 Do If E_LensC[I] <> 0 Then ActiveLast := I;
  N := ActiveLast + 1;
  For I := 0 To D_NT-1 Do E_FreqT[I] := 0;
  E_ProcessCLen(E_LensC, N, True);
  { 5) Build NT Huffman tree and codes. }
  E_BuildHuffman(E_FreqT, D_NT, E_LensT);
  E_CanonicalCodes(E_LensT, D_NT, E_CodesT);
  { 6) Write NT length table. }
  E_WritePtLen(E_LensT, D_NT, D_TBIT, 3);
  { 7) Write CLen using NT tree. }
  E_WriteCLenHeader(E_LensC, D_NC);
  { 8) NP length table: all zero (no matches). }
  For I := 0 To D_NP-1 Do NPLens[I] := 0;
  E_WritePtLen(NPLens, D_NP, D_PBIT, -1);
 End;
 { 9) Emit each literal as its Huffman code. }
 If ActiveCount > 1 Then
  For I := 0 To E_BlockN-1 Do
   E_PutBits(E_LensC[E_BlockBuf^[I]], E_CodesC[E_BlockBuf^[I]]);
 E_BlockN := 0;
End;

Procedure E_BeginEncode;
Begin
 E_BitBuf := 0;
 E_BitCount := 0;
 E_OutPos := 0;
 E_BytesWritten := 0;
 E_BlockN := 0;
End;

Procedure E_AddByte(B: Byte);
Begin
 E_BlockBuf^[E_BlockN] := B;
 Inc(E_BlockN);
 If E_BlockN >= 8000 Then E_FlushBlock;
End;

Procedure E_EndEncode;
Begin
 If E_BlockN > 0 Then E_FlushBlock;
 E_FinishBits;
End;

{ Compress a file using method 1 (literal-only Huffman).
  Returns the number of compressed bytes written. }
Function E_CompressFile(Var Src: File; OSize: LongInt;
                        Var FileCRC: LongInt): LongInt;
Var
 Buf: Array[0..4095] of Byte;
 ToRead: LongInt;
 Got, I: Integer;
 CRC: LongInt;
Begin
 D_InitCRC;
 CRC := LongInt($FFFFFFFF);
 E_BeginEncode;
 While OSize > 0 Do Begin
  If OSize > 4096 Then ToRead := 4096 Else ToRead := OSize;
  BlockRead(Src, Buf, ToRead, Got);
  If Got <= 0 Then Break;
  For I := 0 To Got-1 Do Begin
   CRC := D_UpdateCRC(CRC, Buf[I]);
   E_AddByte(Buf[I]);
  End;
  Dec(OSize, Got);
 End;
 E_EndEncode;
 FileCRC := CRC xor LongInt($FFFFFFFF);
 E_CompressFile := E_BytesWritten;
End;

{ ============================================================ }

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 FirstEntry:Boolean;
 HeaderBuffer:ArjHeader;
 ByteReaded,Got:Integer;
 FilePosFindFiles,PackSize,NumFiles,DataPos,Remaining,ToRead:LongInt;
 DT:DateTime;
 B:Byte;
 TargetName:String;
 ExtractBuf:Array[0..4095]of Byte;
 ResCRC, ExpCRC:LongInt;
 OkExtract:Boolean;
 ParamIdx:Integer;
 SrcFile:File;
 SrcName,StoredName:String;
 SrcSize,EOAOff:LongInt;
 SrcCRC:LongInt;
 SrcDosDT:LongInt;
 SR:SearchRec;
 ArchiveExists:Boolean;
 DowDummy:Word;
 Method:Byte;
 SwArg:String;
 ArcName:String;
 FirstFileIdx:Integer;
 HeaderStart, DataEnd, CompressedSize: LongInt;

BEGIN
 New(D_InBuf);
 New(D_CTable);
 New(D_LeftT);
 New(D_RightT);
 New(D_Dict);
 New(D_CRCTab);
 New(E_OutBuf);
 New(E_BlockBuf);
 New(E_HuffParent);
 New(E_HuffNF);
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ARJ : Cette commande permet d''afficher la liste des fichiers contenu dans ',
          'une archive de format ARJ.');
  WriteLn;
  WriteLn('Syntaxe : ARJ l archive.arj');
  WriteLn('          ARJ e archive.arj  (extraire les fichiers)');
  WriteLn('          ARJ x archive.arj  (extraire les fichiers)');
  WriteLn('          ARJ a archive.arj fichier1 [fichier2 ...]  (ajouter des fichiers)');
  WriteLn('Switch  : -m<N>  M�thode de compression (0=stockage, 1=Huffman, 2-4=non support�)');
 End
  Else
 If ParamCount>0Then Begin
  If ParamStr(1)='l'Then Begin
   If ParamStr(2)=''Then Begin
    WriteLn('Nom d''archive ARJ attendu');
    Halt;
   End;
   {$I-}Assign(SourceARJ,ParamStr(2));
   Reset(SourceARJ,1);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Fichier ARJ introuvable : ',ParamStr(2));
    Halt;
   End;
   NumFiles:=0;
   FilePosFindFiles:=0;
   FirstEntry:=True;
   Repeat
    Seek(SourceARJ,FilePosFindFiles);
    FillChar(HeaderBuffer,SizeOf(HeaderBuffer),0);
    BlockRead(SourceARJ,HeaderBuffer,SizeOf(HeaderBuffer),ByteReaded);
    If HeaderBuffer.BHdrSz>0 Then Begin
     B:=1;
     TargetName:='';
     While HeaderBuffer.NameDat[B]<>#0 do Begin
      If HeaderBuffer.NameDat[B]='/'Then TargetName:=''
                                    Else TargetName:=TargetName+HeaderBuffer.NameDat[B];
      Inc(B);
     End;
     PackSize:=HeaderBuffer.BHdrSz+HeaderBuffer.CSize;
     If HeaderBuffer.FType=2Then PackSize:=HeaderBuffer.BHdrSz;
     If HeaderBuffer.BHdrSz=0Then PackSize:=0;
     Inc(FilePosFindFiles,PackSize+10);
     If(FirstEntry)Then Begin
      FirstEntry:=False;
      Case Language of
       _English:Begin
        WriteLn('Processing archive: ',TargetName);
        Write('Archive date:       ');
       End;
       Else Begin
        WriteLn('Traitement d''archive : ',TargetName);
        Write('Archive date : ');
       End;
      End;
      UnpackTime(HeaderBuffer.DosDT,DT);
      Write(DT.Year:4,'-',PadZeroLeft(DT.Month,2),'-',PadZeroLeft(DT.Day,2),' ');
      Write(DT.Hour:2,':',PadZeroLeft(DT.Min,2),':',PadZeroLeft(DT.Sec,2));
      WriteLn;
      Case Language of
       _English:WriteLn(PadRight('Filename',12),' ',
                        PadRight('Original',10),' ',
                        PadRight('Compressed',10),' ',
                        PadRight('Ratio',5),' ',
                        PadRight('DateTime',8),' ',
                        PadRight('modified',8),' ',
                        PadRight('CRC-32',8),' ',
                        'AttrBTPMGVX');
       Else WriteLn(PadRight('Nom fichier',12),' ',
                    PadRight('Original',10),' ',
                    PadRight('Compress�',10),' ',
                    PadRight('Ratio',5),' ',
                    PadRight('DateHeur',8),' ',
                    PadRight('modifi�',8),' ',
                    PadRight('CRC-32',8),' ',
                    'AttrBTPMGVX');
      End;
      WriteLn('------------ ---------- ---------- ----- ',
              '----------------- -------- -----------');
     End
      Else
     Begin
      Write(PadRight(TargetName,12),' ');
      Write(HeaderBuffer.OSize:10,' ');
      Write(PackSize:10,' ');
      Write(HeaderBuffer.CSize/HeaderBuffer.OSize:5:3,' ');
      UnpackTime(HeaderBuffer.DosDT,DT);
      Write(PadZeroLeft(DT.Year mod 100,2),'-',PadZeroLeft(DT.Month,2),
              '-',PadZeroLeft(DT.Day,2),' ');
      Write(DT.Hour:2,':',PadZeroLeft(DT.Min,2),':',PadZeroLeft(DT.Sec,2));
      Write(' ',LongHex2Str(HeaderBuffer.SEFP));
      WriteLn;
      Inc(NumFiles);
     End;
    End;
   Until HeaderBuffer.BHdrSz=0;
   If NumFiles>0 Then Begin
    WriteLn('------------ ---------- ---------- -----');
    WriteLn(NumFiles:3,' fichiers');
   End;
   Close(SourceARJ);
  End
   Else
  If(ParamStr(1)='e')or(ParamStr(1)='x')Then Begin
   If ParamStr(2)=''Then Begin
    WriteLn('Nom d''archive ARJ attendu');
    Halt;
   End;
   {$I-}Assign(SourceARJ,ParamStr(2));
   Reset(SourceARJ,1);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Fichier ARJ introuvable : ',ParamStr(2));
    Halt;
   End;
   NumFiles:=0;
   FilePosFindFiles:=0;
   FirstEntry:=True;
   Repeat
    Seek(SourceARJ,FilePosFindFiles);
    FillChar(HeaderBuffer,SizeOf(HeaderBuffer),0);
    BlockRead(SourceARJ,HeaderBuffer,SizeOf(HeaderBuffer),ByteReaded);
    If HeaderBuffer.BHdrSz>0 Then Begin
     B:=1;
     TargetName:='';
     While(B<=120)and(HeaderBuffer.NameDat[B]<>#0)do Begin
      If HeaderBuffer.NameDat[B]='/'Then TargetName:=''
                                    Else TargetName:=TargetName+HeaderBuffer.NameDat[B];
      Inc(B);
     End;
     PackSize:=LongInt(HeaderBuffer.BHdrSz)+HeaderBuffer.CSize;
     If HeaderBuffer.FType=2Then PackSize:=HeaderBuffer.BHdrSz;
     If HeaderBuffer.BHdrSz=0Then PackSize:=0;
     If FirstEntry Then Begin
      FirstEntry:=False;
     End
      Else
     If(HeaderBuffer.FType<=1)and(TargetName<>'')Then Begin
      DataPos:=FilePosFindFiles+LongInt(HeaderBuffer.BHdrSz)+10;
      If(HeaderBuffer.SVer>3)Then Begin
       Case Language of
        _English:WriteLn('Skipping ',TargetName,
                         ' : compression method ',HeaderBuffer.SVer,
                         ' not supported');
        Else WriteLn('Ignor� ',TargetName,
                     ' : m�thode de compression ',HeaderBuffer.SVer,
                     ' non support�e');
       End;
      End
       Else
      Begin
       Seek(SourceARJ,DataPos);
       {$I-}Assign(DestFile,TargetName);
       Rewrite(DestFile,1);{$I+}
       If IoResult<>0 Then Begin
        WriteLn('Impossible de cr�er : ',TargetName);
       End
        Else
       Begin
        ExpCRC:=HeaderBuffer.SEFP;
        OkExtract:=True;
        If HeaderBuffer.SVer=0 Then Begin
         { M�thode 0 : copie sans compression }
         D_InitCRC;
         ResCRC:=LongInt($FFFFFFFF);
         Remaining:=HeaderBuffer.OSize;
         While Remaining>0 Do Begin
          If Remaining>4096 Then ToRead:=4096 Else ToRead:=Remaining;
          BlockRead(SourceARJ,ExtractBuf,ToRead,Got);
          If Got<=0 Then Begin OkExtract:=False; Break; End;
          BlockWrite(DestFile,ExtractBuf,Got);
          For B:=0 To Got-1 Do
           ResCRC:=D_UpdateCRC(ResCRC,ExtractBuf[B]);
          Dec(Remaining,Got);
         End;
         ResCRC:=ResCRC xor LongInt($FFFFFFFF);
        End
         Else
        Begin
         { M�thodes 1,2,3 : LZ77 + Huffman dynamique }
         OkExtract:=D_Decompress(HeaderBuffer.CSize,
                                 HeaderBuffer.OSize,
                                 ExpCRC,ResCRC);
        End;
        Close(DestFile);
        If Not OkExtract Then Begin
         Case Language of
          _English:WriteLn('Error extracting: ',TargetName);
          Else WriteLn('Erreur d''extraction : ',TargetName);
         End;
        End
         Else
        If ResCRC<>ExpCRC Then Begin
         Case Language of
          _English:WriteLn('CRC mismatch on: ',TargetName,
                           ' (expected ',LongHex2Str(ExpCRC),
                           ', got ',LongHex2Str(ResCRC),')');
          Else WriteLn('CRC incorrect : ',TargetName,
                       ' (attendu ',LongHex2Str(ExpCRC),
                       ', obtenu ',LongHex2Str(ResCRC),')');
         End;
         Inc(NumFiles);
        End
         Else
        Begin
         Case Language of
          _English:WriteLn('Extracted: ',TargetName,' (',HeaderBuffer.OSize,' bytes)');
          Else WriteLn('Extrait : ',TargetName,' (',HeaderBuffer.OSize,' octets)');
         End;
         Inc(NumFiles);
        End;
       End;
      End;
     End;
     Inc(FilePosFindFiles,PackSize+10);
    End;
   Until HeaderBuffer.BHdrSz=0;
   Case Language of
    _English:WriteLn(NumFiles,' file(s) extracted');
    Else WriteLn(NumFiles,' fichier(s) extrait(s)');
   End;
   Close(SourceARJ);
  End
   Else
  If ParamStr(1)='a'Then Begin
   Method := 0;
   ArcName := '';
   FirstFileIdx := 0;
   { Scan parameters: classify switches (-m<N>, /m<N>) and positionals.
     First positional = archive name; subsequent positionals = files. }
   ParamIdx := 2;
   While ParamStr(ParamIdx) <> '' Do Begin
    SwArg := ParamStr(ParamIdx);
    If(Length(SwArg) >= 2)and((SwArg[1]='-')or(SwArg[1]='/'))Then Begin
     If(Length(SwArg) >= 3)and((SwArg[2]='m')or(SwArg[2]='M'))Then Begin
      If(SwArg[3] in ['0'..'4'])and(Length(SwArg) = 3)Then Begin
       Method := Ord(SwArg[3]) - Ord('0');
       If Method > 1 Then Begin
        WriteLn('M�thode de compression ',Method,
                ' non support�e en �criture (utilisez -m0 ou -m1)');
        Halt;
       End;
      End
       Else
      Begin
       WriteLn('Valeur invalide pour le switch -m : ',SwArg);
       Halt;
      End;
     End
      Else
     Begin
      WriteLn('Switch non reconnu : ',SwArg);
      Halt;
     End;
    End
     Else
    Begin
     If ArcName = '' Then ArcName := SwArg
     Else If FirstFileIdx = 0 Then FirstFileIdx := ParamIdx;
    End;
    Inc(ParamIdx);
   End;
   If ArcName = '' Then Begin
    WriteLn('Nom d''archive ARJ attendu');
    Halt;
   End;
   If FirstFileIdx = 0 Then Begin
    WriteLn('Au moins un fichier source est requis');
    Halt;
   End;
   Assign(SourceARJ,ArcName);
   {$I-}Reset(SourceARJ,1);{$I+}
   ArchiveExists := IoResult = 0;
   If ArchiveExists Then Begin
    EOAOff := FindEndOfArchive(SourceARJ);
    If EOAOff < 0 Then Begin
     Close(SourceARJ);
     WriteLn('Archive ARJ corrompue ou non valide : ',ArcName);
     Halt;
    End;
    Seek(SourceARJ, EOAOff);
    Truncate(SourceARJ);
   End
    Else
   Begin
    {$I-}Rewrite(SourceARJ,1);{$I+}
    If IoResult <> 0 Then Begin
     WriteLn('Impossible de cr�er l''archive : ',ArcName);
     Halt;
    End;
    GetFTime(SourceARJ, SrcDosDT);
    If SrcDosDT = 0 Then Begin
     GetDate(DT.Year, DT.Month, DT.Day, DowDummy);
     GetTime(DT.Hour, DT.Min, DT.Sec, DowDummy);
     PackTime(DT, SrcDosDT);
    End;
    WriteArjHeader(SourceARJ, 2, 0, SrcDosDT, 0, 0, 0,
                   StripPath(ArcName), '');
   End;
   NumFiles := 0;
   ParamIdx := FirstFileIdx;
   While ParamStr(ParamIdx) <> '' Do Begin
    SrcName := ParamStr(ParamIdx);
    If(SrcName[1]='-')or(SrcName[1]='/')Then Begin
     Inc(ParamIdx);
     Continue;
    End;
    {$I-}Assign(SrcFile, SrcName);
    Reset(SrcFile, 1);{$I+}
    If IoResult <> 0 Then Begin
     WriteLn('Fichier introuvable : ',SrcName);
    End
     Else
    Begin
     SrcSize := FileSize(SrcFile);
     GetFTime(SrcFile, SrcDosDT);
     StoredName := StripPath(SrcName);
     If Method = 0 Then Begin
      SrcCRC := CRC32OfFile(SrcFile, SrcSize);
      Seek(SrcFile, 0);
      WriteArjHeader(SourceARJ, 0, 0, SrcDosDT, SrcSize, SrcSize, SrcCRC,
                     StoredName, '');
      Remaining := SrcSize;
      While Remaining > 0 Do Begin
       If Remaining > 4096 Then ToRead := 4096 Else ToRead := Remaining;
       BlockRead(SrcFile, ExtractBuf, ToRead, Got);
       If Got <= 0 Then Break;
       BlockWrite(SourceARJ, ExtractBuf, Got);
       Dec(Remaining, Got);
      End;
      Case Language of
       _English:WriteLn('Adding: ',StoredName,' (',SrcSize,' bytes, stored)');
       Else WriteLn('Ajout : ',StoredName,' (',SrcSize,' octets, stock�)');
      End;
     End
      Else
     Begin
      { Method 1: write header with placeholder, compress, patch CSize. }
      HeaderStart := FilePos(SourceARJ);
      WriteArjHeader(SourceARJ, 0, 1, SrcDosDT, 0, SrcSize, 0,
                     StoredName, '');
      DataEnd := FilePos(SourceARJ);
      CompressedSize := E_CompressFile(SrcFile, SrcSize, SrcCRC);
      DataEnd := FilePos(SourceARJ);
      Seek(SourceARJ, HeaderStart);
      WriteArjHeader(SourceARJ, 0, 1, SrcDosDT, CompressedSize, SrcSize,
                     SrcCRC, StoredName, '');
      Seek(SourceARJ, DataEnd);
      Case Language of
       _English:WriteLn('Adding: ',StoredName,' (',SrcSize,' -> ',
                        CompressedSize,' bytes, method 1)');
       Else WriteLn('Ajout : ',StoredName,' (',SrcSize,' -> ',
                    CompressedSize,' octets, m�thode 1)');
      End;
     End;
     Close(SrcFile);
     Inc(NumFiles);
    End;
    Inc(ParamIdx);
   End;
   WriteEndMarker(SourceARJ);
   Close(SourceARJ);
   Case Language of
    _English:WriteLn(NumFiles,' file(s) added');
    Else WriteLn(NumFiles,' fichier(s) ajout�(s)');
   End;
  End
   Else
  WriteLn('Param�tre non reconnu');
 End
  Else
 WriteLn('Param�tre requis');
END.
