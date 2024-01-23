{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program TV(Input,Output);

Uses Crt,DOS;

Type
 StrPointer=^String;

Var
 ForceVGA:Boolean;
 Lines:Integer;
 ModeParam:(_None,_Delimiter,_DelimiterValue,_Lines);
 Delimiter:Char;
 K:Char;
 Err,Value:Word;
 SourceCSV:Text;
 CurrParam,CurrLine,CurrWord,CurrField,FileName,TFileName:String;
 I,X,Y,XCur,YCur:Integer;
 First:Boolean;
 Fields:Array[0..100]of String[75];
 FieldsWidth:Array[0..100]of Integer;
 PA:Array[0..10000] of StrPointer;
 PosField,NumField,CurrLength:Integer;
 NumFieldMax:Integer;
 NumRecord:LongInt;
 P:StrPointer;

{$IFNDEF FPC}
 Procedure CursorOff;
 Var
  Regs:Registers;
 Begin
  Regs.AH:=1;
  Regs.CH:=32;
  Regs.CL:=0;
  Intr($10,Regs);
 End;

 Procedure CursorOn;
 Var
  Regs:Registers;
 Begin
  Regs.AX:=$0100;
  Regs.CX:=(7 shl 8)+9;
  Intr($10,Regs);
 End;
{$ENDIF}

Function IsNumber(S:String):Boolean;
Var
 I:Integer;
Begin
 IsNumber:=True;
 For I:=1 to Length(S)do Begin
  If Not(S[I]in['0'..'9','.'])Then Begin
   IsNumber:=False;
   Exit;
  End;
 End;
End;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function Dupl(C:Char;Num:Integer):String;
Var
 I:Byte;
 S:String;
Begin
 S:='';
 For I:=1 to Num do S:=S+C;
 Dupl:=S;
End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function Path2Name(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2Name:=N;
End;

Function Path2Ext(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2Ext:=E;
End;

Procedure HeaderField;
Var
 I:Integer;
 PosField,PosX:Integer;
 CurrWord,CurrLine:String;
Begin
 PosX:=1;
 PosField:=0;
 CurrWord:='';
 CurrLine:=PA[0]^;
 TextColor(Yellow);
 For I:=1 to Length(CurrLine)do Begin
  If CurrLine[I]=Delimiter Then Begin
   If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
    CurrWord:=Copy(CurrWord,2,Length(CurrWord)-2);
   End;
   If(PosX<=80)Then Begin
    GotoXY(PosX,1);
    Write(CurrWord);
   End;
   CurrWord:='';
   Inc(PosX,FieldsWidth[PosField]);
   Inc(PosField);
  End
   Else
  CurrWord:=CurrWord+CurrLine[I];
 End;
 If(PosX<=80)Then Begin
  GotoXY(PosX,1);
  Write(CurrWord);
 End;
End;

Procedure ShowLine(CurrLine:String;Y:Byte);
Var
 I:Integer;
 PosField,PosX:Integer;
 CurrWord:String;
Begin
 PosX:=1;
 PosField:=0;
 CurrWord:='';
 For I:=1 to Length(CurrLine)do Begin
  If CurrLine[I]=Delimiter Then Begin
   If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
    CurrWord:=Copy(CurrWord,2,Length(CurrWord)-2);
   End;
   If(PosX<=80)Then Begin
    GotoXY(PosX,Y);
    If PosX+Length(CurrWord)>80 Then Write(Copy(CurrWord,1,80-PosX+1))
                                Else Write(CurrWord);
   End;
   CurrWord:='';
   Inc(PosX,FieldsWidth[PosField]);
   Inc(PosField);
  End
   Else
  CurrWord:=CurrWord+CurrLine[I];
 End;
 If(PosX<=80)Then Begin
  GotoXY(PosX,Y);
  If PosX+Length(CurrWord)>80 Then Write(Copy(CurrWord,1,80-PosX+1))
                              Else Write(CurrWord);
 End;
End;

Procedure StatusBar;Begin
 GotoXY(1,Lines);
 TextBackground(Blue);
 TextColor(Brown);
 Write(FileName,' |');
 ClrEol;
 TextBackground(Black);
End;

Procedure ShowColumnType(S:String);Begin
 TextBackground(Blue);
 TextColor(Brown);
 GotoXY(57,Lines);
 Write('Type de colonne : ',S,' |');
 TextColor(LightGray);
 TextBackground(Black);
End;

Procedure HidePointer;Begin
 GotoXY(1,YCur+2);
 ClrEol;
 ShowLine(PA[Y]^,YCur+2);
End;

Procedure ShowPointer;
Var
 I:Integer;
 PosField,PosX:Integer;
 CurrWord,CurrLine:String;
Begin
 PosX:=1;
 PosField:=0;
 CurrWord:='';
 CurrLine:=PA[Y]^;
 For I:=1 to Length(CurrLine)do Begin
  If CurrLine[I]=Delimiter Then Begin
   If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
    CurrWord:=Copy(CurrWord,2,Length(CurrWord)-2);
   End;
   If(PosX<=80)Then Begin
    If(PosX=XCur+1)Then Begin
     TextBackground(LightCyan);
     TextColor(Black);
     GotoXY(PosX,YCur+2);
     If PosX+FieldsWidth[PosField]>80 Then Write(Copy(PadRight(CurrWord,FieldsWidth[PosField]),1,80-PosX+1))
                                      Else Write(PadRight(CurrWord,FieldsWidth[PosField]));
     If IsNumber(CurrWord)Then ShowColumnType('Num')
                          Else ShowColumnType('Str');
    End;
   End;
   CurrWord:='';
   Inc(PosX,FieldsWidth[PosField]);
   Inc(PosField);
  End
   Else
  CurrWord:=CurrWord+CurrLine[I];
 End;
 If(PosX<=80)Then Begin
  If(PosX=XCur+1)Then Begin
   TextBackground(LightCyan);
   TextColor(Black);
   GotoXY(PosX,YCur+2);
   If PosX+FieldsWidth[PosField]>80 Then Write(Copy(PadRight(CurrWord,FieldsWidth[PosField]),1,80-PosX+1))
                                    Else Write(PadRight(CurrWord,FieldsWidth[PosField]));
   If IsNumber(CurrWord)Then ShowColumnType('Num')
                        Else ShowColumnType('Str');
  End;
 End;
 TextBackground(Black);
 TextColor(White);
End;

Procedure RefreshPage;
Var
 J:Integer;
Begin
 TextColor(White);
 For J:=0 to Lines-3 do Begin
  If(PA[Y-YCur+J]=NIL)Then Break;
  GotoXY(1,2+J);
  ClrEol;
  ShowLine(PA[Y-YCur+J]^,2+J);
 End;
End;

Procedure HomePage;
Var
 J:Integer;
Begin
 HeaderField;
 TextColor(White);
 For J:=0 to Lines-3 do Begin
  If(PA[J+1]=NIL)Then Break;
  ShowLine(PA[J+1]^,2+J);
 End;
 StatusBar;
 ShowPointer;
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('TV : Cette commande permet de visualiser un ',
                'fichier CSV comme dans un tableur.');
  WriteLn;
  WriteLn('Syntaxe : TV fichier.CSV [-D caractere] [-DV nombre]');
  WriteLn('             [-LINES nombre]');
  WriteLn;
  WriteLn(' fichier.CSV    Nom du fichier a afficher');
  WriteLn(' -D caractere   Indique le caractŠre de s‚paration');
  WriteLn(' -DV nombre     Indique la valeur ASCII du caractŠre ',
                          'de s‚paration');
  WriteLn(' -LINES nombre  Force le nombre de ligne d''affichage sp‚cifi‚');
  WriteLn(' -VGA           Force le mode EGA/VGA (en mode DOS uniquement).');
  WriteLn;
 End
  Else
 Begin
  Lines:=25;
  ForceVGA:=False;
  ModeParam:=_None;
  Delimiter:=',';
  X:=0;
  Y:=1;
  XCur:=0;
  YCur:=0;
  CurrLength:=0;
  NumRecord:=0;
  NumField:=0;
  NumFieldMax:=0;
  FileName:='';
  FillChar(Fields,SizeOf(Fields),0);
  FillChar(FieldsWidth,SizeOf(FieldsWidth),0);
  FillChar(PA,SizeOf(PA),0);
  If ParamCount>0Then Begin
   For I:=1 to ParamCount do Begin
    Case ModeParam of
     _Delimiter:Begin
      CurrParam:=ParamStr(I);
      If Length(CurrParam)>0 Then Delimiter:=CurrParam[1];
      ModeParam:=_None;
     End;
     _DelimiterValue:Begin
      CurrParam:=ParamStr(I);
      If Length(CurrParam)>0 Then Begin
       Val(CurrParam,Value,Err);
       Delimiter:=Char(Value);
      End;
      ModeParam:=_None;
     End;
     _Lines:Begin
      CurrParam:=ParamStr(I);
      If Length(CurrParam)>0 Then Begin
       Val(CurrParam,Lines,Err);
      End;
      ModeParam:=_None;
     End;
     Else Begin
      If(StrToUpper(ParamStr(I))='-D')or(StrToUpper(ParamStr(I))='--DELIMITER')Then Begin
       ModeParam:=_Delimiter;
      End
       Else
      If(StrToUpper(ParamStr(I))='-DV')or(StrToUpper(ParamStr(I))='/DV')Then Begin
       ModeParam:=_DelimiterValue;
      End
       Else
      If(StrToUpper(ParamStr(I))='-LINES')or(StrToUpper(ParamStr(I))='/LINES')Then Begin
       ModeParam:=_Lines;
      End
       Else
      If(StrToUpper(ParamStr(I))='-VGA')or(StrToUpper(ParamStr(I))='/VGA')Then Begin
       ForceVGA:=True;
      End
       Else
      FileName:=FExpand(ParamStr(I));
     End;
    End;
   End;
   If Path2Ext(FileName)=''Then FileName:=FileName+'.CSV';
   Assign(SourceCSV,FileName);
   {$I-}Reset(SourceCSV);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Fichier CSV ',FileName,' est introuvable !');
    Halt;
   End;
   While Not EOF(SourceCSV)do Begin
    ReadLn(SourceCSV,CurrLine);
    GetMem(P,Length(CurrLine)+1);
    P^:=CurrLine;
    PA[NumRecord]:=P;
    Inc(NumRecord);
    If NumRecord>High(PA)Then Break;
    NumField:=0;
    For I:=1 to Length(CurrLine)do Begin
     If CurrLine[I]=Delimiter Then Begin
      If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
       CurrLength:=Length(Copy(CurrWord,2,Length(CurrWord)-2))+1;
       If(CurrLength>FieldsWidth[NumField])Then FieldsWidth[NumField]:=CurrLength;
       Inc(NumField);
      End
       Else
      Begin
       CurrLength:=Length(CurrWord)+1;
       If(CurrLength>FieldsWidth[NumField])Then FieldsWidth[NumField]:=CurrLength;
       Inc(NumField);
      End;
      CurrWord:='';
     End
      Else
     CurrWord:=CurrWord+CurrLine[I];
    End;
    CurrLength:=Length(CurrWord)+1;
    If(CurrLength>FieldsWidth[NumField])Then FieldsWidth[NumField]:=CurrLength;
    Inc(NumField);
    If(NumField>NumFieldMax)Then NumFieldMax:=NumField;
   End;
   Close(SourceCSV);
   If(ForceVGA)Then Begin
    TextMode(CO80+Font8x8);
    If Lines=25 Then Lines:=50;
   End;
   ClrScr;
   CursorOff;
   HomePage;
   Repeat
    K:=ReadKey;
    Case K of
     #0:Case ReadKey of
      #72:Begin { Haut }
       HidePointer;
       If Y>1 Then Begin
        Dec(Y);
        If YCur>0 Then Dec(YCur)
                  Else RefreshPage;
       End;
       ShowPointer;
      End;
      #73:If(NumRecord>Lines)Then Begin { PgUp }
       If(Y-(Lines-4)-YCur>=1)Then Begin
        HidePointer;
        Dec(Y,Lines-4);
        RefreshPage;
        ShowPointer;
       End
        Else
       Begin
        X:=0;
        Y:=1;
        XCur:=0;
        YCur:=0;
        RefreshPage;
        ShowPointer;
       End;
      End;
      #75:Begin { Gauche }
       HidePointer;
       If X>0 Then Begin
        Dec(X);
        If XCur-FieldsWidth[X]>=0 Then Dec(XCur,FieldsWidth[X])
                                  Else RefreshPage;
       End;
       ShowPointer;
      End;
      #77:Begin { Droite }
       HidePointer;
       If X<NumField-1 Then Begin
        Inc(X);
        If(XCur+FieldsWidth[X-1]<80)Then Inc(XCur,FieldsWidth[X-1])
                                    Else RefreshPage;
       End;
       ShowPointer;
      End;
      #80:Begin { Bas }
       HidePointer;
       If(Y<NumRecord-1)Then Begin
        Inc(Y);
        If(YCur<(Lines-3))Then Inc(YCur)
                          Else RefreshPage;
       End;
       ShowPointer;
      End;
      #81:If(NumRecord>Lines)Then Begin { PgDn }
       If(Y+Lines-4<NumRecord-1)Then Begin
        HidePointer;
        Inc(Y,Lines-4);
        RefreshPage;
        ShowPointer;
       End
        Else
       Begin
        X:=0;
        Y:=NumRecord-1;
        XCur:=0;
        YCur:=Lines-3;
        RefreshPage;
        ShowPointer;
       End;
      End;
      #117:If(NumRecord>Lines)Then Begin { Ctrl+End }
       X:=0;
       Y:=NumRecord-1;
       XCur:=0;
       YCur:=Lines-3;
       RefreshPage;
       ShowPointer;
      End;
      #119:Begin { Ctrl+Home }
       X:=0;
       Y:=1;
       XCur:=0;
       YCur:=0;
       RefreshPage;
       ShowPointer;
      End;
     End;
    End;
   Until K=#27;
   ClrScr;
   CursorOn;
  End;
 End;
END.
