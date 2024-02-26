#!/bin/bash

cd $HOME
git clone https://github.com/darchr/gapbs.git
cd gapbs
git pull
make HOOKS=1 -j`nproc`

# downloading the twitter graph
cd $HOME
mkdir prebuilt-graphs
cd prebuilt-graphs
wget https://github.com/ANLAB-KAIST/traces/releases/download/twitter_rv.net/twitter_rv.net.00.gz
wget https://github.com/ANLAB-KAIST/traces/releases/download/twitter_rv.net/twitter_rv.net.01.gz
wget https://github.com/ANLAB-KAIST/traces/releases/download/twitter_rv.net/twitter_rv.net.02.gz
wget https://github.com/ANLAB-KAIST/traces/releases/download/twitter_rv.net/twitter_rv.net.03.gz
gunzip twitter_rv.net.00.gz
gunzip twitter_rv.net.01.gz
gunzip twitter_rv.net.02.gz
gunzip twitter_rv.net.03.gz
cat twitter_rv.net.00 twitter_rv.net.01 twitter_rv.net.02 twitter_rv.net.03 > twitter.el
rm twitter_rv*
