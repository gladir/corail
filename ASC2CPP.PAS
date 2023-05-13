{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2CPP(Input,Output);

Var
 SourceASC,TargetCPP:Text;
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
  WriteLn('ASC2CPP : Cette commande permet de transformer du texte en code source CPP.');
  WriteLn;
  WriteLn('Syntaxe : ASC2CPP nomdufichier.asc nomdufichier.CPP');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetCPP,ParamStr(2));
  {$I+}Rewrite(TargetCPP); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier C++ !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetCPP,'#include <iostream>');
  WriteLn(TargetCPP);
  WriteLn(TargetCPP,'int main() {');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetCPP,' std::cout << std::endl;;')
                 Else WriteLn(TargetCPP,' std::cout << "',StringToCString(CurrLine),'" << std::endl;');
  End;
  WriteLn(TargetCPP,' return 0;');
  WriteLn(TargetCPP,'}');
  Close(TargetCPP);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'#include <iostream>');
  WriteLn(Output);
  WriteLn(Output,'int main() {');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,' std::cout << std::endl;;')
                 Else WriteLn(Output,' std::cout << "',StringToCString(CurrLine),'" << std::endl;');
  End;
  WriteLn(' return 0;');
  WriteLn(Output,'}');
 End;
END.