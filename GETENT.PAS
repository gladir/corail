{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program GETENT;

Var
 ModeOutput:(_Raw,_CSV,_TSV,_HTML,_XML);
 I:Integer;
 FileName,KeyName:String;

Procedure ReadFileEtc(FileName:String);
Var
 FileEtc:Text;
 I:Integer;
 Skip:Boolean;
 CurrLine,CurrWord:String;
Begin
 {$I-}Assign(FileEtc,'/etc/'+FileName);
 Reset(FileEtc);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Erreur de lecture du fichier /etc/',FileName);
  Halt(1);
 End;
 Case ModeOutput of
  _HTML:WriteLn('<table>');
  _XML:Begin
   WriteLn('<?xml version="1.0" encoding="UTF-8"?>');
   WriteLn('<table>');
  End;
 End;
 While Not EOF(FileEtc)do Begin
  ReadLn(FileEtc,CurrLine);
  If KeyName<>''Then Begin
   Skip:=True;
   CurrWord:='';
   For I:=1 to Length(CurrLine)do Begin
    If CurrLine[I]=':'Then Begin
     If(CurrWord=KeyName)Then Skip:=False;
     Break;
    End
     Else
    CurrWord:=CurrWord+CurrLine[I];
   End;
  End
   Else
  Skip:=False;
  If Not(Skip)Then Case ModeOutput of
   _CSV:Begin
    For I:=1 to Length(CurrLine)do Begin
     If CurrLine[I]=':'Then Write(',')
                       Else Write(CurrLine[I]);
    End;
    WriteLn;
   End;
   _HTML:Begin
    WriteLn(' ':4,'<tr>');
    Write(' ':8,'<td>');
    For I:=1 to Length(CurrLine)do Begin
     If CurrLine[I]=':'Then Begin
      WriteLn('</td>');
      Write(' ':8,'<td>');
     End
      Else
     Write(CurrLine[I]);
    End;
    WriteLn('</td>');
    WriteLn(' ':4,'</tr>');
   End;
   _TSV:Begin
    For I:=1 to Length(CurrLine)do Begin
     If CurrLine[I]=':'Then Write(#9)
                       Else Write(CurrLine[I]);
    End;
    WriteLn;
   End;
   _XML:Begin
    WriteLn(' ':4,'<line>');
    Write(' ':8,'<colonne>');
    For I:=1 to Length(CurrLine)do Begin
     If CurrLine[I]=':'Then Begin
      WriteLn('</td>');
      Write(' ':8,'<colonne>');
     End
      Else
     Write(CurrLine[I]);
    End;
    WriteLn('</colonne>');
    WriteLn(' ':4,'</line>');
   End;
   Else WriteLn(CurrLine);
  End;
 End;
 If(ModeOutput in [_HTML,_XML])Then WriteLn('</table>');
 Close(FileEtc);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('GETENT : Cette commande permet de demander les entr‚es de la ',
                   'base de donn‚es administrative.');
  WriteLn;
  WriteLn('Syntaxe : GETENT [option] database key ');
  WriteLn;
  WriteLn(' database        Indique le nom de la base de donn‚es.');
  WriteLn(' key             Indique le nom de la clef … rechercher.');
  WriteLn(' --help          Affiche l''aide sur cette commande.');
  WriteLn(' --output:format Formatage de sortie : CSV, HTML, TSV ou XML.');
  WriteLn(' --version       Indique la version de la commande.');
 End
  Else
 If(ParamStr(1)='-v')or(ParamStr(1)='--version')Then Begin
  WriteLn('GETENT 1.0 - Clone Pascal de linux, freebsd ou corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('crit par Sylvain Maltais');
 End
  Else
 If ParamCount>0 Then Begin
  ModeOutput:=_Raw;
  FileName:='';
  KeyName:='';
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='--output:csv'Then ModeOutput:=_CSV Else
   If ParamStr(I)='--output:html'Then ModeOutput:=_HTML Else
   If ParamStr(I)='--output:tsv'Then ModeOutput:=_TSV Else
   If ParamStr(I)='--output:xml'Then ModeOutput:=_XML Else
   If FileName=''Then FileName:=ParamStr(I)
                 Else KeyName:=ParamStr(I);
  End;
  If FileName<>''Then ReadFileEtc(FileName)
   Else
  Begin
   WriteLn('Nom de base de donn‚e requis !');
   Halt(2);
  End;
 End;
END.