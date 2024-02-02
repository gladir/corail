{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program USERDEL;

Uses DOS;

Var
 Language:(_Albanian,_French,_English,_Germany,_Italian,_Spain);
 Ok,Skip:Boolean;
 TmpLanguage,UserOrID,LoginName:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function GetUserName(UserOrID:String):String;
Var
 FilePasswd:Text;
 I,CellPos:Integer;
 CurrLine,CurrWord:String;
 Cells:Array[0..6]of String;
Begin
 GetUserName:='';
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
   If(Cells[0]=UserOrID)or(Cells[2]=UserOrID)Then Begin
    GetUserName:=Cells[0];
    Close(FilePasswd);
    Exit;
   End;
  End;
 End;
 Close(FilePasswd);
End;

Function DeleteUser(UserOrID:String):Boolean;
Var
 FilePasswd,NewFilePasswd:Text;
 I,CellPos:Integer;
 UserFound:Boolean;
 CurrLine,CurrWord:String;
 Cells:Array[0..6]of String;
Begin
 DeleteUser:=False;
 {$I-}Assign(FilePasswd,'/etc/passwd');
 Reset(FilePasswd);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier /etc/passwd');
  Halt(1);
 End;
 {$I-}Assign(NewFilePasswd,'/etc/passwd.tmp');
 Rewrite(NewFilePasswd);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de cr‚er un nouveau fichier /etc/passwd');
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
    UserFound:=True;
    DeleteUser:=True;
   End;
  End;
  If(UserFound)Then Begin
   { Ne l'‚crit pas dans le nouveau fichier }
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

Procedure DeleteUserMail(UserName:String);
Var
 FileUserMail:File;
Begin
 {$I-}Assign(FileUserMail,'/usr/spool/mail/'+UserName);
 Erase(FileUserMail);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Aucun tampon de courriel pr‚sent');
 End;
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
    WriteLn('userdel - Removes a user from the system.');
    WriteLn;
    WriteLn('Syntax: userdel username');
    WriteLn;
   End;
   Else Begin
    WriteLn('userdel : Cette commande permet de supprimer un utilisateur du systŠme.');
    WriteLn;
    WriteLn('Syntaxe : userdel username');
    WriteLn;
    WriteLn(' username   Indique le nom de l''utilisateur … supprimer');
   End;
  End;
 End
  Else
 Begin
  UserOrID:=ParamStr(1);
  LoginName:=GetUserName(UserOrID);
  If DeleteUser(UserOrID)Then Begin
   WriteLn('Utilisateur ',LoginName,' supprim‚');
   DeleteUserMail(LoginName);
  End
   Else
  Begin
   WriteLn('Utilisateur introuvable');
   Halt(1);
  End;
 End;
END.