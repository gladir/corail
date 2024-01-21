{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CSVFAKER;

Uses Strings;

Const
 CityList:Array[0..72]of PChar=(
  'Alger','Alma','Arvida','Bagdad','Bagotville','Barcelone','Beijing',
  'Berlin','Boston','Brampton','Brossard','Calgary','Chicago',
  'Chicoutimi','Chomedey','Dallas','Delhi','Edmonton','Gasp‚','Gatineau',
  'GenŠve','Grand-mŠre','Guelph','Halifax','Hamilton','Houston','Jakarta',
  'JonquiŠre','Laval','L‚vis','London','Londres','Longueuil','Madrid',
  'Manille','Markham','Marseille','Mexico','Miami','Milan','Mirabel',
  'Mississauga','Mumbai','Moncton','Montr‚al','Moscou','Munich',
  'Oakville','Ottawa','Paris','P‚kin','Qu‚bec','Rome','Saguenay',
  'Sainte-Doroth‚e','Saint-J‚rome','Saint-Lin','S‚oul','Shanghai',
  'Sherbrooke','Sept-Iles','St-Lin','Ste-Doroth‚e','Surrey','Sydney',
  'Tadoussac','T‚h‚ran','Terrebonne','Tokyo','Toronto','Vancouver',
  'Washington','Winnipeg'
 );

 CountryList:Array[0..248]of PChar=(
  'Afghanistan','Afrique du sud','Albanie','Alg‚rie','Allemagne',
  'Andorre','Angola','Anguilla','Antarctique','Antigua et Barbuda',
  'Arabie saoudite','Argentine','Armenie','Aruba','Australie',
  'Autriche','Azerbaidjan','Bahamas','Bahrein','Bangladesh',
  'Barbade','Belgique','Belize','Benin','Bermudes','Bhutan','Bi‚lorussie',
  'Bolivie','Bonaire','Bosnie-Herzegovine','Botswana','Br‚sil',
  'Brunei Darussalam','Bulgarie','Burkina Faso','Burundi','Cambodge',
  'Cameroun','Canada','Cap-Vert','Centrafrique','Chili','Chine',
  'Chypre','Colombie','Comores','Congo-Brazzaville','Cor‚e du Nord',
  'Cor‚e du Sud','Costa Rica','C“te d''Ivoire','Croatie','Cuba',
  'Curacao','Danemark','Djibouti','Dominique','Egypte',
  'Emirats arabes unis','Equateur','Erythr‚e','Espagne','Estonie',
  'Etats-Unis','Ethiopie','Fidji','Finlande','France','Gabon',
  'Gambie','Georgie','Georgie du Sud','Ghana','Gibraltar','GrŠce',
  'Grenade','Groenland','Guadeloupe','Guam','Guatemala','Guernesey',
  'Guin‚e','Guin‚e equatoriale','Guin‚e-Bissau','Guyana','Guyane',
  'Haiti','Honduras','Hong Kong','Hongrie','Ile Bouvet','Ile Christmas',
  'Ile de Man','Ile Heard','Ile Norfolk','Iles Aland','Iles Caimans',
  'Iles Cocos','Iles Cook','Iles Feroe','Iles Malouines',
  'Iles Mariannes du Nord','Iles Marshall','Iles mineures',
  'Iles Salomon','Iles Turques-et-Caiques','Iles Vierges',
  'Iles Vierges des Etats-Unis','Inde','Indon‚sie','Irak','Iran',
  'Irlande','Islande','Isra‰l','Italie','Jamaique','Japon','Jersey',
  'Jordanie','Kazakhstan','Kenya','Kirghizistan','Kiribati','Kosovo',
  'Koweit','Laos','Lesotho','Lettonie','Liban','Liberia','Libye',
  'Liechtenstein','Lituanie','Luxembourg','Macao','Mac‚doine',
  'Madagascar','Malaisie','Malawi','Maldives','Mali','Malte','Maroc',
  'Martinique','Maurice','Mauritanie','Mayotte','Mexique','Micronesie',
  'Moldavie','Monaco','Mongolie','Montenegro','Montserrat','Mozambique',
  'Myanmar','Namibie','Nauru','N‚pal','Nicaragua','Niger','Nig‚ria',
  'Nioue','NorvŠge','Nouvelle-Caledonie','Nouvelle-Z‚lande','Oman',
  'Ouganda','Ouzbekistan','Pakistan','Palaos','Panama',
  'Papouasie-Nouvelle Guinee','Paraguay','Pays-Bas','P‚rou','Philippines',
  'Pitcairn','Pologne','Polyn‚sie Fran‡aise','Porto Rico','Portugal',
  'Qatar','R‚publique d‚mocratique du congo','R‚publique Dominicaine',
  'R‚publique Togolaise','R‚union','Roumanie','Royaume-Uni','Russie',
  'Rwanda','Sahara Occidental','Saint-Barthelemy',
  'Saint-Christophe-et-Nieves','Saint-Marin','Saint-Martin',
  'Saint-Pierre et Miquelon','Saint-Vincent-et-les Grenadines',
  'Sainte-H‚lŠne','Sainte-Lucie','Salvador','Samoa','Samoa americaines',
  'Sao Tome-et-Principe','S‚n‚gal','Serbie','Seychelles','Sierra Leone',
  'Singapour','Slovaquie','Slov‚nie','Somalie','Soudan','Sri Lanka',
  'Sud-Soudan','SuŠde','Suisse','Surinam','Svalbard et Ile Jan Mayen',
  'Swaziland','Syrie','Tadjikistan','Taiwan','Tanzanie','Tchad',
  'Tchequie','Terres australes fran‡aises',
  'Territoire britannique de l''oc‚an Indien','Territoire palestinien',
  'Thailande','Timor Oriental','Tokelau','Tonga','Trinidad et Tobago',
  'Tunisie','Turkmenistan','Turquie','Tuvalu','Ukraine','Uruguay',
  'Vanuatu','Vatican','V‚nezuela','Vietnam','Wallis-et-Futuna',
  'Y‚men','Zambie','Zimbabwe'
 );

 FirstNameList:Array[0..45]of PChar=(
  'Adrien','Albert','Alexandre','Alice','Andr‚','Annie','Antoine',
  'Arthur','BenoŒt','Charles-EugŠne','Cl‚mence','Daniel','tienne',
  'Fran‡ois','Francis','Geneveive','Guillaume','Jacques','Jean','J‚r“me',
  'Joe','John','Joseph','Karl','Louisa','Luc','Manon','Marie',
  'Marguerite','Marina','Mathieu','Mohamed','Naomy','Philippe','Pierre',
  'Robert','Roger','Romald','Sophie','Steeve','Sylvain','Th‚odore','Tom',
  'William','Xavier','Yvan'
 );

 LastNameList:Array[0..306]of PChar=(
  'Tremblay','Gagnon','Roy','C“t‚','Bouchard','Gauthier',
  'Morin','Lavoie','Fortin','Gagn‚','Ouellet','Pelletier',
  'B‚langer','L‚vesque','Bergeron','Leblanc','Paquette',
  'Girard','Simard','Boucher','Caron','Beaulieu','Cloutier',
  'Dub‚','Poirier','Fournier','Lapointe','Leclerc','Lefebvre',
  'Poulin','Thibault','St-Pierre','Nadeau','Martin','Landry',
  'Martel','B‚dard','Grenier','Lessard','Bernier','Richard',
  'Michaud','H‚bert','Desjardins','Couture','Turcotte',
  'Lachance','Parent','Blais','Gosselin','Savard','Proulx',
  'Beaudoin','Demers','Perreault','Boudreau','Lemieux',
  'Cyr','Perron','Dufour','Dion','Mercier','Bolduc',
  'B‚rub‚','Boisvert','Langlois','M‚nard','Therrien',
  'Bilodeau','Plante','Blanchette','Dubois','Champagne',
  'Paradis','Fortier','Arsenault','Dupuis','Gaudreault',
  'Hamel','Boul‚','Villeneuve','Rousseau','Gravel','Th‚riault',
  'Lemay','Robert','Allard','Deschˆnes','Giroux','Guay',
  'Leduc','Boivin','Charbonneau','Lambert','Raymond',
  'Vachon','Gilbert','Audet','Jean','Larouche','Legault',
  'Trudel','Fontaine','Picard','Labelle','Lacroix',
  'Jacques','Moreau','Carrier','Bernard','Desrosiers',
  'Goulet','Renaud','Dionne','Lapierre','Vaillancourt',
  'Fillion','Lalonde','Tessier','Bertrand','Tardif',
  'Lepage','Gingras','Benoit','Rioux','Giguere','Drouin',
  'Harvey','Lauzon','Gendron','Boutin','Laflamme','Vall‚e',
  'Dumont','Breton','Par‚','Paquin','Robitaille','Gelinas',
  'Duchesne','Lussier','S‚guin','Veilleux','Potvin',
  'Gervais','P‚pin','Laroche','Morissette','Charron',
  'Lavall‚e','Laplante','Chabot','Brunet','V‚zina',
  'Desrochers','Labrecque','Coulombe','Tanguay','Chouinard',
  'No‰l','Pouliot','Lacasse','Daigle','Marcoux','Lamontagne',
  'Turgeon','Larocque','Roberge','Auger','Masse','Pilon',
  'Racine','Dallaire','mond','Gr‚goire','Beauregard',
  'Smith','Denis','Lebel','Blouin','Martineau','Labb‚',
  'Beauchamp','St-Onge','Charette','Dupont','Letourneau',
  'Rodrigue','Cormier','Rivard','Mathieu','Asselin',
  'St-Jean','Plourde','Thibodeau','Belisle','St-Laurent',
  'Godin','Desbiens','Lavigne','Doucet','Labont‚','Marchand',
  'Brassard','Forget','Patel','Marcotte','B‚land','Larose',
  'Duval','Archambault','Maltais','Tr‚panier','Lalibert‚',
  'Bisson','Brisson','Dufresne','Beaudry','Chartrand',
  'Houde','Fr‚chette','Lafontaine','Guillemette','Drolet',
  'Vincent','Richer','Germain','LariviŠre','Ferland',
  'Trottier','Pich‚','Boulanger','Sirois','Charest',
  'Provost','Durand','Dumas','Soucy','Lamoureux',
  'Lachapelle','Begin','Boily','Croteau','Savoie','Provencher',
  'Pr‚vost','Duguay','Lemire','Delisle','Desmarais','Laberge',
  'Nault','Bourgeois','Lafrance','Lagace','Daoust',
  'Brault','Castonguay','ValliŠres','Pellerin','Rivest',
  'Brochu','Samson','L‚pine','Leroux','Larochelle',
  'Brousseau','Sauv‚','Laurin','Cl‚ment','Bissonnette',
  'Lajoie','Aubin','Doyon','Labrie','Grondin','Faucher',
  'Corriveau','T‚treault','Bourque','Dagenais','Ducharme',
  'CarriŠre','Duquette','Lafleur','Langevin','Corbeil',
  'Bourassa','Page','Trudeau','Gaudet','Cantin','Goyette',
  'Boyer','Francoeur','St-Louis','Barrette','Vigneault',
  'Ouimet','Baril','LafreniŠre','Meunier','Laporte',
  'Joseph','Brodeur','Legar‚','Lafond'
 );

 JobsList:Array[0..26]of PChar=(
  'Avocat','Agent immobilier','Analyste','Architecte','Astronome',
  'Barmen','Biologiste','Blogueur','Chanteur','Charpentier','Chimiste',
  'Diplomate','lectricien','Enquˆteur','G‚n‚ticien','Guitariste',
  'InfirmiŠre','Journaliste','Math‚maticien','M‚decin','Paysagiste',
  'Physicien','Policier','Pompiste','Programmeur','Scrum Master',
  'Serveuse'
 );

 StreetList:Array[0..28]of PChar=(
  'Albert','Armand Frappier','Ampere','Argenson','Boileau','Cadieux',
  'Daigle','Emile','Favreau','Gagnon','Hervieux','Isabelle','Josiane',
  'Kugler','Labries','Maheux','Nicolet','Olivier','Papineau',
  'Quevillon','Racicot','Saint-Henri','Tulipes','Villeneuve','Violette',
  'Wilfrid Laurier','Xavier','Yamaska','Zephyr'
 );

Type
 GroupType=(None,Address,City,Country,FirstName,LastName,FullName,
            IntegerNumber,RealNumber,Job,Price,Street);

Var
 ModeParam:(_None,_Rows,_Delimiter);
 Delimiter:Char;
 GroupList:Array[0..255]of GroupType;
 GroupNum:Integer;
 Err:Word;
 I:Integer;
 J:LongInt;
 Rows:LongInt;
 CurrParam,CurrField:String;

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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CSVFAKER : Cette commande permet de g‚n‚rer un fichier CSV ',
                     ' selon des donn‚es al‚tatoires sp‚cifi‚s.');
  WriteLn;
  WriteLn('Syntaxe : CSVFAKER [city|firstname|lastname|name|job|price] [...]');
  WritelN('                   [-R nombre] [-D caractŠre]');
  WriteLn;
  WriteLn(' address      Colonne d''une adresse');
  WriteLn(' city         Colonne de ville');
  WriteLn(' country      Colonne de pays');
  WriteLn(' firstname    Colonne de pr‚nom');
  WriteLn(' fullname     Colonne de pr‚nom et nom');
  WriteLn(' integer      Colonne d''un nombre entier');
  WriteLn(' job          Colonne de travail');
  WriteLn(' lasttname    Colonne de nom de famille');
  WriteLn(' price        Colonne de prix');
  WriteLn(' real         Colonne d''un nombre r‚el');
  WriteLn(' street       Colonne d''une rue');
  WriteLn(' -D caractŠre CaractŠre de s‚p‚ration. Par d‚faut ®,¯.');
  WriteLn(' -R nombre    Nombre de ligne … g‚n‚r‚. Par d‚faut 10.');
 End
  Else
 Begin
  Delimiter:=',';
  Rows:=10;
  ModeParam:=_None;
  GroupNum:=0;
  FillChar(GroupList,SizeOf(GroupList),0);
  For I:=1 to ParamCount do Begin
   If(ModeParam=_Rows)Then Begin
    Val(ParamStr(I),Rows,Err);
    ModeParam:=_None;
   End
    Else
   If(ModeParam=_Delimiter)Then Begin
    CurrParam:=ParamStr(I);
    If Length(CurrParam)>0 Then Delimiter:=CurrParam[1];
    ModeParam:=_None;
   End
    Else
   If(StrToUpper(ParamStr(I))='-D')or(StrToUpper(ParamStr(I))='--DELIMITER')Then Begin
    ModeParam:=_Delimiter;
   End
    Else
   If(StrToUpper(ParamStr(I))='-R')or(StrToUpper(ParamStr(I))='--ROWS')Then Begin
    ModeParam:=_Rows;
   End
    Else
   If StrToUpper(ParamStr(I))='ADDRESS'Then Begin
    GroupList[GroupNum]:=Address;
    Inc(GroupNum);
   End
    Else
   If StrToUpper(ParamStr(I))='CITY'Then Begin
    GroupList[GroupNum]:=City;
    Inc(GroupNum);
   End
    Else
   If StrToUpper(ParamStr(I))='COUNTRY'Then Begin
    GroupList[GroupNum]:=Country;
    Inc(GroupNum);
   End
    Else
   If StrToUpper(ParamStr(I))='FIRSTNAME'Then Begin
    GroupList[GroupNum]:=FirstName;
    Inc(GroupNum);
   End
    Else
   If StrToUpper(ParamStr(I))='FULLNAME'Then Begin
    GroupList[GroupNum]:=FullName;
    Inc(GroupNum);
   End
    Else
   If StrToUpper(ParamStr(I))='INTEGER'Then Begin
    GroupList[GroupNum]:=IntegerNumber;
    Inc(GroupNum);
   End
    Else
   If StrToUpper(ParamStr(I))='JOB'Then Begin
    GroupList[GroupNum]:=Job;
    Inc(GroupNum);
   End
    Else
   If StrToUpper(ParamStr(I))='LASTNAME'Then Begin
    GroupList[GroupNum]:=LastName;
    Inc(GroupNum);
   End
    Else
   If StrToUpper(ParamStr(I))='NAME'Then Begin
    GroupList[GroupNum]:=FullName;
    Inc(GroupNum);
   End
    Else
   If StrToUpper(ParamStr(I))='PRICE'Then Begin
    GroupList[GroupNum]:=Price;
    Inc(GroupNum);
   End
    Else
   If StrToUpper(ParamStr(I))='REAL'Then Begin
    GroupList[GroupNum]:=RealNumber;
    Inc(GroupNum);
   End
    Else
   If StrToUpper(ParamStr(I))='STREET'Then Begin
    GroupList[GroupNum]:=Street;
    Inc(GroupNum);
   End;
  End;
  If GroupNum>0 Then For J:=1 to Rows do Begin
   For I:=0 to GroupNum-1 do Begin
    Case GroupList[I] of
     Address:Begin
      Str(Random(1000),CurrField);
      CurrField:=CurrField+' '+StrPas(StreetList[Random(High(StreetList))]);
     End;
     City:CurrField:=StrPas(CityList[Random(High(CityList))]);
     Country:CurrField:=StrPas(CountryList[Random(High(CountryList))]);
     FirstName:CurrField:=StrPas(FirstNameList[Random(High(FirstNameList))]);
     FullName:CurrField:=StrPas(FirstNameList[Random(High(FirstNameList))])+' '+
                         StrPas(LastNameList[Random(High(LastNameList))]);
     LastName:CurrField:=StrPas(LastNameList[Random(High(LastNameList))]);
     IntegerNumber:Str(Random(32767),CurrField);
     Job:CurrField:=StrPas(JobsList[Random(High(JobsList))]);
     Price:Begin
      Str(Random(1000),CurrField);
      Str(Random(100),CurrParam);
      CurrField:=CurrField+','+CurrParam+' $';
     End;
     RealNumber:Str(Random,CurrField);
     Street:CurrField:=StrPas(StreetList[Random(High(StreetList))]);
     Else CurrField:='';
    End;
    If I>0 Then Write(Delimiter);
    Write(CurrField);
   End;
   WriteLn;
  End;
 End;
END.