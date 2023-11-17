{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program XBM2BAS;

Var
 SourceXBM:Text;
 ImageWidth,ImageHeight:Word;
 SourceFileName,CurrLine,CurrWord,CurrValue:String;
 R,G,B:Byte;
 Buffer:Array[0..4095]of Byte;
 I,Value,BytesPerLine,BitsPerPixel,CountByLine:Integer;
 Err:Word;
 CurrData,CountData:LongInt;
 CurrLineNumber:LongInt;

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

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('XBM2BAS : Cette commande permet de convertir une image ',
                     'de format XBM (X BitMap) en code source Basic.');
  WriteLn;
  WriteLn('Syntaxe : XBM2BAS nomdufichier.XBM');
  WriteLn;
  WriteLn(' nomdufichier   Ce paramŠtre permet d''indiquer le nom du fichier XBM.');
 End
  Else
 If ParamCount>0Then Begin
  CurrLineNumber:=70;
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
  WriteLn('10 NumXPixels%=',ImageWidth);
  WriteLn('20 NumYPixels%=',ImageHeight);
  WriteLn('30 BitsPerPixel%=',BitsPerPixel);
  WriteLn('40 BytesPerLine%=',BytesPerLine);
  WriteLn('50 ''BitmapData');
  Write('60 DATA ');
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
        Write('&H',ByteHex2Str(Value));
        Inc(CurrData);
        Inc(CountByLine);
        If(CountByLine>12)Then Begin
         WriteLn;
         Write(CurrLineNumber,' DATA ');
         CountByLine:=0;
         Inc(CurrLineNumber,10);
        End
         Else
        Write(',');
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
      Write('&H',ByteHex2Str(Value));
      Inc(CurrData);
      Inc(CountByLine);
      If(CountByLine>12)Then Begin
       WriteLn;
       Write(CurrLineNumber,' DATA ');
       CountByLine:=0;
       Inc(CurrLineNumber,10);
      End
       Else
      If(CurrData<CountData)Then Write(',');
     End;
    End;
   End;
   WriteLn;
   Close(SourceXBM);
  End;
 End
  Else
 WriteLn('ParamŠtre attendu !');
END.