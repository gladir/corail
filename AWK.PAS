{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal, Turbo Pascal)
}

Program AWK;

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

 MaxLine=1024;

Type
 StrPointer=^String;

Var
 FileAWK:Text;
 Mode:(_None,_F);
 Terminated:Boolean;
 CurrCommand:String;
 FileName,CurrLine:String;
 CurrPos:Byte;
 PA:Array[1..MaxLine] of StrPointer;
 CurrLinePtr,NumberLine:Integer;
 CurrNumberLine:Integer;
 I:Integer;

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

Function GetNumberValue:Real;
Var
 I:Byte;
 Top,P_2:Char;
 AppendOk:Boolean;
 _Result,P,P2:Real;
 Err:Word;
 PostFix:String;
 Value:String;
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
  Else If Infix[I]=')'Then Begin
   While(TopOfStack>1)and(StackPeek<>'(')do PostFix:=PostFix+StackPop;
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
  R:=GetNumberValue;
  If Frac(R)=0.0Then WriteLn(R:0:0)
                Else WriteLn(R);
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
   14: NoImplementation:=True; { cos }
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
 End
  Else
 If ParamCount>1Then Begin
  NumberLine:=0;CurrNumberLine:=0;
  Mode:=_None;FileName:='';
  For I:=1 to ParamCount do Begin
   If Mode=_F Then Begin
    FileName:=ParamStr(I);
    Mode:=_None;
   End
    Else
   If ParamStr(I)='-f'Then Mode:=_F;
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