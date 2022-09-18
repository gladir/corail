{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program DBASE;

Uses Strings,Crt,DOS;

Const
 MainMenu:Array[0..7]of String[15]=(
  'Ajustement','CrÇer','Mise Ö jour','Position','Demande','Organise','Modifie','Outils'
 );

 MainMenuEnglish:Array[0..7]of String[15]=(
  'Set Up','Create','Update','Position','Retrieve','Organize','Modify','Tools'
 );

 SubMenuSetUp:Array[0..8]of String[30]=(
  'Fichier de base de donnÇes','','Format de l''Çcran','Requàte','',
  'Catalogue','Vue','','Sortir de dBASE'
 );

 SubMenuSetUpEnglish:Array[0..8]of String[20]=(
  'Database file','','Format for Screen','Query','','Catalog',
  'View','','Quit dBASE'
 );

 SubMenuCreate:Array[0..5]of String[30]=(
  'Fichier de base de donnÇes','Format','Vue','Requàte','Rapport','êtiquette'
 );

 SubMenuCreateEnglish:Array[0..5]of String[20]=(
   'Database file','Format','View','Query','Report','Label'
 );

 SubMenuUpdate:Array[0..10]of String[20]=(
  'Ajoute','','Edite','Affiche','','Navigue','Remplace','','Efface','Rappel','Compacte'
 );

 SubMenuUpdateEnglish:Array[0..10]of String[20]=(
  'Append','','Edit','Display','','Browse','Replace','','Delete','Recall','Pack'
 );

 SubMenuPosition:Array[0..6]of String[25]=(
  'Positionne','','Emplacement','Continue','','Saut','Aller Ö l''enregistrement'
 );

 SubMenuPositionEnglish:Array[0..6]of String[20]=(
  'Seek','','Locate','Continue','','Skip','Goto Record'
 );

 SubMenuRetrieve:Array[0..7]of String[20]=(
  'Liste','Affiche','Rapport','êtiquette','','Somme','Moyenne','Compte'
 );

 SubMenuRetrieveEnglish:Array[0..7]of String[20]=(
  'List','Display','Report','Label','','Sum','Average','Count'
 );

 SubMenuOrganize:Array[0..3]of String[20]=(
  'Index','Tri','','Copie'
 );

 SubMenuOrganizeEnglish:Array[0..3]of String[20]=(
  'Index','Sort','','Copy'
 );

 SubMenuModify:Array[0..5]of String[30]=(
  'Fichier de base de donnÇes','Format','Vue','Requàte','Rapport',
  'êtiquette'
 );

 SubMenuModifyEnglish:Array[0..5]of String[20]=(
  'Database file','Format','View','Query','Report','Label'
 );

 SubMenuTools:Array[0..8]of String[25]=(
  'Fixe l''unitÇ de disque','Copie le fichier','RÇpertoire',
  'Renomme','Efface','Liste la structure','','Importe','Exporte'
 );

 SubMenuToolsEnglish:Array[0..8]of String[20]=(
  'Set drive','Copy file','Directory','Rename','Erase',
  'List structure','','Import','Export'
 );

 YMenuMax:Array[1..8]of Byte=(
  High(SubMenuSetup),High(SubMenuCreate),High(SubMenuUpdate),
  High(SubMenuPosition),High(SubMenuRetrieve),High(SubMenuOrganize),
  High(SubMenuModify),High(SubMenuTools)
 );

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 ShowASCII128,OnMenu,DoubleFrame:Boolean;
 YMenu,XMenu:Integer;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

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

Function GetCurrentDisk:Char;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 GetCurrentDisk:=CurrentDir[1];
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
 TextColor(0);
 TextBackground(7);
End;

Procedure SetColorUnSelect;Begin
 TextColor(7);
 TextBackground(0);
End;

Procedure ShowMenu;
Var
 I:Byte;
Begin
 Box(1,1,80,1,$7);
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

Procedure SubMenuItem(Y:Integer;Disable:Boolean);Begin
 If(Disable)Then SetColorUnSelect Else
 If Y=YMenu Then SetColorSelect
            Else SetColorUnSelect;
 Case XMenu of
  1:Begin
   GotoXY(2,3+Y);
   If SubMenuSetup[Y]=''Then Write(DuplicateString('-',27+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuSetupEnglish[Y],27));
    Else Write(' ',PadRight(SubMenuSetup[Y],27));
   End;
  End;
  2:Begin
   Case Language of
    _English:GotoXY(10,3+Y);
    Else GotoXY(14,3+Y);
   End;
   If SubMenuCreate[Y]=''Then Write(DuplicateString('-',27+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuCreateEnglish[Y],27));
    Else Write(' ',PadRight(SubMenuCreate[Y],27));
   End;
  End;
  3:Begin
   Case Language of
    _English:GotoXY(18,3+Y);
    Else GotoXY(21,3+Y);
   End;
   If SubMenuUpdate[Y]=''Then Write(DuplicateString('-',20+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuUpdateEnglish[Y],20));
    Else Write(' ',PadRight(SubMenuUpdate[Y],20));
   End;
  End;
  4:Begin
   Case Language of
    _English:GotoXY(26,3+Y);
    Else GotoXY(34,3+Y);
   End;
   If SubMenuPosition[Y]=''Then Write(DuplicateString('-',25+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuPositionEnglish[Y],25));
    Else Write(' ',PadRight(SubMenuPosition[Y],25));
   End;
  End;
  5:Begin
   Case Language of
    _English:GotoXY(36,3+Y);
    Else GotoXY(44,3+Y);
   End;
   If SubMenuRetrieve[Y]=''Then Write(DuplicateString('-',15+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuRetrieveEnglish[Y],15));
    Else Write(' ',PadRight(SubMenuRetrieve[Y],15));
   End;
  End;
  6:Begin
   Case Language of
    _English:GotoXY(46,3+Y);
    Else GotoXY(53,3+Y);
   End;
   If SubMenuOrganize[Y]=''Then Write(DuplicateString('-',15+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuOrganizeEnglish[Y],15));
    Else Write(' ',PadRight(SubMenuOrganize[Y],15));
   End;
  End;
  7:Begin
   GotoXY(52,3+Y);
   If SubMenuModify[Y]=''Then Write(DuplicateString('-',27+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuModifyEnglish[Y],27));
    Else Write(' ',PadRight(SubMenuModify[Y],27));
   End;
  End;
  8:Begin
   GotoXY(56,3+Y);
   If SubMenuTools[Y]=''Then Write(DuplicateString('-',23+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuToolsEnglish[Y],23));
    Else Write(' ',PadRight(SubMenuTools[Y],23));
   End;
  End;
 End;
End;

Procedure ShowSubMenu;
Var
 I:Integer;
Begin
 Case XMenu of
  1:Begin
   FrameEmpty(1,2,30,4+High(SubMenuSetup),$07);
   For I:=Low(SubMenuSetup)to High(SubMenuSetup)do Begin
    SubMenuItem(I,False);
   End;
  End;
  2:Begin
   Case Language of
    _English: FrameEmpty(9,2,38,4+High(SubMenuCreate),$07);
    Else FrameEmpty(13,2,42,4+High(SubMenuCreate),$07);
   End;
   For I:=Low(SubMenuCreate)to High(SubMenuCreate)do Begin
    SubMenuItem(I,False);
   End;
  End;
  3:Begin
   Case Language of
    _English:FrameEmpty(17,2,39,4+High(SubMenuUpdate),$07);
    Else FrameEmpty(20,2,42,4+High(SubMenuUpdate),$07);
   End;
   For I:=Low(SubMenuUpdate)to High(SubMenuUpdate)do Begin
    SubMenuItem(I,False);
   End;
  End;
  4:Begin
   Case Language of
    _English:FrameEmpty(25,2,52,4+High(SubMenuPosition),$07);
    Else FrameEmpty(33,2,60,4+High(SubMenuPosition),$07);
   End;
   For I:=Low(SubMenuPosition)to High(SubMenuPosition)do Begin
    SubMenuItem(I,False);
   End;
  End;
  5:Begin
   Case Language of
    _English:FrameEmpty(35,2,52,4+High(SubMenuRetrieve),$07);
    Else FrameEmpty(43,2,60,4+High(SubMenuRetrieve),$07);
   End;
   For I:=Low(SubMenuRetrieve)to High(SubMenuRetrieve)do Begin
    SubMenuItem(I,False);
   End;
  End;
  6:Begin
   Case Language of
    _English:FrameEmpty(45,2,62,4+High(SubMenuOrganize),$07);
    Else FrameEmpty(52,2,69,4+High(SubMenuOrganize),$07);
   End;
   For I:=Low(SubMenuOrganize)to High(SubMenuOrganize)do Begin
    SubMenuItem(I,False);
   End;
  End;
  7:Begin
   FrameEmpty(51,2,80,4+High(SubMenuModify),$07);
   For I:=Low(SubMenuModify)to High(SubMenuModify)do Begin
    SubMenuItem(I,False);
   End;
  End;
  8:Begin
   FrameEmpty(55,2,80,4+High(SubMenuTools),$07);
   For I:=Low(SubMenuTools)to High(SubMenuTools)do Begin
    SubMenuItem(I,False);
   End;
  End;
 End;
End;

Procedure HideSubMenu;Begin
 Box(1,2,80,15,$7);
End;

Procedure ShowBottomBar;Begin
 GotoXY(1,23);
 TextBackground(7);
 TextColor(0);
 ClrEol;
 If(OnMenu)Then Write(PadRight('ASSIST',15))
           Else Write(PadRight('Command Line',15));
 Write(#186,'<',GetCurrentDisk,':>',#186);
 GotoXY(1,24);
 TextBackground(0);
 TextColor(15);
 ClrEol;
 If(OnMenu)Then Write('Move selection bar - ',#24,#25,'. Select - ',
                      #17,#196,#217,'.  Leave menu - ',#27,#26,
                      '. Help - F1. Exit - Esc.');
 GotoXY(1,25);
 TextBackground(0);
 TextColor(7);
 ClrEol;
 If Not(OnMenu)Then Write(' ':30,'Enter a dBASE command.')
End;

Procedure NotImplemented;Begin
 Box(5,11,75,13,$60);
 FrameEmpty(5,11,75,13,$60);
 GotoXY(20,12);
 Write('Cette fonctionnalite n''est pas implemented');
 ReadKey;
 Box(5,11,75,13,$07);
End;

Procedure Init;Begin
 TextBackground(0);
 TextColor(7);
 ClrScr;
 ShowMenu;
 ShowBottomBar;
End;

Procedure Run;
Var
 K:Char;
 Terminated:Boolean;
Begin
 Terminated:=False;
 If(OnMenu)Then ShowSubMenu;
 Repeat
  K:=ReadKey;
  If(OnMenu)Then Case K of
   #0:Case ReadKey of
     #72:Begin { Up }
      SubMenuItem(YMenu,True);
      If YMenu>0Then Dec(YMenu)
                Else YMenu:=YMenuMax[XMenu];
      Case XMenu of
       1:If YMenu in[1,4,7]Then Dec(YMenu);
       3:If YMenu in[1,4,7]Then Dec(YMenu);
       4:If YMenu in[1,4]Then Dec(YMenu);
       5:If YMenu in[4]Then Dec(YMenu);
       6:If YMenu in[2]Then Dec(YMenu);
       8:If YMenu in[6]Then Dec(YMenu);
      End;
      SubMenuItem(YMenu,False);
     End;
     #75:Begin { Gauche }
     HideSubMenu;
     If XMenu>1 Then Dec(XMenu)
                Else XMenu:=High(MainMenu)+1;
     YMenu:=0;
     ShowMenu;
     ShowSubMenu;
    End;
    #77:Begin { Droite }
     HideSubMenu;
     If XMenu<=High(MainMenu)Then Inc(XMenu)
                             Else XMenu:=1;
     YMenu:=0;
     ShowMenu;
     ShowSubMenu;
    End;
    #80:Begin { Down }
     SubMenuItem(YMenu,True);
     If YMenu<YMenuMax[XMenu]Then Inc(YMenu)
                             Else YMenu:=0;
     Case XMenu of
      1:If YMenu in[1,4,7]Then Inc(YMenu);
      3:If YMenu in[1,4,7]Then Inc(YMenu);
      4:If YMenu in[1,4]Then Inc(YMenu);
      5:If YMenu in[4]Then Inc(YMenu);
      6:If YMenu in[2]Then Inc(YMenu);
      8:If YMenu in[6]Then Inc(YMenu);
     End;
     SubMenuItem(YMenu,False);
    End;
   End;
   #13:Begin
    OnMenu:=False;
    ShowMenu;
    HideSubMenu;
    Case XMenu of
     1:Case YMenu of
      8:Terminated:=True;
      Else NotImplemented;
     End;
     Else NotImplemented;
    End;
   End;
   #27:Begin
    OnMenu:=False;
    ShowMenu;
    HideSubMenu;
   End;
  End
   Else
  Case K of
   #0:Case ReadKey of
    #60:Begin { F2 }
     XMenu:=1;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
   End;
   #27:Terminated:=True;
  End;
 Until Terminated;
End;

Procedure Done;Begin
 TextColor(7);
 TextBackground(Black);
 ClrScr;
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
  WriteLn('DBASE : Cette commande permet de lancer dBASE.');
  WriteLn;
  WriteLn('Syntaxe : DBASE');
 End
  Else
 Begin
  OnMenu:=True;
  YMenu:=0;XMenu:=1;
  DoubleFrame:=True;
  Init;
  Run;
  Done;
 End;
END.