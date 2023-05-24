{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2CFM(Input,Output);

Var
 SourceASC,TargetCFM:Text;
 CurrLine:String;

Function StringToCFMString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'\"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToCFMString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2CFM : Cette commande permet de transformer du texte en code source ColdFusion.');
  WriteLn;
  WriteLn('Syntaxe : ASC2CFM nomdufichier.asc nomdufichier.CFM');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetCFM,ParamStr(2));
  {$I+}Rewrite(TargetCFM); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier ColdFusion !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetCFM,'<CFSCRIPT>');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetCFM,' WriteOutput("");')
                 Else WriteLn(TargetCFM,' WriteOutput("',StringToCFMString(CurrLine),'<br />");');
  End;
  WriteLn(TargetCFM,'</CFSCRIPT>');
  Close(TargetCFM);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'<CFSCRIPT>');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,' WriteOutput("");')
                 Else WriteLn(Output,' WriteOutput("',StringToCFMString(CurrLine),'<br />");');
  End;
  WriteLn(Output,'</CFSCRIPT>');
 End;
END.

