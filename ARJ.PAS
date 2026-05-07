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

Var
 D_BitBuf: Word;
 D_BitCount: Byte;
 D_SubBitBuf: Byte;
 D_InBuf: Array[0..4095] of Byte;
 D_InPos, D_InEnd: Word;
 D_CompLeft: LongInt;
 D_CLen: Array[0..509] of Byte;
 D_PtLen: Array[0..18] of Byte;
 D_CTable: Array[0..4095] of Word;
 D_PtTable: Array[0..255] of Word;
 D_LeftT, D_RightT: Array[0..1019] of Word;
 D_BlockSize: Word;
 D_Dict: Array[0..D_DICSIZ-1] of Byte;
 D_DictPos: Word;
 D_CRCTab: Array[0..255] of LongInt;
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
  D_CRCTab[I]:=C;
 End;
 D_CRCInited:=True;
End;

Function D_UpdateCRC(CRC: LongInt; B: Byte): LongInt;
Begin
 D_UpdateCRC := (CRC shr 8) xor D_CRCTab[(CRC xor B) and $FF];
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
 BlockRead(SourceARJ, D_InBuf, Need, Got);
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
 D_GetByte := D_InBuf[D_InPos];
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
     1: Tmp := D_LeftT[PIdx];
    Else Tmp := D_RightT[PIdx];
    End;
    If Tmp = 0 Then Begin
     D_RightT[Avail] := 0;
     D_LeftT[Avail] := 0;
     Tmp := Avail;
     Case PMode Of
      0: Tbl^[PIdx] := Avail;
      1: D_LeftT[PIdx] := Avail;
     Else D_RightT[PIdx] := Avail;
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
    1: D_LeftT[PIdx] := Ch;
   Else D_RightT[PIdx] := Ch;
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
  For I:=0 To 4095 Do D_CTable[I] := C;
 End Else Begin
  I := 0;
  While I < N Do Begin
   C := D_PtTable[D_BitBuf shr 8];
   If C >= D_NT Then Begin
    Mask := $80;
    Repeat
     If(D_BitBuf and Mask)<>0 Then C := D_RightT[C]
                              Else C := D_LeftT[C];
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
  D_MakeTable(D_NC, 12, PByteBuf(@D_CLen), PWordBuf(@D_CTable));
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
 J := D_CTable[D_BitBuf shr 4];
 If J >= D_NC Then Begin
  Mask := $08;
  Repeat
   If(D_BitBuf and Mask)<>0 Then J := D_RightT[J]
                            Else J := D_LeftT[J];
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
   If(D_BitBuf and Mask)<>0 Then J := D_RightT[J]
                            Else J := D_LeftT[J];
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
   D_Dict[D_DictPos] := C;
   ResCRC := D_UpdateCRC(ResCRC, C);
   Inc(D_DictPos);
   If D_DictPos >= D_DICSIZ Then Begin
    BlockWrite(DestFile, D_Dict, D_DICSIZ);
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
    D_Dict[D_DictPos] := D_Dict[P];
    ResCRC := D_UpdateCRC(ResCRC, D_Dict[P]);
    Inc(P);
    If P >= D_DICSIZ Then P := 0;
    Inc(D_DictPos);
    If D_DictPos >= D_DICSIZ Then Begin
     BlockWrite(DestFile, D_Dict, D_DICSIZ);
     D_DictPos := 0;
    End;
    Dec(J);
   End;
  End;
 End;
 If(D_DictPos > 0) and (not D_Error) Then
  BlockWrite(DestFile, D_Dict, D_DictPos);
 ResCRC := ResCRC xor LongInt($FFFFFFFF);
 D_Decompress := (not D_Error) and (Count >= OSize);
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

BEGIN
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
  WriteLn('Param�tre non reconnu');
 End
  Else
 WriteLn('Param�tre requis');
END.
