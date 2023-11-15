{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program VIEWPPM;

Uses {$IFDEF FPC}
      Crt,PtcGraph,PtcCrt,PtcMouse
     {$ELSE}
      Crt,Graph
     {$ENDIF};

Type
 RGB=Record
  R,G,B:Byte;
 End;

Var
 SourcePPM:File;
 SourceFileName,CurrWord:String;
 ImageWidth,ImageHeight,ByteReaded:Word;
 Value,BitsPerPixel,LineCount,StepCount:Integer;
 Err:Word;
 PixelX,PixelY:Word;
 CurrChar:Char;
 RGBBuffer:RGB;

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

Procedure AddPixel;Begin
 PutPixel(PixelX,PixelY,Value);
 If(PixelX+1<ImageWidth)Then Inc(PixelX)
  Else
 Begin
  PixelX:=0;
  Inc(PixelY);
 End;
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('VIEWPPM : Cette commande permet de visualiser une image ',
                     'en format PPM (Portable PixMap).');
  WriteLn;
  WriteLn('Syntaxe : VIEWPPM nomdufichier.PPM');
  WriteLn;
  WriteLn(' nomdufichier   Ce paramätre permet d''indiquer le nom du fichier PPM.');
 End
  Else
 If ParamCount>0Then Begin
  SourceFileName:=ParamStr(1);
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
  InitScr;
  PixelX:=0;
  PixelY:=0;
  While Not(EOF(SourcePPM))do Begin
    BlockRead(SourcePPM,RGBBuffer,SizeOf(RGB),ByteReaded);
    Value:=RGBTo16Color(RGBBuffer.R,RGBBuffer.G,RGBBuffer.B);
    AddPixel;
  End;
  Close(SourcePPM);
  If(ReadKey=#0)Then Begin
   If(ReadKey<>#0)Then Begin
   End;
  End;
 End
  Else
 WriteLn('Paramätre attendu !');
END.