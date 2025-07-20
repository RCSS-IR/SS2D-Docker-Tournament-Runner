#!/bin/bash
source ./utils.sh

HERE=`pwd`
NETWORK=
TEAM_LIST=
ROOT_LOG_DIR=${HERE}/logs
ROOT_EVENT_DIR=${HERE}/events
USE_TELEGRAM=0
GROUP_NAME=
LEAGUE_TYPE=
TAG='latest'
TEST_MODE=1

# ./test_stepladder.sh -n server1 -tl games/step -ld $(pwd)/log -ed $(pwd)/log -st major -gn TEST

printHelp() {
  echo "
     Usage : ./test_stepladder.sh [OPTIONS]
     Options:
        -tl, --team-list [team list path]               list of teams(file)
        -ld, --log_directory                            log directory
        -ed, --event_directory                          server and event directory
        -n , --network                                  network
        -gn , --group-name                              group name
        -st, --ss2d-type [starter OR major]             type of competition
        -t,  --tag                                      image tag
        
     STEPLADDER FORMAT:
     - First team in list starts as Challenger (Bottom position)
     - Challenger challenges each subsequent team
     - If Challenger wins, they go up to the next position
     - If current Defender wins, they stay at the top and became the new Challenger
     
     This is a TEST VERSION that simulates games without running them.
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
  echo "============================================="
  echo "         STEPLADDER TEST MODE"
  echo "============================================="
  echo "TEAM_LIST     : " ${TEAM_LIST}
  echo "LOG_DIR       : " ${ROOT_LOG_DIR}
  echo "EVENT_DIR     : " ${ROOT_EVENT_DIR}
  echo "NETWORK       : " ${NETWORK}
  echo "LEAGUE_TYPE   : " ${LEAGUE_TYPE}
  echo "GROUP_NAME    : " ${GROUP_NAME}
  echo "============================================="
  echo "           LIST OF TEAMS"
  echo "============================================="
  while read -r line
  do
    echo "⚽ $line"
  done < ${TEAM_LIST}
  echo "============================================="
  echo ""
}

# Simulate a game result - randomly pick winner or use team strength
simulate_game() {
  local team1="$1"
  local team2="$2"
  local timestamp="$3"
  
  # Simple simulation: random winner with slight bias towards first team (current champion)
  local random_num=$((RANDOM % 100))
  
  # 60% chance for team1 (leader advantage), 40% for team2 (challenger)
  if [ $random_num -lt 60 ]; then
    local winner="$team1"
    local score1=$((RANDOM % 3 + 1))
    local score2=$((RANDOM % score1))
  else
    local winner="$team2"
    local score2=$((RANDOM % 3 + 1))
    local score1=$((RANDOM % score2))
  fi
  
  echo "🏆 STEPLADDER MATCH: $team1 (Leader) vs $team2 (Challenger)"
  echo "📊 RESULT: $team1 $score1 - $score2 $team2"
  echo "🥇 WINNER: $winner"
  echo ""
  
  # Return the winner by writing to a temp file
  echo "$winner" > /tmp/game_winner
}

main() {
  checkParams "$@"
  printParams
  
  # Copy team list to avoid modifying original
  cp ${TEAM_LIST} ${TEAM_LIST}_test_copy
  TEAM_LIST_WORK=${TEAM_LIST}_test_copy
  
  winner=$(head -n 1 ${TEAM_LIST_WORK})
  tail ${TEAM_LIST_WORK} -n +2 > ${TEAM_LIST_WORK}_tmp
  cat ${TEAM_LIST_WORK}_tmp > ${TEAM_LIST_WORK}
  
  echo "🏅 STARTING Challenger: $winner"
  echo ""
  
  counter=0
  round=1
  
  while true; do
    counter=$((counter+1))
    newteam=$(head -n 1 ${TEAM_LIST_WORK})
    if [ "$newteam" = "" ]; then
      break
    fi
    
    echo "📍 ROUND $round"
    echo "=================================="
    
    TIME_STAMP="G$( (tr -dc A-Za-z0-9 </dev/urandom | head -c 5) && echo '')P"
    
    # Simulate the game
    simulate_game "$winner" "$newteam" "$TIME_STAMP"
    game_winner=$(cat /tmp/game_winner)
    
    # Update winner
    winner="$game_winner"
    
    # Remove the challenger from the list
    tail ${TEAM_LIST_WORK} -n +2 > ${TEAM_LIST_WORK}_tmp
    cat ${TEAM_LIST_WORK}_tmp > ${TEAM_LIST_WORK}
    
    echo "� CURRENT Challenger/Winner: $winner"
    echo ""
    
    round=$((round+1))
    sleep 1  # Small delay for readability
  done
  
  echo "🎉 FINAL STEPLADDER LEADER: $winner 🎉"
  echo "👑 Total rounds played: $((round-1))"
  
  # Cleanup
  rm -f ${TEAM_LIST_WORK} ${TEAM_LIST_WORK}_tmp /tmp/game_winner
}

main "$@"
exit 0
