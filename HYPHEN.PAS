{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program HYPHEN;

Var
 Mode:(_End,_All);
 BeginWord,EndWord,I,J,K:Integer;
 Handle:Text;
 CurrName,CurrLine,FindWord:String;

Function IsLetter(Chr:Char):Boolean;Begin
 IsLetter:=Chr in ['A'..'Z','a'..'z'];
End;

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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('HYPHEN : Cette commande permet de rechercher les mots avec des traits-unions.');
  WriteLn;
  WriteLn('Syntaxe : HYPHEN [/ALL] [fichier]');
  WriteLn;
  WriteLn(' /ALL   Recherche tous les mots avec des traits d''unions');
 End
  Else
 If ParamCount>0Then Begin
  CurrName:='';
  Mode:=_End;
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/ALL'Then Mode:=_All
                                    Else CurrName:=ParamStr(I);
  End;
  If CurrName<>''Then Begin
   Assign(Handle,CurrName);
   {$I-}Reset(Handle);{$I+}
   If IOResult=0Then Begin
    If(Mode=_All)Then While NOT EOF(Handle)do Begin
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
     If(Length(CurrLine)>0)Then Begin
      J:=Length(CurrLine);
      If IsLetter(CurrLine[J-1])and(CurrLine[J]='-')Then Begin
       BeginWord:=1;
       EndWord:=J;
       For K:=J-1 downto 1 do Begin
        If Not IsLetter(CurrLine[K])Then Begin
         BeginWord:=K+1;
         Break;
        End;
       End;
       WriteLn(Copy(CurrLine,BeginWord,EndWord-BeginWord+1));
      End;
     End;
    End
     Else
    While NOT EOF(Handle)do Begin
     ReadLn(Handle,CurrLine);
     J:=Length(CurrLine);
     If IsLetter(CurrLine[J-1])and(CurrLine[J]='-')Then Begin
      BeginWord:=1;
      EndWord:=J;
      For K:=J-1 downto 1 do Begin
       If Not IsLetter(CurrLine[K])Then Begin
        BeginWord:=K+1;
        Break;
       End;
      End;
      WriteLn(Copy(CurrLine,BeginWord,EndWord-BeginWord+1));
     End;
    End;
    Close(Handle);
   End
    Else
   WriteLn('Impossible de lire ',ParamStr(I));
  End;
 End;
END.