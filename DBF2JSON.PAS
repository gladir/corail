{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program DBF2JSON;

{$A-}

Uses DOS,Strings;

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
 SourceDBF:File;
 TargetSQL:Text;
 ByteReaded:Word;
 HDBase:DBaseIIIFileHeaderRec; { Structure de l'entete d'un fichier DBase }
 FieldDBase:DBaseIIIFieldRec;  { Structure d'un champ de DBase }
 BufOfs,FieldSize,K:Integer;
 I,J,FP,NumField:LongInt;
 FieldDBaseList:Array[0..127]of DBaseIIIFieldRec;
 Buffer:Array[0..16384]of Byte;
 FileName,TableName,TStr:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('DBF2JSON - Cette commande permet de convertir un fichier DBF en format JSON');
  WriteLn;
  WriteLn('Syntaxe : DBF2JSON source.DBF');
 End
  Else
 Begin
  TableName:=Path2Name(ParamStr(1));
  FileName:=FExpand(ParamStr(1));
  If Path2Ext(FileName)=''Then FileName:=FileName+'.DBF';
  FillChar(FieldDBaseList,SizeOf(FieldDBaseList),0);
  {$I-}Assign(SourceDBF,FileName);
  Reset(SourceDBF,1);{$I+}
  If IoResult<>0 Then Begin
   WriteLn('Fichier ',FileName,' introuvable !');
   Halt;
  End;
  FillChar(HDBase,SizeOf(HDBase),0);
  BlockRead(SourceDBF,HDBase,SizeOf(HDBase),ByteReaded);
  If HDBase.HeadType=$3Then Begin { Fichier DBase III+ ? }
   FP:=SizeOf(DBaseIIIFileHeaderRec);
   NumField:=0;
   WriteLn('{');
   Repeat
    Seek(SourceDBF,FP);
    FillChar(FieldDBase,SizeOf(FieldDBase),0);
    BlockRead(SourceDBF,FieldDBase,SizeOf(FieldDBase),ByteReaded);
    FieldDBaseList[NumField]:=FieldDBase;
    Inc(FP,SizeOf(FieldDBase));
    If FieldDBase.FieldName[1]=#13 Then Break;
    Inc(NumField);
    If(FP>FileSize(SourceDBF))Then Break;
   Until FieldDBase.FieldName[1]=#13;
   If NumField<1 Then Begin
    WriteLn('Aucun champ present !');
    Halt;
   End;
   If HDBase.RecordSize>SizeOf(Buffer)Then Begin
    WriteLn('Enregistrement trop grand !');
    Halt;
   End;
   If HDBase.HeaderLength=0Then Seek(SourceDBF,FP-SizeOf(FieldDBase)+2)
                           Else Seek(SourceDBF,HDBase.HeaderLength+1);
   If HDBase.RecordCount>0 Then Begin
    WriteLn(' ':4,'"',TableName,'":{');
   End;
   For J:=1 to HDBase.RecordCount do Begin
    BlockRead(SourceDBF,Buffer,HDBase.RecordSize,ByteReaded);
    BufOfs:=0;
    WriteLn(' ':8,'"line":{');
    For I:=0 To NumField-1 do Begin
     Write(' ':12,'"',Trim(StrPas(@FieldDBaseList[I].FieldName)),'":');
     Case FieldDBaseList[I].FieldType of
      'C','N':FieldSize:=FieldDBaseList[I].Width;
      'I':FieldSize:=2;
      'L':FieldSize:=1;
      Else FieldSize:=0;
     End;
     Case FieldDBaseList[I].FieldType of
      'C':Begin
       Write('"');
       TStr:='';
       For K:=0 to FieldDBaseList[I].Width-1 do Begin
        If Buffer[BufOfs+K]=0 Then Break;
        TStr:=TStr+Char(Buffer[BufOfs+K]);
       End;
       Write(TrimR(TStr));
       Write('"');
      End;
      'N':Begin
       TStr:='';
       For K:=0 to FieldDBaseList[I].Width-1 do Begin
        If Buffer[BufOfs+K]=0 Then Break;
        TStr:=TStr+Char(Buffer[BufOfs+K]);
       End;
       If Trim(TStr)=''Then Write('0')
                       Else Write(Trim(TStr));
      End;
      'I':Write(Buffer[BufOfs]+Buffer[BufOfs+1]*256);
      'L':Write(Buffer[BufOfs]);
     End;
     If I<NumField-1 Then Write(',');
     WriteLn;
     Inc(BufOfs,FieldSize);
    End;
    Write(' ':8,'}');
    If J<HDBase.RecordCount Then Write(',');
    WriteLn;
   End;
   If HDBase.RecordCount>0 Then Begin
    WriteLn(' ':4,'}');
   End;
   WriteLn('}');
  End;
  Close(SourceDBF);
 End;
END.

