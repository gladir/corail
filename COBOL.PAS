{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program COBOL;

Const
 MaxLine=1024;

Type
 StrPointer=^String;

Var
 NumberLine:Integer;
 PA:Array[1..MaxLine] of StrPointer;

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

Function TrimR(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 TrimR:=S;
End;

Function Trim(S:String):String;Begin
 Trim:=TrimL(TrimR(s));
End;

Function RPos(Ch:Char;Const S:String):Integer;
Var
 i:Integer;
Begin
 For i:=Length(s) downto 1 do If s[i]=ch Then Begin
  RPos:=i;
  Exit;
 End;
 RPos:=0;
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

Function AddLine(S:String):Boolean;
Var
 P:StrPointer;
Begin
 If(NumberLine>=MaxLine)Then Begin
  AddLine:=False;
  Exit;
 End;
 Inc(NumberLine);
 GetMem(P,Length(S)+1);
 P^:=S;
 PA[NumberLine]:=P;
 AddLine:=True;
End;

Procedure RunLine(Line:String);
Var
 Prefix,Content:String;
 StartQuote,EndQuote:Integer;
Begin
 Line:=Trim(Line);
 Prefix:=Copy(Line,1,7);
 If StrToUpper(Prefix)='DISPLAY' Then Begin
  StartQuote:=Pos('"',Line);
  EndQuote:=RPos('"',Line);
  If(StartQuote>0)and(EndQuote>StartQuote)Then Begin
   Content:=Copy(Line,StartQuote+1,EndQuote-StartQuote-1);
   WriteLn(Content);
  End
   Else
  WriteLn('Erreur : chaåne mal formÇe dans DISPLAY.');
 End
  Else
 If Line<>''Then WriteLn('Instruction non reconnue : ',Line);
End;

Procedure InterpretFile(Filename:String);
Var
 FileLoad:Text;
 S:String;
 i:Integer;
Begin
 {$I-}Assign(FileLoad,FileName);
 Reset(FileLoad);{$I+}
 If IoResult<>0Then Begin
  WriteLn('Fichier introuvable');
  Exit;
 End;
 NumberLine:=0;
 While Not EOF(FileLoad) do Begin
  ReadLn(FileLoad,S);
  If Not AddLine(TrimL(S))Then Begin
   WriteLn('Manque de mÇmoire');
   Break;
  End;
 End;
 Close(FileLoad);
 For i:=1 to NumberLine do RunLine(PA[i]^);
end;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('COBOL : Cette commande permet de lancer l''interpreteur de COBOL.');
  WriteLn;
  WriteLn('Syntaxe : COBOL [option] [fichier.COB]');
  WriteLn;
  WriteLn(' fichier.COB   Nom du fichier de COBOL');
  WriteLn(' --version     Version de la commande');
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('COBOL 0.1 - InterprÇteur de COBOL de Corail, COBOL-0');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('êcrit par Sylvain Maltais');
 End
  Else
 If ParamCount>0 Then Begin
  InterpretFile(ParamStr(1))
 End
  Else
 Begin
  WriteLn('Paramätre attendu !');
 End;
END.