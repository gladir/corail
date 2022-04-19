{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program _FILE;

Uses DOS;

Var
 I:Integer;
 FileCheck:File {$IFDEF FPC}of Byte{$ENDIF};
 ByteReaded:Integer;
 Buffer:Array[0..79]of Byte;
 LongSign:LongInt Absolute Buffer;
 WordSign:Word Absolute Buffer;
 _Dir:DirStr;
 _Name:NameStr;
 _Ext:ExtStr;

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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('FILE : Cette commande permet de determiner le type de fichier.');
  WriteLn;
  WriteLn('Syntaxe : FILE nomdufichier');
 End
  Else
 If ParamCount>0 Then Begin
  For I:=1 to ParamCount do Begin
   FillChar(Buffer,SizeOf(Buffer),0);
   {$I-}Assign(FileCheck,ParamStr(1));
   Reset(FileCheck);{$I+}
   If IoResult=0Then Begin
    BlockRead(FileCheck,Buffer,SizeOf(Buffer),ByteReaded);
    If Buffer[0]=$1AThen WriteLn('Archive ARC')Else
    If WordSign=$601AThen WriteLn('Binaire executable Atari ST')Else
    If WordSign=$6669Then WriteLn('Fichier musical 669 de Renaissance')Else
    If WordSign=60000Then WriteLn('Archive ARJ')Else
    If LongSign=$04034B50Then WriteLn('Archive ZIP')Else
    If LongSign=$53C145C7Then WriteLn('Fichier GeoWorks 2')Else
    If LongSign=$53CF45C7Then WriteLn('Fichier GeoWorks')Else
    If(Buffer[0]=Byte('.'))and(Buffer[1]=Byte('s'))and(Buffer[2]=Byte('n'))and(Buffer[3]=Byte('d'))Then
	 WriteLn('Fichier sonore de Sun Microsystems')
	 Else
    If(Buffer[0]=Byte('!'))and(Buffer[1]=Byte('<'))and(Buffer[2]=Byte('a'))and(Buffer[3]=Byte('r'))and
	  (Buffer[4]=Byte('c'))and(Buffer[5]=Byte('h'))and(Buffer[6]=Byte('>'))Then WriteLn('Archive compresse Debian')Else
    If(Buffer[0]=Byte('2'))and(Buffer[1]=Byte('B'))and(Buffer[2]=Byte('I'))and(Buffer[3]=Byte('T'))Then
	 WriteLn('Fichier sonore 2-BIT systems de Atari ST')Else
    If(Buffer[0]=Byte('7'))and(Buffer[1]=Byte('z'))and(Buffer[2]=$BC)and(Buffer[3]=$AF)and(Buffer[4]=$27)and
	  (Buffer[5]=$1C)Then WriteLn('Archive 7Zip')Else
    If(Buffer[0]=Byte('B'))and(Buffer[1]=Byte('G'))and(Buffer[2]=Byte('X'))and(Buffer[3]=Byte('1'))Then
	 WriteLn('Image Bitmap Genesis graphiX pour le MonsterBook')Else
    If(Buffer[0]=Byte('B'))and(Buffer[1]=Byte('M'))Then WriteLn('Image Bitmap pour Windows ou OS/2')Else
    If(Buffer[0]=Byte('C'))and(Buffer[1]=Byte('T'))and(Buffer[2]=Byte('M'))and(Buffer[3]=Byte('F'))Then
	 WriteLn('Fichier sonore Creative Music File')Else
    If(Buffer[0]=Byte('L'))and(Buffer[1]=Byte('P'))and(Buffer[2]=Byte('F'))Then WriteLn('Animation DeluxePaint')Else
    If(Buffer[0]=Byte('M'))and(Buffer[1]=Byte('S'))and(Buffer[2]=Byte('C'))and(Buffer[3]=Byte('F'))Then
	 WriteLn('Archive CAB de Windows')Else
    If(Buffer[0]=Byte('T'))and(Buffer[1]=Byte('D'))Then WriteLn('Image disque TeleDisk')Else
    If(Buffer[0]=$7F)and(Buffer[1]=Byte('E'))and(Buffer[2]=Byte('L'))and(Buffer[3]=Byte('F'))Then
	 WriteLn('Fichier ex‚cutable ELF (Executable and Linkable Format) pour les systemes de styles UNIX')Else
    If(Buffer[0]=$AA)and(Buffer[1]=$59)Then WriteLn('Image Bitmap IBM d''OS/2')Else
    If(Buffer[0]=$CA)and(Buffer[1]=$FE)and(Buffer[2]=$BA)and(Buffer[3]=$BE)Then WriteLn('Fichier d''une classe de Java')
     Else
    Begin
     FSplit(ParamStr(1),_Dir,_Name,_Ext);
     _Ext:=StrToUpper(_Ext);
     If _Ext='.BAS'Then WriteLn('Code source BASIC') Else
     If _Ext='.BAT'Then WriteLn('Fichier de traitement par lot Batch du DOS') Else
     If _Ext='.BMP'Then WriteLn('Image Bitmap BMP d''OS/2 ou Windows')Else
     If _Ext='.BSQ'Then WriteLn('Archive BINSCII Binary Archive de l''Apple II')Else
     If _Ext='.C'Then WriteLn('Code source C') Else
     If _Ext='.COM'Then WriteLn('Binaire executable de commande') Else
     If _Ext='.EXE'Then WriteLn('Binaire executable') Else
     If _Ext='.FNT'Then WriteLn('Police de caractŠres') Else
     If _Ext='.GIF'Then WriteLn('Image Bitmap GIF') Else
     If _Ext='.H'Then WriteLn('Code source d''entete C') Else
     If _Ext='.HTM'Then WriteLn('Code source de HTML') Else
     If _Ext='.HTML'Then WriteLn('Code source de HTML') Else
     If _Ext='.JAVA'Then WriteLn('Code source Java')Else
     If _Ext='.JPG'Then WriteLn('Image Bitmap JPEG') Else
     If _Ext='.PAS'Then WriteLn('Code source Pascal')Else
     If _Ext='.PHP'Then WriteLn('Code source PHP')Else
     If _Ext='.TXT'Then WriteLn('Texte ASCII')Else
     If _Ext='.XML'Then WriteLn('Code source XML')Else
     If _Ext='.ZIP'Then WriteLn('Archive ZIP')
      Else
     WriteLn('Format inconnu');
    End;
    Close(FileCheck);
   End
    Else
   WriteLn('Erreur de lecture');
  End;
 End
  Else
 WriteLn('Parametre requis !');
END.
