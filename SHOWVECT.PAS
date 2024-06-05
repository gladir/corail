{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program SHOWVECT;

Uses Crt,DOS,Strings;

Const
 VectStr:Array[0..255]of PChar=(
  {00h}'Division par z‚ro',
  {01h}'Pas … pas',
  {02h}'Erreur m‚moire',
  {03h}'Point d''arrˆt',
  {04h}'D‚bordement',
  {05h}'Impression de l''‚cran',
  {06h}'Instruction invalide',
  {07h}'Instruction coprocesseur',
  {08h}'(IRQ0) Interruption temporisateur',
  {09h}'(IRQ1) Interruption clavier',
  {0Ah}'(IRQ2) [Cascade]',
  {0Bh}'(IRQ3) Port s‚rie 2 (COM2)',
  {0Ch}'(IRQ4) Port s‚rie 1 (COM1)',
  {0Dh}'(IRQ5) Port parallŠle 2 (LPT2)',
  {0Eh}'(IRQ6) Contr“leur de disquette',
  {0Fh}'(IRQ7) Port parallŠle 1 (LPT1)',
  {10h}'Interface de gestion vid‚o',
  {11h}'Demande la configuration',
  {12h}'Demande la taille de la m‚moire conventionnelle',
  {13h}'Interface de gestion d''accŠs aux disques',
  {14h}'Interface de gestion AUX/FOSSIL',
  {15h}'Extension d''Entr‚e/Sortie',
  {16h}'Interface de gestion du clavier',
  {17h}'Interface de gestion d''imprimante',
  {18h}'Appel du BASIC en ROM',
  {19h}'Red‚marrage de l''ordinateur',
  {1Ah}'Interface de gestion du temps',
  {1Bh}'Pour le clavier quand la touche Break actionn‚',
  {1Ch}'Routine d''horloge',
  {1Dh}'Cette interruption est un pointeur vers les paramŠtres de la table vid‚o',
  {1Eh}'ParamŠtre disquette',
  {1Fh}'CaractŠres graphiques vid‚o',
  {20h}'Terminer un programme',
  {21h}'Service du DOS (DOS API)',
  {22h}'Routine pour terminer un programme',
  {23h}'Touche Break actionn‚e',
  {24h}'Erreur critique',
  {25h}'Lecture absolue',
  {26h}'criture absolue',
  {27h}'Terminer en TSR',
  {28h}'DOS en attente',
  {29h}'Sortie rapide de la console',
  {2Ah}'Interface de service r‚seau',
  {2Bh}'Expansion future du DOS',
  {2Ch}'Services RM386',
  {2Dh}'Services AMIS',
  {2Eh}'EXEC du prompt de COMMAND',
  {2Fh}'Interruption Multiplexe',
  {30h}'R‚serv‚ par DOS',
  {31h}'R‚serv‚ par DOS',
  {32h}'R‚serv‚ par DOS',
  {33h}'Interface du pilote de souris',
  {34h}'R‚serv‚ par DOS',
  {35h}'R‚serv‚ par DOS',
  {36h}'R‚serv‚ par DOS',
  {37h}'R‚serv‚ par DOS',
  {38h}'R‚serv‚ par DOS',
  {39h}'R‚serv‚ par DOS',
  {3Ah}'R‚serv‚ par DOS',
  {3Bh}'R‚serv‚ par DOS',
  {3Ch}'R‚serv‚ par DOS',
  {3Dh}'R‚serv‚ par DOS',
  {3Eh}'R‚serv‚ par DOS',
  {3Fh}'Gestionnaire de recouvrement',
  {40h}'Gestionnaire de lecteur de disquettes',
  {41h}'ParamŠtres du premier disque dur',
  {42h}'Gestionnaire vid‚o par d‚faut',
  {43h}'Table de caractŠres',
  {44h}'Novell Netware (API)',
  {45h}'Inutilis‚',
  {46h}'ParamŠtres du deuxiŠme disque dur',
  {47h}'Inutilis‚',
  {48h}'Inutilis‚',
  {49h}'Inutilis‚',
  {4Ah}'Gestionnaire d''alarme du BIOS',
  {4Bh}'Gestionnaire virtuel',
  {4Ch}'Inutilis‚',
  {4Dh}'Inutilis‚',
  {4Eh}'Inutilis‚',
  {4Fh}'Inutilis‚',
  {50h}'Inutilis‚',
  {51h}'Inutilis‚',
  {52h}'Inutilis‚',
  {53h}'Inutilis‚',
  {54h}'Inutilis‚',
  {55h}'Inutilis‚',
  {56h}'Inutilis‚',
  {57h}'Inutilis‚',
  {58h}'Inutilis‚',
  {59h}'Interface de gestion du GSS Computer Graphics Interface',
  {5Ah}'DoubleDOS/DESQview',
  {5Bh}'Inutilis‚',
  {5Ch}'Gestionnaire BIOS R‚seau (NetBIOS)',
  {5Dh}'Inutilis‚',
  {5Eh}'Inutilis‚',
  {5Fh}'Inutilis‚',
  {60h}'Inutilis‚',
  {61h}'Inutilis‚',
  {62h}'Inutilis‚',
  {63h}'Inutilis‚',
  {64h}'Inutilis‚',
  {65h}'Inutilis‚',
  {66h}'Inutilis‚',
  {67h}'Gestionnaire EMS/EMM',
  {68h}'Inutilis‚',
  {69h}'Inutilis‚',
  {6Ah}'Inutilis‚',
  {6Bh}'Inutilis‚',
  {6Ch}'Inutilis‚',
  {6Dh}'Inutilis‚',
  {6Eh}'Inutilis‚',
  {6Fh}'Gestionnaire 10NET et HP Vectra EX-BIOS',
  {70h}'(IRQ8) Horloge en temps r‚el',
  {71h}'(IRQ9) R‚serv‚',
  {72h}'(IRQ10) R‚serv‚',
  {73h}'(IRQ11) R‚serv‚',
  {74h}'(IRQ12) Souris',
  {75h}'(IRQ13) Coprocesseur math‚matique',
  {76h}'(IRQ14) R‚serv‚',
  {77h}'(IRQ15) R‚serv‚',
  {78h}'Inutilis‚',
  {79h}'Inutilis‚',
  {7Ah}'Gestionnaire Novell Netware (API)',
  {7Bh}'Inutilis‚',
  {7Ch}'Inutilis‚',
  {7Dh}'Inutilis‚',
  {7Eh}'Inutilis‚',
  {7Fh}'Inutilis‚',
  {80h}'Appel au noyau Linux (API)',
  {81h}'Interpr‚teur BASIC',
  {82h}'Interpr‚teur BASIC',
  {83h}'Interpr‚teur BASIC',
  {84h}'Interpr‚teur BASIC',
  {85h}'Interpr‚teur BASIC',
  {86h}'Interpr‚teur BASIC',
  {87h}'Interpr‚teur BASIC',
  {88h}'Interpr‚teur BASIC',
  {89h}'Interpr‚teur BASIC',
  {8Ah}'Interpr‚teur BASIC',
  {8Bh}'Interpr‚teur BASIC',
  {8Ch}'Interpr‚teur BASIC',
  {8Dh}'Interpr‚teur BASIC',
  {8Eh}'Interpr‚teur BASIC',
  {8Fh}'Interpr‚teur BASIC',
  {90h}'Interpr‚teur BASIC',
  {91h}'Interpr‚teur BASIC',
  {92h}'Interpr‚teur BASIC',
  {93h}'Interpr‚teur BASIC',
  {94h}'Interpr‚teur BASIC',
  {95h}'Interpr‚teur BASIC',
  {96h}'Interpr‚teur BASIC',
  {97h}'Interpr‚teur BASIC',
  {98h}'Interpr‚teur BASIC',
  {99h}'Interpr‚teur BASIC',
  {9Ah}'Interpr‚teur BASIC',
  {9Bh}'Interpr‚teur BASIC',
  {9Ch}'Interpr‚teur BASIC',
  {9Dh}'Interpr‚teur BASIC',
  {9Eh}'Interpr‚teur BASIC',
  {9Fh}'Interpr‚teur BASIC',
  {A0h}'Interpr‚teur BASIC',
  {A1h}'Interpr‚teur BASIC',
  {A2h}'Interpr‚teur BASIC',
  {A3h}'Interpr‚teur BASIC',
  {A4h}'Interpr‚teur BASIC',
  {A5h}'Interpr‚teur BASIC',
  {A6h}'Interpr‚teur BASIC',
  {A7h}'Interpr‚teur BASIC',
  {A8h}'Interpr‚teur BASIC',
  {A9h}'Interpr‚teur BASIC',
  {AAh}'Interpr‚teur BASIC',
  {ABh}'Interpr‚teur BASIC',
  {ACh}'Interpr‚teur BASIC',
  {ADh}'Interpr‚teur BASIC',
  {AEh}'Interpr‚teur BASIC',
  {AFh}'Interpr‚teur BASIC',
  {B0h}'Interpr‚teur BASIC',
  {B1h}'Interpr‚teur BASIC',
  {B2h}'Interpr‚teur BASIC',
  {B3h}'Interpr‚teur BASIC',
  {B4h}'Interpr‚teur BASIC',
  {B5h}'Interpr‚teur BASIC',
  {B6h}'Interpr‚teur BASIC',
  {B7h}'Interpr‚teur BASIC',
  {B8h}'Interpr‚teur BASIC',
  {B9h}'Interpr‚teur BASIC',
  {BAh}'Interpr‚teur BASIC',
  {BBh}'Interpr‚teur BASIC',
  {BCh}'Interpr‚teur BASIC',
  {BDh}'Interpr‚teur BASIC',
  {BEh}'Interpr‚teur BASIC',
  {BFh}'Interpr‚teur BASIC',
  {C0h}'Interpr‚teur BASIC',
  {C1h}'Interpr‚teur BASIC',
  {C2h}'Interpr‚teur BASIC',
  {C3h}'Interpr‚teur BASIC',
  {C4h}'Interpr‚teur BASIC',
  {C5h}'Interpr‚teur BASIC',
  {C6h}'Interpr‚teur BASIC',
  {C7h}'Interpr‚teur BASIC',
  {C8h}'Interpr‚teur BASIC',
  {C9h}'Interpr‚teur BASIC',
  {CAh}'Interpr‚teur BASIC',
  {CBh}'Interpr‚teur BASIC',
  {CCh}'Interpr‚teur BASIC',
  {CDh}'Interpr‚teur BASIC',
  {CEh}'Interpr‚teur BASIC',
  {CFh}'Interpr‚teur BASIC',
  {D0h}'Interpr‚teur BASIC',
  {D1h}'Interpr‚teur BASIC',
  {D2h}'Interpr‚teur BASIC',
  {D3h}'Interpr‚teur BASIC',
  {D4h}'Interpr‚teur BASIC',
  {D5h}'Interpr‚teur BASIC',
  {D6h}'Interpr‚teur BASIC',
  {D7h}'Interpr‚teur BASIC',
  {D8h}'Interpr‚teur BASIC',
  {D9h}'Interpr‚teur BASIC',
  {DAh}'Interpr‚teur BASIC',
  {DBh}'Interpr‚teur BASIC',
  {DCh}'Interpr‚teur BASIC',
  {DDh}'Interpr‚teur BASIC',
  {DEh}'Interpr‚teur BASIC',
  {DFh}'Interpr‚teur BASIC',
  {E0h}'Interpr‚teur BASIC',
  {E1h}'Interpr‚teur BASIC',
  {E2h}'Interpr‚teur BASIC',
  {E3h}'Interpr‚teur BASIC',
  {E4h}'Interpr‚teur BASIC',
  {E5h}'Interpr‚teur BASIC',
  {E6h}'Interpr‚teur BASIC',
  {E7h}'Interpr‚teur BASIC',
  {E8h}'Interpr‚teur BASIC',
  {E9h}'Interpr‚teur BASIC',
  {EAh}'Interpr‚teur BASIC',
  {EBh}'Interpr‚teur BASIC',
  {ECh}'Interpr‚teur BASIC',
  {EDh}'Interpr‚teur BASIC',
  {EEh}'Interpr‚teur BASIC',
  {EFh}'Interpr‚teur BASIC',
  {F0h}'Interpr‚teur BASIC',
  {F1h}'Interpr‚teur BASIC',
  {F2h}'Interpr‚teur BASIC',
  {F3h}'Interpr‚teur BASIC',
  {F4h}'Interpr‚teur BASIC',
  {F5h}'Interpr‚teur BASIC',
  {F6h}'Interpr‚teur BASIC',
  {F7h}'Interpr‚teur BASIC',
  {F8h}'Interpr‚teur BASIC',
  {F9h}'Interpr‚teur BASIC',
  {FAh}'Interpr‚teur BASIC',
  {FBh}'Interpr‚teur BASIC',
  {FCh}'Interpr‚teur BASIC',
  {FDh}'Interpr‚teur BASIC',
  {FEh}'Interpr‚teur BASIC',
  {FFh}'Interpr‚teur BASIC'
 );

Var
 I:Integer;
 Terminated:Boolean;
 MinIntr,MaxIntr:Integer;

{$IFNDEF FPC}
 Procedure CursorOff;
 Var
  Regs:Registers;
 Begin
  Regs.AH:=1;
  Regs.CH:=32;
  Regs.CL:=0;
  Intr($10,Regs);
 End;

 Procedure CursorOn;
 Var
  Regs:Registers;
 Begin
  Regs.AX:=$0100;
  Regs.CX:=(7 shl 8)+9;
  Intr($10,Regs);
 End;
{$ENDIF}


Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

Procedure ShowItem(Y,P:Byte);
Var
 Vect:Pointer;
 VectPtr:Record
  _Ofs,_Seg:Byte;
 End Absolute Vect;
Begin
 TextBackground(Blue);
 TextColor(White);
 GotoXY(1,Y+3);
 ClrEol;
 GetIntVec(P,Vect);
 Write(HexWord2Str(P),' ':4,HexWord2Str(VectPtr._Ofs),':',
                            HexWord2Str(VectPtr._Seg),' ':5,
                            Copy(StrPas(VectStr[P]),1,58));
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('SHOWVECT : Cette commande permet d''afficher les adresses des ',
           'vecteurs d''interruptions d''un microprocesseur 8086/8088.');
  WriteLn;
  WriteLn('Syntaxe : SHOWVECT');
 End
  Else
 Begin
  {$IFDEF FPC}
   {$IFDEF WINDOWS}
     SetUseACP(False);
   {$ENDIF}
  {$ENDIF}
  TextMode(CO80);
  TextBackground(LightGray);
  TextColor(Black);
  CursorOff;
  GotoXY(1,1);
  ClrEol;
  GotoXY(12,1);
  Write('Show-Vectors, Version 1.0');
  GotoXY(1,2);
  TextBackground(Red);
  TextColor(Yellow);
  ClrEol;
  Write(' ','Int',' ','Adresse vecteur','  ','Description');
  For I:=0 to 21 do ShowItem(I,I);
  GotoXY(1,25);
  TextBackground(Cyan);
  TextColor(Black);
  ClrEol;
  Write(' <',#24,'> <',#25,'> <PgUp> <PgDn> <Home> <End>    <Esc>=Sortir');
  GotoXY(1,3);
  Terminated:=False;
  MinIntr:=0;
  MaxIntr:=22;
  Repeat
   Case ReadKey of
    #0:Case ReadKey of
     #71:Begin { Home }
      MinIntr:=0;
      MaxIntr:=22;
      For I:=0 to 21 do ShowItem(I,I);
     End;
     #72:If MinIntr>0Then Begin { Haut }
      Dec(MinIntr);
      Dec(MaxIntr);
      Window(1,3,80,24);
      GotoXY(1,1);
      InsLine;
      Window(1,1,80,25);
      ShowItem(0,MinIntr);
     End;
     #73:Begin { PgUp }
      If(MinIntr>22)Then Begin
       Dec(MinIntr,22);
       Dec(MaxIntr,22);
      End
       Else
      Begin
       MinIntr:=0;
       MaxIntr:=22;
      End;
      For I:=0 to 21 do ShowItem(I,MinIntr+I);
     End;
     #79:Begin { End }
      MinIntr:=234;
      MaxIntr:=255;
      For I:=0 to 21 do ShowItem(I,MinIntr+I);
     End;
     #80:If MaxIntr<255 Then Begin { Bas }
      Inc(MinIntr);
      Inc(MaxIntr);
      Window(1,3,80,24);
      GotoXY(1,1);
      DelLine;
      Window(1,1,80,25);
       ShowItem(21,MaxIntr);
     End;
     #81:Begin { PgDn }
     If(MaxIntr<234)Then Begin
       Inc(MinIntr,22);
       Inc(MaxIntr,22);
      End
       Else
      Begin
       MinIntr:=234;
       MaxIntr:=255;
      End;
      For I:=0 to 21 do ShowItem(I,MinIntr+I);
     End;
    End;
    #27:Terminated:=True;
   End;
  Until Terminated;
  Window(1,1,80,25);
  TextBackground(Black);
  TextColor(LightGray);
  ClrScr;
  CursorOn;
 End;
END.