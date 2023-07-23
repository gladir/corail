{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal 3.2, Turbo Pascal 7)
}

Program VDIAG;

Uses Crt,DOS;

Var
 Terminated:Boolean;

Procedure TestColors;
Var
 I,J:Byte;
Begin
  { Page 1 }
 TextMode(CO40);
 ClrScr;
 GotoXY(1,2);
 WriteLn('ATTRIBUTS D''AFFICHAGE');
 WriteLn;
 WriteLn;
 TextColor(7);
 WriteLn('CETTE LIGNE EST UNE INTENSITE NORMAL');
 TextColor(15);
 WriteLn('CETTE LIGNE EST EN HAUTE INTENSITE');
 TextBackground(7);
 TextColor(0);
 Write('CETTE LIGNE EST INVERSION VIDEO');
 TextBackground(0);
 WriteLn;
 WriteLn;
 WriteLn;
 TextColor(Red);
 Write(#219#219#219#219#219);
 Write(#219#219#219#219#219);
 TextColor(LightRed);
 Write(#219#219#219#219#219);
 TextColor(7);
 WriteLn(' rouge');
 WriteLn;
 TextColor(Green);
 Write(#219#219#219#219#219);
 Write(#219#219#219#219#219);
 TextColor(LightGreen);
 Write(#219#219#219#219#219);
 TextColor(7);
 WriteLn(' vert');
 WriteLn;
 TextColor(Blue);
 Write(#219#219#219#219#219);
 Write(#219#219#219#219#219);
 TextColor(LightBlue);
 Write(#219#219#219#219#219);
 TextColor(7);
 WriteLn(' bleu');
 WriteLn;
 TextColor(DarkGray);
 Write(#219#219#219#219#219);
 TextColor(LightGray);
 Write(#219#219#219#219#219);
 TextColor(White);
 Write(#219#219#219#219#219);
 TextColor(7);
 WriteLn(' gris');
 WriteLn;
 GotoXY(1,25);
 Write('Presse une touche pour continuer...');
 ReadKey;
  { Page 2 }
 TextMode(CO40);
 ClrScr;
 GotoXY(1,2);
 WriteLn('ATTRIBUTS D''AFFICHAGE');
 WriteLn;
 WriteLn;
 TextColor(7);
 WriteLn('CETTE LIGNE EST UNE INTENSITE NORMAL');
 TextColor(15);
 WriteLn('CETTE LIGNE EST EN HAUTE INTENSITE');
 TextBackground(7);
 TextColor(0);
 Write('CETTE LIGNE EST INVERSION VIDEO');
 TextBackground(0);
 WriteLn;
 WriteLn;
 TextColor(LightGray+BLINK);
 WriteLn('CETTE LIGNE EST CLIGNOTANTE');
 WriteLn;
 TextBackground(Blue);
 TextColor(LightBlue);
 Write(#220#220#220#220#220);
 TextBackground(0);
 TextColor(7);
 WriteLn(' BLEU');
 WriteLn;
 TextBackground(Green);
 TextColor(LightGreen);
 Write(#220#220#220#220#220);
 TextBackground(0);
 TextColor(7);
 WriteLn(' VERT');
 WriteLn;
 TextBackground(Cyan);
 TextColor(LightCyan);
 Write(#220#220#220#220#220);
 TextBackground(0);
 TextColor(7);
 WriteLn(' CYAN');
 WriteLn;
 TextBackground(Red);
 TextColor(LightRed);
 Write(#220#220#220#220#220);
 TextBackground(0);
 TextColor(7);
 WriteLn(' ROUGE');
 WriteLn;
 TextBackground(Magenta);
 TextColor(LightMagenta);
 Write(#220#220#220#220#220);
 TextBackground(0);
 TextColor(7);
 WriteLn(' MAGENTA');
 WriteLn;
 TextBackground(Brown);
 TextColor(Yellow);
 Write(#220#220#220#220#220);
 TextBackground(0);
 TextColor(7);
 WriteLn(' BRUN');
 WriteLn;
 TextBackground(7);
 TextColor(White);
 Write(#220#220#220#220#220);
 TextBackground(0);
 TextColor(7);
 WriteLn(' BLANC');
 WriteLn;
 GotoXY(1,25);
 Write('Presse une touche pour continuer...');
 ReadKey;
  { Page 3 }
 TextMode(CO80);
 ClrScr;
 GotoXY(1,2);
 WriteLn('ENSEMBLE DE CARACTERES');
 WriteLn;
 For J:=0 to 7 do Begin
  Write('  ');
  For I:=0 to 31 do Begin
   Write(Chr(J*32+I)+' ');
  End;
  WriteLn;
  WriteLn;
 End;
 TextColor(White);
 TextBackground(7);
 For I:=1 to 40 do Begin
  Write(#219' ');
 End;
 TextBackground(0);
 TextColor(7);
 GotoXY(1,25);
 Write('Presse une touche pour continuer...');
 ReadKey;
  { Page 4 }
 TextMode(CO80);
 ClrScr;
 GotoXY(1,2);
 WriteLn('AFFICHAGE 80X25');
 TextBackground(7);
 TextColor(0);
 For J:=0 to 21 do Begin
  For I:=0 to 79 do Write(Chr(32+I+J))
 End;
 TextBackground(0);
 TextColor(7);
 GotoXY(1,25);
 Write('Presse une touche pour continuer...');
 ReadKey;
  { Page 5 }
 TextMode(CO40);
 ClrScr;
 GotoXY(1,2);
 WriteLn('AFFICHAGE 40X25');
 TextBackground(7);
 TextColor(0);
 For J:=0 to 21 do Begin
  For I:=0 to 39 do Write(Chr(32+I+J));
  {$IFDEF FPC}WriteLn;{$ENDIF}
 End;
 TextBackground(0);
 TextColor(7);
 GotoXY(1,25);
 Write('Presse une touche pour continuer...');
 ReadKey;
End;

Function MainMenu:Char;Begin
 TextBackground(Black);
 TextColor(7);
 ClrScr;
 GotoXY(30,4);
 Write('R‚vision 2.1 - 09/01/89');
 GotoXY(32,7);
 Write('C - Ex‚cute les tests de couleurs');
 GotoXY(32,10);
 Write('P - Ex‚cute les tests d''imprimante');
 GotoXY(32,13);
 Write('X - Sortie vers DOS');
 GotoXY(34,16);
 Write('Entrez votre choix: ');
 MainMenu:=ReadKey;
End;


BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('VDIAG : Cette commande permet de lancer le test de diagnostic vid‚o.');
  WriteLn;
  WriteLn('Syntaxe : VDIAG [/?]');
 End
  Else
 Begin
  Terminated:=False;
  Repeat
   Case MainMenu of
    'C','c':TestColors;
    'P','p':Begin
    End;
    #27,'X','x':Terminated:=True;
   End;
  Until Terminated;
  ClrScr;
 End;
END.