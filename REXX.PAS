{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal 3.2, Turbo Pascal 7)
}

Program REXX;

Uses Crt,DOS;

{$IFDEF FPC}
 {$IFDEF WINDOWS}
Function GetVolumeInformationA(RootPathName,VolumeNameBuffer:PChar;
 VolumeNameSize:LongWord;VolumeSerialNumber,MaximumComponentLength,
 FileSystemFlags:Pointer;FileSystemNameBuffer:PChar;
 FileSystemNameSize:LongWord):LongBool;StdCall;
 External 'kernel32.dll' Name 'GetVolumeInformationA';
 {$ENDIF}
{$ENDIF}

Const
 CommandList:Array[0..161]of String[20]=(
  'ABBREV','ABS','ADDRESS','ARG','B2X','BEEP','BITAND','BITOR',
  'BITXOR','CALL','CENTER','CHANGESTR','CHARIN','CHAROUT',
  'CHARS','COMPARE','CONDITION','COPIES','COUNTSTR','C2D',
  'C2X','DATATYPE','DATE','DELSTR','DELWORD','DIGITS',
  'DIRECTORY','D2C','D2X','ENDLOCAL','ERRORTEXT','EXIT','FILESPEC',
  'FORM','FORMAT','FUZZ','IF','INSERT','LASTPOS','LEFT',
  'LENGTH','LINEIN','LINEOUT','LINES','MAX','MIN',
  'OPTIONS','OVERLAY','PARSE','PROCEDURE','POS','PULL',
  'PUSH','QUEUE','QUEUED','RANDOM','RETURN','REVERSE',
  'RIGHT','RXFUNCADD','RXFUNCDROP','RXFUNCQUERY','RXMESSAGEBOX',
  'RXQUEUE','RXWINEXEC','SAY','SELECT','SETLOCAL','SIGN',
  'SOURCELINE','SPACE','STREAM','STRIP','SUBSTR','SUBWORD',
  'SYMBOL','SYSADDREXXMACRO','SYSBOOTDRIVE','SYSCLEARREXXMACROSPACE',
  'SYSCLOSEEVENTSEM','SYSCLOSEMUTEXSEM','SYSCLS','SYSCREATEEVENTSEM',
  'SYSCREATEMUTEXSEM','SYSCREATEOBJECT','SYSCURPOS','SYSCURSTATE',
  'SYSDEREGISTEROBJECTCLASS','SYSDESTROYOBJECT','SYSDRIVEINFO',
  'SYSDRIVEMAP','SYSDROPFUNCS','SYSDROPREXXMACRO','SYSFILEDELETE',
  'SYSFILETREE','SYSFILESEARCH','SYSFILESYSTEMTYPE',
  'SYSGETEA','SYSGETKEY','SYSGETMESSAGE','SYSINI','SYSLOADFUNCS',
  'SYSLOADREXXMACROSPACE','SYSMKDIR','SYSOPENEVENTSEM',
  'SYSOPENMUTEXSEM','SYSOS2VER','SYSPOSTEVENTSEM','SYSPULSEEVENTSEM',
  'SYSPUTEA','SYSQUERYCLASSLIST','SYSQUERYREXXMACRO',
  'SYSREGISTEROBJECTCLASS','SYSRELEASEMUTEXSEM',
  'SYSREORDERREXXMACRO','SYSREQUESTMUTEXSEM','SYSRESETEVENTSEM',
  'SYSRMDIR','SYSSAVEREXXMACROSPACE','SYSSEARCHPATH','SYSSETICON',
  'SYSSETOBJECTDATA','SYSSETPRIORITY','SYSSLEEP','SYSSWITCHSESSION',
  'SYSSYSTEMDIRECTORY','SYSTEMPFILENAME','SYSTEXTSCREENREAD',
  'SYSTEXTSCREENSIZE','SYSVOLUMELABEL','SYSWAITEVENTSEM',
  'SYSWAITNAMEDPIPE','SYSWINVER','THEN','TIME','TRACE',
  'TRANSLATE','TRUNC','VALUE','VAR','VERIFY','WORD',
  'WORDINDEX','WORDLENGTH','WORDPOS','WORDS','XRANGE',
  'X2B','X2C','X2D',
  { Instructions de controle ajoutees apres la table historique afin de ne
    pas modifier les numeros encore utilises par l'ancien moteur. }
  'DO','ELSE','END','EXPOSE','ITERATE','LEAVE','NAME','NOP','NUMERIC',
  'OTHERWISE','SIGNAL','WHEN'
 );

 MaxLine=1024;

Type
 StrPointer=^String;

Var
 Terminated:Boolean;
 ProgramExitRequested:Boolean;
 ProgramExitCode:Integer;
 CurrCommand:String;
 FileName,CurrLine:String;
 PA:Array[1..MaxLine] of StrPointer;
 CurrLinePtr,NumberLine:Integer;
 CurrNumberLine:Integer;
 I:Integer;
 CurrPos:Byte;

Type
 RexxValue=Record
  Text:String;
  Number:Real;
  IsNumber:Boolean;
 End;
 PRexxVariable=^RexxVariable;
 RexxVariable=Record
  Name:String[64];
  Value:String;
  Next:PRexxVariable;
 End;
 PExposedVariable=^ExposedVariable;
 ExposedVariable=Record
  Name:String[64];
  Value:String;
  Next:PExposedVariable;
 End;
 PLocalEnvironment=^LocalEnvironment;
 LocalEnvironment=Record
  DirectoryName:String;
  Next:PLocalEnvironment;
 End;
 PRexxQueueEntry=^RexxQueueEntry;
 RexxQueueEntry=Record
  Value:String;
  Next:PRexxQueueEntry;
 End;

Var
 Variables:PRexxVariable;
 ExprText:String;
 ExprPos:Integer;

Const
 MaxRoutineArgs=16;

Var
 InvokeArgs:Array[1..MaxRoutineArgs]of String;
 InvokeArgCount:Integer;
 CurrentArgs:Array[1..MaxRoutineArgs]of String;
 CurrentArgCount:Integer;
 InitialArgs:Array[1..MaxRoutineArgs]of String;
 InitialArgCount:Integer;
 RoutineReturning:Boolean;
 RoutineResult:String;
 RoutineDepth:Integer;
 NumericDigitsValue:Integer;
 NumericFuzzValue:Integer;
 NumericFormValue:String[16];
 SignalTargetLine:Integer;
 SignalHalt,SignalNoValue,SignalError,SignalSyntax:Boolean;
 SignalHaltName,SignalNoValueName,SignalErrorName,SignalSyntaxName:String[64];
 CurrentConditionName:String[16];
 CurrentConditionDescription:String;
 CurrentConditionInstruction:String[8];
 CurrentConditionStatus:String[8];
 CurrentAddress,PreviousAddress:String[64];
 CurrentOptions:String;
 CurrentTraceSetting:String[2];
 TimeElapsedStart:Real;
 CharInNames:Array[1..MaxRoutineArgs]of String;
 CharInPositions:Array[1..MaxRoutineArgs]of LongInt;
 CharInStreamCount:Integer;
 CharOutNames:Array[1..MaxRoutineArgs]of String;
 CharOutPositions:Array[1..MaxRoutineArgs]of LongInt;
 CharOutStreamCount:Integer;
 LocalEnvironments:PLocalEnvironment;
 RexxQueueHead,RexxQueueTail:PRexxQueueEntry;
 RexxQueueCount:LongInt;

Procedure PushQueue(Value:String);
Var Entry:PRexxQueueEntry;
Begin
 New(Entry);Entry^.Value:=Value;Entry^.Next:=RexxQueueHead;
 RexxQueueHead:=Entry;
 If RexxQueueTail=Nil Then RexxQueueTail:=Entry;
 Inc(RexxQueueCount);
End;

Procedure AppendQueue(Value:String);
Var Entry:PRexxQueueEntry;
Begin
 New(Entry);Entry^.Value:=Value;Entry^.Next:=Nil;
 If RexxQueueTail=Nil Then RexxQueueHead:=Entry
  Else RexxQueueTail^.Next:=Entry;
 RexxQueueTail:=Entry;Inc(RexxQueueCount);
End;

Procedure PullQueue(Var Value:String;Var Found:Boolean);
Var Entry:PRexxQueueEntry;
Begin
 Found:=RexxQueueHead<>Nil;
 If Not Found Then Begin Value:='';Exit;End;
 Entry:=RexxQueueHead;Value:=Entry^.Value;
 RexxQueueHead:=Entry^.Next;
 If RexxQueueHead=Nil Then RexxQueueTail:=Nil;
 Dispose(Entry);Dec(RexxQueueCount);
End;

Procedure FreeQueue;
Var Entry:PRexxQueueEntry;
Begin
 While RexxQueueHead<>Nil Do Begin
  Entry:=RexxQueueHead;RexxQueueHead:=RexxQueueHead^.Next;Dispose(Entry);
 End;
 RexxQueueTail:=Nil;RexxQueueCount:=0;
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

Function IsStringValue:Boolean;Begin
 IsStringValue:=False;
 If CurrLine[CurrPos]in['''','"']Then Begin
  IsStringValue:=True;
 End;
End;

Function ExtractCommand:Byte;
Var
 I:Byte;
Begin
 ExtractCommand:=255;
 CurrCommand:='';
 For I:=CurrPos to Length(CurrLine)do Begin
  If Not(CurrLine[I]in['A'..'Z','a'..'z','_'])Then Begin
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
 If CurrLine[CurrPos]=''''Then Begin
  Inc(CurrPos);
  While(CurrLine[CurrPos]<>'''')and(CurrPos<=Length(CurrLine))do Begin
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
  If CurrLine[CurrPos]=''''Then Inc(CurrPos);
 End
  Else
 If CurrLine[CurrPos]='"'Then Begin
  Inc(CurrPos);
  While(CurrLine[CurrPos]<>'"')and(CurrPos<=Length(CurrLine))do Begin
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
  If CurrLine[CurrPos]='"'Then Inc(CurrPos);
 End;
 GetStringValue:=S;
End;

Procedure SkipSpace;Begin
 While(CurrLine[CurrPos]in[' '])and(CurrPos<Length(CurrLine))do Inc(CurrPos);
End;

Procedure LoadCommand;
Var
 FileLoad:Text;
 S:String;
Begin
 If FileName<>''Then Begin
  {$I-}Assign(FileLoad,FileName);
  Reset(FileLoad);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier introuvable');
   Exit;
  End;
  {NewCommand;}
  While Not EOF(FileLoad) do Begin
   ReadLn(FileLoad,S);
   { Conserver la ligne originale pour SOURCELINE(n). Les analyseurs
     d'instructions appliquent eux-memes Clean/LTrim au moment voulu. }
   If Not AddLine(S)Then Begin
    WriteLn('Manque de m‚moire');
    Break;
   End;
  End;
  Close(FileLoad);
 End
  Else
 WriteLn('Nom du fichier absent');
End;

Procedure SayCommand;Begin
 SkipSpace;
 If IsStringValue Then Begin
  WriteLn(GetStringValue);
 End;
End;

{ -----------------------------------------------------------------
  Noyau REXX executable. L'ancien RunLine ci-dessus est conserve pour
  documenter la table historique, mais ce moteur prend en charge les
  expressions, variables et structures de controle reelles. }

Function RTrim(S:String):String;
Begin
 While(Length(S)>0)and(S[Length(S)]in[' ',#9])do Delete(S,Length(S),1);
 RTrim:=S;
End;

Function Clean(S:String):String;Begin Clean:=RTrim(LTrim(S));End;

Function NormalizeRexxNumber(S:String):String;
Var J:Integer;R:String;
Begin
 S:=Clean(S);R:='';
 If(Length(S)>0)and(S[1]in['+','-'])Then Begin
  R:=S[1];J:=2;
  While(J<=Length(S))and(S[J]in[' ',#9])Do Inc(J);
  R:=R+Copy(S,J,255);
 End Else R:=S;
 NormalizeRexxNumber:=R;
End;

Function NumToText(N:Real):String;
Var S:String;
Begin
 If Abs(N-Round(N))<0.000000001Then Str(Round(N),S)
 Else Begin Str(N:0:8,S);While(System.Pos('.',S)>0)and(S[Length(S)]='0')do Delete(S,Length(S),1);End;
 NumToText:=Clean(S);
End;

Procedure RVText(S:String;Var V:RexxValue);
Var C:Integer;
Begin V.Text:=S;Val(NormalizeRexxNumber(S),V.Number,C);V.IsNumber:=C=0;
 If Not V.IsNumber Then V.Number:=0;End;
Procedure RVNum(N:Real;Var V:RexxValue);
Begin V.Number:=N;V.IsNumber:=True;V.Text:=NumToText(N);End;

Procedure SourceLineValue(LineNumber:LongInt;NumberSpecified:Boolean;
 Var ResultValue:RexxValue);
Begin
 If Not NumberSpecified Then Begin
  RVNum(NumberLine,ResultValue);
  Exit;
 End;
 If(LineNumber<1)or(LineNumber>NumberLine)Then
  RVText('',ResultValue)
 Else RVText(PA[LineNumber]^,ResultValue);
End;

Procedure RandomValue(MinimumValue,MaximumValue,SeedValue:RexxValue;
 ArgumentCount:Integer;Var ResultValue:RexxValue);
Var LowValue,HighValue,GeneratedValue:LongInt;IntervalSize:Real;
Begin
 Case ArgumentCount Of
  0:Begin LowValue:=0;HighValue:=999;End;
  1:Begin LowValue:=0;HighValue:=System.Trunc(MinimumValue.Number);End;
 Else Begin
  LowValue:=System.Trunc(MinimumValue.Number);
  HighValue:=System.Trunc(MaximumValue.Number);
 End;
 End;
 If ArgumentCount>2Then RandSeed:=System.Trunc(SeedValue.Number);
 { Un intervalle inverse est invalide en REXX. Le moteur ne possede pas
   encore de mecanisme d'exception pour les appels incorrects: retourner
   zero evite ici un debordement ou une valeur hors intervalle. }
 If HighValue<LowValue Then Begin RVNum(0,ResultValue);Exit;End;
 IntervalSize:=HighValue-LowValue+1.0;
 GeneratedValue:=LowValue+System.Trunc(System.Random*IntervalSize);
 If GeneratedValue>HighValue Then GeneratedValue:=HighValue;
 RVNum(GeneratedValue,ResultValue);
End;

Function VarFind(Head:PRexxVariable;N:String):PRexxVariable;
Var P:PRexxVariable;
Begin
 N:=StrToUpper(N);
 P:=Head;
 While P<>Nil Do Begin
  If P^.Name=N Then Begin VarFind:=P;Exit;End;
  P:=P^.Next;
 End;
 VarFind:=Nil;
End;

Procedure VarGet(N:String;Var ResultValue:RexxValue);
Var P:PRexxVariable;
Begin
 P:=VarFind(Variables,N);
 If P=Nil Then RVText(StrToUpper(N),ResultValue)
        Else RVText(P^.Value,ResultValue);
End;

Procedure VarSet(N,S:String);
Var P:PRexxVariable;
Begin
 N:=StrToUpper(Clean(N));
 P:=VarFind(Variables,N);
 If P=Nil Then Begin
  New(P);P^.Name:=N;P^.Value:='';P^.Next:=Variables;Variables:=P;
 End;
 P^.Value:=S;
End;

Procedure SymbolValue(SymbolName:String;Var ResultValue:RexxValue);
Var J:Integer;ValidSymbol,VariableSymbol:Boolean;
Begin
 SymbolName:=Clean(SymbolName);ValidSymbol:=SymbolName<>'';
 For J:=1 To Length(SymbolName)Do
  If Not(SymbolName[J]in['a'..'z','A'..'Z','0'..'9','.','!','?',
   '_','#','$','@'])Then ValidSymbol:=False;
 If Not ValidSymbol Then Begin RVText('BAD',ResultValue);Exit;End;
 VariableSymbol:=Not(SymbolName[1]in['0'..'9','.']);
 If VariableSymbol and(VarFind(Variables,SymbolName)<>Nil)Then
  RVText('VAR',ResultValue)
 Else RVText('LIT',ResultValue);
End;

Procedure ValueFunction(VariableName,NewValue,Selector:String;
 ArgumentCount:Integer;Var ResultValue:RexxValue);
Var SelectorName:String;
Begin
 If ArgumentCount<1Then Begin RVText('',ResultValue);Exit;End;
 SelectorName:=StrToUpper(Clean(Selector));
 If(ArgumentCount>2)and(SelectorName<>'')Then Begin
  If(SelectorName='ENVIRONMENT')or(SelectorName='OS2ENVIRONMENT')or
    (SelectorName='DOSENVIRONMENT')or(SelectorName='SYSTEM')Then
   RVText(GetEnv(StrToUpper(Clean(VariableName))),ResultValue)
  Else RVText('',ResultValue);
  Exit;
 End;
 VarGet(VariableName,ResultValue);
 If ArgumentCount>1Then VarSet(VariableName,NewValue);
End;

Procedure FreeVariables(Var Head:PRexxVariable);
Var P:PRexxVariable;
Begin
 While Head<>Nil Do Begin P:=Head;Head:=Head^.Next;Dispose(P);End;
End;

Procedure ESkip;Begin
 While(ExprPos<=Length(ExprText))and(ExprText[ExprPos]in[' ',#9])do Inc(ExprPos);
End;

Procedure ECompare(Var ResultValue:RexxValue);Forward;
Function FindRoutineLabel(Name:String):Integer;Forward;
Function CallRoutine(Name:String):String;Forward;
Function CommandIndex(N:String):Integer;Forward;
Function Truth(V:RexxValue):Boolean;Forward;

Procedure FunctionNotImplemented(FunctionByte:Byte;Var ResultValue:RexxValue);
Begin
 WriteLn('Fonction non implementee: ',CommandList[FunctionByte]);
 RVText(CommandList[FunctionByte],ResultValue);
End;

Function BinaryToHex(BinaryText:String):String;
Const HexDigits:Array[0..15]of Char='0123456789ABCDEF';
Var
 Bits,ResultText:String;J,DigitValue,BitCount:Integer;
Begin
 Bits:='';
 For J:=1 To Length(BinaryText)Do Begin
  If BinaryText[J]in['0','1']Then Bits:=Bits+BinaryText[J]
  Else If Not(BinaryText[J]in[' ',#9])Then Begin
   WriteLn('B2X: caractere binaire invalide: ',BinaryText[J]);BinaryToHex:='';Exit;
  End;
 End;
 If Bits=''Then Begin BinaryToHex:='';Exit;End;
 While(Length(Bits)mod 4)<>0Do Bits:='0'+Bits;
 ResultText:='';J:=1;
 While J<=Length(Bits)Do Begin
  DigitValue:=0;
  For BitCount:=0 To 3 Do Begin
   DigitValue:=DigitValue*2;
   If Bits[J+BitCount]='1'Then Inc(DigitValue);
  End;
  ResultText:=ResultText+HexDigits[DigitValue];Inc(J,4);
 End;
 BinaryToHex:=ResultText;
End;

Function HexToBinary(HexText:String):String;
Var J,DigitValue,BitValue:Integer;HexCharacter:Char;ResultText:String;
Begin
 ResultText:='';
 For J:=1 To Length(HexText)Do Begin
  HexCharacter:=UpCase(HexText[J]);
  If HexCharacter in['0'..'9']Then DigitValue:=Ord(HexCharacter)-Ord('0')
  Else If HexCharacter in['A'..'F']Then
   DigitValue:=Ord(HexCharacter)-Ord('A')+10
  Else If HexCharacter in[' ',#9]Then Continue
  Else Begin
   WriteLn('X2B: caractere hexadecimal invalide: ',HexText[J]);
   HexToBinary:='';
   Exit;
  End;
  { Chaque chiffre exige quatre caracteres. Ne jamais produire un groupe
    partiel lorsque la limite des String Turbo Pascal est atteinte. }
  If Length(ResultText)>251Then Break;
  BitValue:=8;
  While BitValue>0Do Begin
   If(DigitValue and BitValue)<>0Then ResultText:=ResultText+'1'
   Else ResultText:=ResultText+'0';
   BitValue:=BitValue div 2;
  End;
 End;
 HexToBinary:=ResultText;
End;

Function HexNibbleValue(HexCharacter:Char):Integer;
Begin
 HexCharacter:=UpCase(HexCharacter);
 If HexCharacter in['0'..'9']Then
  HexNibbleValue:=Ord(HexCharacter)-Ord('0')
 Else If HexCharacter in['A'..'F']Then
  HexNibbleValue:=Ord(HexCharacter)-Ord('A')+10
 Else HexNibbleValue:=-1;
End;

Function HexToCharacter(HexText:String):String;
Var J,DigitsInGroup,HighNibble,LowNibble:Integer;
 HexDigitsText,ResultText:String;LastWasBlank:Boolean;
Begin
 HexDigitsText:='';DigitsInGroup:=0;LastWasBlank:=False;
 For J:=1 To Length(HexText)Do Begin
  If HexNibbleValue(HexText[J])>=0Then Begin
   HexDigitsText:=HexDigitsText+HexText[J];
   Inc(DigitsInGroup);LastWasBlank:=False;
  End Else If HexText[J]in[' ',#9]Then Begin
   If(DigitsInGroup=0)and(Length(HexDigitsText)=0)Then Begin
    WriteLn('X2C: espace hexadecimal mal place');HexToCharacter:='';Exit;
   End;
   If(DigitsInGroup mod 2)<>0Then Begin
    WriteLn('X2C: espace hors d''une frontiere d''octet');HexToCharacter:='';Exit;
   End;
   DigitsInGroup:=0;LastWasBlank:=True;
  End Else Begin
   WriteLn('X2C: caractere hexadecimal invalide: ',HexText[J]);
   HexToCharacter:='';Exit;
  End;
 End;
 If LastWasBlank Then Begin
  WriteLn('X2C: espace hexadecimal final');HexToCharacter:='';Exit;
 End;
 If HexDigitsText=''Then Begin HexToCharacter:='';Exit;End;
 If(Length(HexDigitsText)mod 2)<>0Then HexDigitsText:='0'+HexDigitsText;
 ResultText:='';J:=1;
 While J<=Length(HexDigitsText)Do Begin
  HighNibble:=HexNibbleValue(HexDigitsText[J]);
  LowNibble:=HexNibbleValue(HexDigitsText[J+1]);
  ResultText:=ResultText+Chr(HighNibble*16+LowNibble);
  Inc(J,2);
 End;
 HexToCharacter:=ResultText;
End;

Procedure HexToDecimal(HexText:String;RequestedDigits:LongInt;
 DigitsSpecified:Boolean;Var ResultValue:RexxValue);
Var J,DigitsInGroup,OriginalLength,FirstDigit,UsedDigits:Integer;
 DigitValue:Integer;DecimalValue,SignValue:Real;
 HexDigitsText:String;LastWasBlank:Boolean;
Begin
 HexDigitsText:='';DigitsInGroup:=0;LastWasBlank:=False;
 For J:=1 To Length(HexText)Do Begin
  If HexNibbleValue(HexText[J])>=0Then Begin
   HexDigitsText:=HexDigitsText+HexText[J];
   Inc(DigitsInGroup);LastWasBlank:=False;
  End Else If HexText[J]in[' ',#9]Then Begin
   If(DigitsInGroup=0)and(Length(HexDigitsText)=0)Then Begin
    RVNum(0,ResultValue);Exit;
   End;
   If(DigitsInGroup mod 2)<>0Then Begin RVNum(0,ResultValue);Exit;End;
   DigitsInGroup:=0;LastWasBlank:=True;
  End Else Begin RVNum(0,ResultValue);Exit;End;
 End;
 If LastWasBlank Then Begin RVNum(0,ResultValue);Exit;End;
 OriginalLength:=Length(HexDigitsText);
 If OriginalLength=0Then Begin RVNum(0,ResultValue);Exit;End;
 If DigitsSpecified Then Begin
  If RequestedDigits<=0Then Begin RVNum(0,ResultValue);Exit;End;
  If RequestedDigits<OriginalLength Then
   FirstDigit:=OriginalLength-RequestedDigits+1
  Else FirstDigit:=1;
 End Else FirstDigit:=1;
 UsedDigits:=OriginalLength-FirstDigit+1;
 { Le type Real de Turbo Pascal deborde au-dela d'environ 31 chiffres
   hexadecimaux. Ne pas laisser une conversion invalide lever l'erreur 205. }
 If UsedDigits>31Then Begin
  WriteLn('X2D: valeur trop grande pour le type Real de Turbo Pascal');
  RVNum(0,ResultValue);Exit;
 End;
 DecimalValue:=0;
 For J:=FirstDigit To OriginalLength Do Begin
  DigitValue:=HexNibbleValue(HexDigitsText[J]);
  DecimalValue:=DecimalValue*16.0+DigitValue;
 End;
 If DigitsSpecified and(RequestedDigits<=OriginalLength)and
   (HexNibbleValue(HexDigitsText[FirstDigit])>=8)Then Begin
  SignValue:=1;
  For J:=1 To RequestedDigits Do SignValue:=SignValue*16.0;
  DecimalValue:=DecimalValue-SignValue;
 End;
 RVNum(DecimalValue,ResultValue);
End;

Function CharacterToHex(SourceText:String):String;
Const HexDigits:Array[0..15]of Char='0123456789ABCDEF';
Var J,ByteValue:Integer;ResultText:String;
Begin
 ResultText:='';J:=1;
 { Deux caracteres sont produits par octet. Une String Turbo Pascal ne peut
   contenir que 255 caracteres, donc au plus 127 octets peuvent etre rendus
   sans couper une paire hexadecimale. }
 While(J<=Length(SourceText))and(Length(ResultText)<=253)Do Begin
  ByteValue:=Ord(SourceText[J]);
  ResultText:=ResultText+HexDigits[ByteValue div 16]+HexDigits[ByteValue mod 16];
  Inc(J);
 End;
 CharacterToHex:=ResultText;
End;

Procedure BeepSound(Frequency,Duration:LongInt;Var ResultValue:RexxValue);
Begin
 If Frequency<37Then Frequency:=37;
 If Frequency>32767Then Frequency:=32767;
 If Duration<0Then Duration:=0;
 If Duration>32767Then Duration:=32767;
 If Duration>0Then Begin
  Sound(Frequency);Delay(Duration);NoSound;
 End;
 RVNum(0,ResultValue);
End;

Function BitAndText(LeftText,RightText,PadText:String;UsePad:Boolean):String;
Var J,ResultLength:Integer;LeftByte,RightByte,PadByte:Byte;ResultText:String;
Begin
 If UsePad Then Begin
  If PadText=''Then PadByte:=0 Else PadByte:=Ord(PadText[1]);
  If Length(LeftText)>Length(RightText)Then ResultLength:=Length(LeftText) Else ResultLength:=Length(RightText);
 End Else Begin
  PadByte:=0;
  If Length(LeftText)<Length(RightText)Then ResultLength:=Length(LeftText) Else ResultLength:=Length(RightText);
 End;
 ResultText:='';
 For J:=1 To ResultLength Do Begin
  If J<=Length(LeftText)Then LeftByte:=Ord(LeftText[J]) Else LeftByte:=PadByte;
  If J<=Length(RightText)Then RightByte:=Ord(RightText[J]) Else RightByte:=PadByte;
  ResultText:=ResultText+Chr(LeftByte and RightByte);
 End;
 BitAndText:=ResultText;
End;

Function BitOrText(LeftText,RightText,PadText:String;UsePad:Boolean):String;
Var J,ResultLength:Integer;LeftByte,RightByte,PadByte:Byte;ResultText:String;
Begin
 If UsePad Then Begin
  If PadText=''Then PadByte:=0 Else PadByte:=Ord(PadText[1]);
  If Length(LeftText)>Length(RightText)Then ResultLength:=Length(LeftText) Else ResultLength:=Length(RightText);
 End Else Begin
  PadByte:=0;
  If Length(LeftText)<Length(RightText)Then ResultLength:=Length(LeftText) Else ResultLength:=Length(RightText);
 End;
 ResultText:='';
 For J:=1 To ResultLength Do Begin
  If J<=Length(LeftText)Then LeftByte:=Ord(LeftText[J]) Else LeftByte:=PadByte;
  If J<=Length(RightText)Then RightByte:=Ord(RightText[J]) Else RightByte:=PadByte;
  ResultText:=ResultText+Chr(LeftByte or RightByte);
 End;
 BitOrText:=ResultText;
End;

Function BitXorText(LeftText,RightText,PadText:String;UsePad:Boolean):String;
Var J,ResultLength:Integer;LeftByte,RightByte,PadByte:Byte;ResultText:String;
Begin
 If UsePad Then Begin
  If PadText=''Then PadByte:=0 Else PadByte:=Ord(PadText[1]);
  If Length(LeftText)>Length(RightText)Then ResultLength:=Length(LeftText) Else ResultLength:=Length(RightText);
 End Else Begin
  PadByte:=0;
  If Length(LeftText)<Length(RightText)Then ResultLength:=Length(LeftText) Else ResultLength:=Length(RightText);
 End;
 ResultText:='';
 For J:=1 To ResultLength Do Begin
  If J<=Length(LeftText)Then LeftByte:=Ord(LeftText[J]) Else LeftByte:=PadByte;
  If J<=Length(RightText)Then RightByte:=Ord(RightText[J]) Else RightByte:=PadByte;
  ResultText:=ResultText+Chr(LeftByte xor RightByte);
 End;
 BitXorText:=ResultText;
End;

Function RepeatCharacter(C:Char;Count:Integer):String;
Var J:Integer;S:String;
Begin
 S:='';For J:=1 To Count Do S:=S+C;RepeatCharacter:=S;
End;

Function ChangeString(Needle,SourceText,Replacement:String):String;
Var P:Integer;ResultText,RemainingText:String;
Begin
 If Needle=''Then Begin ChangeString:=SourceText;Exit;End;
 ResultText:='';RemainingText:=SourceText;
 P:=System.Pos(Needle,RemainingText);
 While P>0Do Begin
  ResultText:=ResultText+Copy(RemainingText,1,P-1)+Replacement;
  Delete(RemainingText,1,P+Length(Needle)-1);
  P:=System.Pos(Needle,RemainingText);
 End;
 ChangeString:=ResultText+RemainingText;
End;

Function CompareText(LeftText,RightText,PadText:String):Integer;
Var J,CompareLength:Integer;LeftChar,RightChar,PadChar:Char;
Begin
 If PadText=''Then PadChar:=' ' Else PadChar:=PadText[1];
 If Length(LeftText)>Length(RightText)Then CompareLength:=Length(LeftText)
  Else CompareLength:=Length(RightText);
 For J:=1 To CompareLength Do Begin
  If J<=Length(LeftText)Then LeftChar:=LeftText[J] Else LeftChar:=PadChar;
  If J<=Length(RightText)Then RightChar:=RightText[J] Else RightChar:=PadChar;
  If LeftChar<>RightChar Then Begin CompareText:=J;Exit;End;
 End;
 CompareText:=0;
End;

Procedure ConditionValue(OptionText:String;Var ResultValue:RexxValue);
Var OptionCode:Char;
Begin
 { CONDITION ne decrit que la condition qui a effectivement transfere le
   controle au gestionnaire courant. Armer un piege avec SIGNAL ON ne suffit
   donc pas a creer une condition. }
 If CurrentConditionName=''Then Begin
  RVText('',ResultValue);Exit;
 End;
 OptionText:=StrToUpper(Clean(OptionText));
 If OptionText=''Then OptionCode:='I'Else OptionCode:=OptionText[1];
 Case OptionCode Of
  'C':RVText(CurrentConditionName,ResultValue);
  'D':RVText(CurrentConditionDescription,ResultValue);
  'I':RVText(CurrentConditionInstruction,ResultValue);
  'S':RVText(CurrentConditionStatus,ResultValue);
 Else
  RVText('',ResultValue);
 End;
End;

Function CopiesText(SourceText:String;Count:LongInt):String;
Var ResultText:String;
Begin
 ResultText:='';
 If(Count<=0)or(SourceText='')Then Begin CopiesText:=ResultText;Exit;End;
 { Une String Turbo Pascal est limitee a 255 caracteres. On construit donc
   autant de copies completes que le type de retour peut en contenir. }
 While(Count>0)and(Length(ResultText)+Length(SourceText)<=255)Do Begin
  ResultText:=ResultText+SourceText;Dec(Count);
 End;
 CopiesText:=ResultText;
End;

Function CountStringOccurrences(Needle,SourceText:String):LongInt;
Var MatchPosition:Integer;OccurrenceCount:LongInt;
Begin
 OccurrenceCount:=0;
 If Needle=''Then Begin CountStringOccurrences:=0;Exit;End;
 MatchPosition:=System.Pos(Needle,SourceText);
 While MatchPosition>0Do Begin
  Inc(OccurrenceCount);
  { La recherche reprend apres toute l'occurrence trouvee: les occurrences
    qui se chevauchent ne sont pas comptees par COUNTSTR. }
  Delete(SourceText,1,MatchPosition+Length(Needle)-1);
  MatchPosition:=System.Pos(Needle,SourceText);
 End;
 CountStringOccurrences:=OccurrenceCount;
End;

Function ReverseText(SourceText:String):String;
Var LeftIndex,RightIndex:Integer;TemporaryCharacter:Char;
Begin
 LeftIndex:=1;RightIndex:=Length(SourceText);
 While LeftIndex<RightIndex Do Begin
  TemporaryCharacter:=SourceText[LeftIndex];
  SourceText[LeftIndex]:=SourceText[RightIndex];
  SourceText[RightIndex]:=TemporaryCharacter;
  Inc(LeftIndex);Dec(RightIndex);
 End;
 ReverseText:=SourceText;
End;

Procedure CharacterToDecimal(SourceText:String;CharacterCount:LongInt;
 CountSpecified:Boolean;Var ResultValue:RexxValue);
Var J,FirstCharacter:Integer;DecimalValue,SignValue:Real;
Begin
 If SourceText=''Then Begin RVNum(0,ResultValue);Exit;End;
 If CountSpecified Then Begin
  If CharacterCount<=0Then Begin RVNum(0,ResultValue);Exit;End;
  If CharacterCount<Length(SourceText)Then
   FirstCharacter:=Length(SourceText)-CharacterCount+1
  Else FirstCharacter:=1;
 End Else FirstCharacter:=1;
 DecimalValue:=0;
 For J:=FirstCharacter To Length(SourceText)Do
  DecimalValue:=DecimalValue*256+Ord(SourceText[J]);
 If CountSpecified Then Begin
  { Lorsque N depasse la longueur, le remplissage a gauche est fait avec
    des octets nuls: la valeur reste donc positive. }
  If CharacterCount<=Length(SourceText)Then
   If Ord(SourceText[FirstCharacter])>=128Then Begin
    SignValue:=1;
    For J:=1 To CharacterCount Do SignValue:=SignValue*256;
    DecimalValue:=DecimalValue-SignValue;
   End;
 End;
 RVNum(DecimalValue,ResultValue);
End;

Function DecimalToCharacter(NumberValue,CharacterCount:LongInt;
 CountSpecified:Boolean):String;
Var ResultText:String;ByteValue:Integer;
Begin
 ResultText:='';
 If CountSpecified Then Begin
  If CharacterCount<=0Then Begin DecimalToCharacter:='';Exit;End;
  If CharacterCount>255Then CharacterCount:=255;
  While CharacterCount>0Do Begin
   ByteValue:=NumberValue mod 256;
   If ByteValue<0Then Inc(ByteValue,256);
   ResultText:=Chr(ByteValue)+ResultText;
   NumberValue:=(NumberValue-ByteValue)div 256;
   Dec(CharacterCount);
  End;
 End Else Begin
  { Sans longueur, REXX choisit la representation non signee minimale. }
  If NumberValue<=0Then Begin DecimalToCharacter:='';Exit;End;
  While NumberValue>0Do Begin
   ByteValue:=NumberValue mod 256;
   ResultText:=Chr(ByteValue)+ResultText;
   NumberValue:=NumberValue div 256;
  End;
 End;
 DecimalToCharacter:=ResultText;
End;

Function DecimalToHex(NumberValue,HexLength:LongInt;
 LengthSpecified:Boolean):String;
Const HexDigits:Array[0..15]of Char='0123456789ABCDEF';
Var ResultText:String;DigitValue:Integer;
Begin
 ResultText:='';
 If LengthSpecified Then Begin
  If HexLength<=0Then Begin DecimalToHex:='';Exit;End;
  If HexLength>255Then HexLength:=255;
  While HexLength>0Do Begin
   DigitValue:=NumberValue mod 16;
   If DigitValue<0Then Inc(DigitValue,16);
   ResultText:=HexDigits[DigitValue]+ResultText;
   NumberValue:=(NumberValue-DigitValue)div 16;
   Dec(HexLength);
  End;
 End Else Begin
  If NumberValue=0Then Begin DecimalToHex:='0';Exit;End;
  If NumberValue<0Then Begin DecimalToHex:='';Exit;End;
  While NumberValue>0Do Begin
   DigitValue:=NumberValue mod 16;
   ResultText:=HexDigits[DigitValue]+ResultText;
   NumberValue:=NumberValue div 16;
  End;
 End;
 DecimalToHex:=ResultText;
End;

Function IsRexxNumber(SourceText:String;Var NumberValue:Real):Boolean;
Var ErrorPosition:Integer;
Begin
 SourceText:=NormalizeRexxNumber(SourceText);
 If SourceText=''Then Begin IsRexxNumber:=False;Exit;End;
 Val(SourceText,NumberValue,ErrorPosition);
 IsRexxNumber:=ErrorPosition=0;
End;

Procedure DataTypeValue(SourceText,TypeText:String;TypeSpecified:Boolean;
 Var ResultValue:RexxValue);
Var J,DigitsInGroup,WholeDigits:Integer;TypeCode:Char;Matches,SeenBlank:Boolean;
 NumberValue,AbsoluteWhole:Real;
Begin
 If Not TypeSpecified Then Begin
  If IsRexxNumber(SourceText,NumberValue)Then RVText('NUM',ResultValue)
  Else RVText('CHAR',ResultValue);
  Exit;
 End;
 TypeText:=StrToUpper(Clean(TypeText));
 If TypeText=''Then Begin RVNum(0,ResultValue);Exit;End;
 TypeCode:=TypeText[1];Matches:=SourceText<>'';
 Case TypeCode Of
  'A':For J:=1 To Length(SourceText)Do
       If Not(SourceText[J]in['a'..'z','A'..'Z','0'..'9'])Then Matches:=False;
  'B':For J:=1 To Length(SourceText)Do
       If Not(SourceText[J]in['0','1'])Then Matches:=False;
  'C','D':Matches:=False; { Les jeux DBCS ne sont pas geres par ce moteur. }
  'L':For J:=1 To Length(SourceText)Do If Not(SourceText[J]in['a'..'z'])Then Matches:=False;
  'M':For J:=1 To Length(SourceText)Do
       If Not(SourceText[J]in['a'..'z','A'..'Z'])Then Matches:=False;
  'N':Matches:=IsRexxNumber(SourceText,NumberValue);
  'S':For J:=1 To Length(SourceText)Do
       If Not(SourceText[J]in['a'..'z','A'..'Z','0'..'9','.','!','?',
        '_','#','$','@'])Then Matches:=False;
  'U':For J:=1 To Length(SourceText)Do If Not(SourceText[J]in['A'..'Z'])Then Matches:=False;
  'W':Begin
       Matches:=IsRexxNumber(SourceText,NumberValue);
       If Matches Then Matches:=NumberValue=System.Trunc(NumberValue);
       If Matches Then Begin
        AbsoluteWhole:=Abs(NumberValue);WholeDigits:=1;
        While AbsoluteWhole>=10Do Begin AbsoluteWhole:=AbsoluteWhole/10;Inc(WholeDigits);End;
        Matches:=WholeDigits<=NumericDigitsValue;
       End;
      End;
  'X':Begin
       Matches:=True;DigitsInGroup:=0;SeenBlank:=False;
       For J:=1 To Length(SourceText)Do Begin
        If SourceText[J]=' 'Then Begin
         If DigitsInGroup>0Then Begin
          If SeenBlank and((DigitsInGroup mod 2)<>0)Then Matches:=False;
          DigitsInGroup:=0;SeenBlank:=True;
         End Else If Not SeenBlank Then Matches:=False;
        End Else Begin
         If Not(SourceText[J]in['0'..'9','a'..'f','A'..'F'])Then Matches:=False;
         Inc(DigitsInGroup);
        End;
       End;
       If(Length(SourceText)>0)and(DigitsInGroup=0)Then Matches:=False;
       If SeenBlank and((DigitsInGroup mod 2)<>0)Then Matches:=False;
      End;
 Else Matches:=False;
 End;
 If Matches Then RVNum(1,ResultValue)Else RVNum(0,ResultValue);
End;

Function IsLeapYear(Year:Word):Boolean;
Begin
 IsLeapYear:=((Year mod 4)=0)and(((Year mod 100)<>0)or((Year mod 400)=0));
End;

Function DaysBeforeYear(Year:Word):LongInt;
Var PreviousYear:LongInt;
Begin
 PreviousYear:=Year-1;
 DaysBeforeYear:=PreviousYear*365+PreviousYear div 4-
  PreviousYear div 100+PreviousYear div 400;
End;

Function DayOfYearValue(Year,Month,Day:Word):Integer;
Const DaysPerMonth:Array[1..12]of Byte=(31,28,31,30,31,30,31,31,30,31,30,31);
Var J,ResultDay:Integer;
Begin
 ResultDay:=Day;
 For J:=1 To Month-1Do Begin
  Inc(ResultDay,DaysPerMonth[J]);
  If(J=2)and IsLeapYear(Year)Then Inc(ResultDay);
 End;
 DayOfYearValue:=ResultDay;
End;

Function PaddedNumber(Value,Width:Integer):String;
Var S:String;
Begin
 Str(Value,S);S:=Clean(S);
 While Length(S)<Width Do S:='0'+S;
 PaddedNumber:=S;
End;

Procedure DateValue(OptionText:String;Var ResultValue:RexxValue);
Const
 ShortMonth:Array[1..12]of String[3]=('Jan','Feb','Mar','Apr','May','Jun',
  'Jul','Aug','Sep','Oct','Nov','Dec');
 FullMonth:Array[1..12]of String[9]=('January','February','March','April',
  'May','June','July','August','September','October','November','December');
 WeekDayName:Array[1..7]of String[9]=('Monday','Tuesday','Wednesday',
  'Thursday','Friday','Saturday','Sunday');
Var Year,Month,Day,DosDayOfWeek:Word;OptionCode:Char;DayOfYear:Integer;
 BaseDays,CenturyDays:LongInt;S:String;
Begin
 GetDate(Year,Month,Day,DosDayOfWeek);
 OptionText:=StrToUpper(Clean(OptionText));
 If OptionText=''Then OptionCode:='N'Else OptionCode:=OptionText[1];
 DayOfYear:=DayOfYearValue(Year,Month,Day);
 BaseDays:=DaysBeforeYear(Year)+DayOfYear-1;
 Case OptionCode Of
  'B':RVNum(BaseDays,ResultValue);
  'C':Begin
       CenturyDays:=BaseDays-DaysBeforeYear((Year div 100)*100)+1;
       RVNum(CenturyDays,ResultValue);
      End;
  'D':RVNum(DayOfYear,ResultValue);
  'E':RVText(PaddedNumber(Day,2)+'/'+PaddedNumber(Month,2)+'/'+
       PaddedNumber(Year mod 100,2),ResultValue);
  'J':RVText(PaddedNumber(Year mod 100,2)+PaddedNumber(DayOfYear,3),ResultValue);
  'M':RVText(FullMonth[Month],ResultValue);
  'N':Begin Str(Day,S);S:=Clean(S);RVText(S+' '+ShortMonth[Month]+' '+
       PaddedNumber(Year,4),ResultValue);End;
  'O':RVText(PaddedNumber(Year mod 100,2)+'/'+PaddedNumber(Month,2)+'/'+
       PaddedNumber(Day,2),ResultValue);
  'S':RVText(PaddedNumber(Year,4)+PaddedNumber(Month,2)+PaddedNumber(Day,2),ResultValue);
  'U':RVText(PaddedNumber(Month,2)+'/'+PaddedNumber(Day,2)+'/'+
       PaddedNumber(Year mod 100,2),ResultValue);
  'W':RVText(WeekDayName[(BaseDays mod 7)+1],ResultValue);
 Else RVText('',ResultValue);
 End;
End;

Function DeleteStringPart(SourceText:String;StartPosition,DeleteLength:LongInt;
 LengthSpecified:Boolean):String;
Var DeleteCount:Integer;
Begin
 If(StartPosition<1)or(StartPosition>Length(SourceText))Then Begin
  DeleteStringPart:=SourceText;Exit;
 End;
 If LengthSpecified Then Begin
  If DeleteLength<=0Then Begin DeleteStringPart:=SourceText;Exit;End;
  If DeleteLength>255Then DeleteCount:=255 Else DeleteCount:=DeleteLength;
 End Else DeleteCount:=Length(SourceText)-StartPosition+1;
 Delete(SourceText,StartPosition,DeleteCount);
 DeleteStringPart:=SourceText;
End;

Function DeleteWords(SourceText:String;FirstWord,WordCount:LongInt;
 CountSpecified:Boolean):String;
Var Position,DeleteStart,WordsSeen:Integer;WordsToDelete:LongInt;
Begin
 If FirstWord<1Then Begin DeleteWords:=SourceText;Exit;End;
 If CountSpecified and(WordCount<=0)Then Begin DeleteWords:=SourceText;Exit;End;
 Position:=1;WordsSeen:=0;DeleteStart:=0;
 While Position<=Length(SourceText)Do Begin
  While(Position<=Length(SourceText))and(SourceText[Position]in[' ',#9])Do Inc(Position);
  If Position>Length(SourceText)Then Break;
  Inc(WordsSeen);
  If WordsSeen=FirstWord Then Begin DeleteStart:=Position;Break;End;
  While(Position<=Length(SourceText))and Not(SourceText[Position]in[' ',#9])Do Inc(Position);
 End;
 If DeleteStart=0Then Begin DeleteWords:=SourceText;Exit;End;
 If CountSpecified Then WordsToDelete:=WordCount Else WordsToDelete:=32767;
 Position:=DeleteStart;
 While(Position<=Length(SourceText))and(WordsToDelete>0)Do Begin
  While(Position<=Length(SourceText))and Not(SourceText[Position]in[' ',#9])Do Inc(Position);
  Dec(WordsToDelete);
  { Les blancs places apres le dernier mot supprime appartiennent eux aussi
    a la sous-chaine DELWORD. }
  While(Position<=Length(SourceText))and(SourceText[Position]in[' ',#9])Do Inc(Position);
 End;
 Delete(SourceText,DeleteStart,Position-DeleteStart);
 DeleteWords:=SourceText;
End;

Procedure DirectoryValue(NewDirectory:String;DirectorySpecified:Boolean;
 Var ResultValue:RexxValue);
Var CurrentDirectory:String;ErrorCode:Integer;
Begin
 If DirectorySpecified Then Begin
  {$I-}ChDir(NewDirectory);{$I+}
  ErrorCode:=IoResult;
  If ErrorCode<>0Then Begin RVText('',ResultValue);Exit;End;
 End;
 GetDir(0,CurrentDirectory);
 RVText(CurrentDirectory,ResultValue);
End;

Procedure SysDeleteFile(FilePath:String;Var ResultValue:RexxValue);
Var TargetFile:File;ErrorCode:Integer;
Begin
 If FilePath=''Then Begin RVNum(2,ResultValue);Exit;End;
 Assign(TargetFile,FilePath);
 {$I-}Erase(TargetFile);{$I+}
 ErrorCode:=IoResult;
 RVNum(ErrorCode,ResultValue);
End;

Procedure SysSearchFile(TargetText,FilePath,StemName,OptionsText:String;
 ArgumentCount:Integer;Var ResultValue:RexxValue);
Var SourceFile:Text;LineText,ComparedLine,ComparedTarget,VariableName:String;
 LineNumberText:String;LineNumber,MatchCount,ErrorCode:LongInt;
 CaseSensitive,IncludeLineNumber,Matches:Boolean;
Begin
 If ArgumentCount<3Then Begin RVNum(87,ResultValue);Exit;End;
 StemName:=StrToUpper(Clean(StemName));
 If StemName=''Then Begin RVNum(87,ResultValue);Exit;End;
 If StemName[Length(StemName)]<>'.'Then StemName:=StemName+'.';
 OptionsText:=StrToUpper(OptionsText);
 CaseSensitive:=System.Pos('C',OptionsText)>0;
 IncludeLineNumber:=System.Pos('N',OptionsText)>0;
 VarSet(StemName+'0','0');
 {$I-}Assign(SourceFile,FilePath);Reset(SourceFile);{$I+}
 ErrorCode:=IoResult;
 If ErrorCode<>0Then Begin RVNum(3,ResultValue);Exit;End;
 If CaseSensitive Then ComparedTarget:=TargetText
 Else ComparedTarget:=StrToUpper(TargetText);
 LineNumber:=0;MatchCount:=0;
 While Not Eof(SourceFile)Do Begin
  ReadLn(SourceFile,LineText);Inc(LineNumber);
  If CaseSensitive Then ComparedLine:=LineText
  Else ComparedLine:=StrToUpper(LineText);
  Matches:=(ComparedTarget='')or(System.Pos(ComparedTarget,ComparedLine)>0);
  If Matches Then Begin
   Inc(MatchCount);Str(MatchCount,VariableName);
   VariableName:=StemName+Clean(VariableName);
   If IncludeLineNumber Then Begin
    Str(LineNumber,LineNumberText);
    VarSet(VariableName,Clean(LineNumberText)+' '+LineText);
   End Else VarSet(VariableName,LineText);
  End;
 End;
 Close(SourceFile);Str(MatchCount,LineNumberText);
 VarSet(StemName+'0',Clean(LineNumberText));
 RVNum(0,ResultValue);
End;

Procedure SysMakeDirectory(DirectoryName:String;Var ResultValue:RexxValue);
Var ErrorCode:Integer;
Begin
 If DirectoryName=''Then Begin RVNum(3,ResultValue);Exit;End;
 {$I-}MkDir(DirectoryName);{$I+}
 ErrorCode:=IoResult;
 RVNum(ErrorCode,ResultValue);
End;

Procedure SysRemoveDirectory(DirectoryName:String;Var ResultValue:RexxValue);
Var ErrorCode:Integer;
Begin
 If DirectoryName=''Then Begin RVNum(3,ResultValue);Exit;End;
 {$I-}RmDir(DirectoryName);{$I+}
 ErrorCode:=IoResult;
 RVNum(ErrorCode,ResultValue);
End;

Procedure SysSleepValue(Seconds:Real;ArgumentSpecified:Boolean;
 Var ResultValue:RexxValue);
Var RemainingMilliseconds:Real;FinalDelay:Word;
Begin
 If(Not ArgumentSpecified)or(Seconds<0)Then Begin
  RVNum(87,ResultValue);
  Exit;
 End;
 RemainingMilliseconds:=Seconds*1000.0;
 { Crt.Delay recoit un Word sous Turbo Pascal. Fractionner l'attente
   permet donc de supporter une duree superieure a 65,535 secondes. }
 While RemainingMilliseconds>=60000.0Do Begin
  Delay(60000);
  RemainingMilliseconds:=RemainingMilliseconds-60000.0;
 End;
 FinalDelay:=System.Trunc(RemainingMilliseconds);
 If FinalDelay>0Then Delay(FinalDelay);
 RVNum(0,ResultValue);
End;

Procedure SysClearScreen(ArgumentCount:Integer;Var ResultValue:RexxValue);
Begin
 If ArgumentCount<>0Then Begin RVNum(87,ResultValue);Exit;End;
 ClrScr;
 RVNum(0,ResultValue);
End;

Procedure SysCursorPosition(RowValue,ColumnValue:RexxValue;
 ArgumentCount:Integer;Var ResultValue:RexxValue);
Var OldRow,OldColumn,NewRow,NewColumn:LongInt;RowText,ColumnText:String;
Begin
 OldRow:=WhereY-1;OldColumn:=WhereX-1;
 If OldRow<0Then OldRow:=0;
 If OldColumn<0Then OldColumn:=0;
 Str(OldRow,RowText);Str(OldColumn,ColumnText);
 RowText:=Clean(RowText);ColumnText:=Clean(ColumnText);
 If ArgumentCount=2Then Begin
  NewRow:=System.Trunc(RowValue.Number);
  NewColumn:=System.Trunc(ColumnValue.Number);
  { GotoXY utilise des Byte et des coordonnees commencant a 1. }
  If(NewRow<0)or(NewRow>254)or(NewColumn<0)or(NewColumn>254)Then Begin
   RVText('',ResultValue);Exit;
  End;
  GotoXY(NewColumn+1,NewRow+1);
 End Else If ArgumentCount<>0Then Begin
  RVText('',ResultValue);Exit;
 End;
 RVText(RowText+' '+ColumnText,ResultValue);
End;

Procedure SysVolumeLabelValue(DriveText:String;Var ResultValue:RexxValue);
Var DriveName,RootPath,CurrentDirectory,VolumeLabel:String;
 J:Integer;SearchData:SearchRec;
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
  RootBuffer,VolumeBuffer:Array[0..255]of Char;
  {$ENDIF}
 {$ENDIF}
Begin
 DriveText:=Clean(DriveText);
 If DriveText=''Then Begin
  GetDir(0,CurrentDirectory);
  If(Length(CurrentDirectory)>=2)and(CurrentDirectory[2]=':')Then
   DriveName:=Copy(CurrentDirectory,1,2)Else Begin RVText('',ResultValue);Exit;End;
 End Else Begin
  If Not(DriveText[1]in['a'..'z','A'..'Z'])Then Begin RVText('',ResultValue);Exit;End;
  DriveName:=UpCase(DriveText[1])+':';
 End;
 RootPath:=DriveName+'\';
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
  FillChar(RootBuffer,SizeOf(RootBuffer),0);
  FillChar(VolumeBuffer,SizeOf(VolumeBuffer),0);
  For J:=1 To Length(RootPath)Do RootBuffer[J-1]:=RootPath[J];
  If GetVolumeInformationA(RootBuffer,VolumeBuffer,SizeOf(VolumeBuffer),
    Nil,Nil,Nil,Nil,0)Then Begin
   VolumeLabel:='';J:=0;
   While(J<SizeOf(VolumeBuffer))and(VolumeBuffer[J]<>#0)Do Begin
    VolumeLabel:=VolumeLabel+VolumeBuffer[J];Inc(J);
   End;
   RVText(VolumeLabel,ResultValue);
  End Else RVText('',ResultValue);
  Exit;
  {$ENDIF}
 {$ENDIF}
 FindFirst(RootPath+'*.*',VolumeID,SearchData);
 If DosError=0Then RVText(SearchData.Name,ResultValue)
  Else RVText('',ResultValue);
End;

Function TwoDigits(Value:Word):String;
Var S:String;
Begin
 Str(Value,S);
 If Length(S)<2Then S:='0'+S;
 TwoDigits:=S;
End;

Function CurrentTimeSeconds:Real;
Var HourValue,MinuteValue,SecondValue,HundredthValue:Word;
Begin
 GetTime(HourValue,MinuteValue,SecondValue,HundredthValue);
 CurrentTimeSeconds:=HourValue*3600.0+MinuteValue*60.0+SecondValue+
 HundredthValue/100.0;
End;

Procedure SysGetKeyValue(EchoOption:String;TimeoutSeconds:Real;
 ArgumentCount:Integer;Var ResultValue:RexxValue);
Var EchoKey,HasTimeout:Boolean;KeyCharacter:Char;
 StartTime,CurrentTime,ElapsedTime:Real;UpperOption:String;
Begin
 If ArgumentCount>2Then Begin RVText('',ResultValue);Exit;End;
 If TimeoutSeconds<0Then Begin RVText('',ResultValue);Exit;End;
 UpperOption:=StrToUpper(Clean(EchoOption));
 EchoKey:=Not((UpperOption='N')or(UpperOption='NO')or
  (UpperOption='NOECHO'));
 HasTimeout:=(ArgumentCount>1)and(TimeoutSeconds>0);
 StartTime:=CurrentTimeSeconds;
 While Not KeyPressed Do Begin
  If HasTimeout Then Begin
   CurrentTime:=CurrentTimeSeconds;
   ElapsedTime:=CurrentTime-StartTime;
   If ElapsedTime<0Then ElapsedTime:=ElapsedTime+86400.0;
   If ElapsedTime>=TimeoutSeconds Then Begin RVText('',ResultValue);Exit;End;
  End;
  Delay(1);
 End;
 KeyCharacter:=ReadKey;
 If EchoKey Then Write(KeyCharacter);
 RVText(KeyCharacter,ResultValue);
End;

Procedure TimeValue(OptionText:String;ArgumentCount:Integer;
 Var ResultValue:RexxValue);
Var HourValue,MinuteValue,SecondValue,HundredthValue,CivilHour:Word;
 OptionCharacter:Char;CurrentSeconds,ElapsedSeconds:Real;S,Suffix:String;
Begin
 If ArgumentCount>1Then Begin RVText('',ResultValue);Exit;End;
 OptionText:=StrToUpper(Clean(OptionText));
 If OptionText=''Then OptionCharacter:='N'Else OptionCharacter:=OptionText[1];
 GetTime(HourValue,MinuteValue,SecondValue,HundredthValue);
 CurrentSeconds:=HourValue*3600.0+MinuteValue*60.0+SecondValue+
  HundredthValue/100.0;
 Case OptionCharacter Of
  'C':Begin
   CivilHour:=HourValue mod 12;If CivilHour=0Then CivilHour:=12;
   If HourValue<12Then Suffix:='am'Else Suffix:='pm';
   Str(CivilHour,S);RVText(S+':'+TwoDigits(MinuteValue)+Suffix,ResultValue);
  End;
  'E','R':Begin
   ElapsedSeconds:=CurrentSeconds-TimeElapsedStart;
   If ElapsedSeconds<0Then ElapsedSeconds:=ElapsedSeconds+86400.0;
   Str(ElapsedSeconds:0:6,S);RVText(S,ResultValue);
   If OptionCharacter='R'Then TimeElapsedStart:=CurrentSeconds;
  End;
  'H':RVNum(HourValue,ResultValue);
  'L':RVText(TwoDigits(HourValue)+':'+TwoDigits(MinuteValue)+':'+
   TwoDigits(SecondValue)+'.'+TwoDigits(HundredthValue)+'0000',ResultValue);
  'M':RVNum(HourValue*60+MinuteValue,ResultValue);
  'N':RVText(TwoDigits(HourValue)+':'+TwoDigits(MinuteValue)+':'+
   TwoDigits(SecondValue),ResultValue);
  'S':RVNum(System.Trunc(CurrentSeconds),ResultValue);
 Else RVText('',ResultValue);
 End;
End;

Function FileSpecPart(OptionText,FileSpecification:String):String;
Var J,LastSeparator,NameStart:Integer;OptionCode:Char;
Begin
 OptionText:=StrToUpper(Clean(OptionText));
 If OptionText=''Then Begin FileSpecPart:='';Exit;End;
 OptionCode:=OptionText[1];
 If(Length(FileSpecification)>=2)and(FileSpecification[2]=':')Then NameStart:=3
 Else NameStart:=1;
 LastSeparator:=0;
 For J:=NameStart To Length(FileSpecification)Do
  If FileSpecification[J]in['\','/']Then LastSeparator:=J;
 Case OptionCode Of
  'D':Begin
       If NameStart=3 Then FileSpecPart:=Copy(FileSpecification,1,2)
       Else FileSpecPart:='';
      End;
  'P':Begin
       If LastSeparator>=NameStart Then
        FileSpecPart:=Copy(FileSpecification,NameStart,LastSeparator-NameStart+1)
       Else FileSpecPart:='';
      End;
  'N':Begin
       If LastSeparator>0 Then FileSpecPart:=Copy(FileSpecification,LastSeparator+1,255)
       Else FileSpecPart:=Copy(FileSpecification,NameStart,255);
      End;
 Else FileSpecPart:='';
 End;
End;

Function RexxSignificantDigits(NumberText:String):Integer;
Var J,Count:Integer;SeenNonZero:Boolean;
Begin
 Count:=0;SeenNonZero:=False;NumberText:=StrToUpper(Clean(NumberText));
 J:=1;
 While(J<=Length(NumberText))and(NumberText[J]<>'E')Do Begin
  If NumberText[J]in['0'..'9']Then Begin
   If NumberText[J]<>'0'Then SeenNonZero:=True;
   If SeenNonZero Then Inc(Count);
  End;
  Inc(J);
 End;
 If Count=0Then Count:=1;
 RexxSignificantDigits:=Count;
End;

Function FormatRexxNumber(NumberValue:Real;OriginalText,BeforeText,AfterText,
 ExponentPlacesText,ExponentTriggerText:String;ArgumentCount:Integer):String;
Var BeforeSpecified,AfterSpecified,ExponentPlacesSpecified,
 ExponentTriggerSpecified,UseExponent:Boolean;
 BeforePlaces,AfterPlaces,ExponentPlaces,ExponentTrigger,ErrorPosition,
 ExponentValue,IntegerLength,PointPosition,J,SignificantDigits:Integer;
 Mantissa,AbsoluteValue:Real;S,ExponentText:String;
Begin
 If ArgumentCount<2Then Begin FormatRexxNumber:=NumToText(NumberValue);Exit;End;
 BeforeSpecified:=(ArgumentCount>=2)and(BeforeText<>'');
 AfterSpecified:=(ArgumentCount>=3)and(AfterText<>'');
 ExponentPlacesSpecified:=(ArgumentCount>=4)and(ExponentPlacesText<>'');
 ExponentTriggerSpecified:=(ArgumentCount>=5)and(ExponentTriggerText<>'');
 BeforePlaces:=0;AfterPlaces:=0;ExponentPlaces:=0;ExponentTrigger:=NumericDigitsValue;
 If BeforeSpecified Then Val(BeforeText,BeforePlaces,ErrorPosition);
 If AfterSpecified Then Val(AfterText,AfterPlaces,ErrorPosition);
 If ExponentPlacesSpecified Then Val(ExponentPlacesText,ExponentPlaces,ErrorPosition);
 If ExponentTriggerSpecified Then Val(ExponentTriggerText,ExponentTrigger,ErrorPosition);
 If(BeforePlaces<0)or(AfterPlaces<0)or(ExponentPlaces<0)or(ExponentTrigger<0)Then Begin
  FormatRexxNumber:='';Exit;
 End;
 If BeforePlaces>255Then BeforePlaces:=255;
 If AfterPlaces>100Then AfterPlaces:=100;
 If ExponentPlaces>9Then Begin FormatRexxNumber:='';Exit;End;
 AbsoluteValue:=Abs(NumberValue);ExponentValue:=0;Mantissa:=NumberValue;
 If AbsoluteValue>0Then Begin
  While AbsoluteValue>=10Do Begin AbsoluteValue:=AbsoluteValue/10;Inc(ExponentValue);End;
  While AbsoluteValue<1Do Begin AbsoluteValue:=AbsoluteValue*10;Dec(ExponentValue);End;
 End;
 UseExponent:=False;
 If ExponentTriggerSpecified Then Begin
  If ExponentTrigger=0Then UseExponent:=ExponentValue<>0
  Else UseExponent:=(ExponentValue+1>ExponentTrigger)or
    (ExponentValue<-(2*ExponentTrigger));
 End;
 If ExponentPlacesSpecified and(ExponentPlaces=0)Then UseExponent:=False;
 If UseExponent Then Begin
  If NumericFormValue='ENGINEERING'Then Begin
   While(ExponentValue mod 3)<>0Do Dec(ExponentValue);
  End;
  Mantissa:=NumberValue;
  If ExponentValue>0Then For J:=1 To ExponentValue Do Mantissa:=Mantissa/10
  Else For J:=1 To -ExponentValue Do Mantissa:=Mantissa*10;
  If Not AfterSpecified Then Begin
   SignificantDigits:=RexxSignificantDigits(OriginalText);
   IntegerLength:=1;
   If Abs(Mantissa)>=10Then IntegerLength:=2;
   If Abs(Mantissa)>=100Then IntegerLength:=3;
   AfterPlaces:=SignificantDigits-IntegerLength;If AfterPlaces<0Then AfterPlaces:=0;
  End;
  Str(Mantissa:0:AfterPlaces,S);S:=Clean(S);
 End Else Begin
  If AfterSpecified Then Begin Str(NumberValue:0:AfterPlaces,S);S:=Clean(S);End
  Else S:=NumToText(NumberValue);
 End;
 PointPosition:=System.Pos('.',S);If PointPosition=0Then IntegerLength:=Length(S)
  Else IntegerLength:=PointPosition-1;
 If BeforeSpecified Then Begin
  If IntegerLength>BeforePlaces Then Begin FormatRexxNumber:='';Exit;End;
  While IntegerLength<BeforePlaces Do Begin S:=' '+S;Inc(IntegerLength);End;
 End;
 If UseExponent Then Begin
  Str(Abs(ExponentValue),ExponentText);ExponentText:=Clean(ExponentText);
  If ExponentPlacesSpecified Then Begin
   If Length(ExponentText)>ExponentPlaces Then Begin FormatRexxNumber:='';Exit;End;
   While Length(ExponentText)<ExponentPlaces Do ExponentText:='0'+ExponentText;
  End;
  If ExponentValue<0Then S:=S+'E-'+ExponentText Else S:=S+'E+'+ExponentText;
 End Else If ExponentPlacesSpecified and(ExponentPlaces>0)Then
  S:=S+RepeatCharacter(' ',ExponentPlaces+2);
 FormatRexxNumber:=S;
End;

Function InsertText(NewText,TargetText:String;InsertPosition,InsertLength:LongInt;
 PositionSpecified,LengthSpecified,PadSpecified:Boolean;PadText:String):String;
Var PadCharacter:Char;Insertion,ResultText:String;RequiredPadding:LongInt;
Begin
 If PadSpecified and(PadText<>'')Then PadCharacter:=PadText[1]Else PadCharacter:=' ';
 If Not PositionSpecified Then InsertPosition:=0;
 If InsertPosition<0Then InsertPosition:=0;
 If InsertPosition>255Then InsertPosition:=255;
 RequiredPadding:=InsertPosition-Length(TargetText);
 If RequiredPadding>0Then
  TargetText:=TargetText+RepeatCharacter(PadCharacter,RequiredPadding);
 If LengthSpecified Then Begin
  If InsertLength<0Then InsertLength:=0;
  If InsertLength>255Then InsertLength:=255;
 End Else InsertLength:=Length(NewText);
 If InsertLength<=Length(NewText)Then Insertion:=Copy(NewText,1,InsertLength)
 Else Insertion:=NewText+RepeatCharacter(PadCharacter,InsertLength-Length(NewText));
 ResultText:=Copy(TargetText,1,InsertPosition)+Insertion+
  Copy(TargetText,InsertPosition+1,255);
 InsertText:=Copy(ResultText,1,255);
End;

Function OverlayText(NewText,TargetText:String;OverlayPosition,OverlayLength:LongInt;
 PositionSpecified,LengthSpecified,PadSpecified:Boolean;PadText:String):String;
Var PadCharacter:Char;Replacement,ResultText:String;RequiredPadding:LongInt;
Begin
 If PadSpecified and(PadText<>'')Then PadCharacter:=PadText[1]Else PadCharacter:=' ';
 If Not PositionSpecified Then OverlayPosition:=1;
 If OverlayPosition<1Then OverlayPosition:=1;
 If OverlayPosition>255Then OverlayPosition:=255;
 If LengthSpecified Then Begin
  If OverlayLength<0Then OverlayLength:=0;
  If OverlayLength>255Then OverlayLength:=255;
 End Else OverlayLength:=Length(NewText);
 RequiredPadding:=OverlayPosition-1-Length(TargetText);
 If RequiredPadding>0Then
  TargetText:=TargetText+RepeatCharacter(PadCharacter,RequiredPadding);
 If OverlayLength<=Length(NewText)Then Replacement:=Copy(NewText,1,OverlayLength)
 Else Replacement:=NewText+RepeatCharacter(PadCharacter,OverlayLength-Length(NewText));
 ResultText:=Copy(TargetText,1,OverlayPosition-1)+Replacement+
  Copy(TargetText,OverlayPosition+OverlayLength,255);
 OverlayText:=Copy(ResultText,1,255);
End;

Function LastPosition(Needle,Haystack:String;StartPosition:LongInt;
 StartSpecified:Boolean):Integer;
Var Candidate,LastCandidate:Integer;
Begin
 LastPosition:=0;
 If(Needle='')or(Haystack='')Then Exit;
 If StartSpecified Then Begin
  If StartPosition<1Then Exit;
  If StartPosition>Length(Haystack)Then StartPosition:=Length(Haystack);
 End Else StartPosition:=Length(Haystack);
 LastCandidate:=Length(Haystack)-Length(Needle)+1;
 If LastCandidate<1Then Exit;
 If StartPosition<LastCandidate Then Candidate:=StartPosition
 Else Candidate:=LastCandidate;
 While Candidate>=1 Do Begin
  If Copy(Haystack,Candidate,Length(Needle))=Needle Then Begin
   LastPosition:=Candidate;
   Exit;
  End;
 Dec(Candidate);
 End;
End;

Function ForwardPosition(Needle,Haystack:String;StartPosition:LongInt;
 StartSpecified:Boolean):Integer;
Var RelativePosition:Integer;
Begin
 ForwardPosition:=0;
 If(Needle='')or(Haystack='')Then Exit;
 If Not StartSpecified Then StartPosition:=1;
 If(StartPosition<1)or(StartPosition>Length(Haystack))Then Exit;
 RelativePosition:=System.Pos(Needle,Copy(Haystack,StartPosition,255));
 If RelativePosition>0Then
  ForwardPosition:=RelativePosition+StartPosition-1;
End;

Function SubStringText(SourceText:String;StartPosition,RequestedLength:LongInt;
 LengthSpecified,PadSpecified:Boolean;PadText:String):String;
Var PadCharacter:Char;AvailableLength,PaddingLength:LongInt;ResultText:String;
Begin
 If StartPosition<1Then Begin SubStringText:='';Exit;End;
 If PadSpecified and(PadText<>'')Then PadCharacter:=PadText[1]
 Else PadCharacter:=' ';
 If Not LengthSpecified Then Begin
  If StartPosition>Length(SourceText)Then ResultText:=''
  Else ResultText:=Copy(SourceText,StartPosition,255);
  SubStringText:=ResultText;
  Exit;
 End;
 If RequestedLength<=0Then Begin SubStringText:='';Exit;End;
 If RequestedLength>255Then RequestedLength:=255;
 If StartPosition>Length(SourceText)Then AvailableLength:=0
 Else Begin
  AvailableLength:=Length(SourceText)-StartPosition+1;
  If AvailableLength>RequestedLength Then AvailableLength:=RequestedLength;
 End;
 If AvailableLength>0Then ResultText:=Copy(SourceText,StartPosition,AvailableLength)
 Else ResultText:='';
 PaddingLength:=RequestedLength-AvailableLength;
 If PaddingLength>0Then ResultText:=ResultText+
  RepeatCharacter(PadCharacter,PaddingLength);
 SubStringText:=ResultText;
End;

Function SubWordText(SourceText:String;FirstWord,RequestedWords:LongInt;
 WordCountSpecified:Boolean):String;
Var CharacterPosition,CurrentWord,StartPosition,EndPosition:Integer;
 WordsRemaining:LongInt;
Begin
 SubWordText:='';
 If FirstWord<1Then Exit;
 If WordCountSpecified and(RequestedWords<=0)Then Exit;
 CharacterPosition:=1;CurrentWord:=0;StartPosition:=0;
 While CharacterPosition<=Length(SourceText)Do Begin
  While(CharacterPosition<=Length(SourceText))and
   (SourceText[CharacterPosition]in[' ',#9])Do Inc(CharacterPosition);
  If CharacterPosition>Length(SourceText)Then Break;
  Inc(CurrentWord);
  If CurrentWord=FirstWord Then Begin StartPosition:=CharacterPosition;Break;End;
  While(CharacterPosition<=Length(SourceText))and not
   (SourceText[CharacterPosition]in[' ',#9])Do Inc(CharacterPosition);
 End;
 If StartPosition=0Then Exit;
 If WordCountSpecified Then WordsRemaining:=RequestedWords
 Else WordsRemaining:=2147483647;
 EndPosition:=StartPosition-1;
 While(CharacterPosition<=Length(SourceText))and(WordsRemaining>0)Do Begin
  While(CharacterPosition<=Length(SourceText))and not
   (SourceText[CharacterPosition]in[' ',#9])Do Begin
   EndPosition:=CharacterPosition;Inc(CharacterPosition);
  End;
  Dec(WordsRemaining);
  If WordsRemaining=0Then Break;
  While(CharacterPosition<=Length(SourceText))and
   (SourceText[CharacterPosition]in[' ',#9])Do Inc(CharacterPosition);
 End;
 If EndPosition>=StartPosition Then
 SubWordText:=Copy(SourceText,StartPosition,EndPosition-StartPosition+1);
End;

Function WordStartIndex(SourceText:String;RequestedWord:LongInt):Integer;
Var CharacterPosition:Integer;CurrentWord:LongInt;
Begin
 WordStartIndex:=0;
 If RequestedWord<1Then Exit;
 CharacterPosition:=1;CurrentWord:=0;
 While CharacterPosition<=Length(SourceText)Do Begin
  While(CharacterPosition<=Length(SourceText))and
   (SourceText[CharacterPosition]in[' ',#9])Do Inc(CharacterPosition);
  If CharacterPosition>Length(SourceText)Then Exit;
  Inc(CurrentWord);
  If CurrentWord=RequestedWord Then Begin
   WordStartIndex:=CharacterPosition;
   Exit;
  End;
  While(CharacterPosition<=Length(SourceText))and not
   (SourceText[CharacterPosition]in[' ',#9])Do Inc(CharacterPosition);
 End;
End;

Function SpaceText(SourceText:String;SeparatorCount:LongInt;
 CountSpecified,PadSpecified:Boolean;PadText:String):String;
Var CharacterPosition:Integer;AddedSeparators:LongInt;PadCharacter:Char;
 ResultText:String;FirstWord:Boolean;
Begin
 If Not CountSpecified Then SeparatorCount:=1;
 If SeparatorCount<0Then Begin SpaceText:='';Exit;End;
 If PadSpecified and(PadText<>'')Then PadCharacter:=PadText[1]
 Else PadCharacter:=' ';
 CharacterPosition:=1;ResultText:='';FirstWord:=True;
 While CharacterPosition<=Length(SourceText)Do Begin
  While(CharacterPosition<=Length(SourceText))and
   (SourceText[CharacterPosition]in[' ',#9])Do Inc(CharacterPosition);
  If CharacterPosition>Length(SourceText)Then Break;
  If Not FirstWord Then Begin
   AddedSeparators:=0;
   While(AddedSeparators<SeparatorCount)and(Length(ResultText)<255)Do Begin
    ResultText:=ResultText+PadCharacter;
    Inc(AddedSeparators);
   End;
  End;
  While(CharacterPosition<=Length(SourceText))and not
   (SourceText[CharacterPosition]in[' ',#9])Do Begin
   If Length(ResultText)<255Then ResultText:=ResultText+SourceText[CharacterPosition];
   Inc(CharacterPosition);
  End;
  FirstWord:=False;
 End;
 SpaceText:=ResultText;
End;

Function CountWords(SourceText:String):Integer;
Var CharacterPosition,WordCount:Integer;
Begin
 WordCount:=0;CharacterPosition:=1;
 While CharacterPosition<=Length(SourceText)Do Begin
  While(CharacterPosition<=Length(SourceText))and
   (SourceText[CharacterPosition]in[' ',#9])Do Inc(CharacterPosition);
  If CharacterPosition>Length(SourceText)Then Begin
   CountWords:=WordCount;
   Exit;
  End;
  Inc(WordCount);
  While(CharacterPosition<=Length(SourceText))and not
   (SourceText[CharacterPosition]in[' ',#9])Do Inc(CharacterPosition);
 End;
 CountWords:=WordCount;
End;

Function WordPhrasePosition(PhraseText,SourceText:String;StartWord:LongInt;
 StartSpecified:Boolean):Integer;
Var PhraseWords,SourceWords,Candidate,LastCandidate:Integer;
 NormalizedPhrase,NormalizedCandidate:String;
Begin
 WordPhrasePosition:=0;
 NormalizedPhrase:=SpaceText(PhraseText,1,True,False,'');
 PhraseWords:=CountWords(NormalizedPhrase);
 If PhraseWords=0Then Exit;
 If Not StartSpecified Then StartWord:=1;
 If StartWord<1Then Exit;
 SourceWords:=CountWords(SourceText);
 LastCandidate:=SourceWords-PhraseWords+1;
 Candidate:=StartWord;
 While Candidate<=LastCandidate Do Begin
  NormalizedCandidate:=SpaceText(SubWordText(SourceText,Candidate,
   PhraseWords,True),1,True,False,'');
  If NormalizedCandidate=NormalizedPhrase Then Begin
   WordPhrasePosition:=Candidate;
   Exit;
  End;
  Inc(Candidate);
 End;
End;

Function StripText(SourceText,OptionText,StripCharacterText:String;
 OptionSpecified,CharacterSpecified:Boolean):String;
Var OptionCharacter,StripCharacter:Char;
Begin
 If OptionSpecified and(OptionText<>'')Then
  OptionCharacter:=UpCase(OptionText[1])
 Else OptionCharacter:='B';
 If CharacterSpecified and(StripCharacterText<>'')Then
  StripCharacter:=StripCharacterText[1]
 Else StripCharacter:=' ';
 If Not(OptionCharacter in['B','L','T'])Then Begin StripText:='';Exit;End;
 If OptionCharacter in['B','L']Then
  While(Length(SourceText)>0)and(SourceText[1]=StripCharacter)Do
   Delete(SourceText,1,1);
 If OptionCharacter in['B','T']Then
  While(Length(SourceText)>0)and
   (SourceText[Length(SourceText)]=StripCharacter)Do
   Delete(SourceText,Length(SourceText),1);
 StripText:=SourceText;
End;

Function TranslateText(SourceText,OutputTable,InputTable,PadText:String;
 ArgumentCount:Integer):String;
Var CharacterPosition,TablePosition:Integer;PadCharacter:Char;
Begin
 If ArgumentCount<=1Then Begin
  TranslateText:=StrToUpper(SourceText);
  Exit;
 End;
 If(ArgumentCount>3)and(PadText<>'')Then PadCharacter:=PadText[1]
 Else PadCharacter:=' ';
 For CharacterPosition:=1 To Length(SourceText)Do Begin
  If ArgumentCount>2Then
   TablePosition:=System.Pos(SourceText[CharacterPosition],InputTable)
  Else TablePosition:=Ord(SourceText[CharacterPosition])+1;
  If TablePosition>0Then Begin
   If TablePosition<=Length(OutputTable)Then
    SourceText[CharacterPosition]:=OutputTable[TablePosition]
   Else SourceText[CharacterPosition]:=PadCharacter;
  End;
 End;
 TranslateText:=SourceText;
End;

Function VerifyText(SourceText,ReferenceText,OptionText:String;
 StartPosition:LongInt;OptionSpecified,StartSpecified:Boolean):Integer;
Var CharacterPosition:Integer;OptionCharacter:Char;CharacterMatches:Boolean;
Begin
 VerifyText:=0;
 If OptionSpecified and(OptionText<>'')Then OptionCharacter:=UpCase(OptionText[1])
 Else OptionCharacter:='N';
 If Not(OptionCharacter in['M','N'])Then Exit;
 If Not StartSpecified Then StartPosition:=1;
 If(StartPosition<1)or(StartPosition>Length(SourceText))Then Exit;
 CharacterPosition:=StartPosition;
 While CharacterPosition<=Length(SourceText)Do Begin
  CharacterMatches:=System.Pos(SourceText[CharacterPosition],ReferenceText)>0;
  If((OptionCharacter='M')and CharacterMatches)or
    ((OptionCharacter='N')and Not CharacterMatches)Then Begin
   VerifyText:=CharacterPosition;
   Exit;
  End;
  Inc(CharacterPosition);
 End;
End;

Function XRangeText(StartText,EndText:String;ArgumentCount:Integer):String;
Var CurrentValue,FinalValue:Byte;GeneratedCount:Integer;ResultText:String;
Begin
 If(ArgumentCount>0)and(StartText<>'')Then CurrentValue:=Ord(StartText[1])
 Else CurrentValue:=0;
 If(ArgumentCount>1)and(EndText<>'')Then FinalValue:=Ord(EndText[1])
 Else FinalValue:=255;
 ResultText:='';GeneratedCount:=0;
 Repeat
  ResultText:=ResultText+Chr(CurrentValue);
  Inc(GeneratedCount);
  If(CurrentValue=FinalValue)or(GeneratedCount>=255)Then Break;
  If CurrentValue=255Then CurrentValue:=0 Else Inc(CurrentValue);
 Until False;
 XRangeText:=ResultText;
End;

Function NormalizeTraceSetting(SettingText:String):String;
Var SettingCharacter:Char;
Begin
 SettingText:=StrToUpper(Clean(SettingText));
 While(Length(SettingText)>0)and(SettingText[1]in['?','!'])Do
  Delete(SettingText,1,1);
 If SettingText=''Then Begin NormalizeTraceSetting:='N';Exit;End;
 SettingCharacter:=SettingText[1];
 If SettingCharacter in['A','C','E','F','I','L','N','O','R','S']Then
  NormalizeTraceSetting:=SettingCharacter
 Else NormalizeTraceSetting:=CurrentTraceSetting;
End;

Procedure TraceValue(SettingText:String;ArgumentCount:Integer;
 Var ResultValue:RexxValue);
Var PreviousSetting:String;
Begin
 PreviousSetting:=CurrentTraceSetting;
 If ArgumentCount>0Then CurrentTraceSetting:=NormalizeTraceSetting(SettingText);
 RVText(PreviousSetting,ResultValue);
End;

Procedure SetLocalValue(Var ResultValue:RexxValue);
Var SavedEnvironment:PLocalEnvironment;
Begin
 New(SavedEnvironment);
 If SavedEnvironment=Nil Then Begin RVNum(0,ResultValue);Exit;End;
 GetDir(0,SavedEnvironment^.DirectoryName);
 SavedEnvironment^.Next:=LocalEnvironments;
 LocalEnvironments:=SavedEnvironment;
 RVNum(1,ResultValue);
End;

Procedure EndLocalValue(Var ResultValue:RexxValue);
Var SavedEnvironment:PLocalEnvironment;ErrorCode:Integer;
Begin
 If LocalEnvironments=Nil Then Begin RVNum(0,ResultValue);Exit;End;
 SavedEnvironment:=LocalEnvironments;
 {$I-}ChDir(SavedEnvironment^.DirectoryName);{$I+}
 ErrorCode:=IoResult;
 If ErrorCode<>0Then Begin RVNum(0,ResultValue);Exit;End;
 LocalEnvironments:=SavedEnvironment^.Next;Dispose(SavedEnvironment);
 RVNum(1,ResultValue);
End;

Procedure RestoreLocalEnvironments;
Var SavedEnvironment:PLocalEnvironment;ErrorCode:Integer;
Begin
 While LocalEnvironments<>Nil Do Begin
  SavedEnvironment:=LocalEnvironments;
  {$I-}ChDir(SavedEnvironment^.DirectoryName);{$I+}
  ErrorCode:=IoResult;
  LocalEnvironments:=SavedEnvironment^.Next;Dispose(SavedEnvironment);
 End;
End;

Function RexxErrorText(ErrorNumber:Integer):String;
Begin
 Case ErrorNumber Of
   3:RexxErrorText:='Program is unreadable';
   4:RexxErrorText:='Program interrupted';
   5:RexxErrorText:='Machine storage exhausted';
   6:RexxErrorText:='Unmatched "/*" or quote';
   7:RexxErrorText:='WHEN or OTHERWISE expected';
   8:RexxErrorText:='Unexpected THEN or ELSE';
   9:RexxErrorText:='Unexpected WHEN or OTHERWISE';
  10:RexxErrorText:='Unexpected or unmatched END';
  11:RexxErrorText:='Control stack full';
  12:RexxErrorText:='Clause too long';
  13:RexxErrorText:='Invalid character in program';
  14:RexxErrorText:='Incomplete DO/SELECT/IF';
  15:RexxErrorText:='Invalid hexadecimal or binary string';
  16:RexxErrorText:='Label not found';
  17:RexxErrorText:='Unexpected PROCEDURE';
  18:RexxErrorText:='THEN expected';
  19:RexxErrorText:='String or symbol expected';
  20:RexxErrorText:='Symbol expected';
  21:RexxErrorText:='Invalid data on end of clause';
  22:RexxErrorText:='Invalid character string';
  23:RexxErrorText:='Invalid data string';
  24:RexxErrorText:='Invalid TRACE request';
  25:RexxErrorText:='Invalid sub-keyword found';
  26:RexxErrorText:='Invalid whole number';
  27:RexxErrorText:='Invalid DO syntax';
  28:RexxErrorText:='Invalid LEAVE or ITERATE';
  29:RexxErrorText:='Environment name too long, or not found';
  30:RexxErrorText:='Name or string too long';
  31:RexxErrorText:='Name starts with number or "."';
  32:RexxErrorText:='';
  33:RexxErrorText:='Invalid expression result';
  34:RexxErrorText:='Logical value not 0 or 1';
  35:RexxErrorText:='Invalid expression';
  36:RexxErrorText:='Unmatched "(" in expression';
  37:RexxErrorText:='Unexpected "," or ")"';
  38:RexxErrorText:='Invalid template or pattern';
  39:RexxErrorText:='Evaluation stack overflow (too many arguments)';
  40:RexxErrorText:='Incorrect call to routine';
  41:RexxErrorText:='Bad arithmetic conversion';
  42:RexxErrorText:='Arithmetic overflow/underflow';
  43:RexxErrorText:='Routine not found';
  44:RexxErrorText:='Function did not return data';
  45:RexxErrorText:='No data specified on function RETURN';
  46:RexxErrorText:='Invalid variable reference';
  47:RexxErrorText:='';
  48:RexxErrorText:='Failure in system service';
  49:RexxErrorText:='Interpretation error';
 Else RexxErrorText:='';
 End;
End;

Procedure RequestProgramExit(ExitValue:RexxValue;ValueSpecified:Boolean;
 Var ResultValue:RexxValue);
Var ExitNumber:LongInt;
Begin
 ExitNumber:=0;
 If ValueSpecified and ExitValue.IsNumber Then ExitNumber:=System.Trunc(ExitValue.Number);
 { Sous DOS et Windows, le code de sortie observable est limite a un octet. }
 If ExitNumber<0Then ExitNumber:=0;
 If ExitNumber>255Then ExitNumber:=255;
 ProgramExitCode:=ExitNumber;ProgramExitRequested:=True;Terminated:=True;
 RVNum(ProgramExitCode,ResultValue);
End;

Procedure CharInValue(StreamName:String;StartPosition,RequestedCount:LongInt;
 UseStart,UseCount:Boolean;Var ResultValue:RexxValue);
Var F:File;Buffer:Array[1..255]of Byte;J,StreamIndex,ReadCount,Count:Integer;
 Position:LongInt;ResultText:String;
Begin
 If Not UseCount Then RequestedCount:=1;
 If RequestedCount<0Then RequestedCount:=0;
 If RequestedCount>255Then RequestedCount:=255;
 Count:=RequestedCount;ResultText:='';
 If StreamName=''Then Begin
  For J:=1 To Count Do ResultText:=ResultText+ReadKey;
  RVText(ResultText,ResultValue);Exit;
 End;
 StreamIndex:=0;
 For J:=1 To CharInStreamCount Do If CharInNames[J]=StreamName Then StreamIndex:=J;
 If StreamIndex=0Then Begin
  If CharInStreamCount<MaxRoutineArgs Then Begin
   Inc(CharInStreamCount);StreamIndex:=CharInStreamCount;
   CharInNames[StreamIndex]:=StreamName;CharInPositions[StreamIndex]:=1;
  End Else StreamIndex:=1;
 End;
 If UseStart Then Position:=StartPosition Else Position:=CharInPositions[StreamIndex];
 If Position<1Then Position:=1;
 {$I-}Assign(F,StreamName);Reset(F,1);{$I+}
 If IoResult<>0Then Begin RVText('',ResultValue);Exit;End;
 If Position-1<FileSize(F)Then Begin
  Seek(F,Position-1);BlockRead(F,Buffer,Count,ReadCount);
  For J:=1 To ReadCount Do ResultText:=ResultText+Chr(Buffer[J]);
 End Else ReadCount:=0;
 Close(F);CharInPositions[StreamIndex]:=Position+ReadCount;
 RVText(ResultText,ResultValue);
End;

Procedure CharOutValue(StreamName,SourceText:String;StartPosition:LongInt;
 UseStart:Boolean;Var ResultValue:RexxValue);
Var F:File;J,StreamIndex,WrittenCount:Integer;Position:LongInt;
Begin
 If StreamName=''Then Begin
  Write(SourceText);RVNum(0,ResultValue);Exit;
 End;
 StreamIndex:=0;
 For J:=1 To CharOutStreamCount Do If CharOutNames[J]=StreamName Then StreamIndex:=J;
 If StreamIndex=0Then Begin
  If CharOutStreamCount<MaxRoutineArgs Then Begin
   Inc(CharOutStreamCount);StreamIndex:=CharOutStreamCount;
   CharOutNames[StreamIndex]:=StreamName;CharOutPositions[StreamIndex]:=0;
  End Else StreamIndex:=1;
 End;
 {$I-}Assign(F,StreamName);Reset(F,1);{$I+}
 If IoResult<>0Then Begin
  {$I-}Rewrite(F,1);{$I+}
  If IoResult<>0Then Begin RVNum(Length(SourceText),ResultValue);Exit;End;
 End;
 If UseStart Then Position:=StartPosition
 Else Begin
  Position:=CharOutPositions[StreamIndex];
  If Position=0Then Position:=FileSize(F)+1;
 End;
 If Position<1Then Position:=1;
 Seek(F,Position-1);WrittenCount:=0;
 If SourceText<>''Then BlockWrite(F,SourceText[1],Length(SourceText),WrittenCount);
 Close(F);CharOutPositions[StreamIndex]:=Position+WrittenCount;
 RVNum(Length(SourceText)-WrittenCount,ResultValue);
End;

Procedure CharsValue(StreamName:String;Var ResultValue:RexxValue);
Var F:File;J,StreamIndex:Integer;Position,Remaining:LongInt;
Begin
 If StreamName=''Then Begin
  If KeyPressed Then RVNum(1,ResultValue)Else RVNum(0,ResultValue);
  Exit;
 End;
 StreamIndex:=0;
 For J:=1 To CharInStreamCount Do If CharInNames[J]=StreamName Then StreamIndex:=J;
 If StreamIndex=0Then Position:=1 Else Position:=CharInPositions[StreamIndex];
 {$I-}Assign(F,StreamName);Reset(F,1);{$I+}
 If IoResult<>0Then Begin RVNum(0,ResultValue);Exit;End;
 Remaining:=FileSize(F)-(Position-1);Close(F);
 If Remaining<0Then Remaining:=0;
 RVNum(Remaining,ResultValue);
End;

Procedure LinesValue(StreamName:String;Var ResultValue:RexxValue);
Var F:File;J,StreamIndex,ReadCount:Integer;Position,LineCount:LongInt;
 CharacterByte:Byte;PreviousWasCR,LastWasTerminator,HaveData:Boolean;
Begin
 If StreamName=''Then Begin
  If KeyPressed Then RVNum(1,ResultValue)Else RVNum(0,ResultValue);
  Exit;
 End;
 StreamIndex:=0;
 For J:=1 To CharInStreamCount Do
  If CharInNames[J]=StreamName Then StreamIndex:=J;
 If StreamIndex=0Then Position:=1 Else Position:=CharInPositions[StreamIndex];
 If Position<1Then Position:=1;
 {$I-}Assign(F,StreamName);Reset(F,1);{$I+}
 If IoResult<>0Then Begin RVNum(0,ResultValue);Exit;End;
 If Position-1>=FileSize(F)Then Begin Close(F);RVNum(0,ResultValue);Exit;End;
 Seek(F,Position-1);LineCount:=0;PreviousWasCR:=False;
 LastWasTerminator:=False;HaveData:=False;
 Repeat
  BlockRead(F,CharacterByte,1,ReadCount);
  If ReadCount>0Then Begin
   HaveData:=True;
   If CharacterByte=13Then Begin
    Inc(LineCount);PreviousWasCR:=True;LastWasTerminator:=True;
   End Else If CharacterByte=10Then Begin
    If Not PreviousWasCR Then Inc(LineCount);
    PreviousWasCR:=False;LastWasTerminator:=True;
   End Else Begin
    PreviousWasCR:=False;LastWasTerminator:=False;
   End;
  End;
 Until ReadCount=0;
 Close(F);
 If HaveData and Not LastWasTerminator Then Inc(LineCount);
 RVNum(LineCount,ResultValue);
End;

Procedure LineInValue(StreamName:String;RequestedLine,RequestedCount:LongInt;
 UseLine,UseCount:Boolean;Var ResultValue:RexxValue);
Var F:File;J,StreamIndex,ReadCount:Integer;Position,CurrentLine,FileLength:LongInt;
 CharacterByte,FollowingByte:Byte;LineText:String;LineFinished:Boolean;
Begin
 If Not UseCount Then RequestedCount:=1;
 If StreamName=''Then Begin
  If RequestedCount<=0Then RVText('',ResultValue)
   Else Begin ReadLn(LineText);RVText(LineText,ResultValue);End;
  Exit;
 End;
 StreamIndex:=0;
 For J:=1 To CharInStreamCount Do
  If CharInNames[J]=StreamName Then StreamIndex:=J;
 If StreamIndex=0Then Begin
  If CharInStreamCount<MaxRoutineArgs Then Begin
   Inc(CharInStreamCount);StreamIndex:=CharInStreamCount;
   CharInNames[StreamIndex]:=StreamName;CharInPositions[StreamIndex]:=1;
  End Else StreamIndex:=1;
 End;
 {$I-}Assign(F,StreamName);Reset(F,1);{$I+}
 If IoResult<>0Then Begin RVText('',ResultValue);Exit;End;
 FileLength:=FileSize(F);
 If UseLine and(RequestedLine>0)Then Begin
  Position:=1;CurrentLine:=1;Seek(F,0);
  While(CurrentLine<RequestedLine)and(Position<=FileLength)Do Begin
   BlockRead(F,CharacterByte,1,ReadCount);
   If ReadCount=0Then Break;
   Inc(Position);
   If CharacterByte=13Then Begin
    If Position<=FileLength Then Begin
     BlockRead(F,FollowingByte,1,ReadCount);
     If(ReadCount>0)and(FollowingByte=10)Then Inc(Position)
      Else If ReadCount>0Then Seek(F,Position-1);
    End;
    Inc(CurrentLine);
   End Else If CharacterByte=10Then Inc(CurrentLine);
  End;
 End Else Begin
  Position:=CharInPositions[StreamIndex];If Position<1Then Position:=1;
 End;
 If Position-1>FileLength Then Position:=FileLength+1;
 Seek(F,Position-1);LineText:='';
 If RequestedCount>0Then Begin
  LineFinished:=False;
  While Not LineFinished Do Begin
   BlockRead(F,CharacterByte,1,ReadCount);
   If ReadCount=0Then LineFinished:=True
   Else Begin
    Inc(Position);
    If CharacterByte=13Then Begin
     If Position<=FileLength Then Begin
      BlockRead(F,FollowingByte,1,ReadCount);
      If(ReadCount>0)and(FollowingByte=10)Then Inc(Position)
       Else If ReadCount>0Then Seek(F,Position-1);
     End;
     LineFinished:=True;
    End Else If CharacterByte=10Then LineFinished:=True
    Else If Length(LineText)<255Then LineText:=LineText+Chr(CharacterByte);
   End;
  End;
 End;
 Close(F);CharInPositions[StreamIndex]:=Position;
 RVText(LineText,ResultValue);
End;

Procedure LineOutValue(StreamName,SourceText:String;RequestedLine:LongInt;
 TextSpecified,LineSpecified:Boolean;Var ResultValue:RexxValue);
Var F:File;J,StreamIndex,ReadCount,WrittenCount:Integer;
 Position,CurrentLine,FileLength:LongInt;CharacterByte,FollowingByte:Byte;
 EndOfLine:Array[1..2]of Byte;
Begin
 If StreamName=''Then Begin
  If TextSpecified and(SourceText<>'')Then WriteLn(SourceText);
  RVNum(0,ResultValue);Exit;
 End;
 StreamIndex:=0;
 For J:=1 To CharOutStreamCount Do
  If CharOutNames[J]=StreamName Then StreamIndex:=J;
 If StreamIndex=0Then Begin
  If CharOutStreamCount<MaxRoutineArgs Then Begin
   Inc(CharOutStreamCount);StreamIndex:=CharOutStreamCount;
   CharOutNames[StreamIndex]:=StreamName;CharOutPositions[StreamIndex]:=0;
  End Else StreamIndex:=1;
 End;
 If Not LineSpecified and((Not TextSpecified)or(SourceText=''))Then Begin
  CharOutPositions[StreamIndex]:=0;RVNum(0,ResultValue);Exit;
 End;
 {$I-}Assign(F,StreamName);Reset(F,1);{$I+}
 If IoResult<>0Then Begin
  {$I-}Rewrite(F,1);{$I+}
  If IoResult<>0Then Begin RVNum(1,ResultValue);Exit;End;
 End;
 FileLength:=FileSize(F);
 If LineSpecified and(RequestedLine>0)Then Begin
  Position:=1;CurrentLine:=1;Seek(F,0);
  While(CurrentLine<RequestedLine)and(Position<=FileLength)Do Begin
   BlockRead(F,CharacterByte,1,ReadCount);
   If ReadCount=0Then Break;
   Inc(Position);
   If CharacterByte=13Then Begin
    If Position<=FileLength Then Begin
     BlockRead(F,FollowingByte,1,ReadCount);
     If(ReadCount>0)and(FollowingByte=10)Then Inc(Position)
      Else If ReadCount>0Then Seek(F,Position-1);
    End;
    Inc(CurrentLine);
   End Else If CharacterByte=10Then Inc(CurrentLine);
  End;
  EndOfLine[1]:=13;EndOfLine[2]:=10;
  While CurrentLine<RequestedLine Do Begin
   Seek(F,FileSize(F));BlockWrite(F,EndOfLine,2,WrittenCount);
   Inc(CurrentLine);Position:=FileSize(F)+1;
  End;
 End Else Begin
  Position:=CharOutPositions[StreamIndex];
  If Position=0Then Position:=FileLength+1;
 End;
 If Position<1Then Position:=1;
 If SourceText=''Then Begin
  Close(F);CharOutPositions[StreamIndex]:=Position;
  RVNum(0,ResultValue);Exit;
 End;
 Seek(F,Position-1);WrittenCount:=0;
 If SourceText<>''Then BlockWrite(F,SourceText[1],Length(SourceText),WrittenCount);
 If WrittenCount<>Length(SourceText)Then Begin
  Close(F);RVNum(1,ResultValue);Exit;
 End;
 EndOfLine[1]:=13;EndOfLine[2]:=10;
 BlockWrite(F,EndOfLine,2,WrittenCount);
 Close(F);
 If WrittenCount<>2Then RVNum(1,ResultValue)
 Else Begin
  CharOutPositions[StreamIndex]:=Position+Length(SourceText)+2;
  RVNum(0,ResultValue);
 End;
End;

Function StreamLineAtPosition(StreamName:String;Position:LongInt):LongInt;
Var F:File;CharacterByte:Byte;ReadCount,ErrorCode:Integer;
 BytesRead,LineNumber:LongInt;PreviousWasCR:Boolean;
Begin
 LineNumber:=1;BytesRead:=0;PreviousWasCR:=False;
 {$I-}Assign(F,StreamName);Reset(F,1);{$I+}ErrorCode:=IoResult;
 If ErrorCode<>0Then Begin StreamLineAtPosition:=0;Exit;End;
 While(BytesRead<Position-1)and(BytesRead<FileSize(F))Do Begin
  BlockRead(F,CharacterByte,1,ReadCount);
  If ReadCount=0Then Break;
  Inc(BytesRead);
  If CharacterByte=13Then Begin Inc(LineNumber);PreviousWasCR:=True;End
  Else If CharacterByte=10Then Begin
   If Not PreviousWasCR Then Inc(LineNumber);PreviousWasCR:=False;
  End Else PreviousWasCR:=False;
 End;
 Close(F);StreamLineAtPosition:=LineNumber;
End;

Procedure StreamValue(StreamName,OptionText,CommandText:String;
 ArgumentCount:Integer;Var ResultValue:RexxValue);
Var F:File;J,K,ErrorCode,ReadIndex,WriteIndex:Integer;
 FileLength,NewPosition,OffsetValue:LongInt;OptionCode:Char;
 UpperCommand,PositionText,ExpandedName:String;PositionCode:Char;
Begin
 StreamName:=Clean(StreamName);OptionText:=StrToUpper(Clean(OptionText));
 CommandText:=Clean(CommandText);UpperCommand:=StrToUpper(CommandText);
 If OptionText=''Then OptionCode:='S'Else OptionCode:=OptionText[1];
 ReadIndex:=0;WriteIndex:=0;
 For J:=1 To CharInStreamCount Do If CharInNames[J]=StreamName Then ReadIndex:=J;
 For J:=1 To CharOutStreamCount Do If CharOutNames[J]=StreamName Then WriteIndex:=J;
 If OptionCode='S'Then Begin
  If StreamName=''Then RVText('READY',ResultValue)
  Else Begin
   {$I-}Assign(F,StreamName);Reset(F,1);{$I+}ErrorCode:=IoResult;
   If ErrorCode=0Then Begin Close(F);RVText('READY',ResultValue);End
    Else RVText('NOTREADY',ResultValue);
  End;
  Exit;
 End;
 If OptionCode='D'Then Begin
  If StreamName=''Then RVText('READY',ResultValue)
  Else Begin
   {$I-}Assign(F,StreamName);Reset(F,1);{$I+}ErrorCode:=IoResult;
   If ErrorCode=0Then Begin Close(F);RVText('READY',ResultValue);End
    Else RVText('NOTREADY: FILE NOT FOUND',ResultValue);
  End;
  Exit;
 End;
 If OptionCode<>'C'Then Begin RVText('',ResultValue);Exit;End;

 If UpperCommand='QUERY EXISTS'Then Begin
  {$I-}Assign(F,StreamName);Reset(F,1);{$I+}ErrorCode:=IoResult;
  If ErrorCode=0Then Begin Close(F);ExpandedName:=FExpand(StreamName);RVText(ExpandedName,ResultValue);End
   Else RVText('',ResultValue);
  Exit;
 End;
 If UpperCommand='QUERY SIZE'Then Begin
  {$I-}Assign(F,StreamName);Reset(F,1);{$I+}ErrorCode:=IoResult;
  If ErrorCode=0Then Begin FileLength:=FileSize(F);Close(F);RVNum(FileLength,ResultValue);End
   Else RVNum(0,ResultValue);
  Exit;
 End;
 If UpperCommand='QUERY LINEPOS READ'Then Begin
  If ReadIndex=0Then RVNum(1,ResultValue)
   Else RVNum(StreamLineAtPosition(StreamName,CharInPositions[ReadIndex]),ResultValue);
  Exit;
 End;
 If UpperCommand='QUERY LINEPOS WRITE'Then Begin
  If WriteIndex=0Then RVNum(0,ResultValue)
   Else RVNum(StreamLineAtPosition(StreamName,CharOutPositions[WriteIndex]),ResultValue);
  Exit;
 End;
 If UpperCommand='CLOSE'Then Begin
  If ReadIndex>0Then Begin
   For J:=ReadIndex To CharInStreamCount-1 Do Begin
    CharInNames[J]:=CharInNames[J+1];CharInPositions[J]:=CharInPositions[J+1];
   End;
   Dec(CharInStreamCount);
  End;
  If WriteIndex>0Then Begin
   For J:=WriteIndex To CharOutStreamCount-1 Do Begin
    CharOutNames[J]:=CharOutNames[J+1];CharOutPositions[J]:=CharOutPositions[J+1];
   End;
   Dec(CharOutStreamCount);
  End;
  RVText('READY:',ResultValue);Exit;
 End;
 If(UpperCommand='RESET')or(UpperCommand='FLUSH')Then Begin
  If(UpperCommand='RESET')Then Begin
   If ReadIndex>0Then CharInPositions[ReadIndex]:=1;
   If WriteIndex>0Then CharOutPositions[WriteIndex]:=0;
  End;
  RVText('READY:',ResultValue);Exit;
 End;
 If Copy(UpperCommand,1,4)='OPEN'Then Begin
  {$I-}Assign(F,StreamName);Reset(F,1);{$I+}ErrorCode:=IoResult;
  If ErrorCode<>0Then Begin
   If(System.Pos('WRITE',UpperCommand)>0)or(System.Pos('APPEND',UpperCommand)>0)or
     (System.Pos('REPLACE',UpperCommand)>0)or(UpperCommand='OPEN')Then Begin
    {$I-}Rewrite(F,1);{$I+}ErrorCode:=IoResult;
   End;
  End Else If System.Pos('REPLACE',UpperCommand)>0Then Begin
   Close(F);{$I-}Rewrite(F,1);{$I+}ErrorCode:=IoResult;
  End;
  If ErrorCode<>0Then Begin RVText('ERROR',ResultValue);Exit;End;
  FileLength:=FileSize(F);Close(F);
  If ReadIndex=0Then Begin
   If CharInStreamCount<MaxRoutineArgs Then Begin
    Inc(CharInStreamCount);ReadIndex:=CharInStreamCount;
    CharInNames[ReadIndex]:=StreamName;
   End;
  End;
  If ReadIndex>0Then CharInPositions[ReadIndex]:=1;
  If WriteIndex=0Then Begin
   If CharOutStreamCount<MaxRoutineArgs Then Begin
    Inc(CharOutStreamCount);WriteIndex:=CharOutStreamCount;
    CharOutNames[WriteIndex]:=StreamName;
   End;
  End;
  If WriteIndex>0Then Begin
   If System.Pos('APPEND',UpperCommand)>0Then CharOutPositions[WriteIndex]:=FileLength+1
    Else CharOutPositions[WriteIndex]:=1;
  End;
  RVText('READY:',ResultValue);Exit;
 End;

 If Copy(UpperCommand,1,7)='READPOS'Then Begin
  PositionText:=Clean(Copy(CommandText,8,255));K:=ReadIndex;
 End Else If Copy(UpperCommand,1,8)='WRITEPOS'Then Begin
  PositionText:=Clean(Copy(CommandText,9,255));K:=WriteIndex;
 End Else Begin RVText('ERROR',ResultValue);Exit;End;
 If K=0Then Begin
  If Copy(UpperCommand,1,7)='READPOS'Then Begin
   If CharInStreamCount>=MaxRoutineArgs Then Begin RVText('ERROR',ResultValue);Exit;End;
   Inc(CharInStreamCount);K:=CharInStreamCount;CharInNames[K]:=StreamName;
   CharInPositions[K]:=1;
  End Else Begin
   If CharOutStreamCount>=MaxRoutineArgs Then Begin RVText('ERROR',ResultValue);Exit;End;
   Inc(CharOutStreamCount);K:=CharOutStreamCount;CharOutNames[K]:=StreamName;
   CharOutPositions[K]:=1;
  End;
 End;
 If Copy(UpperCommand,1,7)='READPOS'Then NewPosition:=CharInPositions[K]
  Else NewPosition:=CharOutPositions[K];
 If PositionText<>''Then Begin
  PositionCode:='=';
  If PositionText[1]in['=','+','-','<']Then Begin
   PositionCode:=PositionText[1];Delete(PositionText,1,1);PositionText:=Clean(PositionText);
  End;
  Val(PositionText,OffsetValue,ErrorCode);
  If ErrorCode<>0Then Begin RVText('ERROR',ResultValue);Exit;End;
  If PositionCode='='Then NewPosition:=OffsetValue
  Else If PositionCode='+'Then NewPosition:=NewPosition+OffsetValue
  Else If PositionCode='-'Then NewPosition:=NewPosition-OffsetValue
  Else Begin
   {$I-}Assign(F,StreamName);Reset(F,1);{$I+}ErrorCode:=IoResult;
   If ErrorCode=0Then Begin FileLength:=FileSize(F);Close(F);NewPosition:=FileLength-OffsetValue+1;End;
  End;
  If NewPosition<1Then NewPosition:=1;
  If Copy(UpperCommand,1,7)='READPOS'Then CharInPositions[K]:=NewPosition
   Else CharOutPositions[K]:=NewPosition;
 End;
 RVNum(NewPosition,ResultValue);
End;

Function CenterText(SourceText:String;TargetLength:Integer;PadText:String):String;
Var LeftCount,RightCount,StartPosition:Integer;PadChar:Char;
Begin
 If TargetLength<=0Then Begin CenterText:='';Exit;End;
 If PadText=''Then PadChar:=' ' Else PadChar:=PadText[1];
 If Length(SourceText)>TargetLength Then Begin
  StartPosition:=((Length(SourceText)-TargetLength)div 2)+1;
  CenterText:=Copy(SourceText,StartPosition,TargetLength);Exit;
 End;
 LeftCount:=(TargetLength-Length(SourceText))div 2;
 RightCount:=TargetLength-Length(SourceText)-LeftCount;
 CenterText:=RepeatCharacter(PadChar,LeftCount)+SourceText+RepeatCharacter(PadChar,RightCount);
End;

Procedure EPrimary(Var ResultValue:RexxValue);
Var Q:Char;S,Nm:String;N:Real;C,J,MinimumLength,LocalInvokeCount:Integer;
 FunctionByte:Byte;A,B,D,E:RexxValue;
 LocalInvokeArgs:Array[1..MaxRoutineArgs]of String;
Begin
 ESkip;
 If ExprPos>Length(ExprText)Then Begin
  RVText('',ResultValue);
  Exit;
 End;
 If ExprText[ExprPos]in['''','"']Then Begin
  Q:=ExprText[ExprPos];
  Inc(ExprPos);S:='';
  While(ExprPos<=Length(ExprText))and(ExprText[ExprPos]<>Q)do Begin
   S:=S+ExprText[ExprPos];
   Inc(ExprPos);
  End;
  If ExprPos<=Length(ExprText)Then Inc(ExprPos);
  RVText(S,ResultValue);
  Exit;
 End;
 If ExprText[ExprPos]='('Then Begin
  Inc(ExprPos);
  ECompare(ResultValue);
  ESkip;
  If(ExprPos<=Length(ExprText))and(ExprText[ExprPos]=')')Then Inc(ExprPos);
  Exit;
 End;
 If ExprText[ExprPos]='-'Then Begin Inc(ExprPos);EPrimary(A);RVNum(-A.Number,ResultValue);Exit;End;
 If ExprText[ExprPos]in['0'..'9','.']Then Begin
  S:='';
  While(ExprPos<=Length(ExprText))and(ExprText[ExprPos]in['0'..'9','.'])do Begin
   S:=S+ExprText[ExprPos];
   Inc(ExprPos);
  End;
  Val(S,N,C);
  If C<>0Then N:=0;
  RVNum(N,ResultValue);
  Exit;
 End;
 Nm:='';
 While(ExprPos<=Length(ExprText))and(ExprText[ExprPos]in['A'..'Z','a'..'z','0'..'9','_','.'])do Begin
  Nm:=Nm+ExprText[ExprPos];
  Inc(ExprPos);
 End;
 ESkip;
 If(ExprPos<=Length(ExprText))and(ExprText[ExprPos]='(')Then Begin
  Inc(ExprPos);LocalInvokeCount:=0;ESkip;
  While(ExprPos<=Length(ExprText))and(ExprText[ExprPos]<>')')and(LocalInvokeCount<MaxRoutineArgs)do Begin
   ECompare(A);Inc(LocalInvokeCount);LocalInvokeArgs[LocalInvokeCount]:=A.Text;ESkip;
   If(ExprPos<=Length(ExprText))and(ExprText[ExprPos]=',')Then Begin Inc(ExprPos);ESkip;End Else Break;
  End;
  If ExprPos<=Length(ExprText)Then If ExprText[ExprPos]=')'Then Inc(ExprPos);
  InvokeArgCount:=LocalInvokeCount;
  For J:=1 To InvokeArgCount Do InvokeArgs[J]:=LocalInvokeArgs[J];
  If InvokeArgCount>0Then RVText(InvokeArgs[1],A)Else RVText('',A);
  If InvokeArgCount>1Then RVText(InvokeArgs[2],B)Else RVText('',B);
  If InvokeArgCount>2Then RVText(InvokeArgs[3],D)Else RVText('',D);
  If InvokeArgCount>3Then RVText(InvokeArgs[4],E)Else RVText('',E);
  Nm:=StrToUpper(Nm);
  C:=CommandIndex(Nm);If C<0Then FunctionByte:=255 Else FunctionByte:=Byte(C);
  Case FunctionByte Of
   0:Begin { ABBREV }
    If InvokeArgCount>2Then MinimumLength:=System.Trunc(D.Number)
     Else MinimumLength:=Length(B.Text);
    If MinimumLength<0Then MinimumLength:=0;
    If(Length(B.Text)>=MinimumLength)and(Length(B.Text)<=Length(A.Text))and
      (Copy(A.Text,1,Length(B.Text))=B.Text)Then RVNum(1,ResultValue)
     Else RVNum(0,ResultValue);
   End;
   1:RVNum(Abs(A.Number),ResultValue); { ABS }
   2:RVText(CurrentAddress,ResultValue); { ADDRESS }
   3:Begin { ARG }
    If InvokeArgCount=0Then RVNum(CurrentArgCount,ResultValue)
    Else Begin
     J:=System.Trunc(A.Number);
     If InvokeArgCount=1Then Begin
      If(J>=1)and(J<=CurrentArgCount)Then RVText(CurrentArgs[J],ResultValue)Else RVText('',ResultValue);
     End Else Begin
      S:=StrToUpper(B.Text);
      If S='E'Then Begin If(J>=1)and(J<=CurrentArgCount)Then RVNum(1,ResultValue)Else RVNum(0,ResultValue);End
      Else If S='O'Then Begin If(J<1)or(J>CurrentArgCount)Then RVNum(1,ResultValue)Else RVNum(0,ResultValue);End
      Else RVText('',ResultValue);
     End;
    End;
   End;
   4:RVText(BinaryToHex(A.Text),ResultValue); { B2X }
   5:Begin { BEEP }
    If InvokeArgCount=0Then BeepSound(800,200,ResultValue)
    Else If InvokeArgCount=1Then BeepSound(System.Trunc(A.Number),200,ResultValue)
    Else BeepSound(System.Trunc(A.Number),System.Trunc(B.Number),ResultValue);
   End;
   6:RVText(BitAndText(A.Text,B.Text,D.Text,InvokeArgCount>2),ResultValue); { BITAND }
   7:RVText(BitOrText(A.Text,B.Text,D.Text,InvokeArgCount>2),ResultValue); { BITOR }
   8:RVText(BitXorText(A.Text,B.Text,D.Text,InvokeArgCount>2),ResultValue); { BITXOR }
   9:Begin { CALL }
    { Forme fonctionnelle pratique: CALL('routine',arg1,...). Le premier
      argument est le nom et les suivants deviennent les arguments REXX. }
    S:=A.Text;
    If InvokeArgCount>0Then Begin
     For J:=1 To InvokeArgCount-1 Do InvokeArgs[J]:=InvokeArgs[J+1];
     Dec(InvokeArgCount);
    End;
    RVText(CallRoutine(S),ResultValue);
   End;
   10:RVText(CenterText(A.Text,System.Trunc(B.Number),D.Text),ResultValue); { CENTER }
   11:RVText(ChangeString(A.Text,B.Text,D.Text),ResultValue); { CHANGESTR }
   12:CharInValue(A.Text,System.Trunc(B.Number),System.Trunc(D.Number),
    InvokeArgCount>1,InvokeArgCount>2,ResultValue); { CHARIN }
   13:CharOutValue(A.Text,B.Text,System.Trunc(D.Number),InvokeArgCount>2,ResultValue); { CHAROUT }
   14:CharsValue(A.Text,ResultValue); { CHARS }
   15:RVNum(CompareText(A.Text,B.Text,D.Text),ResultValue); { COMPARE }
   16:ConditionValue(A.Text,ResultValue); { CONDITION }
   17:RVText(CopiesText(A.Text,System.Trunc(B.Number)),ResultValue); { COPIES }
   18:RVNum(CountStringOccurrences(A.Text,B.Text),ResultValue); { COUNTSTR }
   19:CharacterToDecimal(A.Text,System.Trunc(B.Number),InvokeArgCount>1,
    ResultValue); { C2D }
   20:RVText(CharacterToHex(A.Text),ResultValue); { C2X }
   21:DataTypeValue(A.Text,B.Text,InvokeArgCount>1,ResultValue); { DATATYPE }
   22:DateValue(A.Text,ResultValue); { DATE }
   23:RVText(DeleteStringPart(A.Text,System.Trunc(B.Number),
    System.Trunc(D.Number),InvokeArgCount>2),ResultValue); { DELSTR }
   24:RVText(DeleteWords(A.Text,System.Trunc(B.Number),System.Trunc(D.Number),
    InvokeArgCount>2),ResultValue); { DELWORD }
   25:RVNum(NumericDigitsValue,ResultValue); { DIGITS }
   26:DirectoryValue(A.Text,InvokeArgCount>0,ResultValue); { DIRECTORY }
   27:RVText(DecimalToCharacter(System.Trunc(A.Number),System.Trunc(B.Number),
    InvokeArgCount>1),ResultValue); { D2C }
   28:RVText(DecimalToHex(System.Trunc(A.Number),System.Trunc(B.Number),
    InvokeArgCount>1),ResultValue); { D2X }
   29:EndLocalValue(ResultValue); { ENDLOCAL }
   30:RVText(RexxErrorText(System.Trunc(A.Number)),ResultValue); { ERRORTEXT }
   31:RequestProgramExit(A,InvokeArgCount>0,ResultValue); { EXIT }
   32:RVText(FileSpecPart(A.Text,B.Text),ResultValue); { FILESPEC }
   33:RVText(NumericFormValue,ResultValue); { FORM }
   34:RVText(FormatRexxNumber(A.Number,A.Text,InvokeArgs[2],InvokeArgs[3],
    InvokeArgs[4],InvokeArgs[5],InvokeArgCount),ResultValue); { FORMAT }
   35:RVNum(NumericFuzzValue,ResultValue); { FUZZ }
   36:Begin { IF, forme fonctionnelle du repartiteur interne }
    If Truth(A)Then RVNum(1,ResultValue)Else RVNum(0,ResultValue);
   End;
   37:RVText(InsertText(A.Text,B.Text,System.Trunc(D.Number),
    System.Trunc(E.Number),InvokeArgCount>2,
    InvokeArgCount>3,InvokeArgCount>4,InvokeArgs[5]),ResultValue); { INSERT }
   38:RVNum(LastPosition(A.Text,B.Text,System.Trunc(D.Number),
    InvokeArgCount>2),ResultValue); { LASTPOS }
   39:RVText(Copy(A.Text,1,System.Trunc(B.Number)),ResultValue); { LEFT }
   40:RVNum(Length(A.Text),ResultValue); { LENGTH }
   41:LineInValue(A.Text,System.Trunc(B.Number),System.Trunc(D.Number),
    InvokeArgCount>1,InvokeArgCount>2,ResultValue); { LINEIN }
   42:LineOutValue(A.Text,B.Text,System.Trunc(D.Number),InvokeArgCount>1,
    InvokeArgCount>2,ResultValue); { LINEOUT }
   43:LinesValue(A.Text,ResultValue); { LINES }
   44:Begin { MAX }
    If A.Number>B.Number Then N:=A.Number Else N:=B.Number;RVNum(N,ResultValue);
   End;
   45:Begin { MIN }
    If A.Number<B.Number Then N:=A.Number Else N:=B.Number;RVNum(N,ResultValue);
   End;
   46:FunctionNotImplemented(FunctionByte,ResultValue); { OPTIONS }
   47:RVText(OverlayText(A.Text,B.Text,System.Trunc(D.Number),
    System.Trunc(E.Number),InvokeArgCount>2,InvokeArgCount>3,
    InvokeArgCount>4,InvokeArgs[5]),ResultValue); { OVERLAY }
   48:FunctionNotImplemented(FunctionByte,ResultValue); { PARSE }
   49:FunctionNotImplemented(FunctionByte,ResultValue); { PROCEDURE }
   50:RVNum(ForwardPosition(A.Text,B.Text,System.Trunc(D.Number),
    InvokeArgCount>2),ResultValue); { POS }
   51:FunctionNotImplemented(FunctionByte,ResultValue); { PULL }
   52:FunctionNotImplemented(FunctionByte,ResultValue); { PUSH }
   53:FunctionNotImplemented(FunctionByte,ResultValue); { QUEUE }
   54:RVNum(RexxQueueCount,ResultValue); { QUEUED }
   55:RandomValue(A,B,D,InvokeArgCount,ResultValue); { RANDOM }
   56:FunctionNotImplemented(FunctionByte,ResultValue); { RETURN }
   57:RVText(ReverseText(A.Text),ResultValue); { REVERSE }
   58:Begin { RIGHT }
    J:=Length(A.Text)-System.Trunc(B.Number)+1;If J<1Then J:=1;RVText(Copy(A.Text,J,255),ResultValue);
   End;
   59:FunctionNotImplemented(FunctionByte,ResultValue); { RXFUNCADD }
   60:FunctionNotImplemented(FunctionByte,ResultValue); { RXFUNCDROP }
   61:FunctionNotImplemented(FunctionByte,ResultValue); { RXFUNCQUERY }
   62:FunctionNotImplemented(FunctionByte,ResultValue); { RXMESSAGEBOX }
   63:FunctionNotImplemented(FunctionByte,ResultValue); { RXQUEUE }
   64:FunctionNotImplemented(FunctionByte,ResultValue); { RXWINEXEC }
   65:FunctionNotImplemented(FunctionByte,ResultValue); { SAY }
   66:FunctionNotImplemented(FunctionByte,ResultValue); { SELECT }
   67:SetLocalValue(ResultValue); { SETLOCAL }
   68:Begin { SIGN }
    If A.Number<0Then N:=-1 Else If A.Number>0Then N:=1 Else N:=0;RVNum(N,ResultValue);
   End;
   69:SourceLineValue(System.Trunc(A.Number),InvokeArgCount>0,
    ResultValue); { SOURCELINE }
   70:RVText(SpaceText(A.Text,System.Trunc(B.Number),InvokeArgCount>1,
    InvokeArgCount>2,D.Text),ResultValue); { SPACE }
   71:StreamValue(A.Text,B.Text,D.Text,InvokeArgCount,ResultValue); { STREAM }
   72:RVText(StripText(A.Text,B.Text,D.Text,InvokeArgCount>1,
    InvokeArgCount>2),ResultValue); { STRIP }
   73:RVText(SubStringText(A.Text,System.Trunc(B.Number),
    System.Trunc(D.Number),InvokeArgCount>2,InvokeArgCount>3,E.Text),
    ResultValue); { SUBSTR }
   74:RVText(SubWordText(A.Text,System.Trunc(B.Number),
    System.Trunc(D.Number),InvokeArgCount>2),ResultValue); { SUBWORD }
   75:SymbolValue(A.Text,ResultValue); { SYMBOL }
   76:FunctionNotImplemented(FunctionByte,ResultValue); { SYSADDREXXMACRO }
   77:FunctionNotImplemented(FunctionByte,ResultValue); { SYSBOOTDRIVE }
   78:FunctionNotImplemented(FunctionByte,ResultValue); { SYSCLEARREXXMACROSPACE }
   79:FunctionNotImplemented(FunctionByte,ResultValue); { SYSCLOSEEVENTSEM }
   80:FunctionNotImplemented(FunctionByte,ResultValue); { SYSCLOSEMUTEXSEM }
   81:SysClearScreen(InvokeArgCount,ResultValue); { SYSCLS }
   82:FunctionNotImplemented(FunctionByte,ResultValue); { SYSCREATEEVENTSEM }
   83:FunctionNotImplemented(FunctionByte,ResultValue); { SYSCREATEMUTEXSEM }
   84:FunctionNotImplemented(FunctionByte,ResultValue); { SYSCREATEOBJECT }
   85:SysCursorPosition(A,B,InvokeArgCount,ResultValue); { SYSCURPOS }
   86:FunctionNotImplemented(FunctionByte,ResultValue); { SYSCURSTATE }
   87:FunctionNotImplemented(FunctionByte,ResultValue); { SYSDEREGISTEROBJECTCLASS }
   88:FunctionNotImplemented(FunctionByte,ResultValue); { SYSDESTROYOBJECT }
   89:FunctionNotImplemented(FunctionByte,ResultValue); { SYSDRIVEINFO }
   90:FunctionNotImplemented(FunctionByte,ResultValue); { SYSDRIVEMAP }
   91:FunctionNotImplemented(FunctionByte,ResultValue); { SYSDROPFUNCS }
   92:FunctionNotImplemented(FunctionByte,ResultValue); { SYSDROPREXXMACRO }
   93:SysDeleteFile(A.Text,ResultValue); { SYSFILEDELETE }
   94:FunctionNotImplemented(FunctionByte,ResultValue); { SYSFILETREE }
   95:SysSearchFile(A.Text,B.Text,D.Text,E.Text,InvokeArgCount,
    ResultValue); { SYSFILESEARCH }
   96:FunctionNotImplemented(FunctionByte,ResultValue); { SYSFILESYSTEMTYPE }
   97:FunctionNotImplemented(FunctionByte,ResultValue); { SYSGETEA }
   98:SysGetKeyValue(A.Text,B.Number,InvokeArgCount,ResultValue); { SYSGETKEY }
   99:FunctionNotImplemented(FunctionByte,ResultValue); { SYSGETMESSAGE }
   100:FunctionNotImplemented(FunctionByte,ResultValue); { SYSINI }
   101:FunctionNotImplemented(FunctionByte,ResultValue); { SYSLOADFUNCS }
   102:FunctionNotImplemented(FunctionByte,ResultValue); { SYSLOADREXXMACROSPACE }
   103:SysMakeDirectory(A.Text,ResultValue); { SYSMKDIR }
   104:FunctionNotImplemented(FunctionByte,ResultValue); { SYSOPENEVENTSEM }
   105:FunctionNotImplemented(FunctionByte,ResultValue); { SYSOPENMUTEXSEM }
   106:FunctionNotImplemented(FunctionByte,ResultValue); { SYSOS2VER }
   107:FunctionNotImplemented(FunctionByte,ResultValue); { SYSPOSTEVENTSEM }
   108:FunctionNotImplemented(FunctionByte,ResultValue); { SYSPULSEEVENTSEM }
   109:FunctionNotImplemented(FunctionByte,ResultValue); { SYSPUTEA }
   110:FunctionNotImplemented(FunctionByte,ResultValue); { SYSQUERYCLASSLIST }
   111:FunctionNotImplemented(FunctionByte,ResultValue); { SYSQUERYREXXMACRO }
   112:FunctionNotImplemented(FunctionByte,ResultValue); { SYSREGISTEROBJECTCLASS }
   113:FunctionNotImplemented(FunctionByte,ResultValue); { SYSRELEASEMUTEXSEM }
   114:FunctionNotImplemented(FunctionByte,ResultValue); { SYSREORDERREXXMACRO }
   115:FunctionNotImplemented(FunctionByte,ResultValue); { SYSREQUESTMUTEXSEM }
   116:FunctionNotImplemented(FunctionByte,ResultValue); { SYSRESETEVENTSEM }
   117:SysRemoveDirectory(A.Text,ResultValue); { SYSRMDIR }
   118:FunctionNotImplemented(FunctionByte,ResultValue); { SYSSAVEREXXMACROSPACE }
   119:FunctionNotImplemented(FunctionByte,ResultValue); { SYSSEARCHPATH }
   120:FunctionNotImplemented(FunctionByte,ResultValue); { SYSSETICON }
   121:FunctionNotImplemented(FunctionByte,ResultValue); { SYSSETOBJECTDATA }
   122:FunctionNotImplemented(FunctionByte,ResultValue); { SYSSETPRIORITY }
   123:SysSleepValue(A.Number,InvokeArgCount>0,ResultValue); { SYSSLEEP }
   124:FunctionNotImplemented(FunctionByte,ResultValue); { SYSSWITCHSESSION }
   125:FunctionNotImplemented(FunctionByte,ResultValue); { SYSSYSTEMDIRECTORY }
   126:FunctionNotImplemented(FunctionByte,ResultValue); { SYSTEMPFILENAME }
   127:FunctionNotImplemented(FunctionByte,ResultValue); { SYSTEXTSCREENREAD }
   128:FunctionNotImplemented(FunctionByte,ResultValue); { SYSTEXTSCREENSIZE }
   129:SysVolumeLabelValue(A.Text,ResultValue); { SYSVOLUMELABEL }
   130:FunctionNotImplemented(FunctionByte,ResultValue); { SYSWAITEVENTSEM }
   131:FunctionNotImplemented(FunctionByte,ResultValue); { SYSWAITNAMEDPIPE }
   132:FunctionNotImplemented(FunctionByte,ResultValue); { SYSWINVER }
   133:FunctionNotImplemented(FunctionByte,ResultValue); { THEN }
   134:TimeValue(A.Text,InvokeArgCount,ResultValue); { TIME }
   135:TraceValue(A.Text,InvokeArgCount,ResultValue); { TRACE }
   136:RVText(TranslateText(A.Text,B.Text,D.Text,E.Text,InvokeArgCount),
    ResultValue); { TRANSLATE }
   137:RVNum(System.Trunc(A.Number),ResultValue); { TRUNC }
   138:ValueFunction(A.Text,B.Text,D.Text,InvokeArgCount,ResultValue); { VALUE }
   139:FunctionNotImplemented(FunctionByte,ResultValue); { VAR }
   140:RVNum(VerifyText(A.Text,B.Text,D.Text,System.Trunc(E.Number),
    InvokeArgCount>2,InvokeArgCount>3),ResultValue); { VERIFY }
   141:RVText(SubWordText(A.Text,System.Trunc(B.Number),1,True),
    ResultValue); { WORD }
   142:RVNum(WordStartIndex(A.Text,System.Trunc(B.Number)),
    ResultValue); { WORDINDEX }
   143:RVNum(Length(SubWordText(A.Text,System.Trunc(B.Number),1,True)),
    ResultValue); { WORDLENGTH }
   144:RVNum(WordPhrasePosition(A.Text,B.Text,System.Trunc(D.Number),
    InvokeArgCount>2),ResultValue); { WORDPOS }
   145:RVNum(CountWords(A.Text),ResultValue); { WORDS }
   146:RVText(XRangeText(A.Text,B.Text,InvokeArgCount),ResultValue); { XRANGE }
   147:RVText(HexToBinary(A.Text),ResultValue); { X2B }
   148:RVText(HexToCharacter(A.Text),ResultValue); { X2C }
   149:HexToDecimal(A.Text,System.Trunc(B.Number),InvokeArgCount>1,
    ResultValue); { X2D }
   150:FunctionNotImplemented(FunctionByte,ResultValue); { DO }
   151:FunctionNotImplemented(FunctionByte,ResultValue); { ELSE }
   152:FunctionNotImplemented(FunctionByte,ResultValue); { END }
   153:FunctionNotImplemented(FunctionByte,ResultValue); { EXPOSE }
   154:FunctionNotImplemented(FunctionByte,ResultValue); { ITERATE }
   155:FunctionNotImplemented(FunctionByte,ResultValue); { LEAVE }
   156:FunctionNotImplemented(FunctionByte,ResultValue); { NAME }
   157:FunctionNotImplemented(FunctionByte,ResultValue); { NOP }
   158:FunctionNotImplemented(FunctionByte,ResultValue); { NUMERIC }
   159:FunctionNotImplemented(FunctionByte,ResultValue); { OTHERWISE }
   160:FunctionNotImplemented(FunctionByte,ResultValue); { SIGNAL }
   161:FunctionNotImplemented(FunctionByte,ResultValue); { WHEN }
   Else If FindRoutineLabel(Nm)>0Then RVText(CallRoutine(Nm),ResultValue)
    Else RVText(Nm,ResultValue);
  End;
  Exit;
 End;
 VarGet(Nm,ResultValue);
End;

Procedure EPower(Var ResultValue:RexxValue);
Var
 A,B:RexxValue;
 J:Integer;
 N:Real;
Begin
 EPrimary(A);
 ESkip;
 While Copy(ExprText,ExprPos,2)='**'do Begin
  Inc(ExprPos,2);
  EPrimary(B);N:=1;
  For J:=1To System.Trunc(B.Number)do N:=N*A.Number;RVNum(N,A);
  ESkip;
 End;
 ResultValue:=A;
End;

Procedure EMul(Var ResultValue:RexxValue);
Var A,B:RexxValue;Op:String[2];
Begin
 EPower(A);
 While True Do Begin
  ESkip;Op:='';
  If Copy(ExprText,ExprPos,2)='//'Then Begin
   Op:='//';
   Inc(ExprPos,2);
  End
   Else
  If(ExprPos<=Length(ExprText))and(ExprText[ExprPos]in['*','/','%'])Then Begin
   Op:=ExprText[ExprPos];
   Inc(ExprPos);
  End;
  If Op=''Then Break;
  EPower(B);
  If Op='*'Then RVNum(A.Number*B.Number,A)Else
  If(Op='/')and(B.Number<>0)Then RVNum(A.Number/B.Number,A)Else
  If(Op='%')and(B.Number<>0)Then RVNum(System.Trunc(A.Number/B.Number),A)Else
  If(Op='//')and(B.Number<>0)Then RVNum(System.Trunc(A.Number)mod
System.Trunc(B.Number),A)Else RVNum(0,A);
 End;
 ResultValue:=A;
End;

Procedure EAdd(Var ResultValue:RexxValue);
Var A,B:RexxValue;O:Char;
Begin
 EMul(A);
 While True Do Begin
  ESkip;
  If(ExprPos>Length(ExprText))or Not(ExprText[ExprPos]in['+','-'])Then Break;
  O:=ExprText[ExprPos];Inc(ExprPos);
  EMul(B);
  If O='+'Then RVNum(A.Number+B.Number,A)
          Else RVNum(A.Number-B.Number,A);
 End;
 ResultValue:=A;
End;

Procedure ECompare(Var ResultValue:RexxValue);
Var A,B:RexxValue;O:String[2];T:Boolean;
Begin
 EAdd(A);ESkip;O:='';If Copy(ExprText,ExprPos,2)='>='Then O:='>=' Else
 If Copy(ExprText,ExprPos,2)='<='Then O:='<='Else
 If Copy(ExprText,ExprPos,2)='<>'Then O:='<>'Else
 If(ExprPos<=Length(ExprText))and(ExprText[ExprPos]in['=','>','<'])Then O:=ExprText[ExprPos];
 If O<>''Then Begin
  Inc(ExprPos,Length(O));EAdd(B);
  If A.IsNumber and B.IsNumber Then Begin
   If O='='Then T:=A.Number=B.Number Else
   If O='<>'Then T:=A.Number<>B.Number Else
   If O='>'Then T:=A.Number>B.Number Else
   If O='<'Then T:=A.Number<B.Number Else
   If O='>='Then T:=A.Number>=B.Number
            Else T:=A.Number<=B.Number;
  End
   Else
  Begin
   If O='='Then T:=StrToUpper(A.Text)=StrToUpper(B.Text) Else
   If O='<>'Then T:=StrToUpper(A.Text)<>StrToUpper(B.Text) Else
   If O='>'Then T:=StrToUpper(A.Text)>StrToUpper(B.Text)Else
   If O='<'Then T:=StrToUpper(A.Text)<StrToUpper(B.Text)Else
   If O='>='Then T:=StrToUpper(A.Text)>=StrToUpper(B.Text)
            Else T:=StrToUpper(A.Text)<=StrToUpper(B.Text);
  End;
  If T Then RVNum(1,A)Else
            RVNum(0,A);
  End;
  ResultValue:=A;
End;

Procedure Eval(S:String;Var ResultValue:RexxValue);
Var A,B:RexxValue;Tight:Boolean;
Begin
 ExprText:=S;ExprPos:=1;ECompare(A);
 While ExprPos<=Length(ExprText)do Begin
  ESkip;
  If ExprPos>Length(ExprText)Then Break;
  Tight:=Copy(ExprText,ExprPos,2)='||';
  If Tight Then Inc(ExprPos,2);
  ECompare(B);
  If Tight Then RVText(A.Text+B.Text,A)
           Else RVText(A.Text+' '+B.Text,A);
 End;
 ResultValue:=A;
End;

Function Truth(V:RexxValue):Boolean;Begin If V.IsNumber Then Truth:=V.Number<>0 Else Truth:=(V.Text<>'')and(V.Text<>'0');End;
Function CommandIndex(N:String):Integer;
Var J:Integer;
Begin
 CommandIndex:=-1;N:=StrToUpper(Clean(N));
 For J:=Low(CommandList)To High(CommandList)Do
  If N=CommandList[J]Then Begin CommandIndex:=J;Exit;End;
End;

Function WordStart(S,W:String):Boolean;
Var
 U,FirstWord:String;P:Integer;
Begin
 U:=StrToUpper(Clean(S));
 W:=StrToUpper(W);
 P:=System.Pos(' ',W);If P=0Then FirstWord:=W Else FirstWord:=Copy(W,1,P-1);
 { Toute reconnaissance d'instruction passe par CommandList. Les mots qui
   n'y figurent pas ne peuvent donc pas etre pris accidentellement pour une
   commande REXX. }
 WordStart:=(CommandIndex(FirstWord)>=0)and(Copy(U,1,Length(W))=W)and
  ((Length(U)=Length(W))or(U[Length(W)+1]in[' ',#9]));
End;

Function ClauseStart(S,W:String):Boolean;
Var U:String;
Begin
 U:=StrToUpper(Clean(S));W:=StrToUpper(W);
 ClauseStart:=(Copy(U,1,Length(W))=W)and
  ((Length(U)=Length(W))or(U[Length(W)+1]in[' ',#9]));
End;

Function FindWord(S,W:String):Integer;
Var
 J,D:Integer;
 Q:Char;
 U:String;
Begin
 U:=StrToUpper(S);
 W:=StrToUpper(W);
 J:=1;D:=0;Q:=#0;FindWord:=0;
 While J<=Length(S)-Length(W)+1 Do Begin
  If Q<>#0 Then Begin
   If S[J]=Q Then Q:=#0;Inc(J);
  End
   Else
  If S[J]in['''','"']Then Begin
   Q:=S[J];Inc(J);
  End
   Else
  Begin
   If S[J]='('Then Inc(D)Else
   If S[J]=')'Then Dec(D);
   If(D=0)and(Copy(U,J,Length(W))=W)and((J=1)or(S[J-1]in[' ',#9]))and
     ((J+Length(W)>Length(S))or(S[J+Length(W)]in[' ',#9]))Then Begin
    FindWord:=J;
    Exit;
   End;
   Inc(J);
  End;
 End;
End;

Function BlockEnd(A,Z:Integer):Integer;
Var
 J,D:Integer;U:String;
Begin
 D:=1;J:=A;
 While J<=Z Do Begin
  U:=StrToUpper(Clean(PA[J]^));
  If WordStart(U,'DO')or WordStart(U,'SELECT')or
    (System.Pos(' THEN DO',U)>0)or WordStart(U,'ELSE DO')or
    WordStart(U,'OTHERWISE DO')Then Inc(D);
  If WordStart(U,'END')Then Begin
   Dec(D);
   If D=0Then Begin
    BlockEnd:=J;
    Exit;
   End;
  End;
  Inc(J);
 End;
 BlockEnd:=Z;
End;

Var
 LoopSignal:Byte;

Procedure ExecRange(A,Z:Integer);Forward;

Procedure ParseTemplate(Value,Template:String;MakeUpper:Boolean);
Const MaxParseTokens=64;
Var
 Tokens:Array[1..MaxParseTokens]of String;
 LiteralToken:Array[1..MaxParseTokens]of Boolean;
 TokenCount,J,K,P,CursorPos,EndPos,Code,AbsolutePos:Integer;
 Q:Char;Token,Piece:String;IsNumber:Boolean;
Begin
 If MakeUpper Then Value:=StrToUpper(Value);
 TokenCount:=0;J:=1;
 While(J<=Length(Template))and(TokenCount<MaxParseTokens)Do Begin
  While(J<=Length(Template))and(Template[J]in[' ',#9])Do Inc(J);
  If J>Length(Template)Then Break;
  Inc(TokenCount);LiteralToken[TokenCount]:=False;Token:='';
  If Template[J]in['''','"']Then Begin
   Q:=Template[J];Inc(J);LiteralToken[TokenCount]:=True;
   While(J<=Length(Template))and(Template[J]<>Q)Do Begin Token:=Token+Template[J];Inc(J);End;
   If(J<=Length(Template))and(Template[J]=Q)Then Inc(J);
  End Else
   While(J<=Length(Template))and Not(Template[J]in[' ',#9])Do Begin Token:=Token+Template[J];Inc(J);End;
  Tokens[TokenCount]:=Token;
 End;

 CursorPos:=1;J:=1;
 While J<=TokenCount Do Begin
  Token:=Tokens[J];IsNumber:=Token<>'';
  For K:=1 To Length(Token)Do If Not(Token[K]in['0'..'9'])Then IsNumber:=False;
  If LiteralToken[J] Then Begin
   P:=System.Pos(Token,Copy(Value,CursorPos,255));
   If P>0Then CursorPos:=CursorPos+P-1+Length(Token)Else CursorPos:=Length(Value)+1;
   Inc(J);Continue;
  End;
  If IsNumber Then Begin Val(Token,AbsolutePos,Code);CursorPos:=AbsolutePos;Inc(J);Continue;End;

  { Une variable est delimitee par le prochain litteral ou la prochaine
    position. Entre deux variables, elle recoit un mot; la derniere recoit
    tout le reste, conformement aux modeles PARSE de REXX. }
  If J=TokenCount Then Begin Piece:=Clean(Copy(Value,CursorPos,255));CursorPos:=Length(Value)+1;End
  Else If LiteralToken[J+1]Then Begin
   P:=System.Pos(Tokens[J+1],Copy(Value,CursorPos,255));
   If P>0Then Begin Piece:=Clean(Copy(Value,CursorPos,P-1));CursorPos:=CursorPos+P-1+Length(Tokens[J+1]);End
    Else Begin Piece:=Clean(Copy(Value,CursorPos,255));CursorPos:=Length(Value)+1;End;
   Inc(J);
  End Else Begin
   IsNumber:=Tokens[J+1]<>'';
   For K:=1 To Length(Tokens[J+1])Do If Not(Tokens[J+1][K]in['0'..'9'])Then IsNumber:=False;
   If IsNumber Then Begin
    Val(Tokens[J+1],AbsolutePos,Code);EndPos:=AbsolutePos-1;
    If EndPos<CursorPos Then Piece:=''Else Piece:=Clean(Copy(Value,CursorPos,EndPos-CursorPos+1));
    CursorPos:=AbsolutePos;Inc(J);
   End Else Begin
    While(CursorPos<=Length(Value))and(Value[CursorPos]in[' ',#9])Do Inc(CursorPos);
    EndPos:=CursorPos;While(EndPos<=Length(Value))and Not(Value[EndPos]in[' ',#9])Do Inc(EndPos);
    Piece:=Copy(Value,CursorPos,EndPos-CursorPos);CursorPos:=EndPos;
   End;
  End;
  If Token<>'.'Then VarSet(Token,Piece);
  Inc(J);
 End;
End;

Procedure RunAddressCommand(EnvironmentName,CommandText:String);
Var CommandProcessor:String;
Begin
 If CommandText=''Then Exit;
 If CurrentTraceSetting='C'Then WriteLn('+++ ',CommandText);
 EnvironmentName:=StrToUpper(Clean(EnvironmentName));
 If(EnvironmentName='SYSTEM')or(EnvironmentName='COMMAND')or(EnvironmentName='CMD')Then Begin
  CommandProcessor:=GetEnv('COMSPEC');If CommandProcessor=''Then CommandProcessor:='CMD.EXE';
  Exec(CommandProcessor,'/C '+CommandText);
  If DosError<>0Then WriteLn('Erreur ADDRESS ',EnvironmentName,': ',DosError);
 End Else WriteLn('Environnement ADDRESS non supporte: ',EnvironmentName);
End;

Procedure ExecOne(S:String);
Var P,J:Integer;V:RexxValue;Name,Rest,ArgName,FirstWord,CommandText,OldAddress,
 SourceText,Template:String;Found,MakeUpper:Boolean;CommandByte:Byte;
Begin
 S:=Clean(S);If S=''Then Exit;
 P:=1;While(P<=Length(S))and(S[P]in['A'..'Z','a'..'z','_'])Do Inc(P);
 FirstWord:=Copy(S,1,P-1);J:=CommandIndex(FirstWord);
 If J<0Then CommandByte:=255 Else CommandByte:=Byte(J);
 Case CommandByte Of
  2:Begin { ADDRESS }
   Rest:=Clean(Copy(S,8,255));
   If Rest=''Then Begin
    OldAddress:=CurrentAddress;CurrentAddress:=PreviousAddress;PreviousAddress:=OldAddress;
   End Else If ClauseStart(Rest,'VALUE')Then Begin
    Eval(Clean(Copy(Rest,6,255)),V);Name:=StrToUpper(V.Text);
    PreviousAddress:=CurrentAddress;CurrentAddress:=Name;
   End Else Begin
    P:=System.Pos(' ',Rest);
    If P=0Then Begin Name:=Rest;CommandText:='';End
     Else Begin Name:=Copy(Rest,1,P-1);CommandText:=Clean(Copy(Rest,P+1,255));End;
    Name:=StrToUpper(Name);PreviousAddress:=CurrentAddress;CurrentAddress:=Name;
    If CommandText<>''Then Begin Eval(CommandText,V);RunAddressCommand(CurrentAddress,V.Text);End;
   End;
  End;
  65:Begin { SAY }
   Eval(Copy(S,4,255),V);WriteLn(V.Text);
  End;
  9:Begin { CALL }
   Rest:=Clean(Copy(S,5,255));P:=System.Pos(' ',Rest);
   If P>0Then Begin Name:=Copy(Rest,1,P-1);Rest:=Clean(Copy(Rest,P+1,255));End Else Begin Name:=Rest;Rest:='';End;
   InvokeArgCount:=0;
   While(Rest<>'')and(InvokeArgCount<MaxRoutineArgs)do Begin
    P:=System.Pos(',',Rest);If P>0Then Begin
     Eval(Copy(Rest,1,P-1),V);
     Delete(Rest,1,P);
     Rest:=Clean(Rest);
    End
     Else
    Begin
     Eval(Rest,V);
     Rest:='';
    End;
    Inc(InvokeArgCount);InvokeArgs[InvokeArgCount]:=V.Text;
   End;
   VarSet('RESULT',CallRoutine(Name));
  End;
  46:Begin { OPTIONS }
   Rest:=Clean(Copy(S,8,255));
   If Rest=''Then CurrentOptions:=''
   Else Begin
    Eval(Rest,V);
    CurrentOptions:=V.Text;
   End;
  End;
  51:Begin { PULL }
   PullQueue(Rest,Found);
   If Not Found Then ReadLn(Rest);
   ArgName:=Clean(Copy(S,5,255));
   If ArgName<>''Then ParseTemplate(Rest,ArgName,True);
  End;
  52:Begin { PUSH }
   Rest:=Clean(Copy(S,5,255));
   If Rest<>''Then Eval(Rest,V)Else RVText('',V);
   PushQueue(V.Text);
  End;
  53:Begin { QUEUE }
   Rest:=Clean(Copy(S,6,255));
   If Rest<>''Then Eval(Rest,V)Else RVText('',V);
   AppendQueue(V.Text);
  End;
  48:Begin { PARSE }
   Rest:=Clean(Copy(S,6,255));MakeUpper:=False;
   If ClauseStart(Rest,'UPPER')Then Begin
    MakeUpper:=True;Rest:=Clean(Copy(Rest,6,255));
   End;
   If ClauseStart(Rest,'ARG')Then Begin
    Rest:=Clean(Copy(Rest,4,255));J:=1;
    While Rest<>''Do Begin
     P:=System.Pos(',',Rest);
     If P>0Then Begin Template:=Clean(Copy(Rest,1,P-1));Delete(Rest,1,P);Rest:=Clean(Rest);End
      Else Begin Template:=Rest;Rest:='';End;
     If J<=CurrentArgCount Then SourceText:=CurrentArgs[J]Else SourceText:='';
     ParseTemplate(SourceText,Template,MakeUpper);Inc(J);
    End;
   End Else If ClauseStart(Rest,'VAR')Then Begin
    Rest:=Clean(Copy(Rest,4,255));P:=System.Pos(' ',Rest);
    If P>0Then Begin
     Name:=Copy(Rest,1,P-1);Template:=Clean(Copy(Rest,P+1,255));
     VarGet(Name,V);ParseTemplate(V.Text,Template,MakeUpper);
    End;
   End Else If ClauseStart(Rest,'VALUE')Then Begin
    Rest:=Clean(Copy(Rest,6,255));P:=FindWord(Rest,'WITH');
    If P>0Then Begin
     Eval(Clean(Copy(Rest,1,P-1)),V);Template:=Clean(Copy(Rest,P+4,255));
     ParseTemplate(V.Text,Template,MakeUpper);
    End;
   End Else If ClauseStart(Rest,'PULL')Then Begin
    Template:=Clean(Copy(Rest,5,255));PullQueue(SourceText,Found);
    If Not Found Then ReadLn(SourceText);
    ParseTemplate(SourceText,Template,MakeUpper);
   End Else If ClauseStart(Rest,'LINEIN')Then Begin
    Template:=Clean(Copy(Rest,7,255));ReadLn(SourceText);
    ParseTemplate(SourceText,Template,MakeUpper);
   End Else If ClauseStart(Rest,'VERSION')Then
    ParseTemplate('REXX-DEVCOOLS 1.0',Clean(Copy(Rest,8,255)),MakeUpper)
   Else If ClauseStart(Rest,'SOURCE')Then
    ParseTemplate('WINDOWS COMMAND '+FileName,Clean(Copy(Rest,7,255)),MakeUpper);
  End;
  56:Begin { RETURN }
   Rest:=Clean(Copy(S,7,255));
   If Rest<>''Then Eval(Rest,V)Else RVText('',V);
   If RoutineDepth>0Then Begin
    RoutineResult:=V.Text;
    RoutineReturning:=True;
   End
    Else
   RequestProgramExit(V,Rest<>'',V);
  End;
  49:; { PROCEDURE est traite lors de l'entree dans CallRoutine }
  135:Begin { TRACE }
   Rest:=Clean(Copy(S,6,255));
   If ClauseStart(Rest,'VALUE')Then Begin
    Eval(Clean(Copy(Rest,6,255)),V);
    CurrentTraceSetting:=NormalizeTraceSetting(V.Text);
   End Else CurrentTraceSetting:=NormalizeTraceSetting(Rest);
  End;
  158:Begin { NUMERIC }
   If WordStart(S,'NUMERIC DIGITS')Then Begin
    Rest:=Clean(Copy(S,15,255));If Rest=''Then NumericDigitsValue:=9
     Else Begin Eval(Rest,V);J:=System.Trunc(V.Number);If J>0Then NumericDigitsValue:=J;End;
    If NumericFuzzValue>=NumericDigitsValue Then NumericFuzzValue:=NumericDigitsValue-1;
   End Else If WordStart(S,'NUMERIC FUZZ')Then Begin
    Rest:=Clean(Copy(S,13,255));If Rest=''Then NumericFuzzValue:=0
     Else Begin Eval(Rest,V);J:=System.Trunc(V.Number);If(J>=0)and(J<NumericDigitsValue)Then NumericFuzzValue:=J;End;
   End Else If WordStart(S,'NUMERIC FORM')Then Begin
    Rest:=StrToUpper(Clean(Copy(S,13,255)));If Rest=''Then NumericFormValue:='SCIENTIFIC'
     Else If(Rest='SCIENTIFIC')or(Rest='ENGINEERING')Then NumericFormValue:=Rest;
   End;
  End;
  160:Begin { SIGNAL }
   If WordStart(S,'SIGNAL ON')Then Begin
    Rest:=Clean(Copy(S,10,255));P:=FindWord(Rest,'NAME');
    If P>0Then Begin Name:=StrToUpper(Clean(Copy(Rest,P+4,255)));Rest:=StrToUpper(Clean(Copy(Rest,1,P-1)));End
     Else Begin Rest:=StrToUpper(Rest);Name:=Rest;End;
    If Rest='HALT'Then Begin SignalHalt:=True;SignalHaltName:=Name;End
    Else If Rest='NOVALUE'Then Begin SignalNoValue:=True;SignalNoValueName:=Name;End
    Else If Rest='ERROR'Then Begin SignalError:=True;SignalErrorName:=Name;End
    Else If Rest='SYNTAX'Then Begin SignalSyntax:=True;SignalSyntaxName:=Name;End;
   End Else If WordStart(S,'SIGNAL OFF')Then Begin
    Rest:=StrToUpper(Clean(Copy(S,11,255)));If Rest='HALT'Then SignalHalt:=False
    Else If Rest='NOVALUE'Then SignalNoValue:=False Else If Rest='ERROR'Then SignalError:=False
    Else If Rest='SYNTAX'Then SignalSyntax:=False;
   End Else If WordStart(S,'SIGNAL VALUE')Then Begin
    Eval(Clean(Copy(S,13,255)),V);Name:=V.Text;SignalTargetLine:=FindRoutineLabel(Name);
   End Else Begin Name:=Clean(Copy(S,7,255));SignalTargetLine:=FindRoutineLabel(Name);End;
  End;
  157:; { NOP }
  155:LoopSignal:=1; { LEAVE }
  154:LoopSignal:=2; { ITERATE }
 31:Begin { EXIT }
   Rest:=Clean(Copy(S,5,255));
   If Rest<>''Then Begin Eval(Rest,V);RequestProgramExit(V,True,V);End
   Else Begin RVNum(0,V);RequestProgramExit(V,False,V);End;
  End;
  36:Begin { IF imbrique ou transmis comme clause simple }
   P:=FindWord(S,'THEN');
   If P=0Then WriteLn('THEN manquant')
   Else Begin
    Eval(Copy(S,3,P-3),V);Rest:=Clean(Copy(S,P+4,255));
    J:=FindWord(Rest,'ELSE');
    If J>0Then Begin
     If Truth(V)Then ExecOne(Clean(Copy(Rest,1,J-1)))
     Else ExecOne(Clean(Copy(Rest,J+4,255)));
    End Else If Truth(V)Then ExecOne(Rest);
   End;
  End;
  Else Begin
   If S[Length(S)]=':'Then Exit;
   P:=System.Pos('=',S);If P>1Then Begin Eval(Copy(S,P+1,255),V);VarSet(Copy(S,1,P-1),V.Text);End
    Else WriteLn('Commande non reconnue: ',S);
  End;
 End;
End;

Procedure ExecRange(A,Z:Integer);
Var
 J,P,E,K,ToPos,ByPos,EqPos,RepeatCount:Integer;
 S,C,Act,LoopVar:String;
 V:RexxValue;Done:Boolean;
 LoopValue,LoopEnd,LoopStep:Real;
Begin
 J:=A;
 While(J<=Z)and Not Terminated and Not RoutineReturning and(LoopSignal=0)do Begin
 S:=Clean(PA[J]^);
  If(S<>'')and(Copy(S,1,2)<>'/*')Then Begin
   If CurrentTraceSetting[1]in['A','I','R']Then WriteLn('+++ ',S)
   Else If(CurrentTraceSetting='L')and(Length(S)>0)and
    (S[Length(S)]=':')Then WriteLn('+++ ',S);
  End;
  If(S='')or(Copy(S,1,2)='/*')Then Inc(J) Else
  If WordStart(S,'IF')Then Begin
   P:=FindWord(S,'THEN');
   If P=0Then Begin
    WriteLn('THEN manquant ligne ',J);
    Inc(J);
   End
    Else
   Begin
    C:=Copy(S,3,P-3);
    Act:=Clean(Copy(S,P+4,255));
    Eval(C,V);
    If StrToUpper(Act)='DO'Then Begin
     E:=BlockEnd(J+1,Z);
     If Truth(V)Then ExecRange(J+1,E-1);J:=E+1;If(J<=Z)and WordStart(PA[J]^,'ELSE')Then Begin
      Act:=Clean(Copy(Clean(PA[J]^),5,255));If StrToUpper(Act)='DO'Then Begin
      E:=BlockEnd(J+1,Z);
      If Not Truth(V)Then ExecRange(J+1,E-1);
      J:=E+1;
     End
      Else
     Begin
      If Not Truth(V)Then ExecOne(Act);
      Inc(J);
     End;
    End;
   End
    Else
   Begin
    K:=FindWord(Act,'ELSE');
    If K>0Then Begin
     If Truth(V)Then ExecOne(Clean(Copy(Act,1,K-1)))
     Else ExecOne(Clean(Copy(Act,K+4,255)));
     Inc(J);
    End Else Begin
     If Truth(V)Then ExecOne(Act);
     Inc(J);
     If(J<=Z)and WordStart(PA[J]^,'ELSE')Then Begin
      If Not Truth(V)Then ExecOne(Copy(Clean(PA[J]^),5,255));
      Inc(J);
     End;
    End;
   End;
  End;
 End
  Else
 If WordStart(S,'SELECT')Then Begin
  E:=BlockEnd(J+1,Z);Done:=False;K:=J+1;
  While K<E Do Begin
   Act:=Clean(PA[K]^);
   If WordStart(Act,'WHEN')Then Begin
    P:=FindWord(Act,'THEN');
    If P=0Then Begin
     WriteLn('THEN manquant ligne ',K);
     Inc(K);
    End Else Begin
     C:=Clean(Copy(Act,P+4,255));
     If StrToUpper(C)='DO'Then Begin
      ToPos:=BlockEnd(K+1,E-1);
      If Not Done Then Begin
       Eval(Copy(Act,5,P-5),V);
       If Truth(V)Then Begin
        ExecRange(K+1,ToPos-1);
        Done:=True;
       End;
      End;
      K:=ToPos+1;
     End Else Begin
      If Not Done Then Begin
       Eval(Copy(Act,5,P-5),V);
       If Truth(V)Then Begin
        ExecOne(C);
        Done:=True;
       End;
      End;
      Inc(K);
     End;
    End;
   End Else If WordStart(Act,'OTHERWISE')Then Begin
    C:=Clean(Copy(Act,10,255));
    If StrToUpper(C)='DO'Then Begin
     ToPos:=BlockEnd(K+1,E-1);
     If Not Done Then Begin ExecRange(K+1,ToPos-1);Done:=True;End;
     K:=ToPos+1;
    End Else Begin
     If Not Done Then Begin ExecOne(C);Done:=True;End;
     Inc(K);
    End;
   End Else Inc(K);
  End;
  If Not Done Then WriteLn('WHEN ou OTHERWISE attendu ligne ',J);
  J:=E+1;
 End
  Else
 If WordStart(S,'DO WHILE')or WordStart(S,'DO UNTIL')Then Begin
  E:=BlockEnd(J+1,Z);
  C:=Copy(S,9,255);
  Repeat
   Eval(C,V);
   If WordStart(S,'DO WHILE')Then Begin
    If Not Truth(V)Then Break;
   End
    Else
   If Truth(V)Then Break;
   LoopSignal:=0;ExecRange(J+1,E-1);
   If LoopSignal=1Then Begin
    LoopSignal:=0;
    Break;
   End;
   If LoopSignal=2Then LoopSignal:=0;
  Until Terminated;J:=E+1;
 End
  Else
 If WordStart(S,'DO FOREVER')Then Begin
  E:=BlockEnd(J+1,Z);
  Repeat
   LoopSignal:=0;ExecRange(J+1,E-1);
   If LoopSignal=1Then Begin
    LoopSignal:=0;
    Break;
   End;
   If LoopSignal=2Then LoopSignal:=0;
   Until Terminated;
   J:=E+1;
  End
   Else
  If WordStart(S,'DO')and(System.Pos('=',S)>0)and(FindWord(S,'TO')>0)Then Begin
   E:=BlockEnd(J+1,Z);
   EqPos:=System.Pos('=',S);
   ToPos:=FindWord(S,'TO');
   ByPos:=FindWord(S,'BY');
   LoopVar:=Clean(Copy(S,3,EqPos-3));
   Eval(Copy(S,EqPos+1,ToPos-EqPos-1),V);LoopValue:=V.Number;
   If ByPos>0Then Begin
    Eval(Copy(S,ToPos+2,ByPos-ToPos-2),V);LoopEnd:=V.Number;
    Eval(Copy(S,ByPos+2,255),V);LoopStep:=V.Number;
   End
    Else
   Begin
    Eval(Copy(S,ToPos+2,255),V);LoopEnd:=V.Number;
    LoopStep:=1;
   End;
   If LoopStep=0Then LoopStep:=1;
   While (((LoopStep>0)and(LoopValue<=LoopEnd))or((LoopStep<0)and(LoopValue>=LoopEnd)))and Not Terminated Do Begin
    VarSet(LoopVar,NumToText(LoopValue));LoopSignal:=0;ExecRange(J+1,E-1);
    If LoopSignal=1Then Begin LoopSignal:=0;Break;End;
    If LoopSignal=2Then LoopSignal:=0;
    LoopValue:=LoopValue+LoopStep;
   End;
   J:=E+1;
  End
   Else
  If WordStart(S,'DO')and(Clean(Copy(S,3,255))<>'')Then Begin
   E:=BlockEnd(J+1,Z);
   Eval(Copy(S,3,255),V);RepeatCount:=System.Trunc(V.Number);
   For K:=1 To RepeatCount Do Begin
    LoopSignal:=0;
    ExecRange(J+1,E-1);
    If LoopSignal=1Then Begin
     LoopSignal:=0;
     Break;
    End;
    If LoopSignal=2Then LoopSignal:=0;
    If Terminated Then Break;
   End;
   J:=E+1;
  End
  Else
  If WordStart(S,'DO')Then Begin
   E:=BlockEnd(J+1,Z);
   ExecRange(J+1,E-1);
   J:=E+1;
  End
   Else
  If WordStart(S,'END')or WordStart(S,'ELSE')Then Inc(J)
   Else
  Begin
   ExecOne(S);
   Inc(J);
  End;
  If SignalTargetLine>0Then Begin
   If(SignalTargetLine>=A)and(SignalTargetLine<=Z)Then Begin J:=SignalTargetLine+1;SignalTargetLine:=0;End
    Else Exit;
  End;
 End;
End;

Function FindRoutineLabel(Name:String):Integer;
Var J:Integer;S:String;
Begin
 FindRoutineLabel:=0;Name:=StrToUpper(Clean(Name));
 For J:=1 To NumberLine Do Begin
  S:=Clean(PA[J]^);
  If(Length(S)>1)and(S[Length(S)]=':')Then
   If StrToUpper(Clean(Copy(S,1,Length(S)-1)))=Name Then Begin FindRoutineLabel:=J;Exit;End;
 End;
End;

Function CallRoutine(Name:String):String;
Var
 LabelLine,EndLine,J,K,SavedArgCount,SavedExprPos,
  SavedInvokeCount:Integer;
 S,ProcedureText,ExposeName:String;
 SavedReturning,HasProcedure:Boolean;
 SavedResult,SavedExprText:String;
 SavedVariables:PRexxVariable;
 VariableEntry:PRexxVariable;
 ExposedHead,ExposedEntry,NextExposed:PExposedVariable;
 SavedArgs,SavedInvokeArgs:Array[1..MaxRoutineArgs]of String;
Begin
 Name:=StrToUpper(Clean(Name));LabelLine:=FindRoutineLabel(Name);
 If LabelLine=0Then Begin CallRoutine:=Name;Exit;End;

 { Sauvegarder tout l'etat que l'evaluation recursive peut modifier. }
 SavedExprText:=ExprText;SavedExprPos:=ExprPos;
 SavedReturning:=RoutineReturning;SavedResult:=RoutineResult;
 SavedArgCount:=CurrentArgCount;
 For J:=1 To MaxRoutineArgs Do Begin
  SavedArgs[J]:=CurrentArgs[J];
  SavedInvokeArgs[J]:=InvokeArgs[J];
  If J<=InvokeArgCount Then CurrentArgs[J]:=InvokeArgs[J]Else CurrentArgs[J]:='';
 End;
 CurrentArgCount:=InvokeArgCount;SavedInvokeCount:=InvokeArgCount;

 EndLine:=NumberLine;
 For J:=LabelLine+1 To NumberLine Do Begin
  S:=Clean(PA[J]^);
  If(Length(S)>1)and(S[Length(S)]=':')Then Begin EndLine:=J-1;Break;End;
 End;

 J:=LabelLine+1;
 While(J<=EndLine)and(Clean(PA[J]^)='')Do Inc(J);
 ProcedureText:='';HasProcedure:=False;ExposedHead:=Nil;
 If(J<=EndLine)and WordStart(Clean(PA[J]^),'PROCEDURE')Then Begin
  HasProcedure:=True;ProcedureText:=Clean(Copy(Clean(PA[J]^),10,255));
  If WordStart(ProcedureText,'EXPOSE')Then Begin
   ProcedureText:=Clean(Copy(ProcedureText,7,255));
   While ProcedureText<>''Do Begin
    K:=1;
    While(K<=Length(ProcedureText))and not(ProcedureText[K]in[' ',#9])Do Inc(K);
    ExposeName:=Copy(ProcedureText,1,K-1);
    Delete(ProcedureText,1,K-1);
    While(Length(ProcedureText)>0)and(ProcedureText[1]in[' ',#9])Do
     Delete(ProcedureText,1,1);
    If ExposeName<>''Then Begin
     New(ExposedEntry);
     ExposedEntry^.Name:=StrToUpper(ExposeName);
     ExposedEntry^.Value:='';
     ExposedEntry^.Next:=ExposedHead;
     ExposedHead:=ExposedEntry;
    End;
   End;
  End;
 End;

 If HasProcedure Then Begin
  SavedVariables:=Variables;Variables:=Nil;
  ExposedEntry:=ExposedHead;
  While ExposedEntry<>Nil Do Begin
   VariableEntry:=VarFind(SavedVariables,ExposedEntry^.Name);
   If VariableEntry<>Nil Then ExposedEntry^.Value:=VariableEntry^.Value;
   VarSet(ExposedEntry^.Name,ExposedEntry^.Value);
   ExposedEntry:=ExposedEntry^.Next;
  End;
 End;

 RoutineReturning:=False;RoutineResult:='';Inc(RoutineDepth);
 ExecRange(LabelLine+1,EndLine);
 Dec(RoutineDepth);
 CallRoutine:=RoutineResult;

 If HasProcedure Then Begin
  ExposedEntry:=ExposedHead;
  While ExposedEntry<>Nil Do Begin
   VariableEntry:=VarFind(Variables,ExposedEntry^.Name);
   If VariableEntry<>Nil Then ExposedEntry^.Value:=VariableEntry^.Value
    Else ExposedEntry^.Value:='';
   ExposedEntry:=ExposedEntry^.Next;
  End;
  FreeVariables(Variables);Variables:=SavedVariables;
  ExposedEntry:=ExposedHead;
  While ExposedEntry<>Nil Do Begin
   VarSet(ExposedEntry^.Name,ExposedEntry^.Value);
   ExposedEntry:=ExposedEntry^.Next;
  End;
 End;

 ExposedEntry:=ExposedHead;
 While ExposedEntry<>Nil Do Begin
  NextExposed:=ExposedEntry^.Next;
  Dispose(ExposedEntry);
  ExposedEntry:=NextExposed;
 End;

 CurrentArgCount:=SavedArgCount;InvokeArgCount:=SavedInvokeCount;
 For J:=1 To MaxRoutineArgs Do Begin CurrentArgs[J]:=SavedArgs[J];InvokeArgs[J]:=SavedInvokeArgs[J];End;
 RoutineReturning:=SavedReturning;RoutineResult:=SavedResult;
 ExprText:=SavedExprText;ExprPos:=SavedExprPos;
End;

Procedure ExecuteCommand;Begin
 Variables:=Nil;
 RexxQueueHead:=Nil;RexxQueueTail:=Nil;RexxQueueCount:=0;
 Terminated:=False;
 ProgramExitRequested:=False;ProgramExitCode:=0;
 LoopSignal:=0;
 CurrentArgCount:=InitialArgCount;
 For I:=1 To MaxRoutineArgs Do CurrentArgs[I]:=InitialArgs[I];
 InvokeArgCount:=0;RoutineReturning:=False;RoutineResult:='';RoutineDepth:=0;
 NumericDigitsValue:=9;NumericFuzzValue:=0;NumericFormValue:='SCIENTIFIC';
 SignalTargetLine:=0;SignalHalt:=False;SignalNoValue:=False;SignalError:=False;SignalSyntax:=False;
 SignalHaltName:='HALT';SignalNoValueName:='NOVALUE';SignalErrorName:='ERROR';SignalSyntaxName:='SYNTAX';
 CurrentConditionName:='';CurrentConditionDescription:='';
 CurrentConditionInstruction:='';CurrentConditionStatus:='';
 CurrentAddress:='SYSTEM';PreviousAddress:='SYSTEM';
 CurrentOptions:='';
 CurrentTraceSetting:='N';
 TimeElapsedStart:=CurrentTimeSeconds;
 CharInStreamCount:=0;
 CharOutStreamCount:=0;
 LocalEnvironments:=Nil;
 If NumberLine>0Then ExecRange(1,NumberLine);
 RestoreLocalEnvironments;
 FreeQueue;
 FreeVariables(Variables);
End;

BEGIN
 Randomize;
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('REXX : Cette commande permet de lancer le langage de programmation REXX');
  WriteLn;
  WriteLn('Syntaxe : REXX [fichier.REX]');
 End
  Else
 Begin
 FileName:='';
  InitialArgCount:=0;
  NumberLine:=0;CurrNumberLine:=0;
  If ParamCount>0 Then Begin
   FileName:=ParamStr(1);
   If ParamCount>1Then Begin
    InitialArgCount:=1;InitialArgs[1]:='';
    For I:=2 to ParamCount do Begin
     If InitialArgs[1]<>''Then InitialArgs[1]:=InitialArgs[1]+' ';
     InitialArgs[1]:=InitialArgs[1]+ParamStr(I);
    End;
   End;
   LoadCommand;
   ExecuteCommand;
   If ProgramExitRequested Then Halt(ProgramExitCode);
  End
 End;
END.
