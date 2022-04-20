{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal)
}

Program Reboot;

Var
 FirstParam:String;

BEGIN
 FirstParam:=ParamStr(1);
 If FirstParam='/?'Then Begin
  WriteLn('REBOOT   Cette commande permet de redemarrer l''ordinateur');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('REBOOT [/?]');
  WriteLn;
  WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 Begin
  {$IFNDEF FPC}
   MemW[Seg0040:$72]:=$1234;
   ASM
    INT 19h
   END;
  {$ENDIF}
 End;
END.