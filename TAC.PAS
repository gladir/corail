{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program TAC;

Var
 Before:Boolean;
 I:Integer;
 Handle:File;
 C:Char;
 ByteReaded:Word;
 CurrLine:String;
 FS,FilePos:LongInt;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('TAC : Cette commande permet d''afficher le contenu du ',
                 'fichier dans le sens inverse.');
  WriteLn;
  WriteLn('Syntaxe : TAC [option] [fichier]');
  WriteLn;
  WriteLn(' fichier    Ce paramŠtre permet d''indiquer le fichier … afficher');
  WriteLn(' -b         Ce paramŠtre fixe le s‚parateur avant au lieu d''aprŠs.');
  WriteLn(' --before   Ce paramŠtre fixe le s‚parateur avant au lieu d''aprŠs.');
  WriteLn(' --help     Ce paramŠtre permet d''afficher l''aide de cette commande.');
  WriteLn(' --version  Ce paramŠtre permet d''indiquer la version de la commande.');
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('TAC 1.0 - Clone Pascal de coreutils');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('crit par Sylvain Maltais');
 End
  Else
 If ParamCount>0Then Begin
  Before:=False;
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='-b')or(ParamStr(I)='--before')Then Before:=True;
  End;
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='-b')or(ParamStr(I)='--before')Then Begin
    { Saute ... }
   End
    Else
   Begin
    Assign(Handle,ParamStr(I));
    {$I-}Reset(Handle,1);{$I+}
    If IOResult=0Then Begin
     FS:=FileSize(Handle);
     If FS>0 Then Begin
      FilePos:=FS-1;
      CurrLine:='';
      While FilePos>=0 do Begin
       Seek(Handle,FilePos);
       BlockRead(Handle,C,1,ByteReaded);
       Dec(FilePos);
       If ByteReaded=0 Then Break;
       Case C of
        #13:Begin
         If(Before)Then Write(#13,#10,CurrLine)
                   Else WriteLn(CurrLine);
         CurrLine:='';
        End;
        #10:;
        Else Begin
         CurrLine:=C+CurrLine;
        End;
       End;
      End;
      WriteLn(CurrLine);
     End;
     Close(Handle);
    End
     Else
    Begin
     WriteLn('Impossible de lire ',ParamStr(I));
     Halt(1);
    End;
   End;
  End;
 End
  Else
 Begin
  Repeat
   ReadLn(Input,CurrLine);
   WriteLn(CurrLine);
  Until EOF;
 End;
END.