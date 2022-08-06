{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program VT100;

Uses Crt;

Var
 Mode:(CursorAbsolute,CursorRelatif);
 SpecialChar:Boolean;
 FileSource:Text;
 S:String;
 Old:Byte;
 OldX,OldY:Array[0..255]of Byte;

Procedure PushCursor;Begin
 OldX[Old]:=WhereX;
 OldY[Old]:=WhereY;
 Inc(Old);
End;

Procedure PopCursor;Begin
 If Old>0Then Dec(Old);
 GotoXY(OldX[Old],OldY[Old]);
End;

Procedure ShowVT100(S:String);
Var
 I,J:Byte;
 N1,N2:String;
 V1,V2:Integer;
 Err:Word;
 Question:Boolean;
Begin
 I:=1;
 Question:=False;
 While(I<=Length(S))do Begin
  Case S[I]of
   #27:Begin
    Inc(I);
    Case S[I]of
     '(':Begin
      Inc(I);
      Case S[I]of
       'B':SpecialChar:=True;
      End;
     End;
     '[':Begin
      Inc(I);
      V1:=-1;
      V2:=-1;
      N1:='';
      N2:='';
      If S[I]='?'Then Begin
       Question:=True;
       Inc(I);
      End
       Else
      Question:=False;
      While S[I]in['0'..'9']do Begin
       N1:=N1+S[I];
       Inc(I);
      End;
      If N1<>''Then Val(N1,V1,Err);
      If S[I]=';'Then Begin
       Inc(I);
       While S[I]in['0'..'9']do Begin
        N2:=N2+S[I];
        Inc(I);
       End;
      End;
      If N2<>''Then Val(N2,V2,Err);
      Case S[I]of
       'A':Begin
        If N1=''Then GotoXY(WhereX,WhereY-1)
                Else GotoXY(WhereX,WhereY-V1);
       End;
       'B':Begin
        If N1=''Then GotoXY(WhereX,WhereY+1)
                Else GotoXY(WhereX,WhereY+V1);
       End;
       'C':Begin
        If N1=''Then GotoXY(WhereX+1,WhereY)
                Else GotoXY(WhereX+V1,WhereY);
       End;
       'D':Begin
        If N1=''Then GotoXY(WhereX-1,WhereY)
                Else GotoXY(WhereX-V1,WhereY);
       End;
       'H':Begin
        If(N1<>'')and(N2<>'')Then Begin
         If(Mode=CursorRelatif)Then GotoXY(WhereX+V2,WhereY+V1)
                               Else GotoXY(V2,V1);
        End
         Else
        GotoXY(1,1);
       End;
       'J':Begin
        If N1<>''Then Case V1 of
         0:Begin
          V1:=WhereX;
          V2:=WhereY;
          For J:=V2 to 25 do Begin
           GotoXY(V1,J);
           ClrEol;
          End;
          GotoXY(V1,V2);
         End;
         1:Begin
          V1:=WhereX;
          V2:=WhereY;
          For J:=1 to V2 do Begin
           GotoXY(V1,J);
           ClrEol;
          End;
          GotoXY(V1,V2);
         End;
         2:ClrScr;
        End;
       End;
       'K':Begin
        If N1<>''Then Case V1 of
         0:ClrEol;
         1:Begin
          V2:=WhereX;
          GotoXY(1,WhereY);
          Write(' ':V2);
          GotoXY(V2,WhereY);
         End;
        End
         Else
        ClrEol;
       End;
       'f':Begin
        If(N1<>'')and(N2<>'')Then Begin
         If(Mode=CursorRelatif)Then GotoXY(WhereX+V2,WhereY+V1)
                               Else GotoXY(V2,V1);
        End
         Else
        GotoXY(1,1);
       End;
       'h':Begin
        If N1<>''Then Case V1 of
         6:Mode:=CursorRelatif;
        End;
       End;
       'l':Begin
        If N1<>''Then Case V1 of
         6:Mode:=CursorAbsolute;
        End;
       End;
       'm':Begin
        If N1<>''Then Case V1 of
         0:Begin
          TextColor(7);
          TextBackground(0);
         End;
         1:HighVideo;
         2:LowVideo;
         5:TextColor((TextAttr and $F)+BLINK);
         7:Begin
          V2:=TextAttr;
          TextColor(V2 shr 4);
          TextBackground(V2 and $F);
         End;
         8:TextColor(TextAttr shr 4);
         30..37:TextColor(V1-30);
         40..48:TextBackground(V1-40);
        End;
       End;
       'r':Begin
        If(N1<>'')and(N2<>'')Then Window(1,V1,80,V2);
       End;
      End;
     End; { Fin de '[' }
     '7':PushCursor;
     '8':PopCursor;
     'D':DelLine;
     'E':WriteLn;
     'M':InsLine;
     's':PushCursor;
     'u':PopCursor;
    End;
   End;
   Else Begin
    If(SpecialChar)and(S[I]in[#95..#126])Then Begin
      {$IFDEF FPC}
       {$IFDEF WINDOWS}
        SetUseACP(False);
       {$ENDIF}
     {$ENDIF}
     Case S[I]of { Code ASCII IBM PC }
      #103:Write(#241);
      #106:Write(#217);
      #107:Write(#191);
      #108:Write(#218);
      #109:Write(#192);
      #110:Write(#197);
      #111,#112,#113,#114,#115:Write(#196);
      #116:Write(#195);
      #117:Write(#180);
      #118:Write(#193);
      #119:Write(#194);
      #120:Write(#179);
      #121:Write(#243);
      #122:Write(#242);
      #123:Write(#227);
      Else Write(S[I]);
     End;
     {$IFDEF FPC}
      {$IFDEF WINDOWS}
       SetUseACP(True);
      {$ENDIF}
     {$ENDIF}
    End
     Else
    Write(S[I]);
   End;
  End;
  Inc(I);
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('VT100 : Cette commande permet d''afficher le contenu de terminal VT100.');
  WriteLn;
  WriteLn('Syntaxe : VT100 fichier');
  WriteLn;
  WriteLn(' fichier           Nom du fichier a afficher');
  WriteLn;
 End
  Else
 If ParamCount>0Then Begin
  Old:=0;
  Mode:=CursorAbsolute;
  SpecialChar:=False;
  Assign(FileSource,ParamStr(1));
  Reset(FileSource);
  While Not EOF(FileSource)do Begin
   ReadLn(FileSource,S);
   ShowVT100(S);
  End;
  Close(FileSource);
 End;
END.