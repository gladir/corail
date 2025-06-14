{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2PAS;

{$A-}

Uses DOS;

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
 CropPos:(crX1,crY1,crX2,crY2);
 First:Boolean;
 CountByLine:Word;
 CurrNumber,FileNameSource:String;
 SourceBMP:File;
 Header:HeaderBMP;
 Size,I,J,K,Min,Max,BytesPerLine,ByteReaded:Word;
 CropX1,CropX2,CropY1,CropY2:Integer;
 Value,CountValue:Integer;
 R,G,B:Byte;
 BIH:BitMapInfoHeader;
 PixelX,PixelY:Word;
 StartPos:LongInt;
 NumPal:Word;
 ImageName:String;
 Palette:Array[0..255]of RGB32;
 Buffer:Array[0..4095]of Byte;
 Err:Word;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function Path2Name(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2Name:=N;
End;

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

Function InCropZone:Boolean;Begin
  If(CropX1<>-1)Then Begin
    InCropZone:=False;
    If(I>=CropY1)and(I<=CropY2)and(PixelX>=CropX1)and(PixelX<=CropX2)Then Begin
     InCropZone:=True;
    End;
   End
  Else
 InCropZone:=True;
End;

Procedure AddPixel;
Var
 RawValue:Byte;
Begin
 Case(Header.BitCount)of
  4:Begin
   If NumPal=0 Then Begin
    If(First)Then First:=False
     Else
    Begin
     If(InCropZone)Then Write(',');
     Inc(CountByLine);
     If CountByLine>12 Then Begin
      CountByLine:=0;
      If(InCropZone)Then Begin
       WriteLn;
       Write('  ');
      End;
     End;
    End;
    If(InCropZone)Then Write('$',ByteHex2Str(Value));
   End
    Else
   Begin
    If(PixelX<Header.NumXPixels)Then Begin
     If(First)Then First:=False
      Else
     Begin
      If(InCropZone)Then Begin
       Write(',');
      End;
      Inc(CountByLine);
      If CountByLine>12 Then Begin
       CountByLine:=0;
       If(InCropZone)Then Begin
        WriteLn;
        Write('  ');
       End;
      End;
     End;
     If(InCropZone)Then Write('$',ByteHex2Str(Value));
    End;
   End;
   Inc(PixelX,2);
  End;
  8:Begin
   If(First)Then First:=False
    Else
   Begin
    If(InCropZone)Then Write(',');
    Inc(CountByLine);
    If CountByLine>12 Then Begin
     CountByLine:=0;
     If(InCropZone)Then Begin
      WriteLn;
      Write('  ');
     End;
    End;
   End;
   If(InCropZone)Then Write('$',ByteHex2Str(Value));
   Inc(PixelX);
  End;
  24:Begin
   Case CountValue of
    0:R:=Value;
    1:G:=Value;
    2:Begin
     B:=Value;
     If(First)Then First:=False
      Else
     Begin
      If(InCropZone)Then Write(',');
      Inc(CountByLine,3);
      If CountByLine>12 Then Begin
       CountByLine:=0;
       If(InCropZone)Then Begin
        WriteLn;
        Write('  ');
       End;
      End;
     End;
     If(InCropZone)Then Write('$',ByteHex2Str(R),',','$',ByteHex2Str(G),',','$',ByteHex2Str(B));
     Inc(PixelX)
    End;
   End;
   CountValue:=(CountValue+1)mod 3;
  End;
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BMP2PAS : Cette commande permet de convertir une image BitMap (.BMP) ',
                     'en code source Pascal.');
  WriteLn;
  WriteLn('Syntaxe : BMP2PAS nomdufichier.BMP [options]');
  WriteLn;
  WriteLn(' nomdufichier       Ce paramŠtre permet d''indiquer le nom du fichier ".BMP".');
  WriteLn(' /CROP:x1,y1,x2,y2  Ce paramŠtre permet de r‚cup‚rer une partie de l''image');
  WriteLn(' --version          Ce paramŠtre permet de retourner la version de la commande.');
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('BMP2PAS 1.1 - BMP … Pascal de corail et dev-cools');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('crit par Sylvain Maltais');
 End
  Else
 If ParamCount>0Then Begin
  FileNameSource:='';
  CropX1:=-1;
  CropX2:=-1;
  CropY1:=-1;
  CropY2:=-1;
  For I:=1 to ParamCount do Begin
   If StrToUpper(Copy(ParamStr(I),1,Length('/CROP:')))='/CROP:'Then Begin
    CurrNumber:='';
    CropPos:=crX1;
    For J:=Length('/CROP:')+1 to Length(ParamStr(I))do Begin
     If Copy(ParamStr(I),J,1)=','Then Begin
      Case CropPos of
       crX1:Begin
        Val(CurrNumber,CropX1,Err);
        CropPos:=crY1;
       End;
       crY1:Begin
        Val(CurrNumber,CropY1,Err);
        CropPos:=crX2;
       End;
       crX2:Begin
        Val(CurrNumber,CropX2,Err);
        CropPos:=crY2;
       End;
       crY2:Begin
        Val(CurrNumber,CropY2,Err);
       End;
      End;
      CurrNumber:='';
     End
      Else
     CurrNumber:=CurrNumber+Copy(ParamStr(I),J,1);
    End;
    If CropPos=crY2 Then Begin
     Val(CurrNumber,CropY2,Err);
     CropPos:=crY1;
    End;
   End
    Else
   FileNameSource:=ParamStr(I);
  End;
  {$I-}Assign(SourceBMP,FileNameSource);
  Reset(SourceBMP,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de lire le fichier d''image');
   Halt;
  End;
  ImageName:=Path2Name(ParamStr(1));
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
  First:=True;
  If BIH.biCompression in[bi_RGB]Then Begin
   CountByLine:=0;
   WriteLn('Const');
   If(CropX1<>-1)and(CropX2<>-1)Then Begin
    WriteLn(' NumXPixels=',(CropX2-CropX1)+1,';');
   End
    Else
   Begin
    WriteLn(' NumXPixels=',Header.NumXPixels,';');
   End;
   If(CropY1<>-1)and(CropY2<>-1)Then Begin
    WriteLn(' NumYPixels=',(CropY2-CropY1)+1,';');
   End
    Else
   Begin
    WriteLn(' NumYPixels=',Header.NumYPixels,';');
   End;
   WriteLn(' BitsPerPixel=',BIH.biBitCount,';');
   WriteLn(' BytesPerLine=',BytesPerLine,';');
   If(CropX1<>-1)and(CropX2<>-1)Then Begin
    Case BIH.biBitCount of
     4:WriteLn(' BitmapData:Array[0..',Pred((Succ(CropX2-CropX1) shr 1)*(Succ(CropY2-CropY1))),
               ']of Byte=(');
     8:WriteLn(' BitmapData:Array[0..',Pred(Succ(CropX2-CropX1)*(Succ(CropY2-CropY1))),
               ']of Byte=(');
     16:WriteLn(' BitmapData:Array[0..',Pred((Succ(CropX2-CropX1) shl 1)*(Succ(CropY2-CropY1))),
               ']of Byte=(');
     24:WriteLn(' BitmapData:Array[0..',Pred((Succ(CropX2-CropX1)*3)*(Succ(CropY2-CropY1))),
               ']of Byte=(');
     32:WriteLn(' BitmapData:Array[0..',Pred((Succ(CropX2-CropX1) shr 2)*(Succ(CropY2-CropY1))),
               ']of Byte=(');
    End;
   End
    Else
   Begin
    WriteLn(' BitmapData:Array[0..',
           Pred(BytesPerLine*Header.NumYPixels),
           ']of Byte=(');
   End;
   Write('  ');
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
   WriteLn;
   WriteLn(');');
  End
   Else
  Begin
   WriteLn('Compression RLE4 ou RL8 non support‚');
   Halt(3);
  End;
  Close(SourceBMP);
 End
  Else
 WriteLn('ParamŠtre requis !');
END.
