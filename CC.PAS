{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CC;

Uses Crt;

Var
 I:Integer;
 PosMode:(pmTxtColor,pmTxtBackground);
 TxtBackground,TxtColor,SwpColor:Byte;

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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CC : Cette commande permet de lancer le Custom Color.');
  WriteLn;
  WriteLn('Syntaxe : CC NORMAL');
  WriteLn('          CC REVERSE');
  WriteLn('          CC [BRIGHT] [couleur] [ON couleur]');
 End
  Else
 Begin
  TxtColor:=LightGray;
  TxtBackground:=Black;
  PosMode:=pmTxtColor;
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='BLACK'Then Begin
    If(PosMode=pmTxtBackground)Then TxtBackground:=Black
                               Else TxtColor:=Black;
   End
    Else
   If(StrToUpper(ParamStr(I))='BOLD')or
     (StrToUpper(ParamStr(I))='BRIGHT')Then TxtColor:=TxtColor or 8 Else
   If StrToUpper(ParamStr(I))='BLUE'Then Begin
    If(PosMode=pmTxtBackground)Then TxtBackground:=Blue
                               Else TxtColor:=Blue;
   End
    Else
   If StrToUpper(ParamStr(I))='BROWN'Then Begin
    If(PosMode=pmTxtBackground)Then TxtBackground:=Brown
                               Else TxtColor:=Brown;
   End
    Else
   If StrToUpper(ParamStr(I))='CYAN'Then Begin
    If(PosMode=pmTxtBackground)Then TxtBackground:=Cyan
                               Else TxtColor:=Cyan;
   End
    Else
   If StrToUpper(ParamStr(I))='GREEN'Then Begin
    If(PosMode=pmTxtBackground)Then TxtBackground:=Green
                               Else TxtColor:=Green;
   End
    Else
   If(StrToUpper(ParamStr(I))='MAGENT')or
     (StrToUpper(ParamStr(I))='MAGENTA')Then Begin
    If(PosMode=pmTxtBackground)Then TxtBackground:=Magenta
                               Else TxtColor:=Magenta;
   End
    Else
   If(StrToUpper(ParamStr(I))='NORM')or
     (StrToUpper(ParamStr(I))='NORMAL')Then Begin
    If(PosMode=pmTxtBackground)Then TxtBackground:=LightGray
                               Else TxtColor:=LightGray;
   End
    Else
   If StrToUpper(ParamStr(I))='ON'Then PosMode:=pmTxtBackground Else
   If StrToUpper(ParamStr(I))='REVERSE'Then Begin
    SwpColor:=TxtColor;
    TxtColor:=TxtBackground;
    TxtBackground:=SwpColor;
   End
    Else
   If StrToUpper(ParamStr(I))='ORANGE'Then Begin
    If(PosMode=pmTxtBackground)Then TxtBackground:=Brown
                               Else TxtColor:=Brown;
   End
    Else
   If StrToUpper(ParamStr(I))='RED'Then Begin
    If(PosMode=pmTxtBackground)Then TxtBackground:=Red
                               Else TxtColor:=Red;
   End
    Else
   If StrToUpper(ParamStr(I))='WHITE'Then Begin
    If(PosMode=pmTxtBackground)Then TxtBackground:=White
                               Else TxtColor:=White;
   End
    Else
   If(StrToUpper(ParamStr(I))='YELLO')or
     (StrToUpper(ParamStr(I))='YELLOW')Then Begin
    If(PosMode=pmTxtBackground)Then TxtBackground:=Yellow
                               Else TxtColor:=Yellow;
   End;
  End;
  TextColor(TxtColor);
  TextBackground(TxtBackground);
  ClrScr;
  WriteLn('Custom Color, Version 0.1, MIT');
 End;
END.