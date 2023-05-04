{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program DIR;

Uses Crt,DOS;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 Error:Integer;
 P:Byte;
 Info:SearchRec;
 T:DateTime;
 Option:Set of (Pause,Subdirectory,Lower,Brief,Description);
 Column:Set Of (Double,Width);
 TotalNumFiles,TotalSize:LongInt;
 CurrParam,ShowDir,CurrLabel:String;
 CurrDrive:Char;
 OutputFormat:(_Text,_CSV,_HTML,_Json,_XML);

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function Path2Drive(Path:String):Char;Begin
 Path:=FExpand(Path);
 Path2Drive:=Path[1];
End;

Function GetDiskLabel(Dsk:Byte):String;
Var
 Info:SearchRec;
 CurrentDir:String;
Begin
 If Dsk=0Then GetDir(0,CurrentDir)
         Else CurrentDir:=Char(Dsk+64);
 FindFirst(CurrentDir[1]+':\*.*',VolumeID,Info);
 While DosError=0do Begin
  If(Info.Attr = VolumeID)Then Begin
   GetDiskLabel:=Info.Name;
   Exit;
  End;
  FindNext(Info);
 End;
 GetDiskLabel:=''
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
 Option:=[];
 Column:=[];
 P:=0;
 ShowDir:='*.*';
 OutputFormat:=_Text;
 Repeat
  Inc(P);
  CurrParam:=ParamStr(P);
 If Length(CurrParam)=0Then Break;
  If CurrParam='/?'Then Begin
  Case Language of
    _Germany:Begin
     WriteLn('Listet die Dateien und Unterverzeichnisse eines Verzeichnisses auf.');
     WriteLn;
     WriteLn('Format:   DIR [/?] [/2|/W] [/B] [/P] [path] [/FORMAT:format]');
    End;
    _English:Begin
     WriteLn('Purpose:  Display information about files and subdirectories.');
     WriteLn;
     WriteLn('Format:   DIR [/?] [/2|/W] [/B] [/P] [path] [/FORMAT:format]');
    End;
    Else Begin
     WriteLn('DIR   Cette commande permet d''afficher le contenu d''un repertoire dans l''unite de disque.');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('DIR [/?] [/2|/W] [/B] [/P] [chemin] [/FORMAT:format]');
     WriteLn;
     WriteLn(' /?             Ce parametre permet d''afficher l''aide sur cette commande');
     WriteLn(' /2             Ce parametre permet d''afficher sur 2 colonnes');
     WriteLn(' /B             Ce parametre enleve l''entete et les details de la fin');
     WriteLn(' /P             Ce parametre affiche une pause apres l''affichage d''une page pleine');
     WriteLn(' /W             Ce parametre affiche seulement les fichiers sur plein de colonnes');
     WriteLn(' /FORMAT:format Ce parametre permet d''indiquer CSV, HTML, Json, XML');
    End;
   End;
   Exit;
  End
   Else
  If CurrParam='/2'Then Include(Column,Double) Else
  If(CurrParam='/B')or(CurrParam='/b')Then Include(Option,Brief) Else
  If(CurrParam='/L')or(CurrParam='/l')Then Include(Option,Lower) Else
  If(CurrParam='/P')or(CurrParam='/p')Then Include(Option,Pause) Else
  If(CurrParam='/W')or(CurrParam='/w')Then Include(Column,Width) Else
  If(StrToUpper(Copy(CurrParam,1,8))='/FORMAT:')Then Begin
   If StrToUpper(Copy(CurrParam,9,255))='CSV'Then OutputFormat:=_CSV Else
   If StrToUpper(Copy(CurrParam,9,255))='HTML'Then OutputFormat:=_HTML Else
   If StrToUpper(Copy(CurrParam,9,255))='JSON'Then OutputFormat:=_Json Else
   If StrToUpper(Copy(CurrParam,9,255))='XML'Then OutputFormat:=_XML;
  End
   Else
  ShowDir:=CurrParam;
  If P>99Then Break;
 Until CurrParam='';
 CurrDrive:=Path2Drive(ShowDir);
 CurrLabel:=GetDiskLabel(Byte(CurrDrive)-64);
 P:=0;
 Case OutputFormat of
  _CSV:Begin
   FindFirst(ShowDir,AnyFile,Info);
   While DOSError=0 do Begin
    Write(Info.Name);
    If Not((Width)in(Column))Then Begin
     Write(',');
     If Info.Attr and Directory=Directory Then Begin
      Write('[directory]');
     End;
     If Info.Attr and ReadOnly=ReadOnly Then Begin
      Write('[readonly]');
     End;
     If Info.Attr and SysFile=SysFile Then Begin
      Write('[system]');
     End;
     If Info.Attr and Hidden=Hidden Then Begin
      Write('[hidden]');
     End;
     If Info.Attr and Archive=Archive Then Begin
      Write('[archive]');
     End;
     Write(',');
     Write(Info.Size,',');
     UnpackTime(Info.Time,T);
     Write(T.Year:4,'-',PadZeroLeft(T.Month,2),'-',PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2));
    End;
    WriteLn;
    FindNext(Info);
   End;
  End;
  _HTML:Begin
   WriteLn('<!DOCTYPE html>');
   WriteLn('<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="fr" lang="fr">');
   WriteLn('<body>');
   WriteLn('<table>');
   WriteLn(' ':4,'<tr>');
   WriteLn(' ':8,'<th>FileName</th>');
   If Not((Width)in(Column))Then Begin
    WriteLn(' ':8,'<th>Attribut</th>');
    WriteLn(' ':8,'<th>Size</th>');
    WriteLn(' ':8,'<th>Time</th>');
   End;
   WriteLn(' ':4,'</tr>');
   FindFirst(ShowDir,AnyFile,Info);
   While DOSError=0 do Begin
    WriteLn(' ':4,'<tr>');
    WriteLn(' ':8,'<td>',Info.Name,'</td>');
    If Not((Width)in(Column))Then Begin
     Write(' ':8,'<td>');
     If Info.Attr and Directory=Directory Then Begin
      Write('[directory]');
     End;
     If Info.Attr and ReadOnly=ReadOnly Then Begin
      Write('[readonly]');
     End;
     If Info.Attr and SysFile=SysFile Then Begin
      Write('[system]');
     End;
     If Info.Attr and Hidden=Hidden Then Begin
      Write('[hidden]');
     End;
     If Info.Attr and Archive=Archive Then Begin
      Write('[archive]');
     End;
     WriteLn('</td>');
     WriteLn(' ':8,'<td>',Info.Size,'</td>');
     UnpackTime(Info.Time,T);
     WriteLn(' ':8,'<td>',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',
             PadZeroLeft(T.Day,2),' ',T.Hour:2,':',
             PadZeroLeft(T.Min,2),'</td>');
    End;
    WriteLn(' ':4,'</tr>');
    FindNext(Info);
   End;
   WriteLn('</table>');
   WriteLn('</body>');
   WriteLn('</html>');
  End;
  _Json:Begin
   WriteLn('{');
   FindFirst(ShowDir,AnyFile,Info);
   Error:=DOSError;
   While Error=0 do Begin
    WriteLn(' ':4,'"file":{');
    WriteLn(' ':8,'"filename":"',Info.Name,'",');
    If Not((Width)in(Column))Then Begin
     Write(' ':8,'"attribut":"');
     If Info.Attr and Directory=Directory Then Begin
      Write('[directory]');
     End;
     If Info.Attr and ReadOnly=ReadOnly Then Begin
      Write('[readonly]');
     End;
     If Info.Attr and SysFile=SysFile Then Begin
      Write('[system]');
     End;
     If Info.Attr and Hidden=Hidden Then Begin
      Write('[hidden]');
     End;
     If Info.Attr and Archive=Archive Then Begin
      Write('[archive]');
     End;
     WriteLn('",');
     WriteLn(' ':8,'"size":',Info.Size,'",');
     UnpackTime(Info.Time,T);
     WriteLn(' ':8,'"time":"',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',
             PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2),'"');
    End;
    Write(' ':4,'}');
    FindNext(Info);
    Error:=DOSError;
    If Error=0 Then Write(',');
    WriteLn;
   End;
   WriteLn('}');
  End;
  _XML:Begin
   WriteLn('<?xml version="1.0" encoding="UTF-8"?>');
   WriteLn('<files>');
   FindFirst(ShowDir,AnyFile,Info);
   While DOSError=0 do Begin
    WriteLn(' ':4,'<file>');
    WriteLn(' ':8,'<filename>',Info.Name,'</filename>');
    If Not((Width)in(Column))Then Begin
     Write(' ':8,'<attribut>');
     If Info.Attr and Directory=Directory Then Begin
      Write('[directory]');
     End;
     If Info.Attr and ReadOnly=ReadOnly Then Begin
      Write('[readonly]');
     End;
     If Info.Attr and SysFile=SysFile Then Begin
      Write('[system]');
     End;
     If Info.Attr and Hidden=Hidden Then Begin
      Write('[hidden]');
     End;
     If Info.Attr and Archive=Archive Then Begin
      Write('[archive]');
     End;
     WriteLn('</attribut>');
     WriteLn(' ':8,'<size>',Info.Size,'</size>');
     UnpackTime(Info.Time,T);
     WriteLn(' ':8,'<time>',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',
             PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2),
             '</time>');
    End;
    WriteLn(' ':4,'</file>');
    FindNext(Info);
   End;
   WriteLn('</files>');
  End;
  Else Begin
   FindFirst(ShowDir,AnyFile,Info);
   If(Width)in(Column)Then While DOSError=0 do Begin
    Write(PadRight(Info.Name,16));
    FindNext(Info);
    If(Pause)in(Option)Then Begin
    Inc(P);
     If P=Hi(WindMax)Then Begin
      Write('Presse une touche pour continuer...');
      If ReadKey=#27Then Exit;
      WriteLn;
      P:=0;
     End;
    End;
   End
    Else
   If(Double)in(Column)Then While DOSError=0 do Begin
    Write(PadRight(Info.Name,13));
    If Info.Attr and Directory=Directory Then Begin
     Write(PadRight('<DIR>',9));
    End
     Else
    Write(Info.Size:9);
    UnpackTime(Info.Time,T);
    Write(' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2),' ');
    FindNext(Info);
    If(Pause)in(Option)Then Begin
     Inc(P);
     If P=Hi(WindMax)Then Begin
      Write('Presse une touche pour continuer...');
      If ReadKey=#27Then Exit;
      WriteLn;
      P:=0;
     End;
    End;
   End
    Else
   Begin
    TotalNumFiles:=0;
    TotalSize:=0;
    If Not((Brief)in(Option))Then Begin
     Inc(P,2);
     WriteLn('Le volume de l''unite '+CurrDrive+' est '+CurrLabel);
     WriteLn;
    End;
    While DOSError=0 do Begin
     Write(PadRight(Info.Name,13));
     If Info.Attr and Directory=Directory Then Begin
      Write(PadRight('<DIR>',15));
     End
      Else
     Write(Info.Size:15);
     UnpackTime(Info.Time,T);
     WriteLn(' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2));
     FindNext(Info);
     If(Pause)in(Option)Then Begin
      Inc(P);
      If P=Hi(WindMax)Then Begin
       Write('Presse une touche pour continuer...');
       If ReadKey=#27Then Exit;
       WriteLn;
       P:=0;
      End;
     End;
     Inc(TotalNumFiles);
     Inc(TotalSize,Info.Size);
    End;
    If Not((Brief)in(Option))Then Begin
     WriteLn(' Les ',TotalNumFiles,' fichier(s) utilisent ',TotalSize,' octet(s)');
     WriteLn(DiskFree(Byte(CurrDrive)-64):10,' octet(s) de libre');
    End;
   End;
  End;
 End;
END.
