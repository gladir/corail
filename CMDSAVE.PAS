{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CMDSAVE;

{$IFDEF WINDOWS}
 Uses Windows;
{$ENDIF}

{$IFNDEF WINDOWS}
 Type
  TCharInfo=Packed Record
   Character:Char;
   Attribut:Byte;
  End;
  TScreenBuffer=Array[1..25, 1..80] of TCharInfo;
{$ENDIF}

Var
 I,J:Byte;
 FileCmdSave:Text;

{$IFDEF WINDOWS}
 Function GetCharXY(X,Y:Byte):Char;
 Var
  Coord:TCoord;
  C:Char;
  NumRead:Cardinal;
  StdOut:THandle;
 Begin
  StdOut:=GetStdHandle(STD_OUTPUT_HANDLE);
  Coord.X:=X-1;
  Coord.Y:=Y-1;
  ReadConsoleOutputCharacter(StdOut,@C,1,Coord,NumRead);
  GetCharXY:=C;
 End;
{$ELSE}
 Function GetCharXY(X,Y:Byte):Char;
 Var
  ScreenColor:TScreenBuffer Absolute $B800:$0000;
  ScreenMono:TScreenBuffer Absolute $B000:$0000;
 Begin
  GetCharXY:=ScreenColor[Y,X].Character;
 End;
{$ENDIF}

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CMDSAVE : Cette commande permet de sauvegarder le contenu de ',
                    'l''‚cran console dans le fichier sp‚cifi‚.');
  WriteLn;
  WriteLn('Syntaxe : CMDSAVE nomdufichier.txt');
  WriteLn;
  WriteLn(' nomdufichier.txt  Nom du fichier recevant le contenu.');
  WriteLn;
 End
  Else
 If ParamCount>0 Then Begin
  {$I-}Assign(FileCmdSave,ParamStr(1));
  Rewrite(FileCmdSave);{$I+}
  If IoResult=0 Then Begin
   For J:=1 to 25 do Begin
    For I:=1 to 80 do Begin
     Write(FileCmdSave,GetCharXY(I,J));
    End;
    WriteLn(FileCmdSave);
   End;
   Close(FileCmdSave);
  End
   Else
  WriteLn('Impossible d''‚crire dans le fichier : ',ParamStr(1));
 End
  Else
 Begin
  For J:=1 to 25 do For I:=1 to 80 do Begin
   Write(GetCharXY(I,J));
  End;
 End;
END.