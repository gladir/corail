{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program TCC2Msg;

{$I-,S-}

Var
 LineNo,E:Word;Line,Target:String;
 InputBuffer:Array[0..4095]of Char;
 OutputBuffer:Array[0..4095]of Char;

Procedure WriteHeader;Begin
 Write('BI#PIP#OK'#0)
End;

Procedure WriteNewFile(FileName:String);
Var
 I:Byte;
Begin
 While FileName[1]=' 'do FileName:=Copy(FileName,2,Length(FileName)-1);
 For I:=1to Length(FileName)do If FileName[I]in[' ','(']Then Break;
 Write(#0,Copy(FileName,1,I-1),#0);
 Target:=Copy(FileName,I,Length(FileName)-I+2);
 If Target[1]='('Then Target:=Copy(Target,2,Length(Target)-1)
End;

Procedure WriteMessage(Line:Word;Const Message:String);Begin
 Write(#1,Chr(Lo(Line)),Chr(Hi(Line)),#1,#0,Message,#0)
End;

Procedure WriteEnd;Begin
 Write(#127);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('TCC2MSG: Cette programme permet de capturer les messages TCC et de les retourner a Turbo Pascal.');
  WriteLn;
  WriteLn('Syntaxe: TCC2MSG [/?]');
 End
  Else
 Begin
  SetTextBuf(Input,InputBuffer);
  SetTextBuf(Output,OutputBuffer);
  WriteHeader;
  While Not(Eof)do Begin
   ReadLn(Line);
   If Copy(Line,1,9)='**Error**'Then Begin
    WriteNewFile(Copy(Line,10,Length(Line)-9));
    Val(Copy(Target,1,Pos(')',Target)-1),LineNo,E);
    If E=0Then WriteMessage(LineNo,'Error:'+Copy(Target,Pos(')',Target)+1,132));
   End;
   If Copy(Line,1,9)='*Warning*'Then Begin
    WriteNewFile(Copy(Line,10,Length(Line)-9));
    Val(Copy(Target,1,Pos(')',Target)-1),LineNo,E);
    If E=0Then WriteMessage(LineNo,'Warning:'+Copy(Target,Pos(')',Target)+1,132));
   End;
   If Copy(Line,1,6)='Error 'Then Begin
    WriteNewFile(Copy(Line,6,Length(Line)-5));
    Val(Copy(Target,1,Pos(':',Target)-1),LineNo,E);
    If E=0Then WriteMessage(LineNo,'Error'+Copy(Target,Pos(':',Target),132));
   End;
   If Copy(Line,1,8)='Warning 'Then Begin
    WriteNewFile(Copy(Line,8,Length(Line)-7));
    Val(Copy(Target,1,Pos(':',Target)-1),LineNo,E);
    If E=0Then WriteMessage(LineNo,'Warning'+Copy(Target,Pos(':',Target),132));
   End;
  End;
  WriteEnd;
 End;
END.
