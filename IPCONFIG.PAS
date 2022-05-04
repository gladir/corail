{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program IPCONFIG;

Uses
 Winsock;

Type
  TaPInAddr=Array [0..10]of PInAddr;
  PaPInAddr=^TaPInAddr;

Var
 phe:PHostEnt;
 pptr:PaPInAddr;
 Buffer:Array [0..63] of Ansichar;
 I:Integer;
 GInitData:TWSADATA;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('IPCONFIG : Cette commande permet d''afficher l''adresse IP de la machine local');
  WriteLn;
  WriteLn('Syntaxe : IPCONFIG');
 End
  Else
 Begin
  WriteLn;
  WriteLn('Configuration IP de Windows');
  WriteLn;
  WriteLn;
  WSAStartup($101,GInitData);
  GetHostName(Buffer,SizeOf(Buffer));
  phe:=GetHostByName(Buffer);
  If phe = nil Then Begin
   WriteLn('Hote introuvable');
   Exit;
  End;
  pptr:=PaPInAddr(phe^.h_addr_list);
  i:=0;
  While pptr^[i] <> nil do Begin
   WriteLn('Carte Ethernet Local Area Connection ',I+1,' :');
   WriteLn;
   WriteLn('   Adresse IPv4 . . . :',StrPas(inet_ntoa(pptr^[i]^)));
   WriteLn;
   Inc(i);
  End;
  WSACleanup;
 End;
END.
