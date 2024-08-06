{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program PR;

Uses DOS,Printer;

Var
 Mode:(_None,_C);
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

Procedure SubmitFileForPrinting(FileName:String);
Var
 FilePrt:Text;
 Err:Integer;
 CurrLine:String;
Begin
 {$I-}Assign(FilePrt,FileName);
 Reset(FilePrt);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier ',FileName);
  Halt(1);
 End;
 While Not EOF(FilePrt)do Begin
  ReadLn(FilePrt,CurrLine);
  {$I-}WriteLn(Lst,CurrLine);{$I+}
  Err:=IOResult;
  If Err<>0 Then Begin
   WriteLn('Erreur d''impression : ',Err);
   Halt(2);
  End;
 End;
 Close(FilePrt);
End;

BEGIN
 Mode:=_None;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('PR: Cette commande permet d''afficher un/des ficiher(s) ',
              'pour l''impression.');
  WriteLn;
  WriteLn('Syntaxe: PRINT [fichier]');
  WriteLn;
  WriteLn(' fichier    Permet d''indiquer le fichier … imprimer');
 End
  Else
 If ParamCount>0Then For I:=1 to ParamCount do Begin
  SubmitFileForPrinting(ParamStr(I));
 End;
END.

