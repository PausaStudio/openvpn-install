#!/bin/bash
# OpenVPN Manager - Script profissional com instalacao e gerenciamento

# Cores profissionais
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# Variaveis
SCRIPT_NAME="OpenVPN Manager v4.0"
CONFIG_FILE="/etc/openvpn/server.conf"
PSW_FILE="/etc/openvpn/psw-file"
OVPN_DIR="/root"
LOG_FILE="/var/log/openvpn-manager.log"
SELF_SCRIPT="$0"
INSTALL_FLAG="/etc/openvpn/.installed"

# Variaveis de configuracao
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

# Funcao para log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

# Funcao erro
die() {
    echo -e "${RED}[ERRO] $1${NC}"
    exit 1
}

# Funcao para verificar se ja esta instalado
is_installed() {
    if [ -f "$INSTALL_FLAG" ] && [ -f "$CONFIG_FILE" ]; then
        return 0
    else
        return 1
    fi
}

# Funcao para verificar status do servico
check_service() {
    if systemctl is-active --quiet openvpn@server 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# ==================== FUNCOES DE INSTALACAO ====================

# Funcao para preencher configuracoes
setup_configuration() {
    clear
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}     OPENVPN INSTALLER v4.0${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""

    # Usuario
    echo -e "${YELLOW}> CONFIGURACAO DE USUARIO${NC}"
    read -p "$(echo -e ${GREEN}"Nome do usuario: ${NC}")" VPN_USER
    while [ -z "$VPN_USER" ]; do
        echo -e "${RED}Usuario nao pode estar vazio!${NC}"
        read -p "$(echo -e ${GREEN}"Nome do usuario: ${NC}")" VPN_USER
    done

    # Senha
    echo -e "\n${YELLOW}> CONFIGURACAO DE SENHA${NC}"
    read -s -p "$(echo -e ${GREEN}"Senha: ${NC}")" VPN_PASS
    echo
    while [ -z "$VPN_PASS" ]; do
        echo -e "${RED}Senha nao pode estar vazia!${NC}"
        read -s -p "$(echo -e ${GREEN}"Senha: ${NC}")" VPN_PASS
        echo
    done

    # Tipo de IP
    echo -e "\n${YELLOW}> TIPO DE IP${NC}"
    echo "  1) IPv4 (Recomendado - maior compatibilidade)"
    echo "  2) IPv6 (Para redes que usam IPv6)"
    read -p "Escolha [1]: " ip_opt
    case $ip_opt in
        2) 
            IP_VERSION="ipv6"
            echo -e "${CYAN}  Usando IPv6${NC}"
            ;;
        *) 
            IP_VERSION="ipv4"
            echo -e "${CYAN}  Usando IPv4${NC}"
            ;;
    esac

    # Protocolo
    echo -e "\n${YELLOW}> PROTOCOLO${NC}"
    echo "  1) UDP (Recomendado - mais rapido)"
    echo "  2) TCP (Mais compativel)"
    read -p "Escolha [1]: " proto_opt
    case $proto_opt in
        2) VPN_PROTO="tcp" ;;
        *) VPN_PROTO="udp" ;;
    esac
    echo -e "${GREEN}  Protocolo: $VPN_PROTO${NC}"

    # Porta
    echo -e "\n${YELLOW}> PORTA${NC}"
    echo "  1) 53 (DNS - Recomendado)"
    echo "  2) 443 (HTTPS)"
    echo "  3) 1194 (OpenVPN padrao)"
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
    echo -e "${GREEN}  Porta: $VPN_PORT${NC}"

    # DNS
    echo -e "\n${YELLOW}> DNS${NC}"
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
            read -p "DNS Primario: " VPN_DNS1
            read -p "DNS Secundario: " VPN_DNS2
            ;;
        *) 
            VPN_DNS1="8.8.8.8"
            VPN_DNS2="8.8.4.4"
            ;;
    esac
    echo -e "${GREEN}  DNS: $VPN_DNS1, $VPN_DNS2${NC}"

    # Cifra
    echo -e "\n${YELLOW}> CIFRA DE CRIPTOGRAFIA${NC}"
    echo "  1) AES-128-CBC (Rapida, compativel) - Recomendado"
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
    echo -e "${GREEN}  Cifra: $VPN_CIPHER${NC}"

    # Autenticacao
    echo -e "\n${YELLOW}> AUTENTICACAO${NC}"
    echo "  1) SHA256 (Recomendado - bom equilibrio)"
    echo "  2) SHA1 (Compativel, mas mais fraco)"
    echo "  3) SHA512 (Mais seguro, um pouco mais lento)"
    read -p "Escolha [1]: " auth_opt
    case $auth_opt in
        2) VPN_AUTH="SHA1" ;;
        3) VPN_AUTH="SHA512" ;;
        *) VPN_AUTH="SHA256" ;;
    esac
    echo -e "${GREEN}  Auth: $VPN_AUTH${NC}"

    # Validade
    echo -e "\n${YELLOW}> VALIDADE DO CERTIFICADO${NC}"
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
    echo -e "${GREEN}  Validade: $VPN_CERT_DAYS dias${NC}"

    # Resumo
    echo -e "\n${BLUE}════════════════════════════════════════${NC}"
    echo -e "${YELLOW}RESUMO DAS CONFIGURACOES${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "Tipo IP:     ${CYAN}$IP_VERSION${NC}"
    echo -e "Usuario:     ${GREEN}$VPN_USER${NC}"
    echo -e "Protocolo:   ${GREEN}$VPN_PROTO${NC}"
    echo -e "Porta:       ${GREEN}$VPN_PORT${NC}"
    echo -e "DNS:         ${GREEN}$VPN_DNS1, $VPN_DNS2${NC}"
    echo -e "Cifra:       ${GREEN}$VPN_CIPHER${NC}"
    echo -e "Auth:        ${GREEN}$VPN_AUTH${NC}"
    echo -e "Validade:    ${GREEN}$VPN_CERT_DAYS dias${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    read -p "Confirmar instalacao? (s/N): " confirm
    [[ ! "$confirm" =~ ^[Ss]$ ]] && die "Instalacao cancelada"
}

# Funcao para instalar OpenVPN
install_openvpn() {
    setup_configuration
    
    echo -e "\n${YELLOW}Instalando OpenVPN...${NC}"
    
    # DNS do sistema
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf
    
    # Verificar lock do apt
    rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock 2>/dev/null
    dpkg --configure -a 2>/dev/null
    
    # Atualizar e instalar
    apt-get update -qq
    apt-get install -y openvpn easy-rsa curl iptables-persistent -qq
    
    # Configurar easy-rsa
    echo -e "\n${YELLOW}Configurando certificados...${NC}"
    rm -rf /etc/openvpn/easy-rsa
    mkdir -p /etc/openvpn/easy-rsa
    
    cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/ 2>/dev/null || \
    wget -q -O /tmp/easyrsa.tgz https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz && \
    tar xzf /tmp/easyrsa.tgz -C /etc/openvpn/ && \
    mv /etc/openvpn/EasyRSA-3.0.8/* /etc/openvpn/easy-rsa/ && \
    rm -rf /tmp/easyrsa.tgz
    
    cd /etc/openvpn/easy-rsa
    ./easyrsa init-pki <<< "yes" > /dev/null 2>&1
    ./easyrsa build-ca nopass <<< "yes" > /dev/null 2>&1
    ./easyrsa gen-dh > /dev/null 2>&1 &
    wait
    ./easyrsa build-server-full server nopass <<< "yes" > /dev/null 2>&1
    ./easyrsa build-client-full cliente1 nopass <<< "yes" > /dev/null 2>&1
    
    # Script de autenticacao
    cat > /etc/openvpn/auth.sh <<'EOF'
#!/bin/bash
PASSFILE="/etc/openvpn/psw-file"
username=$(head -1 "$1")
password=$(tail -1 "$1")
grep -q "^$username:$password$" $PASSFILE && exit 0 || exit 1
EOF
    chmod +x /etc/openvpn/auth.sh
    
    # Arquivo de usuarios
    echo "$VPN_USER:$VPN_PASS" > /etc/openvpn/psw-file
    chmod 600 /etc/openvpn/psw-file
    
    # Obter IP do servidor
    if [ "$IP_VERSION" = "ipv4" ]; then
        SERVER_IP=$(curl -4 ifconfig.me 2>/dev/null)
        [ -z "$SERVER_IP" ] && SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
    else
        SERVER_IP=$(curl -6 ifconfig.me 2>/dev/null)
        [ -z "$SERVER_IP" ] && SERVER_IP=$(ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-f:]+' | grep -v '^::1' | grep -v '^fe80' | head -1)
        SERVER_IP="[$SERVER_IP]"
    fi
    
    # Configuracao do servidor
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
    
    # Firewall
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p > /dev/null 2>&1
    
    INTERFACE=$(ip route | grep default | awk '{print $5}')
    [ -z "$INTERFACE" ] && INTERFACE="eth0"
    
    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $INTERFACE -j MASQUERADE
    iptables -A INPUT -p $VPN_PROTO --dport $VPN_PORT -j ACCEPT
    iptables-save > /etc/iptables/rules.v4
    
    # Gerar arquivo .ovpn
    cat > /root/$VPN_USER.ovpn <<EOF
client
dev tun
proto $VPN_PROTO
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
    
    # Iniciar servico
    systemctl enable openvpn@server > /dev/null 2>&1
    systemctl restart openvpn@server
    sleep 3
    
    # Criar flag de instalacao
    touch "$INSTALL_FLAG"
    
    if systemctl is-active --quiet openvpn@server; then
        echo -e "\n${GREEN}════════════════════════════════════════${NC}"
        echo -e "${GREEN}[OK] OPENVPN INSTALADO COM SUCESSO!${NC}"
        echo -e "${GREEN}════════════════════════════════════════${NC}"
        echo -e "Tipo IP:     ${CYAN}$IP_VERSION${NC}"
        echo -e "Usuario:     ${YELLOW}$VPN_USER${NC}"
        echo -e "Senha:       ${YELLOW}$VPN_PASS${NC}"
        echo -e "Servidor:    ${YELLOW}$SERVER_IP:$VPN_PORT/$VPN_PROTO${NC}"
        echo -e "Arquivo:     ${YELLOW}/root/$VPN_USER.ovpn${NC}"
        echo -e "${GREEN}════════════════════════════════════════${NC}"
        echo ""
        log "OpenVPN instalado com sucesso - Porta: $VPN_PORT/$VPN_PROTO"
    else
        echo -e "\n${RED}[ERRO] FALHA AO INICIAR OPENVPN${NC}"
        journalctl -u openvpn@server --no-pager -n 10
        exit 1
    fi
}

# ==================== FUNCOES DE GERENCIAMENTO ====================

# Funcao para remover COMPLETAMENTE o OpenVPN
full_uninstall() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${WHITE}REMOVER OPENVPN COMPLETAMENTE${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${RED}[ATENCAO] Isso removera TODA a instalacao do OpenVPN${NC}"
    echo -e "${YELLOW}   - Parar servico OpenVPN${NC}"
    echo -e "${YELLOW}   - Remover todos os pacotes${NC}"
    echo -e "${YELLOW}   - Apagar arquivos de configuracao${NC}"
    echo -e "${YELLOW}   - Remover certificados${NC}"
    echo -e "${YELLOW}   - Apagar usuarios e senhas${NC}"
    echo -e "${YELLOW}   - Remover regras de firewall${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    
    read -p "$(echo -e ${RED}"Digite 'REMOVER' para confirmar: ${NC}")" confirm
    
    if [ "$confirm" != "REMOVER" ]; then
        echo -e "${YELLOW}Remocao cancelada${NC}"
        return 1
    fi
    
    echo -e "\n${YELLOW}Removendo OpenVPN...${NC}"
    
    # Parar servico
    systemctl stop openvpn@server 2>/dev/null
    systemctl disable openvpn@server 2>/dev/null
    
    # Remover pacotes
    apt-get remove --purge -y openvpn easy-rsa 2>/dev/null
    apt-get autoremove -y 2>/dev/null
    
    # Remover arquivos de configuracao
    rm -rf /etc/openvpn
    rm -rf /var/log/openvpn*
    rm -f /etc/iptables/rules.v4 2>/dev/null
    rm -f /etc/iptables/rules.v6 2>/dev/null
    
    # Remover arquivos .ovpn
    rm -f /root/*.ovpn 2>/dev/null
    
    # Remover flag de instalacao
    rm -f "$INSTALL_FLAG" 2>/dev/null
    
    # Limpar regras de firewall
    iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o $(ip route | grep default | awk '{print $5}') -j MASQUERADE 2>/dev/null
    iptables-save > /etc/iptables/rules.v4 2>/dev/null
    
    # Remover configuracoes de sysctl
    sed -i '/net.ipv4.ip_forward=1/d' /etc/sysctl.conf 2>/dev/null
    
    echo -e "${GREEN}[OK] OpenVPN foi completamente removido do sistema${NC}"
    log "OpenVPN completamente desinstalado"
    echo ""
    echo -e "${YELLOW}O script de gerenciamento ainda esta disponivel${NC}"
    echo -e "${YELLOW}Execute 'ovpn' novamente para reinstalar${NC}"
    
    # Perguntar se quer remover o script tambem
    read -p "$(echo -e ${YELLOW}"Deseja remover este script de gerenciamento tambem? (s/N): ${NC}")" remove_script
    if [[ "$remove_script" =~ ^[Ss]$ ]]; then
        rm -f "$SELF_SCRIPT"
        echo -e "${GREEN}[OK] Script removido${NC}"
        exit 0
    fi
    
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
}

# Funcao para exibir status do servico
show_status() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${WHITE}STATUS DO SERVICO${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    
    if check_service; then
        echo -e "${GREEN}[OK] OpenVPN: ONLINE${NC}"
        echo -e "${CYAN}   PID: $(pidof openvpn 2>/dev/null || echo 'N/A')${NC}"
        
        PORT=$(grep "^port" $CONFIG_FILE 2>/dev/null | awk '{print $2}')
        PROTO=$(grep "^proto" $CONFIG_FILE 2>/dev/null | awk '{print $2}')
        echo -e "${CYAN}   Porta: $PORT/$PROTO${NC}"
        
        UPTIME=$(ps -p $(pidof openvpn 2>/dev/null) -o etime= 2>/dev/null | xargs)
        [ -n "$UPTIME" ] && echo -e "${CYAN}   Uptime: $UPTIME${NC}"
    else
        echo -e "${RED}[ERRO] OpenVPN: OFFLINE${NC}"
    fi
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
}

# Funcao para ver logs do sistema
view_logs() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${WHITE}LOGS DO SISTEMA${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${CYAN}1) Logs do OpenVPN (tempo real)${NC}"
    echo -e "${CYAN}2) Logs do OpenVPN (ultimas 50 linhas)${NC}"
    echo -e "${CYAN}3) Logs de autenticacao${NC}"
    echo -e "${CYAN}4) Logs do firewall${NC}"
    echo -e "${CYAN}5) Logs do gerenciador${NC}"
    echo -e "${CYAN}6) Voltar${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    
    read -p "Opcao: " log_opt
    
    case $log_opt in
        1)
            echo -e "${YELLOW}Logs em tempo real (Ctrl+C para sair):${NC}"
            journalctl -u openvpn@server -f
            ;;
        2)
            echo -e "${YELLOW}Ultimas 50 linhas:${NC}"
            journalctl -u openvpn@server -n 50 --no-pager
            ;;
        3)
            echo -e "${YELLOW}Logs de autenticacao:${NC}"
            grep -i "auth\|user\|password" /var/log/syslog | grep openvpn | tail -20
            ;;
        4)
            echo -e "${YELLOW}Regras do firewall:${NC}"
            iptables -L -n -v | head -30
            ;;
        5)
            if [ -f "$LOG_FILE" ]; then
                echo -e "${YELLOW}Logs do gerenciador:${NC}"
                tail -30 "$LOG_FILE"
            else
                echo -e "${RED}Nenhum log do gerenciador encontrado${NC}"
            fi
            ;;
        6)
            return
            ;;
        *)
            echo -e "${RED}Opcao invalida${NC}"
            ;;
    esac
    echo ""
}

# Funcao para listar usuarios
list_users() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${WHITE}USUARIOS CADASTRADOS${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    
    if [ -f "$PSW_FILE" ] && [ -s "$PSW_FILE" ]; then
        echo -e "${CYAN}Usuario: Senha${NC}"
        echo -e "${YELLOW}------------------------------------------------${NC}"
        while IFS=':' read -r user pass; do
            echo -e "${GREEN}> $user${NC} : ${WHITE}$pass${NC}"
        done < "$PSW_FILE"
        
        TOTAL=$(wc -l < "$PSW_FILE")
        echo -e "${YELLOW}------------------------------------------------${NC}"
        echo -e "${CYAN}Total: $TOTAL usuario(s)${NC}"
    else
        echo -e "${RED}[ERRO] Nenhum usuario cadastrado${NC}"
    fi
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
}

# Funcao para adicionar usuario
add_user() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${WHITE}ADICIONAR NOVO USUARIO${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    
    read -p "$(echo -e ${GREEN}"Nome do usuario: ${NC}")" NEW_USER
    if [ -z "$NEW_USER" ]; then
        echo -e "${RED}[ERRO] Nome nao pode estar vazio!${NC}"
        return 1
    fi
    
    if grep -q "^$NEW_USER:" "$PSW_FILE"; then
        echo -e "${RED}[ERRO] Usuario '$NEW_USER' ja existe!${NC}"
        return 1
    fi
    
    read -s -p "$(echo -e ${GREEN}"Senha: ${NC}")" NEW_PASS
    echo
    read -s -p "$(echo -e ${GREEN}"Confirmar senha: ${NC}")" NEW_PASS2
    echo
    
    if [ "$NEW_PASS" != "$NEW_PASS2" ]; then
        echo -e "${RED}[ERRO] Senhas nao conferem!${NC}"
        return 1
    fi
    
    if [ -z "$NEW_PASS" ]; then
        echo -e "${RED}[ERRO] Senha nao pode estar vazia!${NC}"
        return 1
    fi
    
    echo "$NEW_USER:$NEW_PASS" >> "$PSW_FILE"
    log "Novo usuario adicionado: $NEW_USER"
    
    echo -e "\n${GREEN}[OK] Usuario '$NEW_USER' adicionado com sucesso!${NC}"
    
    read -p "$(echo -e ${YELLOW}"Deseja gerar certificado .ovpn para este usuario? (s/N): ${NC}")" gen_cert
    if [[ "$gen_cert" =~ ^[Ss]$ ]]; then
        generate_user_cert "$NEW_USER"
    fi
    
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
}

# Funcao para remover usuario
remove_user() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${WHITE}REMOVER USUARIO${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    
    if [ ! -f "$PSW_FILE" ]; then
        echo -e "${RED}[ERRO] Nenhum usuario cadastrado${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Usuarios disponiveis:${NC}"
    nl -w2 -s') ' "$PSW_FILE" | cut -d':' -f1
    
    read -p "$(echo -e ${GREEN}"Numero ou nome do usuario: ${NC}")" USER_DEL
    
    if [[ "$USER_DEL" =~ ^[0-9]+$ ]]; then
        USER_DEL=$(sed -n "${USER_DEL}p" "$PSW_FILE" | cut -d':' -f1)
    fi
    
    if [ -z "$USER_DEL" ]; then
        echo -e "${RED}[ERRO] Usuario nao encontrado${NC}"
        return 1
    fi
    
    read -p "$(echo -e ${RED}"Remover '$USER_DEL'? (s/N): ${NC}")" confirm
    if [[ "$confirm" =~ ^[Ss]$ ]]; then
        sed -i "/^$USER_DEL:/d" "$PSW_FILE"
        log "Usuario removido: $USER_DEL"
        echo -e "${GREEN}[OK] Usuario '$USER_DEL' removido${NC}"
        
        [ -f "$OVPN_DIR/$USER_DEL.ovpn" ] && rm -f "$OVPN_DIR/$USER_DEL.ovpn"
    fi
    
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
}

# Funcao para gerar certificado para usuario especifico
generate_user_cert() {
    local username=$1
    
    cd /etc/openvpn/easy-rsa
    
    ./easyrsa build-client-full "$username" nopass <<< "yes" > /dev/null 2>&1
    
    if [ -f "pki/issued/$username.crt" ]; then
        SERVER_IP=$(grep "^remote" "$OVPN_DIR/cliente1.ovpn" 2>/dev/null | head -1 | awk '{print $2}')
        PORT=$(grep "^port" $CONFIG_FILE | awk '{print $2}')
        PROTO=$(grep "^proto" $CONFIG_FILE | awk '{print $2}')
        CIPHER=$(grep "^cipher" $CONFIG_FILE | awk '{print $2}')
        AUTH=$(grep "^auth" $CONFIG_FILE | awk '{print $2}')
        DNS=$(grep "dhcp-option DNS" "$OVPN_DIR/cliente1.ovpn" 2>/dev/null | head -1 | awk '{print $3}')
        
        cat > "$OVPN_DIR/$username.ovpn" <<EOF
client
dev tun
proto $PROTO
remote $SERVER_IP $PORT
dhcp-option DNS $DNS
cipher $CIPHER
auth $AUTH
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
$(cat /etc/openvpn/easy-rsa/pki/issued/$username.crt)
</cert>
<key>
$(cat /etc/openvpn/easy-rsa/pki/private/$username.key)
</key>
EOF
        echo -e "${GREEN}[OK] Certificado gerado: /root/$username.ovpn${NC}"
        log "Certificado gerado para: $username"
    else
        echo -e "${RED}[ERRO] Falha ao gerar certificado para $username${NC}"
    fi
}

# Funcao para gerar certificado
generate_cert_with_pass() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${WHITE}GERAR CERTIFICADO .OVPN${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    
    read -p "$(echo -e ${GREEN}"Nome do usuario: ${NC}")" CERT_USER
    
    if [ -z "$CERT_USER" ]; then
        echo -e "${RED}[ERRO] Nome invalido${NC}"
        return 1
    fi
    
    generate_user_cert "$CERT_USER"
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
}

# Funcao para controlar servico
control_service() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${WHITE}CONTROLE DO SERVICO${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "  ${GREEN}1)${NC} Iniciar OpenVPN"
    echo -e "  ${YELLOW}2)${NC} Parar OpenVPN"
    echo -e "  ${BLUE}3)${NC} Reiniciar OpenVPN"
    echo -e "  ${RED}4)${NC} Voltar"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    
    read -p "Opcao: " service_opt
    
    case $service_opt in
        1)
            echo -e "${YELLOW}Iniciando OpenVPN...${NC}"
            systemctl start openvpn@server
            sleep 2
            if check_service; then
                echo -e "${GREEN}[OK] OpenVPN iniciado com sucesso!${NC}"
                log "Servico iniciado manualmente"
            else
                echo -e "${RED}[ERRO] Falha ao iniciar${NC}"
            fi
            ;;
        2)
            echo -e "${YELLOW}Parando OpenVPN...${NC}"
            systemctl stop openvpn@server
            sleep 1
            echo -e "${GREEN}[OK] OpenVPN parado${NC}"
            log "Servico parado manualmente"
            ;;
        3)
            echo -e "${YELLOW}Reiniciando OpenVPN...${NC}"
            systemctl restart openvpn@server
            sleep 2
            if check_service; then
                echo -e "${GREEN}[OK] OpenVPN reiniciado com sucesso!${NC}"
                log "Servico reiniciado manualmente"
            else
                echo -e "${RED}[ERRO] Falha ao reiniciar${NC}"
            fi
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}[ERRO] Opcao invalida${NC}"
            ;;
    esac
    echo ""
}

# Funcao para verificar configuracao
check_config() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${WHITE}VERIFICAR CONFIGURACAO${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    
    echo -e "${CYAN}Arquivos importantes:${NC}"
    [ -f "$CONFIG_FILE" ] && echo -e "${GREEN}[OK] $CONFIG_FILE${NC}" || echo -e "${RED}[ERRO] $CONFIG_FILE${NC}"
    [ -f "$PSW_FILE" ] && echo -e "${GREEN}[OK] $PSW_FILE${NC}" || echo -e "${RED}[ERRO] $PSW_FILE${NC}"
    [ -f "/etc/openvpn/easy-rsa/pki/ca.crt" ] && echo -e "${GREEN}[OK] CA Certificate${NC}" || echo -e "${RED}[ERRO] CA Certificate${NC}"
    
    echo -e "\n${CYAN}Configuracoes atuais:${NC}"
    echo -e "${YELLOW}Porta:${NC} $(grep "^port" $CONFIG_FILE 2>/dev/null | awk '{print $2}')"
    echo -e "${YELLOW}Protocolo:${NC} $(grep "^proto" $CONFIG_FILE 2>/dev/null | awk '{print $2}')"
    echo -e "${YELLOW}Cifra:${NC} $(grep "^cipher" $CONFIG_FILE 2>/dev/null | awk '{print $2}')"
    echo -e "${YELLOW}Auth:${NC} $(grep "^auth" $CONFIG_FILE 2>/dev/null | awk '{print $2}')"
    
    echo -e "\n${CYAN}Firewall:${NC}"
    PORT_ACTUAL=$(grep "^port" $CONFIG_FILE 2>/dev/null | awk '{print $2}')
    iptables -L INPUT -n | grep -q "dpt:$PORT_ACTUAL" && echo -e "${GREEN}[OK] Porta liberada no firewall${NC}" || echo -e "${RED}[AVISO] Porta pode estar bloqueada${NC}"
    
    echo -e "\n${CYAN}Arquivos .ovpn disponiveis:${NC}"
    ls -lh /root/*.ovpn 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}' || echo -e "${RED}  Nenhum arquivo .ovpn encontrado${NC}"
    
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
}

# Funcao para backup
backup_config() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${WHITE}BACKUP DA CONFIGURACAO${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    
    BACKUP_DIR="/root/openvpn-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    cp -r /etc/openvpn "$BACKUP_DIR/"
    cp -r /root/*.ovpn "$BACKUP_DIR/" 2>/dev/null
    
    echo -e "${GREEN}[OK] Backup criado em: $BACKUP_DIR${NC}"
    log "Backup criado: $BACKUP_DIR"
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
}

# Funcao para mostrar ajuda
show_help() {
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}MANUAL DO OPENVPN MANAGER${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Comandos disponiveis:${NC}"
    echo -e "  ${YELLOW}ovpn${NC}              - Inicia o menu interativo"
    echo -e "  ${YELLOW}ovpn status${NC}       - Mostra status do servico"
    echo -e "  ${YELLOW}ovpn users${NC}        - Lista todos os usuarios"
    echo -e "  ${YELLOW}ovpn add${NC}          - Adiciona novo usuario"
    echo -e "  ${YELLOW}ovpn start${NC}        - Inicia o OpenVPN"
    echo -e "  ${YELLOW}ovpn stop${NC}         - Para o OpenVPN"
    echo -e "  ${YELLOW}ovpn restart${NC}      - Reinicia o OpenVPN"
    echo -e "  ${YELLOW}ovpn logs${NC}         - Mostra logs do sistema"
    echo -e "  ${YELLOW}ovpn backup${NC}       - Faz backup da configuracao"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}\n"
}

# Funcao do menu principal (quando ja instalado)
show_menu() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       OpenVPN Manager v4.0             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    if check_service; then
        echo -e " ${GREEN}[ONLINE]${NC} Servico: ${GREEN}ATIVO${NC}  |  Porta: $(grep "^port" $CONFIG_FILE 2>/dev/null | awk '{print $2}')"
    else
        echo -e " ${RED}[OFFLINE]${NC} Servico: ${RED}PARADO${NC}"
    fi
    echo -e " ${CYAN}>${NC} Usuarios: $(wc -l < $PSW_FILE 2>/dev/null || echo 0)"
    echo ""
    
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${WHITE}       MENU PRINCIPAL${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e " ${GREEN}1)${NC} Status do Servico"
    echo -e " ${GREEN}2)${NC} Listar Usuarios"
    echo -e " ${GREEN}3)${NC} Adicionar Usuario"
    echo -e " ${GREEN}4)${NC} Remover Usuario"
    echo -e " ${GREEN}5)${NC} Gerar Certificado .ovpn"
    echo -e " ${GREEN}6)${NC} Controle do Servico"
    echo -e " ${GREEN}7)${NC} Verificar Configuracao"
    echo -e " ${GREEN}8)${NC} Ver Logs"
    echo -e " ${GREEN}9)${NC} Backup"
    echo -e " ${GREEN}10)${NC} Ajuda"
    echo -e " ${RED}11)${NC} Remover COMPLETAMENTE OpenVPN"
    echo -e " ${RED}0)${NC} Sair"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
}

# ==================== MAIN ====================
# Verificar root
if [[ $EUID -ne 0 ]]; then
    die "Execute como root"
fi

# Processar argumentos de linha de comando
case "$1" in
    status)
        if is_installed; then show_status; else echo "OpenVPN nao instalado. Execute 'ovpn' para instalar."; fi
        ;;
    users|list)
        if is_installed; then list_users; else echo "OpenVPN nao instalado. Execute 'ovpn' para instalar."; fi
        ;;
    add)
        if is_installed; then add_user; else echo "OpenVPN nao instalado. Execute 'ovpn' para instalar."; fi
        ;;
    start)
        if is_installed; then systemctl start openvpn@server && echo "[OK] OpenVPN iniciado"; else echo "OpenVPN nao instalado"; fi
        ;;
    stop)
        if is_installed; then systemctl stop openvpn@server && echo "[OK] OpenVPN parado"; else echo "OpenVPN nao instalado"; fi
        ;;
    restart)
        if is_installed; then systemctl restart openvpn@server && echo "[OK] OpenVPN reiniciado"; else echo "OpenVPN nao instalado"; fi
        ;;
    logs)
        if is_installed; then view_logs; else echo "OpenVPN nao instalado. Execute 'ovpn' para instalar."; fi
        ;;
    backup)
        if is_installed; then backup_config; else echo "OpenVPN nao instalado. Execute 'ovpn' para instalar."; fi
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        # Verificar se ja esta instalado
        if is_installed; then
            # Modo gerenciamento
            while true; do
                show_menu
                read -p "$(echo -e ${CYAN}"Escolha uma opcao [0-11]: ${NC}")" choice
                
                case $choice in
                    1) show_status ;;
                    2) list_users ;;
                    3) add_user ;;
                    4) remove_user ;;
                    5) generate_cert_with_pass ;;
                    6) control_service ;;
                    7) check_config ;;
                    8) view_logs ;;
                    9) backup_config ;;
                    10) show_help ;;
                    11) full_uninstall ;;
                    0) 
                        echo -e "${GREEN}Ate logo!${NC}"
                        exit 0
                        ;;
                    *)
                        echo -e "${RED}[ERRO] Opcao invalida!${NC}"
                        sleep 1
                        ;;
                esac
                
                if [[ "$choice" != "0" ]]; then
                    echo -e "\n${YELLOW}Pressione ENTER para continuar...${NC}"
                    read
                fi
            done
        else
            # Modo instalacao (primeira execucao)
            install_openvpn
        fi
        ;;
esac
