#!/bin/bash

tmux kill-session -t gbabt
tmux new -s gbabt -d

tmux send-keys -t gbabt 'bluetoothctl'
tmux send-keys -t gbabt Enter
tmux send-keys -t gbabt 'scan on'
tmux send-keys -t gbabt Enter

while true; do
        sleep 10
        connectCnt=$(bluetoothctl devices Connected | wc -l)
        if [ "x$connectCnt" != "x0" ]; then
                bluetoothctl devices Connected
                continue;
        fi
        bluetoothctl devices | grep GBABTController | while read gbabt; do
                mac=$(echo $gbabt | cut -d ' ' -f2)
                echo "found controller $mac"
                bluetoothctl pair "$mac"
                bluetoothctl connect "$mac"
        done
done
