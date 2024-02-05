{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal (Windows))
}

Program GETCLIP;

{$IFDEF Windows}
 Uses Windows;
{$ELSE}
 Uses Strings;
{$ENDIF}

Const
  {Format du Presse-Papier Windows 9X}
 cfText=1;           { Texte }
 cfBitmap=2;         { Bitmap OEM }
 cfOemText=7;        { Texte OEM }
 cfDspText=$81;      { Format texte }
 cfDspBitmap=$82;    { Format dessin }

Var
 Data:PChar;
 Len:LongInt;

{$IFDEF FPC}
 Function Win9XClipboardFunctionsAvailable:Boolean;Begin
  {$IFDEF Windows}
   Win9XClipboardFunctionsAvailable:=True;
  {$ELSE}
   Win9XClipboardFunctionsAvailable:=False;
  {$ENDIF}
 End;

 Function Win9XClipboardCompact(lDesired:LongInt):LongInt;Begin
  Win9XClipboardCompact:=0;
 End;

 Function Win9XCloseClipboard:Boolean;Begin
  {$IFDEF Windows}
   Win9XCloseClipboard:=CloseClipboard;
  {$ELSE}
   Win9XCloseClipboard:=False;
  {$ENDIF}
 End;

 Function Win9XEmptyClipboard:Boolean;Begin
  {$IFDEF Windows}
   Win9XEmptyClipboard:=EmptyClipboard;
  {$ELSE}
   Win9XEmptyClipboard:=False;
  {$ENDIF}
 End;

 Function Win9XGetClipboardDataSize(wFormat:Word):LongInt;Begin
  {$IFDEF Windows}
   Win9XGetClipboardDataSize:=65500;
  {$ELSE}
   Win9XGetClipboardDataSize:=0;
  {$ENDIF}
 End;

 Function Win9XGetClipboardData(wFormat:Word;DataPtr:Pointer):Boolean;
 {$IFDEF Windows}
 Var
  Hdl:Handle;
  PChr:PChar Absolute Hdl;
 {$ENDIF}
 Begin
  {$IFDEF Windows}
   Hdl:=GetClipboardData(wFormat);
   Move(PChr^,DataPtr^,StrLen(PChr)+1);
   Win9XGetClipboardData:=True;
  {$ELSE}
   Win9XGetClipboardData:=False;
  {$ENDIF}
 End;

 Function Win9XOpenClipboard:Boolean;Begin
  {$IFDEF Windows}
   Win9XOpenClipboard:=OpenClipboard(GetActiveWindow);
  {$ELSE}
   Win9XOpenClipboard:=False;
  {$ENDIF}
 End;

 Function Win9XSetClipboardData(wFormat:Word;DataPtr:Pointer;lSize:LongInt):Boolean;Begin
  Win9XSetClipboardData:=False;
 End;
{$ELSE}
 Function Win9XClipboardFunctionsAvailable:Boolean;Assembler;ASM
  MOV AX,1700h
  INT 2Fh
  XOR BL,BL
  CMP AX,1700h
  JE  @1
  MOV BL,1
 @1:
  XCHG AX,BX
 END;

 Function Win9XClipboardCompact(lDesired:LongInt):LongInt;Assembler;ASM
  MOV AX,1709h
  LES CX,lDesired
  MOV SI,ES
  INT 2Fh
 END;

 Function Win9XCloseClipboard:Boolean;Assembler;ASM
  MOV AX,1708h
  INT 2Fh
  OR  AX,AX
  JE  @End
  MOV AL,1
 @End:
 END;

 Function Win9XEmptyClipboard:Boolean;Assembler;ASM
  MOV AX,1702h
  INT 2Fh
  OR  AX,AX
  JE  @End
  MOV AL,1
 @End:
 END;

 Function Win9XGetClipboardDataSize(wFormat:Word):LongInt;Assembler;ASM
  MOV AX,1704h
  MOV DX,wFormat
  INT 2Fh
 END;

 Function Win9XGetClipboardData(wFormat:Word;DataPtr:Pointer):Boolean;Assembler;ASM
  MOV AX,1705h
  MOV DX,wFormat
  LES BX,DataPtr
  INT 2Fh
  OR  AX,AX
  JE  @End
  MOV AL,1
 @End:
 END;

 Function Win9XOpenClipboard:Boolean;Assembler;ASM
  MOV AX,1701h
  INT 2Fh
  OR  AX,AX
  JE  @End
  MOV AL,1
 @End:
 END;

 Function Win9XSetClipboardData(wFormat:Word;DataPtr:Pointer;lSize:LongInt):Boolean;Begin
  Win9XSetClipboardData:=False;
  If(DataPtr<>Nil)and(lSize<>0)and(Win9XClipboardCompact(lSize)>=lSize)Then Begin
   ASM
    MOV AX,1703h
    MOV DX,wFormat
    LES CX,lSize
    MOV SI,ES
    LES BX,DataPtr
    INT 2Fh
    OR  AX,AX
    JE  @End
    MOV AL,1
@End:
    MOV @Result,AL
   END;
  End;
 End;
{$ENDIF}

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('GETCLIP : Cette commande permet d''afficher le ',
                    'contenu du presse-papier sur la console.');
  WriteLn;
  WriteLn('Syntaxe : GETCLIP [--help]');
  WriteLn;
  WriteLn(' --help                Affiche l''aide de cette commande');
 End
  Else
 Begin
  If(Win9XClipboardFunctionsAvailable)Then Begin
   If(Win9XOpenClipboard)Then Begin
    Len:=Win9XGetClipboardDataSize(cfOemText);
    If Len=0Then Halt
     Else
    Begin
     If Len<=65520Then Begin
      GetMem(Data,Len);
      If(Data<>NIL)Then Begin
       Win9XGetClipboardData(cfOemText,Data);
       WriteLn(StrPas(Data));
      End
       Else
      Begin
       WriteLn('Manque de m‚moire');
       Halt(1);
      End;
     End;
    End;
   End
    Else
   Begin
    WriteLn('Impossible d''ouvrir le presse-papier.');
    Halt(2);
   End;
  End
   Else
  Begin
   WriteLn('Les fonctionnalit‚s de presse-papier ne sont pas disponibles');
  End;
 End;
END.