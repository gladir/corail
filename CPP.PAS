{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}


Program CPP(Input,Output);

Type
 StrPointer=^String;

Var
 FileSource,FileTarget:Text;
 P:StrPointer;
 I,J:Integer;
 CurrKey,CurrValue,S:String;
 _Index:Integer;
 K,V:Array[1..1000] of StrPointer;

Procedure PushKey(_Key,_Value:String);
Var
  P:StrPointer;
Type
 StrPointer=^String;
Begin
 Inc(_Index);
 GetMem(P,Length(_Key)+1);
 P^:=_Key;
 K[_Index]:=P;
 GetMem(P,Length(_Value)+1);
 P^:=_Value;
 V[_Index]:=P;
 WriteLn(_Key,'=',_Value,'!!!');
End;

Function FindValue(_Key:String):String;
Var
 I:Integer;
Begin
 FindValue:='';
 If _Index=0Then Exit;
 For I:=1 to _Index do Begin
  If K[I]^=_Key Then Begin
   FindValue:=V[I]^;
   Exit;
  End;
 End;
End;

Function FindKey(_Name:String):String;
Var
 I:Integer;
Begin
 FindKey:='';
 If _Index=0Then Exit;
 For I:=1 to _Index do Begin
  If V[I]^=_Name Then Begin
   FindKey:=K[I]^;
   Exit;
  End;
 End;
End;


BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('CPP : Cette commande permet d''effectuer un traitement preprocesseur du langage de programmation C.');
  WriteLn;
  WriteLn('Syntaxe : CPP source.c target.c');
 End
  Else
 If ParamCount>=1Then Begin
  _Index:=0;
  Assign(FileSource,ParamStr(1));
  Reset(FileSource);
  Assign(FileTarget,ParamStr(2));
  Rewrite(FileTarget);
  While Not EOF(FileSource) do Begin
   I:=1;
   ReadLn(FileSource,S);
   While(I<=Length(S))do Begin
    If Copy(S,I,7)='#define'Then Begin
     J:=I+7;
     CurrKey:='';
     While J<=Length(S)do Begin
      If S[J]in[' ',#9]Then Inc(J)
                       Else Break;
     End;
     While J<=Length(S)do Begin
      If S[J]in['A'..'Z','a'..'z','0'..'9','_']Then Begin
       CurrKey:=CurrKey+S[J];
       Inc(J);
      End
       Else
      Break;
      CurrValue:=Copy(S,J+1,255);
     End;
     PushKey(CurrKey,CurrValue);
     I:=Length(S)+1;
     Break;
    End
     Else
    If S[I]in['A'..'Z','a'..'z','_']Then Begin
     J:=I+1;
     CurrKey:=S[I];
     While J<=Length(S)do Begin
      If S[J]in['A'..'Z','a'..'z','0'..'9','_']Then Begin
       CurrKey:=CurrKey+S[J];
       Inc(J);
      End
       Else
      Break;
     End;
     CurrValue:=FindValue(CurrKey);
     If CurrValue<>''Then Write(FileTarget,CurrValue)
                     Else Write(FileTarget,CurrKey);
     I:=J;
    End
     Else
    Begin
     Write(FileTarget,S[I]);
     Inc(I);
    End;
   End;
   WriteLn(FileTarget);
  End;
  Close(FileTarget);
  Close(FileSource);
 End;
END.
