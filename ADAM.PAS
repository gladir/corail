{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program ADAM;

Uses Crt,DOS,Printer;

Const
 CommandList:Array[0..72]of String[12]=(
  'AND','APPEND','BLOAD','BRUN','BSAVE','CALL','CATALOG','CLEAR',
  'CLOSE','CONT','DATA','DEF','DEL','DELETE','DIM','DRAW','END',
  'FLASH','FOR','GET','GOSUB','GOTO','GR','HELP',
  'HGR','HGR2','HIMEM','HLIN','HOME','HPLOT','HTAB','IF','INIT',
  'INPUT','INVERSE','LET','LIST','LOAD','LOCK','LOMEM','MON',
  'NEW','NEXT','NOMON','NORMAL','NOTRACE','ON','ONERR','OPEN',
  'PLOT','POKE','POP','POSITION','PR','PRINT','READ','RECOVER',
  'REM','RENAME','RESTORE','RETURN','RUN','SAVE','STOP',
  'SYSTEM','THEN','TEXT','TRACE','UNLOCK','VLIN','VTAB','WAIT',
  'XDRAW'
 );

 FunctionList:Array[0..53]of String[12]=(
  'ABS','ASC','ATN','CHR$','CINT','CSNG','CSRLIN','COS','CVD','CVI',
  'CVS','DATE$','EOF','ERL','ERR','EXP','FIX','FRE','INKEY$','INP',
  'INPUT$','INSTR','INT','LEFT$','LEN','LOF','LOG','LPOS','LTRIM$',
  'MID$','OCT$','PEEK','PLAY','PMAP','POS','RIGHT$','RND','RTRIM$',
  'SCREEN','SGN','SIN','SQR','STR$','STRIG','STRING$','TAN','TAB',
  'TIME$','TIMER','TRIM$','USR','VAL','VARPTR','VARPTR$'
 );

 MaxLine=1024;
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
 GosubStackRec=Record
  Line,Col:Word;
  LineNumber:Integer;
 End;
 ForStackRec=Record
  Line,Col:Word;
  LineNumber:Integer;
  VarName:String[20];
 End;

Var
 Terminated,Tron:Boolean;
 CurrWidth:Byte;
 CurrCommand:String;
 FileName,CurrLine:String;
 CurrPos:Byte;
 PA:Array[1..MaxLine] of StrPointer;
 CurrLinePtr,NumberLine:Integer;
 CurrNumberLine:Integer;
 VarList:Array[1..MaxVariable]of VarPointer;
 I,NumberVariable:Integer;
 GosubStack:Array[1..10]of GosubStackRec;
 GosubPos:Byte;
 ForStack:Array[1..10]of ForStackRec;
 ForPos:Byte;

Function RunBasic(InList:Boolean):Boolean;Forward;
Procedure NewCommand;Forward;

Function TAN(X:Real):Real;Begin
 If Cos(X)=0.0Then Tan:=0.0
              Else Tan:=SIN(X)/COS(X);
End;

Function LTrim(S:String):String;
Var
 I:Integer;
Begin
 I:=1;
 While(I<=Length(s)) and (S[I] in [#9,' ']) do Inc(I);
 Delete(S,1,I-1);
 LTrim:=S;
End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
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

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

Function GetCurrentDisk:Char;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 GetCurrentDisk:=CurrentDir[1];
End;

Function Path2Name(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2Name:=N;
End;

Function Path2ExtNoDot(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2ExtNoDot:=Copy(E,2,255);
End;

Function Path2Ext(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2Ext:=E;
End;

Function Path2Drive(Path:String):Char;Begin
 Path:=FExpand(Path);
 Path2Drive:=Path[1];
End;

Function GetErrorMessage(Code:Word):String;Begin
 Case Code of
  0:GetErrorMessage:='';
  2:GetErrorMessage:='Fichier introuvable';
  3:GetErrorMessage:='Chemin introuvable';
  4:GetErrorMessage:='Trop de fichiers ouvert';
  5:GetErrorMessage:='Acces refuse';
  6:GetErrorMessage:='Handle de fichier invalide';
  12:GetErrorMessage:='Mode d''acces sur disque invalide';
  15:GetErrorMessage:='Num‚ro de disque invalide';
  16:GetErrorMessage:='Impossible de supprimer le r‚pertoire';
  17:GetErrorMessage:='Impossible de renommer sur plusieurs volumes';
  100:GetErrorMessage:='Erreur de lecture … partir du disque';
  101:GetErrorMessage:='Erreur d''ecriture sur le disque';
  102:GetErrorMessage:='Fichier non attribue';
  103:GetErrorMessage:='Le fichier n''est pas ouvert';
  104:GetErrorMessage:='Le fichier n''est pas ouvert … l''entree';
  105:GetErrorMessage:='Le fichier n''est pas ouvert … la sortie';
  106:GetErrorMessage:='Numero invalide';
  150:GetErrorMessage:='Disque protege en ecriture';
  151:GetErrorMessage:='Peripherique est inconnu';
  152:GetErrorMessage:='Disque pas pret';
  153:GetErrorMessage:='Commande inconnue';
  154:GetErrorMessage:='Echec de verification CRC';
  155:GetErrorMessage:='Disque invalide';
  156:GetErrorMessage:='Erreur de recherche sur disque';
  157:GetErrorMessage:='Type de media invalide';
  158:GetErrorMessage:='Secteur introuvable';
  159:GetErrorMessage:='L''imprimante n''a plus de papier';
  160:GetErrorMessage:='Erreur d''ecriture sur le peripherique';
  161:GetErrorMessage:='Erreur de lecture sur le peripherique';
  162:GetErrorMessage:='Defaillance materielle';
  Else GetErrorMessage:='Erreur inconnue';
 End;
End;

Procedure HomeMessage;Begin
 CurrWidth:=36;
 TextMode(CO40);
 Window(1,1,40,25);
 TextBackground(0);
 TextColor($F);
 ClrScr;
 Window(1+2,1,36+2,24);
 TextBackground(0);
 TextColor($F);
 ClrScr;
 WriteLn('       Coleco SmartBASIC V1.0');
 GotoXY(1,24);
End;

Function ExtractCommand:Byte;
Var
 I:Byte;
Begin
 ExtractCommand:=255;
 CurrCommand:='';
 For I:=CurrPos to Length(CurrLine)do Begin
  If Not(CurrLine[I]in['A'..'Z','a'..'z','$','%','!','#'])Then Begin
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
 If NumberLine>=MaxLine Then Begin
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

Procedure QuickSort(Left,Right:Word);
Var
 Lower,Upper,Middle:Word;
 Pivot,T:String;
 Temp:StrPointer;
Begin
 Lower:=Left;
 Upper:=Right;
 Middle:=(Left+Right) shr 1;
 Pivot:=PA[Middle]^;
 Repeat
  While FirstNumberInStr(PA[Lower]^) < FirstNumberInStr(Pivot) do Inc(Lower);
  While FirstNumberInStr(Pivot) < FirstNumberInStr(PA[Upper]^) do Dec(Upper);
  If(Lower<=Upper)Then Begin
   Temp:=PA[Lower];
   PA[Lower]:=PA[Upper];
   PA[Upper]:=Temp;
   Inc(Lower);
   Dec(Upper);
  End;
 Until Lower>Upper;
 If Left<Upper Then QuickSort(Left,Upper);
 If Lower<Right Then QuickSort(Lower,Right);
End;

Procedure ResortList;Begin
 If NumberLine>1 Then QuickSort(1,NumberLine);
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

Function IsStringValue:Boolean;
Var
 I:Byte;
Begin
 IsStringValue:=False;
 If CurrLine[CurrPos]='"'Then Begin
  IsStringValue:=True;
 End
  Else
 Begin
  I:=CurrPos;
  While(CurrLine[I]in[' '])and(I<Length(CurrLine))do Inc(I);
  If CurrLine[I]in['A'..'Z','a'..'z']Then Begin
   Inc(I);
   While I<Length(CurrLine)do Begin
    If Not(CurrLine[I]in['A'..'Z','a'..'z','0'..'9'])Then Break;
    Inc(I);
   End;
   If(I<=Length(CurrLine))and(CurrLine[I]='$')Then IsStringValue:=True;
  End;
 End;
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
  While CurrPos<Length(CurrLine)do Begin
   If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z','0'..'9'])Then Break;
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
 End;
 ReadWord:=StrToUpper(S);
End;

Function ReadWordString:String;
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
  If CurrLine[CurrPos]='$'Then Begin
   S:=S+'$';
   Inc(CurrPos);
  End;
 End;
 ReadWordString:=StrToUpper(S);
End;

Function GetNumberValue(MinTopOfStack:Integer):Real;Forward;

Function GetStringValue:String;
Label Restart;
Var
 J:Integer;
 _Result:Real;
 FunctionFound:Boolean;
 S,VarName:String;
Begin
 GetStringValue:='';
 S:='';
Restart:
 If CurrLine[CurrPos]='"'Then Begin
  Inc(CurrPos);
  While(CurrLine[CurrPos]<>'"')and(CurrPos<=Length(CurrLine))do Begin
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
  If CurrLine[CurrPos]='"'Then Inc(CurrPos);
 End
  Else
 Begin
  VarName:=ReadWordString;
  SkipSpace;
  FunctionFound:=False;
  For J:=Low(FunctionList)to High(FunctionList)do Begin
   If FunctionList[J]=VarName Then Begin
    FunctionFound:=True;
    Case J of
     3:Begin{CHR$}
      If CurrLine[CurrPos]<>'('Then Begin
       WriteLn('"(" attendu');
       Exit;
      End;
      Inc(CurrPos);
      _Result:=GetNumberValue(1);
      If CurrLine[CurrPos]<>')'Then Begin
       WriteLn('")" attendu');
       Exit;
      End;
      Inc(CurrPos);
      S:=S+Chr(Byte(Trunc(_Result)));
      GetStringValue:=S;
      Break;
     End;
     Else Begin
      WriteLn('Type incompatible');
      Exit;
     End;
    End;
   End;
  End;
  If Not(FunctionFound)Then Begin
   If VariableExist(VarName)Then Begin
    S:=S+GetVariableString(VarName);
   End;
  End;
 End;
 SkipSpace;
 If CurrLine[CurrPos]in['+',';']Then Begin
  Inc(CurrPos);
  Goto Restart;
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
 StopChar:=[',',':',';','"','<','=','>'];
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
   While(I<=Length(Infix))and(Infix[I]in['A'..'Z','a'..'z','%','!','#'])do Begin
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
      WriteLn('Type incompatiable');
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
       0:Begin{ABS}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        If Frac(_Result)=0.0 Then Str(Trunc(_Result),Value)
                             Else Str(_Result,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       1:Begin{ASC}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        Value:=GetStringValue;
        If Length(Value)=0Then _Result:=0.0
                          Else _Result:=Ord(Value[1]);
        Str(_Result:0:0,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       2:Begin{ATN}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(ArcTan(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       3:Begin{CHR$}
        WriteLn('Type incompatible');
        Exit;
       End;
       4:Begin{CINT}
       End;
       5:Begin{CSNG}
       End;
       6:Begin{CSRLIN}
        Str(WhereY,Value);
       End;
       7:Begin{COS}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Cos(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       8:Begin{CVD}
       End;
       9:Begin{CVI}
       End;
       10:Begin{CVS}
       End;
       11:Begin{DATE$}
       End;
       12:Begin{EOF}
       End;
       13:Begin{ERL}
       End;
       14:Begin{ERR}
       End;
       15:Begin{EXP}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Exp(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       16:Begin{FIX}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=Trunc(GetNumberValue(TopOfStack));
        Str(_Result:0:0,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       17:Begin{FRE}
       End;
       18:Begin{INKEY$}
       End;
       19:Begin{INP}
       End;
       20:Begin{INPUT$}
       End;
       21:Begin{INSTR}
       End;
       22:Begin{INT}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=Round(GetNumberValue(TopOfStack));
        Str(_Result:0:0,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       23:Begin{LEFT$}
       End;
       24:Begin{LEN}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        Value:=GetStringValue;
        If Length(Value)=0Then _Result:=0.0
                          Else _Result:=Length(Value);
        Str(_Result:0:0,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       25:Begin{LOF}
       End;
       26:Begin{LOG}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Ln(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       27:Begin{LPOS}
       End;
       28:Begin{LTRIM$}
       End;
       29:Begin{MID$}
       End;
       30:Begin{OCT$}
       End;
       31:Begin{PEEK}
       End;
       32:Begin{PLAY}
       End;
       33:Begin{PMAP}
       End;
       34:Begin{POS}
       End;
       35:Begin{RIGHT$}
       End;
       36:Begin{RND}
       End;
       37:Begin{RTRIM$}
       End;
       38:Begin{SCREEN}
       End;
       39:Begin{SGN}
       End;
       40:Begin{SIN}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Sin(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       41:Begin{SQR}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Sqrt(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       42:Begin{STR$}
       End;
       43:Begin{STRIG}
       End;
       44:Begin{STRING$}
       End;
       45:Begin{TAN}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Tan(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       46:Begin{TAB}
       End;
       47:Begin{TIME$}
       End;
       48:Begin{TIMER}
       End;
       49:Begin{TRIM$}
       End;
       50:Begin{USR}
       End;
       51:Begin{VAL}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        Value:=GetStringValue;
        Val(Value,_Result,Err);
        Str(_Result,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       52:Begin{VARPTR}
       End;
       53:Begin{VARPTR$}
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
  If(StrToUpper(Copy(Infix,I,4))='THEN')or(StrToUpper(Copy(Infix,I,2))='TO')Then Break;
 Until I>Length(Infix);
 CurrPos:=I;
 While(TopOfStack>MinTopOfStack)do PostFix:=PostFix+StackPop;
  { Transformation en POSTFIX }
 I:=1;
 Repeat
  If PostFix[I]in['*','+','-',' ']Then Begin
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

 { Traitement des commandes }
Procedure AttrCommand;
Var
 Foreground,Background:Real;
Begin
 Background:=GetNumberValue(1);
 TextBackground(Trunc(Background));
 If GetSeparator=','Then Begin
  Inc(CurrPos);
  Foreground:=GetNumberValue(1);
  If GetSeparator=','Then Begin
   Inc(CurrPos);
   If UpCase(CurrLine[CurrPos])='B'Then Begin
    Inc(CurrPos);
    Foreground:=Foreground+Blink;
   End;
  End;
  TextColor(Trunc(Foreground));
 End;
End;

Procedure BeepCommand;Begin
 Sound(1550);
 Delay(182);
 NoSound;
End;

Procedure CatalogCommand;
Var
 Info:SearchRec;
 CurrDrive:Char;
Begin
 CurrDrive:=GetCurrentDisk;
 FindFirst('*.*',AnyFile,Info);
 While DOSError=0 do Begin
 { Write(PadRight(Info.Name,18));}
  If(Info.Attr and ReadOnly=ReadOnly)Then Write('*')
                                     Else Write(' ');
  If(Path2Ext(Info.Name)='.EXE')or(Path2Ext(Info.Name)='.COM')Then Write('B')Else
  If(Path2Ext(Info.Name)='.BAS')Then Write('A') Else
  If(Path2Ext(Info.Name)='.TXT')Then Write('T')
                                Else Write('S');
  Write(' ',Info.Size shr 9:5,'  ');
  WriteLn(StrToUpper(Info.Name));
  FindNext(Info);
  FindNext(Info);
 End;
 WriteLn;
 WriteLn(' ',DiskFree(Byte(CurrDrive)-64)shr 9:10,' block(s) de libre');
 WriteLn;
End;

Procedure ColorCommand;
Var
 Foreground,Background:Real;
Begin
 Foreground:=GetNumberValue(1);
 TextColor(Trunc(Foreground));
 If GetSeparator=','Then Begin
  Inc(CurrPos);
  Background:=GetNumberValue(1);
  TextBackground(Trunc(Background));
 End;
End;

Procedure ChDirCommand;
Var
 Error:Word;
 S:String;
Begin
 SkipSpace;
 {$I-} ChDir(GetStringValue);{$I+}
 Error:=IoResult;
 If Error<>0Then WriteLn(GetErrorMessage(Error));
End;

Function ForCommand:Boolean;
Var
 R1,R2:Real;
Begin
 ForCommand:=False;
 If ForPos>=High(ForStack)Then Begin
  WriteLn('Pile de FOR pleine.');
  Exit;
 End;
 Inc(ForPos);
 ForStack[ForPos].Line:=CurrLinePtr;
 ForStack[ForPos].LineNumber:=CurrNumberLine;
 SkipSpace;
 ForStack[ForPos].VarName:=Copy(GetVariableName,1,20);
 SkipSpace;
 If GetSeparator<>'='Then Begin
  WriteLn('"=" attendu.');
  Exit;
 End;
 Inc(CurrPos);
 R1:=GetNumberValue(1);
 If VariableExist(ForStack[ForPos].VarName)Then
  SetVariableReal(ForStack[ForPos].VarName,Trunc(R1))
 Else
  AddVariableReal(ForStack[ForPos].VarName,Trunc(R1));
 SkipSpace;
 If StrToUpper(ReadWord)<>'TO'Then Begin
  WriteLn('Mot r‚serv‚ "TO" attendu');
  Exit;
 End;
 SkipSpace;
 ForStack[ForPos].Col:=CurrPos;
 R2:=GetNumberValue(1);
 ForCommand:=True;
End;

Function GosubCommand:Boolean;
Var
 JumpLine:Integer;
 I,J,Err:Integer;
Begin
 GosubCommand:=True;
 If GosubPos>=High(GosubStack)Then Begin
  WriteLn('Pile de GOSUB pleine !');
  GosubCommand:=False;
  Exit;
 End;
 JumpLine:=Trunc(GetNumberValue(1));
 If(CurrPos<=Length(CurrLine))and(CurrLine[CurrPos]=':')Then Inc(CurrPos);
 Inc(GosubPos);
 GosubStack[GosubPos].Line:=CurrLinePtr;
 GosubStack[GosubPos].Col:=CurrPos;
 GosubStack[GosubPos].LineNumber:=CurrNumberLine;
 If NumberLine>0Then Begin
  For I:=1 to NumberLine do If(FirstNumberInStr(PA[I]^)=JumpLine)Then Begin
   CurrNumberLine:=JumpLine;
   CurrLine:=PA[I]^;
   CurrLinePtr:=I;
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
   Exit;
  End;
 End;
 WriteLn('Etiquette introuvable');
 GosubCommand:=False;
End;

Function GotoCommand:Boolean;
Var
 JumpLine:Integer;
 I,J,Err:Integer;
Begin
 GotoCommand:=True;
 JumpLine:=Trunc(GetNumberValue(1));
 If NumberLine>0Then Begin
  For I:=1 to NumberLine do If(FirstNumberInStr(PA[I]^)=JumpLine)Then Begin
   CurrNumberLine:=JumpLine;
   CurrLine:=PA[I]^;
   CurrLinePtr:=I;
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
   Exit;
  End;
 End;
 WriteLn('Etiquette introuvable');
 GotoCommand:=False;
End;

Procedure FlashCommand;Begin
 TextColor((TextAttr and $F)+BLINK);
End;

Procedure HelpCommand;
Var
 I:Byte;
Begin
 For I:=Low(CommandList) to High(CommandList) do Begin
  If CurrWidth=36 Then Write(PadRight(CommandList[I],18))
                  Else Write(PadRight(CommandList[I],10));
 End;
 WriteLn;
End;

Procedure HTabCommand;
Var
 N:Real;
Begin
 N:=GetNumberValue(1);
 GotoXY(Trunc(N),WhereY);
End;

Procedure IfCommand;
Var
 ResultCmp:Boolean;
 Compare:String;
 R1,R2:Real;
 S,S1,S2:String;
Begin
 If GetSeparator='"'Then Begin
  Compare:='';
  S1:=GetStringValue;
  Case GetSeparator of
   '=':Begin
    Compare:='=';
    Inc(CurrPos);
   End;
   '<':Begin
    Inc(CurrPos);
    If GetSeparator='='Then Begin
     Compare:='<=';
     Inc(CurrPos);
    End
     Else
    Compare:='<';
   End;
   '>':Begin
    Inc(CurrPos);
    If GetSeparator='='Then Begin
     Compare:='>=';
     Inc(CurrPos);
    End
     Else
    Compare:='>';
   End;
  End;
  S2:=GetStringValue;
  If Compare='<='Then ResultCmp:=S1<=S2 Else
  If Compare='<'Then ResultCmp:=S1<S2 Else
  If Compare='>='THen ResultCmp:=S1>=S2 Else
  If Compare='>'Then ResultCmp:=S1>S2 Else
  If Compare='='Then ResultCmp:=S1=S2
   Else
  Begin
   WriteLn('Erreur d''operateur de comparaison');
   Exit;
  End;
 End
  Else
 Begin
  Compare:='';
  R1:=GetNumberValue(1);
  Case GetSeparator of
   '=':Begin
    Inc(CurrPos);
    Compare:='=';
   End;
   '<':Begin
    Inc(CurrPos);
    If GetSeparator='='Then Begin
     Inc(CurrPos);
     Compare:='<=';
    End
     Else
    Compare:='<';
   End;
   '>':Begin
    Inc(CurrPos);
    If GetSeparator='='Then Begin
     Compare:='>=';
     Inc(CurrPos);
    End
     Else
    Compare:='>';
   End;
  End;
  R2:=GetNumberValue(1);
  If Compare='<='Then ResultCmp:=R1<=R2 Else
  If Compare='<'Then ResultCmp:=R1<R2 Else
  If Compare='>='THen ResultCmp:=R1>=R2 Else
  If Compare='>'Then ResultCmp:=R1>R2 Else
  If Compare='='Then ResultCmp:=R1=R2
   Else
  Begin
   WriteLn('Erreur d''operateur de comparaison');
   Exit;
  End;
 End;
 While CurrPos<Length(CurrLine) do Begin
  If Not(CurrLine[CurrPos]in[#9,' '])Then Break;
  Inc(CurrPos);
 End;
 S:='';
 While CurrPos<Length(CurrLine) do Begin
  If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z'])Then Break;
  S:=S+CurrLine[CurrPos];
  Inc(CurrPos);
 End;
 If StrToUpper(S)<>'THEN'Then Begin
  WriteLn('Mot reserve THEN introuvable');
  Exit;
 End;
 While CurrPos<Length(CurrLine) do Begin
  If Not(CurrLine[CurrPos]in[#9,' '])Then Break;
  Inc(CurrPos);
 End;
 If ResultCmp Then Exit;
 While CurrPos<Length(CurrLine) do Begin
  If(CurrLine[CurrPos]in[#9,' ',':'])and(StrToUpper(Copy(CurrLine,CurrPos+1,4))='ELSE')Then Begin
   Inc(CurrPos,5);
   Break;
  End;
  Inc(CurrPos);
 End;
End;

Procedure InverseCommand;
Var
 CurrAttr:Byte;
Begin
 CurrAttr:=TextAttr;
 TextBackground(CurrAttr and $F);
 TextColor(CurrAttr shr 4);
End;

Procedure ListCommand;
Var
 I:Integer;
Begin
 If NumberLine>0Then Begin
  For I:=1 to NumberLine do WriteLn(PA[I]^);
 End;
End;

Procedure LListCommand;
Var
 I:Integer;
Begin
 If NumberLine>0Then Begin
  For I:=1 to NumberLine do WriteLn(Lst,PA[I]^);
 End;
End;

Procedure LoadCommand;
Var
 FileLoad:Text;
 S:String;
Begin
 If GetSeparator='"'Then Begin
  FileName:=GetStringValue;
  If FileName<>''Then Begin
   If StrToUpper(Copy(FileName,Length(FileName)-3,4))<>'.BAS'Then FileName:=FileName+'.BAS';
   {$I-}Assign(FileLoad,FileName);
   Reset(FileLoad);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Fichier introuvable');
    Exit;
   End;
   NewCommand;
   While Not EOF(FileLoad) do Begin
    ReadLn(FileLoad,S);
    If Not AddLine(LTrim(S))Then Begin
     WriteLn('Manque de m‚moire');
     Break;
    End;
   End;
   Close(FileLoad);
   ResortList;
  End
   Else
  WriteLn('Nom du fichier absent');
 End
  Else
 WriteLn('Chaine de caractŠres attendu');
End;

Procedure LocateCommand;
Var
 X,Y:Real;
Begin
 X:=GetNumberValue(1);
 If GetSeparator=','Then Begin
  Inc(CurrPos);
  Y:=GetNumberValue(1);
  If(X>80.0)or(X<0.0)Then Begin
   WriteLn('Appel de fonction invalide');
   Exit;
  End;
  GotoXY(Trunc(X),Trunc(Y));
 End
  Else
 WriteLn('Erreur de syntaxe');
End;

Procedure MkDirCommand;
Var
 Error:Word;
 S:String;
Begin
 SkipSpace;
 {$I-} MkDir(GetStringValue);{$I+}
 Error:=IoResult;
 If Error<>0Then WriteLn(GetErrorMessage(Error));
End;

Procedure NewCommand;
Var
 I:Integer;
Begin
 For I:=1 to NumberLine do FreeMem(PA[I],Length(PA[I]^)+1);
 NumberLine:=0;
End;

Function NextCommand:Boolean;
Var
 NextCurrPos,NextCurrLinePtr,NextCurrNumberLine:Word;
 R2:Real;
Begin
 NextCommand:=False;
 If ForPos=0 Then Begin
  WriteLn('NEXT sans FOR');
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
 NextCommand:=True;
End;

Procedure NormalCommand;Begin
 TextColor((TextAttr and $F));
End;

Procedure PrintCommand;
Var
 R:Real;
Begin
 SkipSpace;
 Begin
  If IsStringValue Then Begin
   WriteLn(GetStringValue);
  End
   Else
  Begin
   If CurrPos>Length(CurrLine)Then WriteLn
    Else
   Begin
    R:=GetNumberValue(1);
    If Frac(R)=0.0Then WriteLn(R:0:0)
                  Else WriteLn(R);
   End;
  End;
 End;
End;

Procedure ReturnCommand;Begin
 If(GosubPos=0)Then Begin
  WriteLn('RETURN sans GOSUB');
  Exit;
 End;
 CurrPos:=GosubStack[GosubPos].Col;
 CurrLinePtr:=GosubStack[GosubPos].Line;
 CurrLine:=PA[CurrLinePtr]^;
 CurrNumberLine:=GosubStack[GosubPos].LineNumber;
 Dec(GosubPos);
End;

Procedure RunCommand;
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
     If(Tron)Then Write('[',CurrNumberLine,']');
     Break;
    End;
    Inc(J);
   End;
   While J<=Length(CurrLine)do Begin
    If CurrLine[J]in[' ',#9]Then Inc(J)
                            Else Break;
   End;
   CurrPos:=J;
   If Not RunBasic(True)Then Break;
   Inc(CurrLinePtr);
  End;
 End;
End;

Procedure SaveCommand;
Var
 I:Integer;
 Target:Text;
Begin
 If GetSeparator='"'Then Begin
  FileName:=GetStringValue;
  If FileName=''Then Begin
   WriteLn('Sauvegarde avec un nom vide impossible');
   Exit;
  End;
  {$I-}Assign(Target,FileName);
  Rewrite(Target);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de creer le fichier');
   Exit;
  End;
  If NumberLine>0Then Begin
   For I:=1 to NumberLine do WriteLn(Target,PA[I]^);
  End;
  Close(Target);
 End
  Else
 Begin
  If FileName<>''Then Begin
   {$I-}Assign(Target,FileName);
   Rewrite(Target);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Impossible de creer le fichier');
    Exit;
   End;
   If NumberLine>0Then Begin
    For I:=1 to NumberLine do WriteLn(Target,PA[I]^);
   End;
   Close(Target);
  End
   Else
  WriteLn('Sauvegarde sans nom impossible');
 End;
End;

Procedure SleepCommand;
Var
 N:Real;
Begin
 N:=GetNumberValue(1);
 Delay(Trunc(N*1000));
End;

Procedure SoundCommand;
Var
 Frequence,Intervalle:Real;
Begin
 Frequence:=GetNumberValue(1);
 If GetSeparator=','Then Begin
  Inc(CurrPos);
  Intervalle:=GetNumberValue(1);
  If(Frequence>255.0)or(Intervalle>255.0)Then Begin
   WriteLn('Erreur de fonction');
   Exit;
  End;
  Sound(Trunc(Frequence*255));
  Delay(Trunc(Intervalle*20));
  NoSound;
 End
  Else
 WriteLn('Erreur de syntaxe');
End;

Procedure TroffCommand;Begin
 Tron:=False;
End;

Procedure TronCommand;Begin
 Tron:=True;
End;

Function WidthCommand:Boolean;
Var
 OldTextAttr:Byte;
 Width:Real;
Begin
 WidthCommand:=True;
 Width:=GetNumberValue(1);
 Case Trunc(Width)of
  32:Begin
   CurrWidth:=32;
   TextMode(C40);
   Window(1,1,40,25);
   TextBackground(0);
   TextColor($F);
   ClrScr;
   Window(1+4,1+4,32+4,16+4);
   TextBackground($2);
   TextColor(0);
   ClrScr;
  End;
  40:Begin
   OldTextAttr:=TextAttr;
   CurrWidth:=40;
   TextMode(C40);
   TextColor(OldTextAttr and$F);
   TextBackground(OldTextATtr shr 4);
   Window(1,1,40,24);
   ClrScr;
  End;
  80:Begin
   OldTextAttr:=TextAttr;
   CurrWidth:=80;
   TextMode(C80);
   TextColor(OldTextAttr and$F);
   TextBackground(OldTextAttr shr 4);
   Window(1,1,80,24);
   ClrScr;
  End;
  Else Begin
   WriteLn('Valeur invalide');
   WidthCommand:=False;
  End;
 End;
End;

Function RunBasic(InList:Boolean):Boolean;
Var
 UnknownCommand:Boolean;
 NoImplementation:Boolean;
 J,Err:Integer;
 R1:Real;
 S1:String;
Begin
 RunBasic:=False;
 If Not(InList)Then Begin
  CurrPos:=1;
  J:=1;CurrNumberLine:=0;
  While(J<Length(CurrLine))do Begin
   If Not(CurrLine[J]in['0'..'9'])Then Begin
    Val(Copy(CurrLine,1,J-1),CurrNumberLine,Err);
    Break;
   End;
   Inc(J);
  End;
  If CurrNumberLine<>0Then Begin
   AddLine(CurrLine);
   ResortList;
   Exit;
  End;
 End;
 Repeat
  NoImplementation:=False;
  UnknownCommand:=False;
  Case ExtractCommand of
   0:NoImplementation:=True;{AND}
   1:NoImplementation:=True;{APPEND}
   2:NoImplementation:=True;{BLOAD}
   3:NoImplementation:=True;{BRUN}
   4:NoImplementation:=True;{BSAVE}
   5:NoImplementation:=True;{CALL}
   6:CatalogCommand;{CATALOG}
   7:NoImplementation:=True;{CLEAR}
   8:NoImplementation:=True;{CLOSE}
   9:NoImplementation:=True;{CONT}
   10:NoImplementation:=True;{DATA}
   11:NoImplementation:=True;{DEF}
   12:NoImplementation:=True;{DEL}
   13:NoImplementation:=True;{DELETE}
   14:NoImplementation:=True;{DIM}
   15:NoImplementation:=True;{DRAW}
   16:Exit;{END}
   17:FlashCommand;{FLASH}
   18:If Not(ForCommand)Then Exit;{FOR}
   19:NoImplementation:=True;{GET}
   20:If Not(GosubCommand)Then Exit;{GOSUB}
   21:If Not(GotoCommand)Then Exit;{GOTO}
   22:NoImplementation:=True;{GR}
   23:HelpCommand;{HELP}
   24:NoImplementation:=True;{HGR}
   25:NoImplementation:=True;{HGR2}
   26:NoImplementation:=True;{HIMEM}
   27:NoImplementation:=True;{HLIN}
   28:ClrScr;{HOME}
   29:NoImplementation:=True;{HPLOT}
   30:HTabCommand;{HTAB}
   31:IfCommand;{IF}
   32:NoImplementation:=True;{INIT}
   33:NoImplementation:=True;{INPUT}
   34:InverseCommand;{INVERSE}
   35:NoImplementation:=True;{LET}
   36:ListCommand;{LIST}
   37:LoadCommand;{LOAD}
   38:NoImplementation:=True;{LOCK}
   39:NoImplementation:=True;{LOMEM}
   40:NoImplementation:=True;{MON}
   41:NewCommand;{NEW}
   42:If Not(NextCommand)Then Exit;{NEXT}
   43:NoImplementation:=True;{NOMON}
   44:NormalCommand;{NORMAL}
   45:NoImplementation:=True;{NOTRACE}
   46:NoImplementation:=True;{ON}
   47:NoImplementation:=True;{ONERR}
   48:NoImplementation:=True;{OPEN}
   49:NoImplementation:=True;{PLOT}
   50:NoImplementation:=True;{POKE}
   51:NoImplementation:=True;{POP}
   52:NoImplementation:=True;{POSITION}
   53:NoImplementation:=True;{PR}
   54:PrintCommand;{PRINT}
   55:NoImplementation:=True;{READ}
   56:NoImplementation:=True;{RECOVER}
   57:Begin
    RunBasic:=True;
    Exit;{REM}
   End;
   58:NoImplementation:=True;{RENAME}
   59:ReturnCommand;{RETURN}
   60:NoImplementation:=True;{RETURN}
   61:RunCommand;{RUN}
   62:SaveCommand;{SAVE}
   63:Exit;{STOP}
   64:Begin {SYSTEM}
    Terminated:=True;
    Exit;
   End;
   65:NoImplementation:=True;{THEN}
   66:NoImplementation:=True;{TEXT}
   67:NoImplementation:=True;{TRACE}
   68:NoImplementation:=True;{UNLOCK}
   69:NoImplementation:=True;{VLIN}
   70:NoImplementation:=True;{VTAB}
   71:NoImplementation:=True;{WAIT}
   72:NoImplementation:=True;{XDRAW}
   Else UnknownCommand:=True;
  End;
  If(UnknownCommand)Then Begin
   SkipSpace;
   If CurrLine[CurrPos]='='Then Begin
    Case CurrCommand[Length(CurrCommand)]of
     '%':Begin
      R1:=GetNumberValue(1);
      If VariableExist(CurrCommand)Then
       SetVariableInt(CurrCommand,Trunc(R1))
      Else
       AddVariableInt(CurrCommand,Trunc(R1));
     End;
     '#','!':Begin
      R1:=GetNumberValue(1);
      If VariableExist(CurrCommand)Then
       SetVariableReal(CurrCommand,Trunc(R1))
      Else
       AddVariableReal(CurrCommand,Trunc(R1));
     End;
     '$':Begin
      Inc(CurrPos);
      S1:=GetStringValue;
      If VariableExist(CurrCommand)Then
       SetVariableString(CurrCommand,S1)
      Else
       AddVariableString(CurrCommand,S1);
     End;
     Else Begin
      R1:=GetNumberValue(1);
      If VariableExist(CurrCommand)Then
       SetVariableLongInt(CurrCommand,Trunc(R1))
      Else
       AddVariableLongInt(CurrCommand,Trunc(R1));
     End;
    End;
   End
    Else
   WriteLn('Commande illegale');
   Exit;
  End;
  If(NoImplementation)Then Begin
   WriteLn('Cette commande n''a pas ete implemente');
   Exit;
  End;
  While(CurrLine[CurrPos]in[' ',':'])and(CurrPos<=Length(CurrLine)) do Inc(CurrPos);
  If CurrPos>=Length(CurrLine)Then Break;
  If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z','_'])Then Begin
   If(InList)Then WriteLn('Erreur de syntaxe a la position ',CurrPos,' de la ligne ',CurrNumberLine)
             ELse WriteLn('Erreur de syntaxe a la position ',CurrPos);
   Exit;
  End;
 Until CurrPos>Length(CurrLine);
 RunBasic:=True;
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ADAM : Cette commande permet de lancer l''interpreteur de Adam SmartBASIC.');
  WriteLn;
  WriteLn('Syntaxe : ADAM [fichier]');
 End
  Else
 Begin
  FileName:='';
  Tron:=False;
  NumberLine:=0;CurrNumberLine:=0;
  NumberVariable:=0;GosubPos:=0;ForPos:=0;
  For I:=1 to ParamCount do Begin
   FileName:=ParamStr(I);
  End;
  HomeMessage;
  If FileName<>''Then Begin
   CurrLine:='LOAD "'+FileName+'":RUN';
   RunBasic(False);
  End;
  Terminated:=False;
  Repeat
   Write(']');
   ReadLn(CurrLine);
   CurrLine:=LTrim(CurrLine);
   WriteLn;
   RunBasic(False);
  Until Terminated;
  TextMode(CO80);
  Window(1,1,80,25);
  TextBackground(0);
  TextColor(7);
  ClrScr;
 End;
END.
