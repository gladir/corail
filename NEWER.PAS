{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program NEWER;

Uses DOS;

Var
 F1,F2:File;
 T1,T2:LongInt;
 ErrorLevel:Byte;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('NEWER : Cette commande permet d''indiquer lequel entre les 2 fichiers ');
  WriteLn('        est le plus rÇcent.');
  WriteLn;
  Writeln('Syntaxe : NEWER fichier1 fichier2');
  Writeln;
  Writeln('errorlevel = 0 si 1 est plus ancien que 2,');
  Writeln('             1 si le màme Ége,');
  Writeln('             2 si 1 est plus rÇcent que 2,');
  Writeln('             3 si une erreur.');
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('NEWER 1.0.0 - Clone Pascal de la commande NEWER');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('êcrit par Sylvain Maltais');
 End
  Else
 If ParamCount>1 Then Begin
  ErrorLevel:=3;
  {$I-}Assign(F1,ParamStr(1));
  Reset(f1);{$I+}
  If IOResult<>0 Then Begin
   Writeln('Erreur d''ouverture ',ParamStr(1));
   Halt(3);
  End;
  {$I-}Assign(F2,ParamStr(2));
  Reset(f2);{$I+}
  If IOResult<>0 Then Begin
   Writeln('Erreur d''ouverture ',ParamStr(2));
   Halt(3);
  End;
  GetFTime(F1,T1);
  GetFTime(F2,T2);
  If T1<T2 Then ErrorLevel:=0;
  If T1=T2 Then ErrorLevel:=1;
  If T1>T2 Then ErrorLevel:=2;
  Halt(ErrorLevel)
 End
  Else
 WriteLn('Paramätre requis !');
END.