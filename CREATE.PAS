{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program CREATE;

Var
 OptionFlag:(None,LRL,REC,SIZE);
 Err:Word;
 Handle:File;
 I:Integer;
 LRLValue,RecValue,SizeValue,FileName:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('CREATE : Cette commande permet de creer un fichier.');
  WriteLn;
  WriteLn('Syntaxe : CREATE nomdufichier');
 End
  Else
 Begin
  OptionFlag:=None;
  FileName:='';
  For I:=1 to ParamCount do Begin
   If OptionFlag<>None Then Begin
    Case OptionFlag of
     LRL:LRLValue:=ParamStr(I);
     REC:RECValue:=ParamStr(I);
     SIZE:SIZEValue:=ParamStr(I);
    End;
    OptionFlag:=None;
   End
    Else
   If ParamStr(I)='LRL='Then OptionFlag:=LRL Else
   If ParamStr(I)='REC='Then OptionFlag:=REC Else
   If ParamStr(I)='SIZE='Then OptionFlag:=SIZE
    Else
   Begin
    FileName:=ParamStr(I);
    OptionFlag:=None;
   End;
  End;
  If FileName<>''Then Begin
   Assign(Handle,FileName);
   {$I-}Reset(Handle);{$I+}
   If IOResult<>0 Then Rewrite(Handle);
   Close(Handle);
  End;
 End;
END.