# mini-soc-lab

A small, reproducible SOC lab built entirely from the **real open-source tools
security teams run in production** — no hand-rolled detection engine. One
`make demo` spins up a vulnerable target, attacks it with real tooling,
captures the traffic, runs it through an industry-standard IDS, and lands
the alerts in a real SIEM dashboard.

This is deliberately the opposite of "build your own mini-Snort in Flask":
the point is fluency with the actual stack a SOC analyst / detection
engineer touches day one on the job.

## Architecture

```mermaid
flowchart LR
    subgraph "Simulated network (Docker)"
        A[attacker\nnmap + nping + curl] -->|attack traffic| V[victim\nOWASP Juice Shop]
        C[capture\ntcpdump] -.sniffs attacker netns.-> A
    end
    C -->|capture.pcap| S[Suricata\nET Open + local rules]
    S -->|eve.json alerts| F[Filebeat\nSuricata module]
    F --> E[Elasticsearch]
    E --> K[Kibana\nSuricata alert dashboards]
```

## Try it online — no install

Don't want to install Docker locally? Run the whole thing for free on
[Play with Docker](https://labs.play-with-docker.com/) — a disposable Linux
box with Docker pre-installed, live in your browser. Sign in with a free
Docker Hub account, click **+ ADD NEW INSTANCE**, then paste:

```bash
apk add --no-cache git make
git clone __GITHUB_URL__.git
cd mini-soc-lab
make demo
```

Play with Docker auto-detects listening ports and shows clickable badges at
the top of the screen — click **3000** for Juice Shop and **5601** for
Kibana. Sessions last 4 hours, then the whole box is destroyed — spin up a
fresh one anytime, free, forever. See the [landing page](site/index.html)
for a friendlier walkthrough of the same steps.

## Tools used (all open source — click through)

| Layer | Tool | Link |
|---|---|---|
| Detection engine | Suricata (IDS/IPS/NSM) | https://suricata.io/ |
| Detection ruleset | Emerging Threats Open | https://rules.emergingthreats.net/ |
| Packet capture | tcpdump | https://www.tcpdump.org/ |
| Attack tooling | nmap (scan + nping for flood) | https://nmap.org/ |
| Vulnerable target | OWASP Juice Shop | https://owasp.org/www-project-juice-shop/ |
| Log shipping | Filebeat (Suricata module) | https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-module-suricata.html |
| SIEM / search | Elasticsearch | https://www.elastic.co/elasticsearch |
| SIEM / dashboards | Kibana | https://www.elastic.co/kibana |
| Orchestration | Docker Compose | https://docs.docker.com/compose/ |

## What it detects

Signature-based (Suricata + ET Open + [local.rules](suricata/rules/local.rules)):
- SQL injection (`UNION SELECT`, `' OR 1=1`)
- Reflected XSS (`<script>`, `onerror=`)
- Directory traversal (`../../`)
- Command injection (`; cat /etc/passwd`, `$(...)`)

Behavioral (threshold rules, same thresholds as classic SOC playbooks):
- Port scan — 6+ ports from one source within 5 seconds
- SYN flood / DoS — 30+ SYNs to one destination within 2 seconds

## Prerequisites (running locally)

[Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/)
(Apple Silicon or Intel build, whichever matches your Mac). Everything below
assumes `docker` and `docker compose` are on your `PATH`. Skip this entirely
by using the no-install option above instead.

## Run it

```bash
cd ~/mini-soc-lab
make demo
```

This will: build the attacker image, start Juice Shop, wait for it to be
ready, run the attack simulation, stop the packet capture, run Suricata
against the resulting pcap, and start Elasticsearch/Kibana/Filebeat.

Then open:
- **Kibana** → http://localhost:5601 → *Analytics ▸ Dashboards* → search
  "Suricata" for the pre-built alert dashboards (Filebeat's Suricata module
  loads these automatically, no manual dashboard-building). If a panel looks
  empty, widen the time picker (top right, defaults to "Last 15 minutes") —
  it needs to cover whenever `make attack` actually ran.
- **Raw alerts** → [`suricata/logs/eve.json`](suricata/logs/eve.json) (JSON,
  one alert per line) or `suricata/logs/fast.log` (human-readable).

To re-run just the attack + analysis (SIEM already up):
```bash
make attack capture-stop analyze
```

To also point Suricata at a third-party PCAP (e.g. from
https://www.malware-traffic-analysis.net/) instead of the simulated traffic,
drop it in `pcaps/capture.pcap` and run `make analyze` directly.

Tear down:
```bash
make down      # stop containers, keep captured data
make clean     # stop containers, wipe pcaps/logs/ES volume
```

## Why real tools instead of a custom engine

A hand-built Flask+Scapy detector is a fine exercise in networking
fundamentals, but it doesn't transfer directly to a SOC seat — the job is
tuning Suricata rules, reading `eve.json`, and building Kibana dashboards on
top of the Elastic stack (or the Wazuh/Splunk/Sentinel equivalents). This
lab is built so every command in it is something you'd actually run in a
detection-engineering role, and every tool has a public project you can
keep learning from after this repo.
