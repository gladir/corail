{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program TSV2PAS(Input,Output);

Uses DOS;

Var
 SourceTSV,TargetPAS:Text;
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
  WriteLn('TSV2PAS : Cette commande permet de convertir un fichier TSV ',
                     'en code source Pascal.');
  WriteLn;
  WriteLn('Syntaxe : TSV2PAS source.TSV target.PAS');
  WriteLn;
  WriteLn(' source.TSV  Nom du fichier a convertir');
  WriteLn(' target.PAS  Nom du fichier du r‚sultat');
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
   If Path2Ext(FileName)=''Then FileName:=FileName+'.TSV';
   Assign(SourceTSV,FileName);
   {$I-}Reset(SourceTSV);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Fichier TSV introuvable !');
    Halt;
   End;
   While Not EOF(SourceTSV)do Begin
    ReadLn(SourceTSV,CurrLine);
    Inc(NumRecord);
   End;
   Close(SourceTSV);
   Dec(NumRecord);
   Assign(SourceTSV,FileName);
   {$I-}Reset(SourceTSV);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Fichier TSV introuvable !');
    Halt;
   End;
   If ParamStr(2)=''Then Begin
    First:=True;
    While Not EOF(SourceTSV)do Begin
     ReadLn(SourceTSV,CurrLine);
     If(First)Then Begin
      First:=False;
      WriteLn('Type ',TableName,'Rec=Record');
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=#9 Then Begin
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
       If CurrLine[I]=#9 Then Begin
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
    Close(SourceTSV);
   End
    Else
   Begin
    TFileName:=FExpand(ParamStr(2));
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.PAS';
    Assign(TargetPAS,TFileName);
    {$I-}Rewrite(TargetPAS); {$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de cr‚er le fichier PAS ',TFileName,' !');
     Close(SourceTSV);
     Halt;
    End;
    First:=True;
    While Not EOF(SourceTSV)do Begin
     ReadLn(SourceTSV,CurrLine);
     If(First)Then Begin
      First:=False;
      WriteLn(TargetPAS,'Type ',TableName,'Rec=Record');
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=#9 Then Begin
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
       If CurrLine[I]=#9 Then Begin
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
    Close(TargetPAS);
    Close(SourceTSV);
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
     If CurrLine[I]=#9 Then Begin
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
   End;
  End;
 End;
END.

