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
 SourceCSV:Text;
 NombreSommet,PosField:Integer;
 Err:Word;
 TailleAngle:Real;
 CenterX,CenterY,XMove,YMove,I,J,Rayon:Integer;
 Web,WebNotes:Array[1..100]of PointType;
 Value:Array[1..100]of Integer;
 ValueMessage:Array[1..100]of String[50];
 FileName,CurrLine,CurrWord:String;

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
  WriteLn('Syntaxe : WEBGRAPH source.csv');
  WriteLn;
  WriteLn(' fichier.CSV  Nom du fichier a analyser');
  WriteLn;
 End
  Else
 If ParamCount>0 Then Begin
  NombreSommet:=0;
  FileName:='';
  FillChar(Value,SizeOf(Value),0);
  FillChar(ValueMessage,SizeOf(ValueMessage),#0);
  FillChar(Web,SizeOf(Web),0);
  FillChar(WebNotes,SizeOf(WebNotes),0);
  For I:=1 to ParamCount do Begin
   FileName:=ParamStr(I);
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
 End
  Else
 WriteLn('ParamŠtre attendue !');
END.
