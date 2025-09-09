# Dépendances Qt 6
sudo apt install -y qt6-base-dev qt6-tools-dev qt6-tools-dev-tools cmake

# Récupérer le code
git clone -b new_engine https://github.com/LongSoft/UEFITool.git
cd UEFITool

# Construire UEFITool NE
mkdir -p build-ne && cd build-ne
cmake -DQT_MAJOR=6 -DCMAKE_BUILD_TYPE=Release ../
cmake --build . -j$(nproc)
