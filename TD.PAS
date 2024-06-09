{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program TD; { TD.PAS, TEXTDRAW.PAS }

{$A-}

Uses Crt,DOS;

Const
  { Touche clavier }
 kbNoKey=0;{Pas de touche}
 kbDn=$5000;{Fleche Bas}
 kbEnter=$1C0D;{Enter}
 kbEsc=$011B;{Escape}
 kbShiftTab=$0F00;{Shift+Tabulation}
 kbTab=$0F09;{Tabulation}
 kbUp=$4800;{Fleche Haut}
 kbAltA=$1E00;{Alt+A}
 kbAltT=$1400;{Alt+T}

 FunctionKey:Array[1..16,1..10]of Char=(
  (#201,#187,#205,#186,#200,#188,#204,#185,#203,#202),
  (#218,#191,#196,#179,#192,#217,#195,#180,#194,#193),
  (#214,#183,#196,#186,#211,#189,#199,#182,#210,#208),
  (#213,#184,#205,#179,#212,#190,#198,#181,#209,#207),
  (#206,#197,#215,#216,#240,#247,#15, #14, #21, #19 ),
  (#176,#177,#178,#219,  #8, #10,#220,#223,#221,#222),
  (#254,#249,#250,#220,  #7,  #9,#127,#174,#175,#23 ),
  ( #16, #17, #30, #31, #26, #27, #24, #25, #29, #18),
  (  #1,  #2,  #3,  #4,  #5,  #6, #13, #14, #11, #12),
  (#248,#168,#173,#155,#156,#157,#158,#159,#218,#191),
  (#241,#242,#243,#251,#253,#252,#171,#172,#244,#245),
  (#224,#225,#226,#227,#228,#229,#230,#231,#232,#233),
  (#234,#235,#236,#237,#238,#239,#128,#135,#146,#145),
  (#131,#132,#133,#160,#134,#142,#143,#136,#137,#138),
  (#130,#144,#140,#130,#141,#161,#147,#148,#149,#162),
  (#153,#150,#129,#151,#163,#154,#152,#164,#165,#166)
 );

Type
 TextDrawHeader=Record
  Sign:Word;
  Rows,Columns:Byte;
  Fill:Array[4..23]of Byte;
 End;

Var
 ShowASCII128,Terminated:Boolean;
 C:Char;
 I,X,Y:Integer;
 CurrAttr,CurrFunctionKey:Byte;
 FileName:String;
 SaveMode:(NoneMode,AnsiMode,TextMode);
 Header:TextDrawHeader;
 Screen:Array[0..23,0..79,0..1]of Byte;

{$IFNDEF FPC}
 Procedure CursorOff;
 Var
  Regs:Registers;
 Begin
  Regs.AH:=1;
  Regs.CH:=32;
  Regs.CL:=0;
  Intr($10,Regs);
 End;

 Procedure CursorOn;
 Var
  Regs:Registers;
 Begin
  Regs.AX:=$0100;
  Regs.CX:=(7 shl 8)+9;
  Intr($10,Regs);
 End;
{$ENDIF}

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
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

Function Path2Ext(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2Ext:=E;
End;


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
 Window(1,1,80,25);
End;

Procedure WriteCenter(Y:Byte;S:String;Color:Byte);Begin
 If S=''Then Exit;
 TextColor(Color and $F);
 TextBackground(Color shr 4);
 GotoXY(40-(Length(S) shr 1),Y);
 Write(S);
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
  ChrHori:=#205;
  ChrVert:=#186;
  Chr218:=#201;
  Chr192:=#200;
  Chr191:=#187;
  Chr217:=#188;
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

Procedure DialogBox(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Box(X1,Y1,X2,Y2,Couleur);
 FrameEmpty(X1,Y1,X2,Y2,Couleur);
 TextAttr:=Couleur;
End;

Function ReadLine(Var S:String):Word;
Var
 Rec:SearchRec;
 K:Char;
 X,Y,I:Byte;
 CurrHistory:Integer;
Begin
 ReadLine:=0;
 X:=WhereX;
 Y:=WhereY;
 Repeat
  GotoXY(X,Y);
  Write(S);
  ClrEol;
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #20:Begin {Alt+T}
     ReadLine:=kbAltT;
     Exit;
    End;
    #30:Begin {Alt+A}
     ReadLine:=kbAltA;
     Exit;
    End;
    #72:Begin
     ReadLine:=kbUp;
     Exit;
    End;
    #80:Begin
     ReadLine:=kbDn;
     Exit;
    End;
   End;
   #8:Begin
    If S<>''Then S:=Copy(S,1,Length(S)-1);
   End;
   #9:Begin
    ReadLine:=kbTab;
    Exit;
   End;
   #13:Begin
    ReadLine:=kbEnter;
   End;
   #27:Begin
    ReadLine:=kbEsc;
    Exit;
   End;
   Else S:=S+K;
  End;
  If S[Length(S)]=#13Then Begin
   S:=Copy(S,1,Length(S)-1);
   K:=#13;
  End;
 Until K=#13;
 GotoXY(X,Y);
 WriteLn(S);
End;

Function ReadLineInBox(X1,Y1,X2,Y2:Byte;Var S:String):Word;Begin
 Window(X1,Y1,X2,Y2);
 ReadLineInBox:=ReadLine(S);
 Window(1,1,80,25);
End;

Procedure FrameFull(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Box(X1,Y1,X2,Y2,Couleur);
 FrameEmpty(X1+2,Y1+1,X2-2,Y2-1,Couleur);
End;

Procedure RefreshScreen;
Var
 I,J:Integer;
Begin
 GotoXY(1,1);
 For J:=0 to 23 do For I:=0 to 79 do Begin
  TextColor(Screen[J,I,1]and $F);
  TextBackground(Screen[J,I,1]shr 4);
  Write(Char(Screen[J,I,0]));
 End;
End;

Procedure ShowStatusBar;
Var
 I:Byte;
Begin
 TextColor(LightGray);
 TextBackground(Black);
 GotoXY(1,25);
 Write(PadZeroLeft(CurrFunctionKey,2),'   ');
 For I:=1 to 10 do Begin
  Write('F',I,':');
  Case FunctionKey[CurrFunctionKey,I]of
   #10,#13:Write(' ');
   Else Write(FunctionKey[CurrFunctionKey,I]);
  End;
  Write(' ');
 End;
 Write(' ':3,'Esc=Menu');
 ClrEol;
End;

Procedure Save;
Var
 FileScreen:File;
 FileScreenText:Text;
 ByteWrited:Word;
 I,J:Integer;
Begin
 Case SaveMode of
  TextMode:Begin
   If Path2Ext(FileName)=''Then FileName:=FileName+'.ANS';
   {$I-}Assign(FileScreenText,FileName);
   Rewrite(FileScreenText);{$I+}
   If IOResult=0 Then Begin
    For J:=0 to 23 do Begin
     For I:=0 to 79 do Begin
      Write(FileScreenText,Char(Screen[J,I,0]));
     End;
     WriteLn(FileScreenText);
    End;
    Close(FileScreenText);
   End;
  End;
  Else Begin
   If Path2Ext(FileName)=''Then FileName:=FileName+'.TD';
   {$I-}Assign(FileScreen,FileName);
   Rewrite(FileScreen,1);{$I+}
   If IOResult=0 Then Begin
    Header.Columns:=80;
    Header.Rows:=24;
    BlockWrite(FileScreen,Header,SizeOf(Header),ByteWrited);
    BlockWrite(FileScreen,Screen,SizeOf(Screen),ByteWrited);
    Close(FileScreen);
   End;
  End;
 End;
End;

Procedure SaveAs;
Var
 OldFileName:String;
Begin
 RefreshScreen;
 DialogBox(15,6,65,18,$70);
 CursorOn;
 GotoXY(17,7);
 Write('Sauvegarde sous:');
 GotoXY(20,10);
 Write('<Alt+A> GÇnäre un fichier ANSI');
 GotoXY(20,11);
 Write('<Alt+T> GÇnäre un fichier texte seulement');
 OldFileName:=FileName;
 TextColor(LightGray);
 TextBackground(Black);
 Case ReadLineInBox(17,8,63,8,FileName)of
  kbEsc:Begin
   FileName:=OldFileName;
   Exit;
  End;
  kbAltA:SaveMode:=AnsiMode;
  kbAltT:SaveMode:=TextMode;
 End;
 Save;
End;

Procedure Load;
Var
 FileScreen:File;
 ByteReaded:Word;
Begin
 {$I-}Assign(FileScreen,FileName);
 Reset(FileScreen,1);{$I+}
 If IOResult=0 Then Begin
  BlockRead(FileScreen,Header,SizeOf(Header),ByteReaded);
  BlockRead(FileScreen,Screen,SizeOf(Screen),ByteReaded);
  Close(FileScreen);
  X:=0;
  Y:=0;
  CurrAttr:=$07;
 End
  Else
 Begin
  TextColor(LightRed);
  GotoXY(20,12);
  Write('ERREUR DE LECTURE DU FICHIER ',FileName);
  ReadKey;
 End;
 RefreshScreen;
End;

Procedure LoadSelect;
Var
 Ok:Boolean;
 YFile,CurFile,MaxFile:Integer;
 SearchInfo:SearchRec;
 FileList:Array[0..49]of SearchRec;

 Procedure ShowItem;Begin
  TextBackground(Black);
  TextColor(LightGray);
  GotoXY(30,9+YFile);
  Write(PadRight(FileList[CurFile].Name,22));
 End;

 Procedure HideItem;Begin
  TextBackground(LightGray);
  TextColor(Black);
  GotoXY(30,9+YFile);
  Write(PadRight(FileList[CurFile].Name,22));
 End;

Begin
 MaxFile:=0;
 FindFirst('*.TD',AnyFile,SearchInfo);
 While DOSError=0 do Begin
  Move(SearchInfo,FileList[MaxFile],SizeOf(SearchRec));
  Inc(MaxFile);
  If MaxFile>High(FileList)Then Break;
  FindNext(SearchInfo);
 End;
 DialogBox(25,6,55,18,$70);
 GotoXY(27,7);
 Write('Charge :');
 For I:=0 to 7 do Begin
  GotoXY(30,9+I);
  Write(FileList[I].Name);
 End;
 CurFile:=0;
 YFile:=0;
 Ok:=False;
 ShowItem;
 Repeat
  Case ReadKey of
   #0:Case ReadKey of
    #72:Begin { Haut }
     If CurFile>0 Then Begin
      HideItem;
      Dec(CurFile);
      If YFile>0 Then Dec(YFile)
       Else
      Begin
       Window(30,9,51,16);
       GotoXY(1,1);
       InsLine;
       Window(1,1,80,25);
      End;
      ShowItem;
     End;
    End;
    #80:Begin { Bas }
     If CurFile<MaxFile-1 Then Begin
     HideItem;
     Inc(CurFile);
     If YFile<7 Then Inc(YFile)
      Else
     Begin
      Window(30,9,51,16);
      GotoXY(1,1);
      DelLine;
      Window(1,1,80,25);
     End;
     ShowItem;
     End;
    End;
   End;
   #27:Ok:=True;
   #13:Begin
    FileName:=FileList[CurFile].Name;
    Ok:=True;
   End;
  End;
 Until Ok;
End;

Procedure ClearScreen;Begin
 FillChar(Screen,SizeOf(Screen),0);
 For Y:=0 to 23 do For X:=0 to 79 do Begin
  Screen[Y,X,0]:=Byte(' ');
  Screen[Y,X,1]:=$07;
 End;
End;

Procedure New;Begin
 FileName:='';
 ClearScreen;
 RefreshScreen;
 X:=0;
 Y:=0;
 CurrAttr:=$07;
 GotoXY(1+X,1+Y);
End;

Procedure InsertChar(C:Char);Begin
 GotoXY(1+X,1+Y);
 Screen[Y,X,0]:=Byte(C);
 Screen[Y,X,1]:=CurrAttr;
 TextColor(CurrAttr and $F);
 TextBackground(CurrAttr shr 4);
 Write(C);
 TextColor(LightGray);
 TextBackground(Black);
 Inc(X);
 If X>=80 Then Begin
  X:=0;
  Inc(Y);
  If Y>=24 Then Y:=0;
 End;
End;

Procedure FileMenu;
Const
 MenuItem:Array[1..4]of String[15]=(
  'Chargement',
  'Nouveau',
  'Sauvegarde',
  'Sauvegarde sous'
 );
 CtrlKey:Array[1..4]of Char=('L','N','S','A');
Var
 I,CurPosition:Integer;
 Ok:Boolean;

 Procedure ShowItem;Begin
  TextBackground(Black);
  TextColor(LightGray);
  GotoXY(27,6+CurPosition);
  Write(' Ctrl+',CtrlKey[CurPosition],' ':2,PadRight(MenuItem[CurPosition],17));
 End;

 Procedure HideItem;Begin
  TextBackground(LightGray);
  TextColor(Black);
  GotoXY(27,6+CurPosition);
  Write(' Ctrl+',CtrlKey[CurPosition],' ':2,PadRight(MenuItem[CurPosition],17));
 End;

Begin
 RefreshScreen;
 DialogBox(25,6,55,18,$70);
 For I:=1 to 4 do Begin
  GotoXY(27,6+I);
  Write(' Ctrl+',CtrlKey[I],' ':2,PadRight(MenuItem[I],17));
 End;
 Ok:=False;
 CurPosition:=1;
 ShowItem;
 Repeat
  Case ReadKey of
   #0:Case ReadKey of
    #72:Begin { Haut }
     HideItem;
     If(CurPosition>1)Then Dec(CurPosition)
                      Else CurPosition:=4;
     ShowItem;
    End;
    #80:Begin { Bas }
     HideItem;
     If CurPosition>=4 Then CurPosition:=1
                       Else Inc(CurPosition);
     ShowItem;
    End;
   End;
   #13:Begin
    Case CurPosition of
     1:Begin
      LoadSelect;
      If FileName<>''Then Load;
     End;
     2:New;
     3:If FileName=''Then SaveAs
                     Else Save;
     4:SaveAs;
    End;
    Ok:=True;
   End;
   ^A:Begin
    SaveAs;
    Ok:=True;
   End;
   ^L:Begin
    LoadSelect;
    If FileName<>''Then Load;
    Ok:=True;
   End;
   ^N:Begin
    New;
    Ok:=True;
   End;
   ^S:Begin
    If FileName=''Then SaveAs
                  Else Save;
    Ok:=True;
   End;
   #27:Ok:=True;
  End;
 Until Ok;
End;

Procedure SetColorMenu;
Var
 Ok:Boolean;
 OldCurrAttr:Byte;

 Procedure ShowItem;Begin
  DialogBox(50,11,72,15,CurrAttr);
  GotoXY(52,13);
  Write('Couleur d''attribut');
 End;

Begin
 RefreshScreen;
 DialogBox(5,9,75,17,$70);
 GotoXY(7,11);
 Write('Utilisez '+#24+' et '+#25+' pour le premier plan');
 GotoXY(7,12);
 Write('Utilisez PgUp et PgDn pour l''arriäre-plan');
 GotoXY(7,14);
 Write('Appuyez sur '+#17+#196+#217+' pour accepter');
 GotoXY(7,15);
 Write('Appuyez sur ESC pour quitter sans modifier');
 OldCurrAttr:=CurrAttr;
 Ok:=False;
 ShowItem;
 Repeat
  Case ReadKey of
  #0:Case ReadKey of
    #72:Begin { Haut }
     CurrAttr:=(CurrAttr and $F0)+((CurrAttr-1) and $F);
     ShowItem;
    End;
    #73:Begin { PgUp }
     CurrAttr:=((CurrAttr-$10) and $F0)+(CurrAttr and $F);
     ShowItem;
    End;
    #80:Begin { Bas }
     CurrAttr:=(CurrAttr and $F0)+((CurrAttr+1) and $F);
     ShowItem;
    End;
    #81:Begin { PgDn }
     CurrAttr:=((CurrAttr+$10) and $F0)+(CurrAttr and $F);
     ShowItem;
    End;
   End;
   #13:Ok:=True;
   #27:Begin
    CurrAttr:=OldCurrAttr;
    Ok:=True;
   End;
  End;
 Until Ok;
End;

Procedure FunctionKeyMenu;
Var
 Ok:Boolean;
 OldCurrFunctionKey:Byte;
Begin
 RefreshScreen;
 DialogBox(1,9,80,15,$70);
 WriteCenter(11,'Utilisez '+#24+' et '+#25+' pour sÇlectionner les '+
                 'caractäres des touches de fonction',$70);
 WriteCenter(12,'Appuyez sur '+#17+#196+#217+' pour accepter, '+
                'appuyez sur ESC pour quitter sans modification',$70);
 Ok:=False;
 OldCurrFunctionKey:=CurrFunctionKey;
 Repeat
  Case ReadKey of
   #0:Case ReadKey of
    #72:Begin { Haut }
     If CurrFunctionKey>=16 Then CurrFunctionKey:=1
                            Else Inc(CurrFunctionKey);
     ShowStatusBar;
    End;
    #80:Begin { Bas }
     If CurrFunctionKey<=1 Then CurrFunctionKey:=16
                           Else Dec(CurrFunctionKey);
     ShowStatusBar;
    End;
   End;
   #13:Ok:=True;
   #27:Begin
    OK:=True;
    CurrFunctionKey:=OldCurrFunctionKey;
   End;
  End;
 Until Ok;
End;

Procedure MainMenu;
Const
 MenuItem:Array[1..10]of String[20]=(
  'Aide',
  'Menu de fichier',
  'Fixe les couleurs',
  'Touches de fonctions',
  'Menu de bloc',
  'Type de cadre',
  'Cadre',
  'Serpent',
  'Efface l''Çcran',
  'Quitter'
 );
Var
 I,CurPosition:Integer;
 Ok:Boolean;

 Procedure ShowItem;Begin
  TextBackground(Black);
  TextColor(LightGray);
  GotoXY(27,6+CurPosition);
  Write(' F',CurPosition,' ':2,PadRight(MenuItem[CurPosition],22));
 End;

 Procedure HideItem;Begin
  TextBackground(LightGray);
  TextColor(Black);
  GotoXY(27,6+CurPosition);
  Write(' F',CurPosition,' ':2,PadRight(MenuItem[CurPosition],22));
 End;

Begin
 CursorOff;
 DialogBox(25,6,55,18,$70);
 For I:=1 to 10 do Begin
  GotoXY(27,6+I);
  Write(' F',I,' ':2,MenuItem[I]);
 End;
 Ok:=False;
 CurPosition:=1;
 ShowItem;
 Repeat
  Case ReadKey of
   #0:Case ReadKey of
    #60:FileMenu; { F2 }
    #61:SetColorMenu; { F3 }
    #62:Begin { F4 }
     FunctionKeyMenu;
     Ok:=True;
    End;
    #67:Begin
     ClearScreen; { F9 }
     Ok:=True;
    End;
    #68:Begin
     Terminated:=True; { F10 }
     Ok:=True;
    End;
    #72:Begin { Haut }
     HideItem;
     If(CurPosition>1)Then Dec(CurPosition)
                      Else CurPosition:=10;
     ShowItem;
    End;
    #80:Begin { Bas }
     HideItem;
     If CurPosition>=10 Then CurPosition:=1
                        Else Inc(CurPosition);
     ShowItem;
    End;
   End;
   #13:Begin
    Case CurPosition of
     2:FileMenu;
     3:SetColorMenu;
     4:FunctionKeyMenu;
     9:ClearScreen;
     10:Terminated:=True;
    End;
    Ok:=True;
   End;
   #27:Ok:=True;
  End;
 Until Ok;
 RefreshScreen;
 CursorOn;
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('TD : Cette commande permet de lancer l''application Text Draw.');
  WriteLn;
  WriteLn('Syntaxe : TD [fichier]');
  WriteLn;
  WriteLn(' fichier   Ce paramätre permet d''indiquer le nom du fichier Ö Çditer.');
 End
  Else
 Begin
  ShowASCII128:=False;
  FileName:='';
  If ParamCount>0 Then For I:=1 to ParamCount do Begin
   FileName:=ParamStr(I);
  End;
  TextColor(LightGray);
  TextBackground(Black);
  ClrScr;
  ClearScreen;
  Terminated:=False;
  SaveMode:=AnsiMode;
  CurrFunctionKey:=1;
  CurrAttr:=$07;
  X:=0;
  Y:=0;
  ShowStatusBar;
  If FileName<>''Then Load;
  Repeat
   GotoXY(1+X,1+Y);
   C:=ReadKey;
   Case(C)of
    #0:Begin
     C:=ReadKey;
     Case C of
      #20:SaveMode:=TextMode; { Alt+T }
      #30:SaveMode:=AnsiMode; { Alt+A }
      #59..#68:InsertChar(FunctionKey[CurrFunctionKey,Byte(C)-59+1]);{ F1 Ö F10}
      #72:Begin { Haut }
       Dec(Y);
       If Y<0 Then Y:=23;
      End;
      #75:Begin
       Dec(X);
       If X<0 Then X:=79;
      End;
      #77:Begin
       Inc(X);
       If X>79 Then X:=0;
      End;
      #80:Begin { Bas }
       Inc(Y);
       If Y>=24 Then Y:=0;
      End;
     End;
    End;
    ' '..#255:InsertChar(C);
    #27:MainMenu;
    ^A:SaveAs;
    ^L:Begin
     LoadSelect;
     If FileName<>''Then Load;
    End;
    ^S:Begin
     If FileName=''Then SaveAs
                   Else Save;
    End;
    ^N:New;
   End;
  Until Terminated;
  TextColor(LightGray);
  TextBackground(Black);
  ClrScr;
  CursorOn;
 End;
END.
