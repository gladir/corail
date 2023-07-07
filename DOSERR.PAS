{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal, Turbo Pascal 7)
}

Program DOSERR;

Const
 ErrorMsgList:Array[1..113]of String[120]=(
  {1}'Cette erreur permet d''indiquer que le num‚ro de la fonction n''est pas valide',
  {2}'Cette erreur permet d''indiquer que le fichier est introuvable.',
  {3}'Cette erreur permet d''indiquer que le chemin est introuvable',
  {4}'Cette erreur permet d''indiquer qu''il y a trop de fichiers ouverts simultan‚ment',
  {5}'Cette erreur permet d''indiquer que l''accŠs est refus‚',
  {6}'Cette erreur permet d''indiquer que le descripteur de fichier est inconnu',
  {7}'Cette erreur permet d''indiquer que le bloc de contr“le de la m‚moire d‚truit',
  {8}'Cette erreur permet d''indiquer que la m‚moire disponible est insuffisante',
  {9}'Cette erreur permet d''indiquer que l''adresse de m‚moire est incorrecte',
  {10}'Cette erreur permet d''indiquer que l''environnement est incorrecte',
  {11}'Cette erreur permet d''indiquer le format est invalide.',
  {12}'Cette erreur permet d''indiquer que le code d''accŠs est incorrecte.',
  {13}'Cette erreur permet d''indiquer que les donn‚es sont incorrectes.',
  {14}'',
  {15}'Cette erreur permet d''indiquer que le lecteur (unit‚) est inconnu.',
  {16}'Cette erreur permet d''indiquer qu''une tentative de destruction du r‚pertoire courant a tent‚ d''ˆtre effectu‚.',
  {17}'Cette erreur permet d''indiquer que les p‚riph‚riques sont diff‚rentes.',
  {18}'Cette erreur permet d''indiquer qu''il n''y a plus d''autres fichiers dans la liste.',
  {19}'Cette erreur permet d''indiquer que le support est prot‚g‚ contre l''‚criture.',
  {20}'Cette erreur permet d''indiquer que le p‚riph‚rique est inconnu.',
  {21}'Cette erreur permet d''indiquer que le p‚riph‚rique n''est pas prˆt.',
  {22}'Cette erreur permet d''indiquer que l''instruction est inconnue.',
  {23}'Cette erreur permet d''indiquer qu''une erreur au niveau du CRC a ‚t‚ d‚tect‚.',
  {24}'Cette erreur permet d''indiquer que la largeur de donn‚es sont incorrecte.',
  {25}'Cette erreur permet d''indiquer que la recherche est infructueuse.',
  {26}'Cette erreur permet d''indiquer que le type de p‚riph‚rique est inconnu.',
  {27}'Cette erreur permet d''indiquer que le secteur est introuvable.',
  {28}'Cette erreur permet d''indiquer que l''imprimante n''a plus de papier.',
  {29}'Cette erreur permet d''indiquer qu''une erreur a eu lieu au niveau de l''‚criture.',
  {30}'Cette erreur permet d''indiquer qu''une erreur a eu lieu au niveau de la lecture.',
  {31}'Cette erreur permet d''indiquer qu''il s''agit d''une erreur de classe g‚n‚rale.',
  {32}'Cette erreur permet d''indiquer qu''un problŠme a eu lieu au niveau du partage de ressource.',
  {33}'Cette erreur permet d''indiquer qu''une violation du verrouillage a eu lieu.',
  {34}'Cette erreur permet d''indiquer qu''un changement de disque invalide a ‚t‚ effectu‚.',
  {35}'Cette erreur permet d''indiquer que le FCB est non disponible.',
  {36}'Cette erreur permet d''indiquer que le d‚passement du tampon des ressources s''est produit.',
  {37}'Cette erreur permet d''indiquer que le code de page est invalide.',
  {38}'Cette erreur permet d''indiquer qu''il est impossible de compl‚ter l''op‚ration de fichier (manque d''entr‚e).',
  {39}'Cette erreur permet d''indiquer que l''espace disque est insuffisant.',
  {40}'',
  {41}'',
  {42}'',
  {43}'',
  {44}'',
  {45}'',
  {46}'',
  {47}'',
  {48}'',
  {49}'',
  {50}'Cette erreur permet d''indiquer que l''appel r‚seau n''est pas support‚.',
  {51}'Cette erreur permet d''indiquer que l''ordinateur … distance ne r‚pondant pas.',
  {52}'Cette erreur permet d''indiquer qu''il y a une duplication du nom dans le r‚seau.',
  {53}'Cette erreur permet d''indiquer que le nom du r‚seau est introuvable.',
  {54}'Cette erreur permet d''indiquer le r‚seau est occup‚.',
  {55}'Cette erreur permet d''indiquer que le p‚riph‚rique r‚seau inexistante.',
  {56}'Cette erreur permet d''indiquer que la commande BIOS r‚seau est trop grande.',
  {57}'Cette erreur permet d''indiquer que le mat‚rielle de l''adaptateur r‚seau cause des problŠmes.',
  {58}'Cette erreur permet d''indiquer que la r‚ponse du r‚seau n''est pas valide.',
  {59}'Cette erreur permet d''indiquer des problŠmes inattendue de la part du r‚seau.',
  {60}'Cette erreur permet d''indiquer que l''adaptateur est incompatible.',
  {61}'Cette erreur permet d''indiquer que la queue d''impression est pleine.',
  {62}'Cette erreur permet d''indiquer que la queue d''impression est encore pleine.',
  {63}'Cette erreur permet d''indiquer que le fichier d''impression est effac‚.',
  {64}'Cette erreur permet d''indiquer que le nom de r‚seau est effac‚.',
  {65}'Cette erreur permet d''indiquer un accŠs refus‚.',
  {66}'Cette erreur permet d''indiquer que le type de p‚riph‚rique r‚seau est incorrecte.',
  {67}'Cette erreur permet d''indiquer le nom de r‚seau est introuvable.',
  {68}'Cette erreur permet d''indiquer que le nom de r‚seau est trop grand.',
  {69}'Cette erreur permet d''indiquer que la session de BIOS r‚seau est trop grand.',
  {70}'Cette erreur permet d''indiquer qu''il ne s''agit que d''un arrˆt temporaire.',
  {71}'Cette erreur permet d''indiquer qu''un appel r‚seau est introuvable.',
  {72}'Cette erreur permet d''indiquer que l''arrˆt a ‚t‚ provoquer au niveau de l''impression ou de la redirection.',
  {73}'Cette erreur permet d''indiquer que le logiciel r‚seau est non install‚ ou que la version r‚seau n''est pas valide.',
  {74}'Cette erreur permet d''indiquer que l''adaptateur est ferm‚ de fa‡on subite ou que l''estimation de temps est expir‚.',
  {75}'Cette erreur permet d''indiquer que le mot de passe est expir‚.',
  {76}'Cette erreur permet d''indiquer que la tentative de branchement est invalide en ce moment.',
  {77}'Cette erreur permet d''indiquer que l''excŠde de la limite disque a ‚t‚ signal‚ dans la station de travail.',
  {78}'Cette erreur permet d''indiquer qu''il n''y a pas de branchement dans la station de travail.',
  {79}'',
  {80}'Cette erreur permet de signaler que le fichier est d‚j… existant.',
  {81}'',
  {82}'Cette erreur permet d''indiquer qu''il est impossible de cr‚er un r‚pertoire.',
  {83}'Cette erreur permet d''indiquer qu''un problŠme … provoquer un Interruption 24h (Erreur critique).',
  {84}'Cette erreur permet d''indiquer que problŠme d''en dehors de la structure (trop de redirections) est rencontr‚.',
  {85}'Cette erreur permet d''indiquer une redirection dupliqu‚e.',
  {86}'Cette erreur permet d''indiquer qu''un mot de passe n''est pas valide.',
  {87}'Cette erreur permet d''indiquer que le paramŠtre n''est pas valide.',
  {88}'Cette erreur permet d''indiquer qu''une erreur d''‚criture sur un p‚riph‚rique r‚seau a eu lieu.',
  {89}'Cette erreur permet d''indiquer que la fonction n''est pas support‚ par le r‚seau.',
  {90}'Cette erreur permet d''indiquer que les composantes systŠmes requis ne sont pas install‚.',
  {91}'',
  {92}'',
  {93}'',
  {94}'',
  {95}'',
  {96}'',
  {97}'',
  {98}'',
  {99}'',
  {100}'Cette erreur permet d''indiquer qu''une erreur totalement inconnu s''est produite sur un CD-ROM.',
  {101}'Cette erreur permet d''indiquer que le p‚riph‚rique n''est pas prˆt.',
  {102}'Cette erreur permet d''indiquer que la m‚moire EMS n''est pas d''une longueur suffisante.',
  {103}'Cette erreur permet d''indiquer que le format CD-ROM n''est pas High Sierra ou ISO-9660.',
  {104}'Cette erreur permet d''indiquer que la porte du p‚riph‚rique n''est pas ouverte.',
  {105}'Cette erreur permet d''indiquer que le propri‚taire ne r‚agit plus.',
  {106}'Cette erreur permet d''indiquer le temps limite est exc‚d‚.',
  {107}'Cette erreur permet d''indiquer qu''un changement dans l''unit‚ B est requis.',
  {108}'Cette erreur permet que l''unit‚ est verrouill‚ par un autre processus.',
  {109}'Cette erreur permet d''indiquer l''arrˆter du canal.',
  {110}'Cette erreur permet d''indiquer que la cr‚ation ou l''ouvrir du canal a ‚chou‚.',
  {111}'Cette erreur permet d''indiquer un d‚bordement du tampon du canal.',
  {112}'Cette erreur permet d''indiquer que le disque est plein.',
  {113}'Cette erreur permet d''indiquer qu''il n''y a plus de descripteur de fichier disponible.'
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
   WriteLn('DOSERR   Cette commande permet d''afficher un code d''erreur DOS.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('DOSERR [/?] nombre [...]');
   WriteLn;
   WriteLn(' /?      Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn(' nombre  Ce parametre permet d''indiquer le num‚ro de l''erreur');
   Exit;
  End
   Else
  Begin
   Val(CurrParam,W,Err);
   If Err=0Then Begin
    If Not(W in [1..150])Then Begin
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



