{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program VIEWCSV(Input,Output);

Uses DOS;

Var
 SourceCSV:Text;
 CurrLine,CurrWord,CurrField,TableName,FileName,TFileName:String;
 I:Integer;
 First:Boolean;
 Fields:Array[0..100]of String[75];
 FieldsWidth:Array[0..100]of Integer;
 PosField,NumField,CurrLength:Integer;
 NumFieldMax:Integer;
 NumRecord:LongInt;

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
  WriteLn('VIEWCSV : Cette commande permet de visualiser proprement un ',
                     'fichier CSV dans un terminal.');
  WriteLn;
  WriteLn('Syntaxe : VIEWCSV fichier.CSV');
  WriteLn;
  WriteLn(' fichier.CSV  Nom du fichier a afficher');
  WriteLn;
 End
  Else
 Begin
  CurrLength:=0;
  NumRecord:=0;
  NumField:=0;
  NumFieldMax:=0;
  FillChar(Fields,SizeOf(Fields),0);
  FillChar(FieldsWidth,SizeOf(FieldsWidth),0);
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
    NumField:=0;
    For I:=1 to Length(CurrLine)do Begin
     If CurrLine[I]=','Then Begin
      If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
       CurrLength:=Length(Copy(CurrWord,2,Length(CurrWord)-2));
       If(CurrLength>FieldsWidth[NumField])Then FieldsWidth[NumField]:=CurrLength;
       Inc(NumField);
      End
       Else
      Begin
       CurrLength:=Length(CurrWord);
       If(CurrLength>FieldsWidth[NumField])Then FieldsWidth[NumField]:=CurrLength;
       Inc(NumField);
      End;
      CurrWord:='';
     End
      Else
     CurrWord:=CurrWord+CurrLine[I];
    End;
    CurrLength:=Length(CurrWord);
    If(CurrLength>FieldsWidth[NumField])Then FieldsWidth[NumField]:=CurrLength;
    Inc(NumField);
    If(NumField>NumFieldMax)Then NumFieldMax:=NumField;
   End;
   Close(SourceCSV);
   NumField:=0;
   Dec(NumRecord);
   Assign(SourceCSV,FileName);
   {$I-}Reset(SourceCSV);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Fichier CSV introuvable !');
    Halt;
   End;
   First:=True;
   While Not EOF(SourceCSV)do Begin
    ReadLn(SourceCSV,CurrLine);
    If(First)Then Begin
     First:=False;
     For I:=0 to NumFieldMax-1 do Write('+',Dupl('-',FieldsWidth[I]));
     WriteLn('+');
     CurrWord:='';
     For I:=1 to Length(CurrLine)do Begin
      If CurrLine[I]=','Then Begin
       If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
        Fields[NumField]:=Copy(CurrWord,2,Length(CurrWord)-2);
        Write('|',PadRight(Fields[NumField],FieldsWidth[NumField]));
        Inc(NumField);
       End
        Else
       Begin
        Fields[NumField]:=CurrWord;
        Write('|',PadRight(Fields[NumField],FieldsWidth[NumField]));
        Inc(NumField);
       End;
       CurrWord:='';
      End
       Else
      CurrWord:=CurrWord+CurrLine[I];
     End;
     CurrField:=CurrWord;
     Fields[NumField]:=CurrWord;
     WriteLn('|',PadRight(Fields[NumField],FieldsWidth[NumField]),'|');
     Inc(NumField);
     If NumField>High(Fields)Then Begin
      WriteLn('Enregistrement trop grand !');
      Halt;
     End;
     For I:=0 to NumField-1 do Write('+',Dupl('-',FieldsWidth[I]));
     WriteLn('+');
    End
     Else
    Begin
     PosField:=0;
     CurrWord:='';
     For I:=1 to Length(CurrLine)do Begin
      If CurrLine[I]=','Then Begin
       Write('|');
       If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
        Write(PadRight(StringToBasicString(Copy(CurrWord,2,Length(CurrWord)-2)),FieldsWidth[PosField]));
       End
        Else
       Write(PadRight(StringToBasicString(CurrWord),FieldsWidth[PosField]));
       CurrWord:='';
       Inc(PosField);
      End
       Else
      CurrWord:=CurrWord+CurrLine[I];
     End;
     Write('|',PadRight(StringToBasicString(CurrWord),FieldsWidth[PosField]));
     WriteLn('|');
    End;
   End;
   For I:=0 to NumField-1 do Write('+',Dupl('-',FieldsWidth[I]));
   WriteLn('+');
   Close(SourceCSV);
  End
   Else
  Begin
   While Not EOF do Begin
    ReadLn(Input,CurrLine);
    CurrWord:='';
    PosField:=0;
    For I:=1 to Length(CurrLine)do Begin
     If CurrLine[I]=','Then Begin
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

