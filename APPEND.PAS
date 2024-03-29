{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program _APPEND;

Uses DOS;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Var
 Language:(_Albanian,_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 Source,Dest:Text;
 CurrLine:String;
 Regs:Registers;
 I:Integer;
 C:Char;

BEGIN
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='SQ')or
    (StrToUpper(Copy(TmpLanguage,1,3))='ALB')Then Language:=_Albanian;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  Case Language of
   _Albanian:Begin
    WriteLn('APPEND : Kjo komand� ju lejon t� hapni dosje t� vendosura n� repertor� te ',
                     'specifikuar sikur t� ishte repertori aktual.');
    WriteLn;
    WriteLn('Sintaksa: APPEND [/E] [/PATH:ON|OFF] [/X:ON|OFF]');
    WriteLn;
    WriteLn(' /E         Duhet t� lidhni list�n e repertor�ve me nj� variab�l t� ',
                         'quajtur "APPEND"');
    WriteLn(' /PATH:OFF  Mos k�rkoni n� list�n e repertor�ve t� shtuara kur k�rkoni ',
                         'dosje t� dh�nash.');
    WriteLn(' /PATH:ON   Duhet t� k�rkoni n�p�r list�n e repertor�ve t� shtuara ',
                         'kur k�rkoni dosje t� dh�nash.');
    WriteLn(' /X:OFF     Mos k�rkoni n� list�n e repertor�ve t� shtuara kur ',
                         'ekzekutoni nj� program.');
    WriteLn(' /X:ON      Duhet t� k�rkoni t� k�rkoni n� list�n e repertor�ve ',
                         't� shtuara gjat� ekzekutimit t� nj� programi.');
   End;
   _English:Begin
    WriteLn('FUNCTION 1 : TRSDOS');
    WriteLn('-------------------');
    WriteLn('APPEND : This command lets you append (add) one file ',
            'onto the end of another. This is primarly useful with ',
            'data files.');
    WriteLn;
    WriteLn('APPEND file-1 TO file-2');
    WriteLn;
    WriteLn('FUNCTION 2 : MS-DOS/PC-DOS');
    WriteLn('--------------------------');
    WriteLn('APPEND : Allows programs to open data files in specified ',
            'directories as if they were in the current directory.');
    WriteLn;
    WriteLn('Syntax : APPEND [/E] [/PATH:ON|OFF] [/X:ON|OFF]');
    WriteLn;
    WriteLn(' /E         Stores a copy of the appended directory list in an environment');
    WriteLn('            variable named APPEND. /E may by used only the first time');
    WriteLn('            you use APPEND after starting your system.');
    WriteLn(' /PATH:ON   Applies appended directories to file requests that already');
    WriteLn('            specify a path.  /PATH:ON is the default setting.');
    WriteLn(' /PATH:OFF  Turns off the effect of /PATH:ON.');
    WriteLn(' /X:OFF     Applies appended directories to file requests to open files.');
    WriteLn('            /X:OFF is the default setting.');
    WriteLn(' /X:ON      Applies appended directories to file searches and');
    WriteLn('            application execution.');
   End;
   Else Begin
    WriteLn('FONCTION 1 : TRSDOS');
    WriteLn('-------------------');
    WriteLn('APPEND : Cette commande permet d''ajouter un fichier ASCII � un autre fichier.');
    WriteLn;
    WriteLn('Syntaxe : APPEND fichieraajouter TO fichierdest');
    WriteLn;
    WriteLn('FONCTION 2 : MS-DOS/PC-DOS');
    WriteLn('--------------------------');
    WriteLn('APPEND : Cette commande permet d''ouvrir des fichiers ',
                 'quelques se trouvant dans les r�pertoires sp�cifi�s ',
           'comme s''il s''agissait du r�pertoire courant.');
    WriteLn;
    WriteLn('Syntaxe : APPEND [/E] [/PATH:ON|OFF] [/X:ON|OFF]');
    WriteLn;
    WriteLn(' /E         Il faut associ� la liste des r�pertoires � une variable');
    WriteLn('            d''environnement se nommant �APPEND�.');
    WriteLn(' /PATH:OFF  Il ne faut pas rechercher dans la liste des r�pertoires');
    WriteLn('            ajout�s lors de la recherche de fichiers de donn�es.');
    WriteLn(' /PATH:ON   Il faut rechercher dans la liste des r�pertoires ajout�s');
    WriteLn('            lors de la recherche de fichiers de donn�es.');
    WriteLn(' /X:OFF     Il ne faut pas rechercher dans la liste des r�pertoires');
    WriteLn('            ajout�s lors de l''ex�cution d''un programme.');
    WriteLn(' /X:ON      Il faut rechercher dans la liste des r�pertoires ajout�s');
    WriteLn('            lors de l''ex�cution d''un programme.');
   End;
  End;
 End
  Else
 If(ParamStr(2)='TO')or(ParamStr(2)='to')Then Begin
  Assign(Source,ParamStr(1));
  Reset(Source);
  Assign(Dest,ParamStr(3));
  Append(Dest);
  While Not EOF(Source)do Begin
   ReadLn(Source,CurrLine);
   WriteLn(Dest,CurrLine);
  End;
  Close(Dest);
  Close(Source);
 End
  Else
 If ParamCount>0 Then Begin
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/E'Then Begin
    Regs.AX:=$B700;
    Intr($2F,Regs);
    Regs.AX:=$B707;
    Regs.BX:=Regs.BX or (1 shl 14);
    Intr($2F,Regs);
   End
    Else
   If StrToUpper(ParamStr(I))='/PATH:OFF'Then Begin
    Regs.AX:=$B700;
    Intr($2F,Regs);
    Regs.AX:=$B707;
    Regs.BX:=Regs.BX and Not(1 shl 13);
    Intr($2F,Regs);
   End
    Else
   If StrToUpper(ParamStr(I))='/PATH:ON'Then Begin
    Regs.AX:=$B700;
    Intr($2F,Regs);
    Regs.AX:=$B707;
    Regs.BX:=Regs.BX or (1 shl 13);
    Intr($2F,Regs);
   End
    Else
   If StrToUpper(ParamStr(I))='/X:OFF'Then Begin
    Regs.AX:=$B700;
    Intr($2F,Regs);
    Regs.AX:=$B707;
    Regs.BX:=Regs.BX and Not(1 shl 15);
    Intr($2F,Regs);
   End
    Else
   If StrToUpper(ParamStr(I))='/X:ON'Then Begin
    Regs.AX:=$B700;
    Intr($2F,Regs);
    Regs.AX:=$B707;
    Regs.BX:=Regs.BX or (1 shl 15);
    Intr($2F,Regs);
   End
    Else
   Begin
    WriteLn('Le param�tre ',ParamStr(I),' n''est pas reconnu.');
    Halt;
   End;
  End;
 End
  Else
 Begin
  Regs.AX:=$B704;
  Intr($2F,Regs);
  If(Regs.ES=0)and(Regs.DI=0)Then Begin
   WriteLn('Aucun chemin de recherche pour APPEND');
  End
   Else
  Begin
   {$IFNDEF FPC}
    I:=0;
    Repeat
     C:=Char(Mem[Regs.ES:Regs.DI+I]);
     Write(C);
     Inc(I);
    Until C=#0;
   {$ENDIF}
   WriteLn;
  End;
 End;
END.
