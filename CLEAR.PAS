{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program CLEAR;

Uses Crt;

Var
 FirstParam:String;

BEGIN
 FirstParam:=ParamStr(1);
 If(FirstParam='/?')or(FirstParam='--help')or(FirstParam='-h')or
   (FirstParam='/h')or(FirstParam='/H')Then Begin
  WriteLn('CLEAR   Cette commande permet d''effacer l''ecran.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('CLEAR [/?]');
  WriteLn;
  WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 Begin
  ClrScr;
 End;
END.