# Boot Volume by CLI

* 2016/04/27 youngwoon-park@gmo.jp

## 目的
* 商材: Unit40
* ゴール: NプランVM+追加ディスクをつけた状態をCLIで作成・削除する

## 作業手順
* 作成
  - ブートボリューム作成
  - 追加ボリューム作成（100GB）
  - ブートボリュームを指定してVM作成
  - VM停止
  - 追加ボリュームをVMへアタッチ
  - VM起動
* 削除
  - VM停止
  - VM削除
  - 追加ボリューム削除
  - ブートボリューム削除
  

## OpenStack Client

* OpenStack Client Version
```
$ openstack --version
openstack 2.4.0
```

* Create and source the OpenStack RC file
```
## RCファイル作成
$ vi PROJECT-openrc.sh
export OS_USERNAME=app*****
export OS_PASSWORD=********
export OS_AUTH_URL=https://ident-r2nd1001.app-sys.jp/v2.0
export OS_TENANT_ID=****************
## ソース・ファイル
$ . PROJECT-openrc.sh
```

### 作成フロー
* ボリュームタイプ取得
```
$ openstack volume type list
+--------------------------------------+----------------+
| ID                                   | Name           |
+--------------------------------------+----------------+
| 29001088-5e0b-42ff-99b1-2900b5abf4a8 | ext_iops1k_D   |
| 4e1bbdf3-d16e-4992-b28c-1788055c0be2 | os_boot_v2     |
+--------------------------------------+----------------+
```

* ブートボリューム作成
```
$ openstack volume create --size 30 --type os_boot_v2 --image 4e10e3da-ad7a-4594-8438-be6f7aa6ae2b openstack-client-test01
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| attachments         | []                                   |
| availability_zone   | nova                                 |
| bootable            | false                                |
| consistencygroup_id | None                                 |
| created_at          | 2016-04-26T07:55:56.374942           |
| description         | None                                 |
| encrypted           | False                                |
| id                  | 004158aa-5954-4b61-9b58-6076dd3eab02 |
| name                | openstack-client-test01              |
| properties          |                                      |
| replication_status  | disabled                             |
| size                | 28                                   |
| snapshot_id         | None                                 |
| source_volid        | None                                 |
| status              | creating                             |
| type                | os_boot_v2                           |
| user_id             | 4f00399e650a48368133d49413199522     |
+---------------------+--------------------------------------+
```

* 追加ボリューム作成（100GB）
```
$ openstack volume create --size 100 --type ext_iops1k_D openstack-client-addvol01
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| attachments         | []                                   |
| availability_zone   | nova                                 |
| bootable            | false                                |
| consistencygroup_id | None                                 |
| created_at          | 2016-04-26T08:00:27.014835           |
| description         | None                                 |
| encrypted           | False                                |
| id                  | 93ce9a49-330d-4ac1-862e-a6d12e7dfec9 |
| name                | openstack-client-addvol01            |
| properties          |                                      |
| replication_status  | disabled                             |
| size                | 100                                  |
| snapshot_id         | None                                 |
| source_volid        | None                                 |
| status              | creating                             |
| type                | ext_iops1k_D                         |
| user_id             | 4f00399e650a48368133d49413199522     |
+---------------------+--------------------------------------+
```

* ボリュームリスト取得
```
$ openstack volume list
+--------------------------------------+---------------------------+-----------+------+----------------------------------------+
| ID                                   | Display Name              | Status    | Size | Attached to                            |
+--------------------------------------+---------------------------+-----------+------+----------------------------------------+
| 93ce9a49-330d-4ac1-862e-a6d12e7dfec9 | openstack-client-addvol01 | available |  100 |                                        |
| 004158aa-5954-4b61-9b58-6076dd3eab02 | openstack-client-test01   | available |   28 |                                        |
+--------------------------------------+---------------------------+-----------+------+----------------------------------------+
```

* フレーバーリスト取得
```
$ openstack flavor list
+---------+-------------+--------+------+-----------+-------+-----------+
| ID      | Name        |    RAM | Disk | Ephemeral | VCPUs | Is Public |
+---------+-------------+--------+------+-----------+-------+-----------+
| 201021  | N-0102_H    |   2048 |   28 |         0 |     1 | True      |
+---------+-------------+--------+------+-----------+-------+-----------+
```

* ブートボリュームを指定してVM作成(現段階ではCLIからの作成不可)
```
$ curl -X POST \
-H "X-Auth-Token: ********************" \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
-d '{
    "server": {
        "flavorRef": "201021",
        "block_device_mapping": [
            {
                "volume_id": "004158aa-5954-4b61-9b58-6076dd3eab02"
            }
        ]
    }
}' \
https://compute-r2nd1001.app-sys.jp/v2/77e244143543403babd8dd448703b97f/servers
{
    "server": {
        "security_groups": [
            {
                "name": "default"
            }
        ],
        "OS-DCF:diskConfig": "MANUAL",
        "id": "7ab06191-c12f-4d06-b0b5-949a07be12d1",
        "links": [
            {
                "href": "https://compute-r2nd1001.app-sys.jp/v2/77e244143543403babd8dd448703b97f/servers/7ab06191-c12f-4d06-b0b5-949a07be12d1",
                "rel": "self"
            },
            {
                "href": "https://compute-r2nd1001.app-sys.jp/77e244143543403babd8dd448703b97f/servers/7ab06191-c12f-4d06-b0b5-949a07be12d1",
                "rel": "bookmark"
            }
        ],
        "adminPass": "YgVkepnhE7ff"
    }
}
```

* VM停止
```
$ openstack server stop 7ab06191-c12f-4d06-b0b5-949a07be12d1
```

* VM詳細
```
$ openstack server show 7ab06191-c12f-4d06-b0b5-949a07be12d1
+--------------------------------------+----------------------------------------------------------+
| Field                                | Value                                                    |
+--------------------------------------+----------------------------------------------------------+
| OS-DCF:diskConfig                    | MANUAL                                                   |
| OS-EXT-AZ:availability_zone          | nova                                                     |
| OS-EXT-STS:power_state               | 4                                                        |
| OS-EXT-STS:task_state                | None                                                     |
| OS-EXT-STS:vm_state                  | stopped                                                  |
| OS-SRV-USG:launched_at               | 2016-04-27T03:29:07.000000                               |
| OS-SRV-USG:terminated_at             | None                                                     |
| accessIPv4                           |                                                          |
| accessIPv6                           |                                                          |
| addresses                            | net-2391-int=10.138.12.22; net-2391-ext=10.137.12.22     |
| config_drive                         | True                                                     |
| created                              | 2016-04-27T03:28:58Z                                     |
| flavor                               | N-0102_H (201021)                                        |
| hostId                               | 47d03d03c151ce43a68ff5899d3b859bd2d32f93faa9287fa0d8ab54 |
| id                                   | 7ab06191-c12f-4d06-b0b5-949a07be12d1                     |
| image                                |                                                          |
| key_name                             | None                                                     |
| name                                 | 10-138-12-22                                             |
| os-extended-volumes:volumes_attached | [{u'id': u'004158aa-5954-4b61-9b58-6076dd3eab02'}]       |
| project_id                           | 77e244143543403babd8dd448703b97f                         |
| properties                           |                                                          |
| security_groups                      | [{u'name': u'default'}, {u'name': u'default'}]           |
| status                               | SHUTOFF                                                  |
| updated                              | 2016-04-27T04:52:29Z                                     |
| user_id                              | 4f00399e650a48368133d49413199522                         |
+--------------------------------------+----------------------------------------------------------+
```

* 追加ボリュームをVMへアタッチ
```
$ openstack server add volume 7ab06191-c12f-4d06-b0b5-949a07be12d1 93ce9a49-330d-4ac1-862e-a6d12e7dfec9
```

* VM起動
```
$ openstack server start 7ab06191-c12f-4d06-b0b5-949a07be12d1
```

### 削除フロー

* VM停止
```
$ openstack server stop 7ab06191-c12f-4d06-b0b5-949a07be12d1
```

* VM詳細
```
$ openstack server show 7ab06191-c12f-4d06-b0b5-949a07be12d1
+--------------------------------------+------------------------------------------------------------------------------------------------------+
| Field                                | Value                                                                                                |
+--------------------------------------+------------------------------------------------------------------------------------------------------+
| OS-DCF:diskConfig                    | MANUAL                                                                                               |
| OS-EXT-AZ:availability_zone          | nova                                                                                                 |
| OS-EXT-STS:power_state               | 4                                                                                                    |
| OS-EXT-STS:task_state                | None                                                                                                 |
| OS-EXT-STS:vm_state                  | stopped                                                                                              |
| OS-SRV-USG:launched_at               | 2016-04-27T03:29:07.000000                                                                           |
| OS-SRV-USG:terminated_at             | None                                                                                                 |
| accessIPv4                           |                                                                                                      |
| accessIPv6                           |                                                                                                      |
| addresses                            | net-2391-int=10.138.12.22; net-2391-ext=10.137.12.22                                                 |
| config_drive                         | True                                                                                                 |
| created                              | 2016-04-27T03:28:58Z                                                                                 |
| flavor                               | N-0102_H (201021)                                                                                    |
| hostId                               | 47d03d03c151ce43a68ff5899d3b859bd2d32f93faa9287fa0d8ab54                                             |
| id                                   | 7ab06191-c12f-4d06-b0b5-949a07be12d1                                                                 |
| image                                |                                                                                                      |
| key_name                             | None                                                                                                 |
| name                                 | 10-138-12-22                                                                                         |
| os-extended-volumes:volumes_attached | [{u'id': u'004158aa-5954-4b61-9b58-6076dd3eab02'}, {u'id': u'93ce9a49-330d-4ac1-862e-a6d12e7dfec9'}] |
| project_id                           | 77e244143543403babd8dd448703b97f                                                                     |
| properties                           |                                                                                                      |
| security_groups                      | [{u'name': u'default'}, {u'name': u'default'}]                                                       |
| status                               | SHUTOFF                                                                                              |
| updated                              | 2016-04-28T02:07:45Z                                                                                 |
| user_id                              | 4f00399e650a48368133d49413199522                                                                     |
+--------------------------------------+------------------------------------------------------------------------------------------------------+
```

* VM削除
```
$ openstack server delete 7ab06191-c12f-4d06-b0b5-949a07be12d1
```

* 追加ボリューム削除
```
$ openstack volume delete 93ce9a49-330d-4ac1-862e-a6d12e7dfec9
```

* ブートボリューム削除
```
$ openstack volume delete 004158aa-5954-4b61-9b58-6076dd3eab02
```
