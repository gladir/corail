{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program OD(Input,Output);

Var
 Option:(_OctChar,_Char,_Dec,_Oct,_Hex);
 I:Integer;
 ByteReaded:Integer;
 CurrPos:LongInt;
 FileView:File;
 FileName:String;
 Buffer:Array[0..255]of Byte;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

Function OctByte2Str(value:Byte):String;
Const
 matrix:Array[0..7]of Char = ('0','1','2','3','4','5','6','7');
Begin
 OctByte2Str:=matrix[(value shr 6) and 7]+
              matrix[(value shr 3) and 7]+
              matrix[value and 7];
End;

Function OctWord2Str(value:Word):String;
Const
 matrix:Array[0..7]of Char = ('0','1','2','3','4','5','6','7');
Begin
 OctWord2Str:=matrix[(value shr 15) and 7]+
              matrix[(value shr 12) and 7]+
              matrix[(value shr 9) and 7]+
              matrix[(value shr 6) and 7]+
              matrix[(value shr 3) and 7]+
              matrix[value and 7];
End;


Function LongHex2Str(value:LongInt):String;
Begin
 LongHex2Str:=ByteHex2Str((value shr 24)and $FF)+
              ByteHex2Str((value shr 16)and $FF)+
              ByteHex2Str((value shr 8)and $FF)+
              ByteHex2Str(value and $FF);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('OD : Cette commande permet d''afficher le contenu d''un fichier selon un format specifique.');
  WriteLn;
  WriteLn('Syntaxe : OD [-b|-c|-d|-o|-x] fichier');
  WriteLn;
  WriteLn('  -b    Affiche en octal en caracteres');
  WriteLn('  -c    Affiche en caracteres avec echappement');
  WriteLn('  -d    Affiche en decimales');
  WriteLn('  -o    Affiche en octal');
  WriteLn('  -x    Affiche en hexadecimal');
 End
  Else
 Begin
  FileName:='';
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='-b'Then Option:=_OctChar Else
   If ParamStr(I)='-c'Then Option:=_Char Else
   If ParamStr(I)='-d'Then Option:=_Dec Else
   If ParamStr(I)='-o'Then Option:=_Oct Else
   If ParamStr(I)='-x'Then Option:=_Hex
                      Else FileName:=ParamStr(I);
  End;
  CurrPos:=0;
  If FileName=''Then Begin
   WriteLn('Fichier requis !');
  End
   Else
  Begin
   Assign(FileView,FileName);
   Reset(FileView,1);
   While Not EOF(FileView)do Begin
    BlockRead(FileView,Buffer,16,ByteReaded);
    Write(LongHex2Str(CurrPos),' ');
    For I:=0 to 15 do Begin
     Case Option of
      _OctChar:Write(OctByte2Str(Buffer[I]):4);
      _Char:Begin
       Case Buffer[I]of
            0:Write('\0':4);
            7:Write('\a':4);
            8:Write('\b':4);
            9:Write('\t':4);
           10:Write('\n':4);
           12:Write('\f':4);
           13:Write('\r':4);
     1..6,11,14..32,126..255:Write(OctByte2Str(Buffer[I]):4);
         Else Write(Buffer[I]:4);
       End;
      End;
      _Dec:Begin
       If I and 1=0Then Write(Buffer[I+1]+(Buffer[I] shl 8):5,' ');
      End;
      _Oct:Begin
       If I and 1=0Then Write(OctWord2Str(Buffer[I+1]+(Buffer[I] shl 8)),' ');
      End;
      _Hex:Begin
       Write(ByteHex2Str(Buffer[I]));
       If I and 1=1 Then Write(' ');
      End;
     End;
     If I>ByteReaded Then Break;
    End;
    WriteLn;
    Inc(CurrPos,ByteReaded);
   End;
   Close(FileView);
  End;
 End;
END.