{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7)
}

Program ROMDATE;

Uses Crt,DOS;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 I:Word;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _English:Begin
    WriteLn('ROMDATE : This command return the ROM date.');
    WriteLn;
    WriteLn('ROMDATE [/?]');
    WriteLn;
    WriteLn('/?          = Help for this command');
   End;
   Else Begin
    WriteLn('ROMDATE : Cette commande permet de retourner la date de la ROM.');
    WriteLn;
    WriteLn('Syntaxe : ROMDATE [/?]');
    WriteLn;
    WriteLn(' /?          Ce paramätre permet de founir de l''aide sur cette commande.');
   End;
  End;
 End
  Else
 Begin
  For I:=$FFF5 to $FFFC do Begin
   Write(Chr(Mem[$F000:I]));
  End;
  WriteLn;
 End;
END.