{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program FMT;

Uses DOS;

Var
 Language:(_Albanian,_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 ModeParam:Set of (UniformSpacing);
 ReadFromConsole:Boolean;
 I,J:Integer;
 Found:Boolean;
 SourceText:Text;
 Width,Err:Word;
 CurrLine,CurrBuffer:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function Replace(Source,Old,New:String):String;
Var
 P:LongInt;
Begin
 While Pos(Old,Source)<>0 do Begin
  P:=Pos(Old,Source);
  Delete(Source,P,Length(Old));
  Insert(New,Source,P);
 End;
 Replace:=Source;
End;

Procedure ProcessLine;Begin
 If Length(CurrBuffer)>0 Then Begin
  If Not(CurrBuffer[Length(CurrBuffer)]in[#9,' '])Then CurrBuffer:=CurrBuffer+' ';
 End;
 CurrBuffer:=CurrBuffer+CurrLine;
 If(UniformSpacing in ModeParam)Then Begin
  CurrBuffer:=Replace(CurrBuffer,#32#32,#32);
 End;
 If CurrLine=''Then Begin
  WriteLn(CurrBuffer);
  WriteLn;
  CurrBuffer:='';
 End;
 While(Length(CurrBuffer)>Width)do Begin
  Found:=False;
  For J:=Width downto 1 do Begin
   If J<=Length(CurrBuffer)Then Begin
    If CurrBuffer[J]in[#9,' ']Then Begin
     Found:=True;
     Break;
    End;
   End;
  End;
  If Not(Found)Then Begin
   For J:=Width to Length(CurrBuffer)do Begin
    If CurrBuffer[J]in[#9,' ']Then Begin
     Found:=True;
     Break;
    End;
   End;
  End;
  If(Found)Then Begin
   WriteLn(Copy(CurrBuffer,1,J));
   CurrBuffer:=Copy(CurrBuffer,J+1,255);
  End
   Else
  Break;
 End;
End;

BEGIN
 ReadFromConsole:=True;
 ModeParam:=[];
 Width:=75;
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
    WriteLn('FMT : Reformat each paragraph in the FILE(S), ',
                   'writing to standard output');
    WriteLn;
    WriteLn('Syntax: FMT [option] file');
    WriteLn;
    WriteLn(' file               Indicate the name of the file to process');
    WriteLn(' --uniform-spacing  One space between words');
    WriteLn(' --width=WIDTH      Maximum line width (default of 75 columns');
    WriteLn(' --version          Output version information and exit');
   End;
   Else Begin
    WriteLn('FMT : Cette commande permet de reformater le ',
                   'texte du paragraphe.');
    WriteLn;
    WriteLn('Syntaxe : FMT [option] fichier');
    WriteLn;
    WriteLn(' fichier            Indique le nom du fichier … traiter');
    WriteLn(' --uniform-spacing  Un espace entre les mots');
    WriteLn(' --width=WIDTH      Indique la largeur d''une ligne (la ');
    WriteLn('                    valeur par d‚faut est 75 colonnes)');
    WriteLn(' --version          Affiche la version de cette commande.');
   End;
  End;
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('FMT 1.0 - Clone Pascal de coreutils, linux ou corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('crit par Sylvain Maltais');
 End
  Else
 If ParamCount>0 Then Begin
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='-u')or(ParamStr(I)='--uniform-spacing')Then Begin
    Include(ModeParam,UniformSpacing);
   End
    Else
   If Copy(ParamStr(I),1,Length('--width='))='--width='Then Begin
    Val(Copy(ParamStr(I),Length('--width=')+1,255),Width,Err);
    If Err>0 Then Begin
     WriteLn('Valeur invalide !');
     Halt(2);
    End;
    If(Width=0)Then Begin
     WriteLn('La largeur ne peut pas ˆtre z‚ro');
     Halt(3);
    End;
    If(Width>250)Then Begin
     WriteLn('La largeur ne peut pas ˆtre sup‚rieur … 250 caractŠres');
     Halt(3);
    End;
   End;
  End;
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='-u')or(ParamStr(I)='--uniform-spacing')or
     (Copy(ParamStr(I),1,Length('--width='))='--width=')Then Begin
    { Saute ... }
   End
    Else
   Begin
    ReadFromConsole:=False;
    {$I-}Assign(SourceText,ParamStr(I));
    Reset(SourceText);{$I+}
    If IOResult<>0 Then Begin
     WriteLn('Impossible de lire le fichier ',ParamStr(I));
     Halt(1);
    End;
    CurrBuffer:='';
    While Not EOF(SourceText)do Begin
     ReadLn(SourceText,CurrLine);
     ProcessLine;
    End;
    WriteLn(CurrBuffer);
    Close(SourceText);
   End;
  End;
  If(ReadFromConsole)Then Begin
   Repeat
    ReadLn(Input,CurrLine);
    ProcessLine;
   Until EOF;
   WriteLn(CurrLine);
  End;
 End
  Else
 Begin
  Repeat
   ReadLn(Input,CurrLine);
   ProcessLine;
  Until EOF;
  WriteLn(CurrLine);
 End;
END.