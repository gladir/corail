{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program CP;

Var
 P:Byte;
 ShowVerbose:Boolean;
 F:File;
 CurrParam,Source,Target:String;

Function CopyFile(Source,Target:String;ShowProgression:Boolean):Boolean;
Var
 SourceFile,TargetFile:File;
 RecordsRead:Integer;
 Buffer:Array[1..1000]of Byte;
Begin
 CopyFile:=False;
 Assign(SourceFile,Source);
 {$I-}Reset(SourceFile,1);{$I+}
 If IOResult<>0Then Begin
  WriteLn('Fichier source introuvable ',Source);
  Exit;
 End;
 Assign(TargetFile,Target);
 {$I-}Rewrite(TargetFile,1);
 If(ShowProgression)Then WriteLn('. = 1000 octets de copies');
 BlockRead(SourceFile,Buffer,SizeOf(Buffer),RecordsRead);
 While RecordsRead>0 do Begin
  If(ShowProgression)Then Write('.');
  BlockWrite(TargetFile,Buffer,RecordsRead);
  BlockRead(SourceFile,Buffer,SizeOf(Buffer),RecordsRead);
 End;
 If(ShowProgression)Then WriteLn;
 Close(SourceFile);
 Close(TargetFile);
 {$I+}
 CopyFile:=True;
End;

BEGIN
 P:=0;
 ShowVerbose:=False;
 Source:='';
 Target:='';
 Repeat
  Inc(P);
  CurrParam:=ParamStr(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    WriteLn('Paramätre requis');
   End;
   Break;
  End
   Else
  If(CurrParam='-h')or(CurrParam='--help')Then Begin
   WriteLn('cp   Cette commande permet d''effectuer la copie de fichier vers un autre emplacement.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('cp [-h] [-v] source destination');
   WriteLn;
   WriteLn('    -h       Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('    -v       Ce parametre permet d''afficher les details');
   WriteLn('source       Ce parametre permet d''indiquer le fichier source');
   WriteLn('destination  Ce parametre permet d''indiquer le fichier destination');
   Exit;
  End
   Else
  If(CurrParam='-v')Then ShowVerbose:=True
   Else
  If CurrParam<>''Then
  Begin
   If Source=''Then Source:=CurrParam
               Else Target:=CurrParam;
  End;
  If P>9Then Break;
 Until CurrParam='';
 If(Source='')or(Target='')Then Begin
  WriteLn('La source et la destination sont requises');
 End
  Else
 Begin
  If CopyFile(Source,Target,ShowVerbose)Then WriteLn('1 fichier copie')
                                        Else WriteLn('Echec de copie de fichier');
 End;
END.
