{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program RAW2WAV;

Uses Dos;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 I,NumFiles:Integer;
 Size:LongInt;
 Readed:Word;
 FileName,StrTmp:String;
 Source,Target:File;
 Info:SearchRec;
 Buffer:Array[1..16384] of Byte;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function Path2NoExt(Const Path:String):String;
 Var
  D:DirStr;
  N:NameStr;
  E:ExtStr;
 Begin
 FSplit(Path,D,N,E);
 Path2NoExt:=D+N;
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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _English:Begin
    WriteLn('RAW2WAV : This command converts RAW sound file to WAV format (11025 Hz, mono).');
    WriteLn;
    WriteLn('RAW2WAV [/?] filename');
    WriteLn;
    WriteLn('/?         = Help for this command');
    WriteLn('RAW2WAV    = Filename to check');
   End;
   Else Begin
    WriteLn('RAW2WAV: Cette commande permet de convertir un fichier de son ',
                     'RAW en format WAV (mono en 11025 Hz).');
    WriteLn;
    WriteLn('Syntaxe : RAW2WAV [/?] filename');
    WriteLn;
    WriteLn(' /?          Ce paramŠtre permet de founir de l''aide sur cette commande.');
    WriteLn('filename     Ce paramŠtre permet d''indiquer le fichier … convertir');
   End;
  End;
 End
  Else
 Begin
  FileName:=Path2NoExt(ParamStr(1));
  FindFirst(FileName+'.RAW',Archive,Info);
  NumFiles:=0;
  While DosError=0 do Begin
   Inc(NumFiles);
   Write(Info.Name,' -> ',Copy(Info.Name,1,Length(Info.Name)-3)+'WAV',' ...');
   {$I-}Assign(Source,Info.Name);
   Reset(Source,1);{$I+}
   If IoResult<>0 Then Begin
    WriteLn('Lecture de fichier impossible');
    Halt;
   End;
   Assign(Target,Copy(Info.Name,1,Length(Info.Name)-3)+'WAV');
   Size:=FileSize(Source);
   Inc(Size,36);
   Rewrite(Target,1);
   StrTmp:='RIFF';
   BlockWrite(Target,StrTmp[1],4);
   BlockWrite(Target,Size,4);
   StrTmp:='WAVEfmt '#$10#$00#$00#$00#$01#$00#$01#$00#$11'+'#$00#$00#$11'+'#$00#$00#$01#$00#$08#$00'data';
   BlockWrite(Target,StrTmp[1],Length(StrTmp));
   Dec(Size,36);
   BlockWrite(Target,Size,4);
   While Not Eof(Source) do Begin
    BlockRead(Source,Buffer[1],High(Buffer),Readed);
    BlockWrite(Target,Buffer[1],Readed);
   End;
   Close(Source);
   Close(Target);
   Writeln(#$08#$08#$08'OK ');
   FindNext(Info);
  End;
  If NumFiles=0 Then Begin
   WriteLn('Fichier introuvable');
  End
   Else
  Begin
   WriteLn;
   Writeln(NumFiles,' fichiers de convertie.');
  End;
 End;
END.