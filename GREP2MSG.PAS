{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program Grep2Msg;

{$I-,S-}

Var
 LineNo,E:Word;
 Line:String;
 InputBuffer,OutputBuffer:Array[0..4095]of Char;

Procedure WriteHeader;Begin
 Write('BI#PIP#OK'#0);
End;

Procedure WriteNewFile(Const FileName:String);Begin
 Write(#0,FileName,#0)
End;

Procedure WriteMessage(Line,Col:Word;Const Message:String);Begin
 Write(#1,Chr(Line),Chr(Hi(Line)),Chr(Col),Chr(Hi(Col)),Message,#0);
End;

Procedure WriteEnd;Begin
 Write(#127)
End;

Function LTrim(S:String):String;Var i:Integer;n:String;Begin
 i:=1;
 While(i<=Length(s))and(s[i]=#32)do Inc(i);
 If i<=Length(s)Then Begin
  Move(s[i],n[1],Length(s)-i+1);
  n[0]:=Char(Length(s)-i+1);
 End
  else
 n[0]:=#0;
 LTrim:=n;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('GREP2MSG: Cette programme permet de capturer les messages et de les retourner a Turbo Pascal.');
  WriteLn;
  WriteLn('Syntaxe: GREP2MSG [/?]');
 End
  Else
 Begin
  SetTextBuf(Input,InputBuffer);
  SetTextBuf(Output,OutputBuffer);
  WriteHeader;
  While Not(Eof)do Begin
   ReadLn(Line);
   If Line<>''Then Begin
    If Copy(Line,1,5)='File 'Then WriteNewFile(Copy(Line,6,Length(Line)-6))
     else
    Begin
     Val(Copy(Line,1,Pos(' ',Line)-1),LineNo,E);
     If E=0Then WriteMessage(LineNo,1,LTrim(Copy(Line,9,132)));
    End;
   End;
  End;
  WriteEnd;
 End;
END.