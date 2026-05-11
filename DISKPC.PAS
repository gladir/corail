{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program DISKPC;

{$A-}
{$R-}
{$M 65520,0,655360}

Uses DOS;

Const
 SectorSize=512;

Type
 TSector=Array[0..SectorSize-1]of Byte;

Var
 Img:File;
 ImgName:String;
 Sec:TSector;
 BytesPerSector:Word;
 SectorsPerCluster:Byte;
 ReservedSectors:Word;
 NumFATs:Byte;
 RootEntries:Word;
 TotalSectors:LongInt;
 SectorsPerFAT:LongInt;
 PartitionStart:LongInt;
 FATStart,RootStart,DataStart:LongInt;
 RootDirSectors:LongInt;
 ClusterCount:LongInt;
 FATType:Integer;
 RootCluster:LongInt;
 BPBOffset:Integer;

Function UpStr(S:String):String;
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 UpStr:=S;
End;

Function BaseName(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 BaseName:=N+E;
End;

Function LE16(Off:Integer):Word;
Begin
 LE16:=Word(Sec[Off])or(Word(Sec[Off+1])shl 8);
End;

Function LE32(Off:Integer):LongInt;
Begin
 LE32:=LongInt(Sec[Off])+
       LongInt(Sec[Off+1])*256+
       LongInt(Sec[Off+2])*65536+
       LongInt(Sec[Off+3])*16777216;
End;

Procedure PutLE16(Off:Integer;V:Word);
Begin
 Sec[Off]:=Byte(V and $FF);
 Sec[Off+1]:=Byte((V shr 8)and $FF);
End;

Procedure PutLE32(Off:Integer;V:LongInt);
Begin
 Sec[Off]:=Byte(V and $FF);
 Sec[Off+1]:=Byte((V shr 8)and $FF);
 Sec[Off+2]:=Byte((V shr 16)and $FF);
 Sec[Off+3]:=Byte((V shr 24)and $FF);
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

Procedure WriteSector(LBA:LongInt);
Var
 W:Word;
Begin
 Seek(Img,LBA*SectorSize);
 BlockWrite(Img,Sec,SectorSize,W);
 If W<>SectorSize Then Begin
  WriteLn('Ecriture secteur impossible: ',LBA);
  Halt(1);
 End;
End;

Function LooksLikeBPB:Boolean;
Var
 BPS:Word;
 SPC:Byte;
Begin
 BPBOffset:=0;
 BPS:=LE16(11);
 SPC:=Sec[13];
 LooksLikeBPB:=(BPS=512)and(SPC<>0)and(Sec[16]<>0)and
  (LE16(14)<>0)and((LE16(17)<>0)or((LE16(22)=0)and(LE32(36)<>0)));
 If LooksLikeBPB Then Exit;
 BPS:=Word(Sec[12])or(Word(Sec[13])shl 8);
 SPC:=Sec[14];
 LooksLikeBPB:=(BPS=512)and(SPC<>0)and(Sec[17]<>0)and
  ((Word(Sec[15])or(Word(Sec[16])shl 8))<>0);
 If LooksLikeBPB Then BPBOffset:=1;
End;

Function IsFATPartitionType(T:Byte):Boolean;
Begin
 IsFATPartitionType:=T in[$01,$04,$06,$0B,$0C,$0E,$11,$14,$16,$1B,$1C,$1E];
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
 If(Sec[510]<>$55)or(Sec[511]<>$AA)Then Begin
  FindPartitionStart:=-1;
  Exit;
 End;
 For I:=0 to 3 do Begin
  O:=446+I*16;
  T:=Sec[O+4];
  LBA:=LE32(O+8);
  SZ:=LE32(O+12);
  If IsFATPartitionType(T)and(LBA>0)and(SZ>0)Then Begin
   FindPartitionStart:=LBA;
   Exit;
  End;
 End;
 WriteLn('Aucune partition FAT primaire trouvee.');
 Halt(1);
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
 WriteLn('FAT12 sans BPB standard, format deduit par taille.');
 InferFloppyBySize:=True;
End;

Procedure ReadBoot;
Var
 TS16:Word;
 TS32:LongInt;
 SPF16:Word;
Begin
 PartitionStart:=FindPartitionStart;
 If PartitionStart<0Then Begin
  If InferFloppyBySize Then Exit;
  WriteLn('Image PC invalide: ni FAT direct ni MBR.');
  Halt(1);
 End;
 ReadSector(PartitionStart);
 If Not LooksLikeBPB Then Begin
  WriteLn('Secteur de demarrage FAT invalide.');
  Halt(1);
 End;
 BytesPerSector:=Word(Sec[11+BPBOffset])or(Word(Sec[12+BPBOffset])shl 8);
 If BytesPerSector<>SectorSize Then Begin
  WriteLn('Seuls les secteurs de 512 octets sont supportes.');
  Halt(1);
 End;
 SectorsPerCluster:=Sec[13+BPBOffset];
 ReservedSectors:=Word(Sec[14+BPBOffset])or(Word(Sec[15+BPBOffset])shl 8);
 NumFATs:=Sec[16+BPBOffset];
 RootEntries:=Word(Sec[17+BPBOffset])or(Word(Sec[18+BPBOffset])shl 8);
 TS16:=Word(Sec[19+BPBOffset])or(Word(Sec[20+BPBOffset])shl 8);
 TS32:=LongInt(Sec[32+BPBOffset])+
       LongInt(Sec[33+BPBOffset])*256+
       LongInt(Sec[34+BPBOffset])*65536+
       LongInt(Sec[35+BPBOffset])*16777216;
 If TS16<>0Then TotalSectors:=TS16 Else TotalSectors:=TS32;
 SPF16:=Word(Sec[22+BPBOffset])or(Word(Sec[23+BPBOffset])shl 8);
 If SPF16<>0Then SectorsPerFAT:=SPF16
             Else SectorsPerFAT:=LongInt(Sec[36+BPBOffset])+
                LongInt(Sec[37+BPBOffset])*256+
                LongInt(Sec[38+BPBOffset])*65536+
                LongInt(Sec[39+BPBOffset])*16777216;
 If SectorsPerFAT=0Then Begin
  WriteLn('Taille FAT invalide.');
  Halt(1);
 End;
 If RootEntries=0Then RootCluster:=LongInt(Sec[44+BPBOffset])+
       LongInt(Sec[45+BPBOffset])*256+
       LongInt(Sec[46+BPBOffset])*65536+
       LongInt(Sec[47+BPBOffset])*16777216
 Else RootCluster:=0;
 RootDirSectors:=(LongInt(RootEntries)*32+SectorSize-1)div SectorSize;
 FATStart:=PartitionStart+ReservedSectors;
 RootStart:=FATStart+LongInt(NumFATs)*SectorsPerFAT;
 DataStart:=RootStart+RootDirSectors;
 ClusterCount:=(TotalSectors-(ReservedSectors+
  LongInt(NumFATs)*SectorsPerFAT+RootDirSectors))div SectorsPerCluster;
 If ClusterCount<4085Then FATType:=12
  Else If ClusterCount<65525Then FATType:=16
  Else FATType:=32;
 If(FATType=32)and(RootCluster<2)Then RootCluster:=2;
 WriteLn('FAT',FATType,'  cluster=',SectorsPerCluster,
  '  debut partition=',PartitionStart);
End;

Function FATByte(Offset:LongInt):Byte;
Var
 R:Word;
 B:Byte;
Begin
 Seek(Img,(FATStart*SectorSize)+Offset);
 BlockRead(Img,B,1,R);
 If R<>1Then Begin
  WriteLn('Lecture FAT impossible.');
  Halt(1);
 End;
 FATByte:=B;
End;

Procedure SetFATByte(Offset:LongInt;B:Byte);
Var
 F:Integer;
 W:Word;
 Pos:LongInt;
Begin
 For F:=0 to NumFATs-1 do Begin
  Pos:=((FATStart+LongInt(F)*SectorsPerFAT)*SectorSize)+Offset;
  Seek(Img,Pos);
  BlockWrite(Img,B,1,W);
  If W<>1Then Begin
   WriteLn('Ecriture FAT impossible.');
   Halt(1);
  End;
 End;
End;

Function NextCluster(Cl:LongInt):LongInt;
Var
 O,V:LongInt;
Begin
 If FATType=12Then Begin
  O:=Cl+(Cl div 2);
  V:=LongInt(FATByte(O))or(LongInt(FATByte(O+1))shl 8);
  If(Cl and 1)<>0Then V:=V shr 4 Else V:=V and $0FFF;
  NextCluster:=V;
 End
  Else If FATType=16Then Begin
  O:=Cl*2;
  NextCluster:=LongInt(FATByte(O))or(LongInt(FATByte(O+1))shl 8);
 End
  Else Begin
  O:=Cl*4;
  V:=LongInt(FATByte(O))or(LongInt(FATByte(O+1))shl 8)or
    (LongInt(FATByte(O+2))shl 16)or(LongInt(FATByte(O+3))shl 24);
  NextCluster:=V and $0FFFFFFF;
 End;
End;

Function IsEOC(Cl:LongInt):Boolean;
Begin
 If FATType=12Then IsEOC:=Cl>=$0FF8
  Else If FATType=16Then IsEOC:=Cl>=$FFF8
  Else IsEOC:=Cl>=$0FFFFFF8;
End;

Procedure SetClusterValue(Cl,Val:LongInt);
Var
 O,V:LongInt;
Begin
 If FATType=12Then Begin
  O:=Cl+(Cl div 2);
  V:=LongInt(FATByte(O))or(LongInt(FATByte(O+1))shl 8);
  If(Cl and 1)<>0Then V:=(V and $000F)or((Val and $0FFF)shl 4)
                 Else V:=(V and $F000)or(Val and $0FFF);
  SetFATByte(O,Byte(V and $FF));
  SetFATByte(O+1,Byte((V shr 8)and $FF));
 End
  Else If FATType=16Then Begin
  O:=Cl*2;
  SetFATByte(O,Byte(Val and $FF));
  SetFATByte(O+1,Byte((Val shr 8)and $FF));
 End
  Else Begin
  O:=Cl*4;
  Val:=Val and $0FFFFFFF;
  SetFATByte(O,Byte(Val and $FF));
  SetFATByte(O+1,Byte((Val shr 8)and $FF));
  SetFATByte(O+2,Byte((Val shr 16)and $FF));
  SetFATByte(O+3,Byte((Val shr 24)and $0F));
 End;
End;

Function EOCValue:LongInt;
Begin
 If FATType=12Then EOCValue:=$0FFF
  Else If FATType=16Then EOCValue:=$FFFF
  Else EOCValue:=$0FFFFFFF;
End;

Function ClusterSector(Cl:LongInt):LongInt;
Begin
 ClusterSector:=DataStart+(Cl-2)*SectorsPerCluster;
End;

Function FindFreeCluster(Start:LongInt):LongInt;
Var
 C:LongInt;
Begin
 For C:=Start to ClusterCount+1 do
  If NextCluster(C)=0Then Begin
   FindFreeCluster:=C;
   Exit;
  End;
 FindFreeCluster:=0;
End;

Procedure ClearCluster(Cl:LongInt);
Var
 I:Integer;
Begin
 FillChar(Sec,SizeOf(Sec),0);
 For I:=0 to SectorsPerCluster-1 do WriteSector(ClusterSector(Cl)+I);
End;

Procedure CopyCluster(FromCl,ToCl:LongInt);
Var
 I:Integer;
Begin
 For I:=0 to SectorsPerCluster-1 do Begin
  ReadSector(ClusterSector(FromCl)+I);
  WriteSector(ClusterSector(ToCl)+I);
 End;
End;

Function EntryFirstCluster(Off:Integer):LongInt;
Var
 Cl:LongInt;
Begin
 Cl:=LongInt(LE16(Off+26));
 If FATType=32Then
  Cl:=Cl+LongInt(LE16(Off+20))*65536;
 EntryFirstCluster:=Cl;
End;

Procedure PutEntryFirstCluster(Off:Integer;Cl:LongInt);
Begin
 If FATType=32Then PutLE16(Off+20,Word((Cl shr 16)and $FFFF))
               Else PutLE16(Off+20,0);
 PutLE16(Off+26,Word(Cl and $FFFF));
End;

Function FindPredCluster(Target:LongInt):LongInt;
Var
 C:LongInt;
Begin
 For C:=2 to ClusterCount+1 do
  If NextCluster(C)=Target Then Begin
   FindPredCluster:=C;
   Exit;
  End;
 FindPredCluster:=0;
End;

Function UpdateDirChainReference(StartCl,Target,NewCl:LongInt):Boolean;Forward;

Function UpdateDirSectorReference(LBA,Target,NewCl:LongInt):Boolean;
Var
 I,O:Integer;
 A:Byte;
 FC:LongInt;
Begin
 UpdateDirSectorReference:=False;
 ReadSector(LBA);
 For I:=0 to 15 do Begin
  O:=I*32;
  If Sec[O]=0Then Continue;
  If Sec[O]=$E5Then Continue;
  A:=Sec[O+11];
  If(A and $0F)=$0FThen Continue;
  FC:=EntryFirstCluster(O);
  If FC=Target Then Begin
   PutEntryFirstCluster(O,NewCl);
   WriteSector(LBA);
   UpdateDirSectorReference:=True;
   Exit;
  End;
  If((A and $10)<>0)and(FC>=2)and(Sec[O]<>Ord('.'))Then Begin
   If UpdateDirChainReference(FC,Target,NewCl)Then Begin
    UpdateDirSectorReference:=True;
    Exit;
   End;
   ReadSector(LBA);
  End;
 End;
End;

Function UpdateDirChainReference(StartCl,Target,NewCl:LongInt):Boolean;
Var
 Cur,S,J:LongInt;
Begin
 UpdateDirChainReference:=False;
 Cur:=StartCl;
 While(Cur>=2)and(Not IsEOC(Cur))do Begin
  S:=ClusterSector(Cur);
  For J:=0 to SectorsPerCluster-1 do
   If UpdateDirSectorReference(S+J,Target,NewCl)Then Begin
    UpdateDirChainReference:=True;
    Exit;
   End;
  Cur:=NextCluster(Cur);
 End;
End;

Function UpdateDirReference(Target,NewCl:LongInt):Boolean;
Var
 S:LongInt;
Begin
 UpdateDirReference:=False;
 If FATType=32Then Begin
  UpdateDirReference:=UpdateDirChainReference(RootCluster,Target,NewCl);
  Exit;
 End;
 For S:=0 to RootDirSectors-1 do
  If UpdateDirSectorReference(RootStart+S,Target,NewCl)Then Begin
   UpdateDirReference:=True;
   Exit;
  End;
End;

Procedure RelocateCluster(Target,ReserveEnd:LongInt);
Var
 NewCl,Pred,Val:LongInt;
Begin
 Val:=NextCluster(Target);
 If Val=0 Then Exit;
 NewCl:=FindFreeCluster(ReserveEnd+1);
 If NewCl=0 Then Begin
  WriteLn('Espace insuffisant pour deplacer le cluster ',Target,'.');
  Halt(1);
 End;
 CopyCluster(Target,NewCl);
 SetClusterValue(NewCl,Val);
 Pred:=FindPredCluster(Target);
 If Pred<>0 Then SetClusterValue(Pred,NewCl)
 Else If Not UpdateDirReference(Target,NewCl)Then Begin
  SetClusterValue(NewCl,0);
  SetClusterValue(Target,0);
  WriteLn('Cluster ',Target,' alloue sans entree de repertoire, reutilise.');
  Exit;
 End;
 SetClusterValue(Target,0);
End;

Procedure ReserveSystemClusters(Need:LongInt);
Var
 C,ReserveEnd:LongInt;
Begin
 If Need<=0 Then Exit;
 If FATType=32 Then Begin
  WriteLn('/SYS est supporte seulement sur FAT12/FAT16.');
  Halt(1);
 End;
 If Need>ClusterCount Then Begin
  WriteLn('Fichier systeme trop grand pour cette image.');
  Halt(1);
 End;
 ReserveEnd:=Need+1;
 For C:=2 to ReserveEnd do RelocateCluster(C,ReserveEnd);
End;

Function ValidDOSChar(C:Char):Boolean;
Begin
 ValidDOSChar:=C in['A'..'Z','0'..'9','$','%','''','-','_','@','~','`','!','(',')','{','}','^','#','&'];
End;

Procedure Make83(Source:String;Var Raw:Array of Byte);
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
 S:String;
 I,J:Integer;
 C:Char;
Begin
 FSplit(Source,D,N,E);
 N:=UpStr(N);
 E:=UpStr(E);
 If(Length(E)>0)and(E[1]='.')Then Delete(E,1,1);
 For I:=0 to 10 do Raw[I]:=32;
 J:=0;
 For I:=1 to Length(N)do Begin
  C:=N[I];
  If ValidDOSChar(C)Then Begin
   If J<8Then Begin Raw[J]:=Ord(C); Inc(J); End;
  End;
 End;
 J:=8;
 For I:=1 to Length(E)do Begin
  C:=E[I];
  If ValidDOSChar(C)Then Begin
   If J<11Then Begin Raw[J]:=Ord(C); Inc(J); End;
  End;
 End;
 If Raw[0]=32Then Begin
  S:='FILE';
  For I:=1 to Length(S)do Raw[I-1]:=Ord(S[I]);
 End;
End;

Function NameMatches(Off:Integer;Var Raw:Array of Byte):Boolean;
Var
 I:Integer;
Begin
 NameMatches:=True;
 For I:=0 to 10 do If Sec[Off+I]<>Raw[I]Then Begin
  NameMatches:=False;
  Exit;
 End;
End;

Function FindRootEntry(Var Raw:Array of Byte;Var EntrySector:LongInt;Var EntryOff:Integer):Boolean;
Var
 S,J:LongInt;
 Cur:LongInt;
 I:Integer;
Begin
 FindRootEntry:=False;
 If FATType=32Then Begin
  Cur:=RootCluster;
  While(Cur>=2)and(Not IsEOC(Cur))do Begin
   S:=ClusterSector(Cur);
   For J:=0 to SectorsPerCluster-1 do Begin
    ReadSector(S+J);
    For I:=0 to 15 do Begin
     If NameMatches(I*32,Raw)Then Begin
      WriteLn('Le fichier existe deja dans l''image.');
      Halt(1);
     End;
     If(Sec[I*32]=0)or(Sec[I*32]=$E5)Then Begin
      EntrySector:=S+J;
      EntryOff:=I*32;
      FindRootEntry:=True;
      Exit;
     End;
    End;
   End;
   Cur:=NextCluster(Cur);
  End;
 End
  Else Begin
  For S:=0 to RootDirSectors-1 do Begin
   ReadSector(RootStart+S);
   For I:=0 to 15 do Begin
    If NameMatches(I*32,Raw)Then Begin
     WriteLn('Le fichier existe deja dans l''image.');
     Halt(1);
    End;
    If(Sec[I*32]=0)or(Sec[I*32]=$E5)Then Begin
     EntrySector:=RootStart+S;
     EntryOff:=I*32;
     FindRootEntry:=True;
     Exit;
    End;
   End;
  End;
 End;
End;

Procedure WriteDirectoryEntry(EntrySector:LongInt;EntryOff:Integer;
 Var Raw:Array of Byte;FirstCluster:LongInt;Size:LongInt;Stamp:LongInt;
 Attr:Byte);
Var
 I:Integer;
 T,D:Word;
Begin
 ReadSector(EntrySector);
 For I:=0 to 31 do Sec[EntryOff+I]:=0;
 For I:=0 to 10 do Sec[EntryOff+I]:=Raw[I];
 Sec[EntryOff+11]:=Attr;
 T:=Word(Stamp and $FFFF);
 D:=Word((Stamp shr 16)and $FFFF);
 PutLE16(EntryOff+14,T);
 PutLE16(EntryOff+16,D);
 PutLE16(EntryOff+22,T);
 PutLE16(EntryOff+24,D);
 If FATType=32Then PutLE16(EntryOff+20,Word((FirstCluster shr 16)and $FFFF));
 PutLE16(EntryOff+26,Word(FirstCluster and $FFFF));
 PutLE32(EntryOff+28,Size);
 WriteSector(EntrySector);
End;

Procedure CopyFileToImage(SourceName:String;SysMode:Boolean);
Var
 Src:File;
 Raw:Array[0..10]of Byte;
 EntrySector:LongInt;
 EntryOff:Integer;
 Size,Remain,Need,ClusterBytes:LongInt;
 Cl,FirstCl,PrevCl,NextFree:LongInt;
 I:Integer;
 R:Word;
 Stamp:LongInt;
Begin
 Make83(BaseName(SourceName),Raw);
 If Not FindRootEntry(Raw,EntrySector,EntryOff)Then Begin
  WriteLn('Repertoire racine plein.');
  Halt(1);
 End;
 Assign(Src,SourceName);
 FileMode:=0;
 {$I-}Reset(Src,1);{$I+}
 If IoResult<>0Then Begin
  WriteLn('Impossible d''ouvrir ',SourceName);
  Halt(1);
 End;
 Size:=FileSize(Src);
 GetFTime(Src,Stamp);
 ClusterBytes:=LongInt(SectorsPerCluster)*SectorSize;
 Remain:=Size;
 FirstCl:=0;
 PrevCl:=0;
 If SysMode Then Begin
  Need:=(Size+ClusterBytes-1)div ClusterBytes;
  ReserveSystemClusters(Need);
  Cl:=2;
  While Remain>0 do Begin
   If FirstCl=0 Then FirstCl:=Cl;
   If Remain>ClusterBytes Then SetClusterValue(Cl,Cl+1)
    Else SetClusterValue(Cl,EOCValue);
   For I:=0 to SectorsPerCluster-1 do Begin
    FillChar(Sec,SizeOf(Sec),0);
    If Remain>0 Then Begin
     BlockRead(Src,Sec,SectorSize,R);
     Dec(Remain,R);
    End;
    WriteSector(ClusterSector(Cl)+I);
   End;
   Inc(Cl);
  End;
  If Size=0 Then FirstCl:=0;
  Close(Src);
  WriteDirectoryEntry(EntrySector,EntryOff,Raw,FirstCl,Size,Stamp,$27);
  WriteLn(SourceName,' -> image (/SYS)');
  Exit;
 End;
 NextFree:=2;
 While Remain>0 do Begin
  Cl:=FindFreeCluster(NextFree);
  If Cl=0Then Begin
   Close(Src);
   WriteLn('Espace insuffisant dans l''image.');
   Halt(1);
  End;
  NextFree:=Cl+1;
  If FirstCl=0Then FirstCl:=Cl;
  If PrevCl<>0Then SetClusterValue(PrevCl,Cl);
  SetClusterValue(Cl,EOCValue);
  For I:=0 to SectorsPerCluster-1 do Begin
   FillChar(Sec,SizeOf(Sec),0);
   If Remain>0Then Begin
    BlockRead(Src,Sec,SectorSize,R);
    Dec(Remain,R);
   End;
   WriteSector(ClusterSector(Cl)+I);
  End;
  PrevCl:=Cl;
 End;
 Close(Src);
 If Size=0Then FirstCl:=0;
 WriteDirectoryEntry(EntrySector,EntryOff,Raw,FirstCl,Size,Stamp,$20);
 WriteLn(SourceName,' -> image');
End;

Procedure Help;Begin
 WriteLn('DISKPC : Cette commande permet de copier des fichiers ',
         'dans une image disque PC FAT.');
 WriteLn;
 WriteLn('Syntaxe : DISKPC image.img fichier1 [fichier2 ...] [/SYS:fichier]');
 WriteLn;
 WriteLn('Ajoute les fichiers dans la racine de la premiere partition FAT.');
 WriteLn('/SYS:fichier place un fichier systeme au debut de la zone donnees');
 WriteLn('FAT12/FAT16 et deplace les clusters occupes si necessaire.');
 WriteLn('Supporte FAT12, FAT16 et FAT32. Noms longs VFAT non crees.');
End;

Function IsSysParam(S:String):Boolean;
Var
 U:String;
Begin
 U:=UpStr(S);
 IsSysParam:=(Copy(U,1,5)='/SYS:')or(Copy(U,1,5)='-SYS:');
End;

Var
 I:Integer;
 P:String;
 SysSeen:Boolean;
Begin
 If(ParamCount<2)or(ParamStr(1)='/?')or(ParamStr(1)='-h')or
   (ParamStr(1)='--help')Then Begin
  Help;
  Halt;
 End;
 ImgName:=ParamStr(1);
 Assign(Img,ImgName);
 {$I-}Reset(Img,1);{$I+}
 If IoResult<>0Then Begin
  WriteLn('Impossible d''ouvrir ',ImgName);
  Halt(1);
 End;
 ReadBoot;
 SysSeen:=False;
 For I:=2 to ParamCount do Begin
  P:=ParamStr(I);
  If IsSysParam(P)Then Begin
   If SysSeen Then Begin
    WriteLn('Un seul parametre /SYS:fichier est supporte.');
    Halt(1);
   End;
   SysSeen:=True;
   CopyFileToImage(Copy(P,6,Length(P)-5),True);
  End
   Else CopyFileToImage(P,False);
 End;
 Close(Img);
End.
