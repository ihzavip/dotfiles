#!/usr/bin/env bash
[[ $1 == 0 ]] && cd "/home/lucy" && kitty
[[ $1 == 1 ]] && cd "/home/lucy" && /opt/calibre/bin/ebook-viewer --detach
