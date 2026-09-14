#!/usr/bin/env bats

setup() {
    # Source sync.sh without running main()
    TEST_MODE=1 source "${BATS_TEST_DIRNAME}/../sync.sh"
}

# ── parse_clientlist ──────────────────────────────────────────────────────────

@test "parse_clientlist: extracts name and normalises MAC to lowercase" {
    declare -gA mac_to_name=()
    parse_clientlist "MyDevice>AA:BB:CC:DD:EE:FF>0>0>>>>>"
    [ "${mac_to_name[aa:bb:cc:dd:ee:ff]}" = "MyDevice" ]
}

@test "parse_clientlist: handles multiple entries separated by <" {
    declare -gA mac_to_name=()
    parse_clientlist "Device1>AA:BB:CC:DD:EE:FF>0>0>>>>><Device2>11:22:33:44:55:66>0>0>>>>>"
    [ "${mac_to_name[aa:bb:cc:dd:ee:ff]}" = "Device1" ]
    [ "${mac_to_name[11:22:33:44:55:66]}" = "Device2" ]
}

@test "parse_clientlist: skips empty entries" {
    declare -gA mac_to_name=()
    parse_clientlist "<Device1>AA:BB:CC:DD:EE:FF>0>0>>>>><"
    [ "${#mac_to_name[@]}" -eq 1 ]
}

@test "parse_clientlist: preserves names with spaces and apostrophes" {
    declare -gA mac_to_name=()
    parse_clientlist "Test User's iPhone>AA:BB:CC:DD:EE:FF>0>10>>>>>"
    [ "${mac_to_name[aa:bb:cc:dd:ee:ff]}" = "Test User's iPhone" ]
}

# ── parse_staticlist ──────────────────────────────────────────────────────────

@test "parse_staticlist: extracts MAC and IP, normalises MAC to lowercase" {
    declare -gA mac_to_ip=()
    parse_staticlist "<aa:aa:aa:aa:aa:64>192.168.10.100>>vm100"
    [ "${mac_to_ip[aa:aa:aa:aa:aa:64]}" = "192.168.10.100" ]
}

@test "parse_staticlist: handles multiple entries with leading <" {
    declare -gA mac_to_ip=()
    parse_staticlist "<aa:aa:aa:aa:aa:64>192.168.10.100>>vm100<aa:aa:aa:aa:aa:65>192.168.10.101>>vm101"
    [ "${mac_to_ip[aa:aa:aa:aa:aa:64]}" = "192.168.10.100" ]
    [ "${mac_to_ip[aa:aa:aa:aa:aa:65]}" = "192.168.10.101" ]
}

@test "parse_staticlist: empty input produces empty map" {
    declare -gA mac_to_ip=()
    parse_staticlist ""
    [ "${#mac_to_ip[@]}" -eq 0 ]
}

# ── parse_arp ─────────────────────────────────────────────────────────────────

@test "parse_arp: extracts IP and normalises MAC to lowercase for complete entries" {
    declare -gA mac_to_ip=()
    parse_arp "192.168.10.100   0x1         0x2         aa:aa:aa:aa:aa:64     *        br0"
    [ "${mac_to_ip[aa:aa:aa:aa:aa:64]}" = "192.168.10.100" ]
}

@test "parse_arp: skips incomplete entries (flags != 0x2)" {
    declare -gA mac_to_ip=()
    parse_arp "192.168.10.14    0x1         0x0         00:00:00:00:00:00     *        br0"
    [ "${#mac_to_ip[@]}" -eq 0 ]
}

@test "parse_arp: skips zero MAC addresses" {
    declare -gA mac_to_ip=()
    parse_arp "192.168.10.14    0x1         0x2         00:00:00:00:00:00     *        br0"
    [ "${#mac_to_ip[@]}" -eq 0 ]
}

@test "parse_arp: does not overwrite entries already set by parse_staticlist" {
    declare -gA mac_to_ip=([aa:aa:aa:aa:aa:64]="192.168.10.100")
    parse_arp "192.168.10.99    0x1         0x2         aa:aa:aa:aa:aa:64     *        br0"
    [ "${mac_to_ip[aa:aa:aa:aa:aa:64]}" = "192.168.10.100" ]
}

@test "parse_arp: handles multiple entries across different VLANs" {
    declare -gA mac_to_ip=()
    parse_arp "$(printf '192.168.20.163   0x1         0x2         bb:bb:bb:bb:bb:01     *        br52\n192.168.40.101   0x1         0x2         aa:aa:aa:aa:aa:65     *        br53')"
    [ "${mac_to_ip[bb:bb:bb:bb:bb:01]}" = "192.168.20.163" ]
    [ "${mac_to_ip[aa:aa:aa:aa:aa:65]}" = "192.168.40.101" ]
}

@test "parse_arp: empty input produces empty map" {
    declare -gA mac_to_ip=()
    parse_arp ""
    [ "${#mac_to_ip[@]}" -eq 0 ]
}

# ── parse_leases ──────────────────────────────────────────────────────────────

@test "parse_leases: extracts MAC and IP from lease line" {
    declare -gA mac_to_ip=()
    parse_leases "86274 aa:aa:aa:aa:aa:64 192.168.10.100 vm100 ff:aa:aa:aa:aa:aa:64"
    [ "${mac_to_ip[aa:aa:aa:aa:aa:64]}" = "192.168.10.100" ]
}

@test "parse_leases: does not overwrite existing static entries" {
    declare -gA mac_to_ip=([aa:aa:aa:aa:aa:64]="192.168.10.100")
    parse_leases "86274 aa:aa:aa:aa:aa:64 10.0.0.99 vm100 *"
    [ "${mac_to_ip[aa:aa:aa:aa:aa:64]}" = "192.168.10.100" ]
}

@test "parse_leases: handles multiple lines" {
    declare -gA mac_to_ip=()
    parse_leases "$(printf '86274 aa:bb:cc:dd:ee:ff 192.168.10.1 host1 *\n86274 11:22:33:44:55:66 192.168.10.2 host2 *')"
    [ "${mac_to_ip[aa:bb:cc:dd:ee:ff]}" = "192.168.10.1" ]
    [ "${mac_to_ip[11:22:33:44:55:66]}" = "192.168.10.2" ]
}

@test "parse_leases: normalises MAC to lowercase" {
    declare -gA mac_to_ip=()
    parse_leases "86274 AA:BB:CC:DD:EE:FF 192.168.10.1 host1 *"
    [ "${mac_to_ip[aa:bb:cc:dd:ee:ff]}" = "192.168.10.1" ]
}

# ── parse_lease_hostnames ─────────────────────────────────────────────────────

@test "parse_lease_hostnames: adds DHCP hostname to mac_to_name for unnamed device" {
    declare -gA mac_to_name=()
    parse_lease_hostnames "86199 cc:cc:cc:cc:cc:07 192.168.10.7 p1g2 01:cc:cc:cc:cc:cc:07"
    [ "${mac_to_name[cc:cc:cc:cc:cc:07]}" = "p1g2" ]
}

@test "parse_lease_hostnames: does not overwrite custom_clientlist name" {
    declare -gA mac_to_name=([cc:cc:cc:cc:cc:07]="My PC")
    parse_lease_hostnames "86199 cc:cc:cc:cc:cc:07 192.168.10.7 p1g2 01:cc:cc:cc:cc:cc:07"
    [ "${mac_to_name[cc:cc:cc:cc:cc:07]}" = "My PC" ]
}

@test "parse_lease_hostnames: skips entries with asterisk hostname" {
    declare -gA mac_to_name=()
    parse_lease_hostnames "86199 aa:bb:cc:dd:ee:ff 192.168.10.7 * 01:aa:bb:cc:dd:ee:ff"
    [ "${#mac_to_name[@]}" -eq 0 ]
}

@test "parse_lease_hostnames: handles multiple leases, sets all unnamed" {
    declare -gA mac_to_name=()
    parse_lease_hostnames "$(printf \
        '86199 cc:cc:cc:cc:cc:07 192.168.10.7 p1g2 *\n86382 cc:cc:cc:cc:cc:32 192.168.10.32 x1y4 *')"
    [ "${mac_to_name[cc:cc:cc:cc:cc:07]}" = "p1g2" ]
    [ "${mac_to_name[cc:cc:cc:cc:cc:32]}" = "x1y4" ]
}

@test "parse_lease_hostnames: normalises MAC to lowercase" {
    declare -gA mac_to_name=()
    parse_lease_hostnames "86199 cc:cc:cc:cc:cc:07 192.168.10.7 p1g2 *"
    [ "${mac_to_name[cc:cc:cc:cc:cc:07]}" = "p1g2" ]
}

@test "parse_lease_hostnames: empty input produces empty map" {
    declare -gA mac_to_name=()
    parse_lease_hostnames ""
    [ "${#mac_to_name[@]}" -eq 0 ]
}
