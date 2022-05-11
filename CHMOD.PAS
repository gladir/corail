{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program CHMOD;

Uses DOS;

Var
 Option:Set of (_Quiet,_Verbose);
 FName:File;
 CurrAttr:Word;
 DirInfo:Searchrec;
 I:Byte;

Function IsOctalNumber(C:Char):Boolean;Begin
 IsOctalNumber:=C in['0'..'7'];
End;

Procedure WriteAttr(Input:String);Begin
 Assign(FName,Input);
 GetFAttr(FName,CurrAttr);
 If CurrAttr and ReadOnly <> 0 Then Write('r')
                               Else Write('-');
 If CurrAttr and Hidden <> 0 Then Write('h')
                             Else Write('-');
 If CurrAttr and SysFile <> 0 Then Write('s')
                              Else Write('-');
 If CurrAttr and Archive <> 0 Then Write('a')
                              Else Write('-');
 If CurrAttr and directory <> 0 Then Write('d')
                                Else Write('-');
 If CurrAttr and directory <> 0 Then Write(' \')
                                 Else Write(' ');
 WriteLn(Input);
End;

Procedure FindAttrs(Input:String);
Var
 I:Byte;
 st:String;
Begin
 st:=Input;
 If Length(st)<2 Then Begin
  If Not((_Quiet)in(Option))Then Writeln('Parametres invalide');
  Halt;
 End;
 If(Length(ST)=3)and(IsOctalNumber(ST[1]))and
   (IsOctalNumber(ST[2]))and(IsOctalNumber(ST[3]))Then Begin
  Case ST[1]of
   '0','4':CurrAttr:=ReadOnly;
   '7':CurrAttr:=Archive;
  End;
 End
  Else
 If st[1]in['+','-']Then Begin
  Case st[1] of
   '+':Begin
    For I:=2 to Length(st) do If upcase(st[I])in['A','R','S','H']Then
    Case upcase(st[i]) of
     'A':CurrAttr:=CurrAttr or Archive;
     'R':CurrAttr:=CurrAttr or ReadOnly;
     'S':CurrAttr:=CurrAttr or SysFile;
     'H':CurrAttr:=CurrAttr or Hidden;
    End
     Else
    Begin
     If Not((_Quiet)in(Option))Then Writeln('Parametres invalide');
     Halt;
    End;
   End;
   '-':Begin
    For I:=2 to Length(st) do If upcase(st[I]) in ['A','R','S','H']Then
     Case upcase(st[i]) of
      'A':CurrAttr:=CurrAttr and Not Archive;
      'R':CurrAttr:=CurrAttr and Not ReadOnly;
      'S':CurrAttr:=CurrAttr and Not SysFile;
      'H':CurrAttr:=CurrAttr and Not Hidden;
     End
      Else
     Begin
      If Not((_Quiet)in(Option))Then Writeln('Parametres invalide');
      Halt;
     End;
   End;
  End;
 End
  Else
 Begin
  If Not((_Quiet)in(Option))Then Writeln('Parametres invalide');
  Halt;
 End;
End;

BEGIN
 Option:=[];
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CHMOD : Cette commande permet de changer le mode des fichiers.');
  WriteLn;
  WriteLn('Syntaxe : CHMOD [-v|--quiet] fichiers [+/-rsha]');
  WriteLn;
  WriteLn('  r - Lecture seulement');
  WriteLn('  a - Archive');
  WriteLn('  s - Systeme');
  WriteLn('  h - Cacher');
  WriteLn;
  WriteLn(' -v         Affiche les details');
  WriteLn(' --quiet    Ne pas afficher les messages d''erreurs');
  WriteLn(' --verbose  Affiche les details');
 End
  Else
 If ParamCount=1 Then Begin
  Findfirst(Paramstr(1),Archive+ReadOnly+Hidden+SysFile+Directory,Dirinfo);
  While DOSError=0 do Begin
   WriteAttr(DirInfo.Name);
   FindNext(dirinfo);
  End;
 End
  Else
 If ParamCount>=2Then Begin
  FindFirst(ParamStr(1),Archive+ReadOnly+Hidden+SysFile+Directory,DirInfo);
  While DOSError=0 do Begin
   Assign(FName,DirInfo.Name);
   GetFAttr(FName,CurrAttr);
   For I:=2 to ParamCount do Begin
    If(ParamStr(I)='--quiet')Then Include(Option,_Quiet) Else
    If(ParamStr(I)='-v')or(ParamStr(I)='--verbose')Then Include(Option,_Verbose)
                                                   Else FindAttrs(ParamStr(I));
   End;
   Assign(FName,DirInfo.Name);
   SetFAttr(fname,CurrAttr);
   If(_Verbose)in(Option)Then WriteAttr(DirInfo.Name);
   FindNext(DirInfo);
  End;
 End;
END.