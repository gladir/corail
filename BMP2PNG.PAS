{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2PNG;

{$A-}

Uses DOS;

Const
  {Type de compression Windows}
 bi_RGB=0;
 bi_RLE8=1;
 bi_RLE4=2;

  {Largeur maximale support�e (en pixels).}
 MaxWidth=4096;

  {Signature PNG : 8 octets fixes (137,80,78,71,13,10,26,10).}
 PNGSignature:Array[0..7]of Byte=(137,80,78,71,13,10,26,10);

  {Taille maximale d'un bloc deflate "stored" (BTYPE=00) : 65535 octets.}
 MaxStoredBlock=65535;

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
 SourceBMP,DestPNG:File;
 Header:HeaderBMP;
 BIH:BitMapInfoHeader;
 BMPBytesPerLine,ByteReaded,ByteWritten:Word;
 StartPos:LongInt;
 NumPal:Word;
 Palette:Array[0..255]of RGB32;
 BMPLine:Array[0..MaxWidth*3-1]of Byte;     { Ligne brute lue dans le BMP }
 RowBuf:Array[0..MaxWidth*3]of Byte;        { Filtre (1) + RGB (W*3) }
 OutputName:String;
 ImageWidth,ImageHeight:Word;
 BMPBPL:LongInt;
 Y:LongInt;
 SourceRow:LongInt;
 X:Word;
 PalIdx:Byte;
 ByteV:Byte;
 CRCTable:Array[0..255]of LongInt;
 Adler_A,Adler_B:LongInt;
 IDATCRC,IDATRemaining,IDATBlockRemain:LongInt;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.PNG';
End;

  {Initialise la table de CRC-32 (polyn�me 0xEDB88320), utilis�e pour
   chaque "chunk" PNG.}
Procedure InitCRCTable;
Var
 N,K:Integer;
 C:LongInt;
Begin
 For N:=0 to 255 Do Begin
  C:=N;
  For K:=0 to 7 Do Begin
   If(C and 1)<>0 Then C:=LongInt($EDB88320)xor(LongInt(C shr 1)and LongInt($7FFFFFFF))
                  Else C:=LongInt(C shr 1)and LongInt($7FFFFFFF);
  End;
  CRCTable[N]:=C;
 End;
End;

  {Met � jour un CRC-32 pour un tableau d'octets. Le CRC initial doit
   �tre $FFFFFFFF et le r�sultat final est invers� par XOR avec
   $FFFFFFFF (voir FinishCRC).}
Function UpdateCRC(CRC:LongInt;Const Buf;Len:LongInt):LongInt;
Var
 P:^Byte;
 I:LongInt;
 Idx:Byte;
Begin
 P:=@Buf;
 For I:=0 to Len-1 Do Begin
  Idx:=Byte((CRC xor LongInt(P^))and $FF);
  CRC:=CRCTable[Idx]xor(LongInt(CRC shr 8)and LongInt($00FFFFFF));
  Inc(P);
 End;
 UpdateCRC:=CRC;
End;

Function StartCRC:LongInt;
Begin
 StartCRC:=LongInt($FFFFFFFF);
End;

Function FinishCRC(CRC:LongInt):LongInt;
Begin
 FinishCRC:=CRC xor LongInt($FFFFFFFF);
End;

  {�crit un mot 32 bits "gros-boutien" (octet de poids fort en premier)
   tel qu'utilis� par PNG pour les longueurs, CRC, dimensions, etc.}
Procedure WriteBE32(Value:LongInt);
Var
 B:Array[0..3]of Byte;
Begin
 B[0]:=Byte((Value shr 24)and $FF);
 B[1]:=Byte((Value shr 16)and $FF);
 B[2]:=Byte((Value shr  8)and $FF);
 B[3]:=Byte( Value         and $FF);
 BlockWrite(DestPNG,B,4,ByteWritten);
End;

  {�crit un "chunk" PNG complet : longueur (BE32), type (4 octets ASCII),
   donn�es, CRC-32 calcul� sur le type concat�n� aux donn�es.}
Procedure WriteData(Const Data;Len:LongInt);
Var
 P:^Byte;
 Chunk:Word;
Begin
 P:=@Data;
 While Len>0 Do Begin
  If Len>32768 Then Chunk:=32768 Else Chunk:=Word(Len);
  BlockWrite(DestPNG,P^,Chunk,ByteWritten);
  If ByteWritten<>Chunk Then Begin
   WriteLn('Erreur d''ecriture du fichier PNG !');
   Close(DestPNG);
   Close(SourceBMP);
   Halt;
  End;
  Inc(P,Chunk);
  Dec(Len,Chunk);
 End;
End;

Procedure WriteChunk(Const ChunkType:Array of Char;Const Data;Len:LongInt);
Var
 TypeBuf:Array[0..3]of Byte;
 CRC:LongInt;
Begin
 TypeBuf[0]:=Byte(ChunkType[0]);
 TypeBuf[1]:=Byte(ChunkType[1]);
 TypeBuf[2]:=Byte(ChunkType[2]);
 TypeBuf[3]:=Byte(ChunkType[3]);
 WriteBE32(Len);
 BlockWrite(DestPNG,TypeBuf,4,ByteWritten);
 If Len>0 Then WriteData(Data,Len);
 CRC:=StartCRC;
 CRC:=UpdateCRC(CRC,TypeBuf,4);
 If Len>0 Then CRC:=UpdateCRC(CRC,Data,Len);
 CRC:=FinishCRC(CRC);
 WriteBE32(CRC);
End;

  {Met � jour un Adler-32 (utilis� en queue d'un flux zlib) pour un
   tableau d'octets. La somme est conserv�e dans Adler_A et Adler_B
   (modulo 65521) et combin�e en LongInt par GetAdler32.}
Procedure UpdateAdler(Const Buf;Len:LongInt);
Var
 P:^Byte;
 I:LongInt;
Begin
 P:=@Buf;
 For I:=0 to Len-1 Do Begin
  Adler_A:=(Adler_A+LongInt(P^))mod 65521;
  Adler_B:=(Adler_B+Adler_A)mod 65521;
  Inc(P);
 End;
End;

Function GetAdler32:LongInt;
Begin
 GetAdler32:=(LongInt(Adler_B)shl 16)or LongInt(Adler_A);
End;

Procedure WriteIDATData(Const Data;Len:LongInt);
Begin
 If Len<=0 Then Exit;
 WriteData(Data,Len);
 IDATCRC:=UpdateCRC(IDATCRC,Data,Len);
End;

Procedure WriteIDATByte(B:Byte);
Begin
 WriteIDATData(B,1);
End;

Procedure WriteIDATStoredHeader(BlockLen:LongInt;IsLast:Byte);
Var
 B:Byte;
Begin
 B:=IsLast;
 WriteIDATByte(B);
 B:=Byte(BlockLen and $FF);
 WriteIDATByte(B);
 B:=Byte((BlockLen shr 8)and $FF);
 WriteIDATByte(B);
 B:=Byte((not BlockLen)and $FF);
 WriteIDATByte(B);
 B:=Byte(((not BlockLen)shr 8)and $FF);
 WriteIDATByte(B);
End;

Procedure BeginIDAT(TotalRaw:LongInt);
Var
 TypeBuf:Array[0..3]of Byte;
 NumBlocks,IDATLen:LongInt;
 B:Byte;
Begin
 If TotalRaw=0 Then NumBlocks:=1
               Else NumBlocks:=(TotalRaw+MaxStoredBlock-1)div MaxStoredBlock;
 IDATLen:=2+TotalRaw+NumBlocks*5+4;
 WriteBE32(IDATLen);
 TypeBuf[0]:=Ord('I');
 TypeBuf[1]:=Ord('D');
 TypeBuf[2]:=Ord('A');
 TypeBuf[3]:=Ord('T');
 BlockWrite(DestPNG,TypeBuf,4,ByteWritten);
 IDATCRC:=StartCRC;
 IDATCRC:=UpdateCRC(IDATCRC,TypeBuf,4);
 B:=$78;
 WriteIDATByte(B);
 B:=$01;
 WriteIDATByte(B);
 Adler_A:=1;
 Adler_B:=0;
 IDATRemaining:=TotalRaw;
 IDATBlockRemain:=0;
 If TotalRaw=0 Then WriteIDATStoredHeader(0,1);
End;

Procedure WriteIDATRaw(Const Data;Len:LongInt);
Var
 P:^Byte;
 Chunk,BlockLen:LongInt;
 IsLast:Byte;
Begin
 P:=@Data;
 While Len>0 Do Begin
  If IDATBlockRemain=0 Then Begin
   If IDATRemaining>MaxStoredBlock Then BlockLen:=MaxStoredBlock
                                  Else BlockLen:=IDATRemaining;
   If BlockLen=IDATRemaining Then IsLast:=1 Else IsLast:=0;
   WriteIDATStoredHeader(BlockLen,IsLast);
   IDATBlockRemain:=BlockLen;
  End;
  If Len>IDATBlockRemain Then Chunk:=IDATBlockRemain Else Chunk:=Len;
  WriteIDATData(P^,Chunk);
  UpdateAdler(P^,Chunk);
  Inc(P,Chunk);
  Dec(Len,Chunk);
  Dec(IDATRemaining,Chunk);
  Dec(IDATBlockRemain,Chunk);
 End;
End;

Procedure EndIDAT;
Var
 Adler:LongInt;
 B:Byte;
Begin
 Adler:=GetAdler32;
 B:=Byte((Adler shr 24)and $FF); WriteIDATByte(B);
 B:=Byte((Adler shr 16)and $FF); WriteIDATByte(B);
 B:=Byte((Adler shr  8)and $FF); WriteIDATByte(B);
 B:=Byte( Adler         and $FF); WriteIDATByte(B);
 IDATCRC:=FinishCRC(IDATCRC);
 WriteBE32(IDATCRC);
End;
  {Lit la ligne brute du BMP (RowIndex=0 �tant la ligne sup�rieure du
   bitmap stock� : attention, BMP est stock� de bas en haut, l'appelant
   doit donc inverser l'index avant l'appel).}
Procedure ReadBmpRow(RowIndex:LongInt);
Begin
 Seek(SourceBMP,StartPos+RowIndex*LongInt(BMPBytesPerLine));
 BlockRead(SourceBMP,BMPLine,BMPBytesPerLine,ByteReaded);
End;

  {Renvoie l'index de palette pour le pixel X dans la ligne BMPLine, en
   fonction de la profondeur du BMP source (1, 4 ou 8 bits/pixel).}
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
  8:Begin
   GetPalIndex:=BMPLine[X];
  End;
  Else GetPalIndex:=0;
 End;
End;

Var
 IHDRData:Array[0..12]of Byte;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BMP2PNG : Cette commande permet de convertir une image BitMap (.BMP) ',
                    'en format PNG (.PNG, Portable Network Graphics).');
  WriteLn;
  WriteLn('Syntaxe : BMP2PNG nomdufichier.BMP');
  WriteLn;
  WriteLn(' nomdufichier   Nom du fichier ".BMP" � convertir.');
  WriteLn;
  WriteLn('Le fichier r�sultant porte le m�me nom avec l''extension .PNG, encod�');
  WriteLn('en couleurs vraies (type 2, 8 bits par canal). Seuls les BitMaps 1, 4,');
  WriteLn('8 ou 24 bits par pixel non compress�s sont support�s en entr�e.');
  Halt;
 End;
 If ParamCount<1 Then Begin
  WriteLn('Param�tre requis !');
  Halt;
 End;
 InitCRCTable;
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
 If(BIH.biBitCount<>1)and(BIH.biBitCount<>4)and(BIH.biBitCount<>8)
   and(BIH.biBitCount<>24)Then Begin
  WriteLn('Seuls les BitMaps 1, 4, 8 ou 24 bits par pixel sont support�s !');
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
 If LongInt(BIH.biWidth)>MaxWidth Then Begin
  WriteLn('Image trop large (largeur max : ',MaxWidth,') !');
  Halt;
 End;

 If BIH.biSizeImage=0 Then Begin
  Case BIH.biBitCount of
   1: BMPBPL:=((LongInt(BIH.biWidth)+31)div 32)*4;
   4: BMPBPL:=((LongInt(BIH.biWidth)+7)div 8)*4;
   8: BMPBPL:=((LongInt(BIH.biWidth)+3)div 4)*4;
   24:BMPBPL:=((LongInt(BIH.biWidth)*3+3)div 4)*4;
   Else BMPBPL:=0;
  End;
 End
  Else BMPBPL:=LongInt(BIH.biSizeImage)div LongInt(BIH.biHeight);
 If(BMPBPL<=0)or(BMPBPL>SizeOf(BMPLine))Then Begin
  WriteLn('Largeur de l''image trop grande !');
  Halt;
 End;
 BMPBytesPerLine:=Word(BMPBPL);


  {Lecture �ventuelle de la palette du BMP (pour les profondeurs 1, 4
   et 8 bits par pixel).}
 If BIH.biBitCount<=8 Then Begin
  NumPal:=Word(BIH.biClrUsed);
  If NumPal=0 Then NumPal:=1 shl BIH.biBitCount;
  Seek(SourceBMP,14+SizeOf(BitmapInfoHeader));
  BlockRead(SourceBMP,Palette,LongInt(NumPal)*SizeOf(RGB32),ByteReaded);
 End;

 ImageWidth:=Word(BIH.biWidth);
 ImageHeight:=Word(BIH.biHeight);
 StartPos:=Header.OffBits;

  {Cr�ation du fichier PNG de destination.}
 OutputName:=Path2NameExt(ParamStr(1));
 {$I-}Assign(DestPNG,OutputName);
 Rewrite(DestPNG,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de cr�er le fichier ',OutputName);
  Close(SourceBMP);
  Halt;
 End;

  {Signature PNG.}
 BlockWrite(DestPNG,PNGSignature,8,ByteWritten);

  {Chunk IHDR : 13 octets = largeur, hauteur, bit depth, color type,
   compression, filter, interlace.}
 IHDRData[0]:=Byte((LongInt(ImageWidth) shr 24)and $FF);
 IHDRData[1]:=Byte((LongInt(ImageWidth) shr 16)and $FF);
 IHDRData[2]:=Byte((LongInt(ImageWidth) shr  8)and $FF);
 IHDRData[3]:=Byte( LongInt(ImageWidth)         and $FF);
 IHDRData[4]:=Byte((LongInt(ImageHeight)shr 24)and $FF);
 IHDRData[5]:=Byte((LongInt(ImageHeight)shr 16)and $FF);
 IHDRData[6]:=Byte((LongInt(ImageHeight)shr  8)and $FF);
 IHDRData[7]:=Byte( LongInt(ImageHeight)        and $FF);
 IHDRData[8]:=8;   { Profondeur de bits par canal }
 IHDRData[9]:=2;   { Type de couleur : 2 = RGB }
 IHDRData[10]:=0;  { M�thode de compression : deflate }
 IHDRData[11]:=0;  { M�thode de filtrage : adaptative (filtres 0..4) }
 IHDRData[12]:=0;  { Entrelacement : aucun }
 WriteChunk('IHDR',IHDRData,13);

  {Construction et ecriture des lignes RGB filtrees (filtre None=0 + 3 octets BGR
   convertis en RGB) directement dans le flux IDAT.}
 BeginIDAT((LongInt(ImageWidth)*3+1)*LongInt(ImageHeight));
 For Y:=0 to LongInt(ImageHeight)-1 Do Begin
  SourceRow:=LongInt(ImageHeight)-1-Y;
  ReadBmpRow(SourceRow);
  RowBuf[0]:=0; { Filtre None }
  Case BIH.biBitCount of
   24:Begin
    For X:=0 to ImageWidth-1 Do Begin
     RowBuf[1+X*3+0]:=BMPLine[X*3+2]; { R }
     RowBuf[1+X*3+1]:=BMPLine[X*3+1]; { G }
     RowBuf[1+X*3+2]:=BMPLine[X*3+0]; { B }
    End;
   End;
   Else Begin
    For X:=0 to ImageWidth-1 Do Begin
     PalIdx:=GetPalIndex(X);
     RowBuf[1+X*3+0]:=Palette[PalIdx].R;
     RowBuf[1+X*3+1]:=Palette[PalIdx].G;
     RowBuf[1+X*3+2]:=Palette[PalIdx].B;
    End;
   End;
  End;
  WriteIDATRaw(RowBuf,LongInt(ImageWidth)*3+1);
 End;

 EndIDAT;

  {Chunk IEND, vide.}
 ByteV:=0;
 WriteChunk('IEND',ByteV,0);

 Close(DestPNG);
 Close(SourceBMP);
END.
