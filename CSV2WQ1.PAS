{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program CSV2WQ1(Input,Output);

{$A-}
{$R-}

Uses DOS;

Var
 SourceCSV:Text;
 TargetWQ1:File;
 CurrLine,CurrCell,FileName,TFileName:String;
 CurrColumn,CurrRow:Integer;
 MaxColumn,MaxRow:Integer;
 SheetSizeOffset:LongInt;

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
 BlockWrite(TargetWQ1,B,1);
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

Procedure WriteRecordHeader(RecordType,RecordLen:Integer);
Begin
 PutWord(RecordType);
 PutWord(RecordLen);
End;

Procedure WriteHeader;
Begin
 { WQ1 Quattro Pro for DOS version marker. }
 WriteRecordHeader(0,2);
 PutWord($5120);
End;

Procedure WriteSheetSizePlaceholder;
Begin
 SheetSizeOffset:=FilePos(TargetWQ1);
 WriteRecordHeader($0006,8);
 PutWord(0);
 PutWord(0);
 PutWord(0);
 PutWord(0);
End;

Procedure PatchSheetSize;
Var
 EndOffset:LongInt;
Begin
 EndOffset:=FilePos(TargetWQ1);
 Seek(TargetWQ1,SheetSizeOffset+4);
 PutWord(0);
 PutWord(0);
 If MaxColumn<0Then PutWord(0)
               Else PutWord(MaxColumn);
 If MaxRow<0Then PutWord(-1)
            Else PutWord(MaxRow+1);
 Seek(TargetWQ1,EndOffset);
End;

Procedure WriteEOF;
Begin
 WriteRecordHeader(1,0);
End;

Procedure AddLabel(C,R:Integer;S:String);
Var
 L:Integer;
Begin
 If R>8191Then Exit;
 If C>255Then Exit;
 L:=Length(S);
 { WQ1 label cell: format, col, sheet, row, align, Pascal string. }
 WriteRecordHeader($000F,L+7);
 PutByte($FF);
 PutByte(C);
 PutByte(0);
 PutWord(R);
 PutByte(Ord(''''));
 PutByte(L);
 PutString(S);
 If C>MaxColumn Then MaxColumn:=C;
 If R>MaxRow Then MaxRow:=R;
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
  WriteLn('CSV2WQ1 : Cette commande permet de convertir un fichier CSV en WQ1 de Quattro Pro.');
  WriteLn;
  WriteLn('Syntaxe : CSV2WQ1 source.CSV target.WQ1');
  WriteLn;
  WriteLn(' fichier.CSV  Nom du fichier a convertir');
  WriteLn(' fichier.WQ1  Nom du fichier du resultat');
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
    If Path2Ext(TFileName)=''Then TFileName:=TFileName+'.WQ1';
    Assign(TargetWQ1,TFileName);
    {$I-}Rewrite(TargetWQ1,1);{$I+}
    If IoResult<>0Then Begin
     WriteLn('Impossible de creer le fichier WQ1 ',TFileName,' !');
     Close(SourceCSV);
     Halt;
    End;
    MaxColumn:=-1;
    MaxRow:=-1;
    WriteHeader;
    WriteSheetSizePlaceholder;
    ConvertCSV;
    PatchSheetSize;
    WriteEOF;
    Close(TargetWQ1);
    Close(SourceCSV);
   End;
  End
   Else
  WriteLn('Parametre requis !');
 End;
END.
