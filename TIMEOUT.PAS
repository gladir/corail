{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program TimeOut;

Uses Crt;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Var
 P:Byte;
 Y,I,Value:Integer;
 Err:Word;
 CurrParam:String;
 Mode:(_None,_T);
 NoBreak:Boolean;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 P:=0;
 NoBreak:=False;
 CurrParam:=ParamStr(1);
 If CurrParam='/?'Then Begin
  WriteLn('TIMEOUT   Cette commande permet d''attendre le nombre de ',
                    'secondes specifie');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('TIMEOUT [/?]');
  WriteLn('TIMEOUT /T seconds [/NOBREAK]');
  WriteLn;
  WriteLn(' /?       Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' seconds  Ce parametre permet d''indiquer le nombre de seconde d''attente');
  WriteLn(' /NOBREAK Ce parametre permet d''indiquer qu''on ne peut l''interrompre');
 End
  Else
 Begin
  Value:=-1;
  Mode:=_None;
  Repeat
   Inc(P);
   CurrParam:=ParamStr(P);
   If CurrParam=''Then Begin
    If P=1Then Begin
     WriteLn('Vous devez entrez des paramŠtres !');
     Exit;
    End;
   End
    Else
   If Mode=_T Then Begin
    Val(CurrParam,Value,Err);
    If Err>0 Then Begin
     WriteLn('Valeur invalide !');
     Exit;
    End;
    Mode:=_None;
   End
    Else
   If StrToUpper(CurrParam)='/T'Then Mode:=_T Else
   If StrToUpper(CurrParam)='/NOBREAK'Then NoBreak:=True;
   If P>9Then Break;
  Until CurrParam='';
  If Value>0 Then Begin
   Y:=WhereY;
   WriteLn;
   For I:=Value downto 1 do Begin
    If Not(NoBreak)Then Begin
     If(Keypressed)Then Break;
    End;
    GotoXY(1,Y);
    If(NoBreak)Then Begin
     Write('Attendre ',I,' secondes, appuyez sur CTRL+C pour quitter...');
    End
     Else
    Begin
     Write('Attendre ',I,' secondes, appuyez sur une touche pour continuer...');
    End;
    Delay(1000);
   End;
   WriteLn;
  End;
 End;
END.