{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2RUBY(Input,Output);

Var
 SourceASC,TargetRuby:Text;
 CurrLine:String;

Function StringToRubyString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'\"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToRubyString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2RUBY : Cette commande permet de transformer du texte en code source Python.');
  WriteLn;
  WriteLn('Syntaxe : ASC2RUBY nomdufichier.asc nomdufichier.RB');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetRuby,ParamStr(2));
  {$I+}Rewrite(TargetRuby); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier Ruby !');
   Close(SourceASC);
   Halt;
  End;
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetRuby,'print ""')
                 Else WriteLn(TargetRuby,'print "',StringToRubyString(CurrLine),'"');
  End;
  Close(TargetRuby);
  Close(SourceASC);
 End
  Else
 Begin
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,'print ""')
                 Else WriteLn(Output,'print "',StringToRubyString(CurrLine),'"');
  End;
 End;
END.



