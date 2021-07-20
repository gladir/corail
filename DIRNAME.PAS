{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program DIRNAME;

Var
 Zero:Boolean;
 I:Integer;
 Path:String;

Function GetDirName(Path:String):String;
Var
 I:Integer;
Begin
 GetDirName:='';
 For I:=Length(Path)downto 1 do Begin
  If Path[I]in[';','/','\',':']Then Begin
   GetDirName:=Copy(Path,1,I);
   Exit;
  End;
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('DIRNAME : Cette commande permet de retourner le nom du fichier seulement.');
  WriteLn;
  WriteLn('Syntaxe : DIRNAME path [-z]');
 End
  Else
 If ParamCount>0Then Begin
  Zero:=False;
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='-z')or(ParamStr(I)='-zero')Then Zero:=True;
  End;
  For I:=1 to ParamCount do Begin
   If Not((ParamStr(I)='-z')or(ParamStr(I)='-zero'))Then Begin
    Path:=GetDirName(ParamStr(1));
    If(Zero)Then Write(Path)
            Else WriteLn(Path);
   End;
  End;
 End
  Else
 Begin
  WriteLn('Parametre requis !');
 End;
END.