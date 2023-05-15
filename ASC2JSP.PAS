{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2JSP(Input,Output);

Var
 SourceASC,TargetJSP:Text;
 CurrLine:String;

Function StringToJSPString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'\"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToJSPString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2JSP : Cette commande permet de transformer du texte en code source JSP (Java Server Pages).');
  WriteLn;
  WriteLn('Syntaxe : ASC2JSP nomdufichier.asc nomdufichier.JSP');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetJSP,ParamStr(2));
  {$I+}Rewrite(TargetJSP); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier JSP (Java Server Pages) !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetJSP,'<%');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetJSP,' out.print("");')
                 Else WriteLn(TargetJSP,' out.print("',StringToJSPString(CurrLine),'");');
  End;
  WriteLn(TargetJSP,'%>');
  Close(TargetJSP);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'<%');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,' out.print("");')
                 Else WriteLn(Output,' out.print("',StringToJSPString(CurrLine),'");');
  End;
  WriteLn(Output,'%>');
 End;
END.


