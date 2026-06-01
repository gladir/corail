{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program HTML2RTF(Input,Output);

Type
 StyleRec=Record
  Bold,Italic,Underline:Boolean;
 End;

Var
 SourceHTML:File;
 TargetRTF:Text;
 OutToFile:Boolean;
 C:Char;
 ReadOfs:Word;
 PushChar:Char;
 HasPush:Boolean;
 CurStyle:StyleRec;
 StyleStack:Array[0..63]of StyleRec;
 StyleTop:Integer;
 PreMode,NeedSpace,LastWasPar:Boolean;

Function Lower(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do
  If S[I]in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
 Lower:=S;
End;

Function TrimStr(S:String):String;
Begin
 While(Length(S)>0)and(S[1]<=' ')do Delete(S,1,1);
 While(Length(S)>0)and(S[Length(S)]<=' ')do Dec(S[0]);
 TrimStr:=S;
End;

Function IntToStr(I:LongInt):String;
Var
 S:String;
Begin
 Str(I,S);
 IntToStr:=S;
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
  If EOF(SourceHTML)Then ReadChar:=False
  Else Begin
   BlockRead(SourceHTML,Ch,SizeOf(Ch),ReadOfs);
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
 If OutToFile Then Write(TargetRTF,S)
              Else Write(S);
End;

Procedure OutLn(S:String);
Begin
 If OutToFile Then WriteLn(TargetRTF,S)
              Else WriteLn(S);
End;

Procedure RTFChar(Ch:Char);
Begin
 Case Ch of
  '\':OutS('\\');
  '{':OutS('\{');
  '}':OutS('\}');
  #9:OutS('\tab ');
  Else OutS(Ch);
 End;
 NeedSpace:=False;
 LastWasPar:=False;
End;

Procedure RTFUnicode(N:LongInt);
Begin
 OutS('\u');
 OutS(IntToStr(N));
 OutS('?');
 NeedSpace:=False;
 LastWasPar:=False;
End;

Procedure TextChar(Ch:Char);
Begin
 If PreMode Then Begin
  If Ch=#10 Then Begin
   OutS('\line ');
   LastWasPar:=False;
  End
   Else
  If Ch=#13 Then
  Else RTFChar(Ch);
 End
  Else
 Begin
  If Ch in[#9,#10,#13,' ']Then Begin
   If Not NeedSpace Then NeedSpace:=True;
  End
   Else
  Begin
   If NeedSpace Then Begin
    OutS(' ');
    NeedSpace:=False;
   End;
   RTFChar(Ch);
  End;
 End;
End;

Procedure Par;
Begin
 If Not LastWasPar Then Begin
  OutLn('\par');
  LastWasPar:=True;
  NeedSpace:=False;
 End;
End;

Procedure LineBreak;
Begin
 OutS('\line ');
 NeedSpace:=False;
 LastWasPar:=False;
End;

Procedure SetBold(B:Boolean);
Begin
 If CurStyle.Bold<>B Then Begin
  If B Then OutS('\b ')
       Else OutS('\b0 ');
  CurStyle.Bold:=B;
  NeedSpace:=False;
 End;
End;

Procedure SetItalic(B:Boolean);
Begin
 If CurStyle.Italic<>B Then Begin
  If B Then OutS('\i ')
       Else OutS('\i0 ');
  CurStyle.Italic:=B;
  NeedSpace:=False;
 End;
End;

Procedure SetUnderline(B:Boolean);
Begin
 If CurStyle.Underline<>B Then Begin
  If B Then OutS('\ul ')
       Else OutS('\ulnone ');
  CurStyle.Underline:=B;
  NeedSpace:=False;
 End;
End;

Procedure SetStyle(S:StyleRec);
Begin
 SetUnderline(S.Underline);
 SetItalic(S.Italic);
 SetBold(S.Bold);
End;

Procedure PushStyle;
Begin
 If StyleTop<High(StyleStack)Then Begin
  Inc(StyleTop);
  StyleStack[StyleTop]:=CurStyle;
 End;
End;

Procedure PopStyle;
Begin
 If StyleTop>0 Then Begin
  SetStyle(StyleStack[StyleTop]);
  Dec(StyleTop);
 End;
End;

Function EntityValue(S:String; Var Value:LongInt):Boolean;
Var
 Code,I,N:Integer;
 Hex:Boolean;
Begin
 EntityValue:=True;
 S:=Lower(S);
 If S='amp'Then Value:=Ord('&')
  Else
 If S='lt'Then Value:=Ord('<')
  Else
 If S='gt'Then Value:=Ord('>')
  Else
 If S='quot'Then Value:=Ord('"')
  Else
 If S='apos'Then Value:=Ord('''')
  Else
 If S='nbsp'Then Value:=160
  Else
 If S='copy'Then Value:=169
  Else
 If S='reg'Then Value:=174
  Else
 If S='euro'Then Value:=8364
  Else
 If S='ndash'Then Value:=8211
  Else
 If S='mdash'Then Value:=8212
  Else
 If S='lsquo'Then Value:=8216
  Else
 If S='rsquo'Then Value:=8217
  Else
 If S='ldquo'Then Value:=8220
  Else
 If S='rdquo'Then Value:=8221
  Else
 If S='bull'Then Value:=8226
  Else
 If(Copy(S,1,1)='#')Then Begin
  Delete(S,1,1);
  Hex:=False;
  If(Length(S)>0)and((S[1]='x')or(S[1]='X'))Then Begin
   Hex:=True;
   Delete(S,1,1);
  End;
  Value:=0;
  If Hex Then Begin
   For I:=1 to Length(S)do Begin
    N:=Pos(UpCase(S[I]),'0123456789ABCDEF');
    If N=0 Then Begin EntityValue:=False;Exit;End;
    Value:=Value*16+N-1;
   End;
  End
   Else
  Begin
   Val(S,Value,Code);
   If Code<>0 Then EntityValue:=False;
  End;
 End
  Else EntityValue:=False;
End;

Procedure ReadEntity;
Var
 S:String;
 Ch:Char;
 Value:LongInt;
Begin
 S:='';
 While ReadChar(Ch)do Begin
  If Ch=';'Then Break;
  If Length(S)<40 Then S:=S+Ch;
  If Ch in['<','&',#10,#13]Then Break;
 End;
 If EntityValue(S,Value)Then Begin
  If Value<128 Then TextChar(Chr(Value))
              Else RTFUnicode(Value);
 End
  Else
 Begin
  TextChar('&');
  For Value:=1 to Length(S)do TextChar(S[Value]);
  If Ch=';'Then TextChar(';')
          Else UnreadChar(Ch);
 End;
End;

Procedure SkipComment;
Var
 Ch:Char;
 DashCount:Integer;
Begin
 DashCount:=0;
 While ReadChar(Ch)do Begin
  If Ch='-'Then Inc(DashCount)
  Else
  If(Ch='>')and(DashCount>=2)Then Break
  Else DashCount:=0;
 End;
End;

Procedure ReadTag;
Var
 Ch:Char;
 Raw,Name:String;
 I:Integer;
 Closing,SelfClose:Boolean;
Begin
 Raw:='';
 If Not ReadChar(Ch)Then Exit;
 If Ch='!'Then Begin
  If ReadChar(Ch)Then Begin
   If Ch='-'Then Begin
    If ReadChar(Ch)Then Begin
     If Ch='-'Then SkipComment;
    End;
   End
    Else
   Begin
    While(Ch<>'>')and ReadChar(Ch)do;
   End;
  End;
  Exit;
 End;
 Closing:=False;
 If Ch='/'Then Closing:=True
           Else Raw:=Raw+Ch;
 While ReadChar(Ch)do Begin
  If Ch='>'Then Break;
  If Length(Raw)<120 Then Raw:=Raw+Ch;
 End;
 Raw:=TrimStr(Raw);
 SelfClose:=False;
 If(Length(Raw)>0)and(Raw[Length(Raw)]='/')Then Begin
  SelfClose:=True;
  Dec(Raw[0]);
  Raw:=TrimStr(Raw);
 End;
 Name:='';
 For I:=1 to Length(Raw)do Begin
  If Raw[I]in[#9,#10,#13,' ','/']Then Break;
  Name:=Name+Raw[I];
 End;
 Name:=Lower(Name);
 If Name=''Then Exit;
 If Closing Then Begin
  If(Name='b')or(Name='strong')Then SetBold(False)
   Else
  If(Name='i')or(Name='em')Then SetItalic(False)
   Else
  If(Name='u')Then SetUnderline(False)
   Else
  If(Name='h1')or(Name='h2')or(Name='h3')or(Name='h4')or
    (Name='h5')or(Name='h6')Then Begin
   PopStyle;
   OutS('\fs24 ');
   Par;
  End
   Else
  If(Name='p')or(Name='div')or(Name='section')or(Name='article')or
    (Name='blockquote')or(Name='li')Then Par
   Else
  If Name='pre'Then Begin
   PreMode:=False;
   OutS('\f0 ');
   Par;
  End;
 End
  Else
 Begin
  If(Name='b')or(Name='strong')Then SetBold(True)
   Else
  If(Name='i')or(Name='em')Then SetItalic(True)
   Else
  If(Name='u')Then SetUnderline(True)
   Else
  If(Name='br')Then LineBreak
   Else
  If(Name='p')or(Name='div')or(Name='section')or(Name='article')or
    (Name='blockquote')Then Par
   Else
  If Name='li'Then Begin
   Par;
   OutS('\bullet\tab ');
   LastWasPar:=False;
  End
   Else
  If(Name='ul')or(Name='ol')Then Par
   Else
  If(Name='h1')or(Name='h2')or(Name='h3')or(Name='h4')or
    (Name='h5')or(Name='h6')Then Begin
   Par;
   PushStyle;
   SetBold(True);
   If Name='h1'Then OutS('\fs40 ')
    Else
   If Name='h2'Then OutS('\fs34 ')
    Else
   If Name='h3'Then OutS('\fs30 ')
    Else OutS('\fs26 ');
  End
   Else
  If Name='pre'Then Begin
   Par;
   PreMode:=True;
   OutS('\f1 ');
  End
   Else
  If Name='hr'Then Begin
   Par;
   OutS('------------------------------');
   Par;
  End;
  If SelfClose and(Name<>'br')and(Name<>'hr')Then Begin
  End;
 End;
End;

Procedure PrintRTFHeader;
Begin
 OutLn('{\rtf1\ansi\deff0');
 OutLn('{\fonttbl{\f0\froman Times New Roman;}{\f1\fmodern Courier New;}}');
 OutLn('{\colortbl;\red0\green0\blue0;}');
 OutLn('\viewkind4\uc1\pard\cf1\f0\fs24');
End;

Procedure Convert;
Begin
 CurStyle.Bold:=False;
 CurStyle.Italic:=False;
 CurStyle.Underline:=False;
 StyleTop:=0;
 FillChar(StyleStack,SizeOf(StyleStack),0);
 HasPush:=False;
 PreMode:=False;
 NeedSpace:=False;
 LastWasPar:=True;
 PrintRTFHeader;
 While ReadChar(C)do Begin
  Case C of
   '<':ReadTag;
   '&':ReadEntity;
   Else TextChar(C);
  End;
 End;
 OutLn('\par');
 OutLn('}');
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('HTML2RTF : Cette commande permet de convertir un fichier HTML ',
                     'en format RTF.');
  WriteLn;
  WriteLn('Syntaxe : HTML2RTF source.html [target.rtf]');
  WriteLn;
  WriteLn(' source.html   Nom du fichier a convertir');
  WriteLn(' target.rtf    Nom du fichier du resultat');
  WriteLn;
 End
  Else
 If ParamCount>0 Then Begin
  {$I-}Assign(SourceHTML,ParamStr(1));
  Reset(SourceHTML,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de lire le fichier ',ParamStr(1));
   Halt(1);
  End;
  OutToFile:=ParamStr(2)<>'';
  If OutToFile Then Begin
   Assign(TargetRTF,ParamStr(2));
   {$I-}Rewrite(TargetRTF);{$I+}
   If IOResult<>0 Then Begin
    Close(SourceHTML);
    WriteLn('Impossible d''ecrire le fichier ',ParamStr(2));
    Halt(2);
   End;
  End;
  Convert;
  If OutToFile Then Close(TargetRTF);
  Close(SourceHTML);
 End
  Else
 Begin
  WriteLn('Parametre attendu !');
  Halt(1);
 End;
END.
