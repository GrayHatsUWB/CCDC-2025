- a table is a collection of chains that is responsible for doing something
![[iptablestables_upscayl_4x_upscayl-standard-4x.png]]

- filter table is responsible for filtering incoming and outgoing traffic (the focus), basically firewall stuff
- nat table redirects connections to other interfaces
- mangle table deals with modifying and changing aspects of a packet or connection
- main focus is filter
- chains are tags that define and match packets to the estate
- example: in filter we have input output and forward. each of them is responsible for processing packets based on their type. packets that are being sent will be processed by input, etc.
- mainly interested in input and output chains
- filtering incoming and outgoing
- nat is with connecting devices together
- mangle is ab modifying packets
- they are all responsible for diff things
- filter has input and output, as well as forward
- mangle prerouting chain is used after the packet has entered the network interface (before the packet is sent out and when it just arrives)
- filter forward chain just forwards packets that aren't meant for you
- within chains we have rules, and are responsible for managing input and output of packets
- example of rule: block any incoming ssh connections or http
- if a target matches a rule then a target is set
- targets: accept, reject, drop
- accept will allow the packet through
- reject will drop packet but send feedback back to user
- drop will just drop it and not do anything
- example: you send ssh to a server, input chain will process it and match it against the rules that you have. one rule is to block ssh. if the packet matches against this rule, it will set the target, which will then either accept, reject, or drop. if it doesnt match any rules, it will use the **default policies**. If no defaults, **it will be accepted**.
- when installing, remember to remove other firewalls like ufw and firewalld
- once you uninstall other firewalls, flush rules with `sudo iptables -F`
- usually installed but you can install with `sudo apt install iptables`
- to list out default tables, `iptables -L`
- by default it uses the filter table, which is why this outputs input forward and output chains when you check with `-L`
- when you start, make sure that all of your policies are set to accept, you can do this with `iptables --policy CHAIN ACCEPT`
- be very fucking careful with this because if you set it to drop or reject, you literally won't be able to access the computer anymore
- once you accept everything, you reject everything that you dont want
- to put rules at the top, we use `-I` and to append to the bottom we use `-A`
- use `-s` to specify source 
- example command `iptables -I INPUT -s 10.0.0.1 -j DROP`
- this will drop all packets. `-I` puts at the top, `-s` is the source, and `-j` is the target (accept, reject, or drop)
- with `-s`, we can specify subnets and whatnot with `10.0.0.0/24`, etc.
- to delete rules, we list out options with `iptables -L --line-numbers`
- this allows us to use `-D` to delete.
- so `iptables -D INPUT 1` to delete rule 1 from the input chain
- to block an outgoing connection with a port we can use `iptables -I OUTPUT -p tcp --dport 80 -j DROP`
- `-p` is used for protocol (tcp or udp) and `--dport` is used for the destination port
- always want to apply new block rules to the TOP, not bottom because it reads from top to bottom so if you have a rule that says allow all and you hvae another rule blocking a specific ip address below it, it won't work because it will read allow all and that applies first
- if you want to allow specific users (IPs) to use something while blocking it for someone else, you can put a rule above the previous rule allowing that. for example: `iptables -I INPUT -p tcp --dport 80 -s 10.0.0.1 -j ACCEPT`
- to save your rules, you can use `sudo iptables-save` to keep your rules persistent
- again, to flush rules, you can use `sudo iptables -F` to clear out all rules and reset to defaults
- `-A` for append, `-I` for insert, `-s` for source, `-p` for protocol (**always specify before specifying port number, or else it won't work**), `--dport` for destination port and `-j` for the target (ACCEPT, DENY, DROP)

Here’s your cleaned-up and structured version of your notes:

---

## **Understanding iptables and Firewall Management**

### **1. Overview of Tables in iptables**

- A **table** is a collection of **chains** responsible for handling network traffic.
- Different tables serve different purposes:
    - **Filter Table (Main Focus)**: Handles filtering of incoming and outgoing traffic (firewall functions).
    - **NAT Table**: Redirects connections to other interfaces (used for connecting devices
    - **Mangle Table**: Modifies aspects of packets or connections.

### **2. Chains in iptables**

- **Chains** are tags that define and match packets.
- Each table has different chains to process packets:
    - **Filter Table:**
        - `INPUT` → Handles packets coming into the system.
        - `OUTPUT` → Handles packets going out of the system.
        - `FORWARD` → Forwards packets not meant for the local machine.
    - **Mangle Table:**
        - `PREROUTING` → Used after a packet enters the network interface, before it is sent out.
    - **NAT Table:**
        - Used for connection redirection.

### **3. Rules and Targets**

- Within each **chain**, there are **rules** that manage packet processing.
- Example rule: Block all incoming SSH or HTTP connections.
- **Targets** (Actions applied when a rule matches a packet):
    - `ACCEPT` → Allows the packet through.
    - `REJECT` → Drops the packet but sends feedback to the sender.
    - `DROP` → Silently discards the packet (no response).

#### **How Rules Work:**

1. A packet is processed through the relevant chain.
2. If a rule matches, the corresponding target is applied (`ACCEPT`, `REJECT`, `DROP`).
3. If no rules match, the **default policy** is used.
4. If no default policy is set, the packet is **accepted**.

Example:

- If you send an SSH request to a server:
    - The `INPUT` chain processes it.
    - The packet is matched against rules.
    - If there’s a rule blocking SSH, the corresponding target is applied.

### **4. Installing and Managing iptables**

- **Installation (if not installed):**
    
    ```bash
    sudo apt install iptables
    ```
    
- **Before using iptables, remove other firewalls** like UFW or firewalld:
    
    ```bash
    sudo apt remove ufw firewalld
    ```
    
- **Flush all existing rules** before setting new ones:
    
    ```bash
    sudo iptables -F
    ```
    
- **Check default tables and chains:**
    
    ```bash
    iptables -L
    ```
    
- By default, `iptables -L` shows `INPUT`, `FORWARD`, and `OUTPUT` from the **filter** table.

### **5. Setting Policies and Managing Rules**

- **Default Policy Management:**
    
    ```bash
    iptables --policy CHAIN ACCEPT
    ```
    
    ⚠ **Warning:** If you set the policy to `DROP` or `REJECT`, you may lose access to the system.
    
- **Best Practice for Setting Rules:**
    
    1. Set policies to `ACCEPT` first.
    2. Then explicitly `REJECT` unwanted traffic.
- **Adding Rules:**
    
    - **Insert at the top (`-I`)**:
        
        ```bash
        iptables -I INPUT -s 10.0.0.1 -j DROP
        ```
        
    - **Append to the bottom (`-A`)**:
        
        ```bash
        iptables -A INPUT -s 10.0.0.1 -j DROP
        ```
        
- **Blocking Outgoing Connections by Port:**
    
    ```bash
    iptables -I OUTPUT -p tcp --dport 80 -j DROP
    ```
    
    - `-p` → Protocol (TCP or UDP).
    - `--dport` → Destination port.
- **Rule Order Matters:**
    
    - Rules are processed **top-down**.
    - Ensure blocking rules are at the **top**; otherwise, an earlier `ALLOW` rule might override them.
    - Example:
        
        ```bash
        iptables -I INPUT -p tcp --dport 80 -s 10.0.0.1 -j ACCEPT
        ```
        
        - This **allows** traffic from `10.0.0.1` to port `80` **before** blocking all other traffic.

### **6. Deleting Rules**

- **List Rules with Line Numbers:**
    
    ```bash
    iptables -L --line-numbers
    ```
    
- **Delete a Specific Rule:**
    
    ```bash
    iptables -D INPUT 1
    ```
    
    - Removes **rule #1** from the `INPUT` chain.

### **7. Saving and Resetting Rules**

- **To Save iptables Rules:**
    
    ```bash
    sudo iptables-save
    ```
    
- **To Flush (Reset) All Rules:**
    
    ```bash
    sudo iptables -F
    ```
    

### **8. Common iptables Flags Recap**

|Flag|Description|
|---|---|
|`-A`|Append rule to the end of the chain|
|`-I`|Insert rule at the top of the chain|
|`-s`|Specify source IP address|
|`-p`|Specify protocol (TCP/UDP)|
|`--dport`|Specify destination port|
|`-j`|Set target (ACCEPT, REJECT, DROP)|
|`-D`|Delete a rule by number|
|`-L`|List all rules|
|`--policy`|Set default policy for a chain|
|`-F`|Flush all rules|

---

note that i cant be fucked to deal with ipv6 and we should just disable it so we can focus more on securing our v4 addresses

check if you have an ipv6 address with `ip -c a`

to disable ipv6
`sudo nano /etc/sysctl.conf`
add this to bottom
```
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
```
then apply with 
`sudo sysctl -p`