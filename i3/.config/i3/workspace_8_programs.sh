#!/usr/bin/env bash
[[ $1 == 0 ]] && cd "/home/lucy" && /opt/google/chrome/chrome
[[ $1 == 1 ]] && cd "/home/lucy" && /usr/lib/electron39/electron /usr/lib/obsidian/app.asar
