{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program AMIGADOS;

Uses Crt,DOS;

Const
 CommandList:Array[0..51]of String[20]=(
  'ADDBUFFERS','ALINK','ASSEM','ASSIGN','BINDDRIVERS','BREAK',
  'CD','CHANGETASKPRI','COPY','DATE','DELETE','DIR',
  'DISKCHANGE','DISKCOPY','DISKDOCTOR','DOWNLOAD','ECHO',
  'ED','EDIT','ENDCLI','EXECUTE','FAILAT','FAULT','FILENOTE',
  'FORMAT','IF','INFO','INSTALL','JOIN','LAB','LIST','MAKEDIR',
  'MOUNT','NEWCLI','PATH','PROMPT','PROTECT','QUIT','READ',
  'RELABEL','RENAME','RUN','SEARCH','SETDATE','SETMAP','SKIP',
  'SORT','STACK','STATUS','TYPE','WAIT','WHY'
 );

Var
 Echo:Boolean;
 CommandFound,Terminated:Boolean;
 CmdStr:String;
 CurrCommand,ParamList:String;
 I,J:Byte;

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

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Procedure ChangeChar(Var Str:String;OldChar,NewChar:Char);
Var
 I:Byte;
Begin
 For I:=1 to Length(Str)do Begin
  If Str[I]=OldChar Then Str[I]:=NewChar;
 End;
End;

Function GetCurrentDisk:Char;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 GetCurrentDisk:=CurrentDir[1];
End;

Function GetCurrentDiskAmiga:String;
Var
 Tmp:String;
Begin
 Case GetCurrentDisk of
  'A':GetCurrentDiskAmiga:='DF0:';
  'B':GetCurrentDiskAmiga:='DF1:';
  Else Begin
   Str((Ord(GetCurrentDisk)-Ord('A')-2),Tmp);
   GetCurrentDiskAmiga:='HD'+Tmp+':';
  End;
 End;
End;

Function Path2Drive(Path:String):Char;Begin
 Path:=FExpand(Path);
 Path2Drive:=Path[1];
End;

Function Path2Ext(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2Ext:=E;
End;

Function GetDiskLabel(Dsk:Byte):String;
Var
 Info:SearchRec;
 CurrentDir:String;
Begin
 If Dsk=0Then GetDir(0,CurrentDir)
         Else CurrentDir:=Char(Dsk+64);
 FindFirst(CurrentDir[1]+':\*.*',VolumeID,Info);
 While DosError=0do Begin
  If(Info.Attr = VolumeID)Then Begin
   GetDiskLabel:=Info.Name;
   Exit;
  End;
  FindNext(Info);
 End;
 GetDiskLabel:=''
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

Procedure ExtractCommand;
Var
 I:Byte;
Begin
 For I:=1 to Length(CmdStr)do Begin
  If Not(CmdStr[I]in['A'..'Z','a'..'z','_','-','0'..'9'])Then Begin
   CurrCommand:=StrToUpper(Copy(CmdStr,1,I-1));
   ParamList:=TrimL(Copy(CmdStr,I,255));
   Exit;
  End;
 End;
 CurrCommand:=StrToUpper(CmdStr);
 ParamList:='';
End;

Function ExtractParam(Index:Byte):String;
Var
 Count:Word;
 LocalIndex:Word;
 l:Byte;
 Temp:String;
Begin
 Temp:='';Count:=1;LocalIndex:=1;l:=0;
 While Count<=Length(ParamList)do Begin
  If Not(ParamList[Count] in [' ',#9])then Begin
   If LocalIndex=Index Then Begin
    While (Count<=Length(ParamList)) and (Not(ParamList[count] in[' ',#9])) and (l < 256) do Begin
     Temp:=Temp+ParamList[count];
     Inc(l);
     Inc(Count);
    end;
    Temp[0]:=Char(l);
    ExtractParam:=Temp;
    Exit;
   End;
   While (Count<=Length(ParamList)) and (Not(ParamList[count] in [' ',#9])) do Inc(Count);
   Inc(LocalIndex);
  End;
  If Count>=Length(ParamList)Then Break;
  Inc(Count);
 End;
 ExtractParam:=Temp;
End;

Procedure HomeMessage;Begin
 TextColor(0);
 TextBackground(7);
 WriteLn;
 WriteLn('AmigaShell/AmigaDOS');
 WriteLn;
End;

Procedure ShowPrompt;
Const Week:Array[0..6]of String[3]=('Dim','Lun','Mar','Mer','Jeu','Ven','Sam');
      Mon:Array[1..12]of String[3]=('Jan','Fev','Mar','Avr','Mai','Jui',
			            'Jul','Aou','Sep','Oct','Nov','Dec');
Var
 SP,CurrentDir:String;
 I:Byte;
 Year,Month,Day,DayOfWeek,Hour,Min,Sec,Sec100:Word;
Begin
 If Not(Echo)Then Exit;
 GetDir(0,CurrentDir);
 SP:=GetEnv('PROMPT');
 If SP=''Then SP:='$P$G';
 I:=1;
 While I<=Length(SP)do Begin
  If SP[I]='$'Then Begin
   Inc(I);
   Case SP[I] of
       'D': Begin
	     GetDate(Year,Month,Day,DayOfWeek);
	     Write(Week[DayOfWeek],'  ',Mon[Month],Day,',',Year);
	    End;
       'T': Begin
	     GetTime(Hour,Min,Sec,Sec100);
	     Write(Hour,':',Min,':',Sec);
	    End;
       'B' : Write('|');
   'e','E' : Write(#27);
   'g','G' : Write('>');
       'N' : Write(GetCurrentDiskAmiga);
   'p','P' : Begin
     GetDir(0,CurrentDir);
     If CurrentDir[2]=':'Then Begin
      CurrentDir:=Copy(CurrentDir,3,255);
     End;
     CurrentDir:=GetCurrentDiskAmiga+CurrentDir;
     ChangeChar(CurrentDir,'\','/');
     Write(CurrentDir);
   End;
   '-','S' : Write(' ');
       'V' : Write(Lo(DosVersion),'.',Hi(DosVersion));
   '_','Z' : Write(#13#10);
       'z' : Write('?');
   End;
  End
   Else
  Write(SP[I]);
  Inc(I);
 End;
End;

Procedure InvalidParam(P:Byte);Begin
 WriteLn('Le parametre suivant est invalide : ',ExtractParam(P));
End;

Procedure ADDBUFFERSCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ALINKCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ASSEMCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ASSIGNCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BINDDRIVERSCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BREAKCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CDCommand;
Var
 Error:Word;
 FirstParam,Dir:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('CD   Cette commande permet de fixer ou de demander le repertoire courant.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('CD [/?] chemin');
  WriteLn;
  WriteLn('  /?     Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' chemin  Ce parametre permet d''indiquer le chemin du repertoire.');
 End
  Else
 If Length(FirstParam)>0Then Begin
  {$I-} ChDir(FirstParam);{$I+}
  Error:=IoResult;
  If Error<>0Then WriteLn(GetErrorMessage(Error));
 End
  Else
 Begin
  GetDir(0,Dir);
  WriteLn(Dir);
 End;
End;

Procedure CHANGETASKPRICommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure COPYCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DATECommand;
Const
 DOW:Array[0..6]of String[10]=(
  'Dimanche','Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi'
 );
 Mon:Array[1..12]of String[3]=('Jan','Fev','Mar','Avr','Mai','Jui',
                               'Jul','Aou','Sep','Oct','Nov','Dec');
Var
 FirstParam:String;
 Year,Month,Day,DayOfWeek:Word;
 Hour,Minute,Second,CentSec:Word;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('DATE   Cette commande permet de fixer ou de demander la date du systeme d''exploitation');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('DATE [/?]');
  WriteLn;
  WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 Begin
  GetDate(Year,Month,Day,DayOfWeek);
  Write(DOW[DayOfWeek],' ');
  Write(Day:2,'-',Mon[Month],'-',Copy(PadZeroLeft(Year,4),3,2),' ');
  GetTime(Hour,Minute,Second,CentSec);
  WriteLn(Hour:2,':',PadZeroLeft(Minute,2),':',PadZeroLeft(Second,2));
 End;
End;

Procedure DELETECommand;
Var
 P:Byte;
 Err:Word;
 F:File;
 CurrParam:String;
Begin
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    WriteLn('ParamŠtre requis');
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   WriteLn('DELETE   Cette commande permet d''effectuer la suppression de fichier sur un unite de disque.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('DELETE [/?] fichier');
   WriteLn;
   WriteLn('    /?    Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn(' fichier  Ce parametre permet d''indiquer le nom du fichier a supprimer.');
   Exit;
  End;
  {$I-}Assign(F,CurrParam);
  Erase(F);
  {$I+}
  Err:=IoResult;
  If Err=0Then WriteLn('1 fichier de supprime')
          Else WriteLn(GetErrorMessage(Err));
  If P>9Then Break;
 Until CurrParam='';
End;

Procedure DirCommand;
Var
 P:Byte;
 Info:SearchRec;
 T:DateTime;
 CurrParam,ShowDir:String;
Begin
 P:=0;
 ShowDir:='*.*';
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If Length(CurrParam)=0Then Break;
  If CurrParam='/?'Then Begin
   WriteLn('DIR   Cette commande permet d''afficher le contenu d''un repertoire dans l''unite de disque.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('DIR [/?] [nom]');
   WriteLn;
   WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
   Exit;
  End
   Else
  ShowDir:=CurrParam;
  If P>99Then Break;
 Until CurrParam='';
 P:=0;
 FindFirst(ShowDir,AnyFile,Info);
 While DOSError=0 do Begin
  If(Info.Attr and Directory=Directory)Then Begin
   If(Info.Name<>'..')and(Info.Name<>'.')Then Write(' ':5,PadRight(Info.Name+' (dir)',35));
  End
   Else
  Write('  ',PadRight(Info.Name,38));
  FindNext(Info);
 End;
End;

Procedure DISKCHANGECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DISKCOPYCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DISKDOCTORCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DOWNLOADCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure EchoCommand;
Var
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('ECHO   Cette commande permet d''activer ou desactiver le prompt de commande ',
          'ou d''afficher un message sur le console du systeme d''exploitation.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('ECHO [/?] message');
  WriteLn;
  WriteLn('       /?  Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn('  message  Ce parametre permet d''afficher un message');
 End
  Else
 If ParamList='.'Then WriteLn
                 Else WriteLn(ParamList);
End;

Procedure EDCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure EDITCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ENDCLICommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure EXECUTECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure FAILATCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure FAULTCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure FILENOTECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure FORMATCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure IFCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure INFOCommand;
Var
 I:Char;
 Dsk:Byte;
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('INFO   Cette commande permet de demander des informations sur ',
                  'l''etat du systeme d''exploitation.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('INFO [/?]');
  WriteLn;
  WriteLn('       /?  Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 Begin
  WriteLn;
  WriteLn('Unite    Taille   Utilise     Libre Plein  Erreurs Etat             Nom');
  For I:='A' to 'Z' do Begin
   Dsk:=Ord(I)-Ord('A');
   If DiskSize(Dsk+1)<>-1Then Begin
    Case I of
     'A':Write('DF0:');
     'B':Write('DF1:');
     Else Begin
      Write('DH',Dsk-2,':');
      If Dsk<12Then Write(' ');
     End;
    End;
    If DiskSize(Dsk+1)>1073741824Then Write(DiskSize(Dsk+1) shr 30:9,'G')Else
    If DiskSize(Dsk+1)>1048576Then Write(DiskSize(Dsk+1) shr 20:9,'M') Else
    If DiskSize(Dsk+1)>1024Then Write(DiskSize(Dsk+1) shr 10:9,'K')
                Else Write(DiskSize(Dsk+1):10);
    If(DiskSize(Dsk+1)-DiskFree(Dsk+1)>1073741824)Then Write((DiskSize(Dsk+1)-DiskFree(Dsk+1)) shr 30:10) Else
    If(DiskSize(Dsk+1)-DiskFree(Dsk+1)>1048576)Then Write((DiskSize(Dsk+1)-DiskFree(Dsk+1))shr 20:10)
                Else Write((DiskSize(Dsk+1)-DiskFree(Dsk+1)) shr 10:10);
    If DiskFree(Dsk+1)>1073741824Then Write(DiskFree(Dsk+1) shr 30:10)Else
    If DiskFree(Dsk+1)>1048576Then Write(DiskFree(Dsk+1) shr 20:10) Else
    If DiskFree(Dsk+1)>1024Then Write(DiskFree(Dsk+1) shr 10:10)
                Else Write(DiskFree(Dsk+1):10);
    Write(Trunc(((DiskSize(Dsk+1)-DiskFree(Dsk+1))/DiskSize(Dsk+1))*100):6,'%');
    Write('  ',0,' ':6);
    Write('Lecture/Ecriture ');
    Write(GetDiskLabel(Dsk+1));
    WriteLn;
   End;
  End;
 End;
End;

Procedure INSTALLCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure JOINCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LABCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LISTCommand;
Const
 Mon:Array[1..12]of String[3]=('Jan','Fev','Mar','Avr','Mai','Jui',
                               'Jul','Aou','Sep','Oct','Nov','Dec');
Var
 Option:Set of (QUICK);
 I:Integer;
 Info:SearchRec;
 Path:String;
 T:DateTime;
 NumFiles,NumDirectories:LongInt;
Begin
 If(ExtractParam(1)='--help')or(ExtractParam(1)='-h')Then Begin
  WriteLn('LIST : Cette commande permet d''afficher les fichiers d''un repertoire.');
  WriteLn;
  WriteLn('Syntaxe : LIST [-l] [-s] [-t] [<repertoire>]');
 End
  Else
 Begin
  NumFiles:=0;
  NumDirectories:=0;
  Option:=[];
  Path:='*.*';
  I:=1;
  While I<10 do Begin
   If ExtractParam(I)=''Then Break Else
   If StrToUpper(ExtractParam(I))='QUICK'Then Include(Option,Quick)
                          Else Path:=ExtractParam(I);
   Inc(I);
  End;
  FindFirst(Path,AnyFile,Info);
  While DosError=0 do Begin
   If Not((Info.Name='.')or(Info.Name='..'))Then Begin
    If(Info.Attr and Directory=Directory)Then Inc(NumDirectories)
                                         Else Inc(NumFiles);
    Write(PadRight(Info.Name,40));
    If Not((Quick)in(Option))Then Begin
     If(Info.Attr and Directory=Directory)Then Begin
      Write('Dir':10,' ');
     End
      Else
     Write((Info.Size shr 9)+Byte((Info.Size and$1FF)>0):10,' ');
     Write('----r');
     If(Info.Attr and ReadOnly=ReadOnly)Then Write('-')
                                        Else Write('w');
     If Path2Ext(Info.Name)='.EXE'Then Write('e')
                                  Else Write('-');
     If(Info.Attr and Directory=Directory)Then Write('d')
                                          Else Write('-');
     Write(' ');
     UnpackTime(Info.Time,T);
     Write(' ',T.Day:2,'-',Mon[T.Month],'-',Copy(PadZeroLeft(T.Year,2),3,2));
     Write(' ',T.Hour:2,':',PadZeroLeft(T.Min,2),' ');
    End;
    WriteLn;
   End;
   FindNext(Info);
  End;
  WriteLn(NumFiles,' fichiers - ',NumDirectories,' repertoires');
 End;
End;

Procedure MAKEDIRCommand;
Var
 P:Byte;
 Err:Word;
 CurrParam:String;
Begin
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    WriteLn('ParamŠtre requis');
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   WriteLn('MAKEDIR   Cette commande permet de creer un repertoire.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('MAKEDIR [/?] nomrepertoire');
   WriteLn;
   WriteLn('  nomrepertoire   Ce parametre permet d''indiquer le nom du repertoire');
   WriteLn('            /?    Ce parametre permet d''afficher l''aide sur cette commande');
   Exit;
  End;
  {$I-}MkDir(CurrParam);{$I+}
  Err:=IoResult;
  If Err<>0Then WriteLn(GetErrorMessage(Err));
  If P>9Then Break;
 Until CurrParam='';
End;

Procedure MOUNTCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure NEWCLICommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PATHCommand;
Var
 I:Integer;
 P:Byte;
 PATH,TPath,CurrParam:String;
Begin
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If Length(CurrParam)=0Then Break;
  If CurrParam='/?'Then Begin
   WriteLn('PATH  Cette commande permet de ger les chemins d''acces par defaut.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('PATH [/?] [SHOW]');
   WriteLn;
   WriteLn('Parametres');
   WriteLn;
   WriteLn(' SHOW    Affiche la liste des repertoires a rechercher');
  End
   Else
  If StrToUpper(CurrParam)='SHOW'Then Begin
   PATH:=GetEnv('PATH');
   TPath:='';
   For I:=1 to Length(PATH)do Begin
    If PATH[I]=';'Then Begin
     WriteLn(TPath);
     TPath:='';
    End
     Else
    TPath:=TPath+Path[I];
   End;
   WriteLn(TPath);
  End;
  If P>99Then Break;
 Until CurrParam='';
End;

Procedure PROMPTCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PROTECTCommand;
Var
 CurrAttr:Word;
 Flags:Set Of (ReadFlag,WriteFlag,DeleteFlag,ExecuteFlag);
 P,I:Byte;
 InFlags:Boolean;
 F:File;
 FileName,CurrParam:String;
Begin
 Flags:=[];
 P:=0;
 InFlags:=False;
 FileName:='';
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If Length(CurrParam)=0Then Break;
  If CurrParam='/?'Then Begin
   WriteLn('PROTECT  Cette commande permet de fixer les protection de mode d''acces d''un fichier.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('PROTECT [/?] nomdefichier [FLAGS etat]');
  End
   Else
  If(InFlags)Then Begin
   For I:=1 to Length(CurrParam)do Begin
    Case UpCase(CurrParam[I])of
     'D':Include(Flags,DeleteFlag);
     'E':Include(Flags,ExecuteFlag);
     'R':Include(Flags,ReadFlag);
     'W':Include(Flags,WriteFlag);
    End;
   End;
   InFlags:=False;
  End
   Else
  If StrToUpper(CurrParam)='FLAGS'Then InFlags:=True
                                  Else FileName:=CurrParam;
  If P>99Then Break;
 Until CurrParam='';
 If FileName<>''Then Begin
  Assign(F,FileName);
  GetFAttr(F,CurrAttr);
  If(ReadFlag in Flags)Then CurrAttr:=CurrAttr or ReadOnly
                       Else CurrAttr:=CurrAttr and Not(ReadOnly);
  SetFAttr(F,CurrAttr);
 End
  Else
 WriteLn('Nom de fichier requis !');
End;

Procedure QUITCommand;
Var
 FirstParam:String;
 N,Err:Integer;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('QUIT  Cette commande permet de quitter l''interpreteur de commande.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('QUIT [/?] [CodeSortie]');
  WriteLn;
  WriteLn(' CodeSortie   Ce parametre permet d''indiquer le code de sortie a ',
                         'retourner a l''application parent');
  WriteLn('        /?    Ce parametre permet d''afficher l''aide sur cette commande');

 End
  Else
 If Length(FirstParam)>0Then Begin
  Val(FirstParam,N,Err);
  Halt(N);
  Terminated:=True;
 End
  Else
 Terminated:=True;
End;

Procedure READCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure RELABELCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure RENAMECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure RUNCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SEARCHCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SETDATECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SETMAPCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SKIPCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SORTCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure STACKCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure STATUSCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TYPECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure WAITCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure WHYCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UnknownCommand;Begin
 Exec(CurrCommand,ParamList);
 If DosError<>0Then Begin
  WriteLn('Commande ou nom de fichier non reconnu');
 End;
 WriteLn;
End;

BEGIN
 Echo:=True;Terminated:=False;
 HomeMessage;
 Repeat
  ShowPrompt;
  ReadLn(CmdStr);
  ExtractCommand;
  CommandFound:=False;
  For J:=Low(CommandList) to High(CommandList) do Begin
   If CurrCommand=CommandList[J]Then Begin
    Case(J)of
      0:ADDBUFFERSCommand;
      1:ALINKCommand;
      2:ASSEMCommand;
      3:ASSIGNCommand;
      4:BINDDRIVERSCommand;
      5:BREAKCommand;
      6:CDCommand;
      7:CHANGETASKPRICommand;
      8:COPYCommand;
      9:DATECommand;
      10:DELETECommand;
      11:DIRCommand;
      12:DISKCHANGECommand;
      13:DISKCOPYCommand;
      14:DISKDOCTORCommand;
      15:DOWNLOADCommand;
      16:ECHOCommand;
      17:EDCommand;
      18:EDITCommand;
      19:ENDCLICommand;
      20:EXECUTECommand;
      21:FAILATCommand;
      22:FAULTCommand;
      23:FILENOTECommand;
      24:FORMATCommand;
      25:IFCommand;
      26:INFOCommand;
      27:INSTALLCommand;
      28:JOINCommand;
      29:LABCommand;
      30:LISTCommand;
      31:MAKEDIRCommand;
      32:MOUNTCommand;
      33:NEWCLICommand;
      34:PATHCommand;
      35:PROMPTCommand;
      36:PROTECTCommand;
      37:QUITCommand;
      38:READCommand;
      39:RELABELCommand;
      40:RENAMECommand;
      41:RUNCommand;
      42:SEARCHCommand;
      43:SETDATECommand;
      44:SETMAPCommand;
      45:SKIPCommand;
      46:SORTCommand;
      47:STACKCommand;
      48:STATUSCommand;
      49:TYPECommand;
      50:WAITCommand;
      51:WHYCommand;
    End;
    If J<=High(CommandList)Then Begin
     CommandFound:=True;
     WriteLn;
     Break;
    End;
   End;
  End;
  If Not(CommandFound)Then Begin
   If CmdStr='?'Then Begin
    For I:=Low(CommandList) to High(CommandList) do Write(PadRight(CommandList[I],10));
    WriteLn;
    WriteLn;
   End
    Else
   UnknownCommand;
  End;
 Until Terminated;
END.
