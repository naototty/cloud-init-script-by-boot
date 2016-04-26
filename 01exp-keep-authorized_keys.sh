#!/bin/bash


tmp_dir=/var/lib/cloud/tmp
test -d $tmp_dir || mkdir -p $tmp_dir

authed_keys=/root/.ssh/authorized_keys

bk_key=$tmp_dir/root-authorized_keys
stub_bk_key=$tmp_dir/bk-authorized_keys.stub

test -f $stub_bk_key && rm -rf $stub_bk_key

if [ -f $authed_keys ]; then
  key_cnt=$( wc -l $authed_keys | awk '{print $1}' )
  if [ -f $bk_key ]; then
    bk_key_md5=$( md5sum $bk_key | awk '{print $1}' )
    authed_keys_md5=$( md5sum $authed_keys | awk '{print $1}' )
    if [ $( echo $bk_key_md5 | grep -c $authed_keys_md5 ) -eq 0 ]; then
      cat $authed_keys | {
        while read LINE;
        do
          key_line=${LINE}
          if [ $( echo $key_line | grep -c $bk_key ) -eq 0 ]; then
            echo $key_line >> $stub_bk_key
          fi
        done
      }
      cat $stub_bk_key $bk_key | sort | uniq > ${bk_key}.new
      cat ${bk_key}.new > $authed_keys
      cat ${bk_key}.new > ${bk_key}.old
    fi
  fi
fi
