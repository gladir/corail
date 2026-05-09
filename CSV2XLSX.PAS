{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program CSV2XLSX(Input,Output);

{$A-}
{$R-}

Uses DOS;

Const
 MaxZipEntries=10;
 DeflateBufferSize=8192;
 MaxMatchLength=258;
 MaxMatchDistance=2048;

Type
 ZipEntry=Record
  Name:String;
  CRC:LongInt;
  Size:LongInt;
  CompressedSize:LongInt;
  Offset:LongInt;
 End;

Var
 SourceCSV:Text;
 TargetXLSX:File;
 ZipEntries:Array[1..MaxZipEntries]of ZipEntry;
 ZipCount:Integer;
 CurrCRC:LongInt;
 CurrSize,CurrCompressedSize:LongInt;
 CurrLine,CurrCell,FileName,TFileName:String;
 CurrColumn,CurrRow:Integer;
 DeflateBuffer:Array[1..DeflateBufferSize]of Byte;
 DeflateCount:Integer;
 BitBuffer:LongInt;
 BitCount:Integer;
 CRC32Table:Array[0..255]of LongInt;

Function Path2Ext(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2Ext:=E;
End;

Function LowByte(L:LongInt):Byte;
Begin
 LowByte:=Byte(L and $FF);
End;

Function UShiftRight(L:LongInt;N:Byte):LongInt;
Var
 I:Byte;
Begin
 For I:=1 to N do Begin
  L:=(L shr 1)and $7FFFFFFF;
 End;
 UShiftRight:=L;
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

Procedure UpdateCRC(B:Byte);
Begin
 CurrCRC:=UShiftRight(CurrCRC,8)xor CRC32Table[LowByte(CurrCRC xor B)];
 Inc(CurrSize);
End;

Procedure PutByte(B:Byte);
Begin
 BlockWrite(TargetXLSX,B,1);
End;

Procedure PutWord(W:LongInt);
Begin
 PutByte(Byte(W and $FF));
 PutByte(Byte(UShiftRight(W,8)and $FF));
End;

Procedure PutDWord(L:LongInt);
Begin
 PutByte(Byte(L and $FF));
 PutByte(Byte(UShiftRight(L,8)and $FF));
 PutByte(Byte(UShiftRight(L,16)and $FF));
 PutByte(Byte(UShiftRight(L,24)and $FF));
End;

Procedure PutRaw(S:String);
Var
 I:Integer;
 B:Byte;
Begin
 For I:=1 to Length(S)do Begin
  B:=Ord(S[I]);
  BlockWrite(TargetXLSX,B,1);
 End;
End;

Procedure PutDeflateByte(B:Byte);
Begin
 BlockWrite(TargetXLSX,B,1);
 Inc(CurrCompressedSize);
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

Procedure WriteBits(Value,Bits:Integer);
Begin
 BitBuffer:=BitBuffer or(LongInt(Value)shl BitCount);
 Inc(BitCount,Bits);
 While BitCount>=8 do Begin
  PutDeflateByte(Byte(BitBuffer and $FF));
  BitBuffer:=UShiftRight(BitBuffer,8);
  Dec(BitCount,8);
 End;
 If BitCount=0Then BitBuffer:=0
              Else BitBuffer:=BitBuffer and((1 shl BitCount)-1);
End;

Procedure FlushBits;
Begin
 If BitCount>0Then Begin
  PutDeflateByte(Byte(BitBuffer and $FF));
  BitBuffer:=0;
  BitCount:=0;
 End;
End;

Procedure WriteFixedSymbol(Symbol:Integer);
Var
 Code,Bits:Integer;
Begin
 If Symbol<=143Then Begin
  Code:=$30+Symbol;
  Bits:=8;
 End
  Else If Symbol<=255Then Begin
  Code:=$190+(Symbol-144);
  Bits:=9;
 End
  Else If Symbol<=279Then Begin
  Code:=Symbol-256;
  Bits:=7;
 End
  Else
 Begin
  Code:=$C0+(Symbol-280);
  Bits:=8;
 End;
 WriteBits(ReverseBits(Code,Bits),Bits);
End;

Procedure GetLengthCode(Len:Integer;Var Code,ExtraBits,ExtraValue:Integer);
Const
 LengthBase:Array[0..28]of Integer=(
  3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,
  35,43,51,59,67,83,99,115,131,163,195,227,258);
 LengthExtra:Array[0..28]of Integer=(
  0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,
  3,3,3,3,4,4,4,4,5,5,5,5,0);
Var
 I,MaxLen:Integer;
Begin
 For I:=0 to 28 do Begin
  If LengthExtra[I]=0Then MaxLen:=LengthBase[I]
                      Else MaxLen:=LengthBase[I]+(1 shl LengthExtra[I])-1;
  If Len<=MaxLen Then Begin
   Code:=257+I;
   ExtraBits:=LengthExtra[I];
   ExtraValue:=Len-LengthBase[I];
   Exit;
  End;
 End;
 Code:=285;
 ExtraBits:=0;
 ExtraValue:=0;
End;

Procedure GetDistanceCode(Dist:Integer;Var Code,ExtraBits,ExtraValue:Integer);
Const
 DistBase:Array[0..29]of Integer=(
  1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,
  193,257,385,513,769,1025,1537,2049,3073,4097,
  6145,8193,12289,16385,24577);
 DistExtra:Array[0..29]of Integer=(
  0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,
  6,7,7,8,8,9,9,10,10,11,11,12,12,13,13);
Var
 I,MaxDist:Integer;
Begin
 For I:=0 to 29 do Begin
  If DistExtra[I]=0Then MaxDist:=DistBase[I]
                    Else MaxDist:=DistBase[I]+(1 shl DistExtra[I])-1;
  If Dist<=MaxDist Then Begin
   Code:=I;
   ExtraBits:=DistExtra[I];
   ExtraValue:=Dist-DistBase[I];
   Exit;
  End;
 End;
 Code:=0;
 ExtraBits:=0;
 ExtraValue:=0;
End;

Procedure WriteLengthDistance(Len,Dist:Integer);
Var
 Code,ExtraBits,ExtraValue:Integer;
Begin
 GetLengthCode(Len,Code,ExtraBits,ExtraValue);
 WriteFixedSymbol(Code);
 If ExtraBits>0Then WriteBits(ExtraValue,ExtraBits);
 GetDistanceCode(Dist,Code,ExtraBits,ExtraValue);
 WriteBits(ReverseBits(Code,5),5);
 If ExtraBits>0Then WriteBits(ExtraValue,ExtraBits);
End;

Procedure FindMatch(Pos:Integer;Var BestLen,BestDist:Integer);
Var
 SearchStart,J,L,MaxLen:Integer;
Begin
 BestLen:=0;
 BestDist:=0;
 SearchStart:=Pos-MaxMatchDistance;
 If SearchStart<1 Then SearchStart:=1;
 MaxLen:=DeflateCount-Pos+1;
 If MaxLen>MaxMatchLength Then MaxLen:=MaxMatchLength;
 For J:=Pos-1 downto SearchStart do Begin
  If DeflateBuffer[J]=DeflateBuffer[Pos] Then Begin
   L:=0;
   While(L<MaxLen)and(L<Pos-J)and
        (DeflateBuffer[J+L]=DeflateBuffer[Pos+L])do Inc(L);
   If L>BestLen Then Begin
    BestLen:=L;
    BestDist:=Pos-J;
   End;
  End;
 End;
 If BestLen<3 Then Begin
  BestLen:=0;
  BestDist:=0;
 End;
End;

Procedure FlushDeflateBlock(FinalBlock:Boolean);
Var
 Pos,BestLen,BestDist:Integer;
Begin
 If(Not FinalBlock)and(DeflateCount=0) Then Exit;
 If FinalBlock Then WriteBits(1,1)
               Else WriteBits(0,1);
 WriteBits(1,2);
 Pos:=1;
 While Pos<=DeflateCount do Begin
  FindMatch(Pos,BestLen,BestDist);
  If BestLen>0 Then Begin
   WriteLengthDistance(BestLen,BestDist);
   Inc(Pos,BestLen);
  End
   Else
  Begin
   WriteFixedSymbol(DeflateBuffer[Pos]);
   Inc(Pos);
  End;
 End;
 WriteFixedSymbol(256);
 DeflateCount:=0;
 If FinalBlock Then FlushBits;
End;

Procedure AddDeflateByte(B:Byte);
Begin
 If DeflateCount>=DeflateBufferSize Then FlushDeflateBlock(False);
 Inc(DeflateCount);
 DeflateBuffer[DeflateCount]:=B;
End;

Procedure PutZipData(S:String);
Var
 I:Integer;
 B:Byte;
Begin
 For I:=1 to Length(S)do Begin
  B:=Ord(S[I]);
  UpdateCRC(B);
  AddDeflateByte(B);
 End;
End;

Procedure StartZipEntry(EntryName:String);
Begin
 Inc(ZipCount);
 ZipEntries[ZipCount].Name:=EntryName;
 ZipEntries[ZipCount].Offset:=FilePos(TargetXLSX);
 CurrCRC:=LongInt($FFFFFFFF);
 CurrSize:=0;
 CurrCompressedSize:=0;
 DeflateCount:=0;
 BitBuffer:=0;
 BitCount:=0;

 PutDWord($04034B50);
 PutWord(20);
 PutWord(0);
 PutWord(8);
 PutWord(0);
 PutWord(0);
 PutDWord(0);
 PutDWord(0);
 PutDWord(0);
 PutWord(Length(EntryName));
 PutWord(0);
 PutRaw(EntryName);
End;

Procedure FinishZipEntry;
Var
 EndOffset:LongInt;
Begin
 FlushDeflateBlock(True);
 CurrCRC:=CurrCRC xor LongInt($FFFFFFFF);
 ZipEntries[ZipCount].CRC:=CurrCRC;
 ZipEntries[ZipCount].Size:=CurrSize;
 ZipEntries[ZipCount].CompressedSize:=CurrCompressedSize;
 EndOffset:=FilePos(TargetXLSX);
 Seek(TargetXLSX,ZipEntries[ZipCount].Offset+14);
 PutDWord(CurrCRC);
 PutDWord(CurrCompressedSize);
 PutDWord(CurrSize);
 Seek(TargetXLSX,EndOffset);
End;

Procedure WriteCentralDirectory;
Var
 I:Integer;
 CentralOffset,CentralSize:LongInt;
Begin
 CentralOffset:=FilePos(TargetXLSX);
 For I:=1 to ZipCount do Begin
  PutDWord($02014B50);
  PutWord(20);
  PutWord(20);
  PutWord(0);
  PutWord(8);
  PutWord(0);
  PutWord(0);
  PutDWord(ZipEntries[I].CRC);
  PutDWord(ZipEntries[I].CompressedSize);
  PutDWord(ZipEntries[I].Size);
  PutWord(Length(ZipEntries[I].Name));
  PutWord(0);
  PutWord(0);
  PutWord(0);
  PutWord(0);
  PutDWord(0);
  PutDWord(ZipEntries[I].Offset);
  PutRaw(ZipEntries[I].Name);
 End;
 CentralSize:=FilePos(TargetXLSX)-CentralOffset;
 PutDWord($06054B50);
 PutWord(0);
 PutWord(0);
 PutWord(ZipCount);
 PutWord(ZipCount);
 PutDWord(CentralSize);
 PutDWord(CentralOffset);
  PutWord(0);
End;

Function Word2Hex(W:Integer):String;Forward;
Function OEM850ToUnicode(B:Byte):Integer;Forward;

Procedure WriteXmlEscaped(S:String);
Var
 I:Integer;
 B:Byte;
Begin
 For I:=1 to Length(S)do Begin
  B:=Ord(S[I]);
  If B>=128Then Begin
   PutZipData('&#x');
   PutZipData(Word2Hex(OEM850ToUnicode(B)));
   PutZipData(';');
  End
   Else
  Begin
   Case S[I] of
    '&':PutZipData('&amp;');
    '<':PutZipData('&lt;');
    '>':PutZipData('&gt;');
    '"':PutZipData('&quot;');
    '''':PutZipData('&apos;');
    #9:PutZipData('&#x0009;');
   Else
    If B>=32Then PutZipData(S[I]);
   End;
  End;
 End;
End;

Function ColumnName(C:Integer):String;
Var
 S:String;
 N,R:Integer;
Begin
 S:='';
 N:=C+1;
 While N>0 do Begin
  R:=(N-1)mod 26;
  S:=Chr(Ord('A')+R)+S;
  N:=(N-1)div 26;
 End;
 ColumnName:=S;
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

Function Word2Hex(W:Integer):String;
Var
 S:String;
Begin
 S:='';
 S:=S+HexDigit((W shr 12)and 15);
 S:=S+HexDigit((W shr 8)and 15);
 S:=S+HexDigit((W shr 4)and 15);
 S:=S+HexDigit(W and 15);
 Word2Hex:=S;
End;

Function OEM850ToUnicode(B:Byte):Integer;
Begin
 Case B of
  $80:OEM850ToUnicode:=$00C7; $81:OEM850ToUnicode:=$00FC;
  $82:OEM850ToUnicode:=$00E9; $83:OEM850ToUnicode:=$00E2;
  $84:OEM850ToUnicode:=$00E4; $85:OEM850ToUnicode:=$00E0;
  $86:OEM850ToUnicode:=$00E5; $87:OEM850ToUnicode:=$00E7;
  $88:OEM850ToUnicode:=$00EA; $89:OEM850ToUnicode:=$00EB;
  $8A:OEM850ToUnicode:=$00E8; $8B:OEM850ToUnicode:=$00EF;
  $8C:OEM850ToUnicode:=$00EE; $8D:OEM850ToUnicode:=$00EC;
  $8E:OEM850ToUnicode:=$00C4; $8F:OEM850ToUnicode:=$00C5;
  $90:OEM850ToUnicode:=$00C9; $91:OEM850ToUnicode:=$00E6;
  $92:OEM850ToUnicode:=$00C6; $93:OEM850ToUnicode:=$00F4;
  $94:OEM850ToUnicode:=$00F6; $95:OEM850ToUnicode:=$00F2;
  $96:OEM850ToUnicode:=$00FB; $97:OEM850ToUnicode:=$00F9;
  $98:OEM850ToUnicode:=$00FF; $99:OEM850ToUnicode:=$00D6;
  $9A:OEM850ToUnicode:=$00DC; $9B:OEM850ToUnicode:=$00F8;
  $9C:OEM850ToUnicode:=$00A3; $9D:OEM850ToUnicode:=$00D8;
  $9E:OEM850ToUnicode:=$00D7; $9F:OEM850ToUnicode:=$0192;
  $A0:OEM850ToUnicode:=$00E1; $A1:OEM850ToUnicode:=$00ED;
  $A2:OEM850ToUnicode:=$00F3; $A3:OEM850ToUnicode:=$00FA;
  $A4:OEM850ToUnicode:=$00F1; $A5:OEM850ToUnicode:=$00D1;
  $A6:OEM850ToUnicode:=$00AA; $A7:OEM850ToUnicode:=$00BA;
  $A8:OEM850ToUnicode:=$00BF; $A9:OEM850ToUnicode:=$00AE;
  $AA:OEM850ToUnicode:=$00AC; $AB:OEM850ToUnicode:=$00BD;
  $AC:OEM850ToUnicode:=$00BC; $AD:OEM850ToUnicode:=$00A1;
  $AE:OEM850ToUnicode:=$00AB; $AF:OEM850ToUnicode:=$00BB;
  $B0:OEM850ToUnicode:=$2591; $B1:OEM850ToUnicode:=$2592;
  $B2:OEM850ToUnicode:=$2593; $B3:OEM850ToUnicode:=$2502;
  $B4:OEM850ToUnicode:=$2524; $B5:OEM850ToUnicode:=$00C1;
  $B6:OEM850ToUnicode:=$00C2; $B7:OEM850ToUnicode:=$00C0;
  $B8:OEM850ToUnicode:=$00A9; $B9:OEM850ToUnicode:=$2563;
  $BA:OEM850ToUnicode:=$2551; $BB:OEM850ToUnicode:=$2557;
  $BC:OEM850ToUnicode:=$255D; $BD:OEM850ToUnicode:=$00A2;
  $BE:OEM850ToUnicode:=$00A5; $BF:OEM850ToUnicode:=$2510;
  $C0:OEM850ToUnicode:=$2514; $C1:OEM850ToUnicode:=$2534;
  $C2:OEM850ToUnicode:=$252C; $C3:OEM850ToUnicode:=$251C;
  $C4:OEM850ToUnicode:=$2500; $C5:OEM850ToUnicode:=$253C;
  $C6:OEM850ToUnicode:=$00E3; $C7:OEM850ToUnicode:=$00C3;
  $C8:OEM850ToUnicode:=$255A; $C9:OEM850ToUnicode:=$2554;
  $CA:OEM850ToUnicode:=$2569; $CB:OEM850ToUnicode:=$2566;
  $CC:OEM850ToUnicode:=$2560; $CD:OEM850ToUnicode:=$2550;
  $CE:OEM850ToUnicode:=$256C; $CF:OEM850ToUnicode:=$00A4;
  $D0:OEM850ToUnicode:=$00F0; $D1:OEM850ToUnicode:=$00D0;
  $D2:OEM850ToUnicode:=$00CA; $D3:OEM850ToUnicode:=$00CB;
  $D4:OEM850ToUnicode:=$00C8; $D5:OEM850ToUnicode:=$0131;
  $D6:OEM850ToUnicode:=$00CD; $D7:OEM850ToUnicode:=$00CE;
  $D8:OEM850ToUnicode:=$00CF; $D9:OEM850ToUnicode:=$2518;
  $DA:OEM850ToUnicode:=$250C; $DB:OEM850ToUnicode:=$2588;
  $DC:OEM850ToUnicode:=$2584; $DD:OEM850ToUnicode:=$00A6;
  $DE:OEM850ToUnicode:=$00CC; $DF:OEM850ToUnicode:=$2580;
  $E0:OEM850ToUnicode:=$00D3; $E1:OEM850ToUnicode:=$00DF;
  $E2:OEM850ToUnicode:=$00D4; $E3:OEM850ToUnicode:=$00D2;
  $E4:OEM850ToUnicode:=$00F5; $E5:OEM850ToUnicode:=$00D5;
  $E6:OEM850ToUnicode:=$00B5; $E7:OEM850ToUnicode:=$00FE;
  $E8:OEM850ToUnicode:=$00DE; $E9:OEM850ToUnicode:=$00DA;
  $EA:OEM850ToUnicode:=$00DB; $EB:OEM850ToUnicode:=$00D9;
  $EC:OEM850ToUnicode:=$00FD; $ED:OEM850ToUnicode:=$00DD;
  $EE:OEM850ToUnicode:=$00AF; $EF:OEM850ToUnicode:=$00B4;
  $F0:OEM850ToUnicode:=$00AD; $F1:OEM850ToUnicode:=$00B1;
  $F2:OEM850ToUnicode:=$2017; $F3:OEM850ToUnicode:=$00BE;
  $F4:OEM850ToUnicode:=$00B6; $F5:OEM850ToUnicode:=$00A7;
  $F6:OEM850ToUnicode:=$00F7; $F7:OEM850ToUnicode:=$00B8;
  $F8:OEM850ToUnicode:=$00B0; $F9:OEM850ToUnicode:=$00A8;
  $FA:OEM850ToUnicode:=$00B7; $FB:OEM850ToUnicode:=$00B9;
  $FC:OEM850ToUnicode:=$00B3; $FD:OEM850ToUnicode:=$00B2;
  $FE:OEM850ToUnicode:=$25A0; $FF:OEM850ToUnicode:=$00A0;
 Else
  OEM850ToUnicode:=B;
 End;
End;

Procedure WriteStaticFile(EntryName,Data:String);
Begin
 StartZipEntry(EntryName);
 PutZipData(Data);
 FinishZipEntry;
End;

Procedure WriteContentTypes;
Begin
 StartZipEntry('[Content_Types].xml');
 PutZipData('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 PutZipData('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">');
 PutZipData('<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>');
 PutZipData('<Default Extension="xml" ContentType="application/xml"/>');
 PutZipData('<Override PartName="/xl/workbook.xml" ContentType="'+
            'application/vnd.openxmlformats-officedocument.'+
            'spreadsheetml.sheet.main+xml"/>');
 PutZipData('<Override PartName="/xl/worksheets/sheet1.xml" ContentType="'+
            'application/vnd.openxmlformats-officedocument.spreadsheetml.'+
            'worksheet+xml"/>');
 PutZipData('<Override PartName="/docProps/core.xml" ContentType="'+
            'application/vnd.openxmlformats-package.core-properties+xml"/>');
 PutZipData('<Override PartName="/docProps/app.xml" ContentType="'+
            'application/vnd.openxmlformats-officedocument.extended-properties+xml"/>');
 PutZipData('</Types>');
 FinishZipEntry;
End;

Procedure WriteRootRels;
Begin
 StartZipEntry('_rels/.rels');
 PutZipData('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 PutZipData('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
 PutZipData('<Relationship Id="rId1" Type="http://schemas.'+
            'openxmlformats.org/officeDocument/2006/relationships/'+
            'officeDocument" Target="xl/workbook.xml"/>');
 PutZipData('<Relationship Id="rId2" Type="http://schemas.'+
            'openxmlformats.org/package/2006/relationships/'+
            'metadata/core-properties" Target="docProps/core.xml"/>');
 PutZipData('<Relationship Id="rId3" Type="http://schemas.'+
            'openxmlformats.org/officeDocument/2006/relationships/'+
            'extended-properties" Target="docProps/app.xml"/>');
 PutZipData('</Relationships>');
 FinishZipEntry;
End;

Procedure WriteWorkbook;
Begin
 StartZipEntry('xl/workbook.xml');
 PutZipData('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 PutZipData('<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" ');
 PutZipData('xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">');
 PutZipData('<sheets><sheet name="Feuil1" sheetId="1" r:id="rId1"/></sheets>');
 PutZipData('</workbook>');
 FinishZipEntry;
End;

Procedure WriteWorkbookRels;
Begin
 StartZipEntry('xl/_rels/workbook.xml.rels');
 PutZipData('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 PutZipData('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
 PutZipData('<Relationship Id="rId1" Type="http://schemas.'+
            'openxmlformats.org/officeDocument/2006/relationships/'+
            'worksheet" Target="worksheets/sheet1.xml"/>');
 PutZipData('</Relationships>');
 FinishZipEntry;
End;

Procedure WriteDocProps;
Begin
 StartZipEntry('docProps/core.xml');
 PutZipData('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 PutZipData('<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" ');
 PutZipData('xmlns:dc="http://purl.org/dc/elements/1.1/" ');
 PutZipData('xmlns:dcterms="http://purl.org/dc/terms/" ');
 PutZipData('xmlns:dcmitype="http://purl.org/dc/dcmitype/" ');
 PutZipData('xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');
 PutZipData('<dc:creator>CSV2XLSX</dc:creator>');
 PutZipData('<cp:lastModifiedBy>CSV2XLSX</cp:lastModifiedBy>');
 PutZipData('</cp:coreProperties>');
 FinishZipEntry;

 StartZipEntry('docProps/app.xml');
 PutZipData('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 PutZipData('<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" ');
 PutZipData('xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">');
 PutZipData('<Application>CSV2XLSX</Application>');
 PutZipData('</Properties>');
 FinishZipEntry;
End;

Procedure WriteCell(C,R:Integer;S:String);
Begin
 PutZipData('<c r="');
 PutZipData(ColumnName(C));
 PutZipData(Long2Str(R+1));
 PutZipData('" t="inlineStr"><is><t>');
 WriteXmlEscaped(S);
 PutZipData('</t></is></c>');
End;

Procedure AddCSVCell;
Begin
 If(Length(CurrCell)>=2)and(CurrCell[1]='"')and
   (CurrCell[Length(CurrCell)]='"')Then
  CurrCell:=Copy(CurrCell,2,Length(CurrCell)-2);
 WriteCell(CurrColumn,CurrRow,CurrCell);
 Inc(CurrColumn);
 CurrCell:='';
End;

Procedure WriteWorksheet;
Var
 I:Integer;
 InQuotes:Boolean;
Begin
 StartZipEntry('xl/worksheets/sheet1.xml');
 PutZipData('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 PutZipData('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>');

 CurrRow:=0;
 While Not EOF(SourceCSV)do Begin
  ReadLn(SourceCSV,CurrLine);
  CurrColumn:=0;
  CurrCell:='';
  InQuotes:=False;
  PutZipData('<row r="');
  PutZipData(Long2Str(CurrRow+1));
  PutZipData('">');
  I:=1;
  While I<=Length(CurrLine)do Begin
   If CurrLine[I]='"'Then Begin
    If InQuotes and(I<Length(CurrLine))and(CurrLine[I+1]='"')Then Begin
     CurrCell:=CurrCell+'"';
     Inc(I);
    End
     Else
    Begin
     InQuotes:=Not InQuotes;
     CurrCell:=CurrCell+'"';
    End;
   End
    Else If(CurrLine[I]=',')and(Not InQuotes)Then
   Begin
    AddCSVCell;
   End
    Else
   CurrCell:=CurrCell+CurrLine[I];
   Inc(I);
  End;
  AddCSVCell;
  PutZipData('</row>');
  Inc(CurrRow);
 End;

 PutZipData('</sheetData></worksheet>');
 FinishZipEntry;
End;

Procedure WriteXLSX;
Begin
 ZipCount:=0;
 WriteContentTypes;
 WriteRootRels;
 WriteDocProps;
 WriteWorkbook;
 WriteWorkbookRels;
 WriteWorksheet;
 WriteCentralDirectory;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CSV2XLSX : Cette commande permet de convertir un fichier CSV en XLSX de Microsoft Excel.');
  WriteLn;
  WriteLn('Syntaxe : CSV2XLSX source.CSV target.XLSX');
  WriteLn;
  WriteLn(' fichier.CSV   Nom du fichier a convertir');
  WriteLn(' fichier.XLSX  Nom du fichier du resultat');
  WriteLn;
 End
  Else
 Begin
  If ParamCount>0Then Begin
   FileName:=FExpand(ParamStr(1));
   If Path2Ext(FileName)=''Then FileName:=FileName+'.CSV';
   Assign(SourceCSV,FileName);
   {$I-}Reset(SourceCSV);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Fichier CSV introuvable !');
    Halt;
   End;
   If ParamStr(2)=''Then Begin
    WriteLn('Destination attendue !');
    Close(SourceCSV);
    Halt;
   End
    Else
   Begin
    TFileName:=FExpand(ParamStr(2));
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.XLSX';
    Assign(TargetXLSX,TFileName);
    {$I-}Rewrite(TargetXLSX,1);{$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de creer le fichier XLSX ',TFileName,' !');
     Close(SourceCSV);
     Halt;
    End;
    InitCRC32;
    WriteXLSX;
    Close(TargetXLSX);
    Close(SourceCSV);
   End;
  End
   Else
  WriteLn('Parametre requis !');
 End;
END.
