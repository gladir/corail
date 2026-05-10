{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2ICO;

{$A-}

Uses DOS;

Const
  {Type de compression Windows}
 bi_RGB=0;
 bi_RLE8=1;
 bi_RLE4=2;

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

  {Structures des ressources Windows ".ICO" (ic�nes). Le format est
   identique � celui des curseurs ".CUR" : un en-t�te ICONDIR de 6
   octets suivi de N entr�es ICONDIRENTRY de 16 octets, puis des
   images. Le champ idType vaut 1 pour un fichier ic�ne (et 2 pour un
   curseur). L'image embarqu�e est un DIB (BITMAPINFOHEADER + palette
   �ventuelle) dont le champ biHeight vaut 2 fois la hauteur r�elle :
   les premi�res lignes contiennent le masque XOR (les pixels
   eux-m�mes), et les lignes suivantes le masque AND 1 bit par pixel
   (transparence).}
 IconDir=Record
  idReserved:Word;          { Toujours 0 }
  idType:Word;              { 1 = ic�ne, 2 = curseur }
  idCount:Word;             { Nombre d'images dans le fichier (1 ici) }
 End;

 IconDirEntry=Record
  bWidth:Byte;              { Largeur en pixels (0 si >=256) }
  bHeight:Byte;             { Hauteur en pixels (0 si >=256) }
  bColorCount:Byte;         { Nombre de couleurs (0 si >=256 ou true-color) }
  bReserved:Byte;           { Toujours 0 }
  wPlanes:Word;             { Nombre de plans de couleurs (toujours 1) }
  wBitCount:Word;           { Bits par pixel de l'image embarqu�e }
  dwBytesInRes:LongInt;     { Taille de la ressource image (DIB + masque AND) }
  dwImageOffset:LongInt;    { Offset absolu de l'image depuis le d�but du fichier }
 End;

Var
 SourceBMP,DestICO:File;
 Header:HeaderBMP;
 BIH:BitMapInfoHeader;
 DIBHeader:BitmapInfoHeader;
 IcoDirRec:IconDir;
 IcoEntry:IconDirEntry;
 BMPBytesPerLine,ByteReaded,ByteWritten:Word;
 StartPos:LongInt;
 NumPal:Word;
 Palette:Array[0..255]of RGB32;
 BMPLine:Array[0..MaxWidth*3-1]of Byte;     { Ligne brute lue dans le BMP }
 ANDLine:Array[0..MaxWidth div 8+3]of Byte; { Ligne du masque AND (1 bpp) }
 OutputName:String;
 ImageWidth,ImageHeight:Word;
 BMPBPL:LongInt;
 XORStride,ANDStride:LongInt;
 PaletteBytes,DIBSize:LongInt;
 Y:LongInt;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.ICO';
End;

  {Affiche l'aide en ligne et termine le programme.}
Procedure ShowHelp;
Begin
 WriteLn('BMP2ICO : Cette commande permet de convertir une image BitMap (.BMP) ',
                   'en ressource ic�ne Windows (.ICO).');
 WriteLn;
 WriteLn('Syntaxe : BMP2ICO nomdufichier.BMP');
 WriteLn;
 WriteLn(' nomdufichier   Nom du fichier ".BMP" � convertir.');
 WriteLn;
 WriteLn('Le fichier r�sultant porte le m�me nom avec l''extension .ICO.');
 WriteLn('Seuls les BitMaps 1, 4, 8 ou 24 bits par pixel non compress�s sont support�s.');
 WriteLn('Le masque de transparence (AND) est rempli � z�ro : tous les pixels de');
 WriteLn('l''ic�ne sont opaques (le BMP source ne porte pas d''information alpha).');
 Halt;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then ShowHelp;
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
 If(BIH.biBitCount<>1)and(BIH.biBitCount<>4)and(BIH.biBitCount<>8)
                      and(BIH.biBitCount<>24)Then Begin
  WriteLn('Seuls les BitMaps 1, 4, 8 ou 24 bits par pixel sont support�s !');
  Halt(2);
 End;
 If BIH.biCompression<>bi_RGB Then Begin
  WriteLn('Compression RLE4 ou RLE8 non support�e');
  Halt(3);
 End;
 If(BIH.biWidth<=0)or(BIH.biHeight<=0)Then Begin
  WriteLn('Dimensions invalides !');
  Halt;
 End;
 If(BIH.biWidth>MaxWidth)or(BIH.biHeight>MaxWidth)Then Begin
  WriteLn('Image trop grande (max : ',MaxWidth,') !');
  Halt;
 End;

  {Calcul du nombre d'octets par ligne BMP source : multiple de 4 octets.}
 If BIH.biSizeImage=0 Then
  BMPBPL:=((LongInt(BIH.biWidth)*LongInt(BIH.biBitCount)+31)div 32)*4
                     Else BMPBPL:=LongInt(BIH.biSizeImage)div LongInt(BIH.biHeight);
 If(BMPBPL<=0)or(BMPBPL>SizeOf(BMPLine))Then Begin
  WriteLn('Largeur de l''image trop grande !');
  Halt;
 End;
 BMPBytesPerLine:=Word(BMPBPL);

  {Lecture de la palette source (1, 4 ou 8 bpp). Une ressource ic�ne
   embarque toujours une palette compl�te de 2^biBitCount entr�es
   pour les modes index�s.}
 NumPal:=0;
 PaletteBytes:=0;
 If BIH.biBitCount<24 Then Begin
  Case BIH.biBitCount of
   1:NumPal:=2;
   4:NumPal:=16;
   8:NumPal:=256;
  End;
  Seek(SourceBMP,14+SizeOf(BitmapInfoHeader));
  FillChar(Palette,SizeOf(Palette),0);
  BlockRead(SourceBMP,Palette,LongInt(NumPal)*SizeOf(RGB32),ByteReaded);
  PaletteBytes:=LongInt(NumPal)*SizeOf(RGB32);
 End;

 ImageWidth:=Word(BIH.biWidth);
 ImageHeight:=Word(BIH.biHeight);
 StartPos:=Header.OffBits;

  {Calcul des longueurs de ligne du DIB embarqu� : XOR de la m�me
   profondeur que le BMP source, AND toujours sur 1 bpp ; les deux
   masques sont stock�s en lignes "bottom-up" align�es sur 32 bits.}
 XORStride:=((LongInt(ImageWidth)*LongInt(BIH.biBitCount)+31)div 32)*4;
 ANDStride:=((LongInt(ImageWidth)+31)div 32)*4;

  {Cr�ation du fichier de destination.}
 OutputName:=Path2NameExt(ParamStr(1));
 {$I-}Assign(DestICO,OutputName);
 Rewrite(DestICO,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de cr�er le fichier ',OutputName);
  Close(SourceBMP);
  Halt;
 End;

  {1) En-t�te ICONDIR (6 octets) : une ic�ne, une seule image.}
 IcoDirRec.idReserved:=0;
 IcoDirRec.idType:=1;
 IcoDirRec.idCount:=1;
 BlockWrite(DestICO,IcoDirRec,SizeOf(IcoDirRec),ByteWritten);

  {2) Entr�e ICONDIRENTRY (16 octets).}
 DIBSize:=SizeOf(BitmapInfoHeader)+PaletteBytes+
          XORStride*LongInt(ImageHeight)+ANDStride*LongInt(ImageHeight);
 If ImageWidth>=256 Then IcoEntry.bWidth:=0
                    Else IcoEntry.bWidth:=Byte(ImageWidth);
 If ImageHeight>=256 Then IcoEntry.bHeight:=0
                     Else IcoEntry.bHeight:=Byte(ImageHeight);
 Case BIH.biBitCount of
  1:IcoEntry.bColorCount:=2;
  4:IcoEntry.bColorCount:=16;
  Else IcoEntry.bColorCount:=0;  { 8 bpp = 256 -> 0, 24 bpp -> 0 }
 End;
 IcoEntry.bReserved:=0;
 IcoEntry.wPlanes:=1;
 IcoEntry.wBitCount:=BIH.biBitCount;
 IcoEntry.dwBytesInRes:=DIBSize;
 IcoEntry.dwImageOffset:=SizeOf(IcoDirRec)+SizeOf(IcoEntry); { 6+16 = 22 }
 BlockWrite(DestICO,IcoEntry,SizeOf(IcoEntry),ByteWritten);

  {3) BITMAPINFOHEADER du DIB. La hauteur est doubl�e car le DIB
     contient � la fois le masque XOR et le masque AND empil�s.}
 FillChar(DIBHeader,SizeOf(DIBHeader),0);
 DIBHeader.biSize:=SizeOf(BitmapInfoHeader);
 DIBHeader.biWidth:=BIH.biWidth;
 DIBHeader.biHeight:=BIH.biHeight*2;
 DIBHeader.biPlanes:=1;
 DIBHeader.biBitCount:=BIH.biBitCount;
 DIBHeader.biCompression:=bi_RGB;
 DIBHeader.biSizeImage:=XORStride*LongInt(ImageHeight)+
                        ANDStride*LongInt(ImageHeight);
 DIBHeader.biXPelsPerMeter:=0;
 DIBHeader.biYPelsPerMeter:=0;
 DIBHeader.biClrUsed:=0;
 DIBHeader.biClrImportant:=0;
 BlockWrite(DestICO,DIBHeader,SizeOf(DIBHeader),ByteWritten);

  {4) Palette du DIB (si pertinente). On recopie la palette du BMP
     telle quelle : m�me ordre BGRX, m�me nombre d'entr�es.}
 If PaletteBytes>0 Then BlockWrite(DestICO,Palette,PaletteBytes,ByteWritten);

  {5) Masque XOR : recopie ligne par ligne des pixels du BMP. Le BMP
     est d�j� stock� bottom-up et utilise le m�me alignement DWORD que
     le DIB embarqu� ; on transf�re donc les lignes telles quelles.}
 For Y:=0 to LongInt(ImageHeight)-1 Do Begin
  Seek(SourceBMP,StartPos+Y*LongInt(BMPBytesPerLine));
  FillChar(BMPLine,XORStride,0);
  BlockRead(SourceBMP,BMPLine,BMPBytesPerLine,ByteReaded);
  BlockWrite(DestICO,BMPLine,XORStride,ByteWritten);
 End;

  {6) Masque AND : 1 bit par pixel, � z�ro pour rendre l'int�gralit�
     de l'ic�ne opaque (le BMP source ne fournit aucune information
     d'alpha). Lignes "bottom-up" align�es sur 32 bits.}
 FillChar(ANDLine,SizeOf(ANDLine),0);
 For Y:=0 to LongInt(ImageHeight)-1 Do
  BlockWrite(DestICO,ANDLine,ANDStride,ByteWritten);

 Close(DestICO);
 Close(SourceBMP);
END.
