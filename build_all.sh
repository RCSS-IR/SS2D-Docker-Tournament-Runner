#!/usr/bin/env bash
source ./utils.sh

RUN "bash build_network.sh" -po
RUN "bash build_server.sh" -po
RUN "bash build_teams.sh" -po