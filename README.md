# My Docker Linux VM

Docker Composeだけで立ち上がるUbuntuデスクトップ環境。Macに近い操作感でSteamゲームも楽しめます！

## 必要なツール
- Docker Desktop: https://www.docker.com/products/docker-desktop/

## 使い方
1. このリポジトリをクローン: `git clone https://github.com/your-username/my-docker-linux-vm.git`
2. フォルダに移動: `cd my-docker-linux-vm`
3. 起動: `docker-compose up`
4. ブラウザで `http://localhost:6080` にアクセス。Ubuntuデスクトップが開きます。
5. Steam: デスクトップのターミナルで `steam` を実行。

## 注意
- GPUゲーム用にDocker Desktopの設定でGPU共有を有効化。
- 停止: `docker-compose down`
- 初回起動に時間がかかります。

質問があればIssueを！