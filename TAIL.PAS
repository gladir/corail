{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}


Program TAIL(Input,Output);

Uses DOS;

Var
 OptionFlag:(_None,_Lines,_Bytes);
 ForceCheck:Boolean;
 I,CurrLinePos,MaxBuffer,MaxLine:Integer;
 EndPos,CurrEndPos:LongInt;
 ByteReaded:Integer;
 NumLine,Err:Word;
 FindEnd:Boolean;
 FileView:File{$IFDEF FPC}of Byte{$ENDIF};
 Buffer:Array[0..255]of Byte;
 Info:SearchRec;
 FileName,CurrLine,CurrParam:String;

BEGIN
 OptionFlag:=_None;
 MaxLine:=10;
 MaxBuffer:=32767;
 ForceCheck:=False;
 FileName:='';
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('TAIL : Cette commande permet d''afficher la fin du fichier.');
  WriteLn;
  WriteLn('Syntaxe : TAIL [--lines lignes] [--bytes octets] [-f] nomdufichier');
  WriteLn;
  WriteLn('             -f  Ce parametre permet de forcer la surveiller de ',
                            'la fin du fichier sans arret.');
  WriteLn(' --lines lignes  Ce parametre permet d''indiquer le nombre de ',
                            'ligne a lire.');
  WriteLn(' --bytes octets  Ce parametre permet d''indiquer le nombre ',
                            'd''octets a lire.');
 End
  Else
 If ParamCount > 0 Then Begin
  For I:=1 to ParamCount do Begin
   CurrParam:=ParamStr(I);
   If OptionFlag<>_None Then Begin
    Case OptionFlag of
     _Lines:Val(CurrParam,MaxLine,Err);
     _Bytes:Val(CurrParam,MaxBuffer,Err);
    End;
    OptionFlag:=_None;
   End
    Else
   If CurrParam='-f'Then ForceCheck:=True Else
   If CurrParam='--lines'Then OptionFlag:=_Lines Else
   If CurrParam='--bytes'Then OptionFlag:=_Bytes Else
   If Copy(CurrParam,1,8)='--bytes='Then Begin
    Val(Copy(CurrParam,9,255),MaxBuffer,Err);
   End
    Else
   If Copy(CurrParam,1,8)='--lines='Then Begin
    Val(Copy(CurrParam,9,255),Maxline,Err);
   End
    Else
   If((Length(CurrParam)>=2) and (CurrParam[1]='-')and(CurrParam[2] in['0'..'9']))Then Begin
    Val(Copy(CurrParam,2,255),MaxLine,Err);
   End
    Else
   Begin
    FileName:=ParamStr(I);
    OptionFlag:=_None;
   End;
  End;
  CurrLinePos:=0;
  {$I-}Assign(FileView,FileName);
  Reset(FileView{$IFNDEF FPC},1{$ENDIF});{$I+}
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
  If(ForceCheck)Then Begin
   Repeat
    FindFirst(FileName,AnyFile,Info);
    If(DosError=0)and(Info.Size>EndPos)Then Begin
     {$I-}Assign(FileView,FileName);
     If(ForceCheck)Then FileMode:=0 + $30 + $80; { Fixe le mode Lecture seulement + Partage }
     Reset(FileView{$IFNDEF FPC},1{$ENDIF});{$I+}
     Seek(FileView,EndPos);
     BlockRead(FileView,Buffer,SizeOf(Buffer),ByteReaded);
     If ByteReaded>0Then For I:=0 to ByteReaded-1 do Begin
      Case Buffer[I]of
       13:Begin
        Inc(CurrLinePos);
        WriteLn;
       End;
       10:;
       Else Write(Char(Buffer[I]));
      End;
     End;
     Inc(EndPos,ByteReaded);
     Close(FileView);
    End;
   Until True=False;
  End;
 End
  Else
 WriteLn('Parametre requis !');
END.
