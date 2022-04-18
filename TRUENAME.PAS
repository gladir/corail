{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program TRUENAME;

Uses DOS;

Var
 P:Byte;
 CurrParam:String;
 CurrDirectory:String;

BEGIN
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ParamStr(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    GetDir(0,CurrDirectory);
    WriteLn(CurrDirectory);
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   WriteLn('TRUENAME   Cette commande permet d''afficher le nom complet d''un unite, repertoire ou d''un nom de fichier');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('TRUENAME [/?] [chemin]');
   WriteLn;
   WriteLn(' /?     Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('chemin  Ce parametre permet d''indiquer le nom du chemin a analyser');
   Exit;
  End;
  WriteLn(FExpand(CurrParam));
  If P>9Then Break;
 Until CurrParam='';
END.