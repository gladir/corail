{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program HEXDUMP;

Var
 OutputFormat:(_Text,_C,_CSV,_HTML,_Json,_Pascal,_SQL,_XML);
 Option:(_None,_Offset);
 I:Integer;
 ByteReaded:Integer;
 Err:Word;
 StartPos,CurrPos:LongInt;
 FileView:File;
 CurrParam,FileName:String;
 Buffer:Array[0..255]of Byte;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

Function LongHex2Str(value:LongInt):String;
Begin
 LongHex2Str:=ByteHex2Str((value shr 24)and $FF)+
              ByteHex2Str((value shr 16)and $FF)+
              ByteHex2Str((value shr 8)and $FF)+
              ByteHex2Str(value and $FF);
End;

BEGIN
 OutputFormat:=_Text;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('HEXDUMP : Cette commande permet d''afficher le contenu d''un fichier en format hexadecimal.');
  WriteLn;
  WriteLn('Syntaxe : HEXDUMP fichier [option]');
  WriteLn;
  WriteLn(' fichier        Nom du fichier a afficher');
  WriteLn(' -s deplacement Deplacement d''octets a partir du debut');
  WriteLn(' /FORMAT:format Sortie en C, CSV, HTML, Json, PASCAL, SQL ou XML');
  WriteLn;
 End
  Else
 Begin
  Option:=_None;
  StartPos:=0;
  FileName:='';
  For I:=1 to ParamCount do Begin
   CurrParam:=ParamStr(I);
   If Option=_Offset Then Begin
    Option:=_None;
    Val(CurrParam,StartPos,Err);
   End
    Else
   If CurrParam='-s'Then Option:=_Offset Else
   If(StrToUpper(Copy(CurrParam,1,8))='/FORMAT:')Then Begin
    If StrToUpper(Copy(CurrParam,9,255))='C'Then OutputFormat:=_C Else
    If StrToUpper(Copy(CurrParam,9,255))='CSV'Then OutputFormat:=_CSV Else
    If StrToUpper(Copy(CurrParam,9,255))='HTML'Then OutputFormat:=_HTML Else
    If StrToUpper(Copy(CurrParam,9,255))='JSON'Then OutputFormat:=_Json Else
    If StrToUpper(Copy(CurrParam,9,255))='PASCAL'Then OutputFormat:=_Pascal Else
    If StrToUpper(Copy(CurrParam,9,255))='SQL'Then OutputFormat:=_SQL Else
    If StrToUpper(Copy(CurrParam,9,255))='XML'Then OutputFormat:=_XML;
   End
    Else
   FileName:=CurrParam;
  End;
  CurrPos:=0;
  If FileName=''Then Begin
   WriteLn('Fichier requis !');
  End
   Else
  Begin
   {$I-}Assign(FileView,FileName);
   Reset(FileView,1);{$I+}
   If IoResult<>0 Then Begin
    WriteLn('Fichier introuvable !');
    Halt;
   End;
   Seek(FileView,StartPos);
   Case OutputFormat of
    _C:Begin
     WriteLn('const unsigned char samples[',FileSize(FileView)-1-StartPos,'] = {');
     While Not EOF(FileView)do Begin
      BlockRead(FileView,Buffer,16,ByteReaded);
      Write('/*',LongHex2Str(CurrPos),'*/');
      For I:=0 to 15 do Begin
       If I>=ByteReaded Then Write('  ':3)
        Else
       Begin
        Write('0x',ByteHex2Str(Buffer[I]));
        If I+1<ByteReaded Then Write(',');
       End;
       If I=7Then Write(' ');
      End;
      Write(' /* ');
      For I:=0 to 15 do Begin
       If I>=ByteReaded Then Write(' ')Else
       If Buffer[I]<32Then Write(' ')
                      Else Write(Char(Buffer[I]));
      End;
      Write('*/');
      WriteLn;
      Inc(CurrPos,ByteReaded);
     End;
     WriteLn('};');
    End;
    _CSV:Begin
     While Not EOF(FileView)do Begin
      BlockRead(FileView,Buffer,16,ByteReaded);
      Write(LongHex2Str(CurrPos),',');
      For I:=0 to 15 do Begin
       If I>=ByteReaded Then Write('  ':3)
        Else
       Begin
        Write(ByteHex2Str(Buffer[I]));
        If I+1<ByteReaded Then Write(',');
       End;
      End;
      WriteLn;
      Inc(CurrPos,ByteReaded);
     End;
     WriteLn('};');
    End;
    _HTML:Begin
     WriteLn('<!DOCTYPE html>');
     WriteLn('<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="fr" lang="fr">');
     WriteLn('<body>');
     WriteLn('<table>');
     While Not EOF(FileView)do Begin
      BlockRead(FileView,Buffer,16,ByteReaded);
      WriteLn('<tr>');
      Write('<td>',LongHex2Str(CurrPos),'</td>');
      For I:=0 to 15 do Begin
       If I>=ByteReaded Then Write('<td>',' ':3,'</td>')
                        Else Write('<td>',ByteHex2Str(Buffer[I]),'</td>');
      End;
      Write('<td>');
      For I:=0 to 15 do Begin
       If I>=ByteReaded Then Write(' ')Else
       If Buffer[I]<32Then Write(' ')
                      Else Write(Char(Buffer[I]));
      End;
      Write('</td>');
      WriteLn;
      WriteLn('</tr>');
      Inc(CurrPos,ByteReaded);
     End;
     WriteLn('</table>');
     WriteLn('</body>');
     WriteLn('</html>');
    End;
    _Json:Begin
     WriteLn('{');
     While Not EOF(FileView)do Begin
      WriteLn('{');
      BlockRead(FileView,Buffer,16,ByteReaded);
      Write('"position":"',LongHex2Str(CurrPos),'",');
      Write('"data":"');
      For I:=0 to 15 do Begin
       If I>=ByteReaded Then Write(' ':3)
                       Else Write(ByteHex2Str(Buffer[I]),' ');
      End;
      Write('",');
      Write('"text":"');
      For I:=0 to 15 do Begin
       If I>=ByteReaded Then Write(' ')Else
       If Buffer[I]<32Then Write(' ')
                      Else Write(Char(Buffer[I]));
      End;
      Write('"');
      WriteLn;
      Inc(CurrPos,ByteReaded);
      WriteLn('},');
     End;
     WriteLn('}');
    End;
    _Pascal:Begin
     WriteLn('Const samples:Array[0..',FileSize(FileView)-1-StartPos,'] of Byte=(');
     While Not EOF(FileView)do Begin
      BlockRead(FileView,Buffer,16,ByteReaded);
      Write('{',LongHex2Str(CurrPos),'}');
      For I:=0 to 15 do Begin
       If I>=ByteReaded Then Write('  ':3)
        Else
       Begin
        Write('$',ByteHex2Str(Buffer[I]));
        If I+1<ByteReaded Then Write(',');
       End;
       If I=7Then Write(' ');
      End;
      Write(' { ');
      For I:=0 to 15 do Begin
       If I>=ByteReaded Then Write(' ')Else
       If Buffer[I]<32Then Write(' ')
                      Else Write(Char(Buffer[I]));
      End;
      Write('}');
      WriteLn;
      Inc(CurrPos,ByteReaded);
     End;
     WriteLn(');');
    End;
    _SQL:Begin
     WriteLn('CREATE TABLE line (');
     WriteLn(' ':8,'d1 TEXT,');
     WriteLn(' ':8,'d2 TEXT,');
     WriteLn(' ':8,'d3 TEXT,');
     WriteLn(' ':8,'d4 TEXT,');
     WriteLn(' ':8,'d5 TEXT,');
     WriteLn(' ':8,'d6 TEXT,');
     WriteLn(' ':8,'d7 TEXT,');
     WriteLn(' ':8,'d8 TEXT,');
     WriteLn(' ':8,'d9 TEXT,');
     WriteLn(' ':8,'da TEXT,');
     WriteLn(' ':8,'db TEXT,');
     WriteLn(' ':8,'dc TEXT,');
     WriteLn(' ':8,'dd TEXT,');
     WriteLn(' ':8,'de TEXT,');
     WriteLn(' ':8,'df TEXT');
     WriteLn(');');
     While Not EOF(FileView)do Begin
       WriteLn('INSERT INTO line (d1,d2,d3,d4,d5,d6,d7,d8,d9,da,db,dc,dd,de,df) VALUES (');
      BlockRead(FileView,Buffer,16,ByteReaded);
      Write('/*',LongHex2Str(CurrPos),'*/');
      For I:=0 to 15 do Begin
       If I>=ByteReaded Then Write('''','''')
        Else
       Begin
        Write('''',ByteHex2Str(Buffer[I]),'''');
       End;
       If I<15 Then Write(',');
      End;
      Write(' /*');
      For I:=0 to 15 do Begin
       If I>=ByteReaded Then Write(' ')Else
       If Buffer[I]<32Then Write(' ')
                      Else Write(Char(Buffer[I]));
      End;
      Write('*/');
      WriteLn(');');
      WriteLn;
      Inc(CurrPos,ByteReaded);
     End;
    End;
    _XML:Begin
     WriteLn('<?xml version="1.0" encoding="UTF-8"?>');
     WriteLn('<data>');
     While Not EOF(FileView)do Begin
      BlockRead(FileView,Buffer,16,ByteReaded);
      WriteLn('<line>');
      Write('<position>',LongHex2Str(CurrPos),'</position>');
      For I:=0 to 15 do Begin
       If I>=ByteReaded Then Write('<byte>',' ':3,'</byte>')
                        Else Write('<byte>',ByteHex2Str(Buffer[I]),'</byte>');
      End;
      Write('<!-- ');
      For I:=0 to 15 do Begin
       If I>=ByteReaded Then Write(' ')Else
       If Buffer[I]<32Then Write(' ')
                      Else Write(Char(Buffer[I]));
      End;
      Write('-->');
      WriteLn;
      WriteLn('</line>');
      Inc(CurrPos,ByteReaded);
     End;
     WriteLn('</data>');
    End;
    Else Begin
     While Not EOF(FileView)do Begin
      BlockRead(FileView,Buffer,16,ByteReaded);
      Write(LongHex2Str(CurrPos),' ');
      For I:=0 to 15 do Begin
       If I>=ByteReaded Then Write(' ':3)
                       Else Write(ByteHex2Str(Buffer[I]),' ');
       If I=7Then Write(' ');
      End;
      Write(' |');
      For I:=0 to 15 do Begin
       If I>=ByteReaded Then Write(' ')Else
       If Buffer[I]<32Then Write(' ')
                      Else Write(Char(Buffer[I]));
      End;
      Write('|');
      WriteLn;
      Inc(CurrPos,ByteReaded);
     End;
    End;
   End;
   Close(FileView);
  End;
 End;
END.
