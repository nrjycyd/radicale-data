# radicale-data

## 自定义配置

项目结构

```
/docker/radicale/
├── compose.yml                # Docker Compose 配置
├── update_radicale.sh         # 定时更新数据的脚本
├── data/                      # Radicale 日历数据
├── config/
│   ├── config                 # Radicale 主配置文件
└── └── users                  # 用户认证文件
```

- `config` 文件，使用存储库中的 [预配置文件](https://github.com/tomsquest/docker-radicale/blob/master/config)，参数调整如下

    ```ini
    [server]
    hosts = 0.0.0.0:5232
    
    [auth]
    type = htpasswd
    htpasswd_filename = /config/users
    htpasswd_encryption = bcrypt
    
    [storage]
    filesystem_folder = /data/collections
    ```

- `users` 文件，每行包含用户名和经过 bcrypt 哈希处理的密码，中间用冒号 ( `:`) 分隔

  ```ini
  john:$2a$10$l1Se4qIaRlfOnaC1pGt32uNe/Dr61r4JrZQCNnY.kTx2KgJ70GPSm
  sarah:$2a$10$lKEHYHjrZ.QHpWQeB/feWe/0m4ZtckLI.cYkVOITW8/0xoLCp1/Wy
  ```

  > bcrypt 哈希在线生成链接：https://it-tools.tech/bcrypt

## 脚本使用

`update_radicale.sh` 脚本会自动更新中国黄历，原始数据来自项目 [metowolf/vCards](https://github.com/metowolf/vCards)

脚本使用时应该使用与 `UID`/`GID` 一致的用户执行，否则可能会出现权限问题，导致容器内外的数据无法正常读写。

- **群晖**

  「控制面板」→「任务计划」→「新增」→「计划的任务」→「用户定义的脚本」

- **Debian** 

  设置权限

  ```bash
  cd /docker/radicale
  sudo chmod +x update_radicale.sh
  sudo chmod 600 config/users
  ```

  设置定时任务

  ```bash
  sudo crontab -e
  ```

  添加：

  ```swift
  0 3 * * * /docker/radicale/update_radicale.sh >> /docker/radicale/logs/update_radicale.log 2>&1
  ```

  
