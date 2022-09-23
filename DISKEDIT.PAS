{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program DISKEDIT;

Uses DOS,Crt;

Const
 MainMenu:Array[0..7]of String[12]=(
  'Objet','Edition','Lien','Vue','Informations','Outils','Quitter','F1=Aide'
 );

 MainMenuEnglish:Array[0..7]of String[12]=(
  'Object','Edit','Link','View','Info','Tools','Quit','F1=Help'
 );

 SubMenuObject:Array[0..13]of String[30]=(
  'UnitÇ...',
  'RÇpertoire...',
  'Fichier...',
  'UnitÇ d''allocation...',
  'Secteur...',
  'Secteur physique...',
  '',
  'Table de partition',
  'Enregistrement de dÇmarrage',
  '1iere copie de la FAT',
  '2ieme copie de la FAT',
  '',
  'Presse-papier',
  'Sortie de mÇmoire...'
 );

 SubMenuObjectEnglish:Array[0..13]of String[20]=(
  'Drive...',
  'diRectory...',
  'File...',
  'Cluster...',
  'Sector...',
  'Physical sector...',
  '',
  'partition Table',
  'Boot Record',
  '1st copy of FAT',
  '2nd copy of FAT',
  '',
  'cLipboard',
  'Memory Dump...'
 );

 SubMenuEdit:Array[0..8]of String[15]=(
  'RÇtablir',
  '',
  'Marquer',
  'Copie',
  'Coller dessus',
  'Remplir...',
  '',
  'êcrire les changements...',
  'Annuler les changements...'
 );

 SubMenuEditEnglish:Array[0..8]of String[15]=(
  'Undo',
  '',
  'Mark',
  'Copy',
  'Paste Over',
  'Fill...',
  '',
  'Write changes...',
  'Discard changes...'
 );

 SubMenuLink:Array[0..5]of String[20]=(
  'Fichier','RÇpertoire','Chaåne d''unitÇ d''allocation (FAT)',
  'Partition','','Fenàtre'
 );

 SubMenuLinkEnglish:Array[0..5]of String[20]=(
  'File','Directory','Cluster chain (FAT)','Partition','','Window'
 );

 SubMenuView:Array[0..10]of String[20]=(
  'en Hex','en Texte','en RÇpertoire','en FAT','en Table de partition',
  'en Enregistrement de dÇmarrage','','Divise la fenàtre',
  'Fenàtre croissante','RÇtrÇcis la fenàtre',
  'Echange les fenàtres'
 );

 SubMenuViewEnglish:Array[0..10]of String[20]=(
  'as Hex','as Text','as Directory','as FAT','as Partition Table',
  'as Boot Record','','Split window','Grow window','sHrink window',
  'sWitch windows'
 );

 SubMenuInfo:Array[0..2]of String[30]=(
  'Information d''objet...','Information d''unitÇ...',
  'Cartegraphie des objets...'
 );

 SubMenuInfoEnglish:Array[0..2]of String[30]=(
  'Object info...','Drive info...','Map of object...'
 );

 SubMenuTools:Array[0..13]of String[30]=(
  'Rechercher...',
  'Trouver encore',
  'êcrire dans...',
  'Imprimer dans...',
  '',
  'Recalcule la partition',
  'Compare les fenàtres...',
  'Fixe les attribues...',
  'Fixe la date et l''heure...',
  '',
  'Convertie en hexadÇcimal...',
  'Table ASCII...',
  '',
  'Configuration...'
 );

 SubMenuToolsEnglish:Array[0..13]of String[30]=(
  'Find...',
  'find aGain',
  'Write to...',
  'Print as...',
  '',
  'Recalculate Partition',
  'Compare Windows...',
  'set aTtributes...',
  'set Date/time...',
  '',
  'Hex converter...',
  'ASCII Table...',
  '',
  'cOnfiguration...'
 );

 YMenuMax:Array[1..8]of Byte=(
  High(SubMenuObject),High(SubMenuEdit),High(SubMenuLink),
  High(SubMenuView),High(SubMenuInfo),High(SubMenuTools),0,0
 );

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 YMenu,XMenu:Integer;
 ShowASCII128,OnMenu:Boolean;
 CurrDrive:Char;
 Mode:(_Hex,_Text,_Directory,_FAT,_PartitionTable,_BootRecord);
 IsDisk:Boolean;
 Lecteur,Face,Piste,Start:Byte;
 FileDiskEdit:File {$IFDEF FPC} of Byte{$ENDIF};
 FileName,CurrParam:String;
 Buffer:Array[0..1023]of Byte;
 CurrPos:LongInt;

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

Procedure DiskReset;
{$IFDEF Windows}
 Begin
  WriteLn('Cette operation n''est pas mise en oeuvre.');
  Halt;
 End;
{$ElSE}
 Var
  Regs:Registers;
 Begin
  Regs.AH:=$00;
  Regs.DL:=0;
  Intr($13,Regs);
 End;
{$ENDIF}

Function ReadTrack(Lecteur,Face,Piste,Start,Nombre:Byte;Var Buffer):Byte;
{$IFDEF Windows}
 Begin
  WriteLn('Cette operation n''est pas mise en oeuvre.');
  Halt;
 End;
{$ElSE}
 Var
  Essais:Byte;
  Regs:Registers;
 Begin
  essais:=5;
  Repeat
   WriteLn(Essais);
   Regs.AH:=$02;        { Numero de fonction pour appel interruption }
   Regs.AL:=Nombre;     { Nombre Secteurs par Piste }
   Regs.CH:=Piste;      { Numero de Piste }
   Regs.CL:=Start;      { Commencer par le secteur 1 }
   Regs.DL:=Lecteur;    { Numero de lecteur }
   Regs.DH:=Face;       { Numero de la face }
   Regs.ES:=Seg(Buffer);{ Adresse pour tampon }
   Regs.BX:=Ofs(Buffer);
   Intr($13,Regs);
   If Regs.flags and fcarry=1Then DiskReset;
   Dec(essais);
  Until(Regs.flags and fcarry=0)or(Essais=0);
  ReadTrack:=Regs.AH;
 End;
{$ENDIF}

Function WriteTrack(Lecteur,Face,Piste,Start,Nombre:Byte;Var Buffer):Byte;
{$IFDEF Windows}
 Begin
  WriteLn('Cette operation n''est pas mise en oeuvre.');
  Halt;
 End;
{$ElSE}
 Var
  Essais:Byte;
  Regs:Registers;
 Begin
  essais:=5;
  Repeat
   Regs.AH:=$03;        { Numero de fonction pour appel interruption }
   Regs.AL:=Nombre;     { Nombre Secteurs par Piste }
   Regs.CH:=Piste;      { Numero de Piste }
   Regs.CL:=Start;      { Commencer par le secteur 1 }
   Regs.DL:=Lecteur;    { Numero de lecteur }
   Regs.DH:=Face;       { Numero de la face }
   Regs.ES:=Seg(Buffer);{ Adresse pour tampon }
   Regs.BX:=Ofs(Buffer);
   Intr($13,Regs);
   If Regs.flags and fcarry=1Then DiskReset;
   Dec(essais);
  Until(Regs.flags and fcarry=0)or(Essais=0);
  WriteTrack:=Regs.AH;
 End;
{$ENDIF}

{$IFDEF Windows}
 Procedure Int25h(Drive:Byte;LSN:LongInt;Sects:Word;Var Buffer;Var Erreur:Word);Begin
  WriteLn('Cette fonctionnalite n''est pas mise en oeuvre');
  Halt;
 End;
{$ELSE}
 Var Data:Record
  LSN:LongInt;
  Sects:Word;
  Buffer:Pointer;
 End;

 Procedure Int25h(Drive:Byte;LSN:LongInt;Sects:Word;Var Buffer;Var Erreur:Word);
 Assembler;
 Const __POPF = $9D;
 ASM
  PUSH BP;
  PUSH DS;
   MOV AL,Drive;
   MOV DX,LSN.Word[0];
   MOV CX,Sects;
   LDS BX,Buffer;
   INT $25;
   JB  @@Suite;
   XOR AX,AX;
@@Suite:
   DB __POPF;
  POP DS;
  POP BP;
  LES DI,Erreur;
  MOV ES:[DI],AX;
  CMP AX,519;
  JNE @@No32Bits;
  PUSH BP;
  PUSH DS;
   MOV AL,Drive;
   MOV DX,LSN.Word[0];
   MOV SI,LSN.Word[2];
   MOV CX,Sects;
   MOV BX,Offset Data;
   MOV DS:[BX],DX;
   MOV DS:[BX+2].Word,SI;
   MOV DS:[BX+4],CX;
   LES DI,Buffer;
   MOV DS:[BX+6],DI;
   MOV DS:[BX+8],ES;
   MOV CX,$FFFF;
   INT $25;
   JB  @@Suite2;
   XOR AX,AX;
@@Suite2:
   DB __POPF;
  POP DS;
  POP BP;
  LES DI,Erreur;
  MOV ES:[DI],AX;
@@No32Bits:
 End;
{$ENDIF}

Function TwoByteToWord(A,B:Byte):Word;Begin
 TwoByteToWord:=B*256+A;
End;

Function FourByteToLongInt(A,B,C,D:Byte):LongInt;Begin
 FourByteToLongInt:=D*16777216+C*65536+B*256+A;
End;

Procedure ReadCurrSector;
Var
 ByteReaded:Integer;
 Erreur:Word;
Begin
 If(IsDisk)Then Begin
  Int25h(Byte(CurrDrive)-Byte('A'),CurrPos shr 9,1,Buffer,Erreur);
 End
  Else
 If FileName<>''Then Begin
  Seek(FileDiskEdit,CurrPos);
  BlockRead(FileDiskEdit,Buffer,512,ByteReaded);
 End;
End;

Procedure ReadBootRecord;
Var
 ByteReaded:Integer;
 Erreur:Word;
Begin
 If(IsDisk)Then Begin
  Int25h(Byte(CurrDrive)-Byte('A'),0,1,Buffer,Erreur);
 End
  Else
 If FileName<>''Then Begin
  Seek(FileDiskEdit,CurrPos);
  BlockRead(FileDiskEdit,Buffer,512,ByteReaded);
 End;
End;

Procedure ReadPartitionRecord;Begin
 If(IsDisk)Then Begin
  ReadTrack(Lecteur,0,0,1,1,Buffer);
 End;
End;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

Function LongHex2Str(value:LongInt):String;
Begin
 LongHex2Str:=ByteHex2Str((value shr 24)and $FF)+
              ByteHex2Str((value shr 16)and $FF)+
              ByteHex2Str((value shr 8)and $FF)+
              ByteHex2Str(value and $FF);
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

Procedure ShowStatusBar;Begin
 TextColor(Red+BLINK);
 TextBackground(7);
 GotoXY(1,25);
 ClrEol;
 GotoXY(60,25);
 Case Language of
  _English:Write(#179,'Disk Editor');
  Else Write(#179,'êditeur disque');
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
 GotoXY(1,1);
 For I:=0 to High(MainMenu) do Begin
  If High(MainMenu)=I Then Begin
   SetColorUnSelect;
   Case Language of
    _English: Write(' ':18);
    Else Write(' ':5);
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
  Write(' ');
 End;
End;

Procedure SubMenuItem(Y:Integer;Disable:Boolean);Begin
 If(Disable)Then SetColorUnSelect Else
 If Y=YMenu Then SetColorSelect
            Else SetColorUnSelect;
 Case XMenu of
  1:Begin
   GotoXY(2,3+Y);
   If SubMenuObject[Y]=''Then Write(DuplicateString('-',27+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuObjectEnglish[Y],27));
    Else Write(' ',PadRight(SubMenuObject[Y],27));
   End;
  End;
  2:Begin
   Case Language of
    _English:GotoXY(11,3+Y);
    Else GotoXY(10,3+Y);
   End;
   If SubMenuEdit[Y]=''Then Write(DuplicateString('-',27+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuEditEnglish[Y],27));
    Else Write(' ',PadRight(SubMenuEdit[Y],27));
   End;
  End;
  3:Begin
   Case Language of
    _English:GotoXY(18,3+Y);
    Else GotoXY(20,3+Y);
   End;
   If SubMenuLink[Y]=''Then Write(DuplicateString('-',27+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuLinkEnglish[Y],27));
    Else Write(' ',PadRight(SubMenuLink[Y],27));
   End;
  End;
  4:Begin
   Case Language of
    _English:GotoXY(25,3+Y);
    Else GotoXY(27,3+Y);
   End;
   If SubMenuView[Y]=''Then Write(DuplicateString('-',27+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuViewEnglish[Y],27));
    Else Write(' ',PadRight(SubMenuView[Y],27));
   End;
  End;
  5:Begin
   Case Language of
    _English:GotoXY(32,3+Y);
    Else GotoXY(33,3+Y);
   End;
   If SubMenuInfo[Y]=''Then Write(DuplicateString('-',27+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuInfoEnglish[Y],27));
    Else Write(' ',PadRight(SubMenuInfo[Y],27));
   End;
  End;
  6:Begin
   Case Language of
    _English:GotoXY(39,3+Y);
    Else GotoXY(48,3+Y);
   End;
   If SubMenuTools[Y]=''Then Write(DuplicateString('-',27+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuToolsEnglish[Y],27));
    Else Write(' ',PadRight(SubMenuTools[Y],27));
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
   FrameEmpty(1,2,30,4+High(SubMenuObject),$F0);
   For I:=Low(SubMenuObject)to High(SubMenuObject)do Begin
    SubMenuItem(I,False);
   End;
  End;
  2:Begin
   Case Language of
    _English:FrameEmpty(10,2,39,4+High(SubMenuEdit),$F0);
    Else FrameEmpty(9,2,38,4+High(SubMenuEdit),$F0);
   End;
   For I:=Low(SubMenuEdit)to High(SubMenuEdit)do Begin
    SubMenuItem(I,False);
   End;
  End;
  3:Begin
   Case Language of
    _English: FrameEmpty(17,2,46,4+High(SubMenuLink),$F0);
    Else FrameEmpty(19,2,48,4+High(SubMenuLink),$F0);
   End;
   For I:=Low(SubMenuLink)to High(SubMenuLink)do Begin
    SubMenuItem(I,False);
   End;
  End;
  4:Begin
   Case Language of
    _English:FrameEmpty(24,2,53,4+High(SubMenuView),$F0);
    Else FrameEmpty(26,2,55,4+High(SubMenuView),$F0);
   End;
   For I:=Low(SubMenuView)to High(SubMenuView)do Begin
    SubMenuItem(I,False);
   End;
  End;
  5:Begin
   Case Language of
    _English:FrameEmpty(31,2,60,4+High(SubMenuInfo),$F0);
    Else FrameEmpty(32,2,61,4+High(SubMenuInfo),$F0);
   End;
   For I:=Low(SubMenuInfo)to High(SubMenuInfo)do Begin
    SubMenuItem(I,False);
   End;
  End;
  6:Begin
   Case Language of
    _English:FrameEmpty(38,2,67,4+High(SubMenuTools),$F0);
    Else FrameEmpty(47,2,76,4+High(SubMenuTools),$F0);
   End;
   For I:=Low(SubMenuTools)to High(SubMenuTools)do Begin
    SubMenuItem(I,False);
   End;
  End;
 End;
End;

Procedure View16x16;
Var
 X,I,J,Y:Byte;
 PosInBuffer:Word;
Begin
 GotoXY(1,2);
 Y:=2;
 For J:=0 to 19 do Begin
  If (CurrPos+J*16)and $1FF=0 Then Begin
   TextColor(14+BLINK);
   Write('Secteur ',(CurrPos+J*16) shr 9);
   ClrEol;
   WriteLn;
   TextColor(15+BLINK);
   Inc(Y);
  End;
  Write(LongHex2Str(CurrPos+J*16),':  ');
  For I:=0 to 15 do Begin
   PosInBuffer:=(J shl 4)+I;
   X:=Buffer[PosInBuffer];
   Write(ByteHex2Str(X),' ');
   If I=7Then Write('- ');
  End;
  For I:=0 to 15 do Begin
   PosInBuffer:=(J shl 4)+I;
   X:=Buffer[PosInBuffer];
   If X in[10,13]Then Write(' ')
                 Else Write(Char(X));
  End;
  WriteLn;
  Inc(Y);
 End;
 If Y=22Then ClrEol;
End;

Procedure ShowBootRecord;
Var
 I:Integer;
 BitsDeFat,NbrDeFats:Byte;
 TotSects,PremRoot,PremData,SectsPRoot,TempLong,TotPistes,TotClusters:LongInt;
 Erreur,RawTotSects,SectsPPiste,MaxEntrees,SectsPFat,SectsReserves,BytesPSecteur,NbrTetes:Word;
Begin
 BytesPSecteur:=TwoByteToWord(Buffer[$0B],Buffer[$0C]);
 If BytesPSecteur=0Then BytesPSecteur:=512;
 NbrDeFats:=Buffer[$10];
 If NbrDeFats=0Then NbrDeFats:=2;
 TotSects:=TwoByteToWord(Buffer[$13],Buffer[$14]);
 If TotSects=0Then TotSects:=FourByteToLongInt(Buffer[$20],Buffer[$21],Buffer[$22],Buffer[$23]);
 NbrTetes:=TwoByteToWord(Buffer[$1A],Buffer[$1B]);
 SectsReserves:=TwoByteToWord(Buffer[$0E],Buffer[$0F]);
 SectsPFat:=TwoByteToWord(Buffer[$16],Buffer[$17]);
 PremRoot:=SectsReserves+(NbrDeFats*SectsPFat);
 MaxEntrees:=TwoByteToWord(Buffer[$11],Buffer[$12]);
 SectsPRoot:=(MaxEntrees*32)div BytesPSecteur;
 If(((MaxEntrees*32) mod BytesPSecteur)<>0)Then Inc(SectsPRoot);
 PremData:=PremRoot+SectsPRoot;
 TempLong := LongInt(TotSects);
 SectsPPiste:=TwoByteToWord(Buffer[$18],Buffer[$19]);
 If (LongInt(NbrTetes)*LongInt(SectsPPiste))=0Then Begin
  TempLong:=0
 End
  Else
 Begin
  TempLong := TempLong div (LongInt(NbrTetes)*LongInt(SectsPPiste));
 End;
 TotPistes := TempLong;
 If(TempLong-TotPistes > 0)Then Inc(TotPistes);
 If Buffer[$0D]=0Then TempLong:=0
                 Else TempLong:=(LongInt(TotSects)-LongInt(PremData)) div LongInt(Buffer[$0D]);
 TotClusters := TempLong;
 RawTotSects:=TwoByteToWord(Buffer[$13],Buffer[$14]);
 If RawTotSects=0Then BitsDeFat:=32 Else
 If(RawTotSects>4086)Then BitsDeFat:=16
	             Else BitsDeFat:=12;
 GotoXY(38,4);
 Write('OEM ID : ');
 For I:=0 to 7 do Write(Char(Buffer[3+I]));
 GotoXY(26,5);
 Write('Octets par secteur : ',BytesPSecteur);
 GotoXY(14,6);
 Write('Secteur par unite d''allocation : ',Buffer[$0D]);
 GotoXY(18,7);
 Write('Secteurs reserves au debut : ',TwoByteToWord(Buffer[$0E],Buffer[$0F]));
 GotoXY(18,8);
 Write('Nombre de copies de la FAT : ',NbrDeFats);
 GotoXY(1,9);
 Write('Maximum d''entrees dans le repertoire racine : ',TwoByteToWord(Buffer[$11],Buffer[$12]));
 GotoxY(20,10);
 TotSects:=TwoByteToWord(Buffer[$13],Buffer[$14]);
 Write('Nombre total de secteurs : ');
 If TotSects=0 Then Write('Non-utilise')
               Else Write(TotSects);
 GotoXY(15,11);
 Write('Octet du descripteur de media : ',ByteHex2Str(Buffer[$15]),' Hex, ');
 Case Buffer[$15] of
  $FF: WriteLn('Disquette double face, 8 secteurs/piste');
  $FE: WriteLn('Disquette simple face, 8 secteurs/piste');
  $FD: WriteLn('Disquette double face, 9 secteurs/piste');
  $FC: WriteLn('Disquette simple face, 9 secteurs/piste');
  $F9: WriteLn('Disquette double face, 15 secteurs/piste');
  $F8: WriteLn('Disque dur');
  $F0: WriteLn('Disquette');
  Else WriteLn('Media inconnu : ',Buffer[$15]);
 End;
 GotoXY(28,12);
 Write('Secteurs par FAT : ',SectsPFat);
 GotoXY(26,13);
 Write('Secteurs par piste : ',TwoByteToWord(Buffer[$18],Buffer[$19]));
 GotoXY(31,14);
 Write('Tetes (faces) : ',NbrTetes);
 GotoXY(21,15);
 Write('Secteurs special caches : ');
 Write(FourByteToLongInt(Buffer[$1C],Buffer[$1D],Buffer[$1E],Buffer[$1F]));
 GotoXY(14,16);
 Write('Grand nombre total de secteurs : ',FourByteToLongInt(Buffer[$20],Buffer[$21],Buffer[$22],Buffer[$23]));
 GotoXY(21,17);
 Write('Numero d''unite physique : ',Buffer[$25]);
 GotoXY(18,18);
 Write('Signature d''enregistrement : ',ByteHex2Str(Buffer[$26]),'Hex');
 GotoXY(19,19);
 Write('Numero de serie du volume : ',ByteHex2Str(Buffer[$27]));
 Write(ByteHex2Str(Buffer[$28]),ByteHex2Str(Buffer[$29]),ByteHex2Str(Buffer[$2A]));
 GotoXY(25,20);
 Write('Etiquette du volume : ');
 For I:=0 to 10 do Write(Char(Buffer[$2B+I]));
 GotoXY(8,21);
 Write('Identificateur de systeme de fichier : ');
 For I:=0 to 7 do Write(Char(Buffer[$36+I]));
End;

Procedure ShowView;Begin
 Box(1,2,80,23,$9F);
 Case Mode of
  _Hex:View16x16;
  _Text:Begin
  End;
  _Directory:Begin
  End;
  _FAT:Begin
  End;
  _PartitionTable:Begin
  End;
  _BootRecord:Begin
   ReadBootRecord;
   ShowBootRecord;
  End;
 End;
End;

Procedure HideSubMenu;Begin
 ShowView;
 ShowStatusBar;
 ShowMenu;
End;

Procedure NotImplemented;Begin
 Box(5,11,75,13,$60);
 FrameEmpty(5,11,75,13,$60);
 GotoXY(20,12);
 Write('Cette fonctionnalitÇ n''est pas implÇmentÇ');
 ReadKey;
 HideSubMenu;
End;

Procedure Init;
Var
 Regs:Registers;
Begin
 OnMenu:=False;
 CursorOff;
 Regs.AX:=$1003;
 Regs.BL:=$0;
 Intr($10,Regs);
 ClrScr;
 ShowMenu;
 ShowStatusBar;
 ShowView;
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
    #61:Terminated:=True; { F3 }
    #72:Begin { Up }
     SubMenuItem(YMenu,True);
     If YMenu>0Then Dec(YMenu)
               Else YMenu:=YMenuMax[XMenu];
     Case XMenu of
      1:If YMenu in[6,11]Then Dec(YMenu);
      2:If YMenu in[1,6]Then Dec(YMenu);
      3:If YMenu in[4]Then Dec(YMenu);
      4:If YMenu in[6]Then Dec(YMenu);
      6:If YMenu in[4,9,12]Then Dec(YMenu);
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
      1:If YMenu in[6,11]Then Inc(YMenu);
      2:If YMenu in[1,6]Then Inc(YMenu);
      3:If YMenu in[4]Then Inc(YMenu);
      4:If YMenu in[6]Then Inc(YMenu);
      6:If YMenu in[4,9,12]Then Inc(YMenu);
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
     4:Case YMenu of
      0:Begin
       Mode:=_Hex;
       ShowView;
      End;
      1:Begin
       Mode:=_Text;
       ShowView;
      End;
      2:Begin
       Mode:=_Directory;
       ShowView;
      End;
      3:Begin
       Mode:=_FAT;
       ShowView;
      End;
      4:Begin
       Mode:=_PartitionTable;
       ShowView;
      End;
      5:Begin
       Mode:=_BootRecord;
       ShowView;
      End;
      Else NotImplemented;
     End;
     7:Terminated:=True;
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
     #16:Terminated:=True;
     #18:Begin { Alt+E }
      XMenu:=2;YMenu:=0;
      OnMenu:=True;
      ShowMenu;
      ShowSubMenu;
     End;
     #20:Begin { Alt+T }
      XMenu:=6;YMenu:=0;
      OnMenu:=True;
      ShowMenu;
      ShowSubMenu;
     End;
     #23:Begin { Alt+I }
      XMenu:=5;YMenu:=0;
      OnMenu:=True;
      ShowMenu;
      ShowSubMenu;
     End;
     #24:Begin { Alt+O }
      XMenu:=1;YMenu:=0;
      OnMenu:=True;
      ShowMenu;
      ShowSubMenu;
     End;
     #38:Begin { Alt+L }
      XMenu:=3;YMenu:=0;
      OnMenu:=True;
      ShowMenu;
      ShowSubMenu;
     End;
     #47:Begin { Alt+V }
      XMenu:=4;YMenu:=0;
      OnMenu:=True;
      ShowMenu;
      ShowSubMenu;
     End;
     #60:Begin { F2 }
      Mode:=_Hex;
      ShowView;
     End;
     #61:Begin { F3 }
      Mode:=_Text;
      ShowView;
     End;
     #62:Begin { F4 }
      Mode:=_Directory;
      ShowView;
     End;
     #63:Begin { F5 }
      Mode:=_FAT;
      ShowView;
     End;
     #64:Begin { F6 }
      Mode:=_PartitionTable;
      ShowView;
     End;
     #65:Begin { F7 }
      Mode:=_BootRecord;
      ShowView;
     End;
     #73:If Mode=_Hex Then Begin { PgUp }
      If CurrPos>0Then  CurrPos:=CurrPos-$140;
      ReadCurrSector;
      View16x16;
     End;
     #81:If Mode=_Hex Then Begin { PgDn }
      CurrPos:=CurrPos+$140;
      ReadCurrSector;
      View16x16;
     End;
    End;
   End;
   #27:Terminated:=True; { Esc }
  End;
 Until Terminated;
End;

Procedure Done;Begin
 If Not(IsDisk)Then Begin
  If FileName<>''Then Begin
   Close(FileDiskEdit);
  End;
 End;
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
  WriteLn('DISKEDIT : Cette commande permet de lancer l''editeur de disque.');
  WriteLn;
  WriteLn('Syntaxe : DISKEDIT fichier');
  WriteLn('          DISKEDIT disque:');
 End
  Else
 Begin
  Lecteur:=0;Face:=0;Piste:=0;Start:=0;
  CurrPos:=0;
  Mode:=_Hex;
  ShowASCII128:=False;
  IsDisk:=False;
  FileName:='';
  CurrParam:=ParamStr(1);
  If(CurrParam[1]in['a'..'z','A'..'Z'])and(CurrParam[2]=':')Then Begin
   CurrDrive:=UpCase(CurrParam[1]);
   IsDisk:=True;
  End
   Else
  FileName:=CurrParam;
  If(IsDisk)Then Begin
  End
   Else
  If FileName<>''Then Begin
   {$I-}Assign(FileDiskEdit,FileName);
   Reset(FileDiskEdit);{$I+}
   ReadCurrSector;
  End;
  Init;
  Run;
  Done;
 End;
END.