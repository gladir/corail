{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2PY(Input,Output);

Var
 SourceASC,TargetPython:Text;
 CurrLine:String;

Function StringToPythonString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'\"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToPythonString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2PY : Cette commande permet de transformer du texte en code source Python.');
  WriteLn;
  WriteLn('Syntaxe : ASC2PY nomdufichier.asc nomdufichier.PY');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetPython,ParamStr(2));
  {$I+}Rewrite(TargetPython); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier Python !');
   Close(SourceASC);
   Halt;
  End;
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetPython,'print("")')
                 Else WriteLn(TargetPython,'print("',StringToPythonString(CurrLine),'")');
  End;
  Close(TargetPython);
  Close(SourceASC);
 End
  Else
 Begin
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,'print("")')
                 Else WriteLn(Output,'print("',StringToPythonString(CurrLine),'")');
  End;
 End;
END.


