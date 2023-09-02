{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program HEX2DEC;

Var
 I:Integer;
 R:LongInt;
 Err:Word;

Function TrimLeftZero(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If S[I]<>'0'Then Begin
   TrimLeftZero:=Copy(S,I,255);
   Exit;
  End;
 End;
 TrimLeftZero:=S;
End;

Function Hex2Integer(hexStr:String):LongInt;
Var
 hexVal:LongInt;
 evalErr:Boolean;
 i,n:LongInt;
Begin
 Err:=0;
 evalErr:=False;
 hexVal:=0;
 For i:=1 to Length(hexStr) do Begin
  n:=Pos(Upcase(hexStr[i]),'0123456789ABCDEF');
  If n=0 Then evalErr:=True
         Else hexVal:=hexVal*16+n-1;
 End;
 If evalErr Then Begin
  hexVal:=0;
  Err:=1;
 End;
 Hex2Integer:=hexVal;
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

Function IsHex(S:String):Boolean;
Var
 I:Integer;
 Hex:Boolean;
Begin
 Hex:=False;
 For I:=1 to Length(S)do Begin
  If S[I]in['A'..'F','a'..'f','x','X']Then Begin
   IsHex:=True;
   Exit;
  End;
 End;
 IsHex:=Hex;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('HEX2DEC : Cette commande permet de convertir un nombre ',
                    'hexad‚cimal en d‚cimal en vice versa.');
  WriteLn;
  WriteLn('Syntaxe : HEX2DEC [hex|dec]');
  WriteLn;
  WriteLn(' dec  Ce paramŠtre permet d''indiquer un nombre d‚cimal.');
  WriteLn(' hex  Ce paramŠtre permet d''indiquer un nombre hexad‚cimal.');
  WriteLn;
 End
  Else
 If ParamCount>0 Then Begin
  For I:=1 to ParamCount do Begin
   If IsHex(ParamStr(I))Then Begin
    Write(ParamStr(I),' = ');
    If Copy(ParamStr(I),1,2)='0x'Then Begin
     WriteLn(Hex2Integer(Copy(ParamStr(I),3,255)));
    End
     Else
    WriteLn(Hex2Integer(ParamStr(I)));
   End
    Else
   Begin
    Val(ParamStr(I),R,Err);
    If R in[0..255]Then Begin
     WriteLn(ParamStr(I),' = ','0x',TrimLeftZero(ByteHex2Str(R)));
    End
     Else
    If(R>=256)and(R<=65535)Then Begin
     WriteLn(ParamStr(I),' = ','0x',TrimLeftZero(HexWord2Str(R)));
    End
     Else
    Begin
     WriteLn(ParamStr(I),' = ','0x',TrimLeftZero(LongHex2Str(R)));
    End;
   End;
  End;
 End;
END.