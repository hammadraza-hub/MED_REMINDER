// M19 step 3 — creates the community groups (and, on the emulator only, some
// demo posts). Groups can only be written with the Admin SDK (the rules block
// clients), so this runs from a PC.
//
//   Emulator (safe, default):
//     set FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
//     node tools/seed_community.js --project medapp-staging [--demo]
//
//   Real project (groups only, never demo data):
//     set GOOGLE_APPLICATION_CREDENTIALS=<service account json>
//     node tools/seed_community.js --project <id> --production
//
// Safe to run again: groups use fixed ids and are overwritten.
const path = require("path");
const admin = require(path.join(__dirname, "..", "functions", "node_modules", "firebase-admin"));

const GROUPS = [
  { id: "diabetes", name: "Diabetes", description: "Living with diabetes: routines, readings and tips.", order: 1 },
  { id: "blood-pressure", name: "Blood Pressure", description: "Managing blood pressure day to day.", order: 2 },
  { id: "heart-health", name: "Heart Health", description: "Heart conditions and staying active.", order: 3 },
  { id: "mental-wellbeing", name: "Mental Wellbeing", description: "Stress, sleep and mood. Be kind to yourself.", order: 4 },
  { id: "caregivers", name: "Caregivers", description: "For people who look after someone else.", order: 5 },
  { id: "general", name: "General", description: "Everything else about taking medicines well.", order: 6 },
];

// Demo only: ids look like real ones (exactly 20 letters/digits: the rules
// require that for blocks and reports).
const DEMO_PROFILES = [
  { id: "DemoCalmRiver000001A", pseudonym: "calm_river42", avatar: "a3", bio: "Type 2, five years in." },
  { id: "DemoBraveOtter00002B", pseudonym: "brave_otter17", avatar: "a7", bio: "" },
  { id: "DemoKindMaple000003C", pseudonym: "kind_maple88", avatar: "a10", bio: "Looking after my dad." },
];

function arg(name) {
  const i = process.argv.indexOf(name);
  return i === -1 ? null : process.argv[i + 1] ?? true;
}

async function main() {
  const project = arg("--project");
  const production = process.argv.includes("--production");
  const demo = process.argv.includes("--demo");
  const emulator = !!process.env.FIRESTORE_EMULATOR_HOST;

  if (!project) throw new Error("Pass --project <id>");
  if (!emulator && !production) {
    throw new Error("No emulator host set. For a real project pass --production (groups only).");
  }
  if (!emulator && demo) {
    throw new Error("--demo is for the emulator only.");
  }

  admin.initializeApp({ projectId: project });
  const db = admin.firestore();

  for (const g of GROUPS) {
    const { id, ...data } = g;
    await db.collection("groups").doc(id).set(data);
  }
  console.log(`groups: ${GROUPS.length} written (${emulator ? "emulator" : "PRODUCTION"})`);

  if (!demo) return;

  for (const p of DEMO_PROFILES) {
    const { id, ...data } = p;
    await db.collection("communityProfiles").doc(id).set({
      ...data,
      createdAt: admin.firestore.Timestamp.fromDate(new Date("2026-11-01T10:00:00Z")),
    });
  }

  const now = Date.now();
  const mins = (m) => admin.firestore.Timestamp.fromMillis(now - m * 60000);
  const posts = [];
  // 25 posts in "diabetes" so paging (20 per page) can be tested.
  for (let i = 1; i <= 25; i++) {
    posts.push({
      group: "diabetes",
      id: `demo-d${String(i).padStart(2, "0")}`,
      authorId: DEMO_PROFILES[i % DEMO_PROFILES.length].id,
      body: `Demo post ${i}: how do you remember your evening dose?`,
      createdAt: mins(i * 30),
      editedAt: i % 7 === 0 ? mins(i * 30 - 5) : null,
      voteCount: i % 5,
      hidden: false,
    });
  }
  posts.push({
    group: "diabetes", id: "demo-hidden", authorId: DEMO_PROFILES[0].id,
    body: "This post was hidden by a moderator.", createdAt: mins(1),
    editedAt: null, voteCount: 0, hidden: true,
  });
  posts.push({
    group: "caregivers", id: "demo-c01", authorId: DEMO_PROFILES[2].id,
    body: "Any tips for pill organisers for a parent with memory problems?",
    createdAt: mins(90), editedAt: null, voteCount: 3, hidden: false,
  });
  // author whose profile no longer exists (account deleted)
  posts.push({
    group: "caregivers", id: "demo-c02", authorId: "DemoDeletedUser0009Z",
    body: "A post from an account that was deleted.", createdAt: mins(200),
    editedAt: null, voteCount: 1, hidden: false,
  });

  for (const p of posts) {
    const { group, id, ...data } = p;
    await db.collection("groups").doc(group).collection("posts").doc(id).set(data);
  }
  console.log(`demo: ${DEMO_PROFILES.length} profiles, ${posts.length} posts written`);
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
