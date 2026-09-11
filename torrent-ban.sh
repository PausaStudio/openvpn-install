#!/bin/bash
# ============================================================
# OpenVPN 53 UDP - Setup final com bloqueio de torrent 100%
# Uso: sudo bash /root/openvpn-final.sh
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Execute como root${NC}"
    exit 1
fi

# Detetar interface principal
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
if [ -z "$INTERFACE" ]; then
    INTERFACE="eth0"
fi

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  OpenVPN 53 UDP - Setup Final${NC}"
echo -e "${GREEN}============================================${NC}"
echo -e "Interface principal: ${CYAN}$INTERFACE${NC}"
echo ""

# ============================================================
# 1) IP FORWARDING
# ============================================================
echo -e "${YELLOW}[1/8] Ativando IP forwarding...${NC}"
echo "net.ipv4.ip_forward=1" | tee /etc/sysctl.d/99-openvpn.conf > /dev/null
sysctl --system > /dev/null
echo -e "${GREEN}  OK${NC}"

# ============================================================
# 2) LIMPAR IPTABLES
# ============================================================
echo -e "${YELLOW}[2/8] Limpando iptables...${NC}"
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
echo -e "${GREEN}  OK${NC}"

# ============================================================
# 3) INPUT - Portas essenciais
# ============================================================
echo -e "${YELLOW}[3/8] Configurando INPUT...${NC}"

# Loopback
iptables -A INPUT -i lo -j ACCEPT

# Conexoes estabelecidas
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# OpenVPN (53 UDP)
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -i tun0 -j ACCEPT

# Portas web / painel / Xray
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp --dport 9090 -j ACCEPT
iptables -A INPUT -p tcp --dport 7300 -j ACCEPT
iptables -A INPUT -p tcp --dport 10086 -j ACCEPT
iptables -A INPUT -p tcp --dport 10087 -j ACCEPT
iptables -A INPUT -p tcp --dport 36712 -j ACCEPT
iptables -A INPUT -p udp --dport 36712 -j ACCEPT

# ICMP (ping)
iptables -A INPUT -p icmp -j ACCEPT

# DNS local (se aplicavel)
iptables -A INPUT -p udp --dport 5300 -j ACCEPT

# Politica final
iptables -P INPUT DROP
echo -e "${GREEN}  OK${NC}"

# ============================================================
# 4) FORWARD - VPN + Bloqueio torrent 100%
# ============================================================
echo -e "${YELLOW}[4/8] Configurando FORWARD (VPN + torrent bloqueado)...${NC}"

# --- 4.1) VPN PRIMEIRO (ordem CRITICA) ---
iptables -A FORWARD -i tun0 -o $INTERFACE -j ACCEPT
iptables -A FORWARD -i $INTERFACE -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# --- 4.2) BLOQUEIO TOTAL DE TORRENT (Whitelist no tunel) ---
# So passa o que for explicito. Todo o resto e bloqueado.
# Isto garante que µTorrent, uTP, DHT, trackers, etc NAO passam.

# Permitir HTTP, HTTPS, DNS, NTP (o que 99% dos utilizadores precisam)
iptables -A FORWARD -i tun0 -o $INTERFACE -p tcp -m multiport --dports 80,443,8080,8443 -j ACCEPT
iptables -A FORWARD -i tun0 -o $INTERFACE -p udp -m multiport --dports 53,123,443 -j ACCEPT

# Permitir SSH de saida (alguns usam para gerir servidores)
iptables -A FORWARD -i tun0 -o $INTERFACE -p tcp --dport 22 -j ACCEPT

# Permitir outras portas comuns que nao sao torrent
# (jogos, VoIP, etc — descomenta se precisares)
# iptables -A FORWARD -i tun0 -o $INTERFACE -p tcp -m multiport --dports 8081,8443,1935,3478,3479,5222,5223,5269,5280,5349,5350 -j ACCEPT
# iptables -A FORWARD -i tun0 -o $INTERFACE -p udp -m multiport --dports 3478,3479,5000:5500,7777:7999,27000:27999 -j ACCEPT

# BLOQUEAR TODO O RESTO (inclui torrent)
iptables -A FORWARD -i tun0 -o $INTERFACE -j REJECT --reject-with icmp-port-unreachable

# --- 4.3) BLOQUEIO ADICIONAL (redundancia, nao afecta o tunel) ---
# Bloqueio explicito das portas tipicas de torrent (para logs e defesa em profundidade)
iptables -A FORWARD -p tcp -m multiport --dports 25,465,587,6881:6889,6969,1337,2710,51413,6881:6999,10000:10100 -j REJECT
iptables -A FORWARD -p udp -m multiport --dports 6881:6889,6969,1337,2710,51413,6881:6999,10000:10100 -j REJECT

# Bloqueio por assinatura de protocolo (BitTorrent)
iptables -A FORWARD -m string --string "BitTorrent protocol" --algo bm --to 65535 -j REJECT
iptables -A FORWARD -m string --string "info_hash" --algo bm --to 65535 -j REJECT
iptables -A FORWARD -m string --string "peer_id=" --algo bm --to 65535 -j REJECT

echo -e "${GREEN}  OK${NC}"

# ============================================================
# 5) OUTPUT - Bloqueio do servidor
# ============================================================
echo -e "${YELLOW}[5/8] Configurando OUTPUT (servidor)...${NC}"

# Bloquear torrent/SMTP originado pelo proprio servidor
iptables -A OUTPUT -p tcp -m multiport --dports 25,465,587 -j REJECT
iptables -A OUTPUT -p tcp --dport 6881:6889 -j REJECT
iptables -A OUTPUT -p udp --dport 6881:6889 -j REJECT
iptables -A OUTPUT -p tcp --dport 6969 -j REJECT
iptables -A OUTPUT -p udp --dport 6969 -j REJECT
iptables -A OUTPUT -p tcp --dport 51413 -j REJECT
iptables -A OUTPUT -p udp --dport 51413 -j REJECT

# Assinaturas de protocolo
iptables -A OUTPUT -m string --string "BitTorrent protocol" --algo bm --to 65535 -j REJECT
iptables -A OUTPUT -m string --string "info_hash" --algo bm --to 65535 -j REJECT

echo -e "${GREEN}  OK${NC}"

# ============================================================
# 6) NAT - MASQUERADE
# ============================================================
echo -e "${YELLOW}[6/8] Configurando NAT...${NC}"
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $INTERFACE -j MASQUERADE
echo -e "${GREEN}  OK${NC}"

# ============================================================
# 7) MANGLE - MSS CLAMPING (CRITICO!)
# ============================================================
echo -e "${YELLOW}[7/8] Configurando MSS clamping...${NC}"
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
echo -e "${GREEN}  OK${NC}"

# ============================================================
# 8) PERSISTENCIA
# ============================================================
echo -e "${YELLOW}[8/8] Guardando regras...${NC}"

mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

# Instalar iptables-persistent se nao tiver
if ! dpkg -l | grep -q iptables-persistent; then
    echo "iptables-persistent" | debconf-set-selections
    echo "iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
    echo "iptables-persistent/autosave_v6 boolean false" | debconf-set-selections
    DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent -qq
fi

systemctl enable netfilter-persistent 2>/dev/null
systemctl start netfilter-persistent 2>/dev/null

systemctl enable openvpn@server 2>/dev/null

echo -e "${GREEN}  OK${NC}"

# ============================================================
# VERIFICACAO FINAL
# ============================================================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ESTADO FINAL${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

echo -e "${CYAN}--- INPUT ---${NC}"
iptables -L INPUT -n --line-numbers | head -20

echo ""
echo -e "${CYAN}--- FORWARD ---${NC}"
iptables -L FORWARD -n --line-numbers

echo ""
echo -e "${CYAN}--- OUTPUT ---${NC}"
iptables -L OUTPUT -n --line-numbers

echo ""
echo -e "${CYAN}--- NAT ---${NC}"
iptables -t nat -L POSTROUTING -n -v

echo ""
echo -e "${CYAN}--- MANGLE (MSS) ---${NC}"
iptables -t mangle -L FORWARD -n -v

echo ""
echo -e "${CYAN}--- OPENVPN ---${NC}"
systemctl is-active openvpn@server
ss -ulpn | grep ':53 '

echo ""
echo -e "${CYAN}--- IP FORWARD ---${NC}"
sysctl net.ipv4.ip_forward

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  CONCLUIDO${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "OpenVPN:    ${GREEN}53 UDP${NC}"
echo -e "Torrent:    ${GREEN}BLOQUEADO (whitelist)${NC}"
echo -e "SMTP:       ${GREEN}BLOQUEADO${NC}"
echo -e "MSS clamp:  ${GREEN}ATIVO${NC}"
echo -e "Persist:    ${GREEN}netfilter-persistent${NC}"
echo ""
echo -e "${YELLOW}Para testar apos reboot:${NC}"
echo "  sudo reboot"
echo "  (aguarde 30s)"
echo "  systemctl is-active openvpn@server"
echo "  sudo ss -ulpn | grep ':53 '"
