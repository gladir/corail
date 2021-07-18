<h2>Introduction</h2>

Les logiciels contenu dans Corail sont une séries de logiciels autonomes écrit en Pascal et n'ayant pas de dépendances avec d'autres fichiers Pascal mais uniquement d'un compilateur, comme par exemple Free Pascal.

<h2>Liste des fichiers</h2>

Voici la liste des différents fichiers proposés dans Corail :

<table>
		<tr>
			<th>Nom</th>
			<th>Description</th>	
		</tr>
		<tr>
			<td><b>APPEND.PAS</b></td>
			<td>Cette commande permet d'ajouter un fichier ASCII à la fin d'un autre fichier. Cette commande est originaire du LDOS pour TRS-80.</td>
		</tr>	
		<tr>
			<td><b>ASM6502.PAS</b></td>
			<td>Cette commande permet de lancer le compilateur de langage de programmation assembleur pour les microprocesseur 6502.</td>
		</tr>
		<tr>
			<td><b>ATTRIB.PAS</b></td>
			<td>Cette commande permet de demander ou de changer les attributs d'un fichier.</td>
		</tr>
		<tr>
			<td><b>BASENAME.PAS</b></td>
			<td>Cette commande permet de retourner le nom du fichier seulement à partir d'un chemin complet de nom de fichier. Cette commande est un équivalent de UNIX.</td>
		</tr>
		<tr>
			<td><b>CAL.PAS</b></td>
			<td>Cette commande permet d'afficher un calendrier. Cette commande est un équivalent de MSX-DOS ou UNIX.</td>
		</tr>
	        <tr>
			<td><b>CAT.PAS</b></td>
			<td>Cette commande permet d'afficher le contenu d'un/des fichiers. Cette commande est un équivalent de UNIX.</td>
		</tr>
		<tr>
			<td><b>COMMAND.PAS</b></td>
			<td>Logiciel clone d'un <i>COMMAND.COM</i> du système d'exploitation <a href="http://www.gladir.com/OS/DOS/intro.htm"><i>DOS</i></a>.</td>
		</tr>		
		<tr>
			<td><b>EVAL.PAS</b></td>
			<td>Cette commande permet d'évaluer des expressions mathématiques</td>
		</tr>		
		<tr>
			<td><b>EXEHEAD.PAS</b></td>
			<td>Cette commande permet d'afficher le contenu de l'entête d'un exécutable.</td>
		</tr>
		<tr>
			<td><b>FIND.PAS</b></td>
			<td>Cette commande permet de rechercher une chaine de caractères dans des fichiers. Cette commande est un équivalent du DOS.</td>
		</tr>
		<tr>
			<td><b>HEAD.PAS</b>
			<td>Cette commande permet d'afficher le début d'un fichier texte. Cette commande est un équivalent de UNIX ou Linux.</td>
		</tr>
 		<tr>
			<td><b>GEODELTA.PAS</b></td>
			<td>Cette commande permet de demander la distance entre deux villes, soit par coordonnée géographique, soit par son nom s'il est répertorié.</td>
		</tr>
	        <tr>
			<td><b>NUMBER.PAS</b></td>
			<td>Cette commande permet de retourner en texte un nombre. Similaire à la commande AIX.</td>
		</tr>
		<tr>
			<td><b>PWD.PAS</b></td>
			<td>Cette commande permet d'afficher le chemin du répertoire courant. Cette commande est un équivalent de UNIX.</td>
		</tr>
		<tr>
			<td><b>SPLIT.PAS</b></td>
			<td>Cette commande permet de séparer un fichier en plusieurs fichiers. Cette commande est un équivalent de UNIX.</td>
		</tr>
	        <tr>
			<td><b>TEE.PAS</b></td>
			<td>Cette commande permet d'envoyer l'entrée standard vers la sortie standard. Cette commande est un équivalent de UNIX ou Linux.</td>
		</tr>
	        <tr>
			<td><b>TOUCH.PAS</b></td>
			<td>Cette commande permet de changer la date et l'heure d'un fichier. Cette commande est un équivalent de UNIX, AIX et Linux.</td>
	        </tr>
	 	<tr>
			<td><b>TRUNCATE.PAS</b></td>
			<td>Cette commande permet de réduire ou augmenter la taille d'un fichier.</td>
		</tr>
		<tr>
			<td><b>VIEWHEX.PAS</b></td>
			<td>Cette commande permet de visualiser un fichier binaire en mode hexadécimal.</td>
		</tr>		
	        <tr>
			<td><b>WC.PAS</b>
			<td>Cette commande permet de compter le nombre de mots, de lignes ou de caractères.</td>
		</tr>
	</table>
	
Aperçu de la commande VIEWHEX :

![image](https://user-images.githubusercontent.com/11842176/123694681-a0523b80-d827-11eb-9314-14661688945d.png)

	
	
<h2>Compilation</h2>
	
Les fichiers Pascal n'ont aucune dépendances, il suffit de télécharger le fichier désiré et de le compiler avec Free Pascal avec la commande  :

<b>fpc</b> <i>LEFICHIER.PAS</i>
