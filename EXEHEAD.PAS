{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program EXEHEAD;

Type
 ExeHeaderRec=Record
  Signature:Array[0..1]of Char;
  LengthRem:Word;
  LengthPages:Word;
  NumReloc:Word;
  HeaderSize:Word;
  MinHeap:Word;
  MaxHeap:Word;
  StackSeg:Word;
  StackPtr:Word;
  CheckSum:Word;
  IpInit:Word;
  CodeSeg:Word;
  RelocOfs:Word;
  OverlayNum:Word;
 End;

Var
 Fich:File;
 Header:ExeHeaderRec;

Procedure Help;Begin
 Writeln;
 Writeln('EXEHEAD: Visualisateur d''entete EXE');
 Writeln;
 Writeln('SYNTAXE: EXEHEAD program.exe');
 Writeln;
End;

Function WordToHex(Number:Word):String;
Const Hexa:Array[0..15] of Char=('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 WordToHex:=Hexa[Hi(Number) shr 4]+Hexa[Hi(Number) and $F]+Hexa[Lo(Number) shr 4]+Hexa[Lo(Number) and $F];
End;

BEGIN
 If((ParamCount = 0)or(ParamCount > 1))Then Help
 Else
 If ParamStr(1)='/?'Then Help Else
 Begin
  Assign(Fich, ParamStr(1));
  Reset(Fich,1);
  BlockRead(Fich,Header,SizeOf(Header));
  Close (Fich);
  WriteLn;
  Writeln('Analyse de l''entete...');
  WriteLn;
  If(Header.Signature[0]='M') and (Header.Signature[1]='Z')Then Begin
   WriteLn('Signature du fichier : ',Header.Signature[0],Header.Signature[1]);
   WriteLn('Taille de la derniere page : ' ,WordToHex(Header.LengthRem),'h, ',Header.LengthRem);
   WriteLn('Nombres de pages : ' ,WordToHex(Header.LengthPages),'h, ', Header.LengthPages);
   WriteLn('Entrees de la table de relocalisation : ' ,WordToHex(Header.NumReloc),'h, ', Header.NumReloc);
   WriteLn('Paragraphes de l''enetete : ',WordToHex(Header.HeaderSize),'h, ', Header.HeaderSize);
   WriteLn('MINALLOC : ' ,WordToHex(Header.MinHeap),'h, ', Header.MinHeap);
   WriteLn('MAXALLOC : ' ,WordToHex(Header.MaxHeap),'h, ', Header.MaxHeap);
   WriteLn('SS initial (Segment de la pile) : ' ,WordToHex(Header.StackSeg),'h, ', Header.StackSeg);
   WriteLn('SP initial (Taille de la pile) : ' ,WordToHex(Header.StackPtr),'h, ',Header.StackPtr);
   WriteLn('Sommation de controle : ' ,WordToHex(Header.CheckSum),'h, ',Header.CheckSum);
   WriteLn('IP initial : ' ,WordToHex(Header.IpInit),'h, ',Header.IpInit);
   WriteLn('CS initial : ' ,WordToHex(Header.CodeSeg),'h, ',Header.CodeSeg);
   WriteLn('Deplacement de la table de relocalisation : ' ,WordToHex(Header.RelocOfs),'h, ',Header.RelocOfs);
   WriteLn('Nombre du segment de recouvrement : ' ,WordToHex(Header.OverlayNum),'h, ',Header.OverlayNum);
  End
   Else
  Begin
   WriteLn('Analyse impossible, le fichier n''est pas d''un type MZ');
  End;
 End;
END.
