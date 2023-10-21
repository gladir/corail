{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CSV2XML(Input,Output);

Uses DOS;

Var
 SourceCSV,TargetXML:Text;
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
  WriteLn('CSV2XML : Cette commande permet de convertir un fichier CSV en XML.');
  WriteLn;
  WriteLn('Syntaxe : CSV2XML source.CSV target.XML');
  WriteLn;
  WriteLn(' fichier.CSV  Nom du fichier a convertir');
  WriteLn(' fichier.XML  Nom du fichier du resultat');
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
    WriteLn('<?xml version="1.0" encoding="UTF-8"?>');
    WriteLn('<table>');
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
      WriteLn(' ':4,'<line>');
      PosField:=0;
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(' ':8,'<',Fields[PosField],'>');
         Write(Copy(CurrWord,2,Length(CurrWord)-2));
         WriteLn('</',Fields[PosField],'>');
        End
         Else
        Begin
         Write(' ':8,'<',Fields[PosField],'>');
         Write(CurrWord);
         WriteLn('</',Fields[PosField],'>');
        End;
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(' ':8,'<',Fields[PosField],'>');
      Write(Copy(CurrWord,2,Length(CurrWord)-2));
      WriteLn('</',Fields[PosField],'>');
      WriteLn(' ':4,'</line>');
     End;
    End;
    WriteLn('</table>');
    Close(SourceCSV);
   End
    Else
   Begin
    TFileName:=FExpand(ParamStr(2));
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.XML';
    Assign(TargetXML,TFileName);
    {$I-}Rewrite(TargetXML); {$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de cr‚er le fichier XML ',TFileName,' !');
     Close(SourceCSV);
     Halt;
    End;
    First:=True;
    WriteLn(TargetXML,'<?xml version="1.0" encoding="UTF-8"?>');
    WriteLn(TargetXML,'<table>');
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
      WriteLn(TargetXML,' ':4,'<line>');
      PosField:=0;
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(TargetXML,' ':8,'<',Fields[PosField],'>');
         Write(TargetXML,Copy(CurrWord,2,Length(CurrWord)-2));
         WriteLn(TargetXML,'</',Fields[PosField],'>');
        End
         Else
        Begin
         Write(TargetXML,' ':8,'<',Fields[PosField],'>');
         Write(TargetXML,CurrWord);
         WriteLn(TargetXML,'</',Fields[PosField],'>');
        End;
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(TargetXML,' ':8,'<',Fields[PosField],'>');
      Write(TargetXML,Copy(CurrWord,2,Length(CurrWord)-2));
      WriteLn(TargetXML,'</',Fields[PosField],'>');
      WriteLn(TargetXML,' ':4,'</line>');
     End;
    End;
    WriteLn(TargetXML,'</table>');
    Close(TargetXML);
    Close(SourceCSV);
   End;
  End
   Else
  WriteLn('ParamŠtre requis !');
 End;
END.
