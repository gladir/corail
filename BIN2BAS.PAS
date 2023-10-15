{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BIN2PAS;

Var
 Source:File;
 Target:Text;
 Tampon:Array[0..0]of Byte;
 ByteReaded:Integer;
 Position:Byte;
 CurrLine:LongInt;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BIN2BAS : Cette commande permet de convertir un fichier binaire en DATA du BASIC.');
  WriteLn;
  WriteLn('Syntaxe : BIN2BAS fichier fichier.bas');
 End
  Else
 If ParamCount=2Then Begin
  CurrLine:=10;
  Assign(Source,ParamStr(1));
  Reset(Source,1);
  Assign(Target,ParamStr(2));
  Rewrite(Target);
  Position:=0;
  Write(Target,CurrLine,' DATA ');
  While Not EOF(Source)do Begin
   BlockRead(Source,Tampon,1,ByteReaded);
   Write(Target,Tampon[0]);
   If Not EOF(Source)Then Begin
    Inc(Position);
    If Position=16Then BEgin
     WriteLn(Target);
     Inc(CurrLine,10);
     Write(Target,CurrLine,' DATA ');
    End
     Else
    Write(Target,',');
    Position:=Position and $F;
   End;
  End;
  WriteLn(Target);
  Close(Target);
  Close(Source);
 End
  Else
 WriteLn('Parametre invalide !');
END.
