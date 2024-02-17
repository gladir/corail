{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program DIS8080;

Uses Strings;

Type
 OperandType=(OPERAND_NONE,OPERAND_BYTE,OPERAND_WORD);
 InstInfoRec=Record
  Opcode:Integer;
  Mnemonic:PChar;
  Size:Integer;
  Operand:OperandType;
 End;

{ Cette table d‚crit toutes les instructions Intel 8080 }
Const InstInfo:Array[0..244]of InstinfoRec=(
  (* Groupe de transfŠre de donn‚es *)
  (Opcode:$78;Mnemonic:'MOV A,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$79;Mnemonic:'MOV A,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$7A;Mnemonic:'MOV A,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$7B;Mnemonic:'MOV A,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$7C;Mnemonic:'MOV A,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$7D;Mnemonic:'MOV A,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$7E;Mnemonic:'MOV A,M';Size:1;Operand:OPERAND_NONE),
  (Opcode:$7F;Mnemonic:'MOV A,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$40;Mnemonic:'MOV B,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$41;Mnemonic:'MOV B,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$42;Mnemonic:'MOV B,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$43;Mnemonic:'MOV B,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$44;Mnemonic:'MOV B,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$45;Mnemonic:'MOV B,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$46;Mnemonic:'MOV B,M';Size:1;Operand:OPERAND_NONE),
  (Opcode:$47;Mnemonic:'MOV B,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$48;Mnemonic:'MOV C,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$49;Mnemonic:'MOV C,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$4A;Mnemonic:'MOV C,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$4B;Mnemonic:'MOV C,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$4C;Mnemonic:'MOV C,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$4D;Mnemonic:'MOV C,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$4E;Mnemonic:'MOV C,M';Size:1;Operand:OPERAND_NONE),
  (Opcode:$4F;Mnemonic:'MOV C,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$50;Mnemonic:'MOV D,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$51;Mnemonic:'MOV D,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$52;Mnemonic:'MOV D,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$53;Mnemonic:'MOV D,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$54;Mnemonic:'MOV D,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$55;Mnemonic:'MOV D,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$56;Mnemonic:'MOV D,M';Size:1;Operand:OPERAND_NONE),
  (Opcode:$57;Mnemonic:'MOV D,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$58;Mnemonic:'MOV E,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$59;Mnemonic:'MOV E,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$5A;Mnemonic:'MOV E,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$5B;Mnemonic:'MOV E,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$5C;Mnemonic:'MOV E,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$5D;Mnemonic:'MOV E,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$5E;Mnemonic:'MOV E,M';Size:1;Operand:OPERAND_NONE),
  (Opcode:$5F;Mnemonic:'MOV E,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$60;Mnemonic:'MOV H,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$61;Mnemonic:'MOV H,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$62;Mnemonic:'MOV H,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$63;Mnemonic:'MOV H,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$64;Mnemonic:'MOV H,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$65;Mnemonic:'MOV H,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$66;Mnemonic:'MOV H,M';Size:1;Operand:OPERAND_NONE),
  (Opcode:$67;Mnemonic:'MOV H,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$68;Mnemonic:'MOV L,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$69;Mnemonic:'MOV L,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$6A;Mnemonic:'MOV L,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$6B;Mnemonic:'MOV L,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$6C;Mnemonic:'MOV L,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$6D;Mnemonic:'MOV L,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$6E;Mnemonic:'MOV L,M';Size:1;Operand:OPERAND_NONE),
  (Opcode:$6F;Mnemonic:'MOV L,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$70;Mnemonic:'MOV M,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$71;Mnemonic:'MOV M,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$72;Mnemonic:'MOV M,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$73;Mnemonic:'MOV M,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$74;Mnemonic:'MOV M,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$75;Mnemonic:'MOV M,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$77;Mnemonic:'MOV M,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$06;Mnemonic:'MVI B,' ;Size:2;Operand:OPERAND_BYTE),
  (Opcode:$16;Mnemonic:'MVI D,' ;Size:2;Operand:OPERAND_BYTE),
  (Opcode:$26;Mnemonic:'MVI H,' ;Size:2;Operand:OPERAND_BYTE),
  (Opcode:$36;Mnemonic:'MVI M,' ;Size:2;Operand:OPERAND_BYTE),
  (Opcode:$0E;Mnemonic:'MVI C,' ;Size:2;Operand:OPERAND_BYTE),
  (Opcode:$1E;Mnemonic:'MVI E,' ;Size:2;Operand:OPERAND_BYTE),
  (Opcode:$2E;Mnemonic:'MVI L,' ;Size:2;Operand:OPERAND_BYTE),
  (Opcode:$3E;Mnemonic:'MVI A,' ;Size:2;Operand:OPERAND_BYTE),
  (Opcode:$3A;Mnemonic:'LDA'    ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$32;Mnemonic:'STA'    ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$2A;Mnemonic:'LHLD'   ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$22;Mnemonic:'SHLD'   ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$01;Mnemonic:'LXI B,' ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$11;Mnemonic:'LXI D,' ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$21;Mnemonic:'LXI H,' ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$31;Mnemonic:'LXI SP,';Size:3;Operand:OPERAND_WORD),
  (Opcode:$0A;Mnemonic:'LDAX B' ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$1A;Mnemonic:'LDAX D' ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$02;Mnemonic:'STAX B' ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$12;Mnemonic:'STAX D' ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$EB;Mnemonic:'XCHG'   ;Size:1;Operand:OPERAND_NONE),

  { Groupe arithm‚tique }
  (Opcode:$80;Mnemonic:'ADD B'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$81;Mnemonic:'ADD C'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$82;Mnemonic:'ADD D'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$83;Mnemonic:'ADD E'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$84;Mnemonic:'ADD H'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$85;Mnemonic:'ADD L'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$86;Mnemonic:'ADD M'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$87;Mnemonic:'ADD A'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$C6;Mnemonic:'ADI'    ;Size:2;Operand:OPERAND_BYTE),
  (Opcode:$88;Mnemonic:'ADC B'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$89;Mnemonic:'ADC C'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$8A;Mnemonic:'ADC D'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$8B;Mnemonic:'ADC E'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$8C;Mnemonic:'ADC H'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$8D;Mnemonic:'ADC L'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$8E;Mnemonic:'ADC M'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$8F;Mnemonic:'ADC A'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$CE;Mnemonic:'ACI'    ;Size:2;Operand:OPERAND_BYTE),
  (Opcode:$90;Mnemonic:'SUB B'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$91;Mnemonic:'SUB C'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$92;Mnemonic:'SUB D'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$93;Mnemonic:'SUB E'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$94;Mnemonic:'SUB H'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$95;Mnemonic:'SUB L'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$96;Mnemonic:'SUB M'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$97;Mnemonic:'SUB A'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$D6;Mnemonic:'SUI'    ;Size:2;Operand:OPERAND_BYTE),
  (Opcode:$98;Mnemonic:'SBB B'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$99;Mnemonic:'SBB C'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$9A;Mnemonic:'SBB D'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$9B;Mnemonic:'SBB E'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$9C;Mnemonic:'SBB H'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$9D;Mnemonic:'SBB L'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$9E;Mnemonic:'SBB M'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$9F;Mnemonic:'SBB A'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$DE;Mnemonic:'SBI'    ;Size:2;Operand:OPERAND_BYTE),
  (Opcode:$04;Mnemonic:'INR B'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$14;Mnemonic:'INR D'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$24;Mnemonic:'INR H'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$34;Mnemonic:'INR M'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$0C;Mnemonic:'INR C'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$1C;Mnemonic:'INR E'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$2C;Mnemonic:'INR L'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$3C;Mnemonic:'INR A'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$05;Mnemonic:'DCR B'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$15;Mnemonic:'DCR D'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$25;Mnemonic:'DCR H'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$35;Mnemonic:'DCR M'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$0D;Mnemonic:'DCR C'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$1D;Mnemonic:'DCR E'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$2D;Mnemonic:'DCR L'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$3D;Mnemonic:'DCR A'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$03;Mnemonic:'INX B'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$13;Mnemonic:'INX D'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$23;Mnemonic:'INX H'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$33;Mnemonic:'INX SP' ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$0B;Mnemonic:'DCX B'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$1B;Mnemonic:'DCX D'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$2B;Mnemonic:'DCX H'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$3B;Mnemonic:'DCX SP' ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$09;Mnemonic:'DAD B'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$19;Mnemonic:'DAD D'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$29;Mnemonic:'DAD H'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$39;Mnemonic:'DAD SP' ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$27;Mnemonic:'DAA'    ;Size:1;Operand:OPERAND_NONE),

  { Groupe logique }
  (Opcode:$A0;Mnemonic:'ANA B'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$A1;Mnemonic:'ANA C'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$A2;Mnemonic:'ANA D'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$A3;Mnemonic:'ANA E'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$A4;Mnemonic:'ANA H'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$A5;Mnemonic:'ANA L'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$A6;Mnemonic:'ANA M'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$A7;Mnemonic:'ANA A'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$E6;Mnemonic:'ANI'    ;Size:2;Operand:OPERAND_BYTE),
  (Opcode:$B0;Mnemonic:'ORA B'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$B1;Mnemonic:'ORA C'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$B2;Mnemonic:'ORA D'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$B3;Mnemonic:'ORA E'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$B4;Mnemonic:'ORA H'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$B5;Mnemonic:'ORA L'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$B6;Mnemonic:'ORA M'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$B7;Mnemonic:'ORA A'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$F6;Mnemonic:'ORI'    ;Size:2;Operand:OPERAND_BYTE),
  (Opcode:$A8;Mnemonic:'XRA B'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$A9;Mnemonic:'XRA C'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$AA;Mnemonic:'XRA D'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$AB;Mnemonic:'XRA E'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$AC;Mnemonic:'XRA H'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$AD;Mnemonic:'XRA L'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$AE;Mnemonic:'XRA M'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$AF;Mnemonic:'XRA A'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$EE;Mnemonic:'XRI'    ;Size:2;Operand:OPERAND_BYTE),
  { Instructions de comparaison }
  (Opcode:$B8;Mnemonic:'CMP B'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$B9;Mnemonic:'CMP C'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$BA;Mnemonic:'CMP D'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$BB;Mnemonic:'CMP E'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$BC;Mnemonic:'CMP H'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$BD;Mnemonic:'CMP L'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$BE;Mnemonic:'CMP M'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$BF;Mnemonic:'CMP A'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$FE;Mnemonic:'CPI'    ;Size:2;Operand:OPERAND_BYTE),
  { Instructions de rotation }
  (Opcode:$07;Mnemonic:'RLC'    ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$0F;Mnemonic:'RRC'    ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$17;Mnemonic:'RAL'    ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$1F;Mnemonic:'RAR'    ;Size:1;Operand:OPERAND_NONE),
  { Instructions de drapeau de compl‚ment et de retenue }
  (Opcode:$2F;Mnemonic:'CMA'    ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$3F;Mnemonic:'CMC'    ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$37;Mnemonic:'STC'    ;Size:1;Operand:OPERAND_NONE),

  { Groupe de branchement }
  { Instruction de branchement inconditionnel }
  (Opcode:$C3;Mnemonic:'JMP'    ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$CD;Mnemonic:'CALL'   ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$C9;Mnemonic:'RET'    ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$E9;Mnemonic:'PCHL'   ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$C7;Mnemonic:'RST 0'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$D7;Mnemonic:'RST 2'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$E7;Mnemonic:'RST 4'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$F7;Mnemonic:'RST 6'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$CF;Mnemonic:'RST 1'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$DF;Mnemonic:'RST 3'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$EF;Mnemonic:'RST 5'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$FF;Mnemonic:'RST 7'  ;Size:1;Operand:OPERAND_NONE),
  { Instructions de branchement conditionnel }
  (Opcode:$DA;Mnemonic:'JC'     ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$D2;Mnemonic:'JNC'    ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$CA;Mnemonic:'JZ'     ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$C2;Mnemonic:'JNZ'    ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$F2;Mnemonic:'JP'     ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$FA;Mnemonic:'JM'     ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$EA;Mnemonic:'JPE'    ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$E2;Mnemonic:'JPO'    ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$DC;Mnemonic:'CC'     ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$D4;Mnemonic:'CNC'    ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$CC;Mnemonic:'CZ'     ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$C4;Mnemonic:'CNZ'    ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$F4;Mnemonic:'CP'     ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$FC;Mnemonic:'CM'     ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$EC;Mnemonic:'CPE'    ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$E4;Mnemonic:'CPO'    ;Size:3;Operand:OPERAND_WORD),
  (Opcode:$D8;Mnemonic:'RC'     ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$D0;Mnemonic:'RNC'    ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$C8;Mnemonic:'RZ'     ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$C0;Mnemonic:'RNZ'    ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$F0;Mnemonic:'RP'     ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$F8;Mnemonic:'RM'     ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$E8;Mnemonic:'RPE'    ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$E0;Mnemonic:'RPO'    ;Size:1;Operand:OPERAND_NONE),

  { Pile, entr‚e/sortie, et instructions de contr“le machine }
  (Opcode:$C5;Mnemonic:'PUSH B' ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$D5;Mnemonic:'PUSH D' ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$E5;Mnemonic:'PUSH H' ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$F5;Mnemonic:'PUSH PSW';Size:1;Operand:OPERAND_NONE),
  (Opcode:$C1;Mnemonic:'POP B'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$D1;Mnemonic:'POP D'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$E1;Mnemonic:'POP H'  ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$F1;Mnemonic:'POP PSW';Size:1;Operand:OPERAND_NONE),
  (Opcode:$E3;Mnemonic:'XTHL'   ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$F9;Mnemonic:'SPHL'   ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$DB;Mnemonic:'IN'     ;Size:2;Operand:OPERAND_BYTE),
  (Opcode:$D3;Mnemonic:'OUT'    ;Size:2;Operand:OPERAND_BYTE),
  (Opcode:$FB;Mnemonic:'EI'     ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$F3;Mnemonic:'DI'     ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$76;Mnemonic:'HLT'    ;Size:1;Operand:OPERAND_NONE),
  (Opcode:$00;Mnemonic:'NOP'    ;Size:1;Operand:OPERAND_NONE),

  (Opcode:$00;Mnemonic:'TERM'   ;Size:0;Operand:OPERAND_NONE)
 );

Type
 StatePerLocation=Record
  DisLine:PChar;
  linebuf:Array[0..31] of Char;
  NeedLabel:Integer;
  GotLabel:Integer;
  Size:Integer;
  ForceData:Integer;
 End;

Const
 INSTINFO_SIZE=312; { Taille de la structure INSTINFO }
 MAX_MEMORY=$8000 div SizeOf(StatePerLocation); { Taille de la m‚moire }
 PC:LongInt=-1;

Var
 FileName:String;
 SourceBin:File;
 State:Array[0..(MAX_MEMORY {div SizeOf(StatePerLocation)})] of StatePerLocation;
 i,c:LongInt;
 inst:^InstInfoRec;
 DisLine:PChar;
 Value:Array[0..1] of Integer;
 Err:Word;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

Function GetNext(MustGetSomething:Integer):Integer;
Var
 Ch:Char;
 ByteReaded:Word;
Begin
 If PC=$FFFF Then Begin
  If MustGetSomething<>0 Then Begin
   Writeln('Trop d''entr‚e');
   Halt(1);
  End
   Else
  Begin
   GetNext:=Integer(EOF(SourceBin));
   Exit;
  End;
 End;
 BlockRead(SourceBin,Ch,1,ByteReaded);
 GetNext:=Ord(Ch);
 If(EOF(SourceBin))and(MustGetSomething<>0)Then Begin
  Writeln('EOF non attendu');
  Halt(1);
 End;
 Inc(PC);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('DIS8080 : Cette commande permet de d‚sassembleur un code binaire de');
  WriteLn('          microprocesseur 8080 en langage de programmation assembleur 8080.');
  WriteLn;
  WriteLn('Syntaxe : DIS8080 [option] [nomdufichier]');
  WriteLn;
  WriteLn(' nomduficher           Nom du fichier binaire');
  WriteLn(' -d ADDR COUNT         Indique l''adresse et la quantit‚ respectivement');
 End
  Else
 If ParamCount>0 Then Begin
  FillChar(State,SizeOf(State),0);
  FileName:='';
   { Analyses des paramŠtres de ligne de commande }
  I:=1;
  While I<=ParamCount do Begin
   If ParamStr(I)='-d'Then Begin
    If ParamCount<=(I+2)Then Begin
     WriteLn('-d ADDR COUNT: attendue(s)');
     Halt(1);
    End;
    Inc(I);
    Val(ParamStr(I),Value[0],Err);
    Inc(I);
    Val(ParamStr(I),Value[1],Err);
    If(MAX_MEMORY<=(Value[0]+Value[1]-1))Then Begin
     WriteLn('-d ADDR COUNT: Intervalle invalide');
     Halt(1);
    End;
    If(Value[0]+Value[1])<MAX_MEMORY Then State[Value[0]+Value[1]].NeedLabel:=1;
    While Value[1]>0 do Begin
     State[Value[0]+Value[1]-1].ForceData:=1;
     Dec(Value[1]);
    End;
    Inc(I); { Prochaine option }
   End
    Else
   If FileName=''Then Begin
    FileName:=ParamStr(I);
    Inc(I);
   End
    Else
   Begin
    Writeln('ParamŠtre invalide : ', ParamStr(I));
    Halt(1);
   End;
  End;
  If FileName=''Then Begin
   WriteLn('Nom de fichier attendue !');
   Halt(2);
  End;
  {$I-}Assign(SourceBin,FileName);
  Reset(SourceBin,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Erreur de lecture du fichier ',FileName);
   Halt(3);
  End;
   { Lecture et d‚codage des instructions }
  While Not EOF(SourceBin)do Begin
   C:=GetNext(0);
   Disline:=State[PC].LineBuf;
   State[PC].Disline:=DisLine;
   State[PC].Size:=1;
   If State[PC].ForceData<>0 Then Begin
    Inst:=NIL;
   End
    Else
   Begin
    Inst:=@INSTINFO[0];
    While Inst^.Size<>0 do Begin
     If Inst^.OpCode=C Then Begin
      State[PC].Size:=Inst^.Size;
      Break;
     End;
     Inc(inst);
    End;
   End;
   If(Inst<>NIL)and(Inst^.Size<>0)Then Begin
    Disline:=StrCat(Disline,Inst^.Mnemonic);
    Disline:=StrCat(Disline,' ');
    Case Inst^.Operand of
     OPERAND_BYTE:Begin
      Value[0]:=GetNext(1);
      Disline:=StrPCopy(Disline+StrLen(disline),'$'+ByteHex2Str(Value[0]));
     End;
     OPERAND_WORD:Begin
      Value[0]:=GetNext(1);
      Value[1]:=GetNext(1);
      State[Value[1] shl 8 or Value[0]].needlabel:=1;
      Disline:=StrPCopy(Disline+StrLen(disline),ByteHex2Str(value[1])+ByteHex2Str(value[0]));
     End;
    End;
   End
    Else
   Begin
    Disline:=StrPCopy(disline, 'db'+#9+ByteHex2Str(c));
    If(c in[32..126])Then Begin
     StrCat(Disline,#9+#9+'; ''');
     Disline:=StrPCopy(Disline,Char(C));
     StrCat(disline,'''');
    End;
   End;
  End;
  Close(SourceBin);
   { Affichage de toutes les instructions }
  I:=0;
  While I<PC do Begin
   If State[I].DisLine<>NIL Then Begin
    If State[i].NeedLabel<>0 Then Begin
     State[i].GotLabel:=1;
     WriteLn(HexWord2Str(I));
    End;
    WriteLn(#9,StrPas(State[I].DisLine));
    Inc(I,State[I].Size);
   End
    Else
   Inc(I);
  End;
  WriteLn;
   { Affichage des d‚finitions de symboles pour les emplacements sans ‚tiquette }
  I:=0;
  While i<MAX_MEMORY do Begin
   If(State[i].NeedLabel<>0)and(State[i].GotLabel=0)Then WriteLn(HexWord2Str(i),' = $',HexWord2Str(i));
   Inc(i);
  End;
  WriteLn;
  WriteLn('end');
  WriteLn;
 End;
END.
