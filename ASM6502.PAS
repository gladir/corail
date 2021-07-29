Program ASM6502;

{$R-}

Const
 Instr6502:Array[0..28]of Record
  InstrName:String[7];
  InstrOpcode:Byte;
 End=(
  (InstrName:'BRK';InstrOpcode:$00),
  (InstrName:'PHP';InstrOpcode:$08),
  (InstrName:'CLC';InstrOpcode:$18),
  (InstrName:'PLP';InstrOpcode:$28),
  (InstrName:'SEC';InstrOpcode:$38),
  (InstrName:'RTI';InstrOpcode:$40),
  (InstrName:'PHA';InstrOpcode:$48),
  (InstrName:'CLI';InstrOpcode:$58),
  (InstrName:'RTS';InstrOpcode:$60),
  (InstrName:'PLA';InstrOpcode:$68),
  (InstrName:'SEI';InstrOpcode:$78),
  (InstrName:'DEY';InstrOpcode:$88),
  (InstrName:'TXA';InstrOpcode:$8A),
  (InstrName:'TYA';InstrOpcode:$98),
  (InstrName:'TXS';InstrOpcode:$9A),
  (InstrName:'TAY';InstrOpcode:$A8),
  (InstrName:'TAX';InstrOpcode:$AA),
  (InstrName:'CLV';InstrOpcode:$B8),
  (InstrName:'TSX';InstrOpcode:$BA),
  (InstrName:'INY';InstrOpcode:$C8),
  (InstrName:'DEX';InstrOpcode:$CA),
  (InstrName:'CLD';InstrOpcode:$D8),
  (InstrName:'INX';InstrOpcode:$E8),
  (InstrName:'NOP';InstrOpcode:$EA),
  (InstrName:'SED';InstrOpcode:$F8),
  (InstrName:'ASLA';InstrOpcode:$0A),
  (InstrName:'ROLA';InstrOpcode:$2A),
  (InstrName:'LSRA';InstrOpcode:$4A),
  (InstrName:'RORA';InstrOpcode:$6A)
 );

 maxSymLen    = 16;
 maxOpcdLen   = 5;
 maxMacParms  = 10;
 symTabCols   = 3;
 white        = #9' ';

 alpha        = ['A'..'Z','a'..'z','@','_'];
 numeric      = ['0'..'9'];
 alphaNumeric = alpha + numeric;

 oIllegal    =   0;
 oImplied    =   1;
 oBranch     =   2;
 oMode       =   3;
 oDB         =   4;
 oDW         =   5;
 oDS         =   6;
 oEQU        =  -7;
 oORG        =  -8;
 oRORG       =  -9;
 oEND        =  10;
 oLIST       = -11;
 oOPT        = -12;
 oMACRO      = -13;
 oENDM       =  14;
 oMacName    =  15;
 oFCC        =  16;

 a_None       =   0;
 a_Imm        =   1;
 a_Abs        =   3;
 a_Zpg        =   5;
 a_Acc        =   7;
 a_Inx        =   9;
 a_Iny        =  11;
 a_Zpx        =  13;
 a_Abx        =  15;
 a_Aby        =  17;
 a_Ind        =  19;
 a_Zpy        =  21;

Type
 SymStr=String[maxSymLen];

 SymPtr=^SymRec;
 SymRec=Record
  SymbolName:SymStr;
  defined:Boolean;
  value:Integer;
  next:SymPtr;
  multiDef:Boolean;
  isSet:Boolean;
  equ:Boolean;
  known:Boolean;
 End;

 MacroLinePtr=^MacroLine;
 MacroLine=Record
  next:MacroLinePtr;
  text:String;
 End;

 MacroParmPtr=^MacroParm;
 MacroParm=Record
  next:MacroParmPtr;
  ParamName:SymStr;
 End;

 MacroPtr=^MacroRec;
 MacroRec=Record
  MacroName:SymStr;
  def:Boolean;
  text:MacroLinePtr;
  next:MacroPtr;
  parms:MacroParmPtr;
  nparms:Integer;
 End;

 OpcdStr=String[maxOpcdLen];
 ModeStr=String[22];

 OpcdPtr=^OpcdRec;
 OpcdRec=Record
  OpcodeName:OpcdStr;
  mode:ModeStr;
  typ:Integer;
  parm:Integer;
  next:OpcdPtr;
 End;

Var
 symTab:SymPtr;
 opcdTab:OpcdPtr;
 macroTab,macPtr:MacroPtr;
 macLine:MacroLinePtr;
 macParms:Array[1..maxMacParms] of String;
 lastLabel:SymStr;

 locPtr:Word;
 codPtr:Word;
 outPtr:Word;
 updLoc:Boolean;
 errFlag:Boolean;
 pass:Integer;
 errCount:Integer;

 CurrLine,ListLine:String;
 listFlag,listMacFlag,macLineFlag,listThisLine,sourceEnd:Boolean;

 instr:Array[1..3] of Integer;
 instrLen:Integer;

 bytStr:String;
 showAddr:Boolean;
 xferAddr:Word;
 xferFound:Boolean;
 evalKnown:Boolean;

 cl_SrcName,cl_ListName,cl_ObjName,cl_BinName:String;
 cl_Err:Boolean;

 source,objet,listing:Text;
 Binary:File of Byte;

Function LTrim(s:String):String;
Var
 i:Integer;
Begin
 i:=1;
 While(i<=Length(s)) and (s[i] in [#9,' ']) do Inc(i);
 Delete(s,1,i-1);
 LTrim:=s;
End;

Function RTrim(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 RTrim:=S;
End;

Function Trim(s:String):String;Begin
 Trim:=LTrim(RTrim(s));
End;

Function StrToUpper(s:String):String;
Var
 i:Integer;
Begin
 For i:=1 to Length(s) do If s[i] in ['a'..'z']Then s[i] := UpCase(s[i]);
 StrToUpper:=s;
End;

Function ByteHex2Str(value:Word):String;
Const
 matrix:Array[0..15]of Char=('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 value:=value and $FF;
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

Procedure Error(ErrorMessage: String);Begin
 errFlag:=True;
 Inc(errCount);
 If pass<>1 Then Begin
  listThisLine:=True;
  WriteLn(listing,'Erreur :  ',ErrorMessage);
  If cl_Err Then WriteLn('Erreur :  ',ErrorMessage);
 End;
End;

Procedure AddMacro(MyName:SymStr;Var macro:MacroPtr);Begin
 New(macro);
 macro^.MacroName:=MyName;
 macro^.def:=FALSE;
 macro^.text:=NIL;
 macro^.next:=macroTab;
 macro^.parms:=NIL;
 macro^.nparms:=0;
 macroTab:=macro;
End;

Procedure AddMacroParam(macro:MacroPtr;MyName:String);
Var
 parm:MacroParmPtr;
 p:MacroParmPtr;
Begin
 New(parm);
 parm^.next:=NIL;
 parm^.ParamName:=StrToUpper(MyName);
 macro^.nparms := macro^.nparms + 1;
 p := macro^.parms;
 If p=NIL Then macro^.parms := parm
  Else
 Begin
  While p^.next<>NIL do p := p^.next;
  p^.next := parm;
 End;
End;

Procedure GetMacParms(macro:MacroPtr);
Var
 i,n,p:Integer;
 s:String;
 done:Boolean;
 parm:MacroParmPtr;
Begin
 For i:=1 to maxMacParms do macParms[i]:='';
  n:=0;
  done:=False;
  Repeat
   i := 1;
   While(i<=Length(CurrLine))and(CurrLine[i]<>';')and(CurrLine[i]<>',') do Begin
    If CurrLine[i]='''' Then Begin
     i:=i+1;
     While (i<=Length(CurrLine))and(CurrLine[i]<>'''') do i := i + 1;
    End;
    i:=i+1;
   End;
   If CurrLine[i]=';' Then done:=True;
   If i<>1 Then Begin
    n:=n+1;
   If n<=maxMacParms Then macParms[n] := Copy(CurrLine,1,i-1);
   Delete(CurrLine,1,i);
  End;
 Until done or(Length(CurrLine)=0);
 If(n>macro^.nparms)or(n>maxMacParms)Then Error('Trop de parametres dans la macro');
 For i:=1 to n do macParms[i]:=Trim(macParms[i]);
 CurrLine:='';
End;

Procedure DoMacParms;
Var
 i,j,n:Integer;
 word:String;
 parm:MacroParmPtr;
Begin
 i:=1;
 While(i<=Length(CurrLine)) do Begin
  While (i<=Length(CurrLine)) and Not(CurrLine[i] IN alpha)do Inc(i);
  If i<=Length(CurrLine) Then Begin
   j := i;
   While(j<=Length(CurrLine))and(CurrLine[j] in alphaNumeric) do Inc(j);
   word:=StrToUpper(Copy(CurrLine,i,j-i));
   parm := macPtr^.parms;
   n := 1;
   While(parm<>NIL)and(parm^.ParamName<>word)do Begin
    parm := parm^.next;
    n:=n+1;
   End;
   If(parm<>NIL)and(n<=maxMacParms)Then Begin
    Delete(CurrLine,i,j-i);
    Insert(macParms[n],CurrLine,i);
    i:=i+Length(macParms[n]);
   End
    Else
   i:=j;
  End;
 End;
End;

Procedure AddMacroLine(macro:MacroPtr;line:String);
Var
 m,p:MacroLinePtr;
Begin
 GetMem(m,SizeOf(MacroLine)-255+Length(line));
 m^.next := NIL;
 Move(line,m^.text,Length(line) + 1);
 p := macro^.text;
 If p=NIL Then macro^.text := m
  Else
 Begin
  While p^.next<>NIL do p := p^.next;
  p^.next := m;
 End;
End;

Procedure FindMacro(MyName:SymStr;Var macro:MacroPtr);
Var
 found:Boolean;
Begin
 macro:=macroTab;
 found:=False;
 While(macro<>NIL)and NOT found do Begin
  found := (macro^.MacroName = MyName);
  If Not found Then macro := macro^.next;
 End;
End;

Procedure AddOpcode(MyName:OpcdStr;mode:ModeStr;typ,parm:Integer);
Var
 p:OpcdPtr;
Begin
 New(p);
 p^.OpcodeName:=MyName;
 p^.mode:=mode;
 p^.typ:=typ;
 p^.parm:=parm;
 p^.next:=opcdTab;
 opcdTab:=p;
End;

Procedure FindOpcode(MyName:String;Var typ,parm:Integer;Var mode:ModeStr;Var macro:MacroPtr);
Var
 p:OpcdPtr;
 found:Boolean;
Begin
 macro:=NIL;
 found:=False;
 p:=opcdTab;
 While (p<>NIL) and Not found do Begin
  found := (p^.OpcodeName = MyName);
  If Not found Then p := p^.next;
 End;
 If Not found Then Begin
  typ:=oIllegal;
  parm:=0;
  mode:='';
  FindMacro(MyName,macro);
  If macro<>NIL Then typ:=oMacName;
 End
  Else
 Begin
  typ:=p^.typ;
  parm:=p^.parm;
  mode:=p^.mode;
 End;
End;

Procedure InitOpcodes;
Var
 I:Byte;
Begin
 opcdTab:=NIL;
 For I:=0 to High(Instr6502)do AddOpcode(Instr6502[I].InstrName,'',oImplied,Instr6502[I].InstrOpcode);

 AddOpcode('BPL','',oBranch,$10);
 AddOpcode('BMI','',oBranch,$30);
 AddOpcode('BVC','',oBranch,$50);
 AddOpcode('BVS','',oBranch,$70);
 AddOpcode('BCC','',oBranch,$90);
 AddOpcode('BCS','',oBranch,$B0);
 AddOpcode('BNE','',oBranch,$D0);
 AddOpcode('BEQ','',oBranch,$F0);

                { ImAbZpAcIxIyZxAxAyInZy }
 AddOpcode('ORA','090D05  0111151D19    ',oMode,0);
 AddOpcode('ASL','  0E060A    161E      ',oMode,0);
 AddOpcode('JSR','  20                  ',oMode,0);
 AddOpcode('AND','292D25  2131353D39    ',oMode,0);
 AddOpcode('BIT','  2C24                ',oMode,0);
 AddOpcode('ROL','  2E262A    363E      ',oMode,0);
 AddOpcode('EOR','494D45  4151555D59    ',oMode,0);
 AddOpcode('LSR','  4E464A    565E      ',oMode,0);
 AddOpcode('JMP','  4C              6C  ',oMode,0);
 AddOpcode('ADC','696D65  6171757D79    ',oMode,0);
 AddOpcode('ROR','  6E666A    767E      ',oMode,0);
 AddOpcode('STA','  8D85  8191959D99    ',oMode,0);
 AddOpcode('STY','  8C84      94        ',oMode,0);
 AddOpcode('STX','  8E86              96',oMode,0);
 AddOpcode('LDY','A0ACA4      B4BC      ',oMode,0);
 AddOpcode('LDA','A9ADA5  A1B1B5BDB9    ',oMode,0);
 AddOpcode('LDX','A2AEA6          BE  B6',oMode,0);
 AddOpcode('CPY','C0CCC4                ',oMode,0);
 AddOpcode('CMP','C9CDC5  C1D1D5DDD9    ',oMode,0);
 AddOpcode('DEC','  CEC6      D6DE      ',oMode,0);
 AddOpcode('CPX','E0ECE4                ',oMode,0);
 AddOpcode('SBC','E9EDE5  E1F1F5FDF9    ',oMode,0);
 AddOpcode('INC','  EEE6      F6FE      ',oMode,0);

 AddOpcode('DB'   ,'',oDB ,0);
 AddOpcode('FCB'  ,'',oDB ,0);
 AddOpcode('BYTE' ,'',oDB ,0);
 AddOpcode('DW'   ,'',oDW ,0);
 AddOpcode('FDB'  ,'',oDW ,0);
 AddOpcode('WORD' ,'',oDW ,0);
 AddOpcode('DS'   ,'',oDS ,0);
 AddOpcode('RMB'  ,'',oDS ,0);
 AddOpcode('BLKB' ,'',oDS ,0);
 AddOpcode('FCC'  ,'',oFCC,0);

 AddOpcode('='    ,'',oEQU,0);
 AddOpcode('EQU'  ,'',oEQU,0);
 AddOpcode('SET'  ,'',oEQU,1);

 AddOpcode('ORG'  ,'',oORG  ,0);
 AddOpcode('AORG' ,'',oORG  ,0);
 AddOpcode('RORG' ,'',oRORG ,0);
 AddOpcode('END'  ,'',oEND  ,0);
 AddOpcode('LIST' ,'',oLIST ,0);
 AddOpcode('OPT'  ,'',oOPT  ,0);
 AddOpcode('MACRO','',oMACRO,0);
 AddOpcode('ENDM' ,'',oENDM ,0);
End;

Function FindSym(symName:SymStr):SymPtr;
Var
 p:SymPtr;
 found:Boolean;
Begin
 found:=False;
 p:=SymTab;
 While(p<>NIL)and Not Found do Begin
  found:=(p^.SymbolName=symName);
  If Not found Then p := p^.next;
 End;
 FindSym:=p;
End;

Function AddSym(symName:SymStr):SymPtr;
Var
 p:SymPtr;
Begin
 New(p);
 With p^ do Begin
  SymbolName:=SymName;
  value:=0;
  next:=SymTab;
  defined:=False;
  multiDef:=False;
  isSet:=False;
  equ:=False;
  known:=False;
 End;
 symTab:=p;
 AddSym:=p;
End;

Function RefSym(symName:SymStr;Var known:Boolean):Integer;
Var
 p:SymPtr;
Begin
 p:=FindSym(symName);
 If p=NIL Then p:=AddSym(symName);
 If Not p^.defined Then Error('Symbole "'+symName+'" non-defini');
 RefSym:=p^.value;
 Case pass of
  1:If Not p^.defined Then known:=False;
  2:If Not p^.known   Then known:=False;
 End;
End;

Procedure DefSym(symName:SymStr;val:Integer;setSym,equSym:Boolean);
Var
 p:SymPtr;
Begin
 If Length(symName)<>0 Then Begin
  p:=FindSym(symName);
  If p=NIL Then p:=AddSym(symName);
  If (Not p^.defined) or (p^.isSet and setSym)Then Begin
   p^.value:=val;
   p^.defined:=True;
   p^.isSet:=setSym;
   p^.equ:=equSym;
  End
   Else
  If p^.value<>val Then Begin
   p^.multiDef:=True;
   Error('Symbole "'+symName+'" definie de multiple fois');
  End;
  If pass=2 Then p^.known:=True;
 End;
End;

Function GetWord:String;
Var
 word:String;
 done:Boolean;
Begin
 CurrLine:=Trim(CurrLine);
 word:='';
 If Length(CurrLine)>0 Then
  If(CurrLine[1]=#12)or(CurrLine[1]=';')Then CurrLine:='';
 If Length(CurrLine)>0 Then Begin
  If Not(CurrLine[1] in alphaNumeric)Then Begin
   word := Copy(CurrLine,1,1);
   Delete(CurrLine,1,1);
   If Length(CurrLine)>0 Then Begin
    If((word[1]='<')and(CurrLine[1]='<'))or((word[1]='>')and(CurrLine[1]='>'))Then Begin
     word:=word+Copy(CurrLine,1,1);
     Delete(CurrLine,1,1);
    End;
   End;
  End
   Else
  Begin
   done:=False;
   While(Length(CurrLine)>0) and Not done do Begin
    word:=word+Upcase(CurrLine[1]);
    Delete(CurrLine,1,1);
    If Length(CurrLine)>0 Then done:=Not(CurrLine[1] in alphaNumeric);
   End;
  End;
 End;
 GetWord := StrToUpper(word);
END;

Procedure Expect(expected:String);Begin
 If GetWord<>expected Then Error('"' + expected + '" attendue');
End;

Function EvalBin(binStr:String):Integer;
Var
 binVal,i,n:Integer;
 evalErr:Boolean;
Begin
 evalErr:=False;
 binVal:=0;
 For i:=1 to Length(binStr) do Begin
  n:=Pos(binStr[i],'01');
  If n=0 Then evalErr := True
         Else binVal  := binVal*2 + n-1;
 End;
 If evalErr Then Begin
  binVal:=0;
  Error('Nombre octal invalide');
 End;
 EvalBin := binVal;
End;

Function EvalOct(octStr:String):Integer;
Var
 octVal,i,n:Integer;
 evalErr:Boolean;
Begin
 evalErr:=False;
 octVal:=0;
 For i:=1 to Length(octStr) do Begin
  n:=Pos(octStr[i],'01234567');
  If n=0 Then evalErr:=True
         Else octVal:=octVal*8+n-1;
 End;
 If evalErr Then Begin
  octVal:=0;
  Error('Nombre octal invalide');
 End;
 EvalOct:=octVal;
End;

Function EvalDec(decStr:String):Integer;
Var
 decVal,i,n:Integer;
 evalErr:Boolean;
Begin
 evalErr:=False;
 decVal:=0;
 For i:=1 to Length(decStr) do Begin
  n:=Pos(decStr[i],'0123456789');
  If n=0 Then evalErr:=True
         Else decVal:=decVal*10+n-1;
 End;
 If(evalErr)Then Begin
  decVal := 0;
  Error('Nombre decimal invalide');
 End;
 EvalDec:=decVal;
End;

Function EvalHex(hexStr:String):Integer;
Var
 hexVal,i,n:Integer;
 evalErr:Boolean;
Begin
 evalErr:=False;
 hexVal:=0;
 For i:=1 TO Length(hexStr)do Begin
  n:=Pos(Upcase(hexStr[i]),'0123456789ABCDEF');
  If n=0 Then evalErr:=True
         Else hexVal:=hexVal*16+n-1;
 End;
 If(evalErr)Then Begin
  hexVal:=0;
  Error('Nombre hexadecimal invalide');
 END;
 EvalHex:=hexVal;
End;

Function Eval0:Integer; Forward;

Function Factor:Integer;
Var
 word:String;
 val:Integer;
Begin
 word:=GetWord;
 val:=0;
 If Length(word)=0 Then Error('Operande attendue') Else
 If (word='.')or(word='*')Then val := locPtr Else
 If word='-'Then val:=-Factor Else
 If word='+'Then val:=Factor Else
 If word='~'Then val:=-Factor-1 Else
 If word='<'Then val:=Factor and 255 Else
 If word='>'Then val:=(Factor shr 8) and 255 Else
 If word='%'Then Begin
  Word:=GetWord;
  val:=EvalBin(word);
 End
  Else
 If word='$'Then Begin
  Word:=GetWord;
  If Length(word)=0 Then val:=locPtr
                    Else val:=EvalHex(word);
 End
  Else
 If word='('Then Begin
  val:=Eval0;
  Expect(')');
 End
  Else
 If word=''''Then Begin
  If Length(CurrLine)=0 Then Error('Operande attendue')
   Else
  Begin
   val:=Ord(CurrLine[1]);
   Delete(CurrLine,1,1);
   Expect('''');
  End;
 End
  Else
 If word[1]='@'Then val:=RefSym(lastLabel+word,evalKnown)Else
 If word[1] in numeric Then Begin
  Case word[Length(word)] of
   'O': val:=EvalOct(Copy(word,1,Length(word)-1));
   'D': val:=EvalDec(Copy(word,1,Length(word)-1));
   'H': val:=EvalHex(Copy(word,1,Length(word)-1));
   'B': val:=EvalBin(Copy(word,1,Length(word)-1));
   Else val:=EvalDec(word);
  End;
 End
  Else
 val:=RefSym(word,evalKnown);
 Factor:=val;
End;

Function Term:Integer;
Var
 word:String;
 val:Integer;
 oldLine:String;
Begin
 val:=Factor;
 oldLine:=CurrLine;
 word:=GetWord;
 While(word='*')or(word='/')or(word='%')do Begin
  Case word[1]of
   '*': val:=val * Factor;
   '/': val:=val div Factor;
   '%': val:=val mod Factor;
  End;
  oldLine:=CurrLine;
  word:=GetWord;
 End;
 CurrLine:=oldLine;
 Term:=val;
End;

Function Eval1:Integer;
Var
 val:Integer;
 word,oldLine:String;
Begin
 val:=Term;
 oldLine:=CurrLine;
 word:=GetWord;
 While (word='+')or(word='-') do Begin
  Case word[1] of
   '+': val:=val+Term;
   '-': val:=val-Term;
  End;
  oldLine := CurrLine;
  word := GetWord;
 End;
 CurrLine := oldLine;
 Eval1 := val;
End;

Function Eval0:Integer;
Var
 word:String;
 val:Integer;
 oldLine:String;
Begin
 val:=Eval1;
 oldLine:=CurrLine;
 word:=GetWord;
 While(word='&')or(word='|')or(word='<<')or(word='>>')do Begin
  Case word[1] of
   '&':val:=val and Eval1;
   '|':val:=val or Eval1;
   '<':val:=val shl Eval1;
   '>':val:=val shr Eval1;
  End;
  oldLine:=CurrLine;
  word:=GetWord;
 End;
 CurrLine:=oldLine;
 Eval0:=val;
End;

Function Eval:Integer;Begin
 evalKnown:=True;
 Eval:=Eval0;
End;

Function EvalByte:Integer;
Var
 val:Integer;
Begin
 val:=Eval;
 If(val<-128)or(val>255)Then Error('Octet en dehors de l''intervalle');
 EvalByte:=val and 255;
End;

Function FindReg(regName,regList,valList:String):Integer;
Var
 p,reg,code:Integer;
Begin
 p:=Pos(' '+Trim(regName)+' ',regList);
 If p=0 Then Begin
  reg := 0;
  Error('Registre non autorise "'+Trim(RegName)+'"');
 End
  Else
 Val(Copy(valList,p,2),reg,code);
 FindReg := reg;
End;

Procedure CodeOut(_byte:Integer);Begin
 If (pass=2) and updLoc Then Begin
  WriteLn(objet,':',HexWord2Str(codPtr));
  outPtr := codPtr;
  updLoc := FALSE;
 End;
 outPtr := outPtr + 1;
 If pass=2 Then Begin
  WriteLn(objet,ByteHex2Str(_byte));
  Write(Binary,Byte(_byte));
 End;
End;

Procedure AddLocPtr(ofs:Word);Begin
 updLoc := updLoc or (codPtr+ofs<>outPtr);
 codPtr := codPtr + ofs;
 locPtr := locPtr + ofs;
End;

Procedure CodeAbsOrg(addr:Word);Begin
 updLoc := updLoc or (addr<>outPtr);
 locPtr := addr;
 codPtr := addr;
End;

Procedure CodeRelOrg(addr: Word);Begin
 locPtr := addr;
End;

Procedure CodeEnd;Begin
 If (pass=2) and xferFound Then WriteLn(objet,'$',HexWord2Str(xferAddr));
End;

Procedure CodeXfer(addr:Integer);Begin
 xferAddr  := addr;
 xferFound := True;
End;

Procedure DoOpcode(typ,parm:Integer;modes:String;macro:MacroPtr);
Var
 val:Integer;
 word:String;
 oldLine:String;
 mode:Integer;
 ch:Char;
 done:Boolean;
Begin
 Case typ of
  oImplied:Begin
   instr[1]:=parm;
   instrLen:=1;
  End;
  oBranch:Begin
   val:=Eval;
   val:=val-locPtr-2;
   If(val<-128)or(val>127)Then Begin
    Error('Branchement en dehors de l''intervalle');
    val:=0;
   End;
   instr[1]:=parm;
   instr[2]:=val;
   instrLen:=2;
  End;
  oMode:Begin
   CurrLine:=Trim(CurrLine);
   mode:=a_None;
   val:=0;
   If Length(CurrLine)=0 Then mode:=a_Acc Else
   Case CurrLine[1]of
    ';':mode:=a_Acc;
    '#':Begin
     Expect('#');
     val:=Eval;
     mode:=a_Imm;
    End;
    '[':Begin
     Expect('[');
     val:=Eval;
     Expect(']');
     mode:=a_Ind;
    End;
    '(':Begin
     Expect('(');
     val:=Eval;
     CurrLine:=Trim(CurrLine);
     If Length(CurrLine)>0 Then Case CurrLine[1]of
      ',':Begin
       Expect(',');
       Expect('X');
       Expect(')');
       mode:=a_Inx;
      End;
      ')':Begin
       Expect(')');
       CurrLine:=LTrim(CurrLine);
       If(Length(CurrLine)=0)or(CurrLine[1]=';')Then Begin
        mode:=a_Ind;
       End
        Else
       Begin
        Expect(',');
        Expect('Y');
        mode:=a_Iny;
       End;
      End;
      Else mode:=a_None;
     End;
    End;
    Else Begin
     CurrLine:=Trim(CurrLine);
     If(Upcase(CurrLine[1])='A')and((Length(CurrLine)=1)or
       ((Length(CurrLine)>1)and((CurrLine[2]=';')or
       (Pos(CurrLine[2],white)<>0))))Then Begin
      Expect('A');
      mode:=a_Acc;
     End
      Else
     Begin
      val:=Eval;
      CurrLine:=Trim(CurrLine);
      If(Length(CurrLine)=0)or(CurrLine[1]=';')Then
       If(val>=0)and(val<256)and evalKnown and(modes[a_Zpg]<>' ')Then mode:=a_Zpg
                                                                 Else mode:=a_Abs
      Else Begin
       Expect(',');
       word:=GetWord;
       If word='X' Then Begin
        If(val>=0)and(val<256)and(evalKnown or(modes[a_Abx]=' '))Then mode:=a_Zpx
                                                                 Else mode:=a_Abx;
       End
        Else
       IF word='Y' Then
        If(val>=0)and(val<256)and(evalKnown or(modes[a_Aby]=' '))and(modes[a_Zpy]<>' ')Then mode:=a_Zpy
                                                                                       Else mode:=a_Aby
      End;
     End;
    End;
   End;
   If(mode<>a_None)and(modes[mode]=' ')Then mode:=a_None;
   If mode<>a_None Then Begin
    word:=Copy(modes,mode,2);
    instr[1]:=EvalHex(word);
   End;
   instrLen:=0;
   Case mode of
    a_None:Error('Mode d''adressage invalide');
    a_Acc:instrLen:=1;
    a_Imm,a_Zpg,a_Inx,a_Iny,a_Zpx,a_Zpy:Begin
     instr[2]:=val AND 255;
     instrLen:=2;
    End;
    a_Abs,a_Abx,a_Aby,a_Ind:Begin
     instr[2]:=val AND 255;
     instr[3]:=val SHR 8;
     instrLen := 3;
    End;
   End;
  End;
  oDB:Begin
   bytStr:='';
   oldLine:=CurrLine;
   word:=GetWord;
   If Length(word)=0 Then Error('Operande attendue');
   While Length(word)<>0 do Begin
    If word=''''Then While word='''' do Begin
     val:=Pos('''',CurrLine);
     If val=0 Then Begin
      bytStr:=bytStr+CurrLine;
      CurrLine:='';
      word:='';
     End
      Else
     Begin
      bytStr:=bytStr+Copy(CurrLine,1,val-1);
      Delete(CurrLine,1,val);
      word:=GetWord;
      If word='''' Then bytStr:=bytStr+'''';
     End;
    End
     Else
    Begin
     CurrLine:=oldLine;
     bytStr:=bytStr+Chr(EvalByte);
     word:=GetWord;
    End;
    If word=','Then Begin
     oldLine:=CurrLine;
     word:=GetWord;
     If Length(word)=0 Then Error('Operande attendue');
    End
     Else
    Begin
     CurrLine:=word+' '+CurrLine;
     word:='';
    End;
   End;
   instrLen:=-Length(bytStr);
  End;
  oDW:Begin
   bytStr:='';
   oldLine:=CurrLine;
   word:=GetWord;
   If Length(word)=0 Then Error('Operande attendue');
   While Length(word)<>0 do Begin
    CurrLine:=oldLine;
    val:=Eval;
    bytStr:=bytStr+Chr(val and 255)+Chr(val shr 8);
    word:=GetWord;
    oldLine:=CurrLine;
    If word=','Then Begin
     word:=GetWord;
     If Length(word)=0 Then Error('Operande attendue');
    End;
   End;
   instrLen:=-Length(bytStr);
  End;
  oDS:Begin
   val := Eval;
   If pass=2 Then Begin
    showAddr:=False;
    Delete(listLine,1,13);
    listLine:=HexWord2Str(codPtr)+':  ('+HexWord2Str(val)+')'+listLine;
   End;
   AddLocPtr(val);
  End;
  oEND:Begin
   oldLine:=CurrLine;
   If Length(GetWord)<>0 Then Begin
    CurrLine:=oldLine;
    val:=Eval;
    CodeXfer(val);
    CurrLine:=Copy(CurrLine,1,7)+'('+HexWord2Str(val)+')'+Copy(CurrLine,14,255);
   End;
   sourceEnd:=True;
  End;
  oENDM:Error('ENDM sans MACRO');
  oMacName:Begin
   If macPtr<>NIL Then Error('Macros imbriquees non prises en charge')
    Else
   Begin
    macPtr:=macro;
    macLine:=macro^.text;
    GetMacParms(macro);
   End;
  End;
  oFCC:Begin
   bytStr:='';
   CurrLine:=LTrim(CurrLine);
   If Length(CurrLine)=0 Then Error('Operande attendu');
   ch:=CurrLine[1];
   Delete(CurrLine,1,1);
   done:=False;
   While(Length(CurrLine)<>0)and Not Done do Begin
    If CurrLine[1]=ch Then Begin
     If(Length(CurrLine)>1)and(CurrLine[2]=ch)Then Begin
      bytStr:=bytStr+CurrLine[1];
      Delete(CurrLine,1,2);
     End
      Else
     Begin
      Delete(CurrLine,1,1);
      CurrLine:=LTrim(CurrLine);
      If(Length(CurrLine)=0)or(CurrLine[1]=';')Then Done:=True
                                                   Else CurrLine := '';
     End;
    End
     Else
    Begin
     bytStr:=bytStr+CurrLine[1];
     Delete(CurrLine,1,1);
    End;
   End;
   If Not done Then Error('Le FCC n''est pas termine correctement.');
   instrLen := -Length(bytStr);
  End;
  Else Error('Opcode inconnu');
 End;
End;

Procedure ReadLine(Var line:String);Begin
 macLineFlag:=(macLine<>NIL);
 If macLineFlag Then Begin
  line:=macLine^.text;
  macLine:=macLine^.next;
  DoMacParms;
 End
  Else
 Begin
  macPtr:=NIL;
  ReadLn(source,line);
 End;
End;

Function EofSource:Boolean;Begin
 EofSource:=EOF(source)and(macLine=NIL);
End;

Procedure ListOut;
Var
 i:Integer;
Begin
 If Trim(listLine) = #12 Then WriteLn(listing,#12) Else
 If Trim(listLine)=''Then WriteLn(listing)
  Else
 Begin
  i:=Length(listLine);
  While(i>0)and(listLine[i]=' ')do Dec(i);
  listLine[0]:=Chr(i);
  WriteLn(listing,listLine);
  If errFlag and cl_Err Then WriteLn(listLine);
 End;
End;

Procedure DoLabelOp(typ,parm:Integer;labl:SymStr);
Var
 val:Integer;
 word:String;
 macro:MacroPtr;
 opcode:OpcdStr;
 mode:ModeStr;
 xmacro:MacroPtr;
 str:String;
 nparms:Integer;
Begin
 Case typ of
  oEQU:Begin
   If Length(labl)=0 Then Error('Etiquette manquante')
    Else
   Begin
    val:=Eval;
    listLine:=Copy(listLine,1,6)+'= '+HexWord2Str(val)+Copy(listLine,13,255);
    DefSym(labl,val,parm=1,parm=0);
   End;
  End;
  oORG:Begin
   CodeAbsOrg(Eval);
   DefSym(labl,locPtr,FALSE,FALSE);
   showAddr:=True;
  End;
  oRORG:Begin
   val:=Eval;
   CodeRelOrg(val);
   DefSym(labl,codPtr,FALSE,FALSE);
   If pass=2 Then Begin
    Delete(listLine,1,11);
    listLine:=HexWord2Str(codPtr)+' = '+HexWord2Str(val)+listLine;
   End;
  End;
  oLIST:Begin
   listThisLine:=TRUE;
   If Length(labl)<>0 Then Error('Etiquette non permis');
   word:=GetWord;
   If word='ON'Then listFlag:=True Else
   If word='OFF'Then listFlag:=False Else
   If word='MACRO'Then listMacFlag:=True Else
   If word='NOMACRO'Then listMacFlag:=False
                    Else Error('Operande illegale');
  End;
  oOPT:Begin
   listThisLine:=True;
   If Length(labl)<>0Then Error('Etiquette non permis');
   word:=GetWord;
   If word='LIST'Then listFlag:=True ELSE
   If word='NOLIST'Then listFlag:=False
                   Else Error('Option non autorise');
  End;
  oMACRO:Begin
   FindMacro(labl,macro);
   If(macro<>NIL)and macro^.def Then Error('Multiple definition de macro')
    Else
   Begin
    If macro=NIL Then Begin
     AddMacro(labl,macro);
     word:=GetWord;
     While(Length(word)<>0)and(word[1] in alpha)do Begin
      AddMacroParam(macro,word);
      word:=GetWord;
      If word=','Then word:=GetWord;
     End;
     If macro^.nParms > maxMacParms Then Error('Trop de parametres dans la macro');
     If Length(word)<>0 Then Error('Operande non autorise');
    End;
    If pass=2 Then macro^.def:=True;
    While (Not EofSource)and(typ<>oENDM)do Begin
    If pass=2 Then ListOut;
    ReadLine(CurrLine);
    listLine:='                ' + CurrLine;
    str:=CurrLine;
    labl:='';
    If Length(CurrLine)>0 Then
     If Pos(CurrLine[1],white)=0 Then Begin
      labl:=GetWord;
      showAddr:=(Length(labl)<>0);
      If Length(labl)<>0 Then
       If labl[1]='@'Then labl:=lastLabel+labl
                     Else lastLabel:=labl;
      If Length(CurrLine)>0 Then
       If CurrLine[1]=':' Then Delete(CurrLine,1,1);
     End;
     opcode:=GetWord;
     If Length(opcode)=0 Then typ := 0
                         Else FindOpcode(opcode,typ,parm,mode,xmacro);
     If typ=oEND Then Error('END n''est pas autorise dans une macro');
     If typ=oENDM Then Begin
      If(pass=1)and(Length(labl)<>0)Then AddMacroLine(macro,labl);
     End
      Else
     If pass=1 Then AddMacroLine(macro,str);
    End;
    If typ<>oENDM Then Error('ENDM attendu');
   End;
  End;
  Else Error('Opcode inconnu');
 End;
End;

Procedure DoPass;
Var
 labl,opcode:SymStr;
 mode:ModeStr;
 typ,parm,i:Integer;
 word:String;
 macro:MacroPtr;
Begin
 Assign(source,cl_SrcName);
 Reset(source);
 sourceEnd:=False;
 lastLabel:='';
 WriteLn('Passage ',pass);
 outPtr:=$FFFF;
 CodeAbsOrg($0000);
 errCount := 0;
 listFlag := TRUE;
 listMacFlag := FALSE;
 While (Not EofSource) and (Not sourceEnd) do Begin
  ReadLine(CurrLine);
  errFlag:=FALSE;
  instrLen:=0;
  showAddr:=False;
  listThisLine:=ListFlag;
  listLine:='                ';
  If Pass=2 Then listLine:=Copy(listLine,1,16)+CurrLine;
  labl:='';
  If Length(CurrLine)>0 Then
   If Pos(CurrLine[1],white)=0 Then Begin
    If(Length(CurrLine)<>0)and(CurrLine[1]='*')Then CurrLine:='';
    labl:=GetWord;
    showAddr:=(Length(labl)<>0);
    If Length(labl)<>0 Then
     If labl[1]='@' Then labl:=lastLabel+labl
                    Else lastLabel := labl;
    If Length(CurrLine)>0 Then
     If CurrLine[1]=':' Then Delete(CurrLine,1,1);
   End;
   opcode:=GetWord;
   If Length(opcode)=0 Then Begin
    typ:=0;
    DefSym(labl,locPtr,False,False);
   End
    Else
   Begin
    FindOpcode(opcode,typ,parm,mode,macro);
    If typ=oIllegal Then Error('Le opcode n''est pas autorise "'+Trim(opcode)+'"')Else
    If typ<0 Then Begin
     showAddr:=False;
     DoLabelOp(typ,parm,labl);
    End
     Else
    Begin
     showAddr := TRUE;
     DefSym(labl,locPtr,FALSE,FALSE);
     DoOpcode(typ,parm,mode,macro);
    End;
    If typ<>oIllegal Then
     If Length(GetWord)>0 Then Error('Trop d''operande');
   End;
   If Pass=2 Then Begin
    If ShowAddr Then listLine:=HexWord2Str(codPtr)+':'+Copy(listLine,6,255);
    If instrLen>0 Then For i:=1 to instrLen do Begin
     word := ByteHex2Str(instr[i]);
     listLine[i*3+4] := word[1];
     listLine[i*3+5] := word[2];
     CodeOut(instr[I]);
    End
     Else
    Begin
     For i := 1 to -instrLen do Begin
      If i<=3 Then Begin
       word := ByteHex2Str(ORD(bytStr[i]));
       listLine[i*3+4] := word[1];
       listLine[i*3+5] := word[2];
      End;
      CodeOut(ORD(bytStr[i]));
    End;
    If -instrLen > 3 Then listLine[4*3+4-1] := '+';
   End;
   If listThisLine and(errFlag or listMacFlag or Not macLineFlag)Then ListOut;
  End;
  AddLocPtr(ABS(instrLen));
 End;
 If Pass=2 Then CodeEnd;
 If Pass=2 Then
 While Not EofSource do Begin
  ReadLine(CurrLine);
  listThisLine := listFlag;
  listLine := '                ' + CurrLine;
  If Length(CurrLine)>0 Then
   If Pos(CurrLine[1],white)<>0 Then Begin
    word := GetWord;
    If Length(word)<>0 Then Begin
     FindOpcode(word,typ,parm,mode,macro);
     Case typ of
      oLIST:Begin
       listThisLine:=True;
       word:=GetWord;
       If word='ON'Then listFlag:=True Else
       If word='OFF'Then listFlag:=False Else
       If word='MACRO'Then listMacFlag:=True Else
       If word='NOMACRO'Then listMacFlag:=False
                        Else listThisLine:=listFlag;
      End;
      oOPT:Begin
       listThisLine:=True;
       word:=GetWord;
       If word='LIST'Then listFlag:=True Else
       If word='NOLIST'Then listFlag:=False
                       Else listThisLine:=listFlag;
      End;
     End;
    End;
   End;
  If listThisLine Then ListOut;
 End;
 Close(source);
End;

Procedure SortSymTab;
Var
 i,j,t:SymPtr;
 sorted:Boolean;
 temp:SymRec;
Begin
 If symTab<>NIL Then Begin
  i := symTab;
  j := i^.next;
  While(j<>NIL)do Begin
   sorted:=True;
   While(j<>NIL)do Begin
    If j^.SymbolName<i^.SymbolName Then Begin
     temp:=i^;i^:=j^;j^:=temp;
     t:=i^.next;i^.next:=j^.next;j^.next:=t;
     sorted:=False;
    End;
    j:=j^.next;
   End;
   i:=i^.next;
   j:=i^.next;
  End;
 End;
End;

Procedure DumpSym(p:SymPtr;Var s:String);Begin
 s := p^.SymbolName;
 While Length(s)<=maxSymLen do s:=s+' ';
 s:=s+HexWord2Str(p^.value)+' ';
 If Not p^.defined Then s:=s+'U';
 If p^.multiDef Then s:=s+'M';
 If p^.isSet Then s:=s+'S';
 If p^.equ Then s:=s+'E';
 While Length(s)<=maxSymLen+9 do s:=s+' ';
End;

Procedure DumpSymTab;
Var
 p:SymPtr;
 i:Integer;
 s:String;
Begin
 SortSymTab;
 i:=1;
 p:=symTab;
 While(p<>NIL)do Begin
  DumpSym(p,s);
  p := p^.next;
  i := i + 1;
  If(p=NIL)or(i>symTabCols)Then Begin
   i := 1;
   S:=RTrim(s);
   WriteLn(listing,s);
  End
   Else
  Write(listing,s);
 End;
End;

Function GetOption(Var optStr:String):String;
Var
 option:String[80];
 p:Integer;
Begin
 optStr:=Trim(optStr);
 p:=Pos(' ',optStr);
 If p=0 Then Begin
  option := optStr;
  optStr := '';
 End
  Else
 Begin
  option:=Copy(optStr,1,p-1);
  optStr:=Copy(optStr,p+1,255);
 End;
 optStr:=StrToUpper(Trim(optStr));
 GetOption:=option;
END;

Function GetOptions(Var cl_SrcName, cl_ListName,cl_ObjName,cl_BinName:String;Var cl_Err:Boolean):Boolean;
Var
 s:String;
 len:Integer;
 optStr,option,optParm,prefix:String;
 p,err:Integer;
 optErr:Boolean;
 i:Integer;
Begin
 cl_SrcName:='';
 cl_ListName:='NUL';
 cl_ObjName:='NUL';
 cl_BinName:='NUL';
 cl_Err:=False;
 optErr:=False;
 optStr:=ParamStr(1);
 For i:=2 TO ParamCount do optStr:=optStr+' '+ParamStr(i);
 option:=GetOption(optStr);
 While Length(option)<>0 do Begin
  optParm:='';
  p:=Pos('=',option);
  If p>0 Then Begin
   optParm:=Copy(option,p+1,255);
   option:=Copy(option,1,p-1);
  End;
  option:=StrToUpper(option);
  If option='-B'Then cl_BinName:=optParm Else
  If option='-L'Then cl_ListName:=optParm Else
  If option='-O'Then cl_ObjName:=optParm Else
  If option='-E'Then cl_Err:=True Else
  If option='?'Then optErr:=True
   Else
  Begin
   If(Copy(option,1,1)='-')or(Length(cl_SrcName)<>0)or(Length(optParm)<>0)Then Begin
    optErr:=True;
    WriteLn('Le parametre de ligne de commande n''est pas autorise : ',option);
   End
    Else
   Begin
    cl_SrcName:=option;
    If Pos('.',cl_SrcName)=0 Then
     If p=0 Then cl_SrcName:=cl_SrcName+'.ASM';
     p:=Pos('.',option);
     If p=0 Then prefix:=option
            Else prefix:=Copy(option,1,p-1);
    End;
   End;
   option:=GetOption(optStr);
  End;
  If cl_SrcName=''Then Begin
   optErr:=True;
   WriteLn('Le fichier source n''est pas specifie')
 End;
 If cl_ListName=''Then cl_ListName:=prefix+'.LIS';
 If cl_ObjName=''Then cl_ObjName:=prefix+'.DAT';
 if cl_BinName=''Then cl_BinName:=prefix+'.BIN';
 If Copy(cl_ListName,1,1)='.'Then cl_ListName:=prefix+cl_ListName;
 If Copy(cl_ObjName,1,1)='.'Then cl_ObjName:=prefix+cl_ObjName;
 If Copy(cl_BinName,1,1)='.'Then cl_BinName:=prefix+cl_BinName;
 GetOptions:=optErr;
End;

BEGIN
 If GetOptions(cl_SrcName,cl_ListName,cl_ObjName,cl_BinName,cl_Err)Then Begin
  WriteLn('ASM6502 : Cette commande permet de compiler un code source assembleur 6502.');
  WriteLn;
  WriteLn('Syntaxe: ASM6502 [options] src [options]');
  WriteLn;
  WriteLn('Parametres');
  WriteLn;
  WriteLn('    -E  Affiche les erreurs a l''ecran');
  WriteLn('    -L  Fabrique un fichier de liste src.LIS');
  WriteLn('    -L=nom');
  WriteLn('    -O  Fabrique un fichier objet de src.OBJ');
  WriteLn('    -O=nom');
  WriteLn('    -B  Fabrique un fichier binaire de src.BIN');
  WriteLn('    -B=nom');
  Halt;
 End;
 Assign(listing,cl_ListName);
 Rewrite(listing);
 Assign(objet,cl_ObjName);
 Rewrite(objet);
 Assign(Binary,cl_BinName);
 Rewrite(Binary);
 symTab:=NIL;
 macroTab:=NIL;
 macPtr:=NIL;
 macLine:=NIL;
 xferAddr:=0;
 xferFound:=False;
 InitOpcodes;
 pass:=1;
 DoPass;
 pass:=2;
 DoPass;
 WriteLn(listing);
 WriteLn(listing,errCount:5,' Erreur(s) total');
 WriteLn(listing);
 If(cl_Err)Then Begin
  WriteLn;
  WriteLn(errCount:5,' Erreur(s) total');
 End;
 DumpSymTab;
 Close(listing);
 Close(objet);
 Close(Binary);
 If errCount<>0 Then Halt(1);
END.
