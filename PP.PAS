{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program PP; { Prompt Pascal }

Uses Crt,DOS;

Const
 CommandList:Array[0..54]of String[20]=(
  'CHDIR','CLRSCR','COPYFILE','CREATEDIR','DELAY','DISKFREE','DISKSIZE',
  'DISKTYPE','ERASE','EXEC','EXIT','FEXPAND','FILESIZE','FINDFIRST',
  'FINDNEXT','FOR','GETCBREAK','GETDATE','GETDIR','GETDISK','GETENV',
  'GETFATTR','GETFTIME','GETTIME','GETVERIFY','GETVERSION','GETVOLUME',
  'GOTO','GOTOXY','HALT','HELP','HIGHVIDEO','IF','LIST','LOWVIDEO','MKDIR',
  'MOVEFILE','NORMVIDEO','REMOVEDIR','RENAME','RMDIR','READKEY',
  'RUNERROR','SETCBREAK','SETDATE','SETDISK','SETENV','SETFATTR',
  'SETFTIME','SETTIME','SETVERIFY','TEXTBACKGROUND','TEXTCOLOR','WRITE',
  'WRITELN'
 );

Var
 Echo:Boolean;
 CommandFound,Terminated:Boolean;
 CurrCommand,ParamList,CmdStr:String;
 ExtractI,J:Integer;
 CurrFile:SearchRec;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

Function TrimL(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If S[I]<>' 'Then Begin
   TrimL:=Copy(S,I,255);
   Exit;
  End;
 End;
 TrimL:=S;
End;

Function CopyFile(Source,Target:String;ShowProgression:Boolean):Boolean;
Var
 SourceFile,TargetFile:File;
 RecordsRead:Integer;
 Buffer:Array[1..1000]of Byte;
Begin
 CopyFile:=False;
 Assign(SourceFile,Source);
 {$I-}Reset(SourceFile,1);{$I+}
 If IOResult<>0Then Begin
  WriteLn('Fichier source introuvable ',Source);
  Exit;
 End;
 Assign(TargetFile,Target);
 {$I-}Rewrite(TargetFile,1);
 If(ShowProgression)Then WriteLn('. = 1000 octets de copies');
 BlockRead(SourceFile,Buffer,SizeOf(Buffer),RecordsRead);
 While RecordsRead>0 do Begin
  If(ShowProgression)Then Write('.');
  BlockWrite(TargetFile,Buffer,RecordsRead);
  BlockRead(SourceFile,Buffer,SizeOf(Buffer),RecordsRead);
 End;
 If(ShowProgression)Then WriteLn;
 Close(SourceFile);
 Close(TargetFile);
 {$I+}
 CopyFile:=True;
End;

Function GetErrorMessage(Code:Word):String;Begin
 Case Code of
  0:GetErrorMessage:='';
  2:GetErrorMessage:='Fichier introuvable';
  3:GetErrorMessage:='Chemin introuvable';
  4:GetErrorMessage:='Trop de fichiers ouvert';
  5:GetErrorMessage:='Acces refuse';
  6:GetErrorMessage:='Handle de fichier invalide';
  12:GetErrorMessage:='Mode d''acces sur disque invalide';
  15:GetErrorMessage:='Num‚ro de disque invalide';
  16:GetErrorMessage:='Impossible de supprimer le r‚pertoire';
  17:GetErrorMessage:='Impossible de renommer sur plusieurs volumes';
  100:GetErrorMessage:='Erreur de lecture … partir du disque';
  101:GetErrorMessage:='Erreur d''ecriture sur le disque';
  102:GetErrorMessage:='Fichier non attribue';
  103:GetErrorMessage:='Le fichier n''est pas ouvert';
  104:GetErrorMessage:='Le fichier n''est pas ouvert … l''entree';
  105:GetErrorMessage:='Le fichier n''est pas ouvert … la sortie';
  106:GetErrorMessage:='Numero invalide';
  150:GetErrorMessage:='Disque protege en ecriture';
  151:GetErrorMessage:='Peripherique est inconnu';
  152:GetErrorMessage:='Disque pas pret';
  153:GetErrorMessage:='Commande inconnue';
  154:GetErrorMessage:='Echec de verification CRC';
  155:GetErrorMessage:='Disque invalide';
  156:GetErrorMessage:='Erreur de recherche sur disque';
  157:GetErrorMessage:='Type de media invalide';
  158:GetErrorMessage:='Secteur introuvable';
  159:GetErrorMessage:='L''imprimante n''a plus de papier';
  160:GetErrorMessage:='Erreur d''ecriture sur le peripherique';
  161:GetErrorMessage:='Erreur de lecture sur le peripherique';
  162:GetErrorMessage:='Defaillance materielle';
  Else GetErrorMessage:='Erreur inconnue';
 End;
End;

Procedure ExtractProcedure;
Var
 I:Byte;
Begin
 For I:=1 to Length(CmdStr)do Begin
  If Not(CmdStr[I]in['A'..'Z','a'..'z','_','0'..'9'])Then Begin
   CurrCommand:=StrToUpper(Copy(CmdStr,1,I-1));
   ParamList:=TrimL(Copy(CmdStr,I,255));
   Exit;
  End;
 End;
 CurrCommand:=StrToUpper(CmdStr);
 ParamList:='';
End;

Function ExtractNumber(Pos:Integer):LongInt;
Var
 CurrParam:String;
 Value:LongInt;
 Err:Word;
Begin
 ExtractI:=Pos;
 While (ExtractI<Length(ParamList))and(ParamList[ExtractI]=' ')do Inc(ExtractI);
 If Not(ParamList[ExtractI]in['0'..'9'])Then Begin
  WriteLn('Nombre attendue !');
  Exit;
 End;
 CurrParam:='';
 While (ExtractI<Length(ParamList))and(ParamList[ExtractI]in['0'..'9'])do Begin
  CurrParam:=CurrParam+ParamList[ExtractI];
  Inc(ExtractI);
 End;
 Val(CurrParam,Value,Err);
 ExtractNumber:=Value;
End;

Function ExtractString(Pos:Integer):String;
Var
 CurrParam:String;
Begin
 ExtractI:=Pos;
 While (ExtractI<Length(ParamList))and(ParamList[ExtractI]=' ')do Inc(ExtractI);
 If ParamList[ExtractI]=''''Then Inc(ExtractI)
  Else
 Begin
  WriteLn('Chaine de caracteres attendue !');
  ExtractString:='';
  Exit;
 End;
 CurrParam:='';
 While ParamList[ExtractI]<>''''do Begin
  CurrParam:=CurrParam+ParamList[ExtractI];
  If Copy(ParamList,ExtractI,2)='''' + ''''Then Begin
   Inc(ExtractI,2);
  End
   Else
  Inc(ExtractI);
 End;
 If ParamList[ExtractI]=''''Then Inc(ExtractI)
  Else
 Begin
  WriteLn('Fin de chaine de caracteres attendue !');
  ExtractString:='';
  Exit;
 End;
 ExtractString:=CurrParam;
End;

Procedure HomeMessage;Begin
 WriteLn;
 TextColor(White);
 Write('PROMPT PASCAL (PP) - ');
 NormVideo;
 Write('Interpreteur de commande Pascal');
 WriteLn;
End;

Procedure ShowPrompt;
Var
 CurrentDir:String;
Begin
 If Not(Echo)Then Exit;
 GetDir(0,CurrentDir);
 WriteLn('Repertoire courant : ',CurrentDir);
 WriteLn;
 WriteLn('Pascal Prompt (PP) Pret');
End;

Procedure ChDirProc;
Var
 Path:String;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  Path:=ExtractString(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  ChDir(Path);
 End
  Else
 WriteLn('Parametre attendue !');
End;

Procedure ClrScrProc;Begin
 If ParamList<>''Then Begin
  WriteLn('Parametre non requis !');
  Exit;
 End;
 ClrScr;
End;

Procedure CopyFileProc;
Var
 Source,Target:String;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  Source:=ExtractString(2);
  If Copy(ParamList,ExtractI,1)<>','Then Begin
   WriteLn(''','' attendue');
   Exit;
  End;
  Inc(ExtractI);
  Target:=ExtractString(ExtractI);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  CopyFile(Source,Target,False);
 End
  Else
 WriteLn('Parametre attendue !');
End;

Procedure DelayProc;
Var
 Value:LongInt;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  Value:=ExtractNumber(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  Delay(Value);
 End
  Else
 WriteLn('Valeur attendue');
End;

Procedure DiskFreeProc;
Var
 CurrDrive:String;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  CurrDrive:=ExtractString(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  WriteLn(DiskFree(Byte(CurrDrive[1])-64));
 End
  Else
 WriteLn(DiskFree(0));
End;

Procedure DiskSizeProc;
Var
 CurrDrive:String;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  CurrDrive:=ExtractString(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  WriteLn(DiskSize(Byte(CurrDrive[1])-64));
 End
  Else
 WriteLn(DiskSize(0));
End;

Procedure DiskTypeProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure EraseProc;
Var
 F:File;
 Err:Integer;
 Path:String;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  Path:=ExtractString(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  {$I-}Assign(F,Path);
  Erase(F);
  {$I+}
  Err:=IoResult;
  If Err=0Then WriteLn('1 fichier de supprime')
          Else WriteLn(GetErrorMessage(Err));
 End
  Else
 WriteLn('Parametre attendue !');
End;

Procedure ExecProc;
Var
 Command,Parameters:String;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  Command:=ExtractString(2);
  Parameters:='';
  If Copy(ParamList,ExtractI,1)=','Then Begin
   Inc(ExtractI);
   Parameters:=ExtractString(ExtractI);
  End;
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  Exec(Command,Parameters);
 End
  Else
 WriteLn('Parametre attendue !');
End;

Procedure ExitProc;Begin
 Terminated:=True;
End;

Procedure FExpandProc;
Var
 Path:String;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  Path:=ExtractString(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  WriteLn(FExpand(Path));
 End
  Else
 WriteLn('Parametre attendue !');
End;

Procedure FileSizeProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure FindFirstProc;
Var
 T:DateTime;
 ShowDir:String;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  ShowDir:=ExtractString(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
 End
  Else
 ShowDir:='*.*';
 FindFirst(ShowDir,AnyFile,CurrFile);
 If DOSError=0 Then Begin
  Write(PadRight(CurrFile.Name,13));
  If CurrFile.Attr and Directory=Directory Then Begin
   Write(PadRight('<DIR>',15));
  End
   Else
  Write(CurrFile.Size:15);
  UnpackTime(CurrFile.Time,T);
  WriteLn(' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2));
 End;
End;

Procedure FindNextProc;
Var
 T:DateTime;
Begin
 If ParamList<>''Then Begin
  WriteLn('Parametre non requis !');
  Exit;
 End;
 FindNext(CurrFile);
 If DOSError=0 Then Begin
  Write(PadRight(CurrFile.Name,13));
  If CurrFile.Attr and Directory=Directory Then Begin
   Write(PadRight('<DIR>',15));
  End
   Else
  Write(CurrFile.Size:15);
  UnpackTime(CurrFile.Time,T);
  WriteLn(' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2));
 End;
End;

Procedure ForProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure GetCBreakProc;
Var
 X:Boolean;
Begin
 If ParamList<>''Then Begin
  WriteLn('Parametre non requis !');
  Exit;
 End;
  GetCBreak(X);
  If(X)Then WriteLn('TRUE')
       Else WriteLn('FALSE');
End;

Procedure GetDateProc;
Var
 Year,Month,Day,DayOfMonth:Word;
Begin
 If ParamList<>''Then Begin
  WriteLn('Parametre non requis !');
  Exit;
 End;
 GetDate(Year,Month,Day,DayOfMonth);
 WriteLn('La date du jour est ',Year:4,'-',PadZeroLeft(Month,2),'-',PadZeroLeft(Day,2));
End;

Procedure GetDirProc;
Var
 Value:LongInt;
 Path:String;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  Value:=ExtractNumber(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  GetDir(Value,Path);
 End
  Else
 GetDir(0,Path);
 WriteLn(Path);
End;

Procedure GetDiskProc;
Var
 CurrentDir:String;
Begin
 If ParamList<>''Then Begin
  WriteLn('Parametre non requis !');
  Exit;
 End;
 GetDir(0,CurrentDir);
 WriteLn(CurrentDir[1]);
End;

Procedure GetEnvProc;
Var
 I:Integer;
 CurrStr:String;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  CurrStr:=ExtractString(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  WriteLn(GetEnv(CurrStr));
 End
  Else
 For I:=0to EnvCount do WriteLn(EnvStr(I));
End;

Procedure GetFAttrProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure GetFTimeProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure GetTimeProc;
Var
 Hour,Minute,Second,CentSec:Word;
Begin
 If ParamList<>''Then Begin
  WriteLn('Parametre non requis !');
  Exit;
 End;
 GetTime(Hour,Minute,Second,CentSec);
 WriteLn('L''heure actuelle est ',Hour:2,':',PadZeroLeft(Minute,2),':',PadZeroLeft(Second,2),',',CentSec);
End;

Procedure GetVerifyProc;
Var
 X:Boolean;
Begin
 If ParamList<>''Then Begin
  WriteLn('Parametre non requis !');
  Exit;
 End;
 GetVerify(X);
 If(X)Then WriteLn('TRUE')
      Else WriteLn('FALSE');
End;

Procedure GetVersionProc;
Var
 Ver:Word;
Begin
 If ParamList<>''Then Begin
  WriteLn('Parametre non requis !');
  Exit;
 End;
 Ver:=DosVersion;
 WriteLn('DOS version ',Lo(Ver),'.',Hi(Ver));
End;

Procedure GetVolumeProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure GotoProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure GotoXYProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure HaltProc;
Var
 Value:LongInt;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  Value:=ExtractNumber(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  Halt(Value);
 End
  Else
 Terminated:=True;
End;

Procedure HelpProc;
Var
 I:Integer;
 HelpCommand:String;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  HelpCommand:=StrToUpper(ExtractString(2));
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  If HelpCommand='CHDIR'Then Begin
   WriteLn('Nom:        CHDIR');
   WriteLn('Decription: Cette procedure change de repertoire');
   WriteLn('Syntaxe:    CHDIR(''repertoire'')');
  End
   Else
  If HelpCommand='CLRSCR'Then Begin
   WriteLn('Nom:         CLRSCR');
   WriteLn('Description: Cette procedure permet d''effacer l''‚cran.');
   WriteLn('Syntaxe:     CLRSCR');
  End
   Else
  If HelpCommand='COPYFILE'Then Begin
   WriteLn('Nom:         COPYFILE');
   WriteLn('Description: Cette procedure permet de copier des fichiers');
   WriteLn('Syntaxe:     COPYFILE(''source'',''destination'')');
  End
   Else
  If HelpCommand='CREATEDIR'Then Begin
   WriteLn('Nom:         CREATEDIR');
   WriteLn('Description: Cette proc‚dure permet de cr‚er un r‚pertoire.');
   WriteLn('Syntaxe:     CREATEDIR(''repertoire'')');
  End
   Else
  If HelpCommand='DELAY'Then Begin
   WriteLn('Nom:         DELAY');
   WriteLn('Description: Cette proc‚dure permet d''attendre le nombre de milliŠme de secondes.');
   WriteLn('Syntaxe:     DELAY(milliseconde)');
  End
   Else
  If HelpCommand='DISKFREE'Then Begin
   WriteLn('Nom:         DISKFREE');
   WriteLn('Description: Cette fonction permet d''afficher l''espace de libre sur le disque.');
   WriteLn('Syntaxe 1:   DISKFREE');
   WriteLn('Syntaxe 2:   DISKFREE(''C'')');
  End
   Else
  If HelpCommand='DISKSIZE'Then Begin
   WriteLn('Nom:         DISKSIZE');
   WriteLn('Description: Cette fonction permet d''afficher l''espace total sur le disque.');
   WriteLn('Syntaxe 1:   DISKSIZE');
   WriteLn('Syntaxe 2:   DISKSIZE(''C'')');
  End
   Else
  If HelpCommand='ERASE'Then Begin
   WriteLn('Nom:         ERASE');
   WriteLn('Description: Cette procedure permet d''effacer un fichier.');
   WriteLn('Syntaxe:     ERASE(''nomdufichier'')');
  End
   Else
  If HelpCommand='EXEC'Then Begin
   WriteLn('Nom:         EXEC');
   WriteLn('Description: Cette proc‚dure permet d''ex‚cuter une commande.');
   WriteLn('Syntaxe 1:   EXEC(''nomduprogramme'')');
   WriteLn('Syntaxe 2:   EXEC(''nomduprogramme'',''parametres'')');
  End
   Else
  If HelpCommand='EXIT'Then Begin
   WriteLn('Nom:         EXIT');
   WriteLn('Description: Cette procedure permet de sortir de l''interpreteur de commande.');
   WriteLn('Syntaxe:     EXIT');
  End
   Else
  If HelpCommand='FEXPAND'Then Begin
   WriteLn('Nom:         FEXPAND');
   WriteLn('Description: Cette fonction permet de retourner le nom complet d''un fichier.');
   WriteLn('Syntaxe:     FEXPAND(''nom'')');
  End
   Else
  If HelpCommand='FILESIZE'Then Begin
   WriteLn('Nom:         FILESIZE');
   WriteLn('Description: Cette fonction permet de retourner la taille d''un fichier.');
   WriteLn('Syntaxe:     FILESIZE(''nomdufichier'')');
  End
   Else
  If HelpCommand='FINDFIRST'Then Begin
   WriteLn('Nom:         FINDFIRST');
   WriteLn('Description: Cette proc‚dure permet d''afficher la premiere entree d''un repertoire.');
   WriteLn('Syntaxe:     FINDFIRST(''chemin'')');
  End
   Else
  If HelpCommand='FINDNEXT'Then Begin
   WriteLn('Nom:         FINDNEXT');
   WriteLn('Description: Cette procedure permet d''afficher l''entree suivante d''un repertoire.');
   WriteLn('Syntaxe:     FINDNEXT');
  End
   Else
  If HelpCommand='GETCBREAK'Then Begin
   WriteLn('Nom:         GETCBREAK');
   WriteLn('Description: Cette fonction permet de demander l''etat du Ctrl+Break.');
   WriteLn('Syntaxe:     GETCBREAK');
  End
   Else
  If HelpCommand='GETDATE'Then Begin
   WriteLn('Nom:         GETDATE');
   WriteLn('Description: Cette fonction permet de demander la date courante.');
   WriteLn('Syntaxe:     GETDATE');
  End
   Else
  If HelpCommand='GETDIR'Then Begin
   WriteLn('Nom:         GETDIR');
   WriteLn('Description: Cette fonction permet de demander le repertoire courant.');
   WriteLn('Syntaxe 1:   GETDIR');
   WriteLn('Syntaxe 2:   GETDIR(numerodisque)');
  End
   Else
  If HelpCommand='GETDISK'Then Begin
   WriteLn('Nom:         GETDISK');
   WriteLn('Description: Cette fonction permet de demander le disque courant.');
   WriteLn('Syntaxe:     GETDISK');
  End
   Else
  If HelpCommand='GETENV'Then Begin
   WriteLn('Nom:         GETENV');
   WriteLn('Description: Cette fonction permet de demander la liste ',
                         'des variables d''environnement du systeme.');
   WriteLn('Syntaxe 1:   GETENV');
   WriteLn('Syntaxe 2:   GETENV(''nomdevariable'')');
  End
   Else
  If HelpCommand='GETFATTR'Then Begin
   WriteLn('Nom:         GETFATTR');
   WriteLn('Description: Cette fonction permet d''afficher les attributs d''un fichier.');
   WriteLn('Syntaxe:     GETFATTR(''nomdufichier'')');
  End
   Else
  If HelpCommand='GETFTIME'Then Begin
   WriteLn('Nom:         GETFTIME');
   WriteLn('Description: Cette fonction permet d''afficher l''heure d''un fichier.');
   WriteLn('Syntaxe:     GETFTIME(''nomdufichier'')');
  End
   Else
  If HelpCommand='GETTIME'Then Begin
   WriteLn('Nom:         GETTIME');
   WriteLn('Description: Cette fonction permet de demander l''heure courante.');
   WriteLn('Syntaxe:     GETTIME');
  End
   Else
  If HelpCommand='GETVERIFY'Then Begin
   WriteLn('Nom:         GETVERIFY');
   WriteLn('Description: Cette fonction permet de demander l''etat du drapeau de verification.');
   WriteLn('Syntaxe:     GETVERIFY');
  End
   Else
  If HelpCommand='GOTOXY'Then Begin
   WriteLn('Nom:         GOTOXY');
   WriteLn('Description: Cette procedure permet de fixer l''emplacement du curseur.');
   WriteLn('Syntaxe:     GOTOXY(x,y)');
  End
   Else
  If HelpCommand='HALT'Then Begin
   WriteLn('Nom:         HALT');
   WriteLn('Description: Cette procedure permet de sortir de l''interpreteur de commande');
   WriteLn('Syntaxe 1:   HALT');
   WriteLn('Syntaxe 2:   HALT(codedesortie)');
  End
   Else
  If HelpCommand='HELP'Then Begin
   WriteLn('Nom:         HELP');
   WriteLn('Description: Cette procedure permet d''afficher de ',
           'l''aide sur une procedure ou fonction');
   WriteLn('Syntaxe 1:   HELP');
   WriteLn('Syntaxe 2:   HELP(''procedureoufonction'')');
  End
   Else
  If HelpCommand='HIGHVIDEO'Then Begin
   WriteLn('Nom:         HIGHVIDEO');
   WriteLn('Description: Cette procedure permet de faire passer l''affichage ',
                         'en haute intensite.');
   WriteLn('Syntaxe:     HIGHVIDEO');
  End
   Else
  If HelpCommand='LIST'Then Begin
   WriteLn('Nom:         LIST');
   WriteLn('Description: Cette procedure permet d''afficher la liste des fichiers.');
   WriteLn('Syntaxe 1:   LIST');
   WriteLn('Syntaxe 2:   LIST(''repertoire'')');
   WriteLn('Exemple:     LIST(''*.*''');
  End
   Else
  If HelpCommand='LOWVIDEO'Then Begin
   WriteLn('Nom:         LOWVIDEO');
   WriteLn('Description: Cette procedure permet de faire passer l''affichage en basse intensite.');
   WriteLn('Syntaxe:     LOWVIDEO');
  End
   Else
  If HelpCommand='MKDIR'Then Begin
   WriteLn('Nom:         MKDIR');
   WriteLn('Description: Cette procedure permet de creer un repertoire.');
   WriteLn('Syntaxe:     MKDIR(''nomdurepertoire'')');
  End
   Else
  If HelpCommand='MOVEFILE'Then Begin
   WriteLn('Nom:         MOVEFILE');
   WriteLn('Description: Cette procedure permet de deplacer un fichier.');
   WriteLn('Syntaxe:     MOVEFILE(''ancienemplacement'',''nouvelleemplacement'')');
  End
   Else
  If HelpCommand='NORMVIDEO'Then Begin
   WriteLn('Nom:         NORMVIDEO');
   WriteLn('Description: Cette procedure permet de fixer la couleur de l''ecriture ',
                         'du texte a intensite normal dans les ecrans de texte.');
   WriteLn('Syntaxe:     NORMVIDEO');
  End
   Else
  If HelpCommand='REMOVEDIR'Then Begin
   WriteLn('Nom:         REMOVEDIR');
   WriteLn('Description: Cette procedure permet de supprimer un repertoire.');
   WriteLn('Syntaxe:     REMOVEDIR(''repertoire'')');
  End
   Else
  If HelpCommand='RENAME'Then Begin
   WriteLn('Nom:         RENAME');
   WriteLn('Description: Cette procedure permet de renommer le nom d''un fichier.');
   WriteLn('Syntaxe:     RENAME(''anciennom'',''nouveaunom'')');
  End
   Else
  If HelpCommand='RMDIR'Then Begin
   WriteLn('Nom:         RMDIR');
   WriteLn('Description: Cette procedure permet de supprimer un repertoire.');
   WriteLn('Syntaxe:     RMDIR(''repertoire'')');
  End
   Else
  If HelpCommand='READKEY'Then Begin
   WriteLn('Nom:         READKEY');
   WriteLn('Description: Cette fonction permet de lire une touche au clavier.');
   WriteLn('Syntaxe:     READKEY');
  End
   Else
  If HelpCommand='RUNERROR'Then Begin
   WriteLn('Nom:         RUNERROR');
   WriteLn('Description: Cette procedure permet de quitter l''interpr‚teur de ',
                         'commande avec le code d''erreur indique.');
   WriteLn('Syntaxe:     RUNERROR(codedesortie)');
  End
   Else
  If HelpCommand='SETCBREAK'Then Begin
   WriteLn('Nom:         SETCBREAK');
   WriteLn('Description: Cette procedure permet de demander l''etat du Ctrl+Break.');
   WriteLn('Syntaxe:     SETCBREAK(TRUE|FALSE)');
  End
   Else
  If HelpCommand='SETDATE'Then Begin
   WriteLn('Nom:         SETDATE');
   WriteLn('Description: Cette procedure permet de fixer la date courante.');
   WriteLn('Syntaxe:     SETDATE(''nouvelledate'')');
  End
   Else
  If HelpCommand='SETDISK'Then Begin
   WriteLn('Nom:         SETDISK');
   WriteLn('Description: Cette procedure permet de fixer le disque courant.');
   WriteLn('Syntaxe:     SETDISK(''C'')');
  End
   Else
  If HelpCommand='SETFATTR'Then Begin
   WriteLn('Nom:         SETFATTR');
   WriteLn('Description: Cette procedure permet de changer les attributs d''un fichier.');
   WriteLn('Syntaxe:     SETFATTR(''fichier'',attribut)');
  End
   Else
  If HelpCommand='SETFTIME'Then Begin
   WriteLn('Nom:         SETFTIME');
   WriteLn('Description: Cette procedure permet de changer l''heure d''un fichier.');
   WriteLn('Syntaxe:     SETFTIME(''fichier'',''dateetheure'')');
  End
   Else
  If HelpCommand='SETTIME'Then Begin
   WriteLn('Nom:         SETTIME');
   WriteLn('Description: Cette procedure permet de fixer l''heure courante.');
   WriteLn('Syntaxe:     SETTIME(''heure'')');
  End
   Else
  If HelpCommand='SETVERIFY'Then Begin
   WriteLn('Nom:         SETVERIFY');
   WriteLn('Description: Cette procedure permet de fixer l''etat de la verification.');
   WriteLn('Syntaxe:     SETVERIFY(TRUE|FALSE)');
  End
   Else
  If HelpCommand='TEXTBACKGROUND'Then Begin
   WriteLn('Nom:         TEXTBACKGROUND');
   WriteLn('Description: Cette procedure permet de fixer la couleur d''arriere-plan.');
   WriteLn('Syntaxe:     TEXTBACKGROUND(valeur)');
  End
   Else
  If HelpCommand='TEXTCOLOR'Then Begin
   WriteLn('Nom:         TEXTCOLOR');
   WriteLn('Description: Cette procedure permet de fixer la couleur du texte.');
   WriteLn('Syntaxe:     TEXTCOLOR(valeur)');
  End
   Else
  If HelpCommand='WRITE'Then Begin
   WriteLn('Nom:         WRITE');
   WriteLn('Description: Cette proc‚dure permet d''afficher un message.');
   WriteLn('Syntaxe 1:   WRITE');
   WriteLn('Syntaxe 2:   WRITE(''message'')');
  End
   Else
  If HelpCommand='WRITELN'Then Begin
   WriteLn('Nom:         WRITELN');
   WriteLn('Description: Cette proc‚dure permet d''afficher un message avec saut de ligne.');
   WriteLn('Syntaxe 1:   WRITELN');
   WriteLn('Syntaxe 2:   WRITELN(''message'')');
  End
   Else
  WriteLn('Procedure ou fonction non reconnu !');
 End
  Else
 Begin
  For I:=Low(CommandList) to High(CommandList) do Write(PadRight(CommandList[I],16));
  WriteLn;
  WriteLn;
 End;
End;

Procedure HighVideoProc;Begin
 If ParamList<>''Then Begin
  WriteLn('Parametre non requis !');
  Exit;
 End;
 HighVideo;
End;

Procedure IfProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure ListProc;
Var
 Info:SearchRec;
 T:DateTime;
 ShowDir:String;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  ShowDir:=ExtractString(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
 End
  Else
 ShowDir:='*.*';
 FindFirst(ShowDir,AnyFile,Info);
 While DOSError=0 do Begin
  Write(PadRight(Info.Name,13));
  If Info.Attr and Directory=Directory Then Begin
   Write(PadRight('<DIR>',15));
  End
   Else
  Write(Info.Size:15);
  UnpackTime(Info.Time,T);
  WriteLn(' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2));
  FindNext(Info);
 End;
End;

Procedure LowVideoProc;Begin
 If ParamList<>''Then Begin
  WriteLn('Parametre non requis !');
  Exit;
 End;
 LowVideo;
End;

Procedure MkDirProc;
Var
 Path:String;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  Path:=ExtractString(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  MkDir(Path);
 End
  Else
 WriteLn('Parametre attendue !');
End;

Procedure MoveFileProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure NormVideoProc;Begin
 If ParamList<>''Then Begin
  WriteLn('Parametre non requis !');
  Exit;
 End;
 NormVideo;
End;

Procedure RenameProc;
Var
 F:File;
 Err:Integer;
 Source,Target:String;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  Source:=ExtractString(2);
  If Copy(ParamList,ExtractI,1)<>','Then Begin
   WriteLn(''','' attendue');
   Exit;
  End;
  Inc(ExtractI);
  Target:=ExtractString(ExtractI);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  {$I-}Assign(F,Source);
  Rename(F,Target);
  {$I+}
  Err:=IoResult;
  If Err=0Then WriteLn('1 fichier de renomme')
          Else WriteLn(GetErrorMessage(Err));
 End
  Else
 WriteLn('Parametre attendue !');
End;

Procedure RmDirProc;
Var
 Path:String;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  Path:=ExtractString(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  RmDir(Path);
 End
  Else
 WriteLn('Parametre attendue !');
End;

Procedure ReadKeyProc;Begin
 If ParamList<>''Then Begin
  WriteLn('Parametre non requis !');
  Exit;
 End;
 ReadKey;
 WriteLn;
End;

Procedure RunErrorProc;
Var
 Value:LongInt;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  Value:=ExtractNumber(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  Halt(Value);
 End
  Else
 WriteLn('Parametre requis !');
End;

Procedure SetCBreakProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure SetDateProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure SetDiskProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure SetEnvProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure SetFAttrProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure SetFTimeProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure SetTimeProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure SetVerifyProc;Begin
 WriteLn('Cette procedure n''est pas mise en oeuvre');
End;

Procedure TextBackgroundProc;
Var
 Value:LongInt;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  Value:=ExtractNumber(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  TextBackground(Value);
 End
  Else
 WriteLn('Valeur attendue');
End;

Procedure TextColorProc;
Var
 Value:LongInt;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  Value:=ExtractNumber(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  TextColor(Value);
 End
  Else
 WriteLn('Valeur attendue');
End;

Procedure WriteProc;Var
 Str:String;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  Str:=ExtractString(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  Write(Str);
 End
  Else
 Write(Str);
End;

Procedure WriteLnProc;
Var
 Str:String;
Begin
 If ParamList<>''Then Begin
  If Copy(ParamList,1,1)<>'('Then Begin
   WriteLn('''('' attendue.');
   Exit;
  End;
  Str:=ExtractString(2);
  If Copy(ParamList,ExtractI,1)<>')'Then Begin
   WriteLn(''')'' attendue.');
   Exit;
  End;
  WriteLn(Str);
 End
  Else
 WriteLn(Str);
End;

BEGIN
 Echo:=True;Terminated:=False;
 HomeMessage;
 Repeat
  ShowPrompt;
  ReadLn(CmdStr);
  ExtractProcedure;
  CommandFound:=False;
  For J:=Low(CommandList) to High(CommandList) do Begin
   If CurrCommand=CommandList[J]Then Begin
    Case(J)of
     0:ChDirProc;
     1:ClrScrProc;
     2:CopyFileProc;
     3:MkDirProc;
     4:DelayProc;
     5:DiskFreeProc;
     6:DiskSizeProc;
     7:DiskTypeProc;
     8:EraseProc;
     9:ExecProc;
     10:ExitProc;
     11:FExpandProc;
     12:FileSizeProc;
     13:FindFirstProc;
     14:FindNextProc;
     15:ForProc;
     16:GetCBreakProc;
     17:GetDateProc;
     18:GetDirProc;
     19:GetDiskProc;
     20:GetEnvProc;
     21:GetFAttrProc;
     22:GetFTimeProc;
     23:GetTimeProc;
     24:GetVerifyProc;
     25:GetVersionProc;
     26:GetVolumeProc;
     27:GotoProc;
     28:GotoXYProc;
     29:HaltProc;
     30:HelpProc;
     31:HighVideoProc;
     32:IfProc;
     33:ListProc;
     34:LowVideoProc;
     35:MkDirProc;
     36:MoveFileProc;
     37:NormVideoProc;
     38:RmDirProc;
     39:RenameProc;
     40:RmDirProc;
     41:ReadKeyProc;
     42:RunErrorProc;
     43:SetCBreakProc;
     44:SetDateProc;
     45:SetDiskProc;
     46:SetEnvProc;
     47:SetFAttrProc;
     48:SetFTimeProc;
     49:SetTimeProc;
     50:SetVerifyProc;
     51:TextBackgroundProc;
     52:TextColorProc;
     53:WriteProc;
     54:WriteLnProc;
    End;
    If J<=High(CommandList)Then Begin
     CommandFound:=True;
     WriteLn;
     Break;
    End;
   End;
  End;
  If Not(CommandFound)Then Begin
   TextColor(LightRed);
   WriteLn('Procedure ou fonction non reconnu');
   NormVideo;
  End;
 Until Terminated;
END.
