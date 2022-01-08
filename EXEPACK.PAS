{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

{$S-,I-,R-}

Program ExePack;

Const
 MaxRWbufSize=$8000;
 FlagWord=$FFFF;
 OrigIPofs=3;
 ShowRLEeffect=TRUE;
 Threshold=4;
 MaxReloc=$3FFC;
 NewLoaderSize=82;
 NewLoader:Array[1..NewLoaderSize]of Byte=(
    {C'est un DUMP du fichier assembleur LOADER.ASM}
  $EB,$08,$00,$00,$00,$00,$00,$00,$00,$00,$2E,$8C,$1E,$06,$00,$2E,
  $8C,$06,$08,$00,$8C,$C3,$83,$C3,$10,$8C,$C8,$8E,$D8,$BE,$52,$00,
  $FC,$AD,$3D,$FF,$FF,$75,$0B,$AD,$3D,$FF,$FF,$74,$0C,$03,$C3,$8E,
  $C0,$AD,$8B,$F8,$26,$01,$1D,$EB,$E8,$2E,$8E,$06,$08,$00,$2E,$8E,
  $1E,$06,$00,$8B,$C3,$2E,$03,$06,$04,$00,$50,$2E,$A1,$02,$00,$50,
  $CB,$90);

Type
 ExeHeaderRec=Record
  Signature,LengthRem,LengthPages,NumReloc,HeaderSize:Word;
  MinHeap,MaxHeap,StackSeg,StackPtr,CheckSum,IpInit,CodeSeg:Word;
  RelocOfs,OverlayNum:Word;
 End;
 RelocRec=Record
  Offset,Segment:Word;
 End;
 RelocArray=Array[1..MaxReloc]of RelocRec;
 PackedTable=Array[1..$7FF0]of Word;
 ReadWriteBuffer=Array[1..MaxRWbufSize]of Byte;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do S[I]:=UpCase(S[I]);
 StrToUpper:=S;
End;

{Cette fonction recherche et retourne la posiution du s‚parateur
 d'extension dans un chemin r‚pertoire.}

Function HasExtension(Name:String;Var DotPos:Word):Boolean;
Var
 I:Word;
Begin
 DotPos:=0;
 For I:=Length(Name)downto 1do If(Name[I]='.')and(DotPos=0)Then DotPos:=I;
 HasExtension:=(DotPos>0)and(Pos('\',Copy(Name,DotPos+1,64))=0);
End;

Function ForceExtension(Name,Ext:String):String;
Var
 DotPos:Word;
Begin
 If HasExtension(Name,DotPos)Then ForceExtension:=Copy(Name,1,DotPos)+Ext
                             else ForceExtension:=Name+'.'+Ext;
End;

Function _BlockRead(Var Handle:File;Var Buffer;Size:Word):Boolean;
Var
 BytesRead:Word;
Begin
 BlockRead(Handle,Buffer,Size,BytesRead);
 _BlockRead:=(IoResult=0)and(BytesRead=Size)
End;

Function _BlockWrite(Var Handle:File;Var Buffer;Size:Word):Boolean;
Var
 BytesWritten:Word;
Begin
 BlockWrite(Handle,Buffer,Size,BytesWritten);
 _BlockWrite:=(IoResult=0)and(BytesWritten=Size)
End;

Procedure PackExe(ExeName,OutName:String);
Var
 ExeF,OutF:File;
 BytesRead,BytesWritten,RWbufSize,I,TableSize,TablePos,LastSeg,
 BlockSize,OldNumReloc,OldHeaderSize:Word;
 OldExeSize,ExeSize,RLEbytes:LongInt;
 LastByte:Byte;
 ExeHeader:ExeHeaderRec;
 RA:^RelocArray;
 PT:^PackedTable;
 RWbuf:^ReadWriteBuffer;

 Procedure SetTable(Var TA:PackedTable;Var TablePos:Word;Value:Word);Begin
  TA[TablePos]:=Value;Inc(TablePos)
 End;

Begin
 If StrToUpper(ExeName)=StrToUpper(OutName)Then Begin
  WriteLn('Fichiers d''entr‚e et de sortie diff‚rent');
  Halt(16);
 End;
 Assign(ExeF,ExeName);
 Reset(ExeF,1);
 If IoResult<>0Then Begin
  WriteLn(ExeName,' introuvable');
  Halt(15);
 End;
 If Not _BlockRead(ExeF,ExeHeader,SizeOf(ExeHeaderRec))Then Begin
  WriteLn('Erreur de lecture du fichier EXE');
  Halt(14);
 End;
 With ExeHeader do Begin
  If Signature<>$5A4DThen Begin
   WriteLn('Ce fichier n''est pas de format EXE standard');
   Halt(13);
  End;
  If NumReloc=0Then Begin
   WriteLn('Ne peut pas ˆtre compacter. Pas de fichier de sortie ‚crit');
   Halt(12);
  End;
  If(NumReloc>MaxReloc)Then Begin
   WriteLn('Nombre d''elements relog‚ excŠde la capacit‚ d''EXEPACK');
   Halt(11);
  End;
  GetMem(RA,NumReloc shl 2);
  If RA=NIL Then Begin
   WriteLn('M‚moire insuffisante');
   Halt(10);
  End;
  Seek(ExeF,RelocOfs);
  If Not _BlockRead(ExeF,RA^,NumReloc shl 2)Then Begin
   WriteLn('Erreur de lecture du fichier EXE');
   Halt(9);
  End;
  LastSeg:=$FFFF;TableSize:=0;
  For I:=1to(NumReloc)do With RA^[I]do Begin
   If(Segment<>LastSeg)Then Begin
    LastSeg:=Segment;
    Inc(TableSize,4);
   End;
   Inc(TableSize,2);
  End;
  Inc(TableSize,4);
  GetMem(PT,TableSize);
  If PT=NIL Then Begin
   WriteLn('M‚moire insuffisante');
   Halt(8);
  End;
  LastSeg:=$FFFF;TablePos:=1;
  For I:=1to(NumReloc)do With RA^[I]do Begin
   If(Segment<>LastSeg)Then Begin
    LastSeg:=Segment;
    SetTable(PT^,TablePos,FlagWord);
    SetTable(PT^,TablePos,Segment);
   End;
   SetTable(PT^,TablePos,Offset);
  End;
  For I:=1to 2do SetTable(PT^,TablePos,FlagWord);
  FreeMem(RA,NumReloc shl 2);
  RWbufSize:=MaxRWbufSize;
  GetMem(RWbuf,RWbufSize);
  If RWBuf=NIL Then Begin
   WriteLn('M‚moire insuffisante');
   Halt(7);
  End;
  OldNumReloc:=NumReloc;OldHeaderSize:=HeaderSize;
  If LengthRem=0Then OldExeSize:=LongInt(LengthPages)shl 9
                else OldExeSize:=(LongInt(LengthPages-1)shl 9)+LongInt(LengthRem);
  NumReloc:=0;HeaderSize:=(SizeOf(ExeHeaderRec)+15)shr 4;
  Move(IpInit,NewLoader[OrigIPofs],4);
  IpInit:=0;CodeSeg:=Succ(OldExeSize shr 4)-OldHeaderSize;
  ExeSize:=(LongInt(HeaderSize)+LongInt(CodeSeg))shl 4+
           LongInt(NewLoaderSize)+LongInt(TableSize);
  If(ExeSize>=OldExeSize)Then Begin
   WriteLn('Taille de compactage excŠde la taille original. Pas sortie ‚crite');
   Halt(6);
  End;
  If ExeSize and 511=0Then Begin;LengthPages:=ExeSize shr 9;LengthRem:=0;End
   else
  Begin
   LengthPages:=Succ(ExeSize shr 9);
   LengthRem:=ExeSize-LongInt(Pred(LongInt(LengthPages))shl 9);
  End;
  Assign(OutF,OutName);
  Rewrite(OutF,1);
  If IoResult<>0Then Begin
   WriteLn('Ne peut pas cr‚er ',OutName);
   Halt(5);
  End;
  If Not _BlockWrite(OutF,ExeHeader,HeaderSize shl 4)Then Begin
   WriteLn('Erreur d''‚criture du fichier EXE');
   Halt(4);
  End;
  Seek(ExeF,OldHeaderSize shl 4);
  LastByte:=0;BlockSize:=0;RLEbytes:=00;
  Repeat
   BlockRead(ExeF,RWbuf^,RWbufSize,BytesRead);
   If IoResult<>0Then Begin
    WriteLn('Erreur de lecture du fichier EXE');
    Halt(3);
   End;
   If BytesRead<>0Then Begin
    If Not _BlockWrite(OutF,RWbuf^,BytesRead)Then Begin
     WriteLn('Erreur d''‚criture du fichier EXE');
     Halt(2);
    End;
    If(ShowRLEeffect)Then For I:=1to(BytesRead)do If LastByte=RWbuf^[I]Then Inc(BlockSize)
     else
    Begin
     LastByte:=RWbuf^[I];
     If(BlockSize>Threshold)Then Inc(RLEbytes,BlockSize-Threshold);
     BlockSize:=0;
    End;
   End;
  Until BytesRead=0;
  If(ShowRLEeffect)and(BlockSize>Threshold)Then Inc(RLEbytes,BlockSize-Threshold);
  Seek(OutF,(LongInt(HeaderSize)+LongInt(CodeSeg))shl 4);
  If Not _BlockWrite(OutF,NewLoader,NewLoaderSize)Then Begin
   WriteLn('Erreur d''‚criture du fichier EXE');
   Halt(1);
  End;
  If Not _BlockWrite(OutF,PT^,TableSize)Then Begin
   WriteLn('Erreur d''‚criture du fichier EXE');
   Halt(1);
  End;
  If(ShowRLEeffect)Then WriteLn('AprŠs compression de l''entˆte du programme la longueur ‚conomis‚ est ',RLEbytes,' octets');
 End;
 FreeMem(PT,TableSize);
 FreeMem(RWbuf,RWbufSize);
 Close(ExeF);
 Close(OutF);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('EXEPACK: Ce programme permet de reduire la taille de l''entete EXE d''un programme 16 bits.');
  WriteLn;
  WriteLn('Syntaxe: EXEPACK AncienNomExe NouveauNomExe');
 End
  Else
 If ParamCount=2Then Begin
  PackExe(ForceExtension(ParamStr(1),'EXE'),ForceExtension(ParamStr(2),'EXE'));
 End
  Else
 WriteLn('Nombre de parametres invalide !');
END.