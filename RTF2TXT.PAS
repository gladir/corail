{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program RTF2TXT;

Uses Strings;

Type
 TagRec=Record
  Code:Word;
  Name:String[30];
  IsText:Boolean;
 End;

Const
 RTF_ADDITIVE=$0040;
 RTF_ADJUSTRIGHT=$0080;
 RTF_AENDDOC=$0100;
 RTF_AF=$0180;
 RTF_AFTNNRLC=$0200;
 RTF_AFTNRSTCONT=$0300;
 RTF_AFTNSTART=$0400;
 RTF_ANSI=$0500;
 RTF_ANSICPG=$0580;
 RTF_AUTHOR=$05B0;
 RTF_B=$0600;
 RTF_BLUE=$0700;
 RTF_BRDRS=$0780;
 RTF_BRDRW=$07A0;
 RTF_BULLET=$0800;
 RTF_C=$0B00;
 RTF_CELL=$0B80;
 RTF_CELLX=$0BA0;
 RTF_CF=$0C00;
 RTF_CGRID=$0C40;
 RTF_CLBRDRB=$0C46;
 RTF_CLBRDRL=$0C4A;
 RTF_CLBRDRR=$0C4D;
 RTF_CLBRDRT=$0C50;
 RTF_CLMGF=$0C56;
 RTF_CLMRG=$0C5A;
 RTF_CLTXLRTB=$0C60;
 RTF_CLVERTALT=$0C80;
 RTF_COLORTBL=$0900;
 RTF_COLSX=$0C90;
 RTF_COMMENT=$0A00;
 RTF_COMPANY=$0CA0;
 RTF_CREATIM=$0CC0;
 RTF_CS=$0D00;
 RTF_DBCH=$0D00;
 RTF_DBCHA=$0D40;
 RTF_DBCHB=$0D80;
 RTF_DEFF=$0E00;
 RTF_DEFLANG=$0E80;
 RTF_DEFLANGFE=$0E90;
 RTF_DEFTAB=$0E98;
 RTF_DY=$0EC0;
 RTF_EDMINS=$0ED0;
 RTF_EMDASH=$0ED4;
 RTF_ENDASH=$0ED8;
 RTF_ENDNHERE=$0EE0;
 RTF_F=$0F00;
 RTF_FBIAS=$0F80;
 RTF_FCHARSET=$1000;
 RTF_FET=$1080;
 RTF_FI=$1100;
 RTF_FIELD=$1180;
 RTF_FLDINST=$11A0;
 RTF_FLDRSLT=$11C0;
 RTF_FNIL=$1200;
 RTF_FONTTBL=$1300;
 RTF_FOOTER=$1400;
 RTF_FOOTERXL=$1500;
 RTF_FOOTERXR=$1600;
 RTF_FOOTERY=$1700;
 RTF_FOOTERYT=$1800;
 RTF_FORMSHADE=$1880;
 RTF_FPRQ=$1900;
 RTF_FROMAN=$1A00;
 RTF_FS=$1B00;
 RTF_FSWISS=$1C00;
 RTF_FTNBJ=$1D00;
 RTF_FTNNAR=$1E00;
 RTF_FTNRSTCONT=$1F00;
 RTF_FTNSTART=$2000;
 RTF_GREEN=$2100;
 RTF_HEADER=$2200;
 RTF_HEADERY=$2240;
 RTF_HICH=$2260;
 RTF_HR=$2280;
 RTF_HYPHCAPS=$22B0;
 RTF_HYPHHOTZ=$22C0;
 RTF_I=$2300;
 RTF_ILVL=$2380;
 RTF_INFO=$2400;
 RTF_INTBL=$2440;
 RTF_INTBLCHAR=$2460;
 RTF_INTBLINT=$2468;
 RTF_JCLISTTAB=$2480;
 RTF_KEEP=$2500;
 RTF_KEEPN=$2580;
 RTF_LANG=$2600;
 RTF_LDBLQUOTE=$2680;
 RTF_LEVELFOLLOW=$2700;
 RTF_LEVELINDENT=$2780;
 RTF_LEVELJC=$2800;
 RTF_LEVELNFC=$2900;
 RTF_LEVELNUMBERS=$2A00;
 RTF_LEVELSPACE=$2A80;
 RTF_LEVELSTARTAT=$2B00;
 RTF_LEVELTEXT=$2C00;
 RTF_LI=$2E00;
 RTF_LINE=$2F00;
 RTF_LINEX=$2F80;
 RTF_LIST=$3000;
 RTF_LISTID=$3100;
 RTF_LISTLEVEL=$3200;
 RTF_LISTNAME=$3280;
 RTF_LISTOVERRIDE=$3300;
 RTF_LISTOVERRIDECOUNT=$3400;
 RTF_LISTOVERRIDETABLE=$3500;
 RTF_LISTSIMPLE=$3580;
 RTF_LISTTABLE=$3598;
 RTF_LISTTEMPLATEID=$35C0;
 RTF_LISTTEXT=$3600;
 RTF_LOCH=$3640;
 RTF_LOCHA=$3644;
 RTF_LOCHB=$3648;
 RTF_LQUOTE=$3680;
 RTF_LS=$36C0;
 RTF_MARGB=$3700;
 RTF_MARGBSXN=$3800;
 RTF_MARGL=$3900;
 RTF_MARGLSXN=$3A00;
 RTF_MARGR=$3B00;
 RTF_MARGRSXN=$3C00;
 RTF_MARGT=$3D00;
 RTF_MARGTSXN=$3E00;
 RTF_MIN=$3E20;
 RTF_MO=$3E40;
 RTF_NOFCHARS=$3E60;
 RTF_NOFCHARSWS=$3E64;
 RTF_NOFPAGES=$3E68;
 RTF_NOFWORDS=$3E70;
 RTF_NOWIDCTLPAR=$3E80;
 RTF_OPERATOR=$3EA0;
 RTF_OUTLINELEVEL=$3EC0;
 RTF_PAGE=$3F00;
 RTF_PANOSE=$3F80;
 RTF_PAPERH=$4000;
 RTF_PAPERW=$4100;
 RTF_PAR=$4200;
 RTF_PARD=$4300;
 RTF_PGBRDRFOOT=$4360;
 RTF_PGBRDRHEAD=$4390;
 RTF_PGDSC=$4400;
 RTF_PGDSCNXT=$4500;
 RTF_PGDSCUSE=$4600;
 RTF_PGHSXN=$4700;
 RTF_PGWSXN=$4800;
 RTF_PLAIN=$4900;
 RTF_PN=$4920;
 RTF_PNDEC=$4930;
 RTF_PNHANG=$4940;
 RTF_PNINDENT=$4960;
 RTF_PNLCLTR=$4970;
 RTF_PNLCRM=$4980;
 RTF_PNLVLBLT=$4982;
 RTF_PNLVLBODY=$4983;
 RTF_PNLVLCONT=$4984;
 RTF_PNRNOT=$4988;
 RTF_PNSECLVL=$498C;
 RTF_PNSTART=$4990;
 RTF_PNTEXT=$4998;
 RTF_PNTXTA=$49A0;
 RTF_PNTXTB=$49A4;
 RTF_PNUCLTR=$49B8;
 RTF_PNUCRM=$49C0;
 RTF_Q=$4A00;
 RTF_QC=$4A30;
 RTF_QR=$4A60;
 RTF_RDBLQUOTE=$4A80;
 RTF_RED=$4B00;
 RTF_REVTIM=$4B80;
 RTF_RI=$4C00;
 RTF_ROW=$4C40;
 RTF_RQUOTE=$4C80;
 RTF_RTF=$4D00;
 RTF_S=$4E00;
 RTF_SA=$4F00;
 RTF_SB=$5000;
 RTF_SBASEDON=$5100;
 RTF_SBKNONE=$5200;
 RTF_SECTD=$5300;
 RTF_SECTDEF=$5380;
 RTF_SECTDEFAULTCL=$53C0;
 RTF_SL=$5400;
 RTF_SNEXT=$5500;
 RTF_STYLESHEET=$5600;
 RTF_TAB=$5680;
 RTF_TITLE=$56B0;
 RTF_TQC=$5700;
 RTF_TRGAPH=$5740;
 RTF_TRLEFT=$5760;
 RTF_TROWD=$5780;
 RTF_TRRH=$57A0;
 RTF_TX=$5800;
 RTF_U=$5900;
 RTF_UC=$5980;
 RTF_UL=$5A00;
 RTF_VERN=$5B00;
 RTF_VERSION=$5C00;
 RTF_VIEWKIND=$5D00;
 RTF_VIEWSCALE=$5E00;
 RTF_WIDCTLPAR=$5F00;
 RTF_WIDOWCTRL=$6000;
 RTF_YR=6100;

 TagList:Array[0..202] of TagRec=(
  (Code:$0040;Name:'ADDITIVE';IsText:True),
  (Code:$0080;Name:'ADJUSTRIGHT';IsText:True),
  (Code:$0100;Name:'AENDDOC';IsText:False),
  (Code:$0180;Name:'AF';IsText:False),
  (Code:$0200;Name:'AFTNNRLC';IsText:False),
  (Code:$0300;Name:'AFTNRSTCONT';IsText:False),
  (Code:$0400;Name:'AFTNSTART';IsText:False),
  (Code:$0500;Name:'ANSI';IsText:False),
  (Code:$0580;Name:'ANSICPG';IsText:False),
  (Code:$05B0;Name:'AUTHOR';IsText:False),
  (Code:$0600;Name:'B';IsText:False),
  (Code:$0700;Name:'BLUE';IsText:False),
  (Code:$0780;Name:'BRDRS';IsText:False),
  (Code:$07A0;Name:'BRDRW';IsText:False),
  (Code:$0800;Name:'BULLET';IsText:False),
  (Code:$0B00;Name:'C';IsText:False),
  (Code:$0B80;Name:'CELL';IsText:False),
  (Code:$0BA0;Name:'CELLX';IsText:False),
  (Code:$0C00;Name:'CF';IsText:False),
  (Code:$0C40;Name:'CGRID';IsText:False),
  (Code:$0C46;Name:'CLBRDRB';IsText:False),
  (Code:$0C4A;Name:'CLBRDRL';IsText:False),
  (Code:$0C4D;Name:'CLBRDRR';IsText:False),
  (Code:$0C50;Name:'CLBRDRT';IsText:False),
  (Code:$0C56;Name:'CLMGF';IsText:False),
  (Code:$0C5A;Name:'CLMRG';IsText:False),
  (Code:$0C60;Name:'CLTXLRTB';IsText:False),
  (Code:$0C80;Name:'CLVERTALT';IsText:False),
  (Code:$0900;Name:'COLORTBL';IsText:False),
  (Code:$0C90;Name:'COLSX';IsText:False),
  (Code:$0A00;Name:'COMMENT';IsText:False),
  (Code:$0CA0;Name:'COMPANY';IsText:False),
  (Code:$0CC0;Name:'CREATIM';IsText:False),
  (Code:$0D00;Name:'CS';IsText:False),
  (Code:$0D00;Name:'DBCH';IsText:False),
  (Code:$0D40;Name:'DBCHA';IsText:False),
  (Code:$0D80;Name:'DBCHB';IsText:False),
  (Code:$0E00;Name:'DEFF';IsText:False),
  (Code:$0E80;Name:'DEFLANG';IsText:False),
  (Code:$0E90;Name:'DEFLANGFE';IsText:False),
  (Code:$0E98;Name:'DEFTAB';IsText:False),
  (Code:$0EC0;Name:'DY';IsText:False),
  (Code:$0ED0;Name:'EDMINS';IsText:False),
  (Code:$0ED4;Name:'EMDASH';IsText:True),
  (Code:$0ED8;Name:'ENDASH';IsText:True),
  (Code:$0EE0;Name:'ENDNHERE';IsText:False),
  (Code:$0F00;Name:'F';IsText:False),
  (Code:$0F80;Name:'FBIAS';IsText:False),
  (Code:$1000;Name:'FCHARSET';IsText:False),
  (Code:$1080;Name:'FET';IsText:False),
  (Code:$1100;Name:'FI';IsText:False),
  (Code:$1180;Name:'FIELD';IsText:False),
  (Code:$11A0;Name:'FLDINST';IsText:False),
  (Code:$11C0;Name:'FLDRSLT';IsText:False),
  (Code:$1200;Name:'FNIL';IsText:False),
  (Code:$1300;Name:'FONTTBL';IsText:False),
  (Code:$1400;Name:'FOOTER';IsText:False),
  (Code:$1500;Name:'FOOTERXL';IsText:False),
  (Code:$1600;Name:'FOOTERXR';IsText:False),
  (Code:$1700;Name:'FOOTERY';IsText:False),
  (Code:$1800;Name:'FOOTERYT';IsText:False),
  (Code:$1880;Name:'FORMSHADE';IsText:False),
  (Code:$1900;Name:'FPRQ';IsText:False),
  (Code:$1A00;Name:'FROMAN';IsText:False),
  (Code:$1B00;Name:'FS';IsText:True),
  (Code:$1C00;Name:'FSWISS';IsText:False),
  (Code:$1D00;Name:'FTNBJ';IsText:False),
  (Code:$1E00;Name:'FTNNAR';IsText:False),
  (Code:$1F00;Name:'FTNRSTCONT';IsText:False),
  (Code:$2000;Name:'FTNSTART';IsText:False),
  (Code:$2100;Name:'GREEN';IsText:False),
  (Code:$2200;Name:'HEADER';IsText:False),
  (Code:$2240;Name:'HEADERY';IsText:False),
  (Code:$2260;Name:'HICH';IsText:False),
  (Code:$2280;Name:'HR';IsText:False),
  (Code:$22B0;Name:'HYPHCAPS';IsText:False),
  (Code:$22C0;Name:'HYPHHOTZ';IsText:False),
  (Code:$2300;Name:'I';IsText:False),
  (Code:$2380;Name:'ILVL';IsText:False),
  (Code:$2400;Name:'INFO';IsText:False),
  (Code:$2440;Name:'INTBL';IsText:False),
  (Code:$2460;Name:'INTBLCHAR';IsText:False),
  (Code:$2468;Name:'INTBLINT';IsText:False),
  (Code:$2480;Name:'JCLISTTAB';IsText:False),
  (Code:$2500;Name:'KEEP';IsText:False),
  (Code:$2580;Name:'KEEPN';IsText:False),
  (Code:$2600;Name:'LANG';IsText:False),
  (Code:$2680;Name:'LDBLQUOTE';IsText:True),
  (Code:$2700;Name:'LEVELFOLLOW';IsText:False),
  (Code:$2780;Name:'LEVELINDENT';IsText:False),
  (Code:$2800;Name:'LEVELJC';IsText:False),
  (Code:$2900;Name:'LEVELNFC';IsText:False),
  (Code:$2A00;Name:'LEVELNUMBERS';IsText:False),
  (Code:$2A80;Name:'LEVELSPACE';IsText:False),
  (Code:$2B00;Name:'LEVELSTARTAT';IsText:False),
  (Code:$2C00;Name:'LEVELTEXT';IsText:False),
  (Code:$2D00;Name:'LEVELTEXT';IsText:False),
  (Code:$2E00;Name:'LI';IsText:False),
  (Code:$2F00;Name:'LINE';IsText:False),
  (Code:$2F80;Name:'LINEX';IsText:False),
  (Code:$3000;Name:'LIST';IsText:False),
  (Code:$3100;Name:'LISTID';IsText:False),
  (Code:$3200;Name:'LISTLEVEL';IsText:False),
  (Code:$3280;Name:'LISTNAME';IsText:False),
  (Code:$3300;Name:'LISTOVERRIDE';IsText:False),
  (Code:$3400;Name:'LISTOVERRIDECOUNT';IsText:False),
  (Code:$3500;Name:'LISTOVERRIDETABLE';IsText:False),
  (Code:$3580;Name:'LISTSIMPLE';IsText:False),
  (Code:$3598;Name:'LISTTABLE';IsText:False),
  (Code:$35C0;Name:'LISTTEMPLATEID';IsText:False),
  (Code:$3600;Name:'LISTTEXT';IsText:False),
  (Code:$3640;Name:'LOCH';IsText:False),
  (Code:$3644;Name:'LOCHA';IsText:False),
  (Code:$3648;Name:'LOCHB';IsText:False),
  (Code:$3680;Name:'LQUOTE';IsText:True),
  (Code:$36C0;Name:'LS';IsText:False),
  (Code:$3700;Name:'MARGB';IsText:False),
  (Code:$3800;Name:'MARGBSXN';IsText:False),
  (Code:$3900;Name:'MARGL';IsText:False),
  (Code:$3A00;Name:'MARGLSXN';IsText:False),
  (Code:$3B00;Name:'MARGR';IsText:False),
  (Code:$3C00;Name:'MARGRSXN';IsText:False),
  (Code:$3D00;Name:'MARGT';IsText:False),
  (Code:$3E00;Name:'MARGTSXN';IsText:False),
  (Code:$3E20;Name:'MIN';IsText:False),
  (Code:$3E40;Name:'MO';IsText:False),
  (Code:$3E60;Name:'NOFCHARS';IsText:False),
  (Code:$3E64;Name:'NOFCHARSWS';IsText:False),
  (Code:$3E68;Name:'NOFPAGES';IsText:False),
  (Code:$3E70;Name:'NOFWORDS';IsText:False),
  (Code:$3E80;Name:'NOWIDCTLPAR';IsText:False),
  (Code:$3EA0;Name:'OPERATOR';IsText:True),
  (Code:$3EC0;Name:'OUTLINELEVEL';IsText:False),
  (Code:$3F00;Name:'PAGE';IsText:False),
  (Code:$3F80;Name:'PANOSE';IsText:True),
  (Code:$4000;Name:'PAPERH';IsText:False),
  (Code:$4100;Name:'PAPERW';IsText:False),
  (Code:$4200;Name:'PAR';IsText:True),
  (Code:$4300;Name:'PARD';IsText:False),
  (Code:$4360;Name:'PGBRDRFOOT';IsText:False),
  (Code:$4390;Name:'PGBRDRHEAD';IsText:False),
  (Code:$4400;Name:'PGDSC';IsText:False),
  (Code:$4500;Name:'PGDSCNXT';IsText:False),
  (Code:$4600;Name:'PGDSCUSE';IsText:False),
  (Code:$4700;Name:'PGHSXN';IsText:False),
  (Code:$4800;Name:'PGWSXN';IsText:False),
  (Code:$4900;Name:'PLAIN';IsText:False),
  (Code:$4920;Name:'PN';IsText:False),
  (Code:$4930;Name:'PNDEC';IsText:False),
  (Code:$4940;Name:'PNHANG';IsText:False),
  (Code:$4960;Name:'PNINDENT';IsText:False),
  (Code:$4970;Name:'PNLCLTR';IsText:False),
  (Code:$4980;Name:'PNLCRM';IsText:False),
  (Code:$4982;Name:'PNLVLBLT';IsText:False),
  (Code:$4983;Name:'PNLVLBODY';IsText:False),
  (Code:$4984;Name:'PNLVLCONT';IsText:False),
  (Code:$4988;Name:'PNRNOT';IsText:False),
  (Code:$498C;Name:'PNSECLVL';IsText:False),
  (Code:$4990;Name:'PNSTART';IsText:False),
  (Code:$4998;Name:'PNTEXT';IsText:False),
  (Code:$49A0;Name:'PNTXTA';IsText:False),
  (Code:$49A4;Name:'PNTXTB';IsText:False),
  (Code:$49B8;Name:'PNUCLTR';IsText:False),
  (Code:$49C0;Name:'PNUCRM';IsText:False),
  (Code:$4A00;Name:'Q';IsText:False),
  (Code:$4A30;Name:'QC';IsText:False),
  (Code:$4A60;Name:'QR';IsText:False),
  (Code:$4A80;Name:'RDBLQUOTE';IsText:True),
  (Code:$4B00;Name:'RED';IsText:False),
  (Code:$4B80;Name:'REVTIM';IsText:False),
  (Code:$4C00;Name:'RI';IsText:False),
  (Code:$4C40;Name:'ROW';IsText:False),
  (Code:$4C80;Name:'RQUOTE';IsText:True),
  (Code:$4D00;Name:'RTF';IsText:False),
  (Code:$4E00;Name:'S';IsText:False),
  (Code:$4F00;Name:'SA';IsText:False),
  (Code:$5000;Name:'SB';IsText:False),
  (Code:$5100;Name:'SBASEDON';IsText:False),
  (Code:$5200;Name:'SBKNONE';IsText:False),
  (Code:$5300;Name:'SECTD';IsText:False),
  (Code:$5380;Name:'SECTDEF';IsText:False),
  (Code:$53C0;Name:'SECTDEFAULTCL';IsText:False),
  (Code:$5400;Name:'SL';IsText:False),
  (Code:$5500;Name:'SNEXT';IsText:False),
  (Code:$5600;Name:'STYLESHEET';IsText:False),
  (Code:$5680;Name:'TAB';IsText:False),
  (Code:$56B0;Name:'TITLE';IsText:True),
  (Code:$5700;Name:'TQC';IsText:False),
  (Code:$5740;Name:'TRGAPH';IsText:False),
  (Code:$5760;Name:'TRLEFT';IsText:False),
  (Code:$5780;Name:'TROWD';IsText:False),
  (Code:$57A0;Name:'TRRH';IsText:False),
  (Code:$5800;Name:'TX';IsText:False),
  (Code:$5900;Name:'U';IsText:False),
  (Code:$5980;Name:'UC';IsText:False),
  (Code:$5A00;Name:'UL';IsText:False),
  (Code:$5B00;Name:'VERN';IsText:False),
  (Code:$5C00;Name:'VERSION';IsText:False),
  (Code:$5D00;Name:'VIEWKIND';IsText:False),
  (Code:$5E00;Name:'VIEWSCALE';IsText:False),
  (Code:$5F00;Name:'WIDCTLPAR';IsText:False),
  (Code:$6000;Name:'WIDOWCTRL';IsText:False),
  (Code:$6100;Name:'YR';IsText:False)
 );

Var
 RTFFile:File;
 C,C1,C2:Char;
 ReadOfs,CurrTag:Word;
 BeginSlash,IsTextTag:Boolean;
 SlashParam,CurrentWord:String;

Function EvalHex(hexStr:String):Integer;
Var
 HexVal,i,n:Integer;
 EvalErr:Boolean;
Begin
 evalErr:=False;
 hexVal:=0;
 For i:=1 TO Length(hexStr)do Begin
  n:=Pos(Upcase(hexStr[i]),'0123456789ABCDEF');
  If n=0 Then evalErr:=True
         Else hexVal:=hexVal*16+n-1;
 End;
 If(EvalErr)Then Begin
  hexVal:=0;
 END;
 EvalHex:=hexVal;
End;

Function IntToStr(I:Integer):String;
Var
 S:String;
Begin
 Str(I,S);
 IntToStr:=S;
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

Function StrToRTFTag(S:String):Word;
Var
 I:Integer;
Begin
 S:=StrToUpper(S);
 For I:=Length(S)downto 1 do Begin
  If S[I]in['A'..'Z']Then Break;
  If S[I]in['0'..'9',' ']Then Dec(S[0]);
 End;
 StrToRTFTag:=0;
 For I:=Low(TagList) to High(TagList)do Begin
  If StrToUpper(TagList[I].Name)=StrToUpper(S)Then Begin
   StrToRTFTag:=TagList[I].Code;
   IsTextTag:=TagList[I].IsText;
   Exit;
  End;
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('RTF2TXT : Cette commande permet de convertir un fichier RTF ',
                     'en format TXT.');
  WriteLn;
  WriteLn('Syntaxe : RTF2TXT source.rtf');
  WriteLn;
  WriteLn(' source.rtf   Nom du fichier a convertir');
  WriteLn;
 End
  Else
 If ParamCount>0 Then Begin
  {$I-}Assign(RTFFile,ParamStr(1));
  Reset(RTFFile,1);{$I+}
  If IOResult=0 Then Begin
   CurrentWord:='';
   SlashParam:='';
   BeginSlash:=False;
   IsTextTag:=True;
   While Not EOF(RTFFile) do BEgin
    BlockRead(RTFFile,C,SizeOf(C),ReadOfs);
    Case C of
     #0:;
     #10,#13:;
     '{':Begin
     End;
     '\':Begin
      BlockRead(RTFFile,C1,SizeOf(C),ReadOfs);
      Case C1 of
       '''':Begin
        BlockRead(RTFFile,C1,SizeOf(C),ReadOfs);
        BlockRead(RTFFile,C2,SizeOf(C),ReadOfs);
        CurrentWord:=CurrentWord+Chr(Byte(EvalHex(C1+C2)));
        BeginSlash:=False;
       End;
       '*':Begin
        BeginSlash:=False;
       End;
       '~':Begin
        If CurrentWord<>''Then Begin
         WriteLn(CurrentWord);
         CurrentWord:='';
        End;
        WriteLn;
        BeginSlash:=False;
       End;
       Else Begin
        SlashParam:=C1;
        While Not EOF(RTFFile)do Begin
         BlockRead(RTFFile,C1,SizeOf(C),ReadOfs);
         If Not(C1 in['A'..'Z','a'..'z','0'..'9','\'])Then Break;
         If C1='\'Then SlashParam:=''
                  Else SlashParam:=SlashParam+C1;
        End;
        CurrTag:=StrToRTFTag(SlashParam);
        Case CurrTag of
         RTF_BULLET:Write('ú');
         RTF_EMDASH:Write('-');
         RTF_ENDASH:Write('-');
         RTF_LDBLQUOTE:Write('®');
         RTF_RDBLQUOTE:Write('¯');
         RTF_PAR:Begin
          If CurrentWord<>''Then Begin
           WriteLn(CurrentWord);
           CurrentWord:='';
          End;
          WriteLn;
         End;
         RTF_RQUOTE:Write('''');
         RTF_TAB:Write(#9);
        End;
        If(IsTextTag)Then Begin
         BeginSlash:=False;
        End
         Else
        BeginSlash:=True;
       End;
      End;
     End;
     '}':Begin
     SlashParam:='';
      BeginSlash:=False;
     End;
     ' ':Begin
      If(BeginSlash)Then Begin
       SlashParam:=SlashParam+' ';
       BeginSlash:=False;
      End
       Else
      Begin
       Write(CurrentWord,' ');
       CurrentWord:='';
      End;
     End;
     Else Begin
      If(BeginSlash)Then SlashParam:=SlashParam+C
                    Else CurrentWord:=CurrentWord+C;
     End;
    End;
   End;
   Write(CurrentWord,' ');
   Close(RTFFile);
  End
   Else
  Begin
   WriteLn('Impossible de lire le fichier ',ParamStr(1));
   Halt(1);
  End;
 End;
END.