{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal)
}

Program SD;

Uses DOS;

Var
 Regs:Registers;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('SD : Cette commande permet d''imprimer l''ecran.');
  WriteLn;
  WriteLn('Syntaxe : SD');
 End
  Else
 Intr($05,Regs);
END.