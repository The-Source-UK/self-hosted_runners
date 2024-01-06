#!/bin/bash

# Variables
ORG=the-source-uk
ACCESS_TOKEN=${TOKEN}

# Functions
cleanup() {
    echo "Removing runner..."
    sleep 3 && sudo pkill -f config.sh &&  sudo pkill -f start.sh &
    ./config.sh remove --token ${REG_TOKEN}
}

REG_TOKEN=$( curl -L -X POST \
    -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/orgs/the-source-uk/actions/runners/registration-token | jq .token --raw-output
    )

echo ${REG_TOKEN} ${ORG}

cd /home/docker/actions-runner || exit 110

if [[ "${1}" == "shutdown" ]]; then
    echo "Shutting down node"
    cleanup
else
    # Begin start procedure
    if [[ -f "/var/run/docker.pid" ]]; then
        sudo rm -f /var/run/docker.pid
    fi
    sudo service docker start
    docker ps
    if [[ $? -gt 0 ]]; then
	sleep 5
   	sudo service docker start
    fi
    ./config.sh --unattended --ephemeral --replace --url https://github.com/${ORG} --token ${REG_TOKEN}

    # https://phoenixnap.com/kb/bash-trap-command
    trap 'cleanup; exit 130' INT
    trap 'cleanup; exit 143' TERM

    ./run.sh & wait $!
    cleanup
fi
