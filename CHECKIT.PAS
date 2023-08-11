{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program CHECKIT;

Uses Crt,DOS;

Const
 MainMenu:Array[0..5]of String[12]=(
  'Aide','Rapport','Test','Performance','Autre','Ajustement'
 );

 SubMenuHelp:Array[0..1]of String[30]=(
  'Testage et rapports','Resultats de performance'
 );

 SubMenuRapport:Array[0..1]of String[30]=(
  'Materiel installe','Association d''interruption'
 );

 SubMenuTest:Array[0..2]of String[30]=(
  'Test de manette de jeux','Test de souris',
  'Diagnostics avance'
 );

 SubMenuPerformance:Array[0..1]of String[20]=(
  'Performance disque','Performance systeme'
 );

 SubMenuOther:Array[0..2]of String[40]=(
  'Mauvaise emplacement de puce memoire',
  'Date et heure CMOS',
  'Disque dur bas niveau'
 );

 SubMenuSetup:Array[0..1]of String[25]=(
  'Bascule de couleur','Selectionne le moniteur'
 );

 YMenuMax:Array[1..6]of Byte=(
  High(SubMenuHelp),High(SubMenuRapport),High(SubMenuTest),
  High(SubMenuPerformance),High(SubMenuOther),
  High(SubMenuSetup)
 );

Var
 ShowASCII128:Boolean;
 I:Integer;
 YMenu,XMenu:Integer;

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
 If Regs.AX=0 Then GetConvMemory:=640
              Else GetConvMemory:=Regs.AX;
End;

Function GetEquip:Word;
Var
 Regs:Registers;
Begin
 Regs.AX:=0;
 Intr($11,Regs);
 GetEquip:=Regs.AX;
End;

Function GetVideoCard:Word;
Var
 Regs:Registers;
Begin
 Regs.AX:=$1A00;
 Intr($10,Regs);
 If Regs.AL=$1AThen GetVideoCard:=Regs.BX
               Else GetVideoCard:=0;
End;

Function MonochromePresent:Byte;Begin
 MonochromePresent:=0;
 If((GetVideoCard and $FF)in[$01,$07,$0B])or
   ((GetVideoCard shr 8)in[$01,$07,$0B])Then MonochromePresent:=1
End;

Function EnhancedGraphicsAdapterPresent:Byte;Begin
 EnhancedGraphicsAdapterPresent:=0;
 If((GetVideoCard and $FF)in[$04,$05,$06,$08,$0A,$0C])or
   ((GetVideoCard shr 8)in[$04,$05,$06,$08,$0A,$0C])Then EnhancedGraphicsAdapterPresent:=1
End;

Function GetNumFloppyDisk:Word;Begin
 GetNumFloppyDisk:=(GetEquip shr 6)and 3;
End;

Function GetNumParallelPort:Word;Begin
 GetNumParallelPort:=(GetEquip shr 14)and 3;
End;

Function GetNumSerialPort:Word;Begin
 GetNumSerialPort:=(GetEquip shr 9) and 3;
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

Procedure SetColorSelect;Begin
 TextColor(1);
 TextBackground(6);
End;

Procedure SetColorUnSelect;Begin
 TextColor(14);
 TextBackground(1);
End;

Procedure UpdateMenu;
Var
 I:Integer;
Begin
 GotoXY(5,4);
 For I:=Low(MainMenu) to High(MainMenu)do Begin
   If I+1=XMenu Then SetColorSelect
                Else SetColorUnSelect;
  If I=Low(MainMenu)Then Write(' ':2)
                    Else Write(' ':3);
  Write(MainMenu[I]);
  Write(' ':2);
 End;
End;

Procedure ShowMenu;
Begin
 FrameEmpty(4,3,76,5,$1E);
 UpdateMenu;
End;

Procedure SubMenuItem(Y:Integer;Disable:Boolean);Begin
 If(Disable)Then SetColorUnSelect Else
 If Y=YMenu Then SetColorSelect
            Else SetColorUnSelect;
 Case XMenu of
  1:Begin
   GotoXY(6,6+Y);
   Write(' ',PadRight(SubMenuHelp[Y],25));
  End;
  2:Begin
   GotoXY(13,6+Y);
   Write(' ',PadRight(SubMenuRapport[Y],28));
  End;
  3:Begin
   GotoXY(25,6+Y);
   Write(' ',PadRight(SubMenuTest[Y],24));
  End;
  4:Begin
   GotoXY(34,6+Y);
   Write(' ',PadRight(SubMenuPerformance[Y],20));
  End;
  5:Begin
   GotoXY(37,6+Y);
   Write(' ',PadRight(SubMenuOther[Y],37));
  End;
  6:Begin
   GotoXY(50,6+Y);
   Write(' ',PadRight(SubMenuSetup[Y],24));
  End;
 End;
End;

Procedure ShowSubMenu;
Var
 I:Integer;
Begin
 Case XMenu of
  1:Begin
   FrameEmpty(5,5,32,7+High(SubMenuHelp),$1E);
   For I:=Low(SubMenuHelp)to High(SubMenuHelp)do Begin
    SubMenuItem(I,False);
   End;
  End;
  2:Begin
   FrameEmpty(12,5,42,7+High(SubMenuRapport),$1E);
   For I:=Low(SubMenuRapport)to High(SubMenuRapport)do Begin
    SubMenuItem(I,False);
   End;
  End;
  3:Begin
   FrameEmpty(24,5,50,7+High(SubMenuTest),$1E);
   For I:=Low(SubMenuTest)to High(SubMenuTest)do Begin
    SubMenuItem(I,False);
   End;
  End;
  4:Begin
   FrameEmpty(33,5,55,7+High(SubMenuPerformance),$1E);
   For I:=Low(SubMenuPerformance)to High(SubMenuPerformance)do Begin
    SubMenuItem(I,False);
   End;
  End;
  5:Begin
   FrameEmpty(36,5,75,7+High(SubMenuOther),$1E);
   For I:=Low(SubMenuOther)to High(SubMenuOther)do Begin
    SubMenuItem(I,False);
   End;
  End;
  6:Begin
   FrameEmpty(49,5,75,7+High(SubMenuSetup),$1E);
   For I:=Low(SubMenuSetup)to High(SubMenuSetup)do Begin
    SubMenuItem(I,False);
   End;
  End;
 End;
End;

Procedure HideSubMenu;Begin
 Box(4,6,76,16,$16);
End;

Procedure Init;Begin
 ClrScr;
 CursorOff;
 Box(1,1,80,25,$16);
 FrameEmpty(1,1,80,24,$16);
 GotoXY(20,1);
 Write(' CheckIt Control Panel Clone de gladir.com ');
 GotoXY(2,17);
 Write(DuplicateString('-',78));
 GotoXY(2,21);
 Write(DuplicateString('-',78));
 GotoXY(10,22);
 Write('- Utilise les touches de fleches pour pointer - ');
 GotoXY(10,23);
 Write('- ENTER pour selectionner - ESC annnule -');
 ShowMenu;
End;

Procedure NotImplemented;Begin
 Box(5,11,75,13,$60);
 FrameEmpty(5,11,75,13,$60);
 GotoXY(20,12);
 Write('Cette fonctionnalite n''est pas implemented');
 ReadKey;
 Init;
 ShowSubMenu;
End;

Procedure InstalledHardware;Begin
 FrameEmpty(7,4,73,23,$1E);
 Box(8,5,72,22,$70);
 GotoXY(25,5);
 Write('Configuration materiel systeme');
 GotoXY(11,7);
 Write(PadRight('Type de processeur :',25));
 TextColor(1);
 Case Test8086 of
  0:WriteLn('8086');
  1:WriteLn('Machine AT 80286');
  2:WriteLn('Machine AT 80386');
  Else WriteLn('Inconnu (',Test8086,')');
 End;
 TextColor(0);
 GotoXY(11,8);
 Write(PadRight('Coprocesseur numerique :',25));
 TextColor(1);
 If Test8087>0Then Write('80287')
              Else Write('Aucun');
 TextColor(0);
 GotoXY(11,9);
 Write(PadRight('Memoire de base :',25));
 TextColor(1);
 Write(GetConvMemory);
 TextColor(0);
 GotoXY(11,10);
 Write(PadRight('Taille EMS :',25));
 TextColor(1);
 Write(0);
 TextColor(0);
 GotoXY(11,11);
 Write(PadRight('Taille XMS :',25));
 TextColor(1);
 Write(0);
 TextColor(0);
 GotoXY(11,12);
 Write(PadRight('Adapteur video :',25));
 TextColor(1);
 Write('VGA');
 TextColor(0);
 GotoXY(11,13);
 Write(PadRight('Mode video :',25));
 TextColor(1);
 Write('Couleur 80x25');
 TextColor(0);
 GotoXY(11,14);
 Write(PadRight('Taille de la RAM Video :',25));
 TextColor(1);
 Write(256);
 TextColor(0);
 GotoXY(11,15);
 Write(PadRight('Unite de disque dur :',25));
 TextColor(1);
 Write(1);
 TextColor(0);
 GotoXY(11,16);
 Write(PadRight('Unite de disquette :',25));
 TextColor(1);
 Write(GetNumFloppyDisk);
 TextColor(0);
 GotoXY(11,17);
 Write(PadRight('Horloge/Calendrier :',25));
 TextColor(1);
 Write('Present');
 TextColor(0);
 GotoXY(11,18);
 Write(PadRight('Ports parallele :',25));
 TextColor(1);
 Write(GetNumParallelPort);
 TextColor(0);
 GotoXY(11,19);
 Write(PadRight('Ports serie :',25));
 TextColor(1);
 Write(GetNumSerialPort);
 TextColor(0);
 GotoXY(11,20);
 Write(PadRight('Ports de jeux :',25));
 TextColor(1);
 Write('Absente');
 TextColor(0);
 GotoXY(11,21);
 Write(PadRight('Souris :',25));
 TextColor(1);
 Write('Absente');
 GotoXY(35,22);
 TextColor(14);
 Write('ESC-Quitte');
 ReadKey;
 Init;
 ShowSubMenu;
End;

Procedure Run;
Var
 K:Char;
Begin
 ShowSubMenu;
 Repeat
  K:=ReadKey;
  Case K of
   #0:Begin
    K:=ReadKey;
    Case K of
     #72:Begin { Up }
      SubMenuItem(YMenu,True);
      If YMenu>0Then Dec(YMenu)
                Else YMenu:=YMenuMax[XMenu];
      SubMenuItem(YMenu,False);
     End;
     #75:Begin { Left }
      HideSubMenu;
      If XMenu=Low(MainMenu)+1Then XMenu:=High(MainMenu)+1
                              Else Dec(XMenu);
      YMenu:=0;
      UpdateMenu;
      ShowSubMenu;
     End;
     #77:Begin { Right }
      HideSubMenu;
      If XMenu=High(MainMenu)+1Then XMenu:=Low(MainMenu)+1
                               Else Inc(XMenu);
      YMenu:=0;
      UpdateMenu;
      ShowSubMenu;
     End;
     #80:Begin { Down }
      SubMenuItem(YMenu,True);
      If YMenu<YMenuMax[XMenu]Then Inc(YMenu)
                              Else YMenu:=0;
      SubMenuItem(YMenu,False);
     End;
    End;
   End;
   #13:Begin
    Case XMenu of
     2:Case YMenu of
      0:InstalledHardware;
      Else NotImplemented;
     End;
     Else NotImplemented;
    End;
   End;
  End;
 Until K=#27;
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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('CHECKIT : Cette commande permet de lancer le menu CheckIt Control Panel.');
  WriteLn;
  WriteLn('Syntaxe : CHECKIT [/ASCII128]');
  WriteLn;
  WriteLn(' /ASCII128   Ce parametre permet de lancer en mode compatibilite 128 caracteres seulement.');
 End
  Else
 Begin
  YMenu:=0;XMenu:=2;
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
