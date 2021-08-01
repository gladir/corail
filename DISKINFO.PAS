{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program DISKINFO;

Function TwoByteToWord(A,B:Byte):Word;Begin
 TwoByteToWord:=B*256+A;
End;

Function FourByteToLongInt(A,B,C,D:Byte):LongInt;Begin
 FourByteToLongInt:=D*16777216+C*65536+B*256+A;
End;

{$IFDEF Windows}
 Procedure Int25h(Drive:Byte;LSN,Sects:Word;Var Buffer;Var Erreur:Word);Begin
  WriteLn('Cette fonctionnalite n''est pas mise en oeuvre');
  Halt;
 End;
{$ELSE}
 Var Data:Record
  LSN:LongInt;
  Sects:Word;
  Buffer:Pointer;
 End;

 Procedure Int25h(Drive:Byte;LSN,Sects:Word;Var Buffer;Var Erreur:Word);
 Assembler;
 Const __POPF = $9D;
 ASM
  PUSH BP;
  PUSH DS;
   MOV AL,Drive;
   MOV DX,LSN;
   MOV CX,Sects;
   LDS BX,Buffer;
   INT $25;
   JB  @@Suite;
   XOR AX,AX;
@@Suite:
   DB __POPF;
  POP DS;
  POP BP;
  LES DI,Erreur;
  MOV ES:[DI],AX;
  CMP AX,519;
  JNE @@No32Bits;
  PUSH BP;
  PUSH DS;
   MOV AL,Drive;
   MOV DX,LSN;
   MOV CX,Sects;
   MOV BX,Offset Data;
   MOV DS:[BX],DX;
   MOV DS:[BX+2].Word,0;
   MOV DS:[BX+4],CX;
   LES DI,Buffer;
   MOV DS:[BX+6],DI;
   MOV DS:[BX+8],ES;
   MOV CX,$FFFF;
   INT $25;
   JB  @@Suite2;
   XOR AX,AX;
@@Suite2:
   DB __POPF;
  POP DS;
  POP BP;
  LES DI,Erreur;
  MOV ES:[DI],AX;
@@No32Bits:
 End;
{$ENDIF}


Var
 FileSource:File{$IFDEF FPC}of Byte{$ENDIF};
 ByteReaded:Integer;
 I:Integer;
 BitsDeFat,NbrDeFats:Byte;
 TotSects,PremRoot,PremData,SectsPRoot,TempLong,TotPistes,TotClusters:LongInt;
 Erreur,RawTotSects,SectsPPiste,MaxEntrees,SectsPFat,SectsReserves,BytesPSecteur,NbrTetes:Word;
 IsDisk:Boolean;
 CurrParam:String;
 FileName:String;
 Buffer:Array[0..511]of Byte;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('DISKINFO : Cette commande permet d''afficher les informations sur une disquette ou un fichier.');
  WriteLn;
  WriteLn('Syntaxe : DISKINFO disque:');
  WriteLn('          DISKINFO fichier');
 End
  Else
 If ParamCount=1Then Begin
  CurrParam:=ParamStr(1);
  If(CurrParam[1]in['a'..'z','A'..'Z'])and(CurrParam[2]=':')Then Begin
   Int25h(Byte(UpCase(CurrParam[1]))-Byte('A'),0,1,Buffer,Erreur);
  End
   Else
  Begin
   FileName:=CurrParam;
   {$I-}Assign(FileSource,FileName);
   Reset(FileSource);{$I+}
   If IoResult=0Then Begin
    BlockRead(FileSource,Buffer,SizeOf(Buffer),ByteReaded);
    Close(FileSource);
   End
    Else
   Begin
    WriteLn('Erreur de lecture du fichier d''image');
    Halt;
   End;
  End;
  Write('Type de media : ');
  Case Buffer[$15] of
   $FF: WriteLn('Disquette double face, 8 secteurs/piste');
   $FE: WriteLn('Disquette simple face, 8 secteurs/piste');
   $FD: WriteLn('Disquette double face, 9 secteurs/piste');
   $FC: WriteLn('Disquette simple face, 9 secteurs/piste');
   $F9: WriteLn('Disquette double face, 15 secteurs/piste');
   $F8: WriteLn('Disque dur');
   $F0: WriteLn('Disquette');
   Else WriteLn('Media inconnu : ',Buffer[$15]);
  End;
  Write('Formateur : ');
  For I:=0 to 7 do Write(Char(Buffer[3+I]));
  WriteLn;
  BytesPSecteur:=TwoByteToWord(Buffer[$0B],Buffer[$0C]);
  If BytesPSecteur=0Then BytesPSecteur:=512;
  WriteLn('Nombre d''octets par secteur : ',BytesPSecteur);
  WriteLn('Nombre de secteurs pour l''unites d''allocation : ',Buffer[$0D]);
  WriteLn('Nombre de secteurs reserves : ',TwoByteToWord(Buffer[$0E],Buffer[$0F]),' (pour le Secteur de demarrage)');
  NbrDeFats:=Buffer[$10];
  If NbrDeFats=0Then NbrDeFats:=2;
  WriteLn('Nombre de FATs : ',NbrDeFats);
  WriteLn('Maximum d''entrees dans le repertoire racine : ',TwoByteToWord(Buffer[$11],Buffer[$12]));
  TotSects:=TwoByteToWord(Buffer[$13],Buffer[$14]);
  If TotSects=0Then TotSects:=FourByteToLongInt(Buffer[$20],Buffer[$21],Buffer[$22],Buffer[$23]);
  WriteLn('Nombre total de secteurs : ',TotSects);
  WriteLn('Nombre de secteurs par piste : ',TwoByteToWord(Buffer[$18],Buffer[$19]));
  NbrTetes:=TwoByteToWord(Buffer[$1A],Buffer[$1B]);
  WriteLn('Nombre de tetes (faces) : ',NbrTetes);
  SectsReserves:=TwoByteToWord(Buffer[$0E],Buffer[$0F]);
  WriteLn('Premier secteur de la FAT : ',SectsReserves);
  SectsPFat:=TwoByteToWord(Buffer[$16],Buffer[$17]);
  PremRoot:=SectsReserves+(NbrDeFats*SectsPFat);
  WriteLn('Premier secteur de "\" : ',PremRoot);
  MaxEntrees:=TwoByteToWord(Buffer[$11],Buffer[$12]);
  SectsPRoot:=(MaxEntrees*32)div BytesPSecteur;
  If(((MaxEntrees*32) mod BytesPSecteur)<>0)Then Inc(SectsPRoot);
  WriteLn('Nombre de secteur dans le repertoire racine : ',SectsPRoot);
  PremData:=PremRoot+SectsPRoot;
  WriteLn('Premier secteur des fichiers : ',PremData);
  TempLong := LongInt(TotSects);
  SectsPPiste:=TwoByteToWord(Buffer[$18],Buffer[$19]);
  If (LongInt(NbrTetes)*LongInt(SectsPPiste))=0Then Begin
   TempLong:=0
  End
   Else
  Begin
   TempLong := TempLong div (LongInt(NbrTetes)*LongInt(SectsPPiste));
  End;
  TotPistes := TempLong;
  If(TempLong-TotPistes > 0)Then Inc(TotPistes);
  If Buffer[$0D]=0Then TempLong:=0
                  Else TempLong := (LongInt(TotSects)-LongInt(PremData)) div LongInt(Buffer[$0D]);
  TotClusters := TempLong;
  WriteLn('Nombre de pistes (cylindres) : ',TotPistes);
  WriteLn('Nombre d''unites d''allocation (pour fichiers) : ',TotClusters);
  RawTotSects:=TwoByteToWord(Buffer[$13],Buffer[$14]);
  If RawTotSects=0Then BitsDeFat:=32 Else
  If(RawTotSects>4086)Then BitsDeFat:=16
		            Else BitsDeFat:=12;
  WriteLn('Longueur des elements de la FAT : ',BitsDeFat,' bits');
  WriteLn;
 End
  Else
 WriteLn('Nombre de parametre invalide !');
END.