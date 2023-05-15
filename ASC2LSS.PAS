{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2LSS(Input,Output);

Var
 SourceASC,TargetLSS:Text;
 CurrLine:String;

Function StringToBasicString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'" & CHR$(34) & "';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToBasicString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2LSS : Cette commande permet de transformer du texte en code source LotusScript.');
  WriteLn;
  WriteLn('Syntaxe : ASC2LSS nomdufichier.asc nomdufichier.LSS');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetLSS,ParamStr(2));
  {$I+}Rewrite(TargetLSS); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier LSS !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetLSS,'Sub Main');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetLSS,'Print ""')
                 Else WriteLn(TargetLSS,'Print "',StringToBasicString(CurrLine),'"');
  End;
  WriteLn(TargetLSS,'End Sub');
  Close(TargetLSS);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'Sub Main');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,'Print ""')
                 Else WriteLn(Output,'Print "',StringToBasicString(CurrLine),'"');
  End;
  WriteLn(Output,'End Sub');
 End;
END.

