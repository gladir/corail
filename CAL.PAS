{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program Cal;

Uses DOS;

Function IsLeapYear(Year:Integer):Boolean;Begin
 IsLeapYear:=((Year AND 3) = 0) AND ((Year MOD 100 <> 0) OR (Year MOD 400 = 0));
End;

Function DateToDayOfWeek(Y,M,D:Integer):Integer;
Var
 T0,T1,T2,Total:Integer;
Begin
 If(M > 12) Or (0 = M) Or (0 = D)Then Begin
  DateToDayOfWeek:=0;Exit;
 End;
 If Y < 0 Then Inc(Y);
 T0 := Trunc(0.6 + 1 / M);
 T1 := M + 12 * T0;
 T2 := Y - T0;
 Total := Trunc(13 * (T1 + 1) / 5) + (5 * T2 div 4) - (T2 div 100) + (T2 div 400) + D - 1;
 DateToDayOfWeek := Total - 7 * (Total div 7);
End;

Procedure PutCalendar(Yr,Mh,Dy:Integer);
Const
 Days:Array[1..12] of Integer=(31,28,31,30,31,30,31,31,30,31,30,31);
Var
 I,D:Integer;
Begin
 If IsLeapYear(Yr)Then Days[2] := 29;
 D := DateToDayOfWeek(Yr, Mh, 1);
 WriteLn('Diman Lundi Mardi Mercr Jeudi Vendr Samed');
 Write(' ':6 * D);
 For I := 1 To Days[Mh]do Begin
  If I < 10 Then Write(' ');
  Write(I,' ':4);
  If(0 = (D + I) Mod 7)Then WriteLn;
 End;
 WriteLn;
 WriteLn;
End;

Function MonthName(Mh:Integer):String;Begin
 Case Mh of
   1:MonthName:='Janvier';
   2:MonthName:='F‚vrier';
   3:MonthName:='Mars';
   4:MonthName:='Avril';
   5:MonthName:='Mai';
   6:MonthName:='Juin';
   7:MonthName:='Juillet';
   8:MonthName:='Ao–t';
   9:MonthName:='Septembre';
   10:MonthName:='Octobre';
   11:MonthName:='Novembre';
   12:MonthName:='D‚cembre';
   Else MonthName:='';
 End;
End;

Var
 CurrYear,CurrMonth,CurrDay,DayOfWeek,Err,I:Word;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CAL : Cette commande permet d''afficher un calendrier.');
  WriteLn;
  WriteLn('Syntaxe : CAL [/h] [/y<aaaa> | <[aaaa-]mm>]');
 End
  Else
 If ParamCount=0Then Begin
  GetDate(CurrYear,CurrMonth,CurrDay,DayOfWeek);
  WriteLn(MonthName(CurrMonth),' ',CurrYear);
  WriteLn;
  PutCalendar(CurrYear,CurrMonth,CurrDay);
 End
  Else
 If(Copy(ParamStr(1),1,2)='/y')or(Copy(ParamStr(1),1,2)='/Y')Then Begin
  Val(Copy(ParamStr(1),3,255),CurrYear,Err);
  For I:=1 to 12 do Begin
   WriteLn(MonthName(I),' ',CurrYear);
   WriteLn;
   PutCalendar(CurrYear,I,1);
  End;
 End
  Else
 Begin
  If Length(ParamStr(1))<=2Then Begin
   GetDate(CurrYear,CurrMonth,CurrDay,DayOfWeek);
   Val(ParamStr(1),CurrMonth,Err);
  End
   Else
  Begin
   Val(Copy(ParamStr(1),1,4),CurrYear,Err);
   Val(Copy(ParamStr(1),6,2),CurrMonth,Err);
  End;
  WriteLn(MonthName(CurrMonth),' ',CurrYear);
  WriteLn;
  PutCalendar(CurrYear,CurrMonth,1);
 End;
END.
