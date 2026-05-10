{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program UNZIP(Input,Output);

{$A-}
{$R-}
{$M 65520,0,655360}

Uses DOS;

Const
 MaxBits=16;
 MaxSymbols=320;
 WindowHalfSize=32768;
 MaxExclude=20;
 ShrinkMaxCode=8191;
 DLEByte=144;
 BZMaxAlphaSize=258;
 BZMaxGroups=6;
 BZGroupSize=50;
 BZMaxSelectors=18002;
 BZChunkSize=16000;
 BZMaxChunks=57;
 LZNumStates=12;
 LZNumPosBitsMax=4;
 LZNumPosStatesMax=16;
 LZNumLenToPosStates=4;
 LZNumAlignBits=4;
 LZAlignTableSize=16;
 LZStartPosModelIndex=4;
 LZEndPosModelIndex=14;
 LZNumFullDistances=128;
 LZLenLowSymbols=8;
 LZLenMidSymbols=8;
 LZLenHighSymbols=256;
 LZLitContextSize=768;
 LZMaxLitContexts=16;
 LZChunkSize=16384;
 LZMaxChunks=256;
 LZBitModelTotal=2048;
 LZMoveBits=5;
 TerseTreeSize=4096;
 TerseCodeSize=257;
 TerseRecordMark=257;
 TerseEOF=0;
 TerseNone=-1;
 TerseStackSize=2047;
 DCLMaxBits=13;
 DCLWindowSize=4096;
 ZstdFSEMaxTableLog=12;
 ZstdFSEMaxTableSize=4096;
 ZstdFSEMaxSymbols=256;
 ZstdHuffMaxSymbols=256;
 ZstdHuffMaxBits=12;
 ZstdHuffMaxTableSize=4096;
 ZstdSeqMaxBlockSize=131072;
 ZstdSeqChunkBits=14;
 ZstdSeqChunkSize=16384;        { 1 shl ZstdSeqChunkBits, < 64 Ko pour TP7 }
 ZstdSeqChunkMask=16383;        { ZstdSeqChunkSize-1 }
 ZstdSeqNumChunks=8;            { ZstdSeqMaxBlockSize div ZstdSeqChunkSize }

Type
 PWindowHalf=^TWindowHalf;
 TWindowHalf=Array[0..WindowHalfSize-1]of Byte;
 Huffman=Record
  NumSymbols:Integer;
  Len:Array[0..MaxSymbols-1]of Byte;
  Code:Array[0..MaxSymbols-1]of LongInt;
 End;
 PShrinkIntArray=^TShrinkIntArray;
 TShrinkIntArray=Array[0..ShrinkMaxCode]of Integer;
 PShrinkByteArray=^TShrinkByteArray;
 TShrinkByteArray=Array[0..ShrinkMaxCode]of Byte;
 PShrinkBoolArray=^TShrinkBoolArray;
 TShrinkBoolArray=Array[0..ShrinkMaxCode]of Boolean;
 PFollowerSizeArray=^TFollowerSizeArray;
 TFollowerSizeArray=Array[0..255]of Byte;
 PFollowerArray=^TFollowerArray;
 TFollowerArray=Array[0..255,0..31]of Byte;
 PBZTTChunk=^TBZTTChunk;
 TBZTTChunk=Array[0..BZChunkSize-1]of LongInt;
 PBZByteChunk=^TBZByteChunk;
 TBZByteChunk=Array[0..BZChunkSize-1]of Byte;
 PLZByteChunk=^TLZByteChunk;
 TLZByteChunk=Array[0..LZChunkSize-1]of Byte;
 PLZLitContext=^TLZLitContext;
 TLZLitContext=Array[0..LZLitContextSize-1]of Word;
 PWordArray=^TWordArray;
 TWordArray=Array[0..32759]of Word;
 PTerseIntArray=^TTerseIntArray;
 TTerseIntArray=Array[0..TerseTreeSize]of Integer;
 TTerseTreeRecord=Record
  Left,Right,Back,NextCount:Integer;
 End;
 PTerseTreeArray=^TTerseTreeArray;
 TTerseTreeArray=Array[0..TerseTreeSize]of TTerseTreeRecord;
 PTerseStackArray=^TTerseStackArray;
 TTerseStackArray=Array[0..TerseStackSize]of Integer;
 PDCLWindow=^TDCLWindow;
 TDCLWindow=Array[0..DCLWindowSize-1]of Byte;
 DCLHuffman=Record
  Count:Array[0..DCLMaxBits]of Integer;
  Symbol:Array[0..255]of Integer;
 End;
 ZstdFSEEntry=Record
  Symbol:Byte;
  Bits:Byte;
  NewState:Integer;
 End;
 ZstdFSETable=Record
  TableLog:Integer;
  TableSize:Integer;
  FastMode:Boolean;
  Entry:Array[0..ZstdFSEMaxTableSize-1]of ZstdFSEEntry;
 End;
 ZstdHuffEntry=Record
  Symbol:Byte;
  Bits:Byte;
 End;
 ZstdHuffTable=Record
  TableLog:Integer;
  TableSize:Integer;
  MaxSymbol:Integer;
  Entry:Array[0..ZstdHuffMaxTableSize-1]of ZstdHuffEntry;
  Weight:Array[0..ZstdHuffMaxSymbols-1]of Byte;
 End;
 PZstdSeqChunk=^TZstdSeqChunk;
 TZstdSeqChunk=Array[0..ZstdSeqChunkSize-1]of Byte;
 PZstdSeqBuffer=^TZstdSeqBuffer;
 TZstdSeqBuffer=Record
  Chunks:Array[0..ZstdSeqNumChunks-1]of PZstdSeqChunk;
 End;
 ZstdRevBitStream=Record
  Buf:PZstdSeqBuffer;
  Base,Size,Pos:LongInt;
  Bits:LongInt;
  BitCount:Integer;
 End;
 ZstdSeqTables=Record
  LL,OFs,ML:ZstdFSETable;
  LLMode,OFMode,MLMode:Integer;
  LLRLE,OFRLE,MLRLE:Byte;
  LLValid,OFValid,MLValid:Boolean;
 End;
 BZHuffman=Record
  MinLen,MaxLen:Integer;
  Len:Array[0..BZMaxAlphaSize-1]of Byte;
  Code:Array[0..BZMaxAlphaSize-1]of LongInt;
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
 WindowLo,WindowHi:PWindowHalf;
 WinPos,WindowMask:LongInt;
 CRC32Table:Array[0..255]of LongInt;
 ListMode,VerboseMode,TestMode,OverwriteMode,NeverOverwrite:Boolean;
 JunkPaths,QuietMode,VeryQuietMode,AutoText,CaseInsensitive:Boolean;
 LowerNames,KeepUnicode,FreshenMode,UpdateMode,PipeMode,CatMode:Boolean;
 ShowCommentMode,MoreMode,RestoreAttr,KeepFullPath:Boolean;
 OutputMode,MoreLines,PrevOutByte:Integer;
 ShrinkPrefix:PShrinkIntArray;
 ShrinkSuffix:PShrinkByteArray;
 ShrinkActive:PShrinkBoolArray;
 ShrinkStack:PShrinkByteArray;
 ReduceSize:PFollowerSizeArray;
 ReduceBits:PFollowerSizeArray;
 ReduceFollowers:PFollowerArray;
 BZTT:Array[0..BZMaxChunks-1]of PBZTTChunk;
 BZByte:Array[0..BZMaxChunks-1]of PBZByteChunk;
 BZBitBuf,BZBitCount:Integer;
 BZBlockLimit:LongInt;
 LZDict:Array[0..LZMaxChunks-1]of PLZByteChunk;
 LZLit:Array[0..LZMaxLitContexts-1]of PLZLitContext;
 LZDictSize,LZDictPos,LZRange,LZCode:LongInt;
 LZIsMatch:Array[0..LZNumStates*LZNumPosStatesMax-1]of Word;
 LZIsRep,LZIsRepG0,LZIsRepG1,LZIsRepG2:Array[0..LZNumStates-1]of Word;
 LZIsRep0Long:Array[0..LZNumStates*LZNumPosStatesMax-1]of Word;
 LZPosSlot:Array[0..LZNumLenToPosStates*64-1]of Word;
 LZPosDecoders:Array[0..LZNumFullDistances-LZEndPosModelIndex-1]of Word;
 LZPosAlign:Array[0..LZAlignTableSize-1]of Word;
 LZLenChoice,LZRepLenChoice:Array[0..1]of Word;
 LZLenLow,LZLenMid,LZRepLenLow,LZRepLenMid:Array[0..LZNumPosStatesMax*8-1]of Word;
 LZLenHigh,LZRepLenHigh:Array[0..LZLenHighSymbols-1]of Word;
 TerseBitsAvailable,TerseSavedBits:Integer;
 DCLBitBuf,DCLBitCount,DCLNext:Integer;
 DCLWin:PDCLWindow;
 ZipCryptActive:Boolean;
 ZipKey0,ZipKey1,ZipKey2:LongInt;
 ZstdRep1,ZstdRep2,ZstdRep3:LongInt;

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

Function CRC32Value(C:LongInt;B:Byte):LongInt; forward;
Function ZipDecryptByte(C:Byte):Byte; forward;

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
 OutCRC:=CRC32Value(OutCRC,B);
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

Function ZipDateTimeStamp(ZTime,ZDate:Integer):LongInt;
Begin
 ZipDateTimeStamp:=(LongInt(ZDate)shl 16)or LongInt(ZTime);
End;

Function GetFileDateTimeStamp(S:String;Var Stamp:LongInt):Boolean;
Var
 F:File;
 R:Integer;
Begin
 Assign(F,S);
 {$I-}Reset(F,1);{$I+}
 R:=IoResult;
 If R<>0Then Begin
  GetFileDateTimeStamp:=False;
  Exit;
 End;
 GetFTime(F,Stamp);
 Close(F);
 GetFileDateTimeStamp:=True;
End;

Procedure SetFileDateTimeStamp(S:String;Stamp:LongInt);
Var
 F:File;
 R:Integer;
Begin
 Assign(F,S);
 {$I-}Reset(F,1);{$I+}
 R:=IoResult;
 If R<>0Then Exit;
 SetFTime(F,Stamp);
 Close(F);
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

Function SameDWord(A,B:LongInt):Boolean;
Begin
 SameDWord:=Hex8(A)=Hex8(B);
End;

Function CRC32Value(C:LongInt;B:Byte):LongInt;
Begin
 CRC32Value:=UShiftRight(C,8)xor CRC32Table[LowByte(C xor B)];
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

Function ReverseBits(Code:LongInt;Bits:Integer):LongInt;
Var
 I:Integer;
 R:LongInt;
Begin
 R:=0;
 For I:=1 to Bits do Begin
  R:=(R shl 1)or(Code and 1);
  Code:=Code shr 1;
 End;
 ReverseBits:=R;
End;

Procedure InitWindow(Use64K:Boolean);
Begin
 If WindowLo=NIL Then GetMem(WindowLo,SizeOf(TWindowHalf));
 If Use64K and(WindowHi=NIL)Then GetMem(WindowHi,SizeOf(TWindowHalf));
 If WindowLo=NIL Then Begin
  WriteLn('Memoire insuffisante pour la fenetre ZIP.');
  Halt(1);
 End;
 If Use64K and(WindowHi=NIL)Then Begin
  WriteLn('Memoire insuffisante pour la fenetre Deflate64.');
  Halt(1);
 End;
 FillChar(WindowLo^,SizeOf(TWindowHalf),0);
 If WindowHi<>NIL Then FillChar(WindowHi^,SizeOf(TWindowHalf),0);
 WinPos:=0;
 WindowMask:=$7FFF;
 If Use64K Then WindowMask:=$FFFF;
End;

Function GetWindowByte(Pos:LongInt):Byte;
Begin
 Pos:=Pos and WindowMask;
 If Pos<WindowHalfSize Then GetWindowByte:=WindowLo^[Pos]
  Else
 Begin
  If WindowHi=NIL Then GetWindowByte:=0
                 Else GetWindowByte:=WindowHi^[Pos-WindowHalfSize];
 End;
End;

Procedure SetWindowByte(Pos:LongInt;B:Byte);
Begin
 Pos:=Pos and WindowMask;
 If Pos<WindowHalfSize Then WindowLo^[Pos]:=B
  Else If WindowHi<>NIL Then WindowHi^[Pos-WindowHalfSize]:=B;
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
 SetWindowByte(WinPos,B);
 WinPos:=(WinPos+1)and WindowMask;
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
Var
 B:Byte;
Begin
 If CompLeft<=0 Then Begin
  WriteLn('Flux compresse trop court.');
  Halt(1);
 End;
 Dec(CompLeft);
 B:=ReadZipByte;
 If ZipCryptActive Then B:=ZipDecryptByte(B);
 ReadCompByte:=B;
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

Procedure ZipCryptUpdate(B:Byte);
Begin
 ZipKey0:=CRC32Value(ZipKey0,B);
 ZipKey1:=ZipKey1+LowByte(ZipKey0);
 ZipKey1:=ZipKey1*LongInt(134775813)+1;
 ZipKey2:=CRC32Value(ZipKey2,Byte(UShiftRight(ZipKey1,24)and $FF));
End;

Function ZipCryptByte:Byte;
Var
 T:LongInt;
Begin
 T:=(ZipKey2 or 2)and $FFFF;
 ZipCryptByte:=Byte(UShiftRight(T*(T xor 1),8)and $FF);
End;

Function ZipDecryptByte(C:Byte):Byte;
Var
 P:Byte;
Begin
 P:=C xor ZipCryptByte;
 ZipCryptUpdate(P);
 ZipDecryptByte:=P;
End;

Procedure ZipCryptInit(Pwd:String);
Var
 I:Integer;
Begin
 ZipKey0:=LongInt(305419896);
 ZipKey1:=LongInt(591751049);
 ZipKey2:=LongInt(878082192);
 For I:=1 to Length(Pwd)do ZipCryptUpdate(Byte(Ord(Pwd[I])));
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

Function ReadBitsLong(N:Integer):LongInt;
Var
 I:Integer;
 V:LongInt;
Begin
 V:=0;
 For I:=0 to N-1 do If ReadBit<>0 Then V:=V or(LongInt(1)shl I);
 ReadBitsLong:=V;
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
 NextCode:Array[0..MaxBits]of LongInt;
 I,Bits:Integer;
 Code:LongInt;
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

Procedure BuildHuffmanInvert(Var H:Huffman;Var Lengths;N:Integer);
Type
 TLengths=Array[0..MaxSymbols-1]of Byte;
Var
 L:^TLengths;
 Count:Array[0..MaxBits]of Integer;
 NextCode:Array[0..MaxBits]of LongInt;
 I,Bits:Integer;
 Code,Mask:LongInt;
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
   If Bits=16 Then Mask:=$FFFF
              Else Mask:=(LongInt(1)shl Bits)-1;
   H.Code[I]:=ReverseBits((Not NextCode[Bits])and Mask,Bits);
   Inc(NextCode[Bits]);
  End;
 End;
End;

Function DecodeSymbol(Var H:Huffman):Integer;
Var
 Len,Sym:Integer;
 Code:LongInt;
Begin
 Code:=0;
 For Len:=1 to MaxBits do Begin
  If ReadBit<>0 Then Code:=Code or(LongInt(1)shl(Len-1));
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
    B:=GetWindowByte(WinRead);
    PutOutByte(B);
   End;
  End;
 Until False;
End;

Procedure Inflate64Codes(Var LitLen,Dist:Huffman);
Const
 LenBase:Array[0..28]of LongInt=(
  3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,
  35,43,51,59,67,83,99,115,131,163,195,227,3);
 LenExtra:Array[0..28]of Integer=(
  0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,
  3,3,3,3,4,4,4,4,5,5,5,5,16);
 DistBase:Array[0..31]of LongInt=(
  1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,
  193,257,385,513,769,1025,1537,2049,3073,4097,
  6145,8193,12289,16385,24577,32769,49153);
 DistExtra:Array[0..31]of Integer=(
  0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,
  6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14);
Var
 Sym:Integer;
 Len,Distance,I,WinRead:LongInt;
 B:Byte;
Begin
 Repeat
  Sym:=DecodeSymbol(LitLen);
  If Sym<256Then PutOutByte(Sym)
   Else If Sym=256Then Exit
   Else
  Begin
   If(Sym<257)or(Sym>285)Then Begin
    WriteLn('Longueur Deflate64 invalide.');
    Halt(1);
   End;
   Sym:=Sym-257;
   Len:=LenBase[Sym];
   If LenExtra[Sym]>0Then Inc(Len,ReadBitsLong(LenExtra[Sym]));
   Sym:=DecodeSymbol(Dist);
   If(Sym<0)or(Sym>31)Then Begin
    WriteLn('Distance Deflate64 invalide.');
    Halt(1);
   End;
   Distance:=DistBase[Sym];
   If DistExtra[Sym]>0Then Inc(Distance,ReadBitsLong(DistExtra[Sym]));
   If Distance>OutSize Then Begin
    WriteLn('Reference Deflate64 invalide.');
    Halt(1);
   End;
   I:=1;
   While I<=Len do Begin
    WinRead:=(WinPos-Distance)and $FFFF;
    B:=GetWindowByte(WinRead);
    PutOutByte(B);
    Inc(I);
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
 InitWindow(False);
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

Procedure InflateDeflate64;
Var
 FinalBlock,BType:Integer;
 LitLen,Dist:Huffman;
Begin
 BitBuf:=0;
 BitCount:=0;
 InitWindow(True);
 Repeat
  FinalBlock:=ReadBit;
  BType:=ReadBits(2);
  Case BType of
   0:InflateStored;
   1:Begin
      BuildFixedTrees(LitLen,Dist);
      Inflate64Codes(LitLen,Dist);
     End;
   2:Begin
      BuildDynamicTrees(LitLen,Dist);
      Inflate64Codes(LitLen,Dist);
     End;
  Else
   WriteLn('Type de bloc Deflate64 invalide.');
   Halt(1);
  End;
 Until FinalBlock<>0;
 AlignByte;
End;

Function ULess(A,B:LongInt):Boolean;
Begin
 ULess:=(A xor LongInt($80000000))<(B xor LongInt($80000000));
End;

Function LZReadByte:Byte;
Begin
 LZReadByte:=ReadCompByte;
End;

Function LZReadWordLE:Integer;
Var
 B1,B2:Integer;
Begin
 B1:=LZReadByte;
 B2:=LZReadByte;
 LZReadWordLE:=B1+256*B2;
End;

Function LZReadDWordLE:LongInt;
Var
 B1,B2,B3,B4:LongInt;
Begin
 B1:=LZReadByte;
 B2:=LZReadByte;
 B3:=LZReadByte;
 B4:=LZReadByte;
 LZReadDWordLE:=B1+256*B2+65536*B3+16777216*B4;
End;

Procedure LZFree;
Var
 I:Integer;
Begin
 For I:=0 to LZMaxChunks-1 do If LZDict[I]<>NIL Then Begin
  FreeMem(LZDict[I],SizeOf(TLZByteChunk));
  LZDict[I]:=NIL;
 End;
 For I:=0 to LZMaxLitContexts-1 do If LZLit[I]<>NIL Then Begin
  FreeMem(LZLit[I],SizeOf(TLZLitContext));
  LZLit[I]:=NIL;
 End;
End;

Procedure LZAllocDict(Size:LongInt);
Var
 I,Need:Integer;
Begin
 If Size<1 Then Size:=1;
 If Size>UncompSize Then Size:=UncompSize;
 If Size<1 Then Size:=1;
 LZDictSize:=Size;
 Need:=(Size+LZChunkSize-1)div LZChunkSize;
 If Need>LZMaxChunks Then Begin
  WriteLn('Dictionnaire LZMA trop grand pour ce modele memoire.');
  Halt(1);
 End;
 For I:=0 to LZMaxChunks-1 do LZDict[I]:=NIL;
 For I:=0 to Need-1 do Begin
  GetMem(LZDict[I],SizeOf(TLZByteChunk));
  If LZDict[I]=NIL Then Begin
   WriteLn('Memoire insuffisante pour LZMA.');
   Halt(1);
  End;
  FillChar(LZDict[I]^,SizeOf(TLZByteChunk),0);
 End;
 LZDictPos:=0;
End;

Procedure LZAllocLiterals(NumContexts:Integer);
Var
 I,J:Integer;
Begin
 If NumContexts>LZMaxLitContexts Then Begin
  LZFree;
  WriteLn('Contexte litteral LZMA trop grand pour Turbo Pascal.');
  Halt(1);
 End;
 For I:=0 to LZMaxLitContexts-1 do LZLit[I]:=NIL;
 For I:=0 to NumContexts-1 do Begin
  GetMem(LZLit[I],SizeOf(TLZLitContext));
  If LZLit[I]=NIL Then Begin
   LZFree;
   WriteLn('Memoire insuffisante pour les litteraux LZMA.');
   Halt(1);
  End;
  For J:=0 to LZLitContextSize-1 do LZLit[I]^[J]:=LZBitModelTotal div 2;
 End;
End;

Procedure LZSetDictByte(Pos:LongInt;B:Byte);
Var
 C,O:Integer;
Begin
 Pos:=Pos mod LZDictSize;
 C:=Pos div LZChunkSize;
 O:=Pos mod LZChunkSize;
 LZDict[C]^[O]:=B;
End;

Function LZGetDictByte(Pos:LongInt):Byte;
Var
 C,O:Integer;
Begin
 Pos:=Pos mod LZDictSize;
 If Pos<0 Then Inc(Pos,LZDictSize);
 C:=Pos div LZChunkSize;
 O:=Pos mod LZChunkSize;
 LZGetDictByte:=LZDict[C]^[O];
End;

Procedure LZPutByte(B:Byte);
Begin
 PutOutByte(B);
 LZSetDictByte(LZDictPos,B);
 Inc(LZDictPos);
 If LZDictPos>=LZDictSize Then LZDictPos:=0;
End;

Procedure LZInitProbs;
Var
 I:Integer;
Begin
 For I:=0 to High(LZIsMatch)do LZIsMatch[I]:=LZBitModelTotal div 2;
 For I:=0 to High(LZIsRep)do Begin
  LZIsRep[I]:=LZBitModelTotal div 2;
  LZIsRepG0[I]:=LZBitModelTotal div 2;
  LZIsRepG1[I]:=LZBitModelTotal div 2;
  LZIsRepG2[I]:=LZBitModelTotal div 2;
 End;
 For I:=0 to High(LZIsRep0Long)do LZIsRep0Long[I]:=LZBitModelTotal div 2;
 For I:=0 to High(LZPosSlot)do LZPosSlot[I]:=LZBitModelTotal div 2;
 For I:=0 to High(LZPosDecoders)do LZPosDecoders[I]:=LZBitModelTotal div 2;
 For I:=0 to High(LZPosAlign)do LZPosAlign[I]:=LZBitModelTotal div 2;
 For I:=0 to 1 do Begin
  LZLenChoice[I]:=LZBitModelTotal div 2;
  LZRepLenChoice[I]:=LZBitModelTotal div 2;
 End;
 For I:=0 to High(LZLenLow)do Begin
  LZLenLow[I]:=LZBitModelTotal div 2;
  LZLenMid[I]:=LZBitModelTotal div 2;
  LZRepLenLow[I]:=LZBitModelTotal div 2;
  LZRepLenMid[I]:=LZBitModelTotal div 2;
 End;
 For I:=0 to High(LZLenHigh)do Begin
  LZLenHigh[I]:=LZBitModelTotal div 2;
  LZRepLenHigh[I]:=LZBitModelTotal div 2;
 End;
End;

Procedure LZRangeInit;
Var
 I:Integer;
Begin
 LZCode:=0;
 LZRange:=LongInt($FFFFFFFF);
 For I:=1 to 5 do LZCode:=(LZCode shl 8)or LZReadByte;
End;

Procedure LZNormalize;
Begin
 While ULess(LZRange,LongInt($01000000))do Begin
  LZRange:=LZRange shl 8;
  LZCode:=(LZCode shl 8)or LZReadByte;
 End;
End;

Function LZDecodeBit(Var Prob:Word):Integer;
Var
 Bound:LongInt;
Begin
 Bound:=UShiftRight(LZRange,11)*Prob;
 If ULess(LZCode,Bound)Then Begin
  LZRange:=Bound;
  Prob:=Prob+((LZBitModelTotal-Prob)shr LZMoveBits);
  LZNormalize;
  LZDecodeBit:=0;
 End
  Else
 Begin
  LZCode:=LZCode-Bound;
  LZRange:=LZRange-Bound;
  Prob:=Prob-(Prob shr LZMoveBits);
  LZNormalize;
  LZDecodeBit:=1;
 End;
End;

Function LZDecodeDirectBits(NumBits:Integer):LongInt;
Var
 I:Integer;
 Res:LongInt;
Begin
 Res:=0;
 For I:=1 to NumBits do Begin
  LZRange:=UShiftRight(LZRange,1);
  Res:=Res shl 1;
  If Not ULess(LZCode,LZRange)Then Begin
   LZCode:=LZCode-LZRange;
   Res:=Res or 1;
  End;
  LZNormalize;
 End;
 LZDecodeDirectBits:=Res;
End;

Function LZBitTreeDecode(P:Pointer;Offset,NumBits:Integer):Integer;
Var
 A:PWordArray;
 M,I:Integer;
Begin
 A:=P;
 M:=1;
 For I:=1 to NumBits do M:=(M shl 1)or LZDecodeBit(A^[Offset+M]);
 LZBitTreeDecode:=M-(1 shl NumBits);
End;

Function LZReverseBitTreeDecode(P:Pointer;Offset,NumBits:Integer):LongInt;
Var
 A:PWordArray;
 M,I,Bit:Integer;
 Res:LongInt;
Begin
 A:=P;
 M:=1;
 Res:=0;
 For I:=0 to NumBits-1 do Begin
  Bit:=LZDecodeBit(A^[Offset+M]);
  M:=(M shl 1)or Bit;
  Res:=Res or(LongInt(Bit)shl I);
 End;
 LZReverseBitTreeDecode:=Res;
End;

Function LZDecodeLen(PChoice,PLow,PMid,PHigh:Pointer;PosState:Integer):Integer;
Var
 Choice,Low,Mid,High:PWordArray;
Begin
 Choice:=PChoice;
 Low:=PLow;
 Mid:=PMid;
 High:=PHigh;
 If LZDecodeBit(Choice^[0])=0 Then
  LZDecodeLen:=LZBitTreeDecode(Low,PosState*LZLenLowSymbols,3)
 Else If LZDecodeBit(Choice^[1])=0 Then
  LZDecodeLen:=LZLenLowSymbols+
   LZBitTreeDecode(Mid,PosState*LZLenMidSymbols,3)
 Else
  LZDecodeLen:=LZLenLowSymbols+LZLenMidSymbols+
   LZBitTreeDecode(High,0,8);
End;

Function LZStateIsChar(State:Integer):Boolean;
Begin
 LZStateIsChar:=State<7;
End;

Function LZLenToPosState(Len:Integer):Integer;
Begin
 Len:=Len-2;
 If Len<0 Then Len:=0;
 If Len<4 Then LZLenToPosState:=Len
          Else LZLenToPosState:=3;
End;

Function LZDecodeLiteral(Lc,Lp,State:Integer;Rep0:LongInt;Prev:Byte):Byte;
Var
 Ctx,Symbol,Bit,MatchBit:Integer;
 MatchByte:Byte;
 Lit:PLZLitContext;
Begin
 Ctx:=((OutSize and((1 shl Lp)-1))shl Lc)+(Prev shr(8-Lc));
 Lit:=LZLit[Ctx];
 Symbol:=1;
 If Not LZStateIsChar(State)Then Begin
  MatchByte:=LZGetDictByte(LZDictPos-Rep0-1);
  Repeat
   MatchBit:=(MatchByte shr 7)and 1;
   MatchByte:=Byte((MatchByte shl 1)and $FF);
   Bit:=LZDecodeBit(Lit^[((1+MatchBit)shl 8)+Symbol]);
   Symbol:=(Symbol shl 1)or Bit;
   If MatchBit<>Bit Then Break;
  Until Symbol>=256;
 End;
 While Symbol<256 do Symbol:=(Symbol shl 1)or LZDecodeBit(Lit^[Symbol]);
 LZDecodeLiteral:=Byte(Symbol-256);
End;

Procedure InflateLZMA;
Var
 Version,PropSize:Integer;
 Props:Array[0..4]of Byte;
 Prop,DictProp:LongInt;
 Lc,Lp,Pb,NumLitContexts,PosStateMask,PosState:Integer;
 State,Len,LenState,PosSlot,NumDirectBits:Integer;
 Rep0,Rep1,Rep2,Rep3,Dist,I:LongInt;
 Prev,B:Byte;
 Sym:Integer;
Begin
 InitWindow(False);
 Version:=LZReadWordLE;
 If Version=0 Then Begin End;
 PropSize:=LZReadWordLE;
 If PropSize<>5 Then Begin
  WriteLn('Proprietes LZMA ZIP non supportees.');
  Halt(1);
 End;
 For Sym:=0 to 4 do Props[Sym]:=LZReadByte;
 Prop:=Props[0];
 Lc:=Prop mod 9;
 Prop:=Prop div 9;
 Lp:=Prop mod 5;
 Pb:=Prop div 5;
 If(Lc>8)or(Lp>4)or(Pb>4)or(Lc+Lp>4)Then Begin
  WriteLn('Parametres LZMA trop grands pour ce modele memoire.');
  Halt(1);
 End;
 DictProp:=Props[1]+256*LongInt(Props[2])+65536*LongInt(Props[3])+
  16777216*LongInt(Props[4]);
 LZAllocDict(DictProp);
 NumLitContexts:=1 shl(Lc+Lp);
 LZAllocLiterals(NumLitContexts);
 LZInitProbs;
 LZRangeInit;
 PosStateMask:=(1 shl Pb)-1;
 State:=0;
 Rep0:=0; Rep1:=0; Rep2:=0; Rep3:=0;
 Prev:=0;
 While OutSize<UncompSize do Begin
  PosState:=OutSize and PosStateMask;
  If LZDecodeBit(LZIsMatch[State*LZNumPosStatesMax+PosState])=0 Then Begin
   B:=LZDecodeLiteral(Lc,Lp,State,Rep0,Prev);
   LZPutByte(B);
   Prev:=B;
   If State<4 Then State:=0
    Else If State<10 Then Dec(State,3)
    Else Dec(State,6);
  End
   Else
  Begin
   If LZDecodeBit(LZIsRep[State])<>0 Then Begin
    If LZDecodeBit(LZIsRepG0[State])=0 Then Begin
     If LZDecodeBit(LZIsRep0Long[State*LZNumPosStatesMax+PosState])=0 Then Begin
      If State<7 Then State:=9 Else State:=11;
      Len:=1;
     End
      Else Len:=LZDecodeLen(@LZRepLenChoice,@LZRepLenLow,
       @LZRepLenMid,@LZRepLenHigh,PosState)+2;
    End
     Else
    Begin
     If LZDecodeBit(LZIsRepG1[State])=0 Then Dist:=Rep1
      Else Begin
       If LZDecodeBit(LZIsRepG2[State])=0 Then Dist:=Rep2
        Else Begin
         Dist:=Rep3;
         Rep3:=Rep2;
        End;
       Rep2:=Rep1;
      End;
     Rep1:=Rep0;
     Rep0:=Dist;
     Len:=LZDecodeLen(@LZRepLenChoice,@LZRepLenLow,
      @LZRepLenMid,@LZRepLenHigh,PosState)+2;
    End;
    If Len<>1 Then If State<7 Then State:=8 Else State:=11;
   End
    Else
   Begin
    Rep3:=Rep2;
    Rep2:=Rep1;
    Rep1:=Rep0;
    Len:=LZDecodeLen(@LZLenChoice,@LZLenLow,@LZLenMid,@LZLenHigh,PosState)+2;
    LenState:=LZLenToPosState(Len);
    PosSlot:=LZBitTreeDecode(@LZPosSlot,LenState*64,6);
    If PosSlot>=LZStartPosModelIndex Then Begin
     NumDirectBits:=(PosSlot shr 1)-1;
     Rep0:=(LongInt(2)or(PosSlot and 1))shl NumDirectBits;
     If PosSlot<LZEndPosModelIndex Then
      Inc(Rep0,LZReverseBitTreeDecode(@LZPosDecoders,
       Rep0-PosSlot-1,NumDirectBits))
     Else Begin
      Inc(Rep0,LZDecodeDirectBits(NumDirectBits-LZNumAlignBits)
       shl LZNumAlignBits);
      Inc(Rep0,LZReverseBitTreeDecode(@LZPosAlign,0,LZNumAlignBits));
     End;
    End
     Else Rep0:=PosSlot;
    If State<7 Then State:=7 Else State:=10;
   End;
   If(Rep0<0)or(Rep0>=OutSize)Then Begin
    LZFree;
    WriteLn('Reference LZMA invalide.');
    Halt(1);
   End;
   For I:=1 to Len do Begin
    B:=LZGetDictByte(LZDictPos-Rep0-1);
    LZPutByte(B);
    Prev:=B;
   End;
  End;
 End;
 LZFree;
End;

Function DCLBits(Need:Integer):Integer;
Var
 Val:Integer;
Begin
 Val:=DCLBitBuf;
 While DCLBitCount<Need do Begin
  Val:=Val or(Integer(ReadCompByte)shl DCLBitCount);
  Inc(DCLBitCount,8);
 End;
 DCLBitBuf:=Val shr Need;
 Dec(DCLBitCount,Need);
 If Need=0 Then DCLBits:=0
           Else DCLBits:=Val and((1 shl Need)-1);
End;

Function DCLDecode(Var H:DCLHuffman):Integer;
Var
 Len,Code,First,Cnt,Index:Integer;
Begin
 Code:=0;
 First:=0;
 Index:=0;
 For Len:=1 to DCLMaxBits do Begin
  Code:=Code or(DCLBits(1)xor 1);
  Cnt:=H.Count[Len];
  If Code<First+Cnt Then Begin
   DCLDecode:=H.Symbol[Index+(Code-First)];
   Exit;
  End;
  Inc(Index,Cnt);
  Inc(First,Cnt);
  First:=First shl 1;
  Code:=Code shl 1;
 End;
 WriteLn('Code DCL Implode invalide.');
 Halt(1);
 DCLDecode:=0;
End;

Procedure DCLConstruct(Var H:DCLHuffman;Var Rep;RepCount:Integer);
Type
 TRep=Array[0..255]of Byte;
Var
 R:^TRep;
 Length:Array[0..255]of Integer;
 Offs:Array[0..DCLMaxBits]of Integer;
 I,Len,Left,Symbol,N:Integer;
Begin
 R:=@Rep;
 Symbol:=0;
 For I:=0 to RepCount-1 do Begin
  Len:=R^[I];
  Left:=(Len shr 4)+1;
  Len:=Len and 15;
  While Left>0 do Begin
   Length[Symbol]:=Len;
   Inc(Symbol);
   Dec(Left);
  End;
 End;
 N:=Symbol;
 For Len:=0 to DCLMaxBits do H.Count[Len]:=0;
 For Symbol:=0 to N-1 do Inc(H.Count[Length[Symbol]]);
 Left:=1;
 For Len:=1 to DCLMaxBits do Begin
  Left:=Left shl 1;
  Dec(Left,H.Count[Len]);
  If Left<0 Then Begin
   WriteLn('Table DCL Implode invalide.');
   Halt(1);
  End;
 End;
 Offs[1]:=0;
 For Len:=1 to DCLMaxBits-1 do Offs[Len+1]:=Offs[Len]+H.Count[Len];
 For Symbol:=0 to N-1 do If Length[Symbol]<>0 Then Begin
  H.Symbol[Offs[Length[Symbol]]]:=Symbol;
  Inc(Offs[Length[Symbol]]);
 End;
End;

Procedure DCLPutByte(B:Byte);
Begin
 PutOutByte(B);
 DCLWin^[DCLNext]:=B;
 DCLNext:=(DCLNext+1)and $0FFF;
End;

Procedure InflateDCLImplode;
Const
 LitLen:Array[0..97]of Byte=(
  11,124,8,7,28,7,188,13,76,4,10,8,12,10,12,10,8,23,8,
  9,7,6,7,8,7,6,55,8,23,24,12,11,7,9,11,12,6,7,22,5,
  7,24,6,11,9,6,7,22,7,11,38,7,9,8,25,11,8,11,9,12,
  8,12,5,38,5,38,5,11,7,5,6,21,6,10,53,8,7,24,10,27,
  44,253,253,253,252,252,252,13,12,45,12,45,12,61,12,45,
  44,173);
 LenLen:Array[0..5]of Byte=(2,35,36,53,38,23);
 DistLen:Array[0..6]of Byte=(2,20,53,230,247,151,248);
 Base:Array[0..15]of Integer=(
  3,2,4,5,6,7,8,9,10,12,16,24,40,72,136,264);
 Extra:Array[0..15]of Integer=(
  0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8);
Var
 LitCode,LenCode,DistCode:DCLHuffman;
 Lit,Dict,Symbol,Len,Dist,CopyBits,I,FromPos:Integer;
 B:Byte;
Begin
 InitWindow(False);
 If DCLWin=NIL Then GetMem(DCLWin,SizeOf(TDCLWindow));
 If DCLWin=NIL Then Begin
  WriteLn('Memoire insuffisante pour DCL Implode.');
  Halt(1);
 End;
 FillChar(DCLWin^,SizeOf(TDCLWindow),0);
 DCLBitBuf:=0;
 DCLBitCount:=0;
 DCLNext:=0;
 DCLConstruct(LitCode,LitLen,SizeOf(LitLen));
 DCLConstruct(LenCode,LenLen,SizeOf(LenLen));
 DCLConstruct(DistCode,DistLen,SizeOf(DistLen));
 Lit:=DCLBits(8);
 If Lit>1 Then Begin
  WriteLn('En-tete DCL Implode invalide.');
  Halt(1);
 End;
 Dict:=DCLBits(8);
 If(Dict<4)or(Dict>6)Then Begin
  WriteLn('Dictionnaire DCL Implode invalide.');
  Halt(1);
 End;
 While True do Begin
  If DCLBits(1)<>0 Then Begin
   Symbol:=DCLDecode(LenCode);
   Len:=Base[Symbol]+DCLBits(Extra[Symbol]);
   If Len=519 Then Break;
   If Len=2 Then CopyBits:=2 Else CopyBits:=Dict;
   Dist:=(DCLDecode(DistCode)shl CopyBits)+DCLBits(CopyBits)+1;
   If Dist>OutSize Then Begin
    WriteLn('Reference DCL Implode invalide.');
    Halt(1);
   End;
   For I:=1 to Len do Begin
    FromPos:=(DCLNext-Dist)and $0FFF;
    B:=DCLWin^[FromPos];
    DCLPutByte(B);
   End;
  End
   Else
  Begin
   If Lit<>0 Then Symbol:=DCLDecode(LitCode)
             Else Symbol:=DCLBits(8);
   DCLPutByte(Byte(Symbol));
  End;
 End;
 FreeMem(DCLWin,SizeOf(TDCLWindow));
 DCLWin:=NIL;
End;

Function TerseReadByte:Byte;
Begin
 TerseReadByte:=ReadCompByte;
End;

Function TerseReadWordBE:Integer;
Var
 B1,B2:Integer;
Begin
 B1:=TerseReadByte;
 B2:=TerseReadByte;
 TerseReadWordBE:=B1*256+B2;
End;

Function TerseReadDWordBE:LongInt;
Var
 B1,B2,B3,B4:LongInt;
Begin
 B1:=TerseReadByte;
 B2:=TerseReadByte;
 B3:=TerseReadByte;
 B4:=TerseReadByte;
 TerseReadDWordBE:=(((B1*256)+B2)*256+B3)*256+B4;
End;

Function TerseGetBlok:Integer;
Var
 B1,B2:Integer;
Begin
 If TerseBitsAvailable=0 Then Begin
  If CompLeft<=0 Then Begin
   TerseGetBlok:=TerseEOF;
   Exit;
  End;
  B1:=TerseReadByte;
  If CompLeft<=0 Then Begin
   WriteLn('Flux TERSE tronque.');
   Halt(1);
  End;
  B2:=TerseReadByte;
  TerseSavedBits:=B2 and $0F;
  TerseBitsAvailable:=4;
  TerseGetBlok:=(B1 shl 4)or(B2 shr 4);
 End
  Else
 Begin
  If CompLeft<=0 Then Begin
   TerseGetBlok:=TerseEOF;
   Exit;
  End;
  B2:=TerseReadByte;
  TerseBitsAvailable:=0;
  TerseGetBlok:=(TerseSavedBits shl 8)or B2;
 End;
End;

Procedure TersePutChar(X:Integer);
Begin
 If(X=0)or(X=TerseRecordMark)Then Exit;
 If(X<0)or(X>256)Then Begin
  WriteLn('Caractere TERSE invalide.');
  Halt(1);
 End;
 PutOutByte(Byte(X-1));
End;

Procedure InflateTersePack;
Var
 Father,CharExt,Backward,Forward:PTerseIntArray;
 H1,H2,X,D,Y,Q,R,E,P,H:Integer;
Begin
 GetMem(Father,SizeOf(TTerseIntArray));
 GetMem(CharExt,SizeOf(TTerseIntArray));
 GetMem(Backward,SizeOf(TTerseIntArray));
 GetMem(Forward,SizeOf(TTerseIntArray));
 If(Father=NIL)or(CharExt=NIL)or(Backward=NIL)or(Forward=NIL)Then Begin
  WriteLn('Memoire insuffisante pour TERSE PACK.');
  Halt(1);
 End;
 H2:=1+Ord(' ');
 For H1:=258 to 4095 do Begin
  Father^[H1]:=H2;
  CharExt^[H1]:=1+Ord(' ');
  H2:=H1;
 End;
 For H1:=258 to 4094 do Begin
  Backward^[H1+1]:=H1;
  Forward^[H1]:=H1+1;
 End;
 Backward^[0]:=4095;
 Forward^[0]:=258;
 Backward^[258]:=0;
 Forward^[4095]:=0;
 X:=0;
 D:=TerseGetBlok;
 While D<>TerseEOF do Begin
  H:=0;
  Y:=Backward^[0];
  Q:=Backward^[Y];
  Backward^[0]:=Q;
  Forward^[Q]:=0;
  H:=Y;
  P:=0;
  While D>257 do Begin
   Q:=Forward^[D];
   R:=Backward^[D];
   Forward^[R]:=Q;
   Backward^[Q]:=R;
   Forward^[D]:=H;
   Backward^[H]:=D;
   H:=D;
   E:=Father^[D];
   Father^[D]:=P;
   P:=D;
   D:=E;
  End;
  Q:=Forward^[0];
  Forward^[Y]:=Q;
  Backward^[Q]:=Y;
  Forward^[0]:=H;
  Backward^[H]:=0;
  CharExt^[X]:=D;
  TersePutChar(D);
  X:=Y;
  While P<>0 do Begin
   E:=Father^[P];
   TersePutChar(CharExt^[P]);
   Father^[P]:=D;
   D:=P;
   P:=E;
  End;
  Father^[Y]:=D;
  D:=TerseGetBlok;
 End;
 FreeMem(Father,SizeOf(TTerseIntArray));
 FreeMem(CharExt,SizeOf(TTerseIntArray));
 FreeMem(Backward,SizeOf(TTerseIntArray));
 FreeMem(Forward,SizeOf(TTerseIntArray));
End;

Procedure InflateTerseSpack;
Var
 Tree:PTerseTreeArray;
 Stack:PTerseStackArray;
 TreeAvail,Node:Integer;

 Procedure TreeInit;
 Var
  I:Integer;
 Begin
  For I:=0 to TerseTreeSize do Begin
   Tree^[I].Left:=TerseNone;
   Tree^[I].Right:=TerseNone;
   Tree^[I].Back:=0;
   Tree^[I].NextCount:=TerseNone;
  End;
  I:=0;
  While I<=TerseCodeSize do Begin
   Tree^[I].Left:=TerseNone;
   Tree^[I].Right:=I;
   Inc(I);
  End;
  For I:=TerseCodeSize+1 to TerseTreeSize-1 do Begin
   Tree^[I].NextCount:=I+1;
   Tree^[I].Left:=TerseNone;
   Tree^[I].Right:=TerseNone;
  End;
  Tree^[TerseTreeSize].NextCount:=TerseNone;
  Tree^[0].NextCount:=0;
  Tree^[0].Back:=0;
  For I:=1 to TerseCodeSize do Tree^[I].NextCount:=TerseNone;
  TreeAvail:=TerseCodeSize+1;
 End;

 Function GetTreeNode:Integer;
 Begin
  Node:=TreeAvail;
  TreeAvail:=Tree^[Node].NextCount;
  GetTreeNode:=Node;
 End;

 Procedure LruAdd(N:Integer);
 Var
  B:Integer;
 Begin
  B:=Tree^[0].Back;
  Tree^[N].NextCount:=0;
  Tree^[0].Back:=N;
  Tree^[N].Back:=B;
  Tree^[B].NextCount:=N;
 End;

 Procedure DeleteRef(DRef:Integer); forward;

 Procedure LruKill;
 Var
  P,Q,R:Integer;
 Begin
  P:=Tree^[0].NextCount;
  Q:=Tree^[P].NextCount;
  R:=Tree^[P].Back;
  Tree^[Q].Back:=R;
  Tree^[R].NextCount:=Q;
  DeleteRef(Tree^[P].Left);
  DeleteRef(Tree^[P].Right);
  Tree^[P].NextCount:=TreeAvail;
  TreeAvail:=P;
 End;

 Procedure DeleteRef(DRef:Integer);
 Begin
  If Tree^[DRef].NextCount=-1 Then LruAdd(DRef)
   Else Inc(Tree^[DRef].NextCount);
 End;

 Procedure BumpRef(BRef:Integer);
 Var
  F,P:Integer;
 Begin
  If Tree^[BRef].NextCount<0 Then Dec(Tree^[BRef].NextCount)
   Else Begin
   F:=Tree^[BRef].NextCount;
   P:=Tree^[BRef].Back;
   Tree^[P].NextCount:=F;
   Tree^[F].Back:=P;
   Tree^[BRef].NextCount:=-1;
  End;
 End;

 Procedure PutChars(X:Integer);
 Begin
  Stack^[0]:=0;
  While True do Begin
   While X>TerseCodeSize do Begin
    Inc(Stack^[0]);
    If Stack^[0]>TerseStackSize Then Begin
     WriteLn('Pile TERSE pleine.');
     Halt(1);
    End;
    Stack^[Stack^[0]]:=Tree^[X].Right;
    X:=Tree^[X].Left;
   End;
   If X<0 Then Begin
    WriteLn('Sequence TERSE invalide.');
    Halt(1);
   End;
   TersePutChar(X);
   If Stack^[0]>0 Then Begin
    X:=Stack^[Stack^[0]];
    Dec(Stack^[0]);
   End
    Else Break;
  End;
 End;

Var
 N,G,H:Integer;
Begin
 GetMem(Tree,SizeOf(TTerseTreeArray));
 GetMem(Stack,SizeOf(TTerseStackArray));
 If(Tree=NIL)or(Stack=NIL)Then Begin
  WriteLn('Memoire insuffisante pour TERSE SPACK.');
  Halt(1);
 End;
 TreeInit;
 Tree^[TerseTreeSize-1].NextCount:=TerseNone;
 H:=TerseGetBlok;
 If H<>TerseEOF Then Begin
  PutChars(H);
  G:=TerseGetBlok;
  While G<>TerseEOF do Begin
   If TreeAvail=TerseNone Then LruKill;
   PutChars(G);
   N:=GetTreeNode;
   Tree^[N].Left:=H;
   Tree^[N].Right:=G;
   BumpRef(H);
   BumpRef(G);
   LruAdd(N);
   H:=G;
   G:=TerseGetBlok;
  End;
 End;
 FreeMem(Tree,SizeOf(TTerseTreeArray));
 FreeMem(Stack,SizeOf(TTerseStackArray));
End;

Procedure InflateTerse;
Var
 Version,Byte2,Byte3,Byte4,VariableFlag,Flags,Ratio:Integer;
 RecordLen1,BlockSize:Integer;
 RecordLen2:LongInt;
 Spack:Boolean;
Begin
 InitWindow(False);
 TerseBitsAvailable:=0;
 TerseSavedBits:=0;
 Version:=TerseReadByte;
 Spack:=True;
 Case Version of
  $01,$07:Begin
    Byte2:=TerseReadByte;
    Byte3:=TerseReadByte;
    Byte4:=TerseReadByte;
    RecordLen1:=TerseReadWordBE;
    If(RecordLen1=0)Then Begin End;
    If(Byte2<>$89)or(Byte3<>$69)or(Byte4<>$A5)Then Begin
     WriteLn('En-tete TERSE invalide.');
     Halt(1);
    End;
    Spack:=False;
   End;
  $02,$05:Begin
    VariableFlag:=TerseReadByte;
    RecordLen1:=TerseReadWordBE;
    Flags:=TerseReadByte;
    Ratio:=TerseReadByte;
    BlockSize:=TerseReadWordBE;
    RecordLen2:=TerseReadDWordBE;
    If(VariableFlag<>0)and(VariableFlag<>1)Then Begin
     WriteLn('Format enregistrement TERSE invalide.');
     Halt(1);
    End;
    If(RecordLen1=0)and(RecordLen2=0)Then Begin
     WriteLn('Longueur enregistrement TERSE invalide.');
     Halt(1);
    End;
    If(Flags=0)and((Ratio<>0)or(BlockSize<>0))Then Begin
     WriteLn('En-tete TERSE invalide.');
     Halt(1);
    End;
    Spack:=Version=$05;
   End;
 Else
  WriteLn('Version TERSE non reconnue.');
  Halt(1);
 End;
 If Spack Then InflateTerseSpack
          Else InflateTersePack;
End;

Function ZstdReadByte:Byte;
Begin
 ZstdReadByte:=ReadCompByte;
End;

Function ZstdReadWordLE:LongInt;
Var
 B1,B2:LongInt;
Begin
 B1:=ZstdReadByte;
 B2:=ZstdReadByte;
 ZstdReadWordLE:=B1+256*B2;
End;

Function ZstdReadDWordLE:LongInt;
Var
 B1,B2,B3,B4:LongInt;
Begin
 B1:=ZstdReadByte;
 B2:=ZstdReadByte;
 B3:=ZstdReadByte;
 B4:=ZstdReadByte;
 ZstdReadDWordLE:=B1+256*B2+65536*B3+16777216*B4;
End;

Procedure ZstdSkip(N:LongInt);
Begin
 While N>0 do Begin
  ZstdReadByte;
  Dec(N);
 End;
End;

Function ZstdReadSize(SizeBytes:Integer;Add256:Boolean):LongInt;
Var
 I:Integer;
 V,Mult:LongInt;
Begin
 V:=0;
 Mult:=1;
 For I:=1 to SizeBytes do Begin
  V:=V+Mult*ZstdReadByte;
  Mult:=Mult*256;
 End;
 If Add256 Then Inc(V,256);
 ZstdReadSize:=V;
End;

Function ZstdBitsMask(N:Integer):LongInt;
Begin
 If N<=0 Then ZstdBitsMask:=0
  Else If N>=31 Then ZstdBitsMask:=$7FFFFFFF
  Else ZstdBitsMask:=(LongInt(1)shl N)-1;
End;

Function ZstdHighBit(V:Integer):Integer;
Var
 R:Integer;
Begin
 R:=0;
 While V>1 do Begin
  V:=V shr 1;
  Inc(R);
 End;
 ZstdHighBit:=R;
End;

Function ZstdBufGet(Buf:PZstdSeqBuffer;Index:LongInt):Byte;Forward;
Procedure ZstdBufSet(Buf:PZstdSeqBuffer;Index:LongInt;Value:Byte);Forward;
Procedure ZstdBufAlloc(Var Buf:PZstdSeqBuffer);Forward;
Procedure ZstdBufFree(Var Buf:PZstdSeqBuffer);Forward;

Function ZstdFSEReadNCount(Var NCount;MaxSymbol,MaxTableLog:Integer;
 Var TableLog:Integer;Var HeaderSize:Integer):Integer;
Type
 TNCount=Array[0..ZstdFSEMaxSymbols]of Integer;
Var
 Count:^TNCount;
 BitStream:LongInt;
 BitCount,ByteCount,CharNum,Remaining,Threshold,NBBits,MaxV,Value:Integer;
 Previous0:Boolean;
 B:Byte;

 Procedure NeedBits(N:Integer);
 Begin
  While BitCount<N do Begin
   B:=ZstdReadByte;
   BitStream:=BitStream or(LongInt(B)shl BitCount);
   Inc(BitCount,8);
   Inc(ByteCount);
  End;
 End;

Begin
 Count:=@NCount;
 For CharNum:=0 to ZstdFSEMaxSymbols do Count^[CharNum]:=0;
 B:=ZstdReadByte;
 BitStream:=B;
 BitCount:=8;
 ByteCount:=1;
 TableLog:=(B and 15)+5;
 If(TableLog<5)or(TableLog>MaxTableLog)Then Begin
  WriteLn('TableLog FSE Zstandard invalide.');
  Halt(1);
 End;
 BitStream:=BitStream shr 4;
 Dec(BitCount,4);
 Remaining:=(1 shl TableLog)+1;
 Threshold:=1 shl TableLog;
 NBBits:=TableLog+1;
 CharNum:=0;
 Previous0:=False;
 While(CharNum<=MaxSymbol)and(Remaining>1)do Begin
  If Previous0 Then Begin
   NeedBits(2);
   While(BitStream and 3)=3 do Begin
    Inc(CharNum,3);
    BitStream:=BitStream shr 2;
    Dec(BitCount,2);
    NeedBits(2);
   End;
   Inc(CharNum,Integer(BitStream and 3));
   BitStream:=BitStream shr 2;
   Dec(BitCount,2);
   If CharNum>MaxSymbol Then Begin
    WriteLn('RLE FSE Zstandard invalide.');
    Halt(1);
   End;
   Previous0:=False;
  End;
  MaxV:=(Threshold shl 1)-1-Remaining;
  NeedBits(NBBits);
  Value:=Integer(BitStream and(Threshold-1));
  If Value<MaxV Then Begin
   BitStream:=BitStream shr(NBBits-1);
   Dec(BitCount,NBBits-1);
  End
   Else
  Begin
   Value:=Integer(BitStream and((Threshold shl 1)-1));
   If Value>=Threshold Then Dec(Value,MaxV);
   BitStream:=BitStream shr NBBits;
   Dec(BitCount,NBBits);
  End;
  Dec(Value);
  Count^[CharNum]:=Value;
  If Value<0 Then Dec(Remaining)
             Else Dec(Remaining,Value);
  Previous0:=Value=0;
  Inc(CharNum);
  While(Threshold>Remaining)do Begin
   Dec(NBBits);
   Threshold:=Threshold shr 1;
  End;
 End;
 If Remaining<>1 Then Begin
  WriteLn('Distribution FSE Zstandard invalide.');
  Halt(1);
 End;
 HeaderSize:=ByteCount;
 ZstdFSEReadNCount:=CharNum-1;
End;

Function ZstdFSEReadNCountBuf(Buf:PZstdSeqBuffer;Size:LongInt;
 Var NCount;MaxSymbol,MaxTableLog:Integer;
 Var TableLog:Integer;Var HeaderSize:Integer):Integer;
Type
 TNCount=Array[0..ZstdFSEMaxSymbols]of Integer;
Var
 Count:^TNCount;
 BitStream:LongInt;
 BitCount,ByteCount,CharNum,Remaining,Threshold,NBBits,MaxV,Value:Integer;
 Previous0:Boolean;
 B:Byte;

 Function ReadB:Byte;
 Begin
  If ByteCount>=Size Then Begin
   WriteLn('En-tete FSE Zstandard tronque.');
   Halt(1);
  End;
  ReadB:=ZstdBufGet(Buf,ByteCount);
  Inc(ByteCount);
 End;

 Procedure NeedBits(N:Integer);
 Begin
  While BitCount<N do Begin
   B:=ReadB;
   BitStream:=BitStream or(LongInt(B)shl BitCount);
   Inc(BitCount,8);
  End;
 End;

Begin
 Count:=@NCount;
 For CharNum:=0 to ZstdFSEMaxSymbols do Count^[CharNum]:=0;
 ByteCount:=0;
 B:=ReadB;
 BitStream:=B;
 BitCount:=8;
 TableLog:=(B and 15)+5;
 If(TableLog<5)or(TableLog>MaxTableLog)Then Begin
  WriteLn('TableLog FSE Zstandard invalide.');
  Halt(1);
 End;
 BitStream:=BitStream shr 4;
 Dec(BitCount,4);
 Remaining:=(1 shl TableLog)+1;
 Threshold:=1 shl TableLog;
 NBBits:=TableLog+1;
 CharNum:=0;
 Previous0:=False;
 While(CharNum<=MaxSymbol)and(Remaining>1)do Begin
  If Previous0 Then Begin
   NeedBits(2);
   While(BitStream and 3)=3 do Begin
    Inc(CharNum,3);
    BitStream:=BitStream shr 2;
    Dec(BitCount,2);
    NeedBits(2);
   End;
   Inc(CharNum,Integer(BitStream and 3));
   BitStream:=BitStream shr 2;
   Dec(BitCount,2);
   If CharNum>MaxSymbol Then Begin
    WriteLn('RLE FSE Zstandard invalide.');
    Halt(1);
   End;
   Previous0:=False;
  End;
  MaxV:=(Threshold shl 1)-1-Remaining;
  NeedBits(NBBits);
  Value:=Integer(BitStream and(Threshold-1));
  If Value<MaxV Then Begin
   BitStream:=BitStream shr(NBBits-1);
   Dec(BitCount,NBBits-1);
  End
   Else
  Begin
   Value:=Integer(BitStream and((Threshold shl 1)-1));
   If Value>=Threshold Then Dec(Value,MaxV);
   BitStream:=BitStream shr NBBits;
   Dec(BitCount,NBBits);
  End;
  Dec(Value);
  Count^[CharNum]:=Value;
  If Value<0 Then Dec(Remaining)
             Else Dec(Remaining,Value);
  Previous0:=Value=0;
  Inc(CharNum);
  While(Threshold>Remaining)do Begin
   Dec(NBBits);
   Threshold:=Threshold shr 1;
  End;
 End;
 If Remaining<>1 Then Begin
  WriteLn('Distribution FSE Zstandard invalide.');
  Halt(1);
 End;
 HeaderSize:=ByteCount;
 ZstdFSEReadNCountBuf:=CharNum-1;
End;

Procedure ZstdFSEBuildTable(Var T:ZstdFSETable;Var NCount;MaxSymbol,TableLog:Integer);
Type
 TNCount=Array[0..ZstdFSEMaxSymbols]of Integer;
 TSymbols=Array[0..ZstdFSEMaxTableSize-1]of Integer;
 TNext=Array[0..ZstdFSEMaxSymbols]of Integer;
Var
 Count:^TNCount;
 TableSymbol:^TSymbols;
 SymbolNext:^TNext;
 TableSize,HighThreshold,TableMask,Step,Pos:Integer;
 Sym,I,N,NextState,NB:Integer;
Begin
 Count:=@NCount;
 GetMem(TableSymbol,SizeOf(TSymbols));
 GetMem(SymbolNext,SizeOf(TNext));
 If(TableSymbol=NIL)or(SymbolNext=NIL)Then Begin
  WriteLn('Memoire insuffisante pour table FSE Zstandard.');
  Halt(1);
 End;
 TableSize:=1 shl TableLog;
 T.TableLog:=TableLog;
 T.TableSize:=TableSize;
 T.FastMode:=True;
 HighThreshold:=TableSize-1;
 For Sym:=0 to MaxSymbol do Begin
  If Count^[Sym]=-1 Then Begin
   TableSymbol^[HighThreshold]:=Sym;
   Dec(HighThreshold);
   SymbolNext^[Sym]:=1;
  End
   Else Begin
   If Count^[Sym]>=TableSize div 2 Then T.FastMode:=False;
   SymbolNext^[Sym]:=Count^[Sym];
  End;
 End;
 TableMask:=TableSize-1;
 Step:=(TableSize shr 1)+(TableSize shr 3)+3;
 Pos:=0;
 For Sym:=0 to MaxSymbol do Begin
  N:=Count^[Sym];
  If N>0 Then For I:=1 to N do Begin
   TableSymbol^[Pos]:=Sym;
   Pos:=(Pos+Step)and TableMask;
   While Pos>HighThreshold do Pos:=(Pos+Step)and TableMask;
  End;
 End;
 If Pos<>0 Then Begin
  FreeMem(TableSymbol,SizeOf(TSymbols));
  FreeMem(SymbolNext,SizeOf(TNext));
  WriteLn('Construction FSE Zstandard invalide.');
  Halt(1);
 End;
 For I:=0 to TableSize-1 do Begin
  Sym:=TableSymbol^[I];
  NextState:=SymbolNext^[Sym];
  Inc(SymbolNext^[Sym]);
  NB:=TableLog-ZstdHighBit(NextState);
  T.Entry[I].Symbol:=Byte(Sym);
  T.Entry[I].Bits:=NB;
  T.Entry[I].NewState:=(NextState shl NB)-TableSize;
 End;
 FreeMem(TableSymbol,SizeOf(TSymbols));
 FreeMem(SymbolNext,SizeOf(TNext));
End;

Procedure ZstdFSESelfTest;
Var
 Count:Array[0..ZstdFSEMaxSymbols]of Integer;
 T:ZstdFSETable;
 I:Integer;
Begin
 For I:=0 to ZstdFSEMaxSymbols do Count[I]:=0;
 Count[0]:=1;
 Count[1]:=1;
 Count[2]:=1;
 Count[3]:=1;
 ZstdFSEBuildTable(T,Count,3,2);
 If(T.TableSize<>4)or(T.Entry[0].Bits>2)Then Begin
  WriteLn('Auto-test FSE Zstandard invalide.');
  Halt(1);
 End;
End;

Procedure ZstdHuffBuildTable(Var H:ZstdHuffTable;MaxSymbol:Integer);
Var
 Count:Array[0..ZstdHuffMaxBits]of Integer;
 Start:Array[0..ZstdHuffMaxBits]of Integer;
 Bits,Sym,Idx,TableLog,Sum,W,Next,Len,J:Integer;
Begin
 For Bits:=0 to ZstdHuffMaxBits do Count[Bits]:=0;
 Sum:=0;
 For Sym:=0 to MaxSymbol do Begin
  If H.Weight[Sym]>ZstdHuffMaxBits Then Begin
   WriteLn('Poids Huffman Zstandard invalide.');
   Halt(1);
  End;
  If H.Weight[Sym]>0 Then Inc(Sum,1 shl(H.Weight[Sym]-1));
 End;
 If Sum=0 Then Begin
  WriteLn('Table Huffman Zstandard vide.');
  Halt(1);
 End;
 TableLog:=ZstdHighBit(Sum);
 If(1 shl TableLog)<>Sum Then Begin
  WriteLn('Somme des poids Huffman Zstandard invalide.');
  Halt(1);
 End;
 If TableLog>11 Then Begin
  WriteLn('Table Huffman Zstandard trop grande.');
  Halt(1);
 End;
 H.TableLog:=TableLog;
 H.TableSize:=1 shl TableLog;
 H.MaxSymbol:=MaxSymbol;
 For Idx:=0 to ZstdHuffMaxTableSize-1 do Begin
  H.Entry[Idx].Symbol:=0;
  H.Entry[Idx].Bits:=0;
 End;
 For Sym:=0 to MaxSymbol do Begin
  W:=H.Weight[Sym];
  If W<>0 Then Inc(Count[W]);
 End;
 If(Count[1]<2)or((Count[1]and 1)<>0)Then Begin
  WriteLn('Poids Huffman Zstandard invalides.');
  Halt(1);
 End;
 Next:=0;
 For W:=1 to TableLog do Begin
  Start[W]:=Next;
  Inc(Next,Count[W]shl(W-1));
 End;
 For Sym:=0 to MaxSymbol do Begin
  W:=H.Weight[Sym];
  If W<>0 Then Begin
   Bits:=TableLog+1-W;
   If(Bits<1)or(Bits>ZstdHuffMaxBits)Then Begin
    WriteLn('Longueur Huffman Zstandard invalide.');
    Halt(1);
   End;
   Len:=1 shl(W-1);
   Idx:=Start[W];
   For J:=0 to Len-1 do Begin
    H.Entry[Idx].Symbol:=Byte(Sym);
    H.Entry[Idx].Bits:=Bits;
    Inc(Idx);
   End;
   Inc(Start[W],Len);
  End;
 End;
End;

Procedure ZstdHuffFinishWeights(Var H:ZstdHuffTable;NumWeights:Integer);
Var
 I,Sum,Full,Left,LastWeight,MaxSymbol:Integer;
Begin
 If(NumWeights<1)or(NumWeights>=ZstdHuffMaxSymbols)Then Begin
  WriteLn('Nombre de poids Huffman Zstandard invalide.');
  Halt(1);
 End;
 Sum:=0;
 For I:=0 to NumWeights-1 do Begin
  If H.Weight[I]>ZstdHuffMaxBits Then Begin
   WriteLn('Poids Huffman Zstandard invalide.');
   Halt(1);
  End;
  If H.Weight[I]<>0 Then Inc(Sum,1 shl(H.Weight[I]-1));
 End;
 If Sum=0 Then Begin
  WriteLn('Poids Huffman Zstandard vides.');
  Halt(1);
 End;
 Full:=1;
 While Full<Sum do Full:=Full shl 1;
 Left:=Full-Sum;
 If Left=0 Then Begin
  WriteLn('Poids final Huffman Zstandard invalide.');
  Halt(1);
 End;
 LastWeight:=0;
 While Left>1 do Begin
  If(Left and 1)<>0 Then Begin
   WriteLn('Poids final Huffman Zstandard invalide.');
   Halt(1);
  End;
  Left:=Left shr 1;
  Inc(LastWeight);
 End;
 Inc(LastWeight);
 H.Weight[NumWeights]:=LastWeight;
 MaxSymbol:=NumWeights;
 ZstdHuffBuildTable(H,MaxSymbol);
End;

Procedure ZstdHuffReadDirect(Var H:ZstdHuffTable;HeaderByte:Integer;
 Var HeaderSize:Integer);
Var
 NumWeights,I,B:Integer;
Begin
 NumWeights:=HeaderByte-127;
 If(NumWeights<1)or(NumWeights>ZstdHuffMaxSymbols-1)Then Begin
  WriteLn('En-tete Huffman Zstandard invalide.');
  Halt(1);
 End;
 For I:=0 to ZstdHuffMaxSymbols-1 do H.Weight[I]:=0;
 HeaderSize:=1+(NumWeights+1)div 2;
 For I:=0 to NumWeights-1 do Begin
  If(I and 1)=0 Then Begin
   B:=ZstdReadByte;
   H.Weight[I]:=(B shr 4)and 15;
   If I+1<NumWeights Then H.Weight[I+1]:=B and 15;
  End;
 End;
 ZstdHuffFinishWeights(H,NumWeights);
End;

Procedure ZstdHuffReadFSE(Var H:ZstdHuffTable;HeaderByte:Integer;
 Var HeaderSize:Integer);
Type
 TCount=Array[0..ZstdFSEMaxSymbols]of Integer;
Var
 Buf:PZstdSeqBuffer;
 Count:TCount;
 T:ZstdFSETable;
 TableLog,FSEHeaderSize,LastSym:Integer;
 I,State1,State2,NumWeights:Integer;
 Off,Start,Cnt:Integer;
 Bits:LongInt;

 Function RFetch(N:Integer):Boolean;
 Begin
  While Cnt<N do Begin
   If Off<=Start Then Begin
    RFetch:=False;
    Exit;
   End;
   Dec(Off);
   Bits:=(Bits shl 8)or ZstdBufGet(Buf,Off);
   Inc(Cnt,8);
  End;
  RFetch:=True;
 End;

 Function RVal(N:Integer):LongInt;
 Begin
  If N=0 Then Begin
   RVal:=0;
   Exit;
  End;
  If Not RFetch(N)Then Begin
   WriteLn('En-tete Huffman FSE Zstandard tronque.');
   Halt(1);
  End;
  Dec(Cnt,N);
  RVal:=UShiftRight(Bits,Cnt)and ZstdBitsMask(N);
 End;

 Procedure NextState(Var State:Integer);
 Var
  E:ZstdFSEEntry;
 Begin
  E:=T.Entry[State];
  State:=E.NewState+RVal(E.Bits);
 End;

Begin
 If(HeaderByte<=0)or(HeaderByte>127)Then Begin
  WriteLn('Taille en-tete Huffman FSE Zstandard invalide.');
  Halt(1);
 End;
 ZstdBufAlloc(Buf);
 If Buf=NIL Then Begin
  WriteLn('Memoire insuffisante pour en-tete Huffman Zstandard.');
  Halt(1);
 End;
 For I:=0 to HeaderByte-1 do ZstdBufSet(Buf,I,ZstdReadByte);
 LastSym:=ZstdFSEReadNCountBuf(Buf,HeaderByte,Count,255,6,
  TableLog,FSEHeaderSize);
 If LastSym>255 Then Begin
  ZstdBufFree(Buf);
  WriteLn('Table FSE Huffman Zstandard invalide.');
  Halt(1);
 End;
 ZstdFSEBuildTable(T,Count,LastSym,TableLog);
 If FSEHeaderSize>=HeaderByte Then Begin
  ZstdBufFree(Buf);
  WriteLn('Bitstream Huffman FSE Zstandard absent.');
  Halt(1);
 End;
 Start:=FSEHeaderSize;
 Off:=HeaderByte-1;
 Bits:=ZstdBufGet(Buf,Off);
 If Bits=0 Then Begin
  ZstdBufFree(Buf);
  WriteLn('Fin bitstream Huffman FSE Zstandard invalide.');
  Halt(1);
 End;
 Cnt:=ZstdHighBit(Integer(Bits));
 State1:=Integer(RVal(TableLog));
 State2:=Integer(RVal(TableLog));
 For I:=0 to ZstdHuffMaxSymbols-1 do H.Weight[I]:=0;
 NumWeights:=0;
 While True do Begin
  If Not RFetch(T.Entry[State1].Bits)Then Begin
   If NumWeights>=254 Then Begin
    ZstdBufFree(Buf);
    WriteLn('Trop de poids Huffman Zstandard.');
    Halt(1);
   End;
   H.Weight[NumWeights]:=T.Entry[State1].Symbol;
   H.Weight[NumWeights+1]:=T.Entry[State2].Symbol;
   Inc(NumWeights,2);
   Break;
  End;
  If NumWeights>=255 Then Begin
   ZstdBufFree(Buf);
   WriteLn('Trop de poids Huffman Zstandard.');
   Halt(1);
  End;
  H.Weight[NumWeights]:=T.Entry[State1].Symbol;
  Inc(NumWeights);
  NextState(State1);
  If Not RFetch(T.Entry[State2].Bits)Then Begin
   If NumWeights>=254 Then Begin
    ZstdBufFree(Buf);
    WriteLn('Trop de poids Huffman Zstandard.');
    Halt(1);
   End;
   H.Weight[NumWeights]:=T.Entry[State2].Symbol;
   H.Weight[NumWeights+1]:=T.Entry[State1].Symbol;
   Inc(NumWeights,2);
   Break;
  End;
  If NumWeights>=255 Then Begin
   ZstdBufFree(Buf);
   WriteLn('Trop de poids Huffman Zstandard.');
   Halt(1);
  End;
  H.Weight[NumWeights]:=T.Entry[State2].Symbol;
  Inc(NumWeights);
  NextState(State2);
 End;
 ZstdBufFree(Buf);
 HeaderSize:=1+HeaderByte;
 ZstdHuffFinishWeights(H,NumWeights);
End;

Procedure ZstdHuffReadTable(Var H:ZstdHuffTable;Var HeaderSize:Integer);
Var
 HeaderByte:Integer;
Begin
 HeaderByte:=ZstdReadByte;
 If HeaderByte>=128 Then ZstdHuffReadDirect(H,HeaderByte,HeaderSize)
  Else ZstdHuffReadFSE(H,HeaderByte,HeaderSize);
End;

Procedure ZstdHuffSelfTest;
Var
 H:ZstdHuffTable;
 I:Integer;
Begin
 For I:=0 to ZstdHuffMaxSymbols-1 do H.Weight[I]:=0;
 H.Weight[Ord('A')]:=1;
 H.Weight[Ord('B')]:=1;
 ZstdHuffBuildTable(H,Ord('B'));
 If(H.TableSize<>2)or(H.Entry[0].Bits=0)or(H.Entry[1].Bits=0)Then Begin
  WriteLn('Auto-test Huffman Zstandard invalide.');
  Halt(1);
 End;
End;

Procedure ZstdBuildDefaultSeqTables(Var S:ZstdSeqTables);
Const
 LLDef:Array[0..35]of Integer=(
  4,3,2,2,2,2,2,2,2,2,2,2,2,1,1,1,
  2,2,2,2,2,2,2,2,2,3,2,1,1,1,1,1,
  -1,-1,-1,-1);
 MLDef:Array[0..52]of Integer=(
  1,4,3,2,2,2,2,2,2,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,-1,-1,
  -1,-1,-1,-1,-1);
 OFDef:Array[0..28]of Integer=(
  1,1,1,1,1,1,2,2,2,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,-1,-1,-1,-1,-1);
Begin
 ZstdFSEBuildTable(S.LL,LLDef,35,6);
 ZstdFSEBuildTable(S.ML,MLDef,52,6);
 ZstdFSEBuildTable(S.OFs,OFDef,28,5);
 S.LLValid:=True;
 S.MLValid:=True;
 S.OFValid:=True;
 S.LLMode:=0;
 S.MLMode:=0;
 S.OFMode:=0;
End;

Function ZstdSeqReadNumber:LongInt;
Var
 B0,B1,B2:Integer;
Begin
 B0:=ZstdReadByte;
 If B0=0 Then ZstdSeqReadNumber:=0
  Else If B0<128 Then ZstdSeqReadNumber:=B0
  Else If B0<255 Then Begin
   B1:=ZstdReadByte;
   ZstdSeqReadNumber:=((B0-128)shl 8)+B1;
  End
  Else Begin
   B1:=ZstdReadByte;
   B2:=ZstdReadByte;
   ZstdSeqReadNumber:=B1+(B2 shl 8)+$7F00;
  End;
End;

Procedure ZstdSeqReadOneTable(Var Tab:ZstdFSETable;Var Mode:Integer;
 Var RLE:Byte;Var Valid:Boolean;MaxSymbol,MaxLog:Integer;Name:String);
Var
 Count:Array[0..ZstdFSEMaxSymbols]of Integer;
 TableLog,HeaderSize,LastSym:Integer;
Begin
 Case Mode of
  0:Begin
     { Default tables are installed before this routine is used. }
     Valid:=True;
    End;
  1:Begin
     RLE:=ZstdReadByte;
     Valid:=True;
    End;
  2:Begin
     LastSym:=ZstdFSEReadNCount(Count,MaxSymbol,MaxLog,TableLog,HeaderSize);
     If LastSym>MaxSymbol Then Begin
      WriteLn('Table FSE ',Name,' Zstandard invalide.');
      Halt(1);
     End;
     ZstdFSEBuildTable(Tab,Count,LastSym,TableLog);
     Valid:=True;
    End;
  3:Begin
     If Not Valid Then Begin
      WriteLn('Repeat_Mode FSE ',Name,' Zstandard sans table precedente.');
      Halt(1);
     End;
    End;
 Else
  WriteLn('Mode FSE ',Name,' Zstandard invalide.');
  Halt(1);
 End;
End;

Function ZstdBufGet(Buf:PZstdSeqBuffer;Index:LongInt):Byte;
Begin
 ZstdBufGet:=Buf^.Chunks[Index shr ZstdSeqChunkBits]^[Index and ZstdSeqChunkMask];
End;

Procedure ZstdBufSet(Buf:PZstdSeqBuffer;Index:LongInt;Value:Byte);
Begin
 Buf^.Chunks[Index shr ZstdSeqChunkBits]^[Index and ZstdSeqChunkMask]:=Value;
End;

Procedure ZstdBufAlloc(Var Buf:PZstdSeqBuffer);
Var
 I,J:Integer;
Begin
 New(Buf);
 If Buf=NIL Then Exit;
 For I:=0 to ZstdSeqNumChunks-1 do Buf^.Chunks[I]:=NIL;
 For I:=0 to ZstdSeqNumChunks-1 do Begin
  New(Buf^.Chunks[I]);
  If Buf^.Chunks[I]=NIL Then Begin
   For J:=0 to I-1 do Dispose(Buf^.Chunks[J]);
   Dispose(Buf);
   Buf:=NIL;
   Exit;
  End;
 End;
End;

Procedure ZstdBufFree(Var Buf:PZstdSeqBuffer);
Var
 I:Integer;
Begin
 If Buf=NIL Then Exit;
 For I:=0 to ZstdSeqNumChunks-1 do
  If Buf^.Chunks[I]<>NIL Then Dispose(Buf^.Chunks[I]);
 Dispose(Buf);
 Buf:=NIL;
End;

Function ZstdByteHighBit(V:Byte):Integer;
Var
 I:Integer;
Begin
 For I:=7 downto 0 do
  If(V and(1 shl I))<>0 Then Begin
   ZstdByteHighBit:=I;
   Exit;
  End;
 ZstdByteHighBit:=-1;
End;

Procedure ZstdRevReload(Var B:ZstdRevBitStream);
Var
 NB,I,Shift:LongInt;
Begin
 If B.BitCount>32 Then Begin
  WriteLn('Bitstream sequences Zstandard trop court.');
  Halt(1);
 End;
 If B.Pos>=B.Base+4 Then Begin
  B.Pos:=B.Pos-(B.BitCount div 8);
  B.BitCount:=B.BitCount and 7;
 End
  Else If B.Pos<>B.Base Then Begin
  NB:=B.BitCount div 8;
  If B.Pos-NB<B.Base Then NB:=B.Pos-B.Base;
  B.Pos:=B.Pos-NB;
  B.BitCount:=B.BitCount-(NB*8);
 End;
 B.Bits:=0;
 Shift:=0;
 For I:=B.Pos to B.Pos+3 do Begin
  If I<B.Base+B.Size Then B.Bits:=B.Bits or(LongInt(ZstdBufGet(B.Buf,I))shl Shift);
  Inc(Shift,8);
 End;
End;

Procedure ZstdRevInit(Var B:ZstdRevBitStream;Buf:PZstdSeqBuffer;Base,Size:LongInt);
Var
 Last:Byte;
 I,Shift:LongInt;
Begin
 If Size<=0 Then Begin
  WriteLn('Bitstream sequences Zstandard vide.');
  Halt(1);
 End;
 B.Buf:=Buf;
 B.Base:=Base;
 B.Size:=Size;
 Last:=ZstdBufGet(Buf,Base+Size-1);
 If Last=0 Then Begin
  WriteLn('Fin de bitstream Zstandard invalide.');
  Halt(1);
 End;
 If Size>=4 Then B.Pos:=Base+Size-4
            Else B.Pos:=Base;
 B.Bits:=0;
 Shift:=0;
 For I:=B.Pos to B.Pos+3 do Begin
  If I<Base+Size Then B.Bits:=B.Bits or(LongInt(ZstdBufGet(Buf,I))shl Shift);
  Inc(Shift,8);
 End;
 B.BitCount:=8-ZstdByteHighBit(Last);
 If Size<4 Then B.BitCount:=B.BitCount+(4-Size)*8;
End;

Function ZstdRevReadBits(Var B:ZstdRevBitStream;N:Integer):LongInt;
Var
 R,T:LongInt;
Begin
 If N=0 Then Begin
  ZstdRevReadBits:=0;
  Exit;
 End;
 If B.BitCount+N>32 Then Begin
  ZstdRevReload(B);
  If B.BitCount+N>32 Then Begin
   WriteLn('Bitstream sequences Zstandard trop court.');
   Halt(1);
  End;
 End;
 T:=B.Bits shl B.BitCount;
 R:=UShiftRight(T,32-N)and ZstdBitsMask(N);
 Inc(B.BitCount,N);
 If B.BitCount>=25 Then ZstdRevReload(B);
 ZstdRevReadBits:=R;
End;

Function ZstdPeekBits(Var B:ZstdRevBitStream;N:Integer):LongInt;
Var
 T:LongInt;
Begin
 If N=0 Then Begin
  ZstdPeekBits:=0;
  Exit;
 End;
 If B.BitCount+N>32 Then Begin
  ZstdRevReload(B);
  If B.BitCount+N>32 Then Begin
   WriteLn('Bitstream Huffman Zstandard trop court.');
   Halt(1);
  End;
 End;
 T:=B.Bits shl B.BitCount;
 ZstdPeekBits:=UShiftRight(T,32-N)and ZstdBitsMask(N);
End;

Procedure ZstdConsumeBits(Var B:ZstdRevBitStream;N:Integer);
Begin
 Inc(B.BitCount,N);
 If B.BitCount>=25 Then ZstdRevReload(B);
End;

Procedure ZstdHuffDecodeStream(Var H:ZstdHuffTable;StreamBuf:PZstdSeqBuffer;
 StreamBase,StreamSize:LongInt;LitBuf:PZstdSeqBuffer;Var LitPos:LongInt;
 NumLits:LongInt);
Var
 Off,Start,Cnt:LongInt;
 Bits,Idx:LongInt;
 I:LongInt;

 Function HFetch(N:Integer):Boolean;
 Begin
  While Cnt<N do Begin
   If Off<=Start Then Begin
    HFetch:=False;
    Exit;
   End;
   Dec(Off);
   Bits:=(Bits shl 8)or ZstdBufGet(StreamBuf,Off);
   Inc(Cnt,8);
  End;
  HFetch:=True;
 End;
Begin
 If NumLits<=0 Then Exit;
 If StreamSize<=0 Then Begin
  WriteLn('Bitstream Huffman Zstandard vide.');
  Halt(1);
 End;
 Off:=StreamBase+StreamSize-1;
 If StreamBase>0 Then Start:=StreamBase-1
                 Else Start:=StreamBase;
 Bits:=ZstdBufGet(StreamBuf,Off);
 If Bits=0 Then Begin
  WriteLn('Fin bitstream Huffman Zstandard invalide.');
  Halt(1);
 End;
 Cnt:=ZstdHighBit(Integer(Bits));
 For I:=1 to NumLits do Begin
  If Not HFetch(H.TableLog)Then Begin
   WriteLn('Bitstream Huffman Zstandard trop court.');
   Halt(1);
  End;
  Idx:=UShiftRight(Bits,Cnt-H.TableLog)and ZstdBitsMask(H.TableLog);
  ZstdBufSet(LitBuf,LitPos,H.Entry[Idx].Symbol);
  Inc(LitPos);
  Dec(Cnt,H.Entry[Idx].Bits);
 End;
End;

Function ZstdFSESymbol(Var T:ZstdFSETable;State:Integer):Byte;
Begin
 If(State<0)or(State>=T.TableSize)Then Begin
  WriteLn('Etat FSE Zstandard invalide.');
  Halt(1);
 End;
 ZstdFSESymbol:=T.Entry[State].Symbol;
End;

Procedure ZstdFSENextState(Var BS:ZstdRevBitStream;Var T:ZstdFSETable;
 Var State:Integer);
Var
 E:ZstdFSEEntry;
Begin
 E:=T.Entry[State];
 State:=E.NewState+ZstdRevReadBits(BS,E.Bits);
End;

Procedure ZstdLLCode(Code:Byte;Var Base:LongInt;Var Bits:Integer);
Const
 BaseTab:Array[16..35]of LongInt=(
  16,18,20,22,24,28,32,40,48,64,128,256,512,1024,
  2048,4096,8192,16384,32768,65536);
 BitsTab:Array[16..35]of Byte=(
  1,1,1,1,2,2,3,3,4,6,7,8,9,10,11,12,13,14,15,16);
Begin
 If Code<=15 Then Begin
  Base:=Code;
  Bits:=0;
 End
  Else If Code<=35 Then Begin
  Base:=BaseTab[Code];
  Bits:=BitsTab[Code];
 End
  Else
 Begin
  WriteLn('Code LL Zstandard invalide.');
  Halt(1);
 End;
End;

Procedure ZstdMLCode(Code:Byte;Var Base:LongInt;Var Bits:Integer);
Const
 BaseTab:Array[32..52]of LongInt=(
  35,37,39,41,43,47,51,59,67,83,99,131,259,515,
  1027,2051,4099,8195,16387,32771,65539);
 BitsTab:Array[32..52]of Byte=(
  1,1,1,1,2,2,3,3,4,4,5,7,8,9,10,11,12,13,14,15,16);
Begin
 If Code<=31 Then Begin
  Base:=Code+3;
  Bits:=0;
 End
  Else If Code<=52 Then Begin
  Base:=BaseTab[Code];
  Bits:=BitsTab[Code];
 End
  Else
 Begin
  WriteLn('Code ML Zstandard invalide.');
  Halt(1);
 End;
End;

Function ZstdResolveOffset(OffsetValue,LL:LongInt):LongInt;
Var
 Offset:LongInt;
Begin
 If OffsetValue>3 Then Begin
  Offset:=OffsetValue-3;
  ZstdRep3:=ZstdRep2;
  ZstdRep2:=ZstdRep1;
  ZstdRep1:=Offset;
 End
  Else If OffsetValue=1 Then Begin
  If LL=0 Then Begin
   Offset:=ZstdRep2;
   ZstdRep2:=ZstdRep1;
   ZstdRep1:=Offset;
  End
   Else Offset:=ZstdRep1;
 End
  Else If OffsetValue=2 Then Begin
  Offset:=ZstdRep2;
  ZstdRep2:=ZstdRep1;
  ZstdRep1:=Offset;
 End
  Else If OffsetValue=3 Then Begin
  If LL=0 Then Begin
   Offset:=ZstdRep1-1;
   ZstdRep3:=ZstdRep2;
   ZstdRep2:=ZstdRep1;
   ZstdRep1:=Offset;
  End
   Else Begin
   Offset:=ZstdRep3;
   ZstdRep3:=ZstdRep2;
   ZstdRep2:=ZstdRep1;
   ZstdRep1:=Offset;
  End;
 End
  Else
 Begin
  WriteLn('Offset Zstandard invalide.');
  Halt(1);
 End;
 If Offset<=0 Then Begin
  WriteLn('Repeat offset Zstandard invalide.');
  Halt(1);
 End;
 ZstdResolveOffset:=Offset;
End;

Procedure ZstdCopyMatch(Offset,ML:LongInt);
Var
 I:LongInt;
 B:Byte;
Begin
 If Offset>OutSize Then Begin
  WriteLn('Reference LZ77 Zstandard invalide.');
  Halt(1);
 End;
 For I:=1 to ML do Begin
  B:=GetWindowByte(WinPos-Offset);
  PutOutByte(B);
 End;
End;

Procedure ZstdExecuteSequence(LL,OffsetValue,ML:LongInt;
 LitBuf:PZstdSeqBuffer;Var LitPos:LongInt;LitSize:LongInt);
Var
 I,Offset:LongInt;
Begin
 If LitBuf=NIL Then Exit;
 If LitPos+LL>LitSize Then Begin
  WriteLn('Litteraux Zstandard insuffisants.');
  Halt(1);
 End;
 For I:=1 to LL do Begin
  PutOutByte(ZstdBufGet(LitBuf,LitPos));
  Inc(LitPos);
 End;
 Offset:=ZstdResolveOffset(OffsetValue,LL);
 ZstdCopyMatch(Offset,ML);
End;

Procedure ZstdSeqDecodeCodes(Var S:ZstdSeqTables;Buf:PZstdSeqBuffer;
 Size,NumSeq:LongInt;LitBuf:PZstdSeqBuffer;LitSize:LongInt;DoExecute:Boolean);
Var
 BS:ZstdRevBitStream;
 LLState,OFState,MLState:Integer;
 I,LL,ML,OffsetValue,LitPos:LongInt;
 Base:LongInt;
 ExtraBits:Integer;
 LLC,OMC,MLC:Byte;
Begin
 If NumSeq=0 Then Exit;
 ZstdRevInit(BS,Buf,0,Size);
 If S.LLMode=1 Then LLState:=0 Else LLState:=ZstdRevReadBits(BS,S.LL.TableLog);
 If S.OFMode=1 Then OFState:=0 Else OFState:=ZstdRevReadBits(BS,S.OFs.TableLog);
 If S.MLMode=1 Then MLState:=0 Else MLState:=ZstdRevReadBits(BS,S.ML.TableLog);
 LitPos:=0;
 For I:=1 to NumSeq do Begin
  If S.LLMode=1 Then LLC:=S.LLRLE Else LLC:=ZstdFSESymbol(S.LL,LLState);
  If S.OFMode=1 Then OMC:=S.OFRLE Else OMC:=ZstdFSESymbol(S.OFs,OFState);
  If S.MLMode=1 Then MLC:=S.MLRLE Else MLC:=ZstdFSESymbol(S.ML,MLState);
  If OMC>30 Then Begin
   WriteLn('Code offset Zstandard trop grand.');
   Halt(1);
  End;
  OffsetValue:=(LongInt(1)shl OMC)+ZstdRevReadBits(BS,OMC);
  ZstdMLCode(MLC,Base,ExtraBits);
  ML:=Base+ZstdRevReadBits(BS,ExtraBits);
  ZstdLLCode(LLC,Base,ExtraBits);
  LL:=Base+ZstdRevReadBits(BS,ExtraBits);
  If DoExecute Then ZstdExecuteSequence(LL,OffsetValue,ML,LitBuf,LitPos,LitSize)
               Else ZstdResolveOffset(OffsetValue,LL);
  If I<NumSeq Then Begin
   If S.LLMode<>1 Then ZstdFSENextState(BS,S.LL,LLState);
   If S.MLMode<>1 Then ZstdFSENextState(BS,S.ML,MLState);
   If S.OFMode<>1 Then ZstdFSENextState(BS,S.OFs,OFState);
  End;
 End;
 If DoExecute and(LitBuf<>NIL)Then Begin
  While LitPos<LitSize do Begin
   PutOutByte(ZstdBufGet(LitBuf,LitPos));
   Inc(LitPos);
  End;
 End;
End;

Procedure ZstdReadLiteralsSection(LitBuf:PZstdSeqBuffer;Var LitSize:LongInt;
 Var H:ZstdHuffTable;Var HValid:Boolean;Var BytesRead:LongInt);
Var
 H0,H1,H2,H3,H4:Integer;
 LitType,SizeFormat,NumStreams,HeaderSize:Integer;
 RegenSize,CompSize,Bytes,StartCount:LongInt;
 LitPos,I:LongInt;
 RleByte:Byte;
 StreamBuf:PZstdSeqBuffer;
 J1,J2,J3:Integer;
 Sz1,Sz2,Sz3,Sz4:LongInt;
 Off1,Off2,Off3,Off4:LongInt;
 Seg:LongInt;
Begin
 StartCount:=CompLeft;
 H0:=ZstdReadByte;
 LitType:=H0 and 3;
 SizeFormat:=(H0 shr 2)and 3;
 If(LitType=0)or(LitType=1)Then Begin
  Case SizeFormat of
   0,2:RegenSize:=H0 shr 3;
   1:Begin
      H1:=ZstdReadByte;
      RegenSize:=LongInt(H0 shr 4)or(LongInt(H1)shl 4);
     End;
   3:Begin
      H1:=ZstdReadByte;
      H2:=ZstdReadByte;
      RegenSize:=LongInt(H0 shr 4)or(LongInt(H1)shl 4)or(LongInt(H2)shl 12);
     End;
  End;
  If RegenSize>ZstdSeqMaxBlockSize Then Begin
   WriteLn('Litteraux Zstandard trop volumineux.');
   Halt(1);
  End;
  LitSize:=RegenSize;
  If LitType=0 Then Begin
   For I:=0 to RegenSize-1 do ZstdBufSet(LitBuf,I,ZstdReadByte);
  End
   Else
  Begin
   RleByte:=ZstdReadByte;
   For I:=0 to RegenSize-1 do ZstdBufSet(LitBuf,I,RleByte);
  End;
  BytesRead:=StartCount-CompLeft;
  Exit;
 End;
 { LitType in [2,3]: compressed/treeless Huffman }
 Case SizeFormat of
  0:Begin
     NumStreams:=1;
     H1:=ZstdReadByte;
     H2:=ZstdReadByte;
     RegenSize:=LongInt(H0 shr 4)or(LongInt(H1 and $3F)shl 4);
     CompSize:=LongInt(H1 shr 6)or(LongInt(H2)shl 2);
    End;
  1:Begin
     NumStreams:=4;
     H1:=ZstdReadByte;
     H2:=ZstdReadByte;
     RegenSize:=LongInt(H0 shr 4)or(LongInt(H1 and $3F)shl 4);
     CompSize:=LongInt(H1 shr 6)or(LongInt(H2)shl 2);
    End;
  2:Begin
     NumStreams:=4;
     H1:=ZstdReadByte;
     H2:=ZstdReadByte;
     H3:=ZstdReadByte;
     RegenSize:=LongInt(H0 shr 4)or(LongInt(H1)shl 4)or(LongInt(H2 and $3)shl 12);
     CompSize:=LongInt(H2 shr 2)or(LongInt(H3)shl 6);
    End;
  3:Begin
     NumStreams:=4;
     H1:=ZstdReadByte;
     H2:=ZstdReadByte;
     H3:=ZstdReadByte;
     H4:=ZstdReadByte;
     RegenSize:=LongInt(H0 shr 4)or(LongInt(H1)shl 4)or(LongInt(H2 and $3F)shl 12);
     CompSize:=LongInt(H2 shr 6)or(LongInt(H3)shl 2)or(LongInt(H4)shl 10);
    End;
 End;
 If RegenSize>ZstdSeqMaxBlockSize Then Begin
  WriteLn('Litteraux Zstandard trop volumineux.');
  Halt(1);
 End;
 If CompSize>ZstdSeqMaxBlockSize Then Begin
  WriteLn('Flux litteraux Zstandard trop volumineux.');
  Halt(1);
 End;
 LitSize:=RegenSize;
 If LitType=2 Then Begin
  ZstdHuffReadTable(H,HeaderSize);
  HValid:=True;
  Bytes:=CompSize-HeaderSize;
 End
  Else
 Begin
  If Not HValid Then Begin
   WriteLn('Litteraux treeless Zstandard sans table Huffman.');
   Halt(1);
  End;
  Bytes:=CompSize;
 End;
 If Bytes<=0 Then Begin
  WriteLn('Taille flux Huffman Zstandard invalide.');
  Halt(1);
 End;
 ZstdBufAlloc(StreamBuf);
 If StreamBuf=NIL Then Begin
  WriteLn('Memoire insuffisante pour litteraux Zstandard.');
  Halt(1);
 End;
 LitPos:=0;
 If NumStreams=1 Then Begin
  For I:=0 to Bytes-1 do ZstdBufSet(StreamBuf,I,ZstdReadByte);
  ZstdHuffDecodeStream(H,StreamBuf,0,Bytes,LitBuf,LitPos,RegenSize);
 End
  Else
 Begin
  If Bytes<6 Then Begin
   WriteLn('Table de saut Huffman Zstandard invalide.');
   ZstdBufFree(StreamBuf);
   Halt(1);
  End;
  J1:=ZstdReadByte;J1:=J1 or(Integer(ZstdReadByte)shl 8);
  J2:=ZstdReadByte;J2:=J2 or(Integer(ZstdReadByte)shl 8);
  J3:=ZstdReadByte;J3:=J3 or(Integer(ZstdReadByte)shl 8);
  Sz1:=J1;Sz2:=J2;Sz3:=J3;
  Sz4:=Bytes-6-Sz1-Sz2-Sz3;
  If Sz4<=0 Then Begin
   WriteLn('Taille flux 4 Huffman Zstandard invalide.');
   ZstdBufFree(StreamBuf);
   Halt(1);
  End;
  ZstdBufSet(StreamBuf,0,Byte(J1 and $FF));
  ZstdBufSet(StreamBuf,1,Byte((J1 shr 8)and $FF));
  ZstdBufSet(StreamBuf,2,Byte(J2 and $FF));
  ZstdBufSet(StreamBuf,3,Byte((J2 shr 8)and $FF));
  ZstdBufSet(StreamBuf,4,Byte(J3 and $FF));
  ZstdBufSet(StreamBuf,5,Byte((J3 shr 8)and $FF));
  Off1:=6;Off2:=Off1+Sz1;Off3:=Off2+Sz2;Off4:=Off3+Sz3;
  For I:=6 to Bytes-1 do ZstdBufSet(StreamBuf,I,ZstdReadByte);
  Seg:=(RegenSize+3)div 4;
  ZstdHuffDecodeStream(H,StreamBuf,Off1,Sz1,LitBuf,LitPos,Seg);
  ZstdHuffDecodeStream(H,StreamBuf,Off2,Sz2,LitBuf,LitPos,Seg);
  ZstdHuffDecodeStream(H,StreamBuf,Off3,Sz3,LitBuf,LitPos,Seg);
  ZstdHuffDecodeStream(H,StreamBuf,Off4,Sz4,LitBuf,LitPos,RegenSize-3*Seg);
 End;
 ZstdBufFree(StreamBuf);
 If LitPos<>RegenSize Then Begin
  WriteLn('Decodage litteraux Zstandard incomplet.');
  Halt(1);
 End;
 BytesRead:=StartCount-CompLeft;
End;

Procedure ZstdReadSequencesAndExecute(BlockSize,LitConsumed:LongInt;
 Var S:ZstdSeqTables;LitBuf:PZstdSeqBuffer;LitSize:LongInt);
Var
 NumSeq,BitstreamSize,I,LitPos:LongInt;
 StartCount,HdrConsumed:LongInt;
 Modes:Integer;
 Buf:PZstdSeqBuffer;
Begin
 StartCount:=CompLeft;
 NumSeq:=ZstdSeqReadNumber;
 If NumSeq=0 Then Begin
  LitPos:=0;
  While LitPos<LitSize do Begin
   PutOutByte(ZstdBufGet(LitBuf,LitPos));
   Inc(LitPos);
  End;
  HdrConsumed:=StartCount-CompLeft;
  If LitConsumed+HdrConsumed<>BlockSize Then Begin
   WriteLn('Taille bloc Zstandard incoherente.');
   Halt(1);
  End;
  Exit;
 End;
 Modes:=ZstdReadByte;
 If(Modes and 3)<>0 Then Begin
  WriteLn('Modes sequences Zstandard invalides.');
  Halt(1);
 End;
 S.LLMode:=(Modes shr 6)and 3;
 S.OFMode:=(Modes shr 4)and 3;
 S.MLMode:=(Modes shr 2)and 3;
 ZstdSeqReadOneTable(S.LL,S.LLMode,S.LLRLE,S.LLValid,35,9,'LL');
 ZstdSeqReadOneTable(S.OFs,S.OFMode,S.OFRLE,S.OFValid,31,8,'OF');
 ZstdSeqReadOneTable(S.ML,S.MLMode,S.MLRLE,S.MLValid,52,9,'ML');
 HdrConsumed:=StartCount-CompLeft;
 BitstreamSize:=BlockSize-LitConsumed-HdrConsumed;
 If(BitstreamSize<=0)or(BitstreamSize>ZstdSeqMaxBlockSize)Then Begin
  WriteLn('Taille bitstream sequences Zstandard invalide.');
  Halt(1);
 End;
 ZstdBufAlloc(Buf);
 If Buf=NIL Then Begin
  WriteLn('Memoire insuffisante pour sequences Zstandard.');
  Halt(1);
 End;
 For I:=0 to BitstreamSize-1 do ZstdBufSet(Buf,I,ZstdReadByte);
 ZstdSeqDecodeCodes(S,Buf,BitstreamSize,NumSeq,LitBuf,LitSize,True);
 ZstdBufFree(Buf);
End;

Procedure InflateZstdFrame;
Var
 Desc,DictFlag,FCSFlag,BlockType:Integer;
 Header:LongInt;
 SingleSegment,ChecksumFlag,LastBlock:Boolean;
 DictSize,FCSSize:Integer;
 BlockSize,I,LitSize,LitConsumed:LongInt;
 B:Byte;
 LitBuf:PZstdSeqBuffer;
 Huff:ZstdHuffTable;
 HuffValid:Boolean;
 Seq:ZstdSeqTables;
Begin
 ZstdRep1:=1;
 ZstdRep2:=4;
 ZstdRep3:=8;
 HuffValid:=False;
 ZstdBuildDefaultSeqTables(Seq);
 ZstdBufAlloc(LitBuf);
 If LitBuf=NIL Then Begin
  WriteLn('Memoire insuffisante pour bloc Zstandard.');
  Halt(1);
 End;
 Desc:=ZstdReadByte;
 DictFlag:=Desc and 3;
 ChecksumFlag:=(Desc and 4)<>0;
 If(Desc and 8)<>0 Then Begin
  WriteLn('En-tete Zstandard reserve invalide.');
  Halt(1);
 End;
 SingleSegment:=(Desc and 32)<>0;
 FCSFlag:=(Desc shr 6)and 3;
 If Not SingleSegment Then ZstdReadByte;
 Case DictFlag of
  0:DictSize:=0;
  1:DictSize:=1;
  2:DictSize:=2;
  3:DictSize:=4;
 Else
  DictSize:=0;
 End;
 ZstdSkip(DictSize);
 If FCSFlag=0 Then Begin
  If SingleSegment Then FCSSize:=1 Else FCSSize:=0;
 End
  Else If FCSFlag=1 Then FCSSize:=2
  Else If FCSFlag=2 Then FCSSize:=4
  Else FCSSize:=8;
 If FCSSize=2 Then ZstdReadSize(FCSSize,True)
              Else ZstdReadSize(FCSSize,False);
 Repeat
  Header:=ZstdReadByte;
  Header:=Header or(Integer(ZstdReadByte)shl 8);
  Header:=Header or(Integer(ZstdReadByte)shl 16);
  LastBlock:=(Header and 1)<>0;
  BlockType:=(Header shr 1)and 3;
  BlockSize:=Header shr 3;
  Case BlockType of
   0:Begin
      For I:=1 to BlockSize do PutOutByte(ZstdReadByte);
     End;
   1:Begin
      B:=ZstdReadByte;
      For I:=1 to BlockSize do PutOutByte(B);
     End;
   2:Begin
      LitSize:=0;
      LitConsumed:=0;
      ZstdReadLiteralsSection(LitBuf,LitSize,Huff,HuffValid,LitConsumed);
      ZstdReadSequencesAndExecute(BlockSize,LitConsumed,Seq,LitBuf,LitSize);
     End;
  Else
   ZstdBufFree(LitBuf);
   WriteLn('Bloc Zstandard reserve invalide.');
   Halt(1);
  End;
 Until LastBlock;
 If ChecksumFlag Then ZstdSkip(4);
 ZstdBufFree(LitBuf);
End;

Procedure InflateZstd;
Var
 Magic:LongInt;
 Size:LongInt;
Begin
 InitWindow(False);
 Repeat
  Magic:=ZstdReadDWordLE;
  If(Magic and $FFFFFFF0)=LongInt($184D2A50)Then Begin
   Size:=ZstdReadDWordLE;
   ZstdSkip(Size);
  End
   Else If Magic=LongInt($FD2FB528)Then Begin
   InflateZstdFrame;
  End
   Else
  Begin
   WriteLn('Signature Zstandard invalide.');
   Halt(1);
  End;
 Until(OutSize>=UncompSize)or(CompLeft<=0);
End;

Procedure BZAllocTT(Limit:LongInt);
Var
 I,Need:Integer;
Begin
 BZBlockLimit:=Limit;
 Need:=(Limit+BZChunkSize-1)div BZChunkSize;
 If Need>BZMaxChunks Then Begin
  WriteLn('Bloc BZIP2 trop grand.');
  Halt(1);
 End;
 For I:=0 to BZMaxChunks-1 do BZTT[I]:=NIL;
 For I:=0 to BZMaxChunks-1 do BZByte[I]:=NIL;
 For I:=0 to Need-1 do Begin
  GetMem(BZTT[I],SizeOf(TBZTTChunk));
  GetMem(BZByte[I],SizeOf(TBZByteChunk));
  If(BZTT[I]=NIL)or(BZByte[I]=NIL)Then Begin
   WriteLn('Memoire insuffisante pour BZIP2.');
   Halt(1);
  End;
 End;
End;

Procedure BZFreeTT;
Var
 I:Integer;
Begin
 For I:=0 to BZMaxChunks-1 do If BZTT[I]<>NIL Then Begin
  FreeMem(BZTT[I],SizeOf(TBZTTChunk));
  BZTT[I]:=NIL;
 End;
 For I:=0 to BZMaxChunks-1 do If BZByte[I]<>NIL Then Begin
  FreeMem(BZByte[I],SizeOf(TBZByteChunk));
  BZByte[I]:=NIL;
 End;
End;

Procedure BZSetTT(Pos,Value:LongInt);
Var
 C,O:Integer;
Begin
 If(Pos<0)or(Pos>=BZBlockLimit)Then Begin
  BZFreeTT;
  WriteLn('Index BZIP2 invalide.');
  Halt(1);
 End;
 C:=Pos div BZChunkSize;
 O:=Pos mod BZChunkSize;
 BZTT[C]^[O]:=Value;
End;

Function BZGetTT(Pos:LongInt):LongInt;
Var
 C,O:Integer;
Begin
 If(Pos<0)or(Pos>=BZBlockLimit)Then Begin
  BZFreeTT;
  WriteLn('Index BZIP2 invalide.');
  Halt(1);
 End;
 C:=Pos div BZChunkSize;
 O:=Pos mod BZChunkSize;
 BZGetTT:=BZTT[C]^[O];
End;

Procedure BZSetByte(Pos:LongInt;B:Byte);
Var
 C,O:Integer;
Begin
 If(Pos<0)or(Pos>=BZBlockLimit)Then Begin
  BZFreeTT;
  WriteLn('Index BZIP2 invalide.');
  Halt(1);
 End;
 C:=Pos div BZChunkSize;
 O:=Pos mod BZChunkSize;
 BZByte[C]^[O]:=B;
End;

Function BZGetByte(Pos:LongInt):Byte;
Var
 C,O:Integer;
Begin
 If(Pos<0)or(Pos>=BZBlockLimit)Then Begin
  BZFreeTT;
  WriteLn('Index BZIP2 invalide.');
  Halt(1);
 End;
 C:=Pos div BZChunkSize;
 O:=Pos mod BZChunkSize;
 BZGetByte:=BZByte[C]^[O];
End;

Function BZReadBit:Integer;
Begin
 If BZBitCount=0 Then Begin
  BZBitBuf:=ReadCompByte;
  BZBitCount:=8;
 End;
 Dec(BZBitCount);
 BZReadBit:=(BZBitBuf shr BZBitCount)and 1;
End;

Function BZReadBits(N:Integer):LongInt;
Var
 I:Integer;
 V:LongInt;
Begin
 V:=0;
 For I:=1 to N do V:=(V shl 1)or BZReadBit;
 BZReadBits:=V;
End;

Function BZReadByte:Byte;
Begin
 BZReadByte:=Byte(BZReadBits(8));
End;

Function BZReadMagic:String;
Var
 I:Integer;
 S:String;
Begin
 S:='';
 For I:=1 to 6 do S:=S+Chr(BZReadByte);
 BZReadMagic:=S;
End;

Procedure BZBuildHuffman(Var H:BZHuffman;Var Lengths;N:Integer);
Type
 TLengths=Array[0..BZMaxAlphaSize-1]of Byte;
Var
 L:^TLengths;
 Count:Array[0..BZMaxAlphaSize]of Integer;
 NextCode:Array[0..BZMaxAlphaSize]of LongInt;
 I,Bits:Integer;
 Code:LongInt;
Begin
 L:=@Lengths;
 H.MinLen:=99;
 H.MaxLen:=0;
 For I:=0 to BZMaxAlphaSize-1 do Begin
  H.Len[I]:=0;
  H.Code[I]:=0;
 End;
 For I:=0 to BZMaxAlphaSize do Count[I]:=0;
 For I:=0 to N-1 do Begin
  H.Len[I]:=L^[I];
  If H.Len[I]>0 Then Begin
   Inc(Count[H.Len[I]]);
   If H.Len[I]<H.MinLen Then H.MinLen:=H.Len[I];
   If H.Len[I]>H.MaxLen Then H.MaxLen:=H.Len[I];
  End;
 End;
 Code:=0;
 Count[0]:=0;
 For Bits:=1 to BZMaxAlphaSize do Begin
  Code:=(Code+Count[Bits-1])shl 1;
  NextCode[Bits]:=Code;
 End;
 For I:=0 to N-1 do Begin
  Bits:=H.Len[I];
  If Bits<>0 Then Begin
   H.Code[I]:=NextCode[Bits];
   Inc(NextCode[Bits]);
  End;
 End;
End;

Function BZDecodeSymbol(Var H:BZHuffman;AlphaSize:Integer):Integer;
Var
 Len,Sym:Integer;
 Code:LongInt;
Begin
 Code:=0;
 For Len:=1 to H.MaxLen do Begin
  Code:=(Code shl 1)or BZReadBit;
  If Len>=H.MinLen Then Begin
   For Sym:=0 to AlphaSize-1 do
    If(H.Len[Sym]=Len)and(H.Code[Sym]=Code)Then Begin
     BZDecodeSymbol:=Sym;
     Exit;
    End;
  End;
 End;
 BZFreeTT;
 WriteLn('Code Huffman BZIP2 invalide.');
 Halt(1);
 BZDecodeSymbol:=0;
End;

Procedure BZMoveToFront(Var A;Pos:Integer);
Type
 TByteList=Array[0..255]of Byte;
Var
 L:^TByteList;
 V:Byte;
 I:Integer;
Begin
 L:=@A;
 V:=L^[Pos];
 For I:=Pos downto 1 do L^[I]:=L^[I-1];
 L^[0]:=V;
End;

Procedure BZPutBlockByte(B:Byte;Var NBlock:LongInt;Var Count);
Type
 TCounts=Array[0..255]of LongInt;
Var
 C:^TCounts;
Begin
 C:=@Count;
 If NBlock>=BZBlockLimit Then Begin
  BZFreeTT;
  WriteLn('Bloc BZIP2 trop long.');
  Halt(1);
 End;
 BZSetByte(NBlock,B);
 Inc(C^[B]);
 Inc(NBlock);
End;

Procedure BZDecodeBlock(BlockSize:Integer);
Type
 TBool16=Array[0..15]of Boolean;
 TInUse=Array[0..255]of Boolean;
 TByteList=Array[0..255]of Byte;
 TSelectors=Array[0..BZMaxSelectors-1]of Byte;
 TGroups=Array[0..BZMaxGroups-1]of BZHuffman;
 TLengths=Array[0..BZMaxAlphaSize-1]of Byte;
 TCounts=Array[0..255]of LongInt;
Var
 Magic:String;
 InUse16:TBool16;
 InUse:TInUse;
 SeqToUnseq,MTF:TByteList;
 Selectors:TSelectors;
 Groups:TGroups;
 Lengths:TLengths;
 Counts,Cftab:TCounts;
 BlockCRC,NBlock,OrigPtr,TPos,V:LongInt;
 Randomized:Boolean;
 I,J,K,AlphaSize,NInUse,NGroups,NSelectors,Sel,Sym:Integer;
 CurrLen,RepCount,RunPower,GroupNo,GroupPos,EOB:Integer;
 Ch,LastCh:Integer;
 SameCount:Integer;
 NeedRepeat:Boolean;

 Procedure EmitByte(B:Byte);
 Var
  R:Integer;
Begin
  If NeedRepeat Then Begin
   For R:=1 to B do PutOutByte(Byte(LastCh));
   NeedRepeat:=False;
   SameCount:=0;
   LastCh:=-1;
   Exit;
  End;
  PutOutByte(B);
  If LastCh=B Then Inc(SameCount)
  Else Begin
   LastCh:=B;
   SameCount:=1;
  End;
  If SameCount=4 Then NeedRepeat:=True;
 End;

Begin
 Magic:=BZReadMagic;
 If Magic=#$17#$72#$45#$38#$50#$90 Then Begin
  BZReadBits(32);
  Exit;
 End;
 If Magic<>#$31#$41#$59#$26#$53#$59 Then Begin
  BZFreeTT;
  WriteLn('Bloc BZIP2 invalide.');
  Halt(1);
 End;
 BlockCRC:=BZReadBits(32);
 If BlockCRC=0 Then Begin End;
 Randomized:=BZReadBit<>0;
 If Randomized Then Begin
  BZFreeTT;
  WriteLn('BZIP2 randomise non supporte.');
  Halt(1);
 End;
 OrigPtr:=BZReadBits(24);
 For I:=0 to 15 do InUse16[I]:=BZReadBit<>0;
 For I:=0 to 255 do InUse[I]:=False;
 For I:=0 to 15 do If InUse16[I] Then
  For J:=0 to 15 do InUse[I*16+J]:=BZReadBit<>0;
 NInUse:=0;
 For I:=0 to 255 do If InUse[I] Then Begin
  SeqToUnseq[NInUse]:=I;
  Inc(NInUse);
 End;
 AlphaSize:=NInUse+2;
 EOB:=NInUse+1;
 NGroups:=BZReadBits(3);
 NSelectors:=BZReadBits(15);
 If(NGroups<2)or(NGroups>BZMaxGroups)or
   (NSelectors<1)or(NSelectors>BZMaxSelectors)Then Begin
  BZFreeTT;
  WriteLn('Selecteurs BZIP2 invalides.');
  Halt(1);
 End;
 For I:=0 to NGroups-1 do MTF[I]:=I;
 For I:=0 to NSelectors-1 do Begin
  J:=0;
  While BZReadBit<>0 do Inc(J);
  If J>=NGroups Then Begin
   BZFreeTT;
   WriteLn('Selecteur BZIP2 invalide.');
   Halt(1);
  End;
  Selectors[I]:=MTF[J];
  BZMoveToFront(MTF,J);
 End;
 For I:=0 to NGroups-1 do Begin
  CurrLen:=BZReadBits(5);
  For J:=0 to AlphaSize-1 do Begin
   While BZReadBit<>0 do Begin
    If BZReadBit=0 Then Inc(CurrLen)
                   Else Dec(CurrLen);
    If(CurrLen<1)or(CurrLen>23)Then Begin
     BZFreeTT;
     WriteLn('Longueur Huffman BZIP2 invalide.');
     Halt(1);
    End;
   End;
   Lengths[J]:=CurrLen;
  End;
  BZBuildHuffman(Groups[I],Lengths,AlphaSize);
 End;
 For I:=0 to 255 do Begin
  MTF[I]:=I;
  Counts[I]:=0;
  Cftab[I]:=0;
 End;
 NBlock:=0;
 GroupNo:=-1;
 GroupPos:=0;
 Sel:=0;
 RepCount:=0;
 RunPower:=1;
 Repeat
  If GroupPos=0 Then Begin
   Inc(GroupNo);
   If GroupNo>=NSelectors Then Begin
    BZFreeTT;
    WriteLn('Flux BZIP2 trop long.');
    Halt(1);
   End;
   Sel:=Selectors[GroupNo];
   GroupPos:=BZGroupSize;
  End;
  Dec(GroupPos);
  Sym:=BZDecodeSymbol(Groups[Sel],AlphaSize);
  If(Sym=0)or(Sym=1)Then Begin
   RepCount:=0;
   RunPower:=1;
   Repeat
    If Sym=0 Then Inc(RepCount,RunPower)
             Else Inc(RepCount,RunPower*2);
    RunPower:=RunPower*2;
    If GroupPos=0 Then Begin
     Inc(GroupNo);
     If GroupNo>=NSelectors Then Begin
      BZFreeTT;
      WriteLn('Flux BZIP2 trop long.');
      Halt(1);
     End;
     Sel:=Selectors[GroupNo];
     GroupPos:=BZGroupSize;
    End;
    Dec(GroupPos);
    Sym:=BZDecodeSymbol(Groups[Sel],AlphaSize);
   Until(Sym<>0)and(Sym<>1);
   Ch:=SeqToUnseq[MTF[0]];
   For K:=1 to RepCount do BZPutBlockByte(Ch,NBlock,Counts);
  End;
  If(Sym<>EOB)Then Begin
   J:=Sym-1;
   If(J<0)or(J>=NInUse)Then Begin
    BZFreeTT;
    WriteLn('Symbole BZIP2 invalide.');
    Halt(1);
   End;
   Ch:=SeqToUnseq[MTF[J]];
   BZPutBlockByte(Ch,NBlock,Counts);
   BZMoveToFront(MTF,J);
  End;
 Until Sym=EOB;
 If(OrigPtr<0)or(OrigPtr>=NBlock)Then Begin
  BZFreeTT;
  WriteLn('OrigPtr BZIP2 invalide.');
  Halt(1);
 End;
 Cftab[0]:=0;
 For I:=1 to 255 do Cftab[I]:=Cftab[I-1]+Counts[I-1];
 For I:=0 to NBlock-1 do Begin
  Ch:=BZGetByte(I);
  V:=Cftab[Ch];
  BZSetTT(V,I);
  Inc(Cftab[Ch]);
 End;
 TPos:=OrigPtr;
 LastCh:=-1;
 SameCount:=0;
 NeedRepeat:=False;
 For I:=1 to NBlock do Begin
  TPos:=BZGetTT(TPos);
  Ch:=BZGetByte(TPos);
  EmitByte(Byte(Ch));
 End;
 If NeedRepeat Then Begin
  BZFreeTT;
  WriteLn('Fin de bloc BZIP2 invalide.');
  Halt(1);
 End;
 BZDecodeBlock(BlockSize);
End;

Procedure InflateBZip2;
Var
 B1,B2,B3,Level:Byte;
Begin
 InitWindow(False);
 BZBitBuf:=0;
 BZBitCount:=0;
 B1:=BZReadByte;
 B2:=BZReadByte;
 B3:=BZReadByte;
 If(B1<>Ord('B'))or(B2<>Ord('Z'))or(B3<>Ord('h'))Then Begin
  WriteLn('En-tete BZIP2 invalide.');
  Halt(1);
 End;
 Level:=BZReadByte;
 If(Level<Ord('1'))or(Level>Ord('9'))Then Begin
  WriteLn('Taille de bloc BZIP2 invalide.');
  Halt(1);
 End;
 BZAllocTT((Level-Ord('0'))*100000);
 BZDecodeBlock(Level-Ord('0'));
 BZFreeTT;
End;

Procedure ReadImplodeTree(Var H:Huffman;Symbols:Integer);
Var
 Lengths:Array[0..MaxSymbols-1]of Byte;
 I,J,N,B,L,R,Posi:Integer;
Begin
 For I:=0 to MaxSymbols-1 do Lengths[I]:=0;
 N:=ReadCompByte+1;
 Posi:=0;
 For I:=1 to N do Begin
  B:=ReadCompByte;
  L:=(B and 15)+1;
  R:=((B shr 4)and 15)+1;
  For J:=1 to R do Begin
   If Posi>=Symbols Then Begin
    WriteLn('Arbre Implode invalide.');
    Halt(1);
   End;
   Lengths[Posi]:=L;
   Inc(Posi);
  End;
 End;
 If Posi<>Symbols Then Begin
  WriteLn('Arbre Implode incomplet.');
  Halt(1);
 End;
 BuildHuffmanInvert(H,Lengths,Symbols);
End;

Procedure Explode(Flags:Integer);
Var
 Lit,LenTree,DistTree:Huffman;
 HasLit,LargeWin:Boolean;
 DistBits,MinLen,Token,Sym,Len,Dist,Low,I,WinRead:Integer;
 B:Byte;
Begin
 BitBuf:=0;
 BitCount:=0;
 InitWindow(False);
 LargeWin:=(Flags and 2)<>0;
 HasLit:=(Flags and 4)<>0;
 DistBits:=6;
 If LargeWin Then DistBits:=7;
 MinLen:=2;
 If HasLit Then MinLen:=3;
 If HasLit Then ReadImplodeTree(Lit,256);
 ReadImplodeTree(LenTree,64);
 ReadImplodeTree(DistTree,64);
 While OutSize<UncompSize do Begin
  Token:=ReadBit;
  If Token<>0 Then Begin
   If HasLit Then B:=Byte(DecodeSymbol(Lit))
             Else B:=Byte(ReadBits(8));
   PutOutByte(B);
  End
   Else
  Begin
   Low:=ReadBits(DistBits);
   Sym:=DecodeSymbol(DistTree);
   Dist:=(Sym shl DistBits)+Low+1;
   Sym:=DecodeSymbol(LenTree);
   Len:=Sym+MinLen;
   If Sym=63 Then Inc(Len,ReadBits(8));
   If(OutSize+Len>UncompSize)or(Dist>OutSize)Then Begin
    WriteLn('Reference Implode invalide.');
    Halt(1);
   End;
   For I:=1 to Len do Begin
    WinRead:=(WinPos-Dist)and $7FFF;
    B:=GetWindowByte(WinRead);
    PutOutByte(B);
   End;
  End;
 End;
 AlignByte;
End;

Procedure ShrinkInit;
Var
 I:Integer;
Begin
 If ShrinkPrefix=NIL Then GetMem(ShrinkPrefix,SizeOf(TShrinkIntArray));
 If ShrinkSuffix=NIL Then GetMem(ShrinkSuffix,SizeOf(TShrinkByteArray));
 If ShrinkActive=NIL Then GetMem(ShrinkActive,SizeOf(TShrinkBoolArray));
 If ShrinkStack=NIL Then GetMem(ShrinkStack,SizeOf(TShrinkByteArray));
 If(ShrinkPrefix=NIL)or(ShrinkSuffix=NIL)or
   (ShrinkActive=NIL)or(ShrinkStack=NIL)Then Begin
  WriteLn('Memoire insuffisante pour Shrink.');
  Halt(1);
 End;
 For I:=0 to ShrinkMaxCode do Begin
  ShrinkPrefix^[I]:=-1;
  ShrinkSuffix^[I]:=0;
  ShrinkActive^[I]:=False;
 End;
 For I:=0 to 255 do Begin
  ShrinkSuffix^[I]:=I;
  ShrinkActive^[I]:=True;
 End;
 ShrinkActive^[256]:=False;
End;

Procedure ShrinkDone;
Begin
 If ShrinkPrefix<>NIL Then Begin
  FreeMem(ShrinkPrefix,SizeOf(TShrinkIntArray));
  ShrinkPrefix:=NIL;
 End;
 If ShrinkSuffix<>NIL Then Begin
  FreeMem(ShrinkSuffix,SizeOf(TShrinkByteArray));
  ShrinkSuffix:=NIL;
 End;
 If ShrinkActive<>NIL Then Begin
  FreeMem(ShrinkActive,SizeOf(TShrinkBoolArray));
  ShrinkActive:=NIL;
 End;
 If ShrinkStack<>NIL Then Begin
  FreeMem(ShrinkStack,SizeOf(TShrinkByteArray));
  ShrinkStack:=NIL;
 End;
End;

Function ShrinkFindFree:Integer;
Var
 I:Integer;
Begin
 For I:=257 to ShrinkMaxCode do Begin
  If Not ShrinkActive^[I]Then Begin
   ShrinkFindFree:=I;
   Exit;
  End;
 End;
 ShrinkFindFree:=-1;
End;

Procedure ShrinkAdd(Prefix:Integer;Suffix:Byte);
Var
 N:Integer;
Begin
 N:=ShrinkFindFree;
 If N<0Then Exit;
 ShrinkPrefix^[N]:=Prefix;
 ShrinkSuffix^[N]:=Suffix;
 ShrinkActive^[N]:=True;
End;

Procedure ShrinkPartialClear;
Var
 I:Integer;
 Used:PShrinkBoolArray;
Begin
 GetMem(Used,SizeOf(TShrinkBoolArray));
 If Used=NIL Then Begin
  WriteLn('Memoire insuffisante pour Shrink.');
  Halt(1);
 End;
 For I:=0 to ShrinkMaxCode do Used^[I]:=False;
 For I:=257 to ShrinkMaxCode do Begin
  If ShrinkActive^[I]and(ShrinkPrefix^[I]>=257)Then
   Used^[ShrinkPrefix^[I]]:=True;
 End;
 For I:=257 to ShrinkMaxCode do Begin
  If ShrinkActive^[I]and(Not Used^[I])Then Begin
   ShrinkActive^[I]:=False;
   ShrinkPrefix^[I]:=-1;
   ShrinkSuffix^[I]:=0;
  End;
 End;
 FreeMem(Used,SizeOf(TShrinkBoolArray));
End;

Function ShrinkDecodeToStack(Code:Integer;Var FirstChar:Byte):Integer;
Var
 Top,Guard:Integer;
Begin
 Top:=0;
 Guard:=0;
 While Code>=0 do Begin
  If(Code>ShrinkMaxCode)or(Not ShrinkActive^[Code])Then Begin
   WriteLn('Code Shrink invalide.');
   Halt(1);
  End;
  ShrinkStack^[Top]:=ShrinkSuffix^[Code];
  Inc(Top);
  If Code<256Then Break;
  Code:=ShrinkPrefix^[Code];
  Inc(Guard);
  If Guard>ShrinkMaxCode Then Begin
   WriteLn('Boucle Shrink invalide.');
   Halt(1);
  End;
 End;
 FirstChar:=ShrinkStack^[Top-1];
 ShrinkDecodeToStack:=Top;
End;

Procedure ShrinkOutputStack(Top:Integer);
Var
 I:Integer;
Begin
 For I:=Top-1 downto 0 do PutOutByte(ShrinkStack^[I]);
End;

Function ShrinkReadCode(CodeSize:Integer):Integer;
Begin
 ShrinkReadCode:=ReadBits(CodeSize);
End;

Procedure UnShrink;
Var
 CodeSize,Code,OldCode,SubCode,Top:Integer;
 FirstChar,OldFirstChar:Byte;
Begin
 BitBuf:=0;
 BitCount:=0;
 InitWindow(False);
 ShrinkInit;
 CodeSize:=9;
 OldCode:=-1;
 OldFirstChar:=0;
 While OutSize<UncompSize do Begin
  Code:=ShrinkReadCode(CodeSize);
  If Code=256Then Begin
   SubCode:=ShrinkReadCode(CodeSize);
   If SubCode=1Then Begin
    If CodeSize<13Then Inc(CodeSize);
   End
    Else If SubCode=2Then ShrinkPartialClear
    Else Begin
     ShrinkDone;
     WriteLn('Commande Shrink inconnue.');
     Halt(1);
    End;
  End
   Else
  Begin
   If OldCode<0Then Begin
    Top:=ShrinkDecodeToStack(Code,FirstChar);
    ShrinkOutputStack(Top);
    OldCode:=Code;
    OldFirstChar:=FirstChar;
   End
    Else
   Begin
    If(Code<=ShrinkMaxCode)and(ShrinkActive^[Code])Then Begin
     Top:=ShrinkDecodeToStack(Code,FirstChar);
     ShrinkOutputStack(Top);
    End
     Else
    Begin
     Top:=ShrinkDecodeToStack(OldCode,FirstChar);
     ShrinkOutputStack(Top);
     PutOutByte(OldFirstChar);
     FirstChar:=OldFirstChar;
    End;
    ShrinkAdd(OldCode,FirstChar);
    OldCode:=Code;
    OldFirstChar:=FirstChar;
   End;
  End;
 End;
 ShrinkDone;
 AlignByte;
End;

Function FollowerBits(N:Integer):Integer;
Begin
 If N>16Then FollowerBits:=5
  Else If N>8Then FollowerBits:=4
  Else If N>4Then FollowerBits:=3
  Else If N>2Then FollowerBits:=2
  Else If N>0Then FollowerBits:=1
  Else FollowerBits:=0;
End;

Procedure ReduceInit;
Var
 I,J,N:Integer;
Begin
 If ReduceSize=NIL Then GetMem(ReduceSize,SizeOf(TFollowerSizeArray));
 If ReduceBits=NIL Then GetMem(ReduceBits,SizeOf(TFollowerSizeArray));
 If ReduceFollowers=NIL Then GetMem(ReduceFollowers,SizeOf(TFollowerArray));
 If(ReduceSize=NIL)or(ReduceBits=NIL)or(ReduceFollowers=NIL)Then Begin
  WriteLn('Memoire insuffisante pour Reduce.');
  Halt(1);
 End;
 For I:=0 to 255 do Begin
  ReduceSize^[I]:=0;
  ReduceBits^[I]:=0;
  For J:=0 to 31 do ReduceFollowers^[I,J]:=0;
 End;
 For I:=255 downto 0 do Begin
  N:=ReadBits(6);
  If N>32Then Begin
   WriteLn('Follower set Reduce invalide.');
   Halt(1);
  End;
  ReduceSize^[I]:=N;
  ReduceBits^[I]:=FollowerBits(N);
  For J:=0 to N-1 do ReduceFollowers^[I,J]:=ReadBits(8);
 End;
End;

Procedure ReduceDone;
Begin
 If ReduceSize<>NIL Then Begin
  FreeMem(ReduceSize,SizeOf(TFollowerSizeArray));
  ReduceSize:=NIL;
 End;
 If ReduceBits<>NIL Then Begin
  FreeMem(ReduceBits,SizeOf(TFollowerSizeArray));
  ReduceBits:=NIL;
 End;
 If ReduceFollowers<>NIL Then Begin
  FreeMem(ReduceFollowers,SizeOf(TFollowerArray));
  ReduceFollowers:=NIL;
 End;
End;

Function ReduceReadByte(Prev:Byte):Byte;
Var
 Idx:Integer;
Begin
 If ReduceSize^[Prev]=0 Then Begin
  ReduceReadByte:=ReadBits(8);
 End
  Else If ReadBit=1 Then Begin
  ReduceReadByte:=ReadBits(8);
 End
  Else
 Begin
  Idx:=ReadBits(ReduceBits^[Prev]);
  If Idx>=ReduceSize^[Prev]Then Begin
   ReduceDone;
   WriteLn('Index follower Reduce invalide.');
   Halt(1);
  End;
  ReduceReadByte:=ReduceFollowers^[Prev,Idx];
 End;
End;

Procedure UnReduce(Factor:Integer);
Var
 Prev,V,W,B:Byte;
 LenBits,LenMask,Len,Dist,I,WinRead:Integer;
Begin
 BitBuf:=0;
 BitCount:=0;
 InitWindow(False);
 ReduceInit;
 Prev:=0;
 LenBits:=8-Factor;
 LenMask:=(1 shl LenBits)-1;
 While OutSize<UncompSize do Begin
  B:=ReduceReadByte(Prev);
  Prev:=B;
 If B<>DLEByte Then Begin
   PutOutByte(B);
  End
   Else
  Begin
   V:=ReduceReadByte(Prev);
   Prev:=V;
   If V=0 Then PutOutByte(DLEByte)
    Else
   Begin
    Len:=V and LenMask;
    If Len=LenMask Then Begin
     B:=ReduceReadByte(Prev);
     Prev:=B;
     Inc(Len,B);
    End;
    Inc(Len,3);
    W:=ReduceReadByte(Prev);
    Prev:=W;
    Dist:=((V shr LenBits)*256)+W+1;
    If OutSize+Len>UncompSize Then Begin
     ReduceDone;
     WriteLn('Reference Reduce trop longue.');
     Halt(1);
    End;
    For I:=1 to Len do Begin
     If Dist>OutSize Then PutOutByte(0)
      Else
     Begin
      WinRead:=(WinPos-Dist)and $7FFF;
      PutOutByte(GetWindowByte(WinRead));
     End;
    End;
   End;
  End;
 End;
 ReduceDone;
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
  1:MethodName:='shrink';
  2,3,4,5:Begin
     Str(Method,S);
     MethodName:='reduce-'+S;
    End;
  6:MethodName:='implode';
  7:MethodName:='tokenize';
  8:MethodName:='deflate';
  9:MethodName:='deflate64';
  10:MethodName:='dcl-implode';
  12:MethodName:='bzip2';
  14:MethodName:='lzma';
  18:MethodName:='ibm-terse';
  19:MethodName:='ibm-lz77';
  93:MethodName:='zstandard';
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

Procedure PrepareZipCrypto(Flags:Integer;CRC:LongInt;Name:String);
Var
 I:Integer;
 B,CheckByte:Byte;
Begin
 ZipCryptActive:=False;
 If(Flags and 1)=0 Then Exit;
 If Password=''Then Begin
  WriteLn('Mot de passe requis pour ',Name);
  Halt(1);
 End;
 If(Flags and $40)<>0 Then Begin
  WriteLn('Chiffrement fort ZIP non supporte: ',Name);
  Halt(1);
 End;
 If CompLeft<12 Then Begin
  WriteLn('En-tete de chiffrement ZIP invalide: ',Name);
  Halt(1);
 End;
 ZipCryptInit(Password);
 ZipCryptActive:=True;
 CheckByte:=0;
 For I:=1 to 12 do Begin
  B:=ReadCompByte;
  If I=12 Then CheckByte:=B;
 End;
 If CheckByte<>Byte(UShiftRight(CRC,24)and $FF)Then Begin
  WriteLn('Mot de passe incorrect ou en-tete ZIP chiffre invalide: ',Name);
  Halt(1);
 End;
End;

Procedure ExtractArchive;
Var
 Sig:LongInt;
 Flags,Method,NameLen,ExtraLen,ZipTime,ZipDate:Integer;
 CRC,CompSize,ZipStamp,DiskStamp:LongInt;
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
  ZipTime:=ReadWordLE;
  ZipDate:=ReadWordLE;
  ZipStamp:=ZipDateTimeStamp(ZipTime,ZipDate);
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
     Else If FreshenMode and Existing and GetFileDateTimeStamp(OutName,DiskStamp)
       and(DiskStamp>=ZipStamp)Then Begin
     If Not QuietMode and Not VeryQuietMode Then MoreWriteLn('A jour '+OutName);
     SkipBytes(CompSize);
    End
     Else If UpdateMode and Existing and GetFileDateTimeStamp(OutName,DiskStamp)
       and(DiskStamp>=ZipStamp)Then Begin
     If Not QuietMode and Not VeryQuietMode Then MoreWriteLn('A jour '+OutName);
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
     CompLeft:=CompSize;
     ZipCryptActive:=False;
     ExpectedCRC:=CRC;
     OutCRC:=LongInt($FFFFFFFF);
     OutSize:=0;
     PrevOutByte:=-1;
     PrepareZipCrypto(Flags,CRC,Name);
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
     Case Method of
      0:Begin
         InitWindow(False);
         While CompLeft>0 do Begin
          B:=ReadCompByte;
          PutOutByte(B);
         End;
        End;
      1:UnShrink;
      2:UnReduce(1);
      3:UnReduce(2);
      4:UnReduce(3);
      5:UnReduce(4);
      6:Explode(Flags);
      7:Begin
         If OutputMode=0 Then Close(OutFile);
         WriteLn('Methode ZIP 7 tokenizing reservee/non documentee: ',Name);
         Halt(1);
        End;
      8:InflateDeflate;
      9:InflateDeflate64;
      10:Begin
          InflateDCLImplode;
         End;
      12:Begin
          InflateBZip2;
         End;
      14:Begin
          InflateLZMA;
         End;
      18:Begin
          InflateTerse;
         End;
      19:Begin
          If OutputMode=0 Then Close(OutFile);
          WriteLn('Methode ZIP 19 IBM LZ77 z Architecture/PFS non portable: ',Name);
          WriteLn('Cette methode depend du format CMPSC/dictionnaire IBM z/Architecture.');
          Halt(1);
         End;
      93:Begin
          InflateZstd;
         End;
     Else
      If OutputMode=0 Then Close(OutFile);
      WriteLn('Methode ZIP non supportee (',Method,') pour ',Name);
      Halt(1);
     End;
     OutCRC:=OutCRC xor LongInt($FFFFFFFF);
     If CompLeft>0 Then SkipBytes(CompLeft);
     If(OutSize<>UncompSize)or Not SameDWord(OutCRC,ExpectedCRC)Then Begin
      If OutputMode=0 Then Close(OutFile);
      WriteLn('Erreur CRC/taille pour ',Name);
      If Not VeryQuietMode Then
       WriteLn('  taille=',OutSize,'/',UncompSize,
        ' crc=',Hex8(OutCRC),'/',Hex8(ExpectedCRC));
      Halt(1);
     End;
     If OutputMode=0 Then Begin
      Close(OutFile);
      SetFileDateTimeStamp(OutName,ZipStamp);
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
 WriteLn(' -P mot    Mot de passe ZipCrypto classique');
 WriteLn(' -X -U -:  Options reconnues pour compatibilite');
 WriteLn;
 WriteLn('Supporte les methodes ZIP store (0), shrink (1), ',
        'reduce (2-5), implode (6), deflate (8), Deflate64 (9), ');
 WriteLn('DCL Implode (10), BZIP2 (12), LZMA (14), IBM TERSE (18), ',
        'Zstandard/ZSTD (93).');
 WriteLn('Methode 7 tokenizing reconnue, mais reservee/non documentee.');
 WriteLn('Methode 10 DCL Implode/old IBM TERSE supportee.');
 WriteLn('IBM TERSE (18) supporte les flux PACK/SPACK avec en-tete TERSE.');
 WriteLn('Methode 19 IBM LZ77 z Architecture/PFS reconnue, non portable.');
 WriteLn('Methode 93 Zstandard: blocs Raw/RLE et compresses Huffman/FSE/LZ77.');
 WriteLn('BZIP2 utilise la memoire de tas par blocs pour l''inversion BWT.');
 WriteLn('LZMA utilise un dictionnaire sur tas; lc+lp doit etre <= 4.');
 WriteLn('Note : -P supporte ZipCrypto classique, pas AES/WinZip ni chiffrement fort.');
 WriteLn('-X restaure peu d''attributs; -f/-u comparent les dates ZIP/DOS.');
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
 WindowLo:=NIL;
 WindowHi:=NIL;
 WindowMask:=$7FFF;
 ZipCryptActive:=False;
 ShrinkPrefix:=NIL;
 ShrinkSuffix:=NIL;
 ShrinkActive:=NIL;
 ShrinkStack:=NIL;
 ReduceSize:=NIL;
 ReduceBits:=NIL;
 ReduceFollowers:=NIL;
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
