{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program JO;

Var
 DisableBooleanDetect,CreateArray,Pretty,First,DataParam:Boolean;
 I:Integer;
 CurrLine,Key,Value:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Procedure DataToKeyValue(Line:String;Var Key,Value:String);
Var
 P:Integer;
Begin
 P:=Pos('=',Line);
 If P>0 Then Begin
  Key:=Copy(Line,1,P-1);
  Value:=Copy(Line,P+1,255);
 End
  Else
 Begin
  Key:=Line;
  Value:='false';
 End;
End;

Function IsNumber(S:String):Boolean;
Var
 I:Integer;
Begin
 IsNumber:=True;
 For I:=1 to Length(S)do Begin
  If Not(S[I]in['0'..'9','.'])Then Begin
   IsNumber:=False;
   Exit;
  End;
 End;
End;


Function IsQuotedData(Value:String):Boolean;Begin
 IsQuotedData:=True;
 If Value=''Then Exit;
 If IsNumber(Value)Then IsQuotedData:=False
  Else
 If Not(DisableBooleanDetect)Then Begin
  If StrToUpper(Value)='NULL'Then IsQuotedData:=False Else
  If StrToUpper(Value)='FALSE'Then IsQuotedData:=False Else
  If StrToUpper(Value)='TRUE'Then IsQuotedData:=False;
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('JO : Cette commande permet de cr‚er des objets JSON.');
  WriteLn;
  WriteLn('Syntaxe : JO [options] [data]');
  WriteLn;
  WriteLn(' -a   Permet de cr‚er un tableau de mots.');
  WriteLn(' -B   D‚sactive la d‚tection bool‚enne true, false ou null');
  WriteLn(' -p   Permet d''effectuer un joli affichage JSON vers la sortie');
  WriteLn;
 End
  Else
 Begin
  Pretty:=False;
  CreateArray:=False;
  DisableBooleanDetect:=False;
  DataParam:=False;
  If ParamCount>0Then For I:=1 to ParamCount do Begin
   If ParamStr(I)='-a'Then CreateArray:=True Else
   If ParamStr(I)='-B'Then DisableBooleanDetect:=True Else
   If ParamStr(I)='-p'Then Pretty:=True
                      Else DataParam:=True;
  End;
  If(DataParam)Then Begin
   If(CreateArray)Then Begin
    First:=True;
    Write('[');
    If(Pretty)Then Begin
     WriteLn;
     Write(' ');
    End;
    For I:=1 to ParamCount do Begin
     If(ParamStr(I)='-a')or(ParamStr(I)='-p')or(ParamStr(I)='-B')Then Begin
      { Fait rien ...}
     End
      Else
     Begin
      If(First)Then First:=False
       Else
      Begin
       Write(',');
       If(Pretty)Then Begin
        WriteLn;
        Write(' ');
       End;
      End;
      Write(ParamStr(I));
     End;
    End;
    If(Pretty)Then WriteLn;
    WriteLn(']');
   End
    Else
   Begin
    First:=True;
    Write('{');
    If(Pretty)Then Begin
     WriteLn;
     Write(' ');
    End;
    For I:=1 to ParamCount do Begin
     If(ParamStr(I)='-a')or(ParamStr(I)='-p')or(ParamStr(I)='-B')Then Begin
      { Fait rien ...}
     End
      Else
     Begin
      If(First)Then First:=False
       Else
      Begin
       Write(',');
       If(Pretty)Then Begin
        WriteLn;
        Write(' ');
       End;
      End;
      DataToKeyValue(ParamStr(I),Key,Value);
      Write('"',Key,'":');
      If IsQuotedData(Value)Then Write('"',Value,'"')
                            Else Write(Value);
     End;
    End;
    If(Pretty)Then WriteLn;
    WriteLn('}');
   End;
  End
   Else
  Begin
   If(CreateArray)Then Begin
    First:=True;
    Write('[');
    If(Pretty)Then Begin
     WriteLn;
     Write(' ');
    End;
    While Not EOF do Begin
     If(First)Then First:=False
      Else
     Begin
      Write(',');
      If(Pretty)Then Begin
       WriteLn;
       Write(' ');
      End;
     End;
     ReadLn(CurrLine);
     Write(CurrLine);
    End;
    If(Pretty)Then WriteLn;
    WriteLn(']');
   End
    Else
   Begin
    First:=True;
    Write('{');
    If(Pretty)Then Begin
     WriteLn;
     Write(' ');
    End;
    While Not EOF do Begin
     If(First)Then First:=False
      Else
     Begin
      Write(',');
      If(Pretty)Then Begin
       WriteLn;
       Write(' ');
      End;
     End;
     ReadLn(CurrLine);
     DataToKeyValue(CurrLine,Key,Value);
     Write('"',Key,'":');
     If IsQuotedData(Value)Then Write('"',Value,'"')
                           Else Write(Value);
    End;
    If(Pretty)Then WriteLn;
    WriteLn('}');
   End;
  End;
 End;
END.