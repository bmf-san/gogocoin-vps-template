# gogocoin-vps-template

gogocoin を VPS に systemd + GitHub Actions でデプロイするテンプレート

## 免責事項

**このテンプレートおよび gogocoin を使用した取引によって生じたいかなる損失・損害についても、作者は一切の責任を負いません。暗号通貨取引は高リスクであり、投資元本を失う可能性があります。自己責任においてご利用ください。**

## 構成

```
gogocoin-vps-template/
├── gogocoin.service              # systemd ユニットファイル
├── setup.sh                      # VPS 初回セットアップスクリプト
├── Makefile                      # setup / config / tunnel / backup コマンド
├── .github/
│   └── workflows/
│       └── deploy.yml            # GitHub Actions デプロイワークフロー
└── docs/
    ├── INITIAL_RUNBOOK.md        # 初回 VPS セットアップ手順
    └── RUNBOOK.md                # 日常運用手順
```

## 使い方

### 1. テンプレートからリポジトリを作成する

GitHub の「Use this template」ボタンから新しいリポジトリを作成します。

### 2. SSH 鍵を用意する

VPS への接続に使用する SSH 鍵を作成または用意し、`Makefile` の `SSH_KEY` 変数に合わせます:

```makefile
SSH_KEY ?= ~/.ssh/gogocoin  # ← 自分の鍵のパスに変更
```

### 3. VPS をセットアップする

詳細な手順は [docs/INITIAL_RUNBOOK.md](docs/INITIAL_RUNBOOK.md) を参照してください。

```bash
# VPS へのセットアップスクリプト転送・実行
make setup CONOHA_HOST=<VPS_IP>

# config.yaml の転送
make config CONOHA_HOST=<VPS_IP>
```

### 4. GitHub Secrets を登録する

| Secret 名 | 内容 |
|---|---|
| `CONOHA_HOST` | VPS の IP アドレス |
| `CONOHA_USER` | SSH ユーザー名（例: `root`） |
| `CONOHA_SSH_KEY` | SSH 秘密鍵（`cat ~/.ssh/gogocoin` の出力を丸ごとペースト） |
| `BITFLYER_API_KEY` | bitFlyer API キー |
| `BITFLYER_API_SECRET` | bitFlyer API シークレット |

### 5. 初回デプロイを実行する

Actions → Deploy → Run workflow でデプロイします。

### 6. WebUI にアクセスする

```bash
make tunnel CONOHA_HOST=<VPS_IP>
# → http://localhost:8080
```

## ドキュメント

| ドキュメント | 内容 |
|---|---|
| [INITIAL_RUNBOOK](docs/INITIAL_RUNBOOK.md) | 初回 VPS セットアップ〜初回デプロイまでの手順 |
| [RUNBOOK](docs/RUNBOOK.md) | デプロイ・WebUI アクセス・ログ確認などの日常運用手順 |

## 動作確認環境

- Ubuntu 24.04 LTS
- gogocoin v1.x（[bmf-san/gogocoin](https://github.com/bmf-san/gogocoin)）

## カスタム戦略について

gogocoin v1.x 以降、`pkg/strategy.Strategy` インターフェースを実装することで独自の取引戦略を差し込めます。
カスタム戦略を使用する場合は、gogocoin をフォークするのではなく、自分のリポジトリに `go.mod` で `github.com/bmf-san/gogocoin` を参照し、`engine.Run()` を呼び出す `cmd/gogocoin/main.go` を作成してください。
詳細は [gogocoin DESIGN_DOC.md §5](https://github.com/bmf-san/gogocoin/blob/main/docs/DESIGN_DOC.md) を参照してください。
