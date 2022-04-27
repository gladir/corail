{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program WHICH;

Uses DOS;

Var
 J,I:Integer;
 PATH,TPath,FullName:String;

Function FileExist(Name:String):Boolean;
Var
 Rec:SearchRec;
Begin
 FindFirst(Name,AnyFile,Rec);
 FileExist:=DosError=0;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('WHICH : Cette commande permet de localiser l''emplacement ',
                   'd''une commande.');
  WriteLn;
  WriteLn('Syntaxe : WHICH nomdufichier');
 End
  Else
 Begin
  For J:=1 to ParamCount do Begin
   PATH:=GetEnv('PATH');
   TPath:='';
   For I:=1 to Length(PATH)do Begin
    If PATH[I]=';'Then Begin
     FullName:=FExpand(TPath);
     If Not(FullName[Length(FullName)]in['\','/'])Then FullName:=FullName+'\';
     FullName:=FullName+ParamStr(1);
     If FileExist(FullName)Then Begin
      WriteLn(FullName);
      TPath:='';
      Break;
     End;
     If FileExist(FullName+'.EXE')Then Begin
      WriteLn(FullName,'.EXE');
      TPath:='';
      Break;
     End;
     TPath:='';
    End
     Else
    TPath:=TPath+Path[I];
   End;
   If TPath<>''Then Begin
    FullName:=FExpand(TPath);
    If Not(FullName[Length(FullName)]in['\','/'])Then FullName:=FullName+'\';
    FullName:=FullName+ParamStr(1);
    If FileExist(FullName)Then Begin
     WriteLn(FullName);
     TPath:='';
     Break;
    End;
    If FileExist(FullName+'.EXE')Then Begin
     WriteLn(FullName,'.EXE');
     TPath:='';
     Break;
    End;
   End;
  End;
 End;
END.