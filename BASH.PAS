{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program BASH;

Uses Crt,DOS;

Const
 BashFileNameHistory={$IFDEF FPC}'.bash_history'{$ELSE}'.BASHIST'{$ENDIF};

 CommandList:Array[0..39]of String[16]=(
  'alias','bind','break','builtin','caller','cd','command',
  'continue','declare','echo','enable','eval','exec','exit',
  'export','getops','hash','help','history','let','local','logout',
  'mapfile','printf','pwd','read','readarray','readonly','return',
  'shift','source','test','times','trap','type','typeset','ulimit',
  'umask','unalias','unset'
 );

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
 CommandFound,Terminated,NoRC,Manual:Boolean;
 CmdStr,LogName:String;
 Option:(optNone,optCommand);
 BaseDir,CurrCommand,ParamList:String;
 I,J:Byte;
 History:Array[1..MaxHistory] of StrPointer;
 NumberHistory:LongInt;
 AliasList:PAliasRec;
 VariableList:PVariableRec;

Procedure RunScript(FileName:String);Forward;
Procedure RunCommandInternal;Forward;

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

Function PadZeroLeft(Value:String;Space:Byte):String;
Var
 S:String;
Begin
 S:=Value;
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

Procedure ChangeChar(Var Str:String;OldChar,NewChar:Char);
Var
 I:Byte;
Begin
 For I:=1 to Length(Str)do Begin
  If Str[I]=OldChar Then Str[I]:=NewChar;
 End;
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
 {$I-}Assign(History,BashFileNameHistory);
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
 {$I-}Assign(HistoryFile,BashFileNameHistory);
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
 WriteLn('bash - Bourne Again SHell');
 WriteLn;
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

Procedure BindCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BreakCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BuiltinCommand;Begin
 If ExtractParam(1)='--help'Then Begin
  WriteLn('builtin : Cette commande permet d''ex‚cuter une commande int‚grer ',
                     'dans BASH');
  WriteLn;
  WriteLn('Syntaxe : builtin commande parametres');
  WriteLn;
  WriteLn(' commande     La commande a ex‚cuter');
  WriteLn(' parameters   La listes des paramŠtres.');
 End
  Else
 Begin
  CmdStr:=ParamList;
  ExtractCommand;
  RunCommandInternal;
 End;
End;

Procedure CallerCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CdCommand;Begin
 If ExtractParam(1)='--help'Then Begin
  WriteLn('cd : Cette commande permet de changer le r‚pertoire courant.');
  WriteLn;
  WriteLn('Syntaxe : cd chemin');
  WriteLn;
  WriteLn(' chemin     Ce paramŠtre permet d''indiquer le nouveau chemin de r‚pertoire');
 End
  Else
 ChDir(ParamList);
End;

Procedure CommandCommand;
Var
 I:Integer;
 Param1,Param2:String;
Begin
 If ExtractParam(1)='--help'Then Begin
  WriteLn('command : Cette commande permet d''ex‚cuter la commande sp‚cifi‚');
  WriteLn;
  WriteLn('Syntaxe : command commande parametres');
  WriteLn;
  WriteLn(' commande     La commande a ex‚cuter');
  WriteLn(' parameters   La listes des paramŠtres.');
 End
  Else
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
End;

Procedure ContinueCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DeclareCommand;
Var
 S:String;
 P,I:Integer;
Begin
 S:=ExtractParam(1);
 P:=1;
 If S='--help'Then Begin
  WriteLn('declare : Cette commande permet de d‚clarer une variable.');
  WriteLn;
  WriteLn('Syntaxe : declare nom=valeur');
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
 If ExtractParam(1)='--help'Then Begin
  WriteLn('exec : Cette commande permet d''ex‚cuter la commande sp‚cifi‚');
  WriteLn;
  WriteLn('Syntaxe : exec commande parametres');
  WriteLn;
  WriteLn(' commande     La commande a ex‚cuter');
  WriteLn(' parameters   La listes des paramŠtres.');
  WriteLn(' --help  Affiche l''aide de cette commande');
 End
  Else
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

Procedure HistoryCommand;
Var
 FirstParam:String;
 I:LongInt;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='--help'Then Begin
  WriteLn('history : Cette commande permet d''afficher l''historique des ',
                     'commandes.');
  WriteLn;
  WriteLn('Syntaxe : history [option]');
  WriteLn;
  WriteLn(' -a   Ajoute l''historique dans le fichier d''historique');
  WriteLn(' -c   Efface l''historique');
  WriteLn(' -r   Charge l''historique du fichier d''historique');
  WriteLn(' -w   crit l''historique dans le fichier d''historique');
 End
  Else
 If FirstParam='-a'Then SaveHistory(True) Else
 If FirstParam='-c'Then ClearHistory Else
 If FirstParam='-r'Then Begin
  ClearHistory;
  LoadHistory;
 End
  Else
 If FirstParam='-w'Then SaveHistory(False) Else
 If FirstParam=''Then Begin
  IF NumberHistory>0 Then For I:=1 to NumberHistory do Begin
   Write(I:5);
   If History[I]^=''Then WriteLn('*')
                    Else WriteLn('  ',History[I]^);
  End;
 End
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
 If ExtractParam(1)='--help'Then Begin
  WriteLn('logout : Cette commande permet de se d‚connecter de ',
                    'l''interpr‚teur de commande et de retourner ',
                    'le code optionnel sp‚cifi‚ … l''interpr‚teur ',
                    'de commande.');
  WriteLn;
  WriteLn('Syntaxe : logout [n]');
  WriteLn;
  WriteLn(' n       Indique la valeur num‚rique … retourner');
  WriteLn(' --help  Affiche l''aide de cette commande');
 End
  Else
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

Procedure PrintfCommand;
Var
 CurrParam:Integer;
 I,PadLeft:Integer;
 Err:Word;
 S,R,T:String;
 ValueStr:String;
Begin
 If ExtractParam(1)='--help'Then Begin
  WriteLn('printf : Cette commande permet d''‚crire une chaine de ',
                    'caractŠres, selon un certain formatage, vers ',
                    'la sortie standard.');
  WriteLn;
  WriteLn('Syntaxe : printf format [arguments]');
  WriteLn;
  WriteLn(' format     Le format … utiliser');
  WriteLn(' arguments  La liste des paramŠtres … mettre dans le format');
  WriteLn(' --help     Affiche l''aide de cette commande');
 End
  Else
 Begin
  CurrParam:=2;
  S:=ExtractParam(1);
  R:='';
  I:=1;
  While I<=Length(S)do Begin
   If S[I]='$'Then Begin
    Inc(I);
    ValueStr:='';
    While(I<=Length(S))and(S[I]in['A'..'Z','a'..'z','0'..'9'])do Begin
     ValueStr:=ValueStr+S[I];
     Inc(I);
    End;
    R:=R+GetVariableValue(ValueStr);
    Dec(I);
   End
    Else
   If S[I]='\'Then Begin
    Inc(I);
    If I>Length(S)Then Break;
    Case S[I]of
     '0':R:=R+#0;
     'a':R:=R+#7;
     'b':R:=R+#8;
     'f':R:=R+#12;
     'n':R:=R+#10;
     'r':R:=R+#13;
     't':R:=R+#9;
     'v':R:=R+#11;
     '\':R:=R+'\';
     '''':R:=R+'''';
     '"':R:=R+'"';
     '?':R:=R+'?';
    End;
   End
    Else
   If S[I]='%'Then Begin
    Inc(I);
    If I>Length(S)Then Break;
    Case S[I]of
     'c':Begin
      ValueStr:=ExtractParam(CurrParam);
      Inc(CurrParam);
      If Length(ValueStr)>0 Then R:=R+ValueStr[1];
     End;
     'd','f','g','i','l':Begin
      T:=ExtractParam(CurrParam);
      Inc(CurrParam);
      R:=R+T;
     End;
     '0'..'9':Begin
      T:='';
      While(S[I]in['0'..'9'])and(I<=Length(S))do Begin
       T:=T+S[I];
       Inc(I);
      End;
      Val(T,PadLeft,Err);
      R:=R+PadZeroLeft(ExtractParam(CurrParam),PadLeft);
      Inc(CurrParam);
     End;
    End;
   End
    Else
   R:=R+S[I];
   Inc(I);
  End;
  WriteLn(R);
 End;
End;

Procedure PwdCommand;
Var
 CurrDir:String;
Begin
 If ExtractParam(1)='--help'Then Begin
  WriteLn('pwd : Cette commande permet d''afficher le chemin du ',
                 'r‚pertoire courant.');
  WriteLn;
  WriteLn('Syntaxe : pwd [--help]');
  WriteLn;
  WriteLn(' --help  Affiche l''aide de cette commande');
 End
  Else
 Begin
  GetDir(0,CurrDir);
  ChangeChar(CurrDir,'\','/');
  WriteLn(CurrDir);
 End;
End;

Procedure ReadCommand;
Var
 S:String;
Begin
 If ExtractParam(1)='--help'Then Begin
  WriteLn('read : Cette commande permet de lire une ligne sur ',
                  'l''entr‚e standard.');
  WriteLn;
  WriteLn('Syntaxe : read [variable]');
  WriteLn;
  WriteLn(' variable   Nom de la variable recevant les donn‚es');
  WriteLn(' --help  Affiche l''aide de cette commande');
 End
  Else
 If ExtractParam(1)=''Then ReadLn
  Else
 Begin
  ReadLn(S);
  AddVariable(ExtractParam(1),S);
 End;
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

Procedure ShowPrompt;Begin
 Write(LogName,'$ ');
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
    18:HistoryCommand;
    19:LetCommand;
    20:LocalCommand;
    21:LogoutCommand;
    22:MapfileCommand;
    23:PrintfCommand;
    24:PwdCommand;
    25:ReadCommand;
    26:ReadarrayCommand;
    27:ReadonlyCommand;
    28:ReturnCommand;
    29:ShiftCommand;
    30:SourceCommand;
    31:TestCommand;
    32:TimesCommand;
    33:TrapCommand;
    34:TypeCommand;
    35:TypesetCommand;
    36:UlimitCommand;
    37:UmaskCommand;
    38:UnaliasCommand;
    39:UnsetCommand;
   End;
   If J<=High(CommandList)Then Begin
    CommandFound:=True;
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
  I:=1;
  While(I<=Length(CmdStr))and(CmdStr[I]in['A'..'Z','a'..'z','0'..'9','-'])do Inc(I);
  If(I>1)and(I<=Length(CmdStr))Then Begin
   If CmdStr[I]='='Then Begin
    AddVariable(Copy(CmdStr,1,I-1),Copy(CmdStr,I+1,255));
    Exit;
   End;
  End;
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

Procedure ReadLine(Var S:String);
Var
 Rec:SearchRec;
 Dir:String;
 K:Char;
 X,Y:Byte;
 CurrHistory:LongInt;
Begin
 CurrHistory:=NumberHistory;
 X:=WhereX;
 Y:=WhereY;
 S:='';
 Repeat
  GotoXY(X,Y);
  TextColor(LightGray);
  For I:=1 to Length(S)do Begin
   If S[I]=' 'Then TextColor(Cyan);
   Write(S[I]);
  End;
  TextColor(Cyan);
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
   #9:If S<>''Then Begin
    For I:=Length(S) downto 1 do Begin
     If S[I]=' 'Then Begin
      Dir:=Path2Dir(Copy(S,I+1,255));
      FindFirst(Copy(S,I+1,255)+'*.*',AnyFile,Rec);
      If DosError=0 Then Begin
       S:=Copy(S,1,I)+Dir+Rec.Name;
      End;
      Break;
     End;
    End;
   End;
   Else S:=S+K;
  End;
  If S[Length(S)]=#13Then Begin
   S:=Copy(S,1,Length(S)-1);
   K:=#13;
  End;
 Until K=#13;
 GotoXY(X,Y);
 TextColor(LightGray);
 For I:=1 to Length(S)do Begin
  If S[I]=' 'Then TextColor(Cyan);
  Write(S[I]);
 End;
 TextColor(White);
 ClrEol;
 WriteLn
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BASH : Cette commande permet de lancer l''interpr‚teur de commande BASH.');
  WriteLn;
  WriteLn('Syntaxe : BASH [option] [script.sh]');
  WriteLn;
  WriteLn(' script.sh  Indique un script a ex‚cuter.');
  WriteLn(' -c cmd     Indique une commande a ex‚cuter.');
  WriteLn(' --cygwin   Recherche dans les dossiers de Cygwin');
  WriteLn(' --norc     Indique qu''il ne faut pas charger le fichier personnalis‚ ®.bashrc¯');
  WriteLn(' --help     Affiche l''aide de cette commande.');
  WriteLn(' --version  Indique la version de cette commande.');
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('BASH 1.0 - Clone Pascal de bash-0, linux, unix ou corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('crit par Sylvain Maltais');
 End
  Else
 Begin
  BaseDir:='';
  Manual:=True;
  NoRC:=False;
  NumberHistory:=0;
  FillChar(History,SizeOf(History),0);
  LoadHistory;
  AliasList:=NIL;
  VariableList:=NIL;
  Terminated:=False;
  Option:=optNone;
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
    If ParamStr(I)='--cygwin32'Then BaseDir:='/cygwin32' Else
    If ParamStr(I)='--norc'Then NoRC:=True
     Else
    Begin
     RunScript(ParamStr(I));
     Manual:=False;
    End;
   End;
  End;
  If(Manual)Then Begin
   If Not(NoRC)Then Begin
    If FileExist('.bashrc')Then RunScript('.bashrc');
   End;
   HomeMessage;
   Repeat
    ShowPrompt;
    ReadLine(CmdStr);
    RunCommand;
   Until Terminated;
   SaveHistory(False);
  End;
 End;
END.
