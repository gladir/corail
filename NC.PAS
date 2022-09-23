{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program NorthCommander;

{$M 8192,0,65556}

Uses Crt,Dos;

Const
 MinCote=0;
 MaxCote=1;
 MaxFiles=511;

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
  'Renommer/deplacer',
  'Cree un repertoire',
  'Supprimer',
  'Attribut de fichiers',
  'Selectionner un groupe',
  'Deselectionner un groupe',
  'Inverser la selection',
  'Restaurer la selection',
  'Quitter'
  );

  MenuDisk:Array[0..4]of String[30]=(
   'Copier une disquette...',
   'Formater une disquette...',
   'Nommer un disque',
   'Utilitaire reseau...',
   'Nettoyage disque...'
  );

  MenuCommands:Array[0..12] of String[26]=(
   'Arbre NCD',
   'Recherche de fichiers',
   'Historique',
   'Ligne EGA',
   'Permuter les panneaux',
   'Afficher/effacer les panneaux',
   'Compare les repertoires',
   'Synchroniser les repertoires',
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

Var
 I:Integer;
 ShowASCII128:Boolean;
 Nombre:Array[0..1] of 0..511;
 PositionX:Array[0..1] of 0..511;
 YPos:Array[0..1] of 0..17;
 PanelPath:Array[0..1] of PathStr;
 PanelType:Array[0..1] of 0..7;
 PanelDisable:Array[0..1]of Boolean;
 PathTem:PathStr;
 Tem:String[4];
 PositionCur:0..79;
 XP,YP,Xa,Ya,PosMenu,Cote,Vg,Menu:Byte;
 PositionBar:0..PanelHeightSize;
 KeyBar:Boolean;
 CurrCommand:PathStr;
 Date_Time:DateTime;
 ChaineTemporaire:String[64];
 Numerique:Word;
 XS,YS:Word;
 BS:Word;

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

Procedure Box(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Window(X1+1,Y1+1,X2+1,Y2+1);
 TextBackground((Couleur shr 4)and 15);
 TextColor(Couleur and 15);
 ClrScr;
 Window(1,1,80,25);
End;

Procedure Write1(X,Y,Caractere,Couleur:Byte);Begin
 GotoXY(X+1,Y+1);
 TextBackground((Couleur shr 4)and 15);
 TextColor(Couleur and 15);
 Write(Char(Caractere));
End;

Procedure WriteXY(X,Y:Byte;Phrase:String;Couleur:Byte);Begin
 TextBackground((Couleur shr 4)and 15);
 TextColor(Couleur and 15);
 GotoXY(X+1,Y+1);
 Write(Phrase);
End;

Procedure WriteChoice(X,Y:Byte;Phrase:String;Couleur1,Couleur2:Byte);Begin
 Write1(X,Y,Ord(Phrase[1]),Couleur1);
 WriteXY(X+1,Y,Copy(Phrase,2,255),Couleur2);
End;

Procedure WriteCenter(Y:Byte;Phrase:String;Couleur:Byte);Begin
 WriteXY(40 - Length(Phrase) div 2,Y,Phrase,Couleur);
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
  ChrHori:=#$C4;
  ChrVert:=#$B3;
  Chr218:=#218;
  Chr192:=#192;
  Chr191:=#191;
  Chr217:=#217;
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

Procedure FrameFull(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Box(X1,Y1,X2,Y2,Couleur);
 FrameEmpty(X1+2,Y1+1,X2-2,Y2-1,Couleur);
End;

Procedure MoveWindow(X1,Y1,X2,Y2,Couleur:Byte;Direction:Integer);Begin
 Window(X1+1,Y1+1,X2+1,Y2+1);
 If Direction<0Then Begin
  GotoXY(1,1);
  DelLine;
 End
  Else
 Begin
  GotoXY(1,1);
  InsLine;
 End;
 Window(1,1,80,25);
End;

Procedure FrameChoice(X1,Y1,X2,Y2:Byte);
Var
 I:Integer;
Begin
 Box(X1,Y1,X2,Y2,63);
 Write1(X1,Y1,218,63);
 Write1(X1,Y2,192,63);
 For I:=X1+1 to X2-1 do Begin
  Write1(I,Y1,$C4,63);
  Write1(I,Y2,$C4,63);
 End;
 For I:=Y1+1 to Y2-1 do Begin
  Write1(X1,I,$B3,63);
  Write1(X2,I,$B3,63);
 End;
End;

Type StrName = String[12];

Var
 Nom              : Array[MinCote..MaxCote,0..MaxFiles] of StrName;
 Temps            : Array[MinCote..MaxCote,0..MaxFiles] of LongInt;
 Taille           : Array[MinCote..MaxCote,0..MaxFiles] of LongInt;
 Attribt          : Array[MinCote..MaxCote,0..MaxFiles] of Byte;
 Accepte          : Array[MinCote..MaxCote,0..MaxFiles] of 0..1;
 NombreFichierX   : Array[MinCote..MaxCote] of 0..MaxFiles;
 TypeTri          : Array[MinCote..MaxCote] of 0..4;

Procedure DisqueNonPret(Disque:Byte);
Var
  Registre:Registers;
  OK:Boolean;
  Touche:Char;
Begin
 OK := False;
 Repeat
  Box(11,11,68,12,$4F);
  FrameEmpty(10,10,69,13,$4F);
  WriteCenter(11,'Disque '+Chr(Disque+65)+' pas pret',$4F);
  WriteCenter(12,'Mettre la disquette et presse une touche',$4E);
  Touche := UpCase(ReadKey);
  If(KeyPressed)Then
  Begin
   Touche := ReadKey;
   Touche := #0;
  End;
  Registre.AH := $1C;
  Registre.DL := Disque + 1;
  MsDos(registre);
  If(Registre.AL<>$FF)Then OK := True;
 Until OK;
End;

Function Volume(Drive:Char):PathStr;
Var Palette : SearchRec;
    Erreur  : Integer;
Begin
 Volume := 'Aucun';
 FindFirst(Drive + ':\*.*',VolumeID,Palette);
 Erreur := DosError;
 If(Erreur = 0)Then Volume := Palette.Name
  else
 If(ERREUR=152)Then
 Begin
  Repeat
   DisqueNonPret(Ord(Drive)-65);
   FindFirst(Drive + ':\*.*',VolumeID,Palette);
   Erreur := DosError;
   If(Erreur = 0)Then Volume := Palette.Name;
  Until (Erreur <> 152);
 End;
End;

Procedure ReadFiles(Chaine:PathStr;Attribut:Word;Cote:Byte);
Var Compteur,Position : Word;
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
    Date_TimeB	      : DateTime;
    Palette	      : SearchRec;
    Directory 	      : DirStr;
    FileName  	      : NameStr;
    Extension 	      : ExtStr;
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
 Position 	      := 1;
 FindFirst(Chaine,$FFF7,Palette);
 Erreur := DOSERROR;
 While ((Erreur = 0)or(Erreur = 152)) do Begin
  If(Erreur = 152)Then DisqueNonPret(Ord(Chaine[1])-65);
  If((Palette.Name <> '.')and(Erreur=0))Then Begin
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
  Erreur := DOSERROR;
 End;
 NombreFichierX[Cote] := Position - 1;
 Case TypeTri[Cote] of
  0 : TriNom;
  1 : TriExtension;
  2 : TriHeure;
  3 : TriTaille;
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
 GotoXY(1,24);
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
 If(Ligne <= NombreFichierX[Cote])Then Begin
  If(Selected)Then Begin
   If(Accepte[Cote,Ligne]=0)Then Couleur := 48 else Couleur := 62;
  End
   Else
  Begin
   If(Accepte[Cote,Ligne] = 0)Then Couleur := 31 else Couleur := 30;
  End;
  TextColor(Couleur and $F);
  TextBackground((Couleur shr 4)and 7);
  GotoXY(Cote*40+2,Y+3);
  Write(PadRight(Nom[Cote,Ligne],12),ChrVert);
  If(Attribt[Cote,Ligne] <> 16)Then Write(Taille[Cote,Ligne]:8) Else
  If(Attribt[Cote,Ligne]=16)Then Begin
   If(Nom[Cote,Ligne]='..')Then Write('SOUS-REP')
                           Else Write('SUR-REP ');
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

Procedure RefreshPanel;
Var
 I,J:Byte;
 Couleur:Byte;
 ChrVert:Char;
Begin
 If(ShowASCII128)Then ChrVert:='|'
                 Else ChrVert:=#179;
 For I:=0 to 1 do Begin
  If(PanelDisable[I])Then Begin
   Box(40*I,0,40*I+39,20,7);
  End
   Else
  Case PanelType[I]of
   2:Begin
    Box(40*I+1,0,40*I+38,20,31);
    FrameEmpty(40*I,0,40*I+39,21,31);
    WriteXY(40*I+13,2,'€ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€',31);
    WriteXY(40*I+13,3,'€ Information €',31);
    WriteXY(40*I+13,4,'€‹‹‹‹‹‹‹‹‹‹‹‹‹€',31);
    WriteXY(40*I+2,6,'Repertoire :',31);
    WriteXY(40*I+2,7,PanelPath[1],30);
    TextBackGround(1);
    TextColor(11);
    WriteXY(40*I+2,14,'Nombre de Fichier :',31);
    GotoXY(40*I+23,15);
    Write(NombreFichierX[1]:7,' Fichiers');
    WriteXY(40*I+2,13,'Volume            :',31);
    GotoXY(40*I+23,14);
    Write(Volume(PanelPath[1,1]));
    WriteXY(40*I+2,15,'Taille disque     :',31);
    GotoXY(40*I+23,16);
    Write(DiskSize(Ord(PanelPath[1,1])-64):9,' Octets');
    WriteXY(40*I+2,16,'Espace libre      :',31);
    GotoXY(40*I+23,17);
    Write(DiskFree(Ord(PanelPath[1,1])-64):9,' Octets');
    WriteXY(40*I+2,18,'Version du MS-DOS :',31);
    GotoXY(40*I+23,19);
    Write(Lo(DosVersion),'.',Hi(DosVersion));
    WriteXY(40*I+2,19,'MÇmoire total     :',31);
    GotoXY(40*I+23,20);
    Write(RAMSize:9,' Octets');
    WriteXY(40*I+2,20,'MÇmoire libre     :',31);
    GotoXY(40*I+23,21);
    Write(640*1024:9,' Octets');
   End;
   4:Begin
    FrameEmpty(40*I,0,40*I+39,5+SideLength[I],31);
    WriteXY(40*I+1,1,'   Nom   Ext'+ChrVert+' Taille '+ChrVert+
          '   Date   '+ChrVert+'Heure',30);
    If(PanelPath[I,Length(PanelPath[I])]<>'\')Then PathTem:=PanelPath[I]+'\'
                                              Else PathTem:=PanelPath[I];
    ReadFiles(PathTem+'*.*',$FFFF,I);
    For J:=0 to SideLength[Cote] do ShowLine(J,J,I,False,True);
    If Cote=0Then Couleur:=49
             Else Couleur:=31;
    WriteXY(40*I+20-((Length(PanelPath[I])+2) div 2),0,' '+PanelPath[I]+' ',Couleur);
    If NombreFichierX[I]<=SideLength[I]Then Box(40*I+1,NombreFichierX[I]+2,40*I+38,SideLength[I]+2,31);
    GotoXY(40*I+2,21);
    TextBackground(Blue);
    TextColor(White);
    Write(DuplicateString('-',38));
   End;
  End;
 End;
End;

Procedure ShowKeyFunc;
Const
 FunctionKeyValue:Array[0..9]of String[7]=(
  'Aide','Menu','Affich','Editer','Copier','RenDep','CreRep','Suppr.','Menu','Sortie'
 );
Var
 I:Byte;
Begin
 TextBackground(Black);
 TextColor(LightGray);
 GotoXY(1,25);
 Write('1');
 For I:=1 to 8 do Begin
  GotoXY(I*8,25);
  Write(' ',I+1);
 End;
 TextBackground(Cyan);
 TextColor(Black);
 For I:=0 to 8 do Begin
  GotoXY(I*8+2,25);
  Write(PadRight(FunctionKeyValue[I],6));
 End;
 TextBackground(Black);
 TextColor(LightGray);
 GotoXY(71,25);
 Write(' 10');
 TextBackground(Cyan);
 TextColor(Black);
 GotoXY(74,25);
 Write(FunctionKeyValue[9]);
 ClrEol;
End;

Procedure ShowPanelStatusBar(Cote:Byte);Begin
 If PanelDisable[Cote]Then Exit;
 If PanelType[Cote]<>4Then Exit;
 If Nombre[Cote]>0Then Begin
  TextBackground(Blue);
  TextColor(Yellow);
  GotoXY(40*Cote+2,22);
  Write(Nombre[Cote],' fichiers selectionnes    ');
 End
  Else
 ShowLine(19,PositionX[Cote],Cote,False,False);
End;

Procedure Refresh;
Var
 I:Byte;
Begin
 RefreshPanel;
 For I:=0 to 1 do ShowPanelStatusBar(I);
 Nombre[0]:=0;
 Nombre[1]:=0;
 ShowKeyFunc;
 ShowPrompt;
 ChDir(PanelPath[Cote]);
 CurrCommand:='';
End;

Procedure Change(Cote:Binaire);
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
 OK := 0;
 FrameFull(BoxX1,7,BoxX2,12,$70);
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
 Refresh;
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


Procedure DialogNotImplement;Begin
 FrameFull(10,9,70,16,$70);
 WriteCenter(12,'Cette fonctionnalite n''est pas implante',$70);
 WriteXY(38,14,' Ok ',$0F);
 ReadKey;
End;

Procedure ErrorOk(Msg:String);Begin
 FrameFull(10,9,70,16,$4F);
 WriteCenter(12,Msg,$40);
 WriteXY(38,14,' Ok ',$30);
 ReadKey;
End;

Procedure HelpFunc;Begin
 DialogNotImplement;
 Refresh;
End;

Procedure MenuFunc;Begin
 DialogNotImplement;
 Refresh;
End;

Procedure ViewFunc;
Var
 Finish:Boolean;
 FileView:File{$IFDEF FPC}of Byte{$ENDIF};
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
   GotoXY(I*7+1+2,25);
   Write(PadRight(FunctionKeyValue[I],6));
  End;
  GotoXY(67,25);
  Write(FunctionKeyValue[9]);
  ClrEol;
  TextBackground(Black);
  TextColor(LightGray);
  For I:=0 to 9 do Begin
   GotoXY(I*7+1,25);
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
  TextBackground(Black);
  TextColor(LightGray);
  GotoXY(1,2);
  X:=1;
  J:=0;
  PosInBuffer:=0;
  While(J<23)and(PosInBuffer<2048)do Begin
   Case(Buffer[PosInBuffer])of
    13:Begin
     ClrEol;
     WriteLn;
     X:=1;
     Inc(J);
     If Buffer[PosInBuffer+1]=10Then Inc(PosInBuffer);
     If J=23Then Break;
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
    If J=23Then Break;
   End;
   Inc(PosInBuffer);
  End;
  If J<23Then Begin
   Window(1,1+J,80,22);
   ClrScr;
   Window(1,1,80,25);
  End;
  ViewASCII:=PosInBuffer;
 End;

Begin
 FileName:=GetCurrName;
 Assign(FileView,FileName);
 {$I-}Reset(FileView{$IFNDEF FPC},1{$ENDIF});{$I+}
 If IoResult<>0Then Begin
  FrameFull(10,9,70,16,$4F);
  WriteCenter(12,'Probleme de lecture du fichier :',$40);
  WriteCenter(13,FileName,$40);
  WriteXY(38,14,' Ok ',$0F);
  ReadKey;
  Refresh;
  Exit;
 End;
 CurrPos:=0;
 ClrScr;
 ViewFrameASCII;
 Finish:=False;
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
        If CurrLinePos>=24Then Begin
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
 Refresh;
End;

Procedure EditFunc;Begin
 Exec('NCEDIT.EXE',GetCurrName);
 Refresh;
End;

Procedure RenMovFunc;Begin
 DialogNotImplement;
 Refresh;
End;

Procedure MkDirFunc;
Var
 Touche:Char;
 Chaine8:PathStr;
 Position:Byte;
 Erreur:Word;
 Tableau:Pointer;
 Changement:Byte;
Begin
 Changement:=0;
 FrameFull(8,5,71,18,63);
 WriteCenter(8,'Creation d''un repertoire',62);
 WriteXY(12,10,'Nom du repertoire a creer :',62);
 Write1(31,12,91,63);
 Write1(49,12,93,63);
 For Position := 0 to 7 do Begin
  Write1(33+Position*2,12,32,15);
  Write1(33+Position*2,13,196,63);
 End;
 WriteXY(12,15,'Longueur :',63);
 WriteXY(39,15,'Disque :',63);
 WriteXY(48,15,Copy(PanelPath[Cote],1,1),62);
 Position := 0;
 Erreur   := 0;
 Chaine8  := '';
 PathTem  := '';
 Repeat
  Str(Position+1,PathTem);
  WriteXY(22,15,PathTem,62);
  GotoXY(34+Position*2,13);
  Touche:=ReadKey;
  If KeyPressed Then
  Begin
   Touche := ReadKey;
   Case Touche of
     #71 : Position := 0;
     #75 : Position := (Position - 1) and 7;
     #77 : Position := (Position + 1) and 7;
    End;
    Touche := #00;
   End;
   Case Touche of
    #08 : Begin
  	   If(Position > 0)Then Begin
	    Dec(Position);
	    Chaine8[Position] := #32;
	    Write1(33+Position*2,12,32,15);
	   End;
	  End;
    #13 : Begin
	   PathTem:=PanelPath[Cote];
	   If(PathTem[Length(PathTem)] <> '\')Then PathTem := PathTem + '\';
	   PathTem := PathTem + Chaine8 + #00;
           {$I-}
           MkDir(PathTem);
           Erreur:=IoResult;
           {$I+}
           If(Erreur<>0)Then Begin
            Box(11,12,68,14,$4F);
            FrameEmpty(10,11,69,15,$4F);
            WriteCenter(12,'Erreur : De rÇpertoire',$4F);
            WriteCenter(13,'Impossible de crÇe le rÇpertoire',$4F);
            WriteCenter(14,'Presse une touche pour retourner',$4E);
            Write(^G);
            Touche := ReadKey;
            If(KeyPressed)Then Touche := ReadKey;
           End
            else
           Changement := 1;
	   Touche := #27;
	  End;
   End;
   If(Touche > #31)and(Not(Touche in ['?','*']))and(Position < 8)Then Begin
    Chaine8 := Copy(Chaine8,1,Position) + UpCase(Touche) + Copy(Chaine8,Position + 1,8);
    Write1(33+Position*2,12,Ord(UpCase(Touche)),15);
    If(Position < 7)Then Inc(Position);
   End
    else
   If(Touche > #31)Then Write(^G);
  Until (Touche = #27);
 Refresh;
End;

Procedure DeleteFunc;
Var
 Touche:Char;
 I:Integer;
 Changement:Byte;
 Vd:String;
Begin
 Changement:=0;
 If(Nombre[Cote] = 0)And(Attribt[Cote,PositionX[Cote]+1] = 16)Then Begin
  GetDir(0,Vd);
  Chdir(PanelPath[Cote]);
  {$I-}RmDir(Nom[Cote,PositionX[Cote]+1]);{$I+}
  If(IoResult<>0)Then;
  ChDir(Vd);
  Changement:=1;
 End
  Else
 If(Nombre[Cote] = 0)And(Attribt[Cote,PositionX[Cote]+1] < 16)Then Begin
  Box(11,12,68,14,$4F);
  FrameEmpty(10,11,69,15,$4F);
  WriteCenter(12,'Es-tu certain de vouloir effacer :',$4F);
  WriteCenter(13,Nom[Cote,PositionX[Cote]+1],$4F);
  WriteCenter(14,'Presse <ESC> pour retourner',$4E);
  Repeat
   Touche:=ReadKey;
   If(KeyPressed)Then Begin
    Touche:=ReadKey;
    Touche:=#0;
   End;
  Until Touche in [#13,#27];
  If Touche<>#27Then Begin
   PathTem:=PanelPath[Cote];
   If(PanelPath[Cote,Length(PanelPath[Cote])]<>'\')Then PathTem := PanelPath[Cote] + '\';
   PathTem:=PathTem+Nom[Cote,PositionX[Cote]+1];
   If(DeleteFile(PathTem)<>-1)Then Changement := 1;
  End;
 End
  else
 Begin
  FrameFull(19,8,59,17,$4F);
  Str(Nombre[Cote],PathTem);
  WriteCenter(11,'Etes-vous certain de vouloir',$4E);
  WriteCenter(12,'effacer '+PathTem+' fichier(s)',$4E);
  {CrossNextGeneration;}
  Touche := ReadKey;
  If(KeyPressed)Then Touche := ReadKey;
  If(Touche in ['O','o','Y','y',#13])Then Begin
   For I:=0 to NombreFichierX[Cote]-1 do Begin
    If(Accepte[Cote,I+1]=1)Then Begin
     PathTem:=PanelPath[Cote];
     If(PanelPath[Cote,Length(PanelPath[Cote])]<>'\')Then PathTem := PanelPath[Cote] + '\';
     PathTem:=PathTem+Nom[Cote,I+1];
     FrameFull(35-(Length(PathTem) div 2),8,43+(Length(PathTem) div 2),17,$70);
     WriteCenter(11,'Efface le fichier :',$7E);
     WriteCenter(13,PathTem,$7E);
     If(DeleteFile(PathTem)<>1)Then Changement:=1;
    End;
   End;
  End;
 End;
 Refresh;
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

Procedure CertainQuitter;
Var
 Touche:Char;
 Quitte:Boolean;
Begin
 FrameFull(10,9,70,16,$70);
 WriteCenter(12,'Etes-vous certain de vouloir quitter ?',$70);
 WriteCenter(14,'Oui  Non',$70);
 WriteXY(35,14,' Oui ',$30);
 Touche:=ReadKey;
 If(KeyPressed)Then Touche := ReadKey;
 If(Touche in [#13,'Y','y','o','O'])Then Quitte := True
				     Else Quitte := False;
 If(KeyPressed)Then Touche:=ReadKey;
 If(Quitte)Then Done
           Else Refresh;
End;

Procedure CopyFile(Source,Target:String);
Var Source_File : File;
    Target_File : File;
    Num_Read    : Word;
    Num_Write   : Word;
    Buffer	: Array[0..32767] of Char;
Begin
 FrameFull(10,8,69,16,63);
 WriteCenter(11,'Copie fichier '+Source,62);
 WriteCenter(12,'Ö',62);
 WriteCenter(13,Target+Source,62);
 Assign(Source_File,Source);
 Reset(Source_File,1);
 If(IOResult <> 0)Then Exit;
 {If(Pos('\',Target[Length(target)])<>1)Then Target := Target + '\';}
 Assign(Target_File,Target + Source);
 Rewrite(Target_File,1);
 If(IOResult<>0)Then Exit;
 Repeat
  BlockRead(Source_File,Buffer,32768,Num_Read);
  BlockWrite(Target_File,Buffer,Num_Read,Num_Write);
  If(Num_Read<>Num_Write)Then
  Begin
   WriteLn('Impossible de copier le fichier : ',Source:13);
   Close(Source_File);
   Erase(Target_File);
   Close(Target_File);
   Exit
  End;
 Until Num_Read = 0;
 Close(Source_File);
 Close(Target_File);
End;

Procedure CopyFunc;
Var Source  : PathStr;
    Target  : PathStr;
    Boucle  : Word;
    Direct  : Boolean;
    Erreur  : Byte;
Begin
 If(PanelType[0] in [4])and(PanelType[1] in [4])Then Begin
  Direct := True;
  Target := PanelPath[(Cote + 1) and 1];
  For Boucle := 0 to NombreFichierX[Cote] - 1 do Begin
   If(Accepte[Cote,Boucle] = 1)Then Direct:=False;
  End;
  If(Direct)Then CopyFile(Nom[Cote,PositionX[Cote]+1],Target)
   else
  Begin
   For Boucle := 0 to NombreFichierX[Cote] - 1 do Begin
    If(Accepte[Cote,Boucle] = 1)Then CopyFile(Nom[Cote,Boucle],Target);
   End;
  End;
  Refresh;
 End
  else
 Write(^G);
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

Procedure EnterExecute;
Label 90;
Var
 Touche:Char;
 I:Integer;
Begin
 TextColor(7);
 TextBackGround(0);
 If CurrCommand<>''Then Begin
  PathTem := PanelPath[Cote];
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
   If(Nom[Cote,PositionX[Cote]+1]='..')Then Begin
    Delete(PanelPath[Cote],Length(PanelPath[Cote]),1);
    While PanelPath[Cote,Length(PanelPath[Cote])]<>'\'do Delete(PanelPath[Cote],Length(PanelPath[Cote]),1);
    If(Length(PanelPath[Cote])<>3)Then Delete(PanelPath[Cote],Length(PanelPath[Cote]),1);
   End
    else
   Begin
    If Not(PanelPath[Cote,Length(PanelPath[Cote])]='\')Then PanelPath[Cote]:=PanelPath[Cote]+'\';
    PanelPath[Cote]:=PanelPath[Cote]+Nom[Cote,PositionX[Cote]+1];
   End;
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
    WriteLn('Indication du Repertoire');
    For I:=0 to 39 do Write('-');
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
      WriteLn('Erreur : MÇmoire insuffisante!');
      TestExit;
     End
      else
     Case DosExitCode of
      1 : WriteLn('Interrompu par Ctrl + C');
      2 : WriteLn('Erreur de PÇriphÇrique');
      3 : WriteLn('Terminaison en mode rÇsidant');
     End;
    End;
    If(ChaineTemporaire='.EXE')or(ChaineTemporaire='.COM')Then Begin
     Exec(PathTem+Nom[Cote,PositionX[Cote]+1],'');
     WriteLn;
     If(DosError>0)Then Write('Erreur ',DosError:4,' : ');
     Case DosError of
      $00 : Begin
    	     Case DosExitCode of
	      0 : Write('Operation Reussit');
	      1 : Write('Interrompu par Ctrl + C');
	      2 : Write('Erreur de PÇriphÇrique');
	      3 : Write('Terminaison en mode rÇsidant');
	     End;
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
     else
    WriteLn('Erreur : Extension incorrect');
90 :WriteLn;
    WriteLn('Presse une touche pour retourner au North Commander...');
    {    XP:=WhereX;
    YP:=WhereY;}
    Touche:=ReadKey;
    If(KeyPressed)Then Touche := ReadKey;
    Touche:=#00;
    TextMode(C80);
    ShowKeyFunc;
    Refresh;
   End
    else
   Write(^G);
  End;
 End;
End;

Procedure Init;Begin
 TextMode(C80);
 If(WhereX>1)Then WriteLn;
 WriteLn('North Commandeur  - Clone Norton Commander');
 WriteLn;
 Menu:=0;
 Cote:=1;
 PanelType[0]:=4;
 PanelType[1]:=4;
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
  WriteLn('Impossible de lancer l''execution du NC');
  Write(^G);
  Halt;
 End;
 PanelPath[1]:=PanelPath[0];
 Refresh;
End;

Procedure SetOffFunctionKeyBar;Begin
 KeyBar:=False;
 GotoXY(1,25);
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
 RefreshPanel;
End;

Procedure ToggleInactivePanel;Begin
 PanelDisable[Cote xor 1]:=Not PanelDisable[Cote xor 1];
 RefreshPanel;
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
 RefreshPanel;
End;

Procedure AffichageMenu(Position:Byte);
Var
 I:Integer;
Begin
 FrameChoice(Position*10,1,Position*10+2+LengthMenu[Position],HeightMenu[Position]+3);
 For I:=0 to HeightMenu[Position] do Begin
  Case Position of
   $00:WriteXY(2,2+I,MenuLeft[I],48);
   $01:WriteXY(12,2+I,MenuFiles[I],48);
   $02:WriteXY(22,2+I,MenuDisk[I],48);
   $03:WriteXY(32,2+I,MenuCommands[I],48);
   $04:WriteXY(42,2+I,MenuLeft[I],48);
  End;
 End;
End;

Procedure UnselectItemMenu(Position,PosItem:Byte);Begin
 Case Position of
  $00:WriteXY(2,2+PosItem,MenuLeft[PosItem],48);
  $01:WriteXY(12,2+PosItem,MenuFiles[PosItem],48);
  $02:WriteXY(22,2+PosItem,MenuDisk[PosItem],48);
  $03:WriteXY(32,2+PosItem,MenuCommands[PosItem],48);
  $04:WriteXY(42,2+PosItem,MenuLeft[PosItem],48);
 End;
End;

Procedure SelectItemMenu(Position,PosItem:Byte);Begin
 Case Position of
  $00: WriteXY(2,2+PosItem,MenuLeft[PosItem],15);
  $01: WriteXY(12,2+PosItem,MenuFiles[PosItem],15);
  $02: WriteXY(22,2+PosItem,MenuDisk[PosItem],15);
  $03: WriteXY(32,2+PosItem,MenuCommands[PosItem],15);
  $04: WriteXY(42,2+PosItem,MenuLeft[PosItem],15);
 End;
End;

Procedure ShowPullDnMenu;
Var
 I:Integer;
Begin
 Box(0,0,79,0,48);
 For I:=0 to High(MainMenuChoice) do WriteChoice(2+I*10,0,MainMenuChoice[I],62,48);
End;

Procedure PullDnMenu;
Var
 K:Char;
 PosItem:Byte;
Begin
 ShowPullDnMenu;
 WriteXY(2+PosMenu*10,0,MainMenuChoice[PosMenu],15);
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
       15:Change(0);
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
       8..10:DialogNotImplement;
       11:CertainQuitter;
      End;
      Break;
     End;
     2:Begin { Disk }
      DialogNotImplement;
      Break;
     End;
     3:Begin { Commands }
      DialogNotImplement;
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
       15:Change(1);
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
    RefreshPanel;
    ShowPullDnMenu;
    WriteChoice(2+PosMenu*10,0,MainMenuChoice[PosMenu],62,48);
    If PosMenu=0Then PosMenu:=High(MainMenuChoice)
                Else PosMenu:=PosMenu - 1;
    WriteXY(2+PosMenu*10,0,MainMenuChoice[PosMenu],15);
    AffichageMenu(PosMenu);
    PosItem:=0;
    SelectItemMenu(PosMenu,PosItem);
   End;
   #77,#116:Begin
    RefreshPanel;
    ShowPullDnMenu;
    WriteChoice(2+PosMenu*10,0,MainMenuChoice[PosMenu],62,48);
    PosMenu:=(PosMenu+1) mod 5;
    WriteXY(2+PosMenu*10,0,MainMenuChoice[PosMenu],15);
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
 RefreshPanel;
End;

Procedure UnselectFileBar;Begin
 ShowLine(YPos[Cote],PositionX[Cote],Cote,False,True);
End;

Procedure SelectFileBar;Begin
 ShowLine(YPos[Cote],PositionX[Cote],Cote,True,True);
 GotoXY(Length(PanelPath[Cote])+1+PositionCur+1,23+1);
 ShowPanelStatusBar(Cote);
End;

Procedure Run;
Label 20;
Var
 K:Char;
Begin
 Repeat
  If(Menu=0)and(PanelType[Cote]=4)Then SelectFileBar;
  GotoXY(Length(PanelPath[Cote])+1+PositionCur+1,23+1);
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
    #71:If(PanelType[Cote]=4)Then Begin { Home }
     PositionX[Cote] := 0;
     YPos[Cote]      := 0;
     UpdateBoard;
     SelectFileBar;
    End;
    #72:Begin { Up }
     If(PanelType[Cote]=4)Then Begin
      If(PositionX[Cote]>0)Then Begin
       UnselectFileBar;
       Dec(PositionX[Cote]);
       Numerique := 40 * Cote;
       If(YPos[0]=0)And(Cote=0)Then Begin
        MoveWindow(Numerique+1,2,Numerique+38,2+SideLength[Cote],27,1);
        ShowLine(0,PositionX[0],0,False,True);
        GotoXY(1+PositionCur,24);
       End
        Else
       If(YPos[1]=0)And(Cote=1)Then Begin
        MoveWindow(Numerique+1,2,Numerique+38,2+SideLength[Cote],27,1);
        ShowLine(0,PositionX[1],1,False,True);
        GotoXY(1+PositionCur,24);
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
    #80:Begin
     If PanelType[Cote]=4 Then Begin
20:   If(PositionX[Cote]<NombreFichierX[Cote]-1)Then Begin
       UnselectFileBar;
       Inc(PositionX[Cote]);
       If(YPos[Cote]=SideLength[Cote])Then Begin
        Numerique := 40 * Cote;
        MoveWindow(Numerique+1,3,Numerique+38,2+SideLength[Cote],27,-1);
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
    #104:Begin
     Cote:=0;
     Change(0);
    End;
    #105:Begin
     Cote:=1;
     Change(1);
    End;
   End;
   If(K = #68)Then K:=#27 else K:=#00;
  End;
  Case K of
   #9:If(PanelType[Cote xor 1]=4)and(Not PanelDisable[Cote xor 1])Then Begin
    UnselectFileBar;
    Cote:=Cote xor 1;
    SelectFileBar;
   End;
   ^B:ToggleFunctionKeyBar;
   ^L:ToggleStatusPanel;
   ^M:EnterExecute;
   ^O:TogglePanel;
   ^P:ToggleInactivePanel;
   ^U:SwapPanels;
   #27:CertainQuitter;
  End;
  If(K>#31)And(PositionCur<79)Then Begin
   K:=UpCase(K);
   CurrCommand:=CurrCommand+K;
   GotoXY(Length(PanelPath[Cote])+1+PositionCur+1,23+1);
   TextBackground(Black);
   TextColor(LightGray);
   Write(K);
   Inc(PositionCur);
  End;
 Until K=#27;
End;

BEGIN
 ShowASCII128:=False;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('NC : Cette commande permet de lancer le gestionnaire de fichiers.');
  WriteLn;
  WriteLn('Syntaxe : NC [/ASCII128]');
  WriteLn;
  WriteLn(' /ASCII128   Ce parametre permet de lancer en mode compatibilite 128 caracteres seulement.');
  Halt;
 End;
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
END.
