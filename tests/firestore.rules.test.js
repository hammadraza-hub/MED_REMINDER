const fs = require("fs");

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");

const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
  deleteField,
  arrayRemove,
} = require("firebase/firestore");

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "medapp-staging",
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules: fs.readFileSync("firestore.rules", "utf8"),
    },
  });
});

afterAll(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, "profiles", "profile1"), {
      ownerUid: "owner123",
      kind: "self",
      name: "Test Patient",
      timezone: "America/New_York",

      roles: {
        owner123: "owner",
        caregiver123: "caregiver",
        viewer123: "viewer",
      },

      memberUids: [
        "owner123",
        "caregiver123",
        "viewer123",
      ],

      healthUids: [
        "owner123",
        "caregiver123",
      ],

      permissions: {
        caregiver123: {
          editMedications: true,
          logDoses: true,
        },
      },
    });

        await setDoc(
      doc(db, "profiles", "profile1", "medications", "med1"),
      {
        name: "Test Medicine",
        strength: "500mg",
        profileId: "profile1",
        status: "active",
        source: "manual",
        schedule: {
          type: "daily",
          times: ["08:00"],
          startDate: new Date(),
          version: 1,
        },
        lowStockDays: 7,
        createdAt: new Date(),
        createdBy: "owner123",
        updatedAt: new Date(),
        updatedBy: "owner123",
      }
    );

    await setDoc(
      doc(db, "profiles", "profile1", "doses", "dose1"),
      {
        medId: "med1",
        status: "pending",
      }
    );
  });
});

describe("Firestore Security Rules — M0", () => {

  test("Unauthenticated users cannot read profiles", async () => {
    const db = testEnv.unauthenticatedContext().firestore();

    await assertFails(
      getDoc(doc(db, "profiles", "profile1"))
    );
  });

  test("Owner can read profile", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();

    await assertSucceeds(
      getDoc(doc(db, "profiles", "profile1"))
    );
  });

  test("Caregiver can read medications", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();

    await assertSucceeds(
      getDoc(doc(db, "profiles", "profile1", "medications", "med1"))
    );
  });

  test("Caregiver with permission can update medication", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();

    await assertSucceeds(
      updateDoc(
        doc(db, "profiles", "profile1", "medications", "med1"),
            { name: "Updated Medicine", updatedAt: new Date() }
      )
    );
  });

  test("Viewer cannot update medication", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();

    await assertFails(
      updateDoc(
        doc(db, "profiles", "profile1", "medications", "med1"),
        { name: "Unauthorized Update" }
      )
    );
  });

  test("Unauthorized user cannot read medication", async () => {
    const db = testEnv.authenticatedContext("stranger123").firestore();

    await assertFails(
      getDoc(doc(db, "profiles", "profile1", "medications", "med1"))
    );
  });

  test("Caregiver can log dose", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();

    await assertSucceeds(
      updateDoc(
        doc(db, "profiles", "profile1", "doses", "dose1"),
        { status: "taken" }
      )
    );
  });

  test("Viewer cannot log dose", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();

    await assertFails(
      updateDoc(
        doc(db, "profiles", "profile1", "doses", "dose1"),
        { status: "taken" }
      )
    );
  });

  test("Caregiver cannot change profile owner", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();

    await assertFails(
      updateDoc(
        doc(db, "profiles", "profile1"),
        { ownerUid: "caregiver123" }
      )
    );
  });

  test("Owner cannot change ownerUid", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();

    await assertFails(
      updateDoc(
        doc(db, "profiles", "profile1"),
        { ownerUid: "anotherUser" }
      )
    );
  });

});
describe("Profile Creation Security — M0", () => {

  test("Authenticated user can create own profile", async () => {
    const db = testEnv.authenticatedContext("newOwner123").firestore();

    await assertSucceeds(
      setDoc(doc(db, "profiles", "newProfile1"), {
        ownerUid: "newOwner123",
        kind: "self",
        name: "Test Patient",
        timezone: "America/New_York",

        roles: {
          newOwner123: "owner",
        },

        memberUids: ["newOwner123"],
        healthUids: ["newOwner123"],
        permissions: {},
      })
    );
  });

  test("User cannot create profile for another owner", async () => {
    const db = testEnv.authenticatedContext("attacker123").firestore();

    await assertFails(
      setDoc(doc(db, "profiles", "newProfile2"), {
        ownerUid: "victim123",
        kind: "self",
        name: "Fake Profile",
        timezone: "America/New_York",

        roles: {
          victim123: "owner",
        },

        memberUids: ["victim123"],
        healthUids: ["victim123"],
        permissions: {},
      })
    );
  });

  test("User cannot assign caregiver during profile creation", async () => {
    const db = testEnv.authenticatedContext("newOwner123").firestore();

    await assertFails(
      setDoc(doc(db, "profiles", "newProfile3"), {
        ownerUid: "newOwner123",
        kind: "self",
        name: "Test Patient",
        timezone: "America/New_York",

        roles: {
          newOwner123: "owner",
          attacker123: "caregiver",
        },

        memberUids: [
          "newOwner123",
          "attacker123",
        ],

        healthUids: ["newOwner123"],

        permissions: {
          attacker123: {
            editMedications: true,
          },
        },
      })
    );
  });

  test("User cannot create profile without owner role", async () => {
    const db = testEnv.authenticatedContext("newOwner123").firestore();

    await assertFails(
      setDoc(doc(db, "profiles", "newProfile4"), {
        ownerUid: "newOwner123",
        kind: "self",
        name: "Test Patient",
        timezone: "America/New_York",

        roles: {
          newOwner123: "viewer",
        },

        memberUids: ["newOwner123"],
        healthUids: ["newOwner123"],
        permissions: {},
      })
    );
  });

});
describe("Role Escalation & Health Access — M0", () => {

  test("Caregiver cannot promote themselves to owner", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();

    await assertFails(
      updateDoc(doc(db, "profiles", "profile1"), {
        "roles.caregiver123": "owner",
      })
    );
  });

  test("Viewer cannot promote themselves to caregiver", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();

    await assertFails(
      updateDoc(doc(db, "profiles", "profile1"), {
        "roles.viewer123": "caregiver",
      })
    );
  });

  test("Caregiver cannot grant themselves health access", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();

    await assertFails(
      updateDoc(doc(db, "profiles", "profile1"), {
        healthUids: [
          "owner123",
          "caregiver123",
          "attacker123",
        ],
      })
    );
  });

  test("Viewer cannot change permissions", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();

    await assertFails(
      updateDoc(doc(db, "profiles", "profile1"), {
        "permissions.viewer123.editMedications": true,
      })
    );
  });

  test("Authorized caregiver can read health records", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();

    await assertSucceeds(
      getDoc(
        doc(db, "profiles", "profile1", "allergies", "allergy1")
      )
    );
  });

    test("Viewer without health access cannot read health records", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();

    // M3: Allergies are now readable by all members (canRead)
    // Use vitals instead — still requires health access (canViewHealth)
    await assertFails(
      getDoc(
        doc(db, "profiles", "profile1", "vitals", "vital1")
      )
    );
  });

  // M3: Any member can read allergies (new behavior)
  test("Viewer can read allergies (M3 — any member can read)", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();

    await assertSucceeds(
      getDoc(
        doc(db, "profiles", "profile1", "allergies", "allergy1")
      )
    );
  });

});

describe("Owner Profile Update Security — M0", () => {

  test("Owner can update profile name", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();

    await assertSucceeds(
      updateDoc(doc(db, "profiles", "profile1"), {
        name: "Updated Patient Name",
      })
    );
  });

  test("Owner cannot modify roles directly", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();

    await assertFails(
      updateDoc(doc(db, "profiles", "profile1"), {
        "roles.viewer123": "caregiver",
      })
    );
  });

  test("Owner cannot modify memberUids directly", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();

    await assertFails(
      updateDoc(doc(db, "profiles", "profile1"), {
        memberUids: ["owner123", "attacker123"],
      })
    );
  });

  test("Owner cannot modify healthUids directly", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();

    await assertFails(
      updateDoc(doc(db, "profiles", "profile1"), {
        healthUids: ["owner123", "attacker123"],
      })
    );
  });

  test("Owner cannot grant medication permission directly", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();

    await assertFails(
      updateDoc(doc(db, "profiles", "profile1"), {
        "permissions.viewer123.editMedications": true,
      })
    );
  });

});

describe("Customers (Subscriptions) Security — M12", () => {

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "customers", "owner123"), {
        activePlan: "annual_premium",
        status: "active",
      });
    });
  });

  test("User can read their own customer record", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(getDoc(doc(db, "customers", "owner123")));
  });

  test("User cannot read another user's customer record", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();
    await assertFails(getDoc(doc(db, "customers", "owner123")));
  });

  test("User cannot write their own customer record", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      updateDoc(doc(db, "customers", "owner123"), { activePlan: "family_plan" })
    );
    await assertFails(
      setDoc(doc(db, "customers", "owner123"), { activePlan: "family_plan" })
    );
  });

  test("Unauthenticated user cannot read customer records", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, "customers", "owner123")));
  });

});


describe("Users legal acceptance — M13 step 2", () => {

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "users", "owner123"), {
        email: "o@example.com",
        displayName: "Owner",
        legal: { termsVersion: "1.0", privacyVersion: "1.0" },
        legalVersions: { terms: "1.0", privacy: "1.0" },
      });
      await setDoc(doc(db, "users", "viewer123"), {
        email: "v@example.com",
        displayName: "Viewer",
      });
    });
  });

  test("User can record acceptance of newer legal versions", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(
      updateDoc(doc(db, "users", "owner123"), {
        legal: { termsVersion: "1.1", privacyVersion: "1.1", acceptedAt: new Date() },
        legalVersions: { terms: "1.1", privacy: "1.1" },
        updatedAt: new Date(),
      })
    );
  });

  test("User cannot record acceptance for another user", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      updateDoc(doc(db, "users", "viewer123"), {
        legal: { termsVersion: "9.9", privacyVersion: "9.9" },
        updatedAt: new Date(),
      })
    );
  });

  test("Legal acceptance update cannot smuggle in protected fields", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      updateDoc(doc(db, "users", "owner123"), {
        legal: { termsVersion: "1.1", privacyVersion: "1.1" },
        plan: "family_plan",
        updatedAt: new Date(),
      })
    );
  });

});


describe("Users settings map — M13 step 3", () => {

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "users", "owner123"), {
        email: "o@example.com",
        displayName: "Owner",
        settings: { doseEnabled: false, escalationMinutes: 25 },
      });
    });
  });

  test("Saving language by dotted path keeps notification settings", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(
      updateDoc(doc(db, "users", "owner123"), {
        "settings.language": "hi",
        "settings.textSizeIndex": 3,
      })
    );
    const snap = await assertSucceeds(getDoc(doc(db, "users", "owner123")));
    expect(snap.data().settings).toEqual({
      doseEnabled: false,
      escalationMinutes: 25,
      language: "hi",
      textSizeIndex: 3,
    });
  });

  test("Saving notification keys by dotted path keeps language", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(
      updateDoc(doc(db, "users", "owner123"), { "settings.language": "es" })
    );
    await assertSucceeds(
      updateDoc(doc(db, "users", "owner123"), { "settings.doseEnabled": true })
    );
    const snap = await assertSucceeds(getDoc(doc(db, "users", "owner123")));
    expect(snap.data().settings.language).toBe("es");
    expect(snap.data().settings.doseEnabled).toBe(true);
  });

  test("User cannot change another user's settings", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();
    await assertFails(
      updateDoc(doc(db, "users", "owner123"), { "settings.language": "ar" })
    );
  });

});


describe("Config (remote FAQ) — M13 step 4", () => {

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "config", "faq"), {
        items: [{ id: "a", order: 1, q: { en: "Q?" }, a: { en: "A." } }],
      });
    });
  });

  test("Signed-in user can read config/faq", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(getDoc(doc(db, "config", "faq")));
  });

  test("Unauthenticated user cannot read config/faq", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, "config", "faq")));
  });

  test("Clients cannot write config/faq", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      setDoc(doc(db, "config", "faq"), { items: [] })
    );
    await assertFails(
      updateDoc(doc(db, "config", "faq"), { items: [] })
    );
    await assertFails(deleteDoc(doc(db, "config", "faq")));
  });

});


describe("Support tickets — M13 step 5", () => {

  const { serverTimestamp, collection, addDoc } = require("firebase/firestore");

  const ticket = (over = {}) => ({
    uid: "owner123",
    subject: "Reminders are not ringing",
    body: "Since yesterday no dose reminder rings on my phone.",
    appVersion: "1.0.0",
    device: "android Android 15",
    locale: "en",
    status: "open",
    createdAt: serverTimestamp(),
    ...over,
  });

  test("User can create their own ticket", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(addDoc(collection(db, "supportTickets"), ticket()));
  });

  test("Unauthenticated user cannot create a ticket", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(addDoc(collection(db, "supportTickets"), ticket()));
  });

  test("Cannot create a ticket for another user", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      addDoc(collection(db, "supportTickets"), ticket({ uid: "viewer123" }))
    );
  });

  test("Extra or missing fields are rejected", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      addDoc(collection(db, "supportTickets"), ticket({ admin: true }))
    );
    const { body, ...withoutBody } = ticket();
    await assertFails(addDoc(collection(db, "supportTickets"), withoutBody));
  });

  test("Empty or oversized subject/body are rejected", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      addDoc(collection(db, "supportTickets"), ticket({ subject: "" }))
    );
    await assertFails(
      addDoc(collection(db, "supportTickets"), ticket({ subject: "x".repeat(121) }))
    );
    await assertFails(
      addDoc(collection(db, "supportTickets"), ticket({ body: "" }))
    );
    await assertFails(
      addDoc(collection(db, "supportTickets"), ticket({ body: "x".repeat(2001) }))
    );
  });

  test("Limits are inclusive (120 / 2000 characters)", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(
      addDoc(
        collection(db, "supportTickets"),
        ticket({ subject: "x".repeat(120), body: "y".repeat(2000) })
      )
    );
  });

  test("Status must be open and createdAt must be server time", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      addDoc(collection(db, "supportTickets"), ticket({ status: "closed" }))
    );
    await assertFails(
      addDoc(collection(db, "supportTickets"), ticket({ createdAt: new Date(2020, 1, 1) }))
    );
  });

  test("User reads own tickets only; tickets are immutable", async () => {
    let id;
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const r = await addDoc(collection(context.firestore(), "supportTickets"), {
        ...ticket(),
        createdAt: new Date(),
      });
      id = r.id;
    });
    const owner = testEnv.authenticatedContext("owner123").firestore();
    const other = testEnv.authenticatedContext("viewer123").firestore();
    await assertSucceeds(getDoc(doc(owner, "supportTickets", id)));
    await assertFails(getDoc(doc(other, "supportTickets", id)));
    await assertFails(updateDoc(doc(owner, "supportTickets", id), { subject: "x" }));
    await assertFails(deleteDoc(doc(owner, "supportTickets", id)));
  });

});


describe("Account deletion request — M14 step 4", () => {

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "users", "owner123"), {
        email: "o@example.com",
        displayName: "Owner",
      });
      await setDoc(doc(db, "users", "pending123"), {
        email: "p@example.com",
        displayName: "Pending",
        deletionRequestedAt: new Date("2026-11-01T00:00:00Z"),
      });
    });
  });

  test("User can request deletion with the server time", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(
      updateDoc(doc(db, "users", "owner123"), {
        deletionRequestedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      })
    );
  });

  test("Request with a client-chosen time is rejected", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      updateDoc(doc(db, "users", "owner123"), {
        deletionRequestedAt: new Date("2020-01-01T00:00:00Z"),
      })
    );
  });

  test("User can cancel a pending request", async () => {
    const db = testEnv.authenticatedContext("pending123").firestore();
    await assertSucceeds(
      updateDoc(doc(db, "users", "pending123"), {
        deletionRequestedAt: deleteField(),
        updatedAt: serverTimestamp(),
      })
    );
    const snap = await assertSucceeds(
      getDoc(doc(testEnv.authenticatedContext("pending123").firestore(), "users", "pending123"))
    );
    expect(snap.data().deletionRequestedAt).toBeUndefined();
  });

  test("Cannot move a pending request to a different time", async () => {
    const db = testEnv.authenticatedContext("pending123").firestore();
    await assertFails(
      updateDoc(doc(db, "users", "pending123"), {
        deletionRequestedAt: new Date("2030-01-01T00:00:00Z"),
      })
    );
  });

  test("Cannot request deletion for another user", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      updateDoc(doc(db, "users", "pending123"), {
        deletionRequestedAt: deleteField(),
      })
    );
    await assertFails(
      updateDoc(doc(db, "users", "pending123"), {
        deletionRequestedAt: serverTimestamp(),
      })
    );
  });

  test("Deletion request cannot smuggle in other fields", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      updateDoc(doc(db, "users", "owner123"), {
        deletionRequestedAt: serverTimestamp(),
        plan: "family_plan",
      })
    );
    await assertFails(
      updateDoc(doc(db, "users", "owner123"), {
        deletionRequestedAt: serverTimestamp(),
        displayName: "Changed",
      })
    );
  });

  test("Unauthenticated user cannot request deletion", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      updateDoc(doc(db, "users", "owner123"), {
        deletionRequestedAt: serverTimestamp(),
      })
    );
  });

  test("User document still cannot be deleted directly", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(deleteDoc(doc(db, "users", "owner123")));
  });

});


// ---------------------------------------------------------------
// M14 step 5 — account purge (delete allowed only after the grace period)
// ---------------------------------------------------------------

const DAY = 24 * 60 * 60 * 1000;

async function seedPurgeData(requestedAt, uid = "owner123") {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const user = { email: "x@example.com", displayName: "X" };
    if (requestedAt) user.deletionRequestedAt = requestedAt;
    await setDoc(doc(db, "users", uid), user);
    await setDoc(doc(db, "users", uid, "devices", "dev1"), { token: "t" });

    const p = ["profiles", "profile1"];
    await setDoc(doc(db, ...p, "medications", "med1", "inventoryEvents", "ev1"), { delta: -1 });
    await setDoc(doc(db, ...p, "doses", "dose2"), { medId: "med1", status: "taken" });
    await setDoc(doc(db, ...p, "pharmacies", "ph1"), { name: "Ph" });
    await setDoc(doc(db, ...p, "dailySummaries", "2026-11-01"), { taken: 1 });
    await setDoc(doc(db, ...p, "vitals", "v1"), { bp: "120/80" });
    await setDoc(doc(db, ...p, "symptoms", "s1"), { name: "x" });
    await setDoc(doc(db, ...p, "allergies", "a1"), { name: "Pen" });
  });
}

describe("Account purge after grace period — M14 step 5", () => {

  beforeEach(async () => {
    await seedPurgeData(new Date(Date.now() - 8 * DAY));
  });

  test("Owner can delete every kind of record once the grace period is over", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    const p = ["profiles", "profile1"];

    await assertSucceeds(deleteDoc(doc(db, ...p, "medications", "med1", "inventoryEvents", "ev1")));
    await assertSucceeds(deleteDoc(doc(db, ...p, "medications", "med1")));
    await assertSucceeds(deleteDoc(doc(db, ...p, "doses", "dose1")));
    await assertSucceeds(deleteDoc(doc(db, ...p, "doses", "dose2"))); // taken dose
    await assertSucceeds(deleteDoc(doc(db, ...p, "pharmacies", "ph1")));
    await assertSucceeds(deleteDoc(doc(db, ...p, "dailySummaries", "2026-11-01")));
    await assertSucceeds(deleteDoc(doc(db, ...p, "vitals", "v1")));
    await assertSucceeds(deleteDoc(doc(db, ...p, "symptoms", "s1")));
    await assertSucceeds(deleteDoc(doc(db, ...p, "allergies", "a1")));
  });

  test("Owner can delete the profile, devices and the user document", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(deleteDoc(doc(db, "profiles", "profile1")));
    await assertSucceeds(deleteDoc(doc(db, "users", "owner123", "devices", "dev1")));
    await assertSucceeds(deleteDoc(doc(db, "users", "owner123")));
  });

  test("Deleting a profile does not need its children to be empty first", async () => {
    // Firestore does not cascade; the app deletes children first. The rule
    // itself must still allow the owner to remove the profile document.
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(deleteDoc(doc(db, "profiles", "profile1")));
  });

  test("A caregiver cannot purge the owner's data even with their own due request", async () => {
    await seedPurgeData(new Date(Date.now() - 8 * DAY), "caregiver123");
    const db = testEnv.authenticatedContext("caregiver123").firestore();
    await assertFails(deleteDoc(doc(db, "profiles", "profile1")));
    await assertFails(deleteDoc(doc(db, "profiles", "profile1", "medications", "med1")));
    await assertFails(deleteDoc(doc(db, "profiles", "profile1", "doses", "dose2")));
    await assertFails(deleteDoc(doc(db, "profiles", "profile1", "vitals", "v1")));
  });

  test("Cannot delete another user's document", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(deleteDoc(doc(db, "users", "viewer123")));
  });

  test("Records that are not health data stay protected", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "profiles", "profile1", "randomStuff", "r1"), { a: 1 });
    });
    await assertFails(deleteDoc(doc(db, "profiles", "profile1", "randomStuff", "r1")));
  });

  test("Unauthenticated users cannot purge", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(deleteDoc(doc(db, "profiles", "profile1")));
    await assertFails(deleteDoc(doc(db, "users", "owner123")));
  });
});

describe("Purge is blocked during the grace period — M14 step 5", () => {

  async function expectAllDeletesDenied() {
    const db = testEnv.authenticatedContext("owner123").firestore();
    const p = ["profiles", "profile1"];
    await assertFails(deleteDoc(doc(db, ...p, "medications", "med1", "inventoryEvents", "ev1")));
    await assertFails(deleteDoc(doc(db, ...p, "medications", "med1")));
    await assertFails(deleteDoc(doc(db, ...p, "doses", "dose2"))); // taken
    await assertFails(deleteDoc(doc(db, ...p, "pharmacies", "ph1")));
    await assertFails(deleteDoc(doc(db, ...p, "dailySummaries", "2026-11-01")));
    await assertFails(deleteDoc(doc(db, ...p, "vitals", "v1")));
    await assertFails(deleteDoc(doc(db, ...p, "symptoms", "s1")));
    await assertFails(deleteDoc(doc(db, "profiles", "profile1")));
    await assertFails(deleteDoc(doc(db, "users", "owner123")));
  }

  test("2 days after the request: nothing can be deleted", async () => {
    await seedPurgeData(new Date(Date.now() - 2 * DAY));
    await expectAllDeletesDenied();
  });

  test("6 days 23 hours after the request: still blocked", async () => {
    await seedPurgeData(new Date(Date.now() - (7 * DAY - 60 * 60 * 1000)));
    await expectAllDeletesDenied();
  });

  test("No deletion request at all: nothing can be deleted", async () => {
    await seedPurgeData(null);
    await expectAllDeletesDenied();
  });

  test("After cancelling (field removed) deletes are blocked again", async () => {
    await seedPurgeData(new Date(Date.now() - 8 * DAY));
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(
      updateDoc(doc(db, "users", "owner123"), { deletionRequestedAt: deleteField() })
    );
    await expectAllDeletesDenied();
  });

  test("User cannot backdate the request to skip the grace period", async () => {
    await seedPurgeData(new Date(Date.now() - 1 * DAY));
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      updateDoc(doc(db, "users", "owner123"), {
        deletionRequestedAt: new Date(Date.now() - 30 * DAY),
      })
    );
    await expectAllDeletesDenied();
  });
});


describe("Member leaves a profile (own access only) — M14 step 6", () => {

  const ref = (db) => doc(db, "profiles", "profile1");

  test("A viewer can remove only their own access", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();
    await assertSucceeds(
      updateDoc(ref(db), {
        memberUids: arrayRemove("viewer123"),
        healthUids: arrayRemove("viewer123"), // not in the list: no-op
        "roles.viewer123": deleteField(),
        updatedAt: serverTimestamp(),
      })
    );
  });

  test("A caregiver with permissions can leave, entry included", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();
    await assertSucceeds(
      updateDoc(ref(db), {
        memberUids: arrayRemove("caregiver123"),
        healthUids: arrayRemove("caregiver123"),
        "roles.caregiver123": deleteField(),
        "permissions.caregiver123": deleteField(),
      })
    );
  });

  test("Leaving but keeping the permissions entry is rejected", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();
    await assertFails(
      updateDoc(ref(db), {
        memberUids: arrayRemove("caregiver123"),
        healthUids: arrayRemove("caregiver123"),
        "roles.caregiver123": deleteField(),
      })
    );
  });

  test("Leaving but keeping the role entry is rejected", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();
    await assertFails(
      updateDoc(ref(db), { memberUids: arrayRemove("viewer123") })
    );
  });

  test("Cannot remove somebody else's access", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();
    await assertFails(
      updateDoc(ref(db), {
        memberUids: arrayRemove("caregiver123"),
        "roles.caregiver123": deleteField(),
      })
    );
  });

  test("Cannot remove the owner", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();
    await assertFails(
      updateDoc(ref(db), {
        memberUids: arrayRemove("owner123"),
        healthUids: arrayRemove("owner123"),
        "roles.owner123": deleteField(),
      })
    );
  });

  test("Cannot leave AND remove someone else in the same write", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();
    await assertFails(
      updateDoc(ref(db), {
        memberUids: arrayRemove("viewer123", "caregiver123"),
        "roles.viewer123": deleteField(),
      })
    );
  });

  test("Cannot promote yourself or change other fields while leaving", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();
    await assertFails(updateDoc(ref(db), { "roles.viewer123": "owner" }));
    await assertFails(
      updateDoc(ref(db), {
        memberUids: arrayRemove("viewer123"),
        "roles.viewer123": deleteField(),
        name: "Hijacked",
      })
    );
    await assertFails(
      updateDoc(ref(db), {
        memberUids: arrayRemove("viewer123"),
        "roles.viewer123": deleteField(),
        ownerUid: "viewer123",
      })
    );
  });

  test("The owner cannot use the leave path", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      updateDoc(ref(db), {
        memberUids: arrayRemove("owner123"),
        healthUids: arrayRemove("owner123"),
        "roles.owner123": deleteField(),
      })
    );
  });

  test("Non-members and anonymous users cannot touch membership", async () => {
    const outsider = testEnv.authenticatedContext("stranger999").firestore();
    await assertFails(
      updateDoc(ref(outsider), { memberUids: arrayRemove("viewer123") })
    );
    const anon = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      updateDoc(ref(anon), { memberUids: arrayRemove("viewer123") })
    );
  });
});

