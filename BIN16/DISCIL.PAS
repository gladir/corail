{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program DISCIL;

Type
 OpCodeRec=Record
  Opcode:Byte;
  Name:String[15];
  OperandCount:Byte;
  IsBranch:Boolean;
  HasArgList:Boolean;
  IsTwoByteOpCode:Boolean;
 end;

Const
 OpCodeCIL:Array[0..191]of OpCodeRec=(
  (Opcode:$00;Name:'nop';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$01;Name:'break';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$02;Name:'ldarg.0';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$03;Name:'ldarg.1';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$04;Name:'ldarg.2';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$05;Name:'ldarg.3';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$06;Name:'ldloc.0';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$07;Name:'ldloc.1';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$08;Name:'ldloc.2';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$09;Name:'ldloc.3';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$0A;Name:'stloc.0';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$0B;Name:'stloc.1';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$0C;Name:'stloc.2';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$0D;Name:'stloc.3';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$0E;Name:'ldarg.s';OperandCount:1;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$0F;Name:'ldarga.s';OperandCount:1;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$10;Name:'starg.s';OperandCount:1;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$11;Name:'ldloc.s';OperandCount:1;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$12;Name:'ldloca.s';OperandCount:1;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$13;Name:'stloc.s';OperandCount:1;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$14;Name:'ldnull';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$15;Name:'ldc.i4.m1';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$16;Name:'ldc.i4.0';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$17;Name:'ldc.i4.1';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$18;Name:'ldc.i4.2';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$19;Name:'ldc.i4.3';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$1A;Name:'ldc.i4.4';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$1B;Name:'ldc.i4.5';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$1C;Name:'ldc.i4.6';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$1D;Name:'ldc.i4.7';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$1E;Name:'ldc.i4.8';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$1F;Name:'ldc.i4.s';OperandCount:1;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$20;Name:'ldc.i4';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$21;Name:'ldc.i8';OperandCount:8;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$22;Name:'ldc.r4';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$23;Name:'ldc.r8';OperandCount:8;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$25;Name:'dup';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$26;Name:'pop';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$27;Name:'jmp';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$28;Name:'call';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$29;Name:'calli';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$2A;Name:'ret';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$2B;Name:'br.s';OperandCount:1;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$2C;Name:'brfalse.s';OperandCount:1;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$2D;Name:'brtrue.s';OperandCount:1;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$2E;Name:'beq.s';OperandCount:1;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$2F;Name:'bge.s';OperandCount:1;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$30;Name:'bgt.s';OperandCount:1;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$31;Name:'ble.s';OperandCount:1;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$32;Name:'blt.s';OperandCount:1;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$33;Name:'bne.un.s';OperandCount:1;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$34;Name:'bge.un.s';OperandCount:1;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$35;Name:'bgt.un.s';OperandCount:1;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$36;Name:'ble.un.s';OperandCount:1;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$37;Name:'blt.un.s';OperandCount:1;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$38;Name:'br';OperandCount:4;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$39;Name:'brfalse';OperandCount:4;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$3A;Name:'brtrue';OperandCount:4;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$3B;Name:'beq';OperandCount:4;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$3C;Name:'bge';OperandCount:4;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$3D;Name:'bgt';OperandCount:4;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$3E;Name:'ble';OperandCount:4;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$3F;Name:'blt';OperandCount:4;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$40;Name:'bne.un';OperandCount:4;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$41;Name:'bge.un';OperandCount:4;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$42;Name:'bgt.un';OperandCount:4;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$43;Name:'ble.un';OperandCount:4;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$44;Name:'blt.un';OperandCount:4;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$45;Name:'switch';OperandCount:4;IsBranch:False;HasArgList:True;IsTwoByteOpCode:False),
  (Opcode:$46;Name:'ldind.i1';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$47;Name:'ldind.u1';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$48;Name:'ldind.i2';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$49;Name:'ldind.u2';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$4A;Name:'ldind.i4';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$4B;Name:'ldind.u4';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$4C;Name:'ldind.i8';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$4D;Name:'ldind.i';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$4E;Name:'ldind.r4';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$4F;Name:'ldind.r8';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$50;Name:'ldind.ref';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$51;Name:'stind.ref';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$52;Name:'stind.i1';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$53;Name:'stind.i2';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$54;Name:'stind.i4';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$55;Name:'stind.i8';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$56;Name:'stind.r4';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$57;Name:'stind.r8';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$58;Name:'add';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$59;Name:'sub';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$5A;Name:'mul';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$5B;Name:'div';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$5C;Name:'div.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$5D;Name:'rem';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$5E;Name:'rem.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$5F;Name:'and';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$60;Name:'or';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$61;Name:'xor';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$62;Name:'shl';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$63;Name:'shr';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$64;Name:'shr.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$65;Name:'neg';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$66;Name:'not';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$67;Name:'conv.i1';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$68;Name:'conv.i2';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$69;Name:'conv.i4';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$6A;Name:'conv.i8';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$6B;Name:'conv.r4';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$6C;Name:'conv.r8';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$6D;Name:'conv.u4';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$6E;Name:'conv.u8';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$6F;Name:'callvirt';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$70;Name:'cpobj';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$71;Name:'ldobj';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$72;Name:'ldstr';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$73;Name:'newobj';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$74;Name:'castclass';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$75;Name:'isinst';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$76;Name:'conv.r.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$79;Name:'unbox';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$7A;Name:'throw';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$7B;Name:'ldfld';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$7C;Name:'ldflda';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$7D;Name:'stfld';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$7E;Name:'ldsfld';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$7F;Name:'ldsflda';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$80;Name:'stsfld';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$81;Name:'stobj';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$82;Name:'conv.ovf.i1.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$83;Name:'conv.ovf.i2.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$84;Name:'conv.ovf.i4.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$85;Name:'conv.ovf.i8.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$86;Name:'conv.ovf.u1.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$87;Name:'conv.ovf.u2.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$88;Name:'conv.ovf.u4.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$89;Name:'conv.ovf.u8.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$8A;Name:'conv.ovf.i.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$8B;Name:'conv.ovf.u.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$8C;Name:'box';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$8D;Name:'newarr';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$8E;Name:'ldlen';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$8F;Name:'ldelema';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$90;Name:'ldelem.i1';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$91;Name:'ldelem.u1';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$92;Name:'ldelem.i2';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$93;Name:'ldelem.u2';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$94;Name:'ldelem.i4';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$95;Name:'ldelem.u4';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$96;Name:'ldelem.i8';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$97;Name:'ldelem.i';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$98;Name:'ldelem.r4';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$99;Name:'ldelem.r8';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$9A;Name:'ldelem.ref';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$9B;Name:'stelem.i';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$9C;Name:'stelem.i1';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$9D;Name:'stelem.i2';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$9E;Name:'stelem.i4';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$9F;Name:'stelem.i8';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$A0;Name:'stelem.r4';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$A1;Name:'stelem.r8';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$A2;Name:'stelem.ref';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$A3;Name:'ldelem';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$A4;Name:'stelem';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$A5;Name:'unbox.any';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$B3;Name:'conv.ovf.i1';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$B4;Name:'conv.ovf.u1';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$B5;Name:'conv.ovf.i2';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$B6;Name:'conv.ovf.u2';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$B7;Name:'conv.ovf.i4';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$B8;Name:'conv.ovf.u4';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$B9;Name:'conv.ovf.i8';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$BA;Name:'conv.ovf.u8';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$C2;Name:'refanyval';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$C3;Name:'ckfinite';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$C6;Name:'mkrefany';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$D0;Name:'ldtoken';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$D1;Name:'conv.u2';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$D2;Name:'conv.u1';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$D3;Name:'conv.i';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$D4;Name:'conv.ovf.i';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$D5;Name:'conv.ovf.u';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$D6;Name:'add.ovf';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$D7;Name:'add.ovf.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$D8;Name:'mul.ovf';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$D9;Name:'mul.ovf.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$DA;Name:'sub.ovf';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$DB;Name:'sub.ovf.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$DC;Name:'endfinally';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$DD;Name:'leave';OperandCount:4;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$DE;Name:'leave.s';OperandCount:1;IsBranch:True;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$DF;Name:'stind.i';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$E0;Name:'conv.u';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$FE;Name:'';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:True)
 );

 OpCode2CIL:Array[0..27]of OpCodeRec=(
  (Opcode:$00;Name:'arglist';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$01;Name:'ceq';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$02;Name:'cgt';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$03;Name:'cgt.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$04;Name:'clt';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$05;Name:'clt.un';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$16;Name:'constrained.';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$17;Name:'cpblk';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$11;Name:'endfilter';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$18;Name:'initblk';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$15;Name:'Initobj';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$09;Name:'ldarg';OperandCount:2;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$0A;Name:'ldarga';OperandCount:2;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$06;Name:'ldftn';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$0C;Name:'ldloc';OperandCount:2;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$0D;Name:'ldloca';OperandCount:2;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$07;Name:'ldvirtftn';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$0F;Name:'localloc';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$19;Name:'no.';OperandCount:1;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$1E;Name:'readonly.';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$1D;Name:'Refanytype';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$1A;Name:'rethrow';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$1C;Name:'sizeof';OperandCount:4;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$0B;Name:'starg';OperandCount:2;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$0E;Name:'stloc';OperandCount:2;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$14;Name:'tail.';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$12;Name:'unaligned.';OperandCount:1;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False),
  (Opcode:$13;Name:'volatile.';OperandCount:0;IsBranch:False;HasArgList:False;IsTwoByteOpCode:False)
 );

Var
 FileBIN:File;
 RawMode:Boolean;
 Pos,ByteReaded:Word;
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

Function WordToStr(X:Word):String;
Var
 S:String;
Begin
 Str(X,S);
 WordToStr:=S;
End;

Function IntToStr(X:Word):String;
Var
 S:String;
Begin
 Str(X,S);
 IntToStr:=S;
End;

Function LongToStr(L:LongInt):String;
Var
 S:String;
Begin
 Str(L,S);
 LongToStr:=S;
End;

Function LongHex2Str(value:LongInt):String;
Begin
 LongHex2Str:=ByteHex2Str((value shr 24)and $FF)+
              ByteHex2Str((value shr 16)and $FF)+
              ByteHex2Str((value shr 8)and $FF)+
              ByteHex2Str(value and $FF);
End;

Function Decode(Var Buf;Var I:Word):String;
Var
 T:Array[0..65520] of Byte Absolute Buf;
 Found:Boolean;
 S:String;
 J,J2,OpcodeData:Byte;

 Function GetLongInt:LongInt;Begin
  GetLongInt:=LongInt((T[I+3] shl 24)+(T[I+2] shl 16)+(T[I+1] shl 8)+T[I]);
  Inc(I,4);
 End;

Begin
 S:='';
 OpcodeData:=T[I];
 Found:=False;
 For J:=0 to High(OpCodeCIL)do Begin
  If(OpCodeCIL[J].Opcode=OpcodeData)Then Begin
   If(OpCodeCIL[J].IsTwoByteOpCode)Then Begin
    OpcodeData:=T[I+1];
    For J2:=0 to High(OpCode2CIL)do Begin
     If(OpCode2CIL[J2].IsTwoByteOpCode)Then Begin
      Found:=True;
      S:=OpCode2CIL[J2].Name;
      Inc(I,2);
      Inc(I,Opcode2CIL[J2].OperandCount*2);
      Break;
     End;
    End;
    If(Found)Then Break;
   End
    Else
   Begin
    Found:=True;
    S:=OpCodeCIL[J].Name;
    Inc(I);
    Case OpcodeCIL[J].OperandCount of
     8:S:=S+' '+LongHex2Str(GetLongInt)+LongHex2Str(GetLongInt)+'h';
     4:S:=S+' '+LongHex2Str(GetLongInt)+'h';
     Else Inc(I,OpcodeCIL[J].OperandCount);
    End;
   End;
   Break;
  End;
 End;
 If Not(Found)Then Begin
  S:='DB '+HexByte(OpcodeData);
  Inc(I);
 End;
 Decode:=S;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('DISCIL : Cette commande permet de d‚sassembleur un code binaire de');
  WriteLn('          CIL en langage de programmation assembleur CIL.');
  WriteLn;
  WriteLn('Syntaxe : DISCIL nomdufichier');
  WriteLn;
  WriteLn(' nomduficher           Nom du fichier binaire');
 End
  Else
 If ParamCount>0 Then Begin
  RawMode:=False;
  {$I-}Assign(FileBIN,ParamStr(1));
  Reset(FileBIN,1);{$I+}
  If IOResult=0 Then Begin
   FPos:=0;
   While FPos<FileSize(FileBIN)do Begin
    BlockRead(FileBIN,BinBuffer,SizeOf(BinBuffer),ByteReaded);
    If ByteReaded=0 Then Break;
    Pos:=0;
    If ByteReaded<15 Then Begin
     While(Pos<ByteReaded)do Begin
      Write(HexWord2Str(Pos),'h ');
      DisStr:=Decode(BinBuffer,Pos);
      WriteLn(DisStr);
     End;
     Break;
    End
     Else
    Begin
     While(Pos<ByteReaded-15)do Begin
      Write(LongHex2Str(FPos+Pos),'h ');
      DisStr:=Decode(BinBuffer,Pos);
      WriteLn(DisStr);
     End;
    End;
    Inc(FPos,Pos);
   End;
   Close(FileBIN);
  End
   Else
  WriteLn('Impossible de lire le fichier ',ParamStr(1));
 End;
END.

