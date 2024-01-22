{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program MDT(Input,Output);

Uses DOS;

Var
 SourceCSV,TargetMD:Text;
 CurrLine,CurrWord,CurrField,TableName,FileName,TFileName:String;
 I:Integer;
 First,TSVMode:Boolean;
 Fields:Array[0..100]of String[75];
 PosField,NumField,CurrLength,MaxLength:Integer;
 NumRecord:LongInt;
 Delimiter:Char;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;


Function Dupl(C:Char;Num:Integer):String;
Var
 I:Byte;
 S:String;
Begin
 S:='';
 For I:=1 to Num do S:=S+C;
 Dupl:=S;
End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

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
  If Source[I]='|'Then ConvStr:=ConvStr+'\|';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToBasicString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('MDT : Cette commande permet de convertir un fichier CSV ou TSV',
                   'en une table Markdown.');
  WriteLn;
  WriteLn('Syntaxe : MDT source.CSV|source.TSV [target.MD]');
  WriteLn;
  WriteLn(' source.CSV  Nom du fichier a convertir');
  WriteLn(' source.TSV  Nom du fichier a convertir');
  WriteLn(' target.MD   Nom du fichier du r‚sultat');
  WriteLn;
 End
  Else
 Begin
  Delimiter:=',';
  TSVMode:=False;
  CurrLength:=0;
  MaxLength:=0;
  NumRecord:=0;
  NumField:=0;
  FillChar(Fields,SizeOf(Fields),0);
  If ParamCount>0Then Begin
   TableName:=Path2Name(ParamStr(1));
   FileName:=FExpand(ParamStr(1));
   If Path2Ext(FileName)=''Then FileName:=FileName+'.CSV';
   If StrToUpper(Path2Ext(FileName))='.TSV'Then Begin
    Delimiter:=#9;
    TSVMode:=True;
   End;
   Assign(SourceCSV,FileName);
   {$I-}Reset(SourceCSV);{$I+}
   If IoResult<>0Then Begin
    If(TSVMode)Then WriteLn('Fichier TSV introuvable !')
               Else WriteLn('Fichier CSV introuvable !');
    Halt(1);
   End;
   While Not EOF(SourceCSV)do Begin
    ReadLn(SourceCSV,CurrLine);
    For I:=1 to Length(CurrLine)do Begin
     If CurrLine[I]=Delimiter Then Begin
      If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
       CurrLength:=Length(Copy(CurrWord,2,Length(CurrWord)-2));
       If(CurrLength>MaxLength)Then MaxLength:=CurrLength;
      End
       Else
      Begin
       CurrLength:=Length(CurrWord);
       If(CurrLength>MaxLength)Then MaxLength:=CurrLength;
      End;
      CurrWord:='';
     End
      Else
     CurrWord:=CurrWord+CurrLine[I];
    End;
    CurrLength:=Length(CurrWord);
    If(CurrLength>MaxLength)Then MaxLength:=CurrLength;
   End;
   Close(SourceCSV);
   Dec(NumRecord);
   Assign(SourceCSV,FileName);
   {$I-}Reset(SourceCSV);{$I+}
   If IoResult<>0Then Begin
    If(TSVMode)Then WriteLn('Fichier TSV introuvable !')
               Else WriteLn('Fichier CSV introuvable !');
    Halt(2);
   End;
   If ParamStr(2)=''Then Begin
    First:=True;
    While Not EOF(SourceCSV)do Begin
     ReadLn(SourceCSV,CurrLine);
     If(First)Then Begin
      First:=False;
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=Delimiter Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Fields[NumField]:=Copy(CurrWord,2,Length(CurrWord)-2);
         Inc(NumField);
        End
         Else
        Begin
         Fields[NumField]:=CurrWord;
         Inc(NumField);
        End;
        Write('|',PadRight(Fields[NumField-1],MaxLength));
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      CurrField:=CurrWord;
      Fields[NumField]:=CurrWord;
      WriteLn('|',PadRight(Fields[NumField],MaxLength),'|');
      Inc(NumField);
      If NumField>High(Fields)Then Begin
       WriteLn('Enregistrement trop grand !');
       Halt;
      End;
      For I:=1 to NumField do Begin
       Write('|',PadRight(Dupl('-',MaxLength),MaxLength));
      End;
      WriteLn('|');
     End
      Else
     Begin
      PosField:=0;
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=Delimiter Then Begin
        Write('|');
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(PadRight(StringToBasicString(Copy(CurrWord,2,Length(CurrWord)-2)),MaxLength));
        End
         Else
        Write(PadRight(StringToBasicString(CurrWord),MaxLength));
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write('|',PadRight(StringToBasicString(CurrWord),MaxLength));
      WriteLn('|');
     End;
    End;
    Close(SourceCSV);
   End
    Else
   Begin
    TFileName:=FExpand(ParamStr(2));
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.MD';
    Assign(TargetMD,TFileName);
    {$I-}Rewrite(TargetMD); {$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de cr‚er le fichier MD ',TFileName,' !');
     Close(SourceCSV);
     Halt(3);
    End;
    First:=True;
    While Not EOF(SourceCSV)do Begin
     ReadLn(SourceCSV,CurrLine);
     If(First)Then Begin
      First:=False;
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=Delimiter Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Fields[NumField]:=Copy(CurrWord,2,Length(CurrWord)-2);
         Inc(NumField);
        End
         Else
        Begin
         Fields[NumField]:=CurrWord;
         Inc(NumField);
        End;
        Write(TargetMD,'|',PadRight(Fields[NumField-1],MaxLength));
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      CurrField:=CurrWord;
      Fields[NumField]:=CurrWord;
      WriteLn(TargetMD,'|',PadRight(Fields[NumField],MaxLength),'|');
      Inc(NumField);
      If NumField>High(Fields)Then Begin
       WriteLn('Enregistrement trop grand !');
       Halt(4);
      End;
      For I:=1 to NumField do Begin
       Write(TargetMD,'|',Dupl('-',MaxLength));
      End;
      WriteLn(TargetMD,'|');
     End
      Else
     Begin
      PosField:=0;
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=Delimiter Then Begin
        Write(TargetMD,'|');
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(TargetMD,PadRight(StringToBasicString(Copy(CurrWord,2,Length(CurrWord)-2)),MaxLength));
        End
         Else
        Write(TargetMD,PadRight(StringToBasicString(CurrWord),MaxLength));
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(TargetMD,'|',PadRight(StringToBasicString(CurrWord),MaxLength));
      WriteLn(TargetMD,'|');
     End;
    End;
    Close(TargetMD);
    Close(SourceCSV);
   End;
  End
   Else
  Begin
   While Not EOF do Begin
    ReadLn(Input,CurrLine);
    CurrWord:='';
    PosField:=0;
    For I:=1 to Length(CurrLine)do Begin
     If CurrLine[I]=Delimiter Then Begin
      Write('|');
      If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
       Write(StringToBasicString(Copy(CurrWord,2,Length(CurrWord)-2)));
      End
       Else
      Write(StringToBasicString(CurrWord));
      CurrWord:='';
      Inc(PosField);
     End
      Else
     CurrWord:=CurrWord+CurrLine[I];
    End;
    If PosField=0Then Write('|');
    Write(StringToBasicString(CurrWord));
    Inc(PosField);
    WriteLn('|');
   End;
  End;
 End;
END.

