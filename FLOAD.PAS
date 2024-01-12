{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7)
}

Program FLOAD;

Uses DOS;

Var
 Verbose,NoLoad:Boolean;
 FontFile:File;
 I:Integer;
 ByteReaded,Err:Word;
 FontNum,HeightChr:Byte;
 FS,StartPos:LongInt;
 FileName:String;
 Buffer:Array[0..4095]of Byte;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Procedure LoadFont(AscII:Word;Table,Matrice:Byte;Nombre:Word;Buffer:Pointer);
Var
 Regs:Registers;
Begin
 Regs.AX:=$1100;
 Regs.BH:=Matrice;
 Regs.BL:=Table;
 Regs.CX:=Nombre;
 Regs.DX:=AscII;
 Regs.BP:=Ofs(Buffer^);
 Regs.ES:=Seg(Buffer^);
 Intr($10,Regs);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('FLOAD : Cette commande permet de charger une police de ',
                   'caractŠres … partir d''un fichier de format ®.FNT¯ ',
                   'en m‚moire vid‚o.');
  WriteLn;
  WriteLn('Syntaxe : FLOAD fichier.FNT [fontnum] [/V]');
  WriteLn;
  WriteLn(' fichier.FNT  Nom du fichier de police de caractŠres');
  WriteLn(' fontnum      Num‚ro de la table de police de caractŠres');
  WriteLn(' /V           Affiche d‚taill‚');
  WriteLn(' /NOLOAD      Ne charge pas la police de caractŠres');
 End
  Else
 If ParamCount>0 Then Begin
  FontNum:=0;
  Verbose:=False;
  NoLoad:=False;
  FileName:='';
  For I:=1 to ParamCount do Begin
   If(StrToUpper(ParamStr(I))='/NOLOAD')Then NoLoad:=True Else
   If(StrToUpper(ParamStr(I))='/V')or
     (StrToUpper(ParamStr(I))='/VERBOSE')Then Begin
    Verbose:=True;
   End
    Else
   If FileName=''Then FileName:=ParamStr(I)
    Else
   Begin
    Val(ParamStr(I),FontNum,Err);
    If Err>0 Then Begin
     WriteLn('Num‚ro de table invalide :',ParamStr(I));
     Halt(2);
    End;
    If Not(FontNum in[0..7])Then Begin
     WriteLn('Le num‚ro de table doit ˆtre situ‚ entre 0 et 7');
     Halt(3);
    End;
   End;
  End;
  If FileName=''Then Begin
   WriteLn('Nom de fichier attendue !');
   Halt(4);
  End;
  {$I-}Assign(FontFile,FileName);
  Reset(FontFile,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Police de caractŠres introuvable : ',FileName);
   Halt(1);
  End;
  FS:=FileSize(FontFile);
  StartPos:=0;
  If Frac((FS-8)/256)=0.0 Then StartPos:=8
                          Else StartPos:=0;
  HeightChr:=(FS-StartPos)shr 8;
  If(Verbose)Then Begin
   WriteLn('Nom du fichier : ',FileName);
   WriteLn('Num‚ro de table ',FontNum);
   WriteLn('Position de d‚part : ',StartPos);
   WriteLn('Hauteur des caractŠres : ',HeightChr);
  End;
  Seek(FontFile,StartPos);
  BlockRead(FontFile,Buffer,SizeOf(Buffer),ByteReaded);
  If Not(NoLoad)Then LoadFont(0,FontNum,HeightChr,256,@Buffer);
  Close(FontFile);
 End
  Else
 Begin
  WriteLn('ParamŠtre attendu !');
  Halt(4);
 End;
END.