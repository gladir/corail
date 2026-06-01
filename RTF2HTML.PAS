{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program RTF2HTML(Input,Output);

Type
 StyleRec=Record
  Bold,Italic,Underline:Boolean;
 End;

Var
 RTFFile:File;
 HTMLFile:Text;
 OutToFile:Boolean;
 C:Char;
 ReadOfs:Word;
 PushChar:Char;
 HasPush:Boolean;
 Level,SkipLevel,UcSkip,SkipChars:Integer;
 PendingIgnorable,InParagraph:Boolean;
 CurStyle:StyleRec;
 StyleStack:Array[0..63]of StyleRec;

Function IntToStr(I:LongInt):String;
Var
 S:String;
Begin
 Str(I,S);
 IntToStr:=S;
End;

Function Lower(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do
  If S[I]in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
 Lower:=S;
End;

Function EvalHex(S:String):Integer;
Var
 I,N,V:Integer;
Begin
 V:=0;
 For I:=1 to Length(S)do Begin
  N:=Pos(UpCase(S[I]),'0123456789ABCDEF');
  If N=0 Then Begin
   EvalHex:=0;
   Exit;
  End;
  V:=V*16+N-1;
 End;
 EvalHex:=V;
End;

Function IsDestination(S:String):Boolean;
Begin
 S:=Lower(S);
 IsDestination:=(S='fonttbl')or(S='colortbl')or(S='stylesheet')or
                (S='info')or(S='pict')or(S='object')or
                (S='header')or(S='footer')or(S='footnote')or
                (S='annotation')or(S='datastore')or(S='filetbl')or
                (S='revtbl')or(S='rsidtbl')or(S='listtable')or
                (S='listoverridetable')or(S='generator')or
                (S='themedata')or(S='xmlnstbl');
End;

Function ReadChar(Var Ch:Char):Boolean;
Begin
 If HasPush Then Begin
  Ch:=PushChar;
  HasPush:=False;
  ReadChar:=True;
 End
  Else
 Begin
  If EOF(RTFFile)Then ReadChar:=False
  Else Begin
   BlockRead(RTFFile,Ch,SizeOf(Ch),ReadOfs);
   ReadChar:=ReadOfs=SizeOf(Ch);
  End;
 End;
End;

Procedure UnreadChar(Ch:Char);
Begin
 PushChar:=Ch;
 HasPush:=True;
End;

Procedure OutS(S:String);
Begin
 If OutToFile Then Write(HTMLFile,S)
              Else Write(S);
End;

Procedure OutLn(S:String);
Begin
 If OutToFile Then WriteLn(HTMLFile,S)
              Else WriteLn(S);
End;

Procedure WriteHTMLChar(Ch:Char);
Begin
 Case Ch of
  '&':OutS('&amp;');
  '<':OutS('&lt;');
  '>':OutS('&gt;');
  '"':OutS('&quot;');
  #160:OutS('&nbsp;');
  Else OutS(Ch);
 End;
End;

Procedure StartParagraph;
Begin
 If Not InParagraph Then Begin
  OutS('<p>');
  InParagraph:=True;
 End;
End;

Procedure EndParagraph;
Begin
 If InParagraph Then Begin
  OutLn('</p>');
  InParagraph:=False;
 End;
End;

Procedure SetBold(B:Boolean);
Begin
 If CurStyle.Bold<>B Then Begin
  If B Then OutS('<strong>')
      Else OutS('</strong>');
  CurStyle.Bold:=B;
 End;
End;

Procedure SetItalic(B:Boolean);
Begin
 If CurStyle.Italic<>B Then Begin
  If B Then OutS('<em>')
      Else OutS('</em>');
  CurStyle.Italic:=B;
 End;
End;

Procedure SetUnderline(B:Boolean);
Begin
 If CurStyle.Underline<>B Then Begin
  If B Then OutS('<u>')
      Else OutS('</u>');
  CurStyle.Underline:=B;
 End;
End;

Procedure SetStyle(S:StyleRec);
Begin
 SetUnderline(S.Underline);
 SetItalic(S.Italic);
 SetBold(S.Bold);
End;

Procedure PlainStyle;
Var
 S:StyleRec;
Begin
 S.Bold:=False;
 S.Italic:=False;
 S.Underline:=False;
 SetStyle(S);
End;

Procedure WriteUnicode(N:LongInt);
Begin
 If N<0 Then N:=N+65536;
 OutS('&#');
 OutS(IntToStr(N));
 OutS(';');
End;

Procedure HandleControl(WordName:String; HasParam:Boolean; Param:LongInt);
Begin
 WordName:=Lower(WordName);
 If PendingIgnorable Then Begin
  SkipLevel:=Level;
  PendingIgnorable:=False;
 End;
 If IsDestination(WordName)Then SkipLevel:=Level;
 If SkipLevel>0 Then Exit;
 StartParagraph;
 If WordName='b'Then Begin
  If HasParam and(Param=0)Then SetBold(False)
                         Else SetBold(True);
 End
  Else
 If WordName='i'Then Begin
  If HasParam and(Param=0)Then SetItalic(False)
                         Else SetItalic(True);
 End
  Else
 If WordName='ul'Then Begin
  If HasParam and(Param=0)Then SetUnderline(False)
                         Else SetUnderline(True);
 End
  Else
 If(WordName='ulnone')Then SetUnderline(False)
  Else
 If(WordName='plain')Then PlainStyle
  Else
 If(WordName='par')Then Begin
  EndParagraph;
  StartParagraph;
 End
  Else
 If(WordName='line')Then OutS('<br>')
  Else
 If(WordName='tab')Then OutS('&nbsp;&nbsp;&nbsp;&nbsp;')
  Else
 If(WordName='emdash')or(WordName='endash')Then OutS('-')
  Else
 If(WordName='lquote')or(WordName='rquote')Then OutS('''')
  Else
 If(WordName='ldblquote')or(WordName='rdblquote')Then OutS('&quot;')
  Else
 If(WordName='bullet')Then OutS('&bull;')
  Else
 If(WordName='u')Then Begin
  If HasParam Then WriteUnicode(Param);
  SkipChars:=UcSkip;
 End;
End;

Procedure ReadControl;
Var
 Ch,C1,C2:Char;
 WordName,NumStr:String;
 HasParam,Neg:Boolean;
 Param:LongInt;
 Code:Integer;
Begin
 If Not ReadChar(Ch)Then Exit;
 Case Ch of
  '\','{','}':Begin
   If SkipLevel=0 Then Begin
    StartParagraph;
    WriteHTMLChar(Ch);
   End;
  End;
  '''':Begin
   If ReadChar(C1)and ReadChar(C2)Then Begin
    If SkipLevel=0 Then Begin
     Code:=EvalHex(C1+C2);
     StartParagraph;
     If Code<128 Then WriteHTMLChar(Chr(Code))
                Else Begin
                 OutS('&#');
                 OutS(IntToStr(Code));
                 OutS(';');
                End;
    End;
   End;
  End;
  '*':PendingIgnorable:=True;
  '~':If SkipLevel=0 Then Begin StartParagraph;OutS('&nbsp;');End;
  '-':If SkipLevel=0 Then Begin StartParagraph;OutS('&shy;');End;
  '_':If SkipLevel=0 Then Begin StartParagraph;OutS('-');End;
  Else Begin
   If Not(Ch in['A'..'Z','a'..'z'])Then Exit;
   WordName:='';
   Repeat
    WordName:=WordName+Ch;
    If Not ReadChar(Ch)Then Break;
   Until Not(Ch in['A'..'Z','a'..'z']);
   HasParam:=False;
   Neg:=False;
   NumStr:='';
   If Ch='-'Then Begin
    Neg:=True;
    If Not ReadChar(Ch)Then Ch:=' ';
   End;
   While Ch in['0'..'9']do Begin
    HasParam:=True;
    NumStr:=NumStr+Ch;
    If Not ReadChar(Ch)Then Break;
   End;
   Param:=0;
   If HasParam Then Begin
    Val(NumStr,Param,Code);
    If Neg Then Param:=-Param;
   End;
   If Ch<>' 'Then UnreadChar(Ch);
   HandleControl(WordName,HasParam,Param);
  End;
 End;
End;

Procedure PrintHeader;
Begin
 OutLn('<!DOCTYPE html>');
 OutLn('<html>');
 OutLn('<head>');
 OutLn('  <meta charset="utf-8">');
 OutLn('  <title>RTF2HTML</title>');
 OutLn('</head>');
 OutLn('<body>');
End;

Procedure PrintFooter;
Begin
 PlainStyle;
 EndParagraph;
 OutLn('</body>');
 OutLn('</html>');
End;

Procedure Convert;
Begin
 CurStyle.Bold:=False;
 CurStyle.Italic:=False;
 CurStyle.Underline:=False;
 FillChar(StyleStack,SizeOf(StyleStack),0);
 HasPush:=False;
 Level:=0;
 SkipLevel:=0;
 UcSkip:=1;
 SkipChars:=0;
 PendingIgnorable:=False;
 InParagraph:=False;
 PrintHeader;
 While ReadChar(C)do Begin
  Case C of
   #0,#10,#13:;
   '{':Begin
    Inc(Level);
    If Level<=High(StyleStack)Then StyleStack[Level]:=CurStyle;
   End;
   '}':Begin
    If SkipLevel=Level Then SkipLevel:=0;
    If Level<=High(StyleStack)Then SetStyle(StyleStack[Level]);
    If Level>0 Then Dec(Level);
    PendingIgnorable:=False;
   End;
   '\':ReadControl;
   Else Begin
    If SkipLevel=0 Then Begin
     If SkipChars>0 Then Dec(SkipChars)
     Else Begin
      StartParagraph;
      WriteHTMLChar(C);
     End;
    End;
   End;
  End;
 End;
 PrintFooter;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('RTF2HTML : Cette commande permet de convertir un fichier RTF ',
                     'en format HTML.');
  WriteLn;
  WriteLn('Syntaxe : RTF2HTML source.rtf [target.html]');
  WriteLn;
  WriteLn(' source.rtf    Nom du fichier '+#133+' convertir');
  WriteLn(' target.html   Nom du fichier du r'+#130+'sultat');
  WriteLn;
 End
  Else
 If ParamCount>0 Then Begin
  {$I-}Assign(RTFFile,ParamStr(1));
  Reset(RTFFile,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de lire le fichier ',ParamStr(1));
   Halt(1);
  End;
  OutToFile:=ParamStr(2)<>'';
  If OutToFile Then Begin
   Assign(HTMLFile,ParamStr(2));
   {$I-}Rewrite(HTMLFile);{$I+}
   If IOResult<>0 Then Begin
    Close(RTFFile);
    WriteLn('Impossible d''ecrire le fichier ',ParamStr(2));
    Halt(2);
   End;
  End;
  Convert;
  If OutToFile Then Close(HTMLFile);
  Close(RTFFile);
 End
  Else
 Begin
  WriteLn('Parametre attendu !');
  Halt(1);
 End;
END.
