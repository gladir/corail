{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program DU;

Uses DOS;

Var
 OptionParam:Set Of (Count,Bytes,Summarize,HumanReadable);
 TotalSize:LongInt;
 Info:SearchRec;
 S,StartDir,OriginDir,DirSearch:String;
 ShowFileSize:Boolean;
 I:Integer;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function GetComputedSize(Size:LongInt):String;
Var
 S:String;
Begin
 If(HumanReadable in OptionParam)Then Begin
  If Size>1073741824Then Begin
   Str(Size shr 30,S);
   S:=S+'G';
  End
   Else
  If Size>1048576Then Begin
   Str(Size shr 20,S);
   S:=S+'M';
  End
   Else
  If Size>1024Then Begin
   Str(Size shr 10,S);
   S:=S+'K';
  End
   Else
  Begin
   Str(Size,S);
   S:=S+'B';
  End;
 End
  Else
 Begin
  If(Bytes in OptionParam)Then Size:=Size Else
  If Size and $1FF>0Then Size:=Succ(Size shr 10)
                    Else Size:=(Size shr 10);
  Str(Size,S);
 End;
 GetComputedSize:=S;
End;

Function Replace(Source,Old,New:String):String;
Var
 P:LongInt;
Begin
 While Pos(Old,Source)<>0 do Begin
  P:=Pos(Old,Source);
  Delete(Source,P,Length(Old));
  Insert(New,Source,P);
 End;
 Replace:=Source;
End;


Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function IsWildCard(Path:String):Boolean;Begin
 IsWildCard:=(Pos('*',Path)>0)or(Pos('?',Path)>0)
End;

Function Path2Dir(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 Path2Dir:='';
 If Path=''Then Exit;
 FSplit(Path,D,N,E);
 If E=''Then Begin
  If D[Length(D)]<>'\'Then D:=D+'\';
  D:=D+E;
 End;
 If D=''Then Path2Dir:='' Else
 If D[Length(D)]<>'\'Then D:=D+'\';
 Path2Dir:=D;
End;

Function SetPath4AddFile(Path:String):String;Begin
 If Path=''Then GetDir(0,Path);
 If Path[Length(Path)]<>'\'Then Path:=Path+'\';
 SetPath4AddFile:=Path;
End;

Function GetFilesSize(FileSpec:String):LongInt;
Var
 Info:SearchRec;
 CurrFile:File;
 Found:Boolean;
 CurrSize,Size:LongInt;
 S:String;
Begin
 GetFilesSize:=0;
 Size:=0;
 FileSpec:=FExpand(FileSpec);
 FindFirst(FileSpec,AnyFile,Info);
 Found:=False;
 While DOSError=0 do Begin
  Found:=True;
  If Info.Attr and Directory=Directory Then Begin
   If Not((Info.Name='.')or(Info.Name='..')or(Info.Name=''))Then Begin
    CurrSize:=GetFilesSize(SetPath4AddFile(Path2Dir(FileSpec)+Info.Name)+'*.*');
    TotalSize:=TotalSize+CurrSize;
    S:=GetComputedSize(CurrSize);
    If Not(Summarize in OptionParam)Then Begin
     Write(PadRight(S,8));
     WriteLn('./',Replace(Replace(SetPath4AddFile(Path2Dir(FileSpec)+Info.Name),StartDir,''),'\','/'));
    End;
   End;
  End
   Else
  Begin
   Size:=Size+Info.Size;
  End;
  FindNext(Info);
 End;
 GetFilesSize:=Size;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('DU : Cette commande permet de comptabilis‚ l''espace occup‚ ',
                'par un r‚pertoire et ses enfants.');
  WriteLn;
  WriteLn('Syntaxe : DU [option] [r‚pertoire]');
  WriteLn;
  WriteLn(' r‚pertoire        Emplacement o— effectuer la comptabilisation');
  WriteLn(' -b                Affiche la taille en octets');
  WriteLn(' --bytes           Affiche la taille en octets');
  WriteLn(' -c                Calcul l''espace occup‚');
  WriteLn(' -h                Affiche une taille lisible pour ');
  WriteLn('                   un humain (exemple: 1K, 234M, 2G,...)');
  WriteLn(' --help            Affiche de l''aide sur cette commande');
  WriteLn(' --human-readable  Affiche une taille lisible pour ');
  WriteLn('                   un humain (exemple: 1K, 234M, 2G,...)');
  WriteLn(' -s                Affiche seulement le total');
  WriteLn(' --summarize       Affiche seulement le total');
 End
  Else
 Begin
  OptionParam:=[];
  ShowFileSize:=False;
  TotalSize:=0;
  DirSearch:='';
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='-s')or(ParamStr(I)='--summarize')Then Include(OptionParam,Summarize) Else
   If(ParamStr(I)='-b')or(ParamStr(I)='--bytes')Then Include(OptionParam,Bytes) Else
   If(ParamStr(I)='-h')or(ParamStr(I)='--human-readable')Then Include(OptionParam,HumanReadable) Else
   If ParamStr(I)='-c'Then Include(OptionParam,Count)
                      Else DirSearch:=ParamStr(I);
  End;
  If DirSearch<>''Then Begin
   ShowFileSize:=IsWildCard(DirSearch);
   If IsWildCard(DirSearch)Then Begin
    OriginDir:=FExpand(DirSearch);
    StartDir:=Path2Dir(OriginDir);
   End
    Else
   Begin
    OriginDir:=FExpand(SetPath4AddFile(DirSearch)+'*.*');
    StartDir:=Copy(OriginDir,1,Length(OriginDir)-3);
   End;
   FindFirst(OriginDir,AnyFile,Info);
  End
   Else
  Begin
   OriginDir:='';
   StartDir:=FExpand('*.*');
   StartDir:=Copy(StartDir,1,Length(StartDir)-3);
   FindFirst('*.*',AnyFile,Info);
  End;
  While DOSError=0 do Begin
   If Info.Attr and Directory=Directory Then Begin
    If(Info.Name<>'.')and(Info.Name<>'..')Then Begin
     GetFilesSize(SetPath4AddFile(StartDir)+Info.Name);
    End;
   End
    Else
   If(ShowFileSize)Then Begin
    S:=GetComputedSize(Info.Size);
    TotalSize:=TotalSize+Info.Size;
    If Not(Summarize in OptionParam)Then Begin
     Write(PadRight(S,8));
     WriteLn('./',Replace(SetPath4AddFile(StartDir)+Info.Name,'\','/'));
    End;
   End;
   FindNext(Info);
  End;
  S:=GetComputedSize(TotalSize);
  If(Summarize in OptionParam)Then Begin
   WriteLn(PadRight(S,8),'.');
  End
   Else
  If(Count in OptionParam)Then Begin
   WriteLn(PadRight(S,8),'.');
   WriteLn(PadRight(S,8),' total');
  End;
 End;
END.