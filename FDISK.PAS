{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program FDISK;

{$A-}

Uses Crt,DOS;

Type
 {Structure de lecture pour le disque }
 SecPosType=Record
  Head:Byte;
  SectTrack:Word;
 End;

 {Structure de partition}
 PartEntry=Record
  Status:Byte;
  StartSec:SecPosType;
  PartType:Byte;
  EndSec:SecPosType;
  SecOfs,NumSec:LongInt;
 End;

 PartSec=Record { d�crit le secteur de partition }
  BootCode:Array[0..$1BD]of Byte;    { Code de d�marrage du disque dur }
  PartTable:Array[0..3]of PartEntry; { Table des partitions de disque dur }
  IdCode:Word;                       { Signature: AA55h }
 End;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 CurrentDisk:Byte;
 IsDisk:Boolean;
 FileName:String;
 Buffer:Array[0..1023]of Byte;

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

Procedure ReadPartitionRecord;
Var
 Partition:File;
 ByteReaded:Word;
Begin
 If(IsDisk)Then Begin
  ReadTrack($80+CurrentDisk-1,0,0,1,1,Buffer);
 End
  Else
 If FileName<>''Then Begin
  {$I-}Assign(Partition,FileName);
  Reset(Partition,1);{$I+}
  If IOResult=0 Then Begin
   BlockRead(Partition,Buffer,512,ByteReaded);
   Close(Partition);
  End;
 End;
End;

Procedure WritePartitionRecord;
Var
 Partition:File;
 ByteReaded:Word;
Begin
 If(IsDisk)Then Begin
  WriteTrack($80+CurrentDisk-1,0,0,1,1,Buffer);
 End
  Else
 If FileName<>''Then Begin
  {$I-}Assign(Partition,FileName);
  Reset(Partition,1);{$I+}
  If IOResult=0 Then Begin
   BlockWrite(Partition,Buffer,512,ByteReaded);
   Close(Partition);
  End;
 End;
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

Procedure WriteLnCenter(S:String);Begin
 GotoXY((((Lo(WindMax)-Lo(WindMin))-Length(S))shr 1),WhereY);
 WriteLn(S);
End;

{ Lit un secteur (512 octets) depuis l'image fichier.
  Retourne True si OK. Buf doit contenir au moins 512 octets. }
Function ReadImgSector(LBA:LongInt;Var Buf):Boolean;
Var
 F:File;
 BR:Word;
Begin
 ReadImgSector:=False;
 If FileName='' Then Exit;
 {$I-}Assign(F,FileName);Reset(F,1);{$I+}
 If IOResult<>0 Then Exit;
 {$I-}Seek(F,LBA*512);{$I+}
 If IOResult<>0 Then Begin Close(F);Exit;End;
 {$I-}BlockRead(F,Buf,512,BR);{$I+}
 Close(F);
 ReadImgSector:=(IOResult=0)And(BR=512);
End;

{ Geometrie du disque physique courant (caches une fois lue). }
Var
 GeoValid:Boolean;
 GeoHeads,GeoSPT:Word;

{$IFNDEF Windows}
Procedure FetchGeometry;
Var Regs:Registers;
Begin
 If GeoValid Then Exit;
 Regs.AH:=$08;
 Regs.DL:=$80+CurrentDisk-1;
 Intr($13,Regs);
 If(Regs.Flags and FCarry)=0 Then Begin
  GeoHeads:=Regs.DH+1;
  GeoSPT:=Regs.CL and $3F;
  If(GeoHeads>0)And(GeoSPT>0)Then GeoValid:=True;
 End;
End;
{$ENDIF}

{ Lit un secteur (512 octets) en LBA depuis le disque physique courant.
  Retourne True si OK. }
Function ReadDiskLBA(LBA:LongInt;Var Buf):Boolean;
{$IFDEF Windows}
 Begin ReadDiskLBA:=False; End;
{$ELSE}
Var
 Cyl,Head,Sect:Word;
 Tmp:LongInt;
 Status:Byte;
Begin
 ReadDiskLBA:=False;
 FetchGeometry;
 If Not GeoValid Then Exit;
 { LBA = ((Cyl*Heads) + Head) * SPT + Sect - 1 }
 Sect:=Word(LBA Mod GeoSPT)+1;
 Tmp:=LBA Div GeoSPT;
 Head:=Word(Tmp Mod GeoHeads);
 Cyl:=Word(Tmp Div GeoHeads);
 If Cyl>1023 Then Exit;  { au-dela de la limite CHS BIOS }
 Status:=ReadTrack($80+CurrentDisk-1,Head,Byte(Cyl),Byte(Sect),1,Buf);
 ReadDiskLBA:=(Status=0);
End;
{$ENDIF}

{ Lit un secteur depuis l'image OU le disque selon le mode courant. }
Function ReadSector(LBA:LongInt;Var Buf):Boolean;
Begin
 If FileName<>'' Then ReadSector:=ReadImgSector(LBA,Buf)
 Else ReadSector:=ReadDiskLBA(LBA,Buf);
End;

{ Calcule le % UTILISE d'une partition FAT en parcourant sa FAT.
  Renvoie -1 si impossible (type non supporte, lecture echouee, etc.). }
Function PartUsagePct(Const PE:PartEntry):Integer;
Var
 Sec:Array[0..511] of Byte;
 BytesPerSec,RsvdSec,RootEntCnt,SecPerClus:Word;
 SecPerFAT,TotSec:LongInt;
 NumFATs:Byte;
 FATType:Byte;       { 12, 16 ou 32 }
 DataSec,TotClus:LongInt;
 FATStart:LongInt;
 BytesInFAT:LongInt;
 FATBuf:Array[0..511] of Byte;
 CurFATSec:LongInt;
 LastFATSec:LongInt;
 ClusIdx:LongInt;
 Ofs:LongInt;
 V12:Word;
 V16:Word;
 V32:LongInt;
 Free:LongInt;
 Used:LongInt;
Begin
 PartUsagePct:=-1;
 If Not ReadSector(PE.SecOfs,Sec) Then Exit;
 { Verifier signature de boot sector }
 If(Sec[510]<>$55)Or(Sec[511]<>$AA)Then Exit;
 BytesPerSec:=Word(Sec[11])Or(Word(Sec[12])Shl 8);
 SecPerClus:=Sec[13];
 RsvdSec:=Word(Sec[14])Or(Word(Sec[15])Shl 8);
 NumFATs:=Sec[16];
 RootEntCnt:=Word(Sec[17])Or(Word(Sec[18])Shl 8);
 TotSec:=Word(Sec[19])Or(Word(Sec[20])Shl 8);
 If TotSec=0 Then
  TotSec:=LongInt(Sec[32])Or(LongInt(Sec[33])Shl 8)
        Or(LongInt(Sec[34])Shl 16)Or(LongInt(Sec[35])Shl 24);
 SecPerFAT:=Word(Sec[22])Or(Word(Sec[23])Shl 8);
 If SecPerFAT=0 Then
  SecPerFAT:=LongInt(Sec[36])Or(LongInt(Sec[37])Shl 8)
           Or(LongInt(Sec[38])Shl 16)Or(LongInt(Sec[39])Shl 24);
 If(BytesPerSec<>512)Or(SecPerClus=0)Or(NumFATs=0)Or(SecPerFAT=0)Then Exit;
 { Calcul du nombre de clusters de donnees }
 DataSec:=TotSec-(RsvdSec+LongInt(NumFATs)*SecPerFAT
                  +((LongInt(RootEntCnt)*32+BytesPerSec-1)Div BytesPerSec));
 If DataSec<=0 Then Exit;
 TotClus:=DataSec Div SecPerClus;
 If TotClus<4085 Then FATType:=12
 Else If TotClus<65525 Then FATType:=16
 Else FATType:=32;
 FATStart:=PE.SecOfs+RsvdSec;
 BytesInFAT:=LongInt(SecPerFAT)*BytesPerSec;
 { Scanner FAT, compter clusters libres (entree=0) }
 CurFATSec:=-1;
 LastFATSec:=-1;
 Free:=0;
 { Clusters valides : 2..TotClus+1 }
 For ClusIdx:=2 To TotClus+1 Do Begin
  Case FATType Of
   12:Ofs:=ClusIdx+(ClusIdx Shr 1);
   16:Ofs:=ClusIdx Shl 1;
   Else Ofs:=ClusIdx Shl 2;
  End;
  If Ofs>=BytesInFAT Then Break;
  CurFATSec:=FATStart+(Ofs Div BytesPerSec);
  If CurFATSec<>LastFATSec Then Begin
   If Not ReadSector(CurFATSec,FATBuf) Then Exit;
   LastFATSec:=CurFATSec;
  End;
  Ofs:=Ofs Mod BytesPerSec;
  Case FATType Of
   12:Begin
    { Cas frontiere : entree de 12 bits a cheval sur deux secteurs }
    If Ofs=BytesPerSec-1 Then Begin
     V12:=FATBuf[Ofs];
     If Not ReadSector(CurFATSec+1,FATBuf) Then Exit;
     LastFATSec:=CurFATSec+1;
     V12:=V12 Or(Word(FATBuf[0])Shl 8);
    End Else
     V12:=Word(FATBuf[Ofs])Or(Word(FATBuf[Ofs+1])Shl 8);
    If(ClusIdx And 1)=0 Then V12:=V12 And $0FFF
                        Else V12:=V12 Shr 4;
    If V12=0 Then Inc(Free);
   End;
   16:Begin
    V16:=Word(FATBuf[Ofs])Or(Word(FATBuf[Ofs+1])Shl 8);
    If V16=0 Then Inc(Free);
   End;
   Else Begin
    V32:=LongInt(FATBuf[Ofs])Or(LongInt(FATBuf[Ofs+1])Shl 8)
        Or(LongInt(FATBuf[Ofs+2])Shl 16)Or(LongInt(FATBuf[Ofs+3])Shl 24);
    V32:=V32 And $0FFFFFFF;
    If V32=0 Then Inc(Free);
   End;
  End;
 End;
 Used:=TotClus-Free;
 If Used<0 Then Used:=0;
 If TotClus>0 Then
  PartUsagePct:=Integer((Used*100+TotClus Div 2)Div TotClus)
 Else
  PartUsagePct:=0;
End;

Procedure WriteListPartition;
Var
 Partition:PartSec Absolute Buffer;
 I:Byte;
 Letter:Char;
 TypeName:String;
 TotSec:LongInt;
 Pct:Integer;
Begin
 Write(' ':2,'Lecteur de disque dur en cours : ');
 HighVideo;
 If FileName<>''Then WriteLn(FileName)
                Else WriteLn(CurrentDisk);
 LowVideo;
 WriteLn;
 WriteLn(' ':2,'Partition    Etat   Type   Nom du volume    Mo  Syst�me    Utilis�');
 ReadPartitionRecord;
 { Total des secteurs occupes par toutes les partitions = taille du disque }
 TotSec:=0;
 For I:=0 to 3 do
  If Partition.PartTable[I].PartType<>0Then
   Inc(TotSec,Partition.PartTable[I].NumSec);
 Letter:='C';
 For I:=0 to 3 do If Partition.PartTable[I].PartType<>0Then Begin
  Write(' ':3);
  If Partition.PartTable[I].PartType in[$04,$05,$06,$07,$0B,$0C]Then Begin
   Write(Letter,': ');
   Letter:=Succ(Letter);
  End
   Else
  Write(' ':3);
  HighVideo;
  Write(I+1,' ':9);
  LowVideo;
  If Partition.PartTable[I].Status=$80 Then Write('A')
                                       Else Write(' ');
  Write(' ':4);
  Write('PRI DOS',' ':2);
  Write('NOLABEL',' ':7);
  { Taille en Mo = NumSec * 512 / (1024*1024) = NumSec / 2048 }
  Write((Partition.PartTable[I].NumSec + 1024) Div 2048:6,' ':3);
  Case Partition.PartTable[I].PartType of
   $00:TypeName:='Entr�e vide';
   $01:TypeName:='FAT12';
   $02:TypeName:='XENIX root';
   $03:TypeName:='XENIX /usr';
   $04,$05,$06:TypeName:='FAT16';
   $07:TypeName:='NTFS ou HPFS';
   $08:TypeName:='D�marrage AIX';
   $09:TypeName:='Donn�es AIX';
   $0A:TypeName:='OS/2 Boot Manager';
   $0B,$0C:TypeName:='FAT32';
   $0D:TypeName:='SILICON SAFE';
   $0E,$0F:TypeName:='FAT16/WIN95';
   $11,$14,$16:TypeName:='FAT12 cach�';
   $12:TypeName:='Partition de configuration';
   $17:TypeName:='IFS cach�';
   $18:TypeName:='AST SmartSleep';
   $1B:TypeName:='FAT32 cach�';
   $1C:TypeName:='FAT32';
   $1E:TypeName:='FAT16/WIN95';
   $24:TypeName:='NEC DOS';
   $27:TypeName:='MirOS';
   $2A:TypeName:='AtheOS';
   $2B:TypeName:='SylStor';
   $32:TypeName:='NOS';
   $35:TypeName:='JFS';
   Else TypeName:='Inconnu';
  End;
  Write(PadRight(TypeName,11));
  { % d'occupation reel via scan FAT (image fichier ou disque physique) }
  Pct:=PartUsagePct(Partition.PartTable[I]);
  If Pct<0 Then
   { Fallback : % du disque physique occupe par cette partition }
   If TotSec>0 Then
    Write(Integer((LongInt(Partition.PartTable[I].NumSec)*100+TotSec Div 2)
                  Div TotSec),'%')
   Else
    Write('  ? ')
  Else
   Write(Pct,'%');
  WriteLn;
 End;
End;

Procedure CreatePartition;Begin
 ClrScr;
 WriteLn('Cette fonctionnalit� n''est pas implement� !');
 ReadKey;
End;

Procedure ActivePartition;
Var
 Partition:PartSec Absolute Buffer;
 CurrActive,I,ActiveX,ActiveY:Byte;
Begin
 ClrScr;
 WriteLn;
 WriteLn;
 WriteLn;
 WriteLnCenter('Activation de la partition de la partition');
 WriteLn;
 WriteListPartition;
 WriteLn;
 WriteLn;
 WriteLn;
 Write(' ':2,'Entrez le num�ro de la partition que vous voulez activer...: ');
 HighVideo;
 CurrActive:=0;
 For I:=0 to 3 do Begin
  If Partition.PartTable[I].Status=$80 Then CurrActive:=I+1;
 End;
 Write('[');
 ActiveX:=WhereX;
 ActiveY:=WhereY;
 WriteLn(CurrActive,']');
 GotoXY(1,25);
 LowVideo;
 Write(' ':2,'Appuyez sur ');
 HighVideo;
 Write('ECHAP');
 LowVideo;
 Write(' pour quitter FDISK');
 Repeat
  HighVideo;
  GotoXY(ActiveX,ActiveY);
  Write(CurrActive);
  GotoXY(ActiveX,ActiveY);
  LowVideo;
  Case ReadKey of
   '1':If Partition.PartTable[0].PartType<>0Then CurrActive:=1;
   '2':If Partition.PartTable[1].PartType<>0Then CurrActive:=2;
   '3':If Partition.PartTable[2].PartType<>0Then CurrActive:=3;
   '4':If Partition.PartTable[3].PartType<>0Then CurrActive:=4;
   #13:Begin
    Partition.PartTable[0].Status:=0;
    Partition.PartTable[1].Status:=0;
    Partition.PartTable[2].Status:=0;
    Partition.PartTable[3].Status:=0;
    Partition.PartTable[CurrActive-1].Status:=$80;
    WritePartitionRecord;
    Exit;
   End;
   #27:Exit;
  End;
 Until False;
End;

Procedure DeletePartition;Begin
 ClrScr;
 WriteLn('Cette fonctionnalit� n''est pas implement� !');
 Write(' ':2,'Appuyez sur ');
 HighVideo;
 Write('ECHAP');
 LowVideo;
 Write(' pour quitter FDISK');
 ReadKey;
End;

Procedure ShowPartition;Begin
 ClrScr;
 WriteLn;
 WriteLn;
 WriteLn;
 WriteLnCenter('Affichage des informations sur les partitions');
 WriteLn;
 WriteListPartition;
 GotoXY(1,25);
 Write(' ':2,'Appuyez sur ');
 HighVideo;
 Write('ECHAP');
 LowVideo;
 Write(' pour quitter FDISK');
 ReadKey;
End;

Procedure SelectFixedDisk;Begin
 ClrScr;
 WriteLn('Cette fonctionnalit� n''est pas implement� !');
 Write(' ':2,'Appuyez sur ');
 HighVideo;
 Write('ECHAP');
 LowVideo;
 Write(' pour quitter FDISK');
 ReadKey;
End;

Function ShowMainMenu:Byte;
Var
 Choice:Char;
Begin
 ShowMainMenu:=0;
 Choice:='4';
 TextBackground(0);
 TextColor(7);
 ClrScr;
 WriteLnCenter('Ensemble Corail');
 WriteLnCenter('FDISK');
 WriteLnCenter('Gladir.com licence MIT 2022');
 WriteLn;
 HighVideo;
 Case Language of
  _English: WriteLnCenter('Fixed Disk Setup Program');
  Else WriteLnCenter('Options de FDISK');
 End;
 WriteLn;
 LowVideo;
 Case Language of
  _English:Write(' ':4,'Current Fixed Disk Drive: ');
  Else Write(' ':4,'Lecteur de disque dur en cours : ');
 End;
 HighVideo;
 If FileName<>''Then WriteLn(FileName)
                Else WriteLn(CurrentDisk);
 LowVideo;
 WriteLn;
 Case Language of
  _English:WriteLn(' ':4,'Choose one of the following: ');
  Else WriteLn(' ':4,'Choisissez parmi ce qui suit : ');
 End;
 WriteLn;
 HighVideo;
 Write(' ':4,'1. ');
 LowVideo;
 Case Language of
  _English: WriteLn('Create DOS Partition');
  Else WriteLn('Cr�ation d''une partition ou lecteur logique DOS');
 End;
 HighVideo;
 Write(' ':4,'2. ');
 LowVideo;
 Case Language of
  _English:WriteLn('Change Active partition');
  Else WriteLn('Activation d''une partition');
 End;
 HighVideo;
 Write(' ':4,'3. ');
 LowVideo;
 Case Language of
  _English:WriteLn('Delete DOS partition');
  Else WriteLn('Suppression d''une partition ou lecteur logique DOS');
 End;
 HighVideo;
 Write(' ':4,'4. ');
 LowVideo;
 Case Language of
  _English:WriteLn('Display Partition Data');
  Else WriteLn('Affichage des informations sur les partitions');
 End;
 HighVideo;
 Write(' ':4,'5. ');
 LowVideo;
 Case Language of
  _English:WriteLn('Select Next Fixed Disk Drive');
  Else WriteLn('S�lectionne le prochain unit� de disque dur');
 End;
 WriteLn;
 WriteLn;
 WriteLn;
 Case Language of
  _English:Write(' ':4,'Entrer choice: ');
  Else Write(' ':4,'Entrez votre choix : ');
 End;
 HighVideo;
 WriteLn('[',Choice,']');
 LowVideo;
 WriteLn;
 WriteLn;
 WriteLn;
 Case Language of
  _English:Begin
   Write(' ':4,'Press ');
   HighVideo;
   Write('Esc');
   LowVideo;
   Write(' to return to DOS');
  End;
  Else Begin
   Write(' ':4,'Appuyez sur ');
   HighVideo;
   Write('ECHAP');
   LowVideo;
   Write(' pour quitter FDISK');
  End;
 End;
 Repeat
  GotoXY(27,19);
  Write(Choice);
  GotoXY(27,19);
  Case ReadKey of
   #0:ReadKey;
   #13:Begin
    Case Choice of
     '1':ShowMainMenu:=1;
     '2':ShowMainMenu:=2;
     '3':ShowMainMenu:=3;
     '4':ShowMainMenu:=4;
     '5':ShowMainMenu:=5;
    End;
    Exit;
   End;
   #27:Exit;
   '1':Choice:='1';
   '2':Choice:='2';
   '3':Choice:='3';
   '4':Choice:='4';
   '5':Choice:='5';
  End;
 Until False;
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
  WriteLn('FDISK : Cette commande permet d''effectuer la gestion d''un disque dur.');
  WriteLn;
  WriteLn('Syntaxe : FDISK [fichier]');
 End
  Else
 Begin
  If SizeOf(PartSec)<>512 Then Begin
   WriteLn('Mauvaise directive de compilation. Les enregistrements ne doivent pas �tre align�s');
   Halt;
  End;
  FileName:='';
  CurrentDisk:=1;
  IsDisk:=True;
  If ParamStr(1)<>''Then Begin
   FileName:=ParamStr(1);
   IsDisk:=False;
  End;
  Repeat
   Case ShowMainMenu of
    0:Break;
    1:CreatePartition;
    2:ActivePartition;
    3:DeletePartition;
    4:ShowPartition;
    5:SelectFixedDisk;
   End;
  Until False;
  ClrScr;
 End;
END.
