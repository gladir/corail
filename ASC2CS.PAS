{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2CS(Input,Output);

Var
 SourceASC,TargetCS:Text;
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
  WriteLn('ASC2CS : Cette commande permet de transformer du texte en code source C#.');
  WriteLn;
  WriteLn('Syntaxe : ASC2CS nomdufichier.asc nomdufichier.CS');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetCS,ParamStr(2));
  {$I+}Rewrite(TargetCS); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier CS !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetCS,'using System;');
  WriteLn(TargetCS,'using System.Collections.Generic;');
  WriteLn(TargetCS,'using System.Text;');
  WriteLn(TargetCS);
  WriteLn(TargetCS,'namespace consoleProgram {');
  WriteLn(TargetCS,' ':4,'class Program {');
  WriteLn(TargetCS,' ':8,'static void Main(string[] args) {');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetCS,' ':12,'Console.WriteLine("");')
                 Else WriteLn(TargetCS,' ':12,'Console.WriteLine("',StringToCString(CurrLine),'");');
  End;
  WriteLn(TargetCS,' ':8,'}');
  WriteLn(TargetCS,' ':4,'}');
  WriteLn(TargetCS,'}');
  Close(TargetCS);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'using System;');
  WriteLn(Output,'using System.Collections.Generic;');
  WriteLn(Output,'using System.Text;');
  WriteLn(Output);
  WriteLn(Output,'static void Main(string[] args) {');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,' Console.WriteLine("");')
                 Else WriteLn(Output,' Console.WriteLine("',StringToCString(CurrLine),'");');
  End;
  WriteLn(Output,'}');
 End;
END.
