{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program TOD;

Uses Crt,DOS;

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

Var
 Pos:(PMonth,PDay,PYear,PHour,PMin,PSec);
 Year,Month,Day,DayOfMonth,Hour,Minute,Second,CentSec,Err:Word;
 I,Y:Byte;
 S,T:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('TOD : Cette commande permet de demander la date et l''heure de la journee.');
  WriteLn;
  WriteLn('Syntaxe : TOD [/?] [mois/jour/annee heure:minute:seconde]');
  WriteLn;
  WriteLn(' mois     Ce parametre permet d''indiquer le mois');
  WriteLn(' jour     Ce parametre permet d''indiquer le jour du mois');
  WriteLn(' annee    Ce parametre permet d''indiquer l''annee');
  WriteLn(' heure    Ce parametre permet d''indiquer l''heure');
  WriteLn(' minute   Ce parametre permet d''indiquer les minutes');
  WriteLn(' seconde  Ce parametre permet d''indiquer les secondes');
  WriteLn('  P       Ce parametre permet d''afficher l''heure en continue');
 End
  Else
 If(ParamStr(1)='P')or(ParamStr(1)='p')Then Begin
  Y:=WhereY;
  Repeat
   GotoXY(1,Y);
   GetDate(Year,Month,Day,DayOfMonth);
   GetTime(Hour,Minute,Second,CentSec);
   Write(PadZeroLeft(Month,2),'-',PadZeroLeft(Day,2),'-',PadZeroLeft(Year mod 100,2),
         ' ':7,PadZeroLeft(Hour,2),':',PadZeroLeft(Minute,2),':',PadZeroLeft(Second,2));
  Until Keypressed;
  If(ReadKey<>#0)Then;
  WriteLn;
 End
  Else
 If ParamCount>0Then Begin
  T:='';
  Pos:=PMonth;
  S:=ParamStr(1);
  For I:=1 to Length(S)do Begin
   If S[I]<>'/'Then T:=T+S[I];
   If S[I]='/'Then Begin
    If Pos=PMonth Then Begin
     Val(T,Month,Err);
     Pos:=PDay;
    End
     Else
    If Pos=PDay Then Begin
     Val(T,Day,Err);
     Pos:=PYear;
    End
     Else
    Val(T,Year,Err);
    T:='';
   End;
  End;
  If T<>''Then Val(T,Year,Err);
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
 Begin
  GetDate(Year,Month,Day,DayOfMonth);
  GetTime(Hour,Minute,Second,CentSec);
  WriteLn(Month:2,'-',PadZeroLeft(Day,2),'-',PadZeroLeft(Year mod 100,2),
          ' ':6,PadZeroLeft(Hour,2),':',PadZeroLeft(Minute,2),':',
          PadZeroLeft(Second,2));
 End;
END.
