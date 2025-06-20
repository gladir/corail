{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/pcdos-0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program E;

Uses Strings,Crt,DOS;

Const
 EditX=2;
 EditY=3;
 EditNumLines=22;

 MainMenu:Array[0..5]of String[10]=(
  'Fichier','Edition','Recherche','Vue','Options','Aide'
 );

 MainMenuEnglish:Array[0..5]of String[10]=(
  'File','Edit','Search','View','Options','Help'
 );

 MainMenuGermany:Array[0..5]of String[10]=(
  'Datei','Bearbeiten','Sucdhen','Aussicht','Optionen','Hilfe'
 );

 SubMenuFile:Array[0..8]of String[20]=(
  'Nouveau','Ouvrir...','Sauvegarde','Sauvegarde sous...',
  'Fermer','','Imprimer...','','Sortir'
 );

 SubMenuFileEnglish:Array[0..8]of String[20]=(
  'New','Open...','Save','Save As...',
  'Close','','Print...','','Exit'
 );

 SubMenuFileGermany:Array[0..8]of String[20]=(
  'Neu','�ffnen...','Speichern','Speichern unter...',
  'Nah dran','','Drucken...','','Beenden'
 );

 SubMenuEdit:Array[0..3]of String[10]=(
  'Couper','Copier','Coller','Efface'
 );

 SubMenuEditEnglish:Array[0..3]of String[10]=(
  'Cut','Copy','Paste','Clear'
 );

 SubMenuEditGermany:Array[0..3]of String[10]=(
  'Ausschneiden','Kopieren','Einf�gen','L�schen'
 );

 SubMenuSearch:Array[0..2]of String[30]=(
  'Recherche..','Repete la derniere recherche','Remplace...'
 );

 SubMenuSearchEnglish:Array[0..2]of String[30]=(
  'Find..','Repeat Last Find','Replace...'
 );

 SubMenuSearchGermany:Array[0..2]of String[30]=(
  'Suchen...','Weitersuchen','�ndern...'
 );

 SubMenuView:Array[0..2]of String[25]=(
  'Fragmente une fenetre','Taille de la fenetre','Ferme la fenetre'
 );

 SubMenuViewEnglish:Array[0..2]of String[25]=(
  'Split window','Size Window','Close Window'
 );

 SubMenuOptions:Array[0..1]of String[15]=(
  'Ajustements...','Couleurs...'
 );

 SubMenuOptionsEnglish:Array[0..1]of String[15]=(
  'Settings...','Colors...'
 );

 SubMenuOptionsGermany:Array[0..1]of String[15]=(
  'Bildschirmanzeige...','Pfad f�r Hilfe...'
 );

 SubMenuHelp:Array[0..1]of String[15]=(
  'Commandes...','A propos...'
 );

 SubMenuHelpEnglish:Array[0..1]of String[15]=(
  'Commands...','About...'
 );

 YMenuMax:Array[1..6]of Byte=(
  High(SubMenuFile),High(SubMenuEdit),High(SubMenuSearch),
  High(SubMenuView),High(SubMenuOptions),
  High(SubMenuHelp)
 );

Type

 PCharByteRec=Record
  PChr:PChar;
  Nm:Byte;
 End;

 StrByteRec=Record
  PChr:PChar;
  Nm:Byte;
  Len:Word;
 End;

 StrWordRec = Record
  PChr:PChar;
  Nm,Len:Word;
 End;

 PCharWordRec = Record
  PChr:PChar;
  Nm:Word;
 End;

 RBufPtr = ^RBufRec;

 RBufRec = Record
  Buf:Pointer;
  Size:Word;
  Previous,Next:RBufPtr;
 End;

 ArrayList = Record
  PCurrPtr,Count:LongInt;
  CurrPtr,List,EndListPtr:RBufPtr;
 End;

Const
 MinRec=SizeOf(PCharWordRec)+1;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 Use132Column,ShowASCII128,OnMenu:Boolean;
 YMenu,XMenu:Integer;
 EditNumColumns,MaxX:Integer;

Function MaxAvail:LongInt;Begin
 MaxAvail:=High(LongInt);
End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function DuplicateString(C:Char;Num:Integer):String;
Var
 I:Byte;
 S:String;
Begin
 S:='';
 For I:=1 to Num do S:=S+C;
 DuplicateString:=S;
End;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function MemAlloc(Size:Word):Pointer;
Var Ptr:Pointer;
Begin
 MemAlloc := NIL;
 If(Size = 0)Then Exit;
 If(MaxAvail < Size)Then Exit;
 GetMem(Ptr,Size);
 MemAlloc := Ptr;
End;

Function MemNew(Size:Word):Pointer;
Var
 Ptr:Pointer;
Begin
 Ptr:=MemAlloc(Size);
 If(Ptr<>NIL)Then FillChar(Ptr^,Size,0);
 MemNew:=Ptr;
End;

Function NewBlock(Var Buf;Size:Word):Pointer;
Var
 Ptr:Pointer;
Begin
 Ptr:=MemAlloc(Size);
 If(Ptr<>NIL)Then Move(Buf,Ptr^,Size);
 NewBlock:=Ptr;
End;

Procedure ArrayListInit(Var Q:ArrayList);Begin
 Q.PCurrPtr := -1;
 Q.CurrPtr := NIL;
 Q.List := NIL;
 Q.EndListPtr := NIL;
 Q.Count := 0;
End;

Function ArrayListIsEmpty(Var Q:ArrayList):Boolean;
Begin
 ArrayListIsEmpty := (Q.List = NIL);
End;

Function ArrayListAdd(Var Q:ArrayList;Size:Word):Pointer;
Var
 W:RBufRec;
 WPtr:RBufPtr;
 Addr:Pointer;
Begin
 ArrayListAdd:=NIL;
 FillChar(W,SizeOf(W),0);
 If Size>0Then Begin
  Addr:=MemAlloc(Size);
  If(Addr=NIL)Then Exit;
  W.Buf:=Addr;
  W.Size:=Size
 End;
 If(Q.List=NIL)Then Begin
  Q.List:=NewBlock(W,SizeOf(RBufRec));
  If(Q.List=NIL)Then Exit;
  Q.EndListPtr:=Q.List
 End
  Else
 Begin
  WPtr:=Q.EndListPtr;
  If(WPtr=NIL)Then Exit;
  W.Previous:=WPtr;
  WPtr^.Next:=NewBlock(W,SizeOf(RBufRec));
  Q.EndListPtr:=WPtr^.Next;
 End;
 Inc(Q.Count);
 ArrayListAdd:=Addr
End;

Function ArrayListAddBuf(Var Q:ArrayList;Size:Word;Const Block):Boolean;
Var
 Ptr:Pointer;
Begin
 ArrayListAddBuf:=False;
 Ptr:=ArrayListAdd(Q,Size);
 If(Ptr<>NIL)Then Begin
  Move(Block,Ptr^,Size);
  ArrayListAddBuf:=True;
 End;
End;

Function ArrayList_AddBuf(Var Q:ArrayList;Size:Word):Pointer;
Var Ptr:Pointer;
Begin
 ArrayList_AddBuf := NIL;
 If Not(ArrayListAddBuf(Q,Size,Ptr))Then Exit;
 ArrayList_AddBuf := Ptr;
End;

Function ArrayList_SetPtr(Var Q:ArrayList;P:LongInt):Pointer;
Var
 WP:RBufPtr;
 I:LongInt;
Begin
 WP:=Q.List;
 For I:=1to(P)do Begin
  WP:=WP^.Next;
  If(WP=NIL)Then Begin
   ArrayList_SetPtr:=NIL;
   Exit;
  End;
 End;
 ArrayList_SetPtr:=WP
End;


Function ArrayListIns(Var Q:ArrayList;P:LongInt;Size:Word):Pointer;
Var
 WP,NewP:RBufPtr;
 Addr:Pointer;
Begin
 ArrayListIns:=NIL;
 If(P>Q.Count)Then Exit;
 If(P=Q.Count)Then ArrayListIns:=ArrayListAdd(Q,Size)
  else
 Begin
  Addr:=NIL;
  If P=0Then Begin
   WP:=MemNew(SizeOf(Q.List^));
   If(WP=NIL)Then Exit;
   Q.List^.Previous:=WP;WP^.Next:=Q.List;
   If Size>0Then Begin
    Addr:=MemAlloc(Size);
    If(Addr=NIL)Then Exit;
    WP^.Buf:=Addr;WP^.Size:=Size
   End;
   Q.List:=WP
  End
   else
  Begin
   NewP:=MemNew(SizeOf(Q.List^));
   If(NewP=NIL)Then Exit;
   WP:=ArrayList_SetPtr(Q,P);
   If(WP=NIL)Then Exit;
   NewP^.Next:=WP;
   NewP^.Previous:=WP^.Previous;
   If Size>0Then Begin
    Addr:=MemAlloc(Size);
    If(Addr=NIL)Then Exit;
    NewP^.Buf:=Addr;
    NewP^.Size:=Size
   End;
   WP^.Previous^.Next:=NewP;
   WP^.Previous:=NewP
  End;
  Inc(Q.Count);
  ArrayListIns:=Addr
 End
End;

Function ArrayListInsBlock(Var Q:ArrayList;P:LongInt;Size:Word;Const Block):Boolean;
Var
 Ptr:Pointer;
Begin
 ArrayListInsBlock:=False;
 Ptr:=ArrayListIns(Q,P,Size);
 If(Ptr<>NIL)Then Begin
  Move(Block,Ptr^,Size);
  ArrayListInsBlock:=True;
 End;
End;


Function ArrayListInsBuf(Var Q:ArrayList;P:LongInt;Size:Word;Var Addr:Pointer):Boolean;
Var WP,NewP:RBufPtr; I:LongInt;
Begin
 ArrayListInsBuf := False;
 If(P > Q.Count)Then Exit;
 If(P = Q.Count)Then ArrayListInsBuf := ArrayListAddBuf(Q,Size,Addr)
  else
 Begin
  ArrayListInsBuf := False;
  If(P = 0)Then
  Begin
   WP := MemAlloc(SizeOf(Q.List^));
   If(WP = NIL)Then Exit;
   Q.List^.Previous := WP; WP^.Previous := NIL; WP^.Next := Q.List;
   If(Size = 0)Then
   Begin
    WP^.Buf := NIL; WP^.Size := 0; Addr := NIL;
   End
    Else
   Begin
    Addr := MemAlloc(Size);
    If(Addr = NIL)Then Exit;
    WP^.Buf := Addr; WP^.Size := Size;
   End;
   Q.List := WP;
  End
   else
  Begin
   NewP := MemAlloc(SizeOf(Q.List^));
   If(NewP = NIL)Then Exit;
   WP := Q.List;
   For I := 1 to P do
   Begin
    If(WP = NIL)Then Exit;
    WP := WP^.Next;
   End;
   NewP^.Next := WP; NewP^.Previous := WP^.Previous;
   If(Size = 0)Then
   Begin
    NewP^.Buf := NIL; NewP^.Size := 0; Addr := NIL;
   End
    Else
   Begin
    Addr := MemAlloc(Size);
    If(Addr = NIL)Then Exit;
    NewP^.Buf := Addr; NewP^.Size := Size;
   End;
   WP^.Previous^.Next := NewP; WP^.Previous := NewP;
  End;
  Inc(Q.Count); ArrayListInsBuf := True;
 End;
End;

Function ArrayListAddPChr(Var Q:ArrayList;PChr:PChar):Boolean;
Type
 TChar=Array[0..32767]of Char;
Var
 PBuf:^TChar;
 L:Word;
Begin
 ArrayListAddPChr:=False;
 L:=StrLen(PChr)+1;
 PBuf:=ArrayListAdd(Q,L);
 If(PBuf=NIL)Then Exit;
 If L=1Then PBuf^[0]:=#0
       Else Move(PChr^,PBuf^,L);
 ArrayListAddPChr:=True
End;

Function ArrayListAddPChrByte(Var Q:ArrayList;PChr:PChar;Num:Byte):Boolean;
Var PCharByte:^PCharByteRec; Ptr:Pointer;
Begin
 ArrayListAddPChrByte := False;
 If Not(ArrayListAddBuf(Q,SizeOf(PCharByteRec),Ptr))Then Exit;
 PCharByte := Ptr; PCharByte^.PChr := PChr; PCHarByte^.Nm := Num;
 ArrayListAddPChrByte := True;
End;

Function ArrayListAddStrByte(Var Q:ArrayList;Str:String;Num:Byte):Boolean;
Var StrByte:^StrByteRec; Ptr:Pointer; PChr:Array[0..255] of Char;
Begin
 ArrayListAddStrByte := False;
 If Not(ArrayListAddBuf(Q,SizeOf(StrByteRec),Ptr))Then Exit;
 StrByte := Ptr; StrPCopy(PChr,Str); StrByte^.PChr := StrNew(PChr);
 StrByte^.Len := Length(Str); StrByte^.Nm := Num; ArrayListAddStrByte := True;
End;

Function ArrayListAddStrWord(Var Q:ArrayList;Str:String;Num:Word):Boolean;
Var StrWord:^StrWordRec; Ptr:Pointer; PChr:Array[0..255] of Char;
Begin
 ArrayListAddStrWord := False;
 If Not(ArrayListAddBuf(Q,SizeOf(StrWordRec),Ptr))Then Exit;
 StrWord := Ptr; StrPCopy(PChr,Str); StrWord^.PChr := StrNew(PChr);
 StrWord^.Len := Length(Str); StrWord^.Nm := Num; ArrayListAddStrWord := True;
End;

Function ArrayListAddLn(Var Q:ArrayList):Boolean;
Begin
 ArrayListAddLn := ArrayListAddPChr(Q,NIL);
End;

Function ArrayListAddStr(Var Q:ArrayList;Const Str:String):Boolean;
Var
 Ptr:Pointer;
 PC:PChar Absolute Ptr;
 Size:Word;
Begin
 If Length(Str)=0Then ArrayListAddStr:=ArrayListAddLn(Q)
  Else
 Begin
  ArrayListAddStr:=False;
  Size:=Length(Str)+1;
  If(Size<MinRec)Then Size:=MinRec;
  Ptr:=ArrayListAdd(Q,Size);
  If(Ptr=NIL)Then Exit;
  StrPCopy(PC,Str);
  ArrayListAddStr:=True
 End;
End;

Function ArrayListInsStr(Var Q:ArrayList;P:LongInt;Str:String):Boolean;
Var Ptr:Pointer; PChr:PChar; Size:Word;
Begin
 ArrayListInsStr := False; Size := Length(Str)+1;
 If(Size < 32)Then Size := 32;
 If Not(ArrayListInsBuf(Q,P,Size,Ptr))Then Exit;
 If(Ptr = NIL)Then Exit;
 PChr := Ptr; StrPCopy(PChr,Str); ArrayListInsStr := True;
End;

Function ArrayListInsStrWord(Var Q:ArrayList;P:LongInt;Str:String;Num:Word):Boolean;
Var StrWord:^StrWordRec; Ptr:Pointer; PChr:Array[0..255] of Char;
Begin
 ArrayListInsStrWord := False;
 If Not(ArrayListInsBuf(Q,P,SizeOf(StrWordRec),Ptr))Then Exit;
 StrWord := Ptr; StrPCopy(PChr,Str);
 StrWord^.PChr := StrNew(PChr); StrWord^.Len := Length(Str);
 StrWord^.Nm := Num; ArrayListInsStrWord := True;
End;

Function ArrayListAddPChrWord(Var Q:ArrayList;PChr:PChar;Num:Word):Boolean;
Var PCharWord:^PCharWordRec; Ptr:Pointer;
Begin
 ArrayListAddPChrWord := False;
 If Not(ArrayListAddBuf(Q,SizeOf(PCharWordRec),Ptr))Then Exit;
 PCharWord := Ptr; PCharWord^.PChr := PChr;
 PCHarWord^.Nm := Num; ArrayListAddPChrWord := True;
End;

Function ArrayListGetBuf(Var Q:ArrayList;P:LongInt;Var Size:Word):Pointer;
Var WP:RBufPtr; I:LongInt;
Begin
 Size := 0; ArrayListGetBuf := Nil;
 If(P < 0)or(P >= Q.Count)Then Exit;
 If(P = 0)Then
 Begin
  ArrayListGetBuf := Q.List^.Buf; Size := Q.List^.Size;
 End
  Else
 Begin
  WP := Q.List;
  For I := 1 to P do
  Begin
   If(WP = NIL)Then Exit;
   WP := WP^.Next;
  End;
  If(WP = NIL)Then Exit;
  ArrayListGetBuf := WP^.Buf; Size := WP^.Size;
 End;
End;

Procedure ArrayListPrevious(Var Q:ArrayList);Begin
 If Not(Q.CurrPtr = NIL)Then
 Begin
  Q.CurrPtr := Q.CurrPtr^.Previous;
  Dec(Q.PCurrPtr);
 End;
End;

Procedure ArrayListNext(Var Q:ArrayList);Begin
 If Not(Q.CurrPtr = NIL)Then
 Begin
  Q.CurrPtr := Q.CurrPtr^.Next;
  Inc(Q.PCurrPtr);
 End;
End;

Procedure ArrayListSetPtr(Var Q:ArrayList;P:LongInt);
Var WP:RBufPtr; I:LongInt;
Begin
 If(P = 0)Then
 Begin
  Q.PCurrPtr := 0; Q.CurrPtr := Q.List;
 End
  else
 If Not(Q.PCurrPtr = P)Then
 Begin
  If(Q.PCurrPtr - 1 = P)Then ArrayListPrevious(Q) else
  If(Q.PCurrPtr + 1 = P)Then ArrayListNext(Q)
   else
  Begin
   WP := Q.List;
   If(P > 0)Then For I := 1 to P do
   Begin
    If(WP = NIL)Then Exit;
    WP := WP^.Next;
   End;
   If(WP = NIL)Then Exit;
   Q.PCurrPtr := P;
   Q.CurrPtr  := WP;
  End;
 End;
End;

Function ArrayList_GetCurrBuf(Var Q:ArrayList):Pointer;Begin
 If(Q.CurrPtr = NIL)Then ArrayList_GetCurrBuf := NIL Else ArrayList_GetCurrBuf := Q.CurrPtr^.Buf;
End;

Function ArrayListGetCurrBuf(Var Q:ArrayList;Var Size:Word):Pointer;Begin
 If(Q.CurrPtr = NIL)Then
 Begin
  ArrayListGetCurrBuf := NIL; Size := 0;
 End
  Else
 Begin
  ArrayListGetCurrBuf := Q.CurrPtr^.Buf; Size := Q.CurrPtr^.Size;
 End;
End;

Function ArrayList_GetBuf(Var Q:ArrayList;P:LongInt):Pointer;
Var Size:Word;
Begin
 ArrayList_GetBuf := ArrayListGetBuf(Q,P,Size);
End;

Function ArrayListGetCurrStr(Var Q:ArrayList):String;Begin
 ArrayListGetCurrStr := StrPas(ArrayList_GetCurrBuf(Q));
End;

Function ArrayList_GetStr(Var Q:ArrayList;P:LongInt):String;Begin
 ArrayList_GetStr := StrPas(ArrayList_GetBuf(Q,P));
End;

Function ArrayListRemoveAt(Var Q:ArrayList;P:LongInt):Boolean;
Var WP:RBufPtr; I:LongInt;
Begin
 ArrayListRemoveAt := False;
 If(Q.Count = 0)or(P < 0)or(P >= Q.Count)Then Exit;
 If(P = 0)Then
 Begin
  If(Q.List = NIL)Then Exit;
  WP := Q.List;
  FreeMem(WP^.Buf,WP^.Size);
  FreeMem(WP,SizeOf(WP^));
  If(Q.Count > 1)Then
  Begin
   If(Q.List^.Next = NIL)Then Exit;
   WP^.Next^.Previous := NIL; Q.List := Q.List^.Next; Q.CurrPtr := NIL;
   Q.PCurrPtr := -1; Dec(Q.Count); ArrayListRemoveAt := True;
   Exit;
  End
   else
  Begin
   Q.PCurrPtr := -1; Q.CurrPtr := NIL; Q.List := NIL; Q.EndListPtr := NIL;
   Q.Count := 0; ArrayListRemoveAt := True;
   Exit;
  End;
 End
  else
 Begin
  WP := Q.List;
  For I := 1 to P do
  Begin
   If(WP = NIL)Then Exit;
   WP := WP^.Next;
  End;
  If(WP = NIL)Then Exit;
  If(Q.Count - 1 = P)Then
  Begin
   Q.EndListPtr := WP^.Previous; WP^.Previous^.Next := NIL;
  End
   Else
  Begin
   WP^.Next^.Previous := WP^.Previous; WP^.Previous^.Next := WP^.Next;
  End;
  FreeMem(WP^.Buf,WP^.Size);
  FreeMem(WP,SizeOf(Q.List^));
  Dec(Q.Count);
  ArrayListRemoveAt := True;
 End;
End;

Function ArrayListSetBuf(Var Q:ArrayList;P:LongInt;Size:Word;Var Addr:Pointer):Boolean;
Var WP:RBufPtr; I:LongInt;
Begin
 ArrayListSetBuf := False;
 If(P < 0)or(P > Q.Count)Then Exit;
 If(P = Q.Count)Then
 Begin
  ArrayListSetBuf := ArrayListAddBuf(Q,Size,Addr);
  Exit;
 End;
 If(P = 0)Then
 Begin
  FreeMem(Q.List^.Buf,Q.List^.Size);
  If(Size = 0)Then
  Begin
   Q.List^.Buf := NIL; Q.List^.Size := 0;
  End
   Else
  Begin
   Addr := MemAlloc(Size);
   If(Addr = NIL)Then Exit;
   Q.List^.Buf := Addr; Q.List^.Size := Size;
  End;
  ArrayListSetBuf := True;
  Exit;
 End;
 WP := Q.List;
 For I := 1 to P do
 Begin
  If(WP = NIL)Then Exit;
  WP := WP^.Next;
 End;
 FreeMem(WP^.Buf,WP^.Size);
 If(Size = 0)Then
 Begin
  WP^.Buf := NIL; WP^.Size := 0;
 End
  Else
 Begin
  Addr := MemAlloc(Size);
  If(Addr = NIL)Then Exit;
  WP^.Buf := Addr; WP^.Size := Size;
 End;
 ArrayListSetBuf := True;
End;

Function ArrayList_SetBuf(Var Q:ArrayList;P:LongInt;Size:Word):Pointer;
Var Ptr:Pointer;
Begin
 ArrayList_SetBuf := NIL;
 If Not(ArrayListSetBuf(Q,P,Size,Ptr))Then Exit;
 ArrayList_SetBuf := Ptr;
End;

Function ArrayListCount(Var Q:ArrayList):LongInt;Begin
 ArrayListCount := Q.Count;
End;

Function ArrayListMaxList(Var Q:ArrayList):LongInt;Begin
 ArrayListMaxList := Q.Count - 1;
End;

Procedure ArrayListPopCurrPtr(Var Q:ArrayList;Addr:Pointer);Begin
 Q.CurrPtr:=Addr;
End;

Procedure ArrayListDone(Var Q:ArrayList);
Var WP:RBufPtr; Ptr:^StrByteRec;
Begin
 WP := Q.List;
 While Not(WP = NIL) do
 Begin
  If(WP^.Size = SizeOf(StrByteRec))Then
  Begin
   Ptr := WP^.Buf;
   StrDispose(Ptr^.PChr);
  End;
  FreeMem(WP^.Buf,WP^.Size);
  FreeMem(WP,SizeOf(RBufRec));
  WP := WP^.Next;
 End;
End;

Var
 List:ArrayList;
 I:Integer;
 P:LongInt;
 PX:LongInt;
 X,Y:Byte;
 InsMode,Modified:Boolean;
 CurrPtr:Pointer;
 FileName:String;

Procedure Box(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Window(X1,Y1,X2,Y2);
 TextBackground((Couleur shr 4)and 15);
 {$IFDEF FPC}
  If Couleur and $80=$80 Then Begin
   TextColor((Couleur and 15)+BLINK);
  End
   Else
  TextColor(Couleur and 15);
 {$ELSE}
  TextColor(Couleur and 15);
 {$ENDIF}
 ClrScr;
 Window(1,1,EditNumColumns+2,25);
End;

Procedure FrameEmpty(X1,Y1,X2,Y2,Couleur:Byte);
Var
 I:Byte;
 ChrHori,ChrVert:Char;
 Chr218,Chr192,Chr191,Chr217:Char;
Begin
 TextBackground((Couleur shr 4)and 15);
 TextColor(Couleur and 15);
 If(ShowASCII128)Then Begin
  ChrHori:='-';
  ChrVert:='|';
  Chr218:='+';
  Chr192:='+';
  Chr191:='+';
  Chr217:='+';
 End
  Else
 Begin
  ChrHori:=#$C4;
  ChrVert:=#$B3;
  Chr218:=#218;
  Chr192:=#192;
  Chr191:=#191;
  Chr217:=#217;
 End;
 For I:=Y1+1 to Y2-1 do Begin
  GotoXY(X1,I);
  Write(ChrVert);
  GotoXY(X2,I);
  Write(ChrVert);
 End;
 GotoXY(X1+1,Y1);
 Write(DuplicateString(ChrHori,X2-X1-1));
 GotoXY(X1+1,Y2);
 Write(DuplicateString(ChrHori,X2-X1-1));
 GotoXY(X1,Y1);
 Write(Chr218);
 GotoXY(X1,Y2);
 Write(Chr192);
 GotoXY(X2,Y1);
 Write(Chr191);
 GotoxY(X2,Y2);
 Write(Chr217);
End;

Procedure LoadText(FileName:String);
Var
 TextFile:Text;
 CurrLine:String;
Begin
 {$I-}Assign(TextFile,FileName);
 Reset(TextFile);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Le fichier ',FileName,' est introuvable !');
  Halt;
 End;
 While Not EOF(TextFile) do Begin
  ReadLn(TextFile,CurrLine);
  ArrayListAddStr(List,CurrLine);
 End;
 Close(TextFile);
End;

Procedure ColorEditor;Begin
 TextBackground(0);
 TextColor(7);
End;

Procedure SaveText(FileName:String);
Var
 TextFile:Text;
 CurrLine:String;
 I:Integer;
Begin
 Assign(TextFile,FileName);
 Rewrite(TextFile);
 If Not ArrayListIsEmpty(List)Then Begin
  ArrayListSetPtr(List,0);
  For I:=1 to ArrayListCount(List)do Begin
   CurrLine:=ArrayListGetCurrStr(List);
   WriteLn(TextFile,CurrLine);
   ArrayListNext(List);
  End;
 End;
 Close(TextFile);
 Modified:=False;
 If Not(Modified)Then Begin
  TextColor(7);
  TextBackground(0);
  GotoXY(3,2);
  Write(' ');
  ColorEditor;
 End;
 ArrayListSetPtr(List,P);
End;

Function TEPopCurr:PChar;Begin
 ArrayListPopCurrPtr(List,CurrPtr);
 TEPopCurr:=ArrayList_GetCurrBuf(List)
End;

Procedure TEPutPos;Begin
 TextColor(0);
 TextBackground(7);
 GotoXY(40,25);
 Case Language of
  _English:Write('| Column : ',(PX+1):6);
  Else Write('| Colonne : ',(PX+1):6);
 End;
 GotoXY(60,25);
 Case Language of
  _English:Write('Line : ',(P+1):6);
  Else Write('Line : ',(P+1):6);
 End;
 ColorEditor;
 GotoXY(EditX+X,EditY+Y);
End;

Procedure RefreshEditor;
Var
 I:Byte;
 CurrLine:String;
Begin
 ColorEditor;
 ArrayListSetPtr(List,P-Y);
 For I:=0 to EditNumLines-1 do Begin
  GotoXY(EditX,EditY+I);
  If I>ArrayListCount(List)Then Write(' ':EditNumColumns)
   Else
  Begin
   CurrLine:=ArrayListGetCurrStr(List);
   Write(PadRight(Copy(CurrLine,1,EditNumColumns),EditNumColumns));
   ArrayListNext(List);
  End;
 End;
 ArrayListSetPtr(List,P);
End;

Procedure SetColorSelect;Begin
 TextColor(15);
 TextBackground(0);
End;

Procedure SetColorUnSelect;Begin
 TextColor(0);
 TextBackground(7);
End;

Procedure ShowMenu;
Var
 I:Byte;
Begin
 Box(1,1,80,1,$70);
 GotoXY(4,1);
 For I:=0 to High(MainMenu) do Begin
  If(OnMenu)Then Begin
   If I+1=XMenu Then SetColorSelect
                Else SetColorUnSelect;
  End;
  Case Language of
   _English:Write(' ',MainMenuEnglish[I],' ');
   _Germany:Write(' ',MainMenuGermany[I],' ');
   Else Write(' ',MainMenu[I],' ');
  End;
 End;
End;

Procedure SubMenuItem(Y:Integer;Disable:Boolean);Begin
 If(Disable)Then SetColorUnSelect Else
 If Y=YMenu Then SetColorSelect
            Else SetColorUnSelect;
 Case XMenu of
  1:Begin
   GotoXY(5,3+Y);
   If SubMenuFile[Y]=''Then Write(DuplicateString('-',25+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuFileEnglish[Y],25));
    _Germany:Write(' ',PadRight(SubMenuFileGermany[Y],25));
    Else Write(' ',PadRight(SubMenuFile[Y],25));
   End;
  End;
  2:Begin
   Case Language of
    _English:Begin
     GotoXY(11,3+Y);
     Write(' ',PadRight(SubMenuEditEnglish[Y],28));
    End;
    _Germany:Begin
     GotoXY(12,3+Y);
     Write(' ',PadRight(SubMenuEditGermany[Y],28));
    End;
    Else Begin
     GotoXY(14,3+Y);
     Write(' ',PadRight(SubMenuEdit[Y],28))
    End;
   End;
  End;
  3:Begin
   Case Language of
    _English:Begin
     GotoXY(17,3+Y);
     Write(' ',PadRight(SubMenuSearchEnglish[Y],29));
    End;
    _Germany:Begin
     GotoXY(24,3+Y);
     Write(' ',PadRight(SubMenuSearchGermany[Y],29));
    End;
    Else Begin
     GotoXY(23,3+Y);
     Write(' ',PadRight(SubMenuSearch[Y],29));
    End;
   End;
  End;
  4:Begin
   Case Language of
    _English:Begin
     GotoXY(25,3+Y);
     Write(' ',PadRight(SubMenuViewEnglish[Y],22));
    End;
    _Germany:Begin
     GotoXY(33,3+Y);
     Write(' ',PadRight(SubMenuView[Y],22));
    End;
    Else Begin
     GotoXY(34,3+Y);
     Write(' ',PadRight(SubMenuView[Y],22));
    End;
   End;
  End;
  5:Begin
   Case Language of
    _English:Begin
     GotoXY(31,3+Y);
     Write(' ',PadRight(SubMenuOptionsEnglish[Y],15));
    End;
    _Germany:Begin
     GotoXY(43,3+Y);
     Write(' ',PadRight(SubMenuOptionsGermany[Y],20));
    End;
    Else Begin
     GotoXY(39,3+Y);
     Write(' ',PadRight(SubMenuOptions[Y],15));
    End;
   End;
  End;
  6:Begin
   Case Language of
    _English:Begin
     GotoXY(40,3+Y);
     Write(' ',PadRight(SubMenuHelpEnglish[Y],14));
    End;
    _Germany:Begin
     GotoXY(53,3+Y);
     Write(' ',PadRight(SubMenuHelp[Y],14));
    End;
    Else Begin
     GotoXY(48,3+Y);
     Write(' ',PadRight(SubMenuHelp[Y],14));
    End;
   End;
  End;
 End;
End;

Procedure ShowSubMenu;
Var
 I:Integer;
Begin
 Case XMenu of
  1:Begin
   FrameEmpty(4,2,31,4+High(SubMenuFile),$70);
   For I:=Low(SubMenuFile)to High(SubMenuFile)do Begin
    SubMenuItem(I,False);
   End;
  End;
  2:Begin
   Case Language of
    _English:FrameEmpty(10,2,40,4+High(SubMenuEdit),$70);
    _Germany:FrameEmpty(11,2,41,4+High(SubMenuEdit),$70);
    Else FrameEmpty(13,2,43,4+High(SubMenuEdit),$70);
   End;
   For I:=Low(SubMenuEdit)to High(SubMenuEdit)do Begin
    SubMenuItem(I,False);
   End;
  End;
  3:Begin
   Case Language of
    _English: FrameEmpty(16,2,47,4+High(SubMenuSearch),$70);
    _Germany: FrameEmpty(23,2,54,4+High(SubMenuSearch),$70);
    Else FrameEmpty(22,2,53,4+High(SubMenuSearch),$70);
   End;
   For I:=Low(SubMenuSearch)to High(SubMenuSearch)do Begin
    SubMenuItem(I,False);
   End;
  End;
  4:Begin
   Case Language of
    _English: FrameEmpty(24,2,48,4+High(SubMenuView),$70);
    _Germany: FrameEmpty(32,2,56,4+High(SubMenuView),$70);
    Else FrameEmpty(33,2,57,4+High(SubMenuView),$70);
   End;
   For I:=Low(SubMenuView)to High(SubMenuView)do Begin
    SubMenuItem(I,False);
   End;
  End;
  5:Begin
   Case Language of
    _English: FrameEmpty(30,2,47,4+High(SubMenuOptions),$70);
    _Germany: FrameEmpty(42,2,64,4+High(SubMenuOptions),$70);
    Else FrameEmpty(38,2,55,4+High(SubMenuOptions),$70);
   End;
   For I:=Low(SubMenuOptions)to High(SubMenuOptions)do Begin
    SubMenuItem(I,False);
   End;
  End;
  6:Begin
   Case Language of
    _English:FrameEmpty(39,2,55,4+High(SubMenuHelp),$70);
    _Germany:FrameEmpty(52,2,68,4+High(SubMenuHelp),$70);
    Else FrameEmpty(47,2,63,4+High(SubMenuHelp),$70);
   End;
   For I:=Low(SubMenuHelp)to High(SubMenuHelp)do Begin
    SubMenuItem(I,False);
   End;
  End;
 End;
End;

Procedure ShowEditor;
Var
 I:Byte;
 CurrLine:String;
Begin
 TextBackground(0);
 TextColor(7);
 ClrScr;
 ShowMenu;
 TextBackground(0);
 TextColor(7);
 GotoXY(1,2);
 Write('|',DuplicateString('-',EditNumColumns),'|');
 ArrayListSetPtr(List,0);
 TextColor(0);
 TextBackground(7);
 If FileName=''Then Begin
  Case Language of
   _English:CurrLine:='UNTITLE1';
   Else CurrLine:='SANSNOM1'
  End;
 End
  Else
 CurrLine:=' '+FileName+' ';
 GotoXY(((80-Length(CurrLine)) shr 1),2);
 Write(CurrLine);
 GotoXY(1,25);
 ClrEol;
 GotoXY(18,25);
 Write('Mode : ');
 If(InsMode)Then Begin
  Case Language of
   _English:Write('Insert');
   Else Write('Insertion');
  End;
 End
  Else
 Begin
  Case Language of
   _English:Write('Overwrite');
   Else Write('Ecrasement');
  End;
 End;
 TextBackground(0);
 TextColor(7);
 For I:=0 to EditNumLines-1 do Begin
  GotoXY(EditX-1,EditY+I);
  Write('|');
  If I>ArrayListCount(List)Then ClrEol
   Else
  Begin
   CurrLine:=ArrayListGetCurrStr(List);
   Write(Copy(CurrLine,1,EditNumColumns));
   ArrayListNext(List);
  End;
  GotoXY(EditX+EditNumColumns,EditY+I);
  Write('|');
 End;
 ArrayListSetPtr(List,P);
 TEPutPos;
End;

Procedure HideSubMenu;Begin
 ShowEditor;
End;

Procedure NotImplemented;Begin
 Box(5,11,75,13,$60);
 FrameEmpty(5,11,75,13,$60);
 GotoXY(20,12);
 Write('Cette fonctionnalite n''est pas implemented');
 ReadKey;
 ShowEditor;
End;

Procedure ShowModified;Begin
 TextColor(7);
 TextBackground(0);
 GotoXY(3,2);
 Write('*');
 ColorEditor;
End;

Procedure InsertLetter(C:Char);
Var
 Ptr:PChar;
 CurrLine:String;
Begin
 If Not(Modified)Then ShowModified;
 Modified:=True;
 If P>=ArrayListCount(List)Then Begin
  CurrLine:=PadRight('',PX)+C;
  ArrayListAddStr(List,CurrLine);
  ArrayListSetPtr(List,P);
 End
  Else
 Begin
  ArrayListSetPtr(List,P);
  CurrLine:=ArrayListGetCurrStr(List);
  If PX>Length(CurrLine)Then CurrLine:=PadRight(CurrLine,PX);
  Insert(C,CurrLine,PX+1);
  Ptr:=ArrayList_SetBuf(List,P,Length(CurrLine)+1);
  StrPCopy(Ptr,CurrLine);
 End;
 GotoXY(EditX,EditY+Y);
 Write(Copy(CurrLine,1,EditNumColumns));
 Inc(PX);
 Inc(X);
End;

Procedure DeleteLetter;
Var
 Ptr:PChar;
 CurrLine:String;
Begin
 If Not(Modified)Then ShowModified;
 Modified:=True;
 If P>=ArrayListCount(List)Then Begin
  CurrLine:='';
  ArrayListAddStr(List,CurrLine);
  ArrayListSetPtr(List,P);
 End
  Else
 Begin
  ArrayListSetPtr(List,P);
  CurrLine:=ArrayListGetCurrStr(List);
  If PX>Length(CurrLine)Then CurrLine:=PadRight(CurrLine,PX);
  Delete(CurrLine,PX+1,1);
  Ptr:=ArrayList_SetBuf(List,P,Length(CurrLine)+1);
  StrPCopy(Ptr,CurrLine);
 End;
 GotoXY(EditX,EditY+Y);
 Write(PadRight(Copy(CurrLine,1,EditNumColumns),EditNumColumns));
End;

Procedure BackSpaceLetter;
Var
 Ptr:PChar;
 CurrLine:String;
Begin
 If Not(Modified)Then ShowModified;
 Modified:=True;
 If P>=ArrayListCount(List)Then Begin
  CurrLine:='';
  ArrayListAddStr(List,CurrLine);
  ArrayListSetPtr(List,P);
 End
  Else
 Begin
  ArrayListSetPtr(List,P);
  CurrLine:=ArrayListGetCurrStr(List);
  If PX>Length(CurrLine)Then CurrLine:=PadRight(CurrLine,PX);
  Delete(CurrLine,PX,1);
  Ptr:=ArrayList_SetBuf(List,P,Length(CurrLine)+1);
  StrPCopy(Ptr,CurrLine);
 End;
 GotoXY(EditX,EditY+Y);
 Write(PadRight(Copy(CurrLine,1,EditNumColumns),EditNumColumns));
 If PX>0Then Dec(PX);
 If X>0Then Dec(X);
End;

Procedure KeyDown;
Var
 CurrLine:String;
Begin
 If P<ArrayListMaxList(List)Then Begin { Bas }
  Inc(P);
  ArrayListNext(List);
  If Y<EditNumLines-1 Then Inc(Y)
   Else
  Begin
   Window(EditX,EditY,EditX+EditNumColumns-1,EditY+EditNumLines-1);
   DelLine;
   Window(1,1,EditNumColumns+2,25);
   GotoXY(EditX,EditY+EditNumLines-1);
   CurrLine:=ArrayListGetCurrStr(List);
   Write(Copy(CurrLine,1,EditNumColumns));
  End;
 End;
End;

Procedure AboutBox;Begin
 Box(20,9,60,9,$F0);
 GotoXY(32,9);
 Write('A propos de EDIT');
 Box(20,10,60,16,$70);
 GotoXY(30,11);
 Write('PC-DOS Editor Clone');
 GotoXY(32,12);
 Write('Version 0.0.026');
 GotoXY(31,13);
 Write('Licence MIT 2022');
 GotoXY(37,15);
 {$IFDEF FPC}
  TextColor(0+BLINK);
 {$ENDIF}
 Write('> OK <');
 ReadKey;
 ShowEditor;
End;

Procedure KbdEnter;Begin
 If P>=ArrayListMaxList(List)Then Begin
  ArrayListAddStr(List,'');
  Inc(P);
  If Y<EditNumLines-1 Then Inc(Y);
  RefreshEditor;
 End
  Else
 KeyDown;
End;

Procedure RunEditor;
Var
 PC:PChar;
 L:Word;
 K:Char;
 Terminated:Boolean;
 CurrLine:String;
Begin
 Terminated:=False;
 Repeat
  TEPutPos;
  K:=ReadKey;
  If(OnMenu)Then Case K of
   #0:Case ReadKey of
     #72:Begin { Up }
      SubMenuItem(YMenu,True);
      If YMenu>0Then Dec(YMenu)
                Else YMenu:=YMenuMax[XMenu];
      If XMenu=1 Then Begin
       If YMenu in[5,7]Then Dec(YMenu);
      End;
      SubMenuItem(YMenu,False);
     End;
     #75:Begin { Gauche }
     HideSubMenu;
     If XMenu>1 Then Dec(XMenu)
                Else XMenu:=High(MainMenu)+1;
     YMenu:=0;
     ShowMenu;
     ShowSubMenu;
    End;
    #77:Begin { Droite }
     HideSubMenu;
     If XMenu<=High(MainMenu)Then Inc(XMenu)
                             Else XMenu:=1;
     YMenu:=0;
     ShowMenu;
     ShowSubMenu;
    End;
    #80:Begin { Down }
     SubMenuItem(YMenu,True);
     If YMenu<YMenuMax[XMenu]Then Inc(YMenu)
                             Else YMenu:=0;
     If XMenu=1 Then Begin
       If YMenu in[5,7]Then Inc(YMenu);
      End;
     SubMenuItem(YMenu,False);
    End;
   End;
   #13:Begin
    OnMenu:=False;
    HideSubMenu;
    Case XMenu of
     1:Case YMenu of
      2:SaveText(FileName);
      8:Terminated:=True;
      Else NotImplemented;
     End;
     6:Case YMenu of
      1:AboutBox;
      Else NotImplemented;
     End;
     Else NotImplemented;
    End;
   End;
   #27:Begin
    OnMenu:=False;
    HideSubMenu;
   End;
  End
   Else
  Case K of
   #0:Case ReadKey of
    #18:Begin { Alt+E }
     XMenu:=2;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #19:Begin { Alt+R }
     XMenu:=3;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #24:Begin { Alt+O }
     XMenu:=5;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #30:Begin { Alt+A }
     XMenu:=6;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #32:If Language=_Germany Then Begin { Alt+D }
     XMenu:=1;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #31:Begin { Alt+S }
     XMenu:=3;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #33:Begin { Alt+F }
     XMenu:=1;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #35:Begin { Alt+H }
     XMenu:=6;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #47:Begin { Alt+V }
     XMenu:=4;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    'K':Begin { Gauche }
     If PX>0Then Begin
      Dec(PX);
      If X>0Then Dec(X);
      TEPutPos;
     End;
    End;
    'M':Begin { Droite }
     If PX<255{65520}Then Begin
      Inc(PX);
      If X<MaxX Then Inc(X);
      TEPutPos;
     End;
    End;
    'H':If P>0Then Begin { Haut }
      ArrayListSetPtr(List,P);
      Dec(P);
      ArrayListPrevious(List);
      If Y>0Then Dec(Y)
       Else
      Begin
       Window(EditX,EditY,EditX+EditNumColumns-1,EditY+EditNumLines-1);
       InsLine;
       Window(1,1,EditNumColumns+2,25);
       GotoXY(EditX,EditY);
       CurrLine:=ArrayListGetCurrStr(List);
       Write(Copy(CurrLine,1,EditNumColumns));
      End;
     End;
    'P':KeyDown; { Bas }
    #83:DeleteLetter;
   End;
   #8:BackSpaceLetter;
   #13:KbdEnter;
   #27:Terminated:=True;
   Else If(InsMode)Then InsertLetter(K);
 End;
 Until Terminated;
End;

Procedure DoneEditor;Begin
 ArrayListDone(List);
 TextBackground(0);
 TextColor(7);
 ClrScr;
End;

{$IFDEF FPC}
 Procedure SetVideoMode132;Begin
  WriteLn('Non impl�ment� en Free Pascal');
  Halt;
 End;
{$ELSE}
 Procedure SetVideoMode132;
 Const
  VESA_GET_INFO=$4F00;
  VESA_SET_MODE=$4F02;
  VESA_TEXT_132=$0109;  { Mode VESA texte 132x25 }
 Type
  TVESAInfo=Record
   Signature:Array[1..4] of Char;  { 'VESA' }
   Version:Word;
   OemString:Pointer;
   Capabilities:Array[1..4] of Byte;
   VideoModes:Pointer;
   MemorySize:Word;
   Reserved:Array[1..236] of Byte;
  End;
 Var
  Regs:Registers;
  VESAInfo:TVESAInfo;
 Begin
   { V�rifie si VESA est disponible }
  FillChar(Regs,SizeOf(Regs),0);
  FillChar(VESAInfo,SizeOf(VESAInfo),0);
  VESAInfo.Signature:='VESA';
  Regs.AX:=VESA_GET_INFO;
  Regs.ES:=Seg(VESAInfo);
  Regs.DI:=Ofs(VESAInfo);
  Intr($10,Regs);
  If(Regs.AH=0)and(VESAInfo.Signature='VESA')Then Begin
    { Active le mode 132 colonnes }
   Regs.AX:=VESA_SET_MODE;
   Regs.BX:=VESA_TEXT_132;
   Intr($10,Regs);
   If Regs.AH=0 Then Begin
    WindMax:=131;  { 132 colonnes - 1 }
    LastMode:=3;   { Mode texte }
   End
    Else
   Begin
    WriteLn('Erreur: Mode 132 colonnes non support�');
    Halt;
   End;
  End
   Else
  Begin
   WriteLn('Erreur: VESA non support�');
   Halt;
  End;
 End;

{$ENDIF}

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Startet den MS-DOS-Editor, der ASCII-Dateien erzeugt und ver�ndert.');
    WriteLn;
    WriteLn('E [[Laufwerk:][Pfad[Dateiname]]')
   End;
   Else Begin
    WriteLn('E : Cette commande permet d''�diter un fichier texte ASCII.');
    WriteLn;
    WriteLn('Syntaxe : E nomdufichier');
    WriteLn;
    WriteLn(' /132       Permet d''utiliser un affichage de 132 colonnes');
    WriteLn(' /ASCII128  Permet d''utiliser des codes ASCII de 7 bits');
   End;
  End;
 End
  Else
 Begin
  OnMenu:=False;
  YMenu:=0;XMenu:=1;
  ShowASCII128:=False;
  Use132Column:=False;
  Modified:=False;
  InsMode:=True;
  P:=0;PX:=0;
  X:=0;Y:=0;
  FileName:='';
  EditNumColumns:=78;
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/ASCII128'Then ShowASCII128:=True Else
   If ParamStr(I)='/132'Then Begin
    Use132Column:=True;
    SetVideoMode132;
    Window(1,1,132,25);
    EditNumColumns:=130;
   End
    Else
   FileName:=ParamStr(I);
  End;
  MaxX:=EditNumColumns-1;
  ArrayListInit(List);
  If FileName<>''Then LoadText(FileName);
  ShowEditor;
  RunEditor;
  DoneEditor;
 End;
END.
