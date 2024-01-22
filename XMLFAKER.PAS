{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program XMLFAKER;

Uses Strings;

Const
 CityList:Array[0..72]of PChar=(
  'Alger','Alma','Arvida','Bagdad','Bagotville','Barcelone','Beijing',
  'Berlin','Boston','Brampton','Brossard','Calgary','Chicago',
  'Chicoutimi','Chomedey','Dallas','Delhi','Edmonton','GaspÇ','Gatineau',
  'Genäve','Grand-märe','Guelph','Halifax','Hamilton','Houston','Jakarta',
  'Jonquiäre','Laval','LÇvis','London','Londres','Longueuil','Madrid',
  'Manille','Markham','Marseille','Mexico','Miami','Milan','Mirabel',
  'Mississauga','Mumbai','Moncton','MontrÇal','Moscou','Munich',
  'Oakville','Ottawa','Paris','PÇkin','QuÇbec','Rome','Saguenay',
  'Sainte-DorothÇe','Saint-JÇrome','Saint-Lin','SÇoul','Shanghai',
  'Sherbrooke','Sept-Iles','St-Lin','Ste-DorothÇe','Surrey','Sydney',
  'Tadoussac','TÇhÇran','Terrebonne','Tokyo','Toronto','Vancouver',
  'Washington','Winnipeg'
 );

 CountryList:Array[0..248]of PChar=(
  'Afghanistan','Afrique du sud','Albanie','AlgÇrie','Allemagne',
  'Andorre','Angola','Anguilla','Antarctique','Antigua et Barbuda',
  'Arabie saoudite','Argentine','Armenie','Aruba','Australie',
  'Autriche','Azerbaidjan','Bahamas','Bahrein','Bangladesh',
  'Barbade','Belgique','Belize','Benin','Bermudes','Bhutan','BiÇlorussie',
  'Bolivie','Bonaire','Bosnie-Herzegovine','Botswana','BrÇsil',
  'Brunei Darussalam','Bulgarie','Burkina Faso','Burundi','Cambodge',
  'Cameroun','Canada','Cap-Vert','Centrafrique','Chili','Chine',
  'Chypre','Colombie','Comores','Congo-Brazzaville','CorÇe du Nord',
  'CorÇe du Sud','Costa Rica','Cìte d''Ivoire','Croatie','Cuba',
  'Curacao','Danemark','Djibouti','Dominique','Egypte',
  'Emirats arabes unis','Equateur','ErythrÇe','Espagne','Estonie',
  'Etats-Unis','Ethiopie','Fidji','Finlande','France','Gabon',
  'Gambie','Georgie','Georgie du Sud','Ghana','Gibraltar','Gräce',
  'Grenade','Groenland','Guadeloupe','Guam','Guatemala','Guernesey',
  'GuinÇe','GuinÇe equatoriale','GuinÇe-Bissau','Guyana','Guyane',
  'Haiti','Honduras','Hong Kong','Hongrie','Ile Bouvet','Ile Christmas',
  'Ile de Man','Ile Heard','Ile Norfolk','Iles Aland','Iles Caimans',
  'Iles Cocos','Iles Cook','Iles Feroe','Iles Malouines',
  'Iles Mariannes du Nord','Iles Marshall','Iles mineures',
  'Iles Salomon','Iles Turques-et-Caiques','Iles Vierges',
  'Iles Vierges des Etats-Unis','Inde','IndonÇsie','Irak','Iran',
  'Irlande','Islande','Israâl','Italie','Jamaique','Japon','Jersey',
  'Jordanie','Kazakhstan','Kenya','Kirghizistan','Kiribati','Kosovo',
  'Koweit','Laos','Lesotho','Lettonie','Liban','Liberia','Libye',
  'Liechtenstein','Lituanie','Luxembourg','Macao','MacÇdoine',
  'Madagascar','Malaisie','Malawi','Maldives','Mali','Malte','Maroc',
  'Martinique','Maurice','Mauritanie','Mayotte','Mexique','Micronesie',
  'Moldavie','Monaco','Mongolie','Montenegro','Montserrat','Mozambique',
  'Myanmar','Namibie','Nauru','NÇpal','Nicaragua','Niger','NigÇria',
  'Nioue','Norväge','Nouvelle-Caledonie','Nouvelle-ZÇlande','Oman',
  'Ouganda','Ouzbekistan','Pakistan','Palaos','Panama',
  'Papouasie-Nouvelle Guinee','Paraguay','Pays-Bas','PÇrou','Philippines',
  'Pitcairn','Pologne','PolynÇsie Franáaise','Porto Rico','Portugal',
  'Qatar','RÇpublique dÇmocratique du congo','RÇpublique Dominicaine',
  'RÇpublique Togolaise','RÇunion','Roumanie','Royaume-Uni','Russie',
  'Rwanda','Sahara Occidental','Saint-Barthelemy',
  'Saint-Christophe-et-Nieves','Saint-Marin','Saint-Martin',
  'Saint-Pierre et Miquelon','Saint-Vincent-et-les Grenadines',
  'Sainte-HÇläne','Sainte-Lucie','Salvador','Samoa','Samoa americaines',
  'Sao Tome-et-Principe','SÇnÇgal','Serbie','Seychelles','Sierra Leone',
  'Singapour','Slovaquie','SlovÇnie','Somalie','Soudan','Sri Lanka',
  'Sud-Soudan','Suäde','Suisse','Surinam','Svalbard et Ile Jan Mayen',
  'Swaziland','Syrie','Tadjikistan','Taiwan','Tanzanie','Tchad',
  'Tchequie','Terres australes franáaises',
  'Territoire britannique de l''ocÇan Indien','Territoire palestinien',
  'Thailande','Timor Oriental','Tokelau','Tonga','Trinidad et Tobago',
  'Tunisie','Turkmenistan','Turquie','Tuvalu','Ukraine','Uruguay',
  'Vanuatu','Vatican','VÇnezuela','Vietnam','Wallis-et-Futuna',
  'YÇmen','Zambie','Zimbabwe'
 );

 FirstNameList:Array[0..45]of PChar=(
  'Adrien','Albert','Alexandre','Alice','AndrÇ','Annie','Antoine',
  'Arthur','Benoåt','Charles-Eugäne','ClÇmence','Daniel','êtienne',
  'Franáois','Francis','Geneveive','Guillaume','Jacques','Jean','JÇrìme',
  'Joe','John','Joseph','Karl','Louisa','Luc','Manon','Marie',
  'Marguerite','Marina','Mathieu','Mohamed','Naomy','Philippe','Pierre',
  'Robert','Roger','Romald','Sophie','Steeve','Sylvain','ThÇodore','Tom',
  'William','Xavier','Yvan'
 );

 LastNameList:Array[0..306]of PChar=(
  'Tremblay','Gagnon','Roy','CìtÇ','Bouchard','Gauthier',
  'Morin','Lavoie','Fortin','GagnÇ','Ouellet','Pelletier',
  'BÇlanger','LÇvesque','Bergeron','Leblanc','Paquette',
  'Girard','Simard','Boucher','Caron','Beaulieu','Cloutier',
  'DubÇ','Poirier','Fournier','Lapointe','Leclerc','Lefebvre',
  'Poulin','Thibault','St-Pierre','Nadeau','Martin','Landry',
  'Martel','BÇdard','Grenier','Lessard','Bernier','Richard',
  'Michaud','HÇbert','Desjardins','Couture','Turcotte',
  'Lachance','Parent','Blais','Gosselin','Savard','Proulx',
  'Beaudoin','Demers','Perreault','Boudreau','Lemieux',
  'Cyr','Perron','Dufour','Dion','Mercier','Bolduc',
  'BÇrubÇ','Boisvert','Langlois','MÇnard','Therrien',
  'Bilodeau','Plante','Blanchette','Dubois','Champagne',
  'Paradis','Fortier','Arsenault','Dupuis','Gaudreault',
  'Hamel','BoulÇ','Villeneuve','Rousseau','Gravel','ThÇriault',
  'Lemay','Robert','Allard','Deschànes','Giroux','Guay',
  'Leduc','Boivin','Charbonneau','Lambert','Raymond',
  'Vachon','Gilbert','Audet','Jean','Larouche','Legault',
  'Trudel','Fontaine','Picard','Labelle','Lacroix',
  'Jacques','Moreau','Carrier','Bernard','Desrosiers',
  'Goulet','Renaud','Dionne','Lapierre','Vaillancourt',
  'Fillion','Lalonde','Tessier','Bertrand','Tardif',
  'Lepage','Gingras','Benoit','Rioux','Giguere','Drouin',
  'Harvey','Lauzon','Gendron','Boutin','Laflamme','VallÇe',
  'Dumont','Breton','ParÇ','Paquin','Robitaille','Gelinas',
  'Duchesne','Lussier','SÇguin','Veilleux','Potvin',
  'Gervais','PÇpin','Laroche','Morissette','Charron',
  'LavallÇe','Laplante','Chabot','Brunet','VÇzina',
  'Desrochers','Labrecque','Coulombe','Tanguay','Chouinard',
  'Noâl','Pouliot','Lacasse','Daigle','Marcoux','Lamontagne',
  'Turgeon','Larocque','Roberge','Auger','Masse','Pilon',
  'Racine','Dallaire','êmond','GrÇgoire','Beauregard',
  'Smith','Denis','Lebel','Blouin','Martineau','LabbÇ',
  'Beauchamp','St-Onge','Charette','Dupont','Letourneau',
  'Rodrigue','Cormier','Rivard','Mathieu','Asselin',
  'St-Jean','Plourde','Thibodeau','Belisle','St-Laurent',
  'Godin','Desbiens','Lavigne','Doucet','LabontÇ','Marchand',
  'Brassard','Forget','Patel','Marcotte','BÇland','Larose',
  'Duval','Archambault','Maltais','TrÇpanier','LalibertÇ',
  'Bisson','Brisson','Dufresne','Beaudry','Chartrand',
  'Houde','FrÇchette','Lafontaine','Guillemette','Drolet',
  'Vincent','Richer','Germain','Lariviäre','Ferland',
  'Trottier','PichÇ','Boulanger','Sirois','Charest',
  'Provost','Durand','Dumas','Soucy','Lamoureux',
  'Lachapelle','Begin','Boily','Croteau','Savoie','Provencher',
  'PrÇvost','Duguay','Lemire','Delisle','Desmarais','Laberge',
  'Nault','Bourgeois','Lafrance','Lagace','Daoust',
  'Brault','Castonguay','Valliäres','Pellerin','Rivest',
  'Brochu','Samson','LÇpine','Leroux','Larochelle',
  'Brousseau','SauvÇ','Laurin','ClÇment','Bissonnette',
  'Lajoie','Aubin','Doyon','Labrie','Grondin','Faucher',
  'Corriveau','TÇtreault','Bourque','Dagenais','Ducharme',
  'Carriäre','Duquette','Lafleur','Langevin','Corbeil',
  'Bourassa','Page','Trudeau','Gaudet','Cantin','Goyette',
  'Boyer','Francoeur','St-Louis','Barrette','Vigneault',
  'Ouimet','Baril','Lafreniäre','Meunier','Laporte',
  'Joseph','Brodeur','LegarÇ','Lafond'
 );

 JobsList:Array[0..26]of PChar=(
  'Avocat','Agent immobilier','Analyste','Architecte','Astronome',
  'Barmen','Biologiste','Blogueur','Chanteur','Charpentier','Chimiste',
  'Diplomate','êlectricien','Enquàteur','GÇnÇticien','Guitariste',
  'Infirmiäre','Journaliste','MathÇmaticien','MÇdecin','Paysagiste',
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

 Words:Array[0..177]of PChar=(
  'lorem','ipsum','dolor','sit','amet','consectetur','adipiscing',
  'elit','curabitur','vel','hendrerit','libero','eleifend',
  'blandit','nunc','ornare','odio','ut','orci','gravida',
  'imperdiet','nullam','purus','lacinia','a','pretium','quis',
  'congue','praesent','sagittis','laoreet','auctor','mauris',
  'non','velit','eros','dictum','proin','accumsan','sapien','nec',
  'massa','volutpat','venenatis','sed','eu','molestie','lacus',
  'quisque','porttitor','ligula','dui','mollis','tempus','at',
  'magna','vestibulum','turpis','ac','diam','tincidunt','id',
  'condimentum','enim','sodales','in','hac','habitasse','platea',
  'dictumst','aenean','neque','fusce','augue','leo','eget','semper',
  'mattis','tortor','scelerisque','nulla','interdum','tellus',
  'malesuada','rhoncus','porta','sem','aliquet','et','nam',
  'suspendisse','potenti','vivamus','luctus','fringilla','erat',
  'donec','justo','vehicula','ultricies','varius','ante','primis',
  'faucibus','ultrices','posuere','cubilia','curae','etiam',
  'cursus','aliquam','quam','dapibus','nisl','feugiat','egestas',
  'class','aptent','taciti','sociosqu','ad','litora','torquent',
  'per','conubia','nostra','inceptos','himenaeos','phasellus',
  'nibh','pulvinar','vitae','urna','iaculis','lobortis','nisi',
  'viverra','arcu','morbi','pellentesque','metus','commodo',
  'ut','facilisis','felis','tristique','ullamcorper','placerat',
  'aenean','convallis','sollicitudin','integer','rutrum','duis',
  'est','etiam','bibendum','donec','pharetra','vulputate',
  'maecenas','mi','fermentum','consequat','suscipit','aliquam',
  'habitant','senectus','netus','fames','quisque','euismod',
  'curabitur','lectus','elementum','tempor','risus','cras'
 );

Type
 GroupType=(None,Address,City,Country,FirstName,LastName,FullName,
            IntegerNumber,RealNumber,Job,Price,Street,TextData);

Var
 ModeParam:(_None,_Rows);
 GroupList:Array[0..255]of GroupType;
 GroupNum:Integer;
 Err:Word;
 I:Integer;
 J:LongInt;
 Rows:LongInt;
 CurrName,CurrParam,CurrField:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function StrToCapital(S:String):String;Begin
 If Length(S)=0 Then StrToCapital:=''
                Else StrToCapital:=UpCase(S[1])+Copy(S,2,255);
End;

Function Gauss:Real;
Var
 U,V,X,Y:Real;
Begin
 X:=Random;
 Y:=Random;
 U:=Sqrt(-2*Ln(X))*Cos(2*PI*Y);
 V:=Sqrt(-2*Ln(X))*Sin(2*PI*Y);
 Gauss:=U;
End;

Function GaussMs(M,S:Real):Real;Begin
 GaussMs:=Gauss+S+M;
End;

Function GaussSentence:Integer;Begin
 GaussSentence:=Round(GaussMs(2.460,5.080));
End;

Function FakeText:String;
Const
 Count=25;
 LoremIpsum=True;
Var
 I,NumWord,_Index,LenSentence:Integer;
 Capital:Boolean;
 R,LastWord:String;
Begin
 R:='';
 Capital:=True;
 LenSentence:=GaussSentence;
 I:=0;NumWord:=0;
 If(LoremIpsum)Then Begin
  I:=2;
  R:='Lorem ';
  R:=R+'Ipsum ';
  NumWord:=2;
 End;
 While(I<Count)do Begin
  _Index:=Random(High(Words));
  If LastWord=StrPas(Words[_Index])Then _Index:=Random(High(Words));
  If(Capital)Then Begin
   R:=R+StrToCapital(StrPas(Words[_Index]));
   Capital:=False;
  End
   Else
  R:=R+StrPas(Words[_Index]);
  If I+1<Count Then Begin
   If NumWord>=LenSentence Then Begin
    LenSentence:=GaussSentence;
    Case Random(2) of
     0:R:=R+', ';
     1:Begin
      R:=R+'. ';
      Capital:=True;
     End;
    End;
    NumWord:=0;
   End
    Else
   Begin
    R:=R+' ';
    Inc(NumWord);
    Capital:=False;
   End;
  End;
  LastWord:=StrPas(Words[_Index]);
  Inc(I);
 End;
 R:=R+'.';
 FakeText:=R;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('XMLFAKER : Cette commande permet de gÇnÇrer un fichier XML ',
                     ' selon des donnÇes alÇatoires spÇcifiÇs.');
  WriteLn;
  WriteLn('Syntaxe : XMLFAKER [city|firstname|lastname|name|job|price] [...]');
  WritelN('                   [-R nombre]');
  WriteLn;
  WriteLn(' address      Colonne d''une adresse');
  WriteLn(' city         Colonne de ville');
  WriteLn(' country      Colonne de pays');
  WriteLn(' firstname    Colonne de prÇnom');
  WriteLn(' fullname     Colonne de prÇnom et nom');
  WriteLn(' integer      Colonne d''un nombre entier');
  WriteLn(' job          Colonne de travail');
  WriteLn(' lasttname    Colonne de nom de famille');
  WriteLn(' price        Colonne de prix');
  WriteLn(' real         Colonne d''un nombre rÇel');
  WriteLn(' street       Colonne d''une rue');
  WriteLn(' text         Colonne d''un texte');
  WriteLn(' -R nombre    Nombre de ligne Ö gÇnÇrÇ. Par dÇfaut 10.');
 End
  Else
 Begin
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
   End
    Else
   If StrToUpper(ParamStr(I))='TEXT'Then Begin
    GroupList[GroupNum]:=TextData;
    Inc(GroupNum);
   End;
  End;
  If GroupNum>0 Then Begin
   WriteLn('<?xml version="1.0" encoding="ISO-8859-1"?>');
   WriteLn('<table>');
   For J:=1 to Rows do Begin
    WriteLn(' ':4,'<line>');
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
      TextData:CurrField:=FakeText;
      Else CurrField:='';
     End;
     Case GroupList[I]of
      Address:CurrName:='address';
      City:CurrName:='city';
      Country:CurrName:='country';
      FirstName:CurrName:='firstname';
      LastName:CurrName:='lastname';
      FullName:CurrName:='fullname';
      IntegerNumber:CurrName:='integername';
      RealNumber:CurrName:='real';
      Job:CurrName:='job';
      Price:CurrName:='price';
      Street:CurrName:='street';
      TextData:CurrName:='text';
      Else CurrName:='';
     End;
     WriteLn(' ':8,'<',CurrName,I,'>',CurrField,'</',CurrName,I,'>');
    End;
    WriteLn(' ':4,'</line>');
   End;
   WriteLn('</table>');
  End;
 End;
END.

