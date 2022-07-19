{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program MSXDOS;

{$M 4096,0,0}

Uses Crt,DOS;

Const
 CommandList:Array[0..48]of String[8]=(
  'ASSIGN','ATDIR','ATTRIB','BASIC','BEEP','BOOT','BUFFERS',
  'CD','CHDIR','CHKDSK','CLS','COMMAND','COMMAND2',
  'CONCAT','COPY','DATE','DEL','DIR','DISKCOPY','ECHO',
  'ERA','ERASE','EXIT','FIXDISK','FORMAT','HELP',
  'MD','MKDIR','MODE','MOVE','MVDIR','PATH','PAUSE',
  'RAMDISK','RD','REM','RENAME','RESET','RMDIR','RNDIR',
  'SET','TIME','TYPE','UNDEL','VER','VERIFY','VOL','XCOPY',
  'XDIR'
 );

Var
 Prompt:Boolean;
 CurrWidth:Byte;
 AttrAdd,AttrRemove:Word;
 SubDirectory:Boolean;
 InCmd:Byte;
 Option:(optNone,optCommand);
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

Procedure ChangeChar(Var Str:String;OldChar,NewChar:Char);
Var
 I:Byte;
Begin
 For I:=1 to Length(Str)do Begin
  If Str[I]=OldChar Then Str[I]:=NewChar;
 End;
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

Function GetCurrentDisk:Char;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 GetCurrentDisk:=CurrentDir[1];
End;

Function FileExist(Name:String):Boolean;
Var
 Rec:SearchRec;
Begin
 FindFirst(Name,AnyFile,Rec);
 FileExist:=DosError=0;
End;

Function Path2Drive(Path:String):Char;Begin
 Path:=FExpand(Path);
 Path2Drive:=Path[1];
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

Procedure SetAttribut(Var F:File);
Var
 CurrAttr:Word;
Begin
 GetFAttr(F,CurrAttr);
 If AttrRemove and ReadOnly=ReadOnly Then CurrAttr:=CurrAttr and Not ReadOnly;
 If AttrRemove and Archive=Archive Then CurrAttr:=CurrAttr and Not Archive;
 If AttrRemove and Hidden=Hidden Then CurrAttr:=CurrAttr and Not Hidden;
 If AttrRemove and SysFile=SysFile Then CurrAttr:=CurrAttr and Not SysFile;

 If AttrAdd and ReadOnly=ReadOnly Then CurrAttr:=CurrAttr or ReadOnly;
 If AttrAdd and Archive=Archive Then CurrAttr:=CurrAttr or Archive;
 If AttrAdd and Hidden=Hidden Then CurrAttr:=CurrAttr or Hidden;
 If AttrAdd and SysFile=SysFile THen CurrAttr:=CurrAttr or SysFile;
 SetFAttr(F,CurrAttr);
End;

Procedure SetAttributFiles(FileSpec:String);
Var
 Info:SearchRec;
 CurrFile:File;
 Found:Boolean;
Begin
 FindFirst(FileSpec,AnyFile,Info);
 Found:=False;
 While DOSError=0 do Begin
  Found:=True;
  If Info.Attr and Directory=Directory Then Begin
   {If(SubDirectory)Then SetAttributFiles(Info.Name+'\*.*');}
  End
   Else
  Begin
   Assign(CurrFile,Info.Name);
   SetAttribut(CurrFile);
  End;
  FindNext(Info);
 End;
 If Not Found Then WriteLn('Aucun resultat trouve');
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
  15:GetErrorMessage:='NumÇro de disque invalide';
  16:GetErrorMessage:='Impossible de supprimer le rÇpertoire';
  17:GetErrorMessage:='Impossible de renommer sur plusieurs volumes';
  100:GetErrorMessage:='Erreur de lecture Ö partir du disque';
  101:GetErrorMessage:='Erreur d''ecriture sur le disque';
  102:GetErrorMessage:='Fichier non attribue';
  103:GetErrorMessage:='Le fichier n''est pas ouvert';
  104:GetErrorMessage:='Le fichier n''est pas ouvert Ö l''entree';
  105:GetErrorMessage:='Le fichier n''est pas ouvert Ö la sortie';
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

Procedure SetDefaultColor;Begin
 TextBackground(1);
 TextColor($F{$IFDEF FPC}+BLINK{$ENDIF});
End;

Procedure HomeMessage;Begin
 CurrWidth:=29;
 TextMode(CO40);
 SetDefaultColor;
 Window(3+1,1,3+29,25);
 ClrScr;
 WriteLn;
 WriteLn('MSX-DOS version 0.0');
 WriteLn('Tous droits reserves gladir.com');
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
 JapanMode:Boolean;
Begin
 If Not(Echo)Then Exit;
 GetDir(0,CurrentDir);
 If(Prompt)Then SP:='$P$G'
           Else SP:='$N$G';
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
       'N' : Write(GetCurrentDisk);
   'p','P' : Begin
     GetDir(0,CurrentDir);
     ChangeChar(CurrentDir,'/','\');
     JapanMode:=False;
     If(JapanMode)Then ChangeChar(CurrentDir,'\',{$IFDEF FPC}#165{$ELSE}#157{$ENDIF});
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

Procedure AssignCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ATDIRCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure AttribCommand;
Var
 P:Integer;
 Info:SearchRec;
 IsAttrSetting:Array[Byte]of Boolean;
 CurrParam:String;
Begin
 CurrParam:=ExtractParam(1);
 If ExtractParam(1)='/?'Then Begin
  WriteLn('ATTRIB - Cette commande permet de demander ou changer l''attribut d''un fichier');
  WriteLn;
  WriteLn('Syntaxe : ATTRIB nomdufichier [+R|-R] [+A|-A] [+S|-S] [+H|-H]');
 End
  Else
 If CurrParam=''Then Begin
  FindFirst('*.*',AnyFile and Not Directory,Info);
  While DOSError=0 do Begin
   If Info.Attr and ReadOnly=ReadOnly Then Write('r') Else Write('-');
   If Info.Attr and SysFile=SysFile Then Write('s') Else Write('-');
   If Info.Attr and Archive=Archive Then Write('a') Else Write('-');
   If Info.Attr and Hidden=Hidden Then Write('h') Else Write('-');
   If Info.Attr and VolumeID=VolumeID Then Write('v') Else Write('-');
   If Info.Attr and Directory=Directory Then Write('d') Else Write('-');
   Write(' ');
   WriteLn(Info.Name);
   FindNext(Info);
  End;
 End
  Else
 Begin
  FillChar(IsAttrSetting,SizeOf(IsAttrSetting),0);
  AttrAdd:=0;
  AttrRemove:=0;
  SubDirectory:=False;
  P:=1;
  Repeat
   If StrToUpper(CurrParam)='+R'Then Begin
    AttrAdd:=ReadOnly;
    IsAttrSetting[P]:=True;
   End
    Else
   If StrToUpper(CurrParam)='-R'Then Begin
    AttrRemove:=ReadOnly;
    IsAttrSetting[P]:=True;
   End
    Else
   If StrToUpper(CurrParam)='+H'Then Begin
    AttrAdd:=Hidden;
    IsAttrSetting[P]:=True;
   End
    Else
   If StrToUpper(CurrParam)='-H'Then Begin
    AttrRemove:=Hidden;
    IsAttrSetting[P]:=True;
   End
    Else
   If StrToUpper(CurrParam)='+A'Then Begin
    AttrAdd:=Archive;
    IsAttrSetting[P]:=True;
   End
    Else
   If StrToUpper(CurrParam)='-A'Then Begin
    AttrRemove:=Archive;
    IsAttrSetting[P]:=True;
   End
    Else
   If StrToUpper(CurrParam)='+S'Then Begin
    AttrAdd:=SysFile;
    IsAttrSetting[P]:=True;
   End
    Else
   If StrToUpper(CurrParam)='-S'Then Begin
    AttrRemove:=SysFile;
    IsAttrSetting[P]:=True;
   End
    Else
   If StrToUpper(CurrParam)='/S'Then Begin
    SubDirectory:=True;
    IsAttrSetting[P]:=True;
   End;
   Inc(P);
   CurrParam:=ExtractParam(P);
  Until CurrParam='';
  P:=1;
  CurrParam:=ExtractParam(1);
  Repeat
   If Not IsAttrSetting[P]Then Begin
    SetAttributFiles(ExtractParam(P));
   End;
   If P=255Then Exit;
   Inc(P);
   CurrParam:=ExtractParam(P);
  Until CurrParam='';
 End;
End;

Procedure BasicCommand;Begin
 Exec('MSXBASIC.EXE',ParamList);
 If DosError<>0 Then Exec('BASIC.EXE',ParamList);
 Case(CurrWidth)of
  29:Begin
  TextMode(CO40);
  Window(3+1,1,3+29,25);
  End;
  40:TextMode(CO40);
  80:TextMode(CO80);
 End;
 SetDefaultColor;
 ClrScr;
End;

Procedure BeepCommand;
Var
 FirstParam:String;
 X:Boolean;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('BEEP   Cette commande permet d''emettre un bip sonore.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('BEEP [/?]');
  WriteLn;
  WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 Begin
  Sound(1550);
  Delay(182);
  NoSound;
 End;
End;

Procedure BootCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BuffersCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ChDirCommand;
Var
 Error:Word;
 FirstParam,Dir:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('CHDIR   Cette commande permet de fixer ou de demander le repertoire courant.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('CD [/?] chemin');
  WriteLn('CHDIR [/?] chemin');
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

Procedure ChkDskCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CLSCommand;
Var
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('CLS   Cette commande permet d''effacer l''ecran.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('CLS [/?]');
  WriteLn;
  WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 Begin
  SetDefaultColor;
  ClrScr;
 End;
End;

Procedure COMMANDCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure COMMAND2Command;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CONCATCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CopyCommand;
Var
 P:Byte;
 ShowProgression:Boolean;
 F:File;
 CurrParam,Source,Target:String;
Begin
 P:=0;
 ShowProgression:=False;
 Source:='';
 Target:='';
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    WriteLn('Paramätre requis');
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   WriteLn('COPY   Cette commande permet d''effacer la copie de fichier vers un autre emplacement.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('COPY [/?] [/P] source destination');
   WriteLn;
   WriteLn('    /?       Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('    /P       Ce parametre permet d''afficher la progression de la copie');
   WriteLn('source       Ce parametre permet d''indiquer le fichier source');
   WriteLn('destination  Ce parametre permet d''indiquer le fichier destination');
   Exit;
  End
   Else
  If(CurrParam='/P')or(CurrParam='/p')Then ShowProgression:=True
   Else
  If CurrParam<>''Then
  Begin
   If Source=''Then Source:=CurrParam
               Else Target:=CurrParam;
  End;
  If P>9Then Break;
 Until CurrParam='';
 If(Source='')or(Target='')Then Begin
  WriteLn('La source et la destination sont requises');
 End
  Else
 Begin
  If CopyFile(Source,Target,ShowProgression)Then WriteLn('1 fichier copie')
                                            Else WriteLn('Echec de copie de fichier');
 End;
End;

Procedure DelCommand;
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
    WriteLn('Paramätre requis');
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   WriteLn('DEL   Cette commande permet d''effectuer la suppression de fichier sur un unite de disque.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('DEL [/?] fichier');
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
 Option:Set of (Pause,Subdirectory,Lower,Brief,Description);
 Column:Set Of (Double,Width);
 TotalNumFiles,TotalSize:LongInt;
 CurrParam,ShowDir,CurrLabel:String;
 CurrDrive:Char;
Begin
 Option:=[];
 Column:=[];
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
   WriteLn('DIR [/?] [/2|/W] [/B] [/P] [chemin]');
   WriteLn;
   WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn(' /2   Ce parametre permet d''afficher sur 2 colonnes');
   WriteLn(' /B   Ce parametre enleve l''entete et les details de la fin');
   WriteLN(' /P   Ce parametre affiche une pause apres l''affichage d''une page pleine');
   WriteLn(' /W   Ce parametre affiche seulement les fichiers sur plein de colonnes');
   Exit;
  End
   Else
  If CurrParam='/2'Then Include(Column,Double) Else
  If(CurrParam='/B')or(CurrParam='/b')Then Include(Option,Brief) Else
  If(CurrParam='/L')or(CurrParam='/l')Then Include(Option,Lower) Else
  If(CurrParam='/P')or(CurrParam='/p')Then Include(Option,Pause) Else
  If(CurrParam='/W')or(CurrParam='/w')Then Include(Column,Width)
                   Else ShowDir:=CurrParam;
  If P>99Then Break;
 Until CurrParam='';
 CurrDrive:=Path2Drive(ShowDir);
 CurrLabel:=GetDiskLabel(Byte(CurrDrive)-64);
 P:=0;
 FindFirst(ShowDir,AnyFile,Info);
 If(Width)in(Column)Then While DOSError=0 do Begin
  Write(PadRight(Info.Name,16));
  FindNext(Info);
  If(Pause)in(Option)Then Begin
   Inc(P);
   If P=Hi(WindMax)Then Begin
    Write('Presse une touche pour continuer...');
    If ReadKey=#27Then Exit;
    WriteLn;
    P:=0;
   End;
  End;
 End
  Else
 If(Double)in(Column)Then While DOSError=0 do Begin
  Write(PadRight(Info.Name,13));
  If Info.Attr and Directory=Directory Then Begin
   Write(PadRight('<DIR>',9));
  End
   Else
  Write(Info.Size:9);
  UnpackTime(Info.Time,T);
  Write(' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2),' ');
  FindNext(Info);
  If(Pause)in(Option)Then Begin
   Inc(P);
   If P=Hi(WindMax)Then Begin
    Write('Presse une touche pour continuer...');
    If ReadKey=#27Then Exit;
    WriteLn;
    P:=0;
   End;
  End;
 End
  Else
 Begin
  TotalNumFiles:=0;
  TotalSize:=0;
  If Not((Brief)in(Option))Then Begin
   Inc(P,2);
   WriteLn('Le volume de l''unite '+CurrDrive+' est '+CurrLabel);
   WriteLn;
  End;
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
   If(Pause)in(Option)Then Begin
    Inc(P);
    If P=Hi(WindMax)Then Begin
     Write('Presse une touche pour continuer...');
     If ReadKey=#27Then Exit;
     WriteLn;
     P:=0;
    End;
   End;
   Inc(TotalNumFiles);
   Inc(TotalSize,Info.Size);
  End;
  If Not((Brief)in(Option))Then Begin
   WriteLn(' Les ',TotalNumFiles,' fichier(s) utilisent ',TotalSize shr 9,' Ko');
   WriteLn(DiskFree(Byte(CurrDrive)-64)shr 9:10,' Ko de libre');
  End;
 End;
End;

Procedure DiskCopyCommand;Begin
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
  WriteLn('ECHO [OFF|ON]');
  WriteLn;
  WriteLn('       /?  Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn('  message  Ce parametre permet d''afficher un message');
  WriteLn('      OFF  Ce parametre permet de desactiver le prompt.');
  WriteLn('       ON  Ce parametre permet d''activer le prompt.');
 End
  Else
 If ParamList='.'Then WriteLn Else
 If StrToUpper(ParamList)='OFF'Then Echo:=False Else
 If StrToUpper(ParamList)='ON'Then Echo:=True
                              Else WriteLn(ParamList);
End;

Procedure EraseCommand;Var
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
    WriteLn('Paramätre requis');
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   WriteLn('ERASE   Cette commande permet d''effectuer la suppression de fichier sur un unite de disque.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('ERASE [/?] fichier');
   WriteLn;
   WriteLn('      /?    Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('  fichier   Ce parametre permet d''indiquer le nom du fichier a supprimer.');
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

Function ExitCommand:Boolean;
Var
 FirstParam:String;
 N,Err:Integer;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('EXIT  Cette commande permet de quitter l''interpreteur de commande.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('EXIT [/?] [CodeSortie]');
  WriteLn;
  WriteLn(' CodeSortie   Ce parametre permet d''indiquer le code de sortie a ',
                         'retourner a l''application parent');
  WriteLn('        /?    Ce parametre permet d''afficher l''aide sur cette commande');
  ExitCommand:=False;
 End
  Else
 If Length(FirstParam)>0Then Begin
  Val(FirstParam,N,Err);
  Halt(N);
  ExitCommand:=True;
 End
  Else
 ExitCommand:=True;
End;

Procedure FixDiskCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure FormatCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure HelpCommand;Begin
 WriteLn('Les commandes standard suivantes sont disponible.');
 WriteLn('Pour plus d''information sur une commande specifique, ecrire :');
 WriteLn;
 WriteLn(' HELP nomdelacommande');
 WriteLn;
 WriteLn('ASSIGN ... Assigne un disque logique a physique');
 WriteLn('ATDIR .... Changes les attributs des repertoires');
 WriteLn('BASIC .... Allez dans le MSX BASIC sur disque');
 WriteLn('BUFFERS .. Affiche/fixe les nombres de tampons de disque');
 WriteLn('CD ....... Voir CHDIR');
 WriteLn('CHDIR .... Affiche/fixe le repertoire courant');
 WriteLn('CHKDSK ... Verifie l''integrite d''un disque');
 WriteLn('CLS ...... Efface l''ecran');
 WriteLn('CONCAT ... Joindre des fichiers ensembles');
 WriteLn('COPY ..... Copies les fichiers');
 WriteLn('DATE ..... Affiche/fixe la date courante');
 WriteLn('DEL ...... Voir ERASE');
 WriteLn('DIR ...... Affiche les noms de fichiers dans un disque');
 WriteLn('DISKCOPY . Copie uyn disque entier sur un autre');
 WriteLn('ECHO ..... Affiche le texte le suivant');
 WriteLn('ERA ...... Voir ERASE');
 WriteLn('ERASE .... Efface des fichiers');
 WriteLn('EXIT ..... Quitte le COMMAND2.COM');
 WriteLn('Presse n''importe quel touche pour continuer...');
 If ReadKey=#0 Then ReadKey;
 WriteLn('FIXDISK .. Met a jour le disque MSX-DOS 1 vers MSX-DOS 2');
 WriteLn('FORMAT ... Formatte un disque');
 WriteLn('HELP ..... Fournit l''aide d''une commande');
 WriteLn('KMODE .... Fixe ou reinialise le mode "Kanji"');
 WriteLn('MD ....... Voir MKDIR');
 WriteLn('MKDIR .... Create un nouveau sous-repertoire');
 WriteLn('MODE ..... Change le mode de l''ecran');
 WriteLn('MOVE ..... Deplace les fichiers d''un disque');
 WriteLn('MVDIR .... Deplace un sous-repertoire');
 WriteLn('PATH ..... Affiche/fixe la chemin de recherche d''une commande');
 WriteLn('PAUSE .... Affiche un prompt et attend une touche enfonce');
 WriteLn('RAMDISK .. Affiche/fixe la taille d''un disque en RAM');
 WriteLn('RD ....... Voir RMDIR');
 WriteLn('REM ...... Remarque... Ignore le texte le suivant');
 WriteLn('REN ...... Voir RENAME');
 WriteLn('RENAME ... Renomme des fichiers');
 WriteLn('RMDIR .... Enleve un sous-repertoire vide');
 WriteLn('RNDIR .... Renomme un sous-repertoire');
 WriteLn('SET ...... Affiche/fixe la chaine de caracteres d''environnement');
 WriteLn('TIME ..... Affiche/fixe l''heure courante');
 WriteLn('TYPE ..... Affiche le contenu de fichiers');
 WriteLn('UNDEL .... Recupere des fichiers effaces');
 WriteLn('VER ...... Affiche les numeros de versions MSX-DOS');
 WriteLn('Presse n''importe quel touche pour continuer...');
 If ReadKey=#0 Then ReadKey;
 WriteLn('VERIFY ... Affiche/fixe l''etat de verification courante');
 WriteLn('VOL ...... Affiche/fixe le nom du volume du disque');
 WriteLn('XCOPY .... Copies les fichiers d''un arbre de repertoire');
 WriteLn('XDIR ..... Affiches les noms d''un fichiers d''un arbre de repertoire');
 WriteLn;
 WriteLn('Aide pour les autres fournitures MSX-DOS aussi disponible.');
 WriteLn('Les sujets standard sont :');
 WriteLn;
 WriteLn('BATCH .... Fichiers de traitement par lot');
 WriteLn('EDITING .. Ligne de commande et rentrer');
 WriteLn('ENV ...... Chaine de caracteres d''environnement');
 WriteLn('ERRORS ... Messages d''erreur etr annulation, reessayer les erreurs');
 WriteLn('IO ....... Redirection, tuyau et entree/sortie standard');
 WriteLn('SYNTAX ... Notation utilise dans les descriptions de commande');
End;

Procedure MkDirCommand;Var
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
    WriteLn('Paramätre requis');
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   WriteLn('MKDIR   Cette commande permet de creer un repertoire.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('MKDIR [/?] nomrepertoire');
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

Procedure ModeCommand;
Var
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('MODE   Cette commande permet de changer la largeur ',
          'de l''affichage');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('MODE largeur');
  WriteLn;
  WriteLn('   largeur   Ce parametre peut etre 40 ou 80');
 End
  Else
 If FirstParam='29'Then Begin
  CurrWidth:=29;
  TextMode(CO40);
  SetDefaultColor;
  Window(3+1,1,3+29,25);
  ClrScr;
 End
  Else
 If FirstParam='40'Then Begin
  CurrWidth:=40;
  TextMode(C40);
  Window(1,1,40,25);
  SetDefaultColor;
  ClrScr;
 End
  Else
 If FirstParam='80'Then Begin
  CurrWidth:=80;
  TextMode(C80);
  Window(1,1,80,25);
  SetDefaultColor;
  ClrScr;
 End;
End;

Procedure MoveCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure MvDirCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PathCommand;Begin
 WriteLn(GetEnv('PATH'));
End;

Procedure PauseCommand;
Var
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('PAUSE   Cette commande permet d''afficher un message de pause et une ',
          'attente d''une action utilisateur pour poursuivre.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('PAUSE [/?]');
  WriteLn;
  WriteLn('   /?    Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 Begin
  WriteLn('Presse une touche pour continuer...');
  ReadKey;
 End;
End;

Procedure PromptCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure RmDirCommand;Var
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
    WriteLn('Paramätre requis');
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   WriteLn('RMDIR   Cette commande permet de supprimer un repertoire vide.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('RMDIR [/?] nomrepertoire');
   WriteLn;
   WriteLn('  /?           Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('nomrepertoire  Ce parametre permet d''indiquer le nom du repertoire');
   Exit;
  End;
  {$I-}RmDir(CurrParam);{$I+}
  Err:=IoResult;
  If Err<>0Then WriteLn(GetErrorMessage(Err));
  If P>9Then Break;
 Until CurrParam='';
End;

Procedure RemCommand;
Var
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('REM   Cette commande permet d''indiquer une remarque.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('REM [/?] commentaires');
  WriteLn;
  WriteLn('  /?           Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn('commentaires   Ce parametre permet d''indiquer une remarque');
 End;
End;

Procedure RenameCommand;
Var
 P:Byte;
 Err:Word;
 F:File;
 CurrParam,Source,Target:String;
Begin
 P:=0;
 Source:='';
 Target:='';
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    WriteLn('Paramätre requis');
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   WriteLn('RENAME   Cette commande permet de renommer un fichier.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('RENAME [/?] anciennom nouveaunom');
   WriteLn;
   WriteLn(' /?         Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('anciennom   Ce parametre permet d''indiquer l''ancien nom');
   WriteLn('nouveaunom  Ce parametre permet d''indiquer le nouveau nom');
   Exit;
  End
   Else
  If CurrParam<>''Then
  Begin
   If Source=''Then Source:=CurrParam
               Else Target:=CurrParam;
  End;
  If P>9Then Break;
 Until CurrParam='';
 If(Source='')or(Target='')Then Begin
  WriteLn('La source et la destination sont requises');
 End
  Else
 Begin
  {$I-}Assign(F,Source);
  Rename(F,Target);
  {$I+}
  Err:=IoResult;
  If Err=0Then WriteLn('1 fichier de renomme')
          Else WriteLn(GetErrorMessage(Err));
 End;
End;

Procedure RAMDISKCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ResetCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure RnDirCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SetCommand;
Var
 Pause:Boolean;
 I,P:Integer;
 FirstParam:String;
Begin
 Pause:=False;
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('SET   Cette commande permet de fixer ou demander le contenu des ',
          'variables d''environnement du systeme d''exploitation');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('SET [/?] [/P]');
  WriteLn;
  WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' /P   Ce parametre permet d''effectuer une pause entre chaque page');
  Exit;
 End
  Else
 If StrToUpper(Copy(FirstParam,1,7))='PROMPT='Then Begin
  If StrToUpper(Copy(FirstParam,8,255))='ON'Then Prompt:=True Else
  If StrToUpper(Copy(FirstParam,8,255))='OFF'Then Prompt:=False
   Else
  WriteLn('Valeur non reconnu');
 End
  Else
 Begin
  If(FirstParam='/P')or(FirstParam='/p')Then Pause:=True;
  P:=0;
  For I:=0to EnvCount do Begin
   WriteLn(EnvStr(I));
   If(Pause)Then Begin
    Inc(P);
    If P=Hi(WindMax)Then Begin
     Write('Presse une touche pour continuer...');
     ReadKey;
     WriteLn;
     P:=0;
    End;
   End;
  End;
 End;
End;

Procedure ShiftCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TimeCommand;
Var
 FirstParam:String;
 Hour,Minute,Second,CentSec:Word;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('TIME   Cette commande permet de fixer ou de demander l''heure du systeme d''exploitation');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('TIME [/?]');
  WriteLn;
  WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 Begin
  GetTime(Hour,Minute,Second,CentSec);
  WriteLn('L''heure actuelle est ',Hour:2,':',PadZeroLeft(Minute,2),':',PadZeroLeft(Second,2),',',CentSec);
 End;
End;

Procedure TrueNameCommand;
Var
 P:Byte;
 CurrParam:String;
 CurrDirectory:String;
Begin
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    GetDir(0,CurrDirectory);
    WriteLn(CurrDirectory);
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   WriteLn('TRUENAME   Cette commande permet d''afficher le nom complet d''un unite, repertoire ou d''un nom de fichier');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('TRUENAME [/?] [chemin]');
   WriteLn;
   WriteLn(' /?     Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('chemin  Ce parametre permet d''indiquer le nom du chemin a analyser');
   Exit;
  End;
  WriteLn(FExpand(CurrParam));
  If P>9Then Break;
 Until CurrParam='';
End;

Procedure TypeCommand;
Var
 P:Byte;
 Err:Word;
 Handle:Text;
 CurrParam,CurrLine:String;
Begin
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If(Length(CurrParam)=0)and(P=1)Then Begin
   WriteLn('La syntaxe est incorrecte');
   Exit;
  End;
  If CurrParam='/?'Then Begin
   WriteLn('TYPE   Cette commande permet d''afficher le contenu d''un fichier');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('TYPE [/?] [fichier]');
   WriteLn;
   WriteLn('  /?     Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('fichier  Ce parametre permet d''indiquer le nom du fichier a afficher');
   Exit;
  End;
  If CurrParam<>''Then Begin
   Assign(Handle,CurrParam);
   {$I-}Reset(Handle);{$I+}
   Err:=IOResult;
   If Err<>0Then Begin
    WriteLn('Nom du fichier : "',CurrParam,'"');
    WriteLn(GetErrorMessage(Err));
    Exit;
   End;
   While NOT EOF(Handle)do Begin
    ReadLn(Handle,CurrLine);
    WriteLn(CurrLine);
   End;
   Close(Handle);
  End;
  If P>9Then Break;
 Until CurrParam='';
End;

Procedure UndelCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure VerCommand;
Var
 Ver:Word;
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('VER   Cette commande permet de demander la version du systeme d''exploitation.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('VER [/?]');
  WriteLn;
  WriteLn(' /?    Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 Begin
  Ver:=DosVersion;
  WriteLn('MSX-DOS kernel version ',Lo(Ver),'.',Hi(Ver));
  WriteLn('MSXDOS2.SYS version 0.0');
  WriteLn('COMMAND2.COM version 0.0');
  WriteLn('Tous droits reserves gladir.com');
 End;
End;

Procedure VerifyCommand;Var
 FirstParam:String;
 X:Boolean;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('VERIFY   Cette commande permet de fixer ou de demander l''etat du ',
          'drapeau de verification de lecture de secteur d''unite d''allocation du systeme d''exploitation.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('VERIFY [/?] [OFF|ON]');
  WriteLn;
  WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' OFF    Ce parametre permet d''activer la verification');
  WriteLn(' ON     Ce parametre permet de desactiver la verification');
 End
  Else
 If StrToUpper(ParamList)='OFF'Then SetVerify(False) Else
 If StrToUpper(ParamList)='ON'Then SetVerify(True)
  Else
 Begin
  GetVerify(X);
  Write('VERIFY = ');
  If(X)Then WriteLn('on')
       Else WriteLn('off');
 End;
End;

Procedure VolCommand;
Var
 FirstParam,Volume:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('VOL   Cette commande permet d''afficher le nom du volume d''une unite de disque.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('VOL [/?] [unite:]');
  WriteLn;
  WriteLn(' /?      Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' unite:  Ce paramtre permet d''indiquer la lettre d''unite de disque');
 End
  Else
 If(Length(FirstParam)=2) and (FirstParam[2]=':')Then Begin
  If FirstParam[2]=':'Then Begin
   Write('Le volume de l''unite ',UpCase(FirstParam[1]));
   Volume:=GetDiskLabel(Byte(UpCase(FirstParam[1]))-64);
   If Length(Volume)=0Then WriteLn(' n''a pas d''etiquette')
                      Else WriteLn(Volume);
  End
   Else
  InvalidParam(1);
 End
  Else
 If Length(FirstParam)>0Then Begin
  InvalidParam(1);
 End
  Else
 Begin
   Write('Le volume de l''unite ',GetCurrentDisk);
   Volume:=GetDiskLabel(0);
   If Length(Volume)=0Then WriteLn(' n''a pas d''etiquette')
                      Else WriteLn(Volume);
 End;
End;

Procedure XCopyCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure XDirCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DateCommand;
Var
 FirstParam:String;
 Year,Month,Day,DayOfMonth:Word;
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
  GetDate(Year,Month,Day,DayOfMonth);
  WriteLn('La date du jour est ',Year:4,'-',PadZeroLeft(Month,2),'-',PadZeroLeft(Day,2));
 End;
End;

Procedure UnknownCommand;Begin
 Exec(CurrCommand,ParamList);
 If DosError<>0Then Begin
  WriteLn('Commande ou nom de fichier non reconnu');
 End;
 WriteLn;
End;

Procedure RunCommand;
Var
 LastEcho:Boolean;
 FileBat:Text;
Begin
 ExtractCommand;
 CommandFound:=False;
 For J:=Low(CommandList) to High(CommandList) do Begin
  If CurrCommand=CommandList[J]Then Begin
   Case(J)of
    0:AssignCommand;
    1:ATDIRCommand;
    2:AttribCommand;
    3:BasicCommand;
    4:BeepCommand;
    5:BootCommand;
    6:BuffersCommand;
    7:ChDirCommand;
    8:ChDirCommand;
    9:ChkDskCommand;
    10:CLSCommand;
    11:COMMANDCommand;
    12:COMMAND2Command;
    13:CONCATCommand;
    14:CopyCommand;
    15:DateCommand;
    16:DelCommand;
    17:DIRCommand;
    18:DiskCopyCommand;
    19:EchoCommand;
    20:EraseCommand;
    21:EraseCommand;
    22:Terminated:=ExitCommand;
    23:FixDiskCommand;
    24:FormatCommand;
    25:HelpCommand;
    26:MkDirCommand;
    27:MkDirCommand;
    28:ModeCommand;
    29:MoveCommand;
    30:MvDirCommand;
    31:PathCommand;
    32:PauseCommand;
    33:RAMDISKCommand;
    34:RmDirCommand;
    35:RemCommand;
    36:RenameCommand;
    37:ResetCommand;
    38:RmDirCommand;
    39:RnDirCommand;
    40:SetCommand;
    41:TimeCommand;
    42:TypeCommand;
    43:UndelCommand;
    44:VerCommand;
    45:VerifyCommand;
    46:VolCommand;
    47:XCopyCommand;
    48:XDirCommand;
   End;
   If J<=High(CommandList)Then Begin
    CommandFound:=True;
    Break;
   End;
  End;
 End;
 If Not(CommandFound)Then Begin
  If CmdStr='?'Then Begin
   For I:=Low(CommandList) to High(CommandList) do Write(PadRight(CommandList[I],10));
   WriteLn;
  End
   Else
  If FileExist(CmdStr+'.BAT')Then Begin
   Inc(InCmd);
   If InCmd>20Then Begin
    WriteLn('Limite de 20 fichiers de traitements par lots maximum.');
    Exit;
   End;
   LastEcho:=Echo;
   Assign(FileBat,CmdStr+'.BAT');
   {$I-}Reset(FileBat);{$I+}
   If IOResult=0Then Begin
    While Not EOF(FileBat)do Begin
     ReadLn(FileBat,CmdStr);
     If(Echo)Then WriteLn(CmdStr);
     RunCommand;
    End;
   End
    Else
   WriteLn('Probleme de lecture du fichier de traitement par lot');
   Close(FileBat);
   Echo:=LastEcho;
   Dec(InCmd);
  End
   Else
  UnknownCommand;
 End;
End;

BEGIN
 Echo:=True;InCmd:=0;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('MSXDOS : Cette commande permet de lancer l''interpreteur de commande.');
  WriteLn;
  WriteLn('Syntaxe : MSXDOS [command]');
 End
  Else
 If ParamCount>1Then Begin
  Option:=optNone;
  For I:=1 to ParamCount do Begin
   CmdStr:=ParamStr(I);
   RunCommand;
  End;
 End
  Else
 Begin
  Prompt:=False;
  Terminated:=False;
  HomeMessage;
  Repeat
   ShowPrompt;
   ReadLn(CmdStr);
   RunCommand;
  Until Terminated;
 End;
END.

