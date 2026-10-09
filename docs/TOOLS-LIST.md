# Danh sách toàn bộ tools

## Global

```text
./bin/netadmin help
./bin/netadmin --help
./bin/netadmin version
./bin/netadmin --version
./bin/netadmin <module> help
```

## Doctor

```text
./bin/netadmin doctor
./bin/netadmin doctor run
./bin/netadmin doctor help
```

## DHCP

```text
./bin/netadmin dhcp help
./bin/netadmin dhcp install
./bin/netadmin dhcp scope add <name> <subnet> <netmask> <start-ip> <end-ip> <gateway> <dns[,dns]> [domain] [lease-seconds]
./bin/netadmin dhcp scope update <name> <subnet> <netmask> <start-ip> <end-ip> <gateway> <dns[,dns]> [domain] [lease-seconds]
./bin/netadmin dhcp scope list
./bin/netadmin dhcp scope remove <name>
./bin/netadmin dhcp reservation add <name> <mac> <ip> [hostname]
./bin/netadmin dhcp reservation list
./bin/netadmin dhcp reservation remove <name>
./bin/netadmin dhcp lease list
./bin/netadmin dhcp lease release <ip>
./bin/netadmin dhcp config show
./bin/netadmin dhcp config check
./bin/netadmin dhcp config rollback
./bin/netadmin dhcp service start
./bin/netadmin dhcp service stop
./bin/netadmin dhcp service restart
./bin/netadmin dhcp service status
./bin/netadmin dhcp service enable
./bin/netadmin dhcp service enable-now
```

## DNS

```text
./bin/netadmin dns help
./bin/netadmin dns install
./bin/netadmin dns network list
./bin/netadmin dns network static <connection> <address/prefix> <gateway> <dns[,dns]>
./bin/netadmin dns network dhcp <connection>
./bin/netadmin dns zone add <domain> <server-ip> [admin-label]
./bin/netadmin dns zone add-reverse <reverse-zone> <server-fqdn>
./bin/netadmin dns zone add-secondary <domain> <primary-ip>
./bin/netadmin dns zone list
./bin/netadmin dns zone remove <domain-or-zone>
./bin/netadmin dns record add <zone> <name> <A|AAAA|CNAME|MX|NS|TXT|PTR> <value> [ttl]
./bin/netadmin dns record list <zone>
./bin/netadmin dns record remove <zone> <name> <type>
./bin/netadmin dns transfer allow <zone> <secondary-ip>
./bin/netadmin dns forwarders set <ip[,ip]>
./bin/netadmin dns forwarders clear
./bin/netadmin dns query <name> [server]
./bin/netadmin dns config show
./bin/netadmin dns config check
./bin/netadmin dns config rollback
./bin/netadmin dns service start
./bin/netadmin dns service stop
./bin/netadmin dns service restart
./bin/netadmin dns service status
./bin/netadmin dns service enable
./bin/netadmin dns service enable-now
```

## Storage

```text
./bin/netadmin storage help
./bin/netadmin storage disk list
./bin/netadmin storage disk free <device>
./bin/netadmin storage partition create <device> <start> <end> [gpt|msdos]
./bin/netadmin storage filesystem list
./bin/netadmin storage filesystem format <partition> <xfs|ext4|ext3> [label]
./bin/netadmin storage filesystem mount <partition> <mountpoint> [options]
./bin/netadmin storage lvm install
./bin/netadmin storage lvm list
./bin/netadmin storage lvm pv-create <partition>
./bin/netadmin storage lvm vg-create <vg> <pv>
./bin/netadmin storage lvm vg-extend <vg> <pv>
./bin/netadmin storage lvm lv-create <vg> <lv> <size>
./bin/netadmin storage lvm lv-extend <lv-path> <size>
./bin/netadmin storage quota enable <mountpoint>
./bin/netadmin storage quota set <mountpoint> <user> <soft-blocks> <hard-blocks> <soft-inodes> <hard-inodes>
./bin/netadmin storage quota report <mountpoint>
```

## Samba

```text
./bin/netadmin samba help
./bin/netadmin samba install
./bin/netadmin samba share add-public <name> <path> [read-only|read-write]
./bin/netadmin samba share add-group <name> <path> <group> [read-only|read-write]
./bin/netadmin samba share list
./bin/netadmin samba share remove <name>
./bin/netadmin samba user add <username> <group>
./bin/netadmin samba user remove <username>
./bin/netadmin samba user list
./bin/netadmin samba permissions grant <share> <username|@group> <read|write>
./bin/netadmin samba status
./bin/netadmin samba sessions
./bin/netadmin samba config show
./bin/netadmin samba config check
./bin/netadmin samba config apply
./bin/netadmin samba config rollback
./bin/netadmin samba service start
./bin/netadmin samba service stop
./bin/netadmin samba service restart
./bin/netadmin samba service status
./bin/netadmin samba service enable
./bin/netadmin samba service enable-now
./bin/netadmin samba client list //<server>/<share> [username]
./bin/netadmin samba client copy //<server>/<share> <remote-item> <destination> [username]
```

## Environment variables

```text
NETADMIN_CONFIG
NETADMIN_DRY_RUN
NETADMIN_ASSUME_YES
NETADMIN_ROOT
NETADMIN_BACKUP_DIR
NO_COLOR
DHCP_CONFIG
DHCP_LEASES
DNS_CONFIG
DNS_MANAGED_CONFIG
DNS_ZONE_DIR
SAMBA_CONFIG
```

## Core system tools

```text
bash
cat
printf
read
source
command
test
awk
sed
grep
cut
tr
find
sort
head
date
mktemp
install
cp
mv
mkdir
rm
dnf
yum
rpm
systemctl
firewall-cmd
semanage
restorecon
chcon
chown
chmod
```

## Network and DNS system tools

```text
ip
nmcli
named
named-checkconf
named-checkzone
dig
```

## DHCP system tools

```text
dhcpd
omshell
```

## Storage system tools

```text
lsblk
parted
partprobe
udevadm
mkfs.xfs
mkfs.ext4
mkfs.ext3
blkid
mount
umount
mountpoint
findmnt
xfs_growfs
resize2fs
pvcreate
vgcreate
vgextend
lvcreate
lvextend
pvs
vgs
lvs
quotacheck
quotaon
setquota
repquota
df
du
```

## Samba system tools

```text
testparm
smbstatus
smbpasswd
pdbedit
smbclient
mount.cifs
groupadd
useradd
usermod
id
getent
```

## Diagnostic tools

```text
journalctl
ss
ping
traceroute
tcpdump
namei
hostnamectl
```
