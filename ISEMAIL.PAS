{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/gladir)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program ISEMAIL;

Function IsValidEmail(Email:String):Boolean;
Var
 I,ArobasFound,AfterArobas:Integer;
Begin
 If(Email='')or(Length(Email)=0)Then Begin
  IsValidEmail:=False;
  Exit;
 End;
 For I:=1 To Length(Email) do Begin
  Case Email[I]of
   #9,#10,#13,' ','(',')',':',',',
   '/','''','"','~','`','!','#','$','%','^','&','*','+','=','[',
   ']','{','}','|','?','<','>':Begin
    IsValidEmail:=False;
    Exit;
   End;
  End;
 End;
 ArobasFound:=0;
 For I:=2 to Length(Email)do Begin
  If Email[I]='@'Then Begin
   Inc(ArobasFound);
   If ArobasFound=1 Then AfterArobas:=I;
  End;
 End;
 If ArobasFound<>1 Then Begin
  IsValidEmail:=False;
  Exit;
 End;
 Inc(AfterArobas,2);
 While(AfterArobas<Length(Email))and(Email[AfterArobas]<>'.')do Inc(AfterArobas);

 IsValidEmail:=Not((AfterArobas>=Length(Email)-1)or(Email[AfterArobas]<>'.'));
End;

Var
 J:Integer;
 Code:Byte;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('ISEMAIL : Cette commande permet de v‚rifier si le courriel ',
          'est un courriel valide');
  WriteLn;
  WriteLn('Syntaxe : ISEMAIL email');
  WriteLn;
  WriteLn(' email   Ce parametre permet d''indiquer l''adresse de courriel');
 End
  Else
 If ParamCount>0Then Begin
  Code:=0;
  For J:=1 to ParamCount do Begin
   If IsValidEmail(ParamStr(J))Then Begin
    WriteLn('True');
   End
    Else
   Begin
    WriteLn('False');
    Inc(Code);
   End;
  End;
  Halt(Code);
 End;
END.
