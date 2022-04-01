{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program SH;

Uses Crt,DOS;

Const
 CommandList:Array[0..80]of String[16]=(
  'alias','bind','break','builtin','caller','cat','cd','chdir','chmod',
  'chown','cmp','command','continue','cp','doscp','date','declare','df',
  'du','echo','enable','env','eval','exec','exit','export','file','find',
  'getops','hash','head','help','id','kill','let','ln','ll','local',
  'logout','ls','mail','mapfile','mkdir','more','mv','news','nm','od',
  'pr','printf','ps','pwd','read','readarray','readonly','return','rm',
  'rmdir','shift','size','source','split','stty','tail','tee','test',
  'times','tr','trap','tset','tty','type','typeset','ulimit','umask',
  'unalias','unset','wc','whereis','who','write'
 );

Type
 DeleteOption=Set Of (Question,Verbose);

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

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
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

Function GetErrorMessage(Code:Word):String;Begin
 Case Code of
  0:GetErrorMessage:='';
  2:GetErrorMessage:='Fichier introuvable';
  3:GetErrorMessage:='Chemin introuvable';
  4:GetErrorMessage:='Trop de fichiers ouvert';
  5:GetErrorMessage:='Acces refuse';
  6:GetErrorMessage:='Handle de fichier invalide';
  12:GetErrorMessage:='Mode d''acces sur disque invalide';
  15:GetErrorMessage:='NumÇro de disque invalide';
  16:GetErrorMessage:='Impossible de supprimer le rÇpertoire';
  17:GetErrorMessage:='Impossible de renommer sur plusieurs volumes';
  100:GetErrorMessage:='Erreur de lecture Ö partir du disque';
  101:GetErrorMessage:='Erreur d''ecriture sur le disque';
  102:GetErrorMessage:='Fichier non attribue';
  103:GetErrorMessage:='Le fichier n''est pas ouvert';
  104:GetErrorMessage:='Le fichier n''est pas ouvert Ö l''entree';
  105:GetErrorMessage:='Le fichier n''est pas ouvert Ö la sortie';
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

Function CopyFile(Source,Target:String):Boolean;
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
 BlockRead(SourceFile,Buffer,SizeOf(Buffer),RecordsRead);
 While RecordsRead>0 do Begin
  BlockWrite(TargetFile,Buffer,RecordsRead);
  BlockRead(SourceFile,Buffer,SizeOf(Buffer),RecordsRead);
 End;
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
  MoveFile:=CopyFile(Source,Target);
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

Procedure CpCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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

Procedure DeclareCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DfCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DuCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure EchoCommand;Begin
 WriteLn(ParamList);
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
    WriteLn('Paramätre requis');
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
    WriteLn('Erreur de dÇplacement du fichier.');
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

Procedure PrintfCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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
    WriteLn('Paramätre requis');
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
    WriteLn('Paramätre requis');
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
 WriteLn('Cette commande n''est pas mise en oeuvre');
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
     32:IdCommand;
     33:KillCommand;
     34:LetCommand;
     35:LnCommand;
     36:LlCommand;
     37:LocalCommand;
     38:LogoutCommand;
     39:LsCommand;
     40:MailCommand;
     41:MapfileCommand;
     42:MkdirCommand;
     43:MoreCommand;
     44:MvCommand;
     45:NewsCommand;
     46:NmCommand;
     47:OdCommand;
     48:PrCommand;
     49:PrintfCommand;
     50:PsCommand;
     51:PwdCommand;
     52:ReadCommand;
     53:ReadarrayCommand;
     54:ReadonlyCommand;
     55:ReturnCommand;
     56:RmCommand;
     57:RmdirCommand;
     58:ShiftCommand;
     59:SizeCommand;
     60:SourceCommand;
     61:SplitCommand;
     62:SttyCommand;
     63:TailCommand;
     64:TeeCommand;
     65:TestCommand;
     66:TimesCommand;
     67:TrCommand;
     68:TrapCommand;
     69:TsetCommand;
     70:TtyCommand;
     71:TypeCommand;
     72:TypesetCommand;
     73:UlimitCommand;
     74:UmaskCommand;
     75:UnaliasCommand;
     76:UnsetCommand;
     77:WcCommand;
     78:WhereisCommand;
     79:WhoCommand;
     80:WriteCommand;
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
