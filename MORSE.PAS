{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program MORSE;

Uses DOS;

Type
 MorseRec=Record
  Character:Char;
  CodeMorse:String[8];
 End;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage,CurrParam,CurrWord:String;
 DecodeMorse:Boolean;
 I,J,K:Integer;

Const
 Morses:Array[0..38]of MorseRec=(
  (Character:'a';CodeMorse:'.- '),
  (Character:'b';CodeMorse:'-... '),
  (Character:'c';CodeMorse:'-.-. '),
  (Character:'d';CodeMorse:'-.. '),
  (Character:'e';CodeMorse:'. '),
  (Character:'f';CodeMorse:'..-. '),
  (Character:'g';CodeMorse:'--. '),
  (Character:'h';CodeMorse:'.... '),
  (Character:'i';CodeMorse:'.. '),
  (Character:'j';CodeMorse:'.--- '),
  (Character:'k';CodeMorse:'.-. '),
  (Character:'l';CodeMorse:'.-.. '),
  (Character:'m';CodeMorse:'-- '),
  (Character:'n';CodeMorse:'-. '),
  (Character:'o';CodeMorse:'--- '),
  (Character:'p';CodeMorse:'.--. '),
  (Character:'q';CodeMorse:'--.- '),
  (Character:'r';CodeMorse:'.-. '),
  (Character:'s';CodeMorse:'... '),
  (Character:'t';CodeMorse:'- '),
  (Character:'u';CodeMorse:'..- '),
  (Character:'v';CodeMorse:'...- '),
  (Character:'w';CodeMorse:'.-- '),
  (Character:'x';CodeMorse:'-..- '),
  (Character:'y';CodeMorse:'-.-- '),
  (Character:'z';CodeMorse:'--.. '),
  (Character:' ';CodeMorse:'  '),
  (Character:'1';CodeMorse:'.---- '),
  (Character:'2';CodeMorse:'..--- '),
  (Character:'3';CodeMorse:'...-- '),
  (Character:'4';CodeMorse:'....- '),
  (Character:'5';CodeMorse:'..... '),
  (Character:'6';CodeMorse:'-.... '),
  (Character:'7';CodeMorse:'--... '),
  (Character:'8';CodeMorse:'---.. '),
  (Character:'9';CodeMorse:'-----.'),
  (Character:'0';CodeMorse:'----- '),
  (Character:'?';CodeMorse:'..--.. '),
  (Character:'!';CodeMorse:'--..-- ')
 );

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

BEGIN
 DecodeMorse:=False;
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('MORSE : Cette commande permet d''Çcrire en code Morse ',
                  'la chaine de caractäres spÇcifiÇ.');
  WriteLn;
  WriteLn('Syntaxe : MORSE [/?] [/DECODE] "message"');
  WriteLn;
  WriteLn(' /?       Ce paramätre permet de founir de l''aide sur cette commande.');
  WriteLn('/DECODE   Ce paramätre permet d''indiquer qu''il faut dÇcoder le code Morse.');
  WriteLn('"message" Ce paramätre permet d''indiquer le message Ö encoder');
 End
  Else
 Begin
  For I:=1 to ParamCount do Begin
   CurrParam:=ParamStr(I);
   If StrToUpper(CurrParam)='/DECODE'Then Begin
    DecodeMorse:=True;
   End
    Else
   Begin
    If(DecodeMorse)Then Begin
     CurrWord:='';
     For J:=1 to Length(CurrParam)do Begin
      CurrWord:=CurrWord+CurrParam[J];
      If CurrParam[J]=' 'Then Begin
       For K:=Low(Morses) to High(Morses)do Begin
        If(Morses[K].CodeMorse=CurrWord)Then Begin
         Write(Morses[K].Character);
         Break;
        End;
       End;
       CurrWord:='';
      End;
     End;
     If CurrWord<>''Then For K:=Low(Morses) to High(Morses)do Begin
      If(Morses[K].CodeMorse=CurrWord+' ')Then Begin
       Write(Morses[K].Character);
       Break;
      End;
     End;
    End
     Else
    For J:=1 to Length(CurrParam)do Begin
     For K:=Low(Morses) to High(Morses)do Begin
      If StrToUpper(Morses[K].Character)=StrToUpper(CurrParam[J])Then Begin
       Write(Morses[K].CodeMorse);
       Break;
      End;
     End;
    End;
    WriteLn;
   End;
  End;
 End;
END.