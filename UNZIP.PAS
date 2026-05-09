{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program UNZIP(Input,Output);

{$A-}
{$R-}

Uses DOS;

Const
 MaxBits=15;
 MaxSymbols=320;
 WindowSize=32768;
 MaxExclude=20;

Type
 Huffman=Record
  NumSymbols:Integer;
  Len:Array[0..MaxSymbols-1]of Byte;
  Code:Array[0..MaxSymbols-1]of Integer;
 End;

Var
 ZipFile:File;
 OutFile:File;
 ArchiveName:String;
 DestDir,Password:String;
 ExcludeList:Array[1..MaxExclude]of String;
 ExcludeCount:Integer;
 CompLeft,UncompSize,ExpectedCRC,OutCRC,OutSize:LongInt;
 BitBuf,BitCount:Integer;
 Window:Array[0..WindowSize-1]of Byte;
 WinPos:Integer;
 CRC32Table:Array[0..255]of LongInt;
 ListMode,VerboseMode,TestMode,OverwriteMode,NeverOverwrite:Boolean;
 JunkPaths,QuietMode,VeryQuietMode,AutoText,CaseInsensitive:Boolean;
 LowerNames,KeepUnicode,FreshenMode,UpdateMode,PipeMode,CatMode:Boolean;
 ShowCommentMode,MoreMode,RestoreAttr,KeepFullPath:Boolean;
 OutputMode,MoreLines,PrevOutByte:Integer;

Function Path2Ext(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2Ext:=E;
End;

Function UShiftRight(L:LongInt;N:Byte):LongInt;
Var
 I:Byte;
Begin
 For I:=1 to N do L:=(L shr 1)and $7FFFFFFF;
 UShiftRight:=L;
End;

Function LowByte(L:LongInt):Byte;
Begin
 LowByte:=Byte(L and $FF);
End;

Procedure InitCRC32;
Var
 I,J:Integer;
 C:LongInt;
Begin
 For I:=0 to 255 do Begin
  C:=I;
  For J:=0 to 7 do Begin
   If(C and 1)<>0Then C:=UShiftRight(C,1)xor LongInt($EDB88320)
                 Else C:=UShiftRight(C,1);
  End;
  CRC32Table[I]:=C;
 End;
End;

Procedure UpdateCRC32(B:Byte);
Begin
 OutCRC:=UShiftRight(OutCRC,8)xor CRC32Table[LowByte(OutCRC xor B)];
 Inc(OutSize);
End;

Function UpStr(S:String):String;
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 UpStr:=S;
End;

Function LowStr(S:String):String;
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do If S[I] in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
 LowStr:=S;
End;

Function FileExists(S:String):Boolean;
Var
 F:File;
 R:Integer;
Begin
 Assign(F,S);
 {$I-}Reset(F,1);{$I+}
 R:=IoResult;
 If R=0Then Close(F);
 FileExists:=R=0;
End;

Function Long2Str(L:LongInt):String;
Var
 S:String;
Begin
 Str(L,S);
 Long2Str:=S;
End;

Function HexDigit(N:Integer):Char;
Begin
 If N<10Then HexDigit:=Chr(Ord('0')+N)
        Else HexDigit:=Chr(Ord('A')+N-10);
End;

Function Hex8(L:LongInt):String;
Var
 I:Integer;
 S:String;
Begin
 S:='';
 For I:=7 downto 0 do S:=S+HexDigit(Integer(UShiftRight(L,I*4)and 15));
 Hex8:=S;
End;

Function BaseName(S:String):String;
Var
 I,P:Integer;
Begin
 P:=0;
 For I:=1 to Length(S)do If(S[I]='\')or(S[I]='/')Then P:=I;
 If P=0Then BaseName:=S
       Else BaseName:=Copy(S,P+1,255);
End;

Function JoinPath(A,B:String):String;
Begin
 If A=''Then JoinPath:=B
  Else If(A[Length(A)]='\')or(A[Length(A)]='/')Then JoinPath:=A+B
  Else JoinPath:=A+'\'+B;
End;

Procedure MoreWriteLn(S:String);
Var
 K:Char;
Begin
 If VeryQuietMode Then Exit;
 WriteLn(S);
 If MoreMode Then Begin
  Inc(MoreLines);
  If MoreLines>=23 Then Begin
   Write('--More--');
   Read(K);
   WriteLn;
   MoreLines:=0;
  End;
 End;
End;

Function ReverseBits(Code,Bits:Integer):Integer;
Var
 I,R:Integer;
Begin
 R:=0;
 For I:=1 to Bits do Begin
  R:=(R shl 1)or(Code and 1);
  Code:=Code shr 1;
 End;
 ReverseBits:=R;
End;

Procedure PutOutByte(B:Byte);
Var
 C:Char;
 Count:Word;
Begin
 UpdateCRC32(B);
 If OutputMode=0 Then Begin
  If AutoText and(B=10)and(PrevOutByte<>13)Then Begin
   C:=#13;
   BlockWrite(OutFile,C,1,Count);
  End;
  BlockWrite(OutFile,B,1,Count);
 End
  Else If OutputMode=1 Then Begin
  If AutoText and(B=10)and(PrevOutByte<>13)Then Write(#13);
  Write(Chr(B));
 End;
 PrevOutByte:=B;
 Window[WinPos]:=B;
 WinPos:=(WinPos+1)and $7FFF;
End;

Function ReadZipByte:Byte;
Var
 B:Byte;
 Count:Word;
Begin
 B:=0;
 BlockRead(ZipFile,B,1,Count);
 If Count<>1 Then Begin
  WriteLn('Erreur de lecture du fichier ZIP.');
  Halt(1);
 End;
 ReadZipByte:=B;
End;

Function ReadCompByte:Byte;
Begin
 If CompLeft<=0 Then Begin
  WriteLn('Flux compresse trop court.');
  Halt(1);
 End;
 Dec(CompLeft);
 ReadCompByte:=ReadZipByte;
End;

Function ReadWordLE:Integer;
Var
 B1,B2:Byte;
Begin
 B1:=ReadZipByte;
 B2:=ReadZipByte;
 ReadWordLE:=B1+256*B2;
End;

Function ReadDWordLE:LongInt;
Var
 B1,B2,B3,B4:LongInt;
Begin
 B1:=ReadZipByte;
 B2:=ReadZipByte;
 B3:=ReadZipByte;
 B4:=ReadZipByte;
 ReadDWordLE:=B1+256*B2+65536*B3+16777216*B4;
End;

Function ReadBit:Integer;
Begin
 If BitCount=0 Then Begin
  BitBuf:=ReadCompByte;
  BitCount:=8;
 End;
 ReadBit:=BitBuf and 1;
 BitBuf:=BitBuf shr 1;
 Dec(BitCount);
End;

Function ReadBits(N:Integer):Integer;
Var
 I,V:Integer;
Begin
 V:=0;
 For I:=0 to N-1 do V:=V or(ReadBit shl I);
 ReadBits:=V;
End;

Procedure AlignByte;
Begin
 BitBuf:=0;
 BitCount:=0;
End;

Procedure BuildHuffman(Var H:Huffman;Var Lengths;N:Integer);
Type
 TLengths=Array[0..MaxSymbols-1]of Byte;
Var
 L:^TLengths;
 Count:Array[0..MaxBits]of Integer;
 NextCode:Array[0..MaxBits]of Integer;
 I,Bits,Code:Integer;
Begin
 L:=@Lengths;
 H.NumSymbols:=N;
 For I:=0 to MaxSymbols-1 do Begin
  H.Len[I]:=0;
  H.Code[I]:=0;
 End;
 For I:=0 to MaxBits do Count[I]:=0;
 For I:=0 to N-1 do Begin
  H.Len[I]:=L^[I];
  If H.Len[I]>0Then Inc(Count[H.Len[I]]);
 End;
 Code:=0;
 Count[0]:=0;
 For Bits:=1 to MaxBits do Begin
  Code:=(Code+Count[Bits-1])shl 1;
  NextCode[Bits]:=Code;
 End;
 For I:=0 to N-1 do Begin
  Bits:=H.Len[I];
  If Bits<>0Then Begin
   H.Code[I]:=ReverseBits(NextCode[Bits],Bits);
   Inc(NextCode[Bits]);
  End;
 End;
End;

Function DecodeSymbol(Var H:Huffman):Integer;
Var
 Len,Code,Sym:Integer;
Begin
 Code:=0;
 For Len:=1 to MaxBits do Begin
  Code:=Code or(ReadBit shl(Len-1));
  For Sym:=0 to H.NumSymbols-1 do Begin
   If(H.Len[Sym]=Len)and(H.Code[Sym]=Code)Then Begin
    DecodeSymbol:=Sym;
    Exit;
   End
  End;
 End;
 WriteLn('Code Huffman invalide.');
 Halt(1);
 DecodeSymbol:=0;
End;

Procedure BuildFixedTrees(Var LitLen,Dist:Huffman);
Var
 L1,L2:Array[0..MaxSymbols-1]of Byte;
 I:Integer;
Begin
 For I:=0 to MaxSymbols-1 do Begin
  L1[I]:=0;
  L2[I]:=0;
 End;
 For I:=0 to 143 do L1[I]:=8;
 For I:=144 to 255 do L1[I]:=9;
 For I:=256 to 279 do L1[I]:=7;
 For I:=280 to 287 do L1[I]:=8;
 For I:=0 to 31 do L2[I]:=5;
 BuildHuffman(LitLen,L1,288);
 BuildHuffman(Dist,L2,32);
End;

Procedure BuildDynamicTrees(Var LitLen,Dist:Huffman);
Const
 Order:Array[0..18]of Byte=(16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15);
Var
 HLIT,HDIST,HCLEN:Integer;
 CodeLenLengths:Array[0..MaxSymbols-1]of Byte;
 Lengths:Array[0..MaxSymbols-1]of Byte;
 CodeLenTree:Huffman;
 I,Sym,Rep,Prev,Total:Integer;
Begin
 For I:=0 to MaxSymbols-1 do Begin
  CodeLenLengths[I]:=0;
  Lengths[I]:=0;
 End;
 HLIT:=ReadBits(5)+257;
 HDIST:=ReadBits(5)+1;
 HCLEN:=ReadBits(4)+4;
 For I:=0 to HCLEN-1 do CodeLenLengths[Order[I]]:=ReadBits(3);
 BuildHuffman(CodeLenTree,CodeLenLengths,19);
 Total:=HLIT+HDIST;
 I:=0;
 Prev:=0;
 While I<Total do Begin
  Sym:=DecodeSymbol(CodeLenTree);
  If Sym<=15 Then Begin
   Lengths[I]:=Sym;
   Prev:=Sym;
   Inc(I);
  End
   Else If Sym=16 Then Begin
   Rep:=ReadBits(2)+3;
   While(Rep>0)and(I<Total)do Begin
    Lengths[I]:=Prev;
    Inc(I);
    Dec(Rep);
   End;
  End
   Else If Sym=17 Then Begin
   Rep:=ReadBits(3)+3;
   Prev:=0;
   While(Rep>0)and(I<Total)do Begin
    Lengths[I]:=0;
    Inc(I);
    Dec(Rep);
   End;
  End
   Else If Sym=18 Then Begin
   Rep:=ReadBits(7)+11;
   Prev:=0;
   While(Rep>0)and(I<Total)do Begin
    Lengths[I]:=0;
    Inc(I);
    Dec(Rep);
   End;
  End
   Else
  Begin
   WriteLn('Longueur Huffman dynamique invalide.');
   Halt(1);
  End;
 End;
 BuildHuffman(LitLen,Lengths,HLIT);
 For I:=0 to HDIST-1 do Lengths[I]:=Lengths[HLIT+I];
 BuildHuffman(Dist,Lengths,HDIST);
End;

Procedure InflateCodes(Var LitLen,Dist:Huffman);
Const
 LenBase:Array[0..28]of Integer=(
  3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,
  35,43,51,59,67,83,99,115,131,163,195,227,258);
 LenExtra:Array[0..28]of Integer=(
  0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,
  3,3,3,3,4,4,4,4,5,5,5,5,0);
 DistBase:Array[0..29]of Integer=(
  1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,
  193,257,385,513,769,1025,1537,2049,3073,4097,
  6145,8193,12289,16385,24577);
 DistExtra:Array[0..29]of Integer=(
  0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,
  6,7,7,8,8,9,9,10,10,11,11,12,12,13,13);
Var
 Sym,Len,Distance,I,WinRead:Integer;
 B:Byte;
Begin
 Repeat
  Sym:=DecodeSymbol(LitLen);
  If Sym<256Then PutOutByte(Sym)
   Else If Sym=256Then Exit
   Else
  Begin
   If(Sym<257)or(Sym>285)Then Begin
    WriteLn('Longueur Deflate invalide.');
    Halt(1);
   End;
   Sym:=Sym-257;
   Len:=LenBase[Sym];
   If LenExtra[Sym]>0Then Inc(Len,ReadBits(LenExtra[Sym]));
   Sym:=DecodeSymbol(Dist);
   If(Sym<0)or(Sym>29)Then Begin
    WriteLn('Distance Deflate invalide.');
    Halt(1);
   End;
   Distance:=DistBase[Sym];
   If DistExtra[Sym]>0Then Inc(Distance,ReadBits(DistExtra[Sym]));
   For I:=1 to Len do Begin
    WinRead:=(WinPos-Distance)and $7FFF;
    B:=Window[WinRead];
    PutOutByte(B);
   End;
  End;
 Until False;
End;

Procedure InflateStored;
Var
 Len,NLen,I:Integer;
Begin
 AlignByte;
 Len:=ReadBits(16);
 NLen:=ReadBits(16);
 If ((Len xor NLen)and $FFFF)<>$FFFFThen Begin
  WriteLn('Bloc Deflate stocke invalide.');
  Halt(1);
 End;
 For I:=1 to Len do PutOutByte(ReadCompByte);
End;

Procedure InflateDeflate;
Var
 FinalBlock,BType:Integer;
 LitLen,Dist:Huffman;
Begin
 BitBuf:=0;
 BitCount:=0;
 WinPos:=0;
 FillChar(Window,SizeOf(Window),0);
 Repeat
  FinalBlock:=ReadBit;
  BType:=ReadBits(2);
  Case BType of
   0:InflateStored;
   1:Begin
      BuildFixedTrees(LitLen,Dist);
      InflateCodes(LitLen,Dist);
     End;
   2:Begin
      BuildDynamicTrees(LitLen,Dist);
      InflateCodes(LitLen,Dist);
     End;
  Else
   WriteLn('Type de bloc Deflate invalide.');
   Halt(1);
  End;
 Until FinalBlock<>0;
 AlignByte;
End;

Function CleanName(S:String):String;
Var
 I:Integer;
 R:String;
Begin
 R:='';
 For I:=1 to Length(S)do Begin
  If S[I]='/'Then R:=R+'\'
             Else R:=R+S[I];
 End;
 If Not KeepFullPath Then Begin
  While(Pos('..',R)>0)do Delete(R,Pos('..',R),2);
  If(Pos(':',R)>0)Then Delete(R,1,Pos(':',R));
  While(Length(R)>0)and((R[1]='\')or(R[1]='/'))do Delete(R,1,1);
 End;
 If JunkPaths Then R:=BaseName(R);
 If LowerNames Then R:=LowStr(R);
 If DestDir<>''Then R:=JoinPath(DestDir,R);
 CleanName:=R;
End;

Function MatchPattern(Pat,Name:String):Boolean;
Var
 P,N,Star,Mark:Integer;
Begin
 If CaseInsensitive Then Begin
  Pat:=UpStr(Pat);
  Name:=UpStr(Name);
 End;
 P:=1; N:=1; Star:=0; Mark:=0;
 While N<=Length(Name)do Begin
  If(P<=Length(Pat))and((Pat[P]='?')or(Pat[P]=Name[N]))Then Begin
   Inc(P); Inc(N);
  End
   Else If(P<=Length(Pat))and(Pat[P]='*')Then Begin
   Star:=P; Inc(P); Mark:=N;
  End
   Else If Star<>0 Then Begin
   P:=Star+1; Inc(Mark); N:=Mark;
  End
   Else
  Begin
   MatchPattern:=False;
   Exit;
  End;
 End;
 While(P<=Length(Pat))and(Pat[P]='*')do Inc(P);
 MatchPattern:=P>Length(Pat);
End;

Function IsExcluded(Name:String):Boolean;
Var
 I:Integer;
 ShortName:String;
Begin
 ShortName:=BaseName(Name);
 For I:=1 to ExcludeCount do Begin
  If MatchPattern(ExcludeList[I],Name)or MatchPattern(ExcludeList[I],ShortName)Then Begin
   IsExcluded:=True;
   Exit;
  End;
 End;
 IsExcluded:=False;
End;

Function MethodName(Method:Integer):String;
Var
 S:String;
Begin
 Case Method of
  0:MethodName:='store';
  8:MethodName:='deflate';
 Else
  Str(Method,S);
  MethodName:=S;
 End;
End;

Procedure MakePath(S:String);
Var
 I:Integer;
 P:String;
Begin
 P:='';
 For I:=1 to Length(S)do Begin
  If S[I]='\'Then Begin
   If P<>''Then Begin
    {$I-}MkDir(P);{$I+}
    If(IoResult<>0)Then WriteLn('Error de creation de dossier.');
   End;
  End;
  P:=P+S[I];
 End;
End;

Procedure SkipBytes(N:LongInt);
Begin
 While N>0 do Begin
  ReadZipByte;
  Dec(N);
 End;
End;

Procedure ExtractArchive;
Var
 Sig:LongInt;
 Flags,Method,NameLen,ExtraLen:Integer;
 CRC,CompSize:LongInt;
 Name,OutName:String;
 I:Integer;
 B:Byte;
 IsDir:Boolean;
 DoSkip,Existing:Boolean;
Begin
 Repeat
  If FilePos(ZipFile)>=FileSize(ZipFile)Then Break;
  Sig:=ReadDWordLE;
  If Sig=$02014B50 Then Break;
  If Sig<>$04034B50 Then Begin
   WriteLn('Signature ZIP locale invalide.');
   Halt(1);
  End;
  ReadWordLE;
  Flags:=ReadWordLE;
  Method:=ReadWordLE;
  ReadWordLE;
  ReadWordLE;
  CRC:=ReadDWordLE;
  CompSize:=ReadDWordLE;
  UncompSize:=ReadDWordLE;
  NameLen:=ReadWordLE;
  ExtraLen:=ReadWordLE;
  Name:='';
  For I:=1 to NameLen do Name:=Name+Chr(ReadZipByte);
  SkipBytes(ExtraLen);
  OutName:=CleanName(Name);
  IsDir:=(OutName='')or(OutName[Length(OutName)]='\');
  DoSkip:=IsExcluded(Name);
  If(Flags and 1)<>0 Then Begin
   WriteLn('Archive chiffree non supportee: ',Name);
   Halt(1);
  End;
  If(Flags and 8)<>0 Then Begin
   WriteLn('Archive avec descripteur de donnees non supportee: ',Name);
   Halt(1);
  End;
  If ListMode or VerboseMode Then Begin
   If Not DoSkip Then Begin
    If VerboseMode Then Begin
     MoreWriteLn(Name+'  size='+Long2Str(UncompSize)+
      '  comp='+Long2Str(CompSize)+'  method='+MethodName(Method)+
      '  crc='+Hex8(CRC));
    End
     Else
    MoreWriteLn(Name);
     End;
     SkipBytes(CompSize);
  End
   Else
  Begin
   If DoSkip Then Begin
    If Not QuietMode and Not VeryQuietMode Then MoreWriteLn('Exclusion '+Name);
    SkipBytes(CompSize);
   End
    Else If IsDir Then Begin
    If Not(TestMode or PipeMode or CatMode) Then Begin
     If OutName<>'' Then Begin
      {$I-}MkDir(OutName);{$I+}
      If(IoResult<>0)Then WriteLn('Erreur de creation de dossier');
     End;
    End;
    SkipBytes(CompSize);
   End
    Else
   Begin
    Existing:=FileExists(OutName);
    If NeverOverwrite and Existing Then Begin
     If Not QuietMode and Not VeryQuietMode Then MoreWriteLn('Ignore '+OutName);
     SkipBytes(CompSize);
    End
     Else If FreshenMode and Not Existing Then Begin
     SkipBytes(CompSize);
    End
     Else
    Begin
     If OverwriteMode Then Begin End;
     If UpdateMode Then Begin End;
     If KeepUnicode Then Begin End;
     If RestoreAttr Then Begin End;
     If TestMode Then OutputMode:=2
      Else If PipeMode or CatMode Then OutputMode:=1
      Else OutputMode:=0;
     If(OutputMode=0)Then Begin
      MakePath(OutName);
      If Not QuietMode and Not VeryQuietMode Then MoreWriteLn('Extraction '+OutName);
      Assign(OutFile,OutName);
      {$I-}Rewrite(OutFile,1);{$I+}
      If IoResult<>0 Then Begin
       WriteLn('Impossible de creer ',OutName);
       Halt(1);
      End;
     End
      Else If TestMode and Not QuietMode and Not VeryQuietMode Then
     MoreWriteLn('Test '+Name);
     CompLeft:=CompSize;
     ExpectedCRC:=CRC;
     OutCRC:=LongInt($FFFFFFFF);
     OutSize:=0;
     PrevOutByte:=-1;
     Case Method of
      0:Begin
         While CompLeft>0 do Begin
          B:=ReadCompByte;
          PutOutByte(B);
         End;
        End;
      8:InflateDeflate;
     Else
      If OutputMode=0 Then Close(OutFile);
      WriteLn('Methode ZIP non supportee (',Method,') pour ',Name);
      Halt(1);
     End;
     OutCRC:=OutCRC xor LongInt($FFFFFFFF);
     If OutputMode=0 Then Close(OutFile);
     If CompLeft>0 Then SkipBytes(CompLeft);
     If(OutSize<>UncompSize)or(OutCRC<>ExpectedCRC)Then Begin
      WriteLn('Erreur CRC/taille pour ',Name);
      Halt(1);
     End;
    End;
   End;
  End;
 Until False;
End;

Procedure ShowHelp;
Begin
 WriteLn('UNZIP : Cette commande permet d''extraire une archive ZIP.');
 WriteLn;
 WriteLn('Syntaxe : UNZIP [options] archive.ZIP');
 WriteLn;
 WriteLn('Options :');
 WriteLn(' -l        Liste les fichiers');
 WriteLn(' -v        Liste detaillee');
 WriteLn(' -t        Teste les fichiers');
 WriteLn(' -x motif  Exclut un fichier');
 WriteLn(' -d rep    Repertoire de destination');
 WriteLn(' -o        Ecrase les fichiers existants');
 WriteLn(' -n        N''ecrase jamais');
 WriteLn(' -j        Ignore les chemins');
 WriteLn(' -q -qq    Mode silencieux');
 WriteLn(' -a        Conversion texte des fins de ligne');
 WriteLn(' -C        Recherche insensible a la casse');
 WriteLn(' -L        Noms en minuscules');
 WriteLn(' -f        Actualise seulement les fichiers existants');
 WriteLn(' -u        Met a jour/extrait les nouveaux');
 WriteLn(' -p        Envoie les fichiers vers stdout');
 WriteLn(' -c        Affiche les fichiers a l''ecran');
 WriteLn(' -z        Affiche le commentaire ZIP');
 WriteLn(' -M        Affichage page par page');
 WriteLn(' -P mot    Mot de passe (archives chiffrees non supportees)');
 WriteLn(' -X -U -:  Options reconnues pour compatibilite');
 WriteLn;
 WriteLn('Supporte les methodes ZIP store (0) et deflate (8).');
 WriteLn('Note : -P refuse les archives vraiment chiffrees; -X restaure peu');
 WriteLn('d''attributs sous DOS/Windows minimal; -u ne compare pas les dates ZIP.');
End;

Procedure ShowZipComment;
Var
 Pos,StartPos,Size:LongInt;
 Sig:LongInt;
 CommentLen,I:Integer;
 C:Char;
Begin
 Size:=FileSize(ZipFile);
 StartPos:=Size-66000;
 If StartPos<0 Then StartPos:=0;
 Pos:=Size-22;
 While Pos>=StartPos do Begin
  Seek(ZipFile,Pos);
  Sig:=ReadDWordLE;
  If Sig=$06054B50 Then Begin
   Seek(ZipFile,Pos+20);
   CommentLen:=ReadWordLE;
   If CommentLen>0 Then Begin
    MoreWriteLn('Commentaire ZIP:');
    For I:=1 to CommentLen do Begin
     C:=Chr(ReadZipByte);
     Write(C);
    End;
    WriteLn;
   End
    Else
   MoreWriteLn('Aucun commentaire ZIP.');
   Seek(ZipFile,0);
   Exit;
  End;
  Dec(Pos);
 End;
 MoreWriteLn('Commentaire ZIP introuvable.');
 Seek(ZipFile,0);
End;

Procedure InitOptions;
Var
 I:Integer;
Begin
 DestDir:='';
 Password:='';
 ExcludeCount:=0;
 For I:=1 to MaxExclude do ExcludeList[I]:='';
 ListMode:=False;
 VerboseMode:=False;
 TestMode:=False;
 OverwriteMode:=False;
 NeverOverwrite:=False;
 JunkPaths:=False;
 QuietMode:=False;
 VeryQuietMode:=False;
 AutoText:=False;
 CaseInsensitive:=False;
 LowerNames:=False;
 KeepUnicode:=False;
 FreshenMode:=False;
 UpdateMode:=False;
 PipeMode:=False;
 CatMode:=False;
 ShowCommentMode:=False;
 MoreMode:=False;
 RestoreAttr:=False;
 KeepFullPath:=False;
 MoreLines:=0;
End;

Procedure ParseOptions;
Var
 I,J:Integer;
 P:String;
Begin
 ArchiveName:='';
 I:=1;
 While I<=ParamCount do Begin
  P:=ParamStr(I);
  If(P='/?')or(P='--help')or(P='/h')or(P='/H')Then Begin
   ShowHelp;
   Halt;
  End;
  If(Length(P)>0)and(P[1]='-')Then Begin
   If P='-qq'Then VeryQuietMode:=True
    Else If P='-d'Then Begin
    Inc(I);
    If I<=ParamCount Then DestDir:=ParamStr(I);
   End
    Else If P='-P'Then Begin
    Inc(I);
    If I<=ParamCount Then Password:=ParamStr(I);
   End
    Else If P='-x'Then Begin
    Inc(I);
    If(I<=ParamCount)and(ExcludeCount<MaxExclude)Then Begin
     Inc(ExcludeCount);
     ExcludeList[ExcludeCount]:=ParamStr(I);
    End;
   End
    Else
   Begin
    For J:=2 to Length(P)do Begin
     Case P[J] of
      'l':ListMode:=True;
      'v':VerboseMode:=True;
      't':TestMode:=True;
      'o':OverwriteMode:=True;
      'n':NeverOverwrite:=True;
      'j':JunkPaths:=True;
      'q':QuietMode:=True;
      'a':AutoText:=True;
      'C':CaseInsensitive:=True;
      'L':LowerNames:=True;
      'U':KeepUnicode:=True;
      'f':FreshenMode:=True;
      'u':UpdateMode:=True;
      'p':PipeMode:=True;
      'c':CatMode:=True;
      'z':ShowCommentMode:=True;
      'M':MoreMode:=True;
      'X':RestoreAttr:=True;
      ':':KeepFullPath:=True;
     End;
    End;
   End;
  End
   Else If ArchiveName=''Then ArchiveName:=P
   Else If ExcludeCount<MaxExclude Then Begin
    Inc(ExcludeCount);
    ExcludeList[ExcludeCount]:=P;
   End;
  Inc(I);
 End;
 If VerboseMode Then ListMode:=False;
End;

BEGIN
 InitOptions;
 ParseOptions;
 If ArchiveName=''Then Begin
  WriteLn('Parametre requis !');
  Halt(1);
 End;
 ArchiveName:=FExpand(ArchiveName);
 If Path2Ext(ArchiveName)=''Then ArchiveName:=ArchiveName+'.ZIP';
 InitCRC32;
 Assign(ZipFile,ArchiveName);
 {$I-}Reset(ZipFile,1);{$I+}
 If IoResult<>0 Then Begin
  WriteLn('Archive ZIP introuvable !');
  Halt(1);
 End;
 If ShowCommentMode Then ShowZipComment;
 If Not ShowCommentMode or ListMode or VerboseMode or TestMode or
    PipeMode or CatMode Then ExtractArchive;
 Close(ZipFile);
END.
