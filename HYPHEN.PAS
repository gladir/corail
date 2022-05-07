{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program HYPHEN;

Var
 BeginWord,EndWord,I,J,K:Integer;
 Handle:Text;
 CurrLine,FindWord:String;

Function IsLetter(Chr:Char):Boolean;Begin
 IsLetter:=Chr in ['A'..'Z','a'..'z'];
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('HYPHEN : Cette commande permet de rechercher les mots avec des traits-unions.');
  WriteLn;
  WriteLn('Syntaxe : HYPHEN [fichier]');
 End
  Else
 If ParamCount>0Then Begin
  For I:=1 to ParamCount do Begin
   Assign(Handle,ParamStr(I));
   {$I-}Reset(Handle);{$I+}
   If IOResult=0Then Begin
    While NOT EOF(Handle)do Begin
     ReadLn(Handle,CurrLine);
     For J:=1 to Length(CurrLine)do Begin
      If IsLetter(CurrLine[J])and(CurrLine[J+1]='-')and IsLetter(CurrLine[J+2])Then Begin
       BeginWord:=1;
       For K:=J downto 1 do Begin
        If Not IsLetter(CurrLine[K])Then Begin
         BeginWord:=K+1;
         Break;
        End;
       End;
       For K:=J+2 to Length(CurrLine)do Begin
        If Not IsLetter(CurrLine[K])Then Begin
         EndWord:=K-1;
         Break;
        End;
       End;
       WriteLn(Copy(CurrLine,BeginWord,EndWord-BeginWord+1));
      End;
     End;
    End;
    Close(Handle);
   End
    Else
   WriteLn('Impossible de lire ',ParamStr(I));
  End;
 End;
END.