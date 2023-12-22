{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program _BAR;

Uses {$IFDEF FPC}
      DOS,Crt,PtcGraph,PtcCrt,PtcMouse
     {$ELSE}
      DOS,Crt,Graph
     {$ENDIF};

Const
 HeightScreen=480;

Var
 SourceCSV:Text;
 I,PosField,WidthBar,X,NextX:Integer;
 FileName,CurrLine,CurrWord,CurrData:String;
 CurrType:Integer;
 DataArray:Array[0..365]of String[10];
 TypeArray:Array[0..365]of Integer;
 NumRecord:Integer;
 Err:Word;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function IntToStr(Value:Integer):String;
Var
 S:String;
Begin
 Str(Value,S);
 IntToStr:=S;
End;

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

Procedure StringToDate(S:String;Var Year,Month,Day:Word);
Var
 Err:Word;
Begin
 Val(Copy(S,1,4),Year,Err);
 Val(Copy(S,6,2),Month,Err);
 Val(Copy(S,9,2),Day,Err);
End;

Function DateToString(X:DateTime):String;Begin
 DateToString:=IntToStr(X.Year)+'-'+
               PadZeroLeft(X.Month,2)+'-'+
               PadZeroLeft(X.Day,2);
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
  WriteLn('BAR : Cette commande permet d''afficher un ',
                   ' graphique … barre bas‚ sur les donn‚es d''un fichier ',
                   'CSV.');
  WriteLn;
  WriteLn('Syntaxe : BAR fichier.CSV');
  WriteLn;
  WriteLn('fichier      Ce parametre permet d''indiquer un fichier de donn‚es');
 End
  Else
 If ParamCount>0Then Begin
  FileName:=ParamStr(1);
  {$I-}Assign(SourceCSV,FileName);
  Reset(SourceCSV);{$I+}
  If IoResult<>0 Then Begin
   WriteLn('Erreur de lecture du fichier CSV !');
   Halt;
  End;
  NumRecord:=0;
  While Not EOF(SourceCSV)do Begin
   ReadLn(SourceCSV,CurrLine);
   CurrWord:='';PosField:=0;
   For I:=1 to Length(CurrLine)do Begin
    If CurrLine[I]=','Then Begin
    If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
      If PosField=0 Then CurrData:=Copy(CurrWord,2,Length(CurrWord)-2)
       Else
      Begin
       Val(Copy(CurrWord,2,Length(CurrWord)-2),CurrType,Err);
      End;
      Inc(PosField);
     End
      Else
     Begin
      If PosField=0 Then CurrData:=CurrWord
                    Else Val(CurrWord,CurrType,Err);
      Inc(PosField);
     End;
     CurrWord:='';
    End
     Else
    CurrWord:=CurrWord+CurrLine[I];
   End;
   If CurrWord<>''Then Begin
    If PosField=0 Then CurrData:=CurrWord
                  Else Val(CurrWord,CurrType,Err);
   End;
   TypeArray[NumRecord]:=CurrType;
   DataArray[NumRecord]:=CurrData;
   Inc(NumRecord);
   If NumRecord>High(DataArray)Then Break;
  End;
  Close(SourceCSV);
  If NumRecord>0Then Begin
   InitScr;
   OutTextXY(320-(TextWidth('Graphique … barre')shr 1),0,'Graphique … barre');
   OutTextXY(0,30,'chantillion de donn‚es du fichier ®'+FileName+'¯');
   WidthBar:=575 div NumRecord;
   X:=0;NextX:=0;
   For I:=0 to NumRecord-1 do Begin
    Case I and 1 of
     0:SetFillStyle(SolidFill,LightGray);
     1:SetFillStyle(SolidFill,White);
    End;
    Bar(X,(HeightScreen-1)-20-TypeArray[I]*4,X+WidthBar-1,HeightScreen-1-20);
    If X>=NextX Then Begin
     OutTextXY(X,(HeightScreen-1)-10,DataArray[I]);
     NextX:=NextX+TextWidth(DataArray[I]);
    End;
    Inc(X,WidthBar);
   End;
   For I:=0 to 10 do Begin
    OutTextXY(580,(HeightScreen-1)-20-(I*40)-TextHeight('1234567890')*2,IntToStr(I*10)+'%');
   End;
   ReadKey;
  End
   Else
  WriteLn('Aucune donn‚es n''est pr‚sente pour analyse');
 End;
END.