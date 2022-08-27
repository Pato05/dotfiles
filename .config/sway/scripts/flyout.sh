#!/bin/bash

# this must be the same in fl
STAY_TIMEOUT=2
POLL_RATE=0.05
ITERATIONS=40 # STAY_TIMEOUT/POLL_RATE, bash can't do float arithmetic
LOCK_FILENAME="/tmp/flyout.lock"

set -o braceexpand

repeat_str() {
    i=0
    while [[ "$i" -lt "$2" ]]; do
        echo -n "$1"
        i=$((i+1))
    done
    # printf -- "$1%.0s" {1..$2}
}

display_center(){
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

    win_dim=( $( swaymsg -t get_tree |
        jq '.. | select(.type?) | select(.type=="floating_con") | select(.focused?)|.rect.width, .rect.height, .deco_rect.height' ) )

    win_width=361
    win_height=71

    spacing_x=5
    spacing_y=45
    new_x=$(( (monitor_width - win_width)/2 ))
    new_y=$(( monitor_height - win_height - deco_height - spacing_y ))
}

[ -f "$LOCK_FILENAME" ] && exit 1
sway_get_bottom_center_coords
[ "$1" != "started" ] && exec $@ -- $0 started $new_x $new_y
swaymsg move position $2 $3
swaymsg focus tiling
touch "$LOCK_FILENAME"

ICONS=("󰕿" "󰖀" "󰕾")
# TEXT_COLOR="cdd6f4"

TEXT_COLOR="CD/D6/F4"
echo -n -e "\e]4;1;rgb:$TEXT_COLOR\e\\"

clear

tput civis
get_vars() {
    ISMUTED=`pamixer --get-mute`
    VOLUME=`pamixer --get-volume`
    CHECK="$ISMUTED $VOLUME"
}

show_flyout() {
    tput cup 0 0
    echo ""
    if [[ "$ISMUTED" == "true" ]]; then
        echo -e "\e[2K󰖁  muted" | display_center
    else
        PERC="$((VOLUME * 20 / 100))"
        icon_idx=$(((VOLUME - 1) * 3 / 100))
        icon="${ICONS[$icon_idx]}"
        echo -e "  \e[2K${icon}  \e[37m$(repeat_str "█" $PERC)\e[90m$(repeat_str "█" $((20-PERC)))\e[m  $VOLUME%"
    fi
}


get_vars
show_flyout

# ultra complex logic to avoid spawning more windows and updating current one
i=0
while [ "$i" -lt "$ITERATIONS" ]; do
    BEFORE="$CHECK"
    get_vars
    if [[ "$BEFORE" != "$CHECK" ]]; then
        show_flyout
        i=0
        continue
    fi
    
    [ $i -ge 0 ] && i=$((i+1))
    sleep $POLL_RATE
done
tput cnorm
rm "$LOCK_FILENAME"
