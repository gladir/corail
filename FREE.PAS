{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program FREE;

Uses DOS;

Var
 ShowDrive:Boolean;
 I,Drive:Integer;
 CurrParam:String;
 Mode:(ShowByte,ShowKibi,ShowKilo,ShowMebi,ShowMega,ShowGibi,ShowGiga);
 R:SearchRec;

Function GetDiskLabel(Dsk:Byte):String;
Var
 Info:SearchRec;
 CurrentDir:String;
Begin
 If Dsk=0Then GetDir(0,CurrentDir)
         Else CurrentDir:=Char(Dsk+64);
 FindFirst(CurrentDir[1]+':\*.*',VolumeID,Info);
 While DosError=0do Begin
  If(Info.Attr = VolumeID)Then Begin
   GetDiskLabel:=Info.Name;
   Exit;
  End;
  FindNext(Info);
 End;
 GetDiskLabel:=''
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('FREE : Cette commande permet de demander les ressources de disponible (style Linux) ou ',
                  'les statistiques d''un unite de disque (style 4DOS)');
  WriteLn;
  WriteLn('Syntaxe : FREE [/?] [-b|-k]');
  WriteLn('          FREE unite:');
  WriteLn;
  WriteLn(' unite:   Affiche les statistiques d''un unite (style 4DOS)');
  WriteLn(' -b       Affiche les statistiques en octets (style Linux)');
  WriteLn(' -k       Affiche les statistiques en kibioctets (style Linux)');
  WriteLn(' --kibi   Affiche les statistiques en kibioctets (style Linux)');
  WriteLn(' --kilo   Affiche les statistiques en kilooctets (style Linux)');
  WriteLn(' -m       Affiche les statistiques en mebioctets (style Linux)');
  WriteLn(' --mebi   Affiche les statistiques en mebioctets (style Linux)');
  WriteLn(' --mega   Affiche les statistiques en megaoctets (style Linux)');
  WriteLn(' -g       Affiche les statistiques en gibioctets (style Linux)');
  WriteLn(' --gibi   Affiche les statistiques en gibioctets (style Linux)');
  WriteLn(' --giga   Affiche les statistiques en gigactets (style Linux)');
 End
  Else
 Begin
  ShowDrive:=False;
  Mode:=ShowKilo;
  For I:=1 to ParamCount do Begin
   CurrParam:=ParamStr(I);
   If(CurrParam='-b')or(ParamStr(I)='--bytes')Then Mode:=ShowByte Else
   If(ParamStr(I)='-k')or(ParamStr(I)='--kibi')Then Mode:=ShowKibi Else
   If ParamStr(I)='--kilo'Then Mode:=ShowKilo Else
   If(ParamStr(I)='-m')or(ParamStr(I)='--mebi')Then Mode:=ShowMebi Else
   If ParamStr(I)='--mega'Then Mode:=ShowMebi Else
   If(ParamStr(I)='-g')or(ParamStr(I)='--gibi')Then Mode:=ShowGibi Else
   If ParamStr(I)='--giga'Then Mode:=ShowGiga Else
   If(Length(CurrParam)=2)and(CurrParam[2]=':')and(CurrParam[1]in['a'..'z','A'..'Z'])Then Begin
    Drive:=Ord(CurrParam[1])-Ord('A');
    WriteLn;
    WriteLn(' Volume dans l''unite ',CurrParam[1],' est ',GetDiskLabel(Drive+1));
    WriteLn(DiskSize(Drive+1):20,' octets d''espace disque total');
    WriteLn(DiskSize(Drive+1)-DiskFree(Drive+1):20,' octets d''espace utilise');
    WriteLn(DiskFree(Drive+1):20,' octets d''espace libre');
    ShowDrive:=True;
   End
    Else
   Begin
    WriteLn('Paramätre ',ParamStr(I),' non reconnu');
    Halt;
   End;
  End;
  If Not(ShowDrive)Then Begin
   WriteLn(' ':20,'Total','  ','Utiliser','  ','Libre','  ',
          'Partager','  ','Tampon/Cache','  ','Disponible');
   FindFirst('C:\pagefile.sys',AnyFile,R);
   If(DOSError=0)Then Begin
    Write('Swap Windows:  ');
    Case(Mode)of
     ShowGibi:Write(R.Size shr 30:10);
     ShowGiga:Write(R.Size div 1000000000:10);
     ShowMebi:Write(R.Size shr 20:10);
     ShowMega:Write(R.Size div 1000000:10);
     ShowKibi:Write(R.Size shr 10:10);
     ShowKilo:Write(R.Size div 1000:10);
     Else Write(R.Size:10);
    End;
    Write('?':10,'?':7,'?':10,'?':14,'?':12);
   End;
  End;
 End;
END.