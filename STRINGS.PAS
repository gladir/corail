{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal, Turbo Pascal)
}

Program STRINGS;

Var
 Option:Set of (_Octal,_PrintFileName);
 FileStrings:File;
 MinLength:Integer;
 ByteReaded,Err:Word;
 C:Char;
 I:Integer;
 Pos:LongInt;
 {DirInfo:SearchRec;}
 OutputSeparator:String;
 FileName,CurrString:String;

Function OctLong2Str(value:LongInt):String;
Const
 matrix:Array[0..7]of Char = ('0','1','2','3','4','5','6','7');
Begin
 OctLong2Str:=matrix[(value shr 30) and 7]+
              matrix[(value shr 27) and 7]+
              matrix[(value shr 24) and 7]+
              matrix[(value shr 21) and 7]+
              matrix[(value shr 18) and 7]+
              matrix[(value shr 15) and 7]+
              matrix[(value shr 12) and 7]+
              matrix[(value shr 9) and 7]+
              matrix[(value shr 6) and 7]+
              matrix[(value shr 3) and 7]+
              matrix[value and 7];
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('STRINGS : Cette commande permet de trouver les chaŒnes de ',
                  'caractŠres affichable dans un objet ou un autre ',
                  'fichier binaire.');
  WriteLn;
  WriteLn('Syntaxe : STRINGS [option(s)] fichier');
  WriteLn;
  WriteLn(' fichier                     Fichier binaire … examiner');
  WriteLn(' -<nombre>                   Indique le nombre minimum d''un mot');
  WriteLn('                             (Valeur par d‚faut : 4).');
  WriteLn(' -o                          Pr‚c‚der par un d‚placement (en octal)');
  WriteLn(' --help                      Affiche l''aide de cette commande');
  WriteLn(' --output-separator=<chaine> S‚parateur entre chaque chaŒne de caractŠres');
  WriteLn(' --print-file-name           Affiche le nom du fichier avant le d‚placement');
  WriteLn(' --version          Demande la version de la commande');
  WriteLn;
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('STRINGS 1.0 - Clone Pascal de Corail, linux ou unicos');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('crit par Sylvain Maltais');
 End
  Else
 Begin
  Option:=[];
  MinLength:=4;
  FileName:='';
  OutputSeparator:=#13#10;
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='-o'Then Include(Option,_Octal) Else
   If Copy(ParamStr(I),1,Length('--output-separator='))='--output-separator='Then Begin
    OutputSeparator:=Copy(ParamStr(I),Length('--output-separator=')+1,255);
   End
    Else
   If ParamStr(I)='--print-file-name'Then Include(Option,_PrintFileName) Else
   If Copy(ParamStr(I),1,1)='-'Then Begin
    Val(Copy(ParamStr(I),2,255),MinLength,Err);
    If Err>0 Then Begin
     WriteLn('Longueur minimal invalide !');
     Halt(2);
    End;
   End
    Else
   FileName:=ParamStr(I);
  End;
  {Findfirst(FileName,Archive+ReadOnly+Hidden+SysFile+Directory,Dirinfo);
  While DOSError=0 do Begin}
   {$I-}Assign(FileStrings,FileName);
   Reset(FileStrings,1);{$I+}
   If IOResult<>0 Then Begin
    WriteLn('Impossible de lire le fichier ',FileName);
    Halt(1);
   End;
   Pos:=0;
   CurrString:='';
   While Not EOF(FileStrings)do Begin
    BlockRead(FileStrings,C,1,ByteReaded);
    If ByteReaded=0 Then Break;
     If(C<#32)or(C>#154)Then Begin
     If CurrString<>''Then Begin
      If Length(CurrString)>=MinLength Then Begin
       If(_PrintFileName)in(Option)Then Write(FileName,':');
       If(_Octal)in(Option)Then Write(OctLong2Str(Word(Pos-Length(CurrString)+1)),' ');
        Write(CurrString);
       Write(OutputSeparator);
      End;
     End;
     CurrString:='';
    End
     Else
    CurrString:=CurrString+C;
    Inc(Pos);
   End;
   Close(FileStrings);
   {FindNext(DirInfo);}
  {End;}
 End;
END.
