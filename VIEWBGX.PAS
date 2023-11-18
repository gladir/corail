{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program VIEWBGX;

{$A-}

Uses {$IFDEF FPC}
      Crt,PtcGraph,PtcCrt,PtcMouse
     {$ELSE}
      Crt,Graph
     {$ENDIF};

Type
 {Entàte d'un format d'image BGX }
 BGXHeader=Record
  Sign:Array[0..3]of Char;   { Signature }
  NumXPixels,NumYPixels:Word;{ Nombre de pixels horizontal et vertical }
  BitsPerPixel:Byte;         { Nombre de bits par pixel }
 End;

Var
 SourceBGX:File;
 Header:BGXHeader;
 Size,I,J,K,Min,Max,BytesPerLine,ByteReaded:Word;
 Buffer:Array[0..4095]of Byte;

Function LenNBits2BytesPerLine(Width:Word;Bits4Pixel:Byte):Word;Near;Begin
 Case(Bits4Pixel)of
  1:LenNBits2BytesPerLine:=Width shr 3;
  2:LenNBits2BytesPerLine:=Width shr 2;
  4:LenNBits2BytesPerLine:=Width shr 1;
  9..16:LenNBits2BytesPerLine:=Width shl 1;
  17..24:LenNBits2BytesPerLine:=Width*3;
  25..32:LenNBits2BytesPerLine:=Width shl 2;
  33..64:LenNBits2BytesPerLine:=Width shl 4;
  Else LenNBits2BytesPerLine:=Width;
 End;
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

Function TrueColor15To16Color(Value:Word):Integer;Begin
 TrueColor15To16Color:=((Value shr 10)and 31)+  { Rouge }
                       ((Value shr 5)and 31)+ { Vert }
                       ((Value)and 31); { Blue }
End;

Function TrueColor16To16Color(Value:Word):Integer;Begin
 TrueColor16To16Color:=((Value shr 11)and 31)+  { Rouge }
                       ((Value shr 6)and 31)+ { Vert }
                       ((Value shr 1)and 31); { Blue }
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

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('VIEWBGX : Cette commande permet de visualiser une image BGX');
  WriteLn;
  WriteLn('Syntaxe : VIEWBGX nomdufichier.BGX');
  WriteLn;
  WriteLn(' nomdufichier   Ce paramätre permet d''indiquer le nom du fichier ".BGX".');
 End
  Else
 If ParamCount>0Then Begin
  {$I-}Assign(SourceBGX,ParamStr(1));
  Reset(SourceBGX,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de lire le fichier d''image BGX');
   Halt;
  End;
  BlockRead(SourceBGX,Header,SizeOf(Header),ByteReaded);
  BytesPerLine:=LenNBits2BytesPerLine(Header.NumXPixels,Header.BitsPerPixel);
  If BytesPerLine>SizeOf(Buffer)Then Begin
   WriteLn('Ligne trop large pour àtre lu');
   Halt;
  End;
  InitScr;
  For J:=0to Header.NumYPixels-1 do Begin
   BlockRead(SourceBGX,Buffer,BytesPerLine,ByteReaded);
   If ByteReaded=0 Then Break;
   Case Header.BitsPerPixel of
    4:Begin
     For I:=0 to Header.NumXPixels-1 do Begin
      PutPixel(I*2,J,Buffer[I]shr 4);
      PutPixel(I*2+1,J,Buffer[I]and $F);
     End;
    End;
    8:For I:=0 to Header.NumXPixels-1 do PutPixel(I,J,Buffer[I]);
    15:Begin
     For I:=0 to Header.NumXPixels-1 do Begin
      PutPixel(I,J,TrueColor15To16Color(Buffer[I*2]+Buffer[I*2+1]*256));
     End;
    End;
    16:Begin
     For I:=0 to Header.NumXPixels-1 do Begin
      PutPixel(I,J,TrueColor16To16Color(Buffer[I*2]+Buffer[I*2+1]*256));
     End;
    End;
    24:Begin
     For I:=0 to Header.NumXPixels-1 do Begin
      PutPixel(I,J,RGBTo16Color(Buffer[I*3],Buffer[I*3+1],Buffer[I*3+2]));
     End;
    End;
   End;
  End;
  Close(SourceBGX);
  If(ReadKey=#0)Then Begin
   If(ReadKey<>#0)Then Begin
   End;
  End;
 End
  Else
 WriteLn('Paramätre requis !');
END.