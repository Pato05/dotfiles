#!/bin/bash

STAY_TIMEOUT=1.5
POLL_RATE=0.05
ITERATIONS=`bc <<< "$STAY_TIMEOUT/$POLL_RATE"` # STAY_TIMEOUT/POLL_RATE, bash can't do float arithmetic
LOCK_FILENAME="/tmp/flyout.lock"

AUDIO=true
AUDIO_ICONS=("󰕿" "󰖀" "󰕾")
AUDIO_MUTED="󰖁"

SOURCE=true
SOURCE_ICON="󰍬"
SOURCE_MUTED="󰍭"

BRIGHTNESS=true
BRIGHTNESS_ICONS=("󰃞" "󰃟" "󰃠")

PB_CHARACTER="█"


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

    # keep these synchronized with the dimensions in sway config
    win_width=361 # 19ppt
    win_height=71 # 7ppt

    spacing_x=5
    spacing_y=45
    new_x=$(( (monitor_width - win_width)/2 ))
    new_y=$(( monitor_height - win_height - deco_height - spacing_y ))
}


usage() {
    echo "Usage: $0 'command to run the process in' tui/mako brightness/audio/source"
    exit 1
}

case "$2" in
    tui|mako)
        SHOW_TYPE="$2"
        ;;
    *) usage;; 
esac
case "$3" in
    brightness|audio|source)
        TYPE="$3"
        ;;
    *) usage;;
esac

_TYPE_UPPER="${TYPE^^}"
if [ "${!_TYPE_UPPER}" != "true" ]; then
    echo "$_TYPE_UPPER is disabled."
    exit 1
fi


# LOCK_FILENAME="$LOCK_FILENAME.$TYPE"

[ -f "$LOCK_FILENAME" ] && exit 1

test "$SHOW_TYPE" != "tui"
SUPPORTS_ESCAPE_CODES=$?

if [ "$1" != "started" ] && [ "$SHOW_TYPE" != "mako" ]; then
    if [ "$SHOW_TYPE" == "tui" ]; then
        # uncomment this to enable dynamic positioning
        # sway_get_bottom_center_coords
        exec $1 -- $0 started $2 $3 $new_x $new_y
    else
        echo "Invalid command."
    fi


    exit
fi
touch "$LOCK_FILENAME"


# uncomment this to enable dynamic positioning
# change this if you changed the app_id
# APP_ID="flyout"
# {
#     sleep 0.10 # give sway time to render the window
#     swaymsg '[app_id="'"$APP_ID"'"] move position '"$4 $5"
# } &

#clear

[ "$SUPPORTS_ESCAPE_CODES" == "1" ] && tput civis
get_vars_audio() {
    [ "$AUDIO" == "true" ] || return 1
    AUDIO_ISMUTED=`pamixer --get-mute`
    audio_custom_string=""
    [ "$AUDIO_ISMUTED" == "true" ] && audio_custom_string="muted" # make sure the length of this string is a multiply of 5 for perfect centering. otherwise it will be uncentered
    audio=`pamixer --get-volume`
    AUDIO_CHECK="$AUDIO_ISMUTED $audio"
}

get_vars_source() {
    [ "$SOURCE" == "true" ] || return 1
    SOURCE_ISMUTED=`pamixer --default-source --get-mute`
    source_custom_string=""
    [ "$SOURCE_ISMUTED" == "true" ] && source_custom_string="muted"
    source=`pamixer --default-source --get-volume`
    SOURCE_CHECK="$SOURCE_ISMUTED $source"
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
    SOURCE_BEFORE="${SOURCE_CHECK}"
    BRIGHTNESS_BEFORE="${BRIGHTNESS_CHECK}"
    get_vars_audio
    get_vars_source
    get_vars_brightness
    if [ "$AUDIO_BEFORE" != "$AUDIO_CHECK" ]; then
        CHANGED="audio"
        return 0
    fi

    if [ "$SOURCE_BEFORE" != "$SOURCE_CHECK" ]; then
        CHANGED="source"
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
    if [ "$AUDIO_ISMUTED" == "true" ]; then
        echo "$AUDIO_MUTED"
    else
        get_icon_default "$PERCENT" "${AUDIO_ICONS[@]}"
    fi
}

get_icon_brightness() {
    get_icon_default "$PERCENT" "${BRIGHTNESS_ICONS[@]}"
}

get_icon_source() {
    if [ "$SOURCE_ISMUTED" == "true" ]; then
        echo "$SOURCE_MUTED"
    else
        echo "$SOURCE_ICON"
    fi
}

get_progress_bar() {
    if [ ! -z "$custom_string" ]; then
        spaces=$((1+20+4))
        length=${#custom_string}
        offset=$(((spaces-length)/2))
        printf "%*s%s" $offset "" "$custom_string"
        echo -e
        return
    fi
    local PERC="$((PERCENT * 20 / 100))"
    local PROGRESS_COLOR="\e[37m"
    local PROGRESS_BG="\e[90m"
    local PROGRESS_RESET="\e[m"
    local PB_BG_CHARACTER="$PB_CHARACTER"
    if [ "$PERC" -gt 20 ]; then
        local PROGRESS_COLOR="\e[31m"
        PERC=20
    fi
    if [ "$SUPPORTS_ESCAPE_CODES" != "1" ]; then
        local PROGRESS_COLOR=""
        local PROGRESS_BG=""
        local PROGRESS_RESET=""
        local PB_BG_CHARACTER=" "
    fi
    echo -e "${PROGRESS_COLOR}$(repeat_str "$PB_CHARACTER" $PERC)${PROGRESS_BG}$(repeat_str "$PB_BG_CHARACTER" $((20-PERC)))${PROGRESS_RESET}"
}

show_flyout_tui() {
    tput cup 0 0 # move cursor to 0 0
    local CLEAR_LINE="\e[2K"
    echo ""
    icon=`$get_icon`
    echo -e "${CLEAR_LINE}  ${icon}  $(get_progress_bar)  $PERCENT%"
}

show_flyout_mako() {
    # delete prev flyout notifs
    # PREVIOUS_NOTIFICATIONS=( `makoctl list | jq -c '.data[0][] | select(.category.data=="flyout") | .id.data'` )
    # for notif in ${PREVIOUS_NOTIFICATIONS[@]}; do
    #     makoctl dismiss -n $notif
    # done
    icon=`$get_icon`
    NOTIF_CMD="notify-send -c flyout -h int:value:$PERCENT $icon"
    if [ -z "$NID" ]; then
        NID=`$NOTIF_CMD -p`
    else
        $NOTIF_CMD -r $NID
    fi
}

show_flyout="show_flyout_$SHOW_TYPE"

# sleep 2
get_vars_audio
get_vars_source
get_vars_brightness
reset_type() {
    local custom_string_name="${TYPE}_custom_string"
    get_icon="get_icon_$TYPE"
    PERCENT="${!TYPE}"
    custom_string="${!custom_string_name}"
}
reset_type
# echo percent: $PERCENT, audio: $audio, brightness: $brightness

$show_flyout

# ultra complex logic to avoid spawning more windows and updating current one
i=0
while [ "$i" -lt "$ITERATIONS" ]; do
    check_who_changed
    if [ ! -z "$CHANGED" ]; then
        TYPE="$CHANGED"
        reset_type
        PERCENT="${!TYPE}"
        $show_flyout
        i=0
        continue
    fi
    i=$((i+1))
    sleep $POLL_RATE
done


if [ "$SHOW_TYPE" == "mako" ]; then 
    echo "sending disconnect message"
    makoctl dismiss -n $NID
fi

[ "$SUPPORTS_ESCAPE_CODES" == "1" ] && tput cnorm
rm "$LOCK_FILENAME"
