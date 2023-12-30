{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program UNTAB;

Var
 FileRead,FileWrite:Text;
 I,J,TabSize:Integer;
 LeaveEOL:Boolean;
 Err:Word;
 CurrLine,FileName,TargetFileName:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function LTrim(s:String):String;
Var
 i:Integer;
Begin
 i:=1;
 While(i<=Length(s)) and (s[i] in [#9,' ']) do Inc(i);
 Delete(s,1,i-1);
 LTrim:=s;
End;

Function RTrim(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 RTrim:=S;
End;

Function Trim(s:String):String;Begin
 Trim:=LTrim(RTrim(s));
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('UNTAB : Cette commande permet de convertir des ',
                   'tabulation en espaces');
  WriteLn;
  WriteLn('Syntaxe : UNTAB source destination [/tabsize:x] [/leaveeol]');
  WriteLn;
  WriteLn('source       Fichier Ö convertir');
  WriteLn('destination  Le nouveau fichier crÇÇ');
  WriteLn('/leaveeol    N''enläve pas les espaces en fin de ligne');
  WriteLn('/tabsize:x   Indique le nombre d''espace pour une tabulation');
 End
  Else
 If ParamCount>0 Then Begin
  FileName:='';
  TargetFileName:='';
  TabSize:=4;
  LeaveEOL:=False;
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/LEAVEEOL'Then LeaveEol:=True Else
   If Copy(StrToUpper(ParamStr(I)),1,9)='/TABSIZE:'Then Begin
    Val(Copy(ParamStr(I),10,255),TabSize,Err);
    If Err>0 Then Begin
     WriteLn('Valeur de tabulation invalide');
     Halt;
    End;
   End;
  End;
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/LEAVEEOL'Then Begin
    { Saute ... }
   End
    Else
   If Copy(StrToUpper(ParamStr(I)),1,9)='/TABSIZE:'Then Begin
    { Saute ... }
   End
    Else
   Begin
    If FileName=''Then FileName:=ParamStr(I)
                  Else TargetFileName:=ParamStr(I);
   End;
  End;
  If TargetFileName<>''Then Begin
   {$I-}Assign(FileRead,FileName);
   Reset(FileRead);{$I+}
   If IOResult<>0 Then Begin
    WriteLn('Erreur de lecture du fichier ',FileName);
    Halt;
   End;
   {$I-}Assign(FileWrite,TargetFileName);
   Rewrite(FileWrite);{$I+}
   If IOResult=0 Then Begin
    While Not EOF(FileRead)do Begin
     ReadLn(FileRead,CurrLine);
     If Not(LeaveEol)Then CurrLine:=RTrim(CurrLine);
     For J:=1 to Length(CurrLine)do Begin
      If CurrLine[J]=#9 Then Write(FileWrite,' ':TabSize)
                        Else Write(FileWrite,CurrLine[J]);
     End;
     WriteLn(FileWrite);
    End;
    Close(FileWrite);
    Close(FileRead);
   End
    Else
   WriteLn('Erreur d''Çcriture du fichier ',TargetFileName);
  End
   Else
  If FileName<>''Then Begin
   {$I-}Assign(FileRead,FileName);
   Reset(FileRead);{$I+}
   If IoResult=0 Then Begin
    While Not EOF(FileRead)do Begin
     ReadLn(FileRead,CurrLine);
     If Not(LeaveEol)Then CurrLine:=RTrim(CurrLine);
     For J:=1 to Length(CurrLine)do Begin
      If CurrLine[J]=#9 Then Write(' ':TabSize)
                        Else Write(CurrLine[J]);
     End;
     WriteLn;
    End;
    Close(FileRead);
   End;
  End;
 End
  Else
 WriteLn('Paramätre requis !');
END.
