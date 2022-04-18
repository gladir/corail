{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program VER;

Uses DOS;

Var
 _Version:Word;
 FirstParam:String;

BEGIN
 FirstParam:=ParamStr(1);
 If FirstParam='/?'Then Begin
  WriteLn('VER   Cette commande permet de demander la version du systeme d''exploitation.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('VER [/?]');
  WriteLn;
  WriteLn(' /?    Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 Begin
  _Version:=DosVersion;
  WriteLn('DOS version ',Lo(_Version),'.',Hi(_Version));
 End;
END.