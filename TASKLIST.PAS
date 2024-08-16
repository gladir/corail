{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal (Windows ou Linux))
}

Program TASKLIST;

Uses
 {$IFDEF WINDOWS}
  Windows,SysUtils,JwaTlHelp32;
 {$ELSE}
  BaseUnix, SysUtils;
 {$ENDIF}

Var
 {$IFDEF WINDOWS}
  ProcessEntry:TProcessEntry32;
  SnapshotHandle:THandle;
 {$ELSE}
  Entry:TSearchRec;
  ProcessFile:TextFile;
  Pid:LongInt;
  CmdLine:String;
 {$ENDIF}

Function LongToStr(Value:LongInt):String;
Var
 S:String;
Begin
 Str(Value,S);
 LongToStr:=S;
End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('TASKLIST : Cette commande permet d''afficher la liste de ',
           'tous les processus du systŠme d''exploitation.');
    WriteLn;
    WriteLn('Syntaxe : TASKLIST [/?]');
 End
  Else
 Begin
  {$IFDEF WINDOWS}
    { Cr‚er un instantan‚ de tous les processus en cours }
   SnapshotHandle:=CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
   If SnapshotHandle=INVALID_HANDLE_VALUE then begin
    WriteLn('Erreur: Incapable de cr‚er un instantan‚ des processus.');
    Halt(1);
   End;
   ProcessEntry.dwSize := SizeOf(TProcessEntry32);
    { R‚cup‚rer le premier processus }
   If Process32First(snapshotHandle, processEntry)Then Begin
    WriteLn('PID          Nom du processus');
    WriteLn('-----------------------------');
    Repeat
      { Afficher le PID et le nom du processus }
     WriteLn(PadRight(LongToStr(ProcessEntry.th32ProcessID),12),' ',ProcessEntry.szExeFile);
    Until not Process32Next(snapshotHandle, processEntry);
   End
    Else
   Begin
    WriteLn('Erreur: Incapable de retrouver les processus.');
   End;
    { Fermer le handle du snapshot }
   CloseHandle(snapshotHandle);
  {$ELSE}
   WriteLn('PID            Commande');
   WriteLn('-----------------------------');
    { Parcourir les entr‚es du r‚pertoire /proc }
   If FindFirst('/proc/*',faDirectory,Entry) = 0 Then Begin
    Repeat
     { V‚rifier si le nom de l'entr‚e est un nombre (PID) }
     If TryStrToInt(Entry.Name,Pid)Then Begin
       { Ouvrir le fichier cmdline pour lire la commande du processus }
      {$I+}Assign(ProcessFile,'/proc/'+Entry.Name+'/cmdline');
      Reset(processFile);{$I-}
      If IoResult<>0Then Begin
       WriteLn('Erreur de lecture de cmdline pour PID ',PID);
       Halt(1);
      End;
      ReadLn(ProcessFile, cmdline);
       { Remplacer les null terminators par des espaces }
      Cmdline:=StringReplace(cmdline,#0,' ',[rfReplaceAll]);
      WriteLn(PadRight(LongToStr(pid),12),CmdLine);
      Close(processFile);
     End;
    Until FindNext(entry)<>0;
    FindClose(Entry);
   End;
  {$ENDIF}
 End;
END.