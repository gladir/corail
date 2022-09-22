{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program SYSINFO;

{$M 16384,0,0}

Uses Crt,DOS,Strings;

Const

 MainMenu:Array[0..5]of String[15]=(
  'SystŠme','Disque','Memoire','Performance','Rapport','Quitter!'
 );

 MainMenuEnglish:Array[0..5]of String[15]=(
  'System','Disks','Memory','Benchmarks','Report','Quit!'
 );

 SubMenuSystem:Array[0..7]of String[30]=(
  'Sommaire systŠme...',
  'Sommaire vid‚o...',
  '',
  'Interruptions mat‚riel...',
  'Interruptions logiciels...',
  '',
  'Informations r‚seau...',
  'tats CMOS...'
 );

 SubMenuSystemEnglish:Array[0..7]of String[30]=(
  'System summary...',
  'Video summary...',
  '',
  'Hardware interrupts...',
  'Software interurpts...',
  '',
  'Network information...',
  'CMOS status...'
 );

 SubMenuDisks:Array[0..2]of String[30]=(
  'Sommaire disque...','Caract‚ristiques du disque...','Tables de partition...'
 );

 SubMenuDisksEnglish:Array[0..2]of String[30]=(
  'Disk summary...','disk Characteristics...','Partition Tables...'
 );

 SubMenuMemory:Array[0..6]of String[30]=(
  'Sommaire d''usage de la m‚moire...',
  'Expansion de m‚moire (EMS)...',
  'M‚moire ‚tendue (XMS)...',
  '',
  'List des blocs de m‚moire...',
  'Programme TSR...',
  'Pilote de p‚riph‚rique...'
 );

 SubMenuMemoryEnglish:Array[0..6]of String[30]=(
  'memory Usage summary...','Expanded memory (EMS)...',
  'eXtended memory (XMS)...','','memory Block list...',
  'TSR programs...','Device drivers...'
 );

 SubMenuBenchmarks:Array[0..3]of String[40]=(
  'Vitesse du microprocesseur...',
  'Vitesse du disque dur...',
  'Indice de performance global...',
  'Vitesse de performance du r‚seau...'
 );

 SubMenuBenchmarksEnglish:Array[0..3]of String[40]=(
  'CPU speed...',
  'Hard disk speed...',
  'Overall Performance Index...',
  'Network performance speed...'
 );

 SubMenuReport:Array[0..3]of String[30]=(
  'Voir CONFIG.SYS...','Voir AUTOEXEC.BAT','','Impression du rapport...'
 );

 SubMenuReportEnglish:Array[0..3]of String[30]=(
  'view CONFIG.SYS...','view AUTOEXEC.BAT','','Print report...'
 );

 YMenuMax:Array[1..6]of Byte=(
  High(SubMenuSystem),High(SubMenuDisks),High(SubMenuMemory),
  High(SubMenuBenchmarks),High(SubMenuReport),0
 );

Type
 XMSRegs=Record
  AX,BX,DX,SI,Segment:Word;
 End;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 I:Integer;
 ShowASCII128,OnMenu:Boolean;
 YMenu,XMenu:Integer;
 XMSPtr:Pointer;
 XMSErr:Byte;

{$IFNDEF FPC}
 Procedure CursorOff;
 Var
  Regs:Registers;
 Begin
  Regs.AH:=1;
  Regs.CH:=32;
  Regs.CL:=0;
  Intr($10,Regs);
 End;

 Procedure CursorOn;
 Var
  Regs:Registers;
 Begin
  Regs.AX:=$0100;
  Regs.CX:=(7 shl 8)+9;
  Intr($10,Regs);
 End;
{$ENDIF}

Function GetConvMemory:Word;
Var
 Regs:Registers;
Begin
 Regs.AX:=0;
 Intr($12,Regs);
 GetConvMemory:=Regs.AX;
End;

Function DateBIOS:String;
{$IFDEF FPC}
Begin
 DateBIOS:='Non disponible';
End;
{$ELSE}
 Var
  Chaine:Array[0..7] of Byte Absolute $FFFF:$5;
  Temp:String[15];
  Compteur:Byte;
 Begin
  Temp:='';
  For Compteur:=0 to 7 do Begin
   Temp:=Temp+Chr(Chaine[Compteur]);
  End;
  DateBIOS := Temp;
 End;
{$ENDIF}

Function GetEquip:Word;
Var
 Regs:Registers;
Begin
 Regs.AX:=0;
 Intr($11,Regs);
 GetEquip:=Regs.AX;
End;

Function GetNumParallelPort:Word;Begin
 GetNumParallelPort:=(GetEquip shr 14)and 3;
End;

Function GetNumSerialPort:Word;Begin
 GetNumSerialPort:=(GetEquip shr 9) and 3;
End;

Function XMSInit:Boolean;
Var
 Regs:Registers;
 xr:XMSRegs;
Begin
 Regs.AX:=$4300;
 Intr($2F,Regs);
 If(Regs.AL=$80)Then Begin
  Regs.AX:=$4310;
  Intr($2F,Regs);
  {$IFNDEF FPC}
   XMSPtr:=Ptr(Regs.ES,Regs.BX);
  {$ENDIF}
  XMSErr:=0;
  XMSInit:=True;
 End
  Else
 XMSInit:=False;
End;

Procedure XMSCall(NumFonc:Byte;Var XRegs:XMSRegs);Begin
 {$IFNDEF FPC}
  Inline ( $8C / $D9 /                          { mov    cx,ds        *}
            $51 /                                { push   cx           *}
            $C5 / $BE / $04 / $00 /              { lds    di,[bp+0004] *}
            $8A / $66 / $08 /                    { mov    ah,[bp+0008] *}
            $8B / $9D / $02 / $00 /              { mov    bx,[di+0002] *}
            $8B / $95 / $04 / $00 /              { mov    dx,[di+0004] *}
            $8B / $B5 / $06 / $00 /              { mov    si,[di+0006] *}
            $8E / $5D / $08 /                    { mov    ds,[di+08]   *}
            $8E / $C1 /                          { mov    es,cx        *}
            $26 / $FF / $1E / XMSPtr /           { call   es:[XMSPtr]  *}
            $8C / $D9 /                          { mov    cx,ds        *}
            $C5 / $7E / $04 /                    { lds    di,[bp+04]   *}
            $89 / $05 /                          { mov    [di],ax      *}
            $89 / $5D / $02 /                    { mov    [di+02],bx   *}
            $89 / $55 / $04 /                    { mov    [di+04],dx   *}
            $89 / $75 / $06 /                    { mov    [di+06],si   *}
            $89 / $4D / $08 /                    { mov    [di+08],cx   *}
            $1F                                  { pop    ds           *}
         );
  If(XRegs.AX = 0)and(XRegs.BX >= 128)Then Begin
   XMSErr:=Lo(XRegs.BX)
  End
   else
 {$ENDIF}
 XMSErr:=0;
End;

Function XMSUsed:Integer;
Var
 Used:Integer;
 Handle:Word;
 Xr:XMSRegs;
Begin
 Used:=0;
 For Handle:=0 to 65520 do Begin
  Xr.DX:=Handle;
  XmsCall(14,Xr);
  If Xr.AX=0 Then Break;
  Inc(Used,Xr.DX);
 End;
 XMSUsed:=Used;
End;

Function XMSFree:Integer;
Var
 Xr:XMSRegs;
Begin
 XmsCall(8,Xr);
 XMSFree:=Xr.AX;
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

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
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

Procedure ShowHome;Begin
 TextColor(White+BLINK);
 TextBackground(8);
 ClrScr;
End;

Procedure ShowStatusBar;Begin
 TextColor(Red+BLINK);
 TextBackground(7);
 GotoXY(1,25);
 ClrEol;
 GotoXY(60,25);
 Case Language of
  _English:Write(#179,'System info');
  Else Write(#179,'Information systŠme');
 End;
 ClrEol;
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
   GotoXY(5,3+Y);
   If SubMenuSystem[Y]=''Then Write(DuplicateString('-',27+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuSystemEnglish[Y],27));
    Else Write(' ',PadRight(SubMenuSystem[Y],27));
   End;
  End;
  2:Begin
   Case Language of
    _English: GotoXY(13,3+Y);
    Else GotoXY(14,3+Y);
   End;
   If SubMenuDisks[Y]=''Then Write(DuplicateString('-',30+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuDisksEnglish[Y],30));
    Else Write(' ',PadRight(SubMenuDisks[Y],30));
   End;
  End;
  3:Begin
   Case Language of
    _English:GotoXY(20,3+Y);
    Else GotoXY(22,3+Y);
   End;
   If SubMenuMemory[Y]=''Then Write(DuplicateString('-',31+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuMemoryEnglish[Y],31));
    Else Write(' ',PadRight(SubMenuMemory[Y],31));
   End;
  End;
  4:Begin
   Case Language of
    _English:GotoXY(28,3+Y);
    Else GotoXY(31,3+Y);
   End;
   If SubMenuBenchmarks[Y]=''Then Write(DuplicateString('-',36+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuBenchmarksEnglish[Y],36));
    Else Write(' ',PadRight(SubMenuBenchmarks[Y],36));
   End;
  End;
  5:Begin
   Case Language of
    _English:GotoXY(40,3+Y);
    Else GotoXY(44,3+Y);
   End;
   If SubMenuReport[Y]=''Then Write(DuplicateString('-',25+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuReportEnglish[Y],25));
    Else Write(' ',PadRight(SubMenuReport[Y],25));
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
   FrameEmpty(4,2,33,4+High(SubMenuSystem),$F0);
   For I:=Low(SubMenuSystem)to High(SubMenuSystem)do Begin
    SubMenuItem(I,False);
   End;
  End;
  2:Begin
   Case Language of
    _English:FrameEmpty(12,2,44,4+High(SubMenuDisks),$F0);
    Else FrameEmpty(13,2,45,4+High(SubMenuDisks),$F0);
   End;
   For I:=Low(SubMenuDisks)to High(SubMenuDisks)do Begin
    SubMenuItem(I,False);
   End;
  End;
  3:Begin
   Case Language of
    _English:FrameEmpty(19,2,52,4+High(SubMenuMemory),$F0);
    Else FrameEmpty(21,2,54,4+High(SubMenuMemory),$F0);
   End;
   For I:=Low(SubMenuMemory)to High(SubMenuMemory)do Begin
    SubMenuItem(I,False);
   End;
  End;
  4:Begin
   Case Language of
    _English:FrameEmpty(27,2,65,4+High(SubMenuBenchmarks),$F0);
    Else FrameEmpty(30,2,68,4+High(SubMenuBenchmarks),$F0);
   End;
   For I:=Low(SubMenuBenchmarks)to High(SubMenuBenchmarks)do Begin
    SubMenuItem(I,False);
   End;
  End;
  5:Begin
   Case Language of
    _English:FrameEmpty(39,2,66,4+High(SubMenuReport),$F0);
    Else FrameEmpty(43,2,70,4+High(SubMenuReport),$F0);
   End;
   For I:=Low(SubMenuReport)to High(SubMenuReport)do Begin
    SubMenuItem(I,False);
   End;
  End;
 End;
End;

Procedure HideSubMenu;Begin
 ShowHome;
 ShowStatusBar;
 ShowMenu;
End;

Procedure NotImplemented;Begin
 Box(5,11,75,13,$60);
 FrameEmpty(5,11,75,13,$60);
 GotoXY(20,12);
 Write('Cette fonctionnalit‚ n''est pas impl‚ment‚');
 ReadKey;
 HideSubMenu;
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

Procedure ShowSystemSummary;
Var
 OldWindMax:Word;
 Regs:Registers;
 Used:Integer;
 TotalSize,TotalUsed,TotalFree:LongInt;
Begin
 OldWindMax:=WindMax;
 Case Language of
  _English:BoxInfo(5,3,75,22,'System Summary');
  Else BoxInfo(5,3,75,22,'Sommaire systŠme');
 End;
 Window(6,4,74,21);
 GotoXY(1,1);
 WriteLn;
 Case Language of
  _English:Write('Copyright Notice:':24);
  Else Write('Avertissement l‚gal:':30);
 End;
 WriteLn(' ','Unknown');
 Case Language of
  _English:Write('Built-in BIOS:':24);
  Else Write('BIOS int‚gr‚:':30);
 End;
 WriteLn(' ',DateBIOS);
 Case Language of
  _English:Write('Main Processor:':24,' ');
  Else Write('Microprocesseur:':30,' ');
 End;
 Case Test8086 of
  0:WriteLn('8086');
  1:WriteLn('80286');
  2:WriteLn('80386 ou sup‚rieur');
  Else WriteLn('Unknown');
 End;
 Case Language of
  _English:Write('Math Co-Processor:':24,' ');
  Else Write('Coprocesseur math‚matique:':30,' ');
 End;
 Case Test8087 of
  0:WriteLn('Absent');
  1:WriteLn('8087');
  2:WriteLn('80287');
  3:WriteLn('80387');
  Else WriteLn('Unknown');
 End;
 Case Language of
  _English:Write('Video Adapter:':24);
  Else Write('Adaptateur vid‚o:':30);
 End;
 Regs.AX:=$1A00;
 Intr($10,Regs);
 If Regs.AL=$1A Then Begin
  Case Regs.BL of
   $01:WriteLn('Monochrome Display Adapter (MDA)');
   $02:WriteLn('Color Graphics Adapter (CGA)');
   $04,$05:WriteLn('Enhanced Graphics Adapter (EGA)');
   $06:WriteLn('Professional Graphic Controller (PGA)');
   $07,$08:WriteLn('Video Graphics Array (VGA)');
   $0A,$0B,$0C:WriteLn('Multi-Color Graphics Array (MCGA)');
   Else WriteLn('Inconnu');
  End;
 End
  Else
 Begin
  Regs.AH:=$12;
  Regs.BL:=$10;
  Intr($10,Regs);
  If Regs.BL<>$10 Then Write('EGA')
                  Else WriteLn(' ','Inconnu');
 End;
 Case Language of
  _English:Write('Mouse Type:':24);
  Else Write('Type de souris:':30);
 End;
 WriteLn(' ','Unknown');
 WriteLn;
 WriteLn;
 Case Language of
  _English:Write('Hard disks:':16);
  Else Write('Disques dur:':21);
 End;
 If DiskSize(3)<>-1 Then Begin
  WriteLn(' ',DiskSize(3)div 1024 div 1024,'M');
 End
  Else
 WriteLn('Aucun');
 Case Language of
  _English:Write('Floppy disks:':16);
  Else Write('Unit‚ de disquette:':21);
 End;
 WriteLn(' ','Unknown');
 WriteLn;
 WriteLn;
 WriteLn('DOS Memory:':20,' ',GetConvMemory:5,' Ko');
 Write('Extended Memory:':20,' ');
 If(XMSInit)Then Begin
  Used:=XMSUsed;
  WriteLn(Used+XMSFree:5,' Ko');
 End
  Else
 WriteLn(0:5,' Ko');
 WriteLn('Expanded Memory:':20,' ','Unknown');
 WriteLn;
 Write(' ':30);
 TextColor(Black);
 TextBackground(7);
 Write('   OK   ');
 TextColor(White+BLINK);
 TextBackground(9);
 Window(41,13,72,19);
 Case Language of
  _English:Write('Bus Type:':23,' ');
  Else Write('Type de bus:':23,' ');
 End;
 WriteLn('Unknown');
 Case Language of
  _English:Write('Serial Ports:':23,' ');
  Else Write('Ports s‚rie:':23,' ');
 End;
 WriteLn(GetNumSerialPort);
 Case Language of
  _English:Write('Parallel Ports:':23,' ');
  Else Write('Ports parallŠle:':23,' ');
 End;
 WriteLn(GetNumParallelPort);
 Case Language of
  _English:Write('Keyboard Type:':23,' ');
  Else Write('Type de clavier:':23,' ');
 End;
 WriteLn('Unknown');
 Case Language of
  _English:Write('Operating System:':23,' ');
  Else Write('SystŠme d''exploitation:':23,' ');
 End;
 WriteLn('DOS ',Lo(DOSVersion),'.',Hi(DOSVersion));
 Window(1,1,80,25);
 FrameEmpty(7,4,73,11,$9F);
 FrameEmpty(7,12,39,15,$9F);
 FrameEmpty(7,16,39,20,$9F);
 FrameEmpty(40,12,73,20,$9F);
End;

Procedure Init;
Var
 Regs:Registers;
Begin
 CursorOff;
  { D‚sactive le clignotement }
 Regs.AX:=$1003;
 Regs.BL:=$0;
 Intr($10,Regs);
 ShowHome;
 ShowStatusBar;
 ShowMenu;
End;

Procedure Run;
Var
 Terminated:Boolean;
 K:Char;
Begin
 ShowSystemSummary;
 Terminated:=False;
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
      1:If YMenu in[2,5]Then Dec(YMenu);
      3:If YMenu in[3]Then Dec(YMenu);
      5:If YMenu in[2]Then Dec(YMenu);
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
      1:If YMenu in[2,5]Then Inc(YMenu);
      3:If YMenu in[3]Then Inc(YMenu);
      5:If YMenu in[2]Then Inc(YMenu);
     End;
     SubMenuItem(YMenu,False);
    End;
   End;
   #13:Begin
    OnMenu:=False;
    HideSubMenu;
    Case XMenu of
     1:Case YMenu of
      0:ShowSystemSummary;
      Else NotImplemented;
     End;
     6:Terminated:=True;
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
    #16:Terminated:=True; { Alt+Q }
    #19:Begin { Alt+R }
     XMenu:=5;YMenu:=0;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #25:Begin { Alt+P }
     XMenu:=4;YMenu:=0;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #31:Begin { Alt+S }
     XMenu:=1;YMenu:=0;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #32:Begin { Alt+D }
     XMenu:=2;YMenu:=0;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #48:Begin { Alt+B }
     XMenu:=4;YMenu:=0;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #50:Begin { Alt+M }
     XMenu:=3;YMenu:=0;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
   End;
   #27:Terminated:=True; { Esc }
  End;
 Until Terminated;
End;

Procedure Done;Begin
 TextColor(7);
 TextBackground(0);
 ClrScr;
 CursorOn;
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
    WriteLn('Provides details technical information about your computer.');
    WriteLn;
    WriteLn('SYSINFO [/ASCII128]')
   End;
   Else Begin
    WriteLn('SYSINFO : Cette commande permet de fournir des informations ',
            'techniques … propos de votre ordinateur');
    WriteLn;
    WriteLn('Syntaxe : SYSINFO [/ASCII128]');
    WriteLn;
    WriteLn(' /ASCII128   Ce parametre permet de lancer en mode compatibilite 128 caracteres seulement.');
   End;
  End;
 End
  Else
 Begin
  Init;
  Run;
  Done;
 End;
END.
