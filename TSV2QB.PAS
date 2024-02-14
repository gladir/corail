{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program TSV2QB(Input,Output);

Uses DOS;

Var
 SourceTSV,TargetQB:Text;
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
  If Source[I]='"'Then ConvStr:=ConvStr+'"+CHR$(34)+"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToBasicString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('TSV2QB : Cette commande permet de convertir un fichier TSV ',
                     'en code source QuickBASIC ou QBasic.');
  WriteLn;
  WriteLn('Syntaxe : TSV2QB source.TSV [target.BAS]');
  WriteLn;
  WriteLn(' source.TSV  Nom du fichier a convertir');
  WriteLn(' target.BAS  Nom du fichier du r‚sultat');
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
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=#9 Then Begin
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
      Write('DATA ');
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=#9 Then Begin
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
    Close(SourceTSV);
   End
    Else
   Begin
    TFileName:=FExpand(ParamStr(2));
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.BAS';
    Assign(TargetQB,TFileName);
    {$I-}Rewrite(TargetQB); {$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de cr‚er le fichier BAS ',TFileName,' !');
     Close(SourceTSV);
     Halt;
    End;
    First:=True;
    While Not EOF(SourceTSV)do Begin
     ReadLn(SourceTSV,CurrLine);
     If(First)Then Begin
      First:=False;
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=#9 Then Begin
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
      Write(TargetQB,'DATA ');
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=#9 Then Begin
        If PosField>0Then Write(TargetQB,',');
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(TargetQB,'"',StringToBasicString(Copy(CurrWord,2,Length(CurrWord)-2)),'"');
        End
         Else
        Write(TargetQB,'"',StringToBasicString(CurrWord),'"');
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      If PosField>0Then Write(TargetQB,',');
      Write(TargetQB,'"',StringToBasicString(CurrWord),'"');
      WriteLn(TargetQB);
     End;
    End;
    Close(TargetQB);
    Close(SourceTSV);
   End;
  End
   Else
  Begin
   While Not EOF do Begin
    ReadLn(Input,CurrLine);
    Write('DATA ');
    CurrWord:='';
    PosField:=0;
    For I:=1 to Length(CurrLine)do Begin
     If CurrLine[I]=#9 Then Begin
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


