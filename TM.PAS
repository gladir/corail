{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program TeleMate;

{$M 16384,0,65536}

Uses Crt,DOS;

Const
 MainMenu:Array[0..8]of String[10]=(
  #240,'Fenˆtre','Dialogue','Terminal','Edition','Vue','ArriŠre','Macro','Options'
 );

 MainMenuEnglish:Array[0..8]of String[10]=(
  #240,'Window','Dial','Terminal','Edit','View','Back','Macro','Options'
 );

 SubMenuWindow:Array[0..12]of String[25]=(
  'Agrandir la fenˆtre','D‚place la fenˆtre','Redimensionne la fenˆtre','',
  'Fenˆtre DOS','Aller au DOS','','R‚pertoire de fichier',
  '','Presse-papier','Imprime le fichier','','Sortir'
 );

 SubMenuWindowEnglish:Array[0..12]of String[20]=(
  'Zoom window','Move window','Resize window','',
  'DOS command','Jump to DOS','','File directory',
  '','Clipboard','Print file','','Exit'
 );

 SubMenuTerminal:Array[0..19]of String[20]=(
  'Envoi un fichier','Re‡oi un fichier','Fichier journal','Scripte',
  'Apprendre le scripte','','Coller','R‚p‚ter coller','Image',
  'Pile de commande','','Mode de clavardage','Mode d''origine',
  'Mode r‚ponse','Mode par la porte',
  '','Raccrocher','Vider le texte','Signal d''arrˆt','Imprime le journal'
 );

 SubMenuTerminalEnglish:Array[0..19]of String[20]=(
  'Send file','Receive file','Log file','Script',
  'Learn script','','Paste','Quote','Image','Command stack',
  '','Chat mode','Originate mode','Answer mode','Doorway mode',
  '','Hang up','Clear text','Break signal','Printer log'
 );

 SubMenuOptions:Array[0..11]of String[25]=(
  'G‚n‚ral','Souris et clavier','Ajustement dialogue','R‚pertoire',
  'Terminal','Communication','Protocol','Protocol externe',
  '','Charge les options','Sauvegarde les fenˆtres','Sauvegarde les options'
 );

 SubMenuOptionsEnglish:Array[0..11]of String[20]=(
  'General','Mouse & Keybaord','Dial setup','dIrectory',
  'Terminal','Communication','Protocol','External protocol',
  '','Load options','save Windows','Save options'
 );

 YMenuMax:Array[1..9]of Byte=(
  0,High(SubMenuWindow),0,High(SubMenuTerminal),
  0,0,0,0,High(SubMenuOptions)
 );

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TerminalType:(_TTY,_ANSI,_AVATAR,_PRISM,_VT102,_VT52);
 Version,TmpLanguage:String;
 ShowASCII128,OnMenu,DoubleHor:Boolean;
 YMenu,XMenu:Integer;
 TerminalX,TerminalY:Integer;
 I:Integer;
 SerialPort:Byte;
 SerialBaud:Word;
 SerialParity:(ParityN,ParityO,ParityE);
 SerialData:Byte;
 SerialStop:Byte;
 ModemInit:String;

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

Function DuplicateStringASCII(C:Char;Num:Integer):String;Begin
 If(ShowASCII128)Then Case C of
  #196:C:='-';
 End;
 DuplicateStringASCII:=DuplicateString(C,Num);
End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function TrimL(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If S[I]<>' 'Then Begin
   TrimL:=Copy(S,I,255);
   Exit;
  End;
 End;
 TrimL:=S;
End;

Function TrimR(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 TrimR:=S;
End;

Function Trim(S:String):String;Begin
 Trim:=TrimL(TrimR(S));
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
  If(DoubleHor)Then Begin
   ChrHori:=#205;
   Chr218:=#213;
   Chr192:=#212;
   Chr191:=#184;
   Chr217:=#190;
  End
   Else
  Begin
   ChrHori:=#$C4;
   Chr218:=#218;
   Chr192:=#192;
   Chr191:=#191;
   Chr217:=#217;
  End;
  ChrVert:=#$B3;
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

Procedure LoadTmCfg;
Var
 CurrSection:(_None,_GeneralSetup,_MouseAndKeyboard,_KeyboardTranslation,
 _DialSetup,_Directory,_Terminal,_Communication,_ProtocolSetup,
 _VideoSetup,_PrinterSetup,_WindowSetup);
 FileCfg:Text;
 Err:Word;
 CurrLine,CurrWord,ResultValue:String;
Begin
 {$I-}Assign(FileCfg,'TM.CFG');
 Reset(FileCfg);{$I+}
 If IoResult=0Then Begin
  CurrSection:=_None;
  While Not EOF(FileCfg)do Begin
   ReadLn(FileCfg,CurrLine);
   CurrLine:=Trim(CurrLine);
   If StrToUpper(CurrLine)='% GENERAL SETUP'Then CurrSection:=_GeneralSetup Else
   If StrToUpper(CurrLine)='% MOUSE AND KEYBOARD'Then CurrSection:=_MouseAndKeyboard Else
   If StrToUpper(CurrLine)='% KEYBOARD TRANSLATION'Then CurrSection:=_KeyboardTranslation Else
   If StrToUpper(CurrLine)='% DIAL SETUP'Then CurrSection:=_DialSetup Else
   If StrToUpper(CurrLine)='% DIRECTORY'Then CurrSection:=_Directory Else
   If StrToUpper(CurrLine)='% TERMINAL'Then CurrSection:=_Terminal Else
   If StrToUpper(CurrLine)='% COMMUNICATION'Then CurrSection:=_Communication Else
   If StrToUpper(CurrLine)='% PROTOCOL SETUP'Then CurrSection:=_ProtocolSetup Else
   If StrToUpper(CurrLine)='% VIDEO SETUP'Then CurrSection:=_VideoSetup Else
   If StrToUpper(CurrLine)='% PRINTER SETUP'Then CurrSection:=_PrinterSetup Else
   If StrToUpper(CurrLine)='% WINDOW SETUP'Then CurrSection:=_WindowSetup
    Else
   If Copy(CurrLine,1,2)<>'%%'Then Begin
    CurrWord:='';
    I:=1;
    While(CurrLine[I]in['A'..'Z','a'..'z'])and(I<=Length(CurrLine))do Begin
     CurrWord:=CurrWord+CurrLine[I];
     Inc(I);
    End;
    While(CurrLine[I]in[' ',#9])and(I<=Length(CurrLine))do Inc(I);
    If CurrLine[I]='='Then Begin
     Inc(I);
     While(CurrLine[I]in[' ',#9])and(I<=Length(CurrLine))do Inc(I);
     ResultValue:=Copy(CurrLine,I,255);
     If(CurrSection=_Communication)Then Begin
      If StrToUpper(CurrWord)='DATA'Then Val(ResultValue,SerialData,Err)Else
      If StrToUpper(CurrWord)='BAUD'Then Val(ResultValue,SerialBaud,Err)Else
      If StrToUpper(CurrWord)='MODEMINIT'Then Begin
       ModemInit:=Copy(ResultValue,2,Length(ResultValue)-1);
      End
       Else
      If StrToUpper(CurrWord)='PARITY'Then Begin
       If StrToUpper(ResultValue)='N'Then SerialParity:=ParityN Else
       If StrToUpper(ResultValue)='O'Then SerialParity:=ParityO Else
       If StrToUpper(ResultValue)='E'Then SerialParity:=ParityE;
      End
       Else
      If StrToUpper(CurrWord)='PORT'Then Val(ResultValue,SerialPort,Err)Else
      If StrToUpper(CurrWord)='STOP'Then Val(ResultValue,SerialStop,Err);
     End
      Else
     If(CurrSection=_Terminal)Then Begin
      If StrToUpper(CurrWord)='TERMINALTYPE'Then Begin
       If(StrToUpper(ResultValue)='TTY')Then TerminalType:=_TTY Else
       If(StrToUpper(ResultValue)='ANSI')Then TerminalType:=_ANSI Else
       If(StrToUpper(ResultValue)='AVATAR')Then TerminalType:=_AVATAR Else
       If(StrToUpper(ResultValue)='PRISM')Then TerminalType:=_PRISM Else
       If(StrToUpper(ResultValue)='VT102')Then TerminalType:=_VT102 Else
       If(StrToUpper(ResultValue)='VT52')Then TerminalType:=_VT52;
      End;
     End;
    End;
   End;
  End;
  Close(FileCfg);
 End;
End;

Procedure SaveTmCfg;
Var
 FileCfg:Text;
Begin
 {$I-}Assign(FileCfg,'TM.CFG');
 Rewrite(FileCfg);{$I+}
 If IoResult=0Then Begin
  WriteLn(FileCfg,'Version="',Version,'"');
  WriteLn(FileCfg,'RegNo="[UNREGISTERED]"');
  WriteLn(FileCfg,'RegName="[UNREGISTERED]"');
  WriteLn(FileCfg);
  WriteLn(FileCfg);
  WriteLn(FileCfg,'% General setup');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'XmsHimem=Off');
  WriteLn(FileCfg,'XmsLimit=8192');
  WriteLn(FileCfg,'EmsLimit=8192');
  WriteLn(FileCfg,'VideoRam=32');
  WriteLn(FileCfg,'SwapToEms=On');
  WriteLn(FileCfg,'SwapToDisk=On');
  WriteLn(FileCfg,'MaxDosShell=Off');
  WriteLn(FileCfg,'ScrollBack=100');
  WriteLn(FileCfg,'EditorMargin=65');
  WriteLn(FileCfg,'ScrollBar=On');
  WriteLn(FileCfg,'Bar=On');
  WriteLn(FileCfg,'StatusLine=On');
  WriteLn(FileCfg,'Hour24=Off');
  WriteLn(FileCfg,'DateFormat=0');
  WriteLn(FileCfg,'LogFilter=On');
  WriteLn(FileCfg,'LogHeading=Off');
  WriteLn(FileCfg,'UsageLog=On');
  WriteLn(FileCfg,'Music=Off');
  WriteLn(FileCfg,'Bell=On');
  WriteLn(FileCfg,'ExternalAlarm=Off');
  WriteLn(FileCfg,'AlarmTime=5');
  WriteLn(FileCfg,'AlarmSound=5');
  WriteLn(FileCfg,'AlarmSong1="T240L16O4ABABABABABABABP2"');
  WriteLn(FileCfg,'AlarmSong2=""');
  WriteLn(FileCfg,'AlarmSong3=""');
  WriteLn(FileCfg,'AlarmSong4=""');
  WriteLn(FileCfg,'AlarmSong5=""');
  WriteLn(FileCfg,'MessagePause=1');
  WriteLn(FileCfg,'ErrorPause=2');
  WriteLn(FileCfg,'ScreenSaver=10');
  WriteLn(FileCfg,'DisplayAllInfo=Off');
  WriteLn(FileCfg);
  WriteLn(FileCfg);
  WriteLn(FileCfg,'% Mouse and keyboard');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'%% Mouse setup (MouseType  = None, MSMouse or MouseSys)');
  WriteLn(FileCfg,'%%             (MouseSpeed = Fast, Medium  or Slow)');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'MouseType=MSMouse');
  WriteLn(FileCfg,'MousePort=2');
  WriteLn(FileCfg,'MouseSpeed=Medium');
  WriteLn(FileCfg,'MouseSwapButton=Off');
  WriteLn(FileCfg,'EnhancedKeyboard=Off');
  WriteLn(FileCfg);
  WriteLn(FileCfg);
  WriteLn(FileCfg,'% Keyboard translation');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'Incoming=Off');
  WriteLn(FileCfg,'Outgoing=Off');
  WriteLn(FileCfg);
  WriteLn(FileCfg);
  WriteLn(FileCfg,'% Dial setup');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'Prefix=1');
  WriteLn(FileCfg,'Suffix=1');
  WriteLn(FileCfg,'DialPrefix1="AT DT"');
  WriteLn(FileCfg,'DialPrefix2="AT DP"');
  WriteLn(FileCfg,'DialPrefix3="AT DT"');
  WriteLn(FileCfg,'DialPrefix4="ATDT 9,"');
  WriteLn(FileCfg,'DialSuffix1="^M"');
  WriteLn(FileCfg,'DialSuffix2="^M"');
  WriteLn(FileCfg,'DialSuffix3="^M"');
  WriteLn(FileCfg,'DialSuffix4="^M"');
  WriteLn(FileCfg,'DialCancel="^M^M"');
  WriteLn(FileCfg,'DialBreak="RING^M"');
  WriteLn(FileCfg,'DialTime=35');
  WriteLn(FileCfg,'DialPause=2');
  WriteLn(FileCfg,'DialAttempt=0');
  WriteLn(FileCfg,'DialList=""');
  WriteLn(FileCfg,'DialField=7');
  WriteLn(FileCfg,'AutoBaudDetect=Off');
  WriteLn(FileCfg,'AutoRedial=On');
  WriteLn(FileCfg,'MultipleLine=On');
  WriteLn(FileCfg,'Connect1="CONNECT"');
  WriteLn(FileCfg,'Connect2=""');
  WriteLn(FileCfg,'Connect3=""');
  WriteLn(FileCfg,'Connect4=""');
  WriteLn(FileCfg,'Busy1="NO CARRIER"');
  WriteLn(FileCfg,'Busy2="BUSY"');
  WriteLn(FileCfg,'Busy3="VOICE"');
  WriteLn(FileCfg,'Busy4="NO DIAL"');
  WriteLn(FileCfg);
  WriteLn(FileCfg);
  WriteLn(FileCfg,'% Directory');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'DirTelemate=""');
  WriteLn(FileCfg,'DirUpload=""');
  WriteLn(FileCfg,'DirDownload=""');
  WriteLn(FileCfg,'DirScript=""');
  WriteLn(FileCfg,'DirEdit=""');
  WriteLn(FileCfg,'DirView=""');
  WriteLn(FileCfg,'DirWrite=""');
  WriteLn(FileCfg,'DirImage=""');
  WriteLn(FileCfg,'DirLog=""');
  WriteLn(FileCfg,'DirVirtualMemory=""');
  WriteLn(FileCfg);
  WriteLn(FileCfg);
  WriteLn(FileCfg,'% Terminal');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'%% TerminalType=TTY, ANSI, AVATAR, PRISM, VT102, VT52');
  WriteLn(FileCfg,'%% Connection=Modem, Computer, Fossil, Bios');
  WriteLn(FileCfg,'%% Protocol = Z,Y,G,B,X,O,R,T,S,M,K,C,A');
  WriteLn(FileCfg,'%% Line, character and extended pacing (in 1/20 sec)');
  WriteLn(FileCfg,'%% Pace character = 0 - 255 (ASCII)');
  WriteLn(FileCfg);
  Write(FileCfg,'TerminalType=');
  Case  TerminalType of
   _TTY:WriteLn(FileCfg,'TTY');
   _ANSI:WriteLn(FileCfg,'ANSI');
   _AVATAR:WriteLn(FileCfg,'AVATAR');
   _PRISM:WriteLn(FileCfg,'PRISM');
   _VT102:WriteLn(FileCfg,'VT102');
   _VT52:WriteLn(FileCfg,'VT52');
   Else WriteLn(FileCfg);
  End;
  WriteLn(FileCfg,'Connection=Modem');
  WriteLn(FileCfg,'Protocol=Z');
  WriteLn(FileCfg,'AddLineFeed=Off');
  WriteLn(FileCfg,'AddReturn=Off');
  WriteLn(FileCfg,'LocalEcho=Off');
  WriteLn(FileCfg,'AutoWrap=On');
  WriteLn(FileCfg,'DestructiveBs=On');
  WriteLn(FileCfg,'StripHighBit=Off');
  WriteLn(FileCfg,'ConfirmHangUp=On');
  WriteLn(FileCfg,'XonXoff=Off');
  WriteLn(FileCfg,'RtsCts=On');
  WriteLn(FileCfg,'Fifo16550=On');
  WriteLn(FileCfg,'ExpandBlankLine=On');
  WriteLn(FileCfg,'PaceChar=0');
  WriteLn(FileCfg,'LinePacing=0');
  WriteLn(FileCfg,'CharPacing=0');
  WriteLn(FileCfg,'ExtendedPacing=0');
  WriteLn(FileCfg,'TagSeparator=0');
  WriteLn(FileCfg,'InitialGuessing=On');
  WriteLn(FileCfg,'QuoteString="@> "');
  WriteLn(FileCfg,'QuoteMargin=70');
  WriteLn(FileCfg);
  WriteLn(FileCfg);
  WriteLn(FileCfg,'% Communication');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'%% Com = base address,interrupt no (usually IRQ+8, or HighIRQ+104),IRQ');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'Com1=3f8,12,4');
  WriteLn(FileCfg,'Com2=2f8,11,3');
  WriteLn(FileCfg,'Com3=3e8,12,4');
  WriteLn(FileCfg,'Com4=2e8,11,3');
  WriteLn(FileCfg,'Com5=3f8,12,4');
  WriteLn(FileCfg,'Com6=3f8,12,4');
  WriteLn(FileCfg,'Com7=3f8,12,4');
  WriteLn(FileCfg,'Com8=3f8,12,4');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'%%');
  WriteLn(FileCfg,'%% Init string for most modems');
  WriteLn(FileCfg,'%% ModemInit="AT S0=0 S7=100 S9=12 S11=50 Q0 E1 M1 V1 X4^M~~~AT&C1^M~"');
  WriteLn(FileCfg,'%%');
  WriteLn(FileCfg,'%% Init string for USR high speed modem');
  WriteLn(FileCfg,'%% ModemInit="AT &H1 &R2 S0=0 Q0 E1 M1 V1 X4^M~~~AT&C1^M~"');
  WriteLn(FileCfg,'%%');
  WriteLn(FileCfg,'%% Hangup string for most modems,  "^#" means drop DTR');
  WriteLn(FileCfg,'%%');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'ModemInit="',ModemInit,'"');
  WriteLn(FileCfg,'ModemHangUp="^#~~~+++~~~ATH0^M~"');
  WriteLn(FileCfg,'ModemAnswer="~~~+++~~~AT S0=1^M~"');
  WriteLn(FileCfg,'ModemAnsBack=""');
  WriteLn(FileCfg,'Port=',SerialPort);
  WriteLn(FileCfg,'Baud=',SerialBaud);
  Write(FileCfg,'Parity=');
  Case SerialParity of
   ParityN:WriteLn(FileCfg,'N');
   ParityO:WriteLn(FileCfg,'O');
   ParityE:WriteLn(FileCfg,'E');
   Else WriteLn(FileCfg,'?');
  End;
  WriteLn(FileCfg,'Data=',SerialData);
  WriteLn(FileCfg,'Stop=',SerialStop);
  WriteLn(FileCfg);
  WriteLn(FileCfg);
  WriteLn(FileCfg,'% Protocol setup');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'FilenameGuessing=On');
  WriteLn(FileCfg,'DiskSpace=On');
  WriteLn(FileCfg,'ZAutoDownload=On');
  WriteLn(FileCfg,'ZRecovery=Off');
  WriteLn(FileCfg,'ZAscii=Off');
  WriteLn(FileCfg,'Kermit=35,1,13,0,0,80,0');
  WriteLn(FileCfg,'AsciiUpload=Off,Off,Off,Off,Off,Off');
  WriteLn(FileCfg,'AsciiDownload=Off,Off,Off,Off,Off,Off');
  WriteLn(FileCfg,'Extern1="GIFLink","F","GIFZ-U","GIFZ-D",Off,""');
  WriteLn(FileCfg,'Extern2="GIFLink","Q","GIF-QB","GIF-QB",Off,""');
  WriteLn(FileCfg,'Extern3="HSLink","H","HSLINK-U","HSLINK-D",Off,"HS*R"');
  WriteLn(FileCfg,'Extern4="BiModem","I","BI-MODEM","BI-MODEM",Off,""');
  WriteLn(FileCfg,'Extern5="","","","",Off,""');
  WriteLn(FileCfg,'Extern6="","","","",Off,""');
  WriteLn(FileCfg,'Extern7="","","","",Off,""');
  WriteLn(FileCfg,'Extern8="","","","",Off,""');
  WriteLn(FileCfg);
  WriteLn(FileCfg);
  WriteLn(FileCfg,'% Video setup');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'%% VideoType = Default, Color, B&W or LCD');
  WriteLn(FileCfg,'%% VideoHeight = 25 (Mono)');
  WriteLn(FileCfg,'%%               25 to 32 (CGA)');
  WriteLn(FileCfg,'%%               25 to 28, 35, 43, 50 (EGA/VGA), 40 (VGA)');
  WriteLn(FileCfg,'%% SnowCheck apply on CGA only');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'VideoType=Color');
  WriteLn(FileCfg,'VideoHeight=25');
  WriteLn(FileCfg,'VideoCache=Off');
  WriteLn(FileCfg,'SnowCheck=Off');
  WriteLn(FileCfg);
  WriteLn(FileCfg);
  WriteLn(FileCfg,'% Printer setup');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'%% PrnPort = 0 for LPT1, 1 for LPT2, -1 for NULL');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'PrnPort=0');
  WriteLn(FileCfg);
  WriteLn(FileCfg);
  WriteLn(FileCfg,'% Window setup');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'%% MenuBar=   attr,barattr');
  WriteLn(FileCfg,'%% Menu=      attr,bdattr,barattr,highlite');
  WriteLn(FileCfg,'%% Help=      attr,bdattr,status,errattr');
  WriteLn(FileCfg,'%% Dial=      x,y,l,h,attr,bdattr,highattr,barattr,zoom');
  WriteLn(FileCfg,'%% Terminal=  x,y,l,h,attr,bdattr,xferattr,xferbdattr,zoom');
  WriteLn(FileCfg,'%% Edit=      x,y,l,h,attr,bdattr,mark,status,errattr,zoom,indent,backup');
  WriteLn(FileCfg,'%% View=      x,y,l,h,attr,bdattr,mark,status,errattr,zoom');
  WriteLn(FileCfg,'%% Back=      x,y,l,h,attr,bdattr,mark,status,errattr,zoom,scrollock,capture');
  WriteLn(FileCfg,'%% Macro=     x,y,l,h,attr,bdattr,zoom');
  WriteLn(FileCfg,'%% Stack=     x,y,l,h,attr,bdattr,zoom');
  WriteLn(FileCfg,'%% Dos=       x,y,l,h,attr,bdattr,zoom');
  WriteLn(FileCfg,'%% Option=    attr,bdattr,optattr,highlite');
  WriteLn(FileCfg);
  WriteLn(FileCfg,'MenuBar=112,31');
  WriteLn(FileCfg,'Menu=31,23,95,30');
  WriteLn(FileCfg,'Help=26,26,48,79');
  WriteLn(FileCfg,'Dial=0,1,53,-3,27,19,31,112,On');
  WriteLn(FileCfg,'Terminal=0,/2-2,78,+1/2-2,15,2,On');
  WriteLn(FileCfg,'Transfer=37,4,30,113');
  WriteLn(FileCfg,'Edit=1,2,72,/2,10,2,31,23,79,Off,Off,Off');
  WriteLn(FileCfg,'View=3,5,72,/2,10,2,31,23,79,Off');
  WriteLn(FileCfg,'Back=5,8,72,/2,10,2,31,23,79,Off,Off,On');
  WriteLn(FileCfg,'Macro=61,1,17,21,48,48,Off');
  WriteLn(FileCfg,'Stack=0,1,78,4,78,78,Off');
  WriteLn(FileCfg,'Dos=0,/2-3,78,+1/2,7,7,Off');
  WriteLn(FileCfg,'Option=49,49,19,58');
  Close(FileCfg);
 End;
End;

Procedure SetColorSelect;Begin
 TextColor(15);
 TextBackground(1);
End;

Procedure SetColorUnSelect;Begin
 TextColor(0);
 TextBackground(7);
End;

Procedure ShowMenu;
Var
 I:Byte;
Begin
 Box(1,1,80,1,$70);
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

Procedure SetColorSubSelect;Begin
 TextColor(White);
 TextBackground(Magenta);
End;

Procedure SetColorSubUnSelect;Begin
 TextColor(White);
 TextBackground(Blue);
End;

Procedure SubMenuItem(Y:Integer;Disable:Boolean);Begin
 If(Disable)Then SetColorSubUnSelect Else
 If Y=YMenu Then SetColorSubSelect
            Else SetColorSubUnSelect;
 Case XMenu of
  2:Begin
   GotoXY(5,3+Y);
   If SubMenuWindow[Y]=''Then Write(' ',DuplicateStringASCII(#196,25+1),' ')
    Else
   Case Language of
    _English:Write('  ',PadRight(SubMenuWindowEnglish[Y],26));
    Else Write('  ',PadRight(SubMenuWindow[Y],26));
   End;
  End;
  4:Begin
   Case Language of
    _English:Begin
     GotoXY(19,3+Y);
     If SubMenuTerminal[Y]=''Then Write(' ',DuplicateStringASCII(#196,26+1),' ')
                           Else Write('  ',PadRight(SubMenuTerminalEnglish[Y],27));
    End;
    Else Begin
     GotoXY(24,3+Y);
     If SubMenuTerminal[Y]=''Then Write(' ',DuplicateStringASCII(#196,26+1),' ')
                             Else Write('  ',PadRight(SubMenuTerminal[Y],27))
    End;
   End;
  End;
  9:Begin
   Case Language of
    _English:Begin
     GotoXY(54,3+Y);
     If SubMenuOptions[Y]=''Then Write(' ',DuplicateStringASCII(#196,22+1),' ')
                           Else Write('  ',PadRight(SubMenuOptionsEnglish[Y],23));
    End;
    Else Begin
     GotoXY(52,3+Y);
     If SubMenuOptions[Y]=''Then Write(' ',DuplicateStringASCII(#196,24+1),' ')
                            Else Write('  ',PadRight(SubMenuOptions[Y],25))
    End;
   End;
  End;
 End;
End;

Procedure ShowSubMenu;
Var
 I:Integer;
Begin
 DoubleHor:=True;
 Case XMenu of
  2:Begin
   Case Language of
    _English:FrameEmpty(4,2,33,4+High(SubMenuWindow),$1F);
    Else FrameEmpty(4,2,33,4+High(SubMenuWindow),$1F);
   End;
   For I:=Low(SubMenuWindow)to High(SubMenuWindow)do Begin
    SubMenuItem(I,False);
   End;
  End;
  4:Begin
   Case Language of
    _English: FrameEmpty(18,2,48,4+High(SubMenuTerminal),$1F);
    Else FrameEmpty(23,2,53,4+High(SubMenuTerminal),$1F);
   End;
   For I:=Low(SubMenuTerminal)to High(SubMenuTerminal)do Begin
    SubMenuItem(I,False);
   End;
  End;
  9:Begin
   Case Language of
    _English: FrameEmpty(53,2,79,4+High(SubMenuOptions),$1F);
    Else FrameEmpty(51,2,79,4+High(SubMenuOptions),$1F);
   End;
   For I:=Low(SubMenuOptions)to High(SubMenuOptions)do Begin
    SubMenuItem(I,False);
   End;
  End;
 End;
End;

Procedure ShowBottom;Begin
 GotoXY(1,25);
 TextColor(Black);
 TextBackground(Cyan);
 Case Language of
  _English:Write('F1=Help ');
  Else Write('F1=Aide ');
 End;
 Write(#179);
 Case TerminalType of
  _TTY:Write(' TTY  ');
  _ANSI: Write(' ANSI ');
  _AVATAR: Write('AVATAR');
  _PRISM: Write('PRISM ');
  _VT102: Write('VT102 ');
  _VT52: Write(' VT52 ');
 End;
 Write(#179);
 Write(SerialBaud:6);
 Case SerialParity of
  ParityN:Write('N');
  ParityO:Write('O');
  ParityE:Write('E');
  Else Write('?');
 End;
 Write(SerialData,SerialStop,',',SerialPort);
 Write(#179,' ':20,#179,' Telemate ',Version);
 ClrEol;
End;

Procedure HomeMessage;Begin
 Window(1,2,80,24);
 TextColor(15);
 TextBackground(0);
 ClrScr;
 GotoXY(1,1);
 WriteLn;
 WriteLn('Telemate Clone Version ',Version);
 WriteLn('Licence MIT. Tous droits r‚serv‚ gladir.com');
 WriteLn;
 WriteLn('Enregistrement libre');
 WriteLn;
 If Not(Rs232Init)Then WriteLn('Erreur d''initialisation de modem');
 TerminalX:=WhereX;
 TerminalY:=WhereY;
 Window(1,1,80,25);
End;

Procedure HideSubMenu;Begin
 ShowMenu;
 HomeMessage;
End;

Procedure RefreshAll;Begin
 ClrScr;
 ShowMenu;
 ShowBottom;
 HomeMessage;
End;

Procedure JumpToDOS;Begin
 TextColor(7);
 TextBackground(0);
 ClrScr;
 Exec(GetEnv('COMSPEC'),'');
 RefreshAll;
End;

Procedure NotImplemented;Begin
 Box(5,11,75,13,$60);
 FrameEmpty(5,11,75,13,$60);
 GotoXY(20,12);
 Write('Cette fonctionnalite n''est pas impl‚ment‚');
 ReadKey;
 ShowMenu;
 HomeMessage;
End;

Procedure TerminalPos;Begin
 GotoXY(TerminalX,TerminalY+1);
End;

Procedure InitTeleMate;Begin
 LoadTmCfg;
 ClrScr;
 ShowMenu;
 ShowBottom;
 HomeMessage;
End;

Procedure RunTeleMate;
Var
 K:Char;
 Terminated:Boolean;
Begin
 Terminated:=False;
 Repeat
  TerminalPos;
  K:=ReadKey;
  If(OnMenu)Then Case K of
   #0:Case ReadKey of
    #72:Begin { Up }
     SubMenuItem(YMenu,True);
     If YMenu>0Then Dec(YMenu)
               Else YMenu:=YMenuMax[XMenu];
     Case XMenu of
      2:If YMenu in[3,6,8,11]Then Dec(YMenu);
      4:If YMenu in[5,10,15]Then Dec(YMenu);
      9:If YMenu in[8]Then Dec(YMenu);
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
      2:If YMenu in[3,6,8,11]Then Inc(YMenu);
      4:If YMenu in[5,10,15]Then Inc(YMenu);
      9:If YMenu in[8]Then Inc(YMenu);
     End;
     SubMenuItem(YMenu,False);
    End;
   End;
   #13:Begin
    OnMenu:=False;
    HideSubMenu;
    Case XMenu of
     2:Case YMenu of
      5:JumpToDOS;
      12:Terminated:=True;
      Else NotImplemented;
     End;
     9:Case YMenu of
      9:LoadTmCfg;
      11:SaveTmCfg;
      Else NotImplemented;
     End;
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
   #0:Case ReadKey of
    #17,#33:Begin { Alt+W, Alt+F }
     XMenu:=2;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #24:Begin { Alt+O }
     XMenu:=9;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #45:Terminated:=True; { Alt+X }
   End;
  End;
 Until Terminated;
End;

Procedure DoneTeleMate;Begin
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
    WriteLn('Run the TeleMate program.');
    WriteLn;
    WriteLn('TM [/ASCII128]')
   End;
   Else Begin
    WriteLn('TM : Cette commande permet de lancer l''application TeleMate');
    WriteLn;
    WriteLn('Syntaxe : TM [/ASCII128]');
    WriteLn;
    WriteLn(' /ASCII128   Ce parametre permet de lancer en mode compatibilite 128 caracteres seulement.');
   End;
  End;
 End
  Else
 Begin
  Version:='0.01';
  TerminalType:=_TTY;
  SerialPort:=1;
  SerialBaud:=9600;
  SerialParity:=ParityN;
  SerialData:=8;
  SerialStop:=1;
  ModemInit:='AT S0=0 Q0 E1 X4^M~~~AT&C1^M~';
  If ParamCount>0Then For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/ASCII128'Then ShowASCII128:=True;
  End;
  InitTeleMate;
  RunTeleMate;
  DoneTeleMate;
 End;
END.