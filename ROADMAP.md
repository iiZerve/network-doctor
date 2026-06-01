# Network Doctor Roadmap

## Current Status (v0.x)

- [x] Advanced real-time monitoring with latency/jitter/loss tracking
- [x] Automatic home network vs tether detection
- [x] Structured logging (CSV + JSONL + human readable)
- [x] Manual observation logging (especially gateway LED states)
- [x] Deep Wi-Fi diagnostics focused on Intel AX201 + Hitron gateways
- [x] Stability and Speed optimization profiles
- [x] One-click Rogers/Shaw Support Report generator

## Near-term Goals

- [ ] Improved visual outage timeline / summary
- [ ] Better support for generating before/after reports
- [ ] Add more adapter-specific recommendations (AX210, AX211, BE200, etc.)
- [ ] Support for logging gateway light states more automatically (user-guided)
- [ ] Exportable Markdown/HTML reports

## Longer-term Ideas

- [ ] Background/scheduled monitoring mode
- [ ] Integration with common third-party routers (when user is in bridge mode)
- [ ] Web dashboard (optional, for advanced users)
- [ ] Cross-platform support (limited, since this is heavily Windows + Wi-Fi focused)
- [ ] Community-contributed profiles for different ISPs/gateways

## Known Limitations

- Cannot directly query or control the Hitron CGM4331SHW (no public API)
- Heavily dependent on the user accurately reporting gateway LED behavior
- Client-side only — cannot fix ISP plant issues

Pull requests and ideas are very welcome!
