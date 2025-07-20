#!/bin/bash
command="cat ~/runner/games/group_MIO23T_games_* | wc -l"

last_result=$(eval $command)

while true; do
    result=$(eval $command)
    if [ $result -lt $last_result ]; then
        t -m "$result"
        last_result=$result
    fi

    # if result is 0 then exit
    if [ $result -eq 0 ]; then
        t -m "All games are finished ======================= "
        
        # mkdir ./rcl_to_send
        # cp ./log/MIO23T/**/*.rcl ./rcl_to_send
        # tar -czf rcl_to_send.tar.gz ./rcl_to_send

        # t -m "Logs are ready to send, size is $(du -sh ./logs_to_send.tar.gz | awk '{print $1}')"
        # # if file rcl_to_send.tar.gz is less than 50MB then send it
        # if [ $(du -k ./rcl_to_send.tar.gz | cut -f 1) -lt 20000 ]; then
        #     t -f ./rcl_to_send.tar.gz
        # else
        #     # split it into 50MB parts
        #     split -b 19M ./rcl_to_send.tar.gz ./rcl_to_send.tar.gz.part
        #     # loop and send them all 
        #     for file in ./rcl_to_send.tar.gz.part*; do
        #         t -f $file
        #     done

        #     t -m "# command to join files: cat rcl_to_send.tar.gz.part* > rcl_to_send.tar.gz"
        # fi
        exit 0
    fi

    ping_test=$(ping -c 1 127.0.0.1 | tail -1| awk '{print $4}' | cut -d '/' -f 2 | awk '{if($1 > 10) print "ping is "$1"ms"}')
    if [ ! -z "$ping_test" ]; then
        t -m "ping is more than 10ms"
    fi

    sleep 10
done
