{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program LESS;

Uses Crt;

Var
 Option:Set of (StartEOF);
 FirstTime,Finish:Boolean;
 FileView:File;
 ByteReaded:Word;
 I,CurrLinePos:Integer;
 FileName:String;
 Buffer:Array[0..2048]of Byte;
 LastPos,CurrPos,LenBuf:LongInt;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function GetLastPagePos(Var F:File):LongInt;
Var
 CurrLinePos:Integer;
 LastPos,CurrPos,LenBuf:LongInt;
 ByteReaded:Word;
Begin
 CurrPos:=FileSize(FileView);
 FillChar(Buffer,SizeOf(Buffer),0);
 LenBuf:=2048;
 CurrLinePos:=0;
 LastPos:=CurrPos-LenBuf;
 If LastPos<0Then Begin
  LenBuf:=2048+LastPos;
  LastPos:=0;
 End;
 Seek(fileView,LastPos);
 BlockRead(FileView,Buffer,LenBuf,ByteReaded);
 For I:=ByteReaded-1 downto 0do Begin
  Case Buffer[I]of
   13:Begin
    Inc(CurrLinePos);
    If CurrLinePos>=22Then Begin
     Break;
    End;
   End;
   10:;
  End;
 End;
 GetLastPagePos:=LastPos+I+1;
End;

Function ViewASCII:Integer;
Var
 X,I,J:Byte;
 PosInBuffer:Word;
Begin
 GotoXY(1,1);
 X:=1;
 J:=0;
 PosInBuffer:=0;
 While(J<24)and(PosInBuffer<2048)do Begin
  Case(Buffer[PosInBuffer])of
   13:Begin
    ClrEol;
    WriteLn;
    X:=1;
    Inc(J);
    If Buffer[PosInBuffer+1]=10Then Inc(PosInBuffer);
    If J=24Then Break;
   End;
   0..12,14..31:Begin
    Write(' ');
    Inc(X);
   End;
   Else Begin
    Inc(X);
    Write(Chr(Buffer[PosInBuffer]));
   End;
  End;
  If X=80Then Begin
   X:=1;
   Inc(J);
   If J=24Then Break;
  End;
  Inc(PosInBuffer);
 End;
 ViewASCII:=PosInBuffer;
End;

Procedure MoveBack;Begin
 FillChar(Buffer,SizeOf(Buffer),0);
 LenBuf:=2048;
 CurrLinePos:=0;
 LastPos:=CurrPos-LenBuf;
 If LastPos<0Then Begin
  LenBuf:=2048+LastPos;
  LastPos:=0;
 End;
 Seek(fileView,LastPos);
 BlockRead(FileView,Buffer,LenBuf,ByteReaded);
 For I:=ByteReaded-1 downto 0do Begin
  Case Buffer[I]of
   13:Begin
    Inc(CurrLinePos);
    If CurrLinePos>=24Then Begin
    Break;
   End;
   End;
   10:;
  End;
 End;
 CurrPos:=LastPos+I;
 If I>1Then Inc(CurrPos);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('LESS - Cette commande permet de visualiser un fichier de la fin vers le debut');
  WriteLn;
  WriteLn('Syntaxe : LESS nomdufichier');

  WriteLn('  --endoffile   Ce parametre permet d''indiquer qu''il faut partir de la fin'); End
  Else
 Begin
  Option:=[];
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='--endoffile')or(ParamStr(I)='-eof')Then Begin
    Include(Option,StartEOF);
   End
    Else
   FileName:=ParamStr(1);
  End;
  FirstTime:=True;
  Assign(FileView,FileName);
  Reset(FileView,1);
  ClrScr;
  TextBackground(7);
  TextColor(0);
  GotoXY(1,25);
  Write(FileName);
  TextBackground(0);
  TextColor(7);
  Finish:=False;
  If(StartEOF in Option)Then CurrPos:=GetLastPagePos(FileView)
                        Else CurrPos:=0;
  Repeat
   FillChar(Buffer,SizeOf(Buffer),0);
   Seek(fileView,CurrPos);
   BlockRead(FileView,Buffer,2048,ByteReaded);
   ByteReaded:=ViewASCII;
   If(FirstTime)Then GotoXY(1+Length(FileName),25)
                Else GotoXY(2,25);
   Case ReadKey Of
    #0:Case ReadKey of
     #71:CurrPos:=0; { Touche Home }
     #73:MoveBack; { Touche PgUp }
     #79:CurrPos:=GetLastPagePos(FileView); { Touche End }
     #81:Begin { Touche PageDown }
      If CurrPos+ByteReaded<=FileSize(FileView)Then Inc(CurrPos,ByteReaded);
     End;
    End;
    'q','Q',#27:Finish:=True;
    ' ':MoveBack;
   End;
   GotoXY(1,25);
   Write(':');
   ClrEol;
   FirstTime:=False;
  Until Finish;
  Close(FileView);
  ClrScr;
 End;
END.
