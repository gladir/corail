{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program GREP(Input,Output);

Uses DOS,Strings;

Type
 TRegExprEntryType=(RetBacktrace,RetCharset,RetEndline,RetIllegalend,
                    RetOr,RetStartline,RetPattern);
 TCharSet=Set of Char;
 PRegExprEntry=^TRegExprEntry;
 TRegExprEntry=Record
  Next,NextDestroy:PRegExprEntry;
  Case typ:tregexprentrytype of
   RetCharset:(Chars:TCharSet;ElsePath:PRegExprEntry);
   RetPattern:(Pattern:PRegExprEntry;MinOccurs:Integer;MaxOccurs:Integer;Alternative:PRegExprEntry);
 End;

 TRegExprFlags=Set of (SingleLine,MultiLine,NoCaseSensitive);

Var
 Data:PRegExprEntry;
 DestroyList:PRegExprEntry;
 Option:TRegExprFlags;
 I,Len,LineNumber:LongInt;
 Found:Boolean;
 FileFind:Text;
 Info:SearchRec;
 FindStr,FindInFile,CurrLine:String;
 InitOk:Boolean;
 PTmp:Array[0..255]of Char;

Function PatLength(hp1:PRegExprEntry):Integer;
Var
 Count:Integer;
 hp:pregexprentry;
Begin
 Count:=0;
 If hp1^.typ=RetPattern Then hp:=hp1^.pattern
                        Else hp:=hp1;
 While Assigned(hp)do Begin
  If hp^.typ = RetPattern Then Inc(Count,patlength(hp))Else
  If hp^.typ = RetCharset Then Inc(Count);
  hp:=hp^.next;
 End;
 If hp1^.typ=RetPattern Then Count:=hp1^.minOccurs*Count;
 PatLength:=Count;
End;

Procedure DestroyRegExprEngine;
Var
 hp:PRegExprEntry;
Begin
 hp:=DestroyList;
 While assigned(hp) do Begin
  DestroyList:=hp^.nextdestroy;
  Dispose(hp);
  hp:=DestroyList;
 End;
 Data:=NIL;
 DestroyList:=NIL;
End;

Function GenerateRegExprEngine(RegExpr:PChar):Boolean;
Var
 First:PRegExprEntry;
 CurrPos:PChar;
 Error:Boolean;

 Procedure doregister(p:pregexprentry);Begin
  p^.nextdestroy:=first;
  first:=p;
 End;

 Procedure ReadChars(Var Chars:TCharSet);
 Var
  c1:Char;
 Begin
  chars:=[];
  Case CurrPos^ of
   #0:Exit;
   '.':Begin
    Inc(CurrPos);
    Chars:=[#0..#255]-[#10];
   End;
   '\':Begin
    Inc(CurrPos);
    Case CurrPos^ of
     #0:Begin
      Error:=true;
      Exit;
     End;
     't':Begin
      Inc(CurrPos);
      Chars:=[#9];
     End;
     'n':Begin
      Inc(CurrPos);
      Chars:=[#10];
     End;
     'r':Begin
      Inc(CurrPos);
      Chars:=[#13];
     End;
     'd':Begin
      Inc(CurrPos);
      Chars:=['0'..'9'];
     End;
     'D':Begin
      Inc(CurrPos);
      Chars:=[#0..#255]-['0'..'9'];
     End;
     's':Begin
      Inc(CurrPos);
      Chars:=[' ',#9];
     End;
     'S':Begin
      Inc(CurrPos);
      Chars:=[#0..#255]-[' ',#9];
     End;
     'w':Begin
      Inc(CurrPos);
      Chars:=['A'..'Z','a'..'z','_','0'..'9'];
     End;
     'W':Begin
      Inc(CurrPos);
      Chars:=[#0..#255]-['A'..'Z','a'..'z','_','0'..'9'];
     End;
     'f':Begin
      Inc(CurrPos);
      Chars:=[#12];
     End;
     'a':Begin
      Inc(CurrPos);
      Chars:=[#7];
     End;
     Else Begin
      Chars:=[CurrPos^];
      Inc(CurrPos);
     End;
    End;
   End;
   Else Begin
    If NoCaseSensitive in Option Then c1:=UpCase(CurrPos^)
                                Else c1:=CurrPos^;
    Inc(CurrPos);
    If CurrPos^='-'Then Begin
     Inc(CurrPos);
     If CurrPos^=#0Then Begin
      Error:=true;
      Exit;
     End;
     If NoCaseSensitive in Option Then chars:=[c1..UpCase(CurrPos^)]
                                 Else chars:=[c1..CurrPos^];
     Inc(CurrPos);
    End
     Else
    Chars:=[c1];
   End;
  End;
 End;

 Procedure ReadCharSet(Var CharSet:TCharSet);
 Var
  Chars:TCharSet;
 Begin
  CharSet:=[];
  Case CurrPos^ of
   #0:Exit;
   '[':Begin
    Inc(CurrPos);
    While CurrPos^<>']'do Begin
     If CurrPos^='^'Then Begin
      Inc(CurrPos);
      ReadChars(Chars);
      CharSet:=CharSet+([#0..#255]-chars);
     End
      Else
     Begin
      ReadChars(Chars);
      CharSet:=CharSet+Chars;
     End;
     If Error or(CurrPos^=#0)Then Begin
      Error:=True;
      Exit;
     End;
    End;
    Inc(CurrPos);
   End;
   '^':Begin
    Inc(CurrPos);
    ReadChars(Chars);
    CharSet:=[#0..#255]-chars;
   End;
   Else Begin
    ReadChars(Chars);
    CharSet:=Chars;
   End;
  End;
 End;

 Function ParseOccurences(Var CurrPos:PChar;Var minoccurs,maxoccurs:Integer):Boolean;
 Var
  Err:Word;
  minOccursString,maxOccursString:String;
 Begin
  ParseOccurences:=false;
  minOccurs:=-1;
  maxOccurs:=-1;
  Inc(CurrPos);
  minOccursString:='';
  If CurrPos^ = #0 Then Begin
   Error:=true;
   Exit;
  End;
  While(CurrPos^<>#0)and(CurrPos^ in['0'..'9'])do Begin
   minOccursString:=minOccursString+CurrPos^;
   Inc(CurrPos);
  End;
  If Length(minOccursString)=0 Then Begin
   Error:=true;
   Exit;
  End;
  Val(minOccursString,minOccurs,Err);
  If CurrPos^= '}'Then Begin
   Inc(CurrPos);
   maxOccurs:=minOccurs;
   parseoccurences:=true;
   Exit;
  End;
  If CurrPos^=','Then Begin
   maxOccursString:='';
   Inc(CurrPos);
   While(CurrPos^<>#0)and(CurrPos^ in ['0'..'9'])do Begin
    maxOccursString:=maxOccursString+CurrPos^;
    Inc(CurrPos);
   End;
   If CurrPos^='}'Then Begin
    If length(maxOccursString) > 0 Then Val(maxOccursString,maxOccurs,Err)
                                   Else maxOccurs:=high(integer);
    Inc(CurrPos);
    ParseOccurences:=true;
    Exit;
   End;
  End;
  Error:=True;
 End;

 Function ParseRegExpr(Next,ElsePath:PRegExprEntry):PRegExprEntry;
 Var
  hp:pregexprentry;
  minOccurs,maxOccurs:Integer;
  hp3:PRegExprEntry;
  cs:TCharSet;
  Chaining:^PRegExprEntry;
 Begin
  Chaining:=nil;
  ParseRegExpr:=nil;
  ElsePath:=nil;
  If Error Then Exit;
  While true do Begin
   If error Then Exit;
   Case CurrPos^ of
    '(':Begin
     Inc(CurrPos);
     hp:=parseregexpr(nil,nil);
     If error Then Exit;
     If CurrPos^<>')'Then Begin
      Error:=true;
      Exit;
     End;
     Inc(CurrPos);
     Case CurrPos^ of
      '*':Begin
       Inc(CurrPos);
       New(hp3);
       DoRegister(hp3);
       hp3^.typ:=RetPattern;
       hp3^.alternative:=nil;
       hp3^.pattern:=hp;
       hp3^.elsepath:=elsepath;
       hp3^.minoccurs:=0;
       hp3^.maxoccurs:=high(integer);
      End;
      '+':Begin
       Inc(CurrPos);
       New(hp3);
       DoRegister(hp3);
       hp3^.typ:=RetPattern;
       hp3^.alternative:=nil;
       hp3^.pattern:=hp;
       hp3^.elsepath:=elsepath;
       hp3^.minoccurs:=1;
       hp3^.maxoccurs:=high(integer);
      End;
      '?':Begin
       Inc(CurrPos);
       New(hp3);
       DoRegister(hp3);
       hp3^.typ:=RetPattern;
       hp3^.alternative:=nil;
       hp3^.pattern:=hp;
       hp3^.elsepath:=elsepath;
       hp3^.minoccurs:=0;
       hp3^.maxoccurs:=1;
      End;
      '{':Begin
       If Not ParseOccurences(CurrPos,minOccurs,maxOccurs)Then Exit;
       New(hp3);
       DoRegister(hp3);
       hp3^.typ:=RetPattern;
       hp3^.alternative:=nil;
       hp3^.pattern:=hp;
       hp3^.elsepath:=elsepath;
       hp3^.minoccurs:=minOccurs;
       hp3^.maxoccurs:=maxOccurs;
      End;
      Else Begin
       New(hp3);
       DoRegister(hp3);
       hp3^.typ:=RetPattern;
       hp3^.alternative:=nil;
       hp3^.pattern:=hp;
       hp3^.elsepath:=elsepath;
       hp3^.minoccurs:=1;
       hp3^.maxoccurs:=1;
      End;
     End;
     hp3^.Next:=NIL;
     If Assigned(Chaining)Then Chaining^:=hp3
                          Else parseregexpr:=hp3;
     Chaining:=@hp3^.next;
    End;
    '|':Begin
     If Not Assigned(hp3)Then Begin
      Error:=true;
      Exit;
     End;
     If (hp3^.typ<>RetPattern)Then Begin
      error:=true;
      Exit;
     End;
     While CurrPos^='|' do Begin
      Inc(CurrPos);
      If CurrPos^=#0 Then Begin
       Error:=true;
       Exit;
      End;
      hp:=parseregexpr(Next,ElsePath);
      If PatLength(hp)>PatLength(hp3^.pattern)Then Begin
       hp3^.alternative:=hp3^.pattern;
       hp3^.pattern:=hp;
      End
       Else
      hp3^.alternative:=hp;
     End;
    End;
    ')':Exit;
    '^':Begin
     Inc(CurrPos);
     hp:=parseregexpr(nil,nil);
     If Error Then Exit;
     New(hp3);
     DoRegister(hp3);
     hp3^.typ:=RetStartline;
     hp3^.pattern:=hp;
     hp3^.elsepath:=elsepath;
     hp3^.next:=nil;
     If Assigned(chaining)Then Chaining^:=hp3
                          Else ParseRegExpr:=hp3;
     Chaining:=@hp3^.Next;
    End;
    '$':Begin
     Inc(CurrPos);
     New(hp);
     DoRegister(hp);
     hp^.typ:=RetEndline;
     hp^.elsepath:=elsepath;
     hp^.next:=nil;
     If Assigned(chaining)Then Chaining^:=hp
                          Else ParseRegExpr:=hp;
     Chaining:=@hp^.next;
    End;
    #0:Exit;
    Else Begin
     ReadCharSet(cs);
     If Error Then Exit;
     Case CurrPos^ of
      '*':Begin
       Inc(CurrPos);
       New(hp);
       DoRegister(hp);
       hp^.typ:=RetCharset;
       hp^.chars:=cs;
       hp^.elsepath:=nil;
       hp^.next:=nil;
       New(hp3);
       DoRegister(hp3);
       hp3^.typ:=RetPattern;
       hp3^.alternative:=nil;
       hp3^.pattern:=hp;
       hp3^.elsepath:=elsepath;
       hp3^.minoccurs:=0;
       hp3^.maxoccurs:=high(integer);
       hp3^.next:=nil;
       If Assigned(Chaining)Then Chaining^:=hp3
                            Else ParseRegExpr:=hp3;
       Chaining:=@hp3^.Next;
      End;
      '+':Begin
       Inc(CurrPos);
       New(hp);
       DoRegister(hp);
       hp^.typ:=RetCharset;
       hp^.chars:=cs;
       hp^.elsepath:=nil;
       hp^.next:=nil;
       New(hp3);
       DoRegister(hp3);
       hp3^.typ:=RetPattern;
       hp3^.alternative:=nil;
       hp3^.pattern:=hp;
       hp3^.elsepath:=elsepath;
       hp3^.minoccurs:=1;
       hp3^.maxoccurs:=high(integer);
       hp3^.next:=nil;
       If Assigned(Chaining)Then Chaining^:=hp3
                            Else ParseRegExpr:=hp3;
       Chaining:=@hp3^.next;
      End;
      '?':Begin
       Inc(CurrPos);
       New(hp);
       DoRegister(hp);
       hp^.typ:=RetCharset;
       hp^.chars:=cs;
       hp^.elsepath:=nil;
       hp^.next:=nil;
       New(hp3);
       DoRegister(hp3);
       hp3^.typ:=RetPattern;
       hp3^.pattern:=hp;
       hp3^.alternative:=nil;
       hp3^.elsepath:=elsepath;
       hp3^.minoccurs:=0;
       hp3^.maxoccurs:=1;
       hp3^.next:=nil;
       If Assigned(chaining)Then Chaining^:=hp3
                            Else ParseRegExpr:=hp3;
       Chaining:=@hp3^.next;
      End;
      '{':Begin
       If Not ParseOccurences(CurrPos,minOccurs,maxOccurs)Then Exit;
       New(hp);
       DoRegister(hp);
       hp^.typ:=RetCharset;
       hp^.chars:=cs;
       hp^.elsepath:=nil;
       hp^.next:=nil;
       New(hp3);
       DoRegister(hp3);
       hp3^.typ:=RetPattern;
       hp3^.alternative:=nil;
       hp3^.pattern:=hp;
       hp3^.elsepath:=elsepath;
       hp3^.minoccurs:=minOccurs;
       hp3^.maxoccurs:=maxOccurs;
       hp3^.next:=nil;
       If Assigned(chaining)Then Chaining^:=hp3
                            Else ParseRegExpr:=hp3;
       Chaining:=@hp3^.next;
      End;
      Else Begin
       new(hp);
       doregister(hp);
       hp^.typ:=RetCharset;
       hp^.chars:=cs;
       hp^.elsepath:=elsepath;
       hp^.next:=next;
       If Assigned(chaining)Then Chaining^:=hp
                            Else ParseRegExpr:=hp;
       Chaining:=@hp^.next;
       Continue;
      End;
     End;
    End;
   End;
  End;
 End;

Var
 Endp:pregexprentry;
Begin
 GenerateRegExprEngine:=false;
 Data:=nil;
 DestroyList:=nil;
 If RegExpr=Nil Then Exit;
 First:=Nil;
 If(SingleLine in Option)and(MultiLine in Option)Then Exit;
 CurrPos:=RegExpr;
 GenerateRegExprEngine:=true;
 error:=false;
 New(endp);
 DoRegister(endp);
 Endp^.typ:=RetIllegalend;
 Data:=parseregexpr(nil,endp);
 DestroyList:=first;
 If Error or (CurrPos^<>#0)Then Begin
  GenerateRegExprEngine:=false;
  DestroyRegExprEngine;
 End;
End;

Function RegExprPos(P:PChar;Var I,len:LongInt):Boolean;
Var
 lastpos,firstpos:PChar;

 Function Dosearch(regexprentry:PRegExprEntry;Pos:PChar):Boolean;
 Var
  _Result,Found,CheckValue:Boolean;
  SavedPos:PChar;
  Counter:Word;
 Begin
  DoSearch:=False;
  While true do Begin
   Case regexprentry^.typ of
    RetEndline:Begin
     If pos^ = #0Then Begin
      DoSearch:=true;
      Exit;
     End;
     If MultiLine in Option Then Begin
      If(pos^=#13)and((pos+1)^=#10)Then Begin
       RegExprEntry:=RegExprEntry^.Next;
      End
       Else
      If(pos^=#$85)or(pos^=#10)or((pos^=#13)and((pos-1) >= firstpos)and((pos-1)^ <> #10))Then Begin
       RegExprEntry:=RegExprEntry^.Next;
      End
       Else
      Begin
       DoSearch:=false;
       Exit;
      End;
     End
     Else Exit;
    End;
    RetPattern:Begin
     Found:=False;
     SavedPos:=Pos;
     Counter:=0;
     Repeat
      Found:=DoSearch(regexprentry^.pattern,pos);
      If Not Found Then Break;
      Pos:=LastPos;
      Inc(Counter);
     Until (Not found)or(Counter>=Regexprentry^.MaxOccurs)or(pos^= #0);
     If Counter = 0Then Begin
      If(regexprentry^.minoccurs>0)Then Begin
       DoSearch:=false;
       If Assigned(regexprentry^.alternative)Then Begin
        DoSearch:=DoSearch(regexprentry^.Alternative,SavedPos);
        Exit;
       End;
       Exit;
      End;
      DoSearch:=true;
      LastPos:=SavedPos;
     End
      Else
     Begin
      If(Counter<RegExprEntry^.MinOccurs)or(Counter>RegExprEntry^.MaxOccurs)Then Begin
       DoSearch:=False;
       Exit;
      End;
      DoSearch:=true;
      If Pos^=#0 Then Begin
       DoSearch:=true;
       Exit;
      End;
     End;
     RegExprEntry:=regexprentry^.Next;
     If(Counter=0) and Not Assigned(regexprentry)Then Exit;
    End;
    RetStartline:Begin
     CheckValue:=Pos=FirstPos;
     If MultiLine in Option Then Begin
      If(((pos-1) >= Firstpos)and((pos-1)^=#$85))or
        (((pos-1) >= Firstpos)and((pos-1)^=#10))or
        (((pos-1) >= Firstpos) and ((pos-1)^=#13)and((pos)^<>#10))Then Begin
       CheckValue:=True;
      End;
     End;
     If CheckValue Then Begin
      _Result:=DoSearch(regexprentry^.Pattern,Pos);
      DoSearch:=_Result;
      RegExprEntry:=RegExprEntry^.Next;
      If Not _Result Then Exit;
      pos:=lastpos;
     End
      Else
     Begin
      DoSearch:=false;
      Exit;
     End;
    End;
    RetCharset:Begin
     If(pos^ in regexprentry^.chars)or((NoCaseSensitive in Option)and
     (upcase(pos^) in regexprentry^.chars))Then Begin
     RegExprEntry:=RegExprEntry^.Next;
     Inc(Pos);
    End
    Else Exit;
   End;
   RetBacktrace:Begin
    If DoSearch(regexprentry^.Next,Pos)Then Begin
     DoSearch:=true;
     Exit;
    End
     Else
    If DoSearch(RegExprEntry^.ElsePath,Pos)Then Begin
     DoSearch:=true;
     Exit;
    End
    Else Exit;
   End;
  End;
  LastPos:=Pos;
  If RegExprEntry=nil Then Begin
   DoSearch:=true;
   Exit;
  End;
  If RegExprEntry^.typ=RetIllegalend Then Exit;
  If(pos^=#0)and(regexprentry^.typ = RetEndline)and(Not Assigned(regexprentry^.next))Then Begin
   DoSearch:=True;
   Exit;
  End;
  If Pos^=#0 Then Exit;
 End;
End;

Begin
 RegExprPos:=false;
 I:=0;
 Len:=0;
 FirstPos:=p;
 If Data=Nil Then Exit;
 While p^<>#0 do Begin
  If DoSearch(Data,p)Then Begin
   Len:=LastPos-p;
   RegExprPos:=true;
   Exit;
  End
   Else
  Begin
   Inc(P);
   Inc(I);
  End;
 End;
 I:=-1;
End;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('GREP : Cette commande permet de rechercher une chaine de caractŠres dans des fichiers.');
  WriteLn;
  WriteLn('Syntaxe : GREP "chaine" [fichier] [-I]');
 End
  Else
 If ParamCount>0Then Begin
  Option:=[];
  FindStr:='';
  FindInFile:='';
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/I'Then Include(Option,NoCaseSensitive) Else
   If Copy(ParamStr(I),1,1)='"'Then FindStr:=Copy(ParamStr(I),2,Length(ParamStr(I))-2)
    Else
   Begin
    If FindStr=''Then FindStr:=ParamStr(I)
                 Else FindInFile:=ParamStr(I);
   End;
  End;
  StrPCopy(PTmp,FindStr);
  InitOk:=GenerateRegExprEngine(@PTmp);
  If FindStr=''Then Begin
   WriteLn('Chaine de caracteres de recherche requis !');
  End
   Else
  If FindInFile=''Then Begin
   LineNumber:=1;
   Repeat
    ReadLn(CurrLine);
    StrPCopy(PTmp,CurrLine);
    If(RegExprPos(@PTmp,I,Len))then Begin
     WriteLn(CurrLine);
     Found:=True;
    End;
    Inc(LineNumber);
   Until Eof(Input);
  End
   Else
  Begin
   DOS.FindFirst(FindInFile,AnyFile,Info);
   Found:=False;
   While DOSError=0 do Begin
    LineNumber:=1;
    WriteLn('-------- ',Info.Name);
    Assign(FileFind,Info.Name);
    Reset(FileFind);
    While Not EOF(FileFind)do Begin
     ReadLn(FileFind,CurrLine);
     StrPCopy(PTmp,CurrLine);
     If(RegExprPos(@PTmp,I,Len))then Begin
      WriteLn(CurrLine);
      Found:=True;
     End;
     Inc(LineNumber);
    End;
    Close(FileFind);
    DOS.FindNext(Info);
    WriteLn;
   End;
   If Not(Found)Then WriteLn('Aucun resultat de trouve');
  End;
 End
  Else
 WriteLn('Parametre requis !');
END.