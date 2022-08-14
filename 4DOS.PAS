{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program _4DOS;

{$M 4096,0,16384}

Uses Crt,DOS;

Const
 CommandList:Array[0..80]of String[8]=(
  'ALIAS','ATTRIB','BEEP','BREAK','CALL','CD','CDD','CHCP','CHDIR',
  'CLS','COLOR','COPY','CTTY','DATE','DEL','DELAY','DELETE','DIR',
  'DIRS','DRAWBOX','DRAWHLINE','DRAWVLINE','ECHO','ENDLOCAL',
  'ENDTEXT','ERA','ERASE','ESET','EXCEPT','EXIT','FOR','FREE',
  'GLOBAL','GOSUB','GOTO','HELP','HISTORY','IF','IFF','INKEY',
  'INPUT','KEYSTACK','LH','LOADBTM','LOADHIGH','LOG','MD','MEMORY',
  'MKDIR','MOVE','PATH','PAUSE','PROMPT','PUSHD','QUIT','RD','REM',
  'REN','RENAME','RETURN','RMDIR','SCREEN','SCRPUT','SET','SETDOS',
  'SETLOCAL','SHIFT','SWAPPING','TEE','TEXT','TIME','TIMER','TRUENAME',
  'TYPE','UNALIAS','UNSET','VER','VERIFY','VOL','Y','POPD'
 );

 MaxHistory=100;
 MaxStackDirectory=50;

Type
 StrPointer=^String;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 AttrAdd,AttrRemove:Word;
 SubDirectory:Boolean;
 InCmd:Byte;
 Option:(optNone,optCommand);
 History:Array[1..MaxHistory] of StrPointer;
 StackDirectory:Array[1..MaxStackDirectory] of StrPointer;
 NumberHistory,NumberDirectory:Integer;
 Echo:Boolean;
 CommandFound,Terminated:Boolean;
 CmdStr:String;
 CurrCommand,ParamList:String;
 I,J:Byte;

Function GetConvMemory:Word;
Var
 Regs:Registers;
Begin
 Regs.AX:=0;
 Intr($12,Regs);
 GetConvMemory:=Regs.AX;
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

Function StrToLower(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
 End;
 StrToLower:=S;
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

Function SplitFileName(s:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Splitfilename:=N+E;
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

Function AddHistory(S:String):Boolean;
Var
 I:Word;
 P:StrPointer;
Begin
 If NumberHistory>=MaxHistory Then Begin
  FreeMem(History[1],Length(History[1]^)+1);
  For I:=1 to MaxHistory-1 do History[I]:=History[I+1];
  GetMem(P,Length(S)+1);
  P^:=S;
  History[MaxHistory]:=P;
  AddHistory:=True;
  Exit;
 End
  Else
 Begin
  Inc(NumberHistory);
  GetMem(P,Length(S)+1);
  P^:=S;
  History[NumberHistory]:=P;
  AddHistory:=True;
 End;
End;

Function PushDirectory(Directory:String):Boolean;
Var
 P:StrPointer;
Begin
 If NumberDirectory>=MaxStackDirectory Then Begin
  WriteLn('Pile de r‚pertoire pleine');
  PushDirectory:=False;
  Exit;
 End;
 Inc(NumberDirectory);
 GetMem(P,Length(Directory)+1);
 P^:=Directory;
 StackDirectory[NumberDirectory]:=P;
 PushDirectory:=True;
End;

Function PopDirectory:String;Begin
 PopDirectory:='';
 If NumberDirectory>0Then Begin
  PopDirectory:=StackDirectory[NumberDirectory]^;
  FreeMem(History[NumberDirectory],Length(History[NumberDirectory]^)+1);
  Dec(NumberDirectory);
 End;
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

Function MoveFile(Source,Target:String):Boolean;
Var
 F:File;
Begin
 If(Source='')or(Target='')Then Begin
  MoveFile:=False;
  Exit;
 End;
 Source:=FExpand(Source);
 Target:=FExpand(Target);
 If(Source[1]<>Target[1])and(Source[2]=':')Then Begin { Unite de disque different ?}
   { Copie le fichier }
  MoveFile:=CopyFile(Source,Target,False);
   { Supprime le fichier }
  {$I-}Assign(F,Source);
  Erase(F);
  {$I+}
 End
  Else
 Begin
  {$I-}
  Assign(F,Source);
  Rename(F,Target+'\'+SplitFileName(Source));
  MoveFile:=IOResult=0;
  {$I+}
 End;
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
 WriteLn;
 Case Language of
  _English:WriteLn('4DOS - Command interpreter');
  _Germany:WriteLn('4DOS - Befehlsinterpreter');
  _Italian:WriteLn('4DOS - Interprete di comando');
  _Spain:WriteLn('4DOS - Int‚rprete de comando');
  Else WriteLn('4DOS - Interpreteur de comande');
 End;
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
       'N' : Write(GetCurrentDisk);
   'p','P' : Begin
     GetDir(0,CurrentDir);
     Write(StrToLower(CurrentDir));
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

Procedure AliasCommand;Begin
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
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Change or view file and subdirectoryh attributes');
    WriteLn;
    WriteLn('Format:   ATTRIB file [+R|-R] [+A|-A] [+S|-S] [+H|-H]');
   End;
   Else Begin
    WriteLn('ATTRIB - Cette commande permet de demander ou changer l''attribut d''un fichier');
    WriteLn;
    WriteLn('Syntaxe : ATTRIB nomdufichier [+R|-R] [+A|-A] [+S|-S] [+H|-H]');
   End;
  End;
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

Procedure BeepCommand;
Var
 FirstParam:String;
 X:Boolean;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Beep the speaker or play simple music');
    WriteLn;
    WriteLn('Format:   BEEP [/?]');
   End;
   Else Begin
    WriteLn('BEEP   Cette commande permet d''emettre un bip sonore.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('BEEP [/?]');
    WriteLn;
    WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
   End;
  End;
 End
  Else
 Begin
  Sound(1550);
  Delay(182);
  NoSound;
 End;
End;

Procedure BreakCommand;
Var
 FirstParam:String;
 X:Boolean;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Display, enable, or disable Ctrl-C and Ctrl-Break checking.');
    WriteLn;
    WriteLn('Format:  BREAK [/?]');
   End;
   Else Begin
    WriteLn('BREAK   Cette commande permet de fixer ou de demander l''etat du Ctrl+Break.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('BREAK [/?]');
    WriteLn;
    WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
   End;
  End;
 End
  Else
 Begin
  GetCBreak(X);
  Write('BREAK = ');
  If(X)Then WriteLn('on')
       Else WriteLn('off');
 End;
End;

Procedure CallCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ChDirCommand;
Var
 Error:Word;
 FirstParam,Dir:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Display or change the current directory.');
    WriteLn;
    WriteLn('Format:   CD [path | -]');
    WriteLn(' ':14,'or');
    WriteLn(' ':10,'CHDIR [path | -]');
   End;
   Else Begin
    WriteLn('CHDIR   Cette commande permet de fixer ou de demander le repertoire courant.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('CD [/?] chemin');
    WriteLn('CHDIR [/?] chemin');
    WriteLn;
    WriteLn('  /?     Ce parametre permet d''afficher l''aide sur cette commande');
    WriteLn(' chemin  Ce parametre permet d''indiquer le chemin du repertoire.');
   End;
  End;
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

Procedure CHCPCommand;
Var
 Err:Word;
 Regs:Registers;
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Display of change the current system code page.');
    WriteLn;
    WriteLn('Format:   CHCP [n]');
   End;
   Else Begin
    WriteLn('CHCP   Cette commande permet de fixer ou de demander la page de codes.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('CHCP [/?] [code]');
    WriteLn;
    WriteLn('  /?     Ce parametre permet d''afficher l''aide sur cette commande');
    WriteLn(' code    Ce parametre permet d''indiquer la page de code');
   End;
  End;
 End
  Else
 If FirstParam<>''Then Begin
  Regs.AX:=$6602;
  Val(FirstParam,Regs.BX,Err);
  If Err=0Then Begin
   Intr($21,Regs);
   If(Regs.Flags and FCarry=FCarry)Then Begin
    WriteLn('Impossible de changer le code de page actif');
   End;
  End
   Else
  WriteLn('Code de page invalide.');
 End
  Else
 Begin
  Regs.AX:=$6601;
  Intr($21,Regs);
  If(Regs.Flags and FCarry=FCarry)Then Begin
   WriteLn('Page de code active inconnnu');
  End
   Else
  WriteLn('Page de code active : ',Regs.BX);
 End;
End;

Procedure CDDCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CLSCommand;
Var
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Clear the video display and move the cursor to the upper left');
    WriteLn;
    WriteLn('Format:   CLS [/?]');
   End;
   Else Begin
    WriteLn('CLS   Cette commande permet d''effacer l''ecran.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('CLS [/?]');
    WriteLn;
    WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
   End;
  End;
 End
  Else
 Begin
  ClrScr;
 End;
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
    WriteLn('ParamŠtre requis');
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   Case Language of
    _English:Begin
     WriteLn('Purpose:  Copy data between disks, directories or files.');
     WriteLn;
     WriteLn('Format:   COPY [/?] [/P] source destination');
    End;
    Else Begin
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
    End;
   End;
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

Procedure CTTYCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ColorCommand;
Var
 Option:(None,fg,_ON,bg,bc);
 CurrParam:String;
 Value:Byte;
 I:Integer;
 Err:Word;
Begin
 Option:=fg;
 I:=1;
 CurrParam:=ExtractParam(1);
 If(CurrParam='/?')or(CurrParam='/H')or(CurrParam='/h')Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Change the default display colors.');
    WriteLn;
    WriteLn('Format:   COLOR [[BRIGHT] [BLINK] [fg ON bg] [BORDER bc]');
   End;
   Else Begin
    WriteLn('COLOR   Cette commande permet de fixer la couleur du texte et d''arriere-plan.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('COLOR [/?]');
    WriteLn('COLOR [[BRIGHT] [BLINK] [fg ON bg] [BORDER bc]');
    WriteLn;
    WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
   End;
  End;
 End
  Else
 While CurrParam<>''do Begin
  If(Option=_ON)Then Begin
   If(StrToUpper(CurrParam)='ON')Then Begin
    Option:=bg;
   End
    Else
   Begin
    WriteLn('''ON'' attendu !');
    Break;
   End;
  End
   Else
  Begin
   If(StrToUpper(CurrParam)='BRI')or(StrToUpper(CurrParam)='BRIGHT')Then HighVideo Else
   If(StrToUpper(CurrParam)='BOR')or(StrToUpper(CurrParam)='BORDER')Then Option:=bg Else
   If(StrToUpper(CurrParam)='BLI')or(StrToUpper(CurrParam)='BLINK')Then Begin
   End
    Else
   Case(Option)of
    fg:Begin
     Val(TrimL(CurrParam),Value,Err);
     TextColor(Value);
     Option:=_ON;
    End;
    bg:Begin
     Val(TrimL(CurrParam),Value,Err);
     TextBackground(Value);
     Option:=None;
    End;
    bc:Begin
     Val(CurrParam,Value,Err);
     Option:=None;
    End;
    Else Begin
     WriteLn('Valeur non attendu !');
     Break;
    End;
   End;
  End;
  Inc(I);
  CurrParam:=ExtractParam(I);
  If I>10Then Break;
 End;
End;

Procedure DateCommand;
Var
 FirstParam:String;
 Year,Month,Day,DayOfMonth:Word;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Display and optionnally change the system date.');
    WriteLn;
    WriteLn('Format:   DATE [/?]');
   End;
   Else Begin
    WriteLn('DATE   Cette commande permet de fixer ou de demander la date du systeme d''exploitation');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('DATE [/?]');
    WriteLn;
    WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
   End;
  End;
 End
  Else
 Begin
  GetDate(Year,Month,Day,DayOfMonth);
  WriteLn('La date du jour est ',Year:4,'-',PadZeroLeft(Month,2),'-',PadZeroLeft(Day,2));
 End;
End;

Procedure DelayCommand;
Var
 NombreSeconde:LongInt;
 Err:Word;
Begin
 If(ExtractParam(1)='/?')or(ExtractParam(1)='/h')or(ExtractParam(1)='/H')Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Pause for a specified length of time.');
    WriteLn;
    WriteLn('Format:   DELAY [seconds]');
   End;
   Else Begin
    WriteLn('DELAY : Cette commande permet d''attendre le nombre de secondes specifies.');
    WriteLn;
    WriteLn('Syntaxe : DELAY nombredesecondes');
   End;
  End;
 End
  Else
 If ExtractParam(1)<>''Then Begin
  Val(ExtractParam(1),NombreSeconde,Err);
  Delay(NombreSeconde*1000);
 End
  Else
 WriteLn('Nombre de parametre invalide !');
End;

Procedure DeleteCommand;
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
   Case Language of
    _English:Begin
     WriteLn('Purpose:  Erase one file');
     WriteLn;
     WriteLn('Format:   DEL [/?] file');
     Exit;
    End;
    Else Begin
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
   End;
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
   Case Language of
    _English:Begin
     WriteLn('Purpose:  Display information about files and subdirectories.');
     WriteLn;
     WriteLn('Format:   DIR [/?] [/2|/W] [/B] [/P] [path]');
     Exit;
    End;
    Else Begin
     WriteLn('DIR   Cette commande permet d''afficher le contenu d''un repertoire dans l''unit‚ de disque.');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('DIR [/?] [/2|/W] [/B] [/P] [chemin]');
     WriteLn;
     WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
     WriteLn(' /2   Ce parametre permet d''afficher sur 2 colonnes');
     WriteLn(' /B   Ce parametre enleve l''entˆte et les d‚tails de la fin');
     WriteLN(' /P   Ce parametre affiche une pause apres l''affichage d''une page pleine');
     WriteLn(' /W   Ce parametre affiche seulement les fichiers sur plein de colonnes');
     Exit;
    End;
   End;
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
   WriteLn(' Les ',TotalNumFiles,' fichier(s) utilisent ',TotalSize,' octet(s)');
   WriteLn(DiskFree(Byte(CurrDrive)-64):10,' octet(s) de libre');
  End;
 End;
End;

Procedure DirsCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DrawBoxCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DrawHLineCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DrawVLineCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure EchoCommand;
Var
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Display a message, enable or disable batch file or command-line');
    WriteLn(' ':10,'echoing, or display the echo status.');
    WriteLn;
    WriteLn('Format:   ECHO [ON | OFF | message]');
   End;
   Else Begin
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
   End;
  End;
 End
  Else
 If ParamList='.'Then WriteLn Else
 If StrToUpper(ParamList)='OFF'Then Echo:=False Else
 If StrToUpper(ParamList)='ON'Then Echo:=True
                              Else WriteLn(ParamList);
End;

Procedure EndLocalCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure EndTextCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure EraseCommand;
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
   Case Language of
    _English:Begin
     WriteLn('Purpose:  Erase one file');
     WriteLn;
     WriteLn('Format:   ERASE [/?] file');
     Exit;
    End;
    Else Begin
     WriteLn('ERASE   Cette commande permet d''effectuer la suppression de fichier sur un unit‚ de disque.');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('ERASE [/?] fichier');
     WriteLn;
     WriteLn('      /?    Ce parametre permet d''afficher l''aide sur cette commande');
     WriteLn('  fichier   Ce parametre permet d''indiquer le nom du fichier a supprimer.');
     Exit;
    End;
   End;
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

Procedure ESetCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ExceptCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Function ExitCommand:Boolean;
Var
 FirstParam:String;
 N,Err:Integer;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Return from 4DOS.');
    WriteLn;
    WriteLn('Format:   EXIT [value]');
   End;
   Else Begin
    WriteLn('EXIT  Cette commande permet de quitter l''interpreteur de commande.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('EXIT [/?] [CodeSortie]');
    WriteLn;
    WriteLn(' CodeSortie   Ce parametre permet d''indiquer le code de sortie a ',
                           'retourner a l''application parent');
    WriteLn('        /?    Ce parametre permet d''afficher l''aide sur cette commande');
   End;
  End;
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

Procedure ForCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure FreeCommand;
Var
 P,Drive:Integer;
 CurrParam:String;
Begin
 P:=1;
 CurrParam:=ExtractParam(1);
 If ExtractParam(1)='/?'Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose :  Display the total disk space, total bytes used, and total');
    WriteLn('           bytes free on the specified (or default) drive(s).');
    WriteLn;
    WriteLn('Format:    FREE [drive: ...]');
   End;
   Else Begin
    WriteLn('FREE : Cette commande permet de demander ',
                    'les statistiques d''un unit‚ de disque');
    WriteLn;
    WriteLn('Syntaxe : FREE [/?]');
    WriteLn('          FREE [unite:]');
    WriteLn;
    WriteLn(' unite:   Affiche les statistiques d''un unit‚');
   End;
  End;
 End
  Else
 Repeat
  If CurrParam=''Then Begin
   WriteLn;
   WriteLn(' Volume dans l''unite ',GetCurrentDisk,' est ',GetDiskLabel(0));
   WriteLn(DiskSize(0):20,' octets d''espace disque total');
   WriteLn(DiskSize(0)-DiskFree(0):20,' octets d''espace utilise');
   WriteLn(DiskFree(0):20,' octets d''espace libre');
  End
   Else
  Begin
   Drive:=Ord(CurrParam[1])-Ord('A');
   WriteLn;
   WriteLn(' Volume dans l''unite ',UpCase(CurrParam[1]),' est ',GetDiskLabel(Drive+1));
   WriteLn(DiskSize(Drive+1):20,' octets d''espace disque total');
   WriteLn(DiskSize(Drive+1)-DiskFree(Drive+1):20,' octets d''espace utilise');
   WriteLn(DiskFree(Drive+1):20,' octets d''espace libre');
  End;
  Inc(P);
  CurrParam:=ExtractParam(P);
 Until CurrParam='';
End;

Procedure GlobalCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure GosubCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure GotoCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure HelpCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure HistoryCommand;
Var
 I:Integer;
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('HISTORY   Cette commande permet d''afficher l''historique des commandes.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('HISTORY [/?]');
  WriteLn;
  WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 For I:=1 to NumberHistory do WriteLn(History[I]^);
End;

Procedure IfCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure IFFCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure InkeyCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure InputCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure KeyStackCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LoadBTMCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LoadHighCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LogCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure MemoryCommand;
Var
 I,EnvSize:LongInt;
Begin
 {$IFDEF FPC}
  WriteLn('** Information non disponible sur ce systeme');
 {$ELSE}
  WriteLn(GetConvMemory*1024:15,' octets total de memoire RAM');
  WriteLn(MemAvail:15,' octets de libre');
 {$ENDIF}
 WriteLn;
 EnvSize:=0;
 For I:=1 to EnvCount do Inc(EnvSize,Length(EnvStr(I)));
 WriteLn(EnvSize:15,' taille total de l''environnement');
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
    WriteLn('ParamŠtre requis');
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

Procedure MoveCommand;Begin
 If ExtractParam(1)='/?'Then Begin
  WriteLn('MOVE : Cette commande permet de deplacer un fichier.');
  WriteLn;
  WriteLn('Syntaxe : MOVE source destination');
 End
  Else
 If(ExtractParam(1)<>'')and(ExtractParam(2)<>'')Then Begin
  If Not MoveFile(ExtractParam(1),ExtractParam(2))Then Begin
   WriteLn('Erreur de d‚placement du fichier.');
  End;
 End
  Else
 WriteLn('Nombre de parametre invalide');
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

Procedure PopDCommand;
Var
 Error:Word;
 FirstParam,Dir:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('POPD   Cette commande permet de restaurer le repertoire.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('POPD [/?]');
  WriteLn;
  WriteLn('  /?     Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 Begin
  Dir:=PopDirectory;
  {$I-} ChDir(Dir);{$I+}
  Error:=IoResult;
  If Error<>0Then WriteLn(GetErrorMessage(Error));
 End;
End;

Procedure PromptCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PushDCommand;
Var
 Error:Word;
 FirstParam,Dir:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('PUSHD   Cette commande permet de sauver le repertoire.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('PUSHD [/?] chemin');
  WriteLn;
  WriteLn('  /?     Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' chemin  Ce parametre permet d''indiquer le repertoire a mettre a la place.');
 End
  Else
 If Length(FirstParam)>0Then Begin
  If Not(PushDirectory(FExpand(FirstParam)))Then WriteLn('Pile pleine');
  {$I-} ChDir(FirstParam);{$I+}
  Error:=IoResult;
  If Error<>0Then WriteLn(GetErrorMessage(Error));
 End
  Else
 Begin
  GetDir(0,Dir);
  If Not(PushDirectory(Dir))Then WriteLn('Pile pleine');
 End;
End;

Procedure QuitCommand;Begin
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
    WriteLn('ParamŠtre requis');
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
    WriteLn('ParamŠtre requis');
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

Procedure ReturnCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ScreenCommand;
Var
 X,Y,Err:Word;
Begin
 If ExtractParam(1)='/?'Then Begin
  WriteLn('SCREEN   Cette commande permet de fixer ou demander le contenu des ',
          'variables d''environnement du systeme d''exploitation');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('SCREEN [/?]');
  WriteLn('SCREEN row column [message]');
  WriteLn;
  WriteLn(' /?      Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' row     Ce parametre permet d''indiquer la ligne du texte');
  WriteLn(' column  Ce parametre permet d''indiquer la colonne du texte');
 End
  Else
 Begin
  Val(ExtractParam(1),X,Err);
  Val(ExtractParam(2),Y,Err);
  GotoXY(X+1,Y+1);
  WriteLn(ExtractParam(3));
 End;
End;

Procedure ScrPutCommand;
Const
 ColorList:Array[0..15]of String=(
  'BLACK','BLUE','GREEN','CYAN','RED','MAGENTA','BROWN','LIGHTGRAY',
  'DARKGRAY','LIGHTBLUE','LIGHTGREEN','LIGHTCYAN','LIGHTRED',
  'LIGHTMAGENTA','YELLOW','WHITE');
Var
 Pos:(fg,bg,txt);
 Bright,Blink:Boolean;
 I,X,Y,P,Err:Word;
 Color:Integer;
 CurrParam:String;
Begin
 If ExtractParam(1)='/?'Then Begin
  WriteLn('SCRPUT   Cette commande permet de fixer ou demander le contenu des ',
          'variables d''environnement du systeme d''exploitation');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('SCRPUT [/?]');
  WriteLn('SCRPUT row column [BRIGHT] [BLINK] fg ON bg message');
  WriteLn;
  WriteLn(' /?      Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' row     Ce parametre permet d''indiquer la ligne du texte');
  WriteLn(' column  Ce parametre permet d''indiquer la colonne du texte');
 End
  Else
 Begin
  Bright:=False;
  Val(ExtractParam(1),X,Err);
  Val(ExtractParam(2),Y,Err);
  GotoXY(X+1,Y+1);
  P:=3;
  Pos:=fg;
  CurrParam:=ExtractParam(3);
  Repeat
   If(StrToUpper(CurrParam)='BRI')or(StrToUpper(CurrParam)='BRIGHT')Then Bright:=True Else
   If(StrToUpper(CurrParam)='BLI')or(StrToUpper(CurrParam)='BLINK')Then Blink:=True Else
   If(StrToUpper(CurrParam)<>'ON')Then Begin
    If Pos=fg Then Begin
     Color:=-1;
     For I:=0 to 15 do Begin
      If StrToUpper(CurrParam)=ColorList[I]Then Begin
       Color:=I;
       Break;
      End;
     End;
     If Color=-1Then Val(CurrParam,Color,Err);
     If(Bright)Then Color:=Color or 8;
     If(Blink)Then Color:=Color or 16;
     TextColor(Color and $1F);
     Pos:=bg;
    End
     Else
    If Pos=bg Then Begin
     Color:=-1;
     For I:=0 to 15 do Begin
      If StrToUpper(CurrParam)=ColorList[I]Then Begin
       Color:=I;
       Break;
      End;
     End;
     If Color=-1Then Val(CurrParam,Color,Err);
     TextBackground(Color and 7);
     Pos:=txt;
    End
     Else
    Write(CurrParam);
   End;
   CurrParam:=ExtractParam(P);
   Inc(P);
  Until CurrParam='';
  WriteLn(ExtractParam(3));
 End;
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

Procedure SetDosCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SetLocalCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ShiftCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SwappingCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TeeCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TextCommand;Begin
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

Procedure TimerCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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

Procedure UnaliasCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UnsetCommand;Begin
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
  WriteLn('DOS version ',Lo(Ver),'.',Hi(Ver));
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

Procedure YCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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
 AddHistory(CmdStr);
 ExtractCommand;
 CommandFound:=False;
 For J:=Low(CommandList) to High(CommandList) do Begin
  If CurrCommand=CommandList[J]Then Begin
   Case(J)of
    0:AliasCommand;
    1:AttribCommand;
    2:BeepCommand;
    3:BreakCommand;
    4:CallCommand;
    5:ChDirCommand;
    6:CDDCommand;
    7:CHCPCommand;
    8:ChDirCommand;
    9:CLSCommand;
    10:ColorCommand;
    11:CopyCommand;
    12:CTTYCommand;
    13:DateCommand;
    14:DeleteCommand;
    15:DelayCommand;
    16:DeleteCommand;
    17:DirCommand;
    18:DirsCommand;
    19:DrawBoxCommand;
    20:DrawHLineCommand;
    21:DrawVLineCommand;
    22:EchoCommand;
    23:EndLocalCommand;
    24:EndTextCommand;
    25:EraseCommand;
    26:EraseCommand;
    27:ESetCommand;
    28:ExceptCommand;
    29:Terminated:=ExitCommand;
    30:ForCommand;
    31:FreeCommand;
    32:GlobalCommand;
    33:GosubCommand;
    34:GotoCommand;
    35:HelpCommand;
    36:HistoryCommand;
    37:IfCommand;
    38:IFFCommand;
    39:InkeyCommand;
    40:InputCommand;
    41:KeyStackCommand;
    42:LoadHighCommand;
    43:LoadBTMCommand;
    44:LoadHighCommand;
    45:LogCommand;
    46:MkDirCommand;
    47:MemoryCommand;
    48:MkDirCommand;
    49:MoveCommand;
    50:PathCommand;
    51:PauseCommand;
    52:PromptCommand;
    53:PushDCommand;
    54:QuitCommand;
    55:RmDirCommand;
    56:RemCommand;
    57:RenameCommand;
    58:RenameCommand;
    59:ReturnCommand;
    60:RmDirCommand;
    61:ScreenCommand;
    62:ScrPutCommand;
    63:SetCommand;
    64:SetDosCommand;
    65:SetLocalCommand;
    66:ShiftCommand;
    67:SwappingCommand;
    68:TeeCommand;
    69:TextCommand;
    70:TimeCommand;
    71:TimerCommand;
    72:TrueNameCommand;
    73:TypeCommand;
    74:UnaliasCommand;
    75:UnsetCommand;
    76:VerCommand;
    77:VerifyCommand;
    78:VolCommand;
    79:YCommand;
    80:PopDCommand;
   End;
   If J<=High(CommandList)Then Begin
    CommandFound:=True;
    If InCmd=0Then WriteLn;
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

Procedure ReadLine(Var S:String);
Var
 K:Char;
 X,Y:Byte;
 CurrHistory:Integer;
Begin
 CurrHistory:=NumberHistory;
 X:=WhereX;
 Y:=WhereY;
 S:='';
 Repeat
  GotoXY(X,Y);
  Write(S);
  ClrEol;
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #72:If NumberHistory>0 Then Begin
     S:=History[CurrHistory]^; { Up }
     If CurrHistory>1 Then Dec(CurrHistory);
    End;
    #80:If NumberHistory>0 Then Begin
     S:=History[CurrHistory]^; { Down }
     If CurrHistory<NumberHistory Then Inc(CurrHistory);
    End;
   End;
   #8:Begin
    If S<>''Then S:=Copy(S,1,Length(S)-1);
   End;
   Else S:=S+K;
  End;
  If S[Length(S)]=#13Then Begin
   S:=Copy(S,1,Length(S)-1);
   K:=#13;
  End;
 Until K=#13;
 GotoXY(X,Y);
 WriteLn(S);
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 FillChar(History,SizeOf(History),0);
 NumberHistory:=0;
 FillChar(StackDirectory,SizeOf(StackDirectory),0);
 NumberDirectory:=0;
 Echo:=True;
 InCmd:=0;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _English:Begin
    WriteLn('4DOS : This command allows you to launch the 4DOS command interpreter.');
    WriteLn;
    WriteLn('Syntax : 4DOS [/C command]');
   End;
   _Germany:Begin
    WriteLn('4DOS : Mit diesem Befehl k”nnen Sie den 4DOS -Befehlsinterpreter starten.');
    WriteLn;
    WriteLn('Syntax : 4DOS [/C Befehl]');
   End;
   _Italian:Begin
    WriteLn('4DOS : Questo comando consente di avviare l''interprete di comando 4DOS.');
    WriteLn;
    WriteLn('Sintassi : 4DOS [/C comando]');
   End;
   _Spain:Begin
    WriteLn('4DOS : Este comando le permite iniciar el int‚rprete de comando 4DOS.');
    WriteLn;
    WriteLn('Sintaxis : 4DOS [/C comando]');
   End;
   Else Begin
    WriteLn('4DOS : Cette commande permet de lancer l''interpreteur de commande 4DOS.');
    WriteLn;
    WriteLn('Syntaxe : 4DOS [/C commande]');
   End;
  End;
 End
  Else
 If ParamCount>1Then Begin
  Option:=optNone;
  For I:=1 to ParamCount do Begin
   If(Option=optCommand)Then Begin
    CmdStr:=ParamStr(I);
    RunCommand;
    Option:=optNone;
   End
    Else
   If StrToUpper(ParamStr(I))='/C'Then Option:=optCommand
    Else
   Begin
    WriteLn('Parametre non reconnu : ',ParamStr(I));
   End;
  End;
 End
  Else
 Begin
  Terminated:=False;
  HomeMessage;
  Repeat
   ShowPrompt;
   ReadLine(CmdStr);
   RunCommand;
  Until Terminated;
 End;
END.
