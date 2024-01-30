{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program OCT2DEC;

Var
 SourceText:Text;
 C:Char;
 I:Integer;
 FileName,CurrNumber:String;

Function IsOctal(Value:String):Boolean;
Var
 I:Integer;
 Octal:Boolean;
Begin
 Octal:=True;
 For I:=1 to Length(Value)do Begin
  If Not(Value[I]in['0'..'7'])Then Begin
   IsOctal:=False;
   Exit;
  End;
 End;
 IsOctal:=Octal;
End;

Function OctalToDecimal(OctalStr:String):LongInt;
Var
 I,Len,DecimalNum,Multiplier:LongInt;
Begin
 Len:=Length(octalStr);
 DecimalNum:=0;
 Multiplier:=1;
 For I:=Len downto 1 do Begin
  DecimalNum:=decimalNum+(Ord(octalStr[i])-Ord('0'))*Multiplier;
  Multiplier:=Multiplier*8;
 End;
 OctalToDecimal:=DecimalNum;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('OCT2DEC : Cette commande permet de convertir un nombre octal ',
                     'en nombre d‚cimal ou un fichier texte avec des ',
                     'nombres en d‚cimal.');
  WriteLn;
  WriteLn('Syntaxe : OCT2DEC /INPUT:fichier');
  WriteLn('          OCT2DEC nombre');
  WriteLn;
  WriteLn(' /INPUT:fichier  Indique le fichier … convertir');
 End
  Else
 Begin
  For I:=1 to ParamCount do Begin
   If Copy(ParamStr(I),1,Length('/INPUT:'))='/INPUT:'Then Begin
    FileName:=Copy(ParamStr(I),Length('/INPUT:')+1,255);
    {$I-}Assign(SourceText,FileName);
    Reset(SourceText);{$I+}
    If IOResult<>0 Then Begin
     WriteLn('Impossible d''ouvrir le fichier : ',FileName);
     Halt(1);
    End;
    CurrNumber:='';
    While Not EOF(SourceText)do Begin
     Read(SourceText,C);
     If(C in['0'..'7'])Then Begin
      CurrNumber:=CurrNumber+C;
     End
      Else
     Begin
      If CurrNumber<>''Then Begin
       Write(OctalToDecimal(CurrNumber));
       CurrNumber:='';
      End;
      Write(C);
     End
    End;
    If CurrNumber<>''Then Write(OctalToDecimal(CurrNumber));
    Close(SourceText);
   End
    Else
   If Not IsOctal(ParamStr(I))Then Begin
    WriteLn('Nombre octal invalide !');
    Halt(2);
   End
    Else
   Write(OctalToDecimal(ParamStr(I)));
  End;
 End;
END.