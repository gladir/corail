{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program GETTEXT;

Uses DOS;

Var
 I:Integer;
 TextDomainDir,FileName,MsgId,MsgStr:String;

Function FileExist(Name:String):Boolean;
Var
 Rec:SearchRec;
Begin
 FindFirst(Name,AnyFile,Rec);
 FileExist:=DosError=0;
End;

Function FindText(FileName,MsgId:String;Var MsgStr:String):Boolean;
Var
 POFile:Text;
 CurrLine,CurrMsgId:String;
Begin
 FindText:=False;
 {$I-}Assign(POFile,FileName);
 Reset(POFile);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Fichier PO introuvable : ',FileName);
  Halt(1);
 End;
 CurrMsgId:='';
 While Not EOF(POFile)do Begin
  ReadLn(POFile,CurrLine);
  If Copy(CurrLine,1,Length('msgid '))='msgid 'Then Begin
   CurrMsgId:=Copy(CurrLine,Length('msgid ')+1,255);
   If(Copy(CurrMsgId,1,1)='"')and(Copy(CurrMsgId,Length(CurrMsgId),1)='"')Then Begin
    CurrMsgId:=Copy(CurrMsgId,2,Length(CurrMsgId)-2);
   End;
  End
   Else
  If Copy(CurrLine,1,Length('msgstr '))='msgstr 'Then Begin
   If(CurrMsgId=MsgId)Then Begin
    MsgStr:=Copy(CurrLine,Length('msgstr ')+1,255);
    If (Copy(MsgStr,1,1)='"')and(Copy(MsgStr,Length(MsgStr),1)='"')Then Begin
     MsgStr:=Copy(MsgStr,2,Length(MsgStr)-2);
    End;
    FindText:=True;
    Exit;
   End;
  End;
 End;
 Close(POFile);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('GETTEXT : Cette commande permet d''afficher les ',
                    'traductions de langages humains natif ',
                    'dans un message textuel.');
  WriteLn;
  WriteLn('Syntaxe : GETTEXT [option] [[textdomain] msgid]');
  WriteLn;
  WriteLn(' msgid                 Indique le MsgId');
  WriteLn(' -h                    Affiche l''aide de cette commande');
  WriteLn(' -V                    Affiche la version de cette commande.');
  WriteLn(' --domain=textdomain   Indique le nom du domain (gÇnÇralement un fichier .PO)');
  WriteLn(' --help                Affiche l''aide de cette commande');
  WriteLn(' --version             Affiche la version de cette commande.');
 End
  Else
 If(ParamStr(1)='--version')or(ParamStr(1)='-V')Then Begin
  WriteLn('GETTEXT 1.0 - Clone Pascal de freebsd, linux ou corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('êcrit par Sylvain Maltais');
 End
  Else
 Begin
  FileName:='';
  MsgId:='';
  For I:=1 to ParamCount do Begin
   If Copy(ParamStr(I),1,Length('--domain='))='--domain='Then Begin
    FileName:=Copy(ParamStr(I),Length('--domain=')+1,255);
   End
    Else
   If FileName=''Then FileName:=ParamStr(I)
                 Else MsgId:=ParamStr(I);
  End;
  If Not FileExist(FileName)Then Begin
   TextDomainDir:=GetEnv('TEXTDOMAINDIR');
   If TextDomainDir<>''Then Begin
    If TextDomainDir[Length(TextDomainDir)]<>'\'Then TextDomainDir:=TextDomainDir+'\';
    FileName:=TextDomainDir+FileName;
   End;
  End;
  If FindText(FileName,MsgId,MsgStr)Then Begin
   WriteLn(MsgStr);
  End
   ELse
  WriteLn(MsgId);
 End;
END.