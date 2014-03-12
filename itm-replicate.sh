#!/bin/bash

intervalo=3
minutos=60
max=$[ $minutos * 60 / $intervalo ]
contador=0

function command(){
    ssh -p 8756 -i /SSH/asterisk/.ssh/id_rsa asterisk@pbx02-cr whoami
}

function slavealive() {
    if [ $HOSTNAME == "pbx01-cr" ]
    then
        ping -c 4 172.172.172.2 > /dev/null 2>&1
        if [ $? == 0 ]
        then
            return 0
        else
            return 1
        fi
    else
        ping -c 4 172.172.172.1 > /dev/null 2>&1
        if [ $? == 0 ]
        then
            return 0
        else
            return 1
        fi
    fi
}

function verifyvip() {
IP=$(ip addr show eth0|grep inet|grep 192|awk -F" " '{print $2}'|awk -F"/" '{print $1}'|grep 14)
if [[ -z "${IP}" ]]
    then
        return 1
    else
        return 0
fi
}

while true 
do
verifyvip
if [ $? == 0 ]
then 
    echo "soy master"
    slavealive
    if [ $? == 0 ]
    then
        if [ ${contador} == ${max} ]
        then
            command
        else
            if [ "$FLAG" == "UNREACHABLE" ]
            then
                echo "SLAVE JUST COME UP"
                command
                contador=0
            fi
            FLAG="REACHABLE"
        fi
    else
           echo "slave inalcanzable" 
           FLAG="UNREACHABLE"
    fi
else
    echo "soy slave"
fi
contador=$[ $contador + 1 ]
sleep 3
done