{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program DOSSHELL;

{$M 4096,0,65536}

Uses Crt,DOS;

Type
 ProgramRec=Record
  Command:String;
  Title:String[38];
  Help:String;
  Pause,Group:Boolean;
  Next:Pointer;
 End;

Var
 CurrZone,MenuPos,MenuY:Byte;
 ShowASCII128:Boolean;
 FileManager:Boolean;
 ProgramList:^ProgramRec;
 ProgramCount:Integer;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
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

Function TrimL(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If S[I]<>' 'Then Begin
   TrimL:=Copy(S,I,255);
   Exit;
  End;
 End;
 TrimL:=S;
End;

Function TrimR(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 TrimR:=S;
End;

Function Trim(S:String):String;Begin
 Trim:=TrimL(TrimR(S));
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

Function AddProgramList:Pointer;
Var
 P:^ProgramRec;
 CurrProgram:^ProgramRec;
Begin
 AddProgramList:=NIL;
 GetMem(P,SizeOf(ProgramRec));
 If P<>NIL Then Begin
  If(ProgramList=NIL)Then ProgramList:=P
   Else
  Begin
   CurrProgram:=ProgramList;
   While CurrProgram^.Next<>NIL do CurrProgram:=CurrProgram^.Next;
   If CurrProgram^.Next=NIL Then Begin
    CurrProgram^.Next:=P;
   End;
  End;
  Inc(ProgramCount);
  AddProgramList:=P;
 End;
End;

Procedure LoadDosShellIni;
Var
 CurrSection:(_None,_SaveState,_ProgramStarter);
 FileIni:Text;
 InProgram:Boolean;
 OpenAccol,Group:Integer;
 CurrLine,CurrWord,ResultValue:String;
 I:Integer;
 CurrProgram:ProgramRec;
 CurrPProgram:^ProgramRec;
Begin
 {$I-}Assign(FileIni,'DOSSHELL.INI');
 Reset(FileIni);{$I+}
 If IoResult=0Then Begin
  Group:=0;
  OpenAccol:=0;
  CurrSection:=_None;
  InProgram:=False;
  FillChar(CurrProgram,SizeOf(CurrProgram),0);
  CurrProgram.Next:=NIL;
  While Not EOF(FileIni)do Begin
   ReadLn(FileIni,CurrLine);
   CurrLine:=Trim(CurrLine);
   If StrToUpper(CurrLine)='[SAVESTATE]'Then CurrSection:=_SaveState Else
   If StrToUpper(CurrLine)='[PROGRAMSTARTER]'Then CurrSection:=_ProgramStarter Else
   If Trim(CurrLine)='{'Then Inc(OpenAccol) Else
   If Trim(CurrLine)='}'Then Begin
    If InProgram Then Begin
     CurrPProgram:=AddProgramList;
     If CurrPProgram<>NIL Then Begin
      Move(CurrProgram,CurrPProgram^,SizeOf(CurrProgram));
      FillChar(CurrProgram,SizeOf(CurrProgram),0);
      CurrProgram.Next:=NIL;
     End;
     InProgram:=False;
    End
     Else
    If Group>0Then Dec(Group);
    Dec(OpenAccol)
   End
    Else
   Begin
    CurrWord:='';
    I:=1;
    While(CurrLine[I]in['A'..'Z','a'..'z'])and(I<=Length(CurrLine))do Begin
     CurrWord:=CurrWord+CurrLine[I];
     Inc(I);
    End;
    While(CurrLine[I]in[' ',#9])and(I<=Length(CurrLine))do Inc(I);
    If CurrLine[I]='='Then Begin
     Inc(I);
     While(CurrLine[I]in[' ',#9])and(I<=Length(CurrLine))do Inc(I);
     ResultValue:=Copy(CurrLine,I,255);
     If(CurrSection=_ProgramStarter)Then Begin
      If(InProgram)Then Begin
       If StrToUpper(CurrWord)='COMMAND'Then CurrProgram.Command:=ResultValue Else
       If StrToUpper(CurrWord)='HELP'Then CurrProgram.Help:=ResultValue Else
       If StrToUpper(CurrWord)='PAUSE'Then Begin
        If StrToUpper(ResultValue)='ENABLED'Then CurrProgram.Pause:=True Else
        If StrToUpper(ResultValue)='DISABLED'Then CurrProgram.Pause:=False;
       End
        Else
       If StrToUpper(CurrWord)='TITLE'Then CurrProgram.Title:=ResultValue;
      End
       Else
      If StrToUpper(CurrWord)='GROUP'Then Inc(Group) Else
      If StrToUpper(CurrWord)='FILEMANAGER'Then Begin
       If StrToUpper(ResultValue)='ENABLED'Then FileManager:=True Else
       If StrToUpper(ResultValue)='DISABLED'Then FileManager:=False;
      End
       Else
      If StrToUpper(CurrWord)='PROGRAM'Then InProgram:=True;
     End;
    End;
   End;
  End;
  Close(FileIni);
 End;
End;

Procedure ShowTitle;Begin
 Box(1,1,80,1,$1F);
 GotoXY(30,1);
 Write('MS-DOS Shell Clone');
End;

Procedure ShowMenu;
Const
 MenuItem:Array[0..4]of String[10]=(
  'Fichier','Options','Vue','Arbre','Aide'
 );
 MenuPos:Array[0..High(MenuItem)]of Byte=(2,11,20,25,32);
Var
 I:Byte;
Begin
 Box(1,2,80,2,$30);
 For I:=0 to High(MenuItem) do Begin
  GotoXY(MenuPos[I],2);
  Write(MenuItem[I]);
 End;
End;

Procedure ShowPath;
Var
 Path:String;
Begin
 TextColor(0);
 TextBackground(7);
 GetDir(0,Path);
 GotoXY(1,3);
 Write(' ':2,Path);
 ClrEol;
End;

Procedure ShowDrive;
Var
 I:Char;
Begin
 Box(1,4,80,5,$70);
 TextColor(0);
 TextBackground(7);
 GotoXY(1,4);
 Write(' ');
 For I:='A' to 'Z'do Begin
  If(DiskSize(1+Ord(I)-Ord('A'))<>-1)Then Begin
   Write('[',I,':]');
   Write('  ');
  End;
 End;
 ClrEol;
End;

Procedure ShowFunctionKey;
Const
 FunctionKey:Array[0..1]of String[15]=(
  'F10=Actions','Shift+F9=Prompt de commande'
 );
Var
 I:Integer;
Begin
 TextColor(0);
 TextBackground($3);
 GotoXY(1,25);
 ClrEol;
 For I:=0 to High(FunctionKey) do Begin
  Write(' ',FunctionKey[I]);
 End;
End;

Procedure ShowDirectoryTreePanel;
Var
 ColorState:Byte;
Begin
 If CurrZone=1Then ColorState:=$1F
              Else ColorState:=$60;
 Box(1,6,40,15,$7F);
 FrameEmpty(1,6,40,15,$7F);
 Box(1,6,40,6,ColorState);
 GotoXY(12,6);
 Write('Arbre de repertoire');
End;

Procedure ShowFilesPanel;
Var
 Path:String;
 ColorState:Byte;
Begin
 If CurrZone=2Then ColorState:=$1F
              Else ColorState:=$60;
 Box(41,6,80,15,$7F);
 FrameEmpty(41,6,80,15,$7F);
 Box(41,6,80,6,ColorState);
 GetDir(0,Path);
 If Path[Length(Path)]<>'\'Then Path:=Path+'\';
 Path:=Copy(Path,1,36)+'*.*';
 GotoXY(60-(Length(Path) shr 1),6);
 Write(Path);
End;

Procedure ShowMainPanel;
Var
 StartY,Y,YP:Byte;
 CurrProgram:^ProgramRec;
 ColorState:Byte;
Begin
 If CurrZone=3Then ColorState:=$1F
              Else ColorState:=$60;
 StartY:=16;
 If Not(FileManager)Then StartY:=3;
 Box(1,StartY,40,24,$7F);
 FrameEmpty(1,StartY,40,24,$7F);
 Box(1,StartY,40,StartY,ColorState);
 GotoXY(16,StartY);
 Write('Principal');
 CurrProgram:=ProgramList;
 Y:=StartY+1;
 TextColor(0);
 TextBackground(7);
 YP:=0;
 If CurrProgram<>NIL Then Repeat
  If CurrZone=3 Then Begin
   If YP=MenuY Then Begin
    TextColor($F);
    TextBackground(1);
   End
    Else
   Begin
    TextColor(0);
    TextBackground($7);
   End;
  End;
  GotoXY(6,Y);
  Write(CurrProgram^.Title);
  If CurrProgram^.Next=NIL Then Break;
  CurrProgram:=CurrProgram^.Next;
  Inc(Y);
  Inc(YP);
 Until CurrProgram=NIL;
End;

Procedure SelectProgram;
Var
 StartY,Y:Byte;
 I:Integer;
 CurrProgram:^ProgramRec;
Begin
 StartY:=16;
 If Not(FileManager)Then StartY:=3;
 Y:=StartY+1+MenuY;
 TextColor($F);
 TextBackground(1);
 GotoXY(6,Y);
 CurrProgram:=ProgramList;
 If MenuPos>0 Then Begin
  I:=0;
  While I<=MenuPos do Begin
   If CurrProgram^.Next=NIL Then Break;
   CurrProgram:=CurrProgram^.Next;
   Inc(I);
  End;
 End;
 Write(CurrProgram^.Title);
End;

Procedure UnselectProgram;
Var
 StartY,Y:Byte;
 I:Integer;
 CurrProgram:^ProgramRec;
Begin
 StartY:=16;
 If Not(FileManager)Then StartY:=3;
 Y:=StartY+1+MenuY;
 TextColor(0);
 TextBackground($7);
 GotoXY(2,Y);
 CurrProgram:=ProgramList;
 If MenuPos>0 Then Begin
  I:=0;
  While I<=MenuPos do Begin
   If CurrProgram^.Next=NIL Then Break;
   CurrProgram:=CurrProgram^.Next;
   Inc(I);
  End;
 End;
 Write(' ':4,CurrProgram^.Title);
End;

Procedure ShowActiveTaskListPanel;
Var
 StartY:Byte;
 ColorState:Byte;
Begin
 If CurrZone=4Then ColorState:=$1F
              Else ColorState:=$60;
 StartY:=16;
 If Not(FileManager)Then StartY:=3;
 Box(41,StartY,80,24,$7F);
 FrameEmpty(41,StartY,80,24,$7F);
 Box(41,StartY,80,StartY,ColorState);
 GotoXY(50,StartY);
 Write('Liste de tache active');
End;

Procedure RefreshAll;Begin
 ShowTitle;
 ShowMenu;
 If(FileManager)Then Begin
  ShowPath;
  ShowDrive;
  ShowDirectoryTreePanel;
  ShowFilesPanel;
 End;
 ShowMainPanel;
 ShowActiveTaskListPanel;
 ShowFunctionKey;
End;

Procedure Init;Begin
 MenuPos:=0;
 MenuY:=0;
 CurrZone:=3;
 ProgramCount:=0;
 ProgramList:=NIL;
 FileManager:=True;
 LoadDosShellIni;
 RefreshAll;
End;

Procedure Run;
Var
 K:Char;
 OldZone:Byte;
 CurrProgram:^ProgramRec;
 I:Integer;
Begin
 Repeat
  K:=ReadKey;
  Case K of
   #9:Begin { Tab }
    OldZone:=CurrZone;
    If CurrZone=4 Then CurrZone:=1
                  Else CurrZone:=CurrZone+1;
    Case OldZone of
     1:ShowDirectoryTreePanel;
     2:ShowFilesPanel;
     3:ShowMainPanel;
     4:ShowActiveTaskListPanel;
    End;
    Case CurrZone of
     1:ShowDirectoryTreePanel;
     2:ShowFilesPanel;
     3:ShowMainPanel;
     4:ShowActiveTaskListPanel;
    End;
   End;
   #13:Begin { Enter }
    Case CurrZone of
     3:Begin
      CurrProgram:=ProgramList;
      If MenuPos>0 Then Begin
       I:=0;
       While I<=MenuPos do Begin
        If CurrProgram^.Next=NIL Then Break;
        CurrProgram:=CurrProgram^.Next;
        Inc(I);
       End;
      End;
      TextColor(7);
      TextBackground(0);
      ClrScr;
      Exec(CurrProgram^.Command,'');
      RefreshAll;
     End;
    End;
   End;
   #0:Begin
    K:=ReadKey;
    Case K of
     #72:Begin { Up }
      Case CurrZone of
       3:If MenuPos>0 Then Begin
        UnselectProgram;
        Dec(MenuPos);
        If MenuY>0Then Dec(MenuY);
        SelectProgram;
       End;
      End;
     End;
     #80:Begin { Down }
      Case CurrZone of
       3:If MenuPos<ProgramCount-1 Then Begin
        UnselectProgram;
        Inc(MenuPos);
        Inc(MenuY);
        SelectProgram;
       End;
      End;
     End;
    End;
   End;
  End;
 Until K=#27;
End;

Procedure Done;Begin
 TextBackground(0);
 TextColor(7);
 ClrScr;
 GotoXY(1,1);
End;

Var
 I:Integer;

BEGIN
 ShowASCII128:=False;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('DOSSHELL : Cette commande permet de lancer DOSSHELL.');
  WriteLn;
  WriteLn('Syntaxe : DOSSHELL [/ASCII128]');
  WriteLn;
  WriteLn(' /ASCII128   Ce parametre permet de lancer en mode compatibilite 128 caracteres seulement.');
  Halt;
 End;
 If ParamCount>0Then For I:=1 to ParamCount do Begin
  If StrToUpper(ParamStr(I))='/ASCII128'Then ShowASCII128:=True
   Else
  Begin
   WriteLn('Parametre non reconnu');
   Halt;
  End;
 End;
 Init;
 Run;
 Done;
END.