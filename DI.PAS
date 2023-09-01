{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program DI;

{$N+}

Uses Crt,DOS,Strings;

Type
 (***** Structure d'horloge *****)
 TimeType=(AmPm,      { 12 heures avec AM/PM comme aux ?tats-Unis }
	   Military); { 24 heures comme le systSme international ou militaire }

Var
 Descr:SearchRec;
 Path:PathStr;
 Size,Free:Comp;
 Y,Dsk:Byte;

Var
  { Information de pays }
 CountryInfo:Record
  Date:Word;Curr:Array[0..4]of Char;
  ThSep,DeSep,DtSep,TmSep:Array[0..1]of Char;CurrStyle,Digits:Byte;
  Time:TimeType;CaseUp:Pointer;DaSep:Array[0..1]of Char;
  FillCountry:Array[0..31]of Byte;
 End;

Function IsWildCard(Path:String):Boolean;Begin
 IsWildCard:=(Pos('*',Path)>0)or(Pos('?',Path)>0)
End;

Function IsRomanLetter(Chr:Char):Boolean;Begin
 ISRomanLetter:=Chr in ['A'..'Z','a'..'z'];
End;

Function Left(S:String;L:Integer):String;Begin
 Left:=Copy(S,1,L);
End;

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

Function SetFullName(Name:String):String;
Var
 Dir:DirStr;
 N:NameStr;
 Ext:ExtStr;
Begin
 If Name<>'..'Then Begin {Name:=StrUSpc(Path2Name(Name),8)+Path2Ext(Name);}
  FSplit(Name,Dir,N,Ext);
  Name:=PadRight(N,8)+Ext;
 End;
 SetFullName:=PadRight(Name,12);
End;

Function GetCurrentDisk:Char;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 GetCurrentDisk:=CurrentDir[1];
End;

Function GetDsk:Byte;Begin
 GetDsk:=Byte(GetCurrentDisk)-Byte('A');
End;

Function Path2Dsk(Path:String):Byte;Begin
 If(Path='')or Not(IsRomanLetter(Path[1]))Then Path2Dsk:=GetDsk
                                          Else Path2Dsk:=Byte(UpCase(Path[1]))-65;
End;

Function Path2Drv(Path:String):Char;Begin
 Path2Drv:=Char(Path2Dsk(Path)+65)
End;

Function Path2Dir(Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;

 Procedure AddBackSlash;Begin
  If D[Length(D)]<>'\'Then D:=D+'\';
 End;

Begin
 Path2Dir:='';
 If Path=''Then Exit;
 FSplit(Path,D,N,E);
 If E=''Then Begin
  AddBackSlash;
  D:=D+E;
 End;
 If D=''Then Path2Dir:=''
        Else AddBackSlash;
 Path2Dir:=D;
End;

Function DirExist(Dir:String):Boolean;
Var
 Rec:SearchRec;
Begin
 If Length(Dir)=0Then DirExist:=True
  Else
 Begin
  If Dir[Length(Dir)]='\'Then Dir:=Dir+'*.*'Else
  If IsWildCard(Dir)Then Dir:=Path2Dir(Dir)+'*.*';
  FindFirst(Dir,Directory,Rec);
  DirExist:=DosError=0;
 End;
End;

Function _CStrDate(Year,Month,Day,DayOfWeek:Word):String;
Var
 Target:String;
Begin
 Case(CountryInfo.Date)of
  0:Begin
   Target:=PadZeroLeft(Month,2);
   Target:=Target+StrPas(@CountryInfo.DtSep);
   Target:=Target+PadZeroLeft(Day,2);
  End;
  1:Begin
   Target:=PadZeroLeft(Day,2);
   Target:=Target+StrPas(@CountryInfo.DtSep);
   Target:=Target+PadZeroLeft(Month,2);
  End;
  Else Begin
   Target:=PadZeroLeft(Year,4);
   Target:=Target+StrPas(@CountryInfo.DtSep);
   Target:=Target+PadZeroLeft(Month,2);
   Target:=Target+StrPas(@CountryInfo.DtSep);
   Target:=Target+PadZeroLeft(Day,2);
  End;
 End;
 If CountryInfo.Date<2Then Begin
  Target:=Target+StrPas(@CountryInfo.DtSep);
  Target:=Target+PadZeroLeft(Year,4);
 End;
 _CStrDate:=Target
End;


Function CStrDate(Time:LongInt):String;
Var
 DT:DateTime;
Begin
 UnpackTime(Time,DT); { Bits de 31 … 16 de la date ‚tant important!}
 CStrDate:=_CStrDate(DT.Year,DT.Month,DT.Day,$FFFF);
End;


Function CStrTimeDos(Hour,Min,Sec:Byte):String;
Var
 S:String;
Begin
 S:=PadZeroLeft(Hour,2);
 S:=S+StrPas(@CountryInfo.TmSep);
 S:=S+PadZeroLeft(Min,2);
 S:=S+StrPas(@CountryInfo.TmSep);
 S:=S+PadZeroLeft(Sec,2);
 CStrTimeDos:=S
End;

Function CStrTime(Time:LongInt):String;
Var
 DT:DateTime;
Begin
 UnpackTime(Time,DT);
 CStrTime:=CStrTimeDos(DT.Hour,DT.Min,DT.Sec)
End;

Function StrTime(Time:LongInt):String;Begin
 StrTime:=CStrDate(Time)+' '+CStrTime(Time)
End;

Function CStr(I:Comp):String;
Var
 S:String;
 L:Byte Absolute S;
Begin
 Str(I:0:0,S);
 I:=Abs(I);
 If I>=10E10Then CStr:=S Else
 If I>=1000000000Then
  CStr:=Left(S,L-9)+CountryInfo.ThSep[0]+
        Copy(S,L-8,3)+CountryInfo.ThSep+Copy(S,L-5,3)+
        CountryInfo.ThSep[0]+Copy(S,L-2,3) Else
 If I>=1000000Then CStr:=Left(S,L-6)+CountryInfo.ThSep[0]+
                         Copy(S,L-5,3)+CountryInfo.ThSep[0]+
                         Copy(S,L-2,3)Else
 If I>=1000Then CStr:=Left(S,L-3)+CountryInfo.ThSep[0]+Copy(S,L-2,3)
          Else CStr:=S
End;

{$IFDEF FPC}
 Procedure GetCountry;Begin
  CountryInfo.DtSep:='-';
  CountryInfo.TmSep:=':';
 End;
{$ELSE}
 Procedure GetCountry;Assembler;ASM
  MOV AX,3800h
  MOV DX,Offset CountryInfo;
  INT 21h
 END;
{$ENDIF}

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('DI : Cette commande permet d''afficher le contenu d''un ',
                    'r‚pertoire plus rapidement.');
  WriteLn;
  WriteLn('DI [/?] [[unit‚:][chemin][fichier]]');
  WriteLn;
  WriteLn('[lecteur:][chemin]  Pr‚cisent le lecteur et le r‚pertoire dont vous voulez');
  WriteLn('                    afficher le contenu.');
  WriteLn('         [fichier]  Pr‚cise un fichier ou un groupe de fichiers … lister.');
 End
  Else
 Begin
  GetCountry;
  TextBackground(Black);
  TextColor(7);
  ClrScr;
  Path:=ParamStr(1);
  If Path=''Then Path:='*.*'Else
  If Path[Length(Path)]='\'Then Path:=Path+'*.*' Else
  If DirExist(Path)Then Path:=Path+'\*.*';
  Dsk:=Path2Dsk(Path)+1;
  Size:=DiskSize(Dsk);
  Free:=DiskFree(Dsk);
  TextBackground(Blue);
  TextColor(LightCyan);
  Write('Disque ',Path2Drv(Path),':  Total: ',CStr(Size),'  Utilis‚: ',
	 CStr(Size-Free),'  Libre: ',CStr(Free));
  ClrEol;
  WriteLn;
  TextBackground(Black);
  TextColor(7);
  FindFirst(Path,$FFFF,Descr);
  While DosError=0do Begin
   If(Descr.Attr and Directory<>Directory)Then Descr.Name:=SetFullName(Descr.Name);
   Descr.Name:=PadRight(Descr.Name,12);
   If(Descr.Attr and Directory=Directory)Then TextColor(White)
                                         Else TextColor(7);
   Write(Descr.Name);
   If(Descr.Attr and Directory=Directory)Then Begin
    If Descr.Name[1]='.'Then Write(' <R‚p-Parent> ')Else Write(' <Sous-R‚per> ');
   End
    Else
   Write(CStr(Descr.Size):14);
   Write('  ',StrTime(Descr.Time));
   WriteLn;
   FindNext(Descr);
   Inc(Y);
   If(Y=25)Then Begin
    Y:=1;
    TextBackground(Blue);
    TextColor(LightCyan);
    Write('Presse <ESC> pour quitter ou une autre touche pour continuer...');
    ClrEol;
    Repeat Until KeyPressed;
    TextColor(7);
    TextBackground(Black);
    If(ReadKey=#27)Then Break;
    ClrScr;
   End;
  End;
 End;
END.
