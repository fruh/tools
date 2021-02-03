#!/bin/bash
BURP_PATH=~/Applications/BurpSuitePro

java -jar ${BURP_PATH}/$(ls -t1 "${BURP_PATH}/" | grep .jar | head -n 1) 
