{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program BIN2BGI;

{$I-}
Uses DOS;

Const
 Version:Byte=3;
 Revision:Byte=0;
 Subrev:Byte=1;
 MinVersion:Byte=1;
 MinRevision:Byte=0;
 HeaderSize:Word=160;
 DrvNum:Word=0;
 Null:Byte=0;
 HeaderText=110;
 SubRev2=1;
 SubRev3=1;

Type
 ByteArray=Array[0..65520]of Byte;
 String12=String[12];
 String3=String[3];

Var
 Dname:String[8];
 Tname,Mname,Iname,Oname,Hname,Stemp:String;
 ISize,OSize,HSize,i,Error:Integer;Result:Word;
 Ifile,Ofile,Hfile:File;Mfile:Text;
 Fptr:^ByteArray;Hdata:Array[0..HeaderText]of Char;
 CodeSize,DataSize,DataOfs:Word;
 CreateOK:Boolean;
 Year,Month,Day,DoW:Word;

Const
 CopyRightFile='COPYRITE.DAT';
 Header1='BGI Device Driver';
 Header2='Tous droits r‚serv‚s par les Chevaliers de Malte 1997';
 MonthStr:Array[0..12]of String3=('   ','Jan','F‚v','Mar','Avr','Mai','Jui','Jul','Ao–','Sep','Oct','Nov','D‚c');

Function GetHex(S:String;Var Result:Word):Boolean;Var i,j,k:Integer;Begin
 GetHex:=False;j:=0;Result:=0;k:=Pos('H',S);
 If k=0Then Exit;
 For i:=1to Pred(k)do Begin
  If S[i]>' 'Then begin
   If Not(S[I]in['0'..'9','A'..'F'])Then Exit;
   If S[i]>'9'Then S[i]:=Char(Byte(S[i])-7);
   Result:=(Result shl 4)+(Byte(S[i])and $f);
   Inc(j);
  End;
 End;
 If j>0Then GetHex:=True;
End;

Function FStr(I:Integer):String;Var S:string;Begin;Str(I,S);FStr:=S;End;

Function fstr2(I:Integer):String;Var S:String;Begin
 Str(I,S);
 If Length(S)<2Then S:='0'+S;
 FStr2:=S;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BIN2BGI: Cette programme permet d''‚criture l''entˆte de la portion du pilote BGI.');
  WriteLn;
  WriteLn('Syntaxe: BIN2BGI [DrvName] [input.BIN] [output.BGI] [mapfile.MAP] [version]');
  WriteLn;
  WriteLn(' [DrvName] est le nom de la device (exemple EGA ou CGA)');
  WriteLn(' [input.BIN] est le DRIVER.BIN d''EXE2BIN.');
  WriteLn(' [output.BGI] est le nom fichier DRIVER.BGI.');
  WriteLn(' [mapfile.MAP] est le nom du fichier DRIVER.MAP.');
  WriteLn(' [version] est la version du pilote.');
 End
  Else
 If ParamCount>=1Then Begin
  FillChar(DName,Length(DName),0);
  DName:=ParamStr(1);
  For i:=1to Length(DName)do DName[i]:=UpCase(Dname[i]);
  TName:=DName;IName:=TName;
  If ParamCount>1Then IName:=ParamStr(2);
  If Pos('.',IName)<>0Then IName:=Copy(IName,1,Pred(Pos('.',IName)));
  TName:=IName;MName:=IName;IName:=IName+'.BIN';
  Assign(IFile,IName);
  Reset(IFile,1);
  Error:=IOresult;
  If Error<>0Then Begin
   Writeln('Erreur ',Error,': Impossible d''ouvrir le fichier d''entr‚e ',IName);
   Halt(2);
  End;
  ISize:=FileSize(Ifile);
  Reset(Ifile,1);
  GetMem(Fptr,ISize);
  BlockRead(Ifile,Fptr^,ISize,Result);
  Close(Ifile);
  Error:=IOresult;
  If(Error<>0)or(Result<>ISize)Then Begin
   Writeln('Erreur ',Error,': Erreur de lecture du fichier d''entr‚e ',Iname);
   Halt(4);
  End;
  Oname:=Tname;
  If ParamCount>2Then Oname:=ParamStr(3);
  If Pos('.',Oname)<>0Then Oname:=Copy(Oname,1,Pred(pos('.',Oname)));
  Tname:=Oname;Oname:=Oname+'.BGI';
  Assign(Ofile,Oname);
  Rewrite(Ofile,1);
  Error:=IOresult;
  If Error<>0Then Begin
   Writeln('Erreur ',Error,': Impossible d''ouvrir le fichier de sortie ',Oname);
   Halt(3);
  End;
  If ParamCount>3Then Mname:=ParamStr(4);
  If Pos('.',Mname)<>0Then Mname:=Copy(Mname,1,Pred(Pos('.',Mname)));
  Mname:=Mname+'.MAP';
  If ParamCount>4Then Begin
   Stemp:=ParamStr(5);
   Case Stemp[1]of
    '2':Begin;Version:=2;Revision:=0;SubRev:=SubRev2;MinVersion:=1;MinRevision:=0;End;
    '3':Begin;Version:=3;Revision:=0;SubRev:=SubRev3;MinVersion:=1;MinRevision:=0;End;
    Else Begin
     Writeln('ERREUR: Mauvais num‚ro de version: ',Stemp);
     Halt(5);
    End;
   End;
  End;
  CreateOK:=False;
  If(Fptr^[15]<>Version)Then Begin
   Writeln('ATTENTION: Le num‚ro de version du fichier binaire (',Fptr^[15],') n''est pas compatible avec');
   Writeln(' la version sp‚cifi‚ (',VERSION,'). S.V.P. faite une double v‚rification de la validit‚ des codes');
   If(Fptr^[0]=$1E {pushds})and(Fptr^[1]=$2E {segcs})and {v‚rifie pour V3.00}
     (Fptr^[2]=$8E)and(Fptr^[3]=$1E {movds,[alias]})Then Begin
    Version:=3;Revision:=0;MinVersion:=3;MinRevision:=0;
    If Fptr^[15]=0Then Begin
     Writeln('Le fichier binaire est apparamant ‚t‚ cr‚‚ par le ToolKit de Borland');
     Writeln('pour la versions de pilote 3.00.');
     SubRev:=0;CreateOK:=True;
    End
     else
    If Fptr^[15]=3Then Begin;SubRev:=SubRev3;CreateOK:=True;End;
   End
    else
   If(Fptr^[0]=$1E{pushds})and(Fptr^[1]=$0E{pushcs})and
     (Fptr^[2]=$1F{popds})and(Fptr^[3]=$FC{cld})Then Begin
    Version:=2;Revision:=0;
    If(Fptr^[12]=Byte('C'))and(Fptr^[13]=Byte('B'))and(Fptr^[15]=0)Then Begin
     Writeln('Fichier binaire apparaŒt ˆtre une version originalement binaire 2.00');
     SubRev:=0;MinVersion:=1;MinRevision:=0;CreateOK:=True;
    End
     else
    If Fptr^[15]=2Then Begin;SubRev:=SubRev2;MinVersion:=1;MinRevision:=0;CreateOK:=True;End;
   End;
   If(CreateOK)Then Write('Assumation: ')
    else
   Begin
    Writeln('ERREUR: Le fichier binaire est de type inconnu. Je ne peux pas cr‚er le pilote.');
    Halt(7);
   End;
  End;
  If Version>2Then Begin
   Assign(Mfile,Mname);
   Reset(Mfile);
   Error:=IOresult;
   If Error<>0Then Begin
    Writeln(Error,' ERREUR: Impossible d''ouvrir le fichier MAP ',Mname);
    Halt(3);
   End;
   Repeat
    ReadLn(Mfile,Stemp);
    If Pos('DATA',Stemp)=0Then Stemp:='';
   Until Eof(Mfile)or(Stemp<>'');
   If Not(GetHex(Stemp,Result))Then Begin
    Writeln(Error,' ERREUR: Mauvais format de fichier MAP ',Mname);
    Halt(3);
   End;
   DataOfs:=Result;CodeSize:=DataOfs;DataSize:=Isize-DataOfs;
  End;
  Hname:=CopyRightFile;
  Assign(Hfile,Hname);
  Reset(Hfile,1);
  Error:=IOresult;
  If Error<>0Then Begin
   Writeln(Error,' ERREUR: Impossible d''ouvrir le fichier de droit d''auteur',Hname);
   Writeln('Utilisez un message de droit d''auteur interne:');
   Writeln(Header2);
  End;
  HSize:=FileSize(Hfile);
  If(HSize>HeaderText)Then HSize:=HeaderText;
  Reset(Hfile,1);
  BlockRead(Hfile,Hdata,HSize,Result);
  Close(Hfile);
  Error:=IOresult;
  If(Error<>0)or(Result<>HSize)Then Begin
   Writeln(Error,' Erreur de lecture de l''entˆte du fichier ',Hname);
   Halt(4);
  End;
  If HSize>0Then Begin
   i:=1;
   While(i<HSize)do Begin
    If Hdata[i]<#32Then HSize:=i;
    Inc(i);
   End;
  End;
  GetDate(Year,Month,Day,DoW);
  If Version=2Then Stemp:='pk'#8#8else Stemp:='FBGD'#8#8#8#8;
  Stemp:=Stemp+Header1+' ('+Dname+') '+fstr(Version)+'.'+fstr(Revision)+fstr(SubRev)+'k  ';
  Stemp:=Stemp+MonthStr[Month]+' '+fstr2(Day)+' '+fstr(Year);
  Stemp:=Stemp+#13#10;
  If Length(Stemp)+4+Hsize<127Then Begin
   For i:=0to pred(HSize)do If Not(HData[i]in[#$1A,#0])Then Stemp:=Stemp+HData[i];
  End
   Else
  Begin
   Writeln('ERREUR: Fichier de droits d''auteurs trop long. Utilis‚ un message de droit d''auteur interne.');
   Writeln(Header2);
   Stemp:=Stemp+Header2;
  End;
  Stemp:=Stemp+#13#10#0#$1A;
  Writeln('Cr‚ation de ',Dname,' V',Version,'.',Revision,SubRev,'k  ',
         MonthStr[Month]+' '+FStr2(Day)+' '+FStr(Year),'  pilote BGI.');
  BlockWrite(Ofile,Stemp[1],Length(Stemp));
  BlockWrite(Ofile,Word(HeaderSize),2);
  BlockWrite(Ofile,Word(DrvNum),2);
  Case(Version)of
   2:Begin
    BlockWrite(Ofile,Word(ISize),2);
    BlockWrite(Ofile,Byte(VERSION),1);
    BlockWrite(Ofile,Byte(REVISION),1);
    BlockWrite(Ofile,Byte(MinVersion),1);
    BlockWrite(Ofile,Byte(MinRevision),1);
   End;
   3:Begin
    BlockWrite(Ofile,Word(CodeSize),2);
    BlockWrite(Ofile,Byte(VERSION),1);
    BlockWrite(Ofile,Byte(REVISION),1);
    BlockWrite(Ofile,Byte(MinVersion),1);
    BlockWrite(Ofile,Byte(MinRevision),1);
    BlockWrite(Ofile,Word(DataOfs),2);
    BlockWrite(Ofile,Word(DataSize),2);
   End;
  End;
  OSize:=FilePos(Ofile);
  For i:=OSize to$7F do BlockWrite(Ofile,Byte(null),1);
  BlockWrite(Ofile,Word(HeaderSize),2);
  BlockWrite(Ofile,Word(DrvNum),2);
  Case(Version)of
   2:Begin
    BlockWrite(Ofile,Word(ISize),2);
    BlockWrite(Ofile,Byte(Version),1);
    BlockWrite(Ofile,Byte(Revision),1);
    BlockWrite(Ofile,Byte(MinVersion),1);
    BlockWrite(Ofile,Byte(MinRevision),1);
   End;
   3:Begin
    Blockwrite(Ofile,Word(CodeSize),2);
    Blockwrite(Ofile,Byte(Version),1);
    Blockwrite(Ofile,Byte(Revision),1);
    Blockwrite(Ofile,Byte(MinVersion),1);
    Blockwrite(Ofile,Byte(MinRevision),1);
    Blockwrite(Ofile,Word(DataOfs),2);
    Blockwrite(Ofile,Word(DataSize),2);
   End;
  End;
  BlockWrite(Ofile,DName,Length(Dname)+1);
  OSize:=FilePos(Ofile)+1;
  For i:=OSize to(HeaderSize)do BlockWrite(Ofile,Byte(Null),1);
  Blockwrite(Ofile,Fptr^,ISize,Result);
  FreeMem(Fptr,ISize);
  Close(Ofile);
 End
  Else
 WriteLn('Parametres attendue');
END.
