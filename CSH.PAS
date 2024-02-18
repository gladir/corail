{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program CSH;

Uses Crt,DOS;

Const
 CShellFileNameHistory={$IFDEF FPC}'.history'{$ELSE}'HISTORY'{$ENDIF};

 CommandList:Array[0..40]of String[16]=(
  'alias','bg','cd','chdir','dirs','echo','end','eval','exec','exit',
  'fg','foreach','glob','hashstat','history','jobs','kill','limit',
  'login','logout','nice','nohup','notify','popd','pushd','rehash',
  'repeat','set','setenv','source','stop','suspend','time','umask',
  'unalias','unhash','unlimit','unset','unsetenv','wait','while'
 );

 MaxStackDirectory=50;

 MaxHistory={$IFDEF FPC}10000{$ELSE}100{$ENDIF};

Type
 StrPointer=^String;
 PAliasRec=^AliasRec;
 AliasRec=Record
  Name,Value:String;
  Next:PAliasRec;
 End;
 PVariableRec=^VariableRec;
 VariableRec=Record
  Name,Value:String;
  Next:PVariableRec;
 End;


Var
 Manual:Boolean;
 CmdStr,LogName:String;
 Option:(optNone,optCommand);
 BaseDir,CurrCommand,ParamList:String;
 I,J:Byte;
 StackDirectory:Array[1..MaxStackDirectory] of StrPointer;
 History:Array[1..MaxHistory] of StrPointer;
 NumberHistory,NumberDirectory:Integer;
 CommandFound,Terminated:Boolean;
 AliasList:PAliasRec;
 VariableList:PVariableRec;

Procedure RunScript(FileName:String);Forward;
Procedure RunCommandInternal;Forward;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Procedure TruncAfterSemicolon(Var S:String);
Var
 I:Byte;
Begin
 For I:=1to Length(S)do If S[I]=';'Then Begin
  S[0]:=Chr(I-1);
  Exit;
 End;
End;

Function _Path2Dir(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 _Path2Dir:='';
 If Path=''Then Exit;
 FSplit(Path,D,N,E);
 If E=''Then Begin
  If D[Length(D)]<>'\'Then D:=D+'\';
  D:=D+E;
 End;
 If D=''Then _Path2Dir:='' Else
 If D[Length(D)]<>'\'Then D:=D+'\';
 _Path2Dir:=D;
End;

Function IsWildCard(Const Path:String):Boolean;Begin
 IsWildCard:=(Pos('*',Path)>0)or(Pos('?',Path)>0);
End;

Function DirExist(Dir:String):Boolean;
Var
 Rec:SearchRec;
Begin
 If Length(Dir)=0Then DirExist:=True
  Else
 Begin
  TruncAfterSemicolon(Dir);
  If Dir[Length(Dir)]='\'Then Dir:=Dir+'*.*' Else
  If IsWildCard(Dir)Then Dir:=_Path2Dir(Dir)+'*.*';
  FindFirst(Dir,Directory,Rec);
  DirExist:=DOSError=0;
 End;
End;

Function FileExist(Name:String):Boolean;
Var
 Rec:SearchRec;
Begin
 FindFirst(Name,AnyFile,Rec);
 FileExist:=DosError=0;
End;

Function Path2Dir(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2Dir:=D;
End;

Function TrimL(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If S[I]<>' 'Then Begin
   TrimL:=Copy(S,I,255);
   Exit;
  End;
 End;
 TrimL:=S;
End;

Function AliasExist(Name:String):Boolean;
Var
 P:PAliasRec;
Begin
 AliasExist:=False;
 P:=AliasList;
 While P<>NIL do Begin
  If P^.Name=Name Then Begin
   AliasExist:=True;
   Exit;
  End;
  P:=P^.Next;
 End;
End;

Function GetAliasValue(Name:String):String;
Var
 P:PAliasRec;
Begin
 GetAliasValue:='';
 P:=AliasList;
 While P<>NIL do Begin
  If P^.Name=Name Then Begin
   GetAliasValue:=P^.Value;
   Exit;
  End;
  P:=P^.Next;
 End;
End;

Function SetAliasValue(Name,Value:String):Boolean;
Var
 P:PAliasRec;
Begin
 SetAliasValue:=False;
 P:=AliasList;
 While P<>NIL do Begin
  If P^.Name=Name Then Begin
   P^.Value:=Value;
   SetAliasValue:=True;
   Exit;
  End;
  P:=P^.Next;
 End;
End;

Function AddAlias(Name,Value:String):Boolean;
Var
 P:PAliasRec;
Begin
 AddAlias:=False;
 If AliasExist(Name)Then Begin
  SetAliasValue(Name,Value);
  AddAlias:=True;
 End
  Else
 Begin
  New(P);
  If P=NIL Then Exit;
  P^.Name:=Name;
  P^.Value:=Value;
  P^.Next:=AliasList;
  AliasList:=P;
  AddAlias:=True;
 End;
End;

Function DeleteAlias(Name:String):Boolean;
Var
 Previous,P:PAliasRec;
Begin
 DeleteAlias:=False;
 Previous:=NIL;
 P:=AliasList;
 While P<>NIL do Begin
  If P^.Name=Name Then Begin
   If(Previous=NIL)Then AliasList:=P^.Next
                   Else Previous^.Next:=P^.Next;
   Dispose(P);
   DeleteAlias:=True;
   Exit;
  End;
  Previous:=P;
  P:=P^.Next;
 End;
End;

Function VariableExist(Name:String):Boolean;
Var
 P:PVariableRec;
Begin
 VariableExist:=False;
 P:=VariableList;
 While P<>NIL do Begin
  If P^.Name=Name Then Begin
   VariableExist:=True;
   Exit;
  End;
  P:=P^.Next;
 End;
End;

Function GetVariableValue(Name:String):String;
Var
 P:PVariableRec;
Begin
 GetVariableValue:='';
 P:=VariableList;
 While P<>NIL do Begin
  If P^.Name=Name Then Begin
   GetVariableValue:=P^.Value;
   Exit;
  End;
  P:=P^.Next;
 End;
End;

Function SetVariableValue(Name,Value:String):Boolean;
Var
 P:PVariableRec;
Begin
 SetVariableValue:=False;
 P:=VariableList;
 While P<>NIL do Begin
  If P^.Name=Name Then Begin
   P^.Value:=Value;
   SetVariableValue:=True;
   Exit;
  End;
  P:=P^.Next;
 End;
End;

Function AddVariable(Name,Value:String):Boolean;
Var
 P:PVariableRec;
Begin
 AddVariable:=False;
 If VariableExist(Name)Then Begin
  SetVariableValue(Name,Value);
  AddVariable:=True;
 End
  Else
 Begin
  New(P);
  If P=NIL Then Exit;
  P^.Name:=Name;
  P^.Value:=Value;
  P^.Next:=VariableList;
  VariableList:=P;
  AddVariable:=True;
 End;
End;

Function DeleteVariable(Name:String):Boolean;
Var
 Previous,P:PVariableRec;
Begin
 DeleteVariable:=False;
 Previous:=NIL;
 P:=VariableList;
 While P<>NIL do Begin
  If P^.Name=Name Then Begin
   If(Previous=NIL)Then VariableList:=P^.Next
                   Else Previous^.Next:=P^.Next;
   Dispose(P);
   DeleteVariable:=True;
   Exit;
   End;
  Previous:=P;
  P:=P^.Next;
 End;
End;

Function AddHistory(S:String):Boolean;
Var
 I:Word;
 P:StrPointer;
Begin
 If NumberHistory>=MaxHistory Then Begin
  FreeMem(History[1],Length(History[1]^)+1);
  For I:=1 to MaxHistory-1 do History[I]:=History[I+1];
  GetMem(P,Length(S)+1);
  P^:=S;
  History[MaxHistory]:=P;
  AddHistory:=True;
  Exit;
 End
  Else
 Begin
  Inc(NumberHistory);
  GetMem(P,Length(S)+1);
  P^:=S;
  History[NumberHistory]:=P;
  AddHistory:=True;
 End;
End;

Function PushDirectory(Directory:String):Boolean;
Var
 P:StrPointer;
Begin
 If NumberDirectory>=MaxStackDirectory Then Begin
  WriteLn('Pile de r‚pertoire pleine');
  PushDirectory:=False;
  Exit;
 End;
 Inc(NumberDirectory);
 GetMem(P,Length(Directory)+1);
 P^:=Directory;
 StackDirectory[NumberDirectory]:=P;
 PushDirectory:=True;
End;

Function PopDirectory:String;Begin
 PopDirectory:='';
 If NumberDirectory>0Then Begin
  PopDirectory:=StackDirectory[NumberDirectory]^;
  FreeMem(History[NumberDirectory],Length(History[NumberDirectory]^)+1);
  Dec(NumberDirectory);
 End;
End;

Procedure ClearHistory;
Var
 I:LongInt;
Begin
 For I:=1 to NumberHistory do Begin
  FreeMem(History[I],Length(History[I]^)+1);
  History[I]:=NIL;
 End;
 NumberHistory:=0;
End;

Procedure LoadHistory;
Var
 History:Text;
 CurrLine:String;
Begin
 {$I-}Assign(History,CShellFileNameHistory);
 Reset(History);{$I+}
 If IOResult=0 Then Begin
  While Not EOF(History)do Begin
   ReadLn(History,CurrLine);
   AddHistory(CurrLine);
  End;
  Close(History);
 End;
End;

Procedure SaveHistory(Add:Boolean);
Var
 HistoryFile:Text;
 I:LongInt;
Begin
 {$I-}Assign(HistoryFile,CShellFileNameHistory);
 If(Add)Then Append(HistoryFile)
        Else Rewrite(HistoryFile);{$I+}
 If IOResult=0 Then Begin
  For I:=1 to NumberHistory do Begin
   WriteLn(HistoryFile,History[I]^);
  End;
  Close(HistoryFile);
 End;
End;

Procedure ExtractCommand;
Var
 I:Byte;
Begin
 For I:=1 to Length(CmdStr)do Begin
  If Not(CmdStr[I]in['A'..'Z','a'..'z','_','-','0'..'9'])Then Begin
   CurrCommand:=Copy(CmdStr,1,I-1);
   ParamList:=TrimL(Copy(CmdStr,I,255));
   Exit;
  End;
 End;
 CurrCommand:=CmdStr;
 ParamList:='';
End;

Function ExtractParam(Index:Byte):String;
Var
 Count:Word;
 LocalIndex:Word;
 l:Byte;
 Temp:String;
Begin
 Temp:='';Count:=1;LocalIndex:=1;l:=0;
 While Count<=Length(ParamList)do Begin
  If Not(ParamList[Count] in [' ',#9])then Begin
   If LocalIndex=Index Then Begin
    While (Count<=Length(ParamList)) and (Not(ParamList[count] in[' ',#9])) and (l < 256) do Begin
     Temp:=Temp+ParamList[count];
     Inc(l);
     Inc(Count);
    end;
    Temp[0]:=Char(l);
    ExtractParam:=Temp;
    Exit;
   End;
   While (Count<=Length(ParamList)) and (Not(ParamList[count] in [' ',#9])) do Inc(Count);
   Inc(LocalIndex);
  End;
  If Count>=Length(ParamList)Then Break;
  Inc(Count);
 End;
 ExtractParam:=Temp;
End;

Procedure HomeMessage;Begin
 WriteLn;
 WriteLn('csh - C Shell clone');
 WriteLn;
End;

Procedure ShowPrompt;Begin
 Write('%');
End;

Procedure AliasCommand;
Var
 List:PAliasRec;
 I,P:Integer;
 AliasName,AliasValue:String;
Begin
 If ExtractParam(1)='--help'Then Begin
  WriteLn('alias : Cette commande permet de cr‚er un alias.');
  WriteLn;
  WriteLn('Syntaxe : alias nom valeur');
  WriteLn;
  WriteLn(' nom     Nom de l''alias');
  WriteLn(' valeur  La valeur de l''alias');
 End
  Else
 If(ParamList<>'')Then Begin
  AliasName:='';
  AliasValue:='';
  P:=0;
  For I:=1 to Length(ParamList)do Begin
   If ParamList[I]=' 'Then Begin
    P:=I;
    Break;
   End;
  End;
  If P>0 Then Begin
   AliasName:=Copy(ParamList,1,P-1);
   If P=Length(ParamList)Then Begin
    AddAlias(AliasName,'');
   End
    Else
   AddAlias(AliasName,Copy(ParamList,P+1,255));
  End;
 End
  Else
 Begin
  List:=AliasList;
  While List<>NIL do Begin
   WriteLn(PadRight(List^.Name,10),List^.Value);
   List:=List^.Next;
  End;
 End;
End;

Procedure BgCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ChdirCommand;
Var
 Error:Word;
 FirstParam,Dir:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='-h'Then Begin
  WriteLn('chdir   Cette commande permet de fixer ou de demander le repertoire courant.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('cd [-h] chemin');
  WriteLn('chdir [-h] chemin');
  WriteLn;
  WriteLn('  -h     Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' chemin  Ce parametre permet d''indiquer le chemin du repertoire.');
 End
  Else
 If Length(FirstParam)>0Then Begin
  {$I-} ChDir(FirstParam);{$I+}
  Error:=IoResult;
  If Error<>0Then WriteLn('Impossible de changer de repertoire');
 End
  Else
 Begin
  GetDir(0,Dir);
  WriteLn(Dir);
 End;
End;

Procedure DirsCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure EchoCommand;
Var
 NewLine:Boolean;
 I:Integer;
 S:String;
Begin
 Newline:=True;
 S:=ExtractParam(1);
 If S='--help'Then Begin
  WriteLn('echo : Cette commande permet d''afficher le message sp‚cifi‚');
  WriteLn;
  WriteLn('Syntaxe : echo message');
  WriteLn;
  WriteLn(' message   Indique le message a afficher');
  WriteLn(' --help  Affiche l''aide de cette commande');
 End
  Else
 Begin
  I:=1;
  While S<>''do Begin
   If(S='-n')Then Newline:=False;
   If(S[1]='$')Then Begin
    If(VariableExist(Copy(S,2,255)))Then Write(GetVariableValue(Copy(S,2,255)));
   End
    Else
   Write(S);
   Write(' ');
   Inc(I);
   If I>255 Then Exit;
   S:=ExtractParam(I);
  End;
  If(NewLine)Then WriteLn;
 End;
End;

Procedure EndCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure EvalCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ExecCommand;
Var
 I:Integer;
 Param1,Param2:String;
Begin
 Param1:='';
 Param2:='';
 For I:=1 to Length(ParamList)do Begin
  If Not(ParamList[I]in['A'..'Z','a'..'z','_','-','0'..'9'])Then Begin
   Param1:=Copy(ParamList,1,I-1);
   Param2:=TrimL(Copy(ParamList,I,255));
   Break;
  End;
 End;
 If Param1=''Then Param1:=ParamList;
 Exec(Param1,Param2);
End;

Procedure ExitCommand;Begin
 Terminated:=True;
End;

Procedure FgCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ForeachCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure GlobCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure HashstatCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure HistoryCommand;
Var
 I:Integer;
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='-h'Then Begin
  WriteLn('history   Cette commande permet d''afficher l''historique des commandes.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('history [-h]');
  WriteLn;
  WriteLn('  -h    Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 For I:=1 to NumberHistory do Begin
  Write(I:5);
  WriteLn('  ',History[I]^);
 End;
End;

Procedure JobsCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure KillCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LimitCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LoginCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LogoutCommand;
Var
 Value:Integer;
 Err:Word;
Begin
 If ParamList<>''Then Begin
  Val(ParamList,Value,Err);
  Halt(Value);
 End
  Else
 Terminated:=True;
End;

Procedure NiceCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure NohupCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure NotifyCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PopdCommand;
Var
 Error:Word;
 FirstParam,Dir:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='-h'Then Begin
  WriteLn('popd   Cette commande permet de restaurer le repertoire.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('popd [-h]');
  WriteLn;
  WriteLn('  -h     Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 Begin
  Dir:=PopDirectory;
  {$I-} ChDir(Dir);{$I+}
  Error:=IoResult;
  If Error<>0Then WriteLn('Impossible de changer de repertoire');
 End;
End;

Procedure PushdCommand;
Var
 Error:Word;
 FirstParam,Dir:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='-h'Then Begin
  WriteLn('pushd   Cette commande permet de sauver le repertoire.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('pushd [-h] [chemin]');
  WriteLn;
  WriteLn('  -h     Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' chemin  Ce parametre permet d''indiquer le repertoire a mettre a la place.');
 End
  Else
 If Length(FirstParam)>0Then Begin
  If Not(PushDirectory(FExpand(FirstParam)))Then WriteLn('Pile pleine');
  {$I-} ChDir(FirstParam);{$I+}
  Error:=IoResult;
  If Error<>0Then WriteLn('Impossible de changer de repertoire');
 End
  Else
 Begin
  GetDir(0,Dir);
  If Not(PushDirectory(Dir))Then WriteLn('Pile pleine');
 End;
End;

Procedure RehashCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure RepeatCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SetCommand;
Var
 S:String;
 P,I:Integer;
Begin
 S:=ExtractParam(1);
 P:=1;
 If S='--help'Then Begin
  WriteLn('declare : Cette commande permet de d‚clarer une variable.');
  WriteLn;
  WriteLn('Syntaxe : set nom=valeur');
  WriteLn;
  WriteLn(' nom      Nom de la variable');
  WriteLn(' valeur   Valeur de la variable');
  WriteLn(' --help  Affiche l''aide de cette commande');
 End
  Else
 While S<>''do Begin
  I:=1;
  While(I<=Length(S))and(S[I]in['A'..'Z','a'..'z','0'..'9','-'])do Inc(I);
  If(I>1)and(I<=Length(S))Then Begin
   If S[I]='='Then Begin
    AddVariable(Copy(S,1,I-1),Copy(S,I+1,255));
   End;
  End;
  Inc(P);
  If P>255 Then Exit;
  S:=ExtractParam(P);
 End;
End;

Procedure SetEnvCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SourceCommand;Begin
 If ExtractParam(1)='--help'Then Begin
  WriteLn('source : Cette commande permet de lire et ',
                    'd''ex‚cuter les commandes dans le fichier ',
                    'sp‚cifi‚.');
  WriteLn;
  WriteLn('Syntaxe : source filename');
  WriteLn;
  WriteLn(' filename  Nom du fichier BASH');
  WriteLn(' --help    Affiche l''aide de cette commande');
 End
  Else
 If ExtractParam(1)<>''Then RunScript(ExtractParam(1));
End;

Procedure StopCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SuspendCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TimeCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UmaskCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UnaliasCommand;
Var
 P:Integer;
 S:String;
Begin
 P:=1;
 S:=ExtractParam(1);
 If S='--help'Then Begin
  WriteLn('unalias : Cette commande permet de supprimer un alias.');
  WriteLn;
  WriteLn('Syntaxe : unalias [-a] name');
  WriteLn('          unalias --help');
  WriteLn;
  WriteLn(' name    Le nom de l''alias … supprimer');
  WriteLn(' -a      Permet de supprimer tous les alias');
  WriteLn(' --help  Affiche l''aide de cette commande');
 End
  Else
 While S<>''do Begin
  If S='-a'Then Begin
   While AliasList<>NIL do Begin
    If Not DeleteAlias(AliasList^.Name)Then WriteLn('Impossible de supprimer l''alias ',AliasList^.Name);
   End;
   Exit;
  End;
  If Not DeleteAlias(S)Then Begin
   WriteLn('Impossible de supprimer l''alias ',S);
   Exit;
  End;
  Inc(P);
  If P>255 Then Break;
  S:=ExtractParam(P);
 End;
End;

Procedure UnhashCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UnlimitCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UnsetCommand;
Var
 P:Integer;
 S:String;
Begin
 P:=1;
 S:=ExtractParam(1);
 If S='--help'Then Begin
  WriteLn('unset : Cette commande permet de supprimer une variable.');
  WriteLn;
  WriteLn('Syntaxe : unset name');
  WriteLn('          unset --help');
  WriteLn;
  WriteLn(' name    Le nom de l''alias … supprimer');
  WriteLn(' --help  Affiche l''aide de cette commande');
 End
  Else
 While S<>''do Begin
  If Not DeleteVariable(S)Then Begin
   WriteLn('Impossible de supprimer la variable ',S);
   Exit;
  End;
  Inc(P);
  If P>255 Then Break;
  S:=ExtractParam(P);
 End;
End;

Procedure UnsetenvCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure WaitCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure WhileCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UnknownCommand;
Var
 Err:Word;
Begin
 Exec(CurrCommand,ParamList);
 Err:=DosError;
 If Err>0 Then WriteLn('Commande ou nom de fichier non reconnu');
 WriteLn;
End;

Procedure RunCommandInternal;Begin
 For J:=Low(CommandList) to High(CommandList) do Begin
  If CurrCommand=CommandList[J]Then Begin
   Case(J)of
    0:AliasCommand;
    1:BgCommand;
    2:ChdirCommand;
    3:ChdirCommand;
    4:DirsCommand;
    5:EchoCommand;
    6:EndCommand;
    7:EvalCommand;
    8:ExecCommand;
    9:ExitCommand;
    10:FgCommand;
    11:ForeachCommand;
    12:GlobCommand;
    13:HashstatCommand;
    14:HistoryCommand;
    15:JobsCommand;
    16:KillCommand;
    17:LimitCommand;
    18:LoginCommand;
    19:LogoutCommand;
    20:NiceCommand;
    21:NohupCommand;
    22:NotifyCommand;
    23:PopdCommand;
    24:PushdCommand;
    25:RehashCommand;
    26:RepeatCommand;
    27:SetCommand;
    28:SetEnvCommand;
    29:SourceCommand;
    30:StopCommand;
    31:SuspendCommand;
    32:TimeCommand;
    33:UmaskCommand;
    34:UnaliasCommand;
    35:UnhashCommand;
    36:UnlimitCommand;
    37:UnsetCommand;
    38:UnsetenvCommand;
    39:WaitCommand;
    40:WhileCommand;
   End;
   If J<=High(CommandList)Then Begin
    CommandFound:=True;
    WriteLn;
    Break;
   End;
  End;
 End;
End;

Procedure RunCommand;
Var
 Err:Word;
 I:Integer;
Begin
 If(Length(CmdStr)>=2)and(CmdStr[1]='!')and(CmdStr[2]in['0'..'9'])Then Begin
  Val(Copy(CmdStr,2,255),I,Err);
  If(I>=1)and(I<=NumberHistory)Then Begin
   CmdStr:=History[I]^;
  End
   Else
  Begin
   WriteLn('Nombre en dehors de l''intervalle d''historique');
  End;
 End;
 AddHistory(CmdStr);
 If Copy(CmdStr,1,2)='./'Then Begin
  CurrCommand:=Copy(CmdStr,3,Pos(' ',CmdStr)-3);
  ParamList:=Copy(CmdStr,Pos(' ',CmdStr),255);
  Exec(CurrCommand,ParamList);
  Err:=DosError;
  If Err>0 Then WriteLn('Commande ou nom de fichier non reconnu');
 End
  Else
 Begin
  ExtractCommand;
  CommandFound:=False;
  If AliasExist(CurrCommand)Then Begin
   CmdStr:=GetAliasValue(CurrCommand);
   ExtractCommand;
  End;
  RunCommandInternal;
  If Not(CommandFound)Then UnknownCommand;
 End;
End;

Procedure RunScript(FileName:String);
Var
 FileBat:Text;
Begin
 Assign(FileBat,BaseDir+FileName);
 {$I-}Reset(FileBat);{$I+}
 If IOResult=0Then Begin
  While Not EOF(FileBat)do Begin
   ReadLn(FileBat,CmdStr);
   RunCommand;
  End;
 End
  Else
 WriteLn('ProblŠme de lecture du fichier de traitement par lot');
 Close(FileBat);
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('CSH : Cette commande permet de lancer l''interpr‚teur de commande C Shell.');
  WriteLn;
  WriteLn('Syntaxe : CSH [option] [script.csh]');
  WriteLn;
  WriteLn(' script.csh  Indique un script a ex‚cuter.');
  WriteLn(' -c cmd     Indique une commande a ex‚cuter.');
  WriteLn(' --cygwin   Recherche dans les dossiers de Cygwin');
  WriteLn(' --help     Affiche l''aide de cette commande.');
 End
  Else
 Begin
  BaseDir:='';
  Manual:=True;
  FillChar(History,SizeOf(History),0);
  NumberHistory:=0;
  LoadHistory;
  FillChar(StackDirectory,SizeOf(StackDirectory),0);
  NumberDirectory:=0;
  AliasList:=NIL;
  VariableList:=NIL;
  Terminated:=False;
  LogName:=GetEnv('LOGNAME');
  If ParamCount>0 Then Begin
   For I:=1 to ParamCount do Begin
    If(Option=optCommand)Then Begin
     CmdStr:=ParamStr(I);
     RunCommand;
     Option:=optNone;
     Manual:=False;
    End
     Else
    If ParamStr(I)='-c'Then Option:=optCommand Else
    If ParamStr(I)='--cygwin'Then Begin
     If DirExist('/cygwin')Then BaseDir:='/cygwin' Else
     If DirExist('/cygwin32')Then BaseDir:='/cygwin32' Else
     If DirExist('/cygwin64')Then BaseDir:='/cygwin64';
     If LogName=''Then LogName:=GetEnv('USERNAME');
    End
     Else
    If ParamStr(I)='--cygwin64'Then BaseDir:='/cygwin64' Else
    If ParamStr(I)='--cygwin32'Then BaseDir:='/cygwin32'
     Else
    Begin
     RunScript(ParamStr(I));
     Manual:=False;
    End;
   End;
  End;
  If(Manual)Then Begin
   If FileExist('.cshrc')Then RunScript('.cshrc');
   HomeMessage;
   Repeat
    ShowPrompt;
    ReadLn(CmdStr);
    RunCommand;
   Until Terminated;
   SaveHistory(False);
  End;
 End;
END.