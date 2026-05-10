{ @author: Sylvain Maltais
  @created: 2026
  @version: 1.0
  @website(https://www.gladir.com/nes-tools)
  @abstract(Target: Turbo Pascal, Free Pascal 3.2)
  @description: Emulateur NES
  @license: MIT
}

{$IFDEF FPC}
 {$MODE TP}
 {$H-}
 {$R-}
{$ENDIF}

Program NES;

Uses DOS,
     {$IFDEF FPC}
      PtcGraph, PtcCrt
     {$ELSE}
      Crt, Graph
     {$ENDIF};

{$IFDEF WINDOWS}
Function GetAsyncKeyState(vKey: LongInt): SmallInt;
         StdCall; External 'user32.dll' Name 'GetAsyncKeyState';
Procedure WinSleep(MilliSec: LongInt);
         StdCall; External 'kernel32.dll' Name 'Sleep';
Function GetTickCount: LongInt;
         StdCall; External 'kernel32.dll' Name 'GetTickCount';
{$ENDIF}

{ =================================================================== }
{ CONSTANTES                                                          }
{ =================================================================== }
Const
 { Palette NES 64 couleurs -> palette EGA 16 couleurs (mappage approche). }
 NesRomChunkSize=16384;
 NesPrgRomChunks=32;
 NesChrRomChunks=16;

 NesPalToEga: Array[0..63] Of Byte = (
    {00} 8,  1, 1, 5, 5,12, 4, 6,
    {08} 6,  2, 2,10, 3, 0, 0, 0,
    {10} 7,  9, 9,13,13,12,12, 6,
    {18} 6, 14, 2,10,11, 8, 0, 0,
    {20} 15, 9, 9,13,13,13,12,14,
    {28} 14,10,10,10,11,15, 7, 0,
    {30} 15,15, 9,15,13,13, 6,14,
    {38} 14,11,10,11,11,15, 7, 7);

Type
 TCPU6502MemBlock=Array[0..$7FFF] Of Byte;
 PCPU6502MemBlock=^TCPU6502MemBlock;
 TNesFrameBuffer=Array[0..239,0..255] Of Byte;
 PNesFrameBuffer=^TNesFrameBuffer;
 TRomChunk=Array[0..NesRomChunkSize-1] Of Byte;
 PRomChunk=^TRomChunk;

{ =================================================================== }
{ ETAT GLOBAL                                                          }
{ =================================================================== }
Var
 { Etat 6502 }
 CPU6502_MemLo  : PCPU6502MemBlock;
 CPU6502_MemHi  : PCPU6502MemBlock;
 CPU6502_A      : Byte;
 CPU6502_X      : Byte;
 CPU6502_Y      : Byte;
 CPU6502_P      : Byte;       { NV-BDIZC }
 CPU6502_S      : Byte;       { stack pointer }
 CPU6502_PC     : Word;
 CPU6502_Halted : Boolean;
 CPU6502_ExitCode: Integer;
 CPU6502_Cycles : LongInt;
 CPU6502_Variant: Integer;    { toujours 3 = NES }

 { Etat PPU NES }
 NesActive       : Boolean;
 NesChr          : Array[0..$1FFF] Of Byte;  { CHR (pattern tables 8K)  }
 NesNT           : Array[0..$7FF] Of Byte;   { 2 nametables phys (2x1K) }
 NesPal          : Array[0..$1F] Of Byte;    { palette PPU 32 octets    }
 NesOam          : Array[0..$FF] Of Byte;    { OAM sprite table 64x4    }
 NesFB           : PNesFrameBuffer; { framebuffer pal idx }
 NesFBPrev       : PNesFrameBuffer; { trame precedente   }
 NesFBFirst      : Boolean;
 NesPpuCtrl      : Byte;
 NesPpuMask      : Byte;
 NesPpuStatus    : Byte;
 NesOamAddr      : Byte;
 NesScrollX      : Byte;
 NesScrollY      : Byte;
 NesPpuLatch     : Boolean;
 NesPpuAddr      : Word;
 NesPpuBuf       : Byte;
 NesMirror       : Byte;
 NesPad1, NesPad2     : Byte;
 NesPad1Sh, NesPad2Sh : Byte;
 NesPadStrobe    : Byte;
 NesNmiPending   : Boolean;
 NesFrameDone    : Boolean;
 NesFrameNo      : LongInt;

 { Mappers }
 NesPrgRom       : Array[0..NesPrgRomChunks-1] Of PRomChunk; { 512K }
 NesChrRom       : Array[0..NesChrRomChunks-1] Of PRomChunk; { 256K }
 NesPrgBlocksTotal : Integer;
 NesChrBlocksTotal : Integer;
 NesMapper         : Integer;
 NesUseChrRam      : Boolean;
 { MMC1 }
 NesM1Shift     : Byte;
 NesM1ShiftCount: Byte;
 NesM1Ctrl      : Byte;
 NesM1Chr0      : Byte;
 NesM1Chr1      : Byte;
 NesM1Prg       : Byte;
 { MMC3 (mapper 4) }
 NesM3BankSelect: Byte;
 NesM3Banks     : Array[0..7] Of Byte;

 { Affichage BGI }
 ScrW, ScrH      : Integer;
 NesOX, NesOY    : Integer;     { coin haut-gauche du framebuffer 512x480 }
 NesScale        : Integer;     { facteur d echelle 1 ou 2 }

{ =================================================================== }
{ HELPERS                                                              }
{ =================================================================== }

Function HexNib(N: Byte): Char;
Begin
 If N < 10 Then HexNib := Chr(Ord('0') + N)
           Else HexNib := Chr(Ord('A') + N - 10);
End;

Function HexB(B: Byte): String;
Begin
 HexB := HexNib((B Shr 4) And $F) + HexNib(B And $F);
End;

Function HexW(W: Word): String;
Begin
 HexW := HexB((W Shr 8) And $FF) + HexB(W And $FF);
End;

Function IntToStr(N: LongInt): String;
Var S: String;
Begin
 Str(N, S); IntToStr := S;
End;

Procedure NesAllocHeap;
Var
 I:Integer;
Begin
 If NesFB=NIL Then New(NesFB);
 If NesFBPrev=NIL Then New(NesFBPrev);
 If(NesFB=NIL)or(NesFBPrev=NIL)Then Begin
  WriteLn('Memoire insuffisante pour le framebuffer NES.');
  Halt(1);
 End;
 For I:=0 to NesPrgRomChunks-1 do NesPrgRom[I]:=NIL;
 For I:=0 to NesChrRomChunks-1 do NesChrRom[I]:=NIL;
End;

Procedure NesFreeHeap;
Var
 I:Integer;
Begin
 If NesFB<>NIL Then Begin Dispose(NesFB); NesFB:=NIL; End;
 If NesFBPrev<>NIL Then Begin Dispose(NesFBPrev); NesFBPrev:=NIL; End;
 For I:=0 to NesPrgRomChunks-1 do If NesPrgRom[I]<>NIL Then Begin
  Dispose(NesPrgRom[I]); NesPrgRom[I]:=NIL;
 End;
 For I:=0 to NesChrRomChunks-1 do If NesChrRom[I]<>NIL Then Begin
  Dispose(NesChrRom[I]); NesChrRom[I]:=NIL;
 End;
End;

Procedure NesPrgRomEnsure(Chunk:Integer);
Begin
 If(Chunk<0)or(Chunk>=NesPrgRomChunks)Then Begin
  WriteLn('Index PRG ROM invalide.'); Halt(1);
 End;
 If NesPrgRom[Chunk]=NIL Then Begin
  New(NesPrgRom[Chunk]);
  If NesPrgRom[Chunk]=NIL Then Begin
   WriteLn('Memoire insuffisante pour PRG ROM.'); Halt(1);
  End;
 End;
End;

Procedure NesChrRomEnsure(Chunk:Integer);
Begin
 If(Chunk<0)or(Chunk>=NesChrRomChunks)Then Begin
  WriteLn('Index CHR ROM invalide.'); Halt(1);
 End;
 If NesChrRom[Chunk]=NIL Then Begin
  New(NesChrRom[Chunk]);
  If NesChrRom[Chunk]=NIL Then Begin
   WriteLn('Memoire insuffisante pour CHR ROM.'); Halt(1);
  End;
 End;
End;

Function NesPrgRomGet(Index:LongInt):Byte;
Var
 C,O:Integer;
Begin
 C:=Index div NesRomChunkSize;
 O:=Index mod NesRomChunkSize;
 NesPrgRomEnsure(C);
 NesPrgRomGet:=NesPrgRom[C]^[O];
End;

Function NesChrRomGet(Index:LongInt):Byte;
Var
 C,O:Integer;
Begin
 C:=Index div NesRomChunkSize;
 O:=Index mod NesRomChunkSize;
 NesChrRomEnsure(C);
 NesChrRomGet:=NesChrRom[C]^[O];
End;

Procedure NesPrgRomClear;
Var
 I:Integer;
Begin
 For I:=0 to NesPrgRomChunks-1 do Begin
  NesPrgRomEnsure(I);
  FillChar(NesPrgRom[I]^,SizeOf(TRomChunk),0);
 End;
End;

Procedure NesChrRomClear;
Var
 I:Integer;
Begin
 For I:=0 to NesChrRomChunks-1 do Begin
  NesChrRomEnsure(I);
  FillChar(NesChrRom[I]^,SizeOf(TRomChunk),0);
 End;
End;

Procedure NesPrgRomRead(Var F:File;Size:LongInt);
Var
 Pos,ChunkLen:LongInt;
 C,O:Integer;
 BR:Word;
Begin
 Pos:=0;
 While Pos<Size do Begin
  C:=Pos div NesRomChunkSize;
  O:=Pos mod NesRomChunkSize;
  NesPrgRomEnsure(C);
  ChunkLen:=NesRomChunkSize-O;
  If ChunkLen>Size-Pos Then ChunkLen:=Size-Pos;
  BlockRead(F,NesPrgRom[C]^[O],Word(ChunkLen),BR);
  If BR<>Word(ChunkLen)Then Exit;
  Inc(Pos,ChunkLen);
 End;
End;

Procedure NesChrRomRead(Var F:File;Size:LongInt);
Var
 Pos,ChunkLen:LongInt;
 C,O:Integer;
 BR:Word;
Begin
 Pos:=0;
 While Pos<Size do Begin
  C:=Pos div NesRomChunkSize;
  O:=Pos mod NesRomChunkSize;
  NesChrRomEnsure(C);
  ChunkLen:=NesRomChunkSize-O;
  If ChunkLen>Size-Pos Then ChunkLen:=Size-Pos;
  BlockRead(F,NesChrRom[C]^[O],Word(ChunkLen),BR);
  If BR<>Word(ChunkLen)Then Exit;
  Inc(Pos,ChunkLen);
 End;
End;
Procedure CPU6502_AllocMem;
Begin
 If CPU6502_MemLo=NIL Then New(CPU6502_MemLo);
 If CPU6502_MemHi=NIL Then New(CPU6502_MemHi);
 If(CPU6502_MemLo=NIL)or(CPU6502_MemHi=NIL)Then Begin
  WriteLn('Memoire insuffisante pour la RAM 6502.');
  Halt(1);
 End;
End;

Procedure CPU6502_FreeMem;
Begin
 If CPU6502_MemLo<>NIL Then Begin
  Dispose(CPU6502_MemLo);
  CPU6502_MemLo:=NIL;
 End;
 If CPU6502_MemHi<>NIL Then Begin
  Dispose(CPU6502_MemHi);
  CPU6502_MemHi:=NIL;
 End;
End;

Function CPU6502_MemGet(Addr: LongInt): Byte;
Var
 W:Word;
Begin
 W:=Word(Addr and $7FFF);
 If(Addr and $8000)=0 Then CPU6502_MemGet:=CPU6502_MemLo^[W]
                       Else CPU6502_MemGet:=CPU6502_MemHi^[W];
End;

Procedure CPU6502_MemSet(Addr: LongInt;V: Byte);
Var
 W:Word;
Begin
 W:=Word(Addr and $7FFF);
 If(Addr and $8000)=0 Then CPU6502_MemLo^[W]:=V
                       Else CPU6502_MemHi^[W]:=V;
End;

Procedure CPU6502_ClearMem;
Begin
 CPU6502_AllocMem;
 FillChar(CPU6502_MemLo^,SizeOf(TCPU6502MemBlock),0);
 FillChar(CPU6502_MemHi^,SizeOf(TCPU6502MemBlock),0);
End;
{ =================================================================== }
{ EMULATEUR 6502 (extrait de DEVENV.PAS, simplifie pour NES)           }
{ =================================================================== }

Function CPU6502_Read(Addr: Word): Byte;
Begin
  CPU6502_Read := CPU6502_MemGet(Addr);
End;

Procedure CPU6502_Write(Addr: Word; V: Byte);
Begin
  CPU6502_MemSet(Addr, V);
End;

Function CPU6502_Read16(Addr: Word): Word;
Begin
  CPU6502_Read16 := CPU6502_MemGet(Addr) Or
                    (Word(CPU6502_MemGet(Word(Addr + 1))) Shl 8);
End;

Function CPU6502_Read16Bug(Addr: Word): Word;
Var Hi: Word;
Begin
  Hi := (Addr And $FF00) Or ((Addr + 1) And $FF);
  CPU6502_Read16Bug := CPU6502_MemGet(Addr) Or
                       (Word(CPU6502_MemGet(Hi)) Shl 8);
End;

Procedure CPU6502_Push(V: Byte);
Begin
  CPU6502_MemSet($0100 Or CPU6502_S, V);
 {$R-}{$Q-}
  CPU6502_S := (CPU6502_S - 1) And $FF;
End;

Function CPU6502_Pop: Byte;
Begin
 {$R-}{$Q-}
  CPU6502_S := (CPU6502_S + 1) And $FF;
  CPU6502_Pop := CPU6502_MemGet($0100 Or CPU6502_S);
End;

Procedure CPU6502_Push16(V: Word);
Begin
  CPU6502_Push((V Shr 8) And $FF);
  CPU6502_Push(V And $FF);
End;

Function CPU6502_Pop16: Word;
Var Lo, Hi: Byte;
Begin
  Lo := CPU6502_Pop;
  Hi := CPU6502_Pop;
  CPU6502_Pop16 := Lo Or (Word(Hi) Shl 8);
End;

Procedure CPU6502_SetNZ(V: Byte);
Begin
  CPU6502_P := CPU6502_P And Not $82;
  If V = 0 Then CPU6502_P := CPU6502_P Or $02;
  If (V And $80) <> 0 Then CPU6502_P := CPU6502_P Or $80;
End;

Function CPU6502_GetC: Byte;
Begin
  If (CPU6502_P And $01) <> 0 Then CPU6502_GetC := 1 Else CPU6502_GetC := 0;
End;

Procedure CPU6502_SetC(B: Boolean);
Begin
  If B Then CPU6502_P := CPU6502_P Or $01
       Else CPU6502_P := CPU6502_P And Not $01;
End;

Procedure CPU6502_SetZ(B: Boolean);
Begin
  If B Then CPU6502_P := CPU6502_P Or $02
       Else CPU6502_P := CPU6502_P And Not $02;
End;

Procedure CPU6502_SetV(B: Boolean);
Begin
  If B Then CPU6502_P := CPU6502_P Or $40
       Else CPU6502_P := CPU6502_P And Not $40;
End;

Procedure CPU6502_SetN(B: Boolean);
Begin
  If B Then CPU6502_P := CPU6502_P Or $80
       Else CPU6502_P := CPU6502_P And Not $80;
End;

Function CPU6502_AmIMM: Word;
Begin
  CPU6502_AmIMM := CPU6502_PC; Inc(CPU6502_PC);
End;

Function CPU6502_AmZP: Word;
Begin
  CPU6502_AmZP := CPU6502_MemGet(CPU6502_PC); Inc(CPU6502_PC);
End;

Function CPU6502_AmZPX: Word;
Begin
  CPU6502_AmZPX := (CPU6502_MemGet(CPU6502_PC) + CPU6502_X) And $FF;
  Inc(CPU6502_PC);
End;

Function CPU6502_AmZPY: Word;
Begin
  CPU6502_AmZPY := (CPU6502_MemGet(CPU6502_PC) + CPU6502_Y) And $FF;
  Inc(CPU6502_PC);
End;

Function CPU6502_AmABS: Word;
Begin
  CPU6502_AmABS := CPU6502_Read16(CPU6502_PC);
  CPU6502_PC := CPU6502_PC + 2;
End;

Function CPU6502_AmABX: Word;
Begin
  CPU6502_AmABX := CPU6502_Read16(CPU6502_PC) + CPU6502_X;
  CPU6502_PC := CPU6502_PC + 2;
End;

Function CPU6502_AmABY: Word;
Begin
  CPU6502_AmABY := CPU6502_Read16(CPU6502_PC) + CPU6502_Y;
  CPU6502_PC := CPU6502_PC + 2;
End;

Function CPU6502_AmIZX: Word;
Var Z: Byte;
Begin
  Z := (CPU6502_MemGet(CPU6502_PC) + CPU6502_X) And $FF;
  Inc(CPU6502_PC);
  CPU6502_AmIZX := CPU6502_MemGet(Z) Or
                   (Word(CPU6502_MemGet((Z + 1) And $FF)) Shl 8);
End;

Function CPU6502_AmIZY: Word;
Var Z: Byte;
Begin
  Z := CPU6502_MemGet(CPU6502_PC);
  Inc(CPU6502_PC);
  CPU6502_AmIZY := (CPU6502_MemGet(Z) Or
                    (Word(CPU6502_MemGet((Z + 1) And $FF)) Shl 8))
                   + CPU6502_Y;
End;

Procedure CPU6502_Branch(Cond: Boolean);
Var Off: ShortInt;
Begin
  Off := ShortInt(CPU6502_MemGet(CPU6502_PC));
  Inc(CPU6502_PC);
  If Cond Then CPU6502_PC := CPU6502_PC + Off;
End;

Procedure CPU6502_DoADC(M: Byte);
Var R: Word; A: Byte;
Begin
  A := CPU6502_A;
  R := A + M + CPU6502_GetC;
  CPU6502_SetC(R > $FF);
  CPU6502_SetV(((A Xor M) And $80 = 0) And
               ((A Xor (R And $FF)) And $80 <> 0));
  CPU6502_A := R And $FF;
  CPU6502_SetNZ(CPU6502_A);
End;

Procedure CPU6502_DoSBC(M: Byte);
Begin
  CPU6502_DoADC(M Xor $FF);
End;

Procedure CPU6502_DoCMP(R, M: Byte);
Var D: Integer;
Begin
  D := Integer(R) - Integer(M);
  CPU6502_SetC(R >= M);
  CPU6502_SetNZ(Byte(D));
End;

Function CPU6502_DoASL(M: Byte): Byte;
Begin
  CPU6502_SetC((M And $80) <> 0);
  M := (M Shl 1) And $FF;
  CPU6502_SetNZ(M);
  CPU6502_DoASL := M;
End;

Function CPU6502_DoLSR(M: Byte): Byte;
Begin
  CPU6502_SetC((M And $01) <> 0);
  M := M Shr 1;
  CPU6502_SetNZ(M);
  CPU6502_DoLSR := M;
End;

Function CPU6502_DoROL(M: Byte): Byte;
Var Cin: Byte;
Begin
  Cin := CPU6502_GetC;
  CPU6502_SetC((M And $80) <> 0);
  M := ((M Shl 1) Or Cin) And $FF;
  CPU6502_SetNZ(M);
  CPU6502_DoROL := M;
End;

Function CPU6502_DoROR(M: Byte): Byte;
Var Cin: Byte;
Begin
  Cin := CPU6502_GetC;
  CPU6502_SetC((M And $01) <> 0);
  M := (M Shr 1) Or (Cin Shl 7);
  CPU6502_SetNZ(M);
  CPU6502_DoROR := M;
End;

{ Pas de trap OS sur NES. }
Function CPU6502_TryTrap: Boolean;
Begin
  CPU6502_TryTrap := False;
End;

{ =================================================================== }
{ PPU NES                                                              }
{ =================================================================== }

Function NesPpu_NtAddr(A: Word): Word;
Var Page: Word;
Begin
  A := A And $0FFF;
  Page := A Shr 10;
  Case NesMirror Of
    0: NesPpu_NtAddr := ((Page Shr 1) And 1) Shl 10 Or (A And $3FF);
    1: NesPpu_NtAddr := (Page And 1) Shl 10 Or (A And $3FF);
    2: NesPpu_NtAddr := (Page And 1) Shl 10 Or (A And $3FF);
  Else
    NesPpu_NtAddr := A And $3FF;
  End;
End;

Function NesPpu_VRamRead(A: Word): Byte;
Var Idx: Byte;
Begin
  A := A And $3FFF;
  If A < $2000 Then
    NesPpu_VRamRead := NesChr[A]
  Else If A < $3F00 Then
    NesPpu_VRamRead := NesNT[NesPpu_NtAddr(A)]
  Else Begin
    Idx := A And $1F;
    If (Idx And $13) = $10 Then Idx := Idx And $0F;
    NesPpu_VRamRead := NesPal[Idx];
  End;
End;

Procedure NesPpu_VRamWrite(A: Word; V: Byte);
Var Idx: Byte;
Begin
  A := A And $3FFF;
  If A < $2000 Then
    NesChr[A] := V
  Else If A < $3F00 Then
    NesNT[NesPpu_NtAddr(A)] := V
  Else Begin
    Idx := A And $1F;
    If (Idx And $13) = $10 Then Idx := Idx And $0F;
    NesPal[Idx] := V And $3F;
  End;
End;

Procedure NesPpu_Reset;
Var I: Integer;
Begin
  NesPpuCtrl   := 0;
  NesPpuMask   := 0;
  NesPpuStatus := 0;
  NesOamAddr   := 0;
  NesScrollX   := 0;
  NesScrollY   := 0;
  NesPpuLatch  := False;
  NesPpuAddr   := 0;
  NesPpuBuf    := 0;
  NesNmiPending := False;
  NesFrameDone := False;
  NesFrameNo   := 0;
  NesPad1 := 0; NesPad2 := 0;
  NesPad1Sh := 0; NesPad2Sh := 0;
  NesPadStrobe := 0;
  For I := 0 To $7FF Do NesNT[I] := 0;
  For I := 0 To $1F  Do NesPal[I] := 0;
  For I := 0 To $FF  Do NesOam[I] := 0;
End;

Procedure NesPpu_RegWrite(Reg: Byte; V: Byte);
Begin
  Case Reg Of
    $00: NesPpuCtrl := V;
    $01: NesPpuMask := V;
    $03: NesOamAddr := V;
    $04: Begin
           NesOam[NesOamAddr] := V;
           NesOamAddr := (NesOamAddr + 1) And $FF;
         End;
    $05:
      Begin
        If Not NesPpuLatch Then NesScrollX := V
                           Else NesScrollY := V;
        NesPpuLatch := Not NesPpuLatch;
      End;
    $06:
      Begin
        If Not NesPpuLatch Then
          NesPpuAddr := (NesPpuAddr And $00FF) Or
                        ((Word(V) And $3F) Shl 8)
        Else
          NesPpuAddr := (NesPpuAddr And $FF00) Or V;
        NesPpuLatch := Not NesPpuLatch;
      End;
    $07:
      Begin
        NesPpu_VRamWrite(NesPpuAddr, V);
        If (NesPpuCtrl And $04) <> 0 Then
          NesPpuAddr := (NesPpuAddr + 32) And $3FFF
        Else
          NesPpuAddr := (NesPpuAddr + 1) And $3FFF;
      End;
  End;
End;

Function NesPpu_RegRead(Reg: Byte): Byte;
Var V: Byte;
Begin
  NesPpu_RegRead := 0;
  Case Reg Of
    $02:
      Begin
        NesPpu_RegRead := NesPpuStatus;
        NesPpuStatus := NesPpuStatus And $7F;
        NesPpuLatch := False;
      End;
    $04: NesPpu_RegRead := NesOam[NesOamAddr];
    $07:
      Begin
        If NesPpuAddr >= $3F00 Then Begin
          NesPpu_RegRead := NesPpu_VRamRead(NesPpuAddr);
          NesPpuBuf := NesPpu_VRamRead(NesPpuAddr - $1000);
        End Else Begin
          V := NesPpuBuf;
          NesPpuBuf := NesPpu_VRamRead(NesPpuAddr);
          NesPpu_RegRead := V;
        End;
        If (NesPpuCtrl And $04) <> 0 Then
          NesPpuAddr := (NesPpuAddr + 32) And $3FFF
        Else
          NesPpuAddr := (NesPpuAddr + 1) And $3FFF;
      End;
  End;
End;

Procedure NesPpu_DmaOam(Page: Byte);
Var I: Integer; Base: Word;
Begin
  Base := Word(Page) Shl 8;
  For I := 0 To $FF Do
    NesOam[(NesOamAddr + I) And $FF] := CPU6502_MemGet(Base + I);
End;

{ Sondage clavier -> manette 1.                                       }
{ Bits : 0=A 1=B 2=Sel 3=Start 4=Up 5=Down 6=Left 7=Right             }
Procedure NesPollInput;
Var V: Byte;
Begin
  V := 0;
  {$IFDEF WINDOWS}
  If GetAsyncKeyState($5A) < 0 Then V := V Or $01; { Z = A          }
  If GetAsyncKeyState($58) < 0 Then V := V Or $02; { X = B          }
  If GetAsyncKeyState($41) < 0 Then V := V Or $01; { A = A (alt)    }
  If GetAsyncKeyState($53) < 0 Then V := V Or $02; { S = B (alt)    }
  If GetAsyncKeyState($A1) < 0 Then V := V Or $04; { RShift = Select}
  If GetAsyncKeyState($09) < 0 Then V := V Or $04; { Tab    = Select}
  If GetAsyncKeyState($0D) < 0 Then V := V Or $08; { Enter  = Start }
  If GetAsyncKeyState($20) < 0 Then V := V Or $08; { Espace = Start }
  If GetAsyncKeyState($26) < 0 Then V := V Or $10; { Up             }
  If GetAsyncKeyState($28) < 0 Then V := V Or $20; { Down           }
  If GetAsyncKeyState($25) < 0 Then V := V Or $40; { Left           }
  If GetAsyncKeyState($27) < 0 Then V := V Or $80; { Right          }
  {$ENDIF}
  NesPad1 := V;
End;

Procedure NesPad_Write(V: Byte);
Begin
  NesPadStrobe := V And 1;
  If NesPadStrobe = 1 Then Begin
    NesPad1Sh := NesPad1;
    NesPad2Sh := NesPad2;
  End;
End;

Function NesPad_Read(Port: Byte): Byte;
Var Bit: Byte;
Begin
  If NesPadStrobe = 1 Then Begin
    NesPad1Sh := NesPad1;
    NesPad2Sh := NesPad2;
  End;
  If Port = 0 Then Begin
    Bit := NesPad1Sh And 1;
    NesPad1Sh := (NesPad1Sh Shr 1) Or $80;
  End Else Begin
    Bit := NesPad2Sh And 1;
    NesPad2Sh := (NesPad2Sh Shr 1) Or $80;
  End;
  NesPad_Read := Bit Or $40;
End;

Procedure NesPpu_RenderFrame;
Var
  Sx, Sy, Tx, Ty, Px, Py, FineX, FineY: Integer;
  NtBase, AtBase, BgPatBase, SpPatBase: Word;
  AtByte: Word;
  TileNo, AtBits, PalIdx, ColorIdx, P0, P1: Byte;
  Bit, ScrX, ScrY, NtIdx: Integer;
  AtX, AtY, Quad: Integer;
  S, SpriteY, SpriteTile, SpriteAttr, SpriteX: Integer;
  SpRow, SpCol, FlipH, FlipV, Behind, SpY: Integer;
  SpPat, BgPat: Word;
  ShowBg, ShowSp: Boolean;
  PixBg, PixSp: Byte;
  SpHeight: Integer;
Begin
  ShowBg := (NesPpuMask And $08) <> 0;
  ShowSp := (NesPpuMask And $10) <> 0;
  ColorIdx := NesPal[0] And $3F;
  For Py := 0 To 239 Do
    For Px := 0 To 255 Do NesFB^[Py, Px] := ColorIdx;
  If Not (ShowBg Or ShowSp) Then Exit;
  { --- Background --- }
  If ShowBg Then Begin
    BgPatBase := 0;
    If (NesPpuCtrl And $10) <> 0 Then BgPatBase := $1000;
    NtIdx := NesPpuCtrl And $03;
    For Py := 0 To 239 Do Begin
      Sy := Py + NesScrollY;
      Ty := Sy Shr 3;     FineY := Sy And 7;
      For Px := 0 To 255 Do Begin
        Sx := Px + NesScrollX;
        Tx := Sx Shr 3;   FineX := Sx And 7;
        ScrY := Ty;       ScrX := Tx;
        NtIdx := NesPpuCtrl And $03;
        If ScrX >= 32 Then Begin ScrX := ScrX - 32; NtIdx := NtIdx Xor 1; End;
        If ScrY >= 30 Then Begin ScrY := ScrY - 30; NtIdx := NtIdx Xor 2; End;
        NtBase := $2000 + (NtIdx * $400);
        AtBase := NtBase + $3C0;
        TileNo := NesPpu_VRamRead(NtBase + ScrY * 32 + ScrX);
        BgPat := BgPatBase + (Word(TileNo) Shl 4) + Word(FineY);
        P0 := NesPpu_VRamRead(BgPat);
        P1 := NesPpu_VRamRead(BgPat + 8);
        Bit := 7 - FineX;
        PixBg := ((P0 Shr Bit) And 1) Or (((P1 Shr Bit) And 1) Shl 1);
        If PixBg = 0 Then Begin
          NesFB^[Py, Px] := NesPal[0] And $3F;
        End Else Begin
          AtX := ScrX Shr 2; AtY := ScrY Shr 2;
          AtByte := NesPpu_VRamRead(AtBase + AtY * 8 + AtX);
          Quad := ((ScrY And 2) Shl 1) Or (ScrX And 2);
          AtBits := (AtByte Shr Quad) And 3;
          PalIdx := (AtBits Shl 2) Or PixBg;
          NesFB^[Py, Px] := NesPal[PalIdx And $1F] And $3F;
        End;
      End;
    End;
  End;
  { --- Sprites --- }
  If ShowSp Then Begin
    SpPatBase := 0;
    If (NesPpuCtrl And $08) <> 0 Then SpPatBase := $1000;
    SpHeight := 8;
    If (NesPpuCtrl And $20) <> 0 Then SpHeight := 16;
    For S := 63 Downto 0 Do Begin
      SpriteY    := NesOam[S * 4    ];
      SpriteTile := NesOam[S * 4 + 1];
      SpriteAttr := NesOam[S * 4 + 2];
      SpriteX    := NesOam[S * 4 + 3];
      SpY := SpriteY + 1;
      If SpY >= 240 Then Continue;
      FlipH := SpriteAttr And $40;
      FlipV := SpriteAttr And $80;
      Behind := SpriteAttr And $20;
      For SpRow := 0 To SpHeight - 1 Do Begin
        Py := SpY + SpRow;
        If (Py < 0) Or (Py >= 240) Then Continue;
        FineY := SpRow;
        If FlipV <> 0 Then FineY := SpHeight - 1 - SpRow;
        If SpHeight = 8 Then
          SpPat := SpPatBase + (Word(SpriteTile) Shl 4) + Word(FineY)
        Else Begin
          If (SpriteTile And 1) <> 0 Then SpPat := $1000
                                     Else SpPat := 0;
          SpPat := SpPat + (Word(SpriteTile And $FE) Shl 4);
          If FineY >= 8 Then SpPat := SpPat + 16 + Word(FineY - 8)
                        Else SpPat := SpPat + Word(FineY);
        End;
        P0 := NesPpu_VRamRead(SpPat);
        P1 := NesPpu_VRamRead(SpPat + 8);
        For SpCol := 0 To 7 Do Begin
          Px := SpriteX + SpCol;
          If (Px < 0) Or (Px >= 256) Then Continue;
          If FlipH <> 0 Then Bit := SpCol Else Bit := 7 - SpCol;
          PixSp := ((P0 Shr Bit) And 1) Or
                   (((P1 Shr Bit) And 1) Shl 1);
          If PixSp = 0 Then Continue;
          If (S = 0) And ShowBg And ((NesPpuStatus And $40) = 0) Then Begin
            If NesFB^[Py, Px] <> (NesPal[0] And $3F) Then
              NesPpuStatus := NesPpuStatus Or $40;
          End;
          If (Behind <> 0) And ShowBg And
             (NesFB^[Py, Px] <> (NesPal[0] And $3F)) Then Continue;
          PalIdx := $10 Or ((SpriteAttr And 3) Shl 2) Or PixSp;
          NesFB^[Py, Px] := NesPal[PalIdx And $1F] And $3F;
        End;
      End;
    End;
  End;
  NesFrameDone := True;
End;

Procedure CPU6502_NMI;
{$R-}{$Q-}
Begin
  CPU6502_Push((CPU6502_PC Shr 8) And $FF);
  CPU6502_Push(CPU6502_PC And $FF);
  CPU6502_Push((CPU6502_P And $EF) Or $20);
  CPU6502_P := CPU6502_P Or $04;
  CPU6502_PC := CPU6502_MemGet($FFFA) Or
                (Word(CPU6502_MemGet($FFFB)) Shl 8);
End;


{ =================================================================== }
{ MAPPERS NES                                                          }
{ =================================================================== }

Procedure Nes_PrgMap16(SlotAddr: Word; Bank: Integer);
Var I: Integer; BaseRom: LongInt;
Begin
  If NesPrgBlocksTotal <= 0 Then Exit;
  Bank := Bank Mod NesPrgBlocksTotal;
  If Bank < 0 Then Bank := Bank + NesPrgBlocksTotal;
  BaseRom := LongInt(Bank) * 16384;
  For I := 0 To 16383 Do
    CPU6502_MemSet(SlotAddr + I, NesPrgRomGet(BaseRom + I));
End;

Procedure Nes_PrgMap8(SlotAddr: Word; Bank: Integer);
Var I: Integer; BaseRom: LongInt; BanksTotal: Integer;
Begin
  BanksTotal := NesPrgBlocksTotal * 2;
  If BanksTotal <= 0 Then Exit;
  Bank := Bank Mod BanksTotal;
  If Bank < 0 Then Bank := Bank + BanksTotal;
  BaseRom := LongInt(Bank) * 8192;
  For I := 0 To 8191 Do
    CPU6502_MemSet(SlotAddr + I, NesPrgRomGet(BaseRom + I));
End;

Procedure Nes_ChrMap4(SlotAddr: Word; Bank: Integer);
Var I: Integer; BaseRom: LongInt; BanksTotal: Integer;
Begin
  If NesUseChrRam Then Exit;
  BanksTotal := NesChrBlocksTotal * 2;
  If BanksTotal <= 0 Then Exit;
  Bank := Bank Mod BanksTotal;
  If Bank < 0 Then Bank := Bank + BanksTotal;
  BaseRom := LongInt(Bank) * 4096;
  For I := 0 To 4095 Do
    NesChr[SlotAddr + I] := NesChrRomGet(BaseRom + I);
End;

Procedure Nes_ChrMap1k(SlotAddr: Word; Bank: Integer);
Var I: Integer; BaseRom: LongInt; BanksTotal: Integer;
Begin
  If NesUseChrRam Then Exit;
  BanksTotal := NesChrBlocksTotal * 8;
  If BanksTotal <= 0 Then Exit;
  Bank := Bank Mod BanksTotal;
  If Bank < 0 Then Bank := Bank + BanksTotal;
  BaseRom := LongInt(Bank) * 1024;
  For I := 0 To 1023 Do
    NesChr[SlotAddr + I] := NesChrRomGet(BaseRom + I);
End;

Procedure Nes_M1ApplyBanks;
Var Mode: Byte; PrgLast: Integer;
Begin
  Case NesM1Ctrl And 3 Of
    0, 1: NesMirror := 3;
    2: NesMirror := 1;
    3: NesMirror := 0;
  End;
  If (NesM1Ctrl And $10) <> 0 Then Begin
    Nes_ChrMap4($0000, NesM1Chr0 And $1F);
    Nes_ChrMap4($1000, NesM1Chr1 And $1F);
  End Else Begin
    Nes_ChrMap4($0000, NesM1Chr0 And $1E);
    Nes_ChrMap4($1000, (NesM1Chr0 And $1E) Or 1);
  End;
  Mode := (NesM1Ctrl Shr 2) And 3;
  PrgLast := NesPrgBlocksTotal - 1;
  Case Mode Of
    0, 1: Begin
      Nes_PrgMap16($8000, NesM1Prg And $0E);
      Nes_PrgMap16($C000, (NesM1Prg And $0E) Or 1);
    End;
    2: Begin
      Nes_PrgMap16($8000, 0);
      Nes_PrgMap16($C000, NesM1Prg And $0F);
    End;
    3: Begin
      Nes_PrgMap16($8000, NesM1Prg And $0F);
      Nes_PrgMap16($C000, PrgLast);
    End;
  End;
End;

Procedure Nes_M1Write(EA: Word; V: Byte);
Var Reg: Byte;
Begin
  If (V And $80) <> 0 Then Begin
    NesM1Shift := 0;
    NesM1ShiftCount := 0;
    NesM1Ctrl := NesM1Ctrl Or $0C;
    Nes_M1ApplyBanks;
    Exit;
  End;
  NesM1Shift := (NesM1Shift Shr 1) Or ((V And 1) Shl 4);
  Inc(NesM1ShiftCount);
  If NesM1ShiftCount >= 5 Then Begin
    Reg := (EA Shr 13) And 3;
    Case Reg Of
      0: NesM1Ctrl := NesM1Shift And $1F;
      1: NesM1Chr0 := NesM1Shift And $1F;
      2: NesM1Chr1 := NesM1Shift And $1F;
      3: NesM1Prg  := NesM1Shift And $1F;
    End;
    NesM1Shift := 0;
    NesM1ShiftCount := 0;
    Nes_M1ApplyBanks;
  End;
End;

Procedure Nes_M2Write(EA: Word; V: Byte);
Begin
  Nes_PrgMap16($8000, V And $0F);
End;

Procedure Nes_M3ApplyBanks;
Var ChrInv, PrgMode: Byte; LastBank: Integer;
Begin
  ChrInv  := NesM3BankSelect And $80;
  PrgMode := NesM3BankSelect And $40;
  LastBank := NesPrgBlocksTotal * 2 - 1;
  If PrgMode = 0 Then Begin
    Nes_PrgMap8($8000, NesM3Banks[6]);
    Nes_PrgMap8($A000, NesM3Banks[7]);
    Nes_PrgMap8($C000, LastBank - 1);
    Nes_PrgMap8($E000, LastBank);
  End Else Begin
    Nes_PrgMap8($8000, LastBank - 1);
    Nes_PrgMap8($A000, NesM3Banks[7]);
    Nes_PrgMap8($C000, NesM3Banks[6]);
    Nes_PrgMap8($E000, LastBank);
  End;
  If ChrInv = 0 Then Begin
    Nes_ChrMap1k($0000, NesM3Banks[0] And $FE);
    Nes_ChrMap1k($0400, NesM3Banks[0] Or 1);
    Nes_ChrMap1k($0800, NesM3Banks[1] And $FE);
    Nes_ChrMap1k($0C00, NesM3Banks[1] Or 1);
    Nes_ChrMap1k($1000, NesM3Banks[2]);
    Nes_ChrMap1k($1400, NesM3Banks[3]);
    Nes_ChrMap1k($1800, NesM3Banks[4]);
    Nes_ChrMap1k($1C00, NesM3Banks[5]);
  End Else Begin
    Nes_ChrMap1k($0000, NesM3Banks[2]);
    Nes_ChrMap1k($0400, NesM3Banks[3]);
    Nes_ChrMap1k($0800, NesM3Banks[4]);
    Nes_ChrMap1k($0C00, NesM3Banks[5]);
    Nes_ChrMap1k($1000, NesM3Banks[0] And $FE);
    Nes_ChrMap1k($1400, NesM3Banks[0] Or 1);
    Nes_ChrMap1k($1800, NesM3Banks[1] And $FE);
    Nes_ChrMap1k($1C00, NesM3Banks[1] Or 1);
  End;
End;

Procedure Nes_M3Write(EA: Word; V: Byte);
Var Even: Boolean; Region: Byte;
Begin
  Even := (EA And 1) = 0;
  Region := (EA Shr 13) And 3;
  Case Region Of
    0: Begin
         If Even Then NesM3BankSelect := V
         Else Begin
           NesM3Banks[NesM3BankSelect And 7] := V;
         End;
         Nes_M3ApplyBanks;
       End;
    1: If Even Then Begin
         If (V And 1) <> 0 Then NesMirror := 0
                           Else NesMirror := 1;
       End;
    2, 3: ;
  End;
End;

Procedure Nes_MapperWrite(EA: Word; V: Byte);
Begin
  Case NesMapper Of
    0: ;
    1: Nes_M1Write(EA, V);
    2: Nes_M2Write(EA, V);
    4: Nes_M3Write(EA, V);
  End;
End;

Procedure Nes_MapperInit;
Var I: Integer;
Begin
  Case NesMapper Of
    0: ;
    1: Begin
         NesM1Shift := 0;
         NesM1ShiftCount := 0;
         NesM1Ctrl := $0C;
         NesM1Chr0 := 0;
         NesM1Chr1 := 0;
         NesM1Prg  := 0;
         Nes_M1ApplyBanks;
       End;
    2: Begin
         Nes_PrgMap16($8000, 0);
         Nes_PrgMap16($C000, NesPrgBlocksTotal - 1);
       End;
    4: Begin
         For I := 0 To 7 Do NesM3Banks[I] := 0;
         NesM3BankSelect := 0;
         Nes_M3ApplyBanks;
       End;
  End;
End;

Function NesBus_Read(EA: Word; Var ResultByte: Byte): Boolean;
Begin
  NesBus_Read := False;
  If CPU6502_Variant <> 3 Then Exit;
  If (EA >= $2000) And (EA < $4000) Then Begin
    ResultByte := NesPpu_RegRead(Byte(EA And $07));
    NesBus_Read := True;
  End Else If EA = $4014 Then Begin
    ResultByte := 0; NesBus_Read := True;
  End Else If EA = $4015 Then Begin
    ResultByte := 0; NesBus_Read := True;
  End Else If EA = $4016 Then Begin
    ResultByte := NesPad_Read(0); NesBus_Read := True;
  End Else If EA = $4017 Then Begin
    ResultByte := NesPad_Read(1); NesBus_Read := True;
  End Else If (EA >= $4000) And (EA <= $4013) Then Begin
    ResultByte := 0; NesBus_Read := True;
  End;
End;

Function NesBus_Write(EA: Word; V: Byte): Boolean;
Begin
  NesBus_Write := False;
  If CPU6502_Variant <> 3 Then Exit;
  If EA >= $8000 Then Begin
    Nes_MapperWrite(EA, V);
    NesBus_Write := True;
    Exit;
  End;
  If (EA >= $2000) And (EA < $4000) Then Begin
    NesPpu_RegWrite(Byte(EA And $07), V);
    NesBus_Write := True;
  End Else If EA = $4014 Then Begin
    NesPpu_DmaOam(V);
    NesBus_Write := True;
  End Else If EA = $4016 Then Begin
    NesPad_Write(V);
    NesBus_Write := True;
  End Else If (EA >= $4000) And (EA <= $4017) Then Begin
    NesBus_Write := True;
  End;
End;

Function NesMemRead(EA: Word): Byte;
Var Tmp: Byte;
Begin
  If (CPU6502_Variant = 3) And
     (((EA >= $2000) And (EA <= $4017)) Or (EA >= $8000)) Then Begin
    If NesBus_Read(EA, Tmp) Then Begin
      NesMemRead := Tmp;
      Exit;
    End;
  End;
  NesMemRead := CPU6502_MemGet(EA);
End;

Procedure NesMemWrite(EA: Word; V: Byte);
Begin
  If (CPU6502_Variant = 3) And
     (((EA >= $2000) And (EA <= $4017)) Or (EA >= $8000)) Then Begin
    If NesBus_Write(EA, V) Then Exit;
  End;
  CPU6502_MemSet(EA, V);
End;

{ =================================================================== }
{ CPU6502_Step                                                         }
{ =================================================================== }

{$R-}{$Q-}
Procedure CPU6502_Step;
Var
  Op, M: Byte;
  EA: Word;
  T: Word;
  TmpW: Word;
Begin
  If (CPU6502_Variant = 3) And NesNmiPending Then Begin
    NesNmiPending := False;
    CPU6502_NMI;
  End;
  If CPU6502_TryTrap Then Exit;
  Op := CPU6502_MemGet(CPU6502_PC);
  Inc(CPU6502_PC);
  Case Op Of
    $A9: Begin EA := CPU6502_AmIMM; CPU6502_A := CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $A5: Begin EA := CPU6502_AmZP;  CPU6502_A := CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $B5: Begin EA := CPU6502_AmZPX; CPU6502_A := CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $AD: Begin EA := CPU6502_AmABS; CPU6502_A := NesMemRead(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $BD: Begin EA := CPU6502_AmABX; CPU6502_A := NesMemRead(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $B9: Begin EA := CPU6502_AmABY; CPU6502_A := NesMemRead(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $A1: Begin EA := CPU6502_AmIZX; CPU6502_A := NesMemRead(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $B1: Begin EA := CPU6502_AmIZY; CPU6502_A := NesMemRead(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $A2: Begin EA := CPU6502_AmIMM; CPU6502_X := CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_X); End;
    $A6: Begin EA := CPU6502_AmZP;  CPU6502_X := CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_X); End;
    $B6: Begin EA := CPU6502_AmZPY; CPU6502_X := CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_X); End;
    $AE: Begin EA := CPU6502_AmABS; CPU6502_X := NesMemRead(EA);
               CPU6502_SetNZ(CPU6502_X); End;
    $BE: Begin EA := CPU6502_AmABY; CPU6502_X := NesMemRead(EA);
               CPU6502_SetNZ(CPU6502_X); End;
    $A0: Begin EA := CPU6502_AmIMM; CPU6502_Y := CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_Y); End;
    $A4: Begin EA := CPU6502_AmZP;  CPU6502_Y := CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_Y); End;
    $B4: Begin EA := CPU6502_AmZPX; CPU6502_Y := CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_Y); End;
    $AC: Begin EA := CPU6502_AmABS; CPU6502_Y := NesMemRead(EA);
               CPU6502_SetNZ(CPU6502_Y); End;
    $BC: Begin EA := CPU6502_AmABX; CPU6502_Y := NesMemRead(EA);
               CPU6502_SetNZ(CPU6502_Y); End;
    $85: Begin EA := CPU6502_AmZP;  CPU6502_MemSet(EA, CPU6502_A); End;
    $95: Begin EA := CPU6502_AmZPX; CPU6502_MemSet(EA, CPU6502_A); End;
    $8D: Begin EA := CPU6502_AmABS;
               If Not NesBus_Write(EA, CPU6502_A) Then
                 CPU6502_MemSet(EA, CPU6502_A); End;
    $9D: Begin EA := CPU6502_AmABX;
               If Not NesBus_Write(EA, CPU6502_A) Then
                 CPU6502_MemSet(EA, CPU6502_A); End;
    $99: Begin EA := CPU6502_AmABY;
               If Not NesBus_Write(EA, CPU6502_A) Then
                 CPU6502_MemSet(EA, CPU6502_A); End;
    $81: Begin EA := CPU6502_AmIZX; NesMemWrite(EA, CPU6502_A); End;
    $91: Begin EA := CPU6502_AmIZY; NesMemWrite(EA, CPU6502_A); End;
    $86: Begin EA := CPU6502_AmZP;  CPU6502_MemSet(EA, CPU6502_X); End;
    $96: Begin EA := CPU6502_AmZPY; CPU6502_MemSet(EA, CPU6502_X); End;
    $8E: Begin EA := CPU6502_AmABS;
               If Not NesBus_Write(EA, CPU6502_X) Then
                 CPU6502_MemSet(EA, CPU6502_X); End;
    $84: Begin EA := CPU6502_AmZP;  CPU6502_MemSet(EA, CPU6502_Y); End;
    $94: Begin EA := CPU6502_AmZPX; CPU6502_MemSet(EA, CPU6502_Y); End;
    $8C: Begin EA := CPU6502_AmABS;
               If Not NesBus_Write(EA, CPU6502_Y) Then
                 CPU6502_MemSet(EA, CPU6502_Y); End;
    $AA: Begin CPU6502_X := CPU6502_A; CPU6502_SetNZ(CPU6502_X); End;
    $A8: Begin CPU6502_Y := CPU6502_A; CPU6502_SetNZ(CPU6502_Y); End;
    $8A: Begin CPU6502_A := CPU6502_X; CPU6502_SetNZ(CPU6502_A); End;
    $98: Begin CPU6502_A := CPU6502_Y; CPU6502_SetNZ(CPU6502_A); End;
    $9A: CPU6502_S := CPU6502_X;
    $BA: Begin CPU6502_X := CPU6502_S; CPU6502_SetNZ(CPU6502_X); End;
    $48: CPU6502_Push(CPU6502_A);
    $68: Begin CPU6502_A := CPU6502_Pop; CPU6502_SetNZ(CPU6502_A); End;
    $08: CPU6502_Push(CPU6502_P Or $30);
    $28: CPU6502_P := (CPU6502_Pop And $CF) Or $20;
    $18: CPU6502_SetC(False);
    $38: CPU6502_SetC(True);
    $58: CPU6502_P := CPU6502_P And Not $04;
    $78: CPU6502_P := CPU6502_P Or $04;
    $B8: CPU6502_SetV(False);
    $D8: CPU6502_P := CPU6502_P And Not $08;
    $F8: CPU6502_P := CPU6502_P Or $08;
    $E6: Begin EA := CPU6502_AmZP;  M := (CPU6502_MemGet(EA) + 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_SetNZ(M); End;
    $F6: Begin EA := CPU6502_AmZPX; M := (CPU6502_MemGet(EA) + 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_SetNZ(M); End;
    $EE: Begin EA := CPU6502_AmABS; M := (CPU6502_MemGet(EA) + 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_SetNZ(M); End;
    $FE: Begin EA := CPU6502_AmABX; M := (CPU6502_MemGet(EA) + 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_SetNZ(M); End;
    $C6: Begin EA := CPU6502_AmZP;  M := (CPU6502_MemGet(EA) - 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_SetNZ(M); End;
    $D6: Begin EA := CPU6502_AmZPX; M := (CPU6502_MemGet(EA) - 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_SetNZ(M); End;
    $CE: Begin EA := CPU6502_AmABS; M := (CPU6502_MemGet(EA) - 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_SetNZ(M); End;
    $DE: Begin EA := CPU6502_AmABX; M := (CPU6502_MemGet(EA) - 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_SetNZ(M); End;
    $E8: Begin CPU6502_X := (CPU6502_X + 1) And $FF;
               CPU6502_SetNZ(CPU6502_X); End;
    $C8: Begin CPU6502_Y := (CPU6502_Y + 1) And $FF;
               CPU6502_SetNZ(CPU6502_Y); End;
    $CA: Begin CPU6502_X := (CPU6502_X - 1) And $FF;
               CPU6502_SetNZ(CPU6502_X); End;
    $88: Begin CPU6502_Y := (CPU6502_Y - 1) And $FF;
               CPU6502_SetNZ(CPU6502_Y); End;
    $69: Begin EA := CPU6502_AmIMM; CPU6502_DoADC(CPU6502_MemGet(EA)); End;
    $65: Begin EA := CPU6502_AmZP;  CPU6502_DoADC(CPU6502_MemGet(EA)); End;
    $75: Begin EA := CPU6502_AmZPX; CPU6502_DoADC(CPU6502_MemGet(EA)); End;
    $6D: Begin EA := CPU6502_AmABS; CPU6502_DoADC(CPU6502_MemGet(EA)); End;
    $7D: Begin EA := CPU6502_AmABX; CPU6502_DoADC(CPU6502_MemGet(EA)); End;
    $79: Begin EA := CPU6502_AmABY; CPU6502_DoADC(CPU6502_MemGet(EA)); End;
    $61: Begin EA := CPU6502_AmIZX; CPU6502_DoADC(CPU6502_MemGet(EA)); End;
    $71: Begin EA := CPU6502_AmIZY; CPU6502_DoADC(CPU6502_MemGet(EA)); End;
    $E9: Begin EA := CPU6502_AmIMM; CPU6502_DoSBC(CPU6502_MemGet(EA)); End;
    $E5: Begin EA := CPU6502_AmZP;  CPU6502_DoSBC(CPU6502_MemGet(EA)); End;
    $F5: Begin EA := CPU6502_AmZPX; CPU6502_DoSBC(CPU6502_MemGet(EA)); End;
    $ED: Begin EA := CPU6502_AmABS; CPU6502_DoSBC(CPU6502_MemGet(EA)); End;
    $FD: Begin EA := CPU6502_AmABX; CPU6502_DoSBC(CPU6502_MemGet(EA)); End;
    $F9: Begin EA := CPU6502_AmABY; CPU6502_DoSBC(CPU6502_MemGet(EA)); End;
    $E1: Begin EA := CPU6502_AmIZX; CPU6502_DoSBC(CPU6502_MemGet(EA)); End;
    $F1: Begin EA := CPU6502_AmIZY; CPU6502_DoSBC(CPU6502_MemGet(EA)); End;
    $29: Begin EA := CPU6502_AmIMM; CPU6502_A := CPU6502_A And CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $25: Begin EA := CPU6502_AmZP;  CPU6502_A := CPU6502_A And CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $35: Begin EA := CPU6502_AmZPX; CPU6502_A := CPU6502_A And CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $2D: Begin EA := CPU6502_AmABS; CPU6502_A := CPU6502_A And CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $3D: Begin EA := CPU6502_AmABX; CPU6502_A := CPU6502_A And CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $39: Begin EA := CPU6502_AmABY; CPU6502_A := CPU6502_A And CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $21: Begin EA := CPU6502_AmIZX; CPU6502_A := CPU6502_A And CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $31: Begin EA := CPU6502_AmIZY; CPU6502_A := CPU6502_A And CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $09: Begin EA := CPU6502_AmIMM; CPU6502_A := CPU6502_A Or  CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $05: Begin EA := CPU6502_AmZP;  CPU6502_A := CPU6502_A Or  CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $15: Begin EA := CPU6502_AmZPX; CPU6502_A := CPU6502_A Or  CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $0D: Begin EA := CPU6502_AmABS; CPU6502_A := CPU6502_A Or  CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $1D: Begin EA := CPU6502_AmABX; CPU6502_A := CPU6502_A Or  CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $19: Begin EA := CPU6502_AmABY; CPU6502_A := CPU6502_A Or  CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $01: Begin EA := CPU6502_AmIZX; CPU6502_A := CPU6502_A Or  CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $11: Begin EA := CPU6502_AmIZY; CPU6502_A := CPU6502_A Or  CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $49: Begin EA := CPU6502_AmIMM; CPU6502_A := CPU6502_A Xor CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $45: Begin EA := CPU6502_AmZP;  CPU6502_A := CPU6502_A Xor CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $55: Begin EA := CPU6502_AmZPX; CPU6502_A := CPU6502_A Xor CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $4D: Begin EA := CPU6502_AmABS; CPU6502_A := CPU6502_A Xor CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $5D: Begin EA := CPU6502_AmABX; CPU6502_A := CPU6502_A Xor CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $59: Begin EA := CPU6502_AmABY; CPU6502_A := CPU6502_A Xor CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $41: Begin EA := CPU6502_AmIZX; CPU6502_A := CPU6502_A Xor CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $51: Begin EA := CPU6502_AmIZY; CPU6502_A := CPU6502_A Xor CPU6502_MemGet(EA);
               CPU6502_SetNZ(CPU6502_A); End;
    $C9: Begin EA := CPU6502_AmIMM; CPU6502_DoCMP(CPU6502_A, CPU6502_MemGet(EA)); End;
    $C5: Begin EA := CPU6502_AmZP;  CPU6502_DoCMP(CPU6502_A, CPU6502_MemGet(EA)); End;
    $D5: Begin EA := CPU6502_AmZPX; CPU6502_DoCMP(CPU6502_A, CPU6502_MemGet(EA)); End;
    $CD: Begin EA := CPU6502_AmABS; CPU6502_DoCMP(CPU6502_A, CPU6502_MemGet(EA)); End;
    $DD: Begin EA := CPU6502_AmABX; CPU6502_DoCMP(CPU6502_A, CPU6502_MemGet(EA)); End;
    $D9: Begin EA := CPU6502_AmABY; CPU6502_DoCMP(CPU6502_A, CPU6502_MemGet(EA)); End;
    $C1: Begin EA := CPU6502_AmIZX; CPU6502_DoCMP(CPU6502_A, CPU6502_MemGet(EA)); End;
    $D1: Begin EA := CPU6502_AmIZY; CPU6502_DoCMP(CPU6502_A, CPU6502_MemGet(EA)); End;
    $E0: Begin EA := CPU6502_AmIMM; CPU6502_DoCMP(CPU6502_X, CPU6502_MemGet(EA)); End;
    $E4: Begin EA := CPU6502_AmZP;  CPU6502_DoCMP(CPU6502_X, CPU6502_MemGet(EA)); End;
    $EC: Begin EA := CPU6502_AmABS; CPU6502_DoCMP(CPU6502_X, CPU6502_MemGet(EA)); End;
    $C0: Begin EA := CPU6502_AmIMM; CPU6502_DoCMP(CPU6502_Y, CPU6502_MemGet(EA)); End;
    $C4: Begin EA := CPU6502_AmZP;  CPU6502_DoCMP(CPU6502_Y, CPU6502_MemGet(EA)); End;
    $CC: Begin EA := CPU6502_AmABS; CPU6502_DoCMP(CPU6502_Y, CPU6502_MemGet(EA)); End;
    $24: Begin EA := CPU6502_AmZP;  M := CPU6502_MemGet(EA);
               CPU6502_SetZ((M And CPU6502_A) = 0);
               CPU6502_SetN((M And $80) <> 0);
               CPU6502_SetV((M And $40) <> 0); End;
    $2C: Begin EA := CPU6502_AmABS; M := CPU6502_MemGet(EA);
               CPU6502_SetZ((M And CPU6502_A) = 0);
               CPU6502_SetN((M And $80) <> 0);
               CPU6502_SetV((M And $40) <> 0); End;
    $0A: CPU6502_A := CPU6502_DoASL(CPU6502_A);
    $06: Begin EA := CPU6502_AmZP;  CPU6502_MemSet(EA, CPU6502_DoASL(CPU6502_MemGet(EA))); End;
    $16: Begin EA := CPU6502_AmZPX; CPU6502_MemSet(EA, CPU6502_DoASL(CPU6502_MemGet(EA))); End;
    $0E: Begin EA := CPU6502_AmABS; CPU6502_MemSet(EA, CPU6502_DoASL(CPU6502_MemGet(EA))); End;
    $1E: Begin EA := CPU6502_AmABX; CPU6502_MemSet(EA, CPU6502_DoASL(CPU6502_MemGet(EA))); End;
    $4A: CPU6502_A := CPU6502_DoLSR(CPU6502_A);
    $46: Begin EA := CPU6502_AmZP;  CPU6502_MemSet(EA, CPU6502_DoLSR(CPU6502_MemGet(EA))); End;
    $56: Begin EA := CPU6502_AmZPX; CPU6502_MemSet(EA, CPU6502_DoLSR(CPU6502_MemGet(EA))); End;
    $4E: Begin EA := CPU6502_AmABS; CPU6502_MemSet(EA, CPU6502_DoLSR(CPU6502_MemGet(EA))); End;
    $5E: Begin EA := CPU6502_AmABX; CPU6502_MemSet(EA, CPU6502_DoLSR(CPU6502_MemGet(EA))); End;
    $2A: CPU6502_A := CPU6502_DoROL(CPU6502_A);
    $26: Begin EA := CPU6502_AmZP;  CPU6502_MemSet(EA, CPU6502_DoROL(CPU6502_MemGet(EA))); End;
    $36: Begin EA := CPU6502_AmZPX; CPU6502_MemSet(EA, CPU6502_DoROL(CPU6502_MemGet(EA))); End;
    $2E: Begin EA := CPU6502_AmABS; CPU6502_MemSet(EA, CPU6502_DoROL(CPU6502_MemGet(EA))); End;
    $3E: Begin EA := CPU6502_AmABX; CPU6502_MemSet(EA, CPU6502_DoROL(CPU6502_MemGet(EA))); End;
    $6A: CPU6502_A := CPU6502_DoROR(CPU6502_A);
    $66: Begin EA := CPU6502_AmZP;  CPU6502_MemSet(EA, CPU6502_DoROR(CPU6502_MemGet(EA))); End;
    $76: Begin EA := CPU6502_AmZPX; CPU6502_MemSet(EA, CPU6502_DoROR(CPU6502_MemGet(EA))); End;
    $6E: Begin EA := CPU6502_AmABS; CPU6502_MemSet(EA, CPU6502_DoROR(CPU6502_MemGet(EA))); End;
    $7E: Begin EA := CPU6502_AmABX; CPU6502_MemSet(EA, CPU6502_DoROR(CPU6502_MemGet(EA))); End;
    $10: CPU6502_Branch((CPU6502_P And $80) = 0);
    $30: CPU6502_Branch((CPU6502_P And $80) <> 0);
    $50: CPU6502_Branch((CPU6502_P And $40) = 0);
    $70: CPU6502_Branch((CPU6502_P And $40) <> 0);
    $90: CPU6502_Branch((CPU6502_P And $01) = 0);
    $B0: CPU6502_Branch((CPU6502_P And $01) <> 0);
    $D0: CPU6502_Branch((CPU6502_P And $02) = 0);
    $F0: CPU6502_Branch((CPU6502_P And $02) <> 0);
    $4C: CPU6502_PC := CPU6502_AmABS;
    $6C: Begin T := CPU6502_AmABS;
               CPU6502_PC := CPU6502_Read16Bug(T); End;
    $20: Begin T := CPU6502_AmABS;
               CPU6502_Push16(CPU6502_PC - 1);
               CPU6502_PC := T; End;
    $60: Begin T := CPU6502_Pop16; CPU6502_PC := T + 1; End;
    $40: Begin CPU6502_P := (CPU6502_Pop And $CF) Or $20;
               CPU6502_PC := CPU6502_Pop16; End;
    $00: Begin
           If CPU6502_Variant = 3 Then Begin
             Inc(CPU6502_PC);
             CPU6502_Push((CPU6502_PC Shr 8) And $FF);
             CPU6502_Push(CPU6502_PC And $FF);
             CPU6502_Push(CPU6502_P Or $30);
             CPU6502_P := CPU6502_P Or $04;
             CPU6502_PC := CPU6502_MemGet($FFFE) Or
                           (Word(CPU6502_MemGet($FFFF)) Shl 8);
           End Else Begin
             CPU6502_Halted := True;
             CPU6502_ExitCode := 0;
           End;
         End;
    $EA: ;
    $1A, $3A, $5A, $7A, $DA, $FA: ;
    $80, $82, $89, $C2, $E2: Inc(CPU6502_PC);
    $04, $44, $64: Inc(CPU6502_PC);
    $14, $34, $54, $74, $D4, $F4: Inc(CPU6502_PC);
    $0C: Inc(CPU6502_PC, 2);
    $1C, $3C, $5C, $7C, $DC, $FC: Inc(CPU6502_PC, 2);
    $A3: Begin EA := CPU6502_AmIZX; CPU6502_A := CPU6502_MemGet(EA);
               CPU6502_X := CPU6502_A; CPU6502_SetNZ(CPU6502_A); End;
    $A7: Begin EA := CPU6502_AmZP;  CPU6502_A := CPU6502_MemGet(EA);
               CPU6502_X := CPU6502_A; CPU6502_SetNZ(CPU6502_A); End;
    $AF: Begin EA := CPU6502_AmABS; CPU6502_A := CPU6502_MemGet(EA);
               CPU6502_X := CPU6502_A; CPU6502_SetNZ(CPU6502_A); End;
    $B3: Begin EA := CPU6502_AmIZY; CPU6502_A := CPU6502_MemGet(EA);
               CPU6502_X := CPU6502_A; CPU6502_SetNZ(CPU6502_A); End;
    $B7: Begin EA := CPU6502_AmZPY; CPU6502_A := CPU6502_MemGet(EA);
               CPU6502_X := CPU6502_A; CPU6502_SetNZ(CPU6502_A); End;
    $BF: Begin EA := CPU6502_AmABY; CPU6502_A := CPU6502_MemGet(EA);
               CPU6502_X := CPU6502_A; CPU6502_SetNZ(CPU6502_A); End;
    $83: Begin EA := CPU6502_AmIZX; CPU6502_MemSet(EA, CPU6502_A And CPU6502_X); End;
    $87: Begin EA := CPU6502_AmZP;  CPU6502_MemSet(EA, CPU6502_A And CPU6502_X); End;
    $8F: Begin EA := CPU6502_AmABS; CPU6502_MemSet(EA, CPU6502_A And CPU6502_X); End;
    $97: Begin EA := CPU6502_AmZPY; CPU6502_MemSet(EA, CPU6502_A And CPU6502_X); End;
    $C3: Begin EA := CPU6502_AmIZX; M := (CPU6502_MemGet(EA) - 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_DoCMP(CPU6502_A, M); End;
    $C7: Begin EA := CPU6502_AmZP;  M := (CPU6502_MemGet(EA) - 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_DoCMP(CPU6502_A, M); End;
    $CF: Begin EA := CPU6502_AmABS; M := (CPU6502_MemGet(EA) - 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_DoCMP(CPU6502_A, M); End;
    $D3: Begin EA := CPU6502_AmIZY; M := (CPU6502_MemGet(EA) - 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_DoCMP(CPU6502_A, M); End;
    $D7: Begin EA := CPU6502_AmZPX; M := (CPU6502_MemGet(EA) - 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_DoCMP(CPU6502_A, M); End;
    $DB: Begin EA := CPU6502_AmABY; M := (CPU6502_MemGet(EA) - 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_DoCMP(CPU6502_A, M); End;
    $DF: Begin EA := CPU6502_AmABX; M := (CPU6502_MemGet(EA) - 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_DoCMP(CPU6502_A, M); End;
    $E3: Begin EA := CPU6502_AmIZX; M := (CPU6502_MemGet(EA) + 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_DoSBC(M); End;
    $E7: Begin EA := CPU6502_AmZP;  M := (CPU6502_MemGet(EA) + 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_DoSBC(M); End;
    $EF: Begin EA := CPU6502_AmABS; M := (CPU6502_MemGet(EA) + 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_DoSBC(M); End;
    $F3: Begin EA := CPU6502_AmIZY; M := (CPU6502_MemGet(EA) + 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_DoSBC(M); End;
    $F7: Begin EA := CPU6502_AmZPX; M := (CPU6502_MemGet(EA) + 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_DoSBC(M); End;
    $FB: Begin EA := CPU6502_AmABY; M := (CPU6502_MemGet(EA) + 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_DoSBC(M); End;
    $FF: Begin EA := CPU6502_AmABX; M := (CPU6502_MemGet(EA) + 1) And $FF;
               CPU6502_MemSet(EA, M); CPU6502_DoSBC(M); End;
    $03: Begin EA := CPU6502_AmIZX; M := CPU6502_DoASL(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A Or M;
               CPU6502_SetNZ(CPU6502_A); End;
    $07: Begin EA := CPU6502_AmZP;  M := CPU6502_DoASL(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A Or M;
               CPU6502_SetNZ(CPU6502_A); End;
    $0F: Begin EA := CPU6502_AmABS; M := CPU6502_DoASL(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A Or M;
               CPU6502_SetNZ(CPU6502_A); End;
    $13: Begin EA := CPU6502_AmIZY; M := CPU6502_DoASL(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A Or M;
               CPU6502_SetNZ(CPU6502_A); End;
    $17: Begin EA := CPU6502_AmZPX; M := CPU6502_DoASL(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A Or M;
               CPU6502_SetNZ(CPU6502_A); End;
    $1B: Begin EA := CPU6502_AmABY; M := CPU6502_DoASL(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A Or M;
               CPU6502_SetNZ(CPU6502_A); End;
    $1F: Begin EA := CPU6502_AmABX; M := CPU6502_DoASL(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A Or M;
               CPU6502_SetNZ(CPU6502_A); End;
    $23: Begin EA := CPU6502_AmIZX; M := CPU6502_DoROL(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A And M;
               CPU6502_SetNZ(CPU6502_A); End;
    $27: Begin EA := CPU6502_AmZP;  M := CPU6502_DoROL(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A And M;
               CPU6502_SetNZ(CPU6502_A); End;
    $2F: Begin EA := CPU6502_AmABS; M := CPU6502_DoROL(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A And M;
               CPU6502_SetNZ(CPU6502_A); End;
    $33: Begin EA := CPU6502_AmIZY; M := CPU6502_DoROL(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A And M;
               CPU6502_SetNZ(CPU6502_A); End;
    $37: Begin EA := CPU6502_AmZPX; M := CPU6502_DoROL(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A And M;
               CPU6502_SetNZ(CPU6502_A); End;
    $3B: Begin EA := CPU6502_AmABY; M := CPU6502_DoROL(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A And M;
               CPU6502_SetNZ(CPU6502_A); End;
    $3F: Begin EA := CPU6502_AmABX; M := CPU6502_DoROL(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A And M;
               CPU6502_SetNZ(CPU6502_A); End;
    $43: Begin EA := CPU6502_AmIZX; M := CPU6502_DoLSR(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A Xor M;
               CPU6502_SetNZ(CPU6502_A); End;
    $47: Begin EA := CPU6502_AmZP;  M := CPU6502_DoLSR(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A Xor M;
               CPU6502_SetNZ(CPU6502_A); End;
    $4F: Begin EA := CPU6502_AmABS; M := CPU6502_DoLSR(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A Xor M;
               CPU6502_SetNZ(CPU6502_A); End;
    $53: Begin EA := CPU6502_AmIZY; M := CPU6502_DoLSR(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A Xor M;
               CPU6502_SetNZ(CPU6502_A); End;
    $57: Begin EA := CPU6502_AmZPX; M := CPU6502_DoLSR(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A Xor M;
               CPU6502_SetNZ(CPU6502_A); End;
    $5B: Begin EA := CPU6502_AmABY; M := CPU6502_DoLSR(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A Xor M;
               CPU6502_SetNZ(CPU6502_A); End;
    $5F: Begin EA := CPU6502_AmABX; M := CPU6502_DoLSR(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_A := CPU6502_A Xor M;
               CPU6502_SetNZ(CPU6502_A); End;
    $63: Begin EA := CPU6502_AmIZX; M := CPU6502_DoROR(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_DoADC(M); End;
    $67: Begin EA := CPU6502_AmZP;  M := CPU6502_DoROR(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_DoADC(M); End;
    $6F: Begin EA := CPU6502_AmABS; M := CPU6502_DoROR(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_DoADC(M); End;
    $73: Begin EA := CPU6502_AmIZY; M := CPU6502_DoROR(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_DoADC(M); End;
    $77: Begin EA := CPU6502_AmZPX; M := CPU6502_DoROR(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_DoADC(M); End;
    $7B: Begin EA := CPU6502_AmABY; M := CPU6502_DoROR(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_DoADC(M); End;
    $7F: Begin EA := CPU6502_AmABX; M := CPU6502_DoROR(CPU6502_MemGet(EA));
               CPU6502_MemSet(EA, M); CPU6502_DoADC(M); End;
    $0B, $2B: Begin EA := CPU6502_AmIMM;
                    CPU6502_A := CPU6502_A And CPU6502_MemGet(EA);
                    CPU6502_SetNZ(CPU6502_A);
                    CPU6502_SetC((CPU6502_A And $80) <> 0); End;
    $4B: Begin EA := CPU6502_AmIMM;
               CPU6502_A := CPU6502_A And CPU6502_MemGet(EA);
               CPU6502_A := CPU6502_DoLSR(CPU6502_A); End;
    $6B: Begin EA := CPU6502_AmIMM;
               CPU6502_A := CPU6502_A And CPU6502_MemGet(EA);
               CPU6502_A := CPU6502_DoROR(CPU6502_A); End;
    $CB: Begin EA := CPU6502_AmIMM;
               TmpW := (Word(CPU6502_A And CPU6502_X) -
                        Word(CPU6502_MemGet(EA))) And $1FF;
               CPU6502_X := TmpW And $FF;
               CPU6502_SetC(TmpW < $100);
               CPU6502_SetNZ(CPU6502_X); End;
    $EB: Begin EA := CPU6502_AmIMM; CPU6502_DoSBC(CPU6502_MemGet(EA)); End;
  Else
    CPU6502_Halted := True;
    CPU6502_ExitCode := 1;
  End;
End;


Procedure CPU6502_Reset(EntryAddr: Word);
Begin
  CPU6502_A := 0;
  CPU6502_X := 0;
  CPU6502_Y := 0;
  CPU6502_P := $24;
  CPU6502_S := $FD;
  CPU6502_PC := EntryAddr;
  CPU6502_Halted := False;
  CPU6502_ExitCode := 0;
  CPU6502_Cycles := 0;
End;

{ =================================================================== }
{ CHARGEUR iNES                                                        }
{ =================================================================== }

Function Nes_LoadInes(Const FileName: String): Boolean;
Var
  F: File;
  Hdr: Array[0..15] Of Byte;
  PrgBlocks, ChrBlocks: Byte;
  PrgSize, ChrSize: LongInt;
  BR: Word;
  EntryAddr: Word;
  I: LongInt;
Begin
  Nes_LoadInes := False;
  CPU6502_ClearMem;
  FillChar(NesChr, SizeOf(NesChr), 0);
  NesPrgRomClear;
  NesChrRomClear;
  NesPpu_Reset;
  NesMapper := 0;
  NesUseChrRam := False;
  NesPrgBlocksTotal := 0;
  NesChrBlocksTotal := 0;
  NesMirror := 0;
  Assign(F, FileName);
  FileMode := 0;        { lecture seule : la ROM peut etre read-only }
  {$I-} Reset(F, 1); {$I+}
  If IOResult <> 0 Then Exit;
  BR := 0;
  BlockRead(F, Hdr, 16, BR);
  If BR <> 16 Then Begin Close(F); Exit; End;
  If (Hdr[0] <> $4E) Or (Hdr[1] <> $45) Or
     (Hdr[2] <> $53) Or (Hdr[3] <> $1A) Then Begin
    Close(F);
    Exit;
  End;
  PrgBlocks := Hdr[4];
  ChrBlocks := Hdr[5];
  NesPrgBlocksTotal := PrgBlocks;
  NesChrBlocksTotal := ChrBlocks;
  If ChrBlocks = 0 Then NesUseChrRam := True;
  If (Hdr[6] And $01) <> 0 Then NesMirror := 1
                           Else NesMirror := 0;
  If (Hdr[6] And $08) <> 0 Then NesMirror := 2;
  NesMapper := ((Hdr[6] Shr 4) And $0F) Or (Hdr[7] And $F0);
  { Heuristique DiskDude! }
  If (Hdr[12] <> 0) Or (Hdr[13] <> 0) Or
     (Hdr[14] <> 0) Or (Hdr[15] <> 0) Then
    NesMapper := (Hdr[6] Shr 4) And $0F;
  { Skip trainer si bit 2 }
  If (Hdr[6] And $04) <> 0 Then
    Seek(F, 16 + 512)
  Else
    Seek(F, 16);
  PrgSize := LongInt(PrgBlocks) * 16384;
  If PrgSize > LongInt(NesPrgRomChunks)*NesRomChunkSize Then PrgSize := LongInt(NesPrgRomChunks)*NesRomChunkSize;
  If PrgSize > 0 Then
    NesPrgRomRead(F,PrgSize);
  ChrSize := LongInt(ChrBlocks) * 8192;
  If ChrSize > LongInt(NesChrRomChunks)*NesRomChunkSize Then ChrSize := LongInt(NesChrRomChunks)*NesRomChunkSize;
  If ChrSize > 0 Then
    NesChrRomRead(F,ChrSize);
  Close(F);
  { Mapping initial }
  If NesMapper = 0 Then Begin
    For I := 0 To 16383 Do
      CPU6502_MemSet($8000 + I, NesPrgRomGet(I));
    If NesPrgBlocksTotal >= 2 Then
      For I := 0 To 16383 Do
        CPU6502_MemSet($C000 + I, NesPrgRomGet(16384 + I))
    Else
      For I := 0 To 16383 Do
        CPU6502_MemSet($C000 + I, NesPrgRomGet(I));
    If NesChrBlocksTotal >= 1 Then
      For I := 0 To 8191 Do
        NesChr[I] := NesChrRomGet(I);
  End Else
    Nes_MapperInit;
  EntryAddr := CPU6502_MemGet($FFFC) Or (Word(CPU6502_MemGet($FFFD)) Shl 8);
  CPU6502_Variant := 3;
  CPU6502_Reset(EntryAddr);
  NesActive := True;
  Nes_LoadInes := True;
End;

{ =================================================================== }
{ AFFICHAGE BGI                                                        }
{ =================================================================== }

Procedure NesInitGraphics;
Var Driver, Mode, ErrCode: Integer;
Begin
 {$IFDEF FPC}
  Driver := VGA;
  Mode   := VGAHi;       { 640x480x16 }
 {$ELSE}
  Driver := Detect;
  Mode   := 0;
 {$ENDIF}
 InitGraph(Driver, Mode, '');
 ErrCode := GraphResult;
 If ErrCode <> grOk Then Begin
   WriteLn('NES: Erreur graphique: ', GraphErrorMsg(ErrCode));
   Halt(1);
 End;
 ScrW := GetMaxX + 1;
 ScrH := GetMaxY + 1;
 If (ScrW >= 512) And (ScrH >= 480) Then NesScale := 2
                                    Else NesScale := 1;
 NesOX := (ScrW - 256 * NesScale) Div 2;
 If NesOX < 0 Then NesOX := 0;
 NesOY := (ScrH - 240 * NesScale) Div 2;
 If NesOY < 0 Then NesOY := 0;
 SetColor(15);
 SetBkColor(0);
 ClearViewPort;
End;

Procedure NesShutdownGraphics;
Begin
  CloseGraph;
End;

Procedure NesRenderToScreen;
Var
  Px, Py: Integer;
  C: Byte;
  Sx, Sy: Integer;
Begin
  For Py := 0 To 239 Do
    For Px := 0 To 255 Do Begin
      If NesFBFirst Or (NesFB^[Py, Px] <> NesFBPrev^[Py, Px]) Then Begin
        C := NesPalToEga[NesFB^[Py, Px] And $3F];
        Sx := NesOX + Px * NesScale;
        Sy := NesOY + Py * NesScale;
        SetColor(C);
        If NesScale = 1 Then
          PutPixel(Sx, Sy, C)
        Else Begin
          { 2x2 bloc }
          PutPixel(Sx,     Sy,     C);
          PutPixel(Sx + 1, Sy,     C);
          PutPixel(Sx,     Sy + 1, C);
          PutPixel(Sx + 1, Sy + 1, C);
        End;
        NesFBPrev^[Py, Px] := NesFB^[Py, Px];
      End;
    End;
  NesFBFirst := False;
End;

{ =================================================================== }
{ PROGRAMME PRINCIPAL                                                  }
{ =================================================================== }

Var
  RomFile: String;
  FrameLimit, InstrPerFrame, Steps: LongInt;
  T0, T1: LongInt;
  KeyEsc: Boolean;
  I: LongInt;
  Ch: Char;

BEGIN
  If ParamCount < 1 Then Begin
    WriteLn('NES.PAS - Cette commande permet de lancer un emulateur NES');
    WriteLn;
    WriteLn('Syntaxe : NES fichier.NES');
    WriteLn;
    WriteLn('Touches :');
    WriteLn('  Fleches  = D-Pad');
    WriteLn('  Z / A    = bouton A NES');
    WriteLn('  X / S    = bouton B NES');
    WriteLn('  Tab      = Select');
    WriteLn('  Entree   = Start');
    WriteLn('  Echap    = quitter');
    Halt(1);
  End;
  NesFB:=NIL;
  NesFBPrev:=NIL;
  NesAllocHeap;
  CPU6502_MemLo:=NIL;
  CPU6502_MemHi:=NIL;
  CPU6502_AllocMem;
  RomFile := ParamStr(1);
  WriteLn('Chargement de ', RomFile, '...');
  If Not Nes_LoadInes(RomFile) Then Begin
    WriteLn('Erreur : impossible de charger ', RomFile);
    WriteLn('(Verifiez que le fichier existe et qu il commence par "NES', Chr($1A), '").');
    Halt(2);
  End;
  WriteLn('PRG=', NesPrgBlocksTotal, ' blocs (16K), CHR=', NesChrBlocksTotal,
          ' blocs (8K), Mapper=', NesMapper, ', Mirror=', NesMirror);
  WriteLn('PC initial=$', HexW(CPU6502_PC));
  WriteLn('Demarrage emulateur (Echap pour quitter)...');

  NesInitGraphics;

  Steps         := 0;
  FrameLimit    := 36000;     { 10 minutes a 60 Hz }
  InstrPerFrame := 7460;      { ~29780 cy / 4 cy moy }
  NesFrameNo    := 0;
  KeyEsc        := False;
  NesFBFirst    := True;
  FillChar(NesFBPrev^, SizeOf(TNesFrameBuffer), $FF);

  {$IFDEF WINDOWS}
  T0 := GetTickCount;
  {$ELSE}
  T0 := 0;
  {$ENDIF}

  While (Not CPU6502_Halted) And (NesFrameNo < FrameLimit) And
        (Not KeyEsc) Do Begin
    { Drainer le buffer Crt (Echap rapide via clavier console aussi) }
    While KeyPressed Do Begin
      Ch := ReadKey;
      If Ch = #27 Then KeyEsc := True;
      If Ch = #0 Then If KeyPressed Then ReadKey;
    End;
    {$IFDEF WINDOWS}
    If GetAsyncKeyState($1B) < 0 Then KeyEsc := True;
    {$ENDIF}
    If KeyEsc Then Break;

    NesPollInput;

    { Pre-render scanline 261 : effacer vblank et sprite0 hit }
    NesPpuStatus := NesPpuStatus And $7F;
    NesPpuStatus := NesPpuStatus And $BF;

    { Phase visible }
    For I := 0 To (InstrPerFrame * 4 Div 5) - 1 Do Begin
      If CPU6502_Halted Then Break;
      CPU6502_Step;
      Inc(Steps);
    End;

    NesPpu_RenderFrame;

    { vblank + NMI }
    NesPpuStatus := NesPpuStatus Or $80;
    If (NesPpuCtrl And $80) <> 0 Then NesNmiPending := True;

    For I := 0 To (InstrPerFrame Div 5) - 1 Do Begin
      If CPU6502_Halted Then Break;
      CPU6502_Step;
      Inc(Steps);
    End;

    NesRenderToScreen;
    Inc(NesFrameNo);

    {$IFDEF WINDOWS}
    T1 := GetTickCount - T0;
    If T1 < 16 Then WinSleep(16 - T1);
    T0 := GetTickCount;
    {$ENDIF}
  End;

  NesShutdownGraphics;

  WriteLn;
  If CPU6502_Halted Then
    WriteLn('[Fin emulateur 6502 : ', Steps, ' instructions, code=',
            CPU6502_ExitCode, ']')
  Else
    WriteLn('[Emulation NES arretee : ', Steps, ' instr / ',
            NesFrameNo, ' trames]');
  CPU6502_FreeMem;
  NesFreeHeap;
END.
