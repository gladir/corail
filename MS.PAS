{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal)
}

Program MS;

Uses Crt;

Const
 {Code de touche clavier renvoy?e par ReadKey}
 kbNoKey=0;{Pas de touche}
 kbEsc=$001B;{Escape}
 kbUp=$4800;{Up}
 kbLeft=$4B00;{Fl?che de gauche (Left)}
 kbRight=$4D00;{Fl?che de droite (Right)}
 kbDn=$5000;{Fl?che du bas (Down)}
 kbHome=$4700;{Home}
 kbTab=$0F09;{Tabulation}
 kbEnd=$4F00;{End}
 kbEnter=$000D;{Enter}
 kbF10=$4400;{F10}

Var 
 K:Word;
 J:Byte;
 
Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;  
 
Procedure FillWord(Var X;Len,Value:Word);Assembler;ASM
 CLD;
 LES DI,X;
 MOV CX,Len;
 MOV AX,Value;
 REP STOSW;
END; 
 
Procedure SetModeGS(Mode:Byte);
Const 
 ModeTxt:Array[0..1,0..15] of Byte=(
    ($38,$28,$2D,$0A,$1F,$06,$19,$1C,$02,$07,$06,$07,$00,$00,$00,$00),
    ($71,$50,$5A,$0A,$1F,$06,$19,$1C,$02,$07,$06,$07,$00,$00,$00,$00)
 );
 ModeTxt132:Array[0..15] of Byte=($B5,$84,$97,$0A,$1F,$06,$19,$1C,$02,$07,$06,$07,$00,$00,$00,$00);
 ModeMono:Array[0..15] of Byte=($61,$50,$52,$0F,$19,$06,$19,$19,$02,$0D,$0b,$0c,$00,$00,$00,$00); 
 ModeGrf:Array[0..15] of Byte=($38,$28,$2D,$0A,$7F,$06,$64,$70,$02,$01,$06,$07,$00,$00,$00,$00);
Var 
 ClearFlag:Boolean; 
 I,x80:Byte; 
 Offset:Word;
 _AH:Byte;
 _BL,_BH:Byte;
 _CL,_CH:Byte;
 _DL,_DH:Byte; 
Begin
 ClearFlag := Boolean(Mode shr 7);
 Case Mode and $7F of
  $00,$01,      { Mode Texte 40x25 }
  $02,$03:Begin { Mode Texte 80x25 }
   x80 := Mode shr 1;
   ASM
    XOR AX,AX;
    MOV ES,AX;
    MOV DX,$3B4;
    CMP ES:[$0463],DX;
    JNE @@1;
    MOV DL,$BA;
    MOV AL,$80;
    OUT DX,AL;
    MOV DL,$D4;
    MOV ES:[$0463],DX;
    MOV AL,ES:[$0410];
    AND AL,NOT(16 + 32);
    OR  AL,32;
    MOV ES:[$0410],AL;
@@1:
   END;
   Port[$3D8] := $02 or (Mem[$0040:$65] and (1 shl 5));
   Port[$3DD] := $00;
   Mem[$0040:$65] := (Mem[$0040:$65] and (1 shl 5)) or x80;
   Port[$3D8] := $04 or Mem[$0040:$65];
   For I := 0 to 15 do Begin
    Port[$3D4] := I;
    Port[$3D5] := ModeTxt[x80,I];
   End;
   Port[$3D8] := $0C or Mem[$0040:$65];
   Port[$3D9] := $30; Port[$3DD] := $00; Port[$3DF] := $80;
   If Not(ClearFlag)Then FillWord(Mem[$B800:0],$2000,$0720);
   Mem[$0040:$49] := Mode and $7F;
   MemW[$0040:$4C] := 4096; MemW[$0040:$4E] := 0; Mem[$0040:$62] := 0;
   MemW[$0040:$4A] := 80; Mem[$0040:$84] := 24; MemW[$0040:$85] := 8;
  End;
  $04,$05,$06:Begin { Graphique 320/640x200 en 4/2 couleurs }
   x80 := Byte(Mode = $06) shl 4;
   ASM
    CLI;
    XOR AX,AX;
    MOV ES,AX;
    MOV DX,$3B4;
    CMP ES:[$0463],DX;
    JNE @@1;
    MOV DL,$BA;
    MOV AL,$80;
    OUT DX,AL;
    MOV DL,$D4;
    MOV ES:[$0463],DX;
    MOV AL,ES:[$0410];
    AND AL,NOT(16 + 32);
    OR  AL,32;
    MOV ES:[$0410],AL;
@@1:
    MOV DL,$D8;
    MOV AL,$06;
    OR  AL,x80;
    OUT DX,AL;
   END;
   For I := 0 to 15 do Begin
    Port[$3D4] := I;
    Port[$3D5] := ModeGrf[I];
   End;
   ASM
    MOV DX,$3D8;
    MOV AL,$0E;
    OR  AL,x80;
    OUT DX,AL;
    INC DX; { DX = 3D9h }
    MOV AL,15;
    OUT DX,AL;
    MOV DL,$DF;
    MOV AL,$80;
    OUT DX,AL; { Port[3DFh] := 80h }
    STI;
   END;
   If Not(ClearFlag)Then FillChar(Mem[$B800:0],$7FFF,0);
   Mem[$0040:$49] := Mode and $7F;
   MemW[$0040:$4C] := 16384; MemW[$0040:$4E] := 0; Mem[$0040:$62] := 0;
   MemW[$0040:$4A] := 80; Mem[$0040:$84] := 24; MemW[$0040:$85] := 8;
  End;
  $07:Begin { Mono Texte }
   If(MemW[$0040:$63] = $3D4)Then Begin      
    Port[$3DF] := $47; Port[$3BF] := $00;
    MemW[$0040:$63] := $3B4;
    Mem[$0040:$10] := (Mem[$0040:$10] and Not(16+32)) or (16+32);
   End;
   Port[$3B8] := $08;
   For I := 0 to 15 do Begin
    Port[$3B4] := I;
    Port[$3B5] := ModeMono[I];
   End;
   Port[$3B8] := $08;
   Mem[$0040:$49] := 7;
   MemW[$0040:$4C] := 4096; MemW[$0040:$4E] := 0; Mem[$0040:$62] := 0;
   MemW[$0040:$63] := $3B4;
   MemW[$0040:$4A] := 80; Mem[$0040:$84] := 24; MemW[$0040:$85] := 14;
  End;
  $08:Begin { 132x25 }
   ASM
    XOR AX,AX;
    MOV ES,AX;
    MOV DX,$3B4;
    CMP ES:[$0463],DX;
    JNE @@1;
    MOV DL,$BA;
    MOV AL,$80;
    OUT DX,AL;
    MOV DL,$D4;
    MOV ES:[$0463],DX;
    MOV AL,ES:[$0410];
    AND AL,NOT(16 + 32);
    OR  AL,32;
    MOV ES:[$0410],AL;
@@1:
   END;
   If Not(ClearFlag)Then FillWord(Mem[$B800:0],$2000,$0720);
   Port[$3D8] := $02; Port[$3DD] := $00; Port[$3D8] := $05;
   For I := 0 to 15 do Begin
    Port[$3D4] := I;
    Port[$3D5] := ModeTxt132[I];
   End;
   Port[$3D8] := $0D; Port[$3D9] := $30; Port[$3DD] := $00; Port[$3DF] := $90;
   Mem[$0040:$49] := 7;
   MemW[$0040:$4C] := 6600; MemW[$0040:$4E] := 0; Mem[$0040:$62] := 0;
   Mem[$0040:$4A] := 132; Mem[$0040:$84] := 24; MemW[$0040:$85] := 8;
  End;
 End;
 FillChar(Mem[$0040:$50],16,0);
End; 

Function DuplicateString(C:Char;Num:Integer):String;
Var
 I:Byte;
 S:String;
Begin
 S:='';
 For I:=1 to Num do S:=S+C;
 DuplicateString:=S;
End;

Procedure ShowLine(Num:Byte);Begin
 Case Num of
  0:WriteLn(' [A.]  Texte monochrome 80x25                 - MT');
  1:WriteLn(' [B.]  Monochrome Graphics 1 page             - MG1');
  2:WriteLn(' [C.]  Monochrome Graphics 2 pages            - MG2');
  3:WriteLn(' [D.]  Texte couleur 80x25                    - C80');
  4:WriteLn(' [E.]  132x25 colonnes                        - L25');
  5:WriteLn(' [F.]  132x44 colonnes                        - L44');
  6:WriteLn(' [G.]  Change au moniteur RVB');
  7:WriteLn(' [H.]  Ajustement de l''ecran 132 colonnes');
 End;
End;

Procedure ShowLineSelected(Num:Byte);Begin
 GotoXY(1,10+Num);
 TextColor(Black);
 TextBackground(LightGray);
 ShowLine(Num);
 GotoXY(1,10+Num);
End;

Procedure ShowLineUnselected(Num:Byte);Begin
 GotoXY(1,10+Num);
 TextColor(LightGray);
 TextBackground(Black);
 ShowLine(Num);
End;

Procedure ShowPresentation;Begin
 WriteLn(#201,DuplicateString(#205,56),#187);
 WriteLn(#186,'ATI TECHNOLOGIES INC ATI TECHNOLOGIES INC ATI TECHNOLOGI',#186);
 WriteLn(#186,'ES INC ATI TECHNOLOGIES INC ATI TECHNOLOGIES INC ATI TEC',#186);
 WriteLn(#186,'HNOLOGIES INC ATI TECHNOLOGIES INC ATI TECHNOLOGIES INC ',#186);
 WriteLn(#186,'                                                        ',#186);
 WriteLn(#200,DuplicateString(#205,56),#188);
 WriteLn;
 WriteLn('  Graphics Solution Mode Menu de sélection clone  Version B2.03 ');
 WriteLn;
 For J:=0 to 7 do ShowLine(J);
 WriteLn; 
 Write('CURRENT STATUS: ');
 If Mem[$0040:$49]=7 Then WriteLn('Texte monochrome 80x25 (M80)')
                     Else WriteLn('Texte couleur80x25 (C80)');
 WriteLn;
 WriteLn(' Utiliser <Fleche Haut/Bas> ou une <Lettre> et <Enter> pour selectionner Option, <Esc> pour abandonner');
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('MS : Cette commande permet de lancer le MultiSwitch.');
  WriteLn;
  WriteLn('Syntaxe : MS [MT|C80|L25]');
  WriteLn;
  WriteLn('           MT    Mode monochrome texte');
  WriteLn('           C80   Mode texte couleur 80x25');
  WriteLn('           L25   Mode texte couleur 132x25');
 End
  Else
 If StrToUpper(ParamStr(1))='MT'Then SetModeGS(7) Else
 If StrToUpper(ParamStr(1))='C80'Then SetModeGS(3) Else
 If StrToUpper(ParamStr(1))='L25'Then SetModeGS(8)
  Else
 Begin
  TextMode(BW80);
  ShowPresentation;
  If Mem[$0040:$49]=7 Then J:=0
                      Else J:=3;
  ShowLineSelected(J);
  Repeat
   K:=Byte(ReadKey);
   Case K of
    Byte('A'),Byte('a'):SetModeGS(7);
    Byte('B'),Byte('b'):WriteLn('Fonction non implémenté !');
    Byte('C'),Byte('c'):WriteLn('Fonction non implémenté !');
    Byte('D'),Byte('d'):SetModeGS(3);
    Byte('E'),Byte('e'):SetModeGS(8);
    Byte('F'),Byte('f'):WriteLn('Fonction non implémenté !');
    Byte('G'),Byte('g'):WriteLn('Fonction non implémenté !');
    Byte('H'),Byte('h'):WriteLn('Fonction non implémenté !');
   End;
   If K=0Then K:=K or (Byte(ReadKey)shl 8);
   Case K of
    kbUp:Begin
     ShowLineUnselected(J);
     J:=(J-1) and 7;
	 ShowLineSelected(J);
    End;
    kbDn:Begin
     ShowLineUnselected(J);
     J:=(J+1) and 7;
	 ShowLineSelected(J);
    End;   
    kbEnter:Begin
     Case J of
	  0:SetModeGS(7);
	  3:SetModeGS(3);
	  4:SetModeGS(8);
 	  Else WriteLn('Fonction non implémenté !');
	 End;
 	 Break;
    End;
   End;
  Until K=kbEsc;
  TextColor(LightGray);
  TextBackground(Black);
  ClrScr;
 End;
END.