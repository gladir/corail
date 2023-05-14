{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2AWK(Input,Output);

Var
 SourceASC,TargetAWK:Text;
 CurrLine:String;

Function StringToAWKString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'\"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToAWKString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2AWK : Cette commande permet de transformer du texte en code source AWK.');
  WriteLn;
  WriteLn('Syntaxe : ASC2C nomdufichier.asc nomdufichier.AWK');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetAWK,ParamStr(2));
  {$I+}Rewrite(TargetAWK); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier AWK !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetAWK,'#! /bin/sh');
  WriteLn(TargetAWK);
  WriteLn(TargetAWK,'BEGIN {');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetAWK,' print "";')
                 Else WriteLn(TargetAWK,' print "',StringToAWKString(CurrLine),'";');
  End;
  WriteLn(TargetAWK,' exit;');
  WriteLn(TargetAWK,'}');
  Close(TargetAWK);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'#! /bin/sh');
  WriteLn(Output);
  WriteLn(Output,'BEGIN {');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,' print "";')
                 Else WriteLn(Output,' print "',StringToAWKString(CurrLine),'";');
  End;
  WriteLn(Output,' exit;');
  WriteLn(Output,'}');
 End;
END.

