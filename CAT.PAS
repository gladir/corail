{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program CAT(Input,Output);

Uses DOS;

Var
 ModeParam:Set of (Number,NumberNonblank,SqueezeBlank,ShowEnd,
                   ShowTab,ShowNonprinting,Uniq);
 I,J:Integer;
 LineNumber:LongInt;
 ShowLine,Found:Boolean;
 Handle:Text;
 Info:SearchRec;
 CurrDir,LastLine,CurrLine:String;

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

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
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
  WriteLn(' --help             Affiche l''aide de cette commande');
  WriteLn(' --number           Affiche les num‚ros de ligne');
  WriteLn(' --number-nonblank  Affiche les num‚ros de ligne si la ligne n''est pas vide');
  WriteLn(' --show-all         Equivalent de -vET');
  WriteLn(' --show-nonprinting Utilise des notations ^ et M- pour les caractŠres');
  WriteLn('                    non imprimable');
  WriteLn(' --show-tabs        Affiche un ^I … la place d''une tabulation.');
  WriteLn(' --squeeze-blank    EnlŠve les duplications de ligne blanche');
  WriteLn(' --uniq             Affiche une fois les lignes dupliqu‚');
  WriteLn(' --version          Demande la version de la commande');
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('CAT 2.0 - Clone Pascal de coreutils');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('crit par Sylvain Maltais');
 End
  Else
 If ParamCount>0Then Begin
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
   If(ParamStr(I)='-e')Then Begin
    Include(ModeParam,ShowNonprinting);
    Include(ModeParam,ShowEnd);
   End
    Else
   If(ParamStr(I)='-n')or(ParamStr(I)='--number')Then Include(ModeParam,Number)Else
   If(ParamStr(I)='-b')or(ParamStr(I)='--number-nonblank')Then Include(ModeParam,NumberNonblank)Else
   If(ParamStr(I)='-v')or(ParamStr(I)='--show-nonprinting')Then Include(ModeParam,ShowNonprinting)Else
   If(ParamStr(I)='-T')or(ParamStr(I)='--show-tabs')Then Include(ModeParam,ShowTab) Else
   If(ParamStr(I)='-s')or(ParamStr(I)='--squeeze-blank')Then Include(ModeParam,SqueezeBlank)Else
   If(ParamStr(I)='--uniq')Then Include(ModeParam,Uniq);
  End;
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='-A')or(ParamStr(I)='--show-all')or
     (ParamStr(I)='-E')or(ParamStr(I)='-e')or
     (ParamStr(I)='-n')or(ParamStr(I)='--number')or
     (ParamStr(I)='-b')or(ParamStr(I)='--number-nonblank')or
     (ParamStr(I)='-v')or(ParamStr(I)='--show-nonprinting')or
     (ParamStr(I)='-T')or(ParamStr(I)='--show-tabs')or
     (ParamStr(I)='-s')or(ParamStr(I)='--squeeze-blank')or
     (ParamStr(I)='--uniq')Then Begin
    { Saute ... }
   End
    Else
   Begin
    Found:=False;
    CurrDir:=Path2Dir(FExpand(ParamStr(I)));
    FindFirst(ParamStr(I),AnyFile,Info);
    While DOSError=0 do Begin
     Found:=True;
     Assign(Handle,CurrDir+Info.Name);
     {$I-}Reset(Handle);{$I+}
     If IOResult=0Then Begin
      LineNumber:=0;
      While NOT EOF(Handle)do Begin
       ReadLn(Handle,CurrLine);
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
      Close(Handle);
     End
      Else
     Begin
      WriteLn('Impossible de lire ',ParamStr(I));
      Halt(1);
     End;
     FindNext(Info);
    End;
    If Not(Found)Then Begin
     WriteLn(ParamStr(I),': Aucune correspondance de fichier ou de r‚pertoire.');
     Halt(2);
    End;
   End;
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
