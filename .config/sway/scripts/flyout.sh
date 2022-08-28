#!/bin/bash

# this must be the same in fl
STAY_TIMEOUT=2
POLL_RATE=0.05
ITERATIONS=`bc <<< "$STAY_TIMEOUT/$POLL_RATE"` # STAY_TIMEOUT/POLL_RATE, bash can't do float arithmetic
LOCK_FILENAME="/tmp/flyout.lock"

AUDIO=true
AUDIO_ICONS=("󰕿" "󰖀" "󰕾")
AUDIO_MUTED="󰖁"

BRIGHTNESS=true
BRIGHTNESS_ICONS=("󰃞" "󰃟" "󰃠")


set -o braceexpand

repeat_str() {
    i=0
    while [[ "$i" -lt "$2" ]]; do
        echo -n "$1"
        i=$((i+1))
    done
    # printf -- "$1%.0s" {1..$2}
}

display_center() {
    columns="$(tput cols)"
    while IFS= read -r line; do
        offset="$(( ($columns - ${#line}) / 2))"
        [ $offset -lt 0 ] && offset=0
        #echo "(${#line} - $columns) / 2 = $offset"
        printf "%*s%s" "$offset" "" "$line"
    done
}

sway_get_bottom_center_coords() {
    dimensions=$( swaymsg -t get_outputs |
        jq -r '.. | select(.focused?) | .current_mode | "\(.width)x\(.height)"' )
    scale=$(swaymsg -t get_outputs | jq -r '.. | select(.focused?) | .scale' )

    monitor_width=$(echo "${dimensions%x*}/$scale / 1" | bc)
    monitor_height=$(echo "${dimensions#*x}/$scale / 1" | bc)

    win_width=361 # 19ppt
    win_height=71 # 7ppt

    spacing_x=5
    spacing_y=45
    new_x=$(( (monitor_width - win_width)/2 ))
    new_y=$(( monitor_height - win_height - deco_height - spacing_y ))
}

case "$2" in
    brightness|audio)
        TYPE="$2"
        _TYPE_UPPER="${TYPE^^}"
        if [ "${!_TYPE_UPPER}" != "true" ]; then
            echo "$_TYPE_UPPER is disabled."
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 'command to run the process in' brightness/audio"
        exit 1
        ;;
esac

# LOCK_FILENAME="$LOCK_FILENAME.$TYPE"

[ -f "$LOCK_FILENAME" ] && exit 1

if [ "$1" != "started" ]; then
    sway_get_bottom_center_coords
    exec $1 -- $0 started $2 $new_x $new_y
fi


swaymsg move position $3 $4 &>/dev/null
( sleep 1; swaymsg focus tiling ) &>/dev/null &
touch "$LOCK_FILENAME"

# TEXT_COLOR="cdd6f4"

TEXT_COLOR="CD/D6/F4"
echo -n -e "\e]4;1;rgb:$TEXT_COLOR\e\\"

#clear

tput civis
get_vars_audio() {
    [ "$AUDIO" == "true" ] || return 1
    ISMUTED=`pamixer --get-mute`
    audio=`pamixer --get-volume`
    AUDIO_CHECK="$ISMUTED $audio"
}

get_vars_brightness() {
    [ "$BRIGHTNESS" == "true" ] || return 1
    local VALUE=`brightnessctl -m get`
    local MAX=`brightnessctl -m max`
    # random rounding till it matches with the waybar one
    brightness=$(((VALUE * 100 + MAX/2)/MAX))
    BRIGHTNESS_CHECK="$brightness"
}

check_who_changed() {
    AUDIO_BEFORE="${AUDIO_CHECK}"
    BRIGHTNESS_BEFORE="${BRIGHTNESS_CHECK}"
    get_vars_audio
    get_vars_brightness
    if [ "$AUDIO_BEFORE" != "$AUDIO_CHECK" ]; then
        CHANGED="audio"
        return 0
    fi

    if [ "$BRIGHTNESS_BEFORE" != "$BRIGHTNESS_CHECK" ]; then
        CHANGED="brightness"
        return 0
    fi

    CHANGED=""
}

# get_icon_default <PERCENT (0 <= x <= 100)> <...ICONS>
get_icon_default() {
    PERCENT="$1"
    shift
    ICONS=($@)
    ICON_COUNT=${#ICONS[@]}
    local index=$((PERCENT * $ICON_COUNT / 100))
    if [ "$index" -ge "$ICON_COUNT" ]; then
        index=$((ICON_COUNT-1))
    fi
    echo "${ICONS[$index]}"
}

get_icon_audio() {
    if [[ "$ISMUTED" == "true" ]]; then
        echo "$AUDIO_MUTED"
    else
        get_icon_default "$PERCENT" "${AUDIO_ICONS[@]}"
    fi
}

get_icon_brightness() {
    get_icon_default "$PERCENT" "${BRIGHTNESS_ICONS[@]}"
}


show_flyout() {
    tput cup 0 0
    echo ""
    PERC="$((PERCENT * 20 / 100))"
    icon=`$get_icon`
    echo -e "  \e[2K${icon}  \e[37m$(repeat_str "█" $PERC)\e[90m$(repeat_str "█" $((20-PERC)))\e[m  $PERCENT%"

}

# sleep 2
get_vars_audio
get_vars_brightness
reset_type() {
    get_icon="get_icon_$TYPE"
    PERCENT="${!TYPE}"
}
reset_type
# echo percent: $PERCENT, audio: $audio, brightness: $brightness

show_flyout

# ultra complex logic to avoid spawning more windows and updating current one
i=0
while [ "$i" -lt "$ITERATIONS" ]; do
    check_who_changed
    if [ ! -z "$CHANGED" ]; then
        TYPE="$CHANGED"
        reset_type
        PERCENT="${!TYPE}"
        show_flyout
        i=0
        continue
    fi
    i=$((i+1))
    sleep $POLL_RATE
done
tput cnorm
rm "$LOCK_FILENAME"
