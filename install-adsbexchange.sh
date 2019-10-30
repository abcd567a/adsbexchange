#!/bin/bash
INSTALL_FOLDER=/usr/share/adsbexchange

echo "Creating folder adsbexchange"
sudo mkdir ${INSTALL_FOLDER}

## CHECK FOR PREREQUISITE PACKAGES

echo -e "\e[95m  Installing packages needed to build and fulfill dependencies...\e[97m"
echo -e ""
sudo apt install -y git curl build-essential debhelper python-dev python3-dev socat
echo ""

## DOWNLOAD THE MLAT-CLIENT SOURCE
echo -e "\e[94m  Moving into adsbexchange directory...\e[97m"
cd ${INSTALL_FOLDER}
echo -e "\e[94m  Cloning the mlat-client git repository locally...\e[97m"
echo ""
git clone https://github.com/mutability/mlat-client.git


## BUILD AND INSTALL THE MLAT-CLIENT PACKAGE

echo ""
echo -e "\e[95m  Building and installing the mlat-client package...\e[97m"
echo ""
echo -e "\e[94m  Entering the mlat-client git repository directory...\e[97m"
cd ${INSTALL_FOLDER}/mlat-client

echo -e "\e[94m  Building the mlat-client package...\e[97m"
echo ""
sudo dpkg-buildpackage -b -uc
echo ""
echo -e "\e[94m  Installing the mlat-client package...\e[97m"
echo ""
sudo dpkg -i ${INSTALL_FOLDER}/mlat-client_*.deb

## CREATE THE SCRIPT TO EXECUTE AND MAINTAIN MLAT-CLIENT AND SOCAT TO FEED ADS-B EXCHANGE

# Some distros place socat in /usr/bin instead of /usr/sbin..
if [ -f "/usr/sbin/socat" ]; then
    SOCAT_PATH="/usr/sbin/socat"
fi
if [ -f "/usr/bin/socat" ]; then
    SOCAT_PATH="/usr/bin/socat"
fi


echo "Creating socat startup script file adsbx-socat.sh"
START_SOCAT=${INSTALL_FOLDER}/adsbx-socat.sh
sudo touch ${START_SOCAT}
sudo chmod 777 ${START_SOCAT}
echo "Writing code to startup file adsbx-socat.sh"
/bin/cat <<EOM >${START_SOCAT}
#!/bin/sh
/bin/bash > /var/log/adsbx-socat.log
while sleep 30
do
  ${SOCAT_PATH} -u TCP:localhost:30005 TCP:feed.adsbexchange.com:30005 >> /var/log/adsbx-socat.log 2>&1 
done
EOM
sudo chmod +x ${START_SOCAT}



echo "Creating mlat startup script file adsbx-mlat.sh"
START_MLAT=${INSTALL_FOLDER}/adsbx-mlat.sh
sudo touch ${START_MLAT}
sudo chmod 777 ${START_MLAT}
echo "Writing code to startup file adsbx-mlat.sh"
/bin/cat <<EOM >${START_MLAT}
#!/bin/sh
/bin/bash > /var/log/adsbx-mlat.log
MLAT_CONF=""
while read -r line; do MLAT_CONF="\${MLAT_CONF} \$line"; done < ${INSTALL_FOLDER}/adsbx-mlat.conf
/usr/bin/mlat-client \${MLAT_CONF} >> /var/log/adsbx-mlat.log  2>&1
EOM
sudo chmod +x ${START_MLAT}

echo -e "\e[94m  Creating the file adsbx-mlat.conf...\e[97m"
MLAT_CONFIG=${INSTALL_FOLDER}/adsbx-mlat.conf
sudo touch ${MLAT_CONFIG}
sudo chmod 777 ${MLAT_CONFIG}
echo "Writing code to config file adsbx-mlat.conf"
/bin/cat <<EOM >${MLAT_CONFIG}
--input-type dump1090
--input-connect 127.0.0.1:30005
--lat XX.XXXX
--lon YY.YYYY
--alt ZZZ
--user AAAAAAAA
--server feed.adsbexchange.com:31090
--no-udp
--results beast,connect,127.0.0.1:30104
EOM

sudo chmod 644 ${MLAT_CONFIG}

echo "Creating Service file adsbx-socat.service"
SERVICE_FILE=/lib/systemd/system/adsbx-socat.service
sudo touch ${SERVICE_FILE}
sudo chmod 777 ${SERVICE_FILE}
/bin/cat <<EOM >${SERVICE_FILE}
# adsbexchange socat service for systemd
[Unit]
Description=Adsbexchange-socat
Wants=network.target
After=network.target
[Service]
RuntimeDirectory=adsbexchange
RuntimeDirectoryMode=0755
ExecStart=${INSTALL_FOLDER}/adsbx-socat.sh
SyslogIdentifier=adsbexchange
Type=simple
Restart=on-failure
RestartSec=30
RestartPreventExitStatus=64
Nice=-5
[Install]
WantedBy=default.target

EOM

sudo chmod 744 ${SERVICE_FILE}
sudo systemctl enable adsbx-socat
sudo systemctl start adsbx-socat

echo "Creating Service file adsbx-mlat.service"
SERVICE_FILE=/lib/systemd/system/adsbx-mlat.service
sudo touch ${SERVICE_FILE}
sudo chmod 777 ${SERVICE_FILE}
/bin/cat <<EOM >${SERVICE_FILE}
# adsbexchange-mlat service for systemd
[Unit]
Description=Adsbexchange-mlat
Wants=network.target
After=network.target
[Service]
RuntimeDirectory=adsbexchange
RuntimeDirectoryMode=0755
ExecStart=${INSTALL_FOLDER}/adsbx-mlat.sh
SyslogIdentifier=adsbexchange
Type=simple
Restart=on-failure
RestartSec=30
RestartPreventExitStatus=64
Nice=-5
[Install]
WantedBy=default.target

EOM

sudo chmod 744 ${SERVICE_FILE}
sudo systemctl enable adsbx-mlat
sudo systemctl start adsbx-mlat
echo ""
echo -e "\e[32m========================================\e[39m"
echo -e "\e[32m  ADS-B Exchange feed setup is complete.\e[39m"
echo -e "\e[32m========================================\e[39m"
echo -e ""
echo -e "\e[31mYOU MUST DO FOLLOWING, ELSE ADSBEXCHANGE's MLAT WILL FAIL:\e[39m"
echo -e "\e[33m(1) Edit file /usr/share/adsbexchange/adsbx-mlat.conf, and \e[39m"
echo -e "\e[33m    add YOUR LATITUDE & LONGITUDE (in decimal degrees), \e[39m"
echo -e "\e[33m    ALTITUDE (in meters above sea), and USERID :\e[39m"
echo ""
echo -e "    sudo nano /usr/share/adsbexchange/adsbx-mlat.conf"
echo ""
echo -e "\e[33m    Replace XX.XXX YY.YYYY ZZZ and AAAAA by actual values.\e[39m \n"
echo -e "\e[33m(2) AFTER adding your data as above, restart adsbx mlat\e[39m"
echo -e "     sudo systemctl restart adsbx-mlat " 
echo ""
echo -e "\e[33m(3) Check Status\e[39m"
echo -e "     sudo systemctl status adsbx-mlat " 
echo -e "     sudo systemctl status adsbx-socat " 
echo ""
