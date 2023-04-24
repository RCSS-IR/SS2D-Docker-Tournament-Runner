#!/usr/bin/env bash
source ./.env

_NO_CHECK=0
_BACKGROUND=0
_PRINT_OUTPUT=0
_LOGGING=1
_EXIT_ON_FAIL=0
_COMMAND_DEBUG_MODE=0

_COMMAND_OUTPUT=0
_COMMAND_OUTPUT_FILE=/dev/null

_DISABLE_NOTIFICATION=0

handleFailed() {
  if [ $1 -eq 0 ]; then
    echo $3
  else
    RED='\033[0;31m'
    NC='\033[0m'
    echo -e "${RED}FAILED -${2} ${NC}\n"
  fi
}

checkFail() {
  EXIT_CODE=$1
  COMMAND=$2
  EXIT_ON_FAIL=$3
  #  echo $EXIT_CODE
  if (($EXIT_CODE != 0)); then
    RED='\033[0;31m'
    NC='\033[0m'
    echo -e "${RED}FAILED - ${COMMAND} ${NC}\n"

    if (($EXIT_ON_FAIL)); then
      exit
    fi
  fi
}


RUN() {
  # example :
  # RUN "echo 'hi'" -nc
  # -nc : no check for error
  # -bg : run in background
  # -po : print output of command
  # -nl : no logging
  # -ef : exit on fail
  # -co file_path : command output file
  # -sp file_path : save pid to file

  COMMAND=$1
  shift

  NO_CHECK=$_NO_CHECK
  BACKGROUND=$_BACKGROUND
  PRINT_OUTPUT=$_PRINT_OUTPUT
  LOGGING=$_LOGGING
  COMMAND_OUTPUT=$_COMMAND_OUTPUT
  COMMAND_OUTPUT_FILE=$_COMMAND_OUTPUT_FILE

  SAVE_PID=$_SAVE_PID
  SAVE_PID_OUTPUT_FILE=$_SAVE_PID_OUTPUT_FILE

  while [ $# -gt 0 ]; do
    case "$1" in
    -nc)
      NO_CHECK=1
      ;;
    -bg)
      BACKGROUND=1
      ;;
    -po)
      PRINT_OUTPUT=1
      ;;
    -nl)
      LOGGING=0
      ;;
    -ef)
      EXIT_ON_FAIL=1
      ;;
    -co)
      COMMAND_OUTPUT=1
      COMMAND_OUTPUT_FILE=$2
      shift
      ;;
    -sp)
      SAVE_PID=1
      SAVE_PID_OUTPUT_FILE=$2
      shift
      ;;
    --*)
      echo "RUN function Illegal option $1"
      ;;
    esac
    shift $(($# > 0 ? 1 : 0))
  done

  if ((!$PRINT_OUTPUT && !$COMMAND_OUTPUT)); then
    COMMAND="$COMMAND >>/dev/null 2>&1"
  fi

  if (($COMMAND_OUTPUT)); then
    COMMAND="$COMMAND >>${COMMAND_OUTPUT_FILE} 2>&1"
  fi

  if (($BACKGROUND)); then
    COMMAND="$COMMAND &"
  fi

  if (($LOGGING)); then
    echo "+" $COMMAND
  fi

  if [ $_COMMAND_DEBUG_MODE -eq 0 ]; then
    eval $COMMAND && local PID=$!
    EXIT_CODE=$?
  else
    local PID=10000000
    EXIT_CODE=0
  fi

  if (($SAVE_PID)); then
    echo $PID >$SAVE_PID_OUTPUT_FILE
  fi

  if ((!$NO_CHECK)); then
    checkFail $EXIT_CODE "${COMMAND}" $EXIT_ON_FAIL
  fi
}


SEND_PUBLIC() {
  USE_TELEGRAM=$1
  USE_DISCORD=$2
  read -r -d '' msg <<EOT
  ${3}
EOT

  shift
  DISABLE_NOTIFICATION=$_DISABLE_NOTIFICATION

  while [ $# -gt 0 ]; do
    case "$1" in
    -dn)
      DISABLE_NOTIFICATION=1
      ;;
    --*)
      echo "RUN function Illegal option $1"
      ;;
    esac
    shift $(($# > 0 ? 1 : 0))
  done

  tel_msg=$msg
  tel_msg="${tel_msg//'\n'/$'\n'}"
  if [ $USE_TELEGRAM -eq 1 ]; then
    if (($DISABLE_NOTIFICATION)); then
      curl --data disable_notification="true" \
        --data chat_id="$PUBLIC_CHANNEL_ID" \
        --data-urlencode "text=${tel_msg}" \
        "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?parse_mode=HTML" >>/dev/null 2>&1
      EXIT_CODE=$?
      handleFailed $EXIT_CODE "- FAILED to send message in priva" "+ a msg sent to PUBLIC channel"
      return
    fi
    curl --data chat_id="$PUBLIC_CHANNEL_ID" \
      --data-urlencode "text=${tel_msg}" \
      "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?parse_mode=HTML"
    EXIT_CODE=$?
    handleFailed $EXIT_CODE "- FAILED to send message in priva" "+ a msg sent to PUBLIC channel"
  fi
  if [ $USE_DISCORD -eq 1 ]; then
    curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"${msg}\"}" ${DISCORD_WEBHOOK} >>/dev/null 2>&1
    EXIT_CODE=$?
    handleFailed $EXIT_CODE "- FAILED to send message in priva" "+ a msg sent to PUBLIC channel"
    echo end
  fi
}


SEND_FILE_PUBLIC() {
  read -r -d '' msg <<EOT
${4}
EOT
  USE_TELEGRAM=$1
  USE_GDRIVE=$2
  FILE_LOCATION=$3
  GOOGLE_DRIVE_PARENT=$4
  shift
  shift
  shift
  shift
  shift
  msg='' #todo this makes some problems!!!
  DISABLE_NOTIFICATION=$_DISABLE_NOTIFICATION

  while [ $# -gt 0 ]; do
    case "$1" in
    -dn)
      DISABLE_NOTIFICATION=1
      ;;
    --*)
      echo "RUN function Illegal option $1"
      ;;
    esac
    shift $(($# > 0 ? 1 : 0))
  done
  if [ $USE_TELEGRAM -eq 1 ]; then
    if (($DISABLE_NOTIFICATION)); then
      curl -F document=@\"${FILE_LOCATION}\" \
        -F disable_notification=\"true\" \
        -F chat_id=\"$PUBLIC_CHANNEL_ID\" \
        -F caption=\"${msg}\" \
        "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" >>/dev/null 2>&1
      EXIT_CODE=$?
      handleFailed $EXIT_CODE "- FAILED to send FILE in PUBLIC channel (A)" "+ a FILE sent to PUBLIC channel"
      return
    fi

    curl -F document=@\"${FILE_LOCATION}\" \
      -F chat_id=\"$PUBLIC_CHANNEL_ID\" \
      -F caption=\"${msg}\" \
      "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" >>/dev/null 2>&1
    EXIT_CODE=$?
    handleFailed $EXIT_CODE "- FAILED to send FILE in PUBLIC channel (B)" "+ a FILE sent to PUBLIC channel"
  fi
  if [ $USE_GDRIVE -eq 1 ]; then
    RUN "./gdrive files upload --recursive --parent ${GOOGLE_DRIVE_PARENT} ${FILE_LOCATION}" -po
  fi
}
SEND_FILE_PRIVATE() {
  read -r -d '' msg <<EOT
${2}
EOT
  FILE_LOCATION=$1
  shift
  shift

  curl -F document=@"${FILE_LOCATION}" \
    -F chat_id="$PRIVATE_CHANNEL_ID" \
    -F "caption=${msg}" \
    "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" >>/dev/null 2>&1
  EXIT_CODE=$?
  handleFailed $EXIT_CODE "- FAILED to send FILE in PRIVATE channel" "+ a FILE sent to PRIVATE channel"
}

SEND_PRIVATE() {
  read -r -d '' msg <<EOT
${1}
EOT

  curl --data chat_id="$PRIVATE_CHANNEL_ID" \
    --data-urlencode "text=${msg}" \
    "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?parse_mode=HTML" >>/dev/null 2>&1
  EXIT_CODE=$?
  handleFailed $EXIT_CODE "- FAILED to send message in priva" "+ a msg sent to PRIVATE channel"
}

SEND_ALERT() {
  read -r -d '' msg <<EOT
${1}
EOT
  shift
  DISABLE_NOTIFICATION=$_DISABLE_NOTIFICATION

  while [ $# -gt 0 ]; do
    case "$1" in
    -dn)
      DISABLE_NOTIFICATION=1
      ;;
    --*)
      echo "RUN function Illegal option $1"
      ;;
    esac
    shift $(($# > 0 ? 1 : 0))
  done

  if (($DISABLE_NOTIFICATION)); then
    curl --data disable_notification="true" \
      --data chat_id="$ALERT_CHANNEL_ID" \
      --data-urlencode "text=${msg}" \
      "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?parse_mode=HTML" >>/dev/null 2>&1
    EXIT_CODE=$?
    handleFailed $EXIT_CODE "- FAILED to send message in ALERT" "+ a msg sent to ALERT channel"
    return
  fi

  curl --data chat_id="$ALERT_CHANNEL_ID" \
    --data-urlencode "text=${msg}" \
    "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?parse_mode=HTML" >>/dev/null 2>&1
  EXIT_CODE=$?
  handleFailed $EXIT_CODE "- FAILED to send message in ALERT" "+ a msg sent to ALERT channel"
}

CREATE_DIRECTORY_IN_GDRIVE() {
  GROUP_NAME=$1
  
  # ./gdrive files list
  # output structure (with tab delimiter)
  # ID  NAME  TYPE  SIZE  CREATED MODIFIED

  # see if there is a folder name $GROUP_NAME in the google drive
  FOLDERS=$(./gdrive files list --field-separator '|' --skip-header|grep -E "folder"| cut -d'|' -f1,2)

  FOLDER_NAMES=$(echo "$FOLDERS" | cut -d'|' -f2)
  FOLDER_IDS=$(echo "$FOLDERS" | cut -d'|' -f1)

  # turn the string into array
  FOLDER_NAMES=($FOLDER_NAMES)
  FOLDER_IDS=($FOLDER_IDS)

  # check if the folder name exists return the id of the folder
  exist=0
  ID=''
  for i in "${!FOLDER_NAMES[@]}"; do
    if [ "${FOLDER_NAMES[$i]}" == "$GROUP_NAME" ]; then
      exist=1
      ID="${FOLDER_IDS[$i]}"
      break
    fi
  done


  if [ $exist -eq 0 ]; then
    res=$(./gdrive files mkdir $GROUP_NAME)
    ID=$(echo $res | cut -d':' -f2)
    ID=$(echo $ID | cut -d' ' -f2)
  fi
  
  echo $ID
}


LIST_DOCKER_CONTAINER_NAMES_AND_STATUS () {
  docker ps --format '{{.Names}} {{.Status}}'
}