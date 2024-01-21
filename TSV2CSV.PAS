{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program TSV2CSV;

Uses DOS;

Var
 SourceTSV,TargetCSV:Text;
 FileName,TFileName:String;
 C:Char;

Function Path2Name(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2Name:=N;
End;

Function Path2Ext(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2Ext:=E;
End;


BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('TSV2CSV : Cette commande permet de convertir un fichier ',
                    'TSV (Tab-Separeted Values) en CSV.');
  WriteLn;
  WriteLn('Syntaxe : CSV2TSV source.TSV target.TSV');
  WriteLn;
  WriteLn(' source.CSV   Nom du fichier a convertir');
  WriteLn(' target.TSV   Nom du fichier du r‚sultat');
  WriteLn;
 End
  Else
 If ParamCount>0 Then Begin
  FileName:=FExpand(ParamStr(1));
  If Path2Ext(FileName)=''Then FileName:=FileName+'.TSV';
  Assign(SourceTSV,FileName);
  {$I-}Reset(SourceTSV);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier TSV introuvable !');
   Halt(1);
  End;
  If ParamStr(2)=''Then Begin
   While Not EOF(SourceTSV)do Begin
    Read(SourceTSV,C);
    If C=#9 Then C:=',';
    Write(C);
   End;
  End
   Else
  Begin
   TFileName:=FExpand(ParamStr(2));
   If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.CSV';
   Assign(TargetCSV,TFileName);
   {$I-}Rewrite(TargetCSV); {$I+}
   If IoResult<>0Then Begin
    WriteLn('Impossible de cr‚er le fichier CSV ',TFileName,' !');
    Close(TargetCSV);
    Halt(2);
   End;
   While Not EOF(SourceTSV)do Begin
    Read(SourceTSV,C);
    If C=#9 Then C:=',';
    Write(TargetCSV,C);
   End;
   Close(TargetCSV);
  End;
  Close(SourceTSV);
 End;
END.
