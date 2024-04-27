{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program NorthCommander;

{$M 16384,0,65556}

Uses Crt,Dos;

Const
 Version='1.0.8';
 MinCote=0;
 MaxCote=1;
 MaxFiles={$IFDEF FPC}4095{$ELSE}511{$ENDIF};
 MaxHistory=100;

 kbNoKey=0;{Pas de touche}
 kbDn=$5000;{Fleche Bas}
 kbEnter=$1C0D;{Enter}
 kbEsc=$011B;{Escape}
 kbShiftTab=$0F00;{Shift+Tabulation}
 kbTab=$0F09;{Tabulation}
 kbUp=$4800;{Fleche Haut}

 PanelInfo=2;
 PanelFile=4;
 PanelHeightSize=17;
 LengthMenu:Array[0..4] of Byte = (9,16,26,30,9);
 HeightMenu:Array[0..4] of Byte = (15,13,4,12,15);
 MainMenuChoice:Array[0..4]of String[9]=('Gauche','Fichiers','Disque','Commandes','Droite');
 MenuLeft:Array[0..15] of String[9]=(
  'Arbre',
  'Bref',
  'Info',
  'Link',
  'Plein',
  'Regard',
  'Ouvert',
  'Fermer',
  'Nom',
  'Extension',
  'Heure',
  'Taille',
  'Desorde',
  'Relire',
  'Filtre',
  'Disque'
 );

 MenuFiles:Array[0..13] of String[16]=(
  'Aide',
  'Menu utilisateur',
  'Afficher',
  'Editer',
  'Copier',
  'Renommer/dÇplacer',
  'CrÇe un rÇpertoire',
  'Supprimer',
  'Attribut de fichiers',
  'SÇlectionner un groupe',
  'DesÇlectionner un groupe',
  'Inverser la sÇlection',
  'Restaurer la sÇlection',
  'Quitter'
  );

  MenuDisk:Array[0..4]of String[30]=(
   'Copier une disquette...',
   'Formater une disquette...',
   'Nommer un disque',
   'Utilitaire rÇseau...',
   'Nettoyage disque...'
  );

  MenuCommands:Array[0..12] of String[26]=(
   'Arbre NCD',
   'Recherche de fichiers',
   'Historique',
   'Ligne EGA',
   'Permuter les panneaux',
   'Afficher/effacer les panneaux',
   'Compare les rÇpertoires',
   'Synchroniser les rÇpertoires',
   'Emulation de terminal',
   'Editer le fichier menu...',
   'Editer le fichier extension...',
   'Editeurs...',
   'Configuration...'
  );

  SideLength:Array[0..1] of Byte=(PanelHeightSize,PanelHeightSize);
  HexData:Array[0..15] of Char='0123456789ABCDEF';

Const
 RAMSize=640;

Type
 String2=String[2];
 String4=String[4];
 String12=String[12];
 String64=String[64];
 Binaire=0..1;
 StrName=String[12];
 StrPointer=^String;

Var
 Language:(_Albanian,_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 EGAMode,DoubleFrame:Boolean;
 MaxScreenLine:Byte;
 I:Integer;
 ShowASCII128:Boolean;
 CurrDialog:Byte;
 Nombre:Array[0..1] of 0..MaxFiles;
 PositionX:Array[0..1] of 0..MaxFiles;
 YPos:Array[0..1] of Byte;
 PanelPath:Array[0..1] of PathStr;
 PanelType:Array[0..1] of 0..7;
 PanelDisable:Array[0..1]of Boolean;
 PathTem:PathStr;
 Tem:String[4];
 PositionCur:0..79;
 XP,YP,Xa,Ya,PosMenu,Cote,Vg,Menu:Byte;
 PositionBar:Byte;
 Terminated:Boolean;
 KeyBar:Boolean;
 CurrCommand:PathStr;
 Date_Time:DateTime;
 ChaineTemporaire:String[64];
 Numerique:Word;
 XS,YS:Word;
 BS:Word;
 History:Array[1..MaxHistory] of StrPointer;
 NumberHistory,CurrHistory:Integer;
 Nom:Array[MinCote..MaxCote,0..MaxFiles] of StrName;
 Temps:Array[MinCote..MaxCote,0..MaxFiles] of LongInt;
 Taille:Array[MinCote..MaxCote,0..MaxFiles] of LongInt;
 Attribt:Array[MinCote..MaxCote,0..MaxFiles] of Byte;
 Accepte:Array[MinCote..MaxCote,0..MaxFiles] of 0..1;
 NombreFichierX:Array[MinCote..MaxCote] of 0..MaxFiles;
 TypeTri:Array[MinCote..MaxCote] of 0..4;

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

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
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

Function Replace(Source,Old,New:String):String;
Var
 P:LongInt;
Begin
 While Pos(Old,Source)<>0 do Begin
  P:=Pos(Old,Source);
  Delete(Source,P,Length(Old));
  Insert(New,Source,P);
 End;
 Replace:=Source;
End;

Function RTrim(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 RTrim:=S;
End;

Function LTrim(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If S[I]<>' 'Then Begin
   LTrim:=Copy(S,I,255);
   Exit;
  End;
 End;
 LTrim:=S;
End;

Function Trim(S:String):String;Begin
 Trim:=LTrim(RTrim(S));
End;

Function Path2Name(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2Name:=N;
End;

Function Path2Ext(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2Ext:=E;
End;

Function SplitFileName(s:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Splitfilename:=N+E;
End;

Function FileExist(Name:String):Boolean;
Var
 Rec:SearchRec;
Begin
 FindFirst(Name,AnyFile,Rec);
 FileExist:=DosError=0;
End;

Function DeleteFile(FileName:String):Integer;
Var
 F:File;
Begin
 {$I-}Assign(F,FileName);
 Erase(F);
 {$I+}
 DeleteFile:=IoResult;
End;

Function GetCurrPath:String;Begin
 GetCurrPath:=PanelPath[Cote];
End;

Function GetCurrName:String;
Var
 PathTem:String;
Begin
 PathTem:=PanelPath[Cote];
 If PathTem[Length(PathTem)]<>'\'Then PathTem:=PanelPath[Cote]+'\';
 GetCurrName:=PathTem+Trim(Path2Name(Nom[Cote,PositionX[Cote]+1])) +
                      Path2Ext(Nom[Cote,PositionX[Cote]+1]);
End;

Function GetCurrFileName:String;Begin
 GetCurrFileName:=Trim(Path2Name(Nom[Cote,PositionX[Cote]+1])) +
                  Path2Ext(Nom[Cote,PositionX[Cote]+1]);
End;

Function GetCurrExt:String;Begin
 GetCurrExt:=Path2Ext(Nom[Cote,PositionX[Cote]+1]);
End;

Function AddHistory(S:String):Boolean;
Var
 I:Word;
 P:StrPointer;
Begin
 If NumberHistory>=MaxHistory Then Begin
  FreeMem(History[1],Length(History[1]^)+1);
  For I:=1 to MaxHistory-1 do History[I]:=History[I+1];
  GetMem(P,Length(S)+1);
  P^:=S;
  History[MaxHistory]:=P;
  AddHistory:=True;
  Exit;
 End
  Else
 Begin
  Inc(NumberHistory);
  GetMem(P,Length(S)+1);
  P^:=S;
  History[NumberHistory]:=P;
  AddHistory:=True;
 End;
End;

Procedure FreeHistory;
Var
 I:Word;
Begin
 For I:=1 to NumberHistory do FreeMem(History[I],Length(History[I]^)+1);
 FillChar(History,SizeOf(History),0);
 NumberHistory:=0;
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
 Window(1,1,80,MaxScreenLine);
End;

Procedure Write1(X,Y,Caractere,Couleur:Byte);Begin
 GotoXY(X,Y);
 TextBackground((Couleur shr 4)and 15);
 TextColor(Couleur and 15);
 Write(Char(Caractere));
End;

Procedure WriteXY(X,Y:Byte;Phrase:String;Couleur:Byte);Begin
 TextBackground((Couleur shr 4)and 15);
 TextColor(Couleur and 15);
 GotoXY(X,Y);
 Write(Phrase);
End;

Procedure WriteChoice(X,Y:Byte;Phrase:String;Couleur1,Couleur2:Byte);Begin
 Write1(X,Y,Ord(Phrase[1]),Couleur1);
 WriteXY(X+1,Y,Copy(Phrase,2,255),Couleur2);
End;

Procedure WriteCenter(Y:Byte;Phrase:String;Couleur:Byte);Begin
 WriteXY(40-Length(Phrase) div 2,Y,Phrase,Couleur);
End;

Procedure FrameEmpty(X1,Y1,X2,Y2,Couleur:Byte);
Var
 Compteur:Byte;
 ChrHori,ChrVert:Char;
 Chr218,Chr192,Chr191,Chr217:Char;
Begin
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
 For Compteur:=Y1+1 to Y2-1 do Begin
  Write1(X1,Compteur,Ord(ChrVert),Couleur);
  Write1(X2,Compteur,Ord(ChrVert),Couleur);
 End;
 WriteXY(X1+1,Y1,DuplicateString(ChrHori,X2-X1-1),Couleur);
 WriteXY(X1+1,Y2,DuplicateString(ChrHori,X2-X1-1),Couleur);
 Write1(X1,Y1,Ord(Chr218),Couleur);
 Write1(X1,Y2,Ord(Chr192),Couleur);
 Write1(X2,Y1,Ord(Chr191),Couleur);
 Write1(X2,Y2,Ord(Chr217),Couleur);
End;

Procedure DialogBox(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Box(X1,Y1,X2,Y2,Couleur);
 FrameEmpty(X1,Y1,X2,Y2,Couleur);
 TextAttr:=Couleur;
End;

Procedure FrameFull(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Box(X1,Y1,X2,Y2,Couleur);
 FrameEmpty(X1+2,Y1+1,X2-2,Y2-1,Couleur);
End;

Procedure MoveWindow(X1,Y1,X2,Y2,Couleur:Byte;Direction:Integer);Begin
 Window(X1,Y1,X2,Y2);
 If Direction<0Then Begin
  GotoXY(1,1);
  DelLine;
 End
  Else
 Begin
  GotoXY(1,1);
  InsLine;
 End;
 Window(1,1,80,MaxScreenLine);
End;

Procedure FrameChoice(X1,Y1,X2,Y2:Byte);
Var
 I:Integer;
 ChrHori,ChrVert:Byte;
 Chr218,Chr192,Chr191,Chr217:Byte;
Begin
 If(ShowASCII128)Then Begin
  ChrHori:=Byte('-');
  ChrVert:=Byte('|');
  Chr218:=Byte('+');
  Chr192:=Byte('+');
  Chr191:=Byte('+');
  Chr217:=Byte('+');
 End
  Else
 Begin
  ChrHori:=$C4;
  ChrVert:=$B3;
  Chr218:=218;
  Chr192:=192;
  Chr191:=191;
  Chr217:=217;
 End;
 Box(X1,Y1,X2,Y2,63);
 Write1(X1,Y1,Chr218,63);
 Write1(X2,Y1,Chr191,63);
 Write1(X1,Y2,Chr192,63);
 Write1(X2,Y2,Chr217,63);
 For I:=X1+1 to X2-1 do Begin
  Write1(I,Y1,ChrHori,63);
  Write1(I,Y2,ChrHori,63);
 End;
 For I:=Y1+1 to Y2-1 do Begin
  Write1(X1,I,ChrVert,63);
  Write1(X2,I,ChrVert,63);
 End;
End;

Function ReadLine(Var S:String):Word;
Var
 Rec:SearchRec;
 K:Char;
 X,Y,I:Byte;
 CurrHistory:Integer;
Begin
 ReadLine:=0;
 X:=WhereX;
 Y:=WhereY;
 Repeat
  GotoXY(X,Y);
  Write(S);
  ClrEol;
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #72:Begin
     ReadLine:=kbUp;
     Exit;
    End;
    #80:Begin
     ReadLine:=kbDn;
     Exit;
    End;
   End;
   #8:Begin
    If S<>''Then S:=Copy(S,1,Length(S)-1);
   End;
   #9:Begin
    ReadLine:=kbTab;
    Exit;
   End;
   #13:Begin
    ReadLine:=kbEnter;
   End;
   #27:Begin
    ReadLine:=kbEsc;
    Exit;
   End;
   Else S:=S+K;
  End;
  If S[Length(S)]=#13Then Begin
   S:=Copy(S,1,Length(S)-1);
   K:=#13;
  End;
 Until K=#13;
 GotoXY(X,Y);
 WriteLn(S);
End;

Function ReadLineInBox(X1,Y1,X2,Y2:Byte;Var S:String):Word;Begin
 Window(X1,Y1,X2,Y2);
 ReadLineInBox:=ReadLine(S);
 Window(1,1,80,MaxScreenLine);
End;

Procedure SetDialogTextColor;Begin
 TextBackground(CurrDialog shr 4);
 TextColor(CurrDialog and$F);
End;

Procedure SetButtonColor;Begin
 TextBackground(7);
 TextColor(0);
End;

Procedure SetSelectedButtonColor;Begin
 TextBackground(Cyan);
 TextColor(0);
End;

Procedure ShowButton(ButtonList:String;PosButton:Byte);
Var
 I,CurrPosButton:Integer;
 First:Boolean;
 CurrButton:String;
Begin
 CurrButton:='';
 First:=True;
 CurrPosButton:=0;
 For I:=1 to Length(ButtonList)do Begin
  If ButtonList[I]='|'Then Begin
   SetDialogTextColor;
   If Not(First)Then Write(' ');
   If(PosButton=CurrPosButton)Then SetSelectedButtonColor
                              Else SetButtonColor;
   Write(' ',CurrButton,' ');
   SetDialogTextColor;
   CurrButton:='';
   First:=False;
   Inc(CurrPosButton);
  End
   Else
  CurrButton:=CurrButton+ButtonList[I];
 End;
 If Not(First)Then Write(' ');
 If(PosButton=CurrPosButton)Then SetSelectedButtonColor
                            Else SetButtonColor;
 Write(' ',CurrButton,' ');
End;

Function LengthButton(ButtonList:String):Integer;
Var
 I,CurrPosButton,LenButton:Integer;
 First:Boolean;
 CurrButton:String;
Begin
 LengthButton:=0;
 LenButton:=0;
 CurrButton:='';
 First:=True;
 CurrPosButton:=0;
 For I:=1 to Length(ButtonList)do Begin
  If ButtonList[I]='|'Then Begin
   If Not(First)Then Inc(LenButton,Length(' '));
   Inc(LenButton,Length(' '+CurrButton+' '));
   CurrButton:='';
   First:=False;
   Inc(CurrPosButton);
  End
   Else
  CurrButton:=CurrButton+ButtonList[I];
 End;
 If Not(First)Then Inc(LenButton,Length(' '));
 Inc(LenButton,Length(' '+CurrButton+' '));
 LengthButton:=LenButton;
End;

Function ReadHorizontalButton(ButtonList:String):Word;
Var
 X,Y:Byte;
 K:Char;
 I,NumButton,CurrButton:Integer;
Begin
 CurrDialog:=TextAttr;
 CursorOff;
 ReadHorizontalButton:=kbEsc;
 CurrButton:=0;
 NumButton:=1;
 X:=WhereX;
 Y:=WhereY;
 For I:=1 to Length(ButtonList)do If ButtonList[I]='|'Then Inc(NumButton);
 ShowButton(ButtonList,0);
 Repeat
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #15:Begin { Shift+Tab }
     If(CurrButton>0)Then Begin
      Dec(CurrButton);
      GotoXY(X,Y);
      ShowButton(ButtonList,CurrButton);
     End
      Else
     Begin
      ReadHorizontalButton:=kbShiftTab;
      Break;
     End;
    End;
    #75:Begin { Gauche }
     If(CurrButton>0)Then Dec(CurrButton)
                     Else CurrButton:=NumButton-1;
     GotoXY(X,Y);
     ShowButton(ButtonList,CurrButton);
    End;
    #77:Begin { Droite }
     If(CurrButton+1>=NumButton)Then CurrButton:=0
                                Else Inc(CurrButton);
     GotoXY(X,Y);
     ShowButton(ButtonList,CurrButton);
    End;
   End;
   #9:Begin
    If(CurrButton+1>=NumButton)Then Begin
     ReadHorizontalButton:=kbTab;
     Break;
    End
     Else
    Begin
     Inc(CurrButton);
     GotoXY(X,Y);
     ShowButton(ButtonList,CurrButton);
    End;
   End;
   #13:ReadHorizontalButton:=CurrButton;
   #27:ReadHorizontalButton:=kbEsc;
  End;
 Until K in[#13,#27];
 SetDialogTextColor;
 CursorOn;
End;

Function ReadHorizontalCenterButton(Y:Byte;S:String):Word;Begin
 GotoXY((80-LengthButton(S)) shr 1,Y);
 ReadHorizontalCenterButton:=ReadHorizontalButton(S);
End;

Procedure ShowHorizontalCenterButton(Y:Byte;S:String);Begin
 GotoXY((80-LengthButton(S)) shr 1,Y);
 ShowButton(S,$FF);
End;

Procedure DiskNotReady(Disque:Byte);
Var
 Registre:Registers;
 OK:Boolean;
 Touche:Char;
Begin
 OK := False;
 Repeat
  Box(12,12,69,13,$4F);
  FrameEmpty(11,11,70,14,$4F);
  WriteCenter(12,'Disque '+Chr(Disque+65)+' pas pràt',$4F);
  WriteCenter(13,'Mettre la disquette et pressÇ une touche',$4E);
  Touche:=UpCase(ReadKey);
  If(KeyPressed)Then Begin
   Touche:=ReadKey;
   Touche:=#0;
  End;
  Registre.AH := $1C;
  Registre.DL := Disque + 1;
  MsDos(registre);
  If(Registre.AL<>$FF)Then OK := True;
 Until OK;
End;

Function Volume(Drive:Char):PathStr;
Var
 Info:SearchRec;
 Error:Integer;
Begin
 Volume:='Aucun';
 FindFirst(Drive+':\*.*',VolumeID,Info);
 Error:=DOSError;
 If(Error=0)Then Volume:=Info.Name
  else
 If(Error=152)Then
 Begin
  Repeat
   DiskNotReady(Ord(Drive)-65);
   FindFirst(Drive+':\*.*',VolumeID,Info);
   Error:=DOSError;
   If(Error=0)Then Volume:=Info.Name;
  Until(Error<>152);
 End;
End;

Procedure ReadFiles(Chaine:PathStr;Attribut:Word;Cote:Byte);
Var
 Compteur,Position : Word;
 OK                : Boolean;
 Ecart,I,J,K,M     : LongInt;
 Sortie            : Boolean;
 X                 : String[12];
 XTaille           : LongInt;
 XAttribt          : Byte;
 XSeconde          : 0..59;
 XMinute           : 0..59;
 XHeure            : 0..23;
 XJour             : 1..31;
 XMois             : 1..12;
 XAnnees           : Word;
 Date_TimeB	   : DateTime;
 Palette	   : SearchRec;
 Directory 	   : DirStr;
 FileName  	   : NameStr;
 Extension 	   : ExtStr;
 Erreur            : Integer;

 Procedure SousTri;Begin
  UnpackTime(Temps[Cote,I],Date_Time);
  UnPackTime(Temps[Cote,M],Date_TimeB);
  X               := Nom[Cote,I];
  XTaille         := Taille[Cote,I];
  XAttribt        := Attribt[Cote,I];
  XSeconde        := Date_Time.Sec;
  XMinute         := Date_Time.Min;
  XHeure          := Date_Time.Hour;
  XJour           := Date_Time.Day;
  XMois           := Date_Time.Month;
  XAnnees  	  := Date_Time.Year;
  Nom[Cote,I]     := Nom[Cote,M];
  Taille[Cote,I]  := Taille[Cote,M];
  Attribt[Cote,I] := Attribt[Cote,M];
  Date_Time.Sec   := Date_TimeB.Sec;
  Date_Time.Min   := Date_TimeB.Min;
  Date_Time.Hour  := Date_TimeB.Hour;
  Date_Time.Day   := Date_TimeB.Day;
  Date_Time.Month := Date_TimeB.Month;
  Date_Time.Year  := Date_TimeB.Year;
  Nom[Cote,M]     := X;
  Taille[Cote,M]  := XTaille;
  Attribt[Cote,M] := XAttribt;
  Date_TimeB.Sec  := XSeconde;
  Date_TimeB.Min  := XMinute;
  Date_TimeB.Hour := XHeure;
  Date_TimeB.Day  := XJour;
  Date_TimeB.Month:= XMois;
  Date_TimeB.Year := XAnnees;
  PackTime(Date_Time,Temps[Cote,I]);
  PackTime(Date_TimeB,Temps[Cote,M]);
  Dec(I,Ecart);
 End;

 Procedure SousInit;Begin
  Ecart := Ecart div 2;
  J     := 1;
  K     := NombreFichierX[Cote] - Ecart;
 End;

 Procedure TriNom;Begin
  Ecart := NombreFichierX[Cote];
  If(Ecart>3)Then
  Repeat
   SousInit;
   Repeat
    I      := J;
    Sortie := False;
    Repeat
     M := I + Ecart;
     If Nom[Cote,I] > Nom[Cote,M] Then SousTri
				  Else Sortie := True;
    Until (I<1) or (Sortie = True);
    Inc(J);
   Until J>K;
  Until Ecart = 1;
 End;

 Procedure TriExtension;Begin
  Ecart := NombreFichierX[Cote];
  If(Ecart>3)Then
  Repeat
   SousInit;
   Repeat
    I      := J;
    Sortie := False;
    Repeat
     M := I + Ecart;
     If(Copy(Nom[Cote,I],10,3)+Copy(Nom[Cote,I],1,8) >
	Copy(Nom[Cote,M],10,3)+Copy(Nom[Cote,M],1,8))Then
     SousTri Else Sortie := True;
    Until (I<1) or (Sortie = True);
    Inc(J);
   Until J>K;
  Until Ecart = 1;
 End;

 Procedure TriHeure;Begin
  Ecart := NombreFichierX[Cote];
  If(Ecart>3)Then
  Repeat
   SousInit;
   Repeat
    I      := J;
    Sortie := False;
    Repeat
     M := I + Ecart;
     If(Temps[Cote,I]>Temps[Cote,M])Then
      SousTri
      Else
     Sortie := True;
    Until (I<1) or (Sortie = True);
    Inc(J);
   Until J>K;
  Until Ecart = 1;
 End;

 Procedure TriTaille;Begin
  Ecart := NombreFichierX[Cote];
  If(Ecart>3)Then
  Repeat
   SousInit;
   Repeat
    I      := J;
    Sortie := False;
    Repeat
     M := I + Ecart;
     If Taille[Cote,I] > Taille[Cote,M] Then SousTri
					Else Sortie := True;
    Until (I<1) or (Sortie = True);
    Inc(J);
   Until J>K;
  Until Ecart = 1;
 End;

Begin
 Position:=1;
 FindFirst(Chaine,$FFF7,Palette);
 Erreur:=DOSError;
 While ((Erreur = 0)or(Erreur = 152)) do Begin
  If(Erreur=152)Then DiskNotReady(Ord(Chaine[1])-65);
  If((Palette.Name<>'.')and(Erreur=0))Then Begin
   Accepte[Cote,Position] := 0;
   Attribt[Cote,Position] := Palette.Attr and 22;
   Temps[Cote,Position]   := Palette.Time;
   Taille[Cote,Position]  := Palette.Size;
   If Length(Palette.Name)>12Then Begin
    Nom[Cote,Position] := Copy(Palette.Name,1,12);
   End
    Else
   Nom[Cote,Position] := Palette.Name;
   If(Attribt[Cote,Position]<>16)Then Begin
    FSplit(Palette.Name,Directory,FileName,Extension);
    Repeat
     FileName := FileName + ' ';
    Until (Length(FileName)>=8);
    Nom[Cote,Position] := Filename + Extension;
   End
    else
   If(Attribt[Cote,Position]=16)Then Begin
    Nom[Cote,Position] := #1 + Nom[Cote,Position];
   End;
   Inc(Position);
  End;
  If Position>=MaxFiles Then Break;
  If(Erreur<>0)Then FindFirst(Chaine,$FFF7,Palette)
               Else FindNext(Palette);
  Erreur:=DOSError;
 End;
 NombreFichierX[Cote] := Position - 1;
 Case TypeTri[Cote] of
  0:TriNom;
  1:TriExtension;
  2:TriHeure;
  3:TriTaille;
 End;
 For Compteur := 1 to NombreFichierX[Cote] do Begin
  If(Copy(Nom[Cote,Compteur],1,1)<#32)Then Nom[Cote,Compteur] := Copy(Nom[Cote,Compteur],2,11);
 End;
End;

Function Hex2(Byt:Byte):String2;Begin
 Hex2:=HexData[Byt shr 4]+HexData[Byt and 15];
End;

Function Hex(Byt:Integer):String4;Begin
 Hex:=HexData[(Byt Shr 12)and 15]+
      HexData[(Byt Shr 8)and 15]+
      HexData[(Byt Shr 4)and 15]+
      HexData[Byt and 15];
End;

Procedure ShowPrompt;Begin
 GotoXY(1,MaxScreenLine-1);
 TextBackground(Black);
 TextColor(LightGray);
 Write(PanelPath[Cote]+'>');
 ClrEol;
End;

Procedure ShowLine(Y:Byte;Ligne:Word;Cote:Binaire;Selected:Boolean;Separator:Boolean);
Var
 Date_Time:DateTime;
 Couleur:Byte;
 ChrVert:Char;
Begin
 If(Separator)Then Begin
  If(ShowASCII128)Then ChrVert:='|'
                  Else ChrVert:=#179;
 End
  Else
 ChrVert:=' ';
 Inc(Ligne);
 If(Ligne<=NombreFichierX[Cote])Then Begin
  If(Selected)Then Begin
   If(Accepte[Cote,Ligne]=0)Then Couleur:=48
                            Else Couleur:=62;
  End
   Else
  Begin
   If(Accepte[Cote,Ligne]=0)Then Couleur:=$1B
                            Else Couleur:=$1E;
  End;
  TextColor(Couleur and $F);
  TextBackground((Couleur shr 4)and 7);
  GotoXY(Cote*40+2,Y+3);
  Write(PadRight(Nom[Cote,Ligne],12),ChrVert);
  If(Attribt[Cote,Ligne]<>16)Then Write(Taille[Cote,Ligne]:8) Else
  If(Attribt[Cote,Ligne]=16)Then Begin
   Case Language of
    _English:Begin
     If(Nom[Cote,Ligne]='..')Then Write(#16,'UP--DIR')
                             Else Write(#16,'SUB-DIR');
    End;
    Else Begin
     If(Nom[Cote,Ligne]='..')Then Write('SOUS-REP')
                             Else Write('SUR-REP ');
    End;
   End;
  End;
  UnPackTime(Temps[Cote,Ligne],Date_Time);
  Write(ChrVert,Date_Time.Year:4,'-',
        PadZeroLeft(Date_Time.Month,2),'-',
        PadZeroLeft(Date_Time.Day,2));
  Write(ChrVert,Date_Time.Hour:2,':',PadZeroLeft(Date_Time.Min,2));
 End;
End;

Procedure UpdateBoard;
Var
 I:Byte;
Begin
 For I:=0 to SideLength[Cote] do Begin
  ShowLine(I,PositionX[Cote]-YPos[Cote]+I,Cote,False,True);
 End;
End;

Procedure PanelTitlePath(Side:Byte;Activate:Boolean);
Var
 Color:Byte;
Begin
 If(Activate)Then Color:=49
             Else Color:=$1B;
 WriteXY(40*Side+21-((Length(PanelPath[Side])+2) shr 1),
         1,' '+PanelPath[Side]+' ',Color);
End;

Procedure UnshowPanelPath;Begin
 PanelTitlePath(Cote,False);
End;

Procedure ShowPanelPath;Begin
 PanelTitlePath(Cote,True);
End;

Procedure RefreshPanel(Side:Byte);
Var
 DirInfo:Text;
 J,ParseSide:Byte;
 ChrVert:Char;
 II:Word;
 DirSize:LongInt;
 CurrLine,DirInfoName:String;
Begin
 If(ShowASCII128)Then ChrVert:='|'
                 Else ChrVert:=#179;
 If(PanelDisable[Side])Then Begin
  Box(1+40*Side,1,40+40*Side,21,7);
 End
  Else
 Case PanelType[Side]of
  4:Begin
   FrameEmpty(1+40*Side,1,40*Side+40,6+SideLength[Side],$1B);
   Case Language of
    _English:Begin
     WriteXY(40*Side+2,2,'    Name    '+ChrVert+'  Size  '+ChrVert+
                         '   Date   '+ChrVert+' Time',30);
    End;
    _Germany:Begin
     WriteXY(40*Side+2,2,'    Name    '+ChrVert+'  Grî·e '+ChrVert+
                         '   Datum  '+ChrVert+' Zeit',30);
    End;
    _Italian:Begin
     WriteXY(40*Side+2,2,'    Nome    '+ChrVert+'  Dim.  '+ChrVert+
                         '   Data   '+ChrVert+' Ora ',30);
    End;
    _Spain:Begin
     WriteXY(40*Side+2,2,'    Nombre  '+ChrVert+'  Tama§o'+ChrVert+
                         '    Fecha '+ChrVert+' Hora',30);
    End;
    Else Begin
     WriteXY(40*Side+2,2,'   Nom   Ext'+ChrVert+' Taille '+ChrVert+
                         '   Date   '+ChrVert+'Heure',30);
    End;
   End;
   If(PanelPath[Side,Length(PanelPath[Side])]<>'\')Then PathTem:=PanelPath[Side]+'\'
                                                   Else PathTem:=PanelPath[Side];
   ReadFiles(PathTem+'*.*',$FFFF,Side);
   For J:=0 to SideLength[Cote] do ShowLine(J,J,Side,False,True);
   PanelTitlePath(Side,Cote=Side);
   If NombreFichierX[Side]<=SideLength[Side]Then Box(40*Side+2,NombreFichierX[Side]+3,40*Side+39,SideLength[Side]+3,31);
   GotoXY(40*Side+2,MaxScreenLine-4);
   TextBackground(Blue);
   TextColor(LightCyan);
   If(ShowASCII128)Then Write(DuplicateString('-',38))
    Else
   Begin
    Write(DuplicateString(#196,12),#193);
    Write(DuplicateString(#196,8),#193);
    Write(DuplicateString(#196,10),#193);
    Write(DuplicateString(#196,5));
   End;
  End;
  2:Begin
   ParseSide:=(Side+1)and 1;
   DirSize:=0;
   Box(40*Side+2,1,40*Side+39,MaxScreenLine-2,$1B);
   FrameEmpty(40*Side+1,1,40*Side+40,MaxScreenLine-2,$1B);
   WriteXY(40*Side+7,2,'North Commander, Version '+Version,$1B);
   WriteXY(40*Side+9,3,'Clone de Norton Commander',$1B);
   WriteXY(40*Side+2,4,DuplicateString(#196,38),$1B);
   GotoXY(40*Side+2,5);
   TextColor(Yellow);
   Write(RAMSize*1024:13);
   TextColor(LightCyan);
   Write(' octets de mÇmoire');
   GotoXY(40*Side+2,6);
   TextColor(Yellow);
   Write(640*1024:9);
   TextColor(LightCyan);
   Write(' octets de mÇmoire de libre');
   GotoXY(40*Side+2,7);
   TextColor(Yellow);
   Write(DiskSize(Ord(PanelPath[ParseSide,1])-64));
   TextColor(LightCyan);
   Write(' octets total sur le disque ');
   TextColor(Yellow);
   Write(PanelPath[ParseSide,1],':');
   GotoXY(40*Side+2,8);
   Write(DiskFree(Ord(PanelPath[ParseSide,1])-64));
   TextColor(LightCyan);
   Write(' octets libre sur le disque ');
   TextColor(Yellow);
   Write(PanelPath[ParseSide,1],':');
   GotoXY(40*Side+2,9);
   Write(NombreFichierX[ParseSide]);
   TextColor(LightCyan);
   Write(' fichiers utilisant ');
   TextColor(Yellow);
   For II:=0 to NombreFichierX[ParseSide]-1 do Begin
    Inc(DirSize,Taille[ParseSide,II]);
   End;
   Write(DirSize);
   TextColor(LightCyan);
   Write(' octets dans ');
   GotoXY(40*Side+2,10);
   If Length(PanelPath[ParseSide])<38 Then Write(' ':(38-Length(PanelPath[ParseSide]))shr 1);
   Write(PanelPath[ParseSide]);
   GotoXY(40*Side+2,11);
   Write(DuplicateString(#196,38));
   GotoXY(40*Side+2,12);
   TextColor(LightCyan);
   Write('êtiquette de volume : ');
   TextColor(Yellow);
   Write(Volume(PanelPath[ParseSide,1]));
   TextColor(LightCyan);
   GotoXY(40*Side+2,13);
   Write(DuplicateString(#196,38));
   DirInfoName:=PanelPath[ParseSide];
   If DirInfoName<>''Then Begin
    If DirInfoName[Length(DirInfoName)]<>'\'Then DirInfoName:=DirInfoName+'\';
   End;
   DirInfoName:=DirInfoName+'DIRINFO';
   {$I-}Assign(DirInfo,DirInfoName);
   Reset(DirInfo);{$I+}
   If IOResult=0 Then Begin
    II:=0;
    While Not EOF(DirInfo)do Begin
     ReadLn(DirInfo,CurrLine);
     GotoXY(40*I+2,14+II);
     Write(Copy(CurrLine,1,38));
     Inc(II);
     If II>9 Then Break;
    End;
    Close(DirInfo);
   End
    Else
   Begin
    GotoXY(40*Side+4,15);
    Case Language of
     _English:Begin
      Write('No ''dirinfo'' file in this directory');
     End;
     Else Begin
      Write('Aucun fichier ''dirinfo'' dans ');
      GotoXY(40*Side+4,16);
      Write('ce rÇpertoire');
     End;
    End;
   End;
  End;
 End;
End;

Procedure RefreshPanels;
Var
 I:Byte;
Begin
 For I:=0 to 1 do Begin
  If(PanelDisable[I])Then Begin
   Box(1+40*I,1,40*I+40,MaxScreenLine-2,7);
  End
   Else
  Case PanelType[I]of
   4:RefreshPanel(I);
  End;
 End;
 For I:=0 to 1 do Begin
  If Not(PanelDisable[I])Then Case PanelType[I]of
   2:RefreshPanel(I);
  End;
 End;
End;

Procedure ShowKeyFunc;
Const
 FunctionKeyValue:Array[0..9]of String[7]=(
  'Aide','Menu','Affich','Editer','Copier','RenDep','CreRep','Suppr.','Menu','Sortie'
 );
 FunctionKeyValueEnglish:Array[0..9]of String[7]=(
  'Help','Menu','View','Edit','Copy','RenMov','Mkdir','Delete','PullDn','Quit'
 );
 FunctionKeyValueGerman:Array[0..9]of String[7]=(
  'Hilfe','MenÅ','Anz.','Bearb.','Kopie','UmbBew','MkDir','Lôsche','Funkt.','Quit'
 );
 FunctionKeyValueItalian:Array[0..9]of String[7]=(
  'Guida','Menu','Vista','Modif','Copia','RinSpo','CreDir','Cancel','Tendin','Esci'
 );
 FunctionKeyValueSpain:Array[0..9]of String[7]=(
  'Ayuda','Men£','Ver','Editar','Copiar','RenMov','Hacdir','Borrar','BarMen','Salir'
 );
Var
 I:Byte;
Begin
 TextBackground(Black);
 TextColor(LightGray);
 GotoXY(1,MaxScreenLine);
 Write('1');
 For I:=1 to 8 do Begin
  GotoXY(I*8,MaxScreenLine);
  Write(' ',I+1);
 End;
 TextBackground(Cyan);
 TextColor(Black);
 For I:=0 to 8 do Begin
  GotoXY(I*8+2,MaxScreenLine);
  Case Language of
   _English:Write(PadRight(FunctionKeyValueEnglish[I],6));
   _Germany:Write(PadRight(FunctionKeyValueGerman[I],6));
   _Italian:Write(PadRight(FunctionKeyValueItalian[I],6));
   _Spain:Write(PadRight(FunctionKeyValueSpain[I],6));
   Else Write(PadRight(FunctionKeyValue[I],6));
  End;
 End;
 TextBackground(Black);
 TextColor(LightGray);
 GotoXY(71,MaxScreenLine);
 Write(' 10');
 TextBackground(Cyan);
 TextColor(Black);
 GotoXY(74,MaxScreenLine);
 Case Language of
  _English:Write(FunctionKeyValueEnglish[9]);
  _Germany:Write(FunctionKeyValueGerman[9]);
  _Italian:Write(FunctionKeyValueItalian[9]);
  _Spain:Write(FunctionKeyValueSpain[9]);
  Else Write(FunctionKeyValue[9]);
 End;
 ClrEol;
End;

Procedure ShowPanelStatusBar(Cote:Byte);Begin
 If PanelDisable[Cote]Then Exit;
 If PanelType[Cote]<>4Then Exit;
 If Nombre[Cote]>0Then Begin
  TextBackground(Blue);
  TextColor(Yellow);
  GotoXY(40*Cote+2,MaxScreenLine-3);
  Write(Nombre[Cote],' fichiers sÇlectionnÇs    ');
 End
  Else
 ShowLine(MaxScreenLine-6,PositionX[Cote],Cote,False,False);
End;

Procedure Refresh;
Var
 I:Byte;
Begin
 RefreshPanels;
 For I:=0 to 1 do ShowPanelStatusBar(I);
 Nombre[0]:=0;
 Nombre[1]:=0;
 ShowKeyFunc;
 ShowPrompt;
 ChDir(PanelPath[Cote]);
 CurrCommand:='';
End;

Procedure ChangeDrive(Cote:Binaire);
Var
 Drive:Array['A'..'Z']of Boolean;
 DriveList:String;
 I:Char;
 Nombre:Byte;
 BoxWidth,BoxX1,BoxX2,CurrX:Integer;
 Compteur:Byte;
 Position:Integer;
 OK:0..1;
 Erreur:Byte;
 K:Char;
Begin
 FillChar(Drive,SizeOf(Drive),False);
 Nombre:=0;
 DriveList:='';
 For I:='A' to 'Z'do Begin
  Drive[I]:=DiskSize(1+Ord(I)-Ord('A'))<>-1;
  If Drive[I]Then Begin
   DriveList:=DriveList+I;
   Inc(Nombre);
  End;
 End;
 BoxWidth:=Nombre*4+8;
 If BoxWidth<20Then BoxWidth:=20;
 BoxX1:=Cote*40+((40-BoxWidth)shr 1);
 If BoxX1<0Then BoxX1:=0;
 BoxX2:=BoxX1+BoxWidth;
 Position:=Ord(PanelPath[Cote,1])-64;
 OK:=0;
 FrameFull(BoxX1+1,8,BoxX2+1,13,$70);
 TextColor(0);
 TextBackground(7);
 GotoXY(Cote*40+14,9);
 Write('Lettre de disque');
 GotoXY(Cote*40+9,10);
 Write('Choisir le disque ');
 If(Cote=0)Then Write('gauche')
           Else Write('droite');
 WriteLn(' :');
 CurrX:=BoxX1+4;
 For I:='A'to 'Z'do If Drive[I]Then Begin
  GotoXY(CurrX,11);
  Write(' ',I,'  ');
  Inc(CurrX,4);
 End;
 CurrX:=BoxX1+4;
 Position:=1;
 CursorOff;
 Repeat
  TextBackground(3);
  GotoXY(BoxX1+4*Position,11);
  Write(' ',DriveList[Position],' ');
  K:=ReadKey;
  TextBackground(7);
  GotoXY(BoxX1+4*Position,11);
  Write(' ',DriveList[Position],' ');
  If(KeyPressed)Then Begin
   K:=ReadKey;
   Case K of
    #75:If Position=1 Then Position:=Length(DriveList)
                      Else Dec(Position);
    #77:If Position=Length(DriveList)Then Position:=1
                                     Else Inc(Position);
   End;
  End
   Else
  Case K of
   #13:Begin
    PanelPath[Cote]:=DriveList[Position]+':\';
    OK:=1;
    PanelType[Cote]:=4;
   End;
   #27:OK := 1;
  End;
 Until OK=1;
 CursorOn;
 Refresh;
End;

Procedure DialogNotImplement;Begin
 CursorOff;
 FrameFull(11,10,71,17,$70);
 WriteCenter(13,'Cette fonctionnalitÇ n''est pas implantÇ',$70);
 WriteXY(39,15,' Ok ',$0F);
 ReadKey;
 CursorOn;
End;

Procedure ErrorOk(Msg:String);Begin
 CursorOff;
 FrameFull(11,10,71,17,$4F);
 WriteCenter(13,Msg,$40);
 WriteXY(39,15,' Ok ',$30);
 ReadKey;
 CursorOn;
End;

Procedure CopyFile(Source,Target:String);
Var
 SourceFile,TargetFile:File;
 NumRead,NumWrite:Word;
 Buffer:Array[0..{$IFDEF FPC}32767{$ELSE}2047{$ENDIF}] of Byte;
Begin
 FrameFull(11,9,70,17,63);
 WriteCenter(12,'Copie fichier '+Source,62);
 WriteCenter(13,'Ö',62);
 WriteCenter(14,Target,62);
 {$I-}Assign(SourceFile,Source);
 Reset(SourceFile,1);{$I+}
 If(IOResult<>0)Then Begin
  ErrorOk('Impossible d''ouvrir le fichier '+Source);
  Exit;
 End;
 Target:=Target+'\'+SplitFileName(Source);
 {$I-}Assign(TargetFile,Target);
 Rewrite(TargetFile,1);{$I+}
 If(IOResult<>0)Then Begin
  ErrorOk('Impossible de crÇer le fichier '+Target);
  Exit;
 End;
 Repeat
  BlockRead(SourceFile,Buffer,SizeOf(Buffer),NumRead);
  BlockWrite(TargetFile,Buffer,NumRead,NumWrite);
  If(NumRead<>NumWrite)Then Begin
   WriteLn('Impossible de copier le fichier : ',Source:13);
   Close(SourceFile);
   Erase(TargetFile);
   Close(TargetFile);
   Exit
  End;
 Until NumRead=0;
 Close(SourceFile);
 Close(TargetFile);
End;

Function MoveFile(Source,Target:String):Boolean;
Var
 F:File;
Begin
 If(Source='')or(Target='')Then Begin
  MoveFile:=False;
  Exit;
 End;
 Source:=FExpand(Source);
 Target:=FExpand(Target);
 If(Source[1]<>Target[1])and(Source[2]=':')Then Begin { Unite de disque different ?}
   { Copie le fichier }
  CopyFile(Source,Target);
   { Supprime le fichier }
  {$I-}Assign(F,Source);
  Erase(F);
  {$I+}
  MoveFile:=IOResult=0;
 End
  Else
 Begin
  {$I-}
  Assign(F,Source);
  Rename(F,Target+'\'+SplitFileName(Source));
  MoveFile:=IOResult=0;
  {$I+}
 End;
End;

Procedure HelpFunc;Begin
 DialogNotImplement;
 Refresh;
End;

Procedure MenuFunc;
Const
 MaxMenu=39;
Type
 MenuRec=Record
  Letter:String[3];
  Name:String[50];
  Cmd:String[127];
 End;
Var
 Mode:(_None,_Letter,_Name,_Cmd);
 MenuFile:Text;
 Terminated:Boolean;
 Menu:Array[0..MaxMenu]of MenuRec;
 YMenu,PosMenu,NumMenu,WidthBox,HeightBox,X1,Y1,X2,Y2:Byte;
 I:Integer;
 CurrLine,CurrWord:String;

 Procedure SelectMenu;Begin
  GotoXY(X1+2,Y1+2+YMenu);
  Write(Menu[PosMenu].Letter);
  TextBackground(0);
  GotoXY(X1+5,Y1+2+YMenu);
  Write(' ',PadRight(Copy(Menu[PosMenu].Name,1,50),WidthBox-10));
  TextBackground(Cyan);
 End;

 Procedure UnselectMenu;Begin
  GotoXY(X1+2,Y1+2+YMenu);
  Write(Menu[PosMenu].Letter);
  GotoXY(X1+5,Y1+2+YMenu);
  Write(' ',PadRight(Copy(Menu[PosMenu].Name,1,50),WidthBox-10));
 End;

Begin
 {$I-}Assign(MenuFile,'NC.MNU');
 Reset(MenuFile);{$I+}
 If IOResult=0 Then Begin
  NumMenu:=0;
  FillChar(Menu,SizeOf(Menu),0);
  Mode:=_None;
  While Not EOF(MenuFile)do Begin
   ReadLn(MenuFile,CurrLine);
   CurrWord:='';
   If Mode in[_Letter,_Name]Then Begin
    Menu[NumMenu].Cmd:=CurrLine;
    Inc(NumMenu);
    If NumMenu>MaxMenu Then Break;
    Mode:=_None;
   End
    Else
   Begin
    For I:=1 to Length(CurrLine)do Begin
     If CurrLine[I]=' 'Then Begin
      If CurrWord[Length(CurrWord)]=':'Then Begin
       Menu[NumMenu].Letter:=CurrWord;
       CurrWord:='';
       Mode:=_Letter;
      End;
     End
      Else
     CurrWord:=CurrWord+CurrLine[I];
    End;
    Menu[NumMenu].Name:=Copy(Trim(CurrWord),1,50);
   End;
  End;
  Close(MenuFile);
  If NumMenu=0 Then ErrorOk('Aucun menu prÇsent dans le fichier nc.mnu !')
   Else
  Begin
   CursorOff;
   WidthBox:=20;
   HeightBox:=4+NumMenu;
   If HeightBox>20 Then HeightBox:=20;
   For I:=0 to NumMenu-1 do Begin
    If Length(Menu[I].Name)>WidthBox Then Begin
     WidthBox:=Length(Menu[I].Name);
     If WidthBox>50 Then WidthBox:=50;
    End;
   End;
   Inc(WidthBox,20);
   X1:=40-(WidthBox shr 1);
   Y1:=12-(HeightBox shr 1);
   X2:=40+(WidthBox shr 1);
   Y2:=12+(HeightBox shr 1);
   FrameChoice(X1,Y1,X2,Y2);
   Case Language of
    _English:WriteCenter(Y1,'User Menu',63);
    _Germany:WriteCenter(Y1,'BenutzermenÅ',63);
    _Italian:WriteCenter(Y1,'Menu utente (principale)',63);
    _Spain:WriteCenter(Y1,'Men£ usuario (Principal)',63);
    Else WriteCenter(Y1,'Menu utilisateur',63);
   End;
   For I:=0 to NumMenu-1 do Begin
    GotoXY(X1+2,Y1+2+I);
    Write(Menu[I].Letter);
    GotoXY(X1+5,Y1+2+I);
    Write(' ',Copy(Menu[I].Name,1,50));
   End;
   Terminated:=False;
   PosMenu:=0;
   YMenu:=0;
   SelectMenu;
   Repeat
    Case ReadKey of
     #0:Case ReadKey of
      #72:Begin { Up }
      If PosMenu>0 Then Begin
        UnselectMenu;
        Dec(PosMenu);
        If YMenu>0Then Dec(YMenu)
         Else
        Begin
         Window(X1+2,Y1+2,X2-2,Y2-2);
         InsLine;
         Window(1,1,80,MaxScreenLine);
        End;
        SelectMenu;
       End;
      End;
      #80:Begin { Down }
       If PosMenu<NumMenu-1 Then Begin
        UnselectMenu;
        Inc(PosMenu);
        If YMenu<20-4 Then Inc(YMenu)
         Else
        Begin
         Window(X1+2,Y1+2,X2-2,Y2-2);
         DelLine;
         Window(1,1,80,MaxScreenLine);
        End;
        SelectMenu;
       End;
      End;
     End;
     #13:Begin
      Exec(GetEnv('COMSPEC'),'/C '+Menu[PosMenu].Cmd);
      Refresh;
      Terminated:=True;
     End;
     #27:Terminated:=True;
    End;
   Until Terminated;
   CursorOn;
  End;
 End
  Else
 ErrorOk('Fichier Ænc.mnuØ non prÇsent ou impossible Ö lire');
 Refresh;
End;

Procedure ViewFunc;
Var
 Finish:Boolean;
 FileView:File;
 ByteReaded:Word;
 I,CurrLinePos:Integer;
 FileName:String;
 Buffer:Array[0..2048]of Byte;
 LastPos,CurrPos,LenBuf:LongInt;

 Procedure ViewFrameASCII;
 Const
  FunctionKeyValue:Array[0..9]of String[7]=(
   '','','','','','','','','','Sortir'
  );
 Var
   I:Byte;
   Pour:Byte;
 Begin
  If FileSize(FileView)=0Then Pour:=0
                         Else Pour:=Trunc((CurrPos / FileSize(FileView))*100);
  GotoXY(1,1);
  TextBackground(Cyan);
  TextColor(Black);
  Write(FileName);
  ClrEol;
  GotoXY(Lo(WindMax)-3,1);
  Write(Pour:3,'%');
  For I:=0 to 8 do Begin
   GotoXY(I*7+1+2,MaxScreenLine);
   Write(PadRight(FunctionKeyValue[I],6));
  End;
  GotoXY(67,MaxScreenLine);
  Write(FunctionKeyValue[9]);
  ClrEol;
  TextBackground(Black);
  TextColor(LightGray);
  For I:=0 to 9 do Begin
   GotoXY(I*7+1,MaxScreenLine);
   Write(I+1,' ');
  End;
 End;

 Function ViewASCII:Integer;
 Var
  Pour,X,I,J:Byte;
  PosInBuffer:Word;
 Begin
  If FileSize(FileView)=0Then Pour:=0
                         Else Pour:=Trunc((CurrPos / FileSize(FileView))*100);
  If Pour>=99Then Pour:=100;
  GotoXY(Lo(WindMax)-3,1);
  TextBackground(Cyan);
  TextColor(Black);
  Write(Pour:3,'%');
  TextBackground(Blue);
  TextColor(LightCyan);
  GotoXY(1,2);
  X:=1;
  J:=0;
  PosInBuffer:=0;
  While(J<MaxScreenLine-2)and(PosInBuffer<2048)do Begin
   Case(Buffer[PosInBuffer])of
    13:Begin
     ClrEol;
     WriteLn;
     X:=1;
     Inc(J);
     If Buffer[PosInBuffer+1]=10Then Inc(PosInBuffer);
     If J=MaxScreenLine-2Then Break;
    End;
    0..12,14..31:Begin
     Write(' ');
     Inc(X);
    End;
    Else Begin
     Inc(X);
     Write(Chr(Buffer[PosInBuffer]));
    End;
   End;
   If X=80Then Begin
    X:=1;
    Inc(J);
    If J=MaxScreenLine-2Then Break;
   End;
   Inc(PosInBuffer);
  End;
  If J<23Then Begin
   Window(1,1+J,80,MaxScreenLine-3);
   ClrScr;
   Window(1,1,80,MaxScreenLine);
  End;
  ViewASCII:=PosInBuffer;
 End;

Begin
 FileName:=GetCurrName;
 {$I-}Assign(FileView,FileName);
 Reset(FileView,1);{$I+}
 If IoResult<>0Then Begin
  FrameFull(11,10,71,17,$4F);
  WriteCenter(13,'Probläme de lecture du fichier :',$40);
  WriteCenter(14,FileName,$40);
  WriteXY(39,15,' Ok ',$0F);
  ReadKey;
  Refresh;
  Exit;
 End;
 CurrPos:=0;
 ClrScr;
 ViewFrameASCII;
 Finish:=False;
 CursorOff;
 Repeat
  FillChar(Buffer,SizeOf(Buffer),0);
  Seek(fileView,CurrPos);
  BlockRead(FileView,Buffer,2048,ByteReaded);
  ByteReaded:=ViewASCII;
  Case ReadKey Of
   #0:Case ReadKey of
    #1:Finish:=True;
    #68:Finish:=True; { F10 }
    #73:Begin {PageUp}
     FillChar(Buffer,SizeOf(Buffer),0);
     LenBuf:=2048;
     CurrLinePos:=0;
     LastPos:=CurrPos-LenBuf;
     If LastPos<0Then Begin
      LenBuf:=2048+LastPos;
      LastPos:=0;
     End;
     Seek(fileView,LastPos);
     BlockRead(FileView,Buffer,LenBuf,ByteReaded);
     For I:=ByteReaded-1 downto 0do Begin
      Case Buffer[I]of
       13:Begin
        Inc(CurrLinePos);
        If CurrLinePos>=MaxScreenLine-1Then Begin
         Break;
        End;
       End;
       10:;
      End;
     End;
     CurrPos:=LastPos+I;
     If I>1Then Inc(CurrPos);
    End;
    #81:Begin {PageDown}
     If CurrPos+ByteReaded<=FileSize(FileView)Then Inc(CurrPos,ByteReaded);
    End;
   End;
   #27:Finish:=True;
  End;
 Until Finish;
 Close(FileView);
 CursorOn;
 Refresh;
End;

Procedure EditFunc;Begin
 Exec('NCEDIT.EXE',GetCurrName);
 Refresh;
End;

Procedure CopyFunc;
Var
 Source,Target:String;
 K:Word;
 Boucle:Word;
 Direct,Ok:Boolean;
 Erreur:Byte;
Begin
 If PanelType[(Cote+1) and 1]=PanelFile Then Begin
  Target:=PanelPath[(Cote + 1) and 1];
 End
  Else
 Target:='';
 FrameFull(3,6,76,13,$70);
 Case Language of
  _English:WriteCenter(7,' Copy ',$70);
  _Germany:WriteCenter(7,' Kopieren ',$70);
  _Italian:WriteCenter(7,' Copia ',$70);
  _Spain:WriteCenter(7,' Copiar ',$70);
  Else WriteCenter(7,' Copie ',$70);
 End;
 GotoXY(7,8);
 If(Nombre[Cote]=0)Then Begin
  Case Language of
   _English:Write('Copy "',GetCurrFileName,'" to ');
   _Germany:Write('Kopieren von "',GetCurrFileName,'" nach ');
   _Italian:Write('Copia "',GetCurrFileName,'" in ');
   _Spain:Write('Copiar "',GetCurrFileName,'" in ');
   Else Write('Copie "',GetCurrFileName,'" Ö ');
  End;
 End
  Else
 Begin
  Case Language of
   _English:Write('Copy ',Nombre[Cote],' files to ');
   _Germany:Write('Kopieren von ',Nombre[Cote],' Dateien nach ');
   _Italian:Write('Copia ',Nombre[Cote],' file in ');
   _Spain:Write('Copiar ',Nombre[Cote],' archivos y en ');
   Else Write('Copie ',Nombre[Cote],' fichiers Ö ');
  End;
 End;
 Ok:=False;
 Case Language of
  _English:ShowHorizontalCenterButton(11,'Copy|Cancel');
  _Germany:ShowHorizontalCenterButton(11,'Kopieren|Abbruch');
  _Italian:ShowHorizontalCenterButton(11,'Copia|Annulla');
  _Spain:ShowHorizontalCenterButton(11,'Copiar|Cancelar');
  Else ShowHorizontalCenterButton(11,'Copie|Annule');
 End;
 Repeat
  Repeat
  TextColor(Black);
  TextBackground(LightCyan);
   K:=ReadLineInBox(7,9,72,9,Target);
   If(K=kbEsc)Then Begin
    Refresh;
    Exit;
   End;
  Until(K=kbTab)or(K=kbEnter);
  Case Language of
   _English:K:=ReadHorizontalCenterButton(11,'Copy|Cancel');
   _Germany:K:=ReadHorizontalCenterButton(11,'Kopieren|Abbruch');
   _Italian:K:=ReadHorizontalCenterButton(11,'Copia|Annulla');
   _Spain:K:=ReadHorizontalCenterButton(11,'Copiar|Cancelar');
   Else K:=ReadHorizontalCenterButton(11,'Copie|Annule');
  End;
  If(K=1)or(K=kbEsc)Then Begin
   Refresh;
   Exit;
  End;
  If(K=0)Then OK:=True;
 Until Ok;
 If(Nombre[Cote]=0)Then Begin
  CopyFile(GetCurrName,Target);
 End
  Else
 Begin
  For I:=0 to NombreFichierX[Cote]-1 do Begin
   If(Accepte[Cote,I+1]=1)Then Begin
    PathTem:=PanelPath[Cote];
    If(PanelPath[Cote,Length(PanelPath[Cote])]<>'\')Then PathTem := PanelPath[Cote] + '\';
    PathTem:=PathTem+Trim(Path2Name(Nom[Cote,I+1]))+Path2Ext(Nom[Cote,I+1]);
    CopyFile(PathTem,Target);
   End;
  End;
 End;
 Refresh;
End;

Procedure RenMovFunc;
Var
 F:File;
 S,OldDir:String;
 K:Word;
 Ok,RenameDialog:Boolean;
Begin
 If(Nombre[Cote]=0)Then Begin
  If PanelType[(Cote+1) and 1]=PanelInfo Then Begin
   S:=GetCurrFileName;
   RenameDialog:=True;
  End
   Else
  Begin
   S:=PanelPath[(Cote+1) and 1];
   RenameDialog:=False;
  End;
 End
  Else
 Begin
  If PanelType[(Cote+1) and 1]=PanelFile Then S:=PanelPath[(Cote+1) and 1];
  RenameDialog:=False;
 End;
 FrameFull(3,6,76,13,$70);
 Case Language of
  _English:WriteCenter(7,' Rename ',$70);
  _Germany:WriteCenter(7,' Umbenennen ',$70);
  _Italian:WriteCenter(7,' Rinomina ',$70);
  _Spain:WriteCenter(7,' Renombrar ',$70);
  Else WriteCenter(7,' Renomme ',$70);
 End;
 GotoXY(7,8);
 If(Nombre[Cote]=0)Then Begin
  Case Language of
   _English:Write('Rename or move "',GetCurrFileName,'" to ');
   _Germany:Write('Umbenennen oder Bewegen "',GetCurrFileName,'" nach ');
   _Italian:Write('Rinomina o sposta "',GetCurrFileName,'" in ');
   _Spain:Write('Renombrar o mover "',GetCurrFileName,'" en ');
   Else Write('Renomme ou dÇplace "',GetCurrFileName,'" Ö ');
  End;
 End
  Else
 Begin
  Case Language of
   _English:Write('Rename or move ',Nombre[Cote],' files to ');
   _Germany:Write('Umbenennen oder Bewegen von ',Nombre[Cote],' Dateien nach ');
   _Italian:Write('Rinomina o sposta ',Nombre[Cote],' file in ');
   _Spain:Write('Renombrar o mover ',Nombre[Cote],' archivos en ');
   Else Write('Renomme ou dÇplace ',Nombre[Cote],' fichiers Ö ');
  End;
 End;
 Ok:=False;
 Case Language of
  _English:ShowHorizontalCenterButton(11,'Move|Cancel');
  _Germany:ShowHorizontalCenterButton(11,'Bewegen|Abbrechen');
  _Italian:ShowHorizontalCenterButton(11,'RinSpo|Annulla');
  _Spain:ShowHorizontalCenterButton(11,'Ren/Mv|Cancelar');
  Else Begin
   If(RenameDialog)Then ShowHorizontalCenterButton(11,'Renomme|Annule')
                   Else ShowHorizontalCenterButton(11,'DÇplace|Annule');
  End;
 End;
 Repeat
  Repeat
  TextColor(Black);
  TextBackground(LightCyan);
   K:=ReadLineInBox(7,9,72,9,S);
   If(K=kbEsc)Then Begin
    Refresh;
    Exit;
   End;
  Until(K=kbTab)or(K=kbEnter);
  Case Language of
   _English:K:=ReadHorizontalCenterButton(11,'Move|Cancel');
   _Germany:K:=ReadHorizontalCenterButton(11,'Bewegen|Abbrechen');
   _Italian:K:=ReadHorizontalCenterButton(11,'RinSpo|Annulla');
   _Spain:K:=ReadHorizontalCenterButton(11,'Ren/Mv|Cancelar');
   Else Begin
    If(RenameDialog)Then K:=ReadHorizontalCenterButton(11,'Renomme|Annule')
                    Else K:=ReadHorizontalCenterButton(11,'DÇplace|Annule');
   End;
  End;
  If(K=1)or(K=kbEsc)Then Begin
   Refresh;
   Exit;
  End;
  If(K=0)Then OK:=True;
 Until Ok;
 If(Nombre[Cote]=0)Then Begin
  If PanelType[(Cote+1) and 1]=PanelInfo Then Begin
   GetDir(0,OldDir);
   ChDir(GetCurrPath);
   {$I-}Assign(F,GetCurrName);
   Rename(F,S);{$I+}
   ChDir(OldDir);
  End
   Else
  MoveFile(GetCurrName,S);
 End
  Else
 Begin
  For I:=0 to NombreFichierX[Cote]-1 do Begin
   If(Accepte[Cote,I+1]=1)Then Begin
    PathTem:=PanelPath[Cote];
    If(PanelPath[Cote,Length(PanelPath[Cote])]<>'\')Then PathTem := PanelPath[Cote] + '\';
    PathTem:=PathTem+Trim(Path2Name(Nom[Cote,I+1]))+Path2Ext(Nom[Cote,I+1]);
    MoveFile(PathTem,S);
   End;
  End;
 End;
 Refresh;
End;

Procedure MkDirFunc;
Var
 S:String;
 K:Word;
 Touche:Char;
 Erreur:Word;
Begin
 S:='';
 FrameFull(3,6,76,11,$70);
 Case Language of
  _English:WriteCenter(7,' Make directory ',$70);
  _Germany:WriteCenter(7,' Verzeichnis erstellen ',$70);
  _Italian:WriteCenter(7,' Crea directory ',$70);
  _Spain:WriteCenter(7,' Crear directorio ',$70);
  Else WriteCenter(7,' CrÇation d''un rÇpertoire ',$70);
 End;
 GotoXY(7,8);
 Case Language of
  _English:Write('Create the directory');
  _Germany:Write('Erstellen des Verzeichnisses');
  _Italian:Write('Creare la directory');
  _Spain:Write('Crear el directorio');
  Else Write('CrÇer le rÇpertoire');
 End;
 TextColor(Black);
 TextBackground(LightCyan);
 Repeat
  K:=ReadLineInBox(7,9,72,9,S);
 Until(K=kbEsc)or(K=kbEnter);
 If(K=kbEnter)Then Begin
  PathTem:=PanelPath[Cote];
  If(PathTem[Length(PathTem)]<>'\')Then PathTem:=PathTem+'\';
  PathTem:=PathTem+S;
  {$I-}MkDir(PathTem);
  Erreur:=IoResult;{$I+}
  If(Erreur<>0)Then Begin
   Box(12,13,69,15,$4F);
   FrameEmpty(11,12,70,16,$4F);
   WriteCenter(13,'Erreur : De rÇpertoire',$4F);
   WriteCenter(14,'Impossible de crÇe le rÇpertoire',$4F);
   WriteCenter(15,'Presse une touche pour retourner',$4E);
   Write(^G);
   Touche:=ReadKey;
   If(KeyPressed)Then Touche:=ReadKey;
  End;
 End;
 Refresh;
End;

Procedure DeleteFunc;
Var
 K:Word;
 I:Integer;
 Changement:Byte;
Begin
 Changement:=0;
 If(Nombre[Cote]=0)And(Attribt[Cote,PositionX[Cote]+1] = 16)Then Begin
  FrameFull(10,11,70,17,$70);
  Case Language of
   _English:Begin
    WriteCenter(12,' Delete ',$70);
    WriteCenter(13,'Do you wish to delete the directory',$70);
   End;
   _Germany:Begin
    WriteCenter(12,' Lîschen ',$70);
    WriteCenter(13,'Wollen Sie das Verzeichnis lîschen:',$70);
   End;
   _Italian:Begin
    WriteCenter(12,' Cancella ',$70);
    WriteCenter(13,'Cancellare la directory',$70);
   End;
   _Spain:Begin
    WriteCenter(12,' Borrar ',$70);
    WriteCenter(13,'Desea eliminar el directorio',$70);
   End;
   Else Begin
    WriteCenter(12,' Efface ',$70);
    WriteCenter(13,'Etes-vous certain de vouloir effacer le rÇpertoire',$70);
   End;
  End;
  WriteCenter(14,'"'+GetCurrFileName+'"',$70);
  Repeat
   Case Language of
    _English:K:=ReadHorizontalCenterButton(15,'Delete|Cancel');
    _Germany:K:=ReadHorizontalCenterButton(15,'Lîschen|Abbrechen');
    _Italian:K:=ReadHorizontalCenterButton(15,'Cancella|Annulla');
    _Spain:K:=ReadHorizontalCenterButton(15,'Borrar|Cancelar');
    Else K:=ReadHorizontalCenterButton(15,'Supprimer|Annuler');
   End;
   If K=kbEsc Then K:=1;
  Until K<=1;
  If K=0 Then Begin
   {$I-}RmDir(GetCurrName);{$I+}
   If(IoResult<>0)Then ErrorOk('Erreur de suppression')
                  Else Changement:=1;
  End;
 End
  Else
 If(Nombre[Cote]=0)And(Attribt[Cote,PositionX[Cote]+1]<16)Then Begin
  FrameFull(15,11,65,17,$70);
  Case Language of
   _English:Begin
    WriteCenter(12,' Delete ',$70);
    WriteCenter(13,'Do you wish to delete',$70);
   End;
   _Germany:Begin
    WriteCenter(12,' Lîschen ',$70);
    WriteCenter(13,'Wollen Sie lîschen?',$70);
   End;
   _Italian:Begin
    WriteCenter(12,' Cancella ',$70);
    WriteCenter(13,'Cancellare',$70);
   End;
   _Spain:Begin
    WriteCenter(12,' Borrar ',$70);
    WriteCenter(13,'Desea borrar',$70);
   End;
   Else Begin
    WriteCenter(12,' Efface ',$70);
    WriteCenter(13,'Etes-vous certain de vouloir effacer',$70);
   End;
  End;
  WriteCenter(14,GetCurrFileName,$70);
  Repeat
   Case Language of
    _English:K:=ReadHorizontalCenterButton(15,'Delete|Cancel');
    _Germany:K:=ReadHorizontalCenterButton(15,'Lîschen|Abbrechen');
    _Italian:K:=ReadHorizontalCenterButton(15,'Cancella|Annulla');
    _Spain:K:=ReadHorizontalCenterButton(15,'Borrar|Cancelar');
    Else K:=ReadHorizontalCenterButton(15,'Supprimer|Annuler');
   End;
   If K=kbEsc Then K:=1;
  Until K<=1;
  If K=0 Then Begin
   If(DeleteFile(GetCurrName)<>-1)Then Changement := 1;
  End;
 End
  else
 Begin
  FrameFull(10,11,70,16,$70);
  Str(Nombre[Cote],PathTem);
  Case Language of
   _English:Begin
    WriteCenter(12,' Delete ',$70);
    WriteCenter(13,'You have selected '+PathTem+' files.',$70);
   End;
   _Germany:Begin
    WriteCenter(12,' Lîschen ',$70);
    WriteCenter(13,'Sie haben '+PathTem+' Dateien ausgewÑhlt.',$70);
   End;
   _Italian:Begin
    WriteCenter(12,' Cancella ',$70);
    WriteCenter(13,'E'' stato selezionato '+PathTem+' file.',$70);
   End;
   _Spain:Begin
    WriteCenter(12,' Borrar ',$70);
    WriteCenter(13,'Ha seleccionado '+PathTem+' archivos.',$70);
   End;
   Else Begin
    WriteCenter(12,' Efface ',$70);
    WriteCenter(13,'Etes-vous certain de vouloir effacer '+PathTem+' fichier(s)',$70);
   End;
  End;
  Repeat
   Case Language of
    _English:K:=ReadHorizontalCenterButton(14,'Delete|Cancel');
    _Germany:K:=ReadHorizontalCenterButton(14,'Lîschen|Abbrechen');
    _Italian:K:=ReadHorizontalCenterButton(14,'Cancella|Annulla');
    _Spain:K:=ReadHorizontalCenterButton(14,'Borrar|Cancelar');
    Else K:=ReadHorizontalCenterButton(14,'Supprimer|Annuler');
   End;
   If K=kbEsc Then K:=1;
  Until K<=1;
  If K=0 Then Begin
   For I:=0 to NombreFichierX[Cote]-1 do Begin
    If(Accepte[Cote,I+1]=1)Then Begin
     PathTem:=PanelPath[Cote];
     If(PanelPath[Cote,Length(PanelPath[Cote])]<>'\')Then PathTem := PanelPath[Cote] + '\';
     PathTem:=PathTem+Trim(Path2Name(Nom[Cote,I+1]))+Path2Ext(Nom[Cote,I+1]);
     FrameFull(36-(Length(PathTem) div 2),9,44+(Length(PathTem) div 2),18,$70);
     WriteCenter(12,'Efface le fichier :',$7E);
     WriteCenter(14,PathTem,$7E);
     If(DeleteFile(PathTem)<>1)Then Changement:=1;
    End;
   End;
  End;
 End;
 Refresh;
End;

Function CertainQuitter:Boolean;
Var
 K:Word;
Begin
 CertainQuitter:=False;
 FrameFull(11,10,71,15,$70);
 WriteCenter(11,' Le North Commander ',$70);
 Case Language of
  _English:WriteCenter(12,'Do you want to quit the North Commander?',$70);
  _Germany:WriteCenter(12,'Wollen Sie den North Commander beenden?',$70);
  _Italian:WriteCenter(12,'Uscire da North Commander?',$70);
  _Spain:WriteCenter(12,'Desea salir del Comandante North?',$70);
  Else WriteCenter(12,'Etes-vous certain de vouloir quitter ?',$70);
 End;
 Repeat
  Case Language of
   _English:K:=ReadHorizontalCenterButton(13,'Yes|No');
   _Germany:K:=ReadHorizontalCenterButton(13,'Ja|Nein');
   _Italian:K:=ReadHorizontalCenterButton(13,'S°|No');
   _Spain:K:=ReadHorizontalCenterButton(13,'S°|No');
   Else K:=ReadHorizontalCenterButton(13,'Oui|Non');
  End;
  If(K=kbEsc)Then K:=1;
 Until K<2;
 If K=0 Then CertainQuitter:=True
        Else Refresh;
End;

Procedure RereadPanel;Begin
 RefreshPanel(Cote);
End;

Procedure SwapPanels;
Var
 OldPanel:Byte;
 OldPath:String;
Begin
 OldPath:=PanelPath[0];
 PanelPath[0]:=PanelPath[1];
 PanelPath[1]:=OldPath;
 Cote:=(Cote+1) and 1;
 OldPanel:=PanelType[0];
 PanelType[0]:=PanelType[1];
 PanelType[1]:=OldPanel;
 ShowKeyFunc;
 Refresh;
End;

Procedure Done;Begin
 TextBackground(Black);
 ClrScr;
 Halt;
End;

Procedure TestExit;
Var
 Touche:Char;
Begin
 Write('DÇsirez-vous toujours continuer (O/N) ?');
 Repeat
  Touche := UpCase(ReadKey);
 Until Touche in['O','N'];
 If Touche='N'Then Done;
End;

Function GetCmdByExt(FileName:String;Var Cmd:String):Boolean;
Var
 NcExtFile:Text;
 I:Integer;
 Ext,CurrLine,CurrExt:String;
Begin
 GetCmdByExt:=False;
 Ext:=StrToUpper(Path2Ext(FileName));
 {$I-}Assign(NcExtFile,'NC.EXT');
 Reset(NcExtFile);{$I+}
 If IOResult=0 Then Begin
  While Not EOF(NcExtFile)do Begin
   ReadLn(NcExtFile,CurrLine);
   CurrExt:='.';
   For I:=1 to Length(CurrLine)do Begin
    If CurrLine[I]=':'Then Break
                      Else CurrExt:=CurrExt+CurrLine[I];
   End;
   If(StrToUpper(CurrExt)=Ext)Then Begin
    Cmd:=Trim(Copy(CurrLine,I+1,255));
    Cmd:=Replace(Cmd,'!.!',FileName);
    Cmd:=Replace(Cmd,'.!',Ext);
    GetCmdByExt:=True;
   End;
  End;
  Close(NcExtFile);
 End;
End;

Procedure ChangeParentDir;Begin
 Delete(PanelPath[Cote],Length(PanelPath[Cote]),1);
 While PanelPath[Cote,Length(PanelPath[Cote])]<>'\'do Delete(PanelPath[Cote],Length(PanelPath[Cote]),1);
 If(Length(PanelPath[Cote])<>3)Then Delete(PanelPath[Cote],Length(PanelPath[Cote]),1);
End;

Procedure EnterExecute;
Label 90;
Var
 Touche:Char;
 I:Integer;
 Cmd:String;
Begin
 TextColor(7);
 TextBackGround(0);
 If CurrCommand<>''Then Begin
  AddHistory(CurrCommand);
  CurrHistory:=NumberHistory;
  PathTem:=PanelPath[Cote];
  If PanelPath[Cote,Length(PanelPath[Cote])]<>'\'Then PathTem:=PanelPath[Cote]+'\';
  Dec(YP);
  GotoXY(1,1+YP);
  WriteLn(PathTem+'>'+CurrCommand);
  If(CurrCommand='COMSPEC')Then WriteLn(GetEnv('COMSPEC'))Else
  If CurrCommand<>''Then Begin
   ChaineTemporaire:=GetEnv('COMSPEC');
   If Not FileExist(ChaineTemporaire)Then Begin
    WriteLn('Erreur : COMMAND.COM introuvable!');
    TestExit;
   End;
   Exec(ChaineTemporaire,'/C'+CurrCommand);
   If(DosError=8)Then Begin
    WriteLn('Erreur : MÇmoire insuffisante!');
    TestExit;
   End
    else
   Case DosExitCode of
    1:WriteLn('Interrompu par Ctrl+C');
    2:WriteLn('Erreur de PÇriphÇrique');
    3:WriteLn('Terminaison en mode rÇsidant');
   End;
  End;
  CurrCommand:='';
  PositionCur:=0;
  TextColor(7);
  TextBackGround(0);
  Goto 90;
 End
  else
 If(PanelType[Cote]=4)Then Begin
  If(Attribt[Cote,PositionX[Cote]+1]=16)Then Begin
   If(Nom[Cote,PositionX[Cote]+1]='..')Then ChangeParentDir
    else
   Begin
    If Not(PanelPath[Cote,Length(PanelPath[Cote])]='\')Then PanelPath[Cote]:=PanelPath[Cote]+'\';
    PanelPath[Cote]:=PanelPath[Cote]+Nom[Cote,PositionX[Cote]+1];
   End;
   PositionX[Cote]:=0;
   YPos[Cote]:=0;
   Refresh;
  End
   else
  Begin
   If True Then Begin
    PathTem := PanelPath[Cote];
    If(PanelPath[Cote,Length(PanelPath[Cote])]<>'\')Then PathTem := PanelPath[Cote] + '\';
    GotoXY(1,1+YP);
    WriteLn;
    WriteLn(PathTem,'>',Nom[Cote,PositionX[Cote]+1]);
    WriteLn;
    WriteLn('Indication du RÇpertoire');
    Write(DuplicateString('-',40));
    WriteLn;
    UnPackTime(Temps[Cote,PositionX[Cote]+1],Date_Time);
    WriteLn('Date   : ',Date_Time.Year:4,'-',
                        Date_Time.Month:2,'-',
			Date_Time.Day:2);
    WriteLn('Heure  : ',Date_Time.Hour:2,':',
		        Date_Time.Min:2,':',
		        Date_Time.Sec:2);
    WriteLn('Taille : ',Taille[Cote,PositionX[Cote]+1]:8);
    ChaineTemporaire := Copy(Nom[Cote,PositionX[Cote]+1],9,4);
    If(ChaineTemporaire='.BAT')Then Begin
     ChaineTemporaire := GetEnv('COMSPEC');
     If Not FileExist(ChaineTemporaire)Then Begin
      WriteLn('Erreur : COMMAND.COM introuvable!');
      TestExit;
     End;
     Exec(ChaineTemporaire,'/C'+PathTem+Nom[Cote,PositionX[Cote]+1]);
     If(DosError=8)Then Begin
      WriteLn('Erreur : MÇmoire insuffisante !');
      TestExit;
     End
      else
     Case DosExitCode of
      1 : WriteLn('Interrompu par Ctrl+C');
      2 : WriteLn('Erreur de PÇriphÇrique');
      3 : WriteLn('Terminaison en mode rÇsidant');
     End;
    End;
    If(ChaineTemporaire='.EXE')or(ChaineTemporaire='.COM')Then Begin
     Exec(PathTem+Nom[Cote,PositionX[Cote]+1],'');
     WriteLn;
     If(DosError>0)Then Write('Erreur ',DosError:4,' : ');
     Case DosError of
      $00:Case DosExitCode of
       0 : Write('OpÇration rÇussit');
       1 : Write('Interrompu par Ctrl+C');
       2 : Write('Erreur de PÇriphÇrique');
       3 : Write('Terminaison en mode rÇsidant');
      End;
      $02 : WriteLn('Fichier non-trouvÇ');
      $08 : WriteLn('Pas assez de mÇmoire');
      $0A : WriteLn('Environnement invalide');
      $0B : WriteLn('Format invalide');
      $0F : WriteLn('Disque incorrect');
      $16 : WriteLn('Commande incorrect');
      $1A : WriteLn('Disque non-compatible au MS-DOS');
      $1E : WriteLn('Erreur de lecture');
      $57 : WriteLn('Paramätre incorrect');
       else
      WriteLn('Erreur : Inconnue');
     End;
    End
     Else
    If GetCmdByExt(GetCurrName,Cmd)Then Begin
     Exec(GetEnv('COMSPEC'),'/C '+Cmd);
    End
     Else
    WriteLn('Erreur : Extension incorrect');
90 :WriteLn;
    WriteLn('Presse une touche pour retourner au North Commander...');
    {    XP:=WhereX;
    YP:=WhereY;}
    Touche:=ReadKey;
    If(KeyPressed)Then Touche:=ReadKey;
    Touche:=#00;
    If(EGAMode)Then TextMode(C80+Font8x8)
               Else TextMode(C80);
    ShowKeyFunc;
    Refresh;
   End
    else
   Write(^G);
  End;
 End;
End;

Procedure Init;Begin
 FillChar(History,SizeOf(History),0);
 NumberHistory:=0;
 CurrHistory:=0;
 DoubleFrame:=True;
 TextMode(C80);
 If(WhereX>1)Then WriteLn;
 WriteLn('North Commandeur  - Clone Norton Commander');
 WriteLn;
 Menu:=0;
 Cote:=1;
 PanelType[0]:=PanelFile;
 PanelType[1]:=PanelFile;
 KeyBar:=True;
 TypeTri[0]:=0;
 TypeTri[1]:=0;
 PanelDisable[0]:=False;
 PanelDisable[1]:=False;
 XP:=0;
 YP:=23;
 PositionX[0]:=0;
 YPos[0]:=0;
 PositionX[1]:=0;
 YPos[1]:=0;
 CurrCommand:='';
 PosMenu:=0;
 PositionBar:=0;
 GetDir(0,PanelPath[0]);
 If PanelPath[0]=''Then Begin
  WriteLn('Erreur : RÇpertoire incorrect');
  WriteLn('Impossible de lancer l''exÇcution du NC');
  Write(^G);
  Halt;
 End;
 PanelPath[1]:=PanelPath[0];
 Refresh;
End;

Procedure SetOffFunctionKeyBar;Begin
 KeyBar:=False;
 GotoXY(1,MaxScreenLine);
 TextBackground(0);
 TextColor(7);
 ClrEol;
 ShowPrompt;
End;

Procedure SetOnFunctionKeyBar;Begin
 KeyBar:=True;
 ShowKeyFunc;
 ShowPrompt;
End;

Procedure ToggleFunctionKeyBar;Begin
 KeyBar:=Not KeyBar;
 If(KeyBar)Then SetOnFunctionKeyBar
           Else SetOffFunctionKeyBar;
End;

Procedure ToggleStatusPanel;Begin
 If PanelType[Cote xor 1]=4 Then PanelType[Cote xor 1]:=2
                            Else PanelType[Cote xor 1]:=4;
 RefreshPanels;
End;

Procedure ToggleInactivePanel;Begin
 PanelDisable[Cote xor 1]:=Not PanelDisable[Cote xor 1];
 RefreshPanels;
End;

Procedure TogglePanel;Begin
 If(Not PanelDisable[Cote])or(Not PanelDisable[Cote xor 1])Then Begin
  PanelDisable[Cote]:=True;
  PanelDisable[Cote xor 1]:=True;
 End
  Else
 Begin
  PanelDisable[Cote]:=False;
  PanelDisable[Cote xor 1]:=False;
 End;
 RefreshPanels;
End;

Procedure AffichageMenu(Position:Byte);
Var
 I:Integer;
Begin
 FrameChoice(1+Position*10,2,Position*10+3+LengthMenu[Position],HeightMenu[Position]+4);
 For I:=0 to HeightMenu[Position] do Begin
  Case Position of
   $00:WriteXY(3,3+I,MenuLeft[I],48);
   $01:WriteXY(13,3+I,MenuFiles[I],48);
   $02:WriteXY(23,3+I,MenuDisk[I],48);
   $03:WriteXY(33,3+I,MenuCommands[I],48);
   $04:WriteXY(43,3+I,MenuLeft[I],48);
  End;
 End;
End;

Procedure UnselectItemMenu(Position,PosItem:Byte);Begin
 Case Position of
  $00:WriteXY(3,3+PosItem,MenuLeft[PosItem],48);
  $01:WriteXY(13,3+PosItem,MenuFiles[PosItem],48);
  $02:WriteXY(23,3+PosItem,MenuDisk[PosItem],48);
  $03:WriteXY(33,3+PosItem,MenuCommands[PosItem],48);
  $04:WriteXY(43,3+PosItem,MenuLeft[PosItem],48);
 End;
End;

Procedure SelectItemMenu(Position,PosItem:Byte);Begin
 Case Position of
  $00:WriteXY(3,3+PosItem,MenuLeft[PosItem],15);
  $01:WriteXY(13,3+PosItem,MenuFiles[PosItem],15);
  $02:WriteXY(23,3+PosItem,MenuDisk[PosItem],15);
  $03:WriteXY(33,3+PosItem,MenuCommands[PosItem],15);
  $04:WriteXY(43,3+PosItem,MenuLeft[PosItem],15);
 End;
End;

Procedure ShowPullDnMenu;
Var
 I:Integer;
Begin
 Box(1,1,80,1,48);
 For I:=0 to High(MainMenuChoice) do WriteChoice(3+I*10,1,MainMenuChoice[I],62,48);
End;

Procedure UnselectFileBar;Begin
 If(PanelDisable[Cote])Then Exit;
 ShowLine(YPos[Cote],PositionX[Cote],Cote,False,True);
End;

Procedure SelectFileBar;Begin
 If(PanelDisable[Cote])Then Exit;
 ShowLine(YPos[Cote],PositionX[Cote],Cote,True,True);
 GotoXY(Length(PanelPath[Cote])+1+PositionCur+1,MaxScreenLine-1);
 ShowPanelStatusBar(Cote);
End;

Procedure ShowCommand;Begin
 GotoXY(Length(PanelPath[Cote])+2,MaxScreenLine-1);
 TextBackground(Black);
 TextColor(LightGray);
 Write(CurrCommand);
 ClrEol;
End;

Function DialogHistory:String;
Var
 K:Char;
 I:Byte;
 P,Y:LongInt;

 Procedure ShowItem;Begin
  TextColor(7);
  TextBackground(Black);
  GotoXY(24,4+Y);
  Write(PadRight(Copy(History[P]^,1,34),34));
  GotoXY(24,4+Y);
 End;

 Procedure HideItem;Begin
  TextColor(0);
  TextBackground(Cyan);
  GotoXY(24,4+Y);
  Write(PadRight(Copy(History[P]^,1,34),34));
 End;

 Procedure RefreshList;
 Var
  J:Byte;
 Begin
  TextColor(0);
  TextBackground(Cyan);
  For J:=1 to 19 do Begin
   GotoXY(24,3+J);
   Write(PadRight(Copy(History[P-Y+J-1]^,1,34),34));
  End;
 End;

Begin
 P:=1;Y:=0;
 DialogHistory:='';
 If NumberHistory<20 Then Begin
  Box(19,2,61,NumberHistory+5,$3F);
  FrameEmpty(22,3,58,NumberHistory+4,$3F);
 End
  Else
 Begin
  Box(19,2,61,23,$3F);
  FrameEmpty(22,3,58,22,$3F);
 End;
 Case Language of
  _English:WriteCenter(3,' History ',$3F);
  Else WriteCenter(3,' Historique ',$3F);
 End;
 For I:=1 to NumberHistory do Begin
  If I>=20 Then Break;
  GotoXY(24,3+I);
  Write(History[I]^);
 End;
 ShowItem;
 Repeat
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #72:If P>1 Then Begin { Up }
     HideItem;
     Dec(P);
     If Y>0 Then Dec(Y)
            Else RefreshList;
     ShowItem;
    End;
    #80:If P<NumberHistory Then Begin { Down }
     HideItem;
     Inc(P);
     If Y<18 Then Inc(Y)
             Else RefreshList;
     ShowItem;
    End;
   End;
   #13:Begin
    DialogHistory:=History[P]^;
    Refresh;
    CurrCommand:=History[P]^;
    PositionCur:=Length(CurrCommand);
    ShowCommand;
    Exit;
   End;
  End;
 Until K=#27;
 Refresh;
End;

Procedure PullDnMenu;
Var
 K:Char;
 PosItem:Byte;
Begin
 ShowPullDnMenu;
 WriteXY(3+PosMenu*10,1,MainMenuChoice[PosMenu],15);
 AffichageMenu(PosMenu);
 PosItem:=0;
 SelectItemMenu(PosMenu,PosItem);
 Repeat
  K:=ReadKey;
  If(KeyPressed)Then K:=ReadKey;
  Case(K)of
   #13:Begin
    Case(PosMenu)of
     0:Begin { Left }
      Case PosItem of
       0:PanelType[0]:=0;
       1:PanelType[0]:=1;
       2:PanelType[0]:=2;
       3:PanelType[0]:=3;
       4:PanelType[0]:=4;
       5:PanelType[0]:=5;
       6:PanelType[0]:=4;
       7:PanelType[0]:=6;
       8:TypeTri[0]:=0;
       9:TypeTri[0]:=1;
       10:TypeTri[0]:=2;
       11:TypeTri[0]:=3;
       12:TypeTri[0]:=4;
       13:Refresh;
       14:DialogNotImplement;
       15:ChangeDrive(0);
      End;
      Break;
     End;
     1:Begin { Files }
      Case PosItem of
       0:HelpFunc;
       1:MenuFunc;
       2:ViewFunc;
       3:EditFunc;
       4:CopyFunc;
       5:RenMovFunc;
       6:MkDirFunc;
       7:DeleteFunc;
       8..12:DialogNotImplement;
       13:If(CertainQuitter)Then Terminated:=True;
      End;
      Break;
     End;
     2:Begin { Disk }
      DialogNotImplement;
      Break;
     End;
     3:Begin { Commands }
      Case PosItem of
       2:DialogHistory;
       Else DialogNotImplement;
      End;
      Break;
     End;
     4:Begin { Right }
      Case PosItem of
       0:PanelType[1]:=0;
       1:PanelType[1]:=1;
       2:PanelType[1]:=2;
       3:PanelType[1]:=3;
       4:PanelType[1]:=4;
       5:PanelType[1]:=5;
       6:PanelType[1]:=4;
       7:PanelType[1]:=6;
       8:TypeTri[1]:=0;
       9:TypeTri[1]:=1;
       10:TypeTri[1]:=2;
       11:TypeTri[1]:=3;
       12:TypeTri[1]:=4;
       13:Refresh;
       14:DialogNotImplement;
       15:ChangeDrive(1);
      End;
      Break;
     End;
    End;
   End;
   #72:Begin
    UnselectItemMenu(PosMenu,PosItem);
    If PosItem=0Then PosItem:=HeightMenu[PosMenu]
                Else PosItem:=PosItem-1;
    SelectItemMenu(PosMenu,PosItem);
   End;
   #75,#115:Begin
    RefreshPanels;
    ShowPullDnMenu;
    WriteChoice(3+PosMenu*10,1,MainMenuChoice[PosMenu],62,48);
    If PosMenu=0Then PosMenu:=High(MainMenuChoice)
                Else PosMenu:=PosMenu - 1;
    WriteXY(3+PosMenu*10,1,MainMenuChoice[PosMenu],15);
    AffichageMenu(PosMenu);
    PosItem:=0;
    SelectItemMenu(PosMenu,PosItem);
   End;
   #77,#116:Begin
    RefreshPanels;
    ShowPullDnMenu;
    WriteChoice(3+PosMenu*10,1,MainMenuChoice[PosMenu],62,48);
    PosMenu:=(PosMenu+1) mod 5;
    WriteXY(3+PosMenu*10,1,MainMenuChoice[PosMenu],15);
    AffichageMenu(PosMenu);
    PosItem:=0;
    SelectItemMenu(PosMenu,PosItem);
   End;
   #80:Begin
    UnselectItemMenu(PosMenu,PosItem);
    PosItem:=(PosItem+1)mod (HeightMenu[PosMenu]+1);
    SelectItemMenu(PosMenu,PosItem);
   End;
  End;
 Until K=#27;
 RefreshPanels;
End;

Procedure EGALn;Begin
 EGAMode:=Not EGAMode;
 If(EGAMode)Then Begin
  TextMode(CO80+Font8x8);
  MaxScreenLine:=43;
  SideLength[0]:=35;
  SideLength[1]:=35;
 End
  Else
 Begin
  TextMode(CO80);
  MaxScreenLine:=25;
  SideLength[0]:=17;
  SideLength[1]:=17;
 End;
 Refresh;
End;

Procedure Run;
Label 20;
Var
 K:Char;
Begin
 Terminated:=False;
 Repeat
  If(Menu=0)and(PanelType[Cote]=4)Then SelectFileBar;
  GotoXY(Length(PanelPath[Cote])+1+PositionCur+1,MaxScreenLine-1);
  K:=ReadKey;
  If(KeyPressed)Then Begin
   K:=ReadKey;
   Case K of
    #59:HelpFunc;   { F1 }
    #60:MenuFunc;   { F2 }
    #61:ViewFunc;   { F3 }
    #62:EditFunc;   { F4 }
    #63:CopyFunc;   { F5 }
    #64:RenMovFunc; { F6 }
    #65:MkDirFunc;  { F7 }
    #66:DeleteFunc; { F8 }
    #67:PullDnMenu; { F9 }
    #68:Begin
     If(CertainQuitter)Then Terminated:=True;
    End;
    #71:If(PanelType[Cote]=4)Then Begin { Home }
     PositionX[Cote]:=0;
     YPos[Cote]:=0;
     UpdateBoard;
     SelectFileBar;
    End;
    #72:If Not(PanelDisable[Cote])Then Begin { Up }
     If(PanelType[Cote]=4)Then Begin
      If(PositionX[Cote]>0)Then Begin
       UnselectFileBar;
       Dec(PositionX[Cote]);
       Numerique:=40*Cote;
       If(YPos[0]=0)And(Cote=0)Then Begin
        MoveWindow(Numerique+2,3,Numerique+39,3+SideLength[Cote],27,1);
        ShowLine(0,PositionX[0],0,False,True);
        GotoXY(1+PositionCur,MaxScreenLine-1);
       End
        Else
       If(YPos[1]=0)And(Cote=1)Then Begin
        MoveWindow(Numerique+2,3,Numerique+39,3+SideLength[Cote],27,1);
        ShowLine(0,PositionX[1],1,False,True);
        GotoXY(1+PositionCur,MaxScreenLine-1);
       End
        Else
       If(YPos[Cote]>0)Then Dec(YPos[Cote]);
      End;
     End;
    End;
    #79:If PanelType[Cote]=4 Then Begin { End }
     PositionX[Cote]:=NombreFichierX[Cote]-1;
     If NombreFichierX[Cote]<SideLength[Cote]Then Begin
      YPos[Cote]:=NombreFichierX[Cote]-1;
     End
      Else
     Begin
      YPos[Cote]:=SideLength[Cote];
     End;
     UpdateBoard;
     SelectFileBar;
    End;
    #80:If Not(PanelDisable[Cote])Then Begin { Down }
     If PanelType[Cote]=4 Then Begin
20:   If(PositionX[Cote]<NombreFichierX[Cote]-1)Then Begin
       UnselectFileBar;
       Inc(PositionX[Cote]);
       If(YPos[Cote]=SideLength[Cote])Then Begin
        Numerique:=40*Cote;
        MoveWindow(Numerique+2,3,Numerique+39,3+SideLength[Cote],27,-1);
        SelectFileBar;
       End
        Else
       If(YPos[Cote]<SideLength[Cote])Then Inc(YPos[Cote]);
      End;
     End;
    End;
    #82:Begin
     If(Attribt[Cote,PositionX[Cote]+1]<16)and(PanelType[Cote]=4)Then Begin
      If(Accepte[Cote,PositionX[Cote]+1]=0)Then Begin
       Accepte[Cote,PositionX[Cote]+1]:=1;
       Inc(Nombre[Cote]);
      End
       Else
      Begin
       Accepte[Cote,PositionX[Cote]+1]:=0;
       Dec(Nombre[Cote]);
      End;
      ShowLine(YPos[Cote],PositionX[Cote],Cote,False,True);
      K:=#00;
      Goto 20;
     End;
    End;
    #102:SetOffFunctionKeyBar;
    #103:SetOnFunctionKeyBar;
    #104:Begin { Alt+F1 }
     Cote:=0;
     ChangeDrive(0);
    End;
    #105:Begin { Alt+F2 }
     Cote:=1;
     ChangeDrive(1);
    End;
    #111:DialogHistory; { Alt+F8 }
    #112:EGALn; { Alt+F9 }
    #132:Begin { Ctrl+PgUp }
     ChangeParentDir;
     PositionX[Cote]:=0;
     YPos[Cote]:=0;
     RefreshPanel(Cote);
    End;
   End;
  End
   Else
  Begin
   Case K of
    #8:Begin
     If Length(CurrCommand)>0 Then Begin
      Delete(CurrCommand,Length(CurrCommand),1);
      Dec(PositionCur);
     End;
     ShowCommand;
    End;
    #9:If(PanelType[Cote xor 1]=4)and(Not PanelDisable[Cote xor 1])Then Begin
     UnselectFileBar;
     UnshowPanelPath;
     Cote:=Cote xor 1;
     SelectFileBar;
     ShowPanelPath;
    End;
    ^B:ToggleFunctionKeyBar;
    ^E:If NumberHistory>0 Then Begin
     CurrCommand:=History[CurrHistory]^;
     If CurrHistory>1 Then Dec(CurrHistory);
     ShowCommand;
     PositionCur:=Length(CurrCommand);
    End;
    ^L:ToggleStatusPanel;
    ^M:EnterExecute;
    ^O:TogglePanel;
    ^P:ToggleInactivePanel;
    ^R:RereadPanel;
    ^U:SwapPanels;
    ^X:If NumberHistory>0 Then Begin
     CurrCommand:=History[CurrHistory]^;
     If CurrHistory<NumberHistory Then Inc(CurrHistory);
     ShowCommand;
     PositionCur:=Length(CurrCommand);
    End;
    ^Y,#27:Begin { Ctrl+Y ou Esc }
     CurrCommand:='';
     PositionCur:=0;
     ShowCommand;
    End;
    #28:Begin { Ctrl+\ }
     PanelPath[Cote]:=PanelPath[Cote][1]+':\';
     PositionX[Cote]:=0;
     YPos[Cote]:=0;
     RefreshPanel(Cote);
    End;
   End;
   If(K>#31)And(PositionCur<79)Then Begin
    CurrCommand:=CurrCommand+K;
    GotoXY(Length(PanelPath[Cote])+1+PositionCur+1,MaxScreenLine-1);
    TextBackground(Black);
    TextColor(LightGray);
    Write(K);
    Inc(PositionCur);
   End;
  End;
 Until Terminated;
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
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='SQ')or
    (StrToUpper(Copy(TmpLanguage,1,3))='ALB')Then Language:=_Albanian;
 End;
 ShowASCII128:=False;
 EGAMode:=False;
 MaxScreenLine:=25;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('NC: Dieser Befehl startet den Dateimanager.');
    WriteLn;
    WriteLn('Syntax: NC [/ASCII128]');
    WriteLn;
    WriteLn(' /ASCII128   Mit diesem Parameter kînnen nur 128 Zeichen ',
                          'im KompatibilitÑtsmodus gestartet werden.');
    WriteLn(' --version   Mit diesem Parameter kînnen Sie die Version ',
                          'des Befehls anfordern.');
    Halt;
   End;
   _English:Begin
    WriteLn('NC: This command launches the file manager.');
    WriteLn;
    WriteLn('Syntax: NC [/ASCII128]');
    WriteLn;
    WriteLn(' /ASCII128    This parameter allows 128 characters only ',
                           'to be launched in compatibility mode.');
    WriteLn('--version     This parameter allows you to request the ',
                           'version of the command');
    Halt;
   End;
   _Italian:Begin
    WriteLn('NC: Questo comando avvia il file manager.');
    WriteLn;
    WriteLn('Sintassi: NC [/ASCII128]');
    Halt;
   End;
   Else Begin
    WriteLn('NC : Cette commande permet de lancer le gestionnaire de fichiers.');
    WriteLn;
    WriteLn('Syntaxe : NC [/ASCII128]');
    WriteLn;
    WriteLn(' /ASCII128   Ce paramätre permet de lancer en mode compatibilite ',
                          '128 caractäres seulement.');
    WriteLn(' --version   Ce paramätre permet de demander la version de la commande');
    Halt;
   End;
  End;
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('NC ',Version,' - Clone Pascal de Norton Commander - North Commander');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('êcrit par Sylvain Maltais');
  Halt;
 End
  Else
 If ParamCount>0Then Begin
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/ASCII128'Then ShowASCII128:=True
    Else
   Begin
    Case Language of
     _English:WriteLn('Unknown parameter : ',ParamStr(I));
     Else WriteLn('Paramätre inconnu : ',ParamStr(I));
    End;
    Halt;
   End;
  End;
 End;
 Init;
 Run;
 Done;
END.
