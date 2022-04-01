{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program RM;

Uses Crt,DOS;

Var
 Mode:(_None,_r);
 Option:Set Of (Question,Verbose);
 P:Byte;
 Err:Word;
 CurrParam:String;

Function GetErrorMessage(Code:Word):String;Begin
 Case Code of
  0:GetErrorMessage:='';
  2:GetErrorMessage:='Fichier introuvable';
  3:GetErrorMessage:='Chemin introuvable';
  4:GetErrorMessage:='Trop de fichiers ouvert';
  5:GetErrorMessage:='Acces refuse';
  6:GetErrorMessage:='Handle de fichier invalide';
  12:GetErrorMessage:='Mode d''acces sur disque invalide';
  15:GetErrorMessage:='Num‚ro de disque invalide';
  16:GetErrorMessage:='Impossible de supprimer le r‚pertoire';
  17:GetErrorMessage:='Impossible de renommer sur plusieurs volumes';
  100:GetErrorMessage:='Erreur de lecture … partir du disque';
  101:GetErrorMessage:='Erreur d''ecriture sur le disque';
  102:GetErrorMessage:='Fichier non attribue';
  103:GetErrorMessage:='Le fichier n''est pas ouvert';
  104:GetErrorMessage:='Le fichier n''est pas ouvert … l''entree';
  105:GetErrorMessage:='Le fichier n''est pas ouvert … la sortie';
  106:GetErrorMessage:='Numero invalide';
  150:GetErrorMessage:='Disque protege en ecriture';
  151:GetErrorMessage:='Peripherique est inconnu';
  152:GetErrorMessage:='Disque pas pret';
  153:GetErrorMessage:='Commande inconnue';
  154:GetErrorMessage:='Echec de verification CRC';
  155:GetErrorMessage:='Disque invalide';
  156:GetErrorMessage:='Erreur de recherche sur disque';
  157:GetErrorMessage:='Type de media invalide';
  158:GetErrorMessage:='Secteur introuvable';
  159:GetErrorMessage:='L''imprimante n''a plus de papier';
  160:GetErrorMessage:='Erreur d''ecriture sur le peripherique';
  161:GetErrorMessage:='Erreur de lecture sur le peripherique';
  162:GetErrorMessage:='Defaillance materielle';
  Else GetErrorMessage:='Erreur inconnue';
 End;
End;

Function DeleteFile(FileName:String):Integer;
Var
 F:File;
Begin
 {$I-}Assign(F,FileName);
 Erase(F);
 {$I+}
 DeleteFile:=IoResult;
End;

Procedure DeleteTree(Dir:String);
Var
 Info:SearchRec;
Begin
 FindFirst(Dir+'\*.*',AnyFile,Info);
 While DOSError=0do Begin
  If Info.Attr and Directory=Directory Then Begin
   If(Info.Name<>'.')and(Info.Name<>'..')Then DeleteTree(Dir+'\'+Info.Name);
  End
   Else
  Begin
   If(Question in Option)Then Begin
    Write('Supprimer ',Info.Name,' (O/N) ? ');
    Case ReadKey of
     #27:Exit;
     'O','o':Begin
      Err:=DeleteFile(Dir+'\'+Info.Name);
      WriteLn('Oui');
      If Err=0Then Begin
       If(Verbose in Option)Then WriteLn(Info.Name,' a ete supprime');
      End
       Else
      WriteLn(GetErrorMessage(Err));
     End;
     Else WriteLn('Non');
    End;
    WriteLn;
   End
    Else
   Begin
    Err:=DeleteFile(Dir+'\'+Info.Name);
    If Err=0Then Begin
     If(Verbose in Option)Then WriteLn(Info.Name,' a ete supprime');
    End
     Else
    WriteLn(GetErrorMessage(Err));
   End;
  End;
  FindNext(Info);
 End;
 {$I-}RmDir(Dir);{$I+}
END;

BEGIN
 Mode:=_None;
 Option:=[];
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ParamStr(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    WriteLn('ParamŠtre requis');
   End;
   Break;
  End
   Else
  If Mode=_r Then Begin
   DeleteTree(CurrParam);
  End
   Else
  If CurrParam='/?'Then Begin
   WriteLn('RM   Cette commande permet d''effectuer la suppression de fichier sur un unite de disque.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('RM [/?] [-i][-v] [-r repertoire] [fichier]');
   WriteLn;
   WriteLn('    /?          Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('    -i          Ce parametre permet de demander une confirmation avant de supprimer');
   WriteLn('    -r          Ce parametre permet de supprimer le repertoire recursivement');
   WriteLn('    --recursive Ce parametre permet de supprimer le repertoire recursivement');
   WriteLn('    -v          Ce parametre permet d''afficher les fichiers supprimees.');
   WriteLn('    --verbose   Ce parametre permet d''afficher les fichiers supprimees.');
   WriteLn(' fichier        Ce parametre permet d''indiquer le nom du fichier a supprimer.');
   Exit;
  End
   Else
  If CurrParam='-i'Then Include(Option,Question) Else
  If(CurrParam='-r')or(CurrParam='--recursive')Then Mode:=_r Else
  If(CurrParam='-v')or(CurrParam='--verbose')Then Include(Option,Verbose)
   Else
  Begin
   If(Question in Option)Then Begin
    Write('Supprimer ',CurrParam,' (O/N) ? ');
    Case ReadKey of
     #27:Exit;
     'O','o':Begin
      Err:=DeleteFile(CurrParam);
      WriteLn('Oui');
      If Err=0Then Begin
       If(Verbose in Option)Then WriteLn(CurrParam,' a ete supprime');
      End
       Else
      WriteLn(GetErrorMessage(Err));
     End;
     Else WriteLn('Non');
    End;
    WriteLn;
   End
    Else
   Begin
    Err:=DeleteFile(CurrParam);
    If Err=0Then Begin
     If(Verbose in Option)Then WriteLn(CurrParam,' a ete supprime');
    End
     Else
    WriteLn(GetErrorMessage(Err));
   End;
  End;
  If P>99Then Break;
 Until CurrParam='';
END.