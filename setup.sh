#!/bin/bash
# gogocoin VPS 初期セットアップスクリプト
# 前提: Ubuntu 24.04 LTS / root で実行
set -euo pipefail

INSTALL_DIR=/opt/gogocoin
SERVICE_USER=gogocoin
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== gogocoin セットアップ開始 ==="

# ── パッケージインストール ──────────────────────────────────────────────────
apt-get update -y
apt-get install -y libsqlite3-0 ufw curl

# ── サービスユーザー作成 ───────────────────────────────────────────────────
if ! id "$SERVICE_USER" &>/dev/null; then
  useradd -r -s /sbin/nologin -d "$INSTALL_DIR" "$SERVICE_USER"
  echo "ユーザー $SERVICE_USER を作成しました"
else
  echo "ユーザー $SERVICE_USER は既に存在します（スキップ）"
fi

# ── ディレクトリ作成 ───────────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR"/{data,logs,configs,web}
chown -R "$SERVICE_USER":"$SERVICE_USER" "$INSTALL_DIR"
chmod 750 "$INSTALL_DIR"
echo "ディレクトリ $INSTALL_DIR を作成しました"

# ── systemd ユニットファイルの配置 ─────────────────────────────────────────
cp "$SCRIPT_DIR/gogocoin.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable gogocoin
echo "systemd サービスを登録しました"

# ── UFW ファイアウォール設定（SSH のみ許可・8080 は外部非公開）────────────
ufw allow 22/tcp
ufw --force enable
echo "UFW: 22/tcp のみ許可（8080 は SSH トンネル経由でのみアクセス）"

# ── SSH パスワード認証を無効化（鍵認証のみ許可）──────────────────────────
# 実行前に SSH 鍵でログインできることを確認してください
# 無効化後はパスワードによる SSH ログインは一切できなくなります
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl reload ssh
echo "SSH: パスワード認証を無効化しました（鍵認証のみ許可）"

echo ""
echo "=== セットアップ完了 ==="
echo ""
echo "次のステップ:"
echo "  1. /opt/gogocoin/configs/config.yaml を配置:"
echo "     gogocoin リポジトリの configs/config.example.yaml を参考に編集"
echo ""
echo "  2. GitHub Secrets に登録して deploy.yml を実行:"
echo "     CONOHA_HOST / CONOHA_USER / CONOHA_SSH_KEY"
echo "     BITFLYER_API_KEY / BITFLYER_API_SECRET"
echo ""
echo "  3. WebUI アクセス（SSHトンネル）:"
echo "     ssh -L 8080:localhost:8080 -N root@<VPS_IP>"
echo "     → http://localhost:8080"
