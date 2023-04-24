#!/bin/bash

# ------------- PUBLIC ONES
source ./utils.sh

SS2D_TYPE="major"
GAME_TYPE="test"
# esme serveri ke khaliye
TEST_SERVER_NAME=

LOG_DIR=
LOG_BASE_DIR=
TEAM_RIGHT=agent
TEAM_LEFT_BINARY_LOCATION=
# Jaii ke file haye 01 server hastan
SERVER_DIRECTORY=
EXIT_COMMAND=
EVENT_DIR=
ARCHIVE_FILE_ADDRESS=
TEST_TEAM_NAME="t$( (tr -dc a-z0-9 </dev/urandom | head -c 6) && echo '')p"
TIME_STAMP=$TEST_TEAM_NAME

INIT_TEST_NETWORK=false
NUMBER_OF_TEST_SERVERS=2
ORIGINAL_TEAM_NAME=

prg=$0
if [ ! -e "$prg" ]; then
  case $prg in
  */*) exit 1 ;;
  *) prg=$(command -v -- "$prg") || exit ;;
  esac
fi
dir=$(
  cd -P -- "$(dirname -- "$prg")" && pwd -P
) || exit
prg=$dir/$(basename -- "$prg") || exit

#------------------------------------------------------------
createTestNetwork() {
  RUN "rm -r $SERVER_DIRECTORY" -nc
  RUN "mkdir -p $SERVER_DIRECTORY" -nc
  for ((i = 1; i <= $NUMBER_OF_TEST_SERVERS; i++)); do
    _SERVER_NAME="test$i"
    RUN "docker network rm $_SERVER_NAME" -nc
    RUN "docker network create --internal	--subnet=172.$((90 + $i)).0.0/16 $_SERVER_NAME"
    RUN "echo \"1\"> $SERVER_DIRECTORY/$_SERVER_NAME" -po
  done
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
    -r | --right_team)
      TEAM_RIGHT="$2"
      shift # past argument
      shift # past value
      ;;
    -sd | --server-directory)
      SERVER_DIRECTORY="$2"
      shift # past argument
      shift # past value
      ;;
    -ltbl | --left-team-binary-location)
      TEAM_LEFT_BINARY_LOCATION="$2"
      shift # past argument
      shift # past value
      ;;
    -otn | --original-team-name)
      ORIGINAL_TEAM_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    -in | --init-test-networksm)
      INIT_TEST_NETWORK=true
      shift # past argument
      ;;
    *)                   # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift              # past argument
      ;;
    esac
  done

  success=1
  if ! $INIT_TEST_NETWORK; then
    if [ -z "$SS2D_TYPE" ]; then
      success=0
      echo "SS2D_TYPE is missing"
    fi

    if [ -z "$GAME_TYPE" ]; then
      success=0
      echo "GAME_TYPE is missing"
    fi

    if [ -z "$LOG_DIR" ]; then
      success=0
      echo "LOG_DIR is missing"
    fi

    if [ -z "$TEAM_RIGHT" ]; then
      success=0
      echo "TEAM_RIGHT is missing"
    fi

    if [ -z "$SERVER_DIRECTORY" ]; then
      success=0
      echo "SERVER_DIRECTORY is missing"
    fi

    if [ -z "$TEAM_LEFT_BINARY_LOCATION" ]; then
      success=0
      echo "TEAM_LEFT_BINARY_LOCATION is missing"
    fi

    if [ -z "$ORIGINAL_TEAM_NAME" ]; then
      success=0
      echo "ORIGINAL_TEAM_NAME is missing"
    fi
  fi

  if [[ $INIT_TEST_NETWORK && -z "$SERVER_DIRECTORY" ]]; then
    echo "init test network should be use with server directory (-sd) option"
    exit 1
  fi

  if $INIT_TEST_NETWORK && [[ ! -z "$SERVER_DIRECTORY" ]]; then
    createTestNetwork
    exit 0
  fi

  if ((!success)); then
    printHelp
    exit 1
  fi

}

printHelp() {
  echo "
     Usage : ./run_game.sh [OPTIONS]
     Options:
        -st, --ss2d-type [starter OR major]             type of competition
        -ld, --log_directory                            log directory
        -sd, --server-directory                         network/server directory for test servers
        -ltbl, --left-team-binary-location              binary location of test team
        -in, --init-test-networks                       init test networks
    "
}

createLogDirectory() {
  LOG_BASE_DIR=$LOG_DIR
  RUN "rm -r \"$LOG_DIR\"" -nc
  RUN "mkdir -p \"$LOG_DIR\"" -nc
}

buildTestBinary() {
  echo "--- start build ${TEAM_NAME}"
  RUN "mkdir $TEAM_LEFT_BINARY_LOCATION/../bin" -po
  RUN "mv $TEAM_LEFT_BINARY_LOCATION/* $TEAM_LEFT_BINARY_LOCATION/../bin/" -po
  RUN "mv $TEAM_LEFT_BINARY_LOCATION/../bin $TEAM_LEFT_BINARY_LOCATION/" -po
  RUN "chmod 777 $TEAM_LEFT_BINARY_LOCATION/bin/* -R" -po
  RUN "cp teams.Dockerfile $TEAM_LEFT_BINARY_LOCATION/Dockerfile" -po
  OLD_PWD=$PWD
  RUN "cd $TEAM_LEFT_BINARY_LOCATION && docker build -t $TEST_TEAM_NAME:latest ." -ef
  cd $OLD_PWD
  # RUN "mkdir -p $dir/bins/$ORIGINAL_TEAM_NAME" -nc
  # RUN "cp -r $TEAM_LEFT_BINARY_LOCATION/* $dir/bins/$ORIGINAL_TEAM_NAME/"
  echo "--- end build ${TEAM_NAME}"
}

findEmptyServer() {
  if [ ! -d "$SERVER_DIRECTORY" ]; then
    RUN "mkdir -p ${SERVER_DIRECTORY}"
    RUN "echo 1 > ${SERVER_DIRECTORY}/test1" -po
    RUN "echo 1 > ${SERVER_DIRECTORY}/test2" -po
    RUN "echo 1 > ${SERVER_DIRECTORY}/test3" -po
    RUN "echo 1 > ${SERVER_DIRECTORY}/test4" -po
    # Take action if $DIR exists. #
    echo "Installing config files in ${DIR}..."
  fi
  for server in $SERVER_DIRECTORY/*; do
    S=$(<$server)
    if [[ "$S" == "1" ]]; then
      TEST_SERVER_NAME=$(echo "$server" | tr '/' '\n' | tail -n1)
      RUN "echo \"0\"> $server" -po
      NETWORK=$TEST_SERVER_NAME
      break
    fi
  done

  if [ -z "$TEST_SERVER_NAME" ]; then
    echo "** no empty server!"
    exit 2
  fi
  echo "${NETWORK}" > ${TEAM_LEFT_BINARY_LOCATION}/../../used_server
}

runTest() {
  echo "--- running test"
  printParams
  RUN "./run_game.sh -st ${SS2D_TYPE} -gt ${GAME_TYPE} -ld ${LOG_DIR} -ed ${LOG_DIR} -l ${TEST_TEAM_NAME} -r ${TEAM_RIGHT} -n ${TEST_SERVER_NAME} -ns" -po
  echo "--- end running test"
}

printParams() {
  echo "-------------------------------------"
  echo "            ENVIRONMENTS"
  echo "-------------------------------------"
  echo "SS2D_TYPE       : " ${SS2D_TYPE}
  echo "GAME_TYPE       : " ${GAME_TYPE}
  echo "LOG_DIR         : " ${LOG_DIR}
  echo "EVENT_DIR       : " ${EVENT_DIR}
  echo "TEAM_RIGHT      : " ${TEAM_RIGHT}
  echo "NETWORK         : " ${NETWORK}
  echo "TIME_STAMP      : " ${TIME_STAMP}
  echo "SERVER_DIRECTORY: " ${SERVER_DIRECTORY}
  echo "-------------------------------------"
}


# mire to foldere TEST_SERVER_FOLDER donbale file haye serveraye 0 migarde
# age peyda kone esmesho mirize to TEST_SERVER_NAME va 1 mikone

# Q QUEUE mikhaim bara do ta server faghat -> telegram goftam behet

emptyUsedTestServer() {
  RUN "echo \"1\"> $SERVER_DIRECTORY/$TEST_SERVER_NAME" -po
  RUN "rm ${TEAM_LEFT_BINARY_LOCATION}/../../used_server" -po
}

runExitCommand() {
  if [ ! -z "$EXIT_COMMAND" ]; then
    EC="${EXIT_COMMAND/LOG_DIR/"$LOG_DIR"}"
    EC="${EC/EVENT_DIR/"$EVENT_DIR"}"
    RUN "$EC" -nc -po
  fi
}

removeTestTeamDocker() {
  RUN "docker rmi --force $TEST_TEAM_NAME"
}

main() {
  checkParams "$@"
  #  clear
  createLogDirectory
  buildTestBinary
  findEmptyServer
  runTest
  emptyUsedTestServer
  removeTestTeamDocker

  echo "+ game end. exit... "
}

main "$@"
exit 0
