#!/bin/bash

set -u

BROKERS="$1"
TOPIC="$2"
TARGET_NETWORK="$3"

WAIT_TIMEOUT=$((5*60*1000))

fping -A -e -l -b12 -p "$WAIT_TIMEOUT" -g "$TARGET_NETWORK" 2>/dev/null | while read -r PING_RESPONSE; do
    ip_regex='([0-9a-fA-F.:]+)'
    regex="($ip_regex) +: \[(.*)\], (.*) bytes, (.*) ms \((.*) avg, (.*)% loss\)"
    [[ $PING_RESPONSE =~ $regex ]]
    IP="${BASH_REMATCH[1]}"
    COUNT="${BASH_REMATCH[2]}"
    PACKET_NUMBER="${BASH_REMATCH[3]}"
    SIZE="${BASH_REMATCH[4]}"
    ROUNDTRIP="${BASH_REMATCH[5]}"
    AVG="${BASH_REMATCH[6]}"
    LOSS_PERCENT="${BASH_REMATCH[7]}"

    NOW=$(date --iso-8601=ns)

    jq --unbuffered \
        --null-input \
        --compact-output --ascii-output --monochrome-output \
        --arg ip "$IP" \
        --arg size "$SIZE" \
        --arg roundtrip "$ROUNDTRIP" \
        --arg now "$NOW" \
        '{ "ip": $ip, "size": $size|tonumber, "roundtrip": $roundtrip|tonumber, "time": $now }'


done | kafkacat -P -b $BROKERS -t "$TOPIC"
