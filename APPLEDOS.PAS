{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program AppleDOS;

Uses Crt,DOS;

Const
 CommandList:Array[0..30]of String[8]=(
  'APPEND','BLOAD','BRUN','BSAVE','BYE','CATALOG','CHAIN','CLOSE',
  'CLOSE','DELETE','EXEC','EXIT','FP','IN','INIT','INT','LOAD',
  'LOCK','MAXFILES','MON','NOMON','OPEN','POSITION','PR',
  'READ','RENAME','RUN','SAVE','UNLOCK','VERIFY','WRITE'
 );

Var
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

Function TrimR(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 TrimR:=S;
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

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
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

Function Path2Name(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2Name:=N;
End;

Function Path2ExtNoDot(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2ExtNoDot:=Copy(E,2,255);
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

Function Path2Drive(Path:String):Char;Begin
 Path:=FExpand(Path);
 Path2Drive:=Path[1];
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
 TextBackground(Black);
 TextColor(Green);
 ClrScr;
 WriteLn;
 WriteLn('DOS VERSION 3.3            08/25/80');
 WriteLn('APLPE II PLUS OR ROMCARD   SYSTEM MASTER');
 WriteLn;
End;

Procedure ShowPrompt;Begin
 Write(']');
End;

Procedure InvalidParam(P:Byte);Begin
 WriteLn('Le parametre suivant est invalide : ',ExtractParam(P));
End;

Procedure APPENDCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BLOADCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BRUNCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BSAVECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Function BYECommand:Boolean;
Var
 FirstParam:String;
 N,Err:Integer;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('BYE  Cette commande permet de quitter l''interpreteur de commande.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('BYE [/?] [CodeSortie]');
  WriteLn;
  WriteLn(' CodeSortfiie   Ce parametre permet d''indiquer le code de sortie a ',
                         'retourner a l''application parent');
  WriteLn('        /?    Ce parametre permet d''afficher l''aide sur cette commande');
  BYECommand:=False;
 End
  Else
 If Length(FirstParam)>0Then Begin
  Val(FirstParam,N,Err);
  Halt(N);
  BYECommand:=True;
 End
  Else
 BYECommand:=True;
End;

Procedure CatalogCommand;
Var
 P:Byte;
 Info:SearchRec;
 T:DateTime;
 TotalNumFiles,TotalSize:LongInt;
 CurrParam,ShowDir,CurrLabel:String;
 CurrDrive:Char;
Begin
 P:=0;
 ShowDir:='*.*';
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If Length(CurrParam)=0Then Break;
  If CurrParam='/?'Then Begin
   WriteLn('CATALOG   Cette commande permet d''afficher le contenu d''un repertoire dans l''unite de disque.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('CATALOG [/?] [chemin] [D1|D2|D3|D4]');
   WriteLn;
   WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
   Exit;
  End
   Else
  If CurrParam='D0'Then Begin
   WriteLn('ERREUR D''INTERVALLE');
   Exit;
  End
   Else
  If StrToUpper(CurrParam)='D1'Then ShowDir:='A:\*.*'Else
  If StrToUpper(CurrParam)='D2'Then ShowDir:='B:\*.*'Else
  If StrToUpper(CurrParam)='D3'Then ShowDir:='C:\*.*'Else
  IF StrToUpper(CurrParam)='D4'Then ShowDir:='D:\*.*'
                               Else ShowDir:=CurrParam;
  If P>99Then Break;
 Until CurrParam='';
 CurrDrive:=Path2Drive(ShowDir);
 FindFirst(ShowDir,AnyFile,Info);
 P:=0;
 While DOSError=0 do Begin
  Inc(P);
  If(Info.Attr and ReadOnly=ReadOnly)Then Write('*')
                                     Else Write(' ');
  If(Path2Ext(Info.Name)='.EXE')or(Path2Ext(Info.Name)='.COM')Then Write('B')Else
  If(Path2Ext(Info.Name)='.BAS')Then Write('A') Else
  If(Path2Ext(Info.Name)='.TXT')Then Write('T')
                                Else Write('S');
  Write(' ',HexWord2Str(Word(Info.Size shr 9)),' ');
  WriteLn(StrToUpper(Info.Name));
  FindNext(Info);
  If P=25Then Begin
   ReadKey;
   P:=0;
  End;
 End;
End;

Procedure CHAINCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CLOSECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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

Procedure EXECCommand;Begin
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
  WriteLn(' CodeSortfiie   Ce parametre permet d''indiquer le code de sortie a ',
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

Procedure FPCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure INCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure INITCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure INTCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LOADCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LOCKCommand;
Var
 F:File;
 CurrAttr:Word;
 FirstParam:String;
 X:Boolean;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('LOCK   Cette commande permet d''appliquer un ',
          'verrou sur un fichier');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('LOCK [/?] nomdufichier');

 End
  Else
 If FirstParam<>''Then Begin
  Assign(F,FirstParam);
  GetFAttr(F,CurrAttr);
  CurrAttr:=CurrAttr or ReadOnly;
  SetFAttr(F,CurrAttr);
 End
  Else
 WriteLn('Erreur de syntaxe');
End;

Procedure MAXFILESCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure MONCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure NOMONCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure OPENCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure POSITIONCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PRCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure READCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure RenameCommand;
Var
 P,I:Byte;
 Err:Word;
 F:File;
 CurrParam,Source,Target:String;
Begin
 P:=0;
 Source:='';
 Target:='';
 If ParamList='/?'Then Begin
  WriteLn('RENAME   Cette commande permet de renommer un fichier.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('RENAME [/?] nouveaunom=anciennom');
  WriteLn;
  WriteLn(' /?         Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn('nouveaunom  Ce parametre permet d''indiquer le nouveau nom');
  WriteLn('anciennom   Ce parametre permet d''indiquer l''ancien nom');
  Exit;
 End
  Else
 If ParamList<>''Then Begin
  For I:=1 to Length(ParamList)do Begin
   If ParamList[I]='='Then Begin
    Target:=TrimR(TrimL(Copy(ParamList,1,I-1)));
    Source:=TrimR(TrimL(Copy(ParamList,I+1,255)));
    Break;
   End;
  End;
 End;
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

Procedure RUNCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SAVECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UNLOCKCommand;
Var
 F:File;
 CurrAttr:Word;
 FirstParam:String;
 X:Boolean;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('UNLOCK   Cette commande permet d''enlever un ',
          'verrou sur un fichier');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('UNLOCK [/?] nomdufichier');
 End
  Else
 If FirstParam<>''Then Begin
  Assign(F,FirstParam);
  GetFAttr(F,CurrAttr);
  CurrAttr:=CurrAttr and Not ReadOnly;
  SetFAttr(F,CurrAttr);
 End
  Else
 WriteLn('Erreur de syntaxe');
End;

Procedure VERIFYCommand;
Var
 FirstParam:String;
 X:Boolean;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('VERIFY   Cette commande permet de verifier si ',
          'le fichier existe');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('VERIFY [/?] nomdufichier');

 End
  Else
 If FirstParam<>''Then Begin
  If Not FileExist(FirstParam)Then WriteLn('FICHIER NON PRESENT');
 End
  Else
 WriteLn('Erreur de syntaxe');
End;

Procedure WRITECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UnknownCommand;Begin
 Exec(CurrCommand,ParamList);
 If DosError<>0Then Begin
  WriteLn('Erreur de syntaxe');
 End;
 WriteLn;
End;

BEGIN
 Terminated:=False;
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
     1:BLOADCommand;
     2:BRUNCommand;
     3:BSAVECommand;
     4:Terminated:=BYECommand;
     5:CATALOGCommand;
     6:CHAINCommand;
     7:CLOSECommand;
     8:CLOSECommand;
     9:DELETECommand;
     10:EXECCommand;
     11:Terminated:=ExitCommand;
     12:FPCommand;
     13:INCommand;
     14:INITCommand;
     15:INTCommand;
     16:LOADCommand;
     17:LOCKCommand;
     18:MAXFILESCommand;
     19:MONCommand;
     20:NOMONCommand;
     21:OPENCommand;
     22:POSITIONCommand;
     23:PRCommand;
     24:READCommand;
     25:RENAMECommand;
     26:RUNCommand;
     27:SAVECommand;
     28:UNLOCKCommand;
     29:VERIFYCommand;
     30:WRITECommand;
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
