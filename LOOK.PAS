{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program LOOK;

Var
 Option:Set Of (IgnoreCase);
 Handle:Text;
 I,J:Integer;
 Mode:(_None,_text,_file);
 TextSearch,FileName,CurrLine:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function TrimL(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If S[I]<>' 'Then Begin
   TrimL:=Copy(S,I,255);
   Exit;
  End;
 End;
 TrimL:=S;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('LOOK : Cette commande permet de rechercher les lignes ',
                 'commenáant par une texte specifie.');
  WriteLn;
  WriteLn('Syntaxe : LOOK texte fichier');
  WriteLn;
  WriteLn(' fichier        Ce paramätre permet d''indiquer le fichier a analyser');
 End
  Else
 If ParamCount>1Then Begin
  Option:=[];
  TextSearch:='';
  FileName:='';
  Mode:=_text;
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='-f')or(ParamStr(I)='--ignore-case')Then Include(Option,IgnoreCase) Else
   If Mode=_Text Then Begin
    TextSearch:=ParamStr(I);
    Mode:=_File;
   End
    Else
   If Mode=_File Then Begin
    FileName:=ParamStr(I);
    Mode:=_None;
   End
    Else
   Begin
    WriteLn('Parametre non reconnu : ',ParamStr(I));
   End;
  End;
  If FileName<>''Then Begin
   Assign(Handle,FileName);
   {$I-}Reset(Handle);{$I+}
   If IOResult=0Then Begin
    While NOT EOF(Handle)do Begin
     ReadLn(Handle,CurrLine);
     If(IgnoreCase in Option)Then Begin
      If(StrToUpper(Copy(TrimL(CurrLine),1,Length(TextSearch)))=
         StrToUpper(TextSearch))Then Begin
       WriteLn(CurrLine);
      End;
     End
      Else
     If(Copy(TrimL(CurrLine),1,Length(TextSearch))=TextSearch)Then Begin
      WriteLn(CurrLine);
     End;
    End;
    Close(Handle);
   End;
  End
   Else
  WriteLn('Fichier attendu');
 End
  Else
 WriteLn('Paramätre insuffisant');
END.