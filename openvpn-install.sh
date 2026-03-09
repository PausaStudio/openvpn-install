#!/bin/bash
# OpenVPN Installer - Versão com escolha de IP

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Variáveis
VPN_USER=""
VPN_PASS=""
VPN_PORT=""
VPN_PROTO=""
VPN_DNS1=""
VPN_DNS2=""
VPN_CIPHER=""
VPN_AUTH=""
VPN_CERT_DAYS=""
SERVER_IP=""
IP_VERSION=""

# Função erro
die() {
    echo -e "${RED}[ERRO] $1${NC}"
    exit 1
}

# Função para verificar se comando executou com sucesso
check_success() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ $1${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ $2${NC}"
    fi
}

# Verificar root
if [[ $EUID -ne 0 ]]; then
    die "Execute como root"
fi

clear
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}     OPENVPN INSTALLER v3.3${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""

# ========== USUÁRIO ==========
echo -e "${YELLOW}➤ CONFIGURAÇÃO DE USUÁRIO${NC}"
read -p "$(echo -e ${GREEN}"Nome do usuário: ${NC}")" VPN_USER
while [ -z "$VPN_USER" ]; do
    echo -e "${RED}Usuário não pode estar vazio!${NC}"
    read -p "$(echo -e ${GREEN}"Nome do usuário: ${NC}")" VPN_USER
done

# ========== SENHA ==========
echo -e "\n${YELLOW}➤ CONFIGURAÇÃO DE SENHA${NC}"
read -p "$(echo -e ${GREEN}"Senha: ${NC}")" VPN_PASS
while [ -z "$VPN_PASS" ]; do
    echo -e "${RED}Senha não pode estar vazia!${NC}"
    read -p "$(echo -e ${GREEN}"Senha: ${NC}")" VPN_PASS
done

# ========== TIPO DE IP ==========
echo -e "\n${YELLOW}➤ TIPO DE IP${NC}"
echo "  1) IPv4 (Recomendado - maior compatibilidade)"
echo "  2) IPv6 (Para redes que usam IPv6)"
read -p "Escolha [1]: " ip_opt
case $ip_opt in
    2) 
        IP_VERSION="ipv6"
        echo -e "${CYAN}  ✔ Usando IPv6${NC}"
        ;;
    *) 
        IP_VERSION="ipv4"
        echo -e "${CYAN}  ✔ Usando IPv4${NC}"
        ;;
esac

# ========== PROTOCOLO ==========
echo -e "\n${YELLOW}➤ PROTOCOLO${NC}"
echo "  1) UDP (Recomendado - mais rápido)"
echo "  2) TCP (Mais compatível)"
read -p "Escolha [1]: " proto_opt
case $proto_opt in
    2) VPN_PROTO="tcp" ;;
    *) VPN_PROTO="udp" ;;
esac
echo -e "${GREEN}  ✔ Protocolo: $VPN_PROTO${NC}"

# ========== PORTA ==========
echo -e "\n${YELLOW}➤ PORTA${NC}"
echo "  1) 53 (DNS - Recomendado)"
echo "  2) 443 (HTTPS)"
echo "  3) 1194 (OpenVPN padrão)"
echo "  4) 80 (HTTP)"
echo "  5) Personalizar"
read -p "Escolha [1]: " port_opt
case $port_opt in
    2) VPN_PORT="443" ;;
    3) VPN_PORT="1194" ;;
    4) VPN_PORT="80" ;;
    5) 
        read -p "Digite a porta: " custom_port
        VPN_PORT="$custom_port"
        ;;
    *) VPN_PORT="53" ;;
esac
echo -e "${GREEN}  ✔ Porta: $VPN_PORT${NC}"

# ========== DNS ==========
echo -e "\n${YELLOW}➤ DNS${NC}"
echo "  1) Google (8.8.8.8, 8.8.4.4) - Recomendado"
echo "  2) Cloudflare (1.1.1.1, 1.0.0.1)"
echo "  3) OpenDNS (208.67.222.222, 208.67.220.220)"
echo "  4) Quad9 (9.9.9.9, 149.112.112.112)"
echo "  5) Personalizar"
read -p "Escolha [1]: " dns_opt
case $dns_opt in
    2) 
        VPN_DNS1="1.1.1.1"
        VPN_DNS2="1.0.0.1"
        ;;
    3) 
        VPN_DNS1="208.67.222.222"
        VPN_DNS2="208.67.220.220"
        ;;
    4) 
        VPN_DNS1="9.9.9.9"
        VPN_DNS2="149.112.112.112"
        ;;
    5)
        read -p "DNS Primário: " VPN_DNS1
        read -p "DNS Secundário: " VPN_DNS2
        ;;
    *) 
        VPN_DNS1="8.8.8.8"
        VPN_DNS2="8.8.4.4"
        ;;
esac
echo -e "${GREEN}  ✔ DNS: $VPN_DNS1, $VPN_DNS2${NC}"

# ========== CIFRA ==========
echo -e "\n${YELLOW}➤ CIFRA DE CRIPTOGRAFIA${NC}"
echo "  1) AES-128-CBC (Rápida, compatível) - Recomendado"
echo "  2) AES-256-CBC (Mais segura, um pouco mais lenta)"
echo "  3) AES-128-GCM (Moderna, autenticada)"
echo "  4) AES-256-GCM (Mais segura, moderna)"
read -p "Escolha [1]: " cipher_opt
case $cipher_opt in
    2) VPN_CIPHER="AES-256-CBC" ;;
    3) VPN_CIPHER="AES-128-GCM" ;;
    4) VPN_CIPHER="AES-256-GCM" ;;
    *) VPN_CIPHER="AES-128-CBC" ;;
esac
echo -e "${GREEN}  ✔ Cifra: $VPN_CIPHER${NC}"

# ========== AUTENTICAÇÃO ==========
echo -e "\n${YELLOW}➤ AUTENTICAÇÃO${NC}"
echo "  1) SHA256 (Recomendado - bom equilíbrio)"
echo "  2) SHA1 (Compatível, mas mais fraco)"
echo "  3) SHA512 (Mais seguro, um pouco mais lento)"
read -p "Escolha [1]: " auth_opt
case $auth_opt in
    2) VPN_AUTH="SHA1" ;;
    3) VPN_AUTH="SHA512" ;;
    *) VPN_AUTH="SHA256" ;;
esac
echo -e "${GREEN}  ✔ Auth: $VPN_AUTH${NC}"

# ========== VALIDADE ==========
echo -e "\n${YELLOW}➤ VALIDADE DO CERTIFICADO${NC}"
echo "  1) 30 dias"
echo "  2) 90 dias"
echo "  3) 180 dias"
echo "  4) 365 dias (Recomendado)"
echo "  5) 730 dias (2 anos)"
echo "  6) Personalizar"
read -p "Escolha [4]: " days_opt
case $days_opt in
    1) VPN_CERT_DAYS="30" ;;
    2) VPN_CERT_DAYS="90" ;;
    3) VPN_CERT_DAYS="180" ;;
    5) VPN_CERT_DAYS="730" ;;
    6)
        read -p "Dias: " custom_days
        VPN_CERT_DAYS="$custom_days"
        ;;
    *) VPN_CERT_DAYS="365" ;;
esac
echo -e "${GREEN}  ✔ Validade: $VPN_CERT_DAYS dias${NC}"

# ========== RESUMO ==========
echo -e "\n${BLUE}════════════════════════════════════════${NC}"
echo -e "${YELLOW}RESUMO DAS CONFIGURAÇÕES${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "Tipo IP:     ${CYAN}$IP_VERSION${NC}"
echo -e "Usuário:     ${GREEN}$VPN_USER${NC}"
echo -e "Protocolo:   ${GREEN}$VPN_PROTO${NC}"
echo -e "Porta:       ${GREEN}$VPN_PORT${NC}"
echo -e "DNS:         ${GREEN}$VPN_DNS1, $VPN_DNS2${NC}"
echo -e "Cifra:       ${GREEN}$VPN_CIPHER${NC}"
echo -e "Auth:        ${GREEN}$VPN_AUTH${NC}"
echo -e "Validade:    ${GREEN}$VPN_CERT_DAYS dias${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
read -p "Confirmar instalação? (s/N): " confirm
[[ ! "$confirm" =~ ^[Ss]$ ]] && die "Instalação cancelada"

# ========== VERIFICAR LOCK DO APT ==========
echo -e "\n${YELLOW}Verificando apt...${NC}"
rm -f /var/lib/dpkg/lock-frontend
rm -f /var/lib/dpkg/lock
rm -f /var/cache/apt/archives/lock
dpkg --configure -a

# ========== INSTALAÇÃO ==========
echo -e "\n${YELLOW}Instalando OpenVPN...${NC}"

# DNS do sistema
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

# Atualizar e instalar
apt-get update -qq
check_success "Falha ao atualizar repositórios" "Repositórios atualizados"

apt-get install -y openvpn easy-rsa curl iptables-persistent -qq
check_success "Falha ao instalar pacotes" "Pacotes instalados"

# ========== EASY-RSA CORRIGIDO ==========
echo -e "\n${YELLOW}Configurando certificados...${NC}"

# Limpar instalações anteriores
rm -rf /etc/openvpn/easy-rsa
rm -rf /etc/openvpn/client

# Criar diretórios
mkdir -p /etc/openvpn/easy-rsa
mkdir -p /etc/openvpn/client

# Copiar easy-rsa
cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/ 2>/dev/null || cp -r /usr/share/doc/easy-rsa/examples/* /etc/openvpn/easy-rsa/ 2>/dev/null

# Verificar se easy-rsa foi copiado
if [ ! -f "/etc/openvpn/easy-rsa/easyrsa" ]; then
    # Tentar método alternativo
    cd /etc/openvpn
    wget -q https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz
    tar xzf EasyRSA-3.0.8.tgz
    mv EasyRSA-3.0.8/* easy-rsa/
    rm -rf EasyRSA-3.0.8 EasyRSA-3.0.8.tgz
fi

cd /etc/openvpn/easy-rsa

# Inicializar PKI
./easyrsa init-pki <<< "yes" > /dev/null 2>&1
check_success "Falha ao iniciar PKI" "PKI iniciado"

# Construir CA
./easyrsa build-ca nopass <<< "yes" > /dev/null 2>&1
check_success "Falha ao construir CA" "CA construída"

# Gerar DH
./easyrsa gen-dh > /dev/null 2>&1 &
echo -n "Gerando DH (pode levar alguns segundos)... "
wait
echo -e "${GREEN}OK${NC}"

# Gerar certificado do servidor
./easyrsa build-server-full server nopass <<< "yes" > /dev/null 2>&1
check_success "Falha ao gerar certificado do servidor" "Certificado do servidor gerado"

# Gerar certificado do cliente
./easyrsa build-client-full cliente1 nopass <<< "yes" > /dev/null 2>&1
check_success "Falha ao gerar certificado do cliente" "Certificado do cliente gerado"

# ========== VERIFICAR ARQUIVOS ==========
echo -e "\n${YELLOW}Verificando certificados...${NC}"
if [ ! -f "/etc/openvpn/easy-rsa/pki/ca.crt" ]; then
    die "ca.crt não foi gerado"
fi
if [ ! -f "/etc/openvpn/easy-rsa/pki/dh.pem" ]; then
    die "dh.pem não foi gerado"
fi
if [ ! -f "/etc/openvpn/easy-rsa/pki/issued/server.crt" ]; then
    die "server.crt não foi gerado"
fi
if [ ! -f "/etc/openvpn/easy-rsa/pki/private/server.key" ]; then
    die "server.key não foi gerado"
fi
echo -e "${GREEN}✅ Todos os certificados foram gerados com sucesso${NC}"

# ========== SCRIPT DE AUTENTICAÇÃO ==========
echo -e "\n${YELLOW}Criando script de autenticação...${NC}"
cat > /etc/openvpn/auth.sh <<'EOF'
#!/bin/bash
PASSFILE="/etc/openvpn/psw-file"
username=$(head -1 "$1")
password=$(tail -1 "$1")
grep -q "^$username:$password$" $PASSFILE && exit 0 || exit 1
EOF
chmod +x /etc/openvpn/auth.sh

# Arquivo de usuários
echo "$VPN_USER:$VPN_PASS" > /etc/openvpn/psw-file
chmod 600 /etc/openvpn/psw-file

# ========== IP DO SERVIDOR (ESCOLHIDO PELO USUÁRIO) ==========
echo -e "\n${YELLOW}Obtendo IP do servidor ($IP_VERSION)...${NC}"

if [ "$IP_VERSION" = "ipv4" ]; then
    # Forçar IPv4
    SERVER_IP=$(curl -4 ifconfig.me 2>/dev/null)
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP=$(curl -4 icanhazip.com 2>/dev/null)
    fi
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
    fi
    echo -e "${GREEN}✅ IP IPv4: $SERVER_IP${NC}"
else
    # IPv6
    SERVER_IP=$(curl -6 ifconfig.me 2>/dev/null)
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP=$(curl -6 icanhazip.com 2>/dev/null)
    fi
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP=$(ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-f:]+' | grep -v '^::1' | grep -v '^fe80' | head -1)
    fi
    # Adicionar colchetes para IPv6 no remote
    SERVER_IP="[$SERVER_IP]"
    echo -e "${GREEN}✅ IP IPv6: $SERVER_IP${NC}"
fi

if [ -z "$SERVER_IP" ]; then
    die "Não foi possível obter o IP do servidor"
fi

# ========== CONFIGURAÇÃO DO SERVIDOR ==========
echo -e "\n${YELLOW}Configurando servidor OpenVPN...${NC}"
cat > /etc/openvpn/server.conf <<EOF
port $VPN_PORT
proto $VPN_PROTO
dev tun
ca /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
key /etc/openvpn/easy-rsa/pki/private/server.key
dh /etc/openvpn/easy-rsa/pki/dh.pem
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1"
push "dhcp-option DNS $VPN_DNS1"
push "dhcp-option DNS $VPN_DNS2"
keepalive 10 120
cipher $VPN_CIPHER
auth $VPN_AUTH
persist-key
persist-tun
verb 3
script-security 3
auth-user-pass-verify /etc/openvpn/auth.sh via-file
verify-client-cert none
username-as-common-name
EOF
echo -e "${GREEN}✅ Servidor configurado${NC}"

# ========== FIREWALL ==========
echo -e "\n${YELLOW}Configurando firewall...${NC}"
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p > /dev/null 2>&1

if [ "$IP_VERSION" = "ipv6" ]; then
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
    sysctl -p > /dev/null 2>&1
fi

INTERFACE=$(ip route | grep default | awk '{print $5}')
if [ -z "$INTERFACE" ]; then
    INTERFACE="eth0"
fi

iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $INTERFACE -j MASQUERADE
iptables -A INPUT -p $VPN_PROTO --dport $VPN_PORT -j ACCEPT
iptables-save > /etc/iptables/rules.v4

if [ "$IP_VERSION" = "ipv6" ]; then
    ip6tables -A INPUT -p $VPN_PROTO --dport $VPN_PORT -j ACCEPT
    ip6tables-save > /etc/iptables/rules.v6
fi

echo -e "${GREEN}✅ Firewall configurado (interface: $INTERFACE)${NC}"

# ========== ARQUIVO .OVPN ==========
echo -e "\n${YELLOW}Gerando arquivo .ovpn para cliente...${NC}"
cat > /root/$VPN_USER.ovpn <<EOF
client
dev tun
proto $VPN_PROTO
remote $SERVER_IP $VPN_PORT
remote $SERVER_IP $VPN_PORT
dhcp-option DNS $VPN_DNS1
cipher $VPN_CIPHER
auth $VPN_AUTH
resolv-retry infinite
nobind
persist-key
persist-tun
verb 3
auth-user-pass
route-delay 2
redirect-gateway
fast-io

<ca>
$(cat /etc/openvpn/easy-rsa/pki/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/easy-rsa/pki/issued/cliente1.crt)
</cert>
<key>
$(cat /etc/openvpn/easy-rsa/pki/private/cliente1.key)
</key>
EOF
echo -e "${GREEN}✅ Arquivo /root/$VPN_USER.ovpn gerado${NC}"

# ========== INICIAR SERVIÇO ==========
echo -e "\n${YELLOW}Iniciando OpenVPN na porta $VPN_PORT/$VPN_PROTO...${NC}"

# Liberar porta
fuser -k $VPN_PORT/$VPN_PROTO 2>/dev/null

# Iniciar serviço
systemctl enable openvpn@server > /dev/null 2>&1
systemctl restart openvpn@server
sleep 3

# Verificar status
if systemctl is-active --quiet openvpn@server; then
    echo -e "\n${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ OPENVPN INSTALADO COM SUCESSO!${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "Tipo IP:     ${CYAN}$IP_VERSION${NC}"
    echo -e "Usuário:     ${YELLOW}$VPN_USER${NC}"
    echo -e "Senha:       ${YELLOW}$VPN_PASS${NC}"
    echo -e "Servidor:    ${YELLOW}$SERVER_IP:$VPN_PORT/$VPN_PROTO${NC}"
    echo -e "Arquivo:     ${YELLOW}/root/$VPN_USER.ovpn${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    echo -e "Para adicionar mais usuários:"
    echo -e "  echo 'usuario:senha' >> /etc/openvpn/psw-file"
    echo ""
    echo -e "Para ver logs:"
    echo -e "  tail -f /var/log/syslog | grep ovpn"
else
    echo -e "\n${RED}❌ FALHA AO INICIAR OPENVPN${NC}"
    echo -e "${YELLOW}Verificando erro...${NC}"
    journalctl -u openvpn@server --no-pager -n 10
fi
