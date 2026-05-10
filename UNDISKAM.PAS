{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)

  UNDISKAM : extraction d'une image disque Amiga (.ADF), syst�mes
  de fichiers OFS (DOS\0/\2/\4) et FFS (DOS\1/\3/\5).

  Format ADF DD : 80 cyl. * 2 t�tes * 11 sect. = 1760 blocs de 512 octets.
  Bloc racine : g�n�ralement 880. Big-endian.
}

Program UNDISKAM;

{$A-}

Const
 BSIZE             = 512;
 HT_SIZE           = 72;       { Nombre d'entr�es dans la hash/data table }
 ROOT_BLOCK_DD     = 880;
 ROOT_BLOCK_HD     = 1760;
 T_HEADER          = 2;
 T_LIST            = 16;
 ST_ROOT           = 1;
 ST_USERDIR        = 2;
 ST_FILE           = -3;

Type
 TBlock = Array[0..BSIZE-1] of Byte;

Var
 ADF        : File;
 BlockCount : LongInt;
 IsFFS      : Boolean;
 RootBlk    : LongInt;
 OutDir     : String;
 TotalFiles : Word;
 OkFiles    : Word;

{ Lecture d'un entier 32-bit big-endian dans un bloc. }
Function BE32(Var B:TBlock; Ofs:Word):LongInt;
Begin
 BE32:=(LongInt(B[Ofs]) shl 24) or (LongInt(B[Ofs+1]) shl 16)
       or (LongInt(B[Ofs+2]) shl 8) or LongInt(B[Ofs+3]);
End;

Function ReadBlock(BlockNum:LongInt; Var B:TBlock):Boolean;
Var BytesRead:Word;
Begin
 If(BlockNum<0)or(BlockNum>=BlockCount)Then Begin
  ReadBlock:=False;
  Exit;
 End;
 {$I-}Seek(ADF,BlockNum*BSIZE);
 BlockRead(ADF,B,BSIZE,BytesRead);{$I+}
 ReadBlock:=(IOResult=0)and(BytesRead=BSIZE);
End;

{ Cha�ne BCPL : octet 0 = longueur, suivi des caract�res. }
Function ReadBCPL(Var B:TBlock; Ofs:Word; MaxLen:Byte):String;
Var
 Len,I:Byte;
 S:String;
Begin
 Len:=B[Ofs];
 If Len>MaxLen Then Len:=MaxLen;
 S:='';
 For I:=1 to Len do S:=S+Chr(B[Ofs+I]);
 ReadBCPL:=S;
End;

{ Remplace les caract�res interdits sous Windows par '_'. }
Function SanName(Const S:String):String;
Var
 I:Byte;
 R:String;
 C:Char;
Begin
 R:='';
 For I:=1 to Length(S) do Begin
  C:=S[I];
  If(C='\')or(C='/')or(C=':')or(C='*')or(C='?')or
    (C='"')or(C='<')or(C='>')or(C='|')or(Ord(C)<32)Then C:='_';
  R:=R+C;
 End;
 If R='' Then R:='NONAME';
 SanName:=R;
End;

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

Function EnsureDir(Const Dir:String):Boolean;
Var
 SaveDir,Clean:String;
 Last:Char;
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
 If IOResult=0 Then Begin
  {$I-}ChDir(SaveDir);{$I+}
  If IOResult=0 Then ;
  EnsureDir:=True;
  Exit;
 End;
 {$I-}MkDir(Clean);{$I+}
 EnsureDir:=(IOResult=0);
End;

{ Extrait un fichier � partir de son bloc d'en-t�te.
  - FFS : les blocs de donn�es sont 512 octets bruts.
  - OFS : chaque bloc de donn�es a un en-t�te de 24 octets ;
          taille utile en offset 12 du bloc.
  Les pointeurs dataBlocks[] sont stock�s en ORDRE INVERSE :
  dataBlocks[0] (1er bloc du fichier) � l'offset BSIZE-204 = 308,
  dataBlocks[i] � l'offset 24 + (HT_SIZE-1-i)*4. }
Function ExtractFile(Var Hdr:TBlock; Const Path:String):Boolean;
Var
 OutF:File;
 ByteSize,Remaining,DBlockNum,ExtBlk:LongInt;
 DB:TBlock;
 CurHdr:TBlock;
 I,Count,Written:Word;
 ChunkSize:Word;
 Tmp:LongInt;
 OK:Boolean;
Begin
 ByteSize:=BE32(Hdr,BSIZE-188);
 Remaining:=ByteSize;
 {$I-}Assign(OutF,Path);
 Rewrite(OutF,1);{$I+}
 If IOResult<>0 Then Begin
  ExtractFile:=False;
  Exit;
 End;
 OK:=True;
 Move(Hdr,CurHdr,BSIZE);
 While OK and(Remaining>0)do Begin
  Count:=BE32(CurHdr,8);
  If Count>HT_SIZE Then Count:=HT_SIZE;
  For I:=0 to Count-1 do Begin
   If Remaining<=0 Then Break;
   DBlockNum:=BE32(CurHdr,24+(HT_SIZE-1-I)*4);
   If DBlockNum=0 Then Begin OK:=False; Break; End;
   If Not ReadBlock(DBlockNum,DB)Then Begin OK:=False; Break; End;
   If IsFFS Then Begin
    If Remaining>BSIZE Then ChunkSize:=BSIZE Else ChunkSize:=Remaining;
    {$I-}BlockWrite(OutF,DB,ChunkSize,Written);{$I+}
   End Else Begin
    Tmp:=BE32(DB,12);
    If(Tmp<0)or(Tmp>BSIZE-24)Then Tmp:=BSIZE-24;
    If Tmp>Remaining Then Tmp:=Remaining;
    ChunkSize:=Tmp;
    {$I-}BlockWrite(OutF,DB[24],ChunkSize,Written);{$I+}
   End;
   If(IOResult<>0)or(Written<>ChunkSize)Then Begin OK:=False; Break; End;
   Dec(Remaining,ChunkSize);
  End;
  If(Not OK)or(Remaining<=0)Then Break;
  ExtBlk:=BE32(CurHdr,BSIZE-8);
  If ExtBlk=0 Then Break;
  If Not ReadBlock(ExtBlk,CurHdr)Then Begin OK:=False; Break; End;
 End;
 {$I-}Close(OutF);{$I+}
 If IOResult<>0 Then OK:=False;
 ExtractFile:=OK and(Remaining<=0);
End;

Procedure WalkDir(DirBlock:LongInt; Const Path:String); Forward;

Procedure ProcessEntry(EntryBlock:LongInt; Const Path:String;
                       Var NextInChain:LongInt);
Var
 B:TBlock;
 SecType:LongInt;
 RawName,Name,Sub,FullPath:String;
Begin
 NextInChain:=0;
 If Not ReadBlock(EntryBlock,B)Then Exit;
 If BE32(B,0)<>T_HEADER Then Exit;
 SecType:=BE32(B,BSIZE-4);
 RawName:=ReadBCPL(B,BSIZE-80,30);
 Name:=SanName(RawName);
 NextInChain:=BE32(B,BSIZE-16);
 If SecType=ST_USERDIR Then Begin
  Sub:=MakePath(Path,Name);
  Write('  [DIR] ',Sub,' ... ');
  If EnsureDir(Sub)Then Begin
   WriteLn('OK');
   WalkDir(EntryBlock,Sub);
  End Else WriteLn('�CHEC');
 End Else
 If SecType=ST_FILE Then Begin
  FullPath:=MakePath(Path,Name);
  Inc(TotalFiles);
  Write('  ',FullPath,' (',BE32(B,BSIZE-188),' o.) ... ');
  If ExtractFile(B,FullPath)Then Begin
   Inc(OkFiles);
   WriteLn('OK');
  End Else WriteLn('�CHEC');
 End;
 { Liens (ST_LFILE=-4, ST_LDIR=4, ST_SOFTLINK=3) ignor�s. }
End;

Procedure WalkDir(DirBlock:LongInt; Const Path:String);
Var
 B:TBlock;
 I:Word;
 Slot,Entry,Next:LongInt;
Begin
 If Not ReadBlock(DirBlock,B)Then Exit;
 If BE32(B,0)<>T_HEADER Then Exit;
 For I:=0 to HT_SIZE-1 do Begin
  Slot:=BE32(B,24+I*4);
  Entry:=Slot;
  While Entry<>0 do Begin
   ProcessEntry(Entry,Path,Next);
   Entry:=Next;
  End;
 End;
End;

Procedure DetectFormat(Var Boot:TBlock);
Var Flag:Byte;
Begin
 If(Boot[0]=Ord('D'))and(Boot[1]=Ord('O'))and(Boot[2]=Ord('S'))Then Begin
  Flag:=Boot[3];
  IsFFS:=(Flag and 1)<>0;
  Case Flag of
   0:WriteLn('Format : OFS');
   1:WriteLn('Format : FFS');
   2:WriteLn('Format : OFS (international)');
   3:WriteLn('Format : FFS (international)');
   4:WriteLn('Format : OFS (dir cache)');
   5:WriteLn('Format : FFS (dir cache)');
  Else
   WriteLn('Format : DOS\',Flag,' (inconnu, suppos� FFS=',Ord(IsFFS),')');
  End;
 End Else Begin
  WriteLn('Avertissement : signature DOS absente du boot block.');
  IsFFS:=True;
 End;
End;

Var
 ImgName,VolName:String;
 Boot,Root:TBlock;
 FSize:LongInt;

BEGIN
 If(ParamCount=0)or(ParamStr(1)='/?')or(ParamStr(1)='--help')or
   (ParamStr(1)='-h')Then Begin
  WriteLn('UNDISKAM : Cette commande permet d''extraire tous les fichiers ',
                     'contenus dans une image disque de format .ADF de ',
                     'l''Amiga (syst�mes OFS et FFS).');
  WriteLn;
  WriteLn('Syntaxe : UNDISKAM fichier.ADF [r�pertoire]');
  WriteLn;
  WriteLn('  fichier.ADF   Nom du fichier d''image disque � extraire.');
  WriteLn('  r�pertoire    R�pertoire de destination (par d�faut : courant).');
  Halt;
 End;

 ImgName:=ParamStr(1);
 If ParamCount>=2 Then OutDir:=ParamStr(2) Else OutDir:='';

 If Not EnsureDir(OutDir)Then Begin
  WriteLn('Impossible de cr�er le r�pertoire de destination : ',OutDir);
  Halt(1);
 End;

 {$I-}Assign(ADF,ImgName);
 Reset(ADF,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier : ',ImgName);
  Halt(1);
 End;

 FSize:=FileSize(ADF);
 BlockCount:=FSize div BSIZE;

 If Not ReadBlock(0,Boot)Then Begin
  WriteLn('Impossible de lire le boot block.');
  Close(ADF);
  Halt(1);
 End;
 DetectFormat(Boot);

 { Choix du bloc racine selon la taille (DD = 1760 blocs, HD = 3520). }
 If BlockCount>=3520 Then RootBlk:=ROOT_BLOCK_HD
                     Else RootBlk:=ROOT_BLOCK_DD;

 If Not ReadBlock(RootBlk,Root)Then Begin
  WriteLn('Impossible de lire le bloc racine (',RootBlk,').');
  Close(ADF);
  Halt(1);
 End;

 If(BE32(Root,0)<>T_HEADER)or(BE32(Root,BSIZE-4)<>ST_ROOT)Then Begin
  WriteLn('Bloc racine invalide.');
  Close(ADF);
  Halt(1);
 End;

 VolName:=ReadBCPL(Root,BSIZE-80,30);
 WriteLn('Volume : "',VolName,'" (',BlockCount,' blocs)');
 WriteLn('Extraction vers : ',OutDir);
 WriteLn;

 TotalFiles:=0;
 OkFiles:=0;
 WalkDir(RootBlk,OutDir);

 Close(ADF);
 WriteLn;
 WriteLn(OkFiles,' / ',TotalFiles,' fichier(s) extrait(s).');
END.
