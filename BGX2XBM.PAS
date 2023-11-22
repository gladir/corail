{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BGX2XBM;

{$A-}

Uses DOS;

Type
 {Entàte d'un format d'image BGX }
 BGXHeader=Record
  Sign:Array[0..3]of Char;   { Signature }
  NumXPixels,NumYPixels:Word;{ Nombre de pixels horizontal et vertical }
  BitsPerPixel:Byte;         { Nombre de bits par pixel }
 End;

Var
 SourceBGX:File;
 Header:BGXHeader;
 ImageName:String;
 Size,I,J,K,Min,Max,BytesPerLine,ByteReaded:Word;
 CountByLine:Integer;
 First:Boolean;
 Buffer:Array[0..4095]of Byte;

Function Path2Name(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2Name:=N;
End;

Function LenNBits2BytesPerLine(Width:Word;Bits4Pixel:Byte):Word;Near;Begin
 Case(Bits4Pixel)of
  1:LenNBits2BytesPerLine:=Width shr 3;
  2:LenNBits2BytesPerLine:=Width shr 2;
  4:LenNBits2BytesPerLine:=Width shr 1;
  9..16:LenNBits2BytesPerLine:=Width shl 1;
  17..24:LenNBits2BytesPerLine:=Width*3;
  25..32:LenNBits2BytesPerLine:=Width shl 2;
  33..64:LenNBits2BytesPerLine:=Width shl 4;
  Else LenNBits2BytesPerLine:=Width;
 End;
End;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BGX2XBM : Cette commande permet de convertir une image BGX en XBM');
  WriteLn;
  WriteLn('Syntaxe : BGX2XBM nomdufichier.BGX');
  WriteLn;
  WriteLn(' nomdufichier   Ce paramätre permet d''indiquer le nom du fichier ".BGX".');
 End
  Else
 If ParamCount>0Then Begin
  {$I-}Assign(SourceBGX,ParamStr(1));
  Reset(SourceBGX,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de lire le fichier d''image BGX');
   Halt;
  End;
  ImageName:=Path2Name(ParamStr(1));
  BlockRead(SourceBGX,Header,SizeOf(Header),ByteReaded);
  BytesPerLine:=LenNBits2BytesPerLine(Header.NumXPixels,Header.BitsPerPixel);
  If BytesPerLine>SizeOf(Buffer)Then Begin
   WriteLn('Ligne trop large pour àtre lu');
   Halt;
  End;
  WriteLn('#define ',ImageName,'_width ',Header.NumXPixels);
  WriteLn('#define ',ImageName,'_height ',Header.NumYPixels);
  WriteLn('static unsigned char ',ImageName,'_bits[] = {');
  First:=True;
  CountByLine:=0;
  For J:=0to Header.NumYPixels-1 do Begin
   BlockRead(SourceBGX,Buffer,BytesPerLine,ByteReaded);
   For I:=0 to BytesPerLine-1 do Begin
    If Not(First)Then Write(',');
    If CountByLine>3 Then Begin
     WriteLn;
     CountByLine:=0;
    End
     Else
    Inc(CountByLine);
    Write('0x',ByteHex2Str(Buffer[I]),',');
   End;
  End;
  WriteLn;
  WriteLn('};');
  Close(SourceBGX);
 End
  Else
 WriteLn('Paramätre requis !');
END.