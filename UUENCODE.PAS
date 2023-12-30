{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program UUENCODE;

{$A-}

Const
 SP=Byte(' ');

Type
 TTriplet=Array[0..2] of Byte;
 TKwartet=Array[0..3] of Byte;

Var
 Triplets:Array[1..15] of TTriplet;
 kwar:TKwartet;
 FileName:String[12];
 i,j:Integer;
 f:File;
 g:Text;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Procedure Triplet2Kwartet(Triplet:TTriplet;Var Kwartet:TKwartet);
Var
 I:Integer;
Begin
 Kwartet[0]:=(Triplet[0]SHR 2);
 Kwartet[1]:=((Triplet[0]SHL 4)AND $30)+((Triplet[1]SHR 4)AND $0F);
 Kwartet[2]:=((Triplet[1]SHL 2)AND $3C)+((Triplet[2]SHR 6)AND $03);
 Kwartet[3]:=(Triplet[2]AND $3F);
 For I:=0 to 3 do Begin
  If Kwartet[i]=0 then Kwartet[i]:=$40;
  Inc(Kwartet[i],SP)
 End
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Writeln('UUENCODE : Cette commande permet d''effectuer un encodage ',
                      'd''un fichier binaire.');
  WriteLn;
  WriteLn('Syntaxe:  UUENCODE infile [outfile]');
 End
  Else
 If ParamCount>0Then Begin
  If StrToUpper(ParamStr(1))=StrToUpper(ParamStr(2))Then Begin
   Writeln('Erreur: Le fichier source est identique au fichier de destination');
   Halt(1)
  End;
  {$I-}Assign(f,ParamStr(1));
  FileMode := $40;
  Reset(f,1);{$I+}
  If IOResult<>0 Then Begin
   Writeln('Erreur: Impossible d''ouvrir le fichier ',ParamStr(1));
   Halt(2)
  End;
  If ParamCount<>2 Then Begin
   FileName:=ParamStr(1);
   i:=Pos('.',FileName);
   if i>0 then Delete(FileName,i,Length(FileName));
   FileName:=FileName+'.UUE'
  End
   Else
  FileName:=ParamStr(2);
  If StrToUpper(ParamStr(1))=StrToUpper(FileName)Then Begin
   writeln('Erreur: Fichier source identique au fichier de destination');
   Halt(1)
  End;
  Assign(g,FileName);
  If ParamCount>1 Then Begin
   {$I-}FileMode:=$02;
   Reset(g);{$I+}
   If IOResult=0 Then Begin
    Writeln('Erreur: Fichier ',FileName,' d‚j… exisant.');
    Halt(3)
   End
  End;
  Rewrite(g);
  If IOResult<>0 Then Begin
   Writeln('Erreur: Impossible de cr‚er le fichier ',FileName);
   Halt(4)
  End;
  Writeln(G,'begin 0777 ',ParamStr(1));
  Repeat
   FillChar(Triplets,SizeOf(Triplets),#0);
   BlockRead(f,Triplets,SizeOf(Triplets),i);
   Write(g,Char(SP+i));
   For J:=1 to (i+2) div 3 do Begin
   Triplet2Kwartet(Triplets[j],kwar);
   Write(g,Char(kwar[0]),Char(kwar[1]),Char(kwar[2]),Char(kwar[3]));
  End;
  Writeln(g)
  Until (i < SizeOf(Triplets));
  Writeln(g,'end');
  Close(f);
  Close(g);
  If ParamCount>1 Then Writeln('Fichier UUEnCoded ',FileName,' cr‚‚.');
  Writeln;
 End;
END.
