{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2TGA;

{$A-}

Uses DOS;

Const
  {Type de compression Windows}
 bi_RGB=0;
 bi_RLE8=1;
 bi_RLE4=2;

  {Largeur maximale support�e (en pixels).}
 MaxWidth=4096;

  {Constantes du format TGA (Truevision Targa, utilis� sur Amiga, Atari ST,
   MS-DOS et bien d'autres plates-formes). Toutes les valeurs num�riques
   multi-octets sont stock�es en "little-endian" (Intel).}
 TGAImgUncompColormap=1;  { Image index�e non compress�e }
 TGAImgUncompTrueCol=2;   { Image RGB non compress�e }
 TGAColorMapAbsent=0;
 TGAColorMapPresent=1;

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

  {En-t�te TGA standard : 18 octets, ordre Intel (little-endian).
   Note : aucune zone de bourrage, l'enregistrement est suivi imm�diatement
   de l'�ventuel ID, puis de la palette puis des donn�es pixels.}
 HeaderTGA=Record
  IDLength:Byte;          { Longueur de l'identifiant ASCII (0 = absent) }
  ColorMapType:Byte;      { 0 = pas de palette, 1 = palette pr�sente }
  ImageType:Byte;         { 1 = index� non compress�, 2 = RGB non compress� }
  CMapFirstEntry:Word;    { Premier index de la palette (g�n�ralement 0) }
  CMapLength:Word;        { Nombre d'entr�es dans la palette }
  CMapEntrySize:Byte;     { Taille en bits d'une entr�e (24 dans notre cas) }
  XOrigin:Word;           { Coordonn�es d'origine (0,0) }
  YOrigin:Word;
  ImageWidth:Word;        { Dimensions de l'image en pixels }
  ImageHeight:Word;
  PixelDepth:Byte;        { Bits par pixel (8 ou 24) }
  Descriptor:Byte;        { Bits 0..3 = alpha ; bit 4 = sens X ; bit 5 = sens Y }
 End;

Var
 SourceBMP,DestTGA:File;
 Header:HeaderBMP;
 BIH:BitMapInfoHeader;
 TGAHdr:HeaderTGA;
 BMPBytesPerLine,ByteReaded,ByteWritten:Word;
 StartPos:LongInt;
 NumPal:Word;
 Palette:Array[0..255]of RGB32;
 BMPLine:Array[0..MaxWidth*3-1]of Byte;     { Ligne brute lue dans le BMP }
 OutLine:Array[0..MaxWidth*3-1]of Byte;     { Ligne convertie �crite en TGA }
 OutputName:String;
 ImageWidth,ImageHeight:Word;
 BMPBPL:LongInt;
 I:Integer;
 Y:LongInt;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.TGA';
End;

  {�criture de l'en-t�te TGA en respectant l'ordre Intel.
   On �crit champ par champ pour �viter toute d�pendance � l'alignement
   structurel choisi par le compilateur.}
Procedure WriteTGAHeader;
Var
 B:Byte;
 W:Word;
Begin
 B:=TGAHdr.IDLength;        BlockWrite(DestTGA,B,1,ByteWritten);
 B:=TGAHdr.ColorMapType;    BlockWrite(DestTGA,B,1,ByteWritten);
 B:=TGAHdr.ImageType;       BlockWrite(DestTGA,B,1,ByteWritten);
 W:=TGAHdr.CMapFirstEntry;  BlockWrite(DestTGA,W,2,ByteWritten);
 W:=TGAHdr.CMapLength;      BlockWrite(DestTGA,W,2,ByteWritten);
 B:=TGAHdr.CMapEntrySize;   BlockWrite(DestTGA,B,1,ByteWritten);
 W:=TGAHdr.XOrigin;         BlockWrite(DestTGA,W,2,ByteWritten);
 W:=TGAHdr.YOrigin;         BlockWrite(DestTGA,W,2,ByteWritten);
 W:=TGAHdr.ImageWidth;      BlockWrite(DestTGA,W,2,ByteWritten);
 W:=TGAHdr.ImageHeight;     BlockWrite(DestTGA,W,2,ByteWritten);
 B:=TGAHdr.PixelDepth;      BlockWrite(DestTGA,B,1,ByteWritten);
 B:=TGAHdr.Descriptor;      BlockWrite(DestTGA,B,1,ByteWritten);
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

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BMP2TGA : Cette commande permet de convertir une image BitMap (.BMP) ',
                    'en format Targa (.TGA) utilis� sur Amiga, Atari ST et MS-DOS.');
  WriteLn;
  WriteLn('Syntaxe : BMP2TGA nomdufichier.BMP');
  WriteLn;
  WriteLn(' nomdufichier   Nom du fichier ".BMP" � convertir.');
  WriteLn;
  WriteLn('Le fichier r�sultant porte le m�me nom avec l''extension .TGA.');
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
  Close(SourceBMP);
  Halt;
 End;
 Seek(SourceBMP,14);
 BlockRead(SourceBMP,BIH,SizeOf(BIH),ByteReaded);
 If(BIH.biBitCount<>1)and(BIH.biBitCount<>4)and(BIH.biBitCount<>8)
                      and(BIH.biBitCount<>24)Then Begin
  WriteLn('Seuls les BitMaps 1, 4, 8 ou 24 bits par pixel sont support�s pour la conversion en TGA !');
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

  {Construction de l'en-t�te TGA.
   On stocke toujours la palette sur 256 entr�es 24 bits pour les modes
   index�s ; cela facilite la relecture par les outils anciens et reste
   strictement conforme � la sp�cification Targa.}
 FillChar(TGAHdr,SizeOf(TGAHdr),0);
 TGAHdr.IDLength:=0;
 TGAHdr.XOrigin:=0;
 TGAHdr.YOrigin:=0;
 TGAHdr.ImageWidth:=ImageWidth;
 TGAHdr.ImageHeight:=ImageHeight;
  {Descriptor=0 : origine en bas � gauche, comme dans le format BMP, ce qui
   nous permet d'�crire les lignes dans l'ordre BMP natif (bas vers haut).}
 TGAHdr.Descriptor:=0;
 If BIH.biBitCount=24 Then Begin
  TGAHdr.ColorMapType:=TGAColorMapAbsent;
  TGAHdr.ImageType:=TGAImgUncompTrueCol;
  TGAHdr.CMapFirstEntry:=0;
  TGAHdr.CMapLength:=0;
  TGAHdr.CMapEntrySize:=0;
  TGAHdr.PixelDepth:=24;
 End
  Else
 Begin
  TGAHdr.ColorMapType:=TGAColorMapPresent;
  TGAHdr.ImageType:=TGAImgUncompColormap;
  TGAHdr.CMapFirstEntry:=0;
  TGAHdr.CMapLength:=256;
  TGAHdr.CMapEntrySize:=24;
  TGAHdr.PixelDepth:=8;
 End;

  {Cr�ation du fichier de destination.}
 OutputName:=Path2NameExt(ParamStr(1));
 {$I-}Assign(DestTGA,OutputName);
 Rewrite(DestTGA,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de cr�er le fichier ',OutputName);
  Close(SourceBMP);
  Halt;
 End;

 WriteTGAHeader;

  {�criture de la palette pour les modes index�s : 256 entr�es BGR sur
   24 bits (m�me ordre que dans le BMP, ce qui simplifie le transfert).
   Les entr�es non utilis�es sont mises � z�ro.}
 If BIH.biBitCount<24 Then Begin
  For I:=0 to 255 Do Begin
   If I<NumPal Then Begin
    BlockWrite(DestTGA,Palette[I].B,1,ByteWritten);
    BlockWrite(DestTGA,Palette[I].G,1,ByteWritten);
    BlockWrite(DestTGA,Palette[I].R,1,ByteWritten);
   End
    Else
   Begin
    OutLine[0]:=0;
    BlockWrite(DestTGA,OutLine[0],1,ByteWritten);
    BlockWrite(DestTGA,OutLine[0],1,ByteWritten);
    BlockWrite(DestTGA,OutLine[0],1,ByteWritten);
   End;
  End;
 End;

  {�criture des pixels. TGA avec Descriptor=0 attend l'origine en bas �
   gauche, exactement comme le BMP. On lit donc les lignes du BMP dans
   l'ordre m�moire natif (RowIndex 0 = bas de l'image).}
 For Y:=0 to LongInt(ImageHeight)-1 Do Begin
  ReadBmpRow(Y);
  Case BIH.biBitCount of
   1,4,8:Begin
    For I:=0 to LongInt(ImageWidth)-1 Do
     OutLine[I]:=GetPalIndex(Word(I));
    BlockWrite(DestTGA,OutLine,ImageWidth,ByteWritten);
   End;
   24:Begin
     {BMP et TGA stockent tous deux les pixels en ordre BGR : on copie
      directement les premiers ImageWidth*3 octets de la ligne BMP.}
    BlockWrite(DestTGA,BMPLine,LongInt(ImageWidth)*3,ByteWritten);
   End;
  End;
 End;

 Close(DestTGA);
 Close(SourceBMP);
END.
