{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program LS;

Uses DOS;

Var
 Option:Set of (_l,_sector,_time);
 I:Integer;
 Info:SearchRec;
 Path:String;
 T:DateTime;

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('LS : Cette commande permet d''afficher les fichiers d''un repertoire.');
  WriteLn;
  WriteLn('Syntaxe : LS [-l] [-s] [-t] [repertoire]');
 End
  Else
 Begin
  Option:=[];
  Path:='*.*';
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='-l'Then Include(Option,_l) Else
   If ParamStr(I)='-s'Then Include(Option,_sector)Else
   If ParamStr(I)='-t'Then Include(Option,_time)
                      Else Path:=ParamStr(I);
  End;
  FindFirst(Path,AnyFile,Info);
  While DosError=0 do Begin
   If Not((Info.Name='.')or(Info.Name='..'))Then Begin
    If(_l)in(Option)Then Begin { Affiche les attributs? }
     If(Info.Attr and Directory=Directory)Then Write('d')
                                          Else Write('-');
     If(Info.Attr and ReadOnly=ReadOnly)Then Write('r')
                                        Else Write('w');
     If(Info.Attr and SysFile=SysFile)Then Write('s')
                                      Else Write('-');
     If(Info.Attr and Hidden=Hidden)Then Write('h')
                                    Else Write('-');
     If(Info.Attr and Archive=Archive)Then Write('a')
                                      Else Write('-');
     Write(' ');
    End;
    If(_Sector)in(Option)Then Begin
     Write((Info.Size shr 9)+Byte((Info.Size and$1FF)>0):10,' ');
    End;
    If(_Time)in(Option)Then Begin
     UnpackTime(Info.Time,T);
     Write(' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2),' ');
    End;
    Write(Info.Name);
    WriteLn;
   End;
   FindNext(Info);
  End;
 End;
END.