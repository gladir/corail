{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)

  Assembleur de p-Code UCSD p-System (II.0/II.1 - Heath/Apple Pascal).

  Lit un fichier source assembleur (typiquement la sortie de DISPCODE)
  et produit un fichier binaire de p-Code.

  Le format accept' tol're:
   - colonnes d'adresse et octets hex (sortie DISPCODE), elles sont ignor'es
   - commentaires '; ...' jusqu'a fin de ligne
   - lignes vides, en-t'tes ('Fichier', 'D'but', 'Addr', '------')
   - mn'moniques en majuscules ou minuscules

  Mn'moniques support's:
   SLDC n           (0..127)            -> 1 octet (= n)
   SLDL1..SLDL16                        -> 1 octet (216..231)
   SLDO1..SLDO16                        -> 1 octet (232..247)
   SIND0..SIND7                         -> 1 octet (248..255)
   <op> sans op'rande                   -> 1 octet
   FJP/UJP/EFJ/NFJ +/-n                 -> 1+1 (SB sign')
   CSP n / ADJ n / SAS n / LDP n / STP n / LDM n / STM n
   RNP n / CIP n / RBP n / CBP n / CLP n / CGP n
   EQU/GEQ/GRT/LEQ/LES/NEQ n            -> 1+1 (UB)
   LDCI n                               -> 1+2 (W little-endian)
   INC/IND/IXA/LAO/SRO/LDO/LLA/LDL/STL/MOV n  -> 1+BIG
   LDE/LAE/STE s,o                      -> 1+UB+BIG
   LDA/LOD/STR L<lvl>,off               -> 1+DB+BIG
   CXP s,p / IXP a,b / LPA s,i          -> 1+UB+UB
   LSA n,"texte"                        -> 1+UB+chars
   LDC n,$w1,$w2,...                    -> 1+UB+n*W
   DB $XX,$XX,...                       -> octets bruts (directive)

  Limitations: XJP (case-jump) g'n're 1 octet seul ; pour la table de cas
  utiliser DB.
}

Program ASMPCODE;

{$A-}
{$IFDEF FPC}{$MODE TP}{$ENDIF}

Uses DOS;

Const
 OPK_NONE  = 0;
 OPK_UB    = 1;
 OPK_SB    = 2;
 OPK_W     = 3;
 OPK_BIG   = 4;
 OPK_UBUB  = 5;
 OPK_UBBIG = 6;
 OPK_DBBIG = 7;
 OPK_LSA   = 8;
 OPK_LDC   = 9;
 OPK_XJP   = 10;
 OPK_SLDC  = 200;
 OPK_DB    = 201;

Type
 TMnem=String[6];

Const
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

 Kind128:Array[128..255]Of Byte = (
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_UBBIG,OPK_UB,OPK_NONE,
  OPK_UB,OPK_SB,OPK_BIG,OPK_BIG,OPK_BIG,OPK_BIG,OPK_LSA,OPK_UBBIG,
  OPK_BIG,OPK_BIG,OPK_UB,OPK_BIG,OPK_XJP,OPK_UB,OPK_UB,OPK_UB,
  OPK_UB,OPK_UB,OPK_DBBIG,OPK_LDC,OPK_UB,OPK_UB,OPK_DBBIG,OPK_UB,
  OPK_DBBIG,OPK_SB,OPK_NONE,OPK_NONE,OPK_UB,OPK_UB,OPK_NONE,OPK_NONE,
  OPK_UBUB,OPK_UB,OPK_UB,OPK_NONE,OPK_NONE,OPK_NONE,OPK_BIG,OPK_W,
  OPK_NONE,OPK_NONE,OPK_BIG,OPK_NONE,OPK_BIG,OPK_UBUB,OPK_UB,OPK_UB,
  OPK_UBUB,OPK_UBBIG,OPK_NONE,OPK_SB,OPK_SB,OPK_NONE,OPK_NONE,OPK_NONE,
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,
  OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE,OPK_NONE
 );

Var
 InFile:Text;
 OutFile:File;
 BBuf:Array[0..4095]Of Byte;
 BLen:Integer;
 OutPos:LongInt;
 LineNum:LongInt;
 ErrCount:Integer;
 InName,OutName:String;

Procedure FlushBuf;
Var Wr:Word;
Begin
 If BLen>0 Then Begin BlockWrite(OutFile,BBuf,BLen,Wr); BLen:=0; End;
End;

Procedure Emit(B:Byte);
Begin
 BBuf[BLen]:=B; Inc(BLen); Inc(OutPos);
 If BLen>=SizeOf(BBuf) Then FlushBuf;
End;

Procedure Err(Msg:String);
Begin
 WriteLn('Ligne ',LineNum,': ',Msg); Inc(ErrCount);
End;

Procedure EmitUB(V:LongInt);
Begin
 If (V<0) Or (V>255) Then Begin Err('UB hors limite'); V:=0; End;
 Emit(Byte(V));
End;

Procedure EmitSB(V:LongInt);
Begin
 If (V<-128) Or (V>127) Then Begin Err('SB hors limite'); V:=0; End;
 If V<0 Then V:=V+256;
 Emit(Byte(V));
End;

Procedure EmitW(V:LongInt);
Begin
 If V<0 Then V:=V+65536;
 Emit(Byte(V And $FF));
 Emit(Byte((V Shr 8) And $FF));
End;

Procedure EmitBig(V:LongInt);
Begin
 If (V<0) Or (V>32767) Then Begin Err('BIG hors limite'); V:=0; End;
 If V<128 Then Emit(Byte(V))
 Else Begin
  Emit(Byte($80 Or ((V Shr 8) And $7F)));
  Emit(Byte(V And $FF));
 End;
End;

Function IsDigit(C:Char):Boolean;
Begin IsDigit:=(C>='0')And(C<='9'); End;

Function IsHexDigit(C:Char):Boolean;
Begin
 IsHexDigit:=IsDigit(C) Or ((C>='A')And(C<='F')) Or ((C>='a')And(C<='f'));
End;

Function IsAlpha(C:Char):Boolean;
Begin
 IsAlpha:=((C>='A')And(C<='Z')) Or ((C>='a')And(C<='z'));
End;

Procedure SkipSp(Var P:Integer; S:String);
Begin
 While (P<=Length(S)) And ((S[P]=' ') Or (S[P]=#9)) Do Inc(P);
End;

Function ParseNum(Var P:Integer; S:String; Var V:LongInt):Boolean;
Var Sign:Integer; HasH,Got:Boolean; D:Integer; C:Char;
Begin
 SkipSp(P,S);
 ParseNum:=False; V:=0; Sign:=1; Got:=False; HasH:=False;
 If P>Length(S) Then Exit;
 If S[P]='+' Then Inc(P)
 Else If S[P]='-' Then Begin Sign:=-1; Inc(P); End;
 If (P<=Length(S)) And (S[P]='$') Then Begin HasH:=True; Inc(P); End;
 While P<=Length(S) Do Begin
  C:=S[P];
  If HasH Then Begin
   If Not IsHexDigit(C) Then Break;
   If IsDigit(C) Then D:=Ord(C)-Ord('0')
   Else D:=Ord(UpCase(C))-Ord('A')+10;
   V:=V*16+D; Got:=True;
  End
  Else Begin
   If Not IsDigit(C) Then Break;
   V:=V*10+(Ord(C)-Ord('0')); Got:=True;
  End;
  Inc(P);
 End;
 V:=V*Sign;
 ParseNum:=Got;
End;

Function ParseId(Var P:Integer; S:String; Var Id:String):Boolean;
Begin
 SkipSp(P,S); Id:='';
 If (P>Length(S)) Or (Not IsAlpha(S[P])) Then Begin ParseId:=False; Exit; End;
 While (P<=Length(S)) And (IsAlpha(S[P]) Or IsDigit(S[P])) Do Begin
  Id:=Id+UpCase(S[P]); Inc(P);
 End;
 ParseId:=True;
End;

Function ParseQStr(Var P:Integer; S:String; Var Q:String):Boolean;
Begin
 SkipSp(P,S); Q:='';
 If (P>Length(S)) Or (S[P]<>'"') Then Begin ParseQStr:=False; Exit; End;
 Inc(P);
 While (P<=Length(S)) And (S[P]<>'"') Do Begin
  Q:=Q+S[P]; Inc(P);
 End;
 If P>Length(S) Then Err('cha'+#238+'ne non termin'+#130+'e')
 Else Inc(P);
 ParseQStr:=True;
End;

Function ExpectComma(Var P:Integer; S:String):Boolean;
Begin
 SkipSp(P,S);
 If (P>Length(S)) Or (S[P]<>',') Then Begin ExpectComma:=False; Exit; End;
 Inc(P); ExpectComma:=True;
End;

Function LookupMn(Mn:String; Var Code:Byte; Var Kind:Byte):Boolean;
Var I,P:Integer; N:LongInt;
Begin
 LookupMn:=False;
 If Mn='SLDC' Then Begin Code:=0; Kind:=OPK_SLDC; LookupMn:=True; Exit; End;
 If Mn='DB' Then Begin Code:=0; Kind:=OPK_DB; LookupMn:=True; Exit; End;
 If (Copy(Mn,1,4)='SLDL') And (Length(Mn)>=5) Then Begin
  P:=5;
  If ParseNum(P,Mn,N) And (N>=1) And (N<=16) Then Begin
   Code:=Byte(215+N); Kind:=OPK_NONE; LookupMn:=True; Exit;
  End;
 End;
 If (Copy(Mn,1,4)='SLDO') And (Length(Mn)>=5) Then Begin
  P:=5;
  If ParseNum(P,Mn,N) And (N>=1) And (N<=16) Then Begin
   Code:=Byte(231+N); Kind:=OPK_NONE; LookupMn:=True; Exit;
  End;
 End;
 If (Copy(Mn,1,4)='SIND') And (Length(Mn)>=5) Then Begin
  P:=5;
  If ParseNum(P,Mn,N) And (N>=0) And (N<=7) Then Begin
   Code:=Byte(248+N); Kind:=OPK_NONE; LookupMn:=True; Exit;
  End;
 End;
 For I:=128 To 255 Do
  If Mnem128[I]=Mn Then Begin
   Code:=Byte(I); Kind:=Kind128[I]; LookupMn:=True; Exit;
  End;
End;

Function IsPrefixTok(S:String):Boolean;
Var I:Integer;
Begin
 IsPrefixTok:=False;
 If S='..' Then Begin IsPrefixTok:=True; Exit; End;
 If (Length(S)<>2) And (Length(S)<>6) Then Exit;
 For I:=1 To Length(S) Do
  If Not IsHexDigit(S[I]) Then Exit;
 IsPrefixTok:=True;
End;

Function FindMn(S:String):Integer;
Var P,Q:Integer; Tok:String;
Begin
 FindMn:=0; P:=1;
 While P<=Length(S) Do Begin
  While (P<=Length(S)) And (S[P]=' ') Do Inc(P);
  If P>Length(S) Then Exit;
  Q:=P;
  While (Q<=Length(S)) And (S[Q]<>' ') Do Inc(Q);
  Tok:=Copy(S,P,Q-P);
  If Not IsPrefixTok(Tok) Then Begin FindMn:=P; Exit; End;
  P:=Q;
 End;
End;

Procedure ProcessLine(S:String);
Var I,P:Integer; Mn,Q:String; Code,Kind:Byte; V,V2:LongInt;
Begin
 I:=Pos(';',S); If I>0 Then S:=Copy(S,1,I-1);
 While (Length(S)>0) And ((S[Length(S)]=' ')Or(S[Length(S)]=#9)Or(S[Length(S)]=#13)) Do
  S:=Copy(S,1,Length(S)-1);
 If S='' Then Exit;
 If (Pos('Addr',S)=1) Or (Pos('------',S)>=1) Or (Pos('Fichier',S)=1)
    Or (Pos('D'+#130+'but',S)=1) Or (Pos('Debut',S)=1)
    Or (Pos('Total',S)=1) Then Exit;
 P:=FindMn(S); If P=0 Then Exit;
 If Not ParseId(P,S,Mn) Then Exit;
 If Not LookupMn(Mn,Code,Kind) Then Begin
  Err('mn'+#130+'monique inconnu: '+Mn); Exit;
 End;
 Case Kind Of
  OPK_SLDC: Begin
   If Not ParseNum(P,S,V) Then Begin Err('SLDC: nombre attendu'); Exit; End;
   If (V<0) Or (V>127) Then Begin Err('SLDC hors limite (0..127)'); Exit; End;
   Emit(Byte(V));
  End;
  OPK_DB: Begin
   While ParseNum(P,S,V) Do Begin
    EmitUB(V);
    If Not ExpectComma(P,S) Then Break;
   End;
  End;
  OPK_NONE: Emit(Code);
  OPK_UB: Begin
   Emit(Code);
   If Not ParseNum(P,S,V) Then Err('UB attendu') Else EmitUB(V);
  End;
  OPK_SB: Begin
   Emit(Code);
   If Not ParseNum(P,S,V) Then Err('SB attendu') Else EmitSB(V);
  End;
  OPK_W: Begin
   Emit(Code);
   If Not ParseNum(P,S,V) Then Err('W attendu') Else EmitW(V);
  End;
  OPK_BIG: Begin
   Emit(Code);
   If Not ParseNum(P,S,V) Then Err('BIG attendu') Else EmitBig(V);
  End;
  OPK_UBUB: Begin
   Emit(Code);
   If Not ParseNum(P,S,V) Then Begin Err('UB,UB attendu'); Exit; End;
   If Not ExpectComma(P,S) Then Begin Err('virgule attendue'); Exit; End;
   If Not ParseNum(P,S,V2) Then Begin Err('2e UB attendu'); Exit; End;
   EmitUB(V); EmitUB(V2);
  End;
  OPK_UBBIG: Begin
   Emit(Code);
   If Not ParseNum(P,S,V) Then Begin Err('UB,BIG attendu'); Exit; End;
   If Not ExpectComma(P,S) Then Begin Err('virgule attendue'); Exit; End;
   If Not ParseNum(P,S,V2) Then Begin Err('BIG attendu'); Exit; End;
   EmitUB(V); EmitBig(V2);
  End;
  OPK_DBBIG: Begin
   Emit(Code);
   SkipSp(P,S);
   If (P<=Length(S)) And (UpCase(S[P])='L') Then Inc(P);
   If Not ParseNum(P,S,V) Then Begin Err('DB level attendu'); Exit; End;
   If Not ExpectComma(P,S) Then Begin Err('virgule attendue'); Exit; End;
   If Not ParseNum(P,S,V2) Then Begin Err('BIG attendu'); Exit; End;
   EmitUB(V); EmitBig(V2);
  End;
  OPK_LSA: Begin
   Emit(Code);
   If Not ParseNum(P,S,V) Then Begin Err('LSA: len attendu'); Exit; End;
   If Not ExpectComma(P,S) Then Begin Err('virgule attendue'); Exit; End;
   If Not ParseQStr(P,S,Q) Then Begin Err('"..." attendu'); Exit; End;
   If Length(Q)<>V Then Err('LSA: longueur ne correspond pas');
   EmitUB(V);
   For I:=1 To Length(Q) Do Emit(Byte(Q[I]));
  End;
  OPK_LDC: Begin
   Emit(Code);
   If Not ParseNum(P,S,V) Then Begin Err('LDC: count attendu'); Exit; End;
   EmitUB(V);
   For I:=1 To V Do Begin
    If Not ExpectComma(P,S) Then Begin Err('virgule attendue'); Exit; End;
    If Not ParseNum(P,S,V2) Then Begin Err('mot attendu'); Exit; End;
    EmitW(V2);
   End;
  End;
  OPK_XJP: Begin
   Emit(Code);
   Err('XJP: tableau de cas non support'+#130+', utiliser DB pour la suite');
  End;
 End;
End;

Procedure Usage;Begin
 WriteLn('ASMPCODE : Cette commande permet de lancer l''assembleur ',
         'p-Code UCSD p-System.');
 WriteLn;
 WriteLn('Syntaxe: ASMPCODE source[.ASM] [destination[.CODE]]');
 WriteLn;
 WriteLn(' source.ASM        Ce parametre permet d''indiquer l''assembleur p-Code');
 WriteLn(' destination.CODE  Ce parametre permet d''indiquer le fichier binaire p-Code');
 WriteLn;
 WriteLn('  Si destination omise, remplace l''extension de source par .CODE');
End;

Function ReplaceExt(Const Name,NewExt:String):String;
Var I,LastDot,LastSep:Integer;
Begin
 LastDot:=0; LastSep:=0;
 For I:=1 To Length(Name) Do Begin
  If Name[I]='.' Then LastDot:=I;
  If (Name[I]='\') Or (Name[I]='/') Or (Name[I]=':') Then LastSep:=I;
 End;
 If LastDot>LastSep Then ReplaceExt:=Copy(Name,1,LastDot-1)+NewExt
 Else ReplaceExt:=Name+NewExt;
End;

Function StrUpper(S:String):String;
Var I:Integer;
Begin
 For I:=1 To Length(S) Do S[I]:=UpCase(S[I]);
 StrUpper:=S;
End;

Var
 Line:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or
   (ParamStr(1)='-h')or(ParamCount=0)Then Begin
  Usage;
  Halt;
 End;
 If ParamCount<1 Then Begin Usage; Halt(1); End;
 InName:=ParamStr(1);
 If ParamCount>=2 Then OutName:=ParamStr(2)
 Else OutName:=ReplaceExt(InName,'.CODE');
 If StrUpper(OutName)=StrUpper(InName) Then Begin
  WriteLn('Erreur: source et destination identiques'); Halt(2);
 End;
 Assign(InFile,InName); {$I-} Reset(InFile); {$I+}
 If IOResult<>0 Then Begin WriteLn('Erreur: ouverture ',InName); Halt(2); End;
 Assign(OutFile,OutName); {$I-} Rewrite(OutFile,1); {$I+}
 If IOResult<>0 Then Begin WriteLn('Erreur: cr'+#130+'ation ',OutName); Halt(2); End;
 OutPos:=0; BLen:=0; LineNum:=0; ErrCount:=0;
 While Not EOF(InFile) Do Begin
  ReadLn(InFile,Line); Inc(LineNum);
  ProcessLine(Line);
 End;
 FlushBuf;
 Close(InFile); Close(OutFile);
 WriteLn('Assembl'+#130+' : ',OutPos,' octet(s), ',ErrCount,' erreur(s)');
 If ErrCount>0 Then Halt(1);
END.
