{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program INFO;

Uses DOS;

Var
 I:Char;
 Dsk:Byte;
 FirstParam:String;

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
 FirstParam:=ParamStr(1);
 If FirstParam='/?'Then Begin
  WriteLn('INFO   Cette commande permet de demander des informations sur ',
                  'l''etat du systeme d''exploitation.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('INFO [/?]');
  WriteLn;
  WriteLn('       /?  Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 Begin
  WriteLn;
  WriteLn('Unite    Taille   Utilise     Libre Plein  Erreurs Etat             Nom');
  For I:='A' to 'Z' do Begin
   Dsk:=Ord(I)-Ord('A');
   If DiskSize(Dsk+1)<>-1Then Begin
    Case I of
     'A':Write('DF0:');
     'B':Write('DF1:');
     Else Begin
      Write('DH',Dsk-2,':');
      If Dsk<12Then Write(' ');
     End;
    End;
    If DiskSize(Dsk+1)>1073741824Then Write(DiskSize(Dsk+1) shr 30:9,'G')Else
    If DiskSize(Dsk+1)>1048576Then Write(DiskSize(Dsk+1) shr 20:9,'M') Else
    If DiskSize(Dsk+1)>1024Then Write(DiskSize(Dsk+1) shr 10:9,'K')
                Else Write(DiskSize(Dsk+1):10);
    If(DiskSize(Dsk+1)-DiskFree(Dsk+1)>1073741824)Then Write((DiskSize(Dsk+1)-DiskFree(Dsk+1)) shr 30:10) Else
    If(DiskSize(Dsk+1)-DiskFree(Dsk+1)>1048576)Then Write((DiskSize(Dsk+1)-DiskFree(Dsk+1))shr 20:10)
                Else Write((DiskSize(Dsk+1)-DiskFree(Dsk+1)) shr 10:10);
    If DiskFree(Dsk+1)>1073741824Then Write(DiskFree(Dsk+1) shr 30:10)Else
    If DiskFree(Dsk+1)>1048576Then Write(DiskFree(Dsk+1) shr 20:10) Else
    If DiskFree(Dsk+1)>1024Then Write(DiskFree(Dsk+1) shr 10:10)
                Else Write(DiskFree(Dsk+1):10);
    Write(Trunc(((DiskSize(Dsk+1)-DiskFree(Dsk+1))/DiskSize(Dsk+1))*100):6,'%');
    Write('  ',0,' ':6);
    Write('Lecture/Ecriture ');
    Write(GetDiskLabel(Dsk+1));
    WriteLn;
   End;
  End;
 End;
END.