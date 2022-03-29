{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program HD;

Var
 Option:(_None,_Offset);
 I:Integer;
 ByteReaded:Integer;
 Err:Word;
 StartPos,CurrPos:LongInt;
 FileView:File;
 FileName:String;
 Buffer:Array[0..255]of Byte;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('HEXDUMP : Cette commande permet d''afficher le contenu d''un fichier en format hexadecimal.');
  WriteLn;
  WriteLn('Syntaxe : HEXDUMP fichier [option]');
  WriteLn;
  WriteLn(' fichier           Nom du fichier a afficher');
  WriteLn(' -s deplacement    Deplacement d''octets a partir du debut');
  WriteLn;
 End
  Else
 Begin
  Option:=_None;
  StartPos:=0;
  FileName:='';
  For I:=1 to ParamCount do Begin
   If Option=_Offset Then Begin
    Option:=_None;
    Val(ParamStr(I),StartPos,Err);
   End
    Else
   If ParamStr(I)='-s'Then Option:=_Offset
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
   Seek(FileView,StartPos);
   While Not EOF(FileView)do Begin
    BlockRead(FileView,Buffer,16,ByteReaded);
    Write(LongHex2Str(CurrPos),' ');
    For I:=0 to 15 do Begin
     If I>=ByteReaded Then Write(' ':3)
                     Else Write(ByteHex2Str(Buffer[I]),' ');
     If I=7Then Write(' ');
    End;
    Write(' |');
    For I:=0 to 15 do Begin
     If I>=ByteReaded Then Write(' ')Else
     If Buffer[I]<32Then Write(' ')
                    Else Write(Char(Buffer[I]));
    End;
    Write('|');
    WriteLn;
    Inc(CurrPos,ByteReaded);
   End;
   Close(FileView);
  End;
 End;
END.