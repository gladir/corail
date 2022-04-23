{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program FS;

Uses Crt,DOS;

Var
 P:Byte;
 Info:SearchRec;
 Option:Set of (Pause,Subdirectory,Lower,Brief,Description);
 Column:Set Of (Double,Width);
 TotalNumFiles,TotalSize:LongInt;
 CurrParam,ShowDir,CurrLabel:String;
 CurrDrive:Char;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

Function Path2Drive(Path:String):Char;Begin
 Path:=FExpand(Path);
 Path2Drive:=Path[1];
End;

Function Path2Dir(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 If(Length(D)>3)and(D[Length(D)]='\')Then D:=Copy(D,1,Length(D)-1);
 Path2Dir:=D;
End;

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
 Option:=[];
 Column:=[];
 P:=0;
 ShowDir:='*.*';
 Repeat
  Inc(P);
  CurrParam:=ParamStr(P);
 If Length(CurrParam)=0Then Break;
  If CurrParam='/?'Then Begin
   WriteLn('FS   Cette commande permet d''afficher la taille d''un ou plusieurs fichiers.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('FS [/?] [/P] [chemin]');
   WriteLn;
   WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLN(' /P   Ce parametre affiche une pause apres l''affichage d''une page pleine');
   Exit;
  End
   Else
  If CurrParam='/2'Then Include(Column,Double) Else
  If(CurrParam='/P')or(CurrParam='/p')Then Include(Option,Pause)
                   Else ShowDir:=CurrParam;
  If P>99Then Break;
 Until CurrParam='';
 ShowDir:=FExpand(ShowDir);
 CurrDrive:=Path2Drive(ShowDir);
 CurrLabel:=GetDiskLabel(Byte(CurrDrive)-64);
 P:=0;
 FindFirst(ShowDir,AnyFile,Info);
 TotalNumFiles:=0;
 TotalSize:=0;
 Inc(P,2);
 WriteLn(Path2Dir(ShowDir));
 WriteLn;
 While DOSError=0 do Begin
  If Not((Info.Name='..')or(Info.Name='.'))Then Begin
   Write(' ':4,PadRight(Info.Name,13));
   If Info.Attr and Directory=Directory Then Begin
    Write(PadRight('<DIR>',15));
   End
    Else
   Write(Info.Size:15,' octets');
   WriteLn;
   If(Pause)in(Option)Then Begin
    Inc(P);
    If P=Hi(WindMax)Then Begin
     Write('Presse une touche pour continuer...');
     If ReadKey=#27Then Exit;
     WriteLn;
     P:=0;
    End;
   End;
   Inc(TotalNumFiles);
   Inc(TotalSize,Info.Size);
  End;
  FindNext(Info);
 End;
 WriteLn;
 WriteLn(' ':4,TotalSize,' total d''octet(s) pour ',TotalNumFiles,' fichiers');
 WriteLn(' ':4,'Les ',TotalSize,' octet(s) utilise ',
         (TotalSize*100 div DiskSize(Byte(CurrDrive)-64)),'% de l''espace');
 WriteLn;
 WriteLn(' Utilisation du disque');
 WriteLn(DiskSize(Byte(CurrDrive)-64):10,' octet(s) disponible sur ',CurrDrive,':');
 WriteLn(DiskFree(Byte(CurrDrive)-64):10,' octet(s) inutilise sur ',CurrDrive,':, ',
         (DiskFree(Byte(CurrDrive)-64)*100 div DiskSize(Byte(CurrDrive)-64)),'% est non-utilise');
END.