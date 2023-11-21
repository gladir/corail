{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program SQL2CSV;

Uses DOS;

Const
 CommandList:Array[0..5]of String[8]=(
  'CREATE','DELETE','INSERT','SELECT','SHOW','UPDATE'
 );

Type
 FieldRec=Record
  FieldName:String[50];
  FieldType:Char;
  Spare1,Spare2:Integer;
  Width,Dec:Byte;
 End;

Var
 SourceSQL:Text;
 TargetDBF:File;
 CommandFound,FirstInsert:Boolean;
 FieldCount:Integer;
 TargetName,CurrLine,CurrCommand,ParamList,TableName:String;
 J,ByteWrited:Integer;
 FieldList:Array[0..127]of FieldRec;

Function TrimL(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If S[I]<>' 'Then Begin
   TrimL:=Copy(S,I,255);
   Exit;
  End;
 End;
 TrimL:=S;
End;

Function TrimR(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 TrimR:=S;
End;

Function Trim(s:String):String;Begin
 Trim:=TrimL(TrimR(s));
End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
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

Function Path2NoExt(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2NoExt:=D+N;
End;

Procedure ExtractCommand;
Var
 I,J:Byte;
Begin
 For I:=1 to Length(CurrLine)do Begin
  If Not(CurrLine[I]in['A'..'Z','a'..'z','_','-','0'..'9'])Then Begin
   CurrCommand:=StrToUpper(Copy(CurrLine,1,I-1));
   ParamList:=TrimL(Copy(CurrLine,I,255));
   Exit;
  End;
 End;
 CurrCommand:=StrToUpper(CurrLine);
 ParamList:='';
End;

Procedure CreateCommand;
Var
 Step:(_None,_Open,_Sep,_Close);
 Finished:Boolean;
 CurrWord,CurrWord2:String;
 I:Byte;
 ByteWrited:Integer;
Begin
 Finished:=False;
 If ParamList=''Then ReadLn(SourceSQL,ParamList);
 CurrWord:='';
 I:=1;
 While(I<=Length(ParamList))and(ParamList[I]in['A'..'Z','a'..'z'])do Begin
  CurrWord:=CurrWord+ParamList[I];
  Inc(I);
 End;
 If StrToUpper(CurrWord)<>'TABLE'Then Begin
  WriteLn('Mot clef TABLE attendu !');
  Halt;
 End;
 While(I<=Length(ParamList))and(ParamList[I]in[' ',#9])do Inc(I);
 CurrWord2:='';
 While(I<=Length(ParamList))and(ParamList[I]in['A'..'Z','a'..'z'])do Begin
  CurrWord2:=CurrWord2+ParamList[I];
  Inc(I);
 End;
 If CurrWord2<>''Then Begin
  TableName:=CurrWord2;
 End
  Else
 Begin
  WriteLn('Nom de la table attendu !');
  Halt;
 End;
 Step:=_None;
 Repeat
  Repeat
   While(I<=Length(ParamList))and(ParamList[I]in[' ',#9])do Inc(I);
   If(Step=_None)Then Begin
    If(I<=Length(ParamList))and(ParamList[I]='(')Then Begin
     Step:=_Open;
     Inc(I);
    End;
   End
    Else
   If(Step=_Sep)Then Begin
    If(I<=Length(ParamList))and(ParamList[I]=')')Then Finished:=True Else
    If(I<=Length(ParamList))and(ParamList[I]=',')Then Begin
     Inc(I);
     Step:=_Open;
    End
     Else
    Begin
     WriteLn('S‚parateur attendue !');
    End;
   End
    Else
   Begin
    FillChar(CurrWord,SizeOf(CurrWord),#0);
    CurrWord:='';
    While(I<=Length(ParamList))and(ParamList[I]in['A'..'Z','a'..'z'])do Begin
     CurrWord:=CurrWord+ParamList[I];
     Inc(I);
    End;
    If CurrWord<>''Then Begin
     While(I<=Length(ParamList))and(ParamList[I]in[' ',#9])do Inc(I);
     CurrWord2:='';
     While(I<=Length(ParamList))and(ParamList[I]in['A'..'Z','a'..'z'])do Begin
      CurrWord2:=CurrWord2+ParamList[I];
      Inc(I);
     End;
     If CurrWord2<>''Then Begin
     FieldList[FieldCount].FieldName:=CurrWord;
      If StrToUpper(CurrWord2)='BYTE'Then  Begin
       FieldList[FieldCount].FieldType:='L';
      End
       Else
      If StrToUpper(CurrWord2)='TEXT'Then Begin
       FieldList[FieldCount].FieldType:='C';
       FieldList[FieldCount].Width:=255;
      End
       Else
      If StrToUpper(CurrWord2)='INTEGER'Then Begin
       FieldList[FieldCount].FieldType:='I';
      End
       Else
      If StrToUpper(CurrWord2)='SMALLINT'Then Begin
       FieldList[FieldCount].FieldType:='I';
      End
       Else
      If StrToUpper(CurrWord2)='VARCHAR'Then Begin
       FieldList[FieldCount].FieldType:='C';
       FieldList[FieldCount].Width:=255;
      End
       Else
      Begin
       WriteLn('Type de donn‚es non reconnu : ',CurrWord2);
       Halt;
      End;
      Inc(FieldCount);
      Step:=_Sep;
     End
      Else
     Begin
      WriteLn('Type de donn‚es attendue');
      Halt;
     End;
    End;
   End;
  Until(I>=Length(ParamList))or(Finished);
  If Not(Finished)Then Begin
   If EOF(SourceSQL)Then Finished:=True
    Else
   Begin
    ReadLn(SourceSQL,ParamList);
    I:=1;
  End;
 End;
 Until Finished;
 If FieldCount>0 Then For I:=0 to FieldCount-1 do Begin
  If I>0 Then Write(',');
  Write('"',Trim(FieldList[I].FieldName),'"');
 End;
 WriteLn;
End;

Procedure DeleteCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure InsertCommand;
Var
 Finished:Boolean;
 CurrWord,CurrWord2:String;
 I:Byte;
 Step:(_None,_Open,_Sep,_Close);
 CurrField,ByteWrited:Integer;
Begin
 Finished:=False;
 CurrField:=0;
 If ParamList=''Then ReadLn(SourceSQL,ParamList);
 CurrWord:='';
 I:=1;
 While(I<=Length(ParamList))and(ParamList[I]in['A'..'Z','a'..'z'])do Begin
  CurrWord:=CurrWord+ParamList[I];
  Inc(I);
 End;
 If StrToUpper(CurrWord)<>'INTO'Then Begin
  WriteLn('Mot clef INTO attendu !');
  Halt;
 End;
 Step:=_None;
 While(I<=Length(ParamList))and(ParamList[I]in[' ',#9])do Inc(I);
 CurrWord2:='';
 While(I<=Length(ParamList))and(ParamList[I]in['A'..'Z','a'..'z'])do Begin
  CurrWord2:=CurrWord2+ParamList[I];
  Inc(I);
 End;
 If CurrWord2<>''Then Begin
  TableName:=CurrWord2;
 End;
 Repeat
  Repeat
   While(I<=Length(ParamList))and(ParamList[I]in[' ',#9])do Inc(I);
   If(Step=_None)Then Begin
    If(I<=Length(ParamList))and(ParamList[I]='(')Then Begin
     Step:=_Open;
     Inc(I);
    End;
   End
    Else
   If(Step=_Sep)Then Begin
    If(I<=Length(ParamList))and(ParamList[I]=')')Then Begin
     Inc(I);
     Step:=_Close;
     Finished:=True;
    End
     Else
    If(I<=Length(ParamList))and(ParamList[I]=',')Then Begin
     Inc(I);
     Step:=_Open;
    End
     Else
    Begin
     WriteLn('Position ',I,', caractŠre rencontr‚ : ',ParamList[I]);
     WriteLn('S‚parateur attendue !');
     Halt;
    End;
   End
    Else
   Begin
    FillChar(CurrWord,SizeOf(CurrWord),#0);
    CurrWord:='';
    If(I<=Length(ParamList))and(ParamList[I]='''')Then Begin
     Inc(I);
     While(I<=Length(ParamList))and(ParamList[I]<>'''')do Begin
      CurrWord:=CurrWord+ParamList[I];
      Inc(I);
     End;
     If(I<=Length(ParamList))and(ParamList[I]='''')Then Begin
      Inc(I);
     End
      Else
     Begin
      WriteLn('Chaine de caractŠres sans terminaison.');
      Halt;
     End;
     Step:=_Sep;
    End
     Else
    If(I<=Length(ParamList))and(ParamList[I]in['0'..'9'])Then Begin
     While(I<=Length(ParamList))and(ParamList[I]in['0'..'9'])do Begin
      CurrWord:=CurrWord+ParamList[I];
      Inc(I);
     End;
     Step:=_Sep;
    End
     Else
    Begin
     WriteLn('Donn‚es attendue !');
     Halt;
    End;
    Write('"',CurrWord,'"');
    Inc(CurrField);
    If(CurrField<FieldCount)Then Write(',');
   End;
  Until(I>=Length(ParamList))or(Finished);
  If Not(Finished)Then Begin
   If EOF(SourceSQL)Then Finished:=True
    Else
   Begin
    ReadLn(SourceSQL,ParamList);
    I:=1;
   End;
  End;
 Until Finished;
 WriteLn;
 FirstInsert:=False;
End;

Procedure SelectCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ShowComamnd;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ShowCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('SQL2CSV - Cette commande permet de convertir un fichier SQL en CSV.');
  WriteLn;
  WriteLn('Syntaxe : SQL2CSV source.SQL');
 End
  Else
 Begin
  TableName:='';
  FirstInsert:=True;
  FieldCount:=0;
  FillChar(FieldList,SizeOf(FieldList),0);
  {$I-}Assign(SourceSQL,ParamStr(1));
  Reset(SourceSQL);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible d''ouvrir le fichier ',ParamStr(1));
   Halt;
  End;
  While Not EOF(SourceSQL)do Begin
   ReadLn(SourceSQL,CurrLine);
   ExtractCommand;
   CommandFound:=False;
   For J:=Low(CommandList) to High(CommandList) do Begin
    If CurrCommand=CommandList[J]Then Begin
     CommandFound:=True;
     Case(J)of
      0:CreateCommand;
      1:DeleteCommand;
      2:InsertCommand;
      3:SelectCommand;
      4:ShowComamnd;
      5:ShowCommand;
      Else Begin
       WriteLn('Commande non reconnu');
       Halt;
      End;
     End;
    End;
   End;
   If Not(CommandFound)Then Begin
    WriteLn('Command non support‚');
    Halt;
   End;
  End;
  Close(SourceSQL);
 End;
END.
