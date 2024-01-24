{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program MKTEMP;

Uses DOS;

Var
 CreateDirectory,DryRun,Quiet:Boolean;
 I:Integer;
 NameGenerate,TmpDirManual:String;

Function Left(S:String;L:Integer):String;Begin
 Left:=Copy(S,1,L);
End;

Procedure TruncAfterSemicolon(Var S:String);
Var
 I:Byte;
Begin
 For I:=1to Length(S)do If S[I]=';'Then Begin
  S[0]:=Chr(I-1);
  Exit;
 End;
End;

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

Function IsWildCard(Const Path:String):Boolean;Begin
 IsWildCard:=(Pos('*',Path)>0)or(Pos('?',Path)>0);
End;

Function DirExist(Dir:String):Boolean;
Var
 Rec:SearchRec;
Begin
 If Length(Dir)=0Then DirExist:=True
  Else
 Begin
  TruncAfterSemicolon(Dir);
  If Dir[Length(Dir)]='\'Then Dir:=Dir+'*.*' Else
  If IsWildCard(Dir)Then Dir:=Path2Dir(Dir)+'*.*';
  FindFirst(Dir,Directory,Rec);
  DirExist:=DOSError=0;
 End;
End;

Function GetTempDirectory:String;
Var
 TmpDir:String;
Begin
 If TmpDirManual<>''Then TmpDir:=TmpDirManual
                    Else TmpDir:=GetEnv('TMPDIR');
 If TmpDir=''Then Begin
  {$IFDEF LINUX}
   TmpDir:='/tmp/';
  {$ELSE}
   TmpDir:='C:\TEMP\';
  {$ENDIF}
 End;
 {$IFDEF LINUX}
  If TmpDir[Length(TmpDir)]<>'/'Then TmpDir:=TmpDir+'/';
 {$ELSE}
  If TmpDir[Length(TmpDir)]<>'\'Then TmpDir:=TmpDir+'\';
 {$ENDIF}
 GetTempDirectory:=TmpDir;
End;

Function RecursiveMkDir(Path:String):Boolean;
Var
 I:Word;
 NewDir:String;
Begin
 RecursiveMkDir:=False;
 If Path=''Then Exit;
 Path:=FExpand(Path);
 I:=3;
 Repeat
  Repeat
   Inc(I)
  Until(I>Length(Path))or(Path[Pred(I)]='\');
  NewDir:=Left(Path,Pred(I));
  If Not DirExist(NewDir)Then Begin
   If NewDir[Length(NewDir)]='\'Then NewDir[0]:=Pred(NewDir[0]);
   MkDir(NewDir);
   If IOResult<>0Then Exit;
  End;
 Until I>Length(Path);
 RecursiveMkDir:=True;
End;

Function MkFile(S:String):Boolean;
Var
 F:File;
 R:Boolean;
Begin
 MkFile:=False;
 {$I-}Assign(F,S);
 Rewrite(F);{$I+}
 R:=IOResult=0;
 If(R)Then Close(F);
 MkFile:=R;
End;

Function RandomName(Len:Integer):String;
Const
 PathLetter:Array[0..61]of Char=('7','8','9','a','b','c','d',
                                 'e','f','g','h','i','j','k',
                                 'l','m','n','o','p','q','r',
                                 '0','1','2','3','4','5','6',
                                 's','t','u','v','w','x','y',
                                 'z','A','B','C','D','E','F',
                                 'G','H','I','J','K','L','M',
                                 'N','O','P','Q','R','S','T',
                                 'U','V','W','X','Y','Z');
Var
 I:Integer;
 S:String;
Begin
 S:='';
 For I:=1 to Len do Begin
  S:=S+PathLetter[Random(61)];
 End;
 RandomName:=S;
End;


BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('MKTEMP: Cette commande permet de cr‚er un fichier ou ',
                   'un r‚pertoire temporaire.');
  WriteLn;
  WriteLn('Syntaxe : MKTEMP [options]');
  WriteLn;
  WriteLn(' -d            Permet d''indiquer de cr‚er un r‚pertoire.');
  WriteLn(' -u            Permet d''indiquer de ne rien cr‚er.');
  WriteLn(' -q            Permet d''indiquer de ne pas afficher les ',
                          'messages d''erreur');
  WriteLn(' --tmpdir=DIR  Permet d''indiquer le r‚pertoire temporaire.');
  WriteLn(' --version     Permet d''afficher la version de la commande');
  WriteLn;
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('MKTEMP - Version 1.0-Pascal');
 End
  Else
 Begin
  Randomize;
  TmpDirManual:='';
  CreateDirectory:=False;
  DryRun:=False;
  Quiet:=False;
  If ParamCount>0 Then For I:=1 to ParamCount do Begin
   If(Copy(ParamStr(I),1,Length('--tmpdir='))='--tmpdir=')Then Begin
    TmpDirManual:=Copy(ParamStr(I),Length('--tmpdir=')+1,255);
   End
    Else
   If(ParamStr(I)='-d')or(ParamStr(I)='--directory')Then CreateDirectory:=True Else
   If(ParamStr(I)='-u')or(ParamStr(I)='--dry-run')Then DryRun:=True Else
   If(ParamStr(I)='-q')or(ParamStr(I)='--quiet')Then DryRun:=True
    Else
   Begin
    If Not(Quiet)Then WriteLn('ParamŠtre non reconnu : ',ParamStr(I));
    Halt(3);
   End;
  End;
  {$IFDEF FPC}
   NameGenerate:='tmp.'+RandomName(10);
  {$ELSE}
   NameGenerate:=RandomName(8)+'.TMP';
  {$ENDIF}
  If Not(DryRun)Then Begin
   If Not RecursiveMkDir(GetTempDirectory)Then Begin
    WriteLn('Erreur de cr‚ation r‚cursive');
    Halt(3);
   End;
   If(CreateDirectory)Then Begin
    {$I-}MkDir(GetTempDirectory+NameGenerate);{$I+}
    If IOResult<>0 Then Begin
     If Not(Quiet)Then Begin
      WriteLn('Erreur de cr‚ation du r‚pertoire : ',
              GetTempDirectory,NameGenerate);
     End;
     Halt(1);
    End;
   End
    Else
   Begin
    If Not MkFile(GetTempDirectory+NameGenerate)Then Begin
     If Not(Quiet)Then WriteLn('Erreur de cr‚ation du fichier');
     Halt(2);
    End;
   End;
  End;
  WriteLn(GetTempDirectory+NameGenerate);
 End;
END.