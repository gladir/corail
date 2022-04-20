{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program PWD;

Var
 CurrDir:String;

Procedure ChangeChar(Var Str:String;OldChar,NewChar:Char);
Var
 I:Byte;
Begin
 For I:=1 to Length(Str)do Begin
  If Str[I]=OldChar Then Str[I]:=NewChar;
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('PWD : Cette commande permet d''afficher le repertoire de travail.');
  WriteLn;
  WriteLn('Syntaxe : PWD');
 End
  Else
 Begin
  GetDir(0,CurrDir);
  ChangeChar(CurrDir,'\','/');
  WriteLn(CurrDir);
 End;
END.
