{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7)
}

Program SPEED;

Uses Dos;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 I:Integer;
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
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _English:Begin
    WriteLn('SPEED : This command changes the operating speed of the microprocessor.');
    WriteLn;
    WriteLn('SPEED [/?] [{S | H}] [{E | D}]');
    WriteLn;
    WriteLn('/?         = Help for this command');
    WriteLn('S          = Standard speed');
    WriteLn('H          = High speed');
    WriteLn('D          = Disable front-panel');
    WriteLn('E          = Enable front-panel');
   End;
   Else Begin
    WriteLn('SPEED: Cette commande permet de changer la vitesse de ',
                    'fonctionnement du microprocesseur.');
    WriteLn;
    WriteLn('SPEED [/?] [{S | H}] [{E | D}]');
    WriteLn;
    WriteLn(' /?   Ce paramätre permet de founir de l''aide sur cette commande.');
    WriteLn('D     Ce paramätre permet de dÇsactiver le bouton Ö double vitesse ',
                   'du panneau frontal (s''il est prÇsent).');
    WriteLn('E     Ce paramätre permet d''activer le bouton Ö double vitesse du ',
                   'panneau frontal (s''il est prÇsent).');
    WriteLn('H     Ce paramätre permet de sÇlectionner la haute vitesse ',
                   'du microprocesseur.');
    WriteLn('S     Ce paramätre permet de sÇlectionner la vitesse standard ',
                  'du microprocesseur.');
   End;
  End;
 End
  Else
 If ParamCount>0 Then Begin
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='D'Then Begin
    Regs.AL:=0;
    Regs.AH:=4;
    Intr($15,Regs);
   End
    Else
   If StrToUpper(ParamStr(I))='E'Then Begin
    Regs.AL:=1;
    Regs.AH:=4;
    Intr($15,Regs);
   End
    Else
   If StrToUpper(ParamStr(I))='H'Then Begin
    Regs.AL:=8;
    Regs.AH:=4;
    Intr($15,Regs);
   End
    Else
   If StrToUpper(ParamStr(I))='E'Then Begin
    Regs.AL:=6;
    Regs.AH:=4;
    Intr($15,Regs);
   End
    Else
   Begin
    WriteLn('Paramätre invalide !');
    Halt;
   End;
  End;
 End
  Else
 WriteLn('Paramätre requis !');
END.