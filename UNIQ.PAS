{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal, Turbo Pascal)
}

Program UNIQ(Input,Output);

Var
 FileView:Text;
 FileName,CurrLine,LastLine:String;

BEGIN
 LastLine:='';
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('UNIQ : Cette commande permet de sortir le contenu d''un ',
                 'fichiers sans duplication du contenu de ses lignes');
  WriteLn;
  WriteLn('Syntaxe : UNIQ nomdufichier');
 End
  Else
 If ParamCount>=1Then Begin
  FileName:=ParamStr(1);
  Assign(FileView,FileName);
  {$I-}Reset(FileView);{$I+}
  If IoResult=0Then Begin
   While Not EOF(FileView)do Begin
    ReadLn(FileView,CurrLine);
    If LastLine<>CurrLine Then WriteLn(Output,CurrLine);
    LastLine:=CurrLine;
   End;
  End
   Else
  WriteLn('Erreur de lecture du fichier');
  Close(FileView);
 End
  Else
 Begin
  While Not EOF do Begin
   ReadLn(Input,CurrLine);
   If LastLine<>CurrLine Then WriteLn(Output,CurrLine);
   LastLine:=CurrLine;
  End;
 End;
END.