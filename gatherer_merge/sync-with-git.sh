#! /bin/bash
set -e
set -x

if [ "x$GATHERER_SAVES" = "x" ]; then
  echo "GATHERER_SAVES environment variable is not set." 1>&2
fi

cd $(dirname $(readlink -f "$0") )

git fetch --all
git pull
lua ./merge.lua $GATHERER_SAVES
git commit -a -m "database merged by script at $(date +'%F %T')"
git push origin master
