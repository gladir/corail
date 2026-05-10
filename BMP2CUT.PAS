{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2CUT;

{$A-}

Uses DOS;

Const
  {Type de compression Windows}
 bi_RGB=0;
 bi_RLE8=1;
 bi_RLE4=2;

  {Largeur maximale support�e (en pixels).}
 MaxWidth=4096;

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

  {En-t�te d'un fichier Dr. HALO ".CUT" : 6 octets en ordre Intel (LSB en
   premier). Ce format a �t� d�fini par Media Cybernetics pour Dr. HALO,
   Dr. HALO II et Dr. HALO III ; les trois versions partagent strictement
   la m�me structure d'image (la palette est stock�e � part dans un
   fichier compagnon ".PAL" dont seule la mise en forme diff�re entre
   les versions). Le .CUT contient toujours des index de palette sur 8
   bits (256 couleurs maximum) compress�s ligne par ligne en RLE.}
 HeaderCUT=Record
  Width,Height,Reserved:Word;
 End;

Var
 SourceBMP,DestCUT:File;
 Header:HeaderBMP;
 BIH:BitMapInfoHeader;
 CUTHeader:HeaderCUT;
 BMPBytesPerLine,ByteReaded,ByteWritten:Word;
 StartPos:LongInt;
 NumPal:Word;
 Palette:Array[0..255]of RGB32;
 BMPLine:Array[0..MaxWidth*3-1]of Byte;  { Ligne brute lue dans le BMP }
 PixelLine:Array[0..MaxWidth-1]of Byte;  { Indices 8 bits d�coul�s pour la ligne }
 RLEBuf:Array[0..MaxWidth*2+3]of Byte;   { Tampon RLE (taille pire cas) }
 OutputName:String;
 ImageWidth,ImageHeight:Word;
 BMPBPL:LongInt;
 Y:LongInt;
 SourceRow:LongInt;
 X:Word;
 RLELen:Word;
 EndMarker:Word;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.CUT';
End;

  {Lit la ligne brute du BMP (RowIndex=0 �tant la premi�re ligne stock�e
   dans le fichier ; les BMP �tant "bottom-up", l'appelant doit inverser
   l'index avant l'appel pour parcourir l'image de haut en bas).}
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

  {Encode une ligne de "Count" indices de palette (PixelLine) selon le
   sch�ma RLE Dr. HALO et place le r�sultat dans RLEBuf, terminateur 0
   inclus. Renvoie la longueur totale (qui est aussi la valeur du mot
   "longueur de ligne" pr�c�dant le flux).

   Format des "tokens" �mis :
     - Octet de t�te entre $01 et $7F : suite litt�rale de "n" octets
       (1 � 127) qui suit l'en-t�te tels quels.
     - Octet de t�te entre $81 et $FF : r�p�tition de ($80 OR n), soit
       n=2..127 copies de l'octet de donn�es qui suit. Une r�p�tition
       de longueur 1 ou 0 est interdite : la valeur $80 (run de 0) est
       r�serv�e/ignor�e.
     - Octet $00 : fin de ligne.}
Function EncodeCutRow(Count:Word):Word;
Var
 Pos,DestPos:Word;
 RunLen,LitLen,K:Word;
Begin
 Pos:=0;
 DestPos:=0;
 While Pos<Count Do Begin
   {D�tection d'une r�p�tition � la position courante.}
  RunLen:=1;
  While(Pos+RunLen<Count)and(RunLen<127)and
       (PixelLine[Pos+RunLen]=PixelLine[Pos])Do Inc(RunLen);
  If RunLen>=2 Then Begin
    {Course suffisamment longue : codage en run.}
   RLEBuf[DestPos]:=$80 or Byte(RunLen);
   RLEBuf[DestPos+1]:=PixelLine[Pos];
   Inc(DestPos,2);
   Inc(Pos,RunLen);
  End
   Else Begin
     {Suite litt�rale jusqu'� la prochaine r�p�tition d'au moins 2
      octets, ou jusqu'� 127 octets, ou la fin de la ligne.}
    LitLen:=0;
    While(Pos+LitLen<Count)and(LitLen<127)Do Begin
     If(Pos+LitLen+1<Count)and
       (PixelLine[Pos+LitLen]=PixelLine[Pos+LitLen+1])Then Break;
     Inc(LitLen);
    End;
    If LitLen=0 Then LitLen:=1; { S�curit� : ne devrait pas se produire }
    RLEBuf[DestPos]:=Byte(LitLen);
    Inc(DestPos);
    For K:=0 to LitLen-1 Do RLEBuf[DestPos+K]:=PixelLine[Pos+K];
    Inc(DestPos,LitLen);
    Inc(Pos,LitLen);
   End;
 End;
  {Terminateur de ligne : un octet $00.}
 RLEBuf[DestPos]:=0;
 Inc(DestPos);
 EncodeCutRow:=DestPos;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BMP2CUT : Cette commande permet de convertir une image BitMap (.BMP) ',
                    'en format Dr. HALO (.CUT).');
  WriteLn;
  WriteLn('Syntaxe : BMP2CUT nomdufichier.BMP');
  WriteLn;
  WriteLn(' nomdufichier   Nom du fichier ".BMP" � convertir.');
  WriteLn;
  WriteLn('Le fichier r�sultant porte le m�me nom avec l''extension .CUT et est');
  WriteLn('compatible avec Dr. HALO, Dr. HALO II et Dr. HALO III (les trois');
  WriteLn('versions partagent le m�me format de fichier image). Seuls les');
  WriteLn('BitMaps 1, 4 ou 8 bits par pixel non compress�s sont support�s. La');
  WriteLn('palette du BMP n''est pas stock�e dans le .CUT : Dr. HALO la lit dans');
  WriteLn('un fichier ".PAL" compagnon dont le format d�pend de la version.');
  Halt;
 End;
 If ParamCount<1 Then Begin
  WriteLn('Param�tre requis !');
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
  WriteLn('Signature d''ent�te Bitmap introuvable !');
  Halt;
 End;
 Seek(SourceBMP,14);
 BlockRead(SourceBMP,BIH,SizeOf(BIH),ByteReaded);
 If(BIH.biBitCount<>1)and(BIH.biBitCount<>4)and(BIH.biBitCount<>8)Then Begin
  WriteLn('Seuls les BitMaps 1, 4 ou 8 bits par pixel sont support�s !');
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
 If BIH.biWidth>MaxWidth Then Begin
  WriteLn('Largeur de l''image trop grande !');
  Halt;
 End;

  {Calcul du nombre d'octets par ligne BMP : multiple de 4 octets.}
 If BIH.biSizeImage=0 Then
  BMPBPL:=((LongInt(BIH.biWidth)*LongInt(BIH.biBitCount)+31)div 32)*4
                     Else BMPBPL:=LongInt(BIH.biSizeImage)div LongInt(BIH.biHeight);
 If(BMPBPL<=0)or(BMPBPL>SizeOf(BMPLine))Then Begin
  WriteLn('Largeur de l''image trop grande !');
  Halt;
 End;
 BMPBytesPerLine:=Word(BMPBPL);

  {Lecture de la palette (sert uniquement � valider le BMP source ;
   Dr. HALO conserve la palette dans un fichier .PAL distinct).}
 NumPal:=Word(BIH.biClrUsed);
 If NumPal=0 Then Case BIH.biBitCount of
                    1:NumPal:=2;
                    4:NumPal:=16;
                    8:NumPal:=256;
                   End;
 If NumPal>256 Then NumPal:=256;
 Seek(SourceBMP,14+SizeOf(BitmapInfoHeader));
 FillChar(Palette,SizeOf(Palette),0);
 BlockRead(SourceBMP,Palette,LongInt(NumPal)*SizeOf(RGB32),ByteReaded);

 ImageWidth:=Word(BIH.biWidth);
 ImageHeight:=Word(BIH.biHeight);
 StartPos:=Header.OffBits;

  {Cr�ation du fichier CUT de destination.}
 OutputName:=Path2NameExt(ParamStr(1));
 {$I-}Assign(DestCUT,OutputName);
 Rewrite(DestCUT,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de cr�er le fichier ',OutputName);
  Close(SourceBMP);
  Halt;
 End;

  {�criture de l'en-t�te 6 octets (largeur, hauteur, r�serv�).}
 CUTHeader.Width:=ImageWidth;
 CUTHeader.Height:=ImageHeight;
 CUTHeader.Reserved:=0;
 BlockWrite(DestCUT,CUTHeader,SizeOf(CUTHeader),ByteWritten);

  {�criture des lignes RLE de haut en bas.}
 For Y:=0 to LongInt(ImageHeight)-1 Do Begin
    {Les BMP �tant stock�s "bottom-up", on inverse l'index pour
     parcourir l'image dans l'ordre natural attendu par Dr. HALO.}
   SourceRow:=LongInt(ImageHeight)-1-Y;
   ReadBmpRow(SourceRow);
   For X:=0 to ImageWidth-1 Do PixelLine[X]:=GetPalIndex(X);
   RLELen:=EncodeCutRow(ImageWidth);
   BlockWrite(DestCUT,RLELen,2,ByteWritten);
   BlockWrite(DestCUT,RLEBuf,RLELen,ByteWritten);
 End;

  {Marqueur de fin de fichier : un mot � z�ro apr�s la derni�re ligne
   (un en-t�te de "ligne suppl�mentaire" de longueur nulle).}
 EndMarker:=0;
 BlockWrite(DestCUT,EndMarker,2,ByteWritten);

 Close(DestCUT);
 Close(SourceBMP);
END.
