LES TOOL QUE ÇA CONCERNE : chipsec MEanalyser

POUR UTILISER UNE COMMANDE INSTALLÉ DEPUIS GITHUB!!!!
TOUJOURS COMMENCER PAR "source ~/venvs/$tool/bin/activate"

POUR LES MISES À JOUR DES TOOL GITHUB
git pull

**si ne fonctionne pas car grosse mise ajour python**

rm -rf ~/venvs/$tool
python3 -m venv ~/venvs/$tool
. ~/venvs/$tool/bin/activate
which python (doit etre le chemain du tool)
cd ~/tools/$tool
git pull
pip install -e .
POUR APPELER LE SCRIPT APRES INSTALLATION (PYTHON3 -M MEA.PY ~/SPI_ME.BIN)
deactivate (pour get out venv)

SI DOIT INSTALLÉ DÉPENDENCE
. ~/venvs/$tool/bin/activate
pip install -U pip #(pour updaté pip)
SI PAS INSTALLÉ
pip install -e . #(dans le dossier)
pip install crccheck autrePaquet
