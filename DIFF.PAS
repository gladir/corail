{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program DIFF;

Uses DOS;

Const
 MaxLines=4000;

Type
 TLine=String[255];
 PLineNode=^TLineNode;
 TLineNode=Record
  Text,Norm:TLine;
  Next:PLineNode;
 End;
 TLineIndex=Array[1..MaxLines]of PLineNode;
 TLineList=Record
  First,Last:PLineNode;
  Count:Integer;
  Index:TLineIndex;
 End;
 PLineList=^TLineList;
 TIntArray=Array[0..MaxLines]of Integer;
 PIntArray=^TIntArray;
 TOpKind=(_Equal,_Delete,_Insert);
 TOutMode=(_Normal,_Unified,_Context,_SideBySide);
 TOption=(_IgnoreCase,_IgnoreAllSpace,_IgnoreSpaceChange,
          _IgnoreTrailingSpace,_IgnoreBlankLines,_StripTrailingCR,
          _Brief,_ReportSame,_NewFile);
 TOptions=Set of TOption;
 TOp=Record
  Kind:TOpKind;
  AIndex,BIndex:Integer;
 End;
 POpNode=^TOpNode;
 TOpNode=Record
  Op:TOp;
  Next:POpNode;
 End;
 TOpIndex=Array[1..MaxLines*2]of POpNode;
 TOpList=Record
  First,Last:POpNode;
  Count:Integer;
  Index:TOpIndex;
 End;

Var
 File1,File2,Label1,Label2:String;
 A,B:PLineList;
 ACount,BCount:Integer;
 OpList:TOpList;
 OpCount:Integer;
 Score1,Score2:PIntArray;
 Options:TOptions;
 OutMode:TOutMode;
 ContextLines,OutputWidth:Integer;
 ExitCode:Byte;

Function Lower(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do
  If S[I]in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
 Lower:=S;
End;

Function Upper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do
  If S[I]in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 Upper:=S;
End;

Function IntToStr(N:LongInt):String;
Var
 S:String;
Begin
 Str(N,S);
 IntToStr:=S;
End;

Function TrimRight(S:String):String;
Begin
 While(Length(S)>0)and(S[Length(S)]in[' ',#9,#13])do Dec(S[0]);
 TrimRight:=S;
End;

Function IsBlank(S:String):Boolean;
Var
 I:Integer;
Begin
 IsBlank:=True;
 For I:=1 to Length(S)do
  If Not(S[I]in[' ',#9])Then Begin
   IsBlank:=False;
   Exit;
  End;
End;

Function CompactSpaces(S:String;KeepOne:Boolean):String;
Var
 I:Integer;
 T:String;
 InSpace:Boolean;
Begin
 T:='';
 InSpace:=False;
 For I:=1 to Length(S)do Begin
  If S[I]in[' ',#9]Then Begin
   If KeepOne and Not InSpace Then T:=T+' ';
   InSpace:=True;
  End
   Else
  Begin
   T:=T+S[I];
   InSpace:=False;
  End;
 End;
 If KeepOne Then T:=TrimRight(T);
 CompactSpaces:=T;
End;

Function NormalizeLine(S:String):String;
Begin
 If _StripTrailingCR in Options Then
  If(Length(S)>0)and(S[Length(S)]=#13)Then Dec(S[0]);
 If _IgnoreTrailingSpace in Options Then S:=TrimRight(S);
 If _IgnoreAllSpace in Options Then S:=CompactSpaces(S,False)
  Else
 If _IgnoreSpaceChange in Options Then S:=CompactSpaces(S,True);
 If _IgnoreCase in Options Then S:=Upper(S);
 NormalizeLine:=S;
End;

Function FileExists(Name:String):Boolean;
Var
 F:File;
 R:Integer;
Begin
 {$I-}Assign(F,Name);Reset(F,1);{$I+}
 R:=IOResult;
 If R=0 Then Close(F);
 FileExists:=R=0;
End;

Procedure InitLineList(Var List:TLineList);
Begin
 List.First:=Nil;
 List.Last:=Nil;
 List.Count:=0;
 FillChar(List.Index,SizeOf(List.Index),0);
End;

Procedure AddLine(Var List:TLineList;S:TLine);
Var
 Node:PLineNode;
Begin
 If List.Count>=MaxLines Then Begin
  WriteLn('DIFF: fichier trop grand, maximum ',MaxLines,' lignes.');
  Halt(2);
 End;
 New(Node);
 If Node=Nil Then Begin
  WriteLn('DIFF: memoire insuffisante.');
  Halt(2);
 End;
 Node^.Text:=S;
 Node^.Norm:=NormalizeLine(S);
 Node^.Next:=Nil;
 If List.First=Nil Then List.First:=Node
                   Else List.Last^.Next:=Node;
 List.Last:=Node;
 Inc(List.Count);
 List.Index[List.Count]:=Node;
End;

Procedure FreeLineList(Var List:TLineList);
Var
 Node,NextNode:PLineNode;
Begin
 Node:=List.First;
 While Node<>Nil do Begin
  NextNode:=Node^.Next;
  Dispose(Node);
  Node:=NextNode;
 End;
 InitLineList(List);
End;

Function LineText(Var List:TLineList;Index:Integer):TLine;
Begin
 If(Index<1)or(Index>List.Count)or(List.Index[Index]=Nil)Then LineText:=''
 Else LineText:=List.Index[Index]^.Text;
End;

Function LineNorm(Var List:TLineList;Index:Integer):TLine;
Begin
 If(Index<1)or(Index>List.Count)or(List.Index[Index]=Nil)Then LineNorm:=''
 Else LineNorm:=List.Index[Index]^.Norm;
End;

Procedure InitFilesLists;
Begin
 A:=Nil;
 B:=Nil;
 New(A);
 New(B);
 If(A=Nil)or(B=Nil)Then Begin
  WriteLn('DIFF: memoire insuffisante.');
  Halt(2);
 End;
 InitLineList(A^);
 InitLineList(B^);
End;

Procedure FreeFilesLists;
Begin
 If A<>Nil Then Begin
  FreeLineList(A^);
  Dispose(A);
  A:=Nil;
 End;
 If B<>Nil Then Begin
  FreeLineList(B^);
  Dispose(B);
  B:=Nil;
 End;
End;

Procedure ReadTextFile(Name:String;Var List:TLineList);
Var
 F:Text;
 S:TLine;
Begin
 InitLineList(List);
 If Not FileExists(Name)Then Begin
  If _NewFile in Options Then Exit;
  WriteLn('DIFF: ',Name,': fichier introuvable');
  Halt(2);
 End;
 Assign(F,Name);
 {$I-}Reset(F);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('DIFF: impossible de lire ',Name);
  Halt(2);
 End;
 While Not EOF(F)do Begin
  ReadLn(F,S);
  If Not((_IgnoreBlankLines in Options)and IsBlank(S))Then AddLine(List,S);
 End;
 Close(F);
End;

Function SameLine(AI,BI:Integer):Boolean;
Begin
 SameLine:=LineNorm(A^,AI)=LineNorm(B^,BI);
End;

Procedure InitOpList(Var List:TOpList);
Begin
 List.First:=Nil;
 List.Last:=Nil;
 List.Count:=0;
 FillChar(List.Index,SizeOf(List.Index),0);
End;

Procedure AddOp(K:TOpKind;AI,BI:Integer);
Var
 Node:POpNode;
Begin
 If OpList.Count>=High(OpList.Index) Then Begin
  WriteLn('DIFF: trop de differences pour cette version.');
  Halt(2);
 End;
 New(Node);
 If Node=Nil Then Begin
  WriteLn('DIFF: memoire insuffisante.');
  Halt(2);
 End;
 Node^.Op.Kind:=K;
 Node^.Op.AIndex:=AI;
 Node^.Op.BIndex:=BI;
 Node^.Next:=Nil;
 If OpList.First=Nil Then OpList.First:=Node
                     Else OpList.Last^.Next:=Node;
 OpList.Last:=Node;
 Inc(OpList.Count);
 OpList.Index[OpList.Count]:=Node;
 OpCount:=OpList.Count;
End;

Procedure FreeOpList(Var List:TOpList);
Var
 Node,NextNode:POpNode;
Begin
 Node:=List.First;
 While Node<>Nil do Begin
  NextNode:=Node^.Next;
  Dispose(Node);
  Node:=NextNode;
 End;
 InitOpList(List);
 OpCount:=0;
End;

Function OpKindAt(Index:Integer):TOpKind;
Begin
 If(Index<1)or(Index>OpList.Count)or(OpList.Index[Index]=Nil)Then
  OpKindAt:=_Equal
 Else OpKindAt:=OpList.Index[Index]^.Op.Kind;
End;

Function OpAIndex(Index:Integer):Integer;
Begin
 If(Index<1)or(Index>OpList.Count)or(OpList.Index[Index]=Nil)Then
  OpAIndex:=0
 Else OpAIndex:=OpList.Index[Index]^.Op.AIndex;
End;

Function OpBIndex(Index:Integer):Integer;
Begin
 If(Index<1)or(Index>OpList.Count)or(OpList.Index[Index]=Nil)Then
  OpBIndex:=0
 Else OpBIndex:=OpList.Index[Index]^.Op.BIndex;
End;

Procedure InitScores;
Begin
 Score1:=Nil;
 Score2:=Nil;
 New(Score1);
 New(Score2);
 If(Score1=Nil)or(Score2=Nil)Then Begin
  WriteLn('DIFF: memoire insuffisante.');
  Halt(2);
 End;
 FillChar(Score1^,SizeOf(TIntArray),0);
 FillChar(Score2^,SizeOf(TIntArray),0);
End;

Procedure FreeScores;
Begin
 If Score1<>Nil Then Begin
  Dispose(Score1);
  Score1:=Nil;
 End;
 If Score2<>Nil Then Begin
  Dispose(Score2);
  Score2:=Nil;
 End;
End;

Procedure ForwardScore(A1,A2,B1,B2:Integer;Var Score:TIntArray);
Var
 Prev,Cur:TIntArray;
 I,J,M,V:Integer;
Begin
 M:=B2-B1+1;
 For J:=0 to M do Prev[J]:=0;
 For I:=A1 to A2 do Begin
  Cur[0]:=0;
  For J:=1 to M do Begin
   If SameLine(I,B1+J-1)Then Cur[J]:=Prev[J-1]+1
   Else Begin
    V:=Prev[J];
    If Cur[J-1]>V Then V:=Cur[J-1];
    Cur[J]:=V;
   End;
  End;
  For J:=0 to M do Prev[J]:=Cur[J];
 End;
 For J:=0 to M do Score[J]:=Prev[J];
End;

Procedure ReverseScore(A1,A2,B1,B2:Integer;Var Score:TIntArray);
Var
 Prev,Cur:TIntArray;
 I,J,M,V:Integer;
Begin
 M:=B2-B1+1;
 For J:=0 to M do Prev[J]:=0;
 For I:=A2 downto A1 do Begin
  Cur[0]:=0;
  For J:=1 to M do Begin
   If SameLine(I,B2-J+1)Then Cur[J]:=Prev[J-1]+1
   Else Begin
    V:=Prev[J];
    If Cur[J-1]>V Then V:=Cur[J-1];
    Cur[J]:=V;
   End;
  End;
  For J:=0 to M do Prev[J]:=Cur[J];
 End;
 For J:=0 to M do Score[J]:=Prev[J];
End;

Procedure DiffRange(A1,A2,B1,B2:Integer);
Var
 AMid,J,K,M,BestJ,Best,V:Integer;
 Found:Boolean;
Begin
 If A1>A2 Then Begin
  For J:=B1 to B2 do AddOp(_Insert,0,J);
  Exit;
 End;
 If B1>B2 Then Begin
  For J:=A1 to A2 do AddOp(_Delete,J,0);
  Exit;
 End;
 If A1=A2 Then Begin
  Found:=False;
  For J:=B1 to B2 do
   If SameLine(A1,J)Then Begin
    For K:=B1 to J-1 do AddOp(_Insert,0,K);
    AddOp(_Equal,A1,J);
    For K:=J+1 to B2 do AddOp(_Insert,0,K);
    Found:=True;
    Break;
   End;
  If Not Found Then Begin
   AddOp(_Delete,A1,0);
   For J:=B1 to B2 do AddOp(_Insert,0,J);
  End;
  Exit;
 End;
 AMid:=(A1+A2)div 2;
 M:=B2-B1+1;
 ForwardScore(A1,AMid,B1,B2,Score1^);
 ReverseScore(AMid+1,A2,B1,B2,Score2^);
 Best:=-1;
 BestJ:=0;
 For J:=0 to M do Begin
  V:=Score1^[J]+Score2^[M-J];
  If V>Best Then Begin
   Best:=V;
   BestJ:=J;
  End;
 End;
 DiffRange(A1,AMid,B1,B1+BestJ-1);
 DiffRange(AMid+1,A2,B1+BestJ,B2);
End;

Function HasDiff:Boolean;
Var
 I:Integer;
Begin
 HasDiff:=False;
 For I:=1 to OpCount do
  If OpKindAt(I)<>_Equal Then Begin
   HasDiff:=True;
   Exit;
  End;
End;

Function RangeText(Start,Count:Integer):String;
Begin
 If Count<=1 Then RangeText:=IntToStr(Start)
             Else RangeText:=IntToStr(Start)+','+IntToStr(Start+Count-1);
End;

Procedure PrintNormal;
Var
 I,J,K,OldLine,NewLine,OldStart,NewStart,DelCnt,InsCnt:Integer;
Begin
 I:=1;
 OldLine:=1;
 NewLine:=1;
 While I<=OpCount do Begin
  If OpKindAt(I)=_Equal Then Begin
   Inc(OldLine);
   Inc(NewLine);
   Inc(I);
  End
   Else
  Begin
   OldStart:=OldLine;
   NewStart:=NewLine;
   DelCnt:=0;
   InsCnt:=0;
   J:=I;
   While(J<=OpCount)and(OpKindAt(J)<>_Equal)do Begin
    If OpKindAt(J)=_Delete Then Begin
     Inc(DelCnt);
     Inc(OldLine);
    End
     Else
    Begin
     Inc(InsCnt);
     Inc(NewLine);
    End;
    Inc(J);
   End;
   If(DelCnt>0)and(InsCnt>0)Then
    WriteLn(RangeText(OldStart,DelCnt),'c',RangeText(NewStart,InsCnt))
   Else
   If DelCnt>0 Then
    WriteLn(RangeText(OldStart,DelCnt),'d',NewStart-1)
   Else
    WriteLn(OldStart-1,'a',RangeText(NewStart,InsCnt));
   For K:=I to J-1 do
    If OpKindAt(K)=_Delete Then WriteLn('< ',LineText(A^,OpAIndex(K)));
   If(DelCnt>0)and(InsCnt>0)Then WriteLn('---');
   For K:=I to J-1 do
    If OpKindAt(K)=_Insert Then WriteLn('> ',LineText(B^,OpBIndex(K)));
   I:=J;
  End;
 End;
End;

Procedure HunkOps(Var S,E:Integer);
Var
 I,C:Integer;
Begin
 S:=1;
 E:=OpCount;
 For I:=1 to OpCount do
  If OpKindAt(I)<>_Equal Then Begin
   S:=I;
   Break;
  End;
 For I:=OpCount downto 1 do
  If OpKindAt(I)<>_Equal Then Begin
   E:=I;
   Break;
  End;
 C:=0;
 While(S>1)and(C<ContextLines)do Begin
  Dec(S);
  If OpKindAt(S)=_Equal Then Inc(C);
 End;
 C:=0;
 While(E<OpCount)and(C<ContextLines)do Begin
  Inc(E);
  If OpKindAt(E)=_Equal Then Inc(C);
 End;
End;

Procedure UnifiedRange(S,E:Integer;Var OS,OC,NS,NC:Integer);
Var
 I:Integer;
Begin
 OS:=0;OC:=0;NS:=0;NC:=0;
 For I:=S to E do Begin
  If OpKindAt(I)<>_Insert Then Begin
   If OS=0 Then OS:=OpAIndex(I);
   Inc(OC);
  End;
  If OpKindAt(I)<>_Delete Then Begin
   If NS=0 Then NS:=OpBIndex(I);
   Inc(NC);
  End;
 End;
 If OS=0 Then OS:=1;
 If NS=0 Then NS:=1;
End;

Procedure PrintUnified;
Var
 I,S,E,OS,OC,NS,NC:Integer;
Begin
 WriteLn('--- ',Label1);
 WriteLn('+++ ',Label2);
 HunkOps(S,E);
 UnifiedRange(S,E,OS,OC,NS,NC);
 WriteLn('@@ -',OS,',',OC,' +',NS,',',NC,' @@');
 For I:=S to E do
  Case OpKindAt(I) of
   _Equal:WriteLn(' ',LineText(A^,OpAIndex(I)));
   _Delete:WriteLn('-',LineText(A^,OpAIndex(I)));
   _Insert:WriteLn('+',LineText(B^,OpBIndex(I)));
  End;
End;

Procedure PrintContext;
Var
 I,S,E,OS,OC,NS,NC:Integer;
Begin
 HunkOps(S,E);
 UnifiedRange(S,E,OS,OC,NS,NC);
 WriteLn('*** ',Label1);
 WriteLn('--- ',Label2);
 WriteLn('***************');
 WriteLn('*** ',RangeText(OS,OC),' ****');
 For I:=S to E do
  If OpKindAt(I)<>_Insert Then Begin
   If OpKindAt(I)=_Delete Then Write('! ')
                            Else Write('  ');
   WriteLn(LineText(A^,OpAIndex(I)));
  End;
 WriteLn('--- ',RangeText(NS,NC),' ----');
 For I:=S to E do
  If OpKindAt(I)<>_Delete Then Begin
   If OpKindAt(I)=_Insert Then Write('! ')
                            Else Write('  ');
   WriteLn(LineText(B^,OpBIndex(I)));
  End;
End;

Function PadRight(S:String;W:Integer):String;
Begin
 If Length(S)>W Then S:=Copy(S,1,W);
 While Length(S)<W do S:=S+' ';
 PadRight:=S;
End;

Procedure PrintSideBySide;
Var
 I,W:Integer;
 L,R,M:String;
Begin
 W:=(OutputWidth-5)div 2;
 If W<10 Then W:=10;
 For I:=1 to OpCount do Begin
  L:='';R:='';M:=' ';
  Case OpKindAt(I) of
   _Equal:Begin L:=LineText(A^,OpAIndex(I));R:=LineText(B^,OpBIndex(I));M:=' ';End;
   _Delete:Begin L:=LineText(A^,OpAIndex(I));M:='<';End;
   _Insert:Begin R:=LineText(B^,OpBIndex(I));M:='>';End;
  End;
  WriteLn(PadRight(L,W),' ',M,' ',R);
 End;
End;

Procedure Usage;Begin
 WriteLn('DIFF : Cette commande permet de comparer des fichiers ',
         'ligne par ligne.');
 WriteLn;
 WriteLn('Syntaxe : DIFF [options] fichier1 fichier2');
 WriteLn;
 WriteLn('Options principales compatibles avec GNU diff :');
 WriteLn('  -u, --unified[=N]             Format unifie');
 WriteLn('  -U N                          Format unifie avec N lignes de contexte');
 WriteLn('  -c, --context[=N]             Format contexte');
 WriteLn('  -C N                          Format contexte avec N lignes de contexte');
 WriteLn('  -y, --side-by-side            Affichage cote a cote');
 WriteLn('  -W N, --width=N               Largeur du format cote a cote');
 WriteLn('  -q, --brief                   Indique seulement si les fichiers different');
 WriteLn('  -s, --report-identical-files  Indique si les fichiers sont identiques');
 WriteLn('  -i, --ignore-case             Ignore la casse');
 WriteLn('  -w, --ignore-all-space        Ignore tous les espaces');
 WriteLn('  -b, --ignore-space-change     Ignore les changements de quantite d''espaces');
 WriteLn('  -B, --ignore-blank-lines      Ignore les lignes blanches');
 WriteLn('  -Z, --ignore-trailing-space   Ignore les espaces de fin de ligne');
 WriteLn('      --strip-trailing-cr       Retire CR en fin de ligne');
 WriteLn('  -L, --label=LIBELLE           Libelle pour formats -u et -c');
 WriteLn('  -N, --new-file                Fichier manquant considere vide');
 WriteLn('      --help, -h, /?            Affiche cette aide');
 WriteLn('      --version, -v             Affiche la version');
 WriteLn;
 WriteLn('Notes : cette version implemente le coeur texte de diff. Les formats');
 WriteLn('programmables GNU, scripts ed/RCS, couleurs et comparaison recursive de');
 WriteLn('repertoires ne sont pas inclus.');
End;

Function GetNum(S:String;Default:Integer):Integer;
Var
 N,Code:Integer;
Begin
 If S=''Then GetNum:=Default
 Else Begin
  Val(S,N,Code);
  If Code=0 Then GetNum:=N
            Else GetNum:=Default;
 End;
End;

Procedure AddFileName(S:String);
Begin
 If File1=''Then File1:=S
             Else
 If File2=''Then File2:=S
             Else Begin
  WriteLn('DIFF: trop de noms de fichiers: ',S);
  Halt(2);
 End;
End;

Procedure ParseArgs;
Var
 I,LabelCount:Integer;
 P,Q:String;
Begin
 Options:=[];
 OutMode:=_Normal;
 ContextLines:=3;
 OutputWidth:=130;
 File1:='';File2:='';
 Label1:='';Label2:='';
 LabelCount:=0;
 I:=1;
 While I<=ParamCount do Begin
  P:=ParamStr(I);
  Q:=Lower(P);
  If(P='/?')or(Q='--help')or(Q='-h')Then Begin Usage;Halt(0);End
  Else
  If(Q='--version')or(Q='-v')Then Begin WriteLn('DIFF Pascal 1.0');Halt(0);End
  Else
  If(P='-U')Then Begin
   Inc(I);
   If I<=ParamCount Then ContextLines:=GetNum(ParamStr(I),3);
   OutMode:=_Unified;
  End
  Else
  If Copy(P,1,2)='-U'Then Begin
   ContextLines:=GetNum(Copy(P,3,20),3);
   OutMode:=_Unified;
  End
  Else
  If(P='-C')Then Begin
   Inc(I);
   If I<=ParamCount Then ContextLines:=GetNum(ParamStr(I),3);
   OutMode:=_Context;
  End
  Else
  If Copy(P,1,2)='-C'Then Begin
   ContextLines:=GetNum(Copy(P,3,20),3);
   OutMode:=_Context;
  End
  Else
  If(P='-W')Then Begin
   Inc(I);
   If I<=ParamCount Then OutputWidth:=GetNum(ParamStr(I),130);
  End
  Else
  If Copy(P,1,2)='-W'Then OutputWidth:=GetNum(Copy(P,3,20),130)
  Else
  If(P='-L')Then Begin
   Inc(I);
   Inc(LabelCount);
   If I<=ParamCount Then Begin
    If LabelCount=1 Then Label1:=ParamStr(I)
                    Else Label2:=ParamStr(I);
   End;
  End
  Else
  If(Q='-u')or(Q='--unified')Then OutMode:=_Unified
  Else
  If Copy(Q,1,10)='--unified='Then Begin
   ContextLines:=GetNum(Copy(P,11,20),3);
   OutMode:=_Unified;
  End
  Else
  If(Q='-c')or(Q='--context')Then OutMode:=_Context
  Else
  If Copy(Q,1,10)='--context='Then Begin
   ContextLines:=GetNum(Copy(P,11,20),3);
   OutMode:=_Context;
  End
  Else
  If(Q='-y')or(Q='--side-by-side')Then OutMode:=_SideBySide
  Else
  If Copy(Q,1,8)='--width='Then OutputWidth:=GetNum(Copy(P,9,20),130)
  Else
  If Copy(Q,1,8)='--label='Then Begin
   Inc(LabelCount);
   If LabelCount=1 Then Label1:=Copy(P,9,255)
                   Else Label2:=Copy(P,9,255);
  End
  Else
  If(Q='-q')or(Q='--brief')Then Include(Options,_Brief)
  Else
  If(Q='-s')or(Q='--report-identical-files')Then Include(Options,_ReportSame)
  Else
  If(Q='-i')or(Q='--ignore-case')Then Include(Options,_IgnoreCase)
  Else
  If(P='-w')or(Q='--ignore-all-space')Then Include(Options,_IgnoreAllSpace)
  Else
  If(P='-b')or(Q='--ignore-space-change')Then Include(Options,_IgnoreSpaceChange)
  Else
  If(P='-B')or(Q='--ignore-blank-lines')Then Include(Options,_IgnoreBlankLines)
  Else
  If(P='-Z')or(Q='--ignore-trailing-space')Then Include(Options,_IgnoreTrailingSpace)
  Else
  If Q='--strip-trailing-cr'Then Include(Options,_StripTrailingCR)
  Else
  If(P='-N')or(Q='--new-file')Then Include(Options,_NewFile)
  Else
  If(Q='-a')or(Q='--text')or(Q='--binary')Then Begin
  End
  Else
  If Copy(P,1,1)='-'Then Begin
   WriteLn('DIFF: option non supportee: ',P);
   Halt(2);
  End
  Else AddFileName(P);
  Inc(I);
 End;
 If(File1='')or(File2='')Then Begin
  WriteLn('DIFF: deux fichiers sont requis.');
  WriteLn('Essayez DIFF --help pour plus d''information.');
  Halt(2);
 End;
 If Label1=''Then Label1:=File1;
 If Label2=''Then Label2:=File2;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  Usage;
  Halt;
 End;
 ParseArgs;
 InitFilesLists;
 ReadTextFile(File1,A^);
 ReadTextFile(File2,B^);
 ACount:=A^.Count;
 BCount:=B^.Count;
 InitOpList(OpList);
 InitScores;
 DiffRange(1,ACount,1,BCount);
 If HasDiff Then ExitCode:=1 Else ExitCode:=0;
 If _Brief in Options Then Begin
  If ExitCode=1 Then WriteLn('Les fichiers ',File1,' et ',File2,' sont differents');
 End
  Else
 If(ExitCode=0)and(_ReportSame in Options)Then
  WriteLn('Les fichiers ',File1,' et ',File2,' sont identiques')
 Else
 If ExitCode=1 Then Begin
  Case OutMode of
   _Unified:PrintUnified;
   _Context:PrintContext;
   _SideBySide:PrintSideBySide;
   Else PrintNormal;
  End;
 End;
 FreeScores;
 FreeOpList(OpList);
 FreeFilesLists;
 Halt(ExitCode);
END.
