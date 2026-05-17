{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program H8D;

{$A-}

Uses DOS,Strings;

Const
 SECSIZE=256;
 MAXD=200;
 ESIZE=23;
 DIFSYS=$80;
 DIFLOC=$40;
 DIFWP=$20;
 DIFCNT=$10;
 INBUF=32;

Type
 DiskInfo=Record
  Volser:Char;
  IDate:Word;
  DirSector:Word;
  GrtSector:Word;
  Spg:Byte;
  VolType:Char;
  InitVer:Char;
  RgtSector:Word;
  VolSize:Word;
  SectSize:Word;
  DkFlags:Char;
  _label:Array[0..59]of Char;
  Reserved:Word;
  Spt:Char;
  Unused:Array[0..175]of Char;
 End;

 FileInfoPtr=^FileInfo;
 FileInfo=Record
  Name:Array[0..7]of Char;
  Ext:Array[0..2]of Char;
  Prj:Byte;
  Ver:Byte;
  Clf:Byte;
  Flags:Byte;
  Rsvd:Byte;
  Fgn:Byte;
  Lgn:Byte;
  Lsi:Byte;
  CreDate:Word;
  ModDate:Word;
  Size:Word;
  DName:Array[0..12]of Char;
 End;

Var
 DkBuff:DiskInfo;
 FEntry:FileInfo;
 Direntries:Array[0..MAXD-1] of FileInfoPtr;
 Rwbuff:Array[0..511] of Char;
 Grtbuff:Array[0..SECSIZE-1] of Char;
 Strbuf:Array[0..INBUF + 5] of Char;
 Channel:File;
 NEntries:Integer;
 Chan:File;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

Function IsPrnt(Ch:Char):Boolean;Begin
 IsPrnt:=(Ord(ch)>=32)and(Ord(ch)<=126);
End;

Function StrToIntDef(X:String;Dc:Integer):Integer;
Var
 Value:Integer;
 Err:Word;
Begin
 Val(X,Value,Err);
 StrToIntDef:=Value;
End;

Function FileExists(Name:String):Boolean;
Var
 Rec:SearchRec;
Begin
 FindFirst(Name,AnyFile,Rec);
 FileExists:=DosError=0;
End;

Procedure ReadSectors(Var Buff;I,N:Integer);
Var
 Err:Integer;
 FSize:LongInt;
Begin
 FSize:=FileSize(Channel);
 If (LongInt(I)*SECSIZE+LongInt(N)*SECSIZE)>FSize Then Begin
  WriteLn('Erreur - lecture hors limites (secteur ',I,', ',N,' secteur(s), taille=',FSize,')');
  Halt(1);
 End;
 {$I-}
 Seek(Channel,LongInt(I)*SECSIZE);
 {$I+}
 If IOResult<>0 Then Begin
  WriteLn('Erreur de positionnement');
  Halt(1);
 End;
 {$I-}
 BlockRead(Channel,Buff,N*SECSIZE);
 {$I+}
 Err:=IOResult;
 If Err<>0 Then Begin
  WriteLn('Erreur de lecture (code ',Err,') au secteur ',I);
  Halt(1);
 End;
End;

Procedure WriteSectors(Var Buff;I,N:Integer);
Begin
 {$I-}
 Seek(Channel,LongInt(I)*SECSIZE);
 {$I+}
 If IOResult<>0 Then Begin
  WriteLn('Erreur de positionnement ('+#144+'criture secteur ',I,')');
  Halt(1);
 End;
 {$I-}
 BlockWrite(Channel,Buff,N*SECSIZE);
 {$I+}
 If IOResult<>0 Then Begin
  WriteLn('Erreur d'''+#130+'criture (secteur ',I,')');
  Halt(1);
 End;
End;

Procedure ReadBoot(Const Fname:String);
Var
 Err,Count,I:Integer;
 IFile,Ext,Choice:Integer;
 Done:Boolean;
Begin
 If FileExists(FName)Then Begin
  Write('Fichier de destination ', fname, ' existes. '+#144+'craser? O/N ');
  strbuf[0] := Chr(INBUF);
  ReadLn(StrBuf);
  If UpCase(strbuf[2])='N'Then Exit;
 End;
 {$I-}Assign(Chan,FName);
 Rewrite(Chan,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Erreur d''ouverture du fichier de destination ',FName);
  Exit;
 End
  Else
 WriteLn('Extraction des pistes de d'+#130+'marrage du fichier ',FName);
 Seek(Channel,0);
 If Err<>0 Then Begin
  WriteLn('Erreur de lecture du secteur de l''image disque ', I);
  Halt(1);
 End;
 For I:=0 to 9 do Begin
  BlockRead(Channel,rwbuff,SECSIZE,Count);
  BlockWrite(Chan,rwbuff,SECSIZE);
  If Count<>SECSIZE Then Begin
   WriteLn('Erreur d'''+#130+'criture dans le fichier ',FName);
   Close(chan);
   Exit;
  End;
  Write('.');
 End;
 Close(chan);
 WriteLn('Fichier compl'+#130+'t'+#130);
End;

Function HInfo:Integer;
Var
 I,RC:Integer;
 S,D:PChar;
Begin
 RC:=0;
 ReadSectors(rwbuff,0,1);
 If((rwbuff[0]=#$C3)and(rwbuff[1]=#$C0)and(rwbuff[2]=#$22)and(rwbuff[3]=#$00))or
   ((rwbuff[0]=#$C3)and(rwbuff[1]=#$A0)and(rwbuff[2]=#$22)and(rwbuff[3]=#$20))or
   ((rwbuff[0]=#$AF)and(rwbuff[1]=#$D3)and(rwbuff[2]=#$7D)and(rwbuff[3]=#$CD))Then Begin
  ReadSectors(rwbuff,9,1);
  S:=@rwbuff[0];
  D:=PChar(@dkbuff);
  Move(S^, D^, SECSIZE);
 End
  Else
 RC:=1;
 HInfo:=RC;
End;

Procedure BuildDir;
Var
 cc:LongInt;
 i,j,block,nxtsector:Integer;
 Done:Boolean;
 clu:Word;
 Entry:FileInfoPtr;
 Src,Dst,SDir,DDir:PChar;
 inxt:^Integer;
 GrtSafety:Integer;
Begin
 NxtSector:=dkbuff.DirSector;
 Done:=False;
 NEntries:=0;
 Block:=0;
 WriteLn('Construction du r'+#130+'pertoire...');
 If (NxtSector<=0) Or (LongInt(NxtSector+2)*SECSIZE>FileSize(Channel)) Then Begin
  WriteLn('Erreur - DirSector invalide (',NxtSector,') : ce volume n''est pas un H8D HDOS valide.');
  Exit;
 End;
 Repeat
  ReadSectors(rwbuff,Nxtsector,2);
  Inc(block);
  Src:=RwBuff;
  For I:=0 to 21 do Begin
   If(Done)Then Break;
   If IsPrnt(src^)Then Begin
    If NEntries=MAXD Then Begin
     WriteLn('Erreur - R'+#130+'pertoire plein !');
     Done:=True;
    End
     Else
    Begin
     GetMem(Entry,SizeOf(FileInfo));
     If Entry=NIL Then Begin
      WriteLn('Erreur d''allocation d''entr'+#130+'e de r'+#130+'pertoire !');
      Done:=True;
     End
      Else
     Begin
      Dst:=PChar(Entry);
      Move(Src^, Dst^, ESIZE);
      DirEntries[nentries]:=Entry;
      Clu:=DirEntries[NEntries]^.Fgn and $FF;
      CC:=0;
      GrtSafety:=0;
      Repeat
       Inc(cc);
       Clu:=Byte(grtbuff[clu]) and $FF;
       Inc(GrtSafety);
      Until (Clu=0) Or (GrtSafety>300);
      DirEntries[NEntries]^.Size:=(CC-1)*dkbuff.spg+DirEntries[NEntries]^.lsi;
      SDir:=DirEntries[NEntries]^.Name;
      DDir:=DirEntries[NEntries]^.DName;
      For J:=0 to 7 do Begin
       If (SDir^<>#0) And (SDir^<>' ') Then Begin
        DDir^:=SDir^;
        Inc(DDir);
       End;
       Inc(SDir);
      End;
      SDir:=DirEntries[NEntries]^.Ext;
      If (SDir^<>#0) And (SDir^<>' ') Then Begin
       DDir^:='.';
       Inc(DDir);
       For J:=0 to 2 do Begin
        If (SDir^<>#0) And (SDir^<>' ') Then Begin
         DDir^:=SDir^;
         Inc(DDir);
        End;
        Inc(sdir);
       End;
      End;
      DDir^:=#0;
      Inc(nentries);
     End;
    End;
    Inc(Src,ESIZE);
   End
    Else
   Begin
    Inc(src,ESIZE);
   End;
  End;
  If Not Done Then Begin
   { Le pointeur de prochain bloc repertoire est au offset 510-511 du bloc de 512 octets. }
   NxtSector:=Byte(rwbuff[510]) + Byte(rwbuff[511])*256;
   If NxtSector=0 Then Done:=True
   Else If (NxtSector<0) Or (LongInt(NxtSector+2)*SECSIZE>FileSize(Channel)) Then Begin
    WriteLn('Erreur - prochain secteur r'+#130+'pertoire invalide (',NxtSector,'), arr'+#136+'t de la lecture.');
    Done:=True;
   End;
   If Block>200 Then Begin
    WriteLn('Erreur - cha'+#140+'ne du r'+#130+'pertoire trop longue (cycle?)');
    Done:=True;
   End;
  End;
 Until Done;
 WriteLn('Fait! ', nentries, ' fichiers trouv'+#130+'s');
End;

Function IfThen(Test:Boolean;S,T:String):String;Begin
 If(Test)Then IfThen:=S
         Else IfThen:=T;
End;

Procedure PrDate(d:Integer);
Const
 Month:Array[0..11] of String[5]=('Jan','F�v','Mar','Avr','Mai','Jui',
                                 'Jul','Ao�','Sep','Oct','Nov','D�c');
Var
 Day,Mo,Yr:Integer;
Begin
 If d = 0 Then Write(' Pas-de-date ')
  Else
 Begin
  Day:=d and $1F;
  Mo:=(d div 32) and $0F;
  Yr:=1970+((d div 512) and $3F);
  Write(day:2,month[mo],yr-1900:4);
 End;
End;

Procedure ListDir;
Var
 i,j,Entries,SizTot:Integer;
 c:PChar;
Begin
 Entries:=0;
 SizTot:=0;
 For i:=0 to nentries-1 do Begin
  c:=DirEntries[i]^.Name;
  If IsPrnt(c^)Then Begin
   Inc(entries);
   For j:=1 to 8 do Begin
    If c^=#0 Then Write(' ')
             Else Write(c^);
    Inc(c);
   End;
   Write('.');
   c:=DirEntries[i]^.ext;
   For j:=1 to 3 do Begin
    If c^=#0 Then Write(' ')
             Else Write(c^);
    Inc(c);
   End;
   Write('  ',IfThen((direntries[i]^.flags and DIFSYS)<>0,'S', ' '),
              IfThen((direntries[i]^.flags and DIFLOC)<>0,'L', ' '),
              IfThen((direntries[i]^.flags and DIFWP)<>0,'W', ' '),
              IfThen((direntries[i]^.flags and DIFCNT)<>0,'C', ' '));
   SizTot:=SizTot+Direntries[i]^.Size;
   Write(' ',DirEntries[i]^.size:4);
   PrDate(direntries[i]^.moddate);
   Write('  ',DirEntries[i]^.DName);
   WriteLn;
  End;
 End;
 WriteLn('Fichiers ', entries, ', Total ', siztot);
End;

Function GetBaseName(P:String):String;
Var I:Integer;
Begin
 I:=Length(P);
 While (I>0) And (P[I]<>'\') And (P[I]<>'/') And (P[I]<>':') Do Dec(I);
 GetBaseName:=Copy(P,I+1,Length(P)-I);
End;

Procedure SplitName(FN:String;Var NamePart,ExtPart:String);
Var I:Integer;
Begin
 I:=Length(FN);
 While (I>0) And (FN[I]<>'.') Do Dec(I);
 If I=0 Then Begin
  NamePart:=FN;
  ExtPart:='';
 End Else Begin
  NamePart:=Copy(FN,1,I-1);
  ExtPart:=Copy(FN,I+1,Length(FN)-I);
 End;
End;

Function Match(FName:PChar):Integer;
Var
 i:Integer;
 IsMatch:Boolean;
Begin
 Match:=-1;
 WriteLn('Recherche pour une correspondant avec : ',FName);
 i:=0;
 IsMatch:=False;
 While(i<NEntries)and(Not IsMatch)do Begin
  If StrComp(FName,DirEntries[i]^.DName)=0 Then Begin
   IsMatch:=True;
   Match:=i;
  End;
  Inc(i);
 End;
End;

Function HasWildcard(S:String):Boolean;
Var I:Integer; R:Boolean;
Begin
 R:=False;
 For I:=1 To Length(S) Do
  If (S[I]='*') Or (S[I]='?') Then R:=True;
 HasWildcard:=R;
End;

Function WildMatchSeg(Pat,S:String):Boolean;
Var IP,JS,LP,LS:Integer; R,Done:Boolean;
Begin
 LP:=Length(Pat); LS:=Length(S);
 IP:=1; JS:=1;
 R:=False; Done:=False;
 While (Not Done) And (IP<=LP) Do Begin
  If Pat[IP]='*' Then Begin
   If IP=LP Then Begin R:=True; Done:=True; End
   Else Begin
    While (Not Done) And (JS<=LS) Do Begin
     If WildMatchSeg(Copy(Pat,IP+1,LP-IP),Copy(S,JS,LS-JS+1)) Then Begin
      R:=True; Done:=True;
     End;
     Inc(JS);
    End;
    If Not Done Then Begin
     R:=WildMatchSeg(Copy(Pat,IP+1,LP-IP),'');
     Done:=True;
    End;
   End;
  End Else If Pat[IP]='?' Then Begin
   If JS>LS Then Begin R:=False; Done:=True; End
   Else Begin Inc(IP); Inc(JS); End;
  End Else Begin
   If (JS>LS) Or (UpCase(Pat[IP])<>UpCase(S[JS])) Then Begin
    R:=False; Done:=True;
   End Else Begin Inc(IP); Inc(JS); End;
  End;
 End;
 If Not Done Then R:=(JS>LS);
 WildMatchSeg:=R;
End;

Function WildMatch(Pat,Name:String):Boolean;
Var PN,PE,NN,NE:String;
Begin
 SplitName(Pat,PN,PE);
 SplitName(Name,NN,NE);
 WildMatch:=WildMatchSeg(PN,NN) And WildMatchSeg(PE,NE);
End;

Procedure HexLine(b:PChar;n:Integer);
Var
 I:Integer;
Begin
 For i:=0 to n-1 do Write(' ',HexWord2Str(Ord(b[i])));
End;

Procedure AsciiLine(b:PChar;n:Integer);
Var
 i:Integer;
Begin
 For i:=0 to n-1 do Begin
  If IsPrnt(b[i])Then Write(b[i])
                 Else Write('.');
 End;
End;

Procedure HexDump(b:PChar;n:Integer);
Var
 i:Integer;
Begin
 WriteLn;
 WriteLn(#9'0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F',
          '  0123456789ABCDEF');
 WriteLn(#9'-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --',
         '  ----------------');
 I:=0;
 While(I<N-1)do Begin
  Write(HexWord2Str(i), ' :');
  HexLine(b + i, 16);
  Write('  ');
  AsciiLine(b + i, 16);
  WriteLn;
  I:=I+16;
 End;
End;

Procedure DumpFile(fname:PChar);
Var
 ifile,i,sc:Integer;
 clu:Byte;
Begin
 IFile:=Match(fname);
 If IFile=-1 Then WriteLn('Fichier ', fname, ' introuvable !')
  else
 Begin
  WriteLn('Sortir le fichier ',DirEntries[IFile]^.DName);
  Clu:=DirEntries[ifile]^.Fgn and $FF;
  Sc:=DirEntries[ifile]^.Size;
  While Sc>0 do Begin
   ReadSectors(rwbuff,Clu*dkbuff.spg,dkbuff.spg);
   For I:=0 to dkbuff.spg-1 do Begin
    HexDump(rwbuff + (i * SECSIZE), SECSIZE);
    Dec(sc);
   End;
   Clu:=Byte(grtbuff[clu]) and $FF;
  End;
 End;
End;

Procedure ExtractOne(IFile:Integer;DestName:String);
Var
 i,sc,count,nsec:Integer;
 chan:File;
 clu:Byte;
Begin
 {$I-}Assign(Chan,DestName);
 Rewrite(Chan,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Erreur d''ouverture du fichier de destination ',DestName);
  Exit;
 End;
 WriteLn('Extraction du fichier ',DirEntries[ifile]^.DName,' -> ',DestName);
 Clu:=DirEntries[IFile]^.Fgn and $FF;
 Sc:=DirEntries[ifile]^.Size;
 nsec:=0;
 While Sc>0 do Begin
  If (LongInt(Clu)*dkbuff.spg+dkbuff.spg)*SECSIZE>FileSize(Channel) Then Begin
   WriteLn;
   WriteLn('Erreur - cluster ',Clu,' hors limites pour ',DirEntries[ifile]^.DName,', extraction interrompue.');
   Break;
  End;
  ReadSectors(rwbuff,LongInt(Clu)*dkbuff.spg,dkbuff.spg);
  For i:=0 to dkbuff.spg - 1 do Begin
   If Sc<=0 Then Break;
   BlockWrite(chan, rwbuff[i*SECSIZE], SECSIZE, count);
   If Count<>SECSIZE Then Begin
    WriteLn('Erreur d'''+#130+'criture dans le fichier ',DestName);
    Sc:=0;
    Break;
   End;
   Inc(nsec);
   Write('.');
   Dec(sc);
  End;
  Clu:=Byte(grtbuff[clu]) and $FF;
  If Clu=0 Then Break;
 End;
 WriteLn;
 WriteLn(nsec,' secteurs '+#130+'crit(s)');
 Close(chan);
End;

Procedure Extract(fname:PChar);
Var
 ifile,nmatch:Integer;
 pat:String;
Begin
 pat:=StrPas(fname);
 If HasWildcard(pat) Then Begin
  WriteLn('Recherche pour une correspondant avec : ',pat);
  nmatch:=0;
  For ifile:=0 To NEntries-1 Do Begin
   If WildMatch(pat,StrPas(DirEntries[ifile]^.DName)) Then Begin
    ExtractOne(ifile,StrPas(DirEntries[ifile]^.DName));
    Inc(nmatch);
   End;
  End;
  If nmatch=0 Then WriteLn('Aucun fichier ne correspond ',#133,' ',pat)
              Else WriteLn(nmatch,' fichier(s) extrait(s)');
 End Else Begin
  IFile:=Match(fname);
  If IFile=-1 Then WriteLn('Fichier ', fname, ' introuvable !')
              Else ExtractOne(IFile,pat);
 End;
End;

Function EncodeHDate:Word;
Var Y,M,D,DOW:Word;
Begin
 GetDate(Y,M,D,DOW);
 If Y<1970 Then Y:=1970;
 EncodeHDate:=(((Y-1970) And $3F) Shl 9) Or ((M And $0F) Shl 5) Or (D And $1F);
End;

Procedure AddFile(LocalName:String);
Var
 Src:File;
 SrcSize:LongInt;
 NeedSec,NeedClu,MaxClu,I,J:Integer;
 Used:Array[0..255] Of Boolean;
 FreeClu:Array[0..255] Of Byte;
 NFree,ClusterIdx:Integer;
 DirBlkSector:Integer;
 DirSlot:Integer;
 Found:Boolean;
 DirBlk:Array[0..511] Of Char;
 RGTBuf:Array[0..SECSIZE-1] Of Char;
 SecBuf:Array[0..SECSIZE-1] Of Char;
 EncDate:Word;
 NxtSector:Integer;
 BareName,NameOnly,ExtOnly:String;
 Clu,SafetyClu:Byte;
 SecsWritten,BytesIn,K,Off:Integer;
 SafetyCnt:Integer;
Begin
 If Not FileExists(LocalName) Then Begin
  WriteLn('Fichier source introuvable : ',LocalName);
  Exit;
 End;
 {$I-}Assign(Src,LocalName);
 Reset(Src,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible d''ouvrir ',LocalName);
  Exit;
 End;
 SrcSize:=FileSize(Src);
 If SrcSize=0 Then Begin
  WriteLn('Fichier source vide - rien '+#133+' ajouter');
  Close(Src);
  Exit;
 End;
 NeedSec:=(SrcSize+SECSIZE-1) Div SECSIZE;
 NeedClu:=(NeedSec+dkbuff.spg-1) Div dkbuff.spg;
 MaxClu:=dkbuff.VolSize Div dkbuff.spg;
 If MaxClu<=0 Then MaxClu:=FileSize(Channel) Div (LongInt(SECSIZE)*dkbuff.spg);
 If MaxClu>256 Then MaxClu:=256;

 { 1. Construction de la liste des clusters utilises }
 FillChar(Used,SizeOf(Used),0);
 Used[0]:=True; { cluster 0 reserve (0 = fin de chaine) }
 { Tout cluster ayant un successeur non nul dans la GRT est utilise (en milieu de chaine). }
 { Aussi : valeur $FF dans GRT = cluster r�serv�/bad. }
 For I:=0 To MaxClu-1 Do Begin
  J:=Byte(grtbuff[I]);
  If J<>0 Then Used[I]:=True;
  If J=$FF Then Used[I]:=True;
 End;
 { Marquer toutes les chaines de fichiers (couvre aussi les derniers clusters) }
 For I:=0 To NEntries-1 Do Begin
  Clu:=DirEntries[I]^.Fgn And $FF;
  SafetyCnt:=0;
  While (Clu<>0) And (SafetyCnt<MaxClu) Do Begin
   Used[Clu]:=True;
   Clu:=Byte(grtbuff[Clu]) And $FF;
   Inc(SafetyCnt);
  End;
 End;
 { Marquer les clusters occupes par les blocs du r�pertoire lui-meme }
 NxtSector:=dkbuff.DirSector;
 SafetyCnt:=0;
 While (NxtSector<>0) And (SafetyCnt<200) Do Begin
  Used[NxtSector Div dkbuff.spg]:=True;
  ReadSectors(DirBlk,NxtSector,2);
  NxtSector:=Byte(DirBlk[510])+Byte(DirBlk[511])*256;
  Inc(SafetyCnt);
 End;
 { Marquer le cluster contenant la GRT }
 Used[dkbuff.GrtSector Div dkbuff.spg]:=True;
 { Clusters r�serv�s (RGT) - seulement si RgtSector>0 et valide }
 If (dkbuff.RgtSector>0) And (dkbuff.RgtSector<dkbuff.VolSize) Then Begin
  Used[dkbuff.RgtSector Div dkbuff.spg]:=True;
  ReadSectors(RGTBuf,dkbuff.rgtsector,1);
  For I:=0 To SECSIZE-1 Do Begin
   J:=Byte(RGTBuf[I]);
   If J=0 Then Break;
   If J<MaxClu Then Used[J]:=True;
  End;
 End;

 { 2. Recherche des clusters libres }
 NFree:=0;
 For I:=1 To MaxClu-1 Do
  If Not Used[I] Then Begin
   FreeClu[NFree]:=I;
   Inc(NFree);
   If NFree>=NeedClu Then Break;
  End;
 If NFree<NeedClu Then Begin
  WriteLn('Espace insuffisant : ',NeedClu,' clusters requis, ',NFree,' libres');
  Close(Src);
  Exit;
 End;

 { 3. Recherche d'un slot libre dans le r�pertoire }
 Found:=False;
 NxtSector:=dkbuff.DirSector;
 DirBlkSector:=0; DirSlot:=0;
 While (NxtSector<>0) And (Not Found) Do Begin
  ReadSectors(DirBlk,NxtSector,2);
  For J:=0 To 21 Do Begin
   If Not IsPrnt(DirBlk[J*ESIZE]) Then Begin
    DirBlkSector:=NxtSector;
    DirSlot:=J;
    Found:=True;
    Break;
   End;
  End;
  If Not Found Then
   NxtSector:=Byte(DirBlk[510])+Byte(DirBlk[511])*256;
 End;
 If Not Found Then Begin
  WriteLn('Aucun slot libre dans le r'+#130+'pertoire');
  Close(Src);
  Exit;
 End;

 { 4. V�rifier que le nom n'existe pas d�j� }
 BareName:=GetBaseName(LocalName);
 For I:=1 To Length(BareName) Do BareName[I]:=UpCase(BareName[I]);
 SplitName(BareName,NameOnly,ExtOnly);
 If Length(NameOnly)>8 Then NameOnly:=Copy(NameOnly,1,8);
 If Length(ExtOnly)>3 Then ExtOnly:=Copy(ExtOnly,1,3);

 { 5. �crire les donn�es sur l'image disque }
 WriteLn('Ajout de ',BareName,' (',SrcSize,' octets, ',
         NeedSec,' secteurs, ',NeedClu,' clusters)');
 SecsWritten:=0; ClusterIdx:=0;
 While SecsWritten<NeedSec Do Begin
  K:=SecsWritten Mod dkbuff.spg;
  If (K=0) And (SecsWritten>0) Then Inc(ClusterIdx);
  Clu:=FreeClu[ClusterIdx];
  FillChar(SecBuf,SECSIZE,0);
  BlockRead(Src,SecBuf,SECSIZE,BytesIn);
  WriteSectors(SecBuf,LongInt(Clu)*dkbuff.spg+K,1);
  Inc(SecsWritten);
  Write('.');
 End;
 WriteLn;
 Close(Src);

 { 6. Chainer les clusters dans la GRT et l'ecrire }
 For I:=0 To NeedClu-2 Do
  grtbuff[FreeClu[I]]:=Chr(FreeClu[I+1]);
 grtbuff[FreeClu[NeedClu-1]]:=#0;
 WriteSectors(grtbuff,dkbuff.grtsector,1);

 { 7. Construire l'entree repertoire (23 octets) et recrire le bloc }
 Off:=DirSlot*ESIZE;
 For I:=0 To 7 Do DirBlk[Off+I]:=' ';
 For I:=1 To Length(NameOnly) Do DirBlk[Off+I-1]:=NameOnly[I];
 For I:=0 To 2 Do DirBlk[Off+8+I]:=' ';
 For I:=1 To Length(ExtOnly) Do DirBlk[Off+8+I-1]:=ExtOnly[I];
 DirBlk[Off+11]:=#0;  { Prj }
 DirBlk[Off+12]:=#0;  { Ver }
 DirBlk[Off+13]:=#0;  { Clf }
 DirBlk[Off+14]:=#0;  { Flags }
 DirBlk[Off+15]:=#0;  { Rsvd }
 DirBlk[Off+16]:=Chr(FreeClu[0]);            { Fgn }
 DirBlk[Off+17]:=Chr(FreeClu[NeedClu-1]);    { Lgn }
 DirBlk[Off+18]:=Chr(NeedSec-(NeedClu-1)*dkbuff.spg); { Lsi }
 EncDate:=EncodeHDate;
 DirBlk[Off+19]:=Chr(Lo(EncDate));           { CreDate lo }
 DirBlk[Off+20]:=Chr(Hi(EncDate));           { CreDate hi }
 DirBlk[Off+21]:=Chr(Lo(EncDate));           { ModDate lo }
 DirBlk[Off+22]:=Chr(Hi(EncDate));           { ModDate hi }
 WriteSectors(DirBlk,DirBlkSector,2);

 WriteLn('Fichier ',NameOnly,'.',ExtOnly,' ajout'+#130+' avec succ'+#138+'s');
End;

Procedure PrintInfo;
Var
 i:Integer;
 c:PChar;
Begin
 WriteLn('Volume             = ', dkbuff.volser);
 Write(#144+'tiquette: ''');
 For i:=0 to 59 do Write(dkbuff._label[i]);
 WriteLn('''');
 Write('INIT date          = ');
 PrDate(dkbuff.idate);
 WriteLn;
 WriteLn('D'+#130+'but du r'+#130+'pertoire= ', dkbuff.dirsector);
 WriteLn('Secteur GRT        = ', dkbuff.grtsector);
 WriteLn('Secteurs/groupe    = ', dkbuff.spg);
 WriteLn('Type de volume     = ', dkbuff.voltype);
 WriteLn('Version INIT       = ', dkbuff.initver);
 WriteLn('Secteur RGT        = ', dkbuff.rgtsector);
 WriteLn('Taille du volume   = ', dkbuff.volsize);
 WriteLn('Taille du secteur  = ', dkbuff.sectsize);
 WriteLn('Drapeaux           = ', dkbuff.dkflags);
 WriteLn('Secteurs/piste     = ', dkbuff.spt);
 WriteLn;
End;

Var
 Done:Boolean;
 SecNo:Integer;
 Mode:Char;
 ImgName,ArgName:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or
   (ParamStr(1)='-h')or(ParamCount=0)Then Begin
  WriteLn('H8D - Cette commande permet de lancer l''utilitaire ',
          'de gestion d''images disque Heath/Zenith H8D (HDOS).');
  WriteLn;
  WriteLn('Syntaxe :');
  WriteLn('  H8D <image.h8d>                    Mode interactif');
  WriteLn('  H8D <image.h8d> /L                 Liste les fichiers du volume');
  WriteLn('  H8D <image.h8d> /X <fichier>       Extrait <fichier> du volume');
  WriteLn('  H8D <image.h8d> /A <fichier-local> Ajoute <fichier-local> au volume');
  Halt;
 End
  Else
 Begin
  ImgName:=ParamStr(1);
  Mode:=' ';
  ArgName:='';
  If ParamCount>=2 Then Begin
   ArgName:=ParamStr(2);
   If (Length(ArgName)>=2) And ((ArgName[1]='/') Or (ArgName[1]='-')) Then
    Mode:=UpCase(ArgName[2]);
   If ParamCount>=3 Then ArgName:=ParamStr(3)
                    Else ArgName:='';
  End;
  {$I-}Assign(Channel,ImgName);
  Reset(Channel,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Incapable d''ouvrir le fichier source ', ImgName);
   Halt;
  End
   Else
  If HInfo<>0 Then WriteLn('Le fichier ', ImgName, ' n''est pas un fichier H8D valide !')
   Else
  Begin
   ReadSectors(GrtBuff,dkbuff.GrtSector,1);
   BuildDir;
   { Mode ligne de commande non-interactif }
   If Mode='L' Then Begin
    ListDir;
    Close(Channel);
    Halt;
   End;
   If Mode='X' Then Begin
    If ArgName='' Then Begin
     WriteLn('Nom de fichier manquant pour /X');
    End Else Begin
     For SecNo:=1 To Length(ArgName) Do ArgName[SecNo]:=UpCase(ArgName[SecNo]);
     ArgName:=ArgName+#0;
     Extract(@ArgName[1]);
    End;
    Close(Channel);
    Halt;
   End;
   If Mode='A' Then Begin
    If ArgName='' Then WriteLn('Nom de fichier manquant pour /A')
     Else AddFile(ArgName);
    Close(Channel);
    Halt;
   End;
   WriteLn('Utilitaire de vidage et d''analyse du secteur H8D');
   Done:=False;
   While Not Done do Begin
    WriteLn('I)nfo  A)ide  F)ichier  r'+#130+'pertoire  G)RT  ',
            'R)GT  S)ecteur  eX)traire  aJ)outer  B)D'+#130+'marrage  Q)uitte');
    Write('>>');
    StrBuf[0]:=Chr(INBUF);
    ReadLn(StrBuf);
    Case UpCase(strbuf[2])of
     'I':PrintInfo;
     'A':Begin
      WriteLn('Commandes :');
      WriteLn;
      WriteLn(#9'Info:               Affiche les informations de touches dans le fichier H8D');
      WriteLn(#9'Aide:               Affiche l''aide');
      WriteLn(#9'Fichier:            Affiche le contenu d''un fichier');
      WriteLn(#9'R'+#130+'pertoire:         Affiche un r'+#130+'pertoire de fichier contenu dans H8D');
      WriteLn(#9'GRT:                Sortir la table de r'+#130+'servation de groupe (GRT)');
      WriteLn(#9'RGT:                Sortir la table de groupe r'+#130+'serv'+#130+' (RGT)');
      WriteLn(#9'Secteur:            Sortir le secteur sp'+#130+'cifi'+#130);
      WriteLn(#9'eXtraire:           Extraire un fichier de HDOS');
      WriteLn(#9'aJouter:            Ajouter un fichier local au volume H8D');
      WriteLn(#9'Piste de d'+#130+'marrage: Extraire les pistes de d�marrage dans un fichier');
      WriteLn(#9'Quitte:             Sortir');
      WriteLn;
     End;
     'P':ListDir;
     'F':Begin
      Write('Fichier '+#133+' afficher? : ');
      ReadLn(strbuf);
      StrUpper(strbuf+2);
      DumpFile(strbuf+2);
     End;
     'X':Begin
      Write('Fichier '+#133+' extraire? : ');
      ReadLn(strbuf);
      strupper(strbuf + 2);
      Extract(strbuf + 2);
     End;
     'J':Begin
      Write('Fichier local '+#133+' ajouter? : ');
      ReadLn(strbuf);
      AddFile(StrPas(strbuf+2));
      { Reconstruire le r�pertoire en m�moire apr�s ajout }
      For SecNo:=0 To NEntries-1 Do
       If DirEntries[SecNo]<>NIL Then FreeMem(DirEntries[SecNo],SizeOf(FileInfo));
      NEntries:=0;
      ReadSectors(GrtBuff,dkbuff.GrtSector,1);
      BuildDir;
     End;
     'S':Begin
      Write('Lequel des secteurs ? : ');
      ReadLn(strbuf);
      SecNo:=StrToIntDef(Copy(strbuf,3,Length(strbuf)-2),0);
      If(SecNo<dkbuff.volsize)Then Begin
       ReadSectors(rwbuff,secno,1);
       HexDump(rwbuff,SECSIZE);
      End
       Else
      WriteLn('Secteur ill'+#130+'gale');
     End;
     'B':Begin
      Write('Extraire les pistes de d'+#130+'marrage avec le nom de fichier ? ');
      ReadLn(strbuf);
      StrUpper(strbuf+2);
      ReadBoot(StrPas(strbuf + 2));
     End;
     'R':Begin
      WriteLn('Sortir le RGT...');
      ReadSectors(rwbuff,dkbuff.rgtsector,1);
      HexDump(rwbuff,SECSIZE);
     End;
     'G':Begin
      WriteLn('Sortir le GRT...');
      HexDump(grtbuff,SECSIZE);
     End;
     'Q':Begin
      WriteLn('Sortir...');
      Done:=True;
     End;
    End;
   End;
   Close(Channel);
  End;
 End;
END.
