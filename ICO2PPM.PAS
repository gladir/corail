{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program ICO2PPM;

{$A-}

Type
 RGB=Record
  R,G,B:Byte;
 End;

Const
 DefaultRGB:Array[0..15]of RGB=({ Palette RVB par d‚faut }
  (R:$00;G:$00;B:$00), { 00h (0): Palette RVB Noir par d‚faut }
  (R:$00;G:$00;B:$70), { 01h (1): Palette RVB Bleu par d‚faut }
  (R:$00;G:$70;B:$00), { 02h (2): Palette RVB Vert par d‚faut }
  (R:$00;G:$70;B:$70), { 03h (3): Palette RVB Cyan par d‚faut }
  (R:$70;G:$00;B:$00), { 04h (4): Palette RVB Rouge par d‚faut }
  (R:$70;G:$00;B:$70), { 05h (5): Palette RVB Magenta par d‚faut }
  (R:$70;G:$48;B:$00), { 06h (6): Palette RVB Brun par d‚faut }
  (R:$C4;G:$C4;B:$C4), { 07h (7): Palette RVB Gris clair par d‚faut }
  (R:$34;G:$34;B:$34), { 08h (8): Palette RVB Gris fonc, par d‚faut }
  (R:$00;G:$00;B:$FF), { 09h (9): Palette RVB Bleu claire par d‚faut }
  (R:$24;G:$FC;B:$24), { 0Ah (10): Palette RVB Vert claire par d‚faut }
  (R:$00;G:$FC;B:$FC), { 0Bh (11): Palette RVB Cyan claire par d‚faut }
  (R:$FC;G:$14;B:$14), { 0Ch (12): Palette RVB Rouge claire par d‚faut }
  (R:$B0;G:$00;B:$FC), { 0Dh (13): Palette RVB Magenta claire par d‚faut }
  (R:$FC;G:$FC;B:$24), { 0Eh (14): Palette RVB Jaune par d‚faut }
  (R:$FF;G:$FF;B:$FF));{ 0Fh (15): Palette RVB blanc par d‚faut }


Type
 IconDirEntry=Record
  bWidth:Byte;            { Largeur de l'ic“ne. 16, 32 ou 64 pixels. }
  bHeight:Byte;           { Hauteur de l'ic“ne. Doit ˆtre identique … bWidth }
  bColorCount:Byte;       { Nombre de couleurs. 2, 8 ou 16. }
  bReserved:Byte;         { R‚serv‚s, doit ˆtre … 0 pour l'instant, mais
                            pourra ˆtre utilis‚ ‚ventuellement pour
                            l'extension en 256 couleurs par exemples... }
  wPlanes:Word;           { Nombre de plans de couleurs dans l'ic“ne }
  wBitCount:Word;         { Nombre de bits par pixels }
  dwBytesInRes:LongInt;   { Grosseurs de la ressource en octets.}
  dwImageOffset:LongInt;  { Sp‚cifie la position absolue … partie du d‚but
                            du fichier en octets ou se trouve l'Ic“ne.}
 End;

 IconHeader=Record
  idReserved:Word;        { R‚serv‚; doit toujours ˆtre … 0 }
  idType:Word;            { Sp‚cifie le type de ressource, ce membre doit
                            donc ˆtre … 1 = Ic“ne, 2 = Curseur }
  idCount:Word;           { Nombre d'Ic“ne dans le r‚pertoire, C'est le
                            nombre dans le tableau ridEntries_!}
  idEntries:Array[0..1]of { D‚finit une structure contenant des }
            IconDirEntry; { indications d'une des Ic“nes du fichier.}
 End;

 BitmapInfoHeader=Record
  biSize:LongInt;         { Sp‚cifie le nombre d'octets requis pour la structure }
  biWidth:LongInt;        { Sp‚cifie la largeur du BitMap en pixels }
  biHeight:LongInt;       { Sp‚cifie la hauteur du BitMap en pixels }
  biPlanes:Word;          { Sp‚cifie le nombre de plane pour la destination }
  biBitCount:Word;        { Sp‚cifie le nombre de bits par pixel (1, 4, 8, 24)}
  biCompression:LongInt;  { Sp‚cifie le style de compression: BI_RGB, BI_RLE8, BI_RLE4 }
  biSizeImage:LongInt;    { Sp‚cifie la taille en octets pour l'image }
  biXPelsPerMeter:LongInt;{ Sp‚cifie le nombre horizontal de pixels par mStre }
  biYPelsPerMeter:LongInt;{ Sp‚cifie le nombre vertical de pixels par mStre }
  biClrUsed:LongInt;      { Sp‚cifie le nombre de couleurs index‚s dans la table}
  biClrImportant:LongInt; { Sp‚cifie le nombre de couleurs index‚s dans la table
                            en comptant ceux ‚tant vraiment indispensable … l'affichage}
 End;

Var
 HeaderStr:String;
 SourceICO,TargetPPM:File;
 Header:IconHeader;
 B,Size,I,J,K,Min,Max,BytesPerLine,ByteReaded,ByteWrited:Word;
 Lo4,Hi4:Byte;
 Buffer:Array[0..4095]of Byte;
 BitMap:BitMapInfoHeader Absolute Buffer;
 RGBBuffer:RGB;

Function IntToStr(I:Integer):String;
Var
 S:String;
Begin
 Str(I,S);
 IntToStr:=S;
End;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

BEGIN
If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ICO2PPM : Cette commande permet de transformer un ic“ne ',
                     'en format d''image PPM (Portable PixMap).');
  WriteLn;
  WriteLn('Syntaxe : ICO2PPM source.ICO destination.PPM');
  WriteLn;
  WriteLn(' source.ICO      Ce paramŠtre permet d''indiquer le nom du fichier ".ICO".');
  WriteLn(' destination.PPM Ce paramŠtre permet d''indiquer le nom du fichier ".PPM".');
 End
  Else
 If ParamCount>0Then Begin
  {$I-}Assign(SourceICO,ParamStr(1));
  Reset(SourceICO,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de lire le fichier d''ic“ne');
   Halt;
  End;
  {$I-}Assign(TargetPPM,ParamStr(2));
  Rewrite(TargetPPM,1);{$I+}
  BlockRead(SourceICO,Header,SizeOf(Header),ByteReaded);
  Min:=1;
  Max:=Header.idCount;
  If(Header.idReserved=0)and(Header.idType in[1,2])Then For I:=Min to(Max)do Begin
   Size:=Word(Header.idEntries[I-1].dwBytesInRes);
   If Size>SizeOf(Buffer)Then Begin
    WriteLn('Ligne d''ic“ne trop grande !');
    Halt;
   End;
   Seek(SourceICO,Header.idEntries[I-1].dwImageOffset);
   BlockRead(SourceICO,Buffer,Size,ByteReaded);
   If(Header.idEntries[I-1].bWidth=0)or(Header.idEntries[I-1].bHeight=0)Then Begin
    WriteLn('Taille de l''ic“ne invalide');
    Halt;
   End;
   B:=SizeOf(BitmapInfoHeader);
   Case BitMap.biBitCount of
    1:BytesPerLine:=Header.idEntries[I-1].bWidth shr 4;
    4:Begin
     BytesPerLine:=Header.idEntries[I-1].bWidth shr 1;
     Inc(B,4*16);
    End;
    8:BytesPerLine:=Header.idEntries[I-1].bWidth;
    15,16:BytesPerLine:=Header.idEntries[I-1].bWidth shl 1;
    24:BytesPerLine:=Header.idEntries[I-1].bWidth*3;
    Else BytesPerLine:=Header.idEntries[I-1].bWidth;
   End;
   If BitMap.biBitCount<>4Then Begin
    WriteLn('Seul le format 4 bits est support‚ !1');
    Halt;
   End;
   HeaderStr:='P6'#10+IntToStr(Header.idEntries[I-1].bWidth)+' '+
            IntToStr(Header.idEntries[I-1].bHeight)+#10+
            IntToStr(255)+#10;
   BlockWrite(TargetPPM,HeaderStr[1],Length(HeaderStr),ByteWrited);
   For J:=Header.idEntries[I-1].bHeight-1 downto 0 do Begin
    For K:=0 to BytesPerLine-1 do Begin
     Hi4:=Buffer[B+J*(Header.idEntries[I-1].bWidth shr 1)+K] shr 4;
     RGBBuffer.R:=DefaultRGB[Hi4].R;
     RGBBuffer.G:=DefaultRGB[Hi4].G;
     RGBBuffer.B:=DefaultRGB[Hi4].B;
     BlockWrite(TargetPPM,RGBBuffer,SizeOf(RGBBuffer),ByteWrited);
     Lo4:=Buffer[B+J*(Header.idEntries[I-1].bWidth shr 1)+K]and $F;
     RGBBuffer.R:=DefaultRGB[Lo4].R;
     RGBBuffer.G:=DefaultRGB[Lo4].G;
     RGBBuffer.B:=DefaultRGB[Lo4].B;
     BlockWrite(TargetPPM,RGBBuffer,SizeOf(RGBBuffer),ByteWrited);
    End;
   End;
  End;
  Close(TargetPPM);
  Close(SourceICO);
 End
  Else
 WriteLn('ParamŠtre requis !');
END.
