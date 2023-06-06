#!/usr/bin/env bash
# Connect to WIFI
# Modified from https://github.com/zbaylin/rofi-wifi-menu/blob/master/rofi-wifi-menu.sh

export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LANGUAGE="en_US:en"
# Starts a scan of available broadcasting SSIDs
# nmcli dev wifi rescan

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# FIELDS=SSID,SECURITY,BARS,ACTIVE
FIELDS=SSID,BARS,ACTIVE,SECURITY
POSITION=0
XOFF=-140
YOFF=6
LOC=3
CACHE=~/.local/tmp/wifi-wofi
WWIDTH=600
MAXHEIGHT=1000


# Really janky way of telling if there is currently a connection
CONSTATE=$(nmcli --fields WIFI general | awk '/enabled|disabled/ { printf "%s", $1 }')


if [[ "$CONSTATE" = "enabled" ]]; then
	TOGGLE="toggle off" 
    MANUAL="manual\n"
    while true; do echo ""; sleep 0.1; done | yad --progress --pulsate --fixed --center --hide-text --no-buttons --text='Searching for networks...' --title='' &
    YADPID=$!

    LIST=$(nmcli --fields "$FIELDS" device wifi list | sed '/^--/d' | sort -k2 -dr | \
        awk -F "  +" '/SSID/ {next} {;
            if (seen[$1]++) next;
            sub(/yes/, "󰸞", $3);
            sub(/no/, " ", $3);
            if ($4 == "--") $4=""; else $4="󰌋";
            printf "%s  %-4s %s  %-26s\n", $3,$2,$4,$1 }')"\n"

elif [[ "$CONSTATE" = "disabled" ]]; then
	TOGGLE="toggle on"
fi


# Other connections
LISTB=$(nmcli --fields NAME,TYPE,ACTIVE con show | sort -k2 -dr | \
  awk -F "[  ]{2,}" '/wifi/ {next} /loopback/ {next} /NAME/ {next} {;
    sub(/yes/, "󰸞", $3);
    sub(/no/, "    ", $3);
    sub(/bluetooth/, "󰂴", $2);
    sub(/wireguard/, "󰌆", $2);
    printf "%s      %s         %-26s\n", $3, $2, $1 }')

# Gives a list of known connections so we can parse it later
KNOWNCON=$(nmcli --fields 'NAME,ACTIVE' connection show)

CURRSSID=$(LANGUAGE=C nmcli -t -f active,ssid dev wifi | awk -F: '$1 ~ /^yes/ {print $2}')

if [[ ! -z $CURRSSID ]]; then
	HIGHLINE=$(echo  "$(echo "$LIST" | awk -F "[  ]{2,}" '{print $2}' | grep -Fxn -m 1 "$CURRSSID" | awk -F ":" '{print $1}') + 1" | bc )
fi


LINENUM=$(echo -e "toggle\n$MANUAL${LIST}${LISTB}" | wc -l)
echo "LINENUM: $LINENUM"

# If there are more than 20 SSIDs, the menu will still only have 20 lines
if [ "$LINENUM" -gt 20 ]; then # && [[ "$CONSTATE" =~ "enabled" ]]; then
	LINENUM=20
# Huh? Why would I even need this?
#elif [[ "$CONSTATE" =~ "disabled" ]]; then
#	LINENUM=1
fi

echo "NEW LINENUM: $LINENUM"

[ -z "$YADPID" ] ||  kill -9 $YADPID

CHENTRY=$(echo -e "$TOGGLE\n$MANUAL$LIST$LISTB" | \
    wofi -i --dmenu -p "Select connection" --width "$WWIDTH" --lines $((LINENUM+2)) --cache-file /dev/null --location $LOC --xoffset $XOFF --yoffset $YOFF | awk -F "[  ]{2,}" '{gsub(/<[^>]*>/, ""); print $0}')

export CHENTRY
echo $CHENTRY

CHSSID=$(echo "$CHENTRY" | awk '{ print $NF }')

# If the user inputs "manual" as their SSID in the start window, it will bring them to this screen
if [ "$CHENTRY" = "manual" ] ; then
	# Manual entry of the SSID and password (if appplicable)
	MSSID=$(echo "enter the SSID of the network (SSID,password)" | wofi --dmenu -p "Manual Entry: ")
	# Separating the password from the entered string
	MPASS=$(echo "$MSSID" | awk -F "," '{print $2}')

	# If the user entered a manual password, then use the password nmcli command
	if [ "$MPASS" = "" ]; then
		nmcli dev wifi con "$MSSID"
	else
		nmcli dev wifi con "$MSSID" password "$MPASS"
	fi

elif [ "$CHENTRY" = "toggle on" ]; then
	nmcli radio wifi on

elif [ "$CHENTRY" = "toggle off" ]; then
	nmcli radio wifi off

else

	# If the connection is already in use, then this will still be able to get the SSID
	if [ "$CHSSID" = "*" ]; then
		CHSSID=$(echo "$CHENTRY" | sed  's/\s\{2,\}/\|/g' | awk -F "|" '{print $3}')
	fi

	# Parses the list of preconfigured connections to see if it already contains the chosen SSID. This speeds up the connection process

    CN="$(echo "$KNOWNCON" | grep -w "$CHSSID")"
	if [[ $(echo "$CN" | awk '{ print $1 }') = "$CHSSID" ]]; then
        if [[ $(echo "$CN" | awk '{ print $2 }') = "yes" ]]; then
            nmcli con down "$CHSSID"
        else
		    nmcli con up "$CHSSID"
	    fi
    else
		nmcli dev wifi con "$CHSSID"
	fi

fi
