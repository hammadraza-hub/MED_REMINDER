/* eslint-disable no-console */
// M21 step 1: asks the REAL firestore.rules (on the emulator) what different
// people can do, so the audit does not rely on reading the rules only.
//
//   firebase emulators:start --only auth,firestore --project medapp-staging
//   node tools/audit_rules_probe.js
//
// It only prints a table; it changes no file and no real data (emulator only,
// and it wipes the emulator's Firestore like the jest rules tests do).
//
// Each row: who | what | what the rules said | what is expected | verdict.
// "GAP" means the rules allowed something they should not (or the other way
// round); "ok" means the rules behaved as the plan says.

const fs = require("fs");
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");
const {
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  collection,
  query,
  where,
  serverTimestamp,
} = require("firebase/firestore");

const RULES = fs.readFileSync("firestore.rules", "utf8");
const rows = [];

async function can(promise) {
  try {
    await assertSucceeds(promise);
    return true;
  } catch (_) {
    try {
      await assertFails(promise);
    } catch (_) {
      /* neither: treat as denied */
    }
    return false;
  }
}

function record(who, what, allowed, expectAllowed) {
  rows.push({
    who,
    what,
    rules: allowed ? "ALLOWED" : "denied",
    expected: expectAllowed ? "allowed" : "denied",
    verdict: allowed === expectAllowed ? "ok" : "GAP",
  });
}

async function seed(env) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "profiles", "p1"), {
      ownerUid: "owner",
      kind: "self",
      name: "Patient One",
      timezone: "UTC",
      dob: "1950-01-01",
      conditions: ["diabetes"],
      roles: { owner: "owner", cg: "caregiver", cgNone: "caregiver", viewer: "viewer" },
      memberUids: ["owner", "cg", "cgNone", "viewer"],
      healthUids: ["owner", "cg"],
      permissions: { cg: { editMedications: true, logDoses: true } },
    });
    await setDoc(doc(db, "profiles", "p2"), {
      ownerUid: "other",
      kind: "self",
      name: "Somebody Else",
      timezone: "UTC",
      roles: { other: "owner" },
      memberUids: ["other"],
      healthUids: ["other"],
      permissions: {},
    });
    const sub = (name, id, data) =>
      setDoc(doc(db, "profiles", "p1", name, id), data);
    await sub("medications", "m1", { name: "Metformin", profileId: "p1", status: "active" });
    await sub("doses", "d1", { status: "pending", medicationId: "m1" });
    await sub("allergies", "a1", { name: "Penicillin" });
    await sub("vitals", "v1", { type: "weight", value: 70 });
    await sub("symptoms", "s1", { symptom: "x" });
    await sub("prescribers", "pr1", { name: "Dr" });
    await sub("appointments", "ap1", { type: "checkup" });
    await sub("doctorNotes", "n1", { body: "x" });
    await sub("pharmacies", "ph1", { name: "Pharm" });
    await sub("dailySummaries", "2026-01-01", { taken: 1 });
    await setDoc(doc(db, "profiles", "p1", "medications", "m1", "inventoryEvents", "e1"), { delta: -1 });
    await setDoc(doc(db, "users", "owner"), { email: "o@example.com" });
    await setDoc(doc(db, "users", "stranger"), { email: "s@example.com" });
  });
}

async function readProbes(env) {
  const people = {
    "signed-out": env.unauthenticatedContext(),
    stranger: env.authenticatedContext("stranger"),
    viewer: env.authenticatedContext("viewer"),
    "caregiver(no health)": env.authenticatedContext("cgNone"),
    caregiver: env.authenticatedContext("cg"),
    owner: env.authenticatedContext("owner"),
  };

  // Who may read each profile subcollection (get one doc, and list the lot).
  // expected: [signed-out, stranger, viewer, cgNone, cg, owner]
  const sub = {
    medications: [0, 0, 1, 1, 1, 1],
    doses: [0, 0, 1, 1, 1, 1],
    pharmacies: [0, 0, 1, 1, 1, 1],
    dailySummaries: [0, 0, 1, 1, 1, 1],
    allergies: [0, 0, 1, 1, 1, 1],
    // health records: only people in healthUids
    vitals: [0, 0, 0, 0, 1, 1],
    symptoms: [0, 0, 0, 0, 1, 1],
    prescribers: [0, 0, 0, 0, 1, 1],
    appointments: [0, 0, 0, 0, 1, 1],
    doctorNotes: [0, 0, 0, 0, 1, 1],
  };
  const ids = {
    medications: "m1", doses: "d1", pharmacies: "ph1", dailySummaries: "2026-01-01",
    allergies: "a1", vitals: "v1", symptoms: "s1", prescribers: "pr1",
    appointments: "ap1", doctorNotes: "n1",
  };
  const names = Object.keys(people);
  for (const [name, expected] of Object.entries(sub)) {
    for (let i = 0; i < names.length; i++) {
      const db = people[names[i]].firestore();
      const g = await can(getDoc(doc(db, "profiles", "p1", name, ids[name])));
      record(names[i], `get  profiles/p1/${name}/x`, g, !!expected[i]);
      const l = await can(getDocs(collection(db, "profiles", "p1", name)));
      record(names[i], `LIST profiles/p1/${name}`, l, !!expected[i]);
    }
  }

  // The profile document itself.
  for (let i = 0; i < names.length; i++) {
    const db = people[names[i]].firestore();
    const exp = [0, 0, 1, 1, 1, 1][i];
    record(names[i], "get  profiles/p1", await can(getDoc(doc(db, "profiles", "p1"))), !!exp);
  }
  // LIST of ALL profiles with no filter at all: nobody should be able to.
  for (const n of ["signed-out", "stranger", "viewer", "owner"]) {
    const db = people[n].firestore();
    record(n, "LIST profiles (no filter)", await can(getDocs(collection(db, "profiles"))), false);
  }
  // The query the app really runs: only my own profiles.
  for (const n of ["stranger", "owner"]) {
    const uid = n === "owner" ? "owner" : "stranger";
    const db = people[n].firestore();
    record(
      n,
      "LIST profiles where memberUids array-contains me",
      await can(getDocs(query(collection(db, "profiles"), where("memberUids", "array-contains", uid)))),
      true,
    );
  }
  // The profile of ANOTHER person, asked as "mine" (must still be refused).
  record(
    "stranger",
    "LIST profiles where memberUids array-contains owner",
    await can(getDocs(query(collection(people.stranger.firestore(), "profiles"), where("memberUids", "array-contains", "owner")))),
    false,
  );
}

async function writeProbes(env) {
  const cg = env.authenticatedContext("cg").firestore();
  const owner = env.authenticatedContext("owner").firestore();
  const cgNone = env.authenticatedContext("cgNone").firestore();
  const viewer = env.authenticatedContext("viewer").firestore();

  // Server-only fields on the profile itself.
  for (const [who, db] of [["owner", owner], ["caregiver", cg]]) {
    record(who, "profile: add self to roles/memberUids", await can(updateDoc(doc(db, "profiles", "p1"), { memberUids: ["owner", "cg", "cgNone", "viewer", who] })), false);
  }
  record("owner", "profile: change ownerUid", await can(updateDoc(doc(owner, "profiles", "p1"), { ownerUid: "cg" })), false);
  record("owner", "profile: edit name", await can(updateDoc(doc(owner, "profiles", "p1"), { name: "New" })), true);
  record("owner", "profile: grant a caregiver more permissions", await can(updateDoc(doc(owner, "profiles", "p1"), { "permissions.cgNone": { editMedications: true } })), false);

  // Medications: server-maintained fields.
  const med = (db) => doc(db, "profiles", "p1", "medications", "m1");
  record("owner", "medication: write quantityOnHand", await can(updateDoc(med(owner), { quantityOnHand: 999, updatedAt: serverTimestamp() })), false);
  record("owner", "medication: write flags", await can(updateDoc(med(owner), { flags: { lowStock: true }, updatedAt: serverTimestamp() })), false);
  record("owner", "medication: change status", await can(updateDoc(med(owner), { status: "archived", updatedAt: serverTimestamp() })), false);
  record("caregiver(no permission)", "medication: edit", await can(updateDoc(med(cgNone), { notes: "x", updatedAt: serverTimestamp() })), false);
  record("viewer", "medication: edit", await can(updateDoc(med(viewer), { notes: "x", updatedAt: serverTimestamp() })), false);

  // Doses.
  const dose = (db, id = "d1") => doc(db, "profiles", "p1", "doses", id);
  record("caregiver", "dose: create with ANY fields and status 'taken'", await can(setDoc(dose(cg, "dX"), { status: "taken", junk: "x".repeat(2000), medicationId: "nope" })), false);
  record("caregiver(no logDoses)", "dose: create", await can(setDoc(dose(cgNone, "dY"), { status: "pending" })), false);
  record("viewer", "dose: create", await can(setDoc(dose(viewer, "dZ"), { status: "pending" })), false);
  record("owner", "dose: pending -> missed (PDF: only the server)", await can(updateDoc(dose(owner), { status: "missed" })), false);
  record("owner", "dose: pending -> taken", await can(updateDoc(dose(owner), { status: "taken", loggedAt: new Date(), loggedBy: "owner" })), true);
  record("owner", "dose: change medicationId", await can(updateDoc(dose(owner), { medicationId: "other" })), false);
  record("owner", "dose: scheduledAt in the past/future", await can(updateDoc(dose(owner), { scheduledAt: new Date() })), false);

  // Free-form collections: any shape and size?
  record("caregiver", "allergy: create a 5 KB junk document", await can(setDoc(doc(cg, "profiles", "p1", "allergies", "aJ"), { junk: "x".repeat(5000), anything: { a: 1 } })), false);
  // By design (M3): any caregiver may record a valid allergy.
  record("caregiver(no permission)", "allergy: create a valid one", await can(setDoc(doc(cgNone, "profiles", "p1", "allergies", "aK"), { name: "x" })), true);
  record("caregiver", "pharmacy: create a 5 KB junk document", await can(setDoc(doc(cg, "profiles", "p1", "pharmacies", "phJ"), { junk: "x".repeat(5000) })), false);
  record("caregiver", "inventoryEvent: create a junk event", await can(setDoc(doc(cg, "profiles", "p1", "medications", "m1", "inventoryEvents", "eJ"), { junk: "x".repeat(5000) })), false);

  // Users.
  const me = env.authenticatedContext("stranger").firestore();
  record("stranger", "users/other: read someone else", await can(getDoc(doc(me, "users", "owner"))), false);
  record("stranger", "users/self: write plan/role", await can(updateDoc(doc(me, "users", "stranger"), { plan: "pro" })), false);
  record("stranger", "users/self: write settings 50 KB", await can(updateDoc(doc(me, "users", "stranger"), { settings: { blob: "x".repeat(50000) } })), false);
  record("stranger", "users/self/devices: write 50 KB doc", await can(setDoc(doc(me, "users", "stranger", "devices", "t"), { blob: "x".repeat(50000) })), false);
  record("stranger", "customers/self: write entitlement", await can(setDoc(doc(me, "customers", "stranger"), { status: "active" })), false);
  record("stranger", "config/x: write", await can(setDoc(doc(me, "config", "x"), { a: 1 })), false);
  record("signed-out", "supportTickets: create", await can(setDoc(doc(env.unauthenticatedContext().firestore(), "supportTickets", "t"), { uid: "x" })), false);
}

// Hypothesis for step 2: a LIST can use the same member check as a GET when
// the path holds the profile id.
async function candidateRules() {
  let r = RULES;
  const before = r;
  // profiles (top level): only my own profiles.
  r = r.replace(
    "allow list: if signedIn();\n\n      allow update: if (isOwner(profileId)",
    "allow list: if signedIn() && request.auth.uid in resource.data.memberUids;\n\n      allow update: if (isOwner(profileId)",
  );
  // medications and doses: members only.
  r = r.replace(
    "allow get: if isMember(profileId);\n        allow list: if signedIn();\n\n        // M5: Create",
    "allow get, list: if isMember(profileId);\n\n        // M5: Create",
  );
  r = r.replace(
    "allow get: if isMember(profileId);\n        allow list: if signedIn();\n\n        // M7: Create",
    "allow get, list: if isMember(profileId);\n\n        // M7: Create",
  );
  return { rules: r, changed: r !== before };
}

async function main() {
  const env = await initializeTestEnvironment({
    projectId: "medapp-staging",
    firestore: { host: "127.0.0.1", port: 8080, rules: RULES },
  });
  await env.clearFirestore();
  await seed(env);
  await readProbes(env);
  await writeProbes(env);
  await env.cleanup();

  // Second run: the candidate rules (read probes only).
  const cand = await candidateRules();
  const base = rows.length;
  const env2 = await initializeTestEnvironment({
    projectId: "medapp-staging",
    firestore: { host: "127.0.0.1", port: 8080, rules: cand.rules },
  });
  await env2.clearFirestore();
  await seed(env2);
  await readProbes(env2);
  const candidateRows = rows.splice(base).map((r) => ({ ...r, who: `[candidate] ${r.who}` }));
  await env2.cleanup();

  const gaps = rows.filter((r) => r.verdict === "GAP");
  console.log(`\n== CURRENT RULES: ${rows.length} probes, ${gaps.length} gaps ==`);
  for (const g of gaps) {
    console.log(`GAP  ${g.who.padEnd(24)} ${g.what}  -> rules ${g.rules}, expected ${g.expected}`);
  }
  const cgaps = candidateRows.filter((r) => r.verdict === "GAP");
  console.log(`\n== CANDIDATE RULES (list uses the member check): ${candidateRows.length} read probes, ${cgaps.length} gaps ==`);
  console.log(`candidate rewrite applied: ${cand.changed}`);
  for (const g of cgaps) {
    console.log(`GAP  ${g.who.padEnd(36)} ${g.what}  -> rules ${g.rules}, expected ${g.expected}`);
  }
  fs.writeFileSync(
    process.env.PROBE_OUT || "audit_rules_probe.json",
    JSON.stringify({ current: rows, candidate: candidateRows }, null, 2),
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
