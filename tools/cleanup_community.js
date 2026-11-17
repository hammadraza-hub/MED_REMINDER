// M19 step 7 — removes community leftovers whose post no longer exists:
// comments, votes and reports of deleted posts. (On the Spark plan nothing
// removes them automatically, and the rules do not let a user delete other
// people's comments.) Nobody can see these any more, so this only saves
// space and keeps the moderator list tidy.
//
//   Emulator (safe, default):
//     set FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
//     node tools/cleanup_community.js --project medapp-staging            (count only)
//     node tools/cleanup_community.js --project medapp-staging --apply    (delete)
//
//   Real project:
//     set GOOGLE_APPLICATION_CREDENTIALS=<service account json>
//     node tools/cleanup_community.js --project <id> --production [--apply]
//
// Without --apply nothing is deleted: it only prints what it would remove.
const path = require("path");
const admin = require(path.join(__dirname, "..", "functions", "node_modules", "firebase-admin"));

function arg(name) {
  const i = process.argv.indexOf(name);
  return i === -1 ? null : process.argv[i + 1] ?? true;
}

async function main() {
  const project = arg("--project");
  const production = process.argv.includes("--production");
  const apply = process.argv.includes("--apply");
  const emulator = !!process.env.FIRESTORE_EMULATOR_HOST;

  if (!project) throw new Error("Pass --project <id>");
  if (!emulator && !production) {
    throw new Error("No emulator host set. For a real project pass --production.");
  }

  admin.initializeApp({ projectId: project });
  const db = admin.firestore();

  // post path -> does it exist? (one read per post, cached)
  const exists = new Map();
  async function postExists(ref) {
    const key = ref.path;
    if (!exists.has(key)) exists.set(key, (await ref.get()).exists);
    return exists.get(key);
  }

  const orphans = { comments: [], votes: [], reports: [] };

  for (const kind of ["comments", "votes"]) {
    const snap = await db.collectionGroup(kind).get();
    for (const doc of snap.docs) {
      // groups/{g}/posts/{p}/{kind}/{id}
      const postRef = doc.ref.parent.parent;
      if (!postRef || postRef.parent.id !== "posts") continue;
      if (!(await postExists(postRef))) orphans[kind].push(doc.ref);
    }
  }

  const reports = await db.collection("reports").get();
  for (const doc of reports.docs) {
    const d = doc.data();
    if (!d.groupId || !d.postId) continue;
    const postRef = db.collection("groups").doc(d.groupId).collection("posts").doc(d.postId);
    if (!(await postExists(postRef))) orphans.reports.push(doc.ref);
  }

  const where = emulator ? "emulator" : "PRODUCTION";
  console.log(
    `${where}: orphan comments ${orphans.comments.length}, votes ${orphans.votes.length}, ` +
      `reports ${orphans.reports.length}`
  );

  if (!apply) {
    console.log("Nothing deleted (add --apply to delete).");
    return;
  }

  const all = [...orphans.comments, ...orphans.votes, ...orphans.reports];
  for (let i = 0; i < all.length; i += 400) {
    const batch = db.batch();
    for (const ref of all.slice(i, i + 400)) batch.delete(ref);
    await batch.commit();
  }
  console.log(`Deleted ${all.length} documents.`);
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
