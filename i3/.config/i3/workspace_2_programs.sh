#!/usr/bin/env bash
[[ $1 == 0 ]] && cd "/home/lucy" && /usr/lib/electron39/electron /usr/lib/obsidian/app.asar
[[ $1 == 1 ]] && cd "/home/lucy" && kitty
[[ $1 == 2 ]] && cd "/home/lucy" && /opt/brave-bin/brave --enable-features=VaapiVideoDecoder,VaapiVideoDecodeLinuxGL
