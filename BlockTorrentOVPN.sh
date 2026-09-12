# 1) Ver a ordem atual
sudo iptables -L FORWARD -n -v --line-numbers

# 2) Remover a regra ACCEPT generica do tun0 (a que deixa passar tudo)
sudo iptables -D FORWARD -i tun0 -o eth0 -j ACCEPT

# 3) Adicionar whitelist no TOPO do FORWARD
sudo iptables -I FORWARD 1 -i tun0 -o eth0 -p tcp -m multiport --dports 80,443,8080,8443 -j ACCEPT
sudo iptables -I FORWARD 2 -i tun0 -o eth0 -p udp -m multiport --dports 53,123,443 -j ACCEPT
sudo iptables -I FORWARD 3 -i tun0 -o eth0 -p tcp --dport 22 -j ACCEPT

# 4) Bloquear TODO o resto do tunel
sudo iptables -A FORWARD -i tun0 -o eth0 -j REJECT --reject-with icmp-port-unreachable

# 5) Ver a ordem final
sudo iptables -L FORWARD -n -v --line-numbers

# 6) Guardar
sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
