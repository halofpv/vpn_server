#!/bin/bash
# vpn_server_setup.sh
# Скрипт для автоматической установки и настройки full-tunnel IKEv2/IPsec VPN-сервера
# на Debian/Ubuntu.
# Внешний интерфейс – ens33. Измените его, если требуется.
# Не забудьте заменить "YourPreSharedKey" на ваш действительный общий ключ.

set -e

echo "Обновление системы и установка VPN-пакетов..."
apt update -y
apt install -y strongswan strongswan-pki libcharon-extra-plugins

echo "Резервное копирование старых конфигураций (если существуют)..."
[ -f /etc/ipsec.conf ] && cp /etc/ipsec.conf /etc/ipsec.conf.bak
[ -f /etc/ipsec.secrets ] && cp /etc/ipsec.secrets /etc/ipsec.secrets.bak

echo "Запись /etc/ipsec.conf..."
cat > /etc/ipsec.conf <<'EOF'
config setup
    charondebug="all"

conn test
    keyexchange=ikev2
    authby=secret
    ike=aes256-sha256-modp2048
    esp=aes256-sha256

    # Сервер слушает на всех интерфейсах
    left=0.0.0.0
    leftsubnet=0.0.0.0/0
    leftfirewall=yes

    # Клиент может подключаться с любого IP
    right=%any
    rightsourceip=10.10.10.0/24
    rightsubnet=0.0.0.0/0

    # Передача DNS-серверов клиенту
    modeconfig = push
    leftdns = 8.8.8.8,1.1.1.1

    auto=add
EOF

echo "Запись /etc/ipsec.secrets..."
cat > /etc/ipsec.secrets <<'EOF'
: PSK "YourPreSharedKey"
EOF

echo "Включение IP-форвардинга..."
if ! grep -q "^net.ipv4.ip_forward" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
fi
sysctl -p

echo "Настройка iptables NAT..."
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o ens33 -j MASQUERADE

echo "Перезапуск службы strongSwan..."
systemctl restart strongswan-starter
systemctl enable strongswan-starter

echo "VPN-сервер успешно настроен."
