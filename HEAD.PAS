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
  WriteLn('HEAD : Cette commande permet d''afficher le d‚but du fichier.');
  WriteLn;
  WriteLn('Syntaxe : head nomdufichier [--bytes N] [--lines N]');
  WriteLn;
  WriteLn(' nomdufichier Ce paramŠtre permet d''indiquer le fichier … afficher.');
  WriteLn(' --bytes N    Ce paramŠtre permet d''afficher les nombres ',
                         'd''octets sp‚cifi‚ … partir du d‚but.');
  WriteLn(' --lines N    Ce paramŠtre permet d''afficher le nombre de ',
                         'ligne sp‚cifi‚ … partir du d‚but.');
  WriteLn(' -n N         Ce paramŠtre permet d''afficher le nombre de ',
                         'ligne sp‚cifi‚ … partir du d‚but.');
 End
  Else
 If ParamCount>0 Then Begin
  For I:=1 to ParamCount do Begin
   If OptionFlag<>_None Then Begin
    Case OptionFlag of
     _Lines:Begin
      Val(ParamStr(I),MaxLine,Err);
      If Err>0 Then Begin
       WriteLn('Nombre de lignes invalides !');
       Halt(2);
      End;
     End;
     _Bytes:Begin
      Val(ParamStr(I),MaxBuffer,Err);
      If Err>0 Then Begin
       WriteLn('Tampon du tampon invalides !');
       Halt(3);
      End;
     End;
    End;
    OptionFlag:=_None;
   End
    Else
   If ParamStr(I)='--lines'Then OptionFlag:=_Lines Else
   If ParamStr(I)='-n'Then OptionFlag:=_Lines Else
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
   Begin
    WriteLn('Erreur de lecture du fichier ',FileName);
    Halt(1);
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
    If I>=MaxLine Then Break;
   End;
  End;
 End
  Else
 Begin
  I:=0;
  While Not EOF do Begin
   {$I-}ReadLn(Input,CurrLine);{$I+}
   If IOResult<>0 Then Begin
    WriteLn('Erreur de lecture des donn‚es');
    Halt(4);
   End;
   WriteLn(Output,CurrLine);
   Inc(CurrSize,Length(CurrLine));
   If CurrSize>MaxBuffer Then Break;
   Inc(I);
   If I>=MaxLine Then Break;
  End;
 End;
END.
