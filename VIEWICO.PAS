{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program VIEWICO;

{$A-}

Uses Crt;

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
 SourceICO:File;
 Header:IconHeader;
 Size,I,J,K,Min,Max,BytesPerLine,ByteReaded:Word;
 Buffer:Array[0..4095]of Byte;
 BitMap:BitMapInfoHeader Absolute Buffer;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('VIEWICO : Cette commande permet de visualiser un ic“ne ');
  WriteLn;
  WriteLn('Syntaxe : VIEWICO nomdufichier.ICO');
  WriteLn;
  WriteLn(' nomdufichier   Ce paramŠtre permet d''indiquer le nom du fichier ".ICO".');
 End
  Else
 If ParamCount>0Then Begin
  {$I-}Assign(SourceICO,ParamStr(1));
  Reset(SourceICO,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de lire le fichier d''ic“ne');
   Halt;
  End;
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
   Case BitMap.biBitCount of
    1:BytesPerLine:=Header.idEntries[I-1].bWidth shr 4;
    4:BytesPerLine:=Header.idEntries[I-1].bWidth shr 1;
    8:BytesPerLine:=Header.idEntries[I-1].bWidth;
    15,16:BytesPerLine:=Header.idEntries[I-1].bWidth shl 1;
    24:BytesPerLine:=Header.idEntries[I-1].bWidth*3;
    Else BytesPerLine:=Header.idEntries[I-1].bWidth;
   End;
   If BitMap.biBitCount<>4 Then Begin
    WriteLn('Seul le format 4 bits de couleurs est support‚ !');
    Halt;
   End;
   For J:=Header.idEntries[I-1].bHeight-1 downto 0 do Begin
    For K:=0 to BytesPerLine-1 do Begin
     If Buffer[SizeOf(BitmapInfoHeader)+J*(Header.idEntries[I-1].bWidth shr 1)+K]=0 Then Begin
      TextBackground(0);
      TextColor(8);
      Write('....');
     End
      Else
     Begin
      TextColor(Buffer[SizeOf(BitmapInfoHeader)+J*(Header.idEntries[I-1].bWidth shr 1)+K]shr 4);
      Write(#219#219);
      TextColor(Buffer[SizeOf(BitmapInfoHeader)+J*(Header.idEntries[I-1].bWidth shr 1)+K] and $F);
      Write(#219#219);
     End;
    End;
    TextColor(7);
    TextBackground(0);
    WriteLn;
   End;
  End;
  Close(SourceICO);
 End
  Else
 WriteLn('ParamŠtre requis !');
END.
