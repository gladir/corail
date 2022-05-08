{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program LINE(Input,Output);

Var
 CurrLine:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('LINE : Cette commande permet de lire une ligne.');
  WriteLn;
  WriteLn('Syntaxe : LINE');
 End
  Else
 Begin
  ReadLn(Input,CurrLine);
  WriteLn(Output,CurrLine);
  WriteLn;
  Halt(1);
 End;
END.