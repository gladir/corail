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
   CurrPos:=Length(CurrLine)+1;
   RunLine:=True;
   Exit;
  End
   Else
  Case ExtractCommand of
   0:NoImplementation:=True;{abs}
   1:NoImplementation:=True;{alarm}
   2:NoImplementation:=True;{atan2}
   3:NoImplementation:=True;{binmode}
   4:NoImplementation:=True;{caller}
   5:ChDirCommand;{chdir}
   6:NoImplementation:=True;{chmod}
   7:NoImplementation:=True;{chomp}
   8:NoImplementation:=True;{chop}
   9:NoImplementation:=True;{chown}
   10:NoImplementation:=True;{chr}
   11:NoImplementation:=True;{chroot}
   12:NoImplementation:=True;{close}
   13:NoImplementation:=True;{closedir}
   14:NoImplementation:=True;{cos}
   15:NoImplementation:=True;{crypt}
   16:NoImplementation:=True;{defined}
   17:NoImplementation:=True;{delete}
   18:Begin {die}
    Terminated:=True;
    Exit;
   End;
   19:NoImplementation:=True;{each}
   20:NoImplementation:=True;{endgrent}
   21:NoImplementation:=True;{endhostent}
   22:NoImplementation:=True;{endnetent}
   23:NoImplementation:=True;{endprotoent}
   24:NoImplementation:=True;{endpwent}
   25:NoImplementation:=True;{endservent}
   26:NoImplementation:=True;{eof}
   27:NoImplementation:=True;{eval}
   28:ExecCommand;{exec}
   29:NoImplementation:=True;{exists}
   30:Begin {exit}
    Terminated:=True;
    Exit;
   End;
   31:NoImplementation:=True;{exp}
   32:NoImplementation:=True;{fileno}
   33:NoImplementation:=True;{flock}
   34:NoImplementation:=True;{for}
   35:NoImplementation:=True;{foreach}
   36:NoImplementation:=True;{fork}
   37:NoImplementation:=True;{format}
   38:NoImplementation:=True;{getc}
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
   61:NoImplementation:=True;{gmtime}
   62:NoImplementation:=True;{grep}
   63:NoImplementation:=True;{glob}
   64:NoImplementation:=True;{hex}
   65:NoImplementation:=True;{if}
   66:NoImplementation:=True;{index}
   67:NoImplementation:=True;{int}
   68:NoImplementation:=True;{join}
   69:NoImplementation:=True;{keys}
   70:NoImplementation:=True;{kill}
   71:NoImplementation:=True;{lc}
   72:NoImplementation:=True;{lcfirst}
   73:NoImplementation:=True;{length}
   74:NoImplementation:=True;{link}
   75:NoImplementation:=True;{local}
   76:NoImplementation:=True;{localtime}
   77:NoImplementation:=True;{log}
   78:NoImplementation:=True;{lstat}
   79:NoImplementation:=True;{map}
   80:MkDirCommand;{mkdir}
   81:NoImplementation:=True;{my}
   82:NoImplementation:=True;{oct}
   83:NoImplementation:=True;{open}
   84:NoImplementation:=True;{opendir}
   85:NoImplementation:=True;{ord}
   86:NoImplementation:=True;{pack}
   87:NoImplementation:=True;{package}
   88:NoImplementation:=True;{pipe}
   89:NoImplementation:=True;{pop}
   90:NoImplementation:=True;{pos}
   91:PrintCommand;{print}
   92:NoImplementation:=True;{printf}
   93:NoImplementation:=True;{push}
   94:NoImplementation:=True;{quotameta}
   95:NoImplementation:=True;{qx}
   96:NoImplementation:=True;{rand}
   97:NoImplementation:=True;{read}
   98:NoImplementation:=True;{readdir}
   99:NoImplementation:=True;{readlink}
   100:RenameCommand;{rename}
   101:NoImplementation:=True;{require}
   102:NoImplementation:=True;{rewinddir}
   103:NoImplementation:=True;{return}
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
   123:NoImplementation:=True;{split}
   124:NoImplementation:=True;{sprintf}
   125:NoImplementation:=True;{sqrt}
   126:NoImplementation:=True;{srand}
   127:NoImplementation:=True;{stat}
   128:NoImplementation:=True;{sub}
   129:NoImplementation:=True;{substr}
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
   148:NoImplementation:=True;{use}
   149:NoImplementation:=True;{utime}
   150:NoImplementation:=True;{values}
   151:NoImplementation:=True;{wait}
   152:NoImplementation:=True;{waitpid}
   153:NoImplementation:=True;{wantarray}
   154:NoImplementation:=True;{warn}
   155:NoImplementation:=True;{while}
   156:NoImplementation:=True;{write}
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
