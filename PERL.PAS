{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal 3.2, Turbo Pascal 7)
}

Program PERL;

{$M 16384,0,16384}

Uses Crt,DOS;

Const
 CommandList:Array[0..156]of String[20]=(
  'abs','alarm','atan2','binmode','caller','chdir','chmod','chomp',
  'chop','chown','chr','chroot','close','closedir','cos','crypt',
  'defined','delete','die','each','endgrent','endhostent',
  'endnetent','endprotoent','endpwent','endservent','eof',
  'eval','exec','exists','exit','exp','fileno','flock','for',
  'foreach','fork','format','getc','getgrent','getgrgid',
  'getgrnam','gethostbyaddr','gethostbyname','gethostent',
  'getlogin','getnetbyaddr','getnetbyname','getnetent',
  'getpgrp','getppid','getpriority','getprotobyname',
  'getprotobynumber','getprotoent','getpwent','getpwnam',
  'getpwuid','getservbyname','getservbyport','getserent',
  'gmtime','grep','glob','hex','if','index','int','join',
  'keys','kill','lc','lcfirst','length','link','local',
  'localtime','log','lstat','map','mkdir','my','oct',
  'open','opendir','ord','pack','package','pipe','pop','pos',
  'print','printf','push','quotameta','qx','rand','read',
  'readdir','readlink','rename','require','rewinddir',
  'return','reverse','rmdir','scalar','seek','seekdir',
  'select','setgrent','sethostent','setnetent','setpgrp',
  'setpriority','setprotoent','setpwent','setservent',
  'shift','sin','sleep','sort','splice','split','sprintf',
  'sqrt','srand','stat','sub','substr','symlink','sysopen',
  'sysread','sysseek','system','syswrite','tell','telldir',
  'time','times','uc','ucfirst','umask','undef','unlink',
  'unless','unpack','unshift','use','utime','values','wait',
  'waitpid','wantarray','warn','while','write'
 );

 MaxLine=1024;

Type
 StrPointer=^String;
 PPerlPipe=^TPerlPipe;
 TPerlValue=Record
  Text:String;
  Number:Real;
  IsNumber:Boolean;
 End;
 PPerlVariable=^TPerlVariable;
 TPerlVariable=Record
  Name:String[63];
  Value:String;
  Next:PPerlVariable;
 End;
 PPerlHandle=^TPerlHandle;
 TPerlHandle=Record
  Name:String[63];
  BinaryMode:Boolean;
  IsOpen:Boolean;
  Descriptor:Integer;
  LockMode:Integer;
  PathName:String;
  DataFile:File;
  HasFile:Boolean;
  Pipe:PPerlPipe;
  PipeReadEnd:Boolean;
  Next:PPerlHandle;
 End;
 PPerlCallFrame=^TPerlCallFrame;
 TPerlCallFrame=Record
  RoutineName:String[63];
  PackageName:String[63];
  SourceFile:String;
  SourceLine:Integer;
  HasArguments:Boolean;
  Next:PPerlCallFrame;
 End;
 PPerlDirectoryHandle=^TPerlDirectoryHandle;
 TPerlDirectoryHandle=Record
  Name:String[63];
  PathName:String;
  IsOpen:Boolean;
  Started:Boolean;
  Search:SearchRec;
  Next:PPerlDirectoryHandle;
 End;
 PPerlHashEntry=^TPerlHashEntry;
 TPerlHashEntry=Record
  HashName,Key,Value:String;
  Next:PPerlHashEntry;
 End;
 PPerlHashCursor=^TPerlHashCursor;
 TPerlHashCursor=Record
  HashName:String[63];
  Current:PPerlHashEntry;
  Next:PPerlHashCursor;
 End;
 PPerlFormatLine=^TPerlFormatLine;
 TPerlFormatLine=Record
  Text:String;
  Next:PPerlFormatLine;
 End;
 PPerlFormat=^TPerlFormat;
 TPerlFormat=Record
  Name:String[63];
  FirstLine,LastLine:PPerlFormatLine;
  Next:PPerlFormat;
 End;
 PPerlGlobState=^TPerlGlobState;
 TPerlGlobState=Record
  Pattern:String;
  Search:SearchRec;
  Active:Boolean;
  Next:PPerlGlobState;
 End;
 PPerlSubroutine=^TPerlSubroutine;
 TPerlSubroutine=Record
  Name:String[63];
  PackageName:String[63];
  HeaderLine,EndLine:Integer;
  Next:PPerlSubroutine;
 End;
 PPerlModule=^TPerlModule;
 TPerlModule=Record
  Name,PathName:String;
  FirstLine,LastLine:Integer;
  Next:PPerlModule;
 End;
 PPerlLocalBinding=^TPerlLocalBinding;
 TPerlLocalBinding=Record
  Name:String[63];
  OldValue:String;
  Existed:Boolean;
  ScopeDepth:Integer;
  Next:PPerlLocalBinding;
 End;
 TPerlPipe=Record
  Buffer:String;
  ReadPosition:Integer;
  ReadOpen,WriteOpen:Boolean;
  Next:PPerlPipe;
 End;
 PPerlPosition=^TPerlPosition;
 TPerlPosition=Record
  VariableName:String[63];
  Position:Integer;
  IsDefined:Boolean;
  Next:PPerlPosition;
 End;

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
 PerlVariables:PPerlVariable;
 PerlHandles:PPerlHandle;
 PerlCallStack:PPerlCallFrame;
 PerlDirectoryHandles:PPerlDirectoryHandle;
 PerlHashEntries:PPerlHashEntry;
 PerlHashCursors:PPerlHashCursor;
 PerlFormats:PPerlFormat;
 PerlGlobStates:PPerlGlobState;
 PerlSubroutines:PPerlSubroutine;
 PerlReturning:Boolean;
 PerlReturnValue:TPerlValue;
 PerlModules:PPerlModule;
 PerlIncludePath:String;
 PerlStrictEnabled,PerlWarningsEnabled:Boolean;
 PerlModuleExecutionDepth:Integer;
 PerlLocalBindings:PPerlLocalBinding;
 PerlScopeDepth:Integer;
 PerlPipes:PPerlPipe;
 PerlPositions:PPerlPosition;
 CurrentPerlPackage:String[63];
 ExprSource:String;
 ExprPosition:Integer;

Function StrToUpper(S:String):String;Forward;
Procedure SetPerlVariable(Name,Value:String);Forward;
Function FindPerlVariable(Name:String):PPerlVariable;Forward;
Function DeletePerlVariable(Name:String):Boolean;Forward;
Function ExecutePerlCoreLine(S:String):Boolean;Forward;
Procedure EvalPerlExpression(S:String;Var V:TPerlValue);Forward;
Procedure ExecuteStoredLine(LineIndex:Integer);Forward;
Procedure PerlInvokeSubroutine(Name:String;Var A,B,C:TPerlValue;
 ArgumentCount:Integer;Var V:TPerlValue);Forward;
Procedure RegisterPerlSubroutines;Forward;
Procedure GetPerlArrayElement(ArrayName:String;ElementIndex:Integer;
 Var V:TPerlValue);Forward;
Procedure SetPerlArrayElement(ArrayName:String;ElementIndex:Integer;
 Value:String);Forward;
Function GetPerlArrayCount(ArrayName:String):Integer;Forward;
Function PerlArrayElementName(ArrayName:String;ElementIndex:Integer):String;Forward;
Procedure ClearPerlArray(ArrayName:String);Forward;
Function PerlIntegerBase(Value:LongInt;NumberBase:Integer;UpperCase:Boolean):String;Forward;

Function PerlCommandIndex(Name:String):Integer;
Var J,K:Integer;Matches:Boolean;LeftCharacter,RightCharacter:Char;
Begin
 PerlCommandIndex:=-1;
 For J:=Low(CommandList)To High(CommandList)Do Begin
  Matches:=Length(CommandList[J])=Length(Name);K:=1;
  While Matches and(K<=Length(Name))Do Begin
   LeftCharacter:=CommandList[J][K];RightCharacter:=Name[K];
   If LeftCharacter in['a'..'z']Then LeftCharacter:=Chr(Ord(LeftCharacter)-32);
   If RightCharacter in['a'..'z']Then RightCharacter:=Chr(Ord(RightCharacter)-32);
   Matches:=LeftCharacter=RightCharacter;Inc(K);
  End;
  If Matches Then Begin PerlCommandIndex:=J;Exit;End;
 End;
End;

Function CleanText(S:String):String;
Begin
 While(Length(S)>0)and(S[1]in[' ',#9])Do Delete(S,1,1);
 While(Length(S)>0)and(S[Length(S)]in[' ',#9,#13,#10,';'])Do Delete(S,Length(S),1);
 CleanText:=S;
End;

Function PerlNumberText(N:Real):String;
Var S:String;
Begin
 If Frac(N)=0Then Str(N:0:0,S)Else Begin Str(N:0:10,S);While S[Length(S)]='0'Do Delete(S,Length(S),1);End;
 PerlNumberText:=CleanText(S);
End;

Procedure PerlText(S:String;Var V:TPerlValue);
Var Code:Integer;N:Real;
Begin
 V.Text:=S;Val(CleanText(S),N,Code);V.IsNumber:=(Code=0)and(CleanText(S)<>'');
 If V.IsNumber Then V.Number:=N Else V.Number:=0;
End;

Procedure PerlNumber(N:Real;Var V:TPerlValue);
Begin V.Number:=N;V.IsNumber:=True;V.Text:=PerlNumberText(N);End;

Function FindPerlHandle(Name:String):PPerlHandle;
Var Handle:PPerlHandle;
Begin
 Name:=StrToUpper(CleanText(Name));Handle:=PerlHandles;
 While Handle<>Nil Do Begin
  If Handle^.Name=Name Then Begin FindPerlHandle:=Handle;Exit;End;
  Handle:=Handle^.Next;
 End;
 FindPerlHandle:=Nil;
End;

Procedure RegisterPerlHandle(Name:String;OpenState:Boolean);
Var Handle,Scan:PPerlHandle;NextDescriptor:Integer;
Begin
 Name:=StrToUpper(CleanText(Name));If Name=''Then Exit;
 Handle:=FindPerlHandle(Name);
 If Handle=Nil Then Begin
  New(Handle);Handle^.Name:=Name;Handle^.BinaryMode:=False;Handle^.LockMode:=0;
  Handle^.PathName:='';Handle^.HasFile:=False;Handle^.Pipe:=Nil;
  Handle^.PipeReadEnd:=False;
  If Name='STDIN'Then Handle^.Descriptor:=0
  Else If Name='STDOUT'Then Handle^.Descriptor:=1
  Else If Name='STDERR'Then Handle^.Descriptor:=2
  Else Begin
   NextDescriptor:=3;Scan:=PerlHandles;
   While Scan<>Nil Do Begin
    If Scan^.Descriptor>=NextDescriptor Then NextDescriptor:=Scan^.Descriptor+1;
    Scan:=Scan^.Next;
   End;
   Handle^.Descriptor:=NextDescriptor;
  End;
  Handle^.Next:=PerlHandles;PerlHandles:=Handle;
 End;
 Handle^.IsOpen:=OpenState;
End;

Procedure PerlFileNo(HandleName:String;Var V:TPerlValue);
Var Handle:PPerlHandle;
Begin
 HandleName:=StrToUpper(CleanText(HandleName));
 If(HandleName='STDIN')or(HandleName='STDOUT')or(HandleName='STDERR')Then
  RegisterPerlHandle(HandleName,True);
 Handle:=FindPerlHandle(HandleName);
 If(Handle<>Nil)and Handle^.IsOpen Then PerlNumber(Handle^.Descriptor,V)
 Else PerlText('',V);
End;

Procedure PerlFlock(HandleName:String;Operation:Integer;Var V:TPerlValue);
Var Handle:PPerlHandle;RequestedMode:Integer;
Begin
 HandleName:=StrToUpper(CleanText(HandleName));Handle:=FindPerlHandle(HandleName);
 If(Handle=Nil)or Not Handle^.IsOpen Then Begin PerlText('',V);Exit;End;
 RequestedMode:=Operation and 3;
 If(Operation and 8)<>0Then Handle^.LockMode:=0
 Else If(RequestedMode=1)or(RequestedMode=2)Then Handle^.LockMode:=RequestedMode
 Else Begin PerlText('',V);Exit;End;
 PerlNumber(1,V);
End;

Procedure PerlGetC(HandleName:String;ArgumentCount:Integer;Var V:TPerlValue);
Var Ch:Char;Handle:PPerlHandle;ByteValue:Byte;BytesRead:Word;
Begin
 HandleName:=StrToUpper(CleanText(HandleName));
 If ArgumentCount=0Then HandleName:='STDIN';
 If HandleName='STDIN'Then Begin
  RegisterPerlHandle('STDIN',True);
  Ch:=ReadKey;PerlText(Ch,V);
 End Else Begin
  Handle:=FindPerlHandle(HandleName);
  If(Handle<>Nil)and Handle^.IsOpen and(Handle^.Pipe<>Nil)and Handle^.PipeReadEnd Then Begin
   If Handle^.Pipe^.ReadPosition<=Length(Handle^.Pipe^.Buffer)Then Begin
    Ch:=Handle^.Pipe^.Buffer[Handle^.Pipe^.ReadPosition];Inc(Handle^.Pipe^.ReadPosition);
    PerlText(Ch,V);End Else PerlText('',V);
  End Else If(Handle=Nil)or Not Handle^.IsOpen or Not Handle^.HasFile Then PerlText('',V)
  Else Begin {$I-}BlockRead(Handle^.DataFile,ByteValue,1,BytesRead);{$I+}
   If(IoResult=0)and(BytesRead=1)Then Begin Ch:=Chr(ByteValue);PerlText(Ch,V);End
   Else PerlText('',V);End;
 End;
End;

Function PerlLeapYear(Year:Integer):Boolean;
Begin PerlLeapYear:=(Year mod 4=0)and((Year mod 100<>0)or(Year mod 400=0));End;

Procedure PerlGmTime(TimeValue:LongInt;ArgumentCount:Integer;Var V:TPerlValue);
Const SecondsPerDay:LongInt=86400;
 MonthNames:Array[1..12]of String[3]=('Jan','Feb','Mar','Apr','May','Jun',
 'Jul','Aug','Sep','Oct','Nov','Dec');
 DayNames:Array[0..6]of String[3]=('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
 MonthDays:Array[1..12]of Byte=(31,28,31,30,31,30,31,31,30,31,30,31);
Var Year,Month,Day,Hour,Minute,Second,WeekDay,Days,DaysInYear,DaysInMonth:Integer;
 WYear,WMonth,WDay,WWeekDay,WHour,WMinute,WSecond,Hundredths:Word;
 SYear,SDay,SHour,SMinute,SSecond:String;
begin
 If ArgumentCount=0Then Begin
  GetDate(WYear,WMonth,WDay,WWeekDay);GetTime(WHour,WMinute,WSecond,Hundredths);
  Year:=WYear;Month:=WMonth;Day:=WDay;WeekDay:=WWeekDay;
  Hour:=WHour;Minute:=WMinute;Second:=WSecond;
 End Else Begin
  Days:=TimeValue div SecondsPerDay;Second:=TimeValue mod SecondsPerDay;
  If Second<0Then Begin Inc(Second,SecondsPerDay);Dec(Days);End;
  WeekDay:=(Days+4)mod 7;If WeekDay<0Then Inc(WeekDay,7);
  Hour:=Second div 3600;Second:=Second mod 3600;
  Minute:=Second div 60;Second:=Second mod 60;Year:=1970;
  While Days<0Do Begin Dec(Year);If PerlLeapYear(Year)Then Inc(Days,366)Else Inc(Days,365);End;
  Repeat
   If PerlLeapYear(Year)Then DaysInYear:=366 Else DaysInYear:=365;
   If Days<DaysInYear Then Break;Dec(Days,DaysInYear);Inc(Year);
  Until False;
  Month:=1;
  Repeat
   DaysInMonth:=MonthDays[Month];If(Month=2)and PerlLeapYear(Year)Then Inc(DaysInMonth);
   If Days<DaysInMonth Then Break;Dec(Days,DaysInMonth);Inc(Month);
  Until Month=12;
  Day:=Days+1;
 End;
 Str(Year,SYear);Str(Day:2,SDay);Str(Hour:2,SHour);Str(Minute:2,SMinute);Str(Second:2,SSecond);
 If SHour[1]=' 'Then SHour[1]:='0';If SMinute[1]=' 'Then SMinute[1]:='0';
 If SSecond[1]=' 'Then SSecond[1]:='0';
 PerlText(DayNames[WeekDay]+' '+MonthNames[Month]+' '+SDay+' '+SHour+':' +
  SMinute+':'+SSecond+' '+CleanText(SYear),V);
End;

Procedure PerlHex(HexText:String;Var V:TPerlValue);
Var I,Code:Integer;N:LongInt;CleanHex:String;
Begin
 CleanHex:='';HexText:=CleanText(HexText);
 If Copy(StrToUpper(HexText),1,2)='0X'Then Delete(HexText,1,2);
 For I:=1To Length(HexText)Do If HexText[I]<>'_'Then CleanHex:=CleanHex+HexText[I];
 If CleanHex=''Then Begin PerlNumber(0,V);Exit;End;
 Val('$'+CleanHex,N,Code);
 If Code=0Then PerlNumber(N,V)Else PerlNumber(0,V);
End;

Procedure PerlGrep(PatternText,FirstText,SecondText:String;
 ArgumentCount:Integer;Var V:TPerlValue);
Var MatchCount:Integer;
 Procedure TestValue(ValueText:String);
 Begin
  If Pos(PatternText,ValueText)>0Then Inc(MatchCount);
 End;
Begin
 MatchCount:=0;
 If ArgumentCount>1Then TestValue(FirstText);
 If ArgumentCount>2Then TestValue(SecondText);
 PerlNumber(MatchCount,V);
End;

Function FindPerlGlobState(Pattern:String):PPerlGlobState;
Var State:PPerlGlobState;
Begin
 State:=PerlGlobStates;
 While State<>Nil Do Begin
  If State^.Pattern=Pattern Then Begin FindPerlGlobState:=State;Exit;End;
  State:=State^.Next;
 End;
 New(State);State^.Pattern:=Pattern;State^.Active:=False;
 State^.Next:=PerlGlobStates;PerlGlobStates:=State;FindPerlGlobState:=State;
End;

Procedure PerlGlob(Pattern:String;Var V:TPerlValue);
Var State:PPerlGlobState;ErrorCode,J,SlashPosition:Integer;Prefix:String;
Begin
 Pattern:=CleanText(Pattern);If Pattern=''Then Begin PerlText('',V);Exit;End;
 State:=FindPerlGlobState(Pattern);
 If Not State^.Active Then Begin
  FindFirst(Pattern,AnyFile,State^.Search);ErrorCode:=DosError;
  State^.Active:=ErrorCode=0;
 End Else Begin FindNext(State^.Search);ErrorCode:=DosError;End;
 While(ErrorCode=0)and((State^.Search.Name='.')or(State^.Search.Name='..'))Do Begin
  FindNext(State^.Search);ErrorCode:=DosError;
 End;
 If ErrorCode<>0Then Begin State^.Active:=False;PerlText('',V);Exit;End;
 SlashPosition:=0;
 For J:=1To Length(Pattern)Do If Pattern[J]in['\','/']Then SlashPosition:=J;
 Prefix:=Copy(Pattern,1,SlashPosition);PerlText(Prefix+State^.Search.Name,V);
End;

Procedure PerlIndex(SourceText,SearchText:String;StartPosition:Integer;
 ArgumentCount:Integer;Var V:TPerlValue);
Var FoundPosition:Integer;
Begin
 If ArgumentCount<3Then StartPosition:=0;
 If StartPosition<0Then StartPosition:=0;
 If StartPosition>Length(SourceText)Then Begin PerlNumber(-1,V);Exit;End;
 FoundPosition:=Pos(SearchText,Copy(SourceText,StartPosition+1,255));
 If FoundPosition=0Then PerlNumber(-1,V)
 Else PerlNumber(StartPosition+FoundPosition-1,V);
End;

Procedure PerlJoin(Separator,FirstValue,SecondValue:String;
 ArgumentCount:Integer;Var V:TPerlValue);
Var ArrayName,ResultText:String;I,Count:Integer;Item:TPerlValue;
Begin
 ResultText:='';
 If(Length(FirstValue)>0)and(FirstValue[1]='@')Then Begin
  ArrayName:=Copy(FirstValue,2,255);Count:=GetPerlArrayCount(ArrayName);
  For I:=0To Count-1Do Begin GetPerlArrayElement(ArrayName,I,Item);
   If I>0Then ResultText:=ResultText+Separator;ResultText:=ResultText+Item.Text;End;
 End Else Begin
  If ArgumentCount>1Then ResultText:=FirstValue;
  If ArgumentCount>2Then ResultText:=ResultText+Separator+SecondValue;
 End;
 PerlText(ResultText,V);
End;

Procedure PerlKeys(HashReference:String;Var V:TPerlValue);
Var Entry:PPerlHashEntry;HashName:String;Count:Integer;
Begin
 HashName:=HashReference;
 If(Length(HashName)>0)and(HashName[1]='%')Then Delete(HashName,1,1);
 Count:=0;Entry:=PerlHashEntries;
 While Entry<>Nil Do Begin If Entry^.HashName=HashName Then Inc(Count);Entry:=Entry^.Next;End;
 PerlNumber(Count,V);
End;

Procedure PerlLowerCase(SourceText:String;Var V:TPerlValue);
Var J:Integer;
Begin
 For J:=1To Length(SourceText)Do If SourceText[J]in['A'..'Z']Then
  SourceText[J]:=Chr(Ord(SourceText[J])+32);
 PerlText(SourceText,V);
End;

Procedure PerlLowerCaseFirst(SourceText:String;Var V:TPerlValue);
Begin
 If(Length(SourceText)>0)and(SourceText[1]in['A'..'Z'])Then
  SourceText[1]:=Chr(Ord(SourceText[1])+32);
 PerlText(SourceText,V);
End;

Procedure PerlKill(SignalNumber:Integer;FirstProcess,SecondProcess:String;
 ArgumentCount:Integer;Var V:TPerlValue);
Begin
 { DOS n'expose aucune primitive pour envoyer un signal a un processus.
   Retourner zero respecte le nombre de processus effectivement signales. }
 PerlNumber(0,V);
End;

Procedure PerlLink(ExistingPath,NewPath:String;Var V:TPerlValue);
Begin
 { FAT et l'API DOS de Turbo Pascal ne prennent pas en charge les liens
   physiques. Une copie serait semantiquement incorrecte: signaler l'echec. }
 PerlText('',V);
End;

Procedure PerlLocalTime(TimeValue:LongInt;ArgumentCount:Integer;Var V:TPerlValue);
Begin
 { L'horloge DOS est locale. Sans argument, PerlGmTime lit donc deja l'heure
   locale; pour un epoch explicite, aucune base de fuseaux n'existe sous DOS. }
 PerlGmTime(TimeValue,ArgumentCount,V);
End;

Procedure PerlLog(NumberValue:Real;Var V:TPerlValue);
Begin If NumberValue>0Then PerlNumber(Ln(NumberValue),V)Else PerlText('',V);End;

Procedure PerlLStat(PathName:String;Var V:TPerlValue);
Var Search:SearchRec;ErrorCode:Integer;
Begin
 FindFirst(PathName,AnyFile,Search);ErrorCode:=DosError;
 If ErrorCode=0Then PerlNumber(1,V)Else PerlText('',V);
End;

Procedure PerlMap(ExpressionText,FirstValue,SecondValue:String;
 ArgumentCount:Integer;Var V:TPerlValue);
Var SavedSource,ArrayName:String;SavedPosition,I,Count:Integer;
 OldVariable:PPerlVariable;OldExisted:Boolean;OldValue:String;Item,Mapped:TPerlValue;
 Procedure MapOne(ValueText:String);
 Begin SetPerlVariable('_',ValueText);EvalPerlExpression(ExpressionText,Mapped);Inc(Count);End;
Begin
 SavedSource:=ExprSource;SavedPosition:=ExprPosition;OldVariable:=FindPerlVariable('_');
 OldExisted:=OldVariable<>Nil;If OldExisted Then OldValue:=OldVariable^.Value Else OldValue:='';
 Count:=0;
 If(Length(FirstValue)>0)and(FirstValue[1]='@')Then Begin
  ArrayName:=Copy(FirstValue,2,255);
  For I:=0To GetPerlArrayCount(ArrayName)-1Do Begin
   GetPerlArrayElement(ArrayName,I,Item);MapOne(Item.Text);End;
 End Else Begin
  If ArgumentCount>1Then MapOne(FirstValue);If ArgumentCount>2Then MapOne(SecondValue);
 End;
 If OldExisted Then SetPerlVariable('_',OldValue)Else DeletePerlVariable('_');
 ExprSource:=SavedSource;ExprPosition:=SavedPosition;PerlNumber(Count,V);
End;

Procedure PerlBinMode(HandleName,LayerName:String;Var V:TPerlValue);
Var Handle:PPerlHandle;
Begin
 HandleName:=StrToUpper(CleanText(HandleName));
 If(HandleName='STDIN')or(HandleName='STDOUT')or(HandleName='STDERR')Then
  RegisterPerlHandle(HandleName,True);
 Handle:=FindPerlHandle(HandleName);
 If(Handle=Nil)or Not Handle^.IsOpen Then Begin PerlText('',V);Exit;End;
 LayerName:=StrToUpper(CleanText(LayerName));
 If(LayerName=':CRLF')or(LayerName='CRLF')Then Handle^.BinaryMode:=False
 Else Handle^.BinaryMode:=True;
 PerlNumber(1,V);
End;

Procedure PushPerlCallFrame(RoutineName,PackageName,SourceName:String;
 SourceLine:Integer;HasArguments:Boolean);
Var Frame:PPerlCallFrame;
Begin
 New(Frame);Frame^.RoutineName:=RoutineName;Frame^.PackageName:=PackageName;
 Frame^.SourceFile:=SourceName;Frame^.SourceLine:=SourceLine;
 Frame^.HasArguments:=HasArguments;Frame^.Next:=PerlCallStack;
 PerlCallStack:=Frame;
End;

Procedure PopPerlCallFrame;
Var Frame:PPerlCallFrame;
Begin
 If PerlCallStack=Nil Then Exit;
 Frame:=PerlCallStack;PerlCallStack:=Frame^.Next;Dispose(Frame);
End;

Procedure PerlCaller(RequestedLevel:LongInt;Var V:TPerlValue);
Var Frame:PPerlCallFrame;
Begin
 If RequestedLevel<0Then Begin PerlText('',V);Exit;End;
 Frame:=PerlCallStack;
 While(Frame<>Nil)and(RequestedLevel>0)Do Begin Frame:=Frame^.Next;Dec(RequestedLevel);End;
 If Frame=Nil Then PerlText('',V)Else PerlText(Frame^.PackageName,V);
End;

Function PerlFileExists(PathName:String):Boolean;
Var F:File;ErrorCode:Integer;
Begin
 {$I-}Assign(F,PathName);Reset(F,1);{$I+}ErrorCode:=IoResult;
 PerlFileExists:=ErrorCode=0;If ErrorCode=0Then Close(F);
End;

Procedure PerlChMod(ModeValue:LongInt;FirstFile,SecondFile:String;
 ArgumentCount:Integer;Var V:TPerlValue);
Var F:File;Attributes,ErrorCode,ChangedCount:Word;
 Procedure ChangeOne(PathName:String);
 Begin
  If PathName=''Then Exit;
  Assign(F,PathName);GetFAttr(F,Attributes);ErrorCode:=DosError;
  If ErrorCode<>0Then Exit;
  If(ModeValue and 128)<>0Then Attributes:=Attributes and Not ReadOnly
   Else Attributes:=Attributes or ReadOnly;
  SetFAttr(F,Attributes);If DosError=0Then Inc(ChangedCount);
 End;
Begin
 ChangedCount:=0;If ArgumentCount>1Then ChangeOne(FirstFile);
 If ArgumentCount>2Then ChangeOne(SecondFile);
 PerlNumber(ChangedCount,V);
End;

Procedure PerlChomp(VariableName:String;Var A:TPerlValue;Var V:TPerlValue);
Var Removed:Integer;
Begin
 Removed:=0;
 If Copy(A.Text,Length(A.Text)-1,2)=#13#10Then Begin Delete(A.Text,Length(A.Text)-1,2);Removed:=2;End
 Else If(Length(A.Text)>0)and(A.Text[Length(A.Text)]in[#10,#13])Then Begin Delete(A.Text,Length(A.Text),1);Removed:=1;End;
 If VariableName<>''Then SetPerlVariable(VariableName,A.Text);
 PerlNumber(Removed,V);
End;

Procedure PerlChop(VariableName:String;Var A:TPerlValue;Var V:TPerlValue);
Var RemovedCharacter:String;
Begin
 RemovedCharacter:='';
 If Length(A.Text)>0Then Begin
  RemovedCharacter:=A.Text[Length(A.Text)];Delete(A.Text,Length(A.Text),1);
 End;
 If VariableName<>''Then SetPerlVariable(VariableName,A.Text);
 PerlText(RemovedCharacter,V);
End;

Procedure PerlChOwn(UserId,GroupId:LongInt;FirstFile:String;
 ArgumentCount:Integer;Var V:TPerlValue);
Begin
 { DOS et Windows ne fournissent pas chown par l'unite DOS. Ne pas annoncer
   un faux succes: Perl retourne zero fichier modifie sur cette plateforme. }
 PerlNumber(0,V);
End;

Procedure PerlChr(CharacterCode:LongInt;Var V:TPerlValue);
Begin
 CharacterCode:=CharacterCode mod 256;
 If CharacterCode<0Then Inc(CharacterCode,256);
 PerlText(Chr(CharacterCode),V);
End;

Function FindPerlDirectoryHandle(Name:String):PPerlDirectoryHandle;
Var Handle:PPerlDirectoryHandle;
Begin
 Name:=StrToUpper(CleanText(Name));Handle:=PerlDirectoryHandles;
 While Handle<>Nil Do Begin
  If Handle^.Name=Name Then Begin FindPerlDirectoryHandle:=Handle;Exit;End;
  Handle:=Handle^.Next;
 End;
 FindPerlDirectoryHandle:=Nil;
End;

Procedure RegisterPerlDirectoryHandle(Name:String);
Var Handle:PPerlDirectoryHandle;
Begin
 Name:=StrToUpper(CleanText(Name));If Name=''Then Exit;
 Handle:=FindPerlDirectoryHandle(Name);
 If Handle=Nil Then Begin
  New(Handle);Handle^.Name:=Name;Handle^.PathName:='';Handle^.Started:=False;
  Handle^.Next:=PerlDirectoryHandles;
  PerlDirectoryHandles:=Handle;
 End;
 Handle^.IsOpen:=True;
End;

Procedure PerlCloseDir(HandleName:String;Var V:TPerlValue);
Var Handle:PPerlDirectoryHandle;
Begin
 Handle:=FindPerlDirectoryHandle(HandleName);
 If(Handle<>Nil)and Handle^.IsOpen Then Begin
  Handle^.IsOpen:=False;PerlNumber(1,V);
 End Else PerlText('',V);
End;

Procedure PerlOpen(HandleName,ModeText,PathName:String;
 ArgumentCount:Integer;Var V:TPerlValue);
Var Handle:PPerlHandle;ErrorCode:Integer;SavedFileMode:Byte;
Begin
 HandleName:=StrToUpper(CleanText(HandleName));ModeText:=CleanText(ModeText);
 PathName:=CleanText(PathName);
 If ArgumentCount=2Then Begin
  PathName:=ModeText;ModeText:='<';
  If Copy(PathName,1,2)='>>'Then Begin ModeText:='>>';Delete(PathName,1,2);End
  Else If(Length(PathName)>0)and(PathName[1]in['<','>'])Then Begin
   ModeText:=PathName[1];Delete(PathName,1,1);End;
 End;
 If ModeText=''Then ModeText:='<';RegisterPerlHandle(HandleName,False);
 Handle:=FindPerlHandle(HandleName);
 If Handle^.HasFile Then Begin {$I-}Close(Handle^.DataFile);{$I+}ErrorCode:=IoResult;
  Handle^.HasFile:=False;End;
 Assign(Handle^.DataFile,PathName);SavedFileMode:=FileMode;{$I-}
 If ModeText='>'Then Rewrite(Handle^.DataFile,1)
 Else If ModeText='>>'Then Begin
  FileMode:=2;Reset(Handle^.DataFile,1);
  If IoResult<>0Then Rewrite(Handle^.DataFile,1)Else Seek(Handle^.DataFile,FileSize(Handle^.DataFile));
 End Else Begin
  If Pos('+',ModeText)>0Then FileMode:=2 Else FileMode:=0;
  If Pos('>',ModeText)>0Then Rewrite(Handle^.DataFile,1)Else Reset(Handle^.DataFile,1);
 End;
 {$I+}ErrorCode:=IoResult;FileMode:=SavedFileMode;
 If ErrorCode=0Then Begin Handle^.PathName:=PathName;Handle^.HasFile:=True;
  Handle^.IsOpen:=True;PerlNumber(1,V);End
 Else Begin Handle^.IsOpen:=False;PerlText('',V);End;
End;

Procedure PerlOpenDir(HandleName,PathName:String;Var V:TPerlValue);
Var Handle:PPerlDirectoryHandle;Search:SearchRec;ErrorCode:Integer;
Begin
 HandleName:=StrToUpper(CleanText(HandleName));PathName:=CleanText(PathName);
 FindFirst(PathName,Directory,Search);ErrorCode:=DosError;
 If(ErrorCode<>0)or((Search.Attr and Directory)=0)Then Begin PerlText('',V);Exit;End;
 RegisterPerlDirectoryHandle(HandleName);Handle:=FindPerlDirectoryHandle(HandleName);
 Handle^.PathName:=PathName;Handle^.Started:=False;PerlNumber(1,V);
End;

Procedure PerlRead(HandleName,VariableName:String;RequestedLength:Integer;
 Var V:TPerlValue);
Var Handle:PPerlHandle;Buffer:Array[1..255]of Char;BytesRead:Word;
 I,Available:Integer;ResultText:String;Ch:Char;
Begin
 HandleName:=StrToUpper(CleanText(HandleName));ResultText:='';
 If RequestedLength<0Then Begin PerlText('',V);Exit;End;
 If RequestedLength>255Then RequestedLength:=255;
 If HandleName='STDIN'Then Begin
  RegisterPerlHandle('STDIN',True);BytesRead:=0;
  For I:=1To RequestedLength Do Begin
   Ch:=ReadKey;
   If Ch=#0Then Ch:=ReadKey
   Else Begin ResultText:=ResultText+Ch;Inc(BytesRead);End;
  End;
  If VariableName<>''Then SetPerlVariable(VariableName,ResultText);
  PerlNumber(BytesRead,V);Exit;
 End;
 Handle:=FindPerlHandle(HandleName);
 If(Handle=Nil)or Not Handle^.IsOpen Then Begin PerlText('',V);Exit;End;
 BytesRead:=0;
 If(Handle^.Pipe<>Nil)and Handle^.PipeReadEnd Then Begin
  Available:=Length(Handle^.Pipe^.Buffer)-Handle^.Pipe^.ReadPosition+1;
  If Available<0Then Available:=0;
  If RequestedLength>Available Then RequestedLength:=Available;
  ResultText:=Copy(Handle^.Pipe^.Buffer,Handle^.Pipe^.ReadPosition,RequestedLength);
  Inc(Handle^.Pipe^.ReadPosition,Length(ResultText));BytesRead:=Length(ResultText);
 End Else If Handle^.HasFile Then Begin
  {$I-}BlockRead(Handle^.DataFile,Buffer,RequestedLength,BytesRead);{$I+}
  If IoResult<>0Then Begin PerlText('',V);Exit;End;
  For I:=1To BytesRead Do ResultText:=ResultText+Buffer[I];
 End Else Begin PerlText('',V);Exit;End;
 If VariableName<>''Then SetPerlVariable(VariableName,ResultText);
 PerlNumber(BytesRead,V);
End;

Procedure PerlReadDir(HandleName:String;Var V:TPerlValue);
Var Handle:PPerlDirectoryHandle;ErrorCode:Integer;SearchPath:String;
Begin
 Handle:=FindPerlDirectoryHandle(HandleName);
 If(Handle=Nil)or Not Handle^.IsOpen Then Begin PerlText('',V);Exit;End;
 If Not Handle^.Started Then Begin
  SearchPath:=Handle^.PathName;
  If(Length(SearchPath)>0)and Not(SearchPath[Length(SearchPath)]in['\','/'])Then
   SearchPath:=SearchPath+'\';
  FindFirst(SearchPath+'*.*',AnyFile,Handle^.Search);ErrorCode:=DosError;
  Handle^.Started:=True;
 End Else Begin FindNext(Handle^.Search);ErrorCode:=DosError;End;
 If ErrorCode=0Then PerlText(Handle^.Search.Name,V)Else PerlText('',V);
End;

Procedure PerlReadLink(PathName:String;Var V:TPerlValue);
Begin
 { DOS et Turbo Pascal ne fournissent aucune primitive de lien symbolique.
   Comme Perl sur un systeme sans symlink, readlink retourne undef. }
 PerlText('',V);
End;

Procedure PerlOct(NumberText:String;Var V:TPerlValue);
Var I,NumberBase,Digit:Integer;N:LongInt;
Begin
 NumberText:=StrToUpper(CleanText(NumberText));I:=1;NumberBase:=8;N:=0;
 If Copy(NumberText,1,2)='0X'Then Begin NumberBase:=16;I:=3;End
 Else If Copy(NumberText,1,2)='0B'Then Begin NumberBase:=2;I:=3;End
 Else If(Length(NumberText)>0)and(NumberText[1]='0')Then I:=2;
 While I<=Length(NumberText)Do Begin
  If NumberText[I]='_'Then Begin Inc(I);Continue;End;
  If NumberText[I]in['0'..'9']Then Digit:=Ord(NumberText[I])-Ord('0')
  Else If NumberText[I]in['A'..'F']Then Digit:=Ord(NumberText[I])-Ord('A')+10
  Else Break;
  If Digit>=NumberBase Then Break;N:=N*NumberBase+Digit;Inc(I);
 End;
 PerlNumber(N,V);
End;

Procedure PerlOrd(SourceText:String;Var V:TPerlValue);
Begin If SourceText=''Then PerlNumber(0,V)Else PerlNumber(Ord(SourceText[1]),V);End;

Procedure PerlPack(TemplateText:String;Var FirstValue,SecondValue:TPerlValue;
 ArgumentCount:Integer;Var V:TPerlValue);
Var I,J,RepeatCount,ValueIndex,Digit:Integer;Directive:Char;N:LongInt;
 ResultText,SourceText:String;
 Procedure AddByte(ByteValue:LongInt);
 Begin ResultText:=ResultText+Chr(ByteValue mod 256);End;
 Procedure SelectValue(Index:Integer;Var Selected:TPerlValue);
 Begin If Index=0Then Selected:=FirstValue Else Selected:=SecondValue;End;
Var Selected:TPerlValue;
Begin
 ResultText:='';I:=1;ValueIndex:=0;
 While I<=Length(TemplateText)Do Begin
  Directive:=TemplateText[I];Inc(I);RepeatCount:=0;
  If(I<=Length(TemplateText))and(TemplateText[I]='*')Then Begin RepeatCount:=-1;Inc(I);End
  Else Begin While(I<=Length(TemplateText))and(TemplateText[I]in['0'..'9'])Do Begin
   RepeatCount:=RepeatCount*10+Ord(TemplateText[I])-Ord('0');Inc(I);End;
   If RepeatCount=0Then RepeatCount:=1;
  End;
  SelectValue(ValueIndex,Selected);If ValueIndex<1 Then Inc(ValueIndex);
  If Directive in['a','A','Z']Then Begin
   SourceText:=Selected.Text;If RepeatCount<0Then RepeatCount:=Length(SourceText);
   If(Directive='Z')and(RepeatCount>0)Then Begin
    SourceText:=Copy(SourceText,1,RepeatCount-1)+#0;End;
   If Length(SourceText)>RepeatCount Then SourceText:=Copy(SourceText,1,RepeatCount);
   While Length(SourceText)<RepeatCount Do If Directive='A'Then SourceText:=SourceText+' '
    Else SourceText:=SourceText+#0;ResultText:=ResultText+SourceText;
  End Else If Directive in['H','h']Then Begin
   SourceText:=StrToUpper(Selected.Text);If RepeatCount<0Then RepeatCount:=Length(SourceText);
   J:=1;While J<=RepeatCount Do Begin
    If J<=Length(SourceText)Then Begin If SourceText[J]in['0'..'9']Then
     N:=Ord(SourceText[J])-Ord('0')Else N:=Ord(SourceText[J])-Ord('A')+10;End Else N:=0;
    Digit:=N;Inc(J);
    If J<=Length(SourceText)Then Begin If SourceText[J]in['0'..'9']Then
     N:=Ord(SourceText[J])-Ord('0')Else N:=Ord(SourceText[J])-Ord('A')+10;End Else N:=0;
    If Directive='H'Then AddByte(Digit*16+N)Else AddByte(N*16+Digit);Inc(J);
   End;
  End Else For J:=1To RepeatCount Do Begin
   N:=Trunc(Selected.Number);
   Case Directive of
    'c','C':AddByte(N);
    's','S','v':Begin AddByte(N);AddByte(N div 256);End;
    'n':Begin AddByte(N div 256);AddByte(N);End;
    'l','L','V':Begin AddByte(N);AddByte(N div 256);AddByte(N div 65536);AddByte(N div 16777216);End;
    'N':Begin AddByte(N div 16777216);AddByte(N div 65536);AddByte(N div 256);AddByte(N);End;
   End;
   If(J<RepeatCount)and(ValueIndex<2)Then Begin
    SelectValue(ValueIndex,Selected);Inc(ValueIndex);
   End;
  End;
 End;
 PerlText(ResultText,V);
End;

Procedure PackageCommand;
Var Name:String;
Begin
 Name:=CleanText(Copy(CurrLine,CurrPos,255));If Name=''Then Name:='main';
 CurrentPerlPackage:=Name;CurrPos:=Length(CurrLine)+1;
End;

Procedure PerlPipe(ReadHandleName,WriteHandleName:String;Var V:TPerlValue);
Var PipeState:PPerlPipe;ReadHandle,WriteHandle:PPerlHandle;
Begin
 ReadHandleName:=StrToUpper(CleanText(ReadHandleName));
 WriteHandleName:=StrToUpper(CleanText(WriteHandleName));
 New(PipeState);PipeState^.Buffer:='';PipeState^.ReadPosition:=1;
 PipeState^.ReadOpen:=True;PipeState^.WriteOpen:=True;
 PipeState^.Next:=PerlPipes;PerlPipes:=PipeState;
 RegisterPerlHandle(ReadHandleName,True);RegisterPerlHandle(WriteHandleName,True);
 ReadHandle:=FindPerlHandle(ReadHandleName);WriteHandle:=FindPerlHandle(WriteHandleName);
 ReadHandle^.Pipe:=PipeState;ReadHandle^.PipeReadEnd:=True;
 WriteHandle^.Pipe:=PipeState;WriteHandle^.PipeReadEnd:=False;PerlNumber(1,V);
End;

Procedure PerlPop(ArrayReference:String;Var V:TPerlValue);
Var ArrayName,ElementName:String;Count:Integer;
Begin
 ArrayName:=ArrayReference;If(Length(ArrayName)>0)and(ArrayName[1]='@')Then Delete(ArrayName,1,1);
 Count:=GetPerlArrayCount(ArrayName);If Count=0Then Begin PerlText('',V);Exit;End;
 GetPerlArrayElement(ArrayName,Count-1,V);ElementName:=PerlArrayElementName(ArrayName,Count-1);
 DeletePerlVariable(ElementName);SetPerlVariable('@'+ArrayName+'.COUNT',PerlNumberText(Count-1));
End;

Procedure PerlPos(VariableName:String;Var V:TPerlValue);
Var PositionState:PPerlPosition;
Begin
 PositionState:=PerlPositions;
 While PositionState<>Nil Do Begin
  If PositionState^.VariableName=VariableName Then Begin
   If PositionState^.IsDefined Then PerlNumber(PositionState^.Position,V)Else PerlText('',V);Exit;End;
  PositionState:=PositionState^.Next;
 End;
 PerlText('',V);
End;

Procedure PerlPush(ArrayReference,FirstValue,SecondValue:String;
 ArgumentCount:Integer;Var V:TPerlValue);
Var ArrayName:String;Count:Integer;
Begin
 ArrayName:=ArrayReference;If(Length(ArrayName)>0)and(ArrayName[1]='@')Then Delete(ArrayName,1,1);
 Count:=GetPerlArrayCount(ArrayName);
 If ArgumentCount>1Then Begin SetPerlArrayElement(ArrayName,Count,FirstValue);Inc(Count);End;
 If ArgumentCount>2Then Begin SetPerlArrayElement(ArrayName,Count,SecondValue);Inc(Count);End;
 PerlNumber(Count,V);
End;

Procedure PerlQuoteMeta(SourceText:String;Var V:TPerlValue);
Var J:Integer;ResultText:String;
Begin
 ResultText:='';For J:=1To Length(SourceText)Do Begin
  If Not(SourceText[J]in['A'..'Z','a'..'z','0'..'9','_'])Then ResultText:=ResultText+'\';
  ResultText:=ResultText+SourceText[J];
 End;
 PerlText(ResultText,V);
End;

Procedure PerlQx(CommandText:String;Var V:TPerlValue);
Var CommandShell,TemporaryName,LineText,ResultText,NumberText:String;
 OutputFile:Text;ErrorCode:Integer;
begin
 Str(Random(30000),NumberText);TemporaryName:='PERLQX'+CleanText(NumberText)+'.$$$';
 CommandShell:=GetEnv('COMSPEC');If CommandShell=''Then CommandShell:='COMMAND.COM';
 SwapVectors;Exec(CommandShell,'/C '+CommandText+' > '+TemporaryName);SwapVectors;
 ErrorCode:=DosError;ResultText:='';
 If ErrorCode=0Then Begin {$I-}Assign(OutputFile,TemporaryName);Reset(OutputFile);{$I+}
  If IoResult=0Then Begin While Not Eof(OutputFile)Do Begin ReadLn(OutputFile,LineText);
   ResultText:=ResultText+LineText+#10;End;Close(OutputFile);End;
 End;
 {$I-}Assign(OutputFile,TemporaryName);Erase(OutputFile);{$I+}ErrorCode:=IoResult;
 PerlText(ResultText,V);
End;

Procedure PerlRand(LimitValue:Real;ArgumentCount:Integer;Var V:TPerlValue);
Begin If(ArgumentCount=0)or(LimitValue<=0)Then LimitValue:=1;
 PerlNumber(Random*LimitValue,V);
End;

Procedure PerlSrand(SeedValue:LongInt;ArgumentCount:Integer;Var V:TPerlValue);
Begin
 If ArgumentCount=0Then Begin Randomize;PerlNumber(1,V);End
 Else Begin RandSeed:=SeedValue;PerlNumber(SeedValue,V);End;
End;

Procedure PerlSplit(Separator,SourceText:String;Limit:Integer;
 ArgumentCount:Integer;Var V:TPerlValue);
Var StartPosition,FoundPosition,ElementIndex,I:Integer;Part:String;
begin
 ClearPerlArray('PERLSPLIT');ElementIndex:=0;
 If ArgumentCount<3Then Limit:=0;
 If Separator=' 'Then Begin
  I:=1;
  While I<=Length(SourceText)Do Begin
   While(I<=Length(SourceText))and(SourceText[I]in[' ',#9,#13,#10])Do Inc(I);
   StartPosition:=I;
   While(I<=Length(SourceText))and Not(SourceText[I]in[' ',#9,#13,#10])Do Inc(I);
   If I>StartPosition Then Begin
    SetPerlArrayElement('PERLSPLIT',ElementIndex,Copy(SourceText,StartPosition,I-StartPosition));
    Inc(ElementIndex);
   End;
  End;
 End Else If Separator=''Then Begin
  For I:=1To Length(SourceText)Do Begin
   If(Limit>0)and(ElementIndex=Limit-1)Then Begin
    SetPerlArrayElement('PERLSPLIT',ElementIndex,Copy(SourceText,I,255));Inc(ElementIndex);Break;
   End;
   SetPerlArrayElement('PERLSPLIT',ElementIndex,SourceText[I]);Inc(ElementIndex);
  End;
 End Else Begin
  StartPosition:=1;
  Repeat
   If(Limit>0)and(ElementIndex=Limit-1)Then FoundPosition:=0
   Else FoundPosition:=Pos(Separator,Copy(SourceText,StartPosition,255));
   If FoundPosition=0Then Part:=Copy(SourceText,StartPosition,255)
   Else Part:=Copy(SourceText,StartPosition,FoundPosition-1);
   SetPerlArrayElement('PERLSPLIT',ElementIndex,Part);Inc(ElementIndex);
   If FoundPosition>0Then Inc(StartPosition,FoundPosition-1+Length(Separator));
  Until FoundPosition=0;
  If Limit=0Then While(ElementIndex>0)Do Begin
   GetPerlArrayElement('PERLSPLIT',ElementIndex-1,V);
   If V.Text<>''Then Break;Dec(ElementIndex);
   DeletePerlVariable(PerlArrayElementName('PERLSPLIT',ElementIndex));
   SetPerlVariable('@PERLSPLIT.COUNT',PerlNumberText(ElementIndex));
  End;
 End;
 PerlText('@PERLSPLIT',V);
End;

Procedure PerlSprintf(FormatText:String;FirstValue,SecondValue:TPerlValue;
 ArgumentCount:Integer;Var V:TPerlValue);
Var I,ValueIndex,Width,J:Integer;Conversion:Char;Piece,ResultText:String;
 CurrentValue:TPerlValue;N:LongInt;
Begin
 I:=1;ValueIndex:=1;ResultText:='';
 While I<=Length(FormatText)Do Begin
  If FormatText[I]<>'%'Then Begin ResultText:=ResultText+FormatText[I];Inc(I);End
  Else Begin
   Inc(I);
   If(I<=Length(FormatText))and(FormatText[I]='%')Then Begin
    ResultText:=ResultText+'%';Inc(I);
   End Else Begin
    Width:=0;
    While(I<=Length(FormatText))and(FormatText[I]in['0'..'9'])Do Begin
     Width:=Width*10+Ord(FormatText[I])-Ord('0');Inc(I);
    End;
    If I<=Length(FormatText)Then Begin Conversion:=FormatText[I];Inc(I);
     If ValueIndex=1Then CurrentValue:=FirstValue Else CurrentValue:=SecondValue;
     Inc(ValueIndex);Piece:='';N:=Trunc(CurrentValue.Number);
     Case Conversion of
      's':Piece:=CurrentValue.Text;
      'd','i':Str(N,Piece);
      'u':If N<0Then Piece:=PerlNumberText(4294967296.0+N)Else Str(N,Piece);
      'x':Piece:=PerlIntegerBase(N,16,False);
      'X':Piece:=PerlIntegerBase(N,16,True);
      'o':Piece:=PerlIntegerBase(N,8,False);
      'c':Piece:=Chr(N mod 256);
      'f':Str(CurrentValue.Number:0:6,Piece);
      'e','E','g','G':Piece:=PerlNumberText(CurrentValue.Number);
      Else Piece:='%'+Conversion;
     End;
     Piece:=CleanText(Piece);J:=Width-Length(Piece);
     While J>0Do Begin Piece:=' '+Piece;Dec(J);End;
     ResultText:=ResultText+Piece;
    End;
   End;
  End;
 End;
 PerlText(ResultText,V);
End;

Procedure PerlSubstr(SourceText:String;OffsetValue,LengthValue:Integer;
 ArgumentCount:Integer;Var V:TPerlValue);
Var StartPosition,ResultLength,SourceLength,EndPosition:Integer;
Begin
 SourceLength:=Length(SourceText);StartPosition:=OffsetValue;
 If StartPosition<0Then StartPosition:=SourceLength+StartPosition;
 If StartPosition<0Then StartPosition:=0;
 If StartPosition>SourceLength Then Begin PerlText('',V);Exit;End;
 If ArgumentCount<3Then ResultLength:=SourceLength-StartPosition
 Else If LengthValue>=0Then ResultLength:=LengthValue
 Else Begin
  EndPosition:=SourceLength+LengthValue;
  ResultLength:=EndPosition-StartPosition;
 End;
 If ResultLength<0Then ResultLength:=0;
 If ResultLength>SourceLength-StartPosition Then ResultLength:=SourceLength-StartPosition;
 PerlText(Copy(SourceText,StartPosition+1,ResultLength),V);
End;

Procedure PerlCrypt(PlainText,Salt:String;Var V:TPerlValue);
Const CryptAlphabet='./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
Var I,J:Integer;H1,H2:LongInt;ResultText,Alphabet:String;
Begin
 { Solution autonome pour DOS: l'interface et le comportement sale/reproductible
   de crypt sont conserves sans dependre d'une bibliotheque Unix externe. }
 Alphabet:=CryptAlphabet;
 If Length(Salt)<1Then Salt:='..'
 Else If Length(Salt)<2Then Salt:=Salt+'.';
 Salt:=Copy(Salt,1,2);
 For I:=1To 2Do If Pos(Salt[I],Alphabet)=0Then Salt[I]:='.';
 H1:=5381;H2:=52711;
 For I:=1To Length(PlainText)Do Begin
  H1:=(H1*33+Ord(PlainText[I]))mod 65521;
  H2:=(H2*37+Ord(PlainText[I])+H1)mod 65521;
 End;
 For I:=1To 2Do Begin
  H1:=(H1*33+Ord(Salt[I]))mod 65521;
  H2:=(H2*37+Ord(Salt[I])+H1)mod 65521;
 End;
 ResultText:=Salt;
 For I:=1To 11Do Begin
  J:=(H1+H2+I*17)mod 64;
  { Turbo Pascal 7 ne permet pas d'indexer directement une constante chaine. }
  ResultText:=ResultText+Alphabet[J+1];
  H1:=(H1*41+H2+I)mod 65521;
  H2:=(H2*43+H1+J)mod 65521;
 End;
 PerlText(ResultText,V);
End;

Function FindPerlVariable(Name:String):PPerlVariable;
Var P:PPerlVariable;
Begin
 P:=PerlVariables;
 While P<>Nil Do Begin If P^.Name=Name Then Begin FindPerlVariable:=P;Exit;End;P:=P^.Next;End;
 FindPerlVariable:=Nil;
End;

Procedure SetPerlVariable(Name,Value:String);
Var P:PPerlVariable;
Begin
 P:=FindPerlVariable(Name);
 If P=Nil Then Begin New(P);P^.Name:=Name;P^.Next:=PerlVariables;PerlVariables:=P;End;
 P^.Value:=Value;
End;

Procedure GetPerlVariable(Name:String;Var V:TPerlValue);
Var P:PPerlVariable;
Begin P:=FindPerlVariable(Name);If P=Nil Then PerlText('',V)Else PerlText(P^.Value,V);End;

Function PerlArrayElementName(ArrayName:String;ElementIndex:Integer):String;
Var IndexText:String;
Begin
 Str(ElementIndex,IndexText);
 PerlArrayElementName:='@'+ArrayName+'.'+CleanText(IndexText);
End;

Procedure SetPerlArrayElement(ArrayName:String;ElementIndex:Integer;Value:String);
Var CountValue:TPerlValue;Count:Integer;
Begin
 SetPerlVariable(PerlArrayElementName(ArrayName,ElementIndex),Value);
 GetPerlVariable('@'+ArrayName+'.COUNT',CountValue);Count:=Trunc(CountValue.Number);
 If ElementIndex>=Count Then SetPerlVariable('@'+ArrayName+'.COUNT',
  PerlNumberText(ElementIndex+1));
End;

Procedure GetPerlArrayElement(ArrayName:String;ElementIndex:Integer;Var V:TPerlValue);
Begin GetPerlVariable(PerlArrayElementName(ArrayName,ElementIndex),V);End;

Function GetPerlArrayCount(ArrayName:String):Integer;
Var V:TPerlValue;
Begin GetPerlVariable('@'+ArrayName+'.COUNT',V);GetPerlArrayCount:=Trunc(V.Number);End;

Procedure ClearPerlArray(ArrayName:String);
Var I,Count:Integer;
Begin
 Count:=GetPerlArrayCount(ArrayName);
 For I:=0To Count-1Do DeletePerlVariable(PerlArrayElementName(ArrayName,I));
 SetPerlVariable('@'+ArrayName+'.COUNT','0');
End;

Procedure PerlDefined(VariableName:String;ExpressionValue:TPerlValue;
 Var V:TPerlValue);
Begin
 If VariableName<>''Then Begin
  If FindPerlVariable(VariableName)<>Nil Then PerlNumber(1,V)
  Else PerlText('',V);
 End Else Begin
  { Une constante ou le resultat d'une expression est toujours defini, meme
    lorsqu'il contient la chaine vide. }
  PerlNumber(1,V);
 End;
End;

Function FindPerlHashEntry(HashName,Key:String):PPerlHashEntry;
Var Entry:PPerlHashEntry;
Begin
 Entry:=PerlHashEntries;
 While Entry<>Nil Do Begin
  If(Entry^.HashName=HashName)and(Entry^.Key=Key)Then Begin
   FindPerlHashEntry:=Entry;Exit;
  End;
  Entry:=Entry^.Next;
 End;
 FindPerlHashEntry:=Nil;
End;

Procedure SetPerlHashEntry(HashName,Key,Value:String);
Var Entry:PPerlHashEntry;
Begin
 Entry:=FindPerlHashEntry(HashName,Key);
 If Entry=Nil Then Begin
  New(Entry);Entry^.HashName:=HashName;Entry^.Key:=Key;
  Entry^.Next:=PerlHashEntries;PerlHashEntries:=Entry;
 End;
 Entry^.Value:=Value;
End;

Procedure ClearPerlHash(HashName:String);
Var Entry,Previous,NextEntry:PPerlHashEntry;Cursor:PPerlHashCursor;
Begin
 Entry:=PerlHashEntries;Previous:=Nil;
 While Entry<>Nil Do Begin
  NextEntry:=Entry^.Next;
  If Entry^.HashName=HashName Then Begin
   If Previous=Nil Then PerlHashEntries:=NextEntry Else Previous^.Next:=NextEntry;
   Dispose(Entry);
  End Else Previous:=Entry;
  Entry:=NextEntry;
 End;
 Cursor:=PerlHashCursors;
 While Cursor<>Nil Do Begin If Cursor^.HashName=HashName Then Cursor^.Current:=PerlHashEntries;
  Cursor:=Cursor^.Next;End;
End;

Procedure GetPerlHashEntry(HashName,Key:String;Var V:TPerlValue);
Var Entry:PPerlHashEntry;
Begin
 Entry:=FindPerlHashEntry(HashName,Key);
 If Entry=Nil Then PerlText('',V)Else PerlText(Entry^.Value,V);
End;

Function FindPerlHashCursor(HashName:String):PPerlHashCursor;
Var Cursor:PPerlHashCursor;
Begin
 Cursor:=PerlHashCursors;
 While Cursor<>Nil Do Begin
  If Cursor^.HashName=HashName Then Begin FindPerlHashCursor:=Cursor;Exit;End;
  Cursor:=Cursor^.Next;
 End;
 New(Cursor);Cursor^.HashName:=HashName;Cursor^.Current:=PerlHashEntries;
 Cursor^.Next:=PerlHashCursors;PerlHashCursors:=Cursor;FindPerlHashCursor:=Cursor;
End;

Procedure PerlEach(HashName:String;Var V:TPerlValue);
Var Cursor:PPerlHashCursor;Entry:PPerlHashEntry;
Begin
 If(Length(HashName)>0)and(HashName[1]='%')Then Delete(HashName,1,1);
 Cursor:=FindPerlHashCursor(HashName);Entry:=Cursor^.Current;
 While(Entry<>Nil)and(Entry^.HashName<>HashName)Do Entry:=Entry^.Next;
 If Entry=Nil Then Begin Cursor^.Current:=PerlHashEntries;PerlText('',V);Exit;End;
 Cursor^.Current:=Entry^.Next;PerlText(Entry^.Key,V);
End;

Procedure PerlExists(ReferenceText:String;Var V:TPerlValue);
Var P,Q:Integer;HashName,Key:String;
Begin
 ReferenceText:=CleanText(ReferenceText);P:=Pos('{',ReferenceText);
 Q:=Pos('}',ReferenceText);
 If(P>1)and(Q>P)Then Begin
  HashName:=Copy(ReferenceText,2,P-2);Key:=CleanText(Copy(ReferenceText,P+1,Q-P-1));
  If(Length(Key)>1)and(Key[1]in['''','"'])and(Key[Length(Key)]=Key[1])Then
   Key:=Copy(Key,2,Length(Key)-2);
  If FindPerlHashEntry(HashName,Key)<>Nil Then PerlNumber(1,V)Else PerlText('',V);
 End Else Begin
  If(Length(ReferenceText)>0)and(ReferenceText[1]='$')Then Delete(ReferenceText,1,1);
  If FindPerlVariable(ReferenceText)<>Nil Then PerlNumber(1,V)Else PerlText('',V);
 End;
End;

Function DeletePerlVariable(Name:String):Boolean;
Var P,Previous:PPerlVariable;
Begin
 DeletePerlVariable:=False;P:=PerlVariables;Previous:=Nil;
 While P<>Nil Do Begin
  If P^.Name=Name Then Begin
   If Previous=Nil Then PerlVariables:=P^.Next Else Previous^.Next:=P^.Next;
   Dispose(P);DeletePerlVariable:=True;Exit;
  End;
  Previous:=P;P:=P^.Next;
 End;
End;

Procedure LocalizePerlVariable(Name,NewValue:String);
Var Binding:PPerlLocalBinding;Variable:PPerlVariable;
Begin
 Binding:=PerlLocalBindings;
 While Binding<>Nil Do Begin
  If(Binding^.ScopeDepth=PerlScopeDepth)and(Binding^.Name=Name)Then Begin
   SetPerlVariable(Name,NewValue);Exit;
  End;
  Binding:=Binding^.Next;
 End;
 New(Binding);Binding^.Name:=Name;Binding^.ScopeDepth:=PerlScopeDepth;
 Variable:=FindPerlVariable(Name);Binding^.Existed:=Variable<>Nil;
 If Variable<>Nil Then Binding^.OldValue:=Variable^.Value Else Binding^.OldValue:='';
 Binding^.Next:=PerlLocalBindings;PerlLocalBindings:=Binding;
 SetPerlVariable(Name,NewValue);
End;

Procedure RestorePerlScope(ScopeDepth:Integer);
Var Binding:PPerlLocalBinding;
Begin
 While(PerlLocalBindings<>Nil)and(PerlLocalBindings^.ScopeDepth=ScopeDepth)Do Begin
  Binding:=PerlLocalBindings;PerlLocalBindings:=Binding^.Next;
  If Binding^.Existed Then SetPerlVariable(Binding^.Name,Binding^.OldValue)
  Else DeletePerlVariable(Binding^.Name);
  Dispose(Binding);
 End;
End;

Procedure PerlChRoot(PathName:String;Var V:TPerlValue);
Var ErrorCode:Integer;
Begin
 {$I-}ChDir(PathName);{$I+}ErrorCode:=IoResult;
 If ErrorCode=0Then PerlNumber(1,V)Else PerlText('',V);
End;

Procedure PerlClose(HandleName:String;Var V:TPerlValue);
Var Handle:PPerlHandle;
Begin
 HandleName:=StrToUpper(CleanText(HandleName));
 If(HandleName='STDIN')or(HandleName='STDOUT')or(HandleName='STDERR')Then
  RegisterPerlHandle(HandleName,True);
 Handle:=FindPerlHandle(HandleName);
 If(Handle<>Nil)and Handle^.IsOpen Then Begin
  If Handle^.HasFile Then Begin {$I-}Close(Handle^.DataFile);{$I+}
   Handle^.HasFile:=False;End;
  If Handle^.Pipe<>Nil Then Begin If Handle^.PipeReadEnd Then Handle^.Pipe^.ReadOpen:=False
   Else Handle^.Pipe^.WriteOpen:=False;End;
  Handle^.IsOpen:=False;PerlNumber(1,V);
 End Else PerlText('',V);
End;

Procedure PerlDelete(Name:String;Var V:TPerlValue);
Begin
 If DeletePerlVariable(Name)Then PerlNumber(1,V)Else PerlText('',V);
End;

Procedure PerlEof(HandleName:String;ArgumentCount:Integer;Var V:TPerlValue);
Var Handle:PPerlHandle;AtEnd:Boolean;
Begin
 AtEnd:=False;HandleName:=StrToUpper(CleanText(HandleName));
 If ArgumentCount=0Then AtEnd:=True
 Else If HandleName='STDIN'Then AtEnd:=Eof(Input)
 Else Begin
  Handle:=FindPerlHandle(HandleName);
  If(Handle=Nil)or Not Handle^.IsOpen Then AtEnd:=True
  Else If Handle^.Pipe<>Nil Then AtEnd:=Handle^.Pipe^.ReadPosition>Length(Handle^.Pipe^.Buffer)
  Else If Handle^.HasFile Then AtEnd:=FilePos(Handle^.DataFile)>=FileSize(Handle^.DataFile)
  Else AtEnd:=True;
 End;
 If AtEnd Then PerlNumber(1,V)Else PerlText('',V);
End;

Procedure PerlEval(CodeText:String;Var V:TPerlValue);
Var SavedSource:String;SavedPosition:Integer;
Begin
 SavedSource:=ExprSource;SavedPosition:=ExprPosition;
 If Not ExecutePerlCoreLine(CodeText)Then EvalPerlExpression(CodeText,V)
 Else PerlNumber(1,V);
 ExprSource:=SavedSource;ExprPosition:=SavedPosition;
End;

Procedure ExprSkip;
Begin While(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]in[' ',#9])Do Inc(ExprPosition);End;

Function ExprWord:String;
Var S:String;
Begin
 ExprSkip;S:='';
 While(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]in['A'..'Z','a'..'z','0'..'9','_'])Do Begin
  S:=S+ExprSource[ExprPosition];Inc(ExprPosition);
 End;
 ExprWord:=S;
End;

Procedure ParsePerlOr(Var V:TPerlValue);Forward;

Function PerlArcTan2(Y,X:Real):Real;
Const PerlPi=3.14159265358979323846;
Begin
 If X>0Then PerlArcTan2:=ArcTan(Y/X)
 Else If(X<0)and(Y>=0)Then PerlArcTan2:=ArcTan(Y/X)+PerlPi
 Else If(X<0)and(Y<0)Then PerlArcTan2:=ArcTan(Y/X)-PerlPi
 Else If(X=0)and(Y>0)Then PerlArcTan2:=PerlPi/2
 Else If(X=0)and(Y<0)Then PerlArcTan2:=-PerlPi/2
 Else PerlArcTan2:=0;
End;

Procedure ParsePerlPrimary(Var V:TPerlValue);
Var Q:Char;S,Name,FunctionName,ArgumentVariable,SecondArgumentVariable,
 ArgumentText,HashKey:String;N:Real;
 Code,FunctionByte,FunctionArgumentCount,ArgumentStart,ArgumentSourceStart:Integer;A,B,C:TPerlValue;
Begin
 ExprSkip;If ExprPosition>Length(ExprSource)Then Begin PerlText('',V);Exit;End;
 If ExprSource[ExprPosition]in['''','"']Then Begin
  Q:=ExprSource[ExprPosition];Inc(ExprPosition);S:='';
  While(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]<>Q)Do Begin
   If(Q='"')and(ExprSource[ExprPosition]='\')and(ExprPosition<Length(ExprSource))Then Begin
    Inc(ExprPosition);Case ExprSource[ExprPosition]of
     'n':S:=S+#10;'r':S:=S+#13;'t':S:=S+#9;'\':S:=S+'\';'"':S:=S+'"';Else S:=S+ExprSource[ExprPosition];End;
   End Else S:=S+ExprSource[ExprPosition];Inc(ExprPosition);
  End;
  If ExprPosition<=Length(ExprSource)Then Inc(ExprPosition);PerlText(S,V);Exit;
 End;
 If ExprSource[ExprPosition]='`'Then Begin
  Inc(ExprPosition);S:='';
  While(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]<>'`')Do Begin
   S:=S+ExprSource[ExprPosition];Inc(ExprPosition);End;
  If ExprPosition<=Length(ExprSource)Then Inc(ExprPosition);PerlQx(S,V);Exit;
 End;
 If ExprSource[ExprPosition]='('Then Begin Inc(ExprPosition);ParsePerlOr(V);ExprSkip;
 If ExprSource[ExprPosition]=')'Then Inc(ExprPosition);Exit;End;
 If ExprSource[ExprPosition]='$'Then Begin
  Inc(ExprPosition);Name:=ExprWord;ExprSkip;
  If(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]='{')Then Begin
   Inc(ExprPosition);ParsePerlOr(A);HashKey:=A.Text;ExprSkip;
   If(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]='}')Then Inc(ExprPosition);
   GetPerlHashEntry(Name,HashKey,V);
  End Else If(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]='[')Then Begin
   Inc(ExprPosition);ParsePerlOr(A);ExprSkip;
   If(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]=']')Then Inc(ExprPosition);
   GetPerlArrayElement(Name,Trunc(A.Number),V);
  End Else GetPerlVariable(Name,V);
  Exit;
 End;
 If ExprSource[ExprPosition]='%'Then Begin
  Inc(ExprPosition);Name:=ExprWord;PerlText('%'+Name,V);Exit;
 End;
 If ExprSource[ExprPosition]='@'Then Begin
  Inc(ExprPosition);Name:=ExprWord;PerlText('@'+Name,V);Exit;
 End;
 If ExprSource[ExprPosition]in['0'..'9']Then Begin
  S:='';While(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]in['0'..'9','.'])Do Begin
   S:=S+ExprSource[ExprPosition];Inc(ExprPosition);
  End;
  If(Length(S)>1)and(S[1]='0')and(System.Pos('.',S)=0)Then Begin
   N:=0;Code:=0;
   For FunctionByte:=2 To Length(S)Do Begin
    If Not(S[FunctionByte]in['0'..'7'])Then Code:=1
    Else N:=N*8+Ord(S[FunctionByte])-Ord('0');
   End;
  End Else Val(S,N,Code);
  If Code=0Then PerlNumber(N,V)Else PerlText(S,V);Exit;
 End;
 Name:=ExprWord;
 If Name<>''Then Begin
  FunctionName:=Name;
  ExprSkip;
  If((Name='quotameta')or(Name='QUOTAMETA'))and(ExprPosition<=Length(ExprSource))and
    (ExprSource[ExprPosition]='(')Then Begin
   Inc(ExprPosition);ParsePerlOr(A);ExprSkip;
   If(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]=')')Then Inc(ExprPosition);
   PerlQuoteMeta(A.Text,V);Exit;
  End;
  If(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]='(')Then Begin
   Inc(ExprPosition);ExprSkip;ArgumentSourceStart:=ExprPosition;
   ArgumentStart:=ExprPosition;ArgumentVariable:='';SecondArgumentVariable:='';ArgumentText:='';
   If(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]='$')Then Begin
    Inc(ArgumentStart);
    While(ArgumentStart<=Length(ExprSource))and(ExprSource[ArgumentStart]in['A'..'Z','a'..'z','0'..'9','_'])Do Begin
     ArgumentVariable:=ArgumentVariable+ExprSource[ArgumentStart];Inc(ArgumentStart);
    End;
   End;
   FunctionArgumentCount:=0;
   If(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]<>')')Then FunctionArgumentCount:=1;
   ParsePerlOr(A);ExprSkip;
   ArgumentText:=CleanText(Copy(ExprSource,ArgumentSourceStart,
    ExprPosition-ArgumentSourceStart));
   If(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]=',')Then Begin
    Inc(FunctionArgumentCount);Inc(ExprPosition);ExprSkip;
    If(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]='$')Then Begin
     ArgumentStart:=ExprPosition+1;
     While(ArgumentStart<=Length(ExprSource))and
       (ExprSource[ArgumentStart]in['A'..'Z','a'..'z','0'..'9','_'])Do Begin
      SecondArgumentVariable:=SecondArgumentVariable+ExprSource[ArgumentStart];Inc(ArgumentStart);
     End;
    End;
    ParsePerlOr(B);
   End
    Else
   PerlText('',B);
   ExprSkip;If(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]=',')Then Begin
    Inc(FunctionArgumentCount);Inc(ExprPosition);ParsePerlOr(C);
   End
    Else
   PerlText('',C);
   ExprSkip;
   If(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]=')')Then Inc(ExprPosition);
   FunctionByte:=PerlCommandIndex(FunctionName);
   Case FunctionByte Of
    0:PerlNumber(Abs(A.Number),V);                         { abs }
    2:PerlNumber(PerlArcTan2(A.Number,B.Number),V);       { atan2 }
    3:PerlBinMode(A.Text,B.Text,V);                        { binmode }
    4:Begin                                                { caller }
       If A.Text=''Then PerlCaller(0,V)Else PerlCaller(Trunc(A.Number),V);
      End;
    6:PerlChMod(Trunc(A.Number),B.Text,C.Text,FunctionArgumentCount,V); { chmod }
    7:PerlChomp(ArgumentVariable,A,V);                      { chomp }
    8:PerlChop(ArgumentVariable,A,V);                       { chop }
    9:PerlChOwn(Trunc(A.Number),Trunc(B.Number),C.Text,
       FunctionArgumentCount,V);                           { chown }
    10:PerlChr(Trunc(A.Number),V);                          { chr }
    11:PerlChRoot(A.Text,V);                               { chroot }
    12:PerlClose(A.Text,V);                                { close }
    13:PerlCloseDir(A.Text,V);                              { closedir }
    14:PerlNumber(Cos(A.Number),V);                        { cos }
    15:PerlCrypt(A.Text,B.Text,V);                          { crypt }
    16:PerlDefined(ArgumentVariable,A,V);                  { defined }
    17:PerlDelete(A.Text,V);                               { delete }
    19:PerlEach(A.Text,V);                                 { each }
    26:PerlEof(A.Text,FunctionArgumentCount,V);             { eof }
    27:PerlEval(A.Text,V);                                 { eval }
    29:PerlExists(ArgumentText,V);                         { exists }
    31:PerlNumber(Exp(A.Number),V);                        { exp }
    32:PerlFileNo(A.Text,V);                               { fileno }
    33:PerlFlock(A.Text,Trunc(B.Number),V);                { flock }
    38:PerlGetC(A.Text,FunctionArgumentCount,V);            { getc }
    61:PerlGmTime(Trunc(A.Number),FunctionArgumentCount,V); { gmtime }
    62:PerlGrep(A.Text,B.Text,C.Text,FunctionArgumentCount,V); { grep }
    63:PerlGlob(A.Text,V);                                  { glob }
    64:PerlHex(A.Text,V);                                   { hex }
    66:PerlIndex(A.Text,B.Text,Trunc(C.Number),FunctionArgumentCount,V); { index }
    67:PerlNumber(Trunc(A.Number),V);                      { int }
    68:PerlJoin(A.Text,B.Text,C.Text,FunctionArgumentCount,V); { join }
    69:PerlKeys(A.Text,V);                                 { keys }
    70:PerlKill(Trunc(A.Number),B.Text,C.Text,FunctionArgumentCount,V); { kill }
    71:PerlLowerCase(A.Text,V);                            { lc }
    72:PerlLowerCaseFirst(A.Text,V);                       { lcfirst }
    73:PerlNumber(Length(A.Text),V);                       { length }
    74:PerlLink(A.Text,B.Text,V);                           { link }
    76:PerlLocalTime(Trunc(A.Number),FunctionArgumentCount,V); { localtime }
    77:PerlLog(A.Number,V);                                { log }
    78:PerlLStat(A.Text,V);                                { lstat }
    79:PerlMap(ArgumentText,B.Text,C.Text,FunctionArgumentCount,V); { map }
    82:PerlOct(A.Text,V);                                  { oct }
    83:PerlOpen(A.Text,B.Text,C.Text,FunctionArgumentCount,V); { open }
    84:PerlOpenDir(A.Text,B.Text,V);                       { opendir }
    85:PerlOrd(A.Text,V);                                  { ord }
    86:PerlPack(A.Text,B,C,FunctionArgumentCount,V);        { pack }
    88:PerlPipe(A.Text,B.Text,V);                           { pipe }
    89:PerlPop(A.Text,V);                                  { pop }
    90:PerlPos(ArgumentVariable,V);                        { pos }
    93:PerlPush(A.Text,B.Text,C.Text,FunctionArgumentCount,V); { push }
    94:Begin                                               { quotemeta }
        S:=A.Text;
        If(S='')and(ArgumentText<>'')Then Begin S:=CleanText(ArgumentText);
         If(Length(S)>1)and(S[1]in['''','"'])and(S[Length(S)]=S[1])Then
          S:=Copy(S,2,Length(S)-2);End;
        PerlQuoteMeta(S,V);
       End;
    95:PerlQx(A.Text,V);                                   { qx }
    96:PerlRand(A.Number,FunctionArgumentCount,V);          { rand }
    97:PerlRead(A.Text,SecondArgumentVariable,Trunc(C.Number),V); { read }
    98:PerlReadDir(A.Text,V);                               { readdir }
    99:PerlReadLink(A.Text,V);                              { readlink }
    123:PerlSplit(A.Text,B.Text,Trunc(C.Number),FunctionArgumentCount,V); { split }
    124:PerlSprintf(A.Text,B,C,FunctionArgumentCount,V);    { sprintf }
    125:If A.Number<0Then PerlText('',V)Else PerlNumber(Sqrt(A.Number),V); { sqrt }
    126:PerlSrand(Trunc(A.Number),FunctionArgumentCount,V); { srand }
    129:PerlSubstr(A.Text,Trunc(B.Number),Trunc(C.Number),FunctionArgumentCount,V); { substr }
    140:PerlText(StrToUpper(A.Text),V);                    { uc }
   Else If FunctionByte=-1Then PerlInvokeSubroutine(FunctionName,A,B,C,
    FunctionArgumentCount,V)
   Else PerlText('',V);
   End;
  End Else PerlText(Name,V);
  Exit;
 End;
 PerlText('',V);
End;

Procedure ParsePerlUnary(Var V:TPerlValue);
Begin
 ExprSkip;
 If ExprSource[ExprPosition]='!'Then Begin
  Inc(ExprPosition);ParsePerlUnary(V);
  If(V.Text='')or(V.Text='0')Then PerlNumber(1,V)Else PerlNumber(0,V);
 End
  Else
 If ExprSource[ExprPosition]='-'Then Begin
  Inc(ExprPosition);ParsePerlUnary(V);
  PerlNumber(-V.Number,V);
 End
  Else
 If ExprSource[ExprPosition]='+'Then Begin
  Inc(ExprPosition);
  ParsePerlUnary(V);
  PerlNumber(V.Number,V);
 End
  Else
 ParsePerlPrimary(V);
End;

Procedure ParsePerlMul(Var V:TPerlValue);
Var R:TPerlValue;Op:Char;Count,J:Integer;S:String;
Begin
 ParsePerlUnary(V);
 While True Do Begin ExprSkip;If ExprPosition>Length(ExprSource)Then Exit;Op:=ExprSource[ExprPosition];
  If Not(Op in['*','/','%','x'])Then Exit;Inc(ExprPosition);ParsePerlUnary(R);
  Case Op of '*':PerlNumber(V.Number*R.Number,V);'/':If R.Number<>0Then PerlNumber(V.Number/R.Number,V)Else PerlNumber(0,V);
   '%':PerlNumber(Trunc(V.Number)mod Trunc(R.Number),V);
   'x':Begin S:='';Count:=Trunc(R.Number);For J:=1 To Count Do S:=S+V.Text;PerlText(S,V);End;End;
 End;
End;

Procedure ParsePerlAdd(Var V:TPerlValue);
Var R:TPerlValue;Op:Char;
Begin
 ParsePerlMul(V);
 While True Do Begin
  ExprSkip;
  If ExprPosition>Length(ExprSource)Then Exit;
  Op:=ExprSource[ExprPosition];
  If Not(Op in['+','-','.'])Then Exit;
  Inc(ExprPosition);
  ParsePerlMul(R);
  If Op='+'Then PerlNumber(V.Number+R.Number,V)Else
  If Op='-'Then PerlNumber(V.Number-R.Number,V)
           Else PerlText(V.Text+R.Text,V);
 End;
End;

Procedure ParsePerlCompare(Var V:TPerlValue);
Var R:TPerlValue;Op:String;Truth:Boolean;
Begin
 ParsePerlAdd(V);ExprSkip;Op:='';
 Op:=Copy(ExprSource,ExprPosition,2);
 If(Op='==')or(Op='!=')or(Op='<=')or(Op='>=')Then Inc(ExprPosition,2) Else
 If(ExprPosition<=Length(ExprSource))and(ExprSource[ExprPosition]in['<','>'])Then Begin
  Op:=ExprSource[ExprPosition];
  Inc(ExprPosition);
 End
  Else
 Op:='';
 If Op=''Then Exit;
 ParsePerlAdd(R);
 Truth:=False;
 If Op='=='Then Truth:=V.Number=R.Number Else
 If Op='!='Then Truth:=V.Number<>R.Number Else
 If Op='<'Then Truth:=V.Number<R.Number Else
 If Op='>'Then Truth:=V.Number>R.Number Else
 If Op='<='Then Truth:=V.Number<=R.Number Else
 If Op='>='Then Truth:=V.Number>=R.Number;
 If Truth Then PerlNumber(1,V)Else PerlNumber(0,V);
End;

Procedure ParsePerlAnd(Var V:TPerlValue);Var R:TPerlValue;T:Boolean;Begin
 ParsePerlCompare(V);
 While Copy(ExprSource,ExprPosition,2)='&&'Do Begin
  Inc(ExprPosition,2);
  ParsePerlCompare(R);
  T:=(V.Text<>'')and(V.Text<>'0')and(R.Text<>'')and(R.Text<>'0');
  If T Then PerlNumber(1,V)Else PerlNumber(0,V);
 End;
End;

Procedure ParsePerlOr(Var V:TPerlValue);
Var
 R:TPerlValue;
 T:Boolean;
Begin
 ParsePerlAnd(V);
 While Copy(ExprSource,ExprPosition,2)='||'Do Begin
  Inc(ExprPosition,2);
  ParsePerlAnd(R);T:=((V.Text<>'')and(V.Text<>'0'))or((R.Text<>'')and(R.Text<>'0'));
  If T Then PerlNumber(1,V)Else PerlNumber(0,V);
 End;
End;

Procedure EvalPerlExpression(S:String;Var V:TPerlValue);Begin
 ExprSource:=CleanText(S);ExprPosition:=1;
 ParsePerlOr(V);
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

Function GetCurrentDisk:Char;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 GetCurrentDisk:=CurrentDir[1];
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
 For I:=Low(CommandList)to High(CommandList)do Begin
  If CurrCommand=CommandList[I]Then Begin
   ExtractCommand:=I;
   Exit;
  End;
 End;
End;

Function GetErrorMessage(Code:Word):String;Begin
 Case Code of
  0:GetErrorMessage:='';
  2:GetErrorMessage:='Fichier introuvable';
  3:GetErrorMessage:='Chemin introuvable';
  4:GetErrorMessage:='Trop de fichiers ouvert';
  5:GetErrorMessage:='AccŠs refuse';
  6:GetErrorMessage:='Handle de fichier invalide';
  12:GetErrorMessage:='Mode d''acces sur disque invalide';
  15:GetErrorMessage:='Num‚ro de disque invalide';
  16:GetErrorMessage:='Impossible de supprimer le r‚pertoire';
  17:GetErrorMessage:='Impossible de renommer sur plusieurs volumes';
  100:GetErrorMessage:='Erreur de lecture … partir du disque';
  101:GetErrorMessage:='Erreur d''‚criture sur le disque';
  102:GetErrorMessage:='Fichier non attribue';
  103:GetErrorMessage:='Le fichier n''est pas ouvert';
  104:GetErrorMessage:='Le fichier n''est pas ouvert … l''entr‚e';
  105:GetErrorMessage:='Le fichier n''est pas ouvert … la sortie';
  106:GetErrorMessage:='Num‚ro invalide';
  150:GetErrorMessage:='Disque protege en ‚criture';
  151:GetErrorMessage:='P‚riph‚rique est inconnu';
  152:GetErrorMessage:='Disque pas prˆt';
  153:GetErrorMessage:='Commande inconnue';
  154:GetErrorMessage:='Echec de v‚rification CRC';
  155:GetErrorMessage:='Disque invalide';
  156:GetErrorMessage:='Erreur de recherche sur disque';
  157:GetErrorMessage:='Type de m‚dia invalide';
  158:GetErrorMessage:='Secteur introuvable';
  159:GetErrorMessage:='L''imprimante n''a plus de papier';
  160:GetErrorMessage:='Erreur d''‚criture sur le p‚ripherique';
  161:GetErrorMessage:='Erreur de lecture sur le p‚ripherique';
  162:GetErrorMessage:='D‚faillance mat‚rielle';
  Else GetErrorMessage:='Erreur inconnue';
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

Function FormatString(S:String):String;
Var
 I,PadLeft:Integer;
 Err:Word;
 R,T:String;
 ValueStr:String;
Begin
 R:='';
 I:=1;
 While I<=Length(S)do Begin
  Case S[I]of
   #9:R:=R+'        ';
   '\':Begin
    Inc(I);
    If I>Length(S)Then Break;
    Case S[I]of
     '0':R:=R+#0;
     'a':R:=R+#7;
     'b':R:=R+#8;
     'f':R:=R+#12;
     'n':R:=R+#13+#10;
     'r':R:=R+#13;
     't':R:=R+#9;
     'v':R:=R+#11;
     '\':R:=R+'\';
     '''':R:=R+'''';
     '"':R:=R+'"';
     '?':R:=R+'?';
     Else R:=R+S[I];
    End;
   End;
   Else R:=R+S[I];
  End;
  Inc(I);
 End;
 FormatString:=R;
End;

Procedure ChDirCommand;
Var
 Drive:Char;
 Error:Word;
 CurrPath:String;
Begin
 GetDir(0,CurrPath);
 Drive:=GetCurrentDisk;
 {$I-} ChDir(GetStringValue);{$I+}
 Error:=IoResult;
 If Error<>0Then WriteLn(GetErrorMessage(Error));
 If Drive<>GetCurrentDisk Then ChDir(CurrPath);
End;

Procedure BinModeCommand;
Var Name,LayerName:String;V,HandleValue:TPerlValue;P:Integer;
Begin
 SkipSpace;Name:=CleanText(Copy(CurrLine,CurrPos,255));LayerName:='';
 P:=System.Pos(',',Name);
 If P>0Then Begin LayerName:=CleanText(Copy(Name,P+1,255));Name:=CleanText(Copy(Name,1,P-1));End;
 If(Length(Name)>0)and(Name[1]='$')Then Begin
  Delete(Name,1,1);GetPerlVariable(Name,HandleValue);Name:=HandleValue.Text;
 End;
 If(Length(LayerName)>=2)and(LayerName[1]in['''','"'])Then
  LayerName:=Copy(LayerName,2,Length(LayerName)-2);
 PerlBinMode(Name,LayerName,V);CurrPos:=Length(CurrLine)+1;
End;

Procedure ChompCommand;
Var Name:String;A,V:TPerlValue;J:Integer;
Begin
 SkipSpace;If CurrLine[CurrPos]='$'Then Inc(CurrPos);J:=CurrPos;
 While(J<=Length(CurrLine))and(CurrLine[J]in['A'..'Z','a'..'z','0'..'9','_'])Do Inc(J);
 Name:=Copy(CurrLine,CurrPos,J-CurrPos);GetPerlVariable(Name,A);PerlChomp(Name,A,V);
 CurrPos:=Length(CurrLine)+1;
End;

Procedure ChopCommand;
Var Name:String;A,V:TPerlValue;J:Integer;
Begin
 SkipSpace;If CurrLine[CurrPos]='$'Then Inc(CurrPos);J:=CurrPos;
 While(J<=Length(CurrLine))and(CurrLine[J]in['A'..'Z','a'..'z','0'..'9','_'])Do Inc(J);
 Name:=Copy(CurrLine,CurrPos,J-CurrPos);GetPerlVariable(Name,A);PerlChop(Name,A,V);
 CurrPos:=Length(CurrLine)+1;
End;

Procedure BareFunctionCommand(FunctionName:String);
Var Arguments:String;V:TPerlValue;
Begin
 Arguments:=CleanText(Copy(CurrLine,CurrPos,255));
 EvalPerlExpression(FunctionName+'('+Arguments+')',V);
 CurrPos:=Length(CurrLine)+1;
End;

Procedure CloseCommand;
Var Name:String;V,HandleValue:TPerlValue;
Begin
 SkipSpace;Name:=CleanText(Copy(CurrLine,CurrPos,255));
 If(Length(Name)>0)and(Name[1]='$')Then Begin
  Delete(Name,1,1);GetPerlVariable(Name,HandleValue);Name:=HandleValue.Text;
 End;
 PerlClose(Name,V);CurrPos:=Length(CurrLine)+1;
End;

Procedure DeleteCommand;
Var Name:String;V:TPerlValue;J:Integer;
Begin
 SkipSpace;Name:='';
 If(CurrPos<=Length(CurrLine))and(CurrLine[CurrPos]='$')Then Inc(CurrPos);
 J:=CurrPos;
 While(J<=Length(CurrLine))and(CurrLine[J]in['A'..'Z','a'..'z','0'..'9','_'])Do Inc(J);
 Name:=Copy(CurrLine,CurrPos,J-CurrPos);PerlDelete(Name,V);
 CurrPos:=Length(CurrLine)+1;
End;

Procedure ExecCommand;
Var
 Err:Word;
 Cmd,ArgList:String;
Begin
 Cmd:=GetStringValue;
 ArgList:='';
 If GetSeparator=','Then Begin
  Inc(CurrPos);
  ArgList:=GetStringValue;
 End;
 Exec(Cmd,ArgList);
 Err:=DosError;
 Case Err of
  0:;
  2:WriteLn('Commande ou nom de fichier non reconnu');
  Else Write(GetErrorMessage(Err));
 End;
End;

Procedure MkDirCommand;
Var
 Err:Word;
Begin
 {$I-}MkDir(GetStringValue);{$I+}
 Err:=IoResult;
 If Err<>0Then WriteLn(GetErrorMessage(Err));
End;

Procedure PrintCommand;
Var
 R:Real;
Begin
 If GetSeparator='"'Then Begin
  Write(FormatString(GetStringValue));
 End
  Else
 Begin
  R:=GetNumberValue;
  If Frac(R)=0.0Then WriteLn(R:0:0)
                Else WriteLn(R);
 End;
End;

Procedure RenameCommand;
Var
 Err:Word;
 F:File;
 Source,Target:String;
Begin
 Source:=GetStringValue;
 If GetSeparator=','Then Begin
  Inc(CurrPos);
  Target:=GetStringValue;
 End
  Else
 Begin
  WriteLn('Destination attendue !');
  Halt(2);
 End;
 {$I-}Assign(F,Source);
 Rename(F,Target);
 {$I+}
 Err:=IoResult;
 If Err=0Then WriteLn('1 fichier de renomme')
         Else WriteLn(GetErrorMessage(Err));
End;

Procedure RmDirCommand;
Var
 Err:Word;
Begin
 {$I-}RmDir(GetStringValue);{$I+}
 Err:=IoResult;
 If Err<>0Then WriteLn(GetErrorMessage(Err));
End;

Procedure SleepCommand;
Var
 R:Real;
Begin
 R:=GetNumberValue;
 Delay(Trunc(1000*R));
End;

Procedure SystemCommand;
Var
 Err:Word;
 Cmd,ArgList:String;
Begin
 Cmd:=GetStringValue;
 ArgList:='';
 If GetSeparator=','Then Begin
  Inc(CurrPos);
  ArgList:=GetStringValue;
 End;
 Exec(Cmd,ArgList);
 Err:=DosError;
 Case Err of
  0:;
  2:WriteLn('Commande ou nom de fichier non reconnu');
  Else Write(GetErrorMessage(Err));
 End;
End;

Procedure UnlinkCommand;
Var
 Err:Word;
 F:File;
Begin
 {$I-}Assign(F,GetStringValue);
 Erase(F);
 {$I+}
 Err:=IoResult;
 If Err=0Then WriteLn('1 fichier de supprim‚')
         Else WriteLn(GetErrorMessage(Err));
End;

Function FindAssignment(S:String):Integer;
Var J,Depth:Integer;Q:Char;
Begin
 Depth:=0;Q:=#0;FindAssignment:=0;
 For J:=1 To Length(S)Do Begin
  If Q<>#0 Then Begin If S[J]=Q Then Q:=#0;End
  Else If S[J]in['''','"']Then Q:=S[J]
  Else If S[J]='('Then Inc(Depth)Else If S[J]=')'Then Dec(Depth)
  Else If(Depth=0)and(S[J]='=')and((J=1)or Not(S[J-1]in['=','!','<','>','~']))and
    ((J=Length(S))or(S[J+1]<>'='))Then Begin FindAssignment:=J;Exit;End;
 End;
End;

Procedure PrintPerlExpressions(S:String);
Var J,StartPosition,Depth:Integer;Q:Char;Part:String;V:TPerlValue;
Begin
 S:=CleanText(S);
 If Copy(StrToUpper(S),1,6)='STDOUT'Then S:=CleanText(Copy(S,7,255));
 StartPosition:=1;Depth:=0;Q:=#0;J:=1;
 While J<=Length(S)+1Do Begin
  If J>Length(S)Then Begin Part:=Copy(S,StartPosition,J-StartPosition);EvalPerlExpression(Part,V);Write(V.Text);Break;End;
  If Q<>#0 Then Begin If S[J]=Q Then Q:=#0;End
  Else If S[J]in['''','"']Then Q:=S[J]
  Else If S[J]='('Then Inc(Depth)Else If S[J]=')'Then Dec(Depth)
  Else If(Depth=0)and(S[J]=',')Then Begin
   Part:=Copy(S,StartPosition,J-StartPosition);EvalPerlExpression(Part,V);Write(V.Text);StartPosition:=J+1;
  End;
  Inc(J);
 End;
End;

Procedure SetPerlArrayFromList(ArrayName,ListText:String);
Var J,StartPosition,Depth,ElementIndex:Integer;Quote:Char;Part:String;V:TPerlValue;
Begin
 ListText:=CleanText(ListText);
 If(Length(ListText)>1)and(ListText[1]='(')and
   (ListText[Length(ListText)]=')')Then
  ListText:=Copy(ListText,2,Length(ListText)-2);
 ClearPerlArray(ArrayName);StartPosition:=1;Depth:=0;Quote:=#0;ElementIndex:=0;
 For J:=1To Length(ListText)+1Do Begin
  If J<=Length(ListText)Then Begin
   If Quote<>#0Then Begin If ListText[J]=Quote Then Quote:=#0;End
   Else If ListText[J]in['''','"']Then Quote:=ListText[J]
   Else If ListText[J]in['(','[','{']Then Inc(Depth)
   Else If ListText[J]in[')',']','}']Then Dec(Depth);
  End;
  If(J>Length(ListText))or((Quote=#0)and(Depth=0)and(ListText[J]=','))Then Begin
   Part:=CleanText(Copy(ListText,StartPosition,J-StartPosition));
   If Part<>''Then Begin EvalPerlExpression(Part,V);
    SetPerlArrayElement(ArrayName,ElementIndex,V.Text);Inc(ElementIndex);End;
   StartPosition:=J+1;
  End;
 End;
End;

Procedure SetPerlHashFromList(HashName,ListText:String);
Var J,StartPosition,Depth,ArrowPosition:Integer;Quote:Char;PairText:String;
 KeyValue,ValueValue:TPerlValue;
Begin
 ListText:=CleanText(ListText);
 If(Length(ListText)>1)and(ListText[1]='(')and(ListText[Length(ListText)]=')')Then
  ListText:=Copy(ListText,2,Length(ListText)-2);
 ClearPerlHash(HashName);StartPosition:=1;Depth:=0;Quote:=#0;
 For J:=1To Length(ListText)+1Do Begin
  If J<=Length(ListText)Then Begin
   If Quote<>#0Then Begin If ListText[J]=Quote Then Quote:=#0;End
   Else If ListText[J]in['''','"']Then Quote:=ListText[J]
   Else If ListText[J]in['(','[','{']Then Inc(Depth)
   Else If ListText[J]in[')',']','}']Then Dec(Depth);
  End;
  If(J>Length(ListText))or((Quote=#0)and(Depth=0)and(ListText[J]=','))Then Begin
   PairText:=CleanText(Copy(ListText,StartPosition,J-StartPosition));
   ArrowPosition:=Pos('=>',PairText);
   If ArrowPosition>0Then Begin
    EvalPerlExpression(Copy(PairText,1,ArrowPosition-1),KeyValue);
    EvalPerlExpression(Copy(PairText,ArrowPosition+2,255),ValueValue);
    SetPerlHashEntry(HashName,KeyValue.Text,ValueValue.Text);
   End;
   StartPosition:=J+1;
  End;
 End;
End;

Procedure MyCommand;
Var Arguments,LeftText,RightText,Name,TempArray,SourceArray:String;
 P,J,K,ValueIndex,ValueCount,ArrayIndex:Integer;Sigil:Char;V,ArrayValue:TPerlValue;
Begin
 Arguments:=CleanText(Copy(CurrLine,CurrPos,255));P:=FindAssignment(Arguments);
 If P>0Then Begin LeftText:=CleanText(Copy(Arguments,1,P-1));
  RightText:=CleanText(Copy(Arguments,P+1,255));End
 Else Begin LeftText:=Arguments;RightText:='';End;
 If(Length(LeftText)>1)and(LeftText[1]='(')Then Begin
  K:=Pos(')',LeftText);If K>0Then LeftText:=Copy(LeftText,2,K-2);
  TempArray:='MYVALUES';SetPerlArrayFromList(TempArray,RightText);
  ValueCount:=GetPerlArrayCount(TempArray);ValueIndex:=0;J:=1;
  While J<=Length(LeftText)Do Begin
   While(J<=Length(LeftText))and Not(LeftText[J]in['$','@','%'])Do Inc(J);
   If J>Length(LeftText)Then Break;Sigil:=LeftText[J];Inc(J);Name:='';
   While(J<=Length(LeftText))and(LeftText[J]in['A'..'Z','a'..'z','0'..'9','_'])Do Begin
    Name:=Name+LeftText[J];Inc(J);End;
   If Sigil='$'Then Begin If ValueIndex<ValueCount Then GetPerlArrayElement(TempArray,ValueIndex,V)
    Else PerlText('',V);SetPerlVariable(Name,V.Text);End
   Else If Sigil='@'Then ClearPerlArray(Name)Else ClearPerlHash(Name);
   Inc(ValueIndex);
  End;
 End Else Begin
  J:=1;
  While J<=Length(LeftText)Do Begin
   While(J<=Length(LeftText))and Not(LeftText[J]in['$','@','%'])Do Inc(J);
   If J>Length(LeftText)Then Break;Sigil:=LeftText[J];Inc(J);Name:='';
   While(J<=Length(LeftText))and(LeftText[J]in['A'..'Z','a'..'z','0'..'9','_'])Do Begin
    Name:=Name+LeftText[J];Inc(J);End;
   If Sigil='$'Then Begin If RightText<>''Then EvalPerlExpression(RightText,V)Else PerlText('',V);
    SetPerlVariable(Name,V.Text);End
   Else If Sigil='@'Then Begin
    If RightText<>''Then Begin
     If Copy(StrToUpper(RightText),1,6)='SPLIT('Then Begin
      EvalPerlExpression(RightText,V);
      SourceArray:=Copy(V.Text,2,255);ClearPerlArray(Name);
      ValueCount:=GetPerlArrayCount(SourceArray);
      For ArrayIndex:=0To ValueCount-1Do Begin
       GetPerlArrayElement(SourceArray,ArrayIndex,ArrayValue);
       SetPerlArrayElement(Name,ArrayIndex,ArrayValue.Text);
      End;
     End Else SetPerlArrayFromList(Name,RightText);
    End Else ClearPerlArray(Name);
   End
   Else Begin If RightText<>''Then SetPerlHashFromList(Name,RightText)Else ClearPerlHash(Name);End;
  End;
 End;
 CurrPos:=Length(CurrLine)+1;
End;

Procedure LocalCommand;
Var Arguments,Name,RightText:String;P,J:Integer;V:TPerlValue;
Begin
 Arguments:=CleanText(Copy(CurrLine,CurrPos,255));
 If(Arguments='')or(Arguments[1]<>'$')Then Begin CurrPos:=Length(CurrLine)+1;Exit;End;
 J:=2;While(J<=Length(Arguments))and(Arguments[J]in['A'..'Z','a'..'z','0'..'9','_'])Do Inc(J);
 Name:=Copy(Arguments,2,J-2);P:=FindAssignment(Arguments);
 If P>0Then Begin RightText:=Copy(Arguments,P+1,255);EvalPerlExpression(RightText,V);End
 Else PerlText('',V);
 LocalizePerlVariable(Name,V.Text);CurrPos:=Length(CurrLine)+1;
End;

Procedure QxCommand;
Var Arguments:String;V,CommandValue:TPerlValue;
Begin
 Arguments:=CleanText(Copy(CurrLine,CurrPos,255));
 If(Length(Arguments)>1)and(Arguments[1]in['''','"'])Then
  Begin EvalPerlExpression(Arguments,CommandValue);PerlQx(CommandValue.Text,V);End
 Else PerlQx(Arguments,V);
 CurrPos:=Length(CurrLine)+1;
End;

Function ExecutePerlCoreLine(S:String):Boolean;
Var P,J,K:Integer;Name,RightSide,OperatorText,HashKeyText:String;
 V,OldValue,HashKeyValue:TPerlValue;
Begin
 ExecutePerlCoreLine:=True;S:=CleanText(S);
 If(S='')or(S[1]='#')or(Copy(S,1,2)='#!')Then Exit;
 If(S[1]in['0'..'9'])and(Pos('=',S)=0)Then Exit;
 If Copy(StrToUpper(S),1,6)='PRINT 'Then Begin PrintPerlExpressions(Copy(S,7,255));Exit;End;
 If Copy(StrToUpper(S),1,3)='MY 'Then S:=CleanText(Copy(S,4,255));
 If(Length(S)>1)and(S[1]='@')Then Begin
  J:=2;While(J<=Length(S))and(S[J]in['A'..'Z','a'..'z','0'..'9','_'])Do Inc(J);
  Name:=Copy(S,2,J-2);P:=FindAssignment(S);
  If P>0Then Begin SetPerlArrayFromList(Name,Copy(S,P+1,255));Exit;End;
 End;
 If(Length(S)>1)and(S[1]='$')Then Begin
  J:=2;While(J<=Length(S))and(S[J]in['A'..'Z','a'..'z','0'..'9','_'])Do Inc(J);
  Name:=Copy(S,2,J-2);P:=FindAssignment(S);
  If P>0Then Begin
   OperatorText:='=';If(P>1)and(S[P-1]in['.','+','-','*','/'])Then Begin OperatorText:=S[P-1]+'=';End;
   RightSide:=Copy(S,P+1,255);EvalPerlExpression(RightSide,V);
   If OperatorText<>'='Then Begin
    GetPerlVariable(Name,OldValue);
    If OperatorText='.='Then PerlText(OldValue.Text+V.Text,V)
    Else If OperatorText='+='Then PerlNumber(OldValue.Number+V.Number,V)
    Else If OperatorText='-='Then PerlNumber(OldValue.Number-V.Number,V)
    Else If OperatorText='*='Then PerlNumber(OldValue.Number*V.Number,V)
    Else If(OperatorText='/=')and(V.Number<>0)Then PerlNumber(OldValue.Number/V.Number,V);
   End;
   If(J<=Length(S))and(S[J]='{')Then Begin
    K:=J+1;While(K<=Length(S))and(S[K]<>'}')Do Inc(K);
    HashKeyText:=Copy(S,J+1,K-J-1);EvalPerlExpression(HashKeyText,HashKeyValue);
    SetPerlHashEntry(Name,HashKeyValue.Text,V.Text);
   End Else If(J<=Length(S))and(S[J]='[')Then Begin
    K:=J+1;While(K<=Length(S))and(S[K]<>']')Do Inc(K);
    HashKeyText:=Copy(S,J+1,K-J-1);EvalPerlExpression(HashKeyText,HashKeyValue);
    SetPerlArrayElement(Name,Trunc(HashKeyValue.Number),V.Text);
   End Else SetPerlVariable(Name,V.Text);
   Exit;
  End;
 End;
 ExecutePerlCoreLine:=False;
End;

Function CountCharacter(S:String;Wanted:Char):Integer;
Var J,Count:Integer;Quote:Char;
Begin
 Count:=0;Quote:=#0;
 For J:=1To Length(S)Do Begin
  If Quote<>#0Then Begin If S[J]=Quote Then Quote:=#0;End
  Else If S[J]in['''','"']Then Quote:=S[J]
  Else If S[J]=Wanted Then Inc(Count);
 End;
 CountCharacter:=Count;
End;

Procedure ExecuteForIncrement(S:String);
Var Name:String;J:Integer;OldValue,NewValue:TPerlValue;
Begin
 S:=CleanText(S);
 If(Length(S)>=3)and(S[1]='$')and
   ((Copy(S,Length(S)-1,2)='++')or(Copy(S,Length(S)-1,2)='--'))Then Begin
  J:=2;While(J<=Length(S))and(S[J]in['A'..'Z','a'..'z','0'..'9','_'])Do Inc(J);
  Name:=Copy(S,2,J-2);GetPerlVariable(Name,OldValue);
  If Copy(S,Length(S)-1,2)='++'Then PerlNumber(OldValue.Number+1,NewValue)
  Else PerlNumber(OldValue.Number-1,NewValue);
  SetPerlVariable(Name,NewValue.Text);
 End Else ExecutePerlCoreLine(S);
End;

Procedure ForCommand;
Var Header,InitText,ConditionText,IncrementText:String;
 P1,P2,J,Depth,ForLine,EndLine,BodyLine,Guard:Integer;Condition:TPerlValue;
Begin
 ForLine:=CurrLinePtr;
 Header:=CleanText(Copy(CurrLine,CurrPos,255));
 If(Length(Header)>0)and(Header[1]='(')Then Delete(Header,1,1);
 J:=Pos(')',Header);If J>0Then Delete(Header,J,255);
 P1:=Pos(';',Header);P2:=0;
 If P1>0Then Begin J:=P1+1;While(J<=Length(Header))and(Header[J]<>';')Do Inc(J);P2:=J;End;
 If(P1=0)or(P2=0)Then Begin CurrPos:=Length(CurrLine)+1;Exit;End;
 InitText:=CleanText(Copy(Header,1,P1-1));
 ConditionText:=CleanText(Copy(Header,P1+1,P2-P1-1));
 IncrementText:=CleanText(Copy(Header,P2+1,255));
 Depth:=CountCharacter(CurrLine,'{')-CountCharacter(CurrLine,'}');
 EndLine:=CurrLinePtr;
 While(Depth>0)and(EndLine<NumberLine)Do Begin
  Inc(EndLine);Depth:=Depth+CountCharacter(PA[EndLine]^,'{')-
   CountCharacter(PA[EndLine]^,'}');
 End;
 If EndLine=CurrLinePtr Then Begin CurrPos:=Length(CurrLine)+1;Exit;End;
 ExecutePerlCoreLine(InitText);Guard:=0;
 Repeat
  EvalPerlExpression(ConditionText,Condition);
  If(Condition.Text='')or(Condition.Text='0')Then Break;
  BodyLine:=ForLine+1;
  While(BodyLine<EndLine)and Not Terminated Do Begin
   ExecuteStoredLine(BodyLine);BodyLine:=CurrLinePtr+1;
  End;
  If PerlReturning Then Break;
  ExecuteForIncrement(IncrementText);Inc(Guard);
 Until Guard=32767;
 CurrLinePtr:=EndLine;CurrPos:=Length(CurrLine)+1;
End;

Procedure ForeachCommand;
Var Header,VariableName,ListText,ArrayName,IndexText:String;
 J,P,Depth,ForeachLine,EndLine,BodyLine,ElementIndex,ElementCount:Integer;
 ElementValue:TPerlValue;
Begin
 ForeachLine:=CurrLinePtr;Header:=CleanText(Copy(CurrLine,CurrPos,255));
 If Copy(StrToUpper(Header),1,3)='MY 'Then Header:=CleanText(Copy(Header,4,255));
 If(Length(Header)=0)or(Header[1]<>'$')Then Begin CurrPos:=Length(CurrLine)+1;Exit;End;
 J:=2;While(J<=Length(Header))and(Header[J]in['A'..'Z','a'..'z','0'..'9','_'])Do Inc(J);
 VariableName:=Copy(Header,2,J-2);P:=Pos('(',Header);
 If P=0Then Begin CurrPos:=Length(CurrLine)+1;Exit;End;
 J:=Length(Header);While(J>P)and(Header[J]<>')')Do Dec(J);
 If J<=P Then Begin CurrPos:=Length(CurrLine)+1;Exit;End;
 ListText:=CleanText(Copy(Header,P+1,J-P-1));
 If(Length(ListText)>0)and(ListText[1]='@')Then ArrayName:=Copy(ListText,2,255)
 Else Begin
  Str(ForeachLine,IndexText);ArrayName:='FOREACH'+CleanText(IndexText);
  SetPerlArrayFromList(ArrayName,ListText);
 End;
 Depth:=CountCharacter(CurrLine,'{')-CountCharacter(CurrLine,'}');
 EndLine:=ForeachLine;
 While(Depth>0)and(EndLine<NumberLine)Do Begin
  Inc(EndLine);Depth:=Depth+CountCharacter(PA[EndLine]^,'{')-
   CountCharacter(PA[EndLine]^,'}');
 End;
 ElementCount:=GetPerlArrayCount(ArrayName);
 For ElementIndex:=0To ElementCount-1Do Begin
  GetPerlArrayElement(ArrayName,ElementIndex,ElementValue);
  SetPerlVariable(VariableName,ElementValue.Text);BodyLine:=ForeachLine+1;
  While(BodyLine<EndLine)and Not Terminated Do Begin
   ExecuteStoredLine(BodyLine);BodyLine:=CurrLinePtr+1;
  End;
  If PerlReturning Then Break;
 End;
 CurrLinePtr:=EndLine;CurrLine:=PA[EndLine]^;CurrPos:=Length(CurrLine)+1;
End;

Function PerlConditionFromLine(S:String;Var Condition:TPerlValue):Boolean;
Var P1,P2,J:Integer;ExpressionText:String;
Begin
 P1:=Pos('(',S);P2:=0;
 If P1>0Then For J:=Length(S)DownTo P1+1Do If S[J]=')'Then Begin P2:=J;Break;End;
 If(P1=0)or(P2<=P1)Then Begin PerlConditionFromLine:=False;Exit;End;
 ExpressionText:=Copy(S,P1+1,P2-P1-1);EvalPerlExpression(ExpressionText,Condition);
 PerlConditionFromLine:=True;
End;

Function PerlBlockEnd(HeaderLine:Integer;HeaderClosesPrevious:Boolean):Integer;
Var Depth,J,K:Integer;Quote:Char;S:String;
Begin
 If HeaderClosesPrevious Then Begin Depth:=1;J:=HeaderLine+1;End
 Else Begin Depth:=0;J:=HeaderLine;End;
 While J<=NumberLine Do Begin
  S:=PA[J]^;Quote:=#0;
  For K:=1To Length(S)Do Begin
   If Quote<>#0Then Begin If S[K]=Quote Then Quote:=#0;End
   Else If S[K]in['''','"']Then Quote:=S[K]
   Else If S[K]='{'Then Inc(Depth)
   Else If S[K]='}'Then Begin Dec(Depth);If Depth=0Then Begin PerlBlockEnd:=J;Exit;End;End;
  End;
  Inc(J);
 End;
 PerlBlockEnd:=NumberLine;
End;

Procedure ExecutePerlBlock(FirstLine,LastLine:Integer);
Var LineIndex:Integer;
Begin
 Inc(PerlScopeDepth);
 LineIndex:=FirstLine;
 While(LineIndex<=LastLine)and Not Terminated and Not PerlReturning Do Begin
  ExecuteStoredLine(LineIndex);LineIndex:=CurrLinePtr+1;
 End;
 RestorePerlScope(PerlScopeDepth);Dec(PerlScopeDepth);
End;

Function FindPerlSubroutine(Name:String):PPerlSubroutine;
Var Subroutine:PPerlSubroutine;
Begin
 Name:=StrToUpper(Name);Subroutine:=PerlSubroutines;
 While Subroutine<>Nil Do Begin
  If Subroutine^.Name=Name Then Begin FindPerlSubroutine:=Subroutine;Exit;End;
  Subroutine:=Subroutine^.Next;
 End;
 FindPerlSubroutine:=Nil;
End;

Procedure RegisterPerlSubroutines;
Var LineIndex,J:Integer;S,Name,PackageName:String;Subroutine:PPerlSubroutine;
Begin
 PackageName:='main';
 For LineIndex:=1To NumberLine Do Begin
  S:=CleanText(PA[LineIndex]^);
  If Copy(StrToUpper(S),1,8)='PACKAGE 'Then Begin
   PackageName:=CleanText(Copy(S,9,255));If PackageName=''Then PackageName:='main';
  End Else If Copy(StrToUpper(S),1,4)='SUB 'Then Begin
   J:=5;While(J<=Length(S))and(S[J]in[' ',#9])Do Inc(J);Name:='';
   While(J<=Length(S))and(S[J]in['A'..'Z','a'..'z','0'..'9','_'])Do Begin
    Name:=Name+S[J];Inc(J);
   End;
   If(Name<>'')and(FindPerlSubroutine(Name)=Nil)Then Begin
    New(Subroutine);Subroutine^.Name:=StrToUpper(Name);Subroutine^.PackageName:=PackageName;
    Subroutine^.HeaderLine:=LineIndex;
    Subroutine^.EndLine:=PerlBlockEnd(LineIndex,False);
    Subroutine^.Next:=PerlSubroutines;PerlSubroutines:=Subroutine;
   End;
  End;
 End;
End;

Procedure PerlInvokeSubroutine(Name:String;Var A,B,C:TPerlValue;
 ArgumentCount:Integer;Var V:TPerlValue);
Var Subroutine:PPerlSubroutine;SavedLinePtr,SavedPosition,I,SavedCount,Depth:Integer;
 SavedLine,SavedSource,SaveArrayName:String;SavedExprPosition:Integer;
 SavedReturning:Boolean;SavedReturnValue,Item:TPerlValue;Frame:PPerlCallFrame;
Begin
 Subroutine:=FindPerlSubroutine(Name);If Subroutine=Nil Then Begin PerlText('',V);Exit;End;
 Depth:=0;Frame:=PerlCallStack;While Frame<>Nil Do Begin Inc(Depth);Frame:=Frame^.Next;End;
 Str(Depth,SaveArrayName);SaveArrayName:='CALLSAVE'+CleanText(SaveArrayName);
 SavedCount:=GetPerlArrayCount('_');ClearPerlArray(SaveArrayName);
 For I:=0To SavedCount-1Do Begin GetPerlArrayElement('_',I,Item);
  SetPerlArrayElement(SaveArrayName,I,Item.Text);End;
 ClearPerlArray('_');If ArgumentCount>0Then SetPerlArrayElement('_',0,A.Text);
 If ArgumentCount>1Then SetPerlArrayElement('_',1,B.Text);
 If ArgumentCount>2Then SetPerlArrayElement('_',2,C.Text);
 SavedLinePtr:=CurrLinePtr;SavedLine:=CurrLine;SavedPosition:=CurrPos;
 SavedSource:=ExprSource;SavedExprPosition:=ExprPosition;
 SavedReturning:=PerlReturning;SavedReturnValue:=PerlReturnValue;
 PerlReturning:=False;PerlText('',PerlReturnValue);
 PushPerlCallFrame(Name,Subroutine^.PackageName,FileName,CurrNumberLine,ArgumentCount>0);
 ExecutePerlBlock(Subroutine^.HeaderLine+1,Subroutine^.EndLine-1);
 V:=PerlReturnValue;PopPerlCallFrame;
 ClearPerlArray('_');For I:=0To SavedCount-1Do Begin
  GetPerlArrayElement(SaveArrayName,I,Item);SetPerlArrayElement('_',I,Item.Text);End;
 PerlReturning:=SavedReturning;PerlReturnValue:=SavedReturnValue;
 CurrLinePtr:=SavedLinePtr;CurrLine:=SavedLine;CurrPos:=SavedPosition;
 ExprSource:=SavedSource;ExprPosition:=SavedExprPosition;
End;

Procedure ReturnCommand;
Var ExpressionText:String;
Begin
 ExpressionText:=CleanText(Copy(CurrLine,CurrPos,255));
 If ExpressionText=''Then PerlText('',PerlReturnValue)
 Else EvalPerlExpression(ExpressionText,PerlReturnValue);
 PerlReturning:=True;CurrPos:=Length(CurrLine)+1;
End;

Procedure SubCommand;
Var Subroutine:PPerlSubroutine;
Begin
 Subroutine:=PerlSubroutines;
 While(Subroutine<>Nil)and(Subroutine^.HeaderLine<>CurrLinePtr)Do Subroutine:=Subroutine^.Next;
 If Subroutine<>Nil Then CurrLinePtr:=Subroutine^.EndLine;
 CurrLine:=PA[CurrLinePtr]^;CurrPos:=Length(CurrLine)+1;
End;

Function FindPerlModule(Name:String):PPerlModule;
Var Module:PPerlModule;
Begin
 Module:=PerlModules;Name:=StrToUpper(Name);
 While Module<>Nil Do Begin
  If Module^.Name=Name Then Begin FindPerlModule:=Module;Exit;End;
  Module:=Module^.Next;
 End;
 FindPerlModule:=Nil;
End;

Function PerlModuleLine(LineIndex:Integer):Boolean;
Var Module:PPerlModule;
Begin
 Module:=PerlModules;
 While Module<>Nil Do Begin
  If(LineIndex>=Module^.FirstLine)and(LineIndex<=Module^.LastLine)Then Begin
   PerlModuleLine:=True;Exit;
  End;
  Module:=Module^.Next;
 End;
 PerlModuleLine:=False;
End;

Procedure UseCommand;
Var Arguments,UpperArguments,ModuleName,SavedLine:String;
 ModuleFile,ResolvedPath:PathStr;ScriptDirectory:DirStr;
 DummyName:NameStr;DummyExtension:ExtStr;
 P,J,SavedLinePtr,SavedPosition,FirstModuleLine:Integer;
 Module:PPerlModule;ModuleSource:Text;V:TPerlValue;
Begin
 Arguments:=CleanText(Copy(CurrLine,CurrPos,255));UpperArguments:=StrToUpper(Arguments);
 If(UpperArguments='STRICT')or(Copy(UpperArguments,1,7)='STRICT ')Then Begin
  PerlStrictEnabled:=True;CurrPos:=Length(CurrLine)+1;Exit;End;
 If(UpperArguments='WARNINGS')or(Copy(UpperArguments,1,9)='WARNINGS ')Then Begin
  PerlWarningsEnabled:=True;CurrPos:=Length(CurrLine)+1;Exit;End;
 If Copy(UpperArguments,1,4)='LIB 'Then Begin
  EvalPerlExpression(Copy(Arguments,5,255),V);
  If V.Text<>''Then Begin If PerlIncludePath<>''Then PerlIncludePath:=PerlIncludePath+';';
   PerlIncludePath:=PerlIncludePath+V.Text;End;
  CurrPos:=Length(CurrLine)+1;Exit;
 End;
 If(Arguments='')or(Arguments[1]in['0'..'9'])Then Begin CurrPos:=Length(CurrLine)+1;Exit;End;
 J:=1;While(J<=Length(Arguments))and(Arguments[J]in['A'..'Z','a'..'z','0'..'9','_',':'])Do Inc(J);
 ModuleName:='';P:=1;
 While P<J Do Begin ModuleName:=ModuleName+Arguments[P];Inc(P);End;
 If FindPerlModule(ModuleName)<>Nil Then Begin CurrPos:=Length(CurrLine)+1;Exit;End;
 ModuleFile:='';J:=1;
 While J<=Length(ModuleName)Do Begin
  If(J<Length(ModuleName))and(Copy(ModuleName,J,2)='::')Then Begin ModuleFile:=ModuleFile+'\';Inc(J,2);End
  Else Begin ModuleFile:=ModuleFile+ModuleName[J];Inc(J);End;
 End;
 ModuleFile:=ModuleFile+'.pm';FSplit(FileName,ScriptDirectory,DummyName,DummyExtension);
 ResolvedPath:='';If PerlFileExists(ScriptDirectory+ModuleFile)Then ResolvedPath:=ScriptDirectory+ModuleFile
 Else If PerlFileExists(ModuleFile)Then ResolvedPath:=ModuleFile
 Else ResolvedPath:=FSearch(ModuleFile,PerlIncludePath);
 If ResolvedPath=''Then Begin WriteLn('Module Perl introuvable: ',ModuleName);Terminated:=True;
  CurrPos:=Length(CurrLine)+1;Exit;End;
 Assign(ModuleSource,ResolvedPath);{$I-}Reset(ModuleSource);{$I+}
 If IoResult<>0Then Begin WriteLn('Impossible d''ouvrir le module: ',ResolvedPath);Terminated:=True;Exit;End;
 New(Module);Module^.Name:=StrToUpper(ModuleName);Module^.PathName:=ResolvedPath;
 FirstModuleLine:=NumberLine+1;Module^.FirstLine:=FirstModuleLine;
 While Not Eof(ModuleSource)Do Begin ReadLn(ModuleSource,SavedLine);AddLine(SavedLine);End;
 Close(ModuleSource);Module^.LastLine:=NumberLine;Module^.Next:=PerlModules;PerlModules:=Module;
 RegisterPerlSubroutines;SavedLinePtr:=CurrLinePtr;SavedLine:=CurrLine;SavedPosition:=CurrPos;
 Inc(PerlModuleExecutionDepth);P:=Module^.FirstLine;
 While(P<=Module^.LastLine)and Not Terminated Do Begin ExecuteStoredLine(P);P:=CurrLinePtr+1;End;
 Dec(PerlModuleExecutionDepth);CurrLinePtr:=SavedLinePtr;CurrLine:=SavedLine;
 CurrPos:=Length(CurrLine)+1;
End;

Procedure IfCommand;
Var HeaderLine,CloseLine,MarkerLine,NextClose:Integer;
 HeaderUpper:String;Condition:TPerlValue;ConditionTrue,BranchChosen,HasBranch:Boolean;
Begin
 HeaderLine:=CurrLinePtr;
 If PerlConditionFromLine(CurrLine,Condition)Then
  ConditionTrue:=(Condition.Text<>'')and(Condition.Text<>'0')
 Else ConditionTrue:=False;
 CloseLine:=PerlBlockEnd(HeaderLine,False);BranchChosen:=ConditionTrue;
 If ConditionTrue Then ExecutePerlBlock(HeaderLine+1,CloseLine-1);
 Repeat
  MarkerLine:=CloseLine;HeaderUpper:=StrToUpper(CleanText(PA[MarkerLine]^));
  HasBranch:=(Pos('ELSIF',HeaderUpper)>0)or(Pos('ELSE',HeaderUpper)>0);
  If Not HasBranch Then Begin
   MarkerLine:=CloseLine+1;
   If MarkerLine<=NumberLine Then HeaderUpper:=StrToUpper(CleanText(PA[MarkerLine]^))
   Else HeaderUpper:='';
   HasBranch:=(Copy(HeaderUpper,1,5)='ELSIF')or(Copy(HeaderUpper,1,4)='ELSE');
  End;
  If Not HasBranch Then Break;
  NextClose:=PerlBlockEnd(MarkerLine,Pos('}',PA[MarkerLine]^) > 0);
  If Not BranchChosen Then Begin
   If Pos('ELSIF',HeaderUpper)>0 Then Begin
    If PerlConditionFromLine(PA[MarkerLine]^,Condition)Then
     ConditionTrue:=(Condition.Text<>'')and(Condition.Text<>'0')
    Else ConditionTrue:=False;
   End Else ConditionTrue:=True;
   If ConditionTrue Then Begin
    ExecutePerlBlock(MarkerLine+1,NextClose-1);BranchChosen:=True;
   End;
  End;
  CloseLine:=NextClose;
 Until False;
 CurrLinePtr:=CloseLine;CurrLine:=PA[CloseLine]^;CurrPos:=Length(CurrLine)+1;
End;

Procedure WhileCommand;
Var HeaderText:String;HeaderLine,CloseLine:Integer;
 Condition:TPerlValue;ConditionTrue:Boolean;
Begin
 HeaderLine:=CurrLinePtr;HeaderText:=CurrLine;
 CloseLine:=PerlBlockEnd(HeaderLine,False);
 Repeat
  If PerlConditionFromLine(HeaderText,Condition)Then
   ConditionTrue:=(Condition.Text<>'')and(Condition.Text<>'0')
  Else ConditionTrue:=False;
  If Not ConditionTrue Then Break;
  ExecutePerlBlock(HeaderLine+1,CloseLine-1);
 Until Terminated or PerlReturning;
 CurrLinePtr:=CloseLine;CurrLine:=PA[CloseLine]^;CurrPos:=Length(CurrLine)+1;
End;

Function PerlIntegerBase(Value:LongInt;NumberBase:Integer;UpperCase:Boolean):String;
Const LowerDigits='0123456789abcdef';UpperDigits='0123456789ABCDEF';
Var Digits,ResultText:String;Digit:Integer;Negative:Boolean;
Begin
 If UpperCase Then Digits:=UpperDigits Else Digits:=LowerDigits;
 Negative:=Value<0;If Negative Then Value:=-Value;ResultText:='';
 Repeat
  Digit:=Value mod NumberBase;ResultText:=Digits[Digit+1]+ResultText;
  Value:=Value div NumberBase;
 Until Value=0;
 If Negative Then ResultText:='-'+ResultText;PerlIntegerBase:=ResultText;
End;

Procedure PrintfCommand;
Var Arguments,ArrayName,FormatText,OutputText,Piece:String;
 I,J,ArgumentIndex,ArgumentCount,Width,Precision:Integer;
 LeftAlign,ZeroFill,ShowSign:Boolean;Conversion:Char;V:TPerlValue;N:LongInt;
Begin
 Arguments:=CleanText(Copy(CurrLine,CurrPos,255));ArrayName:='PRINTFARGS';
 SetPerlArrayFromList(ArrayName,Arguments);ArgumentCount:=GetPerlArrayCount(ArrayName);
 If ArgumentCount=0Then Begin CurrPos:=Length(CurrLine)+1;Exit;End;
 GetPerlArrayElement(ArrayName,0,V);FormatText:=V.Text;OutputText:='';
 I:=1;ArgumentIndex:=1;
 While I<=Length(FormatText)Do Begin
  If FormatText[I]<>'%'Then Begin OutputText:=OutputText+FormatText[I];Inc(I);Continue;End;
  Inc(I);If(I<=Length(FormatText))and(FormatText[I]='%')Then Begin
   OutputText:=OutputText+'%';Inc(I);Continue;
  End;
  LeftAlign:=False;ZeroFill:=False;ShowSign:=False;
  While(I<=Length(FormatText))and(FormatText[I]in['-','0','+',' '])Do Begin
   If FormatText[I]='-'Then LeftAlign:=True Else If FormatText[I]='0'Then ZeroFill:=True
   Else If FormatText[I]='+'Then ShowSign:=True;Inc(I);
  End;
  Width:=0;While(I<=Length(FormatText))and(FormatText[I]in['0'..'9'])Do Begin
   Width:=Width*10+Ord(FormatText[I])-Ord('0');Inc(I);End;
  Precision:=-1;
  If(I<=Length(FormatText))and(FormatText[I]='.')Then Begin Inc(I);Precision:=0;
   While(I<=Length(FormatText))and(FormatText[I]in['0'..'9'])Do Begin
    Precision:=Precision*10+Ord(FormatText[I])-Ord('0');Inc(I);End;
  End;
  If I>Length(FormatText)Then Break;Conversion:=FormatText[I];Inc(I);
  If ArgumentIndex<ArgumentCount Then GetPerlArrayElement(ArrayName,ArgumentIndex,V)
  Else PerlText('',V);Inc(ArgumentIndex);Piece:='';N:=Trunc(V.Number);
  Case Conversion of
   's':Begin Piece:=V.Text;If(Precision>=0)and(Length(Piece)>Precision)Then
        Piece:=Copy(Piece,1,Precision);End;
   'd','i':Str(N,Piece);
   'u':If N<0Then Piece:=PerlNumberText(4294967296.0+N) Else Str(N,Piece);
   'x':Piece:=PerlIntegerBase(N,16,False);
   'X':Piece:=PerlIntegerBase(N,16,True);
   'o':Piece:=PerlIntegerBase(N,8,False);
   'c':Piece:=Chr(N mod 256);
   'f':Begin If Precision<0Then Precision:=6;Str(V.Number:0:Precision,Piece);End;
   'e','E':Begin Str(V.Number,Piece);If Conversion='E'Then Piece:=StrToUpper(Piece);End;
   'g','G':Piece:=PerlNumberText(V.Number);
   Else Piece:='%'+Conversion;
  End;
  Piece:=CleanText(Piece);If ShowSign and(V.Number>=0)and(Conversion in['d','i','f','e','E','g','G'])Then Piece:='+'+Piece;
  If Width>Length(Piece)Then Begin
   J:=Width-Length(Piece);
   If LeftAlign Then While J>0Do Begin Piece:=Piece+' ';Dec(J);End
   Else If ZeroFill Then Begin
    If(Length(Piece)>0)and(Piece[1]in['+','-'])Then Begin
     OutputText:=OutputText+Piece[1];Delete(Piece,1,1);End;
    While J>0Do Begin Piece:='0'+Piece;Dec(J);End;
   End Else While J>0Do Begin Piece:=' '+Piece;Dec(J);End;
  End;
  OutputText:=OutputText+Piece;
 End;
 Write(OutputText);CurrPos:=Length(CurrLine)+1;
End;

Function FindPerlFormat(Name:String):PPerlFormat;
Var F:PPerlFormat;
Begin
 Name:=StrToUpper(CleanText(Name));F:=PerlFormats;
 While F<>Nil Do Begin If F^.Name=Name Then Begin FindPerlFormat:=F;Exit;End;F:=F^.Next;End;
 FindPerlFormat:=Nil;
End;

Procedure ClearPerlFormatLines(F:PPerlFormat);
Var L:PPerlFormatLine;
Begin
 While F^.FirstLine<>Nil Do Begin L:=F^.FirstLine;F^.FirstLine:=L^.Next;Dispose(L);End;
 F^.LastLine:=Nil;
End;

Procedure FormatCommand;
Var Name:String;P,J:Integer;F:PPerlFormat;L:PPerlFormatLine;
Begin
 Name:=CleanText(Copy(CurrLine,CurrPos,255));P:=Pos('=',Name);
 If P>0Then Name:=CleanText(Copy(Name,1,P-1));If Name=''Then Name:='STDOUT';
 Name:=StrToUpper(Name);F:=FindPerlFormat(Name);
 If F=Nil Then Begin New(F);F^.Name:=Name;F^.FirstLine:=Nil;F^.LastLine:=Nil;
  F^.Next:=PerlFormats;PerlFormats:=F;End Else ClearPerlFormatLines(F);
 J:=CurrLinePtr+1;
 While(J<=NumberLine)and(CleanText(PA[J]^)<>'.')Do Begin
  New(L);L^.Text:=PA[J]^;L^.Next:=Nil;
  If F^.FirstLine=Nil Then F^.FirstLine:=L Else F^.LastLine^.Next:=L;
  F^.LastLine:=L;Inc(J);
 End;
 CurrLinePtr:=J;If J<=NumberLine Then CurrLine:=PA[J]^;
 CurrPos:=Length(CurrLine)+1;
End;

Procedure WriteFormatCommand;
Var Name,OutputText:String;F:PPerlFormat;L:PPerlFormatLine;V:TPerlValue;
 Width:Integer;
Begin
 Name:=StrToUpper(CleanText(Copy(CurrLine,CurrPos,255)));
 If Name=''Then Name:='STDOUT';F:=FindPerlFormat(Name);
 If(F=Nil)and(PerlFormats<>Nil)Then F:=PerlFormats;
 If F<>Nil Then Begin
  L:=F^.FirstLine;
  While L<>Nil Do Begin
   If Pos('@',L^.Text)>0Then Begin
    Width:=Length(L^.Text);L:=L^.Next;
    If L<>Nil Then Begin EvalPerlExpression(CleanText(L^.Text),V);OutputText:=V.Text;
     While Length(OutputText)<Width Do OutputText:=OutputText+' ';WriteLn(OutputText);End;
   End Else WriteLn(L^.Text);
   If L<>Nil Then L:=L^.Next;
  End;
 End;
 CurrPos:=Length(CurrLine)+1;
End;

Function RunLine:Boolean;
Var
 UnknownCommand:Boolean;
 NoImplementation:Boolean;
 J,Err:Integer;
Begin
 RunLine:=False;
 If ExecutePerlCoreLine(CurrLine)Then Begin RunLine:=True;Exit;End;
 Repeat
  NoImplementation:=False;
  UnknownCommand:=False;
  If CurrLine[CurrPos]='#'Then Begin
   CurrPos:=Length(CurrLine)+1;
   RunLine:=True;
   Exit;
  End
   Else
  Case ExtractCommand of
   0:NoImplementation:=True;{abs}
   1:NoImplementation:=True;{alarm}
   2:NoImplementation:=True;{atan2}
   3:BinModeCommand;{binmode}
   4:NoImplementation:=True;{caller}
   5:ChDirCommand;{chdir}
   6:BareFunctionCommand('chmod');{chmod}
   7:ChompCommand;{chomp}
   8:ChopCommand;{chop}
   9:BareFunctionCommand('chown');{chown}
   10:BareFunctionCommand('chr');{chr}
   11:BareFunctionCommand('chroot');{chroot}
   12:CloseCommand;{close}
   13:BareFunctionCommand('closedir');{closedir}
   14:BareFunctionCommand('cos');{cos}
   15:BareFunctionCommand('crypt');{crypt}
   16:BareFunctionCommand('defined');{defined}
   17:DeleteCommand;{delete}
   18:Begin {die}
    Terminated:=True;
    Exit;
   End;
   19:BareFunctionCommand('each');{each}
   20:NoImplementation:=True;{endgrent}
   21:NoImplementation:=True;{endhostent}
   22:NoImplementation:=True;{endnetent}
   23:NoImplementation:=True;{endprotoent}
   24:NoImplementation:=True;{endpwent}
   25:NoImplementation:=True;{endservent}
   26:BareFunctionCommand('eof');{eof}
   27:BareFunctionCommand('eval');{eval}
   28:ExecCommand;{exec}
   29:BareFunctionCommand('exists');{exists}
   30:Begin {exit}
    Terminated:=True;
    Exit;
   End;
   31:BareFunctionCommand('exp');{exp}
   32:BareFunctionCommand('fileno');{fileno}
   33:BareFunctionCommand('flock');{flock}
   34:ForCommand;{for}
   35:ForeachCommand;{foreach}
   36:NoImplementation:=True;{fork}
   37:FormatCommand;{format}
   38:BareFunctionCommand('getc');{getc}
   39:NoImplementation:=True;{getgrent}
   40:NoImplementation:=True;{getgrgid}
   41:NoImplementation:=True;{getgrnam}
   42:NoImplementation:=True;{gethostbyaddr}
   43:NoImplementation:=True;{gethostbyname}
   44:NoImplementation:=True;{gethostent}
   45:NoImplementation:=True;{getlogin}
   46:NoImplementation:=True;{getnetbyaddr}
   47:NoImplementation:=True;{getnetbyname}
   48:NoImplementation:=True;{getnetent}
   49:NoImplementation:=True;{getpgrp}
   50:NoImplementation:=True;{getppid}
   51:NoImplementation:=True;{getpriority}
   52:NoImplementation:=True;{getprotobyname}
   53:NoImplementation:=True;{getprotobynumber}
   54:NoImplementation:=True;{getprotoent}
   55:NoImplementation:=True;{getpwent}
   56:NoImplementation:=True;{getpwnam}
   57:NoImplementation:=True;{getpwuid}
   58:NoImplementation:=True;{getservbyname}
   59:NoImplementation:=True;{getservbyport}
   60:NoImplementation:=True;{getserent}
   61:BareFunctionCommand('gmtime');{gmtime}
   62:BareFunctionCommand('grep');{grep}
   63:BareFunctionCommand('glob');{glob}
   64:BareFunctionCommand('hex');{hex}
   65:IfCommand;{if}
   66:BareFunctionCommand('index');{index}
   67:BareFunctionCommand('int');{int}
   68:BareFunctionCommand('join');{join}
   69:BareFunctionCommand('keys');{keys}
   70:BareFunctionCommand('kill');{kill}
   71:BareFunctionCommand('lc');{lc}
   72:BareFunctionCommand('lcfirst');{lcfirst}
   73:BareFunctionCommand('length');{length}
   74:BareFunctionCommand('link');{link}
   75:LocalCommand;{local}
   76:BareFunctionCommand('localtime');{localtime}
   77:BareFunctionCommand('log');{log}
   78:BareFunctionCommand('lstat');{lstat}
   79:BareFunctionCommand('map');{map}
   80:MkDirCommand;{mkdir}
   81:MyCommand;{my}
   82:BareFunctionCommand('oct');{oct}
   83:BareFunctionCommand('open');{open}
   84:BareFunctionCommand('opendir');{opendir}
   85:BareFunctionCommand('ord');{ord}
   86:BareFunctionCommand('pack');{pack}
   87:PackageCommand;{package}
   88:BareFunctionCommand('pipe');{pipe}
   89:BareFunctionCommand('pop');{pop}
   90:BareFunctionCommand('pos');{pos}
   91:PrintCommand;{print}
   92:PrintfCommand;{printf}
   93:BareFunctionCommand('push');{push}
   94:BareFunctionCommand('quotameta');{quotameta}
   95:QxCommand;{qx}
   96:BareFunctionCommand('rand');{rand}
   97:BareFunctionCommand('read');{read}
   98:BareFunctionCommand('readdir');{readdir}
   99:BareFunctionCommand('readlink');{readlink}
   100:RenameCommand;{rename}
   101:NoImplementation:=True;{require}
   102:NoImplementation:=True;{rewinddir}
   103:ReturnCommand;{return}
   104:NoImplementation:=True;{reverse}
   105:RmDirCommand;{rmdir}
   106:NoImplementation:=True;{scalar}
   107:NoImplementation:=True;{seek}
   108:NoImplementation:=True;{seekdir}
   109:NoImplementation:=True;{select}
   110:NoImplementation:=True;{setgrent}
   111:NoImplementation:=True;{sethostent}
   112:NoImplementation:=True;{setnetent}
   113:NoImplementation:=True;{setpgrp}
   114:NoImplementation:=True;{setpriority}
   115:NoImplementation:=True;{setprotoent}
   116:NoImplementation:=True;{setpwent}
   117:NoImplementation:=True;{setservent}
   118:NoImplementation:=True;{shift}
   119:NoImplementation:=True;{sin}
   120:SleepCommand;{sleep}
   121:NoImplementation:=True;{sort}
   122:NoImplementation:=True;{splice}
   123:BareFunctionCommand('split');{split}
   124:BareFunctionCommand('sprintf');{sprintf}
   125:BareFunctionCommand('sqrt');{sqrt}
   126:BareFunctionCommand('srand');{srand}
   127:NoImplementation:=True;{stat}
   128:SubCommand;{sub}
   129:BareFunctionCommand('substr');{substr}
   130:NoImplementation:=True;{symlink}
   131:NoImplementation:=True;{sysopen}
   132:NoImplementation:=True;{sysread}
   133:NoImplementation:=True;{sysseek}
   134:SystemCommand;{system}
   135:NoImplementation:=True;{syswrite}
   136:NoImplementation:=True;{tell}
   137:NoImplementation:=True;{telldir}
   138:NoImplementation:=True;{time}
   139:NoImplementation:=True;{times}
   140:NoImplementation:=True;{uc}
   141:NoImplementation:=True;{ucfirst}
   142:NoImplementation:=True;{umask}
   143:NoImplementation:=True;{undef}
   144:UnlinkCommand;{unlink}
   145:NoImplementation:=True;{unless}
   146:NoImplementation:=True;{unpack}
   147:NoImplementation:=True;{unshift}
   148:UseCommand;{use}
   149:NoImplementation:=True;{utime}
   150:NoImplementation:=True;{values}
   151:NoImplementation:=True;{wait}
   152:NoImplementation:=True;{waitpid}
   153:NoImplementation:=True;{wantarray}
   154:NoImplementation:=True;{warn}
   155:WhileCommand;{while}
   156:WriteFormatCommand;{write}
   Else UnknownCommand:=True;
  End;
  If(UnknownCommand)Then Begin
   WriteLn(CurrLine);
   WriteLn('^':CurrPos);
   WriteLn('Commande non reconnu a la position ',CurrPos,' de la ligne ',CurrNumberLine+1);
   Exit;
  End;
  If(NoImplementation)Then Begin
   WriteLn('La commande ou fonction "',CurrCommand,'" n''a pas ‚t‚ implement‚');
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

Procedure ExecuteStoredLine(LineIndex:Integer);
Var J,Err:Integer;
Begin
 If(PerlModuleExecutionDepth=0)and(PerlCallStack=Nil)and
   PerlModuleLine(LineIndex)Then Begin
  CurrLinePtr:=LineIndex;Exit;
 End;
 CurrLinePtr:=LineIndex;CurrLine:=PA[CurrLinePtr]^;CurrNumberLine:=0;J:=1;
 While J<Length(CurrLine)Do Begin
  If Not(CurrLine[J]in['0'..'9'])Then Begin
   Val(Copy(CurrLine,1,J-1),CurrNumberLine,Err);Break;
  End;
  Inc(J);
 End;
 While J<=Length(CurrLine)Do Begin
  If CurrLine[J]in[' ',#9]Then Inc(J)Else Break;
 End;
 CurrPos:=J;RunLine;
End;

Procedure RunProgram;
Begin
 If NumberLine>0Then Begin
  RegisterPerlSubroutines;
  CurrLinePtr:=1;
  While(CurrLinePtr<=NumberLine) do Begin
   ExecuteStoredLine(CurrLinePtr);
   If Terminated Then Break;
   Inc(CurrLinePtr);
  End;
 End;
End;

BEGIN
 Randomize;CurrentPerlPackage:='main';
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('PERL : Cette commande permet de lancer le langage de programmation Perl');
  WriteLn;
  WriteLn('Syntaxe : PERL [fichier.PL]');
  WriteLn;
  WriteLn(' fichier.PL  Ce paramŠtre permet d''indiquer le fichier de code source Perl');
  WriteLn(' --version   Ce paramŠtre permet de demander la version de la commande.');
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('PERL 0.1 - Clone Pascal de Perl pour Corail et PERL-0');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('crit par Sylvain Maltais');
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

