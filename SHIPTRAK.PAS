{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal)
}

Program SHIPTRAK;

Uses DOS;

Var Model     : Byte Absolute $FFFF : $0E;
    SousModel : Byte Absolute $FFFF : $0F;
    Registre  : Registers;

Function ErreurMessage(Numero:Byte) : String;
Var Chaine : String;
    Temp   : String;
Begin
 Case Numero of
  $00 : Chaine := 'Il n''y a pas d''erreur';
  $01 : Chaine := 'Commande invalide';
  $02 : Chaine := 'Marque d''adresse non trouvée';
  $03 : Chaine := 'Disque protégé';
  $04 : Chaine := 'Secteur non trouv‚';
  $05 : Chaine := 'chec de la réinitialisation';
  $06 : Chaine := 'Disquette absente';
  $07 : Chaine := 'Mauvaise table de paramètres';
  $08 : Chaine := 'D‚passement du DMA';
  $09 : Chaine := 'D‚passement d''une frontière de frontière de 64Ko DMA';
  $0A : Chaine := 'Indicateur de secteur défectueux';
  $0B : Chaine := 'Indicateur de piste défecteutueuse';
  $0C : Chaine := 'Type de m‚dium non trouv‚';
  $0D : Chaine := 'Nombre de secteurs invalides';
  $0E : Chaine := 'Marque de contrôle détectée';
  $0F : Chaine := 'Niveau de DMA interdit';
  $10 : Chaine := 'Erreur de CRC ou d''ECC';
  $11 : Chaine := 'Erreur de CRC corrigée';
  $20 : Chaine := 'Erreur de contrôleur';
  $40 : Chaine := 'Erreur lors d''un déplacement';
  $80 : Chaine := 'D‚passement de temps (réponse non disponible)';
  $AA : Chaine := 'Unité non prête';
  $BB : Chaine := 'Erreur indefinie';
  $CC : Chaine := 'Erreur d''écriture';
  $E0 : Chaine := 'Erreur dans le registre d''état';
  $FF : Chaine := 'Echec de l''opération de demande d''état';
   else
  Chaine := 'Inconnue';
 End;
 Str(Numero,Temp);
 If(Numero > 0)Then Chaine := 'Erreur #'+Temp+' : ' + Chaine;
 ErreurMessage := Chaine;
End;

Function ParqueHardDisk(Numero:Byte) : Byte;
Begin
 With Registre do
 Begin
  If((Model=$FA)and(SousModel=$00))or { Si PS/2 modèle 30 }
    ((Model=$FC)and(SousModel=$04))or { Si PS/2 modèle 50 }
    ((Model=$FC)and(SousModel=$05))or { Si PS/2 modèle 60 }
    ((Model=$F8)and(SousModel=$00))or { Si PS/2 modèle 80 }
    ((Model=$F8)and(SousModel=$01))   { Si PS/2 modèle 80 }
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
  WriteLn('SHIPTRAK : Cette commande permet de stationner les têtes d''un disque dur sur ',
	 'les pistes les plus internes en préparation du déplacement de l''unité ',
	 'd''entraînement.');
  WriteLn;
  WriteLn('Syntaxe : SHIPTRAK [/?]');
 End
  Else
 ParqueToutHardDisk
END.