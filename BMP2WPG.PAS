{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2WPG;

{$A-}

Uses DOS;

Const
  {Type de compression Windows}
 bi_RGB=0;
 bi_RLE8=1;
 bi_RLE4=2;

  {Largeur maximale supportee (en pixels).}
 MaxWidth=4096;

  {Constantes du format WPG (WordPerfect Graphics, version 1).
   Les valeurs multi-octets du flux WPG sont en big-endian.}
 WPGMagic0=$FF;
 WPGMagic1=$57;
 WPGMagic2=$50;
 WPGMagic3=$43;
 WPGProductType=1;
 WPGFileType=$16;
 WPGVersionMajor=1;
 WPGVersionMinor=0;

  {Types d'enregistrement utilises.}
 WPGRecStart=$0F;
 WPGRecEnd=$10;
 WPGRecColorMap=$0E;
 WPGRecBitmap1=$0B;

  {Maximum d'octets dans une course litterale RLE WPG.}
 MaxRunLen=127;

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
 SourceBMP,DestWPG:File;
 Header:HeaderBMP;
 BIH:BitMapInfoHeader;
 BMPBytesPerLine,ByteReaded,ByteWritten:Word;
 StartPos:LongInt;
 NumPal:Word;
 Palette:Array[0..255]of RGB32;
 BMPLine:Array[0..MaxWidth*3-1]of Byte;
 OutLine:Array[0..MaxWidth*3-1]of Byte;
 OutputName:String;
 ImageWidth,ImageHeight:Word;
 BMPBPL:LongInt;
 WPGBytesPerLine:Word;
 I:Integer;
 Y:LongInt;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.WPG';
End;

Procedure WriteWordBE(W:Word);
Var
 Buf:Array[0..1]of Byte;
Begin
 Buf[0]:=Byte((W shr 8)and $FF);
 Buf[1]:=Byte(W and $FF);
 BlockWrite(DestWPG,Buf,2,ByteWritten);
End;

Procedure WriteLongBE(L:LongInt);
Var
 Buf:Array[0..3]of Byte;
Begin
 Buf[0]:=Byte((L shr 24)and $FF);
 Buf[1]:=Byte((L shr 16)and $FF);
 Buf[2]:=Byte((L shr 8)and $FF);
 Buf[3]:=Byte(L and $FF);
 BlockWrite(DestWPG,Buf,4,ByteWritten);
End;

Procedure WriteByte(B:Byte);
Begin
 BlockWrite(DestWPG,B,1,ByteWritten);
End;

Procedure WriteRecLength(Len:LongInt);
Begin
 If Len<$FF Then WriteByte(Byte(Len))
 Else Begin
  WriteByte($FF);
  If Len<=$7FFF Then WriteWordBE(Word(Len))
  Else Begin
   WriteWordBE(Word($8000 or ((Len shr 16)and $7FFF)));
   WriteWordBE(Word(Len and $FFFF));
  End;
 End;
End;

Procedure ReadBmpRow(RowIndex:LongInt);
Begin
 Seek(SourceBMP,StartPos+RowIndex*LongInt(BMPBytesPerLine));
 BlockRead(SourceBMP,BMPLine,BMPBytesPerLine,ByteReaded);
End;

Procedure WriteScanlineRLE(Var Line; LineLen:Word);
Var
 P:^Byte;
 Remaining:Word;
 Chunk:Word;
 Buf:Byte;
Begin
 P:=@Line;
 Remaining:=LineLen;
 While Remaining>0 Do Begin
  If Remaining>MaxRunLen Then Chunk:=MaxRunLen
                         Else Chunk:=Remaining;
  Buf:=Byte(Chunk);
  BlockWrite(DestWPG,Buf,1,ByteWritten);
  BlockWrite(DestWPG,P^,Chunk,ByteWritten);
  Inc(P,Chunk);
  Dec(Remaining,Chunk);
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BMP2WPG : Cette commande permet de convertir une image BitMap (.BMP) ',
                    'en fichier WordPerfect Graphics (.WPG).');
  WriteLn;
  WriteLn('Syntaxe : BMP2WPG nomdufichier.BMP');
  WriteLn;
  WriteLn(' nomdufichier   Nom du fichier ".BMP" a convertir.');
  WriteLn;
  WriteLn('Le fichier resultant porte le meme nom avec l''extension .WPG.');
  WriteLn('Seuls les BitMaps 1, 4 ou 8 bits par pixel non compresses sont supportes.');
  Halt;
 End;
 If ParamCount<1 Then Begin
  WriteLn('Parametre requis !');
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
  WriteLn('Signature d''entete Bitmap introuvable !');
  Close(SourceBMP);
  Halt;
 End;
 Seek(SourceBMP,14);
 BlockRead(SourceBMP,BIH,SizeOf(BIH),ByteReaded);
 If(BIH.biBitCount<>1)and(BIH.biBitCount<>4)and(BIH.biBitCount<>8)Then Begin
  WriteLn('Seuls les BitMaps 1, 4 ou 8 bits par pixel sont supportes pour la conversion en WPG !');
  Close(SourceBMP);
  Halt(2);
 End;
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
 If LongInt(BIH.biWidth)>MaxWidth Then Begin
  WriteLn('Image trop large (largeur max : ',MaxWidth,') !');
  Close(SourceBMP);
  Halt;
 End;

 If BIH.biSizeImage=0 Then
  BMPBPL:=((LongInt(BIH.biWidth)*LongInt(BIH.biBitCount)+31)div 32)*4
 Else
  BMPBPL:=LongInt(BIH.biSizeImage)div Abs(LongInt(BIH.biHeight));
 If(BMPBPL<=0)or(BMPBPL>SizeOf(BMPLine))Then Begin
  WriteLn('Largeur de l''image trop grande !');
  Close(SourceBMP);
  Halt;
 End;
 BMPBytesPerLine:=Word(BMPBPL);
 ImageWidth:=Word(BIH.biWidth);
 ImageHeight:=Word(Abs(LongInt(BIH.biHeight)));
 WPGBytesPerLine:=Word((LongInt(ImageWidth)*LongInt(BIH.biBitCount)+7)div 8);

 If(BIH.biClrUsed>0)and(BIH.biClrUsed<=(LongInt(1)shl BIH.biBitCount))Then
  NumPal:=Word(BIH.biClrUsed)
 Else
  Case BIH.biBitCount of
   1:NumPal:=2;
   4:NumPal:=16;
   8:NumPal:=256;
  End;
 Seek(SourceBMP,14+SizeOf(BitmapInfoHeader));
 BlockRead(SourceBMP,Palette,LongInt(NumPal)*4,ByteReaded);
 If ByteReaded<>LongInt(NumPal)*4 Then Begin
  WriteLn('Palette BMP incomplete !');
  Close(SourceBMP);
  Halt;
 End;

 StartPos:=Header.OffBits;

 OutputName:=Path2NameExt(ParamStr(1));
 {$I-}Assign(DestWPG,OutputName);
 Rewrite(DestWPG,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de creer le fichier ',OutputName);
  Close(SourceBMP);
  Halt;
 End;

 WriteByte(WPGMagic0);
 WriteByte(WPGMagic1);
 WriteByte(WPGMagic2);
 WriteByte(WPGMagic3);
 WriteLongBE(16);
 WriteByte(WPGProductType);
 WriteByte(WPGFileType);
 WriteByte(WPGVersionMajor);
 WriteByte(WPGVersionMinor);
 WriteWordBE(0);
 WriteWordBE(0);

 WriteByte(WPGRecStart);
 WriteRecLength(6);
 WriteByte(1);
 WriteByte(0);
 WriteWordBE(Word(LongInt(ImageWidth)*8));
 WriteWordBE(Word(LongInt(ImageHeight)*8));

 WriteByte(WPGRecColorMap);
 WriteRecLength(LongInt(4)+LongInt(NumPal)*3);
 WriteWordBE(0);
 WriteWordBE(NumPal);
 For I:=0 to NumPal-1 Do Begin
  WriteByte(Palette[I].R);
  WriteByte(Palette[I].G);
  WriteByte(Palette[I].B);
 End;

 WriteByte(WPGRecBitmap1);
 WriteRecLength(LongInt(10)+
                (LongInt(WPGBytesPerLine)+
                 ((LongInt(WPGBytesPerLine)+MaxRunLen-1)div MaxRunLen))*
                LongInt(ImageHeight));
 WriteWordBE(ImageWidth);
 WriteWordBE(ImageHeight);
 WriteWordBE(BIH.biBitCount);
 WriteWordBE(150);
 WriteWordBE(150);
 For Y:=0 to ImageHeight-1 Do Begin
  If BIH.biHeight>0 Then
   ReadBmpRow(LongInt(ImageHeight)-1-Y)
  Else
   ReadBmpRow(Y);
  FillChar(OutLine,SizeOf(OutLine),0);
  For I:=0 to WPGBytesPerLine-1 Do OutLine[I]:=BMPLine[I];
  WriteScanlineRLE(OutLine,WPGBytesPerLine);
 End;

 WriteByte(WPGRecEnd);
 WriteRecLength(0);

 Close(SourceBMP);
 Close(DestWPG);
 WriteLn('Fichier WPG cree : ',OutputName);
END.
