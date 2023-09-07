{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program GUID;

Var
 I:Integer;
 Lower:Boolean;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function StrToLower(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
 End;
 StrToLower:=S;
End;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

Function LongHex2Str(value:LongInt):String;
Begin
 LongHex2Str:=ByteHex2Str((value shr 24)and $FF)+
              ByteHex2Str((value shr 16)and $FF)+
              ByteHex2Str((value shr 8)and $FF)+
              ByteHex2Str(value and $FF);
End;

BEGIN
 Lower:=False;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('GUID - Cette commande permet de g‚n‚rer un nombre GUID');
  WriteLn;
  WriteLn('Syntaxe : GUID [/LOWER]');
  WriteLn;
  WriteLn('/LOWER   Ce paramŠtre permet de forcer le nombre en minuscule');
  Halt;
 End
  Else
 If ParamCount>0Then Begin
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/LOWER'Then Begin
    Lower:=True;
   End;
  End;
 End;
 If(Lower)Then Begin
  WriteLn(StrToLower(HexWord2Str(Random(65535))),
          StrToLower(HexWord2Str(Random(65535))),
          '-',StrToLower(HexWord2Str(Random(65535))),'-',
          StrToLower(HexWord2Str(Random(65535))),
          '-',StrToLower(HexWord2Str(Random(65535))),'-',
          StrToLower(HexWord2Str(Random(65535))),
          StrToLower(HexWord2Str(Random(65535))),
          StrToLower(HexWord2Str(Random(65535))));
 End
  Else
 Begin
  WriteLn(HexWord2Str(Random(65535)),HexWord2Str(Random(65535)),
          '-',HexWord2Str(Random(65535)),'-',HexWord2Str(Random(65535)),
          '-',HexWord2Str(Random(65535)),'-',
          HexWord2Str(Random(65535)),HexWord2Str(Random(65535)),
          HexWord2Str(Random(65535)));
 End;
END.
