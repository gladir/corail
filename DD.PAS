{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program DD;

Const
 AsciiToEBCDIC:Array[#0..#255]of Char=(
  #0, #1, #2, #3, #55, #45, #46, #47,
  #22, #5, #37, #11, #12, #13, #14, #15,
  #16, #17, #18, #19, #60, #61, #50, #38,
  #24, #25, #63, #39, #28, #29, #30, #31,
  #64, #90, #127, #123, #91, #108, #80, #125,
  #77, #93, #92, #78, #107, #96, #75, #97,
  #240, #241, #242, #243, #244, #245, #246, #247,
  #248, #249, #122, #94, #76, #126, #110, #111,
  #124, #193, #194, #195, #196, #197, #198, #199,
  #200, #201, #209, #210, #211, #212, #213, #214,
  #215, #216, #217, #226, #227, #228, #229, #230,
  #231, #232, #233, #173, #224, #189, #154, #109,
  #121, #129, #130, #131, #132, #133, #134, #135,
  #136, #137, #145, #146, #147, #148, #149, #150,
  #151, #152, #153, #162, #163, #164, #165, #166,
  #167, #168, #169, #192, #79, #208, #95, #7,
  #32, #33, #34, #35, #36, #21, #6, #23,
  #40, #41, #42, #43, #44, #9, #10, #27,
  #48, #49, #26, #51, #52, #53, #54, #8,
  #56, #57, #58, #59, #4, #20, #62, #225,
  #65, #66, #67, #68, #69, #70, #71, #72,
  #73, #81, #82, #83, #84, #85, #86, #87,
  #88, #89, #98, #99, #100, #101, #102, #103,
  #104, #105, #112, #113, #114, #115, #116, #117,
  #118, #119, #120, #128, #138, #139, #140, #141,
  #142, #143, #144, #106, #155, #156, #157, #158,
  #159, #160, #170, #171, #172, #74, #174, #175,
  #176, #177, #178, #179, #180, #181, #182, #183,
  #184, #185, #186, #187, #188, #161, #190, #191,
  #202, #203, #204, #205, #206, #207, #218, #219,
  #220, #221, #222, #223, #234, #235, #236, #237,
  #238, #239, #250, #251, #252, #253, #254, #255
 );

 AsciiToIBM:Array[#0..#255]of Char=(
  #0, #1, #2, #3, #55, #45, #46, #47,
  #22, #5, #37, #11, #12, #13, #14, #15,
  #16, #17, #18, #19, #60, #61, #50, #38,
  #24, #25, #63, #39, #28, #29, #30, #31,
  #64, #90, #127, #123, #91, #108, #80, #125,
  #77, #93, #92, #78, #107, #96, #75, #97,
  #240, #241, #242, #243, #244, #245, #246, #247,
  #248, #249, #122, #94, #76, #126, #110, #111,
  #124, #193, #194, #195, #196, #197, #198, #199,
  #200, #201, #209, #210, #211, #212, #213, #214,
  #215, #216, #217, #226, #227, #228, #229, #230,
  #231, #232, #233, #173, #224, #189, #95, #109,
  #121, #129, #130, #131, #132, #133, #134, #135,
  #136, #137, #145, #146, #147, #148, #149, #150,
  #151, #152, #153, #162, #163, #164, #165, #166,
  #167, #168, #169, #192, #79, #208, #161, #7,
  #32, #33, #34, #35, #36, #21, #6, #23,
  #40, #41, #42, #43, #44, #9, #10, #27,
  #48, #49, #26, #51, #52, #53, #54, #8,
  #56, #57, #58, #59, #4, #20, #62, #225,
  #65, #66, #67, #68, #69, #70, #71, #72,
  #73, #81, #82, #83, #84, #85, #86, #87,
  #88, #89, #98, #99, #100, #101, #102, #103,
  #104, #105, #112, #113, #114, #115, #116, #117,
  #118, #119, #120, #128, #138, #139, #140, #141,
  #142, #143, #144, #154, #155, #156, #157, #158,
  #159, #160, #170, #171, #172, #173, #174, #175,
  #176, #177, #178, #179, #180, #181, #182, #183,
  #184, #185, #186, #187, #188, #189, #190, #191,
  #202, #203, #204, #205, #206, #207, #218, #219,
  #220, #221, #222, #223, #234, #235, #236, #237,
  #238, #239, #250, #251, #252, #253, #254, #255
 );

 EbcdicToAscii:Array[#0..#255]of Char=(
  #0, #1, #2, #3, #156, #9, #134, #127,
  #151, #141, #142, #11, #12, #13, #14, #15,
  #16, #17, #18, #19, #157, #133, #8, #135,
  #24, #25, #146, #143, #28, #29, #30, #31,
  #128, #129, #130, #131, #132, #10, #23, #27,
  #136, #137, #138, #139, #140, #5, #6, #7,
  #144, #145, #22, #147, #148, #149, #150, #4,
  #152, #153, #154, #155, #20, #21, #158, #26,
  #32, #160, #161, #162, #163, #164, #165, #166,
  #167, #168, #213, #46, #60, #40, #43, #124,
  #38, #169, #170, #171, #172, #173, #174, #175,
  #176, #177, #33, #36, #42, #41, #59, #126,
  #45, #47, #178, #179, #180, #181, #182, #183,
  #184, #185, #203, #44, #37, #95, #62, #63,
  #186, #187, #188, #189, #190, #191, #192, #193,
  #194, #96, #58, #35, #64, #39, #61, #34,
  #195, #97, #98, #99, #100, #101, #102, #103,
  #104, #105, #196, #197, #198, #199, #200, #201,
  #202, #106, #107, #108, #109, #110, #111, #112,
  #113, #114, #94, #204, #205, #206, #207, #208,
  #209, #229, #115, #116, #117, #118, #119, #120,
  #121, #122, #210, #211, #212, #91, #214, #215,
  #216, #217, #218, #219, #220, #221, #222, #223,
  #224, #225, #226, #227, #228, #93, #230, #231,
  #123, #65, #66, #67, #68, #69, #70, #71,
  #72, #73, #232, #233, #234, #235, #236, #237,
  #125, #74, #75, #76, #77, #78, #79, #80,
  #81, #82, #238, #239, #240, #241, #242, #243,
  #92, #159, #83, #84, #85, #86, #87, #88,
  #89, #90, #244, #245, #246, #247, #248, #249,
  #48, #49, #50, #51, #52, #53, #54, #55,
  #56, #57, #250, #251, #252, #253, #254, #255
 );


Var
 ConvMode:Set of (UpperCase,LowerCase,ASCII,EBCDIC,IBM,NotOp,
                  ASCII7,Rot13Op,Rot13C5DOp,AnsiTo437Op,_437ToAnsiOp);
 BytesReaded,BytesWrited:Word;
 I,J:Integer;
 C:Char;
 SourceFile,TargetFile:File;
 SourceFileName,TargetFileName,CurrWord,CurrParam:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function StrToLower(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
 End;
 StrToLower:=S;
End;

Function LoCase(C:Char):Char;Begin
 If C in['A'..'Z']Then C:=Chr(Ord(C)+32);
 LoCase:=C;
End;

Function Rot13(Ch:Char):Char;Begin
 Case Ch of
  'A'..'M','a'..'m':Ch:=Chr(Ord(Ch)+13);
  'N'..'Z','n'..'z':Ch:=Chr(Ord(Ch)-13);
 End;
 Rot13:=Ch;
End;

Function Rot13C5D(Ch:Char):Char;Begin
 Case Ch of
  'A'..'M','a'..'m':Ch:=Chr(Ord(Ch)+13);
  'N'..'Z','n'..'z':Ch:=Chr(Ord(Ch)-13);
  '0'..'9':Ch:=Chr(((Ord(Ch)-Ord('0')+5) mod 10)+Ord('0'));
 End;
 Rot13C5D:=Ch;
End;

Function AnsiTo437(Ch:Char):Char;Begin
 Case Ch of
  #171:Ch:=#174;
  #176:Ch:=#248;
  #177:Ch:=#241;
  #187:Ch:=#175;
  #188:Ch:=#172;
  #189:Ch:=#171;
  #192..#195:Ch:='A';
  #196:Ch:=#142;
  #197:Ch:=#143;
  #198:Ch:=#146;
  #199:Ch:=#128;
  #200:Ch:='E';
  #201:Ch:=#144;
  #202:Ch:='E';
  #203:Ch:='E';
  #204..#207:Ch:='I';
  #208:Ch:='D';
  #209:Ch:=#165;
  #210..#214:Ch:='O';
  #217..#219:Ch:='U';
  #220:Ch:=#154;
  #224:Ch:=#133;
  #225:Ch:=#160;
  #226:Ch:=#131;
  #227:Ch:='a';
  #228:Ch:=#132;
  #229:Ch:=#134;
  #230:Ch:=#145;
  #231:Ch:=#135;
  #232:Ch:=#138;
  #233:Ch:=#130;
  #234:Ch:=#136;
  #235:Ch:=#137;
  #236:Ch:=#141;
  #237:Ch:=#161;
  #238:Ch:=#140;
  #239:Ch:=#139;
  #241:Ch:=#164;
  #242:Ch:=#149;
  #243:Ch:=#162;
  #244:Ch:=#147;
  #246:Ch:=#148;
  #247:Ch:=#246;
  #249:Ch:=#151;
  #250:Ch:=#163;
  #251:Ch:=#150;
  #252:Ch:=#129;
 End;
 AnsiTo437:=Ch;
End;

Function _437ToAnsi(Ch:Char):Char;Begin
 Case Ch of
  #174:Ch:=#171;
  #248:Ch:=#176;
  #241:Ch:=#177;
  #175:Ch:=#187;
  #172:Ch:=#188;
  #171:Ch:=#189;
  #142:Ch:=#196;
  #143:Ch:=#197;
  #146:Ch:=#198;
  #128:Ch:=#199;
  #144:Ch:=#201;
  #165:Ch:=#209;
  #154:Ch:=#220;
  #133:Ch:=#224;
  #160:Ch:=#225;
  #131:Ch:=#226;
  #132:Ch:=#228;
  #134:Ch:=#229;
  #145:Ch:=#230;
  #135:Ch:=#231;
  #138:Ch:=#232;
  #130:Ch:=#233;
  #136:Ch:=#234;
  #137:Ch:=#235;
  #141:Ch:=#236;
  #161:Ch:=#237;
  #140:Ch:=#238;
  #139:Ch:=#239;
  #164:Ch:=#241;
  #149:Ch:=#242;
  #162:Ch:=#243;
  #147:Ch:=#244;
  #148:Ch:=#246;
  #246:Ch:=#247;
  #151:Ch:=#249;
  #163:Ch:=#250;
  #150:Ch:=#251;
  #129:Ch:=#252;
 End;
 _437ToAnsi:=Ch;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('DD : Cette commande permet de convertir un fichier tant ',
                'qu''il se copie.');
  WriteLn;
  WriteLn('Syntaxe : DD if=source of=target conv=valeur');
  WriteLn;
  WriteLn(' if=source       Nom du fichier source');
  WriteLn(' of=target       Nom du fichier destinatire');
  WriteLn(' conv=valeur     Indique le type de conversion (s‚par‚ par des virgules) :');
  WriteLn('       437toansi De code de page 437 (IBM PC) … ANSI');
  WriteLn('       ansito437 De ANSI … code de page 437 (IBM PC)');
  WriteLn('       ascii     De EBCDIC … ASCII');
  WriteLn('       ascii7    Conversion en ASCII 7 bits');
  WriteLn('       ebcdic    De ASCII … EBCDIC');
  WriteLn('       ibm       De ASCII … EBCDIC alternatif');
  WriteLn('       lcase     Change de majuscule … minuscule');
  WriteLn('       not       Effectue une op‚ration de n‚gation des bits');
  WriteLn('       rot13     Effectue une op‚ration d''encodage rot13');
  WriteLn('       rot13c5d  Effectue une op‚ration d''encodage rot13c5d');
  WriteLn('       ucase     Change de minuscule … majuscule');
 End
  Else
 Begin
  ConvMode:=[];
  SourceFileName:='';
  TargetFileName:='';
  For I:=1 to ParamCount do Begin
   If Copy(ParamStr(I),1,Length('if='))='if='Then Begin
    SourceFileName:=Copy(ParamStr(I),Length('if=')+1,255);
   End
    Else
   If Copy(ParamStr(I),1,Length('of='))='of='Then Begin
    TargetFileName:=Copy(ParamStr(I),Length('of=')+1,255);
   End
    Else
   If Copy(ParamStr(I),1,Length('conv='))='conv='Then Begin
    CurrWord:='';
    CurrParam:=Copy(ParamStr(I),Length('conv=')+1,255);
    For J:=1 to Length(CurrParam)do Begin
     If CurrParam[J]=','Then Begin
      If CurrWord='ucase'Then Include(ConvMode,UpperCase) Else
      If CurrWord='lcase'Then Include(ConvMode,LowerCase) Else
      If CurrWord='ebcdic'Then Include(ConvMode,EBCDIC) Else
      If CurrWord='ibm'Then Include(ConvMode,IBM) Else
      If CurrWord='ascii'Then Include(ConvMode,ASCII) Else
      If CurrWord='ascii7'Then Include(ConvMode,ASCII7) Else
      If CurrWord='not'Then Include(ConvMode,NotOp) Else
      If CurrWord='rot13'Then Include(ConvMode,Rot13Op) Else
      If CurrWord='rot13c5d'Then Include(ConvMode,Rot13C5DOp) Else
      If CurrWord='ansito437'Then Include(ConvMode,AnsiTo437Op)Else
      If CurrWord='437toansi'Then Include(ConvMode,_437ToAnsiOp)
       Else
      Begin
       WriteLn('Type de conversion non reconnu : ',CurrWord);
       Halt(8);
      End;
      CurrWord:='';
     End
      Else
     CurrWord:=CurrWord+CurrParam[J];
    End;
    If CurrWord<>''Then Begin
     If CurrWord='ucase'Then Include(ConvMode,UpperCase) Else
     If CurrWord='lcase'Then Include(ConvMode,LowerCase) Else
     If CurrWord='ebcdic'Then Include(ConvMode,EBCDIC) Else
     If CurrWord='ibm'Then Include(ConvMode,IBM) Else
     If CurrWord='ascii'Then Include(ConvMode,ASCII) Else
     If CurrWord='ascii7'Then Include(ConvMode,ASCII7) Else
     If CurrWord='not'Then Include(ConvMode,NotOp) Else
     If CurrWord='rot13'Then Include(ConvMode,Rot13Op) Else
     If CurrWord='rot13c5d'Then Include(ConvMode,Rot13C5DOp) Else
     If CurrWord='ansito437'Then Include(ConvMode,AnsiTo437Op) Else
     If CurrWord='437toansi'Then Include(ConvMode,_437ToAnsiOp)
      Else
     Begin
      WriteLn('Type de conversion non reconnu : ',CurrWord);
      Halt(8);
     End;
    End;
   End
    Else
   Begin
    WriteLn('ParamŠtre non reconnu');
    Halt(5);
   End;
  End;
  If(SourceFileName='')Then Begin
   WriteLn('Nom du fichier source ind‚fini');
   Halt(1);
  End;
  If(TargetFileName='')Then Begin
   WriteLn('Nom du fichier destinataire ind‚fini');
   Halt(2);
  End;
  {$I-}Assign(SourceFile,SourceFileName);
  Reset(SourceFile,1);{$I+}
   If IOResult<>0 Then Begin
   WriteLn('Impossible de lire le fichier ',SourceFileName);
   Halt(3);
  End;
  {$I-}Assign(TargetFile,TargetFileName);
  Rewrite(TargetFile,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible de cr‚er le fichier ',TargetFileName);
   Halt(4);
  End;
  While Not EOF(SourceFile)do Begin
   BlockRead(SourceFile,C,1,BytesReaded);
   If BytesReaded=0 Then Exit;
   If(UpperCase in ConvMode)Then C:=UpCase(C);
   If(LowerCase in ConvMode)Then C:=LoCase(C);
   If(EBCDIC in ConvMode)Then C:=AsciiToEBCDIC[C];
   If(IBM in ConvMode)Then C:=AsciiToIBM[C];
   If(ASCII in ConvMode)Then C:=EbcdicToAscii[C];
   If(ASCII7 in ConvMode)Then Begin
    Case C of
     #128:C:='C';
     #129:C:='u';
     #130:C:='e';
     #131..#134:C:='a';
     #135:C:='c';
     #136..#138:C:='e';
     #139..#141:C:='i';
     #142,#143:C:='A';
     #144:C:='E';
     #147..#149:C:='o';
     #150,#151:C:='u';
     #152:C:='y';
     #153:C:='o';
     #154:C:='u';
     #160:C:='a';
     #161:C:='i';
     #162:C:='o';
     #163:C:='u';
     #164:C:='n';
     #165:C:='N';
     Else C:=Char(Byte(C)and $7F);
    End;
   End;
   If(NotOp in ConvMode)Then C:=Char(Not(Byte(C)));
   If(Rot13Op in ConvMode)Then C:=Rot13(C);
   If(Rot13C5DOp in ConvMode)Then C:=Rot13C5D(C);
   If(AnsiTo437Op in ConvMode)Then C:=AnsiTo437(C);
   If(_437ToAnsiOp in ConvMode)Then C:=_437ToAnsi(C);
   BlockWrite(TargetFile,C,1,BytesWrited);
   If BytesWrited=0 Then Begin
    WriteLn('Erreur d''‚criture');
    Halt(6);
   End;
  End;
  Close(TargetFile);
  Close(SourceFile);
 End;
END.