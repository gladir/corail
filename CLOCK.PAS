{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7)
}

Program CKCMOS;

Uses DOS;

Const
 RTCAdrPort:Byte=$70;
 RTCDtaPort:Byte=$71;

Var
 Mode:(_None,_Save,_Restore,_ShowClock,_SystemClock,_WriteClock);
 I,J:Integer;
 Heure,Min,Sec,CentSec:Word;
 Annee,Mois,Jour,JourSemaine:Word;

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
  WriteLn('CLOCK : Cette commande permet de manipuler l''heure du CMOS.');
  WriteLn;
  WriteLn('Syntaxe : CLOCK -r');
  WriteLn;
  WriteLn('   -amdek    Utilise l''adresse d''un AMDEK SYSTEM/88');
  WriteLn('   -r        Affiche l''heure contenu dans le CMOS');
  WriteLn('   -s        Ecrit l''heure CMOS dans le systäme d''exploitation');
  WriteLn('   -w        Ecrit l''heure du systäme d''exploitation dans le CMOS');
 End
  Else
 Begin
  Mode:=_None;
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='-amdek')Then Begin
    RTCAdrPort:=$E0;
    RTCDtaPort:=$E1;
   End
    Else
   If(ParamStr(I)='-r')Then Mode:=_ShowClock Else
   If(ParamStr(I)='-s')Then Mode:=_SystemClock Else
   If(ParamStr(I)='-w')Then Mode:=_WriteClock
    Else
   Begin
    WriteLn('Paramätre non reconnu');
    Halt;
   End;
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
  Case Mode Of
   _SystemClock:Begin
    SetDate(RTCDT($09),RTCDT($08),RTCDT($07));
    SetTime(RTCDT($04),RTCDT($02),RTCDT($00),0);
   End;
   _WriteClock:Begin
    GetTime(Heure,Min,Sec,CentSec);
    CMOSWrite($04,Heure);
    CMOSWrite($02,Min);
    CMOSWrite($00,Sec);
    GetDate(Annee,Mois,Jour,JourSemaine);
    CMOSWrite($09,Annee);
    CMOSWrite($08,Mois);
    CMOSWrite($07,Jour);
   End;
   Else WriteLn('Paramätre attendu.');
  End;
 End;
END.