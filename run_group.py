#!/usr/bin/env python3
import os
import sys
import argparse
import subprocess
from random import choices
import string
import time


HERE = os.getcwd()
GAME_LIST = ""
ROOT_LOG_DIR = f"{HERE}/logs"
ROOT_EVENT_DIR = f"{HERE}/events"
TAG = 'latest'
NETWORKS = []


def print_help():
    print("""
    Usage : run_group.py [OPTIONS]
    Options:
        -gl, --game-list [game list path]   list of games(file)
        -ld, --log_directory                log directory
        -ed, --event_directory              server and event directory
        -n , --network                      network
        -ns , --networks                    comma separated list of networks
        -t,  --tag                          image tag
    """)


def check_params(args):
    global GAME_LIST, ROOT_LOG_DIR, ROOT_EVENT_DIR, NETWORKS
    if args.game_list:
        GAME_LIST = args.game_list
    if args.log_directory:
        ROOT_LOG_DIR = args.log_directory
    if args.event_directory:
        ROOT_EVENT_DIR = args.event_directory
    if args.networks:
        NETWORKS = args.networks.split(',')
    elif args.network:
        NETWORKS = [args.network]
    if args.tag:
        global TAG
        TAG = args.tag

    if not all([GAME_LIST, ROOT_LOG_DIR, ROOT_EVENT_DIR, NETWORKS]):
        print_help()
        sys.exit(1)

    if not ROOT_LOG_DIR.startswith('/'):
        ROOT_LOG_DIR = f"{HERE}/{ROOT_LOG_DIR}"
    if not ROOT_EVENT_DIR.startswith('/'):
        ROOT_EVENT_DIR = f"{HERE}/{ROOT_EVENT_DIR}"
    if ROOT_LOG_DIR.endswith('/'):
        ROOT_LOG_DIR = ROOT_LOG_DIR[:-1]
    if ROOT_EVENT_DIR.endswith('/'):
        ROOT_EVENT_DIR = ROOT_EVENT_DIR[:-1]


def print_params():
    print("-------------------------------------")
    print("            ENVIRONMENTS")
    print("-------------------------------------")
    print(f"GAME_LIST     : {GAME_LIST}")
    print(f"LOG_DIR       : {ROOT_LOG_DIR}")
    print(f"EVENT_DIR     : {ROOT_EVENT_DIR}")
    print(f"NETWORKS      : {', '.join(NETWORKS)}")
    print("-------------------------------------")
    print("             LIST OF GAMES           ")
    game_string = f"🟩 The server ({', '.join(NETWORKS)}) will run the following games:"
    with open(GAME_LIST, 'r') as file:
        for line in file:
            print(line.strip())
            game_string += f"\n ⚽ {line.strip()}"
    print("-------------------------------------")


def run(command):
    subprocess.run(command, shell=True, check=True)


def remove_game():
    run(f"tail {GAME_LIST} -n +2 > {GAME_LIST}_tmp")
    run(f"cat {GAME_LIST}_tmp > {GAME_LIST}")
    run(f"rm {GAME_LIST}_tmp")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-gl', '--game_list', help='list of games(file)')
    parser.add_argument('-ld', '--log_directory', help='log directory')
    parser.add_argument('-ed', '--event_directory', help='server and event directory')
    parser.add_argument('-n', '--network', help='network')
    parser.add_argument('-ns', '--networks', help='comma separated list of networks')
    parser.add_argument('-t', '--tag', help='image tag')
    args = parser.parse_args()

    check_params(args)
    print_params()

    counter = 0
    while True:
        counter += 1
        with open(GAME_LIST, 'r') as file:
            line = file.readline().strip()

        if not line:
            break

        time_stamp = f"G{''.join(choices(string.ascii_letters + string.digits, k=5))}P"
        game_conf = line.split()
        group_name = game_conf[0]
        log_dir = f"{ROOT_LOG_DIR}/{group_name}"
        event_dir = f"{ROOT_EVENT_DIR}/{group_name}"

        run(f"mkdir -p {log_dir}")
        run(f"mkdir -p {event_dir}")
        run(f"chmod 777 {log_dir} -R")
        run(f"chmod 777 {event_dir} -R")

        print("**********************************************************")
        print(line)

        for network in NETWORKS:
            params = f"-ts {time_stamp} -st {game_conf[1]} -gt {game_conf[2]} -ld {log_dir} -ed {event_dir} -l {game_conf[3]} -r {game_conf[4]} -n {network} -t {TAG}"
            print(f"Running on network: {network}")
            print(params)
            # run(f"./run_game.sh {params}")

        print("**********************************************************")

        remove_game()
        time.sleep(1)


if __name__ == "__main__":
    main()
# ./run_group.py -ns server1,server2 -gl games/test_sync -ld $(pwd)/log -ed $(pwd)/log
# ./run_group.py -n server1 -gl games/test_sync -ld $(pwd)/log -ed $(pwd)/log