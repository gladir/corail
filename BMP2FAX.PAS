{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2FAX;

{$A-}

Uses DOS;

Const
 bi_RGB=0;
 MaxWidth=4096;
 EOLCode='000000000001';

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
 SourceBMP,DestFAX:File;
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
OutByte,OutBitCount:Byte;
Y,SourceRow:LongInt;
R,G,B:Byte;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.FAX';
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
 If TargetOpened Then Close(DestFAX);
 Halt;
End;

Procedure EmitOutputByte(B:Byte);
Begin
 BlockWrite(DestFAX,B,1,ByteWritten);
End;

Procedure WriteBit(BitValue:Byte);
Begin
 If(BitValue and 1)<>0 Then
  OutByte:=OutByte or(Byte(1)shl(7-OutBitCount));
 Inc(OutBitCount);
 If OutBitCount=8 Then Begin
  EmitOutputByte(OutByte);
  OutByte:=0;
  OutBitCount:=0;
 End;
End;

Procedure WriteCode(Const Code:String);
Var
 I:Integer;
Begin
 For I:=1 to Length(Code)Do
  If Code[I]='1'Then WriteBit(1)Else WriteBit(0);
End;

Procedure FlushBits;
Begin
 If OutBitCount<>0 Then Begin
  EmitOutputByte(OutByte);
  OutByte:=0;
  OutBitCount:=0;
 End;
End;

Function WhiteTerminatingCode(Run:Byte):String;
Begin
 Case Run of
  0:WhiteTerminatingCode:='00110101'; 1:WhiteTerminatingCode:='000111';
  2:WhiteTerminatingCode:='0111'; 3:WhiteTerminatingCode:='1000';
  4:WhiteTerminatingCode:='1011'; 5:WhiteTerminatingCode:='1100';
  6:WhiteTerminatingCode:='1110'; 7:WhiteTerminatingCode:='1111';
  8:WhiteTerminatingCode:='10011'; 9:WhiteTerminatingCode:='10100';
  10:WhiteTerminatingCode:='00111'; 11:WhiteTerminatingCode:='01000';
  12:WhiteTerminatingCode:='001000'; 13:WhiteTerminatingCode:='000011';
  14:WhiteTerminatingCode:='110100'; 15:WhiteTerminatingCode:='110101';
  16:WhiteTerminatingCode:='101010'; 17:WhiteTerminatingCode:='101011';
  18:WhiteTerminatingCode:='0100111'; 19:WhiteTerminatingCode:='0001100';
  20:WhiteTerminatingCode:='0001000'; 21:WhiteTerminatingCode:='0010111';
  22:WhiteTerminatingCode:='0000011'; 23:WhiteTerminatingCode:='0000100';
  24:WhiteTerminatingCode:='0101000'; 25:WhiteTerminatingCode:='0101011';
  26:WhiteTerminatingCode:='0010011'; 27:WhiteTerminatingCode:='0100100';
  28:WhiteTerminatingCode:='0011000'; 29:WhiteTerminatingCode:='00000010';
  30:WhiteTerminatingCode:='00000011'; 31:WhiteTerminatingCode:='00011010';
  32:WhiteTerminatingCode:='00011011'; 33:WhiteTerminatingCode:='00010010';
  34:WhiteTerminatingCode:='00010011'; 35:WhiteTerminatingCode:='00010100';
  36:WhiteTerminatingCode:='00010101'; 37:WhiteTerminatingCode:='00010110';
  38:WhiteTerminatingCode:='00010111'; 39:WhiteTerminatingCode:='00101000';
  40:WhiteTerminatingCode:='00101001'; 41:WhiteTerminatingCode:='00101010';
  42:WhiteTerminatingCode:='00101011'; 43:WhiteTerminatingCode:='00101100';
  44:WhiteTerminatingCode:='00101101'; 45:WhiteTerminatingCode:='00000100';
  46:WhiteTerminatingCode:='00000101'; 47:WhiteTerminatingCode:='00001010';
  48:WhiteTerminatingCode:='00001011'; 49:WhiteTerminatingCode:='01010010';
  50:WhiteTerminatingCode:='01010011'; 51:WhiteTerminatingCode:='01010100';
  52:WhiteTerminatingCode:='01010101'; 53:WhiteTerminatingCode:='00100100';
  54:WhiteTerminatingCode:='00100101'; 55:WhiteTerminatingCode:='01011000';
  56:WhiteTerminatingCode:='01011001'; 57:WhiteTerminatingCode:='01011010';
  58:WhiteTerminatingCode:='01011011'; 59:WhiteTerminatingCode:='01001010';
  60:WhiteTerminatingCode:='01001011'; 61:WhiteTerminatingCode:='00110010';
  62:WhiteTerminatingCode:='00110011'; Else WhiteTerminatingCode:='00110100';
 End;
End;

Function BlackTerminatingCode(Run:Byte):String;
Begin
 Case Run of
  0:BlackTerminatingCode:='0000110111'; 1:BlackTerminatingCode:='010';
  2:BlackTerminatingCode:='11'; 3:BlackTerminatingCode:='10';
  4:BlackTerminatingCode:='011'; 5:BlackTerminatingCode:='0011';
  6:BlackTerminatingCode:='0010'; 7:BlackTerminatingCode:='00011';
  8:BlackTerminatingCode:='000101'; 9:BlackTerminatingCode:='000100';
  10:BlackTerminatingCode:='0000100'; 11:BlackTerminatingCode:='0000101';
  12:BlackTerminatingCode:='0000111'; 13:BlackTerminatingCode:='00000100';
  14:BlackTerminatingCode:='00000111'; 15:BlackTerminatingCode:='000011000';
  16:BlackTerminatingCode:='0000010111'; 17:BlackTerminatingCode:='0000011000';
  18:BlackTerminatingCode:='0000001000'; 19:BlackTerminatingCode:='00001100111';
  20:BlackTerminatingCode:='00001101000'; 21:BlackTerminatingCode:='00001101100';
  22:BlackTerminatingCode:='00000110111'; 23:BlackTerminatingCode:='00000101000';
  24:BlackTerminatingCode:='00000010111'; 25:BlackTerminatingCode:='00000011000';
  26:BlackTerminatingCode:='000011001010'; 27:BlackTerminatingCode:='000011001011';
  28:BlackTerminatingCode:='000011001100'; 29:BlackTerminatingCode:='000011001101';
  30:BlackTerminatingCode:='000001101000'; 31:BlackTerminatingCode:='000001101001';
  32:BlackTerminatingCode:='000001101010'; 33:BlackTerminatingCode:='000001101011';
  34:BlackTerminatingCode:='000011010010'; 35:BlackTerminatingCode:='000011010011';
  36:BlackTerminatingCode:='000011010100'; 37:BlackTerminatingCode:='000011010101';
  38:BlackTerminatingCode:='000011010110'; 39:BlackTerminatingCode:='000011010111';
  40:BlackTerminatingCode:='000001101100'; 41:BlackTerminatingCode:='000001101101';
  42:BlackTerminatingCode:='000011011010'; 43:BlackTerminatingCode:='000011011011';
  44:BlackTerminatingCode:='000001010100'; 45:BlackTerminatingCode:='000001010101';
  46:BlackTerminatingCode:='000001010110'; 47:BlackTerminatingCode:='000001010111';
  48:BlackTerminatingCode:='000001100100'; 49:BlackTerminatingCode:='000001100101';
  50:BlackTerminatingCode:='000001010010'; 51:BlackTerminatingCode:='000001010011';
  52:BlackTerminatingCode:='000000100100'; 53:BlackTerminatingCode:='000000110111';
  54:BlackTerminatingCode:='000000111000'; 55:BlackTerminatingCode:='000000100111';
  56:BlackTerminatingCode:='000000101000'; 57:BlackTerminatingCode:='000001011000';
  58:BlackTerminatingCode:='000001011001'; 59:BlackTerminatingCode:='000000101011';
  60:BlackTerminatingCode:='000000101100'; 61:BlackTerminatingCode:='000001011010';
  62:BlackTerminatingCode:='000001100110'; Else BlackTerminatingCode:='000001100111';
 End;
End;

Function MakeupCode(Run:Word;Black:Boolean):String;
Begin
 Case Run of
  64:If Black Then MakeupCode:='0000001111'Else MakeupCode:='11011';
  128:If Black Then MakeupCode:='000011001000'Else MakeupCode:='10010';
  192:If Black Then MakeupCode:='000011001001'Else MakeupCode:='010111';
  256:If Black Then MakeupCode:='000001011011'Else MakeupCode:='0110111';
  320:If Black Then MakeupCode:='000000110011'Else MakeupCode:='00110110';
  384:If Black Then MakeupCode:='000000110100'Else MakeupCode:='00110111';
  448:If Black Then MakeupCode:='000000110101'Else MakeupCode:='01100100';
  512:If Black Then MakeupCode:='0000001101100'Else MakeupCode:='01100101';
  576:If Black Then MakeupCode:='0000001101101'Else MakeupCode:='01101000';
  640:If Black Then MakeupCode:='0000001001010'Else MakeupCode:='01100111';
  704:If Black Then MakeupCode:='0000001001011'Else MakeupCode:='011001100';
  768:If Black Then MakeupCode:='0000001001100'Else MakeupCode:='011001101';
  832:If Black Then MakeupCode:='0000001001101'Else MakeupCode:='011010010';
  896:If Black Then MakeupCode:='0000001110010'Else MakeupCode:='011010011';
  960:If Black Then MakeupCode:='0000001110011'Else MakeupCode:='011010100';
  1024:If Black Then MakeupCode:='0000001110100'Else MakeupCode:='011010101';
  1088:If Black Then MakeupCode:='0000001110101'Else MakeupCode:='011010110';
  1152:If Black Then MakeupCode:='0000001110110'Else MakeupCode:='011010111';
  1216:If Black Then MakeupCode:='0000001110111'Else MakeupCode:='011011000';
  1280:If Black Then MakeupCode:='0000001010010'Else MakeupCode:='011011001';
  1344:If Black Then MakeupCode:='0000001010011'Else MakeupCode:='011011010';
  1408:If Black Then MakeupCode:='0000001010100'Else MakeupCode:='011011011';
  1472:If Black Then MakeupCode:='0000001010101'Else MakeupCode:='010011000';
  1536:If Black Then MakeupCode:='0000001011010'Else MakeupCode:='010011001';
  1600:If Black Then MakeupCode:='0000001011011'Else MakeupCode:='010011010';
  1664:If Black Then MakeupCode:='0000001100100'Else MakeupCode:='011000';
  1728:If Black Then MakeupCode:='0000001100101'Else MakeupCode:='010011011';
  1792:MakeupCode:='00000001000'; 1856:MakeupCode:='00000001100';
  1920:MakeupCode:='00000001101'; 1984:MakeupCode:='000000010010';
  2048:MakeupCode:='000000010011'; 2112:MakeupCode:='000000010100';
  2176:MakeupCode:='000000010101'; 2240:MakeupCode:='000000010110';
  2304:MakeupCode:='000000010111'; 2368:MakeupCode:='000000011100';
  2432:MakeupCode:='000000011101'; 2496:MakeupCode:='000000011110';
  Else MakeupCode:='000000011111';
 End;
End;

Procedure WriteRun(Run:Word;Black:Boolean);
Var
 Makeup:Word;
Begin
 While Run>=2560 Do Begin
  WriteCode(MakeupCode(2560,Black));
  Dec(Run,2560);
 End;
 If Run>=64 Then Begin
  Makeup:=(Run div 64)*64;
  WriteCode(MakeupCode(Makeup,Black));
  Run:=Run mod 64;
 End;
 If Black Then WriteCode(BlackTerminatingCode(Byte(Run)))
          Else WriteCode(WhiteTerminatingCode(Byte(Run)));
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

Function PixelIsBlack(X:Word):Boolean;
Var
 Luma:LongInt;
Begin
 GetRGBPixel(X,R,G,B);
 Luma:=LongInt(R)*299+LongInt(G)*587+LongInt(B)*114;
 PixelIsBlack:=Luma<128000;
End;

Procedure EncodeCurrentLine;
Var
 CurrentBlack,NewBlack:Boolean;
 Run:Word;
 Pos:Word;
Begin
 WriteCode(EOLCode);
 CurrentBlack:=False; {Chaque ligne G3 commence par une course blanche.}
 Run:=0;
 For Pos:=0 to ImageWidth-1 Do Begin
  NewBlack:=PixelIsBlack(Pos);
  If NewBlack=CurrentBlack Then Inc(Run)
  Else Begin
   WriteRun(Run,CurrentBlack);
   CurrentBlack:=NewBlack;
   Run:=1;
  End;
 End;
 WriteRun(Run,CurrentBlack);
End;

Procedure EncodeFaxData;
Var
 I:Byte;
Begin
 For Y:=0 to ImageHeight-1 Do Begin
  If BIH.biHeight>0 Then SourceRow:=LongInt(ImageHeight)-1-Y
                    Else SourceRow:=Y;
  Seek(SourceBMP,StartPos+SourceRow*LongInt(BMPBytesPerLine));
  BlockRead(SourceBMP,BMPLine,BMPBytesPerLine,ByteReaded);
  EncodeCurrentLine;
 End;
 {RTC : six EOL consecutifs pour terminer le flux Group 3 1D.}
 For I:=1 to 6 Do WriteCode(EOLCode);
 FlushBits;
End;

Procedure ShowHelp;
Begin
 WriteLn('BMP2FAX : Cette commande permet de convertir une image BitMap (.BMP) ');
 WriteLn('          en fichier Group 3 FAX brut (.FAX).');
 WriteLn;
 WriteLn('Syntaxe : BMP2FAX source.BMP [destination.FAX]');
 WriteLn;
 WriteLn(' source.BMP      Ce parametre permet d''indiquer le nom du fichier ".BMP".');
 WriteLn(' destination.FAX Ce parametre permet d''indiquer le nom du fichier ".FAX".');
 WriteLn;
 WriteLn('Le fichier cree est un flux CCITT T.4 Group 3 1D Modified Huffman brut,');
 WriteLn('noir/blanc par seuil de luminance, avec EOL par ligne et RTC final.');
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

 {$I-}Assign(DestFAX,OutputName);
 Rewrite(DestFAX,1);{$I+}
 If IOResult<>0 Then Begin
  Close(SourceBMP);
  WriteLn('Impossible de creer le fichier ',OutputName);
  Halt;
 End;
 TargetOpened:=True;
 OutByte:=0;
 OutBitCount:=0;

 EncodeFaxData;

 Close(DestFAX);
 TargetOpened:=False;
 Close(SourceBMP);
 WriteLn('Fichier FAX cree : ',OutputName);
END.
