{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program FLEX;

Uses Crt,DOS;

Const
 CommandList:Array[0..46]of String[8]=(
  'APPEND','ASN','BUILD','CAT','COPY','C4MAT','CLEAN','DATE','DELETE',
  'ECHO','EXEC','EXIT','FIX','GET','I','JUMP','LINK','LIST','MON',
  'NEWDISK','N','O','P','P.COR','PO','PSP','PROT','Q','QCHECK',
  'RENAME','RM','READPROM','S','SAVE','SAVE.LOW','SBOX','SP','STARTUP',
  'TTYSET','TOUCH','UCAL','USEMF','VER','VERIFY','WRITPROM',
  'XOUT','Y'
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

Function RemoveZeroLeft(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S) do Begin
  If S[I]<>'0'Then Begin
   RemoveZeroLeft:=Copy(S,I,255);
   Exit;
  End;
 End;
 RemoveZeroLeft:='0';
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

Function GetHex(Source:String;Var H:Word):Boolean;
Var
 Digit:Word;
Begin
 H:=0;
 GetHex:=False;
 Source:=StrToUpper(Source);
 For I:=1 to Length(Source) do If(Source[I] in ['A'..'F', '0'..'9'])Then Begin
  GetHex:=True;
  If(Source[I]>='A')Then Digit:=Ord(Source[I])-Ord('A')+10
                    Else Digit:=Ord(Source[I])-Ord('0');
  H:=(H Shl 4)+Digit;
 End;
End;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

Function LongHex2Str(value:LongInt):String;
Begin
 LongHex2Str:=ByteHex2Str((value shr 24)and $FF)+
              ByteHex2Str((value shr 16)and $FF)+
              ByteHex2Str((value shr 8)and $FF)+
              ByteHex2Str(value and $FF);
End;

Function GetCurrentDisk:Char;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 GetCurrentDisk:=CurrentDir[1];
End;

Function GetCurrentDiskCoco:String;
Var
 Tmp:String;
Begin
 Case GetCurrentDisk of
  'A':GetCurrentDiskCoco:='/D0';
  'B':GetCurrentDiskCoco:='/D1';
  Else Begin
   Str((Ord(GetCurrentDisk)-Ord('A')-2),Tmp);
   GetCurrentDiskCoco:='/H'+Tmp;
  End;
 End;
End;

Function Path2Drive(Path:String):Char;Begin
 Path:=FExpand(Path);
 Path2Drive:=Path[1];
End;

Function Path2Name(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2Name:=N;
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
 TextColor(6);
 TextBackground(Black);
 WriteLn;
 WriteLn('Clone de l''interpreteur de commande FLEX');
 WriteLn;
End;

Procedure ShowPrompt;Begin
 Write('+++');
End;

Procedure InvalidParam(P:Byte);Begin
 WriteLn('Le parametre suivant est invalide : ',ExtractParam(P));
End;

Procedure APPENDCommand;
Var
 Source,Dest:Text;
 I:Integer;
 CurrParam,LastParam,CurrLine:String;
Begin
 If ExtractParam(1)='/?'Then Begin
  WriteLn('APPEND : Cette commande permet d''ajouter un fichier ASCII … un autre fichier.');
  WriteLn;
  WriteLn('Syntaxe : APPEND fichier [listefichier] fichierdest');
 End
  Else
 Begin
  I:=1;
  LastParam:='';
  Repeat
    CurrParam:=ExtractParam(I);
    If CurrParam<>''Then LastParam:=CurrParam;
    Inc(I);
  Until CurrParam='';
  If LastParam=''Then Begin
   WriteLn('Destination manquante');
   Exit;
  End;
  If I=1Then Begin
   WriteLn('Une source est necessaire');
   Exit;
  End;
  Assign(Dest,LastParam);
  {$I-}Append(Dest);{$I+}
  If IoResult=2Then Begin
   WriteLn('Creation de la destination');
   Rewrite(Dest);
  End;
  I:=1;
  Repeat
   CurrParam:=ExtractParam(I);
   If CurrParam=''Then Break;
   If(CurrParam<>LastParam)Then Begin
    Assign(Source,CurrParam);
    Reset(Source);
    While Not EOF(Source)do Begin
     ReadLn(Source,CurrLine);
     WriteLn(Dest,CurrLine);
    End;
    Close(Source);
   End;
   Inc(I);
  Until CurrParam='';
  Close(Dest);
 End;
End;

Procedure ASNCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BUILDCommand;
Var
 TextFile:Text;
 FirstParam,CurrLine:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('BUILD   Cette commande permet de construire un fichier texte.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('BUILD [/?] nomdufichier');
  WriteLn;
  WriteLn('  /?           Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' nomdufichier  Ce parametre permet d''indiquer le nom du fichier a construire.');
 End
  Else
 If Length(FirstParam)>0Then Begin
  Assign(TextFile,FirstParam);
  Rewrite(TextFile);
  Repeat
   Write('=');
   ReadLn(CurrLine);
   WriteLn(TextFile,CurrLine);
  Until CurrLine='#';
  Close(TextFile);
 End
  Else
 WriteLn('Nom de fichier requis');
End;

Procedure CATCommand;
Var
 P:Byte;
 Info:SearchRec;
 T:DateTime;
 Option:Set of (Detail);
 CurrParam,ShowDir,CurrLabel:String;
 CurrDrive:Char;
Begin
 Option:=[];
 P:=0;
 ShowDir:='*.*';
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If Length(CurrParam)=0Then Break;
  If CurrParam='/?'Then Begin
   WriteLn('CAT   Cette commande permet d''afficher le contenu d''un repertoire dans l''unite de disque.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('CAT [/?] [e] [chemin]');
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
 WriteLn('CATALOGUE DE L''UNITE NUMERO ',Byte(CurrDrive)-65);
 WriteLn('DISK: PERFLEX #',Byte(CurrDrive)-65);
 WriteLn;
 WriteLn(' NOM    TYPE  TAILLE   PRT');
 WriteLn;
 While DOSError=0 do Begin
  If Not((Info.Name='.')or(Info.Name='..'))Then Begin
   Write(PadRight(Path2Name(Info.Name),8));
   Write(PadRight(Path2Ext(Info.Name),4));
   Write(Info.Size shr 9:8,' ':5);
   If(Info.Attr and ReadOnly=ReadOnly)Then Write('W')
                                      Else Write(' ');
   WriteLn;
  End;
  FindNext(Info);
 End;
 WriteLn;
 WriteLn('SECTEUR LIBRE = ',DiskSize(Byte(CurrDrive)-64) shr 9);
End;

Procedure COPYCommand;
Var
 P:Byte;
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
   WriteLn('COPY   Cette commande permet d''effacer la copie de fichier vers un autre emplacement.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('COPY [/?] [/P] source destination');
   WriteLn;
   WriteLn('    /?       Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('source       Ce parametre permet d''indiquer le fichier source');
   WriteLn('destination  Ce parametre permet d''indiquer le fichier destination');
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
  If CopyFile(Source,Target,False)Then WriteLn('1 fichier copie')
                                  Else WriteLn('Echec de copie de fichier');
 End;
End;

Procedure C4MATCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CLEANCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DATECommand;
Const
 Mon:Array[1..12]of String[16]=('janvier','fevrier','mars','avril','mai','juin',
                               'juillet','aout','septembre','octobre','novembre','decembre');
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
  WriteLn(Day,' ',Mon[Month],' ',Year);
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

Procedure ECHOCommand;
Var
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('ECHO   Cette commande permet d''afficher un message sur le console du systeme d''exploitation.');
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

Procedure EXECCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ExitCommand;
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

Procedure FIXCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure GETCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ICommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure JUMPCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LINKCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LISTCommand;
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
   WriteLn('LIST   Cette commande permet d''afficher le contenu d''un fichier');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('LIST [/?] [fichier]');
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

Procedure MONCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure NEWDISKCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure NCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure OCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PCORCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure POCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PSPCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PROTCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure QCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure QCHECKCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure RENAMECommand;
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

Procedure RMCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure READPROMCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SAVECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SAVELOWCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SBOXCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SPCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure STARTUPCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TTYSETCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TOUCHCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UCALCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure USEMFCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure VERCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure VERIFYCommand;
Var
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

Procedure WRITPROMCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure XOUTCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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
     0:APPENDCommand;
     1:ASNCommand;
     2:BUILDCommand;
     3:CATCommand;
     4:COPYCommand;
     5:C4MATCommand;
     6:CLEANCommand;
     7:DATECommand;
     8:DELETECommand;
     9:ECHOCommand;
     10:EXECCommand;
     11:EXITCommand;
     12:FIXCommand;
     13:GETCommand;
     14:ICommand;
     15:JUMPCommand;
     16:LINKCommand;
     17:LISTCommand;
     18:MONCommand;
     19:NEWDISKCommand;
     20:NCommand;
     21:OCommand;
     22:PCommand;
     23:PCORCommand;
     24:POCommand;
     25:PSPCommand;
     26:PROTCommand;
     27:QCommand;
     28:QCHECKCommand;
     29:RENAMECommand;
     30:RMCommand;
     31:READPROMCommand;
     32:SCommand;
     33:SAVECommand;
     34:SAVELOWCommand;
     35:SBOXCommand;
     36:SPCommand;
     37:STARTUPCommand;
     38:TTYSETCommand;
     39:TOUCHCommand;
     40:UCALCommand;
     41:USEMFCommand;
     42:VERCommand;
     43:VERIFYCommand;
     44:WRITPROMCommand;
     45:XOUTCommand;
     46:YCommand;
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