{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program BASH;

Uses Crt,DOS;

Const
 CommandList:Array[0..38]of String[16]=(
  'alias','bind','break','builtin','caller','cd','command',
  'continue','declare','echo','enable','eval','exec','exit',
  'export','getops','hash','help','let','local','logout',
  'mapfile','printf','pwd','read','readarray','readonly','return',
  'shift','source','test','times','trap','type','typeset','ulimit',
  'umask','unalias','unset'
 );

 MaxHistory=100;

Type
 StrPointer=^String;

Var
 CommandFound,Terminated:Boolean;
 CmdStr:String;
 CurrCommand,ParamList:String;
 I,J:Byte;
 History:Array[1..MaxHistory] of StrPointer;
 NumberHistory:Integer;

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
 WriteLn('bash - Bourne Again SHell');
 WriteLn;
End;

Procedure AliasCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BindCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BreakCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BuiltinCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CallerCommand;Begin
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

Procedure DeclareCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure EchoCommand;Begin
 WriteLn(ParamList);
End;

Procedure EnableCommand;Begin
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

Procedure ExportCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure GetopsCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure HashCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure HelpCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LetCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LocalCommand;Begin
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

Procedure MapfileCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PrintfCommand;Begin
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

Procedure ReadarrayCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ReadonlyCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ReturnCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ShiftCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SourceCommand;Begin
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

Procedure TypeCommand;Begin
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

Procedure ShowPrompt;Begin
 Write('$');
End;

Procedure UnknownCommand;Begin
 WriteLn('Commande ou nom de fichier non reconnu');;
 WriteLn;
End;

Procedure ReadLine(Var S:String);
Var
 K:Char;
 X,Y:Byte;
 CurrHistory:Integer;
Begin
 CurrHistory:=NumberHistory;
 X:=WhereX;
 Y:=WhereY;
 S:='';
 Repeat
  GotoXY(X,Y);
  Write(S);
  ClrEol;
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #72:If NumberHistory>0 Then Begin
     S:=History[CurrHistory]^; { Up }
     If CurrHistory>1 Then Dec(CurrHistory);
    End;
    #80:If NumberHistory>0 Then Begin
     S:=History[CurrHistory]^; { Down }
     If CurrHistory<NumberHistory Then Inc(CurrHistory);
    End;
   End;
   #8:Begin
    If S<>''Then S:=Copy(S,1,Length(S)-1);
   End;
   Else S:=S+K;
  End;
  If S[Length(S)]=#13Then Begin
   S:=Copy(S,1,Length(S)-1);
   K:=#13;
  End;
 Until K=#13;
 GotoXY(X,Y);
 WriteLn(S);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BASH : Cette commande permet de lancer l''interpreteur de commande BASH.');
  WriteLn;
  WriteLn('Syntaxe : BASH');
 End
  Else
 Begin
  FillChar(History,SizeOf(History),0);
  NumberHistory:=0;
  Terminated:=False;
  HomeMessage;
  Repeat
   ShowPrompt;
   ReadLine(CmdStr);
   AddHistory(CmdStr);
   ExtractCommand;
   CommandFound:=False;
   For J:=Low(CommandList) to High(CommandList) do Begin
    If CurrCommand=CommandList[J]Then Begin
     Case(J)of
      0:AliasCommand;
      1:BindCommand;
      2:BreakCommand;
      3:BuiltinCommand;
      4:CallerCommand;
      5:CdCommand;
      6:CommandCommand;
      7:ContinueCommand;
      8:DeclareCommand;
      9:EchoCommand;
      10:EnableCommand;
      11:EvalCommand;
      12:ExecCommand;
      13:ExitCommand;
      14:ExportCommand;
      15:GetopsCommand;
      16:HashCommand;
      17:HelpCommand;
      18:LetCommand;
      19:LocalCommand;
      20:LogoutCommand;
      21:MapfileCommand;
      22:PrintfCommand;
      23:PwdCommand;
      24:ReadCommand;
      25:ReadarrayCommand;
      26:ReadonlyCommand;
      27:ReturnCommand;
      28:ShiftCommand;
      29:SourceCommand;
      30:TestCommand;
      31:TimesCommand;
      32:TrapCommand;
      33:TypeCommand;
      34:TypesetCommand;
      35:UlimitCommand;
      36:UmaskCommand;
      37:UnaliasCommand;
      38:UnsetCommand;
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
 End;
END.
