{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal, Turbo Pascal)
}

Program ZFORCE;

Uses
  Dos;

Var
  Info:SearchRec;
  FileName,OldName,NewName,FileExt:String;
  DefaultName:String;

 { Fonction pour extraire l'extension d'un nom de fichier. }
Function GetFileExtension(Const FileName:String):String;
Var
 i:Integer;
Begin
 GetFileExtension:= '';
 For i:=Length(FileName) downto 1 do Begin
  If FileName[i] = '.'Then Begin
   GetFileExtension:= Copy(FileName, i + 1, Length(FileName) - i);
   Break;
  End;
 End;
End;

Function StrToLower(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
 End;
 StrToLower:=S;
End;

Function RenameFile(Const OldName,NewName:String):Boolean;
Var
 F:File;
Begin
 {$I-}Assign(F,OldName);
 Rename(F,NewName); {$I+}
 RenameFile:=IoResult=0;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('ZFORCE : Cette commande permet de forcer l''ajout d''extension ',
                   '®.gz¯ s''il n''existe pas sur tous les fichiers de ',
                   'format ®gzip¯.');
  WriteLn;
  WriteLn('Syntaxe : ZFORCE [nom]');
  Exit;
 End;
 DefaultName:='*.*';
 If ParamStr(1)<>''Then DefaultName:=ParamStr(1);
 FindFirst(DefaultName, AnyFile, Info);
 If DosError=0 Then Begin
  Repeat
   If(Info.Attr and Directory)=0 Then Begin
    FileName:=Info.Name;
    FileExt:=StrToLower(GetFileExtension(FileName));
     { V‚rifier si l'extension est '.gz' ou s'il s'agit d'un fichier gz (ne pas renommer les fichiers d‚j… '.tgz'). }
    If(FileExt<>'gz')and(FileExt='tgz')Then Begin
     OldName:=FileName;
     NewName:=Copy(OldName,1,Length(OldName)-Length(FileExt)-1)+'.gz';
      { Renommer le fichier en ajoutant '.gz' … la fin. }
     RenameFile(OldName,NewName);
     WriteLn('Renomme ', OldName, ' en ', NewName);
    End;
   End;
   FindNext(Info);
  Until DosError<>0;
 End
  Else
 Begin
  WriteLn('Aucun fichier trouv‚.');
 End;
END.