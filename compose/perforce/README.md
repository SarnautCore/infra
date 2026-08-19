# Helix Core local server

This Compose project is separate from the core Sarnaut stack. The scripts in
`scripts/` do not start or stop it.

The server uses
[`neoocean/helix-p4d:2026.1`](https://hub.docker.com/r/neoocean/helix-p4d), a
maintained multi-architecture image based on the current Helix Core 2026.1
release. Its `/p4` directory maps to `G:\SarnautCore-p4depot` on the host. Do
not expose port 1666 to the public internet without adding transport security
and access controls.

## First-time setup

1. Install Docker Desktop and make sure drive `G:` is available to Docker.
2. Copy `.env.example` to `.env` at the repository root.
3. Replace `P4SUPER_PASSWORD` before the first start. Keep
   `P4SUPERUSER=sarnaut` unless the depot has already been initialized under a
   different account.
4. Confirm that `G:\SarnautCore-p4depot` exists.
5. From the repository root, validate and start the server:

   ```powershell
   docker compose --env-file .env -f compose/perforce/docker-compose.yml config
   docker compose --env-file .env -f compose/perforce/docker-compose.yml up -d
   docker compose --env-file .env -f compose/perforce/docker-compose.yml ps
   ```

Connect P4V or the `p4` CLI to `localhost:1666` as `sarnaut`. The image stores
bootstrap settings in the depot on its first run. Changing the username,
password, case mode, or character set in `.env` later does not reinitialize an
existing depot.

Stop the server without deleting the depot:

```powershell
docker compose --env-file .env -f compose/perforce/docker-compose.yml down
```

Back up `G:\SarnautCore-p4depot` before upgrading the image. Major Helix Core
upgrades can require an irreversible database schema upgrade.
