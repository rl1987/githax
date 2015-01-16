#!/bin/sh

PARENT="$1"

if test "x$PARENT" = "x"; then
    echo "You must specify the parent branch."
    exit 1
fi

REV=`git log --reverse --format='%H' ${PARENT}..HEAD | head -1`

if test "x${REV}" = "x"; then
    echo "No changes here since ${PARENT}"
    exit 1
fi

git rebase -i --autosquash ${REV}^

