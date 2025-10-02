#!/bin/bash

awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $4); if ($4 > 2) print $0}' raw/requests-node-arguments-off.log | head -n 69 >filtered/requests-node-arguments-off.log
awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $4); if ($4 > 2) print $0}' raw/requests-node-arguments-on.log | head -n 69 >filtered/requests-node-arguments-on.log
