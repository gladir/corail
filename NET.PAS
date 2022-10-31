{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program NET;

Uses DOS,Strings;

Const
 ErrorCode:Array[0..143]of PChar=(
  { 0x0 }   'L''op‚ration a r‚ussi.',
  { 0x1 }   'Fonction incorrecte.',
  { 0x2 }   'Fichier introuvable.',
  { 0x3 }   'Chemin d''accŠs introuvable.',
  { 0x4 }   'Le systŠme ne peut pas ouvrir le fichier.',
  { 0x5 }   'AccŠs refus‚.',
  { 0x6 }   'Le gestionnaire est invalide.',
  { 0x7 }   'Les blocs de contr“le d''entreposage ont ‚t‚ d‚truits.',
  { 0x8 }   'Il n''y a pas assez d''entreposage de disponible pour traiter cette commande.',
  { 0x9 }   'L''adresse du bloc de contr“le d''entreposage n''est pas valide.',
  { 0xA }   'L''environnement est incorrect.',
  { 0xB }   'Vous avez tent‚ de charger un programme avec un format incorrect.',
  { 0xC }   'Le code d''accŠs est invalide.',
  { 0xD }   'Les donn‚es sont invalides.',
  { 0xE }   'Il n''y a pas assez d''entreposage de disponible pour terminer cette op‚ration.',
  { 0xF }   'Le systŠme ne peut pas trouver l''unit‚ de disque sp‚cifi‚.',
  { 0x10 }  'Le r‚pertoire ne peut pas ˆtre supprim‚.',
  { 0x11 }  'Le systŠme ne peut pas d‚placer le fichier vers un autre unit‚ de disque.',
  { 0x12 }  'Il n''y a plus d''identificateur de fichiers disponibles.',
  { 0x13 }  'Le m‚dia est prot‚g‚ en ‚criture.',
  { 0x14 }  'Le systŠme ne trouve pas le p‚riph‚rique sp‚cifi‚.',
  { 0x15 }  'Le p‚riph‚rique n''est pas disponible.',
  { 0x16 }  'Le p‚riph‚rique ne reconnaŒt pas la commande.',
  { 0x17 }  'Une erreur de donn‚es (contr“le de redondance cyclique) s''est produite.',
  { 0x18 }  'Le programme a ‚mis une commande mais sa longueur est incorrecte.',
  { 0x19 }  'L''unit‚ de disque ne peut pas localiser une zone ou une piste sp‚cifique sur le disque.',
  { 0x1A }  'Il est impossible d''acc‚der au disque ou … la disquette sp‚cifi‚s.',
  { 0x1B }  'L''unit‚ de disque ne peut pas trouver le secteur demand‚.',
  { 0x1C }  'L''imprimante est … court de papier.',
  { 0x1D }  'Le systŠme ne peut pas ‚crire sur le p‚riph‚rique sp‚cifi‚.',
  { 0x1E }  'Le systŠme ne peut pas lire … partir du p‚riph‚rique sp‚cifi‚.',
  { 0x1F }  'Un p‚riph‚rique connect‚ au systŠme ne fonctionne pas.',
  { 0x20 }  'Le processus ne peut pas acc‚der au fichier car il est utilis‚ par un autre processus.',
  { 0x21 }  'Le processus ne peut pas acc‚der au fichier car un autre processus a verrouill‚ une partie du fichier.',
  { 0x22 }  'La mauvaise disquette est dans l''unit‚ de disque.',
  { 0x23 }  NIL,
  { 0x24 }  'Il y a trop de fichiers ouverts pour le partage.',
  { 0x25 }  NIL,
  { 0x26 }  'La fin du fichier est atteint.',
  { 0x27 }  'Le disque est plein.',
  { 0x28 }  NIL,
  { 0x29 }  NIL,
  { 0x2A }  NIL,
  { 0x2B }  NIL,
  { 0x2C }  NIL,
  { 0x2D }  NIL,
  { 0x2E }  NIL,
  { 0x2F }  NIL,
  { 0x30 }  NIL,
  { 0x31 }  NIL,
  { 0x32 }  'La demande n''est pas prise en charge.',
  { 0x33 }  'Ne peut pas trouver le chemin r‚seau.',
  { 0x34 }  'Vous n''‚tiez pas connect‚ car un nom en double existe sur le r‚seau.',
  { 0x35 }  'Le chemin r‚seau n''a pas ‚t‚ trouv‚.',
  { 0x36 }  'Le r‚seau est occup‚.',
  { 0x37 }  'La ressource r‚seau ou le p‚riph‚rique sp‚cifi‚ n''est plus disponible.',
  { 0x38 }  'La limite de commande du BIOS du r‚seau a ‚t‚ atteinte.',
  { 0x39 }  'Une erreur mat‚rielle de l''adaptateur r‚seau s''est produite.',
  { 0x3A }  'Le serveur sp‚cifi‚ ne peut pas r‚aliser l''op‚ration demand‚e.',
  { 0x3B }  'Une erreur r‚seau inattendue s''est produite.',
  { 0x3C }  'Adaptateur … distance n''est pas compatible.',
  { 0x3D }  'La file d''attente de l''imprimante est pleine.',
  { 0x3E }  'L''espace pour entreposer le fichier en attente d''impression n''est pas disponible sur le serveur.',
  { 0x3F }  'Votre fichier en attente d''impression a ‚t‚ supprim‚.',
  { 0x40 }  'Le nom de r‚seau sp‚cifi‚ n''est plus disponible.',
  { 0x41 }  'L''accŠs au r‚seau est refus‚.',
  { 0x42 }  'Le type de ressource r‚seau n''est pas correct.',
  { 0x43 }  'Le nom du r‚seau est introuvable.',
  { 0x44 }  'Le nom limite pour la carte r‚seau de l''ordinateur local a ‚t‚ d‚pass‚.',
  { 0x45 }  'La limite de session du BIOS du r‚seau a ‚t‚ d‚pass‚e.',
  { 0x46 }  'Le serveur … distance est en pause ou en cours de d‚marrage.',
  { 0x47 }  'Aucune autre connexion ne peut ˆtre ‚tablie avec cet ordinateur … distance pour le moment.',
  { 0x48 }  'L''imprimante ou le p‚riph‚rique de disque sp‚cifi‚ a ‚t‚ interrompu.',
  { 0x49 }  NIL,
  { 0x4A }  NIL,
  { 0x4B }  NIL,
  { 0x4C }  NIL,
  { 0x4D }  NIL,
  { 0x4E }  NIL,
  { 0x4F }  NIL,
  { 0x50 }  'Le fichier existe.',
  { 0x51 }  NIL,
  { 0x52 }  'Le r‚pertoire ou le fichier ne peut ˆtre cr‚‚.',
  { 0x53 }  'chec sur l''interruption 24.',
  { 0x54 }  'L''entreposage pour traiter cette demande n''est pas disponible.',
  { 0x55 }  'Le nom du p‚riph‚rique local est d‚j… utilis‚.',
  { 0x56 }  'Le mot de passe r‚seau sp‚cifi‚ n''est pas correct.',
  { 0x57 }  'Le paramŠtre est incorrect.',
  { 0x58 }  'Une erreur d''‚criture s''est produite sur le r‚seau.',
  { 0x59 }  'Le systŠme ne peut pas commencer un autre processus en ce moment.',
  { 0x5A }  NIL,
  { 0x5B }  NIL,
  { 0x5C }  NIL,
  { 0x5D }  NIL,
  { 0x5E }  NIL,
  { 0x5F }  NIL,
  { 0x60 }  NIL,
  { 0x61 }  NIL,
  { 0x62 }  NIL,
  { 0x63 }  NIL,
  { 0x64 }  'Il est impossible de cr‚er un autre systŠme de s‚maphore.',
  { 0x65 }  'Le s‚maphore exclusif appartient … un autre processus.',
  { 0x66 }  'Le s‚maphore est d‚fini et ne peut pas ˆtre ferm‚.',
  { 0x67 }  'S‚maphore ne peut plus ˆtre r‚gl‚.',
  { 0x68 }  'Il est impossible de demander des s‚maphores exclusifs au moment de l''interruption.',
  { 0x69 }  'La propri‚t‚ pr‚c‚dente de ce s‚maphore est termin‚e.',
  { 0x6A }  'Il faut ins‚rer la disquette dans l''unit‚ de disque sp‚cifi‚.',
  { 0x6B }  'Le programme s''est arrˆt‚ car aucune autre disquette n''a pas ‚t‚ ins‚r‚e.',
  { 0x6C }  'Le disque est en cours d''utilisation ou verrouill‚ par un autre processus.',
  { 0x6D }  'Le tuyau de flux de donn‚es s''est termin‚.',
  { 0x6E }  'Le systŠme ne peut pas ouvrir le p‚riph‚rique ou le fichier sp‚cifi‚.',
  { 0x6F }  'Le nom du fichier est trop long.',
  { 0x70 }  'Il n''y a pas assez d''espace sur le disque.',
  { 0x71 }  'Il n''y a plus d''identificateurs de fichiers internes disponibles.',
  { 0x72 }  'Identificateur de fichier interne cible est incorrect.',
  { 0x73 }NIL,
  { 0x74 }NIL,
  { 0x75 }  'Appel IOCTL effectu‚ par le programme d''application est incorrect.',
  { 0x76 }  'La valeur du paramŠtre de paramŠtre de v‚rification en ‚criture est incorrecte.',
  { 0x77 }  'Le systŠme ne prend pas en charge la commande demand‚e.',
  { 0x78 }  'La fonction n''est pas prise en charge sur ce systŠme.',
  { 0x79 }  'Le d‚lai d''expiration du s‚maphore a expir‚.',
  { 0x7A }  'La zone de donn‚es transmise … un appel systŠme est trop petite.',
  { 0x7B }  'Le nom du fichier, le nom du r‚pertoire ou la syntaxe de l''‚tiquette du volume est incorrecte.',
  { 0x7C }  'Le niveau d''appel systŠme n''est pas correct.',
  { 0x7D }  'Le disque n''a pas d''‚tiquette de volume.',
  { 0x7E }  'Le module sp‚cifi‚ est introuvable.',
  { 0x7F }  'La proc‚dure sp‚cifi‚e est introuvable.',
  { 0x80 }  'Il n''y a pas de processus enfants … attendre.',
  { 0x81 } NIL,
  { 0x82 }  'Il faut essayer d''utiliser un descripteur de fichier sur '+
            'une partition de disque ouverte pour une op‚ration autre que des les entr‚es/sorties de disque brutes.',
  { 0x83 }  'Une tentative de d‚placement du pointeur de fichier avant le d‚but du fichier a ‚t‚ effectu‚e.',
  { 0x84 }  'Le pointeur de fichier ne peut pas ˆtre d‚fini sur le p‚riph‚rique ou le fichier sp‚cifi‚.',
  { 0x85 }  'Une commande JOIN ou SUBST ne peut pas ˆtre utilis‚e pour un unit‚ de disque contenant des unit‚s '+
            'de disques pr‚c‚demment joints.',
  { 0x86 }  'Une tentative d''utilisation d''une commande JOIN ou SUBST sur un unit‚ de disque d‚j… joint a ‚t‚ effectu‚e.',
  { 0x87 }  'Une tentative d''utilisation d''une commande JOIN ou SUBST sur un unit‚ de disque d‚j… '+
            'substitu‚ a ‚t‚ effectu‚e.',
  { 0x88 }  'Le systŠme a tent‚ de supprimer la jointure d''un unit‚ de disque non joint.',
  { 0x89 }  'Le systŠme a tent‚ de supprimer la substitution d''un unit‚ de disque non substitu‚.',
  { 0x8A }  'Le systŠme a tent‚ de joindre un unit‚ de disque … un r‚pertoire d''un unit‚ de disque joint.',
  { 0x8B }  'Le systŠme a tent‚ de substituer un unit‚ de disque … un r‚pertoire sur un unit‚ de disque substitu‚.',
  { 0x8C }  'Le systŠme a tent‚ de joindre un unit‚ de disque … un r‚pertoire situ‚ sur un unit‚ de disque substitu‚.',
  { 0x8D }  'Le systŠme a tent‚ de SUBST un unit‚ de disque dans un r‚pertoire d''un unit‚ de disque joint',
  { 0x8E }  'Le systŠme ne peut pas ex‚cuter JOIN ou SUBST pour le moment.',
  { 0x8F }  'Le systŠme ne peut pas joindre ou substituer un unit‚ de disque … ou pour un r‚pertoire '+
            'sur le mˆme unit‚ de disque.'
 );

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 Number:LongInt;
 Err:Word;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

BEGIN
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('NET - Cette commande permet d''effectuer la gestion r‚seau');
  WriteLn;
  WriteLn('Syntaxe : NET HELPMSG numero');
 End
  Else
 If ParamCount>0Then Begin
  If StrToUpper(ParamStr(1))='HELPMSG'Then Begin
   Val(ParamStr(2),Number,Err);
   If Err>0 Then Begin
    WriteLn('Valeur non reconnu');
    Halt;
   End;
   If(Number>=Low(ErrorCode))and(Number<=High(ErrorCode))Then Begin
    WriteLn;
    If ErrorCode[Number]=NIL Then WriteLn(Number,' n''est pas identificateur valide.')
     Else
    WriteLn(StrPas(ErrorCode[Number]));
   End
    Else
   WriteLn('Ce code d''erreur est en dehors de l''intervalle reconnu.');
  End
   Else
  WriteLn('ParamŠtre non support‚');
 End
  Else
 WriteLn('ParamŠtre attendu');
END.