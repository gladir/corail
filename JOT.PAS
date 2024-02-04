{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program JOT;

Uses DOS;

Var
 Language:(_Albanian,_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 ModeParam:(_None,_BWord,_Precision,_Separator,_Format);
 Value:Array[0..3]of Real;
 SkipValue:Array[0..3]of Boolean;
 First,Last,Step,IR:Real;
 I,PosValue,Precision:Integer;
 PrintChar,NewLine,RandomValue:Boolean;
 Err:Word;
 BWord,Separator,Format:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

Function FormatString(S:String;Value:Real):String;
Var
 I,PadLeft:Integer;
 Err:Word;
 R,T:String;
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
    'c':R:=R+Char(Trunc(Value));
    'f':Begin
      Str(Value,T);
      R:=R+T;
     End;
    'd','g','i','l':Begin
     Str(Trunc(Value),T);
     R:=R+T;
    End;
    '0'..'9':Begin
     T:='';
     While(S[I]in['0'..'9'])and(I<=Length(S))do Begin
      T:=T+S[I];
      Inc(I);
     End;
     Val(T,PadLeft,Err);
     R:=R+PadZeroLeft(Trunc(Value),PadLeft);
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
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='SQ')or
    (StrToUpper(Copy(TmpLanguage,1,3))='ALB')Then Language:=_Albanian;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  Case Language of
   _English:Begin
    WriteLn('jot : print sequential or random data');
    WriteLn;
    WriteLn('Syntax: jot [-cnr] [-b word] [-w word] [-s string]',
                     ' [-p precision] [reps [begin [end [s]]]]');
    WriteLn;
    WriteLn(' -r            Generate random data instead of the default sequential data.');
    WriteLn(' -b word       Just print word repetitively.');
    WriteLn(' -w word       Print word with the generated data appended to it.');
    WriteLn(' -c            This is an abbreviation for -w %c.');
    WriteLn(' -s string     Print data separated by string.');
    WriteLn(' -n            Do not print the final newline normally appended to the output.');
    WriteLn(' -p precision  Print only as many digits or characters of the data as ',
                            'indicated by the integer precision.');

   End;
   Else Begin
    WriteLn('JOT : Cette commande permet d''afficher des donn‚es ',
                   's‚quentiel ou al‚atoire.');
    WriteLn;
    WriteLn('Syntaxe : JOT [options] [reps [first [last [step]]]]');
    WriteLn;
    WriteLn(' first         Indique le d‚but de la boucle');
    WriteLn(' last          Indique la fin de la boucle');
    WriteLn(' reps          Indique le nombre de r‚p‚tition');
    WriteLn(' step          Indique le saut de la boucle');
    WriteLn(' -b word       Affiche le mot sp‚cifi‚');
    WriteLn(' -c            Affiche le nombre en caractŠre');
    WriteLn(' -n            N''affiche pas de saut de ligne');
    WriteLn(' -p precision  Indique le nombre de chiffre de pr‚cision');
    WriteLn(' -r            G‚nŠre des nombres al‚atoires');
    WriteLn(' -s separator  Indique le s‚parateur entre les ‚l‚ments');
    WriteLn(' -w format     Utilise un format d''affichage style printf.');
    WriteLn;
   End;
  End;
 End
  Else
 If ParamCount>0Then Begin
  ModeParam:=_None;
  Separator:='';
  BWord:='';
  Format:='';
  First:=1;
  Last:=1;
  Step:=1;
  PosValue:=0;
  Precision:=0;
  PrintChar:=False;
  NewLine:=True;
  RandomValue:=False;
  FillChar(Value,SizeOf(Value),0);
  FillChar(SkipValue,SizeOf(SkipValue),0);
  For I:=1 to ParamCount do Begin
   Case ModeParam of
    _BWord:Begin
     BWord:=ParamStr(I);
     ModeParam:=_None;
    End;
    _Format:Begin
     Format:=ParamStr(I);
     ModeParam:=_None;
    End;
    _Precision:Begin
     Val(ParamStr(I),Precision,Err);
     ModeParam:=_None;
    End;
    _Separator:Begin
     Separator:=ParamStr(I);
     ModeParam:=_None;
    End;
    Else Begin
     If ParamStr(I)='-b'Then ModeParam:=_BWord Else
     If ParamStr(I)='-c'Then PrintChar:=True Else
     If ParamStr(I)='-cn'Then Begin
      PrintChar:=True;
      NewLine:=False;
     End
      Else
     If(ParamStr(I)='-cnr')or(ParamStr(I)='-crn')or
       (ParamStr(I)='-ncr')or(ParamStr(I)='-nrc')or
       (ParamStr(I)='-rcn')or(ParamStr(I)='-rnc')Then Begin
      PrintChar:=True;
      NewLine:=False;
      RandomValue:=True;
      Randomize;
     End
      Else
     If ParamStr(I)='-cr'Then Begin
      PrintChar:=True;
      RandomValue:=True;
      Randomize;
     End
      Else
     If ParamStr(I)='-n'Then NewLine:=False Else
     If ParamStr(I)='-nc'Then Begin
      PrintChar:=True;
      NewLine:=False;
     End
      Else
     If ParamStr(I)='-nr'Then Begin
      NewLine:=False;
      RandomValue:=True;
      Randomize;
     End
      Else
     If ParamStr(I)='-p'Then ModeParam:=_Precision Else
     If ParamStr(I)='-r'Then Begin
      RandomValue:=True;
      Randomize;
     End
      Else
     If ParamStr(I)='-rc'Then Begin
      PrintChar:=True;
      RandomValue:=True;
      Randomize;
     End
      Else
     If ParamStr(I)='-rn'Then Begin
      NewLine:=False;
      RandomValue:=True;
      Randomize;
     End
      Else
     If ParamStr(I)='-s'Then ModeParam:=_Separator Else
     If ParamStr(I)='-w'Then ModeParam:=_Format
      Else
     If PosValue<=3 Then Begin
      If ParamStr(I)='-'Then SkipValue[PosValue]:=True
                        Else Val(ParamStr(I),Value[PosValue],Err);
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
   1:Begin
    If Value[0]=0 Then Begin { Boucle infini }
     First:=1;
     Step:=0;
     Last:=2;
    End
     Else
    Begin
     First:=1;
     Last:=First+Value[0];
     Step:=1;
    End;
   End;
   2:Begin
    Step:=1;
    First:=Value[1];
    Last:=First+Step*Value[0];
   End;
   3:Begin
    First:=Value[1];
    Last:=Value[2];
    If(SkipValue[0])Then Step:=1
                    Else Step:=(Last-First)/Value[0];
   End;
   4:Begin
    First:=Value[1];
    Last:=Value[2];
    Step:=Value[3];
    Last:=First+(Step*Value[0]);
   End;
   Else Begin
    WriteLn('Nombre de paramŠtre invalide !');
    Halt(2);
   End;
  End;
  IR:=First;
  While(IR<=Last)do Begin
   If(BWord<>'')Then Write(BWord) Else
   If(PrintChar)Then Begin
    If(RandomValue)Then Write(Chr(Random(Trunc(Last-First))+Trunc(First)))
                   Else Write(Chr(Trunc(IR)));
   End
    Else
   Begin
    If(Format<>'')Then Begin
     If(RandomValue)Then Write(FormatString(Format,Random(Trunc(Last-First))+Trunc(First)))
                    Else Write(FormatString(Format,IR));
    End
     Else
    If(RandomValue)Then Write(Random(Trunc(Last-First))+Trunc(First))
                   Else Write(IR:0:Precision);
   End;
   If(Separator<>'')Then Write(Separator) Else
   If(NewLine)Then WriteLn;
   IR:=IR+Step;
  End;
 End;
END.