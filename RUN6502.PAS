{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program RUN6502;

Uses Crt;

Var
 DebugOn,Verbose:Boolean;
 Hardware:(noHardware,AppleII,Commodore64,Atari400,Atari800,Atari130XE);
 codeRunning:Boolean;
 A:Byte;     { Registre accumulateur }
 X:Byte;     { Registre d'index X }
 Y:Byte;     { Registre d'index Y }
 P:Byte;     { Registre d'etat de processeur }
 PC:Word; { Registre de compteur der programmes }
 SP:Word; { Registre de pointeur de pile }
 memory:Array[0..16384] of Byte;

Procedure InitEmul;Begin
 codeRunning:=True;
 A:=0;
 X:=0;
 Y:=0;
 P:=0;
 PC:=$600;
 SP:=$100;
End;

Function num2hex(nr:Byte):String;
Const
 HexStr:Array[0..15]of Char=('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f');
Begin
 num2hex := HexStr[(nr and $f0) shr 4] + HexStr[nr and $F];
End;

Function addr2hex(address:Word):String;Begin
  addr2hex := num2hex((address shr 8) and $ff)+num2hex(address and $ff);
End;

Function popByte:Byte;Begin
 popByte := memory[PC] and $ff;
 PC := PC + 1;
End;

Function popWord:Word;Begin
 popWord := popByte + (popByte shl 8);
End;

Procedure stackPush(value:Byte);Begin
  If SP >= 0 Then Begin
   SP := SP - 1;
   memory[(SP and $ff)+$100] := value and $ff;
  End
   else
  Begin
   WriteLn('Pile pleine: ',SP);
   codeRunning := false;
  End;
End;

Function stackPop:Byte;Begin
  If SP < $100 Then Begin
   stackPop := memory[SP+$100];
   SP := SP + 1;
  End
   else
  Begin
   WriteLn('Pile vide');
   codeRunning := false;
   stackPop:=0;
  End;
End;

Procedure jumpBranch(offset:Word);Begin
  If offset > $7f Then PC := PC - ($100 - offset) Else PC := PC + offset;
End;

Procedure memStoreByte(address:Word; value:Byte);
Var
 X,Y:Byte;
Begin
 If(Hardware=Commodore64)Then Begin
  Case address of
   $0400..$07E7:Begin { Texte de la m‚moire vid‚o }
    X:=(address-$0400) mod 40;
    Y:=(address-$0400) div 40;
    GotoXY(X+1,Y+1);
    Write(Chr(value));
    Exit;
   End;
  End;
 End;
 If address>=SizeOf(memory)Then Exit;
 memory[address] := (value and $ff);
End;

Function memReadByte(address:Word):Byte;Begin
 If(Hardware=AppleII)Then Begin
  Case address of
   $BF0E:Begin { SCRMODE }
    memReadByte:=$04; { // 80 colonnes }
    Exit;
   End;
  End;
 End;
 If address>=SizeOf(memory)Then Exit;
 memReadByte := memory[address];
End;

Procedure testADC(value:Byte);
Var
 tmp:Word;
Begin
  If (A xor value) and $80 = $80 Then P := P and $bf else P := P or $40;
  If P and 8 = 8 Then Begin
    tmp := (A and $0f) + (value and $0f) + (P and 1);
    If tmp >= 10 Then tmp := $10 or ((tmp+6) and $0f);
    tmp := tmp + (A and $f0) + (value and $f0);
    If tmp >= 160 Then Begin
      P := P or 1;
      If (P and $bf <> 0) and (tmp >= $180 ) Then P := P and $bf;
      tmp := tmp + $60;
    End
     else
    Begin
      P := P and $fe;
      If (P and $bf <> 0) and ( tmp < $80 ) Then P := P and $bf;
    End;
  End
   else
  Begin
    tmp := A + value + (P and 1);
    If tmp >= $100 Then Begin
      P := P or 1;
      If (P and $bf <> 0) and (tmp >= $180) Then P := P and $bf;
    End
     else
    Begin
      P := P and $fe;
      If (P and $bf <> 0) and (tmp < $80) Then P := P and $bf;
    End;
  End;
  A := tmp and $ff;
  If A <> 0 Then P := P and $fd else P := P or $02;
  If A and $80 = $80 Then P := P or $80 else P := P and $7f;
End;

Procedure testSBC(value:Byte);
Var
 tmp,w:Word;
Begin
  If P and 8 = 8 Then Begin
   tmp := $0f + (A and $0f) - (value and $0f) + (P and 1);
   If tmp < $10 Then Begin
    w := 0;
    tmp := tmp - 6;
   End
    else
   Begin
    w := $10;
    tmp := tmp - $10;
   End;
   w := w +$f0 + (A and $f0) - (value and $f0);
   If w < $100 Then Begin
    P := P and $fe;
    If (P and $bf <> 0) and (w < $80) Then P := P and $bf;
    w := w - $60;
   End
    Else
   Begin
    P := P or 1;
    If (P and $bf <> 0) and (w >= $180) Then P := P and $bf;
   End;
   w := w + tmp;
  End
   else
  Begin
   w := $ff + A - value + (P and 1);
   If w < $100 Then Begin
    P := P and $fe;
    If (P and $bf <> 0) and (w < $80) Then P := P and $bf;
   End
    else
   Begin
    P := P or 1;
    If(P and $bf<>0) and (w >= $180) Then P := P and $bf;
   End;
  End;
  A := w and $ff;
  If A <> 0 Then P := P and $fd else P := P or $02;
  If A and $80 = $80 Then P := P or $80 else P := P and $7f;
End;

Procedure doCompare(reg,val:Word);Begin
  if (reg+val) > $ff Then P := P or 1 else P := P and $fe;
  val := (reg-val);
  If val <> 0 Then P := P and $fd else P := P or $02;
  If val and $80 = $80 Then P := P or $80 else P := P and $7f;
End;

Procedure ExecEmul;
Var
 opcode,zp,offset:Byte;
 currAddr,address,value,sf:Word;
Begin
  If Not(codeRunning)Then Exit;
  opcode := popByte;
  If(DebugOn)Then WriteLn('PC=', addr2hex(PC-1), ' opcode=', opcode, ' X=', X, ' Y=', Y, ' A=', A, ' P=', P);
  Case opcode of
    $00:                            { BRK implicite }
      codeRunning := false;
    $01:Begin                       { ORA INDX }
      address := popByte + X;
      value := memReadByte(address) + (memReadByte( address+1) shl 8);
      A := A or Lo(value);
      If A <> 0 Then P := P and $fd else P := P or $02;
      If A and $80 = $80 Then P := P or $80 else P := P and $7f;
     End;
    $05:Begin                       { ORA ZP }
      zp := popByte;
      A := A or memReadByte(zp);
      If A <> 0 Then P := P and $fd else P := P or $02;
      If A and $80 = $80 Then P := P or $80 else P := P and $7f;
     End;
    $06:Begin                       { ASL ZP }
      zp := popByte;
      value := memReadByte( zp );
      P := (P and $fe) or ((value shr 7) and 1);
      value := value shl 1;
      memStoreByte( zp, value );
      If value <> 0 Then P := P and $fd else P := P or $02;
      If value and $80 = $80 Then P := P or $80 else P := P and $7f;
     End;
    $08:                            { PHP }
      stackPush(P);
    $09:Begin                       { ORA IMM }
      A := A or popByte;
      If A <> 0 Then P := P and $fd else P := P or $02;
      If A and $80 = $80 Then P := P or $80 else P := P and $7f;
     End;
    $0a:Begin                       { ASL IMPL }
       P := (P and $fe) or ((A shr 7) and 1);
       A := A shl 1;
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $0d:                            { ORA ABS }
      Begin
       A := A or memReadByte( popWord );
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $0e:Begin                       { ASL ABS }
       address := popWord;
       value := memReadByte(address);
       P := (P and $fe) or ((value shr 7) and 1);
       value := value shl 1;
       memStoreByte(address, value);
       If value <> 0 Then P := P and $fd else P := P or 2;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $10:Begin                      { BPL }
       offset := popByte;
       If P and $80 = 0 Then jumpBranch( offset );
      End;
    $11:Begin                      { ORA INDY }
       zp := popByte;
       value := memReadByte(zp) + (memReadByte(zp+1) shl 8) + Y;
       A := A or memReadByte(value);
       If A <> 0 Then P := P and $fd  Else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $15:Begin                      { ORA ZPX }
       address := (popByte + X) and $ff;
       A := A or memReadByte(address);
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $16:Begin                      { ASL ZPX }
       address := (popByte + X) and $ff;
       value := memReadByte(address);
       P := (P and $fe) or ((value shr 7) and 1);
       value := value shl 1;
       memStoreByte(address, value);
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 <> $80 Then P := P or $80 else P := P and $7f;
      End;
    $18:                            { CLC }
      P := P and $fe;
    $19:Begin                       { ORA ABSY }
       address := popWord + Y;
       A := A or memReadByte(address);
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $1d:Begin                       { ORA ABSX }
       address := popWord + X;
       A := A or memReadByte(address);
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $1e:Begin                       { ASL ABSX }
       address := popWord + X;
       value := memReadByte(address);
       P := (P and $fe) or ((value shr 7) and 1);
       value := value shl 1;
       memStoreByte( address, value );
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $20:Begin                      { JSR ABS }
       address := popWord;
       currAddr := PC - 1;
       stackPush((currAddr shr 8) and $ff);
       stackPush(currAddr and $ff);
       PC := address;
      End;
    $21:Begin                      { AND INDX }
       address := (popByte + X) and $ff;
       value := memReadByte(address) + (memReadByte(address + 1) shl 8);
       A := A and value;
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $24:Begin                      { BIT ZP }
       zp := popByte;
       value := memReadByte( zp );
       If value and A <> 0 Then P := P and $fd else P := P or $02;
       P := (P and $3f) or (value and $c0);
      End;
    $25:Begin                      { AND ZP }
       zp := popByte;
       A := A and memReadByte( zp );
       If A <> 0 Then P := P and $fd else P := P or 2;
       If A and $80 = $80 Then P := P and $80 else P := P and $7f;
      End;
    $26:Begin                      { ROL ZP }
       sf := (P and 1);
       address := popByte;
       value := memReadByte( address );
       P := (P and $fe) or ((value shr 7) and 1);
       value := value shl 1;
       value := value or sf;
       memStoreByte( address, value );
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $28:                            { PLP }
      P := stackPop or $20;
    $29:Begin                       { AND IMM }
       A := A and popByte;
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
     End;
    $2a:Begin                       { ROL A }
       sf := (P and 1);
       P := (P and $fe) or ((A shr 7) and 1);
       A := A shl 1;
       A := A or sf;
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $2c:Begin                      { BIT ABS }
       value := memReadByte(popWord);
       If value and A <> 0 Then P := P and $fd else P := P or $02;
       P := (P and $3f) or (value and $c0);
      End;
    $2d:Begin                      { AND ABS }
       value := memReadByte(popWord);
       A := A and value;
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80=$80 Then P := P or $80 else P := P and $7f;
      End;
    $2e:Begin                      { ROL ABS }
       sf := P and 1;
       address := popWord;
       value := memReadByte( address );
       P := (P and $fe) or ((value shr 7) and 1);
       value := value shl 1;
       value := value or sf;
       memStoreByte( address, value );
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $30:Begin                       { BMI }
       offset := popByte;
       If P and $80 <> $80 Then jumpBranch( offset );
      End;
    $31:Begin                       { AND INDY }
       zp := popByte;
       value := memReadByte(zp) + (memReadByte(zp+1) shl 8) + Y;
       A := A and memReadByte(value);
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $35:Begin                       { AND INDX }
       zp := popByte;
       value := memReadByte(zp) + (memReadByte(zp+1) shl 8) + X;
       A := A and memReadByte(value);
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $36:Begin                       { ROL ZPX }
       sf := P and 1;
       address := (popByte + X) and $ff;
       value := memReadByte(address);
       P := (P and $fe) or ((value shr 7) and 1);
       value := value shl 1;
       value := value or sf;
       memStoreByte( address, value );
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $38:                            { SEC }
      P := P or 1;
    $39:Begin                       { AND ABSY }
       address := popWord + Y;
       value := memReadByte( address );
       A := A and value;
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and  $7f;
      End;
    $3d:Begin                       { AND ABSX }
       address := popWord + X;
       value := memReadByte(address);
       A := A and value;
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $3e:Begin                       { ROL ABSX }
       sf := P and 1;
       address := popWord + X;
       value := memReadByte(address);
       P := (P and $fe) or ((value shr 7) and 1);
       value := value shl 1;
       value := value or sf;
       memStoreByte(address, value);
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $40:;                           { RTI (non-support‚, =NOP) }
    $41:Begin                       { EOR INDX }
       zp := (popByte + X) and $ff;
       value := memReadByte(zp) + (memReadByte(zp+1) shl 8);
       A := A xor memReadByte(value);
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $45:Begin                       { EOR ZPX }
       address := (popByte + X) and $ff;
       value := memReadByte(address);
       A := A xor value;
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $46:Begin                       { LSR ZP }
       address := popByte and $ff;
       value := memReadByte(address);
       P := (P and $fe) or (value and 1);
       value := value shr 1;
       memStoreByte(address, value);
       If value <> 0 Then P := P and $fd else P := P or 2;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $48:                            { PHA }
      stackPush(A);
    $49:Begin                       { EOR IMM }
       A := A xor popByte;
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P + $80 else P := P and $7f;
      End;
    $4a:Begin                        { LSR }
       P := (P and $fe) or (A and 1);
       A := A shr 1;
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $4c:                            { JMP abs }
      PC := popWord;
    $4d:Begin                       { EOR abs }
       address := popWord;
       value := memReadByte(address);
       A := A xor value;
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $4e:Begin                       { LSR abs }
       address := popWord;
       value := memReadByte(address);
       P := (P and $fe) or (value and 1);
       value := value shr 1;
       memStoreByte(address, value);
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $50:Begin                      { BVC (efface le debordement) }
       offset := popByte;
       If P and $40 = 0 Then jumpBranch(offset);
      End;
    $51:Begin                      { EOR INDY }
       zp := popByte;
       value := memReadByte(zp) + (memReadByte(zp+1) shl 8) + Y;
       A := A xor memReadByte(value);
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $55:Begin                      { EOR ZPX }
       address := (popByte + X) and $ff;
       A := A xor memReadByte(address);
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $56:Begin                      { LSR ZPX }
       address := (popByte + X) and $ff;
       value := memReadByte(address);
       P := (P and $fe) or (value and 1);
       value := value shr 1;
       memStoreByte(address, value);
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $58:;                          { CLI (ne fait rien) }
    $59:Begin                      { EOR ABSY }
       address := popWord + Y;
       value := memReadByte(address);
       A := A xor value;
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $5d:Begin                      { EOR ABSX }
       address := popWord + X;
       value := memReadByte(address);
       A := A xor value;
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $5e:Begin                      { LSR ABSX }
       address := popWord + X;
       value := memReadByte(address);
       P := (P and $fe) or (value and 1);
       value := value shr 1;
       memStoreByte(address, value);
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $60:                           { RTS }
      PC := (stackPop + 1) or (stackPop shl 8);
    $61:Begin                      { ADC INDX }
       zp := (popByte + X) and $ff;
       address := memReadByte(zp) + (memReadByte(zp+1) shl 8);
       value := memReadByte(address);
       testADC( value );
      End;
    $65:Begin                      { ADC ZP }
       address := popByte;
       value := memReadByte(address);
       testADC(value);
      End;
    $66:Begin                      { ROR ZP }
       sf := P and 1;
       address := popByte;
       value := memReadByte( address );
       P := (P and $fe) or (value and 1);
       value := value shr 1;
       If sf <> 0 Then value := value or $80;
       memStoreByte( address, value );
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $68:Begin                      { PLA }
       A := stackPop;
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $69:Begin                      { ADC IMM }
       value := popByte;
       testADC(value);
      End;
    $6a:Begin                      { ROR A }
      sf := P and 1;
      P := (P and $fe) or (A and 1);
      A := A shr 1;
      If sf <> 0 Then A := A or $80;
      If A <> 0 Then P := P and $fd else P := P or $02;
      If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $6c:                           { JMP INDIR }
      PC := memReadByte(popByte) + (memReadByte(popByte) shl 8);
    $6d:Begin                      { ADC ABS }
       address := popWord;
       value := memReadByte(address);
       testADC(value);
      End;
    $6e:Begin                      { ROR ABS }
       sf := P and 1;
       address := popWord;
       value := memReadByte(address);
       P := (P and $fe) or (value and 1);
       value := value shr 1;
       If sf <> 0 Then value := value or $80;
       memStoreByte(address, value);
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $70:Begin                     { BVS (branch on overflow set) }
       offset := popByte;
       If P and $40 = $40 Then jumpBranch(offset);
      End;
    $71:Begin                     { ADC INY }
       zp := popByte;
       address := memReadByte(zp) + (memReadByte(zp + 1) shl 8);
       value := memReadByte(address + Y);
       testADC(value);
      End;
    $75:Begin                     { ADC ZPX }
       address := (popByte + X) and $ff;
       value := memReadByte(address);
       P := (P and $fe) or (value and 1);
       testADC(value);
      End;
    $76:Begin                     { ROR ZPX }
       sf := (P and 1);
       address := (popByte + X) and $ff;
       value := memReadByte(address);
       P := (P and $fe) or (value and 1);
       value := value shr 1;
       If sf <> 0 Then value := value or $80;
       memStoreByte(address, value);
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $78:;                          { SEI (ne fait rien) }
    $79:Begin                      { ADC ABSY }
       address := popWord;
       value := memReadByte(address + Y);
       testADC(value);
      End;
    $7d:Begin                      { ADC ABSX }
       address := popWord;
       value := memReadByte(address + X);
       testADC(value);
      End;
    $7e:Begin                      { ROR ABSX }
       sf := P and 1;
       address := popWord + X;
       value := memReadByte(address);
       P := (P and $fe) or (value and 1);
       value := value shr 1;
       If value <> 0 Then value := value or $80;
       memStoreByte( address, value );
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P and $80 else P := P and $7f;
      End;
    $81:Begin                     { STA INDX }
       zp := (popByte + X) and $ff;
       address := memReadByte(zp) + (memReadByte(zp+1) shl 8);
       memStoreByte(address, A);
      End;
    $84:                           { STY ZP }
      memStoreByte( popByte, Y);
    $85:                           { STA ZP }
      memStoreByte( popByte, A);
    $86:                           { STX ZP }
      memStoreByte( popByte, X);
    $88:Begin                      { DEY (1 octet) }
       Y := (Y-1) and $ff;
       If Y <> 0 Then P := P and $fd else P := P or $02;
       If Y and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $8a:Begin                      { TXA (1 octet); }
      A := X and $ff;
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $8c:                           { STY abs }
      memStoreByte( popWord, Y );
    $8d:                           { STA ABS (3 octets) }
      memStoreByte( popWord, A );
    $8e:                           { STX abs }
      memStoreByte( popWord, X );
    $90:Begin                      { BCC (branchement dans l'effacement de retenue) }
       offset := popByte;
       If P and 1 = 0 Then jumpBranch( offset );
      End;
    $91:Begin                      { STA INDY }
       zp := popByte;
       address := memReadByte(zp) + (memReadByte(zp + 1) shl 8) + Y;
       memStoreByte(address, A);
      End;
    $94:                           { STY ZPX }
      memStoreByte( popByte + X, Y );
    $95:                           { STA ZPX }
      memStoreByte( popByte + X, A );
    $96:                           { STX ZPY }
      memStoreByte( popByte + Y, X );
    $98:Begin                      { TYA }
       A := Y and $ff;
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $99:                           { STA ABSY }
      memStoreByte( popWord + Y, A );
    $9a:                           { TXS }
      SP := X and $ff;
    $9d:Begin                      { STA ABSX }
       address := popWord;
       memStoreByte(address + X, A);
      End;
    $a0:Begin                      { LDY IMM }
       Y := popByte;
       If Y <> 0 Then P := P and $fd else P := P or $02;
       If Y and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $a1:Begin                      { LDA INDX }
       zp := (popByte + X) and $ff;
       address := memReadByte(zp) + (memReadByte(zp + 1) shl 8);
       A := memReadByte(address);
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $a2:Begin                      { LDX IMM }
       X := popByte;
       If X <> 0 Then P := P and $fd else P := P or $02;
       If X and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $a4:Begin                      { LDY ZP }
      Y := memReadByte(popByte);
      If Y <> 0 Then P := P and $fd else P := P or $02;
      If Y and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $a5:Begin                      { LDA ZP }
       A := memReadByte(popByte);
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $a6:Begin                      { LDX ZP }
       X := memReadByte(popByte);
       If X <> 0 Then P := P and $fd else P := P or $02;
       If X and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $a8:Begin                      { TAY }
       Y := A and $ff;
       If Y <> 0 Then P := P and $fd else P := P or $02;
       If Y and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $a9:Begin                      { LDA IMM }
       A := popByte;
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $aa:Begin                      { TAX }
       X := A and $ff;
       If X <> 0 Then P := P and $fd else P := P or $02;
       If X and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $ac:Begin                      { LDY ABS }
       Y := memReadByte(popWord);
       If Y <> 0 Then P := P and $fd else P := P or $02;
       If Y and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $ad:Begin                      { LDA ABS }
       A := memReadByte(popWord);
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $ae:Begin                      { LDX ABS }
       X := memReadByte(popWord);
       If X <> 0 Then P := P and $fd else P := P or $02;
       If X and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $b0:Begin                      { BCS }
       offset := popByte;
       If P and 1 = 1 Then jumpBranch(offset);
      End;
    $b1:Begin                      { LDA INDY }
       zp := popByte;
       address := memReadByte(zp) + (memReadByte(zp+1) shl 8) + Y;
       A := memReadByte(address);
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $b4:Begin                      { LDY ZPX }
       Y := memReadByte(popByte + X);
       If Y <> 0 Then P := P and $fd else P := P or $02;
       If Y = Y and $80 Then P := P or $80 else P := P and $7f;
      End;
    $b5:Begin                      { LDA ZPX }
       A := memReadByte((popByte + X) and $ff);
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $b6:Begin                      { LDX ZPY }
       X := memReadByte(popByte + Y);
       If X <> 0 Then P := P and $fd else P := P or $02;
       If X and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $b8:                          { CLV }
      P := P and $bf;
    $b9:Begin                     { LDA ABSY }
       address := popWord + Y;
       A := memReadByte(address);
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $ba:                          { TSX }
      X := SP and $ff;
    $bc:Begin                     { LDY ABSX }
       address := popWord + X;
       Y := memReadByte(address);
       If Y <> 0 Then P := P and $fd else P := P or $02;
       If Y and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $bd:Begin                     { LDA ABSX }
       address := popWord + X;
       A := memReadByte(address);
       If A <> 0 Then P := P and $fd else P := P or $02;
       If A and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $be:Begin                     { LDX ABSY }
       address := popWord + Y;
       X := memReadByte(address);
       If X <> 0 Then P := P and $fd else P := P or $02;
       If X and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $c0:Begin                     { CPY IMM }
       value := popByte;
       If Y + value > $ff Then P := P or 1 else P := P and $fe;
       value := Y-value;
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $c1:Begin                     { CMP INDY }
       zp := popByte;
       address := memReadByte(zp) + (memReadByte(zp + 1) shl 8) + Y;
       value := memReadByte(address);
       doCompare(A, value);
      End;
    $c4:Begin                     { CPY ZP }
       value := memReadByte(popByte);
       doCompare(Y, value);
      End;
    $c5:Begin                     { CMP ZP }
       value := memReadByte(popByte);
       doCompare(A, value);
      End;
    $c6:Begin                     { DEC ZP }
       zp := popByte;
       value := memReadByte(zp);
       value := value - 1;
       memStoreByte( zp, value and $ff );
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $c8:Begin                     { INY }
       Y := (Y + 1) and $ff;
       If Y <> 0 Then P := P and $fd else P := P or $02;
       If Y and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $c9:Begin                     { CMP IMM }
      value := popByte;
      doCompare( A, value );
      End;
    $ca:Begin                     { DEX }
       X := (X - 1) and $ff;
       If X <> 0 Then P := P and $fd else P := P or $02;
       If X and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $cc:Begin                     { CPY ABS }
       value := memReadByte(popWord);
       doCompare(Y, value);
      End;
    $cd:Begin                     { CMP ABS }
       value := memReadByte(popWord);
       doCompare(A, value);
      End;
    $ce:Begin                     { DEC ABS }
       address := popWord;
       value := memReadByte( address );
       value := value - 1;
       value := value and $ff;
       memStoreByte( address, value );
       If value <> 0 Then P := P and $fd else P := P  or $02;
       If value and $80 = $80 Then P := P or $80 Else P := P and $7f;
      End;
    $d0:Begin                     { BNE }
       offset := popByte;
       If P and 2 = 0 Then jumpBranch( offset );
      End;
    $d1:Begin                     { CMP INDY }
       zp := popByte;
       address := memReadByte(zp) + (memReadByte(zp + 1) shl 8) + Y;
       value := memReadByte(address);
       doCompare(A, value );
      End;
    $d5:Begin                     { CMP ZPX }
       value := memReadByte( popByte + X );
       doCompare(A, value);
      End;
    $d6:Begin                     { DEC ZPX }
       address := popByte + X;
       value := memReadByte(address);
       value := value - 1;
       value := value and $ff;
       memStoreByte( address, value );
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $d8:                          { CLD (CLear Decimal) }
      P := P and $f7;
    $d9:Begin                     { CMP ABSY }
       address := popWord + Y;
       value := memReadByte(address);
       doCompare(A, value);
      End;
    $dd:Begin                     { CMP ABSX }
       address := popWord + X;
       value := memReadByte(address);
       doCompare(A,value);
      End;
    $de:Begin                     { DEC ABSX }
       address := popWord + X;
       value := memReadByte(address);
       value := value - 1;
       value := value and $ff;
       memStoreByte( address, value );
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value = value and $80 Then P := P or $80 else P := P and $7f;
      End;
    $e0:Begin                     { CPX IMM }
       value := popByte;
       doCompare( X, value );
      End;
    $e1:Begin                     { SBC INDX }
       zp := (popByte+X) and $ff;
       address := memReadByte(zp) + (memReadByte(zp+1) shl 8);
       value := memReadByte(address);
       testSBC(value);
      End;
    $e4:Begin                     { CPX ZP }
       value := memReadByte(popByte);
       doCompare( X, value );
      End;
    $e5:Begin                     { SBC ZP }
       address := popByte;
       value := memReadByte(address);
       testSBC(value);
      End;
    $e6:Begin                     { INC ZP }
       zp := popByte;
       value := memReadByte(zp);
       value := value + 1;
       value := value and $ff;
       memStoreByte(zp, value);
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $e8:Begin                     { INX }
       X := (X + 1) and $ff;
       if X <> 0 Then P := P and $fd else P := P or $02;
       if X and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $e9:Begin                     { SBC IMM }
       value := popByte;
       testSBC(value);
      End;
    $ea:;                        { NOP }
    $ec:Begin                    { CPX ABS }
       value := memReadByte(popWord);
       doCompare(X, value);
      End;
    $ed:Begin                    { SBC ABS }
       address := popWord;
       value := memReadByte( address );
       testSBC(value);
      End;
    $ee:Begin                    { INC ABS }
       address := popWord;
       value := memReadByte(address);
       value := value + 1;
       value := value and $ff;
       memStoreByte(address, value);
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $f0:Begin                     { BEQ }
       offset := popByte;
       If P and 2 = 2 Then jumpBranch(offset);
      End;
    $f1:Begin                     { SBC INDY }
       zp := popByte;
       address := memReadByte(zp) + (memReadByte(zp+1) shl 8);
       value := memReadByte( address + Y );
       testSBC( value );
      End;
    $f5:Begin                     { SBC ZPX }
       address := (popByte + X) and $ff;
       value := memReadByte( address );
       P := (P and $fe) or (value and 1);
       testSBC(value);
      End;
    $f6:Begin                     { INC ZPX }
       address := popByte + X;
       value := memReadByte(address);
       value := value + 1;
       value := value and $ff;
       memStoreByte(address, value);
       If value <> 0 Then P := P and $fd else P := P or $02;
       If value and $80 = $80 Then P := P or $80 else P := P and $7f;
      End;
    $f8:                         { SED }
      P := P or 8;
    $f9:Begin                    { SBC ABSY }
       address := popWord;
       value := memReadByte(address + Y);
       testSBC(value);
      End;
    $fd:Begin                    { SBC ABSX }
       address := popWord;
       value := memReadByte(address + X);
       testSBC(value);
      End;
    $fe:Begin                    { INC ABSX }
      address := popWord + X;
      value := memReadByte(address);
      value := value + 1;
      value := value and $ff;
      memStoreByte(address, value);
      If value <> 0 Then P := P and $fd else P := P or $02;
      If value and $80 = $80 Then P := P or $80 else P := P and $7f;
     End;
     Else Begin
      WriteLn('Adresse $', addr2hex(PC), ' - code inconnu ', opcode);
      codeRunning := False;
     End;
  End;

  If (PC = 0) or (Not codeRunning) Then Begin
    WriteLn('Programme termin‚ … PC=$', addr2hex(PC-1));
    codeRunning := False;
  End;
End;

Var
 I,ByteReaded:Integer;
 FileLoad:File {$IFDEF FPC}of Byte{$ENDIF};

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('RUN6502 : Cette commande permet d''executer du code du microprocesseur 6502.');
  WriteLn;
  WriteLn('Syntaxe : RUN6502 [nomdufichier.bin] [/HARDWARE:APPLEII] [/DEBUG] [/VERBOSE]');
 End
  Else
 Begin
  FillChar(memory,SizeOf(memory),0);
  Verbose:=False;
  DebugOn:=False;
  Hardware:=NoHardware;
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='/DEBUG'Then DebugOn:=True Else
   If(ParamStr(I)='/VERBOSE')or(ParamStr(I)='/V')Then Verbose:=True Else
   If ParamStr(I)='/HARDWARE:APPLEII'Then Hardware:=AppleII Else
   If ParamStr(I)='/HARDWARE:COMMODORE64'Then Hardware:=Commodore64
    Else
   Begin
    If(Verbose)Then WriteLn('Chargement du fichier binaire ',ParamStr(I),' dans la RAM du 6502.');
    Assign(FileLoad,ParamStr(I));
    Reset(FileLoad);
    Seek(FileLoad,0);
    BlockRead(FileLoad,Memory[$600],SizeOf(Memory)-$600,ByteReaded);
    Close(FileLoad);
   End;
  End;
  If(Verbose)Then WriteLn('Initialisation de l''emulateur');
  InitEmul;
  If(Verbose)Then WriteLn('Lancement de l''emulation');
  Repeat
   ExecEmul;
  Until Not codeRunning;
 End;
END.
