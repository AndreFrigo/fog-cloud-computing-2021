echo "Downloading scripts"
git clone https://github.com/AndreFrigo/fog-cloud-computing-2021.git
cd fog-cloud-computing-2021/iaas/
cp init_instance.sh manage_db_backup.sh openstack_init.sh progetto_openrc.sh README ~/
cd ~/
chmod +x init_instance.sh manage_db_backup.sh openstack_init.sh
rm -rf fog-cloud-computing-2021
