{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7)
}

Program CyrixCPU;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

{ Cette procÇdure permet de fixer le micro-processeur pour qu'il supporte
 oui ou non l'instruction du Pentium ÆCPUIDØ.
}

Procedure SetCPUID(X:Boolean);Assembler;ASM
 MOV  DX,0022h { Port de contrìle de configuration }
 MOV  AL,0C3h  { Registres de contrìle de configuration CCR3 }
 OUT  DX,AL
 INC  DX
 IN   AL,DX
 MOV  CL,AL    { Sauvegarde dans CL la valeur CCR3 }
  { Fixe les bits 4 Ö 7 du registre CCR3. 1 pour autoriser une modification }
 AND  AL,0Fh
 OR   AL,010h
 XCHG AL,AH
 DEC  DX
 MOV  AL,0C3h  { Registre CCR3 }
 OUT  DX,AL
 INC  DX
 XCHG AL,AH
 OUT  DX,AL
 DEC  DX
 MOV  AL,0E8h
 OUT  DX,AL
 INC  DX
 IN   AL,DX
  { Ajuste le 7 bits du registre Ö la valeur de ÆXØ }
 CMP  X,True
 JE   @2
 AND  AL,LOW(NOT 80h)
 JMP  @3
@2:
 OR   AL,80h
@3:
 XCHG AL,AH
 DEC  DX
 MOV  AL,0E8h
 OUT  DX,AL
 INC  DX
 XCHG AL,AH
 OUT  DX,AL
 DEC  DX
  { Restitution de la valeur original du CCR3 }
 MOV  AL,0C3h  { Registre CCR3 }
 OUT  DX,AL
 INC  DX
 MOV  AL,CL
 OUT  DX,AL
END;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CYRIXCPU : Cette commande permet d''activer l''instruction ',
          'CPUID du Pentium sur des Cyrix 5x86 et 6x86');
  WriteLn;
  WriteLn('Syntaxe : CYRIXCPU [/?] [ON|OFF]');
  WriteLn;
  WriteLn(' ON        Active le CPUID');
  WriteLn(' OFF       DÇsactive le CPUID');
 End
  Else
 If ParamCount>0Then Begin
  If StrToUpper(ParamStr(1))='ON'Then SetCPUID(True)Else
  If StrToUpper(ParamStr(1))='OFF'Then SetCPUID(False)
                                  Else WriteLn('Paramätre non reconnu');
 End;
END.