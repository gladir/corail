{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program DF;

Uses DOS;

Var
 I:Char;
 Dsk:Byte;

BEGIN
 If(ParamStr(1)='--help')or(ParamStr(1)='-h')or(ParamStr(1)='/?')Then Begin
  WriteLn('df : Cette commande permet d''afficher l''espace libre sur les systemes de fichiers.');
  WriteLn;
  WriteLn('Syntaxe : df');
 End
  Else
 Begin
  WriteLn('Sys. fich.       Taille Util. Dispo Uti%');
  For I:='A' to 'Z' do Begin
   Dsk:=Ord(I)-Ord('A');
   If DiskSize(Dsk+1)<>-1Then Begin
    Write(I,':',' ':10);
    If DiskSize(Dsk+1)>1073741824Then Write(DiskSize(Dsk+1) shr 30:9,'G')Else
    If DiskSize(Dsk+1)>1048576Then Write(DiskSize(Dsk+1) shr 20:9,'M') Else
    If DiskSize(Dsk+1)>1024Then Write(DiskSize(Dsk+1) shr 10:9,'K')
                Else Write(DiskSize(Dsk+1):10);
    If(DiskSize(Dsk+1)-DiskFree(Dsk+1)>1073741824)Then Write((DiskSize(Dsk+1)-DiskFree(Dsk+1)) shr 30:5,'G') Else
    If(DiskSize(Dsk+1)-DiskFree(Dsk+1)>1048576)Then Write((DiskSize(Dsk+1)-DiskFree(Dsk+1))shr 20:5,'M')
                Else Write((DiskSize(Dsk+1)-DiskFree(Dsk+1)) shr 10:5,'K');
    If DiskFree(Dsk+1)>1073741824Then Write(DiskFree(Dsk+1) shr 30:5,'G')Else
    If DiskFree(Dsk+1)>1048576Then Write(DiskFree(Dsk+1) shr 20:5,'M') Else
    If DiskFree(Dsk+1)>1024Then Write(DiskFree(Dsk+1) shr 10:5,'K')
                Else Write(DiskFree(Dsk+1):10);
    Write(Trunc(((DiskSize(Dsk+1)-DiskFree(Dsk+1))/DiskSize(Dsk+1))*100):5,'%');
    WriteLn;
   End;
  End;
 End;
END.