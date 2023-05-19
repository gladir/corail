{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program PXD;

Uses DOS;

BEGIN
 If(ParamStr(1)='/?')Then Begin
  WriteLn('PXD : Cette commande permet d''afficher le repertoire d''execution.');
  WriteLn;
  WriteLn('Syntaxe : PXD');
 End
  Else
 WriteLn(GetEnv('PATH'));
END.
