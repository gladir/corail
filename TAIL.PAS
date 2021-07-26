{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}


Program TAIL(Input,Output);

Var
 OptionFlag:(_None,_Lines,_Bytes);
 I,CurrLinePos,MaxBuffer,MaxLine:Integer;
 EndPos,CurrEndPos:LongInt;
 ByteReaded:Integer;
 NumLine,Err:Word;
 FindEnd:Boolean;
 FileView:File of Byte;
 Buffer:Array[0..255]of Byte;
 FileName,CurrLine:String;

BEGIN
 OptionFlag:=_None;
 MaxLine:=10;
 MaxBuffer:=32767;
 FileName:='';
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('TAIL : Cette commande permet d''afficher la fin du fichier.');
  WriteLn;
  WriteLn('Syntaxe : TAIL [--lines lignes] [--bytes octets] nomdufichier');
 End
  Else
 If ParamCount > 0 Then Begin
  For I:=1 to ParamCount do Begin
   If OptionFlag<>_None Then Begin
    Case OptionFlag of
     _Lines:Val(ParamStr(I),MaxLine,Err);
     _Bytes:Val(ParamStr(I),MaxBuffer,Err);
    End;
    OptionFlag:=_None;
   End
    Else
   If ParamStr(I)='--lines'Then OptionFlag:=_Lines Else
   If ParamStr(I)='--bytes'Then OptionFlag:=_Bytes Else
   If Copy(ParamStr(I),1,8)='--bytes='Then Begin
    Val(Copy(ParamStr(I),9,255),MaxBuffer,Err);
   End
    Else
   If Copy(ParamStr(I),1,8)='--lines='Then Begin
    Val(Copy(ParamStr(I),9,255),Maxline,Err);
   End
    Else
   If((Length(ParamStr(I))>=2) and (ParamStr(I)[1]='-')and(ParamStr(I)[2] in['0'..'9']))Then Begin
    Val(Copy(ParamStr(I),2,255),MaxLine,Err);
   End
    Else
   Begin
    FileName:=ParamStr(I);
    OptionFlag:=_None;
   End;
  End;
  CurrLinePos:=0;
  {$I-}Assign(FileView,FileName);
  Reset(FileView);{$I+}
  If IOResult<>0Then Begin
   WriteLn('Fichier introuvable ou impossible a lire !');
   Halt;
  End;
  EndPos:=FileSize(FileView);
  NumLine:=0;FindEnd:=False;
  If MaxBuffer<>32767Then Begin
   Dec(EndPos,MaxBuffer);
   If EndPos < 0Then EndPos:=0;
   MaxLine := 1000;
  End
   Else
  Repeat
   CurrEndPos:=EndPos-SizeOf(Buffer);
   If CurrEndPos<0Then CurrEndPos:=0;
   Seek(FileView,CurrEndPos);
   BlockRead(FileView,Buffer,SizeOf(Buffer),ByteReaded);
   If ByteReaded<=0Then Break;
   For I:=ByteReaded-1 downto 0do Begin
    If Buffer[I]=10Then Begin
     Inc(NumLine);
     If NumLine>MaxLine Then Begin
      Dec(EndPos,SizeOf(Buffer)-I);
      FindEnd:=True;
      Break;
     End;
    End;
   End;
   If(FindEnd)Then Break;
   Dec(EndPos,ByteReaded);
  Until EndPos<=0;
  Seek(FileView,EndPos);
  While Not EOF(FileView)do Begin
   BlockRead(FileView,Buffer,SizeOf(Buffer),ByteReaded);
   If ByteReaded=0Then Break;
   For I:=0 to ByteReaded-1 do Begin
    Case Buffer[I]of
     13:Begin
      Inc(CurrLinePos);
      WriteLn;
     End;
     10:;
     Else Write(Char(Buffer[I]));
    End;
   End;
   If CurrLinePos>=MaxLine Then Break;
  End;
  Close(FileView);
 End
  Else
 WriteLn('Parametre requis !');
END.