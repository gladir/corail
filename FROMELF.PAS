{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program FROMELF;

{$A-}

Var
 I:Integer;
 FileELF:File;
 ByteReaded:Word;
 Header:Record
  Sign:Array[0..3]of Char;
  Format,MemCellFormat:Byte;
  Version:Byte;
  OSABI:Byte;
  Inused1:Array[8..15]of Byte;
  FileType:Word;
  InstructionUsed:Word;
 End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('FROMELF: Cette commande permet d''analyser un ELF.');
  WriteLn;
  WriteLn('Syntaxe: FROMELF programme[.ELF]');
  WriteLn;
  WriteLn('programme  Ce paramŠtre permet d''indiquer le nom du programme.');
 End
  Else
 If ParamCount>0Then For I:=1 to ParamCount do Begin
  {$I+}Assign(FileELF,ParamStr(I));
  Reset(FileELF,1);{$I-}
  If IOResult<>0 Then Begin
   WriteLn('Erreur de lecture du fichier ',ParamStr(I),' !');
   Halt;
  End;
  Seek(FileELF,0);
  BlockRead(FileELF,Header,SizeOf(Header),ByteReaded);
  If ByteReaded=0 Then Begin
   WriteLn('Erreur de lecture de l''entˆte ELF');
   Halt;
  End
   Else
  If(Header.Sign[0]=#$7F)and(Header.Sign[1]='E')and
    (Header.Sign[2]='L')and(Header.Sign[3]='F')Then Begin
   WriteLn('Type de fichier :    ','ELF');
   Write  ('Format :             ');
   Case Header.Format of
    1:WriteLn('32 bits');
    2:WriteLn('64 bits');
    Else WriteLn('Inconnu : ',Header.Format);
   End;
   Write  ('Format des cellules: ');
   Case Header.MemCellFormat of
    1:WriteLn('Petite-Boutiste - Little Endian (LSB)');
    2:WriteLn('Gros-Boutiste - Big Endian (MSB)');
    Else WriteLn('Inconnu : ',Header.Format);
   End;
   WriteLn('Version ELF :        ',Header.Version);
   Write  ('Interface binaire (ABI) :');
   Case Header.OSABI of
    0:WriteLn('UNIX System V');
    1:WriteLn('HP-UX');
    2:WriteLn('NetBSD');
    3:WriteLn('Linux');
    6:WriteLn('Sun Solaris');
    7:WriteLn('IBM AIX');
    8:WriteLn('SGI Irix');
    9:WriteLn('FreeBSD');
    10:WriteLn('Compaq TRU64');
    11:WriteLn('Novell Modesto');
    12:WriteLn('OpenBSD');
    64:WriteLn('ARM EABI');
    97:WriteLn('ARM');
    255:WriteLn('Standalone');
    Else WriteLn('Inconnu')
   End;
   Write  ('Type de fichier :        ');
   Case Header.FileType of
    1:WriteLn('Repositionable');
    2:WriteLn('Ex‚cutable');
    3:WriteLn('Partag‚');
    4:WriteLn('Coeur du systŠme d''exploitation');
    Else WriteLn('Inconnu')
   End;
   Write  ('Ensemble d''instructions :');
   Case Header.InstructionUsed of
    $00:WriteLn('Architecture non sp‚cifi‚.');
    $02:WriteLn('Sparc');
    $03:WriteLn('80x86');
    $08:WriteLn('MIPS');
    $14:WriteLn('PowerPC');
    $28:WriteLn('ARM');
    $2A:WriteLn('SuperH');
    $32:WriteLn('IA-64');
    $3E:WriteLn('x86-64');
    $B7:WriteLn('AArch64');
    Else WriteLn('Inconnu')
   End;
  End
   Else
  WriteLn('Signature ELF invalide');
  Close(FileELF);
 End;
END.