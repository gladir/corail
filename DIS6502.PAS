{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program DIS6502;

Type
 TParm=(
  p0,
  pImpl, { Pas de paramätres }
  pAbso, { word }
  pZPge, { byte }
  pImm,  { #byte }
  pAbsX, { word+x }
  pAbsY, { word+y }
  pIndX, { [byte+x] = array[x]^ }
  pIndY, { [byte]+y = array^[y] }
  pZPgX, { byte+x }
  pZPgY, { byte+y }
  pRela, { shortint(byte) }
  pInd   { [word] }
 );

 TOpCode=Record
  Name:String[3];
  Parm:TParm;
 end;

Const
 OpCode:Array[0..255] of TOpCode=(
 {00-0F}
  (Name:'BRK'; Parm:pImpl),  (Name:'ORA'; Parm:pIndX),
  (Name:'JAM'; Parm:pImpl),  (Name:'SLO'; Parm:pIndX),
  (Name:'NOP'; Parm:pZpge),  (Name:'ORA'; Parm:pZPge),
  (Name:'ASL'; Parm:pZPge),  (Name:'SLO'; Parm:pZPge),
  (Name:'PHP'; Parm:pImpl),  (Name:'ORA'; Parm:pImm),
  (Name:'ASL'; Parm:pImpl),  (Name:'ANC'; Parm:pImm),
  (Name:'NOP'; Parm:pAbso),  (Name:'ORA'; Parm:pAbso),
  (Name:'ASL'; Parm:pAbso),  (Name:'';    Parm:p0   ),
 {10-1F}
  (Name:'BPL'; Parm:pRela),  (Name:'ORA'; Parm:pIndY),
  (Name:'';    Parm:p0   ),  (Name:'SLO'; Parm:pIndY),
  (Name:'NOP'; Parm:pZPgX),  (Name:'ORA'; Parm:pZPgX),
  (Name:'ASL'; Parm:pZPgX),  (Name:'';    Parm:p0   ),
  (Name:'CLC'; Parm:pImpl),  (Name:'ORA'; Parm:pAbsY),
  (Name:'';    Parm:p0   ),  (Name:'';    Parm:p0   ),
  (Name:'';    Parm:p0   ),  (Name:'ORA'; Parm:pAbsX),
  (Name:'ASL'; Parm:pAbsX),  (Name:'';    Parm:p0   ),
 {20-2F}
  (Name:'JSR'; Parm:pAbso),  (Name:'AND'; Parm:pIndX),
  (Name:'';    Parm:p0   ),  (Name:'RLA'; Parm:pIndX),
  (Name:'BIT'; Parm:pZPge),  (Name:'AND'; Parm:pZPge),
  (Name:'ROL'; Parm:pZPge),  (Name:'RLA'; Parm:pZPge),
  (Name:'PLP'; Parm:pImpl),  (Name:'AND'; Parm:pImm),
  (Name:'ROL'; Parm:pImpl),  (Name:'';    Parm:p0   ),
  (Name:'BIT'; Parm:pAbso),  (Name:'AND'; Parm:pAbso),
  (Name:'ROL'; Parm:pAbso),  (Name:'RLA'; Parm:pAbso),
 {30-3F}
  (Name:'BMI'; Parm:pRela),  (Name:'AND'; Parm:pIndY),
  (Name:'';    Parm:p0   ),  (Name:'RLA'; Parm:pIndY),
  (Name:'';    Parm:p0   ),  (Name:'AND'; Parm:pZPgX),
  (Name:'ROL'; Parm:pZPgX),  (Name:'RLA'; Parm:pZPgX),
  (Name:'SEC'; Parm:pImpl),  (Name:'AND'; Parm:pAbsY),
  (Name:'';    Parm:p0   ),  (Name:'RLA'; Parm:pAbsY),
  (Name:'';    Parm:p0   ),  (Name:'AND'; Parm:pAbsX),
  (Name:'ROL'; Parm:pAbsX),  (Name:'RLA'; Parm:pAbsX),
 {40-4F}
  (Name:'RTI'; Parm:pImpl),  (Name:'EOR'; Parm:pIndX),
  (Name:'';    Parm:p0   ),  (Name:'SRE'; Parm:pIndX),
  (Name:'';    Parm:p0   ),  (Name:'EOR'; Parm:pZPge),
  (Name:'LSR'; Parm:pZPge),  (Name:'';    Parm:p0   ),
  (Name:'PHA'; Parm:pImpl),  (Name:'EOR'; Parm:pImm ),
  (Name:'LSR'; Parm:pImpl),  (Name:'ASR'; Parm:pImm ),
  (Name:'JMP'; Parm:pAbso),  (Name:'EOR'; Parm:pAbso),
  (Name:'LSR'; Parm:pAbso),  (Name:'SRE'; Parm:pAbso),
 {50-5F}
  (Name:'BVC'; Parm:pRela),  (Name:'EOR'; Parm:pIndY),
  (Name:'';    Parm:p0   ),  (Name:'SRE'; Parm:pIndY),
  (Name:'';    Parm:p0   ),  (Name:'EOR'; Parm:pZPgX),
  (Name:'LSR'; Parm:pZPgX),  (Name:'SRE'; Parm:pZPgX),
  (Name:'CLI'; Parm:pImpl),  (Name:'EOR'; Parm:pAbsY),
  (Name:'';    Parm:p0   ),  (Name:'SRE'; Parm:pAbsY),
  (Name:'';    Parm:p0   ),  (Name:'EOR'; Parm:pAbsX),
  (Name:'LSR'; Parm:pAbsX),  (Name:'SRE'; Parm:pAbsX),
 {60-6F}
  (Name:'RTS'; Parm:pImpl),  (Name:'ADC'; Parm:pIndX),
  (Name:'';    Parm:p0   ),  (Name:'RRA'; Parm:pIndX),
  (Name:'';    Parm:p0   ),  (Name:'ADC'; Parm:pZPge),
  (Name:'ROR'; Parm:pZPge),  (Name:'RRA'; Parm:pZPge),
  (Name:'PLA'; Parm:pImpl),  (Name:'ADC'; Parm:pImm),
  (Name:'ROR'; Parm:pImpl),  (Name:'';    Parm:p0   ),
  (Name:'JMP'; Parm:pInd ),  (Name:'ADC'; Parm:pAbso),
  (Name:'ROR'; Parm:pAbso),  (Name:'RRA'; Parm:pAbso),
 {70-7F}
  (Name:'BVS'; Parm:pRela),  (Name:'ADC'; Parm:pIndY),
  (Name:'';    Parm:p0   ),  (Name:'RRA'; Parm:pIndY),
  (Name:'';    Parm:p0   ),  (Name:'ADC'; Parm:pZPgX),
  (Name:'ROR'; Parm:pZPgX),  (Name:'RRA'; Parm:pZPgX),
  (Name:'SEI'; Parm:pImpl),  (Name:'ADC'; Parm:pAbsY),
  (Name:'';    Parm:p0   ),  (Name:'RRA'; Parm:pAbsY),
  (Name:'';    Parm:p0   ),  (Name:'ADC'; Parm:pAbsX),
  (Name:'ROR'; Parm:pAbsX),  (Name:'RRA'; Parm:pAbsX),
 {80-8F}
  (Name:'NOP'; Parm:pImm ),  (Name:'STA'; Parm:pIndX),
  (Name:'';    Parm:p0   ),  (Name:'SAX'; Parm:pIndX),
  (Name:'STY'; Parm:pZPge),  (Name:'STA'; Parm:pZPge),
  (Name:'STX'; Parm:pZPge),  (Name:'SAX'; Parm:pZPge),
  (Name:'DEY'; Parm:pImpl),  (Name:'';    Parm:p0   ),
  (Name:'TXA'; Parm:pImpl),  (Name:'ANE'; Parm:pImm ),
  (Name:'STY'; Parm:pAbso),  (Name:'STA'; Parm:pAbso),
  (Name:'STX'; Parm:pAbso),  (Name:'SAX'; Parm:pAbso),
 {90-9F}
  (Name:'BCC'; Parm:pRela),  (Name:'STA'; Parm:pIndY),
  (Name:'';    Parm:p0   ),  (Name:'SHA'; Parm:pIndY),
  (Name:'STY'; Parm:pZPgX),  (Name:'STA'; Parm:pZPgX),
  (Name:'STX'; Parm:pZPgY),  (Name:'SAX'; Parm:pZpgX),
  (Name:'TYA'; Parm:pImpl),  (Name:'STA'; Parm:pAbsY),
  (Name:'TXS'; Parm:pImpl),  (Name:'SHS'; Parm:pAbsY),
  (Name:'SHY'; Parm:pAbsX),  (Name:'STA'; Parm:pAbsX),
  (Name:'SHX'; Parm:pAbsY),  (Name:'SHA'; Parm:pAbsY),
 {A0-AF}
  (Name:'LDY'; Parm:pImm),   (Name:'LDA'; Parm:pIndX),
  (Name:'LDX'; Parm:pImm),   (Name:'LAX'; Parm:pIndX),
  (Name:'LDY'; Parm:pZPge),  (Name:'LDA'; Parm:pZPge),
  (Name:'LDX'; Parm:pZPge),  (Name:'LAX'; Parm:pZPge),
  (Name:'TAY'; Parm:pImpl),  (Name:'LDA'; Parm:pImm),
  (Name:'TAX'; Parm:pImpl),  (Name:'LXA'; Parm:pImm ),
  (Name:'LDY'; Parm:pAbso),  (Name:'LDA'; Parm:pAbso),
  (Name:'LDX'; Parm:pAbso),  (Name:'LAX'; Parm:pAbso),
 {B0-BF}
  (Name:'BCS'; Parm:pRela),  (Name:'LDA'; Parm:pIndY),
  (Name:'';    Parm:p0   ),  (Name:'LAX'; Parm:pIndY),
  (Name:'LDY'; Parm:pZPgX),  (Name:'LDA'; Parm:pZpgX),
  (Name:'LDX'; Parm:pZPgY),  (Name:'LAX'; Parm:pZpgY),
  (Name:'CLV'; Parm:pImpl),  (Name:'LDA'; Parm:pAbsY),
  (Name:'TSX'; Parm:pImpl),  (Name:'LAS'; Parm:pAbsY),
  (Name:'LDY'; Parm:pAbsX),  (Name:'LDA'; Parm:pAbsX),
  (Name:'LDX'; Parm:pAbsY),  (Name:'LAX'; Parm:pAbsY),
 {C0-CF}
  (Name:'CPY'; Parm:pImm ),  (Name:'CMP'; Parm:pIndX),
  (Name:'';    Parm:p0   ),  (Name:'DCP'; Parm:pIndX),
  (Name:'CPY'; Parm:pZPge),  (Name:'CMP'; Parm:pZPge),
  (Name:'DEC'; Parm:pZPge),  (Name:'DCP'; Parm:pZPge),
  (Name:'INY'; Parm:pImpl),  (Name:'CMP'; Parm:pImm),
  (Name:'DEX'; Parm:pImpl),  (Name:'SBX'; Parm:pImm ),
  (Name:'CPY'; Parm:pAbso),  (Name:'CMP'; Parm:pAbso),
  (Name:'DEC'; Parm:pAbso),  (Name:'DCP'; Parm:pAbso),
 {D0-DF}
  (Name:'BNE'; Parm:pRela),  (Name:'CMP'; Parm:pIndY),
  (Name:'';    Parm:p0   ),  (Name:'DCP'; Parm:pIndY),
  (Name:'';    Parm:p0   ),  (Name:'';    Parm:p0   ),
  (Name:'DEC'; Parm:pZPgX),  (Name:'DCP'; Parm:pZPgX),
  (Name:'CLD'; Parm:pImpl),  (Name:'CMP'; Parm:pAbsY),
  (Name:'';    Parm:p0   ),  (Name:'DCP'; Parm:pAbsY),
  (Name:'';    Parm:p0   ),  (Name:'CMP'; Parm:pAbsX),
  (Name:'DEC'; Parm:pAbsX),  (Name:'DCP'; Parm:pAbsX),
 {E0-EF}
  (Name:'CPX'; Parm:pImm ),  (Name:'SBC'; Parm:pIndX),
  (Name:'';    Parm:p0   ),  (Name:'ISB'; Parm:pIndX),
  (Name:'CPX'; Parm:pZPge),  (Name:'SBC'; Parm:pZPge),
  (Name:'INC'; Parm:pZPge),  (Name:'ISB'; Parm:pZPge),
  (Name:'INX'; Parm:pImpl),  (Name:'SBC'; Parm:pImm),
  (Name:'NOP'; Parm:pImpl),  (Name:'';    Parm:p0   ),
  (Name:'CPX'; Parm:pAbso),  (Name:'SBC'; Parm:pAbso),
  (Name:'INC'; Parm:pAbso),  (Name:'ISB'; Parm:pAbso),
 {F0-FF}
  (Name:'BEQ'; Parm:pRela),  (Name:'SBC'; Parm:pIndY),
  (Name:'REU'; Parm:pImm ),  (Name:'ISB'; Parm:pIndY),
  (Name:'';    Parm:p0   ),  (Name:'SBC'; Parm:pZPgX),
  (Name:'INC'; Parm:pZPgX),  (Name:'ISB'; Parm:pZPgX),
  (Name:'SED'; Parm:pImpl),  (Name:'SBC'; Parm:pAbsY),
  (Name:'';    Parm:p0   ),  (Name:'ISB'; Parm:pAbsY),
  (Name:'';    Parm:p0   ),  (Name:'SBC'; Parm:pAbsX),
  (Name:'INC'; Parm:pAbsX),  (Name:'ISB'; Parm:pAbsX)
  );

Var
 FileBIN:File;
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
 Pip2:Word;
 Pip1:Byte Absolute Pip2;
 Instr:String;
Begin
 Pip2:=T[I+1]+T[I+2]*256;
 Instr:=OpCode[T[I]].Name+' ';
 Case OpCode[T[I]].Parm of
  pImpl:Inc(I); { Ne fait rien }
  pAbso:Begin
   Instr:=Instr+ '$'+HexWord2Str(Pip2);
   Inc(I,3);
  End;
  pZPge:Begin
   Instr:=Instr+ '$'+ByteHex2Str(Pip1);
   Inc(I,2);
  End;
  pImm:Begin
   Instr:=Instr+'#$'+ByteHex2Str(Pip1);
   Inc(I,2);
  End;
  pAbsX:Begin
   Instr:=Instr+ '$'+HexWord2Str(Pip2)+',X';
   Inc(I,3);
  End;
  pAbsY:Begin
   Instr:=Instr+ '$'+HexWord2Str(Pip2)+',Y';
   Inc(I,3);
  End;
  pIndX:Begin
   Instr:=Instr+'($'+ByteHex2Str(Pip1)+',X)';
   Inc(I,2);
  End;
  pIndY:Begin
   Instr:=Instr+'($'+ByteHex2Str(Pip1)+'),Y';
   Inc(I,2);
  End;
  pZPgX:Begin
   Instr:=Instr+ '$'+ByteHex2Str(Pip1)+',X';
   Inc(I,2);
  End;
  pZPgY:Begin
   Instr:=Instr+ '$'+ByteHex2Str(Pip1)+',Y';
   Inc(I,2);
  End;
  pRela:Begin
   If ShortInt(Pip1+2)=0 Then Instr:=Instr+' *'
                         Else Instr:=Instr+ '$'+HexWord2Str(I+2+ShortInt(Pip1));
   Inc(I,2);
  ENd;
  pInd:Begin
   Instr:=Instr+'($'+HexWord2Str(Pip2)+')';
   Inc(I,3);
  End;
  Else Begin
   Instr:='DB $'+ByteHex2Str(T[I]);
   Inc(I);
  End;
 End;
 Decode:=Instr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('DIS6502 : Cette commande permet de dÇsassembleur un code binaire de');
  WriteLn('          microprocesseur 6502 en langage de programmation assembleur 6502.');
  WriteLn;
  WriteLn('Syntaxe : DIS6502 nomdufichier');
  WriteLn;
  WriteLn(' nomduficher           Nom du fichier binaire');
 End
  Else
 If ParamCount>0 Then Begin
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
