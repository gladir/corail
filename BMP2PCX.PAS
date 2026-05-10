{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2PCX;

{$A-}

Uses DOS;

Const
  {Type de compression Windows}
 bi_RGB=0;
 bi_RLE8=1;
 bi_RLE4=2;

  {Constantes du format PCX (ZSoft Picture eXchange).}
 PCXManufacturer=10;     { Identificateur ZSoft }
 PCXVersion=5;           { Paintbrush 3.0 et ult�rieur }
 PCXEncodingRLE=1;       { Run-Length Encoding (seul codage standardis�) }
 PCXPaletteColor=1;      { 1 = couleur, 2 = niveaux de gris }
 PCXVGAPaletteMarker=$0C;{ Marqueur pr�c�dant la palette VGA 256 couleurs }

  {Largeur maximale support�e (en pixels).}
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

  {En-t�te PCX : 128 octets, ordre Intel (octet de poids faible en premier).}
 HeaderPCX=Record
  Manufacturer:Byte;        { Toujours 10 (ZSoft) }
  Version:Byte;             { 0, 2, 3, 4 ou 5 }
  Encoding:Byte;            { Toujours 1 (RLE) }
  BitsPerPixel:Byte;        { Bits par pixel et par plan (1, 2, 4 ou 8) }
  Xmin,Ymin,Xmax,Ymax:Word; { Coordonn�es de la fen�tre image (incluses) }
  HDpi,VDpi:Word;           { R�solution horizontale et verticale }
  ColorMap:Array[0..47]of Byte; { Palette EGA 16 couleurs (3 octets RGB par entr�e) }
  Reserved1:Byte;           { R�serv�, mettre � 0 }
  NPlanes:Byte;             { Nombre de plans de couleur }
  BytesPerLine:Word;        { Octets par ligne et par plan (toujours pair) }
  PaletteInfo:Word;         { 1=couleur, 2=niveaux de gris }
  HscreenSize:Word;         { Taille horizontale de l'�cran source (Paintbrush IV+) }
  VscreenSize:Word;         { Taille verticale de l'�cran source (Paintbrush IV+) }
  Filler:Array[0..53]of Byte; { Bourrage pour atteindre 128 octets }
 End;

Var
 SourceBMP,DestPCX:File;
 Header:HeaderBMP;
 BIH:BitMapInfoHeader;
 PCXHeader:HeaderPCX;
 BMPBytesPerLine,ByteReaded,ByteWritten:Word;
 StartPos:LongInt;
 NumPal:Word;
 Palette:Array[0..255]of RGB32;
 BMPLine:Array[0..MaxWidth*3-1]of Byte;     { Ligne brute lue dans le BMP }
 PlaneBuf:Array[0..MaxWidth*3-1]of Byte;     { Tampon de sortie pour un plan PCX (BytesPerLine octets) }
 OutputName:String;
 PCXBytesPerLine:Word;     { Champ "BytesPerLine" du PCX (par plan) }
 PCXNPlanes:Byte;          { Nombre de plans utilis�s }
 PCXBitsPerPixel:Byte;     { Bits par pixel et par plan }
 ImageWidth,ImageHeight:Word;
 BMPBPL:LongInt;
 I:Integer;
 Y:LongInt;
 SourceRow:LongInt;
 PlaneIdx:Integer;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.PCX';
End;

  {�crit "Count" octets identiques de valeur "Value" dans le flux PCX en
   utilisant l'encodage RLE :
   - Si Count >= 1 et (Count >= 2 OU Value >= $C0) on �met l'octet de
     compteur ($C0 OR Count) suivi de Value.
   - Sinon on �met directement Value.
   La sp�cification limite Count � 1..63 ; les appelants morcellent les
   ex�cutions plus longues.}
Procedure RLEWriteRun(Value:Byte;Count:Byte);
Var
 B:Byte;
Begin
 If Count=0 Then Exit;
 If(Count>1)or(Value>=$C0)Then Begin
  B:=$C0 or Count;
  BlockWrite(DestPCX,B,1,ByteWritten);
  BlockWrite(DestPCX,Value,1,ByteWritten);
 End
  Else
 Begin
  BlockWrite(DestPCX,Value,1,ByteWritten);
 End;
End;

  {Encode une ligne (un seul plan) de PCXBytesPerLine octets en RLE et l'�crit
   dans le fichier de destination.}
Procedure WriteRLEPlane(Const Buf:Array of Byte;Length:Word);
Var
 P:Word;
 RunValue:Byte;
 RunCount:Byte;
Begin
 If Length=0 Then Exit;
 P:=0;
 RunValue:=Buf[0];
 RunCount:=1;
 P:=1;
 While P<Length Do Begin
  If(Buf[P]=RunValue)and(RunCount<63)Then Begin
   Inc(RunCount);
  End
   Else
  Begin
   RLEWriteRun(RunValue,RunCount);
   RunValue:=Buf[P];
   RunCount:=1;
  End;
  Inc(P);
 End;
 RLEWriteRun(RunValue,RunCount);
End;

  {Lit la ligne brute du BMP (index RowIndex en haut=0) dans BMPLine.}
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

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BMP2PCX : Cette commande permet de convertir une image BitMap (.BMP) ',
                    'en format PCX (.PCX).');
  WriteLn;
  WriteLn('Syntaxe : BMP2PCX nomdufichier.BMP');
  WriteLn;
  WriteLn(' nomdufichier   Nom du fichier ".BMP" � convertir.');
  WriteLn;
  WriteLn('Le fichier r�sultant porte le m�me nom avec l''extension .PCX.');
  WriteLn('Seuls les BitMaps 1, 4, 8 ou 24 bits par pixel non compress�s sont support�s.');
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
 If BIH.biSizeImage=0 Then
  BMPBPL:=((LongInt(BIH.biWidth)*LongInt(BIH.biBitCount)+31)div 32)*4
  Else
  BMPBPL:=LongInt(BIH.biSizeImage)div LongInt(BIH.biHeight);
 If(BMPBPL<=0)or(BMPBPL>SizeOf(BMPLine))Then Begin
  WriteLn('Largeur de l''image trop grande !');
  Halt;
 End;
 BMPBytesPerLine:=Word(BMPBPL);
 If(BIH.biBitCount<>1)and(BIH.biBitCount<>4)and(BIH.biBitCount<>8)
                      and(BIH.biBitCount<>24)Then Begin
  WriteLn('Seuls les BitMaps 1, 4, 8 ou 24 bits par pixel sont support�s pour la conversion en PCX !');
  Halt(2);
 End;
 If BIH.biCompression<>bi_RGB Then Begin
  WriteLn('Compression RLE4 ou RLE8 non support�');
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

 ImageWidth:=Word(BIH.biWidth);
 ImageHeight:=Word(BIH.biHeight);

  {Lecture de la palette si pr�sente.}
 If BIH.biBitCount<24 Then Begin
  Case BIH.biBitCount of
   1:NumPal:=2;
   4:NumPal:=16;
   8:NumPal:=256;
  End;
  Seek(SourceBMP,14+SizeOf(BitmapInfoHeader));
  BlockRead(SourceBMP,Palette,LongInt(NumPal)*4,ByteReaded);
 End
  Else
 NumPal:=0;

 StartPos:=Header.OffBits;

  {S�lection des param�tres PCX en fonction de la profondeur du BMP source.
   PCX exige BytesPerLine pair (par plan).}
 Case BIH.biBitCount of
  1:Begin
   PCXNPlanes:=1;
   PCXBitsPerPixel:=1;
   PCXBytesPerLine:=Word((LongInt(ImageWidth)+7)div 8);
  End;
  4:Begin
    {Pour 16 couleurs, le standard est 4 plans � 1 bit (formats EGA).}
   PCXNPlanes:=4;
   PCXBitsPerPixel:=1;
   PCXBytesPerLine:=Word((LongInt(ImageWidth)+7)div 8);
  End;
  8:Begin
   PCXNPlanes:=1;
   PCXBitsPerPixel:=8;
   PCXBytesPerLine:=ImageWidth;
  End;
  24:Begin
   PCXNPlanes:=3;
   PCXBitsPerPixel:=8;
   PCXBytesPerLine:=ImageWidth;
  End;
 End;
  {BytesPerLine doit �tre pair selon la sp�cification PCX.}
 If(PCXBytesPerLine and 1)<>0 Then Inc(PCXBytesPerLine);

  {Construction de l'en-t�te PCX.}
 FillChar(PCXHeader,SizeOf(PCXHeader),0);
 PCXHeader.Manufacturer:=PCXManufacturer;
 PCXHeader.Version:=PCXVersion;
 PCXHeader.Encoding:=PCXEncodingRLE;
 PCXHeader.BitsPerPixel:=PCXBitsPerPixel;
 PCXHeader.Xmin:=0;
 PCXHeader.Ymin:=0;
 PCXHeader.Xmax:=ImageWidth-1;
 PCXHeader.Ymax:=ImageHeight-1;
 PCXHeader.HDpi:=72;
 PCXHeader.VDpi:=72;
 PCXHeader.NPlanes:=PCXNPlanes;
 PCXHeader.BytesPerLine:=PCXBytesPerLine;
 PCXHeader.PaletteInfo:=PCXPaletteColor;
 PCXHeader.HscreenSize:=ImageWidth;
 PCXHeader.VscreenSize:=ImageHeight;
  {Palette EGA 16 couleurs : utilis�e pour 1 et 4 bpp. Pour les modes 8 et 24
   bits cette zone reste � z�ro et sera remplac�e (pour 8 bpp) par la palette
   VGA en fin de fichier.}
 If(BIH.biBitCount=1)or(BIH.biBitCount=4)Then Begin
  For I:=0 to NumPal-1 Do Begin
   PCXHeader.ColorMap[I*3+0]:=Palette[I].R;
   PCXHeader.ColorMap[I*3+1]:=Palette[I].G;
   PCXHeader.ColorMap[I*3+2]:=Palette[I].B;
  End;
 End;

  {Cr�ation du fichier de destination.}
 OutputName:=Path2NameExt(ParamStr(1));
 {$I-}Assign(DestPCX,OutputName);
 Rewrite(DestPCX,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de cr�er le fichier ',OutputName);
  Close(SourceBMP);
  Halt;
 End;

  {�criture de l'en-t�te (128 octets).}
 BlockWrite(DestPCX,PCXHeader,SizeOf(PCXHeader),ByteWritten);

  {Boucle sur les lignes de l'image. PCX est stock� de haut en bas, BMP de
   bas en haut : on traduit donc l'index source.}
 For Y:=0 to LongInt(ImageHeight)-1 Do Begin
  SourceRow:=LongInt(ImageHeight)-1-Y;
  ReadBmpRow(SourceRow);

  Case BIH.biBitCount of
   1:Begin
    FillChar(PlaneBuf,PCXBytesPerLine,0);
    For I:=0 to LongInt(ImageWidth)-1 Do
     If GetPalIndex(Word(I))<>0 Then
      PlaneBuf[I shr 3]:=PlaneBuf[I shr 3]or Byte(1 shl (7-(I and 7)));
    WriteRLEPlane(PlaneBuf,PCXBytesPerLine);
   End;
   4:Begin
     {On �met successivement le plan 0 (bit 0 de l'index) jusqu'au plan 3
      (bit 3 de l'index), conform�ment au format PCX EGA.}
    For PlaneIdx:=0 to 3 Do Begin
     FillChar(PlaneBuf,PCXBytesPerLine,0);
     For I:=0 to LongInt(ImageWidth)-1 Do
      If(GetPalIndex(Word(I))shr PlaneIdx)and 1<>0 Then
       PlaneBuf[I shr 3]:=PlaneBuf[I shr 3]or Byte(1 shl (7-(I and 7)));
     WriteRLEPlane(PlaneBuf,PCXBytesPerLine);
    End;
   End;
   8:Begin
    For I:=0 to LongInt(ImageWidth)-1 Do PlaneBuf[I]:=BMPLine[I];
    For I:=ImageWidth to PCXBytesPerLine-1 Do PlaneBuf[I]:=0;
    WriteRLEPlane(PlaneBuf,PCXBytesPerLine);
   End;
   24:Begin
     {Plan 0 = R, plan 1 = G, plan 2 = B (les BMP 24 bits stockent BGR).}
    For I:=0 to LongInt(ImageWidth)-1 Do PlaneBuf[I]:=BMPLine[I*3+2];
    For I:=ImageWidth to PCXBytesPerLine-1 Do PlaneBuf[I]:=0;
    WriteRLEPlane(PlaneBuf,PCXBytesPerLine);

    For I:=0 to LongInt(ImageWidth)-1 Do PlaneBuf[I]:=BMPLine[I*3+1];
    For I:=ImageWidth to PCXBytesPerLine-1 Do PlaneBuf[I]:=0;
    WriteRLEPlane(PlaneBuf,PCXBytesPerLine);

    For I:=0 to LongInt(ImageWidth)-1 Do PlaneBuf[I]:=BMPLine[I*3+0];
    For I:=ImageWidth to PCXBytesPerLine-1 Do PlaneBuf[I]:=0;
    WriteRLEPlane(PlaneBuf,PCXBytesPerLine);
   End;
  End;
 End;

  {Pour les images 8 bits, on ajoute le marqueur 0x0C suivi de la palette VGA
   (768 octets, RGB).}
 If BIH.biBitCount=8 Then Begin
  I:=PCXVGAPaletteMarker;
  PlaneBuf[0]:=Byte(I);
  BlockWrite(DestPCX,PlaneBuf[0],1,ByteWritten);
  For I:=0 to 255 Do Begin
   BlockWrite(DestPCX,Palette[I].R,1,ByteWritten);
   BlockWrite(DestPCX,Palette[I].G,1,ByteWritten);
   BlockWrite(DestPCX,Palette[I].B,1,ByteWritten);
  End;
 End;

 Close(DestPCX);
 Close(SourceBMP);
END.
