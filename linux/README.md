# Linux DevOps Commands — HireFlow Team 02

## Purpose

This folder contains Linux command references and scripts used in DevOps 
workflows for the HireFlow recruitment platform (Sprint #3, Assignment 4.11).

---

## Script: `devops-linux-commands.sh`

A hands-on shell script demonstrating Linux operations across four areas:

| Section | Topics Covered |
|---------|---------------|
| 1. Filesystem Navigation | `pwd`, `ls -la`, `du`, `df`, `find`, log inspection |
| 2. Permissions & Ownership | `chmod`, `chown`, numeric modes, DevOps permission scenarios |
| 3. Process & Network | `ps aux`, `ss`, `netstat`, port checking, connectivity |
| 4. DevOps Patterns | Log grepping, real-time tailing, artifact directory setup |

---

## How to Run
```bash
# Make executable first (required once)
chmod +x linux/devops-linux-commands.sh

# Run the script
bash linux/devops-linux-commands.sh
```

---

## Why Linux Matters for HireFlow

The HireFlow CI/CD pipeline runs on GitHub Actions — which uses Ubuntu 
Linux runners. Every step in our pipeline executes Linux commands:

- `npm install` runs on a Linux runner
- `docker build` runs on a Linux runner  
- `kubectl apply` runs on a Linux runner
- Kubernetes pods themselves run Linux containers

If a script lacks execute permission, the pipeline fails with 
`Permission denied`. If a config file has wrong ownership, the app 
can't read it at startup. These are real failure modes.

---

## Key Permission Rules for HireFlow

| File Type | Permission | Reason |
|-----------|-----------|--------|
| Shell scripts (`.sh`) | `755` | Must be executable by CI runner |
| Config files | `644` | Readable by app, not writable by others |
| `.env` / secret files | `600` | Owner only — never expose secrets |
| Private keys | `400` | Read-only, owner only |
| Docker entrypoint | `755` | Must execute as container PID 1 |

---

## Key Linux Directories Used in DevOps

| Path | DevOps Use |
|------|-----------|
| `/etc/` | Nginx config, system-wide app config |
| `/var/log/` | Application and system logs |
| `/tmp/` | Build artifacts, temporary CI outputs |
| `/usr/bin/` | Installed tools: docker, kubectl, git |
| `/opt/` | Custom software installations |
| `/proc/` | Running process information |