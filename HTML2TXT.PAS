{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program HTML2TXT;

Function strip_tag(S:String):String;
Var
 TagBegin,TagEnd,TagLength:Integer;
Begin
 TagBegin:=Pos('<',S);
 While (TagBegin>0) do Begin
  TagEnd:=Pos('>',S);
  If TagEnd=0Then Break;
  TagLength:=TagEnd-TagBegin+1;
  If TagLength=0Then Break;
  Delete(S,TagBegin,TagLength);
  TagBegin:=Pos('<',S);
 End;
 strip_tag:=S;
End;

Var
 Source,Target:Text;
 CurrLine:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('HTML2TXT : Cette commande permet d''enlever le code HTML et garder le texte.');
  WriteLn;
  WriteLn('Syntaxe : HTML2TXT fichier.html fichier.txt');
 End
  Else
 If ParamCount=2Then Begin
  {$I-}Assign(Source,ParamStr(1));
  Reset(Source);{$I+}
  If IOResult<>0Then Begin
   WriteLn('Fichier introuvable !');
  End
   Else
  Begin
   Assign(Target,ParamStr(2));
   Rewrite(Target);
   While Not EOF(Source)do Begin
    ReadLn(Source,CurrLine);
    WriteLn(Target,strip_tag(CurrLine));
   End;
   Close(Target);
   Close(Source);
  End;
 End
  Else
 WriteLn('Parametre requis !');
END.
