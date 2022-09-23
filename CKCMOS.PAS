{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal)
}

Program CKCMOS;

Const
 RTCAdrPort:Byte=$70;
 RTCDtaPort:Byte=$71;

Var
 Mode:(_None,_Save,_Restore,_ShowClock);
 I,J:Integer;
 ByteReaded:Integer;
 FileName:String;
 Buffer:Array[0..63] of Byte;
 FileCMOS:File{$IFDEF FPC}of Byte{$ENDIF};

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function CMOSRead(Address:Integer):Integer;Begin
 If Address in [0..63]Then Begin
   Port[RTCAdrPort]:=Address;
   CMOSRead:=Port[RTCDtaPort]
 End
  Else
 CMOSRead:=-1;
End;

Procedure CMOSWrite(Address:Integer;Value:Byte);Begin
 Port[RTCAdrPort]:=Address;
 Port[RTCDtaPort]:=Value;
End;

Function RTCDT(Address:Integer):Integer;
Var
 Value:Integer;
Begin
 Value:=CMOSRead(Address);
 If(CMOSRead($0B) and 4 = 4)Then RTCDT:=Value
                            Else RTCDT:=(Value shr 4) * 10 + Value and 15;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('CKCMOS : Cette commande permet de sauvegarder ou restaurer les données du CMOS du système.');
  WriteLn;
  WriteLn('Syntaxe : CKCMOS nomdufichier /T:action');
  WriteLN('          CKCMOS /SHOWCLOCK');
  WriteLn;
  WriteLn('           nomdufichier   Le fichier a lire ou modifier');
  WriteLn('           /T:s           Sauvegarde le CMOS dans un fichier');
  WriteLn('           /T:rs          Copie un fichier dans le CMOS');
  WriteLn('           /AMDEK         Utilise l''adresse d''un AMDEK SYSTEM/88');
  WriteLn('           /SHOWCLOCK     Affiche l''heure contenu dans le CMOS');
 End
  Else
 Begin
  Mode:=_None;
  FileName:='';
  For I:=1 to ParamCount do Begin
   If(StrToUpper(ParamStr(I))='/AMDEK')Then Begin
    RTCAdrPort:=$E0;
	RTCDtaPort:=$E1;
   End
    Else
   If(StrToUpper(ParamStr(I))='/SHOWCLOCK')Then Mode:=_ShowClock;
   If(ParamStr(I)='/T:s')Then Mode:=_Save Else
   If(ParamStr(I)='/T:rs')Then Mode:=_Restore
                         Else FileName:=ParamStr(I);
  End;
  If(Mode=_ShowClock)Then Begin
   If CMOSRead($0E) and 128 = 0 Then Begin
    WriteLn('L''horloge est exploitee en mode ',(CMOSRead($0B) and 2)*6+12,' heures');
    WriteLn('Il est : ', RTCDT($04), ':', RTCDT($02):2,':', RTCDT($00):2);
    WriteLn('Nous sommes le : ',RTCDT($32), RTCDT($09),'-',RTCDT($08),'-',RTCDT($07));
   end
    Else
   WriteLn('ATTENTION ! Impossible de connaitre l''heure. Les piles de l''horloge sont vides');
  End
   Else
  If FileName=''Then WriteLN('Nom de fichier attendu !')
   Else
  Case Mode Of
   _Save:Begin
    For J:=0 to 63 do Buffer[J]:=CMOSRead(J);
	Assign(FileCMOS,FileName);
    {$I-}ReWrite(FileCMOS,1);{$I+}
    If IOResult<>0Then Begin
     WriteLn('Fichier introuvable ou impossible a ecrire !');
     Halt;
    End;	
	{$I-}Seek(FileCMOS,0);
	BlockWrite(FileCMOS,Buffer,64);{$I+}
    If IOResult<>0 Then Begin
     WriteLn('Impossible d''ecrire le fichier');
     Halt;
    End;
   End;
   _Restore:Begin
    {$I-}Assign(FileCMOS,FileName);
    Reset(FileCMOS,1);{$I+}
    If IOResult<>0Then Begin
     WriteLn('Fichier introuvable ou impossible a lire !');
     Halt;
    End;
    Seek(FileCMOS,0);
    BlockRead(FileCMOS,Buffer,SizeOf(Buffer),ByteReaded);
    Close(FileCMOS);
    For J:=0 to 63 do CMOSWrite(J,Buffer[J]);
   End;
  End;
 End;
END.
