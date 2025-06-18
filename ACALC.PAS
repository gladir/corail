{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program ACALC;

Uses Crt, Dos;

Type
 TokenType=(Number, _Operator, _Function, OpenParen, CloseParen, Separator);
 TokenRec=Record
  Case Kind: TokenType of
   Number: (Value: Real);
   _Operator,
   _Function: (Symbol: string);
 End;

Const
  MaxStack = 100;

Var
 CurrParam,Expression:String;
 Position:Integer;
 OutputFormat:Char;
 I:Integer;
 R:Real;
 ErrorCode:Integer;

Function CalcFunction(FuncName:String;x,y:Real):Real;Forward;
Procedure ParseToken(var Result: TokenRec);Forward;

Function StrToLower(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
 End;
 StrToLower:=S;
End;

Function IsDigit(c:Char):Boolean;Begin
 IsDigit := c in ['0'..'9'];
End;

Function IsLetter(c:Char):Boolean;Begin
 IsLetter := c in ['A'..'Z', 'a'..'z'];
End;

Function IsSpace(c:Char):Boolean;Begin
 IsSpace := c in [' ', #9];
End;

Function GetNumber:Real;
Var
 Base:Integer;
 Value:Real;
 IsHex:Boolean;
Begin
 Value:=0;
 Base:=10;
 IsHex:=False;
 If Position<=Length(Expression)Then Begin
  If StrToLower(Expression[Position])='b'Then Begin
   Base:=2;
   Inc(Position);
  End
   Else
  If StrToLower(Expression[Position])='o'Then Begin
   Base:=8;
   Inc(Position);
  End
   Else
  If StrToLower(Expression[Position])='x'Then Begin
   Base:=16;
   IsHex:=True;
   Inc(Position)
  End;
 End;
 While (Position <= Length(Expression)) do Begin
  Case UpCase(Expression[Position]) of
   '0'..'9': Value:=Value*Base+(Ord(Expression[Position])-Ord('0'));
   'A'..'F': If(IsHex)Then
              Value:=Value*Base+(Ord(UpCase(Expression[Position]))-Ord('A')+10)
             Else
              Break;
   Else Break;
  End;
  Inc(Position);
 End;
 GetNumber:=Value;
End;

Function GetPriority(Op:String):Integer;Begin
 Case Op[1] of
  '(': GetPriority:=0;
  '+', '-': GetPriority:=1;
  '*', '/', '%': GetPriority:=2;
  '&', ':', '^': GetPriority:=3;
  '{', '}': GetPriority:=4;
  Else GetPriority:=0;
 End;
End;

Procedure ParseToken(var Result: TokenRec);
Var
 s:String;
Begin
 While(Position<=Length(Expression))and IsSpace(Expression[Position]) do Inc(Position);
 If Position>Length(Expression)Then Begin
  Result.Kind:=_Operator;
  Result.Symbol:='';
  Exit;
 End;
 Case Expression[Position] of
  '0'..'9':Begin
   Result.Kind:=Number;
   Result.Value:=GetNumber;
  End;
  '+','-','*','/','%','&',':','^','{','}':Begin
   Result.Kind:=_Operator;
   Result.Symbol:=Expression[Position];
   Inc(Position);
  End;
  '(':Begin
   Result.Kind:=OpenParen;
   Result.Symbol:='(';
   Inc(Position);
  End;
  ')':Begin
   Result.Kind:=CloseParen;
   Result.Symbol:=')';
   Inc(Position);
  End;
  ';':Begin
   Result.Kind:=Separator;
   Result.Symbol:=';';
   Inc(Position);
  End;
  'A'..'Z', 'a'..'z':Begin
   s:='';
   While (Position <= Length(Expression)) and 
         (IsLetter(Expression[Position]) or IsDigit(Expression[Position])) do Begin
    s:=s+UpCase(Expression[Position]);
    Inc(Position);
   End;
   Result.Kind:=_Function;
   Result.Symbol:=s;
  End;
   Else
  Begin
   ErrorCode:=1; { Expression invalide }
   Result.Kind:=_Operator;
   Result.Symbol:='';
  End;
 End;
End;

Function CalcFunction(FuncName:String;x,y:Real):Real;Begin
 If FuncName='ABS'Then CalcFunction:=Abs(x) Else
 If FuncName='SQRT'Then Begin
  If x>=0 Then CalcFunction:=Sqrt(x)
          Else ErrorCode:=2;
 End
  Else
 If FuncName='SIN'Then CalcFunction:=Sin(x) Else
 If FuncName='COS'Then CalcFunction:=Cos(x) Else
 If FuncName='TAN'Then CalcFunction:=Sin(x)/Cos(x) Else
 If FuncName='MAX'Then CalcFunction:=x Else
 If FuncName='MIN'Then CalcFunction:=x Else
 If FuncName='PI'Then CalcFunction:=3.14159265359
  Else
 Begin
  ErrorCode:=3; { Fonction inconnu }
  CalcFunction:=0;
 End;
End;

Function Evaluate:Real;
Var
 ValueStack:Array[1..MaxStack] of Real;
 OperStack:Array[1..MaxStack] of TokenRec;
 ValTop,OpTop:Integer;
 CurrentToken: TokenRec;
 FuncToken: TokenRec;
 NeedCloseParen: Boolean;
Begin
 ValTop:=0;
 OpTop:=0;
 ErrorCode:=0;
 Position:=1;
 NeedCloseParen := False;
 While ErrorCode = 0 do Begin
  ParseToken(CurrentToken);
  Case CurrentToken.Kind of
   Number:Begin
    Inc(ValTop);
    ValueStack[ValTop]:=CurrentToken.Value;
   End;
   _Operator:Begin
    If CurrentToken.Symbol=''Then Break;  { Fin de l'expression }
     { Traitement des op�rateurs avec le pr�c�dent haut ou �gale }
    While(OpTop>0)and(GetPriority(OperStack[OpTop].Symbol) >= GetPriority(CurrentToken.Symbol)) do Begin
     If ValTop<2 Then Begin
      ErrorCode := 1;  { Plus d'espace pour les op�randes }
      Break;
     End;
     Case OperStack[OpTop].Symbol[1] of
      '+':ValueStack[ValTop-1]:=ValueStack[ValTop-1]+ValueStack[ValTop];
      '-':ValueStack[ValTop-1]:=ValueStack[ValTop-1]-ValueStack[ValTop];
      '*':ValueStack[ValTop-1]:=ValueStack[ValTop-1]*ValueStack[ValTop];
      '/':If ValueStack[ValTop]<>0 Then
           ValueStack[ValTop-1] := ValueStack[ValTop-1] / ValueStack[ValTop]
          Else
           ErrorCode:=2;  { Division par z�ro }
      '%':If ValueStack[ValTop]<>0 Then
           ValueStack[ValTop-1] := Trunc(ValueStack[ValTop-1]) mod Trunc(ValueStack[ValTop])
          Else
           ErrorCode := 2;
      '&': ValueStack[ValTop-1] := Trunc(ValueStack[ValTop-1]) and Trunc(ValueStack[ValTop]);
      ':': ValueStack[ValTop-1] := Trunc(ValueStack[ValTop-1]) or Trunc(ValueStack[ValTop]);
      '^': ValueStack[ValTop-1] := Trunc(ValueStack[ValTop-1]) xor Trunc(ValueStack[ValTop]);
      '{': ValueStack[ValTop-1] := Trunc(ValueStack[ValTop-1]) shl Trunc(ValueStack[ValTop]);
      '}': ValueStack[ValTop-1] := Trunc(ValueStack[ValTop-1]) shr Trunc(ValueStack[ValTop]);
     End;
     Dec(ValTop);
     Dec(OpTop);
    End;
    Inc(OpTop);
    OperStack[OpTop]:=CurrentToken;
   End;
   _Function:Begin
    FuncToken := CurrentToken;
    ParseToken(CurrentToken);
    If CurrentToken.Kind<>OpenParen Then Begin
     ErrorCode := 1;
     Break;
    End;
    
    { Evaluate function argument }
    Position := Position;  { Save position }
    ParseToken(CurrentToken);
    If CurrentToken.Kind=Number Then Begin
     Inc(ValTop);
     ValueStack[ValTop]:=CalcFunction(FuncToken.Symbol,CurrentToken.Value,0);
    End
    Else
    Begin
     ErrorCode := 1;
     Break;
    End;
    
    ParseToken(CurrentToken);
    If CurrentToken.Kind<>CloseParen Then Begin
     ErrorCode := 1;
     Break;
    End;
   End;
   OpenParen:Begin
    Inc(OpTop);
    OperStack[OpTop] := CurrentToken;
   End;
   CloseParen:Begin
    While (OpTop>0)and(OperStack[OpTop].Kind <> OpenParen) do Begin
     If ValTop<2 Then Begin
      ErrorCode:=1;
      Break;
     End;
     Case OperStack[OpTop].Symbol[1] of
      '+': ValueStack[ValTop-1]:=ValueStack[ValTop-1] + ValueStack[ValTop];
      '-': ValueStack[ValTop-1]:=ValueStack[ValTop-1] - ValueStack[ValTop];
      '*': ValueStack[ValTop-1]:=ValueStack[ValTop-1] * ValueStack[ValTop];
      '/': If ValueStack[ValTop] <> 0 then
            ValueStack[ValTop-1]:=ValueStack[ValTop-1] / ValueStack[ValTop]
           Else
            ErrorCode:=2;
     End;
     Dec(ValTop);
     Dec(OpTop);
    End;
    If OpTop > 0 Then
     Dec(OpTop)  { Enl�ve les parenthRemove opening parenthesis }
    Else
     ErrorCode := 6;  { Non correspondance des parenth�ses }
   End;
  End;
 End;
  { Traitement des op�rateurs }
 While (OpTop > 0) and (ErrorCode = 0) do Begin
  If ValTop<2 Then Begin
   ErrorCode := 1;
   Break;
  End;
  Case OperStack[OpTop].Symbol[1] of
   '+': ValueStack[ValTop-1] := ValueStack[ValTop-1] + ValueStack[ValTop];
   '-': ValueStack[ValTop-1] := ValueStack[ValTop-1] - ValueStack[ValTop];
   '*': ValueStack[ValTop-1] := ValueStack[ValTop-1] * ValueStack[ValTop];
   '/': If ValueStack[ValTop] <> 0 Then
         ValueStack[ValTop-1] := ValueStack[ValTop-1] / ValueStack[ValTop]
        Else
         ErrorCode:=2;
  End;
  Dec(ValTop);
  Dec(OpTop);
 End;
 If(ErrorCode=0)and(ValTop=1)Then Evaluate:=ValueStack[1]
  Else
 Begin
  ErrorCode := 1;
   Evaluate := 0;
 End;
End;

Procedure DisplayResult(Value:Real);Begin
 Case UpCase(OutputFormat) of
  'B':WriteLn(Value:0:0, 'B');
  'O':WriteLn(Value:0:0, 'O');
  'X':WriteLn(Value:0:0, 'H');
  'A':Begin
   WriteLn(Value:0:0, 'D');
   WriteLn(Value:0:0, 'B');
   WriteLn(Value:0:0, 'O');
   WriteLn(Value:0:0, 'H');
  End;
  Else WriteLn(Value:0:0);
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('ACALC - Cette commande permet de lancer la calculatrice arithmetique');
  WriteLn;
  WriteLn('Syntaxe: ACALC [/t[:format]]expression [/?]');
  WriteLn;
  WriteLn('  /t[:format]  Format de sortie (D,B,O,X,A)');
  WriteLn('  expression   Expression mathematique');
  WriteLn('  /?           Affiche cette aide');
  Halt;
 End;
 OutputFormat := 'D';
 Expression := '';
 Position := 1;
 ErrorCode := 0;
  { Analyse la ligne de commande }
 For i:=1 to ParamCount do Begin
  CurrParam:=ParamStr(i);
  If(CurrParam[1]='/')and(UpCase(CurrParam[2])='T')Then Begin
   If Length(CurrParam)>=4 Then OutputFormat:=UpCase(CurrParam[4]);
  End
   Else
  Expression:=Expression+CurrParam;
 End;
 R:=Evaluate;
 If ErrorCode <> 0 Then Begin
  Case ErrorCode of
   1: WriteLn('Erreur: Expression invalide');
   2: WriteLn('Erreur: Division par zero');
   3: WriteLn('Erreur: Fonction non reconnue');
   4: WriteLn('Erreur: Parentheses non equilibrees');
   Else WriteLn('Erreur inconnue');
  End;
  Halt(1);
 End
  Else
 DisplayResult(R);
END.