{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program WebGraph;

Uses {$IFDEF FPC}
      Crt,PtcGraph,PtcCrt,PtcMouse
     {$ELSE}
      Crt,Graph
     {$ENDIF};

Var
 SourceCSV,TargetSVG:Text;
 MakeSVG:Boolean;
 NombreSommet,PosField:Integer;
 Err:Word;
 TailleAngle:Real;
 CenterX,CenterY,XMove,YMove,I,J,Rayon:Integer;
 Web,WebNotes:Array[1..100]of PointType;
 Value:Array[1..100]of Integer;
 ValueMessage:Array[1..100]of String[50];
 FileName,FileNameSVG,CurrLine,CurrWord:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('WEBGRAPH : Cette commande permet d''afficher un graphique ',
                     'en toile d''araign‚e … partir de donn‚es.');
  WriteLn;
  WriteLn('Syntaxe : WEBGRAPH [/FORMAT:SVG] source.csv [target.svg]');
  WriteLn;
  WriteLn(' fichier.csv  Nom du fichier a analyser');
  WriteLn(' target.svg   Nom du fichier allant contenir le SVG');
  WriteLn(' /FORMAT:SVG  Sort le r‚sultat en format SVG.');
 End
  Else
 If ParamCount>0 Then Begin
  MakeSVG:=False;
  NombreSommet:=0;
  FileName:='';
  FileNameSVG:='';
  FillChar(Value,SizeOf(Value),0);
  FillChar(ValueMessage,SizeOf(ValueMessage),#0);
  FillChar(Web,SizeOf(Web),0);
  FillChar(WebNotes,SizeOf(WebNotes),0);
  For I:=1 to ParamCount do Begin
   If(StrToUpper(ParamStr(I))='/SVG')or
     (StrToUpper(ParamStr(I))='/FORMAT:SVG')Then MakeSVG:=True Else
   If FileName=''Then FileName:=ParamStr(I)
                 Else FileNameSVG:=ParamStr(I);
  End;
  If FileName=''Then Begin
   WriteLn('Fichier de donn‚es attendue !');
   Halt;
  End;
  {$I-}Assign(SourceCSV,FileName);
  Reset(SourceCSV);{$I+}
  If IoResult<>0 Then Begin
   WriteLn('Erreur de lecture du fichier CSV !');
   Halt;
  End;
  While Not EOF(SourceCSV)do Begin
   ReadLn(SourceCSV,CurrLine);
   Inc(NombreSommet);
   CurrWord:='';PosField:=0;
   For I:=1 to Length(CurrLine)do Begin
    If CurrLine[I]=','Then Begin
     If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
      If PosField=0 Then ValueMessage[NombreSommet]:=Copy(CurrWord,2,Length(CurrWord)-2)
                    Else Val(Copy(CurrWord,2,Length(CurrWord)-2),Value[NombreSommet],Err);
      Inc(PosField);
     End
      Else
     Begin
      If PosField=0 Then ValueMessage[NombreSommet]:=CurrWord
                    Else Val(CurrWord,Value[NombreSommet],Err);
      Inc(PosField);
     End;
     CurrWord:='';
    End
     Else
    CurrWord:=CurrWord+CurrLine[I];
   End;
   If CurrWord<>''Then Begin
    If PosField=0 Then ValueMessage[NombreSommet]:=CurrWord
                  Else Val(CurrWord,Value[NombreSommet],Err);
   End;
  End;
  Close(SourceCSV);
  If(MakeSVG)Then Begin
   If FileNameSVG<>''Then Begin
    {$I+}Assign(TargetSVG,FileNameSVG);
    Rewrite(TargetSVG);{$I-}
    If IOResult=0 Then Begin
     WriteLn(TargetSVG,'<svg width="640" height="480" xmlns="http://www.w3.org/2000/svg">');
     TailleAngle:=(360/NombreSommet)*0.017453292520;
     CenterX:=320 {(GetMaxX+1) shr 1};
     CenterY:=100 {(GetMaxY+1) shr 1};
     For J:=1 to 5 do Begin
      Rayon:=J*10;
      Write(TargetSVG,'<polyline stroke="black" stroke-width="1" fill="none" points="');
      For I:=1 to NombreSommet do Begin
       XMove:=Trunc(Cos(TailleAngle*I)*Rayon);
       YMove:=Trunc(Sin(TailleAngle*I)*Rayon);
       Web[I].X:=CenterX+XMove;
       Web[I].Y:=CenterY+YMove;
       Write(TargetSVG,Web[I].X,' ',Web[I].Y,' ');
      End;
      Web[NombreSommet+1].X:=Web[1].X;
      Web[NombreSommet+1].Y:=Web[1].Y;
      Write(TargetSVG,Web[NombreSommet+1].X,' ',Web[NombreSommet+1].Y);
      WriteLn(TargetSVG,'"/>');
     End;
     For I:=1 to NombreSommet do Begin
      Rayon:=7*10;
      XMove:=Trunc(Cos(TailleAngle*I)*Rayon);
      YMove:=Trunc(Sin(TailleAngle*I)*Rayon);
      Write(TargetSVG,'<line x1="',CenterX,'" ',
                      'y1="',CenterY,'" ',
                      'x2="',CenterX+XMove,'" ',
                      'y2="',CenterY+YMove,'"/>');
     End;
     For I:=1 to NombreSommet do Begin
      Rayon:=9*10;
      XMove:=Trunc(Cos(TailleAngle*I)*Rayon);
      YMove:=Trunc(Sin(TailleAngle*I)*Rayon);
      Write(TargetSVG,'<text x="',CenterX+XMove,'" y="',CenterY+YMove,'">');
      Write(TargetSVG,ValueMessage[I]);
      WriteLn(TargetSVG,'</text>');
     End;
     Write(TargetSVG,'<polyline stroke="blue" stroke-width="1" fill="none" points="');
     For I:=1 to NombreSommet do Begin
      Rayon:=Value[I]*10;
      XMove:=Trunc(Cos(TailleAngle*I)*Rayon);
      YMove:=Trunc(Sin(TailleAngle*I)*Rayon);
      WebNotes[I].X:=CenterX+XMove;
      WebNotes[I].Y:=CenterY+YMove;
      Write(TargetSVG,WebNotes[I].X,' ',WebNotes[I].Y,' ');
     End;
     WebNotes[NombreSommet+1].X:=WebNotes[1].X;
     WebNotes[NombreSommet+1].Y:=WebNotes[1].Y;
     Write(TargetSVG,WebNotes[NombreSommet+1].X,' ',WebNotes[NombreSommet+1].Y);
     WriteLn(TargetSVG,'"/>');
     WriteLn(TargetSVG,'</svg>');
     Close(TargetSVG);
    End;
   End
    Else
   Begin
    WriteLn('<svg width="640" height="480" xmlns="http://www.w3.org/2000/svg">');
    TailleAngle:=(360/NombreSommet)*0.017453292520;
    CenterX:=320 {(GetMaxX+1) shr 1};
    CenterY:=100 {(GetMaxY+1) shr 1};
    For J:=1 to 5 do Begin
     Rayon:=J*10;
     Write('<polyline stroke="black" stroke-width="1" fill="none" points="');
     For I:=1 to NombreSommet do Begin
      XMove:=Trunc(Cos(TailleAngle*I)*Rayon);
      YMove:=Trunc(Sin(TailleAngle*I)*Rayon);
      Web[I].X:=CenterX+XMove;
      Web[I].Y:=CenterY+YMove;
      Write(Web[I].X,' ',Web[I].Y,' ');
     End;
     Web[NombreSommet+1].X:=Web[1].X;
     Web[NombreSommet+1].Y:=Web[1].Y;
     Write(Web[NombreSommet+1].X,' ',Web[NombreSommet+1].Y);
     WriteLn('"/>');
    End;
    For I:=1 to NombreSommet do Begin
     Rayon:=7*10;
     XMove:=Trunc(Cos(TailleAngle*I)*Rayon);
     YMove:=Trunc(Sin(TailleAngle*I)*Rayon);
     Write('<line x1="',CenterX,'" ',
            'y1="',CenterY,'" ',
            'x2="',CenterX+XMove,'" ',
            'y2="',CenterY+YMove,'"/>');
    End;
    For I:=1 to NombreSommet do Begin
     Rayon:=9*10;
     XMove:=Trunc(Cos(TailleAngle*I)*Rayon);
     YMove:=Trunc(Sin(TailleAngle*I)*Rayon);
     Write('<text x="',CenterX+XMove,'" y="',CenterY+YMove,'">');
     Write(ValueMessage[I]);
     WriteLn('</text>');
    End;
    Write('<polyline stroke="blue" stroke-width="1" fill="none" points="');
    For I:=1 to NombreSommet do Begin
     Rayon:=Value[I]*10;
     XMove:=Trunc(Cos(TailleAngle*I)*Rayon);
     YMove:=Trunc(Sin(TailleAngle*I)*Rayon);
     WebNotes[I].X:=CenterX+XMove;
     WebNotes[I].Y:=CenterY+YMove;
     Write(WebNotes[I].X,' ',WebNotes[I].Y,' ');
    End;
    WebNotes[NombreSommet+1].X:=WebNotes[1].X;
    WebNotes[NombreSommet+1].Y:=WebNotes[1].Y;
    Write(WebNotes[NombreSommet+1].X,' ',WebNotes[NombreSommet+1].Y);
    WriteLn('"/>');
    WriteLn('</svg>');
   End;
  End
   Else
  Begin
   InitScr;
   TailleAngle:=(360/NombreSommet)*0.017453292520;
   CenterX:=320 {(GetMaxX+1) shr 1};
   CenterY:=100 {(GetMaxY+1) shr 1};
   SetColor(8);
   For J:=1 to 5 do Begin
    Rayon:=J*10;
    For I:=1 to NombreSommet do Begin
     XMove:=Trunc(Cos(TailleAngle*I)*Rayon);
     YMove:=Trunc(Sin(TailleAngle*I)*Rayon);
     Web[I].X:=CenterX+XMove;
     Web[I].Y:=CenterY+YMove;
    End;
    Web[NombreSommet+1].X:=Web[1].X;
    Web[NombreSommet+1].Y:=Web[1].Y;
    DrawPoly(NombreSommet+1,Web);
   End;
   For I:=1 to NombreSommet do Begin
    Rayon:=7*10;
    XMove:=Trunc(Cos(TailleAngle*I)*Rayon);
    YMove:=Trunc(Sin(TailleAngle*I)*Rayon);
    Line(CenterX,CenterY,CenterX+XMove,CenterY+YMove);
   End;
   SetColor(LightGreen);
   For I:=1 to NombreSommet do Begin
    Rayon:=9*10;
    XMove:=Trunc(Cos(TailleAngle*I)*Rayon);
    YMove:=Trunc(Sin(TailleAngle*I)*Rayon);
    If(YMove=0)and(XMove>0)Then Begin
     OutTextXY(CenterX+XMove,
               CenterY+YMove,ValueMessage[I]);
    End
     Else
    OutTextXY(CenterX+XMove-(TextWidth(ValueMessage[I])shr 1),
              CenterY+YMove,ValueMessage[I]);
   End;
   SetColor(Yellow);
   For I:=1 to NombreSommet do Begin
    Rayon:=Value[I]*10;
    XMove:=Trunc(Cos(TailleAngle*I)*Rayon);
    YMove:=Trunc(Sin(TailleAngle*I)*Rayon);
    WebNotes[I].X:=CenterX+XMove;
    WebNotes[I].Y:=CenterY+YMove;
   End;
   WebNotes[NombreSommet+1].X:=WebNotes[1].X;
   WebNotes[NombreSommet+1].Y:=WebNotes[1].Y;
   DrawPoly(NombreSommet+1,WebNotes);
   ReadKey;
  End;
 End
  Else
 WriteLn('ParamŠtre attendue !');
END.
