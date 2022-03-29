{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program _APPEND;

Var
 Source,Dest:Text;
 CurrLine:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('APPEND : Cette commande permet d''ajouter un fichier ASCII … un autre fichier.');
  WriteLn;
  WriteLn('Syntaxe : APPEND fichieraajouter TO fichierdest');
 End
  Else
 If(ParamStr(2)='TO')or(ParamStr(2)='to')Then Begin
  Assign(Source,ParamStr(1));
  Reset(Source);
  Assign(Dest,ParamStr(3));
  Append(Dest);
  While Not EOF(Source)do Begin
   ReadLn(Source,CurrLine);
   WriteLn(Dest,CurrLine);
  End;
  Close(Dest);
  Close(Source);
 End
  Else
 Begin
  WriteLn('Parametre invalide !');
 End;
END.
