#!/bin/bash

set -u

BROKERS="$1"
TOPIC="$2"

fping -A -e -l -b12 -p 60000 -g 10.0.0.0/22 2>/dev/null | while read -r PING_RESPONSE; do
    ip_regex='[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}'
    regex="($ip_regex)[ ]+: \[(.*)\], (.*) bytes, (.*) ms \((.*) avg, (.*)% loss\)"
    [[ $PING_RESPONSE =~ $regex ]]
    IP="${BASH_REMATCH[1]}"
    COUNT="${BASH_REMATCH[2]}"
    SIZE="${BASH_REMATCH[3]}"
    ROUNDTRIP="${BASH_REMATCH[4]}"
    AVG="${BASH_REMATCH[5]}"
    LOSS_PERCENT="${BASH_REMATCH[6]}"

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
