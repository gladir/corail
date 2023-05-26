{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program SASS;

Const
 MaxVariable=500;

Type
 StrPointer=^String;

Var
 SourceScss,TargetCSS:Text;
 CurrLine:String;
 NumberVariable:Word;
 VariableName:Array[1..MaxVariable]of StrPointer;
 VariableValue:Array[1..MaxVariable]of StrPointer;

Function AddVariable(S,Value:String):Boolean;
Var
 I:Word;
 P:StrPointer;
Begin
 If NumberVariable>=MaxVariable Then Begin
  WriteLn('Trop de variable !');
  AddVariable:=False;
  Exit;
 End
  Else
 Begin
  Inc(NumberVariable);
  GetMem(P,Length(S)+1);
  P^:=S;
  VariableName[NumberVariable]:=P;
  GetMem(P,Length(Value)+1);
  P^:=Value;
  VariableValue[NumberVariable]:=P;
  AddVariable:=True;
 End;
End;

Function FindVariable(Variable:String):Integer;
Var
 I:Integer;
Begin
 FindVariable:=-1;
 For I:=1 to MaxVariable do Begin
  If VariableName[I]^=Variable Then Begin
   FindVariable:=I;
   Exit;
  End;
 End;
End;

Function GetValue(Pos:Integer):String;Begin
 GetValue:=VariableValue[Pos]^;
End;

Function ParseLine(CurrLine:String):String;
Var
 I,P:Integer;
 TargetLine,CurrWord,CurrValue:String;
Begin
 ParseLine:='';
 TargetLine:='';
 I:=1;
 While(I<=Length(CurrLine))do Begin
  If CurrLine[I]='$'Then Begin
   Inc(I);
   CurrWord:='';
   While(CurrLine[I] in['a'..'z','A'..'Z','-','0'..'9'])do Begin
    CurrWord:=CurrWord+CurrLine[I];
    Inc(I);
    If I>Length(CurrLine)Then Break;
   End;
   If I>Length(CurrLine)Then Begin
    P:=FindVariable(CurrWord);
    If P>0Then Begin
     TargetLine:=TargetLine+GetValue(P);
     Break;
    End;
   End;
   While(CurrLine[I]in[' '])and(I<Length(CurrLine))do Inc(I);
   If(CurrLine[I]=':')and(I<=Length(CurrLine))Then Begin
    CurrValue:='';
    While(CurrLine[I]<>';')do Begin
     CurrValue:=CurrValue+CurrLine[I];
     Inc(I);
     If I>Length(CurrLine)Then Break;
    End;
    AddVariable(CurrWord,CurrValue);
    If CurrLine[I]=';'Then Inc(I);
   End
    Else
   Begin
    P:=FindVariable(CurrWord);
    If P>0Then Begin
     TargetLine:=TargetLine+GetValue(P);
     Break;
    End;
   End;
  End
   Else
  Begin
   TargetLine:=TargetLine+CurrLine[I];
   Inc(I);
  End;
 End;
 ParseLine:=TargetLine;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('SASS : Cette commande permet de lancer le compilateur SASS.');
  WriteLn;
  WriteLn('Syntaxe : SASS nomdufichier.scss nomdufichier.css');
 End
  Else
 If ParamCount>0Then Begin
  FillChar(VariableName,SizeOf(VariableName),0);
  FillChar(VariableValue,SizeOf(VariableValue),0);
  NumberVariable:=0;
  Assign(SourceScss,ParamStr(1));
  {$I-}Reset(SourceScss);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier SCSS/SASS introuvable !');
   Halt;
  End;
  Assign(TargetCSS,ParamStr(2));
  {$I+}Rewrite(TargetCSS); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier CSS !');
   Close(SourceScss);
   Halt;
  End;
  While Not EOF(SourceScss)do Begin
   ReadLn(SourceScss,CurrLine);
   WriteLn(TargetCSS,ParseLine(CurrLine));
  End;
  Close(TargetCSS);
  Close(SourceScss);
 End
  Else
 WriteLn('ParamŠtre requis');
END.