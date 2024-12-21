#!/bin/sh

CMD_DIR=$(dirname "$0")
BASE_CMD=$1
shift

#
# 1) Gather subcommand parts until we hit the first dash-option
#    or run out of arguments. Each "part" is stored in a separate
#    variable subcmd_1, subcmd_2, etc.
#
subcmd_count=0
found_dash=0

while [ $# -gt 0 ]; do
    case "$1" in
        -*)  # Once we see the first dash, stop adding to subcmd parts
            found_dash=1
            break
            ;;
        *)
            subcmd_count=$((subcmd_count + 1))
            # Store this arg in subcmd_1, subcmd_2, ...
            eval "subcmd_$subcmd_count=\"\$1\""
            ;;
    esac
    shift
done

#
# 2) Whatever is left (including the dash we broke on) are leftover args.
#    e.g. things like -f README.md or additional words.
#
# shellcheck disable=SC2086  # We actually do want to preserve the spacing in $@
leftover_args="$*"

#
# 3) Try subcommands from longest to shortest. If we find an executable
#    in $CMD_DIR, we exec it immediately. If none match, we fall back
#    to the base command.
#
try_count="$subcmd_count"
while [ "$try_count" -gt 0 ]; do
    #
    # Build a candidate string like "hello-file-contents"
    #
    candidate="$BASE_CMD"
    i=1
    while [ "$i" -le "$try_count" ]; do
        # read subcmd_i
        eval "part=\$subcmd_$i"
        candidate="$candidate-$part"
        i=$((i + 1))
    done

    #
    # Build the leftover subcommand parts (the ones after 'try_count')
    # so they can be appended to leftover_args.
    #
    leftover_subcmd=""
    i=$((try_count + 1))
    while [ "$i" -le "$subcmd_count" ]; do
        eval "part=\$subcmd_$i"
        if [ -z "$leftover_subcmd" ]; then
            leftover_subcmd="$part"
        else
            leftover_subcmd="$leftover_subcmd $part"
        fi
        i=$((i + 1))
    done

    #
    # If candidate is executable, run it with ( leftover_subcmd + leftover_args ).
    #
    if [ -x "$CMD_DIR/$candidate" ]; then
        # We’ll temporarily reset $@ to those leftover pieces for exec
        # so we don’t lose quoting. For true POSIX, we have to do it carefully:
        #
        # leftover_subcmd   -> subcmd words that didn't form part of the candidate
        # leftover_args     -> everything after the dash (if any)
        #
        # We'll build a single new list, then exec with it.

        # Step 1: Save old positional params so we can restore after
        old_pos="$*"

        # Step 2: Reset $@
        set --

        # Step 3: If we have leftover_subcmd, add them one by one
        if [ -n "$leftover_subcmd" ]; then
            # "set --" with a quoted expansion would split on spaces;
            # we need a loop.
            #
            # But leftover_subcmd is just space-separated. We do want them as separate
            # tokens, so a simple `for w in $leftover_subcmd` is correct:
            for w in $leftover_subcmd; do
                set -- "$@" "$w"
            done
        fi

        # Step 4: If we have leftover_args, also add them
        if [ -n "$leftover_args" ]; then
            # leftover_args is the raw $*, so we can do "set -- $@ $leftover_args"
            # safely with POSIX if we trust leftover_args was formed from shift.
            set -- "$@" $leftover_args
        fi

        exec "$CMD_DIR/$candidate" "$@"
        # If exec fails, we exit. But presumably it won't if the file is -x.
    fi

    try_count=$((try_count - 1))
done

#
# 4) If we never matched a subcommand, fall back to the base script
#    with all original subcmd parts plus leftover args.
#
# Rebuild the original subcmd parts as well:
all_subcmd=""
i=1
while [ "$i" -le "$subcmd_count" ]; do
    eval "part=\$subcmd_$i"
    if [ -z "$all_subcmd" ]; then
        all_subcmd="$part"
    else
        all_subcmd="$all_subcmd $part"
    fi
    i=$((i + 1))
done

# Now we exec the base command with all subcmd parts + leftover
set --
# Subcmd parts (if any)
if [ -n "$all_subcmd" ]; then
    for w in $all_subcmd; do
        set -- "$@" "$w"
    done
fi
# leftover
if [ -n "$leftover_args" ]; then
    set -- "$@" $leftover_args
fi

exec "$CMD_DIR/$BASE_CMD" "$@"
