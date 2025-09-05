LES TOOL QUE ÇA CONCERNE : chipsec

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
deactivate (pour get out venv)
