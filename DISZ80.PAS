{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program DISZ80;

{$R-}

Uses Strings;

Type
 OperandType=(OPERAND_NONE,OPERAND_BYTE,OPERAND_WORD);
 InstInfoRec=Record
  Opcode:Integer;
  Mnemonic:PChar;
  Size:Integer;
  Operand:OperandType;
 End;

{ Cette table d‚crit toutes les instructions Z80 }
Const InstInfo:Array[0..255]of InstinfoRec=(
  (* Groupe de transfŠre de donn‚es *)
  (Opcode:$00;Mnemonic:'NOP';Size:1;Operand:OPERAND_NONE),
  (Opcode:$01;Mnemonic:'LD BC,';Size:3;Operand:OPERAND_WORD),
  (Opcode:$02;Mnemonic:'LD (BC),A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$03;Mnemonic:'INC BC';Size:1;Operand:OPERAND_NONE),
  (Opcode:$04;Mnemonic:'INC B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$05;Mnemonic:'DEC B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$06;Mnemonic:'LD B,';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$07;Mnemonic:'RLCA';Size:1;Operand:OPERAND_NONE),
  (Opcode:$08;Mnemonic:'DB $08';Size:1;Operand:OPERAND_NONE),
  (Opcode:$09;Mnemonic:'ADD HL,BC';Size:1;Operand:OPERAND_NONE),
  (Opcode:$0A;Mnemonic:'LD A,(BC)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$0B;Mnemonic:'DEC BC';Size:1;Operand:OPERAND_NONE),
  (Opcode:$0C;Mnemonic:'INC C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$0D;Mnemonic:'DEC C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$0E;Mnemonic:'LD C,';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$0F;Mnemonic:'RRCA';Size:1;Operand:OPERAND_NONE),
  (Opcode:$10;Mnemonic:'DJNZ ';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$11;Mnemonic:'LD DE,';Size:3;Operand:OPERAND_WORD),
  (Opcode:$12;Mnemonic:'LD (DE),A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$13;Mnemonic:'INC DE';Size:1;Operand:OPERAND_NONE),
  (Opcode:$14;Mnemonic:'INC D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$15;Mnemonic:'DEC D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$16;Mnemonic:'LD D,';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$17;Mnemonic:'RLA';Size:1;Operand:OPERAND_NONE),
  (Opcode:$18;Mnemonic:'JR ';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$19;Mnemonic:'ADD HL,DE';Size:1;Operand:OPERAND_NONE),
  (Opcode:$1A;Mnemonic:'LD A,(DE)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$1B;Mnemonic:'DEC DE';Size:1;Operand:OPERAND_NONE),
  (Opcode:$1C;Mnemonic:'INC E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$1D;Mnemonic:'DEC E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$1E;Mnemonic:'LD E,';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$1F;Mnemonic:'RRA';Size:1;Operand:OPERAND_NONE),
  (Opcode:$20;Mnemonic:'JR NZ,';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$21;Mnemonic:'LD HL,';Size:3;Operand:OPERAND_WORD),
  (Opcode:$22;Mnemonic:'LD (**),HL';Size:3;Operand:OPERAND_WORD),
  (Opcode:$23;Mnemonic:'INC HL';Size:1;Operand:OPERAND_NONE),
  (Opcode:$24;Mnemonic:'INC H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$25;Mnemonic:'DEC H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$26;Mnemonic:'LD H,';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$27;Mnemonic:'DB $27';Size:1;Operand:OPERAND_NONE),
  (Opcode:$28;Mnemonic:'JR Z,';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$29;Mnemonic:'ADD HL,HL';Size:1;Operand:OPERAND_NONE),
  (Opcode:$2A;Mnemonic:'LD HL,(**)';Size:3;Operand:OPERAND_WORD),
  (Opcode:$2B;Mnemonic:'DEC HL';Size:1;Operand:OPERAND_NONE),
  (Opcode:$2C;Mnemonic:'INC L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$2D;Mnemonic:'DEC L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$2E;Mnemonic:'LD L,';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$2F;Mnemonic:'CPL';Size:1;Operand:OPERAND_NONE),
  (Opcode:$30;Mnemonic:'JR NC,';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$31;Mnemonic:'LD SP,';Size:3;Operand:OPERAND_WORD),
  (Opcode:$32;Mnemonic:'LD (**),a';Size:3;Operand:OPERAND_WORD),
  (Opcode:$33;Mnemonic:'INC SP';Size:1;Operand:OPERAND_NONE),
  (Opcode:$34;Mnemonic:'INC (HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$35;Mnemonic:'DEC (HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$36;Mnemonic:'LD (HL),';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$37;Mnemonic:'SCF';Size:1;Operand:OPERAND_NONE),
  (Opcode:$38;Mnemonic:'JR C,';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$39;Mnemonic:'ADD HL,SP';Size:1;Operand:OPERAND_NONE),
  (Opcode:$3A;Mnemonic:'LD A,(**)';Size:3;Operand:OPERAND_WORD),
  (Opcode:$3B;Mnemonic:'DEC SP';Size:1;Operand:OPERAND_NONE),
  (Opcode:$3C;Mnemonic:'INC A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$3D;Mnemonic:'DEC A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$3E;Mnemonic:'LD A,';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$3F;Mnemonic:'CCF';Size:1;Operand:OPERAND_NONE),
  (Opcode:$40;Mnemonic:'LD B,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$41;Mnemonic:'LD B,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$42;Mnemonic:'LD B,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$43;Mnemonic:'LD B,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$44;Mnemonic:'LD B,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$45;Mnemonic:'LD B,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$46;Mnemonic:'LD B,(HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$47;Mnemonic:'LD B,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$48;Mnemonic:'LD C,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$49;Mnemonic:'LD C,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$4A;Mnemonic:'LD C,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$4B;Mnemonic:'LD C,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$4C;Mnemonic:'LD C,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$4D;Mnemonic:'LD C,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$4E;Mnemonic:'LD C,(HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$4F;Mnemonic:'LD C,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$50;Mnemonic:'LD D,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$51;Mnemonic:'LD D,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$52;Mnemonic:'LD D,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$53;Mnemonic:'LD D,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$54;Mnemonic:'LD D,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$55;Mnemonic:'LD D,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$56;Mnemonic:'LD D,(HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$57;Mnemonic:'LD D,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$58;Mnemonic:'LD E,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$59;Mnemonic:'LD E,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$5A;Mnemonic:'LD E,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$5B;Mnemonic:'LD E,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$5C;Mnemonic:'LD E,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$5D;Mnemonic:'LD E,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$5E;Mnemonic:'LD E,(HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$5F;Mnemonic:'LD E,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$60;Mnemonic:'LD H,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$61;Mnemonic:'LD H,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$62;Mnemonic:'LD H,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$63;Mnemonic:'LD H,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$64;Mnemonic:'LD H,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$65;Mnemonic:'LD H,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$66;Mnemonic:'LD H,(HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$67;Mnemonic:'LD H,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$68;Mnemonic:'LD L,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$69;Mnemonic:'LD L,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$6A;Mnemonic:'LD L,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$6B;Mnemonic:'LD L,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$6C;Mnemonic:'LD L,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$6D;Mnemonic:'LD L,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$6E;Mnemonic:'LD L,(HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$6F;Mnemonic:'LD L,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$70;Mnemonic:'LD (HL),B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$71;Mnemonic:'LD (HL),C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$72;Mnemonic:'LD (HL),D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$73;Mnemonic:'LD (HL),E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$74;Mnemonic:'LD (HL),H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$75;Mnemonic:'LD (HL),L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$76;Mnemonic:'HALT';Size:1;Operand:OPERAND_NONE),
  (Opcode:$77;Mnemonic:'LD (HL),A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$78;Mnemonic:'LD A,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$79;Mnemonic:'LD A,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$7A;Mnemonic:'LD A,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$7B;Mnemonic:'LD A,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$7C;Mnemonic:'LD A,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$7D;Mnemonic:'LD A,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$7E;Mnemonic:'LD A,(HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$7F;Mnemonic:'LD A,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$80;Mnemonic:'ADD A,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$81;Mnemonic:'ADD A,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$82;Mnemonic:'ADD A,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$83;Mnemonic:'ADD A,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$84;Mnemonic:'ADD A,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$85;Mnemonic:'ADD A,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$86;Mnemonic:'ADD A,(HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$87;Mnemonic:'ADD A,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$88;Mnemonic:'ADC A,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$89;Mnemonic:'ADC A,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$8A;Mnemonic:'ADC A,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$8B;Mnemonic:'ADC A,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$8C;Mnemonic:'ADC A,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$8D;Mnemonic:'ADC A,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$8E;Mnemonic:'ADC A,(HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$8F;Mnemonic:'ADC A,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$90;Mnemonic:'SUB B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$91;Mnemonic:'SUB C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$92;Mnemonic:'SUB D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$93;Mnemonic:'SUB E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$94;Mnemonic:'SUB H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$95;Mnemonic:'SUB L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$96;Mnemonic:'SUB (HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$97;Mnemonic:'SUB A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$98;Mnemonic:'SBC A,B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$99;Mnemonic:'SBC A,C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$9A;Mnemonic:'SBC A,D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$9B;Mnemonic:'SBC A,E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$9C;Mnemonic:'SBC A,H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$9D;Mnemonic:'SBC A,L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$9E;Mnemonic:'SBC A,(HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$9F;Mnemonic:'SBC A,A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$A0;Mnemonic:'AND B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$A1;Mnemonic:'AND C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$A2;Mnemonic:'AND D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$A3;Mnemonic:'AND E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$A4;Mnemonic:'AND H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$A5;Mnemonic:'AND L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$A6;Mnemonic:'AND (HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$A7;Mnemonic:'AND A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$A8;Mnemonic:'XOR B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$A9;Mnemonic:'XOR C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$AA;Mnemonic:'XOR D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$AB;Mnemonic:'XOR E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$AC;Mnemonic:'XOR H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$AD;Mnemonic:'XOR L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$AE;Mnemonic:'XOR (HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$AF;Mnemonic:'XOR A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$B0;Mnemonic:'OR B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$B1;Mnemonic:'OR C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$B2;Mnemonic:'OR D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$B3;Mnemonic:'OR E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$B4;Mnemonic:'OR H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$B5;Mnemonic:'OR L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$B6;Mnemonic:'OR (HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$B7;Mnemonic:'OR A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$B8;Mnemonic:'CP B';Size:1;Operand:OPERAND_NONE),
  (Opcode:$B9;Mnemonic:'CP C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$BA;Mnemonic:'CP D';Size:1;Operand:OPERAND_NONE),
  (Opcode:$BB;Mnemonic:'CP E';Size:1;Operand:OPERAND_NONE),
  (Opcode:$BC;Mnemonic:'CP H';Size:1;Operand:OPERAND_NONE),
  (Opcode:$BD;Mnemonic:'CP L';Size:1;Operand:OPERAND_NONE),
  (Opcode:$BE;Mnemonic:'CP (HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$BF;Mnemonic:'CP A';Size:1;Operand:OPERAND_NONE),
  (Opcode:$C0;Mnemonic:'RET NZ';Size:1;Operand:OPERAND_NONE),
  (Opcode:$C1;Mnemonic:'POP BC';Size:1;Operand:OPERAND_NONE),
  (Opcode:$C2;Mnemonic:'JP NZ,';Size:3;Operand:OPERAND_WORD),
  (Opcode:$C3;Mnemonic:'JP ';Size:3;Operand:OPERAND_WORD),
  (Opcode:$C4;Mnemonic:'CALL NZ,';Size:3;Operand:OPERAND_WORD),
  (Opcode:$C5;Mnemonic:'PUSH BC';Size:1;Operand:OPERAND_NONE),
  (Opcode:$C6;Mnemonic:'ADD A,';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$C7;Mnemonic:'RST 0x00';Size:1;Operand:OPERAND_NONE),
  (Opcode:$C8;Mnemonic:'RET Z';Size:1;Operand:OPERAND_NONE),
  (Opcode:$C9;Mnemonic:'RET';Size:1;Operand:OPERAND_NONE),
  (Opcode:$CA;Mnemonic:'JP Z,';Size:3;Operand:OPERAND_WORD),
  (Opcode:$CB;Mnemonic:'DB $CB';Size:1;Operand:OPERAND_NONE),
  (Opcode:$CC;Mnemonic:'CALL Z,';Size:3;Operand:OPERAND_WORD),
  (Opcode:$CD;Mnemonic:'CALL ';Size:3;Operand:OPERAND_WORD),
  (Opcode:$CE;Mnemonic:'ADC A,';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$CF;Mnemonic:'rst 0x08';Size:1;Operand:OPERAND_NONE),
  (Opcode:$D0;Mnemonic:'RET NC';Size:1;Operand:OPERAND_NONE),
  (Opcode:$D1;Mnemonic:'POP DE';Size:1;Operand:OPERAND_NONE),
  (Opcode:$D2;Mnemonic:'JP NC,';Size:3;Operand:OPERAND_WORD),
  (Opcode:$D3;Mnemonic:'HALT';Size:2;Operand:OPERAND_NONE),
  (Opcode:$D4;Mnemonic:'CALL NC,';Size:3;Operand:OPERAND_WORD),
  (Opcode:$D5;Mnemonic:'PUSH DE';Size:1;Operand:OPERAND_NONE),
  (Opcode:$D6;Mnemonic:'SUB ';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$D7;Mnemonic:'DB $D7';Size:1;Operand:OPERAND_NONE),
  (Opcode:$D8;Mnemonic:'RET C';Size:1;Operand:OPERAND_NONE),
  (Opcode:$D9;Mnemonic:'DB $D9';Size:1;Operand:OPERAND_NONE),
  (Opcode:$DA;Mnemonic:'JP C,';Size:3;Operand:OPERAND_WORD),
  (Opcode:$DB;Mnemonic:'DB $DB';Size:1;Operand:OPERAND_NONE),
  (Opcode:$DC;Mnemonic:'CALL C,';Size:3;Operand:OPERAND_WORD),
  (Opcode:$DD;Mnemonic:'DB $DD';Size:1;Operand:OPERAND_NONE),
  (Opcode:$DE;Mnemonic:'SBC A,';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$DF;Mnemonic:'DB $DF';Size:1;Operand:OPERAND_NONE),
  (Opcode:$E0;Mnemonic:'DB $E0';Size:1;Operand:OPERAND_NONE),
  (Opcode:$E1;Mnemonic:'POP HL';Size:1;Operand:OPERAND_NONE),
  (Opcode:$E2;Mnemonic:'DB $E2';Size:1;Operand:OPERAND_NONE),
  (Opcode:$E3;Mnemonic:'EX (SP),HL';Size:1;Operand:OPERAND_NONE),
  (Opcode:$E4;Mnemonic:'DB $E4';Size:1;Operand:OPERAND_NONE),
  (Opcode:$E5;Mnemonic:'PUSH HL';Size:1;Operand:OPERAND_NONE),
  (Opcode:$E6;Mnemonic:'AND ';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$E7;Mnemonic:'DB $E7';Size:1;Operand:OPERAND_NONE),
  (Opcode:$E8;Mnemonic:'DB $E8';Size:1;Operand:OPERAND_NONE),
  (Opcode:$E9;Mnemonic:'JP (HL)';Size:1;Operand:OPERAND_NONE),
  (Opcode:$EA;Mnemonic:'DB $EA';Size:1;Operand:OPERAND_NONE),
  (Opcode:$EB;Mnemonic:'EX DE,HL';Size:1;Operand:OPERAND_NONE),
  (Opcode:$EC;Mnemonic:'DB $EC';Size:1;Operand:OPERAND_NONE),
  (Opcode:$ED;Mnemonic:'DB $ED';Size:1;Operand:OPERAND_NONE),
  (Opcode:$EE;Mnemonic:'XOR ';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$EF;Mnemonic:'DB $EF';Size:1;Operand:OPERAND_NONE),
  (Opcode:$F0;Mnemonic:'RET P';Size:1;Operand:OPERAND_NONE),
  (Opcode:$F1;Mnemonic:'POP AF';Size:1;Operand:OPERAND_NONE),
  (Opcode:$F2;Mnemonic:'JP P,';Size:3;Operand:OPERAND_WORD),
  (Opcode:$F3;Mnemonic:'DB $F3';Size:1;Operand:OPERAND_NONE),
  (Opcode:$F4;Mnemonic:'DB $F4';Size:1;Operand:OPERAND_NONE),
  (Opcode:$F5;Mnemonic:'PUSH AF';Size:1;Operand:OPERAND_NONE),
  (Opcode:$F6;Mnemonic:'OR ';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$F7;Mnemonic:'DB $F7';Size:1;Operand:OPERAND_NONE),
  (Opcode:$F8;Mnemonic:'RET M';Size:1;Operand:OPERAND_NONE),
  (Opcode:$F9;Mnemonic:'LD SP,HL';Size:1;Operand:OPERAND_NONE),
  (Opcode:$FA;Mnemonic:'JP M,';Size:3;Operand:OPERAND_WORD),
  (Opcode:$FB;Mnemonic:'DB $FB';Size:1;Operand:OPERAND_NONE),
  (Opcode:$FC;Mnemonic:'DB $FC';Size:1;Operand:OPERAND_NONE),
  (Opcode:$FD;Mnemonic:'DB $FD';Size:1;Operand:OPERAND_NONE),
  (Opcode:$FE;Mnemonic:'CP ';Size:2;Operand:OPERAND_BYTE),
  (Opcode:$FF;Mnemonic:'DB $FF';Size:1;Operand:OPERAND_NONE)
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
  WriteLn('DISZ80 : Cette commande permet de d‚sassembleur un code binaire de');
  WriteLn('          microprocesseur Z80 en langage de programmation assembleur Z80.');
  WriteLn;
  WriteLn('Syntaxe : DISZ80 [option] [nomdufichier]');
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
      If(Value[1] shl 8 or Value[0]<High(State))Then State[Value[1] shl 8 or Value[0]].needlabel:=1
       Else
      WriteLn('Op‚rateur Word en dehors de l''intervalle');
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
