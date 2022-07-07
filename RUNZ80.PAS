{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program RUNZ80;

Const
 FlagsC=1;
 FlagsN=2;
 FlagsPV=4;
 Flags3=8;
 FlagsH=16;
 Flags5=32;
 FlagsZ=64;
 FlagsS=128;

 CpuPaused:boolean=False;

Var
 DebugOn,Verbose:Boolean;
 InterruptCounter:Integer;
 Parity:Array[0..256] of Boolean;
 Reg:Record
  A,HL,B,C,DE:Integer;
 End;
 Flags:Record { Drapeau Z80 }
  S:Boolean;
  Zero:Boolean;
  f5:Boolean;
  H:Boolean;
  f3:Boolean;
  PV:Boolean;
  N:Boolean;
  Carry:Boolean;
 End;
 regAF_,regHL_,regBC_,regDE_,regIX,regIY,regID:Integer;
 regSP,regPC,prevPC:Word;

 intI:Integer;
 intR:Integer;
 intRTemp:Word;
 intIFF1,intIFF2:Boolean;
 intIM:Integer;

 memory:Array[0..16384] of Byte;

Function memReadByte(address:Word):Byte;Begin
 If address<0Then memReadByte:=0 Else
 If address<High(Memory)Then memReadByte:=Memory[address]
                        Else memReadByte:=0;
End;

Function memReadWord(address:Word):Word;Begin
 memReadWord:=memReadByte(address)or (memReadByte(address+1) shl 8);
End;

Procedure memStoreByte(address:Word;Const Value:Byte);Begin
 If address<0Then Exit;
 If address<High(Memory)Then Memory[address]:=Value;
End;

Procedure memStoreWord(address:Word;Const Value:Word);Begin
 memStoreByte(address,Value And $FF);
 memStoreByte(address+1,(Value And $FF00) shr 8);
End;

Function inb(port:integer):Integer;Begin
 inb:=0;
End;

Procedure outb(port:Integer;outbyte:integer);Begin
End;

Procedure AdcA(B:Integer);
Var
 wans,ans,c:Integer;
Begin
 If Flags.Carry Then c:=1
                Else c:=0;
 wans:=Reg.A+b+c;
 ans:=wans and $FF;
 Flags.S:=(ans And FlagsS)<>0;
 Flags.f3:=(ans And Flags3)<>0;
 Flags.f5:=(ans And Flags5)<>0;
 Flags.Zero:=(ans = 0);
 Flags.Carry:=(wans And $100)<>0;
 Flags.PV:=((Reg.A Xor ((Not b) And $FFFF)) And (Reg.A Xor ans) And $80)<>0;
 Flags.H:=(((Reg.A And $F) + (b And $F) + c) And FlagsH)<>0;
 Flags.N:=False;
 Reg.A:=ans;
End;

Function Adc16(A,B:Integer):Integer;
Var
 c,lans,ans:Integer;
Begin
 If Flags.Carry Then c:=1
                Else c:=0;
 lans:=a+b+c;
 ans:=lans And $FFFF;
 Flags.S:=(ans And (FlagsS shl 8))<>0;
 Flags.f3:=(ans And (Flags3 shl 8))<>0;
 Flags.f5:=(ans And (Flags5 shl 8))<>0;
 Flags.Zero:=(ans=0);
 Flags.Carry:=(lans And $10000)<>0;
 Flags.PV:=((a Xor ((Not b) And $FFFF)) And (a Xor ans) And $8000)<>0;
 Flags.H:=(((a And $FFF) + (b And $FFF) + c) And $1000) <> 0;
 Flags.N:=False;
 Adc16:=ans;
End;

Procedure AddA(B:Integer);
Var
 wans,ans:Integer;
Begin
 wans:=Reg.A+b;
 ans:=wans And $FF;
 Flags.S:=(ans And FlagsS)<>0;
 Flags.f3:=(ans And Flags3)<>0;
 Flags.f5:=(ans And Flags5)<>0;
 Flags.Zero:=(ans=0);
 Flags.Carry:=(wans And $100) <> 0;
 Flags.PV:=((Reg.A Xor ((Not (b)) And $FFFF)) And (Reg.A Xor ans) And $80)<>0;
 Flags.H:=(((Reg.A And $F)+(b And $F)) And FlagsH)<>0;
 Flags.N:=False;
 Reg.A:=ans;
End;

Function Add16(A,B:Integer):Integer;
Var
 lans,ans:Integer;
Begin
 lans:=A+B;
 ans:=lans And $FFFF;
 Flags.f3:=(ans And (Flags3 shl 8))<>0;
 Flags.f5:=(ans And (Flags5 shl 8))<>0;
 Flags.Carry:=(lans And $10000)<>0;
 Flags.H:=(((a And $FFF)+(b And $FFF)) And $1000)<>0;
 Flags.N:=False;
 Add16:=ans;
End;

Procedure AndA(b:Integer);Begin
 Reg.A:=(Reg.A And b);
 Flags.S:=(Reg.A And FlagsS)<>0;
 Flags.f3:=(Reg.A And Flags3)<>0;
 Flags.f5:=(Reg.A And Flags5)<>0;
 Flags.H:=True;
 Flags.PV:=Parity[Reg.A];
 Flags.Zero:=(Reg.A=0);
 Flags.N:=False;
 Flags.Carry:=False;
End;

Procedure Bit(b,r:Integer);
Var
 IsbitSet:Boolean;
Begin
 IsbitSet:=(r And b)<>0;
 Flags.N:=False;
 Flags.H:=True;
 Flags.S:=IsbitSet And(b=FlagsS);
 Flags.f3:=(r and Flags3)<>0;
 Flags.f5:=(r and Flags5)<>0;
 Flags.Zero:=Not IsbitSet;
 Flags.PV:=Flags.Zero;
End;

Procedure BitHL(b,r:Integer);
Var
 IsbitSet:Boolean;
 rr:Integer;
Begin
 IsbitSet:=(r And b) <> 0;
 Flags.N:=False;
 Flags.H:=True;
 Flags.S:=IsbitSet And (b=FlagsS);
 rr:=(Reg.HL shr 8) and $FF;
 Flags.f3:=(rr and Flags3)<>0;
 Flags.f5:=(rr and Flags5)<>0;
 Flags.Zero:=Not IsbitSet;
 Flags.PV:=Flags.Zero;
End;

Procedure BitID(b,r,id:Integer);
Var
 IsbitSet:Boolean;
Begin
 IsbitSet:=(r And b)<>0;
 Flags.N:=False;
 Flags.H:=True;
 Flags.S:=IsbitSet And (b = FlagsS);
 Flags.f3:=((id shr 8) and Flags3) <> 0;
 Flags.f5:=((id shr 8) and Flags5) <> 0;
 Flags.Zero:=Not IsbitSet;
 Flags.PV:=Flags.Zero;
End;

Function BitRes(Bit,Val:Integer):Integer;Begin
 BitRes:=Val And (Bit Xor $FFFF);
end;

Function BitSet(bit,val:Integer):Integer;Begin
 BitSet:=val Or bit;
End;

Procedure CpA(b:Integer);
Var
 a,wans,ans:Integer;
Begin
 a:=Reg.A;
 wans:=a-b;
 ans:=wans and $FF;
 Flags.S:=(ans and FlagsS)<>0;
 Flags.f3:=(b and Flags3)<>0;
 Flags.f5:=(b and Flags5)<>0;
 Flags.N:=True;
 Flags.Zero:=(ans = 0);
 Flags.Carry:=(wans And $100)<>0;
 Flags.H:=(((a and $F) - (b and $F)) And FlagsH)<>0;
 Flags.PV:=((a xor b) and (a xor ans) And $80)<>0;
End;

Procedure SubA(b:Integer);
Var
 a,wans,ans:Integer;
Begin
 a:=Reg.A;
 wans:=a-b;
 ans:=wans and $FF;
 Flags.S:=(ans and FlagsS)<>0;
 Flags.f3:=(ans and Flags3)<>0;
 Flags.f5:=(ans and Flags5)<>0;
 Flags.Zero:=(ans=0);
 Flags.Carry:=(wans and $100)<>0;
 Flags.PV:=((a xor b) and (a xor ans) and $80) <> 0;
 Flags.H:=(((a and $F) - (b and $F)) and FlagsH) <> 0;
 Flags.N:=True;
 Reg.A:=ans;
End;

Procedure DaaA;
Var
 ans,incr:Integer;
 Carry:Boolean;
Begin
 incr:=0;
 ans:=Reg.A;
 Carry:=Flags.Carry;
 If(Flags.H)Or((ans And $F)>$9)Then Incr:=Incr Or $6;
 If(Carry)Or(ans>$9F)Then Incr:=Incr Or $60;
 If((ans>$8F)And((ans And $F) > 9))Then Incr:=Incr Or $60;
 If(ans>$99)Then Carry:=True;
 If(Flags.N)Then SubA(incr)
            Else AddA(incr);
 ans:=Reg.A;
 Flags.Carry:=Carry;
 Flags.PV:=Parity[ans];
End;

Function Dec16(a:Integer):Integer;Begin
 Dec16:=(a-1)and $FFFF;
End;

Function rlc(ans:Integer):Integer;
Var
 c:Boolean;
Begin
 c:=(ans And $80)<>0;
 If c Then ans:=(ans shl 1)or $1
      Else ans:=ans shl 1;
 ans:=ans And $FF;
 Flags.S:=(ans And FlagsS)<>0;
 Flags.f3:=(ans And Flags3)<>0;
 Flags.f5:=(ans And Flags5)<>0;
 Flags.Zero:=(ans = 0);
 Flags.PV:=Parity[ans];
 Flags.H:=False;
 Flags.N:=False;
 Flags.Carry:=c;
 rlc:=ans;
End;

Function NextPcb:Word;Begin
 NextPcb:=memReadByte(regPC);
 regPC:=regPC+1;
End;

Procedure setD(l:Integer);Begin
 Reg.DE:=(l shl 8)Or(Reg.DE And $FF);
End;

Function GetD:Integer;Begin
 getD:=Reg.DE shr 8;
End;

Procedure SetE(l:Integer);Begin
 Reg.DE:=(Reg.DE And $FF00) Or l;
End;

Function GetE:Integer;Begin
 getE:=Reg.DE And $FF;
End;

Procedure SetF(b:Integer);Begin
 Flags.S:=(b And FlagsS)<>0;
 Flags.Zero:=(b And FlagsZ)<>0;
 Flags.f5:=(b And Flags5)<>0;
 Flags.H:=(b And FlagsH)<>0;
 Flags.f3:=(b And Flags3)<>0;
 Flags.PV:=(b And FlagsPV)<>0;
 Flags.N:=(b And FlagsN)<>0;
 Flags.Carry:=(b And FlagsC)<>0;
End;

Procedure SetH(l:Integer);Begin
 Reg.HL:=(l shl 8)Or(Reg.HL And $FF);
End;

Procedure SetL(l:Integer);Begin
 Reg.HL:=(Reg.HL and $FF00)or l;
End;

Function GetF:Integer;
Var
 res:Integer;
Begin
 res:=0;
 If Flags.S Then res:=res+FlagsS;
 If Flags.Zero Then res:=res+FlagsZ;
 If Flags.f5 Then res:=res+Flags5;
 If Flags.H Then res:=res+FlagsH;
 If Flags.f3 Then res:=res+Flags3;
 If Flags.PV Then res:=res+FlagsPV;
 If Flags.N Then res:=res+FlagsN;
 If Flags.Carry Then res:=res+FlagsC;
 GetF:=res;
End;

Function GetAF:Integer;Begin
 GetAF:=(Reg.A shl 8)or getF;
End;

Function GetBC:Integer;Begin
 GetBC:=(Reg.B shl 8)or Reg.C;
End;

Function GetIR:Integer;Begin
 GetIR:=(intI shl 8) Or intR;
End;

Function GetH:Integer;Begin
 GetH:=Reg.HL shr 8;
End;

Function GetIDH:Integer;Begin
 GetIDH:=(regID shr 8) and $FF;
End;

Function GetIDL:Integer;Begin
 GetIDL:=regID and $FF;
End;

Function GetL:Integer;Begin
 GetL:=Reg.HL and $FF;
End;

Procedure RRCA;
Var
 Carry:Boolean;
Begin
 Carry:=(Reg.A And $1)<>0;
 If Carry Then Reg.A:=(Reg.A shr 1)or $80
          Else Reg.A:=Reg.A shr 1;
 Flags.f3:=(Reg.A And Flags3)<>0;
 Flags.f5:=(Reg.A And Flags5)<>0;
 Flags.N:=False;
 Flags.H:=False;
 Flags.Carry:=Carry;
End;

Function rl(ans:Integer):Integer;
Var
 c:Boolean;
Begin
 c:=(ans And $80) <> 0;
 If Flags.Carry Then ans:=(ans shl 1) or $1
                Else ans:=ans shl 1;
 ans:=ans And $FF;
 Flags.S:=(ans And FlagsS)<>0;
 Flags.f3:=(ans And Flags3)<>0;
 Flags.f5:=(ans And Flags5)<>0;
 Flags.Zero:=(ans = 0);
 Flags.PV:=Parity[ans];
 Flags.H:=False;
 Flags.N:=False;
 Flags.Carry:=c;
 rl:=ans;
End;

Procedure RLA;
Var
 ans:Integer;
 Carry:Boolean;
Begin
 ans:=Reg.A;
 Carry:=(ans And $80)<>0;
 If Flags.Carry Then ans:=(ans shl 1)or $1
                Else ans:=(ans shl 1);
 ans:=ans And $FF;
 Flags.f3:=(ans And Flags3)<>0;
 Flags.f5:=(ans And Flags5)<>0;
 Flags.N:=False;
 Flags.H:=False;
 Flags.Carry:=Carry;
 Reg.A:=ans;
End;

Procedure RLCA;
Var
 Carry:Boolean;
Begin
 Carry:=(Reg.A And $80)<>0;
 If Carry Then Reg.A:=(Reg.A shl 1)or 1
          Else Reg.A:=(Reg.A shl 1);
 Reg.A:=Reg.A And $FF;
 Flags.f3:=(Reg.A And Flags3)<>0;
 Flags.f5:=(Reg.A And Flags5)<>0;
 Flags.N:=False;
 Flags.H:=False;
 Flags.Carry:=Carry;
End;

Function rr(ans:Integer):Integer;
Var
 c:Boolean;
Begin
 c:=(ans And $1)<>0;
 If Flags.Carry Then ans:=(ans shr 1) Or $80
                Else ans:=(ans shr 1);
 Flags.S:=(ans And FlagsS)<>0;
 Flags.f3:=(ans And Flags3)<>0;
 Flags.f5:=(ans And Flags5)<>0;
 Flags.Zero:=(ans = 0);
 Flags.PV:=Parity[ans];
 Flags.H:=False;
 Flags.N:=False;
 Flags.Carry:=c;
 rr:=ans;
End;

Procedure RRA;
Var
 ans:Integer;
 Carry:Boolean;
Begin
 ans:=Reg.A;
 Carry:=(ans And $1)<>0;
 If Flags.Carry Then ans:=(ans shr 1) Or $80
                Else ans:=(ans shr 1);
 Flags.f3:=(ans And Flags3) <> 0;
 Flags.f5:=(ans And Flags5) <> 0;
 Flags.N:=False;
 Flags.H:=False;
 Flags.Carry:=Carry;
 Reg.A:=ans;
End;

Function rrc(ans:Integer):Integer;
Var
 c:Boolean;
Begin
 c:=(ans And $1)<>0;
 If c Then ans:=(ans shr 1)or $80
      Else ans:=(ans shr 1);
 Flags.S:=(ans And FlagsS)<>0;
 Flags.f3:=(ans And Flags3)<>0;
 Flags.f5:=(ans And Flags5)<>0;
 Flags.Zero:=(ans = 0);
 Flags.PV:=Parity[ans];
 Flags.H:=False;
 Flags.N:=False;
 Flags.Carry:=c;
 rrc:=ans;
End;

Procedure RRD;
Var
 ans,t,q:Integer;
Begin
 ans:=Reg.A;
 t:=memReadByte(Reg.HL);
 q:=t;
 t:=(t shr 4)or(ans * 16);
 ans:=(ans And $F0)or(q And $F);
 memStoreByte(Reg.HL,t);
 Flags.S:=(ans And FlagsS)<>0;
 Flags.f3:=(ans And Flags3)<>0;
 Flags.f5:=(ans And Flags5)<>0;
 Flags.Zero:=(ans = 0);
 Flags.PV:=Parity[ans];
 Flags.H:=False;
 Flags.N:=False;
 Reg.A:=ans;
End;

Procedure SbcA(b:Integer);
Var
 a,wans,ans,c:integer;
Begin
 a:=Reg.A;
 If Flags.Carry Then c:=1
                Else c:=0;
 wans:=a-b-c;
 ans:=wans And $FF;
 Flags.S:=(ans And FlagsS)<>0;
 Flags.f3:=(ans And Flags3)<>0;
 Flags.f5:=(ans And Flags5)<>0;
 Flags.Zero:=(ans = 0);
 Flags.Carry:=(wans And $100) <> 0;
 Flags.PV:=((a Xor b) And (a Xor ans) And $80)<>0;
 Flags.H:=(((a And $F)-(b And $F)-c) And FlagsH)<>0;
 Flags.N:=True;
 Reg.A:=ans;
End;

Function sbc16(a,b:Integer):Integer;
Var
 c,lans,ans:Integer;
Begin
 If Flags.Carry Then c:=1
                Else c:=0;
 lans:=a-b-c;
 ans:=lans And $FFFF;
 Flags.S:=(ans And (FlagsS shl 8)) <> 0;
 Flags.f3:=(ans And (Flags3 shl 8)) <> 0;
 Flags.f5:=(ans And (Flags5 shl 8)) <> 0;
 Flags.Zero:=(ans = 0);
 Flags.Carry:=(lans And $10000) <> 0;
 Flags.PV:=((a Xor b) And (a Xor ans) And $8000) <> 0;
 Flags.H:=(((a And $FFF) - (b And $FFF) - c) And $1000) <> 0;
 Flags.N:=True;
 sbc16:=ans;
End;

Procedure SetAF(v:Integer);Begin
 Reg.A:=(v And $FF00) shr 8;
 setF(v And $FF);
End;

Procedure SetBC(nn:Integer);Begin
 Reg.B:=(nn And $FF00) shr 8;
 Reg.C:=nn And $FF;
End;

Function Inc16(a:Integer):Integer;Begin
 inc16:=(a+1) And $FFFF;
End;

Procedure ExAfAf;
Var
 T:Integer;
Begin
 T:=GetAF;
 SetAF(regAF_);
 regAF_:=T;
End;

Function NextPcw:Word;Begin
 NextPcw:=memReadByte(regPC)+(memReadByte(regPC+1) shl 8);
 regPC:=regPC+2;
End;

Function sla(ans:Integer):Integer;
Var
 c:Boolean;
Begin
 c:=(ans And $80) <> 0;
 ans:=(ans shl 1) And $FF;
 Flags.S:=(ans And FlagsS)<>0;
 Flags.f3:=(ans And Flags3)<>0;
 Flags.f5:=(ans And Flags5)<>0;
 Flags.Zero:=(ans = 0);
 Flags.PV:=Parity[ans];
 Flags.H:=False;
 Flags.N:=False;
 Flags.Carry:=c;
 sla:=ans;
End;

Function sls(ans:Integer):Integer;
Var
 c:Boolean;
Begin
 c:=(ans And $80)<>0;
 ans:=((ans * 2)or $1) And $FF;
 Flags.S:=(ans And FlagsS)<>0;
 Flags.f3:=(ans And Flags3)<>0;
 Flags.f5:=(ans And Flags5)<>0;
 Flags.Zero:=(ans = 0);
 Flags.PV:=Parity[ans];
 Flags.H:=False;
 Flags.N:=False;
 Flags.Carry:=c;
 sls:=ans;
End;

Function sra(ans:integer):Integer;
Var
 c:Boolean;
Begin
 c:=(ans And $1)<>0;
 ans:=(ans shr 1)or(ans And $80);
 Flags.S:=(ans And FlagsS)<>0;
 Flags.f3:=(ans And Flags3)<>0;
 Flags.f5:=(ans And Flags5)<>0;
 Flags.Zero:=(ans = 0);
 Flags.PV:=Parity[ans];
 Flags.H:=False;
 Flags.N:=False;
 Flags.Carry:=c;
 sra:=ans;
End;

Function srl(ans:Integer):Integer;
Var
 c:Boolean;
Begin
 c:=(ans and $1)<>0;
 ans:=ans shr 1;
 Flags.S:=(ans And FlagsS)<>0;
 Flags.f3:=(ans And Flags3)<>0;
 Flags.f5:=(ans And Flags5)<>0;
 Flags.Zero:=(ans=0);
 Flags.PV:=Parity[ans];
 Flags.H:=False;
 Flags.N:=False;
 Flags.Carry:=c;
 srl:=Ans;
End;

Procedure XorA(b:Integer);Begin
 Reg.A:=(Reg.A Xor b) And $FF;
 Flags.S:=(Reg.A And FlagsS)<>0;
 Flags.f3:=(Reg.A And Flags3)<>0;
 Flags.f5:=(Reg.A And Flags5)<>0;
 Flags.H:=False;
 Flags.PV:=Parity[Reg.A];
 Flags.Zero:=(Reg.A=0);
 Flags.N:=False;
 Flags.Carry:=False;
End;

Procedure ExecCB;Begin
 intRTemp:=intRTemp+1;
 Case NextPcb of
  $00:Reg.B:=rlc(Reg.B); { RLC B }
  $01:Reg.C:=rlc(Reg.C); { RLC C }
  $02:setD(rlc(getD)); { RLC D }
  $03:setE(rlc(getE)); { RLC E }
  $04:setH(rlc(getH)); { RLC H}
  $05:setL(rlc(getL)); { RLC L }
  $06:memStoreByte(Reg.HL,rlc(memReadByte(Reg.HL))); { RLC (HL) }
  $07:Reg.A:=rlc(Reg.A); { RLC A }
  $08:Reg.B:=rrc(Reg.B); { RRC B }
  $09:Reg.C:=rrc(Reg.C); { RRC C }
  $0A:setD(rrc(getD)); { RRC D }
  $0B:setE(rrc(getE)); { RRC E }
  $0C:setH(rrc(getH)); { RRC H }
  $0D:setL(rrc(getL)); { RRC L }
  $0E:memStoreByte(Reg.HL,rrc(memReadByte(Reg.HL))); { RRC (HL) }
  $0F:Reg.A:=rrc(Reg.A); { RRC A }
  $10:Reg.B:=rl(Reg.B); { RL B }
  $11:Reg.C:=rl(Reg.C); { RL C }
  $12:setD(rl(getD)); { RL D }
  $13:setE(rl(getE)); { RL E }
  $14:setH(rl(getH)); { RL H }
  $15:setL(rl(getL)); { RL L }
  $16:memStoreByte(Reg.HL,rl(memReadByte(Reg.HL))); { RL (HL) }
  $17:Reg.A:=rl(Reg.A); { RL A }
  $18:Reg.B:=rr(Reg.B); { RR B }
  $19:Reg.C:=rr(Reg.C); { RR C }
  $1A:setD(rr(getD)); { RR D }
  $1B:setE(rr(getE)); { RR E }
  $1C:setH(rr(getH)); { RR H }
  $1D:setL(rr(getL)); { RR L }
  $1E:memStoreByte(Reg.HL,rr(memReadByte(Reg.HL))); { RR (HL) }
  $1F:Reg.A:=rr(Reg.A); { RR A }
  $20:Reg.B:=sla(Reg.B); { SLA B }
  $21:Reg.C:=sla(Reg.C); { SLA C }
  $22:setD(sla(getD)); { SLA D }
  $23:setE(sla(getE)); { SLA E }
  $24:setH(sla(getH)); { SLA H }
  $25:setL(sla(getL)); { SLA L }
  $26:memStoreByte(Reg.HL,sla(memReadByte(Reg.HL))); { SLA (HL) }
  $27:Reg.A:=sla(Reg.A); { SLA A }
  $28:Reg.B:=sra(Reg.B); { SRA B }
  $29:Reg.C:=sra(Reg.C); { SRA C }
  $2A:setD(sra(getD)); { SRA D }
  $2B:setE(sra(getE)); { SRA E }
  $2C:setH(sra(getH)); { SRA H }
  $2D:setL(sra(getL)); { SRA L }
  $2E:memStoreByte(Reg.HL, sra(memReadByte(Reg.HL))); { SRA (HL) }
  $2F:Reg.A:=sra(Reg.A); { SRA A }
  $30:Reg.B:=sls(Reg.B); { SLS B }
  $31:Reg.C:=sls(Reg.C); { SLS C }
  $32:setD(sls(getD)); { SLS D }
  $33:setE(sls(getE)); { SLS E }
  $34:setH(sls(getH)); { SLS H }
  $35:setL(sls(getL)); { SLS L }
  $36:memStoreByte(Reg.HL, sls(memReadByte(Reg.HL))); { SLS (HL) }
  $37:Reg.A:=sls(Reg.A); { SLS A }
  $38:Reg.B:=srl(Reg.B); { SRL B }
  $39:Reg.C:=srl(Reg.C); { SRL C }
  $3A:setD(srl(getD)); { SRL D }
  $3B:setE(srl(getE)); { SRL E }
  $3C:setH(srl(getH)); { SRL H }
  $3D:setL(srl(getL)); { SRL L }
  $3E:memStoreByte(Reg.HL,srl(memReadByte(Reg.HL))); { SRL (HL) }
  $3F:Reg.A:=srl(Reg.A); { SRL A }
  $40:Bit($1,Reg.B); { BIT 0,B }
  $41:Bit(1,Reg.C); { BIT 0,C }
  $42:Bit(1,getD); { BIT 0,D }
  $43:Bit(1,getE); { BIT 0,E }
  $44:Bit(1,getH); { BIT 0,H }
  $45:Bit(1,getL); { BIT 0,L }
  $46:BitHL(1,memReadByte(Reg.HL)); { BIT 0,(HL) }
  $47:Bit(1,Reg.A); { BIT 0,A }
  $48:Bit(2,Reg.B); { BIT 1,B }
  $49:Bit(2,Reg.C); { BIT 1,C }
  $4A:Bit(2,getD); { BIT 1,D }
  $4B:Bit(2,getE); { BIT 1,E }
  $4C:Bit(2,getH); { BIT 1,H }
  $4D:Bit(2,getL); { BIT 1,L }
  $4E:BitHL(2,memReadByte(Reg.HL)); { BIT 1,(HL) }
  $4F:Bit(2,Reg.A); { BIT 1,A }
  $50:Bit(4,Reg.B); { BIT 2,B }
  $51:Bit(4,Reg.C); { BIT 2,C }
  $52:Bit(4,GetD); { BIT 2,D }
  $53:Bit(4,GetE); { BIT 2,E }
  $54:Bit(4,GetH); { BIT 2,H }
  $55:Bit(4,GetL); { BIT 2,L }
  $56:BitHL(4,memReadByte(Reg.HL)); { BIT 2,(HL) }
  $57:Bit(4,Reg.A); { BIT 2,A }
  $58:Bit(8,Reg.B); { BIT 3,B }
  $59:Bit(8,Reg.C); { BIT 3,C }
  $5A:Bit(8,GetD); { BIT 3,D }
  $5B:Bit(8,GetE); { BIT 3,E }
  $5C:Bit(8,GetH); { BIT 3,H }
  $5D:Bit(8,GetL); { BIT 3,L }
  $5E:BitHL(8, memReadByte(Reg.HL)); { BIT 3,(HL) }
  $5F:Bit(8,Reg.A); { BIT 3,A }
  $60:Bit($10,Reg.B); { BIT 4,B }
  $61:Bit($10,Reg.C); { BIT 4,C }
  $62:Bit($10,GetD); { BIT 4,D }
  $63:Bit($10,GetE); { BIT 4,E }
  $64:Bit($10,GetH); { BIT 4,H }
  $65:Bit($10,GetL); { BIT 4,L }
  $66:BitHL($10,memReadByte(Reg.HL)); { BIT 4,(HL) }
  $67:Bit($10,Reg.A); { BIT 4,A }
  $68:Bit($20,Reg.B); { BIT 5,B }
  $69:Bit($20,Reg.C); { BIT 5,C }
  $6A:Bit($20,GetD); { BIT 5,D }
  $6B:Bit($20,GetE); { BIT 5,E }
  $6C:Bit($20,GetH); { BIT 5,H }
  $6D:Bit($20,GetL); { BIT 5,L }
  $6E:BitHL($20,memReadByte(Reg.HL)); { BIT 5,(HL) }
  $6F:Bit($20,Reg.A); { BIT 5,A }
  $70:Bit($40,Reg.B); { BIT 6,B }
  $71:Bit($40,Reg.C); { BIT 6,C }
  $72:Bit($40,getD); { BIT 6,D }
  $73:Bit($40,getE); { BIT 6,E }
  $74:Bit($40,getH); { BIT 6,H }
  $75:Bit($40, getL); { BIT 6,L }
  $76:BitHL($40,memReadByte(Reg.HL)); { BIT 6,(HL) }
  $77:Bit($40,Reg.A); { BIT 6,A }
  $78:Bit($80,Reg.B); { BIT 7,B }
  $79:Bit($80,Reg.C); { BIT 7,C }
  $7A:Bit($80,getD); { BIT 7,D }
  $7B:Bit($80,getE); { BIT 7,E }
  $7C:Bit($80, getH); { BIT 7,H }
  $7D:Bit($80, getL); { BIT 7,L }
  $7E:BitHL($80, memReadByte(Reg.HL)); { BIT 7,(HL) }
  $7F:Bit($80,Reg.A); { BIT 7,A }
  $80:Reg.B:=bitRes(1,Reg.B); { RES 0,B }
  $81:Reg.C:=bitRes(1,Reg.C); { RES 0,C }
  $82:SetD(bitRes(1,GetD)); { RES 0,D }
  $83:SetE(bitRes(1,GetE)); { RES 0,E }
  $84:SetH(bitRes(1,GetH)); { RES 0,H }
  $85:SetL(bitRes(1,GetL)); { RES 0,L }
  $86:memStoreByte(Reg.HL, bitRes($1, memReadByte(Reg.HL))); { RES 0,(HL) }
  $87:Reg.A:=bitRes(1,Reg.A); { RES 0,A }
  $88:Reg.B:=bitRes(2,Reg.B); { RES 1,B }
  $89:Reg.C:=bitRes(2,Reg.C); { RES 1,C }
  $8A:SetD(bitRes(2,GetD)); { RES 1,D }
  $8B:SetE(bitRes(2,GetE)); { RES 1,E }
  $8C:SetH(bitRes(2,GetH)); { RES 1,H }
  $8D:SetL(bitRes(2,GetL)); { RES 1,L }
  $8E:memStoreByte(Reg.HL,bitRes(2, memReadByte(Reg.HL))); { RES 1,(HL) }
  $8F:Reg.A:=bitRes(2,Reg.A); { RES 1,A }
  $90:Reg.B:=bitRes(4,Reg.B); { RES 2,B }
  $91:Reg.C:=bitRes(4,Reg.C); { RES 2,C }
  $92:SetD(bitRes(4,GetD)); { RES 2,D }
  $93:SetE(bitRes(4,GetE)); { RES 2,E }
  $94:SetH(bitRes(4,GetH)); { RES 2,H }
  $95:SetL(bitRes(4,GetL)); { RES 2,L }
  $96:memStoreByte(Reg.HL,bitRes(4,memReadByte(Reg.HL))); { RES 2,(HL) }
  $97:Reg.A:=bitRes(4,Reg.A); { RES 2,A }
  $98:Reg.B:=bitRes(8,Reg.B); { RES 3,B }
  $99:Reg.C:=bitRes(8,Reg.C); { RES 3,C }
  $9A:SetD(bitRes(8,GetD)); { RES 3,D }
  $9B:SetE(bitRes(8,GetE)); { RES 3,E }
  $9C:SetH(bitRes(8,GetH)); { RES 3,H }
  $9D:SetL(bitRes(8,GetL)); { RES 3,L }
  $9E:memStoreByte(Reg.HL,bitRes(8, memReadByte(Reg.HL))); { RES 3,(HL) }
  $9F:Reg.A:=bitRes(8,Reg.A); { RES 3,A }
  $A0:Reg.B:=bitRes($10,Reg.B); { RES 4,B }
  $A1:Reg.C:=bitRes($10,Reg.C); { RES 4,C }
  $A2:SetD(bitRes($10,getD)); { RES 4,D }
  $A3:SetE(bitRes($10,getE)); { RES 4,E }
  $A4:SetH(bitRes($10,getH)); { RES 4,H }
  $A5:SetL(bitRes($10,getL)); { RES 4,L }
  $A6:memStoreByte(Reg.HL,bitRes($10,memReadByte(Reg.HL))); { RES 4,(HL) }
  $A7:Reg.A:=bitRes($10,Reg.A); { RES 4,A }
  $A8:Reg.B:=bitRes($20,Reg.B); { RES 5,B }
  $A9:Reg.C:=bitRes($20,Reg.C); { RES 5,C }
  $AA:setD(bitRes($20,getD)); { RES 5,D }
  $AB:setE(bitRes($20,getE)); { RES 5,E }
  $AC:setH( bitRes($20,getH)); { RES 5,H }
  $AD:setL(bitRes($20,getL)); { RES 5,L }
  $AE:memStoreByte(Reg.HL,bitRes($20, memReadByte(Reg.HL))); { RES 5,(HL) }
  $AF:Reg.A:=bitRes($20,Reg.A); { RES 5,A }
  $B0:Reg.B:=bitRes($40,Reg.B); { RES 6,B }
  $B1:Reg.C:=bitRes($40,Reg.C); { RES 6,C }
  $B2:SetD(bitRes($40,getD)); { RES 6,D }
  $B3:SetE(bitRes($40,getE)); { RES 6,E }
  $B4:SetH(bitRes($40,getH)); { RES 6,H }
  $B5:SetL(bitRes($40,getL)); { RES 6,L }
  $B6:memStoreByte(Reg.HL,bitRes($40, memReadByte(Reg.HL))); { RES 6,(HL) }
  $B7:Reg.A:=bitRes($40,Reg.A); { RES 6,A }
  $B8:Reg.B:=bitRes($80,Reg.B); { RES 7,B }
  $B9:Reg.C:=bitRes($80,Reg.C); { RES 7,C }
  $BA:SetD(bitRes($80,getD)); { RES 7,D }
  $BB:SetE(bitRes($80,getE)); { RES 7,E }
  $BC:SetH(bitRes($80,getH)); { RES 7,H }
  $BD:SetL(bitRes($80,getL)); { RES 7,L }
  $BE:memStoreByte(Reg.HL,bitRes($80, memReadByte(Reg.HL))); { RES 7,(HL) }
  $BF:Reg.A:=bitRes($80,Reg.A); { RES 7,A }
  $C0:Reg.B:=bitSet(1,Reg.B); { SET 0,B }
  $C1:Reg.C:=bitSet(1,Reg.C); { SET 0,C}
  $C2:SetD(bitSet(1,getD)); { SET 0,D }
  $C3:SetE(bitSet(1,getE)); { SET 0,E }
  $C4:SetH(bitSet(1,getH)); { SET 0,H }
  $C5:SetL(bitSet(1,getL)); { SET 0,L }
  $C6:memStoreByte(Reg.HL,bitSet(1, memReadByte(Reg.HL))); { SET 0,(HL) }
  $C7:Reg.A:=bitSet(1,Reg.A); { SET 0,A }
  $C8:Reg.B:=bitSet(2,Reg.B); { SET 1,B }
  $C9:Reg.C:=bitSet(2,Reg.C); { SET 1,C }
  $CA:SetD(bitSet(2,getD)); { SET 1,D }
  $CB:SetE(bitSet(2,getE)); { SET 1,E }
  $CC:SetH(bitSet(2,getH)); { SET 1,H }
  $CD:SetL(bitSet(2,getL)); { SET 1,L }
  $CE:memStoreByte(Reg.HL,bitSet(2, memReadByte(Reg.HL))); { SET 1,(HL) }
  $CF:Reg.A:=bitSet(2,Reg.A); { SET 1,A }
  $D0:Reg.B:=bitSet(4,Reg.B); { SET 2,B }
  $D1:Reg.C:=bitSet(4,Reg.C); { SET 2,C }
  $D2:SetD(bitSet(4,getD)); { SET 2,D }
  $D3:SetE(bitSet(4,getE)); { SET 2,E }
  $D4:SetH(bitSet(4,getH)); { SET 2,H }
  $D5:SetL(bitSet(4,getL)); { SET 2,L }
  $D6:memStoreByte(Reg.HL,bitSet($4, memReadByte(Reg.HL))); { SET 2,(HL) }
  $D7:Reg.A:=bitSet(4,Reg.A); { SET 2,A }
  $D8:Reg.B:=bitSet(8,Reg.B); { SET 3,B }
  $D9:Reg.C:=bitSet(8,Reg.C); { SET 3,C }
  $DA:SetD(bitSet(8,getD)); { SET 3,D }
  $DB:SetE(bitSet(8,getE)); { SET 3,E }
  $DC:SetH(bitSet(8,getH)); { SET 3,H }
  $DD:SetL(bitSet(8,getL)); { SET 3,L }
  $DE:memStoreByte(Reg.HL,bitSet($8, memReadByte(Reg.HL))); { SET 3,(HL) }
  $DF:Reg.A:=bitSet(8,Reg.A); { SET 3,A }
  $E0:Reg.B:=bitSet($10,Reg.B); { SET 4,B }
  $E1:Reg.C:=bitSet($10,Reg.C); { SET 4,C }
  $E2:SetD(bitSet($10,getD)); { SET 4,D }
  $E3:SetE(bitSet($10,getE)); { SET 4,E }
  $E4:SetH(bitSet($10,getH)); { SET 4,H }
  $E5:SetL(bitSet($10,getL)); { SET 4,L }
  $E6:memStoreByte(Reg.HL,bitSet($10, memReadByte(Reg.HL))); { SET 4,(HL) }
  $E7:Reg.A:=bitSet($10,Reg.A); { SET 4,A }
  $E8:Reg.B:=bitSet($20,Reg.B); { SET 5,B }
  $E9:Reg.C:=bitSet($20,Reg.C); { SET 5,C }
  $EA:SetD(bitSet($20,getD)); { SET 5,D }
  $EB:SetE(bitSet($20,getE)); { SET 5,E }
  $EC:SetH(bitSet($20,getH));{ SET 5,H }
  $ED:SetL(bitSet($20,getL)); { SET 5,L }
  $EE:memStoreByte(Reg.HL,bitSet($20, memReadByte(Reg.HL))); { SET 5,(HL) }
  $EF:Reg.A:=bitSet($20,Reg.A); { SET 5,A }
  $F0:Reg.B:=bitSet($40,Reg.B); { SET 6,B }
  $F1:Reg.C:=bitSet($40,Reg.C); { SET 6,C }
  $F2:SetD(bitSet($40,getD)); { SET 6,D }
  $F3:SetE(bitSet($40,getE)); { SET 6,E }
  $F4:SetH(bitSet($40,getH)); { SET 6,H }
  $F5:SetL(bitSet($40,getL)); { SET 6,L }
  $F6:memStoreByte(Reg.HL,bitSet($40,memReadByte(Reg.HL))); { SET 6,(HL) }
  $F7:Reg.A:=bitSet($40,Reg.A); { SET 6,A }
  $F8:Reg.B:=bitSet($80,Reg.B); { SET 7,B }
  $F9:Reg.C:=bitSet($80,Reg.C); { SET 7,C }
  $FA:SetD(bitSet($80,getD)); { SET 7,D }
  $FB:SetE(bitSet($80,getE)); { SET 7,E }
  $FC:SetH(bitSet($80,getH)); { SET 7,H }
  $FD:SetL(bitSet($80, getL)); { SET 7,L}
  $FE:memStoreByte(Reg.HL,bitSet($80, memReadByte(Reg.HL))); { SET 7,(HL) }
  $FF:Reg.A:=bitSet($80,Reg.A); { SET 7,A }
  Else Begin
   WriteLn('Instruction CB inconnu ',memReadByte(regPC)+(memReadByte(regPC+1) shl 8),' a ',regPC);
  End;
 End;
End;

Procedure exx;
Var
 t:Integer;
Begin
 t:=Reg.HL;
 Reg.HL:=regHL_;
 regHL_:=t;
 t:=Reg.DE;
 Reg.DE:=regDE_;
 regDE_:=t;
 t:=getBC;
 setBC(regBC_);
 regBC_ := t;
End;

Function IdD:Integer;
Var
 d:integer;
Begin
 d:=NextPcb;
 If ((d And 128) = 128) Then d:=-(256-d);
 IdD:=(regID+d)and $FFFF;
End;

Procedure ld_a_i;Begin
 Flags.S:=(intI and FlagsS)<>0;
 Flags.f3:=(intI and Flags3)<>0;
 Flags.f5:=(intI and Flags5)<>0;
 Flags.Zero:=(intI=0);
 Flags.PV:=intIFF2;
 Flags.H:=False;
 Flags.N:=False;
 Reg.A:=intI;
End;

Procedure ld_a_r;Begin
 intRTemp:=intRTemp And $7F;
 Reg.A:=(intR And $80) Or intRTemp;
 Flags.S:=(Reg.A and FlagsS)<>0;
 Flags.f3:=(Reg.A and Flags3)<>0;
 Flags.f5:=(Reg.A and Flags5)<>0;
 Flags.Zero:=(Reg.A=0);
 Flags.PV:=intIFF2;
 Flags.H:=False;
 Flags.N:=False;
End;

Procedure NegA;
Var
 t:Integer;
Begin
 t:=Reg.A;
 Reg.A:=0;
 SubA(t);
End;

Procedure RLD;
Var
 ans,t,q:Integer;
Begin
 ans:=Reg.A;
 t:=memReadByte(Reg.HL);
 q:=t;
 t:=(t*16)or(ans And $F);
 ans:=(ans And $F0)or(q shr 4);
 memStoreByte(Reg.HL,(t And $FF));
 Flags.S:=(ans And FlagsS)<>0;
 Flags.f3:=(ans And Flags3)<>0;
 Flags.f5:=(ans And Flags5)<>0;
 Flags.Zero:=(ans = 0);
 Flags.PV:=Parity[ans];
 Flags.H:=False;
 Flags.N:=False;
 Reg.A:=ans;
End;

Procedure setIDH(byteval : integer);Begin
 regID:=((byteval shl 8)and $FF00)or(regID And $FF);
End;

Procedure setIDL(byteval:Integer);Begin
 regID := (regID And $FF00) Or (byteval And $FF);
End;

Function InBc:Integer;
Var ans:Integer;
Begin
 ans:=inb(getBC);
 Flags.Zero:=(ans=0);
 Flags.S:=(ans and FlagsS)<>0;
 Flags.f3:=(ans and Flags3)<>0;
 Flags.f5:=(ans and Flags5)<>0;
 Flags.PV:=Parity[ans];
 Flags.N:=False;
 Flags.H:=False;
 InBc:=ans;
End;

Function inc8(ans:Integer):Integer;Begin
 Flags.PV:=(ans=$7F);
 Flags.H:=(((ans And $F) + 1) and FlagsH)<>0;
 ans:=(ans+1) And $FF;
 Flags.S:=(ans and FlagsS)<>0;
 Flags.f3:=(ans and Flags3)<>0;
 Flags.f5:=(ans and Flags5)<>0;
 Flags.Zero:=(ans = 0);
 Flags.N:=False;
 inc8:=ans;
End;

Function dec8(ans:Integer):Integer;Begin
 Flags.PV:=(ans=$80);
 Flags.H:=(((ans And $F)-1) and FlagsH)<>0;
 ans:=(ans - 1) and $FF;
 Flags.S:=(ans and FlagsS)<>0;
 Flags.f3:=(ans and Flags3)<>0;
 Flags.f5:=(ans and Flags5)<>0;
 Flags.Zero:=(ans = 0);
 Flags.N:=True;
 dec8:=ans;
End;

Function popw:Integer;Begin
 popw:=memReadByte(regSP)or(memReadByte(regSP + 1) shl 8);
 regSP:=((regSP+2) and $FFFF);
End;

Procedure poppc;Begin
 regPC:=popw;
End;

Procedure PushWord(word:Integer);Begin
 regSP:=(regSP-2)and $FFFF;
 memStoreWord(regSP,word);
End;

Procedure pushpc;Begin
 PushWord(regPC);
End;

Procedure Refresh(t:integer);Begin
 intRTemp:=intRTemp+t;
End;

Function qdec8(a:integer):integer;Begin
 qdec8:=(a-1) and $FF;
End;

Procedure ExecuteED;
Var
 count,dest,from,b:Integer;
 c:Boolean;
Begin
 intRTemp:=intRTemp+1;
 Case NextPcb of
  0..63, 127..159, 164..167, 172..175, 180..183:; { NOP }
  64:Reg.B:=InBc; { IN B,(c) }
  66:Reg.HL:=sbc16(Reg.HL,getBC); { SBC HL,BC }
  72:Begin { IN C,(c) }
   Reg.C:=InBc;
  End;
  74:Reg.HL:=adc16(Reg.HL,getBC); { ADC HL,BC }
  80:setD(InBc); { IN D,(c) }
  82:Reg.HL:=sbc16(Reg.HL, Reg.DE); { SBC HL,DE }
  88:setE(InBc); { IN E,(c) }
  96:setH(InBc); { IN H,(c) }
  104:setL(InBc); { IN L,(c) }
  112:InBc; { IN (c) }
  120:Reg.A:=InBc; { IN A,(c) }
  65:outb(getBC,Reg.B); { OUT (c),B }
  67:memStoreWord(NextPcw,getBC); { LD (nn),BC }
  68,76,84,92,100,108,116,124:NegA; { NEG }
  69,85,101,117:Begin { RETn }
   intIFF1:=intIFF2;
   poppc;
  End;
  70,78,102,110:intIM:=0; { IM 0 }
  71:intI:=Reg.A; { LD I,A }
  73:outb(getBC,Reg.C); { OUT (c),C }
  75:setBC(memReadWord(NextPcw)); { LD BC,(nn) }
  77,93,109,125:Begin { RETI }
   intIFF1:=intIFF2;
   poppc;
  End;
  79:Begin { LD R,A }
   intR:=Reg.A;
   intRTemp:=intR;
  End;
  81:outb(getBC, getD); { OUT (c),D }
  83:memStoreWord(NextPcw,Reg.DE); { LD (nn),DE }
  86,118:intIM:=1; { IM 1 }
  87:ld_a_i; { LD A,I }
  89:outb(getBC,getE); { OUT (c),E }
  90:Reg.HL:=adc16(Reg.HL,Reg.DE); { ADC HL,DE }
  91:Reg.DE:=memReadWord(NextPcw); { LD DE,(nn) }
  94,126:intIM:=2; { IM 2 }
  95:ld_a_r; { LD A,R }
  97:outb(getBC,getH); { OUT (c),H }
  98:Reg.HL:=sbc16(Reg.HL,Reg.HL); { SBC HL,HL }
  99:memStoreWord(NextPcw,Reg.HL); { LD (nn),HL }
  103:RRD; { RRD }
  105:outb(getBC, getL); { OUT (c),L }
  106:Reg.HL:=adc16(Reg.HL,Reg.HL); { ADC HL,HL }
  107:Reg.HL:=memReadWord(NextPcw); { LD HL,(nn) }
  111:RLD; { RLD }
  113:outb(getBC,0); { OUT (c),0 }
  114:Reg.HL:=sbc16(Reg.HL, regSP); { SBC HL,SP }
  115:memStoreWord(NextPcw, regSP); { LD (nn),SP }
  121:outb(getBC,Reg.A); { OUT (c),A }
  122:Reg.HL:=adc16(Reg.HL,regSP); { ADC HL,SP }
  123:regSP:=memReadWord(NextPcw); { LD SP,(nn) }
  160:Begin { LDI }
   b:=memReadByte(Reg.HL)+Reg.A;
   Flags.f3:=(b and Flags3)<>0;
   Flags.f5:=(b and $02)<>0;
   memStoreByte(Reg.DE, memReadByte(Reg.HL));
   Reg.DE:=inc16(Reg.DE);
   Reg.HL:=inc16(Reg.HL);
   setBC(dec16(getBC));
   Flags.PV:=(getBC<>0);
   Flags.H:=False;
   Flags.N:=False;
  End;
  161:Begin { CPI }
   c:=Flags.Carry;
   CpA(memReadByte(Reg.HL));
   b:=(Reg.A-memReadByte(Reg.HL)-Byte(Flags.H));
   Flags.f3:=(b and Flags3)<>0;
   Flags.f5:=(b and $02)<>0;
   Reg.HL:=inc16(Reg.HL);
   setBC(dec16(getBC));
   Flags.PV:=(getBC<>0);
   Flags.Carry:=c;
  End;
  162:Begin { INI }
   memStoreByte(Reg.HL,inb(getBC));
   b:=qdec8(Reg.B);
   Reg.B:=b;
   Reg.HL:=inc16(Reg.HL);
   Flags.Zero:=(b=0);
   Flags.N:=True;
  End;
  163:Begin { OUTI }
   b:=qdec8(Reg.B);
   Reg.B:=b;
   outb(getBC,memReadByte(Reg.HL));
   Reg.HL:=inc16(Reg.HL);
   Flags.Zero:=(b=0);
   Flags.N:=True;
  End;
  168:Begin { LDD }
   b:=memReadByte(Reg.HL)+Reg.A;
   Flags.f3:=(b and Flags3)<>0;
   Flags.f5:=(b and $02)<>0;
   memStoreByte(Reg.DE, memReadByte(Reg.HL));
   Reg.DE:=dec16(Reg.DE);
   Reg.HL:=dec16(Reg.HL);
   setBC(dec16(getBC));
   Flags.PV:=(getBC<>0);
   Flags.H:=False;
   Flags.N:=False;
  End;
  169:Begin { CPD }
   c:=Flags.Carry;
   CpA(memReadByte(Reg.HL));
   b:=(Reg.A-memReadByte(Reg.HL)-Byte(Flags.H));
   Flags.f3:=(b and Flags3)<>0;
   Flags.f5:=(b and $02)<>0;
   Reg.HL:=dec16(Reg.HL);
   setBC(dec16(getBC));
   Flags.PV:=(getBC<>0);
   Flags.Carry:=c;
  End;
  170:Begin { IND }
   memStoreByte(Reg.HL,inb(getBC));
   b:=qdec8(Reg.B);
   Reg.B:=b;
   Reg.HL:=dec16(Reg.HL);
   Flags.Zero:=(b=0);
   Flags.N:=True;
  End;
  171:Begin { OUTD }
   count:=qdec8(Reg.B);
   Reg.B:=count;
   outb(getBC,memReadByte(Reg.HL));
   Reg.HL:=dec16(Reg.HL);
   Flags.Zero:=(count=0);
   Flags.N:=True;
  End;
  176:Begin { LDIR }
   b:=memReadByte(Reg.HL)+Reg.A;
   Flags.f3:=(b and Flags3)<>0;
   Flags.f5:=(b and $02)<>0;
   memStoreByte(Reg.DE,memReadByte(Reg.HL));
   Reg.DE:=inc16(Reg.DE);
   Reg.HL:=inc16(Reg.HL);
   setBC(dec16(getBC));
   Flags.PV:=(getBC<>0);
   Flags.H:=False;
   Flags.N:=False;
   intRTemp:=intRTemp+1;
   regPC:=regPC-2;
   If getBC=0 Then regPC:=regPC+2;
  End;
  177:Begin { CPIR }
   c:=Flags.Carry;
   CpA(memReadByte(Reg.HL));
   b:=(Reg.A-memReadByte(Reg.HL)-Byte(Flags.H));
   Flags.f3:=(b and Flags3)<>0;
   Flags.f5:=(b and $02)<>0;
   Reg.HL:=inc16(Reg.HL);
   setBC(dec16(getBC));
   Flags.PV:=(getBC<>0);
   Flags.Carry:=c;
   intRTemp:=intRTemp+1;
   If Flags.PV And(Not(Flags.Zero))Then regPC:=regPC-2;
  End;
  178:Begin { INIR }
   memStoreByte(Reg.HL,inb(getBC));
   b:=qdec8(Reg.B);
   Reg.B:=b;
   Reg.HL:=inc16(Reg.HL);
   Flags.Zero:=True;
   Flags.N:=True;
   intRTemp:=intRTemp+1;
   If(b<>0)Then regPC:=regPC-2;
  End;
  179:Begin { OTIR }
   b:=qdec8(Reg.B);
   Reg.B:=b;
   outb(getBC,memReadByte(Reg.HL));
   Reg.HL:=inc16(Reg.HL);
   intRTemp:=intRTemp + 1;
   Flags.Zero:=True;
   Flags.N:=True;
   If(b<>0)Then regPC:=regPC-2;
  End;
  184:Begin { //LDDR }
   b:=memReadByte(Reg.HL)+Reg.A;
   Flags.f3:=(b and Flags3)<>0;
   Flags.f5:=(b and $02)<>0;
   memStoreByte(Reg.DE, memReadByte(Reg.HL));
   Reg.DE:=dec16(Reg.DE);
   Reg.HL:=dec16(Reg.HL);
   setBC(dec16(getBC));
   Flags.PV:=(getBC<>0);
   Flags.H:=False;
   Flags.N:=False;
   intRTemp:=intRTemp+1;
   regPC:=regPC-2;
   If getBC=0 Then regPC:=regPC+2;
  End;
  185:Begin { CPDR }
   c:=Flags.Carry;
   CpA(memReadByte(Reg.HL));
   b:=(Reg.A-memReadByte(Reg.HL)-Byte(Flags.H));
   Flags.f3:=(b and Flags3)<>0;
   Flags.f5:=(b and $02)<>0;
   Reg.HL:=dec16(Reg.HL);
   setBC(dec16(getBC));
   Flags.PV:=(getBC<>0);
   Flags.Carry:=c;
   intRTemp:=intRTemp+1;
   If(Flags.PV)And(Not(Flags.Zero))Then regPC:=regPC-2;
  End;
  186:Begin { INDR }
   memStoreByte(Reg.HL, inb(getBC));
   b:=qdec8(Reg.B);
   Reg.B:=b;
   Reg.HL:=dec16(Reg.HL);
   intRTemp:=intRTemp+1;
   Flags.Zero:=True;
   Flags.N:=True;
   If(b<>0)Then regPC:=regPC-2;
  End;
  187:Begin { OTDR }
   b:=qdec8(Reg.B);
   Reg.B:=b;
   outb(getBC,memReadByte(Reg.HL));
   Reg.HL:=dec16(Reg.HL);
   intRTemp:=intRTemp+1;
   Flags.Zero:=True;
   Flags.N:=True;
   If(b<>0)Then regPC:=regPC-2;
  End;
  Else Begin
   WriteLn('Instruction ED inconnu ',memReadByte(regPC)+(memReadByte(regPC+1) shl 8),' a ',regPC);
   Halt;
  End;
 End;
End;

Procedure ExecuteCB(op,z:Integer);Begin
 Case op of
  $00:Begin { RLC B }
   op:=rlc(memReadByte(z));
   Reg.B:=op;
   memStoreByte(z,op);
  End;
  $01:Begin { RLC C }
   op:=rlc(memReadByte(z));
   Reg.C:=op;
   memStoreByte(z,op);
  End;
  $02:Begin { RLC D }
   op:=rlc(memReadByte(z));
   setD(op);
   memStoreByte(z,op);
  End;
  $03:Begin { RLC E }
   op:=rlc(memReadByte(z));
   setE(op);
   memStoreByte(z,op);
  End;
  $04:Begin { RLC H }
   op:=rlc(memReadByte(z));
   setH(op);
   memStoreByte(z,op);
  End;
  $05:Begin { RLC L }
   op:=rlc(memReadByte(z));
   setL(op);
   memStoreByte(z,op);
  End;
  $06:memStoreByte(z,rlc(memReadByte(z))); { RLC (HL) }
  $07:Begin { RLC A }
   op:=rlc(memReadByte(z));
   Reg.A:=op;
   memStoreByte(z,op);
  End;
  $08:Begin { RRC B }
   op:=rrc(memReadByte(z));
   Reg.B:=op;
   memStoreByte(z,op);
  End;
  $09:Begin { RRC C }
   op:=rrc(memReadByte(z));
   Reg.C:=op;
   memStoreByte(z,op);
  End;
  $0A:Begin { RRC D}
   op:=rrc(memReadByte(z));
   setD(op);
   memStoreByte(z,op);
  End;
  $0B:Begin { RRC E }
   op:=rrc(memReadByte(z));
   setE(op);
   memStoreByte(z,op);
  End;
  $0C:Begin { RRC H }
   op:=rrc(memReadByte(z));
   setH(op);
   memStoreByte(z,op);
  End;
  $0D:Begin { RRC L }
   op:=rrc(memReadByte(z));
   setL(op);
   memStoreByte(z,op);
  End;
  $0E:memStoreByte(z, rrc(memReadByte(z))); { RRC (HL) }
  $0F:Begin { RRC A }
   op:=rrc(memReadByte(z));
   Reg.A:=op;
   memStoreByte(z,op);
  End;
  $10:Begin { RL B }
   op:=rl(memReadByte(z));
   Reg.B:=op;
   memStoreByte(z,op);
  End;
  $11:Begin { RL C }
   op:=rl(memReadByte(z));
   Reg.C:=op;
   memStoreByte(z,op);
  End;
  $12:Begin { RL D }
   op:=rl(memReadByte(z));
   setD(op);
   memStoreByte(z,op);
  End;
  $13:Begin { RL E }
   op:=rl(memReadByte(z));
   setE(op);
   memStoreByte(z, op);
  End;
  $14:Begin { RL H }
   op:=rl(memReadByte(z));
   setH(op);
   memStoreByte(z,op);
  End;
  $15:Begin { RL L }
   op:=rl(memReadByte(z));
   setL(op);
   memStoreByte(z,op);
  End;
  $16:memStoreByte(z,rl(memReadByte(z))); { RL (HL) }
  $17:Begin { RL A }
   op:=rl(memReadByte(z));
   Reg.A:=op;
   memStoreByte(z,op);
  End;
  $18:Begin { RR B }
   op:=rr(memReadByte(z));
   Reg.B:=op;
   memStoreByte(z,op);
  End;
  $19:Begin { RR C }
   op:=rr(memReadByte(z));
   Reg.C:=op;
   memStoreByte(z,op);
  End;
  $1A:Begin { RR D }
   op:=rr(memReadByte(z));
   setD(op);
   memStoreByte(z,op);
  End;
  $1B:Begin { RR E }
   op:=rr(memReadByte(z));
   setE(op);
   memStoreByte(z,op);
  End;
  $1C:Begin { RR H }
   op:=rr(memReadByte(z));
   setH(op);
   memStoreByte(z,op);
  End;
  $1D:Begin { RR L }
   op:=rr(memReadByte(z));
   setL(op);
   memStoreByte(z, op);
  End;
  $1E:memStoreByte(z, rr(memReadByte(z))); { RR (HL) }
  $1F:Begin { RR A }
   op:=rr(memReadByte(z));
   Reg.A:=op;
   memStoreByte(z,op);
  End;
  $20:Begin { SLA B }
   op:=sla(memReadByte(z));
   Reg.B:=op;
   memStoreByte(z,op);
  End;
  $21:Begin { SLA C }
   op:=sla(memReadByte(z));
   Reg.C:=op;
   memStoreByte(z,op);
  End;
  $22:Begin { SLA D }
   op:=sla(memReadByte(z));
   setD(op);
   memStoreByte(z, op);
  End;
  $23:Begin { SLA E }
   op:=sla(memReadByte(z));
   setE(op);
   memStoreByte(z,op);
  End;
  $24:Begin { SLA H }
   op:=sla(memReadByte(z));
   setH(op);
   memStoreByte(z,op);
  End;
  $25:Begin { SLA L }
   op:=sla(memReadByte(z));
   setL(op);
   memStoreByte(z,op);
  End;
  $26:memStoreByte(z, sla(memReadByte(z))); { SLA (HL) }
  $27:Begin { SLA A }
   op:=sla(memReadByte(z));
   Reg.A:=op;
   memStoreByte(z,op);
  End;
  $28:Begin { SRA B }
   op:=sra(memReadByte(z));
   Reg.B:=op;
   memStoreByte(z,op);
  End;
  $29:Begin { SRA C }
   op:=sra(memReadByte(z));
   Reg.C:=op;
   memStoreByte(z, op);
  End;
  $2A:Begin { SRA D }
   op:=sra(memReadByte(z));
   setD(op);
   memStoreByte(z,op);
  End;
  $2B:Begin { SRA E }
   op:=sra(memReadByte(z));
   setE(op);
   memStoreByte(z,op);
  End;
  $2C:Begin { SRA H }
   op:=sra(memReadByte(z));
   setH(op);
   memStoreByte(z,op);
  End;
  $2D:Begin { SRA L }
   op:=sra(memReadByte(z));
   setL(op);
   memStoreByte(z,op);
  End;
  $2E:memStoreByte(z, sra(memReadByte(z)));  { SRA (HL) }
  $2F:Begin { SRA A }
   op:=sra(memReadByte(z));
   Reg.A:=op;
   memStoreByte(z,op);
  End;
  $30:Begin { SLS B }
   op:=sls(memReadByte(z));
   Reg.B:=op;
   memStoreByte(z,op);
  End;
  $31:Begin { SLS C }
   op:=sls(memReadByte(z));
   Reg.C:=op;
   memStoreByte(z,op);
  End;
  $32:Begin { SLS D }
   op:=sls(memReadByte(z));
   setD(op);
   memStoreByte(z, op);
  End;
  $33:Begin { SLS E }
   op:=sls(memReadByte(z));
   setE(op);
   memStoreByte(z,op);
  End;
  $34:Begin { SLS H }
   op:=sls(memReadByte(z));
   setH(op);
   memStoreByte(z,op);
  End;
  $35:Begin { SLS L }
   op:=sls(memReadByte(z));
   setL(op);
   memStoreByte(z,op);
  End;
  $36:memStoreByte(z, sls(memReadByte(z))); { SLS (HL) }
  $37:Begin { SLS A }
   op:=sls(memReadByte(z));
   Reg.A:=op;
   memStoreByte(z,op);
  End;
  $38:Begin { SRL B }
   op:=srl(memReadByte(z));
   Reg.B:=op;
   memStoreByte(z, op);
  End;
  $39:Begin { SRL C }
   op:=srl(memReadByte(z));
   Reg.C:=op;
   memStoreByte(z,op);
  End;
  $3A:Begin { SRL D }
   op:=srl(memReadByte(z));
   setD(op);
   memStoreByte(z,op);
  End;
  $3B:Begin { SRL E }
   op:=srl(memReadByte(z));
   setE(op);
   memStoreByte(z,op);
  End;
  $3C:Begin { SRL H }
   op:=srl(memReadByte(z));
   setH(op);
   memStoreByte(z,op);
  End;
  $3D:Begin { SRL L }
   op:=srl(memReadByte(z));
   setL(op);
   memStoreByte(z,op);
  End;
  $3E:memStoreByte(z, srl(memReadByte(z))); { SRL (ID) }
  $3F:Begin { SRL A }
   op:=srl(memReadByte(z));
   Reg.A:=op;
   memStoreByte(z,op);
  End;
  $40..$47:BitID($1,memReadByte(z),z);  { BIT 0,B }
  $48..$4F:BitID($2,memReadByte(z),z);  { BIT 1,B }
  $50..$57:BitID($4,memReadByte(z),z);  { BIT 2,B }
  $58..$5F:BitID($8,memReadByte(z),z); { BIT 3,B }
  $60..$67:BitID($10,memReadByte(z),z); { BIT 4,B }
  $68..$6F:BitID($20,memReadByte(z),z); { BIT 5,B }
  $70..$77:BitID($40,memReadByte(z),z); { BIT 6,B }
  $78..$7F:BitID($80,memReadByte(z),z); { BIT 7,B }
  $80:Begin { RES 0,(ID+y)->B }
   Reg.B:=bitRes(1,memReadByte(z));
   memStoreByte(z,Reg.B);
  End;
  $81:Begin { RES 0,(ID+y)->C }
   Reg.C:=bitRes(1,memReadByte(z));
   memStoreByte(z,Reg.C);
  End;
  $82:Begin { RES 0,(ID+y)->D }
   setD(bitRes(1,memReadByte(z)));
   memStoreByte(z, getD);
  End;
  $83:Begin { RES 0,(ID+y)->E }
   setE(bitRes(1,memReadByte(z)));
   memStoreByte(z, getE);
  End;
  $84:Begin { RES 0,(ID+y)->H }
   setH(bitRes(1,memReadByte(z)));
   memStoreByte(z,getH);
  End;
  $85:Begin { RES 0,(ID+y)->L }
   setL(bitRes(1,memReadByte(z)));
   memStoreByte(z,getL);
  End;
  $86:memStoreByte(z, bitRes($1,memReadByte(z))); { RES 0,(HL) }
  $87:Begin { RES 0,(ID+y)->A }
   Reg.A:=bitRes(1,memReadByte(z));
   memStoreByte(z,Reg.A);
  End;
  $88:Begin { RES 1,(ID+y)->B }
   Reg.B:=bitRes(2,memReadByte(z));
   memStoreByte(z,Reg.B);
  End;
  $89:Begin { RES 1,(ID+y)->C }
   Reg.C:=bitRes(2,memReadByte(z));
   memStoreByte(z,Reg.C);
  End;
  $8A:Begin { RES 1,(ID+y)->D }
   setD(bitRes(2,memReadByte(z)));
   memStoreByte(z,getD);
  End;
  $8B:Begin { RES 1,(ID+y)->E }
   setE(bitRes(2,memReadByte(z)));
   memStoreByte(z,getE);
  End;
  $8C:Begin { RES 1,(ID+y)->H }
   setH(bitRes(2,memReadByte(z)));
   memStoreByte(z,getH);
  End;
  $8D:Begin { RES 1,(ID+y)->L }
   setL(bitRes(2, memReadByte(z)));
   memStoreByte(z, getL);
  End;
  $8E:memStoreByte(z,bitRes($2,memReadByte(z))); { RES 1,(HL) }
  $8F:Begin { RES 1,(ID+y)->A }
   Reg.A:=bitRes(2, memReadByte(z));
   memStoreByte(z,Reg.A);
  End;
  $90:Begin { RES 2,(ID+y)->B }
   Reg.B:=bitRes(4, memReadByte(z));
   memStoreByte(z,Reg.B);
  End;
  $91:Begin { RES 2,(ID+y)->C }
   Reg.C:=bitRes(4,memReadByte(z));
   memStoreByte(z,Reg.C);
  End;
  $92:Begin { RES 2,(ID+y)->D }
   setD(bitRes(4,memReadByte(z)));
   memStoreByte(z,getD);
  End;
  $93:Begin { RES 2,(ID+y)->E }
   setE(bitRes(4, memReadByte(z)));
   memStoreByte(z, getE);
  End;
  $94:Begin { RES 2,(ID+y)->H }
   setH(bitRes(4, memReadByte(z)));
   memStoreByte(z, getH);
  End;
  $95:Begin { RES 2,(ID+y)->L }
   setL(bitRes(4, memReadByte(z)));
   memStoreByte(z, getL);
  End;
  $96:memStoreByte(z, bitRes($4, memReadByte(z))); { RES 2,(HL) }
  $97:Begin { RES 2,(ID+y)->A }
   Reg.A:=bitRes(4, memReadByte(z));
   memStoreByte(z,Reg.A);
  End;
  $98:Begin { RES 3,(ID+y)->B }
   Reg.B:=bitRes(8, memReadByte(z));
   memStoreByte(z,Reg.B);
  End;
  $99:Begin { RES 3,(ID+y)->C }
   Reg.C:=bitRes(8, memReadByte(z));
   memStoreByte(z,Reg.C);
  End;
  $9A:Begin { RES 3,(ID+y)->D }
   setD(bitRes(8, memReadByte(z)));
   memStoreByte(z, getD);
  End;
  $9B:Begin { RES 3,(ID+y)->E }
   setE(bitRes(8, memReadByte(z)));
   memStoreByte(z,getE);
  End;
  $9C:Begin { RES 3,(ID+y)->H }
   setH(bitRes(8, memReadByte(z)));
   memStoreByte(z, getH);
  End;
  $9D:Begin { RES 3,(ID+y)->L }
   setL(bitRes(8, memReadByte(z)));
   memStoreByte(z, getL);
  End;
  $9E:memStoreByte(z,bitRes($8, memReadByte(z))); { RES 3,(HL) }
  $9F:Begin { RES 3,(ID+y)->A }
   Reg.A:=bitRes(8,memReadByte(z));
   memStoreByte(z,Reg.A);
  End;
  $A0:Begin { RES 4,(ID+y)->B }
   Reg.B:=bitRes($10,memReadByte(z));
   memStoreByte(z,Reg.B);
  End;
  $A1:Begin { RES 4,(ID+y)->C }
   Reg.C:=bitRes($10,memReadByte(z));
   memStoreByte(z,Reg.C);
  End;
  $A2:Begin { RES 4,(ID+y)->D }
   setD(bitRes($10,memReadByte(z)));
   memStoreByte(z, getD);
  End;
  $A3:Begin { RES 4,(ID+y)->E }
   setE(bitRes($10,memReadByte(z)));
   memStoreByte(z,getE);
  End;
  $A4:Begin { RES 4,(ID+y)->H }
   setH(bitRes($10,memReadByte(z)));
   memStoreByte(z,getH);
  End;
  $A5:Begin { RES 4,(ID+y)->L }
   setL(bitRes($10,memReadByte(z)));
   memStoreByte(z,getL);
  End;
  $A6:memStoreByte(z, bitRes($10, memReadByte(z))); { RES 4,(HL) }
  $A7:Begin { RES 4,(ID+y)->A }
   Reg.A:=bitRes($10,memReadByte(z));
   memStoreByte(z,Reg.A);
  End;
  $A8:Begin { RES 5,(ID+y)->B }
   Reg.B:=bitRes($20,memReadByte(z));
   memStoreByte(z,Reg.B);
  End;
  $A9:Begin { RES 5,(ID+y)->C }
   Reg.C:=bitRes($20, memReadByte(z));
   memStoreByte(z,Reg.C);
  End;
  $AA:Begin { RES 5,(ID+y)->D }
   setD(bitRes($20,memReadByte(z)));
   memStoreByte(z,getD);
  End;
  $AB:Begin { RES 5,(ID+y)->E }
   setE(bitRes($20, memReadByte(z)));
   memStoreByte(z, getE);
  End;
  $AC:Begin { RES 5,(ID+y)->H }
   setH(bitRes($20,memReadByte(z)));
   memStoreByte(z,getH);
  End;
  $AD:Begin { RES 5,(ID+y)->L }
   setL(bitRes($20, memReadByte(z)));
   memStoreByte(z, getL);
  End;
  $AE:memStoreByte(z,bitRes($20,memReadByte(z))); { RES 5,(HL) }
  $AF:Begin { RES 5,(ID+y)->A }
   Reg.A:=bitRes($20, memReadByte(z));
   memStoreByte(z,Reg.A);
  End;
  $B0:Begin { RES 6,(ID+y)->B }
   Reg.B:=bitRes($40, memReadByte(z));
   memStoreByte(z,Reg.B);
  End;
  $B1:Begin { RES 6,(ID+y)->C }
   Reg.C:=bitRes($40, memReadByte(z));
   memStoreByte(z,Reg.C);
  End;
  $B2:Begin { RES 6,(ID+y)->D }
   setD(bitRes($40, memReadByte(z)));
   memStoreByte(z,getD);
  End;
  $B3:Begin { RES 6,(ID+y)->E }
   setE(bitRes($40, memReadByte(z)));
   memStoreByte(z, getE);
  End;
  $B4:Begin { RES 6,(ID+y)->H }
   setH(bitRes($40, memReadByte(z)));
   memStoreByte(z, getH);
  End;
  $B5:Begin { RES 6,(ID+y)->L }
   setL(bitRes($40,memReadByte(z)));
   memStoreByte(z,getL);
  End;
  $B6:memStoreByte(z, bitRes($40, memReadByte(z))); { RES 6,(HL) }
  $B7:Begin { RES 6,(ID+y)->A}
   Reg.A:=bitRes($40,memReadByte(z));
   memStoreByte(z,Reg.A);
  End;
  $B8:Begin { RES 6,(ID+y)->B }
   Reg.B:=bitRes($80,memReadByte(z));
   memStoreByte(z,Reg.B);
  End;
  $B9:Begin { RES 6,(ID+y)->C }
   Reg.C:=bitRes($80,memReadByte(z));
   memStoreByte(z,Reg.C);
  End;
  $BA:Begin { RES 6,(ID+y)->D }
   setD(bitRes($80,memReadByte(z)));
   memStoreByte(z,getD);
  End;
  $BB:Begin { RES 6,(ID+y)->E }
   setE(bitRes($80, memReadByte(z)));
   memStoreByte(z, getE);
  End;
  $BC:Begin { RES 6,(ID+y)->H }
   setH(bitRes($80, memReadByte(z)));
   memStoreByte(z, getH);
  End;
  $BD:Begin { RES 6,(ID+y)->L }
   setL(bitRes($80, memReadByte(z)));
   memStoreByte(z, getL);
  End;
  $BE:memStoreByte(z, bitRes($80, memReadByte(z))); { RES 7,(HL) }
  $BF:Begin { RES 7,(ID+y)->A }
   Reg.A:=bitRes($80, memReadByte(z));
   memStoreByte(z,Reg.A);
  End;
  $C0:Begin { SET 0,(ID+y)->B }
   Reg.B:=bitSet(1,memReadByte(z));
   memStoreByte(z,Reg.B);
  End;
  $C1:Begin { SET 0,(ID+y)->C }
   Reg.C:=bitSet(1, memReadByte(z));
   memStoreByte(z,Reg.C);
  End;
  $C2:Begin { SET 0,(ID+y)->D }
   setD(bitSet(1,memReadByte(z)));
   memStoreByte(z,getD);
  End;
  $C3:Begin { SET 0,(ID+y)->E }
   setE(bitSet(1, memReadByte(z)));
   memStoreByte(z, getE);
  End;
  $C4:Begin { SET 0,(ID+y)->H }
   setH(bitSet(1, memReadByte(z)));
   memStoreByte(z,getH);
  End;
  $C5:Begin { SET 0,(ID+y)->L }
   setL(bitSet(1, memReadByte(z)));
   memStoreByte(z, getL);
  End;
  $C6:memStoreByte(z,bitSet($1,memReadByte(z))); { SET 0,(HL) }
  $C7:Begin { SET 0,(ID+y)->A }
   Reg.A:=bitSet(1, memReadByte(z));
   memStoreByte(z,Reg.A);
  End;
  $C8:Begin { SET 1,(ID+y)->B }
   Reg.B:=bitSet(2,memReadByte(z));
   memStoreByte(z,Reg.B);
  End;
  $C9:Begin { SET 1,(ID+y)->C }
   Reg.C:=bitSet(2,memReadByte(z));
   memStoreByte(z,Reg.C);
  End;
  $CA:Begin { SET 1,(ID+y)->D }
   setD(bitSet(2, memReadByte(z)));
   memStoreByte(z, getD);
  End;
  $CB:Begin { SET 1,(ID+y)->E }
   setE(bitSet(2, memReadByte(z)));
   memStoreByte(z,getE);
  End;
  $CC:Begin { SET 1,(ID+y)->H }
   setH(bitSet(2, memReadByte(z)));
   memStoreByte(z, getH);
  End;
  $CD:Begin { SET 1,(ID+y)->L }
   setL(bitSet(2, memReadByte(z)));
   memStoreByte(z, getL);
  End;
  $CE:memStoreByte(z, bitSet($2, memReadByte(z))); { SET 1,(HL) }
  $CF:Begin { SET 1,(ID+y)->A }
   Reg.A:=bitSet(2,memReadByte(z));
   memStoreByte(z,Reg.A);
  End;
  $D0:Begin { SET 2,(ID+y)->B }
   Reg.B:=bitSet(4,memReadByte(z));
   memStoreByte(z,Reg.B);
  End;
  $D1:Begin { SET 2,(ID+y)->C }
   Reg.C:=bitSet(4,memReadByte(z));
   memStoreByte(z,Reg.C);
  End;
  $D2:Begin { SET 2,(ID+y)->D }
   setD(bitSet(4,memReadByte(z)));
   memStoreByte(z,getD);
  End;
  $D3:Begin { SET 2,(ID+y)->E }
   setE(bitSet(4,memReadByte(z)));
   memStoreByte(z,getE);
  End;
  $D4:Begin { SET 2,(ID+y)->H }
   setH(bitSet(4, memReadByte(z)));
   memStoreByte(z, getH);
  End;
  $D5:Begin { SET 2,(ID+y)->L }
   setL(bitSet(4,memReadByte(z)));
   memStoreByte(z, getL);
  End;
  $D6:memStoreByte(z,bitSet($4,memReadByte(z))); { SET 2,(HL) }
  $D7:Begin { SET 2,(ID+y)->A }
   Reg.A:=bitSet(4,memReadByte(z));
   memStoreByte(z,Reg.A);
  End;
  $D8:Begin { SET 3,(ID+y)->B }
   Reg.B:=bitSet(8, memReadByte(z));
   memStoreByte(z,Reg.B);
  End;
  $D9:Begin { SET 3,(ID+y)->C }
   Reg.C:=bitSet(8,memReadByte(z));
   memStoreByte(z,Reg.C);
  End;
  $DA:Begin { SET 3,(ID+y)->D }
   setD(bitSet(8, memReadByte(z)));
   memStoreByte(z,getD);
  End;
  $DB:Begin { SET 3,(ID+y)->E }
   setE(bitSet(8, memReadByte(z)));
   memStoreByte(z, getE);
  End;
  $DC:Begin { SET 3,(ID+y)->H }
   setH(bitSet(8,memReadByte(z)));
   memStoreByte(z,getH);
  End;
  $DD:Begin { SET 3,(ID+y)->L }
   setL(bitSet(8,memReadByte(z)));
   memStoreByte(z,getL);
  End;
  $DE:memStoreByte(z,bitSet($8,memReadByte(z))); { SET 3,(HL) }
  $DF:Begin { SET 3,(ID+y)->A }
   Reg.A:=bitSet(8, memReadByte(z));
   memStoreByte(z,Reg.A);
  End;
  $E0:Begin { SET 4,(ID+y)->B }
   Reg.B:=bitSet($10, memReadByte(z));
   memStoreByte(z,Reg.B);
  End;
  $E1:Begin { SET 4,(ID+y)->C }
   Reg.C:=bitSet($10, memReadByte(z));
   memStoreByte(z,Reg.C);
  End;
  $E2:Begin { SET 4,(ID+y)->D }
   setD(bitSet($10,memReadByte(z)));
   memStoreByte(z,getD);
  End;
  $E3:Begin { SET 4,(ID+y)->E }
   setE(bitSet($10,memReadByte(z)));
   memStoreByte(z,getE);
  End;
  $E4:Begin { SET 4,(ID+y)->H }
   setH(bitSet($10, memReadByte(z)));
   memStoreByte(z,getH);
  End;
  $E5:Begin { SET 4,(ID+y)->L }
   setL(bitSet($10,memReadByte(z)));
   memStoreByte(z,getL);
  End;
  $E6:memStoreByte(z, bitSet($10, memReadByte(z))); { SET 4,(HL) }
  $E7:Begin { SET 4,(ID+y)->A }
   Reg.A:=bitSet($10, memReadByte(z));
   memStoreByte(z,Reg.A);
  End;
  $E8:Begin { SET 5,(ID+y)->B }
   Reg.B:=bitSet($20,memReadByte(z));
   memStoreByte(z,Reg.B);
  End;
  $E9:Begin { SET 5,(ID+y)->C }
   Reg.C:=bitSet($20, memReadByte(z));
   memStoreByte(z,Reg.C);
  End;
  $EA:Begin { SET 5,(ID+y)->D }
   setD(bitSet($20,memReadByte(z)));
   memStoreByte(z,getD);
  End;
  $EB:Begin { SET 5,(ID+y)->E }
   setE(bitSet($20, memReadByte(z)));
   memStoreByte(z,getE);
  End;
  $EC:Begin { SET 5,(ID+y)->H }
   setH(bitSet($20, memReadByte(z)));
   memStoreByte(z,getH);
  End;
  $ED:Begin { SET 5,(ID+y)->L }
   setL(bitSet($20, memReadByte(z)));
   memStoreByte(z, getL);
  End;
  $EE:memStoreByte(z, bitSet($20, memReadByte(z))); { SET 5,(HL) }
  $EF:Begin { SET 5,(ID+y)->A }
   Reg.A:=bitSet($20, memReadByte(z));
   memStoreByte(z,Reg.A);
  End;
  $F0:Begin { SET 6,(ID+y)->B }
   Reg.B:=bitSet($40, memReadByte(z));
   memStoreByte(z,Reg.B);
  End;
  $F1:Begin { SET 6,(ID+y)->C }
   Reg.C:=bitSet($40, memReadByte(z));
   memStoreByte(z, Reg.C);
  End;
  $F2:Begin { SET 6,(ID+y)->D }
   setD(bitSet($40, memReadByte(z)));
   memStoreByte(z, getD);
  End;
  $F3:Begin { SET 6,(ID+y)->E }
   setE(bitSet($40,memReadByte(z)));
   memStoreByte(z,getE);
  End;
  $F4:Begin { SET 6,(ID+y)->H }
   SetH(bitSet($40, memReadByte(z)));
   memStoreByte(z,getH);
  End;
  $F5:Begin { SET 6,(ID+y)->L }
   SetL(bitSet($40, memReadByte(z)));
   memStoreByte(z, getL);
  End;
  $F6:memStoreByte(z, bitSet($40, memReadByte(z))); { SET 6,(HL) }
  $F7:Begin { SET 6,(ID+y)->A }
   Reg.A:=bitSet($40, memReadByte(z));
   memStoreByte(z,Reg.A);
  End;
  $F8:Begin { SET 7,(ID+y)->B }
   Reg.B:=bitSet($80, memReadByte(z));
   memStoreByte(z,Reg.B);
  End;
  $F9:Begin { SET 7,(ID+y)->C }
   Reg.C:=bitSet($80,memReadByte(z));
   memStoreByte(z,Reg.C);
  End;
  $FA:Begin { SET 7,(ID+y)->D }
   SetD(bitSet($80, memReadByte(z)));
   memStoreByte(z, getD);
  End;
  $FB:Begin { SET 7,(ID+y)->E }
   SetE(bitSet($80, memReadByte(z)));
   memStoreByte(z, getE);
  End;
  $FC:Begin { SET 7,(ID+y)->H }
   SetH(bitSet($80, memReadByte(z)));
   memStoreByte(z, getH);
  End;
  $FD:Begin { SET 7,(ID+y)->L }
   SetL(bitSet($80, memReadByte(z)));
   memStoreByte(z, getL);
  End;
  $FE:memStoreByte(z, bitSet($80, memReadByte(z))); { SET 7,(HL) }
  $FF:Begin { SET 7,A }
   Reg.A:=bitSet($80, memReadByte(z));
   memStoreByte(z,Reg.A);
  End;
 End;
End;

Function SpecInterrupt:Integer;begin
 SpecInterrupt:=0;
 interruptCounter:=interruptCounter+1;
 If Not(intIFF1)Then SpecInterrupt:=0;
End;

Procedure OrA(b:Integer);Begin
 Reg.A:=(Reg.A Or b);
 Flags.S:=(Reg.A And FlagsS)<>0;
 Flags.f3:=(Reg.A And Flags3)<>0;
 Flags.f5:=(Reg.A And Flags5)<>0;
 Flags.H:=False;
 Flags.PV:=Parity[Reg.A];
 Flags.Zero:=(Reg.A=0);
 Flags.N:=False;
 Flags.Carry:=False;
End;

Procedure ExecuteId;
Var
 lTemp,op:Integer;
Begin
 intRTemp:=intRTemp+1;
 Case NextPcb of
  0..8, 10..24, 26..32, 39, 40, 47..51, 55, 56, 58..67:Begin
   regPC:=dec16(regPC);
   intRTemp:=intRTemp-1;
  End;
  71..75, 79..83, 87..91, 95, 120..123, 127..131:Begin
   regPC:=dec16(regPC);
   intRTemp:=intRTemp-1;
  End;
  135..139, 143..147, 151..155, 159..163, 167..171:Begin
   regPC:=dec16(regPC);
   intRTemp:=intRTemp-1;
  End;
  175..179, 183..187, 191..202, 204..224, 226, 228:Begin
   regPC:=dec16(regPC);
   intRTemp:=intRTemp-1;
  End;
  230..232, 234..248:Begin
   regPC:=dec16(regPC);
   intRTemp:=intRTemp-1;
  End;
  9:regID:=add16(regID,getBC); { ADD ID,BC }
  25:regID:=add16(regID,Reg.DE); { ADD ID,DE }
  33:regID:=NextPcw; { LD ID,nn }
  34:memStoreWord(NextPcw,regID); { LD (nn),ID }
  35:regID:=inc16(regID); { INC ID }
  36:SetIDH(inc8(getIDH)); { INC IDH}
  37:SetIDH(dec8(getIDH)); { DEC IDH }
  38:SetIDH(NextPcb); { LD IDH,n }
  41:Begin { ADD ID,ID }
   lTemp:=regID;
   regID:=add16(lTemp, lTemp);
  End;
  42:regID:=memReadWord(NextPcw); { LD ID,(nn) }
  43:regID:=dec16(regID); { DEC ID }
  44:SetIDL(inc8(getIDL)); { INC IDL }
  45:SetIDL(dec8(getIDL)); { DEC IDL }
  46:SetIDL(NextPcb); { LD IDL,n }
  52:Begin { INC (ID+d) }
   lTemp:=IdD;
   memStoreByte(lTemp, inc8(memReadByte(lTemp)));
  End;
  53:Begin { DEC (ID+d) }
   lTemp:=IdD;
   memStoreByte(lTemp, dec8(memReadByte(lTemp)));
  End;
  54:Begin { LD (ID+d),n }
   lTemp:=IdD;
   memStoreByte(lTemp,NextPcb);
  End;
  57:regID:=add16(regID, regSP); { ADD ID,SP }
  68:Reg.B:=getIDH; { LD B,IDH }
  69:Reg.B:=getIDL; { LD B,IDL }
  70:Reg.B:=memReadByte(IdD); { LD B,(ID+d) }
  76:Reg.C:=getIDH; { LD C,IDH }
  77:Reg.C:=getIDL; { LD C,IDL }
  78:Reg.C:=memReadByte(IdD); { LD C,(ID+d) }
  84:SetD(getIDH); { LD D,IDH }
  85:SetD(getIDL); { LD D,IDL}
  86:SetD(memReadByte(IdD)); { LD D,(ID+d) }
  92:SetE(getIDH); { LD E,IDH }
  93:SetE(getIDL); { LD E,IDL}
  94:SetE(memReadByte(IdD)); { LD E,(ID+d) }
  96:SetIDH(Reg.B); { LD IDH,B }
  97:SetIDH(Reg.C); { LD IDH,C }
  98:SetIDH(getD); { LD IDH,D }
  99:SetIDH(getE); { LD IDH,E }
  100:; { LD IDH,IDH }
  101:SetIDH(getIDL); { LD IDH,IDL }
  102:SetH(memReadByte(IdD)); { LD H,(ID+d) }
  103:SetIDH(Reg.A); { LD IDH,A}
  104:SetIDL(Reg.B); { LD IDL,B }
  105:SetIDL(Reg.C); { LD IDL,C }
  106:SetIDL(getD); { LD IDL,D }
  107:SetIDL(getE); { LD IDL,E }
  108:SetIDL(getIDH); { LD IDL,IDH }
  109:; { LD IDL,IDL }
  110:SetL(memReadByte(IdD)); { LD L,(ID+d) }
  111:SetIDL(Reg.A); { LD IDL,A }
  112:memStoreByte(IdD,Reg.B); { LD (ID+d),B }
  113:memStoreByte(IdD,Reg.C); { LD (ID+d),C }
  114:memStoreByte(IdD,getD); { LD (ID+d),D }
  115:memStoreByte(IdD,getE); { LD (ID+d),E }
  116:memStoreByte(IdD,getH); { LD (ID+d),H }
  117:memStoreByte(IdD,getL); { LD (ID+d),L }
  119:memStoreByte(IdD,Reg.A); { LD (ID+d),A }
  124:Reg.A:=getIDH; { LD A,IDH }
  125:Reg.A:=getIDL; { LD A,IDL }
  126:Reg.A:=memReadByte(IdD); { LD A,(ID+d) }
  132:AddA(getIDH); { ADD A,IDH }
  133:AddA(getIDL); { ADD A,IDL }
  134:AddA(memReadByte(IdD)); { ADD A,(ID+d) }
  140:AdcA(getIDH);{ ADC A,IDH }
  141:AdcA(getIDL); { ADC A,IDL }
  142:AdcA(memReadByte(IdD)); { ADC A,(ID+d) }
  148:SubA(getIDH); { SUB IDH }
  149:SubA(getIDL); { SUB IDL }
  150:SubA(memReadByte(IdD)); { SUB (ID+d)}
  156:SbcA(getIDH); { SBC A,IDH }
  157:SbcA(getIDL); { SBC A,IDL }
  158:SbcA(memReadByte(IdD)); { SBC A,(ID+d) }
  164:AndA(getIDH); { AND IDH }
  165:AndA(getIDL); { AND IDL }
  166:AndA(memReadByte(IdD)); { AND (ID+d) }
  172:XorA(getIDH); { XOR IDH }
  173:XorA(getIDL); { XOR IDL }
  174:XorA(memReadByte(IdD)); { OR (ID+d) }
  180:OrA(getIDH); { OR IDH }
  181:OrA(getIDL); { OR IDL}
  182:OrA(memReadByte(IdD)); { OR (ID+d) }
  188:CpA(getIDH); { CP IDH }
  189:CpA(getIDL); { CP IDL }
  190:CpA(memReadByte(IdD)); { CP (ID+d) }
  203:Begin { Pr‚fixe CB }
   lTemp:=IdD;
   op:=NextPcb;
   ExecuteCB(op,lTemp);
  End;
  225:regID:=popw; { POP ID }
  227:Begin { EX (SP),ID }
   lTemp:=regID;
   regID:=memReadWord(regSP);
   memStoreWord(regSP,lTemp);
  End;
  229:PushWord(regID); { PUSH ID }
  233:regPC:=regID; { JP ID }
  249:regSP:=regID; { LD SP,ID }
  Else Begin
   WriteLn('Instruction ID inconnu ',memReadByte(regPC)+(memReadByte(regPC+1) shl 8),' a ',regPC);
   Halt;
  End;
 End;
End;

Procedure InitEmul;Begin
 regPC:=0;
 prevPC:=0;
 regSP:=0;
 Reg.A:=0;
 setF(0);
 setBC(0);
 Reg.DE:=0;
 Reg.HL:=0;
 exx;
 ExAfAf;
 Reg.A:=0;
 SetF(0);
 SetBC(0);
 Reg.HL:=0;
 regIX:=0;
 regIY:=0;
 Reg.DE:=0;
 intR:=128;
 intRTemp:=0;
 intI:=0;
 intIFF1:=False;
 intIFF2:=False;
 intIM:=0;
End;

Procedure ExecEmul;
Var
 bbb:Byte;
 intCtrTemp,d,lTemp:Integer;
Begin
 intCtrTemp:=InterruptCounter;
 Repeat
  prevPC:=regPC;
  If intRTemp=$FFFF Then Begin
   WriteLn('Debordement du registre PC');
   Halt;
  End;
  intRTemp:=intRTemp+1;
  Case NextPcb of
   $00:; { NOP }
   $01:setBC(NextPcw);{ LD BC,nn }
   $02:memStoreByte(getBC,Reg.A); { LD (BC),A }
   $03:setBC(inc16(getBC)); { INC BC }
   $04:Reg.B:=inc8(Reg.B); { INC B}
   $05:Reg.B:=dec8(Reg.B); { DEC B}
   $06:Reg.B:=NextPcb; { LD B,n }
   $07:RLCA; { RLCA }
   $08:ExAfAf; { EX AF,AF'}
   $09:Reg.HL:=Add16(Reg.HL, getBC); { ADD HL,BC }
   $0A:Reg.A:=memReadByte(getBC); { LD A,(BC) }
   $0B:setBC(dec16(getBC)); { DEC BC}
   $0C:Reg.C:=inc8(Reg.C); { INC C }
   $0D:Reg.C:=dec8(Reg.C); { DEC C}
   $0E:Reg.C:=NextPcb; { LD C,n }
   $0F:RRCA; { RRCA }
   $10:Begin { DJNZ dis}
    lTemp:=qdec8(Reg.B);
    Reg.B:=lTemp;
    If lTemp<>0 Then Begin
     d:=NextPcb;
     If(d And 128)=128 Then d:=-(256-d);
     regPC:=(regPC+d) And $FFFF;
    End
     Else
    regPC:=Inc16(regPC);
   End;
   $11:Reg.DE:=NextPcw; { LD DE,nn }
   $12:memStoreByte(Reg.DE,Reg.A); { LD (DE),A }
   $13:Reg.DE:=Inc16(Reg.DE); { INC DE}
   $14:SetD(inc8(getD)); { INC D }
   $15:SetD(dec8(getD)); { DEC D }
   $16:SetD(NextPcb); { LD D,n }
   $17:RLA; { RLA }
   $18:Begin { JR dis }
    d:=NextPcb;
    If(d And 128)=128 Then d:=-(256-d);
    regPC:=(regPC+d) And $FFFF;
   End;
   $19:Reg.HL:=add16(Reg.HL,Reg.DE); { ADD HL,DE }
   $1A:Reg.A:=memReadByte(Reg.DE); { LD A,(DE) }
   $1B:Reg.DE:=dec16(Reg.DE); { DEC DE }
   $1C:SetE(inc8(getE)); { INC E }
   $1D:SetE(dec8(getE)); { DEC E }
   $1E:SetE(NextPcb); { LD E,n }
   $1F:RRA; { RRA }
   $20:Begin { JR NZ dis }
    If Not(Flags.Zero)Then Begin
     d:=NextPcb;
     If(d And 128)=128 Then d:=-(256-d);
     regPC:=((regPC+d)And $FFFF);
    End
     Else
    regPC:=Inc16(regPC);
   End;
   $21:Reg.HL:=NextPcw; { LD HL,nn }
   $22:memStoreWord(NextPcw,Reg.HL); { LD (nn),HL }
   $23:Reg.HL:=inc16(Reg.HL); { INC HL }
   $24:setH(inc8(getH)); { INC H }
   $25:setH(dec8(getH)); { DEC H }
   $26:setH(NextPcb); { LD H,n }
   $27:DaaA; { DAA }
   $28:Begin { JR Z dis }
    If Flags.Zero Then Begin
     d:=NextPcb;
     If(d And 128)=128 Then d := -(256 - d);
     regPC:=((regPC+d) And $FFFF);
    End
     Else
    regPC:=inc16(regPC);
   End;
   $29:Reg.HL:=add16(Reg.HL,Reg.HL); { ADD HL,HL }
   $2A:Reg.HL:=memReadWord(NextPcw); { LD HL,(nn) }
   $2B:Reg.HL:=dec16(Reg.HL); { DEC HL }
   $2C:SetL(inc8(getL)); { INC L }
   $2D:SetL(dec8(getL)); { DEC L }
   $2E:SetL(NextPcb); { LD L,n }
   $2F:Begin { CPL }
    Reg.A:=(Reg.A Xor $FF) And $FF;
    Flags.f3:=(Reg.A And Flags3)<>0;
    Flags.f5:=(Reg.A And Flags5)<>0;
    Flags.H:=True;
    Flags.N:=True;
   End;
   $30:Begin { JR NC dis }
    If Not(Flags.Carry)Then Begin
     d:=NextPcb;
     If(d And 128)=128 Then d:=-(256 - d);
     regPC:=((regPC+d)And $FFFF);
    End
     Else
    regPC:=inc16(regPC);
   End;
   $31:regSP:=NextPcw; { LD SP,nn }
   $32:memStoreByte(NextPcw,Reg.A); { LD (nn),A }
   $33:regSP:=inc16(regSP); { INC SP }
   $34:memStoreByte(Reg.HL,inc8(memReadByte(Reg.HL))); { INC (HL) }
   $35:memStoreByte(Reg.HL,dec8(memReadByte(Reg.HL))); { DEC (HL) }
   $36:memStoreByte(Reg.HL,NextPcb); { LD (HL),n }
   $37:Begin { SCF }
    Flags.f3:=(Reg.A And Flags3)<>0;
    Flags.f5:=(Reg.A And Flags5)<>0;
    Flags.N:=False;
    Flags.H:=False;
    Flags.Carry:=True;
   End;
   $38:Begin { JR C dis }
    If Flags.Carry Then Begin
     d:=NextPcb;
     If(d And 128)=128 Then d:=-(256-d);
     regPC:=((regPC + d)and $FFFF);
    End
     Else
    regPC:=inc16(regPC);
   End;
   $39:Reg.HL:=Add16(Reg.HL,regSP); { ADD HL,SP}
   $3A:Reg.A:=memReadByte(NextPcw); { LD A,(nn) }
   $3B:regSP:=dec16(regSP); { DEC SP }
   $3C:Reg.A:=inc8(Reg.A); { INC A }
   $3D:Reg.A:=dec8(Reg.A); { DEC A }
   $3E:Reg.A:=NextPcb; { LD A,n }
   $3F:Begin { CCF }
    Flags.f3:=(Reg.A And Flags3)<>0;
    Flags.f5:=(Reg.A And Flags5)<>0;
    Flags.H:=Flags.Carry;
    Flags.N:=False;
    Flags.Carry:=Not Flags.Carry;
   End;
   $40:; { LD B,B }
   $41:Reg.B:=Reg.C; { LD B,C }
   $42:Reg.B:=getD; { LD B,D }
   $43:Reg.B:=getE; { LD B,E }
   $44:Reg.B:=getH; { LD B,H }
   $45:Reg.B:=getL; { LD B,L }
   $46:Reg.B:=memReadByte(Reg.HL); { LD B,(HL) }
   $47:Reg.B:=Reg.A; { LD B,A }
   $48:Reg.C:=Reg.B; { LD C,B }
   $49:; { LD C,C }
   $4A:Reg.C:=getD; { LD C,D }
   $4B:Reg.C:=getE; { LD C,E }
   $4C:Reg.C:=getH; { LD C,H }
   $4D:Reg.C:=getL; { LD C,L }
   $4E:Reg.C:=memReadByte(Reg.HL); { LD C,(HL) }
   $4F:Reg.C:=Reg.A; { LD C,A }
   $50:setD(Reg.B); { LD D,B }
   $51:setD(Reg.C); { LD D,C }
   $52:; { LD D,D }
   $53:SetD(getE); { LD D,E }
   $54:SetD(getH); { LD D,H }
   $55:SetD(getL); { LD D,L }
   $56:SetD(memReadByte(Reg.HL)); { LD D,(HL) }
   $57:SetD(Reg.A); { LD D,A }
   $58:SetE(Reg.B); { LD E,B }
   $59:SetE(Reg.C); { LD E,C }
   $5A:SetE(getD); { LD E,D }
   $5B:; { LD E,E }
   $5C:SetE(getH); { LD E,H }
   $5D:SetE(getL); { LD E,L }
   $5E:SetE(memReadByte(Reg.HL)); { LD E,(HL) }
   $5F:SetE(Reg.A); { LD E,A }
   $60:SetH(Reg.B); { LD H,B }
   $61:SetH(Reg.C); { LD H,C }
   $62:SetH(getD); { LD H,D }
   $63:SetH(getE); { LD H,E }
   $64:; { LD H,H }
   $65:SetH(getL); { LD H,L }
   $66:SetH(memReadByte(Reg.HL)); { LD H,(HL) }
   $67:SetH(Reg.A); { LD H,A }
   $68:SetL(Reg.B); { LD L,B }
   $69:SetL(Reg.C); { LD L,C }
   $6A:SetL(getD); { LD L,D }
   $6B:SetL(getE); { LD L,E }
   $6C:SetL(getH); { LD L,H }
   $6D:; { LD L,L }
   $6E:SetL(memReadByte(Reg.HL)); { LD L,(HL) }
   $6F:SetL(Reg.A); { LD L,A }
   $70:memStoreByte(Reg.HL,Reg.B); { LD (HL),B }
   $71:memStoreByte(Reg.HL,Reg.C); { LD (HL),C }
   $72:memStoreByte(Reg.HL,getD); { LD (HL),D }
   $73:memStoreByte(Reg.HL,getE); { LD (HL),E }
   $74:memStoreByte(Reg.HL,getH); { LD (HL),H }
   $75:memStoreByte(Reg.HL,getL); { LD (HL),L }
   $76:Begin { HALT }
    WriteLn('Instruction HALT ! ');
    Halt;
   End;
   $77:memStoreByte(Reg.HL,Reg.A); { LD (HL),A }
   $78:Reg.A:=Reg.B; { LD A,B }
   $79:Reg.A:=Reg.C; { LD A,C }
   $7A:Reg.A:=getD; { LD A,D }
   $7B:Reg.A:=getE; { LD A,E }
   $7C:Reg.A:=getH; { LD A,H }
   $7D:Reg.A:=getL; { LD A,L }
   $7E:Reg.A:=memReadByte(Reg.HL); { LD A,(HL) }
   $7F:; { LD A,A }
   $80:AddA(Reg.B); { ADD A,B }
   $81:AddA(Reg.C); { ADD A,C }
   $82:AddA(getD); { ADD A,D }
   $83:AddA(getE); { ADD A,E }
   $84:AddA(getH); { ADD A,H }
   $85:AddA(getL); { ADD A,L }
   $86:AddA(memReadByte(Reg.HL)); { ADD A,(HL) }
   $87:AddA(Reg.A); { ADD A,A }
   $88:AdcA(Reg.B); { ADC A,B }
   $89:AdcA(Reg.C); { ADC A,C }
   $8A:AdcA(getD); { ADC A,D }
   $8B:AdcA(getE); { ADC A,E }
   $8C:AdcA(getH); { ADC A,H }
   $8D:AdcA(getL); { ADC A,L }
   $8E:AdcA(memReadByte(Reg.HL)); { ADC A,(HL) }
   $8F:AdcA(Reg.A); { ADC A,A }
   $90:SubA(Reg.B); { SUB B }
   $91:SubA(Reg.C); { SUB C }
   $92:SubA(getD); { SUB D }
   $93:SubA(getE); { SUB E }
   $94:SubA(getH); { SUB H }
   $95:SubA(getL); { SUB L }
   $96:SubA(memReadByte(Reg.HL)); { SUB (HL) }
   $97:SubA(Reg.A); { SUB A }
   $98:SbcA(Reg.B); { SBC A,B }
   $99:SbcA(Reg.C); { SBC A,C }
   $9A:SbcA(getD); { SBC A,D }
   $9B:SbcA(getE); { SBC A,E }
   $9C:SbcA(getH); { SBC A,H }
   $9D:SbcA(getL); { SBC A,L }
   $9E:SbcA(memReadByte(Reg.HL)); { SBC A,(HL) }
   $9F:SbcA(Reg.A); { SBC A,A }
   $A0:AndA(Reg.B); { AND B }
   $A1:AndA(Reg.C); { AND C }
   $A2:AndA(getD); { AND D }
   $A3:AndA(getE); { AND E }
   $A4:AndA(getH); { AND H }
   $A5:AndA(getL); { AND L }
   $A6:AndA(memReadByte(Reg.HL)); { AND (HL) }
   $A7:AndA(Reg.A); { AND A }
   $A8:XorA(Reg.B); { XOR B }
   $A9:XorA(Reg.C); { XOR C }
   $AA:XorA(getD); { XOR D }
   $AB:XorA(getE); { XOR E }
   $AC:XorA(getH); { XOR H }
   $AD:XorA(getL); { XOR L }
   $AE:XorA(memReadByte(Reg.HL)); { XOR (HL) }
   $AF:Begin { XOR A }
    Reg.A:=0;
    Flags.S:=False;
    Flags.f3:=False;
    Flags.f5:=False;
    Flags.H:=False;
    Flags.PV:=True;
    Flags.Zero:=True;
    Flags.N:=False;
    Flags.Carry:=False;
   End;
   $B0:OrA(Reg.B); { OR B }
   $B1:OrA(Reg.C); { OR C }
   $B2:OrA(getD); { OR D }
   $B3:OrA(getE); { OR E }
   $B4:OrA(getH); { OR H }
   $B5:OrA(getL); { OR L }
   $B6:OrA(memReadByte(Reg.HL)); { OR (HL) }
   $B7:OrA(Reg.A); { OR A }
   $B8:CpA(Reg.B); { CP B }
   $B9:CpA(Reg.C); { CP C }
   $BA:CpA(getD); { CP D }
   $BB:CpA(getE); { CP E }
   $BC:CpA(getH); { CP H }
   $BD:CpA(getL); { CP L }
   $BE:CpA(memReadByte(Reg.HL)); { CP (HL) }
   $BF:CpA(Reg.A); { CP A }
   $C0:If Not(Flags.Zero)Then poppc; { RET NZ }
   $C1:SetBC(popw); { POP BC }
   $C2:Begin { JP NZ,nn }
    If Not(Flags.Zero)Then regPC:=NextPcw
                      Else regPC:=regPC+2;
   End;
   $C3:regPC:=memReadWord(regPC); { JP nn }
   $C4:Begin { CALL NZ,nn }
    If Not(Flags.Zero)Then Begin
     lTemp:=NextPcw;
     PushWord(regPC);
     regPC:=lTemp;
    End
     Else
    regPC:=regPC+2;
   End;
   $C5:PushWord(getBC); { PUSH BC }
   $C6:AddA(NextPcb); { ADD A,n }
   $C7:Begin { RST 0 }
    pushpc;
    regPC:=0;
   End;
   $C8:If Flags.Zero Then poppc; { RET Z }
   $C9:poppc; { RET }
   $CA:Begin { JP Z,nn }
    If Flags.Zero Then regPC:=NextPcw
                  Else regPC:=regPC+2;
   End;
   $CB:ExecCB; { pr‚fixe CB }
   $CC:Begin { CALL Z,nn }
    If Flags.Zero Then Begin
     lTemp:=NextPcw;
     PushWord(regPC);
     regPC:=lTemp;
    End
     Else
    regPC:=regPC+2;
   End;
   $CD:Begin { CALL nn }
    lTemp:=NextPcw;
    PushWord(regPC);
    regPC:=lTemp;
   End;
   $CE:AdcA(NextPcb); { ADC A,n }
   $CF:Begin { RST 08h }
    pushpc;
    regPC:=8;
   End;
   $D0:If Not(Flags.Carry)Then poppc; { RET NC }
   $D1:Reg.DE:=popw; { POP DE }
   $D2:Begin { JP NC,nn }
    If Not(Flags.Carry)Then regPC:=NextPcw
                       Else regPC:=regPC+2;
   End;
   $D3:outb(NextPcb,Reg.A); { OUT (n),A }
   $D4:Begin { CALL NC,nn }
    If Not(Flags.Carry)Then Begin
     lTemp:=NextPcw;
     PushWord(regPC);
     regPC:=lTemp;
    End
     Else
    regPC:=regPC+2;
   End;
   $D5:PushWord(Reg.DE); { PUSH DE }
   $D6:SubA(NextPcb); { SUB n }
   $D7:Begin { RST 10h }
    pushpc;
    regPC:=16;
   End;
   $D8:If Flags.Carry Then poppc; { RET C }
   $D9:exx; { EXX }
   $DA:Begin { JP C,nn }
    If Flags.Carry Then regPC:=NextPcw
                   Else regPC:=regPC+2;
   End;
   $DB:Reg.A:=inb((Reg.A shl 8) Or NextPcb); { IN A,(n) }
   $DC:Begin { CALL C,nn }
    If Flags.Carry Then Begin
     lTemp:=NextPcw;
     PushWord(regPC);
     regPC:=lTemp;
    End
     Else
    regPC:=regPC+2;
   End;
   $DD:Begin { pr‚fixe IX }
    regID:=regIX;
    ExecuteId;
    regIX:=regID;
   End;
   $DE:SbcA(NextPcb); { SBC n }
   $DF:Begin { RST 18h }
    pushpc;
    regPC:=24;
   End;
   $E0:If Not(Flags.PV)Then poppc; { RET PO }
   $E1:Reg.HL:=popw; { POP HL }
   $E2:Begin { JP PO,nn }
    If Not(Flags.PV)Then regPC:=NextPcw
                    Else regPC:=regPC+2;
   End;
   $E3:Begin { EX (SP),HL }
    lTemp:=Reg.HL;
    Reg.HL:=memReadWord(regSP);
    memStoreWord(regSP,lTemp);
   End;
   $E4:Begin { CALL PO,nn }
    If Not(Flags.PV)Then Begin
     lTemp:=NextPcw;
     PushWord(regPC);
     regPC:=lTemp;
    End
     Else
    regPC:=regPC+2;
   End;
   $E5:PushWord(Reg.HL); { PUSH HL }
   $E6:AndA(NextPcb); { AND n }
   $E7:Begin { RST 32 }
    pushpc;
    regPC:=32;
   End;
   $E8:If Flags.PV Then poppc; { RET PE }
   $E9:regPC:=Reg.HL; { JP HL }
   $EA:Begin { JP PE,nn }
    If Flags.PV Then regPC:=NextPcw
           Else regPC:=regPC+2;
   End;
   $EB:Begin { EX DE,HL }
    lTemp:=Reg.HL;
    Reg.HL:=Reg.DE;
    Reg.DE:=lTemp;
   End;
   $EC:Begin { CALL PE,nn }
    If Flags.PV Then Begin
     lTemp:=NextPcw;
     PushWord(regPC);
     regPC:=lTemp;
    End
     Else
    regPC:=regPC+2;
   End;
   $ED:ExecuteED; { prefix ED }
   $EE:XorA(NextPcb); { XOR n }
   $EF:Begin { RST 28h }
    pushpc;
    regPC:=40;
   End;
   $F0:If Not(Flags.S)Then poppc; { RET P }
   $F1:setAF(popw); { POP AF }
   $F2:Begin { JP P,nn }
    If Not(Flags.S)Then regPC:=NextPcw
                   Else regPC:=regPC+2;
   End;
   $F3:Begin { DI }
    intIFF1:=False;
    intIFF2:=False;
   End;
   $F4:Begin { CALL P,nn }
    If Not(Flags.S)Then Begin
     lTemp:=NextPcw;
     PushWord(regPC);
     regPC:=lTemp;
    End
     Else
    regPC:=regPC+2;
   End;
   $F5:PushWord(getAF); { PUSH AF }
   $F6:OrA(NextPcb); { OR n }
   $F7:Begin { RST 48 }
    pushpc;
    regPC:=48;
   End;
   $F8:If Flags.S Then poppc; { RET M }
   $F9:regSP:=Reg.HL; { LD SP,HL }
   $FA:Begin { JP M,nn }
    If Flags.S Then regPC:=NextPcw
               Else regPC:=regPC+2;
   End;
   $FB:Begin { EI }
    intIFF1:=True;
    intIFF2:=True;
   End;
   $FC:Begin { CALL M,nn }
    If Flags.S Then Begin
     lTemp:=NextPcw;
     PushWord(regPC);
     regPC:=lTemp;
    End
     Else
    regPC:=regPC+2;
   End;
   $FD:Begin { pr‚fixe IY }
    regID:=regIY;
    ExecuteId;
    regIY:=regID;
   End;
   $FE:CpA(NextPcb); { CP n }
   $FF:Begin { RST 38h }
    pushpc;
    regPC:=56;
   End;
   Else Begin
    WriteLn('Instruction inconnu ',memReadByte(regPC)+(memReadByte(regPC+1) shl 8),' a ',regPC);
    Halt;
   End;
  End;
  Inc(intR);
  intR:=intR and $7F;
 Until(intCtrTemp<>InterruptCounter)or CpuPaused;
End;

Var
 I,ByteReaded:Integer;
 FileLoad:File {$IFDEF FPC}of Byte{$ENDIF};

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('RUNZ80 : Cette commande permet d''executer du code du microprocesseur Z80.');
  WriteLn;
  WriteLn('Syntaxe : RUNZ80 [nomdufichier.bin] [/DEBUG] [/VERBOSE]');
 End
  Else
 Begin
  FillChar(memory,SizeOf(memory),0);
  Verbose:=False;
  DebugOn:=False;
  interruptCounter:=0;
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='/DEBUG'Then DebugOn:=True Else
   If(ParamStr(I)='/VERBOSE')or(ParamStr(I)='/V')Then Verbose:=True
    Else
   Begin
    If(Verbose)Then WriteLn('Chargement du fichier binaire ',ParamStr(I),' dans la RAM du 6502.');
    Assign(FileLoad,ParamStr(I));
    Reset(FileLoad);
    Seek(FileLoad,0);
    BlockRead(FileLoad,Memory[0],SizeOf(Memory),ByteReaded);
    Close(FileLoad);
   End;
  End;
  If(Verbose)Then WriteLn('Initialisation de l''emulateur');
  InitEmul;
  If(Verbose)Then WriteLn('Lancement de l''emulation');
  Repeat
   ExecEmul;
  Until CpuPaused;
 End;
END.
