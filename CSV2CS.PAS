{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CSV2CS(Input,Output);

Uses DOS;

Var
 SourceCSV,TargetCS:Text;
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

Function StringToCString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'\"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToCString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CSV2CS : Cette commande permet de convertir un fichier CSV ',
                     'en code source C# (C Sharp).');
  WriteLn;
  WriteLn('Syntaxe : CSV2CS source.CSV target.CS');
  WriteLn;
  WriteLn(' fichier.CSV  Nom du fichier a convertir');
  WriteLn(' fichier.CS   Nom du fichier du resultat');
  WriteLn;
 End
  Else
 Begin
  NumRecord:=0;
  CurrRecord:=0;
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
      WriteLn('struct ',TableName,'Rec {');
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         WriteLn('  string ',Copy(CurrWord,2,Length(CurrWord)-2),';');
         Fields[NumField]:=Copy(CurrWord,2,Length(CurrWord)-2);
         Inc(NumField);
        End
         Else
        Begin
         WriteLn('  string ',CurrWord,';');
         Fields[NumField]:=CurrWord;
         Inc(NumField);
        End;
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      WriteLn('  string ',CurrWord,';');
      CurrField:=CurrWord;
      Fields[NumField]:=CurrWord;
      Inc(NumField);
      If NumField>High(Fields)Then Begin
       WriteLn('Enregistrement trop grand !');
       Halt;
      End;
      Write(' ':4,'public ',TableName,'Rec(');
      For I:=0 To NumField-1 do Begin
       Write(' ':2,'string ');
       Write(' ',Fields[I]);
       If I<NumField-1 Then Write(',');
      End;
      WriteLn(') {');
      For I:=0 To NumField-1 do Begin
       Write(' ':6);
       Write('this.',Fields[I]);
       WriteLn('=',Fields[I],';');
      End;
      WriteLn(' ':4,'}');
      WriteLn(' };');
      WriteLn;
      WriteLn('class Program {');
      WriteLn(' ':4,'static void Main(string[] args) {');
      WriteLn(' ':8,TableName,'Rec[] ',TableName,'= new ',TableName,'Rec[]{');
     End
      Else
     Begin
      PosField:=0;
      CurrWord:='';
      Write(' ':11,'new ',TableName,'Rec(');
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write('/* ',Fields[PosField],'= */','"',StringToCString(Copy(CurrWord,2,Length(CurrWord)-2)),'",');
        End
         Else
        Write('/* ',Fields[PosField],'= */','"',StringToCString(CurrWord),'",');
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write('/* ',Fields[PosField],'= */','"',StringToCString(CurrWord),'"');
      Write(')');
      Inc(CurrRecord);
      If CurrRecord<NumRecord Then WriteLn(',')
                              Else WriteLn;
     End;
    End;
    WriteLn(' ':8,'};');
    WriteLn(' ':4,'}');
    WriteLn('}');
    Close(SourceCSV);
   End
    Else
   Begin
    TFileName:=FExpand(ParamStr(2));
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.CS';
    Assign(TargetCS,TFileName);
    {$I-}Rewrite(TargetCS); {$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de cr‚er le fichier C# ',TFileName,' !');
     Close(SourceCSV);
     Halt;
    End;
    First:=True;
    While Not EOF(SourceCSV)do Begin
     ReadLn(SourceCSV,CurrLine);
     If(First)Then Begin
      First:=False;
      WriteLn(TargetCS,'struct ',TableName,'Rec {');
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         WriteLn(TargetCS,'  string ',Copy(CurrWord,2,Length(CurrWord)-2),';');
         Fields[NumField]:=Copy(CurrWord,2,Length(CurrWord)-2);
         Inc(NumField);
        End
         Else
        Begin
         WriteLn(TargetCS,'  string ',CurrWord,';');
         Fields[NumField]:=CurrWord;
         Inc(NumField);
        End;
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(TargetCS,'  string ',CurrWord,';');
      CurrField:=CurrWord;
      Fields[NumField]:=CurrWord;
      Inc(NumField);
      If NumField>High(Fields)Then Begin
       WriteLn('Enregistrement trop grand !');
       Halt;
      End;
      WriteLn(TargetCS);
      Write(TargetCS,' ':4,'public ',TableName,'Rec(');
      For I:=0 To NumField-1 do Begin
       Write(TargetCS,' ':2,'string ');
       Write(TargetCS,' ',Fields[I]);
       If I<NumField-1 Then Write(TargetCS,',');
      End;
      WriteLn(TargetCS,') {');
      For I:=0 To NumField-1 do Begin
       Write(TargetCS,' ':6);
       Write(TargetCS,'this.',Fields[I]);
       WriteLn(TargetCS,'=',Fields[I],';');
      End;
      WriteLn(TargetCS,' ':4,'}');
      WriteLn(TargetCS,'};');
      WriteLn(TargetCS);
      WriteLn(TargetCS,'class Program {');
      WriteLn(TargetCS,' ':4,'static void Main(string[] args) {');
      WriteLn(TargetCS,' ':8,TableName,'Rec[] ',TableName,'= new ',TableName,'Rec[]{');
     End
      Else
     Begin
      CurrWord:='';
      PosField:=0;
      Write(TargetCS,' ':11,'new ',TableName,'Rec(');
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(TargetCS,'/* ',Fields[PosField],'= */','"',StringToCString(Copy(CurrWord,2,Length(CurrWord)-2)),'",');
        End
         Else
        Write(TargetCS,'/* ',Fields[PosField],'= */','"',StringToCString(CurrWord),'",');
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(TargetCS,'/* ',Fields[PosField],'= */','"',StringToCString(CurrWord),'"');
      Write(TargetCS,')');
      Inc(CurrRecord);
      If CurrRecord<NumRecord Then WriteLn(TargetCS,',')
                              Else WriteLn(TargetCS);
     End;
    End;
    WriteLn(TargetCS,' ':8,' };');
    WriteLn(TargetCS,' ':4,'}');
    WriteLn(TargetCS,'}');
    Close(TargetCS);
    Close(SourceCSV);
   End;
  End
   Else
  Begin
   WriteLn('struct ',TableName,'Rec {');
   While Not EOF do Begin
    ReadLn(Input,CurrLine);
    Write('(');
    CurrWord:='';
    For I:=1 to Length(CurrLine)do Begin
     If CurrLine[I]=','Then Begin
      If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
       Write('"',StringToCString(Copy(CurrWord,2,Length(CurrWord)-2)),'";');
      End
       Else
      Write('"',StringToCString(CurrWord),'";');
      CurrWord:='';
     End
      Else
     CurrWord:=CurrWord+CurrLine[I];
    End;
    Write('"',StringToCString(CurrWord),'"');
    WriteLn('};');
    WriteLn('}');
    WriteLn('}');
   End;
  End;
 End;
END.



