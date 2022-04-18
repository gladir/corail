{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program BaseName;

Function GetBaseName(PathSpec:String):String;
Var
 HoldIndex,ScanIndex:Integer;
 ThisChar:Char;
Begin
 HoldIndex := 1;
 For ScanIndex:=1 TO Length (PathSpec)do Begin
  ThisChar:=PathSpec[ScanIndex];
  If ThisChar in[':','/','\']Then HoldIndex:=ScanIndex+1
 End;
 GetBaseName:=Copy(PathSpec,HoldIndex,Length(PathSpec)-HoldIndex+1);
End;

Function RemoveSuffixe(PathSpec,Suffixe:String):String;Begin
 If Copy(PathSpec,Length(PathSpec)-Length(Suffixe)+1,Length(Suffixe))=Suffixe Then Begin
  RemoveSuffixe:=Copy(PathSpec,1,Length(PathSpec)-Length(Suffixe));
 End
  Else
 RemoveSuffixe:=PathSpec;
End;

Var
 Path:String;


BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('BASENAME : Cette commande permet de retourner le nom du fichier seulement.');
  WriteLn;
  WriteLn('Syntaxe : BASENAME path [suffixe]');
 End
  Else
 If ParamCount>0Then Begin
  Path:=GetBaseName(ParamStr(1));
  If ParamCount=2 Then Path:=RemoveSuffixe(Path,ParamStr(2));
  WriteLn(Path);
 End
  Else
 Begin
  WriteLn('Parametre requis !');
 End;
END.
