# Adsbexchange
### Installation script for Adsbexchange data feeder, with startup & control by systemd 
</br>

**Copy-paste following command in Terminal or SSH console and press Enter key. </br>
The script will install and configure Adsbexchange data feeder.** </br></br>
`sudo bash -c "$(wget -O - https://raw.githubusercontent.com/abcd567a/adsbexchange/master/install-adsbexchange.sh)"` 
</br></br></br>
The script builds and installs mlat-client from source code, and takes some more time to install dependencies and build tools and then takes some times to clone and build mlat-client package. Please be patient, and let the script complete.
</br>
### IMPORTANT POST-INSTALL INSTRUCTIONS: </br>
Upon completion of installation , you MUST do following, **else Adsbexchange MLAT will fail**: </br></br>
**(1) Edit file adsbx-mlat.conf** </br>
`   sudo nano /usr/share/adsbexchange/adsbx-mlat.conf` </br>

Replace XX.XXXX, YY.YYYY, ZZZ, and AAAA by actual values of: 
- Latitude (decimal degrees)
- Longitude (decimal degrees)
- Altitude (meters above sea)
- User (you can use any user id you like)

**(2) After editing and saving the file, restart adsbx-mlat** </br>
`sudo systemctl restart adsbx-mlat` </br>
`sudo systemctl status adsbx-mlat` </br>

</br> 

**After installation script finishes, it displays following message:**
```
========================================
  ADS-B Exchange feed setup is complete.
========================================

YOU MUST DO FOLLOWING, ELSE ADSBEXCHANGE's MLAT WILL FAIL:
(1) Edit file /usr/share/adsbexchange/adsbx-mlat.conf, and
    add YOUR LATITUDE & LONGITUDE (in decimal degrees),
    ALTITUDE (in meters above sea), and USERID :

    sudo nano /usr/share/adsbexchange/adsbx-mlat.conf

    Replace XX.XXX YY.YYYY ZZZ and AAAAA by actual values.

(2) After adding your data as above, restart adsbx mlat
     sudo systemctl restart adsbx-mlat

(3) Check Status
     sudo systemctl status adsbx-mlat
     sudo systemctl status adsbx-socat
```
</br>

## TO UNINSTALL COMPLETELY

```
sudo systemctl stop adsbx-mlat 
sudo systemctl disable adsbx-mlat 
sudo rm /lib/systemd/system/adsbx-mlat.service 

sudo systemctl stop adsbx-socat 
sudo systemctl disable adsbx-socat 
sudo rm /lib/systemd/system/adsbx-socat.service 

sudo dpkg --purge mlat-client
sudo rm -rf /usr/share/adsbexchange 

```


