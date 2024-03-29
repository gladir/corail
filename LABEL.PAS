{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program _Label;

{$IFDEF FPC}
 Uses DOS,SysUtils;

 Var
  NewName:String;

 Function GetVolumeInformation(lpRootPathName:PChar; lpVolumeNameBuffer:PChar;
                              nVolumeNameSize:DWORD; lpVolumeSerialNumber:PDWORD;
                              Var lpMaximumComponentLength,lpFileSystemFlags:DWORD;
                              lpFileSystemNameBuffer:PChar; nFileSystemNameSize:DWORD):LongBool; stdcall;
  External 'kernel32.dll' name 'GetVolumeInformationA';

 Function SetVolumeLabelA(lpRootPathName,lpVolumeName:PWideChar):Boolean; stdcall;
  External 'kernel32.dll' name 'SetVolumeLabelA';

 Function GetCurrDrive:Char;
 Var
  S:String;
 Begin
  GetDir(0,S);
  GetCurrDrive := S[1];
 End;

 Function GetVolumeLabel(Dsk:Byte):String;
 Var
  lpMaximumComponentLength, lpFileSystemFlags:DWORD;
  lpRootPathName,lpVolumeNameBuffer:Array[0..MAX_PATH] of Char;
 Begin
  If Dsk=0Then StrPCopy(lpRootPathName,GetCurrDrive+':\')
          Else StrPCopy(lpRootPathName,Char(Dsk+64) + ':\');
  GetVolumeInformation(lpRootPathName,lpVolumeNameBuffer,
                       SizeOf(lpVolumeNameBuffer),NIL,
                       lpMaximumComponentLength,lpFileSystemFlags,NIL,0);
  GetVolumeLabel := StrPas(lpVolumeNameBuffer);
 End;

 Procedure SetVolumeLabel(Dsk:Byte;NewName:String);
 Var
  lpRootPathName,lpVolumeNameBuffer:Array[0..MAX_PATH] of WideChar;
 Begin
  If Dsk=0Then StrPCopy(lpRootPathName,GetCurrDrive+':\')
          Else StrPCopy(lpRootPathName,Char(Dsk+64) + ':\');
  StrPCopy(lpVolumeNameBuffer,NewName);
  WriteLn(SetVolumeLabelA(lpRootPathName,lpVolumeNameBuffer));
 End;

{$ELSE}
 Uses DOS;

 Var
  NewName:String;

 Function GetCurrDrive:Char;
 Var
  S:String;
 Begin
  GetDir(0,S);
  GetCurrDrive := S[1];
 End;

 Function GetCurrentDir:String;
 Var
  S:String;
 Begin
  GetDir(0,S);
  GetCurrentDir:=S;
 End;

 Function GetDsk:Byte;Assembler;ASM
  MOV AH,19h
  INT 21h
 END;

 Function Spc(Len:Byte):String;
 Var
  I:Byte;
  S:String;
 Begin
  S:='';
  For I:=1 to Length(S) do S:=S+' ';
  Spc:=S;
 End;

 Function StrUSpc(Const S:String;L:Byte):String;
 Var
  SLen:Byte Absolute S;
 Begin
  If(L<=SLen)Then StrUSpc:=S
             Else StrUSpc:=S+Spc(L-SLen)
 End;

 Function Left(Const Str:String;Num:Byte):String;Begin
  Left:=Copy(Str,1,Num);
 End;

 Procedure DelChrAt(Var S:String;P:Byte);Begin
  If P=1Then S:=Copy(S,2,255)
        Else S:=Left(S,P-1)+Copy(S,P+1,255)
 End;

 Procedure TruncAfterSemicolon(Var S:String);
 Var
  I:Byte;
 Begin
  For I:=1to Length(S)do If S[I]=';'Then Begin
   S[0]:=Chr(I-1); { Fixe la longueur de la cha�ne de caract�res }
                   { � la position du point-virgule(;) - 1 }
   Exit;
  End;
 End;

 Function Path2Dir(Const Path:String):String;
 Var
  D:DirStr;
  N:NameStr;
  E:ExtStr;

  Procedure AddBackSlash;Begin
   If D[Length(D)]<>'\'Then D:=D+'\'
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
         Else AddBackSlash; { Toujours �tre certain que le dernier caract�re }
                            { se termine par un barre oblique inverse (\). }
  Path2Dir:=D;
 End;

 Function Path2NoDir(Path:String):String;
 Var
  D:DirStr;
  N:NameStr;
  E:ExtStr;
 Begin
  TruncAfterSemicolon(Path);
  FSplit(Path,D,N,E);
  Path2NoDir:=N+E;
 End;

 Function Path2Ext(Const Path:String):String;
 Var
  D:DirStr;
  N:NameStr;
  E:ExtStr;
 Begin
  FSplit(Path,D,N,E);
  Path2Ext:=E;
 End;

 Function Path2Name(Const Path:String):String;
 Var
  D:DirStr;
  N:NameStr;
  E:ExtStr;
 Begin
  FSplit(Path,D,N,E);
  Path2Name:=N;
 End;

 Function SetFullName(Name:String):String;Begin
  If Name[2]<>':'Then Begin
   If Name<>'..'Then Name:=StrUSpc(Path2Name(Name),8)+Path2Ext(Name);
  End;
  SetFullName:=StrUSpc(Name,12);
 End;

 { Cette fonction permet de renommer un fichier, repertoire ou volume avec le nom specifier. }
 Function FCBRen(Attr,Dsk:Byte;Const Source,Target:String):Boolean;
 Label Xit;
 Var
  Q:SearchRec;
  Buf:Array[0..63]of Byte;
  _AH:Byte;
  PtrBuf:Pointer;
  OldDir,SN,TN:String;
 Begin
  OldDir:=FExpand(GetCurrentDir);
  If(Attr and VolumeID=VolumeID)Then Begin
   If Dsk=0Then Dsk:=GetDsk+1;
   ChDir(Chr(Dsk+64)+':\')
  End
   Else
  ChDir(Path2Dir(FExpand(Source)));
  FillChar(Buf,SizeOf(Buf),0);
  Buf[0]:=$FF;
  Buf[6]:=Attr;
  Buf[7]:=Dsk;
  PtrBuf:=@Buf;
  TN:=SetFullName(Path2NoDir(Target));
  DelChrAt(TN,9);
  If(Attr and VolumeID=VolumeID)Then Begin
   FindFirst('*.*',VolumeID,Q);
   If DosError=0Then Begin
    SN:=SetFullName(Path2NoDir(Source));
    Move(SN[1],Buf[8],11);
    ASM
     PUSH DS
      LDS DX,PtrBuf
      MOV AH,13h
      INT 21h
     POP DS
    END;
   End;
   If Target=''Then Begin
    FCBRen:=True;
    Goto Xit;
   End;
   Move(TN[1],Buf[8],11);
   _AH:=$16;
  End
   Else
  Begin
   SN:=SetFullName(Path2NoDir(Source));
   DelChrAt(SN,9);
   Move(SN[1],Buf[8],11);
   Buf[$17]:=Dsk;
   Move(TN[1],Buf[$18],11);
   _AH:=$17;
  End;
  ASM
   PUSH DS
    LDS DX,PtrBuf
    MOV AH,_AH
    INT 21h
   POP DS
   XOR AL,1
   AND AL,1
   MOV @Result,AL
  END;
Xit:
  ChDir(OldDir);
 End;

 Function GetVolumeLabel(Dsk:Byte):String;
 Var
  Info:SearchRec;
  CurrentDir:String;
 Begin
  If Dsk=0Then GetDir(0,CurrentDir)
          Else CurrentDir:=Char(Dsk+64);
  FindFirst(CurrentDir[1]+':\*.*',VolumeID,Info);
  While DosError=0do Begin
   If(Info.Attr = VolumeID)Then Begin
    GetVolumeLabel:=Info.Name;
    Exit;
   End;
   FindNext(Info);
  End;
  GetVolumeLabel:=''
 End;

 Function SetVolumeLabel(Dsk:Byte;Const S:String):Boolean;Begin
  SetVolumeLabel:=FCBRen(VolumeID,Dsk,GetVolumeLabel(Dsk),S)
 End;

{$ENDIF}

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function StringToChar(S:String;Index:Byte):Char;Begin
 If Length(S)<=Index Then StringToChar:=S[Index]
                     Else StringToChar:=#0;
End;

Var
 I:Byte;
 IsUnit:Array[0..255]of Boolean;
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;

Function IsRomanLetter(C:Char):Boolean;Begin
 IsRomanLetter := C in ['A'..'Z','a'..'z'];
End;

BEGIN
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')or(ParamStr(1)='HELP')Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Erstellt, �ndert oder l�scht die Bezeichnung eines Datentr�gers.');
    WriteLn;
    WriteLn('LABEL [Laufwerk:][Bezeichnung]');
   End;
   _English:Begin
    WriteLn('Creates, changes, or deletes the volume label of a disk.');
    WriteLn;
    WriteLn('LABEL [drive:] [label]');
   End;
   Else Begin
    WriteLn('LABEL : Cette commande permet de changer le nom du volume');
    WriteLn;
    WriteLn('Syntaxe: LABEL [unite: [nouveaunom]]');
    WriteLn;
    WriteLn(' unite:      Indique l''unit� que vous souhaitez trait�');
    WriteLn(' nouveaunom  Indique le nouveau du volume');
    WriteLn;
    WriteLn('NB: Si le nouveaunom n''est pas d�finit, il retournera le nom courant');
   End;
  End;
 End
  Else
 If ParamCount=0Then Begin
  WriteLn('�tiquette de l''unit� ',GetCurrDrive,' est ',GetVolumeLabel(0));
 End
  Else
 Begin
  NewName:='';
  For I:=1 to ParamCount do Begin
   IsUnit[I] := Pos(':',ParamStr(I)) > 0;
   If Not(IsUnit[I])Then NewName:=ParamStr(I);
  End;
  If NewName=''Then Begin
   For I:=1 to ParamCount do Begin
    If IsUnit[I]Then WriteLn('�tiquette de l''unit� ',ParamStr(I),' est ',
                            GetVolumeLabel(Byte(StringToChar(ParamStr(I),1))-64));
   End
  End
   Else
  Begin
   For I:=1 to ParamCount do Begin
    If IsUnit[I]Then SetVolumeLabel(Byte(StringToChar(ParamStr(I),1))-64,NewName);
   End
  End;
 End;
END.
