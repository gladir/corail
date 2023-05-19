{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7)
}

Program HDPARK;

Uses DOS;

Var Model     : Byte Absolute $FFFF : $0E;
    SousModel : Byte Absolute $FFFF : $0F;
    Registre  : Registers;
    I,Drive:Integer;
    CurrParam:String;

Function ErreurMessage(Numero:Byte) : String;
Var Chaine : String;
    Temp   : String;
Begin
 Case Numero of
  $00 : Chaine := 'Il n''y a pas d''erreur';
  $01 : Chaine := 'Commande invalide';
  $02 : Chaine := 'Marque d''adresse non trouv√©e';
  $03 : Chaine := 'Disque protÇgÇ';
  $04 : Chaine := 'Secteur non trouvÇ';
  $05 : Chaine := 'êchec de la rÇinitialisation';
  $06 : Chaine := 'Disquette absente';
  $07 : Chaine := 'Mauvaise table de paramätres';
  $08 : Chaine := 'DÇpassement du DMA';
  $09 : Chaine := 'DÇpassement d''une frontiäre de frontiäre de 64Ko DMA';
  $0A : Chaine := 'Indicateur de secteur dÇfectueux';
  $0B : Chaine := 'Indicateur de piste dÇfecteutueuse';
  $0C : Chaine := 'Type de mÇdium non trouvÇ';
  $0D : Chaine := 'Nombre de secteurs invalides';
  $0E : Chaine := 'Marque de contrìle dÇtectÇe';
  $0F : Chaine := 'Niveau de DMA interdit';
  $10 : Chaine := 'Erreur de CRC ou d''ECC';
  $11 : Chaine := 'Erreur de CRC corrigÇe';
  $20 : Chaine := 'Erreur de contrìleur';
  $40 : Chaine := 'Erreur lors d''un dÇplacement';
  $80 : Chaine := 'DÇpassement de temps (rÇponse non disponible)';
  $AA : Chaine := 'UnitÇ non pràte';
  $BB : Chaine := 'Erreur indefinie';
  $CC : Chaine := 'Erreur d''Çcriture';
  $E0 : Chaine := 'Erreur dans le registre d''Çtat';
  $FF : Chaine := 'Echec de l''opÇration de demande d''Çtat';
   else
  Chaine := 'Inconnue';
 End;
 Str(Numero,Temp);
 If(Numero > 0)Then Chaine := 'Erreur #'+Temp+' : ' + Chaine;
 ErreurMessage := Chaine;
End;

Function ParqueHardDisk(Numero:Byte):Byte;Begin
 With Registre do
 Begin
  If((Model=$FA)and(SousModel=$00))or { Si PS/2 mod√®le 30 }
    ((Model=$FC)and(SousModel=$04))or { Si PS/2 mod√®le 50 }
    ((Model=$FC)and(SousModel=$05))or { Si PS/2 mod√®le 60 }
    ((Model=$F8)and(SousModel=$00))or { Si PS/2 mod√®le 80 }
    ((Model=$F8)and(SousModel=$01))   { Si PS/2 mod√®le 80 }
  Then
  Begin
   AH := $19;
   DL := Numero;
   Intr($13,Registre);
   ParqueHardDisk := AH;
  End
   else
  Begin
   AH := $08;
   DL := Numero;
   Intr($13,Registre);
   If(Flags and 1<>0)Then
   Begin
    ParqueHardDisk := AH;
    Exit;
   End;
   AH := $0C;
   Dec(CX);
   DL := Numero;
   Intr($13,Registre);
   If((Flags and 1)<>0)Then ParqueHardDisk := AH;
  End;
 End;
End;

Function ParqueToutHardDisk : Byte;
Var Nombre   : Byte;
    Compteur : Byte;
    Result   : Byte;
Begin
 With Registre do
 Begin
  AH := $08;
  DL := $80;
  Intr($13,Registre);
  If(Flags and 1<>0)Then
  Nombre := AH;
  For Compteur := $80 to Nombre do
  Begin
   Result := ParqueHardDisk(Compteur);
   ParqueToutHardDisk := Result;
   If(Result>0)Then Exit;
  End;
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('HDPARK : Cette commande permet de stationner les tàtes d''un disque dur sur ',
	 'les pistes les plus internes en prÇparation du dÇplacement de l''unitÇ ',
	 'd''entraånement.');
  WriteLn;
  WriteLn('Syntaxe : HDPARK [/?] [unite:]');
  WriteLn;
  WriteLn('Parametres');
  WriteLn;
  WriteLn('  /?      Ce paramätre permet d''afficher l''aide sur cette commande');
  WriteLn('  unite:  Ce paramätre permet d''indiquer l''unite de disque a stationner');
 End
  Else
 If ParamCount>0Then Begin
  For I:=1 to ParamCount do Begin
   CurrParam:=ParamStr(I);
   If CurrParam[2]<>':'Then Begin
    WriteLn('L''unitÇ de disque doit etre suivi par le caractäre ":"');
    Halt;
   End;
   If Not(CurrParam[1]in['C'..'Z','c'..'z'])Then Begin
    WriteLn('L''unitÇ de disque doit etre une lettre entre C et Z');
    Halt;
   End;
   Drive:=Ord(CurrParam[1])-65-2;
   ParqueHardDisk(Drive+$80);
  End;
 End
  Else
 ParqueToutHardDisk
END.
