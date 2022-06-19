#!/bin/bash
source ./utils.sh

HERE=`pwd`
NETWORK=
TEAM_LIST=
ROOT_LOG_DIR=${here}/logs
ROOT_EVENT_DIR=${here}/events
USE_TELEGRAM=1
GROUP_NAME=
LEAGUE_TYPE=
TAG='latest'

printHelp() {
  echo "
     Usage : ./run_group.sh [OPTIONS]
     Options:
        -tl, --team-list [team list path]               list of teams(file)
        -ld, --log_directory                            log directory
        -ed, --event_directory                          server and event directory
        -n , --network                                  network
        -ut, --use-telegram                             will use telegram
        -ud, --use-discord                              will use discord
        -ug, --use-google-drive                         will use google drive
				-gn , --group-name                              group name
				-st, --ss2d-type [starter OR major]             type of competition
        -t,  --tag                                      image tag
    "
}

checkParams() {
  while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    -tl | --team-list)
      TEAM_LIST="$2"
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
		-gn | --group-name)
      GROUP_NAME="$2"
      shift # past argument
      shift # past value
      ;;
		-st | --ss2d-type)
      LEAGUE_TYPE="$2"
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
  [ ! -z "$TEAM_LIST" ] || success=0
  [ ! -z "$ROOT_LOG_DIR" ] || success=0
  [ ! -z "$ROOT_EVENT_DIR" ] || success=0
  [ ! -z "$NETWORK" ] || success=0
	[ ! -z "$GROUP_NAME" ] || success=0
	[ ! -z "$LEAGUE_TYPE" ] || success=0

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
  echo "TEAM_LIST     : " ${TEAM_LIST}
  echo "LOG_DIR       : " ${ROOT_LOG_DIR}
  echo "EVENT_DIR     : " ${ROOT_EVENT_DIR}
  echo "NETWORK       : " ${NETWORK}
	echo "LEAGUE_TYPE       : " ${LEAGUE_TYPE}
	echo "GROUP_NAME       : " ${GROUP_NAME}
  echo "-------------------------------------"
  echo "             LIST OF TEAMS           "
  GAME_STRING="🟩 The server (${NETWORK}) will run games bewteen the following teams by using stepladder format:"
  while read -r line
  do
    echo $line
    GAME_STRING="${GAME_STRING} \n ⚽ ${line}"
  done < ${TEAM_LIST}

  if [[ "$SEND_GROUP_BY" == 1 ]]; then
    SEND_PUBLIC "$USE_TELEGRAM" "$USE_DISCORD" "$GAME_STRING"
  fi
  echo "-------------------------------------"
}

main() {
	checkParams "$@"
  printParams
	winner=$(head -n 1 ${TEAM_LIST})
	tail ${TEAM_LIST} -n +2 > ${TEAM_LIST}_tmp
	cat ${TEAM_LIST}_tmp > ${TEAM_LIST}
	counter=0
	while true; do
		counter=$((counter+1))
		newteam=$(head -n 1 ${TEAM_LIST})
		if [ "$newteam" = "" ]; then
			break
		fi
		TIME_STAMP="G$( (tr -dc A-Za-z0-9 </dev/urandom | head -c 5) && echo '')P"
		LOG_DIR=${ROOT_LOG_DIR}/${GROUP_NAME}
		EVENT_DIR=${ROOT_EVENT_DIR}/${GROUP_NAME}
		RUN "mkdir -p $LOG_DIR"
		RUN "mkdir -p $EVENT_DIR"
		RUN "chmod 777 $LOG_DIR -R"
		RUN "chmod 777 $EVENT_DIR -R"
		echo "**********************************************************"
		echo "($newteam)"
		PARAMS="-ts $TIME_STAMP -st ${LEAGUE_TYPE} -gt cup -ld ${LOG_DIR} -ed ${EVENT_DIR} -l ${winner} -r ${newteam} -n ${NETWORK} -t ${TAG}"
		if [[ "$USE_TELEGRAM" == 1 ]]; then
      PARAMS="${PARAMS} -ut "
    fi
    if [[ "$USE_DISCORD" == 1 ]]; then
      PARAMS="${PARAMS} -ud "
    fi
    if [[ "$USE_GDRIVE" == 1 ]]; then
      GOOGLE_DRIVE_PARENT=$(CREATE_DIRECTORY_IN_GDRIVE $GROUP_NAME)
      PARAMS="${PARAMS} -ug -gdp $GOOGLE_DRIVE_PARENT"
    fi
		echo $PARAMS
		./run_game.sh $PARAMS
		echo "**********************************************************"
		tail ${TEAM_LIST} -n +2 > ${TEAM_LIST}_tmp
		cat ${TEAM_LIST}_tmp > ${TEAM_LIST}
		sleep 1
		#use python
		winner=$(python3 winnerfinder.py "${LOG_DIR}/${TIME_STAMP}")
	done
}


main "$@"
exit 0
