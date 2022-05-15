{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program NORTON;

{$M 4096,0,0}

Uses Strings,Crt,DOS;

Const
 CommandsTitleList:Array[0..10]of String[20]=(
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
  'TS (Recherche texte)'
 );

 CommandsList:Array[0..10]of String[12]=(
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
  'TS'
 );

 CommandsPause:Array[0..10]of Boolean=(
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
  True
 );

 CommandsDescr:Array[0..10]of PChar=(
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

  '^Recherche de texte^'+#13+
  'TS "chaine" [fichier] [/CS]'+#13+
  #13+
  'Recherche de texte dans des fichiers'
 );

Var
 ShowASCII128:Boolean;
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

Procedure ShowMenu;
Const
 MenuItem:Array[0..4]of String[15]=(
  'Menu','Configuration','Conseille','Quitte','F1=Aide'
 );
 MenuPos:Array[0..4]of Byte=(4,12,29,42,71);
Var
 I:Byte;
Begin
 Box(1,1,80,1,$70);
 For I:=0 to 4 do Begin
  GotoXY(MenuPos[I],1);
  Write(MenuItem[I]);
 End;
End;

Procedure ShowCommand;
Var
 I:Integer;
Begin
 For I:=Low(CommandsTitleList) to High(CommandsTitleList)do Begin
  If CommandsTitleList[I][1]='^'Then Begin
   TextColor(Yellow);
   GotoXY(8+((21-Length(CommandsTitleList[I])) div 2),6+I);
   Write(Copy(CommandsTitleList[I],2,255))
  End
   Else
  Begin
   TextColor(White);
   GotoXY(8,6+I);
   Write(CommandsTitleList[I]);
  End;
 End;
End;

Procedure ShowPanel;Begin
 Box(1,2,80,24,$80);
 Box(3,3,78,22,$1F);
 FrameEmpty(3,3,78,22,$1F);
 GotoXY(28,3);
 Write('Le clone Norton Utilities');
 FrameEmpty(6,5,30,19,$1F);
 GotoXY(14,5);
 Write('Commandes');
 FrameEmpty(32,5,76,19,$1F);
 GotoXY(49,5);
 Write('Description');
End;

Procedure ShowFunctionKey;Begin
 TextColor(0);
 TextBackground(7);
 GotoXY(1,25);
 ClrEol;
 Write(' Appuyer sur ENTER pour executer la commande');
 GotoXY(56,25);
 Write('| Norton Utilities Clone')
End;

Procedure Init;Begin
 CurrPos:=1;
 ParamString:='';
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
 Box(33,6,75,18,$1F);
 TextBackground(Blue);
 GotoXY(33,6);
 Y:=6;
 HighColor:=False;
 For I:=0 to StrLen(CommandsDescr[CurrPos])-1do Begin
  Case CommandsDescr[CurrPos][I]of
   '^':Begin
    HighColor:=Not HighColor;
    If(HighColor)Then TextColor(Yellow)
                 Else TextColor(White);
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
 TextColor(White);
 GotoXY(8,6+CurrPos);
 Write(PadRight(CommandsTitleList[CurrPos],21));
End;

Procedure Run;
Var
 K:Char;
Begin
 SelectItem;
 Repeat
  K:=ReadKey;
  Case K of
   #0:Begin
    K:=ReadKey;
    Case K of
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
   #27:Begin { ESC }
   End;
   Else Begin
    ParamString:=ParamString+K;
    GotoXY(7+Length(CommandsList[CurrPos])+1,21);
    Write(ParamString);
   End;
  End;
 Until K=#27;
End;

Procedure Done;Begin
 ClrScr;
End;

BEGIN
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