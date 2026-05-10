{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2CR2;

{$A-}

Uses DOS;

Const
 bi_RGB=0;
 MaxWidth=4096;

 TiffByteOrder=$4949;
 TiffMagic=42;
 TiffNoCompression=1;
 TiffTypeByte=1;
 TiffTypeASCII=2;
 TiffTypeShort=3;
 TiffTypeLong=4;
 TiffTypeRational=5;
 TiffTypeSRational=10;
 TiffPhotoCFA=32803;
 TiffResolutionInch=2;

 TagImageWidth=256;
 TagImageLength=257;
 TagBitsPerSample=258;
 TagCompression=259;
 TagPhotometric=262;
 TagMake=271;
 TagModel=272;
 TagStripOffsets=273;
 TagOrientation=274;
 TagSamplesPerPixel=277;
 TagRowsPerStrip=278;
 TagStripByteCounts=279;
 TagXResolution=282;
 TagYResolution=283;
 TagPlanarConfiguration=284;
 TagResolutionUnit=296;
 TagSoftware=305;
 TagDateTime=306;
 TagCFARepeatPatternDim=33421;
 TagCFAPattern=33422;
 TagCFAPlaneColor=50710;
 TagCFALayout=50711;
 TagBlackLevel=50714;
 TagWhiteLevel=50717;
 TagColorMatrix1=50721;
 TagCalibrationIlluminant1=50778;

 MakeText='Canon'#0;
 ModelText='Canon EOS 5D'#0;
 SoftwareText='CloneDRAW BMP2CR2'#0;
 DateTimeText='2026:01:01 00:00:00'#0;

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

Var
 SourceBMP,DestCR2:File;
 Header:HeaderBMP;
 BIH:BitmapInfoHeader;
 BMPBytesPerLine,ByteReaded,ByteWritten:Word;
 StartPos:LongInt;
 NumPal:Word;
 Palette:Array[0..255]of RGB32;
 BMPLine:Array[0..MaxWidth*3-1]of Byte;
 SourceFileName,OutputName:String;
 ImageWidth,ImageHeight:Word;
 BMPBPL:LongInt;
 TargetOpened:Boolean;
 NumEntries:Word;
 XResOffset,YResOffset:LongInt;
 MakeOffset,ModelOffset,SoftwareOffset,DateTimeOffset:LongInt;
 ColorMatrixOffset:LongInt;
 StripOffset,StripByteCount:LongInt;
 Y,SourceRow:LongInt;
 X:Word;
 R,G,B,Raw8:Byte;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.CR2';
End;

Procedure WriteError(Const S:String);
Begin
 WriteLn(S);
 Close(SourceBMP);
 If TargetOpened Then Close(DestCR2);
 Halt;
End;

Procedure WriteByteToFile(B:Byte);
Begin
 BlockWrite(DestCR2,B,1,ByteWritten);
End;

Procedure WriteWordToFile(W:Word);
Var
 Tmp:Array[0..1]of Byte;
Begin
 Tmp[0]:=Byte(W and $FF);
 Tmp[1]:=Byte((W shr 8)and $FF);
 BlockWrite(DestCR2,Tmp,2,ByteWritten);
End;

Procedure WriteLongToFile(L:LongInt);
Var
 Tmp:Array[0..3]of Byte;
Begin
 Tmp[0]:=Byte(L and $FF);
 Tmp[1]:=Byte((L shr 8)and $FF);
 Tmp[2]:=Byte((L shr 16)and $FF);
 Tmp[3]:=Byte((L shr 24)and $FF);
 BlockWrite(DestCR2,Tmp,4,ByteWritten);
End;

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

Procedure WriteSRational(Numerator,Denominator:LongInt);
Begin
 WriteLongToFile(Numerator);
 WriteLongToFile(Denominator);
End;

Procedure WriteStringData(Const S:String);
Var
 I:Integer;
 C:Char;
Begin
 For I:=1 to Length(S) Do Begin
  C:=S[I];
  BlockWrite(DestCR2,C,1,ByteWritten);
 End;
End;

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
  8:GetPalIndex:=BMPLine[X];
  Else GetPalIndex:=0;
 End;
End;

Procedure GetRGBPixel(X:Word;Var Red,Green,Blue:Byte);
Var
 Index:Byte;
Begin
 If BIH.biBitCount=24 Then Begin
  Blue:=BMPLine[X*3+0];
  Green:=BMPLine[X*3+1];
  Red:=BMPLine[X*3+2];
 End
  Else
 Begin
  Index:=GetPalIndex(X);
  Red:=Palette[Index].R;
  Green:=Palette[Index].G;
  Blue:=Palette[Index].B;
 End;
End;

Procedure WriteRaw16(Value8:Byte);
Var
 Value16:Word;
Begin
 Value16:=Word(Value8)*257;
 WriteWordToFile(Value16);
End;

Procedure WriteCanonLikeColorMatrix;
Begin
 {Matrice approximative sRGB/Canon neutre en rationnels signes TIFF.
  Un vrai CR2 Canon contient des matrices et MakerNotes propres au boitier.}
 WriteSRational(1,1); WriteSRational(0,1); WriteSRational(0,1);
 WriteSRational(0,1); WriteSRational(1,1); WriteSRational(0,1);
 WriteSRational(0,1); WriteSRational(0,1); WriteSRational(1,1);
End;

Procedure ShowHelp;
Begin
 WriteLn('BMP2CR2 : Cette commande permet de convertir une image BitMap (.BMP) ');
 WriteLn('          en fichier .CR2 minimal de type Canon RAW 2.');
 WriteLn;
 WriteLn('Syntaxe : BMP2CR2 source.BMP [destination.CR2]');
 WriteLn;
 WriteLn(' source.BMP      Ce parametre permet d''indiquer le nom du fichier ".BMP".');
 WriteLn(' destination.CR2 Ce parametre permet d''indiquer le nom du fichier ".CR2".');
 WriteLn;
 WriteLn('Le fichier cree est un conteneur CR2/TIFF little-endian avec une image CFA');
 WriteLn('16 bits non compressee, matrice Bayer RGGB et tags RAW essentiels.');
 WriteLn('Limite : un vrai CR2 Canon contient des donnees capteur et MakerNotes');
 WriteLn('proprietaires impossibles a reconstruire fidelement depuis un BMP.');
 Halt;
End;

BEGIN
 TargetOpened:=False;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then
  ShowHelp;
 If ParamCount<1 Then Begin
  WriteLn('Parametre requis !');
  Halt;
 End;

 SourceFileName:=ParamStr(1);
 If ParamCount>1 Then OutputName:=ParamStr(2)
                 Else OutputName:=Path2NameExt(SourceFileName);

 {$I-}Assign(SourceBMP,SourceFileName);
 Reset(SourceBMP,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier BMP : ',SourceFileName);
  Halt;
 End;

 BlockRead(SourceBMP,Header,SizeOf(Header),ByteReaded);
 If Header.Sign<>'BM'Then WriteError('Signature d''entete Bitmap introuvable !');
 Seek(SourceBMP,14);
 BlockRead(SourceBMP,BIH,SizeOf(BIH),ByteReaded);
 If(BIH.biBitCount<>1)and(BIH.biBitCount<>4)and(BIH.biBitCount<>8)
   and(BIH.biBitCount<>24)Then WriteError('Profondeur BMP non supportee !');
 If BIH.biCompression<>bi_RGB Then WriteError('Compression BMP non supportee !');
 If(BIH.biWidth<=0)or(BIH.biHeight<=0)Then WriteError('Dimensions BMP invalides !');
 If LongInt(BIH.biWidth)>MaxWidth Then WriteError('Image trop large !');

 If BIH.biSizeImage=0 Then Begin
  Case BIH.biBitCount of
   1:BMPBPL:=((LongInt(BIH.biWidth)+31)div 32)*4;
   4:BMPBPL:=((LongInt(BIH.biWidth)+7)div 8)*4;
   8:BMPBPL:=((LongInt(BIH.biWidth)+3)div 4)*4;
   24:BMPBPL:=((LongInt(BIH.biWidth)*3+3)div 4)*4;
   Else BMPBPL:=0;
  End;
 End
  Else
 BMPBPL:=LongInt(BIH.biSizeImage)div LongInt(BIH.biHeight);
 If(BMPBPL<=0)or(BMPBPL>SizeOf(BMPLine))Then
  WriteError('Largeur de l''image trop grande !');
 BMPBytesPerLine:=Word(BMPBPL);

 If BIH.biBitCount<=8 Then Begin
  NumPal:=Word(BIH.biClrUsed);
  If NumPal=0 Then NumPal:=1 shl BIH.biBitCount;
  Seek(SourceBMP,14+SizeOf(BitmapInfoHeader));
  BlockRead(SourceBMP,Palette,LongInt(NumPal)*SizeOf(RGB32),ByteReaded);
 End;

 ImageWidth:=Word(BIH.biWidth);
 ImageHeight:=Word(BIH.biHeight);
 StartPos:=Header.OffBits;

 NumEntries:=25;
 XResOffset:=16+2+LongInt(NumEntries)*12+4;
 YResOffset:=XResOffset+8;
 MakeOffset:=YResOffset+8;
 ModelOffset:=MakeOffset+Length(MakeText);
 SoftwareOffset:=ModelOffset+Length(ModelText);
 DateTimeOffset:=SoftwareOffset+Length(SoftwareText);
 ColorMatrixOffset:=DateTimeOffset+Length(DateTimeText);
 StripOffset:=ColorMatrixOffset+72;
 StripByteCount:=LongInt(ImageWidth)*LongInt(ImageHeight)*2;

 {$I-}Assign(DestCR2,OutputName);
 Rewrite(DestCR2,1);{$I+}
 If IOResult<>0 Then Begin
  Close(SourceBMP);
  WriteLn('Impossible de creer le fichier ',OutputName);
  Halt;
 End;
 TargetOpened:=True;

 {En-tete CR2 : TIFF little-endian, premier IFD a l'offset 16, puis marqueur
  Canon CR2 "CR", version 2.0, et offset RAW IFD laisse a zero.}
 WriteWordToFile(TiffByteOrder);
 WriteWordToFile(TiffMagic);
 WriteLongToFile(16);
 WriteByteToFile(Ord('C'));
 WriteByteToFile(Ord('R'));
 WriteWordToFile(2);
 WriteLongToFile(0);

 WriteWordToFile(NumEntries);
 WriteIFDEntry(TagImageWidth,TiffTypeLong,1,LongInt(ImageWidth));
 WriteIFDEntry(TagImageLength,TiffTypeLong,1,LongInt(ImageHeight));
 WriteIFDEntry(TagBitsPerSample,TiffTypeShort,1,16);
 WriteIFDEntry(TagCompression,TiffTypeShort,1,TiffNoCompression);
 WriteIFDEntry(TagPhotometric,TiffTypeShort,1,TiffPhotoCFA);
 WriteIFDEntry(TagMake,TiffTypeASCII,Length(MakeText),MakeOffset);
 WriteIFDEntry(TagModel,TiffTypeASCII,Length(ModelText),ModelOffset);
 WriteIFDEntry(TagStripOffsets,TiffTypeLong,1,StripOffset);
 WriteIFDEntry(TagOrientation,TiffTypeShort,1,1);
 WriteIFDEntry(TagSamplesPerPixel,TiffTypeShort,1,1);
 WriteIFDEntry(TagRowsPerStrip,TiffTypeLong,1,LongInt(ImageHeight));
 WriteIFDEntry(TagStripByteCounts,TiffTypeLong,1,StripByteCount);
 WriteIFDEntry(TagXResolution,TiffTypeRational,1,XResOffset);
 WriteIFDEntry(TagYResolution,TiffTypeRational,1,YResOffset);
 WriteIFDEntry(TagPlanarConfiguration,TiffTypeShort,1,1);
 WriteIFDEntry(TagResolutionUnit,TiffTypeShort,1,TiffResolutionInch);
 WriteIFDEntry(TagSoftware,TiffTypeASCII,Length(SoftwareText),SoftwareOffset);
 WriteIFDEntry(TagDateTime,TiffTypeASCII,Length(DateTimeText),DateTimeOffset);
 WriteIFDEntry(TagCFARepeatPatternDim,TiffTypeShort,2,LongInt($00020002));
 WriteIFDEntry(TagCFAPattern,TiffTypeByte,4,LongInt($02010100));
 WriteIFDEntry(TagCFAPlaneColor,TiffTypeByte,3,LongInt($00020100));
 WriteIFDEntry(TagCFALayout,TiffTypeShort,1,1);
 WriteIFDEntry(TagBlackLevel,TiffTypeLong,1,0);
 WriteIFDEntry(TagWhiteLevel,TiffTypeLong,1,65535);
 WriteIFDEntry(TagColorMatrix1,TiffTypeSRational,9,ColorMatrixOffset);
 WriteLongToFile(0);

 WriteRational(72,1);
 WriteRational(72,1);
 WriteStringData(MakeText);
 WriteStringData(ModelText);
 WriteStringData(SoftwareText);
 WriteStringData(DateTimeText);
 WriteCanonLikeColorMatrix;

 For Y:=LongInt(ImageHeight)-1 downto 0 Do Begin
  SourceRow:=Y;
  Seek(SourceBMP,StartPos+SourceRow*LongInt(BMPBytesPerLine));
  BlockRead(SourceBMP,BMPLine,BMPBytesPerLine,ByteReaded);
  For X:=0 to ImageWidth-1 Do Begin
   GetRGBPixel(X,R,G,B);
   If(Y and 1)=0 Then Begin
    If(X and 1)=0 Then Raw8:=R Else Raw8:=G;
   End
    Else
   Begin
    If(X and 1)=0 Then Raw8:=G Else Raw8:=B;
   End;
   WriteRaw16(Raw8);
  End;
 End;

 Close(DestCR2);
 TargetOpened:=False;
 Close(SourceBMP);
 WriteLn('Fichier CR2 cree : ',OutputName);
END.
