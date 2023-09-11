{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program DISKPART;

{$A-}

Uses Crt,DOS,Strings;

Const
 CommandList:Array[0..35]of String[20]=(
  'ACTIVE','ADD','ASSIGN','ATTRIBUTES','AUTOMOUNT',
  'BREAK','CLEAN','COMPACT','CONVERT','CREATE',
  'DELETE','DETAIL','EXIT','EXPAND','EXTEND','FILESYSTEMS',
  'FORMAT','GPT','HELP','IMPORT','INACTIVE','LIST',
  'MERGE','OFFLINE','ONLINE','RECOVER','REM','REMOVE',
  'REPAIR','RESCAN','RETAIN','SAN','SELECT','SET',
  'SHRINK','UNIQUEID'
 );

 CommandDescr:Array[0..35]of PChar=(
  {ACTIVE}
  'Cette commande permet d''indiquer sur les disques de base une marque '+
  'de partition avec le focus comme active.',
  {ADD}
  'Cette commande permet de mettre un miroir du volume simple avec le '+
  'focus sur le disque sp‚cifi‚.',
  {ASSIGN}
  'Cette commande permet d''attribuer une lettre d''un unit‚ de disque '+
  'ou un point de montage au volume avec le focus.',
  {ATTRIBUTES}
  'Cette commande permet d''afficher, d‚finir ou effacer les attributs '+
  'd''un disque ou d''un volume.',
  {AUTOMOUNT}
  'Cette commande permet d''activer ou d‚sactiver la fonction de montage '+
  'automatique.',
  {BREAK}
  'Cette commande permet de diviser le volume en miroir avec le focus en '+
  'deux volumes simples.',
  {CLEAN}
  'Cette commande permet de supprimer toutes les partitions ou tous les '+
  'formats de volume du disque avec le focus, ®all¯ mettra le disque … '+
  'z‚ro.',
  {COMPACT}
  'Cette commande permet de r‚duire la taille physique d''un fichier de '+
  'disque dur virtuel (VHD) … expansion dynamique.',
  {CONVERT}
  'Cette commande permet de convertir les volumes de table d''allocation '+
  'de fichiers (FAT) et FAT32 dans le systŠme de fichiers NTFS.',
  {CREATE}
  'Cette commande permet de cr‚er une partition, un volume ou disque '+
  'virtuel (VHD).',
  {DELETE}
  'Cette commande permet de supprimer une partition, un volume ou un '+
  'disque dynamique d''une liste de disques.',
  {DETAIL}
  'Cette commande permet d''afficher les propri‚t‚s du disque, de volume '+
  'et de partition s‚lectionn‚, et d''afficher les disques sur lesquels '+
  'r‚side le volume actuel.',
  {EXIT}
  'Cette commande permet de quitter DISKPART.',
  {EXPAND}
  'Cette commande permet d''‚tendre la taille maximale (en Mo) disponible '+
  'sur un disque virtuel.',
  {EXTEND}
  'Cette commande permet d''‚tendre un volume ou une partition avec '+
  'focus et son systŠme de fichiers en espace libre sur un disque.',
  {FILESYSTEMS}
  'Cette commande permet d''afficher les systŠmes de fichiers actuels '+
  'et pris en charge sur le volume.',
  {FORMAT}
  'Cette commande permet de formater un disque pour l''utiliser avec '+
  'Windows.',
  {GPT}
  'Cette commande permet d''associer des attributs … la partition de '+
  'table de partition GUID (GPT) s‚lectionn‚e.',
  {HELP}
  'Cette commande permet de fournir de l''aide sur des commandes de '+
  'DISKPART.',
  {IMPORT}
  'Cette commande permet d''importer un clich‚ instantan‚ transportable '+
  '… partir d''un fichier de m‚tadonn‚es charg‚ dans le systŠme.',
  {INACTIVE}
  'Cette commande permet de marquer la partition systŠme ou la '+
  'partition de d‚marrage avec le focus comme inactive, soit ne pas '+
  'd‚marrer, sur les disques MBR (Master Boot Record).',
  {LIST}
  'Cette commande permet d''afficher une liste d''objets.',
  {MERGE}
  'Cette commande permet de fusionner un disque dur virtuel (VHD) de '+
  'diff‚renciation avec son VHD parent correspondant.',
  {OFFLINE}
  'Cette commande permet de mettre un disque ou un volume en ligne '+
  'en ‚tat hors ligne.',
  {ONLINE}
  'Cette commande permet de mettre un disque ou un volume hors ligne '+
  '… l''‚tat en ligne.',
  {RECOVER}
  'Cette commande permet d''actualiser l''‚tat de tous les disques du '+
  'paquet s‚lectionn‚, tentez la r‚cup‚ration sur les disques du paquet '+
  'non valide et resynchronisez les volumes en miroir et les volumes '+
  'RAID-5 contenant des donn‚es de plex ou de parit‚ p‚rim‚e.',
  {REM}
  'Cette commande permet d''indiquer une remarque.',
  {REMOVE}
  'Cette commande permet de supprimer une lettre d''unit‚ de disque '+
  'ou un point de montage d''un volume.',
  {REPAIR}
  'Cette commande permet de r‚parer un volume RAID-5 avec un membre '+
  'd‚faillant en le rempla‡ant par un disque dynamique sp‚cifi‚.',
  {RESCAN}
  'Cette commande permet de rechercher les nouveaux disques et volumes '+
  'ayant ‚t‚ ajout‚s … l''ordinateur.',
  {RETAIN}
  'Cette commande permet de pr‚parer un volume simple dynamique existant '+
  '… utiliser comme volume de d‚marrage ou systŠme.',
  {SAN}
  'Cette commande permet d''afficher ou de d‚finir la strat‚gie SAN '+
  'pour le systŠme d''exploitation actuellement d‚marr‚.',
  {SELECT}
  'Cette commande permet de d‚placer le focus sur un objet.',
  {SET}
  'Cette commande permet de modifier le type de partition pour la '+
  'partition avec focus. Cette commande est destin‚ … une utilisation OEM.',
  {SHRINK}
  'Cette commande permet de r‚duire la taille du volume s‚lectionn‚.',
  {UNIQUEID}
  'Cette commande permet d''afficher ou de d‚finir l''identificateur '+
  'de table de partition GUID ou la signature MBR pour le disque (de '+
  'base ou dynamique) avec le focus.'
 );

Type
 {Structure de lecture pour le disque }
 SecPosType=Record
  Head:Byte;
  SectTrack:Word;
 End;

 {Structure de partition}
 PartEntry=Record
  Status:Byte;
  StartSec:SecPosType;
  PartType:Byte;
  EndSec:SecPosType;
  SecOfs,NumSec:LongInt;
 End;

 PartSec=Record { d‚crit le secteur de partition }
  BootCode:Array[0..$1BD]of Byte;    { Code de d‚marrage du disque dur }
  PartTable:Array[0..3]of PartEntry; { Table des partitions de disque dur }
  IdCode:Word;                       { Signature: AA55h }
 End;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 CommandFound,Terminated:Boolean;
 CurrentDisk,CurrentPartition:Byte;
 IsDisk:Boolean;
 FileName:String;
 CmdStr:String;
 CurrCommand,ParamList:String;
 I,J:Byte;
 Buffer:Array[0..1023]of Byte;
 Err:Word;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function Hex2Integer(hexStr:String):LongInt;
Var
 hexVal:LongInt;
 evalErr:Boolean;
 i,n:LongInt;
Begin
 Err:=0;
 evalErr:=False;
 hexVal:=0;
 For i:=1 to Length(hexStr) do Begin
  n:=Pos(Upcase(hexStr[i]),'0123456789ABCDEF');
  If n=0 Then evalErr:=True
         Else hexVal:=hexVal*16+n-1;
 End;
 If evalErr Then Begin
  hexVal:=0;
  Err:=1;
 End;
 Hex2Integer:=hexVal;
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

Procedure DiskReset;
{$IFDEF Windows}
 Begin
  WriteLn('Cette operation n''est pas mise en oeuvre.');
  Halt;
 End;
{$ElSE}
 Var
  Regs:Registers;
 Begin
  Regs.AH:=$00;
  Regs.DL:=0;
  Intr($13,Regs);
 End;
{$ENDIF}

Function ReadTrack(Lecteur,Face,Piste,Start,Nombre:Byte;Var Buffer):Byte;
{$IFDEF Windows}
 Begin
  WriteLn('Cette operation n''est pas mise en oeuvre.');
  Halt;
 End;
{$ElSE}
 Var
  Essais:Byte;
  Regs:Registers;
 Begin
  essais:=5;
  Repeat
   WriteLn(Essais);
   Regs.AH:=$02;        { Numero de fonction pour appel interruption }
   Regs.AL:=Nombre;     { Nombre Secteurs par Piste }
   Regs.CH:=Piste;      { Numero de Piste }
   Regs.CL:=Start;      { Commencer par le secteur 1 }
   Regs.DL:=Lecteur;    { Numero de lecteur }
   Regs.DH:=Face;       { Numero de la face }
   Regs.ES:=Seg(Buffer);{ Adresse pour tampon }
   Regs.BX:=Ofs(Buffer);
   Intr($13,Regs);
   If Regs.flags and fcarry=1Then DiskReset;
   Dec(essais);
  Until(Regs.flags and fcarry=0)or(Essais=0);
  ReadTrack:=Regs.AH;
 End;
{$ENDIF}

Function WriteTrack(Lecteur,Face,Piste,Start,Nombre:Byte;Var Buffer):Byte;
{$IFDEF Windows}
 Begin
  WriteLn('Cette operation n''est pas mise en oeuvre.');
  Halt;
 End;
{$ElSE}
 Var
  Essais:Byte;
  Regs:Registers;
 Begin
  essais:=5;
  Repeat
   Regs.AH:=$03;        { Numero de fonction pour appel interruption }
   Regs.AL:=Nombre;     { Nombre Secteurs par Piste }
   Regs.CH:=Piste;      { Numero de Piste }
   Regs.CL:=Start;      { Commencer par le secteur 1 }
   Regs.DL:=Lecteur;    { Numero de lecteur }
   Regs.DH:=Face;       { Numero de la face }
   Regs.ES:=Seg(Buffer);{ Adresse pour tampon }
   Regs.BX:=Ofs(Buffer);
   Intr($13,Regs);
   If Regs.flags and fcarry=1Then DiskReset;
   Dec(essais);
  Until(Regs.flags and fcarry=0)or(Essais=0);
  WriteTrack:=Regs.AH;
 End;
{$ENDIF}

Procedure ReadPartitionRecord;
Var
 Partition:File;
 ByteReaded:Word;
Begin
 If(IsDisk)Then Begin
  ReadTrack($80+CurrentDisk,0,0,1,1,Buffer);
 End
  Else
 If FileName<>''Then Begin
  {$I-}Assign(Partition,FileName);
  Reset(Partition,1);{$I+}
  If IOResult=0 Then Begin
   BlockRead(Partition,Buffer,512,ByteReaded);
   Close(Partition);
  End;
 End;
End;

Procedure WritePartitionRecord;
Var
 Partition:File;
 ByteReaded:Word;
Begin
 If(IsDisk)Then Begin
  WriteTrack($80+CurrentDisk,0,0,1,1,Buffer);
 End
  Else
 If FileName<>''Then Begin
  {$I-}Assign(Partition,FileName);
  Reset(Partition,1);{$I+}
  If IOResult=0 Then Begin
   BlockWrite(Partition,Buffer,512,ByteReaded);
   Close(Partition);
  End;
 End;
End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Procedure WriteLnCenter(S:String);Begin
 GotoXY((((Lo(WindMax)-Lo(WindMin))-Length(S))shr 1),WhereY);
 WriteLn(S);
End;

Procedure ShowPrompt;Begin
 Write('DISKPART>');
End;

Procedure WriteListPartition;
Var
 Partition:PartSec Absolute Buffer;
 I:Byte;
 Letter:Char;
 TypeName:String;
Begin
 Write(' ':2,'Lecteur de disque dur en cours : ');
 HighVideo;
 If FileName<>''Then WriteLn(FileName)
                Else WriteLn(CurrentDisk);
 LowVideo;
 WriteLn;
 WriteLn(' ':2,'Partition    Etat   Type   Nom du volume    Mo  SystŠme    Utilis‚');
 WriteLn(' ':2,'-----------  ------ -----  ---------------  --  ---------  -------');
 ReadPartitionRecord;
 Letter:='C';
 For I:=0 to 3 do If Partition.PartTable[I].PartType<>0Then Begin
  Write(' ':2);
  If Partition.PartTable[I].PartType in[$04,$05,$06,$07,$0B,$0C]Then Begin
   Letter:=Succ(Letter);
  End;
  HighVideo;
  Write('Partition ',I,'  ');
  LowVideo;
  If Partition.PartTable[I].Status=$80 Then Write('A')
                                       Else Write(' ');
  Write(' ':4);
  Write('Primaire',' ':2);
  Write('NOLABEL',' ':7);
  Write(2048,' ':3);
  Case Partition.PartTable[I].PartType of
   $00:TypeName:='Entr‚e vide';
   $01:TypeName:='FAT12';
   $02:TypeName:='XENIX root';
   $03:TypeName:='XENIX /usr';
   $04,$05,$06:TypeName:='FAT16';
   $07:TypeName:='NTFS ou HPFS';
   $08:TypeName:='D‚marrage AIX';
   $09:TypeName:='Donn‚es AIX';
   $0A:TypeName:='OS/2 Boot Manager';
   $0B,$0C:TypeName:='FAT32';
   $0D:TypeName:='SILICON SAFE';
   $0E,$0F:TypeName:='FAT16/WIN95';
   $11,$14,$16:TypeName:='FAT12 cach‚';
   $12:TypeName:='Partition de configuration';
   $17:TypeName:='IFS cach‚';
   $18:TypeName:='AST SmartSleep';
   $1B:TypeName:='FAT32 cach‚';
   $1C:TypeName:='FAT32';
   $1E:TypeName:='FAT16/WIN95';
   $24:TypeName:='NEC DOS';
   $27:TypeName:='MirOS';
   $2A:TypeName:='AtheOS';
   $2B:TypeName:='SylStor';
   $32:TypeName:='NOS';
   $35:TypeName:='JFS';
   Else TypeName:='Inconnu';
  End;
  Write(PadRight(TypeName,11));
  Write(100,'%');
  WriteLn;
 End;
End;

Procedure CreatePartition;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure DeletePartition;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure ShowPartition;Begin
 WriteListPartition;
End;

Procedure SelectFixedDisk;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure ACTIVECommand;
Var
 Partition:PartSec Absolute Buffer;
Begin
 ReadPartitionRecord;
 Case CurrentPartition of
  1:Begin
   Partition.PartTable[0].Status:=$80;
   Partition.PartTable[1].Status:=0;
   Partition.PartTable[2].Status:=0;
   Partition.PartTable[3].Status:=0;
  End;
  2:Begin
   Partition.PartTable[0].Status:=0;
   Partition.PartTable[1].Status:=$80;
   Partition.PartTable[2].Status:=0;
   Partition.PartTable[3].Status:=0;
  End;
  3:Begin
   Partition.PartTable[0].Status:=0;
   Partition.PartTable[1].Status:=0;
   Partition.PartTable[2].Status:=$80;
   Partition.PartTable[3].Status:=0;
  End;
  4:Begin
   Partition.PartTable[0].Status:=0;
   Partition.PartTable[1].Status:=0;
   Partition.PartTable[2].Status:=0;
   Partition.PartTable[3].Status:=$80;
  End;
 End;
 WritePartitionRecord;
 WriteLn;
 WriteLn('DiskPart marque la partition courante comme active.');
End;

Procedure ADDCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure ASSIGNCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure ATTRIBUTESCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure AUTOMOUNTCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure BREAKCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure CLEANCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure COMPACTCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure CONVERTCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure CREATECommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure DELETECommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure DETAILCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Function EXITCommand:Boolean;Begin
 EXITCommand:=True;
End;

Procedure EXPANDCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure EXTENDCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure FILESYSTEMSCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure FORMATCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure GPTCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure HELPCommand;
Var
 I:Integer;
Begin
 For I:=0 to High(CommandList)do Begin
  WriteLn(PadRight(CommandList[I],12),' - ',StrPas(CommandDescr[I]));
 End;
End;

Procedure IMPORTCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure INACTIVECommand;
Var
 Partition:PartSec Absolute Buffer;
Begin
 ReadPartitionRecord;
 Case CurrentPartition of
  1:Begin
   Partition.PartTable[0].Status:=0;
  End;
  2:Begin
   Partition.PartTable[1].Status:=0;
  End;
  3:Begin
   Partition.PartTable[2].Status:=0;
  End;
  4:Begin
   Partition.PartTable[3].Status:=0;
  End;
 End;
 WritePartitionRecord;
 WriteLn;
 WriteLn('DiskPart marque la partition courante comme inactive.');
End;

Procedure LISTCommand;
Var
 Partition:File;
 Size:LongInt;
Begin
 If StrToUpper(ExtractParam(1))='DISK'Then Begin
  If FileName<>''Then Begin
   WriteLn('Disque ###  tat     Taille   Libre   Dyn  Gpt');
   WriteLn('----------  -------  ------   ------  ---  ---');
   {$I-}Assign(Partition,FileName);
   Reset(Partition,1);{$I+}
   Size:=-1;
   If IoResult=0Then Size:=FileSize(Partition);
   Close(Partition);
   Write('Disque 0    Enligne  ');
   If Size>1073741824Then Write(Size shr 30,' G')Else
   If Size>1048576 Then Write(Size shr 20,' M')Else
   If Size>1024 Then Write(Size shr 10,' K')
                Else Write(Size,' O');
   WriteLn;
  End
   Else
  WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
 End
  Else
 If StrToUpper(ExtractParam(1))='PARTITION'Then Begin
  WriteListPartition;
 End
  Else
 WriteLn('ParamŠtre non support‚');
End;

Procedure MERGECommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure OFFLINECommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure ONLINECommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure RECOVERCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure REMCommand;Begin
 { Ne fait rien, il peut mettre n'importe quoi comme paramŠtre }
End;

Procedure REMOVECommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure REPAIRCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure RESCANCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure RETAINCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure SANCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure SELECTCommand;
Var
 R:Integer;
 Err:Word;
Begin
 If StrToUpper(ExtractParam(1))='DISK'Then Begin
  Val(ExtractParam(2),R,Err);
  If Err<>0 Then WriteLn('Valeur invalide')Else
  If Not(R in [0..31])Then Begin
   WriteLn('Num‚ro de disque invalide');
  End
   Else
  Begin
   CurrentDisk:=R;
   If FileName<>''Then Begin
    If CurrentDisk<>0 Then Begin
     WriteLn('Dans un partionnement d''un disque situ‚ dans un fichier, ',
             'le disque est toujours 0 !');
     CurrentDisk:=0;
    End;
   End;
   WriteLn;
   WriteLn('Disque ',CurrentDisk,' est maintenant la ',
           'disque s‚lectionn‚');
  End;
 End
  Else
 If StrToUpper(ExtractParam(1))='PARTITION'Then Begin
  Val(ExtractParam(2),R,Err);
  If Err<>0 Then WriteLn('Valeur invalide')Else
  If Not(R in [1..4])Then Begin
   WriteLn('Num‚ro de partition invalide');
  End
   Else
  Begin
   CurrentPartition:=R;
   WriteLn;
   WriteLn('Partition ',CurrentPartition,' est maintenant la ',
           'partition s‚lectionn‚');
  End;
 End
  Else
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure SETComamnd;
Var
 CurrParam:String;
 R:Integer;
 Partition:PartSec Absolute Buffer;
Begin
 CurrParam:=ExtractParam(1);
 If StrToUpper(Copy(CurrParam,1,3))='ID='Then Begin
  If Copy(CurrParam,4,2)='0x'Then Begin
   R:=Hex2Integer(Copy(CurrParam,6,255));
  End
   Else
  Val(CurrParam,R,Err);
  If Err<>0 Then Begin
   WriteLn('Valeur d''identificateur invalide !');
  End
   Else
  Begin
   ReadPartitionRecord;
   Partition.PartTable[CurrentPartition-1].PartType:=R;
   WritePartitionRecord;
  End;
 End
  Else
 WriteLn('ParamŠtre non reconnu');
End;

Procedure SHRINKCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure UNIQUEIDCommand;Begin
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
End;

Procedure UnknownCommand;Begin
 WriteLn('Commande non reconnu');
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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('DISKPART : Cette commande permet d''effectuer la gestion des disque durs.');
  WriteLn;
  WriteLn('Syntaxe : DISKPART [fichier]');
  WriteLn;
  WriteLn(' fichier   Le fichier a utiliser comme partition de disque');
 End
  Else
 Begin
  If SizeOf(PartSec)<>512 Then Begin
   WriteLn('Mauvaise directive de compilation. Les enregistrements ne doivent pas ˆtre align‚s');
   Halt;
  End;
  FileName:='';
  Terminated:=False;
  CurrentDisk:=0;
  CurrentPartition:=1;
  ReadPartitionRecord;
  IsDisk:=True;
  If ParamStr(1)<>''Then Begin
   FileName:=ParamStr(1);
   IsDisk:=False;
  End;
  Repeat
   ShowPrompt;
   ReadLn(CmdStr);
   ExtractCommand;
   CommandFound:=False;
   For J:=Low(CommandList) to High(CommandList) do Begin
    If CurrCommand=CommandList[J]Then Begin
     Case(J)of
      0:ACTIVECommand;
      1:ADDCommand;
      2:ASSIGNCommand;
      3:ATTRIBUTESCommand;
      4:AUTOMOUNTCommand;
      5:BREAKCommand;
      6:CLEANCommand;
      7:COMPACTCommand;
      8:CONVERTCommand;
      9:CREATECommand;
      10:DELETECommand;
      11:DETAILCommand;
      12:Terminated:=EXITCommand;
      13:EXPANDCommand;
      14:EXTENDCommand;
      15:FILESYSTEMSCommand;
      16:FORMATCommand;
      17:GPTCommand;
      18:HELPCommand;
      19:IMPORTCommand;
      20:INACTIVECommand;
      21:LISTCommand;
      22:MERGECommand;
      23:OFFLINECommand;
      24:ONLINECommand;
      25:RECOVERCommand;
      26:REMCommand;
      27:REMOVECommand;
      28:REPAIRCommand;
      29:RESCANCommand;
      30:RETAINCommand;
      31:SANCommand;
      32:SELECTCommand;
      33:SETComamnd;
      34:SHRINKCommand;
      35:UNIQUEIDCommand;
     End;
     If J<=High(CommandList)Then Begin
      CommandFound:=True;
      WriteLn;
      Break;
     End;
    End;
   End;
   If Not(CommandFound)Then UnknownCommand;
  Until Terminated;
 End;
END.
