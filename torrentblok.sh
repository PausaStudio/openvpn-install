#!/bin/bash
# ============================================================
# Bloqueio de Torrent - Script Independente
# Nao toca no OpenVPN, NAT ou IP forwarding
# Uso: sudo bash /root/bloquear-torrent.sh
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

INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
if [ -z "$INTERFACE" ]; then
    INTERFACE="eth0"
fi

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Bloqueio de Torrent (independente)${NC}"
echo -e "${GREEN}============================================${NC}"
echo -e "Interface principal: ${CYAN}$INTERFACE${NC}"
echo ""

# ============================================================
# 1) LIMPAR REGRAS ANTIGAS DE TORRENT
# ============================================================
echo -e "${YELLOW}[1/4] Limpando regras antigas...${NC}"

# Remover regras antigas do FORWARD (do tunel)
while iptables -D FORWARD -i tun0 -o $INTERFACE -p tcp -m multiport --dports 80,443,8080,8443 -j ACCEPT 2>/dev/null; do :; done
while iptables -D FORWARD -i tun0 -o $INTERFACE -p udp -m multiport --dports 53,123,443 -j ACCEPT 2>/dev/null; do :; done
while iptables -D FORWARD -i tun0 -o $INTERFACE -p tcp --dport 22 -j ACCEPT 2>/dev/null; do :; done
while iptables -D FORWARD -i tun0 -o $INTERFACE -j REJECT --reject-with icmp-port-unreachable 2>/dev/null; do :; done

# Remover regras antigas de torrent/SMTP
while iptables -D FORWARD -p tcp -m multiport --dports 25,465,587,6881:6889,6969,1337,2710,51413 -j REJECT 2>/dev/null; do :; done
while iptables -D FORWARD -p udp -m multiport --dports 6881:6889,6969,1337,2710,51413 -j REJECT 2>/dev/null; do :; done
while iptables -D FORWARD -m string --string "BitTorrent protocol" --algo bm --to 65535 -j REJECT 2>/dev/null; do :; done
while iptables -D FORWARD -m string --string "info_hash" --algo bm --to 65535 -j REJECT 2>/dev/null; do :; done
while iptables -D FORWARD -m string --string "peer_id=" --algo bm --to 65535 -j REJECT 2>/dev/null; do :; done

# Remover do OUTPUT
while iptables -D OUTPUT -p tcp -m multiport --dports 25,465,587 -j REJECT 2>/dev/null; do :; done
while iptables -D OUTPUT -p tcp --dport 6881:6889 -j REJECT 2>/dev/null; do :; done
while iptables -D OUTPUT -p udp --dport 6881:6889 -j REJECT 2>/dev/null; do :; done
while iptables -D OUTPUT -p tcp --dport 6969 -j REJECT 2>/dev/null; do :; done
while iptables -D OUTPUT -p udp --dport 6969 -j REJECT 2>/dev/null; do :; done
while iptables -D OUTPUT -p tcp --dport 51413 -j REJECT 2>/dev/null; do :; done
while iptables -D OUTPUT -p udp --dport 51413 -j REJECT 2>/dev/null; do :; done
while iptables -D OUTPUT -m string --string "BitTorrent protocol" --algo bm --to 65535 -j REJECT 2>/dev/null; do :; done
while iptables -D OUTPUT -m string --string "info_hash" --algo bm --to 65535 -j REJECT 2>/dev/null; do :; done

echo -e "${GREEN}  OK${NC}"

# ============================================================
# 2) APLICAR BLOQUEIO NO FORWARD (clientes VPN)
# ============================================================
echo -e "${YELLOW}[2/4] Bloqueando torrent no FORWARD (clientes VPN)...${NC}"

# --- 2.1) Whitelist PRIMEIRO (navegacao basica) ---
iptables -I FORWARD 1 -i tun0 -o $INTERFACE -p tcp -m multiport --dports 80,443,8080,8443 -j ACCEPT
iptables -I FORWARD 2 -i tun0 -o $INTERFACE -p udp -m multiport --dports 53,123,443 -j ACCEPT
iptables -I FORWARD 3 -i tun0 -o $INTERFACE -p tcp --dport 22 -j ACCEPT

# --- 2.2) Retorno ---
iptables -I FORWARD 4 -i $INTERFACE -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# --- 2.3) Bloquear TUDO o resto do tunel (torrent incluido) ---
iptables -A FORWARD -i tun0 -o $INTERFACE -j REJECT --reject-with icmp-port-unreachable

# --- 2.4) Defesa em profundidade ---
iptables -A FORWARD -p tcp -m multiport --dports 25,465,587,6881:6889,6969,1337,2710,51413 -j REJECT
iptables -A FORWARD -p udp -m multiport --dports 6881:6889,6969,1337,2710,51413 -j REJECT
iptables -A FORWARD -m string --string "BitTorrent protocol" --algo bm --to 65535 -j REJECT
iptables -A FORWARD -m string --string "info_hash" --algo bm --to 65535 -j REJECT
iptables -A FORWARD -m string --string "peer_id=" --algo bm --to 65535 -j REJECT

echo -e "${GREEN}  OK${NC}"

# ============================================================
# 3) APLICAR BLOQUEIO NO OUTPUT (servidor)
# ============================================================
echo -e "${YELLOW}[3/4] Bloqueando torrent no OUTPUT (servidor)...${NC}"

iptables -A OUTPUT -p tcp -m multiport --dports 25,465,587 -j REJECT
iptables -A OUTPUT -p tcp --dport 6881:6889 -j REJECT
iptables -A OUTPUT -p udp --dport 6881:6889 -j REJECT
iptables -A OUTPUT -p tcp --dport 6969 -j REJECT
iptables -A OUTPUT -p udp --dport 6969 -j REJECT
iptables -A OUTPUT -p tcp --dport 51413 -j REJECT
iptables -A OUTPUT -p udp --dport 51413 -j REJECT
iptables -A OUTPUT -m string --string "BitTorrent protocol" --algo bm --to 65535 -j REJECT
iptables -A OUTPUT -m string --string "info_hash" --algo bm --to 65535 -j REJECT

echo -e "${GREEN}  OK${NC}"

# ============================================================
# 4) GUARDAR
# ============================================================
echo -e "${YELLOW}[4/4] Guardando regras...${NC}"

mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4
netfilter-persistent save 2>/dev/null || true

echo -e "${GREEN}  OK${NC}"

# ============================================================
# ESTADO FINAL
# ============================================================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ESTADO FINAL${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

echo -e "${CYAN}--- FORWARD (ordem) ---${NC}"
iptables -L FORWARD -n -v --line-numbers

echo ""
echo -e "${CYAN}--- OUTPUT (bloqueios) ---${NC}"
iptables -L OUTPUT -n -v --line-numbers

echo ""
echo -e "${CYAN}--- NAT (nao foi tocado) ---${NC}"
iptables -t nat -L POSTROUTING -n -v

echo ""
echo -e "${CYAN}--- MANGLE (nao foi tocado) ---${NC}"
iptables -t mangle -L FORWARD -n -v

echo ""
echo -e "${CYAN}--- OPENVPN (nao foi tocado) ---${NC}"
systemctl is-active openvpn@server
ss -ulpn | grep ':53 '

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  CONCLUIDO${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "Torrent:      ${GREEN}BLOQUEADO${NC}"
echo -e "OpenVPN:      ${GREEN}intacto${NC}"
echo -e "NAT:          ${GREEN}intacto${NC}"
echo -e "MSS clamp:    ${GREEN}intacto${NC}"
echo ""
echo -e "${YELLOW}Portas permitidas aos clientes VPN:${NC}"
echo -e "  TCP: 80, 443, 8080, 8443, 22"
echo -e "  UDP: 53, 123, 443"
echo ""
