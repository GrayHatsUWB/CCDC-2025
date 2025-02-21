## 1. What Is iptables?

- **iptables** is a command-line firewall utility in Linux that uses the **Netfilter** framework in the kernel.
- It works with **tables** (like `filter`, `nat`, `mangle`, `raw`), and each table has **chains** (like `INPUT`, `FORWARD`, `OUTPUT` in the `filter` table).
- **Rules** are added to these chains to define how incoming/outgoing/forwarded packets should be handled (e.g., `ACCEPT`, `DROP`, `REJECT`, `LOG`).

---

## 2. Basic Command Structure

```
sudo iptables [ -t <table> ] <COMMAND> <chain> [match criteria/conditions] -j <target>
```

- **sudo iptables**: Run iptables with administrative privileges (root access).
- **-t** : Specify which table to use (defaults to `filter` if not specified).
    - Common tables:
        - **filter**: The default. Contains the `INPUT`, `FORWARD`, and `OUTPUT` chains for packet filtering.
        - **nat**: Used for Network Address Translation. Contains `PREROUTING`, `POSTROUTING`, `OUTPUT` chains.
        - **mangle**: Used for packet alteration.
        - **raw**: Used for special exemptions and advanced packet processing.
- : How you want to add or manipulate the rule. Examples:
    - **-A** (append): Add a new rule to the end of a chain.
    - **-I** (insert): Insert a new rule at a given position in a chain (default is position 1 if not specified).
    - **-D** (delete): Remove a rule from a chain (by match or line number).
    - **-R** (replace): Replace a rule at a specific position in a chain.
    - **-F** (flush): Delete all rules in a chain (or all chains if none specified).
- : The chain you are altering, e.g. `INPUT`, `FORWARD`, `OUTPUT`, `PREROUTING`, `POSTROUTING`.
- **match criteria/conditions**: This can include:
    - **-p** `<protocol>` (e.g., `tcp`, `udp`, `icmp`).
    - **-s** `<source IP>` (e.g., `192.168.1.100`).
    - **-d** `<destination IP>`.
    - **--sport** `<source port>` or **--dport** `<destination port>`.
    - **-m state** `--state <state>` (e.g., `NEW`, `ESTABLISHED`, `RELATED`).
    - **-i** `<interface>` (incoming interface) or **-o** `<interface>` (outgoing interface).
- **-j** : Specifies what to do with the matched packets. Common targets:
    - **ACCEPT**: Let the traffic pass.
    - **DROP**: Silently discard the traffic.
    - **REJECT**: Discard the traffic but send a “reject” response (often an ICMP “port unreachable”).
    - **LOG**: Log the packet (then continue to next rule, unless explicitly used with special modules).
    - **DNAT**: Destination NAT (in `nat` table).
    - **SNAT**: Source NAT (in `nat` table).
    - **MASQUERADE**: A form of SNAT often used for dynamic IP addresses.

---

## 3. Setting Default Policies

A **default policy** is what iptables does when a packet **does not match** any rule in the chain. Typically, we set:

```
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT
```

- **-P** sets the policy on a chain:
    - `INPUT` chain handles traffic **coming into** the server.
    - `FORWARD` chain handles traffic **passing through** the server to another network (used in routing scenarios).
    - `OUTPUT` chain handles traffic **originating** from the server.
- The above means:
    - **Deny all inbound** traffic by default (`DROP`).
    - **Deny all forwarding** by default.
    - **Allow all outbound** traffic by default (`ACCEPT`).

---

## 4. Allowing (ACCEPT) Rules

### 4.1 General Structure

```
sudo iptables -A INPUT -p tcp --dport <PORT> -j ACCEPT
```

- **-A INPUT**: Append to the `INPUT` chain.
- **-p tcp**: Match TCP protocol.
- **--dport** : Match traffic destined for `<PORT>`.
- **-j ACCEPT**: Accept the matching packets.

### 4.2 Examples

#### Allow SSH (port 22)

```
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
```

- Allows any IP to reach port 22 (SSH). If your default INPUT policy is DROP, this is crucial to avoid locking yourself out.

#### Allow HTTP (port 80)

```
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
```

- Common for web servers, lets external traffic connect via port 80.

#### Allow HTTPS (port 443)

```
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

- For secure web (SSL/TLS).

#### Restrict to Specific IP

```
sudo iptables -A INPUT -p tcp -s 192.168.0.10 --dport 22 -j ACCEPT
```

- Only **192.168.0.10** can access SSH on this server; all other sources to port 22 will be dropped if no other rule allows them.

#### Allow Established Connections

```
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

- Allows return traffic for connections you **initiated** or are related to an existing connection. Essential if your default policy is DROP.

#### Loopback Traffic

```
sudo iptables -A INPUT -i lo -j ACCEPT
```

- Allows all traffic on the loopback interface (`lo`, i.e., 127.0.0.1). Many processes rely on this internally.

---

## 5. Denying (DROP/REJECT) Rules

### 5.1 General Structure

```
sudo iptables -A <chain> -p <protocol> [conditions] -j DROP
```

or

```
sudo iptables -A <chain> -p <protocol> [conditions] -j REJECT
```

- **DROP**: Silently discards packets.
- **REJECT**: Discards but sends an ICMP error to the sender.

### 5.2 Examples

#### Block a Specific IP Completely

```
sudo iptables -A INPUT -s 203.0.113.4 -j DROP
```

- Any traffic from **203.0.113.4** gets dropped.

#### Block a Port (e.g., FTP on port 21)

```
sudo iptables -A INPUT -p tcp --dport 21 -j DROP
```

- Denies FTP access to your server.

#### Log Then Drop

```
sudo iptables -A INPUT -p tcp --dport 22 -j LOG --log-prefix "SSH PACKET DROPPED: "
sudo iptables -A INPUT -p tcp --dport 22 -j DROP
```

- First logs a message to `/var/log/syslog` (or similar), then drops the packet.

---

## 6. More Advanced Command Options

### 6.1 Inserting Rules (-I)

If you need a rule to appear **before** existing rules:

```
sudo iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT
```

- Inserts the rule at line 1 in the `INPUT` chain (the highest priority).

### 6.2 Replacing Rules (-R)

To **replace** a rule at a specific line:

```
sudo iptables -R INPUT 2 -p tcp --dport 80 -j ACCEPT
```

- Replaces the **2nd rule** in `INPUT` with the new one.

### 6.3 Deleting Rules (-D)

You can delete by specifying the **exact match** or by **line number**.

1. **Delete by exact match**:
    
    ```
    sudo iptables -D INPUT -p tcp --dport 22 -j ACCEPT
    ```
    
2. **Delete by line number**:
    
    ```
    sudo iptables -L INPUT --line-numbers
    sudo iptables -D INPUT <line_number>
    ```
    

---

## 7. Flushing Rules (-F)

### Flush a Single Chain

```
sudo iptables -F INPUT
```

- Clears all rules in the INPUT chain.

### Flush All Chains

```
sudo iptables -F
```

- **Warning**: This deletes all rules in all chains for the default table (`filter`).

### Delete Any User-Defined Chains

```
sudo iptables -X
```

- Removes user-created chains (ones not automatically created by iptables).

---

## 8. Saving & Restoring iptables Rules

Because iptables rules do **not** persist automatically after a reboot (on many distros), you should **save** them to a file and **restore** at boot.

### Save Rules

```
sudo sh -c "iptables-save > /etc/iptables.rules"
```

- Exports current rules to `/etc/iptables.rules`.

### Restore Rules

```
sudo iptables-restore < /etc/iptables.rules
```

- Reapplies those rules.

_(Different Linux distributions may have different recommended methods — e.g., using `netfilter-persistent`, or placing rules in `/etc/iptables/rules.v4` for Debian/Ubuntu.)_

---

## 9. Common “Real World” Examples

### 9.1 Basic Firewall Setup

1. **Set Default Policies** (Deny inbound, deny forward, allow outbound):
    
    ```
    sudo iptables -P INPUT DROP
    sudo iptables -P FORWARD DROP
    sudo iptables -P OUTPUT ACCEPT
    ```
    
2. **Allow Loopback**:
    
    ```
    sudo iptables -A INPUT -i lo -j ACCEPT
    ```
    
3. **Allow Established Connections**:
    
    ```
    sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    ```
    
4. **Open Common Ports**:
    
    ```
    sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT   # SSH
    sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT   # HTTP
    sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT  # HTTPS
    ```
    
5. **Save**:
    
    ```
    sudo sh -c "iptables-save > /etc/iptables.rules"
    ```
    
    _(Then configure your system to restore at boot.)_

### 9.2 Port Forwarding (Using the nat table)

Let’s say you want to forward incoming traffic on port 8080 to a local port 80:

6. **DNAT** rule in the `PREROUTING` chain of the `nat` table:
    
    ```
    sudo iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 127.0.0.1:80
    ```
    
7. **MASQUERADE** or **SNAT** if forwarding to another network (e.g., if your server routes to internal hosts):
    
    ```
    sudo iptables -t nat -A POSTROUTING -j MASQUERADE
    ```
    

### 9.3 Blocking Specific Countries (geoip)

This is more advanced and requires iptables **geoip** modules or ipset. Typically you create an ipset of IP ranges, then block them:

```
sudo ipset create blocklist hash:net
sudo ipset add blocklist 203.0.113.0/24

sudo iptables -A INPUT -m set --match-set blocklist src -j DROP
```

---

## 10. Final Tips

- **Order of Rules**: iptables checks rules from **top to bottom** in a chain. Once a match is found and acted upon, it stops traversing that chain (unless the target is something like `LOG`).
- **Logging**: Use `-j LOG` with caution; it can fill your logs quickly. Usually, you might do:
    
    ```
    sudo iptables -A INPUT -p tcp --dport 22 -m limit --limit 5/min -j LOG --log-prefix "SSH attempt: "
    ```
    
    This uses the `limit` match to rate-limit logs.
- **Stateful Rules**: `-m state --state ...` or `-m conntrack --ctstate ...` is crucial. Typically:
    
    ```
    sudo iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    ```
    
    (Modern distros often use `conntrack` instead of `state`.)
