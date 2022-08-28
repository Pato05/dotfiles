#!/bin/bash
ID="$RANDOM$RANDOM$RANDOM$RANDOM"
cmd="foot --app-id=$ID"

sway_get_bottom_center_coords() {
    if [ ! -z "$1" ]; then
        extra=' | select(.app_id=="'"$1"'")'
    fi
    local dimensions=$( swaymsg -t get_outputs |
        jq -r '.. | select(.focused?) | .current_mode | "\(.width)x\(.height)"' )
    scale=$(swaymsg -t get_outputs | jq -r '.. | select(.focused?) | .scale' )

    local monitor_width=$(echo "${dimensions%x*}/$scale / 1" | bc)
    local monitor_height=$(echo "${dimensions#*x}/$scale / 1" | bc)
    win_dim=( `swaymsg -t get_tree |
        jq '.. | select(.type?) | select(.type=="floating_con")'"$extra"' | select(.focused?)|.rect.width, .rect.height, .deco_rect.height' `)

    win_width=${win_dim[0]}
    win_height=${win_dim[1]}
    deco_height=${win_dim[2]}

    local spacing_x=5
    local spacing_y=45
    new_x=$(( (monitor_width - win_width)/2 ))
    new_y=$(( monitor_height - win_height - deco_height - spacing_y ))
}

SWAY_CONFIG="$HOME/.config/sway/config"

if [ "$1" != "-" ]; then
    echo "Gathering data from $SWAY_CONFIG..."
    FOR_WINDOW_COMMAND=`grep 'for_window \[app_id="^flyout$"\]' "$SWAY_CONFIG"`
    if [ -z "$FOR_WINDOW_COMMAND" ]; then
        echo "Failed to get for_window command."
        exit 1
    fi
    # echo "$FOR_WINDOW_COMMAND"
    FOR_WINDOW_COMMAND=`echo "$FOR_WINDOW_COMMAND" | sed -E 's/for_window \[app_id="\^flyout\\\$"\]/[app_id="^'"$ID"'\$"]/' | sed 's/\, move position \\\$spawn_coords//'`
    echo "Attempting to get coords..."
    exec $cmd -- $0 - &>/dev/null &
    sleep 0.25
    #echo $FOR_WINDOW_COMMAND
    swaymsg "$FOR_WINDOW_COMMAND"
    swaymsg focus floating
    sway_get_bottom_center_coords "$ID"
    swaymsg move position $new_x $new_y
    echo "copied coords: x=$new_x y=$new_y"
    echo "$new_x $new_y" | wl-copy

    echo "Please check if the red box is aligned correctly."

    wait
else
    tput civis
    sleep 0.5
    echo -e '\e[41m'
    i=0
    columns=`tput cols`
    while [ $i -lt 6 ]; do
        j=0
        while [ $j -lt $columns ]; do
            echo -n ' '
            j=$((j+1))
        done
        echo ''
        i=$((i+1))
    done
    sleep 5
    tput cnorm
fi
