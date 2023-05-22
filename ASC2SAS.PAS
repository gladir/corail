{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2SAS(Input,Output);

Var
 SourceASC,TargetSAS:Text;
 CurrLine:String;

Function StringToSASString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'\"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToSASString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2SAS : Cette commande permet de transformer du texte en code source SAS.');
  WriteLn;
  WriteLn('Syntaxe : ASC2SAS nomdufichier.asc nomdufichier.SAS');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetSAS,ParamStr(2));
  {$I+}Rewrite(TargetSAS); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier SAS !');
   Close(SourceASC);
   Halt;
  End;
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetSAS,'put "";')
                 Else WriteLn(TargetSAS,'put "',StringToSASString(CurrLine),'";');
  End;
  Close(TargetSAS);
  Close(SourceASC);
 End
  Else
 Begin
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,'print "";')
                 Else WriteLn(Output,'print "',StringToSASString(CurrLine),'";');
  End;
 End;
END.


