{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal 3.2, Turbo Pascal 7)
}

Program COMM;

Var
 File1,File2:Text;
 Line1,Line2:String;
 file1Line,file2Line:String;
 done1,done2:Boolean;
 FileName1,FileName2:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('COMM : Cette commande permet de sÇlectionner ou rejeter ',
                  'des lignes communes dans deux fichiers.');
  WriteLn;
  WriteLn('Syntaxe : COMM file1 file2');
 End
  Else
 If ParamCount>0Then Begin
  FileName1:=ParamStr(1);
  FileName2:=ParamStr(2);
  {$I-}Assign(file1,FileName1);
  Reset(file1);
  {$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de lire le premier fichier');
   Halt(1);
  End;
  {$I-}Assign(file2,FileName2);
  Reset(file2);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de lire le deuxiäme fichier');
   Halt(1);
  End;
  done1:=Not Eof(file1);
  done2:=Not Eof(file2);
  While done1 or done2 do Begin
   If(done1)Then ReadLn(file1,file1Line)
            Else file1Line:='';
   If(done2)Then ReadLn(file2,file2Line)
            Else file2Line:='';
   If(file1Line<file2Line)Then begin
    WriteLn(file1Line);
    done1:=Not Eof(file1);
    WriteLn(' ':8,file2Line);
   End
    Else
   If(file1Line>file2Line)Then Begin
    WriteLn(' ':8,file2Line);
    done2 := not Eof(file2);
    WriteLn(file1Line);
   End
    else
   Begin
    WriteLn(' ':16,file1Line);
    done1:=Not Eof(file1);
    done2:=Not Eof(file2);
   End;
  End;
  Close(file1);
  Close(file2);
 End
  Else
 Begin
  WriteLn('Paramätre requis !');
 End;
END.