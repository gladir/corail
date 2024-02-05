{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program REALPATH;

Uses DOS;

Var
 I:Integer;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('REALPATH : Cette commande permet de convertir le paramŠtre ',
                     'du nom de chemin en chemin absolu, avec toutes ',
                     'les r‚f‚rences … ".", ".." et les liens ',
                     'symboliques r‚solus.');
  WriteLn;
  WriteLn('Syntaxe : REALPATH chemin');
  WriteLn;
  WriteLn(' chemin    Nom du chemin … r‚soudre');
 End
  Else
 If ParamCount>0 Then Begin
  For I:=1 to ParamCount do Begin
   WriteLn(FExpand(ParamStr(I)));
  End;
 End;
END.