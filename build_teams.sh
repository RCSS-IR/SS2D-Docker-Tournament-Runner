#!/bin/bash

# ------------- PUBLIC ONES

source ./utils.sh
TAG='latest'
DockerfileName='Dockerfile'
#------------------------------------------------------------

printHelp() {
  echo "
     Usage : ./build_teams.sh [OPTIONS]
     Options:
        -t , --tag
    "
}

checkParams() {
  while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    -t | --tag)
      TAG="$2"
      shift # past argument
      shift # past value
      ;;
    -f | --f)
      DockerfileName="$2"
      shift # past argument
      shift # past value
      ;;
    *) # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift              # past argument
      ;;
    esac
  done

  success=1

  if ((!success)); then
    printHelp
    exit 1
  fi
}

buildTeams() {
  for team in $(ls bins); do
    RUN "bash build_team.sh -n ${team} -t ${TAG} -f ${DockerfileName}" -po
  done
}

main() {
  checkParams "$@"
  buildTeams
}

main "$@"
exit 0