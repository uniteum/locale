# locale

> Immutable utility contracts at deterministic addresses, with data native to each network.

---

## Concept

A `locale` contract is a fixed point of reference. Its address is predictable — derivable before deployment, identical across networks. Its contents are not: each instance is initialized once with chain-specific data and can never be changed.

Query the same address on any supported network and you get the truth for that network.

---

## Properties

- **Deterministic addresses** — deployed via `CREATE2` so the address is known before deployment
- **Immutable data** — initialized once; no owner, no upgrade path, no admin functions
- **Chain-aware** — same structure everywhere, different contents per network
- **Minimal** — no dependencies, no inheritance overhead; pure reference contracts

---

## Deployment

Addresses are consistent across all supported networks. A full deployment manifest is maintained in [`deployments/`](./deployments/).

---

## License

MIT
