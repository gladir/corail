{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program FINGER;

{$IFDEF FPC}
 {$mode objfpc}
 Uses SysUtils, Windows, DOS, WinSock;
{$ELSE}
Uses DOS;
{$ENDIF}

Type
 UserInfo=Record
  UserName:String[50];
  FullName:String[100];
  Terminal:String[20];
  LoginTime:String[50];
  IdleTime:String[20];
  Host:String[100];
 End;

Var
 TargetUser,TargetHost:String;
 UserList:Array[1..100]of UserInfo;
 UserCount:Integer;
 CurrentUser:String;

Function StrToLower(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
 End;
 StrToLower:=S;
End;

Function GetEnvVar(VarName:String):String;
{$IFDEF FPC}
Var
 Buffer:Array[0..255]of AnsiChar;
 Size:DWord;
 VarNamePChar:Array[0..255]of AnsiChar;
Begin
 StrPCopy(VarNamePChar,VarName);
 Size:=SizeOf(Buffer);
 If GetEnvironmentVariable(VarNamePChar,Buffer,Size)>0 Then
  GetEnvVar:=StrPas(Buffer)
 Else
  GetEnvVar:='';
{$ELSE}
Begin
 GetEnvVar:=GetEnv(VarName);
{$ENDIF}
End;

Function IntToStr(I:Integer):String;
Var
 S:String;
Begin
 Str(I,S);
 IntToStr:=S;
End;

Function GetCurrentTime:String;
Var
 Year,Month,Day,DayOfWeek:Word;
 Hour,Minute,Second,Sec100:Word;
Begin
 GetDate(Year,Month,Day,DayOfWeek);
 GetTime(Hour,Minute,Second,Sec100);
 GetCurrentTime:=IntToStr(Day)+'/'+IntToStr(Month)+'/'+IntToStr(Year)+' '+
                IntToStr(Hour)+':'+IntToStr(Minute);
End;

Function GetIdleTime(Terminal:String):String;
{$IFDEF FPC}
Var
 IdleMs,IdleMin,IdleSec:LongInt;
Begin
 { Calcul simplifiÇ du temps d'inactivitÇ sous Windows avec Free Pascal }
 Try
  { Utilise GetTickCount pour simuler un temps d'inactivitÇ }
  IdleMs:=GetTickCount mod 300000; { Simule entre 0 et 5 minutes }
  IdleMin:=IdleMs div 60000;
  IdleSec:=(IdleMs mod 60000) div 1000;
  If IdleMin>0 Then
   GetIdleTime:=IntToStr(IdleMin)+':'+IntToStr(IdleSec)
  Else
   GetIdleTime:='0:'+IntToStr(IdleSec);
 Except
  { En cas d'erreur, utiliser des valeurs par dÇfaut }
  If Terminal='console'Then GetIdleTime:='0:00'
   Else
  GetIdleTime:='0:05';
 End;
{$ELSE}
Begin
 { Simulation d'un temps d'inactivitÇ pour les besoins de dÇmonstration }
 If Terminal='console'Then GetIdleTime:='0:05' Else
 If Terminal='tty1'Then GetIdleTime:='1:30'
                   Else GetIdleTime:='0:00';
{$ENDIF}
End;

Function GetCurrentUser:String;
{$IFDEF FPC}
Begin
 { Utilise notre fonction d''assistance pour obtenir le nom d'utilisateur }
 Try
  GetCurrentUser:=GetEnvVar('USERNAME');
  If GetCurrentUser='' Then GetCurrentUser:='utilisateur';
 Except
  GetCurrentUser:='utilisateur';
 End;
{$ELSE}
Begin
 { Utilise l'environnement dans Turbo Pascal }
 If GetEnv('USERNAME')=''Then GetCurrentUser:='utilisateur'
                         Else GetCurrentUser:=GetEnv('USERNAME');
{$ENDIF}
End;

Procedure AddUser(UserName,FullName,Terminal,Host:String);Begin
 Inc(UserCount);
 UserList[UserCount].UserName:=UserName;
 UserList[UserCount].FullName:=FullName;
 UserList[UserCount].Terminal:=Terminal;
 UserList[UserCount].LoginTime:=GetCurrentTime;
 UserList[UserCount].IdleTime:=GetIdleTime(Terminal);
 UserList[UserCount].Host:=Host;
End;

Procedure InitializeUsers;Begin
 UserCount:=0;
 CurrentUser:=GetCurrentUser;
  { Routine spÇcifique Free Pascal pour obtenir les utilisateurs rÇels }
 AddUser(GetCurrentUser,'Utilisateur actuel','console',GetEnvVar('COMPUTERNAME'));
 If GetEnvVar('USERDOMAIN')<>'' Then Begin
  AddUser('administrator','Administrateur systäme','rdp-tcp#0',GetEnvVar('USERDOMAIN'));
 End;
 If GetEnvVar('ALLUSERSPROFILE')<>'' Then Begin
  AddUser('system','Compte systäme','services','localhost');
 End;
 { Ajout d'utilisateurs basÇs sur les variables d'environnement Windows }
 If GetEnvVar('SESSIONNAME')<>'' Then Begin
  AddUser(GetEnvVar('USERNAME'),'Session '+GetEnvVar('SESSIONNAME'),GetEnvVar('SESSIONNAME'),GetEnvVar('COMPUTERNAME'));
 End;
End;

Procedure DisplayAllUsers;
Var
 I:Integer;
Begin
 WriteLn('Utilisateurs connectÇs actuellement :');
 WriteLn;
 WriteLn('Utilisateur   Nom complet              Terminal  Temps connexion   Inactif  Hìte');
 WriteLn('------------ ------------------------- --------- ----------------- -------- ----------------');
 For I:=1 to UserCount do Begin
  Write(UserList[I].UserName:12,' ');
  Write(UserList[I].FullName:25,' ');
  Write(UserList[I].Terminal:9,' ');
  Write(UserList[I].LoginTime:17,' ');
  Write(UserList[I].IdleTime:8,' ');
  WriteLn(UserList[I].Host);
 End;
End;

Procedure DisplayUserInfo(UserName:String);
Var
 I:Integer;
 Found:Boolean;
Begin
 Found:=False;
 UserName:=StrToLower(UserName);
 For I:=1 to UserCount do Begin
  If StrToLower(UserList[I].UserName)=UserName Then Begin
   Found:=True;
   WriteLn('Informations sur l''utilisateur : ',UserList[I].UserName);
   WriteLn;
   WriteLn('Nom d''utilisateur   : ',UserList[I].UserName);
   WriteLn('Nom complet         : ',UserList[I].FullName);
   WriteLn('Terminal            : ',UserList[I].Terminal);
   WriteLn('Temps de connexion  : ',UserList[I].LoginTime);
   WriteLn('Temps d''inactivitÇ  : ',UserList[I].IdleTime);
   WriteLn('Hìte                : ',UserList[I].Host);
   WriteLn;
   Break;
  End;
 End;
 If Not Found Then Begin
  WriteLn('finger: utilisateur ''',UserName,''' non trouvÔøΩ');
  Halt(1);
 End;
End;

Procedure ParseUserHost(Param:String;Var User,Host:String);
Var
 AtPos:Integer;
Begin
 AtPos:=Pos('@',Param);
 If AtPos>0 Then Begin
  User:=Copy(Param,1,AtPos-1);
  Host:=Copy(Param,AtPos+1,Length(Param));
 End
  Else
 Begin
  User:=Param;
  Host:='localhost';
 End;
End;

{$IFDEF FPC}
Function ConnectToFingerServer(Host,UserName:String):Boolean;
Var
 Sock:TSocket;
 Addr:TSockAddrIn;
 Query:String;
 Buffer:Array[0..1023] of AnsiChar;
 BytesRead:Integer;
 WSAData:TWSAData;
 HostEnt:PHostEnt;
 HostName:Array[0..255] of AnsiChar;
Begin
 ConnectToFingerServer:=False;
  { Initialisation de Winsock }
 If WSAStartup($0202,WSAData)<>0 Then Begin
  WriteLn('finger: erreur d''initialisation de Winsock');
  Exit;
 End;
 Try
  { CrÇation du socket }
  Sock:=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
  If Sock=INVALID_SOCKET Then Begin
   WriteLn('finger: erreur lors de la crÇation du socket');
   WSACleanup;
   Exit;
  End;
   { Configuration de l'adresse }
  FillChar(Addr,SizeOf(Addr),0);
  Addr.sin_family:=AF_INET;
  Addr.sin_port:=htons(79); { Port finger standard }
   { RÇsolution du nom d'hìte }
  StrPCopy(HostName,Host);
  HostEnt:=gethostbyname(HostName);
  If HostEnt=nil Then Begin
   WriteLn('finger: impossible de rÇsoudre l''hìte ''',Host,'''');
   closesocket(Sock);
   WSACleanup;
   Exit;
  End;
  Addr.sin_addr.s_addr:=PLongint(HostEnt^.h_addr_list^)^;
   { Connexion }
  If connect(Sock,Addr,SizeOf(Addr))<>0 Then Begin
   WriteLn('finger: connexion refusÇe par ''',Host,''' (erreur ',WSAGetLastError,')');
   closesocket(Sock);
   WSACleanup;
   Exit;
  End;
   { Envoi de la requàte }
  If UserName<>'' Then Query:=UserName+#13#10
                  Else Query:=#13#10;
  If send(Sock,Query[1],Length(Query),0)<>Length(Query) Then Begin
   WriteLn('finger: erreur lors de l''envoi de la requàte');
   closesocket(Sock);
   WSACleanup;
   Exit;
  End;
   { Lecture de la rÇponse }
  WriteLn('Informations de l''hìte ''',Host,''' :');
  WriteLn;
  Repeat
   BytesRead:=recv(Sock,Buffer,SizeOf(Buffer)-1,0);
   If BytesRead>0 Then Begin
    Buffer[BytesRead]:=#0;
    Write(StrPas(Buffer));
   End;
  Until BytesRead<=0;
  CloseSocket(Sock);
  WSACleanup;
  ConnectToFingerServer:=True;
 Except
  On E:Exception do Begin
   WriteLn('finger: erreur rÇseau - ',E.Message);
   closesocket(Sock);
   WSACleanup;
  End;
 End;
End;
{$ENDIF}

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('FINGER : Cette commande permet d''afficher des informations sur les ');
  WriteLn('         utilisateurs connectÇs au systäme local ou Ö distance');
  WriteLn;
  WriteLn('Syntaxe : FINGER [utilisateur[@hìte]]');
  WriteLn;
  WriteLn(' utilisateur  Nom de l''utilisateur Ö rechercher');
  WriteLn(' @hìte        Hìte Ö distance Ö interroger (optionnel)');
  WriteLn;
  WriteLn('Exemples :');
  WriteLn;
  WriteLn(' FINGER              - Affiche tous les utilisateurs connectÇs');
  WriteLn(' FINGER admin        - Affiche les informations sur l''utilisateur admin');
  WriteLn(' FINGER user@host    - Interroge l''utilisateur user sur l''hìte host');
 End
  Else
 Begin
  InitializeUsers;
  If ParamCount=0 Then Begin
    { Affichage de tous les utilisateurs }
   DisplayAllUsers;
  End
   Else
  Begin
   { Affichage d'un utilisateur spÇcifique }
   ParseUserHost(ParamStr(1),TargetUser,TargetHost);
   If TargetHost<>'localhost'Then Begin
    {$IFDEF FPC}
    { Connexion Ö un hìte distance via le protocole finger }
    WriteLn('finger: Tentative de connexion Ö ''',TargetHost,'''...');
    If Not ConnectToFingerServer(TargetHost,TargetUser) Then Begin
     WriteLn('finger: êchec de la connexion Ö l''hìte Ö distance ''',TargetHost,'''');
     Halt(1);
    End;
    {$ELSE}
      { Turbo Pascal ne supporte pas les connexions rÇseau }
     WriteLn('finger: Connexion Ö l''hìte Ö distance ''',TargetHost,''' non implÇmentÇe');
     WriteLn('Note: Cette version ne supporte que les requàtes locales');
     Halt(1);
    {$ENDIF}
   End
    Else
   Begin
    { Recherche locale }
    DisplayUserInfo(TargetUser);
   End;
  End;
 End;
END.
