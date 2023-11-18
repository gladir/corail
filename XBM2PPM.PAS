{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program XBM2PPM;

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

Var
 SourceXBM:Text;
 TargetPPM:File;
 HeaderStr:String;
 ImageWidth,ImageHeight,ByteReaded,ByteWrited:Word;
 SourceFileName,CurrLine,CurrWord,CurrValue:String;
 R,G,B:Byte;
 I,Value,BytesPerLine,BitsPerPixel,CountByLine:Integer;
 Err:Word;
 CurrData,CountData:LongInt;
 RGBBuffer:RGB;

Function IntToStr(I:Integer):String;
Var
 S:String;
Begin
 Str(I,S);
 IntToStr:=S;
End;

Function TrimL(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If S[I]<>' 'Then Begin
   TrimL:=Copy(S,I,255);
   Exit;
  End;
 End;
 TrimL:=S;
End;

Function TrimR(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 TrimR:=S;
End;

Function Trim(s:String):String;Begin
 Trim:=TrimL(TrimR(s));
End;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;


Function Hex2Integer(hexStr:String):LongInt;
Var
 hexVal:LongInt;
 evalErr:Boolean;
 i,n:LongInt;
Begin
 Err:=0;
 evalErr:=False;
 hexVal:=0;
 For i:=1 to Length(hexStr) do Begin
  n:=Pos(Upcase(hexStr[i]),'0123456789ABCDEF');
  If n=0 Then evalErr:=True
         Else hexVal:=hexVal*16+n-1;
 End;
 If evalErr Then Begin
  hexVal:=0;
  Err:=1;
 End;
 Hex2Integer:=hexVal;
End;

Procedure AddPixel;
Var
 Hi4,Lo4:Byte;
Begin
 Case BitsPerPixel of
  15:Begin
   RGBBuffer.R:=((Value shr 10)and 31) shr 2;
   RGBBuffer.G:=((Value shr 5)and 31) shl 2;
   RGBBuffer.B:=((Value)and 31) shl 2;
   BlockWrite(TargetPPM,RGBBuffer,SizeOf(RGBBuffer),ByteWrited);
  End;
  16:Begin
   RGBBuffer.R:=((Value shr 10)and 31) shr 3;
   RGBBuffer.G:=((Value shr 5)and 31) shl 3;
   RGBBuffer.B:=((Value)and 31) shl 3;
   BlockWrite(TargetPPM,RGBBuffer,SizeOf(RGBBuffer),ByteWrited);
  End;
  8,24:Begin
   BlockWrite(TargetPPM,Value,SizeOf(Byte),ByteWrited);
  End;
  4:Begin
   Hi4:=Value shr 4;
   Lo4:=Value and $F;
   RGBBuffer.R:=DefaultRGB[Hi4].R;
   RGBBuffer.G:=DefaultRGB[Hi4].G;
   RGBBuffer.B:=DefaultRGB[Hi4].B;
   BlockWrite(TargetPPM,RGBBuffer,SizeOf(RGBBuffer),ByteWrited);
   RGBBuffer.R:=DefaultRGB[Lo4].R;
   RGBBuffer.G:=DefaultRGB[Lo4].G;
   RGBBuffer.B:=DefaultRGB[Lo4].B;
   BlockWrite(TargetPPM,RGBBuffer,SizeOf(RGBBuffer),ByteWrited);
  End;
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('XBM2PPM : Cette commande permet de convertir une image ',
                     'de format XBM (X BitMap) en format PPM (Portable PixMap).');
  WriteLn;
  WriteLn('Syntaxe : XBM2PPM source.XBM dest.PPM');
  WriteLn;
  WriteLn(' source   Ce paramŠtre permet d''indiquer le nom du fichier XBM.');
  WriteLn(' dest     Ce paramŠtre permet d''indiquer le nom du fichier PPM.');
 End
  Else
 If ParamCount>0Then Begin
  SourceFileName:=ParamStr(1);
  ImageWidth:=0;
  ImageHeight:=0;
  CurrData:=0;
  {$I-}Assign(SourceXBM,SourceFileName);
  Reset(SourceXBM);{$I+}
  If IOResult=0 Then Begin
   While Not EOF(SourceXBM)do Begin
    ReadLn(SourceXBM,CurrLine);
    CurrLine:=Trim(CurrLine);
    If Copy(CurrLine,1,8)='#define 'Then Begin
     I:=9;
     While(CurrLine[I]in[' ',#9])and(I<=Length(CurrLine))do Inc(I);
     While(CurrLine[I]<>'_')and(I<=Length(CurrLine))do Inc(I);
     Inc(I);
     CurrWord:='';
     While(CurrLine[I]<>' ')and(I<=Length(CurrLine))do Begin
      CurrWord:=CurrWord+CurrLine[I];
      Inc(I);
     End;
     While(CurrLine[I]in[' ',#9])and(I<=Length(CurrLine))do Inc(I);
     CurrValue:=Copy(CurrLine,I,255);
     If CurrWord='width'Then Val(CurrValue,ImageWidth,Err) Else
     If CurrWord='height'Then Val(CurrValue,ImageHeight,Err);
    End
     Else
    If Copy(CurrLine,1,7)='static 'Then Begin
     { Saute la ligne, ne pas s'en occup‚ }
    End
     Else
    Begin
     For I:=1 to Length(CurrLine)do Begin
      If CurrLine[I]in[',','}']Then Inc(CountData);
     End;
    End;
   End;
   Close(SourceXBM);
  End;
  BytesPerLine:=Trunc(CountData/ImageHeight);
  If BytesPerLine=ImageWidth*4 Then BitsPerPixel:=32 Else
  If BytesPerLine=ImageWidth*3 Then BitsPerPixel:=24 Else
  If BytesPerLine=ImageWidth*2 Then BitsPerPixel:=16 Else
  If BytesPerLine=ImageWidth Then BitsPerPixel:=8 Else
  If BytesPerLine*2=ImageWidth Then BitsPerPixel:=4
   Else
  Begin
   WriteLn('Bits par pixel non support‚');
   Halt;
  End;
  CountData:=0;
  {$I-}Assign(SourceXBM,SourceFileName);
  Reset(SourceXBM);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de lire le fichier XBM : ',SourceFileName);
   Halt;
  End;
  {$I-}Assign(TargetPPM,ParamStr(2));
  Rewrite(TargetPPM,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible d''‚crire le fichier PPM : ',ParamStr(2));
   Halt;
  End;
  HeaderStr:='P6'#10+IntToStr(ImageWidth)+' '+
           IntToStr(ImageHeight)+#10+
           IntToStr(255)+#10;
  BlockWrite(TargetPPM,HeaderStr[1],Length(HeaderStr),ByteWrited);
  CountByLine:=0;
  If IOResult=0 Then Begin
   While Not EOF(SourceXBM)do Begin
    ReadLn(SourceXBM,CurrLine);
    CurrLine:=Trim(CurrLine);
    If Copy(CurrLine,1,8)='#define 'Then Begin
     { Saute la ligne, ne pas s'en occup‚ }
    End
     Else
    If Copy(CurrLine,1,7)='static 'Then Begin
     { Saute la ligne, ne pas s'en occup‚ }
    End
     Else
    Begin
     CurrWord:='';
     For I:=1 to Length(CurrLine)do Begin
      If CurrLine[I]in[',','}',';']Then Begin
       If CurrWord<>''Then Begin
        If Copy(CurrWord,1,2)='0x'Then Begin
         Value:=Hex2Integer(Copy(CurrWord,3,255));
        End
         Else
        Val(CurrWord,Value,Err);
        AddPixel;
        Inc(CurrData);
        If(CurrData<CountData)Then Write(',');
        Inc(CountByLine);
        If(CountByLine>16)Then Begin
         CountByLine:=0;
        End;
        CurrWord:='';
       End;
      End
       Else
      CurrWord:=CurrWord+CurrLine[I];
     End;
     If CurrWord<>''Then Begin
      If Copy(CurrWord,1,2)='0x'Then Begin
       Value:=Hex2Integer(Copy(CurrWord,3,255));
      End
       Else
      Val(CurrWord,Value,Err);
      AddPixel;
      Inc(CurrData);
      If(CurrData<CountData)Then Write(',');
      Inc(CountByLine);
      If(CountByLine>16)Then Begin
       CountByLine:=0;
      End;
     End;
    End;
   End;
   Close(TargetPPM);
   Close(SourceXBM);
  End;
 End
  Else
 WriteLn('ParamŠtre attendu !');
END.

