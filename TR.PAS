{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program TR;

Uses DOS;

Type
 SetType=(_none_,_alnum_,_alpha_,_blank_,_cntrl_,_digit_,_graph_,
            _lower_,_print_,_punct_,_space_,_upper_,_xdigit_,
            _string_,_Rang_);
 ParamSetRec=Record
  ThisSet:SetType;
  Value:String[10];
  Pattern:Set of Char;
 End;

Const
 ParamSet:Array[0..11]of ParamSetRec=(
  (ThisSet:_alnum_;Value:'[:alnum:]';
   Pattern:['A'..'Z','a'..'z','0'..'9']),
  (ThisSet:_alpha_;Value:'[:alpha:]';
   Pattern:['A'..'Z','a'..'z']),
  (ThisSet:_blank_;Value:'[:blank:]';
   Pattern:[#9,' ']),
  (ThisSet:_cntrl_;Value:'[:cntrl:]';
   Pattern:[#0..#31,#127]),
  (ThisSet:_digit_;Value:'[:digit:]';
   Pattern:['0'..'9']),
  (ThisSet:_graph_;Value:'[:graph:]';
   Pattern:[#33..#255]),
  (ThisSet:_lower_;Value:'[:lower:]';
   Pattern:['a'..'z']),
  (ThisSet:_print_;Value:'[:print:]';
   Pattern:[#32..#255]),
  (ThisSet:_punct_;Value:'[:punct:]';
   Pattern:['!','"','#','$','%','&','''','(',')','*','+',',','-','.','/','{','}','~']),
  (ThisSet:_space_;Value:'[:space:]';
   Pattern:[#0,#8,' ']),
  (ThisSet:_upper_;Value:'[:upper:]';
   Pattern:['A'..'Z']),
  (ThisSet:_xdigit_;Value:'[:xdigit:]';
   Pattern:['0'..'9','A'..'F','a'..'f'])
 );

Var
 Language:(_Albanian,_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 Found,TruncateSet1:Boolean;
 CurrLine,CurrParam:String;
 I,J,PosParam:Integer;
 C:Char;
 SetParam:Array[1..2]of SetType;
 SetParamI:Array[1..2]of Integer;
 SetParamStr:Array[1..2]of String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function StrToLower(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
 End;
 StrToLower:=S;
End;

Function Dupl(C:Char;Num:Integer):String;
Var
 I:Byte;
 S:String;
Begin
 S:='';
 For I:=1 to Num do S:=S+C;
 Dupl:=S;
End;

Function LoCase(C:Char):Char;Begin
 If C in['A'..'Z']Then C:=Chr(Ord(C)+32);
 LoCase:=C;
End;

Function PadZeroLeft(Value:String;Space:Byte):String;
Var
 S:String;
Begin
 S:=Value;
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

Function SPrintF(S:String):String;
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
     ValueStr:='';
     If Length(ValueStr)>0 Then R:=R+ValueStr[1];
    End;
    'd','f','g','i','l':Begin
     T:='';
     R:=R+T;
    End;
    '0'..'9':Begin
     T:='';
     While(S[I]in['0'..'9'])and(I<=Length(S))do Begin
      T:=T+S[I];
      Inc(I);
     End;
     Val(T,PadLeft,Err);
     {R:=R+PadZeroLeft(ParamStr(CurrParam),PadLeft);}
    End;
   End;
  End
   Else
  R:=R+S[I];
  Inc(I);
 End;
 SPrintF:=R;
End;

Function InRang(C:Char;Rang:String):Boolean;
Var
 I:Integer;
 StartChr,EndChr:Char;
Begin
 InRang:=False;
 StartChr:=#0;
 EndChr:=#0;
 I:=1;
 While I<=Length(Rang)do Begin
  If Rang[I]='-'Then Begin
   StartChr:=Rang[I-1];
   EndChr:=Rang[I+1];
   If(C>=StartChr)and(C<=EndChr)Then Begin
    InRang:=True;
    Exit;
   End;
   Inc(I,2);
  End
   Else
  If Rang[I]=C Then Begin
   InRang:=True;
   Exit;
  End
   Else
  Inc(I);
 End;
End;

Function ReplaceRang(C:Char;Source,Target:String):Char;
Var
 I:Integer;
 StartChr,EndChr,CI:Char;
 SourceRang,TargetRang:String;
Begin
 ReplaceRang:=C;
 StartChr:=#0;
 EndChr:=#0;
 SourceRang:='';
 I:=1;
 While I<=Length(Source)do Begin
  If(Length(Source)>=I+1)and(Source[I+1]='-')Then Begin
   StartChr:=Source[I];
   EndChr:=Source[I+2];
   If StartChr>EndChr Then Begin
    For CI:=StartChr downto EndChr do SourceRang:=SourceRang+CI;
   End
    Else
   For CI:=StartChr to EndChr do SourceRang:=SourceRang+CI;
   Inc(I,3);
  End
   Else
  Begin
   If Source[I]='\'Then Begin
    Inc(I);
    If I>Length(Source)Then Break;
    Case Source[I]of
     '0':SourceRang:=SourceRang+#0;
     'a':SourceRang:=SourceRang+#7;
     'b':SourceRang:=SourceRang+#8;
     'f':SourceRang:=SourceRang+#12;
     'n':SourceRang:=SourceRang+#10;
     'r':SourceRang:=SourceRang+#13;
     't':SourceRang:=SourceRang+#9;
     'v':SourceRang:=SourceRang+#11;
     '\':SourceRang:=SourceRang+'\';
     '''':SourceRang:=SourceRang+'''';
     '"':SourceRang:=SourceRang+'"';
     '?':SourceRang:=SourceRang+'?';
    End;
   End
    Else
   SourceRang:=SourceRang+Source[I];
   Inc(I);
  End;
 End;
 TargetRang:='';
 I:=1;
 If(Length(Target)=2)and(Target[2]='*')Then Begin
  TargetRang:=Dupl(Target[1],Length(SourceRang));
 End
  Else
 While I<=Length(Target)do Begin
  If(Length(Target)>=I+1)and(Target[I+1]='-')Then Begin
   StartChr:=Target[I];
   EndChr:=Target[I+2];
   If StartChr>EndChr Then Begin
    For CI:=StartChr downto EndChr do TargetRang:=TargetRang+CI;
   End
    Else
   For CI:=StartChr to EndChr do TargetRang:=TargetRang+CI;
   Inc(I,3);
  End
   Else
  Begin
   If Target[I]='\'Then Begin
    Inc(I);
    If I>Length(Target)Then Break;
    Case Target[I]of
     '0':TargetRang:=TargetRang+#0;
     'a':TargetRang:=TargetRang+#7;
     'b':TargetRang:=TargetRang+#8;
     'f':TargetRang:=TargetRang+#12;
     'n':TargetRang:=TargetRang+#10;
     'r':TargetRang:=TargetRang+#13;
     't':TargetRang:=TargetRang+#9;
     'v':TargetRang:=TargetRang+#11;
     '\':TargetRang:=TargetRang+'\';
     '''':TargetRang:=TargetRang+'''';
     '"':TargetRang:=TargetRang+'"';
     '?':TargetRang:=TargetRang+'?';
    End;
   End
    Else
   TargetRang:=TargetRang+Target[I];
   Inc(I);
  End;
 End;
 If(TruncateSet1)Then Begin
  If Length(SourceRang)>Length(TargetRang)Then Begin
   SourceRang:=Copy(SourceRang,1,Length(TargetRang));
  End;
 End;
 For I:=1 to Length(SourceRang)do Begin
  If C=SourceRang[I]Then Begin
   ReplaceRang:=TargetRang[I];
   Exit;
  End;
 End;
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
    WriteLn('TR : Translate, squeeze, and/or delete characters from standard input,');
    WriteLn('     writing to standard output.');
    WriteLn;
    WriteLn('Syntax: tr [OPTION]... SET1 [SET2]');

   End;
   Else Begin
    WriteLn('TR : Cette commande permet d''envoyer le contenu de ',
                  'l''entrÇe standard vers la sortie standard en ',
                  'effectuant le traitement spÇcifiÇ.');
    WriteLn;
    WriteLn('Syntaxe : TR [options] [set1] set2');
    WriteLn;
    WriteLn(' set1             Ensemble de recherche');
    WriteLn(' set2             Ensemble de remplacement');
    WriteLn(' -t               Tronquer SET1 Ö la longueur de SET2.');
    WriteLn(' --help           Affiche l''aide de cette commande.');
    WriteLn(' --truncate-set1  Tronquer SET1 Ö la longueur de SET2.');
    WriteLn(' --version        Affiche la version de cette commande.');
    WriteLn;
    WriteLn('Ensemble prÇdefinie : ');
    WriteLn(' [:alnum:]        Toutes les lettres et chiffres');
    WriteLn(' [:alpha:]        Toutes les lettres');
    WriteLn(' [:blank:]        Tous les espaces horizontaux');
    WriteLn(' [:cntrl:]        Tous les caractäres de contrìle');
    WriteLn(' [:digit:]        Tous les chiffres');
    WriteLn(' [:graph:]        Tous les caractäres imprimables, sans compter l''espace');
    WriteLn(' [:lower:]        Toutes les lettres minuscules');
    WriteLn(' [:print:]        Tous les caractäres imprimables, y compris l''espace');
    WriteLn(' [:punct:]        Tous les caractäres de ponctuation');
    WriteLn(' [:space:]        Tous les espaces horizontaux ou verticaux');
    WriteLn(' [:upper:]        Toutes les lettres majuscules');
    WriteLn(' [:xdigit:]       Tous les chiffres hexadÇcimaux');
   End;
  End;
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('TR 1.0 - Clone Pascal de coreutils, linux, unix ou corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('êcrit par Sylvain Maltais');
 End
  Else
 Begin
  TruncateSet1:=False;
  SetParam[1]:=_none_;
  SetParamI[1]:=-1;
  SetParam[2]:=_none_;
  SetParamI[2]:=-1;
  FillChar(SetParamStr,SizeOf(SetParamStr),0);
  PosParam:=1;
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='-t')or(ParamStr(I)='--truncate-set1')Then Begin
    TruncateSet1:=True;
   End
    Else
   Begin
    Found:=False;
    CurrParam:=ParamStr(I);
    For J:=0 to High(ParamSet)do Begin
     If(CurrParam=ParamSet[J].Value)Then Begin
      If PosParam<=2 Then Begin
       Found:=True;
       SetParam[PosParam]:=ParamSet[J].ThisSet;
       SetParamI[PosParam]:=J;
       Inc(PosParam);
      End
       Else
      Begin
       WriteLn('Trop d''ensemble');
       Halt(1);
      End;
     End;
    End;
    If Not(Found)Then Begin
     If PosParam<=2 Then Begin
      Found:=True;
      If(CurrParam[1]='[')and(CurrParam[Length(CurrParam)]=']')Then Begin
       SetParam[PosParam]:=_Rang_;
       SetParamStr[PosParam]:=Copy(CurrParam,2,Length(CurrParam)-2);
       SetParamI[PosParam]:=0;
      End
       Else
      If(CurrParam[1]='''')and(CurrParam[Length(CurrParam)]='''')Then Begin
       SetParam[PosParam]:=_Rang_;
       SetParamStr[PosParam]:=Copy(CurrParam,2,Length(CurrParam)-2);
       SetParamI[PosParam]:=0;
      End
       Else
      Begin
       SetParam[PosParam]:=_string_;
       SetParamStr[PosParam]:=CurrParam;
       SetParamI[PosParam]:=0;
      End;
      Inc(PosParam);
     End
      Else
     Begin
      WriteLn('Trop d''ensemble');
      Halt(1);
     End;
    End;
   End;
  End;
  While Not EOF do Begin
   ReadLn(CurrLine);
   If PosParam=3 Then Begin
    For I:=1 to Length(CurrLine)do Begin
     If(SetParam[1]=_Rang_)Then Begin
      C:=CurrLine[I];
      If InRang(C,SetParamStr[1])Then Begin
       Case SetParam[2]of
        _lower_:Write(LoCase(C));
        _upper_:Write(UpCase(C));
        _string_:Write(SPrintF(SetParamStr[2]));
        _rang_:Write(ReplaceRang(C,SetParamStr[1],SetParamStr[2]));
        Else Write(C);
       End;
      End
       Else
      Write(C);
     End
      Else
     If(CurrLine[I] in ParamSet[SetParamI[1]].Pattern)Then Begin
      C:=CurrLine[I];
      Case SetParam[2]of
       _lower_:Write(LoCase(C));
       _upper_:Write(UpCase(C));
       _string_:Write(SPrintF(SetParamStr[2]));
       Else Write(C);
      End;
     End
      Else
     Write(CurrLine[I]);
    End;
    WriteLn;
   End
    Else
   If PosParam=2 Then Begin
    Case SetParam[1]of
     _lower_:WriteLn(StrToLower(CurrLine));
     _upper_:WriteLn(StrToUpper(CurrLine));
     Else WriteLn(CurrLine);
    End;
   End
    Else
   WriteLn(CurrLine);
  End;
 End;
END.