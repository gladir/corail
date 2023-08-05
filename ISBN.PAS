{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program ISBN;

Var
 S:String;
 I,Len,M:Byte;
 CheckSum:Integer;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('ISBN: Cette commande permet de v‚rifier si un code ISBN est valide.');
  WriteLn;
  WriteLn('Syntaxe: ISBN isbnnumber');
  WriteLn;
  WriteLn('isbnnumber  Ce paramŠtre permet d''indiquer le num‚ro ISBN');
 End
  Else
 Begin
  S:=ParamStr(1);
  Write('V‚rification du num‚ro ISBN ',S,' : ');
  Len:=0;
  For I:=1 to Ord(S[0])do If S[I]in['0'..'9']Then Begin
   Inc(Len);
   S[Len]:=S[I];
  End;
  If S[Ord(S[0])]in['X','x']Then M:=10
                            Else M:=Ord(S[Len])-48;
  S[0]:=Chr(Len);
  CheckSum:=0;
  For I:=1 to Len-1 do Inc(CheckSum,(Ord(S[I])-48)*I);
  If((CheckSum mod 11)=M)Then WriteLn('Valide')
                         Else WriteLn('Invalide!');
 End;
END.
