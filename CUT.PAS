{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program CUT;

Var
 BMin,BMax,CMin,CMax:Byte;
 Option:Set of (ModeB,ModeC);
 Mode:(_None,_b,_c);
 I,J:Integer;
 Err:Word;
 Handle:Text;
 FileName,CurrLine:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CUT : Cette commande permet de supprimer des sections de chaque ligne des fichiers.');
  WriteLn;
  WriteLn('Syntaxe : CUT fichier -b <byte-list>');
  WriteLn;
  WriteLn(' fichier        Ce paramätre permet d''indiquer le fichier a traiter');
  WriteLn(' -b <byte-list> Ce paramätre permet d''indiquer un intervalle de traitement');
 End
  Else
 If ParamCount>0Then Begin
  Option:=[];
  Mode:=_None;
  FileName:='';
  BMin:=1;BMax:=255;
  CMin:=1;CMax:=255;
  For I:=1 to ParamCount do Begin
   If(Mode=_b)Then Begin
    If Pos('-',ParamStr(I))>0Then Begin
     CurrLine:=ParamStr(I);
     For J:=1 to Length(CurrLine)do Begin
      If CurrLine[J]='-'Then Begin
       Val(Copy(CurrLine,1,J-1),BMin,Err);
       Val(Copy(CurrLine,J+1,255),BMax,Err);
       Break;
      End;
     End;
    End
     Else
    Begin
     Val(ParamStr(I),BMin,Err);
     BMax:=BMin;
    End;
    Mode:=_None;
    Include(Option,ModeB);
   End
    Else
   If(Mode=_c)Then Begin
    If Pos('-',ParamStr(I))>0Then Begin
     CurrLine:=ParamStr(I);
     For J:=1 to Length(CurrLine)do Begin
      If CurrLine[J]='-'Then Begin
       Val(Copy(CurrLine,1,J-1),CMin,Err);
       Val(Copy(CurrLine,J+1,255),CMax,Err);
       Break;
      End;
     End;
    End
     Else
    Begin
     Val(ParamStr(I),CMin,Err);
     CMax:=CMin;
    End;
    Mode:=_None;
    Include(Option,ModeC);
   End
    Else
   If ParamStr(I)='-b'Then Mode:=_b else
   If ParamStr(I)='-c'Then Mode:=_c
                      Else FileName:=ParamStr(I);
  End;
  If FileName<>''Then Begin
   Assign(Handle,FileName);
   {$I-}Reset(Handle);{$I+}
   If IOResult=0Then Begin
    While NOT EOF(Handle)do Begin
     ReadLn(Handle,CurrLine);
     If(ModeB in Option)Then Begin
      For J:=BMin to BMax do Begin
       If J>Length(CurrLine)Then Break;
       Write(CurrLine[J]);
      End;
      WriteLn;
     End
      Else
     If(ModeC in Option)Then Begin
      For J:=CMin to CMax do Begin
       If J>Length(CurrLine)Then Break;
       Write(CurrLine[J]);
      End;
      WriteLn;
     End
      Else
     WriteLn(CurrLine);
    End;
    Close(Handle);
   End
    Else
   WriteLn('Impossible de lire ',ParamStr(I));
  End;
 End
  Else
 WriteLn('Parametre attendu');
END.