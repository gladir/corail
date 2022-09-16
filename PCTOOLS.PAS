{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program PCTOOLS;

Uses Crt,DOS,Strings;

Const
 Menu:Array[0..15]of PChar=(
  'DIRECTORY',
  'COPY',
  'COMPARE',
  'SEARCH',
  'RENAME',
  'DELETE',
  'VERIFY',
  'VIEW/EDIT',
  'UNDELETE',
  'STATUS',
  'MAPPING',
  'SYSTEM INFO.',
  'PRINT',
  'LOCATE',
  'FORMAT',
  'Sortir de PC Tools');

 MenuEnglish:Array[0..15]of PChar=(
  'DIRECTORY',
  'COPY',
  'COMPARE',
  'SEARCH',
  'RENAME',
  'DELETE',
  'VERIFY',
  'VIEW/EDIT',
  'UNDELETE',
  'STATUS',
  'MAPPING',
  'SYSTEM INFO.',
  'PRINT',
  'LOCATE',
  'FORMAT',
  'End PC Tools');

 Info:Array[0..15]of PChar=(
  'Affiche les informations du r‚pertoire et '+#13+#10+'‚ventuellement la liste des sous-r‚pertoires.',
  'Copie un fichier, des groupes de fichiers ou '+#13+#10+'un disque entier.',
  'Compare des fichiers ou les disques entiers.',
  'Recherche un fichier, un groupe de fichiers '+#13+#10+'ou un disque entier pour une chaŒne '+#13+#10+
    'de donn‚es correspondante.',
  'Renomme un fichier ou l''‚tiquette d''un Volume.',
  'Efface un fichier ou un groupe de fichiers',
  'V‚rifie que tous les secteurs sont lisibles '+#13+#10+'pour un fichier, un groupe de fichiers, ou un '+
     #13+'disque entier.',
  'Affiche et/ou modifie des donn‚es dans un'+#13+#10+'fichier ou n''importe o— sur le disque.',
  'Tente de r‚cup‚rer un fichier'+#13+#10+'supprim‚ et ses donn‚es.',
  'Affiche et ‚ventuellement modifie '+#13+#10+'l''‚tat du r‚pertoire des fichiers.',
  'Affiche les allocations de secteurs '+#13+#10+'dans un disque. Optionnellement, cartographie les fichiers.',
  'Affiche les informations d''aide '+#13+#10+'… propos du systŠme.',
  'Imprime des fichiers.',
  'Rercherche dans tous les r‚pertoires '+#13+#10+'pour le fichier sp‚cifi‚.',
  'Formate une disquette de donn‚es.',
  'Pour sortir du PC Tools'+#13+#10+'et retourner au DOS.'
 );

 InfoEnglish:Array[0..15]of PChar=(
  'Display directory information and '+#13+#10+'optionnally list sub-directories.',
  'Copy a file, groups of files or '+#13+#10+'an entire disk.',
  'Compare files or entire disks.',
  'Search a file, a group of files '+#13+#10+'or an entire disk for a matching'+#13+#10+
    'string of data',
  'Rename a file or the Volume Label.',
  'Delete a file or a group of files',
  'Verify that all sectors are readable '+#13+#10+'for a file, a group of files, or an '+
     #13+'entire disk',
  'View and/or modify data in a file '+#13+#10+'or anywhere on the disk.',
  'To attempt recovery of a deleted '+#13+#10+'file and its data.',
  'Display and optionnally modify '+#13+#10+'the directory status of files.',
  'Display the allocation of the sectors '+#13+#10+'on a disk. Optionally, map the files.',
  'Display helpful information '+#13+#10+'about your system.',
  'Print files.',
  'Search all directories '+#13+#10+'for specific files.',
  'Format a data diskette.',
  'To exit PC Tools'+#13+#10+'and return to DOS.'
 );

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 P:Byte;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function DuplicateString(C:Char;Num:Integer):String;
Var
 I:Byte;
 S:String;
Begin
 S:='';
 For I:=1 to Num do S:=S+C;
 DuplicateString:=S;
End;

Procedure ShowMenu;
Var
 J:Byte;
Begin
 TextBackground(Black);
 TextColor(7);
 ClrScr;
 GotoXY(36,2);
 TextBackground(Blue);
 Write('PC Tools');
 TextBackground(Black);
 Write(' R1.01');
 GotoxY(20,3);
 WriteLn('(C)Tous droits r‚serv‚s MIT 2022 Gladir.com');
 Write(DuplicateString(#196,80));
 For J:=Low(Menu)to High(Menu)do Begin
  GotoXY(1,6+J);
  If(Language=_English)Then Write(MenuEnglish[J])
                       Else Write(Menu[J]);
 End;
 TextBackground(Blue);
 Case Language of
  _English:Begin
   GotoXY(20,24);
   Write('Use the UP (',#24,') arrow and the DOWN (',#25,') arrow');
   GotoxY(24,25);
   Write('to select. Then press ENTER (',#17,#217,').');
  End;
  Else Begin
   GotoXY(20,24);
   Write('Utilis‚ la flŠche HAUT (',#24,') et la flŠche BAS (',#25,')');
   GotoxY(20,25);
   Write('pour s‚lectionner. Ensuite, enfonc‚ ENTER (',#17,#217,').');
  End;
 End;
 TextBackground(Black);
End;

Procedure Init;Begin
 P:=0;
 ShowMenu;
End;

Procedure SetItem;
Var
 I:Byte;
Begin
 TextBackground(LightRed);
 TextColor(Black{$IFDEF FPC}+BLINK{$ENDIF});
 GotoXY(1,6+P);
 If(Language=_English)Then Write(MenuEnglish[P])
                      Else Write(Menu[P]);
 TextBackground(Black);
 TextColor(7);
 If(Language=_English)Then Begin
  Write(#17,DuplicateString(#196,20-StrLen(MenuEnglish[P])));
 End
  Else
 Begin
  Write(#17,DuplicateString(#196,20-StrLen(Menu[P])));
 End;
 If P=0Then Write(#196,DuplicateString(#196,11))
  Else
 Begin
  Write(#217);
  For I:=1 to P-1 do Begin
   GotoXY(22,6+I);
   Write(#179);
  End;
  GotoXY(22,6);
  Write(#218,DuplicateString(#196,11));
 End;
 GotoXY(34,6);
 Write(#16);
 Window(35,6,80,20);
 ClrScr;
 GotoXY(1,1);
 Case Language of
  _English:Write(StrPas(InfoEnglish[P]));
  Else Write(StrPas(Info[P]));
 End;
 Window(1,1,80,25);
End;

Procedure UnsetItem;Begin
 TextBackground(Black);
 TextColor(7);
 GotoXY(1,6+P);
 Write(Menu[P]);
 ClrEol;
 Window(22,6,80,20);
 ClrScr;
 Window(1,1,80,25);
End;

Procedure Run;
Var
 K:Char;
Begin
 SetItem;
 Repeat
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #72:Begin { Up }
     UnsetItem;
     If P>0 Then Dec(P)
            Else P:=High(Menu);
     SetItem;
    End;
    #80:Begin { Down }
     UnsetItem;
     If P<High(Menu)Then Inc(P)
                    Else P:=Low(Menu);
     SetItem;
    End;
   End;
   #13:Case P of
    15:Exit;
   End;
  End;
 Until K=#27;
End;

Procedure Done;Begin
 TextBackground(Black);
 TextColor(7);
 ClrScr;
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 Init;
 Run;
 Done;
END.