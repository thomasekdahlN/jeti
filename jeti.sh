#!/bin/sh

echo "\nPackage LUA Apps for Jeti App Store"

rm ekdahl.zip
mkdir ekdahl

cp Apps.csv ekdahl/Apps.csv
cp logo.png ekdahl/logo.png


#Make ECU App for Jeti App Store
cp ecu ekdahl/ecu
cp ecu.lc ekdahl/ecu.lc
cp ecu_16.lc ekdahl/ecu_16.lc

#Remove unneccessary folders
rm ekdahl/ecu/Arduino
rm ekdahl/ecu/docs/screenshots
rm ekdahl/ecu/lib/*.lua

#Make SpeedWar App for Jeti App Store
cp speedwar ekdahl/speedwar
cp speedwar.lc ekdahl/speedwar.lc

