# 運用手順書（RUNBOOK）

初回セットアップ完了後の日常運用手順をまとめます。
初回セットアップは [INITIAL_RUNBOOK](INITIAL_RUNBOOK.md) を参照してください。

---

## setup.sh / gogocoin.service の更新

`setup.sh` や `gogocoin.service` を変更した場合は以下で VPS に反映します:

```bash
make setup CONOHA_HOST=<VPS_IP>
```

> `gogocoin.service` を変更した場合はサービスの再起動が必要です:
> ```bash
> ssh -i ~/.ssh/gogocoin root@<VPS_IP> "systemctl daemon-reload && systemctl restart gogocoin"
> ```

---

## デプロイ

### 新しいバージョンをデプロイする

1. GitHub のリポジトリで「Actions」タブを開く
2. 「Deploy」ワークフローを選択し「Run workflow」をクリック
3. ref に以下のいずれかを入力して実行:
   - タグ: `v1.2.0`（特定リリースをデプロイ）
   - ブランチ: `main`（最新コードをデプロイ）

ワークフローの処理内容:
1. `bmf-san/gogocoin` を指定の ref でチェックアウト
2. `CGO_ENABLED=1` で Linux amd64 バイナリをビルド
3. バイナリ・`web/` を rsync で転送
4. GitHub Secrets から `.env` を生成・上書き
5. `systemctl restart gogocoin` でサービス再起動

---

## WebUI へのアクセス

### SSH トンネルを張ってダッシュボードを開く

```bash
make tunnel CONOHA_HOST=<VPS_IP>
```

ブラウザで `http://localhost:8080` を開きます。

> `-N` オプションによりコマンド実行なしにトンネルのみ確立します。
> `Ctrl+C` でトンネルを終了できます。

---

## サービス操作

```bash
# 状態確認
ssh -i ~/.ssh/gogocoin root@<VPS_IP> "systemctl status gogocoin"

# 再起動
ssh -i ~/.ssh/gogocoin root@<VPS_IP> "systemctl restart gogocoin"

# 停止
ssh -i ~/.ssh/gogocoin root@<VPS_IP> "systemctl stop gogocoin"

# 起動
ssh -i ~/.ssh/gogocoin root@<VPS_IP> "systemctl start gogocoin"
```

---

## ログ確認

### systemd ジャーナル

```bash
# 直近 50 行
ssh -i ~/.ssh/gogocoin root@<VPS_IP> "journalctl -u gogocoin -n 50"

# リアルタイム追跡
ssh -i ~/.ssh/gogocoin root@<VPS_IP> "journalctl -u gogocoin -f"
```

### アプリログファイル

```bash
# 直近 100 行
ssh -i ~/.ssh/gogocoin root@<VPS_IP> "tail -n 100 /opt/gogocoin/logs/gogocoin.log"
```

---

## config.yaml の更新

ローカルから転送する場合:

```bash
make config CONOHA_HOST=<VPS_IP>
```

サーバー上で直接編集する場合:

```bash
ssh -i ~/.ssh/gogocoin root@<VPS_IP>
vim /opt/gogocoin/configs/config.yaml
systemctl restart gogocoin
```

---

## API キーのローテーション

`.env` はデプロイ時に GitHub Secrets から自動生成されるため、キーのローテーションは Secrets の更新と再デプロイのみで完了します。サーバーへの SSH は不要です。

1. リポジトリの Secrets 設定ページで `BITFLYER_API_KEY` / `BITFLYER_API_SECRET` を更新
2. Actions → Deploy → Run workflow で再デプロイ

---

## リソース確認

```bash
# メモリ使用量
ssh -i ~/.ssh/gogocoin root@<VPS_IP> "free -m"

# gogocoin プロセスのリソース
ssh -i ~/.ssh/gogocoin root@<VPS_IP> "ps aux | grep gogocoin"

# ディスク使用量
ssh -i ~/.ssh/gogocoin root@<VPS_IP> "df -h /opt/gogocoin && du -sh /opt/gogocoin/*"
```

---

## ログ・データのバックアップ

### VPS からローカルにダウンロードする

```bash
make backup CONOHA_HOST=<VPS_IP>
```

`./backup/<タイムスタンプ>/` 以下に保存されます:
- `logs/` ← gogocoin.log
- `data/` ← gogocoin.db
