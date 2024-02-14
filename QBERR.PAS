{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal 3.2, Turbo Pascal 7)
}

Program QBERR;

Const
 ErrorMsgList:Array[1..76]of String[150]=(
  {1}'Ce code d''erreur permet d''indiquer qu''une instruction NEXT '+
      'est rencontr‚ sans qu''une instruction FOR lui soit associ‚.',
  {2}'Ce code d''erreur permet d''indiquer une erreur dans la syntaxe '+
     'de l''instruction.',
  {3}'Ce code d''erreur permet d''indiquer qu''une instruction RETURN est '+
     'rencontr‚ sans qu''une instruction GOSUB lui soit associ‚.',
  {4}'Ce code d''erreur permet d''indiquer qu''il n''y a plus de donn‚es '+
     'de disponibles avec les instructions DATA.',
  {5}'Ce code d''erreur permet d''indiquer que l''appel de la '+
     'fonction n''est pas autoris‚.',
  {6}'Ce code d''erreur permet d''indiquer un d‚passement de la capacit‚.',
  {7}'Ce code d''erreur permet d''indiquer un manque de m‚moire de '+
     'disponible.',
  {8}'Ce code d''erreur permet d''indiquer qu''une ‚tiquette est ind‚fini.',
  {9}'Ce code d''erreur permet d''indiquer que la position de la cellule '+
      'est en dehors des limites du tableau.',
  {10}'Ce code d''erreur permet d''indiquer que la d‚finition est d‚j… '+
      'existante.',
  {11}'Ce code d''erreur permet d''indiquer une division par z‚ro.',
  {12}'Ce code d''erreur permet d''indiquer une instruction non autoris‚ '+
      'en mode direct.',
  {13}'Ce code d''erreur permet d''indiquer que le type de donn‚es ne '+
      'correspond pas.',
  {14}'Ce code d''erreur permet d''indiquer que l''espace allou‚ pour les '+
      'chaines de caractŠres a atteint sa limite.',
  {15}'',
  {16}'Ce code d''erreur permet d''indiquer que la formule de la chaine '+
      'de caractŠres est trop complexe.',
  {17}'Ce code d''erreur permet d''indiquer qu''il n''est pas possible de '+
      'poursuivre l''ex‚cution du programme.',
  {18}'Ce code d''erreur permet d''indiquer est fonction ind‚finie.',
  {19}'Ce code d''erreur permet d''indiquer que l''instruction RESUME est '+
      'attendue.',
  {20}'Ce code d''erreur permet d''indiquer que l''instruction RESUME n''a '+
      'pas rencontr‚ d''erreur.',
  {21}'',
  {22}'',
  {23}'',
  {24}'Ce code d''erreur permet d''indiquer que le d‚lai d''attente '+
      'pour un p‚riph‚rique a expir‚.',
  {25}'Ce code d''erreur permet d''indiquer que le p‚riph‚rique … un '+
      'problŠme mat‚riel.',
  {26}'Ce code d''erreur permet d''indiquer que l''instruction FOR ne '+
      'contient pas d''instruction NEXT indiquant sa fin.',
  {27}'Ce code d''erreur permet d''indiquer que du papier est attendu '+
      'dans l''imprimante.',
  {28}'',
  {29}'Ce code d''erreur permet d''indiquer que l''instruction WHILE '+
      'ne contient pas d''instruction WEND indiquant sa fin.',
  {30}'Ce code d''erreur permet d''indiquer que l''instruction WEND ne '+
      'contient pas d''instruction WHILE indiquant son commen‡ement.',
  {31}'',
  {32}'',
  {33}'Ce code d''erreur permet d''indiquer que l''‚tiquette sp‚cifi‚ '+
      'existe d‚j….',
  {34}'',
  {35}'Ce code d''erreur permet d''indiquer que le sous-programme '+
      'n''est pas d‚finit.',
  {36}'',
  {37}'Ce code d''erreur permet d''indiquer que le nombre de paramŠtres '+
      'ne correspond pas.',
  {38}'Ce code d''erreur permet d''indiquer un tableau ind‚fini.',
  {39}'',
  {40}'Ce code d''erreur permet d''indiquer qu''une variable est attendue.',
  {41}'',
  {42}'',
  {43}'',
  {44}'',
  {45}'',
  {46}'',
  {47}'',
  {48}'',
  {49}'',
  {50}'Ce code d''erreur permet d''indiquer qu''une d‚bordement de '+
      'champ avec l''instruction FIELD s''est produit.',
  {51}'',
  {52}'Ce code d''erreur permet d''indiquer que le num‚ro ou le nom de '+
       'fichier sp‚cifi‚ est incorrecte.',
  {53}'Ce code d''erreur permet d''indiquer que le fichier est introuvable.',
  {54}'Ce code d''erreur permet d''indiquer que le mode d''accŠs au '+
      'fichier n''est pas conforme.',
  {55}'Ce code d''erreur permet d''indiquer que le fichier sp‚cifi‚ est '+
       'd‚j… ouvert.',
  {56}'Ce code d''erreur permet d''indiquer que l''instruction FIELD est '+
       'd‚j… active.',
  {57}'Ce code d''erreur permet d''indiquer qu''une erreur au niveau des '+
       'entr‚es/sorties de fichier ou de p‚riph‚rique s''est produit.',
  {58}'Ce code d''erreur permet d''indiquer que le fichier existant d‚j….',
  {59}'Ce code d''erreur permet d''indiquer que la longueur de '+
       'l''enregistrement n''est pas autoris‚.',
  {60}'',
  {61}'Ce code d''erreur permet d''indiquer qu''il n''y a plus d''espace '+
       'de disponible sur le disque.',
  {62}'Ce code d''erreur permet d''indiquer qu''une entr‚e est effectu‚ '+
      'en dehors des limites possibles du fichier.',
  {63}'Ce code d''erreur permet d''indiquer que le num‚ro '+
      'd''enregistrement n''est pas correcte.',
  {64}'Ce code d''erreur permet d''indiquer que le nom de fichier n''est '+
      'pas correcte.',
  {65}'',
  {66}'',
  {67}'Ce code d''erreur permet d''indiquer qu''il y a trop de fichiers.',
  {68}'Ce code d''erreur permet d''indiquer que le p‚riph‚rique n''est '+
      'pas disponible actuellement.',
  {69}'Ce code d''erreur permet d''indiquer un d‚passement de la '+
      'capacit‚ d''une m‚moire tampon.',
  {70}'Ce code d''erreur permet d''indiquer un accŠs non autoris‚.',
  {71}'Ce code d''erreur permet d''indiquer que l''unit‚ de disque '+
       'n''est pas disponible en se moment.',
  {72}'Ce code d''erreur permet d''indiquer que l''unit‚ de disque est '+
       'd‚fectueux.',
  {73}'Ce code d''erreur permet d''indiquer que les informations de '+
       'caract‚ristiques ne sont pas disponibles.',
  {74}'Ce code d''erreur permet d''indiquer que l''instruction RENAME '+
       'n''est pas autoris‚ sur une unit‚ de disque diff‚rent.',
  {75}'Ce code d''erreur permet d''indiquer qu''une erreur dans le '+
      'chemin d''accŠs … un fichier.',
  {76}'Ce code d''erreur permet d''indiquer que le chemin d''accŠs … '+
       'un fichier est introuvable.'
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
   WriteLn('QBERR   Cette commande permet d''afficher un code d''erreur QuickBASIC ou QBasic.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('QBERR [/?] nombre [...]');
   WriteLn;
   WriteLn(' /?      Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn(' nombre  Ce parametre permet d''indiquer le num‚ro de l''erreur');
   Exit;
  End
   Else
  Begin
   Val(CurrParam,W,Err);
   If Err=0Then Begin
    If Not(W in [1..76])Then Begin
     WriteLn('Le nombre ',W,' est en dehors de l''intervalle');
    End
     Else
    Begin
     WriteLn(W,' - ',ErrorMsgList[W]);
    End;
   End;
  End;
  If P>255Then Break;
 Until CurrParam='';
END.


