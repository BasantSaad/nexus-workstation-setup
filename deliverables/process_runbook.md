# Process Troubleshooting Runbook

**Nexus Data Systems | Workstation Standardization (NDS-WSS-104)**
**Audience:** DevOps, System Administrators, Junior Data Engineers
**Environment:** Headless Debian/Ubuntu Linux (CLI only)

---

## 1. Key Concepts

| Term | Definition |
| :--- | :--- |
| **Kernel** | The core of the operating system. It runs with full hardware privileges and manages CPU time, memory, files, and devices. Every program asks the Kernel (via system calls) to create processes, deliver signals, and end processes. Commands like `ps`, `htop`, and `kill` are front-ends to the Kernel's process table. |
| **PID (Process ID)** | A unique integer the Kernel assigns to every running process. A PID is how you tell the Kernel *which* process to inspect or signal. PID `1` is the init/systemd process, the ancestor of all others. The **PPID** is the PID of a process's parent. |
| **Daemon** | A long-running background process with no controlling terminal, usually started at boot to provide a service (e.g. `sshd`, `cron`, `systemd-journald`). By convention the name ends in `d`. Daemons are expected and healthy; a *rogue* daemon is one running without authorization or consuming excessive resources. |
| **Zombie process** | A process that has **finished executing** but still has an entry in the process table because its parent has not yet read its exit status (called `wait()`). It shows state `Z` (or `<defunct>`). A zombie uses no CPU and almost no memory, but it holds a PID; thousands of them can exhaust the PID table. Because it is already dead, it **cannot be killed directly**; it is removed when its parent reaps it or the parent exits. |

---

## 2. Inspect Running Processes

```bash
ps aux                 # snapshot of every process (USER, PID, %CPU, %MEM, STAT, COMMAND)
ps -ef                 # same, in full format; shows PPID
htop                   # interactive live view (F10 or q to quit)
tail -n 20 logs/processes.log   # baseline snapshot captured at provisioning
```

Useful columns: **PID** (process ID), **PPID** (parent), **STAT** (state; `Z` = zombie, `R` = running, `S` = sleeping, `D` = uninterruptible I/O wait).

---

## 3. Locate a Zombie Process by PID

**Step 1: List all zombies**

```bash
ps aux | awk '$8 ~ /^Z/'
```

or, showing the parent PID too:

```bash
ps -eo pid,ppid,stat,user,comm | awk '$3 ~ /^Z/'
```

Example output (PID 4821 is the zombie, its parent is PID 4790):

```
 4821  4790 Z    dev1  sensor_ingest <defunct>
```

**Step 2: Count them**

```bash
ps -eo stat | grep -c '^Z'
```

**Step 3: Confirm one specific PID**

```bash
ps -p 4821 -o pid,ppid,stat,cmd
cat /proc/4821/status | grep -E 'State|PPid'
```

`State: Z (zombie)` confirms it. Note the `PPid`; you will need it.

**Step 4: Identify the parent**

```bash
ps -p 4790 -o pid,ppid,stat,user,cmd
```

---

## 4. Force-Terminate

### 4.1 Standard force-kill (SIGKILL)

Replace `4821` with the PID found above.

```bash
kill -9 4821          # same as: kill -SIGKILL 4821  or  kill -s KILL 4821
```

`-9` is signal number 9, **SIGKILL**. It cannot be caught or ignored; the Kernel ends the process immediately. This is the correct command for a hung or rogue process, and it is the first thing to try.

Verify:

```bash
ps -p 4821            # no output besides the header means it is gone
```

### 4.2 If the zombie remains

A zombie is already dead, so signalling it does nothing. Work on the **parent**, in escalating order:

```bash
kill -s SIGCHLD 4790    # 1. nudge the parent to reap its children (wait())
kill -15 4790           # 2. ask the parent to exit cleanly (SIGTERM)
kill -9 4790            # 3. force-kill the parent (last resort)
```

When the parent dies, orphaned zombies are re-parented to PID 1, which reaps them immediately.

**Caution:** check what the parent is (`ps -p 4790 -o cmd`) before killing it. Never kill PID 1 or a production service without approval.

### 4.3 Other helpers

```bash
pkill -9 -f sensor_ingest    # kill by name pattern (use with care)
sudo kill -9 4821            # needed if the process belongs to another user
```

---

## 5. Quick Reference

| Task | Command |
| :--- | :--- |
| Snapshot all processes | `ps aux` |
| Live monitor | `htop` |
| Find zombies | `ps aux \| awk '$8 ~ /^Z/'` |
| Find a zombie's parent | `ps -o ppid= -p <PID>` |
| Force-kill by PID | `kill -9 <PID>` |
| Reap via parent | `kill -s SIGCHLD <PPID>` |
| Verify removal | `ps -p <PID>` |
