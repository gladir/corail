{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal, Turbo Pascal)
}

Program C;

Const
 DirectiveList:Array[0..10]of String[10]=(
  'include','define','endif','elif','else','if','ifdef','ifndef',
  'line','pragma','undef'
 );

 ReservedWordList:Array[0..42]of String[10]=(
  'asm','auto','break','case','cdecl','const','continue',
  'default','do','double','else','enum','extern',
  'far','float','for','goto','huge','if','inline',
  'int','interrupt','long','near','pascal','register',
  'restrict','return','short','signed','sizeof','static',
  'struct','switch','typedef','union','unsigned','void',
  'volatile','while','_Bool','_Complex','_Imaginary'
 );

 FunctionList:Array[0..135]of String[20]=(
  'abort','abs','acos','asctime','asin','assert','atan',
  'atan2','atexit','atof','atoi','atol','bsearch','calloc',
  'ceil','clearerr','clock','cos','cosh','ctime','difftime',
  'div','exit','exp','fabs','fclose','fcloseall','feof',
  'ferror','fflush','fgetc','fgetpos','fgets','floor','fmod',
  'fopen','fprintf','fputc','fputs','fread','free','freopen',
  'frexp','fscanf','fseek','fsetpos','ftell','fwrite','getc',
  'getchar','getenv','gets','gmtime','isalnum','isalpha',
  'iscntrl','isdigit','isgraph','islower','isprint','ispunct',
  'isspace','isupper','isxdigit','labs','ldexp','ldiv',
  'localtime','log','log10','longjmp','malloc','memchr',
  'memcmp','memcpy','memmove','memset','mktime','modf',
  'perror','pow','printf','putc','putchar','puts','qsort',
  'raise','rand','realloc','remove','rename','rewind',
  'scanf','setbuf','setjmp','setvbuf','signal','sin',
  'sinh','sprintf','sqrt','srand','sscanf','strcat','strchr',
  'strcmp','strcpy','strcspn','strerror','strlen',
  'strncat','strncmp','strncpy','strpbrk','strrchr',
  'strspn','strstr','strtod','strtok','strtol','strtoul',
  'system','tan','tanh','time','tmpfile','tmpnam','tolower',
  'toupper','ungetc','va_arg','va_end','va_start','vfprinf',
  'vprintf','vsprintf'
 );

 MaxLine=1024;

Type
 StrPointer=^String;

Var
 FileC:Text;
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
  If Not(CurrLine[I]in['A'..'Z','a'..'z','_'])Then Begin
   CurrCommand:=Copy(CurrLine,CurrPos,I-CurrPos);
   CurrPos:=I;
   Break;
  End;
 End;
 If CurrCommand=''Then Begin
  CurrCommand:=Copy(CurrLine,CurrPos,255);
  CurrPos:=Length(CurrLine)+1;
 End;
 For I:=Low(ReservedWordList)to High(ReservedWordList)do Begin
  If CurrCommand=ReservedWordList[I]Then Begin
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

Function IncludeDirective:Boolean;
Var
 S:String;
Begin
 IncludeDirective:=False;
 SkipSpace;
 If CurrLine[CurrPos]='<'Then Begin
  Inc(CurrPos);
  S:='';
  While(CurrLine[CurrPos]<>'>')and(CurrPos<=Length(CurrLine))do Begin
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
  If CurrLine[CurrPos]<>'>'Then Begin
   WriteLn('> attendu');
   Exit;
  End;
 End
  Else
 Exit;
 IncludeDirective:=True;
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
  NoImplementation:=False;
  UnknownCommand:=False;
  If CurrLine[CurrPos]='#'Then Begin
   Inc(CurrPos);
   CurrCommand:='';
   For I:=CurrPos to Length(CurrLine)do Begin
    If Not(CurrLine[I]in['A'..'Z','a'..'z','_'])Then Begin
     CurrCommand:=Copy(CurrLine,CurrPos,I-CurrPos);
     CurrPos:=I;
     Break;
    End;
   End;
   If CurrCommand=''Then Begin
    WriteLn('Directive attendu a la position ',CurrPos,' de la ligne ',CurrNumberLine+1);
    Exit;
   End;
   For J:=Low(DirectiveList) to High(DirectiveList) do Begin
    If CurrCommand=DirectiveList[J]Then Begin
     UnknownCommand:=False;
     Case(J)of
      0:If Not(IncludeDirective)Then Exit; { #include }
      1:NoImplementation:=True; { #define }
      2:NoImplementation:=True; { #endif }
      3:NoImplementation:=True; { #elif }
      4:NoImplementation:=True; { #else }
      5:NoImplementation:=True; { #if }
      6:NoImplementation:=True; { #ifdef }
      7:NoImplementation:=True; { #ifndef }
      8:NoImplementation:=True; { #line }
      9:NoImplementation:=True; { #pragma }
      10:NoImplementation:=True; { #undef }
      Else UnknownCommand:=True;
     End;
    End;
   End;
   If(UnknownCommand)Then Begin
    WriteLn('Directive non reconnu a la position ',CurrPos,' de la ligne ',CurrNumberLine+1);
    Exit;
   End;
   If(NoImplementation)Then Begin
    WriteLn('La directive "#',CurrCommand,'" n''a pas ete implemente');
    Exit;
   End;
  End
   Else
  Case ExtractCommand of
   0: NoImplementation:=True; { asm}
   1: NoImplementation:=True; { auto }
   2: NoImplementation:=True; { break }
   3: NoImplementation:=True; { case }
   4: NoImplementation:=True; { cdecl }
   5: NoImplementation:=True; { const }
   6: NoImplementation:=True; { continue }
   7: NoImplementation:=True; { default }
   8: NoImplementation:=True; { do }
   9: NoImplementation:=True; { double }
   10: NoImplementation:=True; { else }
   11: NoImplementation:=True; { enum }
   12: NoImplementation:=True; { extern }
   13: NoImplementation:=True; { far }
   14: NoImplementation:=True; { float }
   15: NoImplementation:=True; { for }
   16: NoImplementation:=True; { goto }
   17: NoImplementation:=True; { huge }
   18: NoImplementation:=True; { if }
   19: NoImplementation:=True; { inline }
   20: NoImplementation:=True; { int }
   21: NoImplementation:=True; { interrupt }
   22: NoImplementation:=True; { long }
   23: NoImplementation:=True; { near }
   24: NoImplementation:=True; { pascal }
   25: NoImplementation:=True; { register }
   26: NoImplementation:=True; { restrict }
   27: NoImplementation:=True; { return }
   28: NoImplementation:=True; { short }
   29: NoImplementation:=True; { signed }
   30: NoImplementation:=True; { sizeof }
   31: NoImplementation:=True; { static }
   32: NoImplementation:=True; { struct }
   33: NoImplementation:=True; { switch }
   34: NoImplementation:=True; { typedef }
   35: NoImplementation:=True; { union }
   36: NoImplementation:=True; { unsigned }
   37: NoImplementation:=True; { void }
   38: NoImplementation:=True; { volatile }
   39: NoImplementation:=True; { while }
   40: NoImplementation:=True; { _Bool }
   41: NoImplementation:=True; { _Complex }
   42: NoImplementation:=True; { _Imaginary }
   Else If CurrCommand<>''Then UnknownCommand:=True;
  End;
  If(UnknownCommand)Then Begin
   For J:=Low(FunctionList) to High(FunctionList) do Begin
    If CurrCommand=FunctionList[J]Then Begin
     UnknownCommand:=False;
     Case(J)of
      0:NoImplementation:=True; { abort }
      1:NoImplementation:=True; { abs }
      2:NoImplementation:=True; { acos }
      3:NoImplementation:=True; { asctime }
      4:NoImplementation:=True; { asin }
      5:NoImplementation:=True; { assert }
      6:NoImplementation:=True; { atan }
      7:NoImplementation:=True; { atan2 }
      8:NoImplementation:=True; { atexit }
      9:NoImplementation:=True; { atof }
      10:NoImplementation:=True; { atoi }
      11:NoImplementation:=True; { atol }
      12:NoImplementation:=True; { bsearch }
      13:NoImplementation:=True; { calloc }
      14:NoImplementation:=True; { ceil }
      15:NoImplementation:=True; { clearerr }
      16:NoImplementation:=True; { clock }
      17:NoImplementation:=True; { cos }
      18:NoImplementation:=True; { cosh }
      19:NoImplementation:=True; { ctime }
      20:NoImplementation:=True; { difftime }
      21:NoImplementation:=True; { div }
      22:NoImplementation:=True; { exit }
      23:NoImplementation:=True; { exp }
      24:NoImplementation:=True; { fabs }
      25:NoImplementation:=True; { fclose }
      26:NoImplementation:=True; { fcloseall }
      27:NoImplementation:=True; { feof }
      28:NoImplementation:=True; { ferror }
      29:NoImplementation:=True; { fflush }
      30:NoImplementation:=True; { fgetc }
      31:NoImplementation:=True; { fgetpos }
      32:NoImplementation:=True; { fgets }
      33:NoImplementation:=True; { floor }
      34:NoImplementation:=True; { fmod }
      35:NoImplementation:=True; { fopen }
      36:NoImplementation:=True; { fprintf }
      37:NoImplementation:=True; { fputc }
      38:NoImplementation:=True; { fputs }
      39:NoImplementation:=True; { fread }
      40:NoImplementation:=True; { free }
      41:NoImplementation:=True; { freopen }
      42:NoImplementation:=True; { frexp }
      43:NoImplementation:=True; { fscanf }
      44:NoImplementation:=True; { fseek }
      45:NoImplementation:=True; { fsetpos }
      46:NoImplementation:=True; { ftell }
      47:NoImplementation:=True; { fwrite }
      48:NoImplementation:=True; { getc }
      49:NoImplementation:=True; { getchar }
      50:NoImplementation:=True; { getenv }
      51:NoImplementation:=True; { gets }
      52:NoImplementation:=True; { gmtime }
      53:NoImplementation:=True; { isalnum }
      54:NoImplementation:=True; { isalpha }
      55:NoImplementation:=True; { iscntrl }
      56:NoImplementation:=True; { isdigit }
      57:NoImplementation:=True; { isgraph }
      58:NoImplementation:=True; { islower }
      59:NoImplementation:=True; { isprint }
      60:NoImplementation:=True; { ispunct }
      61:NoImplementation:=True; { isspace }
      62:NoImplementation:=True; { isupper }
      63:NoImplementation:=True; { isxdigit }
      64:NoImplementation:=True; { labs }
      65:NoImplementation:=True; { ldexp }
      66:NoImplementation:=True; { ldiv }
      67:NoImplementation:=True; { localtime }
      68:NoImplementation:=True; { log }
      69:NoImplementation:=True; { log10 }
      70:NoImplementation:=True; { longjmp }
      71:NoImplementation:=True; { malloc }
      72:NoImplementation:=True; { memchr }
      73:NoImplementation:=True; { memcmp }
      74:NoImplementation:=True; { memcpy }
      75:NoImplementation:=True; { memmove }
      76:NoImplementation:=True; { memset }
      77:NoImplementation:=True; { mktime }
      78:NoImplementation:=True; { modf }
      79:NoImplementation:=True; { perror }
      80:NoImplementation:=True; { pow }
      81:NoImplementation:=True; { printf }
      82:NoImplementation:=True; { putc }
      83:NoImplementation:=True; { putchar }
      84:NoImplementation:=True; { puts }
      85:NoImplementation:=True; { qsort }
      86:NoImplementation:=True; { raise }
      87:NoImplementation:=True; { rand }
      88:NoImplementation:=True; { realloc }
      89:NoImplementation:=True; { remove }
      90:NoImplementation:=True; { rename }
      91:NoImplementation:=True; { rewind }
      92:NoImplementation:=True; { scanf }
      93:NoImplementation:=True; { setbuf }
      94:NoImplementation:=True; { setjmp }
      95:NoImplementation:=True; { setvbuf }
      96:NoImplementation:=True; { signal }
      97:NoImplementation:=True; { sin }
      98:NoImplementation:=True; { sinh }
      99:NoImplementation:=True; { sprintf }
      100:NoImplementation:=True; { sqrt }
      101:NoImplementation:=True; { srand }
      102:NoImplementation:=True; { sscanf }
      103:NoImplementation:=True; { strcat }
      104:NoImplementation:=True; { strchr }
      105:NoImplementation:=True; { strcmp }
      106:NoImplementation:=True; { strcpy }
      107:NoImplementation:=True; { strcspn }
      108:NoImplementation:=True; { strerror }
      109:NoImplementation:=True; { strlen }
      110:NoImplementation:=True; { strncat }
      111:NoImplementation:=True; { strncmp }
      112:NoImplementation:=True; { strncpy }
      113:NoImplementation:=True; { strpbrk }
      114:NoImplementation:=True; { strrchr }
      115:NoImplementation:=True; { strspn }
      116:NoImplementation:=True; { strstr }
      117:NoImplementation:=True; { strtod }
      118:NoImplementation:=True; { strtok }
      119:NoImplementation:=True; { strtol }
      120:NoImplementation:=True; { strtoul }
      121:NoImplementation:=True; { system }
      122:NoImplementation:=True; { tan }
      123:NoImplementation:=True; { tanh }
      124:NoImplementation:=True; { time }
      125:NoImplementation:=True; { tmpfile }
      126:NoImplementation:=True; { tmpnam }
      127:NoImplementation:=True; { tolower }
      128:NoImplementation:=True; { toupper }
      129:NoImplementation:=True; { ungetc }
      130:NoImplementation:=True; { va_arg }
      131:NoImplementation:=True; { va_end }
      132:NoImplementation:=True; { va_start }
      133:NoImplementation:=True; { vfprinf }
      134:NoImplementation:=True; { vprintf }
      135:NoImplementation:=True; { vsprintf }
      Else UnknownCommand:=True;
     End;
    End;
   End;
   If(UnknownCommand)Then Begin
    WriteLn(CurrLine);
    WriteLn('^':CurrPos);
    WriteLn('Commande non reconnu a la position ',CurrPos,' de la ligne ',CurrNumberLine+1);
    Exit;
   End;
  End;
  If(NoImplementation)Then Begin
   WriteLn('La commande ou fonction "',CurrCommand,'" n''a pas ete implemente');
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
  WriteLn('C : Cette commande permet de lancer le langage de programmation C.');
  WriteLn;
  WriteLn('Syntaxe : C [nomfichier]');
 End
  Else
 If ParamCount>=1Then Begin
  NumberLine:=0;CurrNumberLine:=0;
  FileName:='';
  For I:=1 to ParamCount do Begin
   FileName:=ParamStr(I);
  End;
  If FileName<>''Then Begin
   {$I-}Assign(FileC,FileName);
   Reset(FileC);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Fichier introuvable');
    Exit;
   End;
   While Not EOF(FileC) do Begin
    ReadLn(FileC,CurrLine);
    If Not AddLine(CurrLine)Then Begin
     WriteLn('Manque de m‚moire');
     Break;
    End;
   End;
   Close(FileC);
   RunProgram;
  End;
 End;
END.