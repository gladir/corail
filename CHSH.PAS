{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CHSH;

Uses DOS;

Var
 ModeParam:(_None,_Root,_Shell);
 I:Integer;
 ChangeDOS,ChangeRoot,ChangeShell:Boolean;
 UserName,RootName,ShellName:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function FileExist(Name:String):Boolean;
Var
 Rec:SearchRec;
Begin
 FindFirst(Name,AnyFile,Rec);
 FileExist:=DosError=0;
End;

Function ChangeUserShell(UserOrID,Root,ShellName:String;ChangeRoot,ChangeShell:Boolean):Boolean;
Var
 FilePasswd,NewFilePasswd:Text;
 I,J,CellPos:Integer;
 UserFound:Boolean;
 CurrLine,CurrWord:String;
 Cells:Array[0..10]of String;
Begin
 ChangeUserShell:=False;
 {$I-}Assign(FilePasswd,'/etc/passwd');
 Reset(FilePasswd);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier /etc/passwd');
  Halt(1);
 End;
 {$I-}Assign(NewFilePasswd,'/etc/passwd.tmp');
 Rewrite(NewFilePasswd);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de crÇer un nouveau fichier /etc/passwd');
  Halt(2);
 End;
 While Not EOF(Filepasswd)do Begin
  UserFound:=False;
  ReadLn(Filepasswd,CurrLine);
  FillChar(Cells,SizeOf(Cells),0);
  CurrWord:='';
  CellPos:=0;
  For I:=1 to Length(CurrLine) do Begin
   If CurrLine[I]=':'Then Begin
    Cells[CellPos]:=CurrWord;
    CurrWord:='';
    Inc(CellPos);
    If CellPos>9 Then Break;
   End
    Else
   CurrWord:=CurrWord+CurrLine[I];
  End;
  If CurrWord<>''Then Begin
   Cells[CellPos]:=CurrWord;
   Inc(CellPos);
  End;
  If Cells[0]<>''Then Begin
   If(Cells[0]=UserOrID)or(Cells[2]=UserOrID)Then Begin
    UserFound:=True;
    ChangeUserShell:=True;
   End;
  End;
  If(UserFound)Then Begin
   For J:=0 to 4 do Write(NewFilepasswd,Cells[J],':');
   If(ChangeRoot)Then Write(NewFilepasswd,Root,':')
                 Else Write(NewFilepasswd,Cells[5]);
   If(ChangeShell)Then Write(NewFilepasswd,ShellName)
                  Else Write(NewFilepasswd,Cells[6]);
   WriteLn(NewFilepasswd);
  End
   Else
  WriteLn(NewFilepasswd,CurrLine);
 End;
 Close(NewFilepasswd);
 Close(FilePasswd);
 Assign(FilePasswd,'/etc/passwd');
 {$I-}Erase(FilePasswd);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de remplacer le fichier /etc/passwd');
  Halt(3);
 End;
 Assign(NewFilepasswd,'/etc/passwd.tmp');
 Rename(NewFilepasswd,'/etc/passwd');
End;

Procedure ShowListShells(DOSMode:Boolean);
Const
 CorailCmds:Array[0..15]of String[12]=(
  '4DOS.EXE','AMIGADOS.EXE','AMIGADOS.EXE','APPLEDOS.EXE',
  'BASH.EXE','BASH.EXE','COMMAND.EXE','CSH.EXE','DRDOS.EXE',
  'KSH.EXE','OS2CMD.EXE','OS9.EXE','PS.EXE','PS.EXE','SH.EXE',
  'TRSDOS.EXE'
 );
Var
 ListShells:Text;
 I:Integer;
 CurrLine,Corail:String;
Begin
 If(DOSMode)Then Begin
  WriteLn('\COMMAND.COM');
   { 4DOS installÇ ? }
  If FileExist('\4DOS\4DOS.COM')Then WriteLn('\4DOS\4DOS.COM');
   { NDOS du Norton Utilities installÇ ? }
  If FileExist('\NU\NDOS.COM')Then WriteLn('\NU\NDOS.COM');
   { Les interprÇteurs de commandes de Corail installÇ ? }
  Corail:=GetEnv('CORAIL');
  If Corail=''Then Corail:='\CORAIL';
  If Corail[Length(Corail)]<>'\'Then Corail:=Corail+'\';
  For I:=Low(CorailCmds) to High(CorailCmds)do Begin
   If FileExist(Corail+CorailCmds[I])Then WriteLn(Corail,CorailCmds[I]);
  End;
 End
  Else
 Begin
  {$I-}Assign(ListShells,'/etc/shells');
  Reset(ListShells);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de lire le fichier /etc/shells');
   Halt(6);
  End;
  While Not EOF(ListShells)do Begin
   ReadLn(ListShells,CurrLine);
   WriteLn(CurrLine);
  End;
  Close(ListShells);
 End;
End;

Function ChangeDOSShell(ShellName:String):Boolean;
Var
 ConfigFile,NewConfigFile:Text;
 I:Integer;
 Found,ShellHigh:Boolean;
 CurrLine,CurrWord:String;
Begin
 ChangeDOSShell:=False;
 {$I-}Assign(ConfigFile,'\CONFIG.SYS');
 Reset(ConfigFile);{$I+}
 If IOResult<>0 Then Begin
  {$I-}Rewrite(ConfigFile);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de lire ou de crÇer un nouveau fichier \CONFIG.SYS');
   Halt(1);
  End;
  WriteLn(ConfigFile,'Shell=',ShellName);
  Close(ConfigFile);
  Exit;
 End;
 {$I-}Assign(NewConfigFile,'/CONFIG.NEW');
 Rewrite(NewConfigFile);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de crÇer un nouveau fichier \CONFIG.SYS');
  Halt(2);
 End;
 While Not EOF(ConfigFile)do Begin
  ReadLn(ConfigFile,CurrLine);
  CurrWord:='';
  Found:=False;
  For I:=1 to Length(CurrLine)do Begin
   If CurrLine[I]='='Then Begin
    If StrToUpper(CurrWord)='SHELL'Then Begin
     Found:=True;
     ShellHigh:=False;
    End
     Else
    If StrToUpper(CurrWord)='SHELLHIGH'Then Begin { DR-DOS ? }
     Found:=True;
     ShellHigh:=True;
    End;
   End
    Else
   CurrWord:=CurrWord+CurrLine[I];
  End;
  If(Found)Then Begin
   If(ShellHigh)Then WriteLn(NewConfigFile,'ShellHigh=',ShellName)
                Else WriteLn(NewConfigFile,'Shell=',ShellName);
  End
   Else
  WriteLn(NewConfigFile,CurrLine);
 End;
 Close(NewConfigFile);
 Close(ConfigFile);
 Assign(ConfigFile,'\CONFIG.SYS');
 {$I-}Erase(ConfigFile);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de remplacer le fichier \CONFIG.SYS');
  Halt(3);
 End;
 Assign(NewConfigFile,'\CONFIG.NEW');
 Rename(NewConfigFile,'\CONFIG.SYS');
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CHSH : Cette commande permet de changer l''interprÇteur ',
                  'de commande par dÇfaut.');
  WriteLn;
  WriteLn('Syntaxe : chsh [option] [-R root] [ -s login_shell] user');
  WriteLn('          chsh --dos -s login_shell ');
  WriteLn;
  WriteLn(' user                 Indique le nom de l''utilisateur');
  WriteLn(' -l                   Affiche la liste des interprÇteurs de commande ');
  WriteLn('                      disponibles');
  WriteLn(' -R root              Indique le chemin du root de l''utilisateur');
  WriteLn(' -s login-shell       Indique le nom de l''interprÇteur de commande');
  WriteLn(' --dos                Indique qu''il faut changer l''interprÇteur de commande DOS');
  WriteLn(' --help               Affiche l''aide sur cette commande');
  WriteLn(' --list-shells        Affiche la liste des interprÇteurs de commande ');
  WriteLn('                      disponibles');
  WriteLn(' --root root          Indique le chemin du root de l''utilisateur');
  WriteLn(' --shell login-shell  Indique le nom de l''interprÇteur de commande');
 End
  Else
 If(ParamStr(1)='-v')or(ParamStr(1)='--version')Then Begin
  WriteLn('CHSH 1.1 - Clone Pascal de shadow-utils, linux, freebsd, ',
                      'xenix ou corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('êcrit par Sylvain Maltais');
 End
  Else
 Begin
  ChangeRoot:=False;
  ChangeShell:=False;
  ChangeDOS:=False;
  ModeParam:=_None;
  RootName:='';
  ShellName:='';
  UserName:='';
  For I:=1 to ParamCount do Begin
   Case ModeParam of
    _Root:Begin
     RootName:=ParamStr(I);
     ModeParam:=_None;
     ChangeRoot:=True;
    End;
    _Shell:Begin
     ShellName:=ParamStr(I);
     ModeParam:=_None;
     ChangeShell:=True;
    End;
    Else Begin
     If(ParamStr(I)='--dos')Then ChangeDOS:=True Else
     If(ParamStr(I)='-l')or(ParamStr(I)='--list-shells')Then Begin
      ShowListShells(ChangeDOS);
      Halt;
     End
      Else
     If(ParamStr(I)='-R')or(ParamStr(I)='--root')Then ModeParam:=_Root Else
     If(ParamStr(I)='-s')or(ParamStr(I)='--shell')Then ModeParam:=_Shell
                                                  Else UserName:=ParamStr(I);
    End;
   End;
  End;
  If(ChangeDOS)Then Begin
   If ChangeDOSShell(ShellName)Then Begin
    WriteLn('Impossible de changer l''interprÇteur de commande DOS !');
    Halt(6);
   End;
  End
   Else
  If(ChangeRoot)or(ChangeShell)Then Begin
   If UserName=''Then Begin
    WriteLn('Nom d''utilisateur requis !');
    Halt(3);
   End;
   If Not ChangeUserShell(UserName,RootName,ShellName,ChangeRoot,ChangeShell)Then Begin
    WriteLn('Utilisateur introuvable !');
    Halt(5);
   End;
  End
   Else
  Begin
   WriteLn('Un root et/ou le shell est requis !');
   Halt(4);
  End;
 End;
END.