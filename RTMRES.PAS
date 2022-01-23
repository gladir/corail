{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal)
}

Program RTMRES;

{$M 2048,0,0}

Uses Dos;

Procedure PrintStr(Const S:String);Assembler;ASM
 PUSH DS
  LDS SI,S
  CLD
  LODSB
  XOR AH,AH
  XCHG AX,CX
  MOV AH,40H
  MOV BX,1
  MOV DX,SI
  INT 21H
 POP DS
End;

Var
 Command:PathStr;
 Parameters:String;
 I:Integer;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('RTMRES : Cette commande permet de charger le RTM en mode resident.');
  WriteLn;
  WriteLn('Syntaxe : RTMRES [/?]');
 End
  Else
 Begin
  PrintStr('RTMRES CLONE'#10#13);
  SwapVectors;
  Command:='';
  Parameters:='';
  If ParamCount > 0 Then Begin
   Command := FSearch(ParamStr(1), GetEnv('PATH'));
   If Command='' Then Begin
    Command:=GetEnv('COMSPEC');
    Parameters:='/C ' + ParamStr(1) + ' ';
   End;
   For I:=2 to ParamCount do Parameters:=Parameters+' '+ParamStr(I);
  End
   Else
  Begin
   PrintStr('RTM Resident.  Ecrire la commande ''EXIT'' pour desinstaller.'#10#13);
   Command := GetEnv('COMSPEC');
  End;
  Exec(Command, Parameters);
  SwapVectors;
  PrintStr('RTM decharger.'#10#13);
 End;
END.