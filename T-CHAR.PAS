{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program T_CHAR;

Uses Crt,DOS;

Var
 I,J:Integer;
 ShowASCII128,Terminated:Boolean;
 DefaultChar:Integer;

{$IFNDEF FPC}
 Procedure CursorOff;
 Var
  Regs:Registers;
 Begin
  Regs.AH:=1;
  Regs.CH:=32;
  Regs.CL:=0;
  Intr($10,Regs);
 End;

 Procedure CursorOn;
 Var
  Regs:Registers;
 Begin
  Regs.AX:=$0100;
  Regs.CX:=(7 shl 8)+9;
  Intr($10,Regs);
 End;
{$ENDIF}


Procedure PCopy(Source,Target:Byte);Begin
 {$IFNDEF FPC}
  Move(Mem[SegB800:Source*(MemW[$0040:$4A]*25*2)],Mem[SegB800:Target*(MemW[$0040:$4A]*25*2)],MemW[$0040:$4A]*25*2)
 {$ENDIF}
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

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function Bin(X:Byte):String;
Var
 I:Integer;
 S:String;
Begin
 If X=0 Then Begin
  Bin:='00000000';
  Exit;
 End;
 S:='';
 For I:=0 to 7 do Begin
  S:=Chr(Byte('0')+((X shr I)and 1))+S;
 End;
 Bin:=S;
End;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Procedure Box(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Window(X1,Y1,X2,Y2);
 TextBackground((Couleur shr 4)and 15);
 {$IFDEF FPC}
  If Couleur and $80=$80 Then Begin
   TextColor((Couleur and 15)+BLINK);
  End
   Else
  TextColor(Couleur and 15);
 {$ELSE}
  TextColor(Couleur and 15);
 {$ENDIF}
 ClrScr;
 Window(1,1,80,25);
End;

Procedure FrameEmpty(X1,Y1,X2,Y2,Couleur:Byte);
Var
 I:Byte;
 ChrHori,ChrVert:Char;
 Chr218,Chr192,Chr191,Chr217:Char;
Begin
 TextBackground((Couleur shr 4)and 15);
 TextColor(Couleur and 15);
 If(ShowASCII128)Then Begin
  ChrHori:='-';
  ChrVert:='|';
  Chr218:='+';
  Chr192:='+';
  Chr191:='+';
  Chr217:='+';
 End
  Else
 Begin
  ChrHori:=#205;
  ChrVert:=#186;
  Chr218:=#201;
  Chr192:=#200;
  Chr191:=#187;
  Chr217:=#188;
 End;
 For I:=Y1+1 to Y2-1 do Begin
  GotoXY(X1,I);
  Write(ChrVert);
  GotoXY(X2,I);
  Write(ChrVert);
 End;
 GotoXY(X1+1,Y1);
 Write(DuplicateString(ChrHori,X2-X1-1));
 GotoXY(X1+1,Y2);
 Write(DuplicateString(ChrHori,X2-X1-1));
 GotoXY(X1,Y1);
 Write(Chr218);
 GotoXY(X1,Y2);
 Write(Chr192);
 GotoXY(X2,Y1);
 Write(Chr191);
 GotoxY(X2,Y2);
 Write(Chr217);
End;

Procedure HideChar;Begin
 TextBackground(Black);
 TextColor(LightGray);
 GotoXY(45+((DefaultChar and $F)shl 1),4);
 Write(' ');
 GotoXY(45+((DefaultChar and $F)shl 1),21);
 Write(' ');
 GotoXY(43,5+(DefaultChar shr 4));
 Write(' ');
 GotoXY(77,5+(DefaultChar shr 4));
 Write(' ');
 GotoXY(45+((DefaultChar and $F)shl 1),5+(DefaultChar shr 4));
 Write(Char(DefaultChar));
End;

Procedure ShowChar;Begin
 TextBackground(Black);
 TextColor(LightCyan);
 GotoXY(45,3);
 Write(Char(DefaultChar));
 GotoXY(53,3);
 Write(DefaultChar,' ');
 GotoXY(61,3);
 Write(ByteHex2Str(DefaultChar));
 GotoXY(68,3);
 Write(Bin(DefaultChar));
 GotoXY(45+((DefaultChar and $F)shl 1),4);
 Write(#25);
 GotoXY(45+((DefaultChar and $F)shl 1),21);
 Write(#24);
 GotoXY(43,5+(DefaultChar shr 4));
 Write(#26);
 GotoXY(77,5+(DefaultChar shr 4));
 Write(#27);
 TextBackground(LightGray);
 TextColor(Black);
 GotoXY(45+((DefaultChar and $F)shl 1),5+(DefaultChar shr 4));
 Write(Char(DefaultChar));
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('T-CHAR : Cette commande permet d''afficher la table ASCII de la console.');
  WriteLn;
  {$IFDEF FPC}
   {$IFDEF WINDOWS}
    WriteLn('Syntaxe : T-CHAR [/ACP]');
    WriteLn;
    WriteLn(' /ACP  - Utilise le mode ACP du CRT');
   {$ELSE}
    WriteLn('Syntaxe : T-CHAR');
   {$ENDIF}
  {$ELSE}
   WriteLn('Syntaxe : T-CHAR');
  {$ENDIF}
  WriteLn;
 End
  Else
 Begin
  CursorOff;
  ShowASCII128:=False;
  {$IFDEF FPC}
   {$IFDEF WINDOWS}
    If StrToUpper(ParamStr(1))<>'/ACP'Then SetUseACP(False);
   {$ENDIF}
  {$ENDIF}
  PCopy(0,1);
  Box(40,1,80,23,$0B);
  FrameEmpty(40,1,80,23,$0B);
  GotoXY(55,1);
  Write(#185);
  TextBackground(Blue);
  TextColor(Yellow);
  Write(' CaractŠre s‚lectionn‚ ');
  TextBackground(Black);
  TextColor(LightCyan);
  Write(#204);
  TextColor(LightGray);
  GotoXY(44,3);
  Write(' ':3,'ASCII',' ':5,'HEX',' ':4,'BIN');
  For J:=0 to 15 do Begin
   GotoXY(44,5+J);
   For I:=0 to 15 do Begin
    If(J*16+I)in [7..8,10,13]Then Write(' ':2)
                             Else Write(Chr(J*16+I):2);
   End;
  End;
  DefaultChar:=Byte('h');
  Terminated:=False;
  ShowChar;
  Repeat
   Case ReadKey of
    #0:Case ReadKey of
     #72:Begin { Haut }
      HideChar;
      DefaultChar:=(DefaultChar-16)and $FF;
      ShowChar;
     End;
     #75:Begin { Gauche }
      HideChar;
      DefaultChar:=(DefaultChar-1)and $FF;
      ShowChar;
     End;
     #77:Begin { Droite }
      HideChar;
      DefaultChar:=(DefaultChar+1)and $FF;
      ShowChar;
     End;
     #80:Begin { Bas }
      HideChar;
      DefaultChar:=(DefaultChar+16)and $FF;
      ShowChar;
     End;
    End;
    #27:Terminated:=True;
   End;
  Until Terminated;
  Box(40,1,80,23,$07);
  PCopy(1,0);
  CursorOn;
 End;
END.