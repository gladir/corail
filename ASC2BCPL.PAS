{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2BCPL(Input,Output);

Var
 SourceASC,TargetBCPL:Text;
 CurrLine:String;

Function StringToBCPLString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'\"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToBCPLString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2BCPL : Cette commande permet de transformer du texte en code source C.');
  WriteLn;
  WriteLn('Syntaxe : ASC2BCPL nomdufichier.asc nomdufichier.BCPL');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetBCPL,ParamStr(2));
  {$I+}Rewrite(TargetBCPL); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier BCPL !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetBCPL,'GET "LIBHDR"');
  WriteLn(TargetBCPL);
  WriteLn(TargetBCPL,'LET START () BE');
  WriteLn(TargetBCPL,'$(');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetBCPL,' WRITES ("*N");')
                 Else WriteLn(TargetBCPL,' WRITES ("',StringToBCPLString(CurrLine),'*N");');
  End;
  WriteLn(TargetBCPL,'$)');
  Close(TargetBCPL);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'GET "LIBHDR"');
  WriteLn(Output);
  WriteLn(Output,'LET START () BE');
  WriteLn(Output,'$(');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,' WRITES ("*N");')
                 Else WriteLn(Output,' WRITES ("',StringToBCPLString(CurrLine),'*N");');
  End;
  WriteLn(Output,'$)');
 End;
END.