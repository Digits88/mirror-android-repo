#!/bin/bash
#
# Checks the repo log for a certain author/email in git's history.
# 
# This will write the path of the projects on the git server to
# git-projects.txt to be manually checked and rewritten.
#
# Brandon Amos
# 2012.08.17

# Note these don't follow the normal convention I use for
# places that need replacing
AUTHOR_EMAIL="oldName <oldEmail>"

# Get the current directory. It should be the root directory of the Android checkout.
BASE_DIR=$PWD

# Get a list of git repositories that repo has checked out
repo forall -c 'echo $REPO_PATH' > paths.txt
repo forall -c 'echo $REPO_PROJECT' > projects.txt

rm -f git-projects.txt

# Go through all of the logs
COUNT=0
while read REPO_PATH
do
  let COUNT++

  cd $REPO_PATH
  LOG_CHECK=`git log | grep "$AUTHOR_EMAIL"`
  cd $BASE_DIR

  # Store the path to the project on the git server
  if [ "$LOG_CHECK" ]; then
    echo `sed -n "${COUNT}p" projects.txt` >> git-projects.txt
  fi
done < paths.txt

# Display the file
cat git-projects.txt

# Clean up
rm {paths,projects}.txt
