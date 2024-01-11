{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program DIRST;

{$A-}

Uses Strings,DOS;

Const
  { Constante de partition de disque dur }
 MinPart=1;                  { Nombre minimal partition }
 MaxPart=4;                  { Nombre maximal partition }

 vxDOSEmu=0;               { Volume de format DOSEmu }
 vxVirtualPC=100;          { Volume de format Virtual PC }

 OfsBF=12;        { DÇplacement dans le ShortBF }

 ciPopF=$9D;{POPF,88+}

Type
 EntreeRepert=Record
  NomFichier:Array[1..8]of Char;
  ExtFichier:Array[1..3]of Char;
  Attr:Byte;
  Rien:Array[1..10]of Char;
  Time:LongInt;
  PremCluster:Word;
  Size:LongInt;
 End;

 {Structure de lecture pour la disquette}
 SecPosType=Record
  Head:Byte;
  SectTrack:Word;
 End;

 {Structure de partition}
 PartEntryType=Record
  Status:Byte;
  StartSec:SecPosType;
  PartType:Byte;
  EndSec:SecPosType;
  SecOfs,NumSec:LongInt;
 End;

  {Structure de Boot}
 PartSecType=Record
  BootCode:Array[0..$1BD]of Byte;
  PartTable:Array[MinPart..MaxPart]of PartEntryType;
 End;

   {Entàte de fichier image DOSEMU correspondant Ö des disques dur}
 DosEmuHeader=Record
  Sign:Array[0..6]of Char; { Signature: 'DOSEMU'#0 }
  Heads:LongInt;           { Nombre de t^te }
  SectorPerTrack:LongInt;  { Secteur par piste }
  Track:LongInt;           { Nombre de pistes }
  ResA:LongInt;            { êgale Ö 128 ?? }
  ResB:Array[23..127]of Byte;{ InutilisÇe }
 End;

 ConnectixVirtualPCHeader=Record
  Sign:Array[0..7]of Char; { Signature: 'conectix' }
 End;

 FileSystemObject=Record
   { ATTENTION!!! Bloc de 17 octets a ne pas dÇplacer }
  BytesPerSector:Word;   { Octets par secteur (dÇplacement 11 du tampon, 2 octets) }
  SectorsPerCluster:Byte;{ Secteur par Cluster (Offset 13 du tampon, 1 octet) }
  SectorsReserved:Word;  { Secteur rÇservÇs (Offset 14 du tampon, 2 octets) }
  NumberOfFATs:Byte;     { Nombre de FATs (Offset 16 du tampon, 1 octet) }
  MaxEntry:Word;         { Nombre maximal d'entr?e (Offset 17 du tampon, 2 octets) }
  RawTotSects:Word;      { Total de secteur brute (Offset 19 du tampon, 2 octets) }
  Media:Byte;            { Type de mÇdia (Offset 21 du tampon, 1 octet) }
  SectorsPerFat:Word;    { Secteurs par FAT (Offset 22 du tampon, 2 octets) }
  SectorsPerTrack:Word;  { Secteurs par piste (Offset 24 du tampon, 2 octets) }
  NumberHeads:Word;      { Nombre de tàtes (Offset 26 du tampon, 2 octets) }
   { DonnÇes normal }
  FatBits:Byte;          { Nombre de bits utilisÇ par la FAT 12, 16, 32 }
  NumTotalSector:LongInt;{ Nombre total de secteur }
  SizeCluster:LongInt;   { Taille d'une unitÇ d'allocation }
  SectorsPerRoot:Word;   { Nombre de secteur par rÇpertoire racine }
  FirstRoot:LongInt;     { Premier secteur du rÇpertoire racine }
  FirstFAT:Word;         { Premier secteur de FAT }
  FirstSectorData:LongInt;{ Premier secteur des fichiers, calcul? }
  TotalTrack:Word;       { Nombre de pistes, calculÇ }
  TotalClusters:LongInt; { Nombre d'unitÇ d'allocation (pour les fichiers) }
  ClusterByFatSector:Word;{Nombre d'unitÇ d'allocation par secteur de FAT }
   { Variable de navigation }
  Dsk:Byte;                     { UnitÇ courante }
  StartSecFat:Word;
  CurrSecFat:Byte;
  MaxSecFat:Word;
  CurrSectorFAT:Array[0..511]of Byte; { Secteur de FAT courant }
   { Variable d'objet de manipulation }
  IsFileImage:Boolean;   { Est-ce un fichier utilisÇ comme disque? }
  ID:Byte;               { Identificateur de modäle: 0=DOSEmu, 1=Virtual PC}
  Handle:File;           { Handle du fichier image }
  FileStart:LongInt;     { Position de dÇpart dans le fichier image }
  FileSize:LongInt;      { Fin du fichier d'image }
  Method:Byte;           { MÇthode: 0=DOS, 1=BIOS }
  EBIOS:Boolean;         { Lecture par EBIOS? }
 End;

 Search32Rec=Record
  Fill:Array[1..2]of Byte;      { NumÇro de ressource associÇ }
  FirstCluster,NmCluster:Word;  { Premier cluster et le nombre cluster }
  PtrDescr:PChar;               { Pointeur sur la description/nom long }
  Attr:Byte;                    { Attribut }
  Time,Size:LongInt;            { Temps et taille }
  Name:String[12];              { Nom du fichier }
 End;

 TSearch32Rec=Array[0..65500div SizeOf(Search32Rec)]of Search32Rec;
 FileSort=(fUnsort,fName,fExt,fSize,fTime);

 BF=Record
  Buffer:^TSearch32Rec;
  SizeB:Word;
  Init:Boolean;       { Initialiser? }
  SizeFiles:LongInt;  { Taille total des fichiers }
  Tri:FileSort;       { Tri sortie par (Name, Extension,...) }
  Compressed:Boolean; { S'agit-il d'un rÇpertoire compressÇ dans un fichier? }
 End;

 Str8=String[8];
 Str12=String[12];

 BootRec=Record{Structure du secteur D,marrage (Boot)}
  JmpCode:Array[0..2]of Byte;    {Code au saut ex,cutable}
  OEMName:Array[0..7]of Char;    {Nom OEM et Version}
  BytesPerSec:Word;              {Octets par secteur}
  SecPerCluster:Byte;            {Secteur par cluster}
  NmResSecs:Word;                {Nombre de secteur r,serv,}
  NmFAT:Byte;                    {Nombre de FAT}
  NmRootDirEntries:Word;         {Nombre d'entrÇe dans le r,pertoire "\"}
  NmTotSec:Word;                 {Nombre total de secteur}
  Media:Byte;                    {Type de mÇdia (dskMedia???)}
  SecPerFAT:Word;                {Secteur par FAT}
  SecPerTrk:Word;                {Dos 3.0+: Secteur par cylindre}
  NmHeads:Word;                  {Dos 3.0+: Nombre de tàtes}
  NmHiddenSec:Word;              {Dos 3.0+: Nombre de secteur cachÇ}
  ResA:Word;                     {RÇservÇ}
  HughNmSec:LongInt;             {Dos 4+: Nombre de secteur si NmSec=0}
  PhysDrvNm:Byte;                {Dos 4+: NumÇro physique du volume}
  ResB:Byte;                     {Dos 4+: RÇservÇ}
  Sign:Byte;                     {Dos 4+: Octet de signature (29h)}
  SerialNm:LongInt;              {Dos 4+: NumÇro de sÇrie du volume}
  VolumeName:Array[0..10]of Char;{Dos 4+: Nom du volume}
  ResC:Array[0..457]of Byte;     {Relatif,gÇnÇralement du code machine...}
 End;

Var
 I:Integer;
 SysErr:Word;
 Q:BF;
 T:DateTime;
 Info:SearchRec;
 NumFiles:Word;
 FindPath,FileImage:String;

{$IFDEF FPC}
 Function MaxAvail:LongInt;Begin
  MaxAvail:=High(LongInt);
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

Function Left(Const Str:String;Num:Byte):String;Begin
 Left:=Copy(Str,1,Num);
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

Function Path2Ext(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2Ext:=E;
End;

Function Path2Dir(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2Dir:=D;
End;

Function Path2NoDir(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2NoDir:=N+E;
End;

Procedure SwapByte(Var a,b:Byte);
Var
 T:Byte;
Begin
 T:=a;
 a:=b;
 b:=T;
End;

Procedure SwapWord(Var a,b:Word);
Var
 T:Word;
Begin
 T:=a;
 a:=b;
 b:=T;
End;

Procedure ReadDsk(Drive:Byte;LSN,Sects:Word;Var Buffer);
{$IFDEF Win32}
 Begin
  FillChar(Buffer,SizeOf(BootRec),0);
 End;
{$ELSE}
 {$IFDEF DPMI}
  Begin
   FillChar(Buffer,SizeOf(BootRec));
  End;
 {$ELSE}
 Assembler;ASM
  PUSH BP
  PUSH DS
   MOV AL,Drive
   MOV DX,LSN
   MOV CX,Sects
   LDS BX,Buffer
   INT 025h
   JB  @Suite
   XOR AX,AX
 @Suite:
   DB ciPOPF
  POP DS
  POP BP
  CMP AX,519
  JNE @No32Bits
  PUSH BP
  PUSH DS
   MOV AL,Drive
   MOV DX,LSN
   MOV CX,Sects
   MOV BX,Offset Buffer
   MOV DS:[BX],DX
   MOV DS:[BX+2].Word,0
   MOV DS:[BX+4],CX
   LES DI,Buffer
   MOV DS:[BX+6],DI
   MOV DS:[BX+8],ES
   MOV CX,0FFFFh
   INT 025h
   JB  @Suite2
   XOR AX,AX
 @Suite2:
   DB ciPOPF
  POP DS
  POP BP
 @No32Bits:
  MOV SysErr,AX
 End;
 {$ENDIF}
{$ENDIF}

Function ActionSectorEBIOS(Action:Word;Dsk:Byte;LBA:LongInt;Count:Word;Var Buffer):Boolean;Near;
{$IFDEF Real}
 Var
  Block:Record
   Size:Byte;
   Res:Byte;
   Count:Word;
   Addr:Pointer;
   LBAlo:Longint;
   LBAhi:Longint;
  End;
  SegBuf,OfsBuf:Word;
 Begin
  FillChar(Block,SizeOf(Block),0);
  Block.Size:=SizeOf(Block);
  Block.Count:=Count;
  Block.Addr:=@Buffer;
  Block.LBAlo:=LBA;
  SegBuf:=Seg(Block);
  OfsBuf:=Ofs(Block);
  ASM
   PUSH DS
    MOV AX,Action
    MOV DL,Dsk
    MOV DS,SegBuf
    MOV SI,OfsBuf
    INT 13h
    MOV AL,0
    ADC AL,AL
    XOR AL,1
   POP DS
   MOV @Result,AL
  END;
 End;
{$ELSE}
 Begin
 End;
{$ENDIF}

Function ReadSectorEBIOS(Dsk:Byte;LBA:LongInt;Count:Word;Var Buffer):Boolean;Begin
 ReadSectorEBIOS:=ActionSectorEBIOS($4200,Dsk,LBA,Count,Buffer);
End;

Function IsMountDriveDOSEmu(Var Buffer):Boolean;
Var
 Header:DosEmuHeader Absolute Buffer;
Begin
 IsMountDriveDOSEmu:=(Header.Sign='DOSEMU'#0);
End;

Function IsMountDrive(Var Buffer):Boolean;
Var
 VirtualPC:ConnectixVirtualPCHeader Absolute Buffer;
Begin
 IsMountDrive:=IsMountDriveDOSEmu(Buffer)or(VirtualPC.Sign='conectix');
End;

Procedure FSReadDsk(Var Q:FileSystemObject;LSN,Sects:LongInt;Var Buffer);
Var
 BBuffer:Array[0..511]of Byte Absolute Buffer;
 WBuffer:Array[0..1]of Word Absolute Buffer;
 LongPos:LongInt Absolute Buffer;
 ByteReaded:Integer;
Begin
 If(Q.IsFileImage)Then Begin
  If Q.FileSize<LongInt(LongInt(LSN)shl 9)+LongInt(Q.FileStart)Then Begin
   WriteLn('Position en dehors de la taille du disque : ',
           LongInt(LongInt(LSN)shl 9)+LongInt(Q.FileStart));
   Halt;
  End;
  Seek(Q.Handle,LongInt(LongInt(LSN)shl 9)+LongInt(Q.FileStart));
  BlockRead(Q.Handle,Buffer,512,ByteReaded);
 End
  Else
 Begin
  If Q.Method=1Then Begin
   If(Q.EBIOS)Then ReadSectorEBIOS(Q.Dsk,LSN,Sects,Buffer)
    Else
   Begin
    {GetSectCyl(LSN,Secteur,Cylindre);
    ReadSectorBIOS(Q.Dsk,,,Buffer);}
   End;
  End
   Else
  ReadDsk(Q.Dsk,LSN,Sects,Buffer);
 End;
End;

Function SearchStartImageDisk(Var Handle:File;FindFAT:Boolean;Var _FileSize,FileStart:LongInt;Var ID:Byte):Boolean;
Var
 Buffer:Array[0..511+128]of Byte;
 WBuffer:Array[0..1]of Word Absolute Buffer;
 LongPos:LongInt Absolute Buffer;
 Q:Record
  Header:DosEmuHeader;
  Part:PartSecType;
 End Absolute Buffer;
 I:Byte;
 ByteReaded:Integer;
Begin
 SearchStartImageDisk:=False;
 _FileSize:=FileSize(Handle);
 FileStart:=0;
 ID:=0;
 Seek(Handle,0);
 BlockRead(Handle,Q,SizeOf(DosEmuHeader)+SizeOf(PartSecType),ByteReaded);
 If(Buffer[0]=Byte('T'))and(Buffer[1]=Byte('D'))Then Begin { Image TeleDisk? }
  FileStart:=$3D;
  SearchStartImageDisk:=True;
 End
  Else
 If(Buffer[0]=$AA)and(Buffer[1]=$59)Then Begin { Fichier image IBM OS/2 }  FileStart:=$29;
  SearchStartImageDisk:=True;
 End
  Else
 If IsMountDrive(Q.Header)Then Begin
  SearchStartImageDisk:=True;
  If IsMountDriveDOSEmu(Q.Header)Then FileStart:=SizeOf(DosEmuHeader)
   Else
  Begin
   ID:=vxVirtualPC;
   Seek(Handle,$0600);
   BlockRead(Handle,LongPos,SizeOf(LongPos),ByteReaded);
   SwapByte(Buffer[0],Buffer[1]);
   SwapByte(Buffer[2],Buffer[3]);
   SwapWord(WBuffer[0],WBuffer[1]);
   FileStart:=LongInt(Succ(LongPos))shl 9;
  End;
  If(FindFAT)Then For I:=1to 4do Begin
   If(Q.Part.PartTable[I].PartType)in[1,4]Then Begin { FAT12 ou FAT16?}
    Inc(FileStart,LongInt((Q.Part.PartTable[I].StartSec.Head*
                 Q.Header.SectorPerTrack+
                 Q.Part.PartTable[I].SecOfs)shl 8));
    Break;
   End;
  End;
 End;
End;


Procedure FSInit(Var Q:FileSystemObject);Begin
 FillChar(Q,SizeOf(Q),0);
End;

Function FSOpen(Var Q:FileSystemObject;Const FileImage:String;FindFAT:Boolean):Boolean;
Var
 Ext:ExtStr;
Begin
 FSOpen:=False;
 FSInit(Q);
 Q.IsFileImage:=FileImage<>'';
 If(Q.IsFileImage)Then Begin
  {$I-}Assign(Q.Handle,FileImage);
  Reset(Q.Handle,1);{$I+}
  Q.FileSize:=FileSize(Q.Handle);
  If IoResult<>0 Then Begin
   WriteLn('Erreur de lecture du fichier d''image');
   Halt;
  End;
  Ext:=StrToUpper(Path2Ext(FileImage));
  If(Ext='.144')or(Ext='.IMA')or(Ext='.IMG')or(Ext='.DSK')or(Ext='.ST')Then Begin
   Q.FileStart:=0;
  End
   Else
  Begin
   If Not(SearchStartImageDisk(Q.Handle,FindFAT,Q.FileSize,Q.FileStart,Q.ID))Then Exit;
  End;
 End;
 FSOpen:=True;
End;

{ Cette fonction permet d'analyser le contenu d'un secteur de d?marrage
 et de rÇunir des informations pertinente.
}

Procedure FSBootAnalysers(Var Q:FileSystemObject;Const Buffer);
Var
 Boot:BootRec Absolute Buffer;
 BBuffer:Array[0..511] of Byte Absolute Buffer;
 TempLong:LongInt;
Begin
 Move(BBuffer[11],Q,17);
 If Q.BytesPerSector=0Then Q.BytesPerSector:=512;
 If Q.NumberOfFATs=0Then Q.NumberOfFATs:=2;
 Q.NumTotalSector:=Boot.NmTotSec;
 If Boot.NmTotSec=0Then Q.NumTotalSector:=Boot.HughNmSec;
 If Boot.BytesPerSec=0Then Q.SizeCluster:=Boot.SecPerCluster*512
                      Else Q.SizeCluster:=Boot.SecPerCluster*Boot.BytesPerSec;
 Q.FirstFAT:=Q.SectorsReserved;
 Q.FirstRoot:=Q.SectorsReserved+(Q.NumberOfFATs*Q.SectorsPerFat);
 Q.SectorsPerRoot:=(Q.MaxEntry shl 5)div Q.BytesPerSector;
 Q.FirstSectorData:=Q.FirstRoot+Q.SectorsPerRoot;
 If(Q.MaxEntry*32)mod Q.BytesPerSector<>0Then Inc(Q.SectorsPerRoot);
 TempLong:=(LongInt(Q.NumTotalSector) div (LongInt(Q.NumberHeads)*LongInt(Q.SectorsPerTrack)));
 Q.TotalTrack:=TempLong;
 If TempLong-Q.TotalTrack>0Then Inc(Q.TotalTrack);
 TempLong:=(LongInt(Q.NumTotalSector)-LongInt(Q.FirstSectorData))div LongInt(Q.SectorsPerCluster);
 Q.TotalClusters:=TempLong;
 Q.ClusterByFatSector:=256;
 If Q.NumTotalSector>=$FFF8Then Q.FatBits:=32 Else
 If Q.NumTotalSector>=$FF8Then Q.FatBits:=16
  Else
 Begin
  Q.ClusterByFatSector:=384;
  Q.FatBits:=12;
 End;
End;

Function FSGetCluster(Var Q:FileSystemObject;P:Word):Word;Near;
Var
 Value:Word;
Begin
 If(P shr 9<>Q.CurrSecFat)Then Begin
  Q.CurrSecFat:=P shr 9;
  FSReadDsk(Q,Q.StartSecFat+Q.CurrSecFat,1,Q.CurrSectorFAT);
 End;
 Move(Q.CurrSectorFAT[P and 511],Value,SizeOf(Word));
 FSGetCluster:=Value;
End;

Function FSGetClusterL(Var Q:FileSystemObject;P:LongInt):Word;Near;
Var
 Value:Word;
Begin
 If(P shr 9<>Q.CurrSecFat)Then Begin
  Q.CurrSecFat:=P shr 9;
  FSReadDsk(Q,Q.StartSecFat+Q.CurrSecFat,1,Q.CurrSectorFAT);
 End;
 Move(Q.CurrSectorFAT[P and 511],Value,SizeOf(Word));
 FSGetClusterL:=Value;
End;

Function FSFindNextElementFat(Var Q:FileSystemObject;Cluster:Word):Word;
Var
 El,Temp:Word;
Begin
 Case(Q.FatBits)of
  32:FSFindNextElementFat:=FSGetClusterL(Q,LongInt(Cluster)shl 1);
  16:FSFindNextElementFat:=FSGetCluster(Q,Cluster shl 1);
  Else Begin
   Temp:=3*Cluster;
   El:=FSGetCluster(Q,Temp shr 1);{ SHR = /2 }
   If Odd(Cluster)Then FSFindNextElementFat:=El shr 4
                  Else FSFindNextElementFat:=El and $0FFF;
  End;
 End;
End;


Procedure _LoadPath(Var Q:BF;Const FileImage:String;Var NmF:Word;Path:String;At:Word);
Label Restart,BrkF,Brki2,Skip,NoImage,Xit;
Var
 FS:FileSystemObject;
 Masque:String;
 Err:Word;
 Buffer:Array[0..15]of EntreeRepert;
 FinList:Boolean;
 i,j,k,l:Word;
 Secteur:LongInt;
 i2:Byte;
 Sx:String;
 UnElement:EntreeRepert;
 Sdc:Byte;
 Choix:Str12;
 PremierSect,NbrSect:LongInt;
 RootDir:Boolean;
 Etoile,Point:Byte;
 Element:Record
  Data:Record Case Byte of
   0:(Nom,Ext:String);
   1:(Raw:Array[0..13]of Char);
  End;
 End;

 Procedure Get;
 Var
  Buffer:Array[0..511]of Byte;
 Begin
  FSReadDsk(FS,0,1,Buffer);
  If SysErr<>0Then Exit;
  FSBootAnalysers(FS,Buffer);
  FS.StartSecFat:=FS.FirstFat;
  FS.MaxSecFat:=FS.SectorsPerFat-1;
  FS.CurrSecFat:=0;
 End;

Begin
 If(Not FSOpen(FS,FileImage,True))Then Goto NoImage;
 Path:=FExpand(Path);
 Q.SizeFiles:=0;
 FS.Dsk:=Byte(Path[1])-65;
 Masque:=Path2NoDir(Path);
 Path:=Copy(Path2Dir(Path),4,255);
 If Masque=''Then Masque:='*.*';
 Masque:=StrToUpper(Masque);
 StrPCopy(@Element.Data.Raw,#8'????????'#3'???');
 Point:=Pos('.',Masque);
 If Point<>0Then Begin
  Element.Data.Ext:=Copy(Masque,Point+1,Length(Masque)-Point);
  If Element.Data.Ext=''Then Element.Data.Ext:='   ';
  Element.Data.Ext:=Element.Data.Ext+'???';
  Etoile:=Pos('*',Element.Data.Ext);
  If Etoile<>0Then For k:=etoile to 3do Element.Data.Ext[k]:='?';
  Dec(Point);
 End
  Else
 Point:=Length(Masque);
 Element.Data.Nom:=Left(Masque,Point)+Element.Data.Nom;
 Etoile:=Pos('*',Element.Data.Nom);
 If Etoile<>0Then For k:=Etoile to 8do Element.Data.Nom[k]:='?';
 Move(Element.Data.Raw[1],Masque[1],12);
 Masque[9]:='.';
 Masque[0]:=#12;
 Get;
 FSReadDsk(FS,FS.StartSecFat,1,FS.CurrSectorFAT);
 If SysErr<>0Then Goto Xit;
 PremierSect:=FS.FirstRoot;
 NbrSect:=FS.SectorsPerRoot;
 RootDir:=True;
 Begin
Restart:
  Secteur:=PremierSect;Sdc:=0;
  For i:=0to NbrSect-1do Begin
   FSReadDsk(FS,Secteur,1,Buffer);
   If SysErr<>0Then Goto Xit;
   For j:=0to 15do Begin
    Move(Buffer[j],UnElement,32);
    With UnElement do Begin
     If(NomFichier[1]=#0)and(J=0)and(Sdc=0)Then Goto Xit; { Arr^ter on frappe du beurre!}
     If NomFichier[1]<>#0Then Begin
      Choix[0]:=#12;Move(NomFichier[1],Choix[1],8);
      Choix[9]:='.';Move(ExtFichier[1],Choix[10],3);
      For k:=1to 12do If Masque[k]='?'Then Choix[k]:='?';
 BrkF:Move(NomFichier,Sx[1],8);
      For i2:=8downto 1do If NomFichier[i2]>' 'Then Begin
       Sx[0]:=Chr(i2);
       Break;
      End;
      If ExtFichier[1]>' 'Then Begin
       Sx:=Sx+'.';
       Sx:=Sx+ExtFichier;
      End;
      Sx:=RTrim(Sx);
      If((Choix=Masque)and(At and Attr=Attr))or(Attr and At and Directory=Directory)Then If Path=''Then
      If Not((Attr and Directory=Directory)and(NomFichier[1]='.')and(NomFichier[2]<>'.'))Then Begin
       If(NomFichier[1]='Ü')Then Begin
        If Hi(At)<>$FFThen Goto Skip;
       End;
       FillChar(Q.Buffer^[NmF],SizeOf(Q.Buffer^[NmF]),0);
       Q.Buffer^[NmF].Name:=Sx;
       Q.Buffer^[NmF].Size:=Size;
       Q.Buffer^[NmF].Time:=Time;
       Q.Buffer^[NmF].Attr:=Attr;
       Q.Buffer^[NmF].FirstCluster:=PremCluster;
       Q.Buffer^[NmF].NmCluster:=k;
       Inc(Q.SizeFiles,Size);
       Inc(NmF);
 Skip:End;
     End;
     If(Attr and Directory=Directory)and Not(NomFichier[1]in[#0,'.',' ',#$E5])Then Begin
      For i2:=1to Length(Path)do If Path[i2]='\'Then Goto Brki2;
Brki2:If Path[i2]<>'\'Then Inc(i2);
      If(Left(Path,i2-1)=Sx)Then Begin
       k:=0;l:=PremCluster;
       Repeat
        l:=FSFindNextElementFat(FS,l);
        If l=0Then FinList:=True
         Else
        Begin
         Inc(k);
         If k>=$FFF8Then Goto BrkF;
         If FS.FatBits>=16Then finlist:=l>=$FFF8
                          Else finlist:=l>=$FF8;
        End;
       Until FinList;
       l:=(PremCluster-2)*FS.SectorsPerCluster+FS.FirstSectorData;
       k:=k*FS.SectorsPerCluster;
       Path:=Copy(Path,i2+1,255);
       PremierSect:=l;NbrSect:=k;RootDir:=False;
       Goto Restart;
      End;
     End;
    End;
   End;
   If(RootDir)Then Inc(Secteur)
    Else
   Begin
    Inc(Sdc);
    If Sdc>FS.SectorsPerCluster-1Then Begin
     k:=((LongInt(Secteur)-LongInt(FS.FirstSectorData))div LongInt(FS.SectorsPerCluster)+2);
     l:=FSFindNextElementFat(FS,k);
     Secteur:=(l-2)*FS.SectorsPerCluster+FS.FirstSectorData;
     Sdc:=0;
    End
     Else
    Inc(Secteur);
   End;
  End;
 End;
Xit:
 If(FS.IsFileImage)Then NoImage:Close(FS.Handle);
End;

Procedure LoadPath(Var Q:BF;Var NmF:Word;Path:String;At:Word);Begin
 _LoadPath(Q,'',NmF,Path,At);
End;

Procedure LoadPathByFileImage(Var Q:BF;Const FileImage:String;Var NmF:Word;Path:String;At:Word);Begin
 _LoadPath(Q,FileImage,NmF,Path,At);
End;

Procedure BFGetFile(Var Q:BF;P:Word;Var Info:SearchRec);Begin
 Info.Name:=Q.Buffer^[P].Name;
 Info.Attr:=Q.Buffer^[P].Attr;
 Info.Time:=Q.Buffer^[P].Time;
 Info.Size:=Q.Buffer^[P].Size;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('DIRST - Cette commande permet d''afficher la liste des fichiers d''une ',
                    'image disque .ST du Atari ST.');
  WriteLn;
  WriteLn('Syntaxe: DIRST [/?] /IMG:fichier [chemin]');
  WriteLn;
  WriteLn('/IMG:fichier    Indique le fichier d''image');
  WriteLn('chemin          Indique le chemin de recherche dans l''image.');
 End
  Else
 If ParamCount>0 Then Begin
  FileImage:='';
  FindPath:='C:\*.*';
  For I:=1 to ParamCount do Begin
   If StrToUpper(Copy(ParamStr(I),1,5))='/IMG:'Then Begin
    FileImage:=Copy(ParamStr(I),6,255);
   End
    Else
   Begin
    FindPath:=ParamStr(I);
    If Path2Dir(FindPath)=''Then FindPath:='C:\'+FindPath;
   End;
  End;
  If FileImage<>''Then Begin
   If MaxAvail<65520Then Q.SizeB:=MaxAvail Else Q.SizeB:=65520;
   GetMem(Q.Buffer,Q.SizeB);NumFiles:=0;
   LoadPathByFileImage(Q,FileImage,NumFiles,FindPath,$FFFF);
   For I:=0to NumFiles-1do Begin
    BFGetFile(Q,I,Info);
    Write(PadRight(Info.Name,13));
    If Info.Attr and Directory=Directory Then Begin
     Write(PadRight('<DIR>',9));
    End
     Else
    Write(Info.Size:9);
    UnpackTime(Info.Time,T);
    WriteLn(' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2),' ');
   End;
  End;
 End;
END.