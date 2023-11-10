{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program TRSDOS;

Uses Crt,DOS;

Const
 CommandList:Array[0..26]of String[8]=(
  'ATTRIB','AUTO','BACKUP','BASIC','BASIC2','CLOCK','COPY',
  'DATE','DEBUG','DEVICE','DIR','DISKDUMP','DUMP','EXIT','FORMAT',
  'FREE','KILL','LIB','LIST','LOAD','PRINT','PROT','RENAME',
  'TAPEDISK','TIME','TRACE','VERIFY'
 );

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 InCmd:Byte;
 Option:(optNone,optCommand);
 Echo:Boolean;
 CommandFound,Terminated:Boolean;
 CmdStr:String;
 CurrCommand,ParamList:String;
 I,J:Byte;
 Clock:Boolean;
 AttrAdd,AttrRemove:Word;
 SubDirectory,ReadOnlyFlag:Boolean;

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

Function DuplicateChar(Chr:Char;Count:Byte):String;
Var
 S:String;
 I:Byte;
Begin
 S:='';
 For I:=1 to Count do S:=S+Chr;
 DuplicateChar:=S;
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

Function FileExist(Name:String):Boolean;
Var
 Rec:SearchRec;
Begin
 FindFirst(Name,AnyFile,Rec);
 FileExist:=DosError=0;
End;

Function GetCurrentDisk:Char;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 GetCurrentDisk:=CurrentDir[1];
End;

Function Path2Drive(Path:String):Char;Begin
 Path:=FExpand(Path);
 Path2Drive:=Path[1];
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

Function Path2Ext(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2Ext:=E;
End;

Function SetPath4AddFile(Path:String):String;Begin
 If Path=''Then GetDir(0,Path);
 If Path[Length(Path)]<>'\'Then Path:=Path+'\';
 SetPath4AddFile:=Path;
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
 FileSpec:=FExpand(FileSpec);
 FindFirst(FileSpec,AnyFile,Info);
 Found:=False;
 While DOSError=0 do Begin
  Found:=True;
  If Info.Attr and Directory=Directory Then Begin
   If(SubDirectory)Then Begin
    If Not((Info.Name='.')or(Info.Name='..')or(Info.Name=''))Then Begin
     SetAttributFiles(SetPath4AddFile(Path2Dir(FileSpec)+Info.Name)+'*.*');
    End;
   End;
  End
   Else
  Begin
   Assign(CurrFile,Path2Dir(FileSpec)+Info.Name);
   SetAttribut(CurrFile);
  End;
  FindNext(Info);
 End;
 If Not Found Then WriteLn('Aucun resultat trouve');
End;

Procedure ShowAttribut;
Var
 Info:SearchRec;
 CurrName:String;
Begin
 FindFirst('*.*',AnyFile and Not Directory,Info);
 While DOSError=0 do Begin
  CurrName:=Info.Name;
  ChangeChar(CurrName,'.','/');
  Write(PadRight(CurrName,18));
  If Info.Attr and ReadOnly=ReadOnly Then Write('P') Else Write(' ');
  Write(' ');
  FindNext(Info);
 End;
End;

Procedure HomeMessage;Begin
 WriteLn;
 WriteLn('Clone de l''interpreteur de commande TRSDOS');
 WriteLn;
End;

Procedure ShowPrompt;Begin
 WriteLn('DOS Ready');
End;

Procedure InvalidParam(P:Byte);Begin
 WriteLn('Le parametre suivant est invalide : ',ExtractParam(P));
End;

Procedure ATTRIBCommand;
Var
 P,I:Integer;
 CurrParam:String;
Begin
 If ExtractParam(1)='/?'Then Begin
  WriteLn('ATTRIB : Cette commande permet de fixer les attributs de ',
                    'protection');
  WriteLn;
  WriteLn('Syntaxe: ATTRIB [/?]');
  WriteLn('         ATTRIB filespec (PROT=READ)');
  WriteLn;
  WriteLn(' (PROT=READ)  Fixe en lecture seulement');
 End
  Else
 If ExtractParam(1)<>''Then Begin
  SubDirectory:=False;
  P:=0;
  Repeat
   Inc(P);
   CurrParam:=ExtractParam(P);
   If CurrParam=''Then Break;
   If StrToUpper(CurrParam)='(PROT=READ)'Then Begin
    ReadOnlyFlag:=True;
   End;
  Until CurrParam='';
  If(ReadOnlyFlag)Then AttrAdd:=ReadOnly
                  Else AttrRemove:=ReadOnly;
  P:=0;
  Repeat
   Inc(P);
   CurrParam:=ExtractParam(P);
   If CurrParam=''Then Break;
   If StrToUpper(CurrParam)<>'(PROT=READ)'Then Begin
    SetAttributFiles(CurrParam);
   End;
  Until CurrParam='';
 End
  Else
 ShowAttribut;
End;

Procedure AUTOCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BACKUPCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BASICCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BASIC2Command;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CLOCKCommand;
Var
 FirstParam:String;
 X:Boolean;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('CLOCK   Cette commande permet d''afficher l''horloge … l''‚cran.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('CLOCK [/?] [(OFF)|(ON)]');
  WriteLn;
  WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' (OFF)  Ce parametre permet d''activer l''horloge');
  WriteLn(' (ON)   Ce parametre permet de desactiver l''horloge');
 End
  Else
 If StrToUpper(ParamList)='(OFF)'Then Clock:=False Else
 If StrToUpper(ParamList)='(ON)'Then Clock:=True
  Else
 If ParamList=''Then Begin
  Clock:=True;
 End
  Else
 WriteLn('ParamŠtre invalide !');
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

Procedure DEBUGCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DEVICECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DirCommand;
Const
 Mon:Array[1..12]of String[3]=('Jan','Fev','Mar','Avr','Mai','Jui',
                               'Jul','Aou','Sep','Oct','Nov','Dec');
Var
 P:Byte;
 NumFiles:LongInt;
 Info:SearchRec;
 T:DateTime;
 Option:Set of (Pause,Subdirectory,Lower,Brief,Description);
 Column:Set Of (Double,Width);
 TotalNumFiles,TotalSize:LongInt;
 CurrName,CurrParam,ShowDir,CurrLabel:String;
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
   WriteLn('DIR [/?] [chemin]');
   WriteLn;
   WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
   Exit;
  End
   Else
  ShowDir:=CurrParam;
  If P>99Then Break;
 Until CurrParam='';
 CurrDrive:=Path2Drive(ShowDir);
 CurrLabel:=GetDiskLabel(Byte(CurrDrive)-64);
 P:=0;
 FindFirst(ShowDir,AnyFile,Info);
 Write('Unite :',Byte(CurrDrive)-65,', DDEN, Libre = ');
 Write(DiskFree(Byte(CurrDrive)-64)/1024:0:2,'K / ');
 WriteLn(DiskSize(Byte(CurrDrive)-64)/1024:0:2,'K');
 WriteLn('Specfichier  MOD Attr   Prot  LRL  #Enrs   EOF   Taille fichier  Ext  Date mod');
 WriteLn(DuplicateChar('-',79));
 NumFiles:=0;
 While DOSError=0 do Begin
  If Not((Info.Name='.')or(Info.Name='..'))Then Begin
   If(Info.Attr and Directory<>Directory)Then Inc(NumFiles);
   CurrName:=Info.Name;
   ChangeChar(CurrName,'.','/');
   Write(PadRight(CurrName,16));
   If(Info.Attr and ReadOnly=ReadOnly)Then Write('P':7)
                                      Else Write(' ':7);
   Write(' ');
   If Path2Ext(Info.Name)='.EXE'Then Write('EXEC')
                                Else Write('READ');
   Write(' ',256:4);
   Write(Info.Size shr 9:7);
   Write(0:6);
   Write(Info.Size/1024:16:2,'K');
   Write(1:5,' ');
   UnpackTime(Info.Time,T);
   Write(' ',T.Day:2,'-',Mon[T.Month],'-',Copy(PadZeroLeft(T.Year,2),3,2));
   WriteLn;
  End;
  FindNext(Info);
 End;
 WriteLn(DuplicateChar('=',79));
 WriteLn(' ':12,NumFiles,' f1ichiers');
End;

Procedure DISKDUMPCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DUMPCommand;
Var
 I:Word;
 OutFile:File;
 CurrParam:String;
Begin
 {$IFDEF FPC}
  WriteLn('Cette commande n''est pas mise en oeuvre en Free Pascal');
 {$ELSE}
 CurrParam:=ExtractParam(1);
 If(CurrParam='/?')or(CurrParam='--help')or(CurrParam='-h')Then Begin
  Case Language of
   _English:Begin
    WriteLn('DUMP : This command takes a snapshot of RAM 640K and sends ',
                   'it to the filename specified.');
    WriteLn;
    WriteLn('DUMP [/?] filename');
    WriteLn;
    WriteLn('/?          = Help for this command');
    WriteLn('filename    = Output filename');
   End;
   Else Begin
    WriteLn('DUMP : Cette commande permet de sauvegarder le contenu de la ',
                   'la m‚moire conventionnelle de 640 Ko et l''envoi dans ',
                   'un fichier.');
    WriteLn;
    WriteLn('Syntaxe : DUMP [/?] filename');
    WriteLn;
    WriteLn(' /?          Ce paramŠtre permet de founir de l''aide sur cette commande.');
    WriteLn('filename     Ce paramŠtre permet d''indiquer le fichier de sortie');
   End;
  End;
 End
  Else
 Begin
  Assign(OutFile,CurrParam);
  Rewrite(OutFile,1);
  For I:=0 to ((640 div $40) - $1)do Begin
   BlockWrite(OutFile,Mem[I:$0000],$8000);
   BlockWrite(OutFile,Mem[I:$8000],$8000)
  End;
  Close(OutFile)
 End;
 {$ENDIF}
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

Procedure FORMATCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure FREECommand;
Var
 LabelName,FirstParam:String;
 I:Integer;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('FREE  Cette commande permet d''afficher l''espace de libre ',
                 'sur les unites.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('FREE [/?]');
 End
  Else
 Begin
  For I:=0 to 3 do Begin
   If DiskSize(I+1)=-1Then Begin
    WriteLn('Disque :',I,'  [Pas disque]');
   End
    Else
   Begin
    Write('Disque :',I,'  ');
    LabelName:=GetDiskLabel(I+1);
    If LabelName=''Then Write('PAS NOM ')
                   Else Write(LabelName:8);
    Write('  Espace libre = ',(DiskFree(I+1)/1024):0:2,'K/  ',(DiskSize(I+1)/1024):0:2,'K');
    WriteLn;
   End;
  End;
 End;
End;

Procedure KILLCommand;
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
    _Germany:Begin
     WriteLn('L”scht eine oder mehrere Dateien.');
     WriteLn;
     WriteLn('KILL [/?] Datainame');
    End;
    _English:Begin
     WriteLn('Purpose:  Erase one file');
     WriteLn;
     WriteLn('Format:   KILL [/?] file');
     Exit;
    End;
    Else Begin
     WriteLn('KILL   Cette commande permet d''effectuer la suppression de fichier sur un unit‚ de disque.');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('KILL [/?] fichier');
     WriteLn;
     WriteLn('    /?    Ce paramŠtre permet d''afficher l''aide sur cette commande');
     WriteLn(' fichier  Ce paramŠtre permet d''indiquer le nom du fichier a supprimer.');
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

Procedure LIBCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LISTCommand;
Var
 I,P:Integer;
 Handle:Text;
 CurrLine,CurrParam:String;
Begin
 CurrParam:=ExtractParam(1);
 If(CurrParam='/?')or(CurrParam='--help')or(CurrParam='-h')Then Begin
  WriteLn('LIST : Cette commande permet d''afficher le contenu du fichier.');
  WriteLn;
  WriteLn('Syntaxe : LIST [fichier]');
 End
  Else
 If CurrParam<>''Then Begin
  P:=0;
  Repeat
   Inc(P);
   CurrParam:=ExtractParam(P);
   If CurrParam<>''Then Begin
    Assign(Handle,CurrParam);
    {$I-}Reset(Handle);{$I+}
    If IOResult=0Then Begin
     While NOT EOF(Handle)do Begin
      ReadLn(Handle,CurrLine);
      WriteLn(CurrLine);
     End;
     Close(Handle);
    End
     Else
    WriteLn('Impossible de lire ',ParamStr(I));
   End;
   If P>9Then Break;
  Until CurrParam='';
 End
  Else
 Begin
  Repeat
   ReadLn(Input,CurrLine);
   WriteLn(CurrLine);
  Until EOF;
 End;
End;

Procedure LOADCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PRINTCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PROTCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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

Procedure TAPEDISKCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TimeCommand;
Var
 FirstParam:String;
 Hour,Minute,Second,CentSec:Word;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('TIME   Cette commande permet de fixer ou l''heure du systeme d''exploitation');
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

Procedure TRACECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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
  WriteLn('VERIFY [/?] [(OFF)|(ON)]');
  WriteLn;
  WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' (OFF)  Ce parametre permet d''activer la verification');
  WriteLn(' (ON)   Ce parametre permet de desactiver la verification');
 End
  Else
 If StrToUpper(ParamList)='(OFF)'Then SetVerify(False) Else
 If StrToUpper(ParamList)='(ON)'Then SetVerify(True)
  Else
 Begin
  GetVerify(X);
  Write('VERIFY = ');
  If(X)Then WriteLn('on')
       Else WriteLn('off');
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
 FileJcl:Text;
 Error:Word;
 PipeS:String;
Begin
  { Change d'unit‚ de disque :A, :B, :C, :D,... }
 If(Length(CmdStr)=2)and(CmdStr[1]=':')and(CmdStr[2]in['A'..'Z','a'..'z'])Then Begin
  {$I-}GetDir(Ord(UpCase(CmdStr[2]))-64,PipeS);
  If PipeS<>''Then ChDir(PipeS)
              Else ChDir(CmdStr+'\');{$I+}
  Error:=IoResult;
  If Error<>0Then WriteLn(GetErrorMessage(Error));
  Exit;
 End;
 ExtractCommand;
 CommandFound:=False;
 For J:=Low(CommandList) to High(CommandList) do Begin
  If CurrCommand=CommandList[J]Then Begin
   Case(J)of
    0:ATTRIBCommand;
    1:AUTOCommand;
    2:BACKUPCommand;
    3:BASICCommand;
    4:BASIC2Command;
    5:CLOCKCommand;
    6:COPYCommand;
    7:DATECommand;
    8:DEBUGCommand;
    9:DEVICECommand;
    10:DIRCommand;
    11:DISKDUMPCommand;
    12:DUMPCommand;
    13:EXITCommand;
    14:FORMATCommand;
    15:FREECommand;
    16:KILLCommand;
    17:LIBCommand;
    18:LISTCommand;
    19:LOADCommand;
    20:PRINTCommand;
    21:PROTCommand;
    22:RENAMECommand;
    23:TAPEDISKCommand;
    24:TIMECommand;
    25:TRACECommand;
    26:VERIFYCommand;
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
  If FileExist(CmdStr+'.JCL')Then Begin
   Inc(InCmd);
   If InCmd>20Then Begin
    WriteLn('Limite de 20 fichiers de traitements par lots maximum.');
    Exit;
   End;
   LastEcho:=Echo;
   Assign(FileJcl,CmdStr+'.JCL');
   {$I-}Reset(FileJcl);{$I+}
   If IOResult=0Then Begin
    While Not EOF(FileJcl)do Begin
     ReadLn(FileJcl,CmdStr);
     If(Echo)Then WriteLn(CmdStr);
     RunCommand;
    End;
   End
    Else
   WriteLn('Probleme de lecture du fichier de traitement par lot');
   Close(FileJcl);
   Echo:=LastEcho;
   Dec(InCmd);
  End
   Else
  UnknownCommand;
 End;
End;

Procedure ReadLine(Var S:String);
Var
 Rec:SearchRec;
 K:Char;
 X,Y,I:Byte;
 CurrHistory:Integer;
 Hour,Minute,Second,CentSec:Word;
Begin
 X:=WhereX;
 Y:=WhereY;
 S:='';
 Repeat
  GotoXY(X,Y);
  Write(S);
  ClrEol;
  If(Clock)Then Begin
   Repeat
    If Not(Keypressed)Then Begin
     Delay(100);
     GotoXY(53,1);
     GetTime(Hour,Minute,Second,CentSec);
     Write(Hour:2,':',PadZeroLeft(Minute,2),':',PadZeroLeft(Second,2));
     GotoXY(X,Y);
     Write(S);
     For I:=1 to 9 do Begin
      If Not(KeyPressed)Then Delay(100);
     End;
    End;
   Until Keypressed;
  End;
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #72:;
   End;
   #8:Begin
    If S<>''Then S:=Copy(S,1,Length(S)-1);
   End;
   #9:Begin
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
 Echo:=True;Clock:=False;
 InCmd:=0;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('TRSDOS : Startet eine neue Kopie des TRSDOS-Befehlsinterpreters.');
    WriteLn;
    WriteLn('TRSDOS [/C Befehl]');
   End;
   _English:Begin
    WriteLn('TRSDOS : Start a new copy of the TRSDOS Command Interpreter.');
    WriteLn;
    WriteLn('Syntax : TRSDOS [/C command]');
   End;
   Else Begin
    WriteLn('TRSDOS : Cette commande permet de lancer l''interpreteur de commande TRSDOS.');
    WriteLn;
    WriteLn('Syntaxe : TRSDOS [/C command]');
    WriteLn;
    WriteLn(' /C command   Ce paramŠtre d''indiquer une des commandes TRSDOS');
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
