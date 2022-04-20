{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program HexView;

Uses Crt;

Var
 Finish:Boolean;
 FileView:File {$IFDEF FPC}of Byte{$ENDIF};
 ByteReaded:Word;
 FileName:String;
 Buffer:Array[0..1023]of Byte;
 CurrPos:LongInt;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

Procedure ViewFrame;
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
 GotoXY(8,3);
 Write('0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F  0123456789ABCDEF');
 For I:=0 to 9 do Begin
  GotoXY(I*7+1,25);
  Write('F',I+1);
 End;
End;

Procedure View16x16;
Var
 Pour,X,I,J:Byte;
 PosInBuffer:Word;
Begin
 If FileSize(FileView)=0Then Pour:=0
                        Else Pour:=Trunc((CurrPos / FileSize(FileView))*100);
 GotoXY(Lo(WindMax)-3,1);
 TextBackground(Cyan);
 TextColor(Black);
 Write(Pour:3,'%');
 TextBackground(Black);
 TextColor(LightGray);
 For J:=0 to 15 do Begin
  GotoXY(1,J+5);
  Write(HexWord2Str(CurrPos+J*16),' -');
  GotoXY(8,J+5);
  For I:=0 to 15 do Begin
   PosInBuffer:=(J shl 4)+I;
   X:=Buffer[PosInBuffer];
   If PosInBuffer>=ByteReaded Then Write('   ')
                              Else Write(ByteHex2Str(X),' ');
  End;
  For I:=0 to 15 do Begin
   PosInBuffer:=(J shl 4)+I;
   X:=Buffer[PosInBuffer];
   If PosInBuffer>=ByteReaded Then Write(' ') Else
   If X in[10,13]Then Write(' ')
                 Else Write(Char(X));
  End;
 End;
End;

BEGIN
 If ParamStr(1)='/?'Then Begin
  WriteLn('VIEWHEX - Cette commande permet de visualiser un fichier en hexadecimal');
  WriteLn;
  WriteLn('Syntaxe : VIEWHEX nomdufichier');
 End
  Else
 Begin
  FileName:=ParamStr(1);
  Assign(FileView,FileName);
  Reset(FileView,1);
  CurrPos:=0;
  ClrScr;
  ViewFrame;
  Finish:=False;
  Repeat
   Seek(fileView,CurrPos);
   BlockRead(FileView,Buffer,256,ByteReaded);
   View16x16;
   Case ReadKey Of
    #0:Case ReadKey of
     #1:Finish:=True;
     #68:Finish:=True; { F10 }
     #73:Begin {PageUp}
      If CurrPos>0 Then Dec(CurrPos,256);
     End;
     #81:Begin {PageDown}
      If CurrPos+256<FileSize(FileView)Then Inc(CurrPos,256);
     End;
    End;
    #27:Finish:=True;
   End;
  Until Finish;
  Close(FileView);
  ClrScr;
 End;
END.
