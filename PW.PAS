{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program PW;

Uses Strings,Crt,DOS;

Const
 MainMenu:Array[0..5]of String[15]=(
  'F1-Aide','F2-Fichier/Impr','F3-Edition',
  'F4-Format','F5-Dictionaire','F6-Adresses'
 );

 MainMenuEnglish:Array[0..5]of String[15]=(
  'F1-Help','F2-File/Print','F3-Edit',
  'F4-Format','F5-Dictionary','F6-Addresses'
 );

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 ShowASCII128,OnMenu,DoubleFrame:Boolean;
 YMenu,XMenu:Integer;

Function DuplicateString(C:Char;Num:Integer):String;
Var
 I:Byte;
 S:String;
Begin
 S:='';
 For I:=1 to Num do S:=S+C;
 DuplicateString:=S;
End;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Procedure Box(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Window(X1,Y1,X2,Y2);
 TextBackground((Couleur shr 4)and 15);
 {$IFDEF FPC}
  If Couleur and $80=$80 Then Begin
   TextColor((Couleur and 15)+BLINK);
  End
   Else
  TextColor(Couleur and 15);
 {$ELSE}
  TextColor(Couleur and 15);
 {$ENDIF}
 ClrScr;
 Window(1,1,80,25);
End;

Procedure FrameEmpty(X1,Y1,X2,Y2,Couleur:Byte);
Var
 I:Byte;
 ChrHori,ChrVert:Char;
 Chr218,Chr192,Chr191,Chr217:Char;
Begin
 TextBackground((Couleur shr 4)and 15);
 TextColor(Couleur and 15);
 If(ShowASCII128)Then Begin
  ChrHori:='-';
  ChrVert:='|';
  Chr218:='+';
  Chr192:='+';
  Chr191:='+';
  Chr217:='+';
 End
  Else
 Begin
  If(DoubleFrame)Then Begin
   ChrHori:=#205;
   ChrVert:=#186;
   Chr218:=#201;
   Chr192:=#200;
   Chr191:=#187;
   Chr217:=#188;
  End
   Else
  Begin
   ChrHori:=#$C4;
   ChrVert:=#$B3;
   Chr218:=#218;
   Chr192:=#192;
   Chr191:=#191;
   Chr217:=#217;
  End;
 End;
 For I:=Y1+1 to Y2-1 do Begin
  GotoXY(X1,I);
  Write(ChrVert);
  GotoXY(X2,I);
  Write(ChrVert);
 End;
 GotoXY(X1+1,Y1);
 Write(DuplicateString(ChrHori,X2-X1-1));
 GotoXY(X1+1,Y2);
 Write(DuplicateString(ChrHori,X2-X1-1));
 GotoXY(X1,Y1);
 Write(Chr218);
 GotoXY(X1,Y2);
 Write(Chr192);
 GotoXY(X2,Y1);
 Write(Chr191);
 GotoxY(X2,Y2);
 Write(Chr217);
End;

Procedure SetColorSelect;Begin
 TextColor(Red);
 TextBackground(7);
End;

Procedure SetColorUnSelect;Begin
 TextColor(7);
 TextBackground(Red);
End;

Procedure ShowMenu;
Var
 I:Byte;
Begin
 Box(1,1,80,1,$47);
 GotoXY(1,1);
 For I:=0 to High(MainMenu) do Begin
  If(OnMenu)Then Begin
   If I+1=XMenu Then SetColorSelect
                Else SetColorUnSelect;
  End;
  Case Language of
   _English:Write(' ',MainMenuEnglish[I],' ');
   Else Write(' ',MainMenu[I],' ');
  End;
 End;
End;

Procedure WritePos;Begin
 TextColor(7);
 TextBackground(0);
 GotoXY(64,24);
 Write('Ligne 1 de Pg 1');
End;

Procedure Init;
Var
 I:Byte;
Begin
 TextColor(7);
 TextBackground(Black);
 ClrScr;
 ShowMenu;
 FrameEmpty(1,2,80,23,$07);
 GotoXY(2,23);
 For I:=1 to 8 do Begin
  Write(DuplicateString(#193,4),#197);
  If I=8 Then Write(DuplicateString(#193,3))
         Else Write(DuplicateString(#193,4));
  Case I of
   1:Write('[');
   7:Write(']');
   8:;
   Else Write(I);
  End;
 End;
 WritePos;
 TextBackground(Black);
 TextColor(LightRed);
 GotoXY(1,25);
 Case Language of
  _English: Write('Esc-Main Menu');
  Else Write('Esc-Menu principal');
 End;
End;

Procedure Run;
Var
 K:Char;
Begin
 GotoXY(10,7);
 K:=ReadKey;
End;

Procedure Done;Begin
 TextColor(7);
 TextBackground(0);
 ClrScr;
End;

Procedure SetupMenuBase;
Const
 MenuOption:Array[0..6]of PChar=(
  '1. S‚lectionne l''imprimante 1',
  '2. S‚lectionne l''imprimante 2',
  '3. Sp‚cifie les codes de contr“le d''imprimante',
  '4. Change le r‚pertoire de donn‚es',
  '5. Change l''unit‚ de disque de travail',
  '6. Change les couleusr d''‚cran',
  '7. Change la vitesse de mise … jour de l''‚cran'
 );
 MenuOptionEnglish:Array[0..6]of PChar=(
  '1. Select printer 1',
  '2. Select printer 2',
  '3. Specify printer control codes',
  '4. Change data directory',
  '5. Change work drive',
  '6. Change screen colors',
  '7. Change screen update speed'
 );
Var
 P:Integer;
 I,Len:Byte;
 K:Char;

 Procedure SelectItem;Begin
  TextBackground(7);
  TextColor(Red);
  GotoXY(28,13+P);
  Write(#16,' ');
  Case Language of
   _English:Write(StrPas(MenuOptionEnglish[P]));
   Else Write(StrPas(MenuOption[P]));
  End;
 End;

 Procedure UnselectItem;Begin
  TextBackground(7);
  TextColor(Black);
  GotoXY(28,13+P);
  Write(' ':2);
  Case Language of
   _English:Write(StrPas(MenuOptionEnglish[P]));
   Else Write(StrPas(MenuOption[P]));
  End;
 End;

Begin
 If Language=_English Then Len:=35
                      Else Len:=52;
 TextColor(White);
 TextBackground(7);
 GotoXY(27,10);
 Write(DuplicateString(#223,Len));
 Box(26,11,26+Len-1,21,$07);
 Box(27,11,27+Len-1,20,$70);
 TextColor(Red);
 Case Language of
  _English:Begin
   GotoXY(40,11);
   Write('Setup Menu');
  End;
  Else Begin
   GotoXY(45,11);
   Write('Menu d''ajustement');
  End;
 End;
 GotoXY(27,12);
 TextColor(8);
 Write(DuplicateString(#196,Len));
 TextColor(Black);
 For I:=0 to 6 do Begin
  GotoXY(30,13+I);
  Case Language of
   _English:Write(StrPas(MenuOptionEnglish[I]));
   Else Write(StrPas(MenuOption[I]));
  End;
 End;
 TextBackground(Black);
 TextColor(LightRed);
 GotoXY(1,25);
 Case Language of
  _English:Write('Esc-Cancel');
  Else Write('Esc-Annuler');
 End;
 P:=0;
 SelectItem;
 Repeat
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #72:Begin { Up }
     UnselectItem;
     If P=0 Then P:=6
            Else Dec(P);
     SelectItem;
    End;
    #80:Begin { Down }
     UnselectItem;
     P:=(P+1)mod 7;
     SelectItem;
    End;
   End;
   #13:Break;
  End;
 Until K=#27;
End;

Function MainMenuBase:Byte;
Const
 MenuOption:Array[0..2]of PChar=('1. Cr‚er/Editer','2. Ajustement','E. Sortir');
 MenuOptionEnglish:Array[0..2]of PChar=('1. Create/Edit','2. Setup','E. Exit');
Var
 Switch:Boolean;
 P:Integer;
 I,X,Y:Byte;
 K:Char;

 Procedure SelectItem;Begin
  TextBackground(7);
  TextColor(Red);
  GotoXY(30,12+P);
  Write(#16,' ');
  Case Language of
   _English:Write(StrPas(MenuOptionEnglish[P]));
   Else Write(StrPas(MenuOption[P]));
  End;
 End;

 Procedure UnselectItem;Begin
  TextBackground(7);
  TextColor(Black);
  GotoXY(30,12+P);
  Write(' ':2);
  Case Language of
   _English:Write(StrPas(MenuOptionEnglish[P]));
   Else Write(StrPas(MenuOption[P]));
  End;
 End;

Begin
 TextMode(CO80);
 TextColor(Red);
 TextBackground(Black);
 ClrScr;
 For I:=1 to 24 do Begin
  Write(DuplicateString(#178,80));
 End;
 TextColor(8);
 TextBackground(Red);
 X:=4;Y:=4;Switch:=True;
 For I:=1 to 22 do Begin
  GotoXY(X,Y);
  Write(#15);
  Inc(X,14);
  If X>80 Then Begin
   If(Switch)Then X:=12
             Else X:=4;
   Inc(Y,5);
   Switch:=Not Switch;
  End;
 End;
 TextColor(White);
 TextBackground(7);
 GotoXY(25,8);
 Write(DuplicateString(#223,30));
 Box(24,9,53,16,$07);
 Box(25,9,54,15,$70);
 GotoXY(30,9);
 TextColor(Red);
 Write('PFS:Professional Write');
 Case Language of
  _English:Begin
   GotoxY(35,10);
   Write('Main Menu');
  End;
  Else Begin
   GotoxY(33,10);
   Write('Main principal');
  End;
 End;
 GotoXY(25,11);
 TextColor(8);
 Write(DuplicateString(#196,30));
 TextColor(Black);
 For I:=0 to 2 do Begin
  GotoXY(32,12+I);
  Case Language of
   _English:Write(StrPas(MenuOptionEnglish[I]));
   Else Write(StrPas(MenuOption[I]));
  End;
 End;
 TextBackground(Black);
 TextColor(LightRed);
 GotoXY(38,25);
 Write('F1-Aide');
 GotoXY(65,25);
 Write(#17,#196,#217,' S‚lectionne');
 P:=0;
 SelectItem;
 Repeat
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #72:Begin { Up }
     UnselectItem;
     If P=0 Then P:=2
            Else Dec(P);
     SelectItem;
    End;
    #80:Begin { Down }
     UnselectItem;
     P:=(P+1)mod 3;
     SelectItem;
    End;
   End;
   #13:Break;
   #27:P:=2;
  End;
 Until K=#27;
 MainMenuBase:=P;
End;

BEGIN
 ShowASCII128:=False;
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ELSE}
   ShowASCII128:=True;
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
  WriteLn('PW : Cette commande permet de lancer le PFS:Professional Write.');
  WriteLn;
  WriteLn('Syntaxe : PW');
 End
  Else
 Begin
  DoubleFrame:=False;
  OnMenu:=False;
  YMenu:=0;XMenu:=1;
  Repeat
   Case MainMenuBase of
    0:Begin
     Init;
     Run;
    End;
    1:SetupMenuBase;
    2:Break;
   End;
  Until False;
  Done;
 End;
END.