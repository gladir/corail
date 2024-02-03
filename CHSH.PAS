{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CHSH;

Var
 ModeParam:(_None,_Root,_Shell);
 I:Integer;
 ChangeRoot,ChangeShell:Boolean;
 UserName,RootName,ShellName:String;

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

Procedure ShowListShells;
Var
 ListShells:Text;
 CurrLine:String;
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

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CHSH : Cette commande permet de changer l''interprÇteur ',
                  'de commande par dÇfaut.');
  WriteLn;
  WriteLn('Syntaxe : chsh [option] [-R root] [ -s login_shell] user');
  WriteLn;
  WriteLn(' user                 Indique le nom de l''utilisateur');
  WriteLn(' -l                   Affiche la liste des interprÇteurs de commande ');
  WriteLn('                      disponibles');
  WriteLn(' -R root              Indique le chemin du root de l''utilisateur');
  WriteLn(' -s login-shell       Indique le nom de l''interprÇteur de commande');
  WriteLn(' --help               Affiche l''aide sur cette commande');
  WriteLn(' --list-shells        Affiche la liste des interprÇteurs de commande ');
  WriteLn('                      disponibles');
  WriteLn(' --root root          Indique le chemin du root de l''utilisateur');
  WriteLn(' --shell login-shell  Indique le nom de l''interprÇteur de commande');
 End
  Else
 If(ParamStr(1)='-v')or(ParamStr(1)='--version')Then Begin
  WriteLn('CHSH 1.0 - Clone Pascal de shadow-utils, linux ou corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('êcrit par Sylvain Maltais');
 End
  Else
 Begin
  ChangeRoot:=False;
  ChangeShell:=False;
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
     If(ParamStr(I)='-l')or(ParamStr(I)='--list-shells')Then Begin
      ShowListShells;
      Halt;
     End
      Else
     If(ParamStr(I)='-R')or(ParamStr(I)='--root')Then ModeParam:=_Root Else
     If(ParamStr(I)='-s')or(ParamStr(I)='--shell')Then ModeParam:=_Shell
                                                  Else UserName:=ParamStr(I);
    End;
   End;
  End;
  If UserName=''Then Begin
   WriteLn('Nom d''utilisateur requis !');
   Halt(3);
  End;
  If(ChangeRoot)or(ChangeShell)Then Begin
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