{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program UNLINK;

Uses DOS;

Var
 FileErase:File;
 Info:SearchRec;
 I:Integer;
 CurrDir:String;

Function Path2Dir(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 Path2Dir:='';
 If Path=''Then Exit;
 FSplit(Path,D,N,E);
 If E=''Then Begin
  If D[Length(D)]<>'\'Then D:=D+'\';
  D:=D+E;
 End;
 If D=''Then Path2Dir:='' Else
 If D[Length(D)]<>'\'Then D:=D+'\';
 Path2Dir:=D;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('UNLINK : Cette commande permet de supprimer un lien symbolique.');
  WriteLn;
  WriteLn('Syntaxe : UNLINK nomdufichier');
  WriteLn;
  WriteLn(' nomdufichier  Nom des fichiers … d‚lier');
  WriteLn;
 End
  Else
 If ParamCount>0 Then Begin
  For I:=1 to ParamCount do Begin
   CurrDir:=Path2Dir(FExpand(ParamStr(I)));
   FindFirst(ParamStr(I),AnyFile,Info);
   While DOSError=0 do Begin
    {$I-}Assign(FileErase,CurrDir+Info.Name);
    Erase(FileErase);{$I+}
    If IOResult<>0 Then Begin
     WriteLn('Impossible de supprimer le fichier : ',Info.Name);
     Halt(1);
    End;
    FindNext(Info);
   End;
  End;
 End;
END.