{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program Truncate_;

Var
 I:Integer;
 Err:Word;
 Size:LongInt;
 FileName:String;

Procedure TruncToFileSize(FileName:String;NewSize:LongInt);
Var
 FileToTrunc:File of Byte;
Begin
 Assign(FileToTrunc,FileName);
 Reset(FileToTRunc);
 Seek(FileToTrunc,NewSize);
 Truncate(FileToTrunc);
 Close(FileToTrunc);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('TRUNCATE : Cette commande permet de reduire ou augmenter la taille d''un fichier.');
  WriteLn;
  WriteLn('Syntaxe : TRUNCATE -size=taille nomdufichier');
 End
  Else
 Begin
  Size:=-1;
  FileName:='';
  For I:=1 to ParamCount do Begin
   If Copy(ParamStr(I),1,6)='-size='Then Begin
    Val(Copy(ParamStr(I),7,255),Size,Err);
   End
    Else
   FileName:=ParamStr(I);
  End;
  If Size=-1 Then Begin
   WriteLn('La taille du fichier n''est pas d‚finit');
  End
   Else
  Begin
   If FileName<>''Then Begin
    TruncToFileSize(FileName,Size);
   End
    Else
   WriteLn('Fichier requis');
  End;
 End;
END.