@echo off
goto :debut
14/02/2018  09:54                20 randomfolder.cmd
crée la liste des dossiers terminaux contenant un type de fichier donnés fourni en paramètre
puis sélectionne l'un d'entre eux au hasard pour le copier vers la destination fournie en paramètre
à faire : crée une liste des dossiers déjà copiés afin de ne pas la piocher à nouveau
à faire : purge la liste d'éviction lorsque la liste de dossiers valides ne contient plus qu'un seul item
à faire : accepter un paramètre en ligne de commande afin de déterminer s'il faut régénérer le liste des dossiers ou s'il faut prendre celle qui est éventuellement existante


PREREQUIS : Utilitaires Linux recompilés pour windows
SED
WC
SORT (ici renommé en usort pour éviter la confusion)
AWK (ici dans sa version GAWK)

:debut
:analysecmdline
set REGENERE=NON
set extrech=
set extout=
set pathout=
set pathbad=

:testaide vérifie si l'on a invoqué l'aide
if @%1@==@/H@ goto :help
if @%1@==@/h@ goto :help
if @%2@==@/H@ goto :help
if @%2@==@/h@ goto :help
if @%3@==@/H@ goto :help
if @%3@==@/h@ goto :help

:testnbparam vérifie si le nombre de paramètres fournis est valide
if @%2@==@@ goto :erreur
:: au moins deux paramètres requis, extension et dossier de destination
if not @%4@==@@ goto :erreur
:: pas plus de 3 paramètres acceptés, le 3° étant l'ordre de régénération de la liste

:testarg1 boucle qui teste si le premier paramètre correspond à une extension, un chemin ou un ordre de régénération, puis décale l'ordre des paramètres et recommence jusqu'à épuisement
REM @echo testarg1 %1
if @%1@==@@ goto :onbosse 
:: si on a épuisé tous les paramètres, il n'y a plus qu'à les traiter

REM @echo regenere %1
if %REGENERE%==OUI goto testextension
REM Pas besoin de retester le /G s'il a déjà été détecté
if @%1@==@/G@ set REGENERE=OUI
if @%1@==@/g@ set REGENERE=OUI
if %REGENERE%==OUI (
shift
goto testarg1
)

:testextension détermine quelle extension de fichier est concernée
REM @echo textextension %1
if not @%extrech%@==@@ goto testpath
REM pas la peine de déterminer une extenson si elle a déjà été déterminée
@echo %1|sed "s/\*/\?/g">%temp%\param.txt
gawk "/\\\|:/ {exit 3}"  %temp%\param.txt
if errorlevel 3 goto testpath
REM 3 = trouvé un élément constitutif d'un chemin
if errorlevel 1 goto erreur
REM 1 = erreur de awk
REM si l'on a un : ou un \ ce n'est pas une extension mais un nom de dossier

wc -m <%temp%\param.txt >%temp%\wc.txt
set /p nwbc=<%temp%\wc.txt
if @%nwbc%@ == @4@ (
:: 3 caractères pour l'extension plus le LF (plus un CR si on ne traite pas par SED)
set /p extrech=<%temp%\param.txt
sed -i "s/\?/_/g" %temp%\param.txt
set /p extout=<%temp%\param.txt
shift
goto testarg1
)

:testpath détermine vers quel endroit produire le résultat
REM @echo testpath %1
REM si on arrive ici c'est que le %1 n'est ni une extension ni le /G donc c'est potentiellement un chemin de destination
if not @%pathout%@==@@ goto testarg1
REM on ne redéfinit pas le chemin de destination si c'est déjà fait
if not exist %1\nul (
REM dans ce cas c'est que le %1 n'est pas un chemin existant
set pathbad=%1
shift
goto testarg1
REM et on n'a toujours pas de chemin valide
)

set pathout=%1
shift
goto testarg1


:onbosse
REM @echo on
REM @echo onbosse %extout% %extrech% x%pathout%x @%pathbad%@
REM @echo on
if not @%pathbad%@==@@ (
@echo %pathbad% n'est pas un chemin de destination valide
goto :eof
)
if @%pathout%@==@@ (
@echo pas de pathout
goto :erreur
)
REM @echo on bosse sur %extout% dans %pathout%
REM goto :eof
for %%I in (%extrech%.txt) do if %%~zI==0 del %%I
REM si le fichier existe mais est de taille nulle, on le régénère
if %REGENERE%==OUI (
del %extrech%.txt 2>nul
del %extrech%_vus.txt 2>nul
)
:generer génère la liste des dossiers parmi lesquels choisir
if not exist %extrech%.txt dir /s /b *.%extrech% |sed "s/^\(.*\\\\\)\(.*$\)/\1/"|usort -u -o %extrech%.txt
:: explication
::: dir /s /b *.%1 pour rechercher tous les fichiers du type recherché, avec leur chemin d'accès complet
::: sed "s/^\(.*\\\\\)\(.*$\)/\1/ pour ôter les noms de fichiers de la liste en question
::: de telle manière que l'on n'ait que des dossiers dont on est certain qu'ils contiennent au moins un fichier du type recherché
::: usort -u -o %extrech%.txt pour dédoublonner la liste des dossiers éligibles
:choisir parcourt la liste des dossiers hébergeant des fichiers de l'extension désirée de manière à en choisir un
wc -l %extrech%.txt|gawk "{print $1}" >%temp%\wc.txt
set /p nbwc=<%temp%\wc.txt
@echo il y a %nbwc% dossiers contenant des fichiers ayant l'extension %extrech%
set /a linenumber=(%random%*%nbwc%/32767)+1
@echo ligne %linenumber% choisie 
sed -n "%linenumber%p" %extrech%.txt >%temp%\param.txt
REM extrait la %linenumber%ième ligne de la liste des dossiers recherchés 
sed -i "%linenumber%d" %extrech%.txt
REM ôte la ligne sélectionnée des lignes à nouveaux sélectionnables
cat %temp%\param.txt >>%extrech%_vus.txt
REM rajoute la ligne sélectionnée à la liste des lignes déjà vues
REM cat %temp%\param.txt
@echo %cd%|sed "s/\\\/\\\\\\\\\\\\/g">%temp%\pattern.txt
REM attention pas d'espace dans les redirections sinon ça matche pas
set /p pattern=<%temp%\pattern.txt

set /p pathin=<%temp%\param.txt
sed "s/%pattern%//" %extrech%.txt >%temp%\param.txt
set /p param=<%temp%\param.txt
@echo xcopy /I "%pathin%*.%extrech%" "%pathout%%param%"
xcopy  "%pathin%*.%extrech%" "%pathout%%param%"
goto :eof
:eof
:erreur
msg /w %username% "Fournir au 2 ou 3 parametres - %0 /H pour l'aide"
goto :eof
:help
@echo %0 %1 %2 %3 %4 >helpfile:tmp
@echo AIDE >>helpfile:tmp
@echo Constitue une liste des dossiers terminaux contenant un type de fichier donnes fourni en parametre>>helpfile:tmp
@echo puis selectionne l'un d'entre eux au hasard pour le copier vers la destination fournie en parametre>>helpfile:tmp
@echo Parametres valides : >>helpfile:tmp
@echo /H : affiche cette page d'aide >>helpfile:tmp
@echo /G : reconstitue la liste des dossiers (utile lorsqu'on en a rajoute, renomme ou supprime un) >>helpfile:tmp
@echo chemin : chemin de destination pour copie du dossier choisi par ce script, encadré par des " si contient des espaces >>helpfile:tmp
@echo xxx : extension de fichier a rechercher, toujours sur 3 caracteres. ? acceptes, * remplaces par des ? >>helpfile:tmp
@echo chemin : chemin de destination pour copie du dossier choisi par ce script, encadrer par des ^" si contient des espaces >>helpfile:tmp
msg /w %username% <helpfile:tmp
del helpfile:tmp
goto :eof
