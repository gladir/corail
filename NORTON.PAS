{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program NORTON;

{$M 16384,0,0}

Uses Strings,Crt,DOS;

Const
 MainMenu:Array[0..4]of String[15]=(
  'Menu','Configuration','Conseille','Quitte!','F1=Aide'
 );
 MainMenuEnglish:Array[0..4]of String[15]=(
  'Menu','Configuration','Advise','Quit!','F1=Help'
 );

 SubMenuMenu:Array[0..5]of String[30]=(
  'Tri par Nom',
  'Tri par Sujet',
  '',
  'Ajout l''ÇlÇment de menu...',
  'Edite l''ÇlÇment de menu...',
  'Efface l''ÇlÇment de menu...'
 );

 SubMenuMenuEnglish:Array[0..5]of String[30]=(
  'sort by Name',
  'sort by Topic',
  '',
  'Add menu item...',
  'Edit menu item...',
  'Delete menu item...'
 );

 SubMenuConfiguration:Array[0..10]of String[30]=(
  'VidÇo et souris...',
  '',
  'Norton Cache...',
  'Fichier CONFIG.SYS...',
  'Fichier AUTOEXEC.BAT...',
  '',
  'Noms alternatif...',
  'êtendre les programmes...',
  '',
  'Mots de passe...',
  'Edition de Menu...'
 );

 SubMenuConfigurationEnglish:Array[0..10]of String[30]=(
  'Video and mouse...',
  '',
  'Norton Cache...',
  'CONFIG.SYS file...',
  'AUTOEXEC.BAT file...',
  '',
  'aLternate names...',
  'Expand programs...',
  '',
  'Passwords...',
  'Menu editing...'
 );

 SubMenuAdvise:Array[0..5]of String[40]=(
  'Probläme commun de disque...',
  'Messages d''erreur DOS...',
  'Messages d''erreur CHKDSK...',
  'Messages d''erreur d''Application...',
  '',
  'Recherche...'
 );

 SubMenuAdviseEnglish:Array[0..5]of String[40]=(
  'common disk Problems...',
  'DOS error messages...',
  'CHKDSK error messages...',
  'Application error messages...',
  '',
  'Search...'
 );

 YMenuMax:Array[1..5]of Byte=(
  High(SubMenuMenu),High(SubMenuConfiguration),High(SubMenuAdvise),0,0
 );

 CommandsTitleList:Array[0..11]of String[20]=(
  '^RECUPERATION',
  'DiskEdit',
  '',
  '^SECURITE',
  'Wipeinfo',
  '',
  '^OUTILS',
  'BE (Batch Enhancer)',
  'FA (Attributs)',
  'FS (Taille)',
  'System Info',
  'TS (Recherche texte)'
 );

 CommandsList:Array[0..11]of String[12]=(
  '',
  'DISKEDIT',
  '',
  '',
  'WIPEINFO',
  '',
  '',
  'BE',
  'FA',
  'FS',
  'SYSINFO',
  'TS'
 );

 CommandsPause:Array[0..11]of Boolean=(
  False,
  False,
  False,
  False,
  True,
  False,
  False,
  True,
  True,
  True,
  False,
  True
 );

 CommandsDescr:Array[0..11]of PChar=(
  '',

  '^Editeur disque (Disk Editor)^'+#13+
  'DISKEDIT [disque:]'+#13+
  'DISKEDIT [fichier]'+#13+
  #13+
  'Visualise ou edition du disque ou d''un '#13+'fichier d''image',
  '',
  '',

  '^Wipeinfo^'+#13+
  'WIPEINFO fichier'+#13+
  #13+
  'Effacement irrecuperable de fichier',

  '',
  '',

  '^Batch Enhancer^'+#13+
  'BE commande'+#13+
  #13+
  'Execute des commandes etendues',

  '^Attributs de fichier^'+#13+
  'FA nomdufichier [attribut+/-]'+#13+
  #13+
  'Change les attributs de fichiers',

  '^Taille de fichier^'+#13+
  'FS [/P] [chemin]'+#13+
  #13+
  'Calcul la taille de fichiers',

  '^Information systäme^'+#13+
  'SYSINFO'+#13+
  #13+
  'Demande des informations techniques sur '+#13+'le systäme',

  '^Recherche de texte^'+#13+
  'TS "chaine" [fichier] [/CS]'+#13+
  #13+
  'Recherche de texte dans des fichiers'
 );

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 ShowASCII128,OnMenu:Boolean;
 YMenu,XMenu:Integer;
 CurrPos:Byte;
 I:Integer;
 ParamString:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

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

Procedure Box(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Window(X1,Y1,X2,Y2);
 TextBackground((Couleur shr 4)and 15);
 If Couleur and $80=$80 Then Begin
  TextColor((Couleur and 15)+BLINK);
 End
  Else
 TextColor(Couleur and 15);
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
 If Couleur and $80=$80 Then Begin
  TextColor((Couleur and 15)+BLINK);
 End
  Else
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
  ChrHori:=#$C4;
  ChrVert:=#$B3;
  Chr218:=#218;
  Chr192:=#192;
  Chr191:=#191;
  Chr217:=#217;
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
 TextColor(15);
 TextBackground(0);
End;

Procedure SetColorUnSelect;Begin
 TextColor(0+BLINK);
 TextBackground(15);
End;

Procedure ShowMenu;
Var
 I:Byte;
Begin
 Box(1,1,80,1,$F0);
 GotoXY(4,1);
 For I:=0 to High(MainMenu) do Begin
  If High(MainMenu)=I Then Begin
   SetColorUnSelect;
   Case Language of
    _English: Write(' ':18);
    Else Write(' ':14);
   End;
  End;
  If(OnMenu)Then Begin
   If I+1=XMenu Then SetColorSelect
                Else SetColorUnSelect;
  End;
  Case Language of
   _English:Write(' ',MainMenuEnglish[I],' ');
   Else Write(' ',MainMenu[I],' ');
  End;
  SetColorUnSelect;
  If High(MainMenu)<>I Then Write('   ');
 End;
End;

Procedure SubMenuItem(Y:Integer;Disable:Boolean);Begin
 If(Disable)Then SetColorUnSelect Else
 If Y=YMenu Then SetColorSelect
            Else SetColorUnSelect;
 Case XMenu of
  1:Begin
   GotoXY(5,3+Y);
   If SubMenuMenu[Y]=''Then Write(DuplicateString('-',27+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuMenuEnglish[Y],27));
    Else Write(' ',PadRight(SubMenuMenu[Y],27));
   End;
  End;
  2:Begin
   GotoXY(14,3+Y);
   If SubMenuConfiguration[Y]=''Then Write(DuplicateString('-',27+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuConfigurationEnglish[Y],27));
    Else Write(' ',PadRight(SubMenuConfiguration[Y],27));
   End;
  End;
  3:Begin
   GotoXY(32,3+Y);
   If SubMenuAdvise[Y]=''Then Write(DuplicateString('-',37+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuAdviseEnglish[Y],37));
    Else Write(' ',PadRight(SubMenuAdvise[Y],37));
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
   FrameEmpty(4,2,33,4+High(SubMenuMenu),$F0);
   For I:=Low(SubMenuMenu)to High(SubMenuMenu)do Begin
    SubMenuItem(I,False);
   End;
  End;
  2:Begin
   FrameEmpty(13,2,42,4+High(SubMenuConfiguration),$F0);
   For I:=Low(SubMenuConfiguration)to High(SubMenuConfiguration)do Begin
    SubMenuItem(I,False);
   End;
  End;
  3:Begin
   FrameEmpty(31,2,70,4+High(SubMenuAdvise),$F0);
   For I:=Low(SubMenuAdvise)to High(SubMenuAdvise)do Begin
    SubMenuItem(I,False);
   End;
  End;
 End;
End;

Procedure ShowCommand;
Var
 I:Integer;
Begin
 For I:=Low(CommandsTitleList) to High(CommandsTitleList)do Begin
  If CommandsTitleList[I][1]='^'Then Begin
   TextColor(Yellow+BLINK);
   GotoXY(8+((21-Length(CommandsTitleList[I])) div 2),6+I);
   Write(Copy(CommandsTitleList[I],2,255))
  End
   Else
  Begin
   TextColor(White+BLINK);
   GotoXY(8,6+I);
   Write(CommandsTitleList[I]);
  End;
 End;
End;

Procedure BoxInfo(X1,Y1,X2,Y2:Byte;Title:String);Begin
 Box(X1+2,Y1+1,X2+2,Y2+1,$07);
 Box(X1,Y1,X2,Y2,$9F);
 FrameEmpty(X1,Y1,X2,Y2,$9F);
 Box(X1,Y1,X2,Y1,$F9);
 Title:=' '+Title+' ';
 GotoXY(X1+(((X2-X1)-Length(Title))shr 1),Y1);
 Write(Title);
 TextColor(White+BLINK);
 TextBackground(9);
End;

Procedure ShowPanel;Begin
 BoxInfo(3,3,78,22,'Le clone Norton Utilities');
 FrameEmpty(6,5,30,19,$9F);
 Box(6,5,30,5,$F9);
 GotoXY(14,5);
 Write('Commandes');
 FrameEmpty(32,5,76,19,$9F);
 Box(32,5,76,5,$F9);
 GotoXY(49,5);
 Write('Description');
 TextBackground(1);
 TextColor(White+BLINK);
End;

Procedure ShowFunctionKey;Begin
 TextColor(0+BLINK);
 TextBackground(7);
 GotoXY(1,25);
 ClrEol;
 Write(' Appuyer sur ENTER pour executer la commande');
 GotoXY(56,25);
 Write('| Norton Utilities Clone')
End;

Procedure Init;
Var
 Regs:Registers;
Begin
 OnMenu:=False;
  { DÇsactive le clignotement }
 Regs.AX:=$1003;
 Regs.BL:=$0;
 Intr($10,Regs);
 CurrPos:=1;
 ParamString:='';
 TextColor(White+BLINK);
 TextBackground(8);
 ClrScr;
 ShowMenu;
 ShowFunctionKey;
 ShowPanel;
 ShowCommand;
End;

Procedure SelectItem;
Var
 I,Y:Integer;
 HighColor:Boolean;
Begin
 TextBackground(Black);
 TextColor(White);
 GotoXY(8,6+CurrPos);
 Write(PadRight(CommandsTitleList[CurrPos],21));
 GotoXY(7,21);
 Write(CommandsList[CurrPos],' ',DuplicateString('.',68-Length(CommandsList[CurrPos])));
 Box(33,6,75,18,$9F);
 TextBackground(Blue);
 GotoXY(33,6);
 Y:=6;
 HighColor:=False;
 For I:=0 to StrLen(CommandsDescr[CurrPos])-1do Begin
  Case CommandsDescr[CurrPos][I]of
   '^':Begin
    HighColor:=Not HighColor;
    If(HighColor)Then TextColor(Yellow+BLINK)
                 Else TextColor(White+BLINK);
   End;
   #13:Begin
    Inc(Y);
    GotoXY(33,Y);
   End;
   Else Write(CommandsDescr[CurrPos][I]);
  End;
 End;
 TextBackground(Black);
 GotoXY(7+Length(CommandsList[CurrPos])+1,21);
End;

Procedure UnselectItem;Begin
 TextBackground(Blue);
 TextColor(White+BLINK);
 GotoXY(8,6+CurrPos);
 Write(PadRight(CommandsTitleList[CurrPos],21));
End;

Procedure HideSubMenu;Begin
 TextColor(White+BLINK);
 TextBackground(8);
 ClrScr;
 ShowMenu;
 ShowFunctionKey;
 ShowPanel;
 ShowCommand;
 SelectItem;
End;

Procedure NotImplemented;Begin
 Box(5,11,75,13,$60);
 FrameEmpty(5,11,75,13,$60);
 GotoXY(20,12);
 Write('Cette fonctionnalitÇ n''est pas implÇmentÇ');
 ReadKey;
 HideSubMenu;
End;

Procedure Run;
Var
 Terminated:Boolean;
 K:Char;
Begin
 Terminated:=False;
 SelectItem;
 Repeat
  K:=ReadKey;
  If(OnMenu)Then Case K of
   #0:Case ReadKey of
    #61:Terminated:=True; { F3 }
    #72:Begin { Up }
     SubMenuItem(YMenu,True);
     If YMenu>0Then Dec(YMenu)
               Else YMenu:=YMenuMax[XMenu];
     Case XMenu of
      1:If YMenu in[2]Then Dec(YMenu);
      2:If YMenu in[1,5,8]Then Dec(YMenu);
      3:If YMenu in[4]Then Dec(YMenu);
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
      1:If YMenu in[2]Then Inc(YMenu);
      2:If YMenu in[1,5,8]Then Inc(YMenu);
      3:If YMenu in[4]Then Inc(YMenu);
     End;
     SubMenuItem(YMenu,False);
    End;
   End;
   #13:Begin
    OnMenu:=False;
    HideSubMenu;
    Case XMenu of
     1:Case YMenu of
      0:NotImplemented;
      Else NotImplemented;
     End;
     4:Terminated:=True;
     Else NotImplemented;
    End;
   End;
   #27:Begin
    OnMenu:=False;
    HideSubMenu;
   End;
  End
   Else
  Case K of
   #0:Begin
    K:=ReadKey;
    Case K of
     #50:Begin { Alt+M }
      XMenu:=1;YMenu:=0;
      OnMenu:=True;
      ShowMenu;
      ShowSubMenu;
     End;
     #72:Begin { Up }
      If CurrPos>1Then Begin
       UnselectItem;
       Dec(CurrPos);
       If CommandsTitleList[CurrPos][1]='^'Then Dec(CurrPos);
       If Length(CommandsTitleList[CurrPos])=0Then Dec(CurrPos);
       SelectItem;
      End;
     End;
     #80:Begin { Down }
      If CurrPos<High(CommandsTitleList)Then Begin
       UnselectItem;
       Inc(CurrPos);
       If Length(CommandsTitleList[CurrPos])=0Then Inc(CurrPos);
       If CommandsTitleList[CurrPos][1]='^'Then Inc(CurrPos);
       SelectItem;
      End;
     End;
    End;
   End;
   #8:Begin
    If ParamString<>''Then ParamString:=Copy(ParamString,1,Length(ParamString)-1);
    GotoXY(7+Length(CommandsList[CurrPos])+1,21);
    Write(ParamString,'.');
    GotoXY(7+Length(CommandsList[CurrPos])+1,21);
    Write(ParamString);
   End;
   #9:Begin { Tab }
   End;
   #13:Begin
    ClrScr;
    Exec(CommandsList[CurrPos],ParamString);
    If CommandsPause[CurrPos]Then Begin
     WriteLn('Presse une touche pour retourner...');
     If ReadKey=#0Then ReadKey;
    End;
    ClrScr;
    ShowMenu;
    ShowFunctionKey;
    ShowPanel;
    ShowCommand;
    SelectItem;
    ParamString:='';
   End;
   #27:Terminated:=True; { Esc }
   Else Begin
    ParamString:=ParamString+K;
    GotoXY(7+Length(CommandsList[CurrPos])+1,21);
    Write(ParamString);
   End;
  End;
 Until Terminated;
End;

Procedure Done;Begin
 TextColor(7);
 TextBackground(Black);
 ClrScr;
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
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
  WriteLn('NORTON : Cette commande permet de lancer le menu Norton Utilities.');
  WriteLn;
  WriteLn('Syntaxe : NORTON [/ASCII128]');
  WriteLn;
  WriteLn(' /ASCII128   Ce parametre permet de lancer en mode compatibilite 128 caracteres seulement.');
 End
  Else
 Begin
  ShowASCII128:=False;
  If ParamCount>0Then For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/ASCII128'Then ShowASCII128:=True
    Else
   Begin
    WriteLn('Parametre inconnu : ',ParamStr(I));
    Halt;
   End;
  End;
  Init;
  Run;
  Done;
 End;
END.
