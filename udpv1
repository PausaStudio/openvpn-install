#!/usr/bin/env bash
#
# Usa `install_udp.sh --help` para ver el uso.
#
# (c) 2024 Jerico
#

set -e

# Nombre de dominio
DOMAIN="requestlab-x.space"

# PROTOCOLO
PROTOCOL="udp"

# PUERTO UDP
UDP_PORT=":36712"

# OBFS
OBFS="jt"

# CONTRASEÑA
PASSWORD="jt"

# Rutas del script
SCRIPT_NAME="$(basename "$0")"
SCRIPT_ARGS=("$@")
EXECUTABLE_INSTALL_PATH="/usr/local/bin/hysteria"
SYSTEMD_SERVICES_DIR="/etc/systemd/system"
CONFIG_DIR="/etc/hysteria"
USER_DB="$CONFIG_DIR/udpusers.db"
REPO_URL="https://github.com/apernet/hysteria"
CONFIG_FILE="$CONFIG_DIR/config.json"
API_BASE_URL="https://api.github.com/repos/apernet/hysteria"
CURL_FLAGS=(-L -f -q --retry 5 --retry-delay 10 --retry-max-time 60)
PACKAGE_MANAGEMENT_INSTALL="${PACKAGE_MANAGEMENT_INSTALL:-}"
SYSTEMD_SERVICE="$SYSTEMD_SERVICES_DIR/hysteria-server.service"
mkdir -p "$CONFIG_DIR"
touch "$USER_DB"

# Otras configuraciones
OPERATING_SYSTEM=""
ARCHITECTURE=""
HYSTERIA_USER=""
HYSTERIA_HOME_DIR=""
VERSION=""
FORCE=""
LOCAL_FILE=""
FORCE_NO_ROOT=""
FORCE_NO_SYSTEMD=""

# Funciones utilitarias
tiene_comando() {
    local _comando=$1
    type -P "$_comando" > /dev/null 2>&1
}

curl() {
    command curl "${CURL_FLAGS[@]}" "$@"
}

mktemp() {
    command mktemp "$@" "hyservinst.XXXXXXXXXX"
}

tput() {
    if tiene_comando tput; then
        command tput "$@"
    fi
}

trojo() {
    tput setaf 1
}

tverde() {
    tput setaf 2
}

tamarillo() {
    tput setaf 3
}

tazul() {
    tput setaf 4
}

taoi() {
    tput setaf 6
}

tnegrita() {
    tput bold
}

treset() {
    tput sgr0
}

nota() {
    local _msg="$1"
    echo -e "$SCRIPT_NAME: $(tnegrita)nota: $_msg$(treset)"
}

advertencia() {
    local _msg="$1"
    echo -e "$SCRIPT_NAME: $(tamarillo)advertencia: $_msg$(treset)"
}

error() {
    local _msg="$1"
    echo -e "$SCRIPT_NAME: $(trojo)error: $_msg$(treset)"
}

mostrar_error_argumento_y_salir() {
    local _msg_error="$1"
    error "$_msg_error"
    echo "Usa \"$0 --help\" para ver el uso." >&2
    exit 22
}

instalar_contenido() {
    local _flags_install="$1"
    local _contenido="$2"
    local _destino="$3"

    local _tmpfile="$(mktemp)"

    echo -ne "Instalando $_destino ... "
    echo "$_contenido" > "$_tmpfile"
    if install "$_flags_install" "$_tmpfile" "$_destino"; then
        echo -e "ok"
    fi

    rm -f "$_tmpfile"
}

eliminar_archivo() {
    local _objetivo="$1"

    echo -ne "Eliminando $_objetivo ... "
    if rm "$_objetivo"; then
        echo -e "ok"
    fi
}

exec_sudo() {
    local _saved_ifs="$IFS"
    IFS=$'\n'
    local _env_preservado=(
        $(env | grep "^PACKAGE_MANAGEMENT_INSTALL=" || true)
        $(env | grep "^OPERATING_SYSTEM=" || true)
        $(env | grep "^ARCHITECTURE=" || true)
        $(env | grep "^HYSTERIA_\w*=" || true)
        $(env | grep "^FORCE_\w*=" || true)
    )
    IFS="$_saved_ifs"

    exec sudo env \
    "${_env_preservado[@]}" \
    "$@"
}

instalar_software() {
    local paquete="$1"
    if tiene_comando apt-get; then
        echo "Instalando $paquete con apt-get..."
        apt-get update && apt-get install -y "$paquete"
    elif tiene_comando dnf; then
        echo "Instalando $paquete con dnf..."
        dnf install -y "$paquete"
    elif tiene_comando yum; then
        echo "Instalando $paquete con yum..."
        yum install -y "$paquete"
    elif tiene_comando zypper; then
        echo "Instalando $paquete con zypper..."
        zypper install -y "$paquete"
    elif tiene_comando pacman; then
        echo "Instalando $paquete con pacman..."
        pacman -Sy --noconfirm "$paquete"
    else
        echo "Error: No se encontró un gestor de paquetes compatible. Instala $paquete manualmente."
        exit 1
    fi
}

usuario_existe() {
    local _usuario="$1"
    id "$_usuario" > /dev/null 2>&1
}

verificar_permiso() {
    if [[ "$UID" -eq '0' ]]; then
        return
    fi

    nota "El usuario que ejecuta este script no es root."

    case "$FORCE_NO_ROOT" in
        '1')
            advertencia "FORCE_NO_ROOT=1 especificado, continuamos sin root y podrías encontrar errores de privilegios."
            ;;
        *)
            if tiene_comando sudo; then
                nota "Re-ejecutando el script con sudo. También puedes especificar FORCE_NO_ROOT=1 para forzar ejecución con el usuario actual."
                exec_sudo "$0" "${SCRIPT_ARGS[@]}"
            else
                error "Ejecuta este script como root o especifica FORCE_NO_ROOT=1 para forzar ejecución con el usuario actual."
                exit 13
            fi
            ;;
    esac
}

verificar_sistema_operativo() {
    if [[ -n "$OPERATING_SYSTEM" ]]; then
        advertencia "OPERATING_SYSTEM=$OPERATING_SYSTEM especificado, se omite la detección del sistema operativo."
        return
    fi

    if [[ "x$(uname)" == "xLinux" ]]; then
        OPERATING_SYSTEM=linux
        return
    fi

    error "Este script solo soporta Linux."
    nota "Especifica OPERATING_SYSTEM=[linux|darwin|freebsd|windows] para omitir esta verificación."
    exit 95
}

verificar_arquitectura() {
    if [[ -n "$ARCHITECTURE" ]]; then
        advertencia "ARCHITECTURE=$ARCHITECTURE especificado, se omite la detección de arquitectura."
        return
    fi

    case "$(uname -m)" in
        'i386' | 'i686')
            ARCHITECTURE='386'
            ;;
        'amd64' | 'x86_64')
            ARCHITECTURE='amd64'
            ;;
        'armv5tel' | 'armv6l' | 'armv7' | 'armv7l')
            ARCHITECTURE='arm'
            ;;
        'armv8' | 'aarch64')
            ARCHITECTURE='arm64'
            ;;
        'mips' | 'mipsle' | 'mips64' | 'mips64le')
            ARCHITECTURE='mipsle'
            ;;
        's390x')
            ARCHITECTURE='s390x'
            ;;
        *)
            error "La arquitectura '$(uname -a)' no está soportada."
            nota "Especifica ARCHITECTURE=<arquitectura> para omitir esta verificación."
            exit 8
            ;;
    esac
}

verificar_systemd() {
    if [[ -d "/run/systemd/system" ]] || grep -q systemd <(ls -l /sbin/init); then
        return
    fi

    case "$FORCE_NO_SYSTEMD" in
        '1')
            advertencia "FORCE_NO_SYSTEMD=1 especificado, continuamos aunque systemd no fue detectado."
            ;;
        '2')
            advertencia "FORCE_NO_SYSTEMD=2 especificado, se omitirán todos los comandos relacionados con systemd."
            ;;
        *)
            error "Este script solo soporta distribuciones Linux con systemd."
            nota "Especifica FORCE_NO_SYSTEMD=1 para deshabilitar esta verificación."
            nota "Especifica FORCE_NO_SYSTEMD=2 para deshabilitar esta verificación y todos los comandos de systemd."
            ;;
    esac
}

parsear_argumentos() {
    while [[ "$#" -gt '0' ]]; do
        case "$1" in
            '--remove')
                if [[ -n "$OPERATION" && "$OPERATION" != 'remove' ]]; then
                    mostrar_error_argumento_y_salir "La opción '--remove' entra en conflicto con otras opciones."
                fi
                OPERATION='remove'
                ;;
            '--version')
                VERSION="$2"
                if [[ -z "$VERSION" ]]; then
                    mostrar_error_argumento_y_salir "Especifica la versión para la opción '--version'."
                fi
                shift
                if ! [[ "$VERSION" == v* ]]; then
                    mostrar_error_argumento_y_salir "Los números de versión deben comenzar con 'v' (ej: 'v1.3.1'), se obtuvo '$VERSION'"
                fi
                ;;
            '-h' | '--help')
                mostrar_uso_y_salir
                ;;
            '-l' | '--local')
                LOCAL_FILE="$2"
                if [[ -z "$LOCAL_FILE" ]]; then
                    mostrar_error_argumento_y_salir "Especifica el binario local a instalar para la opción '-l' o '--local'."
                fi
                break
                ;;
            *)
                mostrar_error_argumento_y_salir "Opción desconocida '$1'"
                ;;
        esac
        shift
    done

    if [[ -z "$OPERATION" ]]; then
        OPERATION='install'
    fi

    case "$OPERATION" in
        'install')
            if [[ -n "$VERSION" && -n "$LOCAL_FILE" ]]; then
                mostrar_error_argumento_y_salir '--version y --local no pueden especificarse juntos.'
            fi
            ;;
        *)
            if [[ -n "$VERSION" ]]; then
                mostrar_error_argumento_y_salir "--version solo está disponible al instalar."
            fi
            if [[ -n "$LOCAL_FILE" ]]; then
                mostrar_error_argumento_y_salir "--local solo está disponible al instalar."
            fi
            ;;
    esac
}

verificar_directorio_hysteria() {
    local _dir_por_defecto="$1"

    if [[ -n "$HYSTERIA_HOME_DIR" ]]; then
        return
    fi

    if ! usuario_existe "$HYSTERIA_USER"; then
        HYSTERIA_HOME_DIR="$_dir_por_defecto"
        return
    fi

    HYSTERIA_HOME_DIR="$(eval echo ~"$HYSTERIA_USER")"
}

descargar_hysteria() {
    local _version="$1"
    local _destino="$2"

    local _url_descarga="$REPO_URL/releases/download/v1.3.5/hysteria-$OPERATING_SYSTEM-$ARCHITECTURE"
    echo "Descargando hysteria: $_url_descarga ..."
    if ! curl -R -H 'Cache-Control: no-cache' "$_url_descarga" -o "$_destino"; then
        error "¡Descarga fallida! Verifica tu conexión e intenta de nuevo."
        return 11
    fi
    return 0
}

verificar_usuario_hysteria() {
    local _usuario_por_defecto="$1"

    if [[ -n "$HYSTERIA_USER" ]]; then
        return
    fi

    if [[ ! -e "$SYSTEMD_SERVICES_DIR/hysteria-server.service" ]]; then
        HYSTERIA_USER="$_usuario_por_defecto"
        return
    fi

    HYSTERIA_USER="$(grep -o '^User=\w*' "$SYSTEMD_SERVICES_DIR/hysteria-server.service" | tail -1 | cut -d '=' -f 2 || true)"

    if [[ -z "$HYSTERIA_USER" ]]; then
        HYSTERIA_USER="$_usuario_por_defecto"
    fi
}

verificar_curl() {
    if ! tiene_comando curl; then
        instalar_software "curl"
    fi
}

verificar_grep() {
    if ! tiene_comando grep; then
        instalar_software "grep"
    fi
}

verificar_sqlite3() {
    if ! tiene_comando sqlite3; then
        instalar_software "sqlite3"
    fi
}

verificar_pip() {
    if ! tiene_comando pip; then
        instalar_software "pip"
    fi
}

verificar_jq() {
    if ! tiene_comando jq; then
        instalar_software "jq"
    fi
}

verificar_entorno() {
    verificar_sistema_operativo
    verificar_arquitectura
    verificar_systemd
    verificar_curl
    verificar_grep
    verificar_pip
    verificar_sqlite3
    verificar_jq
}

mostrar_uso_y_salir() {
    echo
    echo -e "\t$(tnegrita)$SCRIPT_NAME$(treset) - Script de instalación del servidor JT-UDP"
    echo
    echo -e "Uso:"
    echo
    echo -e "$(tnegrita)Instalar JT-UDP$(treset)"
    echo -e "\t$0 [ -f | -l <archivo> | --version <versión> ]"
    echo -e "Opciones:"
    echo -e "\t-f, --force\tForza la reinstalación de la última versión aunque ya esté instalada."
    echo -e "\t-l, --local <archivo>\tInstala el binario JT-UDP especificado en lugar de descargarlo."
    echo -e "\t--version <versión>\tInstala la versión especificada en lugar de la más reciente."
    echo
    echo -e "$(tnegrita)Eliminar JT-UDP$(treset)"
    echo -e "\t$0 --remove"
    echo
    echo -e "$(tnegrita)Verificar actualización$(treset)"
    echo -e "\t$0 -c"
    echo -e "\t$0 --check"
    echo
    echo -e "$(tnegrita)Mostrar esta ayuda$(treset)"
    echo -e "\t$0 -h"
    echo -e "\t$0 --help"
    exit 0
}

tpl_servicio_hysteria_base() {
    local _nombre_config="$1"

    cat << EOF
[Unit]
Description=Servicio JT-UDP
After=network.target

[Service]
User=root
Group=root
WorkingDirectory=/etc/hysteria
Environment="PATH=/usr/local/bin/hysteria"
ExecStart=/usr/local/bin/hysteria server --config /etc/hysteria/config.json

[Install]
WantedBy=multi-user.target
EOF
}

tpl_servicio_hysteria() {
    tpl_servicio_hysteria_base 'config'
}

tpl_servicio_hysteria_x() {
    tpl_servicio_hysteria_base '%i'
}

obtener_usuarios() {
    DB_PATH="/etc/hysteria/udpusers.db"
    if [[ -f "$DB_PATH" ]]; then
        sqlite3 "$DB_PATH" "SELECT username || ':' || password FROM users;" | paste -sd, -
    fi
}

tpl_config_json_hysteria() {
    local_users=$(obtener_usuarios)

    mkdir -p "$CONFIG_DIR"

    cat << EOF > "$CONFIG_FILE"
{
  "server": "$DOMAIN",
  "listen": "$UDP_PORT",
  "protocol": "$PROTOCOL",
  "cert": "/etc/hysteria/hysteria.server.crt",
  "key": "/etc/hysteria/hysteria.server.key",
  "up": "100 Mbps",
  "up_mbps": 100,
  "down": "100 Mbps",
  "down_mbps": 100,
  "disable_udp": false,
  "insecure": true,
  "obfs": "$OBFS",
  "auth": {
    "mode": "passwords",
    "config": [
      "$(echo $local_users)"
    ]
  }
}
EOF
}

configurar_base_de_datos() {
    echo "Configurando base de datos"
    mkdir -p "$(dirname "$USER_DB")"

    if [[ ! -f "$USER_DB" ]]; then
        sqlite3 "$USER_DB" ".databases"
        if [[ $? -ne 0 ]]; then
            echo "Error: No se pudo crear la base de datos en $USER_DB"
            exit 1
        fi
    fi

    sqlite3 "$USER_DB" <<EOF
CREATE TABLE IF NOT EXISTS users (
    username TEXT PRIMARY KEY,
    password TEXT NOT NULL
);
EOF

    tabla_existe=$(sqlite3 "$USER_DB" "SELECT name FROM sqlite_master WHERE type='table' AND name='users';")
    if [[ "$tabla_existe" == "users" ]]; then
        echo "Base de datos configurada exitosamente. La tabla 'users' existe."

        usuario_defecto="default"
        contrasena_defecto="password"
        usuario_existe_db=$(sqlite3 "$USER_DB" "SELECT username FROM users WHERE username='$usuario_defecto';")

        if [[ -z "$usuario_existe_db" ]]; then
            sqlite3 "$USER_DB" "INSERT INTO users (username, password) VALUES ('$usuario_defecto', '$contrasena_defecto');"
            if [[ $? -eq 0 ]]; then
                echo "Usuario por defecto creado exitosamente."
            else
                echo "Error: No se pudo crear el usuario por defecto."
            fi
        else
            echo "El usuario por defecto ya existe."
        fi
    else
        echo "Error: La tabla 'users' no fue creada exitosamente."
        echo "Esquema actual de la base de datos:"
        sqlite3 "$USER_DB" ".schema"
        exit 1
    fi
}

instalar_binario_hysteria() {
    if [[ -n "$LOCAL_FILE" ]]; then
        nota "Instalación local: $LOCAL_FILE"

        echo -ne "Instalando ejecutable de hysteria ... "

        if install -Dm755 "$LOCAL_FILE" "$EXECUTABLE_INSTALL_PATH"; then
            echo "ok"
        else
            exit 2
        fi

        return
    fi

    local _tmpfile=$(mktemp)

    if ! descargar_hysteria "$VERSION" "$_tmpfile"; then
        rm -f "$_tmpfile"
        exit 11
    fi

    echo -ne "Instalando ejecutable de hysteria ... "

    if install -Dm755 "$_tmpfile" "$EXECUTABLE_INSTALL_PATH"; then
        echo "ok"
    else
        exit 13
    fi

    rm -f "$_tmpfile"
}

eliminar_binario_hysteria() {
    eliminar_archivo "$EXECUTABLE_INSTALL_PATH"
}

instalar_config_ejemplo_hysteria() {
    tpl_config_json_hysteria
}

instalar_systemd_hysteria() {
    if [[ "x$FORCE_NO_SYSTEMD" == "x2" ]]; then
        return
    fi

    instalar_contenido -Dm644 "$(tpl_servicio_hysteria)" "$SYSTEMD_SERVICES_DIR/hysteria-server.service"
    instalar_contenido -Dm644 "$(tpl_servicio_hysteria_x)" "$SYSTEMD_SERVICES_DIR/hysteria-server@.service"

    systemctl daemon-reload
}

eliminar_systemd_hysteria() {
    eliminar_archivo "$SYSTEMD_SERVICES_DIR/hysteria-server.service"
    eliminar_archivo "$SYSTEMD_SERVICES_DIR/hysteria-server@.service"

    systemctl daemon-reload
}

instalar_usuario_hysteria_legacy() {
    if ! usuario_existe "$HYSTERIA_USER"; then
        echo -ne "Creando usuario $HYSTERIA_USER ... "
        useradd -r -d "$HYSTERIA_HOME_DIR" -m "$HYSTERIA_USER"
        echo "ok"
    fi
}

instalar_script_gestor() {
    local _script_gestor="/usr/local/bin/menu.sh"
    local _enlace_simbolico="/usr/local/bin/udp"

    echo "Descargando script del gestor..."
    curl -o "$_script_gestor" "https://raw.githubusercontent.com/JotchuaDevz/JT-UDP-DEV/refs/heads/main/menu.sh"
    chmod +x "$_script_gestor"

    echo "Creando enlace simbólico para ejecutar el gestor con el comando 'udp'..."
    ln -sf "$_script_gestor" "$_enlace_simbolico"

    echo "Script del gestor instalado en $_script_gestor"
    echo "Ahora puedes ejecutar el gestor con el comando 'udp'."
}

hysteria_esta_instalada() {
    if [[ -f "$EXECUTABLE_INSTALL_PATH" || -h "$EXECUTABLE_INSTALL_PATH" ]]; then
        return 0
    fi
    return 1
}

obtener_servicios_activos() {
    if [[ "x$FORCE_NO_SYSTEMD" == "x2" ]]; then
        return
    fi

    systemctl list-units --state=active --plain --no-legend \
    | grep -o "hysteria-server@*[^\s]*.service" || true
}

reiniciar_servicios_activos() {
    if [[ "x$FORCE_NO_SYSTEMD" == "x2" ]]; then
        return
    fi

    echo "Reiniciando servicios activos ... "

    for servicio in $(obtener_servicios_activos); do
        echo -ne "Reiniciando $servicio ... "
        systemctl restart "$servicio"
        echo "listo"
    done
}

detener_servicios_activos() {
    if [[ "x$FORCE_NO_SYSTEMD" == "x2" ]]; then
        return
    fi

    echo "Deteniendo servicios activos ... "

    for servicio in $(obtener_servicios_activos); do
        echo -ne "Deteniendo $servicio ... "
        systemctl stop "$servicio"
        echo "listo"
    done
}

realizar_instalacion() {
    local _es_instalacion_nueva
    if ! hysteria_esta_instalada; then
        _es_instalacion_nueva=1
    fi

    instalar_binario_hysteria
    instalar_config_ejemplo_hysteria
    instalar_usuario_hysteria_legacy
    instalar_systemd_hysteria
    configurar_ssl
    iniciar_servicios
    instalar_script_gestor

    if [[ -n "$_es_instalacion_nueva" ]]; then
        echo
        echo -e "$(tnegrita)¡Felicitaciones! JT-UDP se instaló exitosamente en tu servidor.$(treset)"
        echo "Usa el comando 'udp' para acceder al gestor."
        echo
        echo
    else
        reiniciar_servicios_activos
        iniciar_servicios
        echo
        echo -e "$(tnegrita)JT-UDP se actualizó exitosamente a $VERSION.$(treset)"
        echo
    fi
}

realizar_eliminacion() {
    eliminar_binario_hysteria
    detener_servicios_activos
    eliminar_systemd_hysteria

    echo
    echo -e "$(tnegrita)¡Felicitaciones! JT-UDP se eliminó exitosamente de tu servidor.$(treset)"
    echo
    echo -e "Aún necesitas eliminar los archivos de configuración y certificados ACME manualmente con los siguientes comandos:"
    echo
    echo - e "Reiniciando VPS"
    reboot
    echo -e "\t$(trojo)rm -rf "$CONFIG_DIR"$(treset)"
    if [[ "x$HYSTERIA_USER" != "xroot" ]]; then
        echo -e "\t$(trojo)userdel -r "$HYSTERIA_USER"$(treset)"
    fi
    if [[ "x$FORCE_NO_SYSTEMD" != "x2" ]]; then
        echo
        echo -e "Es posible que también necesites deshabilitar los servicios systemd relacionados con los siguientes comandos:"
        echo
        echo -e "\t$(trojo)rm -f /etc/systemd/system/multi-user.target.wants/hysteria-server.service$(treset)"
        echo -e "\t$(trojo)rm -f /etc/systemd/system/multi-user.target.wants/hysteria-server@*.service$(treset)"
        echo -e "\t$(trojo)systemctl daemon-reload$(treset)"
    fi
    echo
}

configurar_ssl() {
    echo "Instalando certificados SSL"

    openssl genrsa -out /etc/hysteria/hysteria.ca.key 2048

    openssl req -new -x509 -days 3650 -key /etc/hysteria/hysteria.ca.key \
        -subj "/C=CN/ST=GD/L=SZ/O=Hysteria, Inc./CN=Hysteria Root CA" \
        -out /etc/hysteria/hysteria.ca.crt

    openssl req -newkey rsa:2048 -nodes -keyout /etc/hysteria/hysteria.server.key \
        -subj "/C=CN/ST=GD/L=SZ/O=Hysteria, Inc./CN=$DOMAIN" \
        -out /etc/hysteria/hysteria.server.csr

    openssl x509 -req \
        -extfile <(printf "subjectAltName=DNS:$DOMAIN,DNS:$DOMAIN") \
        -days 3650 \
        -in /etc/hysteria/hysteria.server.csr \
        -CA /etc/hysteria/hysteria.ca.crt \
        -CAkey /etc/hysteria/hysteria.ca.key \
        -CAcreateserial \
        -out /etc/hysteria/hysteria.server.crt
}

iniciar_servicios() {
    echo "Iniciando JT-UDP"
    apt update
    sudo debconf-set-selections <<< "iptables-persistent iptables-persistent/autosave_v4 boolean true"
    sudo debconf-set-selections <<< "iptables-persistent iptables-persistent/autosave_v6 boolean true"
    apt -y install iptables-persistent
    iptables -t nat -A PREROUTING -i $(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1) -p udp --dport 10000:65000 -j DNAT --to-destination $UDP_PORT
    ip6tables -t nat -A PREROUTING -i $(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1) -p udp --dport 10000:65000 -j DNAT --to-destination $UDP_PORT
    sysctl net.ipv4.conf.all.rp_filter=0
    sysctl net.ipv4.conf.$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1).rp_filter=0
    echo "net.ipv4.ip_forward = 1
    net.ipv4.conf.all.rp_filter=0
    net.ipv4.conf.$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1).rp_filter=0" > /etc/sysctl.conf
    sysctl -p
    sudo iptables-save > /etc/iptables/rules.v4
    sudo ip6tables-save > /etc/iptables/rules.v6
    systemctl enable hysteria-server.service
    systemctl start hysteria-server.service
}

principal() {
    parsear_argumentos "$@"
    verificar_permiso
    verificar_entorno
    verificar_usuario_hysteria "hysteria"
    verificar_directorio_hysteria "/var/lib/$HYSTERIA_USER"
    case "$OPERATION" in
        "install")
            configurar_base_de_datos
            realizar_instalacion
            ;;
        "remove")
            realizar_eliminacion
            ;;
        *)
            error "Operación desconocida '$OPERATION'."
            ;;
    esac
}

principal "$@"
