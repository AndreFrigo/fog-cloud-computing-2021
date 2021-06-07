echo "Downloading scripts"
git clone https://github.com/AndreFrigo/fog-cloud-computing-2021.git
cd fog-cloud-computing-2021/paas/
cp paas_init.sh update_app.sh README ~/
cd ~/
chmod +x paas_init.sh update_app.sh
rm -rf fog-cloud-computing-2021