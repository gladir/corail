{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program TSV2CPP(Input,Output);

Uses DOS;

Var
 SourceTSV,TargetC:Text;
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
  WriteLn('TSV2CPP : Cette commande permet de convertir un fichier TSV ',
                     'en code source C++.');
  WriteLn;
  WriteLn('Syntaxe : TSV2CPP source.TSV target.CPP');
  WriteLn;
  WriteLn(' source.TSV   Nom du fichier a convertir');
  WriteLn(' target.CPP   Nom du fichier du resultat');
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
      WriteLn('typedef struct ',TableName,'Rec {');
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=#9 Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         WriteLn('  char ',Copy(CurrWord,2,Length(CurrWord)-2),'[255];');
         Fields[NumField]:=Copy(CurrWord,2,Length(CurrWord)-2);
         Inc(NumField);
        End
         Else
        Begin
         WriteLn('  char ',CurrWord,'[255];');
         Fields[NumField]:=CurrWord;
         Inc(NumField);
        End;
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      WriteLn('  char ',CurrWord,'[255];');
      CurrField:=CurrWord;
      Fields[NumField]:=CurrWord;
      Inc(NumField);
      If NumField>High(Fields)Then Begin
       WriteLn('Enregistrement trop grand !');
       Halt;
      End;
      WriteLn(' };');
      WriteLn;
      WriteLn('const struct ',TableName,'Rec ',TableName,'[',NumRecord,']={');
     End
      Else
     Begin
      PosField:=0;
      CurrWord:='';
      Write('  {');
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=#9 Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write('.',Fields[PosField],'=','"',StringToCString(Copy(CurrWord,2,Length(CurrWord)-2)),'",');
        End
         Else
        Write('.',Fields[PosField],'=','"',StringToCString(CurrWord),'",');
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write('.',Fields[PosField],'=','"',StringToCString(CurrWord),'"');
      Write('}');
      Inc(CurrRecord);
      If CurrRecord<NumRecord Then WriteLn(',')
                              Else WriteLn;
     End;
    End;
    WriteLn(' };');
    Close(SourceTSV);
   End
    Else
   Begin
    TFileName:=FExpand(ParamStr(2));
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.CPP';
    Assign(TargetC,TFileName);
    {$I-}Rewrite(TargetC); {$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de cr�er le fichier C++ ',TFileName,' !');
     Close(SourceTSV);
     Halt;
    End;
    First:=True;
    While Not EOF(SourceTSV)do Begin
     ReadLn(SourceTSV,CurrLine);
     If(First)Then Begin
      First:=False;
      WriteLn(TargetC,'typedef struct ',TableName,'Rec {');
      CurrWord:='';
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=#9 Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         WriteLn(TargetC,'  char ',Copy(CurrWord,2,Length(CurrWord)-2),'[255];');
         Fields[NumField]:=Copy(CurrWord,2,Length(CurrWord)-2);
         Inc(NumField);
        End
         Else
        Begin
         WriteLn(TargetC,'  char ',CurrWord,'[255];');
         Fields[NumField]:=CurrWord;
         Inc(NumField);
        End;
        CurrWord:='';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      WriteLn(TargetC,'  char ',CurrWord,'[255];');
      CurrField:=CurrWord;
      Fields[NumField]:=CurrWord;
      Inc(NumField);
      If NumField>High(Fields)Then Begin
       WriteLn('Enregistrement trop grand !');
       Halt;
      End;
      WriteLn(TargetC,' };');
      WriteLn(TargetC);
      WriteLn(TargetC,'const struct ',TableName,'Rec ',TableName,'[',NumRecord,']={');
     End
      Else
     Begin
      CurrWord:='';
      PosField:=0;
      Write(TargetC,'  {');
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]=#9 Then Begin
        If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
         Write(TargetC,'.',Fields[PosField],'=','"',StringToCString(Copy(CurrWord,2,Length(CurrWord)-2)),'",');
        End
         Else
        Write(TargetC,'.',Fields[PosField],'=','"',StringToCString(CurrWord),'",');
        CurrWord:='';
        Inc(PosField);
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Write(TargetC,'.',Fields[PosField],'=','"',StringToCString(CurrWord),'"');
      Write(TargetC,'}');
      Inc(CurrRecord);
      If CurrRecord<NumRecord Then WriteLn(TargetC,',')
                              Else WriteLn(TargetC);
     End;
    End;
    WriteLn(TargetC,' };');
    Close(TargetC);
    Close(SourceTSV);
   End;
  End
   Else
  Begin
   WriteLn('const struct ',TableName,'Rec ',TableName,'[]={');
   While Not EOF do Begin
    ReadLn(Input,CurrLine);
    Write('{');
    CurrWord:='';
    For I:=1 to Length(CurrLine)do Begin
     If CurrLine[I]=#9 Then Begin
      If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
       Write('"',StringToCString(Copy(CurrWord,2,Length(CurrWord)-2)),'",');
      End
       Else
      Write('"',StringToCString(CurrWord),'",');
      CurrWord:='';
     End
      Else
     CurrWord:=CurrWord+CurrLine[I];
    End;
    Write('"',StringToCString(CurrWord),'"');
    WriteLn('};');
   End;
  End;
 End;
END.



