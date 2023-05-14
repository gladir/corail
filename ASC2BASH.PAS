{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2BASH(Input,Output);

Var
 SourceASC,TargetBASH:Text;
 CurrLine:String;

Function StringToBASHString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'\"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToBASHString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2BASH : Cette commande permet de transformer du texte en code source BASH.');
  WriteLn;
  WriteLn('Syntaxe : ASC2BASH nomdufichier.asc nomdufichier.sh');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetBASH,ParamStr(2));
  {$I+}Rewrite(TargetBASH); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier BASH !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetBASH,'#! /bin/bash');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetBASH,'echo "\n";')
                 Else WriteLn(TargetBASH,'echo "',StringToBASHString(CurrLine),'\n";');
  End;
  Close(TargetBASH);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'#! /bin/bash');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,'echo "\n";')
                 Else WriteLn(Output,'echo "',StringToBASHString(CurrLine),'\n";');
  End;
 End;
END.


