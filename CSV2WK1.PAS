{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program CSV2WK1(Input,Output);

{$A-}

Uses DOS,Strings;

Type
  {Entete d'un fichier Lotus 1-2-3 }
 HeaderLotus123=Record
  TypeCode:Integer;      { Code d'identification = 0 }
  Length:Integer;        { Longueur des donn'es  = 2 }
  Value:Integer;         { Valeur                = 1030 }
 End;

  {Texte d'un fichier Lotus 1-2-3}
 LabelLotus123=Record
  TypeCode:Integer;          { Code d'identification = 15 }
  Length:Integer;            { Longueur des donn'es }
  Format:Byte;               { Format }
  Column:Integer;            { Colonne }
  Row:Integer;               { Ligne }
  Text:Array[1..257]of Char; { Texte }
 End;

  {Entier d'un fichier Lotus 1-2-3 }
 IntegerLotus123=Record
  TypeCode:Integer;          { Code d'identification = 13 }
  Length:Integer;            { Longueur des donnees }
  Format:Byte;               { Format }
  Column:Integer;            { Colonne }
  Row:Integer;               { Ligne }
  Value:Integer;             { Valeur }
 End;

  {Entier d'un fichier Lotus 1-2-3 }
 DoubleLotus123=Record
  TypeCode:Integer;          { Code d'identification = 13 }
  Length:Integer;            { Longueur des donnees }
  Format:Byte;               { Format }
  Column:Integer;            { Colonne }
  Row:Integer;               { Ligne }
  Value:Double;              { Valeur }
 End;

  {Fin d'un fichier Lotus 1-2-3 }
 EndLotus123=Record
  TypeCode:Integer;      { Code d'identification = 1 }
  Length:Integer;        { Longueur des donnees  = 0 }
 End;

Var
 SourceCSV:Text;
 TargetWK1:File;
 CurrLine,CurrWord,FileName,TFileName:String;
 CurrColumn,CurrRow:Integer;
 I:Integer;
 LDouble:DoubleLotus123;

Function Path2Name(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2Name:=N;
End;

Function Path2Ext(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2Ext:=E;
End;

Procedure AddHeader;
Var
 LHeader:HeaderLotus123;
Begin
 LHeader.TypeCode:=0;
 LHeader.Length:=2;
 LHeader.Value:=1030;
 BlockWrite(TargetWK1,LHeader,SizeOf(LHeader));
End;

Procedure AddLabel(CurrColumn,CurrRow:Integer;CurrWord:String);
Var
 LLabel:LabelLotus123;
 I:Integer;
Begin
 FillChar(LLabel,SizeOf(LLabel),0);
 LLabel.TypeCode:=$0F;
 LLabel.Length:=Length(CurrWord)+7;
 LLabel.Format:=$FF;
 LLabel.Column:=CurrColumn;
 LLabel.Row:=CurrRow;
 LLabel.Text[1]:='''';
 For I:=1 to Length(CurrWord) do LLabel.Text[i+1]:=CurrWord[I];
 BlockWrite(TargetWK1,LLabel,Length(CurrWord)+11);
End;

Procedure AddEnd;
Var
 LEnd:EndLotus123;
Begin
 LEnd.TypeCode:=1;
 LEnd.Length:=0;
 BlockWrite(TargetWK1,LEnd,SizeOf(LEnd));
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CSV2WK1 : Cette commande permet de convertir un fichier CSV en WK1 de Lotus.');
  WriteLn;
  WriteLn('Syntaxe : CSV2WK1 source.CSV target.WK1');
  WriteLn;
  WriteLn(' fichier.CSV  Nom du fichier a convertir');
  WriteLn(' fichier.WK1  Nom du fichier du resultat');
  WriteLn;
 End
  Else
 Begin
  If ParamCount>0Then Begin
   FileName:=FExpand(ParamStr(1));
   If Path2Ext(FileName)=''Then FileName:=FileName+'.CSV';
   Assign(SourceCSV,FileName);
   {$I-}Reset(SourceCSV);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Fichier CSV introuvable !');
    Halt;
   End;
   If ParamStr(2)=''Then Begin
    WriteLn('Destination attendue !');
    Halt;
   End
    Else
   Begin
    CurrRow:=0;
    TFileName:=FExpand(ParamStr(2));
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.WK1';
    Assign(TargetWK1,TFileName);
    {$I-}Rewrite(TargetWK1,1); {$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de cr‚er le fichier WK1 ',TFileName,' !');
     Close(SourceCSV);
     Halt;
    End;
    AddHeader;
    While Not EOF(SourceCSV)do Begin
     ReadLn(SourceCSV,CurrLine);
     CurrColumn:=0;
     CurrWord:='';
     For I:=1 to Length(CurrLine)do Begin
      If CurrLine[I]=','Then Begin
       If(CurrWord[1]='"')and(CurrWord[Length(CurrWord)]='"')Then Begin
        AddLabel(CurrColumn,CurrRow,Copy(CurrWord,2,Length(CurrWord)-2));
        Inc(CurrColumn);
       End
        Else
       Begin
        AddLabel(CurrColumn,CurrRow,CurrWord);
        Inc(CurrColumn);
       End;
       CurrWord:='';
      End
       Else
      CurrWord:=CurrWord+CurrLine[I];
     End;
     AddLabel(CurrColumn,CurrRow,CurrWord);
     Inc(CurrColumn);
     Inc(CurrRow);
    End;
    AddEnd;
    Close(TargetWK1);
    Close(SourceCSV);
   End;
  End
   Else
  WriteLn('ParamŠtre requis !');
 End;
END.
