#!/bin/sh
exit
CRIT=${1:-15}



for capacity in $(find /sys/class/power_supply/*/ -type f -name capacity)
do
	stat=$(cat ${capacity/capacity/status})
	perc=$(cat $capacity)
	bat=$(echo $capacity | cut -d'/' -f5)

	if [ -f "/tmp/battery_warning_$bat" ]; then
		[ $stat == "Charging" ] && rm "/tmp/battery_warning_$bat" && continue
		prev_perc=`cat /tmp/battery_warning`
		# don't notify unless it's less than 5
		[ $prev_perc -gt 5 ] || continue
	fi

	if [ $perc -le $CRIT ] && [ $stat == "Discharging" ]; then
        # lazy solution to avoid annoying user
        cat $perc > /tmp/battery_warning
		if [ $perc -le 5 ]; then
			notify-send --urgency=critical "Battery Low" "Hibernating soon."
			continue
		fi
		notify-send --urgency=critical "Battery Low" "Current charge: $perc%"
	fi
done

