#!/bin/bash
#Used by the minutely cron

# Global Variables
ACTION="${1}"
CLEAN="${2}"

fn_stop_containers()
{
  # Stops the running containers, deregistering them from GitHub
  echo "Stopping everything"
  for container in $(docker ps | grep github | sed 's/.*github_runner_//')
  do
    docker exec github_runner_${container} bash start.sh shutdown
  done
  sleep 5
  docker compose down --remove-orphans
}

fn_start_containers()
{
  # Ensures a clean start of the new containers
  if [[ "${CLEAN}" == "--remove-image" ]]; then
    docker rmi -f aaronthesourceuk/actions-runner
  fi
  echo y | docker system prune -a >/dev/null
  docker compose up -d
}

#
# Script Start
#
cd /opt/Git/github_runner_containers/ || exit 1

case ${ACTION} in
  STOP)
    fn_stop_containers
    ;;
  START)
    fn_start_containers
    ;;
esac
