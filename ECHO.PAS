{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program ECHOCommand;

Var
 I:Integer;
 FirstParam:String;

BEGIN
 FirstParam:=ParamStr(1);
 If FirstParam='/?'Then Begin
  WriteLn('ECHO   Cette commande permet d''afficher un message sur le console du systeme d''exploitation.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('ECHO [/?] message');
  WriteLn;
  WriteLn('       /?  Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn('  message  Ce parametre permet d''afficher un message');
 End
  Else
 Begin
  For I:=1 to ParamCount do Write(ParamStr(I));
  WriteLn;
 End;
END.