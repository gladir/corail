{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program ASC2LOGO(Input,Output);

Var
 SourceASC,TargetLogo:Text;
 CurrLine:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('ASC2LOGO : Cette commande permet de transformer du texte en code source Logo.');
  WriteLn;
  WriteLn('Syntaxe : ASC2LOGO nomdufichier.asc nomdufichier.LGO');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceASC,ParamStr(1));
  {$I-}Reset(SourceASC);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier ASCII introuvable !');
   Halt;
  End;
  Assign(TargetLOGO,ParamStr(2));
  {$I+}Rewrite(TargetLOGO); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier Logo !');
   Close(SourceASC);
   Halt;
  End;
  While Not EOF(SourceASC)do Begin
   ReadLn(SourceASC,CurrLine);
   If CurrLine=''Then WriteLn(TargetLOGO,'PRINT []')
                 Else WriteLn(TargetLOGO,'PRINT [',CurrLine,']');
  End;
  Close(TargetLOGO);
  Close(SourceASC);
 End
  Else
 Begin
  While Not EOF(SourceASC)do Begin
   ReadLn(Input,CurrLine);
   If CurrLine=''Then WriteLn(Output,'PRINT []')
                 Else WriteLn(Output,'PRINT [',CurrLine,']');
  End;
 End;
END.


