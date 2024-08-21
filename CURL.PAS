{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program CURL;

{$mode objfpc}

Uses
 fphttpclient,OpenSSLSockets,SysUtils;

Var
 Client:TFPHTTPClient;
 URL,Response:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CURL : Cette commande permet de lire le contenu d''un URL et ');
  WriteLn('       de le retourner dans la console.');
  WriteLn;
  WriteLn('Syntaxe : CURL url');
 End
  Else
 Begin
  URL:=ParamStr(1);
  If URL=''Then Begin
   WriteLn('Un URL est requis comme paramŠtre !');
   Halt(1);
  End;
   { Cr‚e une instance de TFPHTTPClient }
  Client:=TFPHTTPClient.Create(nil);
  Try
    { Envoie une requˆte GET … l'URL donn‚e et stocke la r‚ponse }
   Response:=Client.SimpleGet(URL);
    { Affiche la r‚ponse }
   Writeln('Response:');
   Writeln(Response);
  Except
   On E: Exception do
    Writeln('Error: ', E.Message);
  End;
  { LibŠre la m‚moire utilis‚e par l'instance de TFPHTTPClient }
  Client.Free;
 End;
END.