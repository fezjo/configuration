#!/bin/bash

# Get all outputs
outputs=$(swaymsg -t get_outputs | jq -r '.[] | .name')

# Get the current output
current_output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused == true).name')
echo "Current output: $current_output"

# List all outputs in a numbered list and ask for source output
echo "Choose source output:"
select source in $outputs; do
    [ -n "$source" ] && break
done

# List all outputs in a numbered list and ask for destination output
echo "Choose destination output:"
select destination in $outputs; do
    [ -n "$destination" ] && break
done

# Get all workspaces on the source output
workspaces=$(swaymsg -t get_workspaces | jq -r ".[] | select(.output == \"$source\") | .name")

# Move all workspaces to the destination output
for workspace in $workspaces; do
    swaymsg "focus output $source"
    swaymsg "move workspace to output $destination"
done

