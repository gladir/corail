{ @author: Sylvain
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2PERL(Input,Output);

Var
 SourceASC,TargetPERL:Text;
 CurrLine:String;

Function StringToPERLString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'\"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToPERLString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2PERL : Cette commande permet de transformer du texte en code source Perl.');
  WriteLn;
  WriteLn('Syntaxe : ASC2PERL nomdufichier.asc nomdufichier.pl');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetPERL,ParamStr(2));
  {$I+}Rewrite(TargetPERL); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier PERL !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetPERL,'#!usr/bin/perl');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetPERL,'print "\n";')
                 Else WriteLn(TargetPERL,'print "',StringToPERLString(CurrLine),'\n";');
  End;
  Close(TargetPERL);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'#!usr/bin/perl');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,'print "\n";')
                 Else WriteLn(Output,'print "',StringToPERLString(CurrLine),'\n";');
  End;
 End;
END.



