{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program L43;

{$IFDEF FPC}
 Uses Crt;
{$ENDIF}

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('L43 : Cette commande permet de faire passer l''affichage texte en ',
          '43 lignes pour les cartes EGA et … 50 lignes pour les cartes VGA.');
  WriteLn;
  WriteLn('Syntaxe : L43 [/?]');
 End
  Else
 {$IFDEF FPC}
  TextMode(Font8x8+CO80);
 {$ELSE}
  ASM
   MOV AH,11h
   MOV AL,12h
   MOV BX,0000h
   INT 10h
   MOV AX,4C00h
   INT 21h
  END;
 {$ENDIF}
END.
