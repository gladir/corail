{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CSV2HTML(Input,Output);

Uses DOS;

Var
 SourceCSV,TargetHTML:Text;
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
  WriteLn('CSV2HTML : Cette commande permet de convertir un fichier CSV en HTML.');
  WriteLn;
  WriteLn('Syntaxe : CSV2HTML source.CSV target.HTML');
  WriteLn;
  WriteLn(' fichier.CSV   Nom du fichier a convertir');
  WriteLn(' fichier.HTML  Nom du fichier du resultat');
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
    WriteLn('<html>');
    WriteLn('<table>');
    While Not EOF(SourceCSV)do Begin
     ReadLn(SourceCSV,CurrLine);
     If(First)Then Begin
      First:=False;
      CurrWord:='';
      WriteLn(' ':4,'<tr>');
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Fields[NumField]:=Copy(CurrWord,2,Length(CurrWord)-2);
         WriteLn(' ':8,'<th>',Fields[NumField],'</th>');
         Inc(NumField);
        End
         Else
        Begin
         Fields[NumField]:=CurrWord;
         WriteLn(' ':8,'<th>',Fields[NumField],'</th>');
         Inc(NumField);
        End;
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      CurrField:=CurrWord;
      Fields[NumField]:=CurrWord;
      WriteLn(' ':8,'<th>',Fields[NumField],'</th>');
      Inc(NumField);
      If NumField>High(Fields)Then Begin
       WriteLn('Enregistrement trop grand !');
       Halt;
      End;
      WriteLn(' ':4,'</tr>');
     End
      Else
     Begin
      WriteLn(' ':4,'<tr>');
      PosField:=0;
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(' ':8,'<td>');
         Write(Copy(CurrWord,2,Length(CurrWord)-2));
         WriteLn('</td>');
        End
         Else
        Begin
         Write(' ':8,'<td>');
         Write(CurrWord);
         WriteLn('</td>');
        End;
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(' ':8,'<td>');
      Write(Copy(CurrWord,2,Length(CurrWord)-2));
      WriteLn('</td>');
      WriteLn(' ':4,'</tr>');
     End;
    End;
    WriteLn('</table>');
    WriteLn('</html>');
    Close(SourceCSV);
   End
    Else
   Begin
    TFileName:=FExpand(ParamStr(2));
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.HTML';
    Assign(TargetHTML,TFileName);
    {$I-}Rewrite(TargetHTML); {$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de cr‚er le fichier HTML ',TFileName,' !');
     Close(SourceCSV);
     Halt;
    End;
    First:=True;
    WriteLn(TargetHTML,'<html>');
    WriteLn(TargetHTML,'<table>');
    While Not EOF(SourceCSV)do Begin
     ReadLn(SourceCSV,CurrLine);
     If(First)Then Begin
      First:=False;
      CurrWord:='';
      WriteLn(TargetHTML,' ':4,'<tr>');
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Fields[NumField]:=Copy(CurrWord,2,Length(CurrWord)-2);
         WriteLn(TargetHTML,' ':8,'<th>',Fields[NumField],'</th>');
         Inc(NumField);
        End
         Else
        Begin
         Fields[NumField]:=CurrWord;
         WriteLn(TargetHTML,' ':8,'<th>',Fields[NumField],'</th>');
         Inc(NumField);
        End;
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      CurrField:=CurrWord;
      Fields[NumField]:=CurrWord;
      WriteLn(TargetHTML,' ':8,'<th>',Fields[NumField],'</th>');
      Inc(NumField);
      If NumField>High(Fields)Then Begin
       WriteLn('Enregistrement trop grand !');
       Halt;
      End;
      WriteLn(TargetHTML,' ':4,'</tr>');
     End
      Else
     Begin
      WriteLn(TargetHTML,' ':4,'<tr>');
      PosField:=0;
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=','Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(TargetHTML,' ':8,'<td>');
         Write(TargetHTML,Copy(CurrWord,2,Length(CurrWord)-2));
         WriteLn(TargetHTML,'</td>');
        End
         Else
        Begin
         Write(TargetHTML,' ':8,'<td>');
         Write(TargetHTML,CurrWord);
         WriteLn(TargetHTML,'</td>');
        End;
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(TargetHTML,' ':8,'<td>');
      Write(TargetHTML,Copy(CurrWord,2,Length(CurrWord)-2));
      WriteLn(TargetHTML,'</td>');
      WriteLn(TargetHTML,' ':4,'</tr>');
     End;
    End;
    WriteLn(TargetHTML,'</table>');
    WriteLn(TargetHTML,'</html>');
    Close(TargetHTML);
    Close(SourceCSV);
   End;
  End
   Else
  WriteLn('ParamŠtre requis !');
 End;
END.