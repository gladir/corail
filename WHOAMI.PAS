{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program WHOAMI;

Uses DOS;

Function StrToLower(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
 End;
 StrToLower:=S;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('WHOAMI : Cette commande permet de retourner l''utilisateur connecte.');
  WriteLn;
  WriteLn('Syntaxe : WHOAMI');
 End
  Else
 Begin
  WriteLn(StrToLower(GetEnv('USERDOMAIN')),'\',StrToLower(GetEnv('USERNAME')));
 End;
END.