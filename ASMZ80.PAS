{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program ASMZ80;

{$R-}

Const
 InstrZ80:Array[0..34]of Record
  InstrName:String[7];
  InstrOpcode:Word;
 End=(
  (InstrName:'EXX';InstrOpcode:$D9),
  (InstrName:'LDI';InstrOpcode:$EDA0),
  (InstrName:'LDIR';InstrOpcode:$EDB0),
  (InstrName:'LDD';InstrOpcode:$EDA8),
  (InstrName:'LDDR';InstrOpcode:$EDB8),
  (InstrName:'CPI';InstrOpcode:$EDA1),
  (InstrName:'CPIR';InstrOpcode:$EDB1),
  (InstrName:'CPD';InstrOpcode:$EDA9),
  (InstrName:'CPDR';InstrOpcode:$EDB9),
  (InstrName:'DAA';InstrOpcode:$27),
  (InstrName:'CPL';InstrOpcode:$2F),
  (InstrName:'NEG';InstrOpcode:$ED44),
  (InstrName:'CCF';InstrOpcode:$3F),
  (InstrName:'SCF';InstrOpcode:$37),
  (InstrName:'NOP';InstrOpcode:$00),
  (InstrName:'HALT';InstrOpcode:$76),
  (InstrName:'DI';InstrOpcode:$F3),
  (InstrName:'EI';InstrOpcode:$FB),
  (InstrName:'RLCA';InstrOpcode:$07),
  (InstrName:'RLA';InstrOpcode:$17),
  (InstrName:'RRCA';InstrOpcode:$0F),
  (InstrName:'RRA';InstrOpcode:$1F),
  (InstrName:'RLD';InstrOpcode:$ED6F),
  (InstrName:'RRD';InstrOpcode:$ED67),
  (InstrName:'RET';InstrOpcode:$C9),
  (InstrName:'RETI';InstrOpcode:$ED4D),
  (InstrName:'RETN';InstrOpcode:$ED45),
  (InstrName:'INI';InstrOpcode:$EDA2),
  (InstrName:'INIR';InstrOpcode:$EDB2),
  (InstrName:'IND';InstrOpcode:$EDAA),
  (InstrName:'INDR';InstrOpcode:$EDBA),
  (InstrName:'OUTI';InstrOpcode:$EDA3),
  (InstrName:'OTIR';InstrOpcode:$EDB3),
  (InstrName:'OUTD';InstrOpcode:$EDAB),
  (InstrName:'OTDR';InstrOpcode:$EDBB)
 );

 maxSymLen=16;
 maxOpcdLen=4;
 symTabCols=3;

 alphaNumeric='1234567890$ABCDEFGHIJKLMNOPQRSTUVWXYZ_';
 numeric='1234567890';
 hex='0123456789ABCDEF';
 white=#9' ';

 oIllegal=0;
 oNone=1;
 oLD=2;
 oEX=3;
 oADD=4;
 oADC_SBC=5;
 oINC_DEC=6;
 oJP_CALL=7;
 oJR=8;
 oRET=9;
 oIN=10;
 oOUT=11;

 oPushPop=12;
 oArith=13;
 oRotate=14;
 oBit=15;
 oIM=16;
 oDJNZ=17;
 oRST=18;

 oDB=19;
 oDW=20;
 oDS=21;
 oEQU=-22;
 oORG=-23;
 oEND=24;
 oLIST=-25;
 oOPT=-26;

 regs=' B C D E H L A I R BC DE HL SP IX IY AF (  ';
 regVals=' 0 1 2 3 4 5 7 8 9 10 11 12 13 14 15 16 17 ';

 reg_None=-1;
 reg_B=0;
 reg_C=1;
 reg_D=2;
 reg_E=3;
 reg_H=4;
 reg_L=5;
 reg_M=6;
 reg_A=7;
 reg_Byte=[reg_B..reg_A];
 reg_I=8;
 reg_R=9;
 reg_BC=10;
 reg_DE=11;
 reg_HL=12;
 reg_SP=13;
 reg_Word=[reg_BC..reg_SP];
 reg_IX=14;
 reg_IY=15;
 reg_AF=16;
 reg_Paren=17;

 conds=' NZ Z NC C PO PE P M ';
 condVals=' 0  1 2  3 4  5  6 7 ';

Type
 SymStr=String[maxSymLen];

 SymPtr =^SymRec;
 SymRec=Record
  name:SymStr;
  value:Integer;
  next:SymPtr;
  defined:Boolean;
  multiDef:Boolean;
  isSet:Boolean;
  equ:Boolean;
 End;

 OpcdStr=String[maxOpcdLen];

 OpcdPtr=^OpcdRec;
 OpcdRec=Record
  name:OpcdStr;
  typ:Integer;
  parm:Integer;
  next:OpcdPtr;
 End;

Var
 symTab:SymPtr;
 opcdTab:OpcdPtr;

 locPtr:Integer;
 newLoc:Integer;
 updLoc:Boolean;
 pass:Integer;
 warnFlag:Boolean;
 errFlag:Boolean;
 errCount:Integer;

 line:String;
 listLine:String;
 listFlag:Boolean;
 listThisLine:Boolean;
 sourceEnd:Boolean;

 instr:Array[1..5] of Integer;
 instrLen:Integer;

 bytStr:String;
 showAddr:Boolean;
 xferAddr:Integer;
 xferFound:Boolean;

 cl_SrcName,cl_ListName,cl_ObjName,cl_BinName:String;
 cl_Err:Boolean;
 cl_Warn:Boolean;

 Source,_Object,Listing:Text;
 Binary:File of Byte;

Function Eval:Integer;Forward;

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

Procedure StAppendCh(Var s:String;ch:Char);Begin
 If Length(s)<>255 Then Begin
  s[0]:=Chr(Length(s)+1);
  s[Length(s)]:=ch;
 End;
End;

Function StrToUpper(s:String):String;
Var
 i:Integer;
Begin
 For i:=1 to Length(s) do If s[i] in ['a'..'z']Then s[i] := UpCase(s[i]);
 StrToUpper:=s;
End;

Function Hex2(i:Integer):String;
Var
 s:String;
Begin
 i:=i AND 255;
 Hex2:=Copy(hex,(i SHR  4)+1,1)+Copy(hex,(i AND 15)+1,1);
End;

Function Hex4(i:Integer):String;Begin
 Hex4 := Hex2(i shr 8) + Hex2(i and 255);
End;

Procedure Error(_message:String);Begin
 errFlag:=True;
 Inc(errCount);
 If pass<>1 Then Begin
  listThisLine:=True;
  WriteLn(listing,'*** Erreur :  ',_message,' ***');
  If cl_Err Then WriteLn('*** Erreur :  ',_message,' ***');
 End;
End;

Procedure Warning(_message:String);Begin
 If(pass<>1) and cl_Warn Then Begin
  listThisLine:=True;
  warnFlag:=True;
  WriteLn(listing,'*** Attention :  ',_message,' ***');
  WriteLn('*** Attention :  ',_message,' ***');
 End;
End;

Procedure IllegalOperand;Begin
 Error('Operande illegale');
 line:='';
End;

Procedure AddOpcode(nom:OpcdStr;typ:Integer;parm:Word);
Var
 p:OpcdPtr;
Begin
 New(p);
 p^.name:=nom;
 p^.typ:=typ;
 p^.parm:=parm;
 p^.next:=opcdTab;
 opcdTab:=p;
End;

Procedure FindOpcode(nom:OpcdStr;Var typ,parm:Integer);
Var
 p:OpcdPtr;
 found:Boolean;
Begin
 found:=False;
 p:=opcdTab;
 While(p<>NIL)and Not Found do Begin
  found:=p^.name=nom;
  If Not Found Then p:=p^.next;
 End;
 If Not found Then Begin
  typ:=oIllegal;
  parm:=0;
 End
  Else
 Begin
  typ:=p^.typ;
  parm := p^.parm;
 End;
End;

Procedure InitOpcodes;
Var
 I:Byte;
Begin
 opcdTab:=NIL;
 For I:=0 to High(InstrZ80)do AddOpcode(InstrZ80[I].InstrName,oNone,InstrZ80[I].InstrOpcode);

 AddOpcode('LD'  ,oLD,0);
 AddOpcode('EX'  ,oEX,0);
 AddOpcode('ADD' ,oADD,0);
 AddOpcode('ADC' ,oADC_SBC,0);
 AddOpcode('SBC' ,oADC_SBC,1);
 AddOpcode('INC' ,oINC_DEC,0);
 AddOpcode('DEC' ,oINC_DEC,1);
 AddOpcode('JP'  ,oJP_CALL,$C3C2);
 AddOpcode('CALL',oJP_CALL,$CDC4);
 AddOpcode('JR'  ,oJR,0);
 AddOpcode('RET' ,oRET,0);

 AddOpcode('PUSH',oPushPop,$C5);
 AddOpcode('POP' ,oPushPop,$C1);

 AddOpcode('SUB' ,oArith,$D690);
 AddOpcode('AND' ,oArith,$E6A0);
 AddOpcode('XOR' ,oArith,$EEA8);
 AddOpcode('OR'  ,oArith,$F6B0);
 AddOpcode('CP'  ,oArith,$FEB8);

 AddOpcode('RLC' ,oRotate,$00);
 AddOpcode('RRC' ,oRotate,$08);
 AddOpcode('RL'  ,oRotate,$10);
 AddOpcode('RR'  ,oRotate,$18);
 AddOpcode('SLA' ,oRotate,$20);
 AddOpcode('SRA' ,oRotate,$28);
 AddOpcode('SRL' ,oRotate,$38);

 AddOpcode('BIT' ,oBit,$40);
 AddOpcode('RES' ,oBit,$80);
 AddOpcode('SET' ,oBit,$C0);

 AddOpcode('IM'  ,oIM,0);

 AddOpcode('DJNZ',oDJNZ,0);

 AddOpcode('IN'  ,oIN,0);

 AddOpcode('OUT' ,oOUT,0);

 AddOpcode('RST' ,oRST,0);

 AddOpcode('DB'  ,oDB,0);
 AddOpcode('DW'  ,oDW,0);
 AddOpcode('DS'  ,oDS,0);

 AddOpcode('='   ,oEQU,0);
 AddOpcode('EQU' ,oEQU,0);
 AddOpcode('DEFL',oEQU,1);

 AddOpcode('ORG' ,oORG,0);
 AddOpcode('END' ,oEND,0);
 AddOpcode('LIST',oLIST,0);
 AddOpcode('OPT' ,oOPT,0);
End;

Function EvalOct(octStr:String):Integer;
Var
 octVal:Integer;
 evalErr:Boolean;
 i,n:Integer;
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
 decVal:Integer;
 evalErr:Boolean;
 i,n:Integer;
Begin
 evalErr:=False;
 decVal:=0;
 For i:=1 to Length(decStr) do Begin
  n:=Pos(decStr[i],'0123456789');
  If n=0 Then evalErr:=True
         Else decVal:=decVal*10+n-1;
 End;
 If evalErr Then Begin
  decVal:=0;
  Error('Nombre decimal invalide');
 End;
 EvalDec:=decVal;
End;

Function EvalHex(hexStr:String):Integer;
Var
 hexVal:Integer;
 evalErr:Boolean;
 i,n:Integer;
Begin
 evalErr:=False;
 hexVal:=0;
 For i:=1 TO Length(hexStr) do Begin
  n:=Pos(Upcase(hexStr[i]),'0123456789ABCDEF');
  If n=0 Then evalErr:=True
         Else hexVal:=hexVal*16+n-1;
 End;
 If evalErr Then Begin
  hexVal := 0;
  Error('Nombre hexadecimal invalide');
 End;
 EvalHex:=hexVal;
End;

Function FindSym(symName:SymStr):SymPtr;
Var
 p:SymPtr;
 found:Boolean;
Begin
 found:=False;
 p:=SymTab;
 While(p<>NIL) and Not Found do Begin
  found:=p^.name=symName;
  If Not found Then p:=p^.next;
 End;
 FindSym:=p;
End;

Function AddSym(symName:SymStr):SymPtr;
Var
 p:SymPtr;
Begin
 New(p);
 With p^ do Begin
  name:=SymName;
  value:=0;
  next:=SymTab;
  defined:=False;
  multiDef:=False;
  isSet:=False;
  equ:=False;
 End;
 symTab:=p;
 AddSym:=p;
End;

Function RefSym(symName:SymStr):Integer;
Var
 p:SymPtr;
 i:Integer;
Begin
 p:=FindSym(symName);
 If p=NIL Then p:=AddSym(symName);
 If Not p^.defined Then Begin
  symName:=StrToUpper(symName);
  i:=Length(symName)-1;
  If symName[Length(symName)]='H'Then
  While(i>0)and(symName[i] IN ['0'..'9','A'..'F'])do i:=i-1;
  If i=0 Then RefSym:=EvalHex(Copy(symName,1,Length(symName)-1))
   Else
  Begin
   Error('Symbole "'+symName+'" indefini');
   RefSym := 0;
  End;
 End
  Else
 RefSym:=p^.value;
End;

Procedure DefSym(symName:SymStr;val:Integer;setSym,equSym:Boolean);
Var
 p:SymPtr;
Begin
 If Length(symName)<>0 Then Begin
  p:=FindSym(symName);
  If p=NIL Then p:=AddSym(symName);
  If(Not p^.defined)or(p^.isSet and setSym)Then Begin
   p^.value:=val;
   p^.defined:=True;
   p^.isSet:=setSym;
   p^.equ:=equSym;
  End
   Else
  If p^.value<>val Then Begin
   p^.multiDef:=True;
   Error('Multiple symbole "' + symName + '" defini');
  End;
 End;
End;

Function GetWord:String;
Var
 word:String;
 done:Boolean;
Begin
 line:=Trim(line);
 word:='';
 If(Length(line)>0)and(line[1]in[#12,';'])Then line:='';
 If Length(line)>0 Then Begin
  If Pos(Upcase(line[1]),alphaNumeric)=0 Then Begin
   word:=Copy(Line,1,1);
   Delete(line,1,1);
  End
   Else
  Begin
   done:=FALSE;
   While(Length(line)>0)and Not Done do Begin
    word:=word+Upcase(line[1]);
    Delete(line,1,1);
    If Length(line)>0 Then done:=Pos(Upcase(line[1]),AlphaNumeric)=0;
   End;
  End;
 End;
 GetWord:=word;
End;

Procedure Expect(expected:String);Begin
 If GetWord<>expected Then Error('"' + expected + '" attendu');
End;

Function Factor:Integer;
Var
 word:String;
 val:Integer;
Begin
 word:=GetWord;
 val:=0;
 If Length(word)=0 Then Error('Operande attendu') else
 If(word='.')or(word='*')Then val:=locPtr Else
 If word='$'Then val:=locPtr Else
 If word='-'Then val:=-Factor Else
 If word='+'Then val:=Factor Else
 If word='~'Then val:=-Factor-1 Else
 If word='('Then Begin
  val:=Eval;
  If GetWord<>')'Then Error('")" attendu');
 End
  Else
 If word=''''Then Begin
  If Length(line)=0 Then Error('Operande attendu')
   Else
  Begin
   val:=Ord(line[1]);
   Delete(line,1,1);
   Expect('''');
  End;
 End
  Else
 If Pos(word[1],numeric)>0 Then Begin
  Case word[Length(word)]of
   'O':val:=EvalOct(Copy(word,1,Length(word)-1));
   'D':val:=EvalDec(Copy(word,1,Length(word)-1));
   'H':val:=EvalHex(Copy(word,1,Length(word)-1));
   Else val:=EvalDec(word);
  End;
 End
  Else
 val:=RefSym(word);
 Factor:=val;
End;

Function Term:Integer;
Var
 word:String;
 val:Integer;
 oldLine:String;
Begin
 val:=Factor;
 oldLine:=line;
 word:=GetWord;
 While(word='*')or(word='/')or(word='%')do Begin
  Case word[1]of
   '*':val:=val * Factor;
   '/':val:=val div Factor;
   '%':val:=val mod Factor;
  End;
  oldLine:=line;
  word:=GetWord;
 End;
 line:=oldLine;
 Term:=val;
End;

Function Eval:Integer;
Var
 word,oldLine:String;
 val:Integer;
Begin
 val:=Term;
 oldLine:=line;
 word:=GetWord;
 While(word='+')or(word='-')do Begin
  Case word[1]of
   '+':val:=val+Term;
   '-':val:=val-Term;
  End;
  oldLine:=line;
  word:=GetWord;
 End;
 line:=oldLine;
 Eval:=val;
End;

Function EvalByte:Integer;
Var
 val:Integer;
Begin
 val:=Eval;
 If(val<-128)or(val>255)Then Error('Octet en dehors de l''intervalle');
 EvalByte:=val AND 255;
End;

Function FindReg(regName,regList,valList:String):Integer;
Var
 p:Integer;
 reg:Integer;
 code:Integer;
Begin
 p:=Pos(' '+Trim(regName)+' ',regList);
 If p=0 Then reg:=-1 Else
 If valList[p+2]=' 'Then Val(Copy(valList,p+1,1),reg,code)
                    Else Val(Copy(valList,p+1,2),reg,code);
 FindReg:=reg;
End;

Procedure CodeOut(_byte:Integer);Begin
 If(pass=2)and updLoc Then Begin
  WriteLn(_object,':',Hex4(newLoc));
  updLoc:=False;
 End;
 If pass=2 Then Begin
  WriteLn(_object,Hex2(_byte));
  Write(Binary,Byte(_byte));
 End;
End;

Procedure CodeOrg(addr:Integer);Begin
 locPtr:=addr;
 newLoc:=locPtr;
 updLoc:=True;
End;

Procedure CodeEnd;Begin
 If(pass=2)and xferFound Then WriteLn(_object,'$',Hex4(xferAddr));
End;

Procedure CodeXfer(addr:Integer);Begin
 xferAddr:=addr;
 xferFound:=True;
End;

Procedure Instr1(b:Byte);Begin
 instr[1]:=b;
 instrLen:=1;
End;

Procedure Instr2(b1,b2: Byte);Begin
 instr[1] := b1;
 instr[2] := b2;
 instrLen := 2;
End;

Procedure Instr3(b1,b2,b3: Byte);Begin
 instr[1]:=b1;
 instr[2]:=b2;
 instr[3]:=b3;
 instrLen:=3;
End;

Procedure Instr3W(b: Byte; w: Word);Begin
 Instr3(b,w and 255,w shr 8);
End;

Procedure Instr4(b1,b2,b3,b4:Byte);Begin
 instr[1]:=b1;
 instr[2]:=b2;
 instr[3]:=b3;
 instr[4]:=b4;
 instrLen:=4;
End;

Procedure Instr4W(b1,b2:Byte;w:Word);Begin
 Instr4(b1,b2,w AND 255,w SHR 8);
End;

Procedure DoOpcode(typ:Integer;parm:Word);
Var
 val:Integer;
 reg1:Integer;
 reg2:Integer;
 word:String;
 oldLine:String;

 Procedure IXOffset;Begin
  word:=GetWord;
  If word=')'Then val:=0 Else
  If(word='+')or(word='-')Then Begin
   val:=Eval;
   If word='-'Then val:=-val;
   If GetWord<>')' Then Error('")" attendu');
  End;
 End;

 Procedure DoArith(imm,reg:Integer);Begin
  oldLine:=Line;
  reg2:=FindReg(GetWord,regs,regVals);
  Case reg2 of
   reg_None:Begin { ADD A,nn }
    line:=oldLine;
    val:=Eval;
    Instr2(imm,val);
   End;
   reg_B,reg_C,reg_D,reg_E,reg_H,reg_L,reg_A:Instr1(reg+reg2); { ADD A,r }
   reg_Paren:Begin
    reg2:=FindReg(GetWord,regs,regVals);
    Case reg2 of
     reg_HL:Begin
      If GetWord<>')' Then Error('")" attendu');
      Instr1(reg+reg_M);
     End;
     reg_IX,reg_IY:Begin
      IXOffset;
      If reg2=reg_IX Then Instr3($DD,reg+reg_M,val)
                     Else Instr3($FD,reg+reg_M,val);
     End;
     Else IllegalOperand;
    End;
   End;
   Else IllegalOperand;
  End;
 End;

Begin
 Case typ of
  oNone:
   If parm>255 Then Instr2(parm shr 8,parm and 255)
               Else Instr1(parm);
  oLD:Begin
   word:=GetWord;
   reg1:=FindReg(word,regs,regVals);
   Case reg1 of
    reg_None:IllegalOperand; { LD nnnn,? }
    reg_B,reg_C,reg_D,reg_E,reg_H,reg_L,reg_A:Begin { LD r,? }
     If GetWord<>',' Then Error('"," attendu');
     oldLine:=line;
     reg2:=FindReg(GetWord,regs,regVals);
     Case reg2 of
      reg_B,reg_C,reg_D,reg_E,reg_H,reg_L,reg_A:Instr1($40+reg1*8+reg2);  { LD r,r }
      reg_I:Instr2($ED,$57); { LD A,I }
      reg_R:Instr2($ED,$5F); { LD A,R }
      reg_Paren:Begin { LD r,(?) }
       oldLine:=Line;
       reg2:=FindReg(GetWord,regs,regVals);
       Case reg2 of
        reg_BC, { LD A,(BC) }
        reg_DE: { LD A,(DE) }
         If reg1<>reg_A Then IllegalOperand
          Else
         Begin
          If GetWord<>')' Then Error('")" attendu');
          Instr1($0A+(reg2-reg_BC)*16);
         End;
        reg_HL:Begin { LD r,(HL) }
         If GetWord<>')' Then Error('")" attendu');
         Instr1($40+reg1*8+reg_M);
        End;
        reg_IX, { LD r,(IX+d) }
        reg_IY:Begin { LD r,(IY+d) }
         IXOffset;
         If reg2=reg_IX Then Instr3($DD,$46+reg1*8,val)
                        Else Instr3($FD,$46+reg1*8,val);
        End;
        reg_None: { LD A,(nnnn) }
         If reg1<>reg_A Then IllegalOperand
          Else
         Begin
          line:=oldLine;
          val:=Eval;
          If GetWord<>')' Then Error('")" attendu');
          Instr3W($3A,val);
         End;
         Else IllegalOperand;
       End;
      End;
      reg_None:Begin { LD r,nn }
       line:=oldLine;
       Instr2($06+reg1*8,Eval);
      End;
      Else IllegalOperand;
     End; { CASE reg2 }
    End; { reg_Byte }
    reg_I:Begin { LD I,A }
     If GetWord<>',' Then Error('"," attendu');
     Expect('A');
     Instr2($ED,$47);
    End;
    reg_R:Begin { LD R,A }
     If GetWord<>',' Then Error('"," attendu');
     Expect('A');
     Instr2($ED,$4F);
    End;
    reg_BC,reg_DE,reg_HL,reg_SP:Begin { LD rr,? }
     If GetWord<>',' Then Error('"," attendu');
     oldLine:=line;
     reg2:=FindReg(GetWord,regs,regVals);
     If(reg1=reg_SP)and(reg2 in[reg_HL,reg_IX,reg_IY])Then Begin { LD SP,HL }
      Case reg2 of
       reg_HL:Instr1($F9);
       reg_IX:Instr2($DD,$F9);
       reg_IY:Instr2($FD,$F9);
      End;
     End
      Else
     If(reg1=reg_HL)and(reg2=reg_Paren)Then Begin
      val:=Eval; { LD HL,(nnnn) }
      If GetWord<>')' Then Error('")" attendu');
      Instr3W($2A,val);
     End
      Else
     If reg2=reg_Paren Then Begin
      val:=Eval; { LD BC,(nnnn) }
      If GetWord<>')' Then Error('")" attendu');
      Instr4W($ED,$4B + (reg1-reg_BC)*16,val);
     End
      Else
     If reg2=reg_None Then Begin { LD rr,nnnn }
      line:=oldLine;
      val:=Eval;
      Instr3W($01+(reg1-reg_BC)*16,val);
     End
     Else IllegalOperand;
    End;
    reg_IX, { LD IX,? }
    reg_IY:Begin { LD IY,? }
     If GetWord<>',' Then Error('"," attendu');
     oldLine:=Line;
     reg2:=FindReg(GetWord,regs,regVals);
     Case reg2 of
      reg_None:Begin { LD IX,nnnn }
       line:=oldLine;
       val:=Eval;
       If reg1=reg_IX Then Instr4W($DD,$21,val)
                      Else Instr4W($FD,$21,val);
      End;
      reg_Paren:Begin { LD IX,(nnnn) }
       val:=Eval;
       If GetWord<>')' Then Error('")" attendu');
       If reg1=reg_IX Then Instr4W($DD,$2A,val)
                      Else Instr4W($FD,$2A,val);
      End;
      Else IllegalOperand;
     End;
    End;
    reg_Paren:Begin { LD (?),? }
     oldLine:=Line;
     reg1:=FindReg(GetWord,regs,regVals);
     Case reg1 of
      reg_None:Begin { LD (nnnn),? }
       line:=oldLine;
       val:=Eval;
       If GetWord<>')' Then Error('")" attendu');
       If GetWord<>',' Then Error('"," attendu');
       reg2:=FindReg(GetWord,regs,regVals);
       Case reg2 of
        reg_A:  Instr3W($32,val);
        reg_HL: Instr3W($22,val);
        reg_BC,
        reg_DE,
        reg_SP: Instr4W($ED,$43+(reg2-reg_BC)*16,val);
        reg_IX: Instr4W($DD,$22,val);
        reg_IY: Instr4W($FD,$22,val);
        Else IllegalOperand;
       End; { CASE reg2 }
      End;
      reg_BC,reg_DE:Begin
       If GetWord<>')' Then Error('")" attendu');
       If GetWord<>',' Then Error('"," attendu');
       Expect('A');
       Instr1($02+(reg1-reg_BC)*16);
      End;
      reg_HL:Begin { LD (HL),? }
       If GetWord<>')' Then Error('")" attendu');
       If GetWord<>',' Then Error('"," attendu');
       oldLine:=Line;
       reg2:=FindReg(GetWord,regs,regVals);
       If reg2=reg_None Then Begin
        line:=oldLine;
        val:=Eval;
        Instr2($36,val);
       End
        Else
       If reg2 in reg_Byte Then Instr1($70 + reg2)
                           Else IllegalOperand;
      End;
      reg_IX,reg_IY:Begin { LD (IX),? }
       IXOffset;
       If GetWord<>',' Then Error('"," attendu');
       oldLine:=Line;
       reg2:=FindReg(GetWord,regs,regVals);
       If reg2=reg_None Then Begin
        line:=oldLine;
        reg2:=Eval;
        If reg1=reg_IX Then Instr4($DD,$36,val,reg2)
                       Else Instr4($FD,$36,val,reg2);
       End
        Else
       If reg2 in reg_Byte Then IF reg1=reg_IX Then Instr3($DD,$70 + reg2,val)
                                               Else Instr3($FD,$70 + reg2,val)
                           Else IllegalOperand;
      End;
     End;
    End;
    Else IllegalOperand;
   End;
  End;
  oEX:Begin
   reg1:=FindReg(GetWord,regs,regVals);
   Case reg1 of
    reg_DE:Begin { EX DE,HL }
     If GetWord<>','Then Error('"," attendu');
     Expect('HL');
     Instr1($EB);
    End;
    reg_AF:Begin { EX AF,AF' }
     If GetWord<>',' Then Error('"," attendu');
     Expect('AF');
     Expect('''');
     Instr1($08);
    End;
    reg_Paren:Begin { EX (SP),? }
     Expect('SP');
     If GetWord<>')' Then Error('")" attendu');
     If GetWord<>',' Then Error('"," attendu');
     reg2:=FindReg(GetWord,regs,regVals);
     Case reg2 of
      reg_HL:Instr1($E3);
      reg_IX:Instr2($DD,$E3);
      reg_IY:Instr2($FD,$E3);
      Else IllegalOperand;
     End;
    End;
    Else IllegalOperand;
   End;
  End;
  oADD:Begin
   reg1:=FindReg(GetWord,regs,regVals);
   Case reg1 of
    reg_A:Begin
     If GetWord<>','Then Error('"," attendu');
     DoArith($C6,$80);
    End;
    reg_HL,reg_IX,reg_IY:Begin
     If GetWord<>',' Then Error('"," attendu');
     reg2:=FindReg(GetWord,regs,regVals);
     If reg2=reg1 Then reg2 := reg_HL;
     If reg2 in reg_Word Then Begin
      Case reg1 of
       reg_HL:Instr1($09 + (reg2-reg_BC)*16);
       reg_IX:Instr2($DD,$09 + (reg2-reg_BC)*16);
       reg_IY:Instr2($FD,$09 + (reg2-reg_BC)*16);
      End;
     End
     Else IllegalOperand;
    End;
    Else IllegalOperand;
   End;
  End;
  oADC_SBC:Begin
   reg1:=FindReg(GetWord,regs,regVals);
   Case reg1 of
    reg_A:Begin
     If GetWord<>','Then Error('"," attendu');
     DoArith($CE+parm*16,$88+parm*16);
    End;
    reg_HL:Begin
     If GetWord<>','Then Error('"," attendu');
     reg2 := FindReg(GetWord,regs,regVals);
     If reg2 in reg_Word Then Instr2($ED,$4A+(reg2-reg_BC)*16-parm*8)
                         Else IllegalOperand;
    End;
    Else IllegalOperand;
   End;
  End;
  oINC_DEC:Begin
   reg1:=FindReg(GetWord,regs,regVals);
   Case reg1 of
    reg_B,reg_C,reg_D,reg_E,reg_H,reg_L,reg_A:Instr1($04 + reg1*8 + parm); { INC r }
    reg_BC,reg_DE,reg_HL,reg_SP:Instr1($03 + (reg1-reg_BC)*16 + parm*8); { INC rr }
    reg_IX:Instr2($DD,$23 + parm*8);
    reg_IY:Instr2($FD,$23 + parm*8);
    reg_Paren:Begin { INC (HL) }
     reg1:=FindReg(GetWord,regs,regVals);
     Case reg1 of
      reg_HL:Begin
       If GetWord<>')' Then Error('")" attendu');
       Instr1($34 + parm);
      End;
      reg_IX,reg_IY:Begin
       IXOffset;
       If reg1=reg_IX Then Instr3($DD,$34 + parm,val)
                      Else Instr3($FD,$34 + parm,val);
      End;
      Else IllegalOperand;
     End;
    End;
   End;
  End;
  oJP_CALL:Begin
   oldLine:=line;
   word:=GetWord;
   If word='('Then Begin
    If(parm SHR 8)<>$C3 Then IllegalOperand
     Else
    Begin
     reg1:=FindReg(GetWord,regs,regVals);
     If GetWord<>')'Then Error('")" attendu');
     Case reg1 of
      reg_HL:Instr1($E9);
      reg_IX:Instr2($DD,$E9);
      reg_IY:Instr2($FD,$E9);
      Else IllegalOperand;
     End;
    End;
   End
    Else
   Begin
    reg1:=FindReg(word,conds,condVals);
    If reg1=reg_None Then Begin
     line:=oldLine;
     val:=Eval;
     Instr3W(parm SHR 8,val);
    End
     Else
    Begin
     If GetWord<>','Then Error('"," attendu');
     val:=Eval;
     Instr3W((parm AND 255) + reg1*8,val);
    End;
    If((parm SHR 8)=$C3) AND (reg1<=3)Then Begin
     val:=locptr+2-val;
     If(-128<=val)and(val<=128)Then Warning('Instruction JR ne peut pas etre utilise ici');
    End;
   End;
  End;
  oJR:Begin
   oldLine:=line;
   reg1:=FindReg(GetWord,conds,condVals);
   If reg1=reg_None Then Begin
    line:=oldLine;
    val:=Eval;
    val:=val-locPtr-2;
    If(val<-128)or(val>127)Then Error('Branchement en dehors de l''intervalle');
    Instr2($18,val);
   End
    Else
   If reg1>=4 Then IllegalOperand
    Else
   Begin
    If GetWord<>','Then Error('"," attendu');
    val:=Eval;
    val:=val-locPtr-2;
    If(val<-128)or(val>127)Then Error('Branchement en dehors de l''intervalle');
    Instr2($20+reg1*8,val);
   End;
  End;
  oRET:Begin
   reg1:=FindReg(GetWord,conds,condVals);
   IF reg1=reg_None Then Instr1($C9)
                    Else Instr1($C0+reg1*8);
  End;
  oIN:Begin
   reg1:=FindReg(GetWord,regs,regVals);
   If Not(reg1 in[reg_B..reg_A])Then IllegalOperand
    Else
   Begin
    If GetWord<>','Then Error('"," attendu');
    Expect('(');
    oldLine:=line;
    reg2:=FindReg(GetWord,regs,regVals);
    If(reg1=reg_A)and(reg2=reg_none)Then Begin
     line:=oldLine;
     val:=Eval;
     If GetWord<>')'Then Error('")" attendu');
     Instr2($DB,val);
    End
     Else
    If reg2=reg_C Then Begin
     If GetWord<>')' Then Error('")" attendu');
     Instr2($ED,$40 + reg1*8)
    End
     Else
    IllegalOperand;
   End;
  End;
  oOUT:Begin
   Expect('(');
   oldLine:=line;
   reg1:=FindReg(GetWord,regs,regVals);
   If reg1=reg_None Then Begin
    line:=oldLine;
    val:=Eval;
    If GetWord<>')'Then Error('")" attendu');
    If GetWord<>','Then Error('"," attendu');
    Expect('A');
    Instr2($D3,val);
   End
    Else
   If reg1=reg_C Then Begin
    If GetWord<>')' Then Error('")" attendu');
    If GetWord<>',' Then Error('"," attendu');
    reg2:=FindReg(GetWord,regs,regVals);
    If reg2 in[reg_B..reg_A]Then Begin
     Instr2($ED,$41+reg2*8);
    End
     Else
    IllegalOperand;
   End
   Else IllegalOperand;
  End;
  oPushPop:Begin
   reg1:=FindReg(GetWord,regs,regVals);
   Case reg1 of
    reg_BC,reg_DE,reg_HL:Instr1(parm+(reg1-reg_BC)*16);
    reg_AF:Instr1(parm + $30);
    reg_IX:Instr2($DD,parm + $20);
    reg_IY:Instr2($FD,parm + $20);
    Else IllegalOperand;
   End;
  End;
  oArith:DoArith(parm SHR 8,parm AND 255);
  oRotate:Begin
   reg1:=FindReg(GetWord,regs,regVals);
   Case reg1 of
    reg_B,reg_C,reg_D,reg_E,reg_H,reg_L,reg_A:Instr2($CB,parm+reg1); { RLC r }
    reg_Paren:Begin
     reg1:=FindReg(GetWord,regs,regVals);
     Case reg1 of
      reg_HL:Begin
       If GetWord<>')'Then Error('")" attendu');
       Instr2($CB,parm+reg_M);
      End;
      reg_IX,reg_IY:Begin
       IXOffset;
       If reg1=reg_IX Then Instr4($DD,$CB,val,parm+reg_M)
                      Else Instr4($FD,$CB,val,parm+reg_M);
      End;
      Else IllegalOperand;
     End;
    End;
    Else IllegalOperand;
   End;
  End;
  oBit:Begin
   reg1:=Eval;
   reg2:=FindReg(GetWord,regs,regVals);
   Case reg2 of
    reg_B,reg_C,reg_D,reg_E,reg_H, reg_L,reg_A:Instr2($CB,parm + reg1*8 + reg2); { BIT n,r }
    reg_Paren:Begin { BIT n,(HL) }
     reg2:=FindReg(GetWord,regs,regVals);
     Case reg2 of
      reg_HL:Begin
       If GetWord<>')'Then Error('")" attendu');
       Instr2($CB,parm + reg1*8 + reg_M);
      End;
      reg_IX,reg_IY:Begin
       IXOffset;
       If reg2=reg_IX Then Instr4($DD,$CB,val,parm + reg1*8 + reg_M)
                      Else Instr4($FD,$CB,val,parm + reg1*8 + reg_M);
      End;
      Else IllegalOperand;
     End;
    End;
   End;
  End;
  oIM:Begin
   word:=GetWord;
   If word='0'Then Instr2($ED,$46)Else
   If word='1'Then Instr2($ED,$56)Else
   If word='2'Then Instr2($ED,$5E)
              Else IllegalOperand;
  End;
  oDJNZ:Begin
   val:=Eval;
   val:=val-locPtr-2;
   If(val<-128)or(val>127)Then Error('Branchement en dehors de l''intervalle');
   Instr2($10,val);
  End;
  oRST:Begin
   val:=Eval;
   If val in[0..7]Then Instr1($C7+val*8) Else
   If val in[$08,$10,$18,$20,$28,$30,$38]Then Instr1($C7+val)
                                         Else IllegalOperand;
  End;
  oDB:Begin
   bytStr:='';
   oldLine:=line;
   word:=GetWord;
   If(word='')or(word=';')Then Error('Operande attendu');
   While(word<>'')and(word<>';')do Begin
    If word=''''Then While word=''''do Begin
     val:=Pos('''',line);
     If val=0 Then Begin
      bytStr:=bytStr+line;
      line:='';
      word:='';
     End
      Else
     Begin
      bytStr:=bytStr+Copy(line,1,val-1);
      Delete(line,1,val);
      oldLine:=line;
      word:=GetWord;
      If word=''''Then bytStr:=bytStr+''''
                  Else line:=oldLine;
     End;
    End
     Else
    Begin
     line:=oldLine;
     bytStr:=bytStr+CHR(EvalByte);
    End;
    word:=GetWord;
    oldLine:=line;
    If word=','Then Begin
     word:=GetWord;
     If(word='')or(word=';')Then Error('Operande attendu');
    End;
   End;
   instrLen:=-Length(bytStr);
  End;
  oDW:Begin
   bytStr:='';
   oldLine:=line;
   word:=GetWord;
   If(word='')or(word=';')Then Error('Operande attendu');
   While(word<>'')and(word<>';')do Begin
    line:=oldLine;
    val:=Eval;
    bytStr:=bytStr+Chr(val and 255)+Chr(val shr 8);
    word:=GetWord;
    oldLine:=line;
    If word=','Then Begin
     word:=GetWord;
     If(word='')or(word=';')Then Error('Operande attendu');
    End;
   End;
   instrLen:=-Length(bytStr);
  End;
  oDS:Begin
   val:=Eval;
   If pass=2 Then Begin
    showAddr:=False;
    Delete(listLine,1,12);
    listLine:=Hex4(locPtr)+'  ('+Hex4(val)+')'+listLine;
   End;
   val:=val+locPtr;
   CodeOrg(val);
  End;
  oEND:Begin
   oldLine:=Line;
   If Length(GetWord)<>0 Then Begin
    line:=oldLine;
    val:=Eval;
    CodeXfer(val);
    line:=Copy(line,1,6)+'('+Hex4(val)+')'+Copy(line,13,255);
   End;
   sourceEnd:=True;
  End;
  Else Error('Opcode inconnu');
 End;
End;

Procedure DoLabelOp(typ,parm:Integer;labl:SymStr);
Var
 val:Integer;
 word:String;
Begin
 Case typ of
  oEQU:Begin
   If Length(labl)=0 Then Error('Etiquette attendu')
    Else
   Begin
    val:=Eval;
    listLine:=Copy(listLine,1,5)+'= '+Hex4(val)+Copy(listLine,12,255);
    DefSym(labl,val,parm=1,parm=0);
   End;
  End;
  oORG:Begin
   CodeOrg(Eval);
   DefSym(labl,locPtr,False,False);
   showAddr:=True;
  End;
  oLIST:Begin
   listThisLine:=True;
   If Length(labl)<>0 Then Error('Etiquette non alloue');
   word:=GetWord;
   If word='ON'Then listFlag:=True Else
   If word='OFF'Then listFlag:=False
                Else IllegalOperand;
  End;
  oOPT:Begin
   listThisLine:=True;
   If Length(labl)<>0 Then Error('Etiquette non alloue');
   word:=GetWord;
   If word='LIST'Then listFlag:=True Else
   If word='NOLIST'Then listFlag:=False
                   Else Error('Option illegale');
  End;
  Else Error('Opcode inconnu');
 End;
End;

Procedure ListOut;
Var
 i:Integer;
Begin
 If Trim(listLine)=#12 Then WriteLn(listing,#12) Else
 If Trim(listLine)=''Then WriteLn(listing)
  Else
 Begin
  i:=Length(listLine);
  While(i>0) AND (listLine[i]=' ')do Dec(i);
  listLine[0]:=CHR(i);
  WriteLn(listing,listLine);
  If(errFlag and cl_Err) or warnFlag Then WriteLn(listLine);
 End;
End;

Procedure DoPass;
Var
 labl:SymStr;
 opcode:OpcdStr;
 typ:Integer;
 parm:Integer;
 i:Integer;
 word:String;
Begin
 Assign(source,cl_SrcName);
 Reset(source);
 sourceEnd:=False;
 WriteLn('Passage ',pass);
 CodeOrg(0);
 errCount:=0;
 listFlag:=True;
 While (Not Eof(source)) and(Not SourceEnd) do Begin
  ReadLn(source,line);
  errFlag:=False;
  warnFlag:=False;
  instrLen:=0;
  showAddr:=False;
  listThisLine:=ListFlag;
  listLine:='                ';
  If Pass=2 Then listLine:=Copy(listLine,1,16)+line;
  labl:='';
  If(Length(line)>0)and(Pos(line[1],white)=0)Then Begin
   labl:=GetWord;
   showAddr:=(Length(labl)<>0);
   If(Length(line)>0)and(line[1]=':')Then Delete(line,1,1);
  End;
  opcode:=GetWord;
  If Length(opcode)=0 Then Begin
   typ:=0;
   DefSym(labl,locPtr,FALSE,FALSE);
  End
   Else
  Begin
   FindOpcode(opcode,typ,parm);
   If typ=oIllegal Then Error('Opcode illegale "'+Trim(opcode) + '"') Else
   If typ<0 Then Begin
    showAddr:=False;
    DoLabelOp(typ,parm,labl);
   End
    Else
   Begin
    showAddr:=True;
    DefSym(labl,locPtr,FALSE,FALSE);
    DoOpcode(typ,parm);
   End;
   If(typ<>oIllegal)and(Length(GetWord)>0)Then Error('Trop d''operandes');
  End;
  If Pass=2 Then Begin
   If ShowAddr Then listLine:=Hex4(locPtr)+Copy(listLine,5,255);
   If instrLen>0 Then For i:=1 to instrLen do Begin
    word:=Hex2(instr[i]);
    listLine[i*2+4]:=word[1];
    listLine[i*2+5]:=word[2];
    CodeOut(instr[I]);
   End
    Else
   For i:=1 to -instrLen do Begin
    If I<=5 Then Begin
     word:=Hex2(Ord(bytStr[i]));
     listLine[i*2+4]:=Word[1];
     listLine[i*2+5]:=Word[2];
    End;
    CodeOut(ORD(bytStr[i]));
   End;
   If listThisLine Then ListOut;
  End;
  locPtr:=locPtr+Abs(instrLen);
 End;
 If Pass=2 Then CodeEnd;
 If Pass=2 Then While Not Eof(source)do Begin
  listThisLine:=listFlag;
  listLine:='                '+line;
  If(Length(line)>0)and(Pos(line[1],white)<>0)Then Begin
   word:=GetWord;
   If Length(word)<>0 Then Begin
    If word='LIST'Then Begin
     listThisLine:=TRUE;
     word:=GetWord;
     If word='ON'Then listFlag:=True Else
     If word='OFF'Then listFlag:=False
                  Else listThisLine:=listFlag;
    End
     Else
    If word='OPT' Then Begin
     listThisLine:=True;
     word:=GetWord;
     If word='LIST'Then listFlag:=True Else
     If word='NOLIST'Then listFlag:=False
                     Else listThisLine:=listFlag;
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
  i:=symTab;
  j:=i^.next;
  While(j<>NIL)do Begin
   sorted:=True;
   While(j<>NIL)do Begin
    If j^.name < i^.name Then Begin
     temp:=i^;
     i^:=j^;
     j^:=temp;
     t:=i^.next;
     i^.next:=j^.next;
     j^.next:=t;
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
 s:=p^.name;
 While Length(s)<=maxSymLen do StAppendCh(s,' ');
 s:=s+Hex4(p^.value);
 StAppendCh(s,' ');
 If Not p^.defined Then StAppendCh(s,'U');
 If p^.multiDef Then StAppendCh(s,'M');
 If p^.isSet Then StAppendCh(s,'S');
 If p^.equ Then StAppendCh(s,'E');
 While Length(s)<=maxSymLen + 9 do StAppendCh(s,' ');
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
  p:=p^.next;
  i:=i+1;
  If(p=NIL)or(i>symTabCols)Then Begin
   i:=1;
   WriteLn(listing,RTrim(s));
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
  option:=optStr;
  optStr:='';
 End
  Else
 Begin
  option:=Copy(optStr,1,p-1);
  optStr:=Copy(optStr,p+1,255);
 End;
 optStr:=Trim(optStr);
 GetOption:=StrToUpper(option);
End;

Function GetOptions(Var cl_SrcName,cl_ListName,cl_ObjName,cl_BinName:String;
                    Var cl_Err:Boolean):Boolean;
Var
 s:String;
 len:Integer;
 optStr:String;
 option:String;
 optParm:String;
 prefix:String;
 p:Integer;
 err:Integer;
 optErr:Boolean;
 i:Integer;
Begin
 cl_SrcName:='';
 cl_ListName:='NUL';
 cl_ObjName:='NUL';
 cl_Err:=False;
 cl_Warn:=False;
 optErr:=False;
 optStr:=ParamStr(1);
 For i:=2 to ParamCount do optStr:=optStr+' '+ParamStr(i);
 option:=GetOption(optStr);
 While Length(option)<>0 do Begin
  optParm:='';
  p:=Pos('=',option);
  If p>0 Then Begin
   optParm:=Copy(option,p+1,255);
   option:=Copy(option,1,p-1);
  End;
  If option='-L'Then cl_ListName:=optParm Else
  If option='-O'Then cl_ObjName :=optParm Else
  If option='-E'Then cl_Err:=True Else
  If option='-W'Then cl_Warn:=True Else
  If option='?'Then optErr:=True
   Else
  Begin
   If(Copy(option,1,1)='-')or(Length(cl_SrcName)<>0)or(Length(optParm)<>0)Then Begin
    optErr:=True;
    WriteLn('option de ligne de commande illegal ',option);
   End
    Else
   Begin
    cl_SrcName:=option;
    If(Pos('.',cl_SrcName)=0)and(p=0)Then cl_SrcName:=cl_SrcName+'.ASM';
    p:=Pos('.',option);
    If p=0 Then prefix:=option
           Else prefix:=Copy(option,1,p-1);
   End;
  End;
  option:=GetOption(optStr);
 End;
 If cl_SrcName=''Then Begin
  optErr:=True;
  WriteLn('Fichier source non specifie')
 End;
 If cl_ListName=''Then cl_ListName:= prefix+'.LIS';
 If cl_ObjName=''Then cl_ObjName:=prefix +'.DAT';
 if cl_BinName=''Then cl_BinName:=prefix+'.BIN';
 If Copy(cl_ListName,1,1)='.'Then cl_ListName:=prefix+cl_ListName;
 If Copy(cl_ObjName,1,1)='.'Then cl_ObjName:=prefix+cl_ObjName;
 GetOptions := optErr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
  GetOptions(cl_SrcName,cl_ListName,cl_ObjName,cl_BinName,cl_Err)Then Begin
  WriteLn('ASMZ80 : Cette commande permet de compiler un code source assembleur Z80.');
  WriteLn;
  WriteLn('Syntaxe :  ASMZ80 [options] src [options]');
  WriteLn;
  WriteLn('    -E  Affiche les erreurs a l''ecran');
  WriteLn('    -L  Fabrique un fichier de liste src.LIS');
  WriteLn('    -L=name');
  WriteLn('    -O  Fabrique un fichier objet de src.OBJ');
  WriteLn('    -O=name');
  WriteLn('    -B  Fabrique un fichier binaire de src.BIN');
  WriteLn('    -B=nom');
  WriteLn;
  Halt;
 End;
 Assign(listing,cl_ListName);
 Rewrite(listing);
 Assign(_object,cl_ObjName);
 Rewrite(_object);
 Assign(Binary,cl_BinName);
 Rewrite(Binary);
 symTab:=NIL;
 xferAddr:=0;
 xferFound:=False;
 InitOpcodes;
 pass:=1;
 DoPass;
 pass:=2;
 DoPass;
 WriteLn(listing);
 WriteLn(listing,errCount:5,' erreur(s) total');
 WriteLn(listing);
 If cl_Err Then Begin
  WriteLn;
  WriteLn(errCount:5,' erreur(s) total');
 End;
 DumpSymTab;
 Close(listing);
 Close(_object);
 Close(Binary);
 If errCount<>0 Then Halt(1);
END.