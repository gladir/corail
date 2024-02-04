{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7)
}

Program HALT;

Var
 Reboot:Boolean;
 I:Integer;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

{$IFDEF FPC}
 Function SetAPMMode(Mode:Word):Boolean;Begin
  WriteLn('Fonction non support‚ dans FPC !');
 End;
{$ELSE}
 Function SetAPMMode(Mode:Word):Boolean;Assembler;ASM
   { Connecter l'interface RM }
  MOV AX,5301h
  XOR BX,BX
  INT 15h
   { Active le pilote APM 1.1 }
  MOV AX,530Eh
  XOR BX,BX
  MOV CX,0101h
  INT 15h
   { Active l'APM }
  MOV AX,5308h
  MOV BX,1
  MOV CX,BX
  INT 15h
   { Demande la mode sp‚cifier }
  MOV AX,5307h
  mov BX,1
  MOV CX,Mode
  INT 15h
  MOV AL,0
  JC  @Error
  MOV AL,True
 @Error:
 @End:
 END;
{$ENDIF}

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('HALT : Cette commande permet d''arrˆter l''ordinateur');
  WriteLn;
  WriteLn('Syntaxe : HALT [option]');
  WriteLn;
  WriteLn(' -r      Red‚marrer l''ordinateur');
  WriteLn(' --help  Affiche l''aide de cette commande');
 End
  Else
 Begin
  Reboot:=False;
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='-r'Then Reboot:=True;
  End;
  If(Reboot)Then Begin
   {$IFDEF FPC}
    WriteLn('Fonction non support‚ dans FPC !');
   {$ELSE}
    MemW[Seg0040:$72]:=$1234;
    ASM
     INT 19h
    END;
   {$ENDIF}
  End
   Else
  Begin
   SetAPMMode(3);
  End;
 End;
END.