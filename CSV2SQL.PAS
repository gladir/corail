{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program CSV2SQL(Input,Output);

Uses DOS;

Var
 SourceCSV,TargetSQL:Text;
 CurrLine,CurrWord,CurrField,TableName,FileName,TFileName:String;
 I:Integer;
 First:Boolean;

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
  WriteLn('CSV2SQL : Cette commande permet de convertir un fichier CSV en SQL.');
  WriteLn;
  WriteLn('Syntaxe : CSV2SQL source.CSV target.SQL');
  WriteLn;
  WriteLn(' fichier.CSV  Nom du fichier a convertir');
  WriteLn(' fichier.SQL  Nom du fichier du resultat');
  WriteLn;
 End
  Else
 Begin
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
    First:=True;
    While Not EOF(SourceCSV)do Begin
     ReadLn(SourceCSV,CurrLine);
     If(First)Then Begin
      First:=False;
      Write('CREATE TABLE ',TableName,' (');
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(Copy(CurrWord,2,Length(CurrWord)-2),' TEXT,');
        End
         Else
        Write(CurrWord,' TEXT,');
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(CurrWord,' TEXT');
      CurrField:=CurrWord;
      WriteLn(');');
     End
      Else
     Begin
      Write('INSERT INTO (');
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write('''',StringToSQLString(Copy(CurrWord,2,Length(CurrWord)-2)),''',');
        End
         Else
        Write('''',StringToSQLString(CurrWord),''',');
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write('''',StringToSQLString(CurrWord),'''');
      WriteLn(');');
     End;
    End;
    Close(SourceCSV);
   End
    Else
   Begin
    TFileName:=FExpand(ParamStr(2));
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.SQL';
    Assign(TargetSQL,TFileName);
    {$I-}Rewrite(TargetSQL); {$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de cr‚er le fichier SQL ',TFileName,' !');
     Close(SourceCSV);
     Halt;
    End;
    First:=True;
    While Not EOF(SourceCSV)do Begin
     ReadLn(SourceCSV,CurrLine);
     If(First)Then Begin
      First:=False;
      Write(TargetSQL,'CREATE TABLE ',TableName,' (');
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(TargetSQL,Copy(CurrWord,2,Length(CurrWord)-2),' TEXT,');
        End
         Else
        Write(TargetSQL,CurrWord,' TEXT,');
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(TargetSQL,CurrWord,' TEXT');
      CurrField:=CurrWord;
      WriteLn(TargetSQL,');');
     End
      Else
     Begin
      Write(TargetSQL,'INSERT INTO (');
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(TargetSQL,'''',StringToSQLString(Copy(CurrWord,2,Length(CurrWord)-2)),''',');
        End
         Else
        Write(TargetSQL,'''',StringToSQLString(CurrWord),''',');
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(TargetSQL,'''',StringToSQLString(CurrWord),'''');
      WriteLn(TargetSQL,');');
     End;
    End;
    Close(TargetSQL);
    Close(SourceCSV);
   End;
  End
   Else
  Begin
   While Not EOF do Begin
    ReadLn(Input,CurrLine);
    Write('INSERT INTO (');
    CurrWord:='';
    For I:=1 to Length(CurrLine)do Begin
     If CurrLine[I]=','Then Begin
      If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
       Write('''',StringToSQLString(Copy(CurrWord,2,Length(CurrWord)-2)),''',');
      End
       Else
      Write('''',StringToSQLString(CurrWord),''',');
      CurrWord:='';
     End
      Else
     CurrWord:=CurrWord+CurrLine[I];
    End;
    Write('''',StringToSQLString(CurrWord),'''');
    WriteLn(');');
   End;
  End;
 End;
END.
