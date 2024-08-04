{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal, Turbo Pascal)
}

Program PG;

Uses Crt,DOS;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 I:Byte;
 S:String;
 FileRead:Text;
 Regs:Registers;

Function StrToUpper(S:String):String;
Var
 I:Byte; { Compteur de boucle attribue a la chaine de caracteres }
Begin
 For I:=1to Length(S)do S[I]:=UpCase(S[I]);
 StrToUpper:=S;
End;

BEGIN
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 If ParamStr(1)='/?'Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Zeigt Daten seitenweise auf dem Bildschirm an.');
    WriteLn;
    WriteLn('PG [Laufwerk:][Pfad]Dateiname');
   End;
   _English:Begin
    WriteLn('Displays output one screen at a time.');
    WriteLn;
    WriteLn('PG source');
   End;
   Else Begin
    WriteLn('PG : Cette commande permet de recevoir l''entr‚e puis ',
            'l''affiche sur un p‚ripherique de sortie un ‚cran 20 lignes ',
            '… la fois.');
    WriteLn;
    WriteLn('Syntaxe : PG source');
   End;
  End;
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('PG 1.0 - Clone Pascal de Corail, unicos-0, aix-0');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('crit par Sylvain Maltais');
 End
  Else
 If ParamCount>0Then Begin
  {$I-}Assign(FileRead,ParamStr(1));
  Reset(FileRead);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible d''ouvrir le fichier ',ParamStr(1));
   Halt(1);
  End;
  I:=0;
  While Not(EOF(FileRead))do Begin
   Inc(I);
   ReadLn(FileRead,S);
   WriteLn(S);
   If I>=20 Then Begin
    ReadKey;
    I:=0;
   End;
  End;
  Close(FileRead);
 End
  Else
 Begin
  I:=0;
  Repeat
   Inc(I);
   ReadLn(Input,S);
   WriteLn(Output,S);
   If I=Hi(WindMax)Then Begin
    Regs.AH := $0C;
    Regs.AL := $07;
    MsDos(Regs);
    I:=0;
   End;
  Until Eof;
 End;
END.