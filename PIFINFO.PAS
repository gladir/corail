{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program ReadPIF;

{$A-}

Type
 TPIFHDR=Record
  Reserved0:Byte;
  CheckSum:Byte;
  Title:Array[0..29] of Char;
  DosMaxS:Word;
  DosMinS:Word;
  PgmName:Array[0..62] of Char;
  Flags1:Byte;
  Reserved1:Byte;
  StartupDir:Array[0..63] of Char;
  CmdLineS:Array[0..63] of Char;
  ScreenType:Byte;
  ScreenPages:Byte;
  IntVecLow:Byte;
  IntVecHigh:Byte;
  ScrnRows:Byte;
  ScrnCols:Byte;
  RowOffs:Byte;
  ColOffs:Byte;
  SystemMem:Word;
  SharedProg:Array[0..63] of Char;
  SharedData:Array[0..63] of Char;
  Flags2:Byte;
  SystemFlags:Byte;
 End;

Var
 PIFHeader:TPIFHDR;
 F:File;
 FileName:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('PIFINFO : Cette commande permet d''afficher les informations ',
          'd''entàte d''un fichier PIF de Windows 1.x et 2.x.');
  WriteLn;
  WriteLn('Syntaxe : PIFINFO fichier.pif');
  WriteLn;
  WriteLn(' fichier.pif   Ce paramätre permet d''indiquer le nom du fichier .PIF.');
 End
  Else
 If ParamCount>0Then Begin
  FileName:=ParamStr(1);
  Assign(F,FileName);
  {$I-} Reset(F,1); {$I+}
  If IOResult<>0 Then Begin
   WriteLn('Erreur: Impossible d''ouvrir le fichier.');
   Halt(1);
  End;
  BlockRead(F, PIFHeader, SizeOf(TPIFHDR));
  Close(F);
  WriteLn('Titre du programme : ', PIFHeader.Title);
  WriteLn('Nom du programme : ', PIFHeader.PgmName);
  WriteLn('RÇpertoire de dÇmarrage : ', PIFHeader.StartupDir);
  WriteLn('Ligne de commande : ', PIFHeader.CmdLineS);
  WriteLn('MÇmoire systäme requise : ', PIFHeader.SystemMem, ' Ko');
  Write('Type d''Çcran : ');
  Case PIFHeader.ScreenType of
   $00,$01:WriteLn('RÇservÇ');
   $02:WriteLn('Mode texte noir et blanc 80x25');
   $03:WriteLn('Mode texte couleur 80x25');
   $04:WriteLn('Mode graphique couleur 320x200 pixels');
   $05:WriteLn('Mode graphique noir et blanc 320x200 pixels');
   $06:WriteLn('Mode graphique noir et blanc 640x200 pixels');
   $07:WriteLn('Mode texte monochrome 80x25');
   $7E:WriteLn('Programme DOS par dÇfault');
   $7F:WriteLn('Programme par dÇfaut de TopView');
   Else WriteLn('Inconnu : ',PIFHeader.ScreenType);
  End;
  WriteLn('Nombre de pages Çcran : ', PIFHeader.ScreenPages);
  WriteLn('Drapeaux 1 : ', PIFHeader.Flags1);
  WriteLn('Drapeaux 2 : ', PIFHeader.Flags2);
  Write('Drapeaux systämes : ');
  If PIFHeader.SystemFlags and $20=$20Then Begin
   Write('êchange les vecteurs d''interruptions ');
  End;
  If PIFHeader.SystemFlags and $40=$40Then Begin
   Write('Utilise des paramätres ');
  End;
  If PIFHeader.SystemFlags and $9F<>0 Then Begin
   Write('Inconnu : ',PIFHeader.SystemFlags);
  End;
  WriteLn;
 End;
END.