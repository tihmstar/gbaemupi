#!/bin/bash

if pidof -o %PPID -x -- "$0" >/dev/null; then
  printf >&2 '%s\n' "ERROR: Script $0 already running"
  exit 1
fi

echo "starting shawazu loop"
(
	while true; do 
    game=$(ls /shawazu/*.gb* 2>/dev/null)
    if [ "x$game" == "x" ]; then
     killall -9 mgba-qt
    fi
		sleep 5;
	done
) &


while true; do
	sleep 3
	game=$(ls /shawazu/*.gb* 2>/dev/null)
	if [ "x$game" == "x" ]; then
		continue;
	fi
	mgba-qt -f "$game" && killall -9 i3
done
