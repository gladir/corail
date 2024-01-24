{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program YES;

Var
 S:String;
 I:Integer;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('YES : Cette commande permet d''effectuer des r‚p‚titions de r‚ponses ',
                 'affirmatives.');
  WriteLn;
  WriteLn('Syntaxe : YES [string]');
  WriteLn;
  WriteLn(' string  Permet d''indiquer la r‚ponse … retourner continuellement.');
  WriteLn;
 End
  Else
 Begin
  S:='';
  If ParamCount>0 Then Begin
   For I:=1 to ParamCount do Begin
    If S<>''Then S:=S+' ';
    S:=S+ParamStr(I);
   End;
  End;
  If S=''Then S:='y';
  While True do Begin
   {$I-}WriteLn(S);{$I+}
   If IOResult<>0 Then Break;
  End;
 End;
END.