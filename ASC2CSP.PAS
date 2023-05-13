{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2CSP(Input,Output);

Var
 SourceASC,TargetC:Text;
 CurrLine:String;

Function StringToCString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'\"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToCString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2CSP : Cette commande permet de transformer du texte en code source CSP (C Server Pages).');
  WriteLn;
  WriteLn('Syntaxe : ASC2CSP nomdufichier.asc nomdufichier.CSP');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetC,ParamStr(2));
  {$I+}Rewrite(TargetC); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier CSP !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetC,'<%');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetC,' HttpResponse_printf("");')
                 Else WriteLn(TargetC,' HttpResponse_printf("',StringToCString(CurrLine),'");');
  End;
  WriteLn(TargetC,'%>');
  Close(TargetC);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'<%');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,' HttpResponse_printf("");')
                 Else WriteLn(Output,' HttpResponse_printf("',StringToCString(CurrLine),'");');
  End;
  WriteLn(Output,'%>');
 End;
END.
