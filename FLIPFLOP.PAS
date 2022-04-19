{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}


Program FlipFlop(Input,Output);

Var
 C:Char;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Write('FLIPFLOP : Cette commande permet d''echanger des fichiers textes ',
        'de TRS-80 et UNIX (ou Amiga).');
  WriteLn;
  WriteLn('Syntaxe : FLIPFLOP [/?]');
 End
  Else
 Begin
  While NOT EOF do Begin
   Read(C);
   Case C of
    #$0A:Begin
     Write({$IFDEF FPC}ErrOutput{$ELSE}Output{$ENDIF},'C');
     WriteLn;
    End;
    #$0D:Begin
     Write({$IFDEF FPC}ErrOutput{$ELSE}Output{$ENDIF},'L');
    End;
    Else Write(C);
   End;
  End;
  WriteLn({$IFDEF FPC}ErrOutput{$ELSE}Output{$ENDIF},'Fait!!');
  WriteLn({$IFDEF FPC}ErrOutput{$ELSE}Output{$ENDIF});
 End;
END.
