{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program DOS2UNIX;

Const
 TmpFile='DOS2UNIX.TMP';

Var
 SourceText:Text;
 TargetData:File {$IFDEF FPC}of Byte{$ENDIF};
 CurrLine:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Write('DOS2UNIX : Cette commande permet de convertir les sauts de ligne ',
        'DOS en saut de ligne UNIX.');
  WriteLn;
  WriteLn('Syntaxe : DOS2UNIX nomdufichier');
 End
  Else
 If ParamCount=1Then Begin
  Assign(SourceText,ParamStr(1));
  Reset(SourceText);
  Assign(TargetData,TmpFile);
  Rewrite(TargetData);
  While NOT EOF(SourceText)do Begin
   ReadLn(SourceText,CurrLine);
   BlockWrite(TargetData,CurrLine[1],Length(CurrLine));
   CurrLine:=Chr($0A);
   BlockWrite(TargetData,CurrLine[1],1);
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
