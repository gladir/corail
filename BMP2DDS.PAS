{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2DDS;

{$A-}

Uses DOS;

Const
 bi_RGB=0;
 MaxWidth=4096;

 DDSD_CAPS=$00000001;
 DDSD_HEIGHT=$00000002;
 DDSD_WIDTH=$00000004;
 DDSD_PITCH=$00000008;
 DDSD_PIXELFORMAT=$00001000;
 DDSCAPS_TEXTURE=$00001000;
 DDPF_ALPHAPIXELS=$00000001;
 DDPF_RGB=$00000040;

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
 SourceBMP,DestDDS:File;
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
 Y,SourceRow:LongInt;
 X:Word;
 R,G,B,A:Byte;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.DDS';
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
 If TargetOpened Then Close(DestDDS);
 Halt;
End;

Procedure WriteByteToFile(B:Byte);
Begin
 BlockWrite(DestDDS,B,1,ByteWritten);
End;

Procedure WriteWordLE(W:Word);
Var
 Tmp:Array[0..1]of Byte;
Begin
 Tmp[0]:=Byte(W and $FF);
 Tmp[1]:=Byte((W shr 8)and $FF);
 BlockWrite(DestDDS,Tmp,2,ByteWritten);
End;

Procedure WriteLongLE(L:LongInt);
Var
 Tmp:Array[0..3]of Byte;
Begin
 Tmp[0]:=Byte(L and $FF);
 Tmp[1]:=Byte((L shr 8)and $FF);
 Tmp[2]:=Byte((L shr 16)and $FF);
 Tmp[3]:=Byte((L shr 24)and $FF);
 BlockWrite(DestDDS,Tmp,4,ByteWritten);
End;

Procedure WriteChars(Const S:String);
Var
 I:Integer;
 C:Char;
Begin
 For I:=1 to Length(S)Do Begin
  C:=S[I];
  BlockWrite(DestDDS,C,1,ByteWritten);
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

Procedure GetRGBPixel(X:Word;Var Red,Green,Blue,Alpha:Byte);
Var
 Index:Byte;
 W:Word;
Begin
 Alpha:=255;
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
   Alpha:=BMPLine[X*4+3];
  End;
  Else Begin Red:=0; Green:=0; Blue:=0; Alpha:=255; End;
 End;
End;

Procedure WriteDDSHeader;
Var
 I:Integer;
Begin
 WriteChars('DDS ');
 WriteLongLE(124); {dwSize}
 WriteLongLE(DDSD_CAPS or DDSD_HEIGHT or DDSD_WIDTH or DDSD_PITCH or
  DDSD_PIXELFORMAT);
 WriteLongLE(LongInt(ImageHeight));
 WriteLongLE(LongInt(ImageWidth));
 WriteLongLE(LongInt(ImageWidth)*4); {pitch}
 WriteLongLE(0); {depth}
 WriteLongLE(0); {mipmaps}
 For I:=1 to 11 Do WriteLongLE(0); {reserved}

 WriteLongLE(32); {DDS_PIXELFORMAT.dwSize}
 WriteLongLE(DDPF_RGB or DDPF_ALPHAPIXELS);
 WriteLongLE(0); {fourcc}
 WriteLongLE(32); {RGB bits}
 WriteLongLE($00FF0000); {R mask}
 WriteLongLE($0000FF00); {G mask}
 WriteLongLE($000000FF); {B mask}
 WriteLongLE(LongInt($FF000000)); {A mask}

 WriteLongLE(DDSCAPS_TEXTURE);
 WriteLongLE(0);
 WriteLongLE(0);
 WriteLongLE(0);
 WriteLongLE(0);
End;

Procedure WritePixelData;
Begin
 For Y:=0 to ImageHeight-1 Do Begin
  If BIH.biHeight>0 Then SourceRow:=LongInt(ImageHeight)-1-Y
                    Else SourceRow:=Y;
  Seek(SourceBMP,StartPos+SourceRow*LongInt(BMPBytesPerLine));
  BlockRead(SourceBMP,BMPLine,BMPBytesPerLine,ByteReaded);
  For X:=0 to ImageWidth-1 Do Begin
   GetRGBPixel(X,R,G,B,A);
   WriteByteToFile(B);
   WriteByteToFile(G);
   WriteByteToFile(R);
   WriteByteToFile(A);
  End;
 End;
End;

Procedure ShowHelp;
Begin
 WriteLn('BMP2DDS : Cette commande permet de convertir une image BitMap (.BMP) ');
 WriteLn('          en fichier DirectDraw Surface (.DDS).');
 WriteLn;
 WriteLn('Syntaxe : BMP2DDS source.BMP [destination.DDS]');
 WriteLn;
 WriteLn(' source.BMP      Ce parametre permet d''indiquer le nom du fichier ".BMP".');
 WriteLn(' destination.DDS Ce parametre permet d''indiquer le nom du fichier ".DDS".');
 WriteLn;
 WriteLn('Le fichier cree est un DDS non compresse A8R8G8B8 32 bits, sans mipmaps.');
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

 {$I-}Assign(DestDDS,OutputName);
 Rewrite(DestDDS,1);{$I+}
 If IOResult<>0 Then Begin
  Close(SourceBMP);
  WriteLn('Impossible de creer le fichier ',OutputName);
  Halt;
 End;
 TargetOpened:=True;

 WriteDDSHeader;
 WritePixelData;

 Close(DestDDS);
 TargetOpened:=False;
 Close(SourceBMP);
 WriteLn('Fichier DDS cree : ',OutputName);
END.
