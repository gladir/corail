{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BEAUTIFY;

Var
 SourceJSON:File;
 LastChar,CurrChar:Char;
 Spacing,ReadedByte:Word;
 Ident:Integer;
 InString:Boolean;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BEAUTIFY : Cette commande permet de rendre lisible le formatage ',
                    ' d''un fichier de format JSON.');
  WriteLn;
  WriteLn('Syntaxe : BEAUTIFY nomdufichier.JSON');
  WriteLn;
  WriteLn(' nomdufichier   Ce paramŠtre permet d''indiquer le nom du fichier JSON.');
 End
  Else
 If ParamCount>0Then Begin
  Spacing:=2;
  {$I-}Assign(SourceJSON,ParamStr(1));
  Reset(SourceJSON,1);{$I+}
  If IOResult=0Then Begin
   Ident:=0;
   InString:=False;
   LastChar:=#0;
   While Not(EOF(SourceJSON))do Begin
    BlockRead(SourceJSON,CurrChar,1,ReadedByte);
    If(InString)Then Begin
     If(LastChar='\')and(CurrChar='"')Then Begin
      { Ne rien faire }
     End
      Else
     If CurrChar='"'Then InString:=False;
     Write(CurrChar);
    End
     Else
    Begin
     If LastChar='}'Then Begin
      If CurrChar<>','Then Begin
       WriteLn;
       WriteLn(' ':Ident*Spacing,'}');
       Write(' ':Ident*Spacing);
      End
       Else
      Write('}');
     End;
     Case CurrChar of
      '"':Begin
       InString:=True;
       Write('"');
      End;
      '{':Begin
       WriteLn('{');
       Inc(Ident);
       Write(' ':Ident*Spacing);
      End;
      '}':Begin
       If Ident>0 Then Dec(Ident);
      End;
      '[':Begin
       WriteLn('[');
       Inc(Ident);
       Write(' ':Ident*Spacing);
      End;
      ']':Begin
       WriteLn(']');
       If Ident>0 Then Dec(Ident);
       Write(' ':Ident*Spacing);
      End;
      ':':Write(': ');
      ',':Begin
       WriteLn(',');
       Write(' ':Ident*Spacing);
      End;
      #13:WriteLn;
      #10:WriteLn;
      Else Write(CurrChar);
     End;
    End;
    LastChar:=CurrChar;
   End;
   Close(SourceJSON);
  End;
 End;
END.