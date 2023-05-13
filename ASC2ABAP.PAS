{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2ABAP(Input,Output);

Var
 SourceASC,TargetABAP:Text;
 CurrLine:String;

Function StringToABAPString(Source:String):String;
Var
 I:Integer;
 ConvStr:String;
Begin
 ConvStr:='';
 For I:=1 to Length(Source)do Begin
  If Source[I]=''''Then ConvStr:=ConvStr+'''';
  ConvStr:=ConvStr+Source[I];
 End;
 StringToABAPString:=ConvStr;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2ABAP : Cette commande permet de transformer du texte en code source ABAP/4.');
  WriteLn;
  WriteLn('Syntaxe : ASC2ABAP nomdufichier.asc nomdufichier.ABAP');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetABAP,ParamStr(2));
  {$I+}Rewrite(TargetABAP); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier ABAP !');
   Close(SourceASC);
   Halt;
  End;
  WriteLn(TargetABAP,'REPORT ABC00001.');
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetABAP,'WRITE: ','''','''')
                 Else WriteLn(TargetABAP,'WRITE: ''',StringToABAPString(CurrLine),'''.');
  End;
  Close(TargetABAP);
  Close(SourceASC);
 End
  Else
 Begin
  WriteLn(Output,'REPORT ABC00001.');
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,'WRITE: ','''','''')
                 Else WriteLn(Output,'WRITE: ''',StringToABAPString(CurrLine),'''.');
  End;
 End;
END.
