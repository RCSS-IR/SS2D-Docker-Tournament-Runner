#!/bin/bash

# ------------- PUBLIC ONES

source ./utils.sh
for team in $(ls bins); do
  RUN "bash build_team.sh -n ${team}" -po
done