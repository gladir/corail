{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CSV2ASM(Input,Output);

Uses DOS;

Var
 SourceCSV,TargetASM:Text;
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

Function StringToBasicString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'",34,"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToBasicString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CSV2ASM : Cette commande permet de convertir un fichier CSV ',
                     'en code source Assembleur.');
  WriteLn;
  WriteLn('Syntaxe : CSV2ASM source.CSV [target.ASM]');
  WriteLn;
  WriteLn(' fichier.CSV  Nom du fichier a convertir');
  WriteLn(' fichier.ASM  Nom du fichier du r‚sultat');
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
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Fields[NumField]:=Copy(CurrWord,2,Length(CurrWord)-2);
         Inc(NumField);
        End
         Else
        Begin
         Fields[NumField]:=CurrWord;
         Inc(NumField);
        End;
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      CurrField:=CurrWord;
      Fields[NumField]:=CurrWord;
      Inc(NumField);
      If NumField>High(Fields)Then Begin
       WriteLn('Enregistrement trop grand !');
       Halt;
      End;
     End
      Else
     Begin
      PosField:=0;
      CurrWord:='';
      Write('DB ');
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If PosField>0Then Write(',');
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write('"',StringToBasicString(Copy(CurrWord,2,Length(CurrWord)-2)),'"');
        End
         Else
        Write('"',StringToBasicString(CurrWord),'"');
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      If PosField>0Then Write(',');
      Write('"',StringToBasicString(CurrWord),'"');
      WriteLn;
     End;
    End;
    Close(SourceCSV);
   End
    Else
   Begin
    TFileName:=FExpand(ParamStr(2));
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.ASM';
    Assign(TargetASM,TFileName);
    {$I-}Rewrite(TargetASM); {$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de cr‚er le fichier assembleur ',TFileName,' !');
     Close(SourceCSV);
     Halt;
    End;
    First:=True;
    While Not EOF(SourceCSV)do Begin
     ReadLn(SourceCSV,CurrLine);
     If(First)Then Begin
      First:=False;
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Fields[NumField]:=Copy(CurrWord,2,Length(CurrWord)-2);
         Inc(NumField);
        End
         Else
        Begin
         Fields[NumField]:=CurrWord;
         Inc(NumField);
        End;
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      CurrField:=CurrWord;
      Fields[NumField]:=CurrWord;
      Inc(NumField);
      If NumField>High(Fields)Then Begin
       WriteLn('Enregistrement trop grand !');
       Halt;
      End;
     End
      Else
     Begin
      CurrWord:='';
      PosField:=0;
      Write(TargetASM,'DB ');
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If PosField>0Then Write(TargetASM,',');
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(TargetASM,'"',StringToBasicString(Copy(CurrWord,2,Length(CurrWord)-2)),'"');
        End
         Else
        Write(TargetASM,'"',StringToBasicString(CurrWord),'"');
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      If PosField>0Then Write(TargetASM,',');
      Write(TargetASM,'"',StringToBasicString(CurrWord),'"');
      WriteLn(TargetASM);
     End;
    End;
    Close(TargetASM);
    Close(SourceCSV);
   End;
  End
   Else
  Begin
   While Not EOF do Begin
    ReadLn(Input,CurrLine);
    Write('DB ');
    CurrWord:='';
    PosField:=0;
    For I:=1 to Length(CurrLine)do Begin
     If CurrLine[I]=','Then Begin
      If PosField>0Then Write(',');
      If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
       Write('"',StringToBasicString(Copy(CurrWord,2,Length(CurrWord)-2)),'"');
      End
       Else
      Write('"',StringToBasicString(CurrWord),'"');
      CurrWord:='';
      Inc(PosField);
     End
      Else
     CurrWord:=CurrWord+CurrLine[I];
    End;
    If PosField>0Then Write(',');
    Write('"',StringToBasicString(CurrWord),'"');
    Inc(PosField);
    WriteLn;
   End;
  End;
 End;
END.

