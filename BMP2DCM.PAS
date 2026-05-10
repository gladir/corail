{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2DCM;

{$A-}

Uses DOS;

Const
 bi_RGB=0;
 MaxWidth=4096;

 SOPSecondaryCapture='1.2.840.10008.5.1.4.1.1.7';
 TransferExplicitVRLittleEndian='1.2.840.10008.1.2.1';
 ImplementationClassUID='1.2.826.0.1.3680043.10.543.1';
 UIDRoot='1.2.826.0.1.3680043.10.543.2.';

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
 SourceBMP,DestDCM:File;
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
 SOPInstanceUID,StudyInstanceUID,SeriesInstanceUID:String;
 StudyDate,StudyTime:String;
 GroupLengthValuePos,MetaStart,MetaEnd:LongInt;
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
 Path2NameExt:=D+N+'.DCM';
End;

Function AbsLong(Value:LongInt):LongInt;
Begin
 If Value<0 Then AbsLong:=-Value
            Else AbsLong:=Value;
End;

Function TrimLeftString(S:String):String;
Begin
 While(Length(S)>0)and(S[1]=' ')Do Delete(S,1,1);
 TrimLeftString:=S;
End;

Function LongToString(Value:LongInt):String;
Var
 S:String;
Begin
 Str(Value,S);
 LongToString:=TrimLeftString(S);
End;

Function Pad2(Value:Word):String;
Var
 S:String;
Begin
 S:=LongToString(Value);
 If Length(S)<2 Then S:='0'+S;
 Pad2:=S;
End;

Function Pad4(Value:Word):String;
Var
 S:String;
Begin
 S:=LongToString(Value);
 While Length(S)<4 Do S:='0'+S;
 Pad4:=S;
End;

Procedure InitDateTimeStrings;
Var
 YR,MO,DA,DOW:Word;
 HR,MI,SE,HS:Word;
Begin
 GetDate(YR,MO,DA,DOW);
 GetTime(HR,MI,SE,HS);
 StudyDate:=Pad4(YR)+Pad2(MO)+Pad2(DA);
 StudyTime:=Pad2(HR)+Pad2(MI)+Pad2(SE);
End;

Function BuildUID(Kind:Word):String;
Var
 Base:String;
 V:LongInt;
Begin
 V:=AbsLong(LongInt(FileSize(SourceBMP)))+LongInt(ImageWidth)*17+
  LongInt(ImageHeight)*31+LongInt(Kind)*101;
 Base:=UIDRoot+LongToString(V)+'.'+LongToString(Kind);
 If Length(Base)>63 Then Base:=Copy(Base,1,63);
 BuildUID:=Base;
End;

Procedure WriteError(Const S:String);
Begin
 WriteLn(S);
 Close(SourceBMP);
 If TargetOpened Then Close(DestDCM);
 Halt;
End;

Procedure WriteByteToFile(B:Byte);
Begin
 BlockWrite(DestDCM,B,1,ByteWritten);
End;

Procedure WriteWordLE(W:Word);
Var
 Tmp:Array[0..1]of Byte;
Begin
 Tmp[0]:=Byte(W and $FF);
 Tmp[1]:=Byte((W shr 8)and $FF);
 BlockWrite(DestDCM,Tmp,2,ByteWritten);
End;

Procedure WriteLongLE(L:LongInt);
Var
 Tmp:Array[0..3]of Byte;
Begin
 Tmp[0]:=Byte(L and $FF);
 Tmp[1]:=Byte((L shr 8)and $FF);
 Tmp[2]:=Byte((L shr 16)and $FF);
 Tmp[3]:=Byte((L shr 24)and $FF);
 BlockWrite(DestDCM,Tmp,4,ByteWritten);
End;

Procedure PatchLongLE(Pos,Value:LongInt);
Var
 Current:LongInt;
Begin
 Current:=FilePos(DestDCM);
 Seek(DestDCM,Pos);
 WriteLongLE(Value);
 Seek(DestDCM,Current);
End;

Procedure WriteChars(Const S:String);
Var
 I:Integer;
 C:Char;
Begin
 For I:=1 to Length(S)Do Begin
  C:=S[I];
  BlockWrite(DestDCM,C,1,ByteWritten);
 End;
End;

Procedure WriteTag(Group,Element:Word);
Begin
 WriteWordLE(Group);
 WriteWordLE(Element);
End;

Procedure WriteVR(Const VR:String);
Begin
 WriteChars(Copy(VR+'  ',1,2));
End;

Procedure WritePaddedString(Const S:String;Pad:Char);
Var
 I:Integer;
 C:Char;
Begin
 For I:=1 to Length(S)Do Begin
  C:=S[I];
  BlockWrite(DestDCM,C,1,ByteWritten);
 End;
 If Odd(Length(S))Then Begin
  C:=Pad;
  BlockWrite(DestDCM,C,1,ByteWritten);
 End;
End;

Procedure WriteElementString(Group,Element:Word;Const VR,Value:String);
Var
 L:Word;
 Pad:Char;
Begin
 If VR='UI' Then Pad:=#0 Else Pad:=' ';
 L:=Length(Value);
 If Odd(L)Then Inc(L);
 WriteTag(Group,Element);
 WriteVR(VR);
 WriteWordLE(L);
 WritePaddedString(Value,Pad);
End;

Procedure WriteElementUS(Group,Element:Word;Value:Word);
Begin
 WriteTag(Group,Element);
 WriteVR('US');
 WriteWordLE(2);
 WriteWordLE(Value);
End;

Procedure WriteElementUL(Group,Element:Word;Value:LongInt);
Begin
 WriteTag(Group,Element);
 WriteVR('UL');
 WriteWordLE(4);
 WriteLongLE(Value);
End;

Procedure WriteElementOB(Group,Element:Word;Var Data;Len:LongInt);
Begin
 WriteTag(Group,Element);
 WriteVR('OB');
 WriteWordLE(0);
 WriteLongLE(Len);
 If Len>0 Then BlockWrite(DestDCM,Data,Len,ByteWritten);
 If Odd(Len)Then WriteByteToFile(0);
End;

Procedure WriteElementPixelDataHeader(Len:LongInt);
Begin
 WriteTag($7FE0,$0010);
 WriteVR('OB');
 WriteWordLE(0);
 WriteLongLE(Len);
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

Procedure WritePreambleAndMeta;
Var
 I:Integer;
 Version:Array[0..1]of Byte;
Begin
 For I:=1 to 128 Do WriteByteToFile(0);
 WriteChars('DICM');

 Version[0]:=0;
 Version[1]:=1;
 WriteTag($0002,$0000);
 WriteVR('UL');
 WriteWordLE(4);
 GroupLengthValuePos:=FilePos(DestDCM);
 WriteLongLE(0);
 MetaStart:=FilePos(DestDCM);
 WriteElementOB($0002,$0001,Version,2);
 WriteElementString($0002,$0002,'UI',SOPSecondaryCapture);
 WriteElementString($0002,$0003,'UI',SOPInstanceUID);
 WriteElementString($0002,$0010,'UI',TransferExplicitVRLittleEndian);
 WriteElementString($0002,$0012,'UI',ImplementationClassUID);
 WriteElementString($0002,$0013,'SH','BMP2DCM');
 MetaEnd:=FilePos(DestDCM);
 PatchLongLE(GroupLengthValuePos,MetaEnd-MetaStart);
End;

Procedure WriteDataSet;
Var
 PixelLen:LongInt;
 PixelPad:Boolean;
Begin
 WriteElementString($0008,$0016,'UI',SOPSecondaryCapture);
 WriteElementString($0008,$0018,'UI',SOPInstanceUID);
 WriteElementString($0008,$0020,'DA',StudyDate);
 WriteElementString($0008,$0030,'TM',StudyTime);
 WriteElementString($0008,$0060,'CS','OT');
 WriteElementString($0008,$0064,'CS','WSD');
 WriteElementString($0008,$103E,'LO','CloneDRAW BMP conversion');
 WriteElementString($0010,$0010,'PN','BMP^CloneDRAW');
 WriteElementString($0010,$0020,'LO','BMP2DCM');
 WriteElementString($0020,$000D,'UI',StudyInstanceUID);
 WriteElementString($0020,$000E,'UI',SeriesInstanceUID);
 WriteElementString($0020,$0011,'IS','1');
 WriteElementString($0020,$0013,'IS','1');
 WriteElementUS($0028,$0002,3);
 WriteElementString($0028,$0004,'CS','RGB');
 WriteElementUS($0028,$0006,0);
 WriteElementUS($0028,$0010,ImageHeight);
 WriteElementUS($0028,$0011,ImageWidth);
 WriteElementUS($0028,$0100,8);
 WriteElementUS($0028,$0101,8);
 WriteElementUS($0028,$0102,7);
 WriteElementUS($0028,$0103,0);

 PixelLen:=LongInt(ImageWidth)*LongInt(ImageHeight)*3;
 PixelPad:=Odd(PixelLen);
 If PixelPad Then Inc(PixelLen);
 WriteElementPixelDataHeader(PixelLen);
End;

Procedure WritePixelData;
Var
 Zero:Byte;
Begin
 Zero:=0;
 For Y:=0 to ImageHeight-1 Do Begin
  If BIH.biHeight>0 Then SourceRow:=LongInt(ImageHeight)-1-Y
                    Else SourceRow:=Y;
  Seek(SourceBMP,StartPos+SourceRow*LongInt(BMPBytesPerLine));
  BlockRead(SourceBMP,BMPLine,BMPBytesPerLine,ByteReaded);
  For X:=0 to ImageWidth-1 Do Begin
   GetRGBPixel(X,R,G,B);
   WriteByteToFile(R);
   WriteByteToFile(G);
   WriteByteToFile(B);
  End;
 End;
 If Odd(LongInt(ImageWidth)*LongInt(ImageHeight)*3)Then
  BlockWrite(DestDCM,Zero,1,ByteWritten);
End;

Procedure ShowHelp;
Begin
 WriteLn('BMP2DCM : Cette commande permet de convertir une image BitMap (.BMP) ');
 WriteLn('          en fichier DICOM (.DCM) Secondary Capture.');
 WriteLn;
 WriteLn('Syntaxe : BMP2DCM source.BMP [destination.DCM]');
 WriteLn;
 WriteLn(' source.BMP      Ce parametre permet d''indiquer le nom du fichier ".BMP".');
 WriteLn(' destination.DCM Ce parametre permet d''indiquer le nom du fichier ".DCM".');
 WriteLn;
 WriteLn('Le fichier cree est un DICOM Part 10, Explicit VR Little Endian, RGB 8 bits');
 WriteLn('non compresse, SOP Class Secondary Capture Image Storage.');
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
 InitDateTimeStrings;
 SOPInstanceUID:=BuildUID(1);
 StudyInstanceUID:=BuildUID(2);
 SeriesInstanceUID:=BuildUID(3);

 {$I-}Assign(DestDCM,OutputName);
 Rewrite(DestDCM,1);{$I+}
 If IOResult<>0 Then Begin
  Close(SourceBMP);
  WriteLn('Impossible de creer le fichier ',OutputName);
  Halt;
 End;
 TargetOpened:=True;

 WritePreambleAndMeta;
 WriteDataSet;
 WritePixelData;

 Close(DestDCM);
 TargetOpened:=False;
 Close(SourceBMP);
 WriteLn('Fichier DCM cree : ',OutputName);
END.
