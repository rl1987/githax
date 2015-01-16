#!/bin/sh

REV=`git log --reverse --format='%H' master..HEAD | head -1`

git rebase -i --autosquash ${REV}^

