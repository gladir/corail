{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program ROT13C5D;

Uses DOS;

Var
 I:Integer;
 OutputFileName,CurrLine:String;
 FileRot13,OutputFileRot13:Text;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function FileExist(Name:String):Boolean;
Var
 Rec:SearchRec;
Begin
 FindFirst(Name,AnyFile,Rec);
 FileExist:=DosError=0;
End;

Function Rot13C5DToString(someText:String):String;
Var
 I:Integer;
 Ch:Char;
 R:String;
Begin
 R:='';
 For I:=1 to Length(someText) do Begin
  Ch:=SomeText[i];
  Case ch of
   'A'..'M','a'..'m':Ch:=Chr(Ord(Ch)+13);
   'N'..'Z','n'..'z':Ch:=Chr(Ord(Ch)-13);
   '0'..'9':Ch:=Chr(((Ord(Ch)-Ord('0')+5) mod 10)+Ord('0'));
  End;
  R:=R+Ch;
 End;
 Rot13C5DToString:=R;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('ROT13C5D : Cette commande permet d''effectuer une rotation de ',
                      '13 lettres de l''alphabet latin et une rotation de 5 ',
                      'chiffres sur les chiffres.');
  WriteLn;
  WriteLn('Syntaxe : ROT13C5D ["message"] [/OUTPUTFILE:fichier2]');
  WriteLn('          ROT13C5D fichier  [/OUTPUTFILE:fichier2]');
  WriteLn;
  WriteLn(' message              Le message … chiffrer avec ROT13');
  WriteLn(' fichier              Le nom du fichier … traiter avec ROT13');
  WriteLn(' /OUTPUTFILE:fichier2 Le nom du fichier allant contenir le r‚sultat');
 End
  Else
 If ParamCount>0 Then Begin
  OutputFileName:='';
  For I:=1 to ParamCount do Begin
   If(StrToUpper(Copy(ParamStr(I),1,Length('/OUTPUTFILE:')))='/OUTPUTFILE:')Then Begin
    OutputFileName:=Copy(ParamStr(I),Length('/OUTPUTFILE:')+1,255);
   End;
  End;
  For I:=1 to ParamCount do Begin
   If(StrToUpper(Copy(ParamStr(I),1,Length('/OUTPUTFILE:')))='/OUTPUTFILE:')Then Begin
    { Saut ... }
   End
    Else
   If FileExist(ParamStr(I))Then Begin
    If OutputFileName<>''Then Begin
     {$I-}Assign(FileRot13,ParamStr(I));
     Reset(FileRot13);{$I+}
     If IOResult<>0 Then Begin
      WriteLn('Impossible de lire le fichier : ',ParamStr(I),'!');
      Halt(1);
     End;
     {$I-}Assign(OutputFileRot13,OutputFileName);
     Rewrite(OutputFileRot13);{$I+}
     If IOResult<>0 Then Begin
      WriteLn('Impossible de cr‚er le fichier : ',OutputFileName,'!');
      Halt(2);
     End;
     While Not EOF(FileRot13)do Begin
      ReadLn(FileRot13,CurrLine);
      WriteLn(OutputFileRot13,Rot13C5DToString(CurrLine));
     End;
     Close(OutputFileRot13);
     Close(FileRot13);
    End
     Else
    Begin
     {$I-}Assign(FileRot13,ParamStr(I));
     Reset(FileRot13);{$I+}
     If IOResult<>0 Then Begin
      WriteLn('Impossible de lire le fichier : ',ParamStr(I),'!');
      Halt(1);
     End;
     While Not EOF(FileRot13)do Begin
      ReadLn(FileRot13,CurrLine);
      WriteLn(Rot13C5DToString(CurrLine));
     End;
     Close(FileRot13);
    End;
   End
    Else
   Begin
    If OutputFileName<>''Then Begin
     {$I-}Assign(OutputFileRot13,OutputFileName);
     Rewrite(OutputFileRot13);{$I+}
     If IOResult<>0 Then Begin
      WriteLn('Impossible de cr‚er le fichier : ',OutputFileName,'!');
      Halt(2);
     End;
     WriteLn(OutputFileRot13,Rot13C5DToString(ParamStr(I)));
     Close(OutputFileRot13);
    End
     Else
    WriteLn(Rot13C5DToString(ParamStr(I)));
   End;
  End;
 End
  Else
 While Not EOF(Input) do Begin
  ReadLn(CurrLine);
  WriteLn(Rot13C5DToString(CurrLine));
 End;
END.

