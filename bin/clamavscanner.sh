#!/bin/zsh
sudo mkdir -p ~/Quarantine
sudo clamscan -r — scan-pdf=yes -l ~/Quarantine/infected.txt — move=~/Quarantine/ /