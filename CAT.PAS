{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program CAT(Input,Output);

Var
 I:Integer;
 Handle:Text;
 CurrLine:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CAT : Cette commande permet d''afficher le contenu du fichier.');
  WriteLn;
  WriteLn('Syntaxe : CAT [fichier]');
 End
  Else
 If ParamCount>0Then Begin
  For I:=1 to ParamCount do Begin
   Assign(Handle,ParamStr(I));
   {$I-}Reset(Handle);{$I+}
   If IOResult=0Then Begin
    While NOT EOF(Handle)do Begin
     ReadLn(Handle,CurrLine);
     WriteLn(CurrLine);
    End;
    Close(Handle);
   End
    Else
   WriteLn('Impossible de lire ',ParamStr(I));
  End;
 End
  Else
 Begin
  Repeat
   ReadLn(Input,CurrLine);
   WriteLn(CurrLine);
  Until EOF;
 End;
END.
