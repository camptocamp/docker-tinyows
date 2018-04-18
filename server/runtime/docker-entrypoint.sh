#!/bin/bash
set -e

#Run entry point scripts if any
DIR=/docker-entrypoint.d
if [[ -d "$DIR" ]]
then
    for env_file in `/bin/run-parts --list --regex '\.env$' "$DIR"`
    do
        . "$env_file"
    done
    /bin/run-parts --regex '\.sh$' "$DIR"
fi

rm -f $APACHE_RUN_DIR/apache2.pid

exec "$@"
