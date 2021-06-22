{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program HEAD(Input,Output);

Type
 OptionFlagType=(_None,_Lines,_Bytes);

Var
 CurrSize,MaxLine,Err,MaxBuffer:Integer;
 I:Integer;
 FileView:Text;
  OptionFlag:OptionFlagType;
 FileName,CurrLine:String;

BEGIN
 OptionFlag:=_None;
 MaxLine:=10;
 MaxBuffer:=32767;
 FileName:='';
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('HEAD : Cette commande permet d''afficher le debut du fichier.');
  WriteLn;
  WriteLn('Syntaxe : head nomdufichier');
 End
  Else
 If ParamCount > 0 Then Begin
  For I:=1 to ParamCount do Begin
   If OptionFlag<>_None Then Begin
    Case OptionFlag of
     _Lines:Val(ParamStr(I),MaxLine,Err);
     _Bytes:Val(ParamStr(I),MaxBuffer,Err);
    End;
    OptionFlag:=_None;
   End
    Else
   If ParamStr(I)='--lines'Then OptionFlag:=_Lines Else
   If ParamStr(I)='--bytes'Then OptionFlag:=_Bytes
    Else
   Begin
    FileName:=ParamStr(I);
    OptionFlag:=_None;
   End;
  End;
  If FileName<>''Then Begin
   I:=0;
   Assign(FileView,FileName);
   Reset(FileView);
   While Not EOF(FileView)do Begin
    ReadLn(FileView,CurrLine);
    WriteLn(Output,CurrLine);
    Inc(CurrSize,Length(CurrLine));
    If CurrSize>MaxBuffer Then Break;
    Inc(I);
    If I>=MaxLine Then Break;
   End;
   Close(FileView);
  End
   Else
  Begin
   I:=0;
   While Not EOF do Begin
    ReadLn(Input,CurrLine);
    WriteLn(Output,CurrLine);
    Inc(CurrSize,Length(CurrLine));
    If CurrSize>MaxBuffer Then Break;
    Inc(I);
    If I > MaxLine Then Break;
   End;
  End;
 End
  Else
 Begin
  I:=0;
  While Not EOF do Begin
   ReadLn(Input,CurrLine);
   WriteLn(Output,CurrLine);
   Inc(CurrSize,Length(CurrLine));
   If CurrSize>MaxBuffer Then Break;
   Inc(I);
   If I > MaxLine Then Break;
  End;
 End;
END.