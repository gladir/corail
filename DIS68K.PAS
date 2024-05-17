{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program DIS68K;

{$A-,R-}

Type
 OpcodeDetails=Record
  AndOpcode:Word;
  XorOpcode:Word;
 End;

Const
 BraTab:Array[0..15]of String[3]=(
  'BRA','BSR','BHI','BLS','BCC','BCS','BNE','BEQ',
  'BVC','BVS','BPL','BMI','BGE','BLT','BGT','BLE'
 );

 SccTab:Array[0..15]of String[3]=(
  'ST','SF','SHI','SLS','SCC','SCS','SNE','SEQ',
  'SVC','SVS','SPL','SMI','SGE','SLT','SGT','SLE'
 );


 OpTab:Array[0..87]of OpcodeDetails=(
  (AndOpcode:$0000;XorOpcode:$0000),
  (AndOpcode:$F1F0;XorOpcode:$C100),
  (AndOpcode:$F000;XorOpcode:$D000),
  (AndOpcode:$F0C0;XorOpcode:$D0C0),
  (AndOpcode:$FF00;XorOpcode:$0600),
  (AndOpcode:$F100;XorOpcode:$5000),
  (AndOpcode:$F130;XorOpcode:$D100),
  (AndOpcode:$F000;XorOpcode:$C000),
  (AndOpcode:$FF00;XorOpcode:$0200),
  (AndOpcode:$F118;XorOpcode:$E100),
  (AndOpcode:$FFC0;XorOpcode:$E1C0),
  (AndOpcode:$F118;XorOpcode:$E000),
  (AndOpcode:$FFC0;XorOpcode:$E0C0),
  (AndOpcode:$F000;XorOpcode:$6000),
  (AndOpcode:$F1C0;XorOpcode:$0140),
  (AndOpcode:$FFC0;XorOpcode:$0840),
  (AndOpcode:$F1C0;XorOpcode:$0180),
  (AndOpcode:$FFC0;XorOpcode:$0880),
  (AndOpcode:$F1C0;XorOpcode:$01C0),
  (AndOpcode:$FFC0;XorOpcode:$08C0),
  (AndOpcode:$F1C0;XorOpcode:$0100),
  (AndOpcode:$FFC0;XorOpcode:$0800),
  (AndOpcode:$F1C0;XorOpcode:$4180),
  (AndOpcode:$FF00;XorOpcode:$4200),
  (AndOpcode:$F100;XorOpcode:$B000),
  (AndOpcode:$F0C0;XorOpcode:$B0C0),
  (AndOpcode:$FF00;XorOpcode:$0C00),
  (AndOpcode:$F138;XorOpcode:$B108),
  (AndOpcode:$F0F8;XorOpcode:$50C8),
  (AndOpcode:$F1C0;XorOpcode:$81C0),
  (AndOpcode:$F1C0;XorOpcode:$80C0),
  (AndOpcode:$F100;XorOpcode:$B100),
  (AndOpcode:$FF00;XorOpcode:$0A00),
  (AndOpcode:$F100;XorOpcode:$C100),
  (AndOpcode:$FFB8;XorOpcode:$4880),
  (AndOpcode:$FFC0;XorOpcode:$4EC0),
  (AndOpcode:$FFC0;XorOpcode:$4E80),
  (AndOpcode:$F1C0;XorOpcode:$41C0),
  (AndOpcode:$FFF8;XorOpcode:$4E50),
  (AndOpcode:$F118;XorOpcode:$E108),
  (AndOpcode:$FFC0;XorOpcode:$E3C0),
  (AndOpcode:$F118;XorOpcode:$E008),
  (AndOpcode:$FFC0;XorOpcode:$E2C0),
  (AndOpcode:$C000;XorOpcode:$0000),
  (AndOpcode:$FFC0;XorOpcode:$44C0),
  (AndOpcode:$FFC0;XorOpcode:$46C0),
  (AndOpcode:$FFC0;XorOpcode:$40C0),
  (AndOpcode:$FFF0;XorOpcode:$4E60),
  (AndOpcode:$C1C0;XorOpcode:$0040),
  (AndOpcode:$FB80;XorOpcode:$4880),
  (AndOpcode:$F138;XorOpcode:$0108),
  (AndOpcode:$F100;XorOpcode:$7000),
  (AndOpcode:$F1C0;XorOpcode:$C1C0),
  (AndOpcode:$F1C0;XorOpcode:$C0C0),
  (AndOpcode:$FFC0;XorOpcode:$4800),
  (AndOpcode:$FF00;XorOpcode:$4400),
  (AndOpcode:$FF00;XorOpcode:$4000),
  (AndOpcode:$FFFF;XorOpcode:$4E71),
  (AndOpcode:$FF00;XorOpcode:$4600),
  (AndOpcode:$F000;XorOpcode:$8000),
  (AndOpcode:$FF00;XorOpcode:$0000),
  (AndOpcode:$FFC0;XorOpcode:$4840),
  (AndOpcode:$FFFF;XorOpcode:$4E70),
  (AndOpcode:$F118;XorOpcode:$E118),
  (AndOpcode:$FFC0;XorOpcode:$E7C0),
  (AndOpcode:$F118;XorOpcode:$E018),
  (AndOpcode:$FFC0;XorOpcode:$E6C0),
  (AndOpcode:$F118;XorOpcode:$E110),
  (AndOpcode:$FFC0;XorOpcode:$E5C0),
  (AndOpcode:$F118;XorOpcode:$E010),
  (AndOpcode:$FFC0;XorOpcode:$E4C0),
  (AndOpcode:$FFFF;XorOpcode:$4E73),
  (AndOpcode:$FFFF;XorOpcode:$4E77),
  (AndOpcode:$FFFF;XorOpcode:$4E75),
  (AndOpcode:$F1F0;XorOpcode:$8100),
  (AndOpcode:$F0C0;XorOpcode:$50C0),
  (AndOpcode:$FFFF;XorOpcode:$4E72),
  (AndOpcode:$F000;XorOpcode:$9000),
  (AndOpcode:$F0C0;XorOpcode:$90C0),
  (AndOpcode:$FF00;XorOpcode:$0400),
  (AndOpcode:$F100;XorOpcode:$5100),
  (AndOpcode:$F130;XorOpcode:$9100),
  (AndOpcode:$FFF8;XorOpcode:$4840),
  (AndOpcode:$FFC0;XorOpcode:$4AC0),
  (AndOpcode:$FFF0;XorOpcode:$4E40),
  (AndOpcode:$FFFF;XorOpcode:$4E76),
  (AndOpcode:$FF00;XorOpcode:$4A00),
  (AndOpcode:$FFF8;XorOpcode:$4E58)
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

Function GetMode(Instruction:Word):Word;
Var
 Mode,Reg:Word;
Begin
 Mode:=(Instruction and $0038) shr 3;
 Reg:=Instruction and $0007;
 If(Mode=7)Then Begin
  If(Reg>=5)Then Begin
   GetMode:=12;
   Exit;
  End
   Else
  Begin
   GetMode:=7+Reg;
   Exit;
  End;
 End;
 GetMode:=Mode;
End;

Function Decode(Var Buf;Var I:Word):String;
Const
 SizeArr:Array[0..2]of Char=('B','W','L');
Var
 T:Array[0..65520] of Byte Absolute Buf;
 IsDecoded,Ok:Boolean;
 OpNum:Integer;
 WordInstr,SReg,DReg,AReg,DMode,Size,Dir,SMode,Data,Count,CC,Temp:LongInt;
 I1:Integer;
 Offset:LongInt;
 RList:Array[0..10]of Integer;
 S,OpcodeS,SourceS,DestS:String;

 Function GetWord:Word;Begin
  GetWord:=(T[I] shl 8)+T[I+1];
  Inc(I,2);
 End;

 Function ModeToStr(Mode,Reg,Size:Word):String;
 Const
  IR:Array[0..1]of Char=('W','L');
 Var
  Displacement,LData:LongInt;
  Data,IReg,IType,ISize:Word;
  OutS:String;
 Begin
  OutS:='';
  Case(Mode)of
   0:OutS:='D'+WordToStr(Reg);
   1:OutS:='A'+WordToStr(Reg);
   2:OutS:='(A'+WordToStr(Reg)+')';
   3:OutS:='(A'+WordToStr(Reg)+'+)';
   4:OutS:='-(A'+WordToStr(Reg)+')';
   5,9:Begin
    Displacement:=GetWord;
    If(Displacement>=32768)Then Displacement:=Displacement-65536;
    If(Mode=5)Then OutS:='+'+WordToStr(Displacement)+'(A'+WordToStr(Reg)+')'
     Else
    Begin
     LData:=I-2+Displacement;
     If(Not RawMode)Then OutS:='+'+WordToStr(Displacement)+'(PC) {$'+LongToStr(LData)+'}';
    End;
   End;
   6,10:Begin
    Data:=GetWord;
    Displacement:=(Data and $00FF);
    If(Displacement>=128)Then Displacement:=Displacement-256;
    IReg:=(Data and $7000) shr 12;
    IType:=(Data and $8000);
    ISize:=(Data and $0800) shr 11;
    If(Mode=6)Then Begin
     If(IType=0)Then Begin
      OutS:='+'+LongToStr(Displacement)+'(A'+WordToSTr(Reg)+',D'+WordToStr(IReg)+'.'+IR[ISize]+')';
     End
      Else
     Begin
      OutS:='+'+LongToStr(Displacement)+'(A'+WordToSTr(Reg)+',A'+WordToStr(IReg)+'.'+IR[ISize]+')';
     End;
    End
     Else
    Begin
     IF(IType=0)Then Begin
      OutS:='+'+WordToStr(Displacement)+'(PC,D'+WordToStr(IReg)+'.'+IR[ISize];
     End
      Else
     Begin
      OutS:=OutS+'+'+WordToStr(Displacement)+'(PC,A'+WordToStr(IReg)+'.'+IR[ISize];
     End;
    End;
   End;
   7:OutS:='$0000'+HexWord2Str(GetWord);
   8:OutS:='$'+HexWord2Str(GetWord)+HexWord2Str(GetWord);
   11:Begin
    Data:=GetWord;
    Case(Size)of
     0:OutS:='#$'+ByteHex2Str(Data and $00FF);
     1:OutS:='#$'+HexWord2Str(Data);
     2:OutS:='#$'+HexWord2Str(Data)+HexWord2Str(GetWord);
    End;
   End;
   Else OutS:=' ; Mode en dehors de l''intervalle';
  End;
  ModeToStr:=OutS;
 End;

Begin
 S:='';
 WordInstr:=GetWord;
 IsDecoded:=False;
 For OpNum:=0 to High(OpTab)do Begin
  If((WordInstr and OpTab[OpNum].AndOpcode)=OpTab[OpNum].XorOpcode)Then Begin
   Case(OpNum)of
    1,74:Begin { ABCD + SBCD }
     SReg:=WordInstr and $0007;
     DReg:=(WordInstr and $0E00) shr 9;
     If OpNum=1 Then S:='ABCD'
                Else S:='SBCD';
     S:=S+' ';
     If((WordInstr and $0008)=0)Then Begin
      S:=S+'D'+WordToStr(SReg)+','+WordToStr(DReg);
     End
      Else
     Begin
      S:=S+'-(A'+WordToStr(SReg)+'),-A('+WordToStr(DReg)+')';
     End;
     IsDecoded:=True;
    End;
    2,7,31,59,77:Begin
     DMode:=GetMode(WordInstr);
     DReg:=WordInstr and $0007;
     Size:=(WordInstr and $00C0) shr 6;
     Ok:=True;
     If(Size=3)Then Ok:=False;
     If(OpNum=2)and(Dmode=1)and(Size=0)Then Ok:=False;
     If(OpNum=77)and(Dmode=1)and(Size=0)Then Ok:=False;
     Dir:=(WordInstr and $0100) shr 8;
     If(OpNum=31)and(Dir=0)Then Ok:=False;
     If(Dir=1)and(DMode>=9)Then OK:=False;
     If(Ok)Then Begin
      Case(OpNum)of
       2:S:='ADD.'+SizeArr[Size];
       7:S:='AND.'+SizeArr[Size];
       31:S:='EOR.'+SizeArr[Size];
       59:S:='OR.'+SizeArr[Size];
       77:S:='SUB.'+SizeArr[Size];
      End;
      S:=S+' ';
      DestS:=ModeToStr(DMode,DReg,Size);
      SReg:=(WordInstr and $0E00) shr 9;
      SourceS:='D'+WordToStr(SReg);
      If(Dir<>0)Then S:=S+SourceS+','+DestS
                Else S:=S+DestS+','+SourceS;
      IsDecoded:=True;
     End;
    End;
    3,78:Begin
     SMode:=GetMode(WordInstr);
     SReg:=WordInstr and $0007;
     DReg:=(WordInstr and $0E00) shr 9;
     Size:=((WordInstr and $0100) shr 8)+1;
     Case(OpNum)of
      3:S:='ADDA.'+SizeArr[Size];
      78:S:='SUBA.'+SizeArr[Size];
     End;
     S:=S+' ';
     S:=S+ModeToStr(SMode,SReg,Size)+',A'+WordToStr(SReg);
     IsDecoded:=True;
    End;
    4,8,26,32,60,79:Begin
     DMode:=GetMode(WordInstr);
     DReg:=WordInstr and $0007;
     Size:=(WordInstr and $00C0) shr 6;
     Ok:=True;
     If(Size=3)Then Ok:=False;
     If(DMode=1)Then Ok:=False;
     If((DMode=9)or(DMode=10))Then Ok:=False;
     If(DMode=12)Then Ok:=False;
     If((DMode=11)and((OpNum=4)or(OpNum=26)or(OpNum=79)))Then Ok:=False;
     If(Ok)Then Begin
      Case(OpNum)of
       4:S:='ADDI.'+SizeArr[Size];
       8:S:='ANDI.'+SizeArr[Size];
       26:S:='CMPI.'+SizeArr[Size];
       32:S:='EORI.'+SizeArr[Size];
       60:S:='ORI.'+SizeArr[Size];
       79:S:='SUBI.'+SizeArr[Size];
      End;
      S:=S+' ';
      Data:=GetWord;
      Case(Size)of
       0:S:=S+'#$'+ByteHex2Str(Data and $00FF);
       1:S:=S+'#$'+HexWord2Str(Data);
       2:S:=S+'#$'+HexWord2Str(Data)+HexWord2Str(GetWord);
      End;
      If(DMode=11)Then S:=S+'SR'
                  Else S:=S+ModeToStr(SMode,DReg,Size);
      IsDecoded:=True;
     End;
    End;
    5,80:Begin
     DMode:=GetMode(WordInstr);
     DReg:=WordInstr and $0007;
     Size:=(WordInstr and $00C0) shr 6;
     Ok:=True;
     If(Size=3)Then Ok:=False;
     If(DMode>=9)Then Ok:=False;
     If(Ok)Then Begin
      If(OpNum=5)Then S:='ADDQ.'+SizeArr[Size]
                 Else S:='SUBQ.'+SizeArr[Size];
       S:=S+' ';
      Count:=(WordInstr and $0E00) shr 9;
      If Count=0Then S:=S+'#8,'+ModeToStr(DMode,DReg,Size)
                Else S:=S+'#'+WordToStr(Count)+','+ModeToStr(DMode,DReg,Size);
     End;
    End;
    6,81,27:Begin
     Size:=(WordInstr and $00C0) shr 6;
     Ok:=True;
     If(Size=3)Then Ok:=False;
     If(Ok)Then Begin
      SReg:=WordInstr and $0007;
      DReg:=(WordInstr and $0E00) shr 9;
      Case(OpNum)of
       6:S:='ADDX.'+SizeArr[Size];
       81:S:='SUBX.'+SizeArr[Size];
       27:S:='CMPM.'+SizeArr[Size];
      End;
      S:=S+' ';
      If(OpNum<>27)and((WordInstr and $0008)=0)Then Begin
       S:=S+'D'+WordToStr(SReg)+','+WordToStr(DReg);
      End
       Else
      If(OpNum=27)Then S:=S+'(A'+WordToStr(SReg)+')+,('+WordToStr(DReg)+')+'
                  Else S:=S+'-(A'+WordToStr(SReg)+'),-('+WordToStr(DReg)+')';
      IsDecoded:=True;
     End;
    End;
    9,11,39,41,63,65,67,69:Begin
     DReg:=WordInstr and $0007;
     Size:=(WordInstr and $00C0) shr 6;
     OK:=True;
     If(Size=3)Then Ok:=False;
     If(Ok)Then Begin
      Case(OpNum)of
       9:S:='ASL.'+SizeArr[Size];
       11:S:='ASR.'+SizeArr[Size];
       39:S:='LSL.'+SizeArr[Size];
       41:S:='LSR.'+SizeArr[Size];
       63:S:='ROR.'+SizeArr[Size];
       65:S:='ROL.'+SizeArr[Size];
       67:S:='ROXL.'+SizeArr[Size];
       69:S:='ROXR.'+SizeArr[Size];
      End;
      Count:=(WordInstr and $0E00) shr 9;
      If(((WordInstr and $0020) shr 5)=0)Then Begin
       If(Count=0)Then Count:=8;
        S:=S+' #'+WordToStr(Count)+',D'+WordToStr(WordInstr and $0007);
      End
       Else
      Begin
       S:=S+' D'+WordToStr(Count)+',D'+WordToStr(WordInstr and $0007);
      End;
      IsDecoded:=True;
     End;
    End;
    10,12,40,64,66,68,70:Begin
     DMode:=GetMode(WordInstr);
     DReg:=WordInstr and $0007;
     Ok:=True;
     If((DMode<=1)or(DMode>=9))Then Ok:=False;
     If(Ok)Then Begin
      Case(OpNum)of
       10:S:='ASL';
       12:S:='ASR';
       40:S:='LSL';
       42:S:='LSR';
       64:S:='ROR';
       66:S:='ROL';
       68:S:='ROXL';
       70:S:='ROXR';
      End;
     End;
     S:=S+' '+ModeToStr(DMode,DReg,0);
     IsDecoded:=True;
    End;
    13:Begin
     CC:=(WordInstr and $0F00) shr 8;
     S:=BraTab[CC]+' ';
     Offset:=(WordInstr and $00FF);
     If(Offset<>0)Then Begin
      If(Offset>=128)Then Offset:=Offset-256;
      If(Not RawMode)Then S:=S+'$'+LongHex2Str(I+Offset)
                     Else S:=S+'*'+IntToStr(Offset);
     End;
     IsDecoded:=True;
    End;
    14,15,16,17,18,19,20,21:Begin
     DMode:=GetMode(WordInstr);
     DReg:=WordInstr and $0007;
     Ok:=True;
     If(DMode=1)Then Ok:=False;
     If(DMOde>=11)Then Ok:=False;
     If(OpNum<20)and(DMode<=9)Then Ok:=False;
     If(Ok)Then Begin
      SReg:=(WordInstr and $0E00) shr 9;
      Case(OpNum)of
       14:Begin
        S:='BCHG';
        SourceS:='D'+WordToStr(SReg);
       End;
       15:Begin
        S:='BCHG';
        SourceS:='#'+WordToStr(GetWord and $002F);
       End;
       16:Begin
        S:='BCLR';
        SourcES:='D'+WordToStr(SReg);
       End;
       17:Begin
        S:='BCLR';
        SourceS:='#'+WordToStr(GetWord and $002F);
       End;
       18:Begin
        S:='BSET';
        SourceS:='D'+WordToStr(SReg);
       End;
       19:Begin
        S:='BSET';
        SourceS:='#'+WordToStr(Data);
       End;
       20:Begin
        S:='BTST';
        SourceS:='D'+WordToStr(SReg);
       End;
       21:Begin
        S:='BTST';
        SourceS:='#'+WordToStr(GetWord and $002F);
       End;
      End;
      DestS:=ModeToStr(DMode,DReg,0);
      S:=S+' '+SourceS+','+DestS;
      IsDecoded:=True;
     End;
    End;
    22,29,30,52,53,24:Begin
     SMode:=GetMode(WordInstr);
     Ok:=True;
     If(SMode=1)and(OpNum<>24)Then Ok:=False;
     If(SMode>=12)Then Ok:=False;
     SReg:=WordInstr and $0007;
     DReg:=(WordInstr and $0E00) shr 9;
     If(OpNum=24)Then Size:=(WordInstr and $00C0) shr 6
                 Else Size:=1;
     If(Size=3)Then Ok:=False;
     If(Ok)Then Begin
      Case(OpNum)of
       22:S:='CHK';
       24:S:='CMP.'+SizeArr[Size];
       29:S:='DIVS';
       30:S:='DIVU';
       52:S:='MULS';
       53:S:='MULU';
      End;
      S:=S+' '+ModeToStr(SMode,SReg,Size)+',D'+WordToStr(DReg);
      IsDecoded:=True;
     End;
    End;
    23:Begin
     DMode:=GetMode(WordInstr);
     DReg:=WordInstr and $0007;
     Ok:=True;
     If(DMode=1)and(DMode>=9)Then Ok:=False;
     Size:=(WordInstr and $00C0) shr 6;
     If Size=3 Then Ok:=False;
     If(Ok)Then Begin
      S:='CLR.'+SizeArr[Size]+' '+ModeToStr(DMode,DReg,Size);
      IsDecoded:=True;
     End;
    End;
    25:Begin
     SMode:=GetMode(WordInstr);
     SReg:=WordInstr and $0007;
     AReg:=(WordInstr and $0E00) shr 9;
     Size:=((WordInstr and $0100) shr 8)+1;
     S:='CMPA.'+SizeArr[Size]+' '+ModeToStr(SMode,SReg,Size)+',A'+WordToStr(AReg);
     IsDecoded:=True;
    End;
    28:Begin
     CC:=(WordInstr and $0F00) shr 8;
     Case(CC)of
      0:S:='DBT';
      1:S:='DBF';
      Else S:='D'+BraTab[CC];
     End;
     Offset:=GetWord;
     If(Offset>=32768)Then Offset:=Offset-65536;
     DReg:=WordInstr and $0007;
     S:=S+' D'+WordToStr(DReg)+',$'+LongHex2Str(I-2+Offset);
     IsDecoded:=True;
    End;
    33:Begin
     DMode:=(WordInstr and $00F8) shr 3;
     Ok:=True;
     If((DMode<>8)and(DMode<>9)and(DMode<>17))Then Ok:=False;
     If(Ok)Then Begin
      DReg:=WordInstr and $0007;
      AReg:=(WordInstr and $0E00) shr 9;
      S:='EXG'+' ';
      Case(DMode)of
       8:S:=S+'D'+WordToStr(DReg)+',D'+WordToStr(AReg);
       9:S:=S+'A'+WordToStr(DReg)+',A'+WordToStr(AReg);
       17:S:=S+'D'+WordToStr(DReg)+',A'+WordToStr(AReg);
      End;
      IsDecoded:=True;
     End;
    End;
    34:Begin
     DReg:=WordInstr and $0007;
     Size:=((WordInstr and $0040) shr 6)+1;
     S:='EXT.'+SizeArr[Size]+' D'+WordToStr(DReg);
     IsDecoded:=True;
    End;
    35,36:Begin
     DMode:=GetMode(WordInstr);
     DReg:=WordInstr and $0007;
     Ok:=True;
     If(DMode<=1)Then Ok:=False;
     If(DMode=3)and(DMode=4)Then Ok:=False;
     If(DMode>=11)Then Ok:=False;
     If(Ok)Then Begin
      Case(OpNum)of
       35:S:='JMP';
       36:S:='JSR';
      End;
      S:=S+' '+ModeToStr(DMode,DReg,0);
      IsDecoded:=True;
     End;
    End;
    37:Begin
     SMode:=GetMode(WordInstr);
     Ok:=True;
     Case(SMode)of
      0,1,3,4:Ok:=False;
     End;
     If(SMode>=11)Then Ok:=False;
     SReg:=WordInstr and $0007;
     S:='LEA'+' '+ModeToStr(SMode,SReg,0)+',A'+WordToStr((WordInstr and $0E00) shr 9);
     IsDecoded:=True;
    End;
    38:Begin
     AReg:=WordInstr and $0007;
     Offset:=GetWord;
     If(Offset>=32768)Then Offset:=Offset-65536;
     S:='LINK A'+WordToStr(AReg)+',#'+LongToStr(Offset);
     IsDecoded:=True;
    End;
    43:Begin
     SMode:=GetMode(WordInstr);
     Data:=((WordInstr and $0E00) shr 9)or((WordInstr and $01C0) shr 3);
     DMode:=GetMode(Data);
     SReg:=WordInstr and $0007;
     DReg:=Data and $0007;
     Size:=(WordInstr and $3000) shr 12;
     Ok:=True;
     If(Size=0)Then Ok:=False;
     If(Ok)Then Begin
      Case(Size)of
       1:Size:=0;
       2:Size:=2;
       3:Size:=1;
      End;
      If(SMode>11)Then Ok:=False;
      If(DMode=1)Then Ok:=False;
      If(DMode>=9)Then Ok:=False;
      If(Ok)Then Begin
       S:='MOVE.'+SizeArr[Size]+' '+ModeToStr(SMode,SReg,Size);
       S:=S+ModeToStr(DMode,DReg,Size);
       IsDecoded:=True;
      End;
     End;
    End;
    44,45:Begin
     SMode:=GetMode(WordInstr);
     SReg:=WordInstr and $0007;
     Size:=1;
     Ok:=True;
     If(SMode=1)Then Ok:=False;
     If(SMode>=12)Then Ok:=False;
     S:='MOVE.W'+' '+ModeToStr(SMode,SReg,Size);
     If(OpNum=44)Then S:=S+',CCR'
                 Else S:=S+',SR';
     IsDecoded:=True;
    End;
    46:Begin
     DMode:=GetMode(WordInstr);
     DReg:=WordInstr and $0007;
     Size:=1;
     Ok:=True;
     If(DMode=1)Then Ok:=False;
     If(DMode>=9)Then Ok:=False;
     If(Ok)Then Begin
      S:='MOVE.W'+' '+'SR,'+ModeToStr(DMode,DReg,Size);
      IsDecoded:=True;
     End;
    End;
    47:Begin
     SReg:=WordInstr and $0007;
     S:='MOVE';
     If((WordInstr and $0008)=0)Then Begin
      S:=S+'A'+WordToStr(WordInstr and $0007)+',USP';
     End
      Else
     Begin
      S:=S+'USP,A'+WordToStr(WordInstr and $0007)+'';
     End;
     IsDecoded:=True;
    End;
    48:Begin
     SMode:=GetMode(WordInstr);
     SReg:=WordInstr and $0007;
     Size:=(WordInstr and $3000) shr 12;
     Ok:=True;
     If(Size<=1)Then Ok:=False;
     If(Ok)Then Begin
      If(Size=3)Then Size:=1;
      DReg:=(WordInstr and $0E00) shr 9;
      S:='MOVEA.'+SizeArr[Size]+' '+ModeToStr(SMode,SReg,Size)+',A'+WordToStr(DReg);
      IsDecoded:=True;
     End;
    End;
    49:Begin
     DMode:=GetMode(WordInstr);
     DReg:=WordInstr and $0007;
     Size:=((WordInstr and $0040) shr 6)+1;
     Ok:=True;
     If(DMode=0)or(DMode=1)Then Ok:=False;
     If(DMode>=9)Then Ok:=False;
     Dir:=(WordInstr and $0400) shr 10;
     If(Dir=0)and(DMode=3)Then Ok:=False;
     If(Dir=1)and(DMode=4)Then Ok:=False;
     If(Ok)Then Begin
      Data:=GetWord;
      If(DMode=4)Then Begin
       Temp:=Data;
       Data:=0;
       For I1:=0 to 15 do Begin
        Data:=(Data shr 1)or(Temp and $8000);
        Temp:=Temp shl 1;
       End;
      End;
      For I1:=0 to 7 do RList[I1+1]:=(Data shr I1) and $0001;
      RList[0]:=0;
      RList[9]:=0;
      RList[10]:=0;
      For I1:=1 to 8 do Begin
       If((RList[I1-1]=0)and(RList[I1]=1)and(RList[I1+1]=1)and(RList[I1+2]=1))Then Begin
        SourceS:='D-'+WordToStr(I1+1);
       End;
       If(RList[I1]=1)and(RList[I1+1]=0)Then Begin
        SourceS:='D'+WordToStr(I1-1);
       End;
       If((RList[I1-1]=0)and(RList[I1]=1)and(RList[I1+1]=1)and(RList[I1+2]=0))Then Begin
        SourceS:='D'+WordToStr(I1-1);
       End;
      End;
      For I1:=8 to 15 do RList[I1-7]:=(Data shr I1) and $0001;
      RList[0]:=0;
      RList[9]:=0;
      RList[10]:=0;
      For I1:=1 to 8 do Begin
       If(RList[I1]=1)and(RList[I1+1]=0)Then Begin
        SourceS:='A'+WordToStr(I1)+'-';
       End;
       If(RList[I1]=1)and(RList[I1+1]=0)Then Begin
        SourceS:='A'+WordToStr(I1-1);
       End;
       If(RList[I1-1]=0)and(RList[I1]=1)and(RList[I1+1]=1)and(RList[I1+2]=0)Then Begin
        SourceS:='A'+WordToStr(I1-1);
       End;
      End;
      DestS:=ModeToStr(DMode,DReg,Size);
      If(Dir=0)Then S:='MOVEM.'+SizeArr[Size]+SourceS+DestS
               Else S:='MOVEM. '+DestS+','+SourceS;
      IsDecoded:=True;
     End;
    End;
    50:Begin
     DReg:=(WordInstr and $0E00) shr 9;
     AReg:=WordInstr and $0007;
     Size:=((WordInstr and $0040) shr 6)+1;
     Ok:=True;
     If(Size=3)Then Ok:=False;
     If(Ok)Then Begin
      Data:=GetWord;
      S:='MOVEP'+SizeArr[Size]+' ';
      If(WordInstr and $0080)=0 Then Begin
       S:=S+'$'+HexWord2Str(Data)+'(A'+WordToStr(AReg)+'),D'+WordToStr(DReg);
      End
       Else
      Begin
       S:=S+'D'+WordToStr(DReg)+',$'+HexWord(Data)+'(A'+WordToStr(AReg)+')';
      End;
      IsDecoded:=True;
     End;
    End;
    51:Begin
     DReg:=(WordInstr and $0E00) shr 9;
     S:='MOVEQ'+' #$'+ByteHex2Str(WordInstr and $00FF)+',D'+WordToStr(DReg);
    End;
    54,55,56,58:Begin
     DMode:=GetMode(WordInstr);
     DReg:=WordInstr and $0007;
     Size:=(WordInstr and $00C0) shr 6;
     Ok:=True;
     If(DMode=1)Then Ok:=False;
     If(DMode>=9)Then Ok:=False;
     If(Size=3)Then Ok:=False;
     If(Ok)Then Begin
      Case(OpNum)of
       54:S:='NBCD.'+SizeArr[Size];
       55:S:='NEG.'+SizeArr[Size];
       56:S:='NEGX.'+SizeArr[Size];
       58:S:='NOT.'+SizeArr[Size];
      End;
      S:=S+' '+ModeToStr(DMode,DReg,Size);
      IsDecoded:=True;
     End;
    End;
    57:Begin
     S:='NOP';
     IsDecoded:=True;
    End;
    62:Begin
     S:='RESET';
     IsDecoded:=True;
    End;
    71:Begin
     S:='RTE';
     IsDecoded:=True;
    End;
    72:Begin
     S:='RTR';
     IsDecoded:=True;
    End;
    73:Begin
     S:='RTS';
     IsDecoded:=True;
    End;
    76:Begin
     S:='STOP';
     IsDecoded:=True;
    End;
    85:Begin
     S:='TRAPV';
     IsDecoded:=True;
    End;
    61:Begin
     SMode:=GetMode(WordInstr);
     Ok:=True;
     If(SMode<1)Then Ok:=False;
     If((SMode=3)and(SMode=4))Then Ok:=False;
     If(SMode>=11)Then Ok:=False;
     S:='PEA';
     SReg:=(WordInstr and $0007);
     S:=S+' '+ModeToStr(SMode,SReg,0);
     IsDecoded:=True;
    End;
    75:Begin
     DMode:=GetMode(WordInstr);
     Ok:=True;
     If(DMode=1)Then Ok:=False;
     If(DMode>=9)Then Ok:=False;
     If(Ok)Then Begin
      DReg:=WordInstr and $0007;
      CC:=(WordInstr and $0F00) shr 8;
      S:=SccTab[CC]+' '+ModeToStr(DMode,DReg,0);
      IsDecoded:=True;
     End;
    End;
    82:Begin
     DReg:=WordInstr and $0007;
     S:='SWAP'+' '+'D'+WordToStr(DReg);
     IsDecoded:=True;
    End;
    83:Begin
     DMode:=GetMode(WordInstr);
     DReg:=WordInstr and $0007;
     Ok:=True;
     If(DMode=1)Then Ok:=False;
     If(DMode>=9)Then Ok:=False;
     If(Ok)Then Begin
      S:='TAS '+ModeToStr(DMode,DReg,0);
      IsDecoded:=True;
     End;
    End;
    84:Begin
     DReg:=WordInstr and $000F;
     S:='TRAP '+WordToStr(DReg);
     IsDecoded:=True;
    End;
    86:Begin
     DMode:=GetMode(WordInstr);
     DReg:=WordInstr and $0007;
     Size:=(WordInstr and $00C0) shr 6;
     Ok:=True;
     If(DMode=1)Then Ok:=False;
     If(DMode>=9)Then Ok:=False;
     If(Size=3)Then Ok:=False;
     S:='TST '+ModeToStr(DMode,DReg,Size);
     IsDecoded:=True;
    End;
    87:Begin
     AReg:=WordInstr and $0007;
     S:='UNLK A'+WordToStr(AReg);
     IsDecoded:=True;
    End;
   End;
   If(IsDecoded)Then Break;
  End;
 End;
 If Not(IsDecoded)Then S:='DW '+WordToStr(WordInstr);
 Decode:=S;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('DIS68K : Cette commande permet de d‚sassembleur un code binaire de');
  WriteLn('          microprocesseur 68000 en langage de programmation assembleur 68000.');
  WriteLn;
  WriteLn('Syntaxe : DIS68K nomdufichier');
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

