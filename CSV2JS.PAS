{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CSV2JS(Input,Output);

Uses DOS;

Var
 SourceCSV,TargetJS:Text;
 CurrLine,CurrWord,CurrField,TableName,FileName,TFileName:String;
 I:Integer;
 First:Boolean;
 Fields:Array[0..100]of String[75];
 PosField,NumField:Integer;
 CurrRecord,NumRecord:LongInt;

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
  WriteLn('CSV2JS : Cette commande permet de convertir un fichier CSV en JavaScript.');
  WriteLn;
  WriteLn('Syntaxe : CSV2JS source.CSV target.JS');
  WriteLn;
  WriteLn(' source.CSV   Nom du fichier a convertir');
  WriteLn(' target.JS    Nom du fichier du r‚sultat');
  WriteLn;
 End
  Else
 Begin
  NumRecord:=0;
  NumField:=0;
  CurrRecord:=0;
  FillChar(Fields,SizeOf(Fields),0);
  If ParamCount>0Then Begin
   TableName:=Path2Name(ParamStr(1));
   FileName:=FExpand(ParamStr(1));
   If Path2Ext(FileName)=''Then FileName:=FileName+'.CSV';
   Assign(SourceCSV,FileName);
   {$I-}Reset(SourceCSV);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Fichier CSV introuvable !');
    Halt(1);
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
    Halt(2);
   End;
   If ParamStr(2)=''Then Begin
    First:=True;
    WriteLn('var ':4,TableName,' = {');
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
       Halt(3);
      End;
     End
      Else
     Begin
      Inc(CurrRecord);
      WriteLn(' ':4,CurrRecord,':{');
      PosField:=0;
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(' ':8,'"',Fields[PosField],'":');
         WriteLn('"',Copy(CurrWord,2,Length(CurrWord)-2),'",');
        End
         Else
        Begin
         Write(' ':8,'"',Fields[PosField],'":');
         WriteLn('"',CurrWord,'",');
        End;
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(' ':8,'"',Fields[PosField],'":');
      If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
       WriteLn('"',Copy(CurrWord,2,Length(CurrWord)-2),'"');
      End
       Else
      WriteLn('"',CurrWord,'"');
      Write(' ':4,'}');
      If(CurrRecord<NumRecord)Then Write(',');
      WriteLn;
     End;
    End;
    WriteLn('};');
    Close(SourceCSV);
   End
    Else
   Begin
    TFileName:=FExpand(ParamStr(2));
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.JS';
    Assign(TargetJS,TFileName);
    {$I-}Rewrite(TargetJS); {$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de cr‚er le fichier JavaScript ',TFileName,' !');
     Close(SourceCSV);
     Halt(4);
    End;
    First:=True;
    WriteLn(TargetJS,'var ':4,TableName,' = {');
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
       Halt(5);
      End;
     End
      Else
     Begin
      Inc(CurrRecord);
      WriteLn(TargetJS,' ':4,CurrRecord,':{');
      PosField:=0;
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(TargetJS,' ':8,'"',Fields[PosField],'":');
         WriteLn(TargetJS,'"',Copy(CurrWord,2,Length(CurrWord)-2),'",');
        End
         Else
        Begin
         Write(TargetJS,' ':8,'"',Fields[PosField],'":');
         WriteLn(TargetJS,'"',CurrWord,'",');
        End;
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(TargetJS,' ':8,'"',Fields[PosField],'":');
      If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
       WriteLn(TargetJS,'"',Copy(CurrWord,2,Length(CurrWord)-2),'"');
      End
       Else
      WriteLn(TargetJS,'"',CurrWord,'"');
      Write(TargetJS,' ':4,'}');
      If(CurrRecord<NumRecord)Then Write(TargetJS,',');
      WriteLn(TargetJS);
     End;
    End;
    WriteLn(TargetJS,'};');
    Close(TargetJS);
    Close(SourceCSV);
   End;
  End
   Else
  WriteLn('ParamŠtre requis !');
 End;
END.


