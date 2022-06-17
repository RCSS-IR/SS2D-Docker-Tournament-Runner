#!/bin/bash

# ------------- PUBLIC ONES

source ./utils.sh

NETWORK=
SERVER_DIRECTORY=

#------------------------------------------------------------

printHelp() {
  echo "
     Usage : ./kill_server.sh [OPTIONS]
     Options:
        -n , --network                                  network
        -sd, --server-directory                         network/server directory for test servers
    "
}

checkParams() {
  while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    -n | --network)
      NETWORK="$2"
      shift # past argument
      shift # past value
      ;;
    -sd | --server-directory)
      SERVER_DIRECTORY="$2"
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
  [ ! -z "$NETWORK" ] || success=0

  if ((!success)); then
    printHelp
    exit 1
  fi
}

killLastServer() {
  echo "--- kill ${NETWORK} server & players"
  RUN "docker kill ${NETWORK}_server" -nc
  RUN "docker rm ${NETWORK}_server" -nc
  RUN "docker kill \$(docker ps -a |grep ${NETWORK} |awk '{print \$1}')"
  RUN "docker rm \$(docker ps -a |grep ${NETWORK} |awk '{print \$1}')"
  echo "--- ${NETWORK} server & players killed"
}

freeTestServer(){
  if [ ! -z "$SERVER_DIRECTORY" ];
  then
    if  [[ $NETWORK == test* ]] ;
    then
      if [ ! -d "$SERVER_DIRECTORY" ]; then
        RUN "mkdir -p ${SERVER_DIRECTORY}"
        RUN "echo 1 > ${SERVER_DIRECTORY}/test1" -po
        RUN "echo 1 > ${SERVER_DIRECTORY}/test2" -po
        RUN "echo 1 > ${SERVER_DIRECTORY}/test3" -po
        RUN "echo 1 > ${SERVER_DIRECTORY}/test4" -po
        # Take action if $DIR exists. #
        echo "Installing config files in ${DIR}..."
      fi
      RUN "echo 1 > ${SERVER_DIRECTORY}/${NETWORK}" -po
    fi
  fi
}
main() {
  checkParams "$@"
  # ----- RUN
  killLastServer
  freeTestServer
}

main "$@"
exit 0
