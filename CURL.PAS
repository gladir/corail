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
  WriteLn(' url        Ce param�tre permet d''indiquer l''URL � lire');
  WriteLn(' --help     Ce param�tre permet de retourner de l''aide sur cette commande');
  WriteLn(' --version  Ce param�tre permet de retourner la version de la commande');
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('CURL 0.2 - Clone Pascal de coreutils, linux, unix ou corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('�crit par Sylvain Maltais');
 End
  Else
 Begin
  URL:=ParamStr(1);
  If URL=''Then Begin
   WriteLn('Un URL est requis comme param�tre !');
   Halt(1);
  End;
   { Cr�e une instance de TFPHTTPClient }
  Client:=TFPHTTPClient.Create(nil);
  Try
    { Envoie une requ�te GET � l'URL donn�e et entrepose la r�ponse }
   Response:=Client.SimpleGet(URL);
    { Affiche la r�ponse }
   {Writeln('Response:');}
   Writeln(Response);
  Except
   On E: Exception do
    Writeln('Error: ', E.Message);
  End;
  { Lib�re la m�moire utilis�e par l'instance de TFPHTTPClient }
  Client.Free;
 End;
END.
