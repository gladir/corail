{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program CSH;

Uses Crt,DOS;

Const
 CommandList:Array[0..40]of String[16]=(
  'alias','bg','cd','chdir','dirs','echo','end','eval','exec','exit',
  'fg','foreach','glob','hashstat','history','jobs','kill','limit',
  'login','logout','nice','nohup','notify','popd','pushd','rehash',
  'repeat','set','setenv','source','stop','suspend','time','umask',
  'unalias','unhash','unlimit','unset','unsetenv','wait','while'
 );

 MaxStackDirectory=50;
 MaxHistory=100;

Type
 StrPointer=^String;

Var
 StackDirectory:Array[1..MaxStackDirectory] of StrPointer;
 History:Array[1..MaxHistory] of StrPointer;
 NumberHistory,NumberDirectory:Integer;
 CommandFound,Terminated:Boolean;
 CmdStr:String;
 CurrCommand,ParamList:String;
 I,J:Byte;

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
 WriteLn('csh - C Shell');
 WriteLn;
End;

Procedure ShowPrompt;Begin
 Write('%');
End;

Procedure AliasCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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

Procedure EchoCommand;Begin
 WriteLn(ParamList);
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
 For I:=1 to NumberHistory do WriteLn(History[I]^);
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

Procedure SetCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SetEnvCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SourceCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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

Procedure UnaliasCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UnhashCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UnlimitCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UnsetCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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

Procedure UnknownCommand;Begin
 WriteLn('Commande ou nom de fichier non reconnu');;
 WriteLn;
End;

BEGIN
 FillChar(History,SizeOf(History),0);
 NumberHistory:=0;
 FillChar(StackDirectory,SizeOf(StackDirectory),0);
 NumberDirectory:=0;
 Terminated:=False;
 HomeMessage;
 Repeat
  ShowPrompt;
  ReadLn(CmdStr);
  AddHistory(CmdStr);
  ExtractCommand;
  CommandFound:=False;
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
  If Not(CommandFound)Then UnknownCommand;
 Until Terminated;
END.
