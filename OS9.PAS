{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program OS9;

Uses Crt,DOS;

Const
 CommandList:Array[0..50]of String[8]=(
  'ATTR','BACKUP','BASIC09','BUILD','CHD','CHX','CMP','COBBLER',
  'CONFIG','COPY','DATE','DCHECK','DEINIZ','DEL','DELDIR','DIR',
  'DISPLAY','DSAVE','ECHO','EDIT','ERROR','EX','EXIT','FORMAT','FREE',
  'HELP','IDENT','INIZ','KILL','LINK','LIST','LOAD','MAKDIR',
  'MDIR','MERGE','MFREE','MODPATCH','MONTYPE','OS9GEN','PROCS',
  'PWD','PXD','RENAME','SETPR','SETIME','SHELL','TMODE',
  'TUNEPORT','UNLINK','WCREATE','XMODE'
 );

 ErrorMsgList:Array[1..255]of String[50]=(
  {1}'Termiaison inconditionnelle',
  {2}'Terminaison clavier',
  {3}'Interruption par le clavier',
  {4}'',
  {5}'',
  {6}'',
  {7}'',
  {8}'',
  {9}'',
  {10}'Symbole non reconnu',
  {11}'Verbiage excessif',
  {12}'Construction ill‚gale de d‚claration',
  {13}'D‚bordement de I-code, besoin de plus de m‚moire.',
  {14}'R‚f‚rence sur le canal ill‚gal',
  {15}'Mode ill‚gal (lecture, ‚criture, mise … jour)',
  {16}'Nombre ill‚gal',
  {17}'Pr‚fixe ill‚gal',
  {18}'Op‚rande ill‚gal',
  {19}'Op‚rateur ill‚gal',
  {20}'Nom de champ d''enregistrement ill‚gal',
  {21}'Dimension ill‚gale',
  {22}'Litt‚ral ill‚gal',
  {23}'Relation ill‚gale',
  {24}'Suffixe de type ill‚gal',
  {25}'Trop grande dimension',
  {26}'Num‚ro de ligne trop grand',
  {27}'D‚claration d''instruction manquante',
  {28}'Num‚ro de chemin manquant',
  {29}'Virgule manquante',
  {30}'Dimension manquante',
  {31}'Instruction DO manquant',
  {32}'M‚moire pleine, besoin de plus de m‚moire d''espace de travail',
  {33}'GOTO attendu',
  {34}'ParenthŠse gauche manquante',
  {35}'R‚f‚rence de ligne manquante',
  {36}'Op‚rande manquant',
  {37}'ParenthŠse droite manquante',
  {38}'Instruction THEN manquante',
  {39}'TO manquante',
  {40}'R‚f‚rence de variable manquante',
  {41}'Pas de guillemet finale',
  {42}'Trop d''indice',
  {43}'Proc‚dure inconnue',
  {44}'Multiple-d‚finition de proc‚dure',
  {45}'Diviser par z‚ro',
  {46}'Non concordance de type d''op‚rande',
  {47}'D‚bordement de pile de chaŒne de caractŠres',
  {48}'Routine non impl‚ment‚e',
  {49}'Variable ind‚finie',
  {50}'D‚bordement de valeur flottante',
  {51}'Ligne avec erreur de compilateur',
  {52}'Valeur hors limites de la destination',
  {53}'D‚bordement de pile de sous-routine',
  {54}'Sous-d‚bordement de pile de sous-routine',
  {55}'Indice en dehors de l''intervalle',
  {56}'Erreur de paramŠtre',
  {57}'D‚bordement de pile de systŠme',
  {58}'Non concordance de type d''entr‚e/sortie',
  {59}'Mauvais format d''entr‚e num‚rique d''entr‚e/sortie',
  {60}'Conversion d''entr‚e/sortie: nombre en dehors de l''intervalle',
  {61}'Format d''entr‚e ill‚gal',
  {62}'Erreur de r‚p‚tition de format d''entr‚e/sortie',
  {63}'Erreur de syntaxe de format d''entr‚e/sortie',
  {64}'Num‚ro de chemin ill‚gal',
  {65}'Mauvais nombre d''indice',
  {66}'Op‚rande de type non enregistr‚',
  {67}'ParamŠtre ill‚gal',
  {68}'Structure de contr“le ill‚gale',
  {69}'Structure de contr“le non correspondante',
  {70}'Variable FOR ill‚gal',
  {71}'Type d''expression ill‚gal',
  {72}'D‚claration d‚clarative ill‚gale',
  {73}'D‚bordement de la taille d''un tableau.',
  {74}'Num‚ro de ligne ind‚fini',
  {75}'Num‚ro de ligne d‚finit de multiple fois',
  {76}'Multiple d‚finition de variable',
  {77}'Variable d''entr‚e ill‚gale',
  {78}'Positionnement en dehors de l''intervalle',
  {79}'Instruction de donn‚es manquante',
  {80}'',
  {81}'',
  {82}'',
  {83}'',
  {84}'',
  {85}'',
  {86}'',
  {87}'',
  {88}'',
  {89}'',
  {90}'',
  {91}'',
  {92}'',
  {93}'',
  {94}'',
  {95}'',
  {96}'',
  {97}'',
  {98}'',
  {99}'',
  {100}'',
  {101}'',
  {102}'',
  {103}'',
  {104}'',
  {105}'',
  {106}'',
  {107}'',
  {108}'',
  {109}'',
  {110}'',
  {111}'',
  {112}'',
  {113}'',
  {114}'',
  {115}'',
  {116}'',
  {117}'',
  {118}'',
  {119}'',
  {120}'',
  {121}'',
  {122}'',
  {123}'',
  {124}'',
  {125}'',
  {126}'',
  {127}'',
  {128}'',
  {129}'',
  {130}'',
  {131}'',
  {132}'',
  {133}'',
  {134}'',
  {135}'',
  {136}'',
  {137}'',
  {138}'',
  {139}'',
  {140}'',
  {141}'',
  {142}'',
  {143}'',
  {144}'',
  {145}'',
  {146}'',
  {147}'',
  {148}'',
  {149}'',
  {150}'',
  {151}'',
  {152}'',
  {153}'',
  {154}'',
  {155}'',
  {156}'',
  {157}'',
  {158}'',
  {159}'',
  {160}'',
  {161}'',
  {162}'',
  {163}'',
  {164}'',
  {165}'',
  {166}'',
  {167}'',
  {168}'',
  {169}'',
  {170}'',
  {171}'',
  {172}'',
  {173}'',
  {174}'',
  {175}'',
  {176}'',
  {177}'',
  {178}'',
  {179}'',
  {180}'',
  {181}'',
  {182}'',
  {183}'Type de fenˆtre ill‚gale',
  {184}'La fenˆtre est d‚j… d‚finie',
  {185}'Police de caractŠres non trouv‚e',
  {186}'D‚bordement de pile',
  {187}'ParamŠtre ill‚gal',
  {188}'',
  {189}'Coordonn‚es ill‚gales',
  {190}'V‚rification d''int‚grit‚ interne',
  {191}'La taille du tampon est trop petite',
  {192}'Commande ill‚gale',
  {193}'La table de l''‚cran ou de la fenˆtre est pleine',
  {194}'Mauvais num‚ro de m‚moire tampon ou ind‚fini',
  {195}'D‚finition de fenˆtre ill‚gale',
  {196}'Fenˆtre non d‚finie',
  {197}'',
  {198}'',
  {199}'',
  {200}'Table de chemin pleine',
  {201}'Num‚ro de chemin ill‚gal',
  {202}'Table de vote d''interruption pleine',
  {203}'Mode ill‚gal',
  {204}'Tableau de p‚riph‚rique pleine',
  {205}'Entˆte de module ill‚gal',
  {206}'R‚pertoire du module plein',
  {207}'M‚moire pleine',
  {208}'Demande de service ill‚gale',
  {209}'Module occup‚',
  {210}'Erreur de limite',
  {211}'Fin du fichier',
  {212}'Renvoyer la m‚moire non allou‚e',
  {213}'Segment non existant',
  {214}'Aucune autorisation',
  {215}'Mauvais nom de chemin',
  {216}'Nom du chemin introuvable',
  {217}'Liste de segments plein',
  {218}'Le fichier existe d‚j…',
  {219}'Adresse de blocs ill‚gale',
  {220}'D‚crocher le t‚l‚phone - perte de donn‚es',
  {221}'Module non trouv‚',
  {222}'',
  {223}'Tentative de suicide',
  {224}'Num‚ro de processus ill‚gal',
  {225}'',
  {226}'Aucun enfant',
  {227}'Code SWI ill‚gal',
  {228}'Processus abandonn‚e',
  {229}'Tableau de processus plein',
  {230}'Zone de paramŠtres ill‚gale',
  {231}'Module connu',
  {232}'Module CRC incorrect',
  {233}'Erreur de signal',
  {234}'Module inexistant',
  {235}'Mauvais nom',
  {236}'Mauvais entˆte',
  {237}'M‚moire vive systŠme pleine',
  {238}'Identificateur de processus inconnu',
  {239}'Aucun num‚ro de tƒche disponible',
  {240}'Erreur d''unit‚',
  {241}'Erreur du secteur',
  {242}'Protection en ‚criture',
  {243}'Erreur CRC',
  {244}'Erreur de lecture',
  {245}'Erreur d''‚criture',
  {246}'Pas prˆt, p‚riph‚rique non prˆt',
  {247}'Erreur de positionnement',
  {248}'M‚dia plein',
  {249}'Type de type incorrect, type de support incompatible',
  {250}'P‚riph‚rique occup‚',
  {251}'Changement d''identificateur de disque',
  {252}'L''enregistrement est verrouill‚',
  {253}'Fichier non partageable occup‚',
  {254}'',
  {255}''
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
 TextBackground(Green);
 WriteLn;
 WriteLn('Clone de l''interpreteur de commande OS-9');
 WriteLn;
End;

Procedure ShowPrompt;Begin
 Write('OS9:');
End;

Procedure InvalidParam(P:Byte);Begin
 WriteLn('Le parametre suivant est invalide : ',ExtractParam(P));
End;

Procedure ATTRCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BACKUPCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure BASIC09Command;Begin
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
   Write('? ');
   ReadLn(CurrLine);
   WriteLn(TextFile,CurrLine);
  Until CurrLine='';
  Close(TextFile);
 End
  Else
 WriteLn('Nom de fichier requis');
End;

Procedure CHDCommand;
Var
 Error:Word;
 FirstParam,Dir:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('CHD   Cette commande permet de fixer ou de demander le repertoire courant.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('CHD [/?] chemin');
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

Procedure CHXCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CMPCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure COBBLERCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CONFIGCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure COPYCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DATECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DCHECKCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DEINIZCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DELCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DELDIRCommand;
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
   WriteLn('DELDIR   Cette commande permet de supprimer un repertoire vide.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('DELDIR [/?] nomrepertoire');
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

Procedure DirCommand;
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
   WriteLn('DIR   Cette commande permet d''afficher le contenu d''un repertoire dans l''unite de disque.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('DIR [/?] [e] [chemin]');
   WriteLn;
   WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('  e   Ce parametre permet d''afficher la liste de facon detaille');
   Exit;
  End
   Else
  If CurrParam='e'Then Include(Option,Detail) Else
  ShowDir:=CurrParam;
  If P>99Then Break;
 Until CurrParam='';
 CurrDrive:=Path2Drive(ShowDir);
 CurrLabel:=GetDiskLabel(Byte(CurrDrive)-64);
 P:=0;
 FindFirst(ShowDir,AnyFile,Info);
 WriteLn(' Repertoire de .');
 WriteLn;
 If(Detail in Option)Then Begin
  WriteLn('Propr Dern.modifica. Attributs Secteur Compteur d''octets Nom');
  WriteLn('----- -------------- --------- ------- ----------------- ---------------');
  While DOSError=0 do Begin
   If Not((Info.Name='.')or(Info.Name='..'))Then Begin
    Write(0:4,'  ');
    UnpackTime(Info.Time,T);
    Write(' ',PadZeroLeft(T.Year mod 100,2):2,'/',PadZeroLeft(T.Month,2),'/',PadZeroLeft(T.Day,2),' ');
    Write(PadZeroLeft(T.Hour,2):2,PadZeroLeft(T.Min,2),'  ');
    If(Info.Attr and Directory=Directory)Then Write('d')
                                         Else Write('-');
    Write('---r');
    If Path2Ext(Info.Name)='.EXE'Then Write('e')
                                 Else Write('-');
    If(Info.Attr and ReadOnly=ReadOnly)Then Write('-')
                                       Else Write('w');
    Write('r ');
    Write(RemoveZeroLeft(LongHex2Str(0)):7);
    Write(RemoveZeroLeft(LongHex2Str(Info.Size)):18);
    WriteLn(' ',Info.Name);
   End;
   FindNext(Info);
  End;
 End
  Else
 Begin
  While DOSError=0 do Begin
   If Not((Info.Name='.')or(Info.Name='..'))Then Begin
    WriteLn(PadRight(Info.Name,25));
   End;
   FindNext(Info);
  End;
 End;
End;

Procedure DISPLAYCommand;
Var
 P:Byte;
 W:Word;
 Msg,CurrParam:String;
Begin
 P:=0;
 Msg:='';
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If Length(CurrParam)=0Then Break;
  If CurrParam='/?'Then Begin
   WriteLn('DISPLAY   Cette commande permet d''afficher un message encodee en hexadecimal.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('DISPLAY [/?] hex [...]');
   WriteLn;
   WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn(' hex  Ce parametre permet d''indiquer des nombres hexadecimal de 2 chiffres');
   Exit;
  End
   Else
  Begin
   If GetHex(ExtractParam(P),W)Then Msg:=Msg+Chr(Lo(W));
  End;
  If P>255Then Break;
 Until CurrParam='';
 If Msg<>''Then WriteLn(Msg);
End;


Procedure DSAVECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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

Procedure EDITCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ERRORCommand;
Var
 P:Byte;
 Err,W:Word;
 CurrParam:String;
Begin
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If Length(CurrParam)=0Then Break;
  If CurrParam='/?'Then Begin
   WriteLn('ERROR   Cette commande permet d''afficher la description de l''erreur.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('ERROR [/?] nombre [...]');
   WriteLn;
   WriteLn(' /?      Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn(' nombre  Ce parametre permet d''indiquer le numero de l''erreur');
   Exit;
  End
   Else
  Begin
   Val(CurrParam,W,Err);
   If Err=0Then Begin
    If Not(W in [1..255])Then WriteLn('Le nombre ',W,' est en dehors de l''intervalle')
                         Else WriteLn(W,' - ',ErrorMsgList[W]);
   End;
  End;
  If P>255Then Break;
 Until CurrParam='';
End;

Procedure EXCommand;Begin
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

Procedure FORMATCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure FREECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure HELPCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure IDENTCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure INIZCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure KILLCommand;Begin
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

Procedure LOADCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure MAKDIRCommand;
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
   WriteLn('MAKDIR   Cette commande permet de creer un repertoire.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('MAKDIR [/?] nomrepertoire');
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

Procedure MDIRCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure MERGECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure MFREECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure MODPATCHCommnand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure MONTYPECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure OS9GENCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PROCSCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PWDCommand;
Var
 CurrDir:String;
Begin
 If(ExtractParam(1)='/?')Then Begin
  WriteLn('PWD : Cette commande permet d''afficher le repertoire de travail.');
  WriteLn;
  WriteLn('Syntaxe : PWD');
 End
  Else
 If ExtractParam(1)=''Then Begin
  GetDir(0,CurrDir);
  ChangeChar(CurrDir,'\','/');
  If CurrDir[2]=':'Then Begin
   CurrDir:=Copy(CurrDir,3,255);
  End;
  CurrDir:=GetCurrentDiskCoco+CurrDir;
  WriteLn(CurrDir);
 End
  Else
 WriteLn('Parametre non requis !');
End;

Procedure PXDCommand;Begin
 If(ExtractParam(1)='/?')Then Begin
  WriteLn('PXD : Cette commande permet d''afficher le repertoire d''execution.');
  WriteLn;
  WriteLn('Syntaxe : PWX');
 End
  Else
 WriteLn(GetEnv('PATH'));
End;

Procedure RENAMECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SETPRCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SETTIMECommand;
Var
 Pos:(PMonth,PDay,PYear,PHour,PMin,PSec);
 Year,Month,Day,DayOfMonth,Hour,Minute,Second,CentSec,Err:Word;
 I:Byte;
 S,T:String;
Begin
 If(ExtractParam(1)='/?')Then Begin
  WriteLn('SETIME : Cette commande permet de fixer l''horloge du systeme d''exploitation.');
  WriteLn;
  WriteLn('Syntaxe : SETIME aa/MM/dd hh:mm[:ss]');
 End
  Else
 If ExtractParam(1)<>''Then Begin
  T:='';
  Pos:=PYear;
  S:=ExtractParam(1);
  For I:=1 to Length(S)do Begin
   If S[I]<>'/'Then T:=T+S[I];
   If S[I]='/'Then Begin
    If Pos=PYear Then Begin
     Val(T,Year,Err);
     Pos:=PMonth;
    End
     Else
    If Pos=PMonth Then Begin
     Val(T,Month,Err);
     Pos:=PDay;
    End
     Else
    Val(T,Day,Err);
    T:='';
   End;
  End;
  If T<>''Then Val(T,Day,Err);
  SetDate(Year,Month,Day);
  S:=ExtractParam(2);
  If S<>''Then Begin
   T:='';
   Hour:=0;
   Minute:=0;
   Second:=0;
   Pos:=PHour;
   For I:=1 to Length(S)do Begin
    If S[I]<>':'Then T:=T+S[I];
    If S[I]=':'Then Begin
     If Pos=PHour Then Begin
      Val(T,Hour,Err);
      Pos:=PMin;
     End
      Else
     If Pos=PMin Then Begin
      Val(T,Minute,Err);
      Pos:=PSec;
     End
      Else
     Val(T,Second,Err);
     T:='';
    End;
   End;
   If T<>''Then Begin
    If(Pos=PMin)Then Val(T,Minute,Err)
                Else Val(T,Second,Err);
   End;
   SetTime(Hour,Minute,Second,0);
  End;
 End
  Else
 WriteLn('Heure attendu');
End;

Procedure SHELLCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TMODECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TUNEPORTCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UNLINKCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure WCREATECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure XMODECommand;Begin
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
     0:ATTRCommand;
     1:BACKUPCommand;
     2:BASIC09Command;
     3:BUILDCommand;
     4:CHDCommand;
     5:CHXCommand;
     6:CMPCommand;
     7:COBBLERCommand;
     8:CONFIGCommand;
     9:COPYCommand;
     10:DATECommand;
     11:DCHECKCommand;
     12:DEINIZCommand;
     13:DELCommand;
     14:DELDIRCommand;
     15:DIRCommand;
     16:DISPLAYCommand;
     17:DSAVECommand;
     18:ECHOCommand;
     19:EDITCommand;
     20:ERRORCommand;
     21:EXCommand;
     22:EXITCommand;
     23:FORMATCommand;
     24:FREECommand;
     25:HELPCommand;
     26:IDENTCommand;
     27:INIZCommand;
     28:KILLCommand;
     29:LINKCommand;
     30:LISTCommand;
     31:LOADCommand;
     32:MAKDIRCommand;
     33:MDIRCommand;
     34:MERGECommand;
     35:MFREECommand;
     36:MODPATCHCommnand;
     37:MONTYPECommand;
     38:OS9GENCommand;
     39:PROCSCommand;
     40:PWDCommand;
     41:PXDCommand;
     42:RENAMECommand;
     43:SETPRCommand;
     44:SETTIMECommand;
     45:SHELLCommand;
     46:TMODECommand;
     47:TUNEPORTCommand;
     48:UNLINKCommand;
     49:WCREATECommand;
     50:XMODECommand;
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
