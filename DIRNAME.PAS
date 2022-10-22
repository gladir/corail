{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program DIRNAME;

Uses DOS;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 Zero:Boolean;
 I:Integer;
 Path:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function GetDirName(Path:String):String;
Var
 I:Integer;
Begin
 GetDirName:='';
 For I:=Length(Path)downto 1 do Begin
  If Path[I]in[';','/','\',':']Then Begin
   GetDirName:=Copy(Path,1,I);
   Exit;
  End;
 End;
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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  Case Language of
   _English:Begin
    WriteLn('Prints a file path with its final component removed.');
    WriteLn;
    WriteLn('Syntax: DIRNAME path [-z]');
   End;
   Else Begin
    WriteLn('DIRNAME : Cette commande permet de retourner le nom du fichier seulement.');
    WriteLn;
    WriteLn('Syntaxe : DIRNAME path [-z]');
   End;
  End;
 End
  Else
 If ParamCount>0Then Begin
  Zero:=False;
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='-z')or(ParamStr(I)='-zero')Then Zero:=True;
  End;
  For I:=1 to ParamCount do Begin
   If Not((ParamStr(I)='-z')or(ParamStr(I)='-zero'))Then Begin
    Path:=GetDirName(ParamStr(1));
    If(Zero)Then Write(Path)
            Else WriteLn(Path);
   End;
  End;
 End
  Else
 Begin
  WriteLn('Parametre requis !');
 End;
END.
