{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program _4DOS;

{$M 8192,0,16384}

Uses Crt,DOS;

Const
 CommandList:Array[0..81]of String[8]=(
  'ALIAS','ATTRIB','BEEP','BREAK','CALL','CD','CDD','CHCP','CHDIR',
  'CLS','COLOR','COPY','CTTY','DATE','DEL','DELAY','DELETE',
  'DESCRIBE','DIR','DIRS','DRAWBOX','DRAWHLINE','DRAWVLINE','ECHO',
  'ENDLOCAL','ENDTEXT','ERA','ERASE','ESET','EXCEPT','EXIT','FOR','FREE',
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
 ShowASCII128,Pipe,PipeToCommand:Boolean;
 PipeFile:Text;
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
 CurrCommand,ParamList,PipeCommand:String;
 I,J:Byte;

Procedure RunCommand;Forward;

Procedure PCopy(Source,Target:Byte);Begin
 {$IFNDEF FPC}
  Move(Mem[SegB800:Source*(MemW[$0040:$4A]*25*2)],Mem[SegB800:Target*(MemW[$0040:$4A]*25*2)],MemW[$0040:$4A]*25*2)
 {$ENDIF}
End;

Function GetConvMemory:Word;
Var
 Regs:Registers;
Begin
 Regs.AX:=0;
 Intr($12,Regs);
 GetConvMemory:=Regs.AX;
End;

Function GetFreeMemory:LongInt;
Var
 Regs:Registers;
Begin
 Regs.AH:=$48;
 Regs.BX:=$FFFF;
 Intr($21,Regs);
 GetFreeMemory:=LongInt(Regs.AX)*16;
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

Function DuplicateString(C:Char;Num:Integer):String;
Var
 I:Byte;
 S:String;
Begin
 S:='';
 For I:=1 to Num do S:=S+C;
 DuplicateString:=S;
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

Function Path2Dir(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2Dir:=D;
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

Procedure Box(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Window(X1,Y1,X2,Y2);
 TextBackground((Couleur shr 4)and 15);
 {$IFDEF FPC}
  If Couleur and $80=$80 Then Begin
   TextColor((Couleur and 15)+BLINK);
  End
   Else
  TextColor(Couleur and 15);
 {$ELSE}
  TextColor(Couleur and 15);
 {$ENDIF}
 ClrScr;
 Window(1,1,80,25);
End;

Procedure FrameEmpty(X1,Y1,X2,Y2,Couleur:Byte);
Var
 I:Byte;
 ChrHori,ChrVert:Char;
 Chr218,Chr192,Chr191,Chr217:Char;
Begin
 TextBackground((Couleur shr 4)and 15);
 TextColor(Couleur and 15);
 If(ShowASCII128)Then Begin
  ChrHori:='-';
  ChrVert:='|';
  Chr218:='+';
  Chr192:='+';
  Chr191:='+';
  Chr217:='+';
 End
  Else
 Begin
  ChrHori:=#$C4;
  ChrVert:=#$B3;
  Chr218:=#218;
  Chr192:=#192;
  Chr191:=#191;
  Chr217:=#217;
 End;
 For I:=Y1+1 to Y2-1 do Begin
  GotoXY(X1,I);
  Write(ChrVert);
  GotoXY(X2,I);
  Write(ChrVert);
 End;
 GotoXY(X1+1,Y1);
 Write(DuplicateString(ChrHori,X2-X1-1));
 GotoXY(X1+1,Y2);
 Write(DuplicateString(ChrHori,X2-X1-1));
 GotoXY(X1,Y1);
 Write(Chr218);
 GotoXY(X1,Y2);
 Write(Chr192);
 GotoXY(X2,Y1);
 Write(Chr191);
 GotoxY(X2,Y2);
 Write(Chr217);
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

Procedure FreeHistory;
Var
 I:Word;
Begin
 For I:=1 to NumberHistory do FreeMem(History[I],Length(History[I]^)+1);
 FillChar(History,SizeOf(History),0);
 NumberHistory:=0;
End;

Function PushDirectory(Directory:String):Boolean;
Var
 P:StrPointer;
Begin
 If NumberDirectory>=MaxStackDirectory Then Begin
  WriteLn('Pile de rÇpertoire pleine');
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
  5:GetErrorMessage:='Accäs refuse';
  6:GetErrorMessage:='Handle de fichier invalide';
  12:GetErrorMessage:='Mode d''acces sur disque invalide';
  15:GetErrorMessage:='NumÇro de disque invalide';
  16:GetErrorMessage:='Impossible de supprimer le rÇpertoire';
  17:GetErrorMessage:='Impossible de renommer sur plusieurs volumes';
  100:GetErrorMessage:='Erreur de lecture Ö partir du disque';
  101:GetErrorMessage:='Erreur d''Çcriture sur le disque';
  102:GetErrorMessage:='Fichier non attribue';
  103:GetErrorMessage:='Le fichier n''est pas ouvert';
  104:GetErrorMessage:='Le fichier n''est pas ouvert Ö l''entrÇe';
  105:GetErrorMessage:='Le fichier n''est pas ouvert Ö la sortie';
  106:GetErrorMessage:='NumÇro invalide';
  150:GetErrorMessage:='Disque protege en Çcriture';
  151:GetErrorMessage:='PÇriphÇrique est inconnu';
  152:GetErrorMessage:='Disque pas pràt';
  153:GetErrorMessage:='Commande inconnue';
  154:GetErrorMessage:='Echec de vÇrification CRC';
  155:GetErrorMessage:='Disque invalide';
  156:GetErrorMessage:='Erreur de recherche sur disque';
  157:GetErrorMessage:='Type de mÇdia invalide';
  158:GetErrorMessage:='Secteur introuvable';
  159:GetErrorMessage:='L''imprimante n''a plus de papier';
  160:GetErrorMessage:='Erreur d''Çcriture sur le pÇripherique';
  161:GetErrorMessage:='Erreur de lecture sur le pÇripherique';
  162:GetErrorMessage:='DÇfaillance matÇrielle';
  Else GetErrorMessage:='Erreur inconnue';
 End;
End;

Procedure ExtractCommand;
Var
 I,J:Byte;
Begin
 For I:=1 to Length(CmdStr)do Begin
  If Not(CmdStr[I]in['A'..'Z','a'..'z','_','-','0'..'9'])Then Begin
   CurrCommand:=StrToUpper(Copy(CmdStr,1,I-1));
   ParamList:=TrimL(Copy(CmdStr,I,255));
   For J:=1 to Length(ParamList)do Begin
    Case ParamList[J]of
     '|':Begin
      If Not(Pipe)Then Begin
       {$I-}Assign(PipeFile,'4DOSPIPE.TMP');
       Rewrite(PipeFile);{$I-}
       If IoResult<>0 Then Begin
        WriteLn('Tuyau invalide !');
       End;
       Pipe:=True;
      End;
      PipeToCommand:=True;
      PipeCommand:=TrimL(Copy(ParamList,J+1,255));
      If J=1 Then ParamList:=''
             Else ParamList:=Copy(ParamList,1,J-1);
     End;
     '>':Begin
      If Not(Pipe)Then Begin
       {$I-}Assign(PipeFile,TrimL(Copy(ParamList,J+1,255)));
       Rewrite(PipeFile);{$I-}
       If IoResult<>0 Then Begin
        WriteLn('Tuyau invalide !');
       End
        Else
       Pipe:=True;
      End;
      If J=1 Then ParamList:=''
             Else ParamList:=Copy(ParamList,1,J-1);
     End;
    End;
   End;
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
  _Spain:WriteLn('4DOS - IntÇrprete de comando');
  Else WriteLn('4DOS - InterprÇteur de commande');
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
 WriteLn('Le paramätre suivant est invalide : ',ExtractParam(P));
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
    WriteLn('BEEP   Cette commande permet d''Çmettre un bip sonore.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('BEEP [/?]');
    WriteLn;
    WriteLn('  /?    Ce paramätre permet d''afficher l''aide sur cette commande');
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
    WriteLn('BREAK   Cette commande permet de fixer ou de demander l''Çtat du Ctrl+Break.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('BREAK [/?]');
    WriteLn;
    WriteLn('  /?    Ce paramätre permet d''afficher l''aide sur cette commande');
   End;
  End;
 End
  Else
 Begin
  GetCBreak(X);
  If(Pipe)Then Begin
   Write(PipeFile,'BREAK = ');
   If(X)Then WriteLn(PipeFile,'on')
        Else WriteLn(PipeFile,'off');
  End
   Else
  Begin
   Write('BREAK = ');
   If(X)Then WriteLn('on')
        Else WriteLn('off');
  End;
 End;
End;

Procedure CallCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ChDirCommand;
Var
 Drive:Char;
 Error:Word;
 FirstParam,Dir,CurrPath:String;
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
    WriteLn('CHDIR   Cette commande permet de fixer ou de demander le rÇpertoire courant.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('CD [/?] chemin');
    WriteLn('CHDIR [/?] chemin');
    WriteLn;
    WriteLn('  /?     Ce paramätre permet d''afficher l''aide sur cette commande');
    WriteLn(' chemin  Ce paramätre permet d''indiquer le chemin du repÇrtoire.');
   End;
  End;
 End
  Else
 If Length(FirstParam)>0Then Begin
  GetDir(0,CurrPath);
  Drive:=GetCurrentDisk;
  {$I-} ChDir(FirstParam);{$I+}
  Error:=IoResult;
  If Error<>0Then WriteLn(GetErrorMessage(Error));
  If Drive<>GetCurrentDisk Then ChDir(CurrPath);
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
    WriteLn('  /?     Ce paramätre permet d''afficher l''aide sur cette commande');
    WriteLn(' code    Ce paramätre permet d''indiquer la page de code');
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

Procedure CDDCommand;
Var
 Error:Word;
 FirstParam,Dir:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Change the current disk drive and directory.');
    WriteLn;
    WriteLn('Format:   CDD [path | -]');
   End;
   Else Begin
    WriteLn('CCD   Cette commande permet de fixer ou de demander le disque et le rÇpertoire courant.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('CDD [/?] chemin');
    WriteLn;
    WriteLn('  /?     Ce paramätre permet d''afficher l''aide sur cette commande');
    WriteLn(' chemin  Ce paramätre permet d''indiquer le chemin du repÇrtoire.');
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
    WriteLn('CLS   Cette commande permet d''effacer l''Çcran.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('CLS [/?]');
    WriteLn;
    WriteLn('  /?    Ce paramätre permet d''afficher l''aide sur cette commande');
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
    WriteLn('Paramätre requis');
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
    WriteLn('COLOR   Cette commande permet de fixer la couleur du texte et d''arriäre-plan.');
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
    WriteLn('  /?    Ce paramätre permet d''afficher l''aide sur cette commande');
   End;
  End;
 End
  Else
 Begin
  GetDate(Year,Month,Day,DayOfMonth);
  If(Pipe)Then WriteLn(PipeFile,'La date du jour est ',Year:4,'-',PadZeroLeft(Month,2),'-',PadZeroLeft(Day,2))
          Else WriteLn('La date du jour est ',Year:4,'-',PadZeroLeft(Month,2),'-',PadZeroLeft(Day,2));
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
    WriteLn('DELAY : Cette commande permet d''attendre le nombre de secondes spÇcifiÇs.');
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
 WriteLn('Nombre de paramätre invalide !');
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
    WriteLn('Paramätre requis');
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
     WriteLn('DEL   Cette commande permet d''effectuer la suppression de fichier sur un unitÇ de disque.');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('DEL [/?] fichier');
     WriteLn;
     WriteLn('    /?    Ce paramätre permet d''afficher l''aide sur cette commande');
     WriteLn(' fichier  Ce paramätre permet d''indiquer le nom du fichier a supprimer.');
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

Procedure DescribeCommand;
Var
 Found:Boolean;
 Source,Target:Text;
 P:Byte;
 CurrParam,CurrLine,CurrDescr:String;
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
   Case Language of
    _English:Begin
     WriteLn('Purpose:  Create, modify, or delete file and subdirectory descriptions');
     WriteLn;
     WriteLn('Format:   DESCRIBE file');
     Exit;
    End;
    Else Begin
     WriteLn('DESCRIBE  Cette commande permet d''ajouter une description Ö un fichier.');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('DESCRIBE fichier');
     WriteLn;
     WriteLn('    /?    Ce paramätre permet d''afficher l''aide sur cette commande');
     WriteLn(' fichier  Ce paramätre permet d''indiquer le nom du fichier a identifier.');
     Exit;
    End;
   End;
  End;
  Found:=False;
  {$I-}Assign(Source,'DESCRIPT.ION');
  Reset(Source);{$I+}
  If IoResult<>0 Then Begin
   Assign(Target,'DESCRIPT.ION');
   Rewrite(Target);
   Write('Description "',CurrParam,'": ');
   ReadLn(CurrDescr);
   WriteLn;
   WriteLn(Target,CurrParam,' ',CurrDescr);
   Close(Target);
  End
   Else
  Begin
   {$I-}Assign(Target,'DESCRIPT.TMP');
   Rewrite(Target);{$I+}
   While Not EOF(Source)do Begin
    ReadLn(Source,CurrLine);
    If(StrToUpper(CurrParam+' ')=StrToUpper(Copy(CurrLine,1,Length(CurrParam)+1)))Then Begin
     Write('Description "',CurrParam,'": ');
     ReadLn(CurrDescr);
     WriteLn;
     Found:=True;
     WriteLn(Target,CurrParam,' ',CurrDescr);
    End
     Else
    WriteLn(Target,CurrLine);
   End;
   If Not(Found)Then Begin
    Write('Description "',CurrParam,'": ');
    ReadLn(CurrDescr);
    WriteLn;
    WriteLn(Target,CurrParam,' ',CurrDescr);
   End;
   Close(Source);
   Assign(Source,'DESCRIPT.ION');
   {$I-}Erase(Source);{$I+}
   Close(Target);
   Assign(Target,'DESCRIPT.TMP');
   Rename(Target,'DESCRIPT.ION');
  End;
  If P>9Then Break;
 Until CurrParam='';
End;

Function GetDescription(Path,FileName:String):String;
Var
 Source:Text;
 CurrLine:String;
Begin
 GetDescription:='';
 {$I-}Assign(Source,Path2Dir(FExpand(Path))+'DESCRIPT.ION');
 Reset(Source);{$I+}
 If IoResult=0 Then Begin
  While Not EOF(Source)do Begin
   ReadLn(Source,CurrLine);
   If(StrToUpper(FileName+' ')=StrToUpper(Copy(CurrLine,1,Length(FileName)+1)))Then Begin
    GetDescription:=Copy(CurrLine,Length(FileName)+1,255);
    Close(Source);
    Exit;
   End;
  End;
  Close(Source);
 End;
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
     WriteLn('DIR   Cette commande permet d''afficher le contenu d''un repertoire dans l''unitÇ de disque.');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('DIR [/?] [/2|/W] [/B] [/P] [chemin]');
     WriteLn;
     WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
     WriteLn(' /2   Ce parametre permet d''afficher sur 2 colonnes');
     WriteLn(' /B   Ce parametre enleve l''entàte et les dÇtails de la fin');
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
   If(Pipe)Then Write(PipeFile,PadRight('<DIR>',9))
           Else Write(PadRight('<DIR>',9));
  End
   Else
  Write(Info.Size:9);
  UnpackTime(Info.Time,T);
  If(Pipe)Then Begin
   Write(PipeFile,' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',
         PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2),' ');
  End
   Else
  Begin
   Write(' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',PadZeroLeft(T.Day,2),' ',
         T.Hour:2,':',PadZeroLeft(T.Min,2),' ');
  End;
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
   If(Pipe)Then Begin
    WriteLn(PipeFile,'Le volume de l''unite '+CurrDrive+' est '+CurrLabel);
    WriteLn(PipeFile);
   End
    Else
   Begin
    WriteLn('Le volume de l''unite '+CurrDrive+' est '+CurrLabel);
    WriteLn;
   End;
  End;
  While DOSError=0 do Begin
   If(Pipe)Then Write(PipeFile,PadRight(Info.Name,13))
           Else Write(PadRight(Info.Name,13));
   If Info.Attr and Directory=Directory Then Begin
    If(Pipe)Then Write(PipeFile,PadRight('<DIR>',15))
            Else Write(PadRight('<DIR>',15));
   End
    Else
   Begin
    If(Pipe)Then Write(PipeFile,Info.Size:15)
            Else Write(Info.Size:15);
   End;
   UnpackTime(Info.Time,T);
   If(Pipe)Then Begin
    Write(PipeFile,' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',
            PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2));
    WriteLn(PipeFile,GetDescription(ShowDir,Info.Name));
   End
    Else
   Begin
    Write(' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',
            PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2));
    WriteLn(GetDescription(ShowDir,Info.Name));
   End;
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
   If(Pipe)Then Begin
    WriteLn(PipeFile,' Les ',TotalNumFiles,' fichier(s) utilisent ',TotalSize,' octet(s)');
    WriteLn(PipeFile,DiskFree(Byte(CurrDrive)-64):10,' octet(s) de libre');
   End
    Else
   Begin
    WriteLn(' Les ',TotalNumFiles,' fichier(s) utilisent ',TotalSize,' octet(s)');
    WriteLn(DiskFree(Byte(CurrDrive)-64):10,' octet(s) de libre');
   End;
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
    WriteLn('Paramätre requis');
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
     WriteLn('ERASE   Cette commande permet d''effectuer la suppression de fichier sur un unitÇ de disque.');
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

Procedure ForCommand;
Var
 PList,VarName,CurrMask,Mask,ForCmd:String;
 J,I:Byte;
Begin
 If ExtractParam(1)='/?'Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('FÅhrt einen Befehl fÅr jede einzelne Datei eines Satzes von Dateien aus.');
    WriteLn;
    WriteLn('FOR %Variable IN (Satz) DO Befehl [Parameter]');
    WriteLn;
    WriteLn(' %Variable  Ein ersetzbarer Parameter (bestehend aus einem einzelnen Zeichen).');
    WriteLn(' (Satz)     Ein Satz von mindestens einer Datei. Platzhalter sind zulÑssig.');
    WriteLn(' Befehl     Befehl, der fÅr jede Datei ausgefÅhrt werden soll.');
    WriteLn(' Parameter  Parameter und Optionen fÅr den angebenen Befehl.');
   End;
   _English:Begin
    WriteLn('Run a specified command for each file in a set of files');
    WriteLn;
    WriteLn('FOR %variable IN (set) DO [command-parameters]');
    WriteLn;
    WriteLn(' %variable  Specifies a replaceable parameter.');
    WriteLn(' (set)      Specifies a set of one more files. Wildcards may be used.');
    WriteLn(' command    Specifies the command to carry out for each file.');
    WriteLn(' command-parameters');
    WriteLn(' ':12,'Specifies parameters or switches for the specified commad.');
   End;
   Else Begin
    WriteLn('FOR : Cette commande permet d''effectuer le traitement d''un group de fichier');
    WriteLn;
    WriteLn('FOR %variable IN (ensemble) DO commande');
    WriteLn('FOR %%variable IN (ensemble) DO commande');
   End;
  End;
 End
  Else
 Begin
  PList:=Trim(ParamList);
  VarName:='';
  I:=1;
  If Copy(PList,1,2)='%%'Then Begin
   VarName:='%%';
   I:=3;
   While(I<=Length(PList))and(UpCase(PList[I])in['A'..'Z'])do Begin
    VarName:=VarName+PList[I];
    Inc(I);
   End;
  End
   Else
  If Copy(PList,1,1)='%'Then Begin
   VarName:='%';
   I:=2;
   While(I<=Length(PList))and(UpCase(PList[I])in['A'..'Z'])do Begin
    VarName:=VarName+PList[I];
    Inc(I);
   End;
  End
   Else
  Begin
   WriteLn('Nom de variable attendu !');
   Exit;
  End;
  While (I<=Length(PList))and(PList[I]in[#9,' '])do Inc(I);
  If StrToUpper(Copy(PList,I,3))='IN 'Then Begin
   Inc(I,3);
   While (I<=Length(PList))and(PList[I]in[#9,' '])do Inc(I);
   If PList[I]<>'('Then Begin
    WriteLn('''('' attendu !');
    Exit;
   End;
   Inc(I);
   Mask:='';
   While(I<=Length(PList))and(PList[I]<>')')do Begin
    Mask:=Mask+PList[I];
    Inc(I);
   End;
   If PList[I]<>')'Then Begin
    WriteLn(''')'' attendu !');
    Exit;
   End;
   Inc(I);
   While (I<=Length(PList))and(PList[I]in[#9,' '])do Inc(I);
   If StrToUpper(Copy(PList,I,3))='DO 'Then Begin
    Inc(I,3);
    ForCmd:=Trim(Copy(PList,I,255));
    CmdStr:='';
    CurrMask:='';
    J:=1;
    While J<=Length(Mask)do Begin
     If Mask[J]=' 'Then Begin
      If Trim(CurrMask)<>''Then Begin
       I:=1;
       While I<=Length(ForCmd)do Begin
        If Copy(ForCmd,I,Length(VarName))=VarName Then Begin
         CmdStr:=CmdStr+CurrMask;
         Inc(I,Length(VarName));
        End
         Else
        Begin
         CmdStr:=CmdStr+ForCmd[I];
         Inc(I);
        End;
       End;
       RunCommand;
       CmdStr:='';
       CurrMask:='';
      End;
     End
      Else
     CurrMask:=CurrMask+Mask[J];
     Inc(J);
    End;
    If Trim(CurrMask)<>''Then  Begin
     I:=1;
     While I<=Length(ForCmd)do Begin
      If Copy(ForCmd,I,Length(VarName))=VarName Then Begin
       CmdStr:=CmdStr+CurrMask;
       Inc(I,Length(VarName));
      End
       Else
      Begin
       CmdStr:=CmdStr+ForCmd[I];
       Inc(I);
      End;
     End;
     If CmdStr<>''Then RunCommand;
    End;
   End
    Else
   WriteLn('Mot rÇservÇ DO attendu');
  End
   Else
  WriteLn('Mot rÇservÇ IN attendu');
 End;
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
                    'les statistiques d''un unitÇ de disque');
    WriteLn;
    WriteLn('Syntaxe : FREE [/?]');
    WriteLn('          FREE [unite:]');
    WriteLn;
    WriteLn(' unite:   Affiche les statistiques d''un unitÇ');
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
 Mode:(_None,_AddHistory,_ReadHistory);
 P,I:Integer;
 HistoryFile:Text;
 CurrLine,CurrParam,FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Display, add to, clear, or read the history list.');
    WriteLn;
    WriteLn('Format:   HISTORY [/?] [/A command] [/R filename]');
   End;
   Else Begin
    WriteLn('HISTORY   Cette commande permet d''afficher l''historique des commandes.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('HISTORY [/?] [/A commande] [/R nomdufichier] [/F]');
    WriteLn;
    WriteLn('  /?              Ce paramätre permet d''afficher l''aide sur cette commande');
    WriteLn('  /A commande     Ce paramätre permet d''ajouter un historique');
    WriteLn('  /F              Ce paramätre permet de vider l''historique');
    WriteLn('  /R nomdufichier Ce paramätre permet de charger un historique');
   End;
  End;
 End
  Else
 If FirstParam=''Then Begin
  For I:=1 to NumberHistory do Begin
   If(Pipe)Then WriteLn(PipeFile,History[I]^)
           Else WriteLn(History[I]^);
  End;
 End
  Else
 If(StrToUpper(FirstParam)='/P')and(ExtractParam(2)='')Then Begin
  P:=1;
  For I:=1 to NumberHistory do Begin
   If(Pipe)Then WriteLn(PipeFile,History[I]^)
           Else WriteLn(History[I]^);
   Inc(P);
   If P=25 Then Begin
    P:=0;
    Case Language of
     _English:Begin
      Write('Press ESC to quit or another key to continue...');
     End;
     Else Begin
      Write('Presse ESC pour quitter ou une autre touche pour continuer...');
     End;
    End;
    If ReadKey=#27 Then Begin
     WriteLn;
     Exit;
    End;
    WriteLn;
   End;
  End;
 End
  Else
 Begin
  Mode:=_None;
  P:=0;
  Repeat
   Inc(P);
   CurrParam:=ExtractParam(P);
   Case Mode of
    _AddHistory:Begin
     AddHistory(CurrParam);
     Mode:=_None;
    End;
    _ReadHistory:Begin
     {$I-}Assign(HistoryFile,CurrParam);
     Reset(HistoryFile);{$I+}
     If IoResult=0 Then Begin
      While Not EOF(HistoryFile)do Begin
       ReadLn(HistoryFile,CurrLine);
       AddHistory(CurrLine);
      End;
      Close(HistoryFile);
     End
      Else
     WriteLn('Erreur de lecture d''historique');
     Mode:=_None;
    End;
    Else Begin
     If StrToUpper(CurrParam)='/A'Then Mode:=_AddHistory Else
     If StrToUppeR(CurrParam)='/F'Then FreeHistory Else
     If StrToUpper(CurrParam)='/R'Then Mode:=_ReadHistory
      Else
     If CurrParam<>''Then Begin
      WriteLn('Paramätre invalide : ',CurrParam);
      Exit;
     End;
    End;
   End;
   If P>9Then Break;
  Until CurrParam='';
 End;
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
  WriteLn(LongInt(GetConvMemory) shr 10:15,' octets total de memoire RAM');
  WriteLn(GetFreeMemory:15,' octets de libre');
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
    WriteLn('Paramätre requis');
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   Case Language of
    _English:Begin
     WriteLn('Purpose:  Create a subdirectory.');
     WriteLn;
     WriteLn('MKDIR [/?] path');
    End;
    Else Begin
     WriteLn('MKDIR   Cette commande permet de creer un repertoire.');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('MKDIR [/?] nomrepertoire');
     WriteLn;
     WriteLn('  nomrepertoire   Ce parametre permet d''indiquer le nom du repertoire');
     WriteLn('            /?    Ce parametre permet d''afficher l''aide sur cette commande');
    End;
   End;
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
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Move files to a new directory and drive.');
    WriteLn;
    WriteLn('Format:   MOVE source destination');
   End;
   Else Begin
    WriteLn('MOVE : Cette commande permet de deplacer un fichier.');
    WriteLn;
    WriteLn('Syntaxe : MOVE source destination');
   End;
  End;
 End
  Else
 If(ExtractParam(1)<>'')and(ExtractParam(2)<>'')Then Begin
  If Not MoveFile(ExtractParam(1),ExtractParam(2))Then Begin
   WriteLn('Erreur de dÇplacement du fichier.');
  End;
 End
  Else
 WriteLn('Nombre de parametre invalide');
End;

Procedure PathCommand;
Var
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Display or alter the list of directories that 4DOS will');
    WriteLn('          search for executable files, batch files, and files with');
    WriteLn('          executable extensions that are not in the current directory.');
    WriteLn;
    WriteLn('PATH [/?]');
   End;
   Else Begin
    WriteLn('PATH   Cette commande permet d''afficher les chemins de recherches.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('PATH [/?]');
    WriteLn;
    WriteLn('   /?    Ce parametre permet d''afficher l''aide sur cette commande');
   End;
  End;
 End
  Else
 Begin
  WriteLn(GetEnv('PATH'));
 End;
End;

Procedure PauseCommand;
Var
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Suspend batch file or alias extension.');
    WriteLn;
    WriteLn('PAUSE [text]');
   End;
   Else Begin
    WriteLn('PAUSE   Cette commande permet d''afficher un message de pause et une ',
            'attente d''une action utilisateur pour poursuivre.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('PAUSE [/?] [texte]');
    WriteLn;
    WriteLn('   /?    Ce paramätre permet d''afficher l''aide sur cette commande');
    WriteLn(' texte   Ce paramätre permet d''indiquer le message de remplacement.');
   End;
  End;
 End
  Else
 If FirstParam<>''Then Begin
  WriteLn(ParamList);
  ReadKey;
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
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Suspend batch file or alias extension');
    WriteLn;
    WriteLn('POPD [/?]');
   End;
   Else Begin
    WriteLn('POPD   Cette commande permet de restaurer le repertoire.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('POPD [/?]');
    WriteLn;
    WriteLn('  /?     Ce parametre permet d''afficher l''aide sur cette commande');
   End;
  End;
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
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Save the current disk drive and directory, optionnally changing');
    WriteLn(' ':10,'to a new drive and directory.');
    WriteLn;
    WriteLn('Format:   PUSHD [path]');
   End;
   Else Begin
    WriteLn('PUSHD   Cette commande permet de sauver le repertoire.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('PUSHD [/?] chemin');
    WriteLn;
    WriteLn('  /?     Ce parametre permet d''afficher l''aide sur cette commande');
    WriteLn(' chemin  Ce parametre permet d''indiquer le repertoire a mettre a la place.');
   End;
  End;
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
    WriteLn('Paramätre requis');
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   Case Language of
    _English:Begin
     WriteLn('Purpose:  Remove one or more subdirectories.');
     WriteLn;
     WriteLn('Format:   RMDIR path');
    End;
    Else Begin
     WriteLn('RMDIR   Cette commande permet de supprimer un repertoire vide.');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('RMDIR [/?] nomrepertoire');
     WriteLn;
     WriteLn('  /?           Ce parametre permet d''afficher l''aide sur cette commande');
     WriteLn('nomrepertoire  Ce parametre permet d''indiquer le nom du repertoire');
    End;
   End;
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
   Case Language of
    _English:Begin
     WriteLn('Purpose:  Rename files.');
     WriteLn;
     WriteLn('Format:   REN old_name new_name');
    End;
    Else Begin
     WriteLn('RENAME   Cette commande permet de renommer un fichier.');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('RENAME [/?] anciennom nouveaunom');
     WriteLn;
     WriteLn(' /?         Ce parametre permet d''afficher l''aide sur cette commande');
     WriteLn('anciennom   Ce parametre permet d''indiquer l''ancien nom');
     WriteLn('nouveaunom  Ce parametre permet d''indiquer le nouveau nom');
    End;
   End;
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
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Position the cursor on the screen and optionnally display a');
    WriteLn(' ':10,'message.');
    WriteLn;
    WriteLn('Format:   SCREEN row column [text]');
   End;
   Else Begin
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
   End;
  End;
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
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Position text on the screen and display it in color.');
    WriteLn;
    WriteLn('Format:   SCRPUT row column [BRIGHT] [BLINK] fg ON bg message');
   End;
   Else Begin
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
   End;
  End;
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
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Display, create, modify, or delete environment variables.');
    WriteLn;
    WriteLn('Format:   SET [/?] [/P]');
   End;
   Else Begin
    WriteLn('SET   Cette commande permet de fixer ou demander le contenu des ',
            'variables d''environnement du systeme d''exploitation');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('SET [/?] [/P]');
    WriteLn;
    WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
    WriteLn(' /P   Ce parametre permet d''effectuer une pause entre chaque page');
   End;
  End;
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
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Display or set the current system time.');
    WriteLn;
    WriteLn('Format:   TIME [/?]');
   End;
   Else Begin
    WriteLn('TIME   Cette commande permet de fixer ou de demander l''heure du systeme d''exploitation');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('TIME [/?]');
    WriteLn;
    WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
   End;
  End;
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
   Case Language of
    _English:Begin
     WriteLn('Purpose:  Find the full, true path and file name for a file.');
     WriteLn;
     WriteLn('Format:   TRUENAME file');
    End;
    Else Begin
     WriteLn('TRUENAME   Cette commande permet d''afficher le nom complet d''un unite, repertoire ou d''un nom de fichier');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('TRUENAME [/?] [chemin]');
     WriteLn;
     WriteLn(' /?     Ce parametre permet d''afficher l''aide sur cette commande');
     WriteLn('chemin  Ce parametre permet d''indiquer le nom du chemin a analyser');
    End;
   End;
   Exit;
  End;
  WriteLn(FExpand(CurrParam));
  If P>9Then Break;
 Until CurrParam='';
End;

Procedure TypeCommand;
Var
 Option:Set of (ShowNumberLine,_Pause);
 L:LongInt;
 ScrLine,I,P:Byte;
 Err:Word;
 Handle:Text;
 CurrParam,CurrLine:String;
Begin
 Option:=[];
 P:=0;
 L:=1;
 ScrLine:=1;
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If StrToUpper(CurrParam)='/L'Then Include(Option,ShowNumberLine) Else
  If StrToUpper(CurrParam)='/P'Then Include(Option,_Pause) Else
  If P>9Then Break;
 Until CurrParam='';
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If(Length(CurrParam)=0)and(P=1)Then Begin
   WriteLn('La syntaxe est incorrecte');
   Exit;
  End;
  If CurrParam='/?'Then Begin
   Case Language of
    _English:Begin
     WriteLn('Purpose:  Display the contents of the specified file(s).');
     WriteLn;
     WriteLn('TYPE [file] [/L] [/P]');
    End;
    Else Begin
     WriteLn('TYPE   Cette commande permet d''afficher le contenu d''un fichier');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('TYPE [/?] [fichier] [/L] [/P]');
     WriteLn;
     WriteLn('  /?     Ce parametre permet d''afficher l''aide sur cette commande');
     WriteLn('  /L     Ce paramätre permet d''afficher les numÇros de ligne');
     WriteLn('  /P     Ce paramätre permet de faire une pause entre chaque Çcran');
     WriteLn('fichier  Ce parametre permet d''indiquer le nom du fichier a afficher');
    End;
   End;
   Exit;
  End;
  If StrToUpper(CurrParam)='/L'Then Begin
  End
   Else
  If StrToUpper(CurrParam)='/P'Then Begin
  End
   Else
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
    If(ShowNumberLine in Option)Then Begin
     Write(L:4,' : ');
     Inc(L);
    End;
    ReadLn(Handle,CurrLine);
    If(Pipe)Then WriteLn(PipeFile,CurrLine)
            Else WriteLn(CurrLine);
    If(_Pause in Option)Then Begin
     Inc(ScrLine);
     If ScrLine=25 Then Begin
      ScrLine:=0;
      Case Language of
       _English:Begin
        Write('Press ESC to quit or another key to continue...');
       End;
       Else Begin
        Write('Presse ESC pour quitter ou une autre touche pour continuer...');
       End;
      End;
      If ReadKey=#27 Then Begin
       WriteLn;
       Exit;
      End;
      WriteLn;
     End;
    End;
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
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Display the current command processor and operating system');
    WriteLn(' ':10,'versions.');
    WriteLn;
    WriteLn('Format:   VER [/?]');
   End;
   Else Begin
    WriteLn('VER   Cette commande permet de demander la version du systeme d''exploitation.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('VER [/?]');
    WriteLn;
    WriteLn(' /?    Ce parametre permet d''afficher l''aide sur cette commande');
   End;
  End;
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
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Enable or disable disk write verification or display the');
    WriteLn(' ':10,'verification state.');
    WriteLn;
    WriteLn('Format:   VERIFY [ON | OFF]');
   End;
   Else Begin
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
   End;
  End;
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
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Display disk volume label(s).');
    WriteLn;
    WriteLn('Format:   VOL [d:] ...');
   End;
   Else Begin
    WriteLn('VOL   Cette commande permet d''afficher le nom du volume d''une unite de disque.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('VOL [/?] [unite:]');
    WriteLn;
    WriteLn(' /?      Ce parametre permet d''afficher l''aide sur cette commande');
    WriteLn(' unite:  Ce paramtre permet d''indiquer la lettre d''unite de disque');
   End;
  End;
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

Procedure UnknownCommand;
Var
 Err:Word;
Begin
 Exec(CurrCommand,ParamList);
 Err:=DosError;
 Case Err of
  0:;
  2:Case Language of
   _English: WriteLn('Bad command or file name');
   Else WriteLn('Commande ou nom de fichier non reconnu');
  End;
  Else Write(GetErrorMessage(Err));
 End;
 WriteLn;
End;

Procedure RunCommand;
Label
 Restart;
Var
 LastEcho:Boolean;
 FileBat:Text;
 OY:Byte;
 Error:Word;
 PipeS:String;
Begin
 AddHistory(CmdStr);
  { Change d'unitÇ de disque A:, B:, C:, D:,... }
 If(Length(CmdStr)=2)and(CmdStr[2]=':')and(CmdStr[1]in['A'..'Z','a'..'z'])Then Begin
  {$I-}GetDir(Ord(UpCase(CmdStr[1]))-64,PipeS);
  If PipeS<>''Then ChDir(PipeS)
              Else ChDir(CmdStr+'\');{$I+}
  Error:=IoResult;
  If Error<>0Then WriteLn(GetErrorMessage(Error));
  Exit;
 End;
  { Recherche une commande interne }
Restart:
 ExtractCommand;
 CommandFound:=False;
 For J:=Low(CommandList) to High(CommandList) do Begin
  If(PipeToCommand)and(StrToUpper(CurrCommand)='MORE')Then Begin
   Reset(PipeFile);
   OY:=1;
   While Not EOF(PipeFile)do Begin
    ReadLn(PipeFile,PipeS);
    WriteLn(PipeS);
    Inc(OY);
    If OY=25 Then Begin
     Write('Presse ESC pour quitter ou une autre touche pour continuer...');
     If ReadKey=#27 Then Begin
      WriteLn;
      Break;
     End;
     OY:=1;
    End;
   End;
   Close(PipeFile);
   Pipe:=False;
   PipeToCommand:=False;
   CommandFound:=True;
   Exit;
  End
   Else
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
    17:DescribeCommand;
    18:DirCommand;
    19:DirsCommand;
    20:DrawBoxCommand;
    21:DrawHLineCommand;
    22:DrawVLineCommand;
    23:EchoCommand;
    24:EndLocalCommand;
    25:EndTextCommand;
    26:EraseCommand;
    27:EraseCommand;
    28:ESetCommand;
    29:ExceptCommand;
    30:Terminated:=ExitCommand;
    31:ForCommand;
    32:FreeCommand;
    33:GlobalCommand;
    34:GosubCommand;
    35:GotoCommand;
    36:HelpCommand;
    37:HistoryCommand;
    38:IfCommand;
    39:IFFCommand;
    40:InkeyCommand;
    41:InputCommand;
    42:KeyStackCommand;
    43:LoadHighCommand;
    44:LoadBTMCommand;
    45:LoadHighCommand;
    46:LogCommand;
    47:MkDirCommand;
    48:MemoryCommand;
    49:MkDirCommand;
    50:MoveCommand;
    51:PathCommand;
    52:PauseCommand;
    53:PromptCommand;
    54:PushDCommand;
    55:QuitCommand;
    56:RmDirCommand;
    57:RemCommand;
    58:RenameCommand;
    59:RenameCommand;
    60:ReturnCommand;
    61:RmDirCommand;
    62:ScreenCommand;
    63:ScrPutCommand;
    64:SetCommand;
    65:SetDosCommand;
    66:SetLocalCommand;
    67:ShiftCommand;
    68:SwappingCommand;
    69:TeeCommand;
    70:TextCommand;
    71:TimeCommand;
    72:TimerCommand;
    73:TrueNameCommand;
    74:TypeCommand;
    75:UnaliasCommand;
    76:UnsetCommand;
    77:VerCommand;
    78:VerifyCommand;
    79:VolCommand;
    80:YCommand;
    81:PopDCommand;
   End;
   If J<=High(CommandList)Then Begin
    CommandFound:=True;
    If InCmd=0Then WriteLn;
    Break;
   End;
  End;
 End;
 If(PipeToCommand)Then Begin
  If Not(CommandFound)Then Begin
   WriteLn('Commande non supportÇ dans un contexte du tuyau');
   Exit;
  End;
  CmdStr:=PipeCommand;
  PipeCommand:='';
  Goto Restart;
 End;
 If(Pipe)Then Begin
  If Not(CommandFound)Then Begin
   WriteLn('Redirection non supportÇ dans un contexte du tuyau');
   Exit;
  End;
  Pipe:=False;
  Close(PipeFile);
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

Function PopupHistory:String;
Var
 K:Char;
 I:Byte;
 P,Y:LongInt;

 Procedure ShowItem;Begin
  TextColor(7);
  TextBackground(Black);
  GotoXY(44,3+Y);
  Write(PadRight(Copy(History[P]^,1,34),34));
  GotoXY(44,3+Y);
 End;

 Procedure HideItem;Begin
  TextColor(0);
  TextBackground(7);
  GotoXY(44,3+Y);
  Write(PadRight(Copy(History[P]^,1,34),34));
 End;

 Procedure RefreshList;
 Var
  J:Byte;
 Begin
  TextColor(0);
  TextBackground(7);
  For J:=1 to 19 do Begin
   GotoXY(44,2+J);
   Write(PadRight(Copy(History[P-Y+J-1]^,1,34),34));
  End;
 End;

Begin
 PCopy(0,1);
 P:=1;Y:=0;
 PopupHistory:='';
 If NumberHistory<20 Then Begin
  Box(42,2,78,NumberHistory+3,$70);
  FrameEmpty(42,2,78,NumberHistory+3,$70);
 End
  Else
 Begin
  Box(42,2,78,22,$70);
  FrameEmpty(42,2,78,22,$70);
 End;
 For I:=1 to NumberHistory do Begin
  If I>=20 Then Break;
  GotoXY(44,2+I);
  Write(History[I]^);
 End;
 ShowItem;
 Repeat
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #72:If P>1 Then Begin { Up }
     HideItem;
     Dec(P);
     If Y>0 Then Dec(Y)
            Else RefreshList;
     ShowItem;
    End;
    #80:If P<NumberHistory Then Begin { Down }
     HideItem;
     Inc(P);
     If Y<18 Then Inc(Y)
             Else RefreshList;
     ShowItem;
    End;
   End;
   #13:Begin
    PopupHistory:=History[P]^;
    Break;
   End;
  End;
 Until K=#27;
 If NumberHistory<20 Then Begin
  Box(42,2,78,NumberHistory+3,$07);
 End
  Else
 Box(42,2,78,22,$07);
 PCopy(1,0);
End;

Procedure ReadLine(Var S:String);
Var
 Rec:SearchRec;
 K:Char;
 X,Y,I:Byte;
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
    #61:If NumberHistory>0 Then Begin { F3 }
     S:=History[NumberHistory]^;
    End;
    #72:If NumberHistory>0 Then Begin
     S:=History[CurrHistory]^; { Up }
     If CurrHistory>1 Then Dec(CurrHistory);
    End;
    #73,#81:If NumberHistory>0 Then Begin { PgUp/PgDn }
     S:=PopupHistory;
    End;
    #80:If NumberHistory>0 Then Begin
     S:=History[CurrHistory]^; { Down }
     If CurrHistory<NumberHistory Then Inc(CurrHistory);
    End;
   End;
   #8:Begin
    If S<>''Then S:=Copy(S,1,Length(S)-1);
   End;
   #9:If S<>''Then Begin
    For I:=Length(S) downto 1 do Begin
     If S[I]=' 'Then Begin
      FindFirst(Copy(S,I+1,255)+'*.*',AnyFile,Rec);
      If DosError=0 Then Begin
       S:=Copy(S,1,I)+Rec.Name;
      End;
      Break;
     End;
    End;
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
 ShowASCII128:=False;
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ELSE}
   ShowASCII128:=True;
  {$ENDIF}
 {$ENDIF}
 FillChar(History,SizeOf(History),0);
 NumberHistory:=0;
 FillChar(StackDirectory,SizeOf(StackDirectory),0);
 NumberDirectory:=0;
 Echo:=True;Pipe:=False;PipeToCommand:=False;
 InCmd:=0;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _English:Begin
    WriteLn('4DOS : This command allows you to launch the 4DOS command interpreter.');
    WriteLn;
    WriteLn('Syntax : 4DOS [/C command]');
   End;
   _Germany:Begin
    WriteLn('4DOS : Mit diesem Befehl kînnen Sie den 4DOS -Befehlsinterpreter starten.');
    WriteLn;
    WriteLn('Syntax : 4DOS [/C Befehl]');
   End;
   _Italian:Begin
    WriteLn('4DOS : Questo comando consente di avviare l''interprete di comando 4DOS.');
    WriteLn;
    WriteLn('Sintassi : 4DOS [/C comando]');
   End;
   _Spain:Begin
    WriteLn('4DOS : Este comando le permite iniciar el intÇrprete de comando 4DOS.');
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
