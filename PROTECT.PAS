{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program PROTECT;

Uses DOS;

Var
 CurrAttr:Word;
 Flags:Set Of (ReadFlag,WriteFlag,DeleteFlag,ExecuteFlag);
 P,I:Byte;
 InFlags:Boolean;
 F:File;
 FileName,CurrParam:String;

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
 Flags:=[];
 P:=0;
 InFlags:=False;
 FileName:='';
 Repeat
  Inc(P);
  CurrParam:=ParamStr(P);
  If Length(CurrParam)=0Then Break;
  If CurrParam='/?'Then Begin
   WriteLn('PROTECT  Cette commande permet de fixer les protection de mode d''acces d''un fichier.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('PROTECT [/?] nomdefichier [FLAGS etat]');
  End
   Else
  If(InFlags)Then Begin
   For I:=1 to Length(CurrParam)do Begin
    Case UpCase(CurrParam[I])of
     'D':Include(Flags,DeleteFlag);
     'E':Include(Flags,ExecuteFlag);
     'R':Include(Flags,ReadFlag);
     'W':Include(Flags,WriteFlag);
    End;
   End;
   InFlags:=False;
  End
   Else
  If StrToUpper(CurrParam)='FLAGS'Then InFlags:=True
                                  Else FileName:=CurrParam;
  If P>99Then Break;
 Until CurrParam='';
 If FileName<>''Then Begin
  Assign(F,FileName);
  GetFAttr(F,CurrAttr);
  If(ReadFlag in Flags)Then CurrAttr:=CurrAttr or ReadOnly
                       Else CurrAttr:=CurrAttr and Not(ReadOnly);
  SetFAttr(F,CurrAttr);
 End
  Else
 WriteLn('Nom de fichier requis !');
END.