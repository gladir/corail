{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal, Turbo Pascal)
}

Program Python;

Uses Crt,DOS;

Const
 ReservedWordList:Array[0..29]of String[10]=(
  'and','assert','break','class','continue','def','del',
  'elif','else','except','exec','finally','for',
  'from','global','if','import','in','is','lambda',
  'not','or','pass','print','raise','return','try',
  'while','with','yield'
 );

 MaxLine=1024;

Type
 StrPointer=^String;

Var
 Terminated:Boolean;
 CurrCommand:String;
 FileName,CurrLine:String;
 PA:Array[1..MaxLine] of StrPointer;
 CurrLinePtr,NumberLine:Integer;
 CurrNumberLine:Integer;
 I:Integer;
 CurrPos:Byte;

Function LTrim(S:String):String;
Var
 I:Integer;
Begin
 I:=1;
 While(I<=Length(s)) and (S[I] in [#9,' ']) do Inc(I);
 Delete(S,1,I-1);
 LTrim:=S;
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

 { Traitement de la liste }
Function AddLine(S:String):Boolean;
Var
 P:StrPointer;
Begin
 If NumberLine>=MaxLine Then Begin
  AddLine:=False;
  Exit;
 End;
 Inc(NumberLine);
 GetMem(P,Length(S)+1);
 P^:=S;
 PA[NumberLine]:=P;
 AddLine:=True;
End;

Function IsStringValue:Boolean;Begin
 IsStringValue:=False;
 If CurrLine[CurrPos]in['''','"']Then Begin
  IsStringValue:=True;
 End;
End;

Function ExtractCommand:Byte;
Var
 I:Byte;
Begin
 ExtractCommand:=255;
 CurrCommand:='';
 For I:=CurrPos to Length(CurrLine)do Begin
  If Not(CurrLine[I]in['A'..'Z','a'..'z','_'])Then Begin
   CurrCommand:=Copy(CurrLine,CurrPos,I-CurrPos);
   CurrPos:=I;
   Break;
  End;
 End;
 If CurrCommand=''Then Begin
  CurrCommand:=Copy(CurrLine,CurrPos,255);
  CurrPos:=Length(CurrLine)+1;
 End;
 For I:=Low(ReservedWordList)to High(ReservedWordList)do Begin
  If CurrCommand=ReservedWordList[I]Then Begin
   ExtractCommand:=I;
   Exit;
  End;
 End;
End;

Function GetStringValue:String;
Var
 J:Integer;
 _Result:Real;
 FunctionFound:Boolean;
 S,VarName:String;
Begin
 GetStringValue:='';
 S:='';
 If CurrLine[CurrPos]=''''Then Begin
  Inc(CurrPos);
  While(CurrLine[CurrPos]<>'''')and(CurrPos<=Length(CurrLine))do Begin
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
  If CurrLine[CurrPos]=''''Then Inc(CurrPos);
 End
  Else
 If CurrLine[CurrPos]='"'Then Begin
  Inc(CurrPos);
  While(CurrLine[CurrPos]<>'"')and(CurrPos<=Length(CurrLine))do Begin
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
  If CurrLine[CurrPos]='"'Then Inc(CurrPos);
 End;
 GetStringValue:=S;
End;

Procedure SkipSpace;Begin
 While(CurrLine[CurrPos]in[' '])and(CurrPos<Length(CurrLine))do Inc(CurrPos);
End;

Function GetSeparator:Char;Begin
 If CurrPos>Length(CurrLine)Then Begin
  GetSeparator:=#0;
  Exit;
 End;
 SkipSpace;
 GetSeparator:=CurrLine[CurrPos];
End;

Procedure LoadCommand;
Var
 FileLoad:Text;
 S:String;
Begin
 If FileName<>''Then Begin
  {$I-}Assign(FileLoad,FileName);
  Reset(FileLoad);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier introuvable');
   Exit;
  End;
  {NewCommand;}
  While Not EOF(FileLoad) do Begin
   ReadLn(FileLoad,S);
   If Not AddLine(LTrim(S))Then Begin
    WriteLn('Manque de m‚moire');
    Break;
   End;
  End;
  Close(FileLoad);
 End
  Else
 WriteLn('Nom du fichier absent');
End;

Procedure PrintCommand;
Var
 Paren:Boolean;
Begin
 Paren:=False;
 SkipSpace;
 If GetSeparator='('Then Begin
  Inc(CurrPos);
  Paren:=True;
 End;
 If IsStringValue Then Begin
  WriteLn(GetStringValue);
 End;
 If(Paren)Then Begin
  If GetSeparator=')'Then Begin
   Inc(CurrPos);
  End
   Else
  Begin
   WriteLn('ParenthŠse fermeture attendue !');
   Halt(2);
  End;
 End;
End;

Function RunLine:Boolean;
Var
 R1:Real;
 UnknownCommand:Boolean;
 NoImplementation:Boolean;
Begin
 RunLine:=False;
 CurrPos:=1;
 NoImplementation:=False;
 UnknownCommand:=False;
 Case ExtractCommand of
  0:NoImplementation:=True;{and}
  1:NoImplementation:=True;{assert}
  2:NoImplementation:=True;{break}
  3:NoImplementation:=True;{class}
  4:NoImplementation:=True;{continue}
  5:NoImplementation:=True;{def}
  6:NoImplementation:=True;{del}
  7:NoImplementation:=True;{elif}
  8:NoImplementation:=True;{else}
  9:NoImplementation:=True;{except}
  10:NoImplementation:=True;{exec}
  11:NoImplementation:=True;{finally}
  12:NoImplementation:=True;{for}
  13:NoImplementation:=True;{from}
  14:NoImplementation:=True;{global}
  15:NoImplementation:=True;{if}
  16:NoImplementation:=True;{import}
  17:NoImplementation:=True;{in}
  18:NoImplementation:=True;{is}
  19:NoImplementation:=True;{lambda}
  20:NoImplementation:=True;{not}
  21:NoImplementation:=True;{or}
  22:NoImplementation:=True;{pass}
  23:PrintCommand;{print}
  24:NoImplementation:=True;{raise}
  25:NoImplementation:=True;{return}
  26:NoImplementation:=True;{try}
  27:NoImplementation:=True;{while}
  28:NoImplementation:=True;{with}
  29:NoImplementation:=True;{yield}
  Else UnknownCommand:=True;
 End;
 If(UnknownCommand)Then Begin
  WriteLn('Mot r‚serv‚ non reconnu');
  Exit;
 End
  Else
 If(NoImplementation)Then Begin
  WriteLn('Ce mot r‚serv‚ n''a pas ‚t‚ impl‚ment‚');
  Exit;
 End;
 RunLine:=True;
End;

Procedure ExecuteCommand;
Var
 J:Integer;
 Err:Integer;
 S1:String;
Begin
 If NumberLine>0Then Begin
  CurrLinePtr:=1;
  While(CurrLinePtr<=NumberLine) do Begin
   CurrLine:=PA[CurrLinePtr]^;
   CurrNumberLine:=0;
   J:=1;
   While(J<Length(CurrLine))do Begin
    If Not(CurrLine[J]in['0'..'9'])Then Begin
     Val(Copy(CurrLine,1,J-1),CurrNumberLine,Err);
     Break;
    End;
    Inc(J);
   End;
   While J<=Length(CurrLine)do Begin
    If CurrLine[J]in[' ',#9]Then Inc(J)
                            Else Break;
   End;
   CurrPos:=J;
   If Not(RunLine)Then Break;
   Inc(CurrLinePtr);
  End;
 End;
End;

Procedure RunCommandMode;Begin
 Terminated:=False;
 Repeat
  Write('>>>');
  ReadLn(CurrLine);
  If CurrLine='quit'Then Exit;
  RunLine;
 Until Terminated;
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('PYTHON : Cette commande permet de lancer le langage de programmation Python');
  WriteLn;
  WriteLn('Syntaxe : PYTHON [fichier.PY]');
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('PYTHON 0.1 - Clone Pascal de Python pour Corail, Linux-0 et PYTHON-0');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('crit par Sylvain Maltais');
 End
  Else
 Begin
  FileName:='';
  NumberLine:=0;CurrNumberLine:=0;
  If ParamCount>0 Then Begin
   For I:=1 to ParamCount do Begin
    FileName:=ParamStr(I);
   End;
   LoadCommand;
   ExecuteCommand;
  End
   Else
  RunCommandMode;
 End;
END.
