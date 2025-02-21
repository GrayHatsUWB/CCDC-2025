## Basic UFW Commands

### Checking UFW Status

- **Command**:
    
    ```
    sudo ufw status
    ```
    
- **Verbose mode**:
    
    ```
    sudo ufw status verbose
    ```
    
- Initially, UFW may be disabled on a fresh system.

### Enabling & Disabling UFW

- **Enable UFW**:
    
    ```
    sudo ufw enable
    ```
    
- **Disable UFW**:
    
    ```
    sudo ufw disable
    ```
    

### Default Policies

- **Set default to deny incoming**:
    
    ```
    sudo ufw default deny incoming
    ```
    
- **Set default to allow outgoing**:
    
    ```
    sudo ufw default allow outgoing
    ```
    
- These commands are typically set before enabling UFW to ensure desired behavior for all ports.

---

## Allowing Connections

### Allow by Service Name

- **Command**:
    
    ```
    sudo ufw allow ssh
    ```
    
- This looks up the service’s default port (e.g., SSH is port 22) and allows incoming traffic.

### Allow by Port Number/Protocol

- **Command**:
    
    ```
    sudo ufw allow 22/tcp
    ```
    
- Alternatively:
    
    ```
    sudo ufw allow 80/tcp
    ```
    
    or
    
    ```
    sudo ufw allow 443/tcp
    ```
    
- The `tcp`/`udp` is needed. Generally speaking, most services like SSH and HTTP use TCP.

### Allow by Port Range

- **Example**:
    
    ```
    sudo ufw allow 6000:6007/tcp
    ```
    
- This opens a range of ports from 6000 to 6007.

### Allow from a Specific IP

- **Example**:
    
    ```
    sudo ufw allow from 192.168.0.4
    ```
    
- This allows traffic from a specific IP to **any** port on the server.

### Allow from Specific IP to a Specific Port

- **Command**:
    
    ```
    sudo ufw allow from 192.168.0.4 to any port 22
    ```
    
- This restricts what the IP can access (in this case, only SSH port 22).

---

## Denying Connections

### Deny by Service/Port

- **Command**:
    
    ```
    sudo ufw deny http
    ```
    
- or
    
    ```
    sudo ufw deny 80/tcp
    ```
    

### Deny from a Specific IP

- **Command**:
    
    ```
    sudo ufw deny from 203.0.113.4
    ```
    

### Deny a Specific IP to a Specific Port

- **Command**:
    
    ```
    sudo ufw deny from 203.0.113.4 to any port 22
    ```
    

---

## Deleting Rules

When you create a rule (allow or deny), UFW assigns it a rule number. You can remove a rule using either the rule syntax or its rule number.

- **Find UFW rules with numbered list**:
    
    ```
    sudo ufw status numbered
    ```
    
- **Delete by rule number**:
    
    ```
    sudo ufw delete <rule_number>
    ```
    
- **Delete by specifying the rule exactly**:
    
    ```
    sudo ufw delete allow 80/tcp
    ```
    

---

## Logging

UFW’s logging is helpful for diagnosing firewall issues or suspicious traffic.

- **Enable logging**:
    
    ```
    sudo ufw logging on
    ```
    
- **Disable logging**:
    
    ```
    sudo ufw logging off
    ```
    
- **Set log levels** (low, medium, high, full):
    
    ```
    sudo ufw logging low
    ```
    

---

## Common Firewall Rules (Examples)

1. **SSH**:
    
    ```
    sudo ufw allow ssh
    ```
    
2. **SSH on non-default port** (e.g., port 2222):
    
    ```
    sudo ufw allow 2222/tcp
    ```
    
3. **HTTP (port 80)**:
    
    ```
    sudo ufw allow http
    ```
    
4. **HTTPS (port 443)**:
    
    ```
    sudo ufw allow https
    ```
    
5. **FTP**:
    
    ```
    sudo ufw allow 21/tcp
    ```
    
6. **OpenSSH**:
    
    ```
    sudo ufw allow 'OpenSSH'
    ```
    