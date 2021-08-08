{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/corail)
  @abstract(Target: Free Pascal)
}

Program DELQ;

Uses Crt,DOS;

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

Function IsWildCard(Path:String):Boolean;Begin
 IsWildCard:=(Pos('*',Path)>0)or(Pos('?',Path)>0)
End;

Var
 P:Byte;
 Err:Word;
 F:File;
  Info:SearchRec;
 CurrParam:String;

BEGIN
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
  If(CurrParam='/?')or(CurrParam='/H')Then Begin
   WriteLn('DELQ   Cette commande permet d''effectuer la suppression ',
                   'de fichier en demandant une confirmation.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('DELQ [/?] fichier');
   WriteLn;
   WriteLn('      /?    Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('      /H    Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('  fichier   Ce parametre permet d''indiquer le nom du fichier a supprimer.');
   Exit;
  End;
  If IsWildCard(CurrParam)Then Begin
   FindFirst(CurrParam,AnyFile,Info);
   While DOSError=0 do Begin
    Write('Voulez-vous supprimer le fichier ',Info.Name,' (O/N) ? ');
    If ReadKey in['O','o']Then Begin
     WriteLn('Oui');
     {$I-}Assign(F,Info.Name);
     Erase(F);
     {$I+}
     Err:=IoResult;
     If Err=0Then WriteLn('1 fichier de supprime')
             Else WriteLn(GetErrorMessage(Err));
    End
     Else
    Begin
     WriteLn('Non');
     WriteLn('Passe au fichier suivant');
    End;
    FindNext(Info);
   End;
  End
   Else
  Begin
   Write('Voulez-vous supprimer le fichier ',CurrParam,' (O/N) ? ');
   If ReadKey in['O','o']Then Begin
    WriteLn('Oui');
    {$I-}Assign(F,CurrParam);
    Erase(F);
    {$I+}
    Err:=IoResult;
    If Err=0Then WriteLn('1 fichier de supprime')
            Else WriteLn(GetErrorMessage(Err));
   End
    Else
   Begin
    WriteLn('Non');
    WriteLn('Passe au fichier suivant');
   End;
  End;
  If P>9Then Break;
 Until CurrParam='';
END.