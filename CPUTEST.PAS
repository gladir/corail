{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}


Program CPUTEST;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('CPUTEST : Cette commande permet de verifier le type de microprocesseur.');
  WriteLn;
  WriteLn('Syntaxe : CPUTEST [/?]');
 End
  Else
 Case Test8086 of
  0:WriteLn('Microprocesseur 8086 detecte');
  1:WriteLn('Microprocesseur 80286 detecte');
  2:WriteLn('Microprocesseur 80386 detecte');
  Else WriteLn('Microprocesseur inconnu : ',Test8086);
 End;
END.
