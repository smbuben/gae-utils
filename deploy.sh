#!/bin/bash

#
# The MIT License (MIT)
#
# Copyright (C) 2014 Stephen M Buben <smbuben@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

function usage {
cat <<EOM
Usage: $0 project_directory [-f]

Deploy the given project directory to Google AppEngine. Automatically create
the file 'static/revision' in the project directory.

Available options:
    -f      Force deployment. Deploy even if:
                - the project has uncommitted changes
                - the 'master' branch is not active
                - the project is not under version control

EOM
}

if [ -z "$1" -o "$1" = "-h" ] ; then
    usage
    exit 1
fi

if [ ! -d $1 ] ; then
    echo "project directory does not exist"
    exit 1
fi

function continue_only_if_forced {
    if [ "$FLAG" != "-f" ] ; then
        exit 1
    fi
}

cd $1
FLAG=$2

STATUS=`git status | tail -n 1`
if [ "$STATUS" != "nothing to commit, working directory clean" ] ; then
    echo "project directory not clean"
    continue_only_if_forced
fi

BRANCH=`git branch | grep "^*" | cut -d " " -f 2`
if [ "$BRANCH" != "master" ] ; then
    echo "not on master (on $BRANCH)"
    continue_only_if_forced
fi

REVISION=`git rev-parse $BRANCH`
if [ -z "$REVISION" ] ; then
    echo "cannot determine revision"
    continue_only_if_forced
fi

cd - >/dev/null

echo "deploying $1 revision $BRANCH/$REVISION"
echo "$BRANCH/$REVISION" > $1/static/revision

google_appengine/appcfg.py \
    --oauth2 \
    update \
    $1

