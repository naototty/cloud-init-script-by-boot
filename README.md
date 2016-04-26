# cloud-init-script-by-boot
## Tips script
cloud-init script for by-boot

  2016/04/26 naoto-gohko@gmo.jp (@naoto_gohko)

# How to use;

cloud-initの機能を利用して、vmが起動時にスクリプトを実行します。
(べつに、rc.localでもできるけど、cloud-initの実行順番、OSの非依存性など考慮してcloud-init化されます)


## 設定を入れるPrivate imageの元となるvmを作成します

OSC(OpenStack client)などで作成します。





## あなたが Privateでイメージ保存したいイメージで、cloud-initの per-boot スクリプトに設定します。

curlで取得して、スクリプトを設置します。

```bash
curl https://raw.githubusercontent.com/naototty/cloud-init-script-by-boot/master/01exp-keep-authorized_keys.sh \
  -o /var/lib/cloud/scripts/per-boot/01exp-keep-authorized_keys.sh

chmod 755 /var/lib/cloud/scripts/per-boot/01exp-keep-authorized_keys.sh
```

ディレクトリを作成して、vm作成時に追記したいssh authorized_keysをコピー配置しておきます。
(複数行でもOKのはず)


```bash
mkdir -p /var/lib/cloud/tmp

cp /root/my-additional-root-authorized_keys  /var/lib/cloud/tmp/root-authorized_keys
```


# スクリブとの中身

あまり大したことはしていません。

bashで行を調べて追記しています。

```bash
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

```
