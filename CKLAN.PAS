{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CKLAN;

Uses DOS;

Function NetworkExist:Boolean;
Var
 Regs:Registers;
Begin
 Regs.AX:=$B800;
 Intr($2F,Regs);
 NetworkExist:=Regs.AL<>0;
End;

Function GetNetBIOSMachineNumber:Byte;
Var
 Regs:Registers;
Begin
 Regs.AX:=$B807;
 Regs.CX:=0;
 Intr($2F,Regs);
 GetNetBIOSMachineNumber:=Regs.CH;
End;

Function GetLanVersion:Word;
Var
 Regs:Registers;
Begin
 Regs.AX:=$B809;
 Intr($2F,Regs);
 GetLanVersion:=Regs.AX;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('CKLAN : Cette commande permet de v‚rifier la pr‚sence d''un ',
                   'r‚seau LAN.');
  WriteLn;
  WriteLn('Syntaxe : CKLAN [/?]');
 End
  Else
 Begin
  Write('R‚seau LAN install‚ : ');
  If(NetworkExist)Then Begin
   WriteLn('Oui');
   WriteLn('LAN Version ',Lo(GetLanVersion),'.',Hi(GetLanVersion));
   WriteLn('Num‚ro de machine: ',GetNetBIOSMachineNumber);
  End
   Else
  WriteLn('Non');
 End;
END.