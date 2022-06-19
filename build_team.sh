#!/usr/bin/env bash
#!/bin/bash

# ------------- PUBLIC ONES

source ./utils.sh

NAME=
TAG='latest'

#------------------------------------------------------------

printHelp() {
  echo "
     Usage : ./build_team.sh [OPTIONS]
     Options:
        -n , --name                                  name
        -t , --tag
    "
}

checkParams() {
  while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    -n | --name)
      NAME="$2"
      shift # past argument
      shift # past value
      ;;
    -t | --tag)
      TAG="$2"
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
  [ ! -z "$NAME" ] || success=0

  if ((!success)); then
    printHelp
    exit 1
  fi
}

buildTeam() {
  echo "--- BUILDING ${NAME}"
  cp teams.Dockerfile bins/${NAME}/Dockerfile
  chmod -R 777 bins/${NAME}/*
  RUN "docker build -t ${NAME}:${TAG} bins/${NAME}" -po
  echo "--- END BUILDING ${NAME}"
}

main() {
  checkParams "$@"
  # ----- RUN
  buildTeam
}

main "$@"
exit 0