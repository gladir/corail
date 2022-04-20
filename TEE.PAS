{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program TEE(Input,Output);

Var
 Option:Set Of (Ajouter);
 FileWrite:Text;
 I:Integer;
 CurrLine:String;
 FileName:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('TEE : Cette commande permet d''envoyer l''entr‚e standard vers la sortie standard.');
  WriteLn;
  WriteLn('Syntaxe : TEE [-a] [nomdufichier]');
 End
  Else
 Begin
  Option:=[];
  FileName:='';
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='-a'Then Include(Option,Ajouter)
                      Else FileName:=ParamStr(I);
  End;
  If FileName<>''Then Begin
   Assign(FileWrite,FileName);
   If(Ajouter in Option)Then Append(FileWrite)
                        Else Rewrite(FileWrite);
  End;
  While Not EOF do Begin
   ReadLn(Input,CurrLine);
   WriteLn(Output,CurrLine);
   If FileName<>''Then WriteLn(FileWrite,CurrLine);
  End;
  If FileName<>''Then Close(FileWrite);
 End;
END.

