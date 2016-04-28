#!/bin/bash


tmp_dir=/var/lib/cloud/tmp
test -d $tmp_dir || mkdir -p $tmp_dir

lock_file=/var/lib/cloud/tmp/.root_pass.lock


# textでやる場合(推奨しない、できれば、ansibleなどで展開して)
# root_pass="hogehoge"

# ランダムに上書きする場合
root_pass=$(openssl rand -base64 9 | awk '{print $1}')


if [ ! -f $lock_file ]; then
  usermod -p `echo ${root_pass} | openssl passwd -1 -stdin` root

  touch $lock_file
fi
