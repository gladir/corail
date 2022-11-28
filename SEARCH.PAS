{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program SEARCH;

Uses DOS;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage,CurrDir:String;
 Info:SearchRec;
 I:Integer;

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
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('SEARCH : Cette commande permet d''afficher les chemins des ',
          'fichiers sp‚cifi‚s.');
  WriteLn;
  WriteLn('Syntax : SEARCH [fichiers]');
 End
  Else
 If ParamCount>0 Then For I:=1 to ParamCount do Begin
  FindFirst(ParamStr(I),AnyFile,Info);
  While DOSError=0 do Begin
   WriteLn(FExpand(Info.Name));
   FindNext(Info);
  End;
 End
  Else
 Begin
  GetDir(0,CurrDir);
  WriteLn(CurrDir);
 End;
END.