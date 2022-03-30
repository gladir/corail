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
 WriteLn;
 WriteLn('Clone de l''interpreteur de commande TRSDOS');
 WriteLn;
End;

Procedure ShowPrompt;Begin
 WriteLn('TRSDOS Ready');
End;

Procedure InvalidParam(P:Byte);Begin
 WriteLn('Le parametre suivant est invalide : ',ExtractParam(P));
End;

Procedure ATTRIBCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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

Procedure CLOCKCommand;Begin
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

Procedure DUMPCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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

Procedure FREECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure KILLCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LIBCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LISTCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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
   UnknownCommand;
  End;
 Until Terminated;
END.
