{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}


Program CPUTEST;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

{$IFNDEF FPC}
 Function DetectCyrix:Boolean;Assembler;ASM
  XOR  AX,AX
  SAHF
  MOV  AX,$05
  MOV  BX,$02
  DIV  BL
  LAHF
  CMP  AH,$02
  JNE  @nocyrix
  MOV  AL,$01
  JMP  @tend
  @nocyrix:
  XOR  AL,AL
 @tend:
 END;

{$ENDIF}

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('CPUTEST : Cette commande permet de verifier le type de microprocesseur.');
  WriteLn;
  {$IFDEF FPC}
   WriteLn('Syntaxe : CPUTEST [/?]');
  {$ELSE}
   WriteLn('Syntaxe : CPUTEST [/?] [/CYRIX]');
   WriteLn;
   WriteLn(' /?      Fournit de l''aide sur cette commande');
   WriteLn(' /CYRIX  D‚tecte les microprocesseur Cyrix 5x86 ou 6x86');
  {$ENDIF}
 End
  {$IFNDEF FPC}
  Else
 If StrToUpper(ParamStr(1))='/CYRIX'Then Begin
  If(DetectCyrix)Then WriteLn('Cyrix d‚tect‚')
                 Else WriteLn('Cyrix absent');
 End
  {$ENDIF}
  Else
 Begin
  Case Test8086 of
   0:WriteLn('Microprocesseur 8086 detecte');
   1:WriteLn('Microprocesseur 80286 detecte');
   2:WriteLn('Microprocesseur 80386 detecte');
   Else WriteLn('Microprocesseur inconnu : ',Test8086);
  End;
  If Test8086>=1 Then WriteLn('Le test de microprocesseur est OK')
                 Else WriteLn('Le test de microprocesseur a echoue');
 End;
END.