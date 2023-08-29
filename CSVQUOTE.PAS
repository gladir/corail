{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CSVQUOTE(Input,Output);

Uses DOS;

Var
 SourceCSV,TargetCSV:Text;
 CurrLine,CurrWord,CurrField,TableName,FileName,TFileName:String;
 I:Integer;
 InQuote:Boolean;

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

Function StringToSQLString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]=''''Then ConvStr:=ConvStr+''''+'''';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToSQLString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CSVQUOTE : Cette commande permet d''enlever les sauts de ',
                      'lignes dans les champs entre guillemets.');
  WriteLn;
  WriteLn('Syntaxe : CSVQUOTE source.CSV [target.CSV]');
  WriteLn;
  WriteLn(' source.CSV  Nom du fichier a convertir');
  WriteLn(' target.CSV  Nom du fichier convertie');
  WriteLn;
 End
  Else
 Begin
  InQuote:=False;
  If ParamCount>0Then Begin
   TableName:=Path2Name(ParamStr(1));
   FileName:=FExpand(ParamStr(1));
   If Path2Ext(FileName)=''Then FileName:=FileName+'.CSV';
   Assign(SourceCSV,FileName);
   {$I-}Reset(SourceCSV);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Fichier CSV introuvable !');
    Halt;
   End;
   If ParamStr(2)=''Then Begin
    CurrWord:='';
    While Not EOF(SourceCSV)do Begin
     ReadLn(SourceCSV,CurrLine);
     For I:=1 to Length(CurrLine)do Begin
      If CurrLine[I]=','Then Begin
       Write(CurrWord,',');
       CurrWord:='';
      End
       Else
      If CurrLine[I]='"'Then Begin
       InQuote:=Not(InQuote);
       CurrWord:=CurrWord+CurrLine[I];
      End
       Else
      Begin
       CurrWord:=CurrWord+CurrLine[I];
      End;
     End;
     If Not(InQuote)Then Begin
      WriteLn(CurrWord);
      CurrWord:='';
     End;
    End;
    If CurrWord<>''Then WriteLn(CurrWord);
    Close(SourceCSV);
   End
    Else
   Begin
    TFileName:=FExpand(ParamStr(2));
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.SQL';
    Assign(TargetCSV,TFileName);
    {$I-}Rewrite(TargetCSV); {$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de cr‚er le fichier SQL ',TFileName,' !');
     Close(SourceCSV);
     Halt;
    End;
    While Not EOF(SourceCSV)do Begin
     ReadLn(SourceCSV,CurrLine);
     For I:=1 to Length(CurrLine)do Begin
      If CurrLine[I]=','Then Begin
       Write(TargetCSV,CurrWord,',');
       CurrWord:='';
      End
       Else
      If CurrLine[I]='"'Then Begin
       InQuote:=Not(InQuote);
       CurrWord:=CurrWord+CurrLine[I];
      End
       Else
      Begin
       CurrWord:=CurrWord+CurrLine[I];
      End;
     End;
     If Not(InQuote)Then Begin
      WriteLn(TargetCSV,CurrWord);
      CurrWord:='';
     End
    End;
    if CurrWord<>''Then WriteLn(TargetCSV,CurrWord);
    Close(TargetCSV);
    Close(SourceCSV);
   End;
  End
   Else
  Begin
   While Not EOF do Begin
    ReadLn(Input,CurrLine);
    For I:=1 to Length(CurrLine)do Begin
     If CurrLine[I]=','Then Begin
      Write(CurrWord,',');
      CurrWord:='';
     End
      Else
     If CurrLine[I]='"'Then Begin
      InQuote:=Not(InQuote);
      CurrWord:=CurrWord+CurrLine[I];
     End
      Else
     Begin
      CurrWord:=CurrWord+CurrLine[I];
     End;
    End;
    If Not(InQuote)Then Begin
     WriteLn(CurrWord);
     CurrWord:='';
    End;
   End;
    If CurrWord<>''Then WriteLn(CurrWord);
  End;
 End;
END.
