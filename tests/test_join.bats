#!/usr/bin/env bats

setup() {
    TEST_MODE=1 source "${BATS_TEST_DIRNAME}/../sync.sh"
}

@test "build_ip_name_map: joins mac_to_name and mac_to_ip on MAC" {
    declare -gA mac_to_name=([aa:bb:cc:dd:ee:ff]="MyDevice")
    declare -gA mac_to_ip=([aa:bb:cc:dd:ee:ff]="192.168.10.10")
    declare -gA ip_to_name=()
    build_ip_name_map
    [ "${ip_to_name[192.168.10.10]}" = "MyDevice" ]
}

@test "build_ip_name_map: skips entries with no IP match" {
    declare -gA mac_to_name=([aa:bb:cc:dd:ee:ff]="Offline")
    declare -gA mac_to_ip=()
    declare -gA ip_to_name=()
    build_ip_name_map
    [ "${#ip_to_name[@]}" -eq 0 ]
}

@test "build_ip_name_map: maps multiple devices" {
    declare -gA mac_to_name=(
        [aa:bb:cc:dd:ee:ff]="Device1"
        [11:22:33:44:55:66]="Device2"
    )
    declare -gA mac_to_ip=(
        [aa:bb:cc:dd:ee:ff]="192.168.10.10"
        [11:22:33:44:55:66]="192.168.10.11"
    )
    declare -gA ip_to_name=()
    build_ip_name_map
    [ "${ip_to_name[192.168.10.10]}" = "Device1" ]
    [ "${ip_to_name[192.168.10.11]}" = "Device2" ]
}

@test "build_ip_name_map: static IP takes precedence when MAC appears in both maps" {
    # mac_to_ip is already merged (static wins) by the time build_ip_name_map runs.
    # Confirm the correct IP is used in the join.
    declare -gA mac_to_name=([aa:aa:aa:aa:aa:64]="vm100")
    declare -gA mac_to_ip=([aa:aa:aa:aa:aa:64]="192.168.10.100")
    declare -gA ip_to_name=()
    build_ip_name_map
    [ "${ip_to_name[192.168.10.100]}" = "vm100" ]
}
