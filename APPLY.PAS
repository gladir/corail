{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program APPLY;

{$M 16384,0,0}

Uses DOS;

Var
 I:Integer;
 NoFile:Boolean;
 FileASCII:Text;
 CurrParam,CurrCommand,Command,FileName,CurrLine:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('APPLY : Cette commande permet d''appliquer des commandes ',
          'Ö plusieurs reprises.');
  WriteLn;
  WriteLn('Syntaxe : APPLY fichier "command"');
 End
  Else
 If ParamCount>0 Then Begin
  Command:='';
  FileName:='';
  NoFile:=False;
  For I:=1 to ParamCount do Begin
   CurrParam:=ParamStr(I);
   If CurrParam='-'Then NoFile:=True Else
   If Copy(CurrParam,1,1)='"'Then Begin
    Command:=Copy(CurrParam,2,Length(CurrParam)-2);
   End
    Else
   If Pos('.',CurrParam)>0 Then Begin
    FileName:=CurrParam;
   End
    Else
   Command:=CurrParam;
  End;
  If Command=''Then Begin
   WriteLn('Commande requise');
  End
   Else
  If NoFile Then Begin
   If Pos('%',Command)>0 Then Begin
    CurrCommand:=Copy(Command,1,Pos('%',Command)-1)+
                 Copy(Command,Pos('%',Command)+1,255);
   End
    Else
   CurrCommand:=Command;
   Exec(GetEnv('COMSPEC'),'/C '+CurrCommand);
  End
   Else
  If FileName=''Then Begin
   WriteLn('Nom de fichier absent');
  End
   Else
  Begin
   {$I-}Assign(FileASCII,FileName);
   Reset(FileASCII);{$I+}
   If IOResult=0 Then Begin
    While Not(EOF(FileASCII))do Begin
     ReadLn(FileASCII,CurrLine);
     If Pos('%',Command)>0 Then Begin
      CurrCommand:=Copy(Command,1,Pos('%',Command)-1)+CurrLine+
                   Copy(Command,Pos('%',Command)+1,255);
     End
      Else
     CurrCommand:=Command;
     Exec(GetEnv('COMSPEC'),'/C '+CurrCommand);
    End;
    Close(FileASCII);
   End;
  End;
 End
  Else
 WriteLn('Paramätre requis !');
END.