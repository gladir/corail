{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2GEM;

{$A-}

Uses DOS;

Const
  {Type de compression Windows}
 bi_RGB=0;
 bi_RLE8=1;
 bi_RLE4=2;

  {Largeur maximale support�e (en pixels).}
 MaxWidth=4096;

  {Constantes du format GEM/IMG (Digital Research GEM, Atari ST).
   Toutes les valeurs num�riques de l'en-t�te sont stock�es en
   "big-endian" (octet de poids fort en premier), conform�ment �
   l'ordonnancement Motorola du 68000.}
 GEMVersion=1;          { Toujours 1 dans le format standard. }
 GEMPatternLen=2;       { Longueur en octets des motifs (pattern run). }
 GEMPixelDim=372;       { Dimension d'un pixel en 1/1000 de mm (~0.372 mm). }
 GEMColorModelRGB=0;    { Mod�le de couleur RGB pour l'extension XIMG. }

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
 SourceBMP,DestGEM:File;
 Header:HeaderBMP;
 BIH:BitMapInfoHeader;
 BMPBytesPerLine,ByteReaded,ByteWritten:Word;
 StartPos:LongInt;
 NumPal:Word;
 Palette:Array[0..255]of RGB32;
 BMPLine:Array[0..MaxWidth*3-1]of Byte;     { Ligne brute lue dans le BMP }
 PlaneBuf:Array[0..(MaxWidth div 8)+3]of Byte; { Tampon d'un plan-ligne }
 OutputName:String;
 ImageWidth,ImageHeight:Word;
 PlaneBytes:Word;        { Octets par ligne et par plan = (Width+7)div 8 }
 NumPlanes:Word;         { Nombre de plans : 1, 4 ou 8 }
 BMPBPL:LongInt;
 I,K:Integer;
 Y:LongInt;
 SourceRow:LongInt;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.GEM';
End;

  {�criture d'un mot 16 bits en big-endian (Motorola).}
Procedure WriteWordBE(W:Word);
Var
 Tmp:Array[0..1]of Byte;
Begin
 Tmp[0]:=Byte(W shr 8);
 Tmp[1]:=Byte(W and $FF);
 BlockWrite(DestGEM,Tmp,2,ByteWritten);
End;

Procedure WriteByte(B:Byte);
Begin
 BlockWrite(DestGEM,B,1,ByteWritten);
End;

  {Encode une "ligne de plan" (PlaneBytes octets) en utilisant le sch�ma RLE
   du format GEM/IMG :
     - Solid run     : un octet (color shl 7) or count, count = 1..127.
                       Color 0 = octet $00 (8 pixels noirs/index 0),
                       Color 1 = octet $FF (8 pixels blancs/index 1).
     - Bit string    : $80, count(1..255), count octets bruts.
   Les "pattern run" et "scanline run" sont autoris�s par la sp�cification
   mais facultatifs ; on ne les g�n�re pas ici, ce qui reste parfaitement
   conforme au format.}
Procedure EncodeRow(Var Buf:Array of Byte;Length:Word);
Var
 P,LStart:Word;
 RunByte,Cmd:Byte;
 RunCount,EmitN:Word;
Begin
 P:=0;
 While P<Length Do Begin
  RunByte:=Buf[P];
  If(RunByte=0)or(RunByte=$FF)Then Begin
    {D�tection d'une plage solide (octets identiques � $00 ou $FF).}
   RunCount:=1;
   While(P+RunCount<Length)and(Buf[P+RunCount]=RunByte)Do Inc(RunCount);
   While RunCount>0 Do Begin
    If RunCount>127 Then EmitN:=127
                    Else EmitN:=RunCount;
    If RunByte=0 Then Cmd:=Byte(EmitN)
                 Else Cmd:=Byte($80 or EmitN);
    WriteByte(Cmd);
    Dec(RunCount,EmitN);
    Inc(P,EmitN);
   End;
  End
   Else
  Begin
    {Cha�ne litt�rale : on regroupe jusqu'� 255 octets cons�cutifs qui
     ne sont ni $00 ni $FF.}
   LStart:=P;
   While(P<Length)and(Buf[P]<>0)and(Buf[P]<>$FF)
                 and(P-LStart<255)Do Inc(P);
   EmitN:=P-LStart;
   WriteByte($80);
   WriteByte(Byte(EmitN));
   BlockWrite(DestGEM,Buf[LStart],EmitN,ByteWritten);
  End;
 End;
End;

  {Lit la ligne brute du BMP (index RowIndex, 0 = haut) dans BMPLine.}
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

  {Convertit une composante 0..255 en valeur 0..1000 (�chelle XIMG).}
Function ToGEM(C:Byte):Word;
Begin
 ToGEM:=Word((LongInt(C)*1000+127)div 255);
End;

  {Construit la ligne du plan PlaneIdx pour la ligne BMP courante (BMPLine).
   Octets pack�s MSB-first : le bit 7 du premier octet correspond au pixel 0.}
Procedure BuildPlaneRow(PlaneIdx:Word);
Var
 X:Word;
 Idx:Byte;
Begin
 FillChar(PlaneBuf,PlaneBytes,0);
 For X:=0 to ImageWidth-1 Do Begin
  Idx:=GetPalIndex(X);
  If((Idx shr PlaneIdx)and 1)<>0 Then
   PlaneBuf[X shr 3]:=PlaneBuf[X shr 3]or Byte(1 shl (7-(X and 7)));
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BMP2GEM : Cette commande permet de convertir une image BitMap (.BMP) ',
                    'en format GEM/IMG (.GEM) de Digital Research GEM et Atari ST.');
  WriteLn;
  WriteLn('Syntaxe : BMP2GEM nomdufichier.BMP');
  WriteLn;
  WriteLn(' nomdufichier   Nom du fichier ".BMP" � convertir.');
  WriteLn;
  WriteLn('Le fichier r�sultant porte le m�me nom avec l''extension .GEM.');
  WriteLn('Seuls les BitMaps 1, 4 ou 8 bits par pixel non compress�s sont support�s.');
  WriteLn('La palette du BMP est conserv�e via l''extension XIMG pour les modes 4 et 8 bpp.');
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
  Close(SourceBMP);
  Halt;
 End;
 Seek(SourceBMP,14);
 BlockRead(SourceBMP,BIH,SizeOf(BIH),ByteReaded);
 If(BIH.biBitCount<>1)and(BIH.biBitCount<>4)and(BIH.biBitCount<>8)Then Begin
  WriteLn('Seuls les BitMaps 1, 4 ou 8 bits par pixel sont support�s pour la conversion en GEM !');
  Close(SourceBMP);
  Halt(2);
 End;
 If BIH.biCompression<>bi_RGB Then Begin
  WriteLn('Compression RLE4 ou RLE8 non support�');
  Close(SourceBMP);
  Halt(3);
 End;
 If(BIH.biWidth<=0)or(BIH.biHeight<=0)Then Begin
  WriteLn('Dimensions invalides !');
  Close(SourceBMP);
  Halt;
 End;
 If LongInt(BIH.biWidth)>MaxWidth Then Begin
  WriteLn('Image trop large (largeur max : ',MaxWidth,') !');
  Close(SourceBMP);
  Halt;
 End;

 If BIH.biSizeImage=0 Then
  BMPBPL:=((LongInt(BIH.biWidth)*LongInt(BIH.biBitCount)+31)div 32)*4
  Else
  BMPBPL:=LongInt(BIH.biSizeImage)div LongInt(BIH.biHeight);
 If(BMPBPL<=0)or(BMPBPL>SizeOf(BMPLine))Then Begin
  WriteLn('Largeur de l''image trop grande !');
  Close(SourceBMP);
  Halt;
 End;
 BMPBytesPerLine:=Word(BMPBPL);
 ImageWidth:=Word(BIH.biWidth);
 ImageHeight:=Word(BIH.biHeight);
 NumPlanes:=BIH.biBitCount;     { 1, 4 ou 8 plans }
 PlaneBytes:=Word((LongInt(ImageWidth)+7)div 8);

  {Lecture de la palette.}
 Case NumPlanes of
  1:NumPal:=2;
  4:NumPal:=16;
  8:NumPal:=256;
 End;
 Seek(SourceBMP,14+SizeOf(BitmapInfoHeader));
 BlockRead(SourceBMP,Palette,LongInt(NumPal)*4,ByteReaded);

 StartPos:=Header.OffBits;

  {Cr�ation du fichier de destination.}
 OutputName:=Path2NameExt(ParamStr(1));
 {$I-}Assign(DestGEM,OutputName);
 Rewrite(DestGEM,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de cr�er le fichier ',OutputName);
  Close(SourceBMP);
  Halt;
 End;

  {�criture de l'en-t�te GEM/IMG (16 octets, big-endian) suivi de l'extension
   XIMG pour les images en couleurs.
   Champ HeaderLen exprim� en mots 16 bits :
     - 1 plan (mono)        : 8 mots (16 octets, pas de XIMG).
     - 4 ou 8 plans (color) : 8 + (4+2+NumPal*6)/2 = 11 + 3*NumPal mots.}
 WriteWordBE(GEMVersion);
 If NumPlanes=1 Then
  WriteWordBE(8)
 Else
  WriteWordBE(Word(11+3*LongInt(NumPal)));
 WriteWordBE(NumPlanes);
 WriteWordBE(GEMPatternLen);
 WriteWordBE(GEMPixelDim);
 WriteWordBE(GEMPixelDim);
 WriteWordBE(ImageWidth);
 WriteWordBE(ImageHeight);
 If NumPlanes>1 Then Begin
   {Magie XIMG (4 octets ASCII) + ColorModel + N entr�es RGB sur 0..1000.}
  WriteByte(Ord('X'));WriteByte(Ord('I'));
  WriteByte(Ord('M'));WriteByte(Ord('G'));
  WriteWordBE(GEMColorModelRGB);
  For I:=0 to NumPal-1 Do Begin
   WriteWordBE(ToGEM(Palette[I].R));
   WriteWordBE(ToGEM(Palette[I].G));
   WriteWordBE(ToGEM(Palette[I].B));
  End;
 End;

  {Boucle sur les lignes de l'image. GEM est stock� de haut en bas, BMP de
   bas en haut : on traduit donc l'index source. Pour chaque ligne on �met
   les NumPlanes plans-lignes les uns derri�re les autres (entrelacement
   par plan), conform�ment � la sp�cification GEM.}
 For Y:=0 to LongInt(ImageHeight)-1 Do Begin
  SourceRow:=LongInt(ImageHeight)-1-Y;
  ReadBmpRow(SourceRow);
  For K:=0 to NumPlanes-1 Do Begin
   BuildPlaneRow(Word(K));
   EncodeRow(PlaneBuf,PlaneBytes);
  End;
 End;

 Close(DestGEM);
 Close(SourceBMP);
END.
