{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program NL;

Var
 Mode:(_None,_Inc,_Start,_SepLine,_Number,_Width);
 LineMode:(_ln,_rn,_rz);
 SourceFile:Text;
 FileName,CurrLine,SepLine:String;
 IncLine,LineNumber:LongInt;
 WidthNumber:Word;
 I:Integer;
 Err:Word;

Function PadRight(Value:Integer;Space:Byte):String;
Var
 I:Byte;
 S:String;
Begin
 Str(Value,S);
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('NL : Cette commande permet d''afficher du texte avec des ',
                'num‚ros de ligne.');
  WriteLn;
  WriteLn('Syntaxe : NL fichier [parametres]');
  WriteLn;
  WriteLn(' fichier        Nom du fichier … visualiser');
  WriteLn(' -i             Incr‚mentation en chaque ligne');
  WriteLn(' -n [ln|rn|rz]  Format du num‚ro de ligne');
  WriteLn(' -s             S‚parateur entre le num‚ro de ligne et la ligne');
  WriteLn(' -v             Num‚ro de ligne de d‚but');
  WriteLn(' -w             Largeur d''un num‚ro de ligne');
  WriteLn;
 End
  Else
 Begin
  Mode:=_None;
  LineMode:=_rn;
  SepLine:='  ';
  WidthNumber:=6;
  IncLine:=1;
  LineNumber:=1;
  For I:=1 to ParamCount do Begin
   Case(Mode)of
    _Inc:Begin
     Val(ParamStr(I),IncLine,Err);
     Mode:=_None;
    End;
    _Number:Begin
     If ParamStr(I)='ln'Then LineMode:=_ln Else
     If ParamStr(I)='rn'Then LineMode:=_rn Else
     If ParamStr(I)='rz'Then LineMode:=_rz;
     Mode:=_None;
    End;
    _SepLine:Begin
     SepLine:=ParamStr(I);
     Mode:=_None;
    End;
    _Start:Begin
     Val(ParamStr(I),LineNumber,Err);
     Mode:=_None;
    End;
    _Width:Begin
     Val(ParamStr(I),WidthNumber,Err);
     Mode:=_None;
    End;
    Else Begin
     If ParamStr(I)='-w'Then Mode:=_Width Else
     If(ParamStr(I)='-v')or
       (ParamStr(I)='--starting-line-number')Then Mode:=_Start Else
     If(ParamStr(I)='-s')or
       (ParamStr(I)='--number-separator')Then Mode:=_SepLine Else
     If ParamStr(I)='-n'Then Mode:=_Number Else
     If ParamStr(I)='-i'Then Mode:=_Inc Else
     If(Copy(ParamStr(I),1,Length('--number-separator='))='--number-separator=')Then Begin
      SepLine:=Copy(ParamStr(I),Length('--number-separator=')+1,255);
     End
      Else
     If(Copy(ParamStr(I),1,Length('--starting-line-number='))='--starting-line-number=')Then Begin
      Val(Copy(ParamStr(I),Length('--starting-line-number=')+1,255),LineNumber,Err);
     End
      Else
     FileName:=ParamStr(I);
    End;
   End;
  End;
  {$I-}Assign(SourceFile,FileName);
  Reset(SourceFile);{$I-}
  While Not EOF(SourceFile)do Begin
   ReadLn(SourceFile,CurrLine);
   Case LineMode of
    _ln: Write(PadRight(LineNumber,WidthNumber));
    _rz: Write(PadZeroLeft(LineNumber,WidthNumber));
    Else Write(LineNumber:WidthNumber);
   End;
   WriteLn(SepLine,CurrLine);
   Inc(LineNumber,IncLine);
  End;
  Close(SourceFile);
 End;
END.