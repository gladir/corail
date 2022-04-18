{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program CATALOG;

Uses Crt,DOS;

Var
 P:Byte;
 Info:SearchRec;
 T:DateTime;
 TotalNumFiles,TotalSize:LongInt;
 CurrParam,ShowDir,CurrLabel:String;
 CurrDrive:Char;

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

Function Path2Ext(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2Ext:=E;
End;

Function Path2Drive(Path:String):Char;Begin
 Path:=FExpand(Path);
 Path2Drive:=Path[1];
End;

BEGIN
 P:=0;
 ShowDir:='*.*';
 Repeat
  Inc(P);
  CurrParam:=ParamStr(P);
  If Length(CurrParam)=0Then Break;
  If CurrParam='/?'Then Begin
   WriteLn('CATALOG   Cette commande permet d''afficher le contenu d''un repertoire dans l''unite de disque.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('CATALOG [/?] [chemin] [D1|D2|D3|D4]');
   WriteLn;
   WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
   Exit;
  End
   Else
  If CurrParam='D0'Then Begin
   WriteLn('ERREUR D''INTERVALLE');
   Exit;
  End
   Else
  If StrToUpper(CurrParam)='D1'Then ShowDir:='A:\*.*'Else
  If StrToUpper(CurrParam)='D2'Then ShowDir:='B:\*.*'Else
  If StrToUpper(CurrParam)='D3'Then ShowDir:='C:\*.*'Else
  IF StrToUpper(CurrParam)='D4'Then ShowDir:='D:\*.*'
                               Else ShowDir:=CurrParam;
  If P>99Then Break;
 Until CurrParam='';
 CurrDrive:=Path2Drive(ShowDir);
 FindFirst(ShowDir,AnyFile,Info);
 P:=0;
 While DOSError=0 do Begin
  Inc(P);
  If(Info.Attr and ReadOnly=ReadOnly)Then Write('*')
                                     Else Write(' ');
  If(Path2Ext(Info.Name)='.EXE')or(Path2Ext(Info.Name)='.COM')Then Write('B')Else
  If(Path2Ext(Info.Name)='.BAS')Then Write('A') Else
  If(Path2Ext(Info.Name)='.TXT')Then Write('T')
                                Else Write('S');
  Write(' ',HexWord2Str(Word(Info.Size shr 9)),' ');
  WriteLn(StrToUpper(Info.Name));
  FindNext(Info);
  If P=25Then Begin
   ReadKey;
   P:=0;
  End;
 End;
END.