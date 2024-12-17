#!/bin/bash

sed 's/#.*//; s/^\s*//; s/\s*$//; /^-/d; /^\s*$/d; s/^+ //' packages.md | yay -S --needed -
