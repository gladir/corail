{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program VIEWASC;

Uses Crt;

Var
 Finish:Boolean;
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

Procedure ViewFrameASCII;
Const
 FunctionKeyValue:Array[0..9]of String[7]=(
  '','','','','','','','','','Sortir'
 );
Var
  I:Byte;
  Pour:Byte;
Begin
 If FileSize(FileView)=0Then Pour:=0
                        Else Pour:=Trunc((CurrPos / FileSize(FileView))*100);
 GotoXY(1,1);
 TextBackground(Cyan);
 TextColor(Black);
 Write(FileName);
 ClrEol;
 GotoXY(Lo(WindMax)-3,1);
 Write(Pour:3,'%');
 For I:=0 to 8 do Begin
  GotoXY(I*7+1+2,25);
  Write(PadRight(FunctionKeyValue[I],6));
 End;
 GotoXY(67,25);
 Write(FunctionKeyValue[9]);
 ClrEol;
 TextBackground(Black);
 TextColor(LightGray);
 For I:=0 to 9 do Begin
  GotoXY(I*7+1,25);
  Write('F',I+1);
 End;
End;

Function ViewASCII:Integer;
Var
 Pour,X,I,J:Byte;
 PosInBuffer:Word;
Begin
 If FileSize(FileView)=0Then Pour:=0
                        Else Pour:=Trunc((CurrPos / FileSize(FileView))*100);
 If Pour>=99Then Pour:=100;
 GotoXY(Lo(WindMax)-3,1);
 TextBackground(Cyan);
 TextColor(Black);
 Write(Pour:3,'%');
 TextBackground(Black);
 TextColor(LightGray);
 GotoXY(1,2);
 X:=1;
 J:=0;
 PosInBuffer:=0;
 While(J<23)and(PosInBuffer<2048)do Begin
  Case(Buffer[PosInBuffer])of
   13:Begin
    ClrEol;
    WriteLn;
    X:=1;
    Inc(J);
    If Buffer[PosInBuffer+1]=10Then Inc(PosInBuffer);
    If J=23Then Break;
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
   If J=23Then Break;
  End;
  Inc(PosInBuffer);
 End;
 If J<23Then Begin
  Window(1,1+J,80,22);
  ClrScr;
  Window(1,1,80,25);
 End;
 ViewASCII:=PosInBuffer;
End;

BEGIN
If ParamStr(1)='/?'Then Begin
  WriteLn('VIEWASC - Cette commande permet de visualiser un fichier ASCII');
  WriteLn;
  WriteLn('Syntaxe : VIEWASC nomdufichier');
 End
  Else
 Begin
  FileName:=ParamStr(1);
  Assign(FileView,FileName);
  Reset(FileView,1);
  CurrPos:=0;
  ClrScr;
  ViewFrameASCII;
  Finish:=False;
  Repeat
   FillChar(Buffer,SizeOf(Buffer),0);
   Seek(fileView,CurrPos);
   BlockRead(FileView,Buffer,2048,ByteReaded);
   ByteReaded:=ViewASCII;
   Case ReadKey Of
    #0:Case ReadKey of
     #1:Finish:=True;
     #68:Finish:=True; { F10 }
     #71:CurrPos:=0; { Touche Home }
     #73:Begin {PageUp}
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
     #79:CurrPos:=GetLastPagePos(FileView); { Touche End }
     #81:Begin {PageDown}
      If CurrPos+ByteReaded<=FileSize(FileView)Then Inc(CurrPos,ByteReaded);
     End;
    End;
    #27:Finish:=True;
   End;
  Until Finish;
  Close(FileView);
  ClrScr;
 End;
END.