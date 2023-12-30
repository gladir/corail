{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program UUDECODE;

{$A-}

Const
 SP=Byte(' ');

Type
 TTriplet=Array[0..2] of Byte;
 TKwartet=Array[0..3] of Byte;

Var
 ByteWrited:Word;
 F:Text;
 G:File;
 FileName:String[12];
 Buffer:String;
 Kwartets:Record
  Lengte:Byte;
  aantal:Byte;
  kwart:Array[1..64] of TKwartet;
 End Absolute Buffer;
 Trip:TTriplet;
 I:Integer;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Procedure Kwartet2Triplet(Kwartet:TKwartet;Var Triplet:TTriplet);Begin
 Triplet[0]:=((Kwartet[0]-SP)SHL 2)+(((Kwartet[1]-SP) AND $30)SHR 4);
 Triplet[1]:=(((Kwartet[1]-SP)AND $0F)SHL 4)+(((Kwartet[2]-SP)AND $3C) SHR 2);
 Triplet[2]:=(((Kwartet[2]-SP) AND $03)SHL 6)+((Kwartet[3]-SP)AND $3F)
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Writeln('UUDECODE : Cette commande permet d''effectuer le d‚codage ',
                      'd''un fichier binaire de format UUE.');
  WriteLn;
  WriteLn('Syntaxe:  UUDECODE infile [outfile]');
 End
  Else
 If ParamCount>0Then Begin
  If StrToUpper(ParamStr(1))=StrToUpper(ParamStr(2))Then Begin
   Writeln('Erreur: Le fichier source est identique au fichier de destination');
   Halt(1)
  End;
  {$I-}Assign(f,ParamStr(1));
  FileMode:=$40;
  Reset(f);{$I+}
  If IOResult<>0 Then Begin
   Writeln('Erreur: Impossible d''ouvrir le fichier ',ParamStr(1));
   Halt(2)
  End;
  Repeat
   ReadLn(F,Buffer)
  Until EOF(f)or(Copy(Buffer,1,5)='begin');
  If Buffer[11]=#32 Then FileName:=Copy(Buffer,12,12)Else
  If Buffer[10]=#32 Then FileName:=Copy(Buffer,11,12)
                    Else FileName:=ParamStr(2);
  If StrToUpper(ParamStr(1))=StrToUpper(FileName)Then Begin
   Writeln('Erreur: Fichier source identique au fichier de destination');
   Halt(1)
  End;
  Assign(g,FileName);
  If ParamCount>1 Then Begin
   {$I-}FileMode:=$02;
   Reset(G,1);{$I+}
   If IOResult=0 Then Begin
    Writeln('Erreur: Fichier ',FileName,' d‚j… exisant.');
    Halt(3)
   End
  End;
  {$I-}Rewrite(G,1);{$I+}
  If IOResult<>0 Then Begin
   Writeln('Erreur: Impossible de cr‚er le fichier ',FileName);
   Halt(4)
  End;
  While(Not EOF(f))and(Buffer<>'end')do Begin
   FillChar(Buffer,SizeOf(Buffer),#32);
   ReadLn(f,Buffer);
   If Buffer<>'end'Then Begin
    For I:=1 to (Kwartets.aantal-32) div 3 do Begin
     Kwartet2Triplet(Kwartets.kwart[i],Trip);
     BlockWrite(G,Trip[0],3,ByteWrited)
    End;
    If((Kwartets.aantal-32) mod 3)>0 Then Begin
     Kwartet2Triplet(Kwartets.kwart[i+1],Trip);
     For I:=1 to ((Kwartets.aantal-32) mod 3) do Begin
      BlockWrite(g,Trip[i-1],1,ByteWrited)
     End;
    End
   End
  End;
  Close(F);
  Close(G);
  If ParamCount>1 Then Writeln('Fichier UUDeCoded ',FileName,' cr‚‚.');
  Writeln;
 End;
END.
