{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program VIEWXBM;

Uses {$IFDEF FPC}
      Crt,PtcGraph,PtcCrt,PtcMouse
     {$ELSE}
      Crt,Graph
     {$ENDIF};

Var
 SourceXBM:Text;
 ImageWidth,ImageHeight:Word;
 SourceFileName,CurrLine,CurrWord,CurrValue:String;
 Buffer:Array[0..4095]of Byte;
 I,Value,BytesPerLine,BitsPerPixel:Integer;
 Err:Word;
 CountData:LongInt;
 PixelX,PixelY:Word;

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

Procedure AddPixel;Begin
 Case(BitsPerPixel)of
  4:Begin
   PutPixel(PixelX,PixelY,Value shr 4);
   PutPixel(PixelX+1,PixelY,Value and $F);
   If(PixelX+4<=ImageWidth)Then Inc(PixelX,2)
    Else
   Begin
    PixelX:=0;
    Inc(PixelY);
   End;
  End;
  8:Begin
   PutPixel(PixelX,PixelY,Value);
   If(PixelX+2<=ImageWidth)Then Inc(PixelX)
    Else
   Begin
    PixelX:=0;
    Inc(PixelY);
   End;
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
  WriteLn('VIEWXBM : Cette commande permet de visualiser une image ',
                     'en format XBM (X BitMap).');
  WriteLn;
  WriteLn('Syntaxe : VIEWXBM nomdufichier.XBM');
  WriteLn;
  WriteLn(' nomdufichier   Ce paramätre permet d''indiquer le nom du fichier XBM.');
 End
  Else
 If ParamCount>0Then Begin
  SourceFileName:=ParamStr(1);
  ImageWidth:=0;
  ImageHeight:=0;
  CountData:=0;
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
     { Saute la ligne, ne pas s'en occupÇ }
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
   WriteLn('Bits par pixel non supportÇ');
   Halt;
  End;
  InitScr;
  PixelX:=0;
  PixelY:=0;
  {$I-}Assign(SourceXBM,SourceFileName);
  Reset(SourceXBM);{$I+}
  If IOResult=0 Then Begin
   While Not EOF(SourceXBM)do Begin
    ReadLn(SourceXBM,CurrLine);
    CurrLine:=Trim(CurrLine);
    If Copy(CurrLine,1,8)='#define 'Then Begin
     { Saute la ligne, ne pas s'en occupÇ }
    End
     Else
    If Copy(CurrLine,1,7)='static 'Then Begin
     { Saute la ligne, ne pas s'en occupÇ }
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
     End;
    End;
   End;
   Close(SourceXBM);
   If(ReadKey=#0)Then Begin
    If(ReadKey<>#0)Then Begin
    End;
   End;
  End;
 End
  Else
 WriteLn('Paramätre attendu !');
END.