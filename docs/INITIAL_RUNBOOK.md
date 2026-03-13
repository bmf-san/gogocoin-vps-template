# 初回 VPS セットアップ手順

初めて VPS に gogocoin を構築する際の手順書。
一度完了すれば以後のデプロイは [RUNBOOK](RUNBOOK.md) を参照。

---

## 1. VPS を用意する

お好みの VPS プロバイダーで以下のスペックのサーバーを用意します:

- OS: **Ubuntu 24.04 LTS (64bit)**
- スペック目安: 1GB RAM / 1コア以上 / SSD 10GB 以上
- 自動バックアップ: 任意
- SSH 鍵認証を有効化

VPS の IP アドレスと SSH 秘密鍵をメモしておきます。

---

## 2. VPS に SSH 接続する

```bash
chmod 600 ~/.ssh/gogocoin
ssh -i ~/.ssh/gogocoin root@<VPS_IP>
```

> SSH 鍵のパスを変更した場合は `Makefile` の `SSH_KEY` 変数を合わせて変更してください。

---

## 3. setup.sh を転送して実行する

ローカルマシンから以下を実行します:

```bash
make setup CONOHA_HOST=<VPS_IP>
```

スクリプトが完了すると以下が整います:
- `libsqlite3-0` / `ufw` / `curl` のインストール
- `gogocoin` サービスユーザーの作成
- `/opt/gogocoin/{data,logs,configs,web}` の作成
- `gogocoin.service` の `/etc/systemd/system/` への配置・enable
- UFW: 22/tcp のみ許可（8080 は外部非公開）
- SSH: パスワード認証を無効化（鍵認証のみ）

---

## 4. config.yaml を配置する

gogocoin リポジトリの `configs/config.example.yaml` を参考に `configs/config.yaml` を作成し、以下で転送します:

```bash
make config CONOHA_HOST=<VPS_IP>
```

> `GOGOCOIN_DIR` のデフォルトは `../gogocoin` です。異なる場所にある場合は `make config CONOHA_HOST=<VPS_IP> GOGOCOIN_DIR=/path/to/gogocoin` で指定してください。

> `config.yaml` 内の `${BITFLYER_API_KEY}` / `${BITFLYER_API_SECRET}` は `.env` の値で自動展開されます。`.env` はデプロイ時に GitHub Secrets から自動生成されるため手動作成は不要です。

---

## 5. Makefile に VPS_IP を設定する（任意）

毎回 `CONOHA_HOST=<VPS_IP>` を指定する手間を省くために、`Makefile` の `CONOHA_HOST` にデフォルト値を設定できます:

```makefile
CONOHA_HOST  ?= <VPS_IP>  # ← ここに IP を記入
```

---

## 6. GitHub Secrets を登録する

このリポジトリの Secrets 設定ページで以下を登録:

| Secret 名 | 値 |
|---|---|
| `CONOHA_HOST` | VPS の IP アドレス |
| `CONOHA_USER` | SSH ユーザー名（例: `root`） |
| `CONOHA_SSH_KEY` | SSH 秘密鍵の内容（`cat ~/.ssh/gogocoin` の出力を丸ごとペースト） |
| `BITFLYER_API_KEY` | bitFlyer API キー |
| `BITFLYER_API_SECRET` | bitFlyer API シークレット |

---

## 7. 初回デプロイを実行する

1. GitHub のリポジトリで「Actions」タブを開く
2. 「Deploy」ワークフローを選択
3. 「Run workflow」ボタンをクリック
4. ref に `main`（または `v1.0.0` などのタグ）を入力して実行

ワークフローが成功すると:
- `/opt/gogocoin/gogocoin` バイナリと `web/` が転送される
- GitHub Secrets から `.env` が生成される
- `gogocoin.service` が起動する

---

## 8. 動作を確認する

```bash
ssh -i ~/.ssh/gogocoin root@<VPS_IP> "systemctl status gogocoin"
```

`active (running)` と表示されれば正常です。

```bash
ssh -i ~/.ssh/gogocoin root@<VPS_IP> "journalctl -u gogocoin -n 50"
```

---

## 9. WebUI にアクセスする

ローカルマシンで SSH トンネルを張ります:

```bash
make tunnel CONOHA_HOST=<VPS_IP>
```

ブラウザで `http://localhost:8080` を開きます。

---

## トラブルシューティング

### サービスが起動しない

```bash
ssh -i ~/.ssh/gogocoin root@<VPS_IP> "journalctl -u gogocoin -n 100"
```

よくある原因:
- `/opt/gogocoin/configs/config.yaml` が存在しない
- バイナリがまだ転送されていない（初回デプロイ前）
- `.env` が生成されていない（デプロイ前、または Secrets 未登録）
