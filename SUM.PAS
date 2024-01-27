{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program SUM;

Uses DOS;

{$R-}

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 SourcePath,Source:String;
 CheckSum:LongInt;
 NumFiles,I:Word;
 SRec:SearchRec;
 C:Char;
 FileArray:Array[1..128] of ^SearchRec;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function Path2Dir(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 Path2Dir:='';
 If Path=''Then Exit;
 FSplit(Path,D,N,E);
 If E=''Then Begin
  If D[Length(D)]<>'\'Then D:=D+'\';
  D:=D+E;
 End;
 If D=''Then Path2Dir:='' Else
 If D[Length(D)]<>'\'Then D:=D+'\';
 Path2Dir:=D;
End;

Function PadZeroLeft(Value:LongInt;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
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

Procedure SumFile(FName:String;FSize:LongInt);
Const
 BufSize=1024;
Type
 FBuf=Array[1..BufSize]of Byte;
Var
 I:Word;
 Source:File;
 Sum:Word;
 Buffer:^FBuf;
 CheckSum:LongInt;
Begin
 CheckSum:=0;
 New(Buffer);
 {$I-}Assign(Source,FName);
 Reset(Source,1);{$I+}
 If IoResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier : ',FName);
  Halt;
 End;
 Repeat
  BlockRead(Source,Buffer^,BufSize,Sum);
  For I:=1 to Sum do Begin
  CheckSum:=(CheckSum shr 1)+((checkSum and 1) shl 15);
  CheckSum:=(CheckSum+Buffer^[I]) and $FFFF;
  End;
 Until Sum=0;
 Close(Source);
 Dispose(Buffer);
 Write(PadZeroLeft(CheckSum,5),' ',Succ(FSize shr 10),' ',FName);
End;

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
  WriteLn('SUM : Cette commande permet d''afficher la sommation de chaque fichier.');
  WriteLn;
  WriteLn('Syntaxe : SUM [/?] filename');
  WriteLn;
  WriteLn(' /?          Ce paramŠtre permet de founir de l''aide sur cette commande.');
  WriteLn('filename     Ce paramŠtre permet d''indiquer le fichier … v‚rifier');
 End
  Else
 If ParamCount>0 Then Begin
  Source:=FExpand(ParamStr(1));
  SourcePath:=Path2Dir(Source);
  NumFiles:=0;
  FindFirst(Source,AnyFile,SRec);
  While DOSError=0 do Begin
   If Not(((SRec.Attr and Directory)>0)or((SRec.attr and VolumeID)>0)and(SRec.Size>0))Then Begin
    Inc(NumFiles);
    New(FileArray[NumFiles]);
    FileArray[numFiles]^:=SRec;
   End;
   FindNext(srec);
   If NumFiles+1>=High(FileArray)Then Break;
  End;
  If NumFiles=0Then Begin
   WriteLn('Fichier introuvable');
  End
   Else
  For I:=1 to NumFiles do SumFile(SourcePath+FileArray[i]^.Name,FileArray[i]^.Size);
 End
  Else
 Begin
  CheckSum:=0;
  While Not EOF do Begin
   {$I-}Read(C);{$I+}
   If IOResult<>0 Then Break;
   CheckSum:=(CheckSum shr 1)+((CheckSum and 1) shl 15);
   CheckSum:=(CheckSum+Byte(C)) and $FFFF;
  End;
  WriteLn(PadZeroLeft(CheckSum,5),1:6);
 End;
END.
