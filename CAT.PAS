{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program CAT(Input,Output);

{$N+}

Uses DOS;

Var
 Language:(_Albanian,_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 ModeParam:Set of (CStr,Lower,Hex,Html,Number,NumberNonblank,PascalStr,
                   SqueezeBlank,ShowEnd,ShowTab,ShowNonprinting,
                   TrimLine,Uniq,Upper,Basic);
 ReadFromConsole:Boolean;
 I,J:Integer;
 LineNumber:LongInt;
 ShowLine,Found:Boolean;
 Handle:Text;
 Info:SearchRec;
 CurrDir,LastLine,CurrLine:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function StrToLower(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
 End;
 StrToLower:=S;
End;

Function TrimL(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If S[I]<>' 'Then Begin
   TrimL:=Copy(S,I,255);
   Exit;
  End;
 End;
 TrimL:=S;
End;

Function TrimR(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 TrimR:=S;
End;

Function Trim(s:String):String;Begin
 Trim:=TrimL(TrimR(s));
End;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
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

Procedure ProcessLine;Begin
 ShowLine:=True;
 If(SqueezeBlank in ModeParam)Then Begin
  If(CurrLine=LastLine)and(CurrLine='')Then ShowLine:=False;
 End
  Else
 If(Uniq in ModeParam)Then Begin
  If(CurrLine=LastLine)Then ShowLine:=False;
 End;
 If(ShowLine)Then Begin
  If(Number in ModeParam)Then Begin
   Inc(LineNumber);
   Write(LineNumber:6,' ':2);
  End
   Else
  If CurrLine<>''Then Begin
   Inc(LineNumber);
   If(NumberNonblank in ModeParam)Then Write(LineNumber:6,' ':2);
  End;
  If(Upper in ModeParam)Then CurrLine:=StrToUpper(CurrLine) Else
  If(Lower in ModeParam)Then CurrLine:=StrToLower(CurrLine);
  If(TrimLine in ModeParam)Then CurrLine:=Trim(CurrLine);
  If(Hex in ModeParam)Then Begin
   For J:=1 to Length(CurrLine)do Write(ByteHex2Str(Byte(CurrLine[J])));
  End
   Else
  If(Html in ModeParam)Then Begin
   For J:=1 to Length(CurrLine)do Begin
    Case CurrLine[J]of
    '&':Write('&amp;');
    '<':Write('&lt;');
    '>':Write('&gt;');
    '"':Write('&quot;');
     Else Write(CurrLine[J]);
    End;
   End;
   Write('<br />');
  End
   Else
  If(PascalStr in ModeParam)Then Begin
   Write('''');
   For J:=1 to Length(CurrLine)do Begin
    Case CurrLine[J]of
     #0:Write('''+#0+''');
     #1..#26:Write('''+^',Chr(64+Byte(CurrLine[I])),'+''');
     #27..#31:Write('''+#',Byte(CurrLine[I]),'+''');
     '''':Write('''','''');
     Else Write(CurrLine[J]);
    End;
   End;
   Write('''');
  End
   Else
  If(CStr in ModeParam)Then Begin
   Write('"');
   For J:=1 to Length(CurrLine)do Begin
    Case CurrLine[J]of
     #0:Write('\0');
     #1..#6,#14..#31:Write('\x',ByteHex2Str(Byte(CurrLine[I])));
     #7:Write('\a');
     #8:Write('\b');
     #9:Write('\t');
     #10:Write('\n');
     #11:Write('\v');
     #12:Write('\f');
     #13:Write('\r');
     '\':Write('\\');
     '''':Write('\''');
     '"':Write('\"');
     '?':Write('\?');
     Else Write(CurrLine[J]);
    End;
   End;
   Write('"');
  End
   Else
  If(ShowNonprinting in ModeParam)Then Begin
   For J:=1 to Length(CurrLine)do Begin
    Case CurrLine[J]of
     #0..#8,#10..#31:Write('^',Chr(Byte(CurrLine[J])+64));
     #9:Write(#9);
     #127:Write('^?');
     #128..#159:Write('M-^',Chr(Byte(CurrLine[J])-128+64));
     #160..#254:Write('M-',Chr(Byte(CurrLine[J])-128));
     #255:Write('M-^?');
     Else Write(CurrLine[J]);
    End;
   End;
  End
   Else
  If(ShowTab in ModeParam)Then Begin
   For J:=1 to Length(CurrLine)do Begin
    Case CurrLine[J]of
     #9:Write('^I');
     Else Write(CurrLine[J]);
    End;
   End;
  End
   Else
  Write(CurrLine);
  If(ShowEnd in ModeParam)Then Write('$');
  WriteLn;
 End;
 LastLine:=CurrLine;
End;

Procedure CatBASIC(SourceName:String);
Label RFGW,RF0,RF1;
Var
 Mode:(None,CocoFileBAS,Coco1FileBAS,GWBASIC);
 Source:File;
 Pos:Word;
 ByteReaded:Word;
 LastB,B:Byte;
 NewLine:Boolean;
 Buffer:Array[0..4]of Byte;
 BufSingle:Single;
 BufDouble:Double;
Begin
 {$I-}Assign(Source,SourceName);
 Reset(Source,1);{$I+}
 If IoResult<>0Then Begin
  WriteLn('Fichier source introuvable');
  Halt;
 End;
 BlockRead(Source,Buffer,3,ByteReaded);
 Mode:=None;
 If(Buffer[0]=$55)Then Begin
  Seek(Source,$119);
  BlockRead(Source,Buffer,3,ByteReaded);
 End;
 If(Buffer[0]=$9D)Then Begin
  Mode:=CocoFileBAS;
 End
  Else
 If(Buffer[0]=$FF)Then Begin
  If Buffer[1]=$7AThen Mode:=GWBASIC
                  Else Mode:=Coco1FileBAS;
 End;
 Case Mode of
  GWBASIC:Begin
   BlockRead(Source,Buffer,1,ByteReaded);
   Pos:=Buffer[0];
   BlockRead(Source,Buffer,1,ByteReaded);
   Pos:=Pos+Buffer[0]*256;
   Write(Pos,' ');
   NewLine:=True;
   LastB:=0;
   Repeat
    BlockRead(Source,Buffer,1,ByteReaded);
    B:=Buffer[0];
RFGW:
    Case B of
     0:Begin
      WriteLn;
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Buffer[0];
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Pos+Buffer[0]*256;
      BlockRead(Source,Buffer,1,ByteReaded);
      If(Pos=0)and(Buffer[0]=26)Then Break;
      Pos:=Buffer[0];
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Pos+Buffer[0]*256;
      Write(Pos,' ');
      NewLine:=True;
     End;
     $0C:Write('&H');
     $0F:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Write(Buffer[0]);
     End;
     $11..$1A:Begin
      Write(Char(Buffer[0]+31));
     End;
     $1C:Begin
      BlockRead(Source,Buffer,2,ByteReaded);
      Write(Buffer[0]+Buffer[1]*256);
     End;
     $1D:Begin
      BlockRead(Source,BufSingle,4,ByteReaded);
      Write(BufSingle);
     End;
     $1F:Begin
      BlockRead(Source,BufDouble,4,ByteReaded);
      Write(BufDouble);
     End;
     $3A:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $20:Begin
        BlockRead(Source,Buffer,1,ByteReaded);
        If Buffer[0]=32Then Write('GOSUB')
                       Else Write(#$3A,#32,Buffer[0]);
       End;
       $8F:Begin
        LastB:=B;
        B:=Buffer[0];
        Goto RFGW;
       ENd;
       $A1:Write('ELSE');
       Else Begin
        Write(Char(B));
        LastB:=B;
        B:=Buffer[0];
        Goto RFGW;
       End;
      End;
     End;
     $81:Write('END');
     $82:Write('FOR');
     $83:Write('NEXT');
     $84:Write('DATA');
     $85:Write('INPUT');
     $86:Write('DIM');
     $87:Write('READ');
     $88:Write('LET');
     $89:Write('GOTO');
     $8A:Write('RUN');
     $8B:Write('IF');
     $8C:Write('RESTORE');
     $8D:Write('GOSUB');
     $8E:Write('RETURN');
     $8F:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $D9:Begin
        Write('''');
        While Not EOF(Source)do Begin
         BlockRead(Source,Buffer,1,ByteReaded);
         If Buffer[0]=0Then Begin
          B:=Buffer[0];
          Goto RFGW;
         End;
         Write(Char(Buffer[0]));
        End;
       End;
       Else Begin
        Write('REM');
        While Not EOF(Source)do Begin
         BlockRead(Source,Buffer,1,ByteReaded);
         If Buffer[0]=0Then Begin
         B:=Buffer[0];
          Goto RFGW;
         End;
         Write(Char(Buffer[0]));
        End;
       End;
      End;
     End;
     $90:Write('STOP');
     $91:Write('PRINT');
     $92:Write('CLEAR');
     $93:Write('LIST');
     $94:Write('NEW');
     $95:Write('ON');
     $96:Write('WAIT');
     $97:Write('DEF');
     $98:Write('POKE');
     $99:Write('CONT');
     $9C:Write('OUT');
     $9D:Write('LPRINT');
     $9E:Write('LLIST');
     $A0:Write('WIDTH');
     $A1:Write('ELSE');
     $A2:Write('TRON');
     $A3:Write('TROFF');
     $A4:Write('SWAP');
     $A5:Write('ERASE');
     $A6:Write('EDIT');
     $A7:Write('ERROR');
     $A8:Write('RESUME');
     $A9:Write('DELETE');
     $AA:Write('AUTO');
     $AB:Write('RENUM');
     $AC:Write('DEFSTR');
     $AD:Write('DEFINT');
     $AE:Write('DEFSNG');
     $AF:Write('DEFDBL');
     $B0:Write('LINE');
     $B1:Write('WHILE');
     $B2:Write('WEND');
     $B3:Write('CALL');
     $B7:Write('WRITE');
     $B8:Write('OPTION');
     $B9:Write('RANDOMIZE');
     $BA:Write('OPEN');
     $BB:Write('CLOSE');
     $BC:Write('LOAD');
     $BD:Write('MERGE');
     $BE:Write('SAVE');
     $BF:Write('COLOR');
     $C0:Write('CLS');
     $C1:Write('MOTOR');
     $C2:Write('BSAVE');
     $C3:Write('BLOAD');
     $C4:Write('SOUND');
     $C5:Write('BEEP');
     $C6:Write('PSET');
     $C7:Write('PRESET');
     $C8:Write('SCREEN');
     $C9:Write('KEY');
     $CA:Write('LOCATE');
     $CC:Write('TO');
     $CD:Write('THEN');
     $CE:Write('TAB(');
     $CF:Write('STEP');
     $D0:Write('USR');
     $D1:Write('FN');
     $D2:Write('SPC(');
     $D3:Write('NOT');
     $D4:Write('ERL');
     $D5:Write('ERR');
     $D6:Write('STRING$');
     $D7:Write('USING');
     $D8:Write('INSTR');
     $D9:Write('''');
     $DA:Write('VARPTR');
     $DB:Write('CSRLIN');
     $DC:Write('POINT');
     $DD:Write('OFF');
     $DE:Write('INKEY$');
     $E6:Write('>');
     $E7:Write('=');
     $E8:Write('<');
     $E9:Write('+');
     $EA:Write('-');
     $EB:Write('*');
     $EC:Write('/');
     $EE:Write('AND');
     $EF:Write('OR');
     $F0:Write('XOR');
     $F1:Write('EQV');
     $F2:Write('IMP');
     $F3:Write('MOD');
     $F4:Write('\');
     $FD:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $81:Write('CVI');
       $82:Write('CVS');
       $83:Write('CVD');
       $84:Write('MKI$');
       $85:Write('MKS$');
       $86:Write('MKD$');
       $87..$8A:Write('---');
       $8B:Write('EXTERR');
       Else Write(Char(Buffer[0]));
      End;
     End;
     $FE:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $81:Write('FILES');
       $82:Write('FIELD');
       $83:Write('SYSTEM');
       $84:Write('NAME');
       $85:Write('LSET');
       $86:Write('RSET');
       $87:Write('KILL');
       $88:Write('PUT');
       $89:Write('GET');
       $8A:Write('RESET');
       $8B:Write('COMMON');
       $8C:Write('CHAIN');
       $8D:Write('DATE$');
       $8E:Write('TIME$');
       $8F:Write('PAINT');
       $90:Write('COM');
       $91:Write('CIRCLE');
       $92:Write('DRAW');
       $93:Write('PLAY');
       $94:Write('TIMER');
       $95:Write('ERDEV');
       $96:Write('IOCTL');
       $97:Write('CHDIR');
       $98:Write('MKDIR');
       $99:Write('RMDIR');
       $9A:Write('SHELL');
       $9B:Write('ENVIRON');
       $9C:Write('VIEW');
       $9D:Write('WINDOW');
       $9E:Write('PMAP');
       $9F:Write('PALETTE');
       $A0:Write('LCOPY');
       $A1:Write('CALLS');
       $A2,$A3,$A4,$A6:Write('---');
       $A5:Write('PCOPY');
       $A7:Write('LOCK');
       $A8:Write('UNLOCK');
       Else Write(Char(Buffer[0]));
      End;
     End;
     $FF:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $81:Write('LEFT$');
       $82:Write('RIGHT$');
       $83:Write('MID$');
       $84:Write('SGN');
       $85:Write('INT');
       $86:Write('ABS');
       $87:Write('SQR');
       $88:Write('RND');
       $89:Write('SIN');
       $8A:Write('LOG');
       $8B:Write('EXP');
       $8C:Write('COS');
       $8D:Write('TAN');
       $8E:Write('ATN');
       $8F:Write('FRE');
       $90:Write('INP');
       $91:Write('POS');
       $92:Write('LEN');
       $93:Write('STR$');
       $94:Write('VAL');
       $95:Write('ASC');
       $96:Write('CHR$');
       $97:Write('PEEK');
       $98:Write('SPACE$');
       $99:Write('OCT$');
       $9A:Write('HEX$');
       $9B:Write('LPOS');
       $9C:Write('CINT');
       $9D:Write('CSNG');
       $9E:Write('CDBL');
       $9F:Write('FIX');
       $A0:Write('PEN');
       $A1:Write('STICK');
       $A2:Write('STRIG');
       $A3:Write('EOF');
       $A4:Write('LOC');
       $A5:Write('LOF');
       Else Write(Char(Buffer[0]));
      End;
     End;
     Else Write(Char(Buffer[0]));
    End;
    If B<>0Then NewLine:=False;
    LastB:=B;
   Until EOF(Source);
   Close(Source);
  End;
  Coco1FileBAS:Begin
   BlockRead(Source,Buffer,1,ByteReaded);
   BlockRead(Source,Buffer,1,ByteReaded);
   BlockRead(Source,Buffer,1,ByteReaded);
   Pos:=Buffer[0]*256;
   BlockRead(Source,Buffer,1,ByteReaded);
   Pos:=Pos+Buffer[0];
   Write(Pos,' ');
   NewLine:=True;
   LastB:=0;
   Repeat
    BlockRead(Source,Buffer,1,ByteReaded);
    B:=Buffer[0];
RF0:
    Case B of
     0:Begin
      WriteLn;
      BlockRead(Source,Buffer,1,ByteReaded);
      BlockRead(Source,Buffer,1,ByteReaded);
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Buffer[0]*256;
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Pos+Buffer[0];
      Write(Pos,' ');
      NewLine:=True;
     End;
     $3A:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $83:Write('''');
       $84:Write('ELSE');
       $92:Write('POKE');
       Else Begin
        Write(':');
        LastB:=B;B:=Buffer[0];
        Goto RF0;
       End;
      End;
     End;
     $80:Write('FOR');
     $81:Write('GO');
     $82:Write('REM');
     $83:Write('''');
     $84:Write('ELSE');
     $85:Write('IF');
     $86:Write('DATA');
     $87:Write('PRINT');
     $88:Write('ON');
     $89:Write('INPUT');
     $8A:Write('END');
     $8B:Write('NEXT');
     $8C:Write('DIM');
     $8D:Write('READ');
     $8E:Write('RUN');
     $8F:Write('RESTORE');
     $90:Write('RETURN');
     $91:Write('STOP');
     $92:Write('POKE');
     $93:Write('CONT');
     $94:Write('LIST');
     $95:Write('CLEAR');
     $96:Write('NEW');
     $97:Write('CLOAD');
     $98:Write('CSAVE');
     $99:Write('OPEN');
     $9A:Write('CLOSE');
     $9B:Write('LLIST');
     $9C:Write('SET');
     $9D:Write('RESET');
     $9E:Write('CLS');
     $9F:Write('MOTOR');
     $A0:Write('SOUND');
     $A1:Write('AUDIO');
     $A2:Write('EXEC');
     $A3:Write('SKIPF');
     $A4:Write('TAB(');
     $A5:Write('TO');
     $A6:Write('SUB');
     $A7:Write('THEN');
     $A8:Write('NOT');
     $A9:Write('STEP');
     $AA:Write('OFF');
     $AB:Write('+');
     $AC:Write('-');
     $AD:Write('*');
     $AE:Write('/');
     $AF:Write('^');
     $B0:Write('AND');
     $B1:Write('OR');
     $B2:Write('>');
     $B3:Write('=');
     $B4:Write('<');
     $B5:Write('DEL');
     $B6:Write('EDIT');
     $B7:Write('TRON');
     $B8:Write('TROFF');
     $B9:Write('DEF');
     $BA:Write('LET');
     $BB:Write('LINE');
     $BC:Write('PCLS');
     $BD:Write('PSET');
     $BE:Write('PRESET');
     $BF:Write('SCREEN');
     $C0:Write('PCLEAR');
     $C1:Write('COLOR');
     $C2:Write('CIRCLE');
     $C3:Write('PAINT');
     $C4:Write('GET');
     $C5:Write('PUT');
     $C6:Write('DRAW');
     $C7:Write('PCOPY');
     $C8:Write('PMODE');
     $C9:Write('PLAY');
     $CA:Write('DLOAD');
     $CB:Write('RENUM');
     $CC:Write('FN');
     $CD:Write('USING');
     $CE:Write('DIR');
     $CF:Write('DRIVE');
     $D0:Write('FIELD');
     $D1:Write('FILES');
     $D2:Write('KILL');
     $D3:Write('LOAD');
     $D4:Write('LSET');
     $D5:Write('MERGE');
     $D6:Write('RENAME');
     $D7:Write('RSET');
     $D8:Write('SAVE');
     $D9:Write('WRITE');
     $DA:Write('VERIFY');
     $DB:Write('UNLOAD');
     $DC:Write('DSKINI');
     $DD:Write('BACKUP');
     $DE:Write('COPY');
     $DF:Write('DSKI$');
     $E0:Write('DSKO$');
     $E3:Write('PALETTE');
     $E4:Write('HSCREEN');
     $E6:Write('HCLS');
     $E7:Write('HCOLOR');
     $E9:Write('HCIRCLE');
     $EA:Write('HLINE');
     $EB:Write('HGET');
     $EC:Write('HPUT');
     $ED:Write('HBUFF');
     $EE:Write('HPRINT');
     $F0:Write('BRK');
     $F1:Write('LOCATE');
     $F7:Write('RGB');
     $FF:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $80:Write('SGN');
       $81:Write('INT');
       $82:Write('ABS');
       $83:Write('USR');
       $84:Write('RND');
       $85:Write('SIN');
       $86:Write('PEEK');
       $87:Write('LEN');
       $88:Write('STR$');
       $89:Write('VAL');
       $8A:Write('ASC');
       $8B:Write('CHR$');
       $8C:Write('EOF');
       $8D:Write('JOYSTK');
       $8E:Write('LEFT$');
       $8F:Write('RIGHT$');
       $90:Write('MID$');
       $91:Write('POINT');
       $92:Write('INKEY$');
       $93:Write('MEM');
       $94:Write('ATN');
       $95:Write('COS');
       $96:Write('TAN');
       $97:Write('EXP');
       $98:Write('FIX');
       $99:Write('LOG');
       $9A:Write('POS');
       $9B:Write('SQR');
       $9C:Write('HEX$');
       $9D:Write('VARPTR');
       $9E:Write('INSTR');
       $9F:Write('TIMER');
       $A0:Write('PPOINT');
       $A1:Write('STRING$');
       $A2:Write('CVN');
       $A3:Write('FREE');
       $A4:Write('LOC');
       $A5:Write('LOF');
       $A6:Write('MKN$');
       Else Write(Char(Buffer[0]));
      End;
     End;
     Else Write(Char(Buffer[0]));
    End;
    If B<>0Then NewLine:=False;
    LastB:=B;
   Until EOF(Source);
   Close(Source);
  End;
  CocoFileBAS:Begin
   BlockRead(Source,Buffer,1,ByteReaded);
   BlockRead(Source,Buffer,1,ByteReaded);
   BlockRead(Source,Buffer,1,ByteReaded);
   Pos:=Buffer[0]*256;
   BlockRead(Source,Buffer,1,ByteReaded);
   Pos:=Pos+Buffer[0];
   Write(Pos,' ');
   NewLine:=True;
   LastB:=0;
   Repeat
    BlockRead(Source,Buffer,1,ByteReaded);
    B:=Buffer[0];
RF1:
    Case B of
     0:Begin
      WriteLn;
      BlockRead(Source,Buffer,1,ByteReaded);
      BlockRead(Source,Buffer,1,ByteReaded);
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Buffer[0]*256;
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Pos+Buffer[0];
      Write(Pos,' ');
      NewLine:=True;
     End;
     $0E,$1C:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Buffer[0]*256;
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Pos+Buffer[0];
      Write(Pos,' ');
     End;
     $0F:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Write(Buffer[0]);
     End;
     $11..$1A:Begin
      Write(Char(Buffer[0]+31));
     End;
     $3A:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $C9: Write('''');
       $D1:Write('ELSE');
       Else Begin
        Write(':');
        LastB:=B;B:=Buffer[0];
        Goto RF1;
       End;
      End;
     End;
     $80:Write('TO');
     $81:Write('X81');
     $82:Write('*');
     $83:Write('AND');
     $84:If LastB<>$3AThen Write('=')
                      Else Write('FOR');
     $85:Write('X85');
     $86:Write('X86');
     $87:Write('PSET');
     $88:Write('X88');
     $89:Write('X89');
     $8A:Write('PLAY');
     $8B:Write('X8B');
     $8C:Write('X8C');
     $8D:Write('X8D');
     $8E:Write('X8E');
     $8F:Write('X8F');
     $90:Write('X90');
     $91:Write('X91');
     $92:Write('WIDTH');
     $93:Write('PALETTE');
     $94:Write('HSCREEN');
     $95:Write('BRK');
     $96:Write('X96');
     $97:Write('RGB');
     $98:Write('X98');
     $99:Write('X99');
     $9A:Write('X9A');
     $9B:Write('X9B');
     $9C:Write('X9C');
     $9D:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $B0:Write('STRING$');
       $D1:Write('RND');
       $E3:Write('CHR$');
       $E4:Write('ASC');
       $E9:Write('LEFT$');
       $ED:Write('INKEY$');
       Else Write(Char(Buffer[0]));
      End;
     End;
     $9E:Write('X9E');
     $9F:Write('X9F');
     $A0:Write('XA0');
     $A1:Write('XA1');
     $A2:Write('XA2');
     $A3:Write('XA3');
     $A4:Write('XA4');
     $A5:Write('<');
     $A6:Write('XA6');
     $A7:Write('XA7');
     $A8:Write('-');
     $A9:Write('XA9');
     $AA:Write('LINE');
     $AB:Write('XAB');
     $AC:Write('XAC');
     $AD:Write('XAD');
     $AE:Write('XAE');
     $AF:Write('ATTR');
     $B0:Write('XB0');
     $B1:Write('OR');
     $B2:Write('XB2');
     $B3:Write('XB3');
     $B4:Write('+');
     $B5:Write('XB5');
     $B6:Write('SUB');
     $B7:Write('XB7');
     $B8:Write('XB8');
     $B9:Write('XB9');
     $BA:Write('XBA');
     $BB:Write('XBB');
     $BC:Write('XBC');
     $BD:Write('XBD');
     $BE:Write('>');
     $BF:Write('PCLEAR');
     $C0:Write('XC0');
     $C1:Write('HCOLOR');
     $C2:Write('XC2');
     $C3:Write('XC3');
     $C4:Write('FOR');
     $C5:Write('GO');
     $C6:Write('XC6');
     $C7:Write('REM');
     $C8:Write('HCIRCLE');
     $C9:Write('''');
     $CA:Write('HCLS');
     $CB:Write('HCIRCLE');
     $CC:Write('HBUFF');
     $CD:Write('HLINE');
     $CE:Write('HGET');
     $CF:Write('HPUT');
     $D0:Write('XD0');
     $D1:Write('ELSE');
     $D2:Write('LOCATE');
     $D3:Write('HPRINT');
     $D4:Write('XD4');
     $D5:Write('XD5');
     $D6:Write('IF');
     $D7:Write('XD7');
     $D8:Write('XD8');
     $D9:Write('XD9');
     $DA:Write('XDA');
     $DB:Write('XDB');
     $DC:Write('DATA');
     $DD:Write('SOUND');
     $DE:Write('XDE');
     $DF:Write('THEN');
     $E0:Write('ON');
     $E1:Write('PRINT');
     $E2:Write('INPUT');
     $E3:Write('NEXT');
     $E4:Write('XE4');
     $E5:Write('DIM');
     $E6:Write('PRESET');
     $E7:Write('READ');
     $E8:Write('XE8');
     $E9:Write('XE9');
     $EA:Write('RETURN');
     $EB:Write('XEB');
     $EC:Write('XEC');
     $ED:Write('POKE');
     $EE:Write('XEE');
     $EF:Write('XEF');
     $F0:Write('XF0');
     $F1:Write('XF1');
     $F2:Write('XF2');
     $F3:Write('XF3');
     $F4:Write('XF4');
     $F5:Write('XF5');
     $F6:Write('XF6');
     $F7:Write('XF7');
     $F8:Write('XF8');
     $F9:Write('XF9');
     $FA:Write('XFA');
     $FB:Write('CLS');
     $FC:Write('XFC');
     $FD:Write('XFD');
     $FE:Write('XFE');
     $FF:Write('XFF');
     Else Write(Char(Buffer[0]));
    End;
    If B<>0Then NewLine:=False;
    LastB:=B;
   Until EOF(Source);
   Close(Source);
  End;
  Else Write('Signature d''encodage non reconnu');
 End;
End;

BEGIN
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='SQ')or
    (StrToUpper(Copy(TmpLanguage,1,3))='ALB')Then Language:=_Albanian;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  Case Language of
   _English:Begin
    WriteLn('CAT : Concatenate FILE(s) to standard output.');
    WriteLn;
    WriteLn('Syntax: cat [OPTION]... [FILE]...');
    WriteLn;
    WriteLn(' -A, --show-all           Equivalent to -vET');
    WriteLn(' -b, --number-nonblank    Number nonempty output lines, overrides -n');
    WriteLn(' -e                       Equivalent to -vE');
    WriteLn(' -E, --show-ends          Display $ at end of each line');
    WriteLn(' -n, --number             Number all output lines');
    WriteLn(' -s, --squeeze-blank      Suppress repeated empty output lines');
    WriteLn(' -t                       Equivalent to -vT');
    WriteLn(' -T, --show-tabs          Display TAB characters as ^I');
    WriteLn(' -u                       (ignored)');
    WriteLn(' -v, --show-nonprinting   Use ^ and M- notation, except for LFD and TAB');
    WriteLn(' --c                      Display each line in C string');
    WriteLn(' --help                   Display this help and exit');
    WriteLn(' --hex                    Display each line in hexadecimal');
    WriteLn(' --html                   Display each line in HTML');
    WriteLn(' --lower                  Lower each line');
    WriteLn(' --pascal                 Display each line in Pascal string');
    WriteLn(' --trim                   Trim each line');
    WriteLn(' --uniq                   Displays once lines are duplicated');
    WriteLn(' --upper                  Upper each line');
    WriteLn(' --version                Output version information and exit');
   End;
   Else Begin
    WriteLn('CAT : Cette commande permet d''afficher le contenu du fichier.');
    WriteLn;
    WriteLn('Syntaxe : CAT [option] [fichier]');
    WriteLn;
    WriteLn(' fichier            Indique le nom du fichier … afficher.');
    WriteLn(' -A                 Equivalent de -vET');
    WriteLn(' -b                 Affiche les num‚ros de ligne si la ligne n''est pas vide');
    WriteLn(' -E                 Affiche un caractŠre $ … la fin d''une ligne.');
    WriteLn(' -e                 Equivalent de -vE');
    WriteLn(' -n                 Affiche les num‚ros de ligne');
    WriteLn(' -s                 EnlŠve les duplications de ligne blanche');
    WriteLn(' -T                 Affiche un ^I … la place d''une tabulation.');
    WriteLn(' -v                 Utilise des notations ^ et M- pour les caractŠres');
    WriteLn('                    non imprimable');
    WriteLn(' --basic            Permet de d‚compresser l''encodage BASIC');
    WriteLn(' --c                Affiche chacune des lignes en chaŒne de caractŠres C');
    WriteLn(' --help             Affiche l''aide de cette commande');
    WriteLn(' --hex              Affiche chacune des lignes en hexad‚cimal');
    WriteLn(' --html             Affiche chacune des lignes en HTML');
    WriteLn(' --lower            Met en minuscule chacune des lignes');
    WriteLn(' --number           Affiche les num‚ros de ligne');
    WriteLn(' --number-nonblank  Affiche les num‚ros de ligne si la ligne n''est pas vide');
    WriteLn(' --pascal           Affiche chacune des lignes en chaŒne de caractŠres Pascal');
    WriteLn(' --show-all         Equivalent de -vET');
    WriteLn(' --show-nonprinting Utilise des notations ^ et M- pour les caractŠres');
    WriteLn('                    non imprimable');
    WriteLn(' --show-tabs        Affiche un ^I … la place d''une tabulation.');
    WriteLn(' --squeeze-blank    EnlŠve les duplications de ligne blanche');
    WriteLn(' --trim             EnlŠve les espaces au d‚but … la fin de chacun des lignes');
    WriteLn(' --uniq             Affiche une fois les lignes dupliqu‚');
    WriteLn(' --upper            Met en majuscule chacune des lignes');
    WriteLn(' --version          Demande la version de la commande');
   End;
  End;
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('CAT 2.1 - Clone Pascal de coreutils, linux, unix ou corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('crit par Sylvain Maltais');
 End
  Else
 If ParamCount>0Then Begin
  ReadFromConsole:=True;
  ModeParam:=[];
  LastLine:='';
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='-E'Then Include(ModeParam,ShowEnd) Else
   If(ParamStr(I)='-A')or(ParamStr(I)='--show-all')Then Begin
    Include(ModeParam,ShowNonprinting);
    Include(ModeParam,ShowEnd);
    Include(ModeParam,ShowTab)
   End
    Else
   If(ParamStr(I)='--c')Then Include(ModeParam,CStr) Else
   If(ParamStr(I)='-e')Then Begin
    Include(ModeParam,ShowNonprinting);
    Include(ModeParam,ShowEnd);
   End
    Else
   If(ParamStr(I)='--hex')Then Include(ModeParam,Hex) Else
   If(ParamStr(I)='--html')Then Include(ModeParam,Html) Else
   If(ParamStr(I)='--lower')Then Include(ModeParam,Lower) Else
   If(ParamStr(I)='-n')or(ParamStr(I)='--number')Then Include(ModeParam,Number)Else
   If(ParamStr(I)='-b')or(ParamStr(I)='--number-nonblank')Then Include(ModeParam,NumberNonblank)Else
   If(ParamStr(I)='--pascal')Then Include(ModeParam,PascalStr) Else
   If(ParamStr(I)='--basic')Then Include(ModeParam,Basic) Else
   If(ParamStr(I)='-v')or(ParamStr(I)='--show-nonprinting')Then Include(ModeParam,ShowNonprinting)Else
   If(ParamStr(I)='-T')or(ParamStr(I)='--show-tabs')Then Include(ModeParam,ShowTab) Else
   If(ParamStr(I)='-s')or(ParamStr(I)='--squeeze-blank')Then Include(ModeParam,SqueezeBlank)Else
   If(ParamStr(I)='--trim')Then Include(ModeParam,TrimLine) Else
   If(ParamStr(I)='--uniq')Then Include(ModeParam,Uniq) Else
   If(ParamStr(I)='--upper')Then Include(ModeParam,Upper);
  End;
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='-A')or(ParamStr(I)='--show-all')or
     (ParamStr(I)='--basic')or
     (ParamStr(I)='--c')or
     (ParamStr(I)='-E')or(ParamStr(I)='-e')or(ParamStr(I)='-u')or
     (ParamStr(I)='--hex')or
     (ParamStr(I)='--html')or
     (ParamStr(I)='--lower')or
     (ParamStr(I)='-n')or(ParamStr(I)='--number')or
     (ParamStr(I)='-b')or(ParamStr(I)='--number-nonblank')or
     (ParamStr(I)='--pascal')or
     (ParamStr(I)='-v')or(ParamStr(I)='--show-nonprinting')or
     (ParamStr(I)='-T')or(ParamStr(I)='--show-tabs')or
     (ParamStr(I)='--trim')or
     (ParamStr(I)='-s')or(ParamStr(I)='--squeeze-blank')or
     (ParamStr(I)='--uniq')or
     (ParamStr(I)='--upper')Then Begin
    { Saute ... }
   End
    Else
   Begin
    Found:=False;
    CurrDir:=Path2Dir(FExpand(ParamStr(I)));
    FindFirst(ParamStr(I),AnyFile,Info);
    While DOSError=0 do Begin
     Found:=True;
     ReadFromConsole:=False;
     If(Basic)in(ModeParam)Then CatBASIC(CurrDir+Info.Name)
      Else
     Begin
      Assign(Handle,CurrDir+Info.Name);
      {$I-}Reset(Handle);{$I+}
      If IOResult=0Then Begin
       LineNumber:=0;
       While NOT EOF(Handle)do Begin
        ReadLn(Handle,CurrLine);
        ProcessLine;
       End;
       Close(Handle);
      End
       Else
      Begin
       Write('cat: ');
       Write(ParamStr(I));
       Case Language of
        _English:WriteLn('Unable to read file');
        Else WriteLn('Impossible de lire le fichier');
       End;
       Halt(1);
      End;
     End;
     FindNext(Info);
    End;
    If Not(Found)Then Begin
     Write('cat: ');
     Write(ParamStr(I));
     Case Language of
      _English:WriteLn('No such file or directory');
      Else WriteLn(': Aucune correspondance de fichier ou de r‚pertoire.');
     End;
     Halt(2);
    End;
   End;
  End;
  If(ReadFromConsole)Then Begin
   LineNumber:=0;
   Repeat
    ReadLn(Input,CurrLine);
    ProcessLine;
   Until EOF;
  End;
 End
  Else
 Begin
  Repeat
   ReadLn(Input,CurrLine);
   WriteLn(CurrLine);
  Until EOF;
 End;
END.
