Program MD5;

{$A-}
{$R-,Q-}

Uses Strings;

Type
 TMDDigest=Record Case Integer of
  0:(_LongInt:Array[0..3] of LongInt);
  1:(_Byte:Array[0..15] of Byte);
 End;
 TByte=Array[0..255]of Byte;
 Padding=Record Case Integer of
  0:(_LongInt:Array[0..15] of LongInt);
  1:(_Byte:Array[0..63]of Byte);
  2:(_Char:Array[0..47]of Char);
  3:(_Record:Record A,B:LongInt;End);
 End;

Var
 Context:Record
  Align:Word;
  BufCnt:LongInt;
  Buffer:Array[0..63] of Byte;
  Length:LongInt;
 End;

 State:Record Case Integer of
  0:(_LongInt:Array[0..3] of LongInt);
  1:(_Byte:Array[0..15]of Byte);
 End;
 ToUpper:Boolean;

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

Function RotateLeftDWord(Value,Shift:LongInt):LongInt;Begin
 RotateLeftDWord:=LongInt(Value shl LongInt(Shift))or LongInt(Value shr LongInt(32-Shift));
End;

Procedure MD5Transform(Buffer:Pointer);
Type
 TBlock=array[0..15] of LongInt;
 PBlock=^TBlock;
Var
 a,b,c,d:LongInt;
 Block:PBlock absolute Buffer;
Begin
 a:=State._LongInt[0];
 b:=State._LongInt[1];
 c:=State._LongInt[2];
 d:=State._LongInt[3];

  { Arrondissement 1 }
 a := b + RotateLeftDWord(LongInt(a + ((b and c) or ((not b) and d)) + Block^[0]  + $d76aa478),  7);
 d := a + RotateLeftDWord(LongInt(d + ((a and b) or ((not a) and c)) + Block^[1]  + $e8c7b756), 12);
 c := d + RotateLeftDWord(LongInt(c + ((d and a) or ((not d) and b)) + Block^[2]  + $242070db), 17);
 b := c + RotateLeftDWord(LongInt(b + ((c and d) or ((not c) and a)) + Block^[3]  + $c1bdceee), 22);
 a := b + RotateLeftDWord(LongInt(a + ((b and c) or ((not b) and d)) + Block^[4]  + $f57c0faf),  7);
 d := a + RotateLeftDWord(LongInt(d + ((a and b) or ((not a) and c)) + Block^[5]  + $4787c62a), 12);
 c := d + RotateLeftDWord(LongInt(c + ((d and a) or ((not d) and b)) + Block^[6]  + $a8304613), 17);
 b := c + RotateLeftDWord(LongInt(b + ((c and d) or ((not c) and a)) + Block^[7]  + $fd469501), 22);
 a := b + RotateLeftDWord(LongInt(a + ((b and c) or ((not b) and d)) + Block^[8]  + $698098d8),  7);
 d := a + RotateLeftDWord(LongInt(d + ((a and b) or ((not a) and c)) + Block^[9]  + $8b44f7af), 12);
 c := d + RotateLeftDWord(LongInt(c + ((d and a) or ((not d) and b)) + Block^[10] + $ffff5bb1), 17);
 b := c + RotateLeftDWord(LongInt(b + ((c and d) or ((not c) and a)) + Block^[11] + $895cd7be), 22);
 a := b + RotateLeftDWord(LongInt(a + ((b and c) or ((not b) and d)) + Block^[12] + $6b901122),  7);
 d := a + RotateLeftDWord(LongInt(d + ((a and b) or ((not a) and c)) + Block^[13] + $fd987193), 12);
 c := d + RotateLeftDWord(LongInt(c + ((d and a) or ((not d) and b)) + Block^[14] + $a679438e), 17);
 b := c + RotateLeftDWord(LongInt(b + ((c and d) or ((not c) and a)) + Block^[15] + $49b40821), 22);
  { Arrondissement 2 }
 a := b + RotateLeftDWord(LongInt(a + ((b and d) or (c and (not d))) + Block^[1]  + $f61e2562),  5);
 d := a + RotateLeftDWord(LongInt(d + ((a and c) or (b and (not c))) + Block^[6]  + $c040b340),  9);
 c := d + RotateLeftDWord(LongInt(c + ((d and b) or (a and (not b))) + Block^[11] + $265e5a51), 14);
 b := c + RotateLeftDWord(LongInt(b + ((c and a) or (d and (not a))) + Block^[0]  + $e9b6c7aa), 20);
 a := b + RotateLeftDWord(LongInt(a + ((b and d) or (c and (not d))) + Block^[5]  + $d62f105d),  5);
 d := a + RotateLeftDWord(LongInt(d + ((a and c) or (b and (not c))) + Block^[10] + $02441453),  9);
 c := d + RotateLeftDWord(LongInt(c + ((d and b) or (a and (not b))) + Block^[15] + $d8a1e681), 14);
 b := c + RotateLeftDWord(LongInt(b + ((c and a) or (d and (not a))) + Block^[4]  + $e7d3fbc8), 20);
 a := b + RotateLeftDWord(LongInt(a + ((b and d) or (c and (not d))) + Block^[9]  + $21e1cde6),  5);
 d := a + RotateLeftDWord(LongInt(d + ((a and c) or (b and (not c))) + Block^[14] + $c33707d6),  9);
 c := d + RotateLeftDWord(LongInt(c + ((d and b) or (a and (not b))) + Block^[3]  + $f4d50d87), 14);
 b := c + RotateLeftDWord(LongInt(b + ((c and a) or (d and (not a))) + Block^[8]  + $455a14ed), 20);
 a := b + RotateLeftDWord(LongInt(a + ((b and d) or (c and (not d))) + Block^[13] + $a9e3e905),  5);
 d := a + RotateLeftDWord(LongInt(d + ((a and c) or (b and (not c))) + Block^[2]  + $fcefa3f8),  9);
 c := d + RotateLeftDWord(LongInt(c + ((d and b) or (a and (not b))) + Block^[7]  + $676f02d9), 14);
 b := c + RotateLeftDWord(LongInt(b + ((c and a) or (d and (not a))) + Block^[12] + $8d2a4c8a), 20);
  { Arrondissement 3 }
 a := b + RotateLeftDWord(LongInt(a + (b xor c xor d) + Block^[5]  + $fffa3942),  4);
 d := a + RotateLeftDWord(LongInt(d + (a xor b xor c) + Block^[8]  + $8771f681), 11);
 c := d + RotateLeftDWord(LongInt(c + (d xor a xor b) + Block^[11] + $6d9d6122), 16);
 b := c + RotateLeftDWord(LongInt(b + (c xor d xor a) + Block^[14] + $fde5380c), 23);
 a := b + RotateLeftDWord(LongInt(a + (b xor c xor d) + Block^[1]  + $a4beea44),  4);
 d := a + RotateLeftDWord(LongInt(d + (a xor b xor c) + Block^[4]  + $4bdecfa9), 11);
 c := d + RotateLeftDWord(LongInt(c + (d xor a xor b) + Block^[7]  + $f6bb4b60), 16);
 b := c + RotateLeftDWord(LongInt(b + (c xor d xor a) + Block^[10] + $bebfbc70), 23);
 a := b + RotateLeftDWord(LongInt(a + (b xor c xor d) + Block^[13] + $289b7ec6),  4);
 d := a + RotateLeftDWord(LongInt(d + (a xor b xor c) + Block^[0]  + $eaa127fa), 11);
 c := d + RotateLeftDWord(LongInt(c + (d xor a xor b) + Block^[3]  + $d4ef3085), 16);
 b := c + RotateLeftDWord(LongInt(b + (c xor d xor a) + Block^[6]  + $04881d05), 23);
 a := b + RotateLeftDWord(LongInt(a + (b xor c xor d) + Block^[9]  + $d9d4d039),  4);
 d := a + RotateLeftDWord(LongInt(d + (a xor b xor c) + Block^[12] + $e6db99e5), 11);
 c := d + RotateLeftDWord(LongInt(c + (d xor a xor b) + Block^[15] + $1fa27cf8), 16);
 b := c + RotateLeftDWord(LongInt(b + (c xor d xor a) + Block^[2]  + $c4ac5665), 23);
  { Arrondissement 4 }
 a := b + RotateLeftDWord(LongInt(a + (c xor (b or (not d))) + Block^[0]  + $f4292244),  6);
 d := a + RotateLeftDWord(LongInt(d + (b xor (a or (not c))) + Block^[7]  + $432aff97), 10);
 c := d + RotateLeftDWord(LongInt(c + (a xor (d or (not b))) + Block^[14] + $ab9423a7), 15);
 b := c + RotateLeftDWord(LongInt(b + (d xor (c or (not a))) + Block^[5]  + $fc93a039), 21);
 a := b + RotateLeftDWord(LongInt(a + (c xor (b or (not d))) + Block^[12] + $655b59c3),  6);
 d := a + RotateLeftDWord(LongInt(d + (b xor (a or (not c))) + Block^[3]  + $8f0ccc92), 10);
 c := d + RotateLeftDWord(LongInt(c + (a xor (d or (not b))) + Block^[10] + $ffeff47d), 15);
 b := c + RotateLeftDWord(LongInt(b + (d xor (c or (not a))) + Block^[1]  + $85845dd1), 21);
 a := b + RotateLeftDWord(LongInt(a + (c xor (b or (not d))) + Block^[8]  + $6fa87e4f),  6);
 d := a + RotateLeftDWord(LongInt(d + (b xor (a or (not c))) + Block^[15] + $fe2ce6e0), 10);
 c := d + RotateLeftDWord(LongInt(c + (a xor (d or (not b))) + Block^[6]  + $a3014314), 15);
 b := c + RotateLeftDWord(LongInt(b + (d xor (c or (not a))) + Block^[13] + $4e0811a1), 21);
 a := b + RotateLeftDWord(LongInt(a + (c xor (b or (not d))) + Block^[4]  + $f7537e82),  6);
 d := a + RotateLeftDWord(LongInt(d + (b xor (a or (not c))) + Block^[11] + $bd3af235), 10);
 c := d + RotateLeftDWord(LongInt(c + (a xor (d or (not b))) + Block^[2]  + $2ad7d2bb), 15);
 b := c + RotateLeftDWord(LongInt(b + (d xor (c or (not a))) + Block^[9]  + $eb86d391), 21);

 Inc(State._LongInt[0],a);
 Inc(State._LongInt[1],b);
 Inc(State._LongInt[2],c);
 Inc(State._LongInt[3],d);
 Inc(Context.Length,64);
End;

Procedure MDUpdate(Var Buf:Padding;Const BufLen:Word);
Var
 Align:Word;
 Num,CurrNum:Word;
Begin
 If BufLen=0 Then Exit;
 Align:=Context.Align;
 Num:=0;
 CurrNum:=0;
 If Context.BufCnt>0 Then Begin
  Num:=Align-Context.BufCnt;
  If Num>BufLen Then Num:=BufLen;
  Move(Buf._Byte[CurrNum],Context.Buffer[Context.BufCnt],Num);
  Context.BufCnt:=Context.BufCnt+Num;
  CurrNum:=CurrNum+Num;
  If Context.BufCnt=Align Then Begin
   MD5Transform(@Context.Buffer);
   Context.BufCnt:=0;
  End;
 End;
 Num:=BufLen-Num;
 While Num>=Align do Begin
  MD5Transform(@Buf._Byte[CurrNum]);
  CurrNum:=CurrNum+Align;
  Num:=Num-Align;
 End;
 If Num>0 Then Begin
  Context.BufCnt:=Num;
  Move(Buf._Byte[CurrNum],Context.Buffer,Num);
 End;
End;

Function CalculateMD5(Const AStr:String):String;
Var
 PS:Padding;
 Digest:TMDDigest;
 i:Integer;
 S:String;
 Pads:Word;
 P:Word;
 PADDING_MD45,Len:Padding;
Begin
 FillChar(Context,Sizeof(Context),0);
 Context.Align:=64;
 State._LongInt[0]:=$67452301;
 State._LongInt[1]:=$efcdab89;
 State._LongInt[2]:=$98badcfe;
 State._LongInt[3]:=$10325476;
 Context.Length:=0;
 Context.BufCnt:=0;
 StrPCopy(PS._Char,AStr);
 MDUpdate(PS,Length(AStr));
 Len._Record.B:=0;
 Len._Record.A:=8*(Context.Length+Context.BufCnt);
 If Context.BufCnt>=56 Then Pads:=120-Context.BufCnt
                       Else Pads:=56-Context.BufCnt;
 FillChar(PADDING_MD45,SizeOf(PADDING_MD45),0);
 PADDING_MD45._LongInt[0]:=$80;
 MDUpdate(PADDING_MD45,Pads);
 MDUpdate(Len,8);
 P:=0;
 For I:=0 to (16 shr 2)-1 do Begin
  Digest._LongInt[I]:=LongInt(LongInt(State._Byte[P]))or
                      LongInt(LongInt(State._Byte[P+1])shl 8)or
                      LongInt(LongInt(State._Byte[P+2])shl 16)or
                      LongInt(LongInt(State._Byte[P+3])shl 24);
  Inc(P,4);
 End;
 S:='';
 For i:=0 to 15 do S:=S+ByteHex2Str(Digest._Byte[i]);
 CalculateMD5:=S;
End;

Var
 I:Integer;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('MD5 : Cette commande permet d''appliquer un algorithme MD5 ',
                 'sur la chaine de caractäres spÇcifiÇs.');
  WriteLn;
  WriteLn('Syntaxe : MD5 chaine [/UPPER]');
  WriteLn;
  WriteLn(' chaine   Permet d''indiquer la chaine de caractäres Ö convertir.');
  WriteLn(' /UPPER   Affiche les chaines MD5 en majuscules');
 End
  Else
 If ParamCount>0 Then Begin
  ToUpper:=False;
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/UPPER'Then ToUpper:=True;
  End;
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/UPPER'Then Begin
    { Sauter ...}
   End
    Else
   If(ToUpper)Then WriteLn(StrToUpper(CalculateMD5(ParamStr(I))))
              Else WriteLn(StrToLower(CalculateMD5(ParamStr(I))));
  End;
 End
  Else
 WriteLn('Paramätre requis !');
END.
