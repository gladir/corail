{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program HexIt;

Uses Crt;

Const
 ViewHeight=$15;
 BlockSize=16*ViewHeight;

Var
 Finish:Boolean;
 FileView:File {$IFDEF FPC}of Byte{$ENDIF};
 ByteReaded:Word;
 FileName:String;
 Buffer:Array[0..1023]of Byte;
 CurrPos,_FileSize:LongInt;
 X,Y:Byte;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function ByteBinary2Str(value:Byte):String;
Var
 S:String;
 I:Byte;
Begin
 S:='';
 For I:=0 to 7 do Begin
  If value and 1=1 Then S:='1'+S
                   Else S:='0'+S;
  value:=value shr 1;
 End;
 ByteBinary2Str:=S;
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

Function LongHex2Str(value:LongInt):String;
Begin
 LongHex2Str:=ByteHex2Str((value shr 24)and $FF)+
              ByteHex2Str((value shr 16)and $FF)+
              ByteHex2Str((value shr 8)and $FF)+
              ByteHex2Str(value and $FF);
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
 GotoXY(1,1);
 TextBackground(Blue);
 TextColor(LightGray);
 ClrEol;
 Write('S‚lection: ',LongHex2Str(0),'h');
 GotoXY(24,1);
 Write('-= HexIt Clone =-');
 If FileSize(FileView)=0Then Pour:=0
                        Else Pour:=Trunc((CurrPos / FileSize(FileView))*100);
 TextBackground(Red);
 TextColor(LightGray);
 GotoXY(1,2);
 ClrEol;
 GotoXY(36,2);
 Write(FileName);
 TextColor(Black);
 TextBackground(Cyan);
 GotoXY(29,2);
 Write(Pour:3,'%');
 For I:=0 to 8 do Begin
  GotoXY(I*7+1+2,25);
  Write(PadRight(FunctionKeyValue[I],6));
 End;
 GotoXY(67,25);
 Write(FunctionKeyValue[9]);
 ClrEol;
 TextBackground(Black);
 GotoXY(1,3);
 TextColor(LightBlue);
 Write('<Active>');
 TextColor(Blue);
 GotoXY(12,3);
 For I:=0 to 15 do Begin
  Write(ByteHex2Str(I),' ');
   If I and 3=3 Then Write(' ');
 End;
 Write(' 0123456789ABCDEF');
 TextColor(LightGray);
 For I:=0 to 9 do Begin
  GotoXY(I*7+1,25);
  Write('F',I+1);
 End;
End;

Procedure ShowPosition;Begin
 TextBackground(Red);
 TextColor(LightGray);
 GotoXY(1,2);
 Write(LongHex2Str(CurrPos+(Y shl 4)),'/',LongHex2Str(_FileSize),'  Hex');
End;

Procedure View16x16;
Var
 Pour,X,I,J:Byte;
 PosInBuffer:Word;
Begin
 If FileSize(FileView)=0Then Pour:=0
                        Else Pour:=Trunc((CurrPos / FileSize(FileView))*100);
 ShowPosition;
 GotoXY(29,2);
 Write(Pour:3,'%');
 TextBackground(Black);
 TextColor(LightGray);
 GotoXY(1,4);
 For J:=0 to ViewHeight-1 do Begin
  TextColor(Blue);
  Write(LongHex2Str(CurrPos+J*16),' ':3);
  TextColor(LightGray);
  For I:=0 to 15 do Begin
   PosInBuffer:=(J shl 4)+I;
   X:=Buffer[PosInBuffer];
   If PosInBuffer>=ByteReaded Then Write('   ')
                              Else Write(ByteHex2Str(X),' ');
   If I and 3=3 Then Write(' ');
  End;
  Write(' ');
  For I:=0 to 15 do Begin
   PosInBuffer:=(J shl 4)+I;
   X:=Buffer[PosInBuffer];
   If PosInBuffer>=ByteReaded Then Write(' ') Else
   If X in[10,13]Then Write(' ')
                 Else Write(Char(X));
  End;
 End;
End;

Procedure ShowCharacter;Begin
 TextBackground(Red);
 TextColor(LightGray);
 GotoXY(63,2);
 Write(ShortInt(Buffer[X+(Y shl 4)]):4,' ',Buffer[X+(Y shl 4)]:3,' ',
       ByteBinary2Str(Buffer[X+(Y shl 4)]));
End;

Procedure SelectX;Begin
 TextBackground(Black);
 TextColor(LightCyan);
 GotoXY(12+X*3+(X shr 2),3);
 Write(ByteHex2Str(X));
End;

Procedure UnselectX;Begin
 TextBackground(Black);
 TextColor(Blue);
 GotoXY(12+X*3+(X shr 2),3);
 Write(ByteHex2Str(X));
End;

Procedure SelectY;Begin
 TextBackground(Black);
 TextColor(LightBlue);
 GotoXY(1,4+Y);
 Write(LongHex2Str(CurrPos+Y*16),' ':3);
End;

Procedure UnselectY;Begin
 TextBackground(Black);
 TextColor(Blue);
 GotoXY(1,4+Y);
 Write(LongHex2Str(CurrPos+Y*16),' ':3);
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If ParamStr(1)='/?'Then Begin
  WriteLn('HEXIT - Cette commande permet de visualiser un fichier en hexad‚cimal');
  WriteLn;
  WriteLn('Syntaxe : HEXIT nomdufichier');
 End
  Else
 If ParamCount>0 Then Begin
  FileName:=ParamStr(1);
  {$I-}Assign(FileView,FileName);
  Reset(FileView,1);{$I+}
  If IoResult<>0 Then Begin
   WriteLn('Impossible d''ouvrir le fichier : ',FileName);
   Halt;
  End;
  _FileSize:=FileSize(FileView);
  X:=0;Y:=0;
  CurrPos:=0;
  ClrScr;
  ViewFrame;
  Finish:=False;
  Seek(fileView,CurrPos);
  BlockRead(FileView,Buffer,BlockSize,ByteReaded);
  View16x16;
  SelectX;
  SelectY;
  Repeat
   ShowCharacter;
   GotoXY(12+X*3+(X shr 2),4+Y);
   Case ReadKey Of
    #0:Case ReadKey of
     #1:Finish:=True;
     #68:Finish:=True; { F10 }
     #72:Begin {Up}
      If Y>0 Then Begin
       UnselectY;
       Dec(Y);
       SelectY;
      End;
      ShowPosition;
     End;
     #73:Begin {PageUp}
      If CurrPos>0 Then Dec(CurrPos,BlockSize);
      Seek(fileView,CurrPos);
      BlockRead(FileView,Buffer,BlockSize,ByteReaded);
      View16x16;
     End;
     #75:Begin { Left }
      If X>0 Then Begin
       UnselectX;
       Dec(X);
       SelectX;
      End;
     End;
     #77:Begin { Right }
      If X<15 Then Begin
       UnselectX;
       Inc(X);
       SelectX;
      End;
     End;
     #80:Begin {Down}
      If Y<ViewHeight-1 Then Begin
       UnselectY;
       Inc(Y);
       SelectY;
      End;
      ShowPosition;
      SelectX;
      SelectY;
     End;
     #81:Begin {PageDown}
      If CurrPos+BlockSize<FileSize(FileView)Then Inc(CurrPos,BlockSize);
      Seek(fileView,CurrPos);
      BlockRead(FileView,Buffer,BlockSize,ByteReaded);
      View16x16;
      SelectX;
      SelectY;
     End;
    End;
    #27:Finish:=True;
   End;
  Until Finish;
  Close(FileView);
  TextBackground(Black);
  TextColor(LightGray);
  ClrScr;
 End
  Else
 WriteLn('Nom de fichier requis !');
END.