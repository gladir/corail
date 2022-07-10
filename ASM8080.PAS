{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program ASM8080;

{$R-}

Const
 Instr8080:Array[0..26]of Record
  InstrName:String[7];
  InstrOpcode:Word;
 End=(
  (InstrName:'NOP';InstrOpcode:0),
  (InstrName:'RLC';InstrOpcode:7),
  (InstrName:'RRC';InstrOpcode:15),
  (InstrName:'RAL';InstrOpcode:23),
  (InstrName:'RAR';InstrOpcode:31),
  (InstrName:'DAA';InstrOpcode:39),
  (InstrName:'CMA';InstrOpcode:47),
  (InstrName:'RIM';InstrOpcode:48),
  (InstrName:'STC';InstrOpcode:55),
  (InstrName:'SIM';InstrOpcode:56),
  (InstrName:'CMC';InstrOpcode:63),
  (InstrName:'HLT';InstrOpcode:118),
  (InstrName:'RNZ';InstrOpcode:192),
  (InstrName:'RZ';InstrOpcode:200),
  (InstrName:'RET';InstrOpcode:201),
  (InstrName:'RNC';InstrOpcode:208),
  (InstrName:'RC';InstrOpcode:216),
  (InstrName:'RPO';InstrOpcode:224),
  (InstrName:'XTHL';InstrOpcode:227),
  (InstrName:'RPE';InstrOpcode:232),
  (InstrName:'PCHL';InstrOpcode:233),
  (InstrName:'XCHG';InstrOpcode:235),
  (InstrName:'RP';InstrOpcode:240),
  (InstrName:'DI';InstrOpcode:243),
  (InstrName:'RM';InstrOpcode:248),
  (InstrName:'SPHL';InstrOpcode:249),
  (InstrName:'EI';InstrOpcode:251)
 );

 maxSymLen=16;
 maxOpcdLen=4;

 alphaNumeric='1234567890$ABCDEFGHIJKLMNOPQRSTUVWXYZ_';
 numeric='1234567890';
 hex='0123456789ABCDEF';
 white=#9' ';

 oIllegal=0;
 oNone=1;
 oOne=2;
 oTwo=3;
 oInrDcr=4;
 oArith=5;
 oMOV=6;
 oMVI=7;
 oLXI=8;
 oInxDcx=9;
 oPushPop=10;
 oStaxLdax=11;
 oRST=12;
 oDB=13;
 oDW=14;
 oDS=15;
 oEQU=-16;
 oORG=-17;
 oEND=18;
 oLIST=-19;
 oOPT=-20;

 regs=' B C D E H L M A ';
 regVals=' 0 1 2 3 4 5 6 7 ';

 regPairs=' B D H SP BC DE HL ';
 regPairVals=' 0 1 2 3  0  1  2  ';

 pushRegs=' B D H PSW BC DE HL AF ';
 pushRegVals=' 0 1 2 3   0  1  2  3  ';

 staxRegs=' B D BC DE ';
 staxRegVals=' 0 1 0  1  ';

Type
 SymStr=String[maxSymLen];
 SymPtr=^SymRec;
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
 pass:Integer;
 errFlag:Boolean;
 errCount:Integer;

 line:String;
 listLine:String;
 listFlag:Boolean;
 listThisLine:Boolean;
 sourceEnd:Boolean;

 instr:Array[1..3] OF Integer;
 instrLen:Integer;

 bytStr:String;
 showAddr:Boolean;
 xferAddr:Integer;
 xferFound:Boolean;

 cl_SrcName,cl_ListName,cl_ObjName,cl_BinName:String;
 cl_Err:Boolean;

 source,_Object,listing:Text;
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

Function Hex2(i:Integer):String;Begin
 i:=i and 255;
 Hex2:=Copy(hex,(i shr 4)+1,1)+Copy(hex,(i and 15)+1,1);
End;

Function Hex4(i:Integer):String;Begin
 Hex4:=Hex2(i SHR 8)+Hex2(i AND 255);
End;

Procedure Error(message:String);Begin
 errFlag:=True;
 Inc(errCount);
 If pass<>1 Then Begin
  listThisLine := TRUE;
  WriteLn(listing,'*** Erreur:  ',Message,' ***');
  IF cl_Err THEN WriteLn('*** Erreur:  ',Message,' ***');
 End;
End;

Procedure AddOpcode(name:OpcdStr;typ,parm:Integer);
Var
 p:OpcdPtr;
Begin
 New(p);
 p^.name:=name;
 p^.typ:=typ;
 p^.parm:=parm;
 p^.next:=opcdTab;
 opcdTab:=p;
End;

Procedure FindOpcode(name:OpcdStr;Var typ,parm:Integer);
Var
 p:OpcdPtr;
 found:Boolean;
Begin
 found:=False;
 p:=opcdTab;
 While(p<>NIL)and Not Found do Begin
  found := (p^.name = name);
  If Not Found Then p:=p^.next;
 End;
 If Not found Then Begin
  typ:=oIllegal;
  parm:=0;
 End
  Else
 Begin
  typ:=p^.typ;
  parm:=p^.parm;
 End;
End;

Procedure InitOpcodes;
Var
 I:Byte;
Begin
 opcdTab:=NIL;
 For I:=0 to High(Instr8080)do AddOpcode(Instr8080[I].InstrName,oNone,Instr8080[I].InstrOpcode);

 AddOpcode('ADI' ,oOne,198);
 AddOpcode('ACI' ,oOne,206);
 AddOpcode('OUT' ,oOne,211);
 AddOpcode('SUI' ,oOne,214);
 AddOpcode('IN'  ,oOne,219);
 AddOpcode('SBI' ,oOne,222);
 AddOpcode('ANI' ,oOne,230);
 AddOpcode('XRI' ,oOne,238);
 AddOpcode('ORI' ,oOne,246);
 AddOpcode('CPI' ,oOne,254);

 AddOpcode('SHLD',oTwo,34);
 AddOpcode('LHLD',oTwo,42);
 AddOpcode('STA' ,oTwo,50);
 AddOpcode('LDA' ,oTwo,58);
 AddOpcode('JNZ' ,oTwo,194);
 AddOpcode('JMP' ,oTwo,195);
 AddOpcode('CNZ' ,oTwo,196);
 AddOpcode('JZ'  ,oTwo,202);
 AddOpcode('CZ'  ,oTwo,204);
 AddOpcode('CALL',oTwo,205);
 AddOpcode('JNC' ,oTwo,210);
 AddOpcode('CNC' ,oTwo,212);
 AddOpcode('JC'  ,oTwo,218);
 AddOpcode('CC'  ,oTwo,220);
 AddOpcode('JPO' ,oTwo,226);
 AddOpcode('CPO' ,oTwo,228);
 AddOpcode('JPE' ,oTwo,234);
 AddOpcode('CPE' ,oTwo,236);
 AddOpcode('JP'  ,oTwo,242);
 AddOpcode('CP'  ,oTwo,244);
 AddOpcode('JM'  ,oTwo,250);
 AddOpcode('CM'  ,oTwo,252);

 AddOpcode('INR' ,oInrDcr,4);
 AddOpcode('DCR' ,oInrDcr,5);

 AddOpcode('ADD' ,oArith,128);
 AddOpcode('ADC' ,oArith,136);
 AddOpcode('SUB' ,oArith,144);
 AddOpcode('SBB' ,oArith,152);
 AddOpcode('ANA' ,oArith,160);
 AddOpcode('XRA' ,oArith,168);
 AddOpcode('ORA' ,oArith,176);
 AddOpcode('CMP' ,oArith,184);

 AddOpcode('MOV' ,oMOV,64);

 AddOpcode('MVI' ,oMVI,6);

 AddOpcode('LXI' ,oLXI,1);

 AddOpcode('INX' ,oInxDcx,3);
 AddOpcode('DAD' ,oInxDcx,9);
 AddOpcode('DCX' ,oInxDcx,11);

 AddOpcode('POP' ,oPushPop,193);
 AddOpcode('PUSH',oPushPop,197);

 AddOpcode('STAX',oStaxLdax,2);
 AddOpcode('LDAX',oStaxLdax,10);

 AddOpcode('RST' ,oRST,199);

 AddOpcode('DB'  ,oDB,0);
 AddOpcode('DW'  ,oDW,0);
 AddOpcode('DS'  ,oDS,0);

 AddOpcode('='   ,oEQU,0);
 AddOpcode('EQU' ,oEQU,0);
 AddOpcode('SET' ,oEQU,1);

 AddOpcode('ORG' ,oORG,0);
 AddOpcode('END' ,oEND,0);
 AddOpcode('LIST',oLIST,0);
 AddOpcode('OPT' ,oOPT,0);
End;

Function FindSym(symName:SymStr):SymPtr;
Var
 p:SymPtr;
 found:Boolean;
Begin
 found:=False;
 p:=SymTab;
 While(p<>NIL)and Not(Found)do Begin
  found:=(p^.name=symName);
  If Not(Found)Then p:=p^.next;
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
Begin
 p:=FindSym(symName);
 If p=NIL Then p:=AddSym(symName);
 If Not p^.defined Then Error('Symbole "' + symName + '" indefini');
 RefSym := p^.value;
End;

Procedure DefSym(symName:SymStr; val:Integer;setSym,equSym:Boolean);
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
   done:=False;
   While(Length(line)>0)and Not Done do Begin
    word:=word+Upcase(line[1]);
    Delete(line,1,1);
    If Length(line)>0 Then Done:=Pos(Upcase(line[1]),AlphaNumeric)=0;
   End;
  End;
 End;
 GetWord:=Word;
End;

Procedure Expect(expected:String);Begin
 If GetWord<>expected Then Error('"' + expected + '" attendu');
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
  octVal := 0;
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
 For i:=1 to Length(hexStr) do Begin
  n:=Pos(Upcase(hexStr[i]),'0123456789ABCDEF');
  If n=0 Then evalErr:=True
         Else hexVal:=hexVal*16+n-1;
 End;
 If evalErr Then Begin
  hexVal:=0;
  Error('Nombre hexadecimal invalide');
 End;
 EvalHex:=hexVal;
End;

Function Eval:Integer; Forward;

Function Factor:Integer;
Var
 word:String;
 val:Integer;
Begin
 word:=GetWord;
 If pos('0X',word)=1 Then Begin
  Delete(word,1,2);
  If Word=''Then Word:='0';
  Word:=Word+'H';
 End;
 val :=0;
 If Length(word)=0 Then Error('Operande attendu') Else
 If(Word='.')or(Word='*')Then val:=locPtr Else
 If word='-'Then val:=-Factor Else
 If word='+'Then val:=Factor Else
 If word='~'Then val:=-Factor-1 Else
 If word='('Then Begin
  val:=Eval;
  Expect(')');
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
  Case word[Length(word)] Of
   'O': val:=EvalOct(Copy(word,1,Length(word)-1));
   'D': val:=EvalDec(Copy(word,1,Length(word)-1));
   'H': val:=EvalHex(Copy(word,1,Length(word)-1));
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
 oldLine:=Line;
 word:=GetWord;
 While(word='*')or(word='/')or(word='%')or(word='&')do Begin
  Case word[1]of
   '*':val:=val*Factor;
   '/':val:=val div Factor;
   '%':val:=val mod Factor;
   '&':val:=(val shr 8) and Factor;
  End;
  oldLine:=Line;
  word:=GetWord;
 End;
 line:=oldLine;
 Term:=val;
End;

Function Eval:Integer;
Var
 word:String;
 val:Integer;
 oldLine:String;
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
 IF(val<-128)or(val>255)Then Error('Octet en dehors de l''intervalle');
 EvalByte:=val and 255;
End;

Function FindReg(regName,regList,valList:String):Integer;
Var
 p,reg,code:Integer;
Begin
 p:=Pos(' '+Trim(regName)+' ',regList);
 If p=0 Then Begin
  reg:=0;
  Error('Registre illegale "'+Trim(RegName)+'"');
 End
  Else
 Val(Copy(valList,p,2),reg,code);
 FindReg:=reg;
End;

Procedure CodeOut(_byte:Integer);Begin
 If pass=2 Then Begin
  WriteLn(_Object,Hex2(_byte));
  Write(Binary,Byte(_byte));
 End;
End;

Procedure CodeOrg(addr:Integer);Begin
 locPtr := addr;
 If pass=2 Then WriteLn(_Object,':',Hex4(addr));
End;

Procedure CodeEnd;Begin
 If(pass=2)and xferFound Then WriteLn(_Object,'$',Hex4(xferAddr));
End;

Procedure CodeXfer(addr:Integer);Begin
 xferAddr:=addr;
 xferFound:=True;
End;

Procedure DoOpcode(typ,parm:Integer);
Var
 val:Integer;
 reg1:Integer;
 reg2:Integer;
 word:String;
 oldLine:String;
Begin
 Case typ of
  oNone:Begin
   instr[1]:=parm;
   instrLen:=1;
  End;
  oOne:Begin
   instr[1]:=parm;
   instr[2]:=EvalByte;
   instrLen:=2;
  End;
  oTwo:Begin
   val:=Eval;
   instr[1]:=parm;
   instr[2]:=val and 255;
   instr[3]:=val shr 8;
   instrLen:=3;
  End;
  oInrDcr:Begin
   reg1:=FindReg(GetWord,regs,regVals);
   instr[1]:=parm+reg1*8;
   instrLen:=1;
  End;
  oArith:Begin
   reg1:=FindReg(GetWord,regs,regVals);
   instr[1]:=parm+reg1;
   instrLen:=1;
  End;
  oMOV:Begin
   reg1:=FindReg(GetWord,regs,regVals);
   Expect(',');
   reg2:=FindReg(GetWord,regs,regVals);
   instr[1]:=parm+reg1*8+reg2;
   instrLen:=1;
  End;
  oMVI:Begin
   reg1:=FindReg(GetWord,regs,regVals);
   Expect(',');
   instr[1]:=parm+reg1*8;
   instr[2]:=EvalByte;
   instrLen:=2;
  End;
  oLXI:Begin
   reg1:=FindReg(GetWord,regPairs,regPairVals);
   Expect(',');
   val:=Eval;
   instr[1]:=parm+reg1*16;
   instr[2]:=val and 255;
   instr[3]:=val shr 8;
   instrLen:=3;
  End;
  oInxDcx:Begin
   reg1:=FindReg(GetWord,regPairs,regPairVals);
   instr[1]:=parm+reg1*16;
   instrLen:=1;
  End;
  oPushPop:Begin
   reg1:=FindReg(GetWord,pushRegs,pushRegVals);
   instr[1]:=parm+reg1*16;
   instrLen:=1;
  End;
  oStaxLdax:Begin
   reg1:=FindReg(GetWord,staxRegs,staxRegVals);
   instr[1]:=parm+reg1*16;
   instrLen:=1;
  End;
  oRST:Begin
   val:=Eval;
   Case val of
    0,1,2,3,4,5,6,7:val:=val*8;
    8,16,24,32,40,48,56:;
    Else Begin
     Error('Nombre de redemarrage illegale');
     val:=0;
    End;
   End;
   instr[1]:=parm+val;
   instrLen:=1;
  End;
  oDB:Begin
   oldLine:=line;
   word:=GetWord;
   If word=''''Then Begin
    val:=Pos('''',line);
    If val=0 Then Begin
     bytStr:=line;
     line:='';
    End
     Else
    Begin
     bytStr:=Copy(line,1,val-1);
     Delete(line,1,val);
    End;
    instrLen:=-Length(bytStr);
   End
   Else Begin
    line:=oldLine;
    instr[1]:=EvalByte;
    instrLen:=1;
   End;
  End;
  oDW:Begin
   val:=Eval;
   instr[1]:=val AND 255;
   instr[2]:=val SHR 8;
   instrLen:=2;
  End;
  oDS:Begin
   val:=Eval;
   If pass=2 Then Begin
    showAddr:=False;
    Delete(listLine,1,13);
    listLine:=Hex4(locPtr)+':  ('+Hex4(val)+')'+listLine;
   End;
   val:=val+locPtr;
   CodeOrg(val);
  End;
  oEND:Begin
   oldLine:=line;
   If Length(GetWord)<>0 Then Begin
    line:=oldLine;
    val:=Eval;
    CodeXfer(val);
    line:=Copy(line,1,7)+'('+Hex4(val)+')'+Copy(line,14,255);
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
    listLine:=Copy(listLine,1,6)+'= '+Hex4(val)+Copy(listLine,13,255);
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
   If Length(labl)<>0 Then Error('Etiquette non autorise');
   word:=GetWord;
   If word='ON'Then listFlag:=True Else
   If word='OFF'Then listFlag:=False
                Else Error('Operande illegale');
  End;
  oOPT:Begin
   listThisLine:=True;
   If Length(labl)<>0 Then Error('Etiquette non autorise');
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
  While(i>0)and(listLine[i]=' ')do Dec(i);
  listLine[0]:=Chr(i);
  WriteLn(listing,listLine);
  If errFlag and cl_Err Then WriteLn(listLine);
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
 While(Not Eof(source))and(Not SourceEnd)do Begin
  ReadLn(source,line);
  errFlag:=False;
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
   DefSym(labl,locPtr,False,False);
  End
   Else
  Begin
   FindOpcode(opcode,typ,parm);
   If typ=oIllegal Then Error('Opcode illegale "'+Trim(opcode)+'"') Else
   If typ<0 Then Begin
    showAddr:=False;
    DoLabelOp(typ,parm,labl);
   End
    Else
   Begin
    showAddr:=True;
    DefSym(labl,locPtr,False,False);
    DoOpcode(typ,parm);
   End;
   If(typ<>oIllegal)and(Length(GetWord)>0)Then Error('Trop d''operandes');
  End;
  If Pass=2 Then Begin
   If ShowAddr Then listLine:=Hex4(locPtr)+':'+Copy(listLine,6,255);
   If instrLen>0 Then For i:=1 to instrLen do Begin
    word:=Hex2(instr[i]);
    listLine[i*3+4]:=word[1];
    listLine[i*3+5]:=word[2];
    CodeOut(instr[I]);
   End
    Else
   For i:=1 to -instrLen do Begin
    If I<=3 Then Begin
     word:=Hex2(Ord(bytStr[i]));
     listLine[i*3+4]:=word[1];
     listLine[i*3+5]:=word[2];
    End;
    CodeOut(Ord(bytStr[i]));
   End;
   If listThisLine Then ListOut;
  End;
  locPtr:=locPtr+Abs(instrLen);
 End;
 If Pass=2 Then CodeEnd;
 If Pass=2 Then While Not Eof(source)do Begin
  listThisLine:=listFlag;
  listLine:='                '+line;
  If Length(line)>0 Then If Pos(line[1],white)<>0 Then Begin
   word:=GetWord;
   If Length(word)<>0 Then Begin
    If word='LIST'Then Begin
     listThisLine:=True;
     word:=GetWord;
     If word='ON'Then listFlag:=True Else
     If word='OFF'Then listFlag:=False
                  Else listThisLine:=listFlag;
    End
     Else
    If word='OPT'Then Begin
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
    If j^.name<i^.name Then Begin
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

Procedure DumpSym(p:SymPtr);Begin
 Write(listing,p^.name:maxSymLen,' ',Hex4(p^.value));
 If Not p^.defined Then Write(listing,' U');
 If p^.multiDef Then Write(listing,' M');
 If p^.isSet Then Write(listing,' S');
 If p^.equ Then Write(listing,' E');
 WriteLn(listing);
End;

Procedure DumpSymTab;
Var
 p:SymPtr;
Begin
 SortSymTab;
 p:=symTab;
 While(p<>NIL)do Begin
  DumpSym(p);
  p:=p^.next;
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
 optStr:=StrToUpper(Trim(optStr));
 GetOption:=option;
End;

Function GetOptions(Var cl_SrcName, cl_ListName,cl_ObjName,cl_BinName:String;
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
  If option='?'Then optErr:=True
   Else
  Begin
   If(Copy(option,1,1)='-')or(Length(cl_SrcName)<>0)or(Length(optParm)<>0)Then Begin
    optErr:=TRUE;
    WriteLn('Option de ligne de commande illegale: ',option);
   End
    Else
   Begin
    cl_SrcName:=option;
    If(Pos('.',cl_SrcName)=0)and(p=0)THEN cl_SrcName:=cl_SrcName+'.ASM';
    p:=Pos('.',option);
    If p=0 Then prefix:=option
           Else prefix:=Copy(option,1,p-1);
   End;
  End;
  option := GetOption(optStr);
 End;
 If cl_SrcName=''Then Begin
  optErr:=True;
  WriteLn('Fichier source non specifie')
 End;
 If cl_ListName=''Then cl_ListName:=prefix+'.LIS';
 If cl_ObjName=''Then cl_ObjName:=prefix+'.DAT';
 If cl_BinName=''Then cl_BinName:=prefix+'.BIN';
 If Copy(cl_ListName,1,1)='.'Then cl_ListName:=prefix+cl_ListName;
 If Copy(cl_ObjName ,1,1)='.'Then cl_ObjName:=prefix+cl_ObjName;
 GetOptions := optErr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
    GetOptions(cl_SrcName,cl_ListName,cl_ObjName,cl_BinName,cl_Err)Then Begin
  WriteLn;
  WriteLn('ASM8080 : Cette commande permet de compiler un code source assembleur 8080.');
  WriteLn;
  WriteLn('Syntaxe : ASM8080 [options] src [options]');
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
 Assign(_Object,cl_ObjName);
 Rewrite(_Object);
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
 WriteLn(listing,errCount:5,' Erreur total(s)');
 WriteLn(listing);
 If cl_Err Then Begin
  WriteLn;
  WriteLn(errCount:5,' Erreur total(s)');
 End;
 DumpSymTab;
 Close(listing);
 Close(_Object);
END.