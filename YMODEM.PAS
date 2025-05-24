{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7)
}

Program YMODEM;

Uses
 Dos;

Const
 SOH=#1;   { D‚but de l'entˆte - 128 octets }
 EOT=#4;   { Fin de transmission }
 ACK=#6;   { Connaissance }
 NAK=#21;  { Connaissance n‚gative }
 CAN=#24;  { Annul‚ }
 CPMEOF=^Z;
 BLOCK_SIZE=128;

Type
 TBuffer=Array[0..BLOCK_SIZE-1] of Byte;

Var
 F:File;
 FileName:String;
 Buf:Array[1..BLOCK_SIZE] of Byte;
 BlockNum:Byte;
 ComPort:Word;
 I:Byte;
 BytesRead:Integer;
 BytesToWrite:Integer;
 C:Char;
 Receiving:Boolean;
 Send:Boolean;

Procedure SendChar(C:Char);Begin
 Port[ComPort]:=Ord(C);
End;

Function ReceiveChar(Var C:Char;Timeout:Integer):Boolean;
Var
 T:LongInt;
Begin
 T:=MemL[$40:$6C]; { Tic d'horloge du BIOS }
 Repeat
  If Port[ComPort] and $01<>0 Then Begin
   C := Chr(Port[ComPort]);
   ReceiveChar := True;
   Exit;
  End;
 Until MemL[$40:$6C] - T>Timeout;
 ReceiveChar:=False;
End;

Procedure SendBlock(Buf:Array of Byte;BlockNum:Byte);
Var
 i:Integer;
 ChkSum:Byte;
Begin
 SendChar(SOH);
 SendChar(Chr(BlockNum));
 SendChar(Chr(255 - BlockNum));
 ChkSum := 0;
 For i:=0 to BLOCK_SIZE-1 do Begin
  SendChar(Chr(Buf[i]));
  ChkSum:=ChkSum+Buf[i];
 End;
 SendChar(Chr(ChkSum));
End;

Function ReceiveBlock(Buf:Array of Byte;Var BlockNum:Byte):Boolean;
Var
 i:Integer;
 Header,BNum,BInv:Byte;
 ChkSum,CalcSum:Byte;
 C:Char;
Begin
 If Not ReceiveChar(C, 10)Then Begin
  ReceiveBlock:=False;
  Exit;
 End;
 If C <> SOH Then Begin
  ReceiveBlock:=False;
  Exit;
 End;
 BNum:=Ord(Port[ComPort]);
 BInv:=Ord(Port[ComPort]);
 For i:=0 to BLOCK_SIZE-1 do Buf[i]:=Port[ComPort];
 ChkSum:=Port[ComPort];
 CalcSum:=0;
 For i:=0 to BLOCK_SIZE-1 do CalcSum:=CalcSum+Buf[i];
 If(BNum+BInv<>255)or(ChkSum<>CalcSum)Then Begin
  ReceiveBlock := False;
  Exit;
 End;
 BlockNum:=BNum;
 ReceiveBlock:=True;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('YMODEM : Cette commande permet d''envoyer ou de recevoir un ',
          ' fichier en utilisant le protocole YModem.');
  WriteLn;
  WriteLn('Syntaxe : YMODEM [fichier]');
 End
  Else
 Begin
  FileName:='';
  For I:=1 to ParamCount do Begin
   FileName:=ParamStr(I);
  End;
  Send:=FileName<>'';
  If(Send)Then Begin
   If FileName=''Then Begin
    Write('Nom du fichier … envoyer : ');
    ReadLn(FileName);
  End;
   Assign(F,FileName);
   {$I-} Reset(F, 1); {$I+}
   If IOResult<>0 Then Begin
    Writeln('Erreur : impossible d''ouvrir le fichier.');
    Halt(1);
   End;
   ComPort:=$3F8; { Port COM1 par d‚faut }
   BlockNum:=1;
     { Attendre le signal 'C' du r‚cepteur }
   Write('Attente du signal du r‚cepteur...');
   Repeat
    ReceiveChar(C,10);
   Until C='C';
   Writeln('OK');
    { Envoyer le bloc 0 (nom + taille fictive) }
   FillChar(Buf, BLOCK_SIZE, 0);
   Move(FileName[1], Buf[1], Length(FileName));
   Buf[Length(FileName)] := 0;
   SendBlock(Buf, 0);
   Repeat
    ReceiveChar(C, 10);
   Until C = ACK;
    { Envoi des blocs de donn‚es }
   Repeat
    BlockRead(F, Buf, BLOCK_SIZE, BytesRead);
    If BytesRead < BLOCK_SIZE Then Begin
     For I:=BytesRead to BLOCK_SIZE-1 do Buf[I]:=Ord(CPMEOF);
    End;
    SendBlock(Buf, BlockNum);
    Repeat
     ReceiveChar(C, 10);
    Until (C=ACK)or(C=NAK);
    If C = ACK Then Inc(BlockNum);
   Until BytesRead<BLOCK_SIZE;
     { Envoyer EOT }
   Repeat
    SendChar(EOT);
    ReceiveChar(C, 10);
   Until C=ACK;
   Close(F);
   Writeln('Transmission termin‚e.');
  End
   Else
  Begin
   ComPort := $3F8; { COM1 }
   WriteLn('R‚cepteur YModem (simplifi‚)');
   WriteLn('En attente du d‚but de la transmission...');
    { Envoi du caractŠre 'C' (pour signaler la disponibilit‚) }
   SendChar('C');
    { R‚ception du bloc 0 : nom du fichier }
   If ReceiveBlock(Buf,BlockNum)Then Begin
    FileName := '';
    I:=0;
    While (Buf[I]<>0) and (I<BLOCK_SIZE) do Begin
     FileName:=FileName+Chr(Buf[I]);
     Inc(I);
    End;
    Assign(F,FileName);
    Rewrite(F,1);
    SendChar(ACK);
    BlockNum:=1;
    Receiving:=True;
    While Receiving do Begin
     If ReceiveBlock(Buf, I)Then Begin
      If I=BlockNum Then Begin
       BlockWrite(F,Buf,BLOCK_SIZE,BytesToWrite);
       Inc(BlockNum);
       SendChar(ACK);
      End
       Else
      SendChar(NAK);
     End
      Else
     Begin
      ReceiveChar(C, 5);
      If C = EOT Then Begin
       SendChar(ACK);
       Receiving:=False;
      End
       Else
      SendChar(NAK);
     End;
    End;
    Close(F);
    WriteLn('Fichier re‡u et sauvegard‚ sous : ', FileName);
   End
    Else
   Begin
    WriteLn('Erreur : bloc d''en-tˆte non re‡u.');
   End;
  End;
 End;
END.
