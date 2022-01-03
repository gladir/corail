{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal)
}

Program RENDIR;

{$IFDEF FPC}
 Uses SysUtils;

 Function RenameDir(OldName,NewName:String):Boolean;Begin
  OldName:=IncludeTrailingPathDelimiter(OldName);
  NewName:=IncludeTrailingPathDelimiter(NewName);
  RenameDir:=RenameFile(OldName, NewName);
 End;
{$ELSE}
 Uses DOS;

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
   S[0]:=Chr(I-1); { Fixe la longueur de la chaåne de caractäres }
                   { Ö la position du point-virgule(;) - 1 }
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
         Else AddBackSlash; { Toujours àtre certain que le dernier caractäre }
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

 Function RenameDir(Const Source,Target:String):Boolean;Begin
  RenameDir:=FCBRen(Directory,0,Source,Target)
 End;
{$ENDIF}

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Write('RENDIR : Cette commande permet de renommer un repertoire.');
  WriteLn;
  WriteLn('Syntaxe : RENDIR source destination');
 End
  Else
 If ParamCount=2Then Begin
  If Not RenameDir(ParamStr(1),ParamStr(2))Then WriteLn('Erreur de renommage de repertoire');
 End;
END.
