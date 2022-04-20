{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program TOUCH;

Uses DOS;

Var
 OptionFlag:(_None,_t);
 DT:DateTime;
 Err:Word;
 NewTime:LongInt;
 FileTouch:File;
 I:Integer;
 TimeString:String;
 FileName:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('TOUCH : Cette commande permet de modifier leur d''un fichier.');
  WriteLn;
  WriteLn('Syntaxe : TOUCH [-t CCAAMMJJhhmmSS] nomdufichier');
  WriteLn;
  WriteLn('Exemple : TOUCH abcd.txt -t 20100101235910');
 End
  Else
 Begin
  OptionFlag:=_None;
  FileName:='';
  TimeString:='';
  For I:=1 to ParamCount do Begin
   If OptionFlag<>_None Then Begin
    Case OptionFlag of
     _t:TimeString:=ParamStr(I);
    End;
    OptionFlag:=_None;
   End
    Else
   If ParamStr(I)='-t'Then OptionFlag:=_t
    Else
   Begin
    FileName:=ParamStr(I);
    OptionFlag:=_None;
   End;
  End;
  If FileName<>''Then Begin
   Assign(FileTouch,FileName);
   {$I-}Reset(FileTouch);{$I+}
   If IOResult<>0 Then Rewrite(FileTouch);
   If TimeString<>''Then Begin
    Val(Copy(TimeString,1,4),DT.Year,Err);
    Val(Copy(TimeString,5,2),DT.Month,Err);
    Val(Copy(TimeString,7,2),DT.Day,Err);
    Val(Copy(TimeString,9,2),DT.Hour,Err);
    Val(Copy(TimeString,11,2),DT.Min,Err);
    Val(Copy(TimeString,13,2),DT.Sec,Err);
    PackTime(DT,NewTime);
    SetFTime(FileTouch,NewTime);
   End;
   Close(FileTouch);
  End;
 End;
END.
