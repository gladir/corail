{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal, Turbo Pascal 7)
}

Program BERR;

Const
 ErrorMsgList:Array[1..100]of String[50]=(
  {1}'INVALID OPERATION',
  {2}'I/O ERROR',
  {3}'FILE NOT OPEN',
  {4}'KEY VALUE NOT FOUND',
  {5}'DUPLICATE KEY VALUE',
  {6}'INVALID KEY NUMBER',
  {7}'DIFFERENT KEY NUMBER',
  {8}'INVALID POSITIONING',
  {9}'END OF FILE',
  {10}'MODIFIABLE KEY VALUE ERROR',
  {11}'INVALID FILENAME',
  {12}'FILE NOT FOUND',
  {13}'EXTENDED FILE ERROR',
  {14}'PRE-IMAGE I/O ERROR',
  {15}'PRE-IMAGE I/O ERROR',
  {16}'EXPANSION ERROR',
  {17}'CLOSE ERROR',
  {18}'DISK FULL',
  {19}'UNRECOVERABLE ERROR',
  {20}'RECORD MANAGER INACTIVE',
  {21}'KEY BUFFER TOO SHORT',
  {22}'DATA BUFFER LENGTH',
  {23}'POSITION BLOCK LENGTH',
  {24}'PAGE SIZE ERROR',
  {25}'CREATE I/O ERROR',
  {26}'NUMBER OF KEYS',
  {27}'INVALID KEY POSITION',
  {28}'INVALID RECORD LENGTH',
  {29}'INVALID KEY LENGTH',
  {30}'NOT A BTRIEVE FILE',
  {31}'FILE ALREADY EXTENDED',
  {32}'EXTEND I/O ERROR',
  {33}'',
  {34}'INVALID EXTENSION NAME',
  {35}'DIRECTORY ERROR',
  {36}'TRANSACTION ERROR',
  {37}'TRANSACTION IS ACTIVE',
  {38}'TRANSACTION CONTROL FILE I/O ERROR',
  {39}'END/ABORT TRANSACTION ERROR',
  {40}'TRANSACTION MAX FILES',
  {41}'OPERATION NOT ALLOWED',
  {42}'INCOMPLETE ACCELERATED ACCESS',
  {43}'INVALID RECORD ADDRESS',
  {44}'NULL KEY PATH',
  {45}'INCONSISTENT KEY FLAGS',
  {46}'INVALID EXTENSION NAME',
  {47}'MAXIMUM OPEN FILES',
  {48}'INVALID ALTERNATE SEQUENCE DEFINITION',
  {49}'KEY TYPE ERROR',
  {50}'OWNER ALREADY SET',
  {51}'INVALID OWNER',
  {52}'ERROR WRITING CACHE',
  {53}'INVALID INTERFACE',
  {54}'VARIABLE PAGE ERROR',
  {55}'AUTOINCREMENT ERROR',
  {56}'INCOMPLETE INDEX',
  {57}'',
  {58}'COMPRESSION BUFFER TOO SHORT',
  {59}'FILE ALREADY EXISTS',
  {60}'REJECT COUNT REACHED',
  {61}'WORK SPACE TOO SMALL',
  {62}'INCORRECT DESCRIPTOR',
  {63}'INVALID EXTENDED INSERT BUFFER',
  {64}'FILTER LIMIT REACHED',
  {65}'INCORRECT FIELD OFFSET',
  {66}'',
  {67}'',
  {68}'',
  {69}'',
  {70}'',
  {71}'',
  {72}'',
  {73}'',
  {74}'AUTOMATIC TRANSACTION ABORT',
  {75}'',
  {76}'',
  {77}'',
  {78}'DEADLOCK DETECTED',
  {79}'PROGRAMMING ERROR',
  {80}'CONFLICT',
  {81}'LOCK ERROR',
  {82}'LOST POSITION',
  {83}'INVALID EXTENSION NAME',
  {84}'RECORD LOCKED',
  {85}'FILE LOCKED',
  {86}'FILE TABLE FULL',
  {87}'HANDLE TABLE FULL',
  {88}'INCOMPATIBLE MODE ERROR',
  {89}'',
  {90}'AUTOMATIC TRANSACTION ABORT',
  {91}'SERVER ERROR',
  {92}'TRANSACTION TABLE FULL',
  {93}'INCOMPATIBLE LOCK TYPE',
  {94}'PERMISSION ERROR',
  {95}'SESSION NO LONGER VALID',
  {96}'COMMUNICATIONS ENVIRONMENT ERROR',
  {97}'DATA MESSAGE TOO SMALL',
  {98}'AUTOMATIC TRANSACTION ABORT',
  {99}'',
  {100}''
 );

 ErrorDescList:Array[1..100]of String[80]=(
  {1}'Op‚ration invalide',
  {2}'Erreur d''entr‚e/sortie',
  {3}'Le fichier n''est pas ouvert',
  {4}'Clef ou valeur introuvable',
  {5}'Duplication de clef ou de valeur',
  {6}'Num‚ro de clef invalide',
  {7}'Num‚ro de clef diff‚rent',
  {8}'Positionnement invalide',
  {9}'Fin de fichier attendue',
  {10}'Erreur de clef et de valeur modifiable',
  {11}'Nom de fichier invalide',
  {12}'Fichier introuvable',
  {13}'Erreur de fichier ‚tendue',
  {14}'Erreur de pr‚-image d''entr‚e/sortie',
  {15}'Erreur de pr‚-image d''entr‚e/sortie',
  {16}'Erreur ‚tendue',
  {17}'Erreur de fermeture',
  {18}'Disque plein',
  {19}'Erreur irr‚cup‚rable',
  {20}'Gestion d''enregistrement inactif',
  {21}'Clef de tampon trop courte',
  {22}'ProblŠme de longueur du tampon de donn‚es',
  {23}'ProblŠme de longueur de position de bloc',
  {24}'Erreur de taille de page',
  {25}'Erreur de cr‚ation d''entr‚e/sortie',
  {26}'Num‚ro de clefs',
  {27}'Position de clef invalide',
  {28}'Longueur d''enregistrement invalide',
  {29}'Longueur de clef invalide',
  {30}'Il ne s''agit pas d''un fichier Btrieve',
  {31}'Fichier d‚j… ‚tendue',
  {32}'Erreur ‚tendue d''entr‚e/sortie',
  {33}'',
  {34}'Nom d''extension invalide',
  {35}'Erreur de r‚pertoire',
  {36}'Erreur de transaction',
  {37}'La transaction est active',
  {38}'Erreur d''entr‚e/sortie de fichier dans le contr“le de transaction',
  {39}'Erreur de fin/d''annulation de transaction',
  {40}'Fichier maximal de transaction',
  {41}'Op‚ration non permise',
  {42}'AccŠs d''acc‚l‚ration incomplŠte',
  {43}'Adresse d''enregistrement invalide',
  {44}'Chemin de clef nulle',
  {45}'Drapeaux de clefs inconsistent',
  {46}'Nom d''extension invalide',
  {47}'Fichiers ouvert maximum',
  {48}'D‚finition de s‚quence alternative invalide',
  {49}'Erreur de type de clef',
  {50}'Ensemble de propri‚taire d‚j… existant',
  {51}'Propri‚taire invalide',
  {52}'Erreur de cache d''‚criture',
  {53}'Interface invalide',
  {54}'Erreur de page variable',
  {55}'Erreur d''autoincr‚mentation',
  {56}'Index incomplŠte',
  {57}'',
  {58}'Tampon de compression trop court',
  {59}'Fichier d‚j… existant',
  {60}'Nombre de rejet atteint',
  {61}'Espace de travail trop petit',
  {62}'Descripteur incorrecte',
  {63}'Tampon d''insertion ‚tendu non valide',
  {64}'Limite de filtre atteinte',
  {65}'D‚placement de champ incorrecte',
  {66}'',
  {67}'',
  {68}'',
  {69}'',
  {70}'',
  {71}'',
  {72}'',
  {73}'',
  {74}'Transaction automatique annul‚',
  {75}'',
  {76}'',
  {77}'',
  {78}'Interblocage d‚tect‚',
  {79}'Erreur de programmation',
  {80}'Conflit',
  {81}'Erreur de verroue',
  {82}'Position perdu',
  {83}'Nom d''extension invalide',
  {84}'Enregistrement verrouill‚',
  {85}'Fichier verrouill‚',
  {86}'Table de fichier pleine',
  {87}'Table de descripteur pleine',
  {88}'Erreur de mode incompatible',
  {89}'',
  {90}'Annulation de transaction automatique',
  {91}'Erreur de serveur',
  {92}'Table de transaction pleine',
  {93}'Type de verroue incompatible',
  {94}'Erreur de permission',
  {95}'La session n''est plus valide',
  {96}'Erreur de communications d''environnement',
  {97}'Donn‚es de message trop court',
  {98}'Annulation de transaction automatique',
  {99}'',
  {100}''
 );

Var
 P:Byte;
 Err,W:Word;
 CurrParam:String;

BEGIN
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ParamStr(P);
  If Length(CurrParam)=0Then Break;
  If CurrParam='/?'Then Begin
   WriteLn('BERR   Cette commande permet d''afficher un code d''erreur Btrieve.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('BERR [/?] nombre [...]');
   WriteLn;
   WriteLn(' /?      Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn(' nombre  Ce parametre permet d''indiquer le num‚ro de l''erreur');
   Exit;
  End
   Else
  Begin
   Val(CurrParam,W,Err);
   If Err=0Then Begin
    If Not(W in [1..100])Then Begin
     WriteLn('Le nombre ',W,' est en dehors de l''intervalle');
    End
     Else
    Begin
     WriteLn(W,' - ',ErrorMsgList[W]);
     WriteLn('  ',ErrorDescList[W]);
    End;
   End;
  End;
  If P>255Then Break;
 Until CurrParam='';
END.

