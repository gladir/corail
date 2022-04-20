{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}


Program WIPEINFO;

Var
 I,ByteReaded:Integer;
 CurrPos:LongInt;
 FileName:String;
 FileToErase:File{$IFDEF FPC}of Byte{$ENDIF};
 Buffer:Array[0..511]of Byte;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('WIPEINFO : Cette commande permet d''effacer totalement les donnees et le fichier.');
  WriteLn;
  WriteLn('Syntaxe : WILEINFO fichiers');
 End
  Else
 If ParamCount>0Then Begin
  FileName:=ParamStr(1);
  {$I-}Assign(FileToErase,ParamStr(1));
  Reset(FileToErase);{$I+}
  If IoResult=0Then Begin
   CurrPos:=0;
   Repeat
    Seek(FileToErase,CurrPos);
    BlockRead(FileToErase,Buffer,SizeOf(Buffer),ByteReaded);
    For I:=0 to High(Buffer)do Buffer[I]:=Random(255);
    Seek(FileToErase,CurrPos);
    BlockWrite(FileToErase,Buffer,ByteReaded);
    Inc(CurrPos,ByteReaded);
   Until CurrPos>=FileSize(FileToErase);
  End;
  Close(FileToErase);
  {$I-}
  Erase(FileToErase);
  {$I+}
  If IoResult=0Then WriteLn('Le fichier ',FileName,' est d‚truit.')
               Else WriteLn('Erreur de destruction du fichier');
 End;
END.
