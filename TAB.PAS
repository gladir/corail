{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program TAB;

Var
 FileRead,FileWrite:Text;
 I,J,TabSize:Integer;
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

Function Replace(Source,Old,New:String):String;
Var
 P:LongInt;
Begin
 While Pos(Old,Source)<>0 do Begin
  P:=Pos(Old,Source);
  Delete(Source,P,Length(Old));
  Insert(New,Source,P);
 End;
 Replace:=Source;
End;

Function Dupl(C:String;Num:LongInt):String;
Var
 I:LongInt;
 S:String;
Begin
 S:='';
 For I:=1 to Num do S:=S+C;
 Dupl:=S;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('TAB : Cette commande permet de convertir des ',
                   'espaces en tabulation');
  WriteLn;
  WriteLn('Syntaxe : TAB source destination [/tabsize:x]');
  WriteLn;
  WriteLn('source       Fichier Ö convertir');
  WriteLn('destination  Le nouveau fichier crÇÇ');
  WriteLn('/tabsize:x   Indique le nombre d''espace pour une tabulation');
 End
  Else
 If ParamCount>0 Then Begin
  FileName:='';
  TargetFileName:='';
  TabSize:=8;
  For I:=1 to ParamCount do Begin
   If Copy(StrToUpper(ParamStr(I)),1,9)='/TABSIZE:'Then Begin
    Val(Copy(ParamStr(I),10,255),TabSize,Err);
    If Err>0 Then Begin
     WriteLn('Valeur de tabulation invalide');
     Halt;
    End;
   End;
  End;
  For I:=1 to ParamCount do Begin
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
     WriteLn(FileWrite,Replace(CurrLine,Dupl(' ',TabSize),#9));
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
     WriteLn(Replace(CurrLine,Dupl(' ',TabSize),#9));
    End;
    Close(FileRead);
   End
    Else
   Begin
    WriteLn('Erreur de lecture du fichier ',FileName);
    Halt;
   End;
  End;
 End
  Else
 WriteLn('Paramätre requis !');
END.