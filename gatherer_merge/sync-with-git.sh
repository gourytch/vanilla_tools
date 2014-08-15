#! /bin/bash
set -e
set -x

if [ "x$GATHERER_HOME" = "x" ]; then
  GATHERER_HOME=$(dirname $(readlink -f "$0") )
fi

cd "$GATHERER_HOME"
if [ ! -f merge.lua ]; then
  echo "merge.lua not found. set up GATHERER_HOME properly and re-run me" 1>&2
  exit 1
fi

if [ "x$GATHERER_SAVES" = "x" ]; then
  echo "set GATHERER_SAVES environment variable and re-run me" 1>&2
  exit 1
fi

git pull origin master
lua ./merge.lua $GATHERER_SAVES
git add MASTER.lua
git commit -m "database merged by script at $(date +'%F %T')"
git push origin master
