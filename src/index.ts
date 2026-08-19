import { DurableObject } from "cloudflare:workers";

type Need = "hunger" | "thirst" | "energy" | "health";
type Action = "wander" | "drink" | "gather_berries" | "eat" | "rest" | "observe";

type Human = {
  id: string;
  name: string;
  sex: "female" | "male";
  ageDays: number;
  x: number;
  y: number;
  needs: Record<Need, number>;
  traits: { curiosity: number; courage: number; sociability: number; diligence: number };
  inventory: { berries: number; wood: number; stone: number };
  action: Action;
  thought: string;
  memories: Array<{ day: number; text: string; importance: number }>;
  divineMessages: Array<{ day: number; text: string }>;
};

type Resource = { id: string; kind: "water" | "berries" | "tree" | "stone"; x: number; y: number; amount: number };

type WorldState = {
  version: 1;
  seed: number;
  minute: number;
  speed: 1 | 4 | 16;
  paused: boolean;
  lastRealMs: number;
  humans: Human[];
  resources: Resource[];
  history: Array<{ minute: number; text: string }>;
};

const clamp = (n: number) => Math.max(0, Math.min(100, n));
const dist = (a: { x: number; y: number }, b: { x: number; y: number }) => Math.hypot(a.x - b.x, a.y - b.y);

function seeded(seed: number) {
  let s = seed >>> 0;
  return () => ((s = Math.imul(1664525, s) + 1013904223 >>> 0) / 4294967296);
}

function makeWorld(): WorldState {
  const seed = 137042;
  const rnd = seeded(seed);
  const resources: Resource[] = [];
  for (let i = 0; i < 44; i++) resources.push({ id: `tree-${i}`, kind: "tree", x: 40 + rnd() * 920, y: 40 + rnd() * 620, amount: 100 });
  for (let i = 0; i < 18; i++) resources.push({ id: `berry-${i}`, kind: "berries", x: 40 + rnd() * 920, y: 40 + rnd() * 620, amount: 8 + Math.floor(rnd() * 12) });
  for (let i = 0; i < 24; i++) resources.push({ id: `stone-${i}`, kind: "stone", x: 40 + rnd() * 920, y: 40 + rnd() * 620, amount: 30 });
  for (let i = 0; i < 14; i++) resources.push({ id: `water-${i}`, kind: "water", x: 70 + i * 66, y: 330 + Math.sin(i * 0.8) * 70, amount: 999999 });

  const human = (id: string, name: string, sex: "female" | "male", x: number, y: number, traits: Human["traits"]): Human => ({
    id, name, sex, ageDays: 20 * 365, x, y,
    needs: { hunger: 15, thirst: 12, energy: 10, health: 100 },
    traits, inventory: { berries: 2, wood: 0, stone: 0 }, action: "observe",
    thought: "I am awake. This place is new.", memories: [{ day: 0, text: "I awoke beneath an open sky beside another like me.", importance: 100 }], divineMessages: []
  });

  return {
    version: 1, seed, minute: 0, speed: 1, paused: false, lastRealMs: Date.now(), resources,
    humans: [
      human("elara", "Elara", "female", 480, 300, { curiosity: 82, courage: 61, sociability: 76, diligence: 70 }),
      human("rowan", "Rowan", "male", 520, 320, { curiosity: 65, courage: 78, sociability: 69, diligence: 63 })
    ],
    history: [{ minute: 0, text: "Elara and Rowan awaken. Humanity begins." }]
  };
}

export class GenesisWorld extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);
    ctx.blockConcurrencyWhile(async () => {
      this.ctx.storage.sql.exec(`CREATE TABLE IF NOT EXISTS world_state (id INTEGER PRIMARY KEY CHECK(id=1), json TEXT NOT NULL)`);
      const row = this.ctx.storage.sql.exec<{ json: string }>("SELECT json FROM world_state WHERE id=1").toArray()[0];
      if (!row) this.save(makeWorld());
    });
  }

  private load(): WorldState {
    const row = this.ctx.storage.sql.exec<{ json: string }>("SELECT json FROM world_state WHERE id=1").one();
    return JSON.parse(row.json) as WorldState;
  }

  private save(state: WorldState) {
    this.ctx.storage.sql.exec("INSERT OR REPLACE INTO world_state(id,json) VALUES(1,?)", JSON.stringify(state));
  }

  private nearest(state: WorldState, h: Human, kind: Resource["kind"]) {
    return state.resources.filter(r => r.kind === kind && r.amount > 0).sort((a, b) => dist(h, a) - dist(h, b))[0];
  }

  private moveToward(h: Human, target: { x: number; y: number }, step = 5) {
    const d = Math.max(0.001, dist(h, target));
    h.x += ((target.x - h.x) / d) * Math.min(step, d);
    h.y += ((target.y - h.y) / d) * Math.min(step, d);
  }

  private think(state: WorldState, h: Human) {
    if (h.needs.thirst > 68) { h.action = "drink"; h.thought = "I need water. Nothing matters more right now."; return; }
    if (h.needs.hunger > 66 && h.inventory.berries > 0) { h.action = "eat"; h.thought = "My stomach aches. I should eat what I have."; return; }
    if (h.needs.hunger > 48) { h.action = "gather_berries"; h.thought = "I need to find something edible."; return; }
    if (h.needs.energy > 78) { h.action = "rest"; h.thought = "My body is exhausted. I need to stop."; return; }
    h.action = "wander";
    h.thought = h.traits.curiosity > 70 ? "I want to know what lies beyond what I can see." : "I should stay alert and learn this place.";
  }

  private tick(state: WorldState, minutes: number) {
    const steps = Math.min(720, Math.max(1, Math.ceil(minutes / 5)));
    const dt = minutes / steps;
    const rnd = seeded(state.seed + Math.floor(state.minute));
    for (let s = 0; s < steps; s++) {
      state.minute += dt;
      for (const h of state.humans) {
        h.ageDays += dt / 1440;
        h.needs.hunger = clamp(h.needs.hunger + 0.028 * dt);
        h.needs.thirst = clamp(h.needs.thirst + 0.045 * dt);
        h.needs.energy = clamp(h.needs.energy + 0.022 * dt);
        if (h.needs.hunger > 94 || h.needs.thirst > 94) h.needs.health = clamp(h.needs.health - 0.035 * dt);
        this.think(state, h);

        if (h.action === "drink") {
          const r = this.nearest(state, h, "water");
          if (r) { if (dist(h, r) > 13) this.moveToward(h, r); else h.needs.thirst = clamp(h.needs.thirst - 1.2 * dt); }
        } else if (h.action === "gather_berries") {
          const r = this.nearest(state, h, "berries");
          if (r) { if (dist(h, r) > 12) this.moveToward(h, r); else if (r.amount > 0) { r.amount--; h.inventory.berries++; h.needs.energy = clamp(h.needs.energy + 0.5); } }
        } else if (h.action === "eat") {
          if (h.inventory.berries > 0) { h.inventory.berries--; h.needs.hunger = clamp(h.needs.hunger - 24); }
        } else if (h.action === "rest") {
          h.needs.energy = clamp(h.needs.energy - 0.8 * dt);
        } else {
          h.x = Math.max(20, Math.min(980, h.x + (rnd() - 0.5) * 9));
          h.y = Math.max(20, Math.min(680, h.y + (rnd() - 0.5) * 9));
        }
      }
    }
  }

  private advance(state: WorldState) {
    const now = Date.now();
    if (!state.paused) {
      const elapsedRealMinutes = Math.min(24 * 60, Math.max(0, (now - state.lastRealMs) / 60000));
      this.tick(state, elapsedRealMinutes * state.speed * 12);
    }
    state.lastRealMs = now;
  }

  async snapshot(): Promise<WorldState> {
    const state = this.load(); this.advance(state); this.save(state); return state;
  }

  async command(command: { type: string; humanId?: string; text?: string; speed?: number }): Promise<WorldState> {
    const state = this.load(); this.advance(state);
    if (command.type === "pause") state.paused = true;
    if (command.type === "resume") state.paused = false;
    if (command.type === "speed" && [1, 4, 16].includes(command.speed ?? 0)) state.speed = command.speed as 1 | 4 | 16;
    if (command.type === "speak" && command.humanId && command.text?.trim()) {
      const h = state.humans.find(x => x.id === command.humanId);
      if (h) {
        const text = command.text.trim().slice(0, 500);
        h.divineMessages.unshift({ day: Math.floor(state.minute / 1440), text });
        h.memories.unshift({ day: Math.floor(state.minute / 1440), text: `The Creator spoke to me: “${text}”`, importance: 100 });
        h.thought = `The Creator spoke to me. I must understand: “${text}”`;
        state.history.push({ minute: state.minute, text: `The Creator spoke to ${h.name}: “${text}”` });
      }
    }
    state.lastRealMs = Date.now(); this.save(state); return state;
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname.startsWith("/api/")) {
      const world = env.WORLDS.getByName("genesis-primary");
      if (url.pathname === "/api/world" && request.method === "GET") return Response.json(await world.snapshot());
      if (url.pathname === "/api/command" && request.method === "POST") {
        const command = await request.json() as { type: string; humanId?: string; text?: string; speed?: number };
        return Response.json(await world.command(command));
      }
      return Response.json({ error: "Not found" }, { status: 404 });
    }
    return env.ASSETS.fetch(request);
  }
} satisfies ExportedHandler<Env>;
