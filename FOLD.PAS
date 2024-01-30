{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program FOLD;

Uses DOS;

Var
 Language:(_Albanian,_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 ReadFromConsole:Boolean;
 Width,Err:Word;
 Bytes:Boolean;
 I:Integer;
 SourceText:Text;
 CurrLine:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Procedure ProcessLine;
Var
 J,LenWidth:Integer;
 CurrWord:String;
Begin
 If(Length(CurrLine)>Width)Then Begin
  CurrWord:='';
  If(Bytes)Then Begin
   For J:=1 to Length(CurrLine)do Begin
    CurrWord:=CurrWord+CurrLine[J];
    If(Length(CurrWord)>=Width)Then Begin
     WriteLn(CurrWord);
     CurrWord:='';
    End;
   End;
  End
   Else
  Begin
   LenWidth:=0;
   For J:=1 to Length(CurrLine)do Begin
    CurrWord:=CurrWord+CurrLine[J];
    Case CurrLine[J]of
     #9:Inc(LenWidth,8);
     Else Inc(LenWidth);
    End;
    If(LenWidth>=Width)Then Begin
     WriteLn(CurrWord);
     CurrWord:='';
    End;
   End;
  End;
  WriteLn(CurrWord);
 End
  Else
 WriteLn(CurrLine);
End;

BEGIN
 Width:=80;
 Bytes:=False;
 ReadFromConsole:=True;
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
    WriteLn('FOLD : Wrap input lines in each FILE, writing ',
                   'to standard input');
    WriteLn;
    WriteLn('Syntax: FOLD [option] file');
    WriteLn;
    WriteLn(' file               Indicate the name of the file to process');
    WriteLn(' -b, --bytes        Count bytes rather than columns');
    WriteLn(' --help             Display this help and exit');
    WriteLn(' --width=WIDTH      Use width column  instead of 80');
    WriteLn(' --version          Output version information and exit');
   End;
   Else Begin
    WriteLn('FOLD : Cette commande permet d''envelopper les ',
                    'lignes d''entr‚e pour s''adapter … la ',
                    'largeur sp‚cifi‚e.');
    WriteLn;
    WriteLn('Syntaxe : FOLD [option] fichier');
    WriteLn;
    WriteLn(' fichier            Indique le nom du fichier … traiter');
    WriteLn(' -b                 Compte les octets plut“t que les colonnes');
    WriteLn(' --bytes            Compte les octets plut“t que les colonnes');
    WriteLn(' --help             Affiche l''aide de cette commande.');
    WriteLn(' --width=WIDTH      Indique la largeur.');
    WriteLn(' --version          Affiche la version de cette commande.');
   End;
  End;
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('FOLD 1.0 - Clone Pascal de coreutils, linux ou corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('crit par Sylvain Maltais');
 End
  Else
 If ParamCount>0 Then Begin
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='-b')or(ParamStr(I)='--bytes')Then Begin
    Bytes:=True;
   End
    Else
   If Copy(ParamStr(I),1,Length('-b'))='-b'Then Begin
    Bytes:=True;
    Val(Copy(ParamStr(I),Length('-b')+1,255),Width,Err);
   End
    Else
   If Copy(ParamStr(I),1,Length('--width='))='--width='Then Begin
    Val(Copy(ParamStr(I),Length('--width=')+1,255),Width,Err);
   End;
  End;
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='-b')or(ParamStr(I)='--bytes')or
     (Copy(ParamStr(I),1,Length('-b'))='-b')or
     (Copy(ParamStr(I),1,Length('--width='))='--width=')Then Begin
    { Saute ...}
   End
    Else
   Begin
    {$I-}Assign(SourceText,ParamStr(I));
    Reset(SourceText);{$I+}
    ReadFromConsole:=False;
    If IOResult<>0 Then Begin
     WriteLn('Impossible de lire le fichier ',ParamStr(I));
     Halt(1);
    End;
    While Not EOF(SourceText)do Begin
     ReadLn(SourceText,CurrLine);
     ProcessLine;
    End;
    Close(SourceText);
   End;
   If(ReadFromConsole)Then Begin
    Repeat
     ReadLn(Input,CurrLine);
     ProcessLine;
    Until EOF;
   End;
  End;
 End
  Else
 Begin
  Repeat
   ReadLn(Input,CurrLine);
   ProcessLine;
  Until EOF;
 End;
END.