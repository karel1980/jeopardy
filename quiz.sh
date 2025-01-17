#!/bin/bash

YAML="${1:-jeopardy-conundra-1.yml}"

echo "Using $YAML"
if [ ! -e "$YAML" ]; then
    echo "$YAML does not exist"
fi

./yaml2json "$YAML" | tee jeopardy.json

echo Updated jeopardy.json

