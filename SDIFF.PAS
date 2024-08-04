{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal, Turbo Pascal)
}

Program SDIFF;

Var
 File1,File2:Text;
 FileName1,FileName2,CurrLine1,CurrLine2:String;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('SDIFF : Cette commande permet de rechercher les diffÇrences ',
                  'cìte Ö cìte du programme.');
  WriteLn;
  WriteLn('Syntaxe : SDIFF fichier1 fichier2');
  WriteLn('Syntaxe : SDIFF --version');
  WriteLn;
  WriteLn(' fichier1   Premier fichier texte');
  WriteLn(' fichier2   Deuxiäme fichier texte');
  WriteLn(' --version  Indique le numÇro de la version du programme.');
  WriteLn;
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('SDIFF 1.0 - Clone Pascal de Corail, unicos-0');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('êcrit par Sylvain Maltais');
 End
  Else
 If ParamCount>0 Then Begin
  FileName1:=ParamStr(1);
  FileName2:=ParamStr(2);
  {$I-}Assign(File1,FileName1);
  Reset(File1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible d''ouvrir le fichier ',FileName1);
   Halt(1);
  End;
  {$I-}Assign(File2,FileName2);
  Reset(File2);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible d''ouvrir le fichier ',FileName2);
   Halt(2);
  End;
  While Not EOF(File1)do Begin
   ReadLn(File1,CurrLine1);
   CurrLine2:='';
    {$I-}ReadLn(File2,CurrLine2);{$I+}
  Write(PadRight(Copy(CurrLine1,1,30),30));
   Write(' ');
   If(CurrLine1=CurrLine2)Then Write(' ') Else
   If CurrLine1=''Then Write('>') Else
   If CurrLine2=''Then Write('<') Else
   If(CurrLine1<>CurrLine2)Then Write('|')
                           Else Write(' ');
   Write(' ');
   WriteLn(Copy(CurrLine2,1,30));
  End;
  Close(File2);
  Close(File1);
 End
  Else
 Begin
  WriteLn('Paramätre requis');
  Halt(3);
 End;
END.