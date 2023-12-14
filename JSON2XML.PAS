{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program JSON2XML;

Uses DOS;

Var
 Mode:(Key,Value);
 DirectValue,InString:Boolean;
 SourceJSON,TargetXML:Text;
 Spacing:Word;
 C:Char;
 CurrWord,FileName,TFileName:String;
 Ident:Integer;
 FieldName:Array[0..49]of String[100];
 GroupValue:Array[0..49]of Boolean;

Function LTrim(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If S[I]<>' 'Then Begin
   LTrim:=Copy(S,I,255);
   Exit;
  End;
 End;
 LTrim:=S;
End;

Function RTrim(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 RTrim:=S;
End;

Function Trim(s:String):String;Begin
 Trim:=LTrim(RTrim(s));
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

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('JSON2XML : Cette commande permet de convertir un fichier JSON en ',
                    'format XML.');
  WriteLn;
  WriteLn('Syntaxe : JSON2XML source.JSON [target.XML]');
  WriteLn;
  WriteLn(' source.JSON  Nom du fichier a convertir');
  WriteLn(' target.XML   Nom du fichier du resultat');
  WriteLn;
 End
  Else
 Begin
  FileName:=FExpand(ParamStr(1));
  If Path2Ext(FileName)=''Then FileName:=FileName+'.JSON';
  Assign(SourceJSON,FileName);
  {$I-}Reset(SourceJSON);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier JSON introuvable !');
   Halt;
  End;
  Spacing:=2;
  InString:=False;
  Ident:=0;
  CurrWord:='';
  Mode:=Key;
  FillChar(FieldName,SizeOf(FieldName),0);
  FillChar(GroupValue,SizeOf(GroupValue),0);
  If ParamStr(2)=''Then Begin
   WriteLn('<?xml version="1.0" encoding="UTF-8"?>');
   While Not EOF(SourceJSON)do Begin
    Read(SourceJSON,C);
    If(InString)Then Begin
     If C='"'Then InString:=False
             Else CurrWord:=CurrWord+C;
    End
     Else
    If Not(C in[#0,#13,#10])Then Begin
     Case C of
      '"':Begin
       InString:=True;
       DirectValue:=False;
      End;
      '{':Begin
       If(Mode=Value)Then Begin
        WriteLn;
       End;
       If CurrWord=''Then GroupValue[Ident]:=True;
       Inc(Ident);
      End;
      '}':Begin
       If(Mode=Value)Then Begin
        If(DirectValue)Then Write(Trim(CurrWord))
                       Else Write(CurrWord);
        Mode:=Key;
       End;
       If Not(GroupValue[Ident])Then WriteLn('</',FieldName[Ident],'>');
       If Ident>0Then Begin
        Dec(Ident);
        If GroupValue[Ident]Then Begin
         If Ident<>0 Then Begin
          If Ident>1 Then Write(' ':Pred(Ident)*Spacing);
          WriteLn('</',FieldName[Ident],'>');
         End;
        End;
       End;
       Mode:=Key;
      End;
      ':':Begin
       FieldName[Ident]:=Trim(CurrWord);
       If Ident>1 Then Write(' ':Pred(Ident)*Spacing);
       Write('<',FieldName[Ident],'>');
       CurrWord:='';
       DirectValue:=True;
       Mode:=Value;
       GroupValue[Ident]:=False;
      End;
      ',':Begin
       If(Mode=Value)Then Begin
        If(DirectValue)Then Write(Trim(CurrWord))
                       Else Write(CurrWord);
        WriteLn('</',FieldName[Ident],'>');
        Mode:=Key;
       End;
       CurrWord:='';
       Mode:=Key;
      End;
      Else CurrWord:=CurrWord+C;
     End;
    End;
   End;
  End
   Else
  Begin
   TFileName:=FExpand(ParamStr(2));
   If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.XML';
   Assign(TargetXML,TFileName);
   {$I-}Rewrite(TargetXML); {$I+}
   If IoResult<>0Then Begin
    WriteLn('Impossible de cr‚er le fichier XML ',TFileName,' !');
    Close(SourceJSON);
    Halt;
   End;
   WriteLn(TargetXML,'<?xml version="1.0" encoding="UTF-8"?>');
   While Not EOF(SourceJSON)do Begin
    Read(SourceJSON,C);
    If(InString)Then Begin
     If C='"'Then InString:=False
             Else CurrWord:=CurrWord+C;
    End
     Else
    If Not(C in[#0,#13,#10])Then Begin
     Case C of
      '"':Begin
       InString:=True;
       DirectValue:=False;
      End;
      '{':Begin
       If(Mode=Value)Then Begin
        WriteLn(TargetXML);
       End;
       If CurrWord=''Then GroupValue[Ident]:=True;
       Inc(Ident);
      End;
      '}':Begin
       If(Mode=Value)Then Begin
        If(DirectValue)Then Write(TargetXML,Trim(CurrWord))
                       Else Write(TargetXML,CurrWord);
        Mode:=Key;
       End;
       If Not(GroupValue[Ident])Then WriteLn(TargetXML,'</',FieldName[Ident],'>');
       If Ident>0Then Begin
        Dec(Ident);
        If GroupValue[Ident]Then Begin
         If Ident<>0 Then Begin
          If Ident>1 Then Write(TargetXML,' ':Pred(Ident)*Spacing);
          WriteLn(TargetXML,'</',FieldName[Ident],'>');
         End;
        End;
       End;
       Mode:=Key;
      End;
      ':':Begin
       FieldName[Ident]:=Trim(CurrWord);
       If Ident>1 Then Write(TargetXML,' ':Pred(Ident)*Spacing);
       Write(TargetXML,'<',FieldName[Ident],'>');
       CurrWord:='';
       DirectValue:=True;
       Mode:=Value;
       GroupValue[Ident]:=False;
      End;
      ',':Begin
       If(Mode=Value)Then Begin
        If(DirectValue)Then Write(TargetXML,Trim(CurrWord))
                       Else Write(TargetXML,CurrWord);
        WriteLn(TargetXML,'</',FieldName[Ident],'>');
        Mode:=Key;
       End;
       CurrWord:='';
       Mode:=Key;
      End;
      Else CurrWord:=CurrWord+C;
     End;
    End;
   End;
   Close(TargetXML);
  End;
  Close(SourceJSON);
 End;
END.