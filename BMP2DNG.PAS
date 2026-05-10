{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2DNG;

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
 TagDNGVersion=50706;
 TagDNGBackwardVersion=50707;
 TagUniqueCameraModel=50708;
 TagCFAPlaneColor=50710;
 TagCFALayout=50711;
 TagBlackLevel=50714;
 TagWhiteLevel=50717;
 TagDefaultScale=50718;
 TagDefaultCropOrigin=50719;
 TagDefaultCropSize=50720;
 TagColorMatrix1=50721;
 TagAsShotNeutral=50728;
 TagCalibrationIlluminant1=50778;
 TagOriginalRawFileName=50827;

 MakeText='Adobe'#0;
 ModelText='Digital Negative'#0;
 SoftwareText='CloneDRAW BMP2DNG'#0;
 UniqueCameraText='CloneDRAW Virtual DNG Camera'#0;
 DateTimeText='2026:01:01 00:00:00'#0;
 OriginalRawText='BMP source converted to DNG'#0;

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
 SourceBMP,DestDNG:File;
 Header:HeaderBMP;
 BIH:BitmapInfoHeader;
 BMPBytesPerLine,ByteReaded,ByteWritten:Word;
 StartPos:LongInt;
 NumPal:Word;
 Palette:Array[0..255]of RGB32;
 BMPLine:Array[0..MaxWidth*4-1]of Byte;
 SourceFileName,OutputName:String;
 ImageWidth,ImageHeight:Word;
 BMPBPL:LongInt;
 TargetOpened:Boolean;
 NumEntries:Word;
 XResOffset,YResOffset:LongInt;
 MakeOffset,ModelOffset,SoftwareOffset,UniqueCameraOffset:LongInt;
 DateTimeOffset,OriginalRawOffset:LongInt;
 ColorMatrixOffset,AsShotNeutralOffset:LongInt;
 DefaultScaleOffset,DefaultCropOriginOffset,DefaultCropSizeOffset:LongInt;
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
 Path2NameExt:=D+N+'.DNG';
End;

Function AbsLong(Value:LongInt):LongInt;
Begin
 If Value<0 Then AbsLong:=-Value
            Else AbsLong:=Value;
End;

Procedure WriteError(Const S:String);
Begin
 WriteLn(S);
 Close(SourceBMP);
 If TargetOpened Then Close(DestDNG);
 Halt;
End;

Procedure WriteByteToFile(B:Byte);
Begin
 BlockWrite(DestDNG,B,1,ByteWritten);
End;

Procedure WriteWordToFile(W:Word);
Var
 Tmp:Array[0..1]of Byte;
Begin
 Tmp[0]:=Byte(W and $FF);
 Tmp[1]:=Byte((W shr 8)and $FF);
 BlockWrite(DestDNG,Tmp,2,ByteWritten);
End;

Procedure WriteLongToFile(L:LongInt);
Var
 Tmp:Array[0..3]of Byte;
Begin
 Tmp[0]:=Byte(L and $FF);
 Tmp[1]:=Byte((L shr 8)and $FF);
 Tmp[2]:=Byte((L shr 16)and $FF);
 Tmp[3]:=Byte((L shr 24)and $FF);
 BlockWrite(DestDNG,Tmp,4,ByteWritten);
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
  BlockWrite(DestDNG,C,1,ByteWritten);
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
 W:Word;
Begin
 Case BIH.biBitCount of
  1,4,8:Begin
   Index:=GetPalIndex(X);
   If Index>=NumPal Then Begin
    Red:=0; Green:=0; Blue:=0;
   End
    Else
   Begin
    Red:=Palette[Index].R;
    Green:=Palette[Index].G;
    Blue:=Palette[Index].B;
   End;
  End;
  16:Begin
   W:=Word(BMPLine[X*2])+(Word(BMPLine[X*2+1])shl 8);
   Red:=Byte(((W shr 10)and 31)shl 3);
   Green:=Byte(((W shr 5)and 31)shl 3);
   Blue:=Byte((W and 31)shl 3);
  End;
  24:Begin
   Blue:=BMPLine[X*3+0];
   Green:=BMPLine[X*3+1];
   Red:=BMPLine[X*3+2];
  End;
  32:Begin
   Blue:=BMPLine[X*4+0];
   Green:=BMPLine[X*4+1];
   Red:=BMPLine[X*4+2];
  End;
  Else Begin Red:=0; Green:=0; Blue:=0; End;
 End;
End;

Procedure WriteRaw16(Value8:Byte);
Begin
 WriteWordToFile(Word(Value8)*257);
End;

Procedure WriteIdentityColorMatrix;
Begin
 WriteSRational(1,1); WriteSRational(0,1); WriteSRational(0,1);
 WriteSRational(0,1); WriteSRational(1,1); WriteSRational(0,1);
 WriteSRational(0,1); WriteSRational(0,1); WriteSRational(1,1);
End;

Procedure WriteHelp;
Begin
 WriteLn('BMP2DNG : Cette commande permet de convertir une image BitMap (.BMP) ');
 WriteLn('          en fichier Adobe Digital Negative (.DNG).');
 WriteLn;
 WriteLn('Syntaxe : BMP2DNG source.BMP [destination.DNG]');
 WriteLn;
 WriteLn(' source.BMP      Ce parametre permet d''indiquer le nom du fichier ".BMP".');
 WriteLn(' destination.DNG Ce parametre permet d''indiquer le nom du fichier ".DNG".');
 WriteLn;
 WriteLn('Le fichier cree est un TIFF/DNG minimal : CFA RGGB 16 bits non compresse,');
 WriteLn('tags DNG essentiels, matrice couleur identite et donnees derivees du BMP.');
 Halt;
End;

BEGIN
 TargetOpened:=False;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then
  WriteHelp;
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
   and(BIH.biBitCount<>16)and(BIH.biBitCount<>24)and(BIH.biBitCount<>32)Then
  WriteError('Profondeur BMP non supportee !');
 If BIH.biCompression<>bi_RGB Then WriteError('Compression BMP non supportee !');
 If(BIH.biWidth<=0)or(BIH.biHeight=0)Then WriteError('Dimensions BMP invalides !');
 If LongInt(BIH.biWidth)>MaxWidth Then WriteError('Image trop large !');

 ImageWidth:=Word(BIH.biWidth);
 ImageHeight:=Word(AbsLong(BIH.biHeight));
 If BIH.biSizeImage=0 Then Begin
  Case BIH.biBitCount of
   1:BMPBPL:=((LongInt(ImageWidth)+31)div 32)*4;
   4:BMPBPL:=((LongInt(ImageWidth)+7)div 8)*4;
   8:BMPBPL:=((LongInt(ImageWidth)+3)div 4)*4;
   16:BMPBPL:=((LongInt(ImageWidth)*2+3)div 4)*4;
   24:BMPBPL:=((LongInt(ImageWidth)*3+3)div 4)*4;
   32:BMPBPL:=LongInt(ImageWidth)*4;
   Else BMPBPL:=0;
  End;
 End
  Else
 BMPBPL:=LongInt(BIH.biSizeImage)div LongInt(ImageHeight);
 If(BMPBPL<=0)or(BMPBPL>SizeOf(BMPLine))Then
  WriteError('Largeur de l''image trop grande !');
 BMPBytesPerLine:=Word(BMPBPL);

 If BIH.biBitCount<=8 Then Begin
  NumPal:=Word(BIH.biClrUsed);
  If NumPal=0 Then NumPal:=1 shl BIH.biBitCount;
  Seek(SourceBMP,14+SizeOf(BitmapInfoHeader));
  BlockRead(SourceBMP,Palette,LongInt(NumPal)*SizeOf(RGB32),ByteReaded);
 End Else NumPal:=0;

 StartPos:=Header.OffBits;
 NumEntries:=30;
 XResOffset:=8+2+LongInt(NumEntries)*12+4;
 YResOffset:=XResOffset+8;
 MakeOffset:=YResOffset+8;
 ModelOffset:=MakeOffset+Length(MakeText);
 SoftwareOffset:=ModelOffset+Length(ModelText);
 UniqueCameraOffset:=SoftwareOffset+Length(SoftwareText);
 DateTimeOffset:=UniqueCameraOffset+Length(UniqueCameraText);
 OriginalRawOffset:=DateTimeOffset+Length(DateTimeText);
 ColorMatrixOffset:=OriginalRawOffset+Length(OriginalRawText);
 AsShotNeutralOffset:=ColorMatrixOffset+72;
 DefaultScaleOffset:=AsShotNeutralOffset+24;
 DefaultCropOriginOffset:=DefaultScaleOffset+16;
 DefaultCropSizeOffset:=DefaultCropOriginOffset+16;
 StripOffset:=DefaultCropSizeOffset+16;
 StripByteCount:=LongInt(ImageWidth)*LongInt(ImageHeight)*2;

 {$I-}Assign(DestDNG,OutputName);
 Rewrite(DestDNG,1);{$I+}
 If IOResult<>0 Then Begin
  Close(SourceBMP);
  WriteLn('Impossible de creer le fichier ',OutputName);
  Halt;
 End;
 TargetOpened:=True;

 WriteWordToFile(TiffByteOrder);
 WriteWordToFile(TiffMagic);
 WriteLongToFile(8);

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
 WriteIFDEntry(TagDNGVersion,TiffTypeByte,4,LongInt($00000401));
 WriteIFDEntry(TagDNGBackwardVersion,TiffTypeByte,4,LongInt($00000101));
 WriteIFDEntry(TagUniqueCameraModel,TiffTypeASCII,Length(UniqueCameraText),UniqueCameraOffset);
 WriteIFDEntry(TagCFAPlaneColor,TiffTypeByte,3,LongInt($00020100));
 WriteIFDEntry(TagCFALayout,TiffTypeShort,1,1);
 WriteIFDEntry(TagBlackLevel,TiffTypeLong,1,0);
 WriteIFDEntry(TagWhiteLevel,TiffTypeLong,1,65535);
 WriteIFDEntry(TagDefaultScale,TiffTypeRational,2,DefaultScaleOffset);
 WriteIFDEntry(TagDefaultCropOrigin,TiffTypeRational,2,DefaultCropOriginOffset);
 WriteIFDEntry(TagDefaultCropSize,TiffTypeRational,2,DefaultCropSizeOffset);
 WriteIFDEntry(TagColorMatrix1,TiffTypeSRational,9,ColorMatrixOffset);
 WriteIFDEntry(TagAsShotNeutral,TiffTypeRational,3,AsShotNeutralOffset);
 WriteIFDEntry(TagCalibrationIlluminant1,TiffTypeShort,1,21);
 WriteIFDEntry(TagOriginalRawFileName,TiffTypeASCII,Length(OriginalRawText),OriginalRawOffset);
 WriteLongToFile(0);

 WriteRational(72,1);
 WriteRational(72,1);
 WriteStringData(MakeText);
 WriteStringData(ModelText);
 WriteStringData(SoftwareText);
 WriteStringData(UniqueCameraText);
 WriteStringData(DateTimeText);
 WriteStringData(OriginalRawText);
 WriteIdentityColorMatrix;
 WriteRational(1,1); WriteRational(1,1); WriteRational(1,1);
 WriteRational(1,1); WriteRational(1,1);
 WriteRational(0,1); WriteRational(0,1);
 WriteRational(LongInt(ImageWidth),1); WriteRational(LongInt(ImageHeight),1);

 For Y:=0 to ImageHeight-1 Do Begin
  If BIH.biHeight>0 Then SourceRow:=LongInt(ImageHeight)-1-Y
                    Else SourceRow:=Y;
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

 Close(DestDNG);
 TargetOpened:=False;
 Close(SourceBMP);
 WriteLn('Fichier DNG cree : ',OutputName);
END.
