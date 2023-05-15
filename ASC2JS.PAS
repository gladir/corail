{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2JS(Input,Output);

Var
 SourceASC,TargetJS:Text;
 CurrLine:String;

Function StringToJSString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'\"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToJSString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2JS : Cette commande permet de transformer du texte en code source JavaScript.');
  WriteLn;
  WriteLn('Syntaxe : ASC2JS nomdufichier.asc nomdufichier.JS');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetJS,ParamStr(2));
  {$I+}Rewrite(TargetJS); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier JavaScript !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetJS,'<script language="JavaScript" type="text/javascript">');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetJS,' document.write("");')
                 Else WriteLn(TargetJS,' document.write("',StringToJSString(CurrLine),'");');
  End;
  WriteLn(TargetJS,'</script>');
  Close(TargetJS);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'<script language="JavaScript" type="text/javascript">');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,' printf("");')
                 Else WriteLn(Output,' printf("',StringToJSString(CurrLine),'");');
  End;
  WriteLn(Output,'</script>');
 End;
END.

