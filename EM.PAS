{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program EM; { EM.PAS / EASYMENU.PAS }

{$M 16384,0,65556}

Uses Crt,Dos;

Var
 DoubleFrame:Boolean;
 ShowASCII128:Boolean;
 MaxScreenLine:Byte;
 I:Integer;
 MenuFileName:String;

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

Procedure PCopy(Source,Target:Byte);Begin
 {$IFNDEF FPC}
  Move(Mem[SegB800:Source*(MemW[$0040:$4A]*25*2)],Mem[SegB800:Target*(MemW[$0040:$4A]*25*2)],MemW[$0040:$4A]*25*2)
 {$ENDIF}
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

Function Replace(Source,Old,New:String):String;
Var
 P:LongInt;
Begin
 While Pos(Old,Source)<>0 do Begin
  P:=Pos(Old,Source);
  Delete(Source,P,Length(Old));
  Insert(New,Source,P);
 End;
 Replace:=Source;
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
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If Not(S[I]in[#9,' '])Then Begin
   LTrim:=Copy(S,I,255);
   Exit;
  End;
 End;
 LTrim:=S;
End;

Function Trim(S:String):String;Begin
 Trim:=LTrim(RTrim(S));
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
 Window(1,1,80,MaxScreenLine);
End;

Procedure Write1(X,Y,Caractere,Couleur:Byte);Begin
 GotoXY(X,Y);
 TextBackground((Couleur shr 4)and 15);
 TextColor(Couleur and 15);
 Write(Char(Caractere));
End;

Procedure WriteXY(X,Y:Byte;Phrase:String;Couleur:Byte);Begin
 TextBackground((Couleur shr 4)and 15);
 TextColor(Couleur and 15);
 GotoXY(X,Y);
 Write(Phrase);
End;

Procedure WriteChoice(X,Y:Byte;Phrase:String;Couleur1,Couleur2:Byte);Begin
 Write1(X,Y,Ord(Phrase[1]),Couleur1);
 WriteXY(X+1,Y,Copy(Phrase,2,255),Couleur2);
End;

Procedure WriteCenter(Y:Byte;Phrase:String;Couleur:Byte);Begin
 WriteXY(40-Length(Phrase) div 2,Y,Phrase,Couleur);
End;

Procedure FrameEmpty(X1,Y1,X2,Y2,Couleur:Byte);
Var
 Compteur:Byte;
 ChrHori,ChrVert:Char;
 Chr218,Chr192,Chr191,Chr217:Char;
Begin
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
  If(DoubleFrame)Then Begin
   ChrHori:=#205;
   ChrVert:=#186;
   Chr218:=#201;
   Chr192:=#200;
   Chr191:=#187;
   Chr217:=#188;
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
 End;
 For Compteur:=Y1+1 to Y2-1 do Begin
  Write1(X1,Compteur,Ord(ChrVert),Couleur);
  Write1(X2,Compteur,Ord(ChrVert),Couleur);
 End;
 WriteXY(X1+1,Y1,DuplicateString(ChrHori,X2-X1-1),Couleur);
 WriteXY(X1+1,Y2,DuplicateString(ChrHori,X2-X1-1),Couleur);
 Write1(X1,Y1,Ord(Chr218),Couleur);
 Write1(X1,Y2,Ord(Chr192),Couleur);
 Write1(X2,Y1,Ord(Chr191),Couleur);
 Write1(X2,Y2,Ord(Chr217),Couleur);
End;

Procedure DialogBox(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Box(X1,Y1,X2,Y2,Couleur);
 FrameEmpty(X1,Y1,X2,Y2,Couleur);
 TextAttr:=Couleur;
End;

Procedure FrameFull(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Box(X1,Y1,X2,Y2,Couleur);
 FrameEmpty(X1+2,Y1+1,X2-2,Y2-1,Couleur);
End;

Procedure FrameChoice(X1,Y1,X2,Y2:Byte);
Var
 I:Integer;
 ChrHori,ChrVert:Byte;
 Chr218,Chr192,Chr191,Chr217:Byte;
Begin
 If(ShowASCII128)Then Begin
  ChrHori:=Byte('-');
  ChrVert:=Byte('|');
  Chr218:=Byte('+');
  Chr192:=Byte('+');
  Chr191:=Byte('+');
  Chr217:=Byte('+');
 End
  Else
 Begin
  ChrHori:=$C4;
  ChrVert:=$B3;
  Chr218:=218;
  Chr192:=192;
  Chr191:=191;
  Chr217:=217;
 End;
 Box(X1,Y1,X2,Y2,63);
 Write1(X1,Y1,Chr218,63);
 Write1(X2,Y1,Chr191,63);
 Write1(X1,Y2,Chr192,63);
 Write1(X2,Y2,Chr217,63);
 For I:=X1+1 to X2-1 do Begin
  Write1(I,Y1,ChrHori,63);
  Write1(I,Y2,ChrHori,63);
 End;
 For I:=Y1+1 to Y2-1 do Begin
  Write1(X1,I,ChrVert,63);
  Write1(X2,I,ChrVert,63);
 End;
End;

Procedure ErrorOk(Msg:String);Begin
 CursorOff;
 FrameFull(11,10,71,17,$4F);
 WriteCenter(13,Msg,$40);
 WriteXY(39,15,' Ok ',$30);
 ReadKey;
 CursorOn;
End;

Procedure MenuFunc;
Const
 MaxMenu=39;
Type
 KeyRec=Record
  Letter:String[10];
  Key1,Key2:Byte;
 End;
 MenuRec=Record
  Letter:String[3];
  Name:String[50];
  Cmd:Array[0..3]of String[31];
 End;
Const
 KeyList:Array[0..9]of KeyRec=(
  (Letter:'F1';Key1:0;Key2:59),
  (Letter:'F2';Key1:0;Key2:60),
  (Letter:'F3';Key1:0;Key2:61),
  (Letter:'F4';Key1:0;Key2:62),
  (Letter:'F5';Key1:0;Key2:63),
  (Letter:'F6';Key1:0;Key2:64),
  (Letter:'F7';Key1:0;Key2:65),
  (Letter:'F8';Key1:0;Key2:66),
  (Letter:'F9';Key1:0;Key2:67),
  (Letter:'F10';Key1:0;Key2:68)
 );
Var
 Mode:(_None,_Letter,_Name,_Cmd);
 MenuFile:Text;
 Terminated:Boolean;
 Menu:Array[0..MaxMenu]of MenuRec;
 YMenu,PosMenu,NumMenu,WidthBox,HeightBox,X1,Y1,X2,Y2:Byte;
 SubCmd,I,J:Integer;
 K:Char;
 CurrLine,CurrWord:String;

 Procedure SelectMenu;Begin
  GotoXY(X1+2,Y1+2+YMenu);
  Write(Menu[PosMenu].Letter);
  TextBackground(0);
  GotoXY(X1+5,Y1+2+YMenu);
  Write(' ',PadRight(Copy(Menu[PosMenu].Name,1,50),WidthBox-10));
  TextBackground(Cyan);
 End;

 Procedure UnselectMenu;Begin
  GotoXY(X1+2,Y1+2+YMenu);
  Write(Menu[PosMenu].Letter);
  GotoXY(X1+5,Y1+2+YMenu);
  Write(' ',PadRight(Copy(Menu[PosMenu].Name,1,50),WidthBox-10));
 End;

 Procedure RunCmd;
 Var
  I:Integer;
 Begin
  Box(X1,Y1,X2,Y2,$07);
  PCopy(1,0);
  For I:=0 to 3 do Begin
   If Menu[PosMenu].Cmd[I]<>''Then Exec(GetEnv('COMSPEC'),'/C '+Menu[PosMenu].Cmd[I]);
  End;
 End;

Begin
 {$I-}Assign(MenuFile,MenuFileName);
 Reset(MenuFile);{$I+}
 If IOResult=0 Then Begin
  NumMenu:=0;
  FillChar(Menu,SizeOf(Menu),0);
  Mode:=_None;
  While Not EOF(MenuFile)do Begin
   ReadLn(MenuFile,CurrLine);
   If Copy(Trim(CurrLine),1,1)<>''''Then Begin
    CurrWord:='';
    If Mode in[_Letter,_Name]Then Begin
     Menu[NumMenu].Cmd[0]:=Trim(CurrLine);
     SubCmd:=1;
     Inc(NumMenu);
     If NumMenu>MaxMenu Then Break;
     Mode:=_None;
    End
     Else
    Begin
     If(Not(CurrLine[1]in[#9,' ']))and(Pos(':',CurrLine)>0)Then Begin
      For I:=1 to Length(CurrLine)do Begin
       If CurrLine[I]in[#9,' ']Then Begin
        If CurrWord[Length(CurrWord)]=':'Then Begin
         Menu[NumMenu].Letter:=Copy(CurrWord,1,Length(CurrWord)-1);
         CurrWord:='';
         Mode:=_Letter;
         SubCmd:=0;
        End
         Else
        CurrWord:=CurrWord+' ';
       End
        Else
       CurrWord:=CurrWord+CurrLine[I];
      End;
      Menu[NumMenu].Name:=Copy(Trim(CurrWord),1,50);
     End
      Else
     If(NumMenu>0)and(SubCmd in[1..3])Then Begin
      Menu[NumMenu-1].Cmd[SubCmd]:=Trim(CurrLine);
      Inc(SubCmd);
     End;
    End;
   End;
  End;
  Close(MenuFile);
  If NumMenu=0 Then ErrorOk('Aucun menu pr‚sent dans le fichier '+MenuFileName+' !')
   Else
  Begin
   PCopy(0,1);
   CursorOff;
   WidthBox:=20;
   HeightBox:=4+NumMenu;
   If HeightBox>20 Then HeightBox:=20;
   For I:=0 to NumMenu-1 do Begin
    If Length(Menu[I].Name)>WidthBox Then Begin
     WidthBox:=Length(Menu[I].Name);
     If WidthBox>50 Then WidthBox:=50;
    End;
   End;
   Inc(WidthBox,20);
   X1:=40-(WidthBox shr 1);
   Y1:=12-(HeightBox shr 1);
   X2:=40+(WidthBox shr 1);
   Y2:=12+(HeightBox shr 1);
   FrameChoice(X1,Y1,X2,Y2);
   For I:=0 to NumMenu-1 do Begin
    GotoXY(X1+2,Y1+2+I);
    Write(Menu[I].Letter);
    GotoXY(X1+5,Y1+2+I);
    Write(' ',Copy(Menu[I].Name,1,50));
   End;
   Terminated:=False;
   PosMenu:=0;
   YMenu:=0;
   SelectMenu;
   Repeat
    K:=ReadKey;
    Case UpCase(K)of
     #0:Begin
      K:=ReadKey;
      For J:=0 to NumMenu-1 do Begin
       For I:=0 to High(KeyList)do Begin
        If(StrToUpper(Menu[J].Letter)=StrToUpper(KeyList[I].Letter))and
          (KeyList[I].Key2=Ord(K))Then Begin
         PosMenu:=J;
         Terminated:=True;
         RunCmd;
         Break;
        End;
        If(Terminated)Then Break;
       End;
      End;
      Case K of
       #72:Begin { Up }
       If PosMenu>0 Then Begin
         UnselectMenu;
         Dec(PosMenu);
         If YMenu>0Then Dec(YMenu)
          Else
         Begin
          Window(X1+2,Y1+2,X2-2,Y2-2);
          InsLine;
          Window(1,1,80,MaxScreenLine);
         End;
         SelectMenu;
        End;
       End;
       #80:Begin { Down }
        If PosMenu<NumMenu-1 Then Begin
         UnselectMenu;
         Inc(PosMenu);
         If YMenu<20-4 Then Inc(YMenu)
          Else
         Begin
          Window(X1+2,Y1+2,X2-2,Y2-2);
          DelLine;
          Window(1,1,80,MaxScreenLine);
         End;
         SelectMenu;
        End;
       End;
      End;
     End;
     #13:Begin
      RunCmd;
      Terminated:=True;
     End;
     #27:Begin
      PCopy(0,1);
      Terminated:=True;
     End;
     'A'..'Z':Begin
      For J:=0 to NumMenu-1 do Begin
       If(StrToUpper(Menu[J].Letter)=StrToUpper(K))Then Begin
        PosMenu:=J;
        Terminated:=True;
        RunCmd;
        Break;
       End;
      End;
     End;
    End;
   Until Terminated;
   CursorOn;
  End;
 End
  Else
 ErrorOk('Fichier ®'+MenuFileName+'¯ non pr‚sent ou impossible … lire');
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('EM : Cette commande permet de lancer l''application Easy Menu.');
  WriteLn;
  WriteLn('Syntaxe : EM [fichier]');
  WriteLn;
  WriteLn(' fichier   Ce paramŠtre permet d''indiquer le nom du fichier de menu.');
 End
  Else
 Begin
  MenuFileName:='EM.DAT';
  MaxScreenLine:=25;
  ShowASCII128:=False;
  DoubleFrame:=True;
  If ParamCount>0 Then For I:=1 to ParamCount do Begin
   MenuFileName:=ParamStr(I);
  End;
  MenuFunc;
 End;
END.
