{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CSPLIT;

Uses DOS;

Var
 Language:(_Albanian,_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 FileName,CurrLine,Prefix:String;
 SourceText,TargetText:Text;
 CurrFileNumber,CurrLineNumber,CurrSize:LongInt;
 I,SplitPos,SplitNumber:Integer;
 Err:Word;
 SplitLineNumber:Array[0..999]of LongInt;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

Function GetCurrSplitFileName:String;Begin
 GetCurrSplitFileName:=Prefix+PadZeroLeft(CurrFileNumber,2);
End;

Procedure ProcessLine;Begin
 WriteLn(TargetText,CurrLine);
 Inc(CurrSize,Length(CurrLine)+1);
 Inc(CurrLineNumber);
 If(SplitPos<SplitNumber)Then Begin
  If CurrLineNumber>=Pred(SplitLineNumber[SplitPos])Then Begin
   Close(TargetText);
   WriteLn(CurrSize);
   CurrSize:=0;
   Inc(SplitPos);
   Inc(CurrFileNumber);
   {$I-}Assign(TargetText,GetCurrSplitFileName);
   Rewrite(TargetText);{$I+}
   If IOResult<>0 Then Begin
    WriteLn('Impossible d''Çcrire le fichier ',GetCurrSplitFileName);
    Halt(2);
   End;
  End;
 End;
End;

BEGIN
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='SQ')or
    (StrToUpper(Copy(TmpLanguage,1,3))='ALB')Then Language:=_Albanian;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  Case Language of
   _English:Begin
    WriteLn('CSPLIT : Output pieces of FILE separated by PATTERN(s) to files ');
    WriteLn('         ''xx00'', ''xx01'', ..., and output byte counts of ');
    WriteLn('         each piece to standard output.');
    WriteLn;
    WriteLn('Read standard input if FILE is -');
    WriteLn;
    WriteLn('Syntax: csplit [OPTION]... FILE PATTERN...');
    WriteLn;
    WriteLn(' --prefix=PREFIX  Use PREFIX instead of ''xx''');
    WriteLn(' --help           Display this help and exit');
    WriteLn(' --version        Output version information and exit');
    WriteLn;
    WriteLn('Each PATTERN may be:');
    WriteLn(' INTEGER          Copy up to but not including ',
                               'specified line number');
    WriteLn(' {INTEGER}        Repeat the previous pattern specified ',
                               'number of times');
   End;
   Else Begin
    WriteLn('CSPLIT : Cette commande permet de sÇparer un fichier en ',
                     'plusieurs sections dÇterminÇ par des lignes de ',
                     'contextes.');
    WriteLn;
    WriteLn('Syntaxe : CSPLIT [options] fichier ligne[...]');
    WriteLn;
    WriteLn(' fichier          Nom du fichier Ö dÇcouper. Si le nom du fichier');
    WriteLn('                  est - alors il lit Ö partie de l''entrÇe standard.');
    WriteLn(' ligne[...]       Un ou des numÇros de lignes ou dÇcouper');
    WriteLn(' --help             Affiche l''aide de cette commande.');
    WriteLn(' --prefix=valeur  PrÇfixe pour les noms de fichiers Ö crÇer');
    WriteLn(' --version          Affiche la version de cette commande.');
   End;
  End;
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('CSPLIT 1.0 - Clone Pascal de coreutils, linux ou corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('êcrit par Sylvain Maltais');
 End
  Else
 Begin
  FillChar(SplitLineNumber,SizeOf(SplitLineNumber),0);
  FileName:='';
  Prefix:='xx';
  CurrFileNumber:=0;
  CurrLineNumber:=0;
  SplitLineNumber[0]:=1;
  SplitPos:=1;
  CurrSize:=0;
  For I:=1 to ParamCount do Begin
   If Copy(ParamStr(I),1,Length('--prefix='))='--prefix='Then Begin
    Prefix:=Copy(ParamStr(I),Length('--prefix=')+1,255);
   End
    Else
   If FileName=''Then FileName:=ParamStr(I)
    Else
   Begin
    Val(ParamStr(I),SplitLineNumber[SplitPos],Err);
    Inc(SplitPos);
   End;
  End;
  SplitNumber:=SplitPos;
  SplitPos:=1;
  If FileName='-'Then Begin
   {$I-}Assign(TargetText,GetCurrSplitFileName);
   Rewrite(TargetText);{$I+}
   If IOResult<>0 Then Begin
    WriteLn('Impossible d''Çcrire le fichier ',GetCurrSplitFileName);
    Halt(2);
   End;
   While Not EOF do Begin
    ReadLn(CurrLine);
    ProcessLine;
   End;
   WriteLn(CurrSize);
   Close(TargetText);
  End
   Else
  If FileName<>''Then Begin
   {$I-}Assign(SourceText,FileName);
   Reset(SourceText);{$I+}
   If IOResult<>0 Then Begin
    WriteLn('Impossible de lire le fichier ',FileName);
    Halt(1);
   End;
   {$I-}Assign(TargetText,GetCurrSplitFileName);
   Rewrite(TargetText);{$I+}
   If IOResult<>0 Then Begin
    WriteLn('Impossible d''Çcrire le fichier ',GetCurrSplitFileName);
    Halt(2);
   End;
   While Not EOF(SourceText)do Begin
    ReadLn(SourceText,CurrLine);
    ProcessLine;
   End;
   WriteLn(CurrSize);
   Close(TargetText);
   Close(SourceText);
  End
   Else
  WriteLn('Nom de fichier requis !');
 End;
END.