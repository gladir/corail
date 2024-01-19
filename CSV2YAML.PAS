{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CSV2YAML;

Uses DOS;

Var
 SourceCSV,TargetYML:Text;
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

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CSV2YAML : Cette commande permet de convertir un fichier CSV en ',
                    'format YAML (extension .YML).');
  WriteLn;
  WriteLn('Syntaxe : CSV2YAML source.CSV target.YML');
  WriteLn;
  WriteLn(' source.CSV  Nom du fichier a convertir');
  WriteLn(' target.YML  Nom du fichier du rÇsultat');
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
      WriteLn('-');
      PosField:=0;
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(' ':8,Fields[PosField],': ');
         WriteLn(Copy(CurrWord,2,Length(CurrWord)-2));
        End
         Else
        Begin
         Write(' ':8,Fields[PosField],': ');
         WriteLn(CurrWord);
        End;
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(' ':8,Fields[PosField],': ');
      If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
        Write(Copy(CurrWord,2,Length(CurrWord)-2));
       End
        Else
       Write(CurrWord);
     End;
    End;
    Close(SourceCSV);
   End
    Else
   Begin
    TFileName:=FExpand(ParamStr(2));
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.YML';
    Assign(TargetYML,TFileName);
    {$I-}Rewrite(TargetYML); {$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de crÇer le fichier YAML ',TFileName,' !');
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
      WriteLn(TargetYML,'-');
      PosField:=0;
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(TargetYML,' ':8,Fields[PosField],': ');
         WriteLn(TargetYML,Copy(CurrWord,2,Length(CurrWord)-2));
        End
         Else
        Begin
         Write(TargetYML,' ':8,Fields[PosField],': ');
         WriteLn(TargetYML,CurrWord);
        End;
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(TargetYML,' ':8,Fields[PosField],': ');
      If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
        Write(TargetYML,Copy(CurrWord,2,Length(CurrWord)-2));
       End
        Else
       Write(TargetYML,CurrWord);
     End;
    End;
    Close(TargetYML);
    Close(SourceCSV);
   End;
  End
   Else
  WriteLn('Paramätre requis !');
 End;
END.
