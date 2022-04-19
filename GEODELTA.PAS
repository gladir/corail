{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program GeoDelta;

Type
 CityGeoRecord=Record
  City:String[20];
  Latitude,LatiDeg:Byte;
  LatiDirection:Char;
  Longitude,LongDeg:Byte;
  LongDirection:Char;
 End;

Var
 Q1Latitude,Q1LatiDeg:Real;Q1LatiDirection:Char;
 Q1Longitude,Q1LongDeg:Real;Q1LongDirection:Char;
 Q2Latitude,Q2LatiDeg:Real;Q2LatiDirection:Char;
 Q2Longitude,Q2LongDeg:Real;Q2LongDirection:Char;
 Err:Word;
 CurrParam:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function Sqrt(X:Real):Real;
Var
 A,B,M,XN:Real;
Begin
 If X=0.0Then Begin
  Sqrt:=0.0;
 End
  Else
 Begin
  M:=1.0;
  XN:=X;
  While XN>=2.0 do Begin
   XN:=0.25*XN;
   M:=2.0*M;
  End;
  While XN<0.5 do Begin
   XN:=4.0*XN;
   M:=0.5*M;
  End;
  A:=XN;
  B:=1.0-XN;
  Repeat
   A:=A*(1.0+0.5*B);
   B:=0.25*(3.0+B)*B*B;
  Until B<1.0E-15;
  Sqrt:=A*M;
 End;
End;

Function Arctan(X:Real):Real;
Var
 A,B:Real;
 N:Integer;
Begin
 A := 1.0 / Sqrt(1.0 + (X * X));
 B := 1.0;
 For N:=1 to 11 do Begin
  A := (A + B) / 2.0;
  B := Sqrt(A * B);
 End;
 Arctan:=X/(Sqrt(1.0+(X*X))*A);
End;

Function Cos(X:Real):Real;
Var
 R,S:Real;
 I:Byte;
Begin
 R:=X*X;
 S:=42.0;
 For I:=10 downto 1 do S:=4.0*I-2.0+(-R)/S;
 S:=S*S;
 Cos:=(S-R)/(S+R);
End;

Function Sin(X:Real):Real;
Var
 R,S:Real;
 I:Byte;
Begin
 R:=X*X;
 S:=42.0;
 For I:=10 downto 1 do S:=4.0*I-2.0+(-R)/S;
 Sin:=2.0*X*S/(R+S*S);
End;

Function ArcCos(a:Real):Real;Begin
 If Abs(a)=1.0Then ArcCos:=(1-a)*PI/2.0
              Else ArcCos:=Arctan(-a/Sqrt(1-a*a))+2*Arctan(1);
End;

Function CoordToDeltaKm(
 Q1Latitude,Q1LatiDeg:Real;Q1LatiDirection:Char;
 Q1Longitude,Q1LongDeg:Real;Q1LongDirection:Char;
 Q2Latitude,Q2LatiDeg:Real;Q2LatiDirection:Char;
 Q2Longitude,Q2LongDeg:Real;Q2LongDirection:Char
):Real;
Var
 a1,b1,a2,b2,RawDelta:Real;
Begin
 a1:=(Q1Latitude+(Q1LatiDeg/60))*PI/180;
 If Q1LatiDirection='N'Then a1:=-a1;
 b1:=(Q1Longitude+(Q1LongDeg/60))*PI/180;
 If Q1LongDirection='O'Then b1:=-b1;
 a2:=(Q2Latitude+(Q2LatiDeg/60))*PI/180;
 If Q2LatiDirection='N'Then a2:=-a2;
 b2:=(Q2Longitude+(Q2LongDeg/60))*PI/180;
 If Q2LongDirection='O'Then b2:=-b2;
 RawDelta:=ArcCos(Cos(a1)*Cos(b1)*Cos(a2)*Cos(b2) + Cos(a1)*Sin(b1)*Cos(a2)*Sin(b2) + Sin(a1)*Sin(a2));
 CoordToDeltaKm:=RawDelta*6378.0;
End;

Function CoordToDeltaStatuteMiles(
 Q1Latitude,Q1LatiDeg:Real;Q1LatiDirection:Char;
 Q1Longitude,Q1LongDeg:Real;Q1LongDirection:Char;
 Q2Latitude,Q2LatiDeg:Real;Q2LatiDirection:Char;
 Q2Longitude,Q2LongDeg:Real;Q2LongDirection:Char
):Real;
Var
 a1,b1,a2,b2,RawDelta:Real;
Begin
 a1:=(Q1Latitude+(Q1LatiDeg/60))*PI/180;
 If Q1LatiDirection='N'Then a1:=-a1;
 b1:=(Q1Longitude+(Q1LongDeg/60))*PI/180;
 If Q1LongDirection='O'Then b1:=-b1;
 a2:=(Q2Latitude+(Q2LatiDeg/60))*PI/180;
 If Q2LatiDirection='N'Then a2:=-a2;
 b2:=(Q2Longitude+(Q2LongDeg/60))*PI/180;
 If Q2LongDirection='O'Then b2:=-b2;
 RawDelta:=ArcCos(Cos(a1)*Cos(b1)*Cos(a2)*Cos(b2) + Cos(a1)*Sin(b1)*Cos(a2)*Sin(b2) + Sin(a1)*Sin(a2));
 CoordToDeltaStatuteMiles:=RawDelta*3963.1;
End;

Function CoordToDeltaNauticalMiles(
 Q1Latitude,Q1LatiDeg:Real;Q1LatiDirection:Char;
 Q1Longitude,Q1LongDeg:Real;Q1LongDirection:Char;
 Q2Latitude,Q2LatiDeg:Real;Q2LatiDirection:Char;
 Q2Longitude,Q2LongDeg:Real;Q2LongDirection:Char
):Real;
Var
 a1,b1,a2,b2,RawDelta:Real;
Begin
 a1:=(Q1Latitude+(Q1LatiDeg/60))*PI/180;
 If Q1LatiDirection='N'Then a1:=-a1;
 b1:=(Q1Longitude+(Q1LongDeg/60))*PI/180;
 If Q1LongDirection='O'Then b1:=-b1;
 a2:=(Q2Latitude+(Q2LatiDeg/60))*PI/180;
 If Q2LatiDirection='N'Then a2:=-a2;
 b2:=(Q2Longitude+(Q2LongDeg/60))*PI/180;
 If Q2LongDirection='O'Then b2:=-b2;
 RawDelta:=ArcCos(Cos(a1)*Cos(b1)*Cos(a2)*Cos(b2) + Cos(a1)*Sin(b1)*Cos(a2)*Sin(b2) + Sin(a1)*Sin(a2));
 CoordToDeltaNauticalMiles:=RawDelta * 3443.9;
End;

Function FindCity(S:String;Pos:Byte):Boolean;
Const
 City:Array[1..73] of CityGeoRecord=(
  (City:'Alger';          Latitude:36; LatiDeg: 45; LatiDirection: 'N'; Longitude: 3;  LongDeg:   2; LongDirection: 'E'),
  (City:'Alma';           Latitude:48; LatiDeg: 35; LatiDirection: 'N'; Longitude: 71; LongDeg:  40; LongDirection: 'O'),
  (City:'Arvida';         Latitude:48; LatiDeg: 26; LatiDirection: 'N'; Longitude: 71; LongDeg:  11; LongDirection: 'O'),
  (City:'Bagdad';         Latitude:33; LatiDeg: 20; LatiDirection: 'N'; Longitude: 44; LongDeg:  26; LongDirection: 'E'),
  (City:'Bagotville';     Latitude:48; LatiDeg: 19; LatiDirection: 'N'; Longitude: 70; LongDeg:  59; LongDirection: 'O'),
  (City:'Barcelone';      Latitude:41; LatiDeg: 22; LatiDirection: 'N'; Longitude:  2; LongDeg:  10; LongDirection: 'E'),
  (City:'Beijing';        Latitude:39; LatiDeg: 54; LatiDirection: 'N'; Longitude: 116;LongDeg:  24; LongDirection: 'E'),
  (City:'Berlin';         Latitude:52; LatiDeg: 31; LatiDirection: 'N'; Longitude: 13; LongDeg:  24; LongDirection: 'E'),
  (City:'Boston';         Latitude:42; LatiDeg: 21; LatiDirection: 'N'; Longitude: 71; LongDeg:   3; LongDirection: 'O'),
  (City:'Brampton';       Latitude:43; LatiDeg: 41; LatiDirection: 'N'; Longitude: 79; LongDeg:  46; LongDirection: 'O'),
  (City:'Brossard';       Latitude:45; LatiDeg: 28; LatiDirection: 'N'; Longitude: 73; LongDeg:  27; LongDirection: 'O'),
  (City:'Calgary';        Latitude:51; LatiDeg:  2; LatiDirection: 'N'; Longitude: 114;LongDeg:   3; LongDirection: 'O'),
  (City:'Chicago';        Latitude:41; LatiDeg: 52; LatiDirection: 'N'; Longitude: 87; LongDeg:  34; LongDirection: 'O'),
  (City:'Chicoutimi';     Latitude:48; LatiDeg: 28; LatiDirection: 'N'; Longitude: 71; LongDeg:   5; LongDirection: 'O'),
  (City:'Chomedey';       Latitude:45; LatiDeg: 32; LatiDirection: 'N'; Longitude: 73; LongDeg:  45; LongDirection: 'O'),
  (City:'Dallas';         Latitude:32; LatiDeg: 46; LatiDirection: 'N'; Longitude: 96; LongDeg:  48; LongDirection: 'O'),
  (City:'Delhi';          Latitude:28; LatiDeg: 38; LatiDirection: 'N'; Longitude: 77; LongDeg:  13; LongDirection: 'E'),
  (City:'Edmonton';       Latitude:53; LatiDeg: 32; LatiDirection: 'N'; Longitude: 113;LongDeg:  30; LongDirection: 'O'),
  (City:'Gaspe';          Latitude:48; LatiDeg: 49; LatiDirection: 'N'; Longitude: 64; LongDeg:  29; LongDirection: 'O'),
  (City:'Gatineau';       Latitude:45; LatiDeg: 29; LatiDirection: 'N'; Longitude: 75; LongDeg:  39; LongDirection: 'O'),
  (City:'Geneve';         Latitude:46; LatiDeg: 12; LatiDirection: 'N'; Longitude: 6;  LongDeg:   9; LongDirection: 'E'),
  (City:'Grand-mere';     Latitude:46; LatiDeg: 36; LatiDirection: 'N'; Longitude: 72; LongDeg:  40; LongDirection: 'O'),
  (City:'Guelph';         Latitude:43; LatiDeg: 33; LatiDirection: 'N'; Longitude: 80; LongDeg:  15; LongDirection: 'O'),
  (City:'Halifax';        Latitude:44; LatiDeg: 38; LatiDirection: 'N'; Longitude: 63; LongDeg:  34; LongDirection: 'O'),
  (City:'Hamilton';       Latitude:43; LatiDeg: 15; LatiDirection: 'N'; Longitude: 79; LongDeg:  52; LongDirection: 'O'),
  (City:'Houston';        Latitude:29; LatiDeg: 45; LatiDirection: 'N'; Longitude: 95; LongDeg:  22; LongDirection: 'O'),
  (City:'Jakarta';        Latitude: 6; LatiDeg: 12; LatiDirection: 'S'; Longitude:106; LongDeg:  50; LongDirection: 'E'),
  (City:'Jonquiere';      Latitude:48; LatiDeg: 27; LatiDirection: 'N'; Longitude: 71; LongDeg:  14; LongDirection: 'O'),
  (City:'Laval';          Latitude:45; LatiDeg: 35; LatiDirection: 'N'; Longitude: 73; LongDeg:  45; LongDirection: 'O'),
  (City:'Levis';          Latitude:46; LatiDeg: 48; LatiDirection: 'N'; Longitude: 71; LongDeg:  11; LongDirection: 'O'),
  (City:'London';         Latitude:42; LatiDeg: 59; LatiDirection: 'N'; Longitude: 81; LongDeg:  14; LongDirection: 'O'),
  (City:'Londres';        Latitude:51; LatiDeg: 30; LatiDirection: 'N'; Longitude:  0; LongDeg:   7; LongDirection: 'O'),
  (City:'Longueuil';      Latitude:45; LatiDeg: 32; LatiDirection: 'N'; Longitude: 73; LongDeg:  31; LongDirection: 'O'),
  (City:'Madrid';         Latitude:40; LatiDeg: 26; LatiDirection: 'N'; Longitude: 3;  LongDeg:  41; LongDirection: 'O'),
  (City:'Manille';        Latitude:14; LatiDeg: 35; LatiDirection: 'N'; Longitude: 120;LongDeg:  58; LongDirection: 'E'),
  (City:'Markham';        Latitude:43; LatiDeg: 53; LatiDirection: 'N'; Longitude: 79; LongDeg:  15; LongDirection: 'O'),
  (City:'Marseille';      Latitude:43; LatiDeg: 17; LatiDirection: 'N'; Longitude: 5;  LongDeg:  22; LongDirection: 'E'),
  (City:'Mexico';         Latitude:23; LatiDeg: 38; LatiDirection: 'N'; Longitude: 102;LongDeg:  33; LongDirection: 'O'),
  (City:'Miami';          Latitude:25; LatiDeg: 47; LatiDirection: 'N'; Longitude: 80; LongDeg:  13; LongDirection: 'O'),
  (City:'Milan';          Latitude:45; LatiDeg: 27; LatiDirection: 'N'; Longitude:  9; LongDeg:  11; LongDirection: 'E'),
  (City:'Mirabel';        Latitude:45; LatiDeg: 39; LatiDirection: 'N'; Longitude: 74; LongDeg:   5; LongDirection: 'O'),
  (City:'Mississauga';    Latitude:43; LatiDeg: 36; LatiDirection: 'N'; Longitude: 79; LongDeg:  39; LongDirection: 'O'),
  (City:'Mumbai';         Latitude:19; LatiDeg:  4; LatiDirection: 'N'; Longitude: 72; LongDeg:  52; LongDirection: 'E'),
  (City:'Moncton';        Latitude:46; LatiDeg:  5; LatiDirection: 'N'; Longitude: 64; LongDeg:  46; LongDirection: 'O'),
  (City:'Montreal';       Latitude:45; LatiDeg: 31; LatiDirection: 'N'; Longitude: 73; LongDeg:  34; LongDirection: 'O'),
  (City:'Moscou';         Latitude:55; LatiDeg: 45; LatiDirection: 'N'; Longitude: 37; LongDeg:  37; LongDirection: 'E'),
  (City:'Munich';         Latitude:48; LatiDeg:  9; LatiDirection: 'N'; Longitude: 11; LongDeg:  34; LongDirection: 'E'),
  (City:'Oakville';       Latitude:43; LatiDeg: 28; LatiDirection: 'N'; Longitude: 79; LongDeg:  41; LongDirection: 'O'),
  (City:'Ottawa';         Latitude:45; LatiDeg: 25; LatiDirection: 'N'; Longitude: 75; LongDeg:  41; LongDirection: 'O'),
  (City:'Paris';          Latitude:48; LatiDeg: 50; LatiDirection: 'N'; Longitude: 2;  LongDeg:  20; LongDirection: 'E'),
  (City:'Pekin';          Latitude:39; LatiDeg: 54; LatiDirection: 'N'; Longitude: 116;LongDeg:  23; LongDirection: 'E'),
  (City:'Quebec';         Latitude:46; LatiDeg: 48; LatiDirection: 'N'; Longitude: 71; LongDeg:  13; LongDirection: 'O'),
  (City:'Rome';           Latitude:41; LatiDeg: 53; LatiDirection: 'N'; Longitude: 12; LongDeg:  29; LongDirection: 'E'),
  (City:'Saguenay';       Latitude:48; LatiDeg: 25; LatiDirection: 'N'; Longitude: 71; LongDeg:   4; LongDirection: 'O'),
  (City:'Sainte-Dorothee';Latitude:45; LatiDeg: 32; LatiDirection: 'N'; Longitude: 73; LongDeg:  49; LongDirection: 'O'),
  (City:'Saint-Jerome';   Latitude:45; LatiDeg: 47; LatiDirection: 'N'; Longitude: 74; LongDeg:  0;  LongDirection: 'O'),
  (City:'Saint-Lin';      Latitude:45; LatiDeg: 44; LatiDirection: 'N'; Longitude: 73; LongDeg:  46; LongDirection: 'O'),
  (City:'Seoul';          Latitude:37; LatiDeg: 33; LatiDirection: 'N'; Longitude: 126;LongDeg:  58; LongDirection: 'E'),
  (City:'Shanghai';       Latitude:31; LatiDeg: 14; LatiDirection: 'N'; Longitude: 121;LongDeg:  29; LongDirection: 'E'),
  (City:'Sherbrooke';     Latitude:45; LatiDeg: 24; LatiDirection: 'N'; Longitude: 71; LongDeg:  54; LongDirection: 'O'),
  (City:'Sept-Iles';      Latitude:50; LatiDeg: 13; LatiDirection: 'N'; Longitude: 66; LongDeg:  23; LongDirection: 'O'),
  (City:'St-Lin';         Latitude:45; LatiDeg: 44; LatiDirection: 'N'; Longitude: 73; LongDeg:  46; LongDirection: 'O'),
  (City:'Ste-Dorothee';   Latitude:45; LatiDeg: 32; LatiDirection: 'N'; Longitude: 73; LongDeg:  49; LongDirection: 'O'),
  (City:'Surrey';         Latitude:49; LatiDeg: 11; LatiDirection: 'N'; Longitude: 122;LongDeg:  51; LongDirection: 'O'),
  (City:'Sydney';         Latitude:33; LatiDeg: 51; LatiDirection: 'S'; Longitude: 151;LongDeg:  11; LongDirection: 'E'),
  (City:'Tadoussac';      Latitude:48; LatiDeg:  9; LatiDirection: 'N'; Longitude: 69; LongDeg:  43; LongDirection: 'O'),
  (City:'Teheran';        Latitude:35; LatiDeg: 41; LatiDirection: 'N'; Longitude: 51; LongDeg:  25; LongDirection: 'E'),
  (City:'Terrebonne';     Latitude:45; LatiDeg: 42; LatiDirection: 'N'; Longitude: 73; LongDeg:  38; LongDirection: 'O'),
  (City:'Tokyo';          Latitude:35; LatiDeg: 41; LatiDirection: 'N'; Longitude: 139;LongDeg:  41; LongDirection: 'E'),
  (City:'Toronto';        Latitude:43; LatiDeg: 40; LatiDirection: 'N'; Longitude: 79; LongDeg:  23; LongDirection: 'O'),
  (City:'Vancouver';      Latitude:49; LatiDeg: 15; LatiDirection: 'N'; Longitude: 123;LongDeg:   6; LongDirection: 'O'),
  (City:'Washington';     Latitude:38; LatiDeg: 53; LatiDirection: 'N'; Longitude: 77; LongDeg:   2; LongDirection: 'O'),
  (City:'Winnipeg';       Latitude:49; LatiDeg: 53; LatiDirection: 'N'; Longitude: 97; LongDeg:   9; LongDirection: 'O')
 );
Var
 I:Integer;
Begin
 FindCity:=False;
 For I:=Low(City)to High(City)do Begin
  If StrToUpper(City[I].City)=StrToUpper(S) Then Begin
   If Pos = 1 Then Begin
    Q1Latitude:=City[I].Latitude;
    Q1LatiDeg:=City[I].LatiDeg;
    Q1LatiDirection:=City[I].LatiDirection;
    Q1Longitude:=City[I].Longitude;
    Q1LongDeg:=City[I].LongDeg;
    Q1LongDirection:=City[I].LongDirection;
   End
    Else
   Begin
    Q2Latitude:=City[I].Latitude;
    Q2LatiDeg:=City[I].LatiDeg;
    Q2LatiDirection:=City[I].LatiDirection;
    Q2Longitude:=City[I].Longitude;
    Q2LongDeg:=City[I].LongDeg;
    Q2LongDirection:=City[I].LongDirection;
   End;
   FindCity:=True;
   Exit;
  End;
 End;
End;


BEGIN
 If ParamStr(1)='/?'Then Begin
  WriteLn('GeoDelta - Cette commande permet de calculer la distance entre deux villes');
  WriteLn;
  WriteLn('Syntaxe : GEODELTA ville1 ville2');
  WriteLn('          GEODELTA ville1 lat2 latdeg2 latdir2 long2 longdeg2 longdir2');
  WriteLn('          GEODELTA lat1 latdeg1 latdir1 long1 longdeg1 longdir1 ville2');
  WriteLn('          GEODELTA lat1 latdeg1 latdir1 long1 longdeg1 longdir1 lat2 latdeg2 latdir2 long2 longdeg2 longdir2');
  WriteLn;
  WriteLn('Exemple:  GEODELTA 45 31 N 73 34 O 48 50 N 2 20 E');
  WriteLn('          GEODELTA montreal paris');
 End
  Else
 Begin
   If FindCity(ParamStr(1),1)Then Begin
    If Not FindCity(ParamStr(2),2)Then Begin
     Val(ParamStr(2),Q2Latitude,Err);
    If Err>0Then WriteLn('ATTENTION ! Erreur de valeur');
     Val(ParamStr(3),Q2LatiDeg,Err);
     CurrParam:=ParamStr(4);
     Q2LatiDirection := CurrParam[1];
     Val(ParamStr(5),Q2Longitude,Err);
     Val(ParamStr(6),Q2LongDeg,Err);
     CurrParam:=ParamStr(7);
     Q2LongDirection := CurrParam[1];
    End;
   End
    Else
   Begin
    Val(ParamStr(1),Q1Latitude,Err);
    If Err>0Then WriteLn('ATTENTION ! Erreur de valeur');
    Val(ParamStr(2),Q1LatiDeg,Err);
    CurrParam:=ParamStr(3);
    Q1LatiDirection := CurrParam[1];
    Val(ParamStr(4),Q1Longitude,Err);
    Val(ParamStr(5),Q1LongDeg,Err);
    CurrParam:=ParamStr(6);
    Q1LongDirection := CurrParam[1];
    If Not FindCity(ParamStr(7),2)Then Begin
     Val(ParamStr(7),Q2Latitude,Err);
    If Err>0Then WriteLn('ATTENTION ! Erreur de valeur');
     Val(ParamStr(8),Q2LatiDeg,Err);
     CurrParam:=ParamStr(9);
     Q2LatiDirection := CurrParam[1];
     Val(ParamStr(10),Q2Longitude,Err);
     Val(ParamStr(11),Q2LongDeg,Err);
     CurrParam:=ParamStr(12);
     Q2LongDirection := CurrParam[1];
    End;
   End;

   WriteLn('Distance en Km : ',
    CoordToDeltaKm(Q1Latitude,Q1LatiDeg,Q1LatiDirection,
                   Q1Longitude,Q1LongDeg,Q1LongDirection,
                   Q2Latitude,Q2LatiDeg,Q2LatiDirection,
                   Q2Longitude,Q2LongDeg,Q2LongDirection):4:8);
 End;
END.
