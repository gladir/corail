{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program Split;

Var
 NombreLigne,CurrLineNumber,CurrPrefix:Integer;
 Err:Word;
 FileSource,FileTarget:Text;
 Prefix,CurrLine:String;

Function GetCurrPrefixNumber:String;
Var
 S:String;
Begin
 Str(CurrPrefix,S);
 If Length(S)<2 Then S:='0'+S;
 If Length(S)<3 Then S:='0'+S;
 GetCurrPrefixNumber:='.'+S;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('SPLIT : Cette commande permet de separer un fichier en plusieurs fichiers.');
  WriteLn;
  WriteLn('Syntaxe : SPLIT nombredeligne fichiersource [prefixe]');
 End
  Else
 If ParamCount>=2Then Begin
  Val(ParamStr(1),NombreLigne,Err);
  If NombreLigne=0Then Begin
   WriteLn('Le nombre de ligne doit superieur a 0 !');
  End
   Else
  Begin
   CurrPrefix:=1;
   CurrLineNumber:=1;
   If(ParamCount>=3)and(ParamStr(3)<>'')Then Begin
    Prefix:=ParamStr(3);
   End
    Else
   Prefix:='FILESPLT';
   Assign(FileSource,ParamStr(2));
   {$I-}Reset(FileSource);{$I+}
   If IOResult=0Then Begin
    Assign(FileTarget,Prefix+GetCurrPrefixNumber);
    Rewrite(FileTarget);
    While Not EOF(FileSource)do Begin
     ReadLn(FileSource,CurrLine);
     WriteLn(FileTarget,CurrLine);
     Inc(CurrLineNumber);
     If CurrLineNumber>NombreLigne Then Begin
      CurrLineNumber:=1;
      Close(FileTarget);
      Inc(CurrPrefix);
      Assign(FileTarget,Prefix+GetCurrPrefixNumber);
      Rewrite(FileTarget);
     End;
    End;
    Close(FileTarget);
    Close(FileSource);
   End
    Else
   WriteLn('Impossible de lire le fichier');
  End;
 End
  Else
 WriteLn('Nombre de parametres insuffisant !');
END.