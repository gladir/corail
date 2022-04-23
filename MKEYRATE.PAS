{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program MKEYRATE;

Uses DOS;

Var
 I:Integer;
 Err:Word;
 Rate,Delay:Word;
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

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('MKEYRATE : Cette commande permet de modifier le temps de reponse ',
          'des claviers AT pour permettre une saisie et un mouvement du curseur ',
          'plus rapide.');
  WriteLn;
  WriteLn('Syntaxe : MKEYRATE /R:nn /D:nnnn');
  WriteLn;
  WriteLn(' /R:nnn   Debit typographique (2 a 30)');
  WriteLn(' /D:nnnn  Delai d''appui (250, 500, 750, 1000)');
 End
  Else
 If ParamCount>0Then Begin
  Rate:=10;
  Delay:=500;
  For I:=1 to ParamCount do Begin
   If Copy(StrToUpper(ParamStr(I)),1,3)='/R:'Then Begin
    Val(Copy(ParamStr(I),4,255),Rate,Err);
   End
    Else
   If Copy(StrToUpper(ParamStr(I)),1,3)='/D:'Then Begin
    Val(Copy(ParamStr(I),4,255),Delay,Err);
   End
    Else
   Begin
    WriteLn('Parametre inconnu :',ParamStr(I));
    Halt;
   End;
  End;
  Regs.AX:=$0305;
  Regs.BH:=$01;
  Regs.BL:=$0C;
  Case Delay of
   0..250:Regs.BH:=$00;
   251..500:Regs.BH:=$01;
   501..1000:Regs.BH:=$02;
  End;
  Case Rate of
   27..30:Regs.BL:=$00;
   25..26:Regs.BL:=$01;
   24:Regs.BL:=$02;
   21..23:Regs.BL:=$03;
   20:Regs.BL:=$04;
   18..19:Regs.BL:=$05;
   17:Regs.BL:=$06;
   16:Regs.BL:=$07;
   15:Regs.BL:=$08;
   13..14:Regs.BL:=$09;
   12:Regs.BL:=$0A;
   11:Regs.BL:=$0B;
   10:Regs.BL:=$0C;
   9:Regs.BL:=$0D;
   8:Regs.BL:=$0F;
   7:Regs.BL:=$10;
   6:Regs.BL:=$12;
   5:Regs.BL:=$14;
   4:Regs.BL:=$17;
   3:Regs.BL:=$1A;
   2:Regs.BL:=$1F;
  End;
  Intr($16,Regs);
 End
  Else
 WriteLn('Parametre requis');
END.
