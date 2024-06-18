{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CPUCHECK;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('CPUCHECK : Cette commande permet de retourner un ERRORLEVEL ',
          'correspondant au type de microprocesseur d‚tect‚.');
  WriteLn;
  WriteLn('Syntaxe : CPUCHECK [/?]');
 End
  Else
 Begin
  Case Test8086 of
   0:Halt(0);
   1:Halt(2);
   Else Halt(3);
  End;
 End;
END.