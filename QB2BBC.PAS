{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program QB2BBC;

Var
 Source:Text;
 CurrLine:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function IsReservedWordQB(CurrWord:String):Boolean;
Const
 ReservedWord:Array[0..48]of String[10]=(
  'ABSOLUTE','AND','BASE','CALL','CASE','COM','COMMON','CONST','DATA',
  'DECLARE','DEF','DIM','DO','ELSE','END','ERASE','ERROR','FOR','FUNCTION',
  'GOSUB','GOTO','IF','INTERRUPT','KEY','LET','LOOP','NEXT','NEW','NOT',
  'ON','OPTION','PEN','PLAY','REDIM','RESTORE','REM','RESUME','RETURN',
  'RUN','SEG','SELECT','SHARED','STRIG','SUB','THEN','TIMER','TO','TYPE',
  'UEVENT'
 );
Var
 I:Integer;
Begin
 IsReservedWordQB:=False;
 For I:=Low(ReservedWord) to High(ReservedWord)do Begin
  If ReservedWord[I]=StrToUpper(CurrWord)Then Begin
   IsReservedWordQB:=True;
   Exit;
  End;
 End;
End;

Function IsFunctionQB(CurrWord:String):Boolean;
Const
 FunctionWord:Array[0..143]of String[10]=(
  'ABS','ACCESS','ASC','ATN','BEEP','BLOAD','BSAVE','CDBL',
  'CHAIN','CHDIR','CHR$','CINT','CIRCLE','CLEAR','CLNG',
  'CLOSE','CLS','COLOR','COM','COMMAND$','COS','CSNG','CSRLIN',
  'CVD','CVDMBF','CVI','DATE$','DECLARE','DRAW','EOF','ENVIRON',
  'ENVIRON$','ERDEV','ERDEV$','ERL','ERR','ERROR','EXIT','EXP',
  'FIELD','FILEATTR','FILES','FIX','FRE','FREEFILE','GET','HEX$',
  'IMP','INKEY$','INP','INPUT','INPUT$','INSTR','INT','KEY','KILL',
  'LBOUND','LCASE$','LEFT$','LEN','LINE','LOC','LOCATE','LOCK',
  'LOF','LOG','LPOS','LPRINT','LSET','LTRIM$','MID$','MKD$',
  'MKDIR','MKDMBF$','MKI$','MKL$','MKSMBF$','NAME','OCT$','OPEN',
  'OUT','PAINT','PALETTE','PCOPY','PEEK','PEN','PLAY','PMAP',
  'POINT','POKE','POS','PRESET','PRINT','PSET','PUT','RANDOMIZE',
  'READ','RESET','RESUME','RIGHT$','RMDIR','RND','RSET','RTRIM$',
  'SCREEN','SEEK','SGN','SHELL','SIN','SLEEP','SOUND','SPACE$',
  'SPC','SQR','STATIC','STICK','STOP','STR$','STRIG','STRING$',
  'SWAP','SYSTEM','TAB','TAN','TIME$','TIMER','TROFF','TROFF',
  'UBOUND','UNLOCK','UCASE$','USING','USR','VAL','VARPTR','VARPTR$',
  'VARSEG','VIEW','WAIT','WEND','WHILE','WIDTH','WINDOW','WRITE'
 );
Var
 I:Integer;
Begin
 IsFunctionQB:=False;
 For I:=Low(FunctionWord) to High(FunctionWord)do Begin
  If FunctionWord[I]=StrToUpper(CurrWord)Then Begin
   IsFunctionQB:=True;
   Exit;
  End;
 End;
End;

Function IsNumber(S:String):Boolean;
Var
 I:Integer;
Begin
 IsNumber:=True;
 For I:=1 to Length(S)do Begin
  If Not(S[I]in['0'..'9','.','E','-','+'])Then Begin
   IsNumber:=False;
   Exit;
  End;
 End;
End;

Function ParseLine(CurrLine:String):String;
Var
 Quote:Boolean;
 LastWord:(_None,_Sub);
 I:Integer;
 CurrWord,NewLine:String;
Begin
 CurrWord:='';
 NewLine:='';
 LastWord:=_None;
 Quote:=False;
 For I:=1 to Length(CurrLine)do Begin
  If CurrLine[I]='"'Then Begin
   CurrWord:=CurrWord+'"';
   If(Quote)Then Begin
    Quote:=False;
    NewLine:=NewLine+CurrWord;
    CurrWord:='';
   End
    Else
   Quote:=True;
  End
   Else
  If(Quote)Then Begin
   CurrWord:=CurrWord+CurrLine[I];
  End
   Else
  If CurrLine[I]in[',','=',' ','(',')','<','>','+','-','*','/']Then Begin
   If IsReservedWordQB(CurrWord)Then Begin
    If StrToUpper(CurrWord)='CALL'Then Begin
     NewLine:=NewLine+'PROC';
     LastWord:=_Sub;
    End
    Else
    If StrToUpper(CurrWord)='DO'Then NewLine:=NewLine+'REPEAT'Else
    If StrToUpper(CurrWord)='LOOP'Then NewLine:=NewLine+'UNTIL FALSE' Else
    If CurrWord='SUB'Then Begin
     LastWord:=_Sub;
     NewLine:=NewLine+'DEF PROC';
    End
     Else
    NewLine:=NewLine+CurrWord;
   End
    Else
   If IsFunctionQB(CurrWord)Then Begin
    NewLine:=NewLine+CurrWord;
   End
    Else
   If IsNumber(CurrWord)Then Begin
    NewLine:=NewLine+CurrWord;
   End
    Else
   Begin
    If Not(CurrWord[Length(CurrWord)]in['$','%','#','!','"'])Then Begin
     NewLine:=NewLine+CurrWord;
     If(LastWord<>_Sub)Then NewLine:=NewLine+'%'
                       Else LastWord:=_None;
    End
     Else
    NewLine:=NewLine+CurrWord;
   End;
   If(StrToUpper(CurrWord)='SUB')and(CurrLine[I]=' ')Then Begin
    CurrWord:='';
   End
    Else
   Begin
    CurrWord:='';
    NewLine:=NewLine+CurrLine[I];
   End;
  End
   Else
  CurrWord:=CurrWord+CurrLine[I];
 End;
 If StrToUpper(CurrWord)='DO'Then NewLine:=NewLine+'REPEAT'Else
 If StrToUpper(CurrWord)='LOOP'Then NewLine:=NewLine+'UNTIL FALSE'
                               Else NewLine:=NewLine+CurrWord;
 If IsReservedWordQB(CurrWord)or IsFunctionQB(CurrWord)or IsNumber(CurrWord)Then Begin
 End
  Else
 If Not(NewLine[Length(NewLine)]in[',','=',' ','(',')','<','>','+',
                '-','*','/','$','%','#','!','"'])Then Begin
  NewLine:=NewLine+'%'
 End;
 ParseLine:=NewLine;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('QB2BBC : Cette commande permet de convertir un code source ',
                    'QBasic ou QuickBasic en BBC BASIC.');
  WriteLn;
  WriteLn('Syntaxe : QB2BBC fichier');
 End
  Else
 Begin
  {$I-}Assign(Source,ParamStr(1));
  Reset(Source);{$I+}
  While Not EOF(Source)do Begin
   ReadLn(Source,CurrLine);
   WriteLn(ParseLine(CurrLine));
  End;
  Close(Source);
 End;
END.
