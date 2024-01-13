{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program VIEWBMP;

{$A-}

Uses {$IFDEF FPC}
      Crt,PtcGraph,PtcCrt,PtcMouse
     {$ELSE}
      Crt,Graph
     {$ENDIF};

Const
  {Type de compression Windows}
 bi_RGB=0;
 bi_RLE8=1;
 bi_RLE4=2;

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
 SourceBMP:File;
 Header:HeaderBMP;
 Size,I,J,K,Min,Max,BytesPerLine,ByteReaded:Word;
 Value,CountValue:Integer;
 R,G,B:Byte;
 BIH:BitMapInfoHeader;
 PixelX,PixelY:Word;
 StartPos:LongInt;
 NumPal:Word;
 Palette:Array[0..255]of RGB32;
 Buffer:Array[0..4095]of Byte;

Function RGBTo16Color(R,G,B:Byte):Integer;
Var
 Kr:Byte;
Begin
 Kr:=0;
 If(R)and$80=$80Then Kr:=Kr or$04;
 If(R)and$40=$40Then Kr:=Kr or$20;
 If(G)and$80=$80Then Kr:=Kr or$02;
 If(G)and$40=$40Then Kr:=Kr or$10;
 If(B)and$80=$80Then Kr:=Kr or$01;
 If(B)and$40=$40Then Kr:=Kr or$08;
 RGBTo16Color:=Kr and$F;
End;

Procedure InitScr;
Var
 Driver,Mode:Integer;
 ErrCode:Integer;
Begin
 {$IFDEF FPC}
  Driver:=VGA;
  Mode:=VGAHi;
 {$ELSE}
  Driver:=Detect;
  Mode:=VGAHi;
 {$ENDIF}
 InitGraph(Driver,Mode,'');
 ErrCode:=GraphResult;
 If ErrCode=grOk Then Begin
  SetColor(White);
  SetLineStyle(0, 0, 1);
 End
  Else
 Begin
  WriteLn('Erreur graphique : ',GraphErrorMsg(ErrCode));
  Halt;
 End;
End;

Procedure AddPixel;
Var
 RawValue:Byte;
Begin
 Case(Header.BitCount)of
  4:Begin
   If NumPal=0 Then Begin
    PutPixel(PixelX,PixelY,Value shr 4);
    PutPixel(PixelX+1,PixelY,Value and $F);
   End
    Else
   Begin
    If(PixelX<Header.NumXPixels)Then Begin
     RawValue:=RGBTo16Color(Palette[Value shr 4].R,Palette[Value shr 4].G,Palette[Value shr 4].B);
     PutPixel(PixelX,PixelY,RawValue);
    End;
    If(PixelX+1<Header.NumXPixels)Then Begin
     RawValue:=RGBTo16Color(Palette[Value and $F].R,Palette[Value and $F].G,Palette[Value and $F].B);
     PutPixel(PixelX+1,PixelY,RawValue);
    End;
   End;
   Inc(PixelX,2);
  End;
  8:Begin
   If NumPal=0 Then Begin
    PutPixel(PixelX,PixelY,Value);
   End
    Else
   Begin
    RawValue:=RGBTo16Color(Palette[Value].R,Palette[Value].G,Palette[Value].B);
    PutPixel(PixelX,PixelY,RawValue);
   End;
   Inc(PixelX);
  End;
  24:Begin
   Case CountValue of
    0:R:=Value;
    1:G:=Value;
    2:Begin
     B:=Value;
     Value:=RGBTo16Color(R,G,B);
     PutPixel(PixelX,PixelY,Value);
     Inc(PixelX)
    End;
   End;
   CountValue:=(CountValue+1)mod 3;
  End;
 End;
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('VIEWBMP : Cette commande permet de visualiser un image BitMap (.BMP).');
  WriteLn;
  WriteLn('Syntaxe : VIEWBMP nomdufichier.BMP');
  WriteLn;
  WriteLn(' nomdufichier   Ce paramŠtre permet d''indiquer le nom du fichier ".BMP".');
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
   WriteLn('Signature d''entˆte Bitmap introuvable !');
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
   BytesPerLine:=Word(LongInt(LongInt(BIH.biSizeImage) div LongInt(BIH.biHeight)));
   If BytesPerLine>SizeOf(Buffer)Then Begin
    WriteLn('Largeur de l''image trop grande !');
    Halt;
   End;
  End;
  InitScr;
  PixelX:=0;
  PixelY:=0;
  CountValue:=0;
  NumPal:=0;
  Case(BIH.biBitCount)of
   8:NumPal:=256;
   4:NumPal:=16;
   Else NumPal:=0;
  End;
  If NumPal>0Then Begin
   Seek(SourceBMP,14+SizeOf(BitmapInfoHeader));
   BlockRead(SourceBMP,Palette,SizeOf(Palette),ByteReaded);
  End;
  StartPos:=Header.OffBits;
  If BIH.biCompression in[bi_RGB]Then Begin
   For I:=Header.NumYPixels-1 downto 0 do Begin
    Seek(SourceBMP,StartPos+I*BytesPerLine);
    BlockRead(SourceBMP,Buffer,BytesPerLine,ByteReaded);
    PixelX:=0;
    For J:=0 to BytesPerLine do Begin
     Value:=Buffer[J];
     AddPixel;
    End;
    Inc(PixelY);
   End;
  End
   Else
  Begin
   WriteLn('Compression RLE4 ou RL8 non support‚');
  End;
  Close(SourceBMP);
  If(ReadKey=#0)Then Begin
   If(ReadKey<>#0)Then Begin
   End;
  End;
 End
  Else
 WriteLn('ParamŠtre requis !');
END.
