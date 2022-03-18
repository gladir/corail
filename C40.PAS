{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program C40;

Uses Crt;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('C40 : Cette commande permet de passer en ‚cran de texte de 40 colonnes.');
  WriteLn;
  WriteLn('Syntaxe : C40');
 End
  Else
 TextMode(CO40);
END.