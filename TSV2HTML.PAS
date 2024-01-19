{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program TSV2HTML(Input,Output);

Uses DOS;

Var
 SourceTSV,TargetHTML:Text;
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


Function Escape(S:String):String;
Var
 I:Integer;
 T:String;
Begin
 T:='';
 For I:=1 to Length(S)do Begin
  Case S[I]of
   '&':T:=T+'&amp;';
   '<':T:=T+'&lt;';
   '>':T:=T+'&gt;';
   '"':T:=T+'&quot;';
   Else T:=T+S[I];
  End;
 End;
 Escape:=T;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('TSV2HTML : Cette commande permet de convertir un fichier ',
                      'TSV (Tab-Separeted Values) en HTML.');
  WriteLn;
  WriteLn('Syntaxe : TSV2HTML source.TSV target.HTML');
  WriteLn;
  WriteLn(' source.TSV   Nom du fichier a convertir');
  WriteLn(' target.HTML  Nom du fichier du r‚sultat');
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
   If ParamStr(2)=''Then Begin
    First:=True;
    WriteLn('<html>');
    WriteLn('<table>');
    While Not EOF(SourceTSV)do Begin
     ReadLn(SourceTSV,CurrLine);
     If(First)Then Begin
      First:=False;
      CurrWord:='';
      WriteLn(' ':4,'<tr>');
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=#9 Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Fields[NumField]:=Copy(CurrWord,2,Length(CurrWord)-2);
         WriteLn(' ':8,'<th>',Escape(Fields[NumField]),'</th>');
         Inc(NumField);
        End
         Else
        Begin
         Fields[NumField]:=CurrWord;
         WriteLn(' ':8,'<th>',Escape(Fields[NumField]),'</th>');
         Inc(NumField);
        End;
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      CurrField:=CurrWord;
      Fields[NumField]:=CurrWord;
      WriteLn(' ':8,'<th>',Escape(Fields[NumField]),'</th>');
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
       If CurrLine[I]=#9 Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(' ':8,'<td>');
         Write(Escape(Copy(CurrWord,2,Length(CurrWord)-2)));
         WriteLn('</td>');
        End
         Else
        Begin
         Write(' ':8,'<td>');
         Write(Escape(CurrWord));
         WriteLn('</td>');
        End;
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(' ':8,'<td>');
      If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
       Write(Escape(Copy(CurrWord,2,Length(CurrWord)-2)));
      End
       Else
      Write(Escape(CurrWord));
      Write(Escape(Copy(CurrWord,2,Length(CurrWord)-2)));
      WriteLn('</td>');
      WriteLn(' ':4,'</tr>');
     End;
    End;
    WriteLn('</table>');
    WriteLn('</html>');
    Close(SourceTSV);
   End
    Else
   Begin
    TFileName:=FExpand(ParamStr(2));
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.HTML';
    Assign(TargetHTML,TFileName);
    {$I-}Rewrite(TargetHTML); {$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de cr‚er le fichier HTML ',TFileName,' !');
     Close(SourceTSV);
     Halt;
    End;
    First:=True;
    WriteLn(TargetHTML,'<html>');
    WriteLn(TargetHTML,'<table>');
    While Not EOF(SourceTSV)do Begin
     ReadLn(SourceTSV,CurrLine);
     If(First)Then Begin
      First:=False;
      CurrWord:='';
      WriteLn(TargetHTML,' ':4,'<tr>');
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=#9 Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Fields[NumField]:=Copy(CurrWord,2,Length(CurrWord)-2);
         WriteLn(TargetHTML,' ':8,'<th>',Escape(Fields[NumField]),'</th>');
         Inc(NumField);
        End
         Else
        Begin
         Fields[NumField]:=CurrWord;
         WriteLn(TargetHTML,' ':8,'<th>',Escape(Fields[NumField]),'</th>');
         Inc(NumField);
        End;
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      CurrField:=CurrWord;
      Fields[NumField]:=CurrWord;
      WriteLn(TargetHTML,' ':8,'<th>',Escape(Fields[NumField]),'</th>');
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
       If CurrLine[I]=#9 Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(TargetHTML,' ':8,'<td>');
         Write(TargetHTML,Escape(Copy(CurrWord,2,Length(CurrWord)-2)));
         WriteLn(TargetHTML,'</td>');
        End
         Else
        Begin
         Write(TargetHTML,' ':8,'<td>');
         Write(TargetHTML,Escape(CurrWord));
         WriteLn(TargetHTML,'</td>');
        End;
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(TargetHTML,' ':8,'<td>');
      If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
       Write(TargetHTML,Escape(Copy(CurrWord,2,Length(CurrWord)-2)));
      End
       Else
      Write(TargetHTML,Escape(CurrWord));
      WriteLn(TargetHTML,'</td>');
      WriteLn(TargetHTML,' ':4,'</tr>');
     End;
    End;
    WriteLn(TargetHTML,'</table>');
    WriteLn(TargetHTML,'</html>');
    Close(TargetHTML);
    Close(SourceTSV);
   End;
  End
   Else
  WriteLn('ParamŠtre requis !');
 End;
END.

