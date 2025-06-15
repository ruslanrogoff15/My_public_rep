#!/bin/bash

dr="${1:-.}"
if [ ! -d "$dr" ]; then
    echo "Error: $dir is not a directory" >&2
    exit 1
fi
find "$dr" -type f -exec du -h {} + | sort -hr
