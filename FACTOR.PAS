{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program FACTOR;

Const
 PrimeNumber:Array[1..100]of Integer=(
  2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,
  73,79,83,89,97,101,103,107,109,113,127,131,137,139,
  149,151,157,163,167,173,179,181,191,193,197,199,211,223,227,229,233,239,
  241,251,257,263,269,271,277,281,283,293,307,311,313,317,331,337,347,349,
  353,359,367,373,379,383,389,397,401,409,419,421,431,433,439,443,449,457,
  461,463,467,479,487,491,499,503,509,521,523,541
 );

Var
 I,Value,Reduce:LongInt;
 Err:Word;
 ReadNumber:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('FACTOR : Cette commande permet de calculer le facteur d''un nombre.');
  WriteLn;
  WriteLn('Syntaxe : FACTOR [nombre]');
 End
  Else
 If ParamCount>0Then Begin
  Val(ParamStr(1),Value,Err);
 End
  Else
 Begin
  ReadLn(ReadNumber);
  Val(ReadNumber,Value,Err);
 End;
 Write(Value,': ');
 If Value>1Then Begin
  Reduce:=Value;
  For I:=Low(PrimeNumber) to High(PrimeNumber) do Begin
   While((Reduce mod PrimeNumber[I])=0)and((Reduce div PrimeNumber[I])>0)do Begin
    Reduce:=Reduce div PrimeNumber[I];
    Write(PrimeNumber[I],' ');
   End;
  End;
 End;
 WriteLn;
END.