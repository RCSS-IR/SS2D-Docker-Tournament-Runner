#!/bin/bash

# ------------- PUBLIC ONES

source ./utils.sh

HERE=`pwd`
SS2D_TYPE=major
GAME_TYPE=league
TEAM_LEFT=
TEAM_RIGHT=
TAG='latest'
NETWORK=
GAME_TIME=$(date -u +%H:%M:%S)
TIME_STAMP="G$( (tr -dc A-Za-z0-9 </dev/urandom | head -c 5) && echo '')P"
LOG_DIR=$(pwd)/log_dir
EVENT_DIR=$(pwd)/event_dir

# ------------- PRIVATE ONES [BUT YOU CAN CHANGE!]
SERVER_IP=
HOST_NAME=rcssserver1
SERVER_PORT=6000

# ------------- PRIVATE ONES [DO NOT CHANGE!]
RUN_IN_SERVER=
CPU_COUNT=$(lscpu | grep "^CPU(s)" | grep -P -o "[0-9]+")
SERVER_CONF=
USE_RESOURCE_LIMIT=0
LEFT_TEAM_RAM_LIMIT=
RIGHT_TEAM_RAM_LIMIT=
LEFT_FIRST_CORE=
LEFT_LAST_CORE=
RIGHT_FIRST_CORE=
RIGHT_LAST_CORE=
LATEST_RIGHT_GOAL=0
LATEST_LEFT_GOAL=0
LATEST_RIGHT_PENALTY_GOAL=0
LATEST_LEFT_PENALTY_GOAL=0
LOSS=""
SERVER_LOG_FILE_NAME=
LEFT_LOG_FILE_NAME=
RIGHT_LOG_FILE_NAME=

#------------------------------------------------------------

printHelp() {
  echo "
     Usage : ./run_game.sh [OPTIONS]
     Options:
        -st, --ss2d-type [starter OR major]             type of competition
        -gt, --game-type [league OR cup OR test]        running game mode
        -ld, --log_directory                            log directory
        -ed, --event_directory                          server and event directory
        -l , --team_left                                left team to run
        -r , --right_team                               right team to run
        -t , --tag                                      image tag=latest
        -n , --network                                  network
        -sp, --server-port                              server port
        -ut, --use-telegram                             will use telegram
        -ud, --use-discord                              will use discord
        -ug, --use-google-drive                         will use google drive
        -ns, --no-send                                  will not send any message
        -gdp, --google-drive-path                       google drive path
    "
}

checkParams() {
  while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    -st | --ss2d-type)
      SS2D_TYPE="$2"
      shift # past argument
      shift # past value
      ;;
    -gt | --game-type)
      GAME_TYPE="$2"
      shift # past argument
      shift # past value
      ;;
    -ld | --log_directory)
      LOG_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    -ed | --event_directory)
      EVENT_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    -l | --team_left)
      TEAM_LEFT="$2"
      shift # past argument
      shift # past value
      ;;
    -r | --right_team)
      TEAM_RIGHT="$2"
      shift # past argument
      shift # past value
      ;;
    -t | --tag)
      TAG="$2"
      shift # past argument
      shift # past value
      ;;
    -n | --network)
      NETWORK="$2"
      shift # past argument
      shift # past value
      ;;
    -sp | --server-port)
      SERVER_PORT="$2"
      shift # past argument
      shift # past value
      ;;
    -ts | --timestamp)
      TIME_STAMP="$2"
      shift # past argument
      shift # past value
      ;;
    -gdp | --google-drive-path)
      GOOGLE_DRIVE_PARENT="$2"
      shift
      shift
      ;;
    -ut | --use-telegram)
      USE_TELEGRAM=1
      shift
      ;;
    -ud | --use-discord)
      USE_DISCORD=1
      shift
      ;;
    -ug | --use-google-drive)
      USE_GDRIVE=1
      shift
      ;;
    -ns | --no-send)
      UPLOAD_LOG_BY=0
      UPLOAD_OUT_BY=0
      SEND_ALERT_BY=0
      SEND_PUBLIC_BY=0
      SEND_PRIVATE_BY=0
      shift # past argument
      ;;
    *) # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift              # past argument
      ;;
    esac
  done

  if [[ "$(echo "$LOG_DIR" | cut -c 1)" != '/' ]]
  then
    LOG_DIR=${HERE}/${LOG_DIR}
  fi
  if [[ "$(echo "$EVENT_DIR" | cut -c 1)" != '/' ]]
  then
    EVENT_DIR=${HERE}/${EVENT_DIR}
  fi
  if [[ $LOG_DIR = */ ]]
  then
    LOG_DIR=${LOG_DIR::-1}
  fi
  if [[ $EVENT_DIR = */ ]]
  then
    EVENT_DIR=${EVENT_DIR::-1}
  fi
  LOG_DIR=${LOG_DIR}/${TIME_STAMP}
  EVENT_DIR=${EVENT_DIR}/${TIME_STAMP}
  success=1
  [ ! -z "$SS2D_TYPE" ] || success=0
  [ ! -z "$GAME_TYPE" ] || success=0
  [ ! -z "$LOG_DIR" ] || success=0
  [ ! -z "$EVENT_DIR" ] || success=0
  [ ! -z "$TEAM_LEFT" ] || success=0
  [ ! -z "$TEAM_RIGHT" ] || success=0
  [ ! -z "$NETWORK" ] || success=0
  [ ! -z "$SERVER_PORT" ] || success=0

  if ((!success)); then
    printHelp
    exit 1
  fi
  RUN "mkdir -p ${LOG_DIR}"
  RUN "mkdir -p ${EVENT_DIR}"
}

checkServerConf() {
  SERVER_CON=""
  if [ $SS2D_TYPE = "starter" ]; then
    if [ $GAME_TYPE = "league" ]; then
      SERVER_CONF="server_starter_league.conf"
    elif [ $GAME_TYPE = "cup" ]; then
      SERVER_CONF="server_starter_cup.conf"
    elif [ $GAME_TYPE = "check" ]; then
      SERVER_CONF="server_starter_check.conf"  
    else
      SERVER_CONF="server_starter_test.conf"
    fi
  else
    if [ $GAME_TYPE = "league" ]; then
      SERVER_CONF="server_league.conf"
    elif [ $GAME_TYPE = "cup" ]; then
      SERVER_CONF="server_cup.conf"
    elif [ $GAME_TYPE = "check" ]; then
      SERVER_CONF="server_check.conf"
    else
      SERVER_CONF="server_test.conf"
    fi
  fi
}

configNetwork() {
  source configs/$NETWORK
  if (($USE_RESOURCE_LIMIT)); then
    echo "use resource limit"
  else
    LEFT_FIRST_CORE=
    LEFT_LAST_CORE=
    RIGHT_FIRST_CORE=
    RIGHT_LAST_CORE=
    LEFT_TEAM_RAM_LIMIT=
    RIGHT_TEAM_RAM_LIMIT=
  fi
}

printParams() {
  echo "-------------------------------------"
  echo "            ENVIRONMENTS"
  echo "-------------------------------------"
  echo "SS2D_TYPE     : " ${SS2D_TYPE}
  echo "GAME_TYPE     : " ${GAME_TYPE}
  echo "LOG_DIR       : " ${LOG_DIR}
  echo "EVENT_DIR     : " ${EVENT_DIR}
  echo "TEAM_LEFT     : " ${TEAM_LEFT}
  echo "TEAM_RIGHT    : " ${TEAM_RIGHT}
  echo "NETWORK       : " ${NETWORK}
  echo "TIME_STAMP    : " ${TIME_STAMP}
  echo "-------------------------------------"
  echo "SERVER_CONF   : " ${SERVER_CONF}
  echo "CPU_COUNT     : " ${CPU_COUNT}
  echo "RUN_IN_SERVER : " ${RUN_IN_SERVER}
  echo "USE_RESOURCE_LIMIT : " ${USE_RESOURCE_LIMIT}
  echo "LEFT_CORES    : " "${LEFT_FIRST_CORE} to ${LEFT_LAST_CORE}"
  echo "RIGHT_CORES   : " "${RIGHT_FIRST_CORE} to ${RIGHT_LAST_CORE}"
  echo "LEFT_TEAM_RAM_LIMIT  :" "${LEFT_TEAM_RAM_LIMIT}"
  echo "RIGHT_TEAM_RAM_LIMIT  :" "${RIGHT_TEAM_RAM_LIMIT}"
  echo "-------------------------------------"
}

killLastServer() {
  echo "--- kill last server & players"
  RUN "docker kill ${NETWORK}_server" -nc
  RUN "docker rm ${NETWORK}_server" -nc
  for num in {1..12}; do
    RUN "docker kill ${NETWORK}_team_${TEAM_LEFT}_${num}" -nc -nl
    RUN "docker kill ${NETWORK}_team_${TEAM_RIGHT}_${num}" -nc -nl
    RUN "docker rm ${NETWORK}_team_${TEAM_LEFT}_${num}" -nc -nl
    RUN "docker rm ${NETWORK}_team_${TEAM_RIGHT}_${num}" -nc -nl
  done
  echo "--- last server & players killed"
}

runServer() {
  echo "--- running rcssserver"
  opt=""
  opt="${opt} --network $NETWORK --ip ${SERVER_IP}"
  opt="${opt} --hostname ${HOST_NAME} -p ${SERVER_PORT}:6000/udp"
  opt="${opt} -v ${LOG_DIR}:/home/ss2dtr/log --name ${NETWORK}_server"
  opt="${opt} -e config_file=${SERVER_CONF} -e DATE_FORMAT=\"${TIME_STAMP}_${NETWORK}_\""
  opt="${opt} rcssserver:latest"
  
  SERVER_LOG_FILE_NAME=${TIME_STAMP}_${NETWORK}.server.log
  RUN "docker run ${opt}" -bg -co "${EVENT_DIR}/${SERVER_LOG_FILE_NAME}"
  sleep 1
  echo "--- end running rcssserver"
}

waitForServer() {
  checkServer=$(docker logs ${NETWORK}_server 2>/dev/null)
  res=$?
  handleFailed ${res} "+ NO SUCH CONTAINER" ""

  while ! echo "${checkServer}" | grep -q "random seed as Hetero Player Seed"; do
    sleep 1
    checkServer=$(docker logs ${NETWORK}_server 2>/dev/null)
    res=$?
    handleFailed ${res} "+ NO SUCH CONTAINER" "++ wait for server ..."

    if [ $res -ne 0 ]; then
      echo "++ try running server again"
      runServer
    fi
  done
  sleep 3
}

RUN_LEFT_TEAM() {
  for num in {1..12}; do
    opt=""
    opt="${opt} --name ${NETWORK}_team_${TEAM_LEFT}_${num}"
    opt="${opt} --network ${NETWORK}"

    if (($USE_RESOURCE_LIMIT)); then
      opt="${opt} --memory ${LEFT_TEAM_RAM_LIMIT}"
      opt="${opt} --cpuset-cpus ${LEFT_FIRST_CORE}-${LEFT_LAST_CORE}"
    fi

    opt="${opt} -e num=${num} -e ip=${SERVER_IP}"
    opt="${opt} ${TEAM_LEFT}:${TAG}"

    LEFT_LOG_FILE_NAME="${TIME_STAMP}_${NETWORK}.l_${TEAM_LEFT}_player"

    RUN "docker run ${opt}" -bg -nc -co "${EVENT_DIR}/${LEFT_LOG_FILE_NAME}${num}.log"
    sleep 2
  done
}

RUN_RIGHT_TEAM() {
  for num in {1..12}; do
    opt=""
    opt="${opt} --name ${NETWORK}_team_${TEAM_RIGHT}_${num}"
    opt="${opt} --network ${NETWORK}"

    if (($USE_RESOURCE_LIMIT)); then
      opt="${opt} --memory ${RIGHT_TEAM_RAM_LIMIT}"
      opt="${opt} --cpuset-cpus ${RIGHT_FIRST_CORE}-${RIGHT_LAST_CORE}"
    fi

    opt="${opt} -e num=${num} -e ip=${SERVER_IP}"
    opt="${opt} ${TEAM_RIGHT}:${TAG}"

    RIGHT_LOG_FILE_NAME="${TIME_STAMP}_${NETWORK}.r_${TEAM_RIGHT}_player"

    RUN "docker run ${opt}" -bg -nc -co "${EVENT_DIR}/${RIGHT_LOG_FILE_NAME}${num}.log"
    sleep 2
  done
}

copyLogs() {
  docker logs ${NETWORK}_server >${EVENT_DIR}/${TIME_STAMP}_${TEAM_LEFT}_${TEAM_RIGHT}_server.out
  docker kill ${NETWORK}_server
  docker rm ${NETWORK}_server
  for num in {1..12}; do
    docker logs ${NETWORK}_team_${TEAM_LEFT}_${num} >${EVENT_DIR}/${TIME_STAMP}_${TEAM_LEFT}_${TEAM_RIGHT}_${TEAM_LEFT}_${num}.out
    docker logs ${NETWORK}_team_${TEAM_RIGHT}_${num} >${EVENT_DIR}/${TIME_STAMP}_${TEAM_LEFT}_${TEAM_RIGHT}_${TEAM_RIGHT}_${num}.out
  done

  for num in {1..12}; do
    docker kill ${NETWORK}_team_${TEAM_LEFT}_${num}
    docker kill ${NETWORK}_team_${TEAM_RIGHT}_${num}
    docker rm ${NETWORK}_team_${TEAM_LEFT}_${num}
    docker rm ${NETWORK}_team_${TEAM_RIGHT}_${num}
  done
}

compresLogsAndOutputs() {
  # RUN "rm ${LOG_DIR}/~/ -r"
  FILENAME=$(ls ${LOG_DIR} | grep -E "${TIME_STAMP}_${NETWORK}*" | grep -E "*.rcg" | head -1 | rev | cut -c 5- | rev)

  # TODO this one needs update
  current_dir=`pwd`
  cd ${LOG_DIR}
  RUN "tar -czvf ${FILENAME}_log.tar.gz ${TIME_STAMP}_${NETWORK}*.rc?" -nc
  cd ${EVENT_DIR}
  RUN "tar -czvf ${FILENAME}_out.tar.gz ${TIME_STAMP}_${NETWORK}*.log" -nc
  cd $current_dir
}

sendLogsTo() {
  if (($UPLOAD_LOG_BY)); then
    for file in $(ls $LOG_DIR | grep -e ${TIME_STAMP}* | grep "log.tar.gz"); do
      echo $LOG_DIR/${file}
      # SEND_FILE_PUBLIC $USE_TELEGRAM $USE_GDRIVE "${LOG_DIR}/${file}" $GOOGLE_DRIVE_PARENT "📎#${TEAM_LEFT}-${LATEST_LEFT_GOAL}-${LATEST_RIGHT_GOAL}-#${TEAM_RIGHT}"
      SEND_FILE_PUBLIC $USE_TELEGRAM $USE_GDRIVE "${EVENT_DIR}/${file}" $GOOGLE_DRIVE_PARENT "📎#${TEAM_LEFT}-${LATEST_LEFT_GOAL}-${LATEST_RIGHT_GOAL}-#${TEAM_RIGHT}"
    done
  fi
  if (($UPLOAD_OUT_BY)); then
    for file in $(ls $EVENT_DIR | grep -e ${TIME_STAMP}* | grep "out.tar.gz"); do
      SEND_FILE_PUBLIC $USE_TELEGRAM $USE_GDRIVE "${EVENT_DIR}/${file}" $GOOGLE_DRIVE_PARENT "📎#${TEAM_LEFT}-${LATEST_LEFT_GOAL}-${LATEST_RIGHT_GOAL}-#${TEAM_RIGHT}"
    done
  fi
}

checkRCGForGameChange() {
  LEFT_GOAL=$(grep -o " goal_l" "${LOG_DIR}/incomplete.rcg" | wc -l)
  RIGHT_GOAL=$(grep -o " goal_r" "${LOG_DIR}/incomplete.rcg" | wc -l)
  RIGHT_PENALTY_GOAL=$(grep -o " penalty_score_r" "${LOG_DIR}/incomplete.rcg" | wc -l)
  LEFT_PENALTY_GOAL=$(grep -o " penalty_score_l" "${LOG_DIR}/incomplete.rcg" | wc -l)

  if (($SEND_GAME_CHANGES)); then
    if [ $LEFT_GOAL -ne $LATEST_LEFT_GOAL ] && [ $LEFT_GOAL -ne "0" ]; then
      LATEST_LEFT_GOAL=$LEFT_GOAL
      LATEST_RIGHT_GOAL=$RIGHT_GOAL
      SEND_PUBLIC $USE_TELEGRAM $USE_DISCORD "🟡 Change In Game ! ${TEAM_LEFT} ${LEFT_GOAL} - ${RIGHT_GOAL} ${TEAM_RIGHT}  #️⃣ ${TIME_STAMP} ⏱ $(date -u +%H:%M:%S) (UTC)"
    fi
    if [ $LEFT_PENALTY_GOAL -ne $LATEST_LEFT_PENALTY_GOAL ] && [ $LEFT_PENALTY_GOAL -ne "0" ]; then
      LATEST_LEFT_PENALTY_GOAL=$LEFT_PENALTY_GOAL
      LATEST_RIGHT_PENALTY_GOAL=$RIGHT_PENALTY_GOAL
      SEND_PUBLIC $USE_TELEGRAM $USE_DISCORD "🟡 Change In Game PENALTY! ${TEAM_LEFT} ${LEFT_PENALTY_GOAL} - ${RIGHT_PENALTY_GOAL} ${TEAM_RIGHT} #️⃣ ${TIME_STAMP} ⏱ $(date -u +%H:%M:%S) (UTC)"
    fi
    if [ $RIGHT_PENALTY_GOAL -ne $LATEST_RIGHT_PENALTY_GOAL ] && [ $RIGHT_PENALTY_GOAL -ne "0" ]; then
      LATEST_LEFT_PENALTY_GOAL=$LEFT_PENALTY_GOAL
      LATEST_RIGHT_PENALTY_GOAL=$RIGHT_PENALTY_GOAL
      SEND_PUBLIC $USE_TELEGRAM $USE_DISCORD "🟡 Change In Game PENALTY! ${TEAM_LEFT} ${LEFT_PENALTY_GOAL} - ${RIGHT_PENALTY_GOAL} ${TEAM_RIGHT} #️⃣ ${TIME_STAMP} ⏱ $(date -u +%H:%M:%S) (UTC)"
    fi
    if [ $RIGHT_GOAL -ne $LATEST_RIGHT_GOAL ] && [ $RIGHT_GOAL -ne "0" ]; then
      LATEST_LEFT_GOAL=$LEFT_GOAL
      LATEST_RIGHT_GOAL=$RIGHT_GOAL
      SEND_PUBLIC $USE_TELEGRAM $USE_DISCORD "🟡 Change In Game ! ${TEAM_LEFT} ${LEFT_GOAL} - ${RIGHT_GOAL} ${TEAM_RIGHT}  #️⃣ ${TIME_STAMP} ⏱ $(date -u +%H:%M:%S) (UTC)"
    fi
  fi
}

checkLoss() {
  # teams=$(echo $1 | tr "-" "\n" | tr "_" "\n")
  teams=$1
  RTeam=$(echo "$teams" | cut -d'_' -f2)
  LTeam=$(echo $(echo "$(cut -d'_' -f4 <<<$teams)" | tr "_" "\n") | sed -e 's/ .*$//')
  # echo $RTeam,$LTeam
  error=0
  for pnum in {1..11}; do
    R=$(cat $teams | grep -v "^0" | grep -v "[0-9]*,[1-9][0-9]*" | grep -v "bye" | grep "${RTeam}_${pnum}:" | wc -l)
    L=$(cat $teams | grep -v "^0" | grep -v "[0-9]*,[1-9][0-9]*" | grep -v "bye" | grep "${LTeam}_${pnum}:" | wc -l)
    echo "${RTeam}_${pnum}:${R} ${LTeam}_${pnum}:${L}"
    if [[ $R != 5999 ]]; then
      error=1
      LOSS+="${RTeam}_${pnum}:${R} "
    fi
    if [[ $L != 5999 ]]; then
      error=1
      LOSS+="${LTeam}_${pnum}:${L} "
    fi
  done
  if [[ $LOSS != "" ]]; then echo $LOSS; fi

  if (($error)); then
    SEND_PRIVATE "LOST #${TIME_STAMP} ${TEAM_LEFT} ${TEAM_RIGHT}
-->  ${LOSS}"
  fi
}

sendStartGameTo() {
  if [ $SEND_PUBLIC_BY -eq 1 ]; then
    SEND_PUBLIC $USE_TELEGRAM $USE_DISCORD "🟢 Game Start: ${TEAM_LEFT} vs ${TEAM_RIGHT}. #️⃣ ${TIME_STAMP} ⏱ $(date -u +%H:%M:%S) (UTC)"
  fi
}

sendEndGameTo() {
  result=$(python3 winnerfinder.py "${LOG_DIR}" "result")
  if (($SEND_ALERT_BY)); then
    SEND_ALERT "
    ▪️ #${TIME_STAMP}

    ▫️ <b>#${TEAM_LEFT}</b> ${result} <b>#${TEAM_RIGHT}</b>
    " &
  fi

  if (($SEND_PUBLIC_BY)); then
    SEND_PUBLIC $USE_TELEGRAM $USE_DISCORD "🔵 Game End: ${TEAM_LEFT} ${result} ${TEAM_RIGHT}. #️⃣ ${TIME_STAMP} ⏱ $(date -u +%H:%M:%S) (UTC)"
  fi

  if (($SEND_PRIVATE_BY)); then
    SEND_PRIVATE "
    ▪️<i> Game End</i>

    ▫️ <b>#${TEAM_LEFT}</b> ${result} <b>#${TEAM_RIGHT}</b>

    #️⃣ #${TIME_STAMP}

    ⏱ TIME: ${GAME_TIME}

    <pre>
    SS2D_TYPE      : ${SS2D_TYPE}
    GAME_TYPE      : ${GAME_TYPE}
    LOG_DIR        : ${LOG_DIR}
    EVENT_DIR      : ${EVENT_DIR}
    TEAM_LEFT      : #${TEAM_LEFT}
    TEAM_RIGHT     : #${TEAM_RIGHT}
    NETWORK        : ${NETWORK}
    TIME_STAMP     : #${TIME_STAMP}
    ----------
    SERVER_CONF    : ${SERVER_CONF}
    CPU_COUNT      : ${CPU_COUNT}
    RUN_IN_SERVER  : ${RUN_IN_SERVER}
    USE_RESOURCE_LIMIT  : ${USE_RESOURCE_LIMIT}
    LEFT_CORES     : ${LEFT_FIRST_CORE} to ${LEFT_LAST_CORE}
    RIGHT_CORES    : ${RIGHT_FIRST_CORE} to ${RIGHT_LAST_CORE}
    LEFT_TEAM_RAM_LIMIT  : ${LEFT_TEAM_RAM_LIMIT}
    RIGHT_TEAM_RAM_LIMIT  : ${RIGHT_TEAM_RAM_LIMIT}
    ----------
    </pre>
    " &
  fi
}

main() {
  checkParams "$@"
  #  clear
  checkServerConf
  configNetwork
  printParams
  # ----- RUN
  killLastServer
  runServer
  waitForServer

  RUN_LEFT_TEAM
  sleep 1
  RUN_RIGHT_TEAM
  
  sendStartGameTo
  while [ "$(docker inspect -f {{.State.Running}} ${NETWORK}_server)" = "true" ]; do
    checkRCGForGameChange
    sleep 1
  done

  #  checkLoss "$(ls $LOG_DIR | grep -e "${TIME_STAMP}" | grep -e ".rcl$")}"

  compresLogsAndOutputs
  sendLogsTo &
  sendEndGameTo

  RUN "./kill_server.sh -n ${NETWORK}"

  echo "+ game end. exit... "
}

main "$@"

exit 0