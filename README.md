# Genesis Project

A persistent browser-based god simulation beginning with two autonomous humans and an untouched world.

## Genesis v0.01

The first vertical slice focuses on making two individual humans interesting before adding civilization-scale systems.

- Persistent world state
- Two autonomous original humans
- Needs: hunger, thirst, energy, health
- Personality traits and independent utility-based decisions
- Perception and memories
- Physical resources: water, trees, stone, berry bushes
- Gathering, eating, drinking, sleeping and wandering
- Creator observation and divine messages
- World history/event log
- Responsive desktop/mobile world view
- Architecture ready for reproduction, construction, knowledge, families and settlements

## Architecture

- Cloudflare Worker
- SQLite-backed Durable Object per world
- Workers Static Assets frontend
- Canvas-based 2D simulation view
- TypeScript

The simulation is authoritative on the server. Clients are windows into the same persistent world.
