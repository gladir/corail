{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program VIEWLSP;

{$A-}

Uses {$IFDEF FPC}
      Crt,PtcGraph,PtcCrt,PtcMouse
     {$ELSE}
      Crt,Graph
     {$ENDIF};

Var
 SourceLSP:Text;
 C:Char;
 Err:Word;
 CurrColor,Color:LongInt;
 IP,X1,Y1,X2,Y2:Integer;
 CurrParen:(_None,_Command);
 Command:(__None,_Circle,_Line,_Polyline);
 OpenParen,OpenStr,PosStr,I:Integer;
 CurrCoord,CurrWord,CurrString:String;
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
  SetLineStyle(0, 0, 1);
 End
  Else
 Begin
  WriteLn('Erreur graphique : ',GraphErrorMsg(ErrCode));
  Halt;
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('VIEWLSP : Cette commande permet de visualiser un image contenu ',
                     'dans un code source AutoLisp (AutoCAD ou CorelCAD)');
  WriteLn;
  WriteLn('Syntaxe : VIEWLSP nomdufichier.LSP');
  WriteLn;
  WriteLn(' nomdufichier   Ce paramŠtre permet d''indiquer le nom du fichier ".LSP".');
 End
  Else
 If ParamCount>0Then Begin
  {$I-}Assign(SourceLSP,ParamStr(1));
  Reset(SourceLSP);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de lire le fichier de format LSP : ',ParamStr(1));
   Halt;
  End;
  InitScr;
  FillChar(PointsParam,SizeOf(PointsParam),0);
  OpenParen:=0;
  OpenStr:=0;
  PosStr:=0;
  IP:=0;
  CurrParen:=_None;
  Command:=__None;
  CurrWord:='';
  CurrString:='';
  While Not EOF(SourceLSP)do Begin
   Read(SourceLSP,C);
   If C='"'Then Begin
    If OpenStr>0 Then Begin
     OpenStr:=0;
     If CurrParen=_Command Then Begin
      Case Command of
       __None:Begin
        If StrToUpper(CurrString)='CIRCLE'Then Command:=_Circle Else
        If StrToUpper(CurrString)='LINE'Then Command:=_Line Else
        If StrToUpper(CurrString)='PLINE'Then Begin
         Command:=_PolyLine;
         IP:=1;
        End;
        Inc(PosStr);
       End;
       _Circle:Begin
        Case PosStr of
         1:Begin
          CurrCoord:='';
          For I:=1 to Length(CurrString)do Begin
           If CurrString[I]=','Then Begin
            Val(CurrCoord,X1,Err);
            CurrCoord:='';
           End
            Else
           CurrCoord:=CurrCoord+CurrString[I];
          End;
          Val(CurrCoord,Y1,Err);
         End;
         2:Begin
          CurrCoord:='';
          For I:=1 to Length(CurrString)do Begin
           If CurrString[I]=','Then Begin
            Val(CurrCoord,X2,Err);
            CurrCoord:='';
           End
            Else
           CurrCoord:=CurrCoord+CurrString[I];
          End;
          Val(CurrCoord,Y2,Err);
         End;
         3:Begin
          { Ne fait rien }
         End;
        End;
        Inc(PosStr);
       End;
       _Line:Begin
        Case PosStr of
         1:Begin
          CurrCoord:='';
          For I:=1 to Length(CurrString)do Begin
           If CurrString[I]=','Then Begin
            Val(CurrCoord,X1,Err);
            CurrCoord:='';
           End
            Else
           CurrCoord:=CurrCoord+CurrString[I];
          End;
          Val(CurrCoord,Y1,Err);
         End;
         2:Begin
          CurrCoord:='';
          For I:=1 to Length(CurrString)do Begin
           If CurrString[I]=','Then Begin
            Val(CurrCoord,X2,Err);
            CurrCoord:='';
           End
            Else
           CurrCoord:=CurrCoord+CurrString[I];
          End;
          Val(CurrCoord,Y2,Err);
         End;
         3:Begin
          { Ne fait rien }
         End;
        End;
        Inc(PosStr);
       End;
       _Polyline:Begin
        CurrCoord:='';
        If Pos(',',CurrString)>0 Then Begin
         For I:=1 to Length(CurrString)do Begin
          If CurrString[I]=','Then Begin
           Val(CurrCoord,PointsParam[IP].X,Err);
           CurrCoord:='';
          End
           Else
          CurrCoord:=CurrCoord+CurrString[I];
         End;
         Val(CurrCoord,PointsParam[IP].Y,Err);
         Inc(IP);
        End;
        Inc(PosStr);
       End;
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
   If C='('Then Inc(OpenParen) Else
   If C=')'Then Begin
    If OpenParen>0 Then Dec(OpenParen);
    If CurrParen=_Command Then Begin
     Case Command of
      _Circle:Ellipse(X1,Y1,0,360,X2-X1,Y2-Y1);
      _Line:Line(X1,Y1,X2,Y2);
      _Polyline:Begin
       PointsParam[IP].X:=PointsParam[1].X;
       PointsParam[IP].Y:=PointsParam[1].Y;
       DrawPoly(IP,PointsParam);
      End;
     End;
    End;
    CurrWord:='';
    CurrParen:=_None;
    Command:=__None;
    PosStr:=0;
    FillChar(PointsParam,SizeOf(PointsParam),0);
   End
    Else
   If OpenParen>0 Then Begin
    If C in[#9,' ','=']Then Begin
     Case CurrParen of
      _None:Begin
       If StrToUpper(CurrWord)='COMMAND'Then CurrParen:=_Command;
       CurrWord:='';
      End;
     End;
    End
     Else
    If(C in[#13,#10])Then CurrWord:=''
                     Else CurrWord:=CurrWord+C;
   End
    Else
   If(C in[#13,#10])Then CurrWord:=''
                    Else CurrWord:=CurrWord+C;
  End;
  Close(SourceLSP);
  If(ReadKey=#0)Then Begin
   If(ReadKey<>#0)Then Begin
   End;
  End;
 End;
END.
