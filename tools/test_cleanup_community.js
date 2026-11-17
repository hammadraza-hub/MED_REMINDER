// Self-test for tools/cleanup_community.js. Runs against the LOCAL Firestore
// emulator only (it writes and removes data). Not part of `npx jest tests`
// because it must not run while the rules tests clear the emulator.
//
//   set FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
//   node tools/test_cleanup_community.js
const path = require("path");
const { execFileSync } = require("child_process");
const admin = require(path.join(__dirname, "..", "functions", "node_modules", "firebase-admin"));

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error("Set FIRESTORE_EMULATOR_HOST (emulator only).");
  process.exit(1);
}

admin.initializeApp({ projectId: "cleanup-selftest" });
const db = admin.firestore();
const script = path.join(__dirname, "cleanup_community.js");

function run(extra) {
  return execFileSync(process.execPath, [script, "--project", "cleanup-selftest", ...extra], {
    env: process.env,
    encoding: "utf8",
  });
}

function check(cond, msg) {
  if (!cond) {
    console.error("FAIL:", msg);
    process.exitCode = 1;
  } else {
    console.log("ok  :", msg);
  }
}

async function main() {
  const live = db.collection("groups").doc("selftest").collection("posts").doc("live");
  const gone = db.collection("groups").doc("selftest").collection("posts").doc("gone");

  // a live post with a comment, a vote and a report: must stay
  await live.set({ authorId: "A".repeat(20), body: "x", hidden: false, voteCount: 1 });
  await live.collection("comments").doc("c1").set({ body: "keep" });
  await live.collection("votes").doc("v1").set({ ok: true });
  await db.collection("reports").doc("keep-report").set({ groupId: "selftest", postId: "live" });

  // a deleted post ("gone" has no document): its leftovers must go
  await gone.collection("comments").doc("c1").set({ body: "orphan" });
  await gone.collection("comments").doc("c2").set({ body: "orphan" });
  await gone.collection("votes").doc("v1").set({ ok: true });
  await db.collection("reports").doc("orphan-report").set({ groupId: "selftest", postId: "gone" });

  const dry = run([]);
  check(/orphan comments 2, votes 1, reports 1/.test(dry), "dry run counts the 2 + 1 + 1 leftovers");
  check((await gone.collection("comments").get()).size === 2, "dry run deletes nothing");

  const applied = run(["--apply"]);
  check(/Deleted 4 documents/.test(applied), "--apply deletes exactly 4 documents");
  check((await gone.collection("comments").get()).empty, "orphan comments are gone");
  check((await gone.collection("votes").get()).empty, "orphan votes are gone");
  check(!(await db.collection("reports").doc("orphan-report").get()).exists, "orphan report is gone");

  check((await live.collection("comments").doc("c1").get()).exists, "live comment stays");
  check((await live.collection("votes").doc("v1").get()).exists, "live vote stays");
  check((await db.collection("reports").doc("keep-report").get()).exists, "live report stays");

  const again = run([]);
  check(/orphan comments 0, votes 0, reports 0/.test(again), "second run finds nothing");

  // safety: refuses without an emulator host or --production
  let refused = false;
  try {
    const env = { ...process.env };
    delete env.FIRESTORE_EMULATOR_HOST;
    execFileSync(process.execPath, [script, "--project", "x"], { env, encoding: "utf8", stdio: "pipe" });
  } catch (e) {
    refused = /--production/.test(String(e.stderr));
  }
  check(refused, "refuses to run without an emulator host or --production");

  // clean up the test data
  await live.collection("comments").doc("c1").delete();
  await live.collection("votes").doc("v1").delete();
  await live.delete();
  await db.collection("reports").doc("keep-report").delete();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
