{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BMP2DIB;

{$A-}

Uses DOS;

Const
  {Type de compression Windows}
 bi_RGB=0;
 bi_RLE8=1;
 bi_RLE4=2;

Type
 HeaderBMP=Record
  Sign:Array[0..1]of Char;
  Size,Reserved0,OffBits:LongInt;
  biSize,NumXPixels,NumYPixels:LongInt;
  Planes,BitCount:Word;
  Compression,SizeImage:LongInt;
  XPelsPerMeter,YPelsPerMeter,ClrUsed,ClrImportant:LongInt;
 End;

  {Le format DIB ("Device-Independent Bitmap") est tout simplement le
   contenu d'un fichier BMP duquel on a retir� l'en-t�te de fichier
   BITMAPFILEHEADER (les 14 premiers octets). Un fichier .DIB
   d�marre donc directement par le BITMAPINFOHEADER, suivi de la
   palette �ventuelle (2^biBitCount entr�es de 4 octets BGRX pour les
   modes index�s) puis des donn�es de pixels stock�es de bas en haut
   et align�es sur 32 bits par ligne. Aucun champ n'est modifi� :
   biSize, biWidth, biHeight, biPlanes, biBitCount, biCompression,
   biSizeImage, biXPelsPerMeter, biYPelsPerMeter, biClrUsed,
   biClrImportant sont recopi�s tels quels depuis le BMP source.}

Var
 SourceBMP,DestDIB:File;
 Header:HeaderBMP;
 Buffer:Array[0..4095]of Byte;
 ByteReaded,ByteWritten:Word;
 ToCopy,Remaining:LongInt;
 OutputName:String;

Function Path2NameExt(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2NameExt:=D+N+'.DIB';
End;

  {Affiche l'aide en ligne et termine le programme.}
Procedure ShowHelp;
Begin
 WriteLn('BMP2DIB : Cette commande permet de convertir une image BitMap (.BMP) ',
                   'en fichier Device-Independent Bitmap (.DIB).');
 WriteLn;
 WriteLn('Syntaxe : BMP2DIB nomdufichier.BMP');
 WriteLn;
 WriteLn(' nomdufichier   Nom du fichier ".BMP" � convertir.');
 WriteLn;
 WriteLn('Le fichier r�sultant porte le m�me nom avec l''extension .DIB.');
 WriteLn('Un fichier DIB est un BMP sans l''en-t�te de 14 octets BITMAPFILEHEADER :');
 WriteLn('il commence directement par le BITMAPINFOHEADER, suivi de la palette');
 WriteLn('�ventuelle puis des donn�es de pixels.');
 Halt;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then ShowHelp;
 If ParamCount<1 Then Begin
  WriteLn('Param�tre requis !');
  Halt;
 End;

 {$I-}Assign(SourceBMP,ParamStr(1));
 Reset(SourceBMP,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de lire le fichier d''image');
  Halt;
 End;
 BlockRead(SourceBMP,Header,SizeOf(Header),ByteReaded);
 If Header.Sign<>'BM'Then Begin
  WriteLn('Signature d''ent�te Bitmap introuvable !');
  Close(SourceBMP);
  Halt;
 End;

  {Cr�ation du fichier de destination.}
 OutputName:=Path2NameExt(ParamStr(1));
 {$I-}Assign(DestDIB,OutputName);
 Rewrite(DestDIB,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible de cr�er le fichier ',OutputName);
  Close(SourceBMP);
  Halt;
 End;

  {Recopie int�grale du contenu du BMP � partir de l'octet 14, soit
   imm�diatement apr�s le BITMAPFILEHEADER. Le BITMAPINFOHEADER, la
   palette et les donn�es de pixels sont conserv�s tels quels.}
 Seek(SourceBMP,14);
 Remaining:=FileSize(SourceBMP)-14;
 While Remaining>0 Do Begin
  If Remaining>SizeOf(Buffer)Then ToCopy:=SizeOf(Buffer)
                             Else ToCopy:=Remaining;
  BlockRead(SourceBMP,Buffer,ToCopy,ByteReaded);
  If ByteReaded=0 Then Break;
  BlockWrite(DestDIB,Buffer,ByteReaded,ByteWritten);
  Dec(Remaining,ByteReaded);
 End;

 Close(DestDIB);
 Close(SourceBMP);
END.
