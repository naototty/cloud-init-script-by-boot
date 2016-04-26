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

## イメージ保存します

privateイメージを保存します。

```bash
openstack server image create --wait --name u1404-cloud-init-test02 2682d12f-a50e-4e8f-a517-540ac2548b29 -f json
```

  * 2682d12f-a50e-4e8f-a517-540ac2548b29 : vmのインスタンスID
  * u1404-cloud-init-test02 : private image保存名称

privateイメージを確認します。

```bash
openstack image list --private -f value
```

## 保存したprivate imageでvmを作成します

先ほど作成したイメージを指定して、vmを作成します

```bash
openstack server create --image u1404-cloud-init-test02 --flavor L-0102_D new-u1404-4 -f yaml
```

responseがこの場合、yamlで
  id:
が server idとなる


## ssh接続を管理ノード経由で行います


出来たvmを確認します

```bash
openstack server list -f value

openstack server show d88ef579-fa90-497a-9c1a-bd770f0f75f8  -f value
```

ssh接続します(管理ノードのみ)

```bash
openstack server ssh -4 --login root --port 10022 \
  --identity ./admin-node-root-id_rsa \
  --option 'HostName=133.130.ab.cd -o Port=22 -o StrictHostKeyChecking=no -o User=root' \
  --address-type=private d88ef579-fa90-497a-9c1a-bd770f0f75f8
```
作業端末からのssh key loginの設定をしていない場合、管理ノードへのssh パスワードがプロンプトがでます。

  * 133.130.ab.cd : 最初に作られるpublic IP (GMO AppsCloud サービスごとの固定値です)
  * --option 'オプション' : ssh接続時のオプション(動作は --debug で確認できる)
  * --address-type=private : アプリクラウドはfloating IPが無いので、内部のL4側IPはPrivateネットワーク指定となります
  * --identify "private key path" : private keyは管理ノードのrootから取ってきます。


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
