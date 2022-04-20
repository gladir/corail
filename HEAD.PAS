{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
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

Function StringToChar(S:String;Index:Byte):Char;Begin
 If Length(S)<=Index Then StringToChar:=S[Index]
                     Else StringToChar:=#0;
End;

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
   If ParamStr(I)='--bytes'Then OptionFlag:=_Bytes Else
   If((Length(ParamStr(I))>=2) and (StringToChar(ParamStr(I),1)='-')and(StringToChar(ParamStr(I),2)in['0'..'9']))Then Begin
    Val(Copy(ParamStr(I),2,255),MaxLine,Err);
   End
    Else
   Begin
    FileName:=ParamStr(I);
    OptionFlag:=_None;
   End;
  End;
  If FileName<>''Then Begin
   I:=0;
   {$I-}Assign(FileView,FileName);
   Reset(FileView);{$I+}
   If IoResult=0Then Begin
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
   WriteLn('Erreur de lecture du fichier ',FileName);
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
