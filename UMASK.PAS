{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program UMASK;

Uses DOS;

Const
 FileSearchList:Array[0..2]of String[20]=(
  '$HOME/.bashrc',
  '$HOME/.profile',
  '/etc/login.defs'
 );

 OctalMask:Array[0..7]of String[3]=(
  'rwx','rw','rx','r','wx','w','x','-'
 );

Var
 I:Integer;
 ShowFile,OutputSymbolic:Boolean;
 BaseDir,HomeDir,UserName,NewUMask,Mask:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function TrimL(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If Not(S[I]in[#9,' '])Then Begin
   TrimL:=Copy(S,I,255);
   Exit;
  End;
 End;
 TrimL:=S;
End;

Function TrimR(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 TrimR:=S;
End;

Function Trim(s:String):String;Begin
 Trim:=TrimL(TrimR(s));
End;

Function IsOctalMask(S:String):Boolean;
Var
 I:Integer;
Begin
 IsOctalMask:=True;
 For I:=1 to Length(S)do Begin
  If Not(S[I]in['0'..'7'])Then Begin
   IsOctalMask:=False;
   Exit;
  End;
 End;
End;

Procedure OctalToUGO(Octal:String;Var U,G,O:Byte);Begin
 Octal:=Trim(Octal);
 If Length(Octal)=4 Then Octal:=Copy(Octal,2,255);
 U:=Ord(Octal[1])-Ord('0');
 G:=Ord(Octal[2])-Ord('0');
 O:=Ord(Octal[3])-Ord('0');
End;

Function SymbolicToOctal(U,G,O:Byte;S:String):String;
Var
 Mode:Char;
 I:Integer;
 Remove,EqualValue:Boolean;
Begin
 Mode:=#0;
 Remove:=False;
 For I:=1 to Length(S)do Begin
  Case S[I]of
   'u':Begin
    Mode:='u';
    Remove:=False;
    EqualValue:=False;
   End;
   'g':Begin
    Mode:='g';
    Remove:=False;
    EqualValue:=False;
   End;
   'o':Begin
    Mode:='o';
    Remove:=False;
    EqualValue:=False;
   End;
   'r':Begin
    If(EqualValue)Then Begin
     Case Mode of
      'u':U:=4;
      'g':G:=4;
      'o':O:=4;
     End;
    End
     Else
    If(Remove)Then Begin
     Case Mode of
      'u':U:=U and Not 4;
      'g':G:=G and Not 4;
      'o':O:=O and Not 4;
     End;
    End
     Else
    Begin
     Case Mode of
      'u':U:=U or 4;
      'g':G:=G or 4;
      'o':O:=O or 4;
     End;
    End;
   End;
   'w':Begin
    If(EqualValue)Then Begin
     Case Mode of
      'u':U:=2;
      'g':G:=2;
      'o':O:=2;
     End;
    End
     Else
    If(Remove)Then Begin
     Case Mode of
      'u':U:=U and Not 2;
      'g':G:=G and Not 2;
      'o':O:=O and Not 2;
     End;
    End
     Else
    Begin
     Case Mode of
      'u':U:=U or 2;
      'g':G:=G or 2;
      'o':O:=O or 2;
     End;
    End;
   End;
   'x':Begin
    If(EqualValue)Then Begin
     Case Mode of
      'u':U:=1;
      'g':G:=1;
      'o':O:=1;
     End;
    End
     Else
    If(Remove)Then Begin
     Case Mode of
      'u':U:=U and Not 1;
      'g':G:=G and Not 1;
      'o':O:=O and Not 1;
     End;
    End
     Else
    Begin
     Case Mode of
      'u':U:=U or 1;
      'g':G:=G or 1;
      'o':O:=O or 1;
     End;
    End;
   End;
   '=':EqualValue:=True;
   '-':Remove:=True;
   '+':Remove:=False;
  End;
 End;
 SymbolicToOctal:=Chr(U+Ord('0'))+Chr(G+Ord('0'))+Chr(O+Ord('0'));
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

Function GetHomeDir(UserName:String):String;Begin
 If UserName=''Then GetHomeDir:='/root'
               Else GetHomeDir:=BaseDir+'/home/'+UserName;
End;

Function GetCurrUMASK(UserName:String):String;
Var
 J:Integer;
 ConfigFile:Text;
 CurrFileName,CurrLine:String;
Begin
 GetCurrUMASK:='';
 For J:=Low(FileSearchList) to High(FileSearchList)do Begin
  CurrFileName:=FileSearchList[J];
  If Copy(CurrFileName,1,5)='$HOME'Then Begin
   CurrFileName:=HomeDir+Copy(CurrFileName,6,255);
  End;
  {$I-}Assign(ConfigFile,CurrFileName);
  Reset(ConfigFile);{$I+}
  If IOResult=0 Then Begin
   While Not EOF(ConfigFile)do Begin
    ReadLn(ConfigFile,CurrLine);
    If StrToUpper(Copy(CurrLine,1,5))='UMASK'Then Begin
     If(ShowFile)Then WriteLn(CurrFileName);
     GetCurrUMASK:=Trim(Copy(CurrLine,6,5));
     Close(ConfigFile);
     Exit;
    End;
   End;
   Close(ConfigFile);
  End;
 End;
End;

Procedure SetUMASK(UserName,UMask:String);
Var
 Found:Boolean;
 J:Integer;
 U,G,O:Byte;
 ConfigFile,NewConfigFile:Text;
 CurrFileName,CurrLine:String;
Begin
 Found:=False;
 For J:=Low(FileSearchList) to High(FileSearchList)do Begin
  CurrFileName:=FileSearchList[J];
  If Copy(CurrFileName,1,5)='$HOME'Then Begin
   CurrFileName:=HomeDir+Copy(CurrFileName,6,255);
  End;
  {$I-}Assign(ConfigFile,CurrFileName);
  Reset(ConfigFile);{$I+}
  If IOResult=0 Then Begin
   {$I-}Assign(NewConfigFile,HomeDir+'/'+'UMASK.TMP');
   Rewrite(NewConfigFile);{$I+}
   If IOResult=0 Then Begin
    While Not EOF(ConfigFile)do Begin
     ReadLn(ConfigFile,CurrLine);
     If StrToUpper(Copy(CurrLine,1,5))='UMASK'Then Begin
      If Not IsOctalMask(UMask)Then Begin
       OctalToUGO(Copy(CurrLine,6,255),U,G,O);
       UMask:=SymbolicToOctal(U,G,O,UMask);
      End;
      WriteLn(NewConfigFile,Copy(CurrLine,1,5),' ',UMask);
      Found:=True;
     End
      Else
     WriteLn(NewConfigFile,CurrLine);
    End;
    If Not(Found)Then Begin
     If IsOctalMask(UMask)Then Write(NewConfigFile,UMask)
      Else
     Begin
      UMask:=SymbolicToOctal(0,0,0,UMask);
      Write(NewConfigFile,UMask);
     End;
     WriteLn(NewConfigFile);
     Found:=True;
    End;
    Close(NewConfigFile);
   End;
   Close(ConfigFile);
   {$I-}Assign(ConfigFile,CurrFileName);
   Erase(ConfigFile);{$I+}
   If IOResult<>0 Then Begin
    WriteLn('Impossible de remplacer le fichier ',CurrFileName);
    Halt(1);
   End;
   {$I-}Assign(NewConfigFile,HomeDir+'/'+'UMASK.TMP');
   Rename(NewConfigFile,CurrFileName);{$I+}
   If IOResult<>0 Then Begin
    WriteLn('Impossible de renommer le fichier ',HomeDir+'/'+'UMASK.TMP',
            ' -> ',CurrFileName);
    Halt(2);
   End;
  End;
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('UMASK : Cette commande permet de fixer les droits d''accŠs par ',
                   'd‚faut de la cr‚ation d''un fichier.');
  WriteLn;
  WriteLn('Syntaxe : UMASK [options] [umask]');
  WriteLn;
  WriteLn(' umask       Indique le UMask … appliquer');
  WriteLn(' -S          Affiche une sortie symbolique');
  WriteLn(' --cygwin    Recherche dans les dossiers de Cygwin');
  WriteLn(' --cygwin32  Recherche dans les dossiers de Cygwin en 32 bits');
  WriteLn(' --cygwin64  Recherche dans les dossiers de Cygwin en 64 bits');
  WriteLn(' --showfile  Affiche le fichier o— a ‚t‚ trouv‚ le UMASK');
  WriteLn(' --help      Affiche l''aide de cette commande.');
 End
  Else
 Begin
  NewUMask:='';
  BaseDir:='';
  ShowFile:=False;
  OutputSymbolic:=False;
  UserName:=GetEnv('LOGNAME');
  If UserName=''Then UserName:=GetEnv('USERNAME');
  If UserName=''Then UserName:='root';
  HomeDir:=GetHomeDir(UserName);
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='-S'Then OutputSymbolic:=True Else
   If ParamStr(I)='--cygwin'Then Begin
    If DirExist('/cygwin')Then BaseDir:='/cygwin' Else
    If DirExist('/cygwin32')Then BaseDir:='/cygwin32' Else
    If DirExist('/cygwin64')Then BaseDir:='/cygwin64';
   End
    Else
   If ParamStr(I)='--cygwin64'Then BaseDir:='/cygwin64' Else
   If ParamStr(I)='--cygwin32'Then BaseDir:='/cygwin32' Else
   If ParamStr(I)='--showfile'Then ShowFile:=True
                              Else NewUMask:=ParamStr(I);
  End;
  If NewUMask<>''Then Begin
   If Length(NewUMask)=4 Then NewUMask:=Copy(NewUMask,2,255);
   SetUMASK(UserName,NewUMask);
  End
   Else
  Begin
   Mask:=GetCurrUMASK(UserName);
   If Mask=''Then Begin
    WriteLn('Erreur de masque');
    Halt(3);
   End;
   If(OutputSymbolic)Then Begin
    WriteLn('u=',OctalMask[Ord(Mask[1])-Ord('0')],',',
            'g=',OctalMask[Ord(Mask[2])-Ord('0')],',',
            'o=',OctalMask[Ord(Mask[3])-Ord('0')]);
   End
    Else
   WriteLn('0',Mask);
  End;
 End;
END.