{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CKSUM;

Uses DOS;

{$R-}

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 SourcePath,Source:String;
 NumFiles,i:Word;
 SRec:SearchRec;
 FileArray:Array[1..128] of ^SearchRec;
 CheckSum,Size:LongInt;
 C:Char;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function PadZeroLeft(Value:LongInt;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

Function Path2Dir(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 Path2Dir:='';
 If Path=''Then Exit;
 FSplit(Path,D,N,E);
 If E=''Then Begin
  If D[Length(D)]<>'\'Then D:=D+'\';
  D:=D+E;
 End;
 If D=''Then Path2Dir:='' Else
 If D[Length(D)]<>'\'Then D:=D+'\';
 Path2Dir:=D;
End;

Function CRC32(Value:Byte;CRC:LongInt):LongInt;
Const
  crc32_table : Array[0..255] of LongInt = (
    $00000000, $77073096, $ee0e612c, $990951ba, $076dc419, $706af48f,
    $e963a535, $9e6495a3, $0edb8832, $79dcb8a4, $e0d5e91e, $97d2d988,
    $09b64c2b, $7eb17cbd, $e7b82d07, $90bf1d91, $1db71064, $6ab020f2,
    $f3b97148, $84be41de, $1adad47d, $6ddde4eb, $f4d4b551, $83d385c7,
    $136c9856, $646ba8c0, $fd62f97a, $8a65c9ec, $14015c4f, $63066cd9,
    $fa0f3d63, $8d080df5, $3b6e20c8, $4c69105e, $d56041e4, $a2677172,
    $3c03e4d1, $4b04d447, $d20d85fd, $a50ab56b, $35b5a8fa, $42b2986c,
    $dbbbc9d6, $acbcf940, $32d86ce3, $45df5c75, $dcd60dcf, $abd13d59,
    $26d930ac, $51de003a, $c8d75180, $bfd06116, $21b4f4b5, $56b3c423,
    $cfba9599, $b8bda50f, $2802b89e, $5f058808, $c60cd9b2, $b10be924,
    $2f6f7c87, $58684c11, $c1611dab, $b6662d3d, $76dc4190, $01db7106,
    $98d220bc, $efd5102a, $71b18589, $06b6b51f, $9fbfe4a5, $e8b8d433,
    $7807c9a2, $0f00f934, $9609a88e, $e10e9818, $7f6a0dbb, $086d3d2d,
    $91646c97, $e6635c01, $6b6b51f4, $1c6c6162, $856530d8, $f262004e,
    $6c0695ed, $1b01a57b, $8208f4c1, $f50fc457, $65b0d9c6, $12b7e950,
    $8bbeb8ea, $fcb9887c, $62dd1ddf, $15da2d49, $8cd37cf3, $fbd44c65,
    $4db26158, $3ab551ce, $a3bc0074, $d4bb30e2, $4adfa541, $3dd895d7,
    $a4d1c46d, $d3d6f4fb, $4369e96a, $346ed9fc, $ad678846, $da60b8d0,
    $44042d73, $33031de5, $aa0a4c5f, $dd0d7cc9, $5005713c, $270241aa,
    $be0b1010, $c90c2086, $5768b525, $206f85b3, $b966d409, $ce61e49f,
    $5edef90e, $29d9c998, $b0d09822, $c7d7a8b4, $59b33d17, $2eb40d81,
    $b7bd5c3b, $c0ba6cad, $edb88320, $9abfb3b6, $03b6e20c, $74b1d29a,
    $ead54739, $9dd277af, $04db2615, $73dc1683, $e3630b12, $94643b84,
    $0d6d6a3e, $7a6a5aa8, $e40ecf0b, $9309ff9d, $0a00ae27, $7d079eb1,
    $f00f9344, $8708a3d2, $1e01f268, $6906c2fe, $f762575d, $806567cb,
    $196c3671, $6e6b06e7, $fed41b76, $89d32be0, $10da7a5a, $67dd4acc,
    $f9b9df6f, $8ebeeff9, $17b7be43, $60b08ed5, $d6d6a3e8, $a1d1937e,
    $38d8c2c4, $4fdff252, $d1bb67f1, $a6bc5767, $3fb506dd, $48b2364b,
    $d80d2bda, $af0a1b4c, $36034af6, $41047a60, $df60efc3, $a867df55,
    $316e8eef, $4669be79, $cb61b38c, $bc66831a, $256fd2a0, $5268e236,
    $cc0c7795, $bb0b4703, $220216b9, $5505262f, $c5ba3bbe, $b2bd0b28,
    $2bb45a92, $5cb36a04, $c2d7ffa7, $b5d0cf31, $2cd99e8b, $5bdeae1d,
    $9b64c2b0, $ec63f226, $756aa39c, $026d930a, $9c0906a9, $eb0e363f,
    $72076785, $05005713, $95bf4a82, $e2b87a14, $7bb12bae, $0cb61b38,
    $92d28e9b, $e5d5be0d, $7cdcefb7, $0bdbdf21, $86d3d2d4, $f1d4e242,
    $68ddb3f8, $1fda836e, $81be16cd, $f6b9265b, $6fb077e1, $18b74777,
    $88085ae6, $ff0f6a70, $66063bca, $11010b5c, $8f659eff, $f862ae69,
    $616bffd3, $166ccf45, $a00ae278, $d70dd2ee, $4e048354, $3903b3c2,
    $a7672661, $d06016f7, $4969474d, $3e6e77db, $aed16a4a, $d9d65adc,
    $40df0b66, $37d83bf0, $a9bcae53, $debb9ec5, $47b2cf7f, $30b5ffe9,
    $bdbdf21c, $cabac28a, $53b39330, $24b4a3a6, $bad03605, $cdd70693,
    $54de5729, $23d967bf, $b3667a2e, $c4614ab8, $5d681b02, $2a6f2b94,
    $b40bbe37, $c30c8ea1, $5a05df1b, $2d02ef8d
  );
Begin
 If CRC=0 Then CRC:=$FFFFFFFF;
 CRC32:=crc32_table[Byte(crc xor LongInt(value))] xor((crc shr 8) and $00FFFFFF);
End;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

Function LongHex2Str(value:LongInt):String;
Begin
 LongHex2Str:=ByteHex2Str((value shr 24)and $FF)+
              ByteHex2Str((value shr 16)and $FF)+
              ByteHex2Str((value shr 8)and $FF)+
              ByteHex2Str(value and $FF);
End;

Procedure Convert32(FName:String;FSize:LongInt);
Const
 BufSize=32768;
Type
 fbuf=Array[1..bufsize]of Byte;
Var
 I:Word;
 Source:File;
 BRead:Word;
 FileBuf:^fbuf;
 crc,tr:LongInt;
Begin
 crc:=$ffffffff;
 tr:=0;
 New(Filebuf);
 {$I-}Assign(Source,FName);
 Reset(Source,1);{$I+}
 If IoResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier !');
  Halt;
 End;
 Repeat
  BlockRead(Source,Filebuf^,BufSize,BRead);
  tr:=tr+BRead;
  For i:=1 to BRead do crc:=CRC32(Filebuf^[i],crc);
 Until BRead = 0;
 Close(Source);
 Dispose(Filebuf);
 Write(LongHex2Str(crc),' ',FSize,' ',FName);
End;

BEGIN
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _English:Begin
    WriteLn('CKSUM : This command print checksum and byte counts of each file.');
    WriteLn;
    WriteLn('CKSUM [/?] filename');
    WriteLn;
    WriteLn('/?          = Help for this command');
    WriteLn('filename    = Filename to check');
   End;
   Else Begin
    WriteLn('CKSUM : Cette commande permet d''afficher la sommation de v�rification ',
                     'CRC et le nombre d''octets de chaque fichier.');
    WriteLn;
    WriteLn('Syntaxe : CKSUM [/?] filename');
    WriteLn;
    WriteLn(' /?          Ce param�tre permet de founir de l''aide sur cette commande.');
    WriteLn('filename     Ce param�tre permet d''indiquer le fichier � v�rifier');
   End;
  End;
 End
  Else
 If ParamCount>0 Then Begin
  Source:=FExpand(ParamStr(1));
  SourcePath:=Path2Dir(Source);
  NumFiles:=0;
  FindFirst(Source,AnyFile,SRec);
  While Doserror=0 do Begin
   If Not(((SRec.Attr and Directory)>0)or((SRec.attr and VolumeID)>0)and(SRec.Size>0))Then Begin
    Inc(NumFiles);
    New(FileArray[NumFiles]);
    FileArray[numFiles]^:=SRec;
   End;
   FindNext(srec);
   If NumFiles+1>=High(FileArray)Then Break;
  End;
  If NumFiles=0Then Begin
   WriteLn('Fichier introuvable');
  End
   Else
  For I:=1 to NumFiles do Convert32(SourcePath+FileArray[i]^.Name,FileArray[i]^.Size);
 End
  Else
 Begin
  CheckSum:=$FFFFFFFF;
  Size:=0;
  While Not EOF do Begin
   {$I-}Read(C);{$I+}
   If IOResult<>0 Then Break;
   CheckSum:=CRC32(Byte(C),CheckSum);
   Inc(Size);
  End;
  WriteLn(LongHex2Str(CheckSum),Size:6);
 End;
END.
