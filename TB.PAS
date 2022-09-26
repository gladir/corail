{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program TB;

Uses Crt,DOS,Strings,Printer;

Const
 EditX=2;
 EditY=6;
 EditNumColumns=68;
 EditNumLines=11;
 MaxX=EditNumColumns-1;

 MainMenu:Array[0..7]of String[12]=(
  'Fichier','Editer','Execute','Compile',
  'Options','Ajustement','Fenetre','Debogue'
 );

 MainMenuEnglish:Array[0..7]of String[12]=(
  'File','Edit','Run','Compile',
  'Options','Setup','Window','Debug'
 );

 SubMenuFile:Array[0..8]of String[20]=(
  'Chargement',
  'Nouveau fichier',
  'Sauvegarde',
  'Enregistrement sous',
  'Fichier principal',
  'Liste des fichiers',
  'Repertoire actif',
  'Interpreteur DOS',
  'Quitter'
 );

 SubMenuFileEnglish:Array[0..8]of String[20]=(
  'Load',
  'New',
  'Save',
  'Write to',
  'Main file',
  'Directory',
  'Change dir',
  'OS shell',
  'Quit'
 );

 SubMenuOptions:Array[0..9]of String[25]=(
  'Compilation vers memoire',
  '',
  '8087 utilise - NON',
  'Arret au clavier - NON',
  'Limites tableau - NON',
  'Depassement - NON',
  'Test de la pile - NON',
  '',
  'Parametres ligne',
  'Meta-instructions'
 );

 SubMenuOptionsEnglish:Array[0..9]of String[25]=(
  'Compile to Memory',
  '',
  '8087 required - OFF',
  'Keyboard break - OFF',
  'Bounds - OFF',
  'Overflow - OFF',
  'Stack test - OFF',
  '',
  'Parameter line',
  'Metastatements'
 );

 SubMenuSetup:Array[0..4]of String[30]=(
  'Couleurs',
  'Repertoires',
  'Divers',
  'Lecture configuration',
  'Sauvegarde configuration'
 );

 SubMenuSetupEnglish:Array[0..4]of String[30]=(
  'Colors',
  'Directories',
  'Miscellaneous',
  'Load Option/Window/Setup',
  'Save Option/Window/Setup'
 );

 SubMenuWindow:Array[0..6]of String[15]=(
  'Ouverture',
  'Fermeture',
  'Suivante',
  'Destination',
  'Quadrillage',
  'File',
  'Agrandissement'
 );

 SubMenuWindowEnglish:Array[0..6]of String[15]=(
  'Open',
  'Close',
  'Next',
  'Goto',
  'Tile',
  'Stack',
  'Zoom'
 );

 SubMenuDebug:Array[0..1]of String[20]=(
  'Trace - NON',
  'Erreur d''execution'
 );

 SubMenuDebugEnglish:Array[0..1]of String[20]=(
  'Trace - OFF',
  'Run-time error'
 );

 YMenuMax:Array[1..8]of Byte=(
  High(SubMenuFile),0,0,0,
  High(SubMenuOptions),High(SubMenuSetup),
  High(SubMenuWindow),High(SubMenuDebug)
 );

 CommandList:Array[0..91]of String[12]=(
  'AND','AUTO','BEEP','BLOAD','BSAVE','CALL','CAT','CHAIN','CHDIR',
  'CIRCLE','CLEAR','CLOSE','CLR','CLS','COLOR','COM','COMMON','CONT',
  'DATA','DEF','DELETE','DIM','DRAW','EDIT','ELSE','END','ERASE','ERROR',
  'FIELD','FILES','FOR','GET','GOSUB','GOTO','HELP','IF','INPUT','KEY',
  'KILL','LET','LINE','LIST','LLIST','LOAD','LOCATE','LPRINT',
  'LSET','MERGE','MKDIR','NAME','NEW','NEXT','ON','OPEN','OPTION',
  'OR','OUT','PAINT','PALETTE','POKE','PLAY','PRESET','PRINT',
  'PSET','PUT','RANDOMIZE','READ','REM','RENUM','RESET','RESUME',
  'RESTORE','RETURN','RMDIR','RSET','RUN','SAVE','SCREEN','SHELL','SLEEP',
  'STOP','SYSTEM','THEN','TROFF','TRON','VIEW','WAIT','WEND','WHILE',
  'WIDTH','WINDOW','WRITE'
 );

 FunctionList:Array[0..53]of String[12]=(
  'ABS','ASC','ATN','CHR$','CINT','CSNG','CSRLIN','COS','CVD','CVI',
  'CVS','DATE$','EOF','ERL','ERR','EXP','FIX','FRE','INKEY$','INP',
  'INPUT$','INSTR','INT','LEFT$','LEN','LOF','LOG','LPOS','LTRIM$',
  'MID$','OCT$','PEEK','PLAY','PMAP','POS','RIGHT$','RND','RTRIM$',
  'SCREEN','SGN','SIN','SQR','STR$','STRIG','STRING$','TAN','TAB',
  'TIME$','TIMER','TRIM$','USR','VAL','VARPTR','VARPTR$'
 );

 MaxLine=1024;
 MaxVariable=100;

Type
 VarTypeEnum=(_None,_Integer,_LongInt,_Real,_String);
 StrPointer=^String;
 VarRec=Record
  Variant:Record Case Integer of
   0:(I:Integer);
   1:(L:LongInt);
   2:(R:Real);
   3:(S:StrPointer);
  End;
  VarType:VarTypeEnum;
  VarName:String[20];
 End;
 VarPointer=^VarRec;
 GosubStackRec=Record
  Line,Col:Word;
  LineNumber:Integer;
 End;
 ForStackRec=Record
  Line,Col:Word;
  LineNumber:Integer;
  VarName:String[20];
 End;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 ShowASCII128:Boolean;
 YMenu,XMenu:Integer;
 OnMenu,Terminated,Tron,KeyFunction:Boolean;
 CurrCommand:String;
 FileName,CurrLine:String;
 CurrPos:Byte;
 CurrLinePtr:Integer;
 CurrNumberLine:Integer;
 VarList:Array[1..MaxVariable]of VarPointer;
 I,NumberVariable:Integer;
 FunctionKeyList:Array[1..10]of String[15];
 GosubStack:Array[1..10]of GosubStackRec;
 GosubPos:Byte;
 ForStack:Array[1..10]of ForStackRec;
 ForPos:Byte;

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

 StrWordRec=Record
  PChr:PChar;
  Nm,Len:Word;
 End;

 PCharWordRec=Record
  PChr:PChar;
  Nm:Word;
 End;

 RBufPtr=^RBufRec;

 RBufRec=Record
  Buf:Pointer;
  Size:Word;
  Previous,Next:RBufPtr;
 End;

 ArrayList=Record
  PCurrPtr,Count:LongInt;
  CurrPtr,List,EndListPtr:RBufPtr;
 End;

Var
 List:ArrayList;
 P:LongInt;
 PX:LongInt;
 X,Y:Byte;
 InsMode,Modified:Boolean;
 CurrPtr:Pointer;

Const
 MinRec=SizeOf(PCharWordRec)+1;

Procedure RunCommand;Forward;
Function RunBasic(InList:Boolean):Boolean;Forward;

Function MaxAvail:LongInt;Begin
 MaxAvail:=High(LongInt);
End;

Procedure SetOutputWindow;Begin
 Window(42,19,69,23);
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

Function RTrim(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 RTrim:=S;
End;

Function LTrim(S:String):String;
Var
 I:Integer;
Begin
 I:=1;
 While(I<=Length(s)) and (S[I] in [#9,' ']) do Inc(I);
 Delete(S,1,I-1);
 LTrim:=S;
End;

Function Trim(S:String):String;Begin
 Trim:=LTrim(RTrim(S));
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

Procedure Box(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Window(X1,Y1,X2,Y2);
 TextBackground((Couleur shr 4)and 15);
 TextColor(Couleur and 15);
 ClrScr;
 Window(1,1,80,25);
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

Procedure ShowFunctionsKey;
Const
 KeyMenuList:Array[0..5]of String[6]=(
  'F1','F5','F6','F7','SCROLL','Alt+X'
 );
 KeyMenuMessage:Array[0..5]of String[20]=(
  'Aide','Agran.','Prochain','Aller a','Taille/De.','Quitter'
 );
 KeyMenuMessageEnglish:Array[0..5]of String[20]=(
  'Help','Zoom','Next','Goto','Size/move','Exit'
 );
 KeyEditList:Array[0..4]of String[6]=(
  'F1','F2','F3','F5','F6'
 );
 KeyEditMessage:Array[0..4]of String[20]=(
  'Aide','Sauve','Nouveau','Agrandis','Prochain'
 );
 KeyEditMessageEnglish:Array[0..4]of String[20]=(
  'Help','Save','New','Zoom','Next'
 );
Var
 I:Byte;
Begin
 TextBackground(1);
 GotoXY(1,25);
 ClrEol;
 If(OnMenu)Then Begin
  For I:=0 to 5 do Begin
   TextColor($B);
   Write(' ',KeyMenuList[I]);
   TextColor($E);
   Case Language of
    _English:Write('-',KeyMenuMessageEnglish[I],' ');
    Else Write('-',KeyMenuMessage[I],' ');
   End;
  End;
 End
  Else
 Begin
  For I:=0 to 4 do Begin
   TextColor($B);
   Write(' ',KeyEditList[I]);
   TextColor($E);
   Case Language of
    _English:Write('-',KeyEditMessageEnglish[I],' ');
    Else Write('-',KeyEditMessage[I],' ');
   End;
  End;
 End;
 TextBackground(0);
 TextColor($B);
End;

Procedure SetColorSelect;Begin
 TextColor($E);
 TextBackground($5);
End;

Procedure SetColorUnSelect;Begin
 TextColor(14);
 TextBackground(1);
End;

Procedure UpdateMenu;
Var
 I:Integer;
Begin
 GotoXY(4,2);
 For I:=Low(MainMenu) to High(MainMenu)do Begin
   If(I+1=XMenu)and(OnMenu)Then SetColorSelect
                           Else SetColorUnSelect;
  Case Language of
   _English: Write(' ',MainMenuEnglish[I],' ');
   Else Write(' ',MainMenu[I],' ');
  End;
 End;
End;

Procedure ShowMenu;Begin
 Box(1,1,80,3,$17);
 FrameEmpty(1,1,80,3,$17);
 TextColor($F);
 GotoXY(35,1);
 Write(' Turbo Basic ');
 UpdateMenu;
End;

Procedure SubMenuItem(Y:Integer;Disable:Boolean);Begin
 If(Disable)Then SetColorUnSelect Else
 If Y=YMenu Then SetColorSelect
            Else SetColorUnSelect;
 Case XMenu of
  1:Begin
   GotoXY(5,5+Y);
   Case Language of
    _English:Write(' ',PadRight(SubMenuFileEnglish[Y],26));
    Else Write(' ',PadRight(SubMenuFile[Y],26));
   End;
  End;
  5:Begin
   Case Language of
    _English:GotoXY(31,5+Y);
    Else GotoXY(40,5+Y);
   End;
   If SubMenuOptions[Y]=''Then Write(DuplicateString('-',33+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuOptionsEnglish[Y],33));
    Else Write(' ',PadRight(SubMenuOptions[Y],33));
   End;
  End;
  6:Begin
   Case Language of
    _English:GotoXY(40,5+Y);
    Else GotoXY(49,5+Y);
   End;
   Case Language of
    _English:Write(' ',PadRight(SubMenuSetupEnglish[Y],25));
    Else Write(' ',PadRight(SubMenuSetup[Y],25));
   End;
  End;
  7:Begin
   Case Language of
    _English:GotoXY(47,5+Y);
    Else GotoXY(61,5+Y);
   End;
   Case Language of
    _English:Write(' ',PadRight(SubMenuWindowEnglish[Y],16));
    Else Write(' ',PadRight(SubMenuWindow[Y],16));
   End;
  End;
  8:Begin
   GotoXY(37,5+Y);
   Case Language of
    _English:Write(' ',PadRight(SubMenuDebugEnglish[Y],37));
    Else Write(' ',PadRight(SubMenuDebug[Y],37));
   End;
  End;
 End;
End;

Procedure ShowSubMenu;
Var
 I:Integer;
Begin
 ShowFunctionsKey;
 Case XMenu of
  1:Begin
   FrameEmpty(4,4,32,6+High(SubMenuFile),$1E);
   For I:=Low(SubMenuFile)to High(SubMenuFile)do Begin
    SubMenuItem(I,False);
   End;
  End;
  5:Begin
   Case Language of
    _English: FrameEmpty(30,4,65,6+High(SubMenuOptions),$1E);
    Else FrameEmpty(39,4,74,6+High(SubMenuOptions),$1E);
   End;
   For I:=Low(SubMenuOptions)to High(SubMenuOptions)do Begin
    SubMenuItem(I,False);
   End;
  End;
  6:Begin
   Case Language of
    _English:FrameEmpty(39,4,66,6+High(SubMenuSetup),$1E);
    Else FrameEmpty(48,4,75,6+High(SubMenuSetup),$1E);
   End;
   For I:=Low(SubMenuSetup)to High(SubMenuSetup)do Begin
    SubMenuItem(I,False);
   End;
  End;
  7:Begin
   Case Language of
    _English:FrameEmpty(46,4,64,6+High(SubMenuWindow),$1E);
    Else FrameEmpty(60,4,78,6+High(SubMenuWindow),$1E);
   End;
   For I:=Low(SubMenuWindow)to High(SubMenuWindow)do Begin
    SubMenuItem(I,False);
   End;
  End;
  8:Begin
   FrameEmpty(36,4,75,6+High(SubMenuDebug),$1E);
   For I:=Low(SubMenuDebug)to High(SubMenuDebug)do Begin
    SubMenuItem(I,False);
   End;
  End;
 End;
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

Procedure LoadText(FileName:String);
Var
 TextFile:Text;
 CurrLine:String;
Begin
 Assign(TextFile,FileName);
 Reset(TextFile);
 While Not EOF(TextFile) do Begin
  ReadLn(TextFile,CurrLine);
  ArrayListAddStr(List,CurrLine);
 End;
 Close(TextFile);
End;

Procedure ColorEditor;Begin
 TextBackground(0);
 TextColor($E);
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
  TextColor(1);
  TextBackground(0);
  GotoXY(40,5);
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
 TextColor(7);
 TextBackground(0);
 GotoXY(20,5);
 Write('Ligne ',(P+1),' ');
 GotoXY(35,5);
 Write('Col ',(PX+1),' ');
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
  If I>ArrayListCount(List)Then ClrEol
   Else
  Begin
   CurrLine:=ArrayListGetCurrStr(List);
   Write(PadRight(Copy(CurrLine,1,EditNumColumns),EditNumColumns));
   ArrayListNext(List);
  End;
 End;
 ArrayListSetPtr(List,P);
End;

Procedure ShowEditor;
Var
 I:Byte;
 CurrLine:String;
Begin
 FrameEmpty(1,4,70,17,$0B);
 ArrayListSetPtr(List,0);
 TextColor(7);
 TextBackground(0);
 GotoXY(7,5);
 Write(Copy(FileName,1,12));
{ ColorEditor;
 For I:=0 to EditNumLines-1 do Begin
  GotoXY(EditX,EditY+I);
  If I>ArrayListCount(List)Then ClrEol
   Else
  Begin
   CurrLine:=ArrayListGetCurrStr(List);
   Write(Copy(CurrLine,1,EditNumColumns));
   ArrayListNext(List);
  End;
 End;
 ArrayListSetPtr(List,P);}
 RefreshEditor;
 TEPutPos;
End;

Procedure ShowTrace;Begin
 Box(71,4,80,24,$0B);
 FrameEmpty(71,4,80,24,$0B);
 TextColor(7);
 GotoXY(73,4);
 Write(' Trace ');
End;

Procedure HideSubMenu;Begin
 Box(1,5,69,16,$0E);
 UpdateMenu;
 ShowEditor;
 ShowTrace;
 ShowFunctionsKey;
End;

Procedure ShowModified;Begin
 TextColor(5);
 TextBackground(0);
 GotoXY(40,5);
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
   Window(1,1,80,25);
   GotoXY(EditX,EditY+EditNumLines-1);
   CurrLine:=ArrayListGetCurrStr(List);
   Write(Copy(CurrLine,1,EditNumColumns));
  End;
 End;
End;

Procedure NotImplemented;Begin
 Box(5,11,75,13,$60);
 FrameEmpty(5,11,75,13,$60);
 GotoXY(20,12);
 Write('Cette fonctionnalite n''est pas implemented');
 ReadKey;
 HideSubMenu;
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
  If Not(OnMenu)Then TEPutPos;
  K:=ReadKey;
  If(OnMenu)Then Case K of
   #0:Case ReadKey of
     #72:Begin { Up }
      SubMenuItem(YMenu,True);
      If YMenu>0Then Dec(YMenu)
                Else YMenu:=YMenuMax[XMenu];
      If XMenu=5 Then Begin
       If YMenu in[1,7]Then Dec(YMenu);
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
     If XMenu=5 Then Begin
       If YMenu in[1,7]Then Inc(YMenu);
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
     2:; { Retour … l'‚diteur }
     3:Begin { Run }
     SetOutputWindow;
     RunCommand;
     Window(1,1,80,25);
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
    #19:Begin { Alt+R }
     SetOutputWindow;
     RunCommand;
     Window(1,1,80,25);
    End;
    #33:Begin { Alt+F }
     XMenu:=1;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #45:Terminated:=True; { Alt+X }
    #60:SaveText(FileName); { F2 }
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
       Window(1,1,80,25);
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
   #27:Begin
    XMenu:=2;
    OnMenu:=True;
    ShowMenu;
    ShowSubMenu;
   End;
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

Procedure NewCommand;Forward;

Function TAN(X:Real):Real;Begin
 If Cos(X)=0.0Then Tan:=0.0
              Else Tan:=SIN(X)/COS(X);
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

Function GetCurrentDisk:Char;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 GetCurrentDisk:=CurrentDir[1];
End;

Function GetErrorMessage(Code:Word):String;Begin
 Case Code of
  0:GetErrorMessage:='';
  2:GetErrorMessage:='Fichier introuvable';
  3:GetErrorMessage:='Chemin introuvable';
  4:GetErrorMessage:='Trop de fichiers ouvert';
  5:GetErrorMessage:='Acces refuse';
  6:GetErrorMessage:='Handle de fichier invalide';
  12:GetErrorMessage:='Mode d''acces sur disque invalide';
  15:GetErrorMessage:='Num‚ro de disque invalide';
  16:GetErrorMessage:='Impossible de supprimer le r‚pertoire';
  17:GetErrorMessage:='Impossible de renommer sur plusieurs volumes';
  100:GetErrorMessage:='Erreur de lecture … partir du disque';
  101:GetErrorMessage:='Erreur d''ecriture sur le disque';
  102:GetErrorMessage:='Fichier non attribue';
  103:GetErrorMessage:='Le fichier n''est pas ouvert';
  104:GetErrorMessage:='Le fichier n''est pas ouvert … l''entree';
  105:GetErrorMessage:='Le fichier n''est pas ouvert … la sortie';
  106:GetErrorMessage:='Numero invalide';
  150:GetErrorMessage:='Disque protege en ecriture';
  151:GetErrorMessage:='Peripherique est inconnu';
  152:GetErrorMessage:='Disque pas pret';
  153:GetErrorMessage:='Commande inconnue';
  154:GetErrorMessage:='Echec de verification CRC';
  155:GetErrorMessage:='Disque invalide';
  156:GetErrorMessage:='Erreur de recherche sur disque';
  157:GetErrorMessage:='Type de media invalide';
  158:GetErrorMessage:='Secteur introuvable';
  159:GetErrorMessage:='L''imprimante n''a plus de papier';
  160:GetErrorMessage:='Erreur d''ecriture sur le peripherique';
  161:GetErrorMessage:='Erreur de lecture sur le peripherique';
  162:GetErrorMessage:='Defaillance materielle';
  Else GetErrorMessage:='Erreur inconnue';
 End;
End;

Procedure ShowFunctionKey;
Var
 I,J,OldY:Byte;
 Temp:String;
Begin
{ OldY:=WhereY;
 Window(1,1,80,25);
 GotoXY(1,25);
 ClrEol;
 If(KeyFunction)Then Begin
  For I:=1 to 10 do Begin
   TextColor(7);
   TextBackground(0);
   Write(I mod 10);
   TextColor(0);
   TextBackground(7);
   Temp:='';
   For J:=1 to Length(FunctionKeyList[I])do Begin
    If FunctionKeyList[I][J]<>#13Then Temp:=Temp+FunctionKeyList[I][J];
   End;
   Write(Temp);
   TextColor(7);
   TextBackground(0);
   If I<10 Then Begin
    If Length(Temp)<7 Then Write(' ':7-Length(Temp));
   End;
  End;
 End;
 Window(1,1,80,24);
 GotoXY(1,OldY);}
End;

Procedure HomeMessage;Begin
 Window(51,19,69,24);
 ClrScr;
End;

Function ExtractCommand:Byte;
Var
 I:Byte;
Begin
 ExtractCommand:=255;
 CurrCommand:='';
 For I:=CurrPos to Length(CurrLine)do Begin
  If Not(CurrLine[I]in['A'..'Z','a'..'z','$','%','!','#'])Then Begin
   CurrCommand:=StrToUpper(Copy(CurrLine,CurrPos,I-CurrPos));
   CurrPos:=I;
   Break;
  End;
 End;
 If CurrCommand=''Then Begin
  CurrCommand:=StrToUpper(Copy(CurrLine,CurrPos,255));
  CurrPos:=Length(CurrLine)+1;
 End;
 For I:=Low(CommandList)to High(CommandList)do Begin
  If CurrCommand=CommandList[I]Then Begin
   ExtractCommand:=I;
   Exit;
  End;
 End;
End;

 { Traitement des variables }
Function VariableExist(S:String):Boolean;
Var
 I:Integer;
Begin
 VariableExist:=False;
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  VariableExist:=True;
  Exit;
 End;
End;

Function VariableType(S:String):VarTypeEnum;
Var
 I:Integer;
Begin
 VariableType:=_None;
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  VariableType:=VarList[I]^.VarType;
  Exit;
 End;
End;

Function AddVariableInt(S:String;Value:Integer):Boolean;
Var
 P:VarPointer;
Begin
 If NumberVariable>=MaxVariable Then Begin
  AddVariableInt:=False;
  Exit;
 End;
 Inc(NumberVariable);
 GetMem(P,SizeOf(VarRec));
 P^.VarName:=Copy(StrToUpper(S),1,20);
 P^.VarType:=_Integer;
 P^.Variant.I:=Value;
 VarList[NumberVariable]:=P;
 AddVariableInt:=True;
End;

Function GetVariableInt(S:String):Integer;
Var
 I:Integer;
Begin
 GetVariableInt:=0;
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  GetVariableInt:=VarList[I]^.Variant.I;
  Exit;
 End;
End;

Procedure SetVariableInt(S:String;Value:Integer);
Var
 I:Integer;
Begin
 For I:=1 to NumberVariable do If(S=VarList[I]^.VarName)Then Begin
  VarList[I]^.Variant.I:=Value;
  Exit;
 End;
End;

Function AddVariableLongInt(S:String;Value:LongInt):Boolean;
Var
 P:VarPointer;
Begin
 If NumberVariable>=MaxVariable Then Begin
  AddVariableLongInt:=False;
  Exit;
 End;
 Inc(NumberVariable);
 GetMem(P,SizeOf(VarRec));
 P^.VarName:=Copy(StrToUpper(S),1,20);
 P^.VarType:=_LongInt;
 P^.Variant.L:=Value;
 VarList[NumberVariable]:=P;
 AddVariableLongInt:=True;
End;

Function GetVariableLongInt(S:String):LongInt;
Var
 I:Integer;
Begin
 GetVariableLongInt:=0;
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  GetVariableLongInt:=VarList[I]^.Variant.L;
  Exit;
 End;
End;

Procedure SetVariableLongInt(S:String;Value:LongInt);
Var
 I:Integer;
Begin
 For I:=1 to NumberVariable do If(S=VarList[I]^.VarName)Then Begin
  VarList[I]^.Variant.L:=Value;
  Exit;
 End;
End;

Function AddVariableReal(S:String;Value:Real):Boolean;
Var
 P:VarPointer;
Begin
 If NumberVariable>=MaxVariable Then Begin
  AddVariableReal:=False;
  Exit;
 End;
 Inc(NumberVariable);
 GetMem(P,SizeOf(VarRec));
 P^.VarName:=Copy(StrToUpper(S),1,20);
 P^.VarType:=_Real;
 P^.Variant.R:=Value;
 VarList[NumberVariable]:=P;
 AddVariableReal:=True;
End;

Function GetVariableReal(S:String):Real;
Var
 I:Integer;
Begin
 GetVariableReal:=0;
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  GetVariableReal:=VarList[I]^.Variant.R;
  Exit;
 End;
End;

Procedure SetVariableReal(S:String;Value:Real);
Var
 I:Integer;
Begin
 For I:=1 to NumberVariable do If(S=VarList[I]^.VarName)Then Begin
  VarList[I]^.Variant.R:=Value;
  Exit;
 End;
End;

Function AddVariableString(S:String;Value:String):Boolean;
Var
 P:VarPointer;
 PS:StrPointer;
Begin
 If NumberVariable>=MaxVariable Then Begin
  AddVariableString:=False;
  Exit;
 End;
 Inc(NumberVariable);
 GetMem(P,SizeOf(VarRec));
 P^.VarName:=Copy(StrToUpper(S),1,20);
 P^.VarType:=_String;
 GetMem(PS,SizeOf(String));
 PS^:=Value;
 P^.Variant.S:=PS;
 VarList[NumberVariable]:=P;
 AddVariableString:=True;
End;

Function GetVariableString(S:String):String;
Var
 I:Integer;
Begin
 GetVariableString:='';
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  GetVariableString:=VarList[I]^.Variant.S^;
  Exit;
 End;
End;

Procedure SetVariableString(S:String;Value:String);
Var
 I:Integer;
Begin
 For I:=1 to NumberVariable do If(S=VarList[I]^.VarName)Then Begin
  VarList[I]^.Variant.S^:=Value;
  Exit;
 End;
End;

Function FirstNumberInStr(S:String):Integer;
Var
 J,Number,Err:Integer;
Begin
 FirstNumberInStr:=0;
 J:=1;
 While(J<Length(S))do Begin
  If Not(S[J]in['0'..'9'])Then Begin
   Val(Copy(S,1,J-1),Number,Err);
   FirstNumberInStr:=Number;
   Break;
  End;
  Inc(J);
 End;
End;

Procedure ResortList;Begin
End;

 { Evaluation d'expression (Infix to PostFix ) }
Var
 Stack:Array[0..100]of Char;
 TopOfStack:Byte;
 resultStack:Array[0..100]of Real;
 TopOfStackInt:Byte;

Procedure StackPushChar(C:Char);Begin
 If TopOfStack>=High(Stack)Then Begin
  WriteLn('Pile pleine!');
  Halt;
 End
  Else
 Begin
  Stack[TopOfStack]:=C;
  Inc(TopOfStack);
 End;
End;

Function StackPop:String;
Var
 S:String;
 Err:Word;
Begin
 Dec(TopOfStack);
 If TopOfStack<1Then Begin
  StackPop:='';
  WriteLn('Pile vide');
  Halt;
 End
  Else
 StackPop:=Stack[TopOfStack];
End;

Function StackPeek:Char;Begin
 StackPeek:=Stack[TopOfStack-1];
End;

Procedure ResultStackPush(C:Real);Begin
 If TopOfStackInt>=High(ResultStack)Then Begin
  WriteLn('Pile pleine!');
  Halt;
 End
  Else
 Begin
  ResultStack[TopOfStackInt]:=C;
  Inc(TopOfStackInt);
 End;
End;

Function ResultStackPop:Real;Begin
 Dec(TopOfStackInt);
 If TopOfStackInt<1Then Begin
  ResultStackPop:=-1.0;
  WriteLn('Pile vide');
  Exit;
 End
  Else
 ResultStackPop:=ResultStack[TopOfStackInt];
End;


Procedure SkipSpace;Begin
 While(CurrLine[CurrPos]in[' '])and(CurrPos<Length(CurrLine))do Inc(CurrPos);
End;

Function GetSeparator:Char;Begin
 If CurrPos>Length(CurrLine)Then Begin
  GetSeparator:=#0;
  Exit;
 End;
 SkipSpace;
 GetSeparator:=CurrLine[CurrPos];
End;

Function IsStringValue:Boolean;
Var
 I:Byte;
Begin
 IsStringValue:=False;
 If CurrLine[CurrPos]='"'Then Begin
  IsStringValue:=True;
 End
  Else
 Begin
  I:=CurrPos;
  While(CurrLine[I]in[' '])and(I<Length(CurrLine))do Inc(I);
  If CurrLine[I]in['A'..'Z','a'..'z']Then Begin
   Inc(I);
   While I<Length(CurrLine)do Begin
    If Not(CurrLine[I]in['A'..'Z','a'..'z','0'..'9'])Then Break;
    Inc(I);
   End;
   If(I<=Length(CurrLine))and(CurrLine[I]='$')Then IsStringValue:=True;
  End;
 End;
End;

Function GetVariableName:String;
Var
 S:String;
Begin
 S:='';
 If CurrLine[CurrPos]in['A'..'Z','a'..'z']Then Begin
  S:=S+CurrLine[CurrPos];
  Inc(CurrPos);
  While CurrPos<Length(CurrLine)do Begin
   If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z','0'..'9'])Then Break;
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
 End;
 GetVariableName:=StrToUpper(S);
End;

Function ReadWord:String;
Var
 S:String;
Begin
 S:='';
 If CurrLine[CurrPos]in['A'..'Z','a'..'z']Then Begin
  S:=S+CurrLine[CurrPos];
  Inc(CurrPos);
  While CurrPos<Length(CurrLine)do Begin
   If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z','0'..'9'])Then Break;
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
 End;
 ReadWord:=StrToUpper(S);
End;

Function ReadWordString:String;
Var
 S:String;
Begin
 S:='';
 If CurrLine[CurrPos]in['A'..'Z','a'..'z']Then Begin
  S:=S+CurrLine[CurrPos];
  Inc(CurrPos);
  While CurrPos<Length(CurrLine)do Begin
   If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z','0'..'9'])Then Break;
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
  If CurrLine[CurrPos]='$'Then Begin
   S:=S+'$';
   Inc(CurrPos);
  End;
 End;
 ReadWordString:=StrToUpper(S);
End;

Function GetNumberValue(MinTopOfStack:Integer):Real;Forward;

Function GetStringValue:String;
Label Restart;
Var
 J:Integer;
 _Result:Real;
 FunctionFound:Boolean;
 S,VarName:String;
Begin
 GetStringValue:='';
 S:='';
Restart:
 If CurrLine[CurrPos]='"'Then Begin
  Inc(CurrPos);
  While(CurrLine[CurrPos]<>'"')and(CurrPos<=Length(CurrLine))do Begin
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
  If CurrLine[CurrPos]='"'Then Inc(CurrPos);
 End
  Else
 Begin
  VarName:=ReadWordString;
  SkipSpace;
  FunctionFound:=False;
  For J:=Low(FunctionList)to High(FunctionList)do Begin
   If FunctionList[J]=VarName Then Begin
    FunctionFound:=True;
    Case J of
     3:Begin{CHR$}
      If CurrLine[CurrPos]<>'('Then Begin
       WriteLn('"(" attendu');
       Exit;
      End;
      Inc(CurrPos);
      _Result:=GetNumberValue(1);
      If CurrLine[CurrPos]<>')'Then Begin
       WriteLn('")" attendu');
       Exit;
      End;
      Inc(CurrPos);
      S:=S+Chr(Byte(Trunc(_Result)));
      GetStringValue:=S;
      Break;
     End;
     Else Begin
      WriteLn('Type incompatible');
      Exit;
     End;
    End;
   End;
  End;
  If Not(FunctionFound)Then Begin
   If VariableExist(VarName)Then Begin
    S:=S+GetVariableString(VarName);
   End;
  End;
 End;
 SkipSpace;
 If CurrLine[CurrPos]in['+',';']Then Begin
  Inc(CurrPos);
  Goto Restart;
 End;
 GetStringValue:=S;
End;

Function GetNumberValue(MinTopOfStack:Integer):Real;
Var
 I,J:Byte;
 Top,P_2:Char;
 AppendOk,FunctionFound:Boolean;
 _Result,P,P2:Real;
 Err:Word;
 PostFix:String;
 VarName,Value:String;
 Exposant:Boolean;
 StopChar:Set Of Char;
 Infix:String;
Begin
 StopChar:=[',',':',';','"','<','=','>'];
 TopOfStack:=1;
 TopOfStackInt:=1;
 PostFix:='';
 Infix:=CurrLine;
 I:=CurrPos;
 If Infix[CurrPos]='-'Then Begin
  Insert('(0)',Infix,CurrPos);
  Dec(CurrPos,3);
 End;
 Repeat
  If(I<=Length(Infix))and(Infix[I]in['A'..'Z','a'..'z'])Then Begin
   VarName:=Infix[I];
   Inc(I);
   While(I<=Length(Infix))and(Infix[I]in['A'..'Z','a'..'z','%','!','#'])do Begin
    VarName:=VarName+Infix[I];
    Inc(I);
   End;
   VarName:=StrToUpper(VarName);
   If VariableExist(VarName)Then Begin
    Case VariableType(VarName)of
     _Integer:Str(GetVariableInt(VarName),Value);
     _LongInt:Str(GetVariableLongInt(VarName),Value);
     _Real:Str(GetVariableReal(VarName),Value);
     Else Begin
      WriteLn('Type incompatiable');
      Exit;
     End;
    End;
   End
    Else
   Begin { Fonction ?}
    FunctionFound:=False;
    For J:=Low(FunctionList)to High(FunctionList)do Begin
     If FunctionList[J]=VarName Then Begin
      FunctionFound:=True;
      Case J of
       0:Begin{ABS}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        If Frac(_Result)=0.0 Then Str(Trunc(_Result),Value)
                             Else Str(_Result,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       1:Begin{ASC}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        Value:=GetStringValue;
        If Length(Value)=0Then _Result:=0.0
                          Else _Result:=Ord(Value[1]);
        Str(_Result:0:0,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       2:Begin{ATN}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(ArcTan(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       3:Begin{CHR$}
        WriteLn('Type incompatible');
        Exit;
       End;
       4:Begin{CINT}
       End;
       5:Begin{CSNG}
       End;
       6:Begin{CSRLIN}
        Str(WhereY,Value);
       End;
       7:Begin{COS}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Cos(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       8:Begin{CVD}
       End;
       9:Begin{CVI}
       End;
       10:Begin{CVS}
       End;
       11:Begin{DATE$}
       End;
       12:Begin{EOF}
       End;
       13:Begin{ERL}
       End;
       14:Begin{ERR}
       End;
       15:Begin{EXP}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Exp(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       16:Begin{FIX}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=Trunc(GetNumberValue(TopOfStack));
        Str(_Result:0:0,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       17:Begin{FRE}
       End;
       18:Begin{INKEY$}
       End;
       19:Begin{INP}
       End;
       20:Begin{INPUT$}
       End;
       21:Begin{INSTR}
       End;
       22:Begin{INT}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=Round(GetNumberValue(TopOfStack));
        Str(_Result:0:0,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       23:Begin{LEFT$}
       End;
       24:Begin{LEN}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        Value:=GetStringValue;
        If Length(Value)=0Then _Result:=0.0
                          Else _Result:=Length(Value);
        Str(_Result:0:0,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       25:Begin{LOF}
       End;
       26:Begin{LOG}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Ln(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       27:Begin{LPOS}
       End;
       28:Begin{LTRIM$}
       End;
       29:Begin{MID$}
       End;
       30:Begin{OCT$}
       End;
       31:Begin{PEEK}
       End;
       32:Begin{PLAY}
       End;
       33:Begin{PMAP}
       End;
       34:Begin{POS}
       End;
       35:Begin{RIGHT$}
       End;
       36:Begin{RND}
       End;
       37:Begin{RTRIM$}
       End;
       38:Begin{SCREEN}
       End;
       39:Begin{SGN}
       End;
       40:Begin{SIN}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Sin(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       41:Begin{SQR}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Sqrt(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       42:Begin{STR$}
       End;
       43:Begin{STRIG}
       End;
       44:Begin{STRING$}
       End;
       45:Begin{TAN}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Tan(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       46:Begin{TAB}
       End;
       47:Begin{TIME$}
       End;
       48:Begin{TIMER}
       End;
       49:Begin{TRIM$}
       End;
       50:Begin{USR}
       End;
       51:Begin{VAL}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        Value:=GetStringValue;
        Val(Value,_Result,Err);
        Str(_Result,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       52:Begin{VARPTR}
       End;
       53:Begin{VARPTR$}
       End;
      End;
      Break;
     End
      Else
     Begin { Variable vide }
      Value:='0';
     End;
    End;
   End;
   PostFix:=PostFix+'('+LTrim(Value)+')';
   If I>Length(Infix)Then Break;
  End
   Else
  If Infix[I]in['0'..'9']Then Begin
   Value:='';
   Exposant:=False;
   Repeat
    If Infix[I]in['E','e']Then Begin
     Exposant:=True;
     Value:=Value+Infix[I];
     Inc(I);
    End
     Else
    If(Exposant)and(Infix[I]in['-','+'])Then Begin
     Value:=Value+Infix[I];
     Inc(I);
    End
     Else
    If Infix[I]in['0'..'9','.']Then Begin
     Value:=Value+Infix[I];
     Inc(I);
    End
     Else
    Break;
   Until I>Length(Infix);
   PostFix:=PostFix+'('+Value+')';
  End
   Else
  If Infix[I]='('Then Begin
   StackPushChar(Infix[I]);
   Inc(I);
  End
   Else
  If Infix[I]in['*','+','-','/']Then Begin
   While(TopOfStack>MinTopOfStack)and(StackPeek <> '(')do Begin
    Top:=StackPeek;
    P_2:=Infix[I];
    AppendOk:=True;
    If(Top='+')and(P_2='*')Then AppendOk:=False
    Else If(Top='*')and(P_2='-')Then AppendOk:=True
    Else If(Top='+')and(P_2='-')Then AppendOk:=True;
    If(AppendOk)Then PostFix:=PostFix+StackPop
                Else Break;
   End;
   StackPushChar(Infix[I]);
   Inc(I);
  End
   Else
  If Infix[I]=')'Then Begin
   If TopOfStack<=MinTopOfStack Then Begin
    Break;
   End;
   While(TopOfStack>MinTopOfStack)and(StackPeek<>'(')do PostFix:=PostFix+StackPop;
   If TopOfStack>1Then StackPop;
   Inc(I);
  End
   Else
  Inc(I);
  If(Infix[I]in StopChar)Then Break;
  If(StrToUpper(Copy(Infix,I,4))='THEN')or(StrToUpper(Copy(Infix,I,2))='TO')Then Break;
 Until I>Length(Infix);
 CurrPos:=I;
 While(TopOfStack>MinTopOfStack)do PostFix:=PostFix+StackPop;
  { Transformation en POSTFIX }
 I:=1;
 Repeat
  If PostFix[I]in['*','+','-',' ']Then Begin
   P:=ResultStackPop;
   P2:=ResultStackPop;
   Case PostFix[I]of
    '+':_Result:=P2+P;
    '-':_Result:=P2-P;
    '*':_Result:=P2*P;
    '/':_Result:=P2/P;
    Else _Result:=-1;
   End;
   ResultStackPush(_Result);
  End
   Else
  Begin
   Value:='';
   Exposant:=False;
   Repeat
    If Postfix[I]in['0'..'9','.']Then Begin
     Value:=Value+Postfix[I];
     Inc(I);
    End
     Else
    If(Value<>'')and(Postfix[I]in['E','e'])Then Begin
     Exposant:=True;
     Value:=Value+Postfix[I];
     Inc(I);
    End
     Else
    If(Value<>'')and(Exposant)and(Postfix[I]in['+','-'])Then Begin
     Value:=Value+Postfix[I];
     Inc(I);
    End
     Else
    Break;
   Until I>Length(Postfix);
   If Value<>''Then Begin
    Val(Value,_Result,Err);
    ResultStackPush(_Result);
   End;
  End;
  Inc(I);
 Until I>Length(Postfix);
 GetNumberValue:=ResultStackPop;
End;

 { Traitement des commandes }
Procedure BeepCommand;Begin
 Sound(1550);
 Delay(182);
 NoSound;
End;

Procedure ColorCommand;
Var
 Foreground,Background:Real;
Begin
 Foreground:=GetNumberValue(1);
 TextColor(Trunc(Foreground));
 If GetSeparator=','Then Begin
  Inc(CurrPos);
  Background:=GetNumberValue(1);
  TextBackground(Trunc(Background));
 End;
End;

Procedure ChDirCommand;
Var
 Error:Word;
 S:String;
Begin
 SkipSpace;
 {$I-} ChDir(GetStringValue);{$I+}
 Error:=IoResult;
 If Error<>0Then WriteLn(GetErrorMessage(Error));
End;

Procedure FilesCommand;
Var
 Info:SearchRec;
 CurrDrive:Char;
Begin
 CurrDrive:=GetCurrentDisk;
 FindFirst('*.*',AnyFile,Info);
 While DOSError=0 do Begin
  Write(PadRight(Info.Name,16));
  FindNext(Info);
 End;
 WriteLn;
 WriteLn(' ',DiskFree(Byte(CurrDrive)-64):10,' octet(s) de libre');
 WriteLn;
End;

Function ForCommand:Boolean;
Var
 R1,R2:Real;
Begin
 ForCommand:=False;
 If ForPos>=High(ForStack)Then Begin
  WriteLn('Pile de FOR pleine.');
  Exit;
 End;
 Inc(ForPos);
 ForStack[ForPos].Line:=CurrLinePtr;
 ForStack[ForPos].LineNumber:=CurrNumberLine;
 SkipSpace;
 ForStack[ForPos].VarName:=Copy(GetVariableName,1,20);
 SkipSpace;
 If GetSeparator<>'='Then Begin
  WriteLn('"=" attendu.');
  Exit;
 End;
 Inc(CurrPos);
 R1:=GetNumberValue(1);
 If VariableExist(ForStack[ForPos].VarName)Then
  SetVariableReal(ForStack[ForPos].VarName,Trunc(R1))
 Else
  AddVariableReal(ForStack[ForPos].VarName,Trunc(R1));
 SkipSpace;
 If StrToUpper(ReadWord)<>'TO'Then Begin
  WriteLn('Mot r‚serv‚ "TO" attendu');
  Exit;
 End;
 SkipSpace;
 ForStack[ForPos].Col:=CurrPos;
 R2:=GetNumberValue(1);
 ForCommand:=True;
End;

Function GosubCommand:Boolean;
Var
 JumpLine:Integer;
 I,J,Err:Integer;
 TempLine:String;
Begin
 GosubCommand:=True;
 If GosubPos>=High(GosubStack)Then Begin
  WriteLn('Pile de GOSUB pleine !');
  GosubCommand:=False;
  Exit;
 End;
 JumpLine:=Trunc(GetNumberValue(1));
 If(CurrPos<=Length(CurrLine))and(CurrLine[CurrPos]=':')Then Inc(CurrPos);
 Inc(GosubPos);
 GosubStack[GosubPos].Line:=CurrLinePtr;
 GosubStack[GosubPos].Col:=CurrPos;
 GosubStack[GosubPos].LineNumber:=CurrNumberLine;
 If ArrayListCount(List)>0Then Begin
  For I:=1 to ArrayListCount(List)do Begin
   ArrayListSetPtr(List,I-1);
   TempLine:=ArrayListGetCurrStr(List);
   If(FirstNumberInStr(TempLine)=JumpLine)Then Begin
    CurrNumberLine:=JumpLine;
    CurrLine:=TempLine;
    CurrLinePtr:=I;
    J:=1;
    While(J<Length(CurrLine))do Begin
     If Not(CurrLine[J]in['0'..'9'])Then Begin
      Val(Copy(CurrLine,1,J-1),CurrNumberLine,Err);
      Break;
      End;
     Inc(J);
    End;
    While J<=Length(CurrLine)do Begin
     If CurrLine[J]in[' ',#9]Then Inc(J)
                             Else Break;
    End;
    CurrPos:=J;
    Exit;
   End;
  End;
 End;
 WriteLn('Etiquette introuvable');
 GosubCommand:=False;
End;

Function GotoCommand:Boolean;
Var
 JumpLine:Integer;
 I,J,Err:Integer;
 TempLine:String;
Begin
 GotoCommand:=True;
 JumpLine:=Trunc(GetNumberValue(1));
 If ArrayListCount(List)>0Then Begin
  For I:=1 to ArrayListCount(List) do Begin
   ArrayListSetPtr(List,I-1);
   TempLine:=ArrayListGetCurrStr(List);
   If(FirstNumberInStr(TempLine)=JumpLine)Then Begin
    CurrNumberLine:=JumpLine;
    CurrLine:=TempLine;
    CurrLinePtr:=I;
    J:=1;
    While(J<Length(CurrLine))do Begin
    If Not(CurrLine[J]in['0'..'9'])Then Begin
      Val(Copy(CurrLine,1,J-1),CurrNumberLine,Err);
      Break;
     End;
     Inc(J);
    End;
    While J<=Length(CurrLine)do Begin
     If CurrLine[J]in[' ',#9]Then Inc(J)
                             Else Break;
    End;
    CurrPos:=J;
    Exit;
   End;
  End;
 End;
 WriteLn('Etiquette introuvable');
 GotoCommand:=False;
End;

Procedure HelpCommand;
Var
 I:Byte;
Begin
 For I:=Low(CommandList) to High(CommandList) do Write(PadRight(CommandList[I],10));
 WriteLn;
End;

Procedure IfCommand;
Var
 ResultCmp:Boolean;
 Compare:String;
 R1,R2:Real;
 S,S1,S2:String;
Begin
 If GetSeparator='"'Then Begin
  Compare:='';
  S1:=GetStringValue;
  Case GetSeparator of
   '=':Begin
    Compare:='=';
    Inc(CurrPos);
   End;
   '<':Begin
    Inc(CurrPos);
    If GetSeparator='='Then Begin
     Compare:='<=';
     Inc(CurrPos);
    End
     Else
    Compare:='<';
   End;
   '>':Begin
    Inc(CurrPos);
    If GetSeparator='='Then Begin
     Compare:='>=';
     Inc(CurrPos);
    End
     Else
    Compare:='>';
   End;
  End;
  S2:=GetStringValue;
  If Compare='<='Then ResultCmp:=S1<=S2 Else
  If Compare='<'Then ResultCmp:=S1<S2 Else
  If Compare='>='THen ResultCmp:=S1>=S2 Else
  If Compare='>'Then ResultCmp:=S1>S2 Else
  If Compare='='Then ResultCmp:=S1=S2
   Else
  Begin
   WriteLn('Erreur d''operateur de comparaison');
   Exit;
  End;
 End
  Else
 Begin
  Compare:='';
  R1:=GetNumberValue(1);
  Case GetSeparator of
   '=':Begin
    Inc(CurrPos);
    Compare:='=';
   End;
   '<':Begin
    Inc(CurrPos);
    If GetSeparator='='Then Begin
     Inc(CurrPos);
     Compare:='<=';
    End
     Else
    Compare:='<';
   End;
   '>':Begin
    Inc(CurrPos);
    If GetSeparator='='Then Begin
     Compare:='>=';
     Inc(CurrPos);
    End
     Else
    Compare:='>';
   End;
  End;
  R2:=GetNumberValue(1);
  If Compare='<='Then ResultCmp:=R1<=R2 Else
  If Compare='<'Then ResultCmp:=R1<R2 Else
  If Compare='>='THen ResultCmp:=R1>=R2 Else
  If Compare='>'Then ResultCmp:=R1>R2 Else
  If Compare='='Then ResultCmp:=R1=R2
   Else
  Begin
   WriteLn('Erreur d''operateur de comparaison');
   Exit;
  End;
 End;
 While CurrPos<Length(CurrLine) do Begin
  If Not(CurrLine[CurrPos]in[#9,' '])Then Break;
  Inc(CurrPos);
 End;
 S:='';
 While CurrPos<Length(CurrLine) do Begin
  If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z'])Then Break;
  S:=S+CurrLine[CurrPos];
  Inc(CurrPos);
 End;
 If StrToUpper(S)<>'THEN'Then Begin
  WriteLn('Mot reserve THEN introuvable');
  Exit;
 End;
 While CurrPos<Length(CurrLine) do Begin
  If Not(CurrLine[CurrPos]in[#9,' '])Then Break;
  Inc(CurrPos);
 End;
 If ResultCmp Then Exit;
 While CurrPos<Length(CurrLine) do Begin
  If(CurrLine[CurrPos]in[#9,' ',':'])and(StrToUpper(Copy(CurrLine,CurrPos+1,4))='ELSE')Then Begin
   Inc(CurrPos,5);
   Break;
  End;
  Inc(CurrPos);
 End;
End;

Procedure KeyCommand;
Var
 S:String;
Begin
 SkipSpace;
 S:='';
 While CurrPos<=Length(CurrLine) do Begin
  If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z'])Then Break;
  S:=S+CurrLine[CurrPos];
  Inc(CurrPos);
 End;
 If StrToUpper(S)='ON'Then Begin
  KeyFunction:=True;
  ShowFunctionKey;
 End
  Else
 If StrToUpper(S)='OFF'Then Begin
  KeyFunction:=False;
  ShowFunctionKey;
 End
  Else
 WriteLn('Mot non reconnu');
End;

Procedure ListCommand;
Var
 I:Integer;
Begin
 If ArrayListCount(List)>0Then Begin
  For I:=1 to ArrayListCount(List) do Begin
   ArrayListSetPtr(List,I-1);
   WriteLn(ArrayListGetCurrStr(List));
  End;
 End;
End;

Procedure LListCommand;
Var
 I:Integer;
Begin
 If ArrayListCount(List)>0Then Begin
  For I:=1 to ArrayListCount(List) do Begin
   ArrayListSetPtr(List,I-1);
   WriteLn(Lst,ArrayListGetCurrStr(List));
  End;
 End;
End;

Procedure LoadCommand;
Var
 FileLoad:Text;
 S:String;
Begin
 If GetSeparator='"'Then Begin
  FileName:=GetStringValue;
  If FileName<>''Then Begin
   If StrToUpper(Copy(FileName,Length(FileName)-3,4))<>'.BAS'Then FileName:=FileName+'.BAS';
   {$I-}Assign(FileLoad,FileName);
   Reset(FileLoad);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Fichier introuvable');
    Exit;
   End;
   NewCommand;
   While Not EOF(FileLoad) do Begin
    ReadLn(FileLoad,S);
    If Not ArrayListAddStr(List,LTrim(S))Then Begin
     WriteLn('Manque de m‚moire');
     Break;
    End;
   End;
   Close(FileLoad);
   ResortList;
  End
   Else
  WriteLn('Nom du fichier absent');
 End
  Else
 WriteLn('Chaine de caractŠres attendu');
End;

Procedure LocateCommand;
Var
 X,Y:Real;
Begin
 Y:=GetNumberValue(1);
 If GetSeparator=','Then Begin
  Inc(CurrPos);
  X:=GetNumberValue(1);
  If(X>80.0)or(X<0.0)Then Begin
   WriteLn('Depassement d''intervalle');
   Exit;
  End;
  GotoXY(Trunc(X),Trunc(Y));
 End
  Else
 GotoXY(1,Trunc(Y));
End;

Procedure MkDirCommand;
Var
 Error:Word;
 S:String;
Begin
 SkipSpace;
 {$I-} MkDir(GetStringValue);{$I+}
 Error:=IoResult;
 If Error<>0Then WriteLn(GetErrorMessage(Error));
End;

Procedure NewCommand;Begin
 ArrayListDone(List);
 ArrayListInit(List);
End;

Function NextCommand:Boolean;
Var
 NextCurrPos,NextCurrLinePtr,NextCurrNumberLine:Word;
 R2:Real;
Begin
 NextCommand:=False;
 If ForPos=0 Then Begin
  WriteLn('NEXT sans FOR');
  Exit;
 End;
 NextCurrPos:=CurrPos;
 NextCurrLinePtr:=CurrLinePtr;
 NextCurrNumberLine:=CurrNumberLine;
 CurrPos:=ForStack[ForPos].Col;
 CurrLinePtr:=ForStack[ForPos].Line;
 ArrayListSetPtr(List,CurrLinePtr-1);
 CurrLine:=ArrayListGetCurrStr(List);
 CurrNumberLine:=ForStack[ForPos].LineNumber;
 SetVariableReal(ForStack[ForPos].VarName,GetVariableReal(ForStack[ForPos].VarName)+1);
 R2:=GetNumberValue(1);
 If GetVariableReal(ForStack[ForPos].VarName)>R2 Then Begin
  CurrPos:=NextCurrPos;
  CurrLinePtr:=NextCurrLinePtr;
  CurrNumberLine:=NextCurrNumberLine;
  ArrayListSetPtr(List,CurrLinePtr-1);
  CurrLine:=ArrayListGetCurrStr(List);
  Dec(ForPos);
 End;
 NextCommand:=True;
End;

Procedure PrintCommand;
Var
 R:Real;
Begin
 SkipSpace;
 Begin
  If IsStringValue Then Begin
   WriteLn(GetStringValue);
  End
   Else
  Begin
   If CurrPos>Length(CurrLine)Then WriteLn
    Else
   Begin
    R:=GetNumberValue(1);
    If Frac(R)=0.0Then WriteLn(R:0:0)
                  Else WriteLn(R);
   End;
  End;
 End;
End;

Procedure RmDirCommand;
Var
 Error:Word;
 S:String;
Begin
 SkipSpace;
 {$I-} RmDir(GetStringValue);{$I+}
 Error:=IoResult;
 If Error<>0Then WriteLn(GetErrorMessage(Error));
End;

Procedure ReturnCommand;Begin
 If(GosubPos=0)Then Begin
  WriteLn('RETURN sans GOSUB');
  Exit;
 End;
 CurrPos:=GosubStack[GosubPos].Col;
 CurrLinePtr:=GosubStack[GosubPos].Line;
 ArrayListSetPtr(List,CurrLinePtr-1);
 CurrLine:=ArrayListGetCurrStr(List);
 CurrNumberLine:=GosubStack[GosubPos].LineNumber;
 Dec(GosubPos);
End;

Procedure RunCommand;
Var
 J:Integer;
 Err:Integer;
Begin
 If ArrayListCount(List)>0Then Begin
  CurrLinePtr:=1;
  While(CurrLinePtr<=ArrayListCount(List)) do Begin
   ArrayListSetPtr(List,CurrLinePtr-1);
   CurrLine:=Trim(ArrayListGetCurrStr(List));
   CurrNumberLine:=0;
   J:=1;
   While(J<Length(CurrLine))do Begin
    If Not(CurrLine[J]in['0'..'9'])Then Begin
     Val(Copy(CurrLine,1,J-1),CurrNumberLine,Err);
     If(Tron)Then Write('[',CurrNumberLine,']');
     Break;
    End;
    Inc(J);
   End;
   While J<=Length(CurrLine)do Begin
    If CurrLine[J]in[' ',#9]Then Inc(J)
                            Else Break;
   End;
   CurrPos:=J;
   If Not RunBasic(True)Then Break;
   Inc(CurrLinePtr);
  End;
 End;
End;

Procedure SaveCommand;
Var
 I:Integer;
 Target:Text;
 CurrLine:String;
Begin
 If GetSeparator='"'Then Begin
  FileName:=GetStringValue;
  If FileName=''Then Begin
   WriteLn('Sauvegarde avec un nom vide impossible');
   Exit;
  End;
  {$I-}Assign(Target,FileName);
  Rewrite(Target);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de creer le fichier');
   Exit;
  End;
  If ArrayListCount(List)>0Then Begin
   For I:=1 to ArrayListCount(List) do Begin
    ArrayListSetPtr(List,I-1);
    CurrLine:=ArrayListGetCurrStr(List);
   End;
  End;
  Close(Target);
 End
  Else
 Begin
  If FileName<>''Then Begin
   {$I-}Assign(Target,FileName);
   Rewrite(Target);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Impossible de creer le fichier');
    Exit;
   End;
   If ArrayListCount(List)>0Then Begin
    For I:=1 to ArrayListCount(List) do Begin
     ArrayListSetPtr(List,I-1);
     CurrLine:=ArrayListGetCurrStr(List);
     WriteLn(Target,CurrLine);
    End;
   End;
   Close(Target);
  End
   Else
  WriteLn('Sauvegarde sans nom impossible');
 End;
End;

Procedure SleepCommand;
Var
 N:Real;
Begin
 N:=GetNumberValue(1);
 Delay(Trunc(N*1000));
End;

Procedure TroffCommand;Begin
 Tron:=False;
End;

Procedure TronCommand;Begin
 Tron:=True;
End;

Function WidthCommand:Boolean;
Var
 Width:Real;
Begin
 WidthCommand:=True;
 Width:=GetNumberValue(1);
 Case Trunc(Width)of
  40:TextMode(C40);
  80:TextMode(C80);
  Else Begin
   WriteLn('Valeur invalide');
   WidthCommand:=False;
  End;
 End;
End;

Procedure ReadLine(Var S:String);
Var
 K:Char;
 Y:Byte;
Begin
 Y:=WhereY;
 S:='';
 Repeat
  GotoXY(1,Y);
  Write(S);
  ClrEol;
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #59:S:=S+FunctionKeyList[1]; { F1 }
    #60:S:=S+FunctionKeyList[2]; { F2 }
    #61:S:=S+FunctionKeyList[3]; { F3 }
    #62:S:=S+FunctionKeyList[4]; { F4 }
    #63:S:=S+FunctionKeyList[5]; { F5 }
    #64:S:=S+FunctionKeyList[6]; { F6 }
    #65:S:=S+FunctionKeyList[7]; { F7 }
    #66:S:=S+FunctionKeyList[8]; { F8 }
    #67:S:=S+FunctionKeyList[9]; { F9 }
    #68:S:=S+FunctionKeyList[10]; { F10 }
   End;
   #8:Begin
    If S<>''Then S:=Copy(S,1,Length(S)-1);
   End;
   Else S:=S+K;
  End;
  If S[Length(S)]=#13Then Begin
   S:=Copy(S,1,Length(S)-1);
   K:=#13;
  End;
 Until K=#13;
 GotoXY(1,Y);
 WriteLn(S);
End;

Function RunBasic(InList:Boolean):Boolean;
Var
 UnknownCommand:Boolean;
 NoImplementation:Boolean;
 J,Err:Integer;
 R1:Real;
 S1:String;
Begin
 RunBasic:=False;
 If Not(InList)Then Begin
  CurrPos:=1;
  J:=1;CurrNumberLine:=0;
  While(J<Length(CurrLine))do Begin
   If Not(CurrLine[J]in['0'..'9'])Then Begin
    Val(Copy(CurrLine,1,J-1),CurrNumberLine,Err);
    Break;
   End;
   Inc(J);
  End;
  If CurrNumberLine<>0Then Begin
   ArrayListAddStr(List,CurrLine);
   ResortList;
   Exit;
  End;
 End;
 Repeat
  NoImplementation:=False;
  UnknownCommand:=False;
  Case ExtractCommand of
   0: NoImplementation:=True;{AND}
   1: NoImplementation:=True;{AUTO}
   2: BeepCommand;{BEEP}
   3: NoImplementation:=True;{BLOAD}
   4: NoImplementation:=True;{BSAVE}
   5: NoImplementation:=True;{CALL}
   6: NoImplementation:=True;{CAT}
   7: NoImplementation:=True;{CHAIN}
   8: ChDirCommand;{CHDIR}
   9: NoImplementation:=True;{CIRCLE}
   10: NoImplementation:=True;{CLEAR}
   11: NoImplementation:=True;{CLOSE}
   12: NoImplementation:=True;{CLR}
   13: ClrScr;{CLS}
   14: ColorCommand;{COLOR}
   15: NoImplementation:=True;{COM}
   16: NoImplementation:=True;{COMMON}
   17: NoImplementation:=True;{CONT}
   18: NoImplementation:=True;{DATA}
   19: NoImplementation:=True;{DEF}
   20: NoImplementation:=True;{DELETE}
   21: NoImplementation:=True;{DIM}
   22: NoImplementation:=True;{DRAW}
   23: NoImplementation:=True;{EDIT}
   24: NoImplementation:=True;{ELSE}
   25: Exit;{END}
   26: NoImplementation:=True;{ERASE}
   27: NoImplementation:=True;{ERROR}
   28: NoImplementation:=True;{FIELD}
   29: FilesCommand;{FILES}
   30: If Not(ForCommand)Then Exit;{FOR}
   31: NoImplementation:=True;{GET}
   32: If Not(GosubCommand)Then Exit;{GOSUB}
   33: If Not(GotoCommand)Then Exit;{GOTO}
   34: HelpCommand;{HELP}
   35: IfCommand;{IF}
   36: NoImplementation:=True;{INPUT}
   37: KeyCommand;{KEY}
   38: NoImplementation:=True;{KILL}
   39: NoImplementation:=True;{LET}
   40: NoImplementation:=True;{LINE}
   41: ListCommand;{LIST}
   42: LListCommand;{LLIST}
   43: LoadCommand;{LOAD}
   44: LocateCommand;{LOCATE}
   45: NoImplementation:=True;{LPRINT}
   46: NoImplementation:=True;{LSET}
   47: NoImplementation:=True;{MERGE}
   48: MkDirCommand;{MKDIR}
   49: NoImplementation:=True;{NAME}
   50: NewCommand;{NEW}
   51: If Not(NextCommand)Then Exit;{NEXT}
   52: NoImplementation:=True;{ON}
   53: NoImplementation:=True;{OPEN}
   54: NoImplementation:=True;{OPTION}
   55: NoImplementation:=True;{OR}
   56: NoImplementation:=True;{OUT}
   57: NoImplementation:=True;{PAINT}
   58: NoImplementation:=True;{PALETTE}
   59: NoImplementation:=True;{POKE}
   60: NoImplementation:=True;{PLAY}
   61: NoImplementation:=True;{PRESET}
   62: PrintCommand;{PRINT}
   63: NoImplementation:=True;{PSET}
   64: NoImplementation:=True;{PUT}
   65: NoImplementation:=True;{RANDOMIZE}
   66: NoImplementation:=True;{READ}
   67: Begin
    RunBasic:=True;
    Exit;{REM}
   End;
   68: NoImplementation:=True;{RENUM}
   69: NoImplementation:=True;{RESET}
   70: NoImplementation:=True;{RESUME}
   71: NoImplementation:=True;{RESTORE}
   72: ReturnCommand;{RETURN}
   73: RmDirCommand;{RMDIR}
   74: NoImplementation:=True;{RSET}
   75: RunCommand;{RUN}
   76: SaveCommand;{SAVE}
   77: NoImplementation:=True;{SCREEN}
   78: NoImplementation:=True;{SHELL}
   79: SleepCommand;{SLEEP}
   80: Exit;{STOP}
   81: Begin {SYSTEM}
    Terminated:=True;
    Exit;
   End;
   82: NoImplementation:=True;{THEN}
   83: TroffCommand;{TROFF}
   84: TronCommand;{TRON}
   85: NoImplementation:=True;{VIEW}
   86: NoImplementation:=True;{WAIT}
   87: NoImplementation:=True;{WEND}
   88: NoImplementation:=True;{WHILE}
   89: If Not(WidthCommand)Then Break;{WIDTH}
   90: NoImplementation:=True;{WINDOW}
   91: NoImplementation:=True;{WRITE}
   Else UnknownCommand:=True;
  End;
  If(UnknownCommand)Then Begin
   SkipSpace;
   If CurrLine[CurrPos]='='Then Begin
    Case CurrCommand[Length(CurrCommand)]of
     '%':Begin
      R1:=GetNumberValue(1);
      If VariableExist(CurrCommand)Then
       SetVariableInt(CurrCommand,Trunc(R1))
      Else
       AddVariableInt(CurrCommand,Trunc(R1));
     End;
     '#','!':Begin
      R1:=GetNumberValue(1);
      If VariableExist(CurrCommand)Then
       SetVariableReal(CurrCommand,Trunc(R1))
      Else
       AddVariableReal(CurrCommand,Trunc(R1));
     End;
     '$':Begin
      Inc(CurrPos);
      S1:=GetStringValue;
      If VariableExist(CurrCommand)Then
       SetVariableString(CurrCommand,S1)
      Else
       AddVariableString(CurrCommand,S1);
     End;
     Else Begin
      R1:=GetNumberValue(1);
      If VariableExist(CurrCommand)Then
       SetVariableLongInt(CurrCommand,Trunc(R1))
      Else
       AddVariableLongInt(CurrCommand,Trunc(R1));
     End;
    End;
   End
    Else
   WriteLn('Commande non reconnu');
   Exit;
  End;
  If(NoImplementation)Then Begin
   WriteLn('Cette commande n''a pas ete implemente');
   Exit;
  End;
  While(CurrLine[CurrPos]in[' ',':'])and(CurrPos<=Length(CurrLine)) do Inc(CurrPos);
  If CurrPos>=Length(CurrLine)Then Break;
  If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z','_'])Then Begin
   If(InList)Then WriteLn('Erreur de syntaxe a la position ',CurrPos,' de la ligne ',CurrNumberLine)
             ELse WriteLn('Erreur de syntaxe a la position ',CurrPos);
   Exit;
  End;
 Until CurrPos>Length(CurrLine);
 RunBasic:=True;
End;

Procedure ShowMessage;Begin
 Box(1,18,40,24,$0B);
 FrameEmpty(1,18,40,24,$0B);
 TextColor(7);
 GotoXY(15,18);
 Write(' Message ');
End;

Procedure ShowRun;Begin
 Box(41,18,70,24,$0B);
 FrameEmpty(41,18,70,24,$0B);
 TextColor(7);
 GotoXY(51,18);
 Case Language of
  _English:Write(' Run ');
  Else Write(' Execution ');
 End;
End;

Procedure Init;Begin
 ShowMenu;
 ShowEditor;
 HomeMessage;
 Window(1,1,80,25);
 ShowMessage;
 ShowRun;
 ShowTrace;
 ShowFunctionsKey;
End;

Procedure Run;Begin
 RunEditor;
End;

Procedure Done;Begin
 Window(1,1,80,25);
 ClrScr;
End;

BEGIN
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
  WriteLn('TB : Cette commande permet de lancer le Turbo Basic.');
  WriteLn;
  WriteLn('Syntaxe : TB [fichier]');
 End
  Else
 Begin
  OnMenu:=False;
  ShowASCII128:=False;
  {$IFDEF FPC}
   {$IFDEF WINDOWS}
    SetUseACP(False);
   {$ELSE}
    ShowASCII128:=True;
   {$ENDIF}
  {$ENDIF}
  Modified:=False;
  InsMode:=True;
  P:=0;PX:=0;
  X:=0;Y:=0;
  FileName:='';
  FunctionKeyList[1]:='LIST ';
  FunctionKeyList[2]:='RUN'#13;
  FunctionKeyList[3]:='LOAD"';
  FunctionKeyList[4]:='SAVE"';
  FunctionKeyList[5]:='CONT'#13;
  FunctionKeyList[6]:=',"LPT1';
  FunctionKeyList[7]:='TRON'#13;
  FunctionKeyList[8]:='TROFF'#13;
  FunctionKeyList[9]:='KEY ';
  FunctionKeyList[10]:='SCREEN';
  Tron:=False;KeyFunction:=True;
  CurrNumberLine:=0;
  NumberVariable:=0;GosubPos:=0;ForPos:=0;
  For I:=1 to ParamCount do Begin
   FileName:=ParamStr(I);
  End;
  If FileName<>''Then LoadText(FileName);
  Init;
  Terminated:=False;
  Run;
  Done;
 End;
END.

