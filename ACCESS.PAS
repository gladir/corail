{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal 3.2, Turbo Pascal 7)
}

Program ACCESS;

Uses Dos;

Var
 mode:String;
 filename:String;
 f:File;
 attrib:Word;
 Ok:Boolean;

Function StrToUpper(S:String):String;
Var
 I:Byte; { Compteur de boucle attribue a la chaine de caracteres }
Begin
 For I:=1to Length(S)do S[I]:=UpCase(S[I]);
 StrToUpper:=S;
End;

Function FileExists(Const FileName:String):Boolean;
Var
 f:File;
 R:Boolean;
Begin
 Assign(f,FileName);
 {$I-}Reset(f);{$I+}
 R:=IOResult=0;
 If(R)Then Close(f);
 FileExists:=R;
End;

Function Path2Ext(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2Ext:=E;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('ACCESS : Cette commande permet de v‚rifier si un fichier ',
                    'est disponible pour les actions sp‚cifi‚s avec ',
                    'les modes de lecture (r), d''‚criture (w) ou ',
                    'd''ex‚cution (x).');
  WriteLn;
  Writeln('Syntaxe : ACCESS [mode] [filename]');
  WriteLn;
  Writeln(' mode      Indique r (lecture), w (‚criture), x (ex‚cutable)');
  WriteLn(' filename  Le nom du fichier a v‚rifier');
 End
  Else
 If ParamCount>=2 Then Begin
  Mode:=ParamStr(1);
  Filename:=ParamStr(2);
  If Not FileExists(FileName)Then Begin
   Writeln('Erreur : Fichier introuvable');
   Halt(2);
  End;
  GetFAttr(FileName,Attrib);
  Ok:=False;
  If Pos('r',Mode)>0 Then Begin
   Assign(f,FileName);
   {$I-} Reset(f); {$I+}
   If IOResult=0 Then Writeln('Lecture autoris‚')
    Else
   Begin
    Writeln('Lecture non autoris‚');
    Halt(255);
   End;
   Ok:=True;
  End;
  If Pos('w',Mode)>0 Then Begin
   Assign(f,Filename);
   {$I-}Rewrite(f);{$I+}
   If IOResult=0 Then Writeln('Ecriture autoris‚')
    Else
   Begin
    Writeln('Ecriture non autoris‚');
    Halt(255);
   End;
   Ok:=True;
  End;
  If Pos('x',Mode)>0 Then Begin
   If(StrToUpper(Path2Ext(FileName))='.EXE')or
     (StrToUpper(Path2Ext(FileName))='.COM')Then Begin
    If Attrib and ReadOnly=0 Then Writeln('Ex‚cutable (pas lecture seulement)')
                             Else Writeln('Ex‚cutable (lecture seulement)');
   End
    Else
   Begin
    Writeln('Ce n''est pas un ex‚cutable');
    Halt(255);
   End;
   Ok:=True;
  End;
  If Not(Ok)Then Begin
   Writeln('Erreur: Mode invalide');
   Halt(2);
  End;
 End
  Else
 WriteLn('ParamŠtre requis !');
END.