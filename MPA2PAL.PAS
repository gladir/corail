{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program MPA2PAL;

{$A-}

Var
 Pal:Array[0..255,1..3]of Byte;
 Z:Byte;
 FileSource,FileTarget:File;
 ByteReaded,ByteWrited:Word;

BEGIN
If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('MPA2PAL : Cette commande permet de convertir un fichier de ',
                   'palette de couleurs MPA (cartographi‚) en format ',
                   'PAL (24 bits).');
  WriteLn;
  WriteLn('Syntaxe : MPA2PAL source.MPA target.PAL');
 End
  Else
 If ParamCount=2 Then Begin
  FillChar(Pal,SizeOf(Pal),0);
  {$I-}Assign(FileSource,ParamStr(1));
  Reset(FileSource,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible d''ouvrir le fichier ',ParamStr(1));
   Halt(1);
  End;
  {$I-}Assign(FileTarget,ParamStr(2));
  Rewrite(FileTarget,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de cr‚er le fichier ',ParamStr(2));
   Halt(2);
  End;
  While Not EOF(FileSource)do Begin
   BlockRead(FileSource,Z,1,ByteReaded);
   BlockRead(FileSource,Pal[Z,1],3,ByteReaded);
  End;
  For Z:=0 to 255 do Begin
   BlockWrite(FileTarget,Pal[Z,1],3,ByteWrited);
  End;
  Close(FileSource);
  Close(FileTarget);
 End
  Else
 Begin
  WriteLn('Mauvais paramŠtres');
  Halt(3);
 End;
END.
