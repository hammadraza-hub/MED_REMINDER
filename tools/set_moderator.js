// M19 step 7 — gives (or takes away) the community "moderator" right of one
// account. The right is a custom claim in the sign-in token, set with the
// Admin SDK from a PC (works on the Spark plan). The person must sign in
// again for it to take effect.
//
//   Emulator (safe, default):
//     set FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
//     node tools/set_moderator.js --project medapp-staging --email a@b.com
//
//   Real project:
//     set GOOGLE_APPLICATION_CREDENTIALS=<service account json>
//     node tools/set_moderator.js --project <id> --email a@b.com --production
//
//   Take it away: add --remove
//   Show only:    add --show
//   Emulator only: add --create to make the account first if it is missing
//                  (password Test1234!, plus its users/{uid} document when
//                  FIRESTORE_EMULATOR_HOST is set), for tests.
const path = require("path");
const admin = require(path.join(__dirname, "..", "functions", "node_modules", "firebase-admin"));

function arg(name) {
  const i = process.argv.indexOf(name);
  return i === -1 ? null : process.argv[i + 1] ?? true;
}

async function main() {
  const project = arg("--project");
  const email = arg("--email");
  const production = process.argv.includes("--production");
  const remove = process.argv.includes("--remove");
  const show = process.argv.includes("--show");
  const emulator = !!process.env.FIREBASE_AUTH_EMULATOR_HOST;

  if (!project) throw new Error("Pass --project <id>");
  if (!email || email === true) throw new Error("Pass --email <address>");
  if (!emulator && !production) {
    throw new Error("No auth emulator host set. For a real project pass --production.");
  }

  admin.initializeApp({ projectId: project });
  const auth = admin.auth();
  let user;
  try {
    user = await auth.getUserByEmail(email);
  } catch (e) {
    if (process.argv.includes("--create") && emulator && e.code === "auth/user-not-found") {
      user = await auth.createUser({ email, password: "Test1234!", emailVerified: true });
      // The app expects a users/{uid} document for every account (sign-up
      // creates it); make one so this test account can sign in to the app.
      if (process.env.FIRESTORE_EMULATOR_HOST) {
        await admin.firestore().collection("users").doc(user.uid).set({
          email,
          displayName: "Moderator",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }
    } else {
      throw e;
    }
  }
  const claims = { ...(user.customClaims || {}) };

  if (show) {
    console.log(`${email}: moderator = ${claims.moderator === true}`);
    return;
  }

  if (remove) {
    delete claims.moderator;
  } else {
    claims.moderator = true;
  }
  await auth.setCustomUserClaims(user.uid, claims);
  console.log(
    `${email}: moderator = ${claims.moderator === true} (${emulator ? "emulator" : "PRODUCTION"}). ` +
      "They must sign in again."
  );
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
