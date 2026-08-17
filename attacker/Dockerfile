# Minimal attacker toolbox — real open-source security tools, not
# reimplementations. All well-known: https://nmap.org/, http://www.hping.org/
FROM alpine:3.20

RUN apk add --no-cache \
    nmap \
    nmap-scripts \
    hping3 \
    curl \
    bind-tools \
    bash

WORKDIR /attacks
COPY simulate_attacks.sh /attacks/simulate_attacks.sh
RUN chmod +x /attacks/simulate_attacks.sh

ENTRYPOINT ["/bin/sh"]
