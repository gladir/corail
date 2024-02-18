{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program KSH;

Uses Crt,DOS;

Const
 CommandList:Array[0..37]of String[16]=(
  'alias','bg','bind','break','buildin','cd','command','continue',
  'echo','eval','exec','exit','export','false','fc','fg',
  'getops','hash','jobs','kill','let','print','pwd','read',
  'readonly','return','set','test','times','trap','true','typeset',
  'ulimit','umask','unalias','unset','wait','whence'
 );

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
 CommandFound,Terminated:Boolean;
 Option:(optNone,optCommand,optRunScript);
 CmdStr,LogName:String;
 BaseDir,CurrCommand,ParamList:String;
 I,J:Byte;
 AliasList:PAliasRec;
 VariableList:PVariableRec;

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

Procedure ChangeChar(Var Str:String;OldChar,NewChar:Char);
Var
 I:Byte;
Begin
 For I:=1 to Length(Str)do Begin
  If Str[I]=OldChar Then Str[I]:=NewChar;
 End;
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
 WriteLn('ksh - Korn SHell clone');
 WriteLn;
End;

Procedure ShowPrompt;Begin
 Write('$');
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
  WriteLn('Syntaxe : alias nom=valeur');
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
   If ParamList[I]='='Then Begin
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
   WriteLn(List^.Name,'=',List^.Value);
   List:=List^.Next;
  End;
 End;
End;

Procedure BgCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BindCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BreakCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BuildinCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CdCommand;Begin
 ChDir(ParamList);
End;

Procedure CommandCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ContinueCommand;Begin
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

Procedure ExportCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure FalseCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure FcCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure FgCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure GetopsCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure HashCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure JobsCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure KillCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LetCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PrintCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PwdCommand;
Var
 CurrDir:String;
Begin
 GetDir(0,CurrDir);
 ChangeChar(CurrDir,'\','/');
 WriteLn(CurrDir);
End;

Procedure ReadCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ReadonlyCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ReturnCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SetCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TestCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TimesCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TrapCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TrueCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TypesetCommand;
Var
 S:String;
 P,I:Integer;
Begin
 S:=ExtractParam(1);
 P:=1;
 If S='--help'Then Begin
  WriteLn('typeset : Cette commande permet de d‚clarer une variable.');
  WriteLn;
  WriteLn('Syntaxe : typeset nom=valeur');
  WriteLn;
  WriteLn(' nom      Nom de la variable');
  WriteLn(' valeur   Valeur de la variable');
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

Procedure UlimitCommand;Begin
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

Procedure UnsetCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure WaitCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure WhenceCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UnknownCommand;Begin
 WriteLn('Commande ou nom de fichier non reconnu');;
 WriteLn;
End;

Procedure RunCommandInternal;Begin
 For J:=Low(CommandList) to High(CommandList) do Begin
  If CurrCommand=CommandList[J]Then Begin
   Case(J)of
    0:AliasCommand;
    1:BgCommand;
    2:BindCommand;
    3:BreakCommand;
    4:BuildinCommand;
    5:CdCommand;
    6:CommandCommand;
    7:ContinueCommand;
    8:EchoCommand;
    9:EvalCommand;
    10:ExecCommand;
    11:ExitCommand;
    12:ExportCommand;
    13:FalseCommand;
    14:FcCommand;
    15:FgCommand;
    16:GetopsCommand;
    17:HashCommand;
    18:JobsCommand;
    19:KillCommand;
    20:LetCommand;
    21:PrintCommand;
    22:PwdCommand;
    23:ReadCommand;
    24:ReadonlyCommand;
    25:ReturnCommand;
    26:SetCommand;
    27:TestCommand;
    28:TimesCommand;
    29:TrapCommand;
    30:TrueCommand;
    31:TypesetCommand;
    32:UlimitCommand;
    33:UmaskCommand;
    34:UnaliasCommand;
    35:UnsetCommand;
    36:WaitCommand;
    37:WhenceCommand;
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
Begin
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
  WriteLn('KSH : Cette commande permet de lancer l''interpr‚teur de commande Korn Shell.');
  WriteLn;
  WriteLn('Syntaxe : KSH [option] [script.ksh]');
  WriteLn;
  WriteLn(' -c cmd         Indique une commande a ex‚cuter.');
  WriteLn(' -R script.ksh  Indique un script a ex‚cuter.');
  WriteLn(' --cygwin       Recherche dans les dossiers de Cygwin');
  WriteLn(' --help         Affiche l''aide de cette commande.');
 End
  Else
 Begin
  BaseDir:='';
  Manual:=True;
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
    If(Option=optRunScript)Then Begin
     RunScript(ParamStr(I));
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
    If ParamStr(I)='-R'Then Option:=optRunScript
     Else
    Begin
     WriteLn('ParamŠtre inconnu !');
     Halt(1);
    End;
   End;
  End;
  If(Manual)Then Begin
   HomeMessage;
   Repeat
    ShowPrompt;
    ReadLn(CmdStr);
    RunCommand;
   Until Terminated;
  End;
 End;
END.