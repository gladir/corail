{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program UNDISKPC;

{$A-}
{$R-}
{$M 65520,0,655360}

Uses DOS;

Const
 SectorSize=512;
 MaxPathLen=128;

Type
 TSector=Array[0..SectorSize-1]of Byte;

Var
 Img:File;
 ImgName,DestDir:String;
 Sec:TSector;
 BytesPerSector:Word;
 SectorsPerCluster:Byte;
 ReservedSectors:Word;
 NumFATs:Byte;
 RootEntries:Word;
 TotalSectors:LongInt;
 SectorsPerFAT:LongInt;
 RootCluster:LongInt;
 PartitionStart:LongInt;
 FATStart,RootStart,DataStart:LongInt;
 RootDirSectors:LongInt;
 ClusterCount:LongInt;
 FATType:Integer;
 BPBOffset:Integer;
 FilesExtracted,DirsCreated:LongInt;
 RootEntriesSeen:LongInt;
 IsHardDiskImage:Boolean;

Function UpStr(S:String):String;
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do
  If S[I] in['a'..'z'] Then S[I]:=Chr(Ord(S[I])-32);
 UpStr:=S;
End;

Function Path2Name(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 If N=''Then N:='DISK';
 Path2Name:=N;
End;

Function PathDir(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 PathDir:=D;
End;

Function HexDigit(N:Byte):Char;
Begin
 If N<10Then HexDigit:=Chr(Ord('0')+N)
        Else HexDigit:=Chr(Ord('A')+N-10);
End;

Function HexByte(B:Byte):String;
Begin
 HexByte:=HexDigit((B shr 4)and 15)+HexDigit(B and 15);
End;

Function JoinPath(A,B:String):String;
Begin
 If A=''Then JoinPath:=B
  Else If A[Length(A)] in['\','/'] Then JoinPath:=A+B
  Else JoinPath:=A+'\'+B;
End;

Procedure MakePath(P:String);
Var
 I:Integer;
 S:String;
Begin
 If P=''Then Exit;
 S:='';
 For I:=1 to Length(P)do Begin
  S:=S+P[I];
  If(P[I]='\')or(P[I]='/') Then Begin
   If Length(S)>1 Then Begin
    {$I-}MkDir(S);{$I+}
    If IoResult<>0 Then Begin End;
   End;
  End;
 End;
 {$I-}MkDir(P);{$I+}
 If IoResult=0 Then Inc(DirsCreated);
End;

Function LE16(Off:Integer):Word;
Begin
 LE16:=Word(Sec[Off])or(Word(Sec[Off+1])shl 8);
End;

Function LE16At(Off:Integer):Word;
Begin
 LE16At:=Word(Sec[Off])or(Word(Sec[Off+1])shl 8);
End;

Function LE32At(Off:Integer):LongInt;
Begin
 LE32At:=LongInt(Sec[Off])+
       LongInt(Sec[Off+1])*256+
       LongInt(Sec[Off+2])*65536+
       LongInt(Sec[Off+3])*16777216;
End;

Function LE32(Off:Integer):LongInt;
Begin
 LE32:=LongInt(Sec[Off])+
       LongInt(Sec[Off+1])*256+
       LongInt(Sec[Off+2])*65536+
       LongInt(Sec[Off+3])*16777216;
End;

Procedure ReadSector(LBA:LongInt);
Var
 R:Word;
Begin
 Seek(Img,LBA*SectorSize);
 BlockRead(Img,Sec,SectorSize,R);
 If R<>SectorSize Then Begin
  WriteLn('Lecture secteur impossible: ',LBA);
  Halt(1);
 End;
End;

Function LooksLikeBPB:Boolean;
Var
 BPS:Word;
 SPC:Byte;
Begin
 BPBOffset:=0;
 BPS:=LE16At(11);
 SPC:=Sec[13];
 LooksLikeBPB:=(BPS=512)and(SPC<>0)and(Sec[16]<>0)and
  (LE16At(14)<>0)and((LE16At(17)<>0)or
  ((LE16At(22)=0)and(LE32At(36)<>0)));
 If LooksLikeBPB Then Exit;
 BPS:=LE16At(12);
 SPC:=Sec[14];
 LooksLikeBPB:=(BPS=512)and(SPC<>0)and(Sec[17]<>0)and
  (LE16At(15)<>0)and((LE16At(18)<>0)or
  ((LE16At(23)=0)and(LE32At(37)<>0)));
 If LooksLikeBPB Then BPBOffset:=1;
End;

Function FindPartitionStart:LongInt;
Var
 I,O:Integer;
 T:Byte;
 LBA,SZ:LongInt;
Begin
 FindPartitionStart:=0;
 ReadSector(0);
 If LooksLikeBPB Then Exit;
 If(Sec[510]<>$55)or(Sec[511]<>$AA) Then Begin
  FindPartitionStart:=-1;
  Exit;
 End;
 For I:=0 to 3 do Begin
  O:=446+I*16;
  T:=Sec[O+4];
  LBA:=LE32(O+8);
  SZ:=LE32(O+12);
  If(T<>0)and(LBA>0)and(SZ>0) Then Begin
   FindPartitionStart:=LBA;
   Exit;
  End;
 End;
 WriteLn('Aucune partition FAT trouvee dans le MBR.');
 Halt(1);
End;

Function IsFATPartitionType(T:Byte):Boolean;
Begin
 IsFATPartitionType:=T in[$01,$04,$06,$0B,$0C,$0E,$11,$14,$16,$1B,$1C,$1E];
End;

Function IsExtendedPartitionType(T:Byte):Boolean;
Begin
 IsExtendedPartitionType:=T in[$05,$0F,$85];
End;

Function InferFloppyBySize:Boolean;
Var
 Sectors:LongInt;
Begin
 InferFloppyBySize:=False;
 Sectors:=FileSize(Img)div SectorSize;
 PartitionStart:=0;
 BytesPerSector:=SectorSize;
 ReservedSectors:=1;
 NumFATs:=2;
 TotalSectors:=Sectors;
 RootCluster:=0;
 Case Sectors of
  720:Begin
       SectorsPerCluster:=2;
       RootEntries:=112;
       SectorsPerFAT:=2;
      End;
  1440:Begin
       SectorsPerCluster:=2;
       RootEntries:=112;
       SectorsPerFAT:=3;
      End;
  2400:Begin
       SectorsPerCluster:=1;
       RootEntries:=224;
       SectorsPerFAT:=7;
      End;
  2880:Begin
       SectorsPerCluster:=1;
       RootEntries:=224;
       SectorsPerFAT:=9;
      End;
 Else
  Exit;
 End;
 RootDirSectors:=(LongInt(RootEntries)*32+SectorSize-1)div SectorSize;
 FATStart:=PartitionStart+ReservedSectors;
 RootStart:=FATStart+LongInt(NumFATs)*SectorsPerFAT;
 DataStart:=RootStart+RootDirSectors;
 ClusterCount:=(TotalSectors-(ReservedSectors+
  LongInt(NumFATs)*SectorsPerFAT+RootDirSectors))div SectorsPerCluster;
 FATType:=12;
 WriteLn('FAT12 sans BPB standard, format deduit par taille (',
  FileSize(Img),' octets).');
 InferFloppyBySize:=True;
End;

Procedure ReadBootAt(StartLBA:LongInt);
Var
 TS16:Word;
 TS32:LongInt;
 SPF16:Word;
Begin
 PartitionStart:=StartLBA;
 ReadSector(PartitionStart);
 If Not LooksLikeBPB Then Begin
  WriteLn('Secteur de demarrage FAT invalide.');
  Halt(1);
 End;
 BytesPerSector:=LE16At(11+BPBOffset);
 If BytesPerSector<>SectorSize Then Begin
  WriteLn('Seuls les secteurs de 512 octets sont supportes.');
  Halt(1);
 End;
 SectorsPerCluster:=Sec[13+BPBOffset];
 ReservedSectors:=LE16At(14+BPBOffset);
 NumFATs:=Sec[16+BPBOffset];
 RootEntries:=LE16At(17+BPBOffset);
 TS16:=LE16At(19+BPBOffset);
 TS32:=LE32At(32+BPBOffset);
 If TS16<>0 Then TotalSectors:=TS16 Else TotalSectors:=TS32;
 SPF16:=LE16At(22+BPBOffset);
 If SPF16<>0 Then SectorsPerFAT:=SPF16
             Else SectorsPerFAT:=LE32At(36+BPBOffset);
 If SectorsPerFAT=0 Then Begin
  WriteLn('Taille FAT invalide.');
  Halt(1);
 End;
 If RootEntries=0 Then RootCluster:=LE32At(44+BPBOffset)
                  Else RootCluster:=0;
 RootDirSectors:=(LongInt(RootEntries)*32+SectorSize-1)div SectorSize;
 FATStart:=PartitionStart+ReservedSectors;
 RootStart:=FATStart+LongInt(NumFATs)*SectorsPerFAT;
 DataStart:=RootStart+RootDirSectors;
 ClusterCount:=(TotalSectors-(ReservedSectors+
  LongInt(NumFATs)*SectorsPerFAT+RootDirSectors))div SectorsPerCluster;
 If ClusterCount<4085 Then FATType:=12
  Else If ClusterCount<65525 Then FATType:=16
  Else FATType:=32;
 If(FATType=32)and(RootCluster<2)Then RootCluster:=2;
 WriteLn('FAT',FATType,'  secteurs=',TotalSectors,
  '  cluster=',SectorsPerCluster,'  racine=',RootEntries);
End;

Procedure ReadBoot;
Begin
 PartitionStart:=FindPartitionStart;
 If PartitionStart<0 Then Begin
  If InferFloppyBySize Then Exit;
  WriteLn('Image disque PC invalide: ni BPB FAT ni MBR.');
  Halt(1);
 End;
 ReadBootAt(PartitionStart);
End;

Function FATByte(Offset:LongInt):Byte;
Var
 R:Word;
 B:Byte;
Begin
 Seek(Img,(FATStart*SectorSize)+Offset);
 BlockRead(Img,B,1,R);
 If R<>1 Then Begin
  WriteLn('Lecture FAT impossible.');
  Halt(1);
 End;
 FATByte:=B;
End;

Function NextCluster(Cl:LongInt):LongInt;
Var
 O:LongInt;
 B1,B2:Byte;
 V:LongInt;
Begin
 If FATType=12 Then Begin
  O:=LongInt(Cl)+(LongInt(Cl)div 2);
  B1:=FATByte(O);
  B2:=FATByte(O+1);
  V:=Word(B1)or(Word(B2)shl 8);
  If(Cl and 1)<>0 Then V:=V shr 4 Else V:=V and $0FFF;
  NextCluster:=V;
 End
  Else If FATType=32 Then Begin
  O:=LongInt(Cl)*4;
  V:=LongInt(FATByte(O))or(LongInt(FATByte(O+1))shl 8)or
     (LongInt(FATByte(O+2))shl 16)or(LongInt(FATByte(O+3))shl 24);
  NextCluster:=V and $0FFFFFFF;
 End
  Else
 Begin
  O:=LongInt(Cl)*2;
  NextCluster:=Word(FATByte(O))or(Word(FATByte(O+1))shl 8);
 End;
End;

Function IsEOC(Cl:LongInt):Boolean;
Begin
 If FATType=12 Then IsEOC:=Cl>=$0FF8
  Else If FATType=16 Then IsEOC:=Cl>=$FFF8
  Else IsEOC:=Cl>=$0FFFFFF8;
End;

Function ClusterSector(Cl:LongInt):LongInt;
Begin
 ClusterSector:=DataStart+LongInt(Cl-2)*SectorsPerCluster;
End;

Function CleanChar(C:Char):Char;
Begin
 If C in['A'..'Z','a'..'z','0'..'9','$','%','''','-','_','@','~','`','!','(',')','{','}','^','#','&'] Then
  CleanChar:=C
 Else CleanChar:='_';
End;

Function ValidNameChar(B:Byte):Boolean;
Var
 C:Char;
Begin
 C:=Chr(B);
 ValidNameChar:=(B=32)or
  (C in['A'..'Z','a'..'z','0'..'9','$','%','''','-','_','@','~','`','!','(',')','{','}','^','#','&']);
End;

Function ValidDirEntry(Off:Integer):Boolean;
Var
 I:Integer;
 Attr:Byte;
Begin
 ValidDirEntry:=False;
 If(Sec[Off]=$00)or(Sec[Off]=$E5)Then Exit;
 If Not ValidNameChar(Sec[Off])or(Sec[Off]=32)Then Exit;
 For I:=0 to 10 do If Not ValidNameChar(Sec[Off+I])Then Exit;
 Attr:=Sec[Off+11];
 If(Attr and $C0)<>0Then Exit;
 ValidDirEntry:=True;
End;

Function EntryName(Off:Integer):String;
Var
 I:Integer;
 N,E:String;
Begin
 N:='';
 For I:=0 to 7 do If Sec[Off+I]<>32 Then N:=N+CleanChar(Chr(Sec[Off+I]));
 E:='';
 For I:=8 to 10 do If Sec[Off+I]<>32 Then E:=E+CleanChar(Chr(Sec[Off+I]));
 If E<>''Then EntryName:=N+'.'+E Else EntryName:=N;
End;

Procedure SetFileDate(P:String;T,D:Word);
Var
 F:File;
 Stamp:LongInt;
 R:Integer;
Begin
 Assign(F,P);
 {$I-}Reset(F,1);{$I+}
 R:=IoResult;
 If R<>0 Then Exit;
 Stamp:=(LongInt(D)shl 16)or T;
 SetFTime(F,Stamp);
 Close(F);
End;

Procedure ExtractFile(Cl:LongInt;Size:LongInt;OutName:String;T,D:Word);
Var
 F:File;
 W:Word;
 ToWrite:Word;
 S,I:LongInt;
 Cur:LongInt;
Begin
 MakePath(PathDir(OutName));
 Assign(F,OutName);
 {$I-}Rewrite(F,1);{$I+}
 If IoResult<>0 Then Begin
  WriteLn('Impossible de creer ',OutName);
  Halt(1);
 End;
 Cur:=Cl;
 While(Size>0)and(Cur>=2)and(Not IsEOC(Cur))do Begin
  S:=ClusterSector(Cur);
  For I:=0 to SectorsPerCluster-1 do Begin
   If Size<=0 Then Break;
   ReadSector(S+I);
   If Size>SectorSize Then ToWrite:=SectorSize Else ToWrite:=Word(Size);
   BlockWrite(F,Sec,ToWrite,W);
   If W<>ToWrite Then Begin
    Close(F);
    WriteLn('Erreur ecriture ',OutName);
    Halt(1);
   End;
   Dec(Size,ToWrite);
  End;
  Cur:=NextCluster(Cur);
 End;
 Close(F);
 SetFileDate(OutName,T,D);
 Inc(FilesExtracted);
 WriteLn(OutName);
End;

Procedure ProcessDir(StartCl:LongInt;Path:String;IsRoot:Boolean);Forward;

Procedure HandleEntry(Off:Integer;Path:String);
Var
 Attr:Byte;
 Name,OutName:String;
 Cl:LongInt;
 Size:LongInt;
 T,D:Word;
Begin
 If Not ValidDirEntry(Off)Then Exit;
 Inc(RootEntriesSeen);
 Attr:=Sec[Off+11];
 If(Attr and $0F)=$0F Then Exit;      { nom long VFAT }
 If(Attr and $08)<>0 Then Exit;       { volume label }
 Name:=EntryName(Off);
 If(Name='')or(Name='.')or(Name='..') Then Exit;
 Cl:=LE16(Off+26);
 If FATType=32 Then Cl:=Cl+(LongInt(LE16(Off+20))shl 16);
 Size:=LE32(Off+28);
 T:=LE16(Off+22);
 D:=LE16(Off+24);
 OutName:=JoinPath(Path,Name);
 If(Attr and $10)<>0 Then Begin
  MakePath(OutName);
  If Cl>=2 Then ProcessDir(Cl,OutName,False);
 End
  Else ExtractFile(Cl,Size,OutName,T,D);
End;

Procedure ProcessRoot(Path:String);
Var
 S:LongInt;
 I:Integer;
 Entry:LongInt;
 Done:Boolean;
Begin
 Done:=False;
 Entry:=0;
 For S:=0 to RootDirSectors-1 do Begin
  If Done Then Break;
  ReadSector(RootStart+S);
  For I:=0 to 15 do Begin
   If Entry>=RootEntries Then Begin Done:=True; Break; End;
   If Sec[I*32]=$00 Then Begin Done:=True; Break; End;
   HandleEntry(I*32,Path);
   ReadSector(RootStart+S);
   Inc(Entry);
  End;
 End;
End;

Procedure ProcessDir(StartCl:LongInt;Path:String;IsRoot:Boolean);
Var
 Cur:LongInt;
 S,I,J:LongInt;
 Done:Boolean;
Begin
 If IsRoot Then Begin
  ProcessRoot(Path);
  Exit;
 End;
 Cur:=StartCl;
 Done:=False;
 While(Cur>=2)and(Not IsEOC(Cur))and(Not Done)do Begin
  S:=ClusterSector(Cur);
  For I:=0 to SectorsPerCluster-1 do Begin
   If Done Then Break;
   ReadSector(S+I);
   For J:=0 to 15 do Begin
    If Sec[J*32]=$00 Then Begin Done:=True; Break; End;
    HandleEntry(J*32,Path);
    ReadSector(S+I);
   End;
  End;
  Cur:=NextCluster(Cur);
 End;
End;

Procedure Help;Begin
 WriteLn('UNDISKPC : Cette commande permet d''extraire les fichiers ',
         'd''une image disque PC FAT12/FAT16/FAT32.');
 WriteLn;
 WriteLn('Syntaxe : UNDISKPC image.img [destination]');
 WriteLn;
 WriteLn('Supporte les images disquette FAT12 et les disques avec MBR/FAT.');
 WriteLn('Les noms longs VFAT sont ignores; les noms 8.3 DOS sont utilises.');
End;

Procedure ExtractCurrentVolume(Path:String);
Begin
 MakePath(Path);
 If FATType=32 Then ProcessDir(RootCluster,Path,False)
               Else ProcessDir(0,Path,True);
End;

Procedure ExtractHardDiskImage;
Var
 I,O:Integer;
 PType:Array[0..3]of Byte;
 PLBA,PSZ:Array[0..3]of LongInt;
 PartPath:String;
 S:String;
 Any:Boolean;

 Procedure ExtractPartition(N:Integer;LBA,SZ:LongInt;T:Byte);
 Begin
  Str(N,S);
  PartPath:=JoinPath(DestDir,'PART'+S);
  WriteLn('Partition ',N,' type=$',HexByte(T),' LBA=',LBA,' secteurs=',SZ);
  ReadBootAt(LBA);
  ExtractCurrentVolume(PartPath);
 End;

 Procedure ProcessExtended(ExtBase:LongInt;Var NextNo:Integer);
 Var
  EBR:LongInt;
  T1,T2:Byte;
  L1,S1,L2,S2:LongInt;
  Guard:Integer;
 Begin
  EBR:=ExtBase;
  Guard:=0;
  While(EBR>0)and(Guard<128)do Begin
   Inc(Guard);
   ReadSector(EBR);
   If(Sec[510]<>$55)or(Sec[511]<>$AA)Then Exit;
   T1:=Sec[446+4];
   L1:=LE32(446+8);
   S1:=LE32(446+12);
   If IsFATPartitionType(T1)and(S1>0)Then Begin
    ExtractPartition(NextNo,EBR+L1,S1,T1);
    Inc(NextNo);
    Any:=True;
   End;
   T2:=Sec[446+16+4];
   L2:=LE32(446+16+8);
   S2:=LE32(446+16+12);
   If IsExtendedPartitionType(T2)and(S2>0)Then EBR:=ExtBase+L2
    Else EBR:=0;
  End;
 End;

Var
 NextNo:Integer;
Begin
 ReadSector(0);
 If(Sec[510]<>$55)or(Sec[511]<>$AA)Then Begin
  WriteLn('MBR invalide.');
  Halt(1);
 End;
 For I:=0 to 3 do Begin
  O:=446+I*16;
  PType[I]:=Sec[O+4];
  PLBA[I]:=LE32(O+8);
  PSZ[I]:=LE32(O+12);
 End;
 Any:=False;
 NextNo:=1;
 For I:=0 to 3 do Begin
  If IsFATPartitionType(PType[I])and(PLBA[I]>0)and(PSZ[I]>0)Then Begin
   Any:=True;
   ExtractPartition(NextNo,PLBA[I],PSZ[I],PType[I]);
   Inc(NextNo);
  End
   Else If IsExtendedPartitionType(PType[I])and(PLBA[I]>0)and(PSZ[I]>0)Then Begin
   ProcessExtended(PLBA[I],NextNo);
  End;
 End;
 If Not Any Then Begin
  WriteLn('Aucune partition FAT primaire trouvee.');
  Halt(1);
 End;
End;

Begin
 If(ParamCount<1)or(ParamStr(1)='/?')or(ParamStr(1)='-h')or
   (ParamStr(1)='--help') Then Begin
  Help;
  Halt;
 End;
 ImgName:=ParamStr(1);
 If ParamCount>=2 Then DestDir:=ParamStr(2)
                 Else DestDir:=Path2Name(ImgName);
 Assign(Img,ImgName);
 FileMode:=0;
 {$I-}Reset(Img,1);{$I+}
 If IoResult<>0 Then Begin
  WriteLn('Impossible d''ouvrir ',ImgName);
  Halt(1);
 End;
 FilesExtracted:=0;
 DirsCreated:=0;
 RootEntriesSeen:=0;
 MakePath(DestDir);
 ReadSector(0);
 IsHardDiskImage:=(FileSize(Img)>8192)and
  (Sec[510]=$55)and(Sec[511]=$AA)and(Not LooksLikeBPB);
 If IsHardDiskImage Then ExtractHardDiskImage
  Else Begin
  ReadBoot;
  ExtractCurrentVolume(DestDir);
 End;
 Close(Img);
 If FilesExtracted=0 Then Begin
  If RootEntriesSeen=0 Then Begin
   WriteLn('Aucun fichier trouve dans le repertoire racine FAT.');
   WriteLn('Note: le MBR/FDISK peut etre valide meme si la partition FAT est vide.');
   WriteLn('Racine LBA=',RootStart,'  FAT LBA=',FATStart,
    '  donnees LBA=',DataStart);
  End
   Else
  WriteLn('Entrees trouvees dans la racine, mais aucun fichier regulier extrait.');
 End;
 WriteLn(FilesExtracted,' fichier(s) extrait(s), ',
  DirsCreated,' repertoire(s) cree(s).');
End.
