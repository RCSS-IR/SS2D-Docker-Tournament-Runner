#!/bin/bash
source ./utils.sh

HERE=`pwd`
NETWORK=
GAME_LIST=
ROOT_LOG_DIR=${here}/logs
ROOT_EVENT_DIR=${here}/events
TAG='latest'

printHelp() {
  echo "
     Usage : ./run_group.sh [OPTIONS]
     Options:
        -gl, --game-list [game list path]               list of games(file)
        -ld, --log_directory                            log directory
        -ed, --event_directory                          server and event directory
        -n , --network                                  network
        -ut, --use-telegram                             will use telegram
        -ud, --use-discord                              will use discord
        -ug, --use-google-drive                         will use google drive
        -t,  --tag                                      image tag
    "
}

checkParams() {
  while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    -gl | --game-list)
      GAME_LIST="$2"
      shift # past argument
      shift # past value
      ;;
    -ld | --log_directory)
      ROOT_LOG_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    -ed | --event_directory)
      ROOT_EVENT_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    -n | --network)
      NETWORK="$2"
      shift # past argument
      shift # past value
      ;;
    -ut | --use-telegram)
      USE_TELEGRAM=1
      shift # past argument
      ;;
    -ud | --use-discord)
      USE_DISCORD=1
      shift # past argument
      ;;
    -ug | --use-google-drive)
      USE_GDRIVE=1
      shift
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
  [ ! -z "$GAME_LIST" ] || success=0
  [ ! -z "$ROOT_LOG_DIR" ] || success=0
  [ ! -z "$ROOT_EVENT_DIR" ] || success=0
  [ ! -z "$NETWORK" ] || success=0

  if ((!success)); then
    printHelp
    exit 1
  fi
  if [[ "$(echo "$ROOT_LOG_DIR" | cut -c 1)" != '/' ]]
  then
    ROOT_LOG_DIR=${HERE}/${ROOT_LOG_DIR}
  fi
  if [[ "$(echo "$ROOT_EVENT_DIR" | cut -c 1)" != '/' ]]
  then
    ROOT_EVENT_DIR=${HERE}/${ROOT_EVENT_DIR}
  fi
  if [[ $ROOT_LOG_DIR = */ ]]
  then
    ROOT_LOG_DIR=${ROOT_LOG_DIR::-1}
  fi
  if [[ $ROOT_EVENT_DIR = */ ]]
  then
    ROOT_EVENT_DIR=${ROOT_EVENT_DIR::-1}
  fi
}

printParams() {
  echo "-------------------------------------"
  echo "            ENVIRONMENTS"
  echo "-------------------------------------"
  echo "GAME_LIST     : " ${GAME_LIST}
  echo "LOG_DIR       : " ${ROOT_LOG_DIR}
  echo "EVENT_DIR     : " ${ROOT_EVENT_DIR}
  echo "NETWORK       : " ${NETWORK}
  echo "-------------------------------------"
  echo "             LIST OF GAMES           "
  GAME_STRING="🟩 The server (${NETWORK}) will run the following games:"
  while read -r line
  do
    echo $line
    GAME_STRING="${GAME_STRING} \n ⚽ ${line}"
  done < ${GAME_LIST}
  if [[ "$SEND_GROUP_BY" == 1 ]]; then
    SEND_PUBLIC "$USE_TELEGRAM" "$USE_DISCORD" "$GAME_STRING"
  fi
  echo "-------------------------------------"
}

removeGame() {
  RUN "tail ${GAME_LIST} -n +2 > ${GAME_LIST}_tmp" -po
	RUN "cat ${GAME_LIST}_tmp > ${GAME_LIST}" -po
  RUN "rm ${GAME_LIST}_tmp" -po
}

main() {
  checkParams "$@"
  printParams
  counter=0
  while true; do
    counter=$((counter+1))
    line=$(head -n 1 ${GAME_LIST})
    if [ "$line" = "" ]; then
      break
    fi
    TIME_STAMP="G$( (tr -dc A-Za-z0-9 </dev/urandom | head -c 5) && echo '')P"
    game_conf=($line)
    GROUP_NAME=${game_conf[0]}
    LOG_DIR=${ROOT_LOG_DIR}/${GROUP_NAME}
    EVENT_DIR=${ROOT_EVENT_DIR}/${GROUP_NAME}
    RUN "mkdir -p ${LOG_DIR}"
    RUN "mkdir -p ${EVENT_DIR}"
    RUN "chmod 777 $LOG_DIR -R"
    RUN "chmod 777 $EVENT_DIR -R"
    echo "**********************************************************"
    echo "${line}"
    PARAMS="-ts ${TIME_STAMP} -st ${game_conf[1]} -gt ${game_conf[2]} -ld ${LOG_DIR} -ed ${EVENT_DIR} -l ${game_conf[3]} -r ${game_conf[4]} -n ${NETWORK} -t ${TAG}"
    if [[ "$USE_TELEGRAM" == 1 ]]; then
      echo "use telegram"
      PARAMS="${PARAMS} -ut "
    fi
    if [[ "$USE_DISCORD" == 1 ]]; then
      echo "use discord"
      PARAMS="${PARAMS} -ud "
    fi
    if [[ "$USE_GDRIVE" == 1 ]]; then
      echo "use google drive"
      GOOGLE_DRIVE_PARENT=$(CREATE_DIRECTORY_IN_GDRIVE $GROUP_NAME)
      PARAMS="${PARAMS} -ug -gdp $GOOGLE_DRIVE_PARENT"
    fi
    echo $PARAMS
    ./run_game.sh $PARAMS
    echo "**********************************************************"
    removeGame
    sleep 1
  done

}

main "$@"
exit 0