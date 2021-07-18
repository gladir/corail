{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program Sleep;

Uses Crt;

Var
 NombreSeconde:LongInt;
 Err:Word;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('SLEEP : Cette commande permet d''attendre le nombre de secondes specifies.');
  WriteLn;
  WriteLn('Syntaxe : SLEEP nombredesecondes');
 End
  Else
 If ParamCount=1Then Begin
  Val(ParamStr(1),NombreSeconde,Err);
  Delay(NombreSeconde*1000);
 End
  Else
 WriteLn('Nombre de parametre invalide !');
END.