{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program CSV2XLS(Input,Output);

{$A-}
{$R-}

Uses DOS;

Var
 SourceCSV:Text;
 TargetXLS:File;
 CurrLine,CurrCell,FileName,TFileName:String;
 CurrColumn,CurrRow:Integer;

Function Path2Ext(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2Ext:=E;
End;

Procedure PutByte(B:Byte);
Begin
 BlockWrite(TargetXLS,B,1);
End;

Procedure PutWord(W:Integer);
Begin
 PutByte(Byte(W and $FF));
 PutByte(Byte((W shr 8)and $FF));
End;

Procedure PutString(S:String);
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do PutByte(Ord(S[I]));
End;

Function IBM437ToWin1252(B:Byte):Byte;
Begin
 Case B of
  $80:IBM437ToWin1252:=$C7; { C cedille }
  $81:IBM437ToWin1252:=$FC; { u trema }
  $82:IBM437ToWin1252:=$E9; { e aigu }
  $83:IBM437ToWin1252:=$E2; { a circonflexe }
  $84:IBM437ToWin1252:=$E4; { a trema }
  $85:IBM437ToWin1252:=$E0; { a grave }
  $86:IBM437ToWin1252:=$E5; { a rond }
  $87:IBM437ToWin1252:=$E7; { c cedille }
  $88:IBM437ToWin1252:=$EA; { e circonflexe }
  $89:IBM437ToWin1252:=$EB; { e trema }
  $8A:IBM437ToWin1252:=$E8; { e grave }
  $8B:IBM437ToWin1252:=$EF; { i trema }
  $8C:IBM437ToWin1252:=$EE; { i circonflexe }
  $8D:IBM437ToWin1252:=$EC; { i grave }
  $8E:IBM437ToWin1252:=$C4; { A trema }
  $8F:IBM437ToWin1252:=$C5; { A rond }
  $90:IBM437ToWin1252:=$C9; { E aigu }
  $91:IBM437ToWin1252:=$E6; { ae }
  $92:IBM437ToWin1252:=$C6; { AE }
  $93:IBM437ToWin1252:=$F4; { o circonflexe }
  $94:IBM437ToWin1252:=$F6; { o trema }
  $95:IBM437ToWin1252:=$F2; { o grave }
  $96:IBM437ToWin1252:=$FB; { u circonflexe }
  $97:IBM437ToWin1252:=$F9; { u grave }
  $98:IBM437ToWin1252:=$FF; { y trema }
  $99:IBM437ToWin1252:=$D6; { O trema }
  $9A:IBM437ToWin1252:=$DC; { U trema }
  $9B:IBM437ToWin1252:=$A2; { cent }
  $9C:IBM437ToWin1252:=$A3; { livre }
  $9D:IBM437ToWin1252:=$A5; { yen }
  $9F:IBM437ToWin1252:=$83; { florin }
  $A0:IBM437ToWin1252:=$E1; { a aigu }
  $A1:IBM437ToWin1252:=$ED; { i aigu }
  $A2:IBM437ToWin1252:=$F3; { o aigu }
  $A3:IBM437ToWin1252:=$FA; { u aigu }
  $A4:IBM437ToWin1252:=$F1; { n tilde }
  $A5:IBM437ToWin1252:=$D1; { N tilde }
  $A6:IBM437ToWin1252:=$AA;
  $A7:IBM437ToWin1252:=$BA;
  $A8:IBM437ToWin1252:=$BF;
  $AA:IBM437ToWin1252:=$AC;
  $AB:IBM437ToWin1252:=$BD;
  $AC:IBM437ToWin1252:=$BC;
  $AD:IBM437ToWin1252:=$A1;
  $AE:IBM437ToWin1252:=$AB;
  $AF:IBM437ToWin1252:=$BB;
  $E1:IBM437ToWin1252:=$DF; { eszett }
  $E6:IBM437ToWin1252:=$B5; { micro }
  $E8:IBM437ToWin1252:=$DE; { Thorn }
  $E9:IBM437ToWin1252:=$DA; { U aigu }
  $EA:IBM437ToWin1252:=$DB; { U circonflexe }
  $EB:IBM437ToWin1252:=$D9; { U grave }
  $EC:IBM437ToWin1252:=$FD; { y aigu }
  $ED:IBM437ToWin1252:=$DD; { Y aigu }
  $F1:IBM437ToWin1252:=$B1;
  $F3:IBM437ToWin1252:=$BE;
  $F6:IBM437ToWin1252:=$F7;
  $F8:IBM437ToWin1252:=$B0;
  $F9:IBM437ToWin1252:=$A8;
  $FA:IBM437ToWin1252:=$B7;
  $FB:IBM437ToWin1252:=$B9;
  $FC:IBM437ToWin1252:=$B3;
  $FD:IBM437ToWin1252:=$B2;
  $FF:IBM437ToWin1252:=$A0;
 Else
  If B<128Then IBM437ToWin1252:=B
          Else IBM437ToWin1252:=Ord('?');
 End;
End;

Procedure PutIBM437StringAsWin1252(S:String);
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do PutByte(IBM437ToWin1252(Ord(S[I])));
End;

Procedure WriteRecordHeader(RecordType,RecordLen:Integer);
Begin
 PutWord(RecordType);
 PutWord(RecordLen);
End;

Procedure WriteBOF;
Begin
 { BIFF2: Begin Of File, type worksheet. }
 WriteRecordHeader($0009,4);
 PutWord($0002);
 PutWord($0010);
End;

Procedure WriteCodePage;
Begin
 { Excel Windows reads old BIFF text most reliably as Windows-1252. }
 WriteRecordHeader($0042,2);
 PutWord(1252);
End;

Procedure WriteEOF;
Begin
 WriteRecordHeader($000A,0);
End;

Procedure AddLabel(C,R:Integer;S:String);
Var
 L:Integer;
Begin
 If R>16383Then Exit;
 If C>255Then Exit;
 L:=Length(S);
 { BIFF2 LABEL: row, column, 3 cell attribute bytes, string length, string bytes. }
 WriteRecordHeader($0004,8+L);
 PutWord(R);
 PutWord(C);
 PutByte(0);
 PutByte(0);
 PutByte(0);
 PutByte(L);
 PutIBM437StringAsWin1252(S);
End;

Procedure AddCSVCell;
Begin
 If(Length(CurrCell)>=2)and(CurrCell[1]='"')and
   (CurrCell[Length(CurrCell)]='"')Then
  CurrCell:=Copy(CurrCell,2,Length(CurrCell)-2);
 AddLabel(CurrColumn,CurrRow,CurrCell);
 Inc(CurrColumn);
 CurrCell:='';
End;

Procedure ConvertCSV;
Var
 I:Integer;
 InQuotes:Boolean;
Begin
 CurrRow:=0;
 While Not EOF(SourceCSV)do Begin
  ReadLn(SourceCSV,CurrLine);
  CurrColumn:=0;
  CurrCell:='';
  InQuotes:=False;
  I:=1;
  While I<=Length(CurrLine)do Begin
   If CurrLine[I]='"'Then Begin
    If InQuotes and(I<Length(CurrLine))and(CurrLine[I+1]='"')Then Begin
     CurrCell:=CurrCell+'"';
     Inc(I);
    End
     Else
    Begin
     InQuotes:=Not InQuotes;
     CurrCell:=CurrCell+'"';
    End;
   End
    Else If(CurrLine[I]=',')and(Not InQuotes)Then
   Begin
    AddCSVCell;
   End
    Else
   CurrCell:=CurrCell+CurrLine[I];
   Inc(I);
  End;
  AddCSVCell;
  Inc(CurrRow);
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CSV2XLS : Cette commande permet de convertir un fichier CSV en XLS de Microsoft Excel.');
  WriteLn;
  WriteLn('Syntaxe : CSV2XLS source.CSV target.XLS');
  WriteLn;
  WriteLn(' fichier.CSV  Nom du fichier a convertir');
  WriteLn(' fichier.XLS  Nom du fichier du resultat');
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
    Close(SourceCSV);
    Halt;
   End
    Else
   Begin
    TFileName:=FExpand(ParamStr(2));
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.XLS';
    Assign(TargetXLS,TFileName);
    {$I-}Rewrite(TargetXLS,1);{$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de creer le fichier XLS ',TFileName,' !');
     Close(SourceCSV);
     Halt;
    End;
    WriteBOF;
    WriteCodePage;
    ConvertCSV;
    WriteEOF;
    Close(TargetXLS);
    Close(SourceCSV);
   End;
  End
   Else
  WriteLn('Parametre requis !');
 End;
END.
