{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal 3.2 (Windows ou Linux))
}

Program TASKKILL;

Uses
 {$IFDEF Windows}
  Windows,SysUtils;
 {$ELSE}
  BaseUnix,Unix,SysUtils;
 {$ENDIF}

Const
 TH32CS_SNAPALL=$00000002; { InstantanÇ de tous les processus }
 TH32CS_SNAPHEAPLIST=$00000001; { InstantanÇ de la liste des tas }
 INVALID_HANDLE_VALUE=-1;

{$IFDEF Windows}
Type
 TProcessEntry32=Record
  dwSize:DWORD;                { Taille de la structure }
  cntUsage:DWORD;              { Nombre de fois que ce processus est utilisÇ }
  th32ProcessID:DWORD;         { Identifiant de processus }
  th32DefaultHeapID:DWORD;     { Identifiant de tas par dÇfaut }
  th32ModuleID:DWORD;          { Identifiant de module }
  cntThreads:DWORD;            { Nombre de processus lÇger }
  th32ParentProcessID:DWORD;   { Identificateur de processus parent }
  dwFlags:DWORD;               { Drapeaux }
  szExeFile:Array[0..MAX_PATH-1] of AnsiChar; { Nom du fichier exÇcutable }
 End;
{$ENDIF}

Var
 ModeParam:(_None,_PID);
 I:Integer;
 PIDIsSet:Boolean;
 PID:DWORD;
 Command:String;

{$IFDEF Windows}
 Function CreateToolhelp32Snapshot(dwFlags:DWORD;th32ProcessID:DWORD):THandle;StdCall;External 'kernel32.dll';
 Function Process32First(hSnapshot:THandle;Var lppe:TProcessEntry32):LongBool;StdCall;External 'kernel32.dll';
 Function Process32Next(hSnapshot:THandle;Var lppe:TProcessEntry32):LongBool;Stdcall;External 'kernel32.dll';
 Function OpenProcess(dwDesiredAccess:DWORD;bInheritHandle:BOOL;dwProcessId: DWORD): THandle; stdcall; external 'kernel32.dll';
 Function TerminateProcess(hProcess:THandle;uExitCode:UINT):LongBool; stdcall; external 'kernel32.dll';
 Procedure CloseHandle(hObject: THandle); stdcall; external 'kernel32.dll';
{$ENDIF}

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

{$IFDEF Windows}
 Procedure KillProcessByName(Const ProcessName:String);
 Var
  Snapshot:THandle;
  ProcessEntry:TProcessEntry32;
 Begin
  Snapshot:=CreateToolhelp32Snapshot(TH32CS_SNAPALL, 0);
  If Snapshot=INVALID_HANDLE_VALUE Then Begin
   Writeln('Erreur: Incompable de crÇer un instantanÇ de processus.');
   Exit;
  End;
  ProcessEntry.dwSize:=SizeOf(ProcessEntry);
  If Process32First(Snapshot, ProcessEntry)Then Begin
   Repeat
    If AnsiCompareText(ProcessEntry.szExeFile,ProcessName)=0 Then Begin
     Writeln('Processus terminÇ: ', ProcessEntry.szExeFile, ' (PID: ', ProcessEntry.th32ProcessID, ')');
     TerminateProcess(OpenProcess(PROCESS_TERMINATE, False, ProcessEntry.th32ProcessID), 0);
    End;
   Until not Process32Next(Snapshot, ProcessEntry);
  End;
  CloseHandle(Snapshot);
 End;

 Procedure KillProcessByID(Const ProcessID:DWORD);
 Var
  ProcessHandle:THandle;
 Begin
  ProcessHandle:=OpenProcess(PROCESS_TERMINATE,False,ProcessID);
  If ProcessHandle=0 Then Begin
   Writeln('Erreur: Incapable d''ouvrir un processus avec l''ID ', ProcessID);
   Exit;
  End;
  If TerminateProcess(ProcessHandle,0)Then
   WriteLn('Processus avec ID ', ProcessID, ' terminÇ.')
  Else
   WriteLn('Erreur: Incapable de terminÇ le processus avec ID ', ProcessID);
  CloseHandle(ProcessHandle);
 End;
{$ELSE}
 Procedure KillProcessByID(ProcessID:Integer);
 Var
  ResultCode:Integer;
 Begin
  ResultCode:=fpKill(ProcessID,SIGTERM); { Envoie le signal SIGTERM pour terminer le processus }
  If ResultCode=0 Then
   WriteLn('Processus avec ID ', ProcessID, ' terminÇ.')
  Else
   WriteLn('Erreur: Incapable de terminÇ le processus avec ID ', ProcessID, ' (Code d''erreur: ', fpGetErrno, ')');
 End;

 Procedure KillProcessByName(Const ProcessName:String);
 Var
  ProcessID:Integer;
  Command:String;
 Begin
  Command:='pkill '+ProcessName; { Utilisation de la commande pkill }
  ProcessID := fpSystem(Command); { ExÇcute la commande }
  If ProcessID=0 Then
   WriteLn('Terminer le processus avec le nom: ', ProcessName)
  else
    writeln('Erreur: Incapable de terminÇ le processus avec le nom: ', ProcessName);
 End;
{$ENDIF}

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('TASKKILL : Cette commande permet de terminer un processus ',
                    'ou programme.');
  WriteLn;
  WriteLn('Syntaxe : TASKKILL [/?] [command] [/PID pid]');
  WriteLn;
  WriteLn('  /?       Affiche l''aide sur cette commande.');
  WriteLn(' command   Nom de la commande ou du processus Ö terminer');
  WriteLn(' /PID pid  Identificateur du processus Ö terminer');
 End
  Else
 If ParamCount>0 Then Begin
  ModeParam:=_None;
  Command:='';
  PID:=0;
  PIDIsSet:=False;
  For I:=1 to ParamCount do Begin
   Case ModeParam of
    _PID:Begin
     PIDIsSet:=True;
     PID:=StrToInt(ParamStr(I));
     ModeParam:=_None;
    End;
    Else Begin
     If StrToUpper(ParamStr(I))='/PID'Then ModeParam:=_PID
                                      Else Command:=ParamStr(I);
    End;
   End;
  End;
  If(PIDIsSet)Then KillProcessByID(PID) Else
  If Command=''Then Begin
   WriteLn('Erreur: Aucun nom de commande Ö terminer.');
   Halt(1);
  End
   Else
  Begin
   If Pos('.exe',Command)>0 Then
    KillProcessByName(Command) { Si c'est un nom de fichier, tuer par nom }
   Else
    KillProcessByID(StrToInt(Command)); { Sinon, tuer par ID }
  End;
 End
  Else
 WriteLn('Paramätre requis !');
END.