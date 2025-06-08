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
 URL,Response:AnsiString;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CURL : Cette commande permet de lire le contenu d''un URL et ');
  WriteLn('       de le retourner dans la console.');
  WriteLn;
  WriteLn('Syntaxe : CURL [url] [options]');
  WriteLn;
  WriteLn(' url        Ce paramätre permet d''indiquer l''URL Ö lire');
  WriteLn(' --help     Ce paramätre permet de retourner de l''aide sur cette commande');
  WriteLn(' --version  Ce paramätre permet de retourner la version de la commande');
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('CURL 0.2 - Clone Pascal de coreutils, linux, unix ou corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('êcrit par Sylvain Maltais');
 End
  Else
 Begin
  URL:=ParamStr(1);
  If URL=''Then Begin
   WriteLn('Un URL est requis comme paramätre !');
   Halt(1);
  End;
   { CrÇe une instance de TFPHTTPClient }
  Client:=TFPHTTPClient.Create(nil);
  Try
    { Envoie une requàte GET Ö l'URL donnÇe et entrepose la rÇponse }
   Response:=Client.SimpleGet(URL);
    { Affiche la rÇponse }
   {Writeln('Response:');}
   Writeln(Response);
  Except
   On E: Exception do
    Writeln('Error: ', E.Message);
  End;
  { Libäre la mÇmoire utilisÇe par l'instance de TFPHTTPClient }
  Client.Free;
 End;
END.
