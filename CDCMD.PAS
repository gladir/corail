{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7)
}

Program CDCMD;

Type
 PInteger=^Integer;

 CDAddr=Record Case Integer Of
  0:(HSGSector:Word);
  1:(Time:Record
   Frame:Byte;
   Second:Byte;
   Minute:Byte;
   Unused:Byte;
  End);
 End;

 RequestHdr=Record
  rqLen:Byte;
  rqUnit:Byte;
  rqCmd:Byte;
  rqStatus:Word;
  Reserved:Array[0..7]of Byte;
 End;

 AudioStatus=Record
  Status:Word;
  Start:CDAddr;
  End1:CDAddr;
 END;

 QChannelInfo=Record
  Tno:Byte; { Track }
  x:Byte;
  tMin:Byte;
  tSec:Byte;
  tFrame:Byte;
  Zero:Byte;
  dMin:Byte;
  dSec:Byte;
  dFrame:Byte;
 End;

 IOInpAudioStatus=Record
  IOctlCmd:Byte;
  Report:AudioStatus;
 End;

 IOInpTrackInfo=Record
  IOctlCmd:Byte;
  Tno:Byte;
  Start:CDAddr;
  Control:Byte;
 End;
  { controle :
     2 pistes      00h
     4 pistes      80h
     Emphasis      10h
     Donn,es       40h
     Copie digital 20h }
 IOInpAudioInfo=Record
  IOctlCmd:Byte;
  TrackLo:Byte;
  TrackHi:Byte;
  TrackLeadOut:CDAddr;
 End;

 IOCTLInpRequest=Record
  IOctlRqh:RequestHdr;
  IOctlMedia:Byte;
  IOCtlxFer:PInteger;
  IOCtlnBytes:Word;
  IOctlSector:Word;
  IOctlVolID:PInteger;
 End;

 TrackInfoTag=Record
  Start:CDAddr;
  Frames:LongInt;
  Delta:CDAddr;
 End;

 ATrackInfoTag99=Array[0..98]of TrackInfoTag;

 IOInpDeviceStatus=Record
  IOctlCmd:Byte;
  Status:Word;
 End;

 IOInpUPC=Record
  IOctlCmd:Byte;
  AddrMode:Byte;
  Signature:Array[0..13]of Char;
  aFrame:Byte;                  { ????? }
 End;

 IOInpDeviceHdr=Record
  IOctlCmd:Byte;
  DeviceHdr:PInteger;
 End;

 IOInpMediaChanged=Record
  IOctlCmd:Byte;
  MediaByte:Byte;
 End;

 IOInpQChannel=Record
  IOctlCmd:Byte;
  AddrMode:Byte;
  qInfo:QChannelInfo;
 End;

 IOOutpEject=Record
  IOctlCmd:Byte;
 End;

 IOInpAudiochanInfo=Record
  IOctlCmd:Byte;
  InpChan0:Byte;
  VolChan0:Byte;
  InpChan1:Byte;
  VolChan1:Byte;
  InpChan2:Byte;
  VolChan2:Byte;
  InpChan3:Byte;
  VolChan3:Byte;
 End;

 IOOutpLockDoor=Record
  IOctlCmd:Byte;
  Function1:Byte;
 END;

 IOInpVolumeSize=Record
  IOctlCmd:Byte;
  HSGSect:Word;
 End;

 IOInpSectorSize=Record
  IOctlCmd:Byte;
  AddrMode:Byte;
  SectSize:Word;
 End;

 IOInpDriveBytes=Record
  IOctlCmd:Byte;
  Bytes2read:Byte;
  ReadBuff:Array[0..127]of Byte;
 End;

 IOInpHeadLoc=Record
  IOctlCmd:Byte;
  AddrMode:Byte;
  Location:Word;
 End;

Type CDPlayer=Record
 MaxTitles:Integer;           { Nombre maximal de titre de l'Album }
 Mode:(cdOpen,cdClose);       { Mode CD-ROM … l'int‚rieur et ext‚rieur }
 rqInput:IOInpAudiochanInfo;
 rqVolume:IOInpAudiochanInfo;
 rqInsert:IOOutpEject;
 rqEject:IOOutpEject;
 rqReset:IOOutpEject;
 rqQChan:IOInpQChannel;
 Index:ATrackInfoTag99;
 StartPlay:LongInt;
 EndPlay:LongInt;
 AudioDrive:Word;
 UnitDrive:Byte;
 Titles:Byte;
 rqInp:IOCTLInpRequest;
 CurrTitle:String;
 Actual,Status:Integer;
 RR:Word;
 TimeInfo:QChannelInfo;
 OldTrack,OldTMin,OldTSec:Byte;
 P:Byte;
 T:Array[0..1]of Char;
End;

Const
  NotChanged=$01;
  IooCloseTray=5;
  Lock=$01;
  Seek1=131;
  DigitalCopy=$20;
  DevClose=14;
  HasChanged=$FF;
  StopAudio=133;
  IoiSectSize=7;
  IoctlInp=3;
  IoctlOutp=12;
  Emphasis=$10;
  FourTrack=$80;
  DoorOpen=$001;
  DataAndAudio=$010;
  DoorUnlocked=$002;
  TwoTrack=$00;
  PrefetChing=$080;
  Unlock=$00;
  DevOpen=13;
  HSGAndRed=$200;
  Interleaving=$020;
  WriteLong=134;
  IoiDriveByteS=5;
  IoiQChanInfo=12;
  ReadLong=128;
  DontKnow=$00;
  ResumeAudio=136;
  IoiUPC=14;
  Data=$40;
  IoiAudioInfo=10;
  AudioManipulation=$100;
  IooEject=0;
  IoiVolSize=8;
  IoiDevStat=6;
  IoiLochead=1;
  IoiDrvHead=0;
  IoiMediaChang=9;
  WriteLongVerify=135;
  IoiAudioStatus=15;
  PlayAudio=132;
  IooLock=1;
  IooAudioChanCtrl=3;
  IoiAudioChanInfo=4;
  CookedAnDraw=$004;
  Red=1;
  ReadWrite=$008;
  IoiTrackInfo=11;
  ReadLongPrefetch=130;
  cdInit=0;
  HSG=0;
  IooReset=2;
  OutputFlush=8;
  InputFlush=7;

  rqStatus:IOInpDeviceStatus=(
   IOctlCmd:IOIDEVSTAT;
   Status:0);

  rqUPC:IOInpUPC=(
   IOctlCmd:IOIUPC;
   AddrMode:Red;
   Signature:(#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0);
   aFrame:0);

  rqHeader:IOInpDeviceHdr=(
   IOctlCmd:IOIDRVHEAD;
   DeviceHdr:NIL);

  rqBusy:IOInpDeviceHdr=(
   IOctlCmd:IOIDRVHEAD;
   DeviceHdr:NIL);

  rqAudioStatus:IOInpAudioStatus=(
   IOctlCmd:IOIAUDIOSTATUS;
   Report:(
    Status:0;
    Start:(HSGSector:0);
    End1:(HSGSector:0)));

  rqMedia:IOInpMediaChanged=(
   IOctlCmd:IOIMEDIACHANG;
   MediaByte:0);

 DefaultCDROMPort:Byte=0;

Var
 Q:CDPlayer;
 I,CurrCmd:Integer;
 CurrDrv:Char;

Function IOctlIn(Var Q:CDPlayer;Drive:Word;Unit1:Byte;PRequest:PInteger;rqLen:Word):Word;Near;Begin
 Q.rqInp.IOCtlnBytes:=rqLen;
 Q.rqInp.IOCtlxFer:=pInteger(pRequest);
 Q.rqInp.IOctlRqh.rqUnit:=Unit1;
 ASM
  MOV AX,1510h
  MOV CX,Drive
  LES BX,Q
  ADD BX,Offset CDPlayer.rqInp
  INT 2Fh
 END;
 IOctlIn:=Q.rqInp.IOctlRqh.rqStatus;
End;

Function GetStatus(Var Q:CDPlayer;Drive:Char):Word;Near;Begin
 If(IOctlIn(Q,Integer(Drive),0,@rqStatus,SizeOf(IOInpDeviceStatus))and$8000)<>0Then Begin
  GetStatus:=$FFFF;
 End
  Else
 Begin
  GetStatus:=rqStatus.Status;
 End;
End;

Function GetHeader(Var Q:CDPlayer):PInteger;Near;Begin
 IOctlIn(Q,Q.AudioDrive,Q.UnitDrive,@rqHeader,SizeOf(IOInpDeviceHdr));
 GetHeader:=rqHeader.DeviceHdr;
End;

Function GetMediaChanged(Var Q:CDPlayer):Byte;Near;Begin
 IOctlIn(Q,Q.AudioDrive,Q.UnitDrive,@rqMedia,SizeOf(IOInpMediaChanged));
 GetMediaChanged:=rqMedia.MediaByte;
End;

Procedure ReadAudioStatus(Var Q:CDPlayer;Var Status:AudioStatus);Near;Begin
 IOctlIn(Q,Q.AudioDrive,Q.UnitDrive,@rqAudioStatus,SizeOf(IOInpAudioStatus));
 Status:=rqAudioStatus.Report;
End;

Function Red2HSG(Time:CDAddr):LongInt;Begin
 Red2HSG:=LongInt(LongInt(Time.Time.Minute)*4500+
                  LongInt(Time.Time.Second)*75+
                  LongInt(Time.Time.Frame));
End;

Procedure HSG2Red(nSect:LongInt;Var Local:CDAddr);Begin
 Local.Time.Frame:=nSect mod 75;
 nSect:=nSect div 75;
 Local.Time.Second:=nSect mod 60;
 Local.Time.Minute:=nSect div 60;
End;

Function GetTOC(Var Q:CDPlayer):Byte;Near;
Var
 rqTOC:IOInpAudioInfo;
 rqTrack:IOInpTrackInfo;
 I:Integer;
Begin
 rqTOC.IOctlCmd:=IOIAUDIOINFO;
 IOctlIn(Q,Q.AudioDrive,Q.UnitDrive,@rqTOC,SizeOf(IOInpAudioInfo));
 rqTrack.IOctlCmd:=IOITRACKINFO;
 For I:=Integer(rqTOC.TrackLo)to Integer(rqTOC.TrackHi)+1do Begin
  rqTrack.Tno:={ToBCD(}I{)};
  IOctlIn(Q,Q.AudioDrive,Q.UnitDrive,@rqTrack,SizeOf(IOInpTrackInfo));
  Q.Index[I].Start:=rqTrack.Start;
  Q.Index[I-1].Frames:=Red2HSG(Q.Index[I].Start)-Red2HSG(Q.Index[I-1].Start);
  HSG2Red(Q.Index[I-1].Frames,Q.Index[I-1].Delta);
  If I>=98Then Break;
 End;
 Q.Index[I-1].Frames:=Red2HSG(rqTOC.TrackLeadOut)-Red2HSG(Q.Index[I-1].Start);
 HSG2Red(Q.Index[I-1].Frames,Q.Index[I-1].Delta);
 Q.Index[0].Start:=Q.Index[1].Start;
 Q.Index[0].Frames:=Red2HSG(rqTOC.TrackLeadOut)-Red2HSG(Q.Index[1].Start);
 HSG2Red(Q.Index[0].Frames,Q.Index[0].Delta);
 GetTOC:=rqTOC.TrackHi
End;

Function InitCDAudio(Var Q:CDPlayer):Integer;
Label Xit;
Var
 StatAudio:AudioStatus;
 I,nDrives:Integer;
 LogicalDrives:Array[0..25]of Char;
Begin
 ASM
  MOV @Result,-1
  MOV AX,01500h
  XOR BX,BX
  INT 02Fh
  OR  BX,BX
  JZ  Xit
  MOV nDrives,BX
  XOR AX,AX
  SUB AX,BP
  MOV BX,Offset LogicalDrives
  SUB BX,AX
  PUSH SS
  POP ES
  MOV AX,150Dh
  INT 2Fh
 End;
 I:=DefaultCDROMPort;
 While(I<nDrives)do Begin
  If((GetStatus(Q,LogicalDrives[I])and DataAndAudio))<>0Then Begin
   Q.AudioDrive:=Integer(LogicalDrives[I]);
   Q.UnitDrive:=I and 1;
   Break;
  End;
  I:=Succ(I)
 End;
 If(I=nDrives)Then Begin
  InitCDAudio:=-2;
  Exit;
 End;
 GetHeader(Q);
 I:=1;
 While I<=20do Begin
  If Integer(GetMediaChanged(Q))<128Then Break;
  I:=Succ(I)
 End;
 If Integer(GetMediaChanged(Q))>128Then Begin
  InitCDAudio:=-3;
  Exit;
 End;
 Q.Titles:=GetTOC(Q);
 ReadAudioStatus(Q,StatAudio);
 Q.EndPlay:=Red2HSG(StatAudio.End1);
 InitCDAudio:=Integer(Q.Titles);
Xit:
End;

Function CDInitApp(Q:CDPlayer):Boolean;Begin
 CDInitApp:=False;
 FillChar(Q,SizeOf(Q),0);
 Q.rqInp.IOctlRqh.rqLen:=SizeOf(IOCTLInpRequest);
 Q.rqInp.IOctlRqh.rqCmd:=IOCTLINP;
 Q.MaxTitles:=InitCDAudio(Q);
 Q.T[0]:='_';Q.T[1]:='_';
 CDInitApp:=True;
End;

Function IOctlOut(Drive:Word;Unit1:Byte;PRequest:PInteger;rqLen:Word):Word;
Var
 rqOutp:IOCTLInpRequest;
Begin
 FillChar(rqOutp,SizeOf(rqOutp),0);
 rqOutp.IOctlRqh.rqLen:=SizeOf(IOCTLInpRequest);
 rqOutp.IOctlRqh.rqCmd:=IOCTLOUTP;
 rqOutp.IOCtlnBytes:=rqLen;
 rqOutp.IOCtlxFer:=PInteger(pRequest);
 rqOutp.IOctlRqh.rqUnit:=Unit1;
 ASM
  MOV AX,1510h
  MOV CX,Drive
  MOV BX,Offset rqOutp
  ADD BX,BP
  PUSH SS
  POP ES
  INT 2Fh
 END;
 IOctlOut:=rqOutp.IOctlRqh.rqStatus
End;

Function CDEject(Var Q:CDPlayer):Word;Begin
 Q.rqEject.IOctlCmd:=IooEject;
 CDEject:=IOctlOut(Q.AudioDrive,Q.UnitDrive,@Q.rqEject,SizeOf(IOOutpEject));
End;

Function CDReset(Var Q:CDPlayer):Word;Begin
 Q.rqReset.IOctlCmd:=IooReset;
 CDReset:=IOctlOut(Q.AudioDrive,Q.UnitDrive,@Q.rqReset,SizeOf(IOOutpEject))
End;

Procedure WriteCDROMStatus(Var Q:CDPlayer;T:Integer);
Var
 A:Byte;
 S:String;
Begin
 Q.Status:=t;
 Case(t)of
  -3:S:='Le CD est chang‚';
  -2:S:='Ce n''est pas un CD audio!';
  -1:S:='Il n''y a pas CD-ROM!';
   0:S:='Prˆt';
   1:S:='Jouer';
   2:S:='Pause';
   3:S:='Arrˆter';
   4:S:='Saut ->';
   5:S:='Saut <-';
   6:S:='Recherche >>';
   7:S:='Recherche <<';
   8:S:='Porte ouverte';
   9:S:='Porte fermer';
  10:S:='Un/Shuffle';
  11:S:='Introjouer ';
 End;
 WriteLn(S);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('CDCMD : Cette commande permet d''envoyer des commandes au CD-ROM.');
  WriteLn;
  WriteLn('Syntaxe : CDCMD [option]');
  WriteLn;
  WriteLn(' -e          Ce paramŠtre permet d''ejecter le CD-ROM');
  WriteLn(' -r          Ce paramŠtre permet de r‚initialiser le CD-ROM');
  WriteLn(' -s          Ce paramŠtre permet d''afficher l''‚tat du CD-ROM');
 End
  Else
 Begin
  CurrCmd:=-1;
  CurrDrv:='D';
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='-e'Then CurrCmd:=IooEject Else
   If ParamStr(I)='-r'Then CurrCmd:=IooReset Else
   If ParamStr(I)='-s'Then CurrCmd:=IoiAudioStatus
    Else
   Begin
    WriteLn('ParamŠtre non reconnu');
    Halt(2);
   End;
  End;
  If CurrCmd=-1 Then Begin
   WriteLn('Commande attendu !');
   Halt(3);
  End
   Else
  If CDInitApp(Q)Then Begin
   Case(CurrCmd)of
    IooEject:WriteCDROMStatus(Q,CDEject(Q));
    IooReset:WriteCDROMStatus(Q,CDReset(Q));
    IoiAudioStatus:WriteCDROMStatus(Q,GetSTatus(Q,CurrDrv));
    Else Begin
     WriteLn('Commande non support‚');
    End;
   End;
  End
   Else
  Begin
   WriteLn('Impossible d''initialiser le CD-ROM');
   Halt(1);
  End;
 End;
END.