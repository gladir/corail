{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program ASCII;

Uses Crt;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
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

Var
 I,J:Integer;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASCII : Cette commande permet d''afficher la table ASCII de la console.');
  WriteLn;
  {$IFDEF FPC}
   {$IFDEF WINDOWS}
    WriteLn('Syntaxe : ASCII [/ACP]');
    WriteLn;
    WriteLn(' /ACP  - Utilise le mode ACP du CRT');
   {$ELSE}
    WriteLn('Syntaxe : ASCII');
   {$ENDIF}
  {$ELSE}
   WriteLn('Syntaxe : ASCII');
  {$ENDIF}
  WriteLn;
 End
  Else
 Begin
  {$IFDEF FPC}
   If StrToUpper(ParamStr(1))<>'/ACP'Then SetUseACP(False);
  {$ENDIF}
  For J:=0 to 15 do Begin
   For I:=0 to 15 do Begin
    Write(ByteHex2Str(J*16+I):4);
   End;
   WriteLn;
   For I:=0 to 15 do Begin
    Write(J*16+I:4);
   End;
   WriteLn;
   For I:=0 to 15 do Begin
    If(J*16+I)in [7..8,10,13]Then Write(' ':4)
                             Else Write(Chr(J*16+I):4);
   End;
   WriteLn;
   WriteLn;
  End;
 End;
END.
