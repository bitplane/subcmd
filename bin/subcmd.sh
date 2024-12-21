#!/bin/bash

CMD_DIR=$(dirname "$0")
BASE_CMD=$1
shift

# Gather all non-dash arguments (until the first dash-option) as potential subcommand parts.
# The rest (including the dash-option and what follows) is leftover_args.
subcmd_parts=()
leftover_args=()

found_dash=false
for arg in "$@"; do
  if [[ $found_dash == false && "$arg" == -* ]]; then
    found_dash=true
  fi
  if [[ $found_dash == false ]]; then
    subcmd_parts+=( "$arg" )
  else
    leftover_args+=( "$arg" )
  fi
done

# We'll attempt from the longest subcmd down to just 1 subcmd-part.
# E.g. if subcmd_parts=( "world" "is" "the" "default" ), we try:
#   hello-world-is-the-default
#   hello-world-is-the
#   hello-world-is
#   hello-world
# If none exist, we fall back to `hello`.
for (( i=${#subcmd_parts[@]}; i>0; i-- )); do
  # Build a candidate script name from the first i words
  candidate="$BASE_CMD"
  for (( j=0; j<i; j++ )); do
    candidate="$candidate-${subcmd_parts[$j]}"
  done

  # The leftover for this candidate is:
  #  - the subcmd_parts that come after i
  #  - plus any leftover_args we collected after a dash
  candidate_leftover=( "${subcmd_parts[@]:$i}" "${leftover_args[@]}" )

  # If we find a matching script, exec it with leftover
  if [[ -x "$CMD_DIR/$candidate" ]]; then
    exec "$CMD_DIR/$candidate" "${candidate_leftover[@]}"
  fi
done

# No subcommand matched, so just run bin/$BASE_CMD with everything
exec "$CMD_DIR/$BASE_CMD" "$@"
