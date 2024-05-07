{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program DIS6809;

{$A-,R-}

Const
 maxOpLen=5; { Longueur maximal en octets de long opcode }

Type
 OpcdStr=String[maxOpLen];
 InstType=(iImplied,iDirect,iImmediate,iLImmediate,iRelative,iLRelative,
           iIndexed,iExtended,iTfrExg,iPshPul);
 InstrRec=Record
  AsmName:OpcdStr; {mn‚monique }
  c:Boolean;       {Drapeau cr}
  r:Boolean;       {Drapeau de r‚f‚rence}
  t:InstType;      {Type}
 End;

Const
 Pow2:Array[0..15] of Word=(1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768);

 opTable:Array[1..4,0..255] of InstrRec=(
  (
   {00} (AsmName:'NEG'  ; c:False; r:False; t:iDirect ),
   {01} (AsmName:''     ; c:False; r:False; t:iImplied), {NEG}
   {02} (AsmName:''     ; c:False; r:False; t:iImplied), {COM}
   {03} (AsmName:'COM'  ; c:False; r:False; t:iDirect ),
   {04} (AsmName:'LSR'  ; c:False; r:False; t:iDirect ),
   {05} (AsmName:''     ; c:False; r:False; t:iImplied), {LSR}
   {06} (AsmName:'ROR'  ; c:False; r:False; t:iDirect ),
   {07} (AsmName:'ASR'  ; c:False; r:False; t:iDirect ),
   {08} (AsmName:'ASL'  ; c:False; r:False; t:iDirect ),
   {09} (AsmName:'ROL'  ; c:False; r:False; t:iDirect ),
   {0A} (AsmName:'DEC'  ; c:False; r:False; t:iDirect ),
   {0B} (AsmName:''     ; c:False; r:False; t:iImplied), {DEC}
   {0C} (AsmName:'INC'  ; c:False; r:False; t:iDirect ),
   {0D} (AsmName:'TST'  ; c:False; r:False; t:iDirect ),
   {0E} (AsmName:'JMP'  ; c:True;  r:False; t:iDirect ),
   {0F} (AsmName:'CLR'  ; c:False; r:False; t:iDirect ),

   {10} (AsmName:''     ; c:False; r:False; t:iImplied), {PAGE2}
   {11} (AsmName:''     ; c:False; r:False; t:iImplied), {PAGE3}
   {12} (AsmName:'NOP'  ; c:False; r:False; t:iImplied),
   {13} (AsmName:'SYNC' ; c:False; r:False; t:iImplied),
   {14} (AsmName:''     ; c:False; r:False; t:iImplied), {???}
   {15} (AsmName:''     ; c:False; r:False; t:iImplied), {???}
   {16} (AsmName:'LBRA' ; c:True ; r:True ; t:iLRelative),
   {17} (AsmName:'LBSR' ; c:False; r:True ; t:iLRelative),
   {18} (AsmName:''     ; c:False; r:False; t:iImplied), {???}
   {19} (AsmName:'DAA'  ; c:False; r:False; t:iImplied),
   {1A} (AsmName:'ORCC' ; c:False; r:False; t:iImmediate),
   {1B} (AsmName:''     ; c:False; r:False; t:iImplied), {???}
   {1C} (AsmName:'ANDCC'; c:False; r:False; t:iImmediate),
   {1D} (AsmName:'SEX'  ; c:False; r:False; t:iImplied),
   {1E} (AsmName:'EXG'  ; c:False; r:False; t:iTfrExg),
   {1F} (AsmName:'TFR'  ; c:False; r:False; t:iTfrExg),

   {20} (AsmName:'BRA'  ; c:True ; r:True ; t:iRelative),
   {21} (AsmName:'BRN'  ; c:False; r:False; t:iRelative),
   {22} (AsmName:'BHI'  ; c:False; r:True ; t:iRelative),
   {23} (AsmName:'BLS'  ; c:False; r:True ; t:iRelative),
   {24} (AsmName:'BCC'  ; c:False; r:True ; t:iRelative),
   {25} (AsmName:'BCS'  ; c:False; r:True ; t:iRelative),
   {26} (AsmName:'BNE'  ; c:False; r:True ; t:iRelative),
   {27} (AsmName:'BEQ'  ; c:False; r:True ; t:iRelative),
   {28} (AsmName:'BVC'  ; c:False; r:True ; t:iRelative),
   {29} (AsmName:'BVS'  ; c:False; r:True ; t:iRelative),
   {2A} (AsmName:'BPL'  ; c:False; r:True ; t:iRelative),
   {2B} (AsmName:'BMI'  ; c:False; r:True ; t:iRelative),
   {2C} (AsmName:'BGE'  ; c:False; r:True ; t:iRelative),
   {2D} (AsmName:'BLT'  ; c:False; r:True ; t:iRelative),
   {2E} (AsmName:'BGT'  ; c:False; r:True ; t:iRelative),
   {2F} (AsmName:'BLE'  ; c:False; r:True ; t:iRelative),

   {30} (AsmName:'LEAX' ; c:False; r:False; t:iIndexed),
   {31} (AsmName:'LEAY' ; c:False; r:False; t:iIndexed),
   {32} (AsmName:'LEAS' ; c:False; r:False; t:iIndexed),
   {33} (AsmName:'LEAU' ; c:False; r:False; t:iIndexed),
   {34} (AsmName:'PSHS' ; c:False; r:False; t:iPshPul ),
   {35} (AsmName:'PULS' ; c:False; r:False; t:iPshPul ),
   {36} (AsmName:'PSHU' ; c:False; r:False; t:iPshPul ),
   {37} (AsmName:'PULU' ; c:False; r:False; t:iPshPul ),
   {38} (AsmName:''     ; c:False; r:False; t:iImplied), {RTS}
   {39} (AsmName:'RTS'  ; c:True ; r:False; t:iImplied),
   {3A} (AsmName:'ABX'  ; c:False; r:False; t:iImplied),
   {3B} (AsmName:'RTI'  ; c:False; r:False; t:iImplied),
   {3C} (AsmName:'CWAI' ; c:False; r:False; t:iImmediate),
   {3D} (AsmName:'MUL'  ; c:False; r:False; t:iImplied),
   {3E} (AsmName:''     ; c:False; r:False; t:iImplied), {SWR}
   {3F} (AsmName:'SWI'  ; c:False; r:False; t:iImplied),

   {40} (AsmName:'NEGA' ; c:False; r:False; t:iImplied),
   {41} (AsmName:''     ; c:False; r:False; t:iImplied), {NEGA}
   {42} (AsmName:''     ; c:False; r:False; t:iImplied), {COMA}
   {43} (AsmName:'COMA' ; c:False; r:False; t:iImplied),
   {44} (AsmName:'LSRA' ; c:False; r:False; t:iImplied),
   {45} (AsmName:''     ; c:False; r:False; t:iImplied), {LSRA}
   {46} (AsmName:'RORA' ; c:False; r:False; t:iImplied),
   {47} (AsmName:'ASRA' ; c:False; r:False; t:iImplied),
   {48} (AsmName:'ASLA' ; c:False; r:False; t:iImplied),
   {49} (AsmName:'ROLA' ; c:False; r:False; t:iImplied),
   {4A} (AsmName:'DECA' ; c:False; r:False; t:iImplied),
   {4B} (AsmName:''     ; c:False; r:False; t:iImplied), {DECA}
   {4C} (AsmName:'INCA' ; c:False; r:False; t:iImplied),
   {4D} (AsmName:'TSTA' ; c:False; r:False; t:iImplied),
   {4E} (AsmName:''     ; c:False; r:False; t:iImplied), {JMPA}
   {4F} (AsmName:'CLRA' ; c:False; r:False; t:iImplied),

   {50} (AsmName:'NEGB' ; c:False; r:False; t:iImplied),
   {51} (AsmName:''     ; c:False; r:False; t:iImplied), {NEGB}
   {52} (AsmName:''     ; c:False; r:False; t:iImplied), {COMB}
   {53} (AsmName:'COMB' ; c:False; r:False; t:iImplied),
   {54} (AsmName:'LSRB' ; c:False; r:False; t:iImplied),
   {55} (AsmName:''     ; c:False; r:False; t:iImplied), {LSRB}
   {56} (AsmName:'RORB' ; c:False; r:False; t:iImplied),
   {57} (AsmName:'ASRB' ; c:False; r:False; t:iImplied),
   {58} (AsmName:'ASLB' ; c:False; r:False; t:iImplied),
   {59} (AsmName:'ROLB' ; c:False; r:False; t:iImplied),
   {5A} (AsmName:'DECB' ; c:False; r:False; t:iImplied),
   {5B} (AsmName:''     ; c:False; r:False; t:iImplied), {DECB}
   {5C} (AsmName:'INCB' ; c:False; r:False; t:iImplied),
   {5D} (AsmName:'TSTB' ; c:False; r:False; t:iImplied),
   {5E} (AsmName:''     ; c:False; r:False; t:iImplied), {JMPB}
   {5F} (AsmName:'CLRB' ; c:False; r:False; t:iImplied),

   {60} (AsmName:'NEG'  ; c:False; r:False; t:iIndexed),
   {61} (AsmName:''     ; c:False; r:False; t:iImplied), {NEG}
   {62} (AsmName:''     ; c:False; r:False; t:iImplied), {COM}
   {63} (AsmName:'COM'  ; c:False; r:False; t:iIndexed),
   {64} (AsmName:'LSR'  ; c:False; r:False; t:iIndexed),
   {65} (AsmName:''     ; c:False; r:False; t:iImplied), {LSR}
   {66} (AsmName:'ROR'  ; c:False; r:False; t:iIndexed),
   {67} (AsmName:'ASR'  ; c:False; r:False; t:iIndexed),
   {68} (AsmName:'ASL'  ; c:False; r:False; t:iIndexed),
   {69} (AsmName:'ROL'  ; c:False; r:False; t:iIndexed),
   {6A} (AsmName:'DEC'  ; c:False; r:False; t:iIndexed),
   {6B} (AsmName:''     ; c:False; r:False; t:iImplied), {DEC}
   {6C} (AsmName:'INC'  ; c:False; r:False; t:iIndexed),
   {6D} (AsmName:'TST'  ; c:False; r:False; t:iIndexed),
   {6E} (AsmName:'JMP'  ; c:True ; r:False; t:iIndexed),
   {6F} (AsmName:'CLR'  ; c:False; r:False; t:iIndexed),

   {70} (AsmName:'NEG'  ; c:False; r:False; t:iExtended),
   {71} (AsmName:''     ; c:False; r:False; t:iImplied ), {NEG}
   {72} (AsmName:''     ; c:False; r:False; t:iImplied ), {COM}
   {73} (AsmName:'COM'  ; c:False; r:False; t:iExtended),
   {74} (AsmName:'LSR'  ; c:False; r:False; t:iExtended),
   {75} (AsmName:''     ; c:False; r:False; t:iImplied ), {LSR}
   {76} (AsmName:'ROR'  ; c:False; r:False; t:iExtended),
   {77} (AsmName:'ASR'  ; c:False; r:False; t:iExtended),
   {78} (AsmName:'ASL'  ; c:False; r:False; t:iExtended),
   {79} (AsmName:'ROL'  ; c:False; r:False; t:iExtended),
   {7A} (AsmName:'DEC'  ; c:False; r:False; t:iExtended),
   {7B} (AsmName:''     ; c:False; r:False; t:iImplied ), {DEC}
   {7C} (AsmName:'INC'  ; c:False; r:False; t:iExtended),
   {7D} (AsmName:'TST'  ; c:False; r:False; t:iExtended),
   {7E} (AsmName:'JMP'  ; c:True ; r:True ; t:iExtended),
   {7F} (AsmName:'CLR'  ; c:False; r:False; t:iExtended),

   {80} (AsmName:'SUBA' ; c:False; r:False; t:iImmediate),
   {81} (AsmName:'CMPA' ; c:False; r:False; t:iImmediate),
   {82} (AsmName:'SBCA' ; c:False; r:False; t:iImmediate),
   {83} (AsmName:'SUBD' ; c:False; r:False; t:iLImmediate),
   {84} (AsmName:'ANDA' ; c:False; r:False; t:iImmediate),
   {85} (AsmName:'BITA' ; c:False; r:False; t:iImmediate),
   {86} (AsmName:'LDA'  ; c:False; r:False; t:iImmediate),
   {87} (AsmName:''     ; c:False; r:False; t:iImplied  ), {STA}
   {88} (AsmName:'EORA' ; c:False; r:False; t:iImmediate),
   {89} (AsmName:'ADCA' ; c:False; r:False; t:iImmediate),
   {8A} (AsmName:'ORA'  ; c:False; r:False; t:iImmediate),
   {8B} (AsmName:'ADDA' ; c:False; r:False; t:iImmediate),
   {8C} (AsmName:'CMPX' ; c:False; r:False; t:iLImmediate),
   {8D} (AsmName:'BSR'  ; c:False; r:True ; t:iRelative ),
   {8E} (AsmName:'LDX'  ; c:False; r:False; t:iLImmediate),
   {8F} (AsmName:''     ; c:False; r:False; t:iImplied  ), {STX}

   {90} (AsmName:'SUBA' ; c:False; r:False; t:iDirect),
   {91} (AsmName:'CMPA' ; c:False; r:False; t:iDirect),
   {92} (AsmName:'SBCA' ; c:False; r:False; t:iDirect),
   {93} (AsmName:'SUBD' ; c:False; r:False; t:iDirect),
   {94} (AsmName:'ANDA' ; c:False; r:False; t:iDirect),
   {95} (AsmName:'BITA' ; c:False; r:False; t:iDirect),
   {96} (AsmName:'LDA'  ; c:False; r:False; t:iDirect),
   {97} (AsmName:'STA'  ; c:False; r:False; t:iDirect),
   {98} (AsmName:'EORA' ; c:False; r:False; t:iDirect),
   {99} (AsmName:'ADCA' ; c:False; r:False; t:iDirect),
   {9A} (AsmName:'ORA'  ; c:False; r:False; t:iDirect),
   {9B} (AsmName:'ADDA' ; c:False; r:False; t:iDirect),
   {9C} (AsmName:'CMPX' ; c:False; r:False; t:iDirect),
   {9D} (AsmName:'JSR'  ; c:False; r:False; t:iDirect),
   {9E} (AsmName:'LDX'  ; c:False; r:False; t:iDirect),
   {9F} (AsmName:'STX'  ; c:False; r:False; t:iDirect),

   {A0} (AsmName:'SUBA' ; c:False; r:False; t:iIndexed),
   {A1} (AsmName:'CMPA' ; c:False; r:False; t:iIndexed),
   {A2} (AsmName:'SBCA' ; c:False; r:False; t:iIndexed),
   {A3} (AsmName:'SUBD' ; c:False; r:False; t:iIndexed),
   {A4} (AsmName:'ANDA' ; c:False; r:False; t:iIndexed),
   {A5} (AsmName:'BITA' ; c:False; r:False; t:iIndexed),
   {A6} (AsmName:'LDA'  ; c:False; r:False; t:iIndexed),
   {A7} (AsmName:'STA'  ; c:False; r:False; t:iIndexed),
   {A8} (AsmName:'EORA' ; c:False; r:False; t:iIndexed),
   {A9} (AsmName:'ADCA' ; c:False; r:False; t:iIndexed),
   {AA} (AsmName:'ORA'  ; c:False; r:False; t:iIndexed),
   {AB} (AsmName:'ADDA' ; c:False; r:False; t:iIndexed),
   {AC} (AsmName:'CMPX' ; c:False; r:False; t:iIndexed),
   {AD} (AsmName:'JSR'  ; c:False; r:False; t:iIndexed),
   {AE} (AsmName:'LDX'  ; c:False; r:False; t:iIndexed),
   {AF} (AsmName:'STX'  ; c:False; r:False; t:iIndexed),

   {B0} (AsmName:'SUBA' ; c:False; r:False; t:iExtended),
   {B1} (AsmName:'CMPA' ; c:False; r:False; t:iExtended),
   {B2} (AsmName:'SBCA' ; c:False; r:False; t:iExtended),
   {B3} (AsmName:'SUBD' ; c:False; r:False; t:iExtended),
   {B4} (AsmName:'ANDA' ; c:False; r:False; t:iExtended),
   {B5} (AsmName:'BITA' ; c:False; r:False; t:iExtended),
   {B6} (AsmName:'LDA'  ; c:False; r:False; t:iExtended),
   {B7} (AsmName:'STA'  ; c:False; r:False; t:iExtended),
   {B8} (AsmName:'EORA' ; c:False; r:False; t:iExtended),
   {B9} (AsmName:'ADCA' ; c:False; r:False; t:iExtended),
   {BA} (AsmName:'ORA'  ; c:False; r:False; t:iExtended),
   {BB} (AsmName:'ADDA' ; c:False; r:False; t:iExtended),
   {BC} (AsmName:'CMPX' ; c:False; r:False; t:iExtended),
   {BD} (AsmName:'JSR'  ; c:False; r:True ; t:iExtended),
   {BE} (AsmName:'LDX'  ; c:False; r:False; t:iExtended),
   {BF} (AsmName:'STX'  ; c:False; r:False; t:iExtended),

   {C0} (AsmName:'SUBB' ; c:False; r:False; t:iImmediate),
   {C1} (AsmName:'CMPB' ; c:False; r:False; t:iImmediate),
   {C2} (AsmName:'SBCB' ; c:False; r:False; t:iImmediate),
   {C3} (AsmName:'ADDD' ; c:False; r:False; t:iLImmediate),
   {C4} (AsmName:'ANDB' ; c:False; r:False; t:iImmediate),
   {C5} (AsmName:'BITB' ; c:False; r:False; t:iImmediate),
   {C6} (AsmName:'LDB'  ; c:False; r:False; t:iImmediate),
   {C7} (AsmName:''     ; c:False; r:False; t:iImplied  ), {STB}
   {C8} (AsmName:'EORB' ; c:False; r:False; t:iImmediate),
   {C9} (AsmName:'ADCB' ; c:False; r:False; t:iImmediate),
   {CA} (AsmName:'ORB'  ; c:False; r:False; t:iImmediate),
   {CB} (AsmName:'ADDB' ; c:False; r:False; t:iImmediate),
   {CC} (AsmName:'LDD'  ; c:False; r:False; t:iLImmediate),
   {CD} (AsmName:''     ; c:False; r:False; t:iImplied  ), {STD}
   {CE} (AsmName:'LDU'  ; c:False; r:False; t:iLImmediate),
   {CF} (AsmName:''     ; c:False; r:False; t:iImplied  ), {STU}

   {D0} (AsmName:'SUBB' ; c:False; r:False; t:iDirect),
   {D1} (AsmName:'CMPB' ; c:False; r:False; t:iDirect),
   {D2} (AsmName:'SBCB' ; c:False; r:False; t:iDirect),
   {D3} (AsmName:'ADDD' ; c:False; r:False; t:iDirect),
   {D4} (AsmName:'ANDB' ; c:False; r:False; t:iDirect),
   {D5} (AsmName:'BITB' ; c:False; r:False; t:iDirect),
   {D6} (AsmName:'LDB'  ; c:False; r:False; t:iDirect),
   {D7} (AsmName:'STB'  ; c:False; r:False; t:iDirect),
   {D8} (AsmName:'EORB' ; c:False; r:False; t:iDirect),
   {D9} (AsmName:'ADCB' ; c:False; r:False; t:iDirect),
   {DA} (AsmName:'ORB'  ; c:False; r:False; t:iDirect),
   {DB} (AsmName:'ADDB' ; c:False; r:False; t:iDirect),
   {DC} (AsmName:'LDD'  ; c:False; r:False; t:iDirect),
   {DD} (AsmName:'STD'  ; c:False; r:False; t:iDirect),
   {DE} (AsmName:'LDU'  ; c:False; r:False; t:iDirect),
   {DF} (AsmName:'STU'  ; c:False; r:False; t:iDirect),

   {E0} (AsmName:'SUBB' ; c:False; r:False; t:iIndexed),
   {E1} (AsmName:'CMPB' ; c:False; r:False; t:iIndexed),
   {E2} (AsmName:'SBCB' ; c:False; r:False; t:iIndexed),
   {E3} (AsmName:'ADDD' ; c:False; r:False; t:iIndexed),
   {E4} (AsmName:'ANDB' ; c:False; r:False; t:iIndexed),
   {E5} (AsmName:'BITB' ; c:False; r:False; t:iIndexed),
   {E6} (AsmName:'LDB'  ; c:False; r:False; t:iIndexed),
   {E7} (AsmName:'STB'  ; c:False; r:False; t:iIndexed),
   {E8} (AsmName:'EORB' ; c:False; r:False; t:iIndexed),
   {E9} (AsmName:'ADCB' ; c:False; r:False; t:iIndexed),
   {EA} (AsmName:'ORB'  ; c:False; r:False; t:iIndexed),
   {EB} (AsmName:'ADDB' ; c:False; r:False; t:iIndexed),
   {EC} (AsmName:'LDD'  ; c:False; r:False; t:iIndexed),
   {ED} (AsmName:'STD'  ; c:False; r:False; t:iIndexed),
   {EE} (AsmName:'LDU'  ; c:False; r:False; t:iIndexed),
   {EF} (AsmName:'STU'  ; c:False; r:False; t:iIndexed),

   {F0} (AsmName:'SUBB' ; c:False; r:False; t:iExtended),
   {F1} (AsmName:'CMPB' ; c:False; r:False; t:iExtended),
   {F2} (AsmName:'SBCB' ; c:False; r:False; t:iExtended),
   {F3} (AsmName:'ADDD' ; c:False; r:False; t:iExtended),
   {F4} (AsmName:'ANDB' ; c:False; r:False; t:iExtended),
   {F5} (AsmName:'BITB' ; c:False; r:False; t:iExtended),
   {F6} (AsmName:'LDB'  ; c:False; r:False; t:iExtended),
   {F7} (AsmName:'STB'  ; c:False; r:False; t:iExtended),
   {F8} (AsmName:'EORB' ; c:False; r:False; t:iExtended),
   {F9} (AsmName:'ADCB' ; c:False; r:False; t:iExtended),
   {FA} (AsmName:'ORB'  ; c:False; r:False; t:iExtended),
   {FB} (AsmName:'ADDB' ; c:False; r:False; t:iExtended),
   {FC} (AsmName:'LDD'  ; c:False; r:False; t:iExtended),
   {FD} (AsmName:'STD'  ; c:False; r:False; t:iExtended),
   {FE} (AsmName:'LDU'  ; c:False; r:False; t:iExtended),
   {FF} (AsmName:'STU'  ; c:False; r:False; t:iExtended)
  ),
  (
   {1000} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1001} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1002} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1003} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1004} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1005} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1006} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1007} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1008} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1009} (AsmName:''     ; c:False; r:False; t:iImplied),
   {100A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {100B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {100C} (AsmName:''     ; c:False; r:False; t:iImplied),
   {100D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {100E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {100F} (AsmName:''     ; c:False; r:False; t:iImplied),

   {1010} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1011} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1012} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1013} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1014} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1015} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1016} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1017} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1018} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1019} (AsmName:''     ; c:False; r:False; t:iImplied),
   {101A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {101B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {101C} (AsmName:''     ; c:False; r:False; t:iImplied),
   {101D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {101E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {101F} (AsmName:''     ; c:False; r:False; t:iImplied),

   {1020} (AsmName:'LBRA' ; c:True ; r:True ; t:iLRelative),
   {1021} (AsmName:'LBRN' ; c:False; r:False; t:iLRelative),
   {1022} (AsmName:'LBHI' ; c:False; r:True ; t:iLRelative),
   {1023} (AsmName:'LBLS' ; c:False; r:True ; t:iLRelative),
   {1024} (AsmName:'LBCC' ; c:False; r:True ; t:iLRelative),
   {1025} (AsmName:'LBCS' ; c:False; r:True ; t:iLRelative),
   {1026} (AsmName:'LBNE' ; c:False; r:True ; t:iLRelative),
   {1027} (AsmName:'LBEQ' ; c:False; r:True ; t:iLRelative),
   {1028} (AsmName:'LBVC' ; c:False; r:True ; t:iLRelative),
   {1029} (AsmName:'LBVS' ; c:False; r:True ; t:iLRelative),
   {102A} (AsmName:'LBPL' ; c:False; r:True ; t:iLRelative),
   {102B} (AsmName:'LBMI' ; c:False; r:True ; t:iLRelative),
   {102C} (AsmName:'LBGE' ; c:False; r:True ; t:iLRelative),
   {102D} (AsmName:'LBLT' ; c:False; r:True ; t:iLRelative),
   {102E} (AsmName:'LBGT' ; c:False; r:True ; t:iLRelative),
   {102F} (AsmName:'LBLE' ; c:False; r:True ; t:iLRelative),

   {1030} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1031} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1032} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1033} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1034} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1035} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1036} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1037} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1038} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1039} (AsmName:''     ; c:False; r:False; t:iImplied),
   {103A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {103B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {103C} (AsmName:''     ; c:False; r:False; t:iImplied),
   {103D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {103E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {103F} (AsmName:'SWI2' ; c:False; r:False; t:iImplied),

   {1040} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1041} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1042} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1043} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1044} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1045} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1046} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1047} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1048} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1049} (AsmName:''     ; c:False; r:False; t:iImplied),
   {104A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {104B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {104C} (AsmName:''     ; c:False; r:False; t:iImplied),
   {104D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {104E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {104F} (AsmName:''     ; c:False; r:False; t:iImplied),

   {1050} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1051} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1052} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1053} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1054} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1055} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1056} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1057} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1058} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1059} (AsmName:''     ; c:False; r:False; t:iImplied),
   {105A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {105B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {105C} (AsmName:''     ; c:False; r:False; t:iImplied),
   {105D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {105E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {105F} (AsmName:''     ; c:False; r:False; t:iImplied),

   {1060} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1061} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1062} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1063} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1064} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1065} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1066} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1067} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1068} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1069} (AsmName:''     ; c:False; r:False; t:iImplied),
   {106A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {106B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {106C} (AsmName:''     ; c:False; r:False; t:iImplied),
   {106D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {106E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {106F} (AsmName:''     ; c:False; r:False; t:iImplied),

   {1070} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1071} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1072} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1073} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1074} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1075} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1076} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1077} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1078} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1079} (AsmName:''     ; c:False; r:False; t:iImplied),
   {107A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {107B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {107C} (AsmName:''     ; c:False; r:False; t:iImplied),
   {107D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {107E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {107F} (AsmName:''     ; c:False; r:False; t:iImplied),

   {1080} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1081} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1082} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1083} (AsmName:'CMPD' ; c:False; r:False; t:iLImmediate),
   {1084} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1085} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1086} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1087} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1088} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1089} (AsmName:''     ; c:False; r:False; t:iImplied),
   {108A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {108B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {108C} (AsmName:'CMPY' ; c:False; r:False; t:iLImmediate),
   {108D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {108E} (AsmName:'LDY'  ; c:False; r:False; t:iLImmediate),
   {108F} (AsmName:''     ; c:False; r:False; t:iImplied), {STY}

   {1090} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1091} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1092} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1093} (AsmName:'CMPD' ; c:False; r:False; t:iDirect ),
   {1094} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1095} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1096} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1097} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1098} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1099} (AsmName:''     ; c:False; r:False; t:iImplied),
   {109A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {109B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {109C} (AsmName:'CMPY' ; c:False; r:False; t:iDirect ),
   {109D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {109E} (AsmName:'LDY'  ; c:False; r:False; t:iDirect ),
   {109F} (AsmName:'STY'  ; c:False; r:False; t:iDirect ),

   {10A0} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10A1} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10A2} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10A3} (AsmName:'CMPD' ; c:False; r:False; t:iIndexed),
   {10A4} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10A5} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10A6} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10A7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10A8} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10A9} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10AA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10AB} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10AC} (AsmName:'CMPY' ; c:False; r:False; t:iIndexed),
   {10AD} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10AE} (AsmName:'LDY'  ; c:False; r:False; t:iIndexed),
   {10AF} (AsmName:'STY'  ; c:False; r:False; t:iIndexed),

   {10B0} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10B1} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10B2} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10B3} (AsmName:'CMPD' ; c:False; r:False; t:iExtended),
   {10B4} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10B5} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10B6} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10B7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10B8} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10B9} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10BA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10BB} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10BC} (AsmName:'CMPY' ; c:False; r:False; t:iExtended),
   {10BD} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10BE} (AsmName:'LDY'  ; c:False; r:False; t:iExtended),
   {10BF} (AsmName:'STY'  ; c:False; r:False; t:iExtended),

   {10C0} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10C1} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10C2} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10C3} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10C4} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10C5} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10C6} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10C7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10C8} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10C9} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10CA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10CB} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10CC} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10CD} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10CE} (AsmName:'LDS'  ; c:False; r:False; t:iLImmediate),
   {10CF} (AsmName:'STS'  ; c:False; r:False; t:iLImmediate),

   {10D0} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10D1} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10D2} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10D3} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10D4} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10D5} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10D6} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10D7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10D8} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10D9} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10DA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10DB} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10DC} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10DD} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10DE} (AsmName:'LDS'  ; c:False; r:False; t:iDirect ),
   {10DF} (AsmName:'STS'  ; c:False; r:False; t:iDirect ),

   {10E0} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10E1} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10E2} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10E3} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10E4} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10E5} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10E6} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10E7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10E8} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10E9} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10EA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10EB} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10EC} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10ED} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10EE} (AsmName:'LDS'  ; c:False; r:False; t:iIndexed),
   {10EF} (AsmName:'STS'  ; c:False; r:False; t:iIndexed),

   {10F0} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10F1} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10F2} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10F3} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10F4} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10F5} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10F6} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10F7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10F8} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10F9} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10FA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10FB} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10FC} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10FD} (AsmName:''     ; c:False; r:False; t:iImplied),
   {10FE} (AsmName:'LDS'  ; c:False; r:False; t:iExtended),
   {10FF} (AsmName:'STS'  ; c:False; r:False; t:iExtended)
  ),
  (
   {1100} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1101} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1102} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1103} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1104} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1105} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1106} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1107} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1108} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1109} (AsmName:''     ; c:False; r:False; t:iImplied),
   {110A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {110B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {110C} (AsmName:''     ; c:False; r:False; t:iImplied),
   {110D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {110E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {110F} (AsmName:''     ; c:False; r:False; t:iImplied),

   {1110} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1111} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1112} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1113} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1114} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1115} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1116} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1117} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1118} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1119} (AsmName:''     ; c:False; r:False; t:iImplied),
   {111A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {111B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {111C} (AsmName:''     ; c:False; r:False; t:iImplied),
   {111D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {111E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {111F} (AsmName:''     ; c:False; r:False; t:iImplied),

   {1120} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1121} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1122} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1123} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1124} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1125} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1126} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1127} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1128} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1129} (AsmName:''     ; c:False; r:False; t:iImplied),
   {112A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {112B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {112C} (AsmName:''     ; c:False; r:False; t:iImplied),
   {112D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {112E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {112F} (AsmName:''     ; c:False; r:False; t:iImplied),

   {1130} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1131} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1132} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1133} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1134} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1135} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1136} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1137} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1138} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1139} (AsmName:''     ; c:False; r:False; t:iImplied),
   {113A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {113B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {113C} (AsmName:''     ; c:False; r:False; t:iImplied),
   {113D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {113E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {113F} (AsmName:'SWI3' ; c:False; r:False; t:iImplied),

   {1140} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1141} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1142} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1143} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1144} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1145} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1146} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1147} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1148} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1149} (AsmName:''     ; c:False; r:False; t:iImplied),
   {114A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {114B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {114C} (AsmName:''     ; c:False; r:False; t:iImplied),
   {114D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {114E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {114F} (AsmName:''     ; c:False; r:False; t:iImplied),

   {1150} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1151} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1152} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1153} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1154} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1155} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1156} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1157} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1158} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1159} (AsmName:''     ; c:False; r:False; t:iImplied),
   {115A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {115B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {115C} (AsmName:''     ; c:False; r:False; t:iImplied),
   {115D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {115E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {115F} (AsmName:''     ; c:False; r:False; t:iImplied),

   {1160} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1161} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1162} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1163} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1164} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1165} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1166} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1167} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1168} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1169} (AsmName:''     ; c:False; r:False; t:iImplied),
   {116A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {116B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {116C} (AsmName:''     ; c:False; r:False; t:iImplied),
   {116D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {116E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {116F} (AsmName:''     ; c:False; r:False; t:iImplied),

   {1170} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1171} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1172} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1173} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1174} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1175} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1176} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1177} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1178} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1179} (AsmName:''     ; c:False; r:False; t:iImplied),
   {117A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {117B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {117C} (AsmName:''     ; c:False; r:False; t:iImplied),
   {117D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {117E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {117F} (AsmName:''     ; c:False; r:False; t:iImplied),

   {1180} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1181} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1182} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1183} (AsmName:'CMPU' ; c:False; r:False; t:iLImmediate),
   {1184} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1185} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1186} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1187} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1188} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1189} (AsmName:''     ; c:False; r:False; t:iImplied),
   {118A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {118B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {118C} (AsmName:'CMPS' ; c:False; r:False; t:iLImmediate),
   {118D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {118E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {118F} (AsmName:''     ; c:False; r:False; t:iImplied),

   {1190} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1191} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1192} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1193} (AsmName:'CMPU' ; c:False; r:False; t:iDirect ),
   {1194} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1195} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1196} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1197} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1198} (AsmName:''     ; c:False; r:False; t:iImplied),
   {1199} (AsmName:''     ; c:False; r:False; t:iImplied),
   {119A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {119B} (AsmName:''     ; c:False; r:False; t:iImplied),
   {119C} (AsmName:'CMPS' ; c:False; r:False; t:iDirect ),
   {119D} (AsmName:''     ; c:False; r:False; t:iImplied),
   {119E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {119F} (AsmName:''     ; c:False; r:False; t:iImplied),

   {11A0} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11A1} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11A2} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11A3} (AsmName:'CMPU' ; c:False; r:False; t:iIndexed),
   {11A4} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11A5} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11A6} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11A7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11A8} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11A9} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11AA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11AB} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11AC} (AsmName:'CMPS' ; c:False; r:False; t:iIndexed),
   {11AD} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11AE} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11AF} (AsmName:''     ; c:False; r:False; t:iImplied),

   {11B0} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11B1} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11B2} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11B3} (AsmName:'CMPU' ; c:False; r:False; t:iExtended),
   {11B4} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11B5} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11B6} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11B7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11B8} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11B9} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11BA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11BB} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11BC} (AsmName:'CMPS' ; c:False; r:False; t:iExtended),
   {11BD} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11BE} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11BF} (AsmName:''     ; c:False; r:False; t:iImplied),

   {11C0} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11C1} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11C2} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11C3} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11C4} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11C5} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11C6} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11C7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11C8} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11C9} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11CA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11CB} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11CC} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11CD} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11CE} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11CF} (AsmName:''     ; c:False; r:False; t:iImplied),

   {11D0} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11D1} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11D2} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11D3} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11D4} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11D5} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11D6} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11D7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11D8} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11D9} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11DA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11DB} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11DC} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11DD} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11DE} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11DF} (AsmName:''     ; c:False; r:False; t:iImplied),

   {11E0} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11E1} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11E2} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11E3} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11E4} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11E5} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11E6} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11E7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11E8} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11E9} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11EA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11EB} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11EC} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11ED} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11EE} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11EF} (AsmName:''     ; c:False; r:False; t:iImplied),

   {11F0} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11F1} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11F2} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11F3} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11F4} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11F5} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11F6} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11F7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11F8} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11F9} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11FA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11FB} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11FC} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11FD} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11FE} (AsmName:''     ; c:False; r:False; t:iImplied),
   {11FF} (AsmName:''     ; c:False; r:False; t:iImplied)
  ),
  (
   {ix00} (AsmName:'0,X'  ; c:False; r:False; t:iImplied),
   {ix01} (AsmName:'1,X'  ; c:False; r:False; t:iImplied),
   {ix02} (AsmName:'2,X'  ; c:False; r:False; t:iImplied),
   {ix03} (AsmName:'3,X'  ; c:False; r:False; t:iImplied),
   {ix04} (AsmName:'4,X'  ; c:False; r:False; t:iImplied),
   {ix05} (AsmName:'5,X'  ; c:False; r:False; t:iImplied),
   {ix06} (AsmName:'6,X'  ; c:False; r:False; t:iImplied),
   {ix07} (AsmName:'7,X'  ; c:False; r:False; t:iImplied),
   {ix08} (AsmName:'8,X'  ; c:False; r:False; t:iImplied),
   {ix09} (AsmName:'9,X'  ; c:False; r:False; t:iImplied),
   {ix0A} (AsmName:'10,X' ; c:False; r:False; t:iImplied),
   {ix0B} (AsmName:'11,X' ; c:False; r:False; t:iImplied),
   {ix0C} (AsmName:'12,X' ; c:False; r:False; t:iImplied),
   {ix0D} (AsmName:'13,X' ; c:False; r:False; t:iImplied),
   {ix0E} (AsmName:'14,X' ; c:False; r:False; t:iImplied),
   {ix0F} (AsmName:'15,X' ; c:False; r:False; t:iImplied),

   {ix10} (AsmName:'-16,X'; c:False; r:False; t:iImplied),
   {ix11} (AsmName:'-15,X'; c:False; r:False; t:iImplied),
   {ix12} (AsmName:'-14,X'; c:False; r:False; t:iImplied),
   {ix13} (AsmName:'-13,X'; c:False; r:False; t:iImplied),
   {ix14} (AsmName:'-12,X'; c:False; r:False; t:iImplied),
   {ix15} (AsmName:'-11,X'; c:False; r:False; t:iImplied),
   {ix16} (AsmName:'-10,X'; c:False; r:False; t:iImplied),
   {ix17} (AsmName:'-9,X' ; c:False; r:False; t:iImplied),
   {ix18} (AsmName:'-8,X' ; c:False; r:False; t:iImplied),
   {ix19} (AsmName:'-7,X' ; c:False; r:False; t:iImplied),
   {ix1A} (AsmName:'-6,X' ; c:False; r:False; t:iImplied),
   {ix1B} (AsmName:'-5,X' ; c:False; r:False; t:iImplied),
   {ix1C} (AsmName:'-4,X' ; c:False; r:False; t:iImplied),
   {ix1D} (AsmName:'-3,X' ; c:False; r:False; t:iImplied),
   {ix1E} (AsmName:'-2,X' ; c:False; r:False; t:iImplied),
   {ix1F} (AsmName:'-1,X' ; c:False; r:False; t:iImplied),

   {ix20} (AsmName:'0,Y'  ; c:False; r:False; t:iImplied),
   {ix21} (AsmName:'1,Y'  ; c:False; r:False; t:iImplied),
   {ix22} (AsmName:'2,Y'  ; c:False; r:False; t:iImplied),
   {ix23} (AsmName:'3,Y'  ; c:False; r:False; t:iImplied),
   {ix24} (AsmName:'4,Y'  ; c:False; r:False; t:iImplied),
   {ix25} (AsmName:'5,Y'  ; c:False; r:False; t:iImplied),
   {ix26} (AsmName:'6,Y'  ; c:False; r:False; t:iImplied),
   {ix27} (AsmName:'7,Y'  ; c:False; r:False; t:iImplied),
   {ix28} (AsmName:'8,Y'  ; c:False; r:False; t:iImplied),
   {ix29} (AsmName:'9,Y'  ; c:False; r:False; t:iImplied),
   {ix2A} (AsmName:'10,Y' ; c:False; r:False; t:iImplied),
   {ix2B} (AsmName:'11,Y' ; c:False; r:False; t:iImplied),
   {ix2C} (AsmName:'12,Y' ; c:False; r:False; t:iImplied),
   {ix2D} (AsmName:'13,Y' ; c:False; r:False; t:iImplied),
   {ix2E} (AsmName:'14,Y' ; c:False; r:False; t:iImplied),
   {ix2F} (AsmName:'15,Y' ; c:False; r:False; t:iImplied),

   {ix30} (AsmName:'-16,Y'; c:False; r:False; t:iImplied),
   {ix31} (AsmName:'-15,Y'; c:False; r:False; t:iImplied),
   {ix32} (AsmName:'-14,Y'; c:False; r:False; t:iImplied),
   {ix33} (AsmName:'-13,Y'; c:False; r:False; t:iImplied),
   {ix34} (AsmName:'-12,Y'; c:False; r:False; t:iImplied),
   {ix35} (AsmName:'-11,Y'; c:False; r:False; t:iImplied),
   {ix36} (AsmName:'-10,Y'; c:False; r:False; t:iImplied),
   {ix37} (AsmName:'-9,Y' ; c:False; r:False; t:iImplied),
   {ix38} (AsmName:'-8,Y' ; c:False; r:False; t:iImplied),
   {ix39} (AsmName:'-7,Y' ; c:False; r:False; t:iImplied),
   {ix3A} (AsmName:'-6,Y' ; c:False; r:False; t:iImplied),
   {ix3B} (AsmName:'-5,Y' ; c:False; r:False; t:iImplied),
   {ix3C} (AsmName:'-4,Y' ; c:False; r:False; t:iImplied),
   {ix3D} (AsmName:'-3,Y' ; c:False; r:False; t:iImplied),
   {ix3E} (AsmName:'-2,Y' ; c:False; r:False; t:iImplied),
   {ix3F} (AsmName:'-1,Y' ; c:False; r:False; t:iImplied),

   {ix40} (AsmName:'0,U'  ; c:False; r:False; t:iImplied),
   {ix41} (AsmName:'1,U'  ; c:False; r:False; t:iImplied),
   {ix42} (AsmName:'2,U'  ; c:False; r:False; t:iImplied),
   {ix43} (AsmName:'3,U'  ; c:False; r:False; t:iImplied),
   {ix44} (AsmName:'4,U'  ; c:False; r:False; t:iImplied),
   {ix45} (AsmName:'5,U'  ; c:False; r:False; t:iImplied),
   {ix46} (AsmName:'6,U'  ; c:False; r:False; t:iImplied),
   {ix47} (AsmName:'7,U'  ; c:False; r:False; t:iImplied),
   {ix48} (AsmName:'8,U'  ; c:False; r:False; t:iImplied),
   {ix49} (AsmName:'9,U'  ; c:False; r:False; t:iImplied),
   {ix4A} (AsmName:'10,U' ; c:False; r:False; t:iImplied),
   {ix4B} (AsmName:'11,U' ; c:False; r:False; t:iImplied),
   {ix4C} (AsmName:'12,U' ; c:False; r:False; t:iImplied),
   {ix4D} (AsmName:'13,U' ; c:False; r:False; t:iImplied),
   {ix4E} (AsmName:'14,U' ; c:False; r:False; t:iImplied),
   {ix4F} (AsmName:'15,U' ; c:False; r:False; t:iImplied),

   {ix50} (AsmName:'-16,U'; c:False; r:False; t:iImplied),
   {ix51} (AsmName:'-15,U'; c:False; r:False; t:iImplied),
   {ix52} (AsmName:'-14,U'; c:False; r:False; t:iImplied),
   {ix53} (AsmName:'-13,U'; c:False; r:False; t:iImplied),
   {ix54} (AsmName:'-12,U'; c:False; r:False; t:iImplied),
   {ix55} (AsmName:'-11,U'; c:False; r:False; t:iImplied),
   {ix56} (AsmName:'-10,U'; c:False; r:False; t:iImplied),
   {ix57} (AsmName:'-9,U' ; c:False; r:False; t:iImplied),
   {ix58} (AsmName:'-8,U' ; c:False; r:False; t:iImplied),
   {ix59} (AsmName:'-7,U' ; c:False; r:False; t:iImplied),
   {ix5A} (AsmName:'-6,U' ; c:False; r:False; t:iImplied),
   {ix5B} (AsmName:'-5,U' ; c:False; r:False; t:iImplied),
   {ix5C} (AsmName:'-4,U' ; c:False; r:False; t:iImplied),
   {ix5D} (AsmName:'-3,U' ; c:False; r:False; t:iImplied),
   {ix5E} (AsmName:'-2,U' ; c:False; r:False; t:iImplied),
   {ix5F} (AsmName:'-1,U' ; c:False; r:False; t:iImplied),

   {ix60} (AsmName:'0,S'  ; c:False; r:False; t:iImplied),
   {ix61} (AsmName:'1,S'  ; c:False; r:False; t:iImplied),
   {ix62} (AsmName:'2,S'  ; c:False; r:False; t:iImplied),
   {ix63} (AsmName:'3,S'  ; c:False; r:False; t:iImplied),
   {ix64} (AsmName:'4,S'  ; c:False; r:False; t:iImplied),
   {ix65} (AsmName:'5,S'  ; c:False; r:False; t:iImplied),
   {ix66} (AsmName:'6,S'  ; c:False; r:False; t:iImplied),
   {ix67} (AsmName:'7,S'  ; c:False; r:False; t:iImplied),
   {ix68} (AsmName:'8,S'  ; c:False; r:False; t:iImplied),
   {ix69} (AsmName:'9,S'  ; c:False; r:False; t:iImplied),
   {ix6A} (AsmName:'10,S' ; c:False; r:False; t:iImplied),
   {ix6B} (AsmName:'11,S' ; c:False; r:False; t:iImplied),
   {ix6C} (AsmName:'12,S' ; c:False; r:False; t:iImplied),
   {ix6D} (AsmName:'13,S' ; c:False; r:False; t:iImplied),
   {ix6E} (AsmName:'14,S' ; c:False; r:False; t:iImplied),
   {ix6F} (AsmName:'15,S' ; c:False; r:False; t:iImplied),

   {ix70} (AsmName:'-16,S'; c:False; r:False; t:iImplied),
   {ix71} (AsmName:'-15,S'; c:False; r:False; t:iImplied),
   {ix72} (AsmName:'-14,S'; c:False; r:False; t:iImplied),
   {ix73} (AsmName:'-13,S'; c:False; r:False; t:iImplied),
   {ix74} (AsmName:'-12,S'; c:False; r:False; t:iImplied),
   {ix75} (AsmName:'-11,S'; c:False; r:False; t:iImplied),
   {ix76} (AsmName:'-10,S'; c:False; r:False; t:iImplied),
   {ix77} (AsmName:'-9,S' ; c:False; r:False; t:iImplied),
   {ix78} (AsmName:'-8,S' ; c:False; r:False; t:iImplied),
   {ix79} (AsmName:'-7,S' ; c:False; r:False; t:iImplied),
   {ix7A} (AsmName:'-6,S' ; c:False; r:False; t:iImplied),
   {ix7B} (AsmName:'-5,S' ; c:False; r:False; t:iImplied),
   {ix7C} (AsmName:'-4,S' ; c:False; r:False; t:iImplied),
   {ix7D} (AsmName:'-3,S' ; c:False; r:False; t:iImplied),
   {ix7E} (AsmName:'-2,S' ; c:False; r:False; t:iImplied),
   {ix7F} (AsmName:'-1,S' ; c:False; r:False; t:iImplied),

   {ix80} (AsmName:',X+'  ; c:False; r:False; t:iImplied),
   {ix81} (AsmName:',X++' ; c:False; r:False; t:iImplied),
   {ix82} (AsmName:',-X'  ; c:False; r:False; t:iImplied),
   {ix83} (AsmName:',--X' ; c:False; r:False; t:iImplied),
   {ix84} (AsmName:',X'   ; c:False; r:False; t:iImplied),
   {ix85} (AsmName:'B,X'  ; c:False; r:False; t:iImplied),
   {ix86} (AsmName:'A,X'  ; c:False; r:False; t:iImplied),
   {ix87} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ix88} (AsmName:',X'   ; c:False; r:False; t:iImmediate),{ $xx,X}
   {ix89} (AsmName:',X'   ; c:False; r:False; t:iExtended), { $xxxx,X}
   {ix8A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ix8B} (AsmName:'D,X'  ; c:False; r:False; t:iImplied),
   {ix8C} (AsmName:',PCR' ; c:False; r:False; t:iRelative), { $xx,PC}
   {ix8D} (AsmName:',PCR' ; c:False; r:False; t:iLRelative),{ $xxxx,PC}
   {ix8E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ix8F} (AsmName:''     ; c:False; r:False; t:iExtended), { $xxxx}

   {ix90} (AsmName:''     ; c:False; r:False; t:iImplied),  {[,X+]}
   {ix91} (AsmName:',X++' ; c:False; r:False; t:iImplied),
   {ix92} (AsmName:''     ; c:False; r:False; t:iImplied),  {[,-X]}
   {ix93} (AsmName:',--X' ; c:False; r:False; t:iImplied),
   {ix94} (AsmName:',X'   ; c:False; r:False; t:iImplied),
   {ix95} (AsmName:'B,X'  ; c:False; r:False; t:iImplied),
   {ix96} (AsmName:'A,X'  ; c:False; r:False; t:iImplied),
   {ix97} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ix98} (AsmName:',X'   ; c:False; r:False; t:iImmediate),{[$xx,X]}
   {ix99} (AsmName:',X'   ; c:False; r:False; t:iExtended), {[$xxxx,X]}
   {ix9A} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ix9B} (AsmName:'D,X'  ; c:False; r:False; t:iImplied),
   {ix9C} (AsmName:',PCR' ; c:False; r:False; t:iRelative), {[$xx,PC]}
   {ix9D} (AsmName:',PCR' ; c:False; r:False; t:iLRelative),{[$xxxx,PC]}
   {ix9E} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ix9F} (AsmName:''     ; c:False; r:False; t:iExtended), {[$xxxx]}

   {ixA0} (AsmName:',Y+'  ; c:False; r:False; t:iImplied),
   {ixA1} (AsmName:',Y++' ; c:False; r:False; t:iImplied),
   {ixA2} (AsmName:',-Y'  ; c:False; r:False; t:iImplied),
   {ixA3} (AsmName:',--Y' ; c:False; r:False; t:iImplied),
   {ixA4} (AsmName:',Y'   ; c:False; r:False; t:iImplied),
   {ixA5} (AsmName:'B,Y'  ; c:False; r:False; t:iImplied),
   {ixA6} (AsmName:'A,Y'  ; c:False; r:False; t:iImplied),
   {ixA7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixA8} (AsmName:',Y'   ; c:False; r:False; t:iImmediate),{ $xx,Y}
   {ixA9} (AsmName:',Y'   ; c:False; r:False; t:iExtended), { $xxxx,Y}
   {ixAA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixAB} (AsmName:'D,Y'  ; c:False; r:False; t:iImplied),
   {ixAC} (AsmName:',PCR' ; c:False; r:False; t:iRelative), { $xx,PC}
   {ixAD} (AsmName:',PCR' ; c:False; r:False; t:iLRelative),{ $xxxx,PC}
   {ixAE} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixAF} (AsmName:''     ; c:False; r:False; t:iExtended), { $xxxx}

   {ixB0} (AsmName:''     ; c:False; r:False; t:iImplied),  {[,Y+]}
   {ixB1} (AsmName:',Y++' ; c:False; r:False; t:iImplied),
   {ixB2} (AsmName:''     ; c:False; r:False; t:iImplied),  {[,-Y]}
   {ixB3} (AsmName:',--Y' ; c:False; r:False; t:iImplied),
   {ixB4} (AsmName:',Y'   ; c:False; r:False; t:iImplied),
   {ixB5} (AsmName:'B,Y'  ; c:False; r:False; t:iImplied),
   {ixB6} (AsmName:'A,Y'  ; c:False; r:False; t:iImplied),
   {ixB7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixB8} (AsmName:',Y'   ; c:False; r:False; t:iImmediate),{[$xx,Y]}
   {ixB9} (AsmName:',Y'   ; c:False; r:False; t:iExtended), {[$xxxx,Y]}
   {ixBA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixBB} (AsmName:'D,Y'  ; c:False; r:False; t:iImplied),
   {ixBC} (AsmName:',PCR' ; c:False; r:False; t:iRelative), {[$xx,PC]}
   {ixBD} (AsmName:',PCR' ; c:False; r:False; t:iLRelative),{[$xxxx,PC]}
   {ixBE} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixBF} (AsmName:''     ; c:False; r:False; t:iExtended), {[$xxxx]}

   {ixC0} (AsmName:',U+'  ; c:False; r:False; t:iImplied),
   {ixC1} (AsmName:',U++' ; c:False; r:False; t:iImplied),
   {ixC2} (AsmName:',-U'  ; c:False; r:False; t:iImplied),
   {ixC3} (AsmName:',--U' ; c:False; r:False; t:iImplied),
   {ixC4} (AsmName:',U'   ; c:False; r:False; t:iImplied),
   {ixC5} (AsmName:'B,U'  ; c:False; r:False; t:iImplied),
   {ixC6} (AsmName:'A,U'  ; c:False; r:False; t:iImplied),
   {ixC7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixC8} (AsmName:',U'   ; c:False; r:False; t:iImmediate),{ $xx,U}
   {ixC9} (AsmName:',U'   ; c:False; r:False; t:iExtended), { $xxxx,U}
   {ixCA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixCB} (AsmName:'D,U'  ; c:False; r:False; t:iImplied),
   {ixCC} (AsmName:',PCR' ; c:False; r:False; t:iRelative), { $xx,PC}
   {ixCD} (AsmName:',PCR' ; c:False; r:False; t:iLRelative),{ $xxxx,PC}
   {ixCE} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixCF} (AsmName:''     ; c:False; r:False; t:iExtended), { $xxxx}

   {ixD0} (AsmName:''     ; c:False; r:False; t:iImplied),  {[,U+]}
   {ixD1} (AsmName:',U++' ; c:False; r:False; t:iImplied),
   {ixD2} (AsmName:''     ; c:False; r:False; t:iImplied),  {[,-U]}
   {ixD3} (AsmName:',--U' ; c:False; r:False; t:iImplied),
   {ixD4} (AsmName:',U'   ; c:False; r:False; t:iImplied),
   {ixD5} (AsmName:'B,U'  ; c:False; r:False; t:iImplied),
   {ixD6} (AsmName:'A,U'  ; c:False; r:False; t:iImplied),
   {ixD7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixD8} (AsmName:',U'   ; c:False; r:False; t:iImmediate),{[$xx,U]}
   {ixD9} (AsmName:',U'   ; c:False; r:False; t:iExtended), {[$xxxx,U]}
   {ixDA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixDB} (AsmName:'D,U'  ; c:False; r:False; t:iImplied),
   {ixDC} (AsmName:',PCR' ; c:False; r:False; t:iRelative), {[$xx,PC]}
   {ixDD} (AsmName:',PCR' ; c:False; r:False; t:iLRelative),{[$xxxx,PC]}
   {ixDE} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixDF} (AsmName:''     ; c:False; r:False; t:iExtended), {[$xxxx]}

   {ixE0} (AsmName:',S+'  ; c:False; r:False; t:iImplied),
   {ixE1} (AsmName:',S++' ; c:False; r:False; t:iImplied),
   {ixE2} (AsmName:',-S'  ; c:False; r:False; t:iImplied),
   {ixE3} (AsmName:',--S' ; c:False; r:False; t:iImplied),
   {ixE4} (AsmName:',S'   ; c:False; r:False; t:iImplied),
   {ixE5} (AsmName:'B,S'  ; c:False; r:False; t:iImplied),
   {ixE6} (AsmName:'A,S'  ; c:False; r:False; t:iImplied),
   {ixE7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixE8} (AsmName:',S'   ; c:False; r:False; t:iImmediate),{ $xx,S}
   {ixE9} (AsmName:',S'   ; c:False; r:False; t:iExtended), { $xxxx,S}
   {ixEA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixEB} (AsmName:'D,S'  ; c:False; r:False; t:iImplied),
   {ixEC} (AsmName:',PCR' ; c:False; r:False; t:iRelative), { $xx,PC}
   {ixED} (AsmName:',PCR' ; c:False; r:False; t:iLRelative),{ $xxxx,PC}
   {ixEE} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixEF} (AsmName:''     ; c:False; r:False; t:iExtended), { $xxxx}

   {ixF0} (AsmName:''     ; c:False; r:False; t:iImplied),  {[,S+]}
   {ixF1} (AsmName:',S++' ; c:False; r:False; t:iImplied),
   {ixF2} (AsmName:''     ; c:False; r:False; t:iImplied),  {[,-S]}
   {ixF3} (AsmName:',--S' ; c:False; r:False; t:iImplied),
   {ixF4} (AsmName:',S'   ; c:False; r:False; t:iImplied),
   {ixF5} (AsmName:'B,S'  ; c:False; r:False; t:iImplied),
   {ixF6} (AsmName:'A,S'  ; c:False; r:False; t:iImplied),
   {ixF7} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixF8} (AsmName:',S'   ; c:False; r:False; t:iImmediate),{[$xx,S]}
   {ixF9} (AsmName:',S'   ; c:False; r:False; t:iExtended), {[$xxxx,S]}
   {ixFA} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixFB} (AsmName:'D,S'  ; c:False; r:False; t:iImplied),
   {ixFC} (AsmName:',PCR' ; c:False; r:False; t:iRelative), {[$xx,PC]}
   {ixFD} (AsmName:',PCR' ; c:False; r:False; t:iLRelative),{[$xxxx,PC]}
   {ixFE} (AsmName:''     ; c:False; r:False; t:iImplied),
   {ixFF} (AsmName:''     ; c:False; r:False; t:iExtended){[$xxxx]}
  )
 );


Var
 FileBIN:File;
 AsmMode:Boolean;
 P,ByteReaded:Word;
 FPos:LongInt;
 DisStr:String;
 BinBuffer:Array[0..1024]of Byte;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

Function HexByte(X:Byte):String;Begin
 HexByte:=ByteHex2Str(X)+'h';
End;

Function HexWord(X:Word):String;Begin
 HexWord:=HexWord2Str(X)+'h';
End;

Function LongHex2Str(value:LongInt):String;
Begin
 LongHex2Str:=ByteHex2Str((value shr 24)and $FF)+
              ByteHex2Str((value shr 16)and $FF)+
              ByteHex2Str((value shr 8)and $FF)+
              ByteHex2Str(value and $FF);
End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;


Function Decode(Var Buf;Var I:Word):String;
Var
 T:Array[0..65520] of Byte Absolute Buf;
 J:Integer;
 Len:Byte;
 B:Byte;
 W:Word;
 Ad:Word;
 Instr:InstrRec;
 Mode:InstrRec;
 LfFlag,RefFlag,CodeRef:Boolean;
 RefAddr:Word;
 R,Line,Comnt:String;

 Function ReadMem(Addr:Word):Byte;Begin
  If Addr-I>=I Then ReadMem:=0
               Else ReadMem:=T[Addr-I];
 End;

 Function GetByte:Byte;Begin
  GetByte:=T[I];
  Inc(I);
  Ad:=Ad+1;
  Len:=Len+1;
 End;

 Procedure Illegal;Begin
  R:='FCB';
  Line:='$'+ByteHex2Str(T[I]);
  Comnt:='';
  Len:=1;
  lfFlag:=False;
  refFlag:=False;
  codeRef:=False;
  refAddr:=0;
 End;

 Function Ref4Str(Addr:Word):String;Begin
  Ref4Str:='$'+HexWord2Str(Addr);
 End;

Begin
 Decode:='';
 R:='';
 Len:=0;
 Ad:=I;
 B:=GetByte;
 Comnt:='';
 Instr:=OpTable[1,B];
 If B=$10 Then Begin
  B:=GetByte;
  Instr:=OpTable[2,B];
 End
  Else
 If B=$11 Then Begin
  B:=GetByte;
  Instr:=OpTable[3,B];
 End;
 R:=Instr.AsmName;
 LfFlag:=Instr.C;
 RefFlag:=Instr.R;
 CodeRef:=Instr.R;
 Line:='';
 RefAddr:=0;
 If Length(R)=0 Then Illegal;
 Case Instr.t of
  iImplied:{Ne fait rien};
  iDirect:Begin
   B:=GetByte;
   If(AsmMode)Then Line:='<$'+ByteHex2Str(B)
              Else Line:='$'+ByteHex2Str(B);
  End;
  iImmediate:Begin
   b:=GetByte;
   Line:='#$'+ByteHex2Str(b);
  End;
  iLImmediate:Begin
   b:=GetByte;
   refAddr:=b*256+GetByte;
   b:=ReadMem(Ad);
   If(B in [$83,$C3,$CC])or((B=$10)and(ReadMem(ad+1)=$83))Then Line:='#$'+HexWord2Str(refAddr)
                                                          Else Line:='#'+Ref4Str(refAddr);
  End;
  iRelative:Begin
   b:=GetByte;
   w:=b;
   If w>=128 Then w:=w or $FF00;
   RefAddr:=Ad+W;
   Line:=Ref4Str(refAddr);
  End;
  iLRelative:Begin
   B:=GetByte;
   W:=B*256+GetByte;
   RefAddr:=Ad+W;
   Line:=Ref4Str(refAddr);
  End;
  iIndexed:Begin
   B:=GetByte;
   J:=B;
   Mode:=OpTable[4,B];
   Line:=Mode.AsmName;
   RefFlag:=Mode.r;
   If(Mode.t=iImplied)and(Length(Line)=0)Then Illegal
    Else
   Begin
    Case mode.t of
     iImplied:{Ne fait rien};
     iImmediate:Begin {add $xx dans le frontale }
      B:=GetByte;
      Line:='$'+ByteHex2Str(b)+line;
     End;
     iExtended:Begin { add $xxxx dans le frontale }
      B:=GetByte;
      W:=B*256+GetByte;
      Line:=Ref4Str(w)+Line;
     End;
     iRelative:Begin {add PC+$xx dans le frontale }
      B:=GetByte;
      W:=B;
      If W>=128 Then W:=W or $FF00;
      RefAddr:=Ad+W;
      Line:=Ref4Str(refAddr)+Line;
     End;
     iLRelative:Begin {add PC+$xxxx dans le frontale }
      B:=GetByte;
      W:=B*256+GetByte;
      RefAddr:=Ad+W;
      Line:=Ref4Str(refAddr)+Line;
     End;
    End;
    If(J and $90)=$90 Then Line:='['+Line+']'
                      Else Line:=Line;
   End;
  End;
  iExtended:Begin
   B:=GetByte;
   refAddr:=B*256+GetByte;
   Line:=Ref4Str(refAddr);
  End;
  iTfrExg:Begin
   B:=GetByte;
   Line:=Copy('D X Y U S PC????A B CCDP????????',(b SHR 4) * 2 + 1,2);
   If Line[Length(Line)]=' 'Then Line[0]:=Chr(Length(line)-1);
   Line:=Line+','+Copy('D X Y U S PC????A B CCDP????????',(B and 15)*2+1,2);
   If Line[Length(Line)]=' 'Then Line[0]:=Chr(Length(Line)-1);
   If Pos('?',line)<>0 Then Illegal Else
   If(b and 15)=5 Then lfFlag:=True; {PC}
  End;
  iPshPul:Begin
   W:=B;
   B:=GetByte;
   For J:=0 to 7 do If(B and Pow2[J])<>0 Then Begin
    If(W and $FE)=$34 Then Line:=Line+Copy('CCA B DPX Y U PC',J*2+1,2)
                      Else Line:=Line+Copy('CCA B DPX Y S PC',J*2+1,2);
    If Line[Length(Line)]=' 'Then Line[0]:=Chr(Length(Line)-1);
    Line:=Line+',';
   End;
   If Line[Length(Line)]=','Then Line[0]:=Chr(Length(Line)-1);
   J:=Pos('A,B',Line);
   If J<>0 Then Line:=Copy(line,1,J-1)+'D'+Copy(line,J+3,Length(line)-J-2);
   If((w=$35)or(w=$37))and(b>=128)Then lfFlag:=True; {PC}
  End;
 End;
 If(CodeRef)Then RefFlag:=True;
 If RefFlag=False Then RefAddr:=0;
 Decode:=PadRight(R,5)+' '+Line;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('DIS6809 : Cette commande permet de d‚sassembleur un code binaire de');
  WriteLn('          microprocesseur 6809 en langage de programmation assembleur 6809.');
  WriteLn;
  WriteLn('Syntaxe : DIS6809 nomdufichier');
  WriteLn;
  WriteLn(' nomduficher           Nom du fichier binaire');
 End
  Else
 If ParamCount>0 Then Begin
  AsmMode:=False;
  {$I-}Assign(FileBIN,ParamStr(1));
  Reset(FileBIN,1);{$I+}
  If IOResult=0 Then Begin
   FPos:=0;
   While FPos<FileSize(FileBIN)do Begin
    BlockRead(FileBIN,BinBuffer,SizeOf(BinBuffer),ByteReaded);
    If ByteReaded=0 Then Break;
    P:=0;
    If ByteReaded<15 Then Begin
     While(P<ByteReaded)do Begin
      Write(HexWord2Str(P),'h ');
      DisStr:=Decode(BinBuffer,P);
      WriteLn(DisStr);
     End;
     Break;
    End
     Else
    Begin
     While(P<ByteReaded-15)do Begin
      Write(LongHex2Str(FPos+P),'h ');
      DisStr:=Decode(BinBuffer,P);
      WriteLn(DisStr);
     End;
    End;
    Inc(FPos,P);
   End;
   Close(FileBIN);
  End
   Else
  WriteLn('Impossible de lire le fichier ',ParamStr(1));
 End;
END.