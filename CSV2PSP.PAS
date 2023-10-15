{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CSV2PSP(Input,Output);

Uses DOS;

Var
 SourceCSV,TargetPAS:Text;
 CurrLine,CurrWord,CurrField,TableName,FileName,TFileName:String;
 I:Integer;
 First:Boolean;
 Fields:Array[0..100]of String[75];
 PosField,NumField:Integer;
 NumRecord:LongInt;

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

Function StringToPASString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]=''''Then ConvStr:=ConvStr+''''+'''';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToPASString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CSV2PSP : Cette commande permet de convertir un fichier CSV ',
                     'en code source PSP (Pascal Server Pages).');
  WriteLn;
  WriteLn('Syntaxe : CSV2PAS source.CSV target.PAS');
  WriteLn;
  WriteLn(' fichier.CSV  Nom du fichier a convertir');
  WriteLn(' fichier.PSP  Nom du fichier du resultat');
  WriteLn;
 End
  Else
 Begin
  NumRecord:=0;
  NumField:=0;
  FillChar(Fields,SizeOf(Fields),0);
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
   While Not EOF(SourceCSV)do Begin
    ReadLn(SourceCSV,CurrLine);
    Inc(NumRecord);
   End;
   Close(SourceCSV);
   Dec(NumRecord);
   Assign(SourceCSV,FileName);
   {$I-}Reset(SourceCSV);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Fichier CSV introuvable !');
    Halt;
   End;
   If ParamStr(2)=''Then Begin
    First:=True;
    While Not EOF(SourceCSV)do Begin
     ReadLn(SourceCSV,CurrLine);
     If(First)Then Begin
      First:=False;
      WriteLn('<%');
      WriteLn('Type ',TableName,'Rec=Record');
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         WriteLn('  ',Copy(CurrWord,2,Length(CurrWord)-2),':String;');
         Fields[NumField]:=Copy(CurrWord,2,Length(CurrWord)-2);
         Inc(NumField);
        End
         Else
        Begin
         WriteLn('  ',CurrWord,':String;');
         Fields[NumField]:=CurrWord;
         Inc(NumField);
        End;
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      WriteLn('  ',CurrWord,':String;');
      CurrField:=CurrWord;
      Fields[NumField]:=CurrWord;
      Inc(NumField);
      If NumField>High(Fields)Then Begin
       WriteLn('Enregistrement trop grand !');
       Halt;
      End;
      WriteLn(' End;');
      WriteLn;
      WriteLn('Var');
      WriteLn(' ',TableName,':Array[1..',NumRecord,'] of ',TableName,'Rec=(');
     End
      Else
     Begin
      PosField:=0;
      CurrWord:='';
      Write('  (');
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(Fields[PosField],':','''',StringToPASString(Copy(CurrWord,2,Length(CurrWord)-2)),''';');
        End
         Else
        Write(Fields[PosField],':','''',StringToPASString(CurrWord),''';');
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(Fields[PosField],':','''',StringToPASString(CurrWord),'''');
      WriteLn(');');
     End;
    End;
    WriteLn(' );');
    WriteLn('%>');
    Close(SourceCSV);
   End
    Else
   Begin
    TFileName:=FExpand(ParamStr(2));
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.PAS';
    Assign(TargetPAS,TFileName);
    {$I-}Rewrite(TargetPAS); {$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de cr‚er le fichier PAS ',TFileName,' !');
     Close(SourceCSV);
     Halt;
    End;
    First:=True;
    While Not EOF(SourceCSV)do Begin
     ReadLn(SourceCSV,CurrLine);
     If(First)Then Begin
      First:=False;
      WriteLn(TargetPAS,'Type ',TableName,'Rec=Record');
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         WriteLn(TargetPAS,'  ',Copy(CurrWord,2,Length(CurrWord)-2),':String;');
         Fields[NumField]:=Copy(CurrWord,2,Length(CurrWord)-2);
         Inc(NumField);
        End
         Else
        Begin
         WriteLn(TargetPAS,'  ',CurrWord,':String;');
         Fields[NumField]:=CurrWord;
         Inc(NumField);
        End;
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(TargetPAS,'  ',CurrWord,':String;');
      CurrField:=CurrWord;
      Fields[NumField]:=CurrWord;
      Inc(NumField);
      If NumField>High(Fields)Then Begin
       WriteLn('Enregistrement trop grand !');
       Halt;
      End;
      WriteLn(TargetPAS,' End;');
      WriteLn(TargetPAS);
      WriteLn(TargetPAS,'Var');
      WriteLn(TargetPAS,' ',TableName,':Array[1..',NumRecord,'] of ',TableName,'Rec=(');
     End
      Else
     Begin
      CurrWord:='';
      PosField:=0;
      Write(TargetPAS,'  (');
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(TargetPAS,Fields[PosField],':','''',StringToPASString(Copy(CurrWord,2,Length(CurrWord)-2)),''';');
        End
         Else
        Write(TargetPAS,Fields[PosField],':','''',StringToPASString(CurrWord),''';');
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(TargetPAS,Fields[PosField],':','''',StringToPASString(CurrWord),'''');
      WriteLn(TargetPAS,');');
     End;
    End;
    WriteLn(TargetPas,' );');
    WriteLn(TargetPas,'%>');
    Close(TargetPAS);
    Close(SourceCSV);
   End;
  End
   Else
  Begin
   WriteLn('Var');
   WriteLn(' ',TableName,':Array[1..?] of ',TableName,'Rec=(');
   While Not EOF do Begin
    ReadLn(Input,CurrLine);
    Write('(');
    CurrWord:='';
    For I:=1 to Length(CurrLine)do Begin
     If CurrLine[I]=','Then Begin
      If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
       Write('''',StringToPASString(Copy(CurrWord,2,Length(CurrWord)-2)),''';');
      End
       Else
      Write('''',StringToPASString(CurrWord),''';');
      CurrWord:='';
     End
      Else
     CurrWord:=CurrWord+CurrLine[I];
    End;
    Write(StringToPASString(CurrWord),'''');
    WriteLn(');');
    WriteLn('%>');
   End;
  End;
 End;
END.

