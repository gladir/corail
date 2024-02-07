{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program GROUPS;

Uses DOS;

Var
 I:Integer;
 BaseDir,Entity:String;

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

Function GroupNameToGroupListName(GroupName:String):String;
Var
 FileGroup:Text;
 I,CellPos:Integer;
 CurrLine,CurrWord,GroupList:String;
 Cells:Array[0..6]of String;
Begin
 GroupNameToGroupListName:='';
 If GroupName=''Then Exit;
 GroupList:=GroupName;
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
    If GroupList<>''Then GroupList:=GroupList+' ';
    GroupList:=GroupList+Cells[0];
   End;
  End;
 End;
 Close(FileGroup);
 GroupNameToGroupListName:=GroupList;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('GROUPS : Cette commande permet d''afficher les groupes ',
                    'd''un utilisateur.');
  WriteLn;
  WriteLn('Syntaxe : GROUPS [options] [user]');
  WriteLn;
  WriteLn(' user        Indique le nom de l''utilisateur');
  WriteLn(' --cygwin    Recherche dans les dossiers de Cygwin');
  WriteLn(' --cygwin32  Recherche dans les dossiers de Cygwin en 32 bits');
  WriteLn(' --cygwin64  Recherche dans les dossiers de Cygwin en 64 bits');
  WriteLn(' --help      Affiche l''aide de cette commande.');
 End
  Else
 Begin
  BaseDir:='';
  Entity:=GetEnv('LOGNAME');
  If Entity=''Then Entity:=GetEnv('USERNAME');
  If Entity=''Then Entity:='root';
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='--cygwin'Then Begin
    If DirExist('/cygwin')Then BaseDir:='/cygwin' Else
    If DirExist('/cygwin32')Then BaseDir:='/cygwin32' Else
    If DirExist('/cygwin64')Then BaseDir:='/cygwin64';
   End
    Else
   If ParamStr(I)='--cygwin64'Then BaseDir:='/cygwin64' Else
   If ParamStr(I)='--cygwin32'Then BaseDir:='/cygwin32'
                              Else Entity:=ParamStr(I);
  End;
  WriteLn(GroupNameToGroupListName(Entity));
 End;
END.