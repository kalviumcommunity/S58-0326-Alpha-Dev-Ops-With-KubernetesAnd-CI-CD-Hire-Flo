# Linux for DevOps — Quick Reference Guide
## HireFlow Team 02 | Assignment 4.11

---

## Filesystem Navigation
```bash
pwd                        # Show current directory path
ls -la                     # List all files with permissions and ownership
cd /path/to/dir            # Change directory
mkdir -p dir/subdir        # Create nested directories in one command
find . -name "*.yml"       # Find all YAML files recursively
find . -name "*.sh" -type f  # Find all shell scripts
du -sh .                   # Show size of current directory
df -h                      # Show disk usage of all mounted filesystems
cat filename               # Display file contents
tail -n 20 app.log         # Show last 20 lines of a log file
tail -f app.log            # Follow log in real time (live streaming)
grep -i "error" app.log    # Search for errors in logs (case-insensitive)
```

---

## Permissions & Ownership
```bash
ls -la                     # Show permissions for all files
chmod +x script.sh         # Add execute permission
chmod 755 script.sh        # rwxr-xr-x (standard scripts)
chmod 644 config.txt       # rw-r--r-- (config files)
chmod 600 .env             # rw------- (secret files)
chmod 400 private.key      # r-------- (read-only secrets)
chown user:group file      # Change file owner and group
chown -R ci:ci /opt/app    # Recursively change ownership
```

### Permission Number Reference
```
7 = rwx (read + write + execute)
6 = rw- (read + write)
5 = r-x (read + execute)
4 = r-- (read only)
0 = --- (no permissions)

Format: chmod [owner][group][others] filename
```

---

## Process Inspection
```bash
ps aux                     # List all running processes
ps aux | grep node         # Find specific process (e.g., Node.js)
ps aux | grep docker       # Check if Docker daemon is running
kill -9 <PID>              # Force kill a process by PID
top                        # Live CPU/memory usage monitor
uptime                     # System uptime and load average
free -h                    # Memory usage in human-readable format
```

---

## Network Inspection
```bash
ss -tlnp                   # Show all listening ports with process info
netstat -tlnp              # Alternative to ss (older systems)
ss -tlnp | grep :3000      # Check if port 3000 is in use
curl -I http://localhost:3000/health  # HTTP health check
ping google.com            # Test basic network connectivity
```

---

## DevOps Scenarios & Solutions

### Scenario 1: CI Pipeline fails with "Permission denied"
```bash
# Problem: Script not executable
ls -la entrypoint.sh
# Shows: -rw-r--r-- (no x bit)

# Fix:
chmod +x entrypoint.sh
git add entrypoint.sh
git commit -m "fix(docker): add execute permission to entrypoint script"
git push
```

### Scenario 2: App won't start — port already in use
```bash
# Problem: Port 3000 already occupied
ss -tlnp | grep :3000
# Shows: node process using port 3000

# Fix: Find and kill the old process
ps aux | grep node
kill -9 <PID>
# Then restart the app
```

### Scenario 3: Container can't read config file
```bash
# Problem: Config file owned by root, app runs as non-root user
ls -la /etc/hireflow/app.conf
# Shows: -rw------- root root

# Fix: Change ownership to app user
sudo chown appuser:appuser /etc/hireflow/app.conf
# OR make it group-readable
sudo chmod 640 /etc/hireflow/app.conf
```

### Scenario 4: Disk space full — CI build failing
```bash
# Diagnose:
df -h                          # Check overall disk usage
du -sh /var/log/*              # Find large log directories
du -sh /tmp/*                  # Check temp build artifacts

# Clean up:
docker system prune -f         # Remove unused Docker images/containers
rm -rf /tmp/old-build-artifacts
```