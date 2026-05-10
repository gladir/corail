{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2MAC;

{$A-}

Uses DOS;

Const
  {Type de compression Windows}
 bi_RGB=0;
 bi_RLE8=1;
 bi_RLE4=2;

  {Constantes du format MacPaint (Apple/Bill Atkinson, 1984).
   - En-t�te de 512 octets, normalement enti�rement � z�ro (sans
     en-t�te MacBinary, c'est-�-dire un fichier ".MAC" pur).
   - Image fixe de 576 pixels de largeur sur 720 pixels de hauteur
     en monochrome (1 bit par pixel, bit de poids fort = pixel le
     plus � gauche).
   - Convention de couleur : bit � 1 = noir, bit � 0 = blanc.
   - Les 720 lignes de 72 octets sont compress�es ind�pendamment
     par l'algorithme PackBits d'Apple.}
 MacPaintWidth=576;
 MacPaintHeight=720;
 MacPaintRowBytes=72;       { MacPaintWidth div 8 }
 MacPaintHeaderSize=512;

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
 SourceBMP,DestMAC:File;
 Header:HeaderBMP;
 BIH:BitMapInfoHeader;
 BMPBytesPerLine,ByteReaded,ByteWritten:Word;
 StartPos:LongInt;
 NumPal:Word;
 Palette:Array[0..1]of RGB32;
 BMPLine:Array[0..(MacPaintWidth div 8)*4+15]of Byte;{ Ligne brute lue dans le BMP }
 RowBuf:Array[0..MacPaintRowBytes-1]of Byte; { Une ligne MacPaint avant compression }
 PackBuf:Array[0..MacPaintRowBytes*2+1]of Byte; { Tampon PackBits (taille pire cas) }
 OutputName:String;
 SrcW,SrcH:LongInt;
 BMPBPL:LongInt;
 Y:LongInt;
 SourceRow:LongInt;
 BlackIndex:Byte;          { Index BMP qui sera mapp� au bit "1" (noir) }
 CopyW,CopyH:Word;         { Dimensions effectivement recopi�es (min(src, MacPaint)) }
 ZeroByte:Byte;
 I:Word;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.MAC';
End;

  {Lit la ligne brute du BMP (RowIndex=0 �tant la premi�re ligne stock�e
   dans le fichier ; les BMP �tant "bottom-up", l'appelant doit inverser
   l'index avant l'appel pour parcourir l'image de haut en bas).}
Procedure ReadBmpRow(RowIndex:LongInt);
Begin
 Seek(SourceBMP,StartPos+RowIndex*LongInt(BMPBytesPerLine));
 BlockRead(SourceBMP,BMPLine,BMPBytesPerLine,ByteReaded);
End;

  {Renvoie le bit (0 ou 1) pour le pixel d'abscisse X dans la ligne
   BMPLine en cours, en 1 bit par pixel, MSB en premier.}
Function GetSrcBit(X:Word):Byte;
Var
 ByteV:Byte;
Begin
 ByteV:=BMPLine[X shr 3];
 GetSrcBit:=(ByteV shr (7-(X and 7)))and 1;
End;

  {Encode un tampon de Count octets selon l'algorithme PackBits d'Apple
   et l'ajoute � PackBuf � partir de l'offset DestPos. Renvoie le
   nouvel offset (taille effective accumul�e). Format des "tokens" :

     - Si l'octet de t�te est compris entre 0 et 127 (signe positif),
       il code une suite litt�rale de (n+1) octets (1 � 128 octets)
       qui suivent l'en-t�te tels quels.
     - S'il est compris entre 129 et 255 (signe n�gatif en compl�ment
       � deux), il code une r�p�tition de (1-n) octets (2 � 128
       occurrences) du seul octet de donn�es qui suit.
     - La valeur 128 (-128) est r�serv�e (ignor�e par les d�codeurs).}
Function PackBitsRow(Const Src:Array of Byte;Count:Word;
                     Var Dest:Array of Byte):Word;
Var
 Pos,DestPos:Word;
 RunLen,LitLen,K:Word;
Begin
 Pos:=0;
 DestPos:=0;
 While Pos<Count Do Begin
   {D�tection d'une r�p�tition � la position courante.}
  RunLen:=1;
  While(Pos+RunLen<Count)and(RunLen<128)and
       (Src[Pos+RunLen]=Src[Pos])Do Inc(RunLen);
  If RunLen>=3 Then Begin
    {Course suffisamment longue pour �tre cod�e en run.}
   Dest[DestPos]:=Byte(257-RunLen); { (1-n) en compl�ment � deux sur 8 bits }
   Dest[DestPos+1]:=Src[Pos];
   Inc(DestPos,2);
   Inc(Pos,RunLen);
  End
   Else Begin
     {On accumule une suite litt�rale jusqu'� rencontrer une nouvelle
      r�p�tition d'au moins 3 octets, ou jusqu'� 128 octets, ou la fin
      du tampon source.}
    LitLen:=0;
    While(Pos+LitLen<Count)and(LitLen<128)Do Begin
     If(Pos+LitLen+2<Count)and
       (Src[Pos+LitLen]=Src[Pos+LitLen+1])and
       (Src[Pos+LitLen+1]=Src[Pos+LitLen+2])Then Break;
     Inc(LitLen);
    End;
    If LitLen=0 Then LitLen:=1; { S�curit� : ne devrait pas se produire }
    Dest[DestPos]:=Byte(LitLen-1);
    Inc(DestPos);
    For K:=0 to LitLen-1 Do Dest[DestPos+K]:=Src[Pos+K];
    Inc(DestPos,LitLen);
    Inc(Pos,LitLen);
   End;
 End;
 PackBitsRow:=DestPos;
End;

  {Calcule l'index BMP correspondant au noir, en comparant la
   luminance des deux entr�es de palette. Si le BMP utilise une
   palette atypique (par exemple index 0 = noir, ce qui est inverse
   de la convention MacPaint), on inverse les bits � la conversion.}
Function PickBlackIndex:Byte;
Var
 L0,L1:LongInt;
Begin
 L0:=LongInt(Palette[0].R)*299+LongInt(Palette[0].G)*587+LongInt(Palette[0].B)*114;
 L1:=LongInt(Palette[1].R)*299+LongInt(Palette[1].G)*587+LongInt(Palette[1].B)*114;
 If L0<=L1 Then PickBlackIndex:=0 Else PickBlackIndex:=1;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BMP2MAC : Cette commande permet de convertir une image BitMap (.BMP) ',
                    'en format MacPaint (.MAC, Apple).');
  WriteLn;
  WriteLn('Syntaxe : BMP2MAC nomdufichier.BMP');
  WriteLn;
  WriteLn(' nomdufichier   Nom du fichier ".BMP" � convertir.');
  WriteLn;
  WriteLn('Le fichier r�sultant porte le m�me nom avec l''extension .MAC. L''image');
  WriteLn('est format�e dans le canevas MacPaint fixe de 576 par 720 pixels en');
  WriteLn('monochrome (les images plus petites sont compl�t�es en blanc, les plus');
  WriteLn('grandes sont tronqu�es). Seuls les BitMaps 1 bit par pixel non');
  WriteLn('compress�s sont support�s en entr�e.');
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
  WriteLn('Seuls les BitMaps 1 bit par pixel (monochromes) sont support�s !');
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

  {Calcul du nombre d'octets par ligne BMP : multiple de 4 octets.}
 If BIH.biSizeImage=0 Then BMPBPL:=((LongInt(BIH.biWidth)+31)div 32)*4
                     Else BMPBPL:=LongInt(BIH.biSizeImage)div LongInt(BIH.biHeight);
 If(BMPBPL<=0)or(BMPBPL>SizeOf(BMPLine))Then Begin
  WriteLn('Largeur de l''image trop grande !');
  Halt;
 End;
 BMPBytesPerLine:=Word(BMPBPL);

  {Lecture de la palette (toujours 2 entr�es pour un BMP 1 bpp).}
 NumPal:=Word(BIH.biClrUsed);
 If NumPal=0 Then NumPal:=2;
 If NumPal>2 Then NumPal:=2;
 Seek(SourceBMP,14+SizeOf(BitmapInfoHeader));
 FillChar(Palette,SizeOf(Palette),0);
 BlockRead(SourceBMP,Palette,LongInt(NumPal)*SizeOf(RGB32),ByteReaded);
 BlackIndex:=PickBlackIndex;

 SrcW:=BIH.biWidth;
 SrcH:=BIH.biHeight;
 StartPos:=Header.OffBits;

  {On d�termine la zone effectivement recopi�e (intersection avec
   le canevas fixe MacPaint). Les pixels manquants sont laiss�s
   � z�ro (blanc).}
 If SrcW>MacPaintWidth Then CopyW:=MacPaintWidth Else CopyW:=Word(SrcW);
 If SrcH>MacPaintHeight Then CopyH:=MacPaintHeight Else CopyH:=Word(SrcH);

  {Cr�ation du fichier MAC de destination.}
 OutputName:=Path2NameExt(ParamStr(1));
 {$I-}Assign(DestMAC,OutputName);
 Rewrite(DestMAC,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de cr�er le fichier ',OutputName);
  Close(SourceBMP);
  Halt;
 End;

  {En-t�te MacPaint : 512 octets � z�ro (pas d'en-t�te MacBinary).}
 ZeroByte:=0;
 For I:=1 to MacPaintHeaderSize Do BlockWrite(DestMAC,ZeroByte,1,ByteWritten);

  {�criture des 720 lignes compress�es PackBits.}
 For Y:=0 to MacPaintHeight-1 Do Begin
    {Initialisation de la ligne en blanc (bits � 0).}
   FillChar(RowBuf,MacPaintRowBytes,0);

   If Y<CopyH Then Begin
      {Les lignes BMP sont stock�es de bas en haut : on calcule
       l'index dans le fichier source qui correspond � la ligne
       MacPaint d'ordre Y (0 = haut de l'image).}
     SourceRow:=LongInt(SrcH)-1-Y;
     ReadBmpRow(SourceRow);
     For I:=0 to CopyW-1 Do Begin
       If GetSrcBit(I)=BlackIndex Then
         RowBuf[I shr 3]:=RowBuf[I shr 3]or(1 shl (7-(I and 7)));
     End;
   End;

   ByteReaded:=PackBitsRow(RowBuf,MacPaintRowBytes,PackBuf);
   BlockWrite(DestMAC,PackBuf,ByteReaded,ByteWritten);
 End;

 Close(DestMAC);
 Close(SourceBMP);
END.
