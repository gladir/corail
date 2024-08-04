{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program PRINTENV;

Uses Crt,DOS;

Var
 Pause:Boolean;
 I,P:Integer;
 FirstParam:String;

BEGIN
 Pause:=False;
 FirstParam:=ParamStr(1);
 If(FirstParam='/?')or(FirstParam='--help')or(FirstParam='-h')or
   (FirstParam='/h')or(FirstParam='/H')Then Begin
  WriteLn('PRINTENV   Cette commande permet de demander le contenu des ',
          'variables d''environnement du systeme d''exploitation');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('PRINTENV [/?] [-p] [nom]');
  WriteLn;
  WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' -p   Ce parametre permet d''effectuer une pause entre chaque page');
  WriteLn(' nom  Ce parametre permet d''afficher la valeur d''une variable');
  Halt;
 End
  Else
 Begin
  If(FirstParam='-p')Then Pause:=True
   Else
  If FirstParam<>''Then Begin
   WriteLn(GetEnv(FirstParam));
   Halt;
  End;
  P:=0;
  For I:=0to EnvCount do Begin
   WriteLn(EnvStr(I));
   If(Pause)Then Begin
    Inc(P);
    If P=Hi(WindMax)Then Begin
     Write('Presse une touche pour continuer...');
     ReadKey;
     WriteLn;
     P:=0;
    End;
   End;
  End;
 End;
END.
