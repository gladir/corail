{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program ASC2PAS(Input,Output);

Var
 SourceASC,TargetPas:Text;
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
  WriteLn('ASC2PAS : Cette commande permet de transformer du texte en code source Pascal.');
  WriteLn;
  WriteLn('Syntaxe : ASC2PAS nomdufichier.asc nomdufichier.PAS');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetPas,ParamStr(2));
  {$I+}Rewrite(TargetPas); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier Pascal !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetPas,'BEGIN');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetPas,' WriteLn;')
                 Else WriteLn(TargetPas,' WriteLn(''',StringToPascalString(CurrLine),''');');
  End;
  WriteLn(TargetPas,'END.');
  Close(TargetPas);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'BEGIN');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,' WriteLn;')
                 Else WriteLn(Output,' WriteLn(''',StringToPascalString(CurrLine),''');');
  End;
  WriteLn(Output,'END.');
 End;
END.
