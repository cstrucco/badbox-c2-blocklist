# BADBOX 2.0 / Vo1d / Kimwolf -- IPs de servidores de control (C2)
# 26 IPs -- 2026-08-12 02:01 UTC
# Uso:  descargar este archivo al router y correr  /import c2-badbox.rsc
# Crea/actualiza el address-list 'badbox-c2'. NO dropea por si solo:
# al final hay un ejemplo de regla, comentado, para que decidas vos.
/ip firewall address-list
:foreach i in=[find list=badbox-c2] do={remove $i}
add list=badbox-c2 address=8.222.223.201 comment="BADBOX2 C2 · :1883 · MQTT C2 · AS45102 ALIBABA-CN-NET - Alibaba (US) Technology, SG"
add list=badbox-c2 address=15.204.53.165 comment="BADBOX2 C2 · :9929 · AS16276 OVH - OVH SAS, US"
add list=badbox-c2 address=34.41.139.193 comment="BADBOX2 C2 · :55500 · AS396982 GOOGLE-CLOUD-PLATFORM - Google LLC, US"
add list=badbox-c2 address=35.241.108.36 comment="BADBOX2 C2 · :7890 · proxy (Clash/Mihomo) · AS396982 GOOGLE-CLOUD-PLATFORM - Google LLC, US"
add list=badbox-c2 address=43.102.213.93 comment="BADBOX2 C2 · :279 · AS45102 ALIBABA-CN-NET - Alibaba (US) Technology, SG"
add list=badbox-c2 address=43.134.123.123 comment="BADBOX2 C2 · :239,286 · AS132203 TENCENT-NET-AP-CN - Tencent Building, SG"
add list=badbox-c2 address=43.135.147.227 comment="BADBOX2 C2 · :242 · AS132203 TENCENT-NET-AP-CN - Tencent Building, SG"
add list=badbox-c2 address=45.78.212.78 comment="BADBOX2 C2 · :245,290 · AS150436 BYTEPLUS-AS-AP - Byteplus Pte. Ltd., SG"
add list=badbox-c2 address=46.8.9.225 comment="BADBOX2 C2 · :18081 · mineria Monero · AS60592 GRANSY - Gransy s.r.o., CZ"
add list=badbox-c2 address=46.8.9.226 comment="BADBOX2 C2 · :18081 · mineria Monero · AS60592 GRANSY - Gransy s.r.o., CZ"
add list=badbox-c2 address=46.8.9.227 comment="BADBOX2 C2 · :18081 · mineria Monero · AS60592 GRANSY - Gransy s.r.o., CZ"
add list=badbox-c2 address=46.62.150.144 comment="BADBOX2 C2 · :21 · AS24940 HETZNER-AS - Hetzner Online GmbH, DE"
add list=badbox-c2 address=47.76.118.67 comment="BADBOX2 C2 · AS45102 ALIBABA-CN-NET - Alibaba (US) Technology, US"
add list=badbox-c2 address=47.84.75.112 comment="BADBOX2 C2 · AS45102 ALIBABA-CN-NET - Alibaba (US) Technology, US"
add list=badbox-c2 address=47.253.5.149 comment="BADBOX2 C2 · :9377 · AS45102 ALIBABA-CN-NET - Alibaba (US) Technology, US"
add list=badbox-c2 address=51.81.137.85 comment="BADBOX2 C2 · :9998 · AS16276 OVH - OVH SAS, US"
add list=badbox-c2 address=107.151.249.174 comment="BADBOX2 C2 · :9998 · AS62610 ZEN-DPS - Zenlayer Inc, US"
add list=badbox-c2 address=117.161.138.181 comment="BADBOX2 C2 · AS9808 CHINAMOBILE-CN - China Mobile Communicat, CN"
add list=badbox-c2 address=119.28.94.95 comment="BADBOX2 C2 · :9998 · AS132203 TENCENT-NET-AP-CN - Tencent Building, CN"
add list=badbox-c2 address=136.243.48.224 comment="BADBOX2 C2 · :9529 · AS24940 HETZNER-AS - Hetzner Online GmbH, DE"
add list=badbox-c2 address=144.217.195.210 comment="BADBOX2 C2 · :9903 · AS16276 OVH - OVH SAS, CA"
add list=badbox-c2 address=154.39.72.88 comment="BADBOX2 C2 · :2918 · AS40065 CNSERVERS - CNSERVERS LLC, US"
add list=badbox-c2 address=154.44.8.142 comment="BADBOX2 C2 · :18081 · mineria Monero · AS979 NETLAB-SDN - NetLab Global, US"
add list=badbox-c2 address=154.83.197.187 comment="BADBOX2 C2 · :9998 · AS135377 UCLOUD-HK-AS-AP - UCLOUD INFORMATION TEC, SC"
add list=badbox-c2 address=192.99.215.40 comment="BADBOX2 C2 · AS16276 OVH - OVH SAS, CA"
add list=badbox-c2 address=192.254.87.10 comment="BADBOX2 C2 · :9998 · AS21859 ZEN-ECN - Zenlayer Inc, US"

# --- ejemplo de contencion (REVISAR antes de habilitar) ---
# OJO: varias de estas IPs son de nube compartida (Alibaba, OVH,
# Tencent, Google Cloud). Un DROP puede afectar OTROS servicios
# alojados en la misma IP. Conviene arrancar con action=log y mirar.
# /ip firewall raw
# add chain=prerouting action=drop dst-address-list=badbox-c2 comment="BADBOX C2 saliente"
# add chain=prerouting action=drop src-address-list=badbox-c2 comment="BADBOX C2 entrante"
