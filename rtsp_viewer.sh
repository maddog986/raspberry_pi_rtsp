#!/bin/bash
#cd /etc/init.d && wget https://raw.githubusercontent.com/maddog986/raspberry_pi_rtsp/master/rtsp_viewer && sudo chmod +x ./rtsp_viewer && sudo ./rtsp_viewer install

set -e #exit if any issues

# Start displaying camera feeds
case "$1" in
    start|repair)
        #load config file
        source $HOME/rtsp_config.cfg

        #loads file that has the feeds
        readarray cameras < $HOME/rtsp_feeds.txt

        if [ "$1" = "start" ]; then
            killall omxplayer screen
        fi

        totalcameras=${#cameras[@]}
        echo Total Cameras: $totalcameras

        totalrows=$(( $totalcameras / $perrow ))
        echo Total Rows: $totalrows

        columns=$(( $totalcameras / $totalrows ))
        echo Columns: $columns

        (( counter = 1 ))
        (( x = 0 ))
        (( y = 0 ))
        (( row = 1 ))
        (( w = width / columns )) #width of each camera will be based on how many per row
        (( h = height / totalrows ))
        (( x2 = w )) #width of the camera box
        (( y2 = h )) #height of the camera box

        echo Starting Cameras

        for i in "${cameras[@]}"
        do
            name='Camera_'$counter

            if [ "$demo" = "1" ]; then
		        i=rtsp://184.72.239.149/vod/mp4:BigBuckBunny_175k.mov;
	        fi

            #if camera not already playing, run the command
            if (!(screen -list | grep -q $name)) then
                if [[ $i != "" ]]; then
                    command="screen -dmS $name sh -c 'omxplayer --avdict rtsp_transport:tcp --win $x,$y,$x2,$y2 $i --live -n -1'"
                    echo $name Loading: $command
                    eval $command
                fi
            fi

            if (( $counter % $columns == 0 )); then
                (( row += 1 )) #increase row
                (( x = 0 )) #reset next camera to left position
                (( y += h )) #set new y value
                (( x2 = w )) #end width position of next camera box
                (( y2 += h )) #end height positon of next camera box
            else
                (( x += w )) #move camera over one spot
                (( x2 += w )) #move camera over one spot
            fi

            (( counter += 1 )) #camera loaded count
        done
    ;;

    # Stop displaying camera feeds
    stop)
        killall omxplayer.bin
        echo "Camera Display Ended"
    ;;

    # Update self
    update)
        # Stop script
        /etc/init.d/rtsp_viewer stop

        # Update script
        wget https://raw.githubusercontent.com/maddog986/raspberry_pi_rtsp/master/rtsp_viewer

        # Start it up again
        /etc/init.d/rtsp_viewer start
    ;;

    install)
        # Upgrade the Package Manager Sources
        apt-get -y upgrade

        # Update the Package Manger Sources
        apt-get -y update

        #create config file
        echo "width=1920
height=1080
perrow=2
demo=1" > $HOME/rtsp_config.cfg

        #create feeds file
        touch $HOME/rtsp_feeds.cfg

        # Install the Packages
        if [ $(dpkg-query -W -f='${Status}' omxplayer 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
            apt-get install omxplayer -y
        fi

        # Install the Packages
        if [ $(dpkg-query -W -f='${Status}' screen 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
            apt-get install screen  -y
        fi

        # Check to see if crontab already created
        if [ crontab -l | grep -q 'rtsp_viewer.sh update' -eq 0 ]; then
            # Runs install script to keep script up to date
            (crontab -l; echo "0 5 * * * sudo /etc/init.d/rtsp_viewer/rtsp_viewer.sh update")| crontab -
        fi

        # Check to see if crontab already created
        if [ crontab -l | grep -q 'sudo reboot' -eq 0 ]; then
            # Reboots system at 6am everyday
            (crontab -l ; echo "0 6 * * * sudo reboot")| crontab -
        fi

        # Check to see if crontab already created
        if [ crontab -l | grep -q 'rtsp_viewer.sh repair' -eq 0 ]; then
            # Runs script every minute between 6am and 11pm to make sure feeds are running
            (crontab -l ; echo "* 6-23 * * * sudo /etc/init.d/rtsp_viewer/rtsp_viewer.sh repair")| crontab -
        fi

        # Check to see if crontab already created
        if [ crontab -l | grep -q 'rtsp_viewer.sh start' -eq 0 ]; then
            # Makes sure script gets started upon boot
            (crontab -l ; echo "@reboot sudo /etc/init.d/rtsp_viewer/rtsp_viewer.sh start")| crontab -
        fi

        # Reboot so changes take effect
        reboot
    ;;

    *)
        echo "Usage: /etc/init.d/rtsp_viewer {start|stop|repair|update}"
        exit 1
    ;;
esac
