{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program TXT2RTF;

Var
 F:Text;
 I:Integer;
 CurrLine:String;

Procedure PrintRTFBegin;Begin
 WriteLn('\par \pard\plain \s0\nowidctlpar{\*\hyphen2\hyphlead2\hyphtrail2\hyphmax0}',
         '\cf0\kerning1\dbch\af5\langfe2052\dbch\af6\afs24\alang1081\loch\f0\fs24',
         '\lang2070{\rtlch \ltrch\loch');
End;

Procedure PrintRTFEnd;Begin
 WriteLn(' }');
End;

Procedure EndRTF;Begin
 WriteLn('\par }');
End;

Procedure Par;Begin
 WriteLn('{\*\ftnsep\chftnsep}\pgndec\pard\plain ',
         '\s20\sb0\sa0\dbch\af8\dbch\af5\afs20\loch\f0\fs20');
End;

Procedure Info;Begin
 WriteLn('\info{\creatim\yr0\mo0\dy0\hr0\min0}{\revtim\yr2021\',
         'mo1\dy17\hr1\min47}{\printim\yr0\mo0\dy0\hr0\min0}{\',
         'comment txt2rtf}{\vern67306242}}\deftab709');
 WriteLn('\viewscale100');
End;

Procedure Txt;Begin
 WriteLn('{\s20\sbasedon0\snext20\sb0\sa0\dbch\af8\dbch\af5\',
         'afs20\loch\f5\fs20 Preformatted Text;}');
End;

Procedure Body;Begin
 WriteLn('{\s16\sbasedon0\snext16\sl288\slmult1\sb0\sa140 Text Body;}');
End;

Procedure Head;Begin
 WriteLn('\s15\sbasedon0\snext16\sb240\sa120\keepn\dbch\af7\dbch',
         '\af9\afs28\loch\f4\fs28 Heading;}');
End;

Procedure Style;Begin
 WriteLn('{\stylesheet{\s0\snext0\nowidctlpar{\*\hyphen2\hyphlead2\',
         'hyphtrail2\hyphmax0}\cf0\dbch\af7\langfe2052\dbch\af9\afs24\',
         'alang1081\loch\f3\fs24\lang2070 Normal;}');
End;

Procedure Color;Begin
 WriteLn('{\colortbl;\red0\green0\blue128;\red0\green128\blue128;}');
End;

Procedure Font;Begin
 WriteLn('{\fonttbl{\f0\froman\fprq2\fcharset0 Free Mono;}}');
End;

Procedure RTF;Begin
 WriteLn('{\rtf1\ansi\deff3\adeflang1025');
End;


BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('TXT2RTF : Cette commande permet de convertir un fichier TXT ',
                     'en format RTF.');
  WriteLn;
  WriteLn('Syntaxe : TXT2RTF source.txt');
  WriteLn;
  WriteLn(' source.txt   Nom du fichier a convertir');
  WriteLn;
 End
  Else
 If ParamCount>0 Then Begin
  RTF;
  Font;
  Color;
  Style;
  Head;
  Body;
  Txt;
  Info;
  Par;
  {$I-}Assign(F,ParamStr(1));
  Reset(F);{$I+}
  If IOResult=0 Then Begin
   PrintRTFBegin;
   While Not EOF(F)do Begin
    ReadLn(F,CurrLine);
    If CurrLine=''Then Begin
     PrintRTFEnd;
     PrintRTFBegin;
    End;
    For I:=1 to Length(CurrLine)do Begin
     Case CurrLine[I]of
      #12:Write('\page');
      '\':Write('\\');
      '{':Write('\{');
      '}':Write('\}');
      Else Write(CurrLine[I]);
     End;
    End;
    WriteLn;
   End;
  End
   Else
  Begin
   WriteLn('Erreur de lecture du fichier ',ParamStr(1));
   Halt(2);
  End;
  PrintRTFEnd;
  Close(F);
  EndRTF;
 End
  Else
 Begin
  WriteLn('Paramätre attendu !');
  Halt(1);
 End;
END.
