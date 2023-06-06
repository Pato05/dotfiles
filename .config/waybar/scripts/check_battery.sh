#!/bin/sh
CRIT=${1:-15}

for capacity in $(find /sys/class/power_supply/*/ -type f -name capacity)
do
    stat=$(cat ${capacity/capacity/status})
    perc=$(cat $capacity)
    bat=$(echo $capacity | cut -d'/' -f5)

    if [ -f "/tmp/battery_warning_$bat" ]; then
    	[ $stat == "Charging" ] && rm "/tmp/battery_warning_$bat" && continue
    	prev_perc=`cat /tmp/battery_warning_$bat`
    	# don't notify unless it's less than 5
    	[ $perc -gt 5 ] && continue
    fi

    if [ $perc -le $CRIT ] && [ $stat == "Discharging" ]; then
        # lazy solution to avoid annoying user
        echo $perc > "/tmp/battery_warning_$bat"
    	if [ $perc -le 5 ]; then
            notify-send -c alert --app-name=battery --urgency=critical "Battery Low ($bat)" "$perc% remaining. Hibernating soon."
    		continue
    	fi
        notify-send -c alert --app-name=battery --urgency=critical "Battery Low ($bat)" "Current charge: $perc%"
    fi
done

