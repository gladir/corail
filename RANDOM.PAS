{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program _RANDOM;

Var
 Silence:Boolean;
 R,I,Scale:Integer;
 Err:Word;

BEGIN
 Randomize;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('RANDOM : Cette commande permet de g�n�rer un nombre al�atoire.');
  WriteLn;
  WriteLn('Syntaxe : RANDOM [-s] [scale]');
  WriteLn;
  WriteLn(' -s     Indique qu''il ne faut afficher le nombre al�atoire');
  WriteLn(' scale  Indique la limite sup�rieur de l''intervalle du nombre al�atoire');
 End
  Else
 If ParamCount>0 Then Begin
  Silence:=False;
  Scale:=2;
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='-s'Then Silence:=True
    Else
   Begin
    Val(ParamStr(I),Scale,Err);
    If Err>0 Then Begin
     WriteLn('�chelle invalide !');
     Halt(0);
    End;
    If(Scale<1)or(Scale>255)Then Begin
     WriteLn('La valeur de l''�chelle est en dehors de l''intervalle');
     Halt(0);
    End;
   End;
  End;
  R:=Random(Scale);
  If Not(Silence)Then WriteLn(R);
  Halt(R);
 End
  Else
 Begin
  R:=Random(2);
  WriteLn(R);
  Halt(R);
 End;
END.