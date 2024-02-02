{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program RMUSER;

Uses DOS;

Var
 Language:(_Albanian,_French,_English,_Germany,_Italian,_Spain);
 Ok,Skip,DeleteOther:Boolean;
 TmpLanguage,UserOrID,LoginName,Response:String;

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
    WriteLn('rmuser - Removes a user from the system.');
    WriteLn;
    WriteLn('Syntax: rmuser');
    WriteLn;
   End;
   Else Begin
    WriteLn('rmuser : Cette commande permet de supprimer un utilisateur du systŠme.');
    WriteLn;
    WriteLn('Syntaxe : rmuser');
    WriteLn;
   End;
  End;
 End
  Else
 Begin
  DeleteOther:=False;
  Case Language of
   _English:Write('Press ENTER when you are ready: ');
   Else Write('Appuyez sur ENTER lorsque vous ˆtes prˆt : ');
  End;
  ReadLn;
  Repeat
   Repeat
    Case Language of
     _English:Write('Enter name of ID to be removed: ');
     Else Write('Saisissez le nom de l''ID … supprimer : ');
    End;
    ReadLn(UserOrID);
    If UserOrID=''Then Begin
     WriteLn('Op‚ration annul‚');
     Halt;
    End;
    LoginName:=GetUserName(UserOrID);
    If LoginName=''Then Begin
     WriteLn('Utilisateur introuvable !');
    End;
   Until LoginName<>'';
   Ok:=False;
   Skip:=False;
   Repeat
    Case Language of
     _English:Write('Removing user ',LoginName,' from the system. CONFIRM? (y/n/q):');
     Else Write('Voulez-vous supprimer l''utilisateur ',LoginName,
                ' du systŠme. S''il vous plait, confirmez (o/n/q) :');
    End;
    ReadLn(Response);
    If(StrToUpper(Response)='Q')Then Halt;
    If(StrToUpper(Response)='N')Then Begin
     Ok:=True;
     Skip:=True;
    End;
    If(StrToUpper(Response)='O')or(StrToUpper(Response)='Y')or
     (StrToUpper(Response)='OUI')or(StrToUpper(Response)='YES')Then Ok:=True;
   Until Ok;
   If(StrToUpper(Response)='O')or(StrToUpper(Response)='Y')or
     (StrToUpper(Response)='OUI')or(StrToUpper(Response)='YES')Then Begin
    If DeleteUser(UserOrID)Then Begin
     DeleteUserMail(LoginName);
    End
     Else
    Begin
     WriteLn('ATTENTION ! Utilisateur introuvable');
    End;
   End;
   Case Language of
    _English:Begin
     WriteLn('User ',LoginName,' removed from the system');
     Write('Do you want to remove another user? (y/n/q): ');
    End;
    Else Begin
     WriteLn('L''utilisateur ',LoginName,' a ‚t‚ supprim‚ du systŠme');
     Write('Voulez-vous supprimer un autre utilisateur ? (o/n/q) : ');
    End;
   End;
   Ok:=False;
   Skip:=False;
   Repeat
    ReadLn(Response);
    If(StrToUpper(Response)='Q')Then Halt;
    If(StrToUpper(Response)='N')Then Begin
     Ok:=True;
     Skip:=True;
    End;
    If(StrToUpper(Response)='O')or(StrToUpper(Response)='Y')or
     (StrToUpper(Response)='OUI')or(StrToUpper(Response)='YES')Then Begin
      Ok:=True;
      DeleteOther:=True;
     End;
   Until Ok;
  Until Not DeleteOther;
 End;
END.