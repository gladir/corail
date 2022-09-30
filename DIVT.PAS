{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal)
}

Program DIVT;

Type
 IntrPtr=Record
  _Ofs,_Seg:Byte;
 End;

Var
 Intr:Array[0..255]of IntrPtr Absolute $0000:$0000;
 I:Byte;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('DIVT: Cette commande permet d''afficher les adresses de la ',
           'tables des interruptions d''un microprocesseur 8086/8088.');
  WriteLn;
  WriteLn('Syntaxe : DIVT');
 End
  Else
 Begin
  For I:=0 to 255 do Begin
   WriteLn('Int ',ByteHex2Str(I),'h: ',HexWord2Str(Intr[I]._Seg),':',
                  HexWord2Str(Intr[I]._Ofs));
  End;
 End;
END.