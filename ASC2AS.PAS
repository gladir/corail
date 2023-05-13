{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2AS(Input,Output);

Var
 SourceASC,TargetAS:Text;
 CurrLine:String;

Function StringToASString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]='"'Then ConvStr:=ConvStr+'\"';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToASString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2AS : Cette commande permet de transformer du texte en code source ActionScript.');
  WriteLn;
  WriteLn('Syntaxe : ASC2AS nomdufichier.asc nomdufichier.AS');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetAS,ParamStr(2));
  {$I+}Rewrite(TargetAS); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier ActionScript !');
   Close(SourceASC);
   Halt;
  End;
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetAS,'trace("");')
                 Else WriteLn(TargetAS,'trace("',StringToASString(CurrLine),'");');
  End;
  Close(TargetAS);
  Close(SourceASC);
 End
  Else
 Begin
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,'trace("");')
                 Else WriteLn(Output,'trace("',StringToASString(CurrLine),'");');
  End;
 End;
END.

