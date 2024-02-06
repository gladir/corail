{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program U2D;

Const
 TmpFile='U2D.TMP';

Var
 SourceText:Text;
 TargetData:File;
 CurrLine:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Write('U2D : Cette commande permet de convertir les sauts de ligne ',
        'UNIX en saut de ligne DOS.');
  WriteLn;
  WriteLn('Syntaxe : U2D nomdufichier');
 End
  Else
 If ParamCount=1Then Begin
  Assign(SourceText,ParamStr(1));
  Reset(SourceText);
  Assign(TargetData,TmpFile);
  Rewrite(TargetData,1);
  While NOT EOF(SourceText)do Begin
   ReadLn(SourceText,CurrLine);
   BlockWrite(TargetData,CurrLine[1],Length(CurrLine));
   CurrLine:=Chr(13)+Chr(10);
   BlockWrite(TargetData,CurrLine[1],2);
  End;
  Close(TargetData);
  Close(SourceText);
  {$I-}Assign(SourceText,ParamStr(1));
  Erase(SourceText);{$I+}
  {$I-}Assign(TargetData,TmpFile);
  Rename(TargetData,ParamStr(1));{$I+}
 End
  Else
 Begin
  WriteLn('Parametre invalide !');
 End;
END.

