// M21 step 2: role x collection x action matrix for the profile data, plus the
// new shape rules (dose create / update, stock, inventory events, allergies,
// pharmacies, user settings, devices). The reading matrix is the permanent
// version of tools/audit_rules_probe.js, so the "list" holes found in the M21
// audit cannot come back unnoticed.
//
// People (profile "p1"):
//   owner     the owner
//   cg        caregiver, editMedications + logDoses, health access
//   cgLog     caregiver, logDoses only, NO health access
//   cgNone    caregiver without any permission, no health access
//   viewer    read-only member, no health access
//   stranger  signed in, not a member
//   anon      signed out

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
  deleteDoc,
  collection,
  query,
  where,
  limit,
  writeBatch,
  serverTimestamp,
  increment,
} = require("firebase/firestore");

let env;

const DAY = 24 * 60 * 60 * 1000;
const ago = (ms) => new Date(Date.now() - ms);
const ahead = (ms) => new Date(Date.now() + ms);

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: "medapp-staging",
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules: fs.readFileSync("firestore.rules", "utf8"),
    },
  });
});

afterAll(async () => {
  if (env) await env.cleanup();
});

const ctx = {
  anon: () => env.unauthenticatedContext().firestore(),
  stranger: () => env.authenticatedContext("stranger").firestore(),
  viewer: () => env.authenticatedContext("viewer").firestore(),
  cgNone: () => env.authenticatedContext("cgNone").firestore(),
  cgLog: () => env.authenticatedContext("cgLog").firestore(),
  cg: () => env.authenticatedContext("cg").firestore(),
  owner: () => env.authenticatedContext("owner").firestore(),
};
const PEOPLE = ["anon", "stranger", "viewer", "cgNone", "cgLog", "cg", "owner"];

// A dose exactly as the app writes it (Dose.toJson).
function appDose(over = {}) {
  return {
    profileId: "p1",
    medicationId: "m1",
    medName: "Metformin",
    doseLabel: "500 mg",
    scheduledAt: ahead(DAY),
    missDeadline: ahead(DAY + 3600 * 1000),
    status: "pending",
    loggedAt: null,
    loggedBy: null,
    reasonCode: null,
    reasonText: null,
    snoozedUntil: null,
    createdAt: new Date(),
    ...over,
  };
}

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (c) => {
    const db = c.firestore();
    await setDoc(doc(db, "profiles", "p1"), {
      ownerUid: "owner",
      kind: "self",
      name: "Patient One",
      timezone: "UTC",
      roles: {
        owner: "owner",
        cg: "caregiver",
        cgLog: "caregiver",
        cgNone: "caregiver",
        viewer: "viewer",
      },
      memberUids: ["owner", "cg", "cgLog", "cgNone", "viewer"],
      healthUids: ["owner", "cg"],
      permissions: {
        cg: { editMedications: true, logDoses: true },
        cgLog: { logDoses: true },
      },
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
    await sub("medications", "m1", {
      name: "Metformin",
      profileId: "p1",
      status: "active",
      quantityOnHand: 30,
    });
    await sub("doses", "d1", appDose());
    await sub("doses", "dOverdue", appDose({ missDeadline: ago(3600 * 1000), scheduledAt: ago(2 * 3600 * 1000) }));
    await sub("doses", "dTaken", appDose({ status: "taken", loggedAt: ago(3600 * 1000), loggedBy: "owner" }));
    await sub("doses", "dTakenOld", appDose({ status: "taken", loggedAt: ago(2 * DAY), loggedBy: "owner" }));
    await sub("doses", "dMissed", appDose({ status: "missed", missDeadline: ago(DAY) }));
    await sub("allergies", "a1", { name: "Penicillin" });
    await sub("vitals", "v1", { type: "weight", value: 70 });
    await sub("symptoms", "s1", { symptom: "x" });
    await sub("prescribers", "pr1", { name: "Dr" });
    await sub("appointments", "ap1", { type: "checkup" });
    await sub("doctorNotes", "n1", { body: "x" });
    await sub("pharmacies", "ph1", { name: "Pharm" });
    await sub("dailySummaries", "2026-01-01", { taken: 1 });
    await setDoc(
      doc(db, "profiles", "p1", "medications", "m1", "inventoryEvents", "e1"),
      { delta: -1, reason: "dose_taken", createdAt: new Date() },
    );
    await setDoc(doc(db, "users", "owner"), { email: "o@example.com" });
    await setDoc(doc(db, "users", "stranger"), { email: "s@example.com" });
  });
});

// ---------------------------------------------------------------------------
// 1. Reading: get one document and LIST the collection, per person
// ---------------------------------------------------------------------------

//            anon stranger viewer cgNone cgLog cg owner
const MEMBERS = [0, 0, 1, 1, 1, 1, 1];
const HEALTH = [0, 0, 0, 0, 0, 1, 1];
const READ_MATRIX = {
  medications: [MEMBERS, "m1"],
  doses: [MEMBERS, "d1"],
  pharmacies: [MEMBERS, "ph1"],
  dailySummaries: [MEMBERS, "2026-01-01"],
  allergies: [MEMBERS, "a1"],
  vitals: [HEALTH, "v1"],
  symptoms: [HEALTH, "s1"],
  prescribers: [HEALTH, "pr1"],
  appointments: [HEALTH, "ap1"],
  doctorNotes: [HEALTH, "n1"],
};

describe("M21 reading: get and list per role", () => {
  const cases = [];
  for (const [name, [expected, id]] of Object.entries(READ_MATRIX)) {
    PEOPLE.forEach((who, i) => cases.push([name, id, who, !!expected[i]]));
  }

  test.each(cases)("%s/%s: %s get -> %s", async (name, id, who, ok) => {
    const p = getDoc(doc(ctx[who](), "profiles", "p1", name, id));
    await (ok ? assertSucceeds(p) : assertFails(p));
  });

  test.each(cases)("%s/%s: %s LIST -> %s", async (name, _id, who, ok) => {
    const p = getDocs(collection(ctx[who](), "profiles", "p1", name));
    await (ok ? assertSucceeds(p) : assertFails(p));
  });

  test.each(PEOPLE.map((w, i) => [w, !!MEMBERS[i]]))(
    "inventoryEvents get and list: %s -> %s",
    async (who, ok) => {
      const db = ctx[who]();
      const col = collection(db, "profiles", "p1", "medications", "m1", "inventoryEvents");
      await (ok ? assertSucceeds(getDocs(col)) : assertFails(getDocs(col)));
      const one = getDoc(doc(col, "e1"));
      await (ok ? assertSucceeds(one) : assertFails(one));
    },
  );

  test.each(PEOPLE.map((w, i) => [w, !!MEMBERS[i]]))(
    "profile document get: %s -> %s",
    async (who, ok) => {
      const p = getDoc(doc(ctx[who](), "profiles", "p1"));
      await (ok ? assertSucceeds(p) : assertFails(p));
    },
  );
});

describe("M21 listing profiles", () => {
  const profiles = (db) => collection(db, "profiles");

  test.each(["anon", "stranger", "viewer", "owner"])(
    "%s cannot list ALL profiles (no filter)",
    async (who) => {
      await assertFails(getDocs(profiles(ctx[who]())));
    },
  );

  test("owner can list own profiles: memberUids array-contains me", async () => {
    await assertSucceeds(
      getDocs(query(profiles(ctx.owner()), where("memberUids", "array-contains", "owner"))),
    );
  });

  test("viewer can list own profiles: memberUids array-contains me", async () => {
    await assertSucceeds(
      getDocs(query(profiles(ctx.viewer()), where("memberUids", "array-contains", "viewer"))),
    );
  });

  test("the query the app uses to find the own profile: ownerUid == me, kind == self, limit", async () => {
    await assertSucceeds(
      getDocs(
        query(
          profiles(ctx.owner()),
          where("ownerUid", "==", "owner"),
          where("kind", "==", "self"),
          limit(1),
        ),
      ),
    );
    await assertSucceeds(
      getDocs(query(profiles(ctx.owner()), where("ownerUid", "==", "owner"), limit(5))),
    );
  });

  test("a stranger cannot ask for somebody else's profiles", async () => {
    await assertFails(
      getDocs(query(profiles(ctx.stranger()), where("memberUids", "array-contains", "owner"))),
    );
    await assertFails(
      getDocs(query(profiles(ctx.stranger()), where("ownerUid", "==", "owner"))),
    );
  });

  test("a stranger's own query returns only the stranger's profiles (none)", async () => {
    const snap = await assertSucceeds(
      getDocs(query(profiles(ctx.stranger()), where("memberUids", "array-contains", "stranger"))),
    );
    expect(snap.size).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// 2. Doses
// ---------------------------------------------------------------------------

describe("M21 dose create", () => {
  const dose = (db, id) => doc(db, "profiles", "p1", "doses", id);

  test("a scheduled dose exactly as the generator writes it (editMedications)", async () => {
    await assertSucceeds(setDoc(dose(ctx.cg(), "new1"), appDose()));
    await assertSucceeds(setDoc(dose(ctx.owner(), "new2"), appDose()));
  });

  test("the 14-day batch the app writes", async () => {
    const db = ctx.cg();
    const b = writeBatch(db);
    for (let i = 0; i < 5; i++) b.set(dose(db, `b${i}`), appDose());
    await assertSucceeds(b.commit());
  });

  test("a scheduled dose needs editMedications (logDoses only is refused)", async () => {
    await assertFails(setDoc(dose(ctx.cgLog(), "x"), appDose()));
  });

  test("viewer, caregiver without permission, stranger, signed-out cannot create", async () => {
    for (const who of ["viewer", "cgNone", "stranger", "anon"]) {
      await assertFails(setDoc(dose(ctx[who](), "x"), appDose()));
    }
  });

  test("a PRN dose (taken now, logged by me) by whoever may log doses", async () => {
    const prn = (uid) => appDose({ status: "taken", loggedAt: new Date(), loggedBy: uid });
    await assertSucceeds(setDoc(dose(ctx.cgLog(), "prn1"), prn("cgLog")));
    await assertSucceeds(setDoc(dose(ctx.cg(), "prn2"), prn("cg")));
    await assertSucceeds(setDoc(dose(ctx.owner(), "prn3"), prn("owner")));
  });

  test("a PRN dose cannot be logged in somebody else's name", async () => {
    await assertFails(
      setDoc(dose(ctx.cg(), "prnX"), appDose({ status: "taken", loggedAt: new Date(), loggedBy: "owner" })),
    );
  });

  test("a PRN dose without loggedAt is refused", async () => {
    await assertFails(setDoc(dose(ctx.cg(), "prnY"), appDose({ status: "taken", loggedBy: "cg" })));
  });

  test("a PRN dose by a caregiver who may not log doses is refused", async () => {
    await assertFails(
      setDoc(dose(ctx.cgNone(), "prnZ"), appDose({ status: "taken", loggedAt: new Date(), loggedBy: "cgNone" })),
    );
  });

  test("created already missed or skipped is refused", async () => {
    await assertFails(setDoc(dose(ctx.owner(), "m"), appDose({ status: "missed" })));
    await assertFails(setDoc(dose(ctx.owner(), "s"), appDose({ status: "skipped" })));
  });

  test("a scheduled dose that already says it was logged is refused", async () => {
    await assertFails(setDoc(dose(ctx.owner(), "l"), appDose({ loggedAt: new Date(), loggedBy: "owner" })));
  });

  test("junk fields, a wrong profileId or oversized text are refused", async () => {
    await assertFails(setDoc(dose(ctx.owner(), "j1"), { ...appDose(), junk: "x" }));
    await assertFails(setDoc(dose(ctx.owner(), "j2"), appDose({ profileId: "p2" })));
    await assertFails(setDoc(dose(ctx.owner(), "j3"), appDose({ medName: "x".repeat(201) })));
    await assertFails(setDoc(dose(ctx.owner(), "j4"), appDose({ scheduledAt: "tomorrow" })));
    await assertFails(setDoc(dose(ctx.owner(), "j5"), { status: "pending" }));
  });
});

describe("M21 dose update", () => {
  const dose = (db, id) => doc(db, "profiles", "p1", "doses", id);

  test("log taken / skipped like the app (status, loggedAt, loggedBy)", async () => {
    await assertSucceeds(
      updateDoc(dose(ctx.cg(), "d1"), { status: "taken", loggedAt: new Date(), loggedBy: "cg" }),
    );
    await assertSucceeds(
      updateDoc(dose(ctx.cgLog(), "dOverdue"), {
        status: "skipped",
        loggedAt: new Date(),
        loggedBy: "cgLog",
        reasonCode: "forgot",
        reasonText: "slept in",
      }),
    );
  });

  test("a late log of a missed dose is fine", async () => {
    await assertSucceeds(
      updateDoc(dose(ctx.owner(), "dMissed"), { status: "taken", loggedAt: new Date(), loggedBy: "owner" }),
    );
  });

  test("logging in somebody else's name is refused", async () => {
    await assertFails(
      updateDoc(dose(ctx.cg(), "d1"), { status: "taken", loggedAt: new Date(), loggedBy: "owner" }),
    );
  });

  test("an invalid reason code or a 501-character reason is refused", async () => {
    await assertFails(updateDoc(dose(ctx.owner(), "dMissed"), { reasonCode: "hungry" }));
    await assertFails(updateDoc(dose(ctx.owner(), "dMissed"), { reasonText: "x".repeat(501) }));
    await assertSucceeds(updateDoc(dose(ctx.owner(), "dMissed"), { reasonCode: "side_effect", reasonText: "x".repeat(500) }));
  });

  test("viewer, no-permission caregiver, stranger cannot log", async () => {
    for (const who of ["viewer", "cgNone", "stranger", "anon"]) {
      await assertFails(updateDoc(dose(ctx[who](), "d1"), { status: "taken", loggedAt: new Date(), loggedBy: who }));
    }
  });

  test("snooze: snoozedUntil + missDeadline", async () => {
    await assertSucceeds(
      updateDoc(dose(ctx.cg(), "d1"), { snoozedUntil: ahead(900000), missDeadline: ahead(7200000) }),
    );
  });

  test("a client cannot change what the dose is (medication, schedule, label)", async () => {
    for (const patch of [{ medicationId: "other" }, { scheduledAt: new Date() }, { medName: "x" }, { profileId: "p2" }, { createdAt: new Date() }]) {
      await assertFails(updateDoc(dose(ctx.owner(), "d1"), patch));
    }
  });

  test("status 'snoozed' (which the app never writes) is refused", async () => {
    await assertFails(updateDoc(dose(ctx.owner(), "d1"), { status: "snoozed" }));
  });

  // The overdue sweep (Spark has no scheduled function).
  test("overdue sweep: pending + deadline passed + only status -> missed", async () => {
    await assertSucceeds(updateDoc(dose(ctx.owner(), "dOverdue"), { status: "missed" }));
    await assertSucceeds(updateDoc(dose(ctx.cg(), "dOverdue"), { status: "missed" }));
  });

  test("the sweep as a batch of several doses", async () => {
    await env.withSecurityRulesDisabled(async (c) => {
      await setDoc(doc(c.firestore(), "profiles", "p1", "doses", "dOverdue2"), appDose({ missDeadline: ago(7200000) }));
    });
    const db = ctx.owner();
    const b = writeBatch(db);
    b.update(dose(db, "dOverdue"), { status: "missed" });
    b.update(dose(db, "dOverdue2"), { status: "missed" });
    await assertSucceeds(b.commit());
  });

  test("a dose that is NOT overdue cannot be marked missed", async () => {
    await assertFails(updateDoc(dose(ctx.owner(), "d1"), { status: "missed" }));
  });

  test("missed together with other changes is refused", async () => {
    await assertFails(updateDoc(dose(ctx.owner(), "dOverdue"), { status: "missed", reasonCode: "forgot" }));
    await assertFails(updateDoc(dose(ctx.owner(), "dOverdue"), { status: "missed", loggedBy: "owner" }));
  });

  test("only someone who may log or edit can run the sweep", async () => {
    for (const who of ["viewer", "cgNone", "stranger", "anon"]) {
      await assertFails(updateDoc(dose(ctx[who](), "dOverdue"), { status: "missed" }));
    }
  });

  test("a taken dose cannot become missed", async () => {
    await assertFails(updateDoc(dose(ctx.owner(), "dTaken"), { status: "missed" }));
  });

  // Undo window.
  test("undo within 24 h of logging", async () => {
    await assertSucceeds(
      updateDoc(dose(ctx.owner(), "dTaken"), {
        status: "pending", loggedAt: null, loggedBy: null, reasonCode: null, reasonText: null, snoozedUntil: null,
      }),
    );
  });

  test("undo after 24 h is refused", async () => {
    await assertFails(
      updateDoc(dose(ctx.owner(), "dTakenOld"), {
        status: "pending", loggedAt: null, loggedBy: null, reasonCode: null, reasonText: null, snoozedUntil: null,
      }),
    );
  });

  test("delete: only a pending dose, only by someone who may edit medications", async () => {
    await assertSucceeds(deleteDoc(dose(ctx.cg(), "d1")));
    await assertFails(deleteDoc(dose(ctx.owner(), "dTaken")));
    await assertFails(deleteDoc(dose(ctx.cgLog(), "dOverdue")));
    await assertFails(deleteDoc(dose(ctx.viewer(), "dOverdue")));
  });
});

// ---------------------------------------------------------------------------
// 3. Stock (quantityOnHand) and inventory events
// ---------------------------------------------------------------------------

describe("M21 stock", () => {
  const med = (db) => doc(db, "profiles", "p1", "medications", "m1");
  const ev = (db, id) => doc(db, "profiles", "p1", "medications", "m1", "inventoryEvents", id);
  const stock = (over = {}) => ({
    quantityOnHand: increment(-1),
    lastAdjustedAt: serverTimestamp(),
    adjustmentSource: "dose_taken",
    updatedAt: serverTimestamp(),
    ...over,
  });

  test("a dose taken: event + stock decrement in one batch, exactly as the app does", async () => {
    for (const who of ["owner", "cg", "cgLog"]) {
      const db = ctx[who]();
      const b = writeBatch(db);
      b.set(doc(collection(db, "profiles", "p1", "medications", "m1", "inventoryEvents")), {
        delta: -1, reason: "dose_taken", doseId: "d1", createdAt: serverTimestamp(),
      });
      b.update(med(db), stock());
      await assertSucceeds(b.commit());
    }
  });

  test("the first count (an absolute number) and a correction", async () => {
    await assertSucceeds(updateDoc(med(ctx.owner()), stock({ quantityOnHand: 60, adjustmentSource: "initial_setup" })));
    await assertSucceeds(updateDoc(med(ctx.cg()), stock({ quantityOnHand: 12, adjustmentSource: "manual" })));
  });

  test("viewer, caregiver without permission, stranger cannot change the stock", async () => {
    for (const who of ["viewer", "cgNone", "stranger", "anon"]) {
      await assertFails(updateDoc(med(ctx[who]()), stock()));
    }
  });

  test("a stock-only writer (logDoses) cannot touch anything else of the medication", async () => {
    await assertFails(updateDoc(med(ctx.cgLog()), stock({ name: "Renamed" })));
    await assertFails(updateDoc(med(ctx.cgLog()), { notes: "x", updatedAt: serverTimestamp() }));
  });

  test("bad values are refused: float, string, out of range, no source, no timestamp", async () => {
    await assertFails(updateDoc(med(ctx.owner()), stock({ quantityOnHand: 12.5 })));
    await assertFails(updateDoc(med(ctx.owner()), stock({ quantityOnHand: "many" })));
    await assertFails(updateDoc(med(ctx.owner()), stock({ quantityOnHand: 1000000 })));
    await assertFails(updateDoc(med(ctx.owner()), stock({ quantityOnHand: -5000 })));
    await assertFails(updateDoc(med(ctx.owner()), stock({ adjustmentSource: "" })));
    await assertFails(updateDoc(med(ctx.owner()), stock({ adjustmentSource: "x".repeat(41) })));
    await assertFails(updateDoc(med(ctx.owner()), stock({ lastAdjustedAt: new Date() })));
    await assertFails(updateDoc(med(ctx.owner()), { quantityOnHand: 5, updatedAt: serverTimestamp() }));
  });

  test("daysOfSupply, flags and status stay server-only", async () => {
    await assertFails(updateDoc(med(ctx.owner()), { daysOfSupply: 3, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(med(ctx.owner()), { flags: { lowStock: true }, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(med(ctx.owner()), { status: "archived", updatedAt: serverTimestamp() }));
  });

  test("inventory event: valid by editors and loggers, junk refused", async () => {
    const good = { delta: -2, reason: "manual", createdAt: serverTimestamp() };
    await assertSucceeds(setDoc(ev(ctx.owner(), "n1"), good));
    await assertSucceeds(setDoc(ev(ctx.cg(), "n2"), { ...good, doseId: null }));
    await assertSucceeds(setDoc(ev(ctx.cgLog(), "n3"), { ...good, doseId: "d1" }));
    await assertFails(setDoc(ev(ctx.owner(), "j1"), { ...good, junk: "x" }));
    await assertFails(setDoc(ev(ctx.owner(), "j2"), { ...good, delta: 1.5 }));
    await assertFails(setDoc(ev(ctx.owner(), "j3"), { ...good, delta: 99999999 }));
    await assertFails(setDoc(ev(ctx.owner(), "j4"), { ...good, reason: "" }));
    await assertFails(setDoc(ev(ctx.owner(), "j5"), { ...good, createdAt: new Date() }));
    await assertFails(setDoc(ev(ctx.owner(), "j6"), { delta: -1, reason: "x" }));
    for (const who of ["viewer", "cgNone", "stranger", "anon"]) {
      await assertFails(setDoc(ev(ctx[who](), "z"), good));
    }
  });

  test("inventory events are never edited", async () => {
    await assertFails(updateDoc(ev(ctx.owner(), "e1"), { delta: -9 }));
  });
});

// ---------------------------------------------------------------------------
// 4. Allergies, pharmacies
// ---------------------------------------------------------------------------

describe("M21 allergies and pharmacies", () => {
  const al = (db, id) => doc(db, "profiles", "p1", "allergies", id);
  const ph = (db, id) => doc(db, "profiles", "p1", "pharmacies", id);

  test("allergy as the add / health-profile screens write it", async () => {
    await assertSucceeds(
      setDoc(al(ctx.cg(), "x1"), {
        name: "Latex", category: "medication", severity: "moderate", symptoms: "rash", addedAt: serverTimestamp(),
      }),
    );
  });

  test("allergy as AllergyRepository writes it (ISO date string)", async () => {
    await assertSucceeds(
      setDoc(al(ctx.owner(), "x2"), {
        id: "x2", memberId: "p1", name: "Peanut", severity: "severe", description: "", createdAt: new Date().toISOString(),
      }),
    );
  });

  test("any caregiver may record an allergy (design of M3), a viewer may not", async () => {
    await assertSucceeds(setDoc(al(ctx.cgNone(), "x3"), { name: "Dust" }));
    await assertFails(setDoc(al(ctx.viewer(), "x4"), { name: "Dust" }));
    await assertFails(setDoc(al(ctx.stranger(), "x5"), { name: "Dust" }));
    await assertFails(setDoc(al(ctx.anon(), "x6"), { name: "Dust" }));
  });

  test("allergy junk is refused: unknown key, no name, huge text, wrong types", async () => {
    await assertFails(setDoc(al(ctx.cg(), "j1"), { name: "x", junk: "y" }));
    await assertFails(setDoc(al(ctx.cg(), "j2"), { severity: "mild" }));
    await assertFails(setDoc(al(ctx.cg(), "j3"), { name: "x".repeat(101) }));
    await assertFails(setDoc(al(ctx.cg(), "j4"), { name: "x", symptoms: "y".repeat(501) }));
    await assertFails(setDoc(al(ctx.cg(), "j5"), { name: 5 }));
    await assertFails(setDoc(al(ctx.cg(), "j6"), { name: "x", severity: ["a"] }));
  });

  test("allergy update must stay valid; only the owner deletes", async () => {
    await assertSucceeds(updateDoc(al(ctx.cg(), "a1"), { severity: "mild" }));
    await assertFails(updateDoc(al(ctx.cg(), "a1"), { junk: "y" }));
    await assertFails(deleteDoc(al(ctx.cg(), "a1")));
    await assertSucceeds(deleteDoc(al(ctx.owner(), "a1")));
  });

  const pharmacy = (over = {}) => ({
    id: "ph9", memberId: "p1", name: "City Pharmacy", phone: "+1 555 0100", address: "1 Main St",
    isPrimary: false, linkedMedicationIds: ["m1"],
    openingHours: [{ label: "Mon", openTime: "09:00", closeTime: "17:00", isClosed: false }],
    createdAt: new Date(), updatedAt: new Date(), ...over,
  });

  test("pharmacy as the app writes it; mark primary", async () => {
    await assertSucceeds(setDoc(ph(ctx.cg(), "ph9"), pharmacy()));
    await assertSucceeds(updateDoc(ph(ctx.cg(), "ph1"), { isPrimary: true }));
  });

  test("pharmacy junk is refused", async () => {
    await assertFails(setDoc(ph(ctx.cg(), "j1"), { ...pharmacy(), junk: "y" }));
    await assertFails(setDoc(ph(ctx.cg(), "j2"), pharmacy({ name: "" })));
    await assertFails(setDoc(ph(ctx.cg(), "j3"), pharmacy({ address: "x".repeat(301) })));
    await assertFails(setDoc(ph(ctx.cg(), "j4"), pharmacy({ linkedMedicationIds: Array(51).fill("m") })));
    await assertFails(setDoc(ph(ctx.cg(), "j5"), pharmacy({ isPrimary: "yes" })));
  });

  test("pharmacy needs editMedications", async () => {
    for (const who of ["cgLog", "cgNone", "viewer", "stranger", "anon"]) {
      await assertFails(setDoc(ph(ctx[who](), "x"), pharmacy()));
    }
  });
});

// ---------------------------------------------------------------------------
// 5. users: settings, devices
// ---------------------------------------------------------------------------

describe("M21 user settings and devices", () => {
  const user = () => doc(ctx.owner(), "users", "owner");

  test("every settings key the app syncs is accepted", async () => {
    await assertSucceeds(
      updateDoc(user(), {
        settings: {
          language: "hi", textSizeIndex: 2, highContrast: true, simplifiedMode: false, voiceInput: true,
          doseEnabled: true, refillEnabled: true, caregiverEnabled: false, escalationMinutes: 25,
          quietHoursEnabled: true, quietStartHour: 22, quietStartMinute: 0, quietEndHour: 7, quietEndMinute: 30,
          hideMedicineNamesOnLockScreen: true,
        },
      }),
    );
    await assertSucceeds(updateDoc(user(), { "settings.language": "es" }));
  });

  test("an unknown settings key (a place to hide data) is refused", async () => {
    await assertFails(updateDoc(user(), { settings: { blob: "x".repeat(50000) } }));
    await assertFails(updateDoc(user(), { "settings.blob": "x" }));
    await assertFails(updateDoc(user(), { "settings.language": "x".repeat(11) }));
    await assertFails(updateDoc(user(), { settings: "not a map" }));
  });

  test("device token documents: the app's fields only", async () => {
    const d = (id) => doc(ctx.owner(), "users", "owner", "devices", id);
    await assertSucceeds(
      setDoc(d("tok1"), { platform: "android", appVersion: "1.0.0", lastSeen: serverTimestamp(), updatedAt: serverTimestamp(), timezone: "Asia/Karachi" }),
    );
    await assertFails(setDoc(d("tok2"), { blob: "x".repeat(50000) }));
    await assertFails(setDoc(d("tok3"), { platform: "x".repeat(21) }));
    await assertSucceeds(deleteDoc(d("tok1")));
  });

  test("nobody else touches my devices", async () => {
    const d = doc(ctx.stranger(), "users", "owner", "devices", "t");
    await assertFails(setDoc(d, { platform: "android" }));
    await assertFails(getDoc(d));
  });
});

// ---------------------------------------------------------------------------
// 6. Daily limits (users/{uid}/limits/{day}): posts 20, comments 100,
//    reports 20, support tickets 5. Mirrors lib/core/daily_limits.dart.
// ---------------------------------------------------------------------------

describe("M21 daily limits", () => {
  const CPA = "A1b2C3d4E5f6G7h8I9j0";
  const today = () => Math.floor(Date.now() / 86400000);
  const counter = (db, uid, day = today()) => doc(db, "users", uid, "limits", String(day));
  const as = (uid) => env.authenticatedContext(uid).firestore();

  const post = (db, id) => doc(db, "groups", "g1", "posts", id);
  const comment = (db, id) => doc(db, "groups", "g1", "posts", "p1", "comments", id);
  const report = (db, id) => doc(db, "reports", id);
  const ticketRef = (db) => doc(collection(db, "supportTickets"));

  const newPost = () => ({ authorId: CPA, body: "hello", createdAt: serverTimestamp(), editedAt: null, voteCount: 0, hidden: false });
  const newComment = () => ({ authorId: CPA, body: "nice", createdAt: serverTimestamp(), editedAt: null });
  const newReport = () => ({ reporterId: CPA, targetType: "post", groupId: "g1", postId: "p1", reason: "spam", createdAt: serverTimestamp() });
  const newTicket = (uid) => ({
    uid, subject: "Help", body: "Please help", appVersion: "1.0.0", device: "android", status: "open", createdAt: serverTimestamp(),
  });

  // The action and the counter in ONE batch, as the app writes them.
  function act(db, uid, kind, ref, data, bump = 1) {
    const b = writeBatch(db);
    b.set(ref, data);
    b.set(counter(db, uid), { [kind]: increment(bump) }, { merge: true });
    return b.commit();
  }

  async function setCounter(uid, fields, day = today()) {
    await env.withSecurityRulesDisabled(async (c) => {
      await setDoc(counter(c.firestore(), uid, day), fields);
    });
  }

  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (c) => {
      const db = c.firestore();
      await setDoc(doc(db, "users", "alice"), { email: "a@example.com", communityProfileId: CPA });
      await setDoc(doc(db, "communityProfiles", CPA), { pseudonym: "alice", avatar: "a1", bio: "", createdAt: new Date() });
      await setDoc(doc(db, "groups", "g1"), { name: "G1" });
      await setDoc(doc(db, "groups", "g1", "posts", "p1"), { authorId: CPA, body: "x", createdAt: new Date(), editedAt: null, voteCount: 0, hidden: false });
    });
  });

  const KINDS = [
    ["posts", 20, (db) => post(db, "n1"), () => newPost()],
    ["comments", 100, (db) => comment(db, "n1"), () => newComment()],
    ["reports", 20, (db) => report(db, "n1"), () => newReport()],
    ["tickets", 5, (db) => ticketRef(db), () => newTicket("alice")],
  ];

  describe.each(KINDS)("%s (limit %i)", (kind, max, makeRef, makeData) => {
    test("the action with its counter bump works", async () => {
      const db = as("alice");
      await assertSucceeds(act(db, "alice", kind, makeRef(db), makeData()));
      const snap = await assertSucceeds(getDoc(counter(db, "alice")));
      expect(snap.data()[kind]).toBe(1);
    });

    test("the action WITHOUT the counter is refused", async () => {
      const db = as("alice");
      await assertFails(setDoc(makeRef(db), makeData()));
    });

    test("a counter bump of 2 (or 0) for one action is refused", async () => {
      const db = as("alice");
      await assertFails(act(db, "alice", kind, makeRef(db), makeData(), 2));
      await assertFails(act(db, "alice", kind, makeRef(db), makeData(), 0));
    });

    test("the last allowed one works, the next one is refused", async () => {
      await setCounter("alice", { [kind]: max - 1 });
      const db = as("alice");
      await assertSucceeds(act(db, "alice", kind, makeRef(db), makeData()));
      const db2 = as("alice");
      await assertFails(act(db2, "alice", kind, makeRef(db2), makeData()));
    });

    test("already at the limit: refused straight away", async () => {
      await setCounter("alice", { [kind]: max });
      const db = as("alice");
      await assertFails(act(db, "alice", kind, makeRef(db), makeData()));
    });

    test("yesterday's counter does not count, and cannot be used to dodge today's", async () => {
      await setCounter("alice", { [kind]: max }, today() - 1);
      const db = as("alice");
      await assertSucceeds(act(db, "alice", kind, makeRef(db), makeData()));
      // an action that bumps YESTERDAY's counter instead of today's is refused
      const db2 = as("alice");
      const b = writeBatch(db2);
      b.set(makeRef(db2), makeData());
      b.set(counter(db2, "alice", today() - 1), { [kind]: increment(1) }, { merge: true });
      await assertFails(b.commit());
    });
  });

  describe("the counter document", () => {
    test("each kind can be raised by one", async () => {
      const db = as("alice");
      for (const kind of ["posts", "comments", "reports", "tickets"]) {
        await assertSucceeds(setDoc(counter(db, "alice"), { [kind]: increment(1) }, { merge: true }));
      }
    });

    test("two fields at once, a jump, a decrease or a reset are refused", async () => {
      await setCounter("alice", { posts: 3 });
      const db = as("alice");
      await assertFails(updateDoc(counter(db, "alice"), { posts: increment(2) }));
      await assertFails(updateDoc(counter(db, "alice"), { posts: increment(-1) }));
      await assertFails(updateDoc(counter(db, "alice"), { posts: 0 }));
      await assertFails(updateDoc(counter(db, "alice"), { posts: increment(1), comments: increment(1) }));
    });

    test("only today's document, no unknown field, no strings", async () => {
      const db = as("alice");
      await assertFails(setDoc(counter(db, "alice", today() + 1), { posts: 1 }));
      await assertFails(setDoc(counter(db, "alice", today() - 1), { posts: 1 }));
      await assertFails(setDoc(counter(db, "alice"), { junk: 1 }));
      await assertFails(setDoc(counter(db, "alice"), { posts: "1" }));
      await assertFails(setDoc(counter(db, "alice"), { posts: 1, junk: 1 }));
    });

    test("nobody touches or reads somebody else's counter; signed out nothing", async () => {
      const db = as("stranger");
      await assertFails(setDoc(counter(db, "alice"), { posts: 1 }));
      await assertFails(getDoc(counter(db, "alice")));
      await assertFails(setDoc(counter(env.unauthenticatedContext().firestore(), "alice"), { posts: 1 }));
    });

    test("an action cannot be paid with somebody else's counter", async () => {
      const db = as("stranger");
      const b = writeBatch(db);
      b.set(post(db, "n1"), newPost());
      b.set(counter(db, "alice"), { posts: increment(1) }, { merge: true });
      await assertFails(b.commit());
    });

    test("the owner reads it; delete only after the account deletion grace period", async () => {
      await setCounter("alice", { posts: 1 });
      const db = as("alice");
      await assertSucceeds(getDoc(counter(db, "alice")));
      await assertFails(deleteDoc(counter(db, "alice")));
    });
  });
});
