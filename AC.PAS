{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal 3.2, Turbo Pascal 7)
}

Program AC;

{$A-}

Uses DOS,Strings;

Const
 EMPTY         = 0;  { Enregistrement vide }
 RUN_LVL       = 1;  { Changement de niveau d'ex‚cution }
 BOOT_TIME     = 2;  { Heure de d‚marrage du systŠme }
 NEW_TIME      = 3;  { Changement d'heure (ancien temps) }
 OLD_TIME      = 4;  { Changement d'heure (nouveau temps) }
 INIT_PROCESS  = 5;  { Processus d'initialisation }
 LOGIN_PROCESS = 6;  { Processus de connexion }
 USER_PROCESS  = 7;  { Session utilisateur active }
 DEAD_PROCESS  = 8;  { Processus termin‚ }
 ACCOUNTING    = 9;  { Audit }

 UT_LINESIZE=32;
 UT_NAMESIZE=32;
 UT_HOSTSIZE=256;

Type
 TExitStatus=Record
  e_termination: {$IFDEF FPC}SmallInt{$ELSE}Integer{$ENDIF};  { Code de terminaison }
  e_exit:{$IFDEF FPC}SmallInt{$ELSE}Integer{$ENDIF};         { Code de sortie }
 End;

 TTimeVal=Record
  tv_sec:LongInt;   { Secondes depuis l'epoch }
  tv_usec:LongInt;  { Microsecondes }
 End;

 TUTMPX32=Record
  ut_type:{$IFDEF FPC}SmallInt{$ELSE}Integer{$ENDIF};
  ut_pid:LongInt;
  ut_line:Array[0..UT_LINESIZE-1] of Char;
  ut_id:Array[0..3] of Char;
  ut_user:Array[0..UT_NAMESIZE-1] of Char;
  ut_host:Array[0..UT_HOSTSIZE-1] of Char;
  ut_exit:TExitStatus;
  ut_session:LongInt;
  ut_tv:TTimeVal;
  ut_addr_v6:Array[0..3] of LongInt;
  __glibc_reserved:Array[0..19] of Byte;
 End;

 TUTMPX64=Record
  ut_type:{$IFDEF FPC}SmallInt{$ELSE}Integer{$ENDIF};
  ut_pid:LongInt;
  ut_pid2:Word;
  ut_line:Array[0..UT_LINESIZE-1] of Char;
  ut_id:Array[0..3] of Char;
  ut_user:Array[0..UT_NAMESIZE-1] of Char;
  ut_host:Array[0..UT_HOSTSIZE-1] of Char;
  ut_exit:TExitStatus;
  ut_session:LongInt;
  ut_tv:TTimeVal;
  ut_session64:LongInt;
  ut_addr_v6:array[0..3] of LongInt;
  __glibc_reserved:Array[0..15] of Byte;
 End;

Const
 WtmpFile:String='/var/log/wtmp';

Var
 f:File;
 rec:TUTMPX64;
 numRead:Integer;
 i:Integer;
 DailyTotals,PrintYear,IndividualTotals,AllDays,PrintZeros:Boolean;
 UserCount:Integer;
 BaseDir:String;
 People:String;

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

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('AC : Cette commande permet d''afficher les statistiques ',
                'de temps de connexions d''un utilisateur.');
  WriteLn;
  Writeln('Syntaxe : AC [options] [people]');
  WriteLn;
  Writeln('  -a, --all-days   Inclue tous les jours');
  Writeln('  -V, --version    Affiche les informations version');
  Writeln('  -h, --help       Affiche l''aide de cette commande');
  WriteLn(' --cygwin          Recherche dans les dossiers de Cygwin');
  WriteLn(' --cygwin32        Recherche dans les dossiers de Cygwin en 32 bits');
  WriteLn(' --cygwin64        Recherche dans les dossiers de Cygwin en 64 bits');
 End
  Else
 Begin
  BaseDir:='';
  DailyTotals:=False;
  PrintYear:=False;
  IndividualTotals:=False;
  AllDays:=False;
  PrintZeros:=False;
  People:='';
  i:=1;
  While i<=ParamCount do Begin
   If ParamStr(I)='--cygwin'Then Begin
    If DirExist('/cygwin')Then BaseDir:='/cygwin' Else
    If DirExist('/cygwin32')Then BaseDir:='/cygwin32' Else
    If DirExist('/cygwin64')Then BaseDir:='/cygwin64';
   End
    Else
   If ParamStr(I)='--cygwin64'Then BaseDir:='/cygwin64' Else
   If ParamStr(I)='--cygwin32'Then BaseDir:='/cygwin32' Else
   If(ParamStr(i)='-d')or(ParamStr(i)='--daily-totals')Then DailyTotals:=True Else
   If(ParamStr(i)='-y')or(ParamStr(i)='--print-year')Then PrintYear:=True Else
   If(ParamStr(i)='-p')or(ParamStr(i)='--individual-totals')Then IndividualTotals:=True Else
   If(ParamStr(i)='-f')or(ParamStr(i)='--file')Then Begin
    If i<ParamCount Then Begin
     Inc(i);
     WtmpFile := ParamStr(i);
    End;
   End
    Else
   If(ParamStr(i)='-a')or(ParamStr(i)='--all-days')Then AllDays := True Else
   If(ParamStr(i)='-z')or(ParamStr(i)='--print-zeros')Then PrintZeros := True Else
   If(ParamStr(i)='-V')or(ParamStr(i)='--version')Then begin
    Writeln('ac - 1.0 - Clone Pascal');
    Halt(0);
   End
    else
   If People=''Then People:=ParamStr(i)
    Else
   Begin
    Writeln('ParamŠtre inconnu: ', ParamStr(i));
    Halt(1);
   End;
   Inc(i);
  End;
  {$I-}Assign(f,BaseDir+WtmpFile);
  Reset(f,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible d''ouvrir le fichier ',BaseDir+WtmpFile);
   Halt(1);
  End;
  While Not EOF(f) do begin
   BlockRead(f,Rec,SizeOf(rec),numRead);
   If NumRead<>SizeOf(rec)Then Break;
   If People<>''Then Begin
    If(rec.ut_user=People)Then Begin
     If Not(AllDays)Then Begin
      Writeln('Utilisateur: ', rec.ut_user, ' … ',
               rec.ut_line,', h“te : ',rec.ut_host);
      WriteLn(DateTimeToStr(rec.ut_tv.tv_sec));
     End;
     Inc(userCount);
    End;
   End
    Else
   If rec.ut_type=USER_PROCESS Then Begin
    If Not(AllDays)Then Begin
     Writeln('Utilisateur: ', rec.ut_user, ' … ',
              rec.ut_line,', h“te : ',rec.ut_host);
     WriteLn(DateTimeToStr(rec.ut_tv.tv_sec));
    End;
    Inc(userCount);
   End;
  End;
  Close(f);
  If DailyTotals then Writeln('Jours totales actifs.');
  If PrintYear then Writeln('Ann‚e ayant ‚t‚ affich.');
  If IndividualTotals then Writeln('Totals individuel active.');
  If AllDays then Begin
   Writeln('  total  ', userCount);
  End;
  If PrintZeros then Writeln('Affiche les nombres d''entr‚es vide.');
 End;
END.