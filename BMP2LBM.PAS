{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2LBM;

{$A-}

Uses DOS;

Const
  {Type de compression Windows}
 bi_RGB=0;
 bi_RLE8=1;
 bi_RLE4=2;

  {Largeur maximale support�e (en pixels). Doit �tre un multiple de 16
   pour rester dans les limites de PlaneRow (cf. RowBytes ci-dessous).}
 MaxWidth=4096;

Type
 RGB32=Record
  B,G,R,FreeByte:Byte;
 End;

 HeaderBMP=Record
  Sign:Array[0..1]of Char;
  Size,Reserved0,OffBits:LongInt;
  biSize,NumXPixels,NumYPixels:LongInt;
  Planes,BitCount:Word;
  Compression,SizeImage:LongInt;
  XPelsPerMeter,YPelsPerMeter,ClrUsed,ClrImportant:LongInt;
 End;

 BitmapInfoHeader=Record
  biSize:LongInt;         { Sp�cifie le nombre d'octets requis pour la structure }
  biWidth:LongInt;        { Sp�cifie la largeur du BitMap en pixels }
  biHeight:LongInt;       { Sp�cifie la hauteur du BitMap en pixels }
  biPlanes:Word;          { Sp�cifie le nombre de plane pour la destination }
  biBitCount:Word;        { Sp�cifie le nombre de bits par pixel (1, 4, 8, 24)}
  biCompression:LongInt;  { Sp�cifie le style de compression: BI_RGB, BI_RLE8, BI_RLE4 }
  biSizeImage:LongInt;    { Sp�cifie la taille en octets pour l'image }
  biXPelsPerMeter:LongInt;{ Sp�cifie le nombre horizontal de pixels par mStre }
  biYPelsPerMeter:LongInt;{ Sp�cifie le nombre vertical de pixels par mStre }
  biClrUsed:LongInt;      { Sp�cifie le nombre de couleurs index�s dans la table}
  biClrImportant:LongInt; { Sp�cifie le nombre de couleurs index�s dans la table
                            en comptant ceux �tant vraiment indispensable � l'affichage}
 End;

Var
 SourceBMP,DestLBM:File;
 Header:HeaderBMP;
 BIH:BitMapInfoHeader;
 BMPBytesPerLine,ByteReaded,ByteWritten:Word;
 StartPos:LongInt;
 NumPal:Word;
 Palette:Array[0..255]of RGB32;
 BMPLine:Array[0..MaxWidth*3-1]of Byte; { Ligne brute lue dans le BMP }
 PixelLine:Array[0..MaxWidth-1]of Byte; { Indices de palette d�coul�s pour la ligne courante }
 PlaneRow:Array[0..(MaxWidth div 8)+1]of Byte; { Une ligne d'un plan (octets MSB->LSB) }
 OutputName:String;
 ImageWidth,ImageHeight:Word;
 BMPBPL:LongInt;
 Y:LongInt;
 SourceRow:LongInt;
 X:Word;
 LBMNPlanes:Byte;
 RowBytes:Word; { Nombre d'octets par plan et par ligne dans le BODY ILBM }

  {Pile de positions des champs "longueur" des chunks IFF en cours
   d'�criture. Quand un chunk est "ferm�", on r��crit sa longueur
   r�elle (en gros-boutien) � la position empil�e.}
 ChunkSizePos:Array[0..7]of LongInt;
 ChunkStart:Array[0..7]of LongInt;
 ChunkDepth:Integer;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.LBM';
End;

  {�crit un mot 16 bits "gros-boutien" (octet de poids fort en premier) :
   format utilis� par toutes les valeurs num�riques d'IFF/ILBM.}
Procedure WriteBE16(Value:Word);
Var
 B:Array[0..1]of Byte;
Begin
 B[0]:=Byte((Value shr 8)and $FF);
 B[1]:=Byte( Value        and $FF);
 BlockWrite(DestLBM,B,2,ByteWritten);
End;

  {�crit un mot 32 bits "gros-boutien" : longueur de chunk IFF.}
Procedure WriteBE32(Value:LongInt);
Var
 B:Array[0..3]of Byte;
Begin
 B[0]:=Byte((Value shr 24)and $FF);
 B[1]:=Byte((Value shr 16)and $FF);
 B[2]:=Byte((Value shr  8)and $FF);
 B[3]:=Byte( Value         and $FF);
 BlockWrite(DestLBM,B,4,ByteWritten);
End;

  {�crit un identificateur de chunk IFF (4 caract�res ASCII).}
Procedure WriteID(Const Id:String);
Var
 B:Array[0..3]of Char;
 I:Integer;
Begin
 For I:=0 to 3 Do
  If(I+1)<=Length(Id)Then B[I]:=Id[I+1] Else B[I]:=' ';
 BlockWrite(DestLBM,B,4,ByteWritten);
End;

  {Ouvre un chunk IFF : �crit son ID, r�serve 4 octets pour la longueur
   (qui sera renseign�e par EndChunk), et empile les positions n�cessaires.}
Procedure BeginChunk(Const Id:String);
Begin
 WriteID(Id);
 ChunkSizePos[ChunkDepth]:=FilePos(DestLBM);
 WriteBE32(0); { Longueur provisoire }
 ChunkStart[ChunkDepth]:=FilePos(DestLBM);
 Inc(ChunkDepth);
End;

  {Ferme le chunk courant : calcule sa longueur (taille des donn�es,
   sans compter ID/longueur), la r��crit en gros-boutien � la position
   r�serv�e, ajoute un octet de bourrage si la longueur est impaire,
   puis revient � la fin du fichier.}
Procedure EndChunk;
Var
 EndPos:LongInt;
 Size:LongInt;
 PadByte:Byte;
Begin
 EndPos:=FilePos(DestLBM);
 Dec(ChunkDepth);
 Size:=EndPos-ChunkStart[ChunkDepth];
 Seek(DestLBM,ChunkSizePos[ChunkDepth]);
 WriteBE32(Size);
 Seek(DestLBM,EndPos);
 If(Size and 1)<>0 Then Begin
  PadByte:=0;
  BlockWrite(DestLBM,PadByte,1,ByteWritten);
 End;
End;

  {Lit la ligne brute du BMP (RowIndex=0 �tant la premi�re ligne stock�e
   dans le fichier ; les BMP �tant "bottom-up", l'appelant doit inverser
   l'index avant l'appel pour parcourir l'image de haut en bas).}
Procedure ReadBmpRow(RowIndex:LongInt);
Begin
 Seek(SourceBMP,StartPos+RowIndex*LongInt(BMPBytesPerLine));
 BlockRead(SourceBMP,BMPLine,BMPBytesPerLine,ByteReaded);
End;

  {Renvoie l'index de palette pour le pixel X dans la ligne BMPLine, en
   fonction de la profondeur du BMP source (1, 4 ou 8 bits/pixel).}
Function GetPalIndex(X:Word):Byte;
Var
 ByteV:Byte;
Begin
 Case BIH.biBitCount of
  1:Begin
   ByteV:=BMPLine[X shr 3];
   GetPalIndex:=(ByteV shr (7-(X and 7)))and 1;
  End;
  4:Begin
   ByteV:=BMPLine[X shr 1];
   If(X and 1)=0 Then GetPalIndex:=ByteV shr 4
                 Else GetPalIndex:=ByteV and $0F;
  End;
  8:Begin
   GetPalIndex:=BMPLine[X];
  End;
  Else GetPalIndex:=0;
 End;
End;

  {Convertit la ligne courante (PixelLine) en un plan ILBM : pour le
   plan d'indice "Plane" (0 = bit de poids le plus faible), on extrait
   le bit correspondant de chaque pixel et on l'�crit dans PlaneRow,
   bit de poids fort en premier (le pixel 0 est dans le bit 7 de
   l'octet 0). La longueur en octets est RowBytes (toujours pair).}
Procedure BuildPlaneRow(Plane:Byte);
Var
 Col:Word;
 BitVal:Byte;
 ByteIdx:Word;
 BitInByte:Byte;
Begin
 FillChar(PlaneRow,RowBytes,0);
 For Col:=0 to ImageWidth-1 Do Begin
  BitVal:=(PixelLine[Col]shr Plane)and 1;
  If BitVal<>0 Then Begin
   ByteIdx:=Col shr 3;
   BitInByte:=7-(Col and 7);
   PlaneRow[ByteIdx]:=PlaneRow[ByteIdx]or(1 shl BitInByte);
  End;
 End;
End;

Var
 Plane:Byte;
 BMHDBuf:Array[0..19]of Byte;
 CMAPBuf:Array[0..255*3-1]of Byte;
 NumColors:Word;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BMP2LBM : Cette commande permet de convertir une image BitMap (.BMP) ',
                    'en format LBM (.LBM, IFF/ILBM Electronic Arts).');
  WriteLn;
  WriteLn('Syntaxe : BMP2LBM nomdufichier.BMP');
  WriteLn;
  WriteLn(' nomdufichier   Nom du fichier ".BMP" � convertir.');
  WriteLn;
  WriteLn('Le fichier r�sultant porte le m�me nom avec l''extension .LBM, encod�');
  WriteLn('en ILBM non compress� (FORM/BMHD/CMAP/BODY). Seuls les BitMaps 1, 4');
  WriteLn('ou 8 bits par pixel non compress�s sont support�s en entr�e.');
  Halt;
 End;
 If ParamCount<1 Then Begin
  WriteLn('Param�tre requis !');
  Halt;
 End;
 {$I-}Assign(SourceBMP,ParamStr(1));
 Reset(SourceBMP,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier d''image');
  Halt;
 End;
 BlockRead(SourceBMP,Header,SizeOf(Header),ByteReaded);
 If Header.Sign<>'BM'Then Begin
  WriteLn('Signature d''ent�te Bitmap introuvable !');
  Halt;
 End;
 Seek(SourceBMP,14);
 BlockRead(SourceBMP,BIH,SizeOf(BIH),ByteReaded);
 If(BIH.biBitCount<>1)and(BIH.biBitCount<>4)and(BIH.biBitCount<>8)Then Begin
  WriteLn('Seuls les BitMaps 1, 4 ou 8 bits par pixel sont support�s !');
  Halt(2);
 End;
 If BIH.biCompression<>bi_RGB Then Begin
  WriteLn('Compression non support�e');
  Halt(3);
 End;
 If(BIH.biWidth<=0)or(BIH.biHeight<=0)Then Begin
  WriteLn('Dimensions invalides !');
  Halt;
 End;
 If LongInt(BIH.biWidth)>MaxWidth Then Begin
  WriteLn('Image trop large (largeur max : ',MaxWidth,') !');
  Halt;
 End;

 If BIH.biSizeImage=0 Then Begin
  Case BIH.biBitCount of
   1: BMPBPL:=((LongInt(BIH.biWidth)+31)div 32)*4;
   4: BMPBPL:=((LongInt(BIH.biWidth)+7)div 8)*4;
   8: BMPBPL:=((LongInt(BIH.biWidth)+3)div 4)*4;
   Else BMPBPL:=0;
  End;
 End
  Else BMPBPL:=LongInt(BIH.biSizeImage)div LongInt(BIH.biHeight);
 If(BMPBPL<=0)or(BMPBPL>SizeOf(BMPLine))Then Begin
  WriteLn('Largeur de l''image trop grande !');
  Halt;
 End;
 BMPBytesPerLine:=Word(BMPBPL);

  {Lecture de la palette du BMP (1, 4 ou 8 bits par pixel).}
 NumPal:=Word(BIH.biClrUsed);
 If NumPal=0 Then NumPal:=1 shl BIH.biBitCount;
 Seek(SourceBMP,14+SizeOf(BitmapInfoHeader));
 BlockRead(SourceBMP,Palette,LongInt(NumPal)*SizeOf(RGB32),ByteReaded);

 ImageWidth:=Word(BIH.biWidth);
 ImageHeight:=Word(BIH.biHeight);
 StartPos:=Header.OffBits;
 LBMNPlanes:=BIH.biBitCount;
 RowBytes:=((ImageWidth+15)div 16)*2;

  {Cr�ation du fichier LBM de destination.}
 OutputName:=Path2NameExt(ParamStr(1));
 {$I-}Assign(DestLBM,OutputName);
 Rewrite(DestLBM,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de cr�er le fichier ',OutputName);
  Close(SourceBMP);
  Halt;
 End;

 ChunkDepth:=0;

  {FORM <size> ILBM ... }
 BeginChunk('FORM');
 WriteID('ILBM');

  {BMHD : 20 octets fixes, gros-boutien.
   Disposition (offset / type) :
     0  Word  width
     2  Word  height
     4  Int16 x (origine)            = 0
     6  Int16 y (origine)            = 0
     8  Byte  nPlanes
     9  Byte  masking                = 0 (mskNone)
    10  Byte  compression             = 0 (cmpNone)
    11  Byte  pad                     = 0
    12  Word  transparentColor        = 0
    14  Byte  xAspect                 = 1
    15  Byte  yAspect                 = 1
    16  Int16 pageWidth               = width
    18  Int16 pageHeight              = height}
 BMHDBuf[ 0]:=Byte((ImageWidth shr 8)and $FF);
 BMHDBuf[ 1]:=Byte( ImageWidth        and $FF);
 BMHDBuf[ 2]:=Byte((ImageHeight shr 8)and $FF);
 BMHDBuf[ 3]:=Byte( ImageHeight        and $FF);
 BMHDBuf[ 4]:=0; BMHDBuf[ 5]:=0; { x }
 BMHDBuf[ 6]:=0; BMHDBuf[ 7]:=0; { y }
 BMHDBuf[ 8]:=LBMNPlanes;
 BMHDBuf[ 9]:=0; { masking : aucun }
 BMHDBuf[10]:=0; { compression : aucune }
 BMHDBuf[11]:=0; { pad }
 BMHDBuf[12]:=0; BMHDBuf[13]:=0; { transparentColor }
 BMHDBuf[14]:=1; BMHDBuf[15]:=1; { xAspect, yAspect }
 BMHDBuf[16]:=Byte((ImageWidth shr 8)and $FF);
 BMHDBuf[17]:=Byte( ImageWidth        and $FF);
 BMHDBuf[18]:=Byte((ImageHeight shr 8)and $FF);
 BMHDBuf[19]:=Byte( ImageHeight        and $FF);
 BeginChunk('BMHD');
 BlockWrite(DestLBM,BMHDBuf,20,ByteWritten);
 EndChunk;

  {CMAP : 3 octets par couleur (R, G, B). On �crit toujours 2^nPlanes
   entr�es pour assurer la coh�rence avec les profondeurs (cas des
   palettes BMP tronqu�es). Les entr�es non d�finies sont laiss�es � 0.}
 NumColors:=1 shl LBMNPlanes;
 FillChar(CMAPBuf,LongInt(NumColors)*3,0);
 For X:=0 to NumPal-1 Do Begin
  If X>=NumColors Then Break;
  CMAPBuf[X*3+0]:=Palette[X].R;
  CMAPBuf[X*3+1]:=Palette[X].G;
  CMAPBuf[X*3+2]:=Palette[X].B;
 End;
 BeginChunk('CMAP');
 BlockWrite(DestLBM,CMAPBuf,LongInt(NumColors)*3,ByteWritten);
 EndChunk;

  {BODY : pour chaque ligne (de haut en bas), pour chaque plan
   (du bit de poids le plus faible au plus fort), on �met RowBytes
   octets de bits group�s MSB en premier (chunky -> planar). La
   compression est laiss�e � 0 (cmpNone) dans BMHD.}
 BeginChunk('BODY');
 For Y:=0 to LongInt(ImageHeight)-1 Do Begin
  SourceRow:=LongInt(ImageHeight)-1-Y;
  ReadBmpRow(SourceRow);
  For X:=0 to ImageWidth-1 Do PixelLine[X]:=GetPalIndex(X);
  For Plane:=0 to LBMNPlanes-1 Do Begin
   BuildPlaneRow(Plane);
   BlockWrite(DestLBM,PlaneRow,RowBytes,ByteWritten);
  End;
 End;
 EndChunk;

  {Fermeture de FORM.}
 EndChunk;

  {Garantie : si la taille du fichier est impaire (au-del� du dernier
   chunk EndChunk), un octet de bourrage est d�j� ajout� par EndChunk.
   Aucune action suppl�mentaire requise ici.}

 Close(DestLBM);
 Close(SourceBMP);
END.
