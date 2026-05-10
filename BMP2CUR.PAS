{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2CUR;

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

  {Structures des ressources Windows ".CUR" (curseurs). Le format est
   identique � celui des ic�nes ".ICO" : un en-t�te ICONDIR de 6 octets
   suivi de N entr�es ICONDIRENTRY de 16 octets, puis des images. Le
   champ idType vaut 1 pour un fichier ic�ne et 2 pour un curseur ; pour
   un curseur, les champs wPlanes et wBitCount de chaque entr�e sont
   r�utilis�s pour stocker respectivement le X et le Y du "point chaud"
   (hotspot). L'image embarqu�e est un DIB (BITMAPINFOHEADER + palette
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
  wPlanes:Word;             { Pour un curseur : X du hotspot }
  wBitCount:Word;           { Pour un curseur : Y du hotspot }
  dwBytesInRes:LongInt;     { Taille de la ressource image (DIB + masque AND) }
  dwImageOffset:LongInt;    { Offset absolu de l'image depuis le d�but du fichier }
 End;

Var
 SourceBMP,DestCUR:File;
 Header:HeaderBMP;
 BIH:BitMapInfoHeader;
 DIBHeader:BitmapInfoHeader;
 CurDir:IconDir;
 CurEntry:IconDirEntry;
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
 HotspotX,HotspotY:Word;
 Y:LongInt;
 Argi:Integer;
 Arg,ArgUp:String;
 InputName:String;
 ParamVal:LongInt;
 Code:Integer;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.CUR';
End;

Function UpStr(Const S:String):String;
Var
 I:Integer;
 R:String;
Begin
 R:=S;
 For I:=1 to Length(R)Do R[I]:=UpCase(R[I]);
 UpStr:=R;
End;

  {Affiche l'aide en ligne et termine le programme.}
Procedure ShowHelp;
Begin
 WriteLn('BMP2CUR : Cette commande permet de convertir une image BitMap (.BMP) ',
                   'en ressource curseur Windows (.CUR).');
 WriteLn;
 WriteLn('Syntaxe : BMP2CUR nomdufichier.BMP [/HX:n] [/HY:n]');
 WriteLn;
 WriteLn(' nomdufichier   Nom du fichier ".BMP" � convertir.');
 WriteLn(' /HX:n          Coordonn�e X du point chaud (hotspot), 0 par d�faut.');
 WriteLn(' /HY:n          Coordonn�e Y du point chaud (hotspot), 0 par d�faut.');
 WriteLn;
 WriteLn('Le fichier r�sultant porte le m�me nom avec l''extension .CUR.');
 WriteLn('Seuls les BitMaps 1, 4, 8 ou 24 bits par pixel non compress�s sont support�s.');
 WriteLn('Le masque de transparence (AND) est rempli � z�ro : tous les pixels du');
 WriteLn('curseur sont opaques (le BMP source ne porte pas d''information alpha).');
 Halt;
End;

BEGIN
  {Analyse de la ligne de commande : un nom de fichier obligatoire et,
   en option, /HX:n et /HY:n pour le point chaud.}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then ShowHelp;
 If ParamCount<1 Then Begin
  WriteLn('Param�tre requis !');
  Halt;
 End;
 InputName:='';
 HotspotX:=0;
 HotspotY:=0;
 For Argi:=1 to ParamCount Do Begin
  Arg:=ParamStr(Argi);
  ArgUp:=UpStr(Arg);
  If(Arg='/?')or(Arg='--help')or(Arg='-h')Then ShowHelp
  Else If(Length(ArgUp)>=4)and(Copy(ArgUp,1,4)='/HX:')Then Begin
   Val(Copy(Arg,5,Length(Arg)-4),ParamVal,Code);
   If(Code<>0)or(ParamVal<0)or(ParamVal>65535)Then Begin
    WriteLn('Valeur /HX invalide !');
    Halt;
   End;
   HotspotX:=Word(ParamVal);
  End
  Else If(Length(ArgUp)>=4)and(Copy(ArgUp,1,4)='/HY:')Then Begin
   Val(Copy(Arg,5,Length(Arg)-4),ParamVal,Code);
   If(Code<>0)or(ParamVal<0)or(ParamVal>65535)Then Begin
    WriteLn('Valeur /HY invalide !');
    Halt;
   End;
   HotspotY:=Word(ParamVal);
  End
  Else If InputName=''Then InputName:=Arg
  Else Begin
   WriteLn('Param�tre inattendu : ',Arg);
   Halt;
  End;
 End;
 If InputName=''Then Begin
  WriteLn('Param�tre requis !');
  Halt;
 End;

 {$I-}Assign(SourceBMP,InputName);
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

  {Lecture de la palette source (1, 4 ou 8 bpp).}
 NumPal:=0;
 PaletteBytes:=0;
 If BIH.biBitCount<24 Then Begin
  Case BIH.biBitCount of
   1:NumPal:=2;
   4:NumPal:=16;
   8:NumPal:=256;
  End;
   {biClrUsed=0 signifie "valeur par d�faut" (2^biBitCount). Sinon
    Windows requiert exactement 2^biBitCount entr�es dans la palette du
    DIB embarqu� dans une ressource ic�ne/curseur, donc on garde
    NumPal � cette valeur et on lit ce qui est r�ellement pr�sent.}
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
 OutputName:=Path2NameExt(InputName);
 {$I-}Assign(DestCUR,OutputName);
 Rewrite(DestCUR,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de cr�er le fichier ',OutputName);
  Close(SourceBMP);
  Halt;
 End;

  {1) En-t�te ICONDIR (6 octets) : un curseur, une seule image.}
 CurDir.idReserved:=0;
 CurDir.idType:=2;
 CurDir.idCount:=1;
 BlockWrite(DestCUR,CurDir,SizeOf(CurDir),ByteWritten);

  {2) Entr�e ICONDIRENTRY (16 octets). Pour un curseur, les champs
     wPlanes / wBitCount sont r�utilis�s pour le hotspot X / Y.}
 DIBSize:=SizeOf(BitmapInfoHeader)+PaletteBytes+
          XORStride*LongInt(ImageHeight)+ANDStride*LongInt(ImageHeight);
 If ImageWidth>=256 Then CurEntry.bWidth:=0
                    Else CurEntry.bWidth:=Byte(ImageWidth);
 If ImageHeight>=256 Then CurEntry.bHeight:=0
                     Else CurEntry.bHeight:=Byte(ImageHeight);
 Case BIH.biBitCount of
  1:CurEntry.bColorCount:=2;
  4:CurEntry.bColorCount:=16;
  Else CurEntry.bColorCount:=0;  { 8 bpp = 256 -> 0, 24 bpp -> 0 }
 End;
 CurEntry.bReserved:=0;
 CurEntry.wPlanes:=HotspotX;
 CurEntry.wBitCount:=HotspotY;
 CurEntry.dwBytesInRes:=DIBSize;
 CurEntry.dwImageOffset:=SizeOf(CurDir)+SizeOf(CurEntry); { 6+16 = 22 }
 BlockWrite(DestCUR,CurEntry,SizeOf(CurEntry),ByteWritten);

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
 BlockWrite(DestCUR,DIBHeader,SizeOf(DIBHeader),ByteWritten);

  {4) Palette du DIB (si pertinente). On recopie la palette du BMP
     telle quelle : m�me ordre BGRX, m�me nombre d'entr�es.}
 If PaletteBytes>0 Then BlockWrite(DestCUR,Palette,PaletteBytes,ByteWritten);

  {5) Masque XOR : recopie ligne par ligne des pixels du BMP. Le BMP
     est d�j� stock� bottom-up et utilise le m�me alignement DWORD que
     le DIB embarqu� ; on transf�re donc les lignes telles quelles.}
 For Y:=0 to LongInt(ImageHeight)-1 Do Begin
  Seek(SourceBMP,StartPos+Y*LongInt(BMPBytesPerLine));
  FillChar(BMPLine,XORStride,0);
  BlockRead(SourceBMP,BMPLine,BMPBytesPerLine,ByteReaded);
  BlockWrite(DestCUR,BMPLine,XORStride,ByteWritten);
 End;

  {6) Masque AND : 1 bit par pixel, � z�ro pour rendre l'int�gralit�
     du curseur opaque (le BMP source ne fournit aucune information
     d'alpha). Lignes "bottom-up" align�es sur 32 bits.}
 FillChar(ANDLine,SizeOf(ANDLine),0);
 For Y:=0 to LongInt(ImageHeight)-1 Do
  BlockWrite(DestCUR,ANDLine,ANDStride,ByteWritten);

 Close(DestCUR);
 Close(SourceBMP);
END.
