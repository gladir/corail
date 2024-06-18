{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7)
}

Program WIPECMOS;

Uses Crt;

Const
 RTCAdrPort:Byte=$70;
 RTCDtaPort:Byte=$71;

Var
 CmosSize:Word;
 ReplaceValue:Byte;
 Err:Word;
 I,J:Integer;
 Buffer:Array[0..63] of Byte;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function CMOSRead(Address:Integer):Integer;Begin
 {$IFDEF FPC}
  WriteLn('Non support‚ par le compilateur Free Pascal');
 {$ELSE}
  If Address in [0..63]Then Begin
   Port[RTCAdrPort]:=Address;
   CMOSRead:=Port[RTCDtaPort]
  End
   Else
  CMOSRead:=-1;
 {$ENDIF}
End;

Procedure CMOSWrite(Address:Integer;Value:Byte);Begin
 {$IFDEF FPC}
  WriteLn('Non support‚ par le compilateur Free Pascal');
 {$ELSE}
  Port[RTCAdrPort]:=Address;
  Port[RTCDtaPort]:=Value;
 {$ENDIF}
End;

Function RTCDT(Address:Integer):Integer;
Var
 Value:Integer;
Begin
 Value:=CMOSRead(Address);
 If(CMOSRead($0B) and 4 = 4)Then RTCDT:=Value
                            Else RTCDT:=(Value shr 4) * 10 + Value and 15;
End;

Procedure ValHex(HexStr:String;Var ReplaceValue:Byte;Var Err:Word);
Var
 hexVal,i,n:Integer;
Begin
 Err:=0;
 hexVal:=0;
 For i:=1 TO Length(hexStr)do Begin
  n:=Pos(Upcase(hexStr[i]),'0123456789ABCDEF');
  If n=0 Then Begin
   Err:=I;
   Exit;
  End
   Else
  HexVal:=hexVal*16+n-1;
 End;
 ReplaceValue:=HexVal;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('WIPECMOS : Cette commande permet d''effacer le contenu du CMOS.');
  WriteLn;
  WriteLn('Syntaxe : WIPECMOS [taille] [option]');
  WriteLn;
  WriteLn(' taille      Taille du CMOS');
  WriteLn(' -b:valeur   Indique la valeur … ‚crire. Par d‚faut 0.');
  WriteLn(' /AMDEK      Utilise l''adresse d''un AMDEK SYSTEM/88');
 End
  Else
 Begin
  CmosSize:=64;
  ReplaceValue:=0;
  For I:=1 to ParamCount do Begin
   If(StrToUpper(ParamStr(I))='/AMDEK')Then Begin
    RTCAdrPort:=$E0;
    RTCDtaPort:=$E1;
   End
    Else
   If Copy(ParamStr(I),1,Length('-b:'))='-b:'Then Begin
    If Copy(ParamStr(I),Length('-b:')+1,1)='$'Then Begin
     ValHex(Copy(ParamStr(I),Length('-b:')+2,255),ReplaceValue,Err);
    End
     Else
    Val(Copy(ParamStr(I),Length('-b:')+1,255),ReplaceValue,Err);
    If Err>0 Then Begin
     WriteLn('Valeur invalide !');
     Halt(1);
    End;
   End
    Else
   Begin
    Val(ParamStr(I),CmosSize,Err);
    If Err>0 Then Begin
     WriteLn('Taille invalide !');
     Halt(2);
    End;
   End;
  End;
  Write('Etes-vous certain de vouloir effacer le contenu de la m‚moire CMOS (O/N) ?');
  If UpCase(ReadKey)in['O','Y']Then Begin
   For J:=0 to 63 do CMOSWrite(J,ReplaceValue);
  End;
 End;
END.

