{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program VIEWWPG;

{$A-}

Uses {$IFDEF FPC}
      Crt,PtcGraph,PtcCrt,PtcMouse
     {$ELSE}
      Crt,Graph
     {$ENDIF};

Const
 MaxWidth=4096;

 WPGMagic0=$FF;
 WPGMagic1=$57;
 WPGMagic2=$50;
 WPGMagic3=$43;

 WPGRecStart=$0F;
 WPGRecEnd=$10;
 WPGRecColorMap=$0E;
 WPGRecBitmap1=$0B;
 WPGRecFillAttr=$01;
 WPGRecLineAttr=$02;
 WPGRecPolyline=$06;
 WPGRecRectangle=$07;
 WPGRecPolygon=$08;

Type
 RGB=Record
  R,G,B:Byte;
 End;

Var
 SourceWPG:File;
 Palette:Array[0..255]of RGB;
 LineBuf:Array[0..MaxWidth-1]of Byte;
 SourceFileName:String;
 ByteReaded:Word;
 NumPal:Word;
 ImageWidth,ImageHeight,BitsPerPixel:Word;
 WPGBytesPerLine:Word;
 PictureWidth,PictureHeight:Word;
 CurrentLineColor:Integer;
 UseLittleEndian:Boolean;
 ScreenReady:Boolean;
 X:Word;
 B:Byte;
 RecType:Byte;
 RecLen:LongInt;
 RecStartPos:LongInt;
 Done:Boolean;

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
  SetLineStyle(0,0,1);
 End
  Else
 Begin
  WriteLn('Erreur graphique : ',GraphErrorMsg(ErrCode));
  Halt;
 End;
End;

Procedure EnsureScr;
Begin
 If Not ScreenReady Then Begin
  InitScr;
  ScreenReady:=True;
 End;
End;

Procedure ReadByte(Var Value:Byte);
Begin
 BlockRead(SourceWPG,Value,1,ByteReaded);
 If ByteReaded<>1 Then Begin
  WriteLn('Lecture incomplete du fichier WPG !');
  Close(SourceWPG);
  Halt;
 End;
End;

Function ReadWordBE:Word;
Var
 B0,B1:Byte;
Begin
 ReadByte(B0);
 ReadByte(B1);
 ReadWordBE:=Word(B0)*256+Word(B1);
End;

Function ReadWordLE:Word;
Var
 B0,B1:Byte;
Begin
 ReadByte(B0);
 ReadByte(B1);
 ReadWordLE:=Word(B0)+Word(B1)*256;
End;

Function ReadWordWPG:Word;
Begin
 If UseLittleEndian Then ReadWordWPG:=ReadWordLE
                    Else ReadWordWPG:=ReadWordBE;
End;

Function ReadLongBE:LongInt;
Var
 B0,B1,B2,B3:Byte;
Begin
 ReadByte(B0);
 ReadByte(B1);
 ReadByte(B2);
 ReadByte(B3);
 ReadLongBE:=(LongInt(B0)shl 24)or(LongInt(B1)shl 16)or
             (LongInt(B2)shl 8)or LongInt(B3);
End;

Function ReadLongLE:LongInt;
Var
 B0,B1,B2,B3:Byte;
Begin
 ReadByte(B0);
 ReadByte(B1);
 ReadByte(B2);
 ReadByte(B3);
 ReadLongLE:=LongInt(B0)or(LongInt(B1)shl 8)or
             (LongInt(B2)shl 16)or(LongInt(B3)shl 24);
End;

Function ReadRecLength:LongInt;
Var
 B:Byte;
 W:Word;
Begin
 ReadByte(B);
 If B<$FF Then ReadRecLength:=B
 Else Begin
  W:=ReadWordWPG;
  If(W and $8000)<>0 Then
   ReadRecLength:=(LongInt(W and $7FFF)shl 16)+LongInt(ReadWordWPG)
  Else
   ReadRecLength:=W;
 End;
End;

Procedure SkipBytes(Count:LongInt);
Var
 Dummy:Array[0..255]of Byte;
 Chunk:Word;
 Readed:Word;
Begin
 While Count>0 Do Begin
  If Count>SizeOf(Dummy) Then Chunk:=SizeOf(Dummy)
                          Else Chunk:=Word(Count);
  BlockRead(SourceWPG,Dummy,Chunk,Readed);
  If Readed<>Chunk Then Begin
   WriteLn('Lecture incomplete du fichier WPG !');
   Close(SourceWPG);
   Halt;
  End;
  Dec(Count,Chunk);
 End;
End;

Function BytesPerLine(Width,BPP:Word):Word;
Begin
 BytesPerLine:=Word((LongInt(Width)*LongInt(BPP)+7)div 8);
End;

Function PalColor(Index:Byte):Integer;
Begin
 If Index<NumPal Then
  PalColor:=RGBTo16Color(Palette[Index].R,Palette[Index].G,Palette[Index].B)
 Else
  PalColor:=Index and $0F;
End;

Procedure DecodeWPGLine(LineLen:Word);
Var
 Pos:Word;
 Count:Byte;
 Readed:Word;
Begin
 Pos:=0;
 FillChar(LineBuf,SizeOf(LineBuf),0);
 While Pos<LineLen Do Begin
  ReadByte(Count);
  If Count=0 Then Begin
   WriteLn('Donnees RLE WPG invalides !');
   Close(SourceWPG);
   Halt;
  End;
  If Pos+Count>LineLen Then Count:=Byte(LineLen-Pos);
  BlockRead(SourceWPG,LineBuf[Pos],Count,Readed);
  If Readed<>Count Then Begin
   WriteLn('Lecture incomplete des donnees bitmap WPG !');
   Close(SourceWPG);
   Halt;
  End;
  Inc(Pos,Count);
 End;
End;

Procedure DrawLine(LineY:Word);
Var
 Index:Byte;
Begin
 Case BitsPerPixel of
  1:Begin
   For X:=0 to ImageWidth-1 Do Begin
    Index:=(LineBuf[X shr 3] shr (7-(X and 7)))and 1;
    PutPixel(X,LineY,PalColor(Index));
   End;
  End;
  4:Begin
   For X:=0 to ImageWidth-1 Do Begin
    If(X and 1)=0 Then Index:=LineBuf[X shr 1]shr 4
                  Else Index:=LineBuf[X shr 1]and $0F;
    PutPixel(X,LineY,PalColor(Index));
   End;
  End;
  8:Begin
   For X:=0 to ImageWidth-1 Do PutPixel(X,LineY,PalColor(LineBuf[X]));
  End;
 End;
End;

Procedure ReadColorMap(Len:LongInt);
Var
 FirstEntry:Word;
 Count:Word;
 I:Word;
Begin
 If Len<4 Then Begin
  WriteLn('Carte de couleurs WPG invalide !');
  Close(SourceWPG);
  Halt;
 End;
 FirstEntry:=ReadWordWPG;
 Count:=ReadWordWPG;
 NumPal:=0;
 For I:=0 to Count-1 Do Begin
  If FirstEntry+I<=255 Then Begin
   ReadByte(Palette[FirstEntry+I].R);
   ReadByte(Palette[FirstEntry+I].G);
   ReadByte(Palette[FirstEntry+I].B);
   If FirstEntry+I+1>NumPal Then NumPal:=FirstEntry+I+1;
  End
   Else
  Begin
   ReadByte(B);
   ReadByte(B);
   ReadByte(B);
  End;
 End;
End;

Procedure ReadBitmap1(Len:LongInt);
Var
 XRes,YRes:Word;
 LineY:Word;
Begin
 If Len<10 Then Begin
  WriteLn('Enregistrement bitmap WPG invalide !');
  Close(SourceWPG);
  Halt;
 End;
 ImageWidth:=ReadWordWPG;
 ImageHeight:=ReadWordWPG;
 BitsPerPixel:=ReadWordWPG;
 XRes:=ReadWordWPG;
 YRes:=ReadWordWPG;
 If(XRes=0)or(YRes=0)Then Begin
 End;

 If(BitsPerPixel<>1)and(BitsPerPixel<>4)and(BitsPerPixel<>8)Then Begin
  WriteLn('Seuls les WPG 1, 4 ou 8 bits sont supportes par ce visualiseur !');
  Close(SourceWPG);
  Halt;
 End;
 If(ImageWidth=0)or(ImageHeight=0)or(ImageWidth>MaxWidth)Then Begin
  WriteLn('Dimensions WPG invalides ou trop larges !');
  Close(SourceWPG);
  Halt;
 End;
 WPGBytesPerLine:=BytesPerLine(ImageWidth,BitsPerPixel);
 If WPGBytesPerLine>SizeOf(LineBuf)Then Begin
  WriteLn('Ligne WPG trop large !');
  Close(SourceWPG);
  Halt;
 End;

 EnsureScr;
 For LineY:=0 to ImageHeight-1 Do Begin
  DecodeWPGLine(WPGBytesPerLine);
  DrawLine(LineY);
 End;
End;

Function ScaleX(Value:Word):Integer;
Begin
 EnsureScr;
 If PictureWidth=0 Then PictureWidth:=ImageWidth;
 If PictureWidth=0 Then PictureWidth:=1;
 ScaleX:=Integer((LongInt(Value)*LongInt(GetMaxX))div LongInt(PictureWidth));
End;

Function ScaleY(Value:Word):Integer;
Begin
 EnsureScr;
 If PictureHeight=0 Then PictureHeight:=ImageHeight;
 If PictureHeight=0 Then PictureHeight:=1;
 ScaleY:=GetMaxY-Integer((LongInt(Value)*LongInt(GetMaxY))div LongInt(PictureHeight));
End;

Procedure ReadStartRecord(Len:LongInt);
Var
 Version,Flags:Byte;
Begin
 If Len>=6 Then Begin
  ReadByte(Version);
  ReadByte(Flags);
  PictureWidth:=ReadWordWPG;
  PictureHeight:=ReadWordWPG;
  If Version=0 Then Begin
  End;
  If Flags=0 Then Begin
  End;
 End;
End;

Procedure ReadFillAttr(Len:LongInt);
Var
 Style,ColorIndex:Byte;
Begin
 If Len>=2 Then Begin
  ReadByte(Style);
  ReadByte(ColorIndex);
  CurrentLineColor:=PalColor(ColorIndex);
  If Style=0 Then Begin
  End;
 End;
End;

Procedure ReadLineAttr(Len:LongInt);
Var
 Style,ColorIndex:Byte;
 W:Word;
Begin
 If Len>=2 Then Begin
  ReadByte(Style);
  ReadByte(ColorIndex);
  CurrentLineColor:=PalColor(ColorIndex);
  If Len>=4 Then W:=ReadWordWPG Else W:=0;
  If(Style=0)or(W=0)Then Begin
  End;
 End;
End;

Procedure ReadPointList(Len:LongInt;CloseShape:Boolean);
Var
 Count:Word;
 I:Word;
 PX,PY:Word;
 FirstX,FirstY:Word;
 PrevX,PrevY:Word;
 SX,SY:Integer;
 PrevSX,PrevSY:Integer;
 FirstSX,FirstSY:Integer;
Begin
 If Len<2 Then Exit;
 Count:=ReadWordWPG;
 If(LongInt(Count)*4+2)>Len Then Exit;
 If Count=0 Then Exit;
 EnsureScr;
 SetColor(CurrentLineColor);
 ReadByte(B); Seek(SourceWPG,FilePos(SourceWPG)-1);
 For I:=0 to Count-1 Do Begin
  PX:=ReadWordWPG;
  PY:=ReadWordWPG;
  SX:=ScaleX(PX);
  SY:=ScaleY(PY);
  If I=0 Then Begin
   FirstX:=PX;
   FirstY:=PY;
   PrevX:=PX;
   PrevY:=PY;
   FirstSX:=SX;
   FirstSY:=SY;
   PrevSX:=SX;
   PrevSY:=SY;
  End
   Else
  Begin
   Line(PrevSX,PrevSY,SX,SY);
   PrevX:=PX;
   PrevY:=PY;
   PrevSX:=SX;
   PrevSY:=SY;
  End;
 End;
 If CloseShape and(Count>1)Then Line(PrevSX,PrevSY,FirstSX,FirstSY);
 If(FirstX=PrevX)and(FirstY=PrevY)Then Begin
 End;
End;

Procedure ReadRectangleRecord(Len:LongInt);
Var
 X1,Y1,W,H:Word;
 SX1,SY1,SX2,SY2,T:Integer;
Begin
 If Len<8 Then Exit;
 X1:=ReadWordWPG;
 Y1:=ReadWordWPG;
 W:=ReadWordWPG;
 H:=ReadWordWPG;
 EnsureScr;
 SetColor(CurrentLineColor);
 SX1:=ScaleX(X1);
 SY1:=ScaleY(Y1);
 SX2:=ScaleX(Word(LongInt(X1)+LongInt(W)));
 SY2:=ScaleY(Word(LongInt(Y1)+LongInt(H)));
 If SX1>SX2 Then Begin T:=SX1; SX1:=SX2; SX2:=T; End;
 If SY1>SY2 Then Begin T:=SY1; SY1:=SY2; SY2:=T; End;
 Rectangle(SX1,SY1,SX2,SY2);
End;

Procedure CheckHeader;
Var
 Magic:Array[0..3]of Byte;
 DataOffset:LongInt;
 ProductType,FileType,Major,Minor:Byte;
 Dummy:Word;
Begin
 BlockRead(SourceWPG,Magic,4,ByteReaded);
 If ByteReaded<>4 Then Begin
  WriteLn('Entete WPG incomplet !');
  Close(SourceWPG);
  Halt;
 End;
 If(Magic[0]<>WPGMagic0)or(Magic[1]<>WPGMagic1)or
   (Magic[2]<>WPGMagic2)or(Magic[3]<>WPGMagic3)Then Begin
  WriteLn('Signature d''entete WPG introuvable !');
  Close(SourceWPG);
  Halt;
 End;
 DataOffset:=ReadLongBE;
 If(DataOffset<16)or(DataOffset>FileSize(SourceWPG))Then Begin
  Seek(SourceWPG,4);
  UseLittleEndian:=True;
  DataOffset:=ReadLongLE;
 End
  Else
 UseLittleEndian:=False;
 ReadByte(ProductType);
 ReadByte(FileType);
 ReadByte(Major);
 ReadByte(Minor);
 Dummy:=ReadWordBE;
 Dummy:=ReadWordBE;
 If Dummy=0 Then Begin
 End;
 If DataOffset>FilePos(SourceWPG)Then Seek(SourceWPG,DataOffset);
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('VIEWWPG : Cette commande permet de visualiser une image WordPerfect Graphics (.WPG).');
  WriteLn;
  WriteLn('Syntaxe : VIEWWPG nomdufichier.WPG');
  WriteLn;
  WriteLn(' nomdufichier   Ce parametre permet d''indiquer le nom du fichier ".WPG".');
  Halt;
 End;
 If ParamCount<1 Then Begin
  WriteLn('Parametre requis !');
  Halt;
 End;

 SourceFileName:=ParamStr(1);
 {$I-}Assign(SourceWPG,SourceFileName);
 Reset(SourceWPG,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier WPG : ',SourceFileName);
  Halt;
 End;

 FillChar(Palette,SizeOf(Palette),0);
 NumPal:=0;
 PictureWidth:=0;
 PictureHeight:=0;
 CurrentLineColor:=White;
 ScreenReady:=False;
 CheckHeader;
 Done:=False;
 While(Not EOF(SourceWPG))and(Not Done)Do Begin
  ReadByte(RecType);
  RecLen:=ReadRecLength;
  RecStartPos:=FilePos(SourceWPG);
  Case RecType of
   WPGRecStart:ReadStartRecord(RecLen);
   WPGRecColorMap:ReadColorMap(RecLen);
   WPGRecBitmap1:ReadBitmap1(RecLen);
   WPGRecFillAttr:ReadFillAttr(RecLen);
   WPGRecLineAttr:ReadLineAttr(RecLen);
   WPGRecPolyline:ReadPointList(RecLen,False);
   WPGRecPolygon:ReadPointList(RecLen,True);
   WPGRecRectangle:ReadRectangleRecord(RecLen);
   WPGRecEnd:Done:=True;
   Else Begin
   End;
  End;
  If FilePos(SourceWPG)<RecStartPos+RecLen Then
   SkipBytes(RecStartPos+RecLen-FilePos(SourceWPG));
 End;

 Close(SourceWPG);
 If(ReadKey=#0)Then Begin
  If(ReadKey<>#0)Then Begin
  End;
 End;
END.
