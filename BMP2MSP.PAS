{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2MSP;

{$A-}

Uses DOS;

Const
  {Type de compression Windows}
 bi_RGB=0;
 bi_RLE8=1;
 bi_RLE4=2;

  {Constantes du format MSP (Microsoft Paint).
   Signature MSP version 1 (non compress�) : les caract�res 'D','a','n','M'
   stock�s en deux mots de 16 bits "petit-boutien" donnent les valeurs $6144
   ('D'+'a'*256) et $4D6E ('n'+'M'*256).}
 MSPSig1V1=$6144;        { 'D','a' }
 MSPSig2V1=$4D6E;        { 'n','M' }

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

  {En-t�te MSP : 32 octets, soit 16 mots de 16 bits en ordre Intel.}
 HeaderMSP=Record
  Sig1,Sig2:Word;          { Signature : "DanM" pour v1, "LinS" pour v2 }
  Width,Height:Word;       { Dimensions en pixels }
  XAspectRatio,
  YAspectRatio:Word;       { Rapport d'aspect (g�n�ralement 1, 1) }
  PrinterWidth,
  PrinterHeight:Word;      { Dimensions � l'impression (en points) }
  PrinterXOffset,
  PrinterYOffset:Word;     { D�calage � l'impression }
  Checksum:Word;           { XOR des dix premiers mots de l'en-t�te }
  Reserved:Array[0..4]of Word; { R�serv�, doit �tre � z�ro }
 End;

Var
 SourceBMP,DestMSP:File;
 Header:HeaderBMP;
 BIH:BitMapInfoHeader;
 MSPHeader:HeaderMSP;
 BMPBytesPerLine,ByteReaded,ByteWritten:Word;
 StartPos:LongInt;
 Palette:Array[0..1]of RGB32;
 BMPLine:Array[0..MaxWidth div 8]of Byte; { Ligne brute lue dans le BMP }
 OutLine:Array[0..MaxWidth div 8]of Byte; { Ligne � �crire vers le MSP }
 OutputName:String;
 ImageWidth,ImageHeight:Word;
 MSPBytesPerLine:Word;
 BMPBPL:LongInt;
 InvertBits:Boolean;
 I:Integer;
 Y:LongInt;
 SourceRow:LongInt;
 W:Word;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.MSP';
End;

  {Calcule la luminance approximative (norme ITU-R BT.601 simplifi�e) d'une
   entr�e de palette, pour d�terminer si elle correspond plut�t au noir ou
   au blanc.}
Function Luma(Const C:RGB32):LongInt;
Begin
 Luma:=LongInt(C.R)*30+LongInt(C.G)*59+LongInt(C.B)*11;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BMP2MSP : Cette commande permet de convertir une image BitMap (.BMP) ',
                    'monochrome en format MSP (.MSP) de Microsoft Paint.');
  WriteLn;
  WriteLn('Syntaxe : BMP2MSP nomdufichier.BMP');
  WriteLn;
  WriteLn(' nomdufichier   Nom du fichier ".BMP" 1 bit/pixel � convertir.');
  WriteLn;
  WriteLn('Le fichier r�sultant porte le m�me nom avec l''extension .MSP et utilise');
  WriteLn('la signature "DanM" (MSP version 1, sans compression).');
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
 If BIH.biBitCount<>1 Then Begin
  WriteLn('Seuls les BitMaps 1 bit par pixel (monochromes) sont support�s pour la conversion en MSP !');
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

 If BIH.biSizeImage=0 Then
  BMPBPL:=((LongInt(BIH.biWidth)+31)div 32)*4
  Else
  BMPBPL:=LongInt(BIH.biSizeImage)div LongInt(BIH.biHeight);
 If(BMPBPL<=0)or(BMPBPL>SizeOf(BMPLine))Then Begin
  WriteLn('Largeur de l''image trop grande !');
  Halt;
 End;
 BMPBytesPerLine:=Word(BMPBPL);

  {Lecture des deux entr�es de palette du BMP. La palette se situe juste
   apr�s l'en-t�te BITMAPINFOHEADER (offset 14 + 40 = 54).}
 Seek(SourceBMP,14+SizeOf(BitmapInfoHeader));
 BlockRead(SourceBMP,Palette,SizeOf(Palette),ByteReaded);
  {En MSP, le bit 1 repr�sente le pixel "encre" (typiquement noir) et le
   bit 0 le fond (typiquement blanc). En BMP 1 bit/pixel, le bit choisit
   l'index dans la palette : si Palette[1] est plus sombre que Palette[0],
   les bits du BMP correspondent d�j� � la convention MSP. Sinon il faut
   inverser chaque octet � l'�criture.}
 InvertBits:=Luma(Palette[1])>Luma(Palette[0]);

 ImageWidth:=Word(BIH.biWidth);
 ImageHeight:=Word(BIH.biHeight);
 MSPBytesPerLine:=Word((LongInt(ImageWidth)+7)div 8);
 StartPos:=Header.OffBits;

  {Construction de l'en-t�te MSP version 1 ("DanM").}
 FillChar(MSPHeader,SizeOf(MSPHeader),0);
 MSPHeader.Sig1:=MSPSig1V1;
 MSPHeader.Sig2:=MSPSig2V1;
 MSPHeader.Width:=ImageWidth;
 MSPHeader.Height:=ImageHeight;
 MSPHeader.XAspectRatio:=1;
 MSPHeader.YAspectRatio:=1;
 MSPHeader.PrinterWidth:=ImageWidth;
 MSPHeader.PrinterHeight:=ImageHeight;
 MSPHeader.PrinterXOffset:=0;
 MSPHeader.PrinterYOffset:=0;
  {Le checksum est le OU exclusif (XOR) des dix premiers mots de
   l'en-t�te (du Sig1 jusqu'au PrinterYOffset inclus).}
 W:=0;
 W:=W xor MSPHeader.Sig1;
 W:=W xor MSPHeader.Sig2;
 W:=W xor MSPHeader.Width;
 W:=W xor MSPHeader.Height;
 W:=W xor MSPHeader.XAspectRatio;
 W:=W xor MSPHeader.YAspectRatio;
 W:=W xor MSPHeader.PrinterWidth;
 W:=W xor MSPHeader.PrinterHeight;
 W:=W xor MSPHeader.PrinterXOffset;
 W:=W xor MSPHeader.PrinterYOffset;
 MSPHeader.Checksum:=W;

  {Cr�ation du fichier de destination.}
 OutputName:=Path2NameExt(ParamStr(1));
 {$I-}Assign(DestMSP,OutputName);
 Rewrite(DestMSP,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de cr�er le fichier ',OutputName);
  Close(SourceBMP);
  Halt;
 End;

  {�criture de l'en-t�te (32 octets).}
 BlockWrite(DestMSP,MSPHeader,SizeOf(MSPHeader),ByteWritten);

  {Boucle sur les lignes : MSP est stock� de haut en bas, BMP de bas
   en haut. On copie les octets significatifs (MSPBytesPerLine), en
   inversant �ventuellement chaque bit pour respecter la convention de
   polarit� MSP (1 = encre).}
 For Y:=0 to LongInt(ImageHeight)-1 Do Begin
  SourceRow:=LongInt(ImageHeight)-1-Y;
  Seek(SourceBMP,StartPos+SourceRow*LongInt(BMPBytesPerLine));
  BlockRead(SourceBMP,BMPLine,BMPBytesPerLine,ByteReaded);
  If InvertBits Then
   For I:=0 to MSPBytesPerLine-1 Do OutLine[I]:=BMPLine[I]xor $FF
  Else
   For I:=0 to MSPBytesPerLine-1 Do OutLine[I]:=BMPLine[I];
   {Les bits inutilis�s du dernier octet (lorsque la largeur n'est pas
    multiple de 8) doivent �tre � z�ro pour repr�senter du blanc en MSP.}
  If(ImageWidth and 7)<>0 Then
   OutLine[MSPBytesPerLine-1]:=OutLine[MSPBytesPerLine-1]
                              and(Byte($FF)shl(8-(ImageWidth and 7)));
  BlockWrite(DestMSP,OutLine,MSPBytesPerLine,ByteWritten);
 End;

 Close(DestMSP);
 Close(SourceBMP);
END.
