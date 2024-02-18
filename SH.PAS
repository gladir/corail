{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program SH;

Uses Crt,DOS;

Const
 CommandList:Array[0..81]of String[16]=(
  'alias','bind','break','builtin','caller','cat','cd','chdir','chmod',
  'chown','cmp','command','continue','cp','doscp','date','declare','df',
  'du','echo','enable','env','eval','exec','exit','export','file','find',
  'getops','hash','head','help','history','id','kill','let','ln','ll','local',
  'logout','ls','mail','mapfile','mkdir','more','mv','news','nm','od',
  'pr','printf','ps','pwd','read','readarray','readonly','return','rm',
  'rmdir','shift','size','source','split','stty','tail','tee','test',
  'times','tr','trap','tset','tty','type','typeset','ulimit','umask',
  'unalias','unset','wc','whereis','who','write'
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
 DeleteOption=Set Of (Question,Verbose);

Var
 CommandFound,Terminated,Manual:Boolean;
 CmdStr,LogName:String;
 Option:(optNone,optCommand);
 BaseDir,CurrCommand,ParamList:String;
 I,J:Byte;
 History:Array[1..MaxHistory] of StrPointer;
 NumberHistory:Integer;
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

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function PadZeroLeftStr(Value:String;Space:Byte):String;
Var
 S:String;
Begin
 S:=Value;
 While Length(S)<Space do S:='0'+S;
 PadZeroLeftStr:=S;
End;

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
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

Function GetErrorMessage(Code:Word):String;Begin
 Case Code of
  0:GetErrorMessage:='';
  2:GetErrorMessage:='Fichier introuvable';
  3:GetErrorMessage:='Chemin introuvable';
  4:GetErrorMessage:='Trop de fichiers ouvert';
  5:GetErrorMessage:='Acces refuse';
  6:GetErrorMessage:='Handle de fichier invalide';
  12:GetErrorMessage:='Mode d''acces sur disque invalide';
  15:GetErrorMessage:='Num‚ro de disque invalide';
  16:GetErrorMessage:='Impossible de supprimer le r‚pertoire';
  17:GetErrorMessage:='Impossible de renommer sur plusieurs volumes';
  100:GetErrorMessage:='Erreur de lecture … partir du disque';
  101:GetErrorMessage:='Erreur d''ecriture sur le disque';
  102:GetErrorMessage:='Fichier non attribue';
  103:GetErrorMessage:='Le fichier n''est pas ouvert';
  104:GetErrorMessage:='Le fichier n''est pas ouvert … l''entree';
  105:GetErrorMessage:='Le fichier n''est pas ouvert … la sortie';
  106:GetErrorMessage:='Numero invalide';
  150:GetErrorMessage:='Disque protege en ecriture';
  151:GetErrorMessage:='Peripherique est inconnu';
  152:GetErrorMessage:='Disque pas pret';
  153:GetErrorMessage:='Commande inconnue';
  154:GetErrorMessage:='Echec de verification CRC';
  155:GetErrorMessage:='Disque invalide';
  156:GetErrorMessage:='Erreur de recherche sur disque';
  157:GetErrorMessage:='Type de media invalide';
  158:GetErrorMessage:='Secteur introuvable';
  159:GetErrorMessage:='L''imprimante n''a plus de papier';
  160:GetErrorMessage:='Erreur d''ecriture sur le peripherique';
  161:GetErrorMessage:='Erreur de lecture sur le peripherique';
  162:GetErrorMessage:='Defaillance materielle';
  Else GetErrorMessage:='Erreur inconnue';
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

Function SplitFileName(s:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Splitfilename:=N+E;
End;

Function CopyFile(Source,Target:String;ShowProgression:Boolean):Boolean;
Var
 SourceFile,TargetFile:File;
 RecordsRead:Integer;
 Buffer:Array[1..1000]of Byte;
Begin
 CopyFile:=False;
 Assign(SourceFile,Source);
 {$I-}Reset(SourceFile,1);{$I+}
 If IOResult<>0Then Begin
  WriteLn('Fichier source introuvable ',Source);
  Exit;
 End;
 Assign(TargetFile,Target);
 {$I-}Rewrite(TargetFile,1);
 If(ShowProgression)Then WriteLn('. = 1000 octets de copies');
 BlockRead(SourceFile,Buffer,SizeOf(Buffer),RecordsRead);
 While RecordsRead>0 do Begin
  If(ShowProgression)Then Write('.');
  BlockWrite(TargetFile,Buffer,RecordsRead);
  BlockRead(SourceFile,Buffer,SizeOf(Buffer),RecordsRead);
 End;
 If(ShowProgression)Then WriteLn;
 Close(SourceFile);
 Close(TargetFile);
 {$I+}
 CopyFile:=True;
End;

Function MoveFile(Source,Target:String):Boolean;
Var
 F:File;
Begin
 If(Source='')or(Target='')Then Begin
  MoveFile:=False;
  Exit;
 End;
 Source:=FExpand(Source);
 Target:=FExpand(Target);
 If(Source[1]<>Target[1])and(Source[2]=':')Then Begin { Unite de disque different ?}
   { Copie le fichier }
  MoveFile:=CopyFile(Source,Target,False);
   { Supprime le fichier }
  {$I-}Assign(F,Source);
  Erase(F);
  {$I+}
 End
  Else
 Begin
  {$I-}
  Assign(F,Source);
  Rename(F,Target+'\'+SplitFileName(Source));
  MoveFile:=IOResult=0;
  {$I+}
 End;
End;

Function DeleteFile(FileName:String):Integer;
Var
 F:File;
Begin
 {$I-}Assign(F,FileName);
 Erase(F);
 {$I+}
 DeleteFile:=IoResult;
End;

Procedure DeleteTree(Option:DeleteOption;Dir:String);
Var
 Info:SearchRec;
 Err:Word;
Begin
 FindFirst(Dir+'\*.*',AnyFile,Info);
 While DOSError=0do Begin
  If Info.Attr and Directory=Directory Then Begin
   If(Info.Name<>'.')and(Info.Name<>'..')Then DeleteTree(Option,Dir+'\'+Info.Name);
  End
   Else
  Begin
   If(Question in Option)Then Begin
    Write('Supprimer ',Info.Name,' (O/N) ? ');
    Case ReadKey of
     #27:Exit;
     'O','o':Begin
      Err:=DeleteFile(Dir+'\'+Info.Name);
      WriteLn('Oui');
      If Err=0Then Begin
       If(Verbose in Option)Then WriteLn(Info.Name,' a ete supprime');
      End
       Else
      WriteLn(GetErrorMessage(Err));
     End;
     Else WriteLn('Non');
    End;
    WriteLn;
   End
    Else
   Begin
    Err:=DeleteFile(Dir+'\'+Info.Name);
    If Err=0Then Begin
     If(Verbose in Option)Then WriteLn(Info.Name,' a ete supprime');
    End
     Else
    WriteLn(GetErrorMessage(Err));
   End;
  End;
  FindNext(Info);
 End;
 {$I-}RmDir(Dir);{$I+}
END;

Procedure HomeMessage;Begin
 WriteLn;
 WriteLn('sh - Shell UNIX par defaut');
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
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CallerCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CatCommand;
Var
 I:Integer;
 Handle:Text;
 CurrLine:String;
Begin
 If(ExtractParam(1)='--help')or(ExtractParam(1)='-h')Then Begin
  WriteLn('cat : Cette commande permet d''afficher le contenu du fichier.');
  WriteLn;
  WriteLn('Syntaxe : cat <fichier>');
 End
  Else
 Begin
  I:=1;
  While I<10 do Begin
   If ExtractParam(I)=''Then Begin
    WriteLn('Fichier requis !');
    Break;
   End;
   Assign(Handle,ExtractParam(I));
   {$I-}Reset(Handle);{$I+}
   If IOResult=0Then Begin
    While NOT EOF(Handle)do Begin
     ReadLn(Handle,CurrLine);
     WriteLn(CurrLine);
    End;
    Close(Handle);
   End
    Else
   WriteLn('Impossible de lire ',ExtractParam(I));
   Inc(I);
  End;
 End
End;

Procedure CdCommand;Begin
 If(ExtractParam(1)='--help')or(ExtractParam(1)='-h')Then Begin
  WriteLn('chdir   Cette commande permet de fixer ou de demander le repertoire courant.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('cd [-h|--help] chemin');
  WriteLn('chdir [-h|--help] chemin');
  WriteLn;
  WriteLn('  -h     Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn('  -help  Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' chemin  Ce parametre permet d''indiquer le chemin du repertoire.');
 End
  Else
 Begin
  ChDir(ParamList);
 End;
End;

Procedure ChmodCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ChownCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CmpCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CommandCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ContinueCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CpCommand;
Var
 P:Byte;
 ShowVerbose:Boolean;
 F:File;
 CurrParam,Source,Target:String;
Begin
 P:=0;
 ShowVerbose:=False;
 Source:='';
 Target:='';
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    WriteLn('ParamŠtre requis');
   End;
   Break;
  End
   Else
  If(CurrParam='-h')or(CurrParam='--help')Then Begin
   WriteLn('cp   Cette commande permet d''effacer la copie de fichier vers un autre emplacement.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('cp [-h] [-v] source destination');
   WriteLn;
   WriteLn('    -h       Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('    -v       Ce parametre permet d''afficher les details');
   WriteLn('source       Ce parametre permet d''indiquer le fichier source');
   WriteLn('destination  Ce parametre permet d''indiquer le fichier destination');
   Exit;
  End
   Else
  If(CurrParam='-v')Then ShowVerbose:=True
   Else
  If CurrParam<>''Then
  Begin
   If Source=''Then Source:=CurrParam
               Else Target:=CurrParam;
  End;
  If P>9Then Break;
 Until CurrParam='';
 If(Source='')or(Target='')Then Begin
  WriteLn('La source et la destination sont requises');
 End
  Else
 Begin
  If CopyFile(Source,Target,ShowVerbose)Then WriteLn('1 fichier copie')
                                        Else WriteLn('Echec de copie de fichier');
 End;
End;

Procedure DoscpCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DateCommand;
Var
 Hour,Minute,Second,CentSec:Word;
 Year,Month,Day,DayOfMonth:Word;
Begin
 If(ExtractParam(1)='--help')or(ExtractParam(1)='-h')Then Begin
  WriteLn('date : Cette commande permet d''afficher le contenu du fichier.');
  WriteLn;
  WriteLn('Syntaxe : date [-h|--help]');
 End
  Else
 If ExtractParam(1)=''Then Begin
  GetDate(Year,Month,Day,DayOfMonth);
  Write(Year:4,'-',PadZeroLeft(Month,2),'-',PadZeroLeft(Day,2),' ');
  GetTime(Hour,Minute,Second,CentSec);
  Write(Hour:2,':',PadZeroLeft(Minute,2),':',PadZeroLeft(Second,2),',',CentSec);
 End
  Else
 WriteLn('Parametre non requis !');
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

Procedure DfCommand;
Var
 I:Char;
 Dsk:Byte;
Begin
 If(ExtractParam(1)='--help')or(ExtractParam(1)='-h')Then Begin
  WriteLn('df : Cette commande permet d''afficher l''espace libre sur les systemes de fichiers.');
  WriteLn;
  WriteLn('Syntaxe : df');
 End
  Else
 Begin
  WriteLn('Sys. fich.       Taille Util. Dispo Uti%');
  For I:='A' to 'Z' do Begin
   Dsk:=Ord(I)-Ord('A');
   If DiskSize(Dsk+1)<>-1Then Begin
    Write(I,':',' ':10);
    If DiskSize(Dsk+1)>1073741824Then Write(DiskSize(Dsk+1) shr 30:9,'G')Else
    If DiskSize(Dsk+1)>1048576Then Write(DiskSize(Dsk+1) shr 20:9,'M') Else
    If DiskSize(Dsk+1)>1024Then Write(DiskSize(Dsk+1) shr 10:9,'K')
                Else Write(DiskSize(Dsk+1):10);
    If(DiskSize(Dsk+1)-DiskFree(Dsk+1)>1073741824)Then Write((DiskSize(Dsk+1)-DiskFree(Dsk+1)) shr 30:5,'G') Else
    If(DiskSize(Dsk+1)-DiskFree(Dsk+1)>1048576)Then Write((DiskSize(Dsk+1)-DiskFree(Dsk+1))shr 20:5,'M')
                Else Write((DiskSize(Dsk+1)-DiskFree(Dsk+1)) shr 10:5,'K');
    If DiskFree(Dsk+1)>1073741824Then Write(DiskFree(Dsk+1) shr 30:5,'G')Else
    If DiskFree(Dsk+1)>1048576Then Write(DiskFree(Dsk+1) shr 20:5,'M') Else
    If DiskFree(Dsk+1)>1024Then Write(DiskFree(Dsk+1) shr 10:5,'K')
                Else Write(DiskFree(Dsk+1):10);
    Write(Trunc(((DiskSize(Dsk+1)-DiskFree(Dsk+1))/DiskSize(Dsk+1))*100):5,'%');
    WriteLn;
   End;
  End;
 End;
End;

Procedure DuCommand;Begin
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


Procedure EnableCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure EnvCommand;
Var
 I:Integer;
Begin
 If(ExtractParam(1)='--help')or(ExtractParam(1)='-h')Then Begin
  WriteLn('env : Cette commande permet d''afficher les variables d''environnement.');
  WriteLn;
  WriteLn('Syntaxe : env');
 End
  Else
 If ExtractParam(1)=''Then Begin
  For I:=0to EnvCount do WriteLn(EnvStr(I));
 End
  Else
 WriteLn('Parametre non requis !');
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

Procedure FileCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure FindCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure GetopsCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure HashCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure HeadCommand;
Var
 CurrSize,MaxLine,Err,MaxBuffer:Integer;
 I:Integer;
 FileView:Text;
 OptionFlag:(_None,_Lines,_Bytes);
 FileName,CurrLine:String;
 CurrParam:String;
Begin
 OptionFlag:=_None;
 MaxLine:=10;
 MaxBuffer:=32767;
 FileName:='';
 If(ExtractParam(1)='--help')or(ExtractParam(1)='-h')Then Begin
  WriteLn('head : Cette commande permet d''afficher le debut du fichier.');
  WriteLn;
  WriteLn('Syntaxe : head [--lines nombre] [--bytes nombre] <nomdufichier>');
 End
  Else
 Begin
  I:=1;
  While I<10 do Begin
   CurrParam:=ExtractParam(I);
   If CurrParam=''Then Break;
   If OptionFlag<>_None Then Begin
    Case OptionFlag of
     _Lines:Val(CurrParam,MaxLine,Err);
     _Bytes:Val(CurrParam,MaxBuffer,Err);
    End;
    OptionFlag:=_None;
   End
    Else
   If CurrParam='--lines'Then OptionFlag:=_Lines Else
   If CurrParam='--bytes'Then OptionFlag:=_Bytes Else
   If((Length(CurrParam)>=2) and (CurrParam[1]='-')and(CurrParam[2]in['0'..'9']))Then Begin
    Val(Copy(CurrParam,2,255),MaxLine,Err);
   End
    Else
   Begin
    FileName:=CurrParam;
    OptionFlag:=_None;
   End;
   Inc(I);
  End;
  If FileName<>''Then Begin
   I:=0;
   Assign(FileView,FileName);
   Reset(FileView);
   While Not EOF(FileView)do Begin
    ReadLn(FileView,CurrLine);
    WriteLn(CurrLine);
    Inc(CurrSize,Length(CurrLine));
    If CurrSize>MaxBuffer Then Break;
    Inc(I);
    If I>=MaxLine Then Break;
   End;
   Close(FileView);
  End
   Else
  WriteLn('Nom de fichier requis !');
 End;
End;

Procedure HelpCommand;
Var
 I:Byte;
Begin
 For I:=Low(CommandList) to High(CommandList) do Write(PadRight(CommandList[I],16));
End;

Procedure HistoryCommand;
Var
 I:Integer;
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If(FirstParam='-?')or((FirstParam='-h'))Then Begin
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

Procedure IdCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure KillCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LetCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LnCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LlCommand;Begin
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

Procedure LsCommand;
Var
 Option:Set of (_l,_sector,_time);
 I:Integer;
 Info:SearchRec;
 Path:String;
 T:DateTime;
Begin
 If(ExtractParam(1)='--help')or(ExtractParam(1)='-h')Then Begin
  WriteLn('ls : Cette commande permet d''afficher les fichiers d''un repertoire.');
  WriteLn;
  WriteLn('Syntaxe : ls [-l] [-s] [-t] [<repertoire>]');
 End
  Else
 Begin
  Option:=[];
  Path:='*.*';
  I:=1;
  While I<10 do Begin
   If ExtractParam(I)=''Then Break Else
   If ExtractParam(I)='-l'Then Include(Option,_l) Else
   If ExtractParam(I)='-s'Then Include(Option,_sector)Else
   If ExtractParam(I)='-t'Then Include(Option,_time)
                          Else Path:=ExtractParam(I);
   Inc(I);
  End;
  FindFirst(Path,AnyFile,Info);
  While DosError=0 do Begin
   If Not((Info.Name='.')or(Info.Name='..'))Then Begin
    If(_l)in(Option)Then Begin { Affiche les attributs? }
     If(Info.Attr and Directory=Directory)Then Write('d')
                                          Else Write('-');
     If(Info.Attr and ReadOnly=ReadOnly)Then Write('r')
                                        Else Write('w');
     If(Info.Attr and SysFile=SysFile)Then Write('s')
                                      Else Write('-');
     If(Info.Attr and Hidden=Hidden)Then Write('h')
                                    Else Write('-');
     If(Info.Attr and Archive=Archive)Then Write('a')
                                      Else Write('-');
     Write(' ');
    End;
    If(_Sector)in(Option)Then Begin
     Write((Info.Size shr 9)+Byte((Info.Size and$1FF)>0):10,' ');
    End;
    If(_Time)in(Option)Then Begin
     UnpackTime(Info.Time,T);
     Write(' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2),' ');
    End;
    Write(Info.Name);
    WriteLn;
   End;
   FindNext(Info);
  End;
 End;
End;

Procedure MailCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure MapfileCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure MkdirCommand;
Var
 P:Byte;
 Err:Word;
 CurrParam:String;
Begin
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    WriteLn('ParamŠtre requis');
   End;
   Break;
  End
   Else
  If(CurrParam='-h')or(CurrParam='--help')Then Begin
   WriteLn('mkdir   Cette commande permet de creer un repertoire.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('mkdir [-h|--help] nomrepertoire');
   WriteLn;
   WriteLn('  nomrepertoire   Ce parametre permet d''indiquer le nom du repertoire');
   WriteLn('            -h    Ce parametre permet d''afficher l''aide sur cette commande');
   Exit;
  End;
  {$I-}MkDir(CurrParam);{$I+}
  Err:=IoResult;
  If Err<>0Then WriteLn('Impossible de creer le repertoire');
  If P>9Then Break;
 Until CurrParam='';
End;

Procedure MoreCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure MvCommand;
Var
 CurrParam1,CurrParam2:String;
Begin
 If(ExtractParam(1)='/?')or(ExtractParam(1)='--help')or(ExtractParam(1)='-h')Then Begin
  WriteLn('mv : Cette commande permet de deplacer un fichier.');
  WriteLn;
  WriteLn('Syntaxe : mv source destination');
 End
  Else
 Begin
  CurrParam1:=ExtractParam(1);
  CurrParam2:=ExtractParam(2);
  If(CurrParam1<>'')and(CurrParam2<>'')Then Begin
   If Not MoveFile(CurrParam1,CurrParam2)Then Begin
    WriteLn('Erreur de d‚placement du fichier.');
   End;
  End
   Else
  WriteLn('Nombre de parametre invalide');
 End;
End;

Procedure NewsCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure NmCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure OdCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PrCommand;Begin
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
      R:=R+PadZeroLeftStr(ExtractParam(CurrParam),PadLeft);
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

Procedure PsCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PwdCommand;
Var
 CurrDir:String;
Begin
 If(ExtractParam(1)='--help')or(ExtractParam(1)='-h')Then Begin
  WriteLn('pwd : Cette commande permet d''afficher le repertoire de travail.');
  WriteLn;
  WriteLn('Syntaxe : pwd');
 End
  Else
 If ExtractParam(1)=''Then Begin
  GetDir(0,CurrDir);
  ChangeChar(CurrDir,'\','/');
  WriteLn(CurrDir);
 End
  Else
 WriteLn('Parametre non requis !');
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

Procedure RmCommand;
Var
 Mode:(_None,_r);
 P:Byte;
 Err:Word;
 Option:DeleteOption;
 CurrParam:String;
Begin
 Mode:=_None;
 Option:=[];
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    WriteLn('ParamŠtre requis');
   End;
   Break;
  End
   Else
  If Mode=_r Then Begin
   DeleteTree(Option,CurrParam);
  End
   Else
  If(CurrParam='-h')or(CurrParam='--help')Then Begin
   WriteLn('rm   Cette commande permet d''effectuer la suppression de fichier sur un unite de disque.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('rm [-h] [-i][-v] [-r repertoire] [fichier]');
   WriteLn;
   WriteLn('    -h          Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('    -i          Ce parametre permet de demander une confirmation avant de supprimer');
   WriteLn('    -r          Ce parametre permet de supprimer le repertoire recursivement');
   WriteLn('    --recursive Ce parametre permet de supprimer le repertoire recursivement');
   WriteLn('    -v          Ce parametre permet d''afficher les fichiers supprimees.');
   WriteLn('    --verbose   Ce parametre permet d''afficher les fichiers supprimees.');
   WriteLn(' fichier        Ce parametre permet d''indiquer le nom du fichier a supprimer.');
   Exit;
  End
   Else
  If CurrParam='-i'Then Include(Option,Question) Else
  If(CurrParam='-r')or(CurrParam='--recursive')Then Mode:=_r Else
  If(CurrParam='-v')or(CurrParam='--verbose')Then Include(Option,Verbose)
   Else
  Begin
   If(Question in Option)Then Begin
    Write('Supprimer ',CurrParam,' (O/N) ? ');
    Case ReadKey of
     #27:Exit;
     'O','o':Begin
      Err:=DeleteFile(CurrParam);
      WriteLn('Oui');
      If Err=0Then Begin
       If(Verbose in Option)Then WriteLn(CurrParam,' a ete supprime');
      End
       Else
      WriteLn(GetErrorMessage(Err));
     End;
     Else WriteLn('Non');
    End;
    WriteLn;
   End
    Else
   Begin
    Err:=DeleteFile(CurrParam);
    If Err=0Then Begin
     If(Verbose in Option)Then WriteLn(CurrParam,' a ete supprime');
    End
     Else
    WriteLn(GetErrorMessage(Err));
   End;
  End;
  If P>99Then Break;
 Until CurrParam='';
End;

Procedure RmdirCommand;
Var
 P:Byte;
 Err:Word;
 CurrParam:String;
Begin
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    WriteLn('ParamŠtre requis');
   End;
   Break;
  End
   Else
  If(CurrParam='-h')or(CurrParam='--help')Then Begin
   WriteLn('rmdir   Cette commande permet de supprimer un repertoire vide.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('rmdir [-h|--help] <nomrepertoire>');
   WriteLn;
   WriteLn('  -h           Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('  -help        Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('nomrepertoire  Ce parametre permet d''indiquer le nom du repertoire');
   Exit;
  End;
  {$I-}RmDir(CurrParam);{$I+}
  Err:=IoResult;
  If Err<>0Then WriteLn('Suppression de repertoire impossible !');
  If P>9Then Break;
 Until CurrParam='';
End;

Procedure ShiftCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SizeCommand;Begin
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

Procedure SplitCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SttyCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TailCommand;
Var
 OptionFlag:(_None,_Lines,_Bytes);
 I,CurrLinePos,MaxBuffer,MaxLine:Integer;
 EndPos,CurrEndPos:LongInt;
 ByteReaded:Integer;
 NumLine,Err:Word;
 FindEnd:Boolean;
 FileView:File{$IFDEF FPC}of Byte{$ENDIF};
 Buffer:Array[0..255]of Byte;
 FileName,CurrLine:String;
 CurrParam:String;
Begin
 OptionFlag:=_None;
 MaxLine:=10;
 MaxBuffer:=32767;
 FileName:='';
 If(ExtractParam(1)='/?')or(ExtractParam(1)='--help')or(ExtractParam(1)='-h')Then Begin
  WriteLn('tail : Cette commande permet d''afficher la fin du fichier.');
  WriteLn;
  WriteLn('Syntaxe : tail [--lines lignes] [--bytes octets] nomdufichier');
 End
  Else
 If ExtractParam(1)<>''Then Begin
  I:=1;
  While ExtractParam(I)<>''do Begin
   CurrParam:=ExtractParam(I);
   If OptionFlag<>_None Then Begin
    Case OptionFlag of
     _Lines:Val(CurrParam,MaxLine,Err);
     _Bytes:Val(CurrParam,MaxBuffer,Err);
    End;
    OptionFlag:=_None;
   End
    Else
   If CurrParam='--lines'Then OptionFlag:=_Lines Else
   If CurrParam='--bytes'Then OptionFlag:=_Bytes Else
   If Copy(CurrParam,1,8)='--bytes='Then Begin
    Val(Copy(CurrParam,9,255),MaxBuffer,Err);
   End
    Else
   If Copy(CurrParam,1,8)='--lines='Then Begin
    Val(Copy(CurrParam,9,255),Maxline,Err);
   End
    Else
   If((Length(CurrParam)>=2) and (CurrParam[1]='-')and(CurrParam[2] in['0'..'9']))Then Begin
    Val(Copy(CurrParam,2,255),MaxLine,Err);
   End
    Else
   Begin
    FileName:=CurrParam;
    OptionFlag:=_None;
   End;
   Inc(I);
  End;
  CurrLinePos:=0;
  {$I-}Assign(FileView,FileName);
  Reset(FileView);{$I+}
  If IOResult<>0Then Begin
   WriteLn('Fichier introuvable ou impossible a lire !');
   Halt;
  End;
  EndPos:=FileSize(FileView);
  NumLine:=0;FindEnd:=False;
  If MaxBuffer<>32767Then Begin
   Dec(EndPos,MaxBuffer);
   If EndPos < 0Then EndPos:=0;
   MaxLine := 1000;
  End
   Else
  Repeat
   CurrEndPos:=EndPos-SizeOf(Buffer);
   If CurrEndPos<0Then CurrEndPos:=0;
   Seek(FileView,CurrEndPos);
   BlockRead(FileView,Buffer,SizeOf(Buffer),ByteReaded);
   If ByteReaded<=0Then Break;
   For I:=ByteReaded-1 downto 0do Begin
    If Buffer[I]=10Then Begin
     Inc(NumLine);
     If NumLine>MaxLine Then Begin
      Dec(EndPos,SizeOf(Buffer)-I);
      FindEnd:=True;
      Break;
     End;
    End;
   End;
   If(FindEnd)Then Break;
   Dec(EndPos,ByteReaded);
  Until EndPos<=0;
  Seek(FileView,EndPos);
  While Not EOF(FileView)do Begin
   BlockRead(FileView,Buffer,SizeOf(Buffer),ByteReaded);
   If ByteReaded=0Then Break;
   For I:=0 to ByteReaded-1 do Begin
    Case Buffer[I]of
     13:Begin
      Inc(CurrLinePos);
      WriteLn;
     End;
     10:;
     Else Write(Char(Buffer[I]));
    End;
   End;
   If CurrLinePos>=MaxLine Then Break;
  End;
  Close(FileView);
 End
  Else
 WriteLn('Parametre requis !');
End;

Procedure TeeCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TestCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TimesCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TrCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TrapCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TsetCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TtyCommand;Begin
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

Procedure WcCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure WhereisCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure WhoCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure WriteCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ShowPrompt;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 ChangeChar(CurrentDir,'\','/');
 Write(CurrentDir,'$');
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
    5:CatCommand;
    6:CdCommand;
    7:CdCommand;
    8:ChmodCommand;
    9:ChownCommand;
    10:CmpCommand;
    11:CommandCommand;
    12:ContinueCommand;
    13:CpCommand;
    14:DoscpCommand;
    15:DateCommand;
    16:DeclareCommand;
    17:DfCommand;
    18:DuCommand;
    19:EchoCommand;
    20:EnableCommand;
    21:EnvCommand;
    22:EvalCommand;
    23:ExecCommand;
    24:ExitCommand;
    25:ExportCommand;
    26:FileCommand;
    27:FindCommand;
    28:GetopsCommand;
    29:HashCommand;
    30:HeadCommand;
    31:HelpCommand;
    32:HistoryCommand;
    33:IdCommand;
    34:KillCommand;
    35:LetCommand;
    36:LnCommand;
    37:LlCommand;
    38:LocalCommand;
    39:LogoutCommand;
    40:LsCommand;
    41:MailCommand;
    42:MapfileCommand;
    43:MkdirCommand;
    44:MoreCommand;
    45:MvCommand;
    46:NewsCommand;
    47:NmCommand;
    48:OdCommand;
    49:PrCommand;
    50:PrintfCommand;
    51:PsCommand;
    52:PwdCommand;
    53:ReadCommand;
    54:ReadarrayCommand;
    55:ReadonlyCommand;
    56:ReturnCommand;
    57:RmCommand;
    58:RmdirCommand;
    59:ShiftCommand;
    60:SizeCommand;
    61:SourceCommand;
    62:SplitCommand;
    63:SttyCommand;
    64:TailCommand;
    65:TeeCommand;
    66:TestCommand;
    67:TimesCommand;
    68:TrCommand;
    69:TrapCommand;
    70:TsetCommand;
    71:TtyCommand;
    72:TypeCommand;
    73:TypesetCommand;
    74:UlimitCommand;
    75:UmaskCommand;
    76:UnaliasCommand;
    77:UnsetCommand;
    78:WcCommand;
    79:WhereisCommand;
    80:WhoCommand;
    81:WriteCommand;
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
 WriteLn(S);
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('SH : Cette commande permet de lancer l''interpreteur de commande standard UNIX.');
  WriteLn;
  WriteLn('Syntaxe : SH [option] [script.sh]');
  WriteLn;
  WriteLn(' script.sh  Indique un script a ex‚cuter.');
  WriteLn(' -c cmd     Indique une commande a ex‚cuter.');
  WriteLn(' --cygwin   Recherche dans les dossiers de Cygwin');
  WriteLn(' --help     Affiche l''aide de cette commande.');
  WriteLn(' --version  Indique la version de cette commande.');
 End
  Else
 Begin
  BaseDir:='';
  Manual:=True;
  FillChar(History,SizeOf(History),0);
  NumberHistory:=0;
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
    If ParamStr(I)='--cygwin32'Then BaseDir:='/cygwin32'
     Else
    Begin
     RunScript(ParamStr(I));
     Manual:=False;
    End;
   End;
  End;
  If(Manual)Then Begin
   HomeMessage;
   Repeat
    ShowPrompt;
    ReadLine(CmdStr);
    RunCommand;
   Until Terminated;
  End;
 End;
END.
