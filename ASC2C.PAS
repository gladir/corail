{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program ASC2C(Input,Output);

Var
 SourceASC,TargetC:Text;
 CurrLine:String;

Function StringToPascalString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]=''''Then ConvStr:=ConvStr+'''';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToPascalString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2C : Cette commande permet de transformer du texte en code source C.');
  WriteLn;
  WriteLn('Syntaxe : ASC2C nomdufichier.asc nomdufichier.C');
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
   WriteLn('Impossible de cr‚er le fichier C !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetC,'#include <stdio.h>');
  WriteLn(TargetC);
  WriteLn(TargetC,'void main() {');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetC,' printf("");')
                 Else WriteLn(TargetC,' printf("',StringToPascalString(CurrLine),'");');
  End;
  WriteLn(TargetC,'}');
  Close(TargetC);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'#include <stdio.h>');
  WriteLn(Output);
  WriteLn(Output,'void main() {');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,' printf("");')
                 Else WriteLn(Output,' printf("',StringToPascalString(CurrLine),'");');
  End;
  WriteLn(Output,'}');
 End;
END.
