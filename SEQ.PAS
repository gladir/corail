{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program SEQ;

Var
 EqualWidth:Boolean;
 ModeParam:(_None,_Format,_Separator);
 Value:Array[0..2]of LongInt;
 First,Last,Step:LongInt;
 I,PosValue:Integer;
 Err:Word;
 Format,Separator,LastS:String;

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

Function FormatString(S:String;Value:LongInt):String;
Var
 I,PadLeft:Integer;
 Err:Word;
 R,T:String;
Begin
 R:='';
 I:=1;
 While I<=Length(S)do Begin
  If S[I]='%'Then Begin
   Inc(I);
   If I>Length(S)Then Break;
   Case S[I]of
    'c':R:=R+Char(Value);
    'd','f','g','i','l':Begin
     Str(Value,T);
     R:=R+T;
    End;
    '0'..'9':Begin
     T:='';
     While(S[I]in['0'..'9'])and(I<=Length(S))do Begin
      T:=T+S[I];
      Inc(I);
     End;
     Val(T,PadLeft,Err);
     R:=R+PadZeroLeft(Value,PadLeft);
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
  WriteLn('SEQ : Cette commande permet de g‚n‚rer des nombres selon ',
                'l''intervalle et le saut sp‚cifi‚.');
  WriteLn;
  WriteLn('Syntaxe : SEQ [options] last');
  WriteLn('          SEQ [options] first last');
  WriteLn('          SEQ [options] first incremental last');
  WriteLn;
  WriteLn(' first       Indique le d‚but de la boucle');
  WriteLn(' last        Indique la fin de la boucle');
  WriteLn(' incremental Indique le saut de la boucle');
  WriteLn(' -f format   Indique un format de formatage');
  WriteLn(' -s chaine   Indique le s‚parateur de valeur');
  WriteLn(' -w          Indique qu''il faut ‚galiser la largeur des nombres');
  WriteLn;
 End
  Else
 If ParamCount>0Then Begin
  EqualWidth:=False;
  Separator:='';
  ModeParam:=_None;
  Format:='';
  PosValue:=0;
  First:=1;
  Last:=0;
  Step:=1;
  FillChar(Value,SizeOf(Value),0);
  For I:=1 to ParamCount do Begin
   Case ModeParam of
    _Format:Begin
     ModeParam:=_None;
     Format:=ParamStr(I);
    End;
    _Separator:Begin
     ModeParam:=_None;
     Separator:=ParamStr(I);
    End;
    Else Begin
     If(ParamStr(I)='-w')or(ParamStr(I)='--equal-width')Then Begin
      EqualWidth:=True;
     End
      Else
     If ParamStr(I)='-f'Then Begin
      ModeParam:=_Format;
     End
      Else
     If ParamStr(I)='-s'Then Begin
      ModeParam:=_Separator;
     End
      Else
     If PosValue<=2 Then Begin
      Val(ParamStr(I),Value[PosValue],Err);
      Inc(PosValue);
     End
      Else
     Begin
      WriteLn('Trop de paramŠtre !');
      Halt(1);
     End;
    End;
   End;
  End;
  Case PosValue of
   1:Last:=Value[0];
   2:Begin
    First:=Value[0];
    Last:=Value[1];
   End;
   3:Begin
    First:=Value[0];
    Step:=Value[1];
    Last:=Value[2];
   End;
   Else Begin
    WriteLn('Nombre de paramŠtre invalide !');
    Halt(2);
   End;
  End;
  I:=First;
  Str(Last,LastS);
  While(I<=Last)do Begin
   If Format<>''Then Begin
    If Separator<>''Then Begin
     Write(FormatString(Format,I),Separator);
    End
     Else
    WriteLn(FormatString(Format,I));
   End
    Else
   Begin
    If(EqualWidth)Then Begin
     Write(PadZeroLeft(I,Length(LastS)));
    End
     Else
    Write(I);
    If Separator<>''Then Begin
     Write(Separator);
    End
     Else
    WriteLn;
   End;
   Inc(I,Step);
  End;
 End;
END.
