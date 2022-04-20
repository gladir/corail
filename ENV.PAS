{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program ENV;

Uses Crt,DOS;

Var
 Pause:Boolean;
 I,P:Integer;
 FirstParam:String;

BEGIN
 Pause:=False;
 FirstParam:=ParamStr(1);
 If FirstParam='/?'Then Begin
  WriteLn('ENV   Cette commande permet de fixer ou demander le contenu des ',
          'variables d''environnement du systeme d''exploitation');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('ENV [/?] [-p]');
  WriteLn;
  WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' -p   Ce parametre permet d''effectuer une pause entre chaque page');
  Exit;
 End
  Else
 If(FirstParam='-p')Then Pause:=True;
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
END.