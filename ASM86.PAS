{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}


Program ASM86;

{$R-,S-,I+,F-,V-,B-,N-}

Uses DOS;

Const
 CommentColumn=25;
 SymbolLength=32;
 CR=13;
 Lf=10;
 Tab=9;
 Maxbyte=MaxInt;
 BigStringSize=127;

Type
 SymString=String[SymbolLength];
 IndxReg=(BX, SI, DI, BP, None);
 IndxSet=Set of IndxReg;
 PtrType=(BPtr, WPtr, DwPtr, QwPtr, TbPtr, UnkPtr);
 String4=String[4];
 String5=Array[1..5] of Char;
 Symtype=(Address, Disp8, Disp16, Othersym, EOLsym, Identifier, JmpDist,
   LfBrack, RtBrack, Plus, Comma, STsym);
 Table=Array[0..20] of SymString;
 BigString=String[BigStringSize];
 Label_Info_ptr = ^Label_Info;
 Label_Info=Record
  Name:SymString;
  ByteCnt:Integer;
  Next:Label_Info_ptr;
 End;
 Fixup_Info_Ptr=^Fixup_Info;
 Fixup_Info=Record
  Name:SymString;
  Indx,Indx2,Fix_pt:Integer;
  Jmptype:(Short,Med);
  Prev,Next:Fixup_Info_Ptr;
 End;

Var
 Language:(_Albanian,_Danish,_French,_English,_Germany,_Italian,_Spain,_Swedish);
 TmpLanguage:String;
 Option:Set of (ShowInstrInComment,InlineForTurboPascal,BinaryFile);
 NoAddrs,Aerr,Symbol,TheEnd,NewFnd,St_first,Displace,WordSize,Wait_Already:Boolean;
 Addr:Integer;
 Sym:Symtype;
 ModeByte,Reg1,Reg2,W1,W2,Sti_val:Integer;
 SaveOfs,DataVal:Record
  Symb:Boolean;
  Sname:SymString;
  Value:Integer;
 End;
 IRset:IndxSet;
 Rmm,Md:Integer;
 ByWord:PtrType;
 Byt,SignExt:Byte;
 Tindex,Tindex0,Column,I,ByteCount,LastSlash:Integer;
 TextArray:Array[0..Maxbyte] of Char;
 Lsid:SymString;
 Str8:Array[1..9] of Char;
 Str:String5 Absolute Str8;
 ID2:Array[1..2] of Char Absolute Str8;
 ID3:Array[1..3] of Char Absolute Str8;
 UCh,LCh:Char;
 Chi,OldChi:Integer;
 SourceFile,TargetFile:Text;
 Binary:File of Byte;
 Start_Col:Integer;
 St:BigString;
 Firstlabel,Pl:Label_Info_ptr;
 Firstfix,Pf:Fixup_Info_Ptr;
 Segm,NValue:Integer;
 Symname:SymString;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function Path2Ext(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2Ext:=E;
End;

Function Path2DirName(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2DirName:=D+N;
End;

Procedure Space(N:Integer);
Var
 I:Integer;
Begin
 For I:=1 to N do Write(' ');
End;

Procedure Error(II:Integer;S:BigString);Begin
 If Not Aerr Then Begin
  WriteLn(St);
  Space(Start_Col+II-4);
  Write('^Erreur');
  If Length(S) > 0 Then Write(', ',S);
  WriteLn;
  Aerr := True;
 End;
End;

Procedure GetCh;Begin
 If Chi<=Ord(St[0])Then LCh:=St[Chi]
                   Else LCh:=Chr(CR);
 UCh:=UpCase(LCh);
 Chi:=Chi+1;
End;

Procedure SkipSpaces;Begin
 While (UCh = ' ') or (UCh = Chr(Tab)) do GetCh;
End;

Function GetDec(Var V:Integer):Boolean;
Const
 Ssize=8;
Var
 S:String[Ssize];
 Getd:Boolean;
 Code:Integer;
Begin
 Getd:=False;
 S:='';
 While(UCh>='0')and(UCh<='9')do Begin
  Getd:=True;
  If Ord(S[0])<Ssize Then S:=S+UCh;
  GetCh;
 End;
 If(Getd)Then Begin
  Val(S,V,Code);
  If Code<>0 Then Error(Chi,'Mauvais format de nombre');
 End;
 GetDec:=Getd;
End;

Function EvalHex(hexStr:String):Integer;
Var
 hexVal,i,n:Integer;
 evalErr:Boolean;
Begin
 evalErr:=False;
 hexVal:=0;
 For i:=1 TO Length(hexStr)do Begin
  n:=Pos(Upcase(hexStr[i]),'0123456789ABCDEF');
  If n=0 Then evalErr:=True
         Else hexVal:=hexVal*16+n-1;
 End;
 If(evalErr)Then Begin
  hexVal:=0;
  Error(Chi,'Nombre hexadecimal invalide');
 END;
 EvalHex:=hexVal;
End;

Function GetDecOrHex(Var V:Integer):Boolean;
Const
 Ssize=8;
Var
 Mode:(_Dec,_Hex);
 S:String[Ssize];
 Getd:Boolean;
 Code:Integer;
Begin
 Getd:=False;
 S:='';
 Mode:=_Dec;
 If(UCh in['0'..'9'])Then Begin
  GetD:=True;
  If Ord(S[0])<Ssize Then S:=S+UCh;
  GetCh;
  While(UCh in['A'..'F', '0'..'9'])do Begin
   If(UCh in['A'..'F'])Then Mode:=_Hex;
   Getd:=True;
   If Ord(S[0])<Ssize Then S:=S+UCh;
   GetCh;
  End;
  If(Mode=_Hex)Then Begin
   If(UCh<>'H')Then Error(Chi,'Nombre hexad‚cimal sans identificateur ''h''')
               Else GetCh;
  End
   Else
  If UCh='H'Then Begin
   Mode:=_Hex;
   GetCh;
  End;
 End;
 If(Getd)Then Begin
  If(Mode=_Dec)Then Val(S,V,Code)
   Else
  Begin
   Code:=0;
   V:=EvalHex(S);
  End;
  If Code<>0 Then Error(Chi,'Mauvais format de nombre');
 End;
 GetDecOrHex:=Getd;
End;

Function GetHex(Var H:Integer):Boolean;
Var
 Digit:Integer;
Begin
 H:=0;
 GetHex:=False;
 While(UCh in ['A'..'F', '0'..'9'])do Begin
  GetHex:=True;
  If(UCh>='A')Then Digit:=Ord(UCh)-Ord('A')+10
              Else Digit:=Ord(UCh)-Ord('0');
  If H and $F000<>0 Then Error(Chi,'D‚bordement');
  H:=(H Shl 4)+Digit;
  GetCh;
 End;
End;

Function GetNumber(Var N:Integer):Boolean;
Var
 Term:Char;
 Err:Boolean;
Begin
 N:=0;
 If UCh='('Then GetCh;
 If(UCh='''')or(UCh='"')Then Begin
  GetNumber:=True;
  Term:=UCh;
  GetCh;
  Err:=False;
  While(UCh<>Term)and Not Err do Begin
   Err:=N and $FF00 <> 0;
   N:=(N Shl 8)+Ord(LCh);
   GetCh;
   If(Err)Then Error(Chi, 'D‚bordement');
  End;
  GetCh;
 End
  Else
 If UCh='$'Then Begin
  GetCh;
  If Not GetHex(N)Then Error(Chi,'Expression de nombre hexad‚cimal');
  GetNumber:=True;
 End
  Else
 GetNumber:=GetDecOrHex(N);
 If UCh=')'Then GetCh;
End;

Function GetExpr(Var Rslt:Integer):Boolean;
Var
 Rs1,Rs2,SaveChi:Integer;
 Pos,Neg:Boolean;
Begin
 SaveChi:=Chi;
 GetExpr:=False;
 SkipSpaces;
 Neg:=UCh='-';
 Pos:=UCh='+';
 If Pos or Neg Then GetCh;
 If GetNumber(Rs1)Then Begin
  GetExpr:=True;
  If Neg Then Rs1:=-Rs1;
  If (UCh='+')or(UCh='-')Then
  If GetExpr(Rs2)Then Rs1:=Rs1+Rs2;
  Rslt:=Rs1;
 End
  Else
 Begin
  Chi:=SaveChi-1;
  GetCh;
 End;
End;

{$V+}
Function GetSymbol(Var S:SymString):Boolean;
Const
 Symchars:Set of Char = ['A'..'Z', '0'..'9', '_', '+', '-','$','*'];
Begin
 If UCh in Symchars Then Begin
  GetSymbol:=True;
  S[0]:=Chr(0);
  While UCh in Symchars do Begin
   If Ord(S[0])<SymbolLength Then S:=S+UCh;
   GetCh;
  End
 End
  Else
 GetSymbol:=False;
End;
{$V-}

Function GetAddress:Boolean;
Var
 Resultat:Boolean;
 SaveChi:Integer;
Begin
 Resultat:=False;
 SaveChi:=Chi;
 If GetExpr(Segm)Then Begin
  SkipSpaces;
  If UCh = ':'Then Begin
   GetCh;
   SkipSpaces;
   Resultat:=GetExpr(NValue);
  End;
 End;
 GetAddress:=Resultat;
 If Not Resultat Then Begin
  Chi := SaveChi-1;
  GetCh;
 End;
End;

Procedure ErrNull;Begin
 Error(Chi, '');
End;

Procedure ErrIncorrect;Begin
 Error(Chi,'Incorrecte ou pas d''operande');
End;

Procedure SegmErr;Begin
 Error(Chi,'Registre de segment n''est pas permis');
End;

Procedure WordReg;Begin
 Error(Chi,'Word Reg Exp');
End;

Procedure DataLarge;Begin
 Error(Chi, 'Donnees trop large');
End;

Procedure Chk_BwPtr;Begin
 If ByWord >= DwPtr Then Error(Chi,'BYTE ou WORD Requis');
End;

Function ByteSize(Val:Integer):Boolean;Begin
 ByteSize:=(Hi(Val) = 0)or(Val and $FF80 = $FF80);
End;

Function ShortSize(Val:Integer):Boolean;Begin
 ShortSize:=(Val >= -128) and (Val<=127);
End;

Function ReadByte:Boolean;
Var
 Rb:Boolean;
Begin
 Rb:=GetExpr(NValue);
 If Rb Then
  If ByteSize(NValue)Then Byt := Lo(NValue)
                     Else DataLarge;
 ReadByte := Rb;
End;

Function MatchSt(Var Table;Size,Maxindx:Integer;Var Indx:Integer):Boolean;
Var
 Ca:Array[0..MaxInt] of Char Absolute Table;
 Rslt:Boolean;

 Function EqArray(Var A1;N:Integer):Boolean;
 Type
  Bigarray=Array[1..MaxInt] of Char;
 Var
   B1:Bigarray Absolute A1;
   I:Integer;
 Begin
  For I := 1 to N do If B1[I] <> Str8[I] Then Begin
   EqArray:=False;
   Exit;
  End;
  EqArray := Str8[N+1] = ' ';
 End;

Begin
 Indx:=0;
 Rslt:=False;
 While(Indx<=Maxindx) and not Rslt do If EqArray(Ca[Indx*Size],Size)Then Rslt:=True
                                                                    Else Indx:=Indx+1;
 MatchSt:=Rslt;
End;

Procedure GetString;
Var
 I:Integer;
Begin
 SkipSpaces;
 Lsid:='          ';
 I:=1;
 If(UCh >= 'A')and(UCh <= 'Z')Then Begin
  While(UCh >= 'A')and(UCh <= 'Z')or(UCh >= '0')and(UCh<='9') do Begin
   If I <= SymbolLength Then Begin
    Lsid[I]:=UCh;
    I:=I+1;
   End;
   GetCh;
  End;
 End;
 Lsid[0] := Chr(I-1);
 Move(Lsid[1],Str8,9);
End;

Procedure InsertChr(C:Char);Begin
 If Tindex<Maxbyte Then Begin
  TextArray[Tindex]:=C;
  Tindex:=Tindex+1;
  Column:=Column+1;
 End
  Else
 Begin
  WriteLn('Debordement de code objet !');
  Halt(1);
 End;
End;

Procedure InsertStr(S:BigString);
Var
 I:Integer;
Begin
 For I:=1 to Ord(S[0]) do InsertChr(S[I]);
End;

Procedure InsertByte(B:Byte);Begin
 If(InlineForTurboPascal in Option)Then InsertChr('$');
 InsertStr(ByteHex2Str(B));
 ByteCount:=ByteCount+1;
 LastSlash:=Tindex;
 If(InlineForTurboPascal in Option)Then InsertChr('/');
 If(BinaryFile in Option)Then Write(Binary,B);
 Wait_Already:=False;
End;

Procedure InsertWord(W:Integer);Begin
 InsertByte(Lo(W));
 InsertByte(Hi(W));
End;

Procedure InsertHi_Low(W:Integer);Begin
 InsertByte(Hi(W));
 InsertByte(Lo(W));
End;

Procedure InsertWait;Begin
 If Not Wait_Already Then InsertByte($9B);
End;

Procedure Modify_Byte(I:Integer;Modify:Byte);
Var
 St:String4;
 J:Integer;

 Function HexToByte(I:Integer;Var J:Integer):Byte;
 Var
  Resultat,Tmp:Byte;
  K:Integer;
  C:Char;
 Const Hex:Set of Char = ['0'..'9', 'A'..'F'];
 Begin
  Resultat:=0;
  While Not(TextArray[I] in Hex) do I:=I+1;
  J := I;
  For K:=I to I+1 do Begin
   C := TextArray[K];
   if C <= '9' then Tmp := Ord(C)-Ord('0') else Tmp := Ord(C)-Ord('A')+10;
   Resultat:=(Resultat Shl 4)+Tmp;
  End;
  HexToByte:=Resultat;
 End;

Begin
 St:=ByteHex2Str(HexToByte(I,J)+Modify);
 TextArray[J]:=St[1];
 TextArray[J+1]:=St[2];
End;

Procedure DoNext;
Var
 TmpCh:Char;
Begin
 OldChi := Chi;
 Symbol := False;
 If Sym = EOLsym Then Exit;
 SkipSpaces;
 If(UCh=Chr(CR))or(UCh=';')Then Sym:=EOLsym Else
 If UCh=','Then Begin
  Sym:=Comma;
  GetCh;
 End
  Else
 If(UCh='>')or(UCh='<')Then Begin
  TmpCh:=UCh;
  GetCh;
  If Not GetSymbol(Symname)Then Error(Chi,'Expression de nom de symbole');
  If TmpCh = '<'Then Sym:=Disp8
                Else Sym:=Disp16;
  Symbol:=True;
 End
  Else
 If GetAddress Then Begin
  If NoAddrs Then ErrNull
             Else Sym:=Address;
 End
  Else
 If GetExpr(NValue)Then Begin
  If ByteSize(NValue)Then Sym:=Disp8
                     Else Sym:=Disp16;
 End
  Else
 If(UCh>='A')and(UCh<='Z')Then Begin
  GetString;
  Symname:=Lsid;
  If(Lsid = 'FAR')or(Lsid='NEAR')or(Lsid='SHORT')Then Sym:=JmpDist Else
  If Lsid = 'ST'Then Sym:=STsym
                Else Sym:=Identifier;
 End
  Else
 If UCh='+'Then Begin
  Sym:=Plus;
  GetCh;
 End
  Else
 If UCh='['Then Begin
  Sym:=LfBrack;
  GetCh;
 End
  Else
 If UCh=']'Then Begin
  Sym:=RtBrack;
  GetCh;
 End
  Else
 Begin
  Sym:=Othersym;
  GetCh;
 End;
End;

Procedure NextA;
Var
 Tmp:PtrType;
 Indx:Integer;
Const
 Ptrary:Array[0..4] of String[2] = ('BY', 'WO', 'DW', 'QW', 'TB');
 Ptrary1:Array[0..4] of String[5]=('BYTE','WORD','DWORD','QWORD','TBYTE');
Begin
 DoNext;
 If Sym=Identifier Then Begin
  Tmp:=BPtr;
  Indx:=0;
  While(Tmp<UnkPtr)and(Lsid<>Ptrary[Indx])and(Lsid<>Ptrary1[Indx])do Begin
   Tmp:=Succ(Tmp);
   Indx:=Indx+1;
  End;
  If Tmp<UnkPtr Then Begin
   ByWord:=Tmp;
   DoNext;
  End;
  If Str='PTR  'Then DoNext;
 End;
End;

Procedure Displace_Bytes(W:Integer);
Var
 C:Char;
Begin
 If Displace Then With SaveOfs do Begin
  If Symb Then Begin
   If W=1 Then C:='>'
          Else C :='<';
   InsertStr(C+Sname);
   If Value<>0 Then InsertStr('+$'+ByteHex2Str(Hi(Value))+ByteHex2Str(Lo(Value)));
   If W=1 Then ByteCount:=ByteCount+2
          Else ByteCount:=ByteCount+1;
   LastSlash:=Tindex;
   If(InlineForTurboPascal in Option)Then InsertChr('/');
  End
   Else
  If W=1 then InsertWord(Value) else InsertByte(Lo(Value));
 End;
End;

Procedure DataBytes(WordSize:Boolean);
Var
 C:Char;
Begin
 With DataVal do Begin
  If Symb Then Begin
   If WordSize Then C:='>'
               Else C:='<';
   InsertStr(C+Sname);
   If Value<>0 Then InsertStr('+$'+ByteHex2Str(Hi(Value))+ByteHex2Str(Lo(Value)));
   If WordSize Then ByteCount := ByteCount+2
               Else ByteCount:=ByteCount+1;
   LastSlash:=Tindex;
   If(InlineForTurboPascal in Option)Then InsertChr('/')
                                     Else InsertChr(' ');
  End
   Else
  If WordSize Then InsertWord(Value)
              Else InsertByte(Lo(Value));
 End;
End;

Function GetIR:Boolean;
Var
 Reg:IndxReg;
Begin
 GetIR:=False; Reg:=None;
 If(Sym=Identifier)and(Lsid[0]=Chr(2))Then
  If ID2='BX'Then Reg:=BX Else
  If ID2='SI'Then Reg:=SI Else
  If ID2='DI'Then Reg:=DI Else
  If ID2='BP'Then Reg:=BP;
 If Reg <> None Then Begin
  IRset:=IRset+[Reg];
  GetIR:=True;
  NextA;
 End;
End;

Function MemReg(Var W:Integer):Boolean;
Label 10;
Var
 SaveChi:Integer;
 Dsp16,OldAddrs,Result_MemReg:Boolean;
Begin
 SaveChi:=OldChi;
 Dsp16:=False;
 Result_MemReg:=False;
 OldAddrs:=NoAddrs;
 NoAddrs:=True;
 SaveOfs.Value:=0;
 SaveOfs.Symb:=False;
 IRset:=[];
 While(Sym<>Comma)and(Sym<>EOLsym) do Begin
  If Sym=LfBrack Then Begin
   Result_MemReg:=True;
   NextA;
  End;
  If Sym=Plus Then NextA;
  If(Sym=Disp8)or(Sym=Disp16)Then With SaveOfs do Begin
   Dsp16 := Dsp16 or (Sym = Disp16);
   If Symbol Then Begin
    Symb:=True;
    Sname:=Symname;
   End
    Else
   Value:=Value+NValue;
   NextA;
  End
   Else
  If Not GetIR Then
   If Sym = RtBrack Then NextA Else
   If Result_MemReg Then Begin
    Error(Chi, 'Virgule ou expression de fin de ligne');
    NextA;
   End
    else
   Goto 10;
  End;
  If Result_MemReg Then Begin
   If(IRset = [])or(IRset = [BP])Then Rmm:=6 Else
   If IRset=[BX,SI]Then Rmm:=0 Else
   If IRset=[BX,DI]Then Rmm:=1 Else
   If IRset=[BP,SI]Then Rmm:=2 Else
   If IRset=[BP,DI]Then Rmm:=3 Else
   If IRset=[SI]Then Rmm:=4 Else
   If IRset=[DI]Then Rmm:=5 Else
   If IRset=[BX]Then Rmm:=7
                Else Error(Chi, 'Combinaison de registre invalide');
   NextA;
   With SaveOfs do Dsp16:=Dsp16 or(Symb and(Value <> 0))or Not ShortSize(Value);
   If IRset = []Then Begin
    Displace:=True;
    Md:=0;
    W:=1;
   End
    Else
   If(IRset=[BP]) and Not Dsp16 Then Begin
    Displace:=True;
    Md:=1; W:=0;
   End
    Else
   If(SaveOfs.Value = 0) and Not(SaveOfs.Symb)Then Begin
    Displace:=False;
    Md:=0;
    W:=3;
   End
    Else
   If Not Dsp16 Then Begin
    Displace:=True;
    Md:=1;
    W:=0;
   End
    Else
   Begin
    Displace:=True;
    Md:=2;
    W:=1;
   End;
   ModeByte := 64*Md+Rmm;
  End
   Else
10:Begin
  Chi:=SaveChi-1;
  GetCh;
  NextA;
 End;
 NoAddrs:=OldAddrs;
 MemReg:=Result_MemReg;
End;

Function St_St:Boolean;
Var
 Err,Rslt:Boolean;

 Function GetSti_Val:Boolean;
 Var
  Grslt:Boolean;
 Begin
  NextA;
  Grslt:=Sym=Disp8;
  If Grslt Then Begin
   Sti_val := NValue;
   Err:=((Sti_val and $F8)<>0);
   NextA;
  End;
  GetSti_Val := Grslt;
 End;

Begin
 Err:=False;
 Rslt:=Sym=STsym;
 If Rslt Then Begin
  If GetSti_Val Then Begin
   St_first:=False;
   While(Sym=Comma)or(Sym=STsym) do NextA;
  End
   Else
  Begin
   St_first:=True;
   If Sym=Comma then NextA;
   If Sym = STsym Then Begin
    If Not GetSti_Val Then Err:=True;
   End
    Else
   Err:=True;
  End;
  If Err Then ErrNull;
 End;
St_St:=Rslt;
End;

Function FstiOnly:Boolean;
Const
  Stiary:Array[0..7] of Word=($DEC0,$DEC8,$DEE8,$DEE0,$DEF8,$DEF0,$DDC0,$D9C8);
  StiOnlyTable:Array[0..7,0..5] of Char=(
   'FADDP ','FMULP ','FSUBP ','FSUBRP', 'FDIVP ', 'FDIVRP', 'FFREE ', 'FXCH  '
  );
Var
 Indx:Integer;
 Rslt:Boolean;
Begin
 Rslt:=MatchSt(StiOnlyTable,6,7,Indx);
 If Rslt Then Begin
  NextA;
  If Not St_St Then Begin
   If Sym=EOLsym Then Sti_val:=1
                 Else ErrIncorrect;
  End;
  InsertWait;
  InsertHi_Low(Stiary[Indx]+Sti_val);
 End;
 FstiOnly:=Rslt;
End;

Function FmemOnly:Boolean;
Const
 MemAry:Array[0..12] of Word=($D920,$D928,$D930,$D938,$DF30,$DF20,$DD20,$DD30,$DD38,$DD30,$D938,$D930,$DD38);
 MemOnlyTable:Array[0..12, 0..6] of Char=(
  'FLDENV ','FLDCW  ','FSTENV ','FSTCW  ','FBSTP  ','FBLD   ','FRSTOR ',
  'FSAVE  ', 'FSTSW  ','FNSAVE ', 'FNSTCW ', 'FNSTENV', 'FNSTSW '
 );
Var
 Indx:Integer;
 Rslt:Boolean;
Begin
 Rslt:=MatchSt(MemOnlyTable,7,12,Indx);
 If Rslt Then Begin
  NextA;
  If Indx<9 Then InsertWait;
  If MemReg(W1) Then Begin
   InsertHi_Low(Memary[Indx]+ModeByte);
   Displace_Bytes(W1);
  End
   Else
  ErrIncorrect;
 End;
 FmemOnly:=Rslt;
End;

Function FldType:Boolean;
Const
  Fldarray:Array[0..2, DwPtr..UnkPtr] of Word = (
   ($D900,$DD00,$DB28,$D9C0),
   ($D910,$DD10,0,    $DDD0),
   ($D918,$DD18,$DB38,$DDD8));
  Fldtable:Array[0..2, 0..3] of Char = ('FLD ', 'FST ', 'FSTP');
Var
 Indx,Tmp:Integer;
 Rslt:Boolean;
Begin
 Rslt:=MatchSt(Fldtable,4,2,Indx);
 If Rslt Then Begin
  NextA;
  InsertWait;
  If ByWord >= DwPtr Then Tmp:=Fldarray[Indx, ByWord];
  If MemReg(W1)Then Begin
   If(ByWord>=DwPtr)and(ByWord<=TbPtr)Then Begin
    InsertHi_Low(Tmp+ModeByte);
    Displace_Bytes(W1);
    If Tmp = 0 Then Error(Chi, 'TBYTE n''est pas permis');
   End
    Else
   Error(Chi, 'DWORD, QWORD ou TBYTE requis');
  End
   Else
  If St_St Then InsertHi_Low(Tmp+Sti_val)
           Else ErrIncorrect;
 End;
 FldType:=Rslt;
End;

Function FildType:Boolean;
Const
  Fildarray:Array[0..2, WPtr..QwPtr] of Word=(
   ($DF00, $DB00, $DF28),
   ($DF10, $DB10, 0),
   ($DF18, $DB18, $DF38));
  Fildtable:Array[0..2, 0..4] of Char=('FILD ', 'FIST ', 'FISTP');
Var
 Indx,Tmp:Integer;
 Rslt:Boolean;
Begin
 Rslt:=MatchSt(Fildtable,5,2,Indx);
 If Rslt Then Begin
  NextA;
  If MemReg(W1)Then Begin
   If(ByWord >= WPtr)and(ByWord <= QwPtr)Then Begin
    InsertWait;
    Tmp:=Fildarray[Indx, ByWord];
    InsertHi_Low(Tmp+ModeByte);
    Displace_Bytes(W1);
    If Tmp = 0 Then Error(Chi, 'QWORD n''est pas permis');
   End
    else
   Error(Chi, 'WORD, DWORD ou QWORD est requis');
  End
   Else
  ErrIncorrect;
 End;
 FildType := Rslt;
End;

Function FaddType:Boolean;
Const Faddtable:Array[0..7, 0..4] of Char=(
  'FADD ','FMUL ','FCOM ','FCOMP','FSUB ','FSUBR','FDIV ','FDIVR');
Var
 Indx:Integer;
 Rslt:Boolean;
Begin
 Rslt:=False;
 If MatchSt(Faddtable,5,7,Indx)Then Begin
  NoAddrs:=True;
  Rslt:=True;
  NextA;
  InsertWait;
  If MemReg(W1)Then Begin
   If ByWord=DwPtr Then InsertByte($D8) Else
   If ByWord=QwPtr Then InsertByte($DC)
                   Else Error(Chi, 'DWORD ou QWORD est requis');
   InsertByte(ModeByte+8*Indx);
   Displace_Bytes(W1);
  End
   Else
  If St_St Then Begin
   If St_first or(Indx = 2)or(Indx = 3)Then InsertByte($D8)
                                       Else InsertByte($DC);
   ModeByte := $C0+8*Indx+Sti_val;
   If Not St_first and (Indx >= 6)Then ModeByte:=ModeByte Xor 8;
   InsertByte(ModeByte);
  End
   Else
  ErrIncorrect;
 End;
 FaddType:=Rslt;
End;

Function FiaddType:Boolean;
Const Fiaddtable:Array[0..7, 0..5]of Char=(
  'FIADD ','FIMUL ','FICOM ','FICOMP','FISUB ','FISUBR','FIDIV ','FIDIVR');
Var
 Indx:Integer;
 Rslt:Boolean;
Begin
 Rslt:=False;
 If MatchSt(Fiaddtable,6,7,Indx)Then Begin
  NoAddrs:=True;
  Rslt:=True;
  NextA;
  If MemReg(W1)Then Begin
   InsertWait;
   If ByWord = DwPtr Then InsertByte($DA)Else
   If ByWord = WPtr Then InsertByte($DE)
                    Else Error(Chi,'WORD ou DWORD est requis');
   InsertByte(ModeByte+8*Indx);
   Displace_Bytes(W1);
  End
   else
  ErrIncorrect;
 End;
 FiaddType:=Rslt;
End;

Function Fnoperand:Boolean;
Const
 Fnoptable :Array[0..32, 0..6] of Char =(
  'FNOP   ', 'FCHS   ', 'FABS   ', 'FTST   ', 'FXAM   ',
  'FLD1   ', 'FLDL2T ', 'FLDL2E ', 'FLDPI  ', 'FLDLG2 ', 'FLDLN2 ',
  'FLDZ   ', 'F2XM1  ', 'FYL2X  ', 'FPTAN  ', 'FPATAN ', 'FXTRACT',
  'FDECSTP', 'FINCSTP', 'FPREM  ', 'FYL2XP1', 'FSQRT  ', 'FRNDINT',
  'FSCALE ', 'FENI   ', 'FDISI  ', 'FCLEX  ', 'FINIT  ', 'FCOMPP ',
  'FNCLEX ', 'FNDISI ', 'FNENI  ', 'FNINIT '
 );
 Fnopcode:Array[0..32] of Word=(
  $D9D0, $D9E0, $D9E1, $D9E4, $D9E5, $D9E8,
  $D9E9, $D9EA, $D9EB, $D9EC, $D9ED, $D9EE,
  $D9F0, $D9F1, $D9F2, $D9F3, $D9F4, $D9F6,
  $D9F7, $D9F8, $D9F9, $D9FA, $D9FC, $D9FD,
  $DBE0, $DBE1, $DBE2, $DBE3, $DED9,
  $DBE2, $DBE1, $DBE0, $DBE3
 );
Var
 Indx:Integer;
 Rslt:Boolean;
Begin
 Rslt:=MatchSt(Fnoptable,7,32,Indx);
 If Rslt Then Begin
  NextA;
  If Indx<29 Then InsertWait;
  InsertHi_Low(Fnopcode[Indx]);
 End;
 Fnoperand:=Rslt;
End;

Function Register(Var R,W:Integer):Boolean;
Const
 Regarray:Array[0..15] of Array[1..2] of Char=(
  'AL', 'CL', 'DL', 'BL', 'AH', 'CH', 'DH', 'BH',
  'AX', 'CX', 'DX', 'BX', 'SP', 'BP', 'SI', 'DI'
 );
Var
 Result_Reg:Boolean;
Begin
 Result_Reg:=False;
 If(Lsid[0]=Chr(2))and(Sym=Identifier)Then Begin
  R:=-1;
  Repeat
   R:=R+1;
  Until (R>15)or(ID2=Regarray[R]);
  Result_Reg:=R<=15;
  If Result_Reg Then Begin
   NextA;
   If Sym=Comma Then NextA;
  End;
  W:=R div 8;
  R:=R and 7;
 End;
 Register:=Result_Reg;
End;

Function SegRegister(Var R:Integer):Boolean;
Var
 Result_Segr:Boolean;
Begin
 If(Sym=Identifier)and(Lsid[0]=Chr(2))Then Begin
  Result_Segr:=True;
  If ID2='ES'Then R:=0 Else
  If ID2='CS'Then R:=1 Else
  If ID2='SS'Then R:=2 Else
  If ID2='DS'Then R:=3
             Else Result_Segr:=False;
  If Result_Segr Then Begin
   NextA;
   If Sym = Comma Then NextA;
  End;
 End
  Else
 Result_Segr:=False;
 SegRegister:=Result_Segr;
End;

Function Data(Var Wd:Boolean):Boolean;
Var
 SaveChi:Integer;
 Resultat:Boolean;
Begin
 Resultat := False; Wd := False;
 SaveChi := OldChi;
 With DataVal do Begin
  Value:=0;
  Symb:=False;
  While (Sym=Disp8)or(Sym=Disp16) do Begin
   Resultat:=True;
   If Symbol Then Begin
    Wd:=Wd or (Sym=Disp16);
    Symb:=True;
    Sname:=Symname;
   End
    else
   Value:=Value+NValue;
   NextA;
   If Sym = Plus Then NextA;
  End;
  Resultat:=(Sym = EOLsym) and Resultat;
  Wd:=Wd or not ByteSize(Value);
 End;
 Data:=Resultat;
 If Not Resultat Then Begin
  Chi:=SaveChi-1;
  GetCh;
  NextA;
 End;
End;

Function TwoOperands:Boolean;
Label 2;
Type
 InsType=(Mov,Adc,Addx,Andx,Cmp,Orx,Sbb,Sub,Xorx,Test,Xchg,Lds,Les,Lea);
 Codetype=Array[Mov..Lea] of Byte;
 Shcodetype=Array[Mov..Test] of Byte;
Var
 Inst:InsType;
 Tmp:Byte;

Const
 Instname:Array[Mov..Lea] of Array[1..5] of Char=(
  'MOV  ','ADC  ','ADD  ','AND  ','CMP  ','OR   ',
  'SBB  ','SUB  ','XOR  ','TEST ','XCHG ','LDS  ',
  'LES  ','LEA  ');
 Immedop:Codetype=($C6,$80,$80,$80,$80,$80,$80,$80,$80,$F6,0,0,0,0);
 Immedreg:Codetype=(0,$10,0,$20,$38,8,$18,$28,$30,0,0,0,0,0);
 Memregop:Codetype=($88,$10,0,$20,$38,8,$18,$28,$30,$84,$86,$C5,$C4,$8D);
 Shimmedop:Shcodetype=(0,$14,4,$24,$3C,$C,$1C,$2C,$34,$A8);

 Function ChkSignExt(WordSize:Boolean):Byte;Begin
  If(Immedop[Inst]=$80)and WordSize and ShortSize(DataVal.Value)Then ChkSignExt:=2
                                                                Else ChkSignExt:=0;
 End;

Begin
 TwoOperands:=False;
 For Inst:=Mov to Lea do If Str = Instname[Inst]Then Goto 2;
 Exit;
2:
 NoAddrs:=True;
 TwoOperands:=True;
 NextA;
 If Register(Reg1, W1)Then Begin
  If Register(Reg2, W2)Then Begin
   If Inst >= Lds Then Error(Chi, 'Registre non permis');
    If W1 <> W2 then Error(Chi, 'Registres incompatible');
    If(Inst=Xchg)and((W1=1)and((Reg1=0)or(Reg2=0)))Then InsertByte($90+Reg1+Reg2)
     Else
    Begin
     InsertByte(Memregop[Inst]+W1);
     InsertByte($C0+Reg1+8*Reg2);
    End;
   End
    Else
   If SegRegister(Reg2)Then Begin
    If(W1 = 0)or(Inst<>Mov)Then SegmErr;
    InsertByte($8C); InsertByte($C0+8*Reg2+Reg1);
   End
    Else
   If Data(WordSize)Then Begin
    If Inst >= Xchg then Error(Chi, 'Valeur immediate non permis');
    If(Ord(WordSize)>W1)Then DataLarge;
    SignExt:=ChkSignExt(W1=1);
    If(Inst=Mov)Then InsertByte($B0+8*W1+Reg1) Else
    If(Reg1=0)Then Begin
     InsertByte(Shimmedop[Inst]+W1);
     SignExt:=0;
    End
     Else
    Begin
     InsertByte(Immedop[Inst]+W1+SignExt);
     InsertByte($C0+Immedreg[Inst]+Reg1);
    End;
    DataBytes((SignExt = 0) and (W1 > 0));
   End
    Else
   If MemReg(W2)Then Begin
    If(Inst=Mov)and(Reg1=0)and(Rmm=6)and(Md=0)Then InsertByte($A0+W1)
     Else
    Begin
     Tmp:=Memregop[Inst];
     If Inst<=Xchg Then Begin
      Tmp:=Tmp+W1;
      If Inst<>Test Then Tmp:=Tmp or 2;
     End;
     InsertByte(Tmp);
     InsertByte(ModeByte+8*Reg1);
    End;
    Displace_Bytes(W2);
   End
   Else ErrNull;
  End
   Else
  If SegRegister(Reg1)Then Begin
  if Inst <> Mov then SegmErr;
  InsertByte($8E);
  If Register(Reg2, W2)Then Begin
   If(W2 = 0)Then WordReg;
   InsertByte($C0+8*Reg1+Reg2);
  End
   Else
  If MemReg(W2)Then Begin
   InsertByte(ModeByte+8*Reg1);
   Displace_Bytes(W2);
  End
   Else
  ErrNull;
 End
  Else
 If MemReg(W1)and(Inst <= Xchg)Then Begin
  If Register(Reg2, W2)Then Begin
   If(W2 > Ord(ByWord))Then Error(Chi, 'Byte Reg Exp');
   If(Inst=Mov)and(Reg2=0)and(Rmm=6)and(Md=0)Then Begin
    InsertByte($A2+W2);
   End
    else
   Begin
    InsertByte(Memregop[Inst]+W2);
    InsertByte(ModeByte+8*Reg2);
   End;
   Displace_Bytes(W1);
  End
   Else
  If SegRegister(Reg2)Then Begin
   If(Inst<>Mov)Then SegmErr;
   InsertByte($8C); InsertByte(ModeByte+8*Reg2);
   Displace_Bytes(W1);
  End
   Else
  If(Data(WordSize))and(Inst<Xchg)Then Begin
   Chk_BwPtr;
   If(Ord(WordSize) > Ord(ByWord))Then DataLarge;
   SignExt := ChkSignExt(ByWord=WPtr);
   InsertByte(Immedop[Inst]+Ord(ByWord)+SignExt);
   InsertByte(ModeByte+Immedreg[Inst]);
   Displace_Bytes(W1);
   DataBytes((SignExt=0) and (ByWord = WPtr));
  End
  Else ErrNull;
 End
  else
 If(Sym = Disp8)or(Sym = Disp16)Then Error(Chi, 'Valeur immediate non permise')
                                Else ErrNull;
End;

Function OneOperand:Boolean;
Type
 InsType=(Dec, Inc, Push, Pop, Nott, Neg);
 Codetype=Array[Dec..Neg] of Byte;
Var
 Inst:InsType;
 Pushpop:Boolean;
Const
  Instname:Array[Dec..Neg] of Array[1..5] of Char=(
   'DEC  ','INC  ','PUSH ','POP  ','NOT  ','NEG  ');
  Regop:Codetype = ($48,$40,$50,$58, 0, 0);
  Segregop : Codetype = (0, 0, 6, 7, 0, 0);
  Memregop : Codetype = ($FE,$FE,$FF,$8F,$F6,$F6);
  Memregcode : Codetype = ($8, 0, $30, 0, $10, $18);
Begin
 OneOperand := False;
 For Inst:=Dec to Neg do If Str = Instname[Inst]Then Begin
  Pushpop:=(Inst=Push)or(Inst=Pop);
  NoAddrs:=True;
  OneOperand:=True;
  NextA;
  If Register(Reg1, W1)Then Begin
   If(W1 = 1)and(Inst < Nott)Then Begin
    InsertByte(Regop[Inst]+Reg1);
   End
    Else
   Begin
    InsertByte(Memregop[Inst]+W1);
    InsertByte($C0+Memregcode[Inst]+Reg1);
    If Pushpop Then WordReg;
   End
  End
   Else
  If SegRegister(Reg1)Then Begin
   InsertByte(Segregop[Inst]+8*Reg1);
   If Not Pushpop Then SegmErr
  End
   Else
  If MemReg(W1)Then Begin
   If Not Pushpop Then Chk_BwPtr;
   InsertByte(Memregop[Inst] or Ord(ByWord));
   InsertByte(ModeByte+Memregcode[Inst]);
   Displace_Bytes(W1);
  End
   Else
  ErrIncorrect;
 End;
End;

Function NoOperand:Boolean;
Const
 Nmbsop=31;
 Sop:Array[0..Nmbsop] of Array[1..5] of Char=(
  'DAA  ', 'AAA  ', 'NOP  ', 'MOVSB', 'MOVSW', 'CMPSB', 'CMPSW',
  'XLAT ', 'HLT  ',
  'CMC  ', 'DAS  ', 'AAS  ', 'CBW  ', 'CWD  ', 'PUSHF',
  'POPF ', 'SAHF ', 'LAHF ', 'STOSB', 'STOSW', 'LODSB', 'LODSW',
  'SCASB', 'SCASW', 'INTO ', 'IRET ', 'CLC  ', 'STC  ', 'CLI  ',
  'STI  ', 'CLD  ', 'STD  ');
 Opcode : Array[0..Nmbsop] of Byte = (
  $27, $37, $90, $A4, $A5, $A6, $A7, $D7, $F4,
  $F5, $2F, $3F, $98, $99, $9C, $9D, $9E, $9F, $AA, $AB, $AC, $AD,
  $AE, $AF, $CE, $CF, $F8, $F9, $FA, $FB, $FC, $FD);
Var
 Index:Integer;
Begin
 NoOperand := False;
 For Index:=0 to Nmbsop do If Str = Sop[Index]Then Begin
  InsertByte(Opcode[Index]);
  NoOperand := True;
  NextA;
  Exit;
 End;
End;

Function Prefix:Boolean;
Const
 Nmbsop=11;
 Ops:Array[0..Nmbsop] of String5=(
   'LOCK ','REP  ','REPZ ','REPNZ','REPE ','REPNE','WAIT ','FWAIT',
   'ES   ','DS   ','CS   ','SS   ');
 Opcode : Array[0..Nmbsop] of Byte = (
  $F0, $F2, $F3, $F2, $F3, $F2, $9B, $9B, $26, $3E, $2E, $36);
Var
 Index:Integer;
 SaveWait:Boolean;
 Opc:Byte;
Begin
 Prefix:=False;
 For Index:=0 to Nmbsop do If Str = Ops[Index]Then Begin
  Opc:=Opcode[Index];
  SaveWait:=Wait_Already;
  InsertByte(Opc);
  Wait_Already:=SaveWait or (Opc=$9B);
  Tindex0:=Tindex;
  If UCh=':'Then GetCh;
  Prefix:=True;
  Exit;
 End;
End;

Function FindLabel(Var B:Integer):Boolean;
Var
 Found:Boolean;
Begin
 Pl:=Firstlabel;
 Found:=False;
 While(Pl <> Nil) and Not Found do With Pl^ do If Symname = Name Then Begin
  Found := True;
  B:=ByteCnt;
 End
  Else
 Pl:=Next;
 FindLabel:=Found;
End;

Function ShortJmp:Boolean;
Const
 NumJmp=34;
 Jumps:Array[0..Numjmp] of Array[1..5] of Char=(
  'JO   ', 'JNO  ', 'JB   ', 'JNAE ', 'JNB  ', 'JAE  ',
  'JE   ', 'JZ   ', 'JNE  ', 'JNZ  ', 'JBE  ', 'JNA  ',
  'JNBE ', 'JA   ', 'LOOPN', 'LOOPZ', 'LOOPE', 'LOOP ',
  'JCXZ ', 'JS   ', 'JNS  ', 'JP   ', 'JPE  ', 'JNP  ',
  'JPO  ', 'JL   ', 'JNGE ', 'JNL  ', 'JGE  ', 'JLE  ',
  'JNG  ', 'JNLE ', 'JG   ', 'JC   ', 'JNC  '
 );
 Opcode : Array[0..Numjmp] of Byte=(
  $70, $71, $72, $72, $73, $73, $74, $74, $75, $75, $76, $76,
  $77, $77, $E0, $E1, $E1, $E2, $E3, $78, $79, $7A, $7A, $7B,
  $7B, $7C, $7C, $7D, $7D, $7E, $7E, $7F, $7F, $72, $73);
Var
 I,B:Integer;
Begin
 ShortJmp:=False;
 For I:=0 to NumJmp do If Str = Jumps[I]Then Begin
  InsertByte(Opcode[I]);
  ShortJmp:=True;
  NoAddrs:=True;
  NextA;
  If Sym = Identifier Then Begin
   If FindLabel(B) Then Begin
    Addr := B-(ByteCount+1);
    If(Addr <= $7F)and(Addr >= -128)Then InsertByte(Lo(Addr))
                                    Else Error(Chi, 'Trop long');
   End
    Else
   Begin
    New(Pf);
    With Pf^ do Begin
     Next:=Firstfix;
     If Firstfix<>Nil Then Firstfix^.Prev := Pf;
     Firstfix:=Pf;
     Prev:=Nil;
     Jmptype:=Short;
     Name:=Symname;
     Fix_pt:=ByteCount;
     Indx:=Tindex;
     InsertByte(0);
    End;
   End;
   NextA;
  End
  Else Error(Chi, 'Expression d''etiquette');
 End;
End;

Function ShfRot:Boolean;
Type
  InsType = (Rclx, Rcrx, Rolx, Rorx, Salx, Sarx, Shlx, Shrx);
Const
 Instname:Array[Rclx..Shrx] of Array[1..3] of Char = (
  'RCL','RCR','ROL','ROR','SAL','SAR','SHL','SHR'
 );
 Regcode:Array[Rclx..Shrx] of Byte=($10, $18, 0, 8, $20, $38, $20, $28);
Var
  Inst:InsType;
  CL:Byte;
Begin
 ShfRot:=False;
 If Lsid[0]=Chr(3) Then For Inst:=Rclx to Shrx do If ID3=Instname[Inst]Then Begin
  NoAddrs:=True;
  ShfRot:=True;
  NextA;
  InsertByte($D0);
  If Register(Reg1, W1)Then InsertByte($C0+Regcode[Inst]+Reg1) Else
  If MemReg(W2)Then Begin
   Chk_BwPtr;
   W1:=Ord(ByWord);
   InsertByte(ModeByte+Regcode[Inst]);
   Displace_Bytes(W2);
  End
   Else
  Error(Chi, 'Registre ou expression de memoire');
  If Sym=Comma Then NextA;
  CL:=0;
  If(Sym=Identifier)and(ID3='CL ')Then CL:=2 else
  If NValue<>1 Then Error(Chi, 'CL ou une expression 1');
  NextA;
  Modify_Byte(Tindex0, CL+W1);
 End;
End;

Function CallJmp:Boolean;
Type
 InsType=(CALL,JMP);
 Codetype=Array[CALL..JMP] of Byte;
Const
  Shortop:Codetype=($E8,$E9);
  Longop:Codetype=($9A,$EA);
  Longcode:Codetype=($18,$28);
  Shortcode:Codetype=($10,$20);
Var
 Inst:InsType;
 Dist:(Nodist,Long,Shrt,Near);
 Tmp:Byte;
 Dwtmp:PtrType;
 B:Integer;
 WordSize:Boolean;
Begin
 CallJmp:=False;
 If Str='CALL 'Then Inst:=CALL Else
 If Str='JMP  'Then Inst:=JMP
               Else Exit;
 CallJmp:=True;
 NextA;
 Dist:=Nodist;
 Dwtmp:=ByWord;
 If Sym=JmpDist Then Begin
  If ID2='FA'Then Dist:=Long Else
  If ID2='NE'Then Dist:=Near Else
  If ID2='SH'Then Dist:=Shrt;
  NextA;
 End;
 If(Sym=Address)Then Begin
  InsertByte(Longop[Inst]);
  InsertWord(NValue);
  InsertWord(Segm);
 End
  Else
 If Register(Reg1, W1)Then Begin
  If W1 = 0 Then WordReg;
  If Dist = Long Then Error(Chi, 'FAR n''est pas permis');
  InsertByte($FF);
  InsertByte($C0+Shortcode[Inst]+Reg1);
 End
  Else
 If Sym = Identifier Then Begin
  If Dist = Long Then Error(Chi, 'Far n''est pas permis avec un etiquette');
  If FindLabel(B) Then Begin
   Addr:=B-(ByteCount+2);
   If Inst = CALL Then Begin
    InsertByte($E8);
    InsertWord(Addr-1);
   End
    Else
   If(Addr<=$7F)and(Addr>=-128)and(Dist<>Near)Then Begin
    InsertByte($EB);
    InsertByte(Lo(Addr));
   End
    Else
   Begin
    InsertByte($E9);
    InsertWord(Addr-1);
   End;
  End
   Else
  Begin
   New(Pf);
   With Pf^ do Begin
    Next := Firstfix;
    If Firstfix <> Nil Then Firstfix^.Prev:=Pf;
    Firstfix:=Pf;
    Prev:=Nil;
    Name:=Symname;
    If Dist=Shrt Then Begin
     Jmptype:=Short;
     InsertByte($EB);
     Fix_pt:=ByteCount;
     Indx:=Tindex;
     InsertByte(0);
    End
     Else
    Begin
     Jmptype:=Med;
     If Inst = CALL Then InsertByte($E8)
                    Else InsertByte($E9);
     Fix_pt:=ByteCount;
     Indx:=Tindex;
     InsertByte(0);
     Indx2:=Tindex;
     InsertByte(0);
    End;
   End;
  End;
 End
  Else
 If Data(WordSize)Then Begin
  If(Inst=JMP)and(Dist=Shrt)Then Begin
   If WordSize Then Error(Chi,'Doit etre une taille d''octet');
   InsertByte($EB);
   DataBytes(False);
  End
   Else
  Begin
   If Not((Dist=Nodist)or(Dist=Near))or(Dwtmp<>UnkPtr)Then
    Error(Chi, 'Seulement NEAR est permis');
   If Not(WordSize)Then Error(Chi, 'Doit etre une taille de mot');
   InsertByte(Shortop[Inst]);
   DataBytes(True);
  End;
 End
  Else
 If MemReg(W1)Then Begin
  If(Dist=Long)or(Dwtmp=DwPtr)Then Tmp:=Longcode[Inst]
                              Else Tmp:=Shortcode[Inst];
  InsertByte($FF);
  InsertByte(ModeByte+Tmp);
  Displace_Bytes(W1);
 End
  Else
 ErrNull;
 NextA;
End;

Procedure Retrn(_Far:Boolean);Begin
 If(Sym=Disp16)or(Sym = Disp8)Then Begin
  If(_Far)Then InsertByte($CA)
          Else InsertByte($C2);
  InsertWord(NValue);
  NextA;
 End
  Else
 If(_Far)Then InsertByte($CB)
         Else InsertByte($C3);
End;

Function OtherInst:Boolean;
Label 2,10,20,30;
Type
  Instsym=(Ret,Retf,Aam,Aad,Inn,Out,Mul,Imul,Divd,Idiv,Int);
Const
 Instname:Array[Ret..Int] of Array[1..5] of Char=(
  'RET  ', 'RETF ', 'AAM  ', 'AAD  ', 'IN   ', 'OUT  ', 'MUL  ',
  'IMUL ', 'DIV  ', 'IDIV ', 'INT  '
 );
Var
 Index:Instsym;
 Tmp:Byte;

 Procedure MulDiv(B:Byte);
 Var
  Wordbit:Integer;
 Begin
  InsertByte($F6);
  If Register(Reg2, W2)Then Begin
   InsertByte($C0+B+Reg2);
   Wordbit:=W2;
  End
   Else
  If MemReg(W2)Then Begin
   Chk_BwPtr;
   Wordbit := Ord(ByWord);
   InsertByte(ModeByte+B);
   Displace_Bytes(W2);
  End
   Else
  Error(Chi, 'Expression de registre ou de memoire');
  Modify_Byte(Tindex0, Wordbit);
 End;

 Function DXreg:Boolean;Begin
  DXreg:=False;
  If Sym=Identifier Then If ID2 = 'DX'Then Begin
   DXreg:=True;
   NextA;
  End;
 End;

 Function Accum(Var W:Integer):Boolean;
 Var
  Result_acc:Boolean;
 Begin
  Result_acc:=False;
  If(Sym=Identifier)Then Begin
   Result_acc:=(ID3 = 'AX ')or(ID3 = 'AL ');
   If Result_acc Then Begin
    If Str[2] = 'X'Then W:=1
                   Else W:=0;
    NextA;
   End;
  End;
  Accum:=Result_acc;
 End;

Begin
 OtherInst:=False;
 For Index:=Ret to Int do If Str = Instname[Index]Then Goto 2;
 Exit;
2:
 OtherInst:=True;
 NextA;
 Case Index of
  Ret:Retrn(False);
  Retf:Retrn(True);
  Out:Begin
   If DXreg Then InsertByte($EE) Else {out dx,ac}
   If Sym = Disp8 Then Begin          {out port,ac}
    InsertByte($E6);
    InsertByte(Lo(NValue));
    NextA;
   End
    Else
   Goto 10;
   If Sym = Comma Then NextA;
   If Accum(W1) Then Modify_Byte(Tindex0, W1) {al ou ax}
                Else Goto 20;
  End;
  Inn:Begin
   If Accum(W1) Then Begin
    If Sym=Comma Then NextA;
    If DXreg Then InsertByte($EC+W1) {in ac,dx}
     Else
    Begin
     If(Sym=Disp8)Then Begin         {in ac,port}
      InsertByte($E4+W1);
      InsertByte(Lo(NValue));
      NextA;
     End
      Else
10:  Error(Chi, 'DX ou expression de port');
    End
   End
    Else
20:Error(Chi, 'Expression AX ou AL');
  End;
  Aam:Begin
   Tmp:=$D4;
   Goto 30;
  End;
  Aad:Begin
   Tmp := $D5;
30:InsertByte(Tmp);
   InsertByte($A);
  End;
  Mul:MulDiv($20);
  Imul:MulDiv($28);
  Divd:MulDiv($30);
  Idiv:MulDiv($38);
  Int:Begin
   If Sym=Disp8 Then Begin
    If NValue = 3 Then InsertByte($CC)
     Else
    Begin
     InsertByte($CD);
     InsertByte(Lo(NValue));
    End;
    NextA;
   End
   Else ErrNull;
  End;
 End;
End;

Function GetQuoted(Var Ls:BigString):Boolean;
Var
 SaveChi,K:Integer;
 Term:Char;
 Gq:Boolean;
Begin
 SkipSpaces;
 SaveChi:=Chi;
 K:=1;
 Gq:=False;
 If(UCh = '''')or(UCh = '"')Then Begin
  Term:=UCh;
  GetCh;
  While(UCh <> Term)and(UCh <> Chr(CR))do If (UCh <> Chr(CR))and(K <= BigStringSize)Then Begin
   Ls[K]:=LCh;
   K:=K+1;
   GetCh;
  End;
  GetCh;
  Gq:=Not(UCh in ['+', '-', '*', '/']);
 End;
 Ls[0]:=Chr(K-1);
 If Not Gq Then Begin
  Chi:=SaveChi-1;
  GetCh;
 End;
 GetQuoted:=Gq;
End;

Procedure DataByte;
Var
 I:Integer;
 Lst:BigString;
Begin
 Repeat
  If GetQuoted(Lst)Then Begin
   For I:=1 to Ord(Lst[0]) do InsertByte(Lo(Ord(Lst[I])));
  End
   Else
  If ReadByte Then InsertByte(Byt)
   Else
  Begin
   ErrNull;
  End;
  While(UCh = ' ')or(UCh = Chr(Tab))or(UCh = ',')do GetCh;
 Until (UCh = Chr(CR)) or (UCh = ';') or Aerr;
 NextA;
End;

Procedure Chk_For_Label;
Var
 Dum1,Dum2:Integer;
Begin
 If Not Prefix Then Begin
  SkipSpaces;
  If(Lsid[0]>Chr(0))and(UCh = ':')Then Begin
   Sym:=Identifier;
   If Register(Dum1,Dum2)Then Error(Chi, 'Nom enregistr‚ utiliser comme ‚tiquette')
    Else
   Begin
    GetCh;
    Symname:=Lsid;
    Pl:=Firstlabel;
    While Pl <> Nil do With Pl^ do Begin
     If Symname = Name Then Error(Chi, 'Etiquette dupliqu‚');
     Pl:=Next;
    End;
    New(Pl);
    With Pl^ do Begin
     Next:=Firstlabel;
     Firstlabel:=Pl;
     ByteCnt:=ByteCount;
     Name:=Symname;
    End;
    Pf:=Firstfix;
    While Pf <> Nil do With Pf^ do Begin
     If Name = Symname Then Begin
      If Pf = Firstfix Then Firstfix:=Next
                       Else Prev^.Next:=Next;
      If Next <> Nil Then Next^.Prev := Prev;
      Dispose(Pf);
      Addr:=ByteCount-(Fix_pt+1);
      If Jmptype = Short Then Begin
       If Addr+$80 <= $FF Then Modify_Byte(Indx, Lo(Addr))
                          Else Error(Chi, 'Trop long');
      End
       Else
      Begin
       Addr := Addr-1;
       Modify_Byte(Indx, Lo(Addr));
       Modify_Byte(Indx2, Hi(Addr));
      End;
     End;
     Pf:=Next;
    End;
   End;
   GetString;
  End;
 End
  Else
 GetString;
End;

Procedure Interpret;Begin
 Tindex0:=Tindex;
 GetString;
 Chk_For_Label;
 While Prefix do GetString;
 If Lsid[0] > Chr(0)Then Begin
  If Not NoOperand Then
  If Not OneOperand Then
  If Not TwoOperands Then
  If Not ShortJmp Then
  If Not CallJmp Then
  If Not ShfRot Then
  If Not OtherInst Then
  If Not FaddType Then
  If Not Fnoperand Then
  If Not FiaddType Then
  If Not FldType Then
  If Not FmemOnly Then
  If Not FildType Then
  If Not FstiOnly Then
  If ID3='DB 'Then DataByte else
  If Lsid='NEW'Then Begin
   NewFnd:=True;
   NextA;
  End
   Else
  If Lsid='END'Then Begin
   TheEnd := True;
   NextA;
  End
   Else
  Error(Chi,'Instruction inconnu');
 End
  Else
 NextA;
 If Sym <> EOLsym then Error(Chi, 'Expression de fin de ligne');
End;

Function ChkIOerror(S:String):Integer;
Var
 IOerr:Integer;
Begin
 IOerr:=IOResult;
 If(IOerr=2)or(IOerr=3)Then WriteLn('Introuvable ', S) Else
 If IOerr<>0 then WriteLn('Erreur d''entr‚e/sortie ', IOerr);
 ChkIOerror:=IOerr;
End;

Procedure LabelReport;
Var
 Pftmp:Fixup_Info_Ptr;
 Pltmp:Label_Info_ptr;
Begin
 Pf:=Firstfix;
 While Pf <> Nil do With Pf^ do Begin
  WriteLn('Etiquette introuvable-- ', Name);
  Pftmp := Next;
  Dispose(Pf);
  Pf:=Pftmp;
 End;
 Pl:=Firstlabel;
 While Pl <> Nil do Begin
  Pltmp:=Pl^.Next;
  Dispose(Pl);
  Pl:=Pltmp;
 End;
End;

Var
 Err:Integer;
 SourceName,TargetName:String;

BEGIN
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='DK'Then Language:=_Danish Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SE'Then Language:=_Swedish Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='SQ')or
    (StrToUpper(Copy(TmpLanguage,1,3))='ALB')Then Language:=_Albanian;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _English:Begin
    WriteLn('ASM86 : This command allows you to compile 8086 assembler.');
    WriteLn;
    WriteLn('Syntax : ASM86 [source[.A86] [target[.H86]]] [/C] [/INLINE|/TP]');
    WriteLn;
    WriteLn('Parameter');
    WriteLn;
    WriteLn('    source       Name of the file containing the assembler source');
    WriteLn('    target       Name of the file containing the machine code in hexadecimal');
    WriteLn('    /B           Create a binary file (.BIN)');
    WriteLn('    /C           Commented output of assembly instructions');
    WriteLn('    /INLINE      Turbo Pascal INLINE instruction output');
    WriteLn('    /TP          Turbo Pascal INLINE instruction output');
    WriteLn('    --version    Output version information and exit');
   End;
   Else Begin
    WriteLn('ASM86 : Cette commande permet de compiler de l''assembleur 8086.');
    WriteLn;
    WriteLn('Syntaxe : ASM86 [source[.A86] [destination[.H86]]] [/C] [/INLINE|/TP]');
    WriteLn;
    WriteLn('ParamŠtres');
    WriteLn;
    WriteLn('    source       Nom du fichier contenant le source assembleur');
    WriteLn('    destination  Nom du fichier contenu le code machine en hexad‚cimal');
    WriteLn('    /B           Fabrique un fichier binaire (.BIN)');
    WriteLn('    /C           Sortie en commentaires des instructions assembleurs');
    WriteLn('    /INLINE      Sortie en instruction INLINE du Turbo Pascal');
    WriteLn('    /TP          Sortie en instruction INLINE du Turbo Pascal');
    WriteLn('    --version    Demande la version de la commande');
   End;
  End;
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('ASM86 1.0.1 - Compilateur assembleur 8086');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('crit par Sylvain Maltais');
 End
  Else
 Begin
  Option:=[];
  SourceName:='';
  TargetName:='';
  If ParamCount>0Then Begin
   For I:=1 to ParamCount do Begin
    If StrToUpper(ParamStr(I))='/B'Then Include(Option,BinaryFile)Else
    If StrToUpper(ParamStr(I))='/C'Then Include(Option,ShowInstrInComment)Else
    If(StrToUpper(ParamStr(I))='/INLINE')or(StrToUpper(ParamStr(I))='/TP')Then Include(Option,InlineForTurboPascal)Else
    If SourceName=''Then Begin
     SourceName:=ParamStr(1);
     If Path2Ext(SourceName)=''Then SourceName:=SourceName+'.A86';
     Assign(SourceFile,SourceName);
     {$I-}Reset(SourceFile);{$I+}
     If ChkIOerror(SourceName)<>0 Then Halt(1);
    End
     Else
    Begin
      TargetName:=ParamStr(I);
      If Path2Ext(TargetName)=''Then TargetName:=TargetName+'.H86';
    End;
   End;
   If SourceName=''Then Begin
    WriteLn('Nom de fichier source assembleur requis');
    Halt(2);
   End
    Else
   If TargetName=''Then Begin
    TargetName:=Path2DirName(SourceName)+'.H86';
    If Path2Ext(TargetName)=''Then TargetName:=TargetName+'.H86';
   End;
  End
   Else
  Begin
   Repeat
    Write('Nom du fichier source [.A86]: ');
    ReadLn(SourceName);
    If SourceName='' Then Halt;
    If Path2Ext(SourceName)=''Then SourceName:=SourceName+'.A86';
    Assign(SourceFile,SourceName);
    {$I-}Reset(SourceFile);{$I+}
    Err:=ChkIOerror(SourceName);
    If Err>1 then Halt(1);
   Until Err=0;
   Write('Code machine hexad‚cimal [',Path2DirName(SourceName),'.H86]: ');
   ReadLn(TargetName);
   If TargetName=''Then TargetName:=Path2DirName(SourceName)+'.H86';
   {DefaultExtension('H86',TargetName,_Name);}
   If Path2Ext(TargetName)=''Then TargetName:=TargetName+'.H86';
  End;
  Assign(TargetFile,TargetName);
  {$I-}Rewrite(TargetFile);{$I+}
  If ChkIOerror(TargetName)<>0 Then Halt(1);
  If(BinaryFile in Option)Then Begin
   Assign(Binary,Path2DirName(TargetName)+'.BIN');
   Rewrite(Binary);
  End;
  Wait_Already:=False;
  NewFnd:=True;
  While NewFnd and Not EOF(SourceFile)do Begin
   NewFnd:=False;
   Start_Col:=1;
   TheEnd:=False;
   Tindex:=0;
   ByteCount:=0;
   Firstlabel:=Nil;
   Firstfix:=Nil;
   If(InlineForTurboPascal in Option)Then InsertStr('INLINE('+^M^J);
   While Not EOF(SourceFile) and Not TheEnd and Not NewFnd do Begin
    Aerr:=False;
    NoAddrs:=False;
    ByWord:=UnkPtr;
    Column:=0;
    ReadLn(SourceFile,St);
    Chi:=1;
    GetCh;
    Sym:=Othersym;
    SkipSpaces;
    If UCh<>Chr(CR)Then Begin
     If Not(InlineForTurboPascal in Option)Then InsertChr(':');
     Interpret;
     InsertChr(' ');
     If Not NewFnd and Not TheEnd Then Begin
      While Column<CommentColumn do InsertChr(' ');
      If(ShowInstrInComment in Option)Then Begin
       If(InlineForTurboPascal in Option)Then InsertStr(' { ')
                                         Else InsertStr(' # ');
       I:=1;
       While(Column<124)and(I<=Length(St))do Begin
        InsertChr(St[I]);
        I:=I+1;
       End;
      End;
      If(InlineForTurboPascal in Option)Then InsertStr(' } ');
      InsertStr(^M^J);
     End;
    End;
    If EOF(SourceFile) or TheEnd or NewFnd Then Begin
     If(InlineForTurboPascal in Option)Then InsertStr(');');
     InsertStr(^M^J);
    End;
   End;
   LabelReport;
   For I:=0 to Tindex-1 do Write(TargetFile,TextArray[I]);
  End;
  If(BinaryFile in Option)Then Close(Binary);
  Close(TargetFile);
  Close(SourceFile);
 End;
END.
