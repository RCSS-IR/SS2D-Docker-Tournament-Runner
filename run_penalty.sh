#!/bin/bash

source ./utils.sh

here=$(pwd)
if [ $# -eq 0 ]; then
  echo ./run_playoff.sh network team_list game_profile log_dir event_dir
  exit
fi
network=$1
team_list=$2
log_dir=${here}/logs
event_dir=${here}/events
game_profile=${3}
echo here
if [ $# -gt 3 ]; then
  echo ./run_playoff.sh team_list log_dir event_dir
  log_dir=$4
  event_dir=$5
fi

>${network}.last
echo $(cat ${team_list})
team1=$(head -n 1 ${team_list})
tail ${team_list} -n+2 >${team_list}_tmp
cat ${team_list}_tmp >${team_list}

LOG_DIR=${log_dir}/play_off/${network}
EVENT_DIR=${event_dir}/play_off/${network}
mkdir -p $LOG_DIR
mkdir -p $EVENT_DIR
chmod 777 $LOG_DIR -R
chmod 777 $EVENT_DIR -R

while true; do
  team2=$(head -n 1 ${team_list})
  if [ "$team2" = "" ]; then
    break
  fi
  echo **********************************************************
  echo "($line)"
  echo ./run_game.sh starter/major league/cup/test log_dir event_dir left_team right_team
  #       ./run_game.sh -st ${game_conf[1]} -gt ${game_conf[2]} -ld ${LOG_DIR} -ed ${EVENT_DIR} -l ${game_conf[3]} -r ${game_conf[4]} -n ${network} &> ${EVENT_DIR}/$(date +%s)_runner.out
  ./run_game.sh -gt cup -st ${game_profile} -ld ${LOG_DIR} -ed ${EVENT_DIR} -l ${team1} -r ${team2} -n ${network}
  tail ${team_list} -n +2 >${team_list}_tmp
  cat ${team_list}_tmp >${team_list}
  team1=$(if [ $(cut -d '|' -f3 ${network}.last) -gt $(cut -d '|' -f5 ${network}.last) ]; then $(echo cut -d '|' -f2 ${network}.last); else $(echo cut -d '|' -f4 ${network}.last); fi)
  sleep 1
done
