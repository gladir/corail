{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7)
}

Program PHOTORAM;

{$A+,B-,D+,E+,F-,I-,L+,N-,O-,R+,S+,V+}

Uses Crt,DOS;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 I:Word;
 OutFile:File;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
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
    WriteLn('PHOTORAM : This command takes a snapshot of RAM 640K and sends ',
                        'it to the filename specified.');
    WriteLn;
    WriteLn('PHOTORAM [/?] filename');
    WriteLn;
    WriteLn('/?          = Help for this command');
    WriteLn('filename    = Output filename');
   End;
   Else Begin
    WriteLn('PHOTORAM : Cette commande permet de sauvegarder le contenu de la ',
                        'la mÇmoire conventionnelle de 640 Ko et l''envoi dans ',
                        'un fichier.');
    WriteLn;
    WriteLn('Syntaxe : PHOTORAM [/?] filename');
    WriteLn;
    WriteLn(' /?          Ce paramätre permet de founir de l''aide sur cette commande.');
    WriteLn('filename     Ce paramätre permet d''indiquer le fichier de sortie');
   End;
  End;
 End
  Else
 Begin
  Assign(OutFile,ParamStr(1));
  Rewrite(OutFile,1);
  For I:=0 to ((640 div $40) - $1)do Begin
   BlockWrite(OutFile,Mem[I:$0000],$8000);
   BlockWrite(OutFile,Mem[I:$8000],$8000)
  End;
  Close(OutFile)
 End;
END.