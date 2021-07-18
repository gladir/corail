{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program STAT;

Uses DOS;

Var
 I:Integer;
 Info:SearchRec;
 T:DateTime;

Function PadRight(Value:LongInt;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:=S+' ';
 PadRight:=S;
End;

Function PadZeroLeft(Value:LongInt;Space:Byte):String;
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
  WriteLn('STAT : Cette commande permet d''afficher des informations sur des fichiers.');
  WriteLn;
  WriteLn('Syntaxe : STAT fichiers');
 End
  Else
 If ParamCount>0Then Begin
  For I:=1 to ParamCount do Begin
  FindFirst(ParamStr(I),AnyFile,Info);
   While DosError=0 do Begin
    If Not((Info.Name='.')or(Info.Name='..'))Then Begin
     WriteLn('Fichier:  ','''',Info.Name,'''');
     WriteLn('Taille:   ',PadRight(Info.Size,10),'Blocs:  ',(Info.Size shr 9)+Byte((Info.Size and$1FF)>0):10,' ');
     UnpackTime(Info.Time,T);
     Write('Acces:    (');
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
     WriteLn(')');
     WriteLn('Modifier: ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2),' ');
    End;
    FindNext(Info);
   End;
  End;
 End
  Else
 WriteLn('Parametres requis !');
END.