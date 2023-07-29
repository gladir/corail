{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program Mode;

Uses DOS;

Const
  { Registre par defaut pour les modes d'affichages texte de la Graphics Solution }
 RegMonoGS:Array[0..11]of Byte=($61,$50,$52,$0F,$19,$06,$19,$19,$02,$0D,$0B,$0C);
 RegColGS:Array[0..11]of Byte=($71,$50,$5A,$0A,$1F,$06,$19,$1C,$02,$07,$06,$07);

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 _Rate,_Delay,I:Integer;      { Compteur de boucle }
 {$IFDEF Windows}
  SmallRate,SmallDelay:SmallInt;
 {$ENDIF}
 SetRate,SetDelay:Boolean;
 Err:Word;
 Regs:Registers;

Function StrToUpper(S:String):String;
Var
 I:Byte; { Compteur de boucle attribue a la chaine de caracteres }
Begin
 For I:=1to Length(S)do S[I]:=UpCase(S[I]);
 StrToUpper:=S;
End;

{$IFNDEF FPC}
 Procedure RegTxt80x25;Near;Assembler;ASM
  DB $71,$50,$5A,$0A,$1F,$06,$19,$1C,$02,$07;
 END;

 Procedure RegTxt132x25;Near;Assembler;ASM
  DB $B5,$84,$97,$0A,$1F,$06,$19,$1C,$02,$07;
 END;

 Procedure RegTxt132x28;Near;Assembler;ASM
  DB $B5,$84,$97,$0A,$1F,$06,$1C,$1C,$02,$07;
 END;

 Procedure Reg320x200c16;Near;Assembler;ASM
  DB $38,$28,$2D,$0A,$7F,$06,$64,$70,$02,$01;
 END;

 Procedure Reg320x200c16Emul;Near;Assembler;ASM
  DB $36,$28,$2D,$08,$64,$06,$64,$64,$02,$07;
 END;

 Procedure Reg640x200c16;Near;Assembler;ASM
  DB $70,$50,$58,$0A,$40,$06,$32,$38,$02,$03;
 END;

 Procedure Reg640x200c16Emul;Near;Assembler;ASM
  DB $61,$50,$52,$08,$32,$06,$32,$32,$02,$07;
 END;

 Procedure Load16Registers;Near;Assembler;ASM { DI=Offset des Registres }
  MOV DX,03D4h
  XOR BX,BX
@1:MOV AH,CS:[DI+BX].Byte
  MOV AL,BL
  OUT DX,AX
  INC BX
  CMP BX,10
  JNE @1
  MOV AX,060Ah;OUT DX,AX
  MOV AX,070Bh;OUT DX,AX
  XOR AH,AH
  INC AX;OUT DX,AX
  INC AX;OUT DX,AX
  INC AX;OUT DX,AX
  INC AX;OUT DX,AX
 END;

 Procedure SetGS132;Near;Assembler;ASM
  CLI
  CLD
  {$IFDEF DPMI}
   MOV ES,SegB800
  {$ELSE}
   MOV AX,0B800h
  MOV ES,AX
  {$ENDIF}
  XOR DI,DI
  MOV CX,2000h
  MOV AX,0720h
  REP STOSW
  MOV DX,03D8h
  MOV AL,2
  OUT DX,AL
  MOV DL,0DDh
  XOR AL,AL
  OUT DX,AL
  MOV DL,0D8h
  MOV AL,5
  OUT DX,AL
 END;

 Procedure _SetExtGS132;Near;Assembler;ASM
  CALL Load16Registers
  MOV DL,0D8h
  MOV AL,00Dh
  OUT DX,AL
  INC DX
  MOV AL,030h
  OUT DX,AL
  MOV DL,0DDh
  XOR AL,AL
  OUT DX,AL
  MOV DL,0DFh
 END;

 Procedure SetExtGS132;Near;Assembler;ASM
  CALL _SetExtGS132
  MOV AL,090h
  OUT DX,AL
 END;

{$ENDIF}

Procedure DisableInterrupt;
{$IFDEF FPC}
 Begin
 End;
{$ELSE}
 Assembler;ASM
  CLI
 END;
{$ENDIF}

Procedure EnableInterrupt;
{$IFDEF FPC}
 Begin
 End;
{$ELSE}
 Assembler;ASM
  STI
 END;
{$ENDIF}

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
 If(ParamCount=0)or(ParamStr(1)='/?')or(ParamStr(1)='-?')or(StrToUpper(ParamStr(1))='HELP')Then Begin
  Case Language of
   _English:Begin
    WriteLn('Change screen devices.');
    WriteLn;
    WriteLn('SCREEN [/?]');
    WriteLn('SCREEN [MT|BW40|CO40|BW80|CO80|CO132] [/GS]');
   End;
   Else Begin
    WriteLn('SCREEN - Cette commande permet de s‚lectionner le mode ',
                     'd''affichage … utiliser avec l''adaptateur ',
                     'd''affichage graphique GDA (Graphics Display Adapter).');
    WriteLn;
    WriteLn('SCREEN [/?]');
    WriteLn('SCREEN [MT|BW40|CO40|BW80|CO80|CO132] [/GS]');
    WriteLn;
    WriteLn(' HELP         Fournit de l''aide sur cette commande');
    WriteLn(' MT           Mode texte monochrome 80x25');
    WriteLn(' BW40         Mode texte noir et blanc 40x25');
    WriteLn(' CO40         Mode texte couleur 40x25');
    WriteLn(' BW80         Mode texte noir et blanc 80x25');
    WriteLn(' CO80         Mode texte couleur 80x25');
    WriteLn(' CO132        Mode texte couleur 132x25');
    WriteLn(' /GS          Force a s''appliquer en fonction d''une Graphics Solution d''ATI');
   End;
  End;
  Halt;
 End
  Else
 If StrToUpper(ParamStr(1))='MT'Then Begin
  If ParamStr(2)='/GS'Then Begin
   {$IFDEF FPC}
    WriteLn('Port materiel : Non supporte par le compilateur FREE PASCAL');
   {$ELSE}
    DisableInterrupt;
     { Permettre une Graphics Solution en mono...}
    Port[$3DF]:=$47; Port[$3B8]:=$08;
    For I:=0to 11do Begin
     Port[$3B4]:=I;
     Port[$3B5]:=RegMonoGS[I];
    End;
    Port[$3B8]:=$08;
     { Mise-a-jour des informations du BIOS en fonction de l'affichage actuel }
    Mem [$0040:$49]:=7;
    MemW[$0040:$4C]:=4096;
    MemW[$0040:$4E]:=0;
    Mem [$0040:$62]:=0;
    MemW[$0040:$63]:=$3B4;
    MemW[$0040:$4A]:=80;
    Mem [$0040:$84]:=24;
    MemW[$0040:$85]:=14;
    Mem [$0040:$60]:=12;
    Mem [$0040:$61]:=11;
    EnableInterrupt;
   {$ENDIF}
  End;
  {$IFDEF FPC}
   WriteLn('Memoire materiel : Non supporte par le compilateur FREE PASCAL');
  {$ELSE}
   Mem[$0:$0410]:=(Mem[$0:$0410] and $CF)or $30; { Mode 80x25 monochrome }
  {$ENDIF}
  Regs.AX:=7;
  Intr($10,Regs);
  WriteLn('Mode texte monochrome 80x25 standard.');
  Halt;
 End
  Else
 If(StrToUpper(ParamStr(1))='CO80')or(StrToUpper(ParamStr(1))='CO40')or
   (StrToUpper(ParamStr(1))='BW80')or(StrToUpper(ParamStr(1))='BW40')Then
 Begin
  If StrToUpper(ParamStr(2))='/GS'Then Begin
   {$IFDEF FPC}
    WriteLn('Port materiel : Non supporte par le compilateur FREE PASCAL');
   {$ELSE}
    DisableInterrupt;
    Port[$3BA]:=$80; Port[$3DF]:=$80;
    Port[$3D8]:=$02; Port[$3DD]:=$00; Port[$3D8]:=$25;
    For I:=0to 11do Begin
     Port[$3D4]:=I;
     Port[$3D5]:=RegColGS[I];
    End;
    Port[$3D8]:=$2D;
    Port[$3D9]:=$30;
    Port[$3DD]:=$00;
     { Mise-a-jour des informations du BIOS en fonction de l'affichage actuel }
    Mem [$0040:$49]:=3;
    MemW[$0040:$4C]:=4096;
    MemW[$0040:$4E]:=0;
    Mem [$0040:$62]:=0;
    MemW[$0040:$63]:=$3D4;
    MemW[$0040:$4A]:=80;
    Mem [$0040:$84]:=24;
    MemW[$0040:$85]:=8;
    Mem [$0040:$60]:=7;
    Mem [$0040:$61]:=6;
    Mem [$0040:$10]:=(Mem[$0040:$10]and Not(16+32))or(32);
    EnableInterrupt;
   {$ENDIF}
  End;
  {$IFDEF FPC}
   WriteLn('Memoire materiel : Non supporte par le compilateur FREE PASCAL');
  {$ELSE}
   Mem[$0:$0410]:=(Mem[$0:$0410] and $CF)or $20; { Mode 80x25 en 16 couleurs}
  {$ENDIF}
  If ParamStr(1)='CO132'Then Begin
   {$IFDEF FPC}
    WriteLn('Carte vid‚o : Non supporte par le compilateur FREE PASCAL');
   {$ELSE}
    ASM
     CALL SetGS132
     MOV DI,Offset RegTxt132x25
     CALL SetExtGS132
     STI
    END;
    Mem[Seg0040:$4A]:=132;
    Mem[Seg0040:$84]:=24;
   {$ENDIF}
  End
   Else
  If ParamStr(1)='CO80'Then Begin
   Regs.AX:=3;
   Intr($10,Regs);
   WriteLn('Mode texte couleur 80x25.');
  End
   Else
  If StrToUpper(ParamStr(1))='CO40'Then Begin
   Regs.AX:=1;
   Intr($10,Regs);
   WriteLn('Mode texte couleur 40x25.');
  End
   Else
  If StrToUpper(ParamStr(1))='BW80'Then
  Begin
   Regs.AX:=2;
   Intr($10,Regs);
   WriteLn('Mode texte noir et blanc 80x25.');
  End
   Else
  Begin
   Regs.AX:=0;
   Intr($10,Regs);
   WriteLn('Mode texte noir et blanc 40x25.');
  End;
  Halt;
 End
  Else
 WriteLn('Erreur de parametre.');
END.