{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program LASTLOG;

Uses Strings,DOS;

Const
 UT_LINESIZE=32;
 UT_NAMESIZE=32;
 UT_HOSTSIZE=256;

Type
 LastLogRecord32=Record
  ll_time:LongInt;
  ll_line:Array[0..UT_LINESIZE-1]of Char;
  ll_host:Array[0..UT_HOSTSIZE-1]of Char;
 End;

 LastLogRecord64=Record
  ll_time:Record Case Byte of
   0:(A,B:LongInt);
   1:(C:Comp);
  End;
  ll_line:Array[0..UT_LINESIZE-1]of Char;
  ll_host:Array[0..UT_HOSTSIZE-1]of Char;
 End;

Var
 LastLogFile:File;
 Use32,Use64:Boolean;
 ByteReaded:Word;
 I:Integer;
 UserOrId,BaseDir:String;
 CurrRec32:LastLogRecord32;
 CurrRec64:LastLogRecord64;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
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

Procedure JulianToGregorian(JulianDN:LongInt;Var Year,Month,Day:Word);
Var
 YYear,XYear,Temp,TempMonth:LongInt;
Begin
 Temp:=((JulianDN-1721119) shl 2)-1;
 JulianDN:=Temp Div 146097;
 XYear:=(Temp Mod 146097) or 3;
 YYear:=(XYear Div 1461);
 Temp:=((((XYear mod 1461)+4) shr 2)*5)-3;
 Day:=((Temp Mod 153)+5) Div 5;
 TempMonth:=Temp Div 153;
 If TempMonth>=10 Then Begin
  Inc(YYear);
  Dec(TempMonth,12);
 End;
 Inc(TempMonth,3);
 Month:=TempMonth;
 Year:=YYear+(JulianDN*100);
End;

Procedure EpochToLocal(Epoch:LongInt;Var Year,Month,Day,Hour,Minute,Second:Word);
Var
 DateNum:LongInt;
Begin
 DateNum:=(Epoch div 86400)+2440588;
 JulianToGregorian(DateNum,Year,Month,day);
 Epoch:=Abs(Epoch mod 86400);
 Hour:=Epoch div 3600;
 Epoch:=Epoch mod 3600;
 Minute:=Epoch div 60;
 Second:=Epoch mod 60;
End;

Function DateTimeToStr(DateTime:LongInt):String;
Var
 Year,Month,Day,Hour,Min,Sec,MSec:Word;
 S,R:String;
Begin
 EpochToLocal(DateTime,Year,Month,Day,Hour,Min,Sec);
 R:=PadZeroLeft(Day,2)+'/'+PadZeroLeft(Month,2)+'/'+PadZeroLeft(Year,4)+' ';
 Str(Hour:2,S);
 R:=R+S+':';
 R:=R+PadZeroLeft(Min,2)+':'+PadZeroLeft(Sec,2);
 DateTimeToStr:=R;
End;

Function LastLogUsers(UserOrID:String):Boolean;
Var
 FilePasswd:Text;
 I,CellPos:Integer;
 UserID:LongInt;
 Err:Word;
 CurrLine,CurrWord:String;
 Cells:Array[0..6]of String;
Begin
 LastLogUsers:=False;
 {$I-}Assign(FilePasswd,BaseDir+'/etc/passwd');
 Reset(FilePasswd);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier ',BaseDir,'/etc/passwd');
  Halt(2);
 End;
 Write(PadRight('Nom utilisateur',18));
 Write(PadRight('Port',18));
 Write(PadRight('De',18));
 WriteLn('DerniŠre connexion');
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
   Val(Cells[2],UserID,Err);
   If(UserOrId='')or(Cells[0]=UserOrID)Then Begin
    LastLogUsers:=True;
    If(Use32)Then Begin
     Seek(LastLogFile,SizeOf(CurrRec32)*UserID);
     FillChar(CurrRec32,SizeOf(CurrRec32),0);
     BlockRead(LastLogFile,CurrRec32,SizeOf(CurrRec32),ByteReaded);
     Write(PadRight(Cells[0],18));
     If CurrRec32.ll_host[0]<>#0 Then Begin
      Write(PadRight(StrPas(CurrRec32.ll_line),18));
      Write(PadRight(StrPas(CurrRec32.ll_host),18));
      WriteLn(DateTimeToStr(CurrRec32.ll_time));
     End
      Else
     Begin
      Write(' ':18);
      Write(' ':18);
      WriteLn('** Jamais connect‚ **');
     End;
    End
     Else
    Begin
     Seek(LastLogFile,SizeOf(CurrRec64)*UserID);
     FillChar(CurrRec64,SizeOf(CurrRec64),0);
     BlockRead(LastLogFile,CurrRec64,SizeOf(CurrRec64),ByteReaded);
     Write(Cells[0]:18);
     If CurrRec64.ll_host[0]<>#0 Then Begin
      Write(PadRight(StrPas(CurrRec64.ll_line),18));
      Write(PadRight(StrPas(CurrRec64.ll_host),18));
      WriteLn(DateTimeToStr(CurrRec64.ll_time.A));
     End
      Else
     Begin
      Write(' ':18);
      Write(' ':18);
      WriteLn('** Jamais connect‚ **');
     End;
    End;
   End;
  End;
 End;
 Close(FilePasswd);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('LASTLOG : Cette commande permet d''afficher la derniŠre connexion ',
                    'd''un utilisateur sp‚cifi‚ ou de tous les utilisateurs.');
  WriteLn;
  WriteLn('Syntaxe : LASTLOG [options] [user]');
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
  Use32:=False;
  Use64:=False;
  UserOrId:='';
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='--cygwin'Then Begin
    If DirExist('/cygwin')Then BaseDir:='/cygwin' Else
    If DirExist('/cygwin32')Then BaseDir:='/cygwin32' Else
    If DirExist('/cygwin64')Then BaseDir:='/cygwin64';
   End
    Else
   If ParamStr(I)='--cygwin64'Then BaseDir:='/cygwin64' Else
   If ParamStr(I)='--cygwin32'Then BaseDir:='/cygwin32'
                              Else UserOrID:=ParamStr(I);
  End;
  {$I-}Assign(LastLogFile,BaseDir+'/var/log/lastlog');
  Reset(LastLogFile,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible d''ouvrir le fichier lastlog.');
   Halt(1);
  End;
  If FileSize(LastLogFile) mod SizeOf(LastLogRecord32)=0 Then Use32:=True Else
  If FileSize(LastLogFile) mod SizeOf(LastLogRecord64)=0 Then Use64:=True;
  LastLogUsers(UserOrId);
  Close(LastLogFile);
 End;
END.