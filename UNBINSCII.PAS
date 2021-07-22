{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program UNBINSCII;

Var
 FirstTime,Match:Boolean;
 Size,Last,Limit,i,j,k:Integer;
 FileSize,ChunkSize,Lines:LongInt;
 FileName:string[32];
 xlate:String[64];
 CurrLine:String[132];
 Values:Array[0..63] of Byte;
 _Out:Array[0..47] of Byte;
 a:Text;
 b:File of Byte;

Procedure Convert4x6to3x8(iX,oX:Integer);
Var
 i,j:Integer;
 temp: LongInt;
 Bytes:Array[0..3] of Byte;
Begin
 For i:=0 to 3 do Begin
  j:=0;
  Repeat
   j := j + 1;
   Match := CurrLine[iX + i + 1] = xlate[j]
  Until match or (j = 64);
  If match Then bytes[i] := j - 1
           Else bytes[i] := 255
 End;
 Temp:=(LongInt(Bytes[3]) and $3F) shl 18 + (Bytes[2] and $3F) shl 12
             + (Bytes[1] and $3F) shl 6 + Bytes[0] and $3F;
 _Out[oX] := temp shr 16;
 _Out[oX + 1] := (temp shr 8) and $FF;
 _Out[oX + 2] := temp and $FF
End;

Function Reverse3:LongInt;Begin
 Reverse3 := _Out[2] * 65536 + _Out[1] * 256 + _Out[0];
End;

Procedure GetLine;
Var
 Size:Integer;
Begin
 Readln(a,CurrLine);
 Size:=Length(CurrLine);
 If size > 0 Then If CurrLine[size] = #$0D Then Delete(CurrLine,size,1);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('Cette commande permet d''extraire les fichiers d''un BSQ d''Apple II.');
  WriteLn;
  Writeln('Syntaxe: UNBINSCII nomdufichier');
 End
  Else
 If ParamCount>=1Then Begin
  FileName:=ParamStr(1);
  FirstTime:=True;
  Assign(a, fileName);
  Reset(a);
  Repeat
   Repeat
    GetLine
   Until (CurrLine = 'FiLeStArTfIlEsTaRt') or eof(a);
   If Eof(a)Then Begin
    writeln('Fin du fichier inattendu !');
    Close(a);
    Close(b);
    Halt(20)
   End;
   GetLine;
   If Length(CurrLine) <> 64 Then Begin
    Writeln('Erreur de translation de table !');
    Close(a);
    Close(b);
    Halt(20)
   End
    else
   Xlate:=CurrLine;
   GetLine;
   If Length(CurrLine) <> 52 Then Begin
    Writeln('Erreur d''attribut de fichier');
    Close(a);
    Close(b);
    Halt(20)
   End;
   If FirstTime Then Begin
    Size:=Ord(CurrLine[1]) - 64;
    FileName:=copy(CurrLine,2,Size);
    Writeln('Le fichier de sortie est nomme "', fileName, '"');
    Assign(b,FileName);
    Rewrite(b);
    Convert4x6to3x8(16, 0);
    FileSize:=reverse3;
    Writeln('Taille du fichier = ',fileSize);
    FirstTime:=False
   End;
   Convert4x6to3x8(44,0);
   ChunkSize:=reverse3;
   Writeln('Taille du morceau = ', chunkSize);
   Lines:=ChunkSize div 48;
   Last:=ChunkSize mod 48;
   If Last <> 0 Then Lines:=Lines+1;
   Limit:=47;
   For i:=1 to Lines do Begin
    GetLine;
    If Length(CurrLine) <> 64 Then Begin
     Writeln('Erreur de ligne de donnees !');
     Close(a);
     Close(b);
     Halt(20)
    End;
    k:=0;
    For j:=0 to 15 do Begin
     Convert4x6to3x8(j * 4, k);
     k:=k+3
    End;
    If (i=lines)and(last<>0)Then Limit:=last-1;
    For j:=0 to limit do Write(b, _Out[j]);
   End;
   GetLine;
   If Length(CurrLine) <> 4 Then Begin
    Writeln('Mauvaise taille des morceaux !');
    Close(a);
    Close(b);
    Halt(20)
   End;
  Until Eof(a);
  Close(b);
  Close(a)
 End
  Else
 WriteLn('Parametre requis !');
END.