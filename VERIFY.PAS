{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program VERIFY;

Uses DOS;

Var
 FirstParam:String;
 X:Boolean;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function FileExist(Name:String):Boolean;
Var
 Rec:SearchRec;
Begin
 FindFirst(Name,AnyFile,Rec);
 FileExist:=DosError=0;
End;

BEGIN
 FirstParam:=ParamStr(1);
 If FirstParam='/?'Then Begin
  WriteLn('VERIFY   Cette commande permet de fixer ou de demander l''etat du ',
          'drapeau de verification de lecture de secteur d''unite d''allocation ',
          'du systeme d''exploitation ou de verifier qu''un fichier existe.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('VERIFY [/?] [OFF|ON]');
  WriteLN('VERIFY nomdufichier');
  WriteLn;
  WriteLn('  /?          Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' OFF          Ce parametre permet d''activer la verification');
  WriteLn(' ON           Ce parametre permet de desactiver la verification');
  WriteLn(' nomdufichier Ce paramätre permet de verifier le fichier (Apple DOS)');
 End
  Else
 If StrToUpper(FirstParam)='OFF'Then SetVerify(False) Else
 If StrToUpper(FirstParam)='ON'Then SetVerify(True)
  Else
 If FirstParam<>''Then Begin
  If Not FileExist(FirstParam)Then WriteLn('FICHIER NON PRESENT');
 End
  Else
 Begin
  GetVerify(X);
  Write('VERIFY = ');
  If(X)Then WriteLn('on')
       Else WriteLn('off');
 End;
END.