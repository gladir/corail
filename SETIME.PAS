{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program SETIME;

Uses DOS;

Var
 Pos:(PMonth,PDay,PYear,PHour,PMin,PSec);
 Year,Month,Day,DayOfMonth,Hour,Minute,Second,CentSec,Err:Word;
 I:Byte;
 S,T:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('SETIME : Cette commande permet de fixer l''horloge du systeme d''exploitation.');
  WriteLn;
  WriteLn('Syntaxe : SETIME aa/MM/dd hh:mm[:ss]');
 End
  Else
 If ParamStr(1)<>''Then Begin
  T:='';
  Pos:=PYear;
  S:=ParamStr(1);
  For I:=1 to Length(S)do Begin
   If S[I]<>'/'Then T:=T+S[I];
   If S[I]='/'Then Begin
    If Pos=PYear Then Begin
     Val(T,Year,Err);
     Pos:=PMonth;
    End
     Else
    If Pos=PMonth Then Begin
     Val(T,Month,Err);
     Pos:=PDay;
    End
     Else
    Val(T,Day,Err);
    T:='';
   End;
  End;
  If T<>''Then Val(T,Day,Err);
  SetDate(Year,Month,Day);
  S:=ParamStr(2);
  If S<>''Then Begin
   T:='';
   Hour:=0;
   Minute:=0;
   Second:=0;
   Pos:=PHour;
   For I:=1 to Length(S)do Begin
    If S[I]<>':'Then T:=T+S[I];
    If S[I]=':'Then Begin
     If Pos=PHour Then Begin
      Val(T,Hour,Err);
      Pos:=PMin;
     End
      Else
     If Pos=PMin Then Begin
      Val(T,Minute,Err);
      Pos:=PSec;
     End
      Else
     Val(T,Second,Err);
     T:='';
    End;
   End;
   If T<>''Then Begin
    If(Pos=PMin)Then Val(T,Minute,Err)
                Else Val(T,Second,Err);
   End;
   SetTime(Hour,Minute,Second,0);
  End;
 End
  Else
 WriteLn('Heure attendu');
END.