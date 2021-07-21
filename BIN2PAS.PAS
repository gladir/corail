{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program BIN2PAS;

Var
 Source:File of Byte;
 Target:Text;
 Tampon:Array[0..0]of Byte;
 ByteReaded:Integer;
 Position:Byte;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BIN2PAS : Cette commande permet de convertir un ficiher binaire en tableau de Pascal.');
  WriteLn;
  WriteLn('Syntaxe : BIN2PAS fichier fichier.pas');
 End
  Else
 If ParamCount=2Then Begin
  Assign(Source,ParamStr(1));
  Reset(Source);
  Assign(Target,ParamStr(2));
  Rewrite(Target);
  Position:=0;
  WriteLn(Target,'Const samples:Array[0..',FileSize(Source)-1,'] of (');
  Write(Target,'  ');
  While Not EOF(Source)do Begin
   BlockRead(Source,Tampon,1,ByteReaded);
   Write(Target,'$',ByteHex2Str(Tampon[0]));
   If Not EOF(Source)Then Begin
    Write(Target,', ');
    Inc(Position);
    If Position=8Then BEgin
     WriteLn(Target);
     Write(Target,'  ');
    End;
    Position:=Position and 7;
   End;
  End;
  WriteLn(Target);
  WriteLn(Target,');');
  Close(Target);
  Close(Source);
 End
  Else
 WriteLn('Parametre invalide !');
END.