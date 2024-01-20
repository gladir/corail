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

 FirstNameList:Array[0..5]of PChar=(
  'Andr‚','BenoŒt','Jacques','Sophie','Steeve','Sylvain'
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

 JobsList:Array[0..11]of PChar=(
  'Agent immobilier','Analyste','Astronome','Barmen','Biologiste',
  'Blogueur','Diplomate','lectricien','G‚n‚ticien','Guitariste',
  'Journaliste','Programmeur'
 );

Type
 GroupType=(None,City,FirstName,LastName,FullName,IntegerNumber,
            RealNumber,Job,Price);

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
  WriteLn(' city         Colonne de ville');
  WriteLn(' firstname    Colonne de pr‚nom');
  WriteLn(' fullname     Colonne de pr‚nom et nom');
  WriteLn(' integer      Colonne d''un nombre entier');
  WriteLn(' job          Colonne de travail');
  WriteLn(' lasttname    Colonne de nom de famille');
  WriteLn(' price        Colonne de prix');
  WriteLn(' real         Colonne d''un nombre r‚el');
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
   If StrToUpper(ParamStr(I))='CITY'Then Begin
    GroupList[GroupNum]:=City;
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
   End;
  End;
  If GroupNum>0 Then For J:=1 to Rows do Begin
   For I:=0 to GroupNum-1 do Begin
    Case GroupList[I] of
     City:CurrField:=StrPas(CityList[Random(High(CityList))]);
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
     Else CurrField:='';
    End;
    If I>0 Then Write(Delimiter);
    Write(CurrField);
   End;
   WriteLn;
  End;
 End;
END.