{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal 3.2, Turbo Pascal 7)
}

Program QPERR;

Const
 ErrorMsgList:Array[1..162]of String[150]=(
  {0001}'Cette erreur indique que la m‚moire est insuffisante pour '+
        'permettre le fonctionnement du compilateur.',
  {0002}'Cette erreur indique que le fichier sp‚cifi‚ est introuvable.',
  {0003}'Cette erreur indique que le fichier est trop gros. En '+
        'QuickPascal 1.0 un fichier de code source Pascal ne peut '+
        'd‚passer 64 Ko.',
  {0004}'Cette erreur indique qu''il y a trop de fichier imbriqu‚s les '+
        'uns dans les autres. Le QuickPascal 1.0 supporte un maximum '+
        'de 5 fichiers source peuvent ˆtre imbriqu‚s.',
  {0005}'Cette erreur indique qu''il est impossible de lire le fichier.',
  {0006}'Cette erreur indique qu''il est impossible de fermer le fichier.',
  {0007}'Cette erreur indique qu''il est impossible de se positionner '+
         'dans le fichier.',
  {0008}'Cette erreur indique que la fin d''une ligne est attendue. '+
        'Vous avez oubli‚ de fermer la chaŒne de caractŠres.',
  {0009}'Cette erreur indique que les caractŠres que vous utilisez '+
        'pour l''identificateur ne sont pas autoris‚ par le compilateur.',
  {0010}'Cette erreur indique que les lignes ne peuvent d‚passer la '+
         'longueur de 126 caractŠres.',
  {0011}'Cette erreur indique qu''une constante de type entier a '+
        '‚t‚ ‚crite d''une fa‡on erron‚e ou que vous d‚passez les '+
        'limites du type entier sp‚cifi‚.',
  {0012}'Cette erreur indique qu''une erreur a ‚t‚ trouv‚ dans la '+
        'constante de caractŠres.',
  {0013}'Cette erreur indique que la chaŒne de caractŠres est plus '+
        'longue que la ligne.',
  {0014}'Cette erreur indique que la fin de fichier de code source '+
         'n''a pas ‚t‚ trouv‚.',
  {0015}'Cette erreur indique que la directive de compilation est '+
        'incorrecte.',
  {0016}'Cette erreur indique que la fin du fichier de code source '+
        'est attendu.',
  {0017}'Cette erreur indique qu''un identificateur est attendu.',
  {0018}'Cette erreur indique que le symbole ";" est attendu.',
  {0019}'Cette erreur indique que le symbole ")" est attendu.',
  {0020}'Cette erreur indique que le symbole "." est attendu.',
  {0021}'Cette erreur indique que le mot r‚serv‚ ®BEGIN¯ est attendu.',
  {0022}'Cette erreur indique que le mot r‚serv‚ ®END¯ est attendu.',
  {0023}'Cette erreur indique que l''‚tiquette en dehors des limites '+
        'permise ‚tant de 0 … 9999.',
  {0024}'Cette erreur indique que l''‚tiquette a d‚j… ‚t‚ d‚finie.',
  {0025}'Cette erreur indique que l''identificateur ou l''‚tiquette a '+
        'd‚j… ‚t‚ d‚finie.',
  {0026}'Cette erreur indique qu''il existe une erreur dans la '+
        'd‚finition du type.',
  {0027}'Cette erreur indique que ce type n''est pas permis … cet '+
        'endroit.',
  {0028}'Cette erreur indique que le mot r‚serv‚ ®OF¯ est attendu.',
  {0029}'Cette erreur indique qu''une restriction s''applique … '+
         'l''impl‚mentation et que vous ne l''avez pas respect‚.',
  {0030}'Cette erreur indique que le symbole "[" est attendu.',
  {0031}'Cette erreur indique que le symbole "]" est attendu.',
  {0032}'Cette erreur indique que l''identificateur n''est pas reconnu.',
  {0033}'Cette erreur indique qu''une erreur se trouve dans le type '+
        'de d‚finition simple.',
  {0034}'Cette erreur indique que le compilateur s''attend … trouver '+
        'un identificateur de type.',
  {0035}'Cette erreur indique que le symbole "=" est attendu.',
  {0036}'Cette erreur indique que le compilateur s''attend … trouver '+
        'une constante.',
  {0037}'Cette erreur indique que le compilateur s''attend … trouver '+
        'une constante de type r‚el ou entier.',
  {0038}'Cette erreur indique que le compilateur attend une base.',
  {0039}'Cette erreur indique que la limite du tableau doit ˆtre un '+
         'scalaire.',
  {0040}'Cette erreur indique que les types de rang du tableau sont '+
         'incompatibles.',
  {0041}'Cette erreur indique que la limite du tableau inf‚rieur … '+
         'valeur sup‚rieur … la limite sup‚rieur du tableau.',
  {0042}'Cette erreur indique que le symbole ":" est attendu.',
  {0043}'Cette erreur indique que la r‚f‚rence d‚finit pr‚alablement '+
         'par un ®FORWARD¯ ne correspond pas … la d‚finition rencontr‚.',
  {0044}'Cette erreur indique que le compilateur s''attend … trouver '+
         'une constante de type entier.',
  {0045}'Cette erreur indique que la longueur de la chaŒne de '+
         'caractŠres excŠde la limite autoris‚ par le compilateur.',
  {0046}'Cette erreur indique que le type de balise du champs doit '+
         'ˆtre un scalaire ou un rang.',
  {0047}'Cette erreur indique que le symbole "(" est attendu.',
  {0048}'Cette erreur indique qu''il y a trop de litt‚rales.',
  {0049}'Cette erreur indique que la structure est trop grosse.',
  {0050}'Cette erreur indique qu''une erreur se trouve dans '+
        'l''expression.',
  {0051}'Cette erreur indique qu''un conflit se trouve dans '+
        'l''op‚rande.',
  {0052}'Cette erreur indique que l''op‚rande de droite ne fait pas '+
        'partie de l''ensemble.',
  {0053}'Cette erreur indique que l''identificateur n''est pas valide.',
  {0054}'Cette erreur indique que le format du type ne correspond pas.',
  {0055}'Cette erreur indique qu''il est impossible de cr‚er le fichier.',
  {0056}'Cette erreur indique qu''il est impossible d''‚crire dans '+
        'le fichier.',
  {0057}'Cette erreur indique que la variable doit ˆtre un pointeur.',
  {0058}'Cette erreur indique que la variable doit ˆtre un '+
        'enregistrement.',
  {0059}'Cette erreur indique que la variable doit ˆtre une chaŒne '+
        'de caractŠres ou un tableau.',
  {0060}'Cette erreur indique qu''il n''y a pas de champs se trouvant '+
        'dans cette objet ou cette enregistrement.',
  {0061}'Cette erreur indique que le type d''index est incompatible '+
         'avec la d‚claration.',
  {0062}'Cette erreur indique que la routine est trop grosse.',
  {0063}'Cette erreur indique que le mot r‚serv‚ ®UNTIL¯ est attendu.',
  {0064}'Cette erreur indique qu''une expression de type bool‚en est '+
        'attendu.',
  {0065}'Cette erreur indique que le mot r‚serv‚ ®DO¯ est attendu.',
  {0066}'Cette erreur indique que le mot r‚serv‚ ®THEN¯ est attendu.',
  {0067}'Cette erreur indique que l''‚tiquette est invalide.',
  {0068}'Cette erreur indique que l''‚tiquette est inconnue.',
  {0069}'Cette erreur indique que l''‚tiquette n''est pas dans le '+
        'bloc courant.',
  {0070}'Cette erreur indique que l''‚tiquette est d‚j… d‚finie.',
  {0071}'Cette erreur indique qu''une ‚tiquette est attendue.',
  {0072}'Cette erreur indique que l''‚tiquette est ind‚finie dans '+
        'la partie pr‚c‚dente.',
  {0073}'Cette erreur indique qu''une erreur se trouve dans '+
        'l''instruction.',
  {0074}'Cette erreur indique que le symbole ":=" est attendu.',
  {0075}'Cette erreur indique que la liaison entre les types ne '+
        'correspond pas.',
  {0076}'Cette erreur indique qu''un identificateur de variable '+
        'est attendu.',
  {0077}'Cette erreur indique que le mot r‚serv‚ ®FOR¯ est attendu.',
  {0078}'Cette erreur indique qu''un type scalaire est attendu.',
  {0079}'Cette erreur indique que les mots r‚serv‚s ®TO¯ ou '+
        '®DOWNTO¯ sont attendus.',
  {0080}'Cette erreur indique que le disque est plein.',
  {0081}'Cette erreur indique que la valeur de la constante est '+
        'en dehors des limites permises.',
  {0082}'Cette erreur indique que le symbole "," est attendu.',
  {0083}'Cette erreur indique qu''erreur de division par z‚ro a '+
        '‚t‚ rencontr‚.',
  {0084}'Cette erreur indique qu''il y a trop de routines local.',
  {0085}'Cette erreur indique qu''une expression de type entier '+
        'est attendu.',
  {0086}'Cette erreur indique que ce type de pointeur ne peut '+
        'pas ˆtre r‚f‚renc‚.',
  {0087}'Cette erreur indique qu''un pointeur typ‚ est attendu.',
  {0088}'Cette erreur indique qu''un type de fichier est attendu.',
  {0089}'Cette erreur indique que le compilateur est incapable '+
        'd''‚crire les expressions de ce type.',
  {0090}'Cette erreur indique qu''une expression ordinaire est attendu.',
  {0091}'Cette erreur indique que le type de fichier n''est pas valide.',
  {0092}'Cette erreur indique qu''un paramŠtre de variable est attendu.',
  {0093}'Cette erreur indique qu''il est impossible pour le compilateur '+
        'de lire les expressions de ce type.',
  {0094}'Cette erreur indique qu''une expression entiŠre ou r‚el est '+
        'attendu.',
  {0095}'Cette erreur indique qu''une expression entiŠre ou r‚el est '+
        'attendu.',
  {0096}'Cette erreur indique que la fonction ne peut pas ˆtre mont‚.',
  {0097}'Cette erreur indique qu''une erreur est rencontr‚ dans '+
        'l''instruction ®INLINE¯.',
  {0098}'Cette erreur indique qu''une ‚tiquette ne peut pas ˆtre employ‚ '+
        'dans la zone d''interface.',
  {0099}'Cette erreur indique que le mot r‚serv‚ ®INTERFACE¯ est attendu.',
  {0100}'Cette erreur indique que le mot r‚serv‚ ®IMPLEMENTATION¯ est '+
        'attendu.',
  {0101}'Cette erreur indique que le fichier d''unit‚ n''est pas valide.',
  {0102}'Cette erreur indique que le champs ou la m‚thode sont d‚j… '+
        'd‚fini.',
  {0103}'Cette erreur indique que le fichier de format QPU est invalide.',
  {0104}'Cette erreur indique qu''il y a une duplication du nom de '+
        'l''unit‚.',
  {0105}'Cette erreur indique qu''il y a une r‚f‚rence d''unit‚ '+
        'circulaire.',
  {0106}'Cette erreur indique qu''il y a une erreur au niveau de la '+
        'constante de type r‚el.',
  {0107}'Cette erreur indique qu''un coprocesseur est requis.',
  {0108}'Cette erreur indique qu''il y a trop de directive de '+
        'compilation.',
  {0109}'Cette erreur indique qu''une directive de compilation est '+
        'mal-plac‚.',
  {0110}'Cette erreur indique qu''une directive de compilation '+
         '®$ENDIF¯ est attendu.',
  {0111}'Cette erreur indique que trop de symbole de directive de '+
        'compilation sont pr‚sents.',
  {0112}'Cette erreur indique qu''une entˆte est incompatible avec '+
        'la pr‚d‚claration.',
  {0113}'Cette erreur indique que la qualification n''est pas autoris‚.',
  {0114}'Cette erreur indique qu''il y a trop de paramŠtre.',
  {0115}'Cette erreur indique que la classe doit ˆtre d‚finit au '+
        'niveau global.',
  {0116}'Cette erreur indique que la classe doit ˆtre d‚finit dans '+
         'une d‚finition de type.',
  {0117}'Cette erreur indique que la r‚f‚rence de fonction ou de '+
        'la proc‚dure est invalide.',
  {0118}'Cette erreur indique que la variable de proc‚dure ou de '+
        'fonction est attendu.',
  {0119}'Cette erreur indique que le type objet est attendu.',
  {0120}'Cette erreur indique que l''objet doit ˆtre d‚fini au niveau '+
        'global.',
  {0121}'Cette erreur indique que l''objet doit ˆtre d‚fini dans une '+
        'd‚finition de type.',
  {0122}'Cette erreur indique que le type de classe est invalide.',
  {0123}'Cette erreur indique que la table attribu‚ aux classe est '+
        'pleine.',
  {0124}'Cette erreur indique qu''une erreur de syntaxe est rencontr‚.',
  {0125}'Cette erreur indique que la m‚thode n''a pas de m‚thode parente.',
  {0126}'Cette erreur indique que le type d''expression doit ˆtre un '+
        'pointeur.',
  {0127}'Cette erreur indique que la variable contient une r‚f‚rence '+
        'non valide.',
  {0128}'Cette erreur indique que la table de symbole est pleine.',
  {0129}'Cette erreur indique que trop d''unit‚ ont ‚t‚ import‚.',
  {0130}'Cette erreur indique que le code machine ne peut exc‚d‚ la '+
        'limite de 64 Ko par segment.',
  {0131}'Cette erreur indique que l''op‚ration de type r‚el n''est '+
        'pas valide.',
  {0132}'Cette erreur indique qu''un d‚bordement de la limite '+
        'sup‚rieur de la valeur r‚el permise.',
  {0133}'Cette erreur indique qu''un d‚bordement de la limite '+
        'inf‚rieur de la valeur r‚el permise.',
  {0134}'Cette erreur indique que la d‚finition externe n''a pas '+
        '‚t‚ d‚fini.',
  {0135}'Cette erreur indique qu''il y a trop de noms de fichier '+
        'd''objet.',
  {0136}'Cette erreur indique que le fichier d''objet n''est pas '+
        'valide.',
  {0137}'Cette erreur indique que le fichier d''objet est trop grand.',
  {0138}'Cette erreur indique que la d‚finition de segment n''est pas '+
        'valide.',
  {0139}'Cette erreur indique que le nom de segment n''est pas valide.',
  {0140}'Cette erreur indique que le code machine contenu dans le '+
        'segment est trop large.',
  {0141}'Cette erreur indique que la d‚finition PUBLIC n''est pas '+
        'valide.',
  {0142}'Cette erreur indique que la d‚finition EXTRN n''est pas valide.',
  {0143}'Cette erreur indique qu''il y a trop de d‚finition externe.',
  {0144}'Cette erreur indique que le ®FIXUP¯ n''est pas valide.',
  {0145}'Cette erreur indique qu''il y a trop de fichier ouvert '+
        'simultan‚ment.',
  {0146}'Cette erreur indique qu''il y a trop de variables d‚fini.',
  {0147}'Cette erreur indique que la directive doit ˆtre au d‚but '+
        'du programme ou de l''unit‚.',
  {0148}'Cette erreur indique que l''assignation n''est pas valide.',
  {0149}'Cette erreur indique que le type de format ensemble est en '+
        'dehors des intervalles permises.',
  {0150}'Cette erreur indique que l''index est en dehors des '+
        'intervalles permises.',
  {0151}'Cette erreur indique que la variable objet est en attente '+
        'd''une fonction.',
  {0152}'Cette erreur indique que la type d''objet est en attente '+
        'd''une fonction.',
  {0153}'Cette erreur indique que l''expression est trop compliqu‚ '+
        'pour ˆtre r‚solu.',
  {0154}'Cette erreur indique que le nom d''unit‚ n''est pas valide.',
  {0155}'Cette erreur indique que la table des informations sur les '+
        'lignes est pleine.',
  {0156}'Cette erreur indique que la table des ®FIXUP¯ est pleine.',
  {0157}'Cette erreur indique que la table source est pleine.',
  {0158}'Cette erreur indique que le mot r‚serv‚ ®UNIT¯ est attendu.',
  {0159}'Cette erreur indique que la r‚f‚rence de nom pr‚c‚demment '+
        'sp‚cifi‚ par un ®FORWARD¯ n''est pas satisfaite.',
  {0160}'Cette erreur indique que les donn‚es d''enregistrement '+
        'r‚it‚r‚ dans le ®FIXUP¯ ne sont pas valide.',
  {0161}'Cette erreur indique que les fichiers d''inclusion ne '+
        'peuvent pas ˆtre joint … cette endroit.',
  {0162}'Cette erreur indique que la pile est pleine.'
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
   WriteLn('QPERR   Cette commande permet d''afficher un code d''erreur QuickPascal.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('QPERR [/?] nombre [...]');
   WriteLn;
   WriteLn(' /?      Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn(' nombre  Ce parametre permet d''indiquer le num‚ro de l''erreur');
   Exit;
  End
   Else
  Begin
   Val(CurrParam,W,Err);
   If Err=0Then Begin
    If Not(W in [1..162])Then Begin
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



