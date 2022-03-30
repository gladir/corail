{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program DISPLAY;

Var
 P:Byte;
 W:Word;
 Msg,CurrParam:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function GetHex(Source:String;Var H:Word):Boolean;
Var
 I:Byte;
 Digit:Word;
Begin
 H:=0;
 GetHex:=False;
 Source:=StrToUpper(Source);
 For I:=1 to Length(Source) do If(Source[I] in ['A'..'F', '0'..'9'])Then Begin
  GetHex:=True;
  If(Source[I]>='A')Then Digit:=Ord(Source[I])-Ord('A')+10
                    Else Digit:=Ord(Source[I])-Ord('0');
  H:=(H Shl 4)+Digit;
 End;
End;

BEGIN
 P:=0;
 Msg:='';
 Repeat
  Inc(P);
  CurrParam:=ParamStr(P);
  If Length(CurrParam)=0Then Break;
  If CurrParam='/?'Then Begin
   WriteLn('DISPLAY   Cette commande permet d''afficher un message encodee en hexadecimal.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('DISPLAY [/?] hex [...]');
   WriteLn;
   WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn(' hex  Ce parametre permet d''indiquer des nombres hexadecimal de 2 chiffres');
   Exit;
  End
   Else
  Begin
   If GetHex(ParamStr(P),W)Then Msg:=Msg+Chr(Lo(W));
  End;
  If P>255Then Break;
 Until CurrParam='';
 If Msg<>''Then WriteLn(Msg);
END.