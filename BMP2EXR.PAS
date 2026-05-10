{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2EXR;

{$A-}

Uses DOS;

Const
 bi_RGB=0;
 MaxWidth=4096;
 EXRMagic=$01312F76;
 EXRVersion=2;
 EXRNoCompression=0;
 EXRIncreasingY=0;
 EXRPixelHalf=1;

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
 SourceBMP,DestEXR:File;
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
 HeaderEnd,OffsetTableStart,PixelDataStart:LongInt;
 ChunkDataSize,ChunkSize:LongInt;
 Y,SourceRow:LongInt;
 X:Word;
 R,G,B:Byte;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.EXR';
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
 If TargetOpened Then Close(DestEXR);
 Halt;
End;

Procedure WriteByteToFile(B:Byte);
Begin
 BlockWrite(DestEXR,B,1,ByteWritten);
End;

Procedure WriteWordLE(W:Word);
Var
 Tmp:Array[0..1]of Byte;
Begin
 Tmp[0]:=Byte(W and $FF);
 Tmp[1]:=Byte((W shr 8)and $FF);
 BlockWrite(DestEXR,Tmp,2,ByteWritten);
End;

Procedure WriteLongLE(L:LongInt);
Var
 Tmp:Array[0..3]of Byte;
Begin
 Tmp[0]:=Byte(L and $FF);
 Tmp[1]:=Byte((L shr 8)and $FF);
 Tmp[2]:=Byte((L shr 16)and $FF);
 Tmp[3]:=Byte((L shr 24)and $FF);
 BlockWrite(DestEXR,Tmp,4,ByteWritten);
End;

Procedure WriteInt64LE(Value:LongInt);
Begin
 WriteLongLE(Value);
 WriteLongLE(0);
End;

Procedure WriteChars(Const S:String);
Var
 I:Integer;
 C:Char;
Begin
 For I:=1 to Length(S)Do Begin
  C:=S[I];
  BlockWrite(DestEXR,C,1,ByteWritten);
 End;
End;

Procedure WriteCString(Const S:String);
Begin
 WriteChars(S);
 WriteByteToFile(0);
End;

Procedure WriteFloat32Zero;
Begin
 WriteLongLE(0);
End;

Procedure WriteFloat32One;
Begin
 WriteLongLE($3F800000);
End;

Procedure WriteAttributeHeader(Const Name,AttrType:String;Size:LongInt);
Begin
 WriteCString(Name);
 WriteCString(AttrType);
 WriteLongLE(Size);
End;

Procedure WriteChannel(Const Name:String);
Begin
 WriteCString(Name);
 WriteLongLE(EXRPixelHalf);
 WriteByteToFile(0); {pLinear}
 WriteByteToFile(0);
 WriteByteToFile(0);
 WriteByteToFile(0);
 WriteLongLE(1); {xSampling}
 WriteLongLE(1); {ySampling}
End;

Procedure WriteEXRHeader;
Begin
 WriteLongLE(EXRMagic);
 WriteLongLE(EXRVersion);

 WriteAttributeHeader('channels','chlist',55);
 WriteChannel('B');
 WriteChannel('G');
 WriteChannel('R');
 WriteByteToFile(0);

 WriteAttributeHeader('compression','compression',1);
 WriteByteToFile(EXRNoCompression);

 WriteAttributeHeader('dataWindow','box2i',16);
 WriteLongLE(0);
 WriteLongLE(0);
 WriteLongLE(LongInt(ImageWidth)-1);
 WriteLongLE(LongInt(ImageHeight)-1);

 WriteAttributeHeader('displayWindow','box2i',16);
 WriteLongLE(0);
 WriteLongLE(0);
 WriteLongLE(LongInt(ImageWidth)-1);
 WriteLongLE(LongInt(ImageHeight)-1);

 WriteAttributeHeader('lineOrder','lineOrder',1);
 WriteByteToFile(EXRIncreasingY);

 WriteAttributeHeader('pixelAspectRatio','float',4);
 WriteFloat32One;

 WriteAttributeHeader('screenWindowCenter','v2f',8);
 WriteFloat32Zero;
 WriteFloat32Zero;

 WriteAttributeHeader('screenWindowWidth','float',4);
 WriteFloat32One;

 WriteByteToFile(0); {fin de l'en-tete}
End;

Function ByteToHalf(Value:Byte):Word;
Var
 X:Real;
 Exp:Integer;
 Mant:LongInt;
Begin
 If Value=0 Then Begin
  ByteToHalf:=0;
  Exit;
 End;
 X:=Value/255.0;
 Exp:=0;
 While X<1.0 Do Begin
  X:=X*2.0;
  Dec(Exp);
 End;
 While X>=2.0 Do Begin
  X:=X/2.0;
  Inc(Exp);
 End;
 Mant:=Round((X-1.0)*1024.0);
 If Mant>=1024 Then Begin
  Mant:=0;
  Inc(Exp);
 End;
 ByteToHalf:=Word(((Exp+15)shl 10)or(Mant and 1023));
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

Procedure WriteOffsetTable;
Var
 Offset:LongInt;
 I:LongInt;
Begin
 Offset:=PixelDataStart;
 For I:=0 to ImageHeight-1 Do Begin
  WriteInt64LE(Offset);
  Inc(Offset,ChunkSize);
 End;
End;

Procedure WriteHalfPlane(Channel:Char);
Begin
 For X:=0 to ImageWidth-1 Do Begin
  GetRGBPixel(X,R,G,B);
  Case Channel of
   'B':WriteWordLE(ByteToHalf(B));
   'G':WriteWordLE(ByteToHalf(G));
   Else WriteWordLE(ByteToHalf(R));
  End;
 End;
End;

Procedure WritePixelChunks;
Begin
 For Y:=0 to ImageHeight-1 Do Begin
  If BIH.biHeight>0 Then SourceRow:=LongInt(ImageHeight)-1-Y
                    Else SourceRow:=Y;
  Seek(SourceBMP,StartPos+SourceRow*LongInt(BMPBytesPerLine));
  BlockRead(SourceBMP,BMPLine,BMPBytesPerLine,ByteReaded);
  WriteLongLE(Y);
  WriteLongLE(ChunkDataSize);
  WriteHalfPlane('B');
  WriteHalfPlane('G');
  WriteHalfPlane('R');
 End;
End;

Procedure ShowHelp;
Begin
 WriteLn('BMP2EXR : Cette commande permet de convertir une image BitMap (.BMP) ');
 WriteLn('          en fichier OpenEXR (.EXR).');
 WriteLn;
 WriteLn('Syntaxe : BMP2EXR source.BMP [destination.EXR]');
 WriteLn;
 WriteLn(' source.BMP      Ce parametre permet d''indiquer le nom du fichier ".BMP".');
 WriteLn(' destination.EXR Ce parametre permet d''indiquer le nom du fichier ".EXR".');
 WriteLn;
 WriteLn('Le fichier cree est un OpenEXR scanline non compresse, canaux B/G/R');
 WriteLn('en half-float 16 bits, sans compression ZIP/PIZ/DWA.');
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
 ChunkDataSize:=LongInt(ImageWidth)*3*2;
 ChunkSize:=8+ChunkDataSize;

 {$I-}Assign(DestEXR,OutputName);
 Rewrite(DestEXR,1);{$I+}
 If IOResult<>0 Then Begin
  Close(SourceBMP);
  WriteLn('Impossible de creer le fichier ',OutputName);
  Halt;
 End;
 TargetOpened:=True;

 WriteEXRHeader;
 HeaderEnd:=FilePos(DestEXR);
 OffsetTableStart:=HeaderEnd;
 PixelDataStart:=OffsetTableStart+LongInt(ImageHeight)*8;
 WriteOffsetTable;
 WritePixelChunks;

 Close(DestEXR);
 TargetOpened:=False;
 Close(SourceBMP);
 WriteLn('Fichier EXR cree : ',OutputName);
END.
