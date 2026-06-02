{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program DIFF3;

Uses Dos;

Const
 MaxLines=4000;
 MaxHunks=4000;

Type
 TLine=String[255];
 PLineNode=^TLineNode;
 TLineNode=Record
  Text:TLine;
  Next:PLineNode;
 End;
 TLineIndex=Array[1..MaxLines]of PLineNode;
 TLineList=Record
  First,Last:PLineNode;
  Count:Integer;
  NoFinalNewline:Boolean;
  Index:TLineIndex;
 End;
 PLineList=^TLineList;
 TIntArray=Array[0..MaxLines]of Integer;
 PIntArray=^TIntArray;
 TOpKind=(_Equal,_Delete,_Insert);
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
 THunk=Record
  BaseStart,BaseCount:Integer;
  SideStart,SideCount:Integer;
 End;
 THunkArray=Array[1..MaxHunks]of THunk;
 PHunkArray=^THunkArray;
 TMode=(_Normal,_Merge,_Ed,_EdOverlap,_EdNoOverlap,_RCS);

Var
 File1,File2,File3:String;
 Label1,Label2,Label3:String;
 DiffProgram:String;
 A,Base,B:PLineList;
 OpList:TOpList;
 OpCount:Integer;
 H1,H3:PHunkArray;
 H1Count,H3Count:Integer;
 Score1,Score2:PIntArray;
 Mode:TMode;
 ShowAncestor,ExitConflicts,StripTrailingCR,EdAppendWQ:Boolean;
 ForceText,InitialTab,IgnoreCR,StdinUsed:Boolean;

Function Lower(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do
  If S[I]in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
 Lower:=S;
End;

Function IntToStr(N:LongInt):String;
Var
 S:String;
Begin
 Str(N,S);
 IntToStr:=S;
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

Function BinaryFile(Name:String):Boolean;
Var
 F:File;
 Buffer:Array[1..512]of Char;
 Readed,I:Integer;
Begin
 BinaryFile:=False;
 {$I-}Assign(F,Name);Reset(F,1);{$I+}
 If IOResult<>0 Then Exit;
 Repeat
  BlockRead(F,Buffer,SizeOf(Buffer),Readed);
  For I:=1 to Readed do
   If Buffer[I]=#0 Then Begin
    BinaryFile:=True;
    Close(F);
    Exit;
   End;
 Until Readed=0;
 Close(F);
End;

Function BinarySame(Name1,Name2:String):Boolean;
Var
 F1,F2:File;
 B1,B2:Array[1..1024]of Char;
 R1,R2,I:Integer;
Begin
 BinarySame:=False;
 {$I-}Assign(F1,Name1);Reset(F1,1);{$I+}
 If IOResult<>0 Then Exit;
 {$I-}Assign(F2,Name2);Reset(F2,1);{$I+}
 If IOResult<>0 Then Begin Close(F1);Exit;End;
 If FileSize(F1)<>FileSize(F2)Then Begin
  Close(F1);
  Close(F2);
  Exit;
 End;
 Repeat
  BlockRead(F1,B1,SizeOf(B1),R1);
  BlockRead(F2,B2,SizeOf(B2),R2);
  If R1<>R2 Then Begin Close(F1);Close(F2);Exit;End;
  For I:=1 to R1 do
   If B1[I]<>B2[I]Then Begin Close(F1);Close(F2);Exit;End;
 Until R1=0;
 Close(F1);
 Close(F2);
 BinarySame:=True;
End;

Function FileEndsWithLF(Name:String):Boolean;
Var
 F:File;
 C:Char;
 SizeF:LongInt;
 Readed:Integer;
Begin
 FileEndsWithLF:=True;
 {$I-}Assign(F,Name);Reset(F,1);{$I+}
 If IOResult<>0 Then Exit;
 SizeF:=FileSize(F);
 If SizeF=0 Then Begin Close(F);Exit;End;
 Seek(F,SizeF-1);
 BlockRead(F,C,1,Readed);
 Close(F);
 If Readed=1 Then FileEndsWithLF:=C=#10;
End;

Procedure InitLineList(Var L:TLineList);
Begin
 L.First:=Nil;
 L.Last:=Nil;
 L.Count:=0;
 L.NoFinalNewline:=False;
 FillChar(L.Index,SizeOf(L.Index),0);
End;

Procedure AddLine(Var L:TLineList;S:TLine);
Var
 N:PLineNode;
Begin
 If L.Count>=MaxLines Then Begin
  WriteLn('DIFF3: trop de lignes, maximum ',MaxLines,'.');
  Halt(2);
 End;
 New(N);
 If N=Nil Then Begin
  WriteLn('DIFF3: memoire insuffisante.');
  Halt(2);
 End;
 N^.Text:=S;
 N^.Next:=Nil;
 If L.First=Nil Then L.First:=N Else L.Last^.Next:=N;
 L.Last:=N;
 Inc(L.Count);
 L.Index[L.Count]:=N;
End;

Procedure FreeLineList(Var L:TLineList);
Var
 N,NextN:PLineNode;
Begin
 N:=L.First;
 While N<>Nil do Begin
  NextN:=N^.Next;
  Dispose(N);
  N:=NextN;
 End;
 InitLineList(L);
End;

Procedure InitFilesLists;
Begin
 A:=Nil;
 Base:=Nil;
 B:=Nil;
 New(A);
 New(Base);
 New(B);
 If(A=Nil)or(Base=Nil)or(B=Nil)Then Begin
  WriteLn('DIFF3: memoire insuffisante.');
  Halt(2);
 End;
 InitLineList(A^);
 InitLineList(Base^);
 InitLineList(B^);
End;

Procedure FreeFilesLists;
Begin
 If A<>Nil Then Begin
  FreeLineList(A^);
  Dispose(A);
  A:=Nil;
 End;
 If Base<>Nil Then Begin
  FreeLineList(Base^);
  Dispose(Base);
  Base:=Nil;
 End;
 If B<>Nil Then Begin
  FreeLineList(B^);
  Dispose(B);
  B:=Nil;
 End;
End;

Procedure InitHunks;
Begin
 H1:=Nil;
 H3:=Nil;
 New(H1);
 New(H3);
 If(H1=Nil)or(H3=Nil)Then Begin
  WriteLn('DIFF3: memoire insuffisante.');
  Halt(2);
 End;
 FillChar(H1^,SizeOf(THunkArray),0);
 FillChar(H3^,SizeOf(THunkArray),0);
 H1Count:=0;
 H3Count:=0;
End;

Procedure FreeHunks;
Begin
 If H1<>Nil Then Begin
  Dispose(H1);
  H1:=Nil;
 End;
 If H3<>Nil Then Begin
  Dispose(H3);
  H3:=Nil;
 End;
 H1Count:=0;
 H3Count:=0;
End;

Procedure InitOpList;
Begin
 OpList.First:=Nil;
 OpList.Last:=Nil;
 OpList.Count:=0;
 FillChar(OpList.Index,SizeOf(OpList.Index),0);
 OpCount:=0;
End;

Procedure FreeOpList;
Var
 N,NextN:POpNode;
Begin
 N:=OpList.First;
 While N<>Nil do Begin
  NextN:=N^.Next;
  Dispose(N);
  N:=NextN;
 End;
 InitOpList;
End;

Function OpKindAt(I:Integer):TOpKind;
Begin
 If(I<1)or(I>OpList.Count)or(OpList.Index[I]=Nil)Then OpKindAt:=_Equal
 Else OpKindAt:=OpList.Index[I]^.Op.Kind;
End;

Procedure NormalizeInputLine(Var S:TLine);
Var
 I:Integer;
Begin
 If StripTrailingCR Then
  If(Length(S)>0)and(S[Length(S)]=#13)Then Dec(S[0]);
 If IgnoreCR Then Begin
  I:=Length(S);
  While I>=1 do Begin
   If S[I]=#13 Then Delete(S,I,1);
   Dec(I);
  End;
 End;
End;

Function LineAt(Var L:TLineList;I:Integer):TLine;
Begin
 If(I<1)or(I>L.Count)or(L.Index[I]=Nil)Then LineAt:=''
 Else LineAt:=L.Index[I]^.Text;
End;

Procedure ReadFile(Name:String;Var L:TLineList);
Var
 F:Text;
 S:TLine;
Begin
 InitLineList(L);
 If Name='-'Then Begin
  If StdinUsed Then Begin
   WriteLn('DIFF3: entree standard deja utilisee');
   Halt(2);
  End;
  StdinUsed:=True;
  While Not EOF(Input)do Begin
   ReadLn(Input,S);
   NormalizeInputLine(S);
   AddLine(L,S);
  End;
  L.NoFinalNewline:=False;
  Exit;
 End;
 If Not FileExists(Name)Then Begin
  WriteLn('DIFF3: ',Name,': fichier introuvable');
  Halt(2);
 End;
 If(Not ForceText)and BinaryFile(Name)Then Begin
  WriteLn('DIFF3: ',Name,': fichier binaire');
  Halt(2);
 End;
 L.NoFinalNewline:=Not FileEndsWithLF(Name);
 Assign(F,Name);
 {$I-}Reset(F);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('DIFF3: impossible de lire ',Name);
  Halt(2);
 End;
 While Not EOF(F)do Begin
  ReadLn(F,S);
  NormalizeInputLine(S);
  AddLine(L,S);
 End;
 Close(F);
End;

Function SameLine(Var X,Y:TLineList;I,J:Integer):Boolean;
Begin
 SameLine:=LineAt(X,I)=LineAt(Y,J);
End;

Procedure InitScores;
Begin
 Score1:=Nil;
 Score2:=Nil;
 New(Score1);
 New(Score2);
 If(Score1=Nil)or(Score2=Nil)Then Begin
  WriteLn('DIFF3: memoire insuffisante.');
  Halt(2);
 End;
 FillChar(Score1^,SizeOf(TIntArray),0);
 FillChar(Score2^,SizeOf(TIntArray),0);
End;

Procedure FreeScores;
Begin
 If Score1<>Nil Then Dispose(Score1);
 If Score2<>Nil Then Dispose(Score2);
 Score1:=Nil;
 Score2:=Nil;
End;

Procedure AddOp(K:TOpKind;AI,BI:Integer);
Var
 N:POpNode;
Begin
 If OpList.Count>=High(OpList.Index)Then Begin
  WriteLn('DIFF3: trop de differences.');
  Halt(2);
 End;
 New(N);
 If N=Nil Then Begin
  WriteLn('DIFF3: memoire insuffisante.');
  Halt(2);
 End;
 N^.Op.Kind:=K;
 N^.Op.AIndex:=AI;
 N^.Op.BIndex:=BI;
 N^.Next:=Nil;
 If OpList.First=Nil Then OpList.First:=N
                     Else OpList.Last^.Next:=N;
 OpList.Last:=N;
 Inc(OpList.Count);
 OpList.Index[OpList.Count]:=N;
 OpCount:=OpList.Count;
End;

Procedure ForwardScore(Var X,Y:TLineList;A1,A2,B1,B2:Integer;
                       Var Score:TIntArray);
Var
 Prev,Cur:TIntArray;
 I,J,M,V:Integer;
Begin
 M:=B2-B1+1;
 For J:=0 to M do Prev[J]:=0;
 For I:=A1 to A2 do Begin
  Cur[0]:=0;
  For J:=1 to M do Begin
   If SameLine(X,Y,I,B1+J-1)Then Cur[J]:=Prev[J-1]+1
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

Procedure ReverseScore(Var X,Y:TLineList;A1,A2,B1,B2:Integer;
                       Var Score:TIntArray);
Var
 Prev,Cur:TIntArray;
 I,J,M,V:Integer;
Begin
 M:=B2-B1+1;
 For J:=0 to M do Prev[J]:=0;
 For I:=A2 downto A1 do Begin
  Cur[0]:=0;
  For J:=1 to M do Begin
   If SameLine(X,Y,I,B2-J+1)Then Cur[J]:=Prev[J-1]+1
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

Procedure DiffRange(Var X,Y:TLineList;A1,A2,B1,B2:Integer);
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
   If SameLine(X,Y,A1,J)Then Begin
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
 ForwardScore(X,Y,A1,AMid,B1,B2,Score1^);
 ReverseScore(X,Y,AMid+1,A2,B1,B2,Score2^);
 Best:=-1;
 BestJ:=0;
 For J:=0 to M do Begin
  V:=Score1^[J]+Score2^[M-J];
  If V>Best Then Begin
   Best:=V;
   BestJ:=J;
  End;
 End;
 DiffRange(X,Y,A1,AMid,B1,B1+BestJ-1);
 DiffRange(X,Y,AMid+1,A2,B1+BestJ,B2);
End;

Procedure AddHunk(Var H:THunkArray;Var HC:Integer;BS,BC,SS,SC:Integer);
Begin
 If(BC=0)and(SC=0)Then Exit;
 If HC>=MaxHunks Then Begin
  WriteLn('DIFF3: trop de blocs de differences.');
  Halt(2);
 End;
 Inc(HC);
 H[HC].BaseStart:=BS;
 H[HC].BaseCount:=BC;
 H[HC].SideStart:=SS;
 H[HC].SideCount:=SC;
End;

Function QuoteArg(S:String):String;
Begin
 If Pos(' ',S)>0 Then QuoteArg:='"'+S+'"'
               Else QuoteArg:=S;
End;

Procedure DeleteTempFile(Name:String);
Var
 F:File;
Begin
 {$I-}Assign(F,Name);Erase(F);{$I+}
 If IOResult<>0 Then;
End;

Function IsDigitChar(C:Char):Boolean;
Begin
 IsDigitChar:=C in['0'..'9'];
End;

Procedure ReadNumber(S:String;Var P,N:Integer);
Begin
 N:=0;
 While(P<=Length(S))and IsDigitChar(S[P])do Begin
  N:=N*10+Ord(S[P])-Ord('0');
  Inc(P);
 End;
End;

Function ParseDiffHeader(S:String;Var BS,BC,SS,SC:Integer):Boolean;
Var
 P,L1,L2,R1,R2:Integer;
 Cmd:Char;
Begin
 ParseDiffHeader:=False;
 If Length(S)=0 Then Exit;
 If Not IsDigitChar(S[1])Then Exit;
 P:=1;
 ReadNumber(S,P,L1);
 L2:=L1;
 If(P<=Length(S))and(S[P]=',')Then Begin
  Inc(P);
  ReadNumber(S,P,L2);
 End;
 If P>Length(S)Then Exit;
 Cmd:=S[P];
 If Not(Cmd in['a','c','d'])Then Exit;
 Inc(P);
 If(P>Length(S))or(Not IsDigitChar(S[P]))Then Exit;
 ReadNumber(S,P,R1);
 R2:=R1;
 If(P<=Length(S))and(S[P]=',')Then Begin
  Inc(P);
  ReadNumber(S,P,R2);
 End;
 Case Cmd of
  'a':Begin
       BS:=L2+1;
       BC:=0;
       SS:=R1;
       SC:=R2-R1+1;
      End;
  'd':Begin
       BS:=L1;
       BC:=L2-L1+1;
       SS:=R2+1;
       SC:=0;
      End;
  Else Begin
       BS:=L1;
       BC:=L2-L1+1;
       SS:=R1;
       SC:=R2-R1+1;
      End;
 End;
 ParseDiffHeader:=True;
End;

Function ParseExternalDiff(OutName:String;Var H:THunkArray;
                           Var HC:Integer):Boolean;
Var
 F:Text;
 S:TLine;
 BS,BC,SS,SC:Integer;
Begin
 ParseExternalDiff:=False;
 HC:=0;
 {$I-}Assign(F,OutName);Reset(F);{$I+}
 If IOResult<>0 Then Exit;
 While Not EOF(F)do Begin
  ReadLn(F,S);
  If ParseDiffHeader(S,BS,BC,SS,SC)Then
   AddHunk(H,HC,BS,BC,SS,SC);
 End;
 Close(F);
 ParseExternalDiff:=True;
End;

Function RunExternalDiff(CommonName,SideName,OutName:String):Boolean;
Var
 Shell,Cmd:String;
Begin
 RunExternalDiff:=False;
 If DiffProgram=''Then Exit;
 If(CommonName='-')or(SideName='-')Then Exit;
 Shell:=GetEnv('COMSPEC');
 If Shell=''Then Shell:=GetEnv('SHELL');
 If Shell=''Then Exit;
 If Pos('\',Shell)>0 Then
  Cmd:='/C '+DiffProgram+' '+QuoteArg(CommonName)+' '+QuoteArg(SideName)+
       ' > '+QuoteArg(OutName)
 Else
  Cmd:='-c "'+DiffProgram+' '+QuoteArg(CommonName)+' '+QuoteArg(SideName)+
       ' > '+QuoteArg(OutName)+'"';
 SwapVectors;
 Exec(Shell,Cmd);
 SwapVectors;
 RunExternalDiff:=(DosError=0)and(DosExitCode<2);
End;

Function BuildHunksWithExternal(SideName,CommonName:String;
                                Var H:THunkArray;Var HC:Integer):Boolean;
Var
 OutName:String;
Begin
 BuildHunksWithExternal:=False;
 If DiffProgram=''Then Exit;
 OutName:='DIFF3'+IntToStr(Random(30000))+'.TMP';
 DeleteTempFile(OutName);
 If RunExternalDiff(CommonName,SideName,OutName)Then
  If ParseExternalDiff(OutName,H,HC)Then
   If(HC>0)or BinarySame(CommonName,SideName)Then
    BuildHunksWithExternal:=True;
 DeleteTempFile(OutName);
End;

Procedure BuildHunks(Var Side,Common:TLineList;SideName,CommonName:String;
                     Var H:THunkArray;
                     Var HC:Integer);
Var
 I,J,OldLine,NewLine,BaseStart,SideStart,BaseCnt,SideCnt:Integer;
Begin
 If BuildHunksWithExternal(SideName,CommonName,H,HC)Then Exit;
 InitOpList;
 DiffRange(Common,Side,1,Common.Count,1,Side.Count);
 HC:=0;
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
   BaseStart:=OldLine;
   SideStart:=NewLine;
   BaseCnt:=0;
   SideCnt:=0;
   J:=I;
   While(J<=OpCount)and(OpKindAt(J)<>_Equal)do Begin
    If OpKindAt(J)=_Delete Then Begin
     Inc(BaseCnt);
     Inc(OldLine);
    End
     Else
    Begin
     Inc(SideCnt);
     Inc(NewLine);
    End;
    Inc(J);
   End;
   AddHunk(H,HC,BaseStart,BaseCnt,SideStart,SideCnt);
   I:=J;
  End;
 End;
 FreeOpList;
End;

Function EndBase(H:THunk):Integer;
Begin
 If H.BaseCount=0 Then EndBase:=H.BaseStart-1
                  Else EndBase:=H.BaseStart+H.BaseCount-1;
End;

Function RangeTxt(Start,Count:Integer):String;
Begin
 If Count<=0 Then RangeTxt:=IntToStr(Start-1)
 Else
 If Count=1 Then RangeTxt:=IntToStr(Start)
             Else RangeTxt:=IntToStr(Start)+','+IntToStr(Start+Count-1);
End;

Procedure PrintLines(Var L:TLineList;S,C:Integer);
Var
 I:Integer;
Begin
 For I:=S to S+C-1 do Begin
  WriteLn(LineAt(L,I));
  If L.NoFinalNewline and(I=L.Count)Then
   WriteLn('\ No newline at end of file');
 End;
End;

Procedure PrintNormalLines(Var L:TLineList;S,C:Integer);
Var
 I:Integer;
Begin
 For I:=S to S+C-1 do Begin
  If InitialTab Then Write(#9) Else Write('  ');
  WriteLn(LineAt(L,I));
  If L.NoFinalNewline and(I=L.Count)Then
   WriteLn('\ No newline at end of file');
 End;
End;

Function SameRange(Var X,Y:TLineList;XS,XC,YS,YC:Integer):Boolean;
Var
 I:Integer;
Begin
 If XC<>YC Then Begin SameRange:=False;Exit;End;
 For I:=0 to XC-1 do
  If LineAt(X,XS+I)<>LineAt(Y,YS+I)Then Begin
   SameRange:=False;
   Exit;
  End;
 SameRange:=True;
End;

Procedure PrintNormalGroup(StartBase,EndB,H1I,H3I:Integer);
Begin
 WriteLn('====');
 If H1I>0 Then Begin
  WriteLn('1:',RangeTxt(H1^[H1I].SideStart,H1^[H1I].SideCount),'c');
  PrintNormalLines(A^,H1^[H1I].SideStart,H1^[H1I].SideCount);
 End
  Else
 Begin
  WriteLn('1:',RangeTxt(StartBase,EndB-StartBase+1),'c');
  PrintNormalLines(Base^,StartBase,EndB-StartBase+1);
 End;
 WriteLn('2:',RangeTxt(StartBase,EndB-StartBase+1),'c');
 PrintNormalLines(Base^,StartBase,EndB-StartBase+1);
 If H3I>0 Then Begin
  WriteLn('3:',RangeTxt(H3^[H3I].SideStart,H3^[H3I].SideCount),'c');
  PrintNormalLines(B^,H3^[H3I].SideStart,H3^[H3I].SideCount);
 End
  Else
 Begin
  WriteLn('3:',RangeTxt(StartBase,EndB-StartBase+1),'c');
  PrintNormalLines(Base^,StartBase,EndB-StartBase+1);
 End;
End;

Procedure PrintConflict(BS,BC,S1,C1,S3,C3:Integer);
Begin
 WriteLn('<<<<<<< ',Label1);
 PrintLines(A^,S1,C1);
 If ShowAncestor Then Begin
  WriteLn('||||||| ',Label2);
  PrintLines(Base^,BS,BC);
 End;
 WriteLn('=======');
 PrintLines(B^,S3,C3);
 WriteLn('>>>>>>> ',Label3);
 ExitConflicts:=True;
End;

Procedure PrintEdConflict(BS,BC,S1,C1,S3,C3:Integer);
Begin
 WriteLn('<<<<<<< ',Label1);
 PrintLines(A^,S1,C1);
 If ShowAncestor Then Begin
  WriteLn('||||||| ',Label2);
  PrintLines(Base^,BS,BC);
 End;
 WriteLn('=======');
 PrintLines(B^,S3,C3);
 WriteLn('>>>>>>> ',Label3);
End;

Procedure OutputGroup(BS,BE,H1I,H3I:Integer);
Var
 H1Here,H3Here:Boolean;
 S1,C1,S3,C3,BC:Integer;
Begin
 H1Here:=H1I>0;
 H3Here:=H3I>0;
 BC:=BE-BS+1;
 If H1Here Then Begin S1:=H1^[H1I].SideStart;C1:=H1^[H1I].SideCount;End
           Else Begin S1:=BS;C1:=BC;End;
 If H3Here Then Begin S3:=H3^[H3I].SideStart;C3:=H3^[H3I].SideCount;End
           Else Begin S3:=BS;C3:=BC;End;
 If Mode=_Merge Then Begin
  If H1Here and Not H3Here Then PrintLines(A^,S1,C1)
  Else
  If H3Here and Not H1Here Then PrintLines(B^,S3,C3)
  Else
  If SameRange(A^,B^,S1,C1,S3,C3)Then PrintLines(A^,S1,C1)
  Else PrintConflict(BS,BC,S1,C1,S3,C3);
 End
  Else
 If(Mode=_Ed)or(Mode=_EdOverlap)or(Mode=_EdNoOverlap)or(Mode=_RCS)Then Begin
  If H3Here and Not H1Here Then Begin
   If Mode=_EdOverlap Then Exit;
   If Mode=_RCS Then WriteLn('a',BS-1,' ',C3)
   Else WriteLn(BS-1,'a');
   PrintLines(B^,S3,C3);
   If Mode<>_RCS Then WriteLn('.');
  End
  Else
  If H3Here and H1Here Then Begin
   If Mode<>_EdNoOverlap Then Begin
    If Not SameRange(A^,B^,S1,C1,S3,C3)Then Begin
     If Mode=_RCS Then WriteLn('d',BS,' ',BC)
     Else WriteLn(RangeTxt(BS,BC),'c');
     If ShowAncestor Then PrintEdConflict(BS,BC,S1,C1,S3,C3)
                     Else PrintLines(B^,S3,C3);
     If Mode<>_RCS Then WriteLn('.');
    End;
   End;
  End;
 End
  Else PrintNormalGroup(BS,BE,H1I,H3I);
End;

Procedure DoDiff3;
Var
 I1,I3,PosB,StartB,EndB,Use1,Use3:Integer;
 H1Here,H3Here:Boolean;
Begin
 I1:=1;
 I3:=1;
 PosB:=1;
 ExitConflicts:=False;
 While(I1<=H1Count)or(I3<=H3Count)do Begin
  H1Here:=(I1<=H1Count);
  H3Here:=(I3<=H3Count);
  If H1Here and ((Not H3Here)or(H1^[I1].BaseStart<=H3^[I3].BaseStart))Then
   StartB:=H1^[I1].BaseStart
  Else StartB:=H3^[I3].BaseStart;
  If Mode=_Merge Then PrintLines(Base^,PosB,StartB-PosB);
  EndB:=StartB-1;
  H1Here:=False;
  H3Here:=False;
  If(I1<=H1Count)and
    ((H1^[I1].BaseStart=StartB)or(H1^[I1].BaseStart<=EndB))Then Begin
   H1Here:=True;
   If EndBase(H1^[I1])>EndB Then EndB:=EndBase(H1^[I1]);
  End;
  If(I3<=H3Count)and
    ((H3^[I3].BaseStart=StartB)or(H3^[I3].BaseStart<=EndB))Then Begin
   H3Here:=True;
   If EndBase(H3^[I3])>EndB Then EndB:=EndBase(H3^[I3]);
  End;
  If H1Here Then Use1:=I1 Else Use1:=0;
  If H3Here Then Use3:=I3 Else Use3:=0;
  OutputGroup(StartB,EndB,Use1,Use3);
  If H1Here Then Inc(I1);
  If H3Here Then Inc(I3);
  PosB:=EndB+1;
 End;
 If Mode=_Merge Then PrintLines(Base^,PosB,Base^.Count-PosB+1);
 If EdAppendWQ and
   ((Mode=_Ed)or(Mode=_EdOverlap)or(Mode=_EdNoOverlap))Then Begin
  WriteLn('w');
  WriteLn('q');
 End;
 If ExitConflicts Then Halt(1);
End;

Procedure Usage;
Begin
 WriteLn('DIFF3 : Cette commande permet de comparer trois fichiers ligne par ligne.');
 WriteLn;
 WriteLn('Syntaxe : DIFF3 [options] fichier1 ancetre fichier3');
 WriteLn;
 WriteLn('Options :');
 WriteLn('  -m, --merge        Fusionne les trois fichiers');
 WriteLn('  -A, --show-all     Fusion avec ancetre dans les conflits');
 WriteLn('  -e, --ed           Script ed avec les changements de fichier3');
 WriteLn('  -E, --show-overlap Comme -e, avec conflits marques');
 WriteLn('  -x, --overlap-only Script ed seulement pour conflits');
 WriteLn('  -X                 Comme -x, avec conflits marques');
 WriteLn('  -3, --easy-only    Script ed seulement pour changements simples');
 WriteLn('  -n, --rcs          Produit un script RCS');
 WriteLn('  -i                 Ajoute w et q aux scripts ed');
 WriteLn('  -L LABEL           Etiquette; peut etre repetee trois fois');
 WriteLn('  -a, --text         Traite les fichiers comme du texte');
 WriteLn('  -T, --initial-tab  Aligne les lignes avec une tabulation');
 WriteLn('      --strip-trailing-cr  Supprime CR en fin de ligne');
 WriteLn('      --ignore-cr    Supprime tous les CR dans les lignes');
 WriteLn('      --diff-program=PROG  Accepte pour compatibilite');
 WriteLn('      --help         Affiche cette aide');
 WriteLn('      --version      Affiche la version');
End;

Procedure ParseArgs;
Var
 I,LC:Integer;
 P,Q:String;
Begin
 Mode:=_Normal;
 ShowAncestor:=False;
 StripTrailingCR:=False;
 EdAppendWQ:=False;
 ForceText:=False;
 InitialTab:=False;
 IgnoreCR:=False;
 StdinUsed:=False;
 DiffProgram:='';
 File1:='';File2:='';File3:='';
 Label1:='';Label2:='';Label3:='';
 LC:=0;
 I:=1;
 While I<=ParamCount do Begin
  P:=ParamStr(I);
  Q:=Lower(P);
  If(P='/?')or(Q='--help')or(Q='-h')Then Begin Usage;Halt(0);End
  Else
  If(Q='--version')or(Q='-v')Then Begin WriteLn('DIFF3 Pascal 1.0');Halt(0);End
  Else
  If P='-E'Then Begin Mode:=_Ed;ShowAncestor:=True;End
  Else
  If P='-X'Then Begin Mode:=_EdOverlap;ShowAncestor:=True;End
  Else
  If P='-A'Then Begin Mode:=_Merge;ShowAncestor:=True;End
  Else
  If(Q='-m')or(Q='--merge')Then Mode:=_Merge
  Else
  If(Q='-e')or(Q='--ed')or(Q='--show-overlap')Then Mode:=_Ed
  Else
  If(Q='-x')or(Q='--overlap-only')Then Mode:=_EdOverlap
  Else
  If(Q='-3')or(Q='--easy-only')Then Mode:=_EdNoOverlap
  Else
  If(Q='-n')or(Q='--rcs')Then Mode:=_RCS
  Else
  If(Q='--show-all')Then Begin Mode:=_Merge;ShowAncestor:=True;End
  Else
 If Q='--strip-trailing-cr'Then StripTrailingCR:=True
 Else
 If(Q='--ignore-cr')or(Q='--ignore-carriage-return')Then IgnoreCR:=True
  Else
  If Q='-i'Then EdAppendWQ:=True
  Else
  If(Q='-t')or(Q='--initial-tab')Then InitialTab:=True
  Else
  If Copy(Q,1,15)='--diff-program='Then DiffProgram:=Copy(P,16,255)
  Else
  If Q='--diff-program'Then Begin
   Inc(I);
   If I<=ParamCount Then DiffProgram:=ParamStr(I);
  End
  Else
  If(Q='-a')or(Q='--text')Then ForceText:=True
  Else
  If(P='-L')or(Q='--label')Then Begin
   Inc(I);
   Inc(LC);
   If I<=ParamCount Then Begin
    If LC=1 Then Label1:=ParamStr(I)
    Else If LC=2 Then Label2:=ParamStr(I)
    Else Label3:=ParamStr(I);
   End;
  End
  Else
  If Copy(Q,1,8)='--label='Then Begin
   Inc(LC);
   If LC=1 Then Label1:=Copy(P,9,255)
   Else If LC=2 Then Label2:=Copy(P,9,255)
   Else Label3:=Copy(P,9,255);
  End
  Else
 If(Copy(P,1,1)='-')and(P<>'-')Then Begin
   WriteLn('DIFF3: option non supportee: ',P);
   Halt(2);
  End
  Else Begin
   If File1=''Then File1:=P
   Else If File2=''Then File2:=P
   Else If File3=''Then File3:=P
   Else Begin
    WriteLn('DIFF3: trop de fichiers');
    Halt(2);
   End;
  End;
  Inc(I);
 End;
 If(File1='')or(File2='')or(File3='')Then Begin
  WriteLn('DIFF3: trois fichiers sont requis.');
  Halt(2);
 End;
 If Label1=''Then Label1:=File1;
 If Label2=''Then Label2:=File2;
 If Label3=''Then Label3:=File3;
End;

Procedure HandleBinaryFiles;
Var
 BA,BB,BC:Boolean;
Begin
 If ForceText Then Exit;
 If(File1='-')or(File2='-')or(File3='-')Then Exit;
 BA:=BinaryFile(File1);
 BB:=BinaryFile(File2);
 BC:=BinaryFile(File3);
 If BA or BB or BC Then Begin
  If BinarySame(File1,File2)and BinarySame(File2,File3)Then Halt(0);
  WriteLn('DIFF3: fichiers binaires differents');
  Halt(1);
 End;
End;

BEGIN
 Randomize;
 ParseArgs;
 HandleBinaryFiles;
 InitScores;
 InitFilesLists;
 ReadFile(File1,A^);
 ReadFile(File2,Base^);
 ReadFile(File3,B^);
 InitHunks;
 BuildHunks(A^,Base^,File1,File2,H1^,H1Count);
 BuildHunks(B^,Base^,File3,File2,H3^,H3Count);
 DoDiff3;
 FreeScores;
 FreeHunks;
 FreeFilesLists;
END.
