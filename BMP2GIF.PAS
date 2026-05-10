{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2GIF;

{$A-}

Uses DOS;

Const
  {Type de compression Windows}
 bi_RGB=0;
 bi_RLE8=1;
 bi_RLE4=2;

  {Param�tres LZW pour le format GIF}
 HashSize=5003;
 MaxLZWBits=12;
 MaxLZWCode=4096; { 1 shl MaxLZWBits }

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
 SourceBMP,DestGIF:File;
 Header:HeaderBMP;
 BIH:BitMapInfoHeader;
 BytesPerLine,ByteReaded,ByteWritten:Word;
 StartPos:LongInt;
 NumPal:Word;
 Palette:Array[0..255]of RGB32;
 Buffer:Array[0..4095]of Byte;
 PixelLine:Array[0..4095]of Byte;
 OutputName:String;

  {Etat de l'encodeur LZW}
 HashKey:Array[0..HashSize-1]of LongInt;
 HashCode:Array[0..HashSize-1]of Word;
 MinCodeSize:Byte;
 ClearCode,EOICode:Word;
 CurCodeSize:Byte;
 NextCode:Word;
 PrefixCode:LongInt;
 BitBuffer:LongInt;
 BitsInBuffer:Byte;
 SubBlock:Array[0..254]of Byte;
 SubBlockLen:Byte;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.GIF';
End;

Procedure WriteByteToFile(B:Byte);
Begin
 BlockWrite(DestGIF,B,1,ByteWritten);
End;

Procedure WriteWordToFile(W:Word);
Var
 Lo,Hi:Byte;
Begin
 Lo:=Byte(W and $FF);
 Hi:=Byte((W shr 8) and $FF);
 BlockWrite(DestGIF,Lo,1,ByteWritten);
 BlockWrite(DestGIF,Hi,1,ByteWritten);
End;

Procedure FlushSubBlock;
Begin
 If SubBlockLen>0 Then Begin
  BlockWrite(DestGIF,SubBlockLen,1,ByteWritten);
  BlockWrite(DestGIF,SubBlock,SubBlockLen,ByteWritten);
  SubBlockLen:=0;
 End;
End;

Procedure EmitOutputByte(B:Byte);
Begin
 SubBlock[SubBlockLen]:=B;
 Inc(SubBlockLen);
 If SubBlockLen=255Then FlushSubBlock;
End;

Procedure EmitCode(Code:Word);
Begin
 BitBuffer:=BitBuffer or(LongInt(Code)shl BitsInBuffer);
 Inc(BitsInBuffer,CurCodeSize);
 While BitsInBuffer>=8Do Begin
  EmitOutputByte(Byte(BitBuffer and $FF));
  BitBuffer:=BitBuffer shr 8;
  Dec(BitsInBuffer,8);
 End;
End;

Procedure FlushBits;
Begin
 If BitsInBuffer>0Then Begin
  EmitOutputByte(Byte(BitBuffer and $FF));
  BitBuffer:=0;
  BitsInBuffer:=0;
 End;
End;

Procedure ResetHash;
Var
 I:Word;
Begin
 For I:=0 to HashSize-1 Do HashKey[I]:=-1;
End;

  { Recherche d'une entr�e (Prefix, Suffix) dans la table de hachage.
    Retourne True si trouv� (Idx pointe sur l'entr�e existante).
    Retourne False sinon (Idx pointe sur l'emplacement libre o� ins�rer). }
Procedure HashFind(Prefix:Word;Suffix:Byte;Var Idx:Word;Var Found:Boolean);
Var
 Key:LongInt;
 H:Word;
Begin
 Key:=(LongInt(Prefix)shl 8)or Suffix;
 H:=Word(((Word(Suffix)shl 5)xor Prefix)mod HashSize);
 While HashKey[H]<>-1Do Begin
  If HashKey[H]=Key Then Begin
   Idx:=H;
   Found:=True;
   Exit;
  End;
  Inc(H);
  If H>=HashSize Then H:=0;
 End;
 Idx:=H;
 Found:=False;
End;

Procedure ResetLZWTable;
Begin
 ResetHash;
 CurCodeSize:=MinCodeSize+1;
 NextCode:=EOICode+1;
End;

Var
 I,X:Word;
 Width,Height:Word;
 Idx:Word;
 Found:Boolean;
 K:Byte;
 GCTBits:Byte;
 GCTSize:Word;
 PackedField:Byte;
 ZeroByte:Byte;
 GIFHeader:String[6];

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BMP2GIF : Cette commande permet de convertir une image BitMap (.BMP) ',
                     'en format GIF (Graphics Interchange Format).');
  WriteLn;
  WriteLn('Syntaxe : BMP2GIF nomdufichier.BMP');
  WriteLn;
  WriteLn(' nomdufichier   Ce param�tre permet d''indiquer le nom du fichier ".BMP".');
  WriteLn;
  WriteLn('Le fichier r�sultant porte le m�me nom avec l''extension .GIF.');
  WriteLn('Seuls les BitMaps 1, 4 et 8 bits par pixel non compress�s sont support�s.');
 End
  Else
 If ParamCount>0Then Begin
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
  If BIH.biSizeImage=0Then Begin
   WriteLn('Taille de l''image = 0 !');
   Halt;
  End
   Else
  Begin
   BytesPerLine:=Word(LongInt(LongInt(BIH.biSizeImage)div LongInt(BIH.biHeight)));
   If BytesPerLine>SizeOf(Buffer)Then Begin
    WriteLn('Largeur de l''image trop grande !');
    Halt;
   End;
  End;
  If(BIH.biBitCount<>1)and(BIH.biBitCount<>4)and(BIH.biBitCount<>8)Then Begin
   WriteLn('Seuls les BitMaps 1, 4 ou 8 bits par pixel sont support�s pour la conversion en GIF !');
   Halt(2);
  End;
  If BIH.biCompression<>bi_RGB Then Begin
   WriteLn('Compression RLE4 ou RL8 non support�');
   Halt(3);
  End;
  Case(BIH.biBitCount)of
   8:Begin NumPal:=256; GCTBits:=7; End; { 2^(7+1)=256 }
   4:Begin NumPal:=16;  GCTBits:=3; End; { 2^(3+1)=16 }
   1:Begin NumPal:=2;   GCTBits:=0; End; { 2^(0+1)=2 }
   Else Begin NumPal:=0; GCTBits:=0; End;
  End;
  GCTSize:=Word(1)shl(GCTBits+1);
  Seek(SourceBMP,14+SizeOf(BitmapInfoHeader));
  BlockRead(SourceBMP,Palette,LongInt(NumPal)*4,ByteReaded);
  StartPos:=Header.OffBits;
  Width:=Word(Header.NumXPixels);
  Height:=Word(Header.NumYPixels);

   {Cr�ation du fichier GIF de destination}
  OutputName:=Path2NameExt(ParamStr(1));
  {$I-}Assign(DestGIF,OutputName);
  Rewrite(DestGIF,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de cr�er le fichier ',OutputName);
   Close(SourceBMP);
   Halt;
  End;

   {Ent�te GIF89a}
  GIFHeader:='GIF89a';
  BlockWrite(DestGIF,GIFHeader[1],6,ByteWritten);

   {Logical Screen Descriptor}
  WriteWordToFile(Width);
  WriteWordToFile(Height);
  PackedField:=$80 or(GCTBits shl 4)or GCTBits;
  WriteByteToFile(PackedField); { GCT pr�sent, profondeur, taille }
  WriteByteToFile(0);            { Index de couleur d'arri�re-plan }
  WriteByteToFile(0);            { Ratio d'aspect des pixels }

   {Global Color Table}
  For I:=0 to GCTSize-1 Do Begin
   If I<NumPal Then Begin
    WriteByteToFile(Palette[I].R);
    WriteByteToFile(Palette[I].G);
    WriteByteToFile(Palette[I].B);
   End
    Else
   Begin
    WriteByteToFile(0);
    WriteByteToFile(0);
    WriteByteToFile(0);
   End;
  End;

   {Image Descriptor}
  WriteByteToFile($2C);
  WriteWordToFile(0);     { Position gauche }
  WriteWordToFile(0);     { Position haute }
  WriteWordToFile(Width);
  WriteWordToFile(Height);
  WriteByteToFile(0);     { Pas de table de couleurs locale, pas d'entrelacement }

   {Donn�es image LZW}
  If BIH.biBitCount<2 Then MinCodeSize:=2 { Le format GIF exige MinCodeSize >= 2 }
   Else MinCodeSize:=BIH.biBitCount;
  WriteByteToFile(MinCodeSize);

  ClearCode:=Word(1)shl MinCodeSize;
  EOICode:=ClearCode+1;
  BitBuffer:=0;
  BitsInBuffer:=0;
  SubBlockLen:=0;
  ResetLZWTable;

  EmitCode(ClearCode);
  PrefixCode:=-1;

  For I:=0 to Height-1 Do Begin
   Seek(SourceBMP,StartPos+LongInt(Height-1-I)*LongInt(BytesPerLine));
   BlockRead(SourceBMP,Buffer,BytesPerLine,ByteReaded);
   Case BIH.biBitCount of
    8:Begin
     For X:=0 to Width-1 Do PixelLine[X]:=Buffer[X];
    End;
    4:Begin
     For X:=0 to Width-1 Do
      If(X and 1)=0 Then PixelLine[X]:=(Buffer[X shr 1]shr 4)and $0F
       Else PixelLine[X]:=Buffer[X shr 1]and $0F;
    End;
    1:Begin
     For X:=0 to Width-1 Do
      PixelLine[X]:=(Buffer[X shr 3]shr(7-(X and 7)))and 1;
    End;
   End;
   For X:=0 to Width-1 Do Begin
    K:=PixelLine[X];
    If PrefixCode<0 Then PrefixCode:=K
     Else
    Begin
     HashFind(Word(PrefixCode),K,Idx,Found);
     If Found Then PrefixCode:=HashCode[Idx]
      Else
     Begin
      EmitCode(Word(PrefixCode));
      If NextCode<MaxLZWCode Then Begin
       HashKey[Idx]:=(LongInt(PrefixCode)shl 8)or K;
       HashCode[Idx]:=NextCode;
       Inc(NextCode);
        {Augmente la taille de code lorsque le compteur d�passe la
         capacit� actuelle. La comparaison est strictement sup�rieure
         car le d�codeur GIF ajoute son entr�e une �tape plus tard que
         l'encodeur ; un test '=' provoquerait une d�synchronisation
         des largeurs de code entre encodeur et d�codeur.}
       If(NextCode>(Word(1)shl CurCodeSize))and(CurCodeSize<MaxLZWBits)Then
        Inc(CurCodeSize);
      End
       Else
      Begin
       EmitCode(ClearCode);
       ResetLZWTable;
      End;
      PrefixCode:=K;
     End;
    End;
   End;
  End;

  If PrefixCode>=0 Then EmitCode(Word(PrefixCode));
  EmitCode(EOICode);
  FlushBits;
  FlushSubBlock;

  ZeroByte:=0;
  WriteByteToFile(ZeroByte); { Terminateur de bloc de donn�es }
  WriteByteToFile($3B);      { Fin du fichier GIF }

  Close(DestGIF);
  Close(SourceBMP);
 End
  Else
 WriteLn('Param�tre requis !');
END.
