{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal )
}

Program CHCP;

Uses DOS;

Var
 Err:Word;
 Regs:Registers;
 FirstParam:String;

BEGIN
 FirstParam:=ParamStr(1);
 If FirstParam='/?'Then Begin
  WriteLn('CHCP   Cette commande permet de fixer ou de demander la page de codes.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('CHCP [/?] [code]');
  WriteLn;
  WriteLn('  /?     Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' code    Ce parametre permet d''indiquer la page de code');
 End
  Else
 If FirstParam<>''Then Begin
  Regs.AX:=$6602;
  Val(FirstParam,Regs.BX,Err);
  If Err=0Then Begin
   Intr($21,Regs);
   If(Regs.Flags and FCarry=FCarry)Then Begin
    WriteLn('Impossible de changer le code de page actif');
   End;
  End
   Else
  WriteLn('Code de page invalide.');
 End
  Else
 Begin
  Regs.AX:=$6601;
  Intr($21,Regs);
  If(Regs.Flags and FCarry=FCarry)Then Begin
   WriteLn('Page de code active inconnnu');
  End
   Else
  WriteLn('Page de code active : ',Regs.BX);
 End;
END.