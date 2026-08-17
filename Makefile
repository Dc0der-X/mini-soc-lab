.PHONY: demo lab-up wait-victim attack capture-stop analyze siem-up urls down clean

# Full end-to-end run: spin up the target, generate attacks, capture them,
# run Suricata against the capture, then bring up the SIEM to view alerts.
demo: lab-up wait-victim attack capture-stop analyze siem-up urls

lab-up:
	docker compose --profile lab up -d --build victim attacker capture

wait-victim:
	@echo "Waiting for Juice Shop to be ready..."
	@until docker compose exec -T attacker curl -s -o /dev/null http://victim:3000; do sleep 2; done
	@echo "Juice Shop is up."

attack:
	docker compose exec -T attacker /attacks/simulate_attacks.sh

capture-stop:
	@echo "Stopping capture (flushing pcap)..."
	docker compose stop capture

analyze:
	@echo "Running Suricata against the captured traffic..."
	docker compose --profile analyze run --rm suricata

siem-up:
	docker compose --profile siem up -d elasticsearch kibana filebeat

urls:
	@echo
	@echo "Kibana:         http://localhost:5601  (Analytics > Dashboards > search 'Suricata')"
	@echo "Elasticsearch:  http://localhost:9200"
	@echo "Juice Shop:     http://localhost:3000"
	@echo "Raw alerts:     suricata/logs/eve.json  (fast.log, stats.log alongside it)"

down:
	docker compose --profile lab --profile siem --profile analyze down

clean: down
	rm -f pcaps/*.pcap suricata/logs/*.json suricata/logs/*.log
	docker compose --profile siem down -v
