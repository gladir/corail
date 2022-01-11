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
 Mode:(_None,_Save,_Restore);
 I,J:Integer;
 ByteReaded:Integer;
 FileName:String;
 Buffer:Array[0..63] of Byte;
 FileCMOS:File{$IFDEF FPC}of Byte{$ENDIF};

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

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('CKCMOS : Cette commande permet de sauvegarder ou restaurer les données du CMOS du système.');
  WriteLn;
  WriteLn('Syntaxe : CMOS nomdufichier /T:action');
  WriteLn;
  WriteLn('           nomdufichier   Le fichier a lire ou modifier');
  WriteLn('           /T:s           Sauvegarde le CMOS dans un fichier');
  WriteLn('           /T:rs          Copie un fichier dans le CMOS');
  WriteLN('           /AMDEK         Utilise l''adresse d''un AMDEK SYSTEM/88');
 End
  Else
 Begin
  Mode:=_None;
  FileName:='';
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='/AMDEK')Then Begin
    RTCAdrPort:=$E0;
	RTCDtaPort:=$E1;
   End 
    Else
   If(ParamStr(I)='/T:s')Then Mode:=_Save Else
   If(ParamStr(I)='/T:rs')Then Mode:=_Restore
                         Else FileName:=ParamStr(I);
  End;
  If FileName=''Then WriteLN('Nom de fichier attendu !')
   Else
  Case Mode Of
   _Save:Begin
    For J:=0 to 63 do Buffer[I]:=CMOSRead(I);
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
    Reset(FileCMOS);{$I+}
    If IOResult<>0Then Begin
     WriteLn('Fichier introuvable ou impossible a lire !');
     Halt;
    End;
    Seek(FileCMOS,0);
    BlockRead(FileCMOS,Buffer,SizeOf(Buffer),ByteReaded);
    Close(FileCMOS);
    For J:=0 to 63 do CMOSWrite(I,Buffer[I]);
   End;
  End;
 End;
END.