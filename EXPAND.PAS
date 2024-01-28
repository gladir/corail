{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program EXPAND;

Uses DOS;

Var
 Language:(_Albanian,_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 ReadFromConsole,FirstOnly,ConvertEntireLine,LeaveEOL:Boolean;
 FileRead:Text;
 I,J,TabSize:Integer;
 Err:Word;
 CurrLine,FileName:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function LTrim(s:String):String;
Var
 i:Integer;
Begin
 i:=1;
 While(i<=Length(s)) and (s[i] in [#9,' ']) do Inc(i);
 Delete(s,1,i-1);
 LTrim:=s;
End;

Function RTrim(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 RTrim:=S;
End;

Function Trim(s:String):String;Begin
 Trim:=LTrim(RTrim(s));
End;

Function IsBlank(C:Char):Boolean;Begin
 IsBlank:=C in[#9,' '];
End;

Procedure ProcessLine;
Var
 First,Convert:Boolean;
Begin
 If Not(LeaveEol)Then CurrLine:=RTrim(CurrLine);
 If Not(FirstOnly)Then Begin
  For J:=1 to Length(CurrLine)do Begin
   If CurrLine[J]=#9 Then Write(' ':TabSize)
                     Else Write(CurrLine[J]);
  End;
 End
  Else
 If(ConvertEntireLine)Then Begin
  First:=True;
  For J:=1 to Length(CurrLine)do Begin
   If CurrLine[J]=#9 Then Begin
    If(First)Then Begin
     Write(' ':TabSize);
     First:=False;
    End
     Else
    Write(#9);
   End
    Else
   Write(CurrLine[J]);
  End;
 End
  Else
 Begin
  Convert:=True;
  For J:=1 to Length(CurrLine)do Begin
   If CurrLine[J]=#9 Then Begin
    If(Convert)Then Write(' ':TabSize)
               Else Write(#9);
   End
    Else
   Write(CurrLine[J]);
   Convert:=Convert and(ConvertEntireLine or IsBlank(CurrLine[J]));
  End;
 End;
 WriteLn;
End;

BEGIN
 FileName:='';
 TabSize:=8;
 LeaveEOL:=True;
 ReadFromConsole:=True;
 ConvertEntireLine:=True;
 FirstOnly:=False;
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
    WriteLn('EXPAND : Convert tabs in each FILE to spaces, writing to ',
                      'standard output.');
    WriteLn;
    WriteLn('Syntax: EXPAND file [option]');
    WriteLn;
    WriteLn(' file           Indicate the name of the file to process');
    WriteLn(' --firstonly    Remove only first tabulation of each line');
    WriteLn(' --help         Display this help and exit');
    WriteLn(' -i, --initial  Do not convert tabs after non blanks');
    WriteLn(' --eol          Remove trailling spaces');
    WriteLn(' --tabs=x       Have tabs N characters apart, not 8');
    WriteLn(' --version      Output version information and exit');
   End;
   Else Begin
    WriteLn('EXPAND : Cette commande permet de convertir des ',
                      'tabulations en espaces');
    WriteLn;
    WriteLn('Syntaxe : EXPAND fichier [option]');
    WriteLn;
    WriteLn(' fichier     Indique le nom du fichier … traiter');
    WriteLn(' -i          Ne pas convertir les tabulations aprŠs des espaces non vides');
    WriteLn(' --firstonly EnlŠve seulement la premiŠre tabulation de chaque ligne');
    WriteLn(' --help      Affiche l''aide sur cette commande');
    WriteLn(' --initial   Ne pas convertir les tabulations aprŠs des espaces non vides');
    WriteLn(' --eol       EnlŠve les espaces en fin de ligne');
    WriteLn(' --tabs=x    Indique le nombre d''espace pour une tabulation');
    WriteLn(' --version   Affiche la version de cette commande.');
   End;
  End;
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('EXPAND 1.0 - Clone Pascal de coreutils, linux ou corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('crit par Sylvain Maltais');
 End
  Else
 If ParamCount>0 Then Begin
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='--firstonly'Then FirstOnly:=True Else
   If(ParamStr(I)='-i')or(ParamStr(I)='--initial')Then ConvertEntireLine:=False Else
   If ParamStr(I)='--eol'Then LeaveEol:=False Else
   If Copy(ParamStr(I),1,Length('--tabs='))='--tabs='Then Begin
    Val(Copy(ParamStr(I),Length('--tabs=')+1,255),TabSize,Err);
    If Err>0 Then Begin
     Write('expand: ');
     Case Language of
      _English:WriteLn('Tab size contains invalid character(s): ''abs=',
                       Copy(ParamStr(I),Length('--tabs=')+1,255),'''');
      Else WriteLn('Valeur de tabulation contient une taille de tabulation invalide: ',
                    Copy(ParamStr(I),Length('--tabs=')+1,255));
     End;
     Halt(2);
    End;
    If TabSize=0 Then Begin
     Write('expand: ');
     Case Language of
      _English:WriteLn('Tab size cannot be 0');
      Else WriteLn('La taille de la tabulation ne peut pas ˆtre 0');
     End;
     Halt(3);
    End;
   End;
  End;
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='-i')or(ParamStr(I)='--initial')Then Begin
    { Saute ... }
   End
    Else
   If(ParamStr(I)='--eol')or(ParamStr(I)='--firstonly')Then Begin
    { Saute ... }
   End
    Else
   If Copy(ParamStr(I),1,Length('--tabs='))='--tabs='Then Begin
    { Saute ... }
   End
    Else
   Begin
    ReadFromConsole:=False;
    FileName:=ParamStr(I);
    {$I-}Assign(FileRead,FileName);
    Reset(FileRead);{$I+}
    If IoResult=0 Then Begin
     While Not EOF(FileRead)do Begin
      ReadLn(FileRead,CurrLine);
      ProcessLine;
     End;
     Close(FileRead);
    End
     Else
    Begin
     Write('expand: ',FileName,': ');
     Case Language of
      _English:WriteLn('No such file or directory');
      Else WriteLn('Erreur de lecture du fichier');
     End;
     Halt(1);
    End;
   End;
  End;
  If(ReadFromConsole)Then Begin
   While Not EOF do Begin
    ReadLn(CurrLine);
    ProcessLine;
   End;
  End;
 End
  Else
 Begin
  While Not EOF do Begin
   ReadLn(CurrLine);
   ProcessLine;
  End;
 End;
END.
