{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program BE;

Uses Crt,DOS;

Var
 Year,Month,Day,DOW:Word;
 Color,NumTick:Integer;
 Err:Word;

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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('BE : Cette commande permet d''executer une commande etendue');
  WriteLn;
  WriteLn('Syntaxe : BE [/?]');
  WriteLn('          BE BEEP');
  WriteLn('          BE CLS [couleur]');
  WriteLn('          BE DELAY tics');
  WriteLn('          BE MONTHDAY');
  WriteLn('          BE WEEKDAY');
  WriteLn;
  WriteLn('  BEEP      Ce parametre permet d''emettre un signal sonore');
  WriteLn('  CLS       Ce parametre permet d''effacer l''ecran');
  WriteLn('  couleur   Ce parametre permet d''indiquer la couleur a appliquer');
  WriteLn('  DELAY     Ce parametre permet d''indiquer un delai');
  WriteLn('  tics      Ce parametre permet d''indiquer des tic de 1/18 de secondes');
  WriteLn('  MONTHDAY  Ce parametre permet de retourner le jour du mois dans ERRORLEVEL.');
  WriteLn('  WEEKDAY  Ce parametre permet de retourner le jour de la semaine dans ERRORLEVEL.');
 End
  Else
 Begin
  If StrToUpper(ParamStr(1))='BEEP'Then Begin
   Sound(1550);
   Delay(182);
   NoSound;
  End
   Else
  If StrToUpper(ParamStr(1))='CLS'Then Begin
   If ParamStr(2)<>''Then Begin
    Val(ParamStr(2),Color,Err);
    TextBackground(Color and 7);
   End;
   ClrScr;
  End
   Else
  If StrToUpper(ParamStr(1))='DELAY'Then Begin
   If ParamStr(2)=''Then WriteLn('Delai de 1/18 de secondes attendue')
    Else
   Begin
    Val(ParamStr(2),NumTick,Err);
    If Err>0Then WriteLn('Nombre invalide')
     Else
    Delay(Trunc((NumTick/18.2)*1000));
   End;
  End
   Else
  If StrToUpper(ParamStr(1))='MONTHDAY'Then Begin
   GetDate(Year,Month,Day,DOW);
   Halt(Day);
  End
   Else
  If StrToUpper(ParamStr(1))='WEEKDAY'Then Begin
   GetDate(Year,Month,Day,DOW);
   Halt(DOW);
  End
   Else
  WriteLn('Commande etendue non reconnu');
 End;
END.