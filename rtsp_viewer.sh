#!/bin/bash

#load config file
source /home/pi/rtsp_config.cfg

#loads file that has the feeds
readarray cameras < /home/pi/rtsp_feeds.txt

#---- There should be no need to edit anything below this line ----

# Start displaying camera feeds
case "$1" in
    start|repair)
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
        curl -o /home/pi/rtsp_viewer.sh https://raw.githubusercontent.com/maddog986/raspberry_pi_rtsp/master/rtsp_viewer.sh
	    chmod 755 /home/pi/rtsp_viewer.sh
    ;;

    *)
        echo "Usage: /home/pi/rtsp_viewer.sh {start|stop|repair} {screen width} {screen height} {cameras per row} {demo mode 0|1}"
        exit 1
    ;;
esac
