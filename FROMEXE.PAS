{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program FROMEXE;

Uses DOS;

Type
 ExeHeader=Record
  Id,LPage,FPages,RelocItems,Size,MinAlloc,MaxAlloc,
  SS,SP,ChkSum,IP,CS,OfsRtbl,OvrNum:Word;
 End;

 WindowsHeader=Record
  ID:Word;
 End;

Var
 F:File;
 I:Integer;
 N:Byte;
 ExeHdr:ExeHeader;
 WinHdr:WindowsHeader;
 ByteReaded:Word;
 ExeSize,HdrSize,OStartUp:LongInt;
 DirFile:SearchRec;
 Compressed:Boolean;
 Path:DirStr;
 Name:NameStr;
 Ext:ExtStr;
 FStr:String;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function WordHex2Str(value:Word):String;Begin
 WordHex2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

Function LongHex2Str(value:LongInt):String;Begin
 LongHex2Str:=ByteHex2Str((value shr 24)and $FF)+
              ByteHex2Str((value shr 16)and $FF)+' '+
              ByteHex2Str((value shr 8)and $FF)+
              ByteHex2Str(value and $FF);
End;

Procedure PrintInfo;
Var
 I:Byte;
 ImgSize,MinXMem,MaxXMem:LongInt;
Begin
 HdrSize:=LongInt(ExeHdr.Size) shl 4;
 ImgSize:=LongInt(ExeSize)-HdrSize;
 MinXMem:=LongInt(ExeHdr.MinAlloc) shl 4;
 MaxXMem:=LongInt(ExeHdr.MaxAlloc) shl 4;
 OStartUp:=HdrSize+LongInt(ExeHdr.CS) shl 4+LongInt(ExeHdr.IP);
 WriteLn(#9#9#9#9#9, 'D‚cimal':8, ' ':3, 'Hexad‚cimal');
 WriteLn('Taille du fichier EXE :', #9#9#9,
         ExeSize:8, '':3, LongHex2Str(ExeSize));
 WriteLn('Taille de l''entˆte EXE :',#9#9,
         HdrSize:8, '':3, LongHex2Str(HdrSize));
 WriteLn('Taille du Code+Init. donn‚es:',#9#9,
         ImgSize:8, '':3, LongHex2Str(ImgSize));
 WriteLn('Pr‚-relocalisation SS:SP', #9#9#9, '':3,
         WordHex2Str(exehdr.ss), ':', WordHex2Str(exehdr.sp));
 WriteLn('Pr‚-relocalisation CS:IP', #9#9#9, '':3,
         WordHex2Str(exehdr.cs), ':', WordHex2Str(exehdr.ip));
 WriteLn('Min. m‚moire suppl‚mentaires requise:',#9,
         MinXMem:8, '':3, LongHex2Str(MinXMem));
 WriteLn('Max. m‚moire suppl‚mentaires demand‚:',#9,
         MaxXMem:8, '':3, LongHex2Str(MaxXMem));
 WriteLn('D‚placement au d‚but du code:', #9#9#9,' ':3,
         LongHex2Str(OStartUp));
 WriteLn('D‚placement de la table de relocalisation:', #9, '':3,
         WordHex2Str(ExeHdr.OfsRtbl):9);
 WriteLn('Nombre de recouvrement des pointeurs:',' ':3,
         exehdr.relocitems:8);
 WriteLn('Nombre de recouvrement:', #9#9#9,
         exehdr.OvrNum:8);
 WriteLn('Valeur de somme de v‚rification:', #9#9,'':3,
         WordHex2Str(exehdr.ChkSum):9);
 WriteLn('M‚moire n‚cessaire au d‚but:', #9#9,
         ImgSize+MinXMem+$100:8);
End;

Procedure IdSignature;
Const
 o_01=14;
 o_02=16;
 o_03=47;
 strlen =5;
 OfsRTE=25 shl 4;
 MaxChar=1024;
Var
 I,J,K:Word;
 CStr:Array[0..3] of String[StrLen];
 OFSeg:Word;
 OSysSeg:LongInt;
 Buffer:Array[0..MaxChar] of Char;
Begin
 Seek(f,OStartUp+3);
 BlockRead(f,OFSeg,SizeOf(OFSeg));
 OSysSeg:=LongInt(OFSeg) shl 4+HdrSize;
 If(OSysSeg+OfsRTE<=DirFile.Size)Then Begin
  Seek(f,OSysSeg+OfsRTE);
  BlockRead(f,Buffer,SizeOf(Buffer),ByteReaded);
  For I:=0 to High(CStr)do Begin
   CStr[i][0]:=Char(StrLen);
   FillChar(cstr[i][1],StrLen,'*');
  End;
  i:=1; j:=1; k:=0;
  Repeat
   If Buffer[i]in['n','t','i','m','e']Then Begin
    If(k>0)and(k=i-1)Then Inc(j);
    Cstr[0][j]:=Buffer[i];
    k:=i;
   End;
   Inc(i);
  Until(cstr[0]='ntime')or(i>MaxChar)or(j>StrLen);
  If(i+o_03<=MaxChar)Then Begin
   Dec(i,strlen);
   Move(Buffer[I+o_01], CStr[1][1],StrLen);
   If CStr[1]='at '#0'.'Then Begin
    WriteLn;
    WriteLn('D‚placement du code vers le code systŠme TP:',#9,'':3,LongHex2Str(OSysSeg):9);
    Write('Compil‚ par Borland Turbo Pascal version ');
    Move(Buffer[i-o_02],CStr[2][1],StrLen);
    If CStr[2]='$4567'Then Begin
     Move(Buffer[i+o_03],CStr[3][1],StrLen);
     If(CStr[3]='83,92')Then WriteLn('7.0') Else
     If(CStr[3]='83,90')Then Writeln('6.0')
                        Else writeln('5.0/5.5');
    End
     Else
    WriteLn('4.0');
   End;
  End;
 End;
End;

Procedure ProcessExeFile;Begin
 If(ExeSize=DirFile.Size)Then Begin
  PrintInfo;
  If Not Compressed Then IdSignature;
  WriteLn;
 End
  Else
 Begin
  Seek(F,$3C);
  BlockRead(F,HdrSize,SizeOf(HdrSize));
  If(HdrSize<=DirFile.Size)Then Begin
   Seek(f,HdrSize);
   BlockRead(f,WinHdr,SizeOf(WinHdr));
  End;
  If(WinHdr.id=$454E)Then Begin
   WriteLn('Fichier EXE ou DLL de DOS/Window');
   PrintInfo;
   Exit;
  End
   Else
  Begin
   PrintInfo;
   WriteLn;
   Writeln('Taille du fichier (',ExeSize,') calcul‚ pour l''entˆte EXE ',
               '(charg‚ par DOS sur l''ex‚cutable)');
   WriteLn('ne correspond pas … la taille du fichier (',DirFile.Size,') ',
               'enregistrement dans le r‚pertoire de fichiers.');
   WriteLn;
   WriteLn('* Fichier EXE enregistr‚ avec des octets suppl‚mentaires ',
           '… la fin du fichier (par exemple, informations de d‚bogage)');
   WriteLn('* Le fichier EXE peut contenir des recouvrements');
   WriteLn('* possible un fichier EXE corrompu');
   WriteLn;
   Exit;
  End;
 End;
End;

Procedure IdFile;Begin
 If(ExeHdr.id=$5A4D)Then Begin
  If(ExeHdr.CS=$FFF0)and(ExeHdr.IP=$0100)and(ExeHdr.OfsRtbl in[$50,$52])Then Begin
  WriteLn('Compress‚ par PKLITE');
  Compressed:=True;
 End;
 If(ExeHdr.Size=2)and(ExeHdr.ChkSum=$899D)Then Begin
  Writeln('Compress‚ par DIET');
  Compressed:=True;
 End;
 If(ExeHdr.Lpage>0)Then ExeSize:=LongInt(ExeHdr.FPages-1) shl 9+ExeHdr.Lpage
                   Else ExeSize:=LongInt(ExeHdr.FPages) shl 9;
  ProcessExeFile;
 End
  Else
 WriteLn('Pas de fichier EXE');
End;

BEGIN
 N:=0;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('FROMEXE: Cette commande permet d''analyser un EXE.');
  WriteLn;
  WriteLn('Syntaxe: FROMEXE programme[.EXE]');
  WriteLn;
  WriteLn('programme  Ce paramŠtre permet d''indiquer le nom du programme.');
 End
  Else
 If ParamCount>0Then For I:=1 to ParamCount do Begin
  FSplit(ParamStr(I),Path,Name,Ext);
  If(Name+Ext='*.*')or(Name+Ext='.')or(Name+Ext='')Then FStr:=Path+'*.exe'Else
  If Path+Ext=''Then FStr:=ParamStr(I)+'.EXE'Else
  If Not Boolean(Pos('.',Ext))Then Begin
   Path:=Path+Name+'\';
   FStr:=Path+'*.EXE';
  End
   Else
  FStr:=ParamStr(I);
  FindFirst(FStr,AnyFile,DirFile);
  While(DOSError=0)do Begin
   If(DirFile.Attr and VolumeID<>VolumeID)and
     (DirFile.Attr and Directory<>Directory)and
     (DirFile.Attr and SysFile<>Sysfile)Then
   Begin
    Compressed:=False;
    {$I-}Assign(F,Path+DirFile.Name);
    Reset(f,1); {$I+}
    If(IOResult=0)Then Begin
     WriteLn;
     WriteLn(DirFile.Name);
     BlockRead(f,ExeHdr,SizeOf(ExeHdr),ByteReaded);
     If(ByteReaded=SizeOf(ExeHdr))Then IdFile
                                Else WriteLn('Erreur dans l''entˆte');
     Close(F);
     Inc(N);
    End;
   End;
   FindNext(DirFile);
  End;
  If(N=0)Then Begin
   If DOSError=3 Then WriteLn('Chemin introuvable')
                 Else WriteLn('Aucun fichier trouv‚');
  End
   Else
  Writeln(n,' fichiers trouv‚s');
 End
  Else
 WriteLn('ParamŠtre requis !');
END.