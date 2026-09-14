# router-sync

Syncs an ASUS router's DHCP/ARP client data (name + IP, joined from
`custom_clientlist`, `dhcp_staticlist`, `/proc/net/arp`, and dnsmasq leases)
into AdGuard Home's custom clients via its API, so AGH's per-client stats
and query log show real device names instead of bare IPs.

Runs on a cron interval (`SYNC_INTERVAL_MINUTES`, default 10) inside the
container; see `entrypoint.sh`.

Deployment config (compose file, secrets, `known_hosts` for the specific
router being synced) lives in [`laforcem/homelab`](https://github.com/laforcem/homelab)'s
`router-sync/` directory — this repo is just the image source.

## Required environment

See `.env.example`. `ROUTER_HOST`/`ROUTER_USER` (+ an SSH key mounted at
`/root/.ssh/id_ed25519`) for the router; `AGH_URL`/`AGH_USER`/`AGH_PASSWORD`
for AdGuard Home's API.

## Tests

```
bats tests/
```
