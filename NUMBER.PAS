{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program Number(Input,Output);

Function NumberToString(X:Integer):String;
Var
 Skip:Boolean;
 Unite,Dizaine,Centaine,Millier:Integer;
 S:String;
Begin
 S:='';
 If X=0Then S:='Zero'
  Else
 Begin
  Skip:=False;
  Unite:=X mod 10;
  Dizaine:=(X div 10)mod 10;
  Centaine:=(X div 100)mod 10;
  Millier:=(X div 1000)mod 10;
  Case Centaine of
   1:S:=S+'mille ';
   2:S:=S+'deux mille ';
   3:S:=S+'trois mille ';
   4:S:=S+'quatre mille ';
   5:S:=S+'cinq mille ';
   6:S:=S+'six mille ';
   7:S:=S+'sept mille ';
   8:S:=S+'huit mille ';
   9:S:=S+'neuf mille ';
  End;
  Case Centaine of
   1:S:=S+'cent ';
   2:S:=S+'deux cents ';
   3:S:=S+'trois cents ';
   4:S:=S+'quatre cents ';
   5:S:=S+'cinq cents ';
   6:S:=S+'six cents ';
   7:S:=S+'sept cents ';
   8:S:=S+'huit cents ';
   9:S:=S+'neuf cents ';
  End;
  Case Dizaine of
   1:Begin
    If Unite in[1..6]Then Begin
     Case Unite of
      1:S:=S+'onze';
      2:S:=S+'douze';
      3:S:=S+'treize';
      4:S:=S+'quatorze';
      5:S:=S+'quinze';
      6:S:=S+'seize';
     End;
     Skip:=True;
    End
     Else
    S:=S+'dix';
   End;
   2:Begin
    S:=S+'vingt';
    If Unite=1Then Begin
     S:=S+' et un';
     Skip:=True;
    End;
   End;
   3:S:=S+'trente';
   4:S:=S+'quarante';
   5:S:=S+'cinquante';
   6:S:=S+'soixante';
   7:S:=S+'soixante-dix';
   8:S:=S+'quatre-vingt';
   9:S:=S+'quatre-vingt-dix';
  End;
  If Not(Skip)Then Begin
   If(Dizaine<>0)and (Unite>1)Then S:=S+'-';
   Case Unite mod 10 of
    1:S:=S+'un';
    2:S:=S+'deux';
    3:S:=S+'trois';
    4:S:=S+'quatre';
    5:S:=S+'cinq';
    6:S:=S+'six';
    7:S:=S+'sept';
    8:S:=S+'huit';
    9:S:=S+'neuf';
   End;
  End;
 End;
 NumberToString:=S;
End;

Var
 Value:Integer;
 Err:Word;

BEGIN
 If ParamStr(1)='/?'Then Begin
  WriteLn('NUMBER : Cette commande permet d''afficher un nombre en texte.');
  WriteLn;
  WriteLn('Syntaxe : NUMBER chiffre');
 End
  Else
 Begin
  Val(ParamStr(1),Value,Err);
  WriteLn(NumberToString(Value));
 End;
END.
