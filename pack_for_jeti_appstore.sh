#!/bin/sh

echo "\nPackage LUA Apps for Jeti App Store"

#Remove old dir
rm ekdahl
rm ekdahl.tar.bz2

#Create new dir
mkdir ekdahl

cp Apps.csv ekdahl/Apps.csv
cp logo.png ekdahl/logo.png


#Make ECU App for Jeti App Store
cp -r ecu ekdahl/ecu
cp ecu.lc ekdahl/ecu.lc
cp ecu_16.lc ekdahl/ecu_16.lc

#Remove unneccessary folders
rm ekdahl/ecu/Arduino
rm ekdahl/ecu/docs/screenshots
rm ekdahl/ecu/lib/*.lua

#Make SpeedWar App for Jeti App Store
cp -r speedwar ekdahl/speedwar
cp speedwar.lc ekdahl/speedwar.lc

cd ekdahl
find . -name .DS_Store -print0 | xargs -0 git rm -f --ignore-unmatch

cd ..
tar -jcvf ekdahl.tar.bz2 ekdahl