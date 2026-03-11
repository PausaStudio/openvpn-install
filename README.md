# OpenVPN Professional Installer

Instalador profissional do OpenVPN com autenticação por usuário/senha.

## 📋 Características

- ✅ Autenticação por usuário/senha (não precisa de certificados)
- ✅ Escolha entre UDP/TCP
- ✅ Portas: 53, 443, 1194, 80 ou personalizada
- ✅ DNS: Google, Cloudflare, OpenDNS, Quad9 ou personalizado
- ✅ Cifras: AES-128/256-CBC/GCM
- ✅ Autenticação: SHA1, SHA256, SHA512
- ✅ Validade do certificado configurável
- ✅ Escolha entre IPv4 ou IPv6
- ✅ Interface amigável com menus
- ✅ Firewall configurado automaticamente
- ✅ Gera arquivo .ovpn pronto para uso

## 🚀 Como usar

```bash
# Baixar o script
wget https://raw.githubusercontent.com/PausaStudio/openvpn-installer/main/openvpn-install.sh

# Dar permissão
chmod +x openvpn-install.sh

# Executar como root
sudo ./openvpn-install.sh
