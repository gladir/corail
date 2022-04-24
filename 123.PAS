{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program _123;

{$IFNDEF FPC}
 {$A-,B-,F+,I-,R-,S-,X+,V-,W-}
{$ENDIF}


Uses Strings,Crt,DOS;

Const
  {Format de la cellule du tableau}
 cfEmpty=0;      { Cellule vide }
 cfValue=1;      { Valeur num'rique }
 cfText=2;       { Valeur texte }
 cfFormula=3;    { Formule }
 cfDate=4;       { Date }
 cfColumn=5;     { Colonne (usage de lecture et sauvegarde seulement) }

 Letters:Set of Char=['A'..'Z', 'a'..'z'];
 Numbers:Set of Char=['0'..'9'];

 MaxLStringLength=65521;

 LeftInputArrow=#17;
 RightInputArrow=#16;

 MaxBuckets=1000;
 MaxHashItemSize=256;

 DollarString=' $ ';
 RepeatFirstChar='\';
 TextFirstChar=' ';
 JustShift=4;
 JustPart=$03;
 DollarPart=$40;
 CommasPart=$80;

 DefMaxCols=65535;
 DefMaxRows=65535;
 DefMaxDecimalPlaces=8;
 DefDecimalPlaces=4;
 DefColWidth=10;
 EmptyRowsAtTop=1;
 EmptyRowsAtBottom=2;
 MinColWidth=3;

 FreeListItems=1000;
 ParserStackSize=10;
 MaxFuncNameLen=5;
 ExpLimit=11356;
 SqrLimit=1E2466;
 MaxExpLen=4;

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
  Text:Array[0..239]of Char; { Texte }
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


 BucketRange=1..MaxBuckets;
 HashItemSizeRange=1..MaxHashItemSize;

 HashItemData=Array[0..Pred(MaxHashItemSize)]of Byte;
 HashItemDataPtr=^HashItemData;
 HashItemPtr=^HashItem;
 HashItem=Record
  Next:HashItemPtr;
  Data:HashItemData;
 End;
 HashItemArray=Array[BucketRange]of HashItemPtr;

 HashTable=Record
  DefaultItemSize:Word;
  Buckets:BucketRange;
  Items:LongInt;
  CurrItem:HashItemPtr;
  CurrBucket:BucketRange;
  HashData:^HashItemArray;
   { Donnees externe }
  Context:Pointer; { Contexte des routines virtuels }
  CreateItem:Procedure(Var Context;Var Item:HashItemPtr);
  CurrItemSize:Function(Var Context;Item:HashItemPtr):Word;
  Found:Function(Var Context;Item:HashItemPtr):Boolean;
  HashValue:Function(Var Context):Word;
  ItemSize:Function(Var Context):Word;
 End;

  {Structure du tableur}
 CelluleValue=Record
  Value:Real;          { Valeur de la cellule }
  Dec:Byte;            { Nombre de d'cimal }
 End;

 CelluleText=Record
  Text:String;        { ChaOne de caractere de la cellule }
 End;

 CelluleFormula=Record
  Value:Real;      { Valeur actuel de la formule }
  Compute:Boolean; { Formule calculer? }
  Error:Boolean;   { Erreur de la valeur }
  Cellule:Boolean; { Y a-t-il au moins une cellule dans la formule? }
  Dec:Byte;        { Nombre de d'cimal }
  Formula:String;  { Formule proprement dite }
 End;

 CelluleHeader=Record
  Format:Byte;
  Justify:(cLeft,cCenter,cRight);
  Attribut:Byte;         { Couleur d'attribut (comme celui de l''cran de texte)}
  GAttr:Byte;            { Attribut Gras=1, Souligner=2,...}
 End;

  { Definition d'une colonne }
 ColumnHeader=Record
  Length:Integer;        { Largeur de la colonne }
  Attribut:Byte;
 End;

 CelluleRec=Record
  Column,Row:{LongInt}Word;
  Header:CelluleHeader;
  Data:Record Case Byte of
  {cfEmpty:();}
   cfValue:(v:CelluleValue);
   cfText:(t:CelluleText);
   cfFormula:(f:CelluleFormula);
   cfColumn:(c:ColumnHeader);
  End;
 End;

 PCellule=^CelluleRec;

 ColumnRec=Record
  Column:LongInt;
  Header:CelluleHeader;
  c:ColumnHeader;
 End;

 PColumn=^ColumnRec;

 ColumnObject=Record
  List:HashTable;
  Curr:ColumnRec;
 End;

 CelluleObject=Record
  List:HashTable;
  Curr:CelluleRec;
  X1,Y1,X2,Y2:LongInt;
 End;

Type
 LStringRange=0..MaxLStringLength;
 LStringData=Array[1..MaxLStringLength]of Char;
 LStringDataPtr=^LStringData;
 LStringPtr=^LString;
 LString=Record
  Len:LStringRange;
  MaxLen:LStringRange;
  Data:LStringDataPtr;
 End;

 STypeListPtr=^STypeList;
 STypeList=Array[1..256]of Word;
 SProcListPtr=^SProcList;
 SProc=Object StoreProc,LoadProc:Pointer; End;
 SProcList=Array[1..256]of SProc;

 CellPos=Record
  Col,Row:Word;
 End;
 Justification=(JLeft,JCenter,JRight);
 DollarStr=String[Length(DollarString)];

 TokenRec=Record
  State:Byte;
  Case Byte of
   0:(Value:Extended);
   1:(CP:CellPos);
   2:(FuncName:String[MaxFuncNameLen]);
 End;

Procedure CECreateItem(Var Context;Var Item:HashItemPtr);Forward;
Function  CECurrItemSize(Var Context;Item:HashItemPtr):Word;Forward;
Function  CEDelete(Var Q:CelluleObject;Column,Row:LongInt):Boolean;Forward;
Function  CEFound(Var Context;Item:HashItemPtr):Boolean;Forward;
Function  CEHashValue(Var Context):Word;Forward;
Function  CEItemSize(Var Context):Word;Forward;
Procedure HTCreateItem(Var Context;Var Item:HashItemPtr);Forward;
Function  HTCurrItemSize(Var Context;Item:HashItemPtr):Word;Forward;
Function  HTFound(Var Context;Item:HashItemPtr):Boolean;Forward;
Function  HTHashValue(Var Context):Word;Forward;
Function  HTItemSize(Var Context):Word;Forward;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function StrPascalCopy(Var Dest;Size:Word;Source:String):PChar;Begin
 If Size<SizeOf(String)Then Source[0]:=Char(Size-1);
 StrPascalCopy:=StrPCopy(PChar(@Dest),Source);
End;

Function GetCurrentDir:String;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 GetCurrentDir:=CurrentDir;
End;

Function HTInit(Var Q:HashTable;InitBuckets:BucketRange):Boolean;Begin
 HTInit:=False;
 FillChar(Q,SizeOf(Q),0);
 {$IFDEF FPC}
  Q.CreateItem:=@HTCreateItem;
  Q.CurrItemSize:=@HTCurrItemSize;
  Q.Found:=@HTFound;
  Q.ItemSize:=@HTItemSize;
  Q.HashValue:=@HTHashValue;
 {$ELSE}
  Q.CreateItem:=HTCreateItem;
  Q.CurrItemSize:=HTCurrItemSize;
  Q.Found:=HTFound;
  Q.ItemSize:=HTItemSize;
  Q.HashValue:=HTHashValue;
 {$ENDIF}
 GetMem(Q.HashData,InitBuckets*SizeOf(HashItemPtr));
 If(Q.HashData=NIL)Then Exit;
 Q.Buckets:=InitBuckets;
 FillChar(Q.HashData^,Q.Buckets*SizeOf(HashItemPtr),0);
 HTInit:=True;
End;

Procedure HTDone(Var Q:HashTable);
Var
 P,D:HashItemPtr;
 I:Word;
Begin
 For I:=1to(Q.Buckets)do Begin
  P:=Q.HashData^[I];
  While(P<>NIL)do Begin
   D:=P;
   P:=P^.Next;
   FreeMem(D,Q.CurrItemSize(Q,D)+SizeOf(HashItemPtr));
  End;
 End;
 FreeMem(Q.HashData,Q.Buckets*SizeOf(HashItemPtr));
End;

Function HTAdd(Var Q:HashTable):Boolean;
Var
 H,A:HashItemPtr;
 V:BucketRange;
Begin
 HTAdd:=False;
 V:=Succ(Q.HashValue(Q{Q.Context})mod Q.Buckets);
 H:=Q.HashData^[V];A:=H;
 While(H<>NIL)do Begin
  H:=H^.Next;
  If(H<>NIL)Then A:=H;
 End;
 If(A=NIL)Then Begin
  GetMem(Q.HashData^[V],Q.ItemSize(Q{Q.Context})+SizeOf(HashItemPtr));
  A:=Q.HashData^[V];
  If(A=NIL)Then Exit;
 End
  else
 Begin
  GetMem(A^.Next,Q.ItemSize(Q{Q.Context})+SizeOf(HashItemPtr));
  If(A^.Next=NIL)Then Exit;
  A:=A^.Next;
 End;
 Q.CreateItem(Q{Q.Context},A);
 A^.Next:=NIL;
 Inc(Q.Items);
 HTAdd:=True;
End;

Function HTDelete(Var Q:HashTable;Deleted:Pointer):Boolean;
Var
 H,D:HashItemPtr;
 V:BucketRange;
Begin
 V:=Succ(Q.HashValue(Q{Q.Context^})mod Q.Buckets);
 H:=Q.HashData^[V];D:=H;
 While(H<>NIL)and(Not(Q.Found(Q{Q.Context^},H)))do Begin
  H:=H^.Next;
  If Not(Q.Found(Q{Q.Context^},H))Then D:=H;
 End;
 If(H=NIL)Then Begin
  If(Deleted<>NIL)Then FillChar(Deleted^,Q.ItemSize(Q{Q.Context^}),0);
  HTDelete:=False;
  Exit;
 End
  Else
 Begin
  If(H=Q.HashData^[V])Then Q.HashData^[V]:=Q.HashData^[V]^.Next
                      Else D^.Next:=H^.Next;
  If(Deleted<>NIL)Then Move(H^.Data,Deleted^,Q.ItemSize(Q{Q.Context^}));
  FreeMem(H,Q.CurrItemSize(Q{Q.Context^},H)+SizeOf(HashItemPtr));
 End;
 Dec(Q.Items);
 HTDelete:=True;
End;

Function HTFirstItem(Var Q:HashTable):HashItemPtr;
Var
 I:Word;
Begin
 For I:=1to(Q.Buckets)do Begin
  Q.CurrBucket:=I;
  Q.CurrItem:=Q.HashData^[I];
  If(Q.CurrItem<>NIL)Then Begin
   HTFirstItem:=Q.CurrItem;
   Exit;
  End;
 End;
 HTFirstItem:=NIL;
End;

Function HTNextItem(Var Q:HashTable):HashItemPtr;Begin
 Q.CurrItem:=Q.CurrItem^.Next;
 If(Q.CurrItem<>NIL)Then Begin
  HTNextItem:=Q.CurrItem;
  Exit;
 End;
 While(Q.CurrBucket<Q.Buckets)do Begin
  Inc(Q.CurrBucket);
  Q.CurrItem:=Q.HashData^[Q.CurrBucket];
  If(Q.CurrItem<>NIL)Then Begin
   HTNextItem:=Q.CurrItem;
   Exit;
  End;
 End;
 HTNextItem:=NIL;
End;

Function HTChange(Var Q:HashTable):Boolean;
Var
 H:HashItemPtr;
Begin
 H:=Q.HashData^[Succ(Q.HashValue(Q{Q.Context^}) mod Q.Buckets)];
 While(H<>NIL)and(Not(Q.Found(Q{Q.Context^},H)))do H:=H^.Next;
 If(H<>NIL)Then Begin;
  Q.CreateItem(Q{Q.Context^},H);
  HTChange:=True;
 End
  Else
 HTChange:=HTAdd(Q);
End;

Function HTSearch(Var Q:HashTable):HashItemPtr;
Var
 H:HashItemPtr;
Begin
 H:=Q.HashData^[Succ(Q.HashValue(Q{Q.Context^})mod Q.Buckets)];
 While(H<>NIL)and(Not(Q.Found(Q{Q.Context^},H)))do H:=H^.Next;
 HTSearch:=H;
End;

Function HTHashValue(Var Context):Word;Begin
 HTHashValue:=1;
End;

Function HTFound(Var Context;Item:HashItemPtr):Boolean;Begin
 HTFound:=False;
End;

Procedure HTCreateItem(Var Context;Var Item:HashItemPtr);Begin
End;

Function HTItemSize(Var Context):Word;
Var
 Q:HashTable Absolute Context;
Begin
 HTItemSize:=Q.DefaultItemSize;
End;

Function HTCurrItemSize(Var Context;Item:HashItemPtr):Word;
Var
 Q:HashTable Absolute Context;
Begin
 HTCurrItemSize:=Q.ItemSize(Q{Q.Context^});
End;

Function COHashValue(Var Context):Word;
Var
 Q:ColumnObject Absolute Context;
Begin
 COHashValue:=Q.Curr.Column;
End;

Function COFound(Var Context;Item:HashItemPtr):Boolean;
Type
 ColumnHashItem=Record
  Next:HashItemPtr;
  Data:ColumnRec;
 End;
Var
 Q:ColumnObject Absolute Context;
 C:^ColumnHashItem Absolute Item;
Begin
 COFound:=Q.Curr.Column=C^.Data.Column;
End;


Procedure COCreateItem(Var Context;Var Item:HashItemPtr);
Var
 Q:ColumnObject Absolute Context;
Begin
 Move(Q.Curr,Item^.Data,SizeOf(ColumnRec));
End;

Function COItemSize(Var Context):Word;Begin
 COItemSize:=SizeOf(ColumnRec)
End;

Procedure COInit(Var Q:ColumnObject);Begin
 FillChar(Q,SizeOf(Q),0);
 Q.List.Context:=@Q;
 HTInit(Q.List,64);
 {$IFDEF FPC}
  Q.List.CreateItem:=@COCreateItem;
  Q.List.Found:=@COFound;
  Q.List.HashValue:=@COHashValue;
  Q.List.ItemSize:=@COItemSize;
 {$ELSE}
  Q.List.CreateItem:=COCreateItem;
  Q.List.Found:=COFound;
  Q.List.HashValue:=COHashValue;
  Q.List.ItemSize:=COItemSize;
 {$ENDIF}
End;

Function COAdd(Var Q:ColumnObject):Boolean;Begin
 COAdd:=HTAdd(Q.List);
End;

Procedure CODelete(Var Q:ColumnObject;Column:LongInt);Begin
 Q.Curr.Column:=Column;
 HTDelete(Q.List,NIL);
End;

Function COGetColumn(Var Q:ColumnObject;Column:LongInt):PColumn;
Var
 I:HashItemPtr;
 W:Byte;
Begin
 Q.Curr.Column:=Column;
 I:=HTSearch(Q.List);
 If(I=NIL)Then COGetColumn:=NIL
          Else COGetColumn:=@I^.Data;
End;

Function COGetColumnWidth(Var Q:ColumnObject;Column:LongInt):Word;
Var
 PC:PColumn;
Begin
 PC:=COGetColumn(Q,Column);
 If(PC=NIL)Then COGetColumnWidth:=10
           Else COGetColumnWidth:=PC^.c.Length;
End;

Function COSearch(Var Q:ColumnObject;Column:LongInt):Boolean;
Var
 I:HashItemPtr;
 W:Byte;
Begin
 Q.Curr.Column:=Column;
 I:=HTSearch(Q.List);
 If(I=NIL)Then Begin
  COSearch:=False;
  FillChar(Q.Curr,SizeOf(ColumnRec),0);
  Q.Curr.c.Length:=10;
  Q.Curr.Column:=Column;
 End
  Else
 Begin
  Move(I^.Data,Q.Curr,SizeOf(ColumnRec));
  COSearch:=True;
 End;
End;

Function COUpdate(Var Q:ColumnObject):Boolean;
Var
 I:HashItemPtr;
 W:Byte;
Begin
 I:=HTSearch(Q.List);
 If(I=NIL)Then COUpdate:=False
  Else
 Begin
  Move(Q.Curr,I^.Data,SizeOf(ColumnRec));
  COUpdate:=True;
 End;
End;

Function COFirstItem(Var Q:ColumnObject):PColumn;
Var
 I:HashItemPtr;
Begin
 I:=HTFirstItem(Q.List);
 If(I=NIL)Then COFirstItem:=NIL
          Else COFirstItem:=@I^.Data;
End;

Function CONextItem(Var Q:CelluleObject):PColumn;
Var
 I:HashItemPtr;
Begin
 I:=HTNextItem(Q.List);
 If(I=NIL)Then CONextItem:=NIL
          Else CONextItem:=@I^.Data;
End;

Procedure CODone(Var Q:ColumnObject);Begin
 HTDone(Q.List);
End;

Procedure COInsertColumn(Var Q:ColumnObject;Column:LongInt);
Var
 New:ColumnObject;
 P:PColumn;
Begin
 COInit(New);
 P:=COFirstItem(Q);
 While(P<>NIL)do Begin
  New.Curr:=P^;
  If(New.Curr.Column>=Column)Then Inc(New.Curr.Column);
  COAdd(New);
  CODelete(Q,P^.Column);
  P:=COFirstItem(Q);
 End;
 CODone(Q);
 Q:=New;
End;

Procedure CODeleteColumn(Var Q:ColumnObject;Column:LongInt);
Var
 New:ColumnObject;
 P:PColumn;
Begin
 COInit(New);
 P:=COFirstItem(Q);
 While(P<>NIL)do Begin
  New.Curr:=P^;
  If(New.Curr.Column>=Column)Then Dec(New.Curr.Column);
  If(P^.Column<>Column)Then COAdd(New);
  CODelete(Q,P^.Column);
  P:=COFirstItem(Q);
 End;
 CODone(Q);
 Q:=New;
End;

Function CEInit(Var Q:CelluleObject):Boolean;Begin
 FillChar(Q,SizeOf(Q),0);
 CEInit:=HTInit(Q.List,256);
 Q.List.Context:=@Q;
 {$IFDEF FPC}
  Q.List.CreateItem:=@CECreateItem;
  Q.List.CurrItemSize:=@CECurrItemSize;
  Q.List.Found:=@CEFound;
  Q.List.HashValue:=@CEHashValue;
  Q.List.ItemSize:=@CEItemSize;
 {$ELSE}
  Q.List.CreateItem:=CECreateItem;
  Q.List.CurrItemSize:=CECurrItemSize;
  Q.List.Found:=CEFound;
  Q.List.HashValue:=CEHashValue;
  Q.List.ItemSize:=CEItemSize;
 {$ENDIF}
End;

Procedure CEDone(Var Q:CelluleObject);Begin
 HTDone(Q.List);
End;

Function CEAdd(Var Q:CelluleObject):Boolean;Begin
 CEAdd:=HTAdd(Q.List);
End;

Function CEAddEmpty(Var Q:CelluleObject;Column,Row:LongInt):Boolean;Begin
 If Not CEDelete(Q,Column,Row)Then Begin
  FillChar(Q.Curr,SizeOf(Q.Curr),0);
  Q.Curr.Column:=Column;
  Q.Curr.Row:=Row;
{  Q.Curr.Header.Attribut:=CurrKrs.Dialog.Env.List.Border;}
 End;
 Q.Curr.Header.Format:=cfEmpty;
 Q.Curr.Header.Justify:=cLeft;
 CEAddEmpty:=CEAdd(Q);
End;

Function CEAddRealValue(Var Q:CelluleObject;Column,Row:LongInt;Value:Real):Boolean;Begin
 If Not CEDelete(Q,Column,Row)Then Begin
  FillChar(Q.Curr,SizeOf(Q.Curr),0);
  Q.Curr.Data.v.Dec:=4;
  Q.Curr.Column:=Column;
  Q.Curr.Row:=Row;
{  Q.Curr.Header.Attribut:=CurrKrs.Dialog.Env.List.Border;}
 End;
 Q.Curr.Header.Format:=cfValue;
 Q.Curr.Header.Justify:=cRight;
 Q.Curr.Data.v.Value:=Value;
 CEAddRealValue:=CEAdd(Q);
End;

Function CEAddIntegerValue(Var Q:CelluleObject;Column,Row:LongInt;Value:LongInt):Boolean;Begin
 If Not CEDelete(Q,Column,Row)Then Begin
  FillChar(Q.Curr,SizeOf(Q.Curr),0);
  Q.Curr.Column:=Column;
  Q.Curr.Row:=Row;
{  Q.Curr.Header.Attribut:=CurrKrs.Dialog.Env.List.Border;}
 End;
 Q.Curr.Header.Format:=cfValue;
 Q.Curr.Header.Justify:=cRight;
 Q.Curr.Data.v.Value:=Value;
 CEAddIntegerValue:=CEAdd(Q);
End;

Function CEAddText(Var Q:CelluleObject;Column,Row:LongInt;Const S:String):Boolean;Begin
 If Not CEDelete(Q,Column,Row)Then Begin
  FillChar(Q.Curr,SizeOf(Q.Curr),0);
  Q.Curr.Column:=Column;
  Q.Curr.Row:=Row;
  Q.Curr.Header.Attribut:=$7;
 End;
 Q.Curr.Header.Format:=cfText;
 Q.Curr.Header.Justify:=cLeft;
 Q.Curr.Data.t.Text:=S;
 CEAddText:=CEAdd(Q);
End;

Function CEAddFormula(Var Q:CelluleObject;Column,Row:LongInt;Const S:String):Boolean;Begin
 If Not CEDelete(Q,Column,Row)Then Begin
  FillChar(Q.Curr,SizeOf(Q.Curr),0);
  Q.Curr.Data.f.Dec:=4;
  Q.Curr.Column:=Column;
  Q.Curr.Row:=Row;
  Q.Curr.Header.Attribut:=$7;
 End;
 Q.Curr.Header.Format:=cfFormula;
 Q.Curr.Header.Justify:=cRight;
 Q.Curr.Data.f.Formula:=S;
 Q.Curr.Data.f.Compute:=False;
 CEAddFormula:=CEAdd(Q);
End;

Function CEDelete(Var Q:CelluleObject;Column,Row:LongInt):Boolean;Begin
 Q.Curr.Column:=Column;
 Q.Curr.Row:=Row;
 CEDelete:=HTDelete(Q.List,@Q.Curr);
End;

Function CESearch(Var Q:CelluleObject;Column,Row:LongInt):PCellule;
Var
 I:HashItemPtr;
Begin
 Q.Curr.Column:=Column;
 Q.Curr.Row:=Row;
 I:=HTSearch(Q.List);
 If(I=NIL)Then CESearch:=NIL
          Else CESearch:=@I^.Data;
End;

Function CEHashValue(Var Context):Word;
Var
 Q:CelluleObject Absolute Context;
Begin
 CEHashValue:=Q.Curr.Column+Q.Curr.Row;
End;

Function CEFound(Var Context;Item:HashItemPtr):Boolean;
Var
 Q:CelluleObject Absolute Context;
 ItemData,QCurr:LongInt;
Begin
 Move(Item^.Data,ItemData,SizeOf(ItemData));
 Move(Q.Curr,QCurr,SizeOf(QCurr));
 CEFound:=ItemData=QCurr;
{ CEFound:=Compare(Item^.Data,Q.Curr,SizeOf(LongInt)*2);}
End;

Procedure CECreateItem(Var Context;Var Item:HashItemPtr);
Var
 Q:CelluleObject Absolute Context;
Begin
 Move(Q.Curr,Item^.Data,CEItemSize(Q));
End;

Function CECurrItemSize(Var Context;Item:HashItemPtr):Word;
Var
 Q:CelluleObject Absolute Context;
 P:PCellule;
Begin
 P:=@Item^.Data;
 Case(P^.Header.Format)of
  cfValue:CECurrItemSize:=SizeOf(LongInt)*2+SizeOf(CelluleHeader)+SizeOf(CelluleValue);
  cfText:CECurrItemSize:=SizeOf(LongInt)*2+SizeOf(CelluleHeader)+Length(P^.Data.t.Text)+1;
  cfFormula:CECurrItemSize:=SizeOf(LongInt)*2+SizeOf(CelluleHeader)+
                        SizeOf(CelluleFormula)-SizeOf(String)+Length(P^.Data.f.Formula)+1;
  cfEmpty:CECurrItemSize:=SizeOf(LongInt)*2+SizeOf(CelluleHeader);
  Else CECurrItemSize:=SizeOf(CelluleRec);
 End;
End;

Function CEItemSize(Var Context):Word;
Var
 Q:CelluleObject Absolute Context;
Begin
 Case(Q.Curr.Header.Format)of
  cfValue:CEItemSize:=SizeOf(LongInt)*2+SizeOf(CelluleHeader)+SizeOf(CelluleValue);
  cfText:CEItemSize:=SizeOf(LongInt)*2+SizeOf(CelluleHeader)+Length(Q.Curr.Data.t.Text)+1;
  cfFormula:CEItemSize:=SizeOf(LongInt)*2+SizeOf(CelluleHeader)+
                        SizeOf(CelluleFormula)-SizeOf(String)+Length(Q.Curr.Data.f.Formula)+1;
  cfEmpty:CEItemSize:=SizeOf(LongInt)*2+SizeOf(CelluleHeader);
  Else CEItemSize:=SizeOf(CelluleRec);
 End;
End;

Function CENumLine(Var Q:CelluleObject):LongInt;
Var
 I:HashItemPtr;
 C:PCellule;
Begin
 Q.X1:=$7FFFFFFF;Q.X2:=0;
 Q.Y1:=$7FFFFFFF;Q.Y2:=0;
 I:=HTFirstItem(Q.List);
 While(I<>NIL)do Begin
  C:=@I^.Data;
  If(C^.Row<Q.Y1)Then Q.Y1:=C^.Row;
  If(C^.Row>Q.Y2)Then Q.Y2:=C^.Row;
  I:=HTNextItem(Q.List);
 End;
 CENumLine:=Q.Y2-Q.Y1+1;
End;

Function CEFindLine(Var Q:CelluleObject;YP:LongInt):PCellule;
Var
 I:HashItemPtr;
 C:PCellule;
Begin
 Q.X1:=$7FFFFFFF;Q.X2:=0;
 Q.Y1:=YP;Q.Y2:=YP;
 I:=HTFirstItem(Q.List);
 While(I<>NIL)do Begin
  C:=@I^.Data;
  If(C^.Row=YP)Then Begin
   If(C^.Column<Q.X1)Then Q.X1:=C^.Column;
   If(C^.Column>Q.X2)Then Q.X2:=C^.Column;
  End;
  I:=HTNextItem(Q.List);
 End;
 CEFindLine:=CESearch(Q,Q.X1,YP);
 If Q.X1>=0Then Inc(Q.X1);
End;

Function CEFirstItem(Var Q:CelluleObject):PCellule;
Var
 I:HashItemPtr;
Begin
 Q.X1:=-1;
 I:=HTFirstItem(Q.List);
 If(I=NIL)Then CEFirstItem:=NIL
          Else CEFirstItem:=@I^.Data;
End;

Function CENextItem(Var Q:CelluleObject):PCellule;
Var
 I:HashItemPtr;
Begin
 If Q.X1<0Then Begin
  I:=HTNextItem(Q.List);
  If(I=NIL)Then CENextItem:=NIL
           Else CENextItem:=@I^.Data;
 End
  Else
 Begin
  If(Q.X1>Q.X2)Then CENextItem:=NIL
   Else
  Begin
   CENextItem:=CESearch(Q,Q.X1,Q.Y1);
   Inc(Q.X1);
  End;
 End;
End;

Procedure CEInsertColumn(Var Q:CelluleObject;Column:LongInt);
Var
 New:CelluleObject;
 P:PCellule;
Begin
 CEInit(New);
 P:=CEFirstItem(Q);
 While(P<>NIL)do Begin
  New.Curr:=P^;
  If(New.Curr.Column>=Column)Then Inc(New.Curr.Column);
  CEAdd(New);
  CEDelete(Q,P^.Column,P^.Row);
  P:=CEFirstItem(Q);
 End;
 CEDone(Q);
 Q:=New;
End;

Procedure CEInsertRow(Var Q:CelluleObject;Row:LongInt);
Var
 New:CelluleObject;
 P:PCellule;
Begin
 CEInit(New);
 P:=CEFirstItem(Q);
 While(P<>NIL)do Begin
  New.Curr:=P^;
  If(New.Curr.Row>=Row)Then Inc(New.Curr.Row);
  CEAdd(New);
  CEDelete(Q,P^.Column,P^.Row);
  P:=CEFirstItem(Q);
 End;
 CEDone(Q);
 Q:=New;
End;

Procedure CEDeleteColumn(Var Q:CelluleObject;Column:LongInt);
Var
 New:CelluleObject;
 P:PCellule;
Begin
 CEInit(New);
 P:=CEFirstItem(Q);
 While(P<>NIL)do Begin
  New.Curr:=P^;
  If(New.Curr.Column>=Column)Then Dec(New.Curr.Column);
  If(P^.Column<>Column)Then CEAdd(New);
  CEDelete(Q,P^.Column,P^.Row);
  P:=CEFirstItem(Q);
 End;
 CEDone(Q);
 Q:=New;
End;

Procedure CEDeleteRow(Var Q:CelluleObject;Row:LongInt);
Var
 New:CelluleObject;
 P:PCellule;
Begin
 CEInit(New);
 P:=CEFirstItem(Q);
 While(P<>NIL)do Begin
  New.Curr:=P^;
  If(New.Curr.Row>=Row)Then Dec(New.Curr.Row);
  If(P^.Row<>Row)Then CEAdd(New);
  CEDelete(Q,P^.Column,P^.Row);
  P:=CEFirstItem(Q);
 End;
 CEDone(Q);
 Q:=New;
End;

Var
 PX,PY:Word;
 SX,SY:Byte;
 Cellule:CelluleObject;
 FileName:String;

Procedure Box(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Window(X1,Y1,X2,Y2);
 TextBackground((Couleur shr 4)and 15);
 TextColor(Couleur and 15);
 ClrScr;
 Window(1,1,80,25);
End;

Function Col2Str(C:LongInt):String;
Var
 S:String[6];
Begin
 Inc(C);
 If C>308915802Then S:=Char(Byte('A')+((C-308915803) div 308915776))
	       Else S:='';
 If C>11881402Then S:=S+Char(Byte('A')+((C-11881403) div 11881376));
 If C>457002Then S:=S+Char(Byte('A')+((C-457003) div 456976));
 If C>18278Then S:=S+Char(Byte('A')+((C-18279) div 17576));
 If C>702Then S:=S+Char(Byte('A')+((Word(C-703)mod 17576) div 676));
 If C>26Then S:=S+Char(Byte('A')+((Word(C-27)mod 676) div 26));
 S:=S+Char(Byte('A')+(Word(C-1)mod 26));
 Col2Str:=S;
End;

Procedure ShowCellule(PX,PY:Word;Refresh:Boolean);
Var
 CurrCellule:PCellule;
Begin
 CurrCellule:=CESearch(Cellule,PX,PY);
 If CurrCellule<>NIL Then Begin
  If CurrCellule^.Header.Format=cfText Then Write(PadRight(CurrCellule^.Data.t.Text,9)) Else
  If(Refresh)Then Write(' ':9);
 End
  Else
 If(Refresh)Then Write(' ':9);
End;

Procedure ShowSpreadSheet;
Var
 I,J:Byte;
 S:String;
Begin
 TextColor(Black);
 TextBackground(Cyan);
 For I:=0 to 7 do Begin
  GotoXY(5+I*9,4);
  Write(' ':5,PadRight(Col2Str((PX-SX)+I),5));
 End;
 Box(5,5,80,24,7);
 For J:=0 to 19 do Begin
  TextColor(Black);
  TextBackground(Cyan);
  GotoXY(1,5+J);
  Str((PY-SY)+J+1,S);
  Write(PadRight(S,4));
  For I:=0 to 7 do Begin
   TextColor(7);
   TextBackground(Black);
   GotoXY(5+I*9,5+J);
   ShowCellule((PX-SX)+I,(PY-SY)+J,False);
  End;
 End;
End;

Procedure LoadSpreatSheet;
Var
 F:File{$IFDEF FPC} of Byte{$ENDIF};
 SpecialChar:Boolean;
 PCel:PCellule;
 LHeader:HeaderLotus123;
 LLabel:LabelLotus123;
 LInteger:IntegerLotus123;
 ByteReaded:Integer;
 FP,FS:LongInt;
 Str:String;
Begin
 {$I-}Assign(F,FileName);
 Reset(F);{$I+}
 If IoResult=0Then Begin
  CEDone(Cellule);
  CEInit(Cellule);
  BlockRead(F,LHeader,SizeOf(LHeader),ByteReaded);
  FP:=0;
  FS:=FileSize(F);
  If(LHeader.TypeCode=0)and(LHeader.Length=2)Then Begin
   Repeat
    Seek(F,FP);
    FillChar(LLabel,SizeOf(LLabel),0);
    BlockRead(F,LLabel,SizeOf(LLabel),ByteReaded);
    Case(LLabel.TypeCode)of
     13:Begin
      CEAddIntegerValue(Cellule,LInteger.Column,LInteger.Row,LInteger.Value);
     End;
     14:Begin
 {     CEAddRealValue(Cellule,LInteger.Column,LInteger.Row,DoubleToReal(DoubleLotus.Value));}
     End;
     15:Begin
      Str:=StrPas(@LLabel.Text);
      SpecialChar:=Str[1]in['''','^','"'];
      If(SpecialChar)Then Begin
       CEAddText(Cellule,LLabel.Column,LLabel.Row,Copy(Str,2,255));
       {PCel:=SCGetCellule(Q,Data.Col,Data.Row);
       If(PCel<>NIL)Then Case Str[1]of
        '''':PCel^.Header.Justify:=cLeft;
        '^':PCel^.Header.Justify:=cCenter;
        '"':PCel^.Header.Justify:=cRight;
       End;}
      End
       Else
      CEAddText(Cellule,LLabel.Column,LLabel.Row,Str);
     End;
    End;
    If LLabel.Length<=0 Then Break;
    Inc(FP,LLabel.Length+4);
   Until FP>=FS;
  End;
 End;
 Close(F);
End;

Procedure SaveSpreatSheet;
Var
 F:File{$IFDEF FPC} of Byte{$ENDIF};
 H:HashItemPtr;
 LHeader:HeaderLotus123;
 LEnd:EndLotus123;
 LLabel:LabelLotus123;
 LDouble:DoubleLotus123;
Begin
 {$I-}Assign(F,FileName);
 Rewrite(F);{$I-}
 If IoResult=0 Then Begin
   {Ecriture de l'entete}
  LHeader.TypeCode:=0;
  LHeader.Length:=2;
  LHeader.Value:=1030;
  BlockWrite(F,LHeader,SizeOf(LHeader));
   {Ecriture du corps}
  H:=HTFirstItem(Cellule.List);
  While(H<>NIL)do Begin
   Move(H^.Data,Cellule.Curr,SizeOf(CelluleRec));
   FillChar(LLabel,SizeOf(LLabel),0);
   LLabel.Column:=Cellule.Curr.Column;
   LLabel.Row:=Cellule.Curr.Row;
  { Data.H:=Cellule.Curr.Header;}
   Case(Cellule.Curr.Header.Format)of
    cfText:Begin
     LLabel.TypeCode:=$0F;
     LLabel.Length:=Length(Cellule.Curr.Data.t.Text)+7{6};
     LLabel.Format:=$FF;
     Case(Cellule.Curr.Header.Justify)of
      cCenter:LLabel.Text[0]:='^';
      cRight:LLabel.Text[0]:='"';
      Else LLabel.Text[0]:='''';
     End;
     StrPascalCopy(LLabel.Text[1],239,Cellule.Curr.Data.t.Text);
    End;
    cfValue:Begin
     LDouble.TypeCode:=$E;
     LDouble.Length:=13;
     LDouble.Format:=2 or 128;
     {RealToDouble(Q.Cellule.Curr.Data.v.Value,LDouble.Value);}
    End;
   End;
   Case(Cellule.Curr.Header.Format)of
    cfText:BlockWrite(F,LLabel,Length(Cellule.Curr.Data.t.Text)+11);
    cfValue:BlockWrite(F,LDouble,17);
 {   cfFormula:AddLotusFormula(Cellule.Curr.Column,Cellule.Curr.Row,Cellule.Curr.Data.f.Formula);}
   End;
   H:=HTNextItem(Cellule.List);
  End;
   {Ecriture de la fin}
  LEnd.TypeCode:=1;
  LEnd.Length:=0;
  BlockWrite(F,LEnd,SizeOf(LEnd));
  Close(F);
 End;
End;

Procedure Init;Begin
 CEInit(Cellule);
 PX:=0;
 PY:=0;
 SX:=0;
 SY:=0;
End;

Procedure SelectColor;Begin
 TextColor(Black);
 TextBackground(Cyan);
End;

Procedure UnselectColor;Begin
 TextColor(7);
 TextBackground(Black);
End;

Procedure ShowCurrCellule;Begin
 GotoXY(5+SX*9,5+SY);
 ShowCellule(PX,PY,True);
End;

Procedure ShowStatusCellule;
Var
 CurrCellule:PCellule;
Begin
 UnselectColor;
 GotoXY(1,1);
 Write(Col2Str(PX),PY+1,': ');
 CurrCellule:=CESearch(Cellule,PX,PY);
 If CurrCellule<>NIL Then Begin
  If CurrCellule^.Header.Format=cfText Then Write('''',CurrCellule^.Data.t.Text);
 End;
 ClrEol;
End;

Function PullMenu:Boolean;
Const
 MaxItem:Array[0..8]of Byte=(9,8,9,0,0,7,1,13,7);
 MenuItem0:Array[0..9] of String[10]=(
  'Feuille',
  'Champ',
  'Recopie',
  'Deplace',
  'Transfert',
  'Impression',
  'Graphe',
  'Outils',
  'Systeme',
  'Quitte'
 );
 Legend0:Array[0..9]of String[75]=(
  'Global, Insere, Detruit, Colonne, RAZ, Titres, Fenetre, Statut, Page',
  'Format,Aligne,Efface,Noms,Justifie,Protege,Deprotege,Saisie,Valeurs,Transpose',
  'Copie une cellule ou un champ de cellules',
  'Deplace une cellule ou un champ de cellules',
  'Charge, Sauve, Associe, Extrait, Detruit, Liste, Importe, Repertoire',
  'Envoie un champ a l''imprimante ou a un fichier d''impression',
  'Cree un graphique',
  'Ecrit-serie,Hypotheses,Trie,Base,Frequence,Matrice,Regression,Analyse',
  'Sortir de 123, passer sous DOS puis revenir a 123',
  'Met fin a la session 1-2-3 (avez-vous sauve votre travail?)'
 );
 MenuItem1:Array[0..8]of String[10]=(
  'Global','Insere','Detruit','Colonne','RAZ','Titres','Fenetre','Statut','Page'
 );
 Legend1:Array[0..8]of String[75]=(
  'Determine les parametres de la feuille',
  'Insere une ou plusieurs colonne(s) ou ligne(s) vierge(S)',
  'Detruit une ou plusieurs colonne(s) ou ligne(s)',
  'Determine les parametres d''affichage de la colonne actuelle',
  'Efface l''integralite de la feuille',
  'Definit des titres horizontaux ou/et verticaux',
  'Determine la separation de l''ecran et al synchronisation du defilement',
  'Affiche les parametres de la feuille',
  'Introduit un saut de page au-dessus du pointeur'
 );

 MenuItem2:Array[0..9]of String[9]=(
  'Format',
  'Align',
  'Efface',
  'Noms',
  'Justifie',
  'Protege',
  'Deprotege',
  'Saisie',
  'Valeurs',
  'Transpose'
 );
 Legend2:Array[0..9]of String[75]=(
  'Determine le format d''une cellule ou d''un champ de cellules',
  'Aligne un libelle ou un champ de libelles (Gauche, Droite, Centre)',
  'Efface le contenu d''une cellule ou d''un champ de cellules',
  'Cree, efface ou modifie des noms de champs',
  'Ajuste la largeur d''une colonne de libelles',
  'Empeche de modifier un champ si le verrouillage est active',
  'Permet de modifier un champ',
  'Entre des donneese dans les cellules non protegees d''un champ',
  'Copie un champ et convertit les formules en valeurs',
  'Copie un champ en inversant les colonnes et les lignes'
 );
 MenuItem5:Array[0..7]of String[12]=(
  'Charge','Sauve','Associe','Extrait','Supprime','Liste','Importe','Repertoire'
 );
 Legend5:Array[0..7]of String[75]=(
  'Efface la feuille actuelle et affiche la feuille choisie',
  'Enregistre l''integralite de la feuille dans un fichier feuille',
  'Incorpore tout ou partie d''un fichier feuille dans la feuille actuelle',
  'Enregistre un champ de cellules dans un fichier feuille',
  'Supprime un fichier feuille, impression ou graphique',
  'Affiche les noms des fichiers 1-2-3 dans le repertoire actuel',
  'Incorpore le texte ou les nombres d''un fichier d''impression dans la feuille',
  'Affiche et/ou determine le repertoire actuel'
 );
 MenuItem6:Array[0..1]of String[10]=(
  'Imprimante','Fichier'
 );
 Legend6:Array[0..1]of String[75]=(
  'Envoie le document a l''imprimante',
  'Envoie le document a un fichier'
 );
 MenuItem7:Array[0..13]of String[15]=(
  'Type','X','A','B','C','D','E','F','RAZ','Visualisation','Sauve','Option','Nom','Quitte'
 );
 Legend7:Array[0..13]of String[75]=(
  'Determine le type de graphique',
  'Determine le champ X',
  'Determine le premier champ de donnees',
  'Determine le deuxieme champ de donnees',
  'Determine le troisieme champ de donnees',
  'Determine le quatrieme champ de donnees',
  'Determine le cinquieme champ de donnees',
  'Determine le sixieme champ de donnees',
  'Annule les parametres du graphique',
  'Affiche le graphique actuel',
  'Sauve le graphique actuel pour impression ulterieure',
  'Legende, Format, Titres, Grille, Echelle, Couleur, N&B, Inititules',
  'Utilise, cree, efface, ou annule des champs nommes',
  'Repasse en mode PRET'
 );
 MenuItem8:Array[0..7]of String[15]=(
  'Ecrit-serie','Hypotheses','Trie','Base','Frequence','Matrice','Regression','Analyse'
 );
 Legend8:Array[0..7]of String[75]=(
  'Introduit une serie de nombres dans un champ',
  'Cree un tableau permettant d''analyser des hypotheses',
  'Trie les enregistrements de donnees',
  'Trouve les enregistrements repondant a des criteres donnes',
  'Calcule la distribution de frequence d''un champ',
  'Effectue des calculs de matrice',
  'Calcule des regressions lineaires',
  'Analyse une colonne de libelles dans un champ'
 );
Var
 I:Integer;
 Level,P:Byte;
 K:Char;
Begin
 PullMenu:=False;
 Level:=0;P:=0;
 Repeat
  GotoXY(1,2);
  For I:=0 to MaxItem[Level] do Begin
   If I=P Then SelectColor
          Else UnselectColor;
   Case Level of
    1:Write(MenuItem1[I]);
    2:Write(MenuItem2[I]);
    5:Write(MenuItem5[I]);
    6:Write(MenuItem6[I]);
    7:Write(MenuItem7[I]);
    8:Write(MenuITem8[I]);
    Else Write(MenuItem0[I]);
   End;
   UnselectColor;
   Write(' ');
  End;
  ClrEol;
  GotoXY(1,3);
  Write(Legend0[P]);
  ClrEol;
  K:=ReadKey;
  If K=#0 Then Begin
   K:=ReadKey;
   Case K of
    #75:Begin { LEFT }
     If P=0Then P:=MaxItem[Level]
           Else P:=P-1;
    End;
    #77:Begin { RIGHT }
     If P=MaxItem[Level]Then P:=0
                        Else P:=P+1;
    End;
   End;
  End
   Else
  If K=#13Then Begin
   Case Level of
    0:Case(P)of
     0,1,4,5,6,7:Begin
      Level:=P+1;
      P:=0;
     End;
     8:Begin
      ClrScr;
      Exec(GetEnv('COMSPEC'),'');
      ClrScr;
      ShowSpreadSheet;
     End;
     9:Begin
      PullMenu:=True;
      Exit;
     End;
    End;
    5:Begin
     Case P of
      0:Begin { Charge }
       GotoXY(1,2);
       Write('Nom du fichier a charge: ');
       Repeat
        GotoXY(26,2);
        Write(FileName);
        ClrEol;
        K:=ReadKey;
        Case K of
         #0:Begin
          K:=ReadKey;
          Case K of
           #53:FileName:=FileName+'/';
          End;
         End;
         #8: If FileName<>''Then FileName:=Copy(FileName,1,Length(FileName)-1);
         #13:Begin
          LoadSpreatSheet;
          GotoXY(1,2);ClrEol;
          GotoXY(1,3);ClrEol;
          ShowSpreadSheet;
          Exit;
         End;
         Else FileName:=FileName+K;
        End;
       Until K in[#13,#27];
      End;
      1:Begin { Sauve }
       GotoXY(1,2);
       Write('Nom du fichier a sauver: ');
       Repeat
        GotoXY(26,2);
        Write(FileName);
        ClrEol;
        K:=ReadKey;
        Case K of
         #0:Begin
          K:=ReadKey;
          Case K of
           #53:FileName:=FileName+'/';
          End;
         End;
         #8: If FileName<>''Then FileName:=Copy(FileName,1,Length(FileName)-1);
         #13:Begin
          SaveSpreatSheet;
          GotoXY(1,2);ClrEol;
          GotoXY(1,3);ClrEol;
          ShowSpreadSheet;
          Exit;
         End;
         Else FileName:=FileName+K;
        End;
       Until K in[#13,#27];
      End;
     End;
    End;
   End;
  End
   Else
  If K=#27Then Begin
   If Level>0Then Begin
    Level:=0;
    K:=#0;
   End;
  End;
 Until K=#27;
 GotoXY(1,2);
 ClrEol;
 GotoXY(1,3);
 ClrEol;
End;

Procedure Run;
Var
 K:Char;
 CurrCommand:String;
Begin
 SelectColor;
 ShowCurrCellule;
 ShowStatusCellule;
 Repeat
  GotoXY(77,1);
  Write('PRET');
  GotoXY(10+SX*9,5+SY);
  K:=ReadKey;
  If K=#0 Then Begin
   K:=ReadKey;
   Case K of
    #31:SaveSpreatSheet; { Alt+S }
    #38:Begin { Alt+L }
     LoadSpreatSheet;
     ShowSpreadSheet;
    End;
    #53:If PullMenu Then Exit; { / Sur le bloc numeric }
    #72:Begin { UP }
     UnselectColor;
     ShowCurrCellule;
     If PY>0 Then PY:=PY-1;
     If SY>0 Then SY:=SY-1
             Else ShowSpreadSheet;
     ShowStatusCellule;
     SelectColor;
     ShowCurrCellule;
    End;
    #75:Begin { LEFT }
     UnselectColor;
     ShowCurrCellule;
     If PX>0 Then PX:=PX-1;
     If SX>0 Then SX:=SX-1
             Else ShowSpreadSheet;
     ShowStatusCellule;
     SelectColor;
     ShowCurrCellule;
    End;
    #77:Begin { RIGHT }
     UnselectColor;
     ShowCurrCellule;
     If PX<65520 Then PX:=PX+1;
     If SX<7 Then SX:=SX+1
             Else ShowSpreadSheet;
     ShowStatusCellule;
     SelectColor;
     ShowCurrCellule;
    End;
    #80:Begin { DOWN }
     UnselectColor;
     ShowCurrCellule;
     If PY<65520 Then PY:=PY+1;
     If SY<19 Then SY:=SY+1
              Else ShowSpreadSheet;
     ShowStatusCellule;
     SelectColor;
     ShowCurrCellule;
    End;
   End;
  End
   Else
  If K='/'Then Begin
   If PullMenu Then Exit;
  End
   Else
  If K<>#27Then Begin
   UnselectColor;
   CurrCommand:=K;
   Repeat
    GotoXY(1,2);
    Write(CurrCommand);
    ClrEol;
    K:=ReadKey;
    Case K of
     #0:Begin
      K:=ReadKey;
      Case K of
       #53:CurrCommand:=CurrCommand+'/';
      End;
     End;
     #8: If CurrCommand<>''Then CurrCommand:=Copy(CurrCommand,1,Length(CurrCommand)-1);
     #13:Begin
      CEAddText(Cellule,PX,PY,CurrCommand);
      ShowStatusCellule;
      SelectColor;
      ShowCurrCellule;
     End;
     Else CurrCommand:=CurrCommand+K;
    End;
   Until K in[#13,#27];
   K:=#0;
  End;
 Until K=#27;
End;

BEGIN
 FileName:=GetCurrentDir+'\FILE0001.WK1';
 Init;
 ClrScr;
 ShowSpreadSheet;
 Run;
 UnselectColor;
 ClrScr;
END.
