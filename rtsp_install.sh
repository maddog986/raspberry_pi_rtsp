#!/bin/bash
#install command:
#mkdir /home/pi/rtsp_vewier && cd /home/pi/rtsp_vewier && wget https://github.com/maddog986/raspberry_pi_rtsp/archive/master.zip && unzip master.zip && mv raspberry_pi_rtsp-master/* . && rm -R raspberry_pi_rtsp-master && rm master.zip && chmod -R 755 /home/pi/rtsp_viewer && sudo ./rtsp_install.sh

set -e #exit if any issues

# Change hostname
echo "camera_viewer" | tee /etc/hostname

# Upgrade the Package Manager Sources
apt-get -y upgrade

# Update the Package Manger Sources
apt-get -y update

# Install the Packages
if [ $(dpkg-query -W -f='${Status}' omxplayer 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt-get install omxplayer -y
fi

# Install the Packages
if [ $(dpkg-query -W -f='${Status}' screen 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt-get install screen  -y
fi

# Runs install script to keep script up to date
(crontab -l; echo "0 5 * * * sudo /home/pi/rtsp_viewer/rtsp_viewer.sh update")| crontab -

# Reboots system at 6am everyday
(crontab -l ; echo "0 6 * * * sudo reboot")| crontab -

# Runs script every minute between 6am and 11pm to make sure feeds are running
(crontab -l ; echo "* 6-23 * * * sudo /home/pi/rtsp_viewer/rtsp_viewer.sh repair")| crontab -

# Makes sure script gets started upon boot
(crontab -l ; echo "@reboot sudo /home/pi/rtsp_viewer/rtsp_viewer.sh start")| crontab -

# Reboot so changes take effect
reboot
