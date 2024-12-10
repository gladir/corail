{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program Token2Bas;

{$N+}

Label RFGW,RF0,RF1;

Const
 GWBASIC_FD:Array[$81..$86]of String[4]=(
  { $81 } 'CVI',
  { $82 } 'CVS',
  { $83 } 'CVD',
  { $84 } 'MKI$',
  { $85 } 'MKS$',
  { $86 } 'MKD$'
 );

 GWBASIC_FE:Array[$81..$A1]of String[10]=(
  { $81 } 'FILES',
  { $82 } 'FIELD',
  { $83 } 'SYSTEM',
  { $84 } 'NAME',
  { $85 } 'LSET',
  { $86 } 'RSET',
  { $87 } 'KILL',
  { $88 } 'PUT',
  { $89 } 'GET',
  { $8A } 'RESET',
  { $8B } 'COMMON',
  { $8C } 'CHAIN',
  { $8D } 'DATE$',
  { $8E } 'TIME$',
  { $8F } 'PAINT',
  { $90 } 'COM',
  { $91 } 'CIRCLE',
  { $92 } 'DRAW',
  { $93 } 'PLAY',
  { $94 } 'TIMER',
  { $95 } 'ERDEV',
  { $96 } 'IOCTL',
  { $97 } 'CHDIR',
  { $98 } 'MKDIR',
  { $99 } 'RMDIR',
  { $9A } 'SHELL',
  { $9B } 'ENVIRON',
  { $9C } 'VIEW',
  { $9D } 'WINDOW',
  { $9E } 'PMAP',
  { $9F } 'PALETTE',
  { $A0 } 'LCOPY',
  { $A1 } 'CALLS'
 );

Var
 Mode:(None,CocoFileBAS,Coco1FileBAS,GWBASIC);
 Source:File {$IFDEF FPC}Of Byte{$ENDIF};
 Target:Text;
 Pos:Word;
 SourceName,TargetName:String;
 ByteReaded:Word;
 LastB,B:Byte;
 NewLine:Boolean;
 Buffer:Array[0..4]of Byte;
 BufSingle:Single;
 BufDouble:Double;
BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('TOKEN2BAS : Cette commande permet de convertir un fichier de ',
          'TOKEN de BASIC en BASIC ASCII.');
  WriteLn;
  WriteLn('Syntaxe : TOKEN2BAS fichiertoken.BAS fichier.BAS');
 End
  Else
 If ParamCount=2Then Begin
  SourceName:=ParamStr(1);
  TargetName:=ParamStr(2);
  {$I-}Assign(Source,SourceName);
  Reset(Source,1);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier source introuvable');
   Halt;
  End;
  {$I-}Assign(Target,TargetName);
  Rewrite(Target);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de creer le fichier destinataire');
   Close(Source);
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
    WriteLn('Source : GWBASIC');
    BlockRead(Source,Buffer,1,ByteReaded);
    Pos:=Buffer[0];
    BlockRead(Source,Buffer,1,ByteReaded);
    Pos:=Pos+Buffer[0]*256;
    Write(Target,Pos,' ');
    NewLine:=True;
    LastB:=0;
    Repeat
     BlockRead(Source,Buffer,1,ByteReaded);
     B:=Buffer[0];
RFGW:
     Case B of
      0:Begin
       WriteLn(Target);
       BlockRead(Source,Buffer,1,ByteReaded);
       Pos:=Buffer[0];
       BlockRead(Source,Buffer,1,ByteReaded);
       Pos:=Pos+Buffer[0]*256;
       BlockRead(Source,Buffer,1,ByteReaded);
       If(Pos=0)and(Buffer[0]=26)Then Break;
       Pos:=Buffer[0];
       BlockRead(Source,Buffer,1,ByteReaded);
       Pos:=Pos+Buffer[0]*256;
       Write(Target,Pos,' ');
       NewLine:=True;
      End;
      $0C:Write(Target,'&H');
      $0F:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       Write(Target,Buffer[0]);
      End;
      $11..$1A:Begin
       Write(Target,Char(Buffer[0]+31));
      End;
      $1C:Begin
       BlockRead(Source,Buffer,2,ByteReaded);
       Write(Target,Buffer[0]+Buffer[1]*256);
      End;
      $1D:Begin
       BlockRead(Source,BufSingle,4,ByteReaded);
       Write(Target,BufSingle);
      End;
      $1F:Begin
       BlockRead(Source,BufDouble,4,ByteReaded);
       Write(Target,BufDouble);
      End;
      $3A:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       Case Buffer[0]of
        $20:Begin
         BlockRead(Source,Buffer,1,ByteReaded);
         If Buffer[0]=32Then Write(Target,'GOSUB')
                        Else Write(Target,#$3A,#32,Buffer[0]);
        End;
        $8F:Begin
         LastB:=B;
         B:=Buffer[0];
         Goto RFGW;
        ENd;
        $A1:Write(Target,'ELSE');
        Else Begin
         Write(Target,Char(B));
         LastB:=B;
         B:=Buffer[0];
         Goto RFGW;
        End;
       End;
      End;
      $81:Write(Target,'END');
      $82:Write(Target,'FOR');
      $83:Write(Target,'NEXT');
      $84:Write(Target,'DATA');
      $85:Write(Target,'INPUT');
      $86:Write(Target,'DIM');
      $87:Write(Target,'READ');
      $88:Write(Target,'RND');
      $89:Write(Target,'GOTO');
      $8A:Write(Target,'RUN');
      $8B:Write(Target,'IF');
      $8C:Write(Target,'RESTORE');
      $8D:Write(Target,'GOSUB');
      $8E:Write(Target,'RETURN');
      $8F:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       Case Buffer[0]of
        $D9:Begin
         Write(Target,'''');
         While Not EOF(Source)do Begin
          BlockRead(Source,Buffer,1,ByteReaded);
          If Buffer[0]=0Then Begin
           B:=Buffer[0];
           Goto RFGW;
          End;
          Write(Target,Char(Buffer[0]));
         End;
        End;
        Else Begin
         Write(Target,'REM');
         While Not EOF(Source)do Begin
          BlockRead(Source,Buffer,1,ByteReaded);
          If Buffer[0]=0Then Begin
           B:=Buffer[0];
           Goto RFGW;
          End;
          Write(Target,Char(Buffer[0]));
         End;
        End;
       End;
      End;
      $90:Write(Target,'STOP');
      $91:Write(Target,'PRINT');
      $92:Write(Target,'CLEAR');
      $93:Write(Target,'LIST');
      $94:Write(Target,'NEW');
      $95:Write(Target,'ON');
      $96:Write(Target,'WAIT');
      $97:Write(Target,'DEF');
      $98:Write(Target,'POKE');
      $99:Write(Target,'CONT');
      $9C:Write(Target,'OUT');
      $9D:Write(Target,'LPRINT');
      $9E:Write(Target,'LLIST');
      $A0:Write(Target,'WIDTH');
      $A1:Write(Target,'ELSE');
      $A2:Write(Target,'TRON');
      $A3:Write(Target,'TROFF');
      $A4:Write(Target,'SWAP');
      $A5:Write(Target,'ERASE');
      $A6:Write(Target,'EDIT');
      $A7:Write(Target,'ERROR');
      $A8:Write(Target,'RESUME');
      $A9:Write(Target,'DELETE');
      $AA:Write(Target,'AUTO');
      $AB:Write(Target,'RENUM');
      $AC:Write(Target,'DEFSTR');
      $AD:Write(Target,'DEFINT');
      $AE:Write(Target,'DEFSNG');
      $AF:Write(Target,'DEFDBL');
      $B0:Write(Target,'LINE');
      $B1:Write(Target,'WHILE');
      $B2:Write(Target,'WEND');
      $B3:Write(Target,'CALL');
      $B7:Write(Target,'WRITE');
      $B8:Write(Target,'OPTION');
      $B9:Write(Target,'RANDOMIZE');
      $BA:Write(Target,'OPEN');
      $BB:Write(Target,'CLOSE');
      $BC:Write(Target,'LOAD');
      $BD:Write(Target,'MERGE');
      $BE:Write(Target,'SAVE');
      $BF:Write(Target,'COLOR');
      $C0:Write(Target,'CLS');
      $C1:Write(Target,'MOTOR');
      $C2:Write(Target,'BSAVE');
      $C3:Write(Target,'BLOAD');
      $C4:Write(Target,'SOUND');
      $C5:Write(Target,'BEEP');
      $C6:Write(Target,'PSET');
      $C7:Write(Target,'PRESET');
      $C8:Write(Target,'SCREEN');
      $C9:Write(Target,'KEY');
      $CA:Write(Target,'LOCATE');
      $CC:Write(Target,'TO');
      $CD:Write(Target,'THEN');
      $CF:Write(Target,'STEP');
      $D0:Write(Target,'USR');
      $D1:Write(Target,'FN');
      $D2:Write(Target,'SPC');
      $D3:Write(Target,'NOT');
      $D4:Write(Target,'ERL');
      $D5:Write(Target,'ERR');
      $D6:Write(Target,'STRING$');
      $D7:Write(Target,'USING');
      $D8:Write(Target,'INSTR');
      $D9:Write(Target,'''');
      $DA:Write(Target,'VARPTR');
      $DB:Write(Target,'CSRLIN');
      $DC:Write(Target,'POINT');
      $DD:Write(Target,'OFF');
      $DE:Write(Target,'INKEY$');
      $E6:Write(Target,'>');
      $E7:Write(Target,'=');
      $E8:Write(Target,'<');
      $E9:Write(Target,'+');
      $EA:Write(Target,'-');
      $EB:Write(Target,'*');
      $EC:Write(Target,'/');
      $EE:Write(Target,'AND');
      $EF:Write(Target,'OR');
      $F0:Write(Target,'XOR');
      $F1:Write(Target,'EQV');
      $F2:Write(Target,'IMP');
      $F3:Write(Target,'MOD');
      $F4:Write(Target,'\');
      $FD:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       Case Buffer[0]of
        $81..$86:Write(Target,GWBASIC_FD[Buffer[0]]);
        $87..$8A:Write(Target,'---');
        $8B:Write(Target,'EXTERR');
        Else Write(Target,Char(Buffer[0]));
       End;
      End;
      $FE:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       Case Buffer[0]of
        $81..$A1:Write(Target,GWBASIC_FE[Buffer[0]]);
        $A2,$A3,$A4,$A6:Write(Target,'---');
        $A5:Write(Target,'PCOPY');
        $A7:Write(Target,'LOCK');
        $A8:Write(Target,'UNLOCK');
        Else Write(Target,Char(Buffer[0]));
       End;
      End;
      $FF:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       Case Buffer[0]of
        $81:Write(Target,'LEFT$');
        $82:Write(Target,'RIGHT$');
        $83:Write(Target,'MID$');
        $84:Write(Target,'SGN');
        $85:Write(Target,'INT');
        $86:Write(Target,'ABS');
        $87:Write(Target,'SQR');
        $88:Write(Target,'RND');
        $89:Write(Target,'SIN');
        $8A:Write(Target,'LOG');
        $8B:Write(Target,'EXP');
        $8C:Write(Target,'COS');
        $8D:Write(Target,'TAN');
        $8E:Write(Target,'ATN');
        $8F:Write(Target,'FRE');
        $90:Write(Target,'INP');
        $91:Write(Target,'POS');
        $92:Write(Target,'LEN');
        $93:Write(Target,'STR$');
        $94:Write(Target,'VAL');
        $95:Write(Target,'ASC');
        $96:Write(Target,'CHR$');
        $97:Write(Target,'PEEK');
        $98:Write(Target,'SPACE$');
        $99:Write(Target,'OCT$');
        $9A:Write(Target,'HEX$');
        $9B:Write(Target,'LPOS');
        $9C:Write(Target,'CINT');
        $9D:Write(Target,'CSNG');
        $9E:Write(Target,'CDBL');
        $9F:Write(Target,'FIX');
        $A0:Write(Target,'PEN');
        $A1:Write(Target,'STICK');
        $A2:Write(Target,'STRIG');
        $A3:Write(Target,'EOF');
        $A4:Write(Target,'LOC');
        $A5:Write(Target,'LOF');
        Else Write(Target,Char(Buffer[0]));
       End;
      End;
      Else Write(Target,Char(Buffer[0]));
     End;
     If B<>0Then NewLine:=False;
     LastB:=B;
    Until EOF(Source);
    Close(Target);
    Close(Source);
   End;
   Coco1FileBAS:Begin
    BlockRead(Source,Buffer,1,ByteReaded);
    BlockRead(Source,Buffer,1,ByteReaded);
    BlockRead(Source,Buffer,1,ByteReaded);
    Pos:=Buffer[0]*256;
    BlockRead(Source,Buffer,1,ByteReaded);
    Pos:=Pos+Buffer[0];
    Write(Target,Pos,' ');
    NewLine:=True;
    LastB:=0;
    Repeat
     BlockRead(Source,Buffer,1,ByteReaded);
     B:=Buffer[0];
RF0:
     Case B of
      0:Begin
       WriteLn(Target);
       BlockRead(Source,Buffer,1,ByteReaded);
       BlockRead(Source,Buffer,1,ByteReaded);

       BlockRead(Source,Buffer,1,ByteReaded);
       Pos:=Buffer[0]*256;
       BlockRead(Source,Buffer,1,ByteReaded);
       Pos:=Pos+Buffer[0];
       Write(Target,Pos,' ');
       NewLine:=True;
      End;
      $3A:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       Case Buffer[0]of
        $83:Write(Target,'''');
        $84:Write(Target,'ELSE');
        $92:Write(Target,'POKE');
        Else Begin
         Write(Target,':');
         LastB:=B;B:=Buffer[0];
         Goto RF0;
        End;
       End;
      End;
      $80:Write(Target,'FOR');
      $81:Write(Target,'GO');
      $82:Write(Target,'REM');
      $83:Write(Target,'''');
      $84:Write(Target,'ELSE');
      $85:Write(Target,'IF');
      $86:Write(Target,'DATA');
      $87:Write(Target,'PRINT');
      $88:Write(Target,'ON');
      $89:Write(Target,'INPUT');
      $8A:Write(Target,'END');
      $8B:Write(Target,'NEXT');
      $8C:Write(Target,'DIM');
      $8D:Write(Target,'READ');
      $8E:Write(Target,'RUN');
      $8F:Write(Target,'RESTORE');
      $90:Write(Target,'RETURN');
      $91:Write(Target,'STOP');
      $92:Write(Target,'POKE');
      $93:Write(Target,'CONT');
      $94:Write(Target,'LIST');
      $95:Write(Target,'CLEAR');
      $96:Write(Target,'NEW');
      $97:Write(Target,'CLOAD');
      $98:Write(Target,'CSAVE');
      $99:Write(Target,'OPEN');
      $9A:Write(Target,'CLOSE');
      $9B:Write(Target,'LLIST');
      $9C:Write(Target,'SET');
      $9D:Write(Target,'RESET');
      $9E:Write(Target,'CLS');
      $9F:Write(Target,'MOTOR');
      $A0:Write(Target,'SOUND');
      $A1:Write(Target,'AUDIO');
      $A2:Write(Target,'EXEC');
      $A3:Write(Target,'SKIPF');
      $A4:Write(Target,'TAB(');
      $A5:Write(Target,'TO');
      $A6:Write(Target,'SUB');
      $A7:Write(Target,'THEN');
      $A8:Write(Target,'NOT');
      $A9:Write(Target,'STEP');
      $AA:Write(Target,'OFF');
      $AB:Write(Target,'+');
      $AC:Write(Target,'-');
      $AD:Write(Target,'*');
      $AE:Write(Target,'/');
      $AF:Write(Target,'^');
      $B0:Write(Target,'AND');
      $B1:Write(Target,'OR');
      $B2:Write(Target,'>');
      $B3:Write(Target,'=');
      $B4:Write(Target,'<');
      $B5:Write(Target,'DEL');
      $B6:Write(Target,'EDIT');
      $B7:Write(Target,'TRON');
      $B8:Write(Target,'TROFF');
      $B9:Write(Target,'DEF');
      $BA:Write(Target,'LET');
      $BB:Write(Target,'LINE');
      $BC:Write(Target,'PCLS');
      $BD:Write(Target,'PSET');
      $BE:Write(Target,'PRESET');
      $BF:Write(Target,'SCREEN');
      $C0:Write(Target,'PCLEAR');
      $C1:Write(Target,'COLOR');
      $C2:Write(Target,'CIRCLE');
      $C3:Write(Target,'PAINT');
      $C4:Write(Target,'GET');
      $C5:Write(Target,'PUT');
      $C6:Write(Target,'DRAW');
      $C7:Write(Target,'PCOPY');
      $C8:Write(Target,'PMODE');
      $C9:Write(Target,'PLAY');
      $CA:Write(Target,'DLOAD');
      $CB:Write(Target,'RENUM');
      $CC:Write(Target,'FN');
      $CD:Write(Target,'USING');
      $CE:Write(Target,'DIR');
      $CF:Write(Target,'DRIVE');
      $D0:Write(Target,'FIELD');
      $D1:Write(Target,'FILES');
      $D2:Write(Target,'KILL');
      $D3:Write(Target,'LOAD');
      $D4:Write(Target,'LSET');
      $D5:Write(Target,'MERGE');
      $D6:Write(Target,'RENAME');
      $D7:Write(Target,'RSET');
      $D8:Write(Target,'SAVE');
      $D9:Write(Target,'WRITE');
      $DA:Write(Target,'VERIFY');
      $DB:Write(Target,'UNLOAD');
      $DC:Write(Target,'DSKINI');
      $DD:Write(Target,'BACKUP');
      $DE:Write(Target,'COPY');
      $DF:Write(Target,'DSKI$');
      $E0:Write(Target,'DSKO$');
      $E3:Write(Target,'PALETTE');
      $E4:Write(Target,'HSCREEN');
      $E6:Write(Target,'HCLS');
      $E7:Write(Target,'HCOLOR');
      $E9:Write(Target,'HCIRCLE');
      $EA:Write(Target,'HLINE');
      $EB:Write(Target,'HGET');
      $EC:Write(Target,'HPUT');
      $ED:Write(Target,'HBUFF');
      $EE:Write(Target,'HPRINT');
      $F0:Write(Target,'BRK');
      $F1:Write(Target,'LOCATE');
      $F7:Write(Target,'RGB');
      $FF:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       Case Buffer[0]of
        $80:Write(Target,'SGN');
        $81:Write(Target,'INT');
        $82:Write(Target,'ABS');
        $83:Write(Target,'USR');
        $84:Write(Target,'RND');
        $85:Write(Target,'SIN');
        $86:Write(Target,'PEEK');
        $87:Write(Target,'LEN');
        $88:Write(Target,'STR$');
        $89:Write(Target,'VAL');
        $8A:Write(Target,'ASC');
        $8B:Write(Target,'CHR$');
        $8C:Write(Target,'EOF');
        $8D:Write(Target,'JOYSTK');
        $8E:Write(Target,'LEFT$');
        $8F:Write(Target,'RIGHT$');
        $90:Write(Target,'MID$');
        $91:Write(Target,'POINT');
        $92:Write(Target,'INKEY$');
        $93:Write(Target,'MEM');
        $94:Write(Target,'ATN');
        $95:Write(Target,'COS');
        $96:Write(Target,'TAN');
        $97:Write(Target,'EXP');
        $98:Write(Target,'FIX');
        $99:Write(Target,'LOG');
        $9A:Write(Target,'POS');
        $9B:Write(Target,'SQR');
        $9C:Write(Target,'HEX$');
        $9D:Write(Target,'VARPTR');
        $9E:Write(Target,'INSTR');
        $9F:Write(Target,'TIMER');
        $A0:Write(Target,'PPOINT');
        $A1:Write(Target,'STRING$');
        $A2:Write(Target,'CVN');
        $A3:Write(Target,'FREE');
        $A4:Write(Target,'LOC');
        $A5:Write(Target,'LOF');
        $A6:Write(Target,'MKN$');
        Else Write(Target,Char(Buffer[0]));
       End;
      End;
      Else Write(Target,Char(Buffer[0]));
     End;
     If B<>0Then NewLine:=False;
     LastB:=B;
    Until EOF(Source);
    Close(Target);
    Close(Source);
   End;
   CocoFileBAS:Begin
    WriteLn('Source : Color Computer');
    BlockRead(Source,Buffer,1,ByteReaded);
    BlockRead(Source,Buffer,1,ByteReaded);
    BlockRead(Source,Buffer,1,ByteReaded);
    Pos:=Buffer[0]*256;
    BlockRead(Source,Buffer,1,ByteReaded);
    Pos:=Pos+Buffer[0];
    Write(Target,Pos,' ');
    NewLine:=True;
    LastB:=0;
    Repeat
     BlockRead(Source,Buffer,1,ByteReaded);
     B:=Buffer[0];
RF1:
     Case B of
      0:Begin
       WriteLn(Target);
       BlockRead(Source,Buffer,1,ByteReaded);
       BlockRead(Source,Buffer,1,ByteReaded);

       BlockRead(Source,Buffer,1,ByteReaded);
       Pos:=Buffer[0]*256;
       BlockRead(Source,Buffer,1,ByteReaded);
       Pos:=Pos+Buffer[0];
       Write(Target,Pos,' ');
       NewLine:=True;
      End;
      $0E,$1C:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       Pos:=Buffer[0]*256;
       BlockRead(Source,Buffer,1,ByteReaded);
       Pos:=Pos+Buffer[0];
       Write(Target,Pos,' ');
      End;
      $0F:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       Write(Target,Buffer[0]);
      End;
      $11..$1A:Begin
       Write(Target,Char(Buffer[0]+31));
      End;
      $3A:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       Case Buffer[0]of
        $C9: Write(Target,'''');
        $D1:Write(Target,'ELSE');
        Else Begin
         Write(Target,':');
         LastB:=B;B:=Buffer[0];
         Goto RF1;
        End;
       End;
      End;
      $80:Write(Target,'TO');
      $81:Write(Target,'X81');
      $82:Write(Target,'*');
      $83:Write(Target,'AND');
      $84:If LastB<>$3AThen Write(Target,'=')
                       Else Write(Target,'FOR');
      $85:Write(Target,'X85');
      $86:Write(Target,'X86');
      $87:Write(Target,'PSET');
      $88:Write(Target,'X88');
      $89:Write(Target,'X89');
      $8A:Write(Target,'PLAY');
      $8B:Write(Target,'X8B');
      $8C:Write(Target,'X8C');
      $8D:Write(Target,'X8D');
      $8E:Write(Target,'X8E');
      $8F:Write(Target,'X8F');
      $90:Write(Target,'X90');
      $91:Write(Target,'X91');
      $92:Write(Target,'WIDTH');
      $93:Write(Target,'PALETTE');
      $94:Write(Target,'HSCREEN');
      $95:Write(Target,'BRK');
      $96:Write(Target,'X96');
      $97:Write(Target,'RGB');
      $98:Write(Target,'X98');
      $99:Write(Target,'X99');
      $9A:Write(Target,'X9A');
      $9B:Write(Target,'X9B');
      $9C:Write(Target,'X9C');
      $9D:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       Case Buffer[0]of
        $B0:Write(Target,'STRING$');
        $D1:Write(Target,'RND');
        $E3:Write(Target,'CHR$');
        $E4:Write(Target,'ASC');
        $E9:Write(Target,'LEFT$');
        $ED:Write(Target,'INKEY$');
        Else Write(Target,Char(Buffer[0]));
       End;
      End;
      $9E:Write(Target,'X9E');
      $9F:Write(Target,'X9F');
      $A0:Write(Target,'XA0');
      $A1:Write(Target,'XA1');
      $A2:Write(Target,'XA2');
      $A3:Write(Target,'XA3');
      $A4:Write(Target,'XA4');
      $A5:Write(Target,'<');
      $A6:Write(Target,'XA6');
      $A7:Write(Target,'XA7');
      $A8:Write(Target,'-');
      $A9:Write(Target,'XA9');
      $AA:Write(Target,'LINE');
      $AB:Write(Target,'XAB');
      $AC:Write(Target,'XAC');
      $AD:Write(Target,'XAD');
      $AE:Write(Target,'XAE');
      $AF:Write(Target,'ATTR');
      $B0:Write(Target,'XB0');
      $B1:Write(Target,'OR');
      $B2:Write(Target,'XB2');
      $B3:Write(Target,'XB3');
      $B4:Write(Target,'+');
      $B5:Write(Target,'XB5');
      $B6:Write(Target,'SUB');
      $B7:Write(Target,'XB7');
      $B8:Write(Target,'XB8');
      $B9:Write(Target,'XB9');
      $BA:Write(Target,'XBA');
      $BB:Write(Target,'XBB');
      $BC:Write(Target,'XBC');
      $BD:Write(Target,'XBD');
      $BE:Write(Target,'>');
      $BF:Write(Target,'PCLEAR');
      $C0:Write(Target,'XC0');
      $C1:Write(Target,'HCOLOR');
      $C2:Write(Target,'XC2');
      $C3:Write(Target,'XC3');
      $C4:Write(Target,'FOR');
      $C5:Write(Target,'GO');
      $C6:Write(Target,'XC6');
      $C7:Write(Target,'REM');
      $C8:Write(Target,'HCIRCLE');
      $C9:Write(Target,'''');
      $CA:Write(Target,'HCLS');
      $CB:Write(Target,'HCIRCLE');
      $CC:Write(Target,'HBUFF');
      $CD:Write(Target,'HLINE');
      $CE:Write(Target,'HGET');
      $CF:Write(Target,'HPUT');
      $D0:Write(Target,'XD0');
      $D1:Write(Target,'ELSE');
      $D2:Write(Target,'LOCATE');
      $D3:Write(Target,'HPRINT');
      $D4:Write(Target,'XD4');
      $D5:Write(Target,'XD5');
      $D6:Write(Target,'IF');
      $D7:Write(Target,'XD7');
      $D8:Write(Target,'XD8');
      $D9:Write(Target,'XD9');
      $DA:Write(Target,'XDA');
      $DB:Write(Target,'XDB');
      $DC:Write(Target,'DATA');
      $DD:Write(Target,'SOUND');
      $DE:Write(Target,'XDE');
      $DF:Write(Target,'THEN');
      $E0:Write(Target,'ON');
      $E1:Write(Target,'PRINT');
      $E2:Write(Target,'INPUT');
      $E3:Write(Target,'NEXT');
      $E4:Write(Target,'XE4');
      $E5:Write(Target,'DIM');
      $E6:Write(Target,'PRESET');
      $E7:Write(Target,'READ');
      $E8:Write(Target,'XE8');
      $E9:Write(Target,'XE9');
      $EA:Write(Target,'RETURN');
      $EB:Write(Target,'XEB');
      $EC:Write(Target,'XEC');
      $ED:Write(Target,'POKE');
      $EE:Write(Target,'XEE');
      $EF:Write(Target,'XEF');
      $F0:Write(Target,'XF0');
      $F1:Write(Target,'XF1');
      $F2:Write(Target,'XF2');
      $F3:Write(Target,'XF3');
      $F4:Write(Target,'XF4');
      $F5:Write(Target,'XF5');
      $F6:Write(Target,'XF6');
      $F7:Write(Target,'XF7');
      $F8:Write(Target,'XF8');
      $F9:Write(Target,'XF9');
      $FA:Write(Target,'XFA');
      $FB:Write(Target,'CLS');
      $FC:Write(Target,'XFC');
      $FD:Write(Target,'XFD');
      $FE:Write(Target,'XFE');
      $FF:Write(Target,'XFF');
      Else Write(Target,Char(Buffer[0]));
     End;
     If B<>0Then NewLine:=False;
     LastB:=B;
    Until EOF(Source);
    Close(Target);
    Close(Source);
   End;
   Else Write('Signature d''encodage non reconnu');
  End;
  WriteLn('Conversion complete.');
 End
  Else
 WriteLn('Parametre invalide !');
END.
