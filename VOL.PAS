{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program VOL;

Uses DOS;

Var
 FileIMG:File;
 FirstParam,Volume:String;
 I:Byte;
 ByteReaded:Integer;
 Buffer:Array[0..511]of Byte;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function GetCurrentDisk:Char;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 GetCurrentDisk:=CurrentDir[1];
End;

Function GetDiskLabel(Dsk:Byte):String;
Var
 Info:SearchRec;
 CurrentDir:String;
Begin
 If Dsk=0Then GetDir(0,CurrentDir)
         Else CurrentDir:=Char(Dsk+64);
 FindFirst(CurrentDir[1]+':\*.*',VolumeID,Info);
 While DosError=0do Begin
  If(Info.Attr = VolumeID)Then Begin
   GetDiskLabel:=Info.Name;
   Exit;
  End;
  FindNext(Info);
 End;
 GetDiskLabel:=''
End;

Procedure InvalidParam(P:Byte);Begin
 WriteLn('Le parametre suivant est invalide : ',ParamStr(P));
End;

BEGIN
 FirstParam:=ParamStr(1);
 If FirstParam='/?'Then Begin
  WriteLn('VOL   Cette commande permet d''afficher le nom du volume d''une unit‚ de disque.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('VOL [/?] [unite:]');
  WriteLn('VOL [/IMG:fichier]');
  WriteLn;
  WriteLn(' /?           Ce paramŠtre permet d''afficher l''aide sur cette commande');
  WriteLn(' unite:       Ce paramŠtre permet d''indiquer la lettre d''unit‚ de disque');
  WriteLn(' /IMG:fichier Ce paramŠtre permet de v‚rifier dans une image disque le nom');
 End
  Else
 If StrToUpper(Copy(FirstParam,1,5))='/IMG:'Then Begin
  {$I-}Assign(FileIMG,Copy(FirstParam,6,255));
  Reset(FileIMG,1);{$I+}
  If IoResult=0 Then Begin
   Seek(FileIMG,0);
   BlockRead(FileIMG,Buffer,SizeOf(Buffer),ByteReaded);
   If ByteReaded=SizeOf(Buffer) Then Begin
    If Buffer[$2B]<32 Then Begin
     For I:=1 to 11 do Write(Char(Buffer[$2B+I]));
    End
     Else
    Begin
     For I:=0 to 10 do Write(Char(Buffer[$2B+I]));
    End;
   End
    Else
   Write('Erreur de lecture du fichier d''image.');
   WriteLn;
   Close(FileIMG);
  End
   Else
  WriteLn('Impossible de lire le fichier d''image : ',Copy(FirstParam,6,255),'!');
 End
  Else
 If(Length(FirstParam)=2) and (FirstParam[2]=':')Then Begin
  If FirstParam[2]=':'Then Begin
   Write('Le volume de l''unit‚ ',UpCase(FirstParam[1]));
   Volume:=GetDiskLabel(Byte(UpCase(FirstParam[1]))-64);
   If Length(Volume)=0Then WriteLn(' n''a pas d''‚tiquette')
                      Else WriteLn(Volume);
  End
   Else
  InvalidParam(1);
 End
  Else
 If Length(FirstParam)>0Then Begin
  InvalidParam(1);
 End
  Else
 Begin
   Write('Le volume de l''unit‚ ',GetCurrentDisk);
   Volume:=GetDiskLabel(0);
   If Length(Volume)=0Then WriteLn(' n''a pas d''‚tiquette')
                      Else WriteLn(Volume);
 End;
END.
