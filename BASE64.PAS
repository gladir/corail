{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program BASE64(Input,Output);

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

Function Base64ToString(S:String):String;
Const
 base64Alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
Var
 c,c2:String;
 sum:LongInt;
 i,j,bitModifier:Integer;
 toProcess,StrResult:String;
Begin
 StrResult:='';
 toProcess:='';
 For i:=1 to (Length(S) + 1) do Begin
  c:=S[i];
  If Length(toProcess) = 4 Then Begin
   sum:=0;
   bitModifier:=18;
   For j:=1 to Length(toProcess) do Begin
    c2:=toProcess[j];
    sum:=sum+((pos(c2, base64Alphabet) - 1) shl bitModifier);
    Dec(bitModifier,6);
   End;
   Insert(Chr((sum shr 16) and 255), StrResult, Length(StrResult)+1);
   Insert(Chr((sum shr 8) and 255), StrResult, Length(StrResult)+1);
   Insert(Chr(sum and 255), StrResult, Length(StrResult)+1);
   toProcess:='';
  End;
  If c<>'='Then Begin
   If Pos(c,base64Alphabet) <> 0 Then Begin
    toProcess:=toProcess+c;
   End
    else
   If i<>(Length(S) + 1)Then Begin
    StrResult:=S;
    break;
   End;
  End
   Else
  Begin
   toProcess:=toProcess+'A';
  End;
 End;
 Base64ToString:=StrResult;
End;

Var
 I:Integer;
 Handle:File {$IFDEF FPC}of Byte{$ENDIF};
 HandleBase64:Text;
 CurrLine:String;
 ByteReaded:Integer;
 Decode:Boolean;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('BASE64 : Cette commande permet de retourner en base64 un fichier.');
  WriteLn;
  WriteLn('Syntaxe : BASE64 nomfichier [-d]');
 End
  Else
 If ParamCount>0Then Begin
  Decode:=False;
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='-d'Then Decode:=True;
  End;
  For I:=1 to ParamCount do Begin
   If ParamStr(I)<>'-d'Then Begin
    If(Decode)Then Begin
     Assign(HandleBase64,ParamStr(I));
     {$I-}Reset(HandleBase64);{$I+}
     If IOResult=0Then Begin
      While NOT EOF(HandleBase64)do Begin
       ReadLn(HandleBase64,CurrLine);
       WriteLn(Base64ToString(CurrLine));
      End;
      Close(HandleBase64);
     End
      Else
     WriteLn('Impossible de lire ',ParamStr(I));
    End
     Else
    Begin
     Assign(Handle,ParamStr(I));
     {$I-}Reset(Handle);{$I+}
     If IOResult=0Then Begin
      While NOT EOF(Handle)do Begin
       BlockRead(Handle,CurrLine[1],57,ByteReaded);
       CurrLine[0]:=Chr(ByteReaded);
       WriteLn(StringToBase64(CurrLine));
      End;
      Close(Handle);
     End
      Else
     WriteLn('Impossible de lire ',ParamStr(I));
    End;
   End;
  End;
 End
  Else
 Begin
  Repeat
   ReadLn(Input,CurrLine);
   WriteLn(StringToBase64(CurrLine));
  Until EOF;
 End;
END.
