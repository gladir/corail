{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal)
}

Program EQUIP;

Uses DOS;

Function GetConvMemory:Word;
Var
 Regs:Registers;
Begin
 Regs.AX:=0;
 Intr($12,Regs);
 GetConvMemory:=Regs.AX;
End;

Function GetEquip:Word;
Var
 Regs:Registers;
Begin
 Regs.AX:=0;
 Intr($11,Regs);
 GetEquip:=Regs.AX;
End;

Function GetVideoCard:Word;
Var
 Regs:Registers;
Begin
 Regs.AX:=$1A00;
 Intr($10,Regs);
 If Regs.AL=$1AThen GetVideoCard:=Regs.BX
               Else GetVideoCard:=0;
End;

Function MonochromePresent:Byte;Begin
 MonochromePresent:=0;
 If((GetVideoCard and $FF)in[$01,$07,$0B])or
   ((GetVideoCard shr 8)in[$01,$07,$0B])Then MonochromePresent:=1
End;

Function EnhancedGraphicsAdapterPresent:Byte;Begin
 EnhancedGraphicsAdapterPresent:=0;
 If((GetVideoCard and $FF)in[$04,$05,$06,$08,$0A,$0C])or
   ((GetVideoCard shr 8)in[$04,$05,$06,$08,$0A,$0C])Then EnhancedGraphicsAdapterPresent:=1
End;

Function GetNumFloppyDisk:Word;Begin
 GetNumFloppyDisk:=(GetEquip shr 6)and 3;
End;

Function GetNumParallelPort:Word;Begin
 GetNumParallelPort:=(GetEquip shr 14)and 3;
End;

Function GetNumSerialPort:Word;Begin
 GetNumSerialPort:=(GetEquip shr 9) and 3;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('EQUIP : Cette commande permet d''afficher l''equipement installe.');
  WriteLn;
  WriteLn('Syntaxe : EQUIP');
 End
  Else
 Begin
  WriteLn(' Equipement installe');
  WriteLn(' (',GetConvMemory:5,'k) - Memoire');
  Write(' ':6,'(');
  If Test8087>0Then Write(1)
               Else Write(0);
  WriteLn(') - Coprocesseur mathematique');
  WriteLn(' ':6,'(',GetNumFloppyDisk,') - Unite de disquette');
  WriteLn(' ':6,'(',MonochromePresent,') - Adaptateur monochrome');
  WriteLn(' ':6,'(',EnhancedGraphicsAdapterPresent,') - Adaptateur graphique etendu');
  WriteLn(' ':6,'(',GetNumParallelPort,') - Port parallele');
  WriteLn(' ':6,'(',GetNumSerialPort,') - Port serie');
 End;
END.