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
 City:Array[1..25] of CityGeoRecord=(
  (City:'Alma';      Latitude:48; LatiDeg: 35; LatiDirection: 'N'; Longitude: 71; LongDeg:  40; LongDirection: 'O'),
  (City:'Berlin';    Latitude:52; LatiDeg: 31; LatiDirection: 'N'; Longitude: 13; LongDeg:  24; LongDirection: 'E'),
  (City:'Calgary';   Latitude:51; LatiDeg: 02; LatiDirection: 'N'; Longitude: 114;LongDeg:  03; LongDirection: 'O'),
  (City:'Dallas';    Latitude:32; LatiDeg: 46; LatiDirection: 'N'; Longitude: 96; LongDeg:  48; LongDirection: 'O'),
  (City:'Edmonton';  Latitude:53; LatiDeg: 32; LatiDirection: 'N'; Longitude: 113;LongDeg:  30; LongDirection: 'O'),
  (City:'Gaspe';     Latitude:48; LatiDeg: 49; LatiDirection: 'N'; Longitude: 64; LongDeg:  29; LongDirection: 'O'),
  (City:'Geneve';    Latitude:46; LatiDeg: 12; LatiDirection: 'N'; Longitude: 6;  LongDeg:   9; LongDirection: 'E'),
  (City:'Halifax';   Latitude:44; LatiDeg: 38; LatiDirection: 'N'; Longitude: 63; LongDeg:  34; LongDirection: 'O'),
  (City:'Houston';   Latitude:29; LatiDeg: 45; LatiDirection: 'N'; Longitude: 95; LongDeg:  22; LongDirection: 'O'),
  (City:'Laval';     Latitude:45; LatiDeg: 35; LatiDirection: 'N'; Longitude: 73; LongDeg:  45; LongDirection: 'O'),
  (City:'Longueuil'; Latitude:45; LatiDeg: 32; LatiDirection: 'N'; Longitude: 73; LongDeg:  31; LongDirection: 'O'),
  (City:'Marseille'; Latitude:43; LatiDeg: 17; LatiDirection: 'N'; Longitude: 5;  LongDeg:  22; LongDirection: 'E'),
  (City:'Miami';     Latitude:25; LatiDeg: 47; LatiDirection: 'N'; Longitude: 80; LongDeg:  13; LongDirection: 'O'),
  (City:'Montreal';  Latitude:45; LatiDeg: 31; LatiDirection: 'N'; Longitude: 73; LongDeg:  34; LongDirection: 'O'),
  (City:'Munich';    Latitude:48; LatiDeg:  9; LatiDirection: 'N'; Longitude: 11; LongDeg:  34; LongDirection: 'E'),
  (City:'Ottawa';    Latitude:45; LatiDeg: 25; LatiDirection: 'N'; Longitude: 75; LongDeg:  41; LongDirection: 'O'),
  (City:'Paris';     Latitude:48; LatiDeg: 50; LatiDirection: 'N'; Longitude: 2;  LongDeg:  20; LongDirection: 'E'),
  (City:'Pekin';     Latitude:39; LatiDeg: 54; LatiDirection: 'N'; Longitude: 116;LongDeg:  23; LongDirection: 'E'),
  (City:'Quebec';    Latitude:46; LatiDeg: 48; LatiDirection: 'N'; Longitude: 71; LongDeg:  13; LongDirection: 'O'),
  (City:'Rome';      Latitude:41; LatiDeg: 53; LatiDirection: 'N'; Longitude: 12; LongDeg:  29; LongDirection: 'E'),
  (City:'Sherbrooke';Latitude:45; LatiDeg: 24; LatiDirection: 'N'; Longitude: 71; LongDeg:  54; LongDirection: 'O'),
  (City:'Sept-Iles'; Latitude:50; LatiDeg: 13; LatiDirection: 'N'; Longitude: 66; LongDeg:  23; LongDirection: 'O'),
  (City:'Sydney';    Latitude:33; LatiDeg: 51; LatiDirection: 'S'; Longitude: 151;LongDeg:  11; LongDirection: 'E'),
  (City:'Toronto';   Latitude:43; LatiDeg: 40; LatiDirection: 'N'; Longitude: 79; LongDeg:  23; LongDirection: 'O'),
  (City:'Vancouver'; Latitude:49; LatiDeg: 15; LatiDirection: 'N'; Longitude: 123;LongDeg:  06; LongDirection: 'O')
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
     Val(ParamStr(3),Q2LatiDeg,Err);
     Q2LatiDirection := ParamStr(4)[1];
     Val(ParamStr(5),Q2Longitude,Err);
     Val(ParamStr(6),Q2LongDeg,Err);
     Q2LongDirection := ParamStr(7)[1];
    End;
   End
    Else
   Begin
    Val(ParamStr(1),Q1Latitude,Err);
    Val(ParamStr(2),Q1LatiDeg,Err);
    Q1LatiDirection := ParamStr(3)[1];
    Val(ParamStr(4),Q1Longitude,Err);
    Val(ParamStr(5),Q1LongDeg,Err);
    Q1LongDirection := ParamStr(6)[1];
    If Not FindCity(ParamStr(7),2)Then Begin
     Val(ParamStr(7),Q2Latitude,Err);
     Val(ParamStr(8),Q2LatiDeg,Err);
     Q2LatiDirection := ParamStr(9)[1];
     Val(ParamStr(10),Q2Longitude,Err);
     Val(ParamStr(11),Q2LongDeg,Err);
     Q2LongDirection := ParamStr(12)[1];
    End;
   End;

   WriteLn('Distance en Km : ',
    CoordToDeltaKm(Q1Latitude,Q1LatiDeg,Q1LatiDirection,
                   Q1Longitude,Q1LongDeg,Q1LongDirection,
                   Q2Latitude,Q2LatiDeg,Q2LatiDirection,
                   Q2Longitude,Q2LongDeg,Q2LongDirection):4:8);
 End;
END.