{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BIN2ASM;

Var
 Mode:(_None,_DB,_DD,_DW,_DQ,_DT);
 Source:File;
 Target:Text;
 Tampon:Array[0..10]of Byte;
 TW:Word Absolute Tampon;
 TD:LongInt Absolute Tampon;
 ByteReaded:Integer;
 Position:Byte;
 I,WidthData:Integer;
 StartPos:LongInt;
 Err:Word;
 SourceFileName,TargetFileName:String;

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

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BIN2ASM : Cette commande permet de convertir un fichier binaire ',
                     'en instructions DB ou autre de l''assembleur.');
  WriteLn;
  WriteLn('Syntaxe : BIN2ASM [/D(B|W|D)] source dest.ASM');
  WriteLn;
  WriteLn('source    Nom du fichier source binaire');
  WriteLn('dest.ASM  Nom du fichier assembleur … g‚n‚rer.');
  WriteLn(' /Annnn   Position de d‚but en hexad‚cimal');
  WriteLn(' /Bnnnn   Position de d‚but en d‚cimal');
  WriteLn(' /DB      Sort les donn‚es avec des instructions DB');
  WriteLn(' /DD      Sort les donn‚es avec des instructions DD');
  WriteLn(' /DW      Sort les donn‚es avec des instructions DW');
  WriteLn(' /Snn     Nombre de donn‚es en hexad‚cimal (01 … 80)');
  WriteLn(' /Wnn    Nombre de donn‚es en d‚cimal (1 … 80)');
 End
  Else
 If ParamCount>0Then Begin
  Mode:=_DB;
  StartPos:=0;
  WidthData:=16;
  SourceFileName:='';
  TargetFileName:='';
  For I:=1 to ParamCount do Begin
   If Copy(StrToUpper(ParamStr(I)),1,2)='/A'Then Begin
    StartPos:=Hex2Integer(Copy(ParamStr(I),3,255));
    If Err>0 Then Begin
     WriteLn('Valeur invalide !');
     Halt;
    End;
   End
    Else
   If Copy(StrToUpper(ParamStr(I)),1,2)='/B'Then Begin
    Val(Copy(ParamStr(I),3,255),StartPos,Err);
    If Err>0 Then Begin
     WriteLn('Valeur invalide !');
     Halt;
    End;
   End
    Else
   If(StrToUpper(ParamStr(I))='/D')or(StrToUpper(ParamStr(I))='/DB')Then Begin
    Mode:=_DB;
   End
    Else
   If StrToUpper(ParamStr(I))='/DW'Then Begin
    Mode:=_DW;
   End
    Else
   If StrToUpper(ParamStr(I))='/DD'Then Begin
    Mode:=_DD;
   End
    Else
   If Copy(StrToUpper(ParamStr(I)),1,2)='/S'Then Begin
    WidthData:=Hex2Integer(Copy(ParamStr(I),3,255));
    If Err>0 Then Begin
     WriteLn('Valeur invalide !');
     Halt;
    End;
    If Not(WidthData in[$01..$80])Then Begin
     WriteLn('Nombre de donn‚es en dehors de l''intervalle !');
     Halt;
    End;
   End
    Else
   If Copy(StrToUpper(ParamStr(I)),1,2)='/W'Then Begin
    Val(Copy(ParamStr(I),3,255),WidthData,Err);
    If Err>0 Then Begin
     WriteLn('Valeur invalide !');
     Halt;
    End;
    If Not(WidthData in[$01..$80])Then Begin
     WriteLn('Nombre de donn‚es en dehors de l''intervalle !');
     Halt;
    End;
   End
    Else
   If SourceFileName=''Then SourceFileName:=ParamStr(I)Else
   If TargetFileName=''Then TargetFileName:=ParamStr(I)
    Else
   Begin
    WriteLn('ParamŠtre invalide');
    Halt;
   End;
  End;
  {$I-}Assign(Source,ParamStr(1));
  Reset(Source,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible d''ouvrir le fichier binaire ');
   Halt(1);
  End;
  {$I-}Assign(Target,ParamStr(2));
  Rewrite(Target);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de cr‚er le fichier assembleur ');
   Halt(1);
  End;
  Seek(Source,StartPos);
  Position:=0;
  Case Mode of
   _DD:Begin
    Write(Target,' DD ');
    While Not EOF(Source)do Begin
     FillChar(Tampon,SizeOf(Tampon),0);
     BlockRead(Source,Tampon,2,ByteReaded);
     Write(Target,LongHex2Str(TD));
     If Not EOF(Source)Then Begin
      Inc(Position);
      If Position=16Then Begin
       WriteLn(Target);
       Write(Target,' DD ');
      End
       Else
      Write(Target,',');
      Position:=Position mod 16;
     End;
    End;
   End;
   _DW:Begin
    Write(Target,' DW ');
    While Not EOF(Source)do Begin
     FillChar(Tampon,SizeOf(Tampon),0);
     BlockRead(Source,Tampon,2,ByteReaded);
     Write(Target,HexWord2Str(TW));
     If Not EOF(Source)Then Begin
      Inc(Position);
      If Position=WidthData Then Begin
       WriteLn(Target);
       Write(Target,' DW ');
      End
       Else
      Write(Target,',');
      Position:=Position mod WidthData;
     End;
    End;
   End;
   Else Begin
    Write(Target,' DB ');
    While Not EOF(Source)do Begin
     BlockRead(Source,Tampon,1,ByteReaded);
     Write(Target,ByteHex2Str(Tampon[0]),'h');
     If Not EOF(Source)Then Begin
      Inc(Position);
      If Position=WidthData Then Begin
       WriteLn(Target);
       Write(Target,' DB ');
      End
       Else
      Write(Target,',');
      Position:=Position mod WidthData;
     End;
    End;
   End;
  End;
  WriteLn(Target);
  Close(Target);
  Close(Source);
 End
  Else
 WriteLn('Parametre attendue !');
END.