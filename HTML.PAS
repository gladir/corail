{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program HTML;

Uses Strings;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Type
 ColorRec=Record
  ColorName:PChar;
  ColorCode:String[6];
 End;

Const
 ColorList:Array[0..142]of ColorRec=(
  (ColorName:'aliceblue';
   ColorCode:'F0F8FF'),
  (ColorName:'antiquewhite';
   ColorCode:'FAEBD7'),
  (ColorName:'aqua';
   ColorCode:'00FFFF'),
  (ColorName:'aquamarine';
   ColorCode:'7FFFD4'),
  (ColorName:'azure';
   ColorCode:'F0FFFF'),
  (ColorName:'beige';
   ColorCode:'F5F5DC'),
  (ColorName:'bisque';
   ColorCode:'FFE4C4'),
  (ColorName:'black';
   ColorCode:'000000'),
  (ColorName:'blanchedalmond';
   ColorCode:'FFEBCD'),
  (ColorName:'blue';
   ColorCode:'0000FF'),
  (ColorName:'blueviolet';
   ColorCode:'8A2BE2'),
  (ColorName:'brown';
   ColorCode:'A52A2A'),
  (ColorName:'burlywood';
   ColorCode:'DEB887'),
  (ColorName:'cadetblue';
   ColorCode:'5F9EA0'),
  (ColorName:'chartreuse';
   ColorCode:'7FFF00'),
  (ColorName:'chocolate';
   ColorCode:'D2691E'),
  (ColorName:'coral';
   ColorCode:'FF7F50'),
  (ColorName:'cornflowerblue';
   ColorCode:'6495ED'),
  (ColorName:'cornsilk';
   ColorCode:'FFF8DC'),
  (ColorName:'crimson';
   ColorCode:'DC143C'),
  (ColorName:'cyan';
   ColorCode:'00FFFF'),
  (ColorName:'darkblue';
   ColorCode:'00008B'),
  (ColorName:'darkcyan';
   ColorCode:'008B8B'),
  (ColorName:'darkgoldenrod';
   ColorCode:'B8860B'),
  (ColorName:'darkgrey';
   ColorCode:'A9A9A9'),
  (ColorName:'darkgreen';
   ColorCode:'006400'),
  (ColorName:'darkkhaki';
   ColorCode:'BDB76B'),
  (ColorName:'darkmagenta';
   ColorCode:'8B008B'),
  (ColorName:'darkolivegreen';
   ColorCode:'556B2F'),
  (ColorName:'darkorange';
   ColorCode:'FF8C00'),
  (ColorName:'darkorchid';
   ColorCode:'9932CC'),
  (ColorName:'darkred';
   ColorCode:'8B0000'),
  (ColorName:'darksalmon';
   ColorCode:'E9967A'),
  (ColorName:'darkseagreen';
   ColorCode:'8FBC8F'),
  (ColorName:'darkslateblue';
   ColorCode:'483D8B'),
  (ColorName:'darkslategray';
   ColorCode:'2F4F4F'),
  (ColorName:'darkslategrey';
   ColorCode:'2F4F4F'),
  (ColorName:'darkturquoise';
   ColorCode:'00CED1'),
  (ColorName:'darkviolet';
   ColorCode:'9400D3'),
  (ColorName:'deeppink';
   ColorCode:'FF1493'),
  (ColorName:'deepskyblue';
   ColorCode:'00BFFF'),
  (ColorName:'dimgrey';
   ColorCode:'696969'),
  (ColorName:'dodgerblue';
   ColorCode:'1E90FF'),
  (ColorName:'firebrick';
   ColorCode:'B22222'),
  (ColorName:'floralwhite';
   ColorCode:'FFFAF0'),
  (ColorName:'forestgreen';
   ColorCode:'228B22'),
  (ColorName:'fuchsia';
   ColorCode:'FF00FF'),
  (ColorName:'gainsboro';
   ColorCode:'DCDCDC'),
  (ColorName:'ghostwhite';
   ColorCode:'F8F8FF'),
  (ColorName:'gold';
   ColorCode:'FFD700'),
  (ColorName:'goldenrod';
   ColorCode:'DAA520'),
  (ColorName:'gray';
   ColorCode:'808080'),
  (ColorName:'grey';
   ColorCode:'808080'),
  (ColorName:'green';
   ColorCode:'008000'),
  (ColorName:'greenyellow';
   ColorCode:'ADFF2F'),
  (ColorName:'honeydew';
   ColorCode:'F0FFF0'),
  (ColorName:'hotpink';
   ColorCode:'FF69B4'),
  (ColorName:'indianred';
   ColorCode:'CD5C5C'),
  (ColorName:'indigo';
   ColorCode:'4B0082'),
  (ColorName:'ivory';
   ColorCode:'FFFFF0'),
  (ColorName:'khaki';
   ColorCode:'F0E68C'),
  (ColorName:'lavender';
   ColorCode:'E6E6FA'),
  (ColorName:'lavenderblush';
   ColorCode:'FFF0F5'),
  (ColorName:'lawngreen';
   ColorCode:'7CFC00'),
  (ColorName:'lemonchiffon';
   ColorCode:'FFFACD'),
  (ColorName:'lightblue';
   ColorCode:'ADD8E6'),
  (ColorName:'lightcoral';
   ColorCode:'F08080'),
  (ColorName:'lightcyan';
   ColorCode:'E0FFFF'),
  (ColorName:'lightgoldenrodyellow';
   ColorCode:'FAFAD2'),
  (ColorName:'lightgray';
   ColorCode:'D3D3D3'),
  (ColorName:'lightgreen';
   ColorCode:'90EE90'),
  (ColorName:'lightpink';
   ColorCode:'FFB6C1'),
  (ColorName:'lightsalmon';
   ColorCode:'FFA07A'),
  (ColorName:'lightseagreen';
   ColorCode:'20B2AA'),
  (ColorName:'lightskyblue';
   ColorCode:'87CEFA'),
  (ColorName:'lightslategray';
   ColorCode:'778899'),
  (ColorName:'lightslategrey';
   ColorCode:'778899'),
  (ColorName:'lightsteelblue';
   ColorCode:'B0C4DE'),
  (ColorName:'lightyellow';
   ColorCode:'FFFFE0'),
  (ColorName:'lime';
   ColorCode:'00FF00'),
  (ColorName:'limegreen';
   ColorCode:'32CD32'),
  (ColorName:'linen';
   ColorCode:'FAF0E6'),
  (ColorName:'magenta';
   ColorCode:'FF00FF'),
  (ColorName:'maroon';
   ColorCode:'800000'),
  (ColorName:'mediumaquamarine';
   ColorCode:'66CDAA'),
  (ColorName:'mediumblue';
   ColorCode:'0000CD'),
  (ColorName:'mediumorchid';
   ColorCode:'BA55D3'),
  (ColorName:'mediumpurple';
   ColorCode:'9370D8'),
  (ColorName:'mediumseagreen';
   ColorCode:'3CB371'),
  (ColorName:'mediumslateblue';
   ColorCode:'7B68EE'),
  (ColorName:'mediumspringgreen';
   ColorCode:'00FA9A'),
  (ColorName:'mediumturquoise';
   ColorCode:'48D1CC'),
  (ColorName:'mediumvioletred';
   ColorCode:'C71585'),
  (ColorName:'midnightblue';
   ColorCode:'191970'),
  (ColorName:'mintcream';
   ColorCode:'F5FFFA'),
  (ColorName:'mistyrose';
   ColorCode:'FFE4E1'),
  (ColorName:'moccasin';
   ColorCode:'FFE4B5'),
  (ColorName:'navajowhite';
   ColorCode:'FFDEAD'),
  (ColorName:'navy';
   ColorCode:'000080'),
  (ColorName:'oldlace';
   ColorCode:'FDF5E6'),
  (ColorName:'olive';
   ColorCode:'808000'),
  (ColorName:'olivedrab';
   ColorCode:'6B8E23'),
  (ColorName:'orange';
   ColorCode:'FFA500'),
  (ColorName:'orangered';
   ColorCode:'FF4500'),
  (ColorName:'orchid';
   ColorCode:'DA70D6'),
  (ColorName:'palegoldenrod';
   ColorCode:'EEE8AA'),
  (ColorName:'palegreen';
   ColorCode:'98FB98'),
  (ColorName:'paleturquoise';
   ColorCode:'AFEEEE'),
  (ColorName:'palevioletred';
   ColorCode:'D87093'),
  (ColorName:'papayawhip';
   ColorCode:'FFEFD5'),
  (ColorName:'peachpuff';
   ColorCode:'FFDAB9'),
  (ColorName:'peru';
   ColorCode:'CD853F'),
  (ColorName:'pink';
   ColorCode:'FFC0CB'),
  (ColorName:'plum';
   ColorCode:'DDA0DD'),
  (ColorName:'powderblue';
   ColorCode:'B0E0E6'),
  (ColorName:'purple';
   ColorCode:'800080'),
  (ColorName:'red';
   ColorCode:'FF0000'),
  (ColorName:'rosybrown';
   ColorCode:'BC8F8F'),
  (ColorName:'royalblue';
   ColorCode:'4169E1'),
  (ColorName:'saddlebrown';
   ColorCode:'8B4513'),
  (ColorName:'salmon';
   ColorCode:'FA8072'),
  (ColorName:'sandybrown';
   ColorCode:'F4A460'),
  (ColorName:'seagreen';
   ColorCode:'2E8B57'),
  (ColorName:'seashell';
   ColorCode:'FFF5EE'),
  (ColorName:'sienna';
   ColorCode:'A0522D'),
  (ColorName:'silver';
   ColorCode:'C0C0C0'),
  (ColorName:'skyblue';
   ColorCode:'87CEEB'),
  (ColorName:'slateblue';
   ColorCode:'6A5ACD'),
  (ColorName:'slategrey';
   ColorCode:'708090'),
  (ColorName:'snow';
   ColorCode:'FFFAFA'),
  (ColorName:'springgreen';
   ColorCode:'00FF7F'),
  (ColorName:'steelblue';
   ColorCode:'4682B4'),
  (ColorName:'tan';
   ColorCode:'D2B48C'),
  (ColorName:'teal';
   ColorCode:'008080'),
  (ColorName:'thistle';
   ColorCode:'D8BFD8'),
  (ColorName:'tomato';
   ColorCode:'FF6347'),
  (ColorName:'turquoise';
   ColorCode:'40E0D0'),
  (ColorName:'violet';
   ColorCode:'EE82EE'),
  (ColorName:'wheat';
   ColorCode:'F5DEB3'),
  (ColorName:'white';
   ColorCode:'FFFFFF'),
  (ColorName:'whitesmoke';
   ColorCode:'F5F5F5'),
  (ColorName:'yellow';
   ColorCode:'FFFF00'),
  (ColorName:'yellowgreen';
   ColorCode:'9ACD32')
 );

Var
 Value:Integer;
 Err:Word;
 I,J:Integer;
 Column,Line:Byte;


BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('HTML - Cette commande permet de lancer le generateur HTML.');
  WriteLn;
  WriteLn('Syntaxe : HTML TABLE colonne ligne');
  WriteLn('          HTML COLOR nom');
  WriteLn('          HTML nombre');
  WriteLn;
  WriteLn(' TABLE   Permet de generer un tableau.');
  WriteLn(' colonne Nombre de colonnes que doit avoir le tableau');
  WriteLn(' ligne   Nombre de lignes que doit avoir le tableau');
  WriteLn(' COLOR   Permet de generer un code de couleur');
  WriteLn(' nom     Nom de la couleur a rechercher');
  WriteLn(' nombre  Echantillion de la version HTML specifie');
 End
  Else
 If ParamCount>0 Then Begin
  If StrToUpper(ParamStr(1))='TABLE'Then Begin
   Val(ParamStr(2),Column,Err);
   If Err>0Then Begin
    WriteLn('Nombre de colonne invalide');
    Halt;
   End;
   Val(ParamStr(3),Line,Err);
   If Err>0Then Begin
    WriteLn('Nombre de ligne invalide');
    Halt;
   End;
   WriteLn('<table>');
   For J:=1 to Line do Begin
    WriteLn(' ':4,'<tr>');
    Write(' ':8);
    For I:=1 to Column do Begin
     Write('<td></td>');
    End;
    WriteLn;
    WriteLn(' ':4,'</tr>');
   End;
   WriteLn('</table>');
  End
   Else
  If StrToUpper(ParamStr(1))='COLOR'Then Begin
   For I:=Low(ColorList)to High(ColorList)do Begin
    If StrToUpper(StrPas(ColorList[I].ColorName))=StrToUpper(ParamStr(2))Then Begin
     WriteLn('#',ColorList[I].ColorCode);
     Exit;
    End;
   End;
  End
   Else
  If ParamStr(1)='1'Then Begin
   WriteLn('<BODY>');
   WriteLn('<!-- Mettre votre texte ici !>');
   WriteLn('</BODY>');
  End
   Else
  If ParamStr(1)='2'Then Begin
   WriteLn('<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">');
   WriteLn('<BODY>');
   WriteLn('<!-- Mettre votre texte ici !>');
   WriteLn('</BODY>');
  End
   Else
  If ParamStr(1)='3'Then Begin
   WriteLn('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN">');
   WriteLn('<HTML>');
   WriteLn('<BODY>');
   WriteLn('<!-- Mettre votre texte ici !>');
   WriteLn('</BODY>');
   WriteLn('</HTML>');
  End
   Else
  If ParamStr(1)='4'Then Begin
   WriteLn('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "https://www.w3.org/TR/html4/strict.dtd">');
   WriteLn('<HTML>');
   WriteLn('<BODY>');
   WriteLn('<!-- Mettre votre texte ici !>');
   WriteLn('</BODY>');
   WriteLn('</HTML>');
  End
   Else
  If ParamStr(1)='5'Then Begin
   WriteLn('<!DOCTYPE html>');
   WriteLn('<html lang="fr">');
   WriteLn('<body>');
   WriteLn('<!-- Mettre votre texte ici !>');
   WriteLn('</body>');
   WriteLn('</html>');
  End;
 End;
END.
