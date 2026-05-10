{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2BGX;

{$A-}

Uses DOS;

Const
  {Type de compression Windows}
 bi_RGB=0;
 bi_RLE8=1;
 bi_RLE4=2;

  {Largeur maximale supportee pour une ligne BMP, padding inclus.}
 MaxLineBytes=16384;

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
  biSize:LongInt;
  biWidth:LongInt;
  biHeight:LongInt;
  biPlanes:Word;
  biBitCount:Word;
  biCompression:LongInt;
  biSizeImage:LongInt;
  biXPelsPerMeter:LongInt;
  biYPelsPerMeter:LongInt;
  biClrUsed:LongInt;
  biClrImportant:LongInt;
 End;

 {Entete d'un format d'image BGX}
 BGXHeader=Record
  Sign:Array[0..3]of Char;
  NumXPixels,NumYPixels:Word;
  BitsPerPixel:Byte;
 End;

Var
 SourceBMP,TargetBGX:File;
 Header:HeaderBMP;
 BIH:BitMapInfoHeader;
 BGX:BGXHeader;
 Buffer:Array[0..MaxLineBytes-1]of Byte;
 SourceFileName,TargetFileName:String;
 BMPBytesPerLine,BGXBytesPerLine,ByteReaded,ByteWritten:Word;
 ImageWidth,ImageHeight:Word;
 StartPos,BMPBPL:LongInt;
 Y:LongInt;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.BGX';
End;

Function AbsLong(Value:LongInt):LongInt;
Begin
 If Value<0 Then AbsLong:=-Value
            Else AbsLong:=Value;
End;

Function LenNBits2BytesPerLine(Width:Word;Bits4Pixel:Byte):Word;Near;Begin
 Case(Bits4Pixel)of
  1:LenNBits2BytesPerLine:=(Width+7)shr 3;
  2:LenNBits2BytesPerLine:=(Width+3)shr 2;
  4:LenNBits2BytesPerLine:=(Width+1)shr 1;
  9..16:LenNBits2BytesPerLine:=Width shl 1;
  17..24:LenNBits2BytesPerLine:=Width*3;
  25..32:LenNBits2BytesPerLine:=Width shl 2;
  33..64:LenNBits2BytesPerLine:=Width shl 4;
  Else LenNBits2BytesPerLine:=Width;
 End;
End;

Procedure ReadBmpRow(RowIndex:LongInt);
Begin
 Seek(SourceBMP,StartPos+RowIndex*BMPBytesPerLine);
 BlockRead(SourceBMP,Buffer,BMPBytesPerLine,ByteReaded);
 If ByteReaded<>BMPBytesPerLine Then Begin
  WriteLn('Lecture incomplete d''une ligne BMP !');
  Close(SourceBMP);
  Close(TargetBGX);
  Halt;
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BMP2BGX : Cette commande permet de convertir une image BitMap (.BMP) ',
                    'en format BGX (MonsterBook).');
  WriteLn;
  WriteLn('Syntaxe : BMP2BGX source.BMP [dest.BGX]');
  WriteLn;
  WriteLn(' source  Ce parametre permet d''indiquer le nom du fichier BMP.');
  WriteLn(' dest    Ce parametre permet d''indiquer le nom du fichier BGX.');
  WriteLn;
  WriteLn('Si dest est omis, le fichier resultant porte le meme nom avec l''extension .BGX.');
  WriteLn('Seuls les BitMaps non compresses 4, 8, 16, 24 ou 32 bits sont supportes.');
  Halt;
 End;
 If ParamCount<1 Then Begin
  WriteLn('Parametre requis !');
  Halt;
 End;

 SourceFileName:=ParamStr(1);
 If ParamCount>1 Then TargetFileName:=ParamStr(2)
                 Else TargetFileName:=Path2NameExt(SourceFileName);

 {$I-}Assign(SourceBMP,SourceFileName);
 Reset(SourceBMP,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier BMP : ',SourceFileName);
  Halt;
 End;

 BlockRead(SourceBMP,Header,SizeOf(Header),ByteReaded);
 If Header.Sign<>'BM'Then Begin
  WriteLn('Signature d''entete Bitmap introuvable !');
  Close(SourceBMP);
  Halt;
 End;

 Seek(SourceBMP,14);
 BlockRead(SourceBMP,BIH,SizeOf(BIH),ByteReaded);
 If BIH.biCompression<>bi_RGB Then Begin
  WriteLn('Compression RLE4 ou RLE8 non supportee');
  Close(SourceBMP);
  Halt(3);
 End;
 If(BIH.biWidth<=0)or(BIH.biHeight=0)Then Begin
  WriteLn('Dimensions invalides !');
  Close(SourceBMP);
  Halt;
 End;
 If(BIH.biWidth>65535)or(AbsLong(BIH.biHeight)>65535)Then Begin
  WriteLn('Dimensions trop grandes pour le format BGX !');
  Close(SourceBMP);
  Halt;
 End;
 If(BIH.biBitCount<>4)and(BIH.biBitCount<>8)and
   (BIH.biBitCount<>16)and(BIH.biBitCount<>24)and
   (BIH.biBitCount<>32)Then Begin
  WriteLn('Bits par pixel non supporte pour la conversion en BGX !');
  Close(SourceBMP);
  Halt(2);
 End;

 ImageWidth:=Word(BIH.biWidth);
 ImageHeight:=Word(AbsLong(BIH.biHeight));
 BMPBPL:=((LongInt(ImageWidth)*LongInt(BIH.biBitCount)+31)div 32)*4;
 BGXBytesPerLine:=LenNBits2BytesPerLine(ImageWidth,Byte(BIH.biBitCount));
 If(BMPBPL<=0)or(BMPBPL>SizeOf(Buffer))Then Begin
  WriteLn('Largeur de l''image trop grande !');
  Close(SourceBMP);
  Halt;
 End;
 BMPBytesPerLine:=Word(BMPBPL);
 StartPos:=Header.OffBits;

 BGX.Sign:='BGX1';
 BGX.NumXPixels:=ImageWidth;
 BGX.NumYPixels:=ImageHeight;
 BGX.BitsPerPixel:=Byte(BIH.biBitCount);

 {$I-}Assign(TargetBGX,TargetFileName);
 Rewrite(TargetBGX,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible d''ecrire le fichier BGX : ',TargetFileName);
  Close(SourceBMP);
  Halt;
 End;

 BlockWrite(TargetBGX,BGX,SizeOf(BGX),ByteWritten);
 If ByteWritten<>SizeOf(BGX) Then Begin
  WriteLn('Impossible d''ecrire l''entete BGX !');
  Close(SourceBMP);
  Close(TargetBGX);
  Halt;
 End;

 For Y:=0 to ImageHeight-1 Do Begin
  If BIH.biHeight>0 Then
   ReadBmpRow(LongInt(ImageHeight)-1-Y)
  Else
   ReadBmpRow(Y);
  BlockWrite(TargetBGX,Buffer,BGXBytesPerLine,ByteWritten);
  If ByteWritten<>BGXBytesPerLine Then Begin
   WriteLn('Impossible d''ecrire une ligne BGX !');
   Close(SourceBMP);
   Close(TargetBGX);
   Halt;
  End;
 End;

 Close(SourceBMP);
 Close(TargetBGX);
 WriteLn('Fichier BGX cree : ',TargetFileName);
END.
