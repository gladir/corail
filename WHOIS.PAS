{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program WHOIS;

Uses Strings;

Type
 IPNetRange=Record
  A_IP1,A_IP2,A_IP3,A_IP4,B_IP1,B_IP2,B_IP3,B_IP4:Byte;
  OrgName:PChar;
  Country:Word;
 End;

 CountryRec=Record
  Value:Word;
  CountryName:PChar;
 End;

Const
 CountryList:Array[0..242]of CountryRec=(
  (Value:10796;CountryName:'Region du pacifique et d''asie'),
  (Value:10797;CountryName:'Europe'),
  (Value:10798;CountryName:'Andorre'),
  (Value:10799;CountryName:'mirats Arabes Unis'),
  (Value:10800;CountryName:'Afghanistan'),
  (Value:10801;CountryName:'Antigua-et-Barbuda'),
  (Value:10802;CountryName:'Anguilla'),
  (Value:10803;CountryName:'Albanie'),
  (Value:10804;CountryName:'Arm‚nie'),
  (Value:10823;CountryName:'Antilles n‚erlandaises'),
  (Value:10824;CountryName:'Angola'),
  (Value:10825;CountryName:'Antarctique'),
  (Value:10826;CountryName:'Argentine'),
  (Value:10827;CountryName:'Samoa am‚ricaines'),
  (Value:10828;CountryName:'Autriche'),
  (Value:10829;CountryName:'Australie'),
  (Value:10830;CountryName:'Aruba'),
  (Value:10831;CountryName:'Azerba‹djan'),
  (Value:10832;CountryName:'Bosnie et Herz‚govine'),
  (Value:10833;CountryName:'Barbade (La)'),
  (Value:10834;CountryName:'Bangladesh'),
  (Value:10835;CountryName:'Belgique'),
  (Value:10836;CountryName:'Burkina-Faso'),
  (Value:10837;CountryName:'Bulgarie'),
  (Value:10838;CountryName:'Bahre‹n'),
  (Value:10839;CountryName:'Burundi'),
  (Value:10840;CountryName:'B‚nin'),
  (Value:10841;CountryName:'Bermudes'),
  (Value:10842;CountryName:'Brunei'),
  (Value:10843;CountryName:'Bolivie'),
  (Value:10844;CountryName:'Br‚sil'),
  (Value:10845;CountryName:'Bahamas'),
  (Value:10846;CountryName:'Bhoutan'),
  (Value:10847;CountryName:'Bouvet Island'),
  (Value:10848;CountryName:'Iles Bouvet'),
  (Value:10849;CountryName:'Belarus'),
  (Value:10850;CountryName:'Belize'),
  (Value:10851;CountryName:'Canada'),
  (Value:10852;CountryName:'Iles Cocos-Keeling'),
  (Value:10853;CountryName:'Congo, R‚publique d‚mocratique du (Za‹re)'),
  (Value:10854;CountryName:'R‚publique Centrafricaine'),
  (Value:10855;CountryName:'Congo'),
  (Value:10856;CountryName:'Suisse'),
  (Value:10857;CountryName:'C“te D''Ivoire'),
  (Value:10858;CountryName:'Iles Cook'),
  (Value:10859;CountryName:'Chili'),
  (Value:10860;CountryName:'Cameroun'),
  (Value:10861;CountryName:'Chine'),
  (Value:10862;CountryName:'Colombie'),
  (Value:10863;CountryName:'Costa Rica'),
  (Value:10864;CountryName:'Cuba'),
  (Value:10865;CountryName:'Cap-Vert'),
  (Value:10866;CountryName:'Ile Christmas'),
  (Value:10867;CountryName:'Chypre'),
  (Value:10868;CountryName:'R‚publique tchŠque'),
  (Value:10869;CountryName:'Allemagne'),
  (Value:10870;CountryName:'Djibouti'),
  (Value:10871;CountryName:'Danemark'),
  (Value:10872;CountryName:'Dominique (la)'),
  (Value:10873;CountryName:'R‚publique Dominicaine'),
  (Value:10874;CountryName:'Alg‚rie'),
  (Value:10875;CountryName:'quateur'),
  (Value:10876;CountryName:'Estonie'),
  (Value:10877;CountryName:'gypte'),
  (Value:10878;CountryName:'Western Sahara'),
  (Value:10879;CountryName:'rythr‚e'),
  (Value:10880;CountryName:'Espagne'),
  (Value:10881;CountryName:'thiopie'),
  (Value:10882;CountryName:'Finlande'),
  (Value:10883;CountryName:'Iles Fidji'),
  (Value:10884;CountryName:'Iles Malouines'),
  (Value:10885;CountryName:'Micron‚sie'),
  (Value:10886;CountryName:'Iles F‚ro‚'),
  (Value:10887;CountryName:'France'),
  (Value:10888;CountryName:'France, Metropolitan'),
  (Value:10889;CountryName:'Gabon'),
  (Value:10890;CountryName:'Royaume-Uni'),
  (Value:10891;CountryName:'Grenade'),
  (Value:10892;CountryName:'G‚orgie'),
  (Value:10893;CountryName:'Guyane fran‡aise'),
  (Value:10894;CountryName:'Ghana'),
  (Value:10895;CountryName:'Gibraltar'),
  (Value:10896;CountryName:'Groenland'),
  (Value:10897;CountryName:'Gambie'),
  (Value:10898;CountryName:'Guin‚e'),
  (Value:10899;CountryName:'Guadeloupe'),
  (Value:10900;CountryName:'Guin‚e quatoriale'),
  (Value:10901;CountryName:'GrŠce'),
  (Value:10902;CountryName:'G‚orgie du Sud et Sandwich du Sud (IIes)'),
  (Value:10903;CountryName:'Guatemala'),
  (Value:10904;CountryName:'Guam'),
  (Value:10905;CountryName:'Guin‚e-Bissau'),
  (Value:10906;CountryName:'Guyane'),
  (Value:10907;CountryName:'Hong Kong'),
  (Value:10908;CountryName:'Iles Heard et Iles McDonald'),
  (Value:10909;CountryName:'Honduras (le)'),
  (Value:10910;CountryName:'Croatie'),
  (Value:10911;CountryName:'Ha‹ti'),
  (Value:10912;CountryName:'Hongrie'),
  (Value:10913;CountryName:'Indon‚sie'),
  (Value:10914;CountryName:'Irlande'),
  (Value:10915;CountryName:'Isra‰l'),
  (Value:10916;CountryName:'Inde'),
  (Value:10917;CountryName:'Territoires Britanniques de l''''oc‚an Indien'),
  (Value:10918;CountryName:'Irak'),
  (Value:10919;CountryName:'Iran'),
  (Value:10920;CountryName:'Islande'),
  (Value:10921;CountryName:'Italie'),
  (Value:10922;CountryName:'Jama‹que'),
  (Value:10923;CountryName:'Jordanie'),
  (Value:10924;CountryName:'Japon'),
  (Value:10925;CountryName:'Kenya'),
  (Value:10926;CountryName:'Kirghizistan'),
  (Value:10927;CountryName:'Cambodge'),
  (Value:10928;CountryName:'Kiribati'),
  (Value:10929;CountryName:'Comores'),
  (Value:10930;CountryName:'Saint-Christopher et Nevis (Iles)'),
  (Value:10931;CountryName:'Cor‚e, R‚publique d‚mocratique populaire de'),
  (Value:10932;CountryName:'Cor‚e, R‚publique de'),
  (Value:10933;CountryName:'Kowe‹t'),
  (Value:10934;CountryName:'Iles Ca‹mans'),
  (Value:10935;CountryName:'Kazakhstan'),
  (Value:10936;CountryName:'Laos, R‚publique D‚mocratique populaire du'),
  (Value:10937;CountryName:'Liban'),
  (Value:10938;CountryName:'Sainte-Lucie'),
  (Value:10939;CountryName:'Liechtenstein'),
  (Value:10940;CountryName:'Sri Lanka'),
  (Value:10941;CountryName:'Lib‚ria'),
  (Value:10942;CountryName:'Lesotho'),
  (Value:10943;CountryName:'Lituanie'),
  (Value:10944;CountryName:'Luxembourg'),
  (Value:10945;CountryName:'Lettonie'),
  (Value:10946;CountryName:'Jamahiriya arabe libyenne (Lybie)'),
  (Value:10947;CountryName:'Maroc'),
  (Value:10948;CountryName:'Monaco'),
  (Value:10949;CountryName:'Moldavie'),
  (Value:10950;CountryName:'Madagascar'),
  (Value:10951;CountryName:'Iles Marshall'),
  (Value:10952;CountryName:'Mac‚doine'),
  (Value:10953;CountryName:'Mali'),
  (Value:10954;CountryName:'Myanmar (Union de)'),
  (Value:10955;CountryName:'Mongolie'),
  (Value:10956;CountryName:'Macao'),
  (Value:10957;CountryName:'Mariannes du Nord'),
  (Value:10958;CountryName:'Martinique'),
  (Value:10959;CountryName:'Mauritanie'),
  (Value:10960;CountryName:'Montserrat'),
  (Value:10961;CountryName:'Malte'),
  (Value:10962;CountryName:'Ile Maurice'),
  (Value:10963;CountryName:'Maldives'),
  (Value:10964;CountryName:'Malawi'),
  (Value:10965;CountryName:'Mexique'),
  (Value:10966;CountryName:'Malaisie'),
  (Value:10967;CountryName:'Mozambique'),
  (Value:10968;CountryName:'Namibie'),
  (Value:10969;CountryName:'Nouvelle Cal‚donie'),
  (Value:10970;CountryName:'Niger'),
  (Value:10971;CountryName:'Ile de Norfolk'),
  (Value:10972;CountryName:'Nig‚ria'),
  (Value:10973;CountryName:'Nicaragua'),
  (Value:10974;CountryName:'Pays-Bas'),
  (Value:10975;CountryName:'NorvŠge'),
  (Value:10976;CountryName:'N‚pal'),
  (Value:10977;CountryName:'Nauru'),
  (Value:10978;CountryName:'Niue'),
  (Value:10979;CountryName:'Nouvelle Z‚lande'),
  (Value:10980;CountryName:'Oman'),
  (Value:10981;CountryName:'Panama'),
  (Value:10982;CountryName:'P‚rou'),
  (Value:10983;CountryName:'Polyn‚sie fran‡aise'),
  (Value:10984;CountryName:'Papouasie Nouvelle-Guin‚e'),
  (Value:10985;CountryName:'Philippines'),
  (Value:10986;CountryName:'Pakistan'),
  (Value:10987;CountryName:'Pologne'),
  (Value:10988;CountryName:'Saint-Pierre-et-Miquelon'),
  (Value:10989;CountryName:'Pitcairn'),
  (Value:10990;CountryName:'Porto Rico'),
  (Value:10991;CountryName:'Palestinian Territory, Occupied'),
  (Value:10992;CountryName:'Portugal'),
  (Value:10993;CountryName:'Palau'),
  (Value:10994;CountryName:'Paraguay'),
  (Value:10995;CountryName:'Qatar'),
  (Value:10996;CountryName:'R‚union (Ile de la)'),
  (Value:10997;CountryName:'Roumanie'),
  (Value:10998;CountryName:'F‚d‚ration de Russie'),
  (Value:10999;CountryName:'Rwanda'),
  (Value:11000;CountryName:'Arabie Saoudite'),
  (Value:11001;CountryName:'Iles Salomon'),
  (Value:11002;CountryName:'Seychelles'),
  (Value:11003;CountryName:'Soudan'),
  (Value:11004;CountryName:'SuŠde'),
  (Value:11005;CountryName:'Singapour'),
  (Value:11006;CountryName:'Sainte H‚lŠne'),
  (Value:11007;CountryName:'Slov‚nie'),
  (Value:11008;CountryName:'Svalbard'),
  (Value:11009;CountryName:'Slovaquie'),
  (Value:11010;CountryName:'Sierra Leone'),
  (Value:11011;CountryName:'Saint-Marin'),
  (Value:11012;CountryName:'S‚n‚gal'),
  (Value:11013;CountryName:'Somalie'),
  (Value:11014;CountryName:'Suriname'),
  (Value:11015;CountryName:'Sao Tom, et Prince'),
  (Value:11016;CountryName:'Salvador'),
  (Value:11017;CountryName:'R‚publique arabe syrienne'),
  (Value:11018;CountryName:'Swaziland'),
  (Value:11019;CountryName:'Iles Turks et Ca‹cos'),
  (Value:11020;CountryName:'Tchad'),
  (Value:11021;CountryName:'Terres Australes fran‡aises'),
  (Value:11022;CountryName:'Togo'),
  (Value:11023;CountryName:'Tha‹lande'),
  (Value:11024;CountryName:'Tajikistan'),
  (Value:11025;CountryName:'Iles Tokelau'),
  (Value:11026;CountryName:'Turkm‚nistan'),
  (Value:11027;CountryName:'Tunisie'),
  (Value:11028;CountryName:'Tonga'),
  (Value:11029;CountryName:'Timor oriental'),
  (Value:11030;CountryName:'Turquie'),
  (Value:11031;CountryName:'Trinit‚-et-Tobago'),
  (Value:11032;CountryName:'Tuvalu (Iles)'),
  (Value:11033;CountryName:'Taiwan'),
  (Value:11034;CountryName:'Tanzanie'),
  (Value:11035;CountryName:'Ukraine'),
  (Value:11036;CountryName:'Uganda'),
  (Value:11037;CountryName:'D‚pendances am‚ricaines du Pacifique'),
  (Value:11038;CountryName:'tats-Unis'),
  (Value:11039;CountryName:'Uruguay'),
  (Value:11040;CountryName:'Ouzb‚kistan'),
  (Value:11041;CountryName:'tat de la cit‚ du Vatican'),
  (Value:11042;CountryName:'Saint-Vincent et les Grenadines'),
  (Value:11043;CountryName:'Venezuela'),
  (Value:11044;CountryName:'Iles Vierges britanniques'),
  (Value:11045;CountryName:'Iles Vierges am‚ricaines'),
  (Value:11046;CountryName:'Vietnam'),
  (Value:11047;CountryName:'Vanuatu'),
  (Value:11048;CountryName:'Wallis et Futuna'),
  (Value:11049;CountryName:'Samoa'),
  (Value:11050;CountryName:'Y‚men'),
  (Value:11051;CountryName:'Mayotte'),
  (Value:11052;CountryName:'Yougoslavie'),
  (Value:11053;CountryName:'Afrique du Sud'),
  (Value:11054;CountryName:'Zambie'),
  (Value:11055;CountryName:'Zaire'),
  (Value:11056;CountryName:'Zimbabwe')

 );

 IPNetRangeList:Array[0..1074]of IPNetRange=(
  (A_IP1:70; A_IP2:80; A_IP3:0;   A_IP4:0;
   B_IP1:70; B_IP2:83; B_IP3:255; B_IP4:255;
   OrgName:'Le Groupe Videotron Ltee';
   Country:10851),

  (A_IP1:70; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:70; B_IP2:14; B_IP3:255; B_IP4:255;
   OrgName:'Sprint PCS';
   Country:11038),

  (A_IP1:70; A_IP2:43; A_IP3:0; A_IP4:0;
   B_IP1:70; B_IP2:43; B_IP3:127; B_IP4:255;
   OrgName:'NuVox Communications, Inc.';
   Country:11038),

  (A_IP1:70; A_IP2:44; A_IP3:0; A_IP4:0;
   B_IP1:70; B_IP2:44; B_IP3:63; B_IP4:255;
   OrgName:'PenTeleData Inc. - Cable';
   Country:11038),

  (A_IP1:80; A_IP2:201; A_IP3:16; A_IP4:0;
   B_IP1:80; B_IP2:201; B_IP3:31; B_IP4:255;
   OrgName:'Belgacom SA de droit public, ANS/ROC/RNO/IEC - TGX Building';
   Country:10835),

  (A_IP1:82; A_IP2:67; A_IP3:10; A_IP4:0;
   B_IP1:82; B_IP2:67; B_IP3:11; B_IP4:255;
   OrgName:'Free SAS / ProXad';
   Country:10887),

  (A_IP1:82; A_IP2:113; A_IP3:18; A_IP4:0;
   B_IP1:82; B_IP2:113; B_IP3:23; B_IP4:255;
   OrgName:'Monaco Telecom';
   Country:10948),

  (A_IP1:83; A_IP2:195; A_IP3:0; A_IP4:0;
   B_IP1:83; B_IP2:205; B_IP3:255; B_IP4:255;
   OrgName:'Wanadoo France';
   Country:10887),

  (A_IP1:65; A_IP2:19; A_IP3:128; A_IP4:0;
   B_IP1:65; B_IP2:19; B_IP3:191; B_IP4:255;
   OrgName:'Hurricane Electric';
   Country:11038),

  (A_IP1:81; A_IP2:57; A_IP3:206; A_IP4:0;
   B_IP1:81; B_IP2:57; B_IP3:207; B_IP4:255;
   OrgName:'Free SAS / ProXad - France';
   Country:10887),

  (A_IP1:83; A_IP2:206; A_IP3:0; A_IP4:0;
   B_IP1:83; B_IP2:206; B_IP3:3; B_IP4:255;
   OrgName:'ALL RUNNET (Oleane.fr)';
   Country:10887),

  (A_IP1:207; A_IP2:253; A_IP3:0; A_IP4:0;
   B_IP1:207; B_IP2:253; B_IP3:255; B_IP4:255;
   OrgName:'Videotron Telecom Ltee';
   Country:10851),

  (A_IP1:193; A_IP2:95; A_IP3:44; A_IP4:0;
   B_IP1:193; B_IP2:95; B_IP3:44; B_IP4:255;
   OrgName:'Centre National d''Informatique';
   Country:11027),

  (A_IP1:212; A_IP2:78; A_IP3:160; A_IP4:0;
   B_IP1:212; B_IP2:78; B_IP3:191; B_IP4:255;
   OrgName:'COLT Telecom GmbH';
   Country:10869),

  (A_IP1:82; A_IP2:125; A_IP3:197; A_IP4:0;
   B_IP1:82; B_IP2:127; B_IP3:255; B_IP4:255;
   OrgName:'France Telecom - Wanadoo France';
   Country:10887),

  (A_IP1:212; A_IP2:78; A_IP3:192; A_IP4:0;
   B_IP1:212; B_IP2:78; B_IP3:206; B_IP4:255;
   OrgName:'Webcenter hosting - Lycos Europe';
   Country:10869),

  (A_IP1:213; A_IP2:140; A_IP3:56; A_IP4:0;
   B_IP1:213; B_IP2:140; B_IP3:59; B_IP4:255;
   OrgName:'MPTA Algerie';
   Country:10874),

  (A_IP1:24; A_IP2:200; A_IP3:0; A_IP4:0;
   B_IP1:24; B_IP2:203; B_IP3:255; B_IP4:255;
   OrgName:'Le Groupe Videotron Ltee';
   Country:10851),

  (A_IP1:82; A_IP2:230; A_IP3:20; A_IP4:0;
   B_IP1:82; B_IP2:230; B_IP3:21; B_IP4:255;
   OrgName:'Free SAS / ProXad - France';
   Country:10887),

  (A_IP1:66; A_IP2:249; A_IP3:64; A_IP4:0;
   B_IP1:66; B_IP2:249; B_IP3:95; B_IP4:255;
   OrgName:'Google Inc.';
   Country:11038),

  (A_IP1:65; A_IP2:92; A_IP3:0; A_IP4:0;
   B_IP1:65; B_IP2:95; B_IP3:255; B_IP4:255;
   OrgName:'Bell Canada (Sympatico)';
   Country:10851),

  (A_IP1:196; A_IP2:207; A_IP3:192; A_IP4:0;
   B_IP1:196; B_IP2:207; B_IP3:255; B_IP4:255;
   OrgName:'African Internet Numbers Registry';
   Country:11012),

  (A_IP1:196; A_IP2:206; A_IP3:0; A_IP4:0;
   B_IP1:196; B_IP2:206; B_IP3:255; B_IP4:255;
   OrgName:'African Internet Numbers Registry';
   Country:10947),

  (A_IP1:81; A_IP2:57; A_IP3:206; A_IP4:0;
   B_IP1:81; B_IP2:57; B_IP3:207; B_IP4:255;
   OrgName:'Free SAS / ProXad - France';
   Country:10887),

  (A_IP1:65; A_IP2:19; A_IP3:128; A_IP4:0;
   B_IP1:65; B_IP2:19; B_IP3:191; B_IP4:255;
   OrgName:'Hurricane Electric';
   Country:11038),

  (A_IP1:83; A_IP2:195; A_IP3:0; A_IP4:0;
   B_IP1:83; B_IP2:205; B_IP3:255; B_IP4:255;
   OrgName:'Wanadoo France';
   Country:10887),

  (A_IP1:82; A_IP2:113; A_IP3:18; A_IP4:0;
   B_IP1:82; B_IP2:113; B_IP3:23; B_IP4:255;
   OrgName:'Monaco Telecom';
   Country:10948),

  (A_IP1:82; A_IP2:67; A_IP3:10; A_IP4:0;
   B_IP1:82; B_IP2:67; B_IP3:11; B_IP4:255;
   OrgName:'Free SAS / ProXad';
   Country:10887),

  (A_IP1:80; A_IP2:201; A_IP3:16; A_IP4:0;
   B_IP1:80; B_IP2:201; B_IP3:31; B_IP4:255;
   OrgName:'Belgacom SA de droit public, ANS/ROC/RNO/IEC - TGX Building';
   Country:10835),

  (A_IP1:70; A_IP2:44; A_IP3:0; A_IP4:0;
   B_IP1:70; B_IP2:44; B_IP3:63; B_IP4:255;
   OrgName:'PenTeleData Inc. - Cable';
   Country:11038),

  (A_IP1:70; A_IP2:43; A_IP3:0; A_IP4:0;
   B_IP1:70; B_IP2:43; B_IP3:127; B_IP4:255;
   OrgName:'NuVox Communications, Inc.';
   Country:11038),

  (A_IP1:70; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:70; B_IP2:14; B_IP3:255; B_IP4:255;
   OrgName:'Sprint PCS';
   Country:11038),

  (A_IP1:70; A_IP2:80; A_IP3:0; A_IP4:0;
   B_IP1:70; B_IP2:83; B_IP3:255; B_IP4:255;
   OrgName:'Le Groupe Videotron Ltee';
   Country:10851),

  (A_IP1:207; A_IP2:253; A_IP3:180; A_IP4:0;
   B_IP1:207; B_IP2:253; B_IP3:180; B_IP4:255;
   OrgName:'Netgraphe Communication inc.';
   Country:10851),

  (A_IP1:192; A_IP2:168; A_IP3:0; A_IP4:0;
   B_IP1:192; B_IP2:168; B_IP3:255; B_IP4:255;
   OrgName:'R‚seau local';
   Country:0),

  (A_IP1:84; A_IP2:4; A_IP3:0; A_IP4:0;
   B_IP1:84; B_IP2:7; B_IP3:216; B_IP4:255;
   OrgName:'INTERNET RESIDENTIEL CEGETEL France';
   Country:10887),

  (A_IP1:217; A_IP2:128; A_IP3:75; A_IP4:0;
   B_IP1:217; B_IP2:128; B_IP3:75; B_IP4:255;
   OrgName:'Wanadoo France';
   Country:10887),

  (A_IP1:217; A_IP2:74; A_IP3:99; A_IP4:0;
   B_IP1:217; B_IP2:74; B_IP3:99; B_IP4:255;
   OrgName:'Externall - Europe ASP';
   Country:10887),

  (A_IP1:81; A_IP2:22; A_IP3:64; A_IP4:0;
   B_IP1:81; B_IP2:22; B_IP3:64; B_IP4:255;
   OrgName:'EEPAD ISP';
   Country:10874),

  (A_IP1:82; A_IP2:128; A_IP3:0; A_IP4:0;
   B_IP1:82; B_IP2:128; B_IP3:31; B_IP4:255;
   OrgName:'Multi-Links Telecommunications Limited';
   Country:10972),

  (A_IP1:87; A_IP2:89; A_IP3:76; A_IP4:0;
   B_IP1:87; B_IP2:90; B_IP3:255; B_IP4:255;
   OrgName:'T-Online France - Club Internet';
   Country:10887),

  (A_IP1:198; A_IP2:103; A_IP3:223; A_IP4:0;
   B_IP1:198; B_IP2:103; B_IP3:223; B_IP4:255;
   OrgName:'D‚veloppement social Canada (sdc-dsc.gc.ca)';
   Country:10851),

  (A_IP1:198; A_IP2:103; A_IP3:0; A_IP4:0;
   B_IP1:198; B_IP2:103; B_IP3:255; B_IP4:255;
   OrgName:'GTIS';
   Country:10851),

  (A_IP1:216; A_IP2:13; A_IP3:0; A_IP4:0;
   B_IP1:216; B_IP2:13; B_IP3:255; B_IP4:255;
   OrgName:'Allstream Corp. Corporation Allstream';
   Country:10851),

  (A_IP1:10; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:10; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Internet Assigned Numbers Authority';
   Country:11038),

  (A_IP1:11; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:11; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'DoD Intel Information Systems/Defense Intelligence Agency';
   Country:11038),

  (A_IP1:12; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:12; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'AT&T WorldNet Services';
   Country:11038),

  (A_IP1:13; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:13; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Xerox Palo Alto Research Center';
   Country:11038),

  (A_IP1:14; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:14; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Internet Assigned Numbers Authority';
   Country:11038),

  (A_IP1:15; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:16; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Hewlett-Packard Company';
   Country:11038),

  (A_IP1:17; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:17; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Apple Computer, Inc.';
   Country:11038),

  (A_IP1:18; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:18; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Massachusetts Institute of Technology';
   Country:11038),

  (A_IP1:19; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:19; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Ford Motor Company';
   Country:11038),

  (A_IP1:20; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:20; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Computer Sciences Corporation';
   Country:11038),

  (A_IP1:21; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:21; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'DoD Network Information Center';
   Country:11038),

  (A_IP1:22; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:22; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Defense Information Systems Agency';
   Country:11038),

  (A_IP1:23; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:23; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Internet Assigned Numbers Authority';
   Country:11038),

  (A_IP1:24; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:24; B_IP2:15; B_IP3:255; B_IP4:255;
   OrgName:'Comcast Cable Communications, IP Services';
   Country:11038),

  (A_IP1:9; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:9; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'IBM Corporation';
   Country:11038),

  (A_IP1:8; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:8; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Level 3 Communications, Inc.';
   Country:11038),

  (A_IP1:7; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:7; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Defense Information Systems Agency';
   Country:11038),

  (A_IP1:6; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:6; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Army Information Systems Center (U.S. Army Yuma Proving Ground)';
   Country:11038),

  (A_IP1:5; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:5; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Internet Assigned Numbers Authority';
   Country:11038),

  (A_IP1:4; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:4; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Level 3 Communications, Inc.';
   Country:11038),

  (A_IP1:3; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:3; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'General Electric Company';
   Country:11038),

  (A_IP1:0; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:2; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Internet Assigned Numbers Authority';
   Country:11038),

  (A_IP1:25; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:25; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'DINSA, Ministry of Defence';
   Country:10890),

  (A_IP1:26; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:26; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Defense Information Systems Agency';
   Country:11038),

  (A_IP1:27; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:27; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Internet Assigned Numbers Authority';
   Country:11038),

  (A_IP1:28; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:28; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'ARPA DSI JPO';
   Country:11038),

  (A_IP1:29; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:30; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Defense Information Systems Agency';
   Country:11038),

  (A_IP1:31; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:31; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Internet Assigned Numbers Authority';
   Country:11038),

  (A_IP1:32; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:32; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'AT&T Global Network Services';
   Country:11038),

  (A_IP1:33; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:33; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'DoD Network Information Center';
   Country:11038),

  (A_IP1:35; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:35; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Merit Network Inc.';
   Country:11038),

  (A_IP1:36; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:37; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Internet Assigned Numbers Authority';
   Country:11038),

  (A_IP1:38; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:38; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Performance Systems International Inc.';
   Country:11038),

  (A_IP1:39; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:39; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Internet Assigned Numbers Authority';
   Country:11038),

  (A_IP1:40; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:40; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Eli Lilly and Company';
   Country:11038),

  (A_IP1:43; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:43; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Japan Inet';
   Country:10924),

  (A_IP1:44; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:44; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Amateur Radio Digital Communications';
   Country:11038),

  (A_IP1:45; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:45; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Interop Show Network';
   Country:11038),

  (A_IP1:47; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:47; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Bell-Northern Research';
   Country:10851),

  (A_IP1:48; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:48; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Prudential Securities Inc.';
   Country:11038),

  (A_IP1:51; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:51; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Department of Social Security of UK';
   Country:10890),

  (A_IP1:52; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:52; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'E.I. du Pont de Nemours and Co., Inc.';
   Country:11038),

  (A_IP1:53; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:53; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Cap Debis Ccs';
   Country:10869),

  (A_IP1:54; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:54; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Merck and Co., Inc.';
   Country:11038),

  (A_IP1:56; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:56; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'U.S. Postal Service';
   Country:11038),

  (A_IP1:57; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:57; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Soci‚t‚ Internationale de T‚l‚communications A‚ronautiques (SITA)';
   Country:10887),

  (A_IP1:58; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:58; B_IP2:1; B_IP3:255; B_IP4:255;
   OrgName:'Fujitsu Ltd.';
   Country:10924),

  (A_IP1:58; A_IP2:2; A_IP3:0; A_IP4:0;
   B_IP1:58; B_IP2:2; B_IP3:255; B_IP4:255;
   OrgName:'Gecis- Global Business Organisation';
   Country:10916),

  (A_IP1:58; A_IP2:3; A_IP3:0; A_IP4:0;
   B_IP1:58; B_IP2:3; B_IP3:127; B_IP4:255;
   OrgName:'Kyushu Telecommunication Network Co., Inc.';
   Country:10924),

  (A_IP1:58; A_IP2:4; A_IP3:0; A_IP4:0;
   B_IP1:58; B_IP2:5; B_IP3:255; B_IP4:255;
   OrgName:'U''s Communications Corp.';
   Country:10924),

  (A_IP1:58; A_IP2:6; A_IP3:0; A_IP4:0;
   B_IP1:58; B_IP2:6; B_IP3:0; B_IP4:31;
   OrgName:'Grigor Investments Pty Ltd';
   Country:10829),

  (A_IP1:60; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:60; B_IP2:10; B_IP3:255; B_IP4:255;
   OrgName:'CNCGROUP Hebei Province Network/China Network Communications Group Corporation';
   Country:10861),

  (A_IP1:66; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:0; B_IP3:255; B_IP4:255;
   OrgName:'ITC Deltacom';
   Country:11038),

  (A_IP1:66; A_IP2:1; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:1; B_IP3:255; B_IP4:255;
   OrgName:'SPRINT BWG';
   Country:11038),

  (A_IP1:66; A_IP2:2; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:3; B_IP3:255; B_IP4:255;
   OrgName:'XO Communications';
   Country:11038),

  (A_IP1:66; A_IP2:4; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:5; B_IP3:255; B_IP4:255;
   OrgName:'State of Tennessee Department of Education';
   Country:11038),

  (A_IP1:66; A_IP2:6; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:15; B_IP4:255;
   OrgName:'Mindsync Corporation';
   Country:11038),

  (A_IP1:66; A_IP2:6; A_IP3:16; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:31; B_IP4:255;
   OrgName:'Sobonito Investments ltd.';
   Country:11038),

  (A_IP1:66; A_IP2:6; A_IP3:32; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:47; B_IP4:255;
   OrgName:'MidWest Communications, Inc.';
   Country:11038),

  (A_IP1:66; A_IP2:6; A_IP3:48; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:63; B_IP4:255;
   OrgName:'Momentous';
   Country:10851),

  (A_IP1:66; A_IP2:6; A_IP3:64; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:79; B_IP4:255;
   OrgName:'Connecticut Telephone Incorporated';
   Country:11038),

  (A_IP1:67; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:67; B_IP2:7; B_IP3:255; B_IP4:255;
   OrgName:'Qwest Communications Corporation';
   Country:11038),

  (A_IP1:68; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:68; B_IP2:15; B_IP3:255; B_IP4:255;
   OrgName:'Cox Communications Inc.';
   Country:11038),

  (A_IP1:66; A_IP2:6; A_IP3:80; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:95; B_IP4:255;
   OrgName:'Equiva Services LLC';
   Country:11038),

  (A_IP1:66; A_IP2:6; A_IP3:96; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:127; B_IP4:255;
   OrgName:'Lighthouse Communications, Inc.';
   Country:11038),

  (A_IP1:66; A_IP2:6; A_IP3:128; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:143; B_IP4:255;
   OrgName:'SKYWEB, INC.';
   Country:11038),

  (A_IP1:66; A_IP2:6; A_IP3:144; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:144; B_IP4:255;
   OrgName:'Manheim Auctions';
   Country:11038),

  (A_IP1:69; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:69; B_IP2:0; B_IP3:127; B_IP4:255;
   OrgName:'SBC Internet Services';
   Country:11038),

  (A_IP1:69; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:69; B_IP2:0; B_IP3:0; B_IP4:7;
   OrgName:'The Medicine Shoppe';
   Country:11038),

  (A_IP1:69; A_IP2:0; A_IP3:128; A_IP4:0;
   B_IP1:69; B_IP2:0; B_IP3:255; B_IP4:255;
   OrgName:'Interland';
   Country:11038),

  (A_IP1:69; A_IP2:1; A_IP3:0; A_IP4:0;
   B_IP1:69; B_IP2:1; B_IP3:63; B_IP4:255;
   OrgName:'KNOLOGY Holdings, Inc.';
   Country:11038),

  (A_IP1:69; A_IP2:1; A_IP3:64; A_IP4:0;
   B_IP1:69; B_IP2:1; B_IP3:95; B_IP4:255;
   OrgName:'WCIX.Net, Inc.';
   Country:11038),

  (A_IP1:69; A_IP2:1; A_IP3:96; A_IP4:0;
   B_IP1:69; B_IP2:1; B_IP3:127; B_IP4:255;
   OrgName:'Northwest Open Access Network Oregon, Inc.';
   Country:11038),

  (A_IP1:69; A_IP2:1; A_IP3:128; A_IP4:0;
   B_IP1:69; B_IP2:1; B_IP3:159; B_IP4:255;
   OrgName:'Indiana Data Center, LLC';
   Country:11038),

  (A_IP1:80; A_IP2:170; A_IP3:0; A_IP4:0;
   B_IP1:80; B_IP2:170; B_IP3:127; B_IP4:255;
   OrgName:'TELE2 FRANCE S.A / TELE2/SWIPNET';
   Country:10887),

  (A_IP1:212; A_IP2:195; A_IP3:64; A_IP4:0;
   B_IP1:212; B_IP2:195; B_IP3:255; B_IP4:255;
   OrgName:'T-Online France - Club Internet';
   Country:10887),

  (A_IP1:216; A_IP2:252; A_IP3:128; A_IP4:0;
   B_IP1:216; B_IP2:252; B_IP3:255; B_IP4:255;
   OrgName:'SES Americom Inc.';
   Country:11038),

  (A_IP1:62; A_IP2:161; A_IP3:71; A_IP4:0;
   B_IP1:62; B_IP2:161; B_IP3:71; B_IP4:255;
   OrgName:'CCBP (France Telecom Transpac)';
   Country:10887),

  (A_IP1:66; A_IP2:6; A_IP3:160; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:175; B_IP4:255;
   OrgName:'PurchasePro.com';
   Country:11038),

  (A_IP1:66; A_IP2:6; A_IP3:176; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:191; B_IP4:255;
   OrgName:'Dial Assurance, Inc.';
   Country:11038),

  (A_IP1:66; A_IP2:6; A_IP3:192; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:207; B_IP4:255;
   OrgName:'Waymark Internet Services, Inc.';
   Country:11038),

  (A_IP1:66; A_IP2:6; A_IP3:208; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:223; B_IP4:255;
   OrgName:'Tierzero';
   Country:11038),

  (A_IP1:66; A_IP2:6; A_IP3:208; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:208; B_IP4:255;
   OrgName:'MmicMan LLC';
   Country:11038),

  (A_IP1:71; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:71; B_IP2:3; B_IP3:255; B_IP4:255;
   OrgName:'Sprint DSL Network';
   Country:11038),

  (A_IP1:72; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:72; B_IP2:0; B_IP3:31; B_IP4:255;
   OrgName:'CITISTREET';
   Country:11038),

  (A_IP1:73; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:73; B_IP2:191; B_IP3:255; B_IP4:255;
   OrgName:'Comcast IP Services, L.L.C.';
   Country:11038),

  (A_IP1:74; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:74; B_IP2:1; B_IP3:255; B_IP4:255;
   OrgName:'Covad Communications Co.';
   Country:11038),

  (A_IP1:77; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:79; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Internet Assigned Numbers Authority';
   Country:11038),

  (A_IP1:85; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:85; B_IP2:7; B_IP3:255; B_IP4:255;
   OrgName:'Swisscom IP-Plus/Swisscom Fixnet AG';
   Country:10856),

  (A_IP1:86; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:86; B_IP2:0; B_IP3:31; B_IP4:255;
   OrgName:'NTLI Network Management Centre';
   Country:10890),

  (A_IP1:87; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:87; B_IP2:31; B_IP3:255; B_IP4:255;
   OrgName:'Telecom Italia Net';
   Country:10921),

  (A_IP1:88; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:88; B_IP2:3; B_IP3:212; B_IP4:255;
   OrgName:'Telefonica de Espana';
   Country:10880),

  (A_IP1:80; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:91; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'European Regional Registry';
   Country:10974),

  (A_IP1:92; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:120; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Internet Assigned Numbers Authority';
   Country:11038),

  (A_IP1:121; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:122; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Asia Pacific Network Information Centre';
   Country:10829),

  (A_IP1:80; A_IP2:249; A_IP3:64; A_IP4:0;
   B_IP1:80; B_IP2:249; B_IP3:79; B_IP4:255;
   OrgName:'African Internet Numbers Registry';
   Country:10874),

  (A_IP1:80; A_IP2:249; A_IP3:80; A_IP4:0;
   B_IP1:80; B_IP2:249; B_IP3:83; B_IP4:255;
   OrgName:'Consolidated Webmaster Corp';
   Country:11038),

  (A_IP1:124; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:124; B_IP2:0; B_IP3:15; B_IP4:255;
   OrgName:'SK Networks co., Ltd';
   Country:10932),

  (A_IP1:125; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:125; B_IP2:1; B_IP3:255; B_IP4:255;
   OrgName:'Fujitsu Ltd.';
   Country:10924),

  (A_IP1:126; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:126; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Japan Nation-wide Network of Softbank BB Corp.';
   Country:10924),

  (A_IP1:133; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:133; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Japan Network Information Center';
   Country:10924),

  (A_IP1:145; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:145; B_IP2:127; B_IP3:255; B_IP4:255;
   OrgName:'SURFnet Network Services';
   Country:10974),

  (A_IP1:66; A_IP2:65; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:67; B_IP3:255; B_IP4:255;
   OrgName:'Road Runner';
   Country:11038),

  (A_IP1:66; A_IP2:70; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:70; B_IP3:127; B_IP4:255;
   OrgName:'DataPipe';
   Country:11038),

  (A_IP1:66; A_IP2:70; A_IP3:128; A_IP4:0;
   B_IP1:66; B_IP2:70; B_IP3:255; B_IP4:255;
   OrgName:'OLM,LLC';
   Country:11038),

  (A_IP1:66; A_IP2:72; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:72; B_IP3:0; B_IP4:7;
   OrgName:'Chateau Communities';
   Country:11038),

  (A_IP1:66; A_IP2:74; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:75; B_IP3:255; B_IP4:255;
   OrgName:'Road Runner';
   Country:11038),

  (A_IP1:66; A_IP2:76; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:76; B_IP3:255; B_IP4:255;
   OrgName:'Cox Communications Inc.';
   Country:11038),

  (A_IP1:66; A_IP2:78; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:78; B_IP3:63; B_IP4:255;
   OrgName:'Virtual Development INC';
   Country:11038),

  (A_IP1:66; A_IP2:78; A_IP3:64; A_IP4:0;
   B_IP1:66; B_IP2:78; B_IP3:95; B_IP4:255;
   OrgName:'Internet Professionals & Network Solutions';
   Country:11038),

  (A_IP1:66; A_IP2:79; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:79; B_IP3:95; B_IP4:255;
   OrgName:'Mebtel Communications';
   Country:11038),

  (A_IP1:66; A_IP2:79; A_IP3:96; A_IP4:0;
   B_IP1:66; B_IP2:79; B_IP3:111; B_IP4:255;
   OrgName:'e-annix';
   Country:11038),

  (A_IP1:66; A_IP2:80; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:80; B_IP3:255; B_IP4:255;
   OrgName:'MegaPath Networks Inc.';
   Country:11038),

  (A_IP1:66; A_IP2:82; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:82; B_IP3:255; B_IP4:255;
   OrgName:'Hughes Network Systems';
   Country:11038),

  (A_IP1:66; A_IP2:84; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:84; B_IP3:63; B_IP4:255;
   OrgName:'Jumpline Inc';
   Country:11038),

  (A_IP1:66; A_IP2:84; A_IP3:64; A_IP4:0;
   B_IP1:66; B_IP2:84; B_IP3:95; B_IP4:255;
   OrgName:'Visual Link';
   Country:11038),

  (A_IP1:66; A_IP2:88; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:89; B_IP3:255; B_IP4:255;
   OrgName:'XO Communications';
   Country:11038),

  (A_IP1:66; A_IP2:90; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:90; B_IP3:63; B_IP4:255;
   OrgName:'Smart City';
   Country:11038),

  (A_IP1:66; A_IP2:90; A_IP3:64; A_IP4:0;
   B_IP1:66; B_IP2:90; B_IP3:127; B_IP4:255;
   OrgName:'FDC Servers.net, LLC';
   Country:11038),

  (A_IP1:66; A_IP2:94; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:94; B_IP3:31; B_IP4:255;
   OrgName:'T-Mobile USA';
   Country:11038),

  (A_IP1:61; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:61; B_IP2:3; B_IP3:255; B_IP4:255;
   OrgName:'Bharat Sanchar Nigam Limited';
   Country:10916),

  (A_IP1:61; A_IP2:4; A_IP3:0; A_IP4:0;
   B_IP1:61; B_IP2:4; B_IP3:63; B_IP4:255;
   OrgName:'Eastar Technology';
   Country:10907),

  (A_IP1:61; A_IP2:4; A_IP3:64; A_IP4:0;
   B_IP1:61; B_IP2:4; B_IP3:79; B_IP4:255;
   OrgName:'CBBN.NET, Internet Service Provider';
   Country:10861),

  (A_IP1:66; A_IP2:6; A_IP3:209; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:210; B_IP4:255;
   OrgName:'Paridox Ventures, Inc';
   Country:11038),

  (A_IP1:66; A_IP2:6; A_IP3:211; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:211; B_IP4:255;
   OrgName:'XpressBet (Ventures LLC)';
   Country:11038),

  (A_IP1:66; A_IP2:6; A_IP3:212; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:213; B_IP4:255;
   OrgName:'Webkeepers';
   Country:11038),

  (A_IP1:66; A_IP2:6; A_IP3:214; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:215; B_IP4:255;
   OrgName:'Paridox Ventures, Inc';
   Country:11038),

  (A_IP1:66; A_IP2:6; A_IP3:216; A_IP4:0;
   B_IP1:66; B_IP2:6; B_IP3:216; B_IP4:31;
   OrgName:'MMICMAN, LLC';
   Country:11038),

  (A_IP1:66; A_IP2:6; A_IP3:216; A_IP4:32;
   B_IP1:66; B_IP2:6; B_IP3:216; B_IP4:63;
   OrgName:'Narcotics Anonymous World Services Inc.';
   Country:11038),

  (A_IP1:194; A_IP2:51; A_IP3:11; A_IP4:112;
   B_IP1:194; B_IP2:51; B_IP3:11; B_IP4:127;
   OrgName:'AON SGCA (Patrick Fournier) / R‚seaux d''AccŠs … l''INternet';
   Country:10887),

  (A_IP1:81; A_IP2:249; A_IP3:167; A_IP4:0;
   B_IP1:81; B_IP2:249; B_IP3:167; B_IP4:255;
   OrgName:'Wanadoo France';
   Country:10887),

  (A_IP1:81; A_IP2:192; A_IP3:100; A_IP4:0;
   B_IP1:81; B_IP2:192; B_IP3:100; B_IP4:255;
   OrgName:'Adsl Maroc Telecom';
   Country:10947),

  (A_IP1:67; A_IP2:70; A_IP3:140; A_IP4:0;
   B_IP1:67; B_IP2:70; B_IP3:143; B_IP4:255;
   OrgName:'Bell Sympatico';
   Country:10851),

  (A_IP1:67; A_IP2:68; A_IP3:0; A_IP4:0;
   B_IP1:67; B_IP2:71; B_IP3:255; B_IP4:255;
   OrgName:'Bell Canada';
   Country:10851),

  (A_IP1:83; A_IP2:182; A_IP3:0; A_IP4:0;
   B_IP1:83; B_IP2:182; B_IP3:255; B_IP4:255;
   OrgName:'TELE2 Belgium';
   Country:11004),

  (A_IP1:82; A_IP2:248; A_IP3:0; A_IP4:0;
   B_IP1:82; B_IP2:255; B_IP3:255; B_IP4:255;
   OrgName:'Proxad / Free SAS';
   Country:10887),

  (A_IP1:68; A_IP2:236; A_IP3:0; A_IP4:0;
   B_IP1:68; B_IP2:239; B_IP3:255; B_IP4:255;
   OrgName:'Verizon Internet Services Inc.';
   Country:11038),

  (A_IP1:216; A_IP2:117; A_IP3:128; A_IP4:0;
   B_IP1:216; B_IP2:117; B_IP3:191; B_IP4:255;
   OrgName:'Advanced Internet Technologies, Inc.';
   Country:11038),

  (A_IP1:69; A_IP2:70; A_IP3:20; A_IP4:0;
   B_IP1:69; B_IP2:70; B_IP3:20; B_IP4:255;
   OrgName:'SAC Affaires VL';
   Country:10851),

  (A_IP1:195; A_IP2:93; A_IP3:64; A_IP4:0;
   B_IP1:195; B_IP2:93; B_IP3:127; B_IP4:25;
   OrgName:'America Online Inc.';
   Country:11038),

  (A_IP1:134; A_IP2:21; A_IP3:0; A_IP4:0;
   B_IP1:134; B_IP2:21; B_IP3:255; B_IP4:255;
   OrgName:'Universit‚ de Fribourg - Service Informatique';
   Country:10856),

  (A_IP1:195; A_IP2:212; A_IP3:49; A_IP4:64;
   B_IP1:195; B_IP2:212; B_IP3:49; B_IP4:127;
   OrgName:'Euroclear';
   Country:10835),

  (A_IP1:193; A_IP2:251; A_IP3:169; A_IP4:0;
   B_IP1:193; B_IP2:251; B_IP3:169; B_IP4:255;
   OrgName:'Complexe informatique PTT';
   Country:10874),

  (A_IP1:213; A_IP2:41; A_IP3:128; A_IP4:0;
   B_IP1:213; B_IP2:41; B_IP3:255; B_IP4:255;
   OrgName:'Nerim';
   Country:10887),

  (A_IP1:193; A_IP2:52; A_IP3:99; A_IP4:0;
   B_IP1:193; B_IP2:52; B_IP3:99; B_IP4:255;
   OrgName:'CRI de l''Universit‚ de Nantes';
   Country:10887),

  (A_IP1:213; A_IP2:180; A_IP3:232; A_IP4:0;
   B_IP1:213; B_IP2:180; B_IP3:235; B_IP4:255;
   OrgName:'EUTELSAT S.A. (European Telecommunications Satellite Organization)';
   Country:10887),

  (A_IP1:207; A_IP2:107; A_IP3:0; A_IP4:0;
   B_IP1:207; B_IP2:107; B_IP3:255; B_IP4:255;
   OrgName:'Sprint Canada Inc.';
   Country:10851),

  (A_IP1:132; A_IP2:203; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:203; B_IP3:255; B_IP4:255;
   OrgName:'Universit‚ Laval - Service de l''informatique et des t‚l‚communications';
   Country:10851),

  (A_IP1:24; A_IP2:122; A_IP3:0; A_IP4:0;
   B_IP1:24; B_IP2:122; B_IP3:239; B_IP4:255;
   OrgName:'COGECO Cable Canada Inc.';
   Country:10851),

  (A_IP1:142; A_IP2:217; A_IP3:0; A_IP4:0;
   B_IP1:142; B_IP2:217; B_IP3:255; B_IP4:255;
   OrgName:'Telebec';
   Country:10851),

  (A_IP1:213; A_IP2:150; A_IP3:160; A_IP4:0;
   B_IP1:213; B_IP2:150; B_IP3:191; B_IP4:255;
   OrgName:'Agence Tunisienne Internet - ATI';
   Country:11027),

  (A_IP1:217; A_IP2:136; A_IP3:204; A_IP4:0;
   B_IP1:217; B_IP2:136; B_IP3:204; B_IP4:255;
   OrgName:'Belgacom ISP SA/NV';
   Country:10835),

  (A_IP1:207; A_IP2:35; A_IP3:47; A_IP4:64;
   B_IP1:207; B_IP2:35; B_IP3:47; B_IP4:95;
   OrgName:'MPB Technologies';
   Country:10851),

  (A_IP1:207; A_IP2:35; A_IP3:0; A_IP4:0;
   B_IP1:207; B_IP2:35; B_IP3:255; B_IP4:255;
   OrgName:'Bell Canada';
   Country:10851),

  (A_IP1:65; A_IP2:92; A_IP3:16; A_IP4:0;
   B_IP1:65; B_IP2:92; B_IP3:31; B_IP4:255;
   OrgName:'Nexxia HSE';
   Country:10851),

  (A_IP1:172; A_IP2:16; A_IP3:0; A_IP4:0;
   B_IP1:172; B_IP2:31; B_IP3:255; B_IP4:255;
   OrgName:'Internet Assigned Numbers Authority';
   Country:11038),

  (A_IP1:64; A_IP2:86; A_IP3:140; A_IP4:0;
   B_IP1:64; B_IP2:86; B_IP3:141; B_IP4:255;
   OrgName:'Le Groupe CGI';
   Country:10851),

  (A_IP1:64; A_IP2:86; A_IP3:0; A_IP4:0;
   B_IP1:64; B_IP2:86; B_IP3:255; B_IP4:255;
   OrgName:'Teleglobe Inc.';
   Country:10851),

  (A_IP1:147; A_IP2:94; A_IP3:40; A_IP4:0;
   B_IP1:147; B_IP2:94; B_IP3:127; B_IP4:255;
   OrgName:'R‚seaux Universit‚ de Provence et Phocean';
   Country:10887),

  (A_IP1:137; A_IP2:91; A_IP3:0; A_IP4:0;
   B_IP1:137; B_IP2:91; B_IP3:255; B_IP4:255;
   OrgName:'Arizona Public Service Company';
   Country:10851),

  (A_IP1:69; A_IP2:72; A_IP3:128; A_IP4:0;
   B_IP1:69; B_IP2:72; B_IP3:255; B_IP4:255;
   OrgName:'Pegasus Web Technologies';
   Country:10851),

  (A_IP1:207; A_IP2:134; A_IP3:0; A_IP4:0;
   B_IP1:207; B_IP2:134; B_IP3:255; B_IP4:255;
   OrgName:'TELUS Communications Inc.';
   Country:10851),

  (A_IP1:213; A_IP2:223; A_IP3:113; A_IP4:0;
   B_IP1:213; B_IP2:223; B_IP3:119; B_IP4:255;
   OrgName:'Cegetel - DTI';
   Country:10887),

  (A_IP1:207; A_IP2:96; A_IP3:128; A_IP4:0;
   B_IP1:207; B_IP2:96; B_IP3:255; B_IP4:255;
   OrgName:'Videotron Telecom Ltee';
   Country:10851),

  (A_IP1:172; A_IP2:192; A_IP3:0; A_IP4:0;
   B_IP1:172; B_IP2:216; B_IP3:255; B_IP4:255;
   OrgName:'America Online';
   Country:11038),

  (A_IP1:164; A_IP2:81; A_IP3:0; A_IP4:0;
   B_IP1:164; B_IP2:81; B_IP3:255; B_IP4:255;
   OrgName:'Universit‚ de Limoges - Service Commun Informatique';
   Country:10887),

  (A_IP1:212; A_IP2:194; A_IP3:0; A_IP4:0;
   B_IP1:212; B_IP2:194; B_IP3:191; B_IP4:255;
   OrgName:'T-Online France - Club Internet';
   Country:10887),

  (A_IP1:66; A_IP2:130; A_IP3:0; A_IP4:0;
   B_IP1:66; B_IP2:131; B_IP3:255; B_IP4:255;
   OrgName:'Le Groupe Videotron Ltee';
   Country:10851),

  (A_IP1:193; A_IP2:47; A_IP3:80; A_IP4:0;
   B_IP1:193; B_IP2:47; B_IP3:80; B_IP4:255;
   OrgName:'Exalead S.A.';
   Country:10887),

  (A_IP1:216; A_IP2:254; A_IP3:128; A_IP4:0;
   B_IP1:216; B_IP2:254; B_IP3:223; B_IP4:255;
   OrgName:'Primus Telecommunications Canada Inc.';
   Country:10851),

  (A_IP1:206; A_IP2:162; A_IP3:128; A_IP4:0;
   B_IP1:206; B_IP2:162; B_IP3:191; B_IP4:255;
   OrgName:'TELUS Communications Inc.';
   Country:10851),

  (A_IP1:132; A_IP2:208; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:208; B_IP3:25; B_IP4:255;
   OrgName:'Universite du Quebec a Montreal (UQAM)';
   Country:10851),

  (A_IP1:207; A_IP2:176; A_IP3:202; A_IP4:64;
   B_IP1:207; B_IP2:176; B_IP3:202; B_IP4:95;
   OrgName:'Imextech Inc.';
   Country:10851),

  (A_IP1:207; A_IP2:176; A_IP3:128; A_IP4:0;
   B_IP1:207; B_IP2:176; B_IP3:255; B_IP4:255;
   OrgName:'UUNET Technologies, Inc.';
   Country:11038),

  (A_IP1:132; A_IP2:207; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:207; B_IP3:255; B_IP4:255;
   OrgName:'Ecole Polytechnique de Montreal';
   Country:10851),

  (A_IP1:132; A_IP2:209; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:209; B_IP3:255; B_IP4:255;
   OrgName:'Universit‚ du Qu‚bec … Trois-RiviŠres (UQTR)';
   Country:10851),

  (A_IP1:132; A_IP2:204; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:204; B_IP3:255; B_IP4:255;
   OrgName:'University of Montreal';
   Country:10851),

  (A_IP1:132; A_IP2:205; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:205; B_IP3:255; B_IP4:255;
   OrgName:'Concordia University';
   Country:10851),

  (A_IP1:132; A_IP2:202; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:202; B_IP3:255; B_IP4:255;
   OrgName:'Reseau Interordinateurs Scientifique Quebecois (RISQ)';
   Country:10851),

  (A_IP1:132; A_IP2:201; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:201; B_IP3:255; B_IP4:255;
   OrgName:'Southwestern Bell Telephone Company';
   Country:11038),

  (A_IP1:132; A_IP2:200; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:200; B_IP3:255; B_IP4:255;
   OrgName:'Federal Reserve Board';
   Country:11038),

  (A_IP1:132; A_IP2:210; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:210; B_IP3:255; B_IP4:255;
   OrgName:'Universit‚ de Sherbrooke';
   Country:10851),

  (A_IP1:132; A_IP2:211; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:211; B_IP3:255; B_IP4:255;
   OrgName:'Ecole des Hautes Etudes Commerciales (HEC)';
   Country:10851),

  (A_IP1:132; A_IP2:212; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:212; B_IP3:255; B_IP4:255;
   OrgName:'Universit‚ du Quebec … Chicoutimi (UQAC)';
   Country:10851),

  (A_IP1:132; A_IP2:213; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:213; B_IP3:255; B_IP4:255;
   OrgName:'Universit‚ du Qu‚bec … Hull (UQAH)';
   Country:10851),

  (A_IP1:132; A_IP2:214; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:214; B_IP3:255; B_IP4:255;
   OrgName:'T‚l‚-Universit‚';
   Country:10851),

  (A_IP1:132; A_IP2:215; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:215; B_IP3:255; B_IP4:255;
   OrgName:'Universit‚ du Qu‚bec … Rimouski (UQAR)';
   Country:10851),

  (A_IP1:132; A_IP2:216; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:216; B_IP3:255; B_IP4:255;
   OrgName:'McGill University';
   Country:10851),

  (A_IP1:132; A_IP2:217; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:219; B_IP3:255; B_IP4:255;
   OrgName:'Centre de Recherche Informatique de Montreal';
   Country:10851),

  (A_IP1:132; A_IP2:220; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:220; B_IP3:255; B_IP4:255;
   OrgName:'Sobeco Group, Inc.';
   Country:10851),

  (A_IP1:132; A_IP2:221; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:221; B_IP3:255; B_IP4:255;
   OrgName:'MinistŠre des Transports du Qu‚bec';
   Country:10851),

  (A_IP1:132; A_IP2:223; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:223; B_IP3:255; B_IP4:255;
   OrgName:'GenRad, Inc.';
   Country:11038),

  (A_IP1:132; A_IP2:1; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:1; B_IP3:255; B_IP4:255;
   OrgName:'SSG/SIN';
   Country:11038),

  (A_IP1:132; A_IP2:229; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:232; B_IP3:255; B_IP4:255;
   OrgName:'RIPE Network Coordination Centre';
   Country:10974),

  (A_IP1:132; A_IP2:240; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:240; B_IP3:255; B_IP4:255;
   OrgName:'Vitalink Communications';
   Country:11038),

  (A_IP1:132; A_IP2:250; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:250; B_IP3:255; B_IP4:255;
   OrgName:'Naval Research Laboratory';
   Country:11038),

  (A_IP1:132; A_IP2:251; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:251; B_IP3:255; B_IP4:255;
   OrgName:'Institute for Space and Terrestrial Science';
   Country:10851),

  (A_IP1:132; A_IP2:253; A_IP3:0; A_IP4:0;
   B_IP1:132; B_IP2:253; B_IP3:255; B_IP4:255;
   OrgName:'Parametric Technology Corporation';
   Country:11038),

  (A_IP1:207; A_IP2:61; A_IP3:255; A_IP4:128;
   B_IP1:207; B_IP2:61; B_IP3:255; B_IP4:191;
   OrgName:'Desjardins Securite financiere';
   Country:10851),

  (A_IP1:129; A_IP2:175; A_IP3:0; A_IP4:0;
   B_IP1:129; B_IP2:175; B_IP3:255; B_IP4:255;
   OrgName:'Universit‚ Paris-Sud - Centre de Ressources Informatique (CRI)';
   Country:10887),

  (A_IP1:217; A_IP2:136; A_IP3:0; A_IP4:0;
   B_IP1:217; B_IP2:136; B_IP3:31; B_IP4:255;
   OrgName:'Belgacom SA de droit public';
   Country:10835),

  (A_IP1:195; A_IP2:36; A_IP3:128; A_IP4:0;
   B_IP1:195; B_IP2:36; B_IP3:161; B_IP4:255;
   OrgName:'T-Online France - Club Internet';
   Country:10887),

  (A_IP1:194; A_IP2:2; A_IP3:88; A_IP4:0;
   B_IP1:194; B_IP2:2; B_IP3:95; B_IP4:255;
   OrgName:'Capgemini France';
   Country:10887),

  (A_IP1:193; A_IP2:50; A_IP3:159; A_IP4:0;
   B_IP1:193; B_IP2:50; B_IP3:159; B_IP4:255;
   OrgName:'Universit‚ de Marne La vall‚e';
   Country:10887),

  (A_IP1:212; A_IP2:194; A_IP3:192; A_IP4:0;
   B_IP1:212; B_IP2:195; B_IP3:63; B_IP4:255;
   OrgName:'T-Online France - Club Internet';
   Country:10887),

  (A_IP1:213; A_IP2:136; A_IP3:96; A_IP4:0;
   B_IP1:213; B_IP2:136; B_IP3:127; B_IP4:255;
   OrgName:'African Internet Numbers Registry';
   Country:10857),

  (A_IP1:194; A_IP2:250; A_IP3:235; A_IP4:88;
   B_IP1:194; B_IP2:250; B_IP3:235; B_IP4:95;
   OrgName:'France Telecom Transpac';
   Country:10887),

  (A_IP1:62; A_IP2:201; A_IP3:139; A_IP4:128;
   B_IP1:62; B_IP2:201; B_IP3:139; B_IP4:191;
   OrgName:'Bouygues Telecom RES Division for Customer DOS EuropaJ';
   Country:10887),

  (A_IP1:64; A_IP2:110; A_IP3:0; A_IP4:0;
   B_IP1:64; B_IP2:110; B_IP3:191; B_IP4:255;
   OrgName:'SES Americom Inc.';
   Country:11038),

  (A_IP1:206; A_IP2:97; A_IP3:32; A_IP4:0;
   B_IP1:206; B_IP2:99; B_IP3:119; B_IP4:255;
   OrgName:'Savvis';
   Country:11038),

  (A_IP1:206; A_IP2:98; A_IP3:253; A_IP4:0;
   B_IP1:206; B_IP2:98; B_IP3:255; B_IP4:255;
   OrgName:'SOTELGUI S.A.';
   Country:10898),

  (A_IP1:198; A_IP2:155; A_IP3:0; A_IP4:0;
   B_IP1:198; B_IP2:155; B_IP3:255; B_IP4:255;
   OrgName:'Bristol Myers Squibb Pharmaceutical Research Institute';
   Country:11038),

  (A_IP1:199; A_IP2:243; A_IP3:239; A_IP4:0;
   B_IP1:199; B_IP2:243; B_IP3:239; B_IP4:255;
   OrgName:'Mins - BAC Inc. / RTSS';
   Country:10851),

  (A_IP1:199; A_IP2:243; A_IP3:0; A_IP4:0;
   B_IP1:199; B_IP2:243; B_IP3:255; B_IP4:255;
   OrgName:'Bell Canada';
   Country:10851),

  (A_IP1:67; A_IP2:68; A_IP3:0; A_IP4:0;
   B_IP1:67; B_IP2:68; B_IP3:255; B_IP4:255;
   OrgName:'HSE';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:36; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:47; B_IP4:255;
   OrgName:'CollŠge de Maisonneuve';
   Country:10851),

  (A_IP1:81; A_IP2:199; A_IP3:50; A_IP4:0;
   B_IP1:81; B_IP2:199; B_IP3:51; B_IP4:255;
   OrgName:'Tech IP Planet - Gilat Satcom Range';
   Country:10915),

  (A_IP1:206; A_IP2:167; A_IP3:48; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:48; B_IP4:255;
   OrgName:'Productivity Point International';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:49; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:49; B_IP4:255;
   OrgName:'Communications MULTIMEDIA Enter-Net';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:35; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:35; B_IP4:255;
   OrgName:'Informatika';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:34; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:34; B_IP4:255;
   OrgName:'Web Option SNC';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:33; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:33; B_IP4:255;
   OrgName:'Jon Simon et Associes';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:32; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:32; B_IP4:255;
   OrgName:'Institut des communications graphiques du Qu‚bec';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:31; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:31; B_IP4:255;
   OrgName:'Ministre des Finances du Qu‚bec';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:30; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:30; B_IP4:255;
   OrgName:'CollŠge O''Sullivan de Montr‚al';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:28; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:29; B_IP4:255;
   OrgName:'R‚gie du bƒtiment du Qu‚bec';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:23; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:23; B_IP4:255;
   OrgName:'CEGEP de la r‚gion de l''amiante';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:22; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:22; B_IP4:255;
   OrgName:'Les Conseilleurs Inro Inc.';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:21; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:21; B_IP4:255;
   OrgName:'Mus‚e des Arts et Traditions populaires';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:20; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:20; B_IP4:255;
   OrgName:'Regroupement Loisir Qu‚bec';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:10; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:19; B_IP4:255;
   OrgName:'C‚gep de Victoriaville';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:8; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:9; B_IP4:255;
   OrgName:'Locus Speech Corporation';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:4; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:7; B_IP4:255;
   OrgName:'MinistŠre des Affaires Internationales du Qu‚bec';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:3; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:3; B_IP4:255;
   OrgName:'Commission des normes du travail du Qu‚bec';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:2; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:2; B_IP4:255;
   OrgName:'Ministre des Finances du Qu‚bec';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:50; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:50; B_IP4:255;
   OrgName:'FONEX DATA Systems Inc.';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:51; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:51; B_IP4:255;
   OrgName:'Commission Scolaire des D‚couvreurs';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:52; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:52; B_IP4:255;
   OrgName:'MinistŠre de la Sant‚ et des Services Sociaux du Qu‚bec';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:53; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:53; B_IP4:255;
   OrgName:'Commission scolaire Saint-Jean-sur-Richelieu';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:54; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:54; B_IP4:255;
   OrgName:'Centre informatique des CEGEPs du Saguenay-Lac-Saint-Jean';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:55; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:55; B_IP4:255;
   OrgName:'Digital Design Lt‚e';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:56; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:56; B_IP4:255;
   OrgName:'IEPF';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:58; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:60; B_IP4:255;
   OrgName:'Direction de la sant‚ publique du Qu‚bec';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:61; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:61; B_IP4:255;
   OrgName:'National Capital Commission';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:62; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:62; B_IP4:255;
   OrgName:'Microtec Technologies Inc.';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:63; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:63; B_IP4:255;
   OrgName:'Technologies OPTIM inc';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:64; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:64; B_IP4:255;
   OrgName:'MinistŠre de l''Industrie, du Commerce et des Sciences du Qu‚bec';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:68; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:68; B_IP4:255;
   OrgName:'Centre d''expertise et de consultation en tourisme';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:69; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:69; B_IP4:255;
   OrgName:'Microtec Technologies Inc.';
   Country:10851),

  (A_IP1:206; A_IP2:191; A_IP3:0; A_IP4:0;
   B_IP1:206; B_IP2:191; B_IP3:63; B_IP4:255;
   OrgName:'Magma Communications Ltd.';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:100; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:109; B_IP4:255;
   OrgName:'CEGEP Francois-Xavier-Garneau (CollŠge Montmorency)';
   Country:10851),

  (A_IP1:195; A_IP2:6; A_IP3:100; A_IP4:248;
   B_IP1:195; B_IP2:6; B_IP3:100; B_IP4:255;
   OrgName:'Henri-maire-sa';
   Country:10887),

  (A_IP1:196; A_IP2:200; A_IP3:0; A_IP4:0;
   B_IP1:196; B_IP2:207; B_IP3:255; B_IP4:255;
   OrgName:'RIPE Network Coordination Centre';
   Country:10974),

  (A_IP1:207; A_IP2:236; A_IP3:189; A_IP4:224;
   B_IP1:207; B_IP2:236; B_IP3:189; B_IP4:255;
   OrgName:'The Aldo Group Inc';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:72; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:72; B_IP4:255;
   OrgName:'CollŠge de l''Assomption';
   Country:10851),

  (A_IP1:202; A_IP2:228; A_IP3:188; A_IP4:128;
   B_IP1:202; B_IP2:228; B_IP3:188; B_IP4:191;
   OrgName:'Humming Heads Inc.';
   Country:10924),

  (A_IP1:213; A_IP2:36; A_IP3:142; A_IP4:0;
   B_IP1:213; B_IP2:36; B_IP3:237; B_IP4:255;
   OrgName:'Tiscali France';
   Country:10887),

  (A_IP1:195; A_IP2:186; A_IP3:96; A_IP4:0;
   B_IP1:195; B_IP2:186; B_IP3:255; B_IP4:255;
   OrgName:'Swisscom IP-Plus';
   Country:10856),

  (A_IP1:206; A_IP2:167; A_IP3:73; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:73; B_IP4:255;
   OrgName:'McGill Research Center for Intelligent Machines';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:74; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:74; B_IP4:255;
   OrgName:'Centre coll‚gial de d‚veloppement de mat‚riel didactique';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:76; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:76; B_IP4:255;
   OrgName:'C‚gep Joliette-De LanaudiŠre';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:77; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:77; B_IP4:255;
   OrgName:'Info-attraits';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:78; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:78; B_IP4:63;
   OrgName:'AKAMAI';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:79; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:79; B_IP4:255;
   OrgName:'LB Products Ltee. (Vantree Systems)';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:80; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:87; B_IP4:255;
   OrgName:'C‚gep Andr‚-Laurendeau';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:88; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:88; B_IP4:255;
   OrgName:'Centre de recherche LICEF';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:89; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:89; B_IP4:255;
   OrgName:'Info-attraits';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:90; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:99; B_IP4:255;
   OrgName:'CollŠge Montmorency';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:110; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:110; B_IP4:255;
   OrgName:'C‚gep St-F‚licien';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:111; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:111; B_IP4:255;
   OrgName:'Services Documentaires multim‚dia';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:114; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:114; B_IP4:255;
   OrgName:'Champlain College … St-Lambert';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:115; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:117; B_IP4:255;
   OrgName:'CRIM - Service de formation';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:118; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:119; B_IP4:255;
   OrgName:'CollŠge de Maisonneuve';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:120; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:122; B_IP4:255;
   OrgName:'CollŠge de l''Outaouais';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:123; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:127; B_IP4:255;
   OrgName:'CollŠge H‚ritage';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:160; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:160; B_IP4:255;
   OrgName:'Commission scolaire de Memphremagog';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:159; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:159; B_IP4:255;
   OrgName:'Centre Hospitalier Universitaire de Qu‚bec';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:161; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:161; B_IP4:255;
   OrgName:'Centre d''‚tudes coll‚giales en Charlevoix';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:133; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:135; B_IP4:255;
   OrgName:'C‚gep de JonquiŠre';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:146; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:146; B_IP4:255;
   OrgName:'Commission scolaire des Hauts-Cantons';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:148; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:148; B_IP4:255;
   OrgName:'Bureau de la statistique du Qu‚bec';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:151; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:151; B_IP4:255;
   OrgName:'Communications MULTIMEDIA Enter-Net';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:152; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:152; B_IP4:255;
   OrgName:'Commission scolaire au Coeur des Vall‚es';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:154; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:154; B_IP4:255;
   OrgName:'C‚gep de Chicoutimi';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:157; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:157; B_IP4:255;
   OrgName:'Soci‚t‚ d''habitation du Qu‚bec';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:168; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:168; B_IP4:255;
   OrgName:'Commission scolaire Morilac';
   Country:10851),

  (A_IP1:213; A_IP2:103; A_IP3:0; A_IP4:0;
   B_IP1:213; B_IP2:103; B_IP3:127; B_IP4:255;
   OrgName:'Tele2 France S.A.';
   Country:10887),

  (A_IP1:205; A_IP2:167; A_IP3:6; A_IP4:0;
   B_IP1:205; B_IP2:167; B_IP3:7; B_IP4:255;
   OrgName:'Schneider Automation, Inc.';
   Country:11038),

  (A_IP1:193; A_IP2:190; A_IP3:208; A_IP4:0;
   B_IP1:193; B_IP2:190; B_IP3:211; B_IP4:255;
   OrgName:'Facult‚ Polytechnique de Mons - Centre Informatique FPMS';
   Country:10835),

  (A_IP1:206; A_IP2:167; A_IP3:169; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:169; B_IP4:255;
   OrgName:'Direction G‚n‚rale des t‚l‚communications';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:176; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:179; B_IP4:255;
   OrgName:'CollŠge de la R‚gion de l''Amiante';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:180; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:186; B_IP4:255;
   OrgName:'Universit‚ de Sherbrooke, R‚sidences';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:188; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:188; B_IP4:255;
   OrgName:'Eastern Townships School Board';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:189; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:191; B_IP4:255;
   OrgName:'Institut de Recherche en Biotechnologie';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:192; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:195; B_IP4:255;
   OrgName:'Universit‚ Bishop';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:196; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:200; B_IP4:255;
   OrgName:'C‚gep de Chicoutimi';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:201; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:202; B_IP4:255;
   OrgName:'Institut de Recherche en Mat‚riaux Industriels';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:204; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:205; B_IP4:255;
   OrgName:'National Research Council of Canada';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:206; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:207; B_IP4:255;
   OrgName:'Institut de recherches cliniques de Montr‚al';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:230; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:230; B_IP4:255;
   OrgName:'Commission Scolaire Jacques-Cartier';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:224; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:224; B_IP4:255;
   OrgName:'C‚gep de St-F‚licien';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:226; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:227; B_IP4:255;
   OrgName:'Hopital G‚n‚ral Juif SMBD';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:228; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:229; B_IP4:255;
   OrgName:'CollŠge Delta';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:212; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:212; B_IP4:255;
   OrgName:'Alliance Num‚rique';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:213; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:213; B_IP4:255;
   OrgName:'Centre NAD';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:214; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:214; B_IP4:255;
   OrgName:'Ericsson Canada Inc.';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:216; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:216; B_IP4:255;
   OrgName:'MinistŠre de l''environnement';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:217; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:219; B_IP4:255;
   OrgName:'Commission scolaire de Coaticook';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:220; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:222; B_IP4:255;
   OrgName:'CollŠge de l''Outaouais';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:232; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:237; B_IP4:255;
   OrgName:'Institut de Tourisme et d''Hotellerie du Qu‚bec';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:239; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:239; B_IP4:255;
   OrgName:'R‚seau Interordinateur Scientifique Qu‚becois [RISQ]';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:240; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:241; B_IP4:255;
   OrgName:'C‚gep Sorel-Tracy';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:242; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:243; B_IP4:255;
   OrgName:'CollŠge Delta';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:248; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:249; B_IP4:255;
   OrgName:'C‚gep de Chicoutimi';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:250; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:250; B_IP4:255;
   OrgName:'Commission scolaires des sommets';
   Country:10851),

  (A_IP1:206; A_IP2:167; A_IP3:254; A_IP4:0;
   B_IP1:206; B_IP2:167; B_IP3:254; B_IP4:255;
   OrgName:'Commission Scolaire de Sorel-Tracy';
   Country:10851),

  (A_IP1:206; A_IP2:168; A_IP3:0; A_IP4:0;
   B_IP1:206; B_IP2:168; B_IP3:0; B_IP4:255;
   OrgName:'Measurement Factory, Inc';
   Country:11038),

  (A_IP1:206; A_IP2:171; A_IP3:0; A_IP4:0;
   B_IP1:206; B_IP2:171; B_IP3:0; B_IP4:255;
   OrgName:'National University';
   Country:11038),

  (A_IP1:206; A_IP2:172; A_IP3:0; A_IP4:0;
   B_IP1:206; B_IP2:172; B_IP3:0; B_IP4:255;
   OrgName:'Bell Canada ICN DMZ environments';
   Country:10851),

  (A_IP1:206; A_IP2:174; A_IP3:0; A_IP4:0;
   B_IP1:206; B_IP2:174; B_IP3:127; B_IP4:255;
   OrgName:'GCI Communications, Inc.';
   Country:11038),

  (A_IP1:206; A_IP2:175; A_IP3:0; A_IP4:0;
   B_IP1:206; B_IP2:175; B_IP3:255; B_IP4:255;
   OrgName:'UUNET Technologies, Inc.';
   Country:11038),

  (A_IP1:206; A_IP2:176; A_IP3:0; A_IP4:0;
   B_IP1:206; B_IP2:176; B_IP3:15; B_IP4:255;
   OrgName:'University of South Dakota';
   Country:11038),

  (A_IP1:206; A_IP2:177; A_IP3:1; A_IP4:0;
   B_IP1:206; B_IP2:177; B_IP3:23; B_IP4:255;
   OrgName:'Conseil Des Ecoles Catholique De Langue';
   Country:10851),

  (A_IP1:206; A_IP2:177; A_IP3:24; A_IP4:0;
   B_IP1:206; B_IP2:177; B_IP3:46; B_IP4:255;
   OrgName:'London & Middlesex County Roman Catholic';
   Country:10851),

  (A_IP1:206; A_IP2:180; A_IP3:0; A_IP4:0;
   B_IP1:206; B_IP2:180; B_IP3:63; B_IP4:255;
   OrgName:'Reynolds and Reynolds';
   Country:11038),

  (A_IP1:206; A_IP2:180; A_IP3:64; A_IP4:0;
   B_IP1:206; B_IP2:180; B_IP3:127; B_IP4:255;
   OrgName:'Midwestern Intermediate Unit IV';
   Country:11038),

  (A_IP1:206; A_IP2:180; A_IP3:128; A_IP4:0;
   B_IP1:206; B_IP2:180; B_IP3:159; B_IP4:255;
   OrgName:'Houston Area League of PC Users, Inc.';
   Country:11038),

  (A_IP1:207; A_IP2:61; A_IP3:255; A_IP4:0;
   B_IP1:207; B_IP2:61; B_IP3:255; B_IP4:7;
   OrgName:'PLB International Inc';
   Country:10851),

  (A_IP1:207; A_IP2:61; A_IP3:255; A_IP4:16;
   B_IP1:207; B_IP2:61; B_IP3:255; B_IP4:31;
   OrgName:'Direct Transport Group';
   Country:10851),

  (A_IP1:207; A_IP2:61; A_IP3:255; A_IP4:32;
   B_IP1:207; B_IP2:61; B_IP3:255; B_IP4:39;
   OrgName:'Durham Children''s Aid';
   Country:10851),

  (A_IP1:207; A_IP2:61; A_IP3:255; A_IP4:40;
   B_IP1:207; B_IP2:61; B_IP3:255; B_IP4:47;
   OrgName:'Axxess International Inc';
   Country:10851),

  (A_IP1:207; A_IP2:61; A_IP3:255; A_IP4:56;
   B_IP1:207; B_IP2:61; B_IP3:255; B_IP4:63;
   OrgName:'Roche Ltee Groupe Conseil';
   Country:10851),

  (A_IP1:216; A_IP2:37; A_IP3:64; A_IP4:0;
   B_IP1:216; B_IP2:37; B_IP3:95; B_IP4:255;
   OrgName:'Worldcom/Worldspice Technologies Inc.';
   Country:11038),

  (A_IP1:193; A_IP2:52; A_IP3:145; A_IP4:0;
   B_IP1:193; B_IP2:52; B_IP3:145; B_IP4:255;
   OrgName:'Universit‚ de Rouen';
   Country:10887),

  (A_IP1:142; A_IP2:225; A_IP3:0; A_IP4:0;
   B_IP1:142; B_IP2:225; B_IP3:255; B_IP4:255;
   OrgName:'FinanciŠre Banque Nationale Inc.';
   Country:10851),

  (A_IP1:202; A_IP2:22; A_IP3:224; A_IP4:0;
   B_IP1:202; B_IP2:22; B_IP3:239; B_IP4:255;
   OrgName:'Micro Logic Systems';
   Country:10969),

  (A_IP1:65; A_IP2:89; A_IP3:12; A_IP4:0;
   B_IP1:65; B_IP2:89; B_IP3:12; B_IP4:63;
   OrgName:'Saint Gobain';
   Country:11038),

  (A_IP1:65; A_IP2:89; A_IP3:12; A_IP4:64;
   B_IP1:65; B_IP2:89; B_IP3:12; B_IP4:95;
   OrgName:'Sonic';
   Country:11038),

  (A_IP1:65; A_IP2:88; A_IP3:0; A_IP4:0;
   B_IP1:65; B_IP2:91; B_IP3:255; B_IP4:255;
   OrgName:'Broadwing Communications, Inc.';
   Country:11038),

  (A_IP1:195; A_IP2:245; A_IP3:108; A_IP4:0;
   B_IP1:195; B_IP2:245; B_IP3:109; B_IP4:255;
   OrgName:'Ariave Satcom LTD';
   Country:10915),

  (A_IP1:142; A_IP2:213; A_IP3:0; A_IP4:0;
   B_IP1:142; B_IP2:213; B_IP3:255; B_IP4:255;
   OrgName:'Direction g‚n‚rale de l''informatique du Qu‚bec';
   Country:10851),

  (A_IP1:142; A_IP2:215; A_IP3:0; A_IP4:0;
   B_IP1:142; B_IP2:215; B_IP3:255; B_IP4:255;
   OrgName:'Dylex Ltd';
   Country:10851),

  (A_IP1:142; A_IP2:219; A_IP3:0; A_IP4:0;
   B_IP1:142; B_IP2:219; B_IP3:255; B_IP4:255;
   OrgName:'District de Coquitlam';
   Country:10851),

  (A_IP1:159; A_IP2:50; A_IP3:0; A_IP4:0;
   B_IP1:159; B_IP2:50; B_IP3:255; B_IP4:255;
   OrgName:'Banque Nationale de Paris - BNP';
   Country:10887),

  (A_IP1:213; A_IP2:169; A_IP3:100; A_IP4:0;
   B_IP1:213; B_IP2:169; B_IP3:100; B_IP4:255;
   OrgName:'Netsystem Service';
   Country:10944),

  (A_IP1:67; A_IP2:142; A_IP3:0; A_IP4:0;
   B_IP1:67; B_IP2:143; B_IP3:255; B_IP4:255;
   OrgName:'Hughes Network Systems (DirecPC)';
   Country:11038),

  (A_IP1:195; A_IP2:25; A_IP3:48; A_IP4:0;
   B_IP1:195; B_IP2:25; B_IP3:48; B_IP4:255;
   OrgName:'Oleane Hostmaster (France Telecom Transpac)';
   Country:10887),

  (A_IP1:193; A_IP2:194; A_IP3:80; A_IP4:200;
   B_IP1:193; B_IP2:194; B_IP3:80; B_IP4:207;
   OrgName:'CDER (Belhamel Maiouf)';
   Country:10874),

  (A_IP1:217; A_IP2:128; A_IP3:226; A_IP4:0;
   B_IP1:217; B_IP2:128; B_IP3:226; B_IP4:255;
   OrgName:'Wanadoo France';
   Country:10887),

  (A_IP1:84; A_IP2:97; A_IP3:0; A_IP4:0;
   B_IP1:84; B_IP2:103; B_IP3:231; B_IP4:255;
   OrgName:'Neuf telecom (gaoland.net)';
   Country:10887),

  (A_IP1:81; A_IP2:220; A_IP3:72; A_IP4:0;
   B_IP1:81; B_IP2:220; B_IP3:79; B_IP4:255;
   OrgName:'NC Num‚riCable';
   Country:10887),

  (A_IP1:193; A_IP2:194; A_IP3:92; A_IP4:192;
   B_IP1:193; B_IP2:194; B_IP3:92; B_IP4:207;
   OrgName:'Centre universitaire de Tiaret';
   Country:10874),

  (A_IP1:212; A_IP2:92; A_IP3:0; A_IP4:128;
   B_IP1:212; B_IP2:92; B_IP3:0; B_IP4:151;
   OrgName:'Antenna Hungaria - Hungarian Radiocommunications Corporation';
   Country:10912),

  (A_IP1:216; A_IP2:228; A_IP3:208; A_IP4:0;
   B_IP1:216; B_IP2:228; B_IP3:223; B_IP4:255;
   OrgName:'Cable Axion Digitel Inc.';
   Country:10851),

  (A_IP1:139; A_IP2:165; A_IP3:0; A_IP4:0;
   B_IP1:139; B_IP2:165; B_IP3:255; B_IP4:255;
   OrgName:'Universit‚ de LiŠge (ULg)';
   Country:10835),

  (A_IP1:142; A_IP2:242; A_IP3:0; A_IP4:0;
   B_IP1:142; B_IP2:242; B_IP3:255; B_IP4:255;
   OrgName:'SNC-Lavalin, Inc.';
   Country:10851),

  (A_IP1:69; A_IP2:64; A_IP3:192; A_IP4:0;
   B_IP1:69; B_IP2:64; B_IP3:223; B_IP4:255;
   OrgName:'Con Edison Communications';
   Country:11038),

  (A_IP1:204; A_IP2:124; A_IP3:196; A_IP4:0;
   B_IP1:204; B_IP2:124; B_IP3:199; B_IP4:255;
   OrgName:'Coca Cola Bottling Company of New York';
   Country:11038),

  (A_IP1:217; A_IP2:167; A_IP3:147; A_IP4:0;
   B_IP1:217; B_IP2:167; B_IP3:147; B_IP4:255;
   OrgName:'Danone (De Suzzoni Philippe/Gilles Poisson)';
   Country:10887),

  (A_IP1:141; A_IP2:115; A_IP3:0; A_IP4:0;
   B_IP1:141; B_IP2:115; B_IP3:255; B_IP4:255;
   OrgName:'Universit‚ Paul Sabatier (UPS) (Institut de Recherche en Informatique de Toulouse)';
   Country:10887),

  (A_IP1:81; A_IP2:91; A_IP3:227; A_IP4:0;
   B_IP1:81; B_IP2:91; B_IP3:227; B_IP4:63;
   OrgName:'Office des Postes et Telecommunications (OPT)';
   Country:10840),

  (A_IP1:150; A_IP2:89; A_IP3:0; A_IP4:0;
   B_IP1:150; B_IP2:89; B_IP3:255; B_IP4:255;
   OrgName:'Osaka Institute of Technology';
   Country:10924),

  (A_IP1:194; A_IP2:51; A_IP3:20; A_IP4:0;
   B_IP1:194; B_IP2:51; B_IP3:20; B_IP4:255;
   OrgName:'Global Security Group - France Telecom';
   Country:10887),

  (A_IP1:41; A_IP2:248; A_IP3:0; A_IP4:0;
   B_IP1:41; B_IP2:251; B_IP3:255; B_IP4:255;
   OrgName:'Office National des Postes et Telecommunications';
   Country:10947),

  (A_IP1:140; A_IP2:94; A_IP3:0; A_IP4:0;
   B_IP1:140; B_IP2:94; B_IP3:255; B_IP4:255;
   OrgName:'ASTRIUM SAS';
   Country:10887),

  (A_IP1:62; A_IP2:161; A_IP3:176; A_IP4:0;
   B_IP1:62; B_IP2:161; B_IP3:176; B_IP4:127;
   OrgName:'VNU (vnu.com)';
   Country:10887),

  (A_IP1:69; A_IP2:156; A_IP3:202; A_IP4:0;
   B_IP1:69; B_IP2:156; B_IP3:203; B_IP4:255;
   OrgName:'Sympatico HSE (Bell)';
   Country:10851),

  (A_IP1:80; A_IP2:41; A_IP3:0; A_IP4:0;
   B_IP1:80; B_IP2:41; B_IP3:255; B_IP4:255;
   OrgName:'Tiscali UK Limited';
   Country:10890),

  (A_IP1:201; A_IP2:252; A_IP3:64; A_IP4:0;
   B_IP1:201; B_IP2:252; B_IP3:64; B_IP4:255;
   OrgName:'Apolo -Gold-Telecom-Per';
   Country:10826),

  (A_IP1:196; A_IP2:207; A_IP3:218; A_IP4:0;
   B_IP1:196; B_IP2:207; B_IP3:218; B_IP4:255;
   OrgName:'Sentoo';
   Country:11012),

  (A_IP1:193; A_IP2:194; A_IP3:64; A_IP4:0;
   B_IP1:193; B_IP2:194; B_IP3:95; B_IP4:255;
   OrgName:'Algerian Academic Research Network';
   Country:10874),

  (A_IP1:137; A_IP2:153; A_IP3:0; A_IP4:0;
   B_IP1:137; B_IP2:153; B_IP3:255; B_IP4:255;
   OrgName:'Sony Corporation';
   Country:10924),

  (A_IP1:81; A_IP2:199; A_IP3:104; A_IP4:0;
   B_IP1:81; B_IP2:199; B_IP3:107; B_IP4:255;
   OrgName:'Togotelecom';
   Country:11022),

  (A_IP1:193; A_IP2:188; A_IP3:105; A_IP4:0;
   B_IP1:193; B_IP2:188; B_IP3:105; B_IP4:65;
   OrgName:'Bahrain Telecommunication Company';
   Country:10838),

  (A_IP1:207; A_IP2:134; A_IP3:99; A_IP4:176;
   B_IP1:207; B_IP2:134; B_IP3:99; B_IP4:178;
   OrgName:'Brockhouse and Cooper 20Go';
   Country:10851),

  (A_IP1:155; A_IP2:94; A_IP3:0; A_IP4:0;
   B_IP1:155; B_IP2:94; B_IP3:255; B_IP4:255;
   OrgName:'Wyeth-Ayerst Research';
   Country:11038),

  (A_IP1:66; A_IP2:234; A_IP3:128; A_IP4:0;
   B_IP1:66; B_IP2:234; B_IP3:159; B_IP4:255;
   OrgName:'Backbone Communications, Inc.';
   Country:11038),

  (A_IP1:195; A_IP2:154; A_IP3:224; A_IP4:112;
   B_IP1:195; B_IP2:154; B_IP3:224; B_IP4:127;
   OrgName:'KDI';
   Country:10887),

  (A_IP1:193; A_IP2:168; A_IP3:73; A_IP4:0;
   B_IP1:193; B_IP2:168; B_IP3:73; B_IP4:255;
   OrgName:'CRP - Gabriel Lippmann (Centre de Recherche Public)';
   Country:10944),

  (A_IP1:212; A_IP2:190; A_IP3:193; A_IP4:64;
   B_IP1:212; B_IP2:190; B_IP3:193; B_IP4:95;
   OrgName:'Euroclear Bank';
   Country:10835),

  (A_IP1:204; A_IP2:19; A_IP3:245; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:247; B_IP4:255;
   OrgName:'Internet JRV';
   Country:10851),

  (A_IP1:198; A_IP2:152; A_IP3:0; A_IP4:0;
   B_IP1:198; B_IP2:152; B_IP3:255; B_IP4:255;
   OrgName:'AVAYA Communication';
   Country:11038),

  (A_IP1:198; A_IP2:153; A_IP3:0; A_IP4:0;
   B_IP1:198; B_IP2:153; B_IP3:7; B_IP4:255;
   OrgName:'Sales Technologies, Inc.';
   Country:11038),

  (A_IP1:198; A_IP2:153; A_IP3:8; A_IP4:0;
   B_IP1:198; B_IP2:153; B_IP3:15; B_IP4:255;
   OrgName:'Park Nicollet Health Services';
   Country:11038),

  (A_IP1:198; A_IP2:153; A_IP3:16; A_IP4:0;
   B_IP1:198; B_IP2:153; B_IP3:31; B_IP4:255;
   OrgName:'California Casualty';
   Country:11038),

  (A_IP1:198; A_IP2:153; A_IP3:32; A_IP4:0;
   B_IP1:198; B_IP2:153; B_IP3:57; B_IP4:255;
   OrgName:'Sun Health Corporation';
   Country:11038),

  (A_IP1:221; A_IP2:170; A_IP3:0; A_IP4:0;
   B_IP1:221; B_IP2:171; B_IP3:255; B_IP4:255;
   OrgName:'NEC Corporation';
   Country:10924),

  (A_IP1:81; A_IP2:224; A_IP3:0; A_IP4:0;
   B_IP1:81; B_IP2:236; B_IP3:255; B_IP4:255;
   OrgName:'Telia Network Services';
   Country:11004),

  (A_IP1:213; A_IP2:103; A_IP3:192; A_IP4:0;
   B_IP1:213; B_IP2:103; B_IP3:255; B_IP4:255;
   OrgName:'Tele2 France S.A.';
   Country:10887),

  (A_IP1:64; A_IP2:18; A_IP3:160; A_IP4:0;
   B_IP1:64; B_IP2:18; B_IP3:191; B_IP4:255;
   OrgName:'Oricom Internet';
   Country:10851),

  (A_IP1:88; A_IP2:152; A_IP3:170; A_IP4:0;
   B_IP1:88; B_IP2:152; B_IP3:255; B_IP4:255;
   OrgName:'Bezeq International';
   Country:10915),

  (A_IP1:217; A_IP2:17; A_IP3:234; A_IP4:0;
   B_IP1:217; B_IP2:17; B_IP3:234; B_IP4:255;
   OrgName:'Bahrain Telecommunications Company';
   Country:10838),

  (A_IP1:81; A_IP2:220; A_IP3:80; A_IP4:0;
   B_IP1:81; B_IP2:220; B_IP3:91; B_IP4:255;
   OrgName:'NC Num‚riCable';
   Country:10887),

  (A_IP1:142; A_IP2:169; A_IP3:0; A_IP4:0;
   B_IP1:142; B_IP2:169; B_IP3:255; B_IP4:255;
   OrgName:'TELUS Communications Inc.';
   Country:10851),

  (A_IP1:62; A_IP2:235; A_IP3:0; A_IP4:0;
   B_IP1:62; B_IP2:235; B_IP3:255; B_IP4:255;
   OrgName:'Scarlet';
   Country:10835),

  (A_IP1:62; A_IP2:205; A_IP3:76; A_IP4:0;
   B_IP1:62; B_IP2:205; B_IP3:127; B_IP4:255;
   OrgName:'TVD Internet - UPC Belgium - Chello';
   Country:10835),

  (A_IP1:84; A_IP2:112; A_IP3:0; A_IP4:0;
   B_IP1:84; B_IP2:119; B_IP3:255; B_IP4:255;
   OrgName:'Chello Broadband GmbH';
   Country:11004),

  (A_IP1:193; A_IP2:248; A_IP3:80; A_IP4:0;
   B_IP1:193; B_IP2:248; B_IP3:81; B_IP4:255;
   OrgName:'Wanadoo France';
   Country:10887),

  (A_IP1:195; A_IP2:115; A_IP3:71; A_IP4:0;
   B_IP1:195; B_IP2:115; B_IP3:71; B_IP4:63;
   OrgName:'Lacour Concept';
   Country:10887),

  (A_IP1:70; A_IP2:48; A_IP3:0; A_IP4:0;
   B_IP1:70; B_IP2:55; B_IP3:255; B_IP4:255;
   OrgName:'Bell Canada';
   Country:10851),

  (A_IP1:194; A_IP2:3; A_IP3:93; A_IP4:110;
   B_IP1:194; B_IP2:3; B_IP3:93; B_IP4:110;
   OrgName:'GI - Customer Interconnexion With RAEI Backbone';
   Country:10887),

  (A_IP1:81; A_IP2:194; A_IP3:0; A_IP4:0;
   B_IP1:81; B_IP2:194; B_IP3:15; B_IP4:255;
   OrgName:'Institut de Radioprotection et de Suret‚ Nucl‚aire';
   Country:10887),

  (A_IP1:86; A_IP2:214; A_IP3:196; A_IP4:0;
   B_IP1:86; B_IP2:214; B_IP3:196; B_IP4:255;
   OrgName:'Wanadoo France';
   Country:10887),

  (A_IP1:149; A_IP2:220; A_IP3:0; A_IP4:0;
   B_IP1:149; B_IP2:220; B_IP3:255; B_IP4:255;
   OrgName:'Forschungszentrum Rossendorf';
   Country:10869),

  (A_IP1:82; A_IP2:122; A_IP3:76; A_IP4:0;
   B_IP1:82; B_IP2:122; B_IP3:76; B_IP4:255;
   OrgName:'Wanadoo France';
   Country:10887),

  (A_IP1:205; A_IP2:151; A_IP3:1; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:7; B_IP4:255;
   OrgName:'CollŠge Bois-De-Boulogne';
   Country:10851),

  (A_IP1:86; A_IP2:12; A_IP3:208; A_IP4:0;
   B_IP1:86; B_IP2:12; B_IP3:223; B_IP4:255;
   OrgName:'NTL Internet';
   Country:10890),

  (A_IP1:205; A_IP2:151; A_IP3:16; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:16; B_IP4:255;
   OrgName:'Infoteck Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:17; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:50; B_IP4:255;
   OrgName:'MinistŠre de l''Agriculture du Qu‚bec';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:61; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:69; B_IP4:255;
   OrgName:'COGECO Cable Canada Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:51; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:51; B_IP4:255;
   OrgName:'MinistŠre des Affaires Internationales du Qu‚bec';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:52; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:52; B_IP4:255;
   OrgName:'Interlect';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:53; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:53; B_IP4:255;
   OrgName:'Bennett, Nidata, L‚gar‚ & Associates Solutions';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:250; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:254; B_IP4:255;
   OrgName:'CollŠge Edouard-Montpetit';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:247; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:249; B_IP4:255;
   OrgName:'Hopital du Sacr‚-Coeur de Montr‚al';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:227; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:246; B_IP4:255;
   OrgName:'Sidbec-Dosco (ISPAT) Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:226; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:226; B_IP4:255;
   OrgName:'Innovatron';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:225; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:225; B_IP4:255;
   OrgName:'Total Internet Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:222; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:224; B_IP4:255;
   OrgName:'Vid‚otron T‚l‚com Lt‚e';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:220; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:221; B_IP4:255;
   OrgName:'Alliance Mass Marketing Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:219; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:219; B_IP4:255;
   OrgName:'CSP Foods Ltd';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:217; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:218; B_IP4:255;
   OrgName:'JB Audio Centre Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:216; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:216; B_IP4:255;
   OrgName:'Commission de coop‚ration environmentale Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:215; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:215; B_IP4:255;
   OrgName:'Cantrex Group Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:214; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:214; B_IP4:255;
   OrgName:'Omega Network Co.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:210; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:211; B_IP4:255;
   OrgName:'Informatique MultiHexa Inc./Technologies Multipartn''r (TMI) Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:208; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:209; B_IP4:255;
   OrgName:'INTERNET JRV, Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:204; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:207; B_IP4:255;
   OrgName:'Cit‚Net T‚l‚com Inc. - Bloc de sous-r‚seau de Classe C';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:203; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:203; B_IP4:255;
   OrgName:'Les Systems Zenon';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:202; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:202; B_IP4:255;
   OrgName:'Lanter.Net Inc (CiteNet Telecom Inc.)';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:201; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:201; B_IP4:255;
   OrgName:'Empire Media et Communications';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:200; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:200; B_IP4:255;
   OrgName:'CiteNet Telecom Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:197; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:199; B_IP4:255;
   OrgName:'C‚gep de Saint-Hyacinthe';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:196; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:196; B_IP4:255;
   OrgName:'Centre d''Insemincation Artificielle du Qu‚bec Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:195; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:195; B_IP4:255;
   OrgName:'Demon Systems';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:194; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:194; B_IP4:255;
   OrgName:'CiteNet Telecom Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:193; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:193; B_IP4:255;
   OrgName:'Compugard Services';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:192; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:192; B_IP4:255;
   OrgName:'Wasserman Stotland';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:191; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:191; B_IP4:255;
   OrgName:'LAS Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:190; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:190; B_IP4:255;
   OrgName:'Combyne Data Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:188; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:188; B_IP4:255;
   OrgName:'AD Technologies Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:187; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:187; B_IP4:255;
   OrgName:'WavePhore Canada Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:186; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:186; B_IP4:255;
   OrgName:'Werdz Communications';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:184; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:185; B_IP4:255;
   OrgName:'Logic Systems McCarthy-Williams Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:180; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:183; B_IP4:255;
   OrgName:'Bytewide Marketing';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:179; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:179; B_IP4:255;
   OrgName:'InfoLogic Systems';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:169; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:178; B_IP4:255;
   OrgName:'Ciment St-Laurent';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:168; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:168; B_IP4:255;
   OrgName:'Communications Accessibles Montr‚al Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:166; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:167; B_IP4:255;
   OrgName:'Optel P.M.L.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:165; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:165; B_IP4:255;
   OrgName:'Envision Software Consultants Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:164; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:164; B_IP4:255;
   OrgName:'CGI Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:162; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:163; B_IP4:255;
   OrgName:'Commission scolaire de la Pointe-de-l''Ile';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:160; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:161; B_IP4:255;
   OrgName:'Sulzer Canada';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:128; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:159; B_IP4:255;
   OrgName:'DMR Group Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:126; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:127; B_IP4:255;
   OrgName:'Port de Montr‚al';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:125; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:125; B_IP4:255;
   OrgName:'Commission scolaire des Manoirs';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:124; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:124; B_IP4:255;
   OrgName:'Lansco Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:122; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:123; B_IP4:255;
   OrgName:'Entreprise TwinMind';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:121; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:121; B_IP4:255;
   OrgName:'L''Unique';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:120; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:120; B_IP4:255;
   OrgName:'Irisco Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:116; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:119; B_IP4:255;
   OrgName:'Communications Accessibles Montr‚al Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:112; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:112; B_IP4:255;
   OrgName:'Assembl‚e nationale du Qu‚bec';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:106; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:111; B_IP4:255;
   OrgName:'St. Remy Press';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:104; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:105; B_IP4:255;
   OrgName:'Touch Communications Ltd.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:103; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:103; B_IP4:255;
   OrgName:'Novalink';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:102; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:102; B_IP4:255;
   OrgName:'Futur Info Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:101; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:101; B_IP4:255;
   OrgName:'InterSurf';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:100; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:100; B_IP4:255;
   OrgName:'Club Centra';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:98; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:99; B_IP4:255;
   OrgName:'InterConNet';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:97; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:97; B_IP4:255;
   OrgName:'R‚gie de d‚sinstallions Olympiques de Montr‚al';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:96; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:96; B_IP4:255;
   OrgName:'Adcognito Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:88; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:95; B_IP4:255;
   OrgName:'Memotec Communications Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:84; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:87; B_IP4:255;
   OrgName:'Communications Inter-Acces';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:83; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:83; B_IP4:255;
   OrgName:'Keops informatique inc';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:82; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:82; B_IP4:255;
   OrgName:'Silonex Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:81; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:81; B_IP4:255;
   OrgName:'BibliothŠque de Kirkland';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:80; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:80; B_IP4:255;
   OrgName:'Ville de Kirkland';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:70; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:79; B_IP4:255;
   OrgName:'Universit‚ du Qu‚bec';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:60; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:60; B_IP4:255;
   OrgName:'Le Groupe BDDS';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:59; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:59; B_IP4:255;
   OrgName:'UtiliSoft Inc';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:58; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:58; B_IP4:255;
   OrgName:'Computing Services';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:57; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:57; B_IP4:255;
   OrgName:'Siv Data International Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:56; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:56; B_IP4:255;
   OrgName:'B2B2C Inc';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:55; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:55; B_IP4:255;
   OrgName:'Videotron Telecom Ltee, Service';
   Country:10851),

  (A_IP1:205; A_IP2:151; A_IP3:54; A_IP4:0;
   B_IP1:205; B_IP2:151; B_IP3:54; B_IP4:255;
   OrgName:'R‚gie des Installations Olympiques de Montr‚al';
   Country:10851),

  (A_IP1:216; A_IP2:154; A_IP3:0; A_IP4:0;
   B_IP1:216; B_IP2:154; B_IP3:191; B_IP4:255;
   OrgName:'Look Communications Inc.';
   Country:10851),

  (A_IP1:216; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:216; B_IP2:5; B_IP3:255; B_IP4:255;
   OrgName:'XO Communications';
   Country:11038),

  (A_IP1:216; A_IP2:0; A_IP3:129; A_IP4:0;
   B_IP1:216; B_IP2:0; B_IP3:129; B_IP4:255;
   OrgName:'Cypress Communications';
   Country:11038),

  (A_IP1:216; A_IP2:0; A_IP3:152; A_IP4:0;
   B_IP1:216; B_IP2:0; B_IP3:159; B_IP4:255;
   OrgName:'Logix Communications';
   Country:11038),

  (A_IP1:216; A_IP2:0; A_IP3:220; A_IP4:0;
   B_IP1:216; B_IP2:0; B_IP3:220; B_IP4:31;
   OrgName:'Digital Solutions';
   Country:11038),

  (A_IP1:216; A_IP2:0; A_IP3:220; A_IP4:32;
   B_IP1:216; B_IP2:0; B_IP3:220; B_IP4:47;
   OrgName:'Infowave';
   Country:11038),

  (A_IP1:216; A_IP2:0; A_IP3:220; A_IP4:48;
   B_IP1:216; B_IP2:0; B_IP3:220; B_IP4:63;
   OrgName:'Emergent Business';
   Country:11038),

  (A_IP1:216; A_IP2:0; A_IP3:220; A_IP4:64;
   B_IP1:216; B_IP2:0; B_IP3:220; B_IP4:95;
   OrgName:'BMG';
   Country:11038),

  (A_IP1:216; A_IP2:0; A_IP3:220; A_IP4:128;
   B_IP1:216; B_IP2:0; B_IP3:220; B_IP4:191;
   OrgName:'Regent Tower';
   Country:11038),

  (A_IP1:216; A_IP2:113; A_IP3:6; A_IP4:0;
   B_IP1:216; B_IP2:113; B_IP3:9; B_IP4:255;
   OrgName:'Cactus Communications Internet';
   Country:10851),

  (A_IP1:216; A_IP2:113; A_IP3:12; A_IP4:64;
   B_IP1:216; B_IP2:113; B_IP3:12; B_IP4:95;
   OrgName:'Soci‚t‚ du Parc des Iles de Montr‚al';
   Country:10851),

  (A_IP1:216; A_IP2:113; A_IP3:12; A_IP4:128;
   B_IP1:216; B_IP2:113; B_IP3:12; B_IP4:191;
   OrgName:'Gaz Metropolitain';
   Country:10851),

  (A_IP1:216; A_IP2:113; A_IP3:16; A_IP4:0;
   B_IP1:216; B_IP2:113; B_IP3:17; B_IP4:255;
   OrgName:'SecureNet Information Services Inc.';
   Country:10851),

  (A_IP1:216; A_IP2:113; A_IP3:22; A_IP4:0;
   B_IP1:216; B_IP2:113; B_IP3:22; B_IP4:255;
   OrgName:'Efficient Solution';
   Country:10851),

  (A_IP1:216; A_IP2:113; A_IP3:23; A_IP4:0;
   B_IP1:216; B_IP2:113; B_IP3:23; B_IP4:255;
   OrgName:'Commission scolaire de St-Hyacinthe';
   Country:10851),

  (A_IP1:216; A_IP2:113; A_IP3:24; A_IP4:0;
   B_IP1:216; B_IP2:113; B_IP3:24; B_IP4:31;
   OrgName:'Bombardier A‚ronautique';
   Country:10851),

  (A_IP1:216; A_IP2:113; A_IP3:24; A_IP4:32;
   B_IP1:216; B_IP2:113; B_IP3:24; B_IP4:39;
   OrgName:'Interactive Decison Solutions';
   Country:10851),

  (A_IP1:216; A_IP2:113; A_IP3:24; A_IP4:48;
   B_IP1:216; B_IP2:113; B_IP3:24; B_IP4:55;
   OrgName:'L-3 Communications MAS (Canada) Inc.';
   Country:10851),

  (A_IP1:216; A_IP2:113; A_IP3:24; A_IP4:56;
   B_IP1:216; B_IP2:113; B_IP3:24; B_IP4:63;
   OrgName:'Groupe Essaim inc.';
   Country:10851),

  (A_IP1:216; A_IP2:113; A_IP3:54; A_IP4:0;
   B_IP1:216; B_IP2:113; B_IP3:54; B_IP4:255;
   OrgName:'Commissions Scolaire des Patriotes';
   Country:10851),

  (A_IP1:134; A_IP2:214; A_IP3:0; A_IP4:0;
   B_IP1:134; B_IP2:214; B_IP3:255; B_IP4:255;
   OrgName:'Universit‚ Claude Bernard Lyon 1';
   Country:10887),

  (A_IP1:86; A_IP2:215; A_IP3:95; A_IP4:0;
   B_IP1:86; B_IP2:215; B_IP3:95; B_IP4:255;
   OrgName:'Wanadoo France';
   Country:10887),

  (A_IP1:193; A_IP2:191; A_IP3:224; A_IP4:0;
   B_IP1:193; B_IP2:191; B_IP3:239; B_IP4:255;
   OrgName:'Communaut‚ Francaise Wallonie-Bruxelles';
   Country:10835),

  (A_IP1:205; A_IP2:236; A_IP3:1; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:1; B_IP4:255;
   OrgName:'Dolfe Systems';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:2; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:2; B_IP4:255;
   OrgName:'CollŠge Shawinigan';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:3; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:3; B_IP4:255;
   OrgName:'MinistŠre de l''ducation du Qu‚bec';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:4; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:7; B_IP4:255;
   OrgName:'Champlain Regionnal College, Lennoxville Campus';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:8; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:12; B_IP4:255;
   OrgName:'C‚gep de Levis-Lauzon';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:13; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:13; B_IP4:255;
   OrgName:'MinistŠre de la Culture et des Communications du Qu‚bec';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:14; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:14; B_IP4:255;
   OrgName:'Groupe conseil Genivar inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:15; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:15; B_IP4:255;
   OrgName:'Genimos Data inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:16; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:16; B_IP4:255;
   OrgName:'Buzz Image Group Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:17; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:17; B_IP4:255;
   OrgName:'Centre international des droits de la personne et du d‚veloppement d‚mocratique';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:18; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:18; B_IP4:255;
   OrgName:'Alt-C Systems Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:19; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:19; B_IP4:255;
   OrgName:'Mackenzie Gervais S.E.N.C.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:20; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:22; B_IP4:255;
   OrgName:'Commission Scolaire Marie-Victorin';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:23; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:23; B_IP4:255;
   OrgName:'Courdeau-Procinbec Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:26; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:26; B_IP4:255;
   OrgName:'Carrefour d''information et de recherche pour les initiatives locales';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:27; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:27; B_IP4:255;
   OrgName:'Soci‚t‚ du palais des congrŠs de Montr‚al';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:28; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:30; B_IP4:255;
   OrgName:'Desjardins Ducharmes Stein Monast Avocats';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:31; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:31; B_IP4:255;
   OrgName:'Protastant School Brd of Greater Montreal';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:32; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:33; B_IP4:255;
   OrgName:'Bombardier, Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:35; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:35; B_IP4:255;
   OrgName:'C‚gep de Rimouski';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:36; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:36; B_IP4:255;
   OrgName:'Centre R‚gional des Services aux BibliothŠques';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:37; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:37; B_IP4:255;
   OrgName:'Groupe Educalivres Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:38; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:39; B_IP4:255;
   OrgName:'V.P. Teleconnect Services Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:40; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:40; B_IP4:255;
   OrgName:'Technologies Sepia Inc';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:41; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:41; B_IP4:255;
   OrgName:'VanTree Systems Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:42; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:42; B_IP4:255;
   OrgName:'Sogi Informatique Limit‚e';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:43; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:43; B_IP4:255;
   OrgName:'Connection MMIC inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:44; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:45; B_IP4:255;
   OrgName:'Top Computer Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:46; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:46; B_IP4:255;
   OrgName:'Internet Montr‚al';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:47; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:47; B_IP4:255;
   OrgName:'Distribution Parent';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:50; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:50; B_IP4:255;
   OrgName:'Quebec''s linux users group';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:51; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:51; B_IP4:255;
   OrgName:'Tellabs Operations, Inc.';
   Country:11038),

  (A_IP1:205; A_IP2:236; A_IP3:52; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:52; B_IP4:255;
   OrgName:'Cartons St-Laurent Inc';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:53; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:53; B_IP4:255;
   OrgName:'Internet Qu‚bec IQ Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:54; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:54; B_IP4:255;
   OrgName:'Prospection Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:55; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:55; B_IP4:255;
   OrgName:'Accent Internet';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:57; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:57; B_IP4:255;
   OrgName:'C‚gep de Baie-Comeau';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:58; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:58; B_IP4:255;
   OrgName:'@six.net';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:59; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:59; B_IP4:255;
   OrgName:'Institut de Design Montr‚al';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:60; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:69; B_IP4:255;
   OrgName:'Bombardier Inc';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:70; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:70; B_IP4:255;
   OrgName:'Cybertourisme Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:71; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:71; B_IP4:255;
   OrgName:'Centre Internet de D‚veloppement';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:72; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:72; B_IP4:255;
   OrgName:'Centennial Academy Inc';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:73; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:73; B_IP4:255;
   OrgName:'C‚gep de Baie-Comeau';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:74; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:74; B_IP4:255;
   OrgName:'Prima Telematic Inc';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:75; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:75; B_IP4:255;
   OrgName:'Tellabs Operations, Inc.';
   Country:11038),

  (A_IP1:205; A_IP2:236; A_IP3:76; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:76; B_IP4:255;
   OrgName:'C‚gep de Sept-Iles';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:77; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:77; B_IP4:255;
   OrgName:'C‚gep Beauce-Appalache';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:80; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:80; B_IP4:255;
   OrgName:'Connection MMIC inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:82; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:82; B_IP4:255;
   OrgName:'Media Online';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:83; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:87; B_IP4:255;
   OrgName:'Accent Internet';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:88; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:88; B_IP4:255;
   OrgName:'Commission scolaire Outaouais-Hull';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:90; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:90; B_IP4:255;
   OrgName:'CONTACT-NET';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:91; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:91; B_IP4:255;
   OrgName:'SFG Technologies Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:92; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:92; B_IP4:255;
   OrgName:'Ulix Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:93; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:95; B_IP4:255;
   OrgName:'CollŠge Vanier';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:96; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:96; B_IP4:255;
   OrgName:'Promacad Services Ltd.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:97; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:97; B_IP4:255;
   OrgName:'MCNET';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:98; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:98; B_IP4:255;
   OrgName:'Hayes Dana Qu‚bec Inc';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:99; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:99; B_IP4:255;
   OrgName:'James R. Hay and Associates';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:100; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:100; B_IP4:255;
   OrgName:'MEG@Toon Station';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:101; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:101; B_IP4:255;
   OrgName:'Desfosses Consultation';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:102; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:102; B_IP4:255;
   OrgName:'Communications Mednet Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:103; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:103; B_IP4:255;
   OrgName:'DataSpace Insight Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:104; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:107; B_IP4:255;
   OrgName:'Connection MMIC inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:108; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:108; B_IP4:255;
   OrgName:'Distribution Trans X';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:109; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:109; B_IP4:255;
   OrgName:'R‚seau Equiglobe Network';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:110; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:114; B_IP4:255;
   OrgName:'Cabano Kingsway Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:115; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:115; B_IP4:255;
   OrgName:'Blizz Informatique enr.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:116; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:116; B_IP4:255;
   OrgName:'AccŠs Internet Belin, Inc. (Ste-Justine)';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:117; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:117; B_IP4:255;
   OrgName:'NOMAD s.e.n.c';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:118; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:118; B_IP4:255;
   OrgName:'ErgoNet Marketing';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:119; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:119; B_IP4:255;
   OrgName:'Les logiciels Polysoft Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:120; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:123; B_IP4:255;
   OrgName:'Connection MMIC inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:124; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:124; B_IP4:255;
   OrgName:'M.S. Informatique enr.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:125; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:125; B_IP4:255;
   OrgName:'C‚gep de Saint-Hyacinthe';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:126; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:126; B_IP4:255;
   OrgName:'Internet Mont-Laurier, Enr.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:128; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:128; B_IP4:255;
   OrgName:'Internet Montr‚al';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:129; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:129; B_IP4:255;
   OrgName:'Makaera Vir Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:130; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:130; B_IP4:255;
   OrgName:'Vice Entertainment Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:131; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:131; B_IP4:255;
   OrgName:'The Internet World Cafe';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:132; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:132; B_IP4:255;
   OrgName:'Alliance Commerciale Technologique';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:133; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:133; B_IP4:255;
   OrgName:'Agence Zone Communications';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:134; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:139; B_IP4:255;
   OrgName:'Le CollŠge Fran‡ais';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:140; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:140; B_IP4:255;
   OrgName:'Socom technologies inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:141; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:141; B_IP4:255;
   OrgName:'INTERNET-BBSI INC.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:142; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:142; B_IP4:255;
   OrgName:'Speedy Transport and Cartage';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:143; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:143; B_IP4:255;
   OrgName:'Marque d''Or Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:144; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:144; B_IP4:255;
   OrgName:'CollŠge Vanier';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:145; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:145; B_IP4:255;
   OrgName:'Can Inst for Native Training (CINT)';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:146; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:146; B_IP4:255;
   OrgName:'Le Groupe DMV';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:147; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:147; B_IP4:255;
   OrgName:'SecureNet Information Services';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:148; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:148; B_IP4:255;
   OrgName:'SOGETEL INC';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:149; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:149; B_IP4:255;
   OrgName:'Internet Montr‚al';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:150; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:151; B_IP4:255;
   OrgName:'Tugnet Enr';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:152; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:152; B_IP4:255;
   OrgName:'Yamatech Connectivity Solutions';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:153; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:153; B_IP4:255;
   OrgName:'Devicom Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:154; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:154; B_IP4:255;
   OrgName:'Civec Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:155; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:155; B_IP4:255;
   OrgName:'Envirovision 2010';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:156; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:156; B_IP4:255;
   OrgName:'CDIJFT';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:157; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:162; B_IP4:255;
   OrgName:'Bell Helicopter Textron';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:163; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:163; B_IP4:255;
   OrgName:'Les maitres typographes Zibra';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:164; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:164; B_IP4:255;
   OrgName:'CARA Informatique';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:165; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:165; B_IP4:255;
   OrgName:'CIBL 101.5 FM';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:166; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:167; B_IP4:255;
   OrgName:'AEI Internet Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:168; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:168; B_IP4:255;
   OrgName:'TriQuest Information Technologies';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:169; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:169; B_IP4:255;
   OrgName:'Echo Communications';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:170; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:170; B_IP4:255;
   OrgName:'BibliothŠque de la Ville de Kirkland';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:171; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:171; B_IP4:255;
   OrgName:'Air Alliance Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:172; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:172; B_IP4:255;
   OrgName:'SOGETEL INC';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:173; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:173; B_IP4:255;
   OrgName:'GA Finance';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:174; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:174; B_IP4:255;
   OrgName:'Groupe 3-SOFT inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:175; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:177; B_IP4:255;
   OrgName:'Infobahn Online Services';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:178; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:179; B_IP4:255;
   OrgName:'Louvicourt Mine';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:180; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:180; B_IP4:255;
   OrgName:'Centre de sant‚ publique de Qu‚bec';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:181; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:181; B_IP4:255;
   OrgName:'SickBay';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:182; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:183; B_IP4:255;
   OrgName:'camLink Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:184; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:184; B_IP4:255;
   OrgName:'Faltec Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:185; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:185; B_IP4:255;
   OrgName:'Internauts Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:186; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:187; B_IP4:255;
   OrgName:'Malofilm Distribution Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:188; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:188; B_IP4:255;
   OrgName:'I-SYST';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:189; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:189; B_IP4:255;
   OrgName:'Service T‚l‚matique/Service Internet de Montr‚al';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:190; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:190; B_IP4:255;
   OrgName:'Memotec Communications Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:191; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:191; B_IP4:255;
   OrgName:'XBR Communications Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:192; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:223; B_IP4:255;
   OrgName:'UAP Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:224; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:224; B_IP4:255;
   OrgName:'Les Electroniques Inpro Inc';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:225; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:225; B_IP4:255;
   OrgName:'Dator Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:226; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:226; B_IP4:255;
   OrgName:'Connection MMIC inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:227; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:227; B_IP4:255;
   OrgName:'SoftSet Consulting';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:228; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:228; B_IP4:255;
   OrgName:'Niro Technologie';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:229; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:229; B_IP4:255;
   OrgName:'Ergosoft Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:230; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:230; B_IP4:255;
   OrgName:'B2B2C Inc';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:231; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:231; B_IP4:255;
   OrgName:'The BGW Group Inc';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:232; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:232; B_IP4:255;
   OrgName:'CAA-Qu‚bec';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:233; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:233; B_IP4:255;
   OrgName:'ABL Canada Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:234; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:234; B_IP4:255;
   OrgName:'Ordinateurs PMC Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:235; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:235; B_IP4:255;
   OrgName:'Net-Communication';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:236; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:236; B_IP4:255;
   OrgName:'Ordinox Network Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:237; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:239; B_IP4:255;
   OrgName:'AMF Technotransport inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:240; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:243; B_IP4:255;
   OrgName:'Internet Montr‚al';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:244; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:244; B_IP4:255;
   OrgName:'Coredev Techno Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:236; A_IP3:245; A_IP4:0;
   B_IP1:205; B_IP2:236; B_IP3:254; B_IP4:255;
   OrgName:'Les r‚seaux LAN Cit‚ Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:2; A_IP4:0;
   B_IP1:205; B_IP2:205; B_IP3:3; B_IP4:255;
   OrgName:'Makaera Vir Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:6; A_IP4:0;
   B_IP1:205; B_IP2:205; B_IP3:6; B_IP4:255;
   OrgName:'GSI';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:7; A_IP4:0;
   B_IP1:205; B_IP2:205; B_IP3:7; B_IP4:255;
   OrgName:'Lognet (Visior Logipaye)';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:8; A_IP4:0;
   B_IP1:205; B_IP2:205; B_IP3:8; B_IP4:255;
   OrgName:'Surefire Commerce Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:8; A_IP4:0;
   B_IP1:205; B_IP2:205; B_IP3:8; B_IP4:255;
   OrgName:'SiteSell Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:11; A_IP4:0;
   B_IP1:205; B_IP2:205; B_IP3:11; B_IP4:255;
   OrgName:'TotalNet Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:12; A_IP4:0;
   B_IP1:205; B_IP2:205; B_IP3:12; B_IP4:255;
   OrgName:'JCC Networks';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:13; A_IP4:0;
   B_IP1:205; B_IP2:205; B_IP3:13; B_IP4:127;
   OrgName:'New Trade Technology Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:13; A_IP4:128;
   B_IP1:205; B_IP2:205; B_IP3:13; B_IP4:191;
   OrgName:'SpeechWorks';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:13; A_IP4:192;
   B_IP1:205; B_IP2:205; B_IP3:13; B_IP4:255;
   OrgName:'EMS Technologies Canada Ltd.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:14; A_IP4:0;
   B_IP1:205; B_IP2:205; B_IP3:14; B_IP4:255;
   OrgName:'UUNET Canada Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:15; A_IP4:64;
   B_IP1:205; B_IP2:205; B_IP3:15; B_IP4:79;
   OrgName:'Logibec Groupe Informatique Limit‚e';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:15; A_IP4:32;
   B_IP1:205; B_IP2:205; B_IP3:15; B_IP4:63;
   OrgName:'Haptic Technologies';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:15; A_IP4:80;
   B_IP1:205; B_IP2:205; B_IP3:15; B_IP4:95;
   OrgName:'Action 20/80 Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:15; A_IP4:96;
   B_IP1:205; B_IP2:205; B_IP3:15; B_IP4:111;
   OrgName:'National Sales and Distrigution(NSD)';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:15; A_IP4:112;
   B_IP1:205; B_IP2:205; B_IP3:15; B_IP4:127;
   OrgName:'Bennett Environmental Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:15; A_IP4:128;
   B_IP1:205; B_IP2:205; B_IP3:15; B_IP4:143;
   OrgName:'T4G Limited';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:15; A_IP4:144;
   B_IP1:205; B_IP2:205; B_IP3:15; B_IP4:159;
   OrgName:'Distex Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:15; A_IP4:192;
   B_IP1:205; B_IP2:205; B_IP3:15; B_IP4:207;
   OrgName:'Ganytech Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:15; A_IP4:160;
   B_IP1:205; B_IP2:205; B_IP3:15; B_IP4:175;
   OrgName:'Tariffic.Com Limit‚e';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:15; A_IP4:176;
   B_IP1:205; B_IP2:205; B_IP3:15; B_IP4:191;
   OrgName:'Grand Format Inc';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:15; A_IP4:208;
   B_IP1:205; B_IP2:205; B_IP3:15; B_IP4:223;
   OrgName:'Rideau Medals & Decoration Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:15; A_IP4:224;
   B_IP1:205; B_IP2:205; B_IP3:15; B_IP4:239;
   OrgName:'GoSecure';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:15; A_IP4:240;
   B_IP1:205; B_IP2:205; B_IP3:15; B_IP4:255;
   OrgName:'Morin';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:16; A_IP4:0;
   B_IP1:205; B_IP2:205; B_IP3:16; B_IP4:15;
   OrgName:'R‚no-D‚pot Inc';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:16; A_IP4:16;
   B_IP1:205; B_IP2:205; B_IP3:16; B_IP4:31;
   OrgName:'Mayne Pharma';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:16; A_IP4:32;
   B_IP1:205; B_IP2:205; B_IP3:16; B_IP4:63;
   OrgName:'FCB Direct Mtl.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:16; A_IP4:64;
   B_IP1:205; B_IP2:205; B_IP3:16; B_IP4:79;
   OrgName:'Golf-Tours.com';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:16; A_IP4:80;
   B_IP1:205; B_IP2:205; B_IP3:16; B_IP4:95;
   OrgName:'Finrad';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:16; A_IP4:96;
   B_IP1:205; B_IP2:205; B_IP3:16; B_IP4:111;
   OrgName:'Sabex 2002 Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:16; A_IP4:112;
   B_IP1:205; B_IP2:205; B_IP3:16; B_IP4:127;
   OrgName:'Canada Direct Data Base Marketing Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:16; A_IP4:128;
   B_IP1:205; B_IP2:205; B_IP3:16; B_IP4:143;
   OrgName:'Zero-Knowledge Systems, Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:16; A_IP4:144;
   B_IP1:205; B_IP2:205; B_IP3:16; B_IP4:175;
   OrgName:'AstenJohnson';
   Country:11038),

  (A_IP1:205; A_IP2:205; A_IP3:16; A_IP4:176;
   B_IP1:205; B_IP2:205; B_IP3:16; B_IP4:191;
   OrgName:'Medlii/ 94995 Canada';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:16; A_IP4:192;
   B_IP1:205; B_IP2:205; B_IP3:16; B_IP4:207;
   OrgName:'Tecsys Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:16; A_IP4:208;
   B_IP1:205; B_IP2:205; B_IP3:16; B_IP4:223;
   OrgName:'Net Communications';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:16; A_IP4:224;
   B_IP1:205; B_IP2:205; B_IP3:16; B_IP4:239;
   OrgName:'Rolf C. Hagen Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:16; A_IP4:240;
   B_IP1:205; B_IP2:205; B_IP3:16; B_IP4:255;
   OrgName:'Seafarers International Union of Canada';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:17; A_IP4:0;
   B_IP1:205; B_IP2:205; B_IP3:17; B_IP4:15;
   OrgName:'Opal-RT Technologies Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:205; A_IP3:17; A_IP4:16;
   B_IP1:205; B_IP2:205; B_IP3:17; B_IP4:31;
   OrgName:'Siprolab Telecom';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:1; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:1; B_IP4:255;
   OrgName:'Informatique PubliWEB Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:2; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:2; B_IP4:255;
   OrgName:'Institut Philippe Pinel de Montr‚al';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:3; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:3; B_IP4:255;
   OrgName:'Montr‚al Internet Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:4; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:5; B_IP4:255;
   OrgName:'FAMIC INC';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:6; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:7; B_IP4:255;
   OrgName:'CollŠge LaSalle';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:8; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:19; B_IP4:255;
   OrgName:'C‚gep de Saint-J‚rome';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:20; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:20; B_IP4:255;
   OrgName:'Rapace Multimedia Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:21; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:21; B_IP4:255;
   OrgName:'HMR inc.';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:22; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:22; B_IP4:255;
   OrgName:'Commission scolaire de Coaticook';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:23; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:23; B_IP4:255;
   OrgName:'Bureau de la statistique du Qu‚bec';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:24; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:24; B_IP4:255;
   OrgName:'CollŠge de Rosemont';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:26; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:26; B_IP4:255;
   OrgName:'CollŠge Delta';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:27; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:27; B_IP4:255;
   OrgName:'Assembl‚e nationale du Qu‚bec';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:28; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:28; B_IP4:255;
   OrgName:'MinistŠre des Affaires municipales, Gouvernement du Qu‚bec';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:29; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:29; B_IP4:255;
   OrgName:'Commission scolaire de Trois-RiviŠres';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:30; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:34; B_IP4:255;
   OrgName:'Commission Scolaire du Sault-Saint-Louis';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:35; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:71; B_IP4:255;
   OrgName:'COGECO Cable Canada Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:72; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:77; B_IP4:255;
   OrgName:'C‚gep de Saint-Laurent';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:78; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:78; B_IP4:255;
   OrgName:'CollŠge de Limoilou';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:80; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:87; B_IP4:255;
   OrgName:'C‚gep de Chicoutimi';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:210; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:219; B_IP4:255;
   OrgName:'C‚gep de Marie-Victorin';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:96; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:111; B_IP4:255;
   OrgName:'North East Data Vault';
   Country:11038),

  (A_IP1:205; A_IP2:237; A_IP3:128; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:159; B_IP4:255;
   OrgName:'KanOkla Communications';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:160; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:175; B_IP4:255;
   OrgName:'Internet Consulting Services LLC';
   Country:11038),

  (A_IP1:205; A_IP2:237; A_IP3:192; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:207; B_IP4:255;
   OrgName:'Ethernext Inc.';
   Country:11038),

  (A_IP1:205; A_IP2:237; A_IP3:220; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:224; B_IP4:255;
   OrgName:'C‚gep Saint-Jean-sur-Richelieu';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:225; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:225; B_IP4:255;
   OrgName:'Librairie Renaud-Bray (1981) Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:226; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:226; B_IP4:255;
   OrgName:'Progi-Soft Informatique (PSI)';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:227; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:229; B_IP4:255;
   OrgName:'CyberSecure Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:230; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:230; B_IP4:255;
   OrgName:'CPU Service inc.';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:231; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:231; B_IP4:255;
   OrgName:'CollŠge Matane';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:232; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:235; B_IP4:255;
   OrgName:'Videoway';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:236; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:236; B_IP4:255;
   OrgName:'Ecole commerciale du Cap';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:237; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:237; B_IP4:255;
   OrgName:'KOCHICA Communications, Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:238; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:239; B_IP4:255;
   OrgName:'PlanŠte Qu‚bec, Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:240; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:241; B_IP4:255;
   OrgName:'Office de la langue fran‡aise du Qu‚bec';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:242; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:242; B_IP4:255;
   OrgName:'Internet Haute-Yamasaka';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:243; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:247; B_IP4:255;
   OrgName:'CollŠge Lionel-Groulx';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:248; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:251; B_IP4:255;
   OrgName:'FMMO Publications Informatiques, Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:250; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:250; B_IP4:255;
   OrgName:'3Web Media Communications Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:252; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:252; B_IP4:255;
   OrgName:'Fonds FCAR';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:253; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:253; B_IP4:255;
   OrgName:'Soci‚t‚ qu‚bequoise d''information juridique';
   Country:10851),

  (A_IP1:205; A_IP2:237; A_IP3:254; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:254; B_IP4:255;
   OrgName:'Optimisation-Bureautique inc.';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:1; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:1; B_IP4:255;
   OrgName:'NETCORE-CA';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:2; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:2; B_IP4:255;
   OrgName:'Northern College of Applied Arts & Technology';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:3; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:3; B_IP4:255;
   OrgName:'Niagara Peninsula Industry Education Council';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:4; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:7; B_IP4:255;
   OrgName:'Internet Access Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:8; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:9; B_IP4:255;
   OrgName:'NETinc';
   Country:10841),

  (A_IP1:205; A_IP2:211; A_IP3:10; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:10; B_IP4:255;
   OrgName:'Foodservice and Hospitality Magazine';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:11; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:11; B_IP4:255;
   OrgName:'Redeemer Reformed Christian College';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:12; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:13; B_IP4:255;
   OrgName:'Toronto Internet Cooperative';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:14; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:14; B_IP4:255;
   OrgName:'Natural Sciences & Engineering Research Council';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:15; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:15; B_IP4:255;
   OrgName:'KMH Cardiology and Diagnostic Centers';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:16; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:23; B_IP4:255;
   OrgName:'College Boreal';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:26; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:78; B_IP4:255;
   OrgName:'Algonquin College';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:79; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:79; B_IP4:255;
   OrgName:'Visible Decisions, Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:80; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:80; B_IP4:255;
   OrgName:'Lonet Communications';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:81; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:81; B_IP4:255;
   OrgName:'Lake Superior Board of Education';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:82; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:82; B_IP4:255;
   OrgName:'Beacon Eye Institute';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:83; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:83; B_IP4:255;
   OrgName:'Caspar Computer Services Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:84; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:87; B_IP4:255;
   OrgName:'Tee-Comm Electronics, Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:88; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:90; B_IP4:255;
   OrgName:'St Clair College of Applied Arts and Technology';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:92; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:93; B_IP4:255;
   OrgName:'Internet Service Bureau of Canada';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:94; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:95; B_IP4:255;
   OrgName:'GTAnet Networking';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:96; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:127; B_IP4:255;
   OrgName:'Simcoe County District School Board';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:128; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:128; B_IP4:255;
   OrgName:'Breken Technologies Group';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:129; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:129; B_IP4:255;
   OrgName:'University of Toronto';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:130; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:131; B_IP4:255;
   OrgName:'Interware.net Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:132; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:135; B_IP4:255;
   OrgName:'Environnement Canada';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:136; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:136; B_IP4:255;
   OrgName:'CATIE';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:137; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:137; B_IP4:255;
   OrgName:'FTTCNet Canada';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:138; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:139; B_IP4:255;
   OrgName:'Bit Pacific Technologies Incorporated';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:140; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:145; B_IP4:255;
   OrgName:'Fanshawe College of Applied Arts and Technology';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:146; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:146; B_IP4:255;
   OrgName:'Westburne Industrial Enterprises Ltd.';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:147; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:147; B_IP4:255;
   OrgName:'Town of Atikokan';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:149; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:149; B_IP4:255;
   OrgName:'Internet Connectivity Services Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:150; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:151; B_IP4:151;
   OrgName:'Branksome Hall';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:152; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:153; B_IP4:255;
   OrgName:'Redden Cable TV Ltd.';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:154; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:155; B_IP4:255;
   OrgName:'Central Ontario Internet Services, Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:156; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:159; B_IP4:255;
   OrgName:'Durham College of applied Arts and Technology';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:160; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:160; B_IP4:255;
   OrgName:'University Health Network';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:161; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:161; B_IP4:255;
   OrgName:'Prescient International, Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:162; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:162; B_IP4:255;
   OrgName:'Electricity Distributors Association';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:163; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:163; B_IP4:255;
   OrgName:'Lakefield College School';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:164; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:165; B_IP4:255;
   OrgName:'Sentex Communications Corporation';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:168; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:169; B_IP4:255;
   OrgName:'Ontario College of Art and Design';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:170; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:170; B_IP4:255;
   OrgName:'Legasys Corporation';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:171; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:171; B_IP4:255;
   OrgName:'ObjecTime Limited';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:172; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:172; B_IP4:255;
   OrgName:'By The Falls Computers';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:173; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:173; B_IP4:255;
   OrgName:'Dryden Board of Education - Sioux';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:174; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:174; B_IP4:255;
   OrgName:'Queensway-Carleton Hospital';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:175; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:175; B_IP4:255;
   OrgName:'KawarthaNET';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:176; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:177; B_IP4:255;
   OrgName:'Caspar Computer Services Inc.';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:178; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:178; B_IP4:255;
   OrgName:'Hummingbird Communications Ltd.';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:179; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:179; B_IP4:255;
   OrgName:'Load, Human Resources Canada';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:180; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:183; B_IP4:255;
   OrgName:'Durham College of applied Arts and Technology';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:184; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:191; B_IP4:255;
   OrgName:'Ottawa Civic Hospital';
   Country:10851),

  (A_IP1:205; A_IP2:211; A_IP3:192; A_IP4:0;
   B_IP1:205; B_IP2:211; B_IP3:195; B_IP4:255;
   OrgName:'Amnet HON';
   Country:10909),

  (A_IP1:204; A_IP2:19; A_IP3:1; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:1; B_IP4:255;
   OrgName:'Absolu Technologies inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:2; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:7; B_IP4:255;
   OrgName:'C‚gep du Vieux-Montreal';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:8; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:9; B_IP4:255;
   OrgName:'AD OPT Technologies Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:10; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:12; B_IP4:255;
   OrgName:'CollŠge Lionel-Groulx';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:13; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:13; B_IP4:255;
   OrgName:'Icotech';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:14; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:15; B_IP4:255;
   OrgName:'Digital Equipment of Canada Ltd';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:16; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:16; B_IP4:255;
   OrgName:'AnsCo Information Systems LTD';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:17; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:17; B_IP4:255;
   OrgName:'Cedrom-Sni Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:18; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:19; B_IP4:255;
   OrgName:'Newlink Telecommunications';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:20; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:21; B_IP4:255;
   OrgName:'MKS Informatique';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:22; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:22; B_IP4:255;
   OrgName:'Simard Hamel Communications Limit‚e';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:23; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:23; B_IP4:255;
   OrgName:'Universit‚ de Sherbrooke';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:24; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:24; B_IP4:255;
   OrgName:'Acfas (Association canadienne-francaise pour l''avancement des sciences)';
   Country:10851),

  (A_IP1:24; A_IP2:37; A_IP3:0; A_IP4:0;
   B_IP1:24; B_IP2:37; B_IP3:255; B_IP4:255;
   OrgName:'Le Groupe Videotron Limit‚e';
   Country:10851),

  (A_IP1:195; A_IP2:46; A_IP3:217; A_IP4:0;
   B_IP1:195; B_IP2:46; B_IP3:217; B_IP4:255;
   OrgName:'MGN';
   Country:10887),

  (A_IP1:204; A_IP2:19; A_IP3:25; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:25; B_IP4:255;
   OrgName:'Le Groupe Conseil Innovitech';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:26; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:26; B_IP4:255;
   OrgName:'Comm. nord-americaine de coop. environmentale';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:27; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:27; B_IP4:255;
   OrgName:'Canadian Jewish Congress (CJC)';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:28; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:29; B_IP4:255;
   OrgName:'Roche ltee groupe conseil';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:29; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:29; B_IP4:255;
   OrgName:'Cantrex Groupe Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:30; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:32; B_IP4:255;
   OrgName:'CollŠge de JonquiŠre';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:33; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:33; B_IP4:255;
   OrgName:'Montreal Internet Inc';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:34; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:35; B_IP4:255;
   OrgName:'Mega Quebec';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:36; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:36; B_IP4:255;
   OrgName:'R‚seau Electronique du Montr‚al M‚tropolitain inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:37; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:37; B_IP4:255;
   OrgName:'Internet Saguenay Lac St-Jean inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:38; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:39; B_IP4:255;
   OrgName:'Le Groupe Berclain, Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:40; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:41; B_IP4:255;
   OrgName:'Valiquet Lamothe Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:42; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:42; B_IP4:255;
   OrgName:'Conf‚rence des Recteurs et des Principaux';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:43; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:43; B_IP4:255;
   OrgName:'Internet Trois-RiviŠres';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:44; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:47; B_IP4:255;
   OrgName:'R‚seau Internet Qu‚bec Inc';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:48; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:77; B_IP4:255;
   OrgName:'Institut de recherche d''Hydro-Quebec (IREQ)';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:78; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:78; B_IP4:255;
   OrgName:'Les Consultants Androide';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:79; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:79; B_IP4:255;
   OrgName:'National Film Board of Canada';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:80; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:87; B_IP4:255;
   OrgName:'Commission scolaire catholique de Sherbrooke';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:88; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:99; B_IP4:255;
   OrgName:'Memotec';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:100; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:101; B_IP4:255;
   OrgName:'Buzz Image Groupe Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:102; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:103; B_IP4:255;
   OrgName:'CGI Group Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:104; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:104; B_IP4:255;
   OrgName:'Centre de services aux bibliothŠques';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:105; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:105; B_IP4:255;
   OrgName:'Solcorp';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:106; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:107; B_IP4:255;
   OrgName:'MegaWeb Internet Network Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:108; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:108; B_IP4:255;
   OrgName:'CollŠge Jean-Guy Leboeuf Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:109; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:109; B_IP4:255;
   OrgName:'Soci‚t‚ de radio-t‚l‚vision du Qu‚bec Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:110; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:110; B_IP4:255;
   OrgName:'Rampart Partitions Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:111; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:111; B_IP4:255;
   OrgName:'Unicate Networks Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:112; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:112; B_IP4:255;
   OrgName:'ATS Aerospace - MW Network Operations';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:113; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:113; B_IP4:255;
   OrgName:'Institut de R‚adaptation de Montr‚al';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:114; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:114; B_IP4:255;
   OrgName:'Inter-Cable Internet Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:115; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:115; B_IP4:255;
   OrgName:'Richter, Usher & Vineberg';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:116; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:117; B_IP4:255;
   OrgName:'Information Technology Integration';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:118; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:118; B_IP4:255;
   OrgName:'Axones Telecommunications Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:120; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:120; B_IP4:255;
   OrgName:'Goodman Phillips & Vineberg';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:121; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:121; B_IP4:255;
   OrgName:'National-Com Internet Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:122; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:122; B_IP4:255;
   OrgName:'Cossette Communication Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:123; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:123; B_IP4:255;
   OrgName:'PC Dynamics Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:124; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:125; B_IP4:255;
   OrgName:'Reseau TakTik';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:126; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:127; B_IP4:255;
   OrgName:'SyncNet Communications Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:128; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:128; B_IP4:255;
   OrgName:'Commission scolaire des Draveurs';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:130; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:130; B_IP4:255;
   OrgName:'Club Macintosh de Qu‚bec Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:131; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:131; B_IP4:255;
   OrgName:'Omer DeSerres';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:132; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:133; B_IP4:255;
   OrgName:'Small Lately Users Group';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:134; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:134; B_IP4:255;
   OrgName:'Hydra Software';
   Country:10851),

  (A_IP1:209; A_IP2:71; A_IP3:206; A_IP4:16;
   B_IP1:209; B_IP2:71; B_IP3:206; B_IP4:23;
   OrgName:'Dotcom (Runes technology)';
   Country:10851),

  (A_IP1:195; A_IP2:83; A_IP3:68; A_IP4:0;
   B_IP1:195; B_IP2:83; B_IP3:68; B_IP4:255;
   OrgName:'Rectorat de l''acad‚mie de Poitiers';
   Country:10887),

  (A_IP1:204; A_IP2:19; A_IP3:135; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:135; B_IP4:255;
   OrgName:'Canadian Electricity Association';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:136; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:137; B_IP4:255;
   OrgName:'Insanely Interactive Systems Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:138; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:138; B_IP4:255;
   OrgName:'Micro Centra';
   Country:10851),

  (A_IP1:199; A_IP2:181; A_IP3:77; A_IP4:0;
   B_IP1:199; B_IP2:181; B_IP3:78; B_IP4:255;
   OrgName:'TigerDirect';
   Country:11038),

  (A_IP1:199; A_IP2:181; A_IP3:79; A_IP4:0;
   B_IP1:199; B_IP2:181; B_IP3:79; B_IP4:255;
   OrgName:'Micromedia';
   Country:11038),

  (A_IP1:192; A_IP2:150; A_IP3:14; A_IP4:0;
   B_IP1:192; B_IP2:150; B_IP3:14; B_IP4:255;
   OrgName:'Adobe Systems Inc.';
   Country:11038),

  (A_IP1:207; A_IP2:46; A_IP3:0; A_IP4:0;
   B_IP1:207; B_IP2:46; B_IP3:255; B_IP4:255;
   OrgName:'Microsoft Corp';
   Country:11038),

  (A_IP1:169; A_IP2:145; A_IP3:0; A_IP4:0;
   B_IP1:169; B_IP2:145; B_IP3:255; B_IP4:255;
   OrgName:'SAP America';
   Country:11038),

  (A_IP1:141; A_IP2:146; A_IP3:0; A_IP4:0;
   B_IP1:141; B_IP2:146; B_IP3:255; B_IP4:255;
   OrgName:'Oracle Corporation';
   Country:11038),

  (A_IP1:216; A_IP2:104; A_IP3:208; A_IP4:0;
   B_IP1:216; B_IP2:104; B_IP3:223; B_IP4:255;
   OrgName:'Macromedia Inc';
   Country:11038),

  (A_IP1:66; A_IP2:94; A_IP3:224; A_IP4:0;
   B_IP1:66; B_IP2:94; B_IP3:255; B_IP4:255;
   OrgName:'Yahoo!';
   Country:11038),

  (A_IP1:64; A_IP2:233; A_IP3:160; A_IP4:0;
   B_IP1:64; B_IP2:233; B_IP3:191; B_IP4:255;
   OrgName:'Google Inc.';
   Country:11038),

  (A_IP1:72; A_IP2:5; A_IP3:124; A_IP4:0;
   B_IP1:72; B_IP2:5; B_IP3:125; B_IP4:255;
   OrgName:'Sun Microsystems';
   Country:11038),

  (A_IP1:199; A_IP2:60; A_IP3:112; A_IP4:0;
   B_IP1:199; B_IP2:60; B_IP3:115; B_IP4:255;
   OrgName:'Future Shop Ltd.';
   Country:10851),

  (A_IP1:207; A_IP2:236; A_IP3:183; A_IP4:64;
   B_IP1:207; B_IP2:236; B_IP3:183; B_IP4:95;
   OrgName:'Ville de Laval';
   Country:10851),

  (A_IP1:142; A_IP2:243; A_IP3:0; A_IP4:0;
   B_IP1:142; B_IP2:243; B_IP3:255; B_IP4:255;
   OrgName:'Ville de Montr‚al';
   Country:10851),

  (A_IP1:84; A_IP2:96; A_IP3:34; A_IP4:16;
   B_IP1:84; B_IP2:96; B_IP3:34; B_IP4:31;
   OrgName:'Internet Services - Didier LE BRETON';
   Country:10887),

  (A_IP1:204; A_IP2:19; A_IP3:139; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:139; B_IP4:255;
   OrgName:'Sico Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:140; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:140; B_IP4:255;
   OrgName:'Cognologic Software Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:141; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:143; B_IP4:255;
   OrgName:'L''Union des Producteurs Agricoles';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:144; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:151; B_IP4:255;
   OrgName:'Abitibi Consolidated Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:152; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:153; B_IP4:255;
   OrgName:'Sisca Informatique inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:154; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:155; B_IP4:255;
   OrgName:'Arena Communications';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:156; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:156; B_IP4:255;
   OrgName:'Stone Consolidated Canada';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:157; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:157; B_IP4:255;
   OrgName:'CyberConcept Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:158; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:158; B_IP4:255;
   OrgName:'Commission Scolaire Verdun';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:159; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:159; B_IP4:255;
   OrgName:'M & R';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:160; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:160; B_IP4:255;
   OrgName:'Core-net inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:161; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:161; B_IP4:255;
   OrgName:'Sapience Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:163; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:163; B_IP4:255;
   OrgName:'Zercom Technologies Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:164; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:164; B_IP4:255;
   OrgName:'Choreo Systems Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:165; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:165; B_IP4:255;
   OrgName:'ConnecTalk Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:166; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:167; B_IP4:255;
   OrgName:'Varnet Information Systems Inc';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:168; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:169; B_IP4:255;
   OrgName:'MPACT Immedia Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:170; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:171; B_IP4:255;
   OrgName:'Magnet Internet Gateway';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:172; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:175; B_IP4:255;
   OrgName:'Ville de Sherbrooke';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:176; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:176; B_IP4:255;
   OrgName:'Logibro Inc';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:177; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:177; B_IP4:255;
   OrgName:'AED Internet Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:178; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:178; B_IP4:255;
   OrgName:'Francois Beauregard Logiciels inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:179; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:179; B_IP4:255;
   OrgName:'IdMEDIA';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:180; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:183; B_IP4:255;
   OrgName:'Astra Research Unit';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:184; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:185; B_IP4:255;
   OrgName:'Internet Estrie';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:186; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:186; B_IP4:255;
   OrgName:'Omniplus Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:187; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:187; B_IP4:255;
   OrgName:'V.I.T. Voyages Intair Transit Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:188; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:191; B_IP4:255;
   OrgName:'Communications Accessibles Montreal Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:192; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:199; B_IP4:255;
   OrgName:'STS Systems Inc';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:206; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:207; B_IP4:255;
   OrgName:'AEI Internet Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:209; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:210; B_IP4:255;
   OrgName:'Centre de recherche Volvox';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:211; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:211; B_IP4:255;
   OrgName:'Starber International Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:212; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:215; B_IP4:255;
   OrgName:'La Capitale, compagnie d''assurance g‚n‚rale';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:216; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:216; B_IP4:255;
   OrgName:'Logistec Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:217; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:218; B_IP4:255;
   OrgName:'Honeybee Software Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:219; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:219; B_IP4:255;
   OrgName:'Logiciels Object Inc';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:220; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:220; B_IP4:255;
   OrgName:'Groupe LGS Inc';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:221; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:221; B_IP4:255;
   OrgName:'Internet Management Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:222; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:222; B_IP4:255;
   OrgName:'Bombardier Inc. Canadair';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:224; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:225; B_IP4:255;
   OrgName:'LINQ Communications';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:226; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:227; B_IP4:255;
   OrgName:'Ferst Consultants Ltd.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:228; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:228; B_IP4:255;
   OrgName:'Safe Engineering Services Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:229; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:229; B_IP4:255;
   OrgName:'Aniq Ltd.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:230; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:230; B_IP4:255;
   OrgName:'Ultimate Technographics Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:231; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:231; B_IP4:255;
   OrgName:'Bestseller Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:232; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:233; B_IP4:255;
   OrgName:'Equifax Canada Inc';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:234; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:235; B_IP4:255;
   OrgName:'Coffeehaus, Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:236; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:237; B_IP4:255;
   OrgName:'Le Groupe Informatique MEI Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:238; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:239; B_IP4:255;
   OrgName:'Nuke Laboratoire';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:240; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:240; B_IP4:255;
   OrgName:'Alroma Scientifique Inc.';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:243; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:243; B_IP4:255;
   OrgName:'Lectra Systems Inc';
   Country:10851),

  (A_IP1:204; A_IP2:19; A_IP3:248; A_IP4:0;
   B_IP1:204; B_IP2:19; B_IP3:254; B_IP4:255;
   OrgName:'ClicNet Telecommunications Inc.';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:178; A_IP4:0;
   B_IP1:207; B_IP2:96; B_IP3:178; B_IP4:15;
   OrgName:'Papiers Fraser inc (Canada)';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:246; A_IP4:32;
   B_IP1:207; B_IP2:96; B_IP3:246; B_IP4:79;
   OrgName:'Soci‚t‚ des alcools du Qu‚bec';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:247; A_IP4:128;
   B_IP1:207; B_IP2:96; B_IP3:247; B_IP4:255;
   OrgName:'STR Inc.';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:248; A_IP4:0;
   B_IP1:207; B_IP2:96; B_IP3:248; B_IP4:255;
   OrgName:'OIIQ';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:250; A_IP4:0;
   B_IP1:207; B_IP2:96; B_IP3:250; B_IP4:15;
   OrgName:'Trans Optique inc.';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:250; A_IP4:16;
   B_IP1:207; B_IP2:96; B_IP3:250; B_IP4:31;
   OrgName:'Superclub Videotron Limit‚e';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:250; A_IP4:64;
   B_IP1:207; B_IP2:96; B_IP3:250; B_IP4:127;
   OrgName:'Capella Technologie';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:251; A_IP4:192;
   B_IP1:207; B_IP2:96; B_IP3:251; B_IP4:255;
   OrgName:'Cyber Cat Inc';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:244; A_IP4:0;
   B_IP1:207; B_IP2:96; B_IP3:245; B_IP4:255;
   OrgName:'La bande Passante';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:243; A_IP4:0;
   B_IP1:207; B_IP2:96; B_IP3:243; B_IP4:255;
   OrgName:'Coop‚rative de cablodistribution de l''arriŠre-pays';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:239; A_IP4:0;
   B_IP1:207; B_IP2:96; B_IP3:239; B_IP4:255;
   OrgName:'Equifax Canada Inc';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:240; A_IP4:0;
   B_IP1:207; B_IP2:96; B_IP3:240; B_IP4:63;
   OrgName:'Musiqueplus';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:238; A_IP4:128;
   B_IP1:207; B_IP2:96; B_IP3:238; B_IP4:135;
   OrgName:'Institut St-Joseph';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:237; A_IP4:0;
   B_IP1:207; B_IP2:96; B_IP3:237; B_IP4:255;
   OrgName:'Institut Canadien du Qu‚bec';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:235; A_IP4:192;
   B_IP1:207; B_IP2:96; B_IP3:235; B_IP4:223;
   OrgName:'Soci‚t‚ Team';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:235; A_IP4:128;
   B_IP1:207; B_IP2:96; B_IP3:235; B_IP4:159;
   OrgName:'Association Interm‚diaire en Assurance de Personnes du Qu‚bec';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:233; A_IP4:0;
   B_IP1:207; B_IP2:96; B_IP3:233; B_IP4:255;
   OrgName:'Commission Scolaire de St-Hyacinthe';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:226; A_IP4:128;
   B_IP1:207; B_IP2:96; B_IP3:226; B_IP4:191;
   OrgName:'BibliothŠque de Ville de Lasalle';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:161; A_IP4:64;
   B_IP1:207; B_IP2:96; B_IP3:161; B_IP4:95;
   OrgName:'Soci‚t‚ G‚n‚rale de Financement du Qu‚bec';
   Country:10851),

  (A_IP1:207; A_IP2:96; A_IP3:0; A_IP4:0;
   B_IP1:207; B_IP2:96; B_IP3:127; B_IP4:255;
   OrgName:'RCN Corporation';
   Country:11038),

  (A_IP1:216; A_IP2:254; A_IP3:94; A_IP4:192;
   B_IP1:216; B_IP2:254; B_IP3:94; B_IP4:223;
   OrgName:'Advanced Computing Solutions';
   Country:11038),

  (A_IP1:216; A_IP2:254; A_IP3:94; A_IP4:248;
   B_IP1:216; B_IP2:254; B_IP3:94; B_IP4:255;
   OrgName:'Netline Internet Solutions';
   Country:11038),

  (A_IP1:216; A_IP2:254; A_IP3:94; A_IP4:240;
   B_IP1:216; B_IP2:254; B_IP3:94; B_IP4:247;
   OrgName:'NewVenue.com';
   Country:11038),

  (A_IP1:216; A_IP2:254; A_IP3:94; A_IP4:160;
   B_IP1:216; B_IP2:254; B_IP3:94; B_IP4:191;
   OrgName:'Giga Information Group';
   Country:11038),

  (A_IP1:63; A_IP2:112; A_IP3:168; A_IP4:0;
   B_IP1:63; B_IP2:112; B_IP3:171; B_IP4:255;
   OrgName:'Monster.com';
   Country:11038),

  (A_IP1:158; A_IP2:228; A_IP3:0; A_IP4:0;
   B_IP1:158; B_IP2:228; B_IP3:255; B_IP4:255;
   OrgName:'Kronos Inc.';
   Country:11038),

  (A_IP1:158; A_IP2:229; A_IP3:0; A_IP4:0;
   B_IP1:158; B_IP2:229; B_IP3:255; B_IP4:255;
   OrgName:'Florida Department of Insurance';
   Country:11038),

  (A_IP1:216; A_IP2:46; A_IP3:31; A_IP4:64;
   B_IP1:216; B_IP2:46; B_IP3:31; B_IP4:127;
   OrgName:'EGP Techno Virtuel';
   Country:10851),

  (A_IP1:216; A_IP2:46; A_IP3:0; A_IP4:0;
   B_IP1:216; B_IP2:46; B_IP3:31; B_IP4:255;
   OrgName:'Openface Inc.';
   Country:10851),

  (A_IP1:216; A_IP2:46; A_IP3:2; A_IP4:0;
   B_IP1:216; B_IP2:46; B_IP3:2; B_IP4:15;
   OrgName:'High Touch Communications';
   Country:10851),

  (A_IP1:216; A_IP2:46; A_IP3:2; A_IP4:160;
   B_IP1:216; B_IP2:46; B_IP3:2; B_IP4:191;
   OrgName:'Tˆte Chercheuse';
   Country:10851),

  (A_IP1:216; A_IP2:46; A_IP3:2; A_IP4:192;
   B_IP1:216; B_IP2:46; B_IP3:2; B_IP4:223;
   OrgName:'E-Space Connexions';
   Country:10851),

  (A_IP1:216; A_IP2:46; A_IP3:3; A_IP4:96;
   B_IP1:216; B_IP2:46; B_IP3:3; B_IP4:127;
   OrgName:'Solution Microplus Data Lan Inc.';
   Country:10851),

  (A_IP1:216; A_IP2:46; A_IP3:39; A_IP4:32;
   B_IP1:216; B_IP2:46; B_IP3:39; B_IP4:63;
   OrgName:'PC Innovations';
   Country:11038),

  (A_IP1:216; A_IP2:46; A_IP3:32; A_IP4:0;
   B_IP1:216; B_IP2:46; B_IP3:63; B_IP4:255;
   OrgName:'Homenet Communications, Inc.';
   Country:11038),

  (A_IP1:192; A_IP2:220; A_IP3:0; A_IP4:0;
   B_IP1:192; B_IP2:220; B_IP3:255; B_IP4:255;
   OrgName:'NTT America, Inc.';
   Country:11038),

  (A_IP1:207; A_IP2:96; A_IP3:218; A_IP4:0;
   B_IP1:207; B_IP2:96; B_IP3:218; B_IP4:31;
   OrgName:'Algorithme Pharma inc.';
   Country:10851),

  (A_IP1:207; A_IP2:253; A_IP3:225; A_IP4:128;
   B_IP1:207; B_IP2:253; B_IP3:225; B_IP4:191;
   OrgName:'Groupe Educalivres Inc.';
   Country:10851),

  (A_IP1:199; A_IP2:243; A_IP3:141; A_IP4:8;
   B_IP1:199; B_IP2:243; B_IP3:141; B_IP4:15;
   OrgName:'Cofomo Inc';
   Country:10851),

  (A_IP1:64; A_IP2:254; A_IP3:224; A_IP4:0;
   B_IP1:64; B_IP2:254; B_IP3:255; B_IP4:255;
   OrgName:'MTO Telecom Inc.';
   Country:10851),

  (A_IP1:69; A_IP2:90; A_IP3:0; A_IP4:0;
   B_IP1:69; B_IP2:90; B_IP3:255; B_IP4:255;
   OrgName:'Peer 1 Network Inc.';
   Country:11038),

  (A_IP1:69; A_IP2:90; A_IP3:203; A_IP4:192;
   B_IP1:69; B_IP2:90; B_IP3:203; B_IP4:223;
   OrgName:'Integrated Information Vertex';
   Country:10851),

  (A_IP1:198; A_IP2:73; A_IP3:180; A_IP4:0;
   B_IP1:198; B_IP2:73; B_IP3:180; B_IP4:255;
   OrgName:'Communications Accessibles Montreal Inc.';
   Country:10851),

  (A_IP1:64; A_IP2:254; A_IP3:231; A_IP4:144;
   B_IP1:64; B_IP2:254; B_IP3:231; B_IP4:151;
   OrgName:'Merkurium Performance Indicators';
   Country:10851),

  (A_IP1:207; A_IP2:112; A_IP3:0; A_IP4:0;
   B_IP1:207; B_IP2:112; B_IP3:127; B_IP4:255;
   OrgName:'Primus Telecommunications Canada Inc.';
   Country:10851),

  (A_IP1:66; A_IP2:98; A_IP3:128; A_IP4:0;
   B_IP1:66; B_IP2:98; B_IP3:255; B_IP4:255;
   OrgName:'Everyones Internet';
   Country:11038),

  (A_IP1:67; A_IP2:69; A_IP3:38; A_IP4:0;
   B_IP1:67; B_IP2:69; B_IP3:38; B_IP4:7;
   OrgName:'Systematix Technologies';
   Country:10851),

  (A_IP1:66; A_IP2:235; A_IP3:192; A_IP4:0;
   B_IP1:66; B_IP2:235; B_IP3:223; B_IP4:255;
   OrgName:'iPowerWeb, Inc.';
   Country:11038),

  (A_IP1:67; A_IP2:15; A_IP3:0; A_IP4:0;
   B_IP1:67; B_IP2:15; B_IP3:255; B_IP4:255;
   OrgName:'Everyones Internet';
   Country:11038),

  (A_IP1:64; A_IP2:141; A_IP3:0; A_IP4:0;
   B_IP1:64; B_IP2:141; B_IP3:127; B_IP4:255;
   OrgName:'Big Pipe Inc.';
   Country:10851),

  (A_IP1:151; A_IP2:198; A_IP3:48; A_IP4:0;
   B_IP1:151; B_IP2:198; B_IP3:48; B_IP4:63;
   OrgName:'Ridgewood Board of Education';
   Country:11038),

  (A_IP1:151; A_IP2:196; A_IP3:0; A_IP4:0;
   B_IP1:151; B_IP2:205; B_IP3:255; B_IP4:255;
   OrgName:'Verizon Internet Services Inc.';
   Country:11038),

  (A_IP1:207; A_IP2:253; A_IP3:194; A_IP4:24;
   B_IP1:207; B_IP2:253; B_IP3:194; B_IP4:24;
   OrgName:'Nurun';
   Country:10851),

  (A_IP1:216; A_IP2:127; A_IP3:64; A_IP4:0;
   B_IP1:216; B_IP2:127; B_IP3:95; B_IP4:255;
   OrgName:'Everyones Internet';
   Country:11038),

  (A_IP1:64; A_IP2:254; A_IP3:228; A_IP4:128;
   B_IP1:64; B_IP2:254; B_IP3:228; B_IP4:159;
   OrgName:'Synersoft Inc.';
   Country:10851),

  (A_IP1:209; A_IP2:104; A_IP3:82; A_IP4:128;
   B_IP1:209; B_IP2:104; B_IP3:82; B_IP4:255;
   OrgName:'Logica';
   Country:10851),

  (A_IP1:207; A_IP2:253; A_IP3:24; A_IP4:96;
   B_IP1:207; B_IP2:253; B_IP3:24; B_IP4:103;
   OrgName:'FTQ';
   Country:10851),

  (A_IP1:159; A_IP2:33; A_IP3:0; A_IP4:0;
   B_IP1:159; B_IP2:33; B_IP3:255; B_IP4:255;
   OrgName:'Canadian Broadcasting Corporation';
   Country:10851),

  (A_IP1:209; A_IP2:172; A_IP3:32; A_IP4:0;
   B_IP1:209; B_IP2:172; B_IP3:63; B_IP4:255;
   OrgName:'Groupe iWeb Technologies inc.';
   Country:10851),

  (A_IP1:192; A_IP2:169; A_IP3:0; A_IP4:0;
   B_IP1:192; B_IP2:169; B_IP3:1; B_IP4:255;
   OrgName:'RGnet, LLC';
   Country:11038),

  (A_IP1:192; A_IP2:169; A_IP3:2; A_IP4:0;
   B_IP1:192; B_IP2:169; B_IP3:4; B_IP4:255;
   OrgName:'FMC Technologies, Inc.';
   Country:11038),

  (A_IP1:192; A_IP2:169; A_IP3:8; A_IP4:0;
   B_IP1:192; B_IP2:169; B_IP3:9; B_IP4:255;
   OrgName:'IEM, Inc.';
   Country:11038),

  (A_IP1:69; A_IP2:90; A_IP3:205; A_IP4:128;
   B_IP1:69; B_IP2:90; B_IP3:205; B_IP4:255;
   OrgName:'QITX';
   Country:10851),

  (A_IP1:204; A_IP2:174; A_IP3:223; A_IP4:0;
   B_IP1:204; B_IP2:174; B_IP3:223; B_IP4:255;
   OrgName:'NetNation Communications Inc';
   Country:11038),

  (A_IP1:207; A_IP2:228; A_IP3:224; A_IP4:0;
   B_IP1:207; B_IP2:228; B_IP3:255; B_IP4:255;
   OrgName:'HopOne Internet Corporation';
   Country:11038),

  (A_IP1:207; A_IP2:183; A_IP3:37; A_IP4:0;
   B_IP1:207; B_IP2:183; B_IP3:37; B_IP4:255;
   OrgName:'Pixelweb';
   Country:10851),

  (A_IP1:198; A_IP2:168; A_IP3:250; A_IP4:0;
   B_IP1:198; B_IP2:168; B_IP3:251; B_IP4:255;
   OrgName:'DMR Consulting, Inc.';
   Country:10851),

  (A_IP1:199; A_IP2:246; A_IP3:60; A_IP4:0;
   B_IP1:199; B_IP2:246; B_IP3:71; B_IP4:255;
   OrgName:'The Globe and Mail';
   Country:10851),

  (A_IP1:219; A_IP2:0; A_IP3:0; A_IP4:0;
   B_IP1:219; B_IP2:63; B_IP3:255; B_IP4:255;
   OrgName:'SoftBank BB Corp';
   Country:10924),

  (A_IP1:196; A_IP2:28; A_IP3:240; A_IP4:0;
   B_IP1:196; B_IP2:28; B_IP3:255; B_IP4:255;
   OrgName:'ONATEL (Office National des T‚l‚communications, PTT)';
   Country:10836),

  (A_IP1:134; A_IP2:212; A_IP3:0; A_IP4:0;
   B_IP1:134; B_IP2:212; B_IP3:255; B_IP4:255;
   OrgName:'Office National d''Etudes et de Recherches A‚ronautiques';
   Country:10887),

  (A_IP1:195; A_IP2:56; A_IP3:8; A_IP4:0;
   B_IP1:195; B_IP2:56; B_IP3:9; B_IP4:255;
   OrgName:'GTS-DataNet Tavkozlesi Kft.';
   Country:10912),

  (A_IP1:209; A_IP2:161; A_IP3:192; A_IP4:0;
   B_IP1:209; B_IP2:161; B_IP3:255; B_IP4:255;
   OrgName:'Look Communications Inc.';
   Country:10851),

  (A_IP1:209; A_IP2:161; A_IP3:209; A_IP4:0;
   B_IP1:209; B_IP2:161; B_IP3:209; B_IP4:63;
   OrgName:'MacDonald Administration Services';
   Country:10851),

  (A_IP1:212; A_IP2:147; A_IP3:0; A_IP4:0;
   B_IP1:212; B_IP2:147; B_IP3:63; B_IP4:255;
   OrgName:'VTX Services SA';
   Country:10856),

  (A_IP1:60; A_IP2:32; A_IP3:0; A_IP4:0;
   B_IP1:60; B_IP2:47; B_IP3:255; B_IP4:255;
   OrgName:'NTT Communications Corporation';
   Country:10924),

  (A_IP1:60; A_IP2:35; A_IP3:0; A_IP4:0;
   B_IP1:60; B_IP2:35; B_IP3:255; B_IP4:255;
   OrgName:'Plala Networks Inc.';
   Country:10924),

  (A_IP1:86; A_IP2:66; A_IP3:128; A_IP4:0;
   B_IP1:86; B_IP2:71; B_IP3:254; B_IP4:255;
   OrgName:'Neuf telecom (gaoland.net)';
   Country:10887),

  (A_IP1:192; A_IP2:192; A_IP3:0; A_IP4:0;
   B_IP1:192; B_IP2:192; B_IP3:255; B_IP4:255;
   OrgName:'Ministry of Education computer Center';
   Country:11033),

  (A_IP1:195; A_IP2:68; A_IP3:0; A_IP4:0;
   B_IP1:195; B_IP2:68; B_IP3:127; B_IP4:255;
   OrgName:'COLT Telecom GmbH';
   Country:10890),

  (A_IP1:205; A_IP2:205; A_IP3:91; A_IP4:0;
   B_IP1:205; B_IP2:205; B_IP3:91; B_IP4:63;
   OrgName:'Primonics Inc.';
   Country:10851),

  (A_IP1:207; A_IP2:61; A_IP3:145; A_IP4:0;
   B_IP1:207; B_IP2:61; B_IP3:145; B_IP4:63;
   OrgName:'Banque Nationale du Canada';
   Country:10851),

  (A_IP1:146; A_IP2:19; A_IP3:0; A_IP4:0;
   B_IP1:146; B_IP2:19; B_IP3:255; B_IP4:255;
   OrgName:'Ecole pour les Etudes et la Recherche en Informatique et Electronique';
   Country:10887),

  (A_IP1:62; A_IP2:39; A_IP3:103; A_IP4:0;
   B_IP1:62; B_IP2:39; B_IP3:103; B_IP4:255;
   OrgName:'VIVACTION - Groupe ITN France';
   Country:10887),

  (A_IP1:216; A_IP2:98; A_IP3:48; A_IP4:0;
   B_IP1:216; B_IP2:98; B_IP3:63; B_IP4:255;
   OrgName:'Ubisoft Entertainment';
   Country:10851),

  (A_IP1:216; A_IP2:98; A_IP3:64; A_IP4:0;
   B_IP1:216; B_IP2:98; B_IP3:95; B_IP4:255;
   OrgName:'NetAccess, Inc.';
   Country:11038),

  (A_IP1:205; A_IP2:233; A_IP3:198; A_IP4:0;
   B_IP1:205; B_IP2:233; B_IP3:198; B_IP4:255;
   OrgName:'Acces-Cible Inc.';
   Country:10851),

  (A_IP1:62; A_IP2:244; A_IP3:70; A_IP4:0;
   B_IP1:62; B_IP2:244; B_IP3:70; B_IP4:255;
   OrgName:'RMI Informatique';
   Country:10887),

  (A_IP1:216; A_IP2:137; A_IP3:104; A_IP4:0;
   B_IP1:216; B_IP2:137; B_IP3:107; B_IP4:255;
   OrgName:'Rocler Technologies';
   Country:10851),

  (A_IP1:142; A_IP2:131; A_IP3:0; A_IP4:0;
   B_IP1:142; B_IP2:131; B_IP3:255; B_IP4:255;
   OrgName:'Fairmont Hotels & Resorts Inc.';
   Country:10851),

  (A_IP1:208; A_IP2:101; A_IP3:0; A_IP4:0;
   B_IP1:208; B_IP2:101; B_IP3:63; B_IP4:255;
   OrgName:'SoftLayer Technologies Inc.';
   Country:11038),

  (A_IP1:199; A_IP2:243; A_IP3:80; A_IP4:240;
   B_IP1:199; B_IP2:243; B_IP3:80; B_IP4:247;
   OrgName:'Simmco (Mutual-Tech Quebec)';
   Country:10851),

  (A_IP1:216; A_IP2:94; A_IP3:216; A_IP4:0;
   B_IP1:216; B_IP2:94; B_IP3:216; B_IP4:31;
   OrgName:'Le Groupe RO-NA Dismat';
   Country:10851),

  (A_IP1:206; A_IP2:47; A_IP3:249; A_IP4:0;
   B_IP1:206; B_IP2:47; B_IP3:249; B_IP4:249;
   OrgName:'Informatique Rive-Sud';
   Country:10851),

  (A_IP1:61; A_IP2:127; A_IP3:108; A_IP4:160;
   B_IP1:61; B_IP2:127; B_IP3:108; B_IP4:175;
   OrgName:'Sodegaura Education Center';
   Country:10924),

  (A_IP1:192; A_IP2:25; A_IP3:81; A_IP4:0;
   B_IP1:192; B_IP2:25; B_IP3:100; B_IP4:255;
   OrgName:'Agilent Technologies';
   Country:11038),

  (A_IP1:69; A_IP2:157; A_IP3:240; A_IP4:0;
   B_IP1:69; B_IP2:157; B_IP3:240; B_IP4:255;
   OrgName:'Sympatico HSE';
   Country:10851),

  (A_IP1:199; A_IP2:243; A_IP3:181; A_IP4:72;
   B_IP1:199; B_IP2:243; B_IP3:181; B_IP4:79;
   OrgName:'Informatique C“t‚, Coulombe Inc';
   Country:10851),

  (A_IP1:66; A_IP2:158; A_IP3:128; A_IP4:0;
   B_IP1:66; B_IP2:158; B_IP3:159; B_IP4:159;
   OrgName:'B2B2C Inc';
   Country:10851),

  (A_IP1:131; A_IP2:107; A_IP3:0; A_IP4:0;
   B_IP1:131; B_IP2:107; B_IP3:255; B_IP4:255;
   OrgName:'Microsoft Corp';
   Country:11038),

  (A_IP1:205; A_IP2:237; A_IP3:248; A_IP4:0;
   B_IP1:205; B_IP2:237; B_IP3:248; B_IP4:255;
   OrgName:'Electro-Informatique Michaud';
   Country:10851),

  (A_IP1:66; A_IP2:38; A_IP3:215; A_IP4:24;
   B_IP1:66; B_IP2:38; B_IP3:215; B_IP4:31;
   OrgName:'Gestion Jaran';
   Country:10851),

  (A_IP1:64; A_IP2:235; A_IP3:192; A_IP4:0;
   B_IP1:64; B_IP2:235; B_IP3:223; B_IP4:255;
   OrgName:'Work Integrated Networks, Inc.';
   Country:10851),

  (A_IP1:198; A_IP2:103; A_IP3:53; A_IP4:0;
   B_IP1:198; B_IP2:103; B_IP3:53; B_IP4:255;
   OrgName:'Finance Canada and Treasury Board Secretariat';
   Country:10851),

  (A_IP1:216; A_IP2:18; A_IP3:119; A_IP4:112;
   B_IP1:216; B_IP2:18; B_IP3:119; B_IP4:127;
   OrgName:'MSDS Solutions Inc/Conceptum Inc';
   Country:10851),

  (A_IP1:204; A_IP2:101; A_IP3:221; A_IP4:224;
   B_IP1:204; B_IP2:101; B_IP3:221; B_IP4:255;
   OrgName:'Sucre Lantic Limit‚e';
   Country:10851),

  (A_IP1:41; A_IP2:223; A_IP3:248; A_IP4:0;
   B_IP1:41; B_IP2:223; B_IP3:251; B_IP4:255;
   OrgName:'Omnium des Telecom et de l''internet';
   Country:10840),

  (A_IP1:66; A_IP2:201; A_IP3:205; A_IP4:160;
   B_IP1:66; B_IP2:201; B_IP3:205; B_IP4:167;
   OrgName:'Conseil G‚n‚ral de D‚veloppement de Montr‚al';
   Country:10851),

  (A_IP1:192; A_IP2:193; A_IP3:0; A_IP4:0;
   B_IP1:192; B_IP2:193; B_IP3:255; B_IP4:255;
   OrgName:'Citicorp Global Information Network';
   Country:11038),

  (A_IP1:207; A_IP2:253; A_IP3:2; A_IP4:192;
   B_IP1:207; B_IP2:253; B_IP3:2; B_IP4:223;
   OrgName:'Multi-Solutions inc.';
   Country:10851),

  (A_IP1:198; A_IP2:168; A_IP3:234; A_IP4:0;
   B_IP1:198; B_IP2:168; B_IP3:243; B_IP4:255;
   OrgName:'Soci‚t‚ de l''Assurance Automobile du Qu‚bec';
   Country:10851)
 );

Var
 I,J,K:Integer;
 IP:Array[1..4]of Byte;
 PosIP:Byte;
 Err:Word;
 CurrParam,CurrIP:String;


BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('WHOIS : Cette commande permet de recherche l''organisme ',
          'associe avec un IP.');
  WriteLn;
  WriteLn('Syntaxe : WHOIS [ip]');
  WriteLn;
  WriteLn(' ip   Ce parametre permet d''indiquer une adresse IPv4 (x.x.x.x)');
  WriteLn;
  WriteLn('NB: Les donnees sont bases sur un dictionnaire locale hors ligne ');
  WriteLn('depuis 2006. Les donnees peuvent ne pas etre exacte a cause ');
  WriteLn('des nombreuses fluctuations dans l''infonuagique.')
 End
  Else
 If ParamCount>0Then Begin
  For I:=1 to ParamCount do Begin
   CurrParam:=ParamStr(I);
   CurrIP:='';
   IP[1]:=0;IP[2]:=0;IP[3]:=0;IP[4]:=0;PosIP:=1;
   For J:=1 to Length(CurrParam)do Begin
    If CurrParam[J]='.'Then Begin
     Val(CurrIP,IP[PosIP],Err);
     CurrIP:='';
     Inc(PosIP);
     If PosIP>=5Then Begin
      WriteLn('Adresse IP de format IPv4 attendu');
      Halt;
     End;
    End
     Else
    CurrIP:=CurrIP+CurrParam[J];
   End;
   If CurrIP<>''Then Begin
    Val(CurrIP,IP[PosIP],Err);
    CurrIP:='';
   End;
   For J:=Low(IPNetRangeList) to High(IPNetRangeList)do Begin
    If((IP[1]>=IPNetRangeList[J].A_IP1)and(IP[1]<=IPNetRangeList[J].B_IP1))and
      ((IP[2]>=IPNetRangeList[J].A_IP2)and(IP[2]<=IPNetRangeList[J].B_IP2))and
      ((IP[3]>=IPNetRangeList[J].A_IP3)and(IP[3]<=IPNetRangeList[J].B_IP3))and
      ((IP[4]>=IPNetRangeList[J].A_IP4)and(IP[4]<=IPNetRangeList[J].B_IP4))Then Begin
     WriteLn('Adresse IPv4 :          ',IP[1],'.',IP[2],'.',IP[3],'.',IP[4]);
     WriteLn('Intervalle reseau :     ',IPNetRangeList[J].A_IP1,'.',
                                        IPNetRangeList[J].A_IP2,'.',
                                        IPNetRangeList[J].A_IP3,'.',
                                        IPNetRangeList[J].A_IP4,' a ',
                                        IPNetRangeList[J].B_IP1,'.',
                                        IPNetRangeList[J].B_IP2,'.',
                                        IPNetRangeList[J].B_IP3,'.',
                                        IPNetRangeList[J].B_IP4);
     WriteLn('Nom de l''organisation : ',StrPas(IPNetRangeList[J].OrgName));
     Write('Pays d''origine :        ');
     For K:=Low(CountryList) to High(CountryList)do Begin
      If(IPNetRangeList[J].Country=CountryList[K].Value)Then Begin
       WriteLn(StrPas(CountryList[K].CountryName));
       Break;
      End;
     End;
    End;
   End;
  End;
 End;
END.