#!/bin/bash

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 权限运行此脚本"
  exit
fi

# 更新系统并安装必要的工具
apt update && apt upgrade -y
apt install -y curl wget unzip

# 下载并安装 Hysteria
wget https://github.com/HyNetwork/hysteria/releases/download/v1.3.5/hysteria-linux-amd64
chmod +x hysteria-linux-amd64
mv hysteria-linux-amd64 /usr/local/bin/hysteria

# 生成自签名证书
openssl req -x509 -nodes -newkey rsa:4096 -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -days 365 -subj "/CN=example.com"

# 生成随机密码
PASSWORD=$(openssl rand -base64 16)

# 创建服务器配置文件
cat > /etc/hysteria/config.json <<EOF
{
  "listen": ":36712",
  "cert": "/etc/hysteria/server.crt",
  "key": "/etc/hysteria/server.key",
  "obfs": "$PASSWORD",
  "recv_window_conn": 107374182400,
  "recv_window_client": 13421772800
}
EOF

# 创建 systemd 服务
cat > /etc/systemd/system/hysteria.service <<EOF
[Unit]
Description=Hysteria Server
After=network.target

[Service]
ExecStart=/usr/local/bin/hysteria -c /etc/hysteria/config.json server
Restart=on-failure
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

# 启动 Hysteria 服务
systemctl daemon-reload
systemctl enable hysteria
systemctl start hysteria

# 输出客户端配置
echo "Hysteria 服务器已成功部署！"
echo "请使用以下配置连接到服务器："
echo "服务器地址: $(curl -s ifconfig.me)"
echo "端口: 36712"
echo "密码: $PASSWORD"
echo "证书: 自签名"
