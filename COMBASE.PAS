{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program COMBASE;

{$M 16384,0,65536}

Uses Crt,DOS;

Const
 MainMenu:Array[0..7]of String[15]=(
  'Terminal','Connecte','Xfer Fichs','Macros',
  'Fichier','Ajuste','Applications','Sortir'
 );

 MainMenuEnglish:Array[0..7]of String[15]=(
  'Terminal','Connect','Xfer Files','Macros',
  'File','Setup','Applications','Quit'
 );

 SubMenuConnect:Array[0..6]of String[35]=(
  'R‚pertoire de num‚ration',
  'Num‚rotation rapide',
  'Raccrocher',
  'Configure le r‚pertoire de num.',
  'Mode de r‚ponse',
  'R‚ponse avec CP … distance',
  'Processeur de commande … distance'
 );

 SubMenuConnectEnglish:Array[0..6]of String[20]=(
  'Dialing Directory',
  'Quick Dial',
  'Hangup',
  'Configure Dialing Dir',
  'Answer Mode',
  'Answer with Remote CP',
  'Remote Cmd Processor'
 );

 SubMenuXferFiles:Array[0..9]of String[20]=(
  '   Envoyer:',
  'Xmodem CRC',
  'Ymodem',
  'Ymodem Batch',
  'Ascii',
  '   Recevoir:',
  'Xmodem CRC',
  'Ymodem',
  'Ymodem Batch',
  'Ascii'
 );

 SubMenuXferFilesEnglish:Array[0..9]of String[20]=(
  '   Send:',
  'Xmodem CRC',
  'Ymodem',
  'Ymodem Batch',
  'Ascii',
  '   Receive:',
  'Xmodem CRC',
  'Ymodem',
  'Ymodem Batch',
  'Ascii'
 );

 SubMenuFile:Array[0..5]of String[20]=(
  'R‚pertoire',
  'AccŠs DOS',
  'Type',
  'Copie',
  'Efface',
  'Batch.bat'
 );

 SubMenuFileEnglish:Array[0..5]of String[20]=(
  'Directory',
  'DOS Access',
  'Type',
  'Copy',
  'Erase',
  'Batch.bat'
 );

 SubMenuSetup:Array[0..8]of String[30]=(
  'R‚pertoire de num‚ration',
  'ParamŠtres',
  'G‚n‚ral par d‚faut',
  'Modem',
  'Mode EGA en 43 Lignes',
  'Fixe la couleur du Menu',
  'Fixe la couleur du Terminal',
  'Fixe la couleur Xfer',
  'Contr“le de la neige'
 );

 SubMenuSetupEnglish:Array[0..8]of String[20]=(
  'Dialing Directory','Parameters','General Defaults','Modem',
  '43 Line EGA Mode','Set Menu Color','Set Term Color',
  'Set Xfer Color','Snow Control'
 );

 SubMenuApplications:Array[0..1]of String[25]=(
  'MemoRite',
  'Informations du programme'
 );

 SubMenuApplicationsEnglish:Array[0..1]of String[15]=(
  'MemoRite',
  'Program Info'
 );

 YMenuMax:Array[1..8]of Byte=(
  0,High(SubMenuConnect),High(SubMenuXferFiles),
  0,High(SubMenuFile),High(SubMenuSetup),
  High(SubMenuApplications),0
 );

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 I:Integer;
 ShowASCII128,OnMenu,DoubleFrame:Boolean;
 YMenu,XMenu:Integer;
 SerialPort:Byte;
 SerialBaud:Word;
 SerialParity:(ParityN,ParityO,ParityE);
 SerialData:Byte;
 SerialStop:Byte;
 ModemInit:String;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
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

Function DuplicateString(C:Char;Num:Integer):String;
Var
 I:Byte;
 S:String;
Begin
 S:='';
 For I:=1 to Num do S:=S+C;
 DuplicateString:=S;
End;

Function Rs232Ready(Port:Byte):Boolean;
Var
 Regs:Registers;
Begin
 Rs232Ready:=False;
 If(Port>1)or(Port>4)Then Exit;
 Regs.AX:=$0300;
 Regs.DX:=Port-1;
 Intr($14,Regs);
 If(Regs.AX and $0300)=0 Then Exit;
 Rs232Ready:=True;
End;

Function Rs232Send(Port:Byte;S:String):Boolean;
Var
 K,L:Byte;
 Regs:Registers;
 RawS:String;
Begin
 Rs232Send:=False;
 Regs.AH:=$01;
 Regs.DX:=Port-1;
 RawS:='';
 K:=1;
 While K<Length(S)do Begin
  If Copy(S,K,2)='^M'Then Begin
   RawS:=RawS+#13;
   Inc(K,2);
  End
   Else
  Begin
   RawS:=RawS+S[K];
   Inc(K);
  End;
 End;
 For K:=1 to Length(RawS)do Begin
  L:=0;
  While(L<250)and(Not Rs232Ready(Port))do L:=L+1;
  If L>=250 Then Exit;
  Regs.AL:=Ord(RawS[K]);
  Intr($14,Regs);
  If(Regs.AH and $8E)<>0 Then Exit;
 End;
 Rs232Send:=True;
End;

Function Rs232Init:Boolean;Begin
 Rs232Init:=Rs232Send(SerialPort,ModemInit);
End;

Function Rs232Compose(PhoneNumber:String):Boolean;Begin
 Rs232Compose:=Rs232Send(SerialPort,'ATDT'+PhoneNumber);
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
 Box(1,2,80,2,$07);
 GotoXY(1,2);
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
 SetColorUnSelect;
 GotoXY(1,3);
 Write(DuplicateString(#196,80));
End;

Procedure SubMenuItem(Y:Integer;Disable:Boolean);Begin
 If(Disable)Then SetColorUnSelect Else
 If Y=YMenu Then SetColorSelect
            Else SetColorUnSelect;
 Case XMenu of
  2:Begin
   GotoXY(12,4+Y);
   If SubMenuConnect[Y]=''Then Write(DuplicateString('-',35+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuConnectEnglish[Y],35));
    Else Write(' ',PadRight(SubMenuConnect[Y],35));
   End;
  End;
  3:Begin
   Case Language of
    _English:GotoXY(21,4+Y);
    Else GotoXY(22,4+Y);
   End;
   If SubMenuXferFiles[Y]=''Then Write(DuplicateString('-',25+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuXferFilesEnglish[Y],25));
    Else Write(' ',PadRight(SubMenuXferFiles[Y],25));
   End;
  End;
  5:Begin
   Case Language of
    _English:GotoXY(41,4+Y);
    Else GotoXY(42,4+Y);
   End;
   If SubMenuFile[Y]=''Then Write(DuplicateString('-',25+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuFileEnglish[Y],25));
    Else Write(' ',PadRight(SubMenuFile[Y],25));
   End;
  End;
  6:Begin
   Case Language of
    _English:GotoXY(47,4+Y);
    Else GotoXY(51,4+Y);
   End;
   If SubMenuSetup[Y]=''Then Write(DuplicateString('-',28+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuSetupEnglish[Y],28));
    Else Write(' ',PadRight(SubMenuSetup[Y],28));
   End;
  End;
  7:Begin
   GotoXY(53,4+Y);
   If SubMenuApplications[Y]=''Then Write(DuplicateString('-',26+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuApplicationsEnglish[Y],26));
    Else Write(' ',PadRight(SubMenuApplications[Y],26));
   End;
  End;
 End;
End;

Procedure ShowSubMenu;
Var
 I:Integer;
Begin
 Case XMenu of
  2:Begin
   FrameEmpty(11,3,48,5+High(SubMenuConnect),$07);
   For I:=Low(SubMenuConnect)to High(SubMenuConnect)do Begin
    SubMenuItem(I,False);
   End;
  End;
  3:Begin
   Case Language of
    _English: FrameEmpty(20,3,47,5+High(SubMenuXferFiles),$07);
    Else FrameEmpty(21,3,48,5+High(SubMenuXferFiles),$07);
   End;
   For I:=Low(SubMenuXferFiles)to High(SubMenuXferFiles)do Begin
    SubMenuItem(I,False);
   End;
  End;
  5:Begin
   Case Language of
    _English:FrameEmpty(40,3,67,5+High(SubMenuFile),$07);
    Else FrameEmpty(41,3,68,5+High(SubMenuFile),$07);
   End;
   For I:=Low(SubMenuFile)to High(SubMenuFile)do Begin
    SubMenuItem(I,False);
   End;
  End;
  6:Begin
   Case Language of
    _English:FrameEmpty(46,3,76,5+High(SubMenuSetup),$07);
    Else FrameEmpty(50,3,80,5+High(SubMenuSetup),$07);
   End;
   For I:=Low(SubMenuSetup)to High(SubMenuSetup)do Begin
    SubMenuItem(I,False);
   End;
  End;
  7:Begin
   FrameEmpty(52,3,80,5+High(SubMenuApplications),$07);
   For I:=Low(SubMenuApplications)to High(SubMenuApplications)do Begin
    SubMenuItem(I,False);
   End;
  End;
 End;
End;

Procedure HideSubMenu;Begin
 Box(1,2,80,15,$07);
End;

Procedure NotImplemented;Begin
 Box(5,11,75,13,$60);
 FrameEmpty(5,11,75,13,$60);
 GotoXY(20,12);
 Write('Cette fonctionnalite n''est pas implemented');
 ReadKey;
 Box(5,11,75,13,$07);
End;

Procedure ShowStatusBar;Begin
 TextColor(8);
 TextBackground(7);
 GotoXY(1,25);
 Write('ComBase ');
 Case Language of
  _English:Write('F1-Help');
  Else Write('F1-Aide');
 End;
 Write('  COM',SerialPort,'  Baud ',SerialBaud,'  ');
 Write(SerialData,' ');
 Case SerialParity of
  ParityN:Write('NONE');
  ParityO:Write('O');
  ParityE:Write('E');
 End;
 Write(' ',SerialStop,'Dup FULL  Capt OFF  :  NO FILE');
 ClrEol;
End;

Procedure Init;Begin
 TextColor(7);
 TextBackground(0);
 ClrScr;
 TextColor(8);
 TextBackground(7);
 GotoXY(1,1);
 Write(' ':8,'AdComm - Advanced Communications Library');
 ClrEol;
 ShowMenu;
 ShowStatusBar;
 GotoXY(1,3);
End;

Procedure Run;
Var
 Terminated:Boolean;
 K:Char;
Begin
 Terminated:=False;
 Repeat
  K:=ReadKey;
  If(OnMenu)Then Case K of
   #0:Case ReadKey of
     #72:Begin { Up }
      SubMenuItem(YMenu,True);
      If YMenu>0Then Dec(YMenu)
                Else YMenu:=YMenuMax[XMenu];
      Case XMenu of
       3:If YMenu in[0,5]Then Begin
        If YMenu=0Then YMenu:=YMenuMax[XMenu]
                  Else Dec(YMenu);
       End;
      End;
      SubMenuItem(YMenu,False);
     End;
     #75:Begin { Gauche }
     HideSubMenu;
     If XMenu>1 Then Dec(XMenu)
                Else XMenu:=High(MainMenu)+1;
     If XMenu=3Then YMenu:=1
               Else YMenu:=0;
     ShowMenu;
     ShowSubMenu;
    End;
    #77:Begin { Droite }
     HideSubMenu;
     If XMenu<=High(MainMenu)Then Inc(XMenu)
                             Else XMenu:=1;
     If XMenu=3Then YMenu:=1
               Else YMenu:=0;
     ShowMenu;
     ShowSubMenu;
    End;
    #80:Begin { Down }
     SubMenuItem(YMenu,True);
     If YMenu<YMenuMax[XMenu]Then Inc(YMenu)
                             Else YMenu:=0;
     Case XMenu of
      3:If YMenu in[0,5]Then Inc(YMenu);
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
     8:Begin
      Terminated:=True;
      Break;
     End;
     Else NotImplemented;
    End;
   End;
   #27:Begin
    OnMenu:=False;
    HideSubMenu;
   End;
  End
 Until K=#27;
End;

Procedure Done;Begin
 TextColor(7);
 TextBackground(0);
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
  Case Language of
   _English:Begin
    WriteLn('Run the ComBase program.');
    WriteLn;
    WriteLn('COMBASE [/ASCII128]')
   End;
   Else Begin
    WriteLn('COMBASE : Cette commande permet de lancer l''application ComBase');
    WriteLn;
    WriteLn('Syntaxe : COMBASE [/ASCII128]');
    WriteLn;
    WriteLn(' /ASCII128   Ce parametre permet de lancer en mode compatibilite 128 caracteres seulement.');
   End;
  End;
 End
  Else
 Begin
  OnMenu:=True;
  YMenu:=0;XMenu:=1;
  SerialPort:=1;
  SerialBaud:=9600;
  SerialParity:=ParityN;
  SerialData:=8;
  SerialStop:=1;
  ModemInit:='AT S0=0 Q0 E1 X4^M~~~AT&C1^M~';
  If ParamCount>0Then For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/ASCII128'Then ShowASCII128:=True;
  End;
  Init;
  Run;
  Done;
 End;
END.