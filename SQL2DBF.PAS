{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program SQL2DBF;

Uses DOS;

Const
 CommandList:Array[0..5]of String[8]=(
  'CREATE','DELETE','INSERT','SELECT','SHOW','UPDATE'
 );

Type
 {Structure de fichier DBase III}
 DBaseIIIFileHeaderRec=Record
  HeadType,Year,Month,Day:Byte;
  RecordCount:LongInt;
  HeaderLength,RecordSize:Integer;
  Fill:Array[1..20]of Byte;
 End;

 DBaseIIIFieldRec=Record
  FieldName:Array[1..11]of Char;
  FieldType:Char;
  Spare1,Spare2:Integer;
  Width,Dec:Byte;
  WorkSpace:Array[1..14]of Byte;
 End;

Var
 SourceSQL:Text;
 TargetDBF:File;
 CommandFound:Boolean;
 FieldCount:Integer;
 TargetName,CurrLine,CurrCommand,ParamList,TableName:String;
 J:Integer;
 HDBase:DBaseIIIFileHeaderRec; { Structure de l'entete d'un fichier DBase }
 FieldDBase:DBaseIIIFieldRec;  { Structure d'un champ de DBase }
 FieldDBaseList:Array[0..127]of DBaseIIIFieldRec;

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
      Move(CurrWord[1],FieldDBaseList[FieldCount].FieldName,11);
      If StrToUpper(CurrWord2)='BYTE'Then  Begin
       FieldDBaseList[FieldCount].FieldType:='L';
       Inc(HDBase.RecordSize);
      End
       Else
      If StrToUpper(CurrWord2)='TEXT'Then Begin
       FieldDBaseList[FieldCount].FieldType:='C';
       FieldDBaseList[FieldCount].Width:=255;
       Inc(HDBase.RecordSize,255);
      End
       Else
      If StrToUpper(CurrWord2)='INTEGER'Then Begin
       FieldDBaseList[FieldCount].FieldType:='I';
       Inc(HDBase.RecordSize,2);
      End
       Else
      If StrToUpper(CurrWord2)='SMALLINT'Then Begin
       FieldDBaseList[FieldCount].FieldType:='I';
       Inc(HDBase.RecordSize,2);
      End
       Else
      If StrToUpper(CurrWord2)='VARCHAR'Then Begin
       FieldDBaseList[FieldCount].FieldType:='C';
       FieldDBaseList[FieldCount].Width:=255;
       Inc(HDBase.RecordSize,255);
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
  If EOF(SourceSQL)Then Finished:=True;
  ReadLn(SourceSQL,ParamList);
  I:=1;
 Until Finished;
 FieldDBaseList[FieldCount].FieldName[1]:=#13;
 HDBase.HeadType:=$3;
 Seek(TargetDBF,0);
 BlockWrite(TargetDBF,HDBase,SizeOf(HDBase),ByteWrited);
 BlockWrite(TargetDBF,FieldDBaseList,
            SizeOf(DBaseIIIFieldRec)*Succ(FieldCount),ByteWrited);
End;

Procedure DeleteCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure InsertCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
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
  WriteLn('SQL2DBF - Cette commande permet de convertir un fichier SQL en DBF.');
  WriteLn;
  WriteLn('Syntaxe : SQL2DBF source.SQL');
 End
  Else
 Begin
  TableName:='';
  FieldCount:=0;
  FillChar(HDBase,SizeOf(HDBase),0);
  FillChar(FieldDBaseList,SizeOf(FieldDBaseList),0);
  {$I-}Assign(SourceSQL,ParamStr(1));
  Reset(SourceSQL);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible d''ouvrir le fichier ',ParamStr(1));
   Halt;
  End;
  If ParamStr(2)<>''Then TargetName:=ParamStr(2)
                    Else TargetName:=Path2NoExt(ParamStr(1))+'.DBF';
  {$I-}Assign(TargetDBF,TargetName);
  Rewrite(TargetDBF,1);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible d''‚crire le fichier ',TargetName);
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
  Close(TargetDBF);
  Close(SourceSQL);
 End;
END.
