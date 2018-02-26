#!/bin/bash
set -e #exit if any issues

# Change hostname
echo "rtsp_viewer" | sudo tee /etc/hostname

# Upgrade the Package Manager Sources
sudo apt-get -y upgrade

# Update the Package Manger Sources
sudo apt-get -y update

# Install the Packages
if [ $(dpkg-query -W -f='${Status}' omxplayer 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  sudo apt-get install omxplayer -y
fi

# Install the Packages
if [ $(dpkg-query -W -f='${Status}' screen 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  sudo apt-get install screen  -y
fi

# Runs install script to keep script up to date
(sudo crontab -l; echo "0 5 * * * sudo /home/pi/rtsp_viewer/rtsp_viewer.sh update")| sudo crontab -

# Reboots system at 6am everyday
(sudo crontab -l ; echo "0 6 * * * sudo reboot")| sudo crontab -

# Runs script every minute between 6am and 11pm to make sure feeds are running
(sudo crontab -l ; echo "* 6-23 * * * sudo /home/pi/rtsp_viewer/rtsp_viewer.sh repair")| sudo crontab -

# Makes sure script gets started upon boot
(sudo crontab -l ; echo "@reboot sudo /home/pi/rtsp_viewer/rtsp_viewer.sh start")| sudo crontab -
