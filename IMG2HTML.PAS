{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program IMG2HTML;

Var
 First:Boolean;
 HandleIMG:File;
 HandleHTML:Text;
 CurrLine:String;
 ByteReaded:Integer;

Function ToBase64(value:Integer):String;Begin
 Case value of
  0..25:ToBase64:=Char(65+value);
  26..51:ToBase64:=Char(97+(value - 26));
  52..61:ToBase64:=Char(48+(value-52));
  62:ToBase64:='+';
  63:ToBase64:='/';
  Else ToBase64:='';
 End;
End;

Function StringToBase64(S:String):String;
Var
 StrResult:String;
 I,J:Integer;
 _Dim:Integer;
 _Low:Integer;
Begin
 StrResult:='';
 I:=1;
 While I<=Length(S) do Begin
  _Low:=(Ord(S[I]) Mod 4) * 16;
  StrResult:=StrResult+ToBase64(Ord(S[I]) div 4);
  If Length(S)-I+1=1 Then Begin
   StrResult:=StrResult+ToBase64(_Low);
  End
   Else
  Begin
   StrResult:=StrResult+ToBase64(_Low+(Ord(S[I+1]) div 16));
  End;
  If Length(S)-I+1>1 Then Begin
   StrResult:=StrResult+ToBase64((((Ord(S[I+1]) mod 16)*4)+(Ord(S[I+2]) div 64)));
   If Length(S) - I + 1>2 Then Begin
    StrResult:=StrResult+ToBase64(Ord(S[I+2]) Mod 64);
   End
    Else
   Begin
    StrResult:=StrResult+'=';
   End;
  End
   Else
  StrResult:=StrResult+'==';
  Inc(I,3);
 End;
 StringToBase64:=StrResult;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('IMG2HTML : Cette commande permet de convertir une image en code HTML.');
  WriteLn;
  WriteLn('Syntaxe : IMG2HTML image.png fichier.html');
 End
  Else
 If ParamCount>0Then Begin
  Assign(HandleIMG,ParamStr(1));
  {$I-}Reset(HandleIMG,1);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Image de fichier introuvable');
   Halt;
  End;
  Assign(HandleHTML,ParamStr(2));
  {$I-}Rewrite(HandleHTML);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier HTML introuvable');
   Close(HandleHTML);
   Halt;
  End;
  First:=True;
  Write(HandleHTML,'<img src="data:image/png;base64, ');
  If IOResult=0Then Begin
   While NOT EOF(HandleIMG)do Begin
    If(First)Then Begin
     First:=False;
     BlockRead(HandleIMG,CurrLine[1],21,ByteReaded);
    End
     Else
    Begin
     WriteLn(HandleHTML);
     BlockRead(HandleIMG,CurrLine[1],45,ByteReaded);
    End;
    CurrLine[0]:=Chr(ByteReaded);
    Write(HandleHTML,StringToBase64(CurrLine));
   End;
   WriteLn(HandleHTML,'">');
   Close(HandleHTML);
   Close(HandleIMG);
  End;
 End;
END.