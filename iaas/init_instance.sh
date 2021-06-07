#!/bin/sh

# Set Europe/Rome timezone
sudo timedatectl set-timezone Europe/Rome

echo "Waiting for volume to be attached..."

while [ ! -e /dev/vdb ]
do
  sleep 1
done

echo "Volume /dev/vdb was attached!"

echo "Creating FS and mouting volume to /mnt/disk1"
sudo mkfs.ext4 /dev/vdb
sudo mkdir /mnt/disk1
sudo mount /dev/vdb /mnt/disk1

echo "Setting up auto-mount"
sudo sh -c "echo '/dev/vdb /mnt/disk1 ext4 defaults 0 2' >> /etc/fstab"

echo "Adding authorized keys for ssh access"
__ECHO_EVAL__
__ECHO_ADMIN__

echo "Installing MariaDB"
sudo apt update
sudo apt install mariadb-server -y

echo "Stopping MariaDB"

echo "Setting password for MariaDB root user"
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '12345';"

echo "Setting bind-address to allow for connections from every host"
sudo sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf

echo "Adding grant privileges to mysql root user from everywhere"
sudo mysql -uroot -p12345 -e "GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '12345' WITH GRANT OPTION;FLUSH PRIVILEGES;"

echo "Restarting mysql service"
sudo systemctl restart mysql

mkdir /home/ubuntu/db-tools

cat << 'EOF' > /home/ubuntu/db-tools/backup_db.sh
#!/bin/sh 
FILENAME=db-backup-`date +"%FT%T"`
sudo sh -c "mysqldump -uroot -p12345 --single-transaction --routines --triggers --all-databases > /mnt/disk1/$FILENAME.sql"
EOF

chmod +x /home/ubuntu/db-tools/backup_db.sh

cat << 'EOF' > /home/ubuntu/db-tools/restore_db.sh
#!/bin/sh 
sudo mysql -uroot -p12345 -e "DROP DATABASE vehiclesapp_prod"
sudo mysql -uroot -p12345 -e "DROP DATABASE vehiclesapp_develop"
sudo mysql -uroot -p12345 < /mnt/disk1/$1
EOF

chmod +x /home/ubuntu/db-tools/restore_db.sh

cat << EOF > /home/ubuntu/init_db.sql
CREATE DATABASE vehiclesapp_prod;
USE vehiclesapp_prod;

CREATE TABLE vehicle(
    license_plate VARCHAR(40) PRIMARY KEY,
    vehicle_type VARCHAR(40),
    model VARCHAR(256),
    production_year INT
);

CREATE TABLE current_status(
    id VARCHAR(40) PRIMARY KEY REFERENCES vehicle(license_plate),
    fuel INT,
    mileage INT,
    current_speed INT
);

CREATE DATABASE vehiclesapp_develop;
USE vehiclesapp_develop;

CREATE TABLE vehicle(
    license_plate VARCHAR(40) PRIMARY KEY,
    vehicle_type VARCHAR(40),
    model VARCHAR(256),
    production_year INT
);

CREATE TABLE current_status(
    id VARCHAR(40) PRIMARY KEY REFERENCES vehicle(license_plate),
    fuel INT,
    mileage INT,
    current_speed INT
);

EOF


echo "Initializing database..."
sudo mysql -uroot -p12345 < /home/ubuntu/init_db.sql
rm /home/ubuntu/init_db.sql

echo "Filling database..."
git clone https://github.com/AndreFrigo/fog-cloud-computing-2021.git
cd fog-cloud-computing-2021/iaas/
python3 fill_db.py
sudo mysql -uroot -p12345 < ./fill_prod.sql
sudo mysql -uroot -p12345 < ./fill_develop.sql
cd ../..
rm -rf fog-cloud-computing-2021

echo "Adding cron job to backup database every day at 3 AM"
sudo sh -c "echo '0 3 * * *   ubuntu  sh /home/ubuntu/db-tools/backup_db.sh' >> /etc/crontab"

echo "Instance was started correctly and the initialization script finished successfully!" > /home/ubuntu/info.txt


