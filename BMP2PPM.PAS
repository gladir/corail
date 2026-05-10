{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2PPM;

{$A-}

Uses DOS;

Const
  {Type de compression Windows}
 bi_RGB=0;
 bi_RLE8=1;
 bi_RLE4=2;

 MaxLineBytes=16384;

Type
 RGB=Record
  R,G,B:Byte;
 End;

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

Var
 SourceBMP,TargetPPM:File;
 Header:HeaderBMP;
 BIH:BitmapInfoHeader;
 Palette:Array[0..255]of RGB32;
 Buffer:Array[0..MaxLineBytes-1]of Byte;
 HeaderStr,SourceFileName,TargetFileName:String;
 BMPBytesPerLine,ByteReaded,ByteWritten:Word;
 ImageWidth,ImageHeight,NumPal:Word;
 StartPos,BMPBPL:LongInt;
 Y:LongInt;
 Pixel:RGB;

Function IntToStr(I:LongInt):String;
Var
 S:String;
Begin
 Str(I,S);
 IntToStr:=S;
End;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.PPM';
End;

Function AbsLong(Value:LongInt):LongInt;
Begin
 If Value<0 Then AbsLong:=-Value
            Else AbsLong:=Value;
End;

Procedure ReadBmpRow(RowIndex:LongInt);
Begin
 Seek(SourceBMP,StartPos+RowIndex*BMPBytesPerLine);
 BlockRead(SourceBMP,Buffer,BMPBytesPerLine,ByteReaded);
 If ByteReaded<>BMPBytesPerLine Then Begin
  WriteLn('Lecture incomplete d''une ligne BMP !');
  Close(SourceBMP);
  Close(TargetPPM);
  Halt;
 End;
End;

Procedure WriteRGB(R,G,B:Byte);
Begin
 Pixel.R:=R;
 Pixel.G:=G;
 Pixel.B:=B;
 BlockWrite(TargetPPM,Pixel,SizeOf(Pixel),ByteWritten);
 If ByteWritten<>SizeOf(Pixel) Then Begin
  WriteLn('Impossible d''ecrire un pixel PPM !');
  Close(SourceBMP);
  Close(TargetPPM);
  Halt;
 End;
End;

Procedure WritePalettePixel(Index:Byte);
Begin
 If Index>=NumPal Then WriteRGB(0,0,0)
                 Else WriteRGB(Palette[Index].R,Palette[Index].G,Palette[Index].B);
End;

Procedure WriteBmpLine;
Var
 I:LongInt;
 B:Byte;
 W:Word;
Begin
 Case BIH.biBitCount of
  1:Begin
   For I:=0 to ImageWidth-1 Do Begin
    B:=Buffer[I shr 3];
    If(B and ($80 shr (I and 7)))<>0 Then WritePalettePixel(1)
                                      Else WritePalettePixel(0);
   End;
  End;
  4:Begin
   For I:=0 to ImageWidth-1 Do Begin
    B:=Buffer[I shr 1];
    If(I and 1)=0 Then WritePalettePixel(B shr 4)
                  Else WritePalettePixel(B and $0F);
   End;
  End;
  8:Begin
   For I:=0 to ImageWidth-1 Do WritePalettePixel(Buffer[I]);
  End;
  16:Begin
   For I:=0 to ImageWidth-1 Do Begin
    W:=Word(Buffer[I*2])+(Word(Buffer[I*2+1]) shl 8);
    WriteRGB(Byte(((W shr 10)and 31) shl 3),
             Byte(((W shr 5)and 31) shl 3),
             Byte((W and 31) shl 3));
   End;
  End;
  24:Begin
   For I:=0 to ImageWidth-1 Do Begin
    WriteRGB(Buffer[I*3+2],Buffer[I*3+1],Buffer[I*3]);
   End;
  End;
  32:Begin
   For I:=0 to ImageWidth-1 Do Begin
    WriteRGB(Buffer[I*4+2],Buffer[I*4+1],Buffer[I*4]);
   End;
  End;
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BMP2PPM : Cette commande permet de convertir une image BitMap (.BMP) ',
                    'en format d''image PPM (Portable PixMap).');
  WriteLn;
  WriteLn('Syntaxe : BMP2PPM source.BMP [destination.PPM]');
  WriteLn;
  WriteLn(' source.BMP      Ce parametre permet d''indiquer le nom du fichier ".BMP".');
  WriteLn(' destination.PPM Ce parametre permet d''indiquer le nom du fichier ".PPM".');
  WriteLn;
  WriteLn('Si destination est omis, le fichier resultant porte le meme nom avec l''extension .PPM.');
  WriteLn('Seuls les BitMaps non compresses 1, 4, 8, 16, 24 ou 32 bits sont supportes.');
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
  WriteLn('Dimensions trop grandes pour le format PPM !');
  Close(SourceBMP);
  Halt;
 End;
 If(BIH.biBitCount<>1)and(BIH.biBitCount<>4)and(BIH.biBitCount<>8)and
   (BIH.biBitCount<>16)and(BIH.biBitCount<>24)and(BIH.biBitCount<>32)Then Begin
  WriteLn('Bits par pixel non supporte pour la conversion en PPM !');
  Close(SourceBMP);
  Halt(2);
 End;

 ImageWidth:=Word(BIH.biWidth);
 ImageHeight:=Word(AbsLong(BIH.biHeight));
 BMPBPL:=((LongInt(ImageWidth)*LongInt(BIH.biBitCount)+31)div 32)*4;
 If(BMPBPL<=0)or(BMPBPL>SizeOf(Buffer))Then Begin
  WriteLn('Largeur de l''image trop grande !');
  Close(SourceBMP);
  Halt;
 End;
 BMPBytesPerLine:=Word(BMPBPL);

 NumPal:=0;
 Case BIH.biBitCount of
  1:NumPal:=2;
  4:NumPal:=16;
  8:NumPal:=256;
 End;
 If(BIH.biClrUsed>0)and(BIH.biClrUsed<NumPal)Then NumPal:=Word(BIH.biClrUsed);
 If NumPal>0 Then Begin
  Seek(SourceBMP,14+SizeOf(BitmapInfoHeader));
  BlockRead(SourceBMP,Palette,LongInt(NumPal)*4,ByteReaded);
  If ByteReaded<>LongInt(NumPal)*4 Then Begin
   WriteLn('Palette BMP incomplete !');
   Close(SourceBMP);
   Halt;
  End;
 End;

 StartPos:=Header.OffBits;
 {$I-}Assign(TargetPPM,TargetFileName);
 Rewrite(TargetPPM,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible d''ecrire le fichier PPM : ',TargetFileName);
  Close(SourceBMP);
  Halt;
 End;

 HeaderStr:='P6'#10+IntToStr(ImageWidth)+' '+
            IntToStr(ImageHeight)+#10+
            IntToStr(255)+#10;
 BlockWrite(TargetPPM,HeaderStr[1],Length(HeaderStr),ByteWritten);
 If ByteWritten<>Length(HeaderStr) Then Begin
  WriteLn('Impossible d''ecrire l''entete PPM !');
  Close(SourceBMP);
  Close(TargetPPM);
  Halt;
 End;

 For Y:=0 to ImageHeight-1 Do Begin
  If BIH.biHeight>0 Then
   ReadBmpRow(LongInt(ImageHeight)-1-Y)
  Else
   ReadBmpRow(Y);
  WriteBmpLine;
 End;

 Close(SourceBMP);
 Close(TargetPPM);
 WriteLn('Fichier PPM cree : ',TargetFileName);
END.
