{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program VIEWSVG;

{$A-}

Uses {$IFDEF FPC}
      Crt,PtcGraph,PtcCrt,PtcMouse
     {$ELSE}
      Crt,Graph
     {$ENDIF};

Var
 SourceSVG:Text;
 ColorSetted:Boolean;
 C:Char;
 Err:Word;
 CurrColor,Color:LongInt;
 IP,I,X,Y,X1,Y1,X2,Y2,Width,Height,CX,CY,R,RX,RY:Integer;
 OpenTag,OpenStr:Integer;
 CurrTag:(_None,_SVG,_Circle,_Ellipse,_Line,_Polyline,
          _Rect,_Text,_CloseText);
 CurrParam:(__None,_X,_Y,_X1,_Y1,_X2,_Y2,_Fill,_Points,
            _CX,_CY,_R,_RX,_RY,_Stroke,_Width,_Height);
 SubCurrParam:(_None_,_X_,_Y_);
 CurrPoints,CurrWord,CurrString,TextString:String;
 PointsParam:Array[1..255]of PointType;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function ColorToValue(S:String):LongInt;
Var
 X:LongInt;
Begin
 If StrToUpper(S)='BLACK'Then ColorToValue:=0 Else
 If StrToUpper(S)='BLUE'Then ColorToValue:=1 Else
 If StrToUpper(S)='GREEN'Then ColorToValue:=2 Else
 If StrToUpper(S)='MAGENTA'Then ColorToValue:=13 Else
 If StrToUpper(S)='RED'Then ColorToValue:=12 Else
 If StrToUpper(S)='YELLOW'Then ColorToValue:=14 Else
 If StrToUpper(S)='WHITE'Then ColorToValue:=15
  Else
 Begin
  Val(S,X,Err);
  ColorToValue:=X;
 End;
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
  SetBkColor(White);
  ClearDevice;
  SetColor(8);
  CurrColor:=8;
  SetLineStyle(0,0,1);
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
  WriteLn('VIEWSVG : Cette commande permet de visualiser un image de format SVG');
  WriteLn;
  WriteLn('Syntaxe : VIEWSVG nomdufichier.SVG');
  WriteLn;
  WriteLn(' nomdufichier   Ce paramŠtre permet d''indiquer le nom du fichier ".SVG".');
 End
  Else
 If ParamCount>0Then Begin
  {$I-}Assign(SourceSVG,ParamStr(1));
  Reset(SourceSVG);{$I+}
  If IOResult=0 Then Begin
   InitScr;
   FillChar(PointsParam,SizeOf(PointsParam),0);
   CurrWord:='';
   CurrString:='';
   TextString:='';
   OpenTag:=0;
   OpenStr:=0;
   CurrTag:=_None;
   CurrParam:=__None;
   While Not EOF(SourceSVG)do Begin
    Read(SourceSVG,C);
    If C='<'Then Inc(OpenTag)Else
    If C='>'Then Begin
     If OpenTag>0Then Begin
      If StrToUpper(CurrWord)='/TEXT'Then CurrTag:=_CloseText;
      Dec(OpenTag);
     End;
     Case CurrTag of
      _Circle:Circle(CX,CY,R);
      _Ellipse:Ellipse(CX,CY,0,360,RX,RY);
      _CloseText:Begin
       OutTextXY(X,Y,TextString);
       TextString:='';
      End;
      _Line:Begin
       If(ColorSetted)Then SetColor(Color)
                      Else SetColor(CurrColor);
       Line(X1,Y1,X2,Y2);
      End;
      _Polyline:Begin
       SetColor(Color);
       DrawPoly(IP,PointsParam);
       SetColor(CurrColor);
      End;
      _Rect:Rectangle(X,Y,X+Width,Y+Height);
     End;
     CurrTag:=_None;
     CurrParam:=__None;
     CurrWord:='';
     CurrString:='';
     FillChar(PointsParam,SizeOf(PointsParam),0);
    End
     Else
    If C='"'Then Begin
     If OpenStr>0 Then Begin
      OpenStr:=0;
      Case CurrTag of
       _Circle:Case CurrParam of
        _CX:Val(CurrString,CX,Err);
        _CY:Val(CurrString,CY,Err);
        _R:Val(CurrString,R,Err);
       End;
       _Ellipse:Case CurrParam of
        _CX:Val(CurrString,CX,Err);
        _CY:Val(CurrString,CY,Err);
        _RX:Val(CurrString,RX,Err);
        _RY:Val(CurrString,RY,Err);
        _Stroke:Begin
         Color:=ColorToValue(CurrString);
         ColorSetted:=True;
        End;
       End;
       _Line:Case CurrParam of
        _X1:Val(CurrString,X1,Err);
        _Y1:Val(CurrString,Y1,Err);
        _X2:Val(CurrString,X2,Err);
        _Y2:Val(CurrString,Y2,Err);
        _Stroke:Begin
         Color:=ColorToValue(CurrString);
         ColorSetted:=True;
        End;
       End;
       _Polyline:Case CurrParam of
        _Points:Begin
         CurrPoints:='';
         SubCurrParam:=_X_;
         IP:=1;
         For I:=1 to Length(CurrString)do Begin
          If CurrString[I]=' 'Then Begin
           Case SubCurrParam of
            _X_:Begin
             Val(CurrPoints,PointsParam[IP].X,Err);
             SubCurrParam:=_Y_;
            End;
            _Y_:Begin
             Val(CurrPoints,PointsParam[IP].Y,Err);
             SubCurrParam:=_X_;
             Inc(IP);
            End;
           End;
           CurrPoints:='';
          End
           Else
          CurrPoints:=CurrPoints+CurrString[I];
         End;
         If CurrPoints<>''Then Begin
          Case SubCurrParam of
           _X_:Begin
            Val(CurrPoints,PointsParam[IP].X,Err);
            SubCurrParam:=_Y_;
           End;
           _Y_:Begin
            Val(CurrPoints,PointsParam[IP].Y,Err);
            SubCurrParam:=_X_;
            Inc(IP);
           End;
          End;
          CurrPoints:='';
         End
        End;
        _Stroke:Begin
         Color:=ColorToValue(CurrString);
         ColorSetted:=True;
        End;
       End;
       _Rect:Case CurrParam of
        _X:Val(CurrString,X,Err);
        _Y:Val(CurrString,Y,Err);
        _HEIGHT:Val(CurrString,Height,Err);
        _WIDTH:Val(CurrString,Width,Err);
       End;
       _Text:Case CurrParam of
        _X:Val(CurrString,X,Err);
        _Y:Val(CurrString,Y,Err);
       End;
      End;
     End
      Else
     Begin
      OpenStr:=1;
      CurrString:='';
     End;
    End
     Else
    If OpenStr>0 Then Begin
     CurrString:=CurrString+C;
    End
     Else
    If OpenTag>0 Then Begin
     If C in[#9,' ','=']Then Begin
      Case CurrTag of
       _None:Begin
        If StrToUpper(CurrWord)='CIRCLE'Then CurrTag:=_Circle Else
        If StrToUpper(CurrWord)='ELLIPSE'Then CurrTag:=_Ellipse Else
        If StrToUpper(CurrWord)='LINE'Then Begin
         CurrTag:=_Line;
         Color:=CurrColor;
         ColorSetted:=False;
        End
         Else
        If StrToUpper(CurrWord)='POLYLINE'Then Begin
         ColorSetted:=False;
         Color:=CurrColor;
         CurrTag:=_Polyline;
        End
         Else
        If StrToUpper(CurrWord)='RECT'Then CurrTag:=_Rect Else
        If StrToUpper(CurrWord)='TEXT'Then CurrTag:=_Text;
       End;
       _Circle:Begin
        If StrToUpper(CurrWord)='CX'Then CurrParam:=_CX Else
        If StrToUpper(CurrWord)='CY'Then CurrParam:=_CY Else
        If StrToUpper(CurrWord)='R'Then CurrParam:=_R;
       End;
       _Ellipse:Begin
        If StrToUpper(CurrWord)='CX'Then CurrParam:=_CX Else
        If StrToUpper(CurrWord)='CY'Then CurrParam:=_CY Else
        If StrToUpper(CurrWord)='RX'Then CurrParam:=_RX Else
        If STrToUpper(CurrWord)='RY'Then CurrParam:=_RY Else
        If StrToUpper(CurrWord)='STROKE'Then CurrParam:=_Stroke;         ColorSetted:=True;
       End;
       _Line:Begin
        If StrToUpper(CurrWord)='X1'Then CurrParam:=_X1 Else
        If StrToUpper(CurrWord)='Y1'Then CurrParam:=_Y1 Else
        If StrToUpper(CurrWord)='X2'Then CurrParam:=_X2 Else
        If STrToUpper(CurrWord)='Y2'Then CurrParam:=_Y2 Else
        If StrToUpper(CurrWord)='STROKE'Then CurrParam:=_Stroke;
       End;
       _Polyline:Begin
        If StrToUpper(CurrWord)='FILL'Then CurrParam:=_Fill Else
        If StrToUpper(CurrWord)='POINTS'Then CurrParam:=_Points Else
        If StrToUpper(CurrWord)='STROKE'Then CurrParam:=_Stroke;
       End;
       _Rect:Begin
        If StrToUpper(CurrWord)='X'Then CurrParam:=_X Else
        If StrToUpper(CurrWord)='Y'Then CurrParam:=_Y Else
        If StrToUpper(CurrWord)='HEIGHT'Then CurrParam:=_Height Else
        If StrToUpper(CurrWord)='WIDTH'Then CurrParam:=_Width;
       End;
       _Text:Begin
        If StrToUpper(CurrWord)='X'Then CurrParam:=_X Else
        If StrToUpper(CurrWord)='Y'Then CurrParam:=_Y;
       End;
      End;
      CurrWord:='';
     End
      Else
     CurrWord:=CurrWord+C;
    End
     Else
    If Not(C in[#13,#10])Then TextString:=TextString+C;
   End;
   Close(SourceSVG);
  If(ReadKey=#0)Then Begin
   If(ReadKey<>#0)Then Begin
   End;
  End;
  End;
 End;
END.
