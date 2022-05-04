{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program HOSTNAME;

Uses DOS;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('HOSTNAME : Cette commande permet de retourner le nom de hote.');
  WriteLn;
  WriteLn('Syntaxe : HOSTNAME');
 End
  Else
 WriteLn(GetEnv('COMPUTERNAME'));
END.