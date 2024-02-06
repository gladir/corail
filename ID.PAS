{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program ID;

Uses DOS;

Var
 Language:(_Albanian,_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 Mode:(_None,_User,_GroupId,_Group);
 I:Integer;
 BaseDir,Entity,UserName,UserID,GroupName,GroupID:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
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

Function Path2Dir(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 Path2Dir:='';
 If Path=''Then Exit;
 FSplit(Path,D,N,E);
 If E=''Then Begin
  If D[Length(D)]<>'\'Then D:=D+'\';
  D:=D+E;
 End;
 If D=''Then Path2Dir:='' Else
 If D[Length(D)]<>'\'Then D:=D+'\';
 Path2Dir:=D;
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
  If IsWildCard(Dir)Then Dir:=Path2Dir(Dir)+'*.*';
  FindFirst(Dir,Directory,Rec);
  DirExist:=DOSError=0;
 End;
End;

Function GroupIDToGroupName(GroupID:String):String;
Var
 FileGroup:Text;
 I,CellPos:Integer;
 CurrLine,CurrWord:String;
 Cells:Array[0..6]of String;
Begin
 GroupIDToGroupName:='';
 {$I-}Assign(FileGroup,BaseDir+'/etc/group');
 Reset(FileGroup);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier ',BaseDir,'/etc/group');
  Halt(1);
 End;
 While Not EOF(FileGroup)do Begin
  ReadLn(FileGroup,CurrLine);
  FillChar(Cells,SizeOf(Cells),0);
  CurrWord:='';
  CellPos:=0;
  For I:=1 to Length(CurrLine) do Begin
   If CurrLine[I]=':'Then Begin
    Cells[CellPos]:=CurrWord;
    CurrWord:='';
    Inc(CellPos);
    If CellPos>5 Then Break;
   End
    Else
   CurrWord:=CurrWord+CurrLine[I];
  End;
  If CurrWord<>''Then Begin
   Cells[CellPos]:=CurrWord;
   Inc(CellPos);
  End;
  If Cells[0]<>''Then Begin
   If(Cells[2]=GroupID)Then Begin
    GroupIDToGroupName:=Cells[0];
    Close(FileGroup);
    Exit;
   End;
  End;
 End;
 Close(FileGroup);
End;

Function UsersInGroupExist(GroupID:String):Boolean;
Var
 FilePasswd:Text;
 I,CellPos:Integer;
 CurrLine,CurrWord:String;
 Cells:Array[0..6]of String;
Begin
 UsersInGroupExist:=False;
 {$I-}Assign(FilePasswd,BaseDir+'/etc/passwd');
 Reset(FilePasswd);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier ',BaseDir,'/etc/passwd');
  Halt(1);
 End;
 While Not EOF(Filepasswd)do Begin
  ReadLn(Filepasswd,CurrLine);
  FillChar(Cells,SizeOf(Cells),0);
  CurrWord:='';
  CellPos:=0;
  For I:=1 to Length(CurrLine) do Begin
   If CurrLine[I]=':'Then Begin
    Cells[CellPos]:=CurrWord;
    CurrWord:='';
    Inc(CellPos);
    If CellPos>5 Then Break;
   End
    Else
   CurrWord:=CurrWord+CurrLine[I];
  End;
  If CurrWord<>''Then Begin
   Cells[CellPos]:=CurrWord;
   Inc(CellPos);
  End;
  If Cells[0]<>''Then Begin
   If(Cells[3]=GroupID)Then Begin
    Close(FilePasswd);
    UsersInGroupExist:=True;
    Exit;
   End;
  End;
 End;
 Close(FilePasswd);
End;

Function GroupNameToGroupID(GroupName:String):String;
Var
 FileGroup:Text;
 I,CellPos:Integer;
 CurrLine,CurrWord:String;
 Cells:Array[0..6]of String;
Begin
 GroupNameToGroupID:='';
 {$I-}Assign(FileGroup,BaseDir+'/etc/group');
 Reset(FileGroup);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier ',BaseDir,'/etc/group');
  Halt(1);
 End;
 While Not EOF(FileGroup)do Begin
  ReadLn(FileGroup,CurrLine);
  FillChar(Cells,SizeOf(Cells),0);
  CurrWord:='';
  CellPos:=0;
  For I:=1 to Length(CurrLine) do Begin
   If CurrLine[I]=':'Then Begin
    Cells[CellPos]:=CurrWord;
    CurrWord:='';
    Inc(CellPos);
    If CellPos>5 Then Break;
   End
    Else
   CurrWord:=CurrWord+CurrLine[I];
  End;
  If CurrWord<>''Then Begin
   Cells[CellPos]:=CurrWord;
   Inc(CellPos);
  End;
  If Cells[0]<>''Then Begin
   If(Cells[0]=GroupName)Then Begin
    Close(FileGroup);
    GroupNameToGroupID:=Cells[2];
    Exit;
   End;
  End;
 End;
 Close(FileGroup);
End;

Function GroupNameToGroupList(GroupName:String;Verbose:Boolean):String;
Var
 FileGroup:Text;
 I,CellPos:Integer;
 CurrLine,CurrWord,GroupList:String;
 Cells:Array[0..6]of String;
Begin
 GroupNameToGroupList:='';
 If GroupName=''Then Exit;
 GroupList:=GroupNameToGroupID(GroupName);
 If(Verbose)Then GroupList:=GroupList+'('+GroupName+')';
 {$I-}Assign(FileGroup,BaseDir+'/etc/group');
 Reset(FileGroup);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier ',BaseDir,'/etc/group');
  Halt(1);
 End;
 While Not EOF(FileGroup)do Begin
  ReadLn(FileGroup,CurrLine);
  FillChar(Cells,SizeOf(Cells),0);
  CurrWord:='';
  CellPos:=0;
  For I:=1 to Length(CurrLine) do Begin
   If CurrLine[I]=':'Then Begin
    Cells[CellPos]:=CurrWord;
    CurrWord:='';
    Inc(CellPos);
    If CellPos>5 Then Break;
   End
    Else
   CurrWord:=CurrWord+CurrLine[I];
  End;
  If CurrWord<>''Then Begin
   Cells[CellPos]:=CurrWord;
   Inc(CellPos);
  End;
  If Cells[0]<>''Then Begin
   If(Cells[3]=GroupName)Then Begin
    If GroupList<>''Then Begin
     If(Verbose)Then GroupList:=GroupList+','
                ELse GroupList:=GroupList+' ';
    End;
    GroupList:=GroupList+Cells[2];
    If(Verbose)Then GroupList:=GroupList+'('+Cells[0]+')';
   End;
  End;
 End;
 Close(FileGroup);
 GroupNameToGroupList:=GroupList;
End;

Function UserIdToUserName(UserOrID:String):String;
Var
 FilePasswd:Text;
 I,CellPos:Integer;
 CurrLine,CurrWord:String;
 Cells:Array[0..6]of String;
Begin
 UserIdToUserName:='';
 {$I-}Assign(FilePasswd,BaseDir+'/etc/passwd');
 Reset(FilePasswd);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier ',BaseDir,'/etc/passwd');
  Halt(1);
 End;
 While Not EOF(Filepasswd)do Begin
  ReadLn(Filepasswd,CurrLine);
  FillChar(Cells,SizeOf(Cells),0);
  CurrWord:='';
  CellPos:=0;
  For I:=1 to Length(CurrLine) do Begin
   If CurrLine[I]=':'Then Begin
    Cells[CellPos]:=CurrWord;
    CurrWord:='';
    Inc(CellPos);
    If CellPos>5 Then Break;
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
    UserIdToUserName:=Cells[0];
    Close(FilePasswd);
    Exit;
   End;
  End;
 End;
 Close(FilePasswd);
End;

Function UserNameToUserID(UserOrID:String):String;
Var
 FilePasswd:Text;
 I,CellPos:Integer;
 CurrLine,CurrWord:String;
 Cells:Array[0..6]of String;
Begin
 UserNameToUserID:='';
 {$I-}Assign(FilePasswd,BaseDir+'/etc/passwd');
 Reset(FilePasswd);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier ',BaseDir,'/etc/passwd');
  Halt(1);
 End;
 While Not EOF(Filepasswd)do Begin
  ReadLn(Filepasswd,CurrLine);
  FillChar(Cells,SizeOf(Cells),0);
  CurrWord:='';
  CellPos:=0;
  For I:=1 to Length(CurrLine) do Begin
   If CurrLine[I]=':'Then Begin
    Cells[CellPos]:=CurrWord;
    CurrWord:='';
    Inc(CellPos);
    If CellPos>5 Then Break;
   End
    Else
   CurrWord:=CurrWord+CurrLine[I];
  End;
  If CurrWord<>''Then Begin
   Cells[CellPos]:=CurrWord;
   Inc(CellPos);
  End;
  If Cells[0]<>''Then Begin
   If(Cells[0]=UserOrID)Then Begin
    UserNameToUserID:=Cells[2];
    Close(FilePasswd);
    Exit;
   End;
  End;
 End;
 Close(FilePasswd);
End;

Function GroupIdFromUserName(UserOrID:String):String;
Var
 FilePasswd:Text;
 I,CellPos:Integer;
 CurrLine,CurrWord:String;
 Cells:Array[0..6]of String;
Begin
 GroupIdFromUserName:='';
 {$I-}Assign(FilePasswd,BaseDir+'/etc/passwd');
 Reset(FilePasswd);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier ',BaseDir,'/etc/passwd');
  Halt(1);
 End;
 While Not EOF(Filepasswd)do Begin
  ReadLn(Filepasswd,CurrLine);
  FillChar(Cells,SizeOf(Cells),0);
  CurrWord:='';
  CellPos:=0;
  For I:=1 to Length(CurrLine) do Begin
   If CurrLine[I]=':'Then Begin
    Cells[CellPos]:=CurrWord;
    CurrWord:='';
    Inc(CellPos);
    If CellPos>5 Then Break;
   End
    Else
   CurrWord:=CurrWord+CurrLine[I];
  End;
  If CurrWord<>''Then Begin
   Cells[CellPos]:=CurrWord;
   Inc(CellPos);
  End;
  If Cells[0]<>''Then Begin
   If(Cells[0]=UserOrID)Then Begin
    GroupIdFromUserName:=Cells[3];
    Close(FilePasswd);
    Exit;
   End;
  End;
 End;
 Close(FilePasswd);
End;

BEGIN
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='SQ')or
    (StrToUpper(Copy(TmpLanguage,1,3))='ALB')Then Language:=_Albanian;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  Case Language of
   _English:Begin
    WriteLn('id - Print user and group information for the specified USER,');
    WriteLn('     or (when USER omitted) for the current user.');
    WriteLn;
    WriteLn('Syntax: id [OPTION]... [USER]');
    WriteLn;
   End;
   Else Begin
    WriteLn('id : Cette commande permet d''afficher les informations ',
                  'd''utilisateur ou de groupe pour l''utilisateur sp‚cifi‚ ',
                  'ou (quand il est omis) por l''utilisateur courant');
    WriteLn;
    WriteLn('Syntaxe : id [OPTION]... [user]');
    WriteLn;
    WriteLn(' user        Indique le nom de l''utilisateur');
    WriteLn(' -g          Affiche uniquement l''ID de groupe effectif');
    WriteLn(' -G          Affiche tous les ID de groupe');
    WriteLn(' -u          Affiche uniquement l''ID de l''utilisateur effectif');
    WriteLn(' --cygwin    Recherche dans les dossiers de Cygwin');
    WriteLn(' --cygwin32  Recherche dans les dossiers de Cygwin en 32 bits');
    WriteLn(' --cygwin64  Recherche dans les dossiers de Cygwin en 64 bits');
   End;
  End;
 End
  Else
 Begin
  Mode:=_None;
  BaseDir:='';
  Entity:=GetEnv('LOGNAME');
  If Entity=''Then Entity:=GetEnv('USERNAME');
  If Entity=''Then Entity:='root';
  UserName:=Entity;
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='--cygwin'Then Begin
    If DirExist('/cygwin')Then BaseDir:='/cygwin' Else
    If DirExist('/cygwin32')Then BaseDir:='/cygwin32' Else
    If DirExist('/cygwin64')Then BaseDir:='/cygwin64';
   End
    Else
   If ParamStr(I)='--cygwin64'Then BaseDir:='/cygwin64' Else
   If ParamStr(I)='--cygwin32'Then BaseDir:='/cygwin32' Else
   If ParamStr(I)='-g'Then Mode:=_GroupId Else
   If ParamStr(I)='-G'Then Mode:=_Group Else
   If ParamStr(I)='-u'Then Mode:=_User
                      Else Entity:=ParamStr(I);
  End;
  Case Mode of
   _Group:WriteLn(GroupNameToGroupList(Entity,False));
   _GroupId:Begin
    UserId:=UserNameToUserID(Entity);
    GroupId:=GroupIdFromUserName(Entity);
    WriteLn(GroupId);
   End;
   _User:WriteLn(UserNameToUserID(Entity));
   Else Begin
    UserId:=UserNameToUserID(Entity);
    GroupId:=GroupIdFromUserName(Entity);
    GroupName:=GroupIdToGroupName(GroupId);
    WriteLn('uid=',UserId,'(',UserName,')',' ',
            'gid=',GroupId,'(',GroupName,')',' ',
            'groups=',GroupNameToGroupList(GroupName,True));
   End;
  End;
 End;
END.