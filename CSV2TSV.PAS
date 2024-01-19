{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CSV2TSV;

Uses DOS;

Var
 SourceCSV,TargetTSV:Text;
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
  WriteLn('CSV2TSV : Cette commande permet de convertir un fichier ',
                    'CSV en TSV (Tab-Separeted Values).');
  WriteLn;
  WriteLn('Syntaxe : CSV2TSV source.TSV target.HTML');
  WriteLn;
  WriteLn(' source.CSV   Nom du fichier a convertir');
  WriteLn(' target.TSV   Nom du fichier du r‚sultat');
  WriteLn;
 End
  Else
 If ParamCount>0 Then Begin
  FileName:=FExpand(ParamStr(1));
  If Path2Ext(FileName)=''Then FileName:=FileName+'.CSV';
  Assign(SourceCSV,FileName);
  {$I-}Reset(SourceCSV);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier CSV introuvable !');
   Halt(1);
  End;
  If ParamStr(2)=''Then Begin
   While Not EOF(SourceCSV)do Begin
    Read(SourceCSV,C);
    If C=','Then C:=#9;
    Write(C);
   End;
  End
   Else
  Begin
   TFileName:=FExpand(ParamStr(2));
   If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.TSV';
   Assign(TargetTSV,TFileName);
   {$I-}Rewrite(TargetTSV); {$I+}
   If IoResult<>0Then Begin
    WriteLn('Impossible de cr‚er le fichier TSV ',TFileName,' !');
    Close(TargetTSV);
    Halt(2);
   End;
   While Not EOF(SourceCSV)do Begin
    Read(SourceCSV,C);
    If C=','Then C:=#9;
    Write(TargetTSV,C);
   End;
   Close(TargetTSV);
  End;
  Close(SourceCSV);
 End;
END.