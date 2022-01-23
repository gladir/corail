{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal)
}

Program EMSTEST;

Uses Crt,DOS;

Const
 IntrEMS=$67;

Var
 I,TestHandle,Size:Integer;
 EmmError:Byte;
 Intr67h:Pointer;
 
Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End; 

Function EmsInst:Boolean;
Type  
 EmmName=Array[1..8] of Char;              
 EmmNaPtr=^EmmName;
Const 
 Name:EmmName='EMMXXXX0'; 
Var 
 Regs:Registers;
Begin
 Regs.AH:=$35;
 Regs.AL:=IntrEMS; 
 MsDos(Regs);                       
 EmsInst:=(EmmNaPtr(Ptr(Regs.ES,10))^=Name);
End;

Function EmsVersion:Integer;
Var 
 Regs:Registers;
Begin
 Regs.AH:=$46;
 Intr(IntrEMS,Regs);                                   
 If Regs.AH<>0 Then Begin                                                        
  EmmError:=Regs.AH;
  EmsVersion:=-1;
 End
  else   
 EmsVersion:=Regs.AL;
End;

Function EmsFrameSeg:Word;
Var 
 Regs:Registers;
Begin
 Regs.AH:=$41;            
  Intr(IntrEMS,Regs);                                   
  If Regs.AH<>0 Then Begin                                                        
   EmmError:=Regs.AH;
   EmsFrameSeg:=$FFFF;                    
 End
  Else                                                  
 EmsFrameSeg:=Regs.BX;   
End;

Function EmsNumTotalPage:Integer;
Var 
 Regs:Registers;
Begin
 Regs.AH:=$42;                
 Intr(IntrEMS,Regs);
 If Regs.AH<>0 Then Begin                                                        
  EmmError:=Regs.AH;
  EmsNumTotalPage:=-1;
 End
  Else                                                  
 EmsNumTotalPage:=Regs.DX;
End;

Function EmsNumUsedPage:Integer;
Var 
 Regs:Registers;
Begin
 Regs.AH:=$4B;
 Intr(IntrEMS,Regs);
 If Regs.AH<>0 Then Begin                                                        
  EmmError:=Regs.AH;
  EmsNumUsedPage:=-1;
 End
  Else                                                  
 EmsNumUsedPage:=Regs.BX;
End;


Function EmsUsedPage(Handle:Word):Integer;
Var 
 Regs:Registers;   
Begin
 Regs.AH:=$4C;
 Regs.DX:=0;
 Intr(IntrEMS,Regs);
 If Regs.AH<>0 Then Begin
  EmmError:=Regs.AH;
  EmsUsedPage:=-1;
 End
  Else                                                  
 EmsUsedPage:=Regs.BX;
End;

Function EmsFreePage:Integer;
Var 
 Regs:Registers;   
Begin
 Regs.AH:=$42;                
 Intr(IntrEMS,Regs);
 If Regs.AH<>0 Then Begin
  EmmError:=Regs.AH;
  EmsFreePage:=-1;
 End
  Else                                                  
 EmsFreePage:=Regs.BX;
End;

Function EmsAlloc(Pages:Integer):Integer;
Var 
 Regs:Registers;
Begin
 Regs.ah := $43;
 Regs.bx := Pages; 
 Intr(IntrEMS,Regs);
 If Regs.AH<>0 Then Begin
  EmmError:=Regs.AH;
  EmsAlloc:=-1;
 End
  Else
 EmsAlloc:=Regs.DX;
End;

Function EmsFree(Handle:Integer):Boolean;
Var 
 Regs:Registers;
Begin
 Regs.AH:=$45;
 Regs.DX:=Handle;                                
 Intr(IntrEMS,Regs);
 EmmError:=Regs.AH;
 EmsFree:=(Regs.AH=0); 
End;


BEGIN
 If(EmsInst)Then Begin
  WriteLn('+-------------------------------------------+');
  WriteLn('| Turbo Pascal EMS Test Program Version 1.0 |');
  WriteLn('| Corail - Gladir.com                       |');
  WriteLn('+-------------------------------------------+');
  WriteLn;
  WriteLn('PARTIE UN - DETECTION EMS');
  WriteLn('-------------------------');
  WriteLn;
  WriteLn('Gestionnaire de memoire etendue version ',EmsVersion);
  GetIntVec($67,Intr67h);
  WriteLn('Adresse du gestionnaire INT 67   : ',HexWord2Str(Seg(Intr67h^)),':',HexWord2Str(Ofs(Intr67h^)));
  WriteLn('Adresse de segment de la fenetre : ',HexWord2Str(EmsFrameSeg));
  WriteLn('Nombre total de pages            : ',EmsNumTotalPage,' (',EmsNumTotalPage*16,' Ko)');
  WriteLn;
  WriteLn('ID de processus    Page alloue');
  WriteLn('--------------------------------');
  If EmsNumUsedPage>0 Then Begin
   For I:=0 to EmsNumUsedPage-1 do Begin
    WriteLn(' ',HexWord2Str(I),'              ',EmsUsedPage(I):5,' (',EmsUsedPage(I)*16,' Ko)');
   End;
  End;
  WriteLn(' Libre             ',EmsFreePage:5,' (',EmsFreePage*16,' Ko)');
  WriteLn('--------------------------------');
  WriteLn('Presse Esc pour abandonner ou une autre touche pour continuer...');
  If ReadKey=#27 Then Halt;
  WriteLn;
  WriteLn;
  WriteLn;
  WriteLn('PARTIE DEUX - FONCTIONS EMS DE BASE');
  WriteLn('-------------------------');
  WriteLn;
  If EmsFreePage>128 Then Size:=128
                     Else Size:=EmsFreePage;  
  Write('Allocation de ',Size,' pages de memoire EMS : ');
  TestHandle:=EmsAlloc(Size);
  If TestHandle<>-1Then WriteLn('OK')
                   Else WriteLn('Erreur');
  WriteLn('Handle de l''EMS (ID de processus)      : ',HexWord2Str(TestHandle));
  Write('Libérer les ',Size,' pages de memoire EMS   : ');
  If EmsFree(TestHandle)Then WriteLn('OK')
                        Else WriteLn('Erreur');
 End
  Else
 WriteLn('Aucun pilote de EMS détecté !');
END.