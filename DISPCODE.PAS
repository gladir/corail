{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)

  D'sassembleur de p-Code UCSD p-System (II.0/II.1 - Heath/Apple Pascal).

  Lit un fichier binaire contenant du p-Code et affiche le d'sassemblage.
  Convient au contenu brut d'un .CODE UCSD (segment unique) ou aux octets
  extraits par H8D /X d'un fichier SYSTEM.FILER, etc.

  Usage:
   DISPCODE FICHIER [/S=offset] [/N=nb] [/H]

   /S=offset   Adresse de d'but (d'cimal ou $hex). D'faut: 0
   /N=nb       Nombre max d'octets ' d'sassembler. D'faut: tout le fichier
   /H          Aide
}

Program DISPCODE;

{$A-}
{$IFDEF FPC}{$MODE TP}{$ENDIF}

Uses DOS;

Const
 OPK_NONE  = 0;  { aucun op'rande }
 OPK_UB    = 1;  { 1 octet non sign' }
 OPK_SB    = 2;  { 1 octet sign' (jump) }
 OPK_W     = 3;  { 2 octets little-endian }
 OPK_BIG   = 4;  { 1 ou 2 octets (MSB=0 => 1 octet, MSB=1 => 14 bits BE) }
 OPK_UBUB  = 5;  { 2 UB }
 OPK_UBBIG = 6;  { UB + BIG }
 OPK_DBBIG = 7;  { DB (level) + BIG }
 OPK_LSA   = 8;  { UB len + chars }
 OPK_LDC   = 9;  { UB count + count*2 octets }
 OPK_XJP   = 10; { case jump (complexe) }

Type
 TMnem=String[6];

Const
 { Table des mn'moniques pour opcodes 128..255 (les 0..127 sont SLDC). }
 Mnem128:Array[128..255]Of TMnem = (
  'ABI','ABR','ADI','ADR','LAND','DIF','DVI','DVR',         { 128..135 }
  'CHK','FLO','FLT','INN','INT','IOR','MODI','MPI',         { 136..143 }
  'MPR','NGI','NGR','LNOT','SRS','SBI','SBR','SGS',         { 144..151 }
  'SQI','SQR','STO','IXS','UNI','LDE','CSP','LDCN',         { 152..159 }
  'ADJ','FJP','INC','IND','IXA','LAO','LSA','LAE',          { 160..167 }
  'MOV','LDO','SAS','SRO','XJP','RNP','CIP','EQU',          { 168..175 }
  'GEQ','GRT','LDA','LDC','LEQ','LES','LOD','NEQ',          { 176..183 }
  'STR','UJP','LDP','STP','LDM','STM','LDB','STB',          { 184..191 }
  'IXP','RBP','CBP','EQUI','GEQI','GRTI','LLA','LDCI',      { 192..199 }
  'LEQI','LESI','LDL','NEQI','STL','CXP','CLP','CGP',       { 200..207 }
  'LPA','STE','???','EFJ','NFJ','BPT','XIT','NOP',          { 208..215 }
  'SLDL1','SLDL2','SLDL3','SLDL4','SLDL5','SLDL6','SLDL7','SLDL8',
  'SLDL9','SLDL10','SLDL11','SLDL12','SLDL13','SLDL14','SLDL15','SLDL16',
  'SLDO1','SLDO2','SLDO3','SLDO4','SLDO5','SLDO6','SLDO7','SLDO8',
  'SLDO9','SLDO10','SLDO11','SLDO12','SLDO13','SLDO14','SLDO15','SLDO16',
  'SIND0','SIND1','SIND2','SIND3','SIND4','SIND5','SIND6','SIND7'
 );

 { Kind d'op'rande pour 128..255. }
 Kind128:Array[128..255]Of Byte = (
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE, {128-135}
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE, {136-143}
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE, {144-151}
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_UBBIG,OPK_UB,OPK_NONE,  {152-159 LDE,CSP}
  OPK_UB,OPK_SB,OPK_BIG,OPK_BIG,OPK_BIG,OPK_BIG,OPK_LSA,OPK_UBBIG,         {160-167 ADJ,FJP,INC,IND,IXA,LAO,LSA,LAE}
  OPK_BIG,OPK_BIG,OPK_UB,OPK_BIG,OPK_XJP,OPK_UB,OPK_UB,OPK_UB,             {168-175 MOV,LDO,SAS,SRO,XJP,RNP,CIP,EQU}
  OPK_UB,OPK_UB,OPK_DBBIG,OPK_LDC,OPK_UB,OPK_UB,OPK_DBBIG,OPK_UB,          {176-183 GEQ,GRT,LDA,LDC,LEQ,LES,LOD,NEQ}
  OPK_DBBIG,OPK_SB,OPK_NONE,OPK_NONE,OPK_UB,OPK_UB,OPK_NONE,OPK_NONE,      {184-191 STR,UJP,LDP,STP,LDM,STM,LDB,STB}
  OPK_UBUB,OPK_UB,OPK_UB,OPK_NONE,OPK_NONE,OPK_NONE,OPK_BIG,OPK_W,         {192-199 IXP,RBP,CBP,EQUI,GEQI,GRTI,LLA,LDCI}
  OPK_NONE,OPK_NONE,OPK_BIG,OPK_NONE,OPK_BIG,OPK_UBUB,OPK_UB,OPK_UB,       {200-207 LEQI,LESI,LDL,NEQI,STL,CXP,CLP,CGP}
  OPK_UBUB,OPK_UBBIG,OPK_NONE,OPK_SB,OPK_SB,OPK_NONE,OPK_NONE,OPK_NONE,    {208-215 LPA,STE,???,EFJ,NFJ,BPT,XIT,NOP}
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE, {216-223 SLDL1..8}
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE, {224-231 SLDL9..16}
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE, {232-239 SLDO1..8}
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE, {240-247 SLDO9..16}
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE  {248-255 SIND0..7}
 );

 { Mn'moniques des CSP (Call Standard Procedure). }
 CSPMax = 37;
 CSPName:Array[0..CSPMax]Of String[6] = (
  'IOC','NEW','MVL','MVR','EXIT','UREAD','UWRITE','IDS',     { 0..7 }
  'TRS','TIM','FLC','SCN','USTAT','???','???','???',          { 8..15 }
  'LDSEG','ULSEG','TRC','RND','SIN','COS','TAN','ATAN',       { 16..23 }
  'LN','EXP','SQT','MARK','RLS','IOR','UBUSY','POT',          { 24..31 }
  'UWAIT','CHN','INN','OUT','ATT','IORSLT'                    { 32..37 }
 );

Var
 InFile:File;
 InName:String;
 StartOff:LongInt;
 MaxBytes:LongInt;
 Buf:Array[0..16383]Of Byte;
 BufLen:LongInt;
 BufBase:LongInt;     { offset fichier du d'but de Buf }
 FSize:LongInt;
 PC:LongInt;          { offset courant dans le fichier }

Function StrToLongHex(S:String):LongInt;
Var I:Integer; V:LongInt; C:Char; D:Integer;
Begin
 V:=0;
 If (Length(S)>0) And (S[1]='$') Then Begin
  For I:=2 To Length(S) Do Begin
   C:=UpCase(S[I]);
   If (C>='0')And(C<='9') Then D:=Ord(C)-Ord('0')
   Else If (C>='A')And(C<='F') Then D:=Ord(C)-Ord('A')+10
   Else Begin StrToLongHex:=-1; Exit; End;
   V:=V*16+D;
  End;
 End Else Begin
  Val(S,V,I);
  If I<>0 Then Begin StrToLongHex:=-1; Exit; End;
 End;
 StrToLongHex:=V;
End;

Procedure Usage;
Begin
 WriteLn('DISPCODE - Cette commande permet de lancer le ',
         'd'+#130+'sassembleur de p-Code UCSD p-System');
 WriteLn;
 WriteLn('Syntaxe: DISPCODE FICHIER [/S=offset] [/N=nb] [/H]');
 WriteLn;
 WriteLn('  /S=offset   Offset de d'+#130+'but (d'+#130+'cimal ou $hex)');
 WriteLn('  /N=nb       Nombre max d''octets '+#133+' d'+#130+'sassembler');
 WriteLn('  /H          Affiche cette aide');
End;

Procedure ParseCmd;
Var I:Integer; S:String; V:LongInt;
Begin
 InName:=''; StartOff:=0; MaxBytes:=-1;
 For I:=1 To ParamCount Do Begin
  S:=ParamStr(I);
  If (S[1]='/') Or (S[1]='-') Then Begin
   If (Length(S)>=2) And (UpCase(S[2])='H') Then Begin Usage; Halt(0); End
   Else If (Length(S)>=3) And (UpCase(S[2])='S') And (S[3]='=') Then Begin
    V:=StrToLongHex(Copy(S,4,Length(S)-3));
    If V<0 Then Begin WriteLn('Offset invalide: ',S); Halt(2); End;
    StartOff:=V;
   End
   Else If (Length(S)>=3) And (UpCase(S[2])='N') And (S[3]='=') Then Begin
    V:=StrToLongHex(Copy(S,4,Length(S)-3));
    If V<0 Then Begin WriteLn('Compte invalide: ',S); Halt(2); End;
    MaxBytes:=V;
   End
   Else Begin WriteLn('Option inconnue: ',S); Halt(2); End;
  End
  Else If InName='' Then InName:=S
  Else Begin WriteLn('Param'+#138+'tre en trop: ',S); Halt(2); End;
 End;
 If InName='' Then Begin Usage; Halt(1); End;
End;

Procedure FillBuf(Pos:LongInt);
Var R:Word;
Begin
 Seek(InFile,Pos);
 BufLen:=SizeOf(Buf);
 If Pos+BufLen>FSize Then BufLen:=FSize-Pos;
 If BufLen<=0 Then Begin BufLen:=0; BufBase:=Pos; Exit; End;
 BlockRead(InFile,Buf,BufLen,R);
 BufLen:=R;
 BufBase:=Pos;
End;

Function GetByte(Pos:LongInt; Var B:Byte):Boolean;
Begin
 If (Pos<BufBase) Or (Pos>=BufBase+BufLen) Then FillBuf(Pos);
 If (Pos<BufBase) Or (Pos>=BufBase+BufLen) Then Begin
  GetByte:=False; Exit;
 End;
 B:=Buf[Pos-BufBase];
 GetByte:=True;
End;

Procedure WrHex2(B:Byte);
Const Hex:String[16]='0123456789ABCDEF';
Begin
 Write(Hex[(B Shr 4)+1],Hex[(B And 15)+1]);
End;

Procedure WrHex4(W:LongInt);
Begin
 WrHex2(Byte((W Shr 8) And $FF));
 WrHex2(Byte(W And $FF));
End;

Procedure WrHex6(L:LongInt);
Begin
 WrHex2(Byte((L Shr 16) And $FF));
 WrHex4(L And $FFFF);
End;

Procedure PadTo(Col:Integer; CurCol:Integer);
Begin
 While CurCol<Col Do Begin Write(' '); Inc(CurCol); End;
End;

{ Lit BIG ' partir de Pos. Retourne valeur, met Used ' 1 ou 2. }
Function ReadBig(Pos:LongInt; Var Used:Integer):LongInt;
Var B1,B2:Byte;
Begin
 ReadBig:=0; Used:=0;
 If Not GetByte(Pos,B1) Then Exit;
 If B1<128 Then Begin Used:=1; ReadBig:=B1; End
 Else Begin
  If Not GetByte(Pos+1,B2) Then Begin Used:=1; ReadBig:=B1 And $7F; Exit; End;
  Used:=2;
  ReadBig:=LongInt(B1 And $7F)*256+B2;
 End;
End;

{ D'sassemble une instruction ' partir de PC. Retourne taille consomm'e. }
Function DisOne(IPC:LongInt):Integer;
Var Op,B,B2:Byte; W:LongInt; Used:Integer; I,N:Integer;
    BytesShown:Integer; HexCol:Integer; Mn:TMnem;
    C:Char; Lo,Hi:Byte;
Label DoneOps;
Begin
 If Not GetByte(IPC,Op) Then Begin DisOne:=0; Exit; End;
 { Adresse + opcode hex. }
 WrHex6(IPC); Write('  ');
 WrHex2(Op); Write(' ');
 BytesShown:=1; HexCol:=6+2+3;
 { On va d'abord pr'parer mn'monique et op'randes en m'moire ? Non, on
   imprime les octets d'op'rande, puis on PadTo une colonne, puis le texte. }
 { Premi'rement r'soudre la taille pour imprimer tous les octets en hex. }
 { Strat'gie simple: r'imprimer les octets via une 2e passe. }
 { Pour simplifier, on imprime le mn'monique apr's avoir lu les op'randes. }
 If Op<128 Then Begin
  PadTo(30,HexCol);
  Write('SLDC ',Op);
  WriteLn;
  DisOne:=1;
  Exit;
 End;
 Mn:=Mnem128[Op];
 Case Kind128[Op] Of
  OPK_NONE: Begin
   PadTo(30,HexCol); Write(Mn);
   { CSP n'a pas d'op'rande dans Kind128? Si: OPK_UB pour 158. }
   WriteLn; DisOne:=1; Exit;
  End;
  OPK_UB: Begin
   If Not GetByte(IPC+1,B) Then Begin WriteLn(Mn,' ?'); DisOne:=1; Exit; End;
   WrHex2(B); Write(' '); Inc(HexCol,3);
   PadTo(30,HexCol); Write(Mn,' ',B);
   If Op=158 Then Begin { CSP }
    If B<=CSPMax Then Write('  ; ',CSPName[B])
    Else Write('  ; CSP#',B);
   End;
   WriteLn; DisOne:=2; Exit;
  End;
  OPK_SB: Begin
   If Not GetByte(IPC+1,B) Then Begin WriteLn(Mn,' ?'); DisOne:=1; Exit; End;
   WrHex2(B); Write(' '); Inc(HexCol,3);
   PadTo(30,HexCol); Write(Mn,' ');
   If B<128 Then Write('+',B,'   ; -> $') Else Write(Integer(B)-256,'  ; -> $');
   If B<128 Then WrHex6(IPC+2+B) Else WrHex6(IPC+2+B-256);
   WriteLn; DisOne:=2; Exit;
  End;
  OPK_W: Begin
   If Not GetByte(IPC+1,Lo) Then Begin WriteLn(Mn,' ?'); DisOne:=1; Exit; End;
   If Not GetByte(IPC+2,Hi) Then Begin WriteLn(Mn,' ?'); DisOne:=2; Exit; End;
   WrHex2(Lo); Write(' '); WrHex2(Hi); Write(' '); Inc(HexCol,6);
   W:=LongInt(Hi)*256+Lo;
   If W>=32768 Then W:=W-65536;
   PadTo(30,HexCol); Write(Mn,' ',W); WriteLn; DisOne:=3; Exit;
  End;
  OPK_BIG: Begin
   W:=ReadBig(IPC+1,Used);
   If Used=0 Then Begin WriteLn(Mn,' ?'); DisOne:=1; Exit; End;
   For I:=0 To Used-1 Do Begin
    GetByte(IPC+1+I,B); WrHex2(B); Write(' '); Inc(HexCol,3);
   End;
   PadTo(30,HexCol); Write(Mn,' ',W); WriteLn;
   DisOne:=1+Used; Exit;
  End;
  OPK_UBUB: Begin
   If Not GetByte(IPC+1,B) Then Begin WriteLn(Mn,' ?'); DisOne:=1; Exit; End;
   If Not GetByte(IPC+2,B2) Then Begin WriteLn(Mn,' ?'); DisOne:=2; Exit; End;
   WrHex2(B); Write(' '); WrHex2(B2); Write(' '); Inc(HexCol,6);
   PadTo(30,HexCol); Write(Mn,' ',B,',',B2); WriteLn;
   DisOne:=3; Exit;
  End;
  OPK_UBBIG: Begin
   If Not GetByte(IPC+1,B) Then Begin WriteLn(Mn,' ?'); DisOne:=1; Exit; End;
   WrHex2(B); Write(' '); Inc(HexCol,3);
   W:=ReadBig(IPC+2,Used);
   If Used=0 Then Begin PadTo(30,HexCol); WriteLn(Mn,' ',B,',?'); DisOne:=2; Exit; End;
   For I:=0 To Used-1 Do Begin
    GetByte(IPC+2+I,B2); WrHex2(B2); Write(' '); Inc(HexCol,3);
   End;
   PadTo(30,HexCol); Write(Mn,' ',B,',',W); WriteLn;
   DisOne:=2+Used; Exit;
  End;
  OPK_DBBIG: Begin
   If Not GetByte(IPC+1,B) Then Begin WriteLn(Mn,' ?'); DisOne:=1; Exit; End;
   WrHex2(B); Write(' '); Inc(HexCol,3);
   W:=ReadBig(IPC+2,Used);
   If Used=0 Then Begin PadTo(30,HexCol); WriteLn(Mn,' L',B,',?'); DisOne:=2; Exit; End;
   For I:=0 To Used-1 Do Begin
    GetByte(IPC+2+I,B2); WrHex2(B2); Write(' '); Inc(HexCol,3);
   End;
   PadTo(30,HexCol); Write(Mn,' L',B,',',W); WriteLn;
   DisOne:=2+Used; Exit;
  End;
  OPK_LSA: Begin
   If Not GetByte(IPC+1,B) Then Begin WriteLn(Mn,' ?'); DisOne:=1; Exit; End;
   WrHex2(B); Write(' '); Inc(HexCol,3);
   N:=B;
   { Affiche au plus 6 octets de chars en hex pour la colonne. }
   For I:=0 To N-1 Do Begin
    If Not GetByte(IPC+2+I,B2) Then Begin N:=I; Break; End;
    If I<6 Then Begin WrHex2(B2); Write(' '); Inc(HexCol,3); End;
   End;
   If N>6 Then Begin Write('.. '); Inc(HexCol,3); End;
   PadTo(30,HexCol); Write(Mn,' ',B,',"');
   For I:=0 To N-1 Do Begin
    GetByte(IPC+2+I,B2);
    If (B2>=32)And(B2<127) Then Begin C:=Chr(B2); Write(C); End
    Else Write('.');
   End;
   Write('"'); WriteLn;
   DisOne:=2+N; Exit;
  End;
  OPK_LDC: Begin
   If Not GetByte(IPC+1,B) Then Begin WriteLn(Mn,' ?'); DisOne:=1; Exit; End;
   WrHex2(B); Write(' '); Inc(HexCol,3);
   N:=B*2;
   For I:=0 To N-1 Do Begin
    If Not GetByte(IPC+2+I,B2) Then Begin N:=I; Break; End;
    If I<4 Then Begin WrHex2(B2); Write(' '); Inc(HexCol,3); End;
   End;
   If N>4 Then Begin Write('.. '); Inc(HexCol,3); End;
   PadTo(30,HexCol); Write(Mn,' ',B,' words');
   WriteLn;
   DisOne:=2+N; Exit;
  End;
  OPK_XJP: Begin
   { XJP: tableau de cas. Trop complexe pour analyse statique sans
     contexte de proc. On affiche juste l'instruction. }
   PadTo(30,HexCol); Write(Mn,' (table de cas)'); WriteLn;
   DisOne:=1; Exit;
  End;
 End;
 { Fallback inattendu. }
DoneOps:
 PadTo(30,HexCol); Write(Mn); WriteLn;
 DisOne:=1;
End;

Procedure Run2;
Var EndPC:LongInt; Sz:Integer;
Begin
 Assign(InFile,InName); {$I-} Reset(InFile,1); {$I+}
 If IOResult<>0 Then Begin
  WriteLn('Erreur: impossible d''ouvrir ',InName); Halt(3);
 End;
 FSize:=FileSize(InFile);
 BufBase:=-1; BufLen:=0;
 If StartOff>=FSize Then Begin
  WriteLn('Offset hors fichier (taille=',FSize,')'); Close(InFile); Halt(4);
 End;
 If MaxBytes<0 Then EndPC:=FSize
 Else Begin
  EndPC:=StartOff+MaxBytes;
  If EndPC>FSize Then EndPC:=FSize;
 End;
 Write('Fichier   : ',InName,'  (',FSize,' octets)'); WriteLn;
 Write('D'+#130+'but     : $'); WrHex6(StartOff);
 Write('   Fin: $'); WrHex6(EndPC); WriteLn;
 WriteLn('Addr     Hex                       Instruction');
 WriteLn('------   -----------------------   -----------------------');
 PC:=StartOff;
 While PC<EndPC Do Begin
  Sz:=DisOne(PC);
  If Sz<=0 Then Break;
  Inc(PC,Sz);
 End;
 Close(InFile);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or
   (ParamStr(1)='-h')or(ParamCount=0)Then Begin
  Usage;
  Halt;
 End;
 ParseCmd;
 Run2;
END.
