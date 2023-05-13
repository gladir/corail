{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2Ada(Input,Output);

Const
 ProcName='SampleTxt';

Var
 SourceASC,TargetAda:Text;
 CurrLine:String;

Function StringToAdaString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'\"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToAdaString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2ADA : Cette commande permet de transformer du texte en code source ADA.');
  WriteLn;
  WriteLn('Syntaxe : ASC2ADA nomdufichier.asc nomdufichier.ADA');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetAda,ParamStr(2));
  {$I+}Rewrite(TargetAda); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier Ada !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetAda,'with TEXT_IO; use TEXT_IO;');
  WriteLn(TargetAda);
  WriteLn(TargetAda,'procedure ',ProcName,' is begin');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetAda,' PUT_LINE("");')
                 Else WriteLn(TargetAda,' PUT_LINE("',StringToAdaString(CurrLine),'");');
  End;
  WriteLn(TargetAda,'end ',ProcName);
  Close(TargetAda);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'with TEXT_IO; use TEXT_IO;');
  WriteLn(Output);
  WriteLn(Output,'procedure ',ProcName,' is begin');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,' PUT_LINE("");')
                 Else WriteLn(Output,' PUT_LINE("',StringToAdaString(CurrLine),'");');
  End;
  WriteLn(Output,'end ',ProcName);
 End;
END.
