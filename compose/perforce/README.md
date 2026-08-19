# Helix Core local server

This Compose project runs the SarnautCore P4 Server separately from the core
stack. The scripts under the repository-level `scripts/` directory do not
start or stop it.

The service builds `sarnaut/helix-p4d:2026.1` from
`neoocean/helix-p4d:2026.1`. The small local wrapper fixes the upstream
bootstrap order for P4 Server 2026.1, whose secure-by-default behavior requires
the first superuser password before the older image setup can create specs.
The server listens on host port 1666 and stores its database, journals,
checkpoints, and archives under `G:\SarnautCore-p4depot`.

Do not expose port 1666 to the public internet. This setup uses plaintext TCP
and security level 2 for a small LAN development server.

## Environment

Copy `.env.example` to the repository-root `.env` and set these values:

- `P4SUPERUSER` is the P4 superuser. The configured server uses `sarnaut`.
- `P4SUPER_PASSWORD` is the superuser password. Keep it only in `.env`, which
  Git ignores.
- `P4DEPOT_BIND_SOURCE` overrides the host-side depot mount when Docker Desktop
  cannot bind `G:` directly.

Changing the username, password, case mode, or character set after the first
successful start does not reinitialize an existing depot.

## ReFS Dev Drive mount

On this workstation, `G:` is a ReFS Dev Drive. Docker Desktop resolves a direct
`G:/SarnautCore-p4depot` bind to the wrong block device. Mount the drive through
the Docker Desktop WSL distribution with Linux metadata enabled after each
Docker Desktop restart:

```powershell
wsl.exe -d docker-desktop -u root -- sh -lc "mkdir -p /mnt/windows-g-meta && (mountpoint -q /mnt/windows-g-meta || mount -t drvfs -o metadata 'G:' /mnt/windows-g-meta)"
```

Set the following override in `.env` on this machine:

```dotenv
P4DEPOT_BIND_SOURCE=/mnt/windows-g-meta/SarnautCore-p4depot
```

The `metadata` mount option matters. P4D changes archive file modes during
submit; a plain drvfs mount fails those `chmod` calls.

## Start and connect

From the repository root:

```powershell
docker compose -f compose/perforce/docker-compose.yml --env-file .env config
docker compose -f compose/perforce/docker-compose.yml --env-file .env up -d
docker compose -f compose/perforce/docker-compose.yml --env-file .env ps
```

Wait for `p4d` to report `healthy`, then configure the Windows CLI. Unicode
mode requires `P4CHARSET=utf8`.

```powershell
p4 set P4PORT=localhost:1666
p4 set P4CHARSET=utf8
p4 set P4USER=sarnaut
p4 set P4CLIENT=sarnaut-assets-main

$passwordLine = Get-Content .env | Where-Object { $_ -match '^P4SUPER_PASSWORD=' }
$password = $passwordLine.Substring($passwordLine.IndexOf('=') + 1)
$password | p4 login
Remove-Variable password,passwordLine

p4 info
```

## Configured server state

- Security is level 2. Every user needs a strong password, but tickets are not
  mandatory. The deployment has one superuser, named by `P4SUPERUSER` in
  `.env`.
- `assets` is a stream depot with `StreamDepth: //assets/1` and
  `Map: assets/...`.
- `//assets/main` is a `mainline` stream with `share ...` as its path view.
- `sarnaut-assets-main` is a stream client owned by `sarnaut`, rooted at
  `E:\SarnautCore\assets`, and bound to `//assets/main`.
- Changelist 2 added only `//assets/main/README.md`. The workspace's `store/`
  directory is a live content-addressed store and was not opened or submitted.

The typemap applies these mappings to new files:

```text
TypeMap:
        binary+F //....png
        binary+F //....glb
        binary+F //....skmesh
        binary+F //....bin
        binary+F //....pak
        binary+F //....ogv
        binary+F //....fsb
        text     //....tres
        text     //....tscn
        text     //....yaml
        text     //....json
        text     //....md
```

`+F` stores the listed already-compressed or large binary formats as full,
uncompressed revisions instead of RCS/compressed archive data. A typemap only
affects files added after the mapping exists.

Inspect the saved state without opening an editor:

```powershell
p4 configure show security
p4 depot -o assets
p4 stream -o //assets/main
p4 client -o sarnaut-assets-main
p4 typemap -o
p4 files //assets/...
```

## Operations

Stop the server without deleting depot data:

```powershell
docker compose -f compose/perforce/docker-compose.yml --env-file .env down
```

Back up `G:\SarnautCore-p4depot` before upgrading the image. P4 Server upgrades
can require an irreversible database schema upgrade. Checkpoints and journals
protect metadata; a complete backup must also include the depot archives.
