{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CP2GAT;

Uses DOS;

Const
   {Constante du Traitement de texte}
 cgNormal=0;                   { Caractäre normal }
 cgBold=1;                     { Caractäre gras }
 cgUnderLine=2;                { Caractäre soulignÇ }
 cgItalic=4;                   { Caractäre italique }
 cgInverse=8;                  { Caractäre inversÇ en couleur de fond et d'Çcriture }
 cgExposant=cgInverse+cgBold;  { Caractäre en expososant }
 cgDouble=16;                  { Caractäre en largeur double }

Var
 HS,HT:Text;
 S,T:String;
 I,SP:Byte;
 ModeBold,ModeUnderline:Boolean;

Function Path2NoExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NoExt:=D+N;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CP2GAT : Cette commande permet de convertir un fichier ',
                    'texte Central-Point ou Norton en format GAT ',
                    'du MonsterBook.');
  WriteLn;
  WriteLn('Syntaxe : CP2GAT nomdufichier.txt');
  WriteLn;
  WriteLn(' nomdufichier.txt  Nom du fichier recevant le contenu.');
  WriteLn;
 End
  Else
 Begin
  {$I-}Assign(HS,ParamStr(1));
  Reset(HS);{$I+}
  If(IoResult<>0)Then Begin
   WriteLn('Impossible d''ouvrir le fichier source');
   Halt(1)
  End;
  {$I-}Assign(HT,Path2NoExt(ParamStr(1))+'.GAT');
  Rewrite(HT);{$I+}
  If(IoResult<>0)Then Begin
   WriteLn('Impossible de crÇer le fichier GAT');
   Halt(2)
  End;
  WriteLn(HT,': 10 6 90 60 L 0');
  ModeBold:=False;
  ModeUnderline:=False;
  While Not EOF(HS)do Begin
   FillChar(S,SizeOf(S),#0);
   ReadLn(HS,S);
   T:='';
   Sp:=0;
   If S<>''Then Begin
    T:='          ';
    I:=1;
    While(I<=Length(S))do Begin
     If(S[I]='^')and(S[I+1]='B')Then Begin
      ModeBold:=Not(ModeBold);
      Inc(I);
     End
      Else
     If(S[I]='^')and(S[I+1]='U')Then Begin
      ModeUnderline:=Not(ModeUnderline);
      Inc(I);
     End
      Else
     Begin
      If(ModeBold)and(ModeUnderline)Then T:=T+Chr(cgBold+cgUnderline)Else
      If(ModeBold)Then T:=T+Chr(cgBold)Else
      If(ModeUnderline)Then T:=T+Chr(cgUnderline);
      T:=T+S[I];
      If S[I]=' 'Then Inc(Sp);
     End;
     Inc(I);
    End;
    If(Length(S)>60)and(Sp>0)and(T[Length(T)]<>' ')Then Begin
     FillChar(S,SizeOf(S),#0);
     ReadLn(HS,S);
     If S<>''Then T:=T+' ';
    End;
   End;
   WriteLn(HT,T);
  End;
  Close(HT);
  Close(HS);
 End;
END.