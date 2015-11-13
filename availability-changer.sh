#!/bin/bash

replace() {
	echo $(pwd)
	sed -i -e 's/#define __TVOS_UNAVAILABLE                    __OS_AVAILABILITY(tvos,unavailable)/#define __TVOS_UNAVAILABLE_Q                    __OS_AVAILABILITY(tvos,unavailable)/g' Availability.h
	sed -i -e 's/#define __TVOS_PROHIBITED                     __OS_AVAILABILITY(tvos,unavailable)/#define __TVOS_PROHIBITED_Q                     __OS_AVAILABILITY(tvos,unavailable)/g' Availability.h
	rm Availability.h-e
}

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root | try the command sudo ./availability-changer.sh"
    exit
else
	cd /Applications/Xcode.app/Contents/Developer/Platforms/AppleTVOS.platform/Developer/SDKs/AppleTVOS.sdk/usr/include
	replace
	cd /Applications/Xcode.app/Contents/Developer/Platforms/AppleTVSimulator.platform/Developer/SDKs/AppleTVSimulator.sdk/usr/include
	replace
fi