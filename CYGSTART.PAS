{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal (OS/2), Free Pascal (Windows))
}

Program CYGSTART;

{$IFDEF Windows}
 Uses DOS,Strings,Windows,ShellAPI;
{$ELSE}
 Uses DOS,Strings;
{$ENDIF}

Const
 {$IFNDEF Windows}
  SW_HIDE=0;
  SW_SHOWNORMAL=1;
  SW_NORMAL=1;
  SW_SHOWMINIMIZED=2;
  SW_SHOWMAXIMIZED=3;
  SW_MAXIMIZE=3;
  SW_SHOWNOACTIVATE=4;
  SW_SHOW=5;
  SW_MINIMIZE=6;
  SW_SHOWMINNOACTIVE=7;
  SW_SHOWNA=8;
  SW_RESTORE=9;
  SW_SHOWDEFAULT=10;
  SW_FORCEMINIMIZE=11;
 {$ENDIF}
 { Relation du processus }
 prNew=$0001;                { Ind‚pendant }
 prChild=$0002;              { Enfant }

  { Priorit‚ de la session }
 prForeground=$0000;         { Premier plan }
 prBackground=$0001;         { ArriŠre plan }

  { ModŠle de session }
 stDefault=$0000;            { Par d‚faut }
 stOS2FullScrn=$0001;        { OS/2 Plein ‚cran }
 stOS2Window=$0002;          { OS/2 en fenˆtre }
 stPM=$0003;                 { Gestionnaire de pr‚sentation d'OS/2 }
 stDosFullScrn=$0004;        { Dos pleine ‚cran }
 stDosWindow=$0007;          { Dos en fenˆtre }

Type
 OS2StartData=Record
  LenStruct:Word;       { Longueur de la structure (peut ˆtre }
                         { 0018h, 001Eh, 0020h, 0032h, 003Ch) }
  Process:Word;         { Relation du nouveau processus (pr??): }
                         { 0000h = Ind‚pendant, 0001h = Enfant}
  Priority:Word;        { Priorit‚ de la session: }
                         { 0000h = Premier plan }
                         { 0001h = ArriŠre plan }
  Trace:Word;           { Les options de traces }
  Title:PChar;          { Titre du programme }
  Name:PChar;           { Nom du programme }
  Args:PChar;           { Argument du programme }
  TermQ:PChar;          { "TermQ"}
  Environment:PChar;    { Variable d'environnement }
  Inherit:WordBool;     { H‚ritier des donn‚es }
  SessionType:Word;     { ModŠle de session (st????) }
  Icon:PChar;           { Nom de l'ic“ne }
  PgmHandle:PChar;      { Le "PgmHandle" }
  PgmControl:Word;      { Le "PgmControl" }
  Column:Word;          { Colonne }
  Row:Word;             { Ligne }
  Width:Word;           { Largeur }
  Height:Word;          { Hauteur }
  Reserved:Word;        { R‚serv‚e }
  ObjectBuffer:LongInt; { Pointeur sur le tampon d'objet }
  ObjectBufferLen:Word; { Longueur du tampon d'objet }
 End;

Var
 Mode,I:Integer;
 Action,Title,Command,Param,WorkingDir:String;

{$IFNDEF Windows}
 Function OS2Exec(Const Data:OS2StartData):Word;Assembler;ASM
  PUSH DS
   LDS SI,Data
   MOV AH,064h
   MOV BX,0025h
   MOV CX,636Ch
   INT 21h
  POP DS
 END;
{$ENDIF}

Procedure WinStart(Command,Param:String;Mode:Integer);
Var
 TCommand,TWorkDir,TAction,TParam:Array[0..255]of Char;
 {$IFDEF Windows}
  Hdl:Handle;
 {$ELSE}
  Data:OS2StartData;
 {$ENDIF}
Begin
 StrPCopy(TCommand,Command);
 StrPCopy(TWorkDir,WorkingDir);
 StrPCopy(TAction,Action);
 StrPCopy(TParam,Param);
 {$IFDEF Windows}
  Hdl:=0;
  ShellExecute(Hdl,@TAction,@TCommand,@TParam,@TWorkDir,Mode);
 {$ELSE}
  FillChar(Data,SizeOf(Data),0);
  Data.LenStruct:=$32;
  Data.Process:=prNew;
  Case Mode of
   SW_HIDE,SW_SHOWMINIMIZED:Data.Priority:=prBackground;
   SW_SHOWMAXIMIZED,SW_MAXIMIZE:Begin
    Data.Priority:=prForeground;
    Data.SessionType:=stDosFullScrn;
   End
   Else Data.Priority:=prForeground;
  End;
  StrPCopy(Data.Title,Title);
  If Copy(Command,Length(Command)-3,4)='.BAT'Then Begin
   StrPCopy(Data.Args,'/C'+Command);
  End
   Else
  Begin
   StrPCopy(Data.Name,Command);
   StrPCopy(Data.Args,Param);
  End;
  OS2Exec(Data);
 {$ENDIF}
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CYGSTART : Cette commande permet de d‚marrer un programme, ',
                      'ouvrir un fichier ou une URL.');
  WriteLn;
  WriteLn('Syntaxe : CYGSTART [options] command [arguments]');
  WriteLn;
  WriteLn(' command           Indique le programme, le fichier ou l''URL');
  WriteLn(' arguments         Indique les paramŠtres de la commande');
  WriteLn(' --action=action   Indique le nom de l''action … appliquer');
  WriteLn(' --directory=r‚p   Indique le r‚pertoire de travail');
  WriteLn(' --edit            Applique l''action d''‚diter');
  WriteLn(' --explore         Applique l''action d''explorer');
  WriteLn(' --find            Applique l''action de rechercher');
  WriteLn(' --hide            Indique de cacher la fenˆtre');
  WriteLn(' --maximize        Indique qu''il faut avoir la fenˆtre … la taille maximum');
  WriteLn(' --minimize        Indique qu''il faut avoir la fenˆtre … la taille minimum');
  WriteLn(' --open            Applique l''action d''ouverture');
  WriteLn(' --print           Applique l''action d''imprimer');
  WriteLn(' --restore         Active et affiche la fenˆtre');
  WriteLn(' --show            Indique d''afficher la fenˆtre');
  WriteLn(' --showmaximized   Affiche et maximise la fenˆtre');
  WriteLn(' --showminimized   Affiche et minimise la fenˆtre');
  WriteLn(' --showminnoactive Affiche la fenˆtre sous forme de fenˆtre r‚duite.');
  WriteLn(' --showna          Affiche la fenˆtre dans son ‚tat actuel.');
  WriteLn(' --shownoactivate  Affiche une fenˆtre dans sa taille et sa position ');
  WriteLn('                   les plus r‚centes.');
  WriteLn(' --shownormal      Active et affiche une fenˆtre.');
  WriteLn(' --title=titre     Indique le nom de la fenˆtre');
 End
  Else
 Begin
  Mode:=SW_SHOW;
  Command:='';
  Param:='';
  Title:='';
  Action:='';
  WorkingDir:=GetEnv('WINDIR');
  For I:=1 to ParamCount do Begin
   If Copy(ParamStr(I),1,Length('--action='))='--action='Then Begin
    Action:=Copy(ParamStr(I),Length('--action=')+1,255);
   End
    Else
   If Copy(ParamStr(I),1,Length('--directory='))='--directory='Then Begin
    WorkingDir:=Copy(ParamStr(I),Length('--directory=')+1,255);
   End
    Else
   If(ParamStr(I)='--edit')or(ParamStr(I)='-e')Then Action:='edit' Else
   If(ParamStr(I)='--explore')or(ParamStr(I)='-x')Then Action:='explore' Else
   If(ParamStr(I)='--find')or(ParamStr(I)='-f')Then Action:='find' Else
   If ParamStr(I)='--hide'Then Mode:=SW_HIDE Else
   If ParamStr(I)='--maximize'Then Mode:=SW_MAXIMIZE Else
   If ParamStr(I)='--minimize'Then Mode:=SW_MINIMIZE Else
   If(ParamStr(I)='--open')or(ParamStr(I)='-o')Then Action:='open' Else
   If(ParamStr(I)='--print')or(ParamStr(I)='-p')Then Action:='print' Else
   If ParamStr(I)='--restore'Then Mode:=SW_RESTORE Else
   If ParamStr(I)='--show'Then Mode:=SW_SHOW Else
   If ParamStr(I)='--showmaximized'Then Mode:=SW_SHOWMAXIMIZED Else
   If ParamStr(I)='--showminimized'Then Mode:=SW_SHOWMINIMIZED Else
   If ParamStr(I)='--showminnoactive'Then Mode:=SW_SHOWMINNOACTIVE Else
   If ParamStr(I)='--showna'Then Mode:=SW_SHOWNA Else
   If ParamStr(I)='--shownoactivate'Then Mode:=SW_SHOWNOACTIVATE Else
   If ParamStr(I)='--shownormal'Then Mode:=SW_SHOWNORMAL Else
   If Copy(ParamStr(I),1,Length('--title='))='--title='Then Begin
    Title:=Copy(ParamStr(I),Length('--title=')+1,255);
   End
    Else
   If Command=''Then Command:=ParamStr(I) Else
   If Param=''Then Param:=ParamStr(I)
    Else
   Begin
    WriteLn('ParamŠtre invalide !');
    Halt(1);
   End;
  End;
  WinStart(Command,Param,Mode);
 End;
END.