#!/usr/bin/env bash

script="
function truncate(str, n) {
    return (str.length > n) ? str.slice(0, n-1) + '...' : str;
};
var s=Math.min(50, size());
for (i = 0; i < s; ++i) {
    text = str(read(i))
    // escape characters and remove bordering quotes
    text = JSON.stringify(text).slice(1, -1);
    // truncate si done automatically by rofi
    // but we want to keep it short for performance reasons
    text = text.slice(0, 150)
    print(i + ' ' + text + '\n');
}
" 
clips=$(copyq eval -- "$script")

# show the clipboard in dmenu
action=$(printf '%s\n' "${clips[@]}" | rofi -dmenu)

# action on selection
case $action in
    "") ;;
    d*) copyq remove $(echo "$action" | sed 's/.//' );; # type dXX to delete item number XX
    *) line=$(echo -E "$action" | sed 's/ .*//')
       copyq -- select $line # bump the selected item on top of the list
       #sleep 0.01
       #wl-paste
	esac

# TODO
# show images
# better delete (doesn't work if matches something)
# paste it right away
