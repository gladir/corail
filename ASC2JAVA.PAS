{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2Java(Input,Output);

Var
 SourceASC,TargetJava:Text;
 CurrLine:String;

Function StringToJavaString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'\"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToJavaString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2JAVA : Cette commande permet de transformer du texte en code source Java.');
  WriteLn;
  WriteLn('Syntaxe : ASC2JAVA nomdufichier.asc nomdufichier.JAVA');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetJava,ParamStr(2));
  {$I+}Rewrite(TargetJava); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier Java !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetJava,'public class consoleProgram {');
  WriteLn(TargetJava);
  WriteLn(TargetJava,' ':4,'public static void main(String[] args) {');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetJava,' ':8,'System.out.print("");')
                 Else WriteLn(TargetJava,' ':8,'System.out.print("',StringToJavaString(CurrLine),'");');
  End;
  WriteLn(TargetJava,' ':4,'}');
  WriteLn(TargetJava,'}');
  Close(TargetJava);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'public class consoleProgram {');
  WriteLn(Output);
  WriteLn(Output,' ':4,'public static void main(String[] args) {');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,' ':8,'System.out.print("");')
                 Else WriteLn(Output,' ':8,'System.out.print("',StringToJavaString(CurrLine),'");');
  End;
  WriteLn(Output,'}');
 End;
END.

