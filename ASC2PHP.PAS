{ @author: Sylvain
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2PHP(Input,Output);

Var
 SourceASC,TargetPHP:Text;
 CurrLine:String;

Function StringToPHPString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'\"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToPHPString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2PHP : Cette commande permet de transformer du texte en code source PHP.');
  WriteLn;
  WriteLn('Syntaxe : ASC2PHP nomdufichier.asc nomdufichier.php');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetPHP,ParamStr(2));
  {$I+}Rewrite(TargetPHP); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier PHP !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetPHP,'<?php');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetPHP,'print "<br />";')
                 Else WriteLn(TargetPHP,'print "',StringToPHPString(CurrLine),'<br />";');
  End;
  WriteLn(TargetPHP,'?>');
  Close(TargetPHP);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'<?php');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,'echo "<br />";')
                 Else WriteLn(Output,'echo "',StringToPHPString(CurrLine),'<br />";');
  End;
  WriteLn(Output,'?>');
 End;
END.




