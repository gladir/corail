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
  BHdrSz:Word;           { Taille de la simple entàte de fichier }
  FHdrSz:Byte;           { Taille de l'entàte fichier }
  AVNo:Byte;
  MAVX:Byte;
  HostOS:Byte;
  Flags:Byte;
  SVer:Byte;
  FType:Byte;
  Res1:Byte;
  DosDT:LongInt;
  CSize:LongInt;         { Taille compressÇ }
  OSize:LongInt;         { Taille original }
  SEFP:LongInt;
  FSFPos:Word;
  SEDLgn:Word;
  Res2:Word;
  NameDat:Array[1..120]of Char;{ DÇbut du nom,... }
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

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 SourceARJ:File;
 FirstEntry:Boolean;
 HeaderBuffer:ArjHeader;
 ByteReaded:Integer;
 FilePosFindFiles,PackSize,NumFiles:LongInt;
 DT:DateTime;
 B:Byte;
 TargetName:String;

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
                    PadRight('CompressÇ',10),' ',
                    PadRight('Ratio',5),' ',
                    PadRight('DateHeur',8),' ',
                    PadRight('modifiÇ',8),' ',
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
  WriteLn('Paramätre non reconnu');
 End
  Else
 WriteLn('Paramätre requis');
END.
