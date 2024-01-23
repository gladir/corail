{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CATCSV;

Uses DOS;

Var
 I:Integer;
 Info:SearchRec;
 CurrCSV:Text;
 CurrLine:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CATCSV : Cette commande permet de concat‚ner des fichiers ',
                     'CSV en un seule CSV.');
  WriteLn;
  WriteLn('Syntaxe : CATCSV source.CSV [...]');
  WriteLn;
  WriteLn(' source.CSV  Nom des fichiers … fusionner');
  WriteLn;
 End
  Else
 If ParamCount>0 Then Begin
  For I:=1 to ParamCount do Begin
   FindFirst(ParamStr(I),AnyFile,Info);
   While DOSError=0 do Begin
    {$I-}Assign(CurrCSV,Info.Name);
    Reset(CurrCSV);{$I+}
    While Not EOF(CurrCSV)do Begin
     ReadLn(CurrCSV,CurrLine);
     WriteLn(CurrLine);
    End;
    Close(CurrCSV);
    FindNext(Info);
   End;
  End;
 End;
END.