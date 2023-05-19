{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2REXX(Input,Output);

Var
 SourceASC,TargetREXX:Text;
 CurrLine:String;

Function StringToREXXString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'\"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToREXXString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2REXX : Cette commande permet de transformer du texte en code source REXX.');
  WriteLn;
  WriteLn('Syntaxe : ASC2REXX nomdufichier.asc nomdufichier.REX');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetREXX,ParamStr(2));
  {$I+}Rewrite(TargetREXX); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier REXX !');
   Close(SourceASC);
   Halt;
  End;
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetREXX,'SAY ""')
                 Else WriteLn(TargetREXX,'SAY "',StringToREXXString(CurrLine),'"');
  End;
  WriteLn(TargetREXX,'EXIT');
  Close(TargetREXX);
  Close(SourceASC);
 End
  Else
 Begin
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,'SAY ""')
                 Else WriteLn(Output,'SAY "',StringToREXXString(CurrLine),'"');
  End;
 End;
END.



