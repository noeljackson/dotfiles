#!/bin/zsh
typeset -A remotes
remotes=(
  local1 remote1
  local2 remote2
)

for local remote in "${(@kv)remotes}"  # (kv) means key and value
                                       # and (@) within quotes is to
                                       # preserve empty ones (in your
                                       # case ${(kv)remotes} would be
                                       # enough as file paths are not
                                       # meant to be empty).
do
    (
        echo $local &&
        echo $remote
    )
done

typeset {docker,virtualbox,charles}=casks

for cask in casks
do 
(
    echo $cask
)
done