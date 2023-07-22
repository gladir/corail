{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal 3.2, Turbo Pascal 7)
}

Program REXX;

Uses Crt,DOS;

Const
 CommandList:Array[0..149]of String[20]=(
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
  'X2B','X2C','X2D'
 );

 MaxLine=1024;

Type
 StrPointer=^String;

Var
 Terminated:Boolean;
 CurrCommand:String;
 FileName,CurrLine:String;
 PA:Array[1..MaxLine] of StrPointer;
 CurrLinePtr,NumberLine:Integer;
 CurrNumberLine:Integer;
 I:Integer;
 CurrPos:Byte;

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

Procedure SayCommand;Begin
 SkipSpace;
 If IsStringValue Then Begin
  WriteLn(GetStringValue);
 End;
End;

Function RunLine:Boolean;
Var
 R1:Real;
 UnknownCommand:Boolean;
 NoImplementation:Boolean;
Begin
 RunLine:=False;
 CurrPos:=1;
 NoImplementation:=False;
 UnknownCommand:=False;
 Case ExtractCommand of
  0:NoImplementation:=True;{ABBREV}
  1:NoImplementation:=True;{ABS}
  2:NoImplementation:=True;{ADDRESS}
  3:NoImplementation:=True;{ARG}
  4:NoImplementation:=True;{B2X}
  5:NoImplementation:=True;{BEEP}
  6:NoImplementation:=True;{BITAND}
  7:NoImplementation:=True;{BITOR}
  8:NoImplementation:=True;{BITXOR}
  9:NoImplementation:=True;{CALL}
  10:NoImplementation:=True;{CENTER}
  11:NoImplementation:=True;{CHANGESTR}
  12:NoImplementation:=True;{CHARIN}
  13:NoImplementation:=True;{CHAROUT}
  14:NoImplementation:=True;{CHARS}
  15:NoImplementation:=True;{COMPARE}
  16:NoImplementation:=True;{CONDITION}
  17:NoImplementation:=True;{COPIES}
  18:NoImplementation:=True;{COUNTSTR}
  19:NoImplementation:=True;{C2D}
  20:NoImplementation:=True;{C2X}
  21:NoImplementation:=True;{DATATYPE}
  22:NoImplementation:=True;{DATE}
  23:NoImplementation:=True;{DELSTR}
  24:NoImplementation:=True;{DELWORD}
  25:NoImplementation:=True;{DIGITS}
  26:NoImplementation:=True;{DIRECTORY}
  27:NoImplementation:=True;{D2C}
  28:NoImplementation:=True;{D2X}
  29:NoImplementation:=True;{ENDLOCAL}
  30:NoImplementation:=True;{ERRORTEXT}
  31:Begin {EXIT}
   Terminated:=True;
   Exit;
  End;
  32:NoImplementation:=True;{FILESPEC}
  33:NoImplementation:=True;{FORM}
  34:NoImplementation:=True;{FORMAT}
  35:NoImplementation:=True;{FUZZ}
  36:NoImplementation:=True;{IF}
  37:NoImplementation:=True;{INSERT}
  38:NoImplementation:=True;{LASTPOS}
  39:NoImplementation:=True;{LEFT}
  40:NoImplementation:=True;{LENGTH}
  41:NoImplementation:=True;{LINEIN}
  42:NoImplementation:=True;{LINEOUT}
  43:NoImplementation:=True;{LINES}
  44:NoImplementation:=True;{MAX}
  45:NoImplementation:=True;{MIN}
  46:NoImplementation:=True;{OPTIONS}
  47:NoImplementation:=True;{OVERLAY}
  48:NoImplementation:=True;{PARSE}
  49:NoImplementation:=True;{PROCEDURE}
  50:NoImplementation:=True;{POS}
  51:NoImplementation:=True;{PULL}
  52:NoImplementation:=True;{PUSH}
  53:NoImplementation:=True;{QUEUE}
  54:NoImplementation:=True;{QUEUED}
  55:NoImplementation:=True;{RANDOM}
  56:NoImplementation:=True;{RETURN}
  57:NoImplementation:=True;{REVERSE}
  58:NoImplementation:=True;{RIGHT}
  59:NoImplementation:=True;{RXFUNCADD}
  60:NoImplementation:=True;{RXFUNCDROP}
  61:NoImplementation:=True;{RXFUNCQUERY}
  62:NoImplementation:=True;{RXMESSAGEBOX}
  63:NoImplementation:=True;{RXQUEUE}
  64:NoImplementation:=True;{RXWINEXEC}
  65:SayCommand;{SAY}
  66:NoImplementation:=True;{SELECT}
  67:NoImplementation:=True;{SETLOCAL}
  68:NoImplementation:=True;{SIGN}
  69:NoImplementation:=True;{SOURCELINE}
  70:NoImplementation:=True;{SPACE}
  71:NoImplementation:=True;{STREAM}
  72:NoImplementation:=True;{STRIP}
  73:NoImplementation:=True;{SUBSTR}
  74:NoImplementation:=True;{SUBWORD}
  75:NoImplementation:=True;{SYMBOL}
  76:NoImplementation:=True;{SYSADDREXXMACRO}
  77:NoImplementation:=True;{SYSBOOTDRIVE}
  78:NoImplementation:=True;{SYSCLEARREXXMACROSPACE}
  79:NoImplementation:=True;{SYSCLOSEEVENTSEM}
  80:NoImplementation:=True;{SYSCLOSEMUTEXSEM}
  81:NoImplementation:=True;{SYSCLS}
  82:NoImplementation:=True;{SYSCREATEEVENTSEM}
  83:NoImplementation:=True;{SYSCREATEMUTEXSEM}
  84:NoImplementation:=True;{SYSCREATEOBJECT}
  85:NoImplementation:=True;{SYSCURPOS}
  86:NoImplementation:=True;{SYSCURSTATE}
  87:NoImplementation:=True;{SYSDEREGISTEROBJECTCLASS}
  88:NoImplementation:=True;{SYSDESTROYOBJECT}
  89:NoImplementation:=True;{SYSDRIVEINFO}
  90:NoImplementation:=True;{SYSDRIVEMAP}
  91:NoImplementation:=True;{SYSDROPFUNCS}
  92:NoImplementation:=True;{SYSDROPREXXMACRO}
  93:NoImplementation:=True;{SYSFILEDELETE}
  94:NoImplementation:=True;{SYSFILETREE}
  95:NoImplementation:=True;{SYSFILESEARCH}
  96:NoImplementation:=True;{SYSFILESYSTEMTYPE}
  97:NoImplementation:=True;{SYSGETEA}
  98:NoImplementation:=True;{SYSGETKEY}
  99:NoImplementation:=True;{SYSGETMESSAGE}
  100:NoImplementation:=True;{SYSINI}
  101:NoImplementation:=True;{SYSLOADFUNCS}
  102:NoImplementation:=True;{SYSLOADREXXMACROSPACE}
  103:NoImplementation:=True;{SYSMKDIR}
  104:NoImplementation:=True;{SYSOPENEVENTSEM}
  105:NoImplementation:=True;{SYSOPENMUTEXSEM}
  106:NoImplementation:=True;{SYSOS2VER}
  107:NoImplementation:=True;{SYSPOSTEVENTSEM}
  108:NoImplementation:=True;{SYSPULSEEVENTSEM}
  109:NoImplementation:=True;{SYSPUTEA}
  110:NoImplementation:=True;{SYSQUERYCLASSLIST}
  111:NoImplementation:=True;{SYSQUERYREXXMACRO}
  112:NoImplementation:=True;{SYSREGISTEROBJECTCLASS}
  113:NoImplementation:=True;{SYSRELEASEMUTEXSEM}
  114:NoImplementation:=True;{SYSREORDERREXXMACRO}
  115:NoImplementation:=True;{SYSREQUESTMUTEXSEM}
  116:NoImplementation:=True;{SYSRESETEVENTSEM}
  117:NoImplementation:=True;{SYSRMDIR}
  118:NoImplementation:=True;{SYSSAVEREXXMACROSPACE}
  119:NoImplementation:=True;{SYSSEARCHPATH}
  120:NoImplementation:=True;{SYSSETICON}
  121:NoImplementation:=True;{SYSSETOBJECTDATA}
  122:NoImplementation:=True;{SYSSETPRIORITY}
  123:NoImplementation:=True;{SYSSLEEP}
  124:NoImplementation:=True;{SYSSWITCHSESSION}
  125:NoImplementation:=True;{SYSSYSTEMDIRECTORY}
  126:NoImplementation:=True;{SYSTEMPFILENAME}
  127:NoImplementation:=True;{SYSTEXTSCREENREAD}
  128:NoImplementation:=True;{SYSTEXTSCREENSIZE}
  129:NoImplementation:=True;{SYSVOLUMELABEL}
  130:NoImplementation:=True;{SYSWAITEVENTSEM}
  131:NoImplementation:=True;{SYSWAITNAMEDPIPE}
  132:NoImplementation:=True;{SYSWINVER}
  133:NoImplementation:=True;{THEN}
  134:NoImplementation:=True;{TIME}
  135:NoImplementation:=True;{TRACE}
  136:NoImplementation:=True;{TRANSLATE}
  137:NoImplementation:=True;{TRUNC}
  138:NoImplementation:=True;{VALUE}
  139:NoImplementation:=True;{VAR}
  140:NoImplementation:=True;{VERIFY}
  141:NoImplementation:=True;{WORD}
  142:NoImplementation:=True;{WORDINDEX}
  143:NoImplementation:=True;{WORDLENGTH}
  144:NoImplementation:=True;{WORDPOS}
  145:NoImplementation:=True;{WORDS}
  146:NoImplementation:=True;{XRANGE}
  147:NoImplementation:=True;{X2B}
  148:NoImplementation:=True;{X2C}
  149:NoImplementation:=True;{X2D}
  Else UnknownCommand:=True;
 End;
 If(UnknownCommand)Then Begin
  WriteLn('Commande non reconnu');
  Exit;
 End
  Else
 If(NoImplementation)Then Begin
  WriteLn('Cette commande n''a pas ‚t‚ impl‚ment‚');
  Exit;
 End;
 RunLine:=True;
End;

Procedure ExecuteCommand;
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
   If Not(RunLine)Then Break;
   Inc(CurrLinePtr);
  End;
 End;
End;

BEGIN
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
  NumberLine:=0;CurrNumberLine:=0;
  If ParamCount>0 Then Begin
   For I:=1 to ParamCount do Begin
    FileName:=ParamStr(I);
   End;
   LoadCommand;
   ExecuteCommand;
  End
 End;
END.