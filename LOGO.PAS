{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}


Program LOGO;

Uses {$IFDEF FPC}
      Crt,PtcGraph,PtcCrt,PtcMouse
     {$ELSE}
      Crt,Graph
     {$ENDIF};

Const
 CommandList:Array[0..161]of String[15]=(
  'AFFICHE','AFFICHER','ALLER','ALLERX','ALLERY','ANGLE',
  'ARG','ARGUMENT','ARRIERE','AV','AVANCE','AVANCER','BACK','BACK-COLOR',
  'BACKCOLOR','BACKGROUND','BACKWARD','BAISSER','BAISSER-CRAYON',
  'BAISSERCRAYON','BAS','BC','BEGIN','BEGINNING','BLOAD','BSAVE','CACHE',
  'CACHER','CATALOG','CL','CLEAR','CLEARSCREEN','COLOR','COULEUR','COULEUR-DE-FOND',
  'CS','DEBUT','DOWN','DRAW','DROIT','DROITE','ECRIRE','EDIT','END','ERASE','ERASEPICT',
  'EXIT','ERASE','ERASEFILE','FD','FIN','FINI','FINIR','FOND','FOR','FORWARD',
  'FULLSCREEN','GAUCHE','GO','GO-BACK','GOBACK','GOMME','GOMMER','GOODBYE',
  'GOX',  'GOY','HAUT','HIDE','HIDETURTLE','HOME','IF','LC','LEFT','LEVE','LEVER',
  'LEVER-CRAYON','MAKE','MARCHE','MARCHER','MASQUER','MONTRE','MONTRER','NODRAW',
  'OD','OUTPUT','PC','PENCOLORS','PENUP','PENDOWN','PENERASE','PO','POS',
  'POSITION','POSX','POSY','POTS','POUR','PRINT','QUITTE','QUITTER','RE',
  'READ','READPICT','RECOMMENCE','RECOMMENCER','RECULE','RECULER','REPEAT',
  'REPETE','REPETER','REQUEST','RESET','RIGHT','ROTATE','ROTATE-LEFT',
  'ROTATE-RIGHT','ROTATELEFT','RT','SETDISK','ROTATERIGHT','RUOP','SAVE',
  'SAVEPICT','SETPOS','SETPOSITION','SETX','SETY','SHOW','SHOWTURTLE',
  'SPLITSCREEN','STAMPCHAR','STOP','TD','TEXTCOLOR','TEXTBG','TEXTSCREEN',
  'TG','TL','TOURNE','TOURNE-DROITE','TOURNE-GAUCHE','TOURNEDROITE',
  'TOURNEGAUCHE','TOURNER','TOURNER-DROITE','TOURNER-GAUCHE','TOURNERDROITE',
  'TOURNERGAUCHE','TR','TURN','TURNLEFT','TURNRIGHT','TURN-LEFT',
  'TURN-RIGHT','UP','VA','VAX','VAY','WALK','WRITE','X','Y'
 );

 FunctionList:Array[0..6]of String[12]=(
  'ALLOPEN','ATAN','BITAND','BITNOT','BITOR','BITXOR','COS'
 );

 MaxLineSource=1024;
 MaxVariable=100;

Type
 VarTypeEnum=(_None,_Integer,_LongInt,_Real,_String);
 StrPointer=^String;
 VarRec=Record
  Variant:Record Case Integer of
   0:(I:Integer);
   1:(L:LongInt);
   2:(R:Real);
   3:(S:StrPointer);
  End;
  VarType:VarTypeEnum;
  VarName:String[20];
 End;
 VarPointer=^VarRec;
 ForStackRec=Record
  Line,Col:Word;
  LineNumber:Integer;
  VarName:String[20];
 End;

Var
 MaxX:Word;
 Terminated:Boolean;
 CurrCommand:String;
 FileName,CurrLine:String;
 PA:Array[1..MaxLineSource] of StrPointer;
 CurrLinePtr,NumberLine:Integer;
 CurrNumberLine:Integer;
 VarList:Array[1..MaxVariable]of VarPointer;
 I,NumberVariable:Integer;
 XPos,YPos,CurrPos:Byte;
 MinLine,MaxLine,MinColumn,MaxColumn:Byte;
 Angle:Real;
 X,Y,XC,YC:Integer;
 PenDown:Boolean;
 ForStack:Array[1..10]of ForStackRec;
 ForPos:Byte;

Function LTrim(S:String):String;
Var
 I:Integer;
Begin
 I:=1;
 While(I<=Length(s)) and (S[I] in [#9,' ']) do Inc(I);
 Delete(S,1,I-1);
 LTrim:=S;
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

Function IntToStr(I:Integer):String;
Var
 S:String;
Begin
 Str(I,S);
 IntToStr:=S;
End;

 { Traitement des variables }
Function VariableExist(S:String):Boolean;
Var
 I:Integer;
Begin
 VariableExist:=False;
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  VariableExist:=True;
  Exit;
 End;
End;

Function VariableType(S:String):VarTypeEnum;
Var
 I:Integer;
Begin
 VariableType:=_None;
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  VariableType:=VarList[I]^.VarType;
  Exit;
 End;
End;

Function AddVariableInt(S:String;Value:Integer):Boolean;
Var
 P:VarPointer;
Begin
 If NumberVariable>=MaxVariable Then Begin
  AddVariableInt:=False;
  Exit;
 End;
 Inc(NumberVariable);
 GetMem(P,SizeOf(VarRec));
 P^.VarName:=Copy(StrToUpper(S),1,20);
 P^.VarType:=_Integer;
 P^.Variant.I:=Value;
 VarList[NumberVariable]:=P;
 AddVariableInt:=True;
End;

Function GetVariableInt(S:String):Integer;
Var
 I:Integer;
Begin
 GetVariableInt:=0;
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  GetVariableInt:=VarList[I]^.Variant.I;
  Exit;
 End;
End;

Procedure SetVariableInt(S:String;Value:Integer);
Var
 I:Integer;
Begin
 For I:=1 to NumberVariable do If(S=VarList[I]^.VarName)Then Begin
  VarList[I]^.Variant.I:=Value;
  Exit;
 End;
End;

Function AddVariableLongInt(S:String;Value:LongInt):Boolean;
Var
 P:VarPointer;
Begin
 If NumberVariable>=MaxVariable Then Begin
  AddVariableLongInt:=False;
  Exit;
 End;
 Inc(NumberVariable);
 GetMem(P,SizeOf(VarRec));
 P^.VarName:=Copy(StrToUpper(S),1,20);
 P^.VarType:=_LongInt;
 P^.Variant.L:=Value;
 VarList[NumberVariable]:=P;
 AddVariableLongInt:=True;
End;

Function GetVariableLongInt(S:String):LongInt;
Var
 I:Integer;
Begin
 GetVariableLongInt:=0;
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  GetVariableLongInt:=VarList[I]^.Variant.L;
  Exit;
 End;
End;

Procedure SetVariableLongInt(S:String;Value:LongInt);
Var
 I:Integer;
Begin
 For I:=1 to NumberVariable do If(S=VarList[I]^.VarName)Then Begin
  VarList[I]^.Variant.L:=Value;
  Exit;
 End;
End;

Function AddVariableReal(S:String;Value:Real):Boolean;
Var
 P:VarPointer;
Begin
 If NumberVariable>=MaxVariable Then Begin
  AddVariableReal:=False;
  Exit;
 End;
 Inc(NumberVariable);
 GetMem(P,SizeOf(VarRec));
 P^.VarName:=Copy(StrToUpper(S),1,20);
 P^.VarType:=_Real;
 P^.Variant.R:=Value;
 VarList[NumberVariable]:=P;
 AddVariableReal:=True;
End;

Function GetVariableReal(S:String):Real;
Var
 I:Integer;
Begin
 GetVariableReal:=0;
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  GetVariableReal:=VarList[I]^.Variant.R;
  Exit;
 End;
End;

Procedure SetVariableReal(S:String;Value:Real);
Var
 I:Integer;
Begin
 For I:=1 to NumberVariable do If(S=VarList[I]^.VarName)Then Begin
  VarList[I]^.Variant.R:=Value;
  Exit;
 End;
End;

Function AddVariableString(S:String;Value:String):Boolean;
Var
 P:VarPointer;
 PS:StrPointer;
Begin
 If NumberVariable>=MaxVariable Then Begin
  AddVariableString:=False;
  Exit;
 End;
 Inc(NumberVariable);
 GetMem(P,SizeOf(VarRec));
 P^.VarName:=Copy(StrToUpper(S),1,20);
 P^.VarType:=_String;
 GetMem(PS,SizeOf(String));
 PS^:=Value;
 P^.Variant.S:=PS;
 VarList[NumberVariable]:=P;
 AddVariableString:=True;
End;

Function GetVariableString(S:String):String;
Var
 I:Integer;
Begin
 GetVariableString:='';
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  GetVariableString:=VarList[I]^.Variant.S^;
  Exit;
 End;
End;

Procedure SetVariableString(S:String;Value:String);
Var
 I:Integer;
Begin
 For I:=1 to NumberVariable do If(S=VarList[I]^.VarName)Then Begin
  VarList[I]^.Variant.S^:=Value;
  Exit;
 End;
End;

 { Traitement de la liste }
Function AddLine(S:String):Boolean;
Var
 P:StrPointer;
Begin
 If NumberLine>=MaxLineSource Then Begin
  AddLine:=False;
  Exit;
 End;
 Inc(NumberLine);
 GetMem(P,Length(S)+1);
 P^:=S;
 PA[NumberLine]:=P;
 AddLine:=True;
End;

Function FirstNumberInStr(S:String):Integer;
Var
 J,Number,Err:Integer;
Begin
 FirstNumberInStr:=0;
 J:=1;
 While(J<Length(S))do Begin
  If Not(S[J]in['0'..'9'])Then Begin
   Val(Copy(S,1,J-1),Number,Err);
   FirstNumberInStr:=Number;
   Break;
  End;
  Inc(J);
 End;
End;

 { Evaluation d'expression (Infix to PostFix ) }
Var
 Stack:Array[0..100]of Char;
 TopOfStack:Byte;
 resultStack:Array[0..100]of Real;
 TopOfStackInt:Byte;

Procedure StackPushChar(C:Char);Begin
 If TopOfStack>=High(Stack)Then Begin
  WriteLn('Pile pleine!');
  Halt;
 End
  Else
 Begin
  Stack[TopOfStack]:=C;
  Inc(TopOfStack);
 End;
End;

Function StackPop:String;
Var
 S:String;
 Err:Word;
Begin
 Dec(TopOfStack);
 If TopOfStack<1Then Begin
  StackPop:='';
  WriteLn('Pile vide');
  Halt;
 End
  Else
 StackPop:=Stack[TopOfStack];
End;

Function StackPeek:Char;Begin
 StackPeek:=Stack[TopOfStack-1];
End;

Procedure ResultStackPush(C:Real);Begin
 If TopOfStackInt>=High(ResultStack)Then Begin
  WriteLn('Pile pleine!');
  Halt;
 End
  Else
 Begin
  ResultStack[TopOfStackInt]:=C;
  Inc(TopOfStackInt);
 End;
End;

Function ResultStackPop:Real;Begin
 Dec(TopOfStackInt);
 If TopOfStackInt<1Then Begin
  ResultStackPop:=-1.0;
  WriteLn('Pile vide');
  Exit;
 End
  Else
 ResultStackPop:=ResultStack[TopOfStackInt];
End;


Function IsStringValue:Boolean;Begin
 IsStringValue:=False;
 If CurrLine[CurrPos]='['Then Begin
  IsStringValue:=True;
 End;
End;

Procedure ScrollWindow;
Var
 Size:Word;
 P:Pointer;
 J:Integer;
Begin
 Size:=ImageSize(MinColumn*8,MinLine*8,(MaxColumn+1)*8-1,(MinLine+1)*8-1);
 GetMem(P,Size);
 For J:=MinLine+1 to MaxLine do Begin
  GetImage(MinColumn*8,J*8,(MaxColumn+1)*8-1,(J+1)*8-1,P^);
  PutImage(MinColumn*8,(J-1)*8,P^,NormalPut);
 End;
 FreeMem(P,Size);
 SetFillStyle(SolidFill,Black);
 Bar(MinColumn*8,MaxLine*8,(MaxColumn+1)*8+1,(MaxLine+1)*8+1);
End;

Procedure ShowCursor;Begin
 SetFillStyle(SolidFill,Blue);
 Bar(XPos*8,YPos*8,XPos*8+TextWidth(' '),YPos*8+TextHeight(' '));
End;

Procedure HideCursor;Begin
 SetFillStyle(SolidFill,Black);
 Bar(XPos*8,YPos*8,XPos*8+TextWidth(' '),YPos*8+TextHeight(' '));
End;

Procedure WriteChar(C:Char);Begin
 OutTextXY(XPos*8,YPos*8,C);
 Inc(XPos);
End;

Procedure ClearEOL;Begin
 SetFillStyle(SolidFill,Black);
 Bar(XPos*8,YPos*8,MaxX,YPos*8+TextHeight('COMMAND'));
End;

Procedure WriteXY(X,Y:Byte;S:String);Begin
 XPos:=X;YPos:=Y;
 SetFillStyle(SolidFill,Black);
 Bar(XPos*8,YPos*8,XPos*8+TextWidth(S),YPos*8+TextHeight(S));
 OutTextXY(XPos*8,YPos*8,S);
 Inc(XPos,Length(S));
 If XPos>MaxColumn Then Begin
  XPos:=MinColumn;
  If(YPos<MaxLine)Then Inc(YPos)
                  Else ScrollWindow;
 End;
End;

Procedure WriteLineXY(X,Y:Byte;S:String);Begin
 XPos:=X;YPos:=Y;
 SetFillStyle(SolidFill,Black);
 Bar(XPos*8,YPos*8,XPos*8+TextWidth(S),YPos*8+TextHeight(S));
 OutTextXY(XPos*8,YPos*8,S);
  XPos:=MinColumn;
  If(YPos<MaxLine)Then Inc(YPos)
                  Else ScrollWindow;
End;

Procedure WriteLine(S:String);Begin
 If(XPos+Length(S)>MaxColumn)Then Begin
  WriteLineXY(XPos,YPos,Copy(S,1,MaxColumn-XPos+1));
  S:=Copy(S,MaxColumn-XPos+1,255);
  XPos:=MinColumn;
  If(YPos<MaxLine)Then Inc(YPos)
                  Else ScrollWindow;
  WriteLineXY(XPos,YPos,S);
 End
  Else
 WriteLineXY(XPos,YPos,S);
 XPos:=MinColumn;
 If(YPos<MaxLine)Then Inc(YPos)
                 Else ScrollWindow;
End;

Procedure Init;Begin
 PenDown:=True;
 Angle:=-PI/2;
 X:=320 {(GetMaxX+1) shr 1};
 Y:=100 {(GetMaxY+1) shr 1};
 MaxX:=639;
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

Procedure SkipSpace;Begin
 While(CurrLine[CurrPos]in[' '])and(CurrPos<Length(CurrLine))do Inc(CurrPos);
End;

Function GetSeparator:Char;Begin
 If CurrPos>Length(CurrLine)Then Begin
  GetSeparator:=#0;
  Exit;
 End;
 SkipSpace;
 GetSeparator:=CurrLine[CurrPos];
End;

Function GetVariableName:String;
Var
 S:String;
Begin
 S:='';
 If CurrLine[CurrPos]in['A'..'Z','a'..'z']Then Begin
  S:=S+CurrLine[CurrPos];
  Inc(CurrPos);
  While CurrPos<Length(CurrLine)do Begin
   If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z','0'..'9'])Then Break;
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
 End;
 GetVariableName:=StrToUpper(S);
End;

Function ReadWord:String;
Var
 S:String;
Begin
 S:='';
 If CurrLine[CurrPos]in['A'..'Z','a'..'z']Then Begin
  S:=S+CurrLine[CurrPos];
  Inc(CurrPos);
  While CurrPos<=Length(CurrLine)do Begin
   If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z','0'..'9'])Then Break;
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
 End;
 ReadWord:=StrToUpper(S);
End;

Function ExtractCommand:Byte;
Var
 I:Byte;
Begin
 ExtractCommand:=255;
 CurrCommand:='';
 For I:=CurrPos to Length(CurrLine)do Begin
  If Not(CurrLine[I]in['A'..'Z','a'..'z','-'])Then Begin
   CurrCommand:=StrToUpper(Copy(CurrLine,CurrPos,I-CurrPos));
   CurrPos:=I;
   Break;
  End;
 End;
 If CurrCommand=''Then Begin
  CurrCommand:=StrToUpper(Copy(CurrLine,CurrPos,255));
  CurrPos:=Length(CurrLine)+1;
 End;
 For I:=Low(CommandList)to High(CommandList)do Begin
  If CurrCommand=CommandList[I]Then Begin
   ExtractCommand:=I;
   Exit;
  End;
 End;
End;

Function GetStringValue:String;
Var
 J:Integer;
 _Result:Real;
 FunctionFound:Boolean;
 S,VarName:String;
Begin
 GetStringValue:='';
 S:='';
 If CurrLine[CurrPos]='['Then Begin
  Inc(CurrPos);
  While(CurrLine[CurrPos]<>']')and(CurrPos<=Length(CurrLine))do Begin
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
  If CurrLine[CurrPos]=']'Then Inc(CurrPos);
 End;
 GetStringValue:=S;
End;

Function GetNumberValue(MinTopOfStack:Integer):Real;
Var
 I,J:Byte;
 Top,P_2:Char;
 AppendOk,FunctionFound:Boolean;
 _Result,P,P2:Real;
 Err:Word;
 PostFix:String;
 VarName,Value:String;
 Exposant:Boolean;
 StopChar:Set Of Char;
 Infix:String;
Begin
 StopChar:=[',',':',';','"','<','=','>',' '];
 TopOfStack:=1;
 TopOfStackInt:=1;
 PostFix:='';
 Infix:=CurrLine;
 I:=CurrPos;
 If Infix[CurrPos]='-'Then Begin
  Insert('(0)',Infix,CurrPos);
  Dec(CurrPos,3);
 End;
 Repeat
  If(I<=Length(Infix))and(Infix[I]in['A'..'Z','a'..'z'])Then Begin
   VarName:=Infix[I];
   Inc(I);
   While(I<=Length(Infix))and(Infix[I]in['A'..'Z','a'..'z','-'])do Begin
    VarName:=VarName+Infix[I];
    Inc(I);
   End;
   VarName:=StrToUpper(VarName);
   If VariableExist(VarName)Then Begin
    Case VariableType(VarName)of
     _Integer:Str(GetVariableInt(VarName),Value);
     _LongInt:Str(GetVariableLongInt(VarName),Value);
     _Real:Str(GetVariableReal(VarName),Value);
     Else Begin
      WriteLine('Type incompatiable');
      Exit;
     End;
    End;
   End
    Else
   Begin { Fonction ?}
    FunctionFound:=False;
    For J:=Low(FunctionList)to High(FunctionList)do Begin
     If FunctionList[J]=VarName Then Begin
      FunctionFound:=True;
      Case J of
       6:Begin{COS}
        If Infix[I]<>'('Then Begin
         WriteLine('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        If Frac(_Result)=0.0 Then Str(Trunc(_Result),Value)
                             Else Str(_Result,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLine('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
      End;
      Break;
     End
      Else
     Begin { Variable vide }
      Value:='0';
     End;
    End;
   End;
   PostFix:=PostFix+'('+LTrim(Value)+')';
   If I>Length(Infix)Then Break;
  End
   Else
  If Infix[I]in['0'..'9']Then Begin
   Value:='';
   Exposant:=False;
   Repeat
    If Infix[I]in['E','e']Then Begin
     Exposant:=True;
     Value:=Value+Infix[I];
     Inc(I);
    End
     Else
    If(Exposant)and(Infix[I]in['-','+'])Then Begin
     Value:=Value+Infix[I];
     Inc(I);
    End
     Else
    If Infix[I]in['0'..'9','.']Then Begin
     Value:=Value+Infix[I];
     Inc(I);
    End
     Else
    Break;
   Until I>Length(Infix);
   PostFix:=PostFix+'('+Value+')';
  End
   Else
  If Infix[I]='('Then Begin
   StackPushChar(Infix[I]);
   Inc(I);
  End
   Else
  If Infix[I]in['*','+','-','/']Then Begin
   While(TopOfStack>MinTopOfStack)and(StackPeek <> '(')do Begin
    Top:=StackPeek;
    P_2:=Infix[I];
    AppendOk:=True;
    If(Top='+')and(P_2='*')Then AppendOk:=False
    Else If(Top='*')and(P_2='-')Then AppendOk:=True
    Else If(Top='+')and(P_2='-')Then AppendOk:=True;
    If(AppendOk)Then PostFix:=PostFix+StackPop
                Else Break;
   End;
   StackPushChar(Infix[I]);
   Inc(I);
  End
   Else
  If Infix[I]=')'Then Begin
   If TopOfStack<=MinTopOfStack Then Begin
    Break;
   End;
   While(TopOfStack>MinTopOfStack)and(StackPeek<>'(')do PostFix:=PostFix+StackPop;
   If TopOfStack>1Then StackPop;
   Inc(I);
  End
   Else
  Inc(I);
  If(Infix[I]in StopChar)Then Break;
  If(StrToUpper(Copy(Infix,I,2))='DO')or(StrToUpper(Copy(Infix,I,4))='THEN')or(StrToUpper(Copy(Infix,I,2))='TO')Then Break;
 Until I>Length(Infix);
 CurrPos:=I;
 While(TopOfStack>MinTopOfStack)do PostFix:=PostFix+StackPop;
  { Transformation en POSTFIX }
 I:=1;
 Repeat
  If PostFix[I]in['*','+','-','/']Then Begin
   P:=ResultStackPop;
   P2:=ResultStackPop;
   Case PostFix[I]of
    '+':_Result:=P2+P;
    '-':_Result:=P2-P;
    '*':_Result:=P2*P;
    '/':_Result:=P2/P;
    Else _Result:=-1;
   End;
   ResultStackPush(_Result);
  End
   Else
  Begin
   Value:='';
   Exposant:=False;
   Repeat
    If Postfix[I]in['0'..'9','.']Then Begin
     Value:=Value+Postfix[I];
     Inc(I);
    End
     Else
    If(Value<>'')and(Postfix[I]in['E','e'])Then Begin
     Exposant:=True;
     Value:=Value+Postfix[I];
     Inc(I);
    End
     Else
    If(Value<>'')and(Exposant)and(Postfix[I]in['+','-'])Then Begin
     Value:=Value+Postfix[I];
     Inc(I);
    End
     Else
    Break;
   Until I>Length(Postfix);
   If Value<>''Then Begin
    Val(Value,_Result,Err);
    ResultStackPush(_Result);
   End;
  End;
  Inc(I);
 Until I>Length(Postfix);
 GetNumberValue:=ResultStackPop;
End;

Procedure ShowPrompt;Begin
 WriteChar('?');
End;

Procedure AngleCommand;
Var
 Val:Real;
Begin
 Val:=GetNumberValue(1);
 Angle:=Angle+Val*0.017453292520;
End;

Procedure BackwardCommand;
Var
 Val:Real;
 CurrColor,XMove,YMove:Integer;
Begin
 Val:=-GetNumberValue(1);;
 XMove:=Trunc(Cos(Angle)*Val);
 YMove:=Trunc(Sin(Angle)*Val);
 If(PenDown)Then Begin
  CurrColor:=GetColor;
  SetColor(Black);
  Line(X,Y,X+XMove,Y+YMove);
  SetColor(CurrColor);
 End;
 Inc(X,XMove);
 Inc(Y,YMove);
End;

Function ForCommand:Boolean;
Var
 R1,R2:Real;
Begin
 ForCommand:=False;
 If ForPos>=High(ForStack)Then Begin
  WriteLine('Pile de FOR pleine.');
  Exit;
 End;
 Inc(ForPos);
 ForStack[ForPos].Line:=CurrLinePtr;
 ForStack[ForPos].LineNumber:=CurrNumberLine;
 SkipSpace;
 ForStack[ForPos].VarName:=Copy(GetVariableName,1,20);
 SkipSpace;
 R1:=0;
 If VariableExist(ForStack[ForPos].VarName)Then
  SetVariableReal(ForStack[ForPos].VarName,Trunc(R1))
 Else
  AddVariableReal(ForStack[ForPos].VarName,Trunc(R1));
 SkipSpace;
 If StrToUpper(ReadWord)<>'TO'Then Begin
  WriteLine('Mot r‚serv‚ "TO" attendu');
  Exit;
 End;
 SkipSpace;
 ForStack[ForPos].Col:=CurrPos;
 R2:=GetNumberValue(1);
 SkipSpace;
 If StrToUpper(ReadWord)<>'DO'Then Begin
  WriteLine('Mot r‚serv‚ "DO" attendu');
  Exit;
 End;
 ForCommand:=True;
End;

Procedure ForwardCommand;
Var
 Val:Real;
 XMove,YMove:Integer;
Begin
 Val:=GetNumberValue(1);
 XMove:=Trunc(Cos(Angle)*Val);
 YMove:=Trunc(Sin(Angle)*Val);
 If(PenDown)Then Begin
  SetColor(White);
  Line(X,Y,X+XMove,Y+YMove);
 End;
 Inc(X,XMove);
 Inc(Y,YMove);
End;

Procedure GoXCommand;
Var
 Val:Real;
Begin
 Val:=GetNumberValue(1);
 X:=Trunc(Val);
End;

Procedure GoYCommand;
Var
 Val:Real;
Begin
 Val:=GetNumberValue(1);
 Y:=Trunc(Val);
End;

Procedure HomeCommand;Begin
 X:=320 {(GetMaxX+1) shr 1};
 Y:=100 {(GetMaxY+1) shr 1};
End;

Procedure LeftCommand;
Var
 Val:Real;
Begin
 Val:=GetNumberValue(1);
 If Val=-1Then Val:=90;
 Angle:=Angle+(360-Val)*0.017453292520;
End;

Procedure LoadCommand;
Var
 FileLoad:Text;
 S:String;
Begin
 If FileName<>''Then Begin
  If StrToUpper(Copy(FileName,Length(FileName)-3,4))<>'.LGO'Then FileName:=FileName+'.LGO';
  {$I-}Assign(FileLoad,FileName);
  Reset(FileLoad);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier introuvable');
   Exit;
  End;
  {NewCommand;}
  While Not EOF(FileLoad) do Begin
   ReadLn(FileLoad,S);
   If Not AddLine(LTrim(S))Then Begin
    WriteLn('Manque de m‚moire');
    Break;
   End;
  End;
  Close(FileLoad);
 End
  Else
 WriteLn('Nom du fichier absent');
End;

Function OdCommand:Boolean;
Var
 NextCurrPos,NextCurrLinePtr,NextCurrNumberLine:Word;
 R2:Real;
Begin
 OdCommand:=False;
 If ForPos=0 Then Begin
  WriteLn('OD sans FOR');
  Exit;
 End;
 NextCurrPos:=CurrPos;
 NextCurrLinePtr:=CurrLinePtr;
 NextCurrNumberLine:=CurrNumberLine;
 CurrPos:=ForStack[ForPos].Col;
 CurrLinePtr:=ForStack[ForPos].Line;
 CurrLine:=PA[CurrLinePtr]^;
 CurrNumberLine:=ForStack[ForPos].LineNumber;
 SetVariableReal(ForStack[ForPos].VarName,GetVariableReal(ForStack[ForPos].VarName)+1);
 R2:=GetNumberValue(1);
 If GetVariableReal(ForStack[ForPos].VarName)>R2 Then Begin
  CurrPos:=NextCurrPos;
  CurrLinePtr:=NextCurrLinePtr;
  CurrNumberLine:=NextCurrNumberLine;
  CurrLine:=PA[CurrLinePtr]^;
  Dec(ForPos);
 End;
 OdCommand:=True;
End;

Procedure PosCommand;Begin
 WriteLine('['+IntToStr(X)+' '+IntToStr(Y)+']');
End;

Procedure PrintCommand;Begin
 SkipSpace;
 If IsStringValue Then Begin
  WriteLine(GetStringValue);
 End;
End;

Procedure PenDownCommand;Begin
 PenDown:=True;
End;

Procedure PenUpCommand;Begin
 PenDown:=False;
End;

Procedure RightCommand;
Var
 Val:Real;
Begin
 Val:=GetNumberValue(1);
 If Val=-1Then Val:=90;
 Angle:=Angle+Val*0.017453292520;
End;

Procedure SetPositionCommand;
Var
 XVal,YVal:Real;
Begin
 If GetSeparator='['Then Inc(CurrPos);
 SkipSpace;
 XVal:=GetNumberValue(1);
 SkipSpace;
 YVal:=GetNumberValue(1);
 If(PenDown)Then Line(X,Y,Trunc(XVal),Trunc(YVal));
 X:=Trunc(XVal);
 Y:=Trunc(YVal);
 If GetSeparator=']'Then Inc(CurrPos);
End;

Function RunCommand:Boolean;
Var
 R1:Real;
 UnknownCommand:Boolean;
 NoImplementation:Boolean;
Begin
 RunCommand:=False;
 CurrPos:=1;
 NoImplementation:=False;
 UnknownCommand:=False;
 Case ExtractCommand of
  0:PrintCommand;{AFFICHE}
  1:PrintCommand;{AFFICHER}
  2:NoImplementation:=True;{ALLER}
  3:GoXCommand;{ALLERX}
  4:GoYCommand;{ALLERY}
  5:AngleCommand;{ANGLE}
  6:NoImplementation:=True;{ARG}
  7:NoImplementation:=True;{ARGUMENT}
  8:BackwardCommand;{ARRIERE}
  9:NoImplementation:=True;{AV}
  10:ForwardCommand;{AVANCE}
  11:ForwardCommand;{AVANCER}
  12:NoImplementation:=True;{BACK}
  13:NoImplementation:=True;{BACK-COLOR}
  14:NoImplementation:=True;{BACKCOLOR}
  15:NoImplementation:=True;{BACKGROUND}
  16:BackwardCommand;{BACKWARD}
  17:NoImplementation:=True;{BAISSER}
  18:PenDownCommand;{BAISSER-CRAYON}
  19:PenDownCommand;{BAISSERCRAYON}
  20:NoImplementation:=True;{BAS}
  21:NoImplementation:=True;{BC}
  22:NoImplementation:=True;{BEGIN}
  23:NoImplementation:=True;{BEGINNING}
  24:NoImplementation:=True;{BLOAD}
  25:NoImplementation:=True;{BSAVE}
  26:NoImplementation:=True;{CACHE}
  27:NoImplementation:=True;{CACHER}
  28:NoImplementation:=True;{CATALOG}
  29:NoImplementation:=True;{CL}
  30:NoImplementation:=True;{CLEAR}
  31:NoImplementation:=True;{CLEARSCREEN}
  32:NoImplementation:=True;{COLOR}
  33:NoImplementation:=True;{COULEUR}
  34:NoImplementation:=True;{COULEUR-DE-FOND}
  35:NoImplementation:=True;{CS}
  36:HomeCommand;{DEBUT}
  37:NoImplementation:=True;{DOWN}
  38:NoImplementation:=True;{DRAW}
  39:RightCommand;{DROIT}
  40:RightCommand;{DROITE}
  41:NoImplementation:=True;{ECRIRE}
  42:NoImplementation:=True;{EDIT}
  43:NoImplementation:=True;{END}
  44:NoImplementation:=True;{ERASE}
  45:NoImplementation:=True;{ERASEPICT}
  46:NoImplementation:=True;{EXIT}
  47:NoImplementation:=True;{ERASE}
  48:NoImplementation:=True;{ERASEFILE}
  49:ForwardCommand;{FD}
  50:NoImplementation:=True;{FIN}
  51:NoImplementation:=True;{FINI}
  52:NoImplementation:=True;{FINIR}
  53:NoImplementation:=True;{FOND}
  54:If Not(ForCommand)Then Exit;{FOR}
  55:ForwardCommand;{FORWARD}
  56:NoImplementation:=True;{FULLSCREEN}
  57:LeftCommand;{GAUCHE}
  58:NoImplementation:=True;{GO}
  59:NoImplementation:=True;{GO-BACK}
  60:NoImplementation:=True;{GOBACK}
  61:NoImplementation:=True;{GOMME}
  62:NoImplementation:=True;{GOMMER}
  63:Begin {GOODBYE}
   Terminated:=True;
   Exit;
  End;
  64:GoXCommand;{GOX}
  65:GoYCommand;{GOY}
  66:NoImplementation:=True;{HAUT}
  67:NoImplementation:=True;{HIDE}
  68:NoImplementation:=True;{HIDETURTLE}
  69:HomeCommand;{HOME}
  70:NoImplementation:=True;{IF}
  71:NoImplementation:=True;{LC}
  72:LeftCommand;{LEFT}
  73:PenUpCommand;{LEVE}
  74:PenUpCommand;{LEVER}
  75:PenUpCommand;{LEVER-CRAYON}
  76:NoImplementation:=True;{MAKE}
  77:ForwardCommand;{MARCHE}
  78:ForwardCommand;{MARCHER}
  79:NoImplementation:=True;{MASQUER}
  80:NoImplementation:=True;{MONTRE}
  81:NoImplementation:=True;{MONTRER}
  82:NoImplementation:=True;{NODRAW}
  83:If Not(OdCommand)Then Exit;{OD}
  84:NoImplementation:=True;{OUTPUT}
  85:NoImplementation:=True;{PC}
  86:NoImplementation:=True;{PENCOLORS}
  87:PenUpCommand;{PENUP}
  88:PenDownCommand;{PENDOWN}
  89:NoImplementation:=True;{PENERASE}
  90:NoImplementation:=True;{PO}
  91:PosCommand;{POS}
  92:PosCommand;{POSITION}
  93:NoImplementation:=True;{POSX}
  94:NoImplementation:=True;{POSY}
  95:NoImplementation:=True;{POTS}
  96:If Not(ForCommand)Then Exit;{POUR}
  97:PrintCommand;{PRINT}
  98:Begin {QUITTE}
   Terminated:=True;
   Exit;
  End;
  99:Begin {QUITTER}
   Terminated:=True;
   Exit;
  End;
  100:NoImplementation:=True;{RE}
  101:NoImplementation:=True;{READ}
  102:NoImplementation:=True;{READPICT}
  103:NoImplementation:=True;{RECOMMENCE}
  104:NoImplementation:=True;{RECOMMENCER}
  105:NoImplementation:=True;{RECULE}
  106:NoImplementation:=True;{RECULER}
  107:NoImplementation:=True;{REPEAT}
  108:NoImplementation:=True;{REPETE}
  109:NoImplementation:=True;{REPETER}
  110:NoImplementation:=True;{REQUEST}
  111:NoImplementation:=True;{RESET}
  112:RightCommand;{RIGHT}
  113:NoImplementation:=True;{ROTATE}
  114:LeftCommand;{ROTATE-LEFT}
  115:RightCommand;{ROTATE-RIGHT}
  116:LeftCommand;{ROTATELEFT}
  117:RightCommand;{RT}
  118:NoImplementation:=True;{SETDISK}
  119:RightCommand;{ROTATERIGHT}
  120:NoImplementation:=True;{RUOP}
  121:NoImplementation:=True;{SAVE}
  122:NoImplementation:=True;{SAVEPICT}
  123:SetPositionCommand;{SETPOS}
  124:SetPositionCommand;{SETPOSITION}
  125:NoImplementation:=True;{SETX}
  126:NoImplementation:=True;{SETY}
  127:NoImplementation:=True;{SHOW}
  128:NoImplementation:=True;{SHOWTURTLE}
  129:NoImplementation:=True;{SPLITSCREEN}
  130:NoImplementation:=True;{STAMPCHAR}
  131:NoImplementation:=True;{STOP}
  132:NoImplementation:=True;{TD}
  133:NoImplementation:=True;{TEXTCOLOR}
  134:NoImplementation:=True;{TEXTBG}
  135:NoImplementation:=True;{TEXTSCREEN}
  136:LeftCommand;{TG}
  137:LeftCommand;{TL}
  138:NoImplementation:=True;{TOURNE}
  139:RightCommand;{TOURNE-DROITE}
  140:RightCommand;{TOURNE-GAUCHE}
  141:RightCommand;{TOURNEDROITE}
  142:LeftCommand;{TOURNEGAUCHE}
  143:NoImplementation:=True;{TOURNER}
  144:RightCommand;{TOURNER-DROITE}
  145:LeftCommand;{TOURNER-GAUCHE}
  146:RightCommand;{TOURNERDROITE}
  147:LeftCommand;{TOURNERGAUCHE}
  148:RightCommand;{TR}
  149:NoImplementation:=True;{TURN}
  150:LeftCommand;{TURNLEFT}
  151:RightCommand;{TURNRIGHT}
  152:LeftCommand;{TURN-LEFT}
  153:RightCommand;{TURN-RIGHT}
  154:NoImplementation:=True;{UP}
  155:NoImplementation:=True;{VA}
  156:GoXCommand;{VAX}
  157:GoYCommand;{VAY}
  158:ForwardCommand;{WALK}
  159:NoImplementation:=True;{WRITE}
  160:NoImplementation:=True;{X}
  161:NoImplementation:=True;{Y}
  Else UnknownCommand:=True;
 End;
 If(UnknownCommand)Then Begin
  SkipSpace;
  If CurrLine[CurrPos]='='Then Begin
   R1:=GetNumberValue(1);
   If VariableExist(CurrCommand)Then
    SetVariableLongInt(CurrCommand,Trunc(R1))
   Else
    AddVariableLongInt(CurrCommand,Trunc(R1));
  End
   Else
  WriteLine('Commande non reconnu');
  Exit;
 End
  Else
 If(NoImplementation)Then Begin
  WriteLine('Cette commande n''a pas ‚t‚ impl‚ment‚');
  Exit;
 End;
 RunCommand:=True;
End;

Procedure RunListCommand;
Var
 J:Integer;
 Err:Integer;
 S1:String;
Begin
 If NumberLine>0Then Begin
  CurrLinePtr:=1;
  While(CurrLinePtr<=NumberLine) do Begin
   CurrLine:=PA[CurrLinePtr]^;
   CurrNumberLine:=0;
   J:=1;
   While(J<Length(CurrLine))do Begin
    If Not(CurrLine[J]in['0'..'9'])Then Begin
     Val(Copy(CurrLine,1,J-1),CurrNumberLine,Err);
     Break;
    End;
    Inc(J);
   End;
   While J<=Length(CurrLine)do Begin
    If CurrLine[J]in[' ',#9]Then Inc(J)
                            Else Break;
   End;
   CurrPos:=J;
   If Not(RunCommand)Then Break;
   Inc(CurrLinePtr);
  End;
 End;
End;

Procedure ReadLine(Var S:String);
Var
 K:Char;
 X,Y,I:Byte;
 CurrHistory:Integer;
 CursorState:Boolean;
Begin
 X:=XPos;
 Y:=Ypos;
 S:='';
 Repeat
  WriteXY(X,Y,S);
  ClearEol;
  CursorState:=True;
  Repeat
   If(CursorState)Then ShowCursor
                  Else HideCursor;
   If Not(Keypressed)Then Delay(250);
   CursorState:=Not CursorState;
  Until Keypressed;
  HideCursor;
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #72:;
   End;
   #8:Begin
    If S<>''Then S:=Copy(S,1,Length(S)-1);
   End;
   #9:If S<>''Then Begin
    S:=S+'        ';
   End;
   Else S:=S+K;
  End;
  If S[Length(S)]=#13Then Begin
   S:=Copy(S,1,Length(S)-1);
   K:=#13;
  End;
 Until K=#13;
 WriteLineXY(X,Y,S);
 WriteLine('');
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('LOGO : Cette commande permet de lancer le langage de programmation LOGO');
  WriteLn;
  WriteLn('Syntaxe : LOGO [fichier.LGO]');
 End
  Else
 Begin
  FileName:='';
  NumberLine:=0;CurrNumberLine:=0;
  NumberVariable:=0;ForPos:=0;
  XPos:=1;YPos:=1;Terminated:=False;
  MinLine:=1;
  MaxLine:=40;
  MinColumn:=1;
  MaxColumn:=80;
  Init;
  InitScr;
  If ParamCount>0 Then Begin
   For I:=1 to ParamCount do Begin
    FileName:=ParamStr(I);
   End;
   LoadCommand;
   RunListCommand;
   ReadKey;
  End
   Else
  Begin
   Repeat
    ShowPrompt;
    ReadLine(CurrLine);
    RunCommand;
   Until Terminated;
  End;
 End;
END.
