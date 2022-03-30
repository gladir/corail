{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program BUILD;

Var
 TextFile:Text;
 FirstParam,CurrLine:String;

BEGIN
 FirstParam:=ParamStr(1);
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('BUILD   Cette commande permet de construire un fichier texte.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('BUILD [/?] nomdufichier');
  WriteLn;
  WriteLn('  /?           Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' nomdufichier  Ce parametre permet d''indiquer le nom du fichier a construire.');
 End
  Else
 If Length(FirstParam)>0Then Begin
  Assign(TextFile,FirstParam);
  Rewrite(TextFile);
  Repeat
   Write('? ');
   ReadLn(CurrLine);
   WriteLn(TextFile,CurrLine);
  Until CurrLine='';
  Close(TextFile);
 End
  Else
 WriteLn('Nom de fichier requis');
END.