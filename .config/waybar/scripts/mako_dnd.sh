#!/bin/bash

ICONS=("󰪑" "󰂚")

function get_mode {
    local CURRENT_MODE=`makoctl mode | xargs echo -n`
    test "$CURRENT_MODE" == "dnd"
    return $?
}

function echo_mode {
    get_mode
    echo "${ICONS[$?]}"
}

function usage {
    echo "Usage: $0 [set/unset/toggle]"
}

function set_dnd {
    makoctl mode -s dnd
}

function unset_dnd {
    makoctl mode -s default
}

function toggle_mode {
    get_mode && unset_dnd || set_dnd
}

case "$1" in
    set) set_dnd;;
    unset) unset_dnd;;
    toggle) toggle_mode;;
    "") echo_mode;;
    *) usage;;
esac
