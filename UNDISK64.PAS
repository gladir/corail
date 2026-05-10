{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/commodore64-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program UNDISK64;

{$A-}

Const
 SectorCount:Array[1..40] of Integer=(
  21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,
  19,19,19,19,19,19,19,
  18,18,18,18,18,18,
  17,17,17,17,17,
  17,17,17,17,17
 );

 SectorOfs:Array[1..40] of Integer=(
  0,21,42,63,84,105,126,147,168,189,210,231,252,273,294,315,336,
  357,376,395,414,433,452,471,
  490,508,526,544,562,580,
  598,615,632,649,666,
  683,700,717,734,751
 );

 KindExt:Array[0..7] of String[3]=(
  'DEL','SEQ','PRG','USR','REL','___','___','___'
 );

Type
 tBAM=Record
  Track:Byte;
  Sector:Byte;
  Format:Byte;
  Pad0:Byte;
  FAT:Array[1..35,1..4] of byte;
  Name:Array[1..18] of char;
  ID:Array[1..2] of char;
  Pad1:Byte;
  Chars:Array[1..2] of Char;
  Pad2:Array[1..4] of Byte;
  Pad3:Array[1..85] of Byte;
 End;

 TDirEntry=Record
  Kind:Byte;
  dTrack:Byte;
  dSector:Byte;
  Name:Array[1..16] of Char;
  sTrack:Byte;
  sSector:Byte;
  Len:Byte;
  pad0:Array[1..4] of Byte;
  oTrack:Byte;
  oSector:Byte;
  Blocks:Word;
  pad1:Array[1..2] of Byte;
 End;

 TDirectory=Record
  NextTrack :byte;
  NextSector:byte;
  Entry:Array[0..7] of TDirEntry;
 End;

 TSector=Array[0..255] of Byte;

Function SectorOffset(Track,Sector:word):LongInt;Begin
 If(Track<1)or(Track>40)or(Sector<0)or(Sector>=SectorCount[Track])Then
  SectorOffset:=-1
 Else
  SectorOffset:=(LongInt(SectorOfs[Track])+Sector) shl 8;
End;

Function ReadSector(Var Handle:File;Track,Sector:word; Var Data):Boolean;
Var
 Offset:LongInt;
 ByteReaded:Word;
Begin
 Offset:=SectorOffset(Track,Sector);
 If Offset<0 Then Begin
  ReadSector:=False;
  Exit;
 End;
 {$I-}Seek(Handle,Offset);
 BlockRead(Handle,Data,256,ByteReaded);{$I+}
 ReadSector:=(IOResult=0)and(ByteReaded=256);
End;

{ Convertit un caract�re PETSCII en ASCII pour utilisation comme nom de
  fichier sur le syst�me h�te. Les caract�res non-imprimables ou interdits
  sont remplac�s par '_'. }
Function PetToFile(C:Char):Char;
Var B:Byte;
Begin
 B:=Ord(C);
 Case B of
  65..90 : PetToFile:=Chr(B+32);                  { A-Z PETSCII -> a-z }
  97..122: PetToFile:=Chr(B-32);                  { a-z PETSCII -> A-Z }
  193..218:PetToFile:=Chr(B-128);                 { Maj. graphique -> A-Z }
  48..57,45,46:PetToFile:=C;                      { 0-9 - . }
 Else
  PetToFile:='_';
 End;
End;

Function TrimName(Const Raw:Array of Char; Len:Byte):String;
Var
 I,L:Byte;
 S:String;
Begin
 L:=Len;
 While(L>0)and((Raw[L-1]=#$A0)or(Raw[L-1]=' '))do Dec(L);
 S:='';
 For I:=0 to L-1 do S:=S+PetToFile(Raw[I]);
 If S='' Then S:='NONAME';
 TrimName:=S;
End;

{ Cr�e le r�pertoire indiqu� s'il n'existe pas d�j�. Retourne True si le
  r�pertoire est utilisable apr�s l'appel. Une cha�ne vide est consid�r�e
  comme le r�pertoire courant. }
Function EnsureDir(Const Dir:String):Boolean;
Var
 SaveDir,Clean:String;
 Last:Char;
 Existed:Boolean;
Begin
 If Dir='' Then Begin
  EnsureDir:=True;
  Exit;
 End;
 Clean:=Dir;
 Last:=Clean[Length(Clean)];
 If((Last='\')or(Last='/'))and(Length(Clean)>1)Then
  Clean:=Copy(Clean,1,Length(Clean)-1);
 If(Length(Clean)=2)and(Clean[2]=':')Then Begin
  EnsureDir:=True;
  Exit;
 End;
 GetDir(0,SaveDir);
 {$I-}ChDir(Clean);{$I+}
 Existed:=(IOResult=0);
 If Existed Then Begin
  {$I-}ChDir(SaveDir);{$I+}
  If IOResult=0 Then ;
  EnsureDir:=True;
  Exit;
 End;
 {$I-}MkDir(Clean);{$I+}
 EnsureDir:=(IOResult=0);
End;

{ Construit un chemin complet en concat�nant le r�pertoire de destination
  et le nom de fichier (en ajoutant un s�parateur si n�cessaire). }
Function MakePath(Const Dir,Name:String):String;
Var Last:Char;
Begin
 If Dir='' Then MakePath:=Name
 Else Begin
  Last:=Dir[Length(Dir)];
  If(Last='\')or(Last='/')or(Last=':')Then MakePath:=Dir+Name
  Else MakePath:=Dir+'\'+Name;
 End;
End;

Function ExtractFile(Var F:File; Track,Sector:Byte; Const OutName:String;
                     IsRel:Boolean):Boolean;
Var
 Out:File;
 Buf:TSector;
 NextT,NextS:Byte;
 Count:Word;
 Written:Word;
 OK:Boolean;
Begin
 {$I-}Assign(Out,OutName);
 Rewrite(Out,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('  Erreur: impossible de cr�er ',OutName);
  ExtractFile:=False;
  Exit;
 End;
 OK:=True;
 NextT:=Track;
 NextS:=Sector;
 While(NextT<>0)and OK do Begin
  If Not ReadSector(F,NextT,NextS,Buf)Then Begin
   WriteLn('  Erreur: secteur illisible (',NextT,',',NextS,') dans ',OutName);
   OK:=False;
   Break;
  End;
  NextT:=Buf[0];
  NextS:=Buf[1];
  If NextT=0 Then Count:=NextS-1   { dernier secteur: NextS = index du dernier octet }
            Else Count:=254;
  If Count>254 Then Count:=254;
  {$I-}BlockWrite(Out,Buf[2],Count,Written);{$I+}
  If(IOResult<>0)or(Written<>Count)Then OK:=False;
 End;
 {$I-}Close(Out);{$I+}
 If IOResult<>0 Then OK:=False;
 ExtractFile:=OK;
 If IsRel then ; { �vite warning }
End;

Var
 F:File;
 BAM:tBAM;
 DIR:TDirectory;
 ImgName:String;
 OutDir:String;
 BaseName,FullName:String;
 KType:Byte;
 Total,OkCount:Word;
 E:Word;

BEGIN
 If(ParamCount=0)or(ParamStr(1)='/?')or(ParamStr(1)='--help')or
   (ParamStr(1)='-h')Then Begin
  WriteLn('UNDISK64 : Cette commande permet d''extraire tous les fichiers ',
                     'contenus dans une image disque de format .D64 du ',
                     'Commodore 64.');
  WriteLn;
  WriteLn('Syntaxe : UNDISK64 fichier.D64 [r�pertoire]');
  WriteLn;
  WriteLn('  fichier.D64   Nom du fichier d''image disque � extraire.');
  WriteLn('  r�pertoire    R�pertoire de destination (par d�faut : courant).');
  Halt;
 End;

 ImgName:=ParamStr(1);
 If ParamCount>=2 Then OutDir:=ParamStr(2) Else OutDir:='';

 If Not EnsureDir(OutDir)Then Begin
  WriteLn('Impossible de cr�er le r�pertoire de destination : ',OutDir);
  Halt(1);
 End;

 {$I-}Assign(F,ImgName);
 Reset(F,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier : ',ImgName);
  Halt(1);
 End;

 If Not ReadSector(F,18,0,BAM)Then Begin
  WriteLn('Impossible de lire le BAM (piste 18, secteur 0).');
  Close(F);
  Halt(1);
 End;

 WriteLn('Extraction de "',ImgName,'"...');
 If OutDir<>''Then WriteLn('Vers : ',OutDir);

 Total:=0;
 OkCount:=0;

 Dir.NextTrack:=BAM.Track;
 Dir.NextSector:=BAM.Sector;
 While(Dir.NextTrack<>0)and ReadSector(F,Dir.NextTrack,Dir.NextSector,Dir)do Begin
  For E:=0 to 7 do With Dir.Entry[E] do Begin
   If(Kind<>0)and(dTrack<>0)Then Begin
    KType:=Kind and 7;
    BaseName:=TrimName(Name,SizeOf(Name));
    FullName:=MakePath(OutDir,BaseName+'.'+KindExt[KType]);
    Write('  ',FullName,' (',Blocks,' blocs) ... ');
    Inc(Total);
    If ExtractFile(F,dTrack,dSector,FullName,KType=4)Then Begin
     Inc(OkCount);
     WriteLn('OK');
    End Else WriteLn('�CHEC');
   End;
  End;
 End;

 Close(F);
 WriteLn;
 WriteLn(OkCount,' / ',Total,' fichier(s) extrait(s).');
END.
