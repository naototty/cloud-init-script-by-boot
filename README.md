# cloud-init-script-by-boot
## Tips script
cloud-init script for by-boot

  2016/04/26 naoto-gohko@gmo.jp (@naoto_gohko)

# How to use;

cloud-initの機能を利用して、vmが起動時にスクリプトを実行します。
(べつに、rc.localでもできるけど、cloud-initの実行順番、OSの非依存性など考慮してcloud-init化されます)

## 事前環境: CLI環境の設定

CLI(OpenStack Client, OpenStack service client)で作業する場合の環境構築について、記載します。

### CentOS 7の場合

CentOS 7系はpython 2.7なので、パッケージも活用しつつ、virtualenvwrapper環境にCLIを構築します。

```bash
$ sudo yum -y install python-virtualenv-clone.noarch python-virtualenvwrapper.noarch python-tox.noarch python-virtualenv.noarch
```

使用するユーザの.bashrcに設定を入れる

```bash
$ echo '. /usr/bin/virtualenvwrapper.sh'  >> ~/.bashrc
```



#### [初回のみ]OSCなどのClient環境構築

初回は手動でよみこみます

```bash
$ . /usr/bin/virtualenvwrapper.sh
```

virtualenv名“openstack”でここでは作ります。(各自お好きなように)

```bash
$ mkvirtualenv openstack
```

この時点で、virtualenv “copenstack”に切り替わって、プロンプトがかわります

```bash
(openstack)$
```

##### pipでインストール; pip install python-openstackclient

OSC(OpenStackClient)をインストールするのはなぜか、ですが、使いやすいのはもちろん、サービスごとのClientも同時にインストールされるからです。

json, yaml, valueなどレスポンスの値を指定できるので、shell scriptに利用しやすくなっていますので、できればOSCを優先で使いましょう。


インストールします。

```bash
(openstack)$ pip install python-openstackclient
```

OS側に、rpm版の別バージョンを入れている場合には、コンフリクトしますので、次のコマンドでvirtualenv側に新しいバージョンを入れます

swift clientは別途入れる必要あります。

```bash
(openstack)$ pip install --upgrade pytz

(openstack)$ pip install --upgrade cliff

(openstack)$ pip install python-openstackclient python-swiftclient
```

```bash
(openstack)$ pip freeze | grep client
os-client-config==1.17.0
python-cinderclient==1.6.0
python-glanceclient==2.0.0
python-keystoneclient==2.3.1
python-novaclient==3.4.0
python-openstackclient==2.3.0
python-swiftclient==3.0.0
```


#### [2回目以降]OSC環境へのvirtualenv切り替え


virtualenvwrapperの切り替えのコマンドで切り替えます

```bash
$ workon openstack

(openstack)$
```
プロンプトが切り替わります


#### [2回目以降]OSC環境から抜ける場合


“deactivate”コマンドを実行します

```bash
(openstack)$ deactivate

$
```

プロンプトが元に戻ります


### 設定ファイル

OSCは従来の環境変数の他に、設定ファイルで利用できます。

OSC設定ファイルは以下のようになります

```bash
(openstack)$ cat ~/.config/openstack/clouds.yaml
clouds:
    myinfra:
        cloud: gmoappscloud
        auth:
            password: [ぱすわーど]
            project_name: [テナント名]
            username: [ユーザ名]
        interface: public
```

旧来のサービス(nova, neutron, cinder)クライアントCLIは、設定ファイルの対応がされていないので、
環境設定を読みこませるosrc.shを作っておきます。


設定ファイルと環境変数が同時に存在する場合、環境変数が優先されます
  環境変数 > userごとの設定ファイル



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

### cloud-init でパスワード上書き

このスクリプトは非推奨です。
できれば、ansibleなどでssh key loginしてパスワードを書き換えることを推奨します。

この方式では、パスワードをスクリプト内部にrawで書きます。


```bash
curl https://raw.githubusercontent.com/naototty/cloud-init-script-by-boot/master/02exp-keep-root-pass.sh \
  -o /var/lib/cloud/scripts/per-boot/02exp-keep-root-pass.sh

chmod 755 /var/lib/cloud/scripts/per-boot/02exp-keep-root-pass.sh
```

スクリプトを修正して、root passwordを設定します。
  * root_pass の値をplain textで書きます
  * 初期はランダムです

```bash
vim /var/lib/cloud/scripts/per-boot/02exp-keep-root-pass.sh

root_pass='hogehoge'

```

lock fileが無いことを確認します。

  * image作成後、展開時にlock fileがない場合のみ、02exp-keep-root-pass.sh は実行されます

```bash
ls -l /var/lib/cloud/tmp/.root_pass.lock

test -f /var/lib/cloud/tmp/.root_pass.lock && rm -rvf /var/lib/cloud/tmp/.root_pass.lock
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


# スクリプトの中身

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
旧来のサービス(nova, neutron, cinder)クライアントCLIは、設定ファイルの対応がされていないので、
環境設定を読みこませるosrc.shを作っておきます。


設定ファイルと環境変数が同時に存在する場合、環境変数が優先されます
  環境変数 > userごとの設定ファイル



## 設定を入れるPrivate imageの元となるvmを作成します

OSC(OpenStack client)などで作成します。



## あなたが Privateでイメージ保存したいイメージで、cloud-initの per-boot スクリプトに設定します。

curlで取得して、スクリプトを設置します。

```bash
