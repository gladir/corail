{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal, Turbo Pascal)
}

Program AWK;

Uses
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  {$IFDEF DARWIN}
  MacOSAll, { nï¿½cessaire pour appeler ObjC sous macOS/iOS }
  CocoaAll,
  {$ENDIF}
  {$IFDEF UNIX}
  BaseUnix,
  {$ENDIF}
  DOS;

Const
 TokenList:Array[0..69]of String[20]=(
  'BEGIN','BEGINFILE','END','ENDFILE','and','asort','asorti','atan2',
  'bindtextdomain','break','case','close','compl','continue','cos',
  'dcgettext','dcngettext','default','delete','do','else','eval',
  'exit','exp','fflush','for','func','function','gensub','getline',
  'gsub','if','in','include','index','int','isarray','length',
  'load','log','lshift','match','mktime','namespace','next',
  'nextfile','or','patsplit','print','printf','rand','return',
  'rshift','sin','split','sprintf','sqrt','srand','strftime',
  'strtonum','sub','substr','switch','system','systime','tolower',
  'toupper','typeof','while','xor'
 );

 FunctionList:Array[0..15]of String[12]=(
  'ATAN2','COS','EXP','GSUB','INDEX','INT','LENGTH','LOG','MATCH',
  'RAND','SIN','SPLIT','SPRINTF','SQRT','SRAND','SUBSTR'
 );

 MaxLine=1024;
 MaxVariable=100;
 MaxFields=10;

Type
 StrPointer=^String;
 FieldArray=Array[0..MaxFields]of String;
 VarTypeEnum=(_None,_Integer,_LongInt,_Real,_String);
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

Var
 Fields:FieldArray;
 NumFields:Integer;
 FileAWK:Text;
 Mode:(_None_,_F,_InStringSimpleQuote);
 Terminated:Boolean;
 CurrCommand,CurrParam:String;
 FileName,CurrLine:String;
 CurrPos:Byte;
 PA:Array[1..MaxLine] of StrPointer;
 VarList:Array[1..MaxVariable]of VarPointer;
 CurrLinePtr,NumberLine:Integer;
 CurrNumberLine:Integer;
 AccoladeBlock:Integer;
 I,NumberVariable:Integer;

Function GetRawCommandLine:String;
{$IFDEF FPC}
 {$IFDEF WINDOWS}
  Var
   pw:PWideChar;
  Begin
   pw:=GetCommandLineW();
   GetRawCommandLine:=UTF8Encode(WideString(pw)); { convertir UTF-16 vers UTF-8 }
  End;
 {$ELSE}
  {$IFDEF LINUX}
   Var
     f:File;
     buffer:RawByteString;
   Begin
    Assign(f, '/proc/self/cmdline');
    Reset(f, 1);
    SetLength(buffer, FileSize(f));
    BlockRead(f, buffer[1], Length(buffer));
    Close(f);
    { /proc/self/cmdline sï¿½pare les paramï¿½tres avec #0 }
    GetRawCommandLine:= StringReplace(buffer, #0, ' ', [rfReplaceAll]);
   End;
  {$ELSE}
   {$IFDEF DARWIN}
    Var
     ProcInfo:NSObject;
     nsArgs:NSArray;
     i:Integer;
     argStr:NSString;
    Begin
     procInfo:=NSProcessInfo.processInfo;
     nsArgs:=NSProcessInfo(procInfo).arguments;
     GetRawCommandLine:='';
     For i:=0 to nsArgs.count-1 do Begin
      argStr:= NSString(nsArgs.objectAtIndex(i));
      GetRawCommandLine:=GetRawCommandLine+UTF8Encode(argStr.UTF8String)+' ';
     End;
    End;
   {$ELSE}
    Var
     S:String;
    Begin
     S:='';
     For I:=1 to ParamCount do Begin
      S:=S+ParamStr(I);
     End;
     GetRawCommandLine:=S;
    End;
   {$ENDIF}
  {$ENDIF}
 {$ENDIF}
{$ELSE}
 Var
  PtrStr:^String;
 Begin
  PtrStr:=Ptr(PrefixSeg,$80);
  GetRawCommandLine:=PtrStr^;
 End;
{$ENDIF}

Function IsDelimiter(C:Char):Boolean;Begin
 IsDelimiter:=(C=' ')or(C=#9)or(C=#13)or(C=#10);
End;

Function RawParamCount:Integer;
Var
 PC:Integer;
 I:Integer;
 InQuote,InApos,InBrace:Boolean;
 CmdLine:String;
Begin
 PC:=0;
 InQuote:=False;
 InApos:=False;
 InBrace:=False;
 CmdLine:=GetRawCommandLine;
 I:=1;
 While I<=Length(CmdLine)do Begin
  While(I<=Length(CmdLine))and(IsDelimiter(CmdLine[I]))do Inc(I);
  If I<=Length(CmdLine)Then Begin
   Inc(PC);
   While(I<=Length(CmdLine))do Begin
    Case CmdLine[I]of
     '"':If Not(InApos)and Not(InBrace)Then InQuote:=Not(InQuote);
     '''':If Not(InQuote)and Not(InBrace)Then InApos:=Not(InApos);
     '{':If Not(InQuote)and Not(InApos)Then InBrace:=True;
     '}':If Not(InQuote)and Not(InApos)Then InBrace:=False;
     ' ',#9,#13,#10:If Not(InQuote)and Not(InApos)and Not(InBrace)Then Break;
    End;
    Inc(I);
   End;
  End;
 End;
 RawParamCount:=PC-1; { -1 car on ne compte pas le nom du programme }
End;

Function RawParamStr(Index:Integer):String;
Var
 PC,StartPos:Integer;
 I:Integer;
 InQuote,InApos,InBrace:Boolean;
 CmdLine,Param:String;
Begin
 PC:=0;
 InQuote:=False;
 InApos:=False;
 InBrace:=False;
 CmdLine:=GetRawCommandLine;
 I:=1;
 While I<=Length(CmdLine)do Begin
  While(I<=Length(CmdLine))and(IsDelimiter(CmdLine[I]))do Inc(I);
  If I<=Length(CmdLine)Then Begin
   Inc(PC);
   If PC=Index+1 Then Begin
    StartPos:=I;
    While(I<=Length(CmdLine))do Begin
     Case CmdLine[I]of
      '"':If Not(InApos)and Not(InBrace)Then InQuote:=Not(InQuote);
      '''':If Not(InQuote)and Not(InBrace)Then InApos:=Not(InApos);
      '{':If Not(InQuote)and Not(InApos)Then InBrace:=True;
      '}':If Not(InQuote)and Not(InApos)Then InBrace:=False;
      ' ',#9,#13,#10:If Not(InQuote)and Not(InApos)and Not(InBrace)Then Break;
     End;
     Inc(I);
    End;
    RawParamStr:=Copy(CmdLine,StartPos,I-StartPos);
    Exit;
   End;
   While(I<=Length(CmdLine))do Begin
    Case CmdLine[I]of
     '"':If Not(InApos)and Not(InBrace)Then InQuote:=Not(InQuote);
     '''':If Not(InQuote)and Not(InBrace)Then InApos:=Not(InApos);
     '{':If Not(InQuote)and Not(InApos) Then InBrace:=True;
     '}':If Not(InQuote)and Not(InApos) Then InBrace:=False;
     ' ',#9,#13,#10:If Not(InQuote)and Not(InApos)and Not(InBrace)Then Break;
    End;
    Inc(I);
   End;
  End;
 End;
 RawParamStr:='';
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

Function ExtractCommand:Byte;
Var
 I:Byte;
Begin
 ExtractCommand:=255;
 CurrCommand:='';
 For I:=CurrPos to Length(CurrLine)do Begin
  If Not(CurrLine[I]in['A'..'Z','a'..'z','$'])Then Begin
   CurrCommand:=Copy(CurrLine,CurrPos,I-CurrPos);
   CurrPos:=I;
   Break;
  End;
 End;
 If CurrCommand=''Then Begin
  CurrCommand:=Copy(CurrLine,CurrPos,255);
  CurrPos:=Length(CurrLine)+1;
 End;
 For I:=Low(TokenList)to High(TokenList)do Begin
  If CurrCommand=TokenList[I]Then Begin
   ExtractCommand:=I;
   Exit;
  End;
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
  WriteLn('Pile vide');
  Halt;
 End
  Else
 ResultStackPop:=ResultStack[TopOfStackInt];
End;

Function GetStringValue:String;
Var
 S:String;
Begin
 GetStringValue:='';
 S:='';
 If CurrLine[CurrPos]='"'Then Begin
  Inc(CurrPos);
  While(CurrLine[CurrPos]<>'"')and(CurrPos<=Length(CurrLine))do Begin
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
  If CurrLine[CurrPos]='"'Then Inc(CurrPos);
  GetStringValue:=S;
 End;
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
       1:Begin{COS}
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
       2:Begin{EXP}
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
       7:Begin{LOG}
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
  Else If Infix[I]='('Then Begin
   StackPushChar(Infix[I]);
   Inc(I);
  End
  Else If Infix[I]in['*','+','-','/']Then Begin
   While(TopOfStack>1)and(StackPeek <> '(')do Begin
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
  If StrToUpper(Copy(Infix,I,4))='THEN'Then Break;
 Until I>Length(Infix);
 CurrPos:=I;
 While(TopOfStack>1)do PostFix:=PostFix+StackPop;
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


Procedure BeginCommand;Begin
End;

Procedure PrintCommand;
Var
 R:Real;
Begin
 If GetSeparator='"'Then Begin
  WriteLn(GetStringValue);
 End
  Else
 Begin
  R:=GetNumberValue(1);
  If Frac(R)=0.0Then WriteLn(R:0:0)
                Else WriteLn(R);
 End;
End;

Procedure CosCommand;
Begin
 If GetSeparator<>'"'Then Begin
  WriteLn(Cos(GetNumberValue(1)));
 End
  Else
 Begin
  WriteLn('Erreur de syntaxe : cos attend une valeur numerique');
  Halt;
 End;
End;

Procedure SplitIntoFields(Line:String);
Var
 I,Start:Integer;
 InSpace:Boolean;
Begin
 NumFields:=0;
 I:=1;
 InSpace:=True;
 Start:=1;
 While I<=Length(Line)do Begin
  If(Line[I]in[' ',#9])Then Begin
   If Not InSpace Then Begin
    Fields[NumFields]:=Copy(Line,Start,I-Start);
    Inc(NumFields);
    InSpace:=True;
   End;
  End
   Else
  Begin
   If InSpace Then Begin
    Start:=I;
    InSpace:=False;
   End;
  End;
  Inc(I);
 End;
 If Not InSpace Then Begin
  Fields[NumFields]:=Copy(Line,Start,I-Start);
  Inc(NumFields);
 End;
End;

Function RunLine:Boolean;
Var
 UnknownCommand:Boolean;
 NoImplementation:Boolean;
 J,Err:Integer;
Begin
 RunLine:=False;
 Repeat
  If CurrLine[CurrPos]='{'Then  Begin
   Inc(AccoladeBlock);
   Inc(CurrPos);
  End;
  If CurrLine[CurrPos]='}'Then  Begin
   If(AccoladeBlock>0)Then Begin
    Dec(AccoladeBlock);
    Inc(CurrPos);
   End
    Else
   Begin
    WriteLn('Une fermeture d''accolade est rencontr‚ ',
            'sans ouverture d''accolade');
    Halt(1);
   End;
  End;
  If CurrLine[CurrPos]='#'Then Begin
   CurrPos:=Length(CurrLine);
   RunLine:=True;
   Exit;
  End;
  NoImplementation:=False;
  UnknownCommand:=False;
  Case ExtractCommand of
   0: BeginCommand;{BEGIN}
   1: NoImplementation:=True; {BEGINFILE}
   2: NoImplementation:=True; { END }
   3: NoImplementation:=True; {ENDFILE}
   4: NoImplementation:=True; { and }
   5: NoImplementation:=True; { asort }
   6: NoImplementation:=True; { asorti }
   7: NoImplementation:=True; { atan2 }
   8: NoImplementation:=True; { bindtextdomain }
   9: NoImplementation:=True; { break }
   10: NoImplementation:=True; { case }
   11: NoImplementation:=True; { close }
   12: NoImplementation:=True; { compl }
   13: NoImplementation:=True; { continue }
   14: CosCommand; { cos }
   15: NoImplementation:=True; { dcgettext }
   16: NoImplementation:=True; { dcngettext }
   17: NoImplementation:=True; { default }
   18: NoImplementation:=True; { delete }
   19: NoImplementation:=True; { do }
   20: NoImplementation:=True; { else }
   21: NoImplementation:=True; { eval }
   22:Begin
    Terminated:=True;
    Exit;
   End;{ exit }
   23: NoImplementation:=True; { exp }
   24: NoImplementation:=True; { fflush }
   25: NoImplementation:=True; { for }
   26: NoImplementation:=True; { func }
   27: NoImplementation:=True; { function }
   28: NoImplementation:=True; { gensub }
   29: NoImplementation:=True; { getline }
   30: NoImplementation:=True; { gsub }
   31: NoImplementation:=True; { if }
   32: NoImplementation:=True; { in }
   33: NoImplementation:=True; { include }
   34: NoImplementation:=True; { index }
   35: NoImplementation:=True; { int }
   36: NoImplementation:=True; { isarray }
   37: NoImplementation:=True; { length }
   38: NoImplementation:=True; { load }
   39: NoImplementation:=True; { log }
   40: NoImplementation:=True; { lshift }
   41: NoImplementation:=True; { match }
   42: NoImplementation:=True; { mktime }
   43: NoImplementation:=True; { namespace }
   44: NoImplementation:=True; { next }
   45: NoImplementation:=True; { nextfile }
   46: NoImplementation:=True; { or }
   47: NoImplementation:=True; { patsplit }
   48: PrintCommand; { print }
   49: NoImplementation:=True; { printf }
   50: NoImplementation:=True; { rand }
   51: NoImplementation:=True; { return }
   52: NoImplementation:=True; { rshift }
   53: NoImplementation:=True; { sin }
   54: NoImplementation:=True; { split }
   55: NoImplementation:=True; { sprintf }
   56: NoImplementation:=True; { sqrt }
   57: NoImplementation:=True; { srand }
   58: NoImplementation:=True; { strftime }
   59: NoImplementation:=True; { strtonum }
   60: NoImplementation:=True; { sub }
   61: NoImplementation:=True; { substr }
   62: NoImplementation:=True; { switch }
   63: NoImplementation:=True; { system }
   64: NoImplementation:=True; { systime }
   65: NoImplementation:=True; { tolower }
   66: NoImplementation:=True; { toupper }
   67: NoImplementation:=True; { typeof }
   68: NoImplementation:=True; { while }
   69: NoImplementation:=True; { xor }
   Else UnknownCommand:=True;
  End;
  If(UnknownCommand)Then Begin
   WriteLn('Commande non reconnu a la position ',CurrPos,' de la ligne ',CurrNumberLine+1);
   Exit;
  End;
  If(NoImplementation)Then Begin
   WriteLn('La commande ',CurrCommand,' n''a pas ete implemente');
   Exit;
  End;
  While(CurrLine[CurrPos]in[' ',';'])and(CurrPos<=Length(CurrLine)) do Inc(CurrPos);
  If CurrPos>=Length(CurrLine)Then Break;
  If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z','_'])Then Begin
   WriteLn('Erreur de syntaxe a la position ',CurrPos,' de la ligne ',CurrNumberLine+1);
   Exit;
  End;
 Until CurrPos>Length(CurrLine);
 RunLine:=True;
End;

Procedure RunProgram;
Var
 J:Integer;
 Err:Integer;
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
   If Not RunLine Then Break;
   Inc(CurrLinePtr);
  End;
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('AWK : Cette commande permet de lancer le langage de programmation AWK.');
  WriteLn;
  WriteLn('Syntaxe : AWK [-f nomfichier]');
  WriteLn;
  WriteLn(' -f   Ce paramŠtre permet d''indiquer un fichier de code source AWK');
 End
  Else
 If ParamCount>=1Then Begin
  NumberLine:=0;CurrNumberLine:=0;
  Mode:=_None_;FileName:='';
  CurrCommand:='';
  AccoladeBlock:=0;
  For I:=1 to RawParamCount do Begin
   CurrParam:=RawParamStr(I);
   If Mode=_InStringSimpleQuote Then Begin
    If CurrParam[Length(CurrParam)]=''''Then Begin
     CurrCommand:=CurrCommand+' '+Copy(CurrParam,1,Length(CurrParam)-1);
     Mode:=_None_;
    End
     Else
    CurrCommand:=CurrCommand+' '+CurrParam;
   End
    Else
   If Mode=_F Then Begin
    FileName:=CurrParam;
    Mode:=_None_;
   End
    Else
   If(Copy(CurrParam,1,1)='''')and(CurrParam[Length(CurrParam)]='''')Then Begin
    CurrCommand:=Copy(CurrParam,2,Length(CurrParam)-2);
   End
    Else
   If CurrParam='-f'Then Mode:=_F Else
   If(Copy(CurrParam,1,1)='''')Then Begin
    Mode:=_InStringSimpleQuote;
    CurrCommand:=Copy(CurrParam,2,Length(CurrParam)-1);
   End
    Else
   Begin
    WriteLn('ParamŠtre non reconnu');
    Halt(1);
   End;
  End;
  If CurrCommand<>''Then Begin
   CurrLine:=CurrCommand;
   CurrPos:=1;
   RunLine;
  End;
  If FileName<>''Then Begin
   {$I-}Assign(FileAWK,FileName);
   Reset(FileAWK);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Fichier introuvable');
    Exit;
   End;
   While Not EOF(FileAWK) do Begin
    ReadLn(FileAWK,CurrLine);
    If Not AddLine(CurrLine)Then Begin
     WriteLn('Manque de mï¿½moire');
     Break;
    End;
   End;
   Close(FileAWK);
   RunProgram;
  End;
 End;
END.
   56: NoImplementation:=True; { sqrt }
   57: NoImplementation:=True; { srand }
   58: NoImplementation:=True; { strftime }
   59: NoImplementation:=True; { strtonum }
   60: NoImplementation:=True; { sub }
   61: NoImplementation:=True; { substr }
   62: NoImplementation:=True; { switch }
   63: NoImplementation:=True; { system }
   64: NoImplementation:=True; { systime }
   65: NoImplementation:=True; { tolower }
   66: NoImplementation:=True; { toupper }
   67: NoImplementation:=True; { typeof }
   68: NoImplementation:=True; { while }
   69: NoImplementation:=True; { xor }
   Else UnknownCommand:=True;
  End;
  If(UnknownCommand)Then Begin
   WriteLn('Commande non reconnu a la position ',CurrPos,' de la ligne ',CurrNumberLine+1);
   Exit;
  End;
  If(NoImplementation)Then Begin
   WriteLn('La commande ',CurrCommand,' n''a pas ete implemente');
   Exit;
  End;
  While(CurrLine[CurrPos]in[' ',';'])and(CurrPos<=Length(CurrLine)) do Inc(CurrPos);
  If CurrPos>=Length(CurrLine)Then Break;
  If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z','_'])Then Begin
   WriteLn('Erreur de syntaxe a la position ',CurrPos,' de la ligne ',CurrNumberLine+1);
   Exit;
  End;
 Until CurrPos>Length(CurrLine);
 RunLine:=True;
End;

Procedure RunProgram;
Var
 J:Integer;
 Err:Integer;
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
   If Not RunLine Then Break;
   Inc(CurrLinePtr);
  End;
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('AWK : Cette commande permet de lancer le langage de programmation AWK.');
  WriteLn;
  WriteLn('Syntaxe : AWK [-f nomfichier]');
 End
  Else
 If ParamCount>=1Then Begin
  NumberLine:=0;CurrNumberLine:=0;
  NumberVariable:=0;
  Mode:=_None;FileName:='';
  CurrCommand:='';
  AccoladeBlock:=0;
  For I:=1 to RawParamCount do Begin
   CurrParam:=RawParamStr(I);
   If Mode=_InStringSimpleQuote Then Begin
    If CurrParam[Length(CurrParam)]=''''Then Begin
     CurrCommand:=CurrCommand+' '+Copy(CurrParam,1,Length(CurrParam)-1);
     Mode:=_None;
    End
     Else
    CurrCommand:=CurrCommand+' '+CurrParam;
   End
    Else
   If Mode=_F Then Begin
    FileName:=CurrParam;
    Mode:=_None;
   End
    Else
   If(Copy(CurrParam,1,1)='''')and(CurrParam[Length(CurrParam)]='''')Then Begin
    CurrCommand:=Copy(CurrParam,2,Length(CurrParam)-2);
   End
    Else
   If CurrParam='-f'Then Mode:=_F Else
   If(Copy(CurrParam,1,1)='''')Then Begin
    Mode:=_InStringSimpleQuote;
    CurrCommand:=Copy(CurrParam,2,Length(CurrParam)-1);
   End
    Else
   Begin
    WriteLn('ParamŠtre non reconnu');
    Halt(1);
   End;
  End;
  If CurrCommand<>''Then Begin
   CurrLine:=CurrCommand;
   CurrPos:=1;
   RunLine;
  End;
  If FileName<>''Then Begin
   {$I-}Assign(FileAWK,FileName);
   Reset(FileAWK);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Fichier introuvable');
    Exit;
   End;
   While Not EOF(FileAWK) do Begin
    ReadLn(FileAWK,CurrLine);
    If Not AddLine(CurrLine)Then Begin
     WriteLn('Manque de m‚moire');
     Break;
    End;
   End;
   Close(FileAWK);
   RunProgram;
  End;
 End;
END.
