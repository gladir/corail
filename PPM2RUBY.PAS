{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program PPM2RUBY;

Uses DOS;

Type
 RGB=Record
  R,G,B:Byte;
 End;

Var
 SourcePPM:File;
 SourceFileName,CurrWord,ImageName:String;
 ImageWidth,ImageHeight,ByteReaded:Word;
 Value,BytesPerLine,BitsPerPixel,LineCount,StepCount,CountByLine:Integer;
 Err:Word;
 CurrChar:Char;
 First:Boolean;
 RGBBuffer:RGB;

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


BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('PPM2RUBY : Cette commande permet de convertir une image ',
                     'de format PPM (Portable PixMap) en code source Ruby.');
  WriteLn;
  WriteLn('Syntaxe : PPM2RUBY nomdufichier.PPM');
  WriteLn;
  WriteLn(' nomdufichier   Ce paramätre permet d''indiquer le nom du fichier PPM.');
 End
  Else
 If ParamCount>0Then Begin
  SourceFileName:=ParamStr(1);
  ImageName:=Path2Name(SourceFileName);
  ImageWidth:=0;
  ImageHeight:=0;
  {$I-}Assign(SourcePPM,SourceFileName);
  Reset(SourcePPM,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible d''ouvrir le fichier PPM : ',SourceFileName);
   Halt;
  End;
  LineCount:=0;StepCount:=0;
  CurrWord:='';
  While Not(EOF(SourcePPM))do Begin
   BlockRead(SourcePPM,CurrChar,1,ByteReaded);
   If CurrChar in[#10,' ']Then Begin
    Inc(StepCount);
    Case(StepCount)of
     1:If Not((CurrWord='P5')or(CurrWord='P6'))Then Begin
      WriteLn('Seul les formats P5 et P6 de PPM sont reconnu !');
      Halt;
     End;
     2:Val(CurrWord,ImageWidth,Err);
     3:Val(CurrWord,IMageHeight,Err);
     4:Val(CurrWord,Value,Err);
    End;
    CurrWord:='';
   End
    Else
   CurrWord:=CurrWord+CurrChar;
   If CurrChar=#10 Then Inc(LineCount);
   If LineCount>=3 Then Break;
  End;
  BytesPerLine:=ImageWidth*3;
  WriteLn('numxpixels = ',ImageWidth);
  WriteLn('numypixels = ',ImageHeight);
  WriteLn('bitsperpixel = 24');
  WriteLn('bytesperline = ',BytesPerLine);
  WriteLn('bitmapdata = [');
  First:=True;
  CountByLine:=0;
  While Not(EOF(SourcePPM))do Begin
    If Not(First)Then Write(',');
    If CountByLine>3 Then Begin
     WriteLn;
     CountByLine:=0;
    End
     Else
    Inc(CountByLine);
    BlockRead(SourcePPM,RGBBuffer,SizeOf(RGB),ByteReaded);
    Write(RGBBuffer.R,',');
    Write(RGBBuffer.G,',');
    Write(RGBBuffer.B);
    First:=False;
  End;
  WriteLn;
  WriteLn(']');
  Close(SourcePPM);
 End
  Else
 WriteLn('Paramätre attendu !');
END.

