{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2ASP(Input,Output);

Var
 SourceASC,TargetASP:Text;
 CurrLine:String;

Function StringToASPString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'"+CHR(34)+"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToASPString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2ASP : Cette commande permet de transformer du texte en code source ASP.');
  WriteLn;
  WriteLn('Syntaxe : ASC2ASP nomdufichier.asc nomdufichier.ASP');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetASP,ParamStr(2));
  {$I+}Rewrite(TargetASP); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier BAS !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetASP,'<%');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetASP,'Response.Write ""')
                 Else WriteLn(TargetASP,'Response.Write "',StringToASPString(CurrLine),'"');
  End;
  WriteLn(TargetASP,'%>');
  Close(TargetASP);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'<%');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,'Response.Write ""')
                 Else WriteLn(Output,'Response.Write "',StringToASPString(CurrLine),'"');
  End;
  WriteLn(Output,'%>');
 End;
END.