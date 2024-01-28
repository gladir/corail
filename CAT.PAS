{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program CAT(Input,Output);

Uses DOS;

Var
 Language:(_Albanian,_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 ModeParam:Set of (CStr,Lower,Hex,Html,Number,NumberNonblank,PascalStr,
                   SqueezeBlank,ShowEnd,ShowTab,ShowNonprinting,
                   TrimLine,Uniq,Upper);
 ReadFromConsole:Boolean;
 I,J:Integer;
 LineNumber:LongInt;
 ShowLine,Found:Boolean;
 Handle:Text;
 Info:SearchRec;
 CurrDir,LastLine,CurrLine:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function StrToLower(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
 End;
 StrToLower:=S;
End;

Function TrimL(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If S[I]<>' 'Then Begin
   TrimL:=Copy(S,I,255);
   Exit;
  End;
 End;
 TrimL:=S;
End;

Function TrimR(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 TrimR:=S;
End;

Function Trim(s:String):String;Begin
 Trim:=TrimL(TrimR(s));
End;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function Path2Dir(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 Path2Dir:='';
 If Path=''Then Exit;
 FSplit(Path,D,N,E);
 If E=''Then Begin
  If D[Length(D)]<>'\'Then D:=D+'\';
  D:=D+E;
 End;
 If D=''Then Path2Dir:='' Else
 If D[Length(D)]<>'\'Then D:=D+'\';
 Path2Dir:=D;
End;

Procedure ProcessLine;Begin
 ShowLine:=True;
 If(SqueezeBlank in ModeParam)Then Begin
  If(CurrLine=LastLine)and(CurrLine='')Then ShowLine:=False;
 End
  Else
 If(Uniq in ModeParam)Then Begin
  If(CurrLine=LastLine)Then ShowLine:=False;
 End;
 If(ShowLine)Then Begin
  If(Number in ModeParam)Then Begin
   Inc(LineNumber);
   Write(LineNumber:6,' ':2);
  End
   Else
  If CurrLine<>''Then Begin
   Inc(LineNumber);
   If(NumberNonblank in ModeParam)Then Write(LineNumber:6,' ':2);
  End;
  If(Upper in ModeParam)Then CurrLine:=StrToUpper(CurrLine) Else
  If(Lower in ModeParam)Then CurrLine:=StrToLower(CurrLine);
  If(TrimLine in ModeParam)Then CurrLine:=Trim(CurrLine);
  If(Hex in ModeParam)Then Begin
   For J:=1 to Length(CurrLine)do Write(ByteHex2Str(Byte(CurrLine[J])));
  End
   Else
  If(Html in ModeParam)Then Begin
   For J:=1 to Length(CurrLine)do Begin
    Case CurrLine[J]of
    '&':Write('&amp;');
    '<':Write('&lt;');
    '>':Write('&gt;');
    '"':Write('&quot;');
     Else Write(CurrLine[J]);
    End;
   End;
   Write('<br />');
  End
   Else
  If(PascalStr in ModeParam)Then Begin
   Write('''');
   For J:=1 to Length(CurrLine)do Begin
    Case CurrLine[J]of
     #0:Write('''+#0+''');
     #1..#26:Write('''+^',Chr(64+Byte(CurrLine[I])),'+''');
     #27..#31:Write('''+#',Byte(CurrLine[I]),'+''');
     '''':Write('''','''');
     Else Write(CurrLine[J]);
    End;
   End;
   Write('''');
  End
   Else
  If(CStr in ModeParam)Then Begin
   Write('"');
   For J:=1 to Length(CurrLine)do Begin
    Case CurrLine[J]of
     #0:Write('\0');
     #1..#6,#14..#31:Write('\x',ByteHex2Str(Byte(CurrLine[I])));
     #7:Write('\a');
     #8:Write('\b');
     #9:Write('\t');
     #10:Write('\n');
     #11:Write('\v');
     #12:Write('\f');
     #13:Write('\r');
     '\':Write('\\');
     '''':Write('\''');
     '"':Write('\"');
     '?':Write('\?');
     Else Write(CurrLine[J]);
    End;
   End;
   Write('"');
  End
   Else
  If(ShowNonprinting in ModeParam)Then Begin
   For J:=1 to Length(CurrLine)do Begin
    Case CurrLine[J]of
     #0..#8,#10..#31:Write('^',Chr(Byte(CurrLine[J])+64));
     #9:Write(#9);
     #127:Write('^?');
     #128..#159:Write('M-^',Chr(Byte(CurrLine[J])-128+64));
     #160..#254:Write('M-',Chr(Byte(CurrLine[J])-128));
     #255:Write('M-^?');
     Else Write(CurrLine[J]);
    End;
   End;
  End
   Else
  If(ShowTab in ModeParam)Then Begin
   For J:=1 to Length(CurrLine)do Begin
    Case CurrLine[J]of
     #9:Write('^I');
     Else Write(CurrLine[J]);
    End;
   End;
  End
   Else
  Write(CurrLine);
  If(ShowEnd in ModeParam)Then Write('$');
  WriteLn;
 End;
 LastLine:=CurrLine;
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
    WriteLn('CAT : Concatenate FILE(s) to standard output.');
    WriteLn;
    WriteLn('Syntax: cat [OPTION]... [FILE]...');
    WriteLn;
    WriteLn(' -A, --show-all           Equivalent to -vET');
    WriteLn(' -b, --number-nonblank    Number nonempty output lines, overrides -n');
    WriteLn(' -e                       Equivalent to -vE');
    WriteLn(' -E, --show-ends          Display $ at end of each line');
    WriteLn(' -n, --number             Number all output lines');
    WriteLn(' -s, --squeeze-blank      Suppress repeated empty output lines');
    WriteLn(' -t                       Equivalent to -vT');
    WriteLn(' -T, --show-tabs          Display TAB characters as ^I');
    WriteLn(' -u                       (ignored)');
    WriteLn(' -v, --show-nonprinting   Use ^ and M- notation, except for LFD and TAB');
    WriteLn(' --c                      Display each line in C string');
    WriteLn(' --help                   Display this help and exit');
    WriteLn(' --hex                    Display each line in hexadecimal');
    WriteLn(' --html                   Display each line in HTML');
    WriteLn(' --lower                  Lower each line');
    WriteLn(' --pascal                 Display each line in Pascal string');
    WriteLn(' --trim                   Trim each line');
    WriteLn(' --uniq                   Displays once lines are duplicated');
    WriteLn(' --upper                  Upper each line');
    WriteLn(' --version                Output version information and exit');
   End;
   Else Begin
    WriteLn('CAT : Cette commande permet d''afficher le contenu du fichier.');
    WriteLn;
    WriteLn('Syntaxe : CAT [option] [fichier]');
    WriteLn;
    WriteLn(' fichier            Indique le nom du fichier … afficher.');
    WriteLn(' -A                 Equivalent de -vET');
    WriteLn(' -b                 Affiche les num‚ros de ligne si la ligne n''est pas vide');
    WriteLn(' -E                 Affiche un caractŠre $ … la fin d''une ligne.');
    WriteLn(' -e                 Equivalent de -vE');
    WriteLn(' -n                 Affiche les num‚ros de ligne');
    WriteLn(' -s                 EnlŠve les duplications de ligne blanche');
    WriteLn(' -T                 Affiche un ^I … la place d''une tabulation.');
    WriteLn(' -v                 Utilise des notations ^ et M- pour les caractŠres');
    WriteLn('                    non imprimable');
    WriteLn(' --c                Affiche chacune des lignes en chaŒne de caractŠres C');
    WriteLn(' --help             Affiche l''aide de cette commande');
    WriteLn(' --hex              Affiche chacune des lignes en hexad‚cimal');
    WriteLn(' --html             Affiche chacune des lignes en HTML');
    WriteLn(' --lower            Met en minuscule chacune des lignes');
    WriteLn(' --number           Affiche les num‚ros de ligne');
    WriteLn(' --number-nonblank  Affiche les num‚ros de ligne si la ligne n''est pas vide');
    WriteLn(' --pascal           Affiche chacune des lignes en chaŒne de caractŠres Pascal');
    WriteLn(' --show-all         Equivalent de -vET');
    WriteLn(' --show-nonprinting Utilise des notations ^ et M- pour les caractŠres');
    WriteLn('                    non imprimable');
    WriteLn(' --show-tabs        Affiche un ^I … la place d''une tabulation.');
    WriteLn(' --squeeze-blank    EnlŠve les duplications de ligne blanche');
    WriteLn(' --trim             EnlŠve les espaces au d‚but … la fin de chacun des lignes');
    WriteLn(' --uniq             Affiche une fois les lignes dupliqu‚');
    WriteLn(' --upper            Met en majuscule chacune des lignes');
    WriteLn(' --version          Demande la version de la commande');
   End;
  End;
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('CAT 2.0 - Clone Pascal de coreutils, linux, unix ou corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('crit par Sylvain Maltais');
 End
  Else
 If ParamCount>0Then Begin
  ReadFromConsole:=True;
  ModeParam:=[];
  LastLine:='';
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='-E'Then Include(ModeParam,ShowEnd) Else
   If(ParamStr(I)='-A')or(ParamStr(I)='--show-all')Then Begin
    Include(ModeParam,ShowNonprinting);
    Include(ModeParam,ShowEnd);
    Include(ModeParam,ShowTab)
   End
    Else
   If(ParamStr(I)='--c')Then Include(ModeParam,CStr) Else
   If(ParamStr(I)='-e')Then Begin
    Include(ModeParam,ShowNonprinting);
    Include(ModeParam,ShowEnd);
   End
    Else
   If(ParamStr(I)='--hex')Then Include(ModeParam,Hex) Else
   If(ParamStr(I)='--html')Then Include(ModeParam,Html) Else
   If(ParamStr(I)='--lower')Then Include(ModeParam,Lower) Else
   If(ParamStr(I)='-n')or(ParamStr(I)='--number')Then Include(ModeParam,Number)Else
   If(ParamStr(I)='-b')or(ParamStr(I)='--number-nonblank')Then Include(ModeParam,NumberNonblank)Else
   If(ParamStr(I)='--pascal')Then Include(ModeParam,PascalStr) Else
   If(ParamStr(I)='-v')or(ParamStr(I)='--show-nonprinting')Then Include(ModeParam,ShowNonprinting)Else
   If(ParamStr(I)='-T')or(ParamStr(I)='--show-tabs')Then Include(ModeParam,ShowTab) Else
   If(ParamStr(I)='-s')or(ParamStr(I)='--squeeze-blank')Then Include(ModeParam,SqueezeBlank)Else
   If(ParamStr(I)='--trim')Then Include(ModeParam,TrimLine) Else
   If(ParamStr(I)='--uniq')Then Include(ModeParam,Uniq) Else
   If(ParamStr(I)='--upper')Then Include(ModeParam,Upper);
  End;
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='-A')or(ParamStr(I)='--show-all')or
     (ParamStr(I)='--c')or
     (ParamStr(I)='-E')or(ParamStr(I)='-e')or(ParamStr(I)='-u')or
     (ParamStr(I)='--hex')or
     (ParamStr(I)='--html')or
     (ParamStr(I)='--lower')or
     (ParamStr(I)='-n')or(ParamStr(I)='--number')or
     (ParamStr(I)='-b')or(ParamStr(I)='--number-nonblank')or
     (ParamStr(I)='--pascal')or
     (ParamStr(I)='-v')or(ParamStr(I)='--show-nonprinting')or
     (ParamStr(I)='-T')or(ParamStr(I)='--show-tabs')or
     (ParamStr(I)='--trim')or
     (ParamStr(I)='-s')or(ParamStr(I)='--squeeze-blank')or
     (ParamStr(I)='--uniq')or
     (ParamStr(I)='--upper')Then Begin
    { Saute ... }
   End
    Else
   Begin
    Found:=False;
    CurrDir:=Path2Dir(FExpand(ParamStr(I)));
    FindFirst(ParamStr(I),AnyFile,Info);
    While DOSError=0 do Begin
     Found:=True;
     ReadFromConsole:=False;
     Assign(Handle,CurrDir+Info.Name);
     {$I-}Reset(Handle);{$I+}
     If IOResult=0Then Begin
      LineNumber:=0;
      While NOT EOF(Handle)do Begin
       ReadLn(Handle,CurrLine);
       ProcessLine;
      End;
      Close(Handle);
     End
      Else
     Begin
      Write('cat: ');
      Write(ParamStr(I));
      Case Language of
       _English:WriteLn('Unable to read file');
       Else WriteLn('Impossible de lire le fichier');
      End;
      Halt(1);
     End;
     FindNext(Info);
    End;
    If Not(Found)Then Begin
     Write('cat: ');
     Write(ParamStr(I));
     Case Language of
      _English:WriteLn('No such file or directory');
      Else WriteLn(': Aucune correspondance de fichier ou de r‚pertoire.');
     End;
     Halt(2);
    End;
   End;
  End;
  If(ReadFromConsole)Then Begin
   LineNumber:=0;
   Repeat
    ReadLn(Input,CurrLine);
    ProcessLine;
   Until EOF;
  End;
 End
  Else
 Begin
  Repeat
   ReadLn(Input,CurrLine);
   WriteLn(CurrLine);
  Until EOF;
 End;
END.
