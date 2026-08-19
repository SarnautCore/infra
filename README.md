# SarnautCore infrastructure

Local development services for the SarnautCore Go server and Godot client.
Kubernetes and Agones are intentionally out of scope for now.

## Stack

- PostgreSQL 18 for relational data
- Valkey for caching and short-lived state
- NATS with JetStream for messaging and durable streams
- ClickHouse for event and analytics data
- OpenTelemetry Collector for OTLP metrics and logs
- Prometheus for metrics, Loki for logs, and Grafana for dashboards
- A separate, opt-in Helix Core configuration under `compose/perforce/`

The collector accepts OTLP over gRPC and HTTP. It exposes collected metrics for
Prometheus to scrape and sends logs to Loki. Grafana starts with Prometheus,
Loki, and ClickHouse data sources already provisioned.

## Quickstart

Requirements are Windows 11, Docker Desktop, and PowerShell 7 or Windows
PowerShell 5.1.

```powershell
Copy-Item .env.example .env
./scripts/up.ps1
./scripts/status.ps1
```

The values in `.env.example` are local development defaults. Change them if
the machine is shared. `.env` is ignored by Git.

Stop the core stack with:

```powershell
./scripts/down.ps1
```

Named Docker volumes preserve service data across restarts and `down`. To erase
local data, run `docker compose --env-file .env -f compose/docker-compose.yml down -v`
only when that loss is intended.

## Ports

| Service | Host port | Purpose |
| --- | ---: | --- |
| PostgreSQL | 5433 | SQL, configurable with `POSTGRES_PORT` |
| Valkey | 6379 | RESP |
| NATS | 4222 | Clients |
| NATS monitoring | 8222 | Health and monitoring |
| ClickHouse | 8123 | HTTP |
| ClickHouse | 9000 | Native protocol |
| Prometheus | 9090 | Metrics UI and API |
| Grafana | 3000 | Dashboards |
| Loki | 3100 | Log API |
| OTLP gRPC | 4317 | Telemetry ingest |
| OTLP HTTP | 4318 | Telemetry ingest |
| Helix Core | 1666 | Separate P4 stack, not started by core scripts |

## Clean-room posture

SarnautCore is a fan-driven, non-commercial, open-source recreation project.
This repository contains independently written infrastructure configuration. It
does not contain original game binaries, assets, source code, credentials, or
other proprietary material. Project contribution and clean-room guidance lives
in the [SarnautCore documentation](https://github.com/SarnautCore/docs).

## License

Apache License 2.0. See [LICENSE](LICENSE).
