{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program GETMAC;

Uses
 Windows,NB30;

Var
 AdapterList:TLanaEnum;
 NCB:TNCB;
 I:Integer;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

 function GetAdapterInfo(Lana: UChar): String;
var
 Adapter: Adapter_Status;
 NCB: _NCB;
begin
 FillChar(NCB, SizeOf(NCB), 0);
 NCB.ncb_command := NCBRESET;
 NCB.ncb_lana_num := Lana;
 if Netbios(@NCB) <> UChar(NRC_GOODRET) then
 begin
   GetAdapterInfo:= 'Adresse MAC introuvable';
   Exit;
 end;

 FillChar(NCB, SizeOf(NCB), 0);
 NCB.ncb_command := NCBASTAT;
 NCB.ncb_lana_num := Lana;
 NCB.ncb_callname[0]:=Byte('*');
 NCB.ncb_callname[1]:=0;

 FillChar(Adapter, SizeOf(Adapter), 0);
 NCB.ncb_buffer := @Adapter;
 NCB.ncb_length := SizeOf(Adapter);
 if Netbios(@NCB) <> UChar(NRC_GOODRET) then
 begin
   GetAdapterInfo:= 'Adresse MAC introuvable';
   Exit;
 end;
 GetAdapterInfo :=
   ByteHex2Str(Byte(Adapter.adapter_address[0])) + '-' +
   ByteHex2Str(Byte(Adapter.adapter_address[1])) + '-' +
   ByteHex2Str(Byte(Adapter.adapter_address[2])) + '-' +
   ByteHex2Str(Byte(Adapter.adapter_address[3])) + '-' +
   ByteHex2Str(Byte(Adapter.adapter_address[4])) + '-' +
   ByteHex2Str(Byte(Adapter.adapter_address[5]));
end;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('GETMAC : Cette commande permet d''afficher la liste des adresse MAC de la machine local');
  WriteLn;
  WriteLn('Syntaxe : GETMAC');
 End
  Else
 Begin
  WriteLn;
  WriteLn('Adresse physique    Nom du transport');
  WriteLn('=================== ====================================');
  FillChar(NCB, SizeOf(NCB), 0);
  NCB.ncb_command := NCBENUM;
  NCB.ncb_buffer := @AdapterList;
  NCB.ncb_length := SizeOf(AdapterList);
  Netbios(@NCB);
  If AdapterList.Length<=0Then WriteLn('Adresse MAC introuvable')
   Else
  For I:=0 to AdapterList.Length-1 do Begin
   WriteLn(GetAdapterInfo(AdapterList.lana[I]),' ':3,'N/A');
  End;
 End;
END.