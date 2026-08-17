# Minimal attacker toolbox — real open-source security tools, not
# reimplementations. All well-known: https://nmap.org/ (nmap also ships
# nping, used here for the SYN-flood step since hping3 has no arm64 build).
FROM alpine:3.20

RUN apk add --no-cache \
    nmap \
    nmap-scripts \
    nmap-nping \
    curl \
    bind-tools \
    bash

WORKDIR /attacks
COPY simulate_attacks.sh /attacks/simulate_attacks.sh
RUN chmod +x /attacks/simulate_attacks.sh
