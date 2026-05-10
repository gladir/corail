{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2TIFF;

{$A-}

Uses DOS;

Const
  {Type de compression Windows}
 bi_RGB=0;
 bi_RLE8=1;
 bi_RLE4=2;

  {Constantes du format TIFF (TIFF 6.0 baseline, octet de poids faible
   en premier - "Intel byte order").}
 TiffByteOrder=$4949;   { 'II' - little-endian }
 TiffMagic=42;
 TiffNoCompression=1;
 TiffPhotoBlackIsZero=1;
 TiffPhotoRGB=2;
 TiffPhotoPalette=3;
 TiffResolutionInch=2;

  {Codes de type de donn�es TIFF}
 TiffTypeShort=3;
 TiffTypeLong=4;
 TiffTypeRational=5;

  {Identificateurs (tags) TIFF utilis�s}
 TagImageWidth=256;
 TagImageLength=257;
 TagBitsPerSample=258;
 TagCompression=259;
 TagPhotometric=262;
 TagStripOffsets=273;
 TagSamplesPerPixel=277;
 TagRowsPerStrip=278;
 TagStripByteCounts=279;
 TagXResolution=282;
 TagYResolution=283;
 TagResolutionUnit=296;
 TagColorMap=320;

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
 SourceBMP,DestTIFF:File;
 Header:HeaderBMP;
 BIH:BitMapInfoHeader;
 BMPBytesPerLine,ByteReaded,ByteWritten:Word;
 TiffBytesPerLine:Word;
 StartPos:LongInt;
 NumPal:Word;
 Palette:Array[0..255]of RGB32;
 Buffer:Array[0..4095]of Byte;
 OutputName:String;
 NumEntries:Word;
 IsPalette:Boolean;
 SamplesPerPixel:Word;
 BitsPerSample:Word;
 Photometric:Word;
 PaletteSize:Word;       { Nombre d'entr�es dans la palette TIFF (1 shl BitsPerSample) }
 ExternalStart:LongInt;
 XResOffset,YResOffset:LongInt;
 BitsPerSampleOffset:LongInt;
 ColorMapOffset:LongInt;
 StripOffset:LongInt;
 StripByteCount:LongInt;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.TIF';
End;

Procedure WriteByteToFile(B:Byte);
Begin
 BlockWrite(DestTIFF,B,1,ByteWritten);
End;

Procedure WriteWordToFile(W:Word);
Var
 Tmp:Array[0..1]of Byte;
Begin
 Tmp[0]:=Byte(W and $FF);
 Tmp[1]:=Byte((W shr 8)and $FF);
 BlockWrite(DestTIFF,Tmp,2,ByteWritten);
End;

Procedure WriteLongToFile(L:LongInt);
Var
 Tmp:Array[0..3]of Byte;
Begin
 Tmp[0]:=Byte(L and $FF);
 Tmp[1]:=Byte((L shr 8)and $FF);
 Tmp[2]:=Byte((L shr 16)and $FF);
 Tmp[3]:=Byte((L shr 24)and $FF);
 BlockWrite(DestTIFF,Tmp,4,ByteWritten);
End;

  {�criture d'une entr�e d'IFD TIFF (12 octets) :
     Tag (2) + Type (2) + Count (4) + Value-or-Offset (4).
   Pour les types tenant dans 4 octets (par ex. SHORT count=1, LONG count=1),
   Value contient directement la valeur. Sinon, Value contient un d�calage
   absolu (en octets depuis le d�but du fichier) vers les donn�es.}
Procedure WriteIFDEntry(Tag,FType:Word;Count,Value:LongInt);
Begin
 WriteWordToFile(Tag);
 WriteWordToFile(FType);
 WriteLongToFile(Count);
 WriteLongToFile(Value);
End;

Procedure WriteRational(Numerator,Denominator:LongInt);
Begin
 WriteLongToFile(Numerator);
 WriteLongToFile(Denominator);
End;

Var
 I,X:Word;
 Y:LongInt;
 ByteVal:Byte;
 R,G,B:Byte;
 OutByte:Byte;
 ColorMapEntries:Word;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BMP2TIFF : Cette commande permet de convertir une image BitMap (.BMP) ',
                     'en format TIFF (Tagged Image File Format).');
  WriteLn;
  WriteLn('Syntaxe : BMP2TIFF nomdufichier.BMP');
  WriteLn;
  WriteLn(' nomdufichier   Ce param�tre permet d''indiquer le nom du fichier ".BMP".');
  WriteLn;
  WriteLn('Le fichier r�sultant porte le m�me nom avec l''extension .TIF.');
  WriteLn('Seuls les BitMaps 1, 4, 8 ou 24 bits par pixel non compress�s sont support�s.');
 End
  Else
 If ParamCount>0Then Begin
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
  If BIH.biSizeImage=0Then Begin
   WriteLn('Taille de l''image = 0 !');
   Halt;
  End
   Else
  Begin
   BMPBytesPerLine:=Word(LongInt(LongInt(BIH.biSizeImage)div LongInt(BIH.biHeight)));
   If BMPBytesPerLine>SizeOf(Buffer)Then Begin
    WriteLn('Largeur de l''image trop grande !');
    Halt;
   End;
  End;
  If(BIH.biBitCount<>1)and(BIH.biBitCount<>4)and(BIH.biBitCount<>8)
                       and(BIH.biBitCount<>24)Then Begin
   WriteLn('Seuls les BitMaps 1, 4, 8 ou 24 bits par pixel sont support�s pour la conversion en TIFF !');
   Halt(2);
  End;
  If BIH.biCompression<>bi_RGB Then Begin
   WriteLn('Compression RLE4 ou RL8 non support�');
   Halt(3);
  End;

   {Configuration des param�tres TIFF en fonction du nombre de bits par pixel}
  Case(BIH.biBitCount)of
   1:Begin
    IsPalette:=True; SamplesPerPixel:=1; BitsPerSample:=1;
    Photometric:=TiffPhotoPalette; NumPal:=2; PaletteSize:=2;
    TiffBytesPerLine:=Word((LongInt(BIH.biWidth)+7)shr 3);
   End;
   4:Begin
    IsPalette:=True; SamplesPerPixel:=1; BitsPerSample:=4;
    Photometric:=TiffPhotoPalette; NumPal:=16; PaletteSize:=16;
    TiffBytesPerLine:=Word((LongInt(BIH.biWidth)+1)shr 1);
   End;
   8:Begin
    IsPalette:=True; SamplesPerPixel:=1; BitsPerSample:=8;
    Photometric:=TiffPhotoPalette; NumPal:=256; PaletteSize:=256;
    TiffBytesPerLine:=Word(BIH.biWidth);
   End;
   24:Begin
    IsPalette:=False; SamplesPerPixel:=3; BitsPerSample:=8;
    Photometric:=TiffPhotoRGB; NumPal:=0; PaletteSize:=0;
    TiffBytesPerLine:=Word(LongInt(BIH.biWidth)*3);
   End;
  End;

  If NumPal>0Then Begin
   Seek(SourceBMP,14+SizeOf(BitmapInfoHeader));
   BlockRead(SourceBMP,Palette,LongInt(NumPal)*4,ByteReaded);
  End;
  StartPos:=Header.OffBits;
  StripByteCount:=LongInt(TiffBytesPerLine)*LongInt(BIH.biHeight);

   {D�termination du nombre d'entr�es de l'IFD :
    12 entr�es de base, plus une entr�e ColorMap pour les images palettis�es.}
  If IsPalette Then NumEntries:=13 Else NumEntries:=12;

   {Calcul des d�calages des donn�es externes (situ�es apr�s l'IFD)}
  ExternalStart:=8+2+LongInt(NumEntries)*12+4;
  XResOffset:=ExternalStart;
  YResOffset:=XResOffset+8;
  If IsPalette Then Begin
   ColorMapOffset:=YResOffset+8;
   ColorMapEntries:=Word(3*PaletteSize); { Rouge, Vert, Bleu }
   StripOffset:=ColorMapOffset+LongInt(ColorMapEntries)*2;
   BitsPerSampleOffset:=0;
  End
   Else
  Begin
   BitsPerSampleOffset:=YResOffset+8;
   ColorMapOffset:=0;
   StripOffset:=BitsPerSampleOffset+6;     { 3 SHORTs }
   ColorMapEntries:=0;
  End;

   {Cr�ation du fichier TIFF de destination}
  OutputName:=Path2NameExt(ParamStr(1));
  {$I-}Assign(DestTIFF,OutputName);
  Rewrite(DestTIFF,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de cr�er le fichier ',OutputName);
   Close(SourceBMP);
   Halt;
  End;

   {En-t�te TIFF (8 octets)}
  WriteWordToFile(TiffByteOrder); { 'II' - octet de poids faible en premier }
  WriteWordToFile(TiffMagic);     { 42 - nombre magique TIFF }
  WriteLongToFile(8);             { D�calage du premier IFD (juste apr�s l'en-t�te) }

   {IFD : nombre d'entr�es (2 octets) + entr�es (12 octets chacune) tri�es
    par tag croissant + d�calage de l'IFD suivant (4 octets, 0 = aucun).}
  WriteWordToFile(NumEntries);

  WriteIFDEntry(TagImageWidth,TiffTypeLong,1,LongInt(BIH.biWidth));
  WriteIFDEntry(TagImageLength,TiffTypeLong,1,LongInt(BIH.biHeight));
  If IsPalette Then
   WriteIFDEntry(TagBitsPerSample,TiffTypeShort,1,LongInt(BitsPerSample))
   Else
   WriteIFDEntry(TagBitsPerSample,TiffTypeShort,3,BitsPerSampleOffset);
  WriteIFDEntry(TagCompression,TiffTypeShort,1,TiffNoCompression);
  WriteIFDEntry(TagPhotometric,TiffTypeShort,1,LongInt(Photometric));
  WriteIFDEntry(TagStripOffsets,TiffTypeLong,1,StripOffset);
  WriteIFDEntry(TagSamplesPerPixel,TiffTypeShort,1,LongInt(SamplesPerPixel));
  WriteIFDEntry(TagRowsPerStrip,TiffTypeLong,1,LongInt(BIH.biHeight));
  WriteIFDEntry(TagStripByteCounts,TiffTypeLong,1,StripByteCount);
  WriteIFDEntry(TagXResolution,TiffTypeRational,1,XResOffset);
  WriteIFDEntry(TagYResolution,TiffTypeRational,1,YResOffset);
  WriteIFDEntry(TagResolutionUnit,TiffTypeShort,1,TiffResolutionInch);
  If IsPalette Then
   WriteIFDEntry(TagColorMap,TiffTypeShort,LongInt(ColorMapEntries),ColorMapOffset);

  WriteLongToFile(0); { Pas d'IFD suivant }

   {Donn�es externes : r�solutions, BitsPerSample (RGB) ou ColorMap (palette)}
  WriteRational(72,1);  { XResolution = 72 dpi }
  WriteRational(72,1);  { YResolution = 72 dpi }
  If IsPalette Then Begin
    {ColorMap TIFF : tous les rouges (16 bits LE), puis tous les verts,
     puis tous les bleus. Une valeur 8 bits V de la palette BMP est
     �tendue � 16 bits par (V shl 8)or V.}
   For I:=0 to PaletteSize-1 Do Begin
    If I<NumPal Then ByteVal:=Palette[I].R Else ByteVal:=0;
    WriteWordToFile(Word((Word(ByteVal)shl 8)or ByteVal));
   End;
   For I:=0 to PaletteSize-1 Do Begin
    If I<NumPal Then ByteVal:=Palette[I].G Else ByteVal:=0;
    WriteWordToFile(Word((Word(ByteVal)shl 8)or ByteVal));
   End;
   For I:=0 to PaletteSize-1 Do Begin
    If I<NumPal Then ByteVal:=Palette[I].B Else ByteVal:=0;
    WriteWordToFile(Word((Word(ByteVal)shl 8)or ByteVal));
   End;
  End
   Else
  Begin
    {3 valeurs SHORT pour BitsPerSample en RGB}
   WriteWordToFile(BitsPerSample);
   WriteWordToFile(BitsPerSample);
   WriteWordToFile(BitsPerSample);
  End;

   {Donn�es de la bande (strip) : lignes de pixels du haut vers le bas, sans
    le remplissage 4 octets propre au format BMP. Le BMP stocke les lignes
    du bas vers le haut, on lit donc dans l'ordre inverse.}
  For Y:=LongInt(BIH.biHeight)-1 downto 0 Do Begin
   Seek(SourceBMP,StartPos+Y*LongInt(BMPBytesPerLine));
   BlockRead(SourceBMP,Buffer,BMPBytesPerLine,ByteReaded);
   Case BIH.biBitCount of
    1,4,8:Begin
      {Les formats 1, 4 et 8 bits ont la m�me disposition de bits/octet
       en TIFF qu'en BMP (octet de poids fort en premier pour 1 et 4 bpp).
       Il suffit donc de copier les octets utiles, sans le bourrage 4 octets.}
     BlockWrite(DestTIFF,Buffer,TiffBytesPerLine,ByteWritten);
    End;
    24:Begin
      {Conversion BGR (BMP) -> RGB (TIFF baseline) }
     For X:=0 to Word(BIH.biWidth)-1 Do Begin
      B:=Buffer[X*3];
      G:=Buffer[X*3+1];
      R:=Buffer[X*3+2];
      OutByte:=R; BlockWrite(DestTIFF,OutByte,1,ByteWritten);
      OutByte:=G; BlockWrite(DestTIFF,OutByte,1,ByteWritten);
      OutByte:=B; BlockWrite(DestTIFF,OutByte,1,ByteWritten);
     End;
    End;
   End;
  End;

  Close(DestTIFF);
  Close(SourceBMP);
 End
  Else
 WriteLn('Param�tre requis !');
END.
