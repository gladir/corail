{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program GROUPDEL;

Uses DOS;

Var
 Language:(_Albanian,_French,_English,_Germany,_Italian,_Spain);
 Ok,Skip:Boolean;
 TmpLanguage,GroupOrID,GroupName,GroupID:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function GetGroupName(GroupOrID:String):String;
Var
 FileGroup:Text;
 I,CellPos:Integer;
 CurrLine,CurrWord:String;
 Cells:Array[0..6]of String;
Begin
 GetGroupName:='';
 {$I-}Assign(FileGroup,'/etc/group');
 Reset(FileGroup);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier /etc/group');
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
   If(Cells[0]=GroupOrID)or(Cells[2]=GroupOrID)Then Begin
    GetGroupName:=Cells[0];
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
 {$I-}Assign(FilePasswd,'/etc/passwd');
 Reset(FilePasswd);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier /etc/passwd');
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

Function GroupToID(GroupName:String):String;
Var
 FileGroup:Text;
 I,CellPos:Integer;
 CurrLine,CurrWord:String;
 Cells:Array[0..6]of String;
Begin
 GroupToID:='';
 {$I-}Assign(FileGroup,'/etc/group');
 Reset(FileGroup);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier /etc/group');
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
    GroupToID:=Cells[2];
    Exit;
   End;
  End;
 End;
 Close(FileGroup);
End;

Function DeleteGroup(GroupOrID:String):Boolean;
Var
 FileGroup,NewFileGroup:Text;
 I,CellPos:Integer;
 UserFound:Boolean;
 CurrLine,CurrWord:String;
 Cells:Array[0..6]of String;
Begin
 DeleteGroup:=False;
 {$I-}Assign(FileGroup,'/etc/group');
 Reset(FileGroup);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier /etc/group');
  Halt(1);
 End;
 {$I-}Assign(NewFileGroup,'/etc/group.tmp');
 Rewrite(NewFileGroup);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de cr‚er un nouveau fichier /etc/group');
  Halt(2);
 End;
 While Not EOF(FileGroup)do Begin
  UserFound:=False;
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
   If(Cells[0]=GroupOrID)or(Cells[2]=GroupOrID)Then Begin
    UserFound:=True;
    DeleteGroup:=True;
   End;
  End;
  If(UserFound)Then Begin
   { Ne l'‚crit pas dans le nouveau fichier }
  End
   Else
  WriteLn(NewFileGroup,CurrLine);
 End;
 Close(NewFileGroup);
 Close(FileGroup);
 Assign(NewFileGroup,'/etc/group');
 {$I-}Erase(FileGroup);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de remplacer le fichier /etc/group');
  Halt(3);
 End;
 Assign(NewFileGroup,'/etc/group.tmp');
 Rename(NewFileGroup,'/etc/group');
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
    WriteLn('groupdel - Removes a group from the system.');
    WriteLn;
    WriteLn('Syntax: groupdel groupname');
    WriteLn;
   End;
   Else Begin
    WriteLn('groupdel : Cette commande permet de supprimer un groupe du systŠme.');
    WriteLn;
    WriteLn('Syntaxe : groupdel groupname');
    WriteLn;
    WriteLn(' groupname   Indique le nom du groupe … supprimer');
   End;
  End;
 End
  Else
 Begin
  GroupOrID:=ParamStr(1);
  GroupName:=GetGroupName(GroupOrID);
  GroupID:=GroupToID(GroupOrID);
  If GroupID=''Then Begin
   WriteLn('Groupe introuvable');
   Halt(2);
  End
   Else
  If UsersInGroupExist(GroupID)Then Begin
   WriteLn('Impossible de supprimer un groupe utiliser par des utilisateurs');
   Halt(1);
  End
   Else
  If DeleteGroup(GroupOrID)Then Begin
   WriteLn('Groupe ',GroupName,' supprim‚');
  End
   Else
  Begin
   WriteLn('Groupe introuvable');
   Halt(1);
  End;
 End;
END.