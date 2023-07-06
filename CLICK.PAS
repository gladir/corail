{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7)
}

Program Click;

{$M $800,0,0 }   { 2 Ko de pile, pas de m‚moire de tas }

Uses Crt,Dos;

Var
 ClickActivated:Boolean;
 KbdIntVec:Procedure;
 Regs:Registers;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Procedure ClickOn;Interrupt;Begin
 ClickActivated:=True;
End;

Procedure ClickOff;Interrupt;Begin
 ClickActivated:=False;
End;

{$F+}
Procedure Keyclick;Interrupt;Begin
 If Port[$60]<$80 Then Begin
  If(ClickActivated)Then Begin
   Sound(5000);
   Delay(1);
   Nosound;
  End;
 End;
 Inline($9C);
 KbdIntVec;
End;
{$F-}

BEGIN
 ClickActivated:=True;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CLICK : Cette commande permet de contr“ler le son du clic ',
          'clavier lors de frappe de touche');
  WriteLn;
  WriteLn('Syntaxe : CLICK [/?] [ON|OFF]');
  WriteLn;
  WriteLn(' ON        Active le clic');
  WriteLn(' OFF       D‚sactive le clic');
 End
  Else
 If ParamCount>0Then Begin
  If StrToUpper(ParamStr(1))='ON'Then Intr($B0,Regs)Else
  If StrToUpper(ParamStr(1))='OFF'Then Intr($B1,Regs)
                                  Else WriteLn('ParamŠtre non reconnu');
 End
  Else
 Begin
  WriteLn('Installation du programme r‚sident CLICK');
  GetIntVec($9,@KbdIntVec);
  SetIntVec($9,Addr(Keyclick));
  SetIntVec($B0,@ClickOn);
  SetIntVec($B1,@ClickOff);
  Keep(0);
 End;
END.