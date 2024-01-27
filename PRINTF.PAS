{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program PRINTF;

Var
 CurrParam:Integer;

Function PadZeroLeft(Value:String;Space:Byte):String;
Var
 S:String;
Begin
 S:=Value;
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

Function FormatString(S:String):String;
Var
 I,PadLeft:Integer;
 Err:Word;
 R,T:String;
 ValueStr:String;
Begin
 R:='';
 I:=1;
 While I<=Length(S)do Begin
  If S[I]='\'Then Begin
   Inc(I);
   If I>Length(S)Then Break;
   Case S[I]of
    '0':R:=R+#0;
    'a':R:=R+#7;
    'b':R:=R+#8;
    'f':R:=R+#12;
    'n':R:=R+#10;
    'r':R:=R+#13;
    't':R:=R+#9;
    'v':R:=R+#11;
    '\':R:=R+'\';
    '''':R:=R+'''';
    '"':R:=R+'"';
    '?':R:=R+'?';
   End;
  End
   Else
  If S[I]='%'Then Begin
   Inc(I);
   If I>Length(S)Then Break;
   Case S[I]of
    'c':Begin
     ValueStr:=ParamStr(CurrParam);
     Inc(CurrParam);
     If Length(ValueStr)>0 Then R:=R+ValueStr[1];
    End;
    'd','f','g','i','l':Begin
     T:=ParamStr(CurrParam);
     Inc(CurrParam);
     R:=R+T;
    End;
    '0'..'9':Begin
     T:='';
     While(S[I]in['0'..'9'])and(I<=Length(S))do Begin
      T:=T+S[I];
      Inc(I);
     End;
     Val(T,PadLeft,Err);
     R:=R+PadZeroLeft(ParamStr(CurrParam),PadLeft);
     Inc(CurrParam);
    End;
   End;
  End
   Else
  R:=R+S[I];
  Inc(I);
 End;
 FormatString:=R;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('PRINTF : Cette commande permet d''afficher un message avec ',
                    'le format sp‚cifi‚.');
  WriteLn;
  WriteLn('Syntaxe : PRINTF format [arguments]');
  WriteLn;
  WriteLn(' format      Indique la chaine de caractŠres de format');
  WriteLn(' arguments   Indique les diff‚rentes valeurs');
  WriteLn;
 End
  Else
 If ParamCount>0Then Begin
  CurrParam:=2;
  Write(FormatString(ParamStr(1)));
 End;
END.
