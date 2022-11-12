{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program ASC2BAS(Input,Output);

Var
 SourceASC,TargetBAS:Text;
 CurrLine:String;

Function StringToBasicString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'"+CHR$(34)+"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToBasicString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2BAS : Cette commande permet de transformer du texte en code source BAS.');
  WriteLn;
  WriteLn('Syntaxe : ASC2BAS nomdufichier.asc nomdufichier.BAS');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetBAS,ParamStr(2));
  {$I+}Rewrite(TargetBAS); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier BAS !');
   Close(SourceASC);
   Halt;
  End;
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetBAS,'PRINT ""')
                 Else WriteLn(TargetBAS,'PRINT "',StringToBasicString(CurrLine),'"');
  End;
  Close(TargetBAS);
  Close(SourceASC);
 End
  Else
 Begin
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,'PRINT ""')
                 Else WriteLn(Output,'PRINT "',StringToBasicString(CurrLine),'"');
  End;
 End;
END.