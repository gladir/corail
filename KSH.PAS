{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
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

Var
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

Procedure ChangeChar(Var Str:String;OldChar,NewChar:Char);
Var
 I:Byte;
Begin
 For I:=1 to Length(Str)do Begin
  If Str[I]=OldChar Then Str[I]:=NewChar;
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

Procedure HomeMessage;Begin
 WriteLn;
 WriteLn('ksh - Korn SHell');
 WriteLn;
End;

Procedure ShowPrompt;Begin
 Write('$');
End;

Procedure AliasCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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

Procedure EchoCommand;Begin
 WriteLn(ParamList);
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

Procedure TypesetCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UlimitCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UmaskCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UnaliasCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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

BEGIN
 Terminated:=False;
 HomeMessage;
 Repeat
  ShowPrompt;
  ReadLn(CmdStr);
  ExtractCommand;
  CommandFound:=False;
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
  If Not(CommandFound)Then UnknownCommand;
 Until Terminated;
END.