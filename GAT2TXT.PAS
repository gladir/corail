{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program GAT2TXT(Input,Output);

Var
 First:Boolean;
 I:Integer;
 SourceGAT,TargetTXT:Text;
 CurrLine,NewLine:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('GAT2TXT : Cette commande permet de convertir un document de traitement '+
                     'de texte GAT (progiciel MonsterBook) en format TXT.');
  WriteLn;
  WriteLn('Syntaxe : GAT2TXT nomdufichier.GAT nomdufichier.TXT');
 End
  Else
 If ParamCount>0Then Begin
  Assign(SourceGAT,ParamStr(1));
  {$I-}Reset(SourceGAT);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier GAT introuvable !');
   Halt;
  End;
  Assign(TargetTXT,ParamStr(2));
  {$I+}Rewrite(TargetTXT); {$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de cr‚er le fichier TXT !');
   Close(SourceGAT);
   Halt;
  End;
  First:=True;
  While Not EOF(SourceGAT)do Begin
   ReadLn(SourceGAT,CurrLine);
   If(First)Then Begin
    First:=False;
     { Ne pas importer cette ligne, il s'agit du format }
   End
    Else
   Begin
    NewLine:='';
    For I:=1 to Length(CurrLine) do Begin
     If CurrLine[I]>=' 'Then NewLine:=NewLine+CurrLine[I];
    End;
    WriteLn(TargetTXT,NewLine);
   End;
  End;
  Close(TargetTXT);
  Close(SourceGAT);
 End;
END.