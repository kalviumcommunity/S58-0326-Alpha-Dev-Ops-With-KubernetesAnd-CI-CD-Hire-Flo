#!/bin/bash

# ============================================================
# HireFlow DevOps — Linux Filesystem, Permissions & Inspection
# Team 02 | Sprint #3 | Assignment 4.11
# ============================================================
# This script demonstrates Linux commands used in real
# DevOps workflows for the HireFlow recruitment platform.
# Run this script to explore filesystem structure, manage
# permissions, and inspect running processes and network state.
# ============================================================

echo ""
echo "============================================================"
echo "  HIREFLOW — Linux DevOps Command Reference Script"
echo "  Team 02 | Sprint #3 | Assignment 4.11"
echo "============================================================"
echo ""

# ------------------------------------------------------------
# SECTION 1: LINUX FILESYSTEM STRUCTURE & NAVIGATION
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "SECTION 1: Filesystem Structure & Navigation"
echo "------------------------------------------------------------"

echo ""
echo ">> Current working directory:"
pwd

echo ""
echo ">> List all files including hidden files with permissions:"
ls -la

echo ""
echo ">> Show Linux filesystem key directories:"
echo "
/               → Root of entire filesystem
/etc            → System-wide configuration files (e.g., nginx.conf, hosts)
/var/log        → Log files (app logs, system logs, CI runner logs)
/home           → User home directories
/tmp            → Temporary files (CI builds often write here)
/usr/bin        → User-installed binaries (docker, kubectl, git)
/opt            → Optional/third-party software installations
/proc           → Virtual filesystem: running process info
/sys            → Virtual filesystem: kernel and hardware info
"

echo ""
echo ">> Show disk usage of current directory:"
du -sh .

echo ""
echo ">> Show available disk space on all mounted filesystems:"
df -h

echo ""
echo ">> Find all .yml files in current directory and subfolders:"
find . -name "*.yml" -type f

echo ""
echo ">> Find all shell scripts (.sh files):"
find . -name "*.sh" -type f

echo ""
echo ">> Show last 20 lines of a log file (simulated):"
echo "[INFO]  2026-03-16 10:00:01 - HireFlow app started on port 3000"
echo "[INFO]  2026-03-16 10:00:02 - Connected to database"
echo "[INFO]  2026-03-16 10:00:03 - Form version v2.4.1 loaded from ConfigMap"
echo "[WARN]  2026-03-16 10:00:05 - High traffic detected: 3.4x above baseline"
echo "[INFO]  2026-03-16 10:00:06 - HPA triggered: scaling from 2 to 7 pods"
# Real usage in DevOps: tail -n 20 /var/log/hireflow/app.log

echo ""
echo ">> Show environment variables (DevOps relevance: CI/CD injects vars here):"
echo "FORM_VERSION=v2.4.1"
echo "NODE_ENV=production"
echo "PORT=3000"
# Real usage: printenv | grep -i node

echo ""

# ------------------------------------------------------------
# SECTION 2: FILE PERMISSIONS & OWNERSHIP
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "SECTION 2: File Permissions & Ownership"
echo "------------------------------------------------------------"

echo ""
echo ">> Understanding Linux permission format: [type][owner][group][others]"
echo "
Example: -rwxr-xr--
  -         → regular file (d = directory, l = symlink)
  rwx       → owner can Read, Write, Execute
  r-x       → group can Read, Execute (no write)
  r--       → others can only Read

In DevOps:
  - Shell scripts MUST have execute (x) permission to run in CI pipelines
  - Config files with secrets should be 600 (owner read/write only)
  - Docker entrypoint scripts need chmod +x or they fail at container startup
"

echo ""
echo ">> Show permissions of files in linux/ folder:"
ls -la linux/

echo ""
echo ">> Make this script executable (required before running in CI pipeline):"
chmod +x linux/devops-linux-commands.sh
echo "chmod +x applied to devops-linux-commands.sh"

echo ""
echo ">> Demonstrate chmod with numeric mode:"
echo "
Numeric permission reference:
  4 = Read (r)
  2 = Write (w)  
  1 = Execute (x)

  chmod 755 script.sh   → owner:rwx  group:r-x  others:r-x  (standard scripts)
  chmod 644 config.txt  → owner:rw-  group:r--  others:r--  (config files)
  chmod 600 .env        → owner:rw-  group:---  others:---  (secret files ONLY)
  chmod 400 private.key → owner:r--  group:---  others:---  (read-only secrets)
"

echo ""
echo ">> Show file ownership (user:group):"
ls -la linux/devops-linux-commands.sh

echo ""
echo ">> Change ownership example (DevOps context: CI runner owns build files):"
echo "Command: sudo chown ci-runner:ci-runner /opt/hireflow/build"
echo "Purpose: Ensures CI runner process can read/write build artifacts"
echo "(Not executing sudo here — showing the command pattern)"

echo ""
echo ">> Real DevOps scenario — why permissions matter:"
echo "
If a CI pipeline clones the repo and tries to run entrypoint.sh but 
the file has permission 644 (no execute bit), the pipeline fails with:
  Permission denied: ./entrypoint.sh

Fix:  chmod +x entrypoint.sh
      git add entrypoint.sh
      git commit -m 'fix(docker): add execute permission to entrypoint script'

This must be committed to Git so the permission is preserved across clones.
"

echo ""

# ------------------------------------------------------------
# SECTION 3: PROCESS & NETWORK INSPECTION
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "SECTION 3: Process & Network Inspection"
echo "------------------------------------------------------------"

echo ""
echo ">> Show all running processes (snapshot):"
ps aux | head -20

echo ""
echo ">> Search for a specific process (e.g., node server):"
echo "Command: ps aux | grep node"
echo "Purpose: Verify the HireFlow Node.js server is running"
ps aux | grep -i "bash\|node\|docker" | head -10

echo ""
echo ">> Show process tree (parent-child relationships):"
echo "Command: pstree -p"
echo "Purpose: In containers, PID 1 should be your app process, not a shell"
echo "(pstree may not be available in all environments)"

echo ""
echo ">> Check what ports are currently listening:"
echo "Command: netstat -tlnp  OR  ss -tlnp"
echo "Purpose: Verify HireFlow app is listening on port 3000"
echo "         Verify no port conflicts before starting containers"
ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null || echo "(netstat/ss not available in this environment — use inside a Linux VM or container)"

echo ""
echo ">> Check if a specific port is in use:"
echo "Command: ss -tlnp | grep :3000"
echo "Purpose: Before running 'docker run -p 3000:3000', confirm host port 3000 is free"

echo ""
echo ">> Test network connectivity to a service:"
echo "Command: curl -I http://localhost:3000/health"
echo "Purpose: Quick health check — confirms app is responding before marking pod as Ready"
echo "         This is what Kubernetes readiness probe does under the hood"

echo ""
echo ">> Show system resource usage (CPU, memory):"
echo "Command: top  OR  htop"
echo "DevOps relevance: Before setting Kubernetes resource requests/limits,"
echo "observe actual app resource usage under load using top"
free -h 2>/dev/null || echo "(free command output not available here)"

echo ""
echo ">> Check system uptime and load average:"
uptime

echo ""

# ------------------------------------------------------------
# SECTION 4: DEVOPS-SPECIFIC LINUX PATTERNS
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "SECTION 4: DevOps-Specific Linux Patterns for HireFlow"
echo "------------------------------------------------------------"

echo ""
echo ">> Grep application logs for errors (used in debugging deployments):"
echo "Command: grep -i 'error\|warn\|fatal' /var/log/hireflow/app.log"
echo "Purpose: Quickly surface problems after a rolling deployment"

echo ""
echo ">> View logs in real time (follow mode):"
echo "Command: tail -f /var/log/hireflow/app.log"
echo "Purpose: Monitor live application behavior during a deployment or surge"

echo ""
echo ">> Pipe and filter — count error lines in log:"
echo "Command: grep -c 'ERROR' /var/log/hireflow/app.log"
echo "Purpose: Automated log monitoring — if error count > threshold, alert"

echo ""
echo ">> Create a directory structure for HireFlow deployment artifacts:"
mkdir -p /tmp/hireflow-build/{dist,logs,config}
echo "Created: /tmp/hireflow-build/{dist,logs,config}"
ls -la /tmp/hireflow-build/

echo ""
echo ">> Write environment config to a file securely:"
echo "FORM_VERSION=v2.4.1" > /tmp/hireflow-build/config/app.env
echo "NODE_ENV=production" >> /tmp/hireflow-build/config/app.env
echo "PORT=3000" >> /tmp/hireflow-build/config/app.env
chmod 600 /tmp/hireflow-build/config/app.env
echo "Written app.env with permissions 600 (owner-only read/write):"
ls -la /tmp/hireflow-build/config/

echo ""
echo ">> Read the config file back:"
cat /tmp/hireflow-build/config/app.env

echo ""
echo "============================================================"
echo "  Script Complete — All sections demonstrated"
echo "  Team 02 | HireFlow | Assignment 4.11"
echo "============================================================"
echo ""