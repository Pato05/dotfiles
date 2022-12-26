#!/bin/bash

STAY_TIMEOUT=2 # in seconds, should be synchronized with mako's timeout too
POLL_RATE=0.1 # 100ms
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

# TODO: use fifo pipes instead of polling

set -o braceexpand

usage() {
    echo "Usage: $0 brightness/audio/source"
    exit 1
}

case "$1" in
    brightness|audio|source)
        TYPE="$1"
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

SHOULD_POLL_STATE=1

touch "$LOCK_FILENAME"
trap 'rm '"$LOCK_FILENAME"'; exit 0' SIGINT SIGHUP EXIT

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

show_flyout() {
    # delete prev flyout notifs
    # PREVIOUS_NOTIFICATIONS=( `makoctl list | jq -c '.data[0][] | select(.category.data=="flyout") | .id.data'` )
    # for notif in ${PREVIOUS_NOTIFICATIONS[@]}; do
    #     makoctl dismiss -n $notif
    # done
    icon=`$get_icon`
    NOTIF_CMD="notify-send -c flyout -h int:value:$PERCENT $icon"

    [ "$ISMUTED" == "true" ] && NOTIF_CMD="${NOTIF_CMD} --app-name=flyout-muted"

    NID=`makoctl list | jq --raw-output '[ .data[0][] | select(.category.data=="flyout") | .id.data ] | last | select (.!=null)'`
    if [ -z "$NID" ]; then
        NID=`$NOTIF_CMD -p`
    else
        $NOTIF_CMD -r $NID
    fi
}

# sleep 2
if [ "$SHOULD_POLL_STATE" == "1" ]; then
    get_vars_audio
    get_vars_source
    get_vars_brightness
else
    get_vars="get_vars_$TYPE"
    $get_vars
fi

check_time() {
    # local PID=$1
    local NOW=`date +'%s'`
    local ELAPSED=$((NOW - INITIAL_TIME))

    # echo "elapsed: $ELAPSED"

    if [ "$ELAPSED" -ge "$STAY_TIMEOUT" ]; then
        #kill -INT "$PID"
        exit
    fi
}

reset_type() {
    local custom_string_name="${TYPE}_custom_string"
    local muted_name="${TYPE^^}_ISMUTED"
    get_icon="get_icon_$TYPE"
    PERCENT="${!TYPE}"
    ISMUTED="${!muted_name}"
    custom_string="${!custom_string_name}"
    PERCENT="${!TYPE}"
}
reset_type

show_flyout

INITIAL_TIME=`date +'%s'`
if [ "$SHOULD_POLL_STATE" == "1" ]; then
    while true; do
        check_time
        check_who_changed
        if [ ! -z "$CHANGED" ]; then
            TYPE="$CHANGED"
            reset_type
            show_flyout
            INITIAL_TIME=`date +'%s'`
            continue
        fi
        sleep $POLL_RATE
    done
fi
