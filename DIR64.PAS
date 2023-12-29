{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program DIR64;

{$A-}

Const
 SectorCount:Array[1..40] of Integer=(
  21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,
  19,19,19,19,19,19,19,
  18,18,18,18,18,18,
  17,17,17,17,17,
  17,17,17,17,17	{ Piste de 36 … 40 }
 );

 SectorOfs:Array[1..40] of Integer=(
  0,21,42,63,84,105,126,147,168,189,210,231,252,273,294,315,336,
  357,376,395,414,433,452,471,
  490,508,526,544,562,580,
  598,615,632,649,666,
  683,700,717,734,751	{ Piste de 36 … 40 }
 );

 KindName:array[0..15] of String[3]=(
  'DEL','SEQ','PRG','USR','REL','EL?','EQ?','RG?','SR?','EL?','L??',
  'Q??','G??','R??','L??','???'
 );

 Flag:Array[0..1] of Char=('*',' ');

Type
 tBAM=Record
  Track:Byte;
  Sector:Byte;
  Format:Byte;
  Pad0:Byte;
  FAT:Array[1..35,1..4] of byte; { Allocation de secteur }
  Name:Array[1..18] of char;
  ID:Array[1..2] of char;
  Pad1:Byte;
  Chars:Array[1..2] of Char;
  Pad2:Array[1..4] of Byte;
  Pad3:Array[1..85] of Byte;
 End;

  { Structure d'une entr‚e de r‚pertoire }
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
   { Padding:Array[1..2] of Byte; }
  NextTrack :byte;
  NextSector:byte;
  Entry:Array[0..7] of TDirEntry;
 End;

Function PadWordRight(Value:Word;Space:Byte):String;
Var
 S:String;
 I:Byte;
Begin
 Str(Value,S);
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadWordRight:=S;
End;

Function SectorOffset(Track,Sector:word):LongInt;Begin
 If(Track<1)or(Track>40)or(Sector<0)or(Sector>=SectorCount[Track])Then
  SectorOffset:=-1
 Else
  SectorOffset:=(SectorOfs[Track]+Sector) shl 8;
End;

Function ReadSector(Var Handle:File;Track,Sector:word; Var Data):Boolean;
Var
 Offset:LongInt;
 ByteReaded:Word;
Begin
 Offset:=SectorOffset(Track,Sector);
 {$I-}Seek(Handle,Offset);
 BlockRead(Handle,Data,256,ByteReaded);{$I+}
 ReadSector:=(Offset>=0)and(IOResult=0)and(ByteReaded=256);
End;

Var
 F:File;
 BAM:tBAM;
 DIR:TDirectory;
 I:Byte;
 E:Word;
 Q:Char;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('DIR64 : Cette commande permet d''afficher la liste des fichiers ',
                   'que contient une image disque de format .D64 du ',
                   'Commodore 64');
  WriteLn;
  WriteLn('Syntaxe : DIR64 fichier.D64');
  WriteLn;
  WriteLn('  fichier.D64   Ce paramŠtre permet d''indiquer le nom du fichier ',
                           'd''image disque.');
 End
  Else
 If ParamCount>0Then Begin
  {$I-}Assign(F,ParamStr(1));
  Reset(F,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de lire le fichier : ',ParamStr(1));
   Halt;
  End;
  ReadSector(f,18,0,BAM);
  For I:=1 to SizeOf(BAM.Name)do If BAM.Name[i]=' 'Then BAM.Name[i]:=' ';
  WriteLn('0 "',BAM.Name,'" ',BAM.ID,' ',BAM.Chars);
  Dir.NextTrack:=BAM.Track;
  Dir.NextSector:=BAM.Sector;
  While (Dir.NextTrack<>0)and(ReadSector(f,Dir.NextTrack,Dir.NextSector,Dir))do Begin
   For E:=0 to 7 do With Dir.Entry[e] do Begin
    Q:='"';
    For I:=1 to SizeOf(Name)do If Name[i]=' 'Then Begin
     Name[i]:=Q;
     Q:=' ';
    End;
    If Kind<>0 Then WriteLn(PadWordRight(Blocks,6),'"',Name,'  ',Flag[Kind shr 7],' ',KindName[Kind and 15]);
   End;
  End;
  e:=0;
  For i:=1 to 35 do e:=e+BAM.FAT[i,1];
  WriteLn(E,' BLOCKS FREE.');
  Close(F);
 End;
END.